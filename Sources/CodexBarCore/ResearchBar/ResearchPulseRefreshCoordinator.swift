import Foundation

/// Credit-safe orchestration between the credential store, the pulse cache, and the live
/// Corbis MCP client (guide §11). The coordinator owns the spend policy:
///
/// - App launch / no explicit trigger spends no credits (`currentMenuInput`).
/// - Menu-open refreshes only when the cache is stale or missing; a fresh entry is served
///   without a network call.
/// - Concurrent refreshes for one account coalesce to a single in-flight request, so the
///   transport is hit exactly once.
/// - A `creditLimited` result never triggers an auto-refresh loop.
///
/// Every public method returns a `ResearchPulseMenuInput`; errors are mapped to leak-safe
/// menu states rather than propagated.
public actor ResearchPulseRefreshCoordinator {
    private let credentialStore: any CorbisCredentialStoring
    private let cache: any ResearchPulseCaching
    private let client: CorbisMCPClient

    /// In-flight network fetches keyed by account cache component, for coalescing.
    private var inFlight: [String: Task<FetchOutcome, Never>] = [:]

    public init(
        credentialStore: any CorbisCredentialStoring,
        cache: any ResearchPulseCaching,
        client: CorbisMCPClient)
    {
        self.credentialStore = credentialStore
        self.cache = cache
        self.client = client
    }

    private enum FetchOutcome {
        case success(ResearchPulse)
        case failure(CorbisMCPError)
    }

    // MARK: - No-network state

    /// The menu input derivable from the credential and cache alone. Never spends a credit.
    public func currentMenuInput() async -> ResearchPulseMenuInput {
        guard let session = await self.resolveSession() else {
            return .notConnected
        }
        guard let entry = await self.cache.entry(for: session.key) else {
            // Connected, but nothing cached and no network allowed here.
            return .safeError
        }
        return .loaded(pulse: entry.pulse, fromStaleCache: !entry.isFresh(now: Date()))
    }

    // MARK: - Menu-open refresh

    /// Refresh on menu open. A fresh cache entry is served without any network call; a
    /// stale or missing entry triggers one coalesced refresh. If that refresh fails and a
    /// stale entry exists, the stale pulse is surfaced as `loaded(fromStaleCache: true)`.
    public func refreshOnMenuOpen() async -> ResearchPulseMenuInput {
        guard let session = await self.resolveSession() else {
            return .notConnected
        }

        let cachedEntry = await self.cache.entry(for: session.key)
        if let entry = cachedEntry, entry.isFresh(now: Date()) {
            return .loaded(pulse: entry.pulse, fromStaleCache: false)
        }

        let outcome = await self.coalescedFetch(session: session)
        switch outcome {
        case let .success(pulse):
            return .loaded(pulse: pulse, fromStaleCache: false)
        case let .failure(error):
            return Self.menuOpenFailureInput(error: error, staleEntry: cachedEntry)
        }
    }

    // MARK: - Manual refresh

    /// Force a refresh when connected. Concurrent calls coalesce to one in-flight request.
    public func manualRefresh() async -> ResearchPulseMenuInput {
        guard let session = await self.resolveSession() else {
            return .notConnected
        }

        let cachedEntry = await self.cache.entry(for: session.key)
        let outcome = await self.coalescedFetch(session: session)
        switch outcome {
        case let .success(pulse):
            return .loaded(pulse: pulse, fromStaleCache: false)
        case let .failure(error):
            return Self.manualFailureInput(error: error, cachedPulse: cachedEntry?.pulse)
        }
    }

    // MARK: - Session resolution

    private struct Session {
        let credential: CorbisCredential
        let identity: CorbisAccountIdentity
        let key: ResearchPulseCacheKey
    }

    private func resolveSession() async -> Session? {
        let credential: CorbisCredential?
        do {
            credential = try await self.credentialStore.loadCredential()
        } catch {
            return nil
        }
        guard let credential else { return nil }
        let identity = credential.accountIdentity()
        return Session(
            credential: credential,
            identity: identity,
            key: ResearchPulseCacheKey(identity: identity))
    }

    // MARK: - Coalesced fetch

    private func coalescedFetch(session: Session) async -> FetchOutcome {
        let account = session.identity.cacheKeyComponent
        if let existing = self.inFlight[account] {
            return await existing.value
        }

        // No `await` between the lookup above and this insert, so exactly one task is
        // created per account; concurrent callers observe it and await the same value.
        let task = Task<FetchOutcome, Never> { [client, cache] in
            do {
                let result = try await client.fetchResearchPulseResult(token: session.credential.token)
                let entry = ResearchPulseCacheEntry(
                    pulse: result.pulse,
                    rawJSON: result.rawJSON,
                    identity: session.identity)
                try? await cache.store(entry, for: session.key)
                return .success(result.pulse)
            } catch let error as CorbisMCPError {
                return .failure(error)
            } catch {
                return .failure(.server)
            }
        }
        self.inFlight[account] = task
        let outcome = await task.value
        self.inFlight[account] = nil
        return outcome
    }

    // MARK: - Failure mapping

    private static func menuOpenFailureInput(
        error: CorbisMCPError,
        staleEntry: ResearchPulseCacheEntry?) -> ResearchPulseMenuInput
    {
        switch error {
        case .creditLimited:
            return .creditLimited(pulse: staleEntry?.pulse)
        case .invalidCredential:
            return .invalidCredential
        default:
            // Serve a stale cache rather than an error when one is available.
            if let staleEntry {
                return .loaded(pulse: staleEntry.pulse, fromStaleCache: true)
            }
            return .safeError
        }
    }

    private static func manualFailureInput(
        error: CorbisMCPError,
        cachedPulse: ResearchPulse?) -> ResearchPulseMenuInput
    {
        switch error {
        case .creditLimited:
            .creditLimited(pulse: cachedPulse)
        case .invalidCredential:
            .invalidCredential
        default:
            .safeError
        }
    }
}

// MARK: - Pulse re-encoding

extension ResearchPulse {
    /// Encode the pulse back to JSON for cache persistence. Dates are written with
    /// fractional-second ISO-8601 via `ResearchBarISO8601.string(from:)`, matching the
    /// `FileResearchPulseCache` encoder and the live wire format, so `fetchedAt`/
    /// `staleAfter` round-trip exactly when the pulse is reconstructed from `rawJSON`.
    /// A bare `.iso8601` strategy would round timestamps to the nearest second and break
    /// pulse equality across a cache round-trip.
    func makeRawJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ResearchBarISO8601.string(from: date))
        }
        return try encoder.encode(self)
    }
}
