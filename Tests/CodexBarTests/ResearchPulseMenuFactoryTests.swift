import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct ResearchPulseMenuFactoryTests {
    // MARK: Every state has coverage and is non-empty

    @Test
    func everyStateProducesNonEmptyShapedSections() throws {
        for (state, input) in try Self.inputsByState() {
            let model = ResearchPulseMenuModel.make(from: input)
            #expect(model.state == state, "expected \(state) for crafted input, got \(model.state)")
            let sections = ResearchPulseMenuFactory.makeSections(from: model)
            #expect(!sections.isEmpty, "no sections for \(state)")
            #expect(!Self.allItems(sections).isEmpty, "no items for \(state)")
        }
    }

    // MARK: Trend gating

    @Test
    func notTrackedAndTrackingOmitTrendAndDeltaEntries() throws {
        for name in ["pulse-linked-not-tracked", "pulse-linked-tracking"] {
            let sections = try ResearchPulseMenuFactory.makeSections(
                from: .loaded(pulse: ResearchBarFixtures.pulse(name), fromStaleCache: false))
            #expect(!Self.hasTrend(sections), "\(name) should not render a trend")
            #expect(!Self.allTitles(sections).contains { $0.contains("+") }, "\(name) should not render a delta")
        }
    }

    @Test
    func trackedRendersTrend() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"), fromStaleCache: false))
        #expect(Self.hasTrend(sections))
        #expect(Self.allTitles(sections).contains { $0.contains("+7") })
    }

    // MARK: Industry profile shows no zeroed widgets

    @Test
    func industryProfileShowsNoZeroedCitationWidgets() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-industry-profile"), fromStaleCache: false))
        let titles = Self.allTitles(sections)
        #expect(!titles.contains { $0.localizedCaseInsensitiveContains("Citations") })
        #expect(!titles.contains { $0 == "0" })
        #expect(!Self.hasTrend(sections))
    }

    // MARK: Action gating

    @Test
    func creditLimitedHasNoRefreshAction() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .creditLimited(pulse: ResearchBarFixtures.pulse("pulse-credit-limited")))
        #expect(!Self.actions(sections).contains(.refresh))
    }

    @Test
    func unlinkedShowsIdentityConfirmationAction() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-unlinked"), fromStaleCache: false))
        #expect(Self.actions(sections).contains(.reviewIdentity))
    }

    @Test
    func lowConfidenceShowsReviewActionAndNotice() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-low-confidence"), fromStaleCache: false))
        #expect(Self.actions(sections).contains(.reviewIdentity))
        #expect(Self.allItems(sections).contains { $0.kind == .notice })
    }

    @Test
    func staleCacheShowsRefreshAndNotice() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"), fromStaleCache: true))
        #expect(Self.actions(sections).contains(.refresh))
        #expect(Self.allItems(sections).contains { $0.kind == .notice })
    }

    @Test
    func profileLinkActionsUseSuppliedURLsOnly() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")
        let sections = ResearchPulseMenuFactory.makeSections(from: .loaded(pulse: pulse, fromStaleCache: false))
        let linkURLs: [URL] = Self.actions(sections).compactMap { action in
            if case let .openProfileLink(url) = action { return url }
            return nil
        }
        let suppliedURLs = Set(pulse.profileLinks.map(\.url))
        for url in linkURLs {
            #expect(suppliedURLs.contains(url), "profile link \(url) was not supplied by the pulse")
        }
    }

    // MARK: No-leak guarantees

    @Test
    func leakLikeInputCollapsesToSafeErrorWithNoLeak() throws {
        let input: ResearchPulseMenuInput = try .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-leak-like"),
            fromStaleCache: false)
        #expect(ResearchPulseMenuModel.make(from: input).state == .safeError)
        let sections = ResearchPulseMenuFactory.makeSections(from: input)
        for title in Self.allTitles(sections) {
            #expect(!ResearchPulseRedactor.containsInternalAuthorID(title))
            #expect(ResearchPulseRedactor.backendSourceNames(in: title).isEmpty)
        }
    }

    @Test
    func noStateLeaksBackendNamesOrInternalIDsIntoTitles() throws {
        for name in ResearchBarFixtures.allPulseNames {
            let pulse = try ResearchBarFixtures.pulse(name)
            let sections = ResearchPulseMenuFactory.makeSections(from: .loaded(pulse: pulse, fromStaleCache: false))
            for title in Self.allTitles(sections) {
                #expect(!ResearchPulseRedactor.containsInternalAuthorID(title), "leak in \(name): \(title)")
                #expect(
                    ResearchPulseRedactor.backendSourceNames(in: title).isEmpty,
                    "backend name in \(name): \(title)")
            }
        }
    }

    // MARK: Helpers

    private static func inputsByState() throws -> [(ResearchPulseMenuModel.State, ResearchPulseMenuInput)] {
        try [
            (.notConnected, .notConnected),
            (.invalidCredential, .invalidCredential),
            (.safeError, .safeError),
            (.identityUnlinked, .loaded(pulse: ResearchBarFixtures.pulse("pulse-unlinked"), fromStaleCache: false)),
            (
                .industryProfile,
                .loaded(pulse: ResearchBarFixtures.pulse("pulse-industry-profile"), fromStaleCache: false)),
            (
                .loadedNotTracked,
                .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-not-tracked"), fromStaleCache: false)),
            (
                .loadedTracking,
                .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracking"), fromStaleCache: false)),
            (
                .loadedTracked,
                .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"), fromStaleCache: false)),
            (
                .loadedLowConfidence,
                .loaded(pulse: ResearchBarFixtures.pulse("pulse-low-confidence"), fromStaleCache: false)),
            (
                .loadedLowConfidence,
                .loaded(pulse: ResearchBarFixtures.pulse("pulse-profile-only"), fromStaleCache: false)),
            (
                .staleCache,
                .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"), fromStaleCache: true)),
            (.creditLimited, .creditLimited(pulse: ResearchBarFixtures.pulse("pulse-credit-limited"))),
        ]
    }

    private static func allItems(_ sections: [ResearchBarMenuRenderSection]) -> [ResearchBarMenuItem] {
        sections.flatMap(\.items)
    }

    private static func allTitles(_ sections: [ResearchBarMenuRenderSection]) -> [String] {
        var titles: [String] = []
        for section in sections {
            if let title = section.title { titles.append(title) }
            titles.append(contentsOf: section.items.map(\.title))
        }
        return titles
    }

    private static func hasTrend(_ sections: [ResearchBarMenuRenderSection]) -> Bool {
        self.allItems(sections).contains { $0.kind == .trend }
    }

    private static func actions(_ sections: [ResearchBarMenuRenderSection]) -> [ResearchBarMenuAction] {
        self.allItems(sections).compactMap { item in
            if case let .action(action) = item.kind { return action }
            return nil
        }
    }
}
