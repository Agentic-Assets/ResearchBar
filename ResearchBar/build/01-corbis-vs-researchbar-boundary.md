# 01. Corbis vs ResearchBar boundary (corrected)

The ownership split, reconciled against the Corbis code. The concept's split ([`../concept/identity-and-data-consolidation.md`](../concept/identity-and-data-consolidation.md), [`../concept/corbis-api-contracts.md`](../concept/corbis-api-contracts.md)) is largely correct and endorsed. This file corrects two things the concept got optimistic about and adds the client obligations that fall out of the corrected facts. All `path:line` references point into the sibling Corbis repo `agentic-assets-app`.

## Ownership table

| Capability | Corbis (`agentic-assets-app`) | ResearchBar (this repo) |
|---|---|---|
| `get_research_pulse` | **Build (Phase 0)**. Aggregate, ORCID-anchored, redacted, trend fields null until snapshots accrue. | Call once per refresh and render. Handle null trend fields. |
| `get_data_freshness` | Build (Phase 1). "Data through" dates only in v0; no forward "next release" (no backing table). | Call and render. Cacheable, so cache aggressively client-side too. |
| `get_new_work_radar` | Build (Phase 2). Per-user, session-aware, fail-closed under org-forced ZDR. | Call and render. |
| `get_conference_deadlines` | Build (Phase 3, founder decision on dataset). Curated seed plus per-user overrides. | Call and render; thin "add a deadline" UI feeds the override. |
| Identity find/confirm | Build and extend to ORCID-first (net-new; see correction 1 below). | Thin confirm UI over the existing tools. Display ORCID only. |
| Citation deltas and sparkline | Build (Phase 1): snapshot table plus weekly cron. The math is server-side. | **Never compute.** Render the server's values; show "tracking will begin" until `tracked`. |
| Paper-to-repo associations and remote GitHub metadata | Build (Phase 2): `get_linked_repos` or a nested block; serve CI status, stars, default branch when an account is linked. | **Local git only**: scan clone paths, compute ahead/behind/dirty, merge onto Corbis repo records at render time. |
| Agent catalog metadata | Optional later (`get_agent_catalog`), only if corbis.ai web needs it in-browser. | **v1 default**: read the local Corbis plugin install (`plugin.json`, skill paths). |
| Agent launch (Claude Code) | Not server-side. | Build (subprocess). |
| Menu shell, Sparkle, notifications | Not applicable. | Build (CodexBar fork). |
| Response freshness and cache | Sets `staleAfter` and `etag` on every response. | GRDB cache, **keyed by Corbis account**, respecting server cadence. |

## Two corrections to the concept's split

### Correction 1: "Identity find/confirm: extend for ORCID-first" is net-new, not an extension

The concept frames ORCID-first confirm as extending existing tools. The code shows there is nothing to extend yet: there is no `orcid` column anywhere (`lib/db/schema.ts`), and `confirm_academic_identity` requires the internal author id from the caller (`lib/ai/tools/confirm-academic-identity.ts:25-42`, regex `/^A\d+$/i`). Corbis must add an `orcid` column, an ORCID-to-internal resolver, and an ORCID accept path before the client can "confirm by ORCID." For the client this means: the confirm UI stays thin, but it cannot be built against an ORCID accept contract until Corbis Phase 0.A lands. Until then the confirm UI either waits or temporarily round-trips the internal id (which contradicts the never-surface rule, so prefer to wait).

### Correction 2: the never-surface rule is a Corbis backend cleanup, not a property the client inherits

The concept treats "the client never sees backend names or internal ids" as something the thin client gets for free. It does not. Today's Corbis MCP payloads carry the internal id and the backend name (`output-schemas.ts:22`, `business-logic.ts:197-200`, `result-format.ts:97`, `confirm-academic-identity.ts:103`, `registry.ts:539,547`). A thin client rendering them as-is would display exactly what the rule forbids. Corbis Phase 0.B fixes the source; the client redacts defensively as a second layer (see `00`, reality 3).

## ResearchBar client allowlist (corrected)

ResearchBar MAY contain:

- CodexBar shell (`NSStatusItem`, menus, settings, Sparkle, Homebrew).
- Existing CodexBar AI provider usage infrastructure as inherited machinery,
  diagnostics, or a small optional panel while the fork remains upstreamable.
- Corbis auth (OAuth bearer or `corbis_mcp_...` key in Keychain).
- Thin onboarding UI (confirm or cancel over the identity tools), displaying ORCID only.
- A generic panel renderer for aggregate JSON, with explicit handling for null trend fields and the `citationHistoryStatus` enum.
- A polling timer plus a GRDB response cache, keyed by Corbis account, that respects `staleAfter` and `etag` and makes at most one aggregate call per refresh.
- `UNUserNotificationCenter` on server-flagged deltas (Phase 1, once deltas are real).
- Agent subprocess launch (Claude Code).
- A local git clone scanner merged onto Corbis repo records.
- A v1 agent catalog read from the local plugin install.

ResearchBar MUST NOT contain:

- Generic AI quota monitoring as the primary product surface.
- Source adapters, scrapers, or reconcilers.
- Multi-tool MCP orchestration for a menu panel (one aggregate call per panel).
- Citation delta or sparkline computation (server-side only).
- Deadline curation or storage (server-side only; the client only feeds per-user overrides).
- Subfield preset definitions (server-side presets).
- External URL discovery or construction (Corbis resolves every `url`).
- Paper-to-repo association persistence (Corbis owns it; the client merges local git state only).
- Any rendered string that exposes an internal id (`^A\d+$`) or a backend source name. If one appears, treat it as a leak bug, not display data.

## Why centralize in Corbis (unchanged, and confirmed by the code)

The concept's reasons hold ([`../concept/identity-and-data-consolidation.md`](../concept/identity-and-data-consolidation.md)): one service serves ResearchBar, corbis.ai web, and EQUIRE; reconciliation rules improve everywhere at once; ToS-sensitive sources stay behind one audited boundary; billing and routing tune without a client update; and the user experiences "Corbis told me," not "this app scraped six sites." The VISION guardrail to honor: the universal MCP endpoint stays client-agnostic, so the aggregates must not take ResearchBar-specific shaping. Keep the contract reusable by web and EQUIRE.
