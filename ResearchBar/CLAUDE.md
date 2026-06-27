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

- **Client wire contract (authoritative): [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md).** This is a symlink into the Corbis repo's verified guide (`../../agentic-assets-app/docs/researchbar-evaluation/RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`). It is the single source of truth for the MCP transport/auth/billing contract, the live `get_research_pulse` and `get_data_freshness` schemas, the identity handshake, and the client redaction rules. When `build/` and this guide disagree on a wire fact, the guide wins (it is verified against Corbis code at `file:line`). The symlink resolves only when both repos are cloned as siblings under `agentic-assets/`.
- Repo root: [`../AGENTS.md`](../AGENTS.md) (Swift app, scripts, tests)
- Corbis sibling: [`../../agentic-assets-app/docs/researchbar-evaluation/`](../../agentic-assets-app/docs/researchbar-evaluation/)
- Authority: product is `concept/`; implementation facts are `build/` plus Corbis `01` through `08`; native client slices are `build/06` through `10`; blockers are `OPEN-ISSUES.md`

## Gotchas

- **No code in this folder**; grep for `lib/mcp/` here finds nothing (citations target Corbis repo).
- Status (2026-06-27): Corbis Phase 0 + Phase 1 (`get_research_pulse`, `get_data_freshness`, citation-trend snapshots) are implemented and the live MCP smoke passes over real HTTP, so the client panel is **unblocked**. Evidence and the wire contract are in [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md) and Corbis `_recon/2026-06-26-live-smoke.md`.
- Build fixtures first regardless: `build/06` is the fixture path; live mode (`build/08`) is now allowed because the Phase 0 smoke passed, but keep the fixture suite as the test backbone.
- Update `OPEN-ISSUES.md` when closing founder or engineering decisions.
- Keep cross-repo links pointed at sibling `../../agentic-assets-app` from this folder and `../../../agentic-assets-app` from subfolders.

## References

- **Client wire contract: [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md)** (symlink to the verified Corbis guide).
- Map: [`README.md`](README.md)
- Submodules: [`build/CLAUDE.md`](build/CLAUDE.md), [`concept/CLAUDE.md`](concept/CLAUDE.md), [`research/CLAUDE.md`](research/CLAUDE.md)
