# 02. MCP contract: `get_research_pulse`

The exact JSON the client renders, framed for the Swift client. This is the build-against contract. It supersedes the illustrative table in [`../concept/corbis-api-contracts.md`](../concept/corbis-api-contracts.md) where they disagree (mainly: trend fields are nullable with a status flag, `lowConfidence` is a structured object, and no internal id or backend name appears anywhere). The full Corbis-side spec is [`../../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md`](../../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md). All `path:line` references point into the Corbis repo.

## Call facts

| Property | Value |
|---|---|
| Transport | Streamable HTTP, `POST /api/mcp/universal`, JSON-RPC 2.0 |
| Auth | `Authorization: Bearer <token>` (OAuth bearer or `corbis_mcp_...` key) |
| Method / params | `tools/call`, `{ "name": "get_research_pulse", "arguments": {} }` |
| Arguments | none in v0; the caller is the bearer principal, the linked author is read from the account |
| Credit cost | 0.5 per call (`lib/mcp/tool-credits.ts:16`) |
| Tier | tier1 (free-tier reachable; the gate is a Corbis account, not a paid plan) |
| Cacheable server-side | No (per-user); the client caches locally per account |
| Idempotent | Yes (read-only) |

## Response shape (v0)

> **Authoritative live schema:** [`../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md) §4 (verified against `lib/mcp/tools/output-schemas.ts:324-355`). The JSON below is illustrative; where it disagrees with the guide, the guide wins. Three live facts the early drafts missed: the primary field is `profileStatus` (four states), the middle history state is `tracking` (not `accruing`), and `lowConfidence` is `{ identity, citations, reason }` (not `{ identity, metrics, reasons }`).

Trend fields are present but null until history accrues. `profileStatus` selects the render mode; `citationHistoryStatus` selects the trend state.

```json
{
  "profileStatus": "linked_researcher",
  "displayName": "Cayman Seagraves",
  "affiliation": "University of Tulsa",
  "role": null,
  "sector": null,
  "companyName": null,
  "plan": "academic",
  "creditsRemaining": 84.0,
  "orcid": "0000-0002-1825-0097",
  "googleScholarId": null,
  "googleScholarUrl": null,
  "totalCitations": 1284,
  "hIndex": 11,
  "trackedPaperCount": 18,
  "citationDelta7d": null,
  "citationDelta52w": null,
  "sparkline52w": null,
  "citationHistoryStatus": "not_yet_tracked",
  "lowConfidence": { "identity": false, "citations": false, "reason": null },
  "profileLinks": [
    { "label": "ORCID", "url": "https://orcid.org/0000-0002-1825-0097" },
    { "label": "Personal site", "url": "https://example.edu/~cseagraves" }
  ],
  "fetchedAt": "2026-06-17T16:00:00Z",
  "staleAfter": "2026-06-17T22:00:00Z",
  "etag": "sha256:9f2c..."
}
```

Once Phase 1's snapshot store has two or more weekly rows, the same call returns populated trends and `citationHistoryStatus: "tracked"`:

```json
{
  "citationDelta7d": 7,
  "citationDelta52w": 168,
  "sparkline52w": [1102, 1110, 1121, "...48 more weekly totals...", 1284],
  "citationHistoryStatus": "tracked"
}
```

## Field rules the client must honor

- `citationHistoryStatus` is `not_yet_tracked` (no snapshots), `tracking` (one snapshot, deltas still null; show "history is accruing" copy), or `tracked` (two or more). The three trend fields are non-null only when `tracked`. Corbis never fabricates a delta; the client must never invent one either.
- `profileStatus` is the primary render selector: `linked_researcher`, `profile_only`, `industry_profile`, or `unlinked`. All four are first-class (guide §4). For an `unlinked` account, `orcid` is null, `lowConfidence.identity` is true, and the metric and trend fields are null; the client renders a "confirm your ORCID" state, never an internal id. For `industry_profile`, render a professional pulse with null publication metrics, not zeroed citation widgets.
- `creditsRemaining` is live per-user state; show it so the user sees the budget the client spends.
- `profileLinks` carries ORCID and personal-site URLs only. There must be no backend-source domain. The client opens these; it never constructs URLs.
- No field, URL, or string may contain the internal author id pattern (`^A\d+$`) or a backend source name. Corbis enforces this with a redaction pass and a regression test (Corbis Phase 0.B); the client redacts defensively.

## Swift Codable sketch

Illustrative, to make the nullable contract concrete for the renderer. Nullable JSON fields are Swift optionals; the status drives whether the trend view renders.

```swift
struct ResearchPulse: Codable {
    let profileStatus: ProfileStatus
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

    // null in v0; populated only when citationHistoryStatus == .tracked
    let citationDelta7d: Int?
    let citationDelta52w: Int?
    let sparkline52w: [Int]?
    let citationHistoryStatus: CitationHistoryStatus

    let lowConfidence: LowConfidence
    let profileLinks: [ProfileLink]

    let fetchedAt: String
    let staleAfter: String
    let etag: String
}

enum ProfileStatus: String, Codable {
    case linkedResearcher = "linked_researcher"
    case profileOnly = "profile_only"
    case industryProfile = "industry_profile"
    case unlinked
}

enum CitationHistoryStatus: String, Codable {
    case notYetTracked = "not_yet_tracked"
    case tracking
    case tracked
}

struct LowConfidence: Codable {
    let identity: Bool
    let citations: Bool
    let reason: String?
}

struct ProfileLink: Codable {
    let label: String
    let url: URL
}
```

Render logic that follows from the status:

```swift
switch pulse.citationHistoryStatus {
case .tracked:
    // draw sparkline52w and the 7d/52w deltas
case .tracking, .notYetTracked:
    // show "citation tracking will begin shortly" / "history is accruing"; do not draw an empty sparkline or a fake 0
}
```

## See the real shape before writing Swift

Run this against a dev or preview origin with a test-account token. It prints the live payload and fails loudly if a leak slips through, so the client is built against reality, not the illustrative JSON above.

```bash
BASE="http://localhost:3000"     # or a preview URL; never production for writes
curl -s -X POST "$BASE/api/mcp/universal" \
  -H "Authorization: Bearer $CORBIS_MCP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"get_research_pulse","arguments":{}}}' \
  | tee /tmp/pulse.json | jq '.result'
grep -Ei 'openalex|"A[0-9]{5,}"' /tmp/pulse.json && echo "LEAK FOUND" || echo "clean"
```

Discovery (confirm the tool is registered and visible to the token):

```bash
curl -s -X POST "$BASE/api/mcp/universal" \
  -H "Authorization: Bearer $CORBIS_MCP_TOKEN" -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  | jq '.result.tools[].name' | grep get_research_pulse
```

If `get_research_pulse` does not appear in `tools/list`, Corbis Phase 0 is not done yet and the client has nothing real to render. Track the dependency in `03-corbis-track-a-plan.md`.

## The other aggregates (shapes the client will consume later)

These ship in later Corbis phases. The client builds renderers against them when the corresponding phase lands. Concrete shapes are in [`../../../agentic-assets-app/docs/researchbar-evaluation/04-revised-corbis-api-contracts.md`](../../../agentic-assets-app/docs/researchbar-evaluation/04-revised-corbis-api-contracts.md).

- `get_data_freshness` (Phase 1, **now shipped + live**): live shape is `{ sources: [{ id, label, status, dataThrough, dataThroughGranularity, lastRefreshedAt, note }], overallStatus, fetchedAt, staleAfter, etag }` (guide §5, `lib/mcp/tools/output-schemas.ts:363`). A source with no fixed cutoff returns `status: "live"` with `dataThrough: null` rather than a fabricated date. Global and cacheable.
- `get_new_work_radar` (Phase 2): `{ citingYou: [...], subfieldAlerts: [...], relatedToProjects: [...], watermark, fetchedAt, staleAfter, etag }`. Per-user; "new since last run" is real once Corbis adds the watermark store.
- `get_conference_deadlines` (Phase 3): `{ deadlines: [...], userAdded: [...], fetchedAt, staleAfter, etag }`. `daysRemaining` is computed server-side.
