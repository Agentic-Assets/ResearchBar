import Foundation
import Testing
@testable import CodexBarCore

struct ResearchPulseRefreshCoordinatorTests {
    private static let baseURL = URL(string: "https://corbis.test")!

    private static func http(_ status: Int, url: URL?) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url ?? ResearchPulseRefreshCoordinatorTests.baseURL,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: nil)!
    }

    private static func credential(accountID: String = "acct-1", token: String = "tok-1") -> CorbisCredential {
        CorbisCredential(
            token: token,
            accountID: accountID,
            displayEmail: "researcher@example.edu",
            createdAt: Date(),
            lastValidatedAt: nil)
    }

    private static func successEnvelope() throws -> Data {
        let fixture = try ResearchBarFixtures.data("pulse-linked-tracked")
        let structured = try #require(String(bytes: fixture, encoding: .utf8))
        let envelope = """
        {"jsonrpc":"2.0","id":"1","result":{"structuredContent":\(structured),"content":[]}}
        """
        return Data(envelope.utf8)
    }

    // MARK: - Counting transport

    private actor CallCounter {
        private(set) var hits = 0
        func bump() {
            self.hits += 1
        }
    }

    /// Gate that holds the first transport call until the test opens it.
    private actor Gate {
        private var continuation: CheckedContinuation<Void, Never>?
        private var opened = false

        func wait() async {
            if self.opened { return }
            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }

        func open() {
            self.opened = true
            self.continuation?.resume()
            self.continuation = nil
        }
    }

    // MARK: - Tests

    @Test
    func menuOpenWithFreshCacheDoesNotHitTransport() async throws {
        let counter = CallCounter()
        let transport = ProviderHTTPTransportHandler { request in
            await counter.bump()
            return try (Self.successEnvelope(), Self.http(200, url: request.url))
        }
        let client = CorbisMCPClient(baseURL: Self.baseURL, transport: transport)

        let store = InMemoryCorbisCredentialStore(credential: Self.credential())
        let cache = InMemoryResearchPulseCache()
        let identity = Self.credential().accountIdentity()
        let key = ResearchPulseCacheKey(identity: identity)

        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")
        let entry = try ResearchPulseCacheEntry(
            rawJSON: ResearchBarFixtures.data("pulse-linked-tracked"),
            pulse: pulse,
            etag: pulse.etag,
            fetchedAt: Date(),
            staleAfter: Date().addingTimeInterval(3600),
            accountID: identity.accountID)
        try await cache.store(entry, for: key)

        let coordinator = ResearchPulseRefreshCoordinator(
            credentialStore: store,
            cache: cache,
            client: client)

        let input = await coordinator.refreshOnMenuOpen()

        #expect(await counter.hits == 0)
        guard case let .loaded(loadedPulse, fromStaleCache) = input else {
            Issue.record("expected loaded, got \(input)")
            return
        }
        #expect(fromStaleCache == false)
        #expect(loadedPulse == pulse)
    }

    @Test
    func concurrentManualRefreshesCoalesceToOneTransportHit() async throws {
        let counter = CallCounter()
        let gate = Gate()
        let transport = ProviderHTTPTransportHandler { request in
            await counter.bump()
            await gate.wait()
            return try (Self.successEnvelope(), Self.http(200, url: request.url))
        }
        let client = CorbisMCPClient(baseURL: Self.baseURL, transport: transport)

        let store = InMemoryCorbisCredentialStore(credential: Self.credential())
        let cache = InMemoryResearchPulseCache()
        let coordinator = ResearchPulseRefreshCoordinator(
            credentialStore: store,
            cache: cache,
            client: client)

        async let first = coordinator.manualRefresh()
        async let second = coordinator.manualRefresh()

        // Give both callers time to enter the actor and coalesce on one in-flight task.
        try await Task.sleep(nanoseconds: 80_000_000)
        await gate.open()

        let results = await [first, second]
        #expect(await counter.hits == 1)
        for result in results {
            guard case .loaded = result else {
                Issue.record("expected loaded, got \(result)")
                return
            }
        }
    }

    @Test
    func creditLimitedResultDoesNotTriggerAutoRefreshLoop() async {
        let counter = CallCounter()
        let transport = ProviderHTTPTransportHandler { request in
            await counter.bump()
            let envelope = """
            {"jsonrpc":"2.0","id":"1","error":{"code":-32603,\
            "message":"Insufficient credits","data":{"code":"INSUFFICIENT_CREDITS"}}}
            """
            return (Data(envelope.utf8), Self.http(200, url: request.url))
        }
        let client = CorbisMCPClient(baseURL: Self.baseURL, transport: transport)

        let store = InMemoryCorbisCredentialStore(credential: Self.credential())
        let cache = InMemoryResearchPulseCache()
        let coordinator = ResearchPulseRefreshCoordinator(
            credentialStore: store,
            cache: cache,
            client: client)

        let input = await coordinator.refreshOnMenuOpen()

        #expect(await counter.hits == 1)
        guard case let .creditLimited(pulse) = input else {
            Issue.record("expected creditLimited, got \(input)")
            return
        }
        #expect(pulse == nil)
    }

    @Test
    func notConnectedReturnsNotConnected() async {
        let counter = CallCounter()
        let transport = ProviderHTTPTransportHandler { request in
            await counter.bump()
            return try (Self.successEnvelope(), Self.http(200, url: request.url))
        }
        let client = CorbisMCPClient(baseURL: Self.baseURL, transport: transport)

        let store = InMemoryCorbisCredentialStore(credential: nil)
        let cache = InMemoryResearchPulseCache()
        let coordinator = ResearchPulseRefreshCoordinator(
            credentialStore: store,
            cache: cache,
            client: client)

        #expect(await coordinator.refreshOnMenuOpen() == .notConnected)
        #expect(await coordinator.manualRefresh() == .notConnected)
        #expect(await coordinator.currentMenuInput() == .notConnected)
        #expect(await counter.hits == 0)
    }
}
