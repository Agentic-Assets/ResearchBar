import Foundation

// GRDB decision: a SQLite/GRDB-backed cache is deferred pending co-founder sign-off.
// No new SwiftPM dependency is added here. The `ResearchPulseCaching` protocol is the
// swap seam: a future GRDB store would conform to it without touching call sites. Until
// then, ship the in-memory and per-file JSON implementations below.

/// Identifies one cached pulse payload. Keys include the Corbis account identity so a
/// token or account change cannot read another account's cached data.
public struct ResearchPulseCacheKey: Hashable, Sendable {
    /// The account component (account id, or `anon-<fingerprint>`).
    public let account: String
    public let toolName: String
    public let payloadVersion: String

    public init(account: String, toolName: String = "get_research_pulse", payloadVersion: String = "v0") {
        self.account = account
        self.toolName = toolName
        self.payloadVersion = payloadVersion
    }

    public init(
        identity: CorbisAccountIdentity,
        toolName: String = "get_research_pulse",
        payloadVersion: String = "v0")
    {
        self.init(account: identity.cacheKeyComponent, toolName: toolName, payloadVersion: payloadVersion)
    }

    /// Stable string used as the storage handle (dictionary key / file name stem).
    public var storageKey: String {
        "\(self.account)__\(self.toolName)__\(self.payloadVersion)"
    }
}

/// A cached pulse plus its freshness metadata. Persists the raw JSON (not the decoded
/// model) so callers can re-decode against the current schema on read.
public struct ResearchPulseCacheEntry: Equatable, Sendable {
    public let rawJSON: Data
    public let pulse: ResearchPulse
    public let etag: String
    public let fetchedAt: Date
    public let staleAfter: Date
    public let schemaVersion: String
    public let accountID: String?

    public static let currentSchemaVersion = "v0"

    public init(
        rawJSON: Data,
        pulse: ResearchPulse,
        etag: String,
        fetchedAt: Date,
        staleAfter: Date,
        schemaVersion: String = ResearchPulseCacheEntry.currentSchemaVersion,
        accountID: String?)
    {
        self.rawJSON = rawJSON
        self.pulse = pulse
        self.etag = etag
        self.fetchedAt = fetchedAt
        self.staleAfter = staleAfter
        self.schemaVersion = schemaVersion
        self.accountID = accountID
    }

    /// Build an entry from a decoded pulse, taking etag/fetchedAt/staleAfter from the
    /// pulse itself and the account id from the supplied identity.
    public init(pulse: ResearchPulse, rawJSON: Data, identity: CorbisAccountIdentity) {
        self.init(
            rawJSON: rawJSON,
            pulse: pulse,
            etag: pulse.etag,
            fetchedAt: pulse.fetchedAt,
            staleAfter: pulse.staleAfter,
            schemaVersion: ResearchPulseCacheEntry.currentSchemaVersion,
            accountID: identity.accountID)
    }

    /// Server-driven freshness: fresh strictly before `staleAfter`.
    public func isFresh(now: Date) -> Bool {
        now < self.staleAfter
    }
}

/// Coarse freshness classification for callers that prefer an enum over a Bool.
public enum CacheFreshness: Equatable, Sendable {
    case fresh
    case stale
}

/// Storage seam for cached pulses. Implementations isolate entries per account.
public protocol ResearchPulseCaching: Sendable {
    func entry(for key: ResearchPulseCacheKey) async -> ResearchPulseCacheEntry?
    func store(_ entry: ResearchPulseCacheEntry, for key: ResearchPulseCacheKey) async throws
    func invalidate(for key: ResearchPulseCacheKey) async
    func clearAll() async
}

/// In-memory cache keyed by `key.storageKey`. Includes a cross-account guard: a stored
/// entry whose `accountID` disagrees with the requested key's account is treated as a
/// miss, so a stale entry can never bleed across accounts.
public actor InMemoryResearchPulseCache: ResearchPulseCaching {
    private var entries: [String: ResearchPulseCacheEntry] = [:]

    public init() {}

    public func entry(for key: ResearchPulseCacheKey) async -> ResearchPulseCacheEntry? {
        guard let entry = self.entries[key.storageKey] else { return nil }
        if let storedID = entry.accountID, storedID != key.account {
            return nil
        }
        return entry
    }

    public func store(_ entry: ResearchPulseCacheEntry, for key: ResearchPulseCacheKey) async throws {
        self.entries[key.storageKey] = entry
    }

    public func invalidate(for key: ResearchPulseCacheKey) async {
        self.entries[key.storageKey] = nil
    }

    public func clearAll() async {
        self.entries.removeAll()
    }
}
