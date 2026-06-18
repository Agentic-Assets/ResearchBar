# Build Module (code-grounded)

## Most Critical Rule

**This folder wins on implementation facts.** Corbis Track A Phase 0 (`get_research_pulse` v0 + ORCID anchor + redaction) blocks the client. Do not plan or implement against stale concept numbers. Read `00` first.

## Naming Patterns

- Deliverables: `NN-topic-slug.md` (`00`–`05`); do not renumber without updating `README.md`.
- `path:line` citations point into **`../../../agentic-assets-app`**, never this repo.
- Doc-name paths (e.g. `corbis-api-contracts.md`) mean [`../concept/`](../concept/).

## Module Boundaries

| Owns | Delegates |
|---|---|
| Client rules, pulse JSON contract, condensed Corbis phases | Full backend spec → `../../../agentic-assets-app/docs/researchbar-evaluation/` (`01`–`09`) |
| Corrected facts (30 tools, 0.5 credits/call, ORCID unstarted) | Product why → [`../concept/`](../concept/) |
| Track B readiness gates | Swift implementation → repo `Sources/CodexBar` |
| Audit errata record | Living blockers → [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md) |

## Integration Points

- **Corbis implement:** `researchbar-evaluation/08-get-research-pulse-v0-spec.md`, `05-revised-implementation-plan.md`
- **Client contract:** `02-mcp-contract-get-research-pulse.md` (Swift renders this JSON)
- **Phase gate:** `03-corbis-track-a-plan.md` done-when + curl smoke tests in `02`
- **Supersedes:** [`../concept/corbis-api-contracts.md`](../concept/corbis-api-contracts.md) on pulse shape and inventory

## Gotchas

- Trend fields are **null in v0**; UI must use `citationHistoryStatus`, never fake zeros.
- Never-surface is violated in shipped Corbis MCP output; client redacts defensively too.
- GRDB cache must be keyed by Corbis account; server MCP cache is user-blind.
- Poll on menu-open or slow cadence; 50 lifetime credits ≈ 100 calls at 0.5/call.

## References

- Index: [`README.md`](README.md), entry: [`../BUILD.md`](../BUILD.md)
- Corbis eval: [`../../../agentic-assets-app/docs/researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/)
