import CodexBarCore
import Foundation
import Testing

struct ResearchBarStatusIconModelTests {
    // MARK: build/09 accessibility table

    @Test
    func notConnectedReadsNotConnected() {
        let model = ResearchPulseStatusIconModel.make(from: .notConnected)
        #expect(model.accessibilityValue == "Not connected")
    }

    @Test
    func notTrackedReadsTrackingNotStarted() throws {
        let model = try ResearchPulseStatusIconModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-not-tracked"),
            fromStaleCache: false))
        #expect(model.accessibilityValue == "Citation tracking not started")
    }

    @Test
    func trackedReadsTotalCitationsAndSevenDayDelta() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")
        let model = ResearchPulseStatusIconModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))
        let citations = try #require(pulse.totalCitations)
        let delta = try #require(pulse.citationDelta7d)
        #expect(model.accessibilityValue == "\(citations) citations, +\(delta) this week")
    }

    @Test
    func staleCacheReadsCurrentValuePlusStaleLabel() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")
        let model = ResearchPulseStatusIconModel.make(from: .loaded(pulse: pulse, fromStaleCache: true))
        let citations = try #require(pulse.totalCitations)
        #expect(model.accessibilityValue == "\(citations) citations, cached")
        #expect(model.accessibilityValue.localizedCaseInsensitiveContains("cached"))
    }

    @Test
    func creditLimitedReadsCreditLabel() throws {
        let model = try ResearchPulseStatusIconModel
            .make(from: .creditLimited(pulse: ResearchBarFixtures.pulse("pulse-credit-limited")))
        #expect(model.accessibilityValue.localizedCaseInsensitiveContains("credit"))
    }

    @Test
    func safeErrorReadsNeutralLabel() {
        let model = ResearchPulseStatusIconModel.make(from: .safeError)
        #expect(model.accessibilityValue == "Pulse unavailable right now")
    }

    // MARK: No-leak guarantees

    @Test
    func leakLikePulseCollapsesToNeutralSafeError() throws {
        let model = try ResearchPulseStatusIconModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-leak-like"),
            fromStaleCache: false))
        #expect(model.accessibilityValue == "Pulse unavailable right now")
        #expect(!ResearchPulseRedactor.containsInternalAuthorID(model.accessibilityValue))
        #expect(ResearchPulseRedactor.backendSourceNames(in: model.accessibilityValue).isEmpty)
        #expect(!ResearchPulseRedactor.containsInternalAuthorID(model.glanceLabel))
    }

    @Test
    func noFixtureLeaksSensitiveTextIntoIconModel() throws {
        for name in ResearchBarFixtures.allPulseNames {
            let pulse = try ResearchBarFixtures.pulse(name)
            let model = ResearchPulseStatusIconModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))
            for text in [model.accessibilityValue, model.glanceLabel, model.symbolName] {
                #expect(!ResearchPulseRedactor.containsInternalAuthorID(text), "leak in \(name): \(text)")
                #expect(ResearchPulseRedactor.backendSourceNames(in: text).isEmpty, "backend name in \(name): \(text)")
            }
        }
    }

    @Test
    func everyInputProducesANonEmptySymbol() throws {
        let inputs: [ResearchPulseMenuInput] = try [
            .notConnected,
            .invalidCredential,
            .safeError,
            .creditLimited(pulse: ResearchBarFixtures.pulse("pulse-credit-limited")),
            .loaded(pulse: ResearchBarFixtures.pulse("pulse-unlinked"), fromStaleCache: false),
            .loaded(pulse: ResearchBarFixtures.pulse("pulse-industry-profile"), fromStaleCache: false),
            .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-not-tracked"), fromStaleCache: false),
            .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracking"), fromStaleCache: false),
            .loaded(pulse: ResearchBarFixtures.pulse("pulse-low-confidence"), fromStaleCache: false),
            .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"), fromStaleCache: false),
            .loaded(pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"), fromStaleCache: true),
        ]
        for input in inputs {
            let model = ResearchPulseStatusIconModel.make(from: input)
            #expect(!model.symbolName.isEmpty)
            #expect(!model.accessibilityValue.isEmpty)
            #expect(!model.glanceLabel.isEmpty)
        }
    }
}
