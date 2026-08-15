import AppKit
import CodexBarCore
import SwiftUI
import Testing
@testable import CodexBar

@MainActor
struct ResearchBarMenuCardLayoutTests {
    @Test
    func `maximal academic pulse uses the shared compact provider card geometry`() throws {
        let width = StatusItemController.menuCardBaseWidth
        let model = try ResearchPulseCardModel.make(from: .loaded(
            pulse: Self.maximalAcademicPulse(),
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
        #expect(model.credit?.summary == "84 credits remaining")
        #expect(model.metrics.count == 2)
        #expect(model.trend?.sparkline?.isEmpty == false)
        #expect(model.dataQuality != nil)
        #expect(model.notice != nil)
        #expect(model.actions.count == 5)
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
    func `production trend composition keeps separate accessibility children and full inner width`() throws {
        let model = try ResearchPulseCardModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"),
            fromStaleCache: false))
        let trend = try #require(model.trend)
        let presentation = ResearchBarMenuContent.citationTrendPresentation(for: trend)
        let chart = try #require(presentation.chart)
        let width: CGFloat = 282
        let content = ResearchBarCitationTrendContent(trend: trend)
        let size = NSHostingController(rootView: content)
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        let chartSize = NSHostingController(rootView: ResearchBarCitationTrendContent.composition.chart(
            MenuCardChartContent(
                chart: chart,
                color: .accentColor,
                height: ResearchBarCitationTrendContent.composition.chartHeight)))
            .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))

        #expect(ResearchBarCitationTrendContent.composition.accessibilityStructure == .separateSummaryAndChart)
        #expect(abs(chartSize.width - width) <= 0.5)
        #expect(abs(size.width - width) <= 0.5)

        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: root.appendingPathComponent(
                "Sources/CodexBar/ResearchBar/ResearchBarMenuContent.swift"),
            encoding: .utf8)
        #expect(source.contains("Self.composition.container(VStack"))
        #expect(source.contains("Self.composition.chart("))
        #expect(source.contains(".accessibilityElement(children: self.accessibilityChildBehavior)"))
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

    private static func maximalAcademicPulse() throws -> ResearchPulse {
        let base = try ResearchBarFixtures.data("pulse-academic-profile-v1")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        object["citationHistoryStatus"] = "tracked"
        object["citationDelta7d"] = 9
        object["citationDelta52w"] = 41
        object["sparkline52w"] = [96, 101, 108, 113, 121, 128, 136, 143, 151, 158, 166, 175]
        object["lowConfidence"] = [
            "identity": true,
            "citations": true,
            "reason": "Public profile review is needed.",
        ]
        object["profileLinks"] = [
            ["label": "ORCID", "url": "https://orcid.org/0000-0002-1825-0097"],
            ["label": "Google Scholar", "url": "https://scholar.example.edu/profile/researcher"],
        ]
        return try ResearchPulse.decode(JSONSerialization.data(withJSONObject: object))
    }
}
