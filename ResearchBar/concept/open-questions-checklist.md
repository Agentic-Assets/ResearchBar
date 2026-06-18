# Phase 0 validation checklist

> **Historical checklist.** Living status is [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md). Corbis evidence closures are in [`../../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md`](../../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md).

Open questions to close before scaling beyond the pulse panel. **Track A (Corbis) blocks Track B (ResearchBar).** Each item is phrased so the answer closes it.

## Track A: Corbis `agentic-assets-app` (blocking)

### Inventory and identity

- [x] Inventory `lib/research-profile/*`, MCP registry, and web `/api/user/author-link/candidate`. Document gaps vs contracts. **Done:** Corbis [`01-inventory`](../../../agentic-assets-app/docs/researchbar-evaluation/01-inventory-what-exists-today.md), [`02-gap-analysis`](../../../agentic-assets-app/docs/researchbar-evaluation/02-gap-analysis.md).
- [ ] Extend `find_academic_identity` MCP to match web candidate richness (ORCID label, h-index, top works, profile links). Part of Phase 0.C/D.
- [ ] ORCID-first `confirm_academic_identity` (internal author mapping stays server-side). Phase 0.A.
- [ ] Define and document citation-count reconciliation rule (primary source, cross-checks, divergence threshold).

### Aggregate MCP tools (build here, not in ResearchBar)

- [ ] **`get_research_pulse` v0:** ORCID, name, affiliation, credits, total citations, h-index, paper count, low-confidence flags, profile links, `fetchedAt` / `staleAfter` / `etag`. Trend fields **null** with `citationHistoryStatus` until Phase 1. Spec: Corbis [`08`](../../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md).
- [ ] **`get_new_work_radar`:** Phase 2.
- [ ] **`get_data_freshness`:** Phase 1.
- [ ] **`get_conference_deadlines`:** Phase 3; confirm finance-conference dataset.
- [ ] **`get_linked_repos` (Phase 2):** standalone vs nested (open product call).

### Corbis MCP plumbing

- [x] Re-authorize Corbis MCP. Confirm `https://www.corbis.ai/api/mcp/universal` answers from a native client with Bearer token.
- [x] Confirm direct native calling (no proxy) for Swift URLSession.
- [x] Confirm `get_paper_details_batch` is callable (max 25); use inside aggregates, not from client.
- [x] Confirm rate limits: **200/hour enforced**; 10 concurrent is documentation-only.
- [x] Billing: **0.5 credits per aggregate call** regardless of internal fan-out.
- [ ] Measure credit burn for one simulated day using aggregates (feeds [`funnel-economics.md`](funnel-economics.md)).

### Backend sources (server-side only)

- [ ] Confirm backend bibliographic source covers author works, h-index inputs, forward citations on ORCID-linked author; estimate bulk cost-to-serve.
- [ ] Crossref polite pool and 2025-12-01 rate limits.
- [ ] arXiv categories (q-fin.*, econ.*, cs.*) and 1 req/3s limit.

### Legal (before relying on a source)

- [ ] Semantic Scholar CC BY-NC: display in commercial app vs redistribution only (email AI2).
- [ ] Google Scholar: licensed channel only (SerpAPI), opt-in.
- [ ] SSRN downloads: license or omit (SSRN scraper is live in Corbis today).
- [ ] ResearchGate: compliant channel or omit.
- [ ] ORCID Public API vs Member API for revenue-generating use.

## Track B: ResearchBar fork (after Track A proves `get_research_pulse`)

### Shell and client

- [ ] Fork CodexBar (MIT) into a private repo; builds on Swift 6.2, macOS 14+.
- [ ] Corbis OAuth or API key in Keychain; thin ORCID confirm UI over existing identity tools.
- [ ] Render `get_research_pulse` in one menu panel; at most one aggregate call per refresh.
- [ ] Graft RepoBar GRDB **response cache** keyed by Corbis account; respect server `staleAfter` / `etag`.
- [ ] `UNUserNotificationCenter` on server-flagged deltas (Phase 1).

### Distribution and platform

- [ ] Register product domain. Candidate: [`research.bar`](https://instantdomainsearch.com?q=research.bar).
- [ ] Notarized DMG plus Sparkle plus Homebrew on a throwaway build.
- [ ] Test `NSStatusItem` on macOS 26 (Tahoe).
- [ ] Agent launch behind capability flag if App Store variant is ever wanted.
- [ ] Launch-at-login via `SMAppService`.

### macOS-only features (ResearchBar owns)

- [ ] Local git clone scanner: merge ahead/behind/dirty onto Corbis `get_linked_repos` records (Phase 2).
- [ ] Agent catalog from local Corbis plugin install; spawn Claude Code (Phase 3).

## Funnel and product

- [ ] Server-side credit-routing regime (see [`funnel-economics.md`](funnel-economics.md)).
- [ ] ResearchBar-specific Corbis free allowance larger than 50 lifetime credits.
- [ ] Five finance/RE colleagues: activation, signup, credit burn, time-to-value vs credit wall.
