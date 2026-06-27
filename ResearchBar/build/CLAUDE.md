# Build Module (code-grounded)

## Most Critical Rule

**This folder wins on implementation facts.** Corbis Track A Phase 0 (`get_research_pulse` v0 + ORCID anchor + redaction) **is shipped (2026-06-27), so the client is unblocked**; build Track B against fixtures (`06`), then live (`08`). Do not plan or implement against stale concept numbers. Read `00` first. The authoritative wire schema is [`../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md) §4-§5; it wins over the JSON sketches in `02`/`06` on any conflict.

## Naming Patterns

- Deliverables: `NN-topic-slug.md` (`00`–`10`); do not renumber without updating `README.md`.
- `00`–`05`: dependency facts, boundary, contract, phases, risks.
- `06`–`10`: Track B native-client build guides.
- `path:line` citations point into **`../../../agentic-assets-app`**, never this repo.
- Doc-name paths (e.g. `corbis-api-contracts.md`) mean [`../concept/`](../concept/).

## Module Boundaries

| Owns | Delegates |
|---|---|
| Client rules, pulse JSON contract, condensed Corbis phases | Full backend spec: `../../../agentic-assets-app/docs/researchbar-evaluation/` (`01` through `09`) |
| Corrected facts (0.5 credits/call; live `tools/list` 41 authed / 31 anon; ORCID anchor shipped) | Product why: [`../concept/`](../concept/) |
| Track B readiness gates and modular client plans | Swift implementation: repo `Sources/CodexBar` |
| Audit errata record | Living blockers: [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md) |

## Integration Points

- **Corbis implement:** `researchbar-evaluation/08-get-research-pulse-v0-spec.md`, `05-revised-implementation-plan.md`
- **Client contract:** `02-mcp-contract-get-research-pulse.md` (Swift renders this JSON)
- **Phase gate:** `03-corbis-track-a-plan.md` done-when + curl smoke tests in `02`
- **Track B sequence:** `06` fixtures, `07` auth/cache, `08` live MCP, `09` menu rendering, `10` distribution
- **Supersedes:** [`../concept/corbis-api-contracts.md`](../concept/corbis-api-contracts.md) on pulse shape and inventory

## Gotchas

- Trend fields are **null in v0**; UI must use `citationHistoryStatus`, never fake zeros.
- Never-surface was violated in shipped Corbis MCP output at audit; the pulse surface is now redacted, but the client redacts defensively regardless.
- GRDB cache must be keyed by Corbis account; server MCP cache is user-blind.
- Poll on menu-open or slow cadence; 50 lifetime credits is about 100 calls at 0.5/call.
- Do not add global package rename, Sparkle feed changes, or Homebrew cask work before the pulse path works.

## References

- Index: [`README.md`](README.md), entry: [`../BUILD.md`](../BUILD.md)
- Corbis eval: [`../../../agentic-assets-app/docs/researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/)
