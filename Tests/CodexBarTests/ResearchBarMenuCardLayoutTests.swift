import AppKit
import CodexBarCore
import SwiftUI
import Testing
@testable import CodexBar

@MainActor
struct ResearchBarMenuCardLayoutTests {
    @Test
    func academicPulseUsesTheSharedCompactProviderCardWidth() throws {
        let width = StatusItemController.menuCardBaseWidth
        let model = try ResearchPulseCardModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-academic-profile-v1"),
            fromStaleCache: false))
        let actions = ResearchBarMenuActions(
            refresh: {},
            openCorbisSettings: {},
            openSettings: {},
            clearCache: {})

        let size = NSHostingController(rootView: ResearchBarMenuContent(
            model: model,
            actions: actions,
            width: width))
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))

        #expect(abs(size.width - width) <= 0.5)
        #expect(size.height < 260)
    }
}
