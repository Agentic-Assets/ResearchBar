import Foundation

/// High-level Corbis connection lifecycle, surfaced to the menu/settings layer in
/// slice 09. Carries the resolved account identity when connected.
public enum CorbisConnectionState: Equatable, Sendable {
    case notConnected
    case connecting
    case connected(CorbisAccountIdentity)
    case invalid

    /// Map the trivially-determined states onto a menu input. `connecting` and
    /// `connected` depend on a fetched pulse, so they return nil here and are resolved
    /// by the data layer instead.
    public var menuInput: ResearchPulseMenuInput? {
        switch self {
        case .notConnected:
            .notConnected
        case .invalid:
            .invalidCredential
        case .connecting, .connected:
            nil
        }
    }
}
