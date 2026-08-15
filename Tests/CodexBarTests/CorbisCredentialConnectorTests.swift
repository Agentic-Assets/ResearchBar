import Foundation
import Testing
@testable import CodexBarCore

struct CorbisCredentialConnectorTests {
    private static let baseURL = URL(string: "https://corbis.test")!
    private static let oldToken = "corbis_mcp_existing"
    private static let candidateToken = "corbis_mcp_candidate"

    @Test
    func `rejected replacement keeps stored credential and cache`() async throws {
        let existing = Self.credential(token: Self.oldToken)
        let store = InMemoryCorbisCredentialStore(credential: existing)
        let cache = CacheSpy()
        let connector = Self.connector(store: store, cache: cache, statusCode: 401)

        let result = await connector.connect(token: Self.candidateToken)

        #expect(result == .invalidCredential)
        #expect(try await store.loadCredential() == existing)
        #expect(await cache.clearCount == 0)
    }

    @Test
    func `validated replacement is stored and clears prior cache`() async throws {
        let existing = Self.credential(token: Self.oldToken)
        let store = InMemoryCorbisCredentialStore(credential: existing)
        let cache = CacheSpy()
        let connector = Self.connector(store: store, cache: cache, statusCode: 200)

        let result = await connector.connect(token: "  \(Self.candidateToken)  ")

        guard case let .connected(credential) = result else {
            Issue.record("expected a connected result")
            return
        }
        #expect(credential.token == Self.candidateToken)
        #expect(credential.lastValidatedAt != nil)
        #expect(try await store.loadCredential() == credential)
        #expect(await cache.clearCount == 1)
    }

    @Test
    func `secure storage failure does not mislabel token as invalid`() async {
        let cache = CacheSpy()
        let connector = Self.connector(store: FailingCredentialStore(), cache: cache, statusCode: 200)

        let result = await connector.connect(token: Self.candidateToken)

        #expect(result == .storageUnavailableAfterValidation)
        #expect(await cache.clearCount == 0)
    }

    @Test
    func `temporary validation failure does not persist candidate`() async throws {
        let existing = Self.credential(token: Self.oldToken)
        let store = InMemoryCorbisCredentialStore(credential: existing)
        let cache = CacheSpy()
        let connector = Self.connector(store: store, cache: cache, statusCode: 500)

        let result = await connector.connect(token: Self.candidateToken)

        #expect(result == .validationUnavailable)
        #expect(try await store.loadCredential() == existing)
        #expect(await cache.clearCount == 0)
    }

    private static func credential(token: String) -> CorbisCredential {
        CorbisCredential(
            token: token,
            accountID: nil,
            displayEmail: nil,
            createdAt: Date(timeIntervalSince1970: 1),
            lastValidatedAt: nil)
    }

    private static func connector(
        store: some CorbisCredentialStoring,
        cache: some ResearchPulseCaching,
        statusCode: Int)
        -> CorbisCredentialConnector
    {
        let client = CorbisMCPClient(
            baseURL: Self.baseURL,
            transport: ProviderHTTPTransportHandler { request in
                let data = if statusCode == 200 {
                    Data("{\"jsonrpc\":\"2.0\",\"id\":\"1\",\"result\":{\"contents\":[]}}".utf8)
                } else {
                    Data()
                }
                let response = HTTPURLResponse(
                    url: request.url ?? Self.baseURL,
                    statusCode: statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil)!
                return (data, response)
            })
        return CorbisCredentialConnector(credentialStore: store, cache: cache, client: client)
    }
}

private actor CacheSpy: ResearchPulseCaching {
    private(set) var clearCount = 0

    func entry(for _: ResearchPulseCacheKey) async -> ResearchPulseCacheEntry? {
        nil
    }

    func store(_: ResearchPulseCacheEntry, for _: ResearchPulseCacheKey) async throws {}
    func invalidate(for _: ResearchPulseCacheKey) async {}

    func clearAll() async {
        self.clearCount += 1
    }
}

private actor FailingCredentialStore: CorbisCredentialStoring {
    func loadCredential() async throws -> CorbisCredential? {
        nil
    }

    func saveCredential(_: CorbisCredential) async throws {
        throw CorbisCredentialStoreError.writeFailed
    }

    func deleteCredential() async throws {}
}
