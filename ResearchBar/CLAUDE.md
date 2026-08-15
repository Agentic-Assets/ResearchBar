# ResearchBar Documentation Module

## Most Critical Rule

**Docs describe the product; current Swift behavior lives in `Sources/CodexBar*`.** Intelligence and aggregates belong in `agentic-assets-app`. This folder contains product context, maintained contract guidance, and dated planning evidence; it does not own implementation facts. Builders start with the current source and [`BUILD.md`](BUILD.md), not the concept report.

**Fork strategy:** Reuse CodexBar aggressively. Keep inherited AI provider
usage code during Track B for upstream sync and implementation patterns, but
make Corbis research intelligence the default ResearchBar surface. Hide or
demote provider usage if it competes with the pulse menu.

## Naming Patterns

- Top-level entry: `researchbar-in-60-seconds.md`, `BUILD.md`, `OPEN-ISSUES.md`
- Subfolders: `build/` (dated implementation plans), `concept/` (why), `research/` (provenance)
- Legacy path `corbis-integration-plan/`: redirect to `build/`
- Native client build guides: `build/06` through `build/10`

## Module Boundaries

| Owns | Delegates |
|---|---|
| ResearchBar product spec, client contract, blocker tracker | Corbis implementation: `../../agentic-assets-app/docs/researchbar-evaluation/` |
| Track B (macOS shell) guidance in `build/06` through `build/10` | Track A backend code: `agentic-assets-app` `lib/mcp/`, `lib/research-profile/` |
| Open issues and founder decisions | Repo build/test: root `AGENTS.md` |

## Integration Points

- **Client wire-contract reference: [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md).** It is a maintained repository copy, not a symlink. For transport/auth/billing or schema changes, re-verify the cited Corbis source in `agentic-assets-app` before editing client code; the backend source wins over this snapshot and all dated plans.
- Repo root: [`../AGENTS.md`](../AGENTS.md) (Swift app, scripts, tests)
- Corbis sibling: [`../../agentic-assets-app/docs/researchbar-evaluation/`](../../agentic-assets-app/docs/researchbar-evaluation/)
- Authority: current ResearchBar source owns client behavior; current Corbis source owns wire behavior; the maintained wire-contract reference records the integration boundary; `build/`, `concept/`, and `research/` are dated context; blockers are `OPEN-ISSUES.md`.

## Gotchas

- **No code in this folder**; grep for `lib/mcp/` here finds nothing (citations target Corbis repo).
- The Corbis menu/card, cache, credential, and client seams are implemented in the current source. Fixture-backed tests remain the default verification path; live MCP verification is opt-in, requires explicit authorization, and must use a safe test account.
- Update `OPEN-ISSUES.md` when closing founder or engineering decisions.
- Keep cross-repo links pointed at sibling `../../agentic-assets-app` from this folder and `../../../agentic-assets-app` from subfolders.

## References

- **Client wire-contract reference: [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md)** (maintained local copy; backend source is authoritative).
- Map: [`README.md`](README.md)
- Submodules: [`build/CLAUDE.md`](build/CLAUDE.md), [`concept/CLAUDE.md`](concept/CLAUDE.md), [`research/CLAUDE.md`](research/CLAUDE.md)
