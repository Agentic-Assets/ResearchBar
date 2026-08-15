import CodexBarCore
import Foundation
import Testing
@testable import CodexBar

struct ResearchPulseMenuFactoryTests {
    // MARK: Every state has coverage and is non-empty

    @Test
    func `every state produces non empty shaped sections`() throws {
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
    func `not tracked and tracking omit trend and delta entries`() throws {
        for name in ["pulse-linked-not-tracked", "pulse-linked-tracking"] {
            let sections = try ResearchPulseMenuFactory.makeSections(
                from: .loaded(pulse: ResearchBarFixtures.pulse(name), fromStaleCache: false))
            #expect(!Self.hasTrend(sections), "\(name) should not render a trend")
            #expect(!Self.allTitles(sections).contains { $0.contains("+") }, "\(name) should not render a delta")
        }
    }

    @Test
    func `tracked renders trend`() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"), fromStaleCache: false))
        #expect(Self.hasTrend(sections))
        #expect(Self.allTitles(sections).contains { $0.contains("+7") })
    }

    @Test
    func `tracked before fifty two week comparator omits only fifty two week row`() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(
                pulse: ResearchBarFixtures.pulse("pulse-tracked-no-52w-comparator"),
                fromStaleCache: false))
        let titles = Self.allTitles(sections)

        #expect(Self.hasTrend(sections))
        #expect(titles.contains("Past 7 days: +7"))
        #expect(!titles.contains { $0.hasPrefix("Past 52 weeks:") })
    }

    // MARK: Industry profile shows no zeroed widgets

    @Test
    func `industry profile shows no zeroed citation widgets`() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-industry-profile"), fromStaleCache: false))
        let titles = Self.allTitles(sections)
        #expect(!titles.contains { $0.localizedCaseInsensitiveContains("Citations") })
        #expect(!titles.contains { $0 == "0" })
        #expect(!Self.hasTrend(sections))
    }

    @Test
    func `dual contract rows reach renderable menu titles`() throws {
        let limited = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-contract-limited"), fromStaleCache: false))
        let limitedTitles = Self.allTitles(limited)
        #expect(limitedTitles.contains("Credits: 12.5"))
        #expect(limitedTitles.contains("Indexed works: 21"))

        let unlimited = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-contract-unlimited"), fromStaleCache: false))
        #expect(Self.allTitles(unlimited).contains("Credits: Unlimited"))
        #expect(Self.allTitles(unlimited).contains("Indexed works: 24"))

        // Future mixed-version tolerance: explicit new null remains authoritative.
        let authoritativeNull = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(
                pulse: ResearchBarFixtures.pulse("pulse-contract-null-indexed-works"),
                fromStaleCache: false))
        #expect(!Self.allTitles(authoritativeNull).contains { $0.hasPrefix("Indexed works:") })

        let unavailable = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-contract-no-balances"), fromStaleCache: false))
        #expect(!Self.allTitles(unavailable).contains { $0.hasPrefix("Credits:") })
    }

    // MARK: Action gating

    @Test
    func `credit limited has no refresh action`() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .creditLimited(pulse: ResearchBarFixtures.pulse("pulse-credit-limited")))
        #expect(!Self.actions(sections).contains(.refresh))
    }

    @Test
    func `credit limited fallback labels retained context cached and omits prior balance`() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .creditLimited(pulse: ResearchBarFixtures.pulse("pulse-contract-limited")))
        let titles = Self.allTitles(sections)

        #expect(titles.contains { $0.hasPrefix("Cached:") })
        #expect(titles.contains("Plan: academic"))
        #expect(titles.contains("Corbis credits are used up"))
        #expect(!titles.contains { $0.hasPrefix("Credits:") })
        #expect(!titles.contains { $0.contains("12.5") })
    }

    @Test
    func `unlinked shows identity confirmation action`() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-unlinked"), fromStaleCache: false))
        #expect(Self.actions(sections).contains(.reviewIdentity))
    }

    @Test
    func `low confidence shows review action and notice`() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-low-confidence"), fromStaleCache: false))
        #expect(Self.actions(sections).contains(.reviewIdentity))
        #expect(Self.allItems(sections).contains { $0.kind == .notice })
    }

    @Test
    func `stale cache shows refresh and notice`() throws {
        let sections = try ResearchPulseMenuFactory.makeSections(
            from: .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"), fromStaleCache: true))
        #expect(Self.actions(sections).contains(.refresh))
        #expect(Self.allItems(sections).contains { $0.kind == .notice })
    }

    @Test
    func `profile link actions use supplied UR ls only`() throws {
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
    func `leak like input collapses to safe error with no leak`() throws {
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
    func `no state leaks backend names or internal identifiers into titles`() throws {
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

    // MARK: Host-menu injection (merged status menu already provides app-level Quit)

    @Test
    func `host menu sections drop quit to avoid duplicate in merged menu`() throws {
        for (state, input) in try Self.inputsByState() {
            let sections = ResearchPulseMenuFactory.makeHostMenuSections(from: input)
            #expect(
                !Self.actions(sections).contains(.quit),
                "host menu for \(state) must not duplicate the app-level Quit")
            #expect(!Self.allItems(sections).isEmpty, "host menu for \(state) should still have content")
        }
    }

    @Test
    func `host menu sections preserve non quit actions`() {
        // .notConnected exposes [.connect, .openSettings, .quit]; the host variant keeps the
        // research-specific actions and only drops the duplicate Quit.
        let sections = ResearchPulseMenuFactory.makeHostMenuSections(from: .notConnected)
        let actions = Self.actions(sections)
        #expect(actions.contains(.connect))
        #expect(actions.contains(.openSettings))
        #expect(!actions.contains(.quit))
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
