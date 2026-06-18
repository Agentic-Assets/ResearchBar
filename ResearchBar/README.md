# ResearchBar documentation

Research-backed concept and build spec for **ResearchBar**: a macOS menu bar app for academic researchers, powered by and gated to Corbis.

**New here?** Read [`researchbar-in-60-seconds.md`](researchbar-in-60-seconds.md).

**Building?** Start at [`BUILD.md`](BUILD.md).

**Tracking blockers?** See [`OPEN-ISSUES.md`](OPEN-ISSUES.md).

**Canonical location:** `ResearchBar/ResearchBar/` in [Agentic-Assets/ResearchBar](https://github.com/Agentic-Assets/ResearchBar) (CodexBar fork). Moved from `ResearchBar-Concept/` on 2026-06-17. Reorganized into subfolders on 2026-06-18.

## Folder map

| Folder / file | Purpose | Who reads it |
|---|---|---|
| [`researchbar-in-60-seconds.md`](researchbar-in-60-seconds.md) | Elevator pitch | Everyone |
| [`BUILD.md`](BUILD.md) | Builder entry point and read order | Engineers |
| [`RESEARCHBAR-BUILD-REVIEW-2026-06-18.md`](RESEARCHBAR-BUILD-REVIEW-2026-06-18.md) | Deep build review and concrete Track B file plan | Engineers |
| [`OPEN-ISSUES.md`](OPEN-ISSUES.md) | Open decisions, blockers, closed checklist items | Founders + builders |
| [`build/`](build/) | Code-grounded client plan, Corbis dependency contract, and modular Track B native-client guides | Client + Corbis trackers |
| [`concept/`](concept/) | Product north star (why, menu, funnel, fork strategy) | Product + founders |
| [`research/`](research/) | Research archive and verification provenance | Background only |

## Corbis backend (sibling repo)

Full Corbis Track A evaluation (inventory, gap analysis, design review, implementation spec) lives in the **agentic-assets-app** repo:

**Path:** [`../../agentic-assets-app/docs/researchbar-evaluation/`](../../agentic-assets-app/docs/researchbar-evaluation/)

| Corbis doc | What it is |
|---|---|
| [`README.md`](../../agentic-assets-app/docs/researchbar-evaluation/README.md) | Verdict, reading order, scope |
| [`01-inventory-what-exists-today.md`](../../agentic-assets-app/docs/researchbar-evaluation/01-inventory-what-exists-today.md) | File-level map of identity + MCP stack |
| [`02-gap-analysis.md`](../../agentic-assets-app/docs/researchbar-evaluation/02-gap-analysis.md) | Requirement vs exists, effort estimates |
| [`03-design-review.md`](../../agentic-assets-app/docs/researchbar-evaluation/03-design-review.md) | Endorsed decisions and rejected alternatives |
| [`04-revised-corbis-api-contracts.md`](../../agentic-assets-app/docs/researchbar-evaluation/04-revised-corbis-api-contracts.md) | Full aggregate JSON contracts |
| [`05-revised-implementation-plan.md`](../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md) | Corbis phases, files, smoke tests |
| [`06-risks-and-open-questions.md`](../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md) | Closed vs open items with repo evidence |
| [`07-adversarial-review-verdict.md`](../../agentic-assets-app/docs/researchbar-evaluation/07-adversarial-review-verdict.md) | What would fail in production |
| [`08-get-research-pulse-v0-spec.md`](../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md) | Implementation-ready pulse spec |
| [`09-deep-dive-review-and-next-actions.md`](../../agentic-assets-app/docs/researchbar-evaluation/09-deep-dive-review-and-next-actions.md) | Cross-repo deep review and sequence |
| [`_recon/`](../../agentic-assets-app/docs/researchbar-evaluation/_recon/) | Raw agent evidence (audit trail) |

**Relationship:** [`build/`](build/) is the ResearchBar-facing slice of that evaluation plus client guidance. For backend implementation, Corbis `01`–`08` wins on depth; for macOS client work, `build/00`–`02` wins on framing. Where they disagree on facts, both were grounded against code on 2026-06-17 and should agree.

## Track B native client guides

The macOS client plan is split into modular guides so builders can work in
small, reviewable slices:

| Guide | Scope |
|---|---|
| [`build/06-track-b-fixture-pulse-plan.md`](build/06-track-b-fixture-pulse-plan.md) | Fixtures, `ResearchPulse`, decode tests, redaction, menu model |
| [`build/07-track-b-auth-and-cache-plan.md`](build/07-track-b-auth-and-cache-plan.md) | Corbis token, account identity, cache, freshness, GRDB decision |
| [`build/08-track-b-live-mcp-plan.md`](build/08-track-b-live-mcp-plan.md) | JSON-RPC client, smoke tests, error mapping, credit-safe refresh |
| [`build/09-track-b-menu-rendering-plan.md`](build/09-track-b-menu-rendering-plan.md) | Menu states, settings, status icon, descriptor tests |
| [`build/10-track-b-distribution-plan.md`](build/10-track-b-distribution-plan.md) | Product naming, bundle ids, Sparkle, Homebrew, notarization, Tahoe checks |

## Authority (which doc wins)

| Question type | Authoritative source |
|---|---|
| Product intent, competitive gap, GTM | [`concept/2026-06-17-researchbar-concept-and-recommendation.md`](concept/2026-06-17-researchbar-concept-and-recommendation.md) |
| Implementation facts (credits, tools, ORCID, phases) | [`build/`](build/) and Corbis [`researchbar-evaluation/`](../../agentic-assets-app/docs/researchbar-evaluation/) |
| Exact `get_research_pulse` JSON for Swift | [`build/02-mcp-contract-get-research-pulse.md`](build/02-mcp-contract-get-research-pulse.md) + Corbis [`08-get-research-pulse-v0-spec.md`](../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md) |
| Track B native client implementation slices | [`build/06`](build/06-track-b-fixture-pulse-plan.md) through [`build/10`](build/10-track-b-distribution-plan.md) |
| Open blockers and founder decisions | [`OPEN-ISSUES.md`](OPEN-ISSUES.md) |

## Status

Concept exploration plus code-grounded build spec (2026-06-17 audit). **No Swift client or Corbis Phase 0 shipped yet.** Corbis Track A Phase 0 (`get_research_pulse` v0 + ORCID anchor + redaction) blocks a working menu panel.
