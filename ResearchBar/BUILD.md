# Build guide (start here for engineers)

Date: 2026-06-18. This is the single entry point for implementing ResearchBar or tracking the Corbis dependency.

> **Wire contract lives in [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md)** (symlink to the verified Corbis guide). Read it before writing the MCP client: it carries the exact transport/auth/billing contract, the live `get_research_pulse` / `get_data_freshness` schemas, the identity handshake, and the redaction rules. The `build/` guides below are the Swift-side build plan; the guide is the authority on the wire facts.

## Verdict

**BUILD WITH CHANGES.** Corbis APIs first, thin macOS client second. **Update 2026-06-27: Corbis Phase 0 payload/redaction smoke is shipped, the Track B client is fixture-tested and live-MCP-capable behind safe seams, and the app identity is now ResearchBar (`com.corbis.researchbar`).** The remaining live cutover risk is billing/credit policy validation, not basic client shape. See [`OPEN-ISSUES.md`](OPEN-ISSUES.md) for remaining founder/product items and [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md) for the contract.

## Fork strategy

ResearchBar should reuse CodexBar aggressively while making Corbis research
intelligence the default product surface. Keep the existing AI provider usage
machinery during Track B because it preserves upstream mergeability, provides
working patterns for auth, providers, HTTP, settings, menus, and tests, and may
become a small optional ResearchBar feature later. Do not make generic AI usage
the main menu experience.

Builder rule: hide, demote, or feature-flag inherited provider usage when it
competes with the research pulse. Remove it only after the Corbis pulse path,
product naming, and upstream sync strategy are proven.

## Read order

### Track B: ResearchBar macOS client (this repo)

0. **[`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md): the authoritative wire contract (transport, auth, billing, live schemas, identity handshake, redaction, Phase 0B checklist). Read first; it supersedes any wire fact in `build/` on conflict.**
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

Keep fixtures as the stable regression source. Use live MCP only through the client seams and credit-safe refresh path.

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

Verified against Corbis code and the live MCP smoke (2026-06-26). Authoritative source: [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md).

| Topic | Value |
|---|---|
| MCP tools registered | **41** authed; anonymous/invalid token sees **31** tier1 (`tools/list`, 2026-06-26) |
| Credit per `tools/call` | **0.5** (not 1; a diagnostics panel still displays `1`, which is stale) |
| Free tier | **~50 credits** (~**100** aggregate calls). DB-driven default, not a frozen fact; read `creditsRemaining` from the pulse. |
| ORCID-first confirm | **Shipped** (migration `0162`; `confirm_academic_identity` accepts ORCID / Google Scholar / opaque candidate token) |
| Premium MCP tools | enterprise-only in practice; `get_research_pulse` + `get_data_freshness` are both **tier1** (free-reachable) |
| Rate limit enforced | **200/hour** only (`10 concurrent` is docs-only) |
| Pulse trends in v0 | **null** with `citationHistoryStatus: "not_yet_tracked"`; the weekly snapshot store (Phase 1) is shipped and populates real deltas + a 52-week sparkline once history accrues. Middle state is `"tracking"` (code), not `accruing`. |

## Citation convention

`path:line` references in `build/` point into **`../../agentic-assets-app`**, not this repo. Open the Corbis repo for `lib/mcp/...` and `lib/research-profile/...` paths.
