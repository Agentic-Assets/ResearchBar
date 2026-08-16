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
        return try self.successEnvelope(structuredData: fixture)
    }

    private static func successEnvelope(structuredData: Data) throws -> Data {
        let fixture = structuredData
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
    func `request encodes tools call with empty arguments`() async throws {
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

    @Test
    func `credential validation uses protected non-billed resource`() async throws {
        let box = RequestBox()
        let client = Self.client(capturing: { box.set($0) }, respond: { request in
            let envelope = """
            {"jsonrpc":"2.0","id":"1","result":{"contents":[]}}
            """
            return (Data(envelope.utf8), Self.http(200, url: request.url))
        })

        try await client.validateCredential(token: Self.token)

        let request = try #require(box.value)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://corbis.test/api/mcp/universal")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(Self.token)")

        let body = try #require(request.httpBody)
        let decoded = try #require(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(decoded["method"] as? String == "resources/read")
        let params = try #require(decoded["params"] as? [String: Any])
        #expect(params["uri"] as? String == "docs://auth")
    }

    // MARK: - Success

    @Test
    func `success returns decoded pulse`() async throws {
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

    @Test
    func `future malformed fields remain client compatible`() async throws {
        let client = Self.client { request in
            let envelope = try Self.successEnvelope(structuredFixture: "pulse-contract-malformed-new-fields")
            return (envelope, Self.http(200, url: request.url))
        }

        let pulse = try await client.fetchResearchPulse(token: Self.token)
        #expect(pulse.resolvedCreditBalance == .limited(remaining: 9.25))
        #expect(pulse.resolvedIndexedWorksCount == 18)
    }

    // MARK: - HTTP status mapping

    @Test
    func `unauthorized maps to invalid credential`() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(401, url: request.url))
        }
        await #expect(throws: CorbisMCPError.invalidCredential) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func `too many requests maps to rate limited`() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(429, url: request.url))
        }
        await #expect(throws: CorbisMCPError.rateLimited) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func `payment required maps to credit limited`() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(402, url: request.url))
        }
        await #expect(throws: CorbisMCPError.creditLimited) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func `server error maps to server`() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(500, url: request.url))
        }
        await #expect(throws: CorbisMCPError.server) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func `bad request maps to malformed response`() async throws {
        let client = Self.client { request in
            (Data("{}".utf8), Self.http(400, url: request.url))
        }
        await #expect(throws: CorbisMCPError.malformedResponse) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    // MARK: - JSON-RPC error mapping

    @Test
    func `insufficient credits error maps to credit limited`() async throws {
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
    func `auth JSONRPC error maps to invalid credential`() async throws {
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
    func `tool level status error maps to tool error`() async throws {
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
    func `tool level status error sanitizes token like messages`() async throws {
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
    func `leak like structured content throws redaction failed and never returns pulse`() async throws {
        let client = Self.client { request in
            let envelope = try Self.successEnvelope(structuredFixture: "pulse-leak-like")
            return (envelope, Self.http(200, url: request.url))
        }

        await #expect(throws: CorbisMCPError.redactionFailed) {
            _ = try await client.fetchResearchPulse(token: Self.token)
        }
    }

    @Test
    func `live decoded pulse rejects short marker account identifier without echoing plan`() async throws {
        let base = try ResearchBarFixtures.data("pulse-contract-limited")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        let unsafePlan = "Academic acct=12"
        object["plan"] = unsafePlan
        let structuredData = try JSONSerialization.data(withJSONObject: object)
        let client = Self.client { request in
            let envelope = try Self.successEnvelope(structuredData: structuredData)
            return (envelope, Self.http(200, url: request.url))
        }

        do {
            _ = try await client.fetchResearchPulse(token: Self.token)
            Issue.record("expected a redaction failure")
        } catch let error as CorbisMCPError {
            #expect(error == .redactionFailed)
            #expect(!String(describing: error).contains(unsafePlan))
        } catch {
            Issue.record("unexpected error: \(String(describing: error))")
        }
    }

    @Test
    func `thrown errors never leak token or backend names or author ID`() async throws {
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
