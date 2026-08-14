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

        let trend = try #require(tracked.trend)
        let chart = try #require(ResearchBarMenuContent.citationChart(for: trend))
        #expect(chart.kind == .line)
        #expect(chart.unit == "citations")
        #expect(chart.points.map(\.label) == chart.points.indices.map { "Week \($0 + 1)" })
        #expect(try ResearchBarMenuContent.citationChart(for: #require(tracking.trend)) == nil)
    }

    @Test
    func `composed citation trend exposes summary and every weekly value`() throws {
        let model = try ResearchPulseCardModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"),
            fromStaleCache: false))
        let trend = try #require(model.trend)
        let weeklyValues = try #require(trend.sparkline)

        let presentation = ResearchBarMenuContent.citationTrendPresentation(for: trend)
        let expectedWeeklyDescription = weeklyValues.enumerated()
            .map { "Week \($0.offset + 1) \(Double($0.element)) citations" }
            .joined(separator: ", ")

        #expect(presentation.summaryAccessibilityLabel == "Citation trend: +7 this week")
        #expect(presentation.chartAccessibilityLabel == expectedWeeklyDescription)
    }

    @Test
    func `citation chart rejects malformed and text only histories`() {
        let empty = ResearchPulseCardModel.Trend(summary: "Citation history is accruing", sparkline: [])
        let negative = ResearchPulseCardModel.Trend(summary: "Citation history is invalid", sparkline: [1, -1, 2])
        let noHistory = ResearchPulseCardModel.Trend(summary: "Citation tracking starts soon")

        #expect(ResearchBarMenuContent.citationChart(for: empty) == nil)
        #expect(ResearchBarMenuContent.citationChart(for: negative) == nil)
        #expect(ResearchBarMenuContent.citationChart(for: noHistory) == nil)
    }

    @Test
    func `tracked chart card stays within the offered shared width`() throws {
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
    }
}
