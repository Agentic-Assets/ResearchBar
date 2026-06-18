# Corbis integration plan (code-grounded)

Date: 2026-06-17. This folder is the verified, code-grounded plan for the Corbis backend that ResearchBar depends on, plus the client-side guidance that follows from it. It is the "Phase 0 Track A implementation plan" that the repo `README.md` named as the next artifact.

It was produced by inventorying the live Corbis codebase (`agentic-assets/agentic-assets-app`), stress-testing the concept against real code, and writing a revised plan. The full Corbis-internal evaluation (gap analysis, design review with rejected alternatives, per-agent recon with line-level evidence) lives in the Corbis repo at `agentic-assets-app/docs/researchbar-evaluation/`. This folder is the slice that matters for building **ResearchBar** plus the dependency contract it consumes.

## Citation convention (read this first)

Every `path:line` reference in this folder points into the sibling Corbis repo `agentic-assets/agentic-assets-app`, not this repository. A builder who greps this repo for `lib/mcp/...` will find nothing here. Open the Corbis repo for those files. Paths that start with a doc name (for example `corbis-api-contracts.md`) refer to files in this ResearchBar repo.

## One-paragraph verdict: BUILD WITH CHANGES

The concept's architecture instinct is sound and worth building: centralize consolidation in Corbis, keep the macOS client thin, anchor identity on ORCID, map one menu panel to one aggregate MCP call, and design the aggregates so corbis.ai web and EQUIRE can reuse them. But three load-bearing facts in the concept docs that live in this same repo do not survive the code, and two realities the concept treats as "the client inherits for free" are Corbis backend projects that must land before the client can ship a panel. The client is blocked on a single Corbis deliverable (`get_research_pulse` v0) and on two backend prerequisites behind it (an ORCID anchor path and a leak-redaction pass). Build Corbis Track A first, render second.

## Corrected facts (these change the concept, and the funnel math)

| Concept doc says | Code says | Where verified | Client impact |
|---|---|---|---|
| 24 registered MCP tools | **30** | `lib/mcp/tools/registry.ts:1241-1282`, pinned by `tests/unit/lib/mcp/mcp-consolidation.test.ts:87` | None directly; correct the baseline so the inventory is trusted. |
| 1 credit per call | **0.5 credit per call** | `lib/mcp/tool-credits.ts:16` | Doubles the free-tier runway. 50 lifetime free credits divided by 0.5 is **100 aggregate calls** before the wall. Polling cadence is now a product lever, see `00`. |
| ORCID-first confirm "migration in progress" | **Unstarted at the schema level** (no `orcid` column anywhere; confirm keys on the internal author id) | `lib/db/schema.ts` (no match), `lib/ai/tools/confirm-academic-identity.ts:25-42` | The anchor the client renders is net-new backend work, not in-flight. |
| 5 tools enterprise-only | **10** | `lib/ai/capabilities/index.ts:950-966` | Identity tools are tier1, so the free gate still works; the count was wrong. |
| 10 concurrent requests (guarantee) | Documentation-only, not enforced | `lib/mcp/resources/docs.ts:89,430`; only 200/hour is enforced (`lib/rate-limit.ts:67`) | Do not design client concurrency around a "10 concurrent" guarantee. |

The "never surface backend source names or internal ids" rule is **already violated in shipped Corbis MCP output** (`lib/mcp/tools/output-schemas.ts:22`, `lib/mcp/result-format.ts:97`, `lib/ai/tools/confirm-academic-identity.ts:103`). A thin client rendering today's payloads would display the internal id and the backend name. Fixing this is a Corbis Phase 0 prerequisite, not a client property, and the client should also redact defensively (see `00`).

## Reading order

1. **`00-what-this-means-for-researchbar.md`** the client-first summary: the build-order gate, what the client builds vs consumes, and the five corrected realities that change client design. Start here.
2. **`01-corbis-vs-researchbar-boundary.md`** the corrected ownership table and the client allowlist (MUST and MUST NOT).
3. **`02-mcp-contract-get-research-pulse.md`** the exact JSON the client renders, a Swift Codable sketch, auth and billing facts, and a smoke-test you can run before writing Swift.
4. **`03-corbis-track-a-plan.md`** the Corbis backend plan you are waiting on, phased, with done-when gates and MCP smoke tests. Track this to know when the client is unblocked.
5. **`04-corrections-and-sync-back.md`** the precise edits the concept docs in this repo need so the wrong facts are not re-imported.
6. **`05-risks-and-open-questions.md`** client-relevant risks and the founder-only decisions that gate the funnel.

## What this supersedes

Where this folder and the concept docs in this repo disagree, this folder wins on facts (it is code-grounded as of 2026-06-17). It supersedes the tool count and credit-cost numbers in `corbis-api-contracts.md` and `funnel-economics.md`, the "migration in progress" framing in `identity-and-data-consolidation.md`, and the implied always-present trend fields in the `get_research_pulse` table. The concept docs remain useful as the product north star and the client research dossier; treat them as concept exploration, not a build spec.

## Scope

This folder covers the Corbis dependency (Track A) in enough detail to track it, and the ResearchBar client guidance (Track B) that follows from the corrected facts. It does not duplicate the Corbis-internal effort tables and rejected-alternatives analysis; that is in `agentic-assets-app/docs/researchbar-evaluation/` (files `01` through `08` plus `_recon/`). No code was implemented in producing this package.
