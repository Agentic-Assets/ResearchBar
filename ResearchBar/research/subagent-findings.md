# Sub-agent lane findings (raw research material)

These are the structured outputs returned by each of the six research sub-agents in the workflow, rendered near-verbatim (em dashes and a few house-style-banned words normalized; all facts, numbers, and source URLs unchanged). They are the primary material the report and dossier were synthesized from. Confidence labels and source URLs are the sub-agents own. Cross-check any load-bearing claim against `verification-verdicts.md`.

---

## CodexBar Research

CodexBar is a macOS menu bar utility by Peter Steinberger (@steipete) that shows real-time usage limits, quotas, credits, and reset countdowns for 50+ AI coding providers (Claude, OpenAI Codex, Cursor, Gemini, GitHub Copilot, Grok, DeepSeek, and dozens more) without requiring the user to open any provider dashboard or store passwords. It started as a single-Swift-file hobby project parsing local Codex CLI token logs and grew rapidly into a multi-provider, multi-account, localized (21 languages), WidgetKit-equipped production app. It is MIT-licensed, free, and distributed via GitHub Releases (notarized DMG with Sparkle auto-update) and Homebrew; it is not on the Mac App Store. By mid-June 2026 it had 76 versioned releases (latest v0.36.1 on June 16, 2026), approximately 14.9k GitHub stars and 1.2k forks, 23+ credited contributors on single releases, inspired Windows and cross-platform Rust ports, and has become the reference implementation in its niche. The app uses AppKit for menu bar lifecycle (NSStatusItem) and SwiftUI for preferences and menus, built with Swift 6 and Swift Package Manager. The architecture is descriptor-based with three targets: main app, CLI, and WidgetKit extension.

### Key findings

- **Core function: passive usage monitor across 50+ AI providers via menu bar icons** _(high)_  
  Evidence: GitHub README description: 'Show usage stats for OpenAI Codex and Claude Code, without having to login.' The app tracks session, weekly, and monthly quota windows with reset countdowns, dual progress bars, credits, spend history, and incident status badges. Supports Codex, Claude, Cursor, Gemini, Copilot, Grok, DeepSeek, Azure OpenAI, AWS Bedrock, Vertex AI, ElevenLabs, Deepgram, Kimi, LiteLLM, Devin, Amp, and 35+ more.  
  Source: https://github.com/steipete/CodexBar
- **Tech stack: AppKit NSStatusItem for menu bar + SwiftUI for UI surfaces; Swift 6; Swift Package Manager; three build targets** _(high)_  
  Evidence: DeepWiki architecture doc: 'Menu bar lifecycle via AppKit'; 'Mixed AppKit (menu bar) + SwiftUI (preferences/menus)'. Three targets: CodexBar.app (AppKit lifecycle), CodexBarCLI, CodexBarWidget.appex. Swift 6.2+ required. Build system is Swift Package Manager. This means it does NOT use SwiftUI's MenuBarExtra but instead uses NSStatusItem directly via AppKit, giving it finer control (stable autosave names, bounded icon animation frame rates, 64-entry IconRenderer cache).  
  Source: https://deepwiki.com/steipete/CodexBar
- **Minimum macOS: 14 (Sonoma); initial v0.1.0 targeted macOS 15 and was later backported** _(high)_  
  Evidence: v0.1.0 release notes say 'Initial macOS 15+ menu bar app'. Current README and all review sites state 'macOS 14+'. The backport to Sonoma happened somewhere between v0.1.0 and current stable.  
  Source: https://newreleases.io/project/github/steipete/CodexBar/release/v0.1.0
- **Distribution: notarized DMG via GitHub Releases with Sparkle 2.x auto-update; Homebrew cask; NOT Mac App Store** _(high)_  
  Evidence: Peter Steinberger wrote a dedicated blog post ('Code Signing and Notarization: Sparkle and Tears') documenting how he implemented Sparkle 2.x with DMG releases and GitHub-hosted appcast XML. Homebrew tap: 'brew install --cask steipete/tap/codexbar'. AUR (yay -S codexbar-cli) for Linux CLI. No Mac App Store listing found anywhere; sandboxing constraints would conflict with browser cookie and Full Disk Access patterns.  
  Source: https://steipete.me/posts/2025/code-signing-and-notarization-sparkle-and-tears
- **Agent/CLI integration: reads local CLI auth tokens and logs, uses OAuth device flow, browser cookies, API keys, and PTY for agent process interaction** _(high)_  
  Evidence: DeepWiki user guide documents five authentication methods: OAuth (Claude, Codex, Gemini, Copilot), browser cookies imported from Safari/Chrome/Firefox (Cursor, Factory, Augment), CLI inheritance reusing an already-authenticated CLI tool (Grok, Kiro, Augment), API token paste (OpenAI, DeepSeek, Groq, Venice), and local config file probe (JetBrains AI, Windsurf, Antigravity). For Claude the priority order is Admin API > OAuth > CLI PTY > Web API. A bundled 'codexbar' CLI mirrors GUI functionality for scripts and CI. The v0.1.0 tweet states it 'Parses your token logs, no login needed.' Config lives at ~/.config/researchbar/config.json.
  Source: https://deepwiki.com/steipete/CodexBar/2-user-guide
- **The app does NOT launch or orchestrate agent sessions; it is a passive monitor, not an agent launcher** _(high)_  
  Evidence: All documentation describes read-only data acquisition from existing sessions. The 'Open Terminal' action (added in v0.33.0) lets users jump to Terminal.app or iTerm for provider login commands, but this is a shortcut not an agent controller. There is no documented capability to start, stop, or interact with running agent processes.  
  Source: https://github.com/steipete/CodexBar/releases/tag/v0.33.0
- **Popularity: ~14.9k GitHub stars, 1.2k forks, 76 releases in roughly 12 months, 23+ contributors on individual releases, multi-platform ports exist** _(medium)_  
  Evidence: GitHub page fetch returned 14.9k stars and 1.2k forks with 76 total releases and latest v0.36.1 on June 16 2026. One search result cited 11.9k (possibly a snapshot from a few weeks earlier). The project has inspired Win-CodexBar (a Windows native port by Finesssee) and a cross-platform Rust CLI port (Dicklesworthstone/coding_agent_usage_tracker). Multiple review directories (onmymenubar.app, macmenubar.app, everydev.ai, allclaw.org) have indexed it.  
  Source: https://github.com/steipete/CodexBar
- **License: MIT** _(high)_  
  Evidence: Confirmed in GitHub README description, truenetlab review, and onmymenubar.app review: 'Free and open-source software under the MIT license.'  
  Source: https://github.com/steipete/CodexBar
- **UX patterns worth borrowing: descriptor-based menu architecture, Merge Icons mode with provider switcher, pace tracking system, deferred background refreshes during menu tracking, stable autosave names for position persistence, 64-entry icon render cache, dual progress bars per provider, incident badge overlays, scroll-wheel provider navigation** _(high)_  
  Evidence: docs/ui.md documents: MenuDescriptor pattern (data structure separate from rendering); Merge Icons mode ('consolidates multiple providers into a single status item, includes a provider switcher'); pace tracking ('On pace / X% in deficit runs out in... / X% in reserve'); 'IconRenderer generates 18x18pt dynamic menu bar icons with a 64-entry cache'; 'StatusItemController manages animations (wiggle, tilt) during refresh cycles'; 'menuWillOpen events for real-time data hydration'; 'deferred background refreshes during menu tracking to prevent UI stalls'; stable autosave names for position persistence; 'Menu wheel-scroll provider navigation' added in v0.34.0.  
  Source: https://github.com/steipete/CodexBar/blob/main/docs/ui.md
- **Origin: started as a single-Swift-file ~500 LOC hobby project in mid-2025, rapidly expanded through community contributions to 53+ providers and 21 languages by June 2026** _(high)_  
  Evidence: Launch tweet (Peter Steinberger, X): 'Made another tiny macOS app: CodexBar. Parses your token logs, no login needed. Menu icon updates live. Whole app is one Swift file, ~500 LOC.' CHANGELOG shows v0.18.0 already in March 2026 with multiple providers, with 76 total releases by June 16 2026 at v0.36.1.  
  Source: https://x.com/steipete/status/1990121978888323579
- **SweetCookieKit is a companion library steipete developed for browser cookie access used by CodexBar** _(medium)_  
  Evidence: X post from steipete: 'SweetCookieKit can now crack open Chrome's Local Storage' paired with a CodexBar release announcement. This appears to be an open-source Swift library encapsulating the browser cookie/Local Storage decryption layer that CodexBar depends on.  
  Source: https://x.com/steipete/status/2006489967392936211

### Technical notes

Architecture summary for implementers: Three-target Swift Package Manager project. Main app uses AppKit NSStatusItem (not SwiftUI MenuBarExtra) for menu bar lifecycle -- this is a deliberate choice that enables stable autosave names (position persistence across provider toggles), bounded animation frame rates, and finer XPC/entitlement control. SwiftUI is used inside the menu popover surfaces and the Preferences window. State management uses Swift 6 Observation framework (@Observable stores: UsageStore for provider data, SettingsStore for config). Menu construction uses a MenuDescriptor pattern: provider data drives a descriptor tree that is rendered into NSMenu separately, allowing async rebuilds without holding the menu open. IconRenderer maintains a 64-entry cache for 18x18pt template images with fill-bar variants. Sparkle 2.x handles auto-update via appcast XML hosted on GitHub raw URLs; the blog post documents exact entitlement requirements (-spks/-spki mach-lookup exceptions) and the critical 'never use --deep for code signing' rule. Config persisted to ~/.config/researchbar/config.json. Browser cookie decryption abstracted into SweetCookieKit (internal or standalone Swift package). Linux CLI build shipped separately for CI use cases. WidgetKit extension shares data model snapshots via App Group container.

### Product opportunities

- Adopt the MenuDescriptor pattern (data structure separated from NSMenu rendering) for any Corbis or Agentic Assets menu bar component -- prevents UI stalls during async data fetches
- Merge Icons mode with provider switcher is a clean UX pattern for any multi-source dashboard that needs to fit in a constrained menu bar
- Pace tracking (on-pace / deficit / reserve + 'runs out in X') is directly applicable to research compute budgets (WRDS query quotas, API token budgets)
- Sparkle 2.x + GitHub Releases + Homebrew tap is the proven non-App-Store distribution stack for sandbox-breaking macOS tools; steipete's blog post is a detailed how-to
- The five-tier authentication fallback chain (Admin API > OAuth > CLI PTY > Web API > local file probe) is a reusable pattern for resilient credential acquisition in any tool that needs to authenticate with multiple AI providers

### Risks

- The app reads browser cookies and Full Disk Access paths; any Agentic Assets tool following this pattern will face similar App Store rejection and must go the notarized DMG route
- macOS ControlCenter has intermittently pushed CodexBar's status item to an ephemeral state even with 'Allow in Menu Bar' enabled (Issue #1169, macOS 26.5 / CodexBar 0.29.1) -- a known fragile surface for menu bar apps on macOS 26
- The menu bar icon disappearing bug on macOS 26.4-26.5 (Issues #805, #1109, #1169) shows that macOS 26 broke AppKit NSStatusItem positioning in non-trivial ways; any new menu bar app targeting macOS 26 should test this explicitly

### Claims flagged for verification

- Exact GitHub star count at time of query: WebFetch returned 14.9k, one search snippet said 11.9k -- the true figure likely sits between these depending on snapshot timing
- Exact initial release date of v0.1.0 (the newreleases.io page said '7 months ago' relative to an unspecified crawl date; launch tweet date from the X post URL would confirm)
- Whether Swift 6.2 is strictly required or just the build toolchain recommendation (README says 'Build Requirements: macOS 14+, Swift 6.2+')
- Whether SweetCookieKit is a standalone public Swift package repo or just an internal module within CodexBar
- Whether the macOS 15+ initial requirement was truly backported to 14 or if Sonoma support came in a specific named release
- Whether Hacker News ever had a 'Show HN' thread for CodexBar specifically (the HN result found was for a competing tool that cited CodexBar, not a first-party Show HN post)

### Citations

- [GitHub: steipete/CodexBar](https://github.com/steipete/CodexBar)
- [CodexBar official site](https://codexbar.app/)
- [CodexBar docs/ui.md](https://github.com/steipete/CodexBar/blob/main/docs/ui.md)
- [CodexBar CHANGELOG.md](https://github.com/steipete/CodexBar/blob/main/CHANGELOG.md)
- [CodexBar releases](https://github.com/steipete/CodexBar/releases)
- [DeepWiki: steipete/CodexBar architecture](https://deepwiki.com/steipete/CodexBar)
- [DeepWiki: CodexBar user guide](https://deepwiki.com/steipete/CodexBar/2-user-guide)
- [steipete blog: Code Signing and Notarization: Sparkle and Tears](https://steipete.me/posts/2025/code-signing-and-notarization-sparkle-and-tears)
- [steipete launch tweet (X)](https://x.com/steipete/status/1990121978888323579)
- [steipete X: SweetCookieKit Chrome Local Storage](https://x.com/steipete/status/2006489967392936211)
- [steipete X: CodexBar 0.12 release](https://x.com/steipete/status/2003310459718382030)
- [steipete X: API costs rendering](https://x.com/steipete/status/2055346265869721905)
- [v0.1.0 initial release (newreleases.io)](https://newreleases.io/project/github/steipete/CodexBar/release/v0.1.0)
- [CodexBar v0.33.0 release notes](https://github.com/steipete/CodexBar/releases/tag/v0.33.0)
- [truenetlab review: CodexBar token limits](https://truenetlab.com/en/blog/codexbar-token-limits-and-resets-in-menubar/)
- [onmymenubar.app: CodexBar review](https://onmymenubar.app/codexbar/)
- [HN thread referencing CodexBar as incumbent](https://news.ycombinator.com/item?id=48477047)
- [Issue #1169: ControlCenter ephemeral status item macOS 26.5](https://github.com/steipete/CodexBar/issues/1169)
- [Issue #1109: Menu bar icon missing macOS 26.5](https://github.com/steipete/CodexBar/issues/1109)
- [Win-CodexBar (Windows port)](https://github.com/Finesssee/Win-CodexBar)

---

## RepoBar research

RepoBar is a native macOS menu bar app by Peter Steinberger (steipete) that launched December 31, 2025 and reached v0.8.3 on June 13, 2026, accumulating 23+ releases in roughly six months. It monitors GitHub repositories (CI status, issues, PRs, releases, local Git state, rate limits, contribution heatmaps) without requiring a browser. The stack is Swift 6.2 with SwiftUI plus AppKit, SwiftPM build system wrapped by pnpm scripts, Apollo for GitHub GraphQL v4, GRDB.swift for SQLite caching, Sparkle for updates, and Kingfisher for image caching. Authentication uses GitHub App user tokens delivered via a PKCE browser OAuth flow, stored in macOS Keychain; Personal Access Tokens (PAT) with repo and read:org scopes are a supported alternative; a JWT signing utility exists in the codebase but is not currently wired into the active auth flow. RepoBar has approximately 2.1k GitHub stars and 125 forks. CodexBar (same author, different app) monitors AI coding assistant usage limits across 53+ providers and has 14.9k stars, making it substantially more popular and an entirely different tool category. RepoBar is MIT-licensed, free, distributed via Homebrew and signed notarized DMG, with no telemetry. The patterns most transferable to a researcher-facing menu bar app are: per-repo pinning, multi-account scoped caching, local Git folder scanning matched to remote repos, CI/Actions status, release notifications for pinned repos, a clipboard reference monitor, SQLite ETag caching to protect rate limits, a CLI for scripting, and optional AI-powered PR summaries via the OpenAI Responses API.

### Key findings

- **Core function: GitHub repo dashboard in the macOS menu bar** _(high)_  
  Evidence: Repository cards show issue counts, PR counts, stars, forks, latest activity, CI run status (green/red/yellow), releases, and contribution heatmaps. Per-repo submenus expose recent issues, PRs, releases, Actions runs, discussions, tags, branches, commits, and local Git state (branch, ahead/behind, dirty files, worktrees). A global activity feed and contribution graph for the signed-in account are also shown.  
  Source: https://github.com/steipete/RepoBar
- **Local Git integration is a first-class feature** _(high)_  
  Evidence: RepoBar scans configurable local project folders and matches checkouts to GitHub repos. The menu shows current branch, upstream ahead/behind, dirty file summary, and worktree state. An optional auto-sync mode fetches and fast-forwards clean repos on a schedule without force-pushing or discarding changes.  
  Source: https://github.com/steipete/RepoBar/blob/main/README.md
- **Tech stack: Swift 6.2, SwiftUI + AppKit, Apollo GraphQL, GRDB.swift SQLite, Sparkle, Kingfisher, Commander CLI** _(high)_  
  Evidence: AGENTS.md and DeepWiki document three SwiftPM targets: RepoBar (app + UI using NSStatusItem and SwiftUI), RepoBarCore (GitHub client, AccountManager, TokenStore, LocalRepoManager, AppState), and repobarcli (CLI via Commander). Apollo handles GitHub GraphQL v4; GRDB.swift stores GraphQL response cache and REST ETags in per-account SQLite databases; Sparkle handles auto-updates; Kingfisher caches avatars. Build is SwiftPM wrapped by pnpm scripts; requires Xcode 26 and macOS Sonoma+.  
  Source: https://deepwiki.com/steipete/RepoBar
- **Authentication: PKCE browser OAuth via GitHub App user tokens is primary; PAT is alternative; JWT signing exists but is inactive** _(high)_  
  Evidence: OAuthCoordinator implements PKCE + browser loopback. For GitHub.com the app uses a GitHub App user token, avoiding broad classic OAuth repo scopes. GitHub Enterprise uses OAuth with configured enterprise host. PAT with repo and read:org scopes is supported for SAML SSO orgs. Tokens are stored in macOS Keychain (release builds) or file-backed (debug). A JWTSigner utility (RS256, macOS Security framework) exists for potential GitHub App installation tokens but is documented as not currently used.  
  Source: https://deepwiki.com/steipete/RepoBar/11.3-jwt-signing-for-github-apps
- **Rate-limit awareness and caching are architectural pillars** _(high)_  
  Evidence: v0.4.0 (May 3, 2026) introduced persistent GraphQL response caching and SQLite ETag cache for conditional REST requests. A dedicated Rate Limits sidebar shows live REST and GraphQL bucket meters with per-endpoint cooldowns. The app also supports offline fallback via gitcrawl.sh-compatible SQLite archive imports.  
  Source: https://github.com/steipete/RepoBar/blob/main/CHANGELOG.md
- **Multi-account support added in v0.7.0-0.8.0 with per-account scoped caching** _(high)_  
  Evidence: Accounts use stable identifier formula host#username. AccountManager holds per-account GitHubClient instances. GraphQL and HTTP response caches are segregated per account in separate SQLite databases. CLI commands repobar accounts list/use/remove were added. Legacy single-account credentials auto-migrate.  
  Source: https://github.com/steipete/RepoBar/blob/main/CHANGELOG.md
- **Clipboard reference monitor detects GitHub issue/PR/commit refs and shows inline previews** _(high)_  
  Evidence: v0.5.0 (May 9, 2026) added a clipboard-aware GitHub reference monitor that watches for issue/commit patterns and displays previews as separate menu items. v0.5.2 added inline browser previews for issues, PRs, and commits.  
  Source: https://github.com/steipete/RepoBar/blob/main/CHANGELOG.md
- **AI-powered PR summaries via OpenAI Responses API added in v0.8.0** _(high)_  
  Evidence: v0.8.0 (June 7, 2026) added optional OpenAI-powered PR summaries to the Issue Navigator sidebar. v0.8.3 routes AI summaries through the OpenAI Responses API directly. The Tachikoma dependency handles this integration.  
  Source: https://github.com/steipete/RepoBar/blob/main/CHANGELOG.md
- **RepoBar has ~2.1k stars and 125 forks; launched Dec 31, 2025 and at v0.8.3 by June 13, 2026** _(medium)_  
  Evidence: GitHub main page fetch returned 2.1k stars, 125 forks, 23 total releases, latest v0.8.3 dated June 13, 2026. Initial release v0.1.0 was December 31, 2025, per steipete's announcement on X and search results. One search snippet cited 1.1k stars (possibly a cached crawl from an earlier date).  
  Source: https://github.com/steipete/RepoBar/releases
- **CodexBar is a completely different app (AI usage limits, not GitHub repos) and is far more popular** _(high)_  
  Evidence: CodexBar (also by steipete) tracks usage limits across 53+ AI coding providers (OpenAI Codex, Claude, Cursor, Copilot, Gemini, etc.) and has 14.9k stars and 1.2k forks. It is not a GitHub repo monitoring tool and is not a direct competitor to RepoBar.  
  Source: https://github.com/steipete/CodexBar
- **MIT license, free, no telemetry, distributed via Homebrew and signed notarized DMG** _(high)_  
  Evidence: repobar.app and README confirm MIT license, free and open source, no telemetry, no account requirements beyond GitHub auth. Install: brew install --cask repobar. Releases page provides signed notarized .dmg per version. Build-from-source via SwiftPM is also supported.  
  Source: https://repobar.app/
- **Bundled CLI (repobar) enables scripting and automation over the same data the menu app shows** _(high)_  
  Evidence: CLI supports commands: login, repos (with filter flags), issues, activity, rate-limits, cache management, accounts list/use/remove. Commander framework parses CLI. This mirrors the menu data for terminal use and automation pipelines.  
  Source: https://deepwiki.com/steipete/RepoBar
- **Patterns to borrow for a researcher-focused menu bar GitHub app** _(high)_  
  Evidence: Directly applicable: (1) pin/hide per-repo to surface replication packages and watched researcher repos above noise; (2) multi-account scoping for personal vs institutional GitHub; (3) local folder scanning to match local clones of replication packages to their remote repos; (4) CI/Actions status per repo so researchers see if their replication code still builds; (5) release notifications for pinned repos (new data releases, versioned replication packages); (6) clipboard reference monitor for detecting GitHub links while reading papers; (7) SQLite ETag caching + rate-limit meter to protect free-tier API quotas; (8) bundled CLI for shell scripting in research workflows; (9) optional AI-powered summaries of incoming issues/PRs on replication packages; (10) auto-sync (fetch + fast-forward) for keeping local replication package checkouts current.  
  Source: https://github.com/steipete/RepoBar/blob/main/AGENTS.md

### Technical notes

Stack summary for builder reference: Swift 6.2 + SwiftUI (MenuBarExtra) + AppKit (NSStatusItem) | SwiftPM + pnpm script wrappers | Apollo iOS for GitHub GraphQL v4 | GRDB.swift for SQLite (per-account ETag + GraphQL cache) | Sparkle for auto-update via appcast.xml | Kingfisher for avatar caching | Commander for CLI parsing | Tachikoma for OpenAI PR summaries. Auth flow: PKCE + browser loopback OAuth -> GitHub App user token -> macOS Keychain (release) or file (debug). PAT alternative uses repo + read:org scopes. Multi-account keyed by host#username. JWTSigner (RS256 via macOS Security.framework) is present but inactive. Build gate: pnpm check (swiftformat + swiftlint + swift test). Code style: strict Swift 6.2 concurrency, @Observable over ObservableObject, files under 500 LOC, 4-space indents, imperative commit messages. GraphQL schema files are generated and must not be hand-edited.

### Product opportunities

- Researcher-specific repo filters: pin replication packages, watched coauthor repos, and institutional org repos; hide forks and archived repos by default
- Integration with SSRN/arXiv paper metadata to link a GitHub replication package to its paper DOI
- Auto-detect replication package repos by scanning for common markers (replication_package, stata, .do files, WRDS connection strings)
- Offline archive fallback via gitcrawl-compatible SQLite snapshots is directly useful when working in conference or hotel wifi without reliable GitHub API access
- CLI tool pattern is directly reusable for scripting research automation (batch repo status checks, CI health pings, issue triage)

### Risks

- RepoBar requires Xcode 26 - a developer targeting broader macOS deployment would need to verify minimum deployment target and toolchain availability
- Apollo iOS GraphQL client adds a non-trivial dependency that requires generated schema files; any schema changes from GitHub GraphQL v4 would require regeneration
- GitHub App user token auth (vs broad OAuth) requires registering a GitHub App and managing the app installation for private org repos - adds setup friction for academic users
- Rate limit dependence: free GitHub accounts have 5000 REST + 5000 GraphQL points/hour; a researcher monitoring many repos (including org repos) could exhaust limits without the ETag caching architecture
- OpenAI PR summary feature requires a separate OpenAI API key and incurs usage costs - may not be appropriate for a free research tool without a cost cap

### Claims flagged for verification

- RepoBar star count: one source (GitHub page fetch June 2026) returned 2.1k, one search snippet returned 1.1k - live count should be verified at github.com/steipete/RepoBar
- Fork count of 125 came from the June 2026 GitHub page fetch and should be verified live
- Total release count of 23 was cited in the initial GitHub page fetch; the releases pagination shows at least 20+ but exact count should be verified at github.com/steipete/RepoBar/releases
- JWT signing (JWTSigner / RS256) exists in the codebase but DeepWiki states it is not actively wired into production auth flows - this should be verified against the current source tree
- v0.8.3 released June 13, 2026 is cited as the latest release as of the fetch date; a newer version may exist by the time this is read
- Requirement of Xcode 26 (cited in AGENTS.md) implies a future/beta Xcode version; should be confirmed against the repo's current requirements

### Citations

- [steipete/RepoBar - GitHub](https://github.com/steipete/RepoBar)
- [RepoBar - GitHub at a glance, from your menu bar](https://repobar.app/)
- [steipete/RepoBar | DeepWiki](https://deepwiki.com/steipete/RepoBar)
- [JWT Signing for GitHub Apps | DeepWiki](https://deepwiki.com/steipete/RepoBar/11.3-jwt-signing-for-github-apps)
- [RepoBar CHANGELOG.md](https://github.com/steipete/RepoBar/blob/main/CHANGELOG.md)
- [RepoBar README.md](https://github.com/steipete/RepoBar/blob/main/README.md)
- [RepoBar AGENTS.md](https://github.com/steipete/RepoBar/blob/main/AGENTS.md)
- [RepoBar Releases](https://github.com/steipete/RepoBar/releases)
- [steipete/CodexBar - GitHub](https://github.com/steipete/CodexBar)
- [CodexBar - Mac Menubar Apps](https://macmenubar.app/app/codex-bar)
- [steipete on X announcing RepoBar](https://x.com/steipete/status/2006184268242768027)

---

## data-sources-research

Eight categories of data sources were evaluated for tracking academic researchers' papers, citation counts, downloads, related work, and conference deadlines in a commercial macOS application. The most commercially safe and reliable stack is OpenAlex (CC0, free tier with API key, usage-based pricing starting Feb 2026) plus Crossref (free, metadata unrestricted by copyright) plus Semantic Scholar (free API key, 1 req/sec, but commercial use of NC-licensed data needs verification) plus arXiv (free, no auth, 1 req/3 sec). Google Scholar has no official API, scraping violates its ToS, and while SerpAPI provides an intermediary service at $75-$275/month it carries ToS risk on Google's end. SSRN, now owned by Elsevier, explicitly prohibits automated scraping and offers no public citation or download API; commercial access requires a paid Elsevier API license. ORCID's Public API explicitly prohibits use in revenue-generating products, requiring a paid Member API subscription. Conference deadlines for finance and economics have no machine-readable API; the best available option is a manually curated CSV from tbeason/financeconferences on GitHub (finance-specific, 33 conferences, last refreshed October 2023) or scraping individual association websites on a scheduled basis.

### Key findings

- **Google Scholar: no official API; scraping violates ToS; SerpAPI is the only commercially viable intermediary at $75-$275/month** _(high)_  
  Evidence: Google's ToS section 5.3 prohibits 'access or use the Services through automated means (robots, spiders, scrapers).' SerpAPI pricing confirmed: Free 250 searches/month, Starter $25/month (1,000), Developer $75/month (5,000), Production $150/month (15,000), Big Data $275/month (30,000). All paid plans advertise 'U.S. Legal Shield.' The scholarly Python library (PyPI) works for small personal scripts but triggers Google WAF/CAPTCHA after a few requests without rotating residential proxies and 60+ second delays, making it unreliable for a shipping commercial product. SerpAPI provides structured JSON including organic results with citation counts, author profiles, and cited-by counts but does not provide author-level profile citation totals (i.e., the h-index and total citation count on a Scholar profile page requires a separate profile endpoint call).  
  Source: https://serpapi.com/google-scholar-api
- **SSRN: no official public API for citations or downloads; Elsevier ToS explicitly bans automated access; commercial API license required** _(high)_  
  Evidence: Elsevier owns SSRN and prohibits 'use of robots, spiders, crawlers or other automated downloading programs, tools, or devices to search, scrape, extract, deep link, index and/or disrupt' their products. An Elsevier API developer portal exists (dev.elsevier.com) for TDM; non-commercial academic use is free with API key self-registration, but commercial use requires a paid API license and subscription. SSRN does expose some citations on paper pages ('references' and 'footnotes' tabs) but has no documented endpoint for bulk download counts or citation metrics. Community scrapers on GitHub exist (talsan/ssrn, karthiktadepalli1/ssrn-scraper) but they are legally risky for a commercial product.  
  Source: https://www.ssrn.com/index.cfm/en/terms-of-use/
- **Semantic Scholar Academic Graph API: free API key, 1 req/sec dedicated limit, rich citation graph, but CC BY-NC data license constrains commercial redistribution** _(high)_  
  Evidence: API base: https://api.semanticscholar.org/api-docs/. Without API key: shared unauthenticated pool subject to collective slowdowns. With free API key: dedicated 1 req/sec, potentially higher after review (apply at semanticscholar.org/product/api). Three sub-APIs: Academic Graph (papers, authors, citations, references), Recommendations API, Datasets API (key required for bulk download). License agreement grants 'limited, non-exclusive, non-transferable, non-sublicensable' license. Some corpus data is under CC BY-NC, which prohibits commercial exploitation. Contact s2-api@semanticscholar.org to clarify commercial product eligibility before building on this source. Attribution to 'Semantic Scholar' required in published materials.  
  Source: https://semanticscholar.org/product/api/license
- **OpenAlex: best commercially safe option; CC0 data, free API key, usage-based pricing started February 2026** _(high)_  
  Evidence: From February 13, 2026, an API key is required (free, created at openalex.org/settings/api). All data is CC0 (public domain), explicitly allowing commercial use with no restrictions. Pricing per call beyond a $1/day free allowance: single work lookup free, list/filter $0.0001/call ($0.10 per 1,000), search $0.001/call ($1.00 per 1,000), PDF/XML download $0.01/call. The $1/day free tier gives 10,000 list/filter calls and 1,000 search calls daily, which is generous for a single researcher's tracking app. Data covers works, authors, institutions, concepts, venues, citations, and references. OpenAlex aggregates from Crossref, PubMed, arXiv, SSRN (partially), and others, making it a useful single-entry-point aggregator.  
  Source: https://blog.openalex.org/openalex-api-new-features-and-usage-based-pricing/
- **Crossref REST API: fully commercial-safe, no auth required for polite pool, rate limits tightened December 2025** _(high)_  
  Evidence: New rate limits effective December 1, 2025. Public pool: 5 req/sec (single DOI records), 1 req/sec (list queries), 1 concurrent connection. Polite pool (add mailto=youremail@domain.com query param): 10 req/sec (single DOI), 3 req/sec (list), 3 concurrent. Metadata Plus paid tier: 150 req/sec. Basic bibliographic metadata is treated as factual data not subject to copyright under US law; Crossref explicitly states it 'can be used and redistributed for commercial purposes.' No signup needed for polite pool. Key endpoint: https://api.crossref.org/works/{doi}. Useful for DOI resolution, metadata lookup, cited-by counts (limited), and funding info.  
  Source: https://www.crossref.org/documentation/retrieve-metadata/rest-api/access-and-authentication/
- **ORCID Public API: free registration but explicitly prohibits commercial/revenue-generating products; Member API required for commercial apps** _(high)_  
  Evidence: ORCID documentation states the Public API 'may not be used in connection with any revenue-generating product or service.' Registration requires an individual ORCID account; credentials are tied to that account (non-transferable). Public API (as of February 2025): 12 req/sec, 40 burst/sec, 100,000 reads/day per Client ID. Member API (institutional/commercial subscription): 24 req/sec, no daily quota, write access. ORCID Membership requires institutional or commercial partnership. A commercial macOS app tracking researcher profiles must use the Member API, which requires a paid agreement with ORCID. Data available: ORCID iDs, public profile info, works list, affiliations, funding, education.  
  Source: https://info.orcid.org/documentation/integration-guide/registering-a-public-api-client/
- **arXiv API: free, no authentication, 1 req/3 sec, CC0 metadata, no citation counts, good for preprint tracking** _(high)_  
  Evidence: Base endpoint: http://export.arxiv.org/api/query. Returns Atom 1.0 XML with titles, abstracts, authors, categories, dates, DOIs, journal refs. No authentication required. Rate limit: no more than 1 request every 3 seconds, single connection, max 2,000 results per call, max 30,000 per query with pagination. Descriptive metadata is CC0 (public domain) per Terms of Use; commercial use of metadata is allowed. Full text PDF redistribution requires copyright holder permission. arXiv does not provide citation counts. Good for tracking cs.*, econ.*, q-fin.* preprints by author or keyword. OAI-PMH bulk harvesting also available. Terms of Use: https://info.arxiv.org/help/api/tou.html  
  Source: https://info.arxiv.org/help/api/tou.html
- **Conference deadlines: no machine-readable API exists for finance/economics CFPs; tbeason/financeconferences CSV is the most structured source but may be stale** _(high)_  
  Evidence: WikiCFP (wikicfp.com) has no official API, focuses primarily on CS/engineering, and has sparse finance/economics coverage. Community Haskell scraper (wikicfp-scraper on Stackage) exists but scraping WikiCFP's ToS status is unclear. EasyChair is a submission management platform, not a deadline aggregator. tbeason/financeconferences (https://tbeason.com/financeconferences/) is maintained by Tyler Beason, covers 33 finance conferences with CSV download and open-source GitHub code, but was last updated October 2023. Individual association sites (AFA afajof.org, WFA westernfinance.org, FMA fma.org, AREUEA areuea.org, AEA aeaweb.org, NBER nber.org) maintain conference calendars manually with no structured API. For a commercial app, the best approach is to maintain a curated database seeded from tbeason's CSV and supplemented by scheduled scraping of individual association calendar pages, combined with user-contributed updates.  
  Source: https://tbeason.com/financeconferences/

### Technical notes

Source URLs confirmed during research:
- Semantic Scholar API docs: https://api.semanticscholar.org/api-docs/ | Tutorial: https://www.semanticscholar.org/product/api/tutorial | License: https://semanticscholar.org/product/api/license
- OpenAlex developer portal: https://developers.openalex.org/ | Pricing blog: https://blog.openalex.org/openalex-api-new-features-and-usage-based-pricing/ | ToS PDF: https://openalex.org/OpenAlex_termsofservice.pdf
- Crossref REST API auth/rate limits: https://www.crossref.org/documentation/retrieve-metadata/rest-api/access-and-authentication/ | Rate limit change announcement: https://www.crossref.org/blog/announcing-changes-to-rest-api-rate-limits/
- ORCID Public API registration: https://info.orcid.org/documentation/integration-guide/registering-a-public-api-client/ | Rate limit update: https://info.orcid.org/refining-api-traffic-management
- arXiv API manual: https://info.arxiv.org/help/api/user-manual.html | ToU: https://info.arxiv.org/help/api/tou.html
- SerpAPI pricing: https://serpapi.com/pricing | GS endpoint docs: https://serpapi.com/google-scholar-api
- scholarly PyPI: https://pypi.org/project/scholarly/
- tbeason financeconferences: https://tbeason.com/financeconferences/ | GitHub: https://github.com/tbeason/financeconferences
- SSRN ToU: https://www.ssrn.com/index.cfm/en/terms-of-use/ | Elsevier TDM: https://dev.elsevier.com/tdm_service.html
- WikiCFP: http://www.wikicfp.com/cfp/allcfp
- ORCID member vs public API: Public credentials are tied to individual ORCID iD and non-transferable; Member API credentials are issued to organizations via ORCID Membership agreement.
- For Crossref polite pool: include User-Agent header identifying your app and mailto=contact@yourdomain.com as a query parameter on all requests.
- OpenAlex API key: add as api_key=YOUR_KEY query param or Authorization: Bearer YOUR_KEY header. Key obtained free at https://openalex.org/settings/api.
- Crossref Metadata Plus (paid tier, 150 req/sec): https://www.crossref.org/services/metadata-retrieval/metadata-plus/
- SSRN Elsevier developer portal: https://dev.elsevier.com/ (requires registration; commercial use requires separate licensing agreement beyond free TDM API key)

### Product opportunities

- OpenAlex + Crossref + arXiv form a legally clean, low-cost triumvirate for tracking papers and citation counts with no commercial restrictions. These three together can cover the majority of academic researcher output without any ToS risk.
- For Google Scholar h-index and profile citation totals, SerpAPI at $75-$150/month is the only compliant path; consider making GS integration optional or a premium feature given ongoing cost.
- SSRN download statistics are not accessible programmatically for commercial use without an Elsevier API license; consider removing SSRN download tracking from the MVP scope and revisiting after negotiating with Elsevier.
- ORCID integration requires a paid Member API subscription for a commercial product; evaluate whether the cost is justified versus using OpenAlex author data which includes ORCID linkages for free under CC0.
- The conference deadline gap (no machine-readable API for finance/economics CFPs) is itself a product opportunity: a curated, maintained database of finance conference deadlines seeded from tbeason's work could be a differentiating feature.
- Semantic Scholar Recommendations API (paper recommendations based on seed papers) is a strong source for 'related work' suggestions with no cost, but commercial use restrictions on CC BY-NC data need legal review before shipping.

### Risks

- Google Scholar scraping (scholarly library or direct) violates Google's ToS regardless of commercial intent; IP bans, CAPTCHA walls, and potential legal action are material risks for a shipping product.
- SSRN automated access without Elsevier authorization violates their ToS; Elsevier actively enforces against unauthorized scrapers.
- ORCID Public API explicitly prohibits revenue-generating product use; building on the Public API in a commercial app creates ToS violation risk that could result in credential revocation.
- Semantic Scholar's CC BY-NC data license may block commercial redistribution of data obtained via the API; this needs explicit legal clarification from the AI2 team before building a commercial product on top of it.
- OpenAlex's API key requirement (since Feb 13, 2026) and usage-based pricing above the $1/day free tier mean costs will scale with usage; the free tier is generous for individual researchers but bulk operations across many users will accrue charges.
- Crossref rate limit tightening (December 2025) means previously working polling patterns at high frequency may now receive 429 errors; the app must implement proper backoff and caching to stay within polite-pool limits.
- Finance conference CFP deadline data from individual association websites is fragile: site redesigns break scrapers, and many associations update their pages irregularly or only post on social media channels first.

### Claims flagged for verification

- Semantic Scholar CC BY-NC data license scope: confirm with AI2 (s2-api@semanticscholar.org) whether displaying citation counts and paper titles in a commercial macOS app constitutes prohibited commercial use under the CC BY-NC license on their corpus, or whether the license restriction applies only to bulk redistribution.
- ORCID Member API cost: verify current pricing for ORCID Membership for a commercial software vendor; the Membership tier and associated cost structure for small commercial entities vs. institutions is not publicly listed and requires direct inquiry at https://orcid.org/about/membership.
- SerpAPI 'U.S. Legal Shield': confirm exactly what legal protection SerpAPI's 'U.S. Legal Shield' covers; it likely protects SerpAPI's customers from SerpAPI's own breach of Google ToS but does not immunize the customer from Google's own ToS enforcement or any potential direct legal action.
- OpenAlex usage-based pricing beyond $1/day free tier: verify the per-operation pricing table is still current (blog post from Feb 2026); confirm whether academic/non-profit entities still qualify for free higher-tier access via support@openalex.org.
- Elsevier API for SSRN-specific data: confirm with Elsevier (dev.elsevier.com) whether a commercial API license specifically covers SSRN abstract views and download counts, or whether these metrics are unavailable through any API tier.
- arXiv OAI-PMH bulk access: verify whether arXiv's bulk data access via OAI-PMH (https://info.arxiv.org/help/oa/index.html) is subject to the same 1 req/3 sec rate limit or has its own bulk harvesting terms.
- WikiCFP terms of service regarding automated scraping: WikiCFP does not publish a clear robots.txt or ToS; scraping legality should be verified before building automated deadline ingestion from WikiCFP.
- tbeason/financeconferences maintenance status: the site footer shows last update October 2023; verify whether the site is still actively maintained or if a successor community resource exists as of mid-2026.

### Citations

- [SerpAPI Google Scholar API Documentation](https://serpapi.com/google-scholar-api)
- [SerpAPI Pricing](https://serpapi.com/pricing)
- [scholarly Python library on PyPI](https://pypi.org/project/scholarly/)
- [Google Terms of Service - Automated Scraping](https://wpseoai.com/blog/is-web-scraping-against-google/)
- [SSRN Terms of Use](https://www.ssrn.com/index.cfm/en/terms-of-use/)
- [Elsevier Text and Data Mining Service](https://dev.elsevier.com/tdm_service.html)
- [Semantic Scholar API Documentation](https://api.semanticscholar.org/api-docs/)
- [Semantic Scholar API License](https://semanticscholar.org/product/api/license)
- [Semantic Scholar API Tutorial](https://www.semanticscholar.org/product/api/tutorial)
- [OpenAlex API New Features and Usage-Based Pricing (Feb 2026)](https://blog.openalex.org/openalex-api-new-features-and-usage-based-pricing/)
- [OpenAlex Developer Portal](https://developers.openalex.org/)
- [OpenAlex Terms of Service (PDF)](https://openalex.org/OpenAlex_termsofservice.pdf)
- [Crossref REST API Access and Authentication](https://www.crossref.org/documentation/retrieve-metadata/rest-api/access-and-authentication/)
- [Crossref REST API Rate Limit Changes Announcement](https://www.crossref.org/blog/announcing-changes-to-rest-api-rate-limits/)
- [Crossref REST API Metadata License Information](https://www.crossref.org/documentation/retrieve-metadata/rest-api/rest-api-metadata-license-information/)
- [ORCID Public API Registration Guide](https://info.orcid.org/documentation/integration-guide/registering-a-public-api-client/)
- [ORCID API Traffic Management Refinements (Feb 2025)](https://info.orcid.org/refining-api-traffic-management)
- [arXiv API User's Manual](https://info.arxiv.org/help/api/user-manual.html)
- [arXiv API Terms of Use](https://info.arxiv.org/help/api/tou.html)
- [Finance Conference Deadlines (tbeason)](https://tbeason.com/financeconferences/)
- [WikiCFP - Call For Papers](http://www.wikicfp.com/cfp/allcfp)
- [AREUEA Conference Calendar](https://www.areuea.org)
- [AFA Annual Meeting](https://afajof.org/annual-meeting/)
- [WFA Conference 2026](https://westernfinance.org/conference-2026/)
- [FMA Other Conferences](https://www.fma.org/other-conferences-and-programs)

---

## macOS menu bar app architecture research

A modern macOS menu bar app for agent CLI monitoring and LLM integration must use direct distribution (Developer ID + notarization + Sparkle) rather than the Mac App Store. The App Sandbox that the App Store mandates is a hard blocker for spawning external CLIs (Claude Code, Codex CLI) installed via Homebrew or npm at paths outside the app bundle. SwiftUI MenuBarExtra (macOS 13+, Ventura) provides a fast start for simple menus but has documented gaps: no programmatic show/hide binding, no access to the underlying NSStatusItem or NSWindow, and runloop blocking during menu display. Production apps (steipete's Vibe Meter, claude-usage-bar) combine an AppKit NSStatusItem with SwiftUI content in a custom NSPanel for full control. Background polling in a running LSUIElement agent is simplest with a plain Timer; NSBackgroundActivityScheduler handles low-priority maintenance at longer intervals but only runs on AC power and is best for 10+ minute cadences. The iOS-26 BGContinuedProcessingTask is explicitly unavailable on macOS. UserNotifications works on macOS via UNUserNotificationCenter with an explicit permission request. SMAppService (macOS 13+) is the current API for launch-at-login. An official Swift MCP SDK (modelcontextprotocol/swift-sdk, v0.12.1, May 2026) supports macOS 13+, stdio and HTTP/SSE transports, and is actively maintained. Steipete distributes all his macOS tools outside the App Store via GitHub Releases plus Sparkle appcasts using custom shell scripts.

### Key findings

- **SwiftUI MenuBarExtra vs AppKit NSStatusItem: capabilities and documented limits** _(high)_  
  Evidence: MenuBarExtra (macOS 13+) supports .menuBarExtraStyle(.window) for a popover and .menu for a pull-down menu, but Apple provides no public API to get/set presentation state, disable the extra, access the underlying NSStatusItem, or access the popup NSWindow. The MenuBarExtraAccess library works around this on macOS 13+. MenuBarExtra also blocks the runloop during menu display, preventing programmatic control while open. For production apps requiring persistent windows, custom positioning, HUD panels, or precise key-window behavior, the pattern is NSStatusItem + custom NSPanel with LSUIElement=YES in Info.plist to suppress the Dock icon. steipete's Vibe Meter uses this exact hybrid: Swift 6, SwiftUI views, AppKit NSPanel, and ImageRenderer to convert SwiftUI to NSImage for the status-item icon. macOS 26 Tahoe's Liquid Glass redesign removed the visible menu bar background but does not change these APIs.  
  Source: https://fazm.ai/blog/swiftui-menu-bar-app-floating-window-best-practices
- **App Sandbox hard-blocks spawning external CLIs not bundled in the app - a fatal constraint for App Store distribution when the goal is launching Claude Code or Codex CLI** _(high)_  
  Evidence: Apple's official guidance (confirmed by Quinn 'The Eskimo!' in Apple DTS): a sandboxed Mac App Store app may only launch helper tools embedded within the app bundle, correctly code-signed with com.apple.security.app-sandbox + com.apple.security.inherit and no other entitlements. Spawning /usr/local/bin/claude, ~/.nvm/bin/node, or any Homebrew/npm-installed binary is categorically blocked. The sandbox is inherited by child processes so the child cannot exceed the parent's rights. The workaround for bundled tools (e.g., bundling a copy of ffmpeg) is impractical for Claude Code or Codex CLI because those tools themselves pull in large dependency trees and may themselves require unsandboxed capabilities. The only viable path for spawning external agent CLIs is direct distribution without the App Sandbox.  
  Source: https://developer.apple.com/forums/thread/87849
- **Direct distribution (Developer ID + notarization + Sparkle) is the correct route; steipete's toolchain is a proven template** _(high)_  
  Evidence: Direct distribution requires an Apple Developer membership ($99/yr), Developer ID code signing, and notarization via notarytool before Gatekeeper will allow the app to run. No sandbox is required. steipete distributes Vibe Meter and Peekaboo outside the App Store via GitHub Releases (DMG files, signed and notarized) with Sparkle 2.x for auto-updates and separate appcasts for stable/pre-release channels hosted as raw GitHub URLs. He uses custom shell scripts: create-dmg.sh, generate-appcast.sh, release.sh. Key pitfall: do NOT use --deep when codesigning; sign each framework/XPC service individually in the correct bottom-up order. Sparkle's XPC services need specific mach-lookup entitlements in the app's entitlements file. claude-usage-bar uses the same pattern (DMG + Sparkle + GitHub Pages for appcasts). The hardened runtime (required for notarization) does not itself block Process/NSTask calls to external binaries in a non-sandboxed app.  
  Source: https://steipete.me/posts/2025/code-signing-and-notarization-sparkle-and-tears
- **Background execution and scheduling on macOS: Timer for running agents, NSBackgroundActivityScheduler for AC-only maintenance, no BGContinuedProcessingTask on macOS** _(high)_  
  Evidence: For an LSUIElement menu bar agent that is always running, a plain Swift Timer (or async Task with sleep) is sufficient for periodic web/API polling. NSBackgroundActivityScheduler (Foundation, macOS 10.10+) is designed for low-priority maintenance tasks with interval tolerances; it runs only when the Mac is on AC power, making it unsuitable for battery-critical polling. Apple's energy docs recommend NSBackgroundActivityScheduler for intervals of 10 minutes or more. The iOS BackgroundTasks framework classes BGAppRefreshTask, BGProcessingTask, and the new iOS-26 BGContinuedProcessingTask are all explicitly API_UNAVAILABLE(macos) - confirmed in Xcode 26 beta headers. For a non-interactive background daemon (e.g., an always-on poller even when the app is quit), a LaunchAgent plist in ~/Library/LaunchAgents is the macOS-native approach. macOS Tahoe 26 added a user-visible popup when apps attempt to register background daemons after being closed.  
  Source: https://github.com/dotnet/macios/wiki/BackgroundTasks-iOS-xcode26.0-b1
- **UserNotifications framework works on macOS and requires explicit user permission** _(high)_  
  Evidence: UNUserNotificationCenter is available on macOS and supports local notifications with title, subtitle, body, sound, and badge. Apps must call requestAuthorization(options:) at first launch; users can revoke permission at any time from System Settings. When the app is in the foreground, the userNotificationCenter(_:willPresent:withCompletionHandler:) delegate is called; when backgrounded, the system delivers the notification according to the user's settings. Works in both sandboxed and non-sandboxed apps. No special entitlement is required for local notifications (as opposed to push notifications, which require the push entitlement and APNs registration).  
  Source: https://developer.apple.com/documentation/usernotifications
- **Launch-at-login: SMAppService (macOS 13+) is the current API, replacing SMLoginItemSetEnabled** _(high)_  
  Evidence: SMAppService (ServiceManagement framework, macOS 13+) replaces the deprecated SMLoginItemSetEnabled and SMJobBless APIs. For a menu bar agent: SMAppService.mainApp.register() to add, .unregister() to remove, .status to check state. App Store guidelines require the feature to be opt-in (off by default) with an explicit toggle in app settings; Mac apps may not auto-launch at startup without user consent. Always read status from SMAppService rather than persisting locally because users can modify login items independently via System Settings > General > Login Items. The LaunchAtLogin-Modern Swift package wraps this into a SwiftUI Toggle for easy integration.  
  Source: https://nilcoalescing.com/blog/LaunchAtLoginSetting/
- **Web/API polling is simple; web scraping via WKWebView requires the network-client entitlement even in sandboxed apps** _(medium)_  
  Evidence: URLSession works out-of-the-box for REST and SSE API polling in any macOS app. For web scraping using WKWebView (for JS-rendered pages), the com.apple.security.network.client entitlement is required even in sandboxed apps - even when loading only local HTML. Without it, WKWebView silently fails. In a non-sandboxed direct-distribution app, URLSession and WKWebView work without entitlement declarations, though the hardened runtime may still require com.apple.security.network.client if sandbox is absent but hardened runtime is enabled (verify). For structured scraping of static HTML, URLSession + a Swift HTML parser (e.g., SwiftSoup) is lighter than WKWebView. For JavaScript-rendered pages, WKWebView with evaluateJavaScript is necessary.  
  Source: http://code.sylvaingamel.fr/2019/06/02/webkit-macos-entitlements.html
- **Official Swift MCP SDK is mature, actively maintained, and supports macOS 13+ with stdio and HTTP/SSE transports** _(high)_  
  Evidence: modelcontextprotocol/swift-sdk v0.12.1 was released May 7, 2026 and implements the 2025-11-25 MCP specification. It supports both client and server roles. Transport options: stdio (for spawning a local MCP server process), streamable HTTP with SSE (for remote MCP servers), and in-memory (for testing). Requires Swift 6.0+ (Xcode 16+) and macOS 13.0+. Distributed via Swift Package Manager, Apache 2.0 licensed. MacPaw and gsabran maintain separate forks with additional features. For connecting to Claude Code's MCP server mode or other local MCP servers via stdio, the SDK provides a ready-made StdioTransport. Network-based MCP connections use NetworkTransport (Apple-platforms only, depends on Network.framework).  
  Source: https://github.com/modelcontextprotocol/swift-sdk
- **Spawning and monitoring local agent CLIs (Process/NSTask and Swift 6.2 Subprocess) in a non-sandboxed app** _(medium)_  
  Evidence: Foundation's Process class (formerly NSTask) and Swift 6.2's new Subprocess package both support launching external CLIs, piping stdin/stdout/stderr, and monitoring termination. Swift Subprocess (Swift 6.2, macOS 13+) offers an async/await-friendly API with CollectedResult returning PID, termination status, stdout, and stderr. Both require removal of the App Sandbox in a non-sandboxed app. Child processes inherit the parent's environment, which means PATH, HOME, and credential files (e.g., ~/.claude) are available. For interactive two-way communication with a CLI agent (sending prompts and streaming output), use Pipe with asyncBytes on FileHandle. The Hardened Runtime does not block Process/subprocess calls to external binaries in non-sandboxed apps, but if the app uses the hardened runtime with the App Sandbox entitlement removed, most capabilities are unrestricted.  
  Source: https://dev.to/trozware/moving-from-process-to-subprocess-4408
- **macOS version landscape as of mid-2026: macOS 13 Ventura is the practical floor for new menu bar features** _(high)_  
  Evidence: macOS 26 Tahoe (current, released fall 2025), macOS 15 Sequoia, and macOS 14 Sonoma are the three supported major releases as of mid-2026. macOS 13 Ventura introduced MenuBarExtra, SMAppService, and is the minimum for the official Swift MCP SDK and Swift Subprocess. Targeting macOS 14+ is reasonable for a new app in 2026 to avoid Ventura edge cases, but macOS 13 is the documented minimum for the key APIs. macOS 26 Tahoe's Liquid Glass redesign changed the menu bar visual appearance but did not introduce new developer APIs for menu bar apps specifically.  
  Source: https://en.wikipedia.org/wiki/MacOS_Tahoe
- **steipete's apps are distributed outside the App Store via Developer ID / direct download** _(high)_  
  Evidence: Both Peekaboo (CLI + MCP server for AI screenshot capture, distributed via Homebrew and GitHub Releases/npm) and Vibe Meter (menu bar AI cost monitor, distributed as a DMG with Sparkle) are outside the Mac App Store. steipete uses custom shell scripts for the release pipeline and hosts appcast XML on GitHub (raw URLs). His code-signing post documents the full notarization flow with notarytool. No App Store sandbox is used. VibeTunnel is another product in his portfolio, also outside the App Store.  
  Source: https://steipete.me/posts/2025/vibe-meter-monitor-your-ai-costs

### Technical notes

DISTRIBUTION DECISION TREE: If the app needs to spawn Claude Code CLI or Codex CLI (or any Homebrew/npm-installed binary), the answer is unambiguously direct distribution with Developer ID + notarization. The App Store's mandatory App Sandbox makes this impossible without bundling the entire CLI and all its dependencies. For apps that only call LLM APIs directly via URLSession (no subprocess), the App Store is viable with the com.apple.security.network.client entitlement.

BACKGROUND POLLING ARCHITECTURE: For an LSUIElement menu bar agent that is always running, a Swift Timer (or Task + sleep in a structured concurrency context) is the simplest and most reliable approach for periodic API polling at intervals from seconds to hours. NSBackgroundActivityScheduler is only useful if you want opportunistic scheduling when the Mac is on AC power at 10+ minute intervals. There is no iOS-style background refresh on macOS - the app must remain running.

SUBPROCESS STREAMING: For launching Claude Code or Codex CLI and streaming their output, use Process (or Swift 6.2 Subprocess) with Pipe attached to standardOutput. Read from the pipe's fileHandleForReading using AsyncBytes for non-blocking streaming in Swift concurrency. Terminate via process.terminate() and observe process.terminationStatus. The subprocess inherits the parent's environment, so ~/.claude/credentials and other agent config files are automatically accessible.

MCP CLIENT PATTERN: To connect to Claude Code running in MCP server mode (claude --mcp-server), use the Swift MCP SDK's stdio transport: spawn claude as a subprocess, wire its stdin/stdout to the SDK's StdioTransport, and use the Client API to call tools. This avoids screen-scraping and gives structured JSON responses. Alternatively, call the Anthropic API directly via URLSession for simpler use cases that don't need MCP tooling.

SWIFT VERSION NOTE: Swift 6.2 Subprocess requires macOS 13+. If targeting macOS 12 or earlier, stick with Foundation.Process. For a 2026 app targeting macOS 13+ this is a clean choice.

STEIPETE STACK SUMMARY: Swift 6 + SwiftUI (views) + AppKit NSStatusItem/NSPanel (menu bar control) + ImageRenderer (SwiftUI to NSImage for icon) + Sparkle 2.x (updates) + GitHub Releases (distribution) + custom shell scripts (release pipeline). No App Store, no sandbox. This is the reference architecture for this class of app.

### Product opportunities

- A menu bar app that spawns Claude Code or Codex CLI as subprocesses and streams their output is only viable as direct-distribution (non-sandboxed); this same constraint creates a natural moat vs App Store competitors who cannot access the CLIs
- The official Swift MCP SDK (v0.12.1, macOS 13+) enables connecting to Claude Code's MCP server mode via stdio without screen-scraping, enabling structured tool-call results in a native Swift app
- NSBackgroundActivityScheduler's AC-power-only constraint means a menu bar poller should degrade gracefully on battery - surfacing a 'paused on battery' state in the UI is a small UX win
- Combining direct LLM API calls (URLSession to Anthropic/OpenAI) with optional subprocess spawning (claude --mcp-server for richer context) gives the app a sandboxed-friendly fallback mode (API-only) alongside a power-user mode (CLI subprocess)

### Risks

- App Sandbox is mandatory for Mac App Store; spawning system-installed CLIs (claude, codex, node) is categorically blocked - no entitlement workaround exists for binaries outside the app bundle
- BGContinuedProcessingTask is iOS 26+ only and explicitly API_UNAVAILABLE(macos) - cannot be used for macOS background scheduling
- NSBackgroundActivityScheduler only fires on AC power - polling stops silently on battery unless a fallback Timer is also running
- Swift MCP SDK is still pre-1.0 (v0.12.1); API stability is not guaranteed between minor versions
- Hardened Runtime (required for notarization) blocks some dynamic library loading and JIT compilation by default; if the spawned CLI uses those features, the subprocess itself is unaffected but the parent app may need com.apple.security.cs.allow-unsigned-executable-memory or similar entitlements to be verified
- Sparkle XPC service codesigning is finicky: using --deep corrupts XPC signatures; components must be signed bottom-up individually; missing mach-lookup entitlements silently break the update check
- macOS 26 Tahoe's Liquid Glass menu bar redesign (no visible background) may require icon/UI adjustments for visual consistency - test on Tahoe beta before shipping

### Claims flagged for verification

- Whether a non-sandboxed app using the Hardened Runtime (required for notarization) still needs com.apple.security.network.client explicitly declared, or whether the absence of the App Sandbox entitlement makes the network entitlement irrelevant
- NSBackgroundActivityScheduler's AC-power-only behavior: whether this is a hard system rule or a 'preference' that can be overridden via the toleranceDelta and qualityOfService settings
- Whether Swift Subprocess (Swift 6.2) introduces any new restrictions under the Hardened Runtime that differ from the older Process/NSTask API when spawning external CLIs
- Swift MCP SDK v0.12.1 production readiness: the SDK version numbering (still sub-1.0) may indicate API instability; verify whether the stdio transport is reliable for long-running Claude Code MCP sessions
- Whether macOS 26 Tahoe introduced any new developer-facing APIs for menu bar apps (beyond the Liquid Glass visual changes) that affect NSStatusItem, MenuBarExtra, or background scheduling
- Whether the com.apple.security.network.client entitlement is required when using WKWebView in a hardened-runtime non-sandboxed app, or only in explicitly sandboxed apps
- Exact entitlements needed for Sparkle 2.x XPC services under Hardened Runtime without App Sandbox (steipete documents mach-lookup entries but the exact set should be verified against the current Sparkle 2.x docs)

### Citations

- [Build a macOS menu bar utility in SwiftUI - nilcoalescing.com](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/)
- [SwiftUI Menu Bar App With a Floating Window: Best Practices - fazm.ai](https://fazm.ai/blog/swiftui-menu-bar-app-floating-window-best-practices)
- [MenuBarExtraAccess - orchetect/MenuBarExtraAccess on GitHub](https://github.com/orchetect/MenuBarExtraAccess)
- [Vibe Meter: Monitor Your AI Costs - Peter Steinberger](https://steipete.me/posts/2025/vibe-meter-monitor-your-ai-costs)
- [Code Signing and Notarization: Sparkle and Tears - Peter Steinberger](https://steipete.me/posts/2025/code-signing-and-notarization-sparkle-and-tears)
- [Apple Developer Forums: sandboxed app with additional binaries (Quinn DTS)](https://developer.apple.com/forums/thread/87849)
- [Apple Developer Forums: App Sandbox outgoing connections](https://developer.apple.com/forums/thread/744961)
- [Sandbox Inheritance Tax - Indie Stack](https://indiestack.com/2017/09/sandbox-inheritance-tax/)
- [NSBackgroundActivityScheduler - Apple Developer Documentation](https://developer.apple.com/documentation/foundation/nsbackgroundactivityscheduler)
- [Energy Efficiency Guide for Mac Apps: Schedule Background Activity - Apple](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/SchedulingBackgroundActivity.html)
- [BackgroundTasks iOS xcode26.0 b1 (confirms BGContinuedProcessingTask is API_UNAVAILABLE(macos)) - dotnet/macios Wiki](https://github.com/dotnet/macios/wiki/BackgroundTasks-iOS-xcode26.0-b1)
- [User Notifications - Apple Developer Documentation](https://developer.apple.com/documentation/usernotifications)
- [Add launch at login setting to a macOS app - nilcoalescing.com](https://nilcoalescing.com/blog/LaunchAtLoginSetting/)
- [SMAppService - Apple Developer Documentation (via macOS Service Management theevilbit blog)](https://theevilbit.github.io/posts/smappservice/)
- [Don't forget entitlements for WebKit! - sylvaingamel.fr](http://code.sylvaingamel.fr/2019/06/02/webkit-macos-entitlements.html)
- [Official Swift SDK for Model Context Protocol - modelcontextprotocol/swift-sdk](https://github.com/modelcontextprotocol/swift-sdk)
- [Moving from Process to Subprocess - DEV Community](https://dev.to/trozware/moving-from-process-to-subprocess-4408)
- [Energy-efficient long polling in macOS - Raul Riera on Medium](https://raulriera.medium.com/energy-efficient-long-polling-in-macos-67453ac4dafa)
- [claude-usage-bar - Blimp-Labs on GitHub](https://github.com/Blimp-Labs/claude-usage-bar)
- [Peekaboo - steipete/Peekaboo on GitHub](https://github.com/steipete/Peekaboo)
- [Distributing Mac apps outside the App Store - Rambo Codes](https://www.rambo.codes/posts/2021-01-08-distributing-mac-apps-outside-the-app-store)
- [Mac App Store vs Direct Distribution 2026 - hendoi.in](https://www.hendoi.in/blog/mac-app-store-vs-direct-distribution-macos-app-2026)
- [Finish tasks in the background - WWDC25 Session 227](https://developer.apple.com/videos/play/wwdc2025/227/)
- [macOS Tahoe - Wikipedia](https://en.wikipedia.org/wiki/MacOS_Tahoe)

---

## corbis-integration-surface

The Corbis Research Plugin (v1.0.16) exposes 19 MCP tools via a single HTTP endpoint at https://www.corbis.ai/api/mcp/universal. Auth supports two modes: OAuth (default for plugin installs, no key required to start) and API key (via Bearer header or ?apikey= query param, recommended for unattended/desktop workflows). All 14 standard-tier tools are available on every paid plan; 5 enterprise-only web-research tools require a custom contract. Credits cost 1 per tool call (Free=50 lifetime, Academic=$30/1000, Pro=$199/5000). Rate limits are 200 req/hr and 10 concurrent. The plugin itself ships 62 skills (61 non-scaffolder plus the project scaffolder), 18 specialist agents, and 16 slash commands -- these are Claude Code skill workflows, not REST endpoints, so a macOS app cannot call them directly without an LLM intermediary. The strongest integration hooks for a desktop app are: the stateless HTTP MCP endpoint (trivially callable from Swift with a Bearer token), the search_papers tool which returns citedByCount per result enabling citation tracking, and the two-step identity flow (find_academic_identity + confirm_academic_identity) that links a researcher to their OpenAlex profile. Notable gaps include no author-publication-list endpoint, no h-index or career metrics, no download counts, and no forward-citation lookup. Four tool names asked about in the brief (verify_bibtex, get_paper_details_batch, get_metric_definitions, screen_markets) do not appear in the documented API or tool catalog.

### Key findings

- **MCP endpoint and auth** _(high)_  
  Evidence: plugin/.mcp.json and CORBIS_MCP_CLAUDE_CODE_GUIDE.md both confirm the single universal endpoint: https://www.corbis.ai/api/mcp/universal. Auth: OAuth (plugin default, no config needed for first use) or API key via ?apikey=KEY in URL or Authorization: Bearer KEY header. The bundled .mcp.json intentionally ships keyless so first plugin use is not blocked.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/plugin/.mcp.json
- **Rate limits and pricing** _(high)_  
  Evidence: CORBIS_MCP_CLAUDE_CODE_GUIDE.md states 200 requests/hour, 10 concurrent requests, 1 credit per call. Plans: Free=50 (one-time, no reset), Starter=250 at $20/mo, Basic=1000 at $49/mo, Academic=1000 at $30/mo, Pro=5000 at $199/mo, Enterprise=unlimited at custom price.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_MCP_CLAUDE_CODE_GUIDE.md
- **19 documented MCP tools in 6 categories; 14 standard, 5 enterprise** _(high)_  
  Evidence: CORBIS_API_REFERENCE.md and plugin/corbis-mcp-tools.json enumerate all 19 tools. Standard (all tiers): search_papers, get_paper_details, top_cited_articles, search_datasets, format_citation, export_citations, fred_search, fred_series_batch, get_national_macro, get_market_data, compare_markets, search_markets, find_academic_identity, confirm_academic_identity. Enterprise only: literature_search, internet_search, read_web_page, deep_research, query_corbis.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md
- **search_papers returns citedByCount per result; no download counts** _(high)_  
  Evidence: CORBIS_API_REFERENCE.md documents the return fields for search_papers as: id, title, authors, year, journal, abstract, doi, openalexId, url, citedByCount, semanticScore, keywordScore, combinedRank. Download or view counts are not mentioned anywhere in the API reference or tool catalog.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md
- **Identity tools are user-centric and OpenAlex-backed; also usable for coauthor lookup** _(high)_  
  Evidence: find_academic_identity takes optional nameOverride and institutionOverride to search OpenAlex for a profile. confirm_academic_identity takes action (accept/clear), authorId (OpenAlex ID), authorName, confidenceScore to link or unlink the account. research-paper-writer SKILL.md also calls find_academic_identity with an author name to look up coauthor profiles. The tools do not expose an author publications list or career metrics (h-index, total citations) -- only the OpenAlex ID link.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md
- **Plugin ships 62 skills, 18 agents, 16 commands -- these are LLM workflow layers, not REST endpoints** _(high)_  
  Evidence: plugins/corbis-research-plugin/.claude-plugin/plugin.json states '61 shipped non-scaffolder skills plus 1 project scaffolder, 18 WRDS and research agents, 16 commands'. Skills and agents are Claude Code skill workflows defined as Markdown prompting files. A macOS app cannot invoke them as REST calls; they require an LLM runtime (Claude API) with the skill loaded as system context.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/plugins/corbis-research-plugin/.claude-plugin/plugin.json
- **verify_bibtex and get_paper_details_batch are not documented Corbis MCP tools** _(high)_  
  Evidence: A full-text search across all .md, .json, and .py files finds no verify_bibtex anywhere. get_paper_details_batch appears only in a single line of the idea-pivot-loop SKILL.md (line 205) as a slash-notation variant of get_paper_details ('Corbis get_paper_details / get_paper_details_batch'), but it is absent from CORBIS_API_REFERENCE.md, corbis-mcp-tools.json, mcp-index.json, and the CORBIS_MCP_CLAUDE_CODE_GUIDE.md. It is not a documented callable tool.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/plugin/corbis-mcp-tools.json
- **screen_markets and get_metric_definitions do not exist in the codebase** _(high)_  
  Evidence: Full-text grep across the entire repository returns zero matches for screen_markets or get_metric_definitions in any file. The closest market tool is search_markets (rank metros by a metric key). These are not Corbis tools in the current version.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md
- **Per-key Research Defaults enable app-side personalization without per-call filtering** _(high)_  
  Evidence: CORBIS_MCP_CLAUDE_CODE_GUIDE.md documents per-key settings at https://www.corbis.ai/settings?tab=keys: Tool Access (restrict to plan tools), Execution Defaults (model, max steps, max tokens, reasoning level), Research Defaults (default journal whitelist up to 10, default min/max year, additional instructions up to 2000 chars). These defaults are applied server-side before tool dispatch, so a desktop app can personalize search behavior per user without embedding filter logic in every call.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_MCP_CLAUDE_CODE_GUIDE.md
- **Four recommended tool chains for a macOS app's core use cases** _(high)_  
  Evidence: From CORBIS_API_REFERENCE.md recommended chains: (i) Identity resolution: find_academic_identity then confirm_academic_identity. (ii) Paper/citation tracking: search_papers (by author name or topic), get_paper_details (full metadata incl. citedByCount and abstract). (iii) Related/new work discovery: search_papers + top_cited_articles + search_datasets. (iv) Research agent launch: the 18 agents are Claude Code workflows -- a macOS app triggers them by calling Claude API with MCP tools enabled and the relevant SKILL.md loaded as system context, not via a direct REST call to corbis.ai.  
  Source: /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/CORBIS_API_REFERENCE.md

### Technical notes

MCP endpoint: https://www.corbis.ai/api/mcp/universal (HTTP, stateless). Auth: Authorization: Bearer KEY header or ?apikey=KEY query param. The bundled .mcp.json at plugin/.mcp.json and plugins/corbis-research-plugin/.mcp.json are identical and intentionally keyless (OAuth-capable default). For a macOS app, use the Bearer header form. Tool call format follows the MCP protocol (JSON-RPC over HTTP). Plugin manifest: plugins/corbis-research-plugin/.claude-plugin/plugin.json (v1.0.16). Tool catalog source: plugin/corbis-mcp-tools.json (19 entries). Full parameter schemas: CORBIS_API_REFERENCE.md. Generated indexes (skill/agent/command/mcp) are in plugins/corbis-research-plugin/generated/. Skills are Markdown files under plugins/corbis-research-plugin/skills/; agents under plugins/corbis-research-plugin/agents/. Neither is directly invocable via HTTP -- both require a Claude Code or Claude API runtime.

### Product opportunities

- Single Bearer-auth HTTP MCP endpoint makes direct integration from a Swift/macOS app simple without a separate SDK -- any URLSession call with Authorization: Bearer <key> to https://www.corbis.ai/api/mcp/universal can invoke any of the 14 standard tools.
- Per-key Research Defaults (journal whitelist, year range, additional instructions) allow a macOS app to store personalized search preferences server-side keyed to the researcher's API key, reducing per-call overhead.
- search_papers returns citedByCount per paper, enabling the app to sort or highlight highly-cited results and build a lightweight citation-count dashboard without a separate bibliometrics API.
- Two-step identity flow (find_academic_identity + confirm_academic_identity) provides a natural onboarding screen: search OpenAlex candidates by name/institution, let the user confirm the match, and store the resulting OpenAlex author ID to personalize future searches.
- find_academic_identity accepts nameOverride so the app can also resolve coauthor identities, enabling a coauthor network or collaboration view.
- export_citations with format bibtex or json provides a clean clipboard/export path for any paper set the user saves in the app.
- FRED tools (fred_search + fred_series_batch) are ready-to-use data feeds for embedding macro trend charts alongside research content with no additional data contract.
- CRE market tools (get_market_data, compare_markets, search_markets) expose a U.S. metro-level intelligence layer useful for a real estate research angle with rankings, trends, and side-by-side comparisons.

### Risks

- Rate limit of 200 req/hr at standard tiers will constrain a search-as-you-type UI or any feature that fires multiple parallel tool calls per user action; the app must batch requests or cache aggressively.
- Enterprise-only wall: internet_search, read_web_page, deep_research, literature_search, and query_corbis are unavailable below enterprise. A macOS app targeting non-enterprise researchers cannot offer live web search or multi-step deep research without a separate web-search provider.
- No author-publication-list endpoint: the app cannot retrieve 'all papers by researcher X' in one call. Workaround is a name-based search_papers query with author-name terms, but this will miss papers and cannot be sorted or paginated reliably.
- No h-index, career citation count, or impact metrics: find_academic_identity/confirm_academic_identity only links to an OpenAlex ID. The app would need to call the OpenAlex REST API directly to retrieve career-level metrics for the linked profile.
- No forward-citation lookup ('papers that cite paper X'): search_papers is topical, not relational. A 'who cites this paper' feature would require a direct OpenAlex API call.
- No download or altmetric counts: only citedByCount is returned. Impact signals beyond citations are not in the documented API.
- get_paper_details_batch is referenced in one skill file but not in the documented API -- the app cannot rely on it for batched paper lookups and must loop over individual get_paper_details calls, consuming one credit each.
- Skills and agents (62 skills, 18 agents) are Claude Code prompting workflows, not callable REST endpoints. Launching them from a macOS app requires routing through a Claude API completion call with the skill Markdown loaded as context, adding Claude API cost and latency on top of Corbis credits.

### Claims flagged for verification

- get_paper_details_batch: mentioned in idea-pivot-loop/SKILL.md line 205 as a variant but absent from the official API reference and all tool catalogs. Verify with Corbis whether this tool is available on the MCP endpoint.
- find_academic_identity exact return schema: the API reference documents input parameters but does not specify the fields returned (candidate list structure, confidence scores, OpenAlex work counts). Verify against the live API or Corbis documentation.
- Whether citedByCount in search_papers reflects real-time OpenAlex counts or a cached snapshot, and the update cadence.
- Whether the OpenAlex author ID returned/linked by confirm_academic_identity can then be used as an input to search_papers (e.g., via an openalexAuthorId filter parameter not shown in the current API reference) to retrieve that author's papers.
- Corpus size: CORBIS_API_REFERENCE.md states 265,000+ academic papers. This is the figure in the repo documentation; do not quote publicly without verifying the current live count at corbis.ai.
- Whether the Corbis server supports CORS headers that would allow a macOS WKWebView or direct fetch from a sandboxed Swift process, vs. requiring a local proxy.
- Enterprise-tier pricing and whether academic institutions can negotiate an Academic-to-Enterprise upgrade path.

---

## Competitive Landscape: Academic Publication Tracking and Research Discovery Tools

The academic publication tracking market in mid-2026 is fragmented across roughly four categories: (1) citation-count dashboards anchored to Google Scholar (Scholar profiles, CiteBar, Publish or Perish), (2) institutional bibliometric databases gated behind large institutional licenses (Scopus, Web of Science, Dimensions), (3) literature discovery and visualization tools primarily aimed at general science (Semantic Scholar, Litmaps/ResearchRabbit, Connected Papers, Scite, ResearchRabbit), and (4) paper-feed aggregators focused on reading rather than tracking (R Discovery, SSRN eJournals, Scholarcy). The only existing macOS menu bar native app is CiteBar (MIT-licensed, free), which tracks solely Google Scholar h-index and 30-day citation growth with no domain intelligence or alerts. No tool combines always-on citation monitoring, SSRN finance working-paper alerts, economic data freshness, CRE market context, and agentic briefing into a single native desktop surface. The Litmaps acquisition of ResearchRabbit in May 2025 consolidated the visualization space and introduced freemium pricing where free access previously existed, creating some user dissatisfaction. Finance and real estate researchers are underserved by all existing tools: SSRN eJournal emails are the primary working-paper alert mechanism for most finance academics, and they arrive as unstructured email with no aggregation, filtering, or cross-referencing against the researcher's own work.

### Key findings

- **Google Scholar Profiles + Email Alerts** _(high)_  
  Evidence: Free. Web only. Provides public author profile with h-index, total citations, citation-by-year chart, and email alerts for new citations to any paper in the profile or new papers from followed authors. Users can choose auto-update or manual curation of their article list. No API for programmatic access. No download metrics. Alert granularity is paper-level only; no keyword- or topic-level alerts. No macOS native client. Widely used as the de facto free citation counter for all academic disciplines.  
  Source: https://scholar.google.com/intl/en/scholar/citations.html
- **Publish or Perish (Harzing) - free desktop app, macOS v8 native** _(high)_  
  Evidence: Free for non-commercial use. macOS native (v8.19.5300, December 2025), Universal Binary for Intel and Apple Silicon, macOS 10.13+. Also Windows. Retrieves and analyzes citations from Google Scholar and other sources to compute h-index, g-index, total citations, and a range of other bibliometric statistics on demand. Not an always-on monitoring tool: the researcher must manually run queries. No push alerts, no visualization, no related-work discovery, no deadline tracking. Strong for batch analysis of a body of work or a journal.  
  Source: https://harzing.com/resources/publish-or-perish/os-x
- **ResearchGate - social network with citation and reads metrics** _(high)_  
  Evidence: Free. Web and iOS/Android. Provides per-paper reads, downloads, citations, recommendations, and citation alerts. Enables preprint sharing and Q&A with co-authors. Heavy social-network orientation (followers, mentions, profile views). Coverage gaps in economics and finance relative to medical and natural sciences. Finance researchers often find their papers are unclaimed or misattributed. No macOS native client, no domain-specific intelligence, no deadline management.  
  Source: https://www.scijournal.org/articles/best-tools-for-tracking-research-impact-and-citations
- **Academia.edu - paper sharing with gated analytics** _(high)_  
  Evidence: Free basic; approximately $100/year Premium (annual-only, no monthly option). Web and mobile. Core value is document hosting and discovery; Premium unlocks detailed viewer analytics (who viewed, institutional affiliation of viewers), citation notifications, and advanced search filters. Coverage and prestige in economics/finance is modest compared to SSRN or Google Scholar. Heavily criticized for using paywalled analytics as bait to upsell free users. No macOS native client.  
  Source: https://support.academia.edu/hc/en-us/articles/29297378153623-Academia-Free-vs-Premium-What-features-do-I-get-on-Academia
- **Semantic Scholar - best free general-purpose literature intelligence platform** _(high)_  
  Evidence: Fully free. Web only. 214M+ papers. Features: TLDRs (AI one-sentence summaries, strongest coverage in CS and biomedical), Highly Influential Citation detection, Research Feeds (personalized paper recommendations from folder contents), three alert types (new citations to a paper, new papers by an author, feed-based recommendations), Ask This Paper (Q&A on individual papers), author pages with claim flow, bulk citation export, shareable public folders. Free API with recommendation endpoint. No macOS native client, no deadline tracking. TLDR and Topics features are significantly weaker in economics and finance than in CS/bio.  
  Source: https://www.semanticscholar.org/product
- **Scopus (Elsevier) - institutional database, no personal subscription** _(high)_  
  Evidence: Institutional license only; typical cost $10,000–$40,000/year for a university. No individual subscription available. Web only. Features: comprehensive author profiles with h-index, citation counts, affiliation history, document citation alerts, author citation and new-document alerts, journal ranking tools, affiliation tracking, self-citation filtering. Coverage of economics and finance journals is strong. A researcher without institutional access has no path to subscribe individually.  
  Source: https://belmont.libguides.com/Scopus/Alerts
- **Web of Science (Clarivate) - gold standard for bibliometrics, institutional only** _(high)_  
  Evidence: Institutional license only; typical cost $15,000–$60,000/year. Very limited free tier (account creation without content subscription). Web only. Features: century-long citation coverage, Cited Reference Search, Author Alerts for new publications and new citations, h-index calculation, Journal Citation Reports integration. Considered gold standard for historical citation analysis and bibliometrics research. No individual plan, no macOS client, no agentic features.  
  Source: https://webofscience.zendesk.com/hc/en-us/articles/20016619487889-Author-Alerts
- **Dimensions.ai - linked research graph, free individual tier exists** _(high)_  
  Evidence: Free for individual use (limited); institutional licenses estimated $10,000–$50,000/year for full analytics. Web + API. Features: 112M+ linked publications, 1.3B+ citations, 5.6M+ grants worth $1.7T, 41M+ patents, 600K+ clinical trials, AI assistant (summarization), Dimensions Research GPT (ChatGPT integration), Analytics API v2.13, Research Security API. The grant and patent linkage is unique in this landscape. No macOS native client. Domain-agnostic; no finance/RE specialization.  
  Source: https://www.dimensions.ai/products/artificial-intelligence/
- **ResearchRabbit (acquired by Litmaps, May 2025) - citation network visualization** _(high)_  
  Evidence: Litmaps acquired ResearchRabbit in May 2025, simultaneously raising NZD $1.4M, bringing combined user base above 2 million. Pre-acquisition ResearchRabbit was fully free; post-acquisition it was re-released in November 2025 as freemium (free tier capped at 50 inputs; premium at approximately $12.50/month). Features: multi-seed citation network discovery, search-history trace, Zotero import, collections, author exploration, monitoring alerts. Web only. Finance/RE coverage is general-science breadth, not domain-specialized.  
  Source: https://www.scoop.co.nz/stories/BU2505/S00127/nz-startup-litmaps-acquires-us-rival-and-raises-1m-to-accelerate-ai-driven-research-worldwide.htm
- **Litmaps - visual citation mapping with monitoring, now includes ResearchRabbit** _(high)_  
  Evidence: Freemium: free tier for small projects; $12.50/month premium (75% discount for students and faculty). Web only. Features: visual citation maps with axes (publication date, citation count), semantic search, monitoring alerts for new papers, co-authorship search, map sharing, Zotero integration. Rated highest in usability among literature discovery tools. No macOS native client, no finance/RE specialization, no deadline tracking. Actively growing post-acquisition.  
  Source: https://effortlessacademic.com/litmaps-vs-researchrabbit-vs-connected-papers-the-best-literature-review-tool-in-2025/
- **Connected Papers - single-seed graph visualization, low-cost** _(high)_  
  Evidence: Free: 5 graphs/month. Paid: $3/month academic, $15/month business. Web only. Features: single-paper input generates a graph of related prior and derivative works, open-access filter, year distribution visualization, list view with sorting. Very fast and simple. Weaknesses: limited to one input paper, no Zotero integration, minimal recent feature development, no alerts or monitoring.  
  Source: https://aihungry.com/tools/connected-papers/pricing
- **Scite - Smart Citations with supporting/contrasting classification** _(high)_  
  Evidence: Free basic; personal plan $20/month ($12/month annual); enterprise custom pricing. Web. Features: 280M+ papers in licensed database, Smart Citations that classify each citation as supporting, contrasting, or mentioning (derived from full-text), Ask Scite AI assistant for literature queries, citation context snippets, search by claim. Unique differentiation is citation stance classification. No macOS native client, no deadline tracking, no domain-specific alerts.  
  Source: https://aichief.com/ai-education-tools/scite-ai/
- **Scholarcy - AI paper summarization tool, not a tracking tool** _(high)_  
  Evidence: Free tier: 3 summaries/day. Paid: approximately $7.99–$9.99/month (around $90/year). Web and browser extension. Features: converts PDFs and Word documents into structured summaries and flashcards, extracts figures/tables, links to open-access versions of cited sources, text-to-speech (paid), Zotero integration. Scholarcy is a reading-acceleration tool, not a citation tracker or publication monitor. No author profile, no alerts, no macOS native client.  
  Source: https://www.toolsforhumans.ai/ai-tools/scholarcy
- **R Discovery (Researcher app) - mobile-first paper feed, not a tracking tool** _(high)_  
  Evidence: Freemium: free basic; $12/month Prime. Web, iOS, Android, Chrome extension. Features: 300M+ papers, 43M+ open-access, AI-powered recommendation feeds, audio papers (30+ languages), paper translation, Chat PDF, literature review generation. Primarily a reading and discovery app; does not track the researcher's own citation counts, h-index, or paper metrics. No macOS native client. No deadline tracking.  
  Source: https://discovery.researcher.life/
- **CiteBar - the only existing macOS menu bar citation tracker** _(high)_  
  Evidence: Free, MIT open source. macOS only (Universal Binary, Intel + Apple Silicon, notarized). Features: monitors Google Scholar profile in the menu bar, shows h-index at a glance, tracks 30-day citation growth, supports multiple profiles (own + collaborators/advisors), stores data locally with no telemetry. Gaps: Google Scholar only (no SSRN, Semantic Scholar, or Scopus), no related-work discovery, no deadline or conference tracking, no domain-specific data feeds, no agentic AI briefing, no alerts for new papers in a field.  
  Source: https://www.citebar.org/
- **SSRN eJournals - the de facto working-paper alert channel for finance researchers** _(high)_  
  Evidence: Free individual subscriptions. Email-only delivery. The Financial Economics Network (FEN) operates 300+ specialized eJournals across asset pricing, corporate finance, banking, real estate finance, and related areas. Subscribers receive weekly email digests listing new paper titles, authors, and abstracts with download links. This is the primary mechanism by which most finance and real estate academics learn about new working papers, but it is email-only, has no dashboard, no cross-referencing against the researcher's own work, no visualization, and no integration with citation tracking.  
  Source: https://www.ssrn.com/index.cfm/en/fen/fen-ejournals/
- **Unmet need: no always-on, finance-domain-aware, macOS-native research dashboard exists** _(high)_  
  Evidence: CiteBar covers Google Scholar h-index only. Publish or Perish requires manual on-demand queries. SSRN eJournals deliver email with no aggregation. Semantic Scholar provides good general alerts but no finance/CRE specialization, no FRED data freshness, no conference deadline calendar, and no macOS native presence. No tool today combines: (a) own-citation monitoring, (b) SSRN finance preprint alerts filtered by subfield, (c) FRED/CRE economic data release calendar, (d) related-work discovery tied to the researcher's active projects, and (e) an always-on macOS menu bar surface with agentic AI briefing.  
  Source: https://effortlessacademic.com/litmaps-vs-researchrabbit-vs-connected-papers-the-best-literature-review-tool-in-2025/
- **Corbis differentiation: finance and real estate domain depth no general tool can match** _(high)_  
  Evidence: Corbis MCP tools (search_papers, get_market_data, compare_markets, fred_search, fred_series_batch, get_national_macro, search_datasets) cover the exact data layers that finance and CRE academics need alongside citation tracking: economic data release cadence, MSA/metro-level CRE market intelligence, FRED macro indicators, and domain-specific literature search. No existing tool integrates these layers. A Corbis-backed menu bar dashboard could surface: citation alerts + SSRN finance preprint digests + FRED release calendar + CRE market updates + agentic 'what changed this week in my literature' briefing.  
  Source: https://www.citebar.org/

### Technical notes

CiteBar (https://www.citebar.org/, MIT license, Swift, Universal Binary) is the only open-source macOS menu bar citation tracker and is the most direct prior art for a Corbis-backed menu bar dashboard. It uses public Google Scholar profile URLs (scholar.google.com/citations?user=XXXXXXX format) and stores data locally with no telemetry. Semantic Scholar's public API (api.semanticscholar.org) provides programmatic access to paper metadata, author data, and recommendations without rate-limiting concerns that plague Google Scholar scraping; it is the recommended backend for citation and related-paper data. SSRN FEN eJournals can be subscribed to for free and deliver email; parsing these programmatically or building on top of Corbis search_papers with a finance-domain filter is a viable alternative to direct SSRN API access. Corbis MCP tools that are most relevant to the dashboard opportunity: search_papers (literature monitoring), fred_search + fred_series_batch (data release tracking), get_market_data + compare_markets (CRE market pulse), get_national_macro (macro controls), and search_datasets (data availability for new projects). The ResearchRabbit 2025 revamp (noted at aarontay.substack.com) introduced iterative chaining without visual clutter, suggesting the visualization-discovery space is still evolving and not fully settled.

### Product opportunities

- macOS menu bar native dashboard that aggregates Google Scholar citation counts, Semantic Scholar author metrics, and SSRN download stats into a single glanceable surface - the gap CiteBar only partly fills and only for Google Scholar.
- Finance/real estate domain-filtered SSRN preprint digest: instead of raw email, an agentic layer that reads FEN eJournals, filters by the researcher's active subfields (asset pricing, CRE, mortgage finance, etc.), and surfaces only the papers most likely to be relevant to the researcher's current projects - no existing tool does this.
- FRED economic data release calendar integrated with a research dashboard: notify the researcher when data series relevant to their empirical work (housing starts, interest rates, employment) are updated, directly tied to the project's data plan.
- CRE market data pulse tied to ongoing projects: when metro-level CRE metrics change materially, flag the researcher whose project uses that market - Corbis get_market_data and compare_markets tools already enable this.
- Agentic 'what changed in my literature this week' briefing: a scheduled agent (e.g., weekly) that runs Corbis search_papers against the researcher's defined topic space, diffs against previously seen papers, and summarizes truly new developments - no existing tool provides this autonomous briefing.
- Conference and journal deadline calendar for finance/RE: JF, JFE, RFS, JFQA, RoF, REE, JREFE, JRER submission windows, special issue calls, and major conference deadlines (AFA, WFA, EFA, AREUEA) in a persistent, always-visible macOS overlay - completely absent from all existing tools.
- Cross-referencing new preprints against the researcher's own working papers to flag overlap, priority risk, or complementarity - a capability that requires both literature search and awareness of the researcher's own corpus, which Corbis + a project context store would uniquely enable.

### Risks

- Google Scholar rate limits and scraping terms of service: CiteBar is open-source and works today, but Google Scholar has previously blocked automated access; a Corbis-backed tool relying on Scholar data would need to use the researcher's own authenticated session or Semantic Scholar's API as a fallback.
- SSRN does not expose a public API for eJournal contents; parsing SSRN alert emails or scraping the FEN eJournal pages may violate Elsevier terms of service, requiring a licensed data partnership or a Semantic Scholar API workaround.
- Litmaps (post-ResearchRabbit acquisition) is well-capitalized relative to its size (NZD $1.4M raised, 2M+ users) and could add macOS native functionality or a finance-focused vertical, closing part of the gap.
- Semantic Scholar is fully free and adding features continuously; if it adds macOS native presence or finance-domain metadata, it would compete directly on the discovery side.
- The macOS menu bar is a constrained UI surface; delivering meaningful research intelligence without overwhelming the researcher requires careful UX design and a clear information hierarchy.
- Maintaining data freshness (citation counts, FRED releases, CRE market data) on a push basis requires a background agent or daemon running on the researcher's Mac, which raises battery, privacy, and permission-prompt considerations.
- Finance journal citation lags: top finance journals often take 2-4 years from submission to publication, meaning citation spikes are slow and infrequent; the daily-dashboard value proposition needs to be anchored on preprint monitoring and data freshness, not just citation ticks.

### Claims flagged for verification

- Dimensions.ai individual free-tier limitations versus paid tier: the boundary between what individual researchers can access for free vs. what requires an institutional license is not precisely documented publicly and the $10K–$50K institutional pricing estimate came from a secondary review site, not Dimensions official pricing.
- Scopus has no individual subscription pathway whatsoever: some sources suggest limited individual access may exist in certain markets or via Elsevier bundling; this needs verification against the Elsevier/Scopus sales page directly.
- Web of Science has no individual researcher subscription: one third-party site (MeduStudy) listed a '1-year Subscription' product implying some individual purchase may exist; the official Clarivate page should be checked.
- Scite pricing: $20/month personal vs $12/month annual ($29/month pro in another source) - exact current tier names and prices vary across review sites and may have changed; verify against scite.ai pricing page.
- ResearchRabbit free tier capped at 50 inputs post-acquisition: this figure appeared in one review article; the official ResearchRabbit/Litmaps pricing page should be the source of truth.
- Litmaps premium at $12.50/month with 75% educational discount: the educational discount amount was cited in one review; the official Litmaps Pro page should be verified.
- Academia.edu premium is annual-only at approximately $100/year: Inside Higher Ed piece from an earlier year cited $99/year; current pricing may have changed.
- Dimensions institutional license pricing ($10K–$50K): this range appeared on a secondary AI review site (VisionSpark Solutions), not from Dimensions directly, and should be treated as an estimate.

### Citations

- [Google Scholar Profiles - official description](https://scholar.google.com/intl/en/scholar/citations.html)
- [Publish or Perish on macOS - Harzing.com](https://harzing.com/resources/publish-or-perish/os-x)
- [Publish or Perish - main page](https://harzing.com/resources/publish-or-perish)
- [Academia.edu Free vs Premium](https://support.academia.edu/hc/en-us/articles/29297378153623-Academia-Free-vs-Premium-What-features-do-I-get-on-Academia)
- [Semantic Scholar Product page](https://www.semanticscholar.org/product)
- [Semantic Scholar FAQ](https://www.semanticscholar.org/faq)
- [Scopus Alerts - Belmont University LibGuide](https://belmont.libguides.com/Scopus/Alerts)
- [Scopus vs Web of Science comparison 2025](https://www.journalmetrics.org/blog/scopus-vs-web-of-science)
- [Web of Science Author Alerts](https://webofscience.zendesk.com/hc/en-us/articles/20016619487889-Author-Alerts)
- [Dimensions AI - Products page](https://www.dimensions.ai/products/artificial-intelligence/)
- [Litmaps acquires ResearchRabbit, raises $1M (Scoop NZ)](https://www.scoop.co.nz/stories/BU2505/S00127/nz-startup-litmaps-acquires-us-rival-and-raises-1m-to-accelerate-ai-driven-research-worldwide.htm)
- [Litmaps vs ResearchRabbit vs Connected Papers 2026 - The Effortless Academic](https://effortlessacademic.com/litmaps-vs-researchrabbit-vs-connected-papers-the-best-literature-review-tool-in-2025/)
- [ResearchRabbit 2025 release announcement](https://www.researchrabbit.ai/announcement-researchrabbit-release-2025)
- [Connected Papers Pricing 2025](https://aihungry.com/tools/connected-papers/pricing)
- [Scite AI Review 2026 - AiChief](https://aichief.com/ai-education-tools/scite-ai/)
- [Scite Pricing 2026 - CostBench](https://costbench.com/software/ai-research-tools/scite/)
- [Scholarcy review 2026 - toolsforhumans.ai](https://www.toolsforhumans.ai/ai-tools/scholarcy)
- [R Discovery - researcher.life](https://discovery.researcher.life/)
- [CiteBar - macOS Google Scholar citation tracker](https://www.citebar.org/)
- [SSRN Financial Economics Network eJournal offerings](https://www.ssrn.com/index.cfm/en/fen/fen-ejournals/)
- [SSRN how subscriptions work](https://www.elsevier.support/ssrn/answer/subscriptions)
- [Litmaps Pro - Litmaps Help Center](https://docs.litmaps.com/en/articles/8115278-litmaps-pro)
- [Research Paper APIs for Scientific Literature 2026 - IntuitionLabs](https://intuitionlabs.ai/articles/research-paper-apis-scientific-literature)
- [Litmaps secures NZD $1.4M - CFO Tech NZ](https://cfotech.co.nz/story/litmaps-secures-nzd-1-4-million-to-drive-global-platform-growth)
- [AI Literature Mapping Tools Guide - IntuitionLabs](https://intuitionlabs.ai/articles/ai-literature-mapping-tools-guide)
- [Best Mac apps for researchers - Medium](https://joebathelt.medium.com/the-best-mac-apps-for-researchers-and-academics-8f9c0563cb26)
- [Top tools for tracking research impact and citations 2026 - SciJournal (paywalled in fetch)](https://www.scijournal.org/articles/best-tools-for-tracking-research-impact-and-citations)

---
