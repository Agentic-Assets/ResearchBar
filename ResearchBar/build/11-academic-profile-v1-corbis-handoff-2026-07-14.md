---
title: Corbis academic-profile.v1 handoff for ResearchBar
doc_type: cross-repository-handoff
status: corbis-implemented-researchbar-prototype-paused
as_of: 2026-07-14
owner: Agentic Assets
related:
  - ../../agentic-assets-app/goals/2026-07-14-corbis-academic-statistics-goal.md
  - ../../agentic-assets-app/docs/researchbar-evaluation/12-academic-profile-contract-and-reconciliation-2026-07-14.md
  - ./RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md
---

# Corbis academic-profile.v1 handoff for ResearchBar

## Purpose and current state

Corbis is now the source-aware authority for a user's academic profile. This
document records what is complete in Corbis, what was started in ResearchBar,
and the exact work still required before a native client release can claim to
render the new academic statistics correctly.

This is a handoff, not a release record. The Corbis implementation is on
`fix/research-pulse-data-accuracy` at `b705cfede2c8a193e7cc0dfa4df1e04f7abb5e18`
(the academic-profile implementation commit is `25176491e88a2a0d47b1201223339be8adcee8f9`).
Its Vercel preview completed successfully, but authenticated Settings-page and
native-client live proof remain open. Do not treat this document, a preview,
or local tests as production proof.

The authoritative Corbis explanation is
[`12-academic-profile-contract-and-reconciliation-2026-07-14.md`](../../agentic-assets-app/docs/researchbar-evaluation/12-academic-profile-contract-and-reconciliation-2026-07-14.md).
The dated acceptance fixture is intentionally kept in the Corbis repository;
do not copy personal profile evidence or dated values into ResearchBar fixtures
or public documentation.

## What Corbis now does

### One canonical contract

Corbis assembles a single `academic-profile.v1` object and uses it in both
places:

1. The authenticated Settings profile API: `GET /api/user/academic-profile`.
2. The authenticated MCP `get_research_pulse` result as the optional nested
   `academicProfile` field.

The public MCP projection removes internal identity evidence and OpenAlex
author identifiers. It intentionally retains public source names and public
work-record provenance so a client can accurately label evidence. ResearchBar
must never independently merge values from sources or recreate reconciliation.

The contract contains:

| Area | Fields and rules |
| --- | --- |
| Identity | Public evidence only, each with source, status, timestamps, provenance, visibility, and a nullable value. Private email evidence is not public contract data. |
| Sources | OpenAlex, ORCID, Google Scholar, and SSRN state with source label, status, observation/attempt/freshness timestamps, coverage, and warnings. |
| Metrics | Stable metric ID, source, value-or-null, status, observation/attempt/freshness timestamps, scope, reason, and source-only coverage. |
| Works | Preserved source records plus DOI, contributors, source record IDs, normalized title, and version-family ID. |
| Reconciliation | Confirmed families and review-only proposals. Exact DOI/manual version policy may confirm a family; title similarity alone never silently merges records. |
| Aggregation | Works may use reconciled version families. Citations and downloads are always source-specific and are never summed. |

The source status vocabulary is `current`, `partial`, `historical_only`,
`unavailable`, `unconfigured`, `ambiguous`, `stale`, and `error`. `0` is a real
observed value; `null` means no value was evidenced. A client must preserve
that distinction in storage and UI.

### Acquisition and truth boundaries

| Source | Current Corbis behavior | Client implication |
| --- | --- | --- |
| OpenAlex | Uses a public author lookup and cursor-paginated works. Incomplete or malformed pagination becomes `partial`, never a fabricated zero. | Label every metric as OpenAlex-specific. Do not call it a complete publication or citation total. |
| ORCID | Uses the public record API with a bounded timeout and explicit partial/error behavior. | ORCID work summaries are registry evidence, not citation metrics. |
| Google Scholar | Stores a linked-profile anchor only. There is no production scraper. | An `unconfigured`/unavailable state is truthful and must stay visible. |
| SSRN | Reads the user's existing stored SSRN evidence only. There is no new production scraper. | Treat it as historical/source-specific evidence; do not infer current downloads or citations. |

## Corbis runtime and database map

ResearchBar has no database access. It communicates only with Corbis MCP using
an authenticated personal MCP key. The following locations are for maintainers
who need to trace or verify the server behavior.

### Server, auth, and API boundaries

| Concern | Authoritative Corbis location |
| --- | --- |
| Drizzle/Supabase Postgres connection | `lib/db/drizzle.ts` |
| Settings API, user scope, `private, no-store` response | `app/api/user/academic-profile/route.ts` |
| Contract model and assembly invariants | `lib/research-profile/academic-profile-contract.ts` |
| User-scoped profile assembly | `lib/research-profile/academic-profile-service.ts` |
| OpenAlex adapter and cursor pagination | `lib/research-profile/openalex-profile-evidence.ts` |
| ORCID adapter | `lib/research-profile/orcid-enrichment.ts` |
| Reconciliation algorithm | `lib/research-profile/academic-work-reconciliation.ts` |
| Research Pulse public projection | `lib/research-profile/research-pulse.ts` |
| MCP registry and output schema | `lib/mcp/tools/registry.ts`, `lib/mcp/tools/output-schemas.ts` |
| Cron citation snapshots | `app/api/cron/citation-snapshot/route.ts` |

The Settings route takes identity from the authenticated server session; it does
not accept an arbitrary user or author ID. The `get_research_pulse` MCP tool is
also session-scoped (`read:profile`) and is deliberately not globally cached.

### Persistent data involved

| Storage | Purpose | Privacy/access note |
| --- | --- | --- |
| `User` in `lib/db/schema.ts` | Stores profile anchors, including ORCID, OpenAlex/Scholar linkage, confidence/verification state, and profile identity fields. Anchor migration: `lib/db/migrations/0162_researchbar_profile_anchors.sql`. | Server-owned profile data; never query it from ResearchBar. |
| `public.user_ssrn_papers` | Legacy per-user SSRN paper evidence queried by `listUserSsrnPapers` in `lib/db/queries-research-profile.ts`. Migration: `0060_user_cv_ssrn_author_linking.sql`. | Owner-scoped RLS. This is historical evidence, not a live SSRN feed. |
| `public.author_link_attempts` | Audit history for author-link decisions. | Owner SELECT/INSERT policies; not client display data. |
| `public.author_citation_snapshots` | Weekly trend calculations: normalized author ID, cited-by/works data, week, and capture time. Migration: `0164_author_citation_snapshots.sql`; queries: `lib/db/queries-citation-snapshots.ts`. | No JWT read policies. It is server/cron-only trend data and must not appear in ResearchBar. |

The cron route uses a server-side secret and bounded concurrency. It logs
aggregates rather than author identifiers. Do not transfer connection strings,
service credentials, database IDs, or raw profile exports to the client.

## Compatibility fields and the required migration path

`get_research_pulse` keeps older top-level fields for a compatibility window.
They are not an alternative source of truth when `academicProfile` is present:

| Older field | Meaning after academic-profile.v1 |
| --- | --- |
| `totalCitations` / `openAlexCitations` | OpenAlex-only compatibility aliases, never a cross-source total. |
| `hIndex`, `trackedPaperCount` | Legacy compatibility values. The canonical source-specific metrics are under `academicProfile.metrics`. |
| `creditsRemaining`, trends, profile identity | Still normal pulse data. They are separate from academic reconciliation. |

Safe rollout order:

1. ResearchBar decodes and renders `academicProfile` correctly.
2. Native-client tests and a real MCP fixture prove the contract path.
3. A compatible client is released.
4. Only then can Corbis consider retiring legacy academic aliases.

## ResearchBar prototype currently kept in this worktree

The current `fix/researchbar-academic-profile-v1` worktree intentionally keeps
an **uncommitted, paused prototype**. It is not ready to merge, release, or
push as product code. It was retained at the request of the project owner so a
future implementation can resume from the explored design.

Prototype changes presently present:

| File | Started change |
| --- | --- |
| `Sources/CodexBarCore/ResearchBar/AcademicProfile.swift` | New typed models/enums for the public contract, including source/status types, metrics, records, reconciliation families/proposals, and aggregation policy. |
| `Sources/CodexBarCore/ResearchBar/ResearchPulse.swift` | Adds optional `academicProfile`, preserving legacy pulse compatibility. |
| `Sources/CodexBarCore/ResearchBar/ResearchPulseRedactor.swift` | Starts a JSON-path-aware raw scan that permits declared source names inside `academicProfile` while retaining internal-author-ID checks. |
| `Sources/CodexBarCore/ResearchBar/ResearchPulseMenuModel.swift` | Starts source-aware menu sections for academic evidence, source-specific metrics, and coverage. |
| `Tests/CodexBarTests/Fixtures/ResearchBar/pulse-academic-profile-v1.json` and related tests | Adds a representative contract fixture and red/green coverage for source labels, round-tripping, and menu display. |

The prototype proved three important facts:

- The former whole-payload redaction rule rejected a valid contract merely
  because it contained public `OpenAlex` and `SSRN` provenance.
- The previous `ResearchPulse` decoder silently discarded `academicProfile`.
- The native menu previously showed only legacy top-level values and omitted
  nested source labels, statuses, timestamps, coverage, exact nulls, and
  reconciliation details.

The focused source-label, contract-round-trip, and source-aware-menu tests
were observed passing at their respective red/green checkpoints. The final
prototype state has a deliberately failing privacy test for an email placed in
nested academic identity evidence. Consequently, **do not commit or release
the prototype without completing the next section and running the full client
verification suite.**

## Work still required in ResearchBar

1. Complete the field-aware privacy gate.
   - Permit only the declared public provenance vocabulary inside the typed
     academic-profile subtree.
   - Reject private/internal identity visibility, email values, credentials,
     internal OpenAlex author IDs/URLs, and forbidden raw keys such as
     `authorId`, `openalexAuthorId`, `openalexId`, and `sourceId`.
   - Handle a tool-level `status: "error"` before successful-payload scanning
     so its message is sanitized by `CorbisMCPError`, not misclassified.
2. Finish strict contract validation.
   - Keep `academicProfile` optional/nullable for legacy responses.
   - Fail closed for an unsupported contract version, unknown closed enum,
     malformed timestamp, or invalid reconciliation shape.
   - Retain all public nested values for cache round trips, while rendering
     only locally-derived labels and safe summaries.
3. Complete the menu and factory tests.
   - Show each configured source's status, observation/attempt date, and
     coverage.
   - Render exact zero as `0`; render `null` explicitly as unavailable with
     its source status.
   - Use source-specific metric rows; do not create citations/download totals.
   - Keep compact menus free of raw work IDs, provenance text, private identity
     evidence, and arbitrary server-supplied strings.
4. Add client transport tests.
   - A valid `academic-profile.v1` MCP envelope must reach the menu model.
   - Negative fixtures must cover private evidence, author IDs, unknown fields,
     stale/error/unconfigured sources, tool-level errors, and legacy/null
     `academicProfile` responses.
5. Update stale client guidance.
   - `RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md` and
     `build/02-mcp-contract-get-research-pulse.md` still describe all backend
     source names as forbidden. They must distinguish public contract source
     labels from internal/private leakage.
6. Verify before release.
   - Run focused Swift tests, `make test`, `make check`, and a freshly built
     bundle test through `./Scripts/compile_and_run.sh` only when an
     authenticated, user-approved MCP session is available.
   - Record same-time Corbis Settings/API and native menu proof. A protected
     Vercel preview alone is insufficient.

## Corbis verification already recorded

The Corbis branch has recorded the following local verification for the
academic-profile extension:

```text
Focused profile/contract tests: 22 files, 204 passing
MCP consolidation Playwright project: 143 passing
Full Vitest: 588 files passed, 2 skipped; 10,140 tests passed, 3 skipped
Type-check, lint, AI SDK verification, MCP docs check, and offline smoke: passed
Next.js webpack production build: passed
```

Consult the Corbis closeout and goal for precise commands and proof boundaries:

- `tasks/2026-07-14-research-pulse-data-accuracy/closeout-log.md`
- `tasks/2026-07-14-research-pulse-data-accuracy/forward-queue.md`
- `goals/2026-07-14-corbis-academic-statistics-goal.md`

## Tests and docs to use when resuming

In Corbis:

- `tests/unit/lib/research-profile/academic-profile-contract.test.ts`
- `tests/unit/lib/research-profile/academic-profile-service.test.ts`
- `tests/unit/lib/research-profile/academic-work-reconciliation.test.ts`
- `tests/unit/lib/research-profile/openalex-profile-evidence.test.ts`
- `tests/unit/lib/research-profile/orcid-enrichment.test.ts`
- `tests/unit/app/api/user/academic-profile-route.test.ts`
- `tests/unit/lib/research-profile/research-pulse.test.ts`
- `tests/unit/lib/mcp/mcp-consolidation.test.ts`
- `tests/unit/components/settings/academic-profile-evidence.test.tsx`

In ResearchBar, build fixture-first from:

- `Tests/CodexBarTests/ResearchPulseDecodingTests.swift`
- `Tests/CodexBarTests/ResearchPulseRedactorTests.swift`
- `Tests/CodexBarTests/CorbisMCPClientTests.swift`
- `Tests/CodexBarTests/ResearchPulseMenuModelTests.swift`
- `Tests/CodexBarTests/ResearchPulseMenuFactoryTests.swift`
- `ResearchBar/RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`

The governing principle is simple: Corbis supplies the reconciled,
source-aware truth. ResearchBar displays that truth with its source, scope,
freshness, and uncertainty intact. It must never silently turn incomplete
evidence into a total or missing evidence into zero.
