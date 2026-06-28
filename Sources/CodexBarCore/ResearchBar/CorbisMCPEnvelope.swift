import Foundation

// MARK: - JSONValue

/// A minimal, fully-`Codable` JSON value. Used to capture `result.structuredContent`
/// from the Corbis MCP envelope so the client can (a) peek `structuredContent["status"]`
/// for a tool-level error and (b) re-encode the value to `Data` and decode a
/// `ResearchPulse` from it. Numbers are modeled as `Double`; integral values round-trip
/// through `JSONEncoder` without a fractional part, so `Int` fields decode cleanly.
public enum JSONValue: Codable, Equatable, Sendable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case let .bool(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
        case let .string(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        }
    }

    // MARK: Helpers

    /// Member access for object values; nil for any non-object or missing key.
    public subscript(_ key: String) -> JSONValue? {
        if case let .object(dictionary) = self { return dictionary[key] }
        return nil
    }

    /// The wrapped string when this is a `.string`, else nil.
    public var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }

    /// Re-encode this value to canonical JSON bytes.
    public func encodedData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}

// MARK: - JSON-RPC envelope

/// The error half of a JSON-RPC 2.0 response (guide §7 failure mode 1). `data` is
/// captured as a `JSONValue` so structured fields (`code`, `tier`, `retryable`) can be
/// inspected without binding a concrete shape.
public struct JSONRPCErrorBody: Decodable, Equatable, Sendable {
    public let code: Int
    public let message: String
    public let data: JSONValue?
}

/// A decoded JSON-RPC 2.0 response. `Success` is a phantom marker for the structured
/// payload the caller intends to decode from `result.structuredContent`; the
/// `structuredContent` is captured as an opaque `JSONValue` here and decoded separately
/// (the pulse needs the lenient ISO-8601 decoder). Exactly one of `result`/`error` is
/// present in a well-formed envelope.
public struct JSONRPCResponse<Success: Decodable>: Decodable {
    public let result: Result?
    public let error: JSONRPCErrorBody?

    public struct Result: Decodable {
        public let structuredContent: JSONValue?
        public let content: [JSONValue]?
        public let meta: JSONValue?

        enum CodingKeys: String, CodingKey {
            case structuredContent
            case content
            case meta = "_meta"
        }
    }
}

// MARK: - tools/list envelope

/// Lightweight decode of a `tools/list` response. Only tool names are surfaced, for the
/// sparse credential-validation probe.
struct CorbisToolsListResponse: Decodable {
    struct Result: Decodable {
        struct Tool: Decodable {
            let name: String
        }

        let tools: [Tool]
    }

    let result: Result?
    let error: JSONRPCErrorBody?
}

// MARK: - Request builder

/// Encodes a Corbis MCP JSON-RPC request body (guide §2). `tools/call` carries
/// `params.name` and an `arguments` object (empty for `get_research_pulse`); `tools/list`
/// carries no params.
struct CorbisMCPRequestBody: Encodable {
    let jsonrpc: String
    let id: String
    let method: String
    let params: Params?

    struct Params: Encodable {
        let name: String
        let arguments: [String: JSONValue]
    }

    static func toolCall(
        id: String,
        toolName: String,
        arguments: [String: JSONValue] = [:]) -> CorbisMCPRequestBody
    {
        CorbisMCPRequestBody(
            jsonrpc: "2.0",
            id: id,
            method: "tools/call",
            params: Params(name: toolName, arguments: arguments))
    }

    static func toolsList(id: String) -> CorbisMCPRequestBody {
        CorbisMCPRequestBody(jsonrpc: "2.0", id: id, method: "tools/list", params: nil)
    }

    func encodedData() throws -> Data {
        try JSONEncoder().encode(self)
    }
}
