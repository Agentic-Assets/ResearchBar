import Foundation

/// AppKit-free model of the Corbis settings surface (slice 09).
///
/// Pure and testable: it holds the current connection state, the token field text, and an
/// optional already-known display email, then derives token-format validity, the available
/// intents, and a redacted account summary. The bearer token is never echoed back: the
/// summary surfaces only `displayEmail` / `accountID`.
public struct CorbisSettingsViewState: Equatable, Sendable {
    /// Distinct user intents the settings surface can offer, gated by connection state.
    public enum Intent: Equatable, Sendable {
        case connect
        case reconnect
        case unlink
        case clearCache
    }

    /// Required prefix for a pasted Corbis MCP token.
    public static let tokenPrefix = "corbis_mcp_"

    public let connectionState: CorbisConnectionState
    public let tokenField: String
    public let displayEmail: String?

    public init(connectionState: CorbisConnectionState, tokenField: String = "", displayEmail: String? = nil) {
        self.connectionState = connectionState
        self.tokenField = tokenField
        self.displayEmail = displayEmail
    }

    // MARK: Token validation

    /// True when the trimmed token field carries the `corbis_mcp_` prefix and a body.
    public var isTokenFieldValid: Bool {
        Self.isValidToken(self.tokenField)
    }

    public static func isValidToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(self.tokenPrefix) else { return false }
        return trimmed.count > self.tokenPrefix.count
    }

    // MARK: Intents

    /// Intents available for the current connection state. `clearCache` is always present.
    public var availableIntents: [Intent] {
        switch self.connectionState {
        case .notConnected:
            [.connect, .clearCache]
        case .connecting:
            [.clearCache]
        case .connected, .invalid:
            [.reconnect, .unlink, .clearCache]
        }
    }

    // MARK: Redacted summary

    /// A render-safe connection summary. Never includes the bearer token, only the
    /// display email or account id when known.
    public var accountSummary: String {
        switch self.connectionState {
        case .notConnected:
            return "Not connected"
        case .connecting:
            return "Connecting…"
        case .connected:
            if let email = self.displayEmail, !email.isEmpty {
                return "Connected as \(email)"
            }
            return "Connected to Corbis"
        case .invalid:
            return "Connection needs attention"
        }
    }
}
