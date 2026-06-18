# ResearchBar in 60 seconds

**What:** A free macOS menu bar app for academics. Citations, new papers, macro and CRE data releases, deadlines, replication repos, and a one-click Corbis research agent.

**Tagline:** ResearchBar is free. It runs on Corbis.

**Chassis:** Public fork of CodexBar (MIT). The shell is open; the brain is not.

**Architecture in one breath:**

| Layer | Where it lives |
|---|---|
| Identity (ORCID), citations, radar, freshness, deadlines | Corbis `agentic-assets-app` |
| Menu bar, auth, cache, notifications, agent launch | This repo (`ResearchBar/`) |
| Linked repos (remote metadata) | Corbis |
| Local git ahead/behind | ResearchBar only |

**Build order:** Corbis APIs first (`get_research_pulse` and friends), thin client second. Start at [`BUILD.md`](BUILD.md) and [`build/00-what-this-means-for-researchbar.md`](build/00-what-this-means-for-researchbar.md).

**Phase 0 right now:** Ship `get_research_pulse` in Corbis ([`agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md`](../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md)), then render it here.

**Blockers:** [`OPEN-ISSUES.md`](OPEN-ISSUES.md).

**Moat:** No other citation tracker launches a Corbis-powered Claude Code agent from the menu bar.

**Funnel:** Every install that reaches value is a Corbis account. Finance and real estate academics first; everything else is a server-side preset change.

**Full spec:** [`README.md`](README.md) in this folder.

*Concept package moved here 2026-06-17; reorganized into `build/`, `concept/`, `research/` 2026-06-18.*
