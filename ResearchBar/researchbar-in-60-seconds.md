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

**Current client status (2026-08-14):** ResearchBar already renders the fixture-backed pulse through an account-scoped cache and MCP seam. The card shows safe, source-aware research data and only charts validated citation history. Live MCP/account checks remain opt-in and require explicit authorization.

**Client wire-contract reference:** [`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`](RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md) (maintained local copy; current Corbis source is authoritative): transport, auth, billing, schemas, identity handshake, redaction.

**Blockers:** [`OPEN-ISSUES.md`](OPEN-ISSUES.md).

**Moat:** No other citation tracker launches a Corbis-powered Claude Code agent from the menu bar.

**Funnel:** Every install that reaches value is a Corbis account. Finance and real estate academics first; everything else is a server-side preset change.

**Full spec:** [`README.md`](README.md) in this folder.

*Concept package moved here 2026-06-17; reorganized into `build/`, `concept/`, `research/` 2026-06-18.*
