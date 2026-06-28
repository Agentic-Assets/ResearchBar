import Foundation
import Testing
@testable import CodexBarCore

struct CorbisMCPClientTests {
    // MARK: - Helpers

    private static let baseURL = URL(string: "https://corbis.test")!
    private static let token = "corbis_mcp_supersecrettoken_value"

    private static func http(_ status: Int, url: URL?) -> HTTPURLResponse {
        HTTPURLResponse(
            url: url ?? CorbisMCPClientTests.baseURL,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: nil)!
    }

    /// Wrap a structured-content fixture (raw JSON bytes) in a success JSON-RPC envelope.
    private static func successEnvelope(structuredFixture name: String) throws -> Data {
        let fixture = try ResearchBarFixtures.data(name)
        let structured = try #require(String(bytes: fixture, encoding: .utf8))
        let envelope = """
        {"jsonrpc":"2.0","id":"1","result":{"structuredContent":\(structured),\
        "content":[{"type":"text","text":"digest"}],"_meta":{"cached":false}}}
        """
        return Data(envelope.utf8)
    }

    private static func client(
        capturing captured: (@Sendable (URLRequest) -> Void)? = nil,
        respond: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) -> CorbisMCPClient
    {
        let transport = ProviderHTTPTransportHandler { request in
            captured?(request)
            return try await respond(request)
        }
        return CorbisMCPClient(baseURL: CorbisMCPClientTests.baseURL, transport: transport)
    }

    // MARK: - Request shape

    @Test
    func requestEncodesToolsCallWithEmptyArguments() async throws {
        let box = RequestBox()
        let client = Self.client(capturing: { box.set($0) }, respond: { request in
            let envelope = try Self.successEnvelope(structuredFixture: "pulse-linked-tracked")
            return (envelope, Self.http(200, url: request.url))
        })

        _ = try await client.fetchResearchPulse(token: Self.token)

        let request = try #require(box.value)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://corbis.test/api/mcp/universal")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(Self.token)")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(request.httpBody)
        let decoded = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(decoded?["method"] as? String == "tools/call")
        let params = try #require(decoded?["params"] as? [String: Any])
        #expect(params["name"] as? String == "get_research_pulse")
        let arguments = try #require(params["arguments"] as? [String: Any])
        #expect(arguments.isEmpty)
    }

    // MARK: - Success

    @Test
    func successReturnsDecodedPulse() async throws {
        let client = Self.client { request in
            let envelope = try Self.successEnvelope(structuredFixture: "pulse-linked-tracked")
            return (envelope, Self.http(200, url: request.url))
        }

        let pulse = try await client.fetchResearchPulse(token: Self.token)
        #expect(pulse.displayName == "Dr. Rhea Calloway")
        #expect(pulse.totalCitations == 1284)
        #expect(pulse.citationHistoryStatus == .tracked)
        #expect(pulse.hasRenderableTrend)
    }

    // MARK: - HTTP status mapping

    @Test
    func unauthorizedMapsToInvalidCredential() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(401, url: request.url))
        }
        await #expect(throws: CorbisMCPError.invalidCredential) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func tooManyRequestsMapsToRateLimited() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(429, url: request.url))
        }
        await #expect(throws: CorbisMCPError.rateLimited) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func paymentRequiredMapsToCreditLimited() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(402, url: request.url))
        }
        await #expect(throws: CorbisMCPError.creditLimited) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func serverErrorMapsToServer() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(500, url: request.url))
        }
        await #expect(throws: CorbisMCPError.server) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func badRequestMapsToMalformedResponse() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(400, url: request.url))
        }
        await #expect(throws: CorbisMCPError.malformedResponse) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    // MARK: - JSON-RPC error mapping

    @Test
    func insufficientCreditsErrorMapsToCreditLimited() async throws {
        let client = Self.client { request in
            let envelope = """
            {"jsonrpc":"2.0","id":"1","error":{"code":-32603,\
            "message":"Insufficient credits for this request",\
            "data":{"code":"INSUFFICIENT_CREDITS","retryable":false}}}
            """
            return (Data(envelope.utf8), Self.http(200, url: request.url))
        }
        await #expect(throws: CorbisMCPError.creditLimited) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func authJSONRPCErrorMapsToInvalidCredential() async throws {
        let client = Self.client { request in
            let envelope = """
            {"jsonrpc":"2.0","id":"1","error":{"code":-32001,"message":"Authentication required"}}
            """
            return (Data(envelope.utf8), Self.http(200, url: request.url))
        }
        await #expect(throws: CorbisMCPError.invalidCredential) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    // MARK: - Tool-level error

    @Test
    func toolLevelStatusErrorMapsToToolError() async throws {
        let client = Self.client { request in
            let envelope = """
            {"jsonrpc":"2.0","id":"1","result":{"structuredContent":\
            {"status":"error","message":"Profile temporarily unavailable"},"content":[]}}
            """
            return (Data(envelope.utf8), Self.http(200, url: request.url))
        }

        await #expect(throws: CorbisMCPError.self) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }

        do {
            _ = try await client.fetchResearchPulse(token: Self.token)
            Issue.record("expected a tool-level error")
        } catch let error as CorbisMCPError {
            guard case let .toolError(message) = error else {
                Issue.record("expected toolError, got \(error)")
                return
            }
            #expect(message == "Profile temporarily unavailable")
        }
    }

    @Test
    func toolLevelStatusErrorSanitizesTokenLikeMessages() async throws {
        let client = Self.client { request in
            let envelope = """
            {"jsonrpc":"2.0","id":"1","result":{"structuredContent":\
            {"status":"error","message":"Bearer \(Self.token) was rejected"},"content":[]}}
            """
            return (Data(envelope.utf8), Self.http(200, url: request.url))
        }

        do {
            _ = try await client.fetchResearchPulse(token: Self.token)
            Issue.record("expected a tool-level error")
        } catch let error as CorbisMCPError {
            guard case let .toolError(message) = error else {
                Issue.record("expected toolError, got \(error)")
                return
            }
            #expect(message == CorbisMCPError.genericToolMessage)
            #expect(!message.contains(Self.token))
            #expect(!message.lowercased().contains("bearer"))
            #expect(!message.lowercased().contains("corbis_mcp_"))
        }
    }

    // MARK: - Redaction

    @Test
    func leakLikeStructuredContentThrowsRedactionFailedAndNeverReturnsPulse() async throws {
        let client = Self.client { request in
            let envelope = try Self.successEnvelope(structuredFixture: "pulse-leak-like")
            return (envelope, Self.http(200, url: request.url))
        }

        await #expect(throws: CorbisMCPError.redactionFailed) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func thrownErrorsNeverLeakTokenOrBackendNamesOrAuthorID() async throws {
        let client = Self.client { request in
            let envelope = try Self.successEnvelope(structuredFixture: "pulse-leak-like")
            return (envelope, Self.http(200, url: request.url))
        }

        do {
            _ = try await client.fetchResearchPulse(token: Self.token)
            Issue.record("expected a redaction failure")
        } catch {
            let described = String(describing: error)
            #expect(!described.contains(Self.token))
            #expect(!described.lowercased().contains("openalex"))
            #expect(!described.contains("A5012345678"))
        }
    }

    // MARK: - Request capture box

    private final class RequestBox: @unchecked Sendable {
        private let lock = NSLock()
        private var stored: URLRequest?

        func set(_ request: URLRequest) {
            self.lock.lock()
            defer { self.lock.unlock() }
            self.stored = request
        }

        var value: URLRequest? {
            self.lock.lock()
            defer { self.lock.unlock() }
            return self.stored
        }
    }
}
