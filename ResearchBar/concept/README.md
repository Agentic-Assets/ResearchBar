# Concept layer (product north star)

> **Historical concept package (June 2026).** Preserve these documents for product rationale and decision provenance,
> but do not use unqualified "today," "current," phase, tool-count, rate, or implementation-status statements as
> present facts. Current client authority is [`../BUILD.md`](../BUILD.md), the maintained
> [`../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md), and current source/tests.
> Current backend authority is the sibling `agentic-assets-app` source.

**Status:** Concept exploration and high-level spec. **Not** the implementation source of truth for current facts.

For building, use [`../BUILD.md`](../BUILD.md) and [`../build/`](../build/). For Corbis backend depth, use [`../../../agentic-assets-app/docs/researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/).

Factual corrections from the 2026-06-17 code audit were applied to these files on 2026-06-18. If anything here disagrees with [`../build/`](../build/) or the Corbis evaluation on implementation facts, the build docs win.

## Read order

1. [`2026-06-17-researchbar-concept-and-recommendation.md`](2026-06-17-researchbar-concept-and-recommendation.md) — recommendation, menu mock, funnel, fork strategy, GTM.
2. [`identity-and-data-consolidation.md`](identity-and-data-consolidation.md) — ORCID anchor, thin client, never-surface rule.
3. [`corbis-api-contracts.md`](corbis-api-contracts.md) — aggregate tools (illustrative; precise JSON in [`../build/02`](../build/02-mcp-contract-get-research-pulse.md)).
4. [`funnel-economics.md`](funnel-economics.md) — credit burn and conversion (tables at 0.5 credits/call).
5. [`open-questions-checklist.md`](open-questions-checklist.md) — Phase 0 checklist (living items in [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md)).

## Note on phase ordering

The concept report (§7) orders radar/deadlines before data freshness. The code-grounded plan in [`../build/03`](../build/03-corbis-track-a-plan.md) and Corbis [`05-revised-implementation-plan.md`](../../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md) supersede that sequencing.
