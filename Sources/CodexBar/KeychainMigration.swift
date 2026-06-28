import CodexBarCore
import Foundation
import Security

/// Migrates keychain items to use kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
/// to prevent permission prompts on every rebuild during development.
enum KeychainMigration {
    private static let log = CodexBarLog.logger(LogCategories.keychainMigration)
    private static let migrationKey = "KeychainMigrationV1Completed"
    /// Gates the one-time service-rename copy. A separate flag from `migrationKey` so a dev
    /// build that already set `migrationKey` still runs the rename exactly once.
    static let serviceRenameKey = "KeychainServiceRenameV1Completed"

    struct MigrationItem: Hashable {
        let service: String
        let account: String?

        var label: String {
            let accountLabel = self.account ?? "<any>"
            return "\(self.service):\(accountLabel)"
        }
    }

    static let itemsToMigrate: [MigrationItem] = [
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "codex-cookie"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "claude-cookie"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "cursor-cookie"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "factory-cookie"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "minimax-cookie"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "minimax-api-token"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "augment-cookie"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "copilot-api-token"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "zai-api-token"),
        MigrationItem(service: AppIdentity.keychainSecretsService, account: "synthetic-api-key"),
    ]

    /// Run migration once per installation
    static func migrateIfNeeded() {
        guard !KeychainAccessGate.isDisabled else {
            self.log.info("Keychain access disabled; skipping migration")
            return
        }

        // Bridge inherited CodexBar secrets to the new ResearchBar service name first, so the
        // accessibility upgrade below operates on the items at their current service.
        self.renameLegacyServiceIfNeeded()

        if !UserDefaults.standard.bool(forKey: self.migrationKey) {
            self.log.info("Starting keychain migration to reduce permission prompts")

            var migratedCount = 0
            var errorCount = 0

            for item in self.itemsToMigrate {
                do {
                    if try self.migrateItem(item) {
                        migratedCount += 1
                    }
                } catch {
                    errorCount += 1
                    self.log.error("Failed to migrate \(item.label): \(String(describing: error))")
                }
            }

            self.log.info("Keychain migration complete: \(migratedCount) migrated, \(errorCount) errors")
            UserDefaults.standard.set(true, forKey: self.migrationKey)

            if migratedCount > 0 {
                self.log.info("✅ Future rebuilds will not prompt for keychain access")
            }
        } else {
            self.log.debug("Keychain migration already completed, skipping")
        }
    }

    /// One-time copy of inherited secrets from the legacy `com.steipete.CodexBar` service to
    /// the new `AppIdentity.keychainSecretsService`. Without this, secrets written by an
    /// earlier build (same signing identity, old service attribute) are orphaned after the
    /// rename and every provider has to be re-authenticated. Copy-only and idempotent: an
    /// item already present under the new service is left untouched, and the legacy copy is
    /// never deleted, so a partial run cannot lose data.
    static func renameLegacyServiceIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: self.serviceRenameKey) else { return }
        let newService = AppIdentity.keychainSecretsService
        let legacyService = AppIdentity.legacyKeychainSecretsService
        guard legacyService != newService else {
            UserDefaults.standard.set(true, forKey: self.serviceRenameKey)
            return
        }

        var copiedCount = 0
        for item in self.itemsToMigrate {
            guard let account = item.account else { continue }
            do {
                if try self.copyItemAcrossService(account: account, from: legacyService, to: newService) {
                    copiedCount += 1
                }
            } catch {
                self.log.error("Failed to copy \(account) across service rename: \(String(describing: error))")
            }
        }

        self.log.info("Keychain service-rename copy complete: \(copiedCount) copied")
        UserDefaults.standard.set(true, forKey: self.serviceRenameKey)
    }

    /// Copy one generic-password item from `legacyService` to `newService`, preserving the
    /// secret bytes and writing with the no-prompt accessibility level. Returns true when a
    /// new item was written, false when the legacy item is absent or the new item already
    /// exists. Only items in the running app's own keychain access group are visible, so this
    /// never touches another team's CodexBar items.
    private static func copyItemAcrossService(
        account: String,
        from legacyService: String,
        to newService: String) throws -> Bool
    {
        var readQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: legacyService,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        var result: CFTypeRef?
        let readStatus = SecItemCopyMatching(readQuery as CFDictionary, &result)
        readQuery.removeAll()
        if readStatus == errSecItemNotFound {
            return false
        }
        guard readStatus == errSecSuccess, let data = result as? Data else {
            throw KeychainMigrationError.readFailed(readStatus)
        }

        let existsQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: newService,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        if SecItemCopyMatching(existsQuery as CFDictionary, nil) == errSecSuccess {
            // Already migrated; leave the existing item untouched.
            return false
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: newService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainMigrationError.addFailed(addStatus)
        }
        self.log.info("Copied \(account) from legacy keychain service to ResearchBar service")
        return true
    }

    /// Migrate a single keychain item to the new accessibility level
    /// Returns true if item was migrated, false if item didn't exist
    private static func migrateItem(_ item: MigrationItem) throws -> Bool {
        // First, try to read the existing item
        var result: CFTypeRef?
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: item.service,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
        ]
        if let account = item.account {
            query[kSecAttrAccount as String] = account
        }

        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            // Item doesn't exist, nothing to migrate
            return false
        }

        guard status == errSecSuccess else {
            throw KeychainMigrationError.readFailed(status)
        }

        guard let rawItem = result as? [String: Any],
              let data = rawItem[kSecValueData as String] as? Data,
              let accessible = rawItem[kSecAttrAccessible as String] as? String
        else {
            throw KeychainMigrationError.invalidItemFormat
        }

        // Check if already using the correct accessibility
        if accessible == (kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String) {
            self.log.debug("\(item.label) already using correct accessibility")
            return false
        }

        // Delete the old item
        var deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: item.service,
        ]
        if let account = item.account {
            deleteQuery[kSecAttrAccount as String] = account
        }

        let deleteStatus = SecItemDelete(deleteQuery as CFDictionary)
        guard deleteStatus == errSecSuccess else {
            throw KeychainMigrationError.deleteFailed(deleteStatus)
        }

        // Add it back with the new accessibility
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: item.service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        if let account = item.account {
            addQuery[kSecAttrAccount as String] = account
        }

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainMigrationError.addFailed(addStatus)
        }

        self.log.info("Migrated \(item.label) to new accessibility level")
        return true
    }

    /// Reset migration flag (for testing)
    static func resetMigrationFlag() {
        UserDefaults.standard.removeObject(forKey: self.migrationKey)
    }
}

enum KeychainMigrationError: Error {
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)
    case addFailed(OSStatus)
    case invalidItemFormat
}
