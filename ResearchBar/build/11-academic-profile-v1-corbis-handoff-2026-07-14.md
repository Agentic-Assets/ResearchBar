---
title: Corbis academic-profile.v1 handoff for ResearchBar
doc_type: cross-repository-handoff
status: researchbar-implemented-local-verification-complete
as_of: 2026-07-15
owner: Agentic Assets
related:
  - ../RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md
  - https://github.com/Agentic-Assets/agentic-assets-app/blob/f1bcd5431568e98e846fa0ba7e8055b16454706e/goals/2026-07-14-corbis-academic-statistics-goal.md
  - https://github.com/Agentic-Assets/agentic-assets-app/blob/f1bcd5431568e98e846fa0ba7e8055b16454706e/docs/researchbar-evaluation/12-academic-profile-contract-and-reconciliation-2026-07-14.md
---

# Corbis academic-profile.v1 handoff for ResearchBar

## Purpose, scope, and current state

Corbis is the source-aware authority for a user's academic profile. This
document records the current Corbis implementation, the completed native-client
contract work, and the remaining proof boundary before a ResearchBar release.

The source-checked Corbis academic-profile revision is
[`f1bcd5431568e98e846fa0ba7e8055b16454706e`](https://github.com/Agentic-Assets/agentic-assets-app/commit/f1bcd5431568e98e846fa0ba7e8055b16454706e)
(`fix: clarify academic publication types`). It is an ancestor of the locally
recorded `origin/main` commit `df9d8d0d69813ea513b919a7cdc76385c466fd4e`; the
former feature-branch upstream is no longer present locally. This revision
includes the original contract work,
the later compact Settings data tables, DOI-first display selection, match
resolution controls, and the July 15 publication-type clarification. The
earlier `b705cfede` preview was useful deployment evidence for the prior
revision only. It must not be cited as deployment proof for the later
`f1bcd543` UI changes.

Corbis has local authenticated-browser proof for the current Settings surface.
It does **not** have same-time production Corbis API, production Settings UI,
and native ResearchBar proof. Keep local, branch, preview, and production
evidence separate.

The authoritative Corbis explanation is the
[contract and reconciliation guide](https://github.com/Agentic-Assets/agentic-assets-app/blob/f1bcd5431568e98e846fa0ba7e8055b16454706e/docs/researchbar-evaluation/12-academic-profile-contract-and-reconciliation-2026-07-14.md).
The dated Cayman acceptance fixture remains in Corbis. Do not copy personal
profile evidence, live counts, or historical screenshots into ResearchBar
fixtures or public documentation.

## What Corbis now does

### One canonical, source-aware contract

Corbis assembles one authenticated `academic-profile.v1` object. It powers:

1. `GET /api/user/academic-profile` for the authenticated Settings profile.
2. The optional nested `academicProfile` object in the authenticated MCP
   `get_research_pulse` result.

The API is user-scoped and responds `private, no-store`. The MCP projection is
session-scoped and privacy-filtered. ResearchBar has no database access and
must never fetch upstream academic sources or independently reconcile their
records.

| Area | Contract rule |
| --- | --- |
| Identity | The authenticated Settings contract can include public and internal evidence. The MCP projection exposes only `visibility: "public"`; private email evidence cannot enter either client contract. |
| Sources | Source state includes status, observed/attempted/freshness times, coverage, and warnings. |
| Metrics | Each metric has a stable ID, named source, value-or-null, status, timestamps, scope, reason, and source-only coverage. |
| Works | Every source record is retained with a normalized title and `versionFamilyId`. A record is never discarded merely because it appears to duplicate another source. |
| Reconciliation | Confirmed families and review-only proposals are distinct. Exact DOI, manifestation evidence, explicit policy, or an owner decision can confirm a family. Similar titles alone cannot. |
| Aggregation | Works are counted as reconciled version families. Citation and download values are source-specific and are never summed. |

The source-status vocabulary is `current`, `partial`, `historical_only`,
`unavailable`, `unconfigured`, `ambiguous`, `stale`, and `error`. `0` is an
observed zero; `null` is no evidenced value. A client must preserve this
distinction in storage and presentation.

### Source and truth boundaries

| Evidence source | Current Corbis behavior | Required interpretation |
| --- | --- | --- |
| OpenAlex | Public author lookup and cursor-paginated works. Incomplete or malformed pagination becomes `partial`; it never produces a synthetic zero. | Indexed and citation values are source-scoped, not lifetime totals. |
| ORCID | Public record API with a bounded timeout and explicit partial/error handling. | Work summaries are registry evidence, not citation metrics. |
| Google Scholar | Linked profile anchor only; there is no production scraper. | `unconfigured` or unavailable is a truthful result, not zero. |
| SSRN | Existing stored per-user paper evidence only; there is no new production scraper. | Historical/source-specific evidence only. Do not infer current downloads or citations. |

The current public MCP payload may carry public source labels and public work
provenance. That is contract data, not a requirement to expose provider names
in the product. Corbis Settings keeps visible and accessible copy
provider-neutral. ResearchBar should do the same while retaining source,
scope, freshness, and uncertainty in its internal model and safe detail UI.
It must never expose internal author identifiers, private identity evidence,
credentials, or raw internal IDs.

## Current Corbis Settings presentation

The Settings page now presents a compact **Academic Identity** surface rather
than an open-by-default data dump:

- A concise identity and research overview is visible first.
- **Research works**, **Matches to review**, and **Data details** are closed
  disclosures by default.
- The headline label is **Research works**, not "publications" or a lifetime
  total. It shows confirmed reconciliation families and breaks them down by
  classification.
- The Research works table is compact, searchable, sortable, and paginated.
  Its columns are **Publication**, **Type**, **Journal**, and **Year**. Titles
  are DOI-first links; venues are abbreviated with an accessible full-name
  tooltip; alternate manifestations are summarized by a compact version count.
- The current Settings-only derived types are **Journal article**, **Working
  paper**, **DOI-linked research**, and **Other research output**. "Journal
  article" means a non-SSRN journal-article record is present. It is not a
  claim that Corbis has independently verified peer review.
- A mixed published/working-paper family is represented once. A published
  journal manifestation outranks a working-paper manifestation for the
  Settings row. A non-SSRN DOI outranks an SSRN DOI when no journal article is
  identified.
- Unresolved candidates remain in **Matches to review**. The account owner can
  choose **Same work**, **Keep separate**, or undo a decision. Corbis validates
  the proposal membership before persisting an owner-scoped decision; changed
  membership yields `409` rather than a stale merge.

The current local browser check for `f1bcd543` confirmed the four-column
header/body alignment, compact roughly 34px table rows, a keyboard-accessible
type explanation, and no unexpected error dialog. This is local UI proof only.

### Important ResearchBar boundary

The table above is a **Corbis Settings projection**, not a newly serialized
ResearchBar row schema. The current public MCP `academicProfile.works` schema
contains source records, DOI, year, contributors, citations/downloads,
provenance, record and family IDs, plus `workFamilies` and `workProposals`.
It does not currently serialize the Settings-only derived publication type,
preferred display manifestation, abbreviated venue, or prebuilt table row.

Therefore, a future ResearchBar implementation must not recreate the Settings
classification or choose a canonical journal/DOI by guessing. It may display
the contract's raw reconciled families safely, or Corbis must extend the public
contract with an explicitly versioned display projection first. In particular,
do not label an item "Peer reviewed" based only on a DOI, and do not collapse
title-only proposals in the client.

## Corbis runtime and database map

ResearchBar communicates only with authenticated Corbis MCP. The following
locations are for maintainers tracing server behavior, not for client database
access.

| Concern | Authoritative Corbis location |
| --- | --- |
| Drizzle/Supabase Postgres connection | `lib/db/drizzle.ts` |
| Authenticated Settings API | `app/api/user/academic-profile/route.ts` |
| Match-decision API | `app/api/user/academic-profile/matches/route.ts` |
| Contract model and assembly invariants | `lib/research-profile/academic-profile-contract.ts` |
| User-scoped profile assembly | `lib/research-profile/academic-profile-service.ts` |
| Reconciliation algorithm | `lib/research-profile/academic-work-reconciliation.ts` |
| Public Research Pulse projection and redaction | `lib/research-profile/research-pulse.ts` |
| MCP output schema and tool registry | `lib/mcp/tools/output-schemas.ts`, `lib/mcp/tools/registry.ts` |
| Settings evidence/table projections | `components/settings/academic-profile-evidence.tsx`, `components/settings/academic-profile-tables.tsx` |
| Citation trend snapshots | `app/api/cron/citation-snapshot/route.ts` |

| Storage | Purpose and access boundary |
| --- | --- |
| `User` | Profile anchors and verification/linkage state. Anchor migration: `lib/db/migrations/0162_researchbar_profile_anchors.sql`. Server-owned; never query from ResearchBar. |
| `public.user_ssrn_papers` | Legacy per-user SSRN evidence read by `listUserSsrnPapers`. Migration: `lib/db/migrations/0060_user_cv_ssrn_author_linking.sql`. Owner-scoped RLS; historical evidence, not a live SSRN feed. |
| `public.academic_work_match_decisions` | Owner-scoped persisted accept/reject decisions for current proposed matches. Migration: `lib/db/migrations/0187_academic_work_match_decisions.sql`. ResearchBar must not write it. |
| `public.author_link_attempts` | Audit history for author-link decisions. Not client display data. |
| `public.author_citation_snapshots` | Server/cron-only weekly trend data. Migration: `lib/db/migrations/0164_author_citation_snapshots.sql`. It has no client read policies and must not appear in ResearchBar. |

Never transfer connection strings, service credentials, raw profile exports,
internal database IDs, or client-facing author IDs to ResearchBar.

## Compatibility and privacy rules

`get_research_pulse` is session-scoped, requires `read:profile`, accepts no
arguments, and retains older top-level fields during a compatibility window.
Those fields are not alternative truth when `academicProfile` is present:

| Field | Current meaning |
| --- | --- |
| `totalCitations`, `openAlexCitations` | OpenAlex-only compatibility values, never a cross-source total. |
| `hIndex`, `indexedWorksCount`, `trackedPaperCount` | OpenAlex compatibility values. `trackedPaperCount` is deprecated; prefer canonical source-specific metrics in `academicProfile.metrics`. |
| `creditsRemaining`, trends, profile identity | Separate normal pulse data, not academic-profile reconciliation. |

Privacy is enforced twice: Corbis removes internal/private identity evidence and
internal author identifiers from the public projection; a client must still
defensively reject unexpected private evidence or internal identifiers. Do not
apply the old blanket rule that rejects every public source label inside
`academicProfile`; it conflicts with the actual public contract. Conversely,
never render those labels by default simply because the contract contains them.

## ResearchBar implementation

The `fix/researchbar-academic-profile-v1` branch now implements the public
`academic-profile.v1` projection as a parallel research-domain layer. It also
includes the compatible credit, indexed-work, and trend behavior from
`fix/research-pulse-contract-accuracy` at `d5172e9b` without importing that
branch's obsolete closeout artifacts.

| Area | Implemented behavior |
| --- | --- |
| `AcademicProfile.swift` | Typed source, status, identity, metric, public work, family, proposal, and aggregation contracts. Current confirmed-family and proposal bases are distinct, and Settings-only display metadata is not invented in the client. |
| `ResearchPulse.swift` | Decodes the optional profile as authoritative while retaining bounded compatibility for older top-level fields. A malformed or newer nested profile is quarantined instead of silently replaced with legacy totals. |
| `ResearchPulseRedactor.swift` | Allows declared public source provenance only inside the academic subtree while rejecting internal author IDs, private identity fields, credentials, and non-public identity items through both raw and typed scans. |
| `ResearchPulseMenuModel.swift` | Uses compact provider-neutral sections for the research overview, evidence, academic metrics, and data coverage. Status, record count, freshness, and incomplete coverage remain visible without exposing backend plumbing. |
| Fixtures and tests | Cover current contract decoding, zero-versus-null semantics, every current reconciliation basis, forward-incompatible quarantine, nested privacy leaks, cache redaction, menu uncertainty, and the compatibility matrix from the pulse-accuracy branch. |

The visible menu deliberately summarizes reconciled research works and matches
to review without recreating the richer Corbis Settings table or guessing a
canonical publication. Public provider provenance remains available to the
typed model, but default labels use stable ordinal evidence names. When a
future Corbis contract cannot be decoded safely, ResearchBar asks for an update
and hides legacy academic totals.

The client and contract guides now agree on this boundary. Public source names
are valid academic provenance; internal IDs, private identity evidence, and
credentials are never valid client data.

## Verification snapshot and proof boundaries

The following verification was recorded for the current Corbis UI commit
`f1bcd543`:

```text
Academic-profile evidence unit suite: 23 passed
Academic-profile focused suite: 10 files, 74 passed
Full Vitest: 590 files passed, 2 skipped; 10,178 passed, 3 skipped
pnpm type-check: passed
pnpm lint: passed (one pre-existing React Compiler warning)
pnpm exec next build --webpack: passed
```

These are local branch verification results, not production proof. Earlier
contract closeout records remain useful historical evidence, but their counts
and implementation commit are not the current UI verification snapshot.

The ResearchBar branch has the following current local proof:

```text
Focused Research Pulse and MCP suite: 6 suites, 88 passed
Fresh Swift compile: passed as part of the focused suite
make check: passed (format, strict lint, parser, package-path, sharding, and locale gates)
make test: passed (41 shards, 488 test selections)
Release package: passed with ad-hoc signing; bundle was not launched
Keychain and live-provider probes: not run by design
```

An adversarial finder-and-skeptic review confirmed six issues and all six were
fixed before the final gates: public-schema display-field drift, an incomplete
output-schema guide, semantic privacy-key variants, inconsistent sparse-source
ordinals, missing metric context, and shallow reconciliation fixtures. Earlier
concerns about reconciliation enums, newer-contract quarantine, default provider
labels, pulse-accuracy compatibility, and client-side reconciliation were
refuted against the final code and tests.

The fixture-first verification surfaces are:

- Corbis: `tests/unit/lib/research-profile/academic-profile-contract.test.ts`,
  `academic-profile-service.test.ts`, `academic-work-reconciliation.test.ts`,
  `research-pulse.test.ts`,
  `tests/unit/app/api/user/academic-profile-route.test.ts`,
  `tests/unit/app/api/user/academic-profile-matches-route.test.ts`, and
  `tests/unit/components/settings/academic-profile-evidence.test.tsx`.
- ResearchBar: `ResearchPulseDecodingTests.swift`, `ResearchPulseRedactorTests.swift`,
  `CorbisMCPClientTests.swift`, `ResearchPulseMenuModelTests.swift`, and
  `ResearchPulseMenuFactoryTests.swift`.

The governing rule remains: Corbis supplies reconciled, source-aware evidence;
ResearchBar may present it, but it must preserve source, scope, freshness, and
uncertainty. It must never silently convert incomplete evidence into a total,
missing evidence into zero, or an unreviewed possible match into one work.
