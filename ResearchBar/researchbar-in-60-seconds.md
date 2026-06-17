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

**Build order:** Corbis APIs first (`get_research_pulse` and friends), thin client second. See `corbis-api-contracts.md`.

**Phase 0 right now:** Ship `get_research_pulse` in Corbis, then render it here.

**Moat:** No other citation tracker launches a Corbis-powered Claude Code agent from the menu bar.

**Funnel:** Every install that reaches value is a Corbis account. Finance and real estate academics first; everything else is a server-side preset change.

**Full spec:** Start at `README.md` in this folder.

*Concept package moved here 2026-06-17 from `ResearchBar-Concept/`.*
