import Foundation
import Testing
@testable import CodexBarCore

// MARK: - Fixture loading

/// Shared loader for ResearchBar pulse fixtures under `Fixtures/ResearchBar`.
/// Reused by the decoding, redaction, menu-model, cache, and client test suites.
enum ResearchBarFixtures {
    /// Legacy, current dual-emission, and labeled future-compatibility fixtures.
    static let allPulseNames: [String] = [
        "pulse-linked-not-tracked",
        "pulse-linked-tracking",
        "pulse-linked-tracked",
        "pulse-tracked-no-52w-comparator",
        "pulse-profile-only",
        "pulse-industry-profile",
        "pulse-unlinked",
        "pulse-low-confidence",
        "pulse-academic-profile-v1",
        "pulse-credit-limited",
        "pulse-contract-limited",
        "pulse-contract-unlimited",
        "pulse-contract-malformed-new-fields",
        "pulse-contract-null-indexed-works",
        "pulse-contract-no-balances",
        "pulse-future-post-window-unlimited",
        "pulse-leak-like",
    ]

    static func data(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures/ResearchBar"),
            "missing fixture \(name).json")
        return try Data(contentsOf: url)
    }

    static func pulse(_ name: String) throws -> ResearchPulse {
        try ResearchPulse.decode(self.data(name))
    }
}
