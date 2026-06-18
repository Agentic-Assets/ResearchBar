# 00. What this means for ResearchBar

The client-first read. All `path:line` references point into the sibling Corbis repo `agentic-assets-app`, per the README convention.

## The one gate

ResearchBar cannot ship a working menu panel until Corbis ships `get_research_pulse` v0. That single MCP tool, plus the two backend prerequisites behind it (an ORCID anchor path and a leak-redaction pass), is the entire critical path. Everything else in the client (shell, auth, cache, notifications, agent launch) can be built in parallel against a stubbed response, but the panel does not light up with real data until Corbis Track A Phase 0 is done. The done-when gate and smoke tests for that phase are in `03-corbis-track-a-plan.md`.

Build order, restated: Corbis APIs first, thin client second. This was already the concept's instinct (`researchbar-in-60-seconds.md`); the code confirms it is not optional, because the client has nothing correct to render until the aggregate and its redaction land.

## CodexBar inheritance strategy

Treat CodexBar as the chassis, not as dead code to strip out. The existing AI
provider usage system is useful in three ways:

- It keeps the fork easier to sync with upstream CodexBar while ResearchBar is
  still proving the Corbis pulse path.
- It gives working local patterns for provider registration, settings, auth,
  HTTP calls, status item rendering, tests, packaging, and releases.
- It may become a small optional ResearchBar surface later, such as an
  advanced "AI tools" panel, diagnostics view, or developer-only status block.

The default ResearchBar experience should still be research-first: Corbis
identity, research pulse, credits, cache freshness, profile links, and later
agent launch. If inherited AI usage competes with that menu, hide it, demote
it, or put it behind a feature flag. Do not delete broad provider code until
the Corbis pulse slice works, product naming is approved, and the upstream
merge strategy is clear.

## What ResearchBar builds (and never computes)

ResearchBar is a renderer and a launcher. It consumes aggregate JSON and opens links. It does not consolidate, reconcile, scrape, compute citation deltas, or orchestrate multi-tool fan-out. The full allowlist is in `01-corbis-vs-researchbar-boundary.md`. The short version:

- Menu bar shell (CodexBar fork), settings, Sparkle, Homebrew.
- Corbis auth: an OAuth bearer or a personal MCP API key (`corbis_mcp_...`) held in the Keychain.
- A thin ORCID confirm UI over the existing identity tools.
- A generic panel renderer for aggregate JSON.
- A polling timer plus a GRDB response cache that respects server `staleAfter` and `etag`.
- Local notifications on server-flagged deltas.
- Local git clone scanner (ahead/behind/dirty) merged onto Corbis repo records.
- Agent launch (Claude Code subprocess) and a v1 agent catalog read from the local plugin install.

## Five corrected realities that change client design

These follow directly from the code findings and should shape the client before the first Swift file.

### 1. Polling cadence is a product lever, because credits are scarce and one-time

Each MCP `tools/call` costs **0.5 credits** (`lib/mcp/tool-credits.ts:16`), not 1. The free tier is **50 credits and never resets** (`lib/stripe/usage.ts:117-138`; `creditsResetDate` stays null). So a free user has exactly **100 aggregate calls for the lifetime of the account** before hitting the wall. An always-on background poller that refreshes hourly burns that in about four days, most of it on days the user never opened the menu. That is activation churn of the worst kind: the wall arrives from passive polling, not from felt value.

Client rules that follow:
- Poll on menu-open, or on a slow cadence (for example a few times per day), not aggressively in the background.
- At most **one aggregate call per refresh**. The whole point of the aggregate design is one panel, one call.
- Respect `staleAfter` and `etag` from the response so a fresh-enough cache entry serves without a new call.
- Surface `creditsRemaining` (the pulse returns it) so the user can see the budget the client is spending.

### 2. Trend fields are null in v0; the UI must say "tracking will begin," never show a fake zero

`get_research_pulse` v0 returns `citationDelta7d`, `citationDelta52w`, and `sparkline52w` as **null**, with a `citationHistoryStatus` flag (`not_yet_tracked`, `accruing`, or `tracked`). Corbis cannot return real deltas until a per-user citation-snapshot store accrues at least two weekly rows (Phase 1; see `03`). This is deliberate: Corbis returns honest nulls rather than fabricated deltas (VISION priority 1, evidence before fluency).

Client rules that follow:
- The menu-bar icon sparkline and the delta line must render a "tracking will begin shortly" state when `citationHistoryStatus` is `not_yet_tracked` or `accruing`. Do not draw an empty sparkline or a "0 this week" that reads as a real zero.
- Model the trend fields as optionals in Swift, gated on the status enum, not as non-optional numbers. See the Codable sketch in `02`.
- Notifications on citation deltas are a Phase 1 client feature, because there are no deltas to notify on in v0.

### 3. Redact defensively, even though Corbis should redact at the source

The never-surface rule is currently violated in Corbis output (`output-schemas.ts:22`, `result-format.ts:97`, `confirm-academic-identity.ts:103`). Corbis Phase 0 fixes this at the source. The client should still treat any value matching the internal author id pattern (`/^A\d+$/`) or a backend source name as a bug, not display it. Belt and suspenders: a client that anchors on ORCID should never render an internal id even if one leaks through a not-yet-redacted field.

Client rules that follow:
- The ORCID confirm flow displays and keys on ORCID only.
- Add a client smoke test (or a render-time assertion in debug builds) that fails if a rendered string matches `^A\d+$` or a known backend source name.

### 4. Key the local cache by Corbis account

Corbis learned this the hard way on the server: its MCP cache key is user-blind (`lib/mcp/cache.ts:36-41`), so per-user aggregates are deliberately kept out of the server cache to avoid serving one account's citations to another. The same hazard exists locally. If a Mac has more than one Corbis account (or the user switches accounts), the GRDB cache must be keyed by account identity, never global, or one account's pulse and credit balance will render under another.

### 5. Auth and transport: direct native bearer calls, honor 200/hour, ignore "10 concurrent"

- The Corbis MCP endpoint is Streamable HTTP with bearer auth at `POST /api/mcp/universal`. A native Swift `URLSession` client can call it directly; it is not a browser, so CORS does not gate it, and no proxy is needed (`lib/mcp/CLAUDE.md`).
- The enforced rate limit is **200 requests per hour** (`lib/rate-limit.ts:67`, `lib/mcp/auth.ts:502`). The "10 concurrent" figure in older docs is documentation-only and not enforced (`resources/docs.ts:89,430`); do not build client concurrency logic that depends on it.
- Hold the OAuth bearer or `corbis_mcp_...` key in the Keychain. Never log it.

## Client build order, aligned to Corbis phases

| Corbis phase (the dependency) | ResearchBar can then ship |
|---|---|
| **Phase 0**: `get_research_pulse` v0 + ORCID anchor + redaction | Render one menu panel from the pulse: ORCID, name, affiliation, total citations, h-index, credits, profile links. Trend block shows "tracking will begin." This is the v1 client. |
| **Phase 1**: snapshot store + weekly cron, `get_data_freshness` | Real sparkline and 7d/52w deltas; notifications on deltas; a data-freshness panel. |
| **Phase 2**: `get_new_work_radar`, `get_linked_repos` | A "who cites you / new in your field" panel; local git ahead/behind merged onto Corbis repo records. |
| **Phase 3**: `get_conference_deadlines`, optional `get_agent_catalog` | A deadlines panel; agent launch and catalog (catalog is local-read in v1 regardless). |

Until Phase 0 is done, the honest client state is: shell, auth, ORCID confirm, and a panel that renders the documented shape from a stub. Do not ship a panel that fabricates data to fill the gap.
