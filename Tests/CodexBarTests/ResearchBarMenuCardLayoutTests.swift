import AppKit
import CodexBarCore
import SwiftUI
import Testing
@testable import CodexBar

@MainActor
struct ResearchBarMenuCardLayoutTests {
    @Test
    func `academic pulse uses the shared compact provider card width`() throws {
        let width = StatusItemController.menuCardBaseWidth
        let model = try ResearchPulseCardModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"),
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
        #expect(size.height < 340)
        #expect(model.plan == "academic")
        #expect(model.credit?.summary == "80 credits remaining")
    }

    @Test
    func `tracked research history becomes a full width chart while tracking stays textual`() throws {
        let tracked = try ResearchPulseCardModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"),
            fromStaleCache: false))
        let tracking = try ResearchPulseCardModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-tracking"),
            fromStaleCache: false))

        #expect(try ResearchBarMenuContent.citationChart(for: #require(tracked.trend))?.kind == .line)
        #expect(try ResearchBarMenuContent.citationChart(for: #require(tracking.trend)) == nil)
    }
}
