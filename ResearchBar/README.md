# ResearchBar concept and spec

Research-backed concept and high-level spec for **ResearchBar**: a macOS menu bar app for academic researchers (papers, citations, related work, GitHub repos, conference deadlines), powered by and gated to Corbis as a free top-of-funnel into the paid platform.

**New here?** Read [`researchbar-in-60-seconds.md`](researchbar-in-60-seconds.md) first.

**Canonical location:** `ResearchBar/ResearchBar/` inside the [Agentic-Assets/ResearchBar](https://github.com/Agentic-Assets/ResearchBar) repo (CodexBar fork). Concept docs were moved here from `agentic-assets/ResearchBar-Concept/` on 2026-06-17.

## Read in this order

1. **`2026-06-17-researchbar-concept-and-recommendation.md`** - main report: recommendation, product, funnel, fork strategy, roadmap, business model, risks.
2. **`identity-and-data-consolidation.md`** - ORCID anchor, centralized Corbis service, thin client, never-surface rule.
3. **`corbis-api-contracts.md`** - aggregate MCP tools and Corbis vs ResearchBar split.
4. **`funnel-economics.md`** - illustrative credit burn and conversion.
5. **`open-questions-checklist.md`** - Phase 0 checklist (Corbis Track A before ResearchBar Track B).

## Reference material (the research underneath)

6. **`research-dossier.md`** - synthesized research across six lanes.
7. **`subagent-findings.md`** - raw sub-agent output.
8. **`verification-verdicts.md`** - 12 flagged claims re-checked.
9. **`sources.md`** - citation URLs by lane.

Reference files name data sources the product never exposes. In the product the user sees ORCID and Corbis-branded results only.

## Code-grounded plan (start here for a build)

The verified, code-grounded plan now lives in [`corbis-integration-plan/`](corbis-integration-plan/). It inventories the live Corbis codebase, corrects the concept docs where the code disagrees (tool count 24 to 30, credit cost 1 to 0.5, ORCID-first "in progress" to unstarted), specifies the exact `get_research_pulse` contract the client renders, and lays out the phased Corbis Track A plan the client depends on. Where it and the concept docs below disagree on facts, the code-grounded plan wins.

## Status

Concept exploration plus high-level spec. Not a build spec. The Phase 0 Track A implementation plan promised here was delivered in [`corbis-integration-plan/`](corbis-integration-plan/) on 2026-06-17 (with the full Corbis-internal evaluation in `agentic-assets-app/docs/researchbar-evaluation/`).
