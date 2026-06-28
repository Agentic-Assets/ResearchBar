import AppKit
import CodexBarCore
import Foundation

/// Concrete handlers for the abstract `ResearchBarMenuAction` vocabulary (slice 09).
///
/// Thin glue: it routes refresh to an injected `ResearchPulseRefreshCoordinator`, cache
/// clears to an injected `ResearchPulseCaching`, navigation intents to settings-opening
/// closures, and link intents to `NSWorkspace`. It never constructs a source URL: a profile
/// link is opened only with the URL the pulse itself supplied.
@MainActor
struct ResearchBarMenuActions {
    /// Force a credit-spending refresh and deliver the resulting menu input.
    var refresh: () -> Void
    /// Open the Corbis connection settings tab (connect / reconnect / review identity).
    var openCorbisSettings: () -> Void
    /// Open the general settings surface.
    var openSettings: () -> Void
    /// Clear the cached pulse(s).
    var clearCache: () -> Void

    private static let corbisURL = URL(string: "https://www.corbis.ai")

    func perform(_ action: ResearchBarMenuAction) {
        switch action {
        case .refresh:
            self.refresh()
        case .connect, .reconnect, .reviewIdentity:
            self.openCorbisSettings()
        case .openCorbis:
            Self.open(Self.corbisURL)
        case let .openProfileLink(url):
            Self.open(url)
        case .openSettings:
            self.openSettings()
        case .clearCache:
            self.clearCache()
        case .quit:
            NSApplication.shared.terminate(nil)
        }
    }

    private static func open(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Coordinator-backed wiring

extension ResearchBarMenuActions {
    /// Wire the action handlers to a live refresh coordinator and pulse cache. The refresh
    /// result is delivered on the main actor through `onRefreshResult`.
    init(
        coordinator: ResearchPulseRefreshCoordinator,
        cache: any ResearchPulseCaching,
        openCorbisSettings: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        onRefreshResult: @escaping (ResearchPulseMenuInput) -> Void = { _ in })
    {
        self.refresh = {
            Task { @MainActor in
                let input = await coordinator.manualRefresh()
                onRefreshResult(input)
            }
        }
        self.clearCache = {
            Task { await cache.clearAll() }
        }
        self.openCorbisSettings = openCorbisSettings
        self.openSettings = openSettings
    }
}
