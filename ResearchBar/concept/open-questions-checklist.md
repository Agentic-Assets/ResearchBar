# Phase 0 validation checklist

Open questions to close before scaling beyond the pulse panel. **Track A (Corbis) blocks Track B (ResearchBar).** Each item is phrased so the answer closes it.

## Track A: Corbis `agentic-assets-app` (blocking)

### Inventory and identity

- [ ] Inventory `lib/research-profile/*`, MCP registry, and web `/api/user/author-link/candidate`. Document gaps vs `corbis-api-contracts.md`.
- [ ] Extend `find_academic_identity` MCP to match web candidate richness (ORCID label, h-index, top works, profile links).
- [ ] Migrate `confirm_academic_identity` to ORCID-first confirm (internal author mapping stays server-side).
- [ ] Define and document citation-count reconciliation rule (primary source, cross-checks, divergence threshold).

### Aggregate MCP tools (build here, not in ResearchBar)

- [ ] **`get_research_pulse` v0:** ORCID, name, affiliation, credits, total citations, 7d/52w deltas, sparkline, h-index, paper count, low-confidence flags, profile links, `fetchedAt` / `staleAfter` / `etag`.
- [ ] **`get_new_work_radar`:** citing papers, subfield alerts, related-to-project items; every item has Corbis-resolved links.
- [ ] **`get_data_freshness`:** FRED/CRE/dataset release items for server-side field presets.
- [ ] **`get_conference_deadlines`:** curated seed plus user overrides stored server-side; confirm public finance-conference dataset is still maintained or start curation pipeline.
- [ ] **`get_linked_repos` (Phase 2):** paper-to-repo associations plus remote GitHub metadata when account linked. Decide standalone tool vs nested block.

### Corbis MCP plumbing

- [ ] Re-authorize Corbis MCP. Confirm `https://www.corbis.ai/api/mcp/universal` answers from a native client with Bearer token.
- [ ] Confirm direct native calling (no proxy) for Swift URLSession.
- [ ] Confirm `get_paper_details_batch` is callable (max 25); use inside aggregates, not from client.
- [ ] Confirm rate limits (200/hour, 10 concurrent) and throttling signals.
- [ ] Product sign-off: **one credit per aggregate call** regardless of internal fan-out.
- [ ] Measure credit burn for one simulated day using aggregates (feeds `funnel-economics.md`).

### Backend sources (server-side only)

- [ ] Confirm backend bibliographic source covers author works, h-index inputs, forward citations on ORCID-linked author; estimate bulk cost-to-serve.
- [ ] Crossref polite pool and 2025-12-01 rate limits.
- [ ] arXiv categories (q-fin.*, econ.*, cs.*) and 1 req/3s limit.

### Legal (before relying on a source)

- [ ] Semantic Scholar CC BY-NC: display in commercial app vs redistribution only (email AI2).
- [ ] Google Scholar: licensed channel only (SerpAPI), opt-in.
- [ ] SSRN downloads: license or omit.
- [ ] ResearchGate: compliant channel or omit.
- [ ] ORCID Public API vs Member API for revenue-generating use.

## Track B: ResearchBar fork (after Track A proves `get_research_pulse`)

### Shell and client

- [ ] Fork CodexBar (MIT) into a private repo; builds on Swift 6.2, macOS 14+.
- [ ] Corbis OAuth or API key in Keychain; thin ORCID confirm UI over existing identity tools.
- [ ] Render `get_research_pulse` in one menu panel; at most one aggregate call per refresh.
- [ ] Graft RepoBar GRDB **response cache** and polling; respect server `staleAfter` / `etag`.
- [ ] `UNUserNotificationCenter` on server-flagged deltas (Phase 1).

### Distribution and platform

- [ ] Register product domain. Candidate: [`research.bar`](https://instantdomainsearch.com?q=research.bar) (menu-bar on-brand; verify availability and `.bar` registrar pricing before committing).
- [ ] Notarized DMG plus Sparkle plus Homebrew on a throwaway build.
- [ ] Test `NSStatusItem` on macOS 26 (Tahoe).
- [ ] Agent launch behind capability flag if App Store variant is ever wanted.
- [ ] Launch-at-login via `SMAppService`.

### macOS-only features (ResearchBar owns)

- [ ] Local git clone scanner: merge ahead/behind/dirty onto Corbis `get_linked_repos` records (Phase 2).
- [ ] Agent catalog from local Corbis plugin install; spawn Claude Code (Phase 3). Revisit Corbis `get_agent_catalog` if web needs parity.

## Funnel and product

- [ ] Server-side credit-routing regime (see `funnel-economics.md`).
- [ ] ResearchBar-specific Corbis free allowance larger than 50 lifetime credits.
- [ ] Five finance/RE colleagues: activation, signup, credit burn, time-to-value vs credit wall.
