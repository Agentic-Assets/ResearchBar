# Corbis Dashboard Design

## Purpose

Make the ResearchBar Corbis tab as immediately useful and scannable as the
existing Codex and Claude tabs, without presenting data that the authenticated
Corbis contract does not actually provide. The default surface remains Corbis
research intelligence; inherited generic AI-provider surfaces remain separate.

## Decision

Implement a compact Corbis account and research dashboard from the existing
`get_research_pulse` result. It will display the public research identity,
plan, server-reported remaining credits, research metrics, source-aware trend,
freshness, data quality, and existing safe actions. It will not infer an
allowance, reset time, credit usage history, account email, account identifier,
or bearer-token-derived identity.

The current contract represents finite balance as a remaining value and does
not include a credit limit or period. Therefore a progress bar is rendered
only if a future authenticated contract supplies a positive, authoritative
limit. An unlimited balance is presented as `Unlimited credits`; an unknown
balance is omitted rather than shown as zero.

## User-facing layout

The Corbis tab keeps its existing compact menu-card width and action routing.
It becomes a dashboard in this order:

```text
[graduation cap]  Display name                          Research plan
                  Role · affiliation                    Updated / Cached

Credits
12.5 credits remaining
[full-width progress bar only with a verified credit limit]

Academic pulse
1,284 Citations*                         24 Research works

Citation trend
[full-width chart or figure, when a valid tracked history exists]

Data quality: 3 of 4 sources current and complete
[notice, when applicable]

[Refresh] [Open Corbis] [Review identity] [ORCID] [Google Scholar]
```

`Citations*` retains the existing `Source-specific` qualification. The
dashboard must not total, compare, or silently substitute citation, h-index,
downloads, or work counts across sources. Existing source-authority selection
in `ResearchPulseCardModel` remains the sole presentation path.

Any chart or figure on the Corbis card uses the full available content width,
matching the Codex and Claude tabs. The citation figure is absent when history
is not yet tracked, still accruing, malformed, or unsupported. Those states
retain their truthful text status rather than drawing a zero-valued or
partial-width visualization.

## Components and data flow

`ResearchPulseRefreshCoordinator` remains responsible for account-keyed cache
lookup, menu-open refresh, coalescing, and safe stale-cache fallback.
`ResearchPulseCardModel` remains the boundary that validates/redacts a pulse
and projects renderable values. It will gain presentation-only plan and credit
fields; it will not read a credential or raw token.

`ResearchBarMenuContent` will compose the new header/credit section and a
full-width, conditionally rendered trend figure. It should reuse the inherited
provider-card layout conventions and full-width chart mechanics, but not their
Codex/Claude data fetchers, token-cost stores, account reconciliation, or
hard-coded credit denominators.

The fallback `ResearchPulseMenuModel` path maintains meaningful plan and
credit rows so non-hosted menus remain truthful, but it does not need to
duplicate a visual chart.

## Error handling and privacy

The card preserves existing no-network launch behavior, server freshness,
credit-exhaustion treatment, error redaction, and explicit refresh action.
It must not log or display raw credentials, token fingerprints, internal
author/source/account/install identifiers, private identity evidence, backend
labels, or cross-provider identity data. A malformed, missing, or unsupported
credit field remains absent, never a fabricated balance or percentage.

## Verification

Focused tests cover pulse-to-card projection for finite, unlimited, absent,
and malformed balances; source-aware academic metrics; stale cached state;
credit-exhausted state; and redaction. Menu-card tests cover the full-width
trend layout, truthful no-history states, bounded card height, and
accessibility labels. The implementation also runs the repository-required
format/lint and test gates without live Corbis, browser-cookie, or Keychain
access.

## Deferred Corbis backend capability

The Corbis product needs a separate backend-owned, authenticated, read-only
MCP usage summary before ResearchBar can truthfully show a quota bar, usage
history, reset dates, rate limits, or allowance charts. The requested issue
belongs in the **Corbis** Linear project, targets
`Agentic-Assets/agentic-assets-app`, and requires the matching repo label.

### Proposed issue title

Add account-scoped Corbis entitlement and usage summary for ResearchBar

### Objective

Add ResearchBar install attribution and an account-scoped read-only MCP usage
summary. This enables a future dashboard without client-side allowance math or
exposure of account internals.

### Required response semantics

- Resolve the subject exclusively from the bearer principal; accept no account
  or user argument.
- Return a typed `structuredContent` result with `plan`, compatible
  `creditBalance`, legacy `creditsRemaining` where applicable, `fetchedAt`,
  `staleAfter`, and `etag`.
- Return server-owned entitlement state that distinguishes ordinary Corbis
  credits from any future ResearchBar attribution or allowance.
- Return a usage window and next refresh time only when the finalized
  entitlement regime genuinely has those concepts.
- Return a positive credit limit only when it is authoritative, so the client
  can calculate a percentage without assumptions.
- Return no raw account, install, author, source, or credential identifiers;
  no private identity evidence; and no backend implementation labels.

### Definition of done

- Limited, unlimited, unattributed, and ResearchBar-attributed accounts yield
  unambiguous, typed states.
- Unknown entitlement data produces an explicit safe state, never a fabricated
  zero, reset date, allowance, or usage series.
- Contract, authentication, and cache-isolation tests prove a token cannot
  receive another account's data.
- Redaction tests reject identifiers, credentials, private identity evidence,
  and backend/source plumbing.
- A finite-credit authenticated smoke test proves the observed balance change
  for a successful charged call and the lack of permanent deduction for a
  failed tool call.

The local Linear CLI has no `agenticassets` workspace credential in this
session, so posting this user-authorized issue requires restoring that
workspace authentication. No authentication material is recorded here.
