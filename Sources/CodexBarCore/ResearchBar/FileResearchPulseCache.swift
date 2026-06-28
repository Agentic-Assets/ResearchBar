import Crypto
import Foundation

/// Disk-backed pulse cache: one JSON file per `key.storageKey` under a configurable
/// directory (default Application Support/ResearchBar/pulse-cache). Only the raw JSON
/// and freshness metadata are persisted; the decoded pulse is reconstructed on read via
/// `ResearchPulse.decode`. Dates are written with fractional-second ISO-8601 so
/// etag/fetchedAt/staleAfter round-trip exactly across instances.
public actor FileResearchPulseCache: ResearchPulseCaching {
    private let directory: URL

    public init(directory: URL? = nil) {
        if let directory {
            self.directory = directory
        } else {
            let base = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.directory = base.appendingPathComponent("ResearchBar/pulse-cache", isDirectory: true)
        }
    }

    /// On-disk record. Stores the raw payload rather than the decoded pulse.
    private struct StoredDTO: Codable {
        let rawJSON: Data
        let etag: String
        let fetchedAt: Date
        let staleAfter: Date
        let schemaVersion: String
        let accountID: String?
    }

    public func entry(for key: ResearchPulseCacheKey) async -> ResearchPulseCacheEntry? {
        let url = self.fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let dto = try? Self.makeDecoder().decode(StoredDTO.self, from: data) else { return nil }
        guard let pulse = try? ResearchPulse.decode(dto.rawJSON) else { return nil }
        if let storedID = dto.accountID, storedID != key.account {
            return nil
        }
        return ResearchPulseCacheEntry(
            rawJSON: dto.rawJSON,
            pulse: pulse,
            etag: dto.etag,
            fetchedAt: dto.fetchedAt,
            staleAfter: dto.staleAfter,
            schemaVersion: dto.schemaVersion,
            accountID: dto.accountID)
    }

    public func store(_ entry: ResearchPulseCacheEntry, for key: ResearchPulseCacheKey) async throws {
        try FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        let dto = StoredDTO(
            rawJSON: entry.rawJSON,
            etag: entry.etag,
            fetchedAt: entry.fetchedAt,
            staleAfter: entry.staleAfter,
            schemaVersion: entry.schemaVersion,
            accountID: entry.accountID)
        let data = try Self.makeEncoder().encode(dto)
        try data.write(to: self.fileURL(for: key), options: .atomic)
    }

    public func invalidate(for key: ResearchPulseCacheKey) async {
        try? FileManager.default.removeItem(at: self.fileURL(for: key))
    }

    public func clearAll() async {
        try? FileManager.default.removeItem(at: self.directory)
    }

    private func fileURL(for key: ResearchPulseCacheKey) -> URL {
        // Hash the storage key so two distinct account ids can never collide on disk.
        // Character sanitization could map different accounts to the same filename and
        // serve one account's pulse under another, violating the account-keying rule.
        let digest = SHA256.hash(data: Data(key.storageKey.utf8))
        let name = digest.map { String(format: "%02x", Int($0)) }.joined()
        return self.directory.appendingPathComponent(name).appendingPathExtension("json")
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ResearchBarISO8601.string(from: date))
        }
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
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
}

extension ResearchBarISO8601 {
    /// Render a date with fractional-second ISO-8601, matching the lenient parser used
    /// for `ResearchPulse` timestamps so file-cache dates round-trip exactly.
    static func string(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
