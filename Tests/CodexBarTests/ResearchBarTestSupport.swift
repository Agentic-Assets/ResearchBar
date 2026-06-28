import Foundation
import Testing
@testable import CodexBarCore

// MARK: - Fixture loading

/// Shared loader for ResearchBar pulse fixtures under `Fixtures/ResearchBar`.
/// Reused by the decoding, redaction, menu-model, cache, and client test suites.
enum ResearchBarFixtures {
    /// Every v0 pulse fixture name shipped under `Fixtures/ResearchBar`.
    static let allPulseNames: [String] = [
        "pulse-linked-not-tracked",
        "pulse-linked-tracking",
        "pulse-linked-tracked",
        "pulse-profile-only",
        "pulse-industry-profile",
        "pulse-unlinked",
        "pulse-low-confidence",
        "pulse-credit-limited",
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
