import Foundation

// MARK: - ResearchPulseRedactor

/// Defensive, client-side redaction for the research pulse (guide §8).
///
/// The Corbis backend redacts by construction, but the client adds a second
/// layer: a payload that trips a violation must never render. A leak-like
/// fixture must fail tests; in release, the menu shows a safe error instead.
///
/// Two leak classes are detected:
/// 1. the internal author id pattern `^A\d+$` (and ids embedded in URLs/text), and
/// 2. backend/provider/source names (`openalex`, `semantic scholar`, `ssrn`, ...).
public enum ResearchPulseRedactor {
    public struct Violation: Equatable, Sendable {
        public enum Kind: Equatable, Sendable {
            case internalAuthorID
            /// Carries the matched name for debug logs only; never surface it to users.
            case backendSourceName(String)
        }

        public let field: String
        public let kind: Kind

        public init(field: String, kind: Kind) {
            self.field = field
            self.kind = kind
        }
    }

    /// Backend/provider/source names that must never reach the client surface
    /// (guide §8 item 2). Matched case-insensitively as substrings.
    static let backendNames: [String] = [
        "openalex",
        "openalexid",
        "semantic scholar",
        "ssrn",
        "hybrid_search",
        "sourceid",
        "authorid",
    ]

    // MARK: Scanning

    /// Scan every user-facing string on a decoded pulse.
    public static func scan(_ pulse: ResearchPulse) -> [Violation] {
        var violations: [Violation] = []

        func check(_ value: String?, field: String) {
            guard let value, !value.isEmpty else { return }
            if self.containsInternalAuthorID(value) {
                violations.append(Violation(field: field, kind: .internalAuthorID))
            }
            for name in self.backendSourceNames(in: value) {
                violations.append(Violation(field: field, kind: .backendSourceName(name)))
            }
        }

        check(pulse.displayName, field: "displayName")
        check(pulse.affiliation, field: "affiliation")
        check(pulse.role, field: "role")
        check(pulse.sector, field: "sector")
        check(pulse.companyName, field: "companyName")
        check(pulse.plan, field: "plan")
        check(pulse.orcid, field: "orcid")
        check(pulse.googleScholarId, field: "googleScholarId")
        check(pulse.googleScholarUrl?.absoluteString, field: "googleScholarUrl")
        check(pulse.lowConfidence.reason, field: "lowConfidence.reason")
        for (index, link) in pulse.profileLinks.enumerated() {
            check(link.label, field: "profileLinks[\(index)].label")
            check(link.url.absoluteString, field: "profileLinks[\(index)].url")
        }

        return violations
    }

    /// Catch-all scan of the raw JSON text, for fields the typed model does not surface.
    public static func scanRawJSON(_ data: Data) -> [Violation] {
        guard let text = String(data: data, encoding: .utf8) else { return [] }
        var violations: [Violation] = []
        if self.containsInternalAuthorID(text) {
            violations.append(Violation(field: "rawJSON", kind: .internalAuthorID))
        }
        for name in self.backendSourceNames(in: text) {
            violations.append(Violation(field: "rawJSON", kind: .backendSourceName(name)))
        }
        return violations
    }

    public static func isClean(_ pulse: ResearchPulse) -> Bool {
        self.scan(pulse).isEmpty
    }

    // MARK: Matchers (exposed for unit tests)

    /// True when the string contains the internal author id pattern: a token that
    /// is exactly `A` followed by digits (`^A\d+$`), or an embedded `A` followed by
    /// five or more digits (covers ids inside URLs and concatenated text).
    public static func containsInternalAuthorID(_ string: String) -> Bool {
        let tokens = string.split { !$0.isLetter && !$0.isNumber }
        for token in tokens where self.isAuthorIDToken(token) {
            return true
        }
        return self.containsEmbeddedAuthorID(string)
    }

    /// Canonical backend/source names present in the string (case-insensitive substring).
    public static func backendSourceNames(in string: String) -> [String] {
        let haystack = string.lowercased()
        return self.backendNames.filter { haystack.contains($0) }
    }

    // MARK: Private

    private static func isASCIIDigit(_ character: Character) -> Bool {
        character >= "0" && character <= "9"
    }

    private static func isAuthorIDToken(_ token: Substring) -> Bool {
        guard let first = token.first, first == "A" else { return false }
        let rest = token.dropFirst()
        guard !rest.isEmpty else { return false }
        return rest.allSatisfy(self.isASCIIDigit)
    }

    private static func containsEmbeddedAuthorID(_ string: String) -> Bool {
        let characters = Array(string)
        var index = 0
        while index < characters.count {
            if characters[index] == "A" {
                var digits = 0
                var lookahead = index + 1
                while lookahead < characters.count, self.isASCIIDigit(characters[lookahead]) {
                    digits += 1
                    lookahead += 1
                }
                if digits >= 5 {
                    return true
                }
            }
            index += 1
        }
        return false
    }
}
