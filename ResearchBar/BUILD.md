# Build guide (start here for engineers)

Date: 2026-06-18. This is the single entry point for implementing ResearchBar or tracking the Corbis dependency.

## Verdict

**BUILD WITH CHANGES.** Corbis APIs first, thin macOS client second. The client is blocked until Corbis Phase 0 ships `get_research_pulse` v0 (plus ORCID anchor and backend redaction). See [`OPEN-ISSUES.md`](OPEN-ISSUES.md) for the live blocker list.

## Read order

### Track B: ResearchBar macOS client (this repo)

1. [`build/00-what-this-means-for-researchbar.md`](build/00-what-this-means-for-researchbar.md): gate, client rules (polling, null trends, cache keyed by account, redaction).
2. [`build/01-corbis-vs-researchbar-boundary.md`](build/01-corbis-vs-researchbar-boundary.md): ownership table and MUST/MUST NOT allowlist.
3. [`build/02-mcp-contract-get-research-pulse.md`](build/02-mcp-contract-get-research-pulse.md): JSON contract, Swift Codable sketch, curl smoke tests.
4. [`build/03-corbis-track-a-plan.md`](build/03-corbis-track-a-plan.md): when the client is unblocked (condensed Corbis phases).
5. [`build/05-risks-and-open-questions.md`](build/05-risks-and-open-questions.md): client-relevant risks.
6. [`RESEARCHBAR-BUILD-REVIEW-2026-06-18.md`](RESEARCHBAR-BUILD-REVIEW-2026-06-18.md): deep review and v0 menu state inventory.
7. [`build/06-track-b-fixture-pulse-plan.md`](build/06-track-b-fixture-pulse-plan.md): fixtures, `ResearchPulse`, decode tests, redaction, and menu model.
8. [`build/07-track-b-auth-and-cache-plan.md`](build/07-track-b-auth-and-cache-plan.md): Corbis token storage, account identity, cache, freshness, and GRDB decision.
9. [`build/08-track-b-live-mcp-plan.md`](build/08-track-b-live-mcp-plan.md): JSON-RPC client, smoke tests, error mapping, and credit-safe refresh.
10. [`build/09-track-b-menu-rendering-plan.md`](build/09-track-b-menu-rendering-plan.md): menu states, settings, status icon, and descriptor tests.
11. [`build/10-track-b-distribution-plan.md`](build/10-track-b-distribution-plan.md): naming, bundle ids, Sparkle, Homebrew, notarization, and Tahoe checks.

Build against fixtures until Phase 0 passes its done-when gate in `build/03`.

### Track A: Corbis backend (sibling repo)

Implement in [`../../agentic-assets-app`](../../agentic-assets-app). Full plan:

1. [`../../agentic-assets-app/docs/researchbar-evaluation/README.md`](../../agentic-assets-app/docs/researchbar-evaluation/README.md)
2. [`08-get-research-pulse-v0-spec.md`](../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md): implement against this.
3. [`05-revised-implementation-plan.md`](../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md): phases, files, smoke tests.
4. [`04-revised-corbis-api-contracts.md`](../../agentic-assets-app/docs/researchbar-evaluation/04-revised-corbis-api-contracts.md): later aggregate shapes.
5. [`09-deep-dive-review-and-next-actions.md`](../../agentic-assets-app/docs/researchbar-evaluation/09-deep-dive-review-and-next-actions.md): deep review and cross-repo sequence.

### Product context (optional)

- [`researchbar-in-60-seconds.md`](researchbar-in-60-seconds.md)
- [`concept/2026-06-17-researchbar-concept-and-recommendation.md`](concept/2026-06-17-researchbar-concept-and-recommendation.md)

## Corrected facts (do not plan against stale numbers)

| Topic | Value |
|---|---|
| MCP tools registered | **30** (not 24) |
| Credit per `tools/call` | **0.5** (not 1) |
| Free tier | **50 credits lifetime** (~**100** aggregate calls) |
| ORCID-first confirm | **Unstarted** (net-new backend work) |
| Premium MCP tools | **10** (enterprise-only in practice) |
| Rate limit enforced | **200/hour** only (`10 concurrent` is docs-only) |
| Pulse trends in v0 | **null** until weekly snapshot store accrues |

## Citation convention

`path:line` references in `build/` point into **`../../agentic-assets-app`**, not this repo. Open the Corbis repo for `lib/mcp/...` and `lib/research-profile/...` paths.
