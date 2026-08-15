import Foundation
#if os(macOS)
import Security
#endif

/// A stored Corbis MCP credential. The bearer token is redacted from all string
/// representations so it can never leak into logs or error text.
public struct CorbisCredential: Equatable, Sendable, Codable {
    public let token: String
    public let accountID: String?
    public let displayEmail: String?
    public let createdAt: Date
    public let lastValidatedAt: Date?

    public init(
        token: String,
        accountID: String?,
        displayEmail: String?,
        createdAt: Date,
        lastValidatedAt: Date?)
    {
        self.token = token
        self.accountID = accountID
        self.displayEmail = displayEmail
        self.createdAt = createdAt
        self.lastValidatedAt = lastValidatedAt
    }

    /// One-way SHA-256 hex fingerprint of the token.
    public var fingerprint: String {
        CorbisAccountIdentity.fingerprint(forToken: self.token)
    }

    /// Derive the cache-keying identity for this credential.
    public func accountIdentity() -> CorbisAccountIdentity {
        CorbisAccountIdentity.make(accountID: self.accountID, token: self.token)
    }
}

extension CorbisCredential: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        "CorbisCredential(token: <redacted>, accountID: \(self.accountID ?? "nil"), "
            + "displayEmail: \(self.displayEmail ?? "nil"))"
    }

    public var debugDescription: String {
        self.description
    }
}

/// Persistence seam for the Corbis credential. Implementations must never echo the
/// token into errors or logs.
public protocol CorbisCredentialStoring: Sendable {
    func loadCredential() async throws -> CorbisCredential?
    func saveCredential(_ credential: CorbisCredential) async throws
    func deleteCredential() async throws
}

/// Failures surfaced by a credential store. None of these carry the token.
public enum CorbisCredentialStoreError: Error, Equatable, Sendable {
    case writeFailed
    case deleteFailed
    case corrupted
    case temporarilyUnavailable
}

/// Narrow Keychain seam for the dedicated Corbis credential item. Keeping bearer tokens out
/// of the shared runtime cache prevents an old cache ACL from making reconnect impossible.
protocol CorbisCredentialKeychainOperating: Sendable {
    func load(service: String, account: String) -> CorbisCredentialKeychainLoadResult
    func save(data: Data, service: String, account: String) -> Bool
    func delete(service: String, account: String) -> CorbisCredentialKeychainDeleteResult
}

enum CorbisCredentialKeychainLoadResult: Sendable {
    case found(Data)
    case missing
    case temporarilyUnavailable
    case failed
}

enum CorbisCredentialKeychainDeleteResult: Sendable {
    case removed
    case missing
    case failed
}

private struct SystemCorbisCredentialKeychain: CorbisCredentialKeychainOperating {
    func load(service: String, account: String) -> CorbisCredentialKeychainLoadResult {
        guard !KeychainAccessGate.isDisabled else { return .temporarilyUnavailable }
        #if os(macOS)
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
        ]
        KeychainNoUIQuery.apply(to: &query)

        var result: CFTypeRef?
        switch KeychainSecurity.copyMatching(query as CFDictionary, &result) {
        case errSecSuccess:
            guard let data = result as? Data, !data.isEmpty else { return .failed }
            return .found(data)
        case errSecItemNotFound:
            return .missing
        case errSecInteractionNotAllowed:
            return .temporarilyUnavailable
        default:
            return .failed
        }
        #else
        .missing
        #endif
    }

    func save(data: Data, service: String, account: String) -> Bool {
        guard !KeychainAccessGate.isDisabled else { return false }
        #if os(macOS)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        // A reconnect is user initiated, so it must not force Keychain's no-UI failure
        // policy. This matches the app's established manual-token store pattern: no custom
        // ACL and no interaction-disabled authentication context on writes.
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let updateStatus = KeychainSecurity.update(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        guard updateStatus == errSecItemNotFound else { return false }

        var addQuery = query
        for (key, value) in attributes {
            addQuery[key] = value
        }
        return KeychainSecurity.add(addQuery as CFDictionary, nil) == errSecSuccess
        #else
        false
        #endif
    }

    func delete(service: String, account: String) -> CorbisCredentialKeychainDeleteResult {
        guard !KeychainAccessGate.isDisabled else { return .failed }
        #if os(macOS)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        return switch KeychainSecurity.delete(query as CFDictionary) {
        case errSecSuccess:
            .removed
        case errSecItemNotFound:
            .missing
        default:
            .failed
        }
        #else
        return .missing
        #endif
    }
}

/// Keychain-backed credential store using a dedicated generic-password item.
///
/// The original credential lived in the ACL-managed runtime cache. It remains a read-only
/// migration fallback, but new bearer credentials use a dedicated account without that
/// legacy ACL so an ad-hoc rebuild cannot strand a user's connection.
public struct KeychainCorbisCredentialStore: CorbisCredentialStoring {
    static let currentService = AppIdentity.keychainSecretsService
    static let currentAccount = "corbis-mcp-credential-v2"
    /// Read-only compatibility key. Never reuse it for writes because a stale ACL can make
    /// the record inaccessible until the user explicitly replaces the connection.
    static let legacyKey = KeychainCacheStore.Key(category: "corbis", identifier: "mcp-credential")
    private let keychain: any CorbisCredentialKeychainOperating

    public init() {
        self.keychain = SystemCorbisCredentialKeychain()
    }

    init(keychain: any CorbisCredentialKeychainOperating) {
        self.keychain = keychain
    }

    public func loadCredential() async throws -> CorbisCredential? {
        switch self.keychain.load(service: Self.currentService, account: Self.currentAccount) {
        case let .found(data):
            guard let credential = try? Self.decoder.decode(CorbisCredential.self, from: data) else {
                throw CorbisCredentialStoreError.corrupted
            }
            return credential
        case .missing:
            break
        case .temporarilyUnavailable:
            throw CorbisCredentialStoreError.temporarilyUnavailable
        case .failed:
            throw CorbisCredentialStoreError.corrupted
        }

        // A readable original record keeps existing users connected. An inaccessible original
        // record is intentionally ignored so reconnect can recover into the new dedicated item.
        switch KeychainCacheStore.load(key: Self.legacyKey, as: CorbisCredential.self) {
        case let .found(credential):
            return credential
        case .missing:
            return nil
        case .temporarilyUnavailable:
            return nil
        case .invalid:
            return nil
        }
    }

    public func saveCredential(_ credential: CorbisCredential) async throws {
        guard let data = try? Self.encoder.encode(credential),
              self.keychain.save(data: data, service: Self.currentService, account: Self.currentAccount)
        else {
            throw CorbisCredentialStoreError.writeFailed
        }
    }

    public func deleteCredential() async throws {
        let currentResult = self.keychain.delete(service: Self.currentService, account: Self.currentAccount)
        guard currentResult != .failed else {
            throw CorbisCredentialStoreError.deleteFailed
        }

        let legacyResult = KeychainCacheStore.clearResult(key: Self.legacyKey)
        if currentResult == .missing, legacyResult == .failed {
            // With no v2 entry, a legacy credential can still be active. Do not claim the
            // connection was removed if its accessible record could not be deleted.
            throw CorbisCredentialStoreError.deleteFailed
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
