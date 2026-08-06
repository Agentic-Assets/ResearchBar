import CodexBarCore
import Foundation
import Testing

struct ResearchBarStatusIconModelTests {
    // MARK: build/09 accessibility table

    @Test
    func `not connected reads not connected`() {
        let model = ResearchPulseStatusIconModel.make(from: .notConnected)
        #expect(model.accessibilityValue == "Not connected")
    }

    @Test
    func `not tracked reads tracking not started`() throws {
        let model = try ResearchPulseStatusIconModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-linked-not-tracked"),
            fromStaleCache: false))
        #expect(model.accessibilityValue == "Citation tracking not started")
    }

    @Test
    func `tracked reads total citations and seven day delta`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")
        let model = ResearchPulseStatusIconModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))
        let citations = try #require(pulse.totalCitations)
        let delta = try #require(pulse.citationDelta7d)
        #expect(model.accessibilityValue == "\(citations) citations, +\(delta) this week")
    }

    @Test
    func `stale cache reads current value plus stale label`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")
        let model = ResearchPulseStatusIconModel.make(from: .loaded(pulse: pulse, fromStaleCache: true))
        let citations = try #require(pulse.totalCitations)
        #expect(model.accessibilityValue == "\(citations) citations, cached")
        #expect(model.accessibilityValue.localizedCaseInsensitiveContains("cached"))
    }

    @Test
    func `source aware academic profile does not surface legacy aggregate in status item`() throws {
        let base = try ResearchBarFixtures.data("pulse-academic-profile-v1")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        object["totalCitations"] = 999
        let pulse = try ResearchPulse.decode(JSONSerialization.data(withJSONObject: object))

        let current = ResearchPulseStatusIconModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))
        let stale = ResearchPulseStatusIconModel.make(from: .loaded(pulse: pulse, fromStaleCache: true))

        #expect(current.glanceLabel == "•")
        #expect(current.accessibilityValue == "Citation tracking not started")
        #expect(stale.glanceLabel == "•")
        #expect(stale.accessibilityValue == "Showing cached source-specific research pulse")
        #expect(!current.accessibilityValue.contains("999"))
        #expect(!stale.accessibilityValue.contains("999"))
    }

    @Test
    func `credit limited reads credit label`() throws {
        let model = try ResearchPulseStatusIconModel
            .make(from: .creditLimited(pulse: ResearchBarFixtures.pulse("pulse-credit-limited")))
        #expect(model.accessibilityValue.localizedCaseInsensitiveContains("credit"))
    }

    @Test
    func `unclean credit limited pulse reads only credit notice`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-leak-like")
        let model = ResearchPulseStatusIconModel.make(from: .creditLimited(pulse: pulse))

        #expect(model.glanceLabel == "•")
        #expect(model.accessibilityValue == "Corbis credits are used up")
        #expect(!ResearchPulseRedactor.containsInternalAuthorID(model.accessibilityValue))
    }

    @Test
    func `safe error reads neutral label`() {
        let model = ResearchPulseStatusIconModel.make(from: .safeError)
        #expect(model.accessibilityValue == "Pulse unavailable right now")
    }

    // MARK: No-leak guarantees

    @Test
    func `leak like pulse collapses to neutral safe error`() throws {
        let model = try ResearchPulseStatusIconModel.make(from: .loaded(
            pulse: ResearchBarFixtures.pulse("pulse-leak-like"),
            fromStaleCache: false))
        #expect(model.accessibilityValue == "Pulse unavailable right now")
        #expect(!ResearchPulseRedactor.containsInternalAuthorID(model.accessibilityValue))
        #expect(ResearchPulseRedactor.backendSourceNames(in: model.accessibilityValue).isEmpty)
        #expect(!ResearchPulseRedactor.containsInternalAuthorID(model.glanceLabel))
    }

    @Test
    func `no fixture leaks sensitive text into icon model`() throws {
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
    func `every input produces A non empty symbol`() throws {
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
