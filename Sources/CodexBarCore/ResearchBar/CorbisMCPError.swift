import Foundation

/// Failures surfaced by the live Corbis MCP client. Every case is leak-safe: no case and
/// no associated value may carry the bearer token, raw payload bytes, an internal id, or a
/// backend/source name. `toolError.message` is sanitized to a safe server string (or a
/// generic fallback) before construction; never pass an unsanitized server string into it.
public enum CorbisMCPError: Error, Equatable, Sendable {
    /// Missing or invalid bearer token (HTTP 401 / JSON-RPC -32001).
    case invalidCredential
    /// Credits exhausted or insufficient; never auto-refresh on this.
    case creditLimited
    /// Rate limited (HTTP 429 / JSON-RPC -32004); calm message, never tight-loop.
    case rateLimited
    /// Server-side failure (HTTP 5xx, JSON-RPC internal/tier/scope, or other).
    case server
    /// The HTTP request was rejected as malformed, or the envelope could not be parsed.
    case malformedResponse
    /// The structured payload failed to decode into a `ResearchPulse`.
    case decodeFailed
    /// A client-side redaction scan tripped; the payload must never render.
    case redactionFailed
    /// The pulse decoded but failed semantic validation.
    case semanticInvalid
    /// A tool-level error (`structuredContent.status == "error"`). The message is a safe,
    /// pre-sanitized server string.
    case toolError(message: String)

    /// Generic, leak-free stand-in used whenever a server message cannot be vouched safe.
    public static let genericToolMessage = "The research service reported a problem."

    /// Build a `toolError` from a raw server message, dropping anything that trips the
    /// redactor (internal ids, backend/source names) or that is empty in favor of a
    /// generic, leak-free string. Use this instead of constructing `toolError` directly.
    public static func safeToolError(rawMessage: String?) -> CorbisMCPError {
        guard
            let raw = rawMessage,
            !raw.isEmpty,
            !ResearchPulseRedactor.containsSensitiveCredential(raw),
            !ResearchPulseRedactor.containsInternalAuthorID(raw),
            ResearchPulseRedactor.backendSourceNames(in: raw).isEmpty
        else {
            return .toolError(message: self.genericToolMessage)
        }
        return .toolError(message: raw)
    }
}
