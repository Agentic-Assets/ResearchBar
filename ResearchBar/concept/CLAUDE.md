# Concept Module (product north star)

## Most Critical Rule

**Concept explains why; it does not own implementation facts.** For credits, tool counts, ORCID status, pulse JSON, or phase order, use [`../build/`](../build/) or Corbis `researchbar-evaluation/`. If this folder disagrees with `build/` on facts, `build/` wins.

## Naming Patterns

- Dated anchor report: `YYYY-MM-DD-researchbar-concept-and-recommendation.md`
- Thematic specs: `identity-and-data-consolidation.md`, `corbis-api-contracts.md`, `funnel-economics.md`
- Checklist defers live status to [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md)

## Module Boundaries

| Owns | Delegates |
|---|---|
| Recommendation, menu mock, funnel narrative, fork/GTM | Implementation → [`../build/`](../build/) |
| Architecture principles (thin client, ORCID anchor) | Corbis backend depth → `../../../agentic-assets-app/docs/researchbar-evaluation/` |
| Illustrative aggregate shapes | Precise JSON → [`../build/02-mcp-contract-get-research-pulse.md`](../build/02-mcp-contract-get-research-pulse.md) |
| Phase 0 checklist (historical) | Open blockers → [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md) |

## Integration Points

- Start: [`2026-06-17-researchbar-concept-and-recommendation.md`](2026-06-17-researchbar-concept-and-recommendation.md)
- Provenance: [`../research/research-dossier.md`](../research/research-dossier.md)
- Economics tables use **0.5 credits/call** (corrected 2026-06-18)
- Phase ordering in report §7 is **superseded** by [`../build/03-corbis-track-a-plan.md`](../build/03-corbis-track-a-plan.md)

## Gotchas

- Do not quote Corbis paper-corpus figures from docs; use live corbis.ai only.
- Never-surface is a **target**; Corbis Phase 0.B required before client can rely on payloads.
- `corbis-api-contracts.md` pulse trends are nullable in v0; see `citationHistoryStatus` in `build/02`.
- *Edit concept for product/strategy; edit `build/` or Corbis eval when code facts change.*

## References

- Index: [`README.md`](README.md)
- Build entry: [`../BUILD.md`](../BUILD.md)
