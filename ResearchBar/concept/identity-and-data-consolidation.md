# Identity and data consolidation architecture

> **Implementation facts:** [`../build/`](../build/) and Corbis [`researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/). ORCID-first confirm is **unstarted** (no `orcid` column). Never-surface requires a **backend redaction pass** (Phase 0.B), not something the thin client inherits today.

This file is the source of truth for how ResearchBar handles researcher identity and how it consolidates citations, rankings, and profile data. It encodes the architectural decisions that supersede looser framing in the original concept report. Where this file and the report disagree on architecture, this file wins. Where this file disagrees with [`../build/`](../build/) on code-verified facts, the build docs win.

**Companion:** [`corbis-api-contracts.md`](corbis-api-contracts.md) lists the aggregate MCP tools ResearchBar calls and the Corbis-vs-ResearchBar split for linked repos and the agent catalog.

## The five decisions

1. **ORCID is the public identity anchor.** The ID a user sees, confirms, and is keyed on is their ORCID. No other source ID is ever shown to the user.
2. **Consolidation is a centralized Corbis service.** Pulling, cross-verifying, and reconciling citation counts, rankings, and profile data across many sources is done server-side in `agentic-assets-app`, not in the client.
3. **Menu intelligence is aggregate Corbis APIs.** Panels call `get_research_pulse`, `get_new_work_radar`, `get_data_freshness`, and `get_conference_deadlines` (see contracts doc), not low-level tool fan-out.
4. **ResearchBar is a thin macOS client.** Shell, auth, render, cache, notifications, local git merge, and agent launch. No scrapers, reconcilers, or orchestration loops.
5. **Backend source names are never surfaced.** The user sees ORCID and Corbis-branded consolidated results only. **Today:** shipped MCP output still leaks internal ids and backend names; fixing this is Corbis Phase 0.B ([`../build/03-corbis-track-a-plan.md`](../build/03-corbis-track-a-plan.md)).

## Why centralize in agentic-assets-app

- **Reuse.** One service serves ResearchBar, corbis.ai web, and later surfaces.
- **Single source of truth.** Dedup, reconciliation, and confidence rules improve everywhere at once.
- **Compliance containment.** ToS-sensitive sources stay behind one audited server boundary.
- **Credit and cost control.** Billing and routing tune without client updates.
- **Brand.** The user experiences "Corbis told me," not "this app scraped six sites."

## The identity model

The user confirms one thing: their ORCID. Everything else hangs off it server-side.

1. Connect a Corbis account (OAuth or API key).
2. `find_academic_identity` proposes a match; the candidate is labeled by ORCID.
3. `confirm_academic_identity` links the identity. **Target:** confirm by ORCID. **Today:** confirm requires the internal author id (`confirm-academic-identity.ts` in Corbis); ORCID-first is net-new backend work (add `orcid` column, resolver, ORCID accept path). See [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md).
4. Aggregates return ORCID-keyed, link-complete JSON; the client renders.

Live Corbis already has substantial identity plumbing (`lib/research-profile/*`, MCP tools, web candidate API). Phase 0 inventories it and extends MCP to match web richness before the fork depends on it. See inventory in `corbis-api-contracts.md`.

## The consolidation model

For a researcher (ORCID) and each work (DOI where available), the service:

1. Gathers candidate records from compliant backends.
2. Deduplicates (DOI first, then fuzzy title and author).
3. Reconciles conflicting numbers under a documented rule.
4. Flags low-confidence disagreement without naming sources.
5. Returns one Corbis-branded result with resolved links on every entity.

## Backend source posture (server-side, never surfaced)

Engineering reference for `agentic-assets-app` only. None of these names reach the UI.

| Backend | Role inside the service | Compliance posture | Verdict |
|---|---|---|---|
| Corbis native tools | Identity, papers, citations, FRED, CRE | First-party | Backbone |
| Public bibliographic graph (unbranded) | Author works, career metrics, forward citations | CC0; bulk usage pricing | Core gap-filler, never named |
| Crossref | DOI resolution and metadata | Polite pool with `mailto=` | Use |
| arXiv | Preprint coverage | Open metadata; rate limits | Use |
| Semantic Scholar | Optional graph and recommendations | Confirm commercial eligibility | After legal check |
| Google Scholar | Optional vanity h-index | Licensed channel only (e.g. SerpAPI) | Premium, opt-in |
| SSRN | Downloads and views | No scraping; license or omit | Optional |
| ResearchGate | Profile metrics | Compliant channel or omit | Optional |
| ORCID registry | Identity anchor | Public API limits; Member API paid | Anchor; linkages via compliant paths |

## Corbis vs ResearchBar boundary

| Capability | Corbis (`agentic-assets-app`) | ResearchBar (fork) |
|---|---|---|
| `get_research_pulse` | Build | Call and render |
| `get_new_work_radar` | Build | Call and render |
| `get_data_freshness` | Build | Call and render |
| `get_conference_deadlines` | Build (curate plus user overrides) | Call and render |
| Identity find/confirm | Build and extend | Thin confirm UI only |
| Paper-to-repo associations | Build (`get_linked_repos` or nested) | Merge local git state only |
| GitHub remote metadata (CI, stars) | Serve via Corbis when account linked | Do not poll GitHub API in v1 if Corbis serves it |
| Agent catalog metadata | Optional later (`get_agent_catalog`) | v1: read local plugin install |
| Agent launch (Claude Code) | N/A (not server-side) | Build (subprocess) |
| Menu shell, Sparkle, notifications | N/A | Build (CodexBar fork) |
| Response cache and polling | Sets `staleAfter` / `etag` | GRDB cache; respect server cadence |

## Phase 0 actions (Corbis first)

**Track A (blocking):**

- Inventory `lib/research-profile/*` and MCP registry.
- Ship `get_research_pulse` v0 (ORCID, static citation metrics, profile links, null trend fields, and `citationHistoryStatus`).
- Extend `find_academic_identity` / `confirm_academic_identity` for ORCID-first confirm and web candidate parity.
- Define citation reconciliation rule.

**Track B (after Track A proves the contract):**

- Fork CodexBar shell; Corbis auth; render one panel from `get_research_pulse`.
- No other features until the aggregate call works end to end.

## Open questions

1. Confirm by ORCID directly when name search fails?
2. `get_linked_repos` as standalone tool vs nested block?
3. Promote `get_agent_catalog` to Corbis when web needs it, or keep v1 local-only?
4. Credit billing: 0.5 credits per aggregate call today; decide whether ResearchBar gets a separate allowance or subsidy.
