# ResearchBar Documentation Module

## Most Critical Rule

**Docs describe the product; Swift lives in `Sources/CodexBar`.** Intelligence and aggregates belong in `agentic-assets-app`. This tree is spec and planning only. Builders start at [`BUILD.md`](BUILD.md), not the concept report.

**Fork strategy:** Reuse CodexBar aggressively. Keep inherited AI provider
usage code during Track B for upstream sync and implementation patterns, but
make Corbis research intelligence the default ResearchBar surface. Hide or
demote provider usage if it competes with the pulse menu.

## Naming Patterns

- Top-level entry: `researchbar-in-60-seconds.md`, `BUILD.md`, `OPEN-ISSUES.md`
- Subfolders: `build/` (facts), `concept/` (why), `research/` (provenance)
- Legacy path `corbis-integration-plan/`: redirect to `build/`
- Native client build guides: `build/06` through `build/10`

## Module Boundaries

| Owns | Delegates |
|---|---|
| ResearchBar product spec, client contract, blocker tracker | Corbis implementation: `../../agentic-assets-app/docs/researchbar-evaluation/` |
| Track B (macOS shell) guidance in `build/06` through `build/10` | Track A backend code: `agentic-assets-app` `lib/mcp/`, `lib/research-profile/` |
| Open issues and founder decisions | Repo build/test: root `AGENTS.md` |

## Integration Points

- Repo root: [`../AGENTS.md`](../AGENTS.md) (Swift app, scripts, tests)
- Corbis sibling: [`../../agentic-assets-app/docs/researchbar-evaluation/`](../../agentic-assets-app/docs/researchbar-evaluation/)
- Authority: product is `concept/`; implementation facts are `build/` plus Corbis `01` through `08`; native client slices are `build/06` through `10`; blockers are `OPEN-ISSUES.md`

## Gotchas

- **No code in this folder**; grep for `lib/mcp/` here finds nothing (citations target Corbis repo).
- Status: Phase 0 Corbis not shipped; client panel blocked until pulse v0 lands.
- Build fixtures first: `build/06` is allowed before live Corbis; `build/08` is blocked until Phase 0 smoke passes.
- Update `OPEN-ISSUES.md` when closing founder or engineering decisions.
- Keep cross-repo links pointed at sibling `../../agentic-assets-app` from this folder and `../../../agentic-assets-app` from subfolders.

## References

- Map: [`README.md`](README.md)
- Submodules: [`build/CLAUDE.md`](build/CLAUDE.md), [`concept/CLAUDE.md`](concept/CLAUDE.md), [`research/CLAUDE.md`](research/CLAUDE.md)
