import Foundation

/// AppKit-free model of the Corbis settings surface (slice 09).
///
/// Pure and testable: it holds the current connection state, the token field text, and an
/// optional already-known display email, then derives token-format validity, the available
/// intents, and a redacted account summary. The bearer token is never echoed back, and the
/// server-provided `accountID` is never rendered: the summary surfaces only `displayEmail`
/// when known, otherwise a fixed `Connected to Corbis` string.
public struct CorbisSettingsViewState: Equatable, Sendable {
    /// Distinct user intents the settings surface can offer, gated by connection state.
    public enum Intent: Equatable, Sendable {
        case connect
        case reconnect
        case unlink
        case clearCache
    }

    /// Primary prefix for a pasted Corbis MCP token.
    public static let tokenPrefix = "corbis_mcp_"
    /// Legacy personal keys remain valid on the Corbis service during its compatibility window.
    public static let legacyTokenPrefix = "orbis_mcp_"

    public let connectionState: CorbisConnectionState
    public let tokenField: String
    public let displayEmail: String?

    public init(connectionState: CorbisConnectionState, tokenField: String = "", displayEmail: String? = nil) {
        self.connectionState = connectionState
        self.tokenField = tokenField
        self.displayEmail = displayEmail
    }

    // MARK: Token validation

    /// True when the trimmed token field carries a supported prefix and a body.
    public var isTokenFieldValid: Bool {
        Self.isValidToken(self.tokenField)
    }

    public static func isValidToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = [self.tokenPrefix, self.legacyTokenPrefix]
        guard let prefix = prefixes.first(where: { trimmed.hasPrefix($0) }) else { return false }
        return trimmed.count > prefix.count
    }

    // MARK: Intents

    /// Intents available for the current connection state. `clearCache` is always present.
    public var availableIntents: [Intent] {
        switch self.connectionState {
        case .notConnected:
            [.connect, .clearCache]
        case .connecting:
            [.clearCache]
        case .connected, .invalid, .validationUnavailable, .storageUnavailable:
            [.reconnect, .unlink, .clearCache]
        }
    }

    // MARK: Redacted summary

    /// A render-safe connection summary. Never includes the bearer token or the
    /// server-provided account id. Surfaces only the display email when known, otherwise a
    /// fixed `Connected to Corbis` string.
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
        case .validationUnavailable:
            return "Connection could not be verified"
        case .storageUnavailable:
            return "Secure storage needs attention"
        }
    }

    /// A safe, user-facing explanation that never includes a credential or server response.
    public var diagnostic: String {
        switch self.connectionState {
        case .notConnected:
            "Paste your Corbis MCP token to start tracking your research pulse."
        case .connecting:
            "Validating your connection…"
        case .connected:
            "Connection healthy. Pulse refreshes on menu open and manual refresh."
        case .invalid:
            "The token was not accepted. Your saved connection was not changed."
        case .validationUnavailable:
            "Corbis could not be reached. Your token was not saved. Try again later."
        case .storageUnavailable:
            "ResearchBar could not access secure storage. Your token was not sent."
        }
    }
}
