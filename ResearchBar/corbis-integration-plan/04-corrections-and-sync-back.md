# 04. Corrections and sync-back

The concept docs in this repo carry facts that the Corbis code contradicts as of 2026-06-17. They were written as concept exploration, not a build spec, so the errors are understandable, but a future builder who imports them will plan against wrong numbers. This file is the in-repo correction record and the precise edit list. All `path:line` references in the "code says" column point into the sibling Corbis repo `agentic-assets-app`; the file references in the edit list are docs in **this** repo.

## The corrections

| Concept claim | Where it appears (this repo) | Code says | Evidence (Corbis repo) |
|---|---|---|---|
| 24 registered MCP tools | `corbis-api-contracts.md:128` | 30 | `lib/mcp/tools/registry.ts:1241-1282`, pinned by `tests/unit/lib/mcp/mcp-consolidation.test.ts:87` |
| 1 credit per call | `funnel-economics.md` (tables built on 1.0) | 0.5 | `lib/mcp/tool-credits.ts:16` |
| ORCID-first confirm "migration in progress" | `identity-and-data-consolidation.md:29` | Unstarted at the schema level | no `orcid` column in `lib/db/schema.ts`; `confirm-academic-identity.ts:25-42` keys on the internal id |
| 5 tools enterprise-only | concept report | 10 | `lib/ai/capabilities/index.ts:950-966` |
| 10 concurrent requests | `open-questions-checklist.md:27` | Documentation-only, not enforced | `lib/mcp/resources/docs.ts:89,430`; only 200/hour enforced (`lib/rate-limit.ts:67`) |
| Trend fields always present in `get_research_pulse` | `corbis-api-contracts.md:33-35` | Null until a snapshot store accrues two weekly rows | no per-user citation time series exists; see `03` Phase 1 |

## Why the credit correction matters most

`funnel-economics.md` builds every burn-and-conversion table on 1 credit per call. At the real 0.5, the free-tier runway roughly doubles. With 50 lifetime free credits that never reset (`lib/stripe/usage.ts:117-138`), a free account gets **100 aggregate calls** total, not 50. The corrected runway is on the order of a month under the concept's polling assumptions, not two weeks. Every table in that doc should be recomputed at 0.5, and the funnel narrative re-derived from the corrected number. The polling-cadence guidance in `00-what-this-means-for-researchbar.md` depends on this corrected figure.

## Edit list for the concept docs (recommended)

These edits keep the concept docs internally consistent with the code. Make them in this repo's concept docs; this package does not rewrite them in place, to avoid disturbing the concept narrative without sign-off.

- **`funnel-economics.md`**: change "1 credit per call" to "0.5 credit per call" everywhere and recompute every table; state the corrected free-tier runway (roughly a month under the same assumptions, on 100 lifetime aggregate calls).
- **`corbis-api-contracts.md`**: change the inventory line "Native MCP tools ... 24 tools" to 30; change "Five tools are enterprise-only" to 10. In the `get_research_pulse` table, mark `citationDelta7d`, `citationDelta52w`, and `sparkline52w` as nullable until the snapshot store exists, and add a `citationHistoryStatus` field.
- **`identity-and-data-consolidation.md`**: reframe "confirm by ORCID (target); today still accepts internal author key, migration in progress" as "ORCID-first confirm is unstarted; it is net-new backend work (add an `orcid` column, an ORCID-to-internal resolver, and an ORCID accept path)." Reframe the never-surface rule from a current posture to a backend cleanup project with named edit sites (listed in `03` Phase 0.B).
- **`open-questions-checklist.md`**: change "Confirm rate limits (200/hour, 10 concurrent)" to "200/hour enforced; 10 concurrent is documentation-only and not enforced." Mark the `get_paper_details_batch` (max 25) and "one credit per aggregate call" items closed with the evidence in `03`.
- **The concept report appendix**: note that the tool-count, credit-cost, enterprise-only-count, and concurrency facts were verified against `agentic-assets-app` on 2026-06-17 and corrected here.

## Sync-back to the GitHub repo

If these corrections should also land in the `Agentic-Assets/ResearchBar` GitHub repo, open that PR manually. This package does not open PRs via API (a standing hard rule). The exact edits above are the PR body. The full adversarial verdict that motivates them is `agentic-assets-app/docs/researchbar-evaluation/07-adversarial-review-verdict.md`.
