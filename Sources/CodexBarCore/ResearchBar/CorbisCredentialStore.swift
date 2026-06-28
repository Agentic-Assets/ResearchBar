import Foundation

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

/// Keychain-backed credential store built on `KeychainCacheStore`.
///
/// This is a struct (not an actor) so the `@TaskLocal` service override used in
/// tests propagates synchronously into the underlying `KeychainCacheStore` calls,
/// keeping the no-UI keychain query and test-store seam available without prompts.
public struct KeychainCorbisCredentialStore: CorbisCredentialStoring {
    private let key = KeychainCacheStore.Key(category: "corbis", identifier: "mcp-credential")

    public init() {}

    public func loadCredential() async throws -> CorbisCredential? {
        switch KeychainCacheStore.load(key: self.key, as: CorbisCredential.self) {
        case let .found(credential):
            return credential
        case .missing:
            return nil
        case .temporarilyUnavailable:
            throw CorbisCredentialStoreError.temporarilyUnavailable
        case .invalid:
            throw CorbisCredentialStoreError.corrupted
        }
    }

    public func saveCredential(_ credential: CorbisCredential) async throws {
        guard KeychainCacheStore.storeResult(key: self.key, entry: credential) else {
            throw CorbisCredentialStoreError.writeFailed
        }
    }

    public func deleteCredential() async throws {
        switch KeychainCacheStore.clearResult(key: self.key) {
        case .removed, .missing:
            return
        case .failed:
            throw CorbisCredentialStoreError.deleteFailed
        }
    }
}
