import Foundation

// MARK: - ResearchPulseRedactor

/// Defensive, client-side redaction for the research pulse (guide §8).
///
/// The Corbis backend redacts by construction, but the client adds a second
/// layer: a payload that trips a violation must never render. A leak-like
/// fixture must fail tests; in release, the menu shows a safe error instead.
///
/// Three leak classes are detected:
/// 1. the internal author id pattern `^A\d+$` (and ids embedded in URLs/text),
/// 2. backend/provider/source names (`openalex`, `semantic scholar`, `ssrn`, ...), and
/// 3. a leaked bearer credential (`corbis_mcp_` token or a `Bearer ` header echo).
public enum ResearchPulseRedactor {
    public struct Violation: Equatable, Sendable {
        public enum Kind: Equatable, Sendable {
            case internalAuthorID
            /// Carries the matched name for debug logs only; never surface it to users.
            case backendSourceName(String)
            /// A bearer credential leaked into a rendered field. Carries no payload so the
            /// matched secret is never re-surfaced through the violation itself.
            case sensitiveCredential
            /// Private identity evidence or a private-only field entered the public contract.
            case privateIdentityEvidence
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
            if self.containsSensitiveCredential(value) {
                violations.append(Violation(field: field, kind: .sensitiveCredential))
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
        if let academicProfile = pulse.academicProfile {
            violations.append(contentsOf: self.scanAcademicProfile(academicProfile))
        }

        return violations
    }

    /// Catch-all scan of the raw JSON payload, for fields the typed model does not surface.
    ///
    /// The public `academic-profile.v1` contract deliberately carries source provenance such
    /// as `openalex` and `ssrn`. Those labels remain forbidden in legacy fields, but are not
    /// themselves a leak inside the declared academic-profile subtree. Internal author IDs
    /// remain forbidden everywhere.
    public static func scanRawJSON(_ data: Data) -> [Violation] {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return self.scanRawText(data)
        }

        var violations: [Violation] = []
        self.scanRawJSONObject(object, path: [], isAcademicProfile: false, violations: &violations)
        // Credential detection is deliberately NOT applied here. The raw-JSON gate runs before
        // the tool-error branch, where a `status: "error"` message carrying a token is meant to
        // be sanitized to a generic string by `CorbisMCPError.safeToolError`, not rejected
        // wholesale. The render-safety guarantee for credentials lives on the typed-field
        // `scan(_:)` path and in `safeToolError`.
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

    /// True when the string contains a leaked bearer credential: a `corbis_mcp_` token or
    /// an echoed `Bearer ` authorization header. The matched secret is never returned, only
    /// a boolean, so callers cannot accidentally re-surface it. This is the single source of
    /// truth for credential leak detection across the redactor and `CorbisMCPError`.
    public static func containsSensitiveCredential(_ string: String) -> Bool {
        let lower = string.lowercased()
        return lower.contains("corbis_mcp_") || lower.contains("bearer ")
    }

    public static func containsEmailAddress(_ string: String) -> Bool {
        let localPart = #"[a-z0-9.!#$%&'*+/=?^_`{|}~-]+"#
        let domainPart = #"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+"#
        return string.range(
            of: localPart + "@" + domainPart,
            options: [.regularExpression, .caseInsensitive]) != nil
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

    private static func scanRawText(_ data: Data) -> [Violation] {
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

    private struct AcademicProfileScanEnvelope: Encodable {
        let academicProfile: AcademicProfile
    }

    private static func scanAcademicProfile(_ profile: AcademicProfile) -> [Violation] {
        guard let data = try? JSONEncoder().encode(AcademicProfileScanEnvelope(academicProfile: profile)) else {
            return [Violation(field: "academicProfile", kind: .privateIdentityEvidence)]
        }
        return self.scanRawJSON(data)
    }

    private static func scanRawJSONObject(
        _ value: Any,
        path: [String],
        isAcademicProfile: Bool,
        violations: inout [Violation])
    {
        switch value {
        case let dictionary as [String: Any]:
            if isAcademicProfile,
               path.contains("identity"),
               dictionary.keys.contains("id"),
               dictionary.keys.contains("source"),
               dictionary["visibility"] as? String != "public"
            {
                violations.append(Violation(
                    field: (path + ["visibility"]).joined(separator: "."),
                    kind: .privateIdentityEvidence))
            }
            for (key, child) in dictionary {
                let childPath = path + [key]
                let childIsAcademicProfile = isAcademicProfile || key == "academicProfile"
                if childIsAcademicProfile, self.isForbiddenAcademicProfileKey(key) {
                    violations.append(Violation(
                        field: childPath.joined(separator: "."),
                        kind: .privateIdentityEvidence))
                }
                self.scanRawJSONObject(
                    child,
                    path: childPath,
                    isAcademicProfile: childIsAcademicProfile,
                    violations: &violations)
            }
        case let array as [Any]:
            for (index, child) in array.enumerated() {
                self.scanRawJSONObject(
                    child,
                    path: path + ["[\(index)]"],
                    isAcademicProfile: isAcademicProfile,
                    violations: &violations)
            }
        case let text as String:
            let field = path.joined(separator: ".")
            if self.containsInternalAuthorID(text) {
                violations.append(Violation(field: field, kind: .internalAuthorID))
            }
            if !isAcademicProfile {
                for name in self.backendSourceNames(in: text) {
                    violations.append(Violation(field: field, kind: .backendSourceName(name)))
                }
            } else {
                if self.containsEmailAddress(text) {
                    violations.append(Violation(field: field, kind: .privateIdentityEvidence))
                }
                if self.containsSensitiveCredential(text) {
                    violations.append(Violation(field: field, kind: .sensitiveCredential))
                }
            }
        default:
            return
        }
    }

    private static func isForbiddenAcademicProfileKey(_ key: String) -> Bool {
        let normalized = key.unicodeScalars
            .filter { CharacterSet.alphanumerics.contains($0) }
            .map(String.init)
            .joined()
            .lowercased()

        if normalized.contains("email") || normalized.contains("private") || normalized.contains("credential") {
            return true
        }
        if normalized.contains("apikey") || normalized.contains("secretkey") || normalized.hasSuffix("token") {
            return true
        }
        if ["authorid", "openalexauthorid", "openalexid", "internaluserid", "userid", "databaseid"]
            .contains(normalized)
        {
            return true
        }
        return normalized.hasPrefix("internal") && normalized.hasSuffix("id")
    }
}
