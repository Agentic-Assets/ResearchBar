# Build Module (dated implementation plans)

## Most Critical Rule

**These are dated implementation plans, not the authority for current behavior.** Current ResearchBar source owns client facts; current Corbis source owns wire facts; [`../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md) is a maintained local reference that must be rechecked against Corbis source when the backend contract changes. Read [`../../docs/superpowers/specs/2026-08-14-corbis-dashboard-design.md`](../../docs/superpowers/specs/2026-08-14-corbis-dashboard-design.md) for the current client presentation/privacy constraints. Preserve these plans as historical implementation rationale rather than executing future-tense tasks verbatim.

## Naming Patterns

- Deliverables: `NN-topic-slug.md` (`00`–`10`); do not renumber without updating `README.md`.
- `00`–`05`: dependency facts, boundary, contract, phases, risks.
- `06`–`10`: Track B native-client build guides.
- `path:line` citations point into **`../../../agentic-assets-app`**, never this repo.
- Doc-name paths (e.g. `corbis-api-contracts.md`) mean [`../concept/`](../concept/).

## Module Boundaries

| Owns | Delegates |
|---|---|
| Historical client rules, pulse JSON sketches, condensed Corbis phases | Full backend spec: `../../../agentic-assets-app/docs/researchbar-evaluation/` (`01` through `09`) |
| Dated audit evidence | Product why: [`../concept/`](../concept/) |
| Modular Track B implementation rationale | Swift implementation: repo `Sources/CodexBar*` |
| Audit errata record | Living blockers: [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md) |

## Integration Points

- **Corbis implement:** `researchbar-evaluation/08-get-research-pulse-v0-spec.md`, `05-revised-implementation-plan.md`
- **Client contract:** `02-mcp-contract-get-research-pulse.md` (Swift renders this JSON)
- **Phase gate:** `03-corbis-track-a-plan.md` done-when + curl smoke tests in `02`
- **Track B sequence:** `06` fixtures, `07` auth/cache, `08` live MCP, `09` menu rendering, `10` distribution
- **Supersedes:** [`../concept/corbis-api-contracts.md`](../concept/corbis-api-contracts.md) on pulse shape and inventory

## Gotchas

- Null/invalid history never becomes a fake zero or chart; a validated tracked history may render a full-width citation chart.
- Client redaction fails closed on private identity evidence, credentials, and backend plumbing; public academic provenance is allowed only in its declared source-aware contract field.
- The file/in-memory cache is account-scoped via safe account identity; GRDB remains a deferred storage choice.
- Refresh only through the current menu-open/manual/cache policy. Render only an authoritative remaining finite or unlimited credit balance; never infer a quota, allowance, reset, rate, or usage history.
- Do not add global package rename, Sparkle feed changes, or Homebrew cask work before the pulse path works.

## References

- Index: [`README.md`](README.md), entry: [`../BUILD.md`](../BUILD.md)
- Corbis eval: [`../../../agentic-assets-app/docs/researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/)
