# Concept Module (product north star)

## Most Critical Rule

**Concept explains why; it does not own implementation facts.** For client behavior, use current `Sources/CodexBar*`; for credits, tool counts, ORCID status, or pulse JSON, use current Corbis source and the maintained wire-contract reference. The `build/` folder is dated planning rationale, not a current authority.

## Naming Patterns

- Dated anchor report: `YYYY-MM-DD-researchbar-concept-and-recommendation.md`
- Thematic specs: `identity-and-data-consolidation.md`, `corbis-api-contracts.md`, `funnel-economics.md`
- Checklist defers live status to [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md)

## Module Boundaries

| Owns | Delegates |
|---|---|
| Recommendation, menu mock, funnel narrative, fork/GTM | Current implementation → `Sources/CodexBar*` |
| Architecture principles (thin client, ORCID anchor) | Corbis backend depth → `../../../agentic-assets-app/docs/researchbar-evaluation/` |
| Illustrative aggregate shapes | Precise JSON → current Corbis source and [`../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md) |
| Phase 0 checklist (historical) | Open blockers → [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md) |

## Integration Points

- Start: [`2026-06-17-researchbar-concept-and-recommendation.md`](2026-06-17-researchbar-concept-and-recommendation.md)
- Provenance: [`../research/research-dossier.md`](../research/research-dossier.md)
- Economics tables are historical evidence, not entitlement/allowance guidance.
- Phase ordering in report §7 is historical; check current source and [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md) for live status.

## Gotchas

- Do not quote Corbis paper-corpus figures from docs; use live corbis.ai only.
- Never-surface is a **target**; Corbis Phase 0.B required before client can rely on payloads.
- `corbis-api-contracts.md` pulse trends are nullable in v0; see `citationHistoryStatus` in `build/02`.
- *Edit concept for product/strategy; update source-backed contract/reference docs when code facts change.*

## References

- Index: [`README.md`](README.md)
- Build entry: [`../BUILD.md`](../BUILD.md)
