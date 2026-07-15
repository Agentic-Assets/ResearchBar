import Foundation

// MARK: - academic-profile.v1

/// The public, source-aware academic-profile contract returned alongside a Corbis research
/// pulse. This mirrors the server's `academic-profile.v1` output schema. Keep this model
/// additive: older pulse payloads legitimately omit the entire profile.
public struct AcademicProfile: Codable, Equatable, Sendable {
    public static let contractVersion = "academic-profile.v1"

    public let contractVersion: String
    public let observedAt: Date
    public let identity: [AcademicIdentityEvidence]
    public let sources: [AcademicSourceState]
    public let metrics: [AcademicProfileMetric]
    public let works: [AcademicWork]
    public let workFamilies: [AcademicWorkFamily]
    public let workProposals: [AcademicWorkProposal]
    public let coverageWarnings: [String]
    public let aggregationPolicy: AcademicAggregationPolicy

    public init(
        contractVersion: String,
        observedAt: Date,
        identity: [AcademicIdentityEvidence],
        sources: [AcademicSourceState],
        metrics: [AcademicProfileMetric],
        works: [AcademicWork],
        workFamilies: [AcademicWorkFamily],
        workProposals: [AcademicWorkProposal],
        coverageWarnings: [String],
        aggregationPolicy: AcademicAggregationPolicy)
    {
        self.contractVersion = contractVersion
        self.observedAt = observedAt
        self.identity = identity
        self.sources = sources
        self.metrics = metrics
        self.works = works
        self.workFamilies = workFamilies
        self.workProposals = workProposals
        self.coverageWarnings = coverageWarnings
        self.aggregationPolicy = aggregationPolicy
    }

    public var isSupported: Bool {
        self.contractVersion == Self.contractVersion
    }
}

public enum AcademicProfileSource: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    case openAlex = "openalex"
    case orcid
    case googleScholar = "google_scholar"
    case ssrn

    public var displayLabel: String {
        switch self {
        case .openAlex: "OpenAlex"
        case .orcid: "ORCID"
        case .googleScholar: "Google Scholar"
        case .ssrn: "SSRN"
        }
    }
}

public enum AcademicIdentitySource: String, Codable, Equatable, Sendable {
    case openAlex = "openalex"
    case orcid
    case googleScholar = "google_scholar"
    case ssrn
    case corbisProfile = "corbis_profile"
}

public enum AcademicWorkSource: String, Codable, Equatable, Sendable {
    case openAlex = "openalex"
    case orcid
    case googleScholar = "google_scholar"
    case ssrn
    case crossref
}

public enum AcademicSourceStatus: String, Codable, Equatable, Sendable, CaseIterable {
    case current
    case partial
    case historicalOnly = "historical_only"
    case unavailable
    case unconfigured
    case ambiguous
    case stale
    case error

    public var displayLabel: String {
        switch self {
        case .historicalOnly: "Historical only"
        default: self.rawValue.capitalized
        }
    }
}

public enum AcademicIdentityValue: Codable, Equatable, Sendable {
    case string(String)
    case strings([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = try .strings(container.decode([String].self))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .strings(values): try container.encode(values)
        }
    }
}

public struct AcademicIdentityEvidence: Codable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let value: AcademicIdentityValue?
    public let source: AcademicIdentitySource
    public let sourceRecordId: String?
    public let status: AcademicSourceStatus
    public let observedAt: Date?
    public let attemptedAt: Date?
    public let provenance: String?
    public let visibility: AcademicEvidenceVisibility
    public let reason: String?
}

public enum AcademicEvidenceVisibility: String, Codable, Equatable, Sendable {
    case `public`
}

public struct AcademicSourceState: Codable, Equatable, Sendable {
    public let source: AcademicProfileSource
    /// Preserved for round trips; presentation must use `source.displayLabel`.
    public let label: String
    public let status: AcademicSourceStatus
    public let observedAt: Date?
    public let attemptedAt: Date?
    public let staleAfter: Date?
    public let profileUrl: URL?
    public let reason: String?
    public let warnings: [String]
    public let coverage: AcademicSourceCoverage
}

public struct AcademicSourceCoverage: Codable, Equatable, Sendable {
    public let recordCount: Double?
    public let complete: Bool?
    public let note: String
}

public struct AcademicProfileMetric: Codable, Equatable, Sendable {
    public let id: String
    /// Preserved for round trips; presentation derives labels from typed source and metric id.
    public let label: String
    public let source: AcademicProfileSource
    public let value: Double?
    public let status: AcademicSourceStatus
    public let observedAt: Date?
    public let attemptedAt: Date?
    public let staleAfter: Date?
    public let scope: String
    public let reason: String?
    public let coverage: AcademicMetricCoverage
}

public struct AcademicMetricCoverage: Codable, Equatable, Sendable {
    public let kind: AcademicMetricCoverageKind
    public let complete: Bool?
}

public enum AcademicMetricCoverageKind: String, Codable, Equatable, Sendable {
    case sourceOnly = "source_only"
}

public struct AcademicWork: Codable, Equatable, Sendable {
    public let source: AcademicWorkSource
    public let sourceRecordId: String
    public let title: String
    public let doi: String?
    public let year: Double?
    public let contributors: [String]
    public let citations: Double?
    public let downloads: Double?
    public let observedAt: Date
    public let provenance: String
    public let recordId: String
    public let normalizedTitle: String
    public let versionFamilyId: String
}

public struct AcademicWorkFamily: Codable, Equatable, Sendable {
    public let id: String
    public let status: AcademicWorkFamilyStatus
    public let matchBasis: AcademicWorkMatchBasis
    public let memberRecordIds: [String]
}

public enum AcademicWorkFamilyStatus: String, Codable, Equatable, Sendable {
    case confirmed
    case singleton
}

public enum AcademicWorkMatchBasis: String, Codable, Equatable, Sendable {
    case exactDOI = "exact_doi"
    case manifestationIdentity = "manifestation_identity"
    case manualTitlePolicy = "manual_title_policy"
    case manualVersionPolicy = "manual_version_policy"
    case manualReview = "manual_review"
    case sourceRecord = "source_record"
}

public struct AcademicWorkProposal: Codable, Equatable, Sendable {
    public let id: String
    public let matchBasis: AcademicWorkProposalMatchBasis
    public let memberRecordIds: [String]
    public let reviewRequired: Bool
}

public enum AcademicWorkProposalMatchBasis: String, Codable, Equatable, Sendable {
    case titleOnly = "title_only"
    case titleContributorYear = "title_contributor_year"
}

public struct AcademicAggregationPolicy: Codable, Equatable, Sendable {
    public let works: AcademicWorksAggregationPolicy
    public let citations: AcademicMetricAggregationPolicy
    public let downloads: AcademicMetricAggregationPolicy
}

public enum AcademicWorksAggregationPolicy: String, Codable, Equatable, Sendable {
    case reconciledVersionFamiliesOnly = "reconciled_version_families_only"
}

public enum AcademicMetricAggregationPolicy: String, Codable, Equatable, Sendable {
    case sourceSpecificNeverSum = "source_specific_never_sum"
}
