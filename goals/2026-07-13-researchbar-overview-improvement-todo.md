# ResearchBar Overview improvement to-do, 2026-07-13

Recommended order of attack, from the findings in
`2026-07-13-researchbar-overview-data-report.md`. Items are grouped by where
the work lives. Effort tags: S (< half day), M (1–2 days), L (multi-day or
founder-gated).

## A. Do first — biggest visible wins, no new features

1. **Re-link the Corbis academic identity to the canonical record.** (S,
   operator + Corbis web app) Run `find_academic_identity` /
   `confirm_academic_identity` anchored on ORCID `0000-0002-6124-7440`
   (canonical OpenAlex author `A5090973432`: 11 works / 12 citations / h=2,
   vs the currently linked fragment's 3 / 4 / 1). Verify
   `User.openalexAuthorId` and `authorLinkVerified` in Supabase afterwards.
   Everything downstream (pulse numbers, weekly snapshots, future radar) keys
   off this link, and snapshot history is currently accruing for the wrong
   fragment.

2. **Fix the refresh/staleness path end to end.** (M, client)
   - Re-authenticate the app's Corbis credential (the cache has been frozen
     since 6/29; this machine's Corbis MCP token independently reports
     expired — same likely cause).
   - Stop collapsing refresh failures into the plain "Cached: updated…" state
     (`ResearchPulseRefreshCoordinator.swift:150-166`). Add a distinct
     "Refresh failed — <safe reason>" row and log the `CorbisMCPError` case
     so "never tried" and "failing every time" are distinguishable.
   - Consider a gentle staleness escalation: after N days stale, show
     "Data is N days old — check connection" instead of a bare timestamp.

3. **Fix "Credits: 0" for unlimited plans.** (S backend + S client)
   - Backend: stop coercing `creditsRemaining: null` to `0` for unlimited
     tiers (`lib/research-profile/research-pulse.ts:61,277`; enterprise is
     `monthlyCredits: -1` per `lib/stripe/check-subscription.ts:164-166`).
     Send `null` or an explicit `"unlimited"` marker in the payload.
   - Client: make `creditsRemaining` optional and render "Credits: Unlimited"
     (or hide the row) for non-metered plans instead of a bare number.

4. **Relabel "Tracked papers".** (S, client copy) It is OpenAlex
   `works_count`, not user-tracked papers. "Indexed works" (or "Works on
   OpenAlex") is honest today; keep "Tracked papers" for a future real
   tracking feature.

## B. Data richness — make the numbers reflect the real record

5. **Merge/claim the fragmented OpenAlex identities.** (M, mostly external)
   Eleven unmerged OpenAlex author IDs exist for Cayman. Claiming works via
   ORCID (and submitting OpenAlex author-merge corrections) consolidates the
   graph at the source; merged the record reads ~24 works / ~17 citations /
   h≈3 instead of 3 / 4 / 1.

6. **Store and use the Google Scholar anchor.** (S data entry, L product)
   The verified profile (`user=j1wfmPYAAAAJ`, 31 citations, h-index 3) exists
   but is not linked in Corbis. Short term: save the Scholar URL/ID on the
   profile so it at least appears in Links and identity confidence. Longer
   term: founder decision C4 (Scholar/Semantic Scholar/SSRN licensing) gates
   using its counts; Scholar's merged working-paper+published counting is the
   most flattering and most familiar metric for finance academics — worth
   resolving C4 deliberately.

7. **Surface SSRN output.** (L, founder-gated) 10–15 active SSRN working
   papers with real download traction are invisible in every citation-based
   metric. For an early-career finance audience, papers + downloads is often
   the more meaningful pulse than citations. Even a v1 "Recent working
   papers" list (title + year + venue) from the already-linked author record
   would fill the panel with real content.

8. **Backfill the sparkline from OpenAlex `counts_by_year`.** (M, backend)
   The 52-week sparkline currently waits ~2 weeks for two cron snapshots.
   OpenAlex serves per-year citation counts for the author today; a coarse
   backfill (or seeding the snapshot table at link time) would let the trend
   section render on day one instead of showing "history is accruing".
   Re-linking (item 1) resets the clock, so do this together.

## C. Client Track B follow-ups (already spec'd, not yet built)

9. **In-app identity handshake UI.** (M) `find_academic_identity` /
   `confirm_academic_identity` are live server-side; the client's "Confirm
   identity" is scaffold-only and dead-ends at the token Settings pane
   (`OPEN-ISSUES.md` Track B table). This is the feature that would have let
   the operator fix item 1 from the menu bar. Guide §6 has the contract.

10. **Wire `get_data_freshness`.** (S–M) Fully spec'd (guide §5), live and
    smoke-tested server-side, zero client code. A small "Data current
    through…" footer adds trust and fills visual space honestly.

11. **Notifications on citation deltas.** (M, Phase 1) No
    `UNUserNotificationCenter` usage exists yet; becomes meaningful only
    after items 1 + 8 produce real deltas.

## D. Later phases (tracked, do not start now)

12. **New-work radar** (Phase 2) — blocked server-side on a forward-citation
    ("who cites you") primitive that does not exist yet; flagged XL/high-risk
    in the backend gap analysis.
13. **Linked repos + local git scanner** (Phase 2B) and **conference
    deadlines** (Phase 3, founder decision on a maintained dataset).
14. **Decide the inherited Codex/Claude tabs' fate** (open founder decision)
    — hiding or demoting the AI-usage surface changes how "finished" the
    ResearchBar product feels more than any single data fix.

## Suggested sequencing

Week 1: items 1, 2, 3, 4 (identity re-link + the two bugs + label). This
alone changes the panel from "4 citations, credits 0, two-week-old cache" to
"12+ citations, honest credits, live data with visible refresh state".
Week 2–3: items 8, 10, 9 (sparkline backfill, freshness footer, identity UI).
Then B5–B7 as the durable data-richness track, with C11/D following the
existing phase roadmap.
