import Foundation
import Testing
@testable import CodexBarCore

struct ResearchPulseCacheTests {
    @Test
    func inMemoryStoreThenEntryReturnsIt() async throws {
        let cache = InMemoryResearchPulseCache()
        let identity = CorbisAccountIdentity.make(accountID: "acct-A", token: "tok-A")
        let (entry, key) = try Self.makeEntry(identity: identity)
        try await cache.store(entry, for: key)
        let loaded = await cache.entry(for: key)
        #expect(loaded == entry)
    }

    @Test
    func inMemoryAccountAKeyIsolatedFromAccountB() async throws {
        let cache = InMemoryResearchPulseCache()
        let identityA = CorbisAccountIdentity.make(accountID: "acct-A", token: "tok-A")
        let identityB = CorbisAccountIdentity.make(accountID: "acct-B", token: "tok-B")
        let (entryA, keyA) = try Self.makeEntry(identity: identityA)
        try await cache.store(entryA, for: keyA)

        let keyB = ResearchPulseCacheKey(identity: identityB)
        #expect(await cache.entry(for: keyB) == nil)
    }

    @Test
    func tokenChangeProducesDifferentKeyAndNoCrossRead() async throws {
        let cache = InMemoryResearchPulseCache()
        let identityOne = CorbisAccountIdentity.make(accountID: nil, token: "tok-1")
        let identityTwo = CorbisAccountIdentity.make(accountID: nil, token: "tok-2")
        #expect(identityOne.cacheKeyComponent != identityTwo.cacheKeyComponent)

        let keyOne = ResearchPulseCacheKey(identity: identityOne)
        let keyTwo = ResearchPulseCacheKey(identity: identityTwo)
        #expect(keyOne.storageKey != keyTwo.storageKey)

        let (entryOne, _) = try Self.makeEntry(identity: identityOne)
        try await cache.store(entryOne, for: keyOne)
        #expect(await cache.entry(for: keyTwo) == nil)
    }

    @Test
    func isFreshHonorsServerStaleAfter() throws {
        let identity = CorbisAccountIdentity.make(accountID: "a", token: "t")
        let (entry, _) = try Self.makeEntry(identity: identity)
        #expect(entry.isFresh(now: entry.staleAfter.addingTimeInterval(-1)))
        #expect(!entry.isFresh(now: entry.staleAfter.addingTimeInterval(1)))
    }

    @Test
    func invalidateRemovesEntry() async throws {
        let cache = InMemoryResearchPulseCache()
        let identity = CorbisAccountIdentity.make(accountID: "a", token: "t")
        let (entry, key) = try Self.makeEntry(identity: identity)
        try await cache.store(entry, for: key)
        await cache.invalidate(for: key)
        #expect(await cache.entry(for: key) == nil)
    }

    @Test
    func clearAllEmptiesCache() async throws {
        let cache = InMemoryResearchPulseCache()
        let identity = CorbisAccountIdentity.make(accountID: "a", token: "t")
        let (entry, key) = try Self.makeEntry(identity: identity)
        try await cache.store(entry, for: key)
        await cache.clearAll()
        #expect(await cache.entry(for: key) == nil)
    }

    @Test
    func fileCachePersistsAcrossInstancesPreservingMetadata() async throws {
        let directory = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let identity = CorbisAccountIdentity.make(accountID: "acct-file", token: "tok-file")
        let (entry, key) = try Self.makeEntry(identity: identity)

        let writer = FileResearchPulseCache(directory: directory)
        try await writer.store(entry, for: key)

        let reader = FileResearchPulseCache(directory: directory)
        let loaded = try #require(await reader.entry(for: key))
        #expect(loaded.etag == entry.etag)
        #expect(loaded.fetchedAt == entry.fetchedAt)
        #expect(loaded.staleAfter == entry.staleAfter)
        #expect(loaded.pulse == entry.pulse)
        #expect(loaded == entry)
    }

    @Test
    func fileCacheStaleEntryRoundTrips() async throws {
        let directory = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let identity = CorbisAccountIdentity.make(accountID: "acct-stale", token: "tok-stale")
        let staleAfter = Date(timeIntervalSince1970: 1_600_000_000)
        let (entry, key) = try Self.makeEntry(identity: identity, staleAfter: staleAfter)

        let writer = FileResearchPulseCache(directory: directory)
        try await writer.store(entry, for: key)

        let reader = FileResearchPulseCache(directory: directory)
        let loaded = try #require(await reader.entry(for: key))
        #expect(loaded.staleAfter == staleAfter)
        #expect(!loaded.isFresh(now: Date()))
    }

    @Test
    func fileCachePreservesFractionalSecondTimestamps() async throws {
        let directory = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let identity = CorbisAccountIdentity.make(accountID: "acct-frac", token: "tok-frac")
        // pulse-linked-tracked.json uses fractional-second ISO-8601 ("...:00.512Z").
        let (entry, key) = try Self.makeEntry(name: "pulse-linked-tracked", identity: identity)

        let writer = FileResearchPulseCache(directory: directory)
        try await writer.store(entry, for: key)

        let reader = FileResearchPulseCache(directory: directory)
        let loaded = try #require(await reader.entry(for: key))
        #expect(loaded.fetchedAt == entry.fetchedAt)
        #expect(loaded.staleAfter == entry.staleAfter)
    }

    @Test
    func fileCacheRoundTripsServerBytesPulseExactly() async throws {
        let directory = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let identity = CorbisAccountIdentity.make(accountID: "acct-reenc", token: "tok-reenc")
        // pulse-linked-tracked.json uses fractional-second ISO-8601 ("...:00.512Z"). The
        // refresh coordinator caches the server's validated structured-content bytes
        // (CorbisMCPClient.fetchResearchPulseResult.rawJSON); the fixture bytes stand in for
        // those here. On read FileResearchPulseCache reconstructs the pulse via
        // ResearchPulse.decode(rawJSON), so it must equal the original with exact
        // fetchedAt/staleAfter and no fractional-second loss.
        let data = try ResearchBarFixtures.data("pulse-linked-tracked")
        let pulse = try ResearchPulse.decode(data)
        let entry = ResearchPulseCacheEntry(pulse: pulse, rawJSON: data, identity: identity)
        let key = ResearchPulseCacheKey(identity: identity)

        let writer = FileResearchPulseCache(directory: directory)
        try await writer.store(entry, for: key)

        let reader = FileResearchPulseCache(directory: directory)
        let loaded = try #require(await reader.entry(for: key))
        #expect(loaded.pulse == pulse)
        #expect(loaded.pulse.fetchedAt == pulse.fetchedAt)
        #expect(loaded.pulse.staleAfter == pulse.staleAfter)
    }

    @Test
    func fileCacheDifferentTokenDoesNotCrossRead() async throws {
        let directory = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let identityOne = CorbisAccountIdentity.make(accountID: nil, token: "tok-file-1")
        let identityTwo = CorbisAccountIdentity.make(accountID: nil, token: "tok-file-2")
        let (entryOne, keyOne) = try Self.makeEntry(identity: identityOne)

        let cache = FileResearchPulseCache(directory: directory)
        try await cache.store(entryOne, for: keyOne)

        let keyTwo = ResearchPulseCacheKey(identity: identityTwo)
        #expect(await cache.entry(for: keyTwo) == nil)
    }

    // MARK: - Helpers

    private static func makeEntry(
        name: String = "pulse-linked-not-tracked",
        identity: CorbisAccountIdentity,
        staleAfter: Date? = nil) throws -> (ResearchPulseCacheEntry, ResearchPulseCacheKey)
    {
        let data = try ResearchBarFixtures.data(name)
        let pulse = try ResearchPulse.decode(data)
        let entry = if let staleAfter {
            ResearchPulseCacheEntry(
                rawJSON: data,
                pulse: pulse,
                etag: pulse.etag,
                fetchedAt: pulse.fetchedAt,
                staleAfter: staleAfter,
                accountID: identity.accountID)
        } else {
            ResearchPulseCacheEntry(pulse: pulse, rawJSON: data, identity: identity)
        }
        let key = ResearchPulseCacheKey(identity: identity)
        return (entry, key)
    }

    private static func makeTempDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("rb-pulse-cache-\(UUID().uuidString)", isDirectory: true)
    }
}
