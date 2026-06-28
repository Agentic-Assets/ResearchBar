import Foundation
import Testing
@testable import CodexBarCore

struct ResearchPulseRedactorTests {
    @Test
    func cleanFixturesHaveNoViolations() throws {
        for name in ResearchBarFixtures.allPulseNames where name != "pulse-leak-like" {
            let pulse = try ResearchBarFixtures.pulse(name)
            #expect(ResearchPulseRedactor.scan(pulse).isEmpty, "decoded fixture \(name) should be clean")

            let data = try ResearchBarFixtures.data(name)
            #expect(ResearchPulseRedactor.scanRawJSON(data).isEmpty, "raw fixture \(name) should be clean")
        }
    }

    @Test
    func leakLikeFixtureIsRejected() throws {
        let pulse = try ResearchBarFixtures.pulse("pulse-leak-like")
        #expect(!ResearchPulseRedactor.isClean(pulse))

        let kinds = ResearchPulseRedactor.scan(pulse).map(\.kind)
        #expect(kinds.contains(.internalAuthorID))
        #expect(kinds.contains { kind in
            if case .backendSourceName = kind { return true }
            return false
        })

        let data = try ResearchBarFixtures.data("pulse-leak-like")
        #expect(!ResearchPulseRedactor.scanRawJSON(data).isEmpty)
    }

    @Test
    func detectsInternalAuthorIDInTokensAndEmbedded() {
        #expect(ResearchPulseRedactor.containsInternalAuthorID("Dr. Sam Rivera A5012345678"))
        #expect(ResearchPulseRedactor.containsInternalAuthorID("A123"))
        #expect(ResearchPulseRedactor.containsInternalAuthorID("https://openalex.org/A5012345678"))
        #expect(ResearchPulseRedactor.containsInternalAuthorID("RiveraA5012345678"))

        #expect(!ResearchPulseRedactor.containsInternalAuthorID("0000-0002-1825-0097"))
        #expect(!ResearchPulseRedactor.containsInternalAuthorID("abcDEF123"))
        #expect(!ResearchPulseRedactor.containsInternalAuthorID("Atlas 5 rocket"))
        #expect(!ResearchPulseRedactor.containsInternalAuthorID("Area 51"))
    }

    @Test
    func detectsBackendSourceNames() {
        #expect(ResearchPulseRedactor.backendSourceNames(in: "https://openalex.org/A5").contains("openalex"))
        #expect(ResearchPulseRedactor.backendSourceNames(in: "Resolved via Semantic Scholar")
            .contains("semantic scholar"))
        #expect(ResearchPulseRedactor.backendSourceNames(in: "linked from SSRN").contains("ssrn"))
        #expect(ResearchPulseRedactor.backendSourceNames(in: "openalexId leaked").contains("openalexid"))
        #expect(ResearchPulseRedactor.backendSourceNames(in: "University of Tulsa").isEmpty)
        #expect(ResearchPulseRedactor.backendSourceNames(in: "Commercial Real Estate").isEmpty)
    }
}
