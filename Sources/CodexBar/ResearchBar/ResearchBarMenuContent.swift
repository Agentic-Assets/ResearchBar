import CodexBarCore
import SwiftUI

/// Compact primary renderer for the Corbis research pulse.
///
/// Unlike the legacy text-row renderer, this card shares the inherited provider-card width,
/// keeps the primary scan path bounded, and leaves evidence detail in Corbis rather than
/// expanding a menu into an audit report.
@MainActor
struct ResearchBarMenuContent: View {
    let model: ResearchPulseCardModel
    let actions: ResearchBarMenuActions
    let width: CGFloat

    @Environment(\.menuItemHighlighted) private var isHighlighted

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            self.header

            if let credit = self.model.credit {
                self.credits(credit)
            }

            if !self.model.metrics.isEmpty {
                Divider()
                self.metrics
            }

            if let trend = self.model.trend {
                self.trend(trend)
            }

            if let dataQuality = self.model.dataQuality {
                self.dataQuality(dataQuality)
            }

            if let notice = self.model.notice {
                self.notice(notice)
            }

            if !self.model.actions.isEmpty {
                Divider()
                self.actionGrid
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: self.width, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Corbis research pulse")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "graduationcap.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(self.model.title)
                            .font(.headline.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(1)

                        if let subtitle = self.model.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 3) {
                        if let plan = self.model.plan {
                            Text(plan)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .accessibilityLabel("Research plan: \(plan)")
                        }

                        if let freshness = self.model.freshness {
                            Text(freshness)
                                .font(.caption)
                                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func credits(_ credit: ResearchPulseCardModel.Credit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Credits")
                .font(.caption.weight(.semibold))
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
            Text(credit.summary)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Credits: \(credit.summary)")
    }

    private var metrics: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(self.model.metrics) { metric in
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.value)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                    Text(metric.label)
                        .font(.caption)
                        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let detail = metric.detail {
                        Text(detail)
                            .font(.caption2)
                            .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func trend(_ trend: ResearchPulseCardModel.Trend) -> some View {
        let presentation = Self.citationTrendPresentation(for: trend)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 7) {
                Image(systemName: trend.sparkline == nil ? "clock" : "chart.line.uptrend.xyaxis")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                Text(trend.summary)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(presentation.summaryAccessibilityLabel)

            if let chart = presentation.chart {
                MenuCardChartContent(chart: chart, color: .accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func dataQuality(_ quality: ResearchPulseCardModel.DataQuality) -> some View {
        HStack(spacing: 7) {
            Image(systemName: quality.needsAttention ? "exclamationmark.circle" : "checkmark.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(quality.needsAttention ? Color.secondary : Color.accentColor)
                .accessibilityHidden(true)
            Text("Data quality: \(quality.summary)")
                .font(.footnote)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .accessibilityElement(children: .combine)
    }

    private func notice(_ notice: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: "exclamationmark.triangle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(notice)
                .font(.footnote)
                .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var actionGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(minimum: 128), spacing: 6), GridItem(.flexible(minimum: 128), spacing: 6)],
            alignment: .leading,
            spacing: 6)
        {
            ForEach(self.model.actions) { action in
                Button {
                    self.perform(action)
                } label: {
                    Label(self.actionLabel(action), systemImage: self.actionSymbol(action))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(self.actionLabel(action))
                .accessibilityHint(self.actionHint(action))
            }
        }
    }

    private func perform(_ action: ResearchPulseCardModel.CardAction) {
        switch action {
        case let .menuAction(menuAction):
            self.actions.perform(menuAction)
        case let .profileLink(link):
            self.actions.perform(.openProfileLink(link.url))
        }
    }

    private func actionLabel(_ action: ResearchPulseCardModel.CardAction) -> String {
        switch action {
        case let .profileLink(link): link.label
        case let .menuAction(menuAction):
            switch menuAction {
            case .refresh: "Refresh"
            case .connect: "Connect"
            case .reconnect: "Reconnect"
            case .reviewIdentity: "Review identity"
            case .openCorbis: "Open Corbis"
            case .openProfileLink: "Open link"
            case .openSettings: "Settings"
            case .clearCache: "Clear cache"
            case .quit: "Quit"
            }
        }
    }

    private func actionSymbol(_ action: ResearchPulseCardModel.CardAction) -> String {
        switch action {
        case .profileLink: "arrow.up.right.square"
        case let .menuAction(menuAction):
            switch menuAction {
            case .refresh: "arrow.clockwise"
            case .connect, .reconnect: "link"
            case .reviewIdentity: "person.crop.circle.badge.checkmark"
            case .openCorbis: "arrow.up.right.square"
            case .openProfileLink: "link"
            case .openSettings: "gearshape"
            case .clearCache: "trash"
            case .quit: "power"
            }
        }
    }

    private func actionHint(_ action: ResearchPulseCardModel.CardAction) -> String {
        switch action {
        case .profileLink: "Open the supplied public profile link"
        case let .menuAction(menuAction):
            switch menuAction {
            case .refresh: "Refreshes the research pulse"
            case .connect, .reconnect, .reviewIdentity: "Opens ResearchBar connection settings"
            case .openCorbis: "Opens Corbis in your browser"
            case .openProfileLink: "Opens the supplied public profile link"
            case .openSettings: "Opens ResearchBar settings"
            case .clearCache: "Clears the saved research pulse"
            case .quit: "Quits ResearchBar"
            }
        }
    }

    static func citationChart(for trend: ResearchPulseCardModel.Trend) -> ProviderDetailSection.Chart? {
        guard let sparkline = trend.sparkline,
              !sparkline.isEmpty,
              sparkline.allSatisfy({ $0 >= 0 })
        else {
            return nil
        }

        guard let points = try? sparkline.enumerated().map({ index, value in
            try ProviderDetailSection.Chart.Point(label: "Week \(index + 1)", value: Double(value))
        }) else {
            return nil
        }

        return try? ProviderDetailSection.Chart(kind: .line, title: nil, unit: "citations", points: points)
    }

    struct CitationTrendPresentation {
        let summaryAccessibilityLabel: String
        let chart: ProviderDetailSection.Chart?

        @MainActor
        var chartAccessibilityLabel: String? {
            guard let chart = self.chart else { return nil }
            return MenuCardChartContent.accessibilityLabel(for: chart)
        }
    }

    static func citationTrendPresentation(for trend: ResearchPulseCardModel.Trend) -> CitationTrendPresentation {
        CitationTrendPresentation(
            summaryAccessibilityLabel: "Citation trend: \(trend.summary)",
            chart: self.citationChart(for: trend))
    }
}
