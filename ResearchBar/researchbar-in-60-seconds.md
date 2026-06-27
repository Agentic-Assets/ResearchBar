# ResearchBar in 60 seconds

**What:** A free macOS menu bar app for academics. Citations, new papers, macro and CRE data releases, deadlines, replication repos, and a one-click Corbis research agent.

**Tagline:** ResearchBar is free. It runs on Corbis.

**Chassis:** Public fork of CodexBar (MIT). Reuse the shell, provider
patterns, settings, tests, and release pipeline. Keep generic AI usage as
optional inherited machinery, not the main product. The shell is open; the
brain is not.

**Architecture in one breath:**

| Layer | Where it lives |
|---|---|
| Identity (ORCID), citations, radar, freshness, deadlines | Corbis `agentic-assets-app` |
| Menu bar, auth, cache, notifications, agent launch | This repo (`ResearchBar/`) |
| Linked repos (remote metadata) | Corbis |
| Local git ahead/behind | ResearchBar only |

**Build order:** Corbis APIs first (`get_research_pulse` and friends), thin client second. Start at [`BUILD.md`](BUILD.md) and [`build/00-what-this-means-for-researchbar.md`](build/00-what-this-means-for-researchbar.md).

**Phase 0 status (2026-06-27):** `get_research_pulse` (and `get_data_freshness`) are shipped in Corbis and pass the live MCP smoke, so the client is unblocked. Now render the pulse here.

**Client wire contract:** [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md) (symlink to the verified Corbis guide): transport, auth, billing, live schemas, identity handshake, redaction.

**Blockers:** [`OPEN-ISSUES.md`](OPEN-ISSUES.md).

**Moat:** No other citation tracker launches a Corbis-powered Claude Code agent from the menu bar.

**Funnel:** Every install that reaches value is a Corbis account. Finance and real estate academics first; everything else is a server-side preset change.

**Full spec:** [`README.md`](README.md) in this folder.

*Concept package moved here 2026-06-17; reorganized into `build/`, `concept/`, `research/` 2026-06-18.*
