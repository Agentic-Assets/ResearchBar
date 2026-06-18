# ResearchBar: Concept, Research, and Recommendation

**Date:** 2026-06-17
**Author:** Claude (Opus 4.8), for Cayman Seagraves
**Status:** Concept exploration plus high-level spec. Not a build spec yet.
**Companion files:** [`identity-and-data-consolidation.md`](identity-and-data-consolidation.md), [`corbis-api-contracts.md`](corbis-api-contracts.md), [`../research/research-dossier.md`](../research/research-dossier.md). **Build spec:** [`../BUILD.md`](../BUILD.md), [`../build/`](../build/). **Corbis eval:** [`../../../agentic-assets-app/docs/researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/).
**Location note:** This folder is a sibling of the Corbis-Plugin repo, kept separate per your instruction. Move or rename it freely.

---

## 0. What this is

You floated a product: a macOS menu bar app, in the spirit of Peter Steinberger's CodexBar and RepoBar, that helps academic researchers track their papers, citation counts (Google Scholar, SSRN), downloads, related work, GitHub repositories, and conference deadlines, and that is powered by and gated to the Corbis plugin so that using it pulls people onto the Corbis platform.

I ran a six-lane research workflow (19 agents) on the two reference apps, the academic data sources, the macOS build constraints, the Corbis integration surface, and the competitive landscape, then ran an adversarial verification pass against primary sources (GitHub REST API, package manifests, release metadata). The findings and every disposition are in [`../research/research-dossier.md`](../research/research-dossier.md). This report turns that into a recommendation, a concept, and a phased plan, with three decisions you already made folded in:

1. **Free, Corbis-gated funnel.** The app is free; the intelligence requires a connected Corbis account. It is top-of-funnel for the paid platform.
2. **Fork-first.** Clone CodexBar as the base and build on it, optionally borrowing RepoBar pieces. Do not build the shell from scratch.
3. **Finance and real estate academics first, architected to broaden.** Lead with the Corbis data backbone's strength, and keep the data layer pluggable so other fields can be added later without weakening the core.

---

## 1. Recommendation up front

**Build it. Ship aggregate Corbis APIs in `agentic-assets-app` first (`get_research_pulse`, `get_new_work_radar`, `get_data_freshness`, `get_conference_deadlines`), then fork CodexBar as a thin macOS renderer. Lead with a finance and real estate "research pulse," extensible to any field server-side.**

Why this is the right shape:

- **The base is free to take and well built.** CodexBar is MIT-licensed, 14,945 stars, and the reference implementation for a polished macOS menu bar utility (Swift 6.2, AppKit `NSStatusItem` plus SwiftUI, three-target Swift Package Manager build, notarized DMG plus Sparkle plus Homebrew). RepoBar is also MIT, same author, same stack, and already does the hard part of tracking entities, polling APIs, caching in SQLite, and pushing notifications. Forking the first and borrowing from the second saves months.
- **There is a real, narrow gap.** No existing tool combines own-citation monitoring, finance and real estate preprint alerts by subfield, an economic-data release calendar, related-work discovery tied to active projects, and an agentic weekly briefing in one always-on native macOS surface. CiteBar (MIT) is the only existing menu bar citation tracker, and it does Google Scholar h-index only. That is the wedge.
- **Corbis is a clean, defensible backbone, and the funnel logic works.** Corbis resolves a researcher's identity (anchored on their ORCID), returns papers with consolidated citation counts cross-verified across sources, surfaces top-cited and related work, and (this is the part no competitor has) supplies FRED macro data, US commercial real estate market intelligence, and dataset availability. Gating the intelligence to a Corbis account means every active user is a Corbis account, and the free tier (50 lifetime credits) converts naturally to a paid plan (Academic is $30/month for 1,000 credits).
- **The agentic layer is the moat.** Because a forked, non-sandboxed app can spawn local processes, the app can launch a Corbis-powered Claude Code research agent (or call the Claude API with a Corbis skill loaded) directly from the menu bar. No citation tracker does this. It is also the second funnel: it pulls users into the Claude Code plugin, not only the web platform.

The single most consequential correction from the research, and one to internalize before forking: **CodexBar is a passive usage monitor, not an agent launcher.** It reads provider quota data and displays it. It does not start, stop, or control agent sessions. So "fork CodexBar" means reuse its shell, rendering, auth patterns, and distribution, and then add the research domain and the agent-launch capability as new work. CodexBar gives you the chassis, not the engine.

---

## 2. What the two reference apps actually are (verified)

### CodexBar (the base to fork)

| Attribute | Finding | Confidence |
|---|---|---|
| Purpose | Passive menu bar monitor of usage limits, quotas, and credits across 50+ AI coding providers. Read-only. Not an agent controller. | high |
| Popularity | 14,945 stars (GitHub REST API, 2026-06-17), 1.2k forks, 76 releases, latest v0.36.1 (2026-06-16) | high (API-verified) |
| License | MIT (forkable for a commercial product) | high |
| Stack | Swift 6.2, AppKit `NSStatusItem` for the menu bar plus SwiftUI for preferences and menus. Not `MenuBarExtra`. Three SPM targets (app, CLI, WidgetKit). Swift 6 Observation framework for state. | high |
| Floor | macOS 14 (Sonoma) at runtime; Swift 6.2 only to build from source | high (commit-verified) |
| Distribution | Notarized DMG via GitHub Releases plus Sparkle 2.x auto-update plus Homebrew cask. Not on the Mac App Store. | high |
| Auth patterns | Five-tier fallback chain: OAuth, browser cookies (via the standalone MIT package SweetCookieKit), CLI inheritance, API token, local config probe | high |
| Borrow | `MenuDescriptor` pattern (async menu rebuilds without stalls), Merge Icons mode with a source switcher, pace tracking, bounded icon render cache, deferred refresh during menu tracking, Sparkle plus Homebrew distribution | high |
| Watch | macOS 26 (Tahoe) broke `NSStatusItem` positioning in non-trivial ways (issues #805, #1109, #1169). Test the Tahoe menu bar surface explicitly. | high |

### RepoBar (borrow from, do not necessarily fork)

| Attribute | Finding | Confidence |
|---|---|---|
| Purpose | Menu bar monitor of GitHub repos: CI/Actions status, issues, PRs, releases, local clone state, rate limits | high |
| Popularity | 2,090 stars (API-verified), 125 forks, 23 releases, latest v0.8.3 (2026-06-13) | high |
| License | MIT, free, no telemetry | high |
| Stack | Swift 6.2, SwiftUI plus AppKit `NSStatusItem`, Apollo iOS (GitHub GraphQL), **GRDB.swift for SQLite caching**, Sparkle, Kingfisher (avatars), GitHub App user-token OAuth (PKCE) plus Keychain | high |
| Borrow | SQLite ETag caching plus a live rate-limit meter, multi-account scoping, local-clone scanning (ahead/behind/dirty), per-repo pin/hide, release notifications, a clipboard reference monitor, optional AI summaries of PRs | high |
| Watch | Apollo iOS adds a heavy GraphQL dependency; GitHub App OAuth adds setup friction; the AI-summary feature needs its own API key and cost cap | high |

The practical reading: CodexBar is the more refined and more popular **shell**, which is why it is the right thing to fork and matches your preference. RepoBar is the better **data architecture** for tracking entities over time (its GRDB SQLite cache, polling, rate-limit meter, and notification patterns are exactly what a paper and citation tracker needs). Both are the same author and the same stack, so the pieces compose cleanly.

A third app deserves a mention as direct prior art: **CiteBar** (citebar.org), MIT-licensed, the only existing macOS menu bar citation tracker. It shows Google Scholar h-index and 30-day citation growth, multiple profiles, local storage, no telemetry. It validates the form factor and is worth reading for its Scholar-parsing approach, but it is Scholar-only with no discovery, no deadlines, no data feeds, and no agentic layer. It is the thing to leapfrog.

---

## 3. The product concept

### 3.1 One-line pitch

ResearchBar is a free macOS menu bar app that keeps a researcher's scholarly life one glance away (citations ticking up, new work citing them, fresh preprints in their subfields, economic-data releases, replication-repo status, and conference deadlines) and lets them launch a Corbis-powered research agent on any of it without opening a browser. It runs on Corbis.

### 3.2 The unmet need (verified gap)

No tool combines, in one always-on native macOS surface:

1. own-citation monitoring with deltas,
2. finance and real estate preprint alerts filtered by subfield,
3. a FRED and commercial real estate data-release calendar,
4. related-work discovery tied to active projects, and
5. an agentic "what changed in my literature this week" briefing.

CiteBar covers Scholar h-index only. Publish or Perish requires manual queries. SSRN eJournals are unstructured email. Semantic Scholar has good general alerts but no finance or CRE specialization, no data-freshness layer, no deadlines, and no native presence. The finance and real estate angle is where Corbis's market and macro tools cover data layers that no general academic tool integrates alongside citation tracking.

### 3.3 The menu, sketched

```
  ◔ 1,284 ▲                         ← menu bar icon: tracked citations + 7-day delta
 ┌──────────────────────────────────────────────┐
 │ Cayman Seagraves · U. Tulsa → FAU             │
 │ ORCID 0000-0002-…  · Corbis: Academic (842 cr)│
 ├─ Citation pulse ──────────────────────────────┤
 │ Total citations    1,284    ▲ +7  (7d)        │
 │ Tracked papers        18    h-index 11 *      │
 │ ▁▂▃▃▄▅▆▇  (52-week sparkline)                  │
 ├─ New work radar ──────────────────────────────┤
 │ ● 3 new papers cite you                        │
 │ ● 5 new in "REIT liquidity"                    │
 │ ● 1 related to your active project             │
 ├─ Data freshness  (Finance / RE) ──────────────┤
 │ FRED: CPI released today                       │
 │ CRE: Dallas-Fort Worth Q2 metrics updated      │
 ├─ Replication repos ───────────────────────────┤
 │ reit-liquidity   ✓ CI · 2 ahead · ★14         │
 ├─ Deadlines ───────────────────────────────────┤
 │ AREUEA National   · abstract due in 12 days    │
 │ AFA 2027          · submission due in 41 days  │
 ├────────────────────────────────────────────────┤
 │ ⚡ Run research agent…   (Corbis + Claude Code) │
 │ ⚙ Settings    ↻ Refresh    ⓘ Corbis credits    │
 └────────────────────────────────────────────────┘
   * h-index is optional, consolidated server-side by Corbis
     across sources (premium tier adds Google Scholar). See §5.
```

### 3.4 Feature inventory: aggregate Corbis APIs plus macOS-only glue

ResearchBar does not orchestrate low-level MCP fan-out for menu panels. Each row is one aggregate call (or a documented split) per `corbis-api-contracts.md`.

| Feature | Owner | Client call / action | Funnel role |
|---|---|---|---|
| Identity onboarding | Corbis | `find_academic_identity`, `confirm_academic_identity` | Requires Corbis account. The gate. |
| Citation pulse | Corbis | `get_research_pulse` | Daily-glance hook |
| New work radar | Corbis | `get_new_work_radar` | Recurring value; demonstrates Corbis search |
| Preprint alerts by subfield | Corbis (inside radar) | `get_new_work_radar` | Daily value when citations are slow |
| Data freshness | Corbis | `get_data_freshness` | Finance/RE moat |
| Conference deadlines | Corbis | `get_conference_deadlines` | Habit former; curated server-side |
| Replication repos | Split | Corbis: `get_linked_repos` (associations plus remote GitHub metadata). ResearchBar: local clone ahead/behind/dirty merge only | Stickiness; ties code to papers |
| Run research agent | ResearchBar (v1) | Read local Corbis plugin catalog; spawn Claude Code. Optional later: Corbis `get_agent_catalog` | Moat and second funnel into the plugin |

---

## 4. The Corbis funnel logic and the identity linchpin

### 4.1 The gate

The first-run flow is the gate and the personalization spine at once. The user confirms one thing, their ORCID, and the Corbis consolidation service does the rest server-side:

1. The user connects a Corbis account (OAuth, or pastes an API key). No account means no intelligence.
2. The service proposes an identity match from name and institution (`find_academic_identity`). The candidate is labeled by ORCID, the public anchor.
3. The user confirms, and `confirm_academic_identity` links the identity to the account. The internal source keys the resolver uses are never shown; the user sees their ORCID.
4. The consolidation service now serves the user's papers, citation counts, and rankings, cross-verified across sources. The client renders the result; it does not resolve identity or pull sources itself.

Because the resolver accepts a name override, the same flow resolves coauthors, which enables a collaboration view later. The full identity and consolidation design is in `identity-and-data-consolidation.md`.

### 4.2 The funnel math

- Every install that reaches value is a Corbis account. The app is a daily-active surface, so Corbis brand exposure is daily, not occasional.
- The Corbis free tier is 50 lifetime credits at **0.5 credits per call** (~100 aggregate calls). A user who watches citations, runs new-work radar, and checks data freshness exhausts credits on a roughly four-to-six-week horizon under daily polling, which is the upgrade trigger. The Academic plan is $30/month for 1,000 credits, sized for exactly this user. See [`funnel-economics.md`](funnel-economics.md) (corrected 2026-06-18).
- The agentic layer (each agent run consumes Corbis credits plus, optionally, Claude API tokens) is the high-intent conversion path and pulls power users into the Claude Code plugin.

This is two funnels in one app: a broad funnel into the Corbis web platform (anyone who installs), and a deeper funnel into the Claude Code plugin and paid tiers (power users who run agents).

### 4.3 What Corbis gives you, and the gaps to fill

Corbis exposes MCP tools over `https://www.corbis.ai/api/mcp/universal` with Bearer auth, **200 requests/hour enforced** (**10 concurrent is documentation-only**), **0.5 credits per call**. **Ten** tools are premium (enterprise-only in practice), including `literature_search`, `internet_search`, `read_web_page`, `deep_research`, `query_corbis`, and others (full list in Corbis [`06`](../../../agentic-assets-app/docs/researchbar-evaluation/06-risks-and-open-questions.md)).

**Today:** **30** registered tools in `agentic-assets-app`, including identity (`find_academic_identity`, `confirm_academic_identity`), paper search, `get_paper_details_batch` (up to 25 papers), FRED, CRE, and datasets. Substantial identity code already lives in `lib/research-profile/*`; the web candidate API is richer than MCP today.

**To build for ResearchBar:** four aggregate tools plus optional `get_linked_repos`. These wrap existing primitives and add multi-source reconciliation, delta math, sparklines, link resolution, and deadline curation. The client never loops low-level tools for menu panels. Precise contracts: [`../build/02`](../build/02-mcp-contract-get-research-pulse.md) and Corbis [`04`](../../../agentic-assets-app/docs/researchbar-evaluation/04-revised-corbis-api-contracts.md).

Gaps the aggregates must fill (all server-side):

- ORCID-first confirm (**unstarted**; today confirm keys on internal author ID).
- Multi-source citation reconciliation and h-index (web candidate already returns h-index; consolidation rule not yet documented).
- Forward citations and author works list as part of radar and pulse payloads.
- Conference deadline curation and per-user overrides (not client-held).
- Resolved links on every returned entity (DOI, Corbis paper page, PDF where available).
- Backend redaction pass so internal ids and backend names never reach clients (Phase 0.B).

**Agent catalog:** the exact plugin catalog is versioned and should be read from the local Corbis plugin install at build or runtime. These entries are Claude Code Markdown workflows, not REST endpoints. v1 ResearchBar reads the local plugin install for the browse menu and launches via subprocess; Corbis may add `get_agent_catalog` later for web parity. See `corbis-api-contracts.md`.

---

## 5. Data architecture: one centralized Corbis consolidation service, a thin client

The data layer is not in the app. Identity resolution and the consolidation of citations, rankings, and profile data across many sources (cross-verified and reconciled) live server-side in the `agentic-assets-app` (Corbis) repo, and the app consumes them through Corbis MCP tools and API endpoints. The full design, including the identity model, the cross-verification rule, and the backend source posture, is in `identity-and-data-consolidation.md`. This section states only what the report needs.

Three consequences shape everything downstream:

- **ORCID is the public anchor.** The app shows ORCID and a single Corbis-branded consolidated result. It never shows a raw backend source name, an OpenAlex ID, or per-source numbers.
- **The forked app holds no source adapters.** No scrapers, no resolvers, no reconciliation logic ship in the CodexBar fork. The client builds one Corbis client and renders answers. The provider protocol and the gap-filling backends (an unbranded public bibliographic graph, Crossref, arXiv, and the ToS-sensitive sources behind compliant channels) all live in `agentic-assets-app`, built once and reused by every surface.
- **Extensibility is server-side too.** Identity, citation, preprint, and discovery are field-agnostic; only the finance and real estate data-freshness panel is domain-specific. Broadening to other fields is a service-side change, not a client rewrite, so other fields simply do not show that panel.

The dependable, low-risk core of the service is the Corbis native tools plus an unbranded public bibliographic graph plus Crossref plus arXiv. Google Scholar, SSRN, and ResearchGate are the ToS-sensitive surfaces; they enter the consolidation only through licensed or compliant channels and are premium or optional, never the foundation. The "vanity" Scholar number academics emotionally track is an optional premium add-on, not a dependency, and the service degrades cleanly when a source is unavailable.

Conference deadlines live in Corbis (`get_conference_deadlines`): curated seed, user overrides, and refresh cadence are server-side so corbis.ai web can reuse the same calendar later.

Two rate-limit realities bind the client: Corbis is 200 requests/hour, and each aggregate returns `staleAfter` / `etag` the client should respect. Borrow RepoBar's GRDB SQLite cache for **response caching only**, not for source logic or deadline storage.

---

## 6. Technical architecture and the fork strategy

### 6.1 Distribution is decided for you

If the app spawns the local Claude Code CLI or reads any cookie or Full Disk Access path, the Mac App Store is foreclosed (the App Sandbox blocks spawning non-bundled binaries, and child processes inherit the sandbox). The route is direct distribution: Apple Developer ID, notarization via `notarytool`, Sparkle 2.x auto-update, Homebrew cask. CodexBar already ships exactly this, and Steinberger published the full notarization playbook, so you inherit a proven pipeline.

There is one fork in the road worth naming: an API-only build (URLSession to Corbis only, no subprocess, no cookies) could ship to the Mac App Store with the network-client entitlement. The thin-client design helps here, since all source access is server-side and the app itself just calls Corbis. If you ever want App Store reach, keep the agent-launch feature behind a capability check so an App Store variant can omit it. I would not optimize for this in v1; direct distribution is the right primary channel and matches the niche's norm.

### 6.2 What to reuse, what to graft, what to build

- **Fork from CodexBar:** `NSStatusItem` plus SwiftUI shell, `MenuDescriptor` rendering, icon cache, settings, `LSUIElement` lifecycle, Sparkle plus Homebrew, launch-at-login via `SMAppService`.
- **Graft from RepoBar (client infrastructure only):** GRDB response cache with ETag handling, polling loop, rate-limit meter, notification patterns. Not GitHub GraphQL orchestration if Corbis serves remote repo metadata.
- **Build in ResearchBar fork:** Corbis MCP client; thin ORCID confirm UI; generic panel renderer for aggregate JSON; local git clone scanner merged onto Corbis `get_linked_repos` records; agent catalog from local plugin install plus subprocess launch. No source adapters, reconcilers, deadline curation, or multi-tool orchestration.
- **Build in `agentic-assets-app` (blocking, reuse everywhere):** `get_research_pulse`, `get_new_work_radar`, `get_data_freshness`, `get_conference_deadlines`, `get_linked_repos`; extend identity MCP for ORCID-first parity with web; multi-source reconciliation. Inventory existing `lib/research-profile/*` first. See `identity-and-data-consolidation.md` and `corbis-api-contracts.md`.

### 6.3 The Corbis MCP client in Swift

Two viable paths:

1. **Plain URLSession to the universal endpoint** with an `Authorization: Bearer` header. Simplest, fewest dependencies, full control over caching and the 200/hour budget. Recommended for v1.
2. **The official Swift MCP SDK** (`modelcontextprotocol/swift-sdk`, Apache 2.0, macOS 13+), which provides stdio and HTTP/SSE transports. It is pre-1.0 (v0.12.1), so pin the version and treat API stability as a watch item. Useful later if you want to speak MCP to local servers too.

One open item to confirm against the live API before committing: whether the Corbis server returns CORS headers permitting a direct call from the app, or whether a thin proxy is needed. A native app is not a browser, so CORS usually does not apply, but confirm.

### 6.4 Background work and notifications

There is no iOS-style background refresh on macOS (`BGContinuedProcessingTask` is unavailable on macOS). An always-running `LSUIElement` menu bar app polls with a plain Swift `Timer` or an async task, which is the simplest and most reliable approach. Local notifications work via `UNUserNotificationCenter` with no special entitlement. If you want refresh even when the app is quit, a LaunchAgent is the native route, with the caveat that macOS 26 shows a user-visible prompt when an app registers a background daemon.

### 6.5 The agentic bridge (the moat)

Because the forked app is non-sandboxed, it can launch agents two ways:

- **Local Claude Code:** spawn the `claude` CLI (via Foundation `Process` or Swift `Subprocess`) with the Corbis plugin loaded and a chosen skill or slash command pre-filled, streaming output in a panel or handing off to Terminal. This is the deeper funnel: it requires the user to have Claude Code and the Corbis plugin installed.
- **Hosted via the Claude API:** call a Claude completion with the relevant `SKILL.md` loaded as context for users who do not run Claude Code locally. This trades local-agent power for zero-install reach, and adds Claude API cost.

v1: the app reads the locally installed Corbis plugin (`plugin.json` and skill paths) to render the catalog and spawns Claude Code with a pre-filled skill or command. Optional later: Corbis `get_agent_catalog` MCP tool if corbis.ai web needs the same metadata. Context-aware actions ("draft a referee response," "find related work for this paper") are ResearchBar presentation plus local launch, not server round-trips. This turns a tracker into a research copilot; the moat is Corbis plus local agent launch, not menu bar code.

---

## 7. MVP scope and phased roadmap

Scope the MVP to the wedge, then deepen the differentiator, then add the moat. Each phase is shippable and funnel-positive on its own.

**Phase 0: Corbis aggregates plus thin shell (the gate works).**

*Track A (Corbis, blocking):* Inventory `lib/research-profile/*`. Ship `get_research_pulse` v0. Extend identity MCP for ORCID-labeled candidates and web candidate parity. Define citation reconciliation rule.

*Track B (ResearchBar, after Track A):* Fork CodexBar to a clean shell; Corbis auth; thin confirm UI; render `get_research_pulse` in one menu panel. Target at most one aggregate call per refresh.

Outcome: Corbis account required, ORCID-anchored identity, consolidated citation pulse visible. Funnel-ready.

**Phase 1: The wedge (daily value).**
The build docs now sequence citation snapshots and `get_data_freshness` before radar and deadlines. Treat this concept paragraph as historical framing and use [`../BUILD.md`](../BUILD.md), [`../build/03`](../build/03-corbis-track-a-plan.md), and Corbis [`05`](../../../agentic-assets-app/docs/researchbar-evaluation/05-revised-implementation-plan.md) for implementation order.

**Phase 2: The differentiator (finance/RE moat).**
In the authoritative build plan, this phase is radar plus linked repos. The finance and real estate data-freshness panel moves earlier with the snapshot store.

**Phase 3: The moat (agentic).**
Agent catalog browser (local plugin v1), "Run research agent" launcher (Claude Code subprocess), weekly briefing assembled server-side or from cached radar plus freshness payloads. Optional: promote catalog to Corbis `get_agent_catalog`.

A note on sequencing the funnel: Phase 0 already gates on Corbis, so the funnel starts working before the app is fully featured. That lets you put it in front of a small group of finance and real estate academics (your network, Stace's network) early and measure Corbis signups and credit burn against real usage.

---

## 8. Business model and go-to-market

- **Model:** free app, Corbis-gated. Open-source the shell (the niche norm: CodexBar, RepoBar, and CiteBar are all MIT), which earns stars, credibility, and contributors, while the intelligence (and therefore the value) lives behind the Corbis account. Open-sourcing the shell does not give away the moat, because the moat is Corbis plus the agentic layer, not the menu bar code.
- **Pricing path for the user:** Corbis Free (50 credits) to Academic ($30/month, 1,000 credits). The app's daily polling and radar are the credit-burn that drives the upgrade. Consider negotiating a "ResearchBar" Corbis entitlement or a slightly larger free allowance specifically for app installs, to lengthen the free runway and raise install-to-signup conversion.
- **Distribution channels:** the founders' finance and real estate academic networks first (FMA, AFA, AREUEA, SSRN-FEN communities), then the Steinberger-style launch motion (X, a "Show HN", Homebrew, the macOS menu bar app directories that already index CodexBar and CiteBar). Worth noting from the research: CodexBar grew to ~15k stars without a first-party Show HN, largely on the author's audience and word of mouth, so a credible distribution push through your own academic network can carry the early curve.
- **Positioning line:** "ResearchBar is free. It runs on Corbis." That single line states the value and the gate at once.

---

## 9. Risks and open questions

Hard constraints (high confidence, design around them):

- **macOS 26 (Tahoe) `NSStatusItem` positioning bugs.** CodexBar has open issues. Test the Tahoe menu bar surface explicitly before any release.
- **Rate limits.** Corbis 200/hour and Crossref's tightened limits mean caching is mandatory, not optional. This is the reason to graft RepoBar's GRDB cache.
- **ToS exposure.** Google Scholar and SSRN have no compliant free API. Keep Scholar behind a paid SerpAPI opt-in and do not build download tracking on SSRN scraping.
- **Corbis surface gaps.** No author list, h-index, forward citations, or downloads from the native tools; fill them inside the centralized consolidation service or omit, never in the client.
- **Pre-1.0 Swift MCP SDK.** If used, pin it. Plain URLSession avoids the risk for v1.
- **Backend bibliographic usage cost** accrues server-side across many users in bulk. Budget for it as a Corbis cost-to-serve line inside the consolidation service, not as a client concern.

Open questions to confirm against the live API or vendors before building the relevant piece (these are the low-confidence items from the research):

1. Final JSON schema for `get_research_pulse`, `get_new_work_radar`, `get_data_freshness`, and `get_conference_deadlines` (see `corbis-api-contracts.md`).
2. ORCID-first `confirm_academic_identity` migration path from today's internal author key.
3. One credit per aggregate call regardless of internal fan-out: product sign-off.
4. `get_linked_repos`: standalone tool vs nested in pulse; who polls GitHub when account is linked?
5. Does the Corbis server need a proxy for native Swift, or is direct calling fine?
6. Semantic Scholar CC BY-NC: display in commercial app or redistribution only?
7. Public finance-conference dataset still maintained for `get_conference_deadlines` seed?
8. Live Corbis corpus size: verify against corbis.ai before quoting publicly.

---

## 10. Suggested next step

If you want to move, the lowest-risk first move is **Phase 0 Track A**: ship `get_research_pulse` in `agentic-assets-app` and prove it with MCP calls (identity, static citation metrics, null trend fields, profile links, redaction, and billing). Then **Track B**: fork CodexBar and render that one payload. That sequence answers §9 with real schemas and credit burn before the macOS shell work expands. Put it in front of five finance and real estate colleagues once Track B shows the pulse in the menu bar.

Two naming options to consider alongside the working name ResearchBar: a Corbis-branded name (for example "Corbis Bar" or "Scholar by Corbis") that maximizes funnel attribution, or a neutral name (for example "ScholarBar" or "Tenure") that reads as a community tool and may earn more open-source goodwill. The Corbis-branded route serves the funnel more directly; the neutral route may spread further before users learn it runs on Corbis. I lean Corbis-branded given that driving platform adoption is the stated goal.

**Possible domain:** [`research.bar`](https://instantdomainsearch.com?q=research.bar) is a strong candidate for a product landing or download site: short, on-brand with the menu bar metaphor (`.bar` TLD, same pattern as [citebar.org](https://www.citebar.org/) for CiteBar), and aligned with the working name. Use corbis.ai for platform attribution; use `research.bar` (if registered) for the free macOS app surface. Check availability before public announcement.

When you are ready to turn any phase into a build, the natural next artifact is an implementation plan for that phase (architecture, files, milestones), at which point this concept moves from exploration into a build spec.

---

## Appendix: research provenance

- Full source-cited research: [`../research/research-dossier.md`](../research/research-dossier.md) in this folder (six lanes: CodexBar, RepoBar, academic data sources, macOS build constraints, Corbis integration surface, competitive landscape).
- Verification: 12 flagged claims were checked against primary sources (GitHub REST API, package manifests, release metadata, Hacker News Algolia API). Two were refuted as misattributions (a bogus "125 forks" figure for the Corbis-Plugin repo, and a claim that "Xcode 26" implies a beta when it is the current stable line). Several were corrected to exact figures (CodexBar 14,945 stars; RepoBar 2,090 stars and 23 releases). The CodexBar "passive monitor, not agent launcher" finding is high confidence and shaped the fork strategy here.
- **Code audit (2026-06-17):** Tool count (30), credit cost (0.5/call), ORCID-first status (unstarted), and pulse trend fields (null in v0) were verified against `agentic-assets-app` and documented in [`../build/`](../build/) and [`../../../agentic-assets-app/docs/researchbar-evaluation/`](../../../agentic-assets-app/docs/researchbar-evaluation/). Corbis tool facts in the original research drew on plugin reference files; the live app inventory supersedes those counts.
