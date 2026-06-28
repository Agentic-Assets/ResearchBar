import Foundation

/// Menu-bar status descriptor derived from a `ResearchPulseMenuInput`.
///
/// Maps each research state onto a glanceable SF Symbol name, a short label, and an
/// accessibility value, following the build/09 accessibility table. The model only ever
/// carries numeric counts and fixed neutral copy: it never includes an internal author id
/// or a backend/source name, and it never fabricates a zero trend.
public struct ResearchPulseStatusIconModel: Equatable, Sendable {
    public let symbolName: String
    public let glanceLabel: String
    public let accessibilityValue: String

    public init(symbolName: String, glanceLabel: String, accessibilityValue: String) {
        self.symbolName = symbolName
        self.glanceLabel = glanceLabel
        self.accessibilityValue = accessibilityValue
    }

    // MARK: SF Symbol names

    private enum Symbol {
        static let idle = "graduationcap"
        static let active = "graduationcap.fill"
        static let attention = "exclamationmark.triangle"
        static let stale = "clock.arrow.circlepath"
    }

    // MARK: Construction

    public static func make(from input: ResearchPulseMenuInput) -> ResearchPulseStatusIconModel {
        let model = ResearchPulseMenuModel.make(from: input)
        let pulse = Self.renderablePulse(from: input, state: model.state)

        switch model.state {
        case .notConnected:
            return Self(symbolName: Symbol.idle, glanceLabel: "•", accessibilityValue: "Not connected")
        case .invalidCredential:
            return Self(
                symbolName: Symbol.attention,
                glanceLabel: "!",
                accessibilityValue: "Connection needs attention")
        case .identityUnlinked:
            return Self(
                symbolName: Symbol.attention,
                glanceLabel: "?",
                accessibilityValue: "Confirm your research identity")
        case .industryProfile:
            return Self(symbolName: Symbol.active, glanceLabel: "•", accessibilityValue: "Professional profile")
        case .loadedNotTracked:
            return Self(
                symbolName: Symbol.active,
                glanceLabel: Self.glanceLabel(for: pulse),
                accessibilityValue: "Citation tracking not started")
        case .loadedTracking:
            return Self(
                symbolName: Symbol.active,
                glanceLabel: Self.glanceLabel(for: pulse),
                accessibilityValue: "Citation history is accruing")
        case .loadedTracked, .loadedLowConfidence:
            return Self(
                symbolName: Symbol.active,
                glanceLabel: Self.glanceLabel(for: pulse),
                accessibilityValue: Self.trackedValue(for: pulse))
        case .staleCache:
            return Self(
                symbolName: Symbol.stale,
                glanceLabel: Self.glanceLabel(for: pulse),
                accessibilityValue: Self.staleValue(for: pulse))
        case .creditLimited:
            return Self(
                symbolName: Symbol.attention,
                glanceLabel: Self.glanceLabel(for: pulse),
                accessibilityValue: "Corbis credits are used up")
        case .safeError:
            return Self(
                symbolName: Symbol.attention,
                glanceLabel: "•",
                accessibilityValue: "Pulse unavailable right now")
        }
    }

    // MARK: Pulse extraction

    /// The pulse safe to read numbers from, or nil. Returns nil for `safeError` so a
    /// leak-like or semantically broken payload is never inspected for display copy.
    private static func renderablePulse(
        from input: ResearchPulseMenuInput,
        state: ResearchPulseMenuModel.State) -> ResearchPulse?
    {
        guard state != .safeError else { return nil }
        switch input {
        case let .loaded(pulse, _):
            return pulse
        case let .creditLimited(pulse):
            return pulse
        default:
            return nil
        }
    }

    // MARK: Formatting

    private static func glanceLabel(for pulse: ResearchPulse?) -> String {
        guard let pulse, let citations = pulse.totalCitations else { return "•" }
        return "\(citations)"
    }

    private static func trackedValue(for pulse: ResearchPulse?) -> String {
        guard let pulse else { return "Citations available" }
        var parts: [String] = []
        if let citations = pulse.totalCitations {
            parts.append("\(citations) citations")
        }
        if let delta = pulse.citationDelta7d {
            parts.append("\(Self.signed(delta)) this week")
        }
        return parts.isEmpty ? "Citations available" : parts.joined(separator: ", ")
    }

    private static func staleValue(for pulse: ResearchPulse?) -> String {
        guard let pulse, let citations = pulse.totalCitations else {
            return "Showing cached pulse"
        }
        return "\(citations) citations, cached"
    }

    private static func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }
}
