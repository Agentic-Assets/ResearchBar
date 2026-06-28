import Crypto
import Foundation

/// Stable identity for a connected Corbis account, used to key per-account caches.
///
/// The cache key derives from `accountID` when known, otherwise from a SHA-256
/// fingerprint of the bearer token. The raw token is never stored here and never
/// reconstructable from `tokenFingerprint`. See guide §9 (cache key derives from a
/// hash of the token, never the raw token).
public struct CorbisAccountIdentity: Equatable, Sendable, Codable {
    /// Server-provided account identifier when the credential is linked, else nil.
    public let accountID: String?
    /// Hex SHA-256 of the bearer token. One-way; never the raw token.
    public let tokenFingerprint: String

    public init(accountID: String?, tokenFingerprint: String) {
        self.accountID = accountID
        self.tokenFingerprint = tokenFingerprint
    }

    /// Component used inside cache keys: the account id when present, else an
    /// `anon-` prefixed token fingerprint so anonymous sessions stay isolated.
    public var cacheKeyComponent: String {
        self.accountID ?? "anon-\(self.tokenFingerprint)"
    }

    /// One-way SHA-256 hex digest of the token. Never returns the raw token.
    public static func fingerprint(forToken token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Build an identity from an optional account id and a bearer token. The token
    /// is consumed only to compute the fingerprint and is not retained.
    public static func make(accountID: String?, token: String) -> CorbisAccountIdentity {
        CorbisAccountIdentity(accountID: accountID, tokenFingerprint: self.fingerprint(forToken: token))
    }
}
