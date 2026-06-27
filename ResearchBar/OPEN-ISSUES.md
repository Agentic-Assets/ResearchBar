# Open issues and decisions

Last updated: 2026-06-27. Living tracker for ResearchBar. Corbis evidence-backed closures live in [`../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md`](../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md).

**Build entry:** [`BUILD.md`](BUILD.md). **Wire contract:** [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md). **Client plan:** [`build/`](build/). **Deep client review:** [`RESEARCHBAR-BUILD-REVIEW-2026-06-18.md`](RESEARCHBAR-BUILD-REVIEW-2026-06-18.md). **Corbis plan:** [`../../agentic-assets-app/docs/researchbar-evaluation/`](../../agentic-assets-app/docs/researchbar-evaluation/).

---

## Critical path (blocks a working menu panel)

**RESOLVED 2026-06-27.** Corbis **Phase 0** (and Phase 1 trend snapshots + `get_data_freshness`) is shipped and the live MCP smoke passes over real HTTP, so Track B is unblocked and can build the real pulse panel. Evidence: Corbis `_recon/2026-06-26-live-smoke.md`; contract: [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md).

| # | Work item | Owner | Status |
|---|---|---|---|
| 1 | **0.A ORCID anchor**: `orcid` column, resolver, ORCID-first confirm | Corbis | **Done** (migration `0162`; ORCID + Google Scholar anchors) |
| 2 | **0.B Redaction pass**: strip internal ids and backend names from MCP output | Corbis | **Done** for the pulse surface (no-chunk-leak + pulse redaction tests). Broader low-level paper/citation redaction is the remaining `A4b` follow-up; v0 does not call those tools. |
| 3 | **0.C `fetchAuthorCandidate` extraction**: share web candidate logic for MCP | Corbis | **Done** (`lib/research-profile/author-candidate-service.ts`) |
| 4 | **0.D `get_research_pulse` v0**: static pulse, null trends, `citationHistoryStatus` | Corbis | **Done** (registered, tier1, `read:profile`) |
| 5 | **0.E Tests + smoke tests**: tool-count tripwire, redaction regression, ORCID confirm | Corbis | **Done** (offline + live; `tools/list` authed = 41, anon = 31) |

**Phase 0 done when (MET 2026-06-26):** `get_research_pulse` appears in `tools/list`; live `tools/call` returns a public-anchor-aware payload with no leaks; trend fields null with `not_yet_tracked`. Verified over real HTTP plus the Playwright route contract (9/9). Curl commands in [`build/02`](build/02-mcp-contract-get-research-pulse.md), the contract guide, and Corbis [`05`](../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md). Remaining live gap: the per-call 0.5-credit delta needs a finite-credit free-tier token to observe (reservation/refund is unit-covered).

---

## Engineering risks (active)

| Risk | Mitigation | Doc |
|---|---|---|
| Passive polling burns 50 lifetime credits (~100 calls at 0.5/call) | Poll on menu-open or slow cadence; respect `staleAfter`/`etag`; show `creditsRemaining` | [`build/00`](build/00-what-this-means-for-researchbar.md) |
| Null trends rendered as fake zeros | Gate UI on `citationHistoryStatus`; never draw empty sparkline as "0" | [`build/02`](build/02-mcp-contract-get-research-pulse.md) |
| Internal id / backend name leak | Corbis 0.B + client defensive redact + debug assertion | [`build/01`](build/01-corbis-vs-researchbar-boundary.md) |
| GRDB cache cross-account contamination | Key cache by Corbis account id | [`build/00`](build/00-what-this-means-for-researchbar.md) |
| Per-user pulse added to server cache allowlist | Never add per-user tools to `CACHEABLE_TOOL_NAMES` | Corbis [`03-design-review`](../../agentic-assets-app/docs/researchbar-evaluation/03-design-review.md) §3 |
| ZDR violation on future radar aggregate | Session-aware, fail-closed on web legs from day one | Corbis [`06`](../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md) |
| Tier1 aggregate calling premium primitives | Founder decision: subsidy or forbidden | Corbis [`03`](../../agentic-assets-app/docs/researchbar-evaluation/03-design-review.md) §2 |
| SSRN scraping in production vs "no scraping" posture | Resolve before SSRN numbers in commercial funnel | Corbis [`07`](../../agentic-assets-app/docs/researchbar-evaluation/07-adversarial-review-verdict.md) |

---

## Founder-only decisions (unresolved)

| Decision | Why open | Pointer |
|---|---|---|
| ResearchBar-specific free allowance (>50 lifetime credits) | No install-attribution column; global raise affects all web users | Corbis [`06` §C](../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md) |
| Polling cadence + whether Corbis subsidizes pulse server-side | Product/margin; drives activation churn | [`concept/funnel-economics.md`](concept/funnel-economics.md) |
| `trackedPaperCount` definition | Saved papers vs authored `works_count` | Corbis [`06` §B](../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md) |
| Citation reconciliation rule | Only matters when multiple sources contribute | Corbis [`06` §B](../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md) |
| Conference-deadline seed dataset | Content-ops commitment | [`concept/open-questions-checklist.md`](concept/open-questions-checklist.md) |
| ToS: Semantic Scholar, Scholar/SerpAPI, ResearchGate, ORCID Member API | Legal/vendor | [`concept/open-questions-checklist.md`](concept/open-questions-checklist.md) |
| `get_linked_repos` standalone vs nested | Product shape | [`concept/corbis-api-contracts.md`](concept/corbis-api-contracts.md) |
| Product naming (ResearchBar vs Corbis-branded) | Funnel vs OSS goodwill | [`concept/2026-06-17-researchbar-concept-and-recommendation.md`](concept/2026-06-17-researchbar-concept-and-recommendation.md) §10 |
| Inherited CodexBar AI usage surface | Keep as hidden machinery, optional advanced panel, or remove after pulse proves out | [`build/00`](build/00-what-this-means-for-researchbar.md) |
| Domain `research.bar` | Register before public launch | [`concept/open-questions-checklist.md`](concept/open-questions-checklist.md) |
| Corbis corpus figure | Quote live corbis.ai only | Company hard rule |

---

## Track B: client (Phase 0 green light given 2026-06-27, build now)

| Item | Status |
|---|---|
| Fixture pulse model, fixtures, redaction, menu model | **Next up (start here)**; not started; see [`build/06`](build/06-track-b-fixture-pulse-plan.md) |
| Corbis auth in Keychain and account-keyed cache | Not started; see [`build/07`](build/07-track-b-auth-and-cache-plan.md) |
| Thin ORCID confirm UI (ORCID display only) | **Unblocked** (Corbis 0.A shipped, migration `0162`); not started; see [`build/09`](build/09-track-b-menu-rendering-plan.md) |
| Render `get_research_pulse` in one menu panel | **Unblocked** (Corbis 0.D shipped); start on fixtures via [`build/06`](build/06-track-b-fixture-pulse-plan.md), then live |
| Live JSON-RPC call to Corbis MCP | **Unblocked** (Phase 0 live smoke passed 2026-06-26); not started; see [`build/08`](build/08-track-b-live-mcp-plan.md) |
| GRDB cache keyed by account; respect `staleAfter`/`etag` | Decision needed; see [`build/07`](build/07-track-b-auth-and-cache-plan.md) |
| Notarized DMG + Sparkle + Homebrew | Deferred until pulse path works; see [`build/10`](build/10-track-b-distribution-plan.md) |
| Hide or demote inherited AI provider usage in the menu | Not started; keep code during Track B unless it blocks the research-first surface |
| Test `NSStatusItem` on macOS 26 (Tahoe) | Not started |
| Local git scanner + agent launch (later phases) | Not started |

Full historical checklist: [`concept/open-questions-checklist.md`](concept/open-questions-checklist.md). Current Track B build guides: [`build/06`](build/06-track-b-fixture-pulse-plan.md) through [`build/10`](build/10-track-b-distribution-plan.md).

---

## Closed by code audit (2026-06-17)

Do not re-open without new evidence.

| Item | Answer |
|---|---|
| MCP tool count | **30** (`registry.ts:1241-1282`) |
| Credit per call | **0.5** (`tool-credits.ts:16`) |
| `get_paper_details_batch` max | **25**; reuse via `fetchPaperDetailsBatch` |
| Rate limit enforced | **200/hour**; 10 concurrent is docs-only |
| Native Swift direct MCP | Yes; CORS does not apply |
| Identity tools tier | **tier1** (free gate works) |
| Premium tool count | **10** (enterprise-only in practice) |
| Pulse JSON schema (v0) | [`build/02`](build/02-mcp-contract-get-research-pulse.md) + Corbis [`08`](../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md) |

---

## Documentation hygiene

| Item | Status |
|---|---|
| Folder reorg (`build/`, `concept/`, `research/`) | Done 2026-06-18 |
| Factual corrections in concept docs | Done 2026-06-18 (see [`build/04`](build/04-corrections-and-sync-back.md)) |
| Corbis eval cross-links in README and build docs | Done 2026-06-18 |

---

## Phase roadmap (authoritative sequencing)

Supersedes phase ordering in the concept report. Corbis implements; client renders when each phase lands.

| Phase | Corbis | Client can ship |
|---|---|---|
| **0** | Pulse v0 + ORCID + redaction | One static pulse panel |
| **1** | Citation snapshots + `get_data_freshness` | Trends, notifications, freshness panel |
| **2** | `get_new_work_radar` + `get_linked_repos` | Radar + local git merge |
| **3** | `get_conference_deadlines` | Deadlines panel |

Details: [`build/03`](build/03-corbis-track-a-plan.md), Corbis [`05`](../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md).
