# 04. Corrections and sync-back (audit record)

Date: 2026-06-17 (audit). **Applied to `../concept/` on 2026-06-18** during folder reorganization. Living blockers: [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md).

The concept docs carried facts that the Corbis code contradicted as of 2026-06-17. This file records what was wrong and what was fixed. All `path:line` references in the "code says" column point into **`../../../agentic-assets-app`**.

## The corrections

| Concept claim | Where it appeared | Code says | Evidence (Corbis repo) | Applied |
|---|---|---|---|---|
| 24 registered MCP tools | `corbis-api-contracts.md` | 30 | `lib/mcp/tools/registry.ts:1241-1282`, `mcp-consolidation.test.ts:87` | Yes |
| 1 credit per call | `funnel-economics.md` | 0.5 | `lib/mcp/tool-credits.ts:16` | Yes |
| ORCID-first "migration in progress" | `identity-and-data-consolidation.md` | Unstarted | no `orcid` in `schema.ts`; confirm keys on internal id | Yes |
| 5 tools enterprise-only | concept report | 10 | `lib/ai/capabilities/index.ts:950-966` | Yes |
| 10 concurrent enforced | `open-questions-checklist.md` | Docs only | `resources/docs.ts:89,430`; 200/hour at `rate-limit.ts:67` | Yes |
| Trend fields always in pulse | `corbis-api-contracts.md` | Null until snapshots | no citation time-series; see `03` Phase 1 | Yes |

## Why the credit correction matters

At 0.5 credits per call, 50 lifetime free credits = **100 aggregate calls**. Corrected free-tier runway under daily polling is roughly **28–40 days** (regime A–B), not two weeks. Client polling cadence is the main product lever ([`00`](00-what-this-means-for-researchbar.md)).

## Corbis evaluation (authoritative backend source)

Full adversarial verdict and evidence: [`../../../agentic-assets-app/docs/researchbar-evaluation/07-adversarial-review-verdict.md`](../../../agentic-assets-app/docs/researchbar-evaluation/07-adversarial-review-verdict.md).

If new facts diverge from concept docs again, update `../concept/` and add a row here.
