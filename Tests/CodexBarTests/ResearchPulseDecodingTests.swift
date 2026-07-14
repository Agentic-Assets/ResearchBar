import Foundation
import Testing
@testable import CodexBarCore

struct ResearchPulseDecodingTests {
    @Test
    func decodesEveryFixtureWithoutThrowing() throws {
        for name in ResearchBarFixtures.allPulseNames {
            _ = try ResearchBarFixtures.pulse(name)
        }
    }

    @Test
    func decodesLinkedNotTrackedFields() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-linked-not-tracked")

        #expect(pulse.profileStatus == .linkedResearcher)
        #expect(pulse.displayName == "Dr. Rhea Calloway")
        #expect(pulse.affiliation == "University of Tulsa")
        #expect(pulse.plan == "academic")
        #expect(pulse.creditsRemaining == 84.0)
        #expect(pulse.orcid == "0000-0002-1825-0097")
        #expect(pulse.totalCitations == 1284)
        #expect(pulse.hIndex == 11)
        #expect(pulse.trackedPaperCount == 18)
        #expect(pulse.citationDelta7d == nil)
        #expect(pulse.citationDelta52w == nil)
        #expect(pulse.sparkline52w == nil)
        #expect(pulse.citationHistoryStatus == .notYetTracked)
        #expect(pulse.lowConfidence.identity == false)
        #expect(pulse.lowConfidence.citations == false)
        #expect(pulse.lowConfidence.reason == nil)
        #expect(pulse.profileLinks.count == 2)
        #expect(pulse.profileLinks.first?.label == "ORCID")
        #expect(pulse.etag == "sha256:9f2c1ab4")
        #expect(pulse.staleAfter > pulse.fetchedAt)
    }

    @Test
    func decodesTrackedTrendsAndFractionalSecondDates() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")

        #expect(pulse.citationHistoryStatus == .tracked)
        #expect(pulse.citationDelta7d == 7)
        #expect(pulse.citationDelta52w == 182)
        #expect(pulse.sparkline52w?.count == 52)
        #expect(pulse.sparkline52w?.last == 1284)
        // Fractional-second ISO 8601 ("...:00.512Z") must parse, not throw.
        #expect(pulse.staleAfter > pulse.fetchedAt)
    }

    @Test
    func trackedWithSevenDayComparatorDoesNotRequireFiftyTwoWeekComparator() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-tracked-no-52w-comparator")

        #expect(pulse.citationHistoryStatus == .tracked)
        #expect(pulse.citationDelta7d == 7)
        #expect(pulse.citationDelta52w == nil)
        #expect(pulse.sparkline52w == [1238, 1244, 1250, 1259, 1267, 1275, 1280, 1284])
        #expect(pulse.isSemanticallyValid)
        #expect(pulse.hasRenderableTrend)
    }

    @Test
    func decodesUnlinkedAsFirstClassNullState() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-unlinked")

        #expect(pulse.profileStatus == .unlinked)
        #expect(pulse.orcid == nil)
        #expect(pulse.displayName == nil)
        #expect(pulse.totalCitations == nil)
        #expect(pulse.hIndex == nil)
        #expect(pulse.trackedPaperCount == nil)
        #expect(pulse.lowConfidence.identity == true)
        #expect(pulse.profileLinks.isEmpty)
    }

    @Test
    func decodesIndustryProfileWithNullPublicationMetrics() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-industry-profile")

        #expect(pulse.profileStatus == .industryProfile)
        #expect(pulse.role == "VP of Research")
        #expect(pulse.sector == "Commercial Real Estate")
        #expect(pulse.companyName == "Meridian Capital Partners")
        #expect(pulse.totalCitations == nil)
        #expect(pulse.hIndex == nil)
        #expect(pulse.trackedPaperCount == nil)
    }

    @Test
    func decodesProfileOnlyAndTrackingStates() throws {
        let profileOnly = try ResearchBarFixtures.pulse("pulse-profile-only")
        #expect(profileOnly.profileStatus == .profileOnly)
        #expect(profileOnly.totalCitations == nil)
        #expect(profileOnly.lowConfidence.identity == true)

        let tracking = try ResearchBarFixtures.pulse("pulse-linked-tracking")
        #expect(tracking.citationHistoryStatus == .tracking)
        #expect(tracking.citationDelta7d == nil)
        #expect(tracking.sparkline52w == nil)
        #expect(tracking.googleScholarUrl?.absoluteString == "https://scholar.google.com/citations?user=abcDEF123")
    }

    @Test
    func decodesLimitedCreditBalanceAndPrefersIndexedWorksCount() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-contract-limited")

        #expect(pulse.creditBalance == .limited(remaining: 12.5))
        #expect(pulse.creditsRemaining == 12.5)
        #expect(pulse.indexedWorksCount == 21)
        #expect(pulse.trackedPaperCount == 21)
        #expect(pulse.resolvedIndexedWorksCount == 21)
    }

    @Test
    func decodesCurrentUnlimitedDualEmission() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-contract-unlimited")

        #expect(pulse.creditBalance == .unlimited)
        #expect(pulse.creditsRemaining == 0)
        #expect(pulse.indexedWorksCount == 24)
        #expect(pulse.trackedPaperCount == nil)
        #expect(pulse.resolvedIndexedWorksCount == 24)
        #expect(!pulse.hasNoPublicationMetrics)
    }

    @Test
    func futurePostWindowPayloadToleratesOmittedLegacyFields() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-future-post-window-unlimited")

        #expect(pulse.creditBalance == .unlimited)
        #expect(pulse.creditsRemaining == nil)
        #expect(pulse.indexedWorksCount == 24)
        #expect(pulse.trackedPaperCount == nil)
    }

    @Test
    func futureMalformedNewFieldsFallBackToLegacyWithoutFailingPulse() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-contract-malformed-new-fields")

        #expect(pulse.creditBalance == nil)
        #expect(pulse.resolvedCreditBalance == .limited(remaining: 9.25))
        #expect(pulse.indexedWorksCount == nil)
        #expect(pulse.resolvedIndexedWorksCount == 18)
    }

    @Test
    func futureMixedVersionExplicitNullIndexedWorksCountDoesNotFallBackToLegacyMirror() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-contract-null-indexed-works")

        #expect(pulse.indexedWorksCount == nil)
        #expect(pulse.trackedPaperCount == 18)
        #expect(pulse.resolvedIndexedWorksCount == nil)
        #expect(pulse.hasNoPublicationMetrics)
    }

    @Test
    func futurePayloadMissingBothCreditRepresentationsDoesNotFabricateZero() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-contract-no-balances")

        #expect(pulse.creditBalance == nil)
        #expect(pulse.creditsRemaining == nil)
        #expect(pulse.resolvedCreditBalance == nil)
    }
}
