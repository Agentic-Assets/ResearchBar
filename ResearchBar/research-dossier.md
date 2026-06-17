# ResearchBar Research Dossier

Working name: ResearchBar. A proposed macOS menu bar app for academic researchers to track papers, citation counts, downloads, GitHub repositories, related papers, and conference deadlines, powered by and gated to the Corbis research plugin and its MCP server. This dossier covers prior art, data feasibility, build constraints, the Corbis integration surface, the competitive landscape, and a technical feasibility verdict. It does not cover product recommendation, business model, MVP scope, or roadmap.

Confidence is flagged inline. Claims that were independently checked against primary sources (GitHub REST API, package manifests, release metadata) are marked high confidence; claims that rest on a single secondary review site or an unverified estimate are marked low confidence.

---

## 1. CodexBar analysis

CodexBar is a macOS menu bar utility by Peter Steinberger (@steipete) that displays real-time usage limits, quotas, credits, and reset countdowns for 50+ AI coding providers (Claude, OpenAI Codex, Cursor, Gemini, GitHub Copilot, Grok, DeepSeek, and dozens more) without requiring the user to open a provider dashboard or store passwords (source: https://github.com/steipete/CodexBar). It is the reference implementation in its niche and is the closest architectural analog to ResearchBar, which is why it leads this dossier.

### What it is and what it does

The core function is passive usage monitoring. The app tracks session, weekly, and monthly quota windows with reset countdowns, dual progress bars, credits, spend history, and incident status badges across 50+ providers (high confidence; source: https://github.com/steipete/CodexBar). A consequential design fact for ResearchBar: CodexBar does not launch or orchestrate agent sessions. All documentation describes read-only data acquisition from existing sessions. The "Open Terminal" action added in v0.33.0 only jumps the user to Terminal.app or iTerm for provider login commands; there is no documented capability to start, stop, or interact with running agent processes (high confidence; source: https://github.com/steipete/CodexBar/releases/tag/v0.33.0). It is a monitor, not a controller.

### Stack

CodexBar uses AppKit NSStatusItem for the menu bar lifecycle and SwiftUI for preferences and menu surfaces. It does not use SwiftUI's MenuBarExtra; it uses NSStatusItem directly via AppKit, which buys finer control: stable autosave names for position persistence, bounded icon animation frame rates, and a 64-entry IconRenderer cache for 18x18pt template images (high confidence; source: https://deepwiki.com/steipete/CodexBar). The project is a three-target Swift Package Manager build: the main app (AppKit lifecycle), a CodexBarCLI, and a CodexBarWidget WidgetKit extension. State management uses the Swift 6 Observation framework (`@Observable` stores: UsageStore, SettingsStore). Config persists to `~/.codexbar/config.json`.

The minimum runtime target is macOS 14 (Sonoma). Verification corrected and sharpened the original finding here. CodexBar's initial requirement was indeed macOS 15 (Sequoia): Package.swift declared `.macOS(.v15)`. It was then truly backported to macOS 14, not merely relabeled. Commit be4964fa0 ("feat: support macOS 14 and Intel builds", authored 2025-12-28) changed the platform target to `.macOS(.v14)` and added real Sonoma fallback code in DisplayLink and animation handling, and this shipped in the specific named release CodexBar 0.15.0, published 2025-12-28 (high confidence, verified against source tree and commit; source: https://github.com/steipete/CodexBar/commit/be4964fa0). As of mid-June 2026 the main branch, README, and Homebrew cask all reflect the macOS 14 minimum.

On the toolchain: Swift 6.2+ is strictly required to build from source, not merely recommended. Package.swift declares `// swift-tools-version: 6.2`, which Swift Package Manager enforces as a hard floor (older toolchains cannot build the package). Verification corrected an attribution detail: the README does not literally say "Build Requirements: macOS 14+, Swift 6.2+"; under its "Build from source" heading it says "Requires macOS 14+ and Swift 6.2+." The Swift requirement applies only to building from source; installing the prebuilt app via Homebrew or a GitHub release needs only macOS 14+ at runtime, no Swift toolchain (high confidence; source: https://github.com/steipete/CodexBar/blob/main/Package.swift).

### Distribution

CodexBar is distributed as a notarized DMG via GitHub Releases with Sparkle 2.x auto-update (appcast XML hosted on GitHub raw URLs), plus a Homebrew cask (`brew install --cask steipete/tap/codexbar`). It is not on the Mac App Store, because the browser-cookie and Full Disk Access patterns it relies on conflict with App Store sandboxing. Steipete documented the full notarization flow in a blog post including the entitlement requirements for Sparkle's XPC services and the rule to never use `--deep` for code signing (high confidence; source: https://steipete.me/posts/2025/code-signing-and-notarization-sparkle-and-tears). This is the proven non-App-Store distribution stack for sandbox-breaking macOS tools.

### Agent integration

CodexBar implements five authentication methods, applied as a fallback chain: OAuth device flow (Claude, Codex, Gemini, Copilot), browser cookies imported from Safari/Chrome/Firefox (Cursor, Factory, Augment), CLI inheritance reusing an already-authenticated CLI tool (Grok, Kiro, Augment), API token paste (OpenAI, DeepSeek, Groq, Venice), and local config-file probe (JetBrains AI, Windsurf, Antigravity). For Claude the priority order is Admin API > OAuth > CLI PTY > Web API. A bundled `codexbar` CLI mirrors the GUI for scripts and CI (high confidence; source: https://deepwiki.com/steipete/CodexBar/2-user-guide). Browser cookie decryption is abstracted into SweetCookieKit. Verification confirmed SweetCookieKit is a standalone, public, MIT-licensed Swift Package Manager package (github.com/steipete/SweetCookieKit, also listed on the Swift Package Index), not an internal CodexBar module; CodexBar consumes it as an external versioned SPM dependency (default `from: "0.4.1"`) with an optional local-path override for side-by-side development (high confidence, corrected from "medium"; source: https://github.com/steipete/SweetCookieKit).

### Popularity

As of 2026-06-17, github.com/steipete/CodexBar has exactly 14,945 stars per the GitHub REST API (`stargazers_count`), which the GitHub UI displays as the rounded "14.9k" (high confidence, verified against the API; source: https://api.github.com/repos/steipete/CodexBar). The original finding hedged that the true count "likely sits between" 14.9k and a search snippet's 11.9k; verification refuted that reasoning. A GitHub star count is a single exact integer at any instant, not a range, and a monotonically increasing counter resolves to the freshest (higher) value, not a midpoint. The 11.9k figure is a stale cached search-index snapshot, not a concurrent reading. The project has 1.2k forks and reached 76 releases (latest v0.36.1 on June 16, 2026). It launched as v0.1.0 on 2025-11-16 at approximately 18:16 UTC (high confidence, verified against the GitHub Releases API; the newreleases.io "7 months ago" label is consistent at 213 days; source: https://github.com/steipete/CodexBar/releases/tag/v0.1.0). It started as a single-Swift-file project of roughly 500 lines of code and grew through community contributions (23+ credited contributors on single releases) to 50+ providers and 21 languages, with WidgetKit support and inspired Windows and Rust ports (high confidence; source: https://x.com/steipete/status/1990121978888323579).

One adjacent verification note for completeness: CodexBar never had a first-party "Show HN" thread on Hacker News. The only "Show HN" with "CodexBar" in its title is a third-party Android port that credits the original; competing menu-bar quota tools reference CodexBar inside their own Show HN comment threads (high confidence; source: https://hn.algolia.com/api/v1/search?query=%22CodexBar%22&restrictSearchableAttributes=title&tags=story). This is a minor point but it tempers any inference that a Show HN launch drove its growth.

### What to borrow

The transferable patterns for ResearchBar (all high confidence; source: https://github.com/steipete/CodexBar/blob/main/docs/ui.md):

- The MenuDescriptor pattern: provider data drives a descriptor tree rendered into NSMenu separately, allowing async rebuilds without holding the menu open. This prevents UI stalls during async data fetches, which matters because ResearchBar will poll citation APIs on a timer.
- Merge Icons mode with a provider switcher: consolidates multiple sources into a single status item. Directly applicable to fitting multiple research data sources (Scholar, OpenAlex, SSRN, GitHub) into a constrained menu bar.
- Pace tracking ("on pace / X% in deficit runs out in... / X% in reserve"): applicable to research compute or API budgets such as WRDS query quotas or Corbis credit budgets.
- Deferred background refreshes during menu tracking, stable autosave names for position persistence, a bounded icon render cache, dual progress bars per source, incident badge overlays, and scroll-wheel navigation between items.
- The five-tier authentication fallback chain (Admin API > OAuth > CLI PTY > Web API > local file probe) is a reusable resilient-credential pattern.
- The Sparkle 2.x + GitHub Releases + Homebrew tap distribution stack, with steipete's blog post as a detailed how-to.

Risks to inherit awareness of: macOS 26 (Tahoe) broke AppKit NSStatusItem positioning in non-trivial ways. ControlCenter has intermittently pushed CodexBar's status item to an ephemeral state even with "Allow in Menu Bar" enabled (Issue #1169, macOS 26.5), and the menu bar icon has disappeared on macOS 26.4 through 26.5 (Issues #805, #1109, #1169). Any new menu bar app targeting macOS 26 should test this surface explicitly (high confidence; source: https://github.com/steipete/CodexBar/issues/1169).

---

## 2. RepoBar analysis and what to borrow

RepoBar is a second Steinberger menu bar app, and it is the closest functional analog to the GitHub-tracking portion of ResearchBar. It monitors GitHub repositories (CI status, issues, PRs, releases, local Git state, rate limits, contribution heatmaps) without a browser (high confidence; source: https://github.com/steipete/RepoBar). Note that CodexBar and RepoBar are different apps: CodexBar tracks AI usage limits and is far more popular, while RepoBar tracks GitHub repos (high confidence; source: https://github.com/steipete/CodexBar).

### Status and stack

RepoBar launched December 31, 2025. Verification confirmed the latest release as v0.8.3, published June 13, 2026, via both the GitHub `/releases/latest` pointer and the CHANGELOG entry "0.8.3 - 2026-06-13"; a "0.8.4 - Unreleased" changelog section indicates a newer version is in development but not yet published (high confidence; source: https://github.com/steipete/RepoBar/releases/latest). The repository has exactly 23 published releases (all non-draft, non-prerelease, matching 23 git tags), verified via the paginated GitHub REST API; the HTML releases page paginates at roughly 10 to 12 entries so it does not show the full total at once (high confidence; source: https://api.github.com/repos/steipete/RepoBar/releases). It has 2,090 stars (displayed as 2.1k) and 125 forks, verified via the GitHub REST API; a 1.1k search snippet was stale (high confidence; source: https://api.github.com/repos/steipete/RepoBar).

The stack is Swift 6.2 with SwiftUI plus AppKit (NSStatusItem), SwiftPM wrapped by pnpm scripts, Apollo iOS for GitHub GraphQL v4, GRDB.swift for SQLite caching, Sparkle for updates, Kingfisher for avatar caching, Commander for the CLI, and Tachikoma for OpenAI PR summaries (high confidence; source: https://deepwiki.com/steipete/RepoBar). Three SwiftPM targets: RepoBar (app + UI), RepoBarCore (GitHub client, AccountManager, TokenStore, LocalRepoManager, AppState), and repobarcli (CLI). Distribution mirrors CodexBar: MIT-licensed, free, no telemetry, Homebrew cask plus signed notarized DMG (high confidence; source: https://repobar.app/).

Two build-constraint notes. First, the AGENTS.md cites Xcode 26 as a requirement; this is not a future or beta version. Under Apple's year-based numbering adopted at WWDC 2025 (Xcode jumped from 16 to 26), Xcode 26.0 shipped as stable general availability on September 15-16, 2025, and the current stable release is Xcode 26.5 (May 11, 2026) (high confidence; source: https://xcodereleases.com/). Second, on authentication: RepoBar uses PKCE browser OAuth via GitHub App user tokens as the primary path, Personal Access Tokens (repo + read:org scopes) as an alternative, and stores tokens in the macOS Keychain. A JWTSigner utility implementing RS256 exists in the source tree but has no callers and is not wired into the production auth flow; the live OAuthCoordinator uses GitHub App user-only OAuth and explicitly notes that installation-token PEM resolution was removed (high confidence, verified at main commit 67e5b14, 2026-06-14; source: https://github.com/steipete/RepoBar/blob/main/Sources/RepoBar/Auth/OAuthCoordinator.swift). The practical takeaway for ResearchBar: GitHub App user-token OAuth via Keychain is the shipped, proven pattern; RS256 JWT signing for GitHub App installation tokens is present but inert, so do not assume it as a foundation.

### What to borrow

Directly applicable patterns for a researcher-facing GitHub surface (high confidence; source: https://github.com/steipete/RepoBar/blob/main/AGENTS.md):

- Per-repo pin/hide to surface replication packages and watched researcher repos above noise.
- Multi-account scoping (keyed by `host#username`, with per-account SQLite caches) for personal versus institutional GitHub.
- Local folder scanning that matches local clones to remote repos, showing branch, ahead/behind, dirty files, and worktree state, with optional auto-sync (fetch + fast-forward of clean repos only). For researchers, this keeps local replication-package checkouts current.
- CI/Actions status per repo, so researchers see whether their replication code still builds.
- Release notifications for pinned repos (new data releases, versioned replication packages).
- A clipboard reference monitor that detects GitHub issue/PR/commit references and shows inline previews, useful while reading papers (added v0.5.0).
- SQLite ETag caching plus a live rate-limit meter to protect free-tier API quotas (free GitHub accounts get 5,000 REST + 5,000 GraphQL points/hour).
- A bundled CLI mirroring the menu data, for shell scripting in research workflows.
- Optional AI-powered summaries of incoming issues/PRs via the OpenAI Responses API.
- Offline archive fallback via gitcrawl-compatible SQLite snapshots, useful on conference or hotel wifi.

Risks to inherit awareness of: Apollo iOS adds a non-trivial dependency requiring generated GraphQL schema files (which must not be hand-edited); GitHub App user-token auth requires registering and managing a GitHub App, adding setup friction; and the OpenAI PR-summary feature needs a separate API key and incurs cost, which may not suit a free research tool without a cost cap (high confidence; source: https://github.com/steipete/RepoBar).

---

## 3. Academic data sources: feasibility and compliance matrix

Eight source categories were evaluated for tracking papers, citation counts, downloads, related work, and conference deadlines in a commercial app. The matrix below summarizes API availability, cost, terms-of-service risk, and a recommendation. All rows are high confidence unless noted.

| Source | Official API | Cost | ToS / license risk | Recommendation |
|---|---|---|---|---|
| OpenAlex | Yes (API key required since Feb 13, 2026) | $1/day free allowance; then $0.0001/list-filter call, $0.001/search call, $0.01/PDF-XML call | Low. All data is CC0 (public domain), commercial use explicitly allowed | Primary backbone. Aggregates Crossref, PubMed, arXiv, and partially SSRN (source: https://blog.openalex.org/openalex-api-new-features-and-usage-based-pricing/) |
| Crossref REST | Yes (no auth for polite pool) | Free; Metadata Plus paid tier 150 req/sec | Low. Basic bibliographic metadata is factual, not copyrightable under US law; redistributable commercially | Use for DOI resolution and metadata; add `mailto=` for the polite pool (10 req/sec single DOI) (source: https://www.crossref.org/documentation/retrieve-metadata/rest-api/access-and-authentication/) |
| Semantic Scholar | Yes (free API key, 1 req/sec dedicated) | Free | Medium. Some corpus data is CC BY-NC, which constrains commercial redistribution; needs legal clarification from AI2 (s2-api@semanticscholar.org) | Use for citation graph and the Recommendations API for related work, after confirming commercial eligibility (source: https://semanticscholar.org/product/api/license) |
| arXiv | Yes (no auth, 1 req/3 sec) | Free | Low. Descriptive metadata is CC0; commercial use of metadata allowed (full-text PDF redistribution is not) | Use for preprint tracking (cs.*, econ.*, q-fin.*). No citation counts available (source: https://info.arxiv.org/help/api/tou.html) |
| Google Scholar | No official API | SerpAPI intermediary $75 to $275/month | High. Google ToS section 5.3 bars automated access; the `scholarly` library triggers CAPTCHA after a few requests | If h-index and profile citation totals are required, SerpAPI is the only compliant path; treat as optional or premium (source: https://serpapi.com/google-scholar-api) |
| SSRN | No public citation/download API | Free non-commercial TDM key; commercial requires a paid Elsevier license | High. Elsevier (owner) explicitly bans automated scraping; community scrapers are legally risky | Do not build download tracking on scraping. Commercial access needs an Elsevier API license (source: https://www.ssrn.com/index.cfm/en/terms-of-use/) |
| ORCID | Public API yes; Member API for commercial | Public API free but bars revenue-generating use; Member API is a paid subscription | High for commercial. The Public API "may not be used in connection with any revenue-generating product or service" | For a commercial product, use the Member API or rely on OpenAlex's free CC0 ORCID linkages (source: https://info.orcid.org/documentation/integration-guide/registering-a-public-api-client/) |
| Conference deadlines (finance/econ) | No machine-readable API | Free | Medium. WikiCFP scraping ToS is unclear; association sites have no API | Seed a curated database from tbeason/financeconferences (33 finance conferences, CSV, last refreshed October 2023) and supplement with scheduled scraping and user contributions (source: https://tbeason.com/financeconferences/) |

The commercially clean, low-cost triumvirate is OpenAlex + Crossref + arXiv, with no commercial restrictions across the three. Google Scholar (for h-index and profile totals), SSRN (for download counts), and ORCID (Public API in a commercial product) are the high-risk surfaces. SerpAPI advertises a "U.S. Legal Shield" on paid plans; verification flagged that this likely protects SerpAPI's customers from SerpAPI's own breach of Google ToS but does not immunize the customer from Google's own enforcement or direct legal action (low confidence on the exact scope; needs confirmation with SerpAPI).

Open items that need direct vendor confirmation before reliance (all low confidence as stated): whether Semantic Scholar's CC BY-NC restriction blocks displaying citation counts and titles in a commercial app or only bulk redistribution; ORCID Member API pricing for a small commercial vendor; whether any Elsevier API tier exposes SSRN abstract views and download counts at all; and whether tbeason/financeconferences is still maintained past its October 2023 footer (source: https://tbeason.com/financeconferences/).

Risks to design around: Crossref tightened rate limits effective December 1, 2025, so high-frequency polling now risks 429 errors without backoff and caching (high confidence; source: https://www.crossref.org/blog/announcing-changes-to-rest-api-rate-limits/). OpenAlex costs scale with usage above the $1/day free tier, which is generous per individual researcher but accrues charges in bulk across many users. Finance conference CFP data from association sites is fragile to site redesigns and irregular updates.

---

## 4. macOS build and distribution constraints

A menu bar app that spawns agent CLIs or accesses browser cookies and Full Disk Access paths must use direct distribution (Developer ID + notarization + Sparkle), not the Mac App Store. The App Sandbox that the App Store mandates is a hard blocker. This section catalogs the relevant constraints.

### MenuBarExtra versus NSStatusItem

SwiftUI MenuBarExtra (macOS 13+) is a fast start for simple menus but has documented gaps: no public API to get or set presentation state, disable the extra, access the underlying NSStatusItem, or access the popup NSWindow, and it blocks the runloop during menu display (high confidence; source: https://fazm.ai/blog/swiftui-menu-bar-app-floating-window-best-practices). The MenuBarExtraAccess library works around some of this on macOS 13+. Production apps requiring persistent windows, custom positioning, or precise key-window behavior use the AppKit NSStatusItem + custom NSPanel pattern with `LSUIElement=YES` in Info.plist to suppress the Dock icon. Steinberger's Vibe Meter uses exactly this hybrid (Swift 6, SwiftUI views, AppKit NSPanel, ImageRenderer to convert SwiftUI to NSImage for the status-item icon). macOS 26 Tahoe's Liquid Glass redesign removed the visible menu bar background but did not change these APIs (high confidence; source: https://steipete.me/posts/2025/vibe-meter-monitor-your-ai-costs). Both CodexBar and RepoBar chose NSStatusItem over MenuBarExtra for this reason.

### Sandbox versus notarized

The App Sandbox hard-blocks spawning external CLIs not bundled in the app. Apple's official guidance (Quinn "The Eskimo!", Apple DTS) is that a sandboxed Mac App Store app may only launch helper tools embedded within the app bundle, signed with `com.apple.security.app-sandbox` + `com.apple.security.inherit`. Spawning `/usr/local/bin/claude`, an npm-installed node, or any Homebrew binary is categorically blocked, and the sandbox is inherited by child processes so a child cannot exceed the parent's rights (high confidence; source: https://developer.apple.com/forums/thread/87849). The only viable path for spawning external agent CLIs (or for reading browser cookies and Full Disk Access paths) is direct distribution without the App Sandbox. Direct distribution requires an Apple Developer membership ($99/yr), Developer ID code signing, and notarization via notarytool. Steinberger's toolchain (create-dmg.sh, generate-appcast.sh, release.sh; Sparkle 2.x; raw-GitHub-hosted appcasts; the never-`--deep` codesigning rule and Sparkle XPC mach-lookup entitlements) is the proven template (high confidence; source: https://steipete.me/posts/2025/code-signing-and-notarization-sparkle-and-tears). For an app that only calls REST APIs via URLSession with no subprocess, the App Store remains viable with the `com.apple.security.network.client` entitlement; that is the relevant fork for ResearchBar if it stays API-only.

### Subprocess and agent launching

In a non-sandboxed app, Foundation's Process (formerly NSTask) and Swift 6.2's Subprocess package both launch external CLIs, pipe stdin/stdout/stderr, and monitor termination. Swift Subprocess (macOS 13+) offers an async/await API returning PID, termination status, and captured output. Child processes inherit the parent's environment, so PATH, HOME, and credential files (for example `~/.claude`) are available. For interactive streaming, use Pipe with `asyncBytes` on FileHandle (medium confidence on Hardened Runtime interaction details; source: https://dev.to/trozware/moving-from-process-to-subprocess-4408). The Hardened Runtime (required for notarization) does not itself block Process calls to external binaries in a non-sandboxed app. To connect to an MCP server via stdio, the official Swift MCP SDK (modelcontextprotocol/swift-sdk, v0.12.1, May 7, 2026, macOS 13+, Apache 2.0) provides a ready StdioTransport plus streamable HTTP/SSE; note it is still pre-1.0, so API stability across minor versions is not guaranteed (high confidence on existence, with the pre-1.0 caveat; source: https://github.com/modelcontextprotocol/swift-sdk).

### Background polling

For an always-running LSUIElement menu bar agent, a plain Swift Timer (or async Task with sleep) is the simplest and most reliable approach for periodic API polling from seconds to hours. NSBackgroundActivityScheduler suits low-priority maintenance at 10+ minute intervals but runs only on AC power, so a battery-only fallback Timer is needed and surfacing a "paused on battery" state is a small UX win. There is no iOS-style background refresh on macOS: the iOS BackgroundTasks classes, including the iOS-26 BGContinuedProcessingTask, are explicitly `API_UNAVAILABLE(macos)`, confirmed in Xcode 26 beta headers. For an always-on poller even when the app is quit, a LaunchAgent plist in `~/Library/LaunchAgents` is the macOS-native route; macOS Tahoe 26 added a user-visible popup when apps register background daemons after being closed (high confidence; source: https://github.com/dotnet/macios/wiki/BackgroundTasks-iOS-xcode26.0-b1).

### Notifications

UserNotifications works on macOS via UNUserNotificationCenter and supports local notifications (title, subtitle, body, sound, badge). The app must call `requestAuthorization(options:)` at first launch; users can revoke at any time. Foreground delivery uses the `willPresent` delegate. Local notifications work in both sandboxed and non-sandboxed apps and need no special entitlement (push notifications are the exception) (high confidence; source: https://developer.apple.com/documentation/usernotifications).

### Auto-update and launch at login

Auto-update is Sparkle 2.x via appcast XML on GitHub raw URLs, per the distribution stack above. Launch-at-login uses SMAppService (ServiceManagement, macOS 13+), which replaces the deprecated SMLoginItemSetEnabled: `SMAppService.mainApp.register()` to add, `.unregister()` to remove, `.status` to check. The feature must be opt-in (off by default) with an explicit toggle, and status should be read from SMAppService rather than persisted locally because users can change login items in System Settings (high confidence; source: https://nilcoalescing.com/blog/LaunchAtLoginSetting/).

### Version floor

macOS 13 Ventura is the documented minimum for MenuBarExtra, SMAppService, the official Swift MCP SDK, and Swift Subprocess. Targeting macOS 14+ is reasonable for a new 2026 app to avoid Ventura edge cases, matching CodexBar's macOS 14 floor (high confidence; source: https://en.wikipedia.org/wiki/MacOS_Tahoe). macOS 26 Tahoe changed the menu bar visual appearance (Liquid Glass) without new menu-bar developer APIs, but the NSStatusItem positioning bugs noted in Section 1 mean Tahoe needs explicit testing.

Open items needing confirmation (low confidence as stated): whether a non-sandboxed Hardened-Runtime app still needs `com.apple.security.network.client` declared explicitly or whether the absence of the sandbox entitlement makes it irrelevant; the exact Sparkle 2.x XPC mach-lookup entitlement set under Hardened Runtime; and whether Swift Subprocess introduces any Hardened-Runtime restrictions that differ from Process when spawning CLIs.

---

## 5. Corbis integration surface and the identity linchpin

The Corbis Research Plugin (v1.0.16) exposes 19 MCP tools via a single stateless HTTP endpoint at https://www.corbis.ai/api/mcp/universal, callable from Swift with a Bearer token. Auth supports OAuth (the plugin default, no key required to start) or API key via an `Authorization: Bearer KEY` header or `?apikey=KEY` query param; the bundled `.mcp.json` ships keyless on purpose so first use is not blocked (high confidence; source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/plugin/.mcp.json). Rate limits are 200 requests/hour and 10 concurrent, at 1 credit per call. Plans: Free = 50 lifetime, Starter = 250 at $20/mo, Basic = 1000 at $49/mo, Academic = 1000 at $30/mo, Pro = 5000 at $199/mo, Enterprise = unlimited at custom price (high confidence; source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_MCP_CLAUDE_CODE_GUIDE.md).

Of the 19 tools, 14 are standard-tier (available on every paid plan) and 5 are enterprise-only. The standard tools are: search_papers, get_paper_details, top_cited_articles, search_datasets, format_citation, export_citations, fred_search, fred_series_batch, get_national_macro, get_market_data, compare_markets, search_markets, find_academic_identity, confirm_academic_identity. The enterprise-only tools are: literature_search, internet_search, read_web_page, deep_research, query_corbis (high confidence; source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md).

### Tool-to-feature mapping

| Corbis MCP tool | Tier | Product feature it powers |
|---|---|---|
| search_papers | Standard | Paper and citation tracking. Returns id, title, authors, year, journal, abstract, doi, openalexId, url, citedByCount, semanticScore, keywordScore, combinedRank per result. The citedByCount field enables a lightweight citation dashboard and sorting by impact |
| get_paper_details | Standard | Full per-paper metadata including citedByCount and abstract for a tracked paper |
| top_cited_articles | Standard | Related and influential-work discovery in a topic area |
| search_datasets | Standard | Data-availability discovery for the researcher's active projects |
| find_academic_identity + confirm_academic_identity | Standard | The onboarding and identity linchpin (see below) |
| export_citations | Standard | Clipboard or file export of a saved paper set (bibtex or json) |
| format_citation | Standard | On-demand single-citation formatting |
| fred_search + fred_series_batch | Standard | FRED macro data feeds for an economic-data-freshness panel |
| get_national_macro | Standard | National macro context |
| get_market_data + compare_markets + search_markets | Standard | US metro-level CRE market intelligence: rankings, trends, side-by-side comparisons |
| literature_search, internet_search, read_web_page, deep_research, query_corbis | Enterprise | Live web search and multi-step deep research; unavailable below enterprise |

### The identity linchpin

The two-step identity flow is the natural onboarding and personalization spine. find_academic_identity takes optional nameOverride and institutionOverride to search OpenAlex for a profile; confirm_academic_identity takes an action (accept or clear), an OpenAlex authorId, authorName, and confidenceScore to link or unlink the account. Because find_academic_identity accepts a name override, it also resolves coauthor identities, enabling a coauthor or collaboration view (high confidence; source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md). Per-key Research Defaults at corbis.ai/settings (journal whitelist up to 10, default min/max year, additional instructions up to 2000 chars) are applied server-side, so the app can personalize search behavior per user without embedding filter logic in every call.

### Gaps to call out

The Corbis surface has clear gaps relative to a full researcher dashboard, and these matter for sourcing decisions (all high confidence; source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md):

- No author-publication-list endpoint: there is no single call for "all papers by researcher X." The workaround is a name-based search_papers query, which will miss papers and cannot paginate reliably by author.
- No h-index or career citation metrics: the identity tools only link to an OpenAlex ID. Career-level metrics require a direct OpenAlex REST call on the linked ID.
- No forward-citation lookup: search_papers is topical, not relational, so a "who cites this paper" feature needs a direct OpenAlex call.
- No download or altmetric counts: only citedByCount is returned. SSRN download tracking is not available through Corbis (and, per Section 3, not commercially available by scraping either).
- The 62 skills, 18 agents, and 16 slash commands shipped in the plugin are Claude Code prompting workflows defined as Markdown, not REST endpoints. A macOS app cannot invoke them as HTTP calls; launching them requires routing through a Claude API completion with the relevant SKILL.md loaded as context, adding Claude API cost and latency on top of Corbis credits (high confidence; source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/plugins/corbis-research-plugin/.claude-plugin/plugin.json).

Four tool names that appear in some briefs do not exist as documented callable Corbis tools, which is relevant because the app cannot rely on them. verify_bibtex and get_metric_definitions and screen_markets return zero matches across the repository's documentation and tool catalogs. get_paper_details_batch appears only in a single line of the idea-pivot-loop SKILL.md as a slash-notation variant of get_paper_details and is absent from CORBIS_API_REFERENCE.md, corbis-mcp-tools.json, and the MCP guide, so batched paper lookups must loop over individual get_paper_details calls, consuming one credit each (high confidence; source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/plugin/corbis-mcp-tools.json). Note that the deferred-tool list visible in this environment includes names like verify_bibtex, get_paper_details_batch, get_metric_definitions, screen_markets, and get_market_trends; that is a tool-routing manifest, not the documented Corbis API, and the verification above is against the plugin's own reference files.

Risks specific to the Corbis surface (high confidence; source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_MCP_CLAUDE_CODE_GUIDE.md): the 200 req/hr standard-tier limit constrains any search-as-you-type or parallel-call UI, so the app must batch and cache aggressively; and the enterprise wall removes live web search and deep research for non-enterprise users.

Open items needing confirmation against the live API (low confidence as stated): whether the OpenAlex author ID from confirm_academic_identity can be passed back into search_papers via an author-ID filter; whether citedByCount is real-time or a cached snapshot and its update cadence; the exact return schema of find_academic_identity; whether the Corbis server sends CORS headers permitting a direct fetch from a sandboxed Swift process or whether a local proxy is required; and the live corpus size (the repo documentation states 265,000+ papers, which should not be quoted publicly without verifying the live count at corbis.ai).

---

## 6. Competitive landscape and the precise unmet need

The academic publication tracking market in mid-2026 is fragmented across four categories: citation-count dashboards anchored to Google Scholar, institutional bibliometric databases, literature discovery and visualization tools, and reading-oriented paper-feed aggregators. The table below characterizes the relevant incumbents (all rows high confidence except where a price or tier is noted as estimated, which is low confidence).

| Tool | Platform | Cost | What it does | Gap for a finance/RE researcher |
|---|---|---|---|---|
| Google Scholar Profiles | Web | Free | h-index, total citations, citation-by-year, paper-level email alerts | No API, no download metrics, no topic alerts, no native client (source: https://scholar.google.com/intl/en/scholar/citations.html) |
| Publish or Perish | macOS native (v8) | Free non-commercial | On-demand h-index, g-index, citation stats from Scholar | Manual queries only; no push alerts, discovery, or deadlines (source: https://harzing.com/resources/publish-or-perish/os-x) |
| ResearchGate | Web, mobile | Free | Per-paper reads, downloads, citations, alerts | Weak economics/finance coverage; papers often unclaimed; no native client (source: https://www.scijournal.org/articles/best-tools-for-tracking-research-impact-and-citations) |
| Academia.edu | Web, mobile | Free; ~$100/yr Premium (low confidence) | Hosting, viewer analytics, citation notifications | Modest finance prestige; analytics paywalled; no native client (source: https://support.academia.edu/hc/en-us/articles/29297378153623-Academia-Free-vs-Premium-What-features-do-I-get-on-Academia) |
| Semantic Scholar | Web | Free | 214M+ papers, TLDRs, three alert types, recommendations, free API | TLDR/Topics weaker in econ/finance; no native client, no deadlines (source: https://www.semanticscholar.org/product) |
| Scopus | Web | Institutional only, ~$10K to $40K/yr (low confidence) | Author profiles, h-index, citation alerts | No individual subscription path (source: https://belmont.libguides.com/Scopus/Alerts) |
| Web of Science | Web | Institutional only, ~$15K to $60K/yr (low confidence) | Gold-standard bibliometrics, author alerts | No individual plan, no native client (source: https://webofscience.zendesk.com/hc/en-us/articles/20016619487889-Author-Alerts) |
| Dimensions.ai | Web, API | Free individual (limited); institutional ~$10K to $50K/yr (low confidence) | Linked publications, grants, patents, AI assistant | Domain-agnostic, no finance/RE specialization, no native client (source: https://www.dimensions.ai/products/artificial-intelligence/) |
| ResearchRabbit | Web | Free tier ~50 inputs; premium ~$12.50/mo (low confidence) | Citation-network discovery, Zotero import, alerts | General-science breadth; acquired by Litmaps May 2025; no native client (source: https://www.scoop.co.nz/stories/BU2505/S00127/nz-startup-litmaps-acquires-us-rival-and-raises-1m-to-accelerate-ai-driven-research-worldwide.htm) |
| Litmaps | Web | Free tier; ~$12.50/mo premium (low confidence) | Visual citation maps, monitoring alerts | No native client, no finance/RE specialization, no deadlines (source: https://effortlessacademic.com/litmaps-vs-researchrabbit-vs-connected-papers-the-best-literature-review-tool-in-2025/) |
| Connected Papers | Web | Free 5 graphs/mo; ~$3/mo academic (low confidence) | Single-seed related-work graph | One input only; no alerts or monitoring (source: https://aihungry.com/tools/connected-papers/pricing) |
| Scite | Web | Free basic; ~$20/mo personal (low confidence) | Smart Citations (supporting/contrasting), Ask Scite | No native client, no deadlines, no domain alerts (source: https://aichief.com/ai-education-tools/scite-ai/) |
| Scholarcy | Web, extension | Free 3/day; ~$8 to $10/mo (low confidence) | AI paper summarization and flashcards | A reading tool, not a tracker; no profiles or alerts (source: https://www.toolsforhumans.ai/ai-tools/scholarcy) |
| R Discovery | Web, iOS, Android | Free; ~$12/mo Prime (low confidence) | Recommendation feed, audio papers, Chat PDF | Does not track the researcher's own metrics; no native macOS client (source: https://discovery.researcher.life/) |
| CiteBar | macOS menu bar native | Free, MIT | Google Scholar h-index and 30-day citation growth in the menu bar; multiple profiles; local storage, no telemetry | Google Scholar only; no SSRN, Semantic Scholar, or Scopus; no discovery, deadlines, domain feeds, or alerts (source: https://www.citebar.org/) |
| SSRN eJournals (FEN) | Email | Free | Weekly digests of new working papers across 300+ finance/RE eJournals | Email only; no dashboard, filtering, cross-referencing, or visualization (source: https://www.ssrn.com/index.cfm/en/fen/fen-ejournals/) |

CiteBar is the most direct prior art: it is the only existing open-source macOS menu bar citation tracker, but it covers only Google Scholar h-index and 30-day growth, with no SSRN, no Semantic Scholar, no related-work discovery, no deadlines, no domain data feeds, and no alerts for new papers in a field (high confidence; source: https://www.citebar.org/). The Litmaps acquisition of ResearchRabbit in May 2025 (raising NZD $1.4M, combined user base above 2 million) consolidated the visualization space and introduced freemium pricing where free access previously existed (high confidence; source: https://www.scoop.co.nz/stories/BU2505/S00127/nz-startup-litmaps-acquires-us-rival-and-raises-1m-to-accelerate-ai-driven-research-worldwide.htm).

### The precise unmet need

No existing tool combines, in a single always-on native macOS surface: (a) own-citation monitoring, (b) SSRN finance preprint alerts filtered by subfield, (c) a FRED and CRE economic-data release calendar, (d) related-work discovery tied to the researcher's active projects, and (e) an agentic "what changed in my literature this week" briefing. CiteBar covers Scholar h-index only; Publish or Perish requires manual queries; SSRN eJournals deliver unstructured email with no aggregation; Semantic Scholar provides good general alerts but no finance/CRE specialization, no data-freshness layer, no deadline calendar, and no native presence (high confidence; source: https://effortlessacademic.com/litmaps-vs-researchrabbit-vs-connected-papers-the-best-literature-review-tool-in-2025/). The finance and real estate specialization is where Corbis's market and macro tools (get_market_data, compare_markets, fred_search, fred_series_batch, get_national_macro, search_datasets) cover data layers no general tool integrates alongside citation tracking (high confidence; source: https://www.citebar.org/).

Competitive risks to note: Google Scholar rate limits and ToS make Scholar-dependent features fragile, so a fallback to Semantic Scholar's API is prudent; SSRN exposes no public API, so subfield preprint filtering should be built on Corbis search_papers or Semantic Scholar rather than SSRN scraping; well-capitalized Litmaps or fully-free Semantic Scholar could add native or finance-vertical features; the menu bar is a constrained surface requiring careful information hierarchy; and top finance journals' 2-to-4-year publication lags mean citation ticks are slow, so the daily value proposition leans on preprint monitoring and data freshness rather than citation counts alone (high confidence; source: https://www.citebar.org/).

---

## 7. Technical feasibility verdict

The app is technically feasible as a direct-distribution (notarized, non-App-Store) macOS menu bar app on the NSStatusItem + SwiftUI hybrid pattern, with Corbis MCP over HTTP as the gated backbone and a small set of clean public APIs (OpenAlex, Crossref, arXiv) filling Corbis's gaps. Two flagged elements (Google Scholar h-index, SSRN download counts) carry real ToS exposure and are the only material feasibility constraints on the data side. Below is the explicit disposition of every flagged claim from the verification pass.

### Claims confirmed

- CodexBar v0.1.0 first released 2025-11-16 (~18:16 UTC), verified against the GitHub Releases API (source: https://github.com/steipete/CodexBar/releases/tag/v0.1.0).
- SweetCookieKit is a standalone, public, MIT-licensed SPM package, not an internal CodexBar module; CodexBar consumes it as an external dependency. This corrected the original "medium" confidence to confirmed (source: https://github.com/steipete/SweetCookieKit).
- CodexBar's macOS 15 minimum was truly backported to macOS 14, with real Sonoma fallback code, shipping in the named release 0.15.0 (commit be4964fa0, 2025-12-28). Both halves of the original either/or hold (source: https://github.com/steipete/CodexBar/commit/be4964fa0).
- CodexBar never had a first-party Show HN thread; the only CodexBar-titled Show HN is a third-party Android port that credits the original (source: https://hn.algolia.com/api/v1/search?query=%22CodexBar%22&restrictSearchableAttributes=title&tags=story).
- RepoBar has exactly 23 published releases, verified via the paginated GitHub REST API (source: https://api.github.com/repos/steipete/RepoBar/releases).
- RepoBar's latest release is v0.8.3 (June 13, 2026), with v0.8.4 unreleased and in development (source: https://github.com/steipete/RepoBar/releases/latest).
- RepoBar's JWTSigner (RS256) exists in the source tree but has no callers and is not wired into production auth; the live flow is GitHub App user-only OAuth (source: https://github.com/steipete/RepoBar/blob/main/Sources/RepoBar/Auth/OAuthCoordinator.swift).

### Claims corrected

- CodexBar star count. The original inference ("true figure likely between 14.9k and 11.9k") was refuted reasoning. The corrected figure is exactly 14,945 stars as of 2026-06-17 per the GitHub REST API; "14.9k" is the rounded UI display and "11.9k" is a stale cache. A star count is an exact integer, resolved by the freshest source, not a midpoint (source: https://api.github.com/repos/steipete/CodexBar).
- Swift 6.2 requirement for CodexBar. Corrected to: strictly required to build from source (Package.swift declares `// swift-tools-version: 6.2`, enforced by SwiftPM), and the README's exact wording under "Build from source" is "Requires macOS 14+ and Swift 6.2+," not the paraphrased "Build Requirements" string originally quoted. Installing the prebuilt app needs only macOS 14+ at runtime (source: https://github.com/steipete/CodexBar/blob/main/Package.swift).
- RepoBar star and fork counts. Corrected to 2,090 stars (displayed 2.1k) and 125 forks per the GitHub REST API; the 1.1k search snippet was stale (source: https://api.github.com/repos/steipete/RepoBar).

### Claims refuted

- "Xcode 26 implies a future or beta version." Refuted. Under Apple's WWDC 2025 year-based numbering (Xcode jumped from 16 to 26), Xcode 26.0 shipped as stable GA on September 15-16, 2025, and the current stable release is Xcode 26.5 (May 11, 2026). Xcode 26 is the current shipping major version (source: https://xcodereleases.com/). A secondary part of the same verification, that the Corbis-Plugin repo's AGENTS.md cites an Xcode requirement, was also refuted (no such string exists in that repo); the Xcode 26 reference belongs to RepoBar's AGENTS.md, not the Corbis-Plugin repo.

### Feasibility constraints carried into the verdict

These are not refuted claims but hard constraints established with high confidence:

- App Store is foreclosed if the app spawns external CLIs or reads browser cookies/Full Disk Access paths; direct distribution with Developer ID + notarization + Sparkle is the only route (source: https://developer.apple.com/forums/thread/87849). An API-only build (URLSession to Corbis MCP and public APIs, no subprocess) could in principle ship to the App Store with the network-client entitlement, which is the relevant fork.
- No iOS-style background refresh exists on macOS; BGContinuedProcessingTask is `API_UNAVAILABLE(macos)`. Background polling must use a Timer in an always-running LSUIElement app, with a battery-aware fallback if NSBackgroundActivityScheduler is used (source: https://github.com/dotnet/macios/wiki/BackgroundTasks-iOS-xcode26.0-b1).
- The official Swift MCP SDK (v0.12.1) is usable over stdio and HTTP/SSE but is pre-1.0, so API stability is a watch item (source: https://github.com/modelcontextprotocol/swift-sdk).
- Google Scholar (h-index, profile totals) and SSRN (download counts) are high ToS-risk and have no compliant free API; Scholar via SerpAPI is a paid compliant workaround, and SSRN download counts have no confirmed compliant programmatic source at all (sources: https://serpapi.com/google-scholar-api and https://www.ssrn.com/index.cfm/en/terms-of-use/).
- Corbis exposes citedByCount but not h-index, author publication lists, forward citations, or download/altmetric counts; those require direct OpenAlex calls or are unavailable, and the 200 req/hr standard-tier limit shapes the UI (source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md).

Net technical verdict: feasible with high confidence on the build, distribution, MCP-integration, and clean-data-source axes; the binding constraints are ToS exposure on Scholar and SSRN, the absence of author-level and download metrics in the Corbis surface (requiring direct OpenAlex calls), the macOS 26 NSStatusItem positioning bugs that need explicit testing, and the pre-1.0 status of the Swift MCP SDK.
