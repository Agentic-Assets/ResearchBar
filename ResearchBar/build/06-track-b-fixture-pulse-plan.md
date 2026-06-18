# 06. Track B fixture pulse plan

This guide starts the native ResearchBar client without waiting for live
Corbis data. It builds the first useful slice from fixtures: decode the
`get_research_pulse` contract, model every v0 state, and prove the menu model
does not invent research facts.

## Goal

Create a fixture-backed `ResearchPulse` domain layer that can be tested without
Corbis Phase 0. This is the first Track B implementation package in this repo.

## Gate

Live networking stays off. Builders may create fixtures, models, semantic
helpers, redaction checks, and menu models. They must not call
`/api/mcp/universal` from the app until Corbis Phase 0 passes the smoke tests
in [`02-mcp-contract-get-research-pulse.md`](02-mcp-contract-get-research-pulse.md).

## Files to add

| Path | Purpose |
|---|---|
| `Sources/CodexBarCore/ResearchBar/ResearchPulse.swift` | Codable model for the pulse payload, status enums, and semantic helpers. |
| `Sources/CodexBarCore/ResearchBar/ResearchPulseRedactor.swift` | Defensive display validation for internal ids, backend names, and source fields. |
| `Sources/CodexBar/ResearchBar/ResearchPulseMenuModel.swift` | Converts decoded pulse and local state into display rows and actions. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-linked-not-tracked.json` | Linked account, static metrics, null trend fields. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-linked-accruing.json` | Linked account, one snapshot state, null trend fields. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-linked-tracked.json` | Linked account with real trend fields. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-unlinked.json` | No ORCID confirmed, identity low confidence. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-low-confidence.json` | Metrics present with structured confidence warning. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-credit-limited.json` | Valid identity with low or exhausted credits. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-leak-like.json` | Deliberate internal id or backend source string for negative tests. |
| `Tests/CodexBarTests/ResearchPulseDecodingTests.swift` | Fixture decode coverage. |
| `Tests/CodexBarTests/ResearchPulseMenuModelTests.swift` | State and display behavior coverage. |
| `Tests/CodexBarTests/ResearchPulseRedactorTests.swift` | Defensive leak checks. |

Keep all files under `ResearchBar/` namespaces or folders even though the
package name remains `CodexBar`. Do not rename the package in this slice.

## Model contract

`ResearchPulse` mirrors [`02`](02-mcp-contract-get-research-pulse.md). Required
shape:

```swift
struct ResearchPulse: Codable, Equatable, Sendable {
    let orcid: String?
    let displayName: String?
    let affiliation: String?
    let plan: String
    let creditsRemaining: Double
    let totalCitations: Int?
    let hIndex: Int?
    let trackedPaperCount: Int?
    let citationDelta7d: Int?
    let citationDelta52w: Int?
    let sparkline52w: [Int]?
    let citationHistoryStatus: CitationHistoryStatus
    let lowConfidence: LowConfidence
    let profileLinks: [ProfileLink]
    let fetchedAt: Date
    let staleAfter: Date
    let etag: String
}
```

Use `JSONDecoder.dateDecodingStrategy = .iso8601` or an equivalent formatter
that accepts the Corbis ISO strings. If the existing test helpers already
provide a date decoder, reuse that helper.

## Semantic rules

| Case | Required behavior |
|---|---|
| `citationHistoryStatus == .tracked` and all trend fields are present | Trend rows may render. |
| `citationHistoryStatus == .tracked` and any trend field is missing | Treat as invalid pulse and render a safe error state. |
| `citationHistoryStatus == .notYetTracked` | Render "citation tracking will begin" style state. No sparkline. No zero delta. |
| `citationHistoryStatus == .accruing` | Render "citation tracking is accruing" style state. No sparkline. No zero delta. |
| `orcid == nil` | Render identity confirmation state. No internal ids. |
| `lowConfidence.identity || lowConfidence.metrics` | Render a concise confidence notice without backend source names. |

## Menu model states

`ResearchPulseMenuModel` should produce explicit states:

| State | Inputs |
|---|---|
| `notConnected` | No credential exists. |
| `invalidCredential` | Credential test failed. |
| `identityUnlinked` | Pulse has no ORCID or identity is low confidence enough to require review. |
| `loadedNotTracked` | Pulse linked, trends null, status `not_yet_tracked`. |
| `loadedAccruing` | Pulse linked, trends null, status `accruing`. |
| `loadedTracked` | Pulse linked, trends present, status `tracked`. |
| `loadedLowConfidence` | Pulse linked with confidence notice. |
| `staleCache` | Pulse came from cache and `staleAfter` is in the past. |
| `creditLimited` | Pulse or client error says credits are exhausted or insufficient. |
| `safeError` | Decode, redaction, or semantic validation failed. |

These are display states only. No network request starts from the menu model.

## Test checklist

1. Decode every fixture.
2. Assert `not_tracked` and `accruing` fixtures do not render numeric deltas.
3. Assert tracked fixture renders trend fields only when all trend values exist.
4. Assert unlinked fixture renders identity confirmation, not a fake profile.
5. Assert low-confidence fixture renders a warning and still hides backend names.
6. Assert leak-like fixture fails redaction.
7. Assert no rendered row contains `openalex`, `semantic scholar`, `ssrn`, `sourceId`, `authorId`, or a string matching `^A[0-9]+$`.

## Verification

Run focused tests while building this slice:

```bash
swift test --filter ResearchPulse
```

Before handoff:

```bash
swift build
make test
make check
```

## Done when

- Fixture files exist for every v0 state listed above.
- `ResearchPulse` decodes the documented Corbis pulse contract.
- Menu-model tests prove null trends never become zero trends.
- Redaction tests fail on leak-like payloads.
- No live Corbis call is wired into the app.
