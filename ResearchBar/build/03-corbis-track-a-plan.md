# 03. Corbis Track A plan (the dependency you track)

This is the Corbis backend plan that unblocks ResearchBar, condensed so a client builder can track readiness. The full, file-level plan and the implementation-ready pulse spec live in the Corbis repo: [`../../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md`](../../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md) and [`08-get-research-pulse-v0-spec.md`](../../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md). All `path:line` references point into the Corbis repo. The client is unblocked when Phase 0 passes its done-when gate.

## Phase 0: prove the contract (blocks the client)

Goal: a Corbis account can call `get_research_pulse` over MCP and get an ORCID-anchored, leak-free static pulse, with trend fields returned as explicit nulls. No macOS client required to verify this. This is the only phase that blocks Track B.

Work items:

- **0.A ORCID anchor path.** Add an `orcid` column to `User` (or a dedicated identity table) in `lib/db/schema.ts` near the identity columns at `:67-70`; migrate (`pnpm db:generate`, `pnpm db:migrate`). Persist ORCID on link (`lib/research-profile/author-linking-service.ts`, the manual accept paths at `confirm-academic-identity.ts:81-87` and `app/api/user/author-link/route.ts:145-151`). Add an ORCID-to-internal resolver and an ORCID accept path on `confirm_academic_identity` (`:25-42`).
- **0.B Redaction pass (the never-surface fix).** Strip internal ids and backend names from client-facing output at the shared path: `output-schemas.ts:22,43,59,113,139,169`; backend-domain URLs in `business-logic.ts:197-200,307-318,463-477`; the literal label in `result-format.ts:97`; tool descriptions `registry.ts:539,547`; identity messages `confirm-academic-identity.ts:103` and `find-academic-identity.ts:107,134,208-209`; vendor names in `resources/docs.ts:57,60,327`.
- **0.C `fetchAuthorCandidate` extraction.** Extract the body of `app/api/user/author-link/candidate/route.ts:146-233` into a shared `fetchAuthorCandidate(authorId)` in `lib/research-profile/` so the rich web-only enrichment (h-index, websites, topics, employment) becomes MCP-callable. The existing route then calls it (no behavior change). About 50 lines moved.
- **0.D `get_research_pulse` v0.** Add `GetResearchPulseOutput` to `output-schemas.ts`; register via `bridgeCustom` in `registry.ts` (precedent `query_corbis_retrieve` at `:861-1014`), in `MCP_TOOLS` (`:1241`) and named exports (`:1295`); add the capability entry in `lib/ai/capabilities/index.ts` (`scope: 'read:profile'`, `tier: 'tier1'`); add the barrel re-export in `lib/mcp/tools/index.ts`. Do NOT add it to `CACHEABLE_TOOL_NAMES` (`cache.ts:4-8`); the cache key is user-blind. Implementation reuses `fetchAuthorCandidate`, `getUsageSummary` (`lib/stripe/usage.ts:350`) for credits, and `resolveEffectiveTierForMcp` (`lib/mcp/tier-resolver.ts:30`) for plan; returns trend fields null with `citationHistoryStatus: 'not_yet_tracked'`.
- **0.E Tests.** Bump `EXPECTED_TOOL_COUNT` 30 to 31 and add the tool name (`tests/unit/lib/mcp/mcp-consolidation.test.ts:87,89,1420`; `tests/routes/mcp-tools-comprehensive.test.ts:21`). Add a `MCP_TOOLS` to capability parity test (today only a startup warn, `route.ts:386-397`). Add a redaction regression test asserting no client-facing field matches `/^A\d+$/` or the backend name. Add an ORCID-first confirm test.

### Reuse answers (confirmed against code)

- **`get_paper_details_batch` reusable inside the pulse?** Yes, via the shared function `fetchPaperDetailsBatch(paperIds, { session })` (`lib/mcp/business-logic.ts:381`), not the MCP bridge. Cap is 25, re-enforced at `:388-391`; chunk for authors with more than 25 papers. Strip `openalexId` (`registry.ts:1179`) from each result.
- **Web candidate API reusable inside the pulse?** Yes for the logic, no as a direct HTTP call. The route is cookie-gated (`candidate/route.ts:119`); an MCP request carries a bearer, no cookie, so an internal HTTP call would 401. The fix is the 0.C extraction.

### Phase 0 done when (this is the client's green light)

- `pnpm type-check`, `pnpm lint`, the MCP Vitest suites, and `pnpm verify:ai-sdk` pass.
- `get_research_pulse` appears in `tools/list` for an authenticated free-tier token.
- A live `tools/call` returns an ORCID-anchored payload with no internal id and no backend name anywhere, and trend fields null with `citationHistoryStatus: 'not_yet_tracked'`.
- A grep of a captured response for the internal-id pattern and the backend name returns nothing.

The client smoke tests in `02-mcp-contract-get-research-pulse.md` are exactly the commands that confirm this gate from outside Corbis.

## Phase 1: citation trends and data freshness

- **Snapshot store and weekly cron.** New table `author_citation_snapshot` (`authorKey` server-side, `userId`, `snapshotDate`, `totalCitations`, `worksCount`, `hIndex`, unique `(authorKey, snapshotDate)`). New `CRON_SECRET`-protected route `app/api/cron/author-citation-snapshot/route.ts`, weekly entry in `vercel.json`, `preferredRegion = 'iad1'`. Backfill the first snapshot on link.
- **Wire deltas and sparkline** into `get_research_pulse`: compute `citationDelta7d`, `citationDelta52w`, `sparkline52w` from the snapshots; set `citationHistoryStatus` to `accruing` (one snapshot) or `tracked` (two or more). Never fabricate a delta.
- **`get_data_freshness`** ("data through" only): compose CRE freshness from `data_freshness`/`metric_dates` (`market-data.ts:582,685`) and FRED dates from `fred_series_batch`. Global, cacheable.

Done when: after two weekly cron runs, the pulse returns non-null deltas and a sparkline with `citationHistoryStatus: 'tracked'`, and the cron is idempotent on the unique constraint. This is when the client can ship real trends and delta notifications.

## Phase 2: radar and linked repos

- **`get_new_work_radar`**: add a forward-citation retrieval call (not wired today; `searchPapers` is corpus search, `authorNetwork` is collaboration), plus a per-user watermark store for "new since last run." `subfieldAlerts` from topics or `researchInterests` (`schema.ts:58`); `relatedToProjects` from `projectPaper` (`schema.ts:258`). Session-aware and fail-closed under org-forced ZDR for any external leg (`internet-search/server.ts:22-29`). Per-user, not cacheable.
- **`get_linked_repos`**: paper-to-repo association storage plus optional remote GitHub metadata when an account is linked. The local git ahead/behind/dirty merge stays in this repo.

Done when: the radar returns only items newer than the watermark on a second call, and an org-forced-ZDR account fails closed on the external leg.

## Phase 3: deadlines and optional catalog promotion

- **`get_conference_deadlines`**: confirm a maintained seed dataset (founder decision, `05-risks-and-open-questions.md`), then build curated seed plus per-user overrides. Global seed cacheable; merged per-user view not.
- **Optional `get_agent_catalog`**: promote to Corbis only if corbis.ai web needs the same catalog in-browser. ResearchBar v1 reads the local plugin install, so no Corbis work is required for v1.

## Verification discipline (Corbis side)

Per the Corbis root `CLAUDE.md`: after each phase, run `pnpm type-check`, `pnpm lint`, `pnpm verify:ai-sdk`, and the relevant Vitest suites before commit; sync the affected Corbis `CLAUDE.md` files (`lib/mcp/CLAUDE.md`, `lib/ai/tools/CLAUDE.md`, `lib/ai/tools/REGISTRY.md`, `app/api/CLAUDE.md` for the new cron). Feature branches only; no pushes to `main`.
