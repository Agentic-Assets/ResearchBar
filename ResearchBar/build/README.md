# Build plan (code-grounded)

Date: 2026-06-17 (audit); folder renamed from `corbis-integration-plan/` to `build/` on 2026-06-18.

Verified, code-grounded plan for the Corbis backend ResearchBar depends on, plus client-side guidance. Start at [`../BUILD.md`](../BUILD.md) or **`00-what-this-means-for-researchbar.md`**.

## Corbis evaluation (full backend spec)

This folder is the **ResearchBar-facing slice**. The full Corbis Track A evaluation lives in the sibling repo:

**[`../../../agentic-assets-app/docs/researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/)**

| File | Use when |
|---|---|
| [`README.md`](../../../agentic-assets-app/docs/researchbar-evaluation/README.md) | Verdict and index |
| [`01-inventory-what-exists-today.md`](../../../agentic-assets-app/docs/researchbar-evaluation/01-inventory-what-exists-today.md) | What exists in Corbis today |
| [`02-gap-analysis.md`](../../../agentic-assets-app/docs/researchbar-evaluation/02-gap-analysis.md) | Gaps and effort estimates |
| [`03-design-review.md`](../../../agentic-assets-app/docs/researchbar-evaluation/03-design-review.md) | Design critique + rejected alternatives |
| [`04-revised-corbis-api-contracts.md`](../../../agentic-assets-app/docs/researchbar-evaluation/04-revised-corbis-api-contracts.md) | All aggregate JSON shapes |
| [`05-revised-implementation-plan.md`](../../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md) | **Implement Corbis phases here** |
| [`06-risks-and-open-questions.md`](../../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md) | Closed vs open with evidence |
| [`07-adversarial-review-verdict.md`](../../../agentic-assets-app/docs/researchbar-evaluation/07-adversarial-review-verdict.md) | What would fail in production |
| [`08-get-research-pulse-v0-spec.md`](../../../agentic-assets-app/docs/researchbar-evaluation/08-get-research-pulse-v0-spec.md) | **Implementation-ready pulse spec** |
| [`09-deep-dive-review-and-next-actions.md`](../../../agentic-assets-app/docs/researchbar-evaluation/09-deep-dive-review-and-next-actions.md) | Deep review and cross-repo sequence |
| [`_recon/`](../../../agentic-assets-app/docs/researchbar-evaluation/_recon/) | Raw agent evidence (audit only) |

Open blockers tracked in [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md).

## Citation convention

Every `path:line` reference in this folder points into **`../../../agentic-assets-app`**, not this repository. Doc-name paths (for example `corbis-api-contracts.md`) refer to [`../concept/`](../concept/).

## One-paragraph verdict: BUILD WITH CHANGES

Centralize in Corbis, thin macOS client, ORCID anchor, one panel = one aggregate MCP call. The client is blocked on `get_research_pulse` v0 plus ORCID anchor and redaction (Corbis Phase 0). Build Corbis Track A first, render second.

## Corrected facts

| Was (concept) | Is (code) | Client impact |
|---|---|---|
| 24 MCP tools | **30** | Inventory only |
| 1 credit/call | **0.5** | ~100 lifetime aggregate calls on free tier |
| ORCID-first "in progress" | **Unstarted** | Net-new backend work |
| 5 enterprise-only tools | **10** | Count only; identity tools still tier1 |
| 10 concurrent enforced | **Docs only** | Honor 200/hour |

Never-surface is **violated in shipped MCP output** today; Phase 0.B fixes the source. Client redacts defensively ([`00`](00-what-this-means-for-researchbar.md)).

## Reading order (this folder)

1. [`00-what-this-means-for-researchbar.md`](00-what-this-means-for-researchbar.md)
2. [`01-corbis-vs-researchbar-boundary.md`](01-corbis-vs-researchbar-boundary.md)
3. [`02-mcp-contract-get-research-pulse.md`](02-mcp-contract-get-research-pulse.md)
4. [`03-corbis-track-a-plan.md`](03-corbis-track-a-plan.md)
5. [`04-corrections-and-sync-back.md`](04-corrections-and-sync-back.md) — audit errata (applied to `concept/` 2026-06-18)
6. [`05-risks-and-open-questions.md`](05-risks-and-open-questions.md)

## Authority

This folder wins over [`../concept/`](../concept/) on implementation facts. Corbis [`researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/) wins on backend implementation depth (file-level plans, Zod schemas, test lists).
