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
    public let creditBalance: CreditBalance?
    public let creditsRemaining: Double?
    public let orcid: String?
    public let googleScholarId: String?
    public let googleScholarUrl: URL?
    public let totalCitations: Int?
    public let hIndex: Int?
    public let indexedWorksCount: Int?
    private let hasAuthoritativeIndexedWorksCount: Bool
    public let trackedPaperCount: Int?

    /// Null until a valid roughly-seven-day comparator exists.
    public let citationDelta7d: Int?
    /// Independently null until a valid roughly-52-week comparator exists.
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
        creditsRemaining: Double?,
        creditBalance: CreditBalance? = nil,
        orcid: String?,
        googleScholarId: String?,
        googleScholarUrl: URL?,
        totalCitations: Int?,
        hIndex: Int?,
        trackedPaperCount: Int?,
        indexedWorksCount: Int? = nil,
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
        self.creditBalance = creditBalance
        self.creditsRemaining = creditsRemaining
        self.orcid = orcid
        self.googleScholarId = googleScholarId
        self.googleScholarUrl = googleScholarUrl
        self.totalCitations = totalCitations
        self.hIndex = hIndex
        self.indexedWorksCount = indexedWorksCount
        self.hasAuthoritativeIndexedWorksCount = indexedWorksCount != nil
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

    public var resolvedCreditBalance: CreditBalance? {
        self.creditBalance ?? self.creditsRemaining.map { .limited(remaining: $0) }
    }

    public var resolvedIndexedWorksCount: Int? {
        self.hasAuthoritativeIndexedWorksCount ? self.indexedWorksCount : self.trackedPaperCount
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

public enum CreditBalance: Codable, Equatable, Sendable {
    case limited(remaining: Double)
    case unlimited

    private enum CodingKeys: String, CodingKey {
        case kind
        case remaining
    }

    private enum Kind: String, Codable {
        case limited
        case unlimited
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .limited:
            let remaining = try container.decode(Double.self, forKey: .remaining)
            guard remaining >= 0 else {
                throw DecodingError.dataCorruptedError(
                    forKey: .remaining,
                    in: container,
                    debugDescription: "Limited credit balance cannot be negative")
            }
            self = .limited(remaining: remaining)
        case .unlimited:
            self = .unlimited
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .limited(remaining):
            try container.encode(Kind.limited, forKey: .kind)
            try container.encode(remaining, forKey: .remaining)
        case .unlimited:
            try container.encode(Kind.unlimited, forKey: .kind)
        }
    }
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
    private enum CodingKeys: String, CodingKey {
        case profileStatus
        case displayName
        case affiliation
        case role
        case sector
        case companyName
        case plan
        case creditBalance
        case creditsRemaining
        case orcid
        case googleScholarId
        case googleScholarUrl
        case totalCitations
        case hIndex
        case indexedWorksCount
        case trackedPaperCount
        case citationDelta7d
        case citationDelta52w
        case sparkline52w
        case citationHistoryStatus
        case lowConfidence
        case profileLinks
        case fetchedAt
        case staleAfter
        case etag
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.profileStatus = try container.decode(ProfileStatus.self, forKey: .profileStatus)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
        self.affiliation = try container.decodeIfPresent(String.self, forKey: .affiliation)
        self.role = try container.decodeIfPresent(String.self, forKey: .role)
        self.sector = try container.decodeIfPresent(String.self, forKey: .sector)
        self.companyName = try container.decodeIfPresent(String.self, forKey: .companyName)
        self.plan = try container.decode(String.self, forKey: .plan)
        self.creditBalance = container.decodeTolerantly(CreditBalance.self, forKey: .creditBalance)
        self.creditsRemaining = container.decodeTolerantly(Double.self, forKey: .creditsRemaining)
        self.orcid = try container.decodeIfPresent(String.self, forKey: .orcid)
        self.googleScholarId = try container.decodeIfPresent(String.self, forKey: .googleScholarId)
        self.googleScholarUrl = try container.decodeIfPresent(URL.self, forKey: .googleScholarUrl)
        self.totalCitations = try container.decodeIfPresent(Int.self, forKey: .totalCitations)
        self.hIndex = try container.decodeIfPresent(Int.self, forKey: .hIndex)
        if container.contains(.indexedWorksCount), try container.decodeNil(forKey: .indexedWorksCount) {
            self.indexedWorksCount = nil
            self.hasAuthoritativeIndexedWorksCount = true
        } else if let indexedWorksCount = container.decodeTolerantly(Int.self, forKey: .indexedWorksCount),
                  indexedWorksCount >= 0
        {
            self.indexedWorksCount = indexedWorksCount
            self.hasAuthoritativeIndexedWorksCount = true
        } else {
            self.indexedWorksCount = nil
            self.hasAuthoritativeIndexedWorksCount = false
        }
        self.trackedPaperCount = container.decodeTolerantly(Int.self, forKey: .trackedPaperCount)
            .flatMap { $0 >= 0 ? $0 : nil }
        self.citationDelta7d = try container.decodeIfPresent(Int.self, forKey: .citationDelta7d)
        self.citationDelta52w = try container.decodeIfPresent(Int.self, forKey: .citationDelta52w)
        self.sparkline52w = try container.decodeIfPresent([Int].self, forKey: .sparkline52w)
        self.citationHistoryStatus = try container.decode(
            CitationHistoryStatus.self,
            forKey: .citationHistoryStatus)
        self.lowConfidence = try container.decode(LowConfidence.self, forKey: .lowConfidence)
        self.profileLinks = try container.decode([ProfileLink].self, forKey: .profileLinks)
        self.fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)
        self.staleAfter = try container.decode(Date.self, forKey: .staleAfter)
        self.etag = try container.decode(String.self, forKey: .etag)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.profileStatus, forKey: .profileStatus)
        try container.encodeIfPresent(self.displayName, forKey: .displayName)
        try container.encodeIfPresent(self.affiliation, forKey: .affiliation)
        try container.encodeIfPresent(self.role, forKey: .role)
        try container.encodeIfPresent(self.sector, forKey: .sector)
        try container.encodeIfPresent(self.companyName, forKey: .companyName)
        try container.encode(self.plan, forKey: .plan)
        try container.encodeIfPresent(self.creditBalance, forKey: .creditBalance)
        try container.encodeIfPresent(self.creditsRemaining, forKey: .creditsRemaining)
        try container.encodeIfPresent(self.orcid, forKey: .orcid)
        try container.encodeIfPresent(self.googleScholarId, forKey: .googleScholarId)
        try container.encodeIfPresent(self.googleScholarUrl, forKey: .googleScholarUrl)
        try container.encodeIfPresent(self.totalCitations, forKey: .totalCitations)
        try container.encodeIfPresent(self.hIndex, forKey: .hIndex)
        if self.hasAuthoritativeIndexedWorksCount {
            try container.encodeIfPresent(self.indexedWorksCount, forKey: .indexedWorksCount)
            if self.indexedWorksCount == nil {
                try container.encodeNil(forKey: .indexedWorksCount)
            }
        }
        try container.encodeIfPresent(self.trackedPaperCount, forKey: .trackedPaperCount)
        try container.encodeIfPresent(self.citationDelta7d, forKey: .citationDelta7d)
        try container.encodeIfPresent(self.citationDelta52w, forKey: .citationDelta52w)
        try container.encodeIfPresent(self.sparkline52w, forKey: .sparkline52w)
        try container.encode(self.citationHistoryStatus, forKey: .citationHistoryStatus)
        try container.encode(self.lowConfidence, forKey: .lowConfidence)
        try container.encode(self.profileLinks, forKey: .profileLinks)
        try container.encode(self.fetchedAt, forKey: .fetchedAt)
        try container.encode(self.staleAfter, forKey: .staleAfter)
        try container.encode(self.etag, forKey: .etag)
    }

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
        /// `citationHistoryStatus == .tracked` but the 7-day delta or sparkline is missing/empty.
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

    /// True only when a real trend may be drawn: status is `tracked`, the 7-day
    /// delta exists, and the sparkline is non-empty. The 52-week delta is optional.
    public var hasRenderableTrend: Bool {
        self.citationHistoryStatus == .tracked && self.hasCompleteTrendFields
    }

    private var hasCompleteTrendFields: Bool {
        guard self.citationDelta7d != nil else { return false }
        guard let sparkline = self.sparkline52w, !sparkline.isEmpty else { return false }
        return true
    }

    /// Publication metrics are entirely absent (industry / unlinked / profile-only).
    public var hasNoPublicationMetrics: Bool {
        self.totalCitations == nil && self.hIndex == nil && self.resolvedIndexedWorksCount == nil
    }

    public var showsLowConfidenceNotice: Bool {
        self.lowConfidence.identity || self.lowConfidence.citations
    }
}

extension KeyedDecodingContainer {
    fileprivate func decodeTolerantly<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
        try? self.decode(type, forKey: key)
    }
}
