import CodexBarCore
import Foundation
import Security

/// Migrates keychain items to use kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
/// to prevent permission prompts on every rebuild during development.
enum KeychainMigration {
    private static let log = CodexBarLog.logger(LogCategories.keychainMigration)
    private static let migrationKey = "KeychainMigrationV1Completed"
    /// Gates the one-time service-rename copy. A separate flag from `migrationKey` so a build
    /// that already completed the accessibility migration still copies legacy secrets once.
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

    /// Copy inherited CodexBar secrets to ResearchBar's service exactly once. Existing new
    /// service entries win and the legacy copy is retained, making the operation idempotent
    /// and non-destructive if a migration is interrupted.
    static func renameLegacyServiceIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: self.serviceRenameKey) else { return }

        let legacyService = AppIdentity.legacyKeychainSecretsService
        let newService = AppIdentity.keychainSecretsService
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

    private static func copyItemAcrossService(
        account: String,
        from legacyService: String,
        to newService: String) throws -> Bool
    {
        let readQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: legacyService,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        var result: CFTypeRef?
        let readStatus = KeychainSecurity.copyMatching(readQuery as CFDictionary, &result)
        if readStatus == errSecItemNotFound { return false }
        guard readStatus == errSecSuccess, let data = result as? Data else {
            throw KeychainMigrationError.readFailed(readStatus)
        }

        let existsQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: newService,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        if KeychainSecurity.copyMatching(existsQuery as CFDictionary, nil) == errSecSuccess {
            return false
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: newService,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let addStatus = KeychainSecurity.add(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainMigrationError.addFailed(addStatus)
        }
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

        let status = KeychainSecurity.copyMatching(query as CFDictionary, &result)

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

        let deleteStatus = KeychainSecurity.delete(deleteQuery as CFDictionary)
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

        let addStatus = KeychainSecurity.add(addQuery as CFDictionary, nil)
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
