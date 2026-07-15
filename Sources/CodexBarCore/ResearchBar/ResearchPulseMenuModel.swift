import Foundation

// MARK: - Menu action vocabulary

/// Abstract menu actions for the research surface. The app target maps these to
/// concrete `MenuDescriptor.MenuAction` handlers (slice 09); keeping them in Core
/// makes the menu model fully testable without AppKit.
public enum ResearchBarMenuAction: Equatable, Sendable {
    case refresh
    case connect
    case reconnect
    case reviewIdentity
    case openCorbis
    case openProfileLink(URL)
    case openSettings
    case clearCache
    case quit
}

// MARK: - Menu input

/// What the app knows when building the menu. Slices 07/08 produce these cases
/// from the credential store, cache, and live client; slice 06 builds and tests
/// the whole renderer from them against fixtures.
public enum ResearchPulseMenuInput: Equatable, Sendable {
    case notConnected
    case invalidCredential
    /// Decode, redaction, or semantic validation already failed upstream.
    case safeError
    /// Credits are exhausted or insufficient; render last-known pulse if present, never auto-refresh.
    case creditLimited(pulse: ResearchPulse?)
    /// A decoded pulse to render; `fromStaleCache` marks a served-past-`staleAfter` entry.
    case loaded(pulse: ResearchPulse, fromStaleCache: Bool)
}

// MARK: - Display rows

public struct ResearchMenuRow: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case header
        case info
        case notice
        case sparkline([Int])
        case action(ResearchBarMenuAction)
    }

    public let label: String
    public let value: String?
    public let kind: Kind

    public init(label: String, value: String? = nil, kind: Kind) {
        self.label = label
        self.value = value
        self.kind = kind
    }
}

public struct ResearchMenuSection: Equatable, Sendable {
    public let title: String?
    public let rows: [ResearchMenuRow]

    public init(title: String?, rows: [ResearchMenuRow]) {
        self.title = title
        self.rows = rows
    }
}

// MARK: - ResearchPulseMenuModel

/// Pure, AppKit-free menu model. Converts a decoded pulse and local state into
/// display rows and abstract actions, enforcing the v0 product rules: never
/// fabricate a zero trend, never render an empty sparkline, never surface backend
/// names or internal ids, and never zero out absent publication metrics.
public struct ResearchPulseMenuModel: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case notConnected
        case invalidCredential
        case identityUnlinked
        case industryProfile
        case loadedNotTracked
        case loadedTracking
        case loadedTracked
        case loadedLowConfidence
        case staleCache
        case creditLimited
        case safeError
    }

    public let state: State
    public let sections: [ResearchMenuSection]

    public init(state: State, sections: [ResearchMenuSection]) {
        self.state = state
        self.sections = sections
    }

    // MARK: Construction

    public static func make(from input: ResearchPulseMenuInput) -> ResearchPulseMenuModel {
        switch input {
        case .notConnected:
            notConnectedModel()
        case .invalidCredential:
            invalidCredentialModel()
        case .safeError:
            safeErrorModel()
        case let .creditLimited(pulse):
            Self.creditLimitedModel(pulse: pulse)
        case let .loaded(pulse, fromStaleCache):
            Self.loadedModel(pulse: pulse, fromStaleCache: fromStaleCache)
        }
    }

    // MARK: Convenience accessors (used by the factory and tests)

    public var actions: [ResearchBarMenuAction] {
        self.sections.flatMap(\.rows).compactMap { row in
            if case let .action(action) = row.kind { return action }
            return nil
        }
    }

    public var renderedStrings: [String] {
        var strings: [String] = []
        for section in self.sections {
            if let title = section.title { strings.append(title) }
            for row in section.rows {
                strings.append(row.label)
                if let value = row.value { strings.append(value) }
            }
        }
        return strings
    }

    public var hasSparkline: Bool {
        self.sections.flatMap(\.rows).contains { row in
            if case .sparkline = row.kind { return true }
            return false
        }
    }

    public var hasNotice: Bool {
        self.sections.flatMap(\.rows).contains { row in
            if case .notice = row.kind { return true }
            return false
        }
    }
}

// MARK: - Builders

extension ResearchPulseMenuModel {
    private static func notConnectedModel() -> ResearchPulseMenuModel {
        let sections = [
            ResearchMenuSection(title: nil, rows: [
                ResearchMenuRow(label: "Not connected to Corbis", kind: .notice),
            ]),
            Self.actionsSection(for: .notConnected, profileLinks: []),
        ]
        return ResearchPulseMenuModel(state: .notConnected, sections: sections)
    }

    private static func invalidCredentialModel() -> ResearchPulseMenuModel {
        let sections = [
            ResearchMenuSection(title: nil, rows: [
                ResearchMenuRow(label: "Corbis connection needs attention", kind: .notice),
            ]),
            Self.actionsSection(for: .invalidCredential, profileLinks: []),
        ]
        return ResearchPulseMenuModel(state: .invalidCredential, sections: sections)
    }

    private static func safeErrorModel() -> ResearchPulseMenuModel {
        let sections = [
            ResearchMenuSection(title: nil, rows: [
                ResearchMenuRow(label: "Pulse unavailable right now", kind: .notice),
            ]),
            Self.actionsSection(for: .safeError, profileLinks: []),
        ]
        return ResearchPulseMenuModel(state: .safeError, sections: sections)
    }

    private static func creditLimitedModel(pulse: ResearchPulse?) -> ResearchPulseMenuModel {
        guard let pulse, ResearchPulseRedactor.isClean(pulse), pulse.isSemanticallyValid else {
            // No safe content to show; degrade to a credit notice only.
            let sections = [
                ResearchMenuSection(title: nil, rows: [
                    ResearchMenuRow(label: "Corbis credits are used up", kind: .notice),
                ]),
                Self.actionsSection(for: .creditLimited, profileLinks: []),
            ]
            return ResearchPulseMenuModel(state: .creditLimited, sections: sections)
        }

        var sections = Self.contentSections(for: pulse, state: .creditLimited)
        sections.append(ResearchMenuSection(title: nil, rows: [
            ResearchMenuRow(label: "Corbis credits are used up", kind: .notice),
        ]))
        sections.append(Self.actionsSection(for: .creditLimited, profileLinks: pulse.profileLinks))
        return ResearchPulseMenuModel(state: .creditLimited, sections: sections)
    }

    private static func loadedModel(pulse: ResearchPulse, fromStaleCache: Bool) -> ResearchPulseMenuModel {
        guard ResearchPulseRedactor.isClean(pulse), pulse.isSemanticallyValid else {
            return self.safeErrorModel()
        }

        let state = Self.contentState(for: pulse, fromStaleCache: fromStaleCache)
        switch state {
        case .identityUnlinked:
            return ResearchPulseMenuModel(state: state, sections: Self.unlinkedSections(pulse: pulse))
        default:
            var sections: [ResearchMenuSection] = []
            if state == .staleCache {
                sections.append(ResearchMenuSection(title: nil, rows: [
                    ResearchMenuRow(
                        label: "Cached",
                        value: "updated \(Self.shortTime(pulse.fetchedAt))",
                        kind: .notice),
                ]))
            }
            sections.append(contentsOf: Self.contentSections(for: pulse, state: state))
            sections.append(Self.actionsSection(for: state, profileLinks: pulse.profileLinks))
            return ResearchPulseMenuModel(state: state, sections: sections)
        }
    }

    private static func contentState(for pulse: ResearchPulse, fromStaleCache: Bool) -> State {
        if pulse.profileStatus == .unlinked { return .identityUnlinked }
        if pulse.profileStatus == .industryProfile { return .industryProfile }
        if fromStaleCache { return .staleCache }
        if pulse.showsLowConfidenceNotice { return .loadedLowConfidence }
        switch pulse.citationHistoryStatus {
        case .tracked: return .loadedTracked
        case .tracking: return .loadedTracking
        case .notYetTracked: return .loadedNotTracked
        }
    }

    // MARK: Section content

    private static func unlinkedSections(pulse: ResearchPulse) -> [ResearchMenuSection] {
        var sections = [
            ResearchMenuSection(title: nil, rows: [
                ResearchMenuRow(label: "Link your research identity", kind: .notice),
                ResearchMenuRow(label: "Confirm identity", kind: .info),
            ]),
        ]
        sections.append(Self.creditsSection(for: pulse))
        sections.append(Self.actionsSection(for: .identityUnlinked, profileLinks: pulse.profileLinks))
        return sections
    }

    private static func contentSections(for pulse: ResearchPulse, state: State) -> [ResearchMenuSection] {
        var sections: [ResearchMenuSection] = [Self.identitySection(for: pulse)]

        if let academicProfile = pulse.academicProfile, academicProfile.isSupported {
            sections.append(contentsOf: Self.academicProfileSections(for: academicProfile))
        } else if pulse.hasUnsupportedAcademicProfile {
            sections.append(ResearchMenuSection(title: "Academic profile", rows: [
                ResearchMenuRow(
                    label: "Research data needs a ResearchBar update",
                    value: "Legacy totals are hidden",
                    kind: .notice),
            ]))
        } else if pulse.profileStatus == .industryProfile {
            sections.append(ResearchMenuSection(title: "Research", rows: [
                ResearchMenuRow(label: "Metrics not tracked", kind: .notice),
            ]))
        } else {
            if let metrics = Self.citationSection(for: pulse) {
                sections.append(metrics)
            }
            sections.append(Self.trendSection(for: pulse))
        }

        if pulse.showsLowConfidenceNotice {
            sections.append(ResearchMenuSection(title: nil, rows: [
                ResearchMenuRow(label: "Some values are low confidence", kind: .notice),
            ]))
        }

        if !pulse.profileLinks.isEmpty {
            sections.append(Self.linksSection(for: pulse))
        }
        return sections
    }

    private static func identitySection(for pulse: ResearchPulse) -> ResearchMenuSection {
        var rows: [ResearchMenuRow] = []
        if let name = pulse.displayName {
            rows.append(ResearchMenuRow(label: name, kind: .header))
        }
        if let role = pulse.role {
            rows.append(ResearchMenuRow(label: "Role", value: role, kind: .info))
        }
        if let sector = pulse.sector {
            rows.append(ResearchMenuRow(label: "Sector", value: sector, kind: .info))
        }
        if let company = pulse.companyName {
            rows.append(ResearchMenuRow(label: "Company", value: company, kind: .info))
        }
        if let affiliation = pulse.affiliation {
            rows.append(ResearchMenuRow(label: "Affiliation", value: affiliation, kind: .info))
        }
        if let orcid = pulse.orcid {
            rows.append(ResearchMenuRow(label: "ORCID", value: orcid, kind: .info))
        }
        rows.append(ResearchMenuRow(label: "Plan", value: pulse.plan, kind: .info))
        if let balance = pulse.resolvedCreditBalance {
            rows.append(ResearchMenuRow(label: "Credits", value: Self.creditsLabel(balance), kind: .info))
        }
        return ResearchMenuSection(title: "Account", rows: rows)
    }

    private static func creditsSection(for pulse: ResearchPulse) -> ResearchMenuSection {
        var rows = [ResearchMenuRow(label: "Plan", value: pulse.plan, kind: .info)]
        if let balance = pulse.resolvedCreditBalance {
            rows.append(ResearchMenuRow(label: "Credits", value: self.creditsLabel(balance), kind: .info))
        }
        return ResearchMenuSection(title: "Account", rows: rows)
    }

    /// Citation metrics, or nil when every publication metric is absent (never zero them).
    private static func citationSection(for pulse: ResearchPulse) -> ResearchMenuSection? {
        guard !pulse.hasNoPublicationMetrics else { return nil }
        var rows: [ResearchMenuRow] = []
        if let citations = pulse.resolvedOpenAlexCitations {
            rows.append(ResearchMenuRow(label: "Citations", value: "\(citations)", kind: .info))
        }
        if let hIndex = pulse.hIndex {
            rows.append(ResearchMenuRow(label: "h-index", value: "\(hIndex)", kind: .info))
        }
        if let works = pulse.resolvedIndexedWorksCount {
            rows.append(ResearchMenuRow(label: "Indexed works", value: "\(works)", kind: .info))
        }
        return rows.isEmpty ? nil : ResearchMenuSection(title: "Citation pulse", rows: rows)
    }

    // MARK: academic-profile.v1 presentation

    /// Builds a compact, provider-neutral view while preserving source, freshness,
    /// status, coverage, and reconciliation boundaries from the canonical contract.
    private static func academicProfileSections(for profile: AcademicProfile) -> [ResearchMenuSection] {
        let sourceOrdinals = Self.sourceOrdinals(for: profile)
        var sections = [
            Self.academicOverviewSection(for: profile),
            Self.academicEvidenceSection(for: profile, sourceOrdinals: sourceOrdinals),
            Self.academicMetricsSection(for: profile, sourceOrdinals: sourceOrdinals),
        ]
        if let coverage = Self.academicCoverageSection(for: profile, sourceOrdinals: sourceOrdinals) {
            sections.append(coverage)
        }
        return sections
    }

    private static func academicOverviewSection(for profile: AcademicProfile) -> ResearchMenuSection {
        var rows = [
            ResearchMenuRow(
                label: "Research works",
                value: Self.academicNumberLabel(Double(profile.workFamilies.count)),
                kind: .info),
        ]
        if !profile.workProposals.isEmpty {
            rows.append(ResearchMenuRow(
                label: "Matches to review",
                value: Self.academicNumberLabel(Double(profile.workProposals.count)),
                kind: .notice))
        }
        rows.append(ResearchMenuRow(
            label: "Profile observed",
            value: Self.shortDate(profile.observedAt),
            kind: .info))
        return ResearchMenuSection(title: "Research overview", rows: rows)
    }

    private static func academicEvidenceSection(
        for profile: AcademicProfile,
        sourceOrdinals: [AcademicProfileSource: Int]) -> ResearchMenuSection
    {
        let rows = profile.sources
            .sorted { Self.sourceOrder($0.source) < Self.sourceOrder($1.source) }
            .map { state in
                ResearchMenuRow(
                    label: "Evidence source \(sourceOrdinals[state.source, default: 1])",
                    value: Self.academicSourceDetail(state),
                    kind: Self.isCurrentAndComplete(state) ? .info : .notice)
            }
        return ResearchMenuSection(title: "Evidence", rows: rows)
    }

    private static func academicMetricsSection(
        for profile: AcademicProfile,
        sourceOrdinals: [AcademicProfileSource: Int]) -> ResearchMenuSection
    {
        let rows = profile.metrics.sorted {
            let lhs = Self.sourceOrder($0.source)
            let rhs = Self.sourceOrder($1.source)
            return lhs == rhs ? $0.id < $1.id : lhs < rhs
        }.map { metric in
            let sourceNumber = sourceOrdinals[metric.source, default: 1]
            let label = "\(Self.metricName(metric.id)) · Source \(sourceNumber)"
            return ResearchMenuRow(
                label: label,
                value: Self.academicMetricDetail(metric),
                kind: Self.isCurrentAndComplete(metric) ? .info : .notice)
        }
        return ResearchMenuSection(title: "Academic metrics", rows: rows)
    }

    private static func academicCoverageSection(
        for profile: AcademicProfile,
        sourceOrdinals: [AcademicProfileSource: Int]) -> ResearchMenuSection?
    {
        var rows: [ResearchMenuRow] = []
        for state in profile.sources.sorted(by: { Self.sourceOrder($0.source) < Self.sourceOrder($1.source) }) {
            guard !Self.isCurrentAndComplete(state) else { continue }
            rows.append(ResearchMenuRow(
                label: "Source \(sourceOrdinals[state.source, default: 1])",
                value: Self.coverageDetail(status: state.status, complete: state.coverage.complete),
                kind: .notice))
        }
        guard !rows.isEmpty else { return nil }
        return ResearchMenuSection(title: "Data coverage", rows: rows)
    }

    private static func academicSourceDetail(_ state: AcademicSourceState) -> String {
        var parts = [state.status.displayLabel]
        if let observedAt = state.observedAt {
            parts.append("observed \(Self.shortDate(observedAt))")
        } else if let attemptedAt = state.attemptedAt {
            parts.append("attempted \(Self.shortDate(attemptedAt))")
        }
        if let recordCount = state.coverage.recordCount {
            let suffix = recordCount == 1 ? "record" : "records"
            parts.append("\(Self.academicNumberLabel(recordCount)) \(suffix)")
        } else {
            parts.append("record count unavailable")
        }
        switch state.coverage.complete {
        case true: parts.append("complete")
        case false: parts.append("partial coverage")
        case nil: parts.append("coverage unknown")
        }
        return parts.joined(separator: " · ")
    }

    private static func academicMetricDetail(_ metric: AcademicProfileMetric) -> String {
        var parts = [metric.value.map(Self.academicNumberLabel) ?? "Unavailable"]
        parts.append(metric.status.displayLabel)
        if let observedAt = metric.observedAt {
            parts.append("observed \(Self.shortDate(observedAt))")
        } else if let attemptedAt = metric.attemptedAt {
            parts.append("attempted \(Self.shortDate(attemptedAt))")
        }
        parts.append("scope: \(Self.providerNeutralAcademicText(metric.scope))")
        if let staleAfter = metric.staleAfter {
            parts.append("refresh by \(Self.shortDate(staleAfter))")
        }
        if let reason = metric.reason, !reason.isEmpty {
            parts.append(Self.providerNeutralAcademicText(reason))
        }
        switch metric.coverage.complete {
        case true: break
        case false: parts.append("partial coverage")
        case nil: parts.append("coverage unknown")
        }
        return parts.joined(separator: " · ")
    }

    private static func metricName(_ id: String) -> String {
        let suffix = id.split(separator: ".", maxSplits: 1).last.map(String.init) ?? id
        return switch suffix {
        case "citations": "Citations"
        case "downloads": "Downloads"
        case "h_index": "h-index"
        case "i10_index": "i10-index"
        case "indexed_works": "Indexed works"
        case "work_summaries": "Work summaries"
        case "normalized_title_families": "Title families"
        case "visible_works": "Visible works"
        case "scholarly_papers": "Scholarly papers"
        default: "Research metric"
        }
    }

    private static func sourceOrder(_ source: AcademicProfileSource) -> Int {
        switch source {
        case .openAlex: 0
        case .orcid: 1
        case .googleScholar: 2
        case .ssrn: 3
        }
    }

    private static func sourceOrdinals(for profile: AcademicProfile) -> [AcademicProfileSource: Int] {
        let participating = Set(profile.sources.map(\.source) + profile.metrics.map(\.source))
        return Dictionary(uniqueKeysWithValues: participating
            .sorted { Self.sourceOrder($0) < Self.sourceOrder($1) }
            .enumerated()
            .map { ($0.element, $0.offset + 1) })
    }

    private static func providerNeutralAcademicText(_ text: String) -> String {
        AcademicProfileSource.allCases.reduce(text) { result, source in
            result.replacingOccurrences(
                of: source.displayLabel,
                with: "this source",
                options: .caseInsensitive)
        }
    }

    private static func isCurrentAndComplete(_ state: AcademicSourceState) -> Bool {
        state.status == .current && state.coverage.complete == true
    }

    private static func isCurrentAndComplete(_ metric: AcademicProfileMetric) -> Bool {
        metric.value != nil && metric.status == .current && metric.coverage.complete == true
    }

    private static func coverageDetail(status: AcademicSourceStatus, complete: Bool?) -> String {
        switch complete {
        case true: status.displayLabel
        case false: "\(status.displayLabel) · partial coverage"
        case nil: "\(status.displayLabel) · coverage unknown"
        }
    }

    private static func academicNumberLabel(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value == value.rounded() ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func trendSection(for pulse: ResearchPulse) -> ResearchMenuSection {
        switch pulse.citationHistoryStatus {
        case .tracked where pulse.hasRenderableTrend:
            var rows: [ResearchMenuRow] = []
            if let delta7d = pulse.citationDelta7d {
                rows.append(ResearchMenuRow(label: "Past 7 days", value: Self.deltaLabel(delta7d), kind: .info))
            }
            if let delta52w = pulse.citationDelta52w {
                rows.append(ResearchMenuRow(label: "Past 52 weeks", value: Self.deltaLabel(delta52w), kind: .info))
            }
            if let sparkline = pulse.sparkline52w {
                rows.append(ResearchMenuRow(label: "Trend", kind: .sparkline(sparkline)))
            }
            return ResearchMenuSection(title: "Trend", rows: rows)
        case .tracking:
            return ResearchMenuSection(title: "Trend", rows: [
                ResearchMenuRow(label: "Citation history is accruing", kind: .notice),
            ])
        case .tracked, .notYetTracked:
            return ResearchMenuSection(title: "Trend", rows: [
                ResearchMenuRow(label: "Tracking starts soon", kind: .notice),
            ])
        }
    }

    private static func linksSection(for pulse: ResearchPulse) -> ResearchMenuSection {
        let rows = pulse.profileLinks.map { link in
            ResearchMenuRow(label: link.label, value: link.url.host, kind: .action(.openProfileLink(link.url)))
        }
        return ResearchMenuSection(title: "Links", rows: rows)
    }

    private static func actionsSection(for state: State, profileLinks _: [ProfileLink]) -> ResearchMenuSection {
        let actions: [ResearchBarMenuAction] = switch state {
        case .notConnected:
            [.connect, .openSettings, .quit]
        case .invalidCredential:
            [.reconnect, .openSettings, .quit]
        case .identityUnlinked:
            [.reviewIdentity, .openCorbis, .openSettings, .quit]
        case .creditLimited:
            [.openCorbis, .openSettings, .quit]
        case .safeError:
            [.refresh, .openSettings, .quit]
        case .loadedLowConfidence:
            [.refresh, .reviewIdentity, .openCorbis, .openSettings, .quit]
        case .loadedNotTracked, .loadedTracking, .loadedTracked, .staleCache, .industryProfile:
            [.refresh, .openCorbis, .openSettings, .quit]
        }
        let rows = actions.map { ResearchMenuRow(label: Self.actionLabel($0), kind: .action($0)) }
        return ResearchMenuSection(title: nil, rows: rows)
    }

    // MARK: Formatting

    private static func actionLabel(_ action: ResearchBarMenuAction) -> String {
        switch action {
        case .refresh: "Refresh"
        case .connect: "Connect Corbis"
        case .reconnect: "Reconnect"
        case .reviewIdentity: "Review identity"
        case .openCorbis: "Open Corbis"
        case .openProfileLink: "Open link"
        case .openSettings: "Settings"
        case .clearCache: "Clear cache"
        case .quit: "Quit"
        }
    }

    private static func creditsLabel(_ balance: CreditBalance) -> String {
        switch balance {
        case let .limited(remaining):
            Self.academicNumberLabel(remaining)
        case .unlimited:
            "Unlimited"
        }
    }

    private static func deltaLabel(_ delta: Int) -> String {
        delta >= 0 ? "+\(delta)" : "\(delta)"
    }

    private static func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
