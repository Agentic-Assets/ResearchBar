import CodexBarCore
import Foundation
import Testing

struct ResearchPulseCardModelTests {
    @Test
    func `academic profile uses A bounded source specific card`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-academic-profile-v1")
        let model = ResearchPulseCardModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))

        #expect(model.title == "Dr. Rhea Calloway")
        #expect(model.subtitle == "Assistant Professor of Finance · University of Tulsa")
        #expect(model.metrics.count == 2)
        #expect(model.metrics == [
            .init(id: "citations", label: "Citations", value: "0", detail: "Source-specific"),
            .init(id: "researchWorks", label: "Research works", value: "2"),
        ])
        #expect(model.dataQuality?.summary == "2 of 4 sources current & complete")
        #expect(model.dataQuality?.needsAttention == true)
        #expect(model.trend?.summary == "Citation tracking starts soon")
        #expect(model.actions.count <= 5)
        #expect(!model.actions.contains(.menuAction(.quit)))
        #expect(model.actions.contains(.menuAction(.refresh)))
        #expect(model.actions.contains(.menuAction(.openCorbis)))
        #expect(Set(model.actions.map(\.id)).count == model.actions.count)

        let visibleText = [model.title, model.subtitle, model.freshness, model.notice]
            .compactMap(\.self)
            + model.metrics.flatMap { [$0.label, $0.value, $0.detail].compactMap(\.self) }
            + [model.dataQuality?.summary, model.trend?.summary, model.plan, model.credit?.summary].compactMap(\.self)
        for value in visibleText {
            #expect(ResearchPulseRedactor.backendSourceNames(in: value).isEmpty)
            #expect(!ResearchPulseRedactor.containsInternalAuthorID(value))
        }
    }

    @Test
    func `tracked legacy pulse uses only verified trend values`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")
        let model = ResearchPulseCardModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))

        #expect(model.trend?.summary == "+7 this week")
        #expect(model.trend?.sparkline == pulse.sparkline52w)
    }

    @Test
    func `credit limited card treats retained pulse as cached evidence`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-contract-limited")
        let model = ResearchPulseCardModel.make(from: .creditLimited(pulse: pulse))

        #expect(model.state == .creditLimited)
        #expect(model.notice == "Corbis credits are used up")
        #expect(model.credit == nil)
        #expect(model.freshness?.hasPrefix("Cached · ") == true)
        #expect(!model.actions.contains(.menuAction(.refresh)))
    }

    @Test
    func `card projects plan and finite credits without a quota`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-contract-limited")
        let model = ResearchPulseCardModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))

        #expect(model.plan == pulse.plan)
        #expect(model.credit?.summary == "12.5 credits remaining")
        #expect(model.freshness?.hasPrefix("Updated ") == true)

        let stale = ResearchPulseCardModel.make(from: .loaded(pulse: pulse, fromStaleCache: true))
        #expect(stale.state == .staleCache)
        #expect(stale.credit?.summary == "12.5 credits remaining")
        #expect(stale.freshness?.hasPrefix("Cached · ") == true)
    }

    @Test
    func `card omits a whitespace only plan`() throws {
        let base = try ResearchBarFixtures.data("pulse-contract-limited")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        object["plan"] = " \n\t "
        let pulse = try ResearchPulse.decode(JSONSerialization.data(withJSONObject: object))

        let model = ResearchPulseCardModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))

        #expect(model.plan == nil)
    }

    @Test
    func `card projects unlimited and omits unavailable credits`() throws {
        let unlimitedPulse = try ResearchBarFixtures.pulse("pulse-contract-unlimited")
        let unavailablePulse = try ResearchBarFixtures.pulse("pulse-contract-no-balances")
        let unlimited = ResearchPulseCardModel.make(from: .loaded(
            pulse: unlimitedPulse,
            fromStaleCache: false))
        let unavailable = ResearchPulseCardModel.make(from: .loaded(
            pulse: unavailablePulse,
            fromStaleCache: false))

        #expect(unlimited.credit?.summary == "Unlimited credits")
        #expect(unavailable.credit == nil)
    }

    @Test
    func `card uses valid legacy credit fallback and omits negative credits`() throws {
        let malformedPulse = try ResearchBarFixtures.pulse("pulse-contract-malformed-new-fields")
        let malformed = ResearchPulseCardModel.make(from: .loaded(
            pulse: malformedPulse,
            fromStaleCache: false))
        #expect(malformed.credit?.summary == "9.25 credits remaining")

        let base = try ResearchBarFixtures.data("pulse-contract-limited")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        object["creditBalance"] = NSNull()
        object["creditsRemaining"] = -1
        let negative = try ResearchPulse.decode(JSONSerialization.data(withJSONObject: object))
        let model = ResearchPulseCardModel.make(from: .loaded(pulse: negative, fromStaleCache: false))

        #expect(model.credit == nil)
    }

    @Test
    func `unclean credit limited pulse fails closed`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-leak-like")
        let model = ResearchPulseCardModel.make(from: .creditLimited(pulse: pulse))

        #expect(model.title == "Corbis credits are used up")
        #expect(model.subtitle == nil)
        #expect(model.metrics.isEmpty)
        #expect(!model.actions.contains { action in
            if case .profileLink = action { return true }
            return false
        })
        for text in [model.title, model.notice].compactMap(\.self) {
            #expect(!ResearchPulseRedactor.containsInternalAuthorID(text))
            #expect(ResearchPulseRedactor.backendSourceNames(in: text).isEmpty)
        }
    }

    @Test
    func `unlinked pulse does not expose identity or profile links`() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-unlinked")
        let model = ResearchPulseCardModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))

        #expect(model.title == "Link your research identity")
        #expect(model.subtitle == nil)
        #expect(!model.actions.contains { action in
            if case .profileLink = action { return true }
            return false
        })
    }

    @Test
    func `unsupported academic profile does not fall back to legacy metrics`() throws {
        let base = try ResearchBarFixtures.data("pulse-academic-profile-v1")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        var profile = try #require(object["academicProfile"] as? [String: Any])
        profile["contractVersion"] = "academic-profile.v2"
        object["academicProfile"] = profile
        object["totalCitations"] = 999
        let pulse = try ResearchPulse.decode(JSONSerialization.data(withJSONObject: object))

        let model = ResearchPulseCardModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))

        #expect(model.metrics.isEmpty)
        #expect(model.dataQuality == nil)
        #expect(model.notice == "Research data needs a ResearchBar update")
    }
}
