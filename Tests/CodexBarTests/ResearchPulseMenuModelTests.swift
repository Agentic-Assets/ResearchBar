import Foundation
import Testing
@testable import CodexBarCore

struct ResearchPulseMenuModelTests {
    // MARK: Connection / error states

    @Test
    func notConnectedShowsConnectAndNoMetrics() {
        let model = ResearchPulseMenuModel.make(from: .notConnected)
        #expect(model.state == .notConnected)
        #expect(model.actions.contains(.connect))
        #expect(!model.hasSparkline)
        #expect(!model.renderedStrings.contains { $0.localizedCaseInsensitiveContains("Citations") })
    }

    @Test
    func invalidCredentialShowsReconnect() {
        let model = ResearchPulseMenuModel.make(from: .invalidCredential)
        #expect(model.state == .invalidCredential)
        #expect(model.actions.contains(.reconnect))
    }

    // MARK: profileStatus → state mapping (all four states)

    @Test
    func unlinkedRendersIdentityConfirmationNotAProfile() throws {
        let model = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-unlinked"),
            fromStaleCache: false))
        #expect(model.state == .identityUnlinked)
        #expect(model.actions.contains(.reviewIdentity))
        #expect(!model.hasSparkline)
        // Unlinked must not invent metrics.
        #expect(!model.renderedStrings.contains { $0.localizedCaseInsensitiveContains("h-index") })
    }

    @Test
    func industryProfileShowsProfessionalPulseWithoutZeroedMetrics() throws {
        let model = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-industry-profile"),
            fromStaleCache: false))
        #expect(model.state == .industryProfile)
        // Professional identity is shown.
        #expect(model.renderedStrings.contains { $0.localizedCaseInsensitiveContains("Meridian") })
        // Null publication metrics must not become "0".
        #expect(!model.renderedStrings.contains { $0.localizedCaseInsensitiveContains("Citations") })
        #expect(!model.renderedStrings.contains { $0 == "0" })
    }

    @Test
    func linkedNotTrackedAndTrackingOmitTrendNumbers() throws {
        let notTracked = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-not-tracked"),
            fromStaleCache: false))
        #expect(notTracked.state == .loadedNotTracked)
        #expect(!notTracked.hasSparkline)
        #expect(!notTracked.renderedStrings.contains { $0.contains("+") })

        let tracking = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-tracking"),
            fromStaleCache: false))
        #expect(tracking.state == .loadedTracking)
        #expect(!tracking.hasSparkline)
        #expect(!tracking.renderedStrings.contains { $0.contains("+") })
    }

    @Test
    func linkedTrackedShowsTrendsAndSparkline() throws {
        let model = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"),
            fromStaleCache: false))
        #expect(model.state == .loadedTracked)
        #expect(model.hasSparkline)
        #expect(model.renderedStrings.contains { $0.contains("+7") })
    }

    @Test
    func trackedBeforeFiftyTwoWeekComparatorRendersAvailableTrendOnly() throws {
        let model = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-tracked-no-52w-comparator"),
            fromStaleCache: false))

        #expect(model.state == .loadedTracked)
        #expect(model.hasSparkline)
        #expect(model.renderedStrings.contains("Past 7 days"))
        #expect(model.renderedStrings.contains("+7"))
        #expect(!model.renderedStrings.contains("Past 52 weeks"))
    }

    @Test
    func lowConfidenceShowsNoticeAndReviewAction() throws {
        let model = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-low-confidence"),
            fromStaleCache: false))
        #expect(model.state == .loadedLowConfidence)
        #expect(model.hasNotice)
    }

    // MARK: Cross-cutting modifiers

    @Test
    func staleCacheShowsFetchedTimeAndRefresh() throws {
        let model = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"),
            fromStaleCache: true))
        #expect(model.state == .staleCache)
        #expect(model.actions.contains(.refresh))
        #expect(model.hasNotice)
    }

    @Test
    func creditLimitedHasNoAutomaticRefreshAction() throws {
        let model = try ResearchPulseMenuModel
            .make(from: .creditLimited(pulse: ResearchBarFixtures.pulse("pulse-credit-limited")))
        #expect(model.state == .creditLimited)
        #expect(!model.actions.contains(.refresh))
    }

    @Test
    func creditAndWorksRowsUseDualContractWithoutFabricatingValues() throws {
        let limited = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-contract-limited"),
            fromStaleCache: false))
        #expect(limited.renderedStrings.contains("12.5"))
        #expect(limited.renderedStrings.contains("Indexed works"))
        #expect(limited.renderedStrings.contains("21"))
        #expect(!limited.renderedStrings.contains("Tracked papers"))

        let unlimited = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-contract-unlimited"),
            fromStaleCache: false))
        #expect(unlimited.renderedStrings.contains("Unlimited"))

        let legacyFallback = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-contract-malformed-new-fields"),
            fromStaleCache: false))
        #expect(legacyFallback.renderedStrings.contains("9.25"))
        #expect(legacyFallback.renderedStrings.contains("18"))

        // Future mixed-version tolerance: explicit new null remains authoritative.
        let authoritativeNull = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-contract-null-indexed-works"),
            fromStaleCache: false))
        #expect(!authoritativeNull.renderedStrings.contains("Indexed works"))
        #expect(!authoritativeNull.renderedStrings.contains("18"))

        let unavailable = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-contract-no-balances"),
            fromStaleCache: false))
        #expect(!unavailable.renderedStrings.contains("Credits"))
        #expect(!unavailable.renderedStrings.contains("0"))
    }

    // MARK: Redaction + semantic safety

    @Test
    func leakLikePulseCollapsesToSafeErrorWithNoLeakInRows() throws {
        let model = try ResearchPulseMenuModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-leak-like"),
            fromStaleCache: false))
        #expect(model.state == .safeError)
        for text in model.renderedStrings {
            #expect(!ResearchPulseRedactor.containsInternalAuthorID(text))
            #expect(ResearchPulseRedactor.backendSourceNames(in: text).isEmpty)
        }
    }

    @Test
    func trackedButIncompleteTrendsCollapsesToSafeError() {
        let broken = Self.makeLinkedPulse(citationHistoryStatus: .tracked, citationDelta7d: 5, sparkline52w: nil)
        let model = ResearchPulseMenuModel.make(from: .loaded(pulse: broken, fromStaleCache: false))
        #expect(model.state == .safeError)
        #expect(!model.hasSparkline)
    }

    @Test
    func trackedWithoutSevenDayDeltaCollapsesToSafeError() {
        let broken = Self.makeLinkedPulse(citationHistoryStatus: .tracked, sparkline52w: [95, 100])
        let model = ResearchPulseMenuModel.make(from: .loaded(pulse: broken, fromStaleCache: false))
        #expect(model.state == .safeError)
        #expect(!model.hasSparkline)
    }

    @Test
    func noStateLeaksBackendNamesOrInternalIDs() throws {
        for name in ResearchBarFixtures.allPulseNames {
            let pulse = try ResearchBarFixtures.pulse(name)
            let model = ResearchPulseMenuModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))
            for text in model.renderedStrings {
                #expect(!ResearchPulseRedactor.containsInternalAuthorID(text), "leak in \(name): \(text)")
                #expect(ResearchPulseRedactor.backendSourceNames(in: text).isEmpty, "backend name in \(name): \(text)")
            }
        }
    }

    // MARK: Helpers

    private static func makeLinkedPulse(
        profileStatus: ProfileStatus = .linkedResearcher,
        citationHistoryStatus: CitationHistoryStatus,
        citationDelta7d: Int? = nil,
        citationDelta52w: Int? = nil,
        sparkline52w: [Int]? = nil,
        lowConfidence: LowConfidence = LowConfidence(identity: false, citations: false, reason: nil)) -> ResearchPulse
    {
        ResearchPulse(
            profileStatus: profileStatus,
            displayName: "Dr. Test Researcher",
            affiliation: "Test University",
            role: nil,
            sector: nil,
            companyName: nil,
            plan: "academic",
            creditsRemaining: 50,
            orcid: "0000-0002-0000-0000",
            googleScholarId: nil,
            googleScholarUrl: nil,
            totalCitations: 100,
            hIndex: 5,
            trackedPaperCount: 10,
            citationDelta7d: citationDelta7d,
            citationDelta52w: citationDelta52w,
            sparkline52w: sparkline52w,
            citationHistoryStatus: citationHistoryStatus,
            lowConfidence: lowConfidence,
            profileLinks: [],
            fetchedAt: Date(timeIntervalSince1970: 1_750_000_000),
            staleAfter: Date(timeIntervalSince1970: 1_750_021_600),
            etag: "sha256:test")
    }
}
