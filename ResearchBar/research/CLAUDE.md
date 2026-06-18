# Research Archive Module

## Most Critical Rule

**Read-only provenance.** This folder is not a build spec. Do not derive implementation facts, API contracts, or phase plans from here. Use [`../build/`](../build/) or `../../../agentic-assets-app/docs/researchbar-evaluation/`.

## Naming Patterns

- `research-dossier.md`: synthesized six-lane report input
- `subagent-findings.md`: raw agent lanes (near-verbatim)
- `verification-verdicts.md`: twelve primary-source re-checks
- `sources.md`: URL index by lane (no Corbis `path:line` evidence)

## Module Boundaries

| Owns | Delegates |
|---|---|
| Pre-audit research narrative and citations | Code-grounded audit → [`../build/`](../build/), Corbis `_recon/` |
| CodexBar/RepoBar/macOS/Corbis landscape (June 2026) | Current MCP inventory → Corbis `01-inventory` |
| Verification dispositions for flagged claims | Live product truth → Corbis eval `06`–`07` |

## Integration Points

- Feeds: [`../concept/2026-06-17-researchbar-concept-and-recommendation.md`](../concept/2026-06-17-researchbar-concept-and-recommendation.md)
- Cross-check load-bearing claims via `verification-verdicts.md` before citing dossier numbers
- Code audit (2026-06-17) superseded several Corbis tool/credit claims from the research lanes

## Gotchas

- Dossier Corbis sections may cite plugin docs; live `agentic-assets-app` inventory (30 tools, 0.5/call) wins.
- Reference files name backend sources the **product never exposes**; ORCID + Corbis branding only in UI.
- `subagent-findings.md` is long; grep or use dossier unless auditing a specific lane.
- *Do not add new build requirements here; append research notes or link out to `build/`.*

## References

- Index: [`README.md`](README.md)
- Corbis eval: [`../../../agentic-assets-app/docs/researchbar-evaluation/_recon/`](../../../agentic-assets-app/docs/researchbar-evaluation/_recon/)
