# 05. Risks and open questions

The client-relevant risks and the decisions that gate the funnel. This adapts the Corbis-side risk register ([`../../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md`](../../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md) and [`07-adversarial-review-verdict.md`](../../../agentic-assets-app/docs/researchbar-evaluation/07-adversarial-review-verdict.md)). See also [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md). All `path:line` references point into the Corbis repo.

## Risks that touch the client

1. **Passive polling drains a one-time endowment.** 50 lifetime free credits at 0.5 per call is 100 aggregate calls, ever (`tool-credits.ts:16`, `stripe/usage.ts:117-138`). An always-on background poller burns that in days, on days the user never looked. Mitigation lives in the client: poll on menu-open or a slow cadence, one aggregate call per refresh, respect `staleAfter`/`etag`. This is the single biggest activation risk and it is a client design choice.
2. **Null trend fields rendered as real zeros.** v0 returns null deltas and a null sparkline with `citationHistoryStatus`. A renderer that treats null as 0 shows a flat or empty trend that reads as "you gained nothing," which is wrong and demoralizing. Gate the trend view on the status enum (`02`).
3. **Leak of an internal id or backend name through a not-yet-redacted field.** Corbis Phase 0.B fixes the source, but until it ships, today's payloads leak (`output-schemas.ts:22`, `result-format.ts:97`, `confirm-academic-identity.ts:103`). The client should never render a string matching `^A\d+$` or a backend source name. Add a debug-build assertion or a client smoke test.
4. **Local cache cross-contamination across accounts.** The Corbis server keeps per-user aggregates out of its user-blind cache (`cache.ts:36-41`). The client must key its GRDB cache by Corbis account so a multi-account or account-switch scenario never serves one user's pulse to another.
5. **Designing concurrency around an unenforced limit.** "10 concurrent" is documentation-only (`resources/docs.ts:89,430`). Only 200/hour is enforced (`rate-limit.ts:67`). Build to the 200/hour budget, not the phantom concurrency number.

## Risks that block or delay the client (Corbis-side, track them)

6. **Never-surface is a backend cleanup, not a client property.** Highest-leverage Corbis Phase 0 work; the client cannot honor the rule by rendering raw payloads.
7. **ORCID is not stored and not the link key.** The whole anchor is net-new (`schema.ts` has no `orcid`; confirm keys on the internal id). The ORCID confirm UI waits on this.
8. **Citation time-series gap blocks the headline feature.** Deltas and sparkline need a new table plus a weekly cron (Phase 1); fields are null until two snapshots exist.

## Founder-only decisions (cannot be answered from code)

| Decision | Why it is open | Evidence |
|---|---|---|
| ResearchBar-specific free allowance (bigger than 50 lifetime credits) | No install-attribution column exists; entitlement overrides are typed `tier_upgrade`/`feature_unlock`/`model_access`, none grant credits. A scoped allowance needs a new tier or admin grants keyed to an install source that does not exist. Raising the global allowance raises it for all web users too. | `lib/db/schema.ts:1653,1662`; `lib/entitlements/queries.ts:71-79` |
| Polling cadence and credit regime | Determines how fast the free endowment burns and whether Corbis absorbs the pulse cost server-side (a subsidy) or the user pays per refresh. Product and margin call. | [`../concept/funnel-economics.md`](../concept/funnel-economics.md) |
| SSRN-derived numbers on any paid surface | SSRN is actively scraped in production via Firecrawl (`ssrn-scraper.ts`, wired at `app/api/user/ssrn/route.ts:13-14`), which contradicts the concept's "no scraping; license or omit." Resolve before showing SSRN numbers in a commercial funnel. | `lib/research-profile/ssrn-scraper.ts:12-23` |
| ToS for commercial sources | Semantic Scholar (CC BY-NC commercial display), Google Scholar (SerpAPI, opt-in only), ResearchGate (no compliant channel), ORCID Public vs Member API for revenue use. Vendor and legal questions, not code-resident. | [`../concept/open-questions-checklist.md`](../concept/open-questions-checklist.md) |
| Tier1 aggregates calling premium primitives | A free-tier aggregate that internally calls a premium or token-heavy primitive routes enterprise-cost capability to free users. Acquisition subsidy or forbidden? Margin decision. | `lib/ai/capabilities/index.ts:950-966` |
| Conference-deadline dataset | Confirm a maintained public finance-conference dataset or commit to in-house curation. Content-ops commitment. | [`../concept/open-questions-checklist.md`](../concept/open-questions-checklist.md) |
| Corbis corpus figure | Quote only from live corbis.ai, never from the repo, per the hard rule and VISION trust model. | standing rule |

## Client distribution and platform questions (this repo owns)

These remain the client's to resolve ([`../concept/open-questions-checklist.md`](../concept/open-questions-checklist.md) Track B): register the product domain (candidate `research.bar`, verify availability and registrar pricing), notarized DMG plus Sparkle plus Homebrew on a throwaway build, `NSStatusItem` on current macOS, launch-at-login via `SMAppService`, and whether an agent-launch capability flag is needed for any App Store variant.

## Bottom line

Proceed. Build Corbis Track A Phase 0 first (`get_research_pulse` v0 plus the ORCID anchor and the redaction pass), render the static pulse in one menu panel second, and treat the trend block as "tracking will begin" until the snapshot store accrues. Make the polling cadence conservative from day one, key the local cache by account, and redact defensively. Correct the concept docs' three load-bearing numbers (`04`) so no one re-plans against them.
