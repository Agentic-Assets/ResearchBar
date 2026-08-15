import Foundation

/// High-level Corbis connection lifecycle, surfaced to the menu/settings layer in
/// slice 09. Carries the resolved account identity when connected.
public enum CorbisConnectionState: Equatable, Sendable {
    case notConnected
    case connecting
    case connected(CorbisAccountIdentity)
    case invalid
    /// The candidate was not saved because Corbis could not be reached or its response was invalid.
    case validationUnavailable
    /// Secure local storage was unavailable; this is not evidence that a token was rejected.
    case storageUnavailable

    /// Map the trivially-determined states onto a menu input. `connecting` and
    /// `connected` depend on a fetched pulse, so they return nil here and are resolved
    /// by the data layer instead.
    public var menuInput: ResearchPulseMenuInput? {
        switch self {
        case .notConnected:
            .notConnected
        case .invalid:
            .invalidCredential
        case .validationUnavailable, .storageUnavailable:
            .safeError
        case .connecting, .connected:
            nil
        }
    }
}
