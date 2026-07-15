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
    func allowsDeclaredAcademicProfileSourceLabelsInRawPayload() throws {
        let data = try ResearchBarFixtures.data("pulse-academic-profile-v1")

        #expect(ResearchPulseRedactor.scanRawJSON(data).isEmpty)
    }

    @Test
    func rejectsPrivateEmailInsideAcademicProfile() throws {
        let base = try ResearchBarFixtures.data("pulse-academic-profile-v1")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        var profile = try #require(object["academicProfile"] as? [String: Any])
        var identity = try #require(profile["identity"] as? [[String: Any]])
        identity[0]["value"] = "private.researcher@example.edu"
        profile["identity"] = identity
        object["academicProfile"] = profile

        let mutated = try JSONSerialization.data(withJSONObject: object)
        let violations = ResearchPulseRedactor.scanRawJSON(mutated)
        #expect(!violations.isEmpty)
        #expect(violations.contains { $0.kind == .privateIdentityEvidence })
    }

    @Test
    func rejectsPrivateOnlyFieldsAndCredentialsInsideAcademicProfile() throws {
        let base = try ResearchBarFixtures.data("pulse-academic-profile-v1")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        var profile = try #require(object["academicProfile"] as? [String: Any])
        profile["openalexAuthorId"] = "A5012345678"
        profile["credential"] = "corbis_mcp_privatevalue"
        object["academicProfile"] = profile

        let violations = try ResearchPulseRedactor.scanRawJSON(
            JSONSerialization.data(withJSONObject: object))
        #expect(violations.contains { $0.kind == .privateIdentityEvidence })
        #expect(violations.contains { $0.kind == .internalAuthorID })
        #expect(violations.contains { $0.kind == .sensitiveCredential })
    }

    @Test
    func rejectsSemanticPrivateKeyVariantsInsideAcademicProfile() throws {
        let base = try ResearchBarFixtures.data("pulse-academic-profile-v1")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        var profile = try #require(object["academicProfile"] as? [String: Any])
        profile["private_email"] = "hidden@example.edu"
        profile["emailAddress"] = "hidden@example.edu"
        profile["author_id"] = "private-author"
        profile["internalUserId"] = "private-user"
        profile["accessToken"] = "opaque"
        profile["api_key"] = "opaque"
        object["academicProfile"] = profile

        let violations = try ResearchPulseRedactor.scanRawJSON(
            JSONSerialization.data(withJSONObject: object))
        #expect(violations.count(where: { $0.kind == .privateIdentityEvidence }) >= 6)
    }

    @Test
    func rejectsMissingOrNonStringAcademicIdentityVisibility() throws {
        for visibility: Any? in [nil, 1] {
            let base = try ResearchBarFixtures.data("pulse-academic-profile-v1")
            var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
            var profile = try #require(object["academicProfile"] as? [String: Any])
            var identity = try #require(profile["identity"] as? [[String: Any]])
            identity[0]["visibility"] = visibility
            profile["identity"] = identity
            object["academicProfile"] = profile

            let violations = try ResearchPulseRedactor.scanRawJSON(
                JSONSerialization.data(withJSONObject: object))
            #expect(violations.contains { $0.kind == .privateIdentityEvidence })
        }
    }

    @Test
    func typedAcademicProfileScanProtectsCachedPayloads() throws {
        let base = try ResearchBarFixtures.data("pulse-academic-profile-v1")
        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        var profile = try #require(object["academicProfile"] as? [String: Any])
        var identity = try #require(profile["identity"] as? [[String: Any]])
        identity[0]["value"] = "cached.private@example.edu"
        profile["identity"] = identity
        object["academicProfile"] = profile

        let pulse = try ResearchPulse.decode(JSONSerialization.data(withJSONObject: object))
        #expect(ResearchPulseRedactor.scan(pulse).contains { $0.kind == .privateIdentityEvidence })
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
    func detectsSensitiveCredential() {
        #expect(ResearchPulseRedactor.containsSensitiveCredential("corbis_mcp_abc123def456"))
        #expect(ResearchPulseRedactor.containsSensitiveCredential("Authorization: Bearer abc.def"))
        #expect(ResearchPulseRedactor.containsSensitiveCredential("CORBIS_MCP_UPPER"))
        #expect(!ResearchPulseRedactor.containsSensitiveCredential("Dr. Jane Researcher"))
        #expect(!ResearchPulseRedactor.containsSensitiveCredential("bearings and gears"))
    }

    @Test
    func scanFlagsCredentialLeakInRenderedField() throws {
        // A clean pulse stays clean; a token smuggled into a rendered (typed) field trips the
        // scan so the pulse never renders. The raw-JSON catch-all deliberately does not flag
        // credentials (a tool-error message is sanitized instead), so this guarantee lives on
        // the typed-field scan path.
        let base = try ResearchBarFixtures.data("pulse-linked-tracked")
        let clean = try ResearchPulse.decode(base)
        #expect(ResearchPulseRedactor.scan(clean).isEmpty)

        var object = try #require(try JSONSerialization.jsonObject(with: base) as? [String: Any])
        object["displayName"] = "Dr. Rhea corbis_mcp_leakedsecret"
        let mutated = try JSONSerialization.data(withJSONObject: object)
        let pulse = try ResearchPulse.decode(mutated)
        #expect(ResearchPulseRedactor.scan(pulse).contains { $0.kind == .sensitiveCredential })
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
