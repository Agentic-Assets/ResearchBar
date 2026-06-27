import Foundation

/// Live Corbis MCP client over the universal JSON-RPC endpoint (guide §2/§4/§7/§11).
///
/// Stateless and `Sendable`: it owns only a base URL and an injected transport, so tests
/// drive it with a mocked `ProviderHTTPTransport` and never touch the network. The bearer
/// token is used only to build the `Authorization` header; it is never decoded into, or
/// echoed by, any thrown `CorbisMCPError`.
public struct CorbisMCPResearchPulseResult: Equatable, Sendable {
    public let pulse: ResearchPulse
    public let rawJSON: Data

    public init(pulse: ResearchPulse, rawJSON: Data) {
        self.pulse = pulse
        self.rawJSON = rawJSON
    }
}

public struct CorbisMCPClient: Sendable {
    private let baseURL: URL
    private let transport: any ProviderHTTPTransport

    public init(baseURL: URL, transport: any ProviderHTTPTransport = ProviderHTTPClient.shared) {
        self.baseURL = baseURL
        self.transport = transport
    }

    private var endpointURL: URL {
        self.baseURL.appendingPathComponent("api/mcp/universal")
    }

    // MARK: - get_research_pulse

    /// Fetch and validate the research pulse. One billed call; failures throw a leak-safe
    /// `CorbisMCPError` and are refunded server-side. Never tight-loops.
    public func fetchResearchPulse(token: String) async throws -> ResearchPulse {
        try await self.fetchResearchPulseResult(token: token).pulse
    }

    /// Fetch and validate the research pulse, preserving the validated structured-content JSON
    /// for cache storage so future schema fields are not dropped by typed re-encoding.
    public func fetchResearchPulseResult(token: String) async throws -> CorbisMCPResearchPulseResult {
        let body = CorbisMCPRequestBody.toolCall(id: UUID().uuidString, toolName: "get_research_pulse")
        let request = try self.makeRequest(token: token, body: body)
        let response = try await self.transport.response(for: request, retryPolicy: .disabled)
        try Self.mapHTTPStatus(response.statusCode)

        let envelope: JSONRPCResponse<ResearchPulse>
        do {
            envelope = try JSONDecoder().decode(JSONRPCResponse<ResearchPulse>.self, from: response.data)
        } catch {
            throw CorbisMCPError.malformedResponse
        }

        if let rpcError = envelope.error {
            throw Self.mapJSONRPCError(rpcError)
        }

        guard let structured = envelope.result?.structuredContent else {
            throw CorbisMCPError.malformedResponse
        }

        // Re-encode the structured payload once; use it for the redaction scan and decode.
        let structuredData: Data
        do {
            structuredData = try structured.encodedData()
        } catch {
            throw CorbisMCPError.malformedResponse
        }

        // Defensive client-side redaction runs before anything is decoded or rendered.
        if !ResearchPulseRedactor.scanRawJSON(structuredData).isEmpty {
            throw CorbisMCPError.redactionFailed
        }

        // Tool-level error rides inside a normal HTTP 200 / result envelope.
        if structured["status"]?.stringValue == "error" {
            throw CorbisMCPError.safeToolError(rawMessage: structured["message"]?.stringValue)
        }

        let pulse: ResearchPulse
        do {
            pulse = try ResearchPulse.decode(structuredData)
        } catch {
            throw CorbisMCPError.decodeFailed
        }

        if !ResearchPulseRedactor.scan(pulse).isEmpty {
            throw CorbisMCPError.redactionFailed
        }
        guard pulse.isSemanticallyValid else {
            throw CorbisMCPError.semanticInvalid
        }
        return CorbisMCPResearchPulseResult(pulse: pulse, rawJSON: structuredData)
    }

    // MARK: - tools/list

    /// List available tool names via `tools/list`. Used for a sparse credential-validity
    /// probe; this call returns tool metadata only and is not billed as a pulse fetch.
    public func listToolNames(token: String) async throws -> [String] {
        let body = CorbisMCPRequestBody.toolsList(id: UUID().uuidString)
        let request = try self.makeRequest(token: token, body: body)
        let response = try await self.transport.response(for: request, retryPolicy: .disabled)
        try Self.mapHTTPStatus(response.statusCode)

        let envelope: CorbisToolsListResponse
        do {
            envelope = try JSONDecoder().decode(CorbisToolsListResponse.self, from: response.data)
        } catch {
            throw CorbisMCPError.malformedResponse
        }
        if let rpcError = envelope.error {
            throw Self.mapJSONRPCError(rpcError)
        }
        guard let result = envelope.result else {
            throw CorbisMCPError.malformedResponse
        }
        return result.tools.map(\.name)
    }

    // MARK: - Request construction

    private func makeRequest(token: String, body: CorbisMCPRequestBody) throws -> URLRequest {
        var request = URLRequest(url: self.endpointURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try body.encodedData()
        } catch {
            throw CorbisMCPError.malformedResponse
        }
        return request
    }

    // MARK: - Mapping

    private static func mapHTTPStatus(_ statusCode: Int) throws {
        switch statusCode {
        case 200:
            return
        case 400:
            throw CorbisMCPError.malformedResponse
        case 401:
            throw CorbisMCPError.invalidCredential
        case 402:
            throw CorbisMCPError.creditLimited
        case 429:
            throw CorbisMCPError.rateLimited
        default:
            // 500 and any other non-200 status are treated as a server failure.
            throw CorbisMCPError.server
        }
    }

    private static func mapJSONRPCError(_ error: JSONRPCErrorBody) -> CorbisMCPError {
        if self.looksCreditExhausted(error) {
            return .creditLimited
        }
        switch error.code {
        case -32001:
            return .invalidCredential
        case -32004:
            return .rateLimited
        case -32700, -32600, -32601, -32602:
            // Our request was rejected as malformed at the protocol layer.
            return .malformedResponse
        default:
            // -32603 (internal/tier/scope) and anything else collapse to a server failure.
            return .server
        }
    }

    /// A credit-exhaustion signal can arrive as a 402-style code, or as a `-32603`/internal
    /// error whose message or `data.code` mentions credits.
    private static func looksCreditExhausted(_ error: JSONRPCErrorBody) -> Bool {
        if error.code == 402 {
            return true
        }
        if error.message.lowercased().contains("credit") {
            return true
        }
        if let dataCode = error.data?["code"]?.stringValue?.lowercased(), dataCode.contains("credit") {
            return true
        }
        return false
    }
}
