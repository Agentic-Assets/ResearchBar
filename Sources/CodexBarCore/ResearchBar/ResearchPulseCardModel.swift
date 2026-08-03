import Foundation

/// Compact, presentation-ready projection for the primary ResearchBar menu card.
///
/// The full `academicProfile` remains available for provenance and validation, but a menu-bar
/// card only presents the small set of facts a researcher can scan quickly. It never combines
/// source-specific metrics, invents unavailable values, or exposes backend-source details.
public struct ResearchPulseCardModel: Equatable, Sendable {
    public struct Metric: Equatable, Sendable, Identifiable {
        public let id: String
        public let label: String
        public let value: String
        public let detail: String?

        public init(id: String, label: String, value: String, detail: String? = nil) {
            self.id = id
            self.label = label
            self.value = value
            self.detail = detail
        }
    }

    public struct Trend: Equatable, Sendable {
        public let summary: String
        public let sparkline: [Int]?

        public init(summary: String, sparkline: [Int]? = nil) {
            self.summary = summary
            self.sparkline = sparkline
        }
    }

    public struct DataQuality: Equatable, Sendable {
        public let summary: String
        public let needsAttention: Bool

        public init(summary: String, needsAttention: Bool) {
            self.summary = summary
            self.needsAttention = needsAttention
        }
    }

    public enum CardAction: Equatable, Sendable, Identifiable {
        case menuAction(ResearchBarMenuAction)
        case profileLink(ProfileLink)

        public var id: String {
            switch self {
            case let .menuAction(action):
                "action:\(Self.actionID(action))"
            case let .profileLink(link):
                "link:\(link.url.absoluteString)"
            }
        }

        private static func actionID(_ action: ResearchBarMenuAction) -> String {
            switch action {
            case .refresh: "refresh"
            case .connect: "connect"
            case .reconnect: "reconnect"
            case .reviewIdentity: "reviewIdentity"
            case .openCorbis: "openCorbis"
            case let .openProfileLink(url): "profile:\(url.absoluteString)"
            case .openSettings: "openSettings"
            case .clearCache: "clearCache"
            case .quit: "quit"
            }
        }
    }

    public let state: ResearchPulseMenuModel.State
    public let title: String
    public let subtitle: String?
    public let freshness: String?
    public let metrics: [Metric]
    public let dataQuality: DataQuality?
    public let trend: Trend?
    public let notice: String?
    public let actions: [CardAction]

    public init(
        state: ResearchPulseMenuModel.State,
        title: String,
        subtitle: String?,
        freshness: String?,
        metrics: [Metric],
        dataQuality: DataQuality?,
        trend: Trend?,
        notice: String?,
        actions: [CardAction])
    {
        self.state = state
        self.title = title
        self.subtitle = subtitle
        self.freshness = freshness
        self.metrics = metrics
        self.dataQuality = dataQuality
        self.trend = trend
        self.notice = notice
        self.actions = actions
    }

    public static func make(from input: ResearchPulseMenuInput) -> ResearchPulseCardModel {
        let menuModel = ResearchPulseMenuModel.make(from: input)
        let actions = Self.cardActions(for: menuModel, pulse: Self.safePulse(from: input, state: menuModel.state))
        guard let pulse = Self.safePulse(from: input, state: menuModel.state) else {
            return Self.emptyCard(state: menuModel.state, actions: actions)
        }

        let identity = Self.identity(for: pulse)
        let freshness = Self.freshness(for: pulse, state: menuModel.state)
        let academicProfile = pulse.academicProfile?.isSupported == true ? pulse.academicProfile : nil
        // A present-but-unsupported profile is deliberately not a legacy profile. Rendering the
        // compatibility aliases here would turn them into an unlabelled alternate truth.
        let metrics: [Metric]
        let dataQuality: DataQuality?
        if pulse.hasUnsupportedAcademicProfile {
            metrics = []
            dataQuality = nil
        } else {
            metrics = academicProfile.map(Self.academicMetrics(for:)) ?? Self.legacyMetrics(for: pulse)
            dataQuality = academicProfile.flatMap(Self.dataQuality(for:))
        }
        let trend = Self.trend(for: pulse)
        let notice = Self.notice(for: menuModel.state, pulse: pulse)

        return Self(
            state: menuModel.state,
            title: pulse.displayName ?? "Research pulse",
            subtitle: identity,
            freshness: freshness,
            metrics: metrics,
            dataQuality: dataQuality,
            trend: trend,
            notice: notice,
            actions: actions)
    }
}

extension ResearchPulseCardModel {
    fileprivate static func safePulse(
        from input: ResearchPulseMenuInput,
        state: ResearchPulseMenuModel.State) -> ResearchPulse?
    {
        guard state != .safeError, state != .identityUnlinked else { return nil }
        let pulse: ResearchPulse? = switch input {
        case let .loaded(pulse, _): pulse
        case let .creditLimited(pulse): pulse
        default: nil
        }
        guard let pulse, ResearchPulseRedactor.isClean(pulse), pulse.isSemanticallyValid else { return nil }
        return pulse
    }

    fileprivate static func cardActions(for model: ResearchPulseMenuModel, pulse: ResearchPulse?) -> [CardAction] {
        let primaryActions = model.actions
            .filter {
                switch $0 {
                case .openProfileLink, .quit: false
                default: true
                }
            }
            .prefix(3)
            .map(CardAction.menuAction)
        let profileLinks = pulse?.profileLinks.prefix(2).map(CardAction.profileLink) ?? []
        return primaryActions + profileLinks
    }

    fileprivate static func emptyCard(
        state: ResearchPulseMenuModel.State,
        actions: [CardAction]) -> ResearchPulseCardModel
    {
        let content: (title: String, subtitle: String?, notice: String?) = switch state {
        case .notConnected:
            ("Connect ResearchBar", "Add your Corbis research connection", "Your research pulse is not connected")
        case .invalidCredential:
            ("Connection needs attention", nil, "Reconnect your Corbis research pulse")
        case .identityUnlinked:
            ("Link your research identity", nil, "Confirm an academic identity to begin tracking")
        case .creditLimited:
            ("Corbis credits are used up", nil, "Refresh is paused until credits are available")
        case .safeError:
            ("Pulse unavailable right now", nil, "Try again or open ResearchBar settings")
        case .industryProfile:
            ("Professional profile", nil, nil)
        case .loadedNotTracked, .loadedTracking, .loadedTracked, .loadedLowConfidence, .staleCache:
            ("Research pulse", nil, nil)
        }
        return Self(
            state: state,
            title: content.title,
            subtitle: content.subtitle,
            freshness: nil,
            metrics: [],
            dataQuality: nil,
            trend: nil,
            notice: content.notice,
            actions: actions)
    }

    fileprivate static func identity(for pulse: ResearchPulse) -> String? {
        let values: [String?] = if pulse.profileStatus == .industryProfile {
            [pulse.role, pulse.companyName, pulse.affiliation]
        } else {
            [pulse.role, pulse.affiliation, pulse.orcid == nil ? nil : "ORCID linked"]
        }
        let summary = values.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(2)
        return summary.isEmpty ? nil : summary.joined(separator: " · ")
    }

    fileprivate static func freshness(for pulse: ResearchPulse, state: ResearchPulseMenuModel.State) -> String? {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let timestamp = formatter.string(from: pulse.fetchedAt)
        return state == .staleCache ? "Cached · \(timestamp)" : "Updated \(timestamp)"
    }

    fileprivate static func academicMetrics(for profile: AcademicProfile) -> [Metric] {
        var metrics: [Metric] = []
        if let citations = preferredMetric(named: "citations", in: profile) {
            metrics.append(Metric(
                id: "citations",
                label: "Citations",
                value: self.number(citations),
                detail: "Source-specific"))
        }
        if !profile.workFamilies.isEmpty {
            metrics.append(Metric(
                id: "researchWorks",
                label: "Research works",
                value: self.number(Double(profile.workFamilies.count)),
                detail: nil))
        }
        if metrics.count < 2, let hIndex = preferredMetric(named: "h_index", in: profile) {
            metrics.append(Metric(
                id: "hIndex",
                label: "h-index",
                value: self.number(hIndex),
                detail: "Source-specific"))
        }
        return Array(metrics.prefix(2))
    }

    fileprivate static func legacyMetrics(for pulse: ResearchPulse) -> [Metric] {
        var metrics: [Metric] = []
        if let citations = pulse.resolvedOpenAlexCitations {
            metrics.append(Metric(id: "citations", label: "Citations", value: "\(citations)"))
        }
        if let hIndex = pulse.hIndex, metrics.count < 2 {
            metrics.append(Metric(id: "hIndex", label: "h-index", value: "\(hIndex)"))
        }
        if let works = pulse.resolvedIndexedWorksCount, metrics.count < 2 {
            metrics.append(Metric(id: "indexedWorks", label: "Indexed works", value: "\(works)"))
        }
        return metrics
    }

    fileprivate static func preferredMetric(named suffix: String, in profile: AcademicProfile) -> Double? {
        profile.metrics
            .filter {
                $0.id.split(separator: ".").last == Substring(suffix) &&
                    $0.value != nil &&
                    $0.status == .current &&
                    $0.coverage.complete == true
            }
            .min { self.sourceOrder($0.source) < self.sourceOrder($1.source) }?
            .value
    }

    fileprivate static func dataQuality(for profile: AcademicProfile) -> DataQuality? {
        guard !profile.sources.isEmpty else { return nil }
        let current = profile.sources.count(where: { $0.status == .current && $0.coverage.complete == true })
        let total = profile.sources.count
        return DataQuality(
            summary: "\(current) of \(total) sources current & complete",
            needsAttention: current != total)
    }

    fileprivate static func trend(for pulse: ResearchPulse) -> Trend? {
        switch pulse.citationHistoryStatus {
        case .tracked where pulse.hasRenderableTrend:
            guard let delta = pulse.citationDelta7d else { return nil }
            return Trend(summary: "\(self.signed(delta)) this week", sparkline: pulse.sparkline52w)
        case .tracking:
            return Trend(summary: "Citation history is accruing")
        case .notYetTracked, .tracked:
            return Trend(summary: "Citation tracking starts soon")
        }
    }

    fileprivate static func notice(for state: ResearchPulseMenuModel.State, pulse: ResearchPulse) -> String? {
        switch state {
        case .creditLimited: "Corbis credits are used up"
        case .loadedLowConfidence: "Some research data needs review"
        default: pulse.hasUnsupportedAcademicProfile ? "Research data needs a ResearchBar update" : nil
        }
    }

    fileprivate static func number(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value == value.rounded() ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    fileprivate static func signed(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    fileprivate static func sourceOrder(_ source: AcademicProfileSource) -> Int {
        switch source {
        case .openAlex: 0
        case .orcid: 1
        case .googleScholar: 2
        case .ssrn: 3
        }
    }
}
