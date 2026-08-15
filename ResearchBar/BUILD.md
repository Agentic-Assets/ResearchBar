# Build guide (start here for engineers)

Date: 2026-06-18. This is the single entry point for implementing ResearchBar or tracking the Corbis dependency.

> **Wire-contract reference:** [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md)
> is a maintained local copy, not a symlink or backend authority. It was refreshed against sibling repository
> `agentic-assets-app` `origin/main` commit `c7c87a1527bbc45cc1c201d27fb39f24f99f4075`. Before changing the MCP
> client, re-verify the named backend symbols at current `origin/main`; update the guide's pinned revision when facts
> differ. The `build/` guides preserve Swift-side implementation history and do not override current code or backend
> contract.

## Verdict

**Current client state (2026-08-14):** the thin macOS client, fixture-backed pulse model, account-scoped cache, MCP seam, settings, and ResearchBar card are implemented. Continue to use fixture-backed verification by default. Live MCP/account validation is opt-in and requires explicit authorization; the client must not invent entitlement, allowance, reset, rate, or usage history from a remaining credit balance. See [`OPEN-ISSUES.md`](OPEN-ISSUES.md) for deferred backend/product decisions and the wire-contract reference for integration boundaries.

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

0. **[`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md): maintained local wire
   reference (transport, auth, billing, schemas, identity handshake, redaction, Phase 0B checklist). Read it first, but
   resolve conflicts in favor of current `agentic-assets-app` source.**
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

Historical snapshot verified against Corbis code and a live MCP smoke (2026-06-26). It is not an operational inventory or pricing source. Current backend source is authoritative; clients must inspect `tools/list` and consume only contract fields returned for the authenticated principal.

| Topic | Value |
|---|---|
| MCP tools registered | Historical 2026-06-26 observation only; inspect authenticated `tools/list` at integration time. |
| Credit / allowance | Server-owned and changeable. Render an authoritative remaining finite balance or unlimited state only; never calculate calls, allowance, reset, rate, or usage client-side. |
| ORCID-first confirm | **Shipped** (migration `0162`; `confirm_academic_identity` accepts ORCID / Google Scholar / opaque candidate token) |
| Premium MCP tools | enterprise-only in practice; `get_research_pulse` + `get_data_freshness` are both **tier1** (free-reachable) |
| Rate limit enforced | **200/hour** only (`10 concurrent` is docs-only) |
| Pulse trends in v0 | **null** with `citationHistoryStatus: "not_yet_tracked"`; the weekly snapshot store (Phase 1) is shipped. A valid roughly-seven-day comparator produces `"tracked"`, a real 7-day delta, and a non-empty sparkline. The 52-week delta stays null until a roughly-year-old comparator exists. Middle state is `"tracking"` (code), not `accruing`. |

## Citation convention

`path:line` references in `build/` point into **`../../agentic-assets-app`**, not this repo. Open the Corbis repo for `lib/mcp/...` and `lib/research-profile/...` paths.
