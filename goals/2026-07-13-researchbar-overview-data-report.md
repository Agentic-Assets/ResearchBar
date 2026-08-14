# Why the ResearchBar Overview looks thin — findings report, 2026-07-13

Question from the operator: is the sparse Overview panel caused by an unfinished
product, or by weak per-user data in Corbis?

Answer: both contribute, but in a specific, now-verified way. The client is
essentially done for its v0 scope and renders every field the server sends.
The server payload is thin for three separate reasons: the account is linked
to the wrong (thinnest) OpenAlex identity fragment, the v0 schema is
deliberately minimal, and two real bugs (credits display, silent stale cache)
make it look worse than it is. Evidence below; the companion to-do list is
`2026-07-13-researchbar-overview-improvement-todo.md`.

## 1. The headline numbers are an identity artifact, not your real record

The menu shows Citations: 4, h-index: 1, Tracked papers: 3. Those three
numbers are an exact match for OpenAlex author fragment `A5116866548` — one of
**eleven** unmerged OpenAlex author IDs for "Cayman Seagraves". The linked
fragment is not the canonical record:

| Source | Works | Citations | h-index |
| --- | --- | --- | --- |
| Fragment Corbis linked (`A5116866548`) | 3 | 4 | 1 |
| Canonical ORCID-linked OpenAlex (`A5090973432`, ORCID `0000-0002-6124-7440`) | 11 | 12 | 2 |
| All 11 fragments merged (deduplicated) | ~24 | ~17 | ~3 |
| Verified Google Scholar (`scholar.google.com/citations?user=j1wfmPYAAAAJ`) | — | **31** | **3** |

Google Scholar is ~8x the displayed citation count because it merges
working-paper and published versions (e.g. "Guilty by Political Association":
9 there vs 3+1 split across OpenAlex fragments). On top of that, 10–15 SSRN
working papers (2024–2026, the dominant channel for early-career finance
output) carry download traction but essentially no formal citations yet, and
SSRN is not integrated into Corbis at all.

Why the wrong link happened: the backend auto-link
(`agentic-assets-app/lib/research-profile/openalexlinking.ts`) searches
OpenAlex **by name only** and scores candidates mostly on name similarity
(auto-accepts at score ≥90). With eleven same-name fragments, it latched onto
a thin one. The payload confirms the gap: `orcid: null`,
`googleScholarId: null`, `googleScholarUrl: null` in the cached response, even
though the real ORCID and Scholar profile exist and are public.

Also mislabeled: "Tracked papers" is not "papers you chose to track". The
backend sets it to raw OpenAlex `works_count` for the linked author ID
(`lib/research-profile/research-pulse.ts:283`). There is no user-facing
paper-tracking concept in v0 at all.

## 2. The client is rendering everything it receives

The full v0 wire schema (`get_research_pulse`, JSON-RPC to
`https://www.corbis.ai/api/mcp/universal`) is one flat object:
identity fields, plan/credits, three citation numbers, trend deltas +
sparkline (nullable), low-confidence flags, profile links, freshness stamps.
No papers array, no radar, no discovery — by design ("Do not orchestrate
low-level paper/citation MCP tools from ResearchBar yet",
`RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md`).

The renderer (`Sources/CodexBar/ResearchBar/ResearchPulseMenuModel.swift`)
shows every non-nil field and correctly withholds nil ones. The rich test
fixture (`Tests/CodexBarTests/Fixtures/ResearchBar/pulse-linked-tracked.json`)
proves the client already draws ORCID + Scholar links, 7-day and 52-week
citation deltas, and a 52-point block-glyph sparkline the moment the server
populates them. Everything visible in the fixture but missing live is a data
gap, not a rendering gap.

The trend line "Citation history is accruing" is the designed `tracking`
state: the weekly snapshot cron (`app/api/cron/citation-snapshot/route.ts`,
Mondays 05:00 UTC) has recorded one snapshot for the linked author; deltas and
the sparkline unlock at two or more. This will self-resolve — but it will
accrue history for the **wrong author fragment** until the identity link is
fixed.

## 3. Two real bugs make it look worse

**"Credits: 0" is a display bug, not an empty balance.** The enterprise tier
is unlimited (`monthlyCredits: -1`, stored internally as `creditsRemaining:
null` — `lib/stripe/check-subscription.ts:164-166`). The pulse assembler then
coerces null to 0 (`coerceNumber(usage.creditsRemaining, DEFAULT_CREDITS)`
with `DEFAULT_CREDITS = 0`, `lib/research-profile/research-pulse.ts:61,277`),
so "unlimited" reaches the menu as the number 0. The backend's own smoke log
(`_recon/2026-06-26-live-smoke.md` §A2) already recorded this symptom. The
client compounds it: `creditsRemaining` is a non-optional Double rendered as a
bare number with no "Unlimited" affordance for non-metered plans.

**The panel is frozen at 6/29 and cannot tell you why.** The cached payload
(`~/Library/Application Support/ResearchBar/pulse-cache/…json`) was fetched
2026-06-29 05:21 UTC and went stale six hours later (`staleAfter` is
server-set, +6h). There is deliberately no background refresh timer in v0
(credit conservation); refresh happens only at menu open or ⌥⌘R. The failure
path is the problem: any refresh error except explicit credit-limit or
invalid-credential is silently collapsed into the identical "Cached: updated…"
display with zero diagnostics
(`ResearchPulseRefreshCoordinator.swift:150-166`). Meanwhile the app's other
data sources refresh fine (the Codex/Claude widget snapshot updated tonight,
23:47), and this machine's Corbis MCP plugin token independently returned
"token expired" today — the most likely story is an expired Corbis credential
with every menu-open refresh failing silently for two weeks. The UI cannot
distinguish "never tried" from "failing every time"; that is a genuine client
observability gap.

## 4. What is genuinely unbuilt (and correctly so, per the roadmap)

Track B slices 06–09 (model, redaction, keychain + account-keyed cache, live
MCP client, all 11 menu states) are implemented and test-covered. Absent
features are explicitly future phases, mostly gated on Corbis backend work:

- Phase 1: data-freshness panel (`get_data_freshness` is live server-side;
  zero client code), notifications on citation deltas, real trend rows (client
  code done, waiting on snapshot history).
- Phase 2: new-work radar ("who cites you" — blocked on a missing forward-
  citation primitive server-side), linked repos + local git scanner.
- Phase 3: conference deadlines (blocked on a founder decision about a
  maintained dataset).
- Never scoped for ResearchBar: paper discovery, opportunity map, literature
  positioning (those are Corbis chat/agent tools, not menu-bar features).

One acknowledged in-between gap: the identity-confirmation handshake
(`find_academic_identity` / `confirm_academic_identity`) is fully working on
the backend but the client UI is scaffold-only — "Confirm identity" routes to
the plain token Settings pane. So the single most important fix (re-linking to
the right author record) currently cannot be done from inside the app; it
requires the Corbis web app or a direct MCP call.

## 5. Bottom line

- Roughly 70% data problem: wrong/thin OpenAlex identity fragment, no
  ORCID/Scholar anchors stored, OpenAlex's structural blindness to
  SSRN-heavy finance output, and one-snapshot trend history.
- Roughly 30% product problem: the silent stale-cache failure path, the
  missing in-app identity fix flow, the credits null→0 coercion, and the
  misleading "Tracked papers" label. The rest of the sparseness is the
  intended v0 scope.
- Your real public record (31 Scholar citations, h-index 3, ~24 works,
  10–15 active SSRN papers) is materially better than what the panel shows.
  The single highest-leverage fix is re-linking the Corbis identity to ORCID
  `0000-0002-6124-7440` / OpenAlex `A5090973432` (or the Scholar profile) —
  everything downstream (pulse numbers, snapshots, future radar) keys off
  that link.

## Evidence trail

- Cached live payload decoded from
  `~/Library/Application Support/ResearchBar/pulse-cache/e175976…json`
  (fetched 2026-06-29T05:21Z; all identity anchors null; deltas/sparkline
  null; `profileStatus: linked_researcher`; `creditsRemaining: 0`).
- Backend implementation read at
  `agentic-assets-app/lib/research-profile/research-pulse.ts`,
  `author-candidate-service.ts`, `openalex-linking.ts`,
  `lib/stripe/usage.ts`, `lib/mcp/tier-resolver.ts`,
  `app/api/cron/citation-snapshot/route.ts`.
- Client implementation read at `Sources/CodexBarCore/ResearchBar/*` and
  `Sources/CodexBar/ResearchBar/*` (coordinator failure mapping at
  `ResearchPulseRefreshCoordinator.swift:150-166`).
- Public record verified against the OpenAlex API (11 author fragments
  enumerated), the live ORCID API, Google Scholar search indexing, and SSRN
  (author page `per_id=3111316`).
- Corbis MCP token-expired error reproduced from this machine 2026-07-13.
