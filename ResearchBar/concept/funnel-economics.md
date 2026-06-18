# Funnel economics (illustrative)

This models credit burn and conversion logic for the aggregate-API architecture. Every rate marked "assume" is a placeholder for Phase 0 cohort data. Pricing inputs are verified from the research (see `research-dossier.md`, Sections 3 and 5).

## Verified inputs

Corbis MCP plans (baseline: 1 credit per call, 200 calls/hour, 10 concurrent):

| Plan | Credits | Price | Per-day budget |
|---|---|---|---|
| Free | 50 lifetime | $0 | one-time |
| Starter | 250/mo | $20/mo | ~8/day |
| Academic | 1,000/mo | $30/mo | ~33/day |
| Basic | 1,000/mo | $49/mo | ~33/day |
| Pro | 5,000/mo | $199/mo | ~165/day |
| Enterprise | unlimited | custom | n/a |

**Aggregate billing assumption:** one user-facing credit per aggregate MCP call (`get_research_pulse`, `get_new_work_radar`, etc.), regardless of internal fan-out. Internal bibliographic cost is Corbis cost-to-serve (~$0.001/search after free allowance), not a separate user charge.

## The core lever: credit per aggregate vs cost absorbed server-side

The client calls a small set of aggregates, not dozens of low-level tools. The funnel lever is which aggregates bill a user credit vs which Corbis serves from cache or free backend at its own cost.

| Regime | Billed to user (per day, illustrative) | Absorbed server-side |
|---|---|---|
| A. All aggregates billed | pulse + radar + freshness + deadlines | nothing |
| B. Hybrid (recommended) | radar + freshness + deadlines | `get_research_pulse` refresh |
| C. Differentiator-only | freshness + deadlines (plus identity on first link) | pulse + radar |

The gate stays real in every regime: identity onboarding, CRE/FRED freshness, and agentic runs are Corbis-only capabilities.

## Illustrative per-user credit burn (aggregate model)

Assumptions: one active researcher; pulse daily; radar daily; freshness and agentic briefing weekly; one aggregate call per panel per refresh.

| Aggregate | Refresh cadence | Regime A /day | Regime B /day | Regime C /day |
|---|---|---|---|---|
| `get_research_pulse` | 1/day | 1.0 | 0 (absorbed) | 0 (absorbed) |
| `get_new_work_radar` | 1/day | 1.0 | 1.0 | 0 (absorbed) |
| `get_data_freshness` | ~4/week | 0.6 | 0.6 | 0.6 |
| `get_conference_deadlines` | ~2/week | 0.3 | 0.3 | 0.3 |
| Agentic briefing | ~4/week | 0.6 | 0.6 | 0.6 |
| **Corbis credits/day** | | **~3.5** | **~2.5** | **~1.5** |
| **Corbis credits/month** | | **~105** | **~75** | **~45** |

How long the free 50-credit tier lasts under daily use:

| Regime | Free tier lasts |
|---|---|
| A. All aggregates billed | ~14 days |
| B. Hybrid | ~20 days |
| C. Differentiator-only | ~5 weeks |

Aggregates reduce client call volume (better for the 200/hour cap) and concentrate billing decisions in Corbis. A single `get_research_pulse` replaces what was previously 3+ low-level calls in the old model.

## Two readings of those numbers

Fifty lifetime credits still exhaust within roughly two to three weeks in regimes A and B. That drives conversion but risks activation churn if value is not felt before the wall.

Paid Academic ($30/month, 1,000 credits) has comfortable headroom at ~2.5 to 3.5 credits/day.

Absorbing pulse refresh server-side (regime B) costs roughly $0.001 per internal search. One thousand users at two absorbed searches per day is about $60/month total Corbis cost-to-serve.

Recommended: regime B, plus a ResearchBar-specific free allowance above 50 lifetime credits, tunable server-side without a client update.

## Illustrative conversion funnel

Per 1,000 installs (placeholders for Phase 0 cohort):

| Stage | Assumed rate | Count | Note |
|---|---|---|---|
| Installs | - | 1,000 | from launch channels |
| Activated (Corbis identity onboarding) | assume 60% | 600 | primary funnel win |
| Hit free-credit wall | most activated | ~500 | upgrade prompt |
| Convert to paid Corbis plan | assume 10% of activated | ~60 | ~$1,800 MRR at Academic |
| Adopt Claude Code plugin | assume 15% of activated | ~90 | second funnel |

Dominant value: new Corbis accounts and plugin adopters, not direct app subscription revenue.

## What to measure in Phase 0

- Credit burn per active day per regime, using **aggregate** calls only.
- Activation rate (ORCID confirm complete).
- Time-to-value vs time-to-credit-wall.
- Free-to-paid and plugin-adoption from the five-colleague cohort.
