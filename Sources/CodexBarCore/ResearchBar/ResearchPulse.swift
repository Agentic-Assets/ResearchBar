import Foundation

// MARK: - ResearchPulse

/// Decoded `get_research_pulse` payload (Corbis MCP v0).
///
/// Mirrors the authoritative, code-verified wire schema in
/// `ResearchBar/RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md` §4 (Corbis
/// `lib/mcp/tools/output-schemas.ts:324-355`). The guide wins on any conflict;
/// re-verify against it before changing a field. Nullable JSON fields are Swift
/// optionals; `citationHistoryStatus` gates whether the trend fields render.
public struct ResearchPulse: Codable, Equatable, Sendable {
    public let profileStatus: ProfileStatus
    public let displayName: String?
    public let affiliation: String?
    public let role: String?
    public let sector: String?
    public let companyName: String?
    public let plan: String
    public let creditsRemaining: Double
    public let orcid: String?
    public let googleScholarId: String?
    public let googleScholarUrl: URL?
    public let totalCitations: Int?
    public let hIndex: Int?
    public let trackedPaperCount: Int?

    /// Null until citation history accrues; non-null only when `citationHistoryStatus == .tracked`.
    public let citationDelta7d: Int?
    public let citationDelta52w: Int?
    public let sparkline52w: [Int]?
    public let citationHistoryStatus: CitationHistoryStatus

    public let lowConfidence: LowConfidence
    public let profileLinks: [ProfileLink]

    public let fetchedAt: Date
    public let staleAfter: Date
    public let etag: String

    public init(
        profileStatus: ProfileStatus,
        displayName: String?,
        affiliation: String?,
        role: String?,
        sector: String?,
        companyName: String?,
        plan: String,
        creditsRemaining: Double,
        orcid: String?,
        googleScholarId: String?,
        googleScholarUrl: URL?,
        totalCitations: Int?,
        hIndex: Int?,
        trackedPaperCount: Int?,
        citationDelta7d: Int?,
        citationDelta52w: Int?,
        sparkline52w: [Int]?,
        citationHistoryStatus: CitationHistoryStatus,
        lowConfidence: LowConfidence,
        profileLinks: [ProfileLink],
        fetchedAt: Date,
        staleAfter: Date,
        etag: String)
    {
        self.profileStatus = profileStatus
        self.displayName = displayName
        self.affiliation = affiliation
        self.role = role
        self.sector = sector
        self.companyName = companyName
        self.plan = plan
        self.creditsRemaining = creditsRemaining
        self.orcid = orcid
        self.googleScholarId = googleScholarId
        self.googleScholarUrl = googleScholarUrl
        self.totalCitations = totalCitations
        self.hIndex = hIndex
        self.trackedPaperCount = trackedPaperCount
        self.citationDelta7d = citationDelta7d
        self.citationDelta52w = citationDelta52w
        self.sparkline52w = sparkline52w
        self.citationHistoryStatus = citationHistoryStatus
        self.lowConfidence = lowConfidence
        self.profileLinks = profileLinks
        self.fetchedAt = fetchedAt
        self.staleAfter = staleAfter
        self.etag = etag
    }
}

// MARK: - Enums and nested types

public enum ProfileStatus: String, Codable, Equatable, Sendable, CaseIterable {
    case linkedResearcher = "linked_researcher"
    case profileOnly = "profile_only"
    case industryProfile = "industry_profile"
    case unlinked
}

public enum CitationHistoryStatus: String, Codable, Equatable, Sendable, CaseIterable {
    case notYetTracked = "not_yet_tracked"
    case tracking
    case tracked
}

public struct LowConfidence: Codable, Equatable, Sendable {
    public let identity: Bool
    public let citations: Bool
    public let reason: String?

    public init(identity: Bool, citations: Bool, reason: String?) {
        self.identity = identity
        self.citations = citations
        self.reason = reason
    }
}

public struct ProfileLink: Codable, Equatable, Sendable {
    public let label: String
    public let url: URL

    public init(label: String, url: URL) {
        self.label = label
        self.url = url
    }
}

// MARK: - Decoding

extension ResearchPulse {
    /// Decoder that accepts the Corbis ISO-8601 timestamps with or without
    /// fractional seconds (`...:00Z` and `...:00.512Z`). A bare `.iso8601`
    /// strategy throws on fractional seconds, which the live backend can emit.
    public static func makeJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = ResearchBarISO8601.date(from: raw) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unrecognized ISO-8601 date: \(raw)")
            }
            return date
        }
        return decoder
    }

    /// Decode a raw `structuredContent` payload into a `ResearchPulse`.
    public static func decode(_ data: Data) throws -> ResearchPulse {
        try self.makeJSONDecoder().decode(ResearchPulse.self, from: data)
    }
}

/// Lenient ISO-8601 parsing for Corbis timestamps.
enum ResearchBarISO8601 {
    static func date(from string: String) -> Date? {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFractional.date(from: string) {
            return date
        }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }
}

// MARK: - Semantic validation

extension ResearchPulse {
    /// Semantic problems that make a structurally-decoded pulse unsafe to render
    /// as-is (distinct from a redaction leak). Drives the `safeError` menu state.
    public enum SemanticIssue: Equatable, Sendable {
        /// `citationHistoryStatus == .tracked` but one or more trend fields is missing/empty.
        case trackedButIncompleteTrends
    }

    public func validate() -> [SemanticIssue] {
        var issues: [SemanticIssue] = []
        if self.citationHistoryStatus == .tracked, !self.hasCompleteTrendFields {
            issues.append(.trackedButIncompleteTrends)
        }
        return issues
    }

    public var isSemanticallyValid: Bool {
        self.validate().isEmpty
    }

    /// True only when a real trend may be drawn: status is `tracked` and every
    /// trend field is present and non-empty. Never fabricate a zero trend.
    public var hasRenderableTrend: Bool {
        self.citationHistoryStatus == .tracked && self.hasCompleteTrendFields
    }

    private var hasCompleteTrendFields: Bool {
        guard self.citationDelta7d != nil, self.citationDelta52w != nil else { return false }
        guard let sparkline = self.sparkline52w, !sparkline.isEmpty else { return false }
        return true
    }

    /// Publication metrics are entirely absent (industry / unlinked / profile-only).
    public var hasNoPublicationMetrics: Bool {
        self.totalCitations == nil && self.hIndex == nil && self.trackedPaperCount == nil
    }

    public var showsLowConfidenceNotice: Bool {
        self.lowConfidence.identity || self.lowConfidence.citations
    }
}
