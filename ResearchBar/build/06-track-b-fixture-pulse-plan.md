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
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-linked-not-tracked.json` | `profileStatus: linked_researcher`, static metrics, null trend fields, `citationHistoryStatus: not_yet_tracked`. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-linked-tracking.json` | Linked account, one snapshot, null trend fields, `citationHistoryStatus: tracking`. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-linked-tracked.json` | Linked account with real trend fields, `citationHistoryStatus: tracked`. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-profile-only.json` | `profileStatus: profile_only`, identity present, metrics unavailable. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-industry-profile.json` | `profileStatus: industry_profile`, non-publishing user, null publication metrics. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-unlinked.json` | `profileStatus: unlinked`, no ORCID, identity low confidence. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-low-confidence.json` | Metrics present with `lowConfidence.citations: true` and a `reason`. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-credit-limited.json` | Valid identity with low or exhausted credits. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-leak-like.json` | Deliberate internal id or backend source string for negative tests. |
| `Tests/CodexBarTests/ResearchPulseDecodingTests.swift` | Fixture decode coverage. |
| `Tests/CodexBarTests/ResearchPulseMenuModelTests.swift` | State and display behavior coverage. |
| `Tests/CodexBarTests/ResearchPulseRedactorTests.swift` | Defensive leak checks. |

Keep all files under `ResearchBar/` namespaces or folders even though the
package name remains `CodexBar`. Do not rename the package in this slice.

## Model contract

`ResearchPulse` mirrors the live schema in
[`../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md)
§4 (authoritative, code-verified) and [`02`](02-mcp-contract-get-research-pulse.md).
Decode every field the guide lists; the enums use the shipped wire values
(`tracking`, not `accruing`; `lowConfidence` is `{ identity, citations, reason }`).
Required shape:

```swift
struct ResearchPulse: Codable, Equatable, Sendable {
    let profileStatus: ProfileStatus      // primary render selector: linked_researcher | profile_only | industry_profile | unlinked
    let displayName: String?
    let affiliation: String?
    let role: String?
    let sector: String?
    let companyName: String?
    let plan: String
    let creditsRemaining: Double
    let orcid: String?
    let googleScholarId: String?
    let googleScholarUrl: URL?
    let totalCitations: Int?
    let hIndex: Int?
    let trackedPaperCount: Int?
    let citationDelta7d: Int?
    let citationDelta52w: Int?
    let sparkline52w: [Int]?
    let citationHistoryStatus: CitationHistoryStatus   // not_yet_tracked | tracking | tracked
    let lowConfidence: LowConfidence                   // { identity, citations, reason }
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
| `profileStatus == .linkedResearcher` | Full pulse: identity plus citation metrics plus trend (per `citationHistoryStatus`). |
| `profileStatus == .profileOnly` | Identity plus whatever metrics are non-null; show the low-confidence hint. |
| `profileStatus == .industryProfile` | Professional pulse with null publication metrics. Never render empty citation widgets as zeros. |
| `profileStatus == .unlinked` | Render identity confirmation ("link your identity") state. No internal ids. Not an error. |
| `citationHistoryStatus == .tracked` and all trend fields are present | Trend rows may render. |
| `citationHistoryStatus == .tracked` and any trend field is missing | Treat as invalid pulse and render a safe error state. |
| `citationHistoryStatus == .notYetTracked` | Render "citation tracking will begin" style state. No sparkline. No zero delta. |
| `citationHistoryStatus == .tracking` | Render "history is accruing" style state. No sparkline. No zero delta. |
| `lowConfidence.identity || lowConfidence.citations` | Render a concise confidence notice without backend source names. |

## Menu model states

`ResearchPulseMenuModel` should produce explicit states:

| State | Inputs |
|---|---|
| `notConnected` | No credential exists. |
| `invalidCredential` | Credential test failed. |
| `identityUnlinked` | `profileStatus == .unlinked` (no public anchor). |
| `industryProfile` | `profileStatus == .industryProfile`; professional pulse, null publication metrics. |
| `loadedNotTracked` | Pulse linked, trends null, status `not_yet_tracked`. |
| `loadedTracking` | Pulse linked, trends null, status `tracking`. |
| `loadedTracked` | Pulse linked, trends present, status `tracked`. |
| `loadedLowConfidence` | Pulse linked with confidence notice (`lowConfidence.identity` or `.citations`). |
| `staleCache` | Pulse came from cache and `staleAfter` is in the past. |
| `creditLimited` | Pulse or client error says credits are exhausted or insufficient. |
| `safeError` | Decode, redaction, or semantic validation failed. |

These are display states only. No network request starts from the menu model.

## Test checklist

1. Decode every fixture (all four `profileStatus` states included).
2. Assert `not_tracked` and `tracking` fixtures do not render numeric deltas.
3. Assert tracked fixture renders trend fields only when all trend values exist.
4. Assert unlinked fixture renders identity confirmation, not a fake profile.
5. Assert industry-profile fixture renders a professional pulse with null metrics, not zeroed citation widgets.
6. Assert low-confidence fixture renders a warning and still hides backend names.
7. Assert leak-like fixture fails redaction.
8. Assert no rendered row contains `openalex`, `semantic scholar`, `ssrn`, `sourceId`, `authorId`, or a string matching `^A[0-9]+$`.

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

- Fixture files exist for every v0 state listed above (all four `profileStatus` values and the three `citationHistoryStatus` values).
- `ResearchPulse` decodes the live Corbis pulse contract (guide §4), including `profileStatus` and `lowConfidence { identity, citations, reason }`.
- Menu-model tests prove null trends never become zero trends, and `industry_profile` metrics never render as zeros.
- Redaction tests fail on leak-like payloads.
- No live Corbis call is wired into the app.
