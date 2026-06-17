# Verification verdicts

Twelve claims flagged by the research sub-agents were independently re-checked against primary sources (GitHub REST API, package manifests, release metadata, Hacker News Algolia API). Each verdict is one of: confirmed, partially-true, refuted, uncertain.

---

### [partially-true] Exact GitHub star count at time of query: WebFetch returned 14.9k, one search snippet said 11.9k -- the true figure likely sits between these depending on snapshot timing

The 14.9k data point is correct, but the claim's central inference is wrong and the claim is imprecise.

TARGET (unnamed in the claim): from the "CodexBar Research lane" attribution this is github.com/steipete/CodexBar. The claim never names the repo, which is itself a precision defect: a star count is meaningless without identifying the repo.

PRIMARY-SOURCE CHECK (2026-06-17): The authoritative GitHub REST API (api.github.com/repos/steipete/CodexBar) returns stargazers_count = 14945 (repo pushed_at 2026-06-17T10:48Z). The GitHub UI rounds this to "14.9k", which is exactly what WebFetch reported. So the 14.9k figure is accurate and matches the live count. The 11.9k figure is a stale cached search-index snippet from when the repo had roughly 11,900 stars; it is not a competing valid reading, just an older one.

WHY THE INFERENCE IS WRONG: A GitHub star count is a single exact integer at any instant, directly queryable via the API (stargazers_count). It is not an inherently uncertain range. The claim's logic ("two sources disagree, so the truth lies between them, depending on snapshot timing") is a false-compromise fallacy. When two sources disagree on a monotonically increasing, exactly-knowable counter, the truth is not the midpoint; it is the value from the freshest source. CodexBar's star count only grows over this horizon, so the current truth equals the higher, more recent figure (14945, i.e. 14.9k) and is at or above it, not bracketed somewhere between 11.9k and 14.9k. The 11.9k value is simply the past. The correct action is to query the API for the exact integer rather than average two snapshots.

SUMMARY: 14.9k = right (matches API 14945 and the UI). 11.9k = stale cache, not a valid alternate snapshot. "True figure likely between these" = refuted reasoning. The exact answer is knowable and is 14945.

Source: https://api.github.com/repos/steipete/CodexBar

**Corrected:** As of 2026-06-17, github.com/steipete/CodexBar has exactly 14,945 stars per the GitHub REST API (stargazers_count), which the GitHub UI and WebFetch display as the rounded "14.9k". The "11.9k" value is a stale cached search-index snapshot from when the repo was smaller, not a concurrent reading. A GitHub star count is an exact, single integer retrievable from api.github.com/repos/{owner}/{repo}; it is not a range, and the correct current figure is the fresher (higher) value 14,945, not a midpoint between the two snapshots. The right method is to query the API directly rather than infer a range from two stale-versus-fresh numbers.

---

### [confirmed] Exact initial release date of CodexBar v0.1.0 (newreleases.io showed "7 months ago" relative to an unspecified crawl date; the launch tweet from the X post URL would confirm).

The claim is an open question about the exact v0.1.0 release date of CodexBar (steipete/CodexBar, Peter Steinberger's macOS menu-bar AI-usage app, referenced in AGENTS.md as external tooling inspiration). I resolved it against the authoritative primary source, the GitHub Releases API, rather than the imprecise "7 months ago" string. The GitHub API record for tag v0.1.0 reports created_at = 2025-11-16T18:14:38Z and published_at = 2025-11-16T18:16:34Z, and the underlying annotated-tag commit (sha 3a539b0) carries the same 2025-11-16T18:14:38Z author and committer dates. This is corroborated internally: v0.1.1, v0.1.2, and v0.2.0 were all also cut on 2025-11-16 (18:16 through 22:13 UTC), which is the rapid same-day iteration pattern of a genuine first launch and rules out a backfilled/retagged date. The "7 months ago" relative text on the newreleases.io v0.1.0 page (which shows no absolute date) is fully consistent with this: 2025-11-16 to today (2026-06-17) is 213 days, about 7.0 months. I could not surface the original launch tweet directly via search, but it is not needed; the GitHub release metadata is the canonical primary source and is self-consistent. So the answer to the question: CodexBar v0.1.0 was first released on 2025-11-16 (16 November 2025), at approximately 18:14-18:17 UTC.

**Corrected:** CodexBar (steipete/CodexBar) v0.1.0 was first released on 2025-11-16 (16 November 2025) at ~18:16 UTC, per the GitHub Releases API (created_at 18:14:38Z, published_at 18:16:34Z; the v0.1.0 tag commit carries the same 2025-11-16 date). The newreleases.io "7 months ago" label is consistent with this date as of 2026-06-17 (213 days, ~7.0 months).

Source: https://github.com/steipete/CodexBar/releases/tag/v0.1.0

---

### [partially-true] Whether Swift 6.2 is strictly required or just the build toolchain recommendation (README says "Build Requirements: macOS 14+, Swift 6.2+").

The open question resolves in favor of "strictly required" (for building from source), but the quoted README wording is imprecise.

REQUIREMENT IS STRICT, NOT A MERE RECOMMENDATION. The authoritative source is the project's Package.swift, whose first line declares `// swift-tools-version: 6.2`. In Swift Package Manager, the swift-tools-version comment is a hard floor: per the Swift evolution proposal (SE-0152) and SwiftPM behavior, it "prevents clients from building with a toolchain older than the one defined in the manifest." An older toolchain (e.g. Swift 6.0/6.1) cannot even parse a manifest declaring 6.2 and will error out. So Swift 6.2+ is truly required to build CodexBar from source, not optional or advisory. Package.swift also sets the deployment target to `.macOS(.v14)`, matching the README.

THE QUOTED README STRING IS PARAPHRASED / IMPRECISE. The claim attributes the literal string "Build Requirements: macOS 14+, Swift 6.2+" to the README. The actual README (steipete/CodexBar, main branch) does not use a "Build Requirements:" label. Under the heading "Build from source" it reads, verbatim: "Requires macOS 14+ and Swift 6.2+." Same substance (macOS 14+ and Swift 6.2+), different wording and a different heading.

SCOPE CAVEAT. The Swift 6.2+ requirement applies only to building from source. Users who install the prebuilt app via Homebrew (`brew install --cask steipete/tap/codexbar`) or a GitHub release binary do not need any Swift toolchain; they only need macOS 14+ at runtime. The README's requirement line sits specifically inside the "Build from source" section, consistent with this scope.

Note: a second, unrelated repo (tienflow/CodexBar, a different menu-bar status-indicator app) also exists; the requirement details above are from steipete/CodexBar, the usage-stats menu bar app that matches the claim's wording.

**Corrected:** Swift 6.2+ is strictly required to build CodexBar (steipete/CodexBar) from source, not merely a recommended toolchain: Package.swift declares `// swift-tools-version: 6.2`, which SwiftPM enforces as a hard minimum (older toolchains cannot build the package). The README does not literally say "Build Requirements: macOS 14+, Swift 6.2+"; under its "Build from source" heading it says "Requires macOS 14+ and Swift 6.2+." This requirement applies only to building from source; installing the prebuilt app via Homebrew or a GitHub release needs only macOS 14+ at runtime, with no Swift toolchain.

Source: https://github.com/steipete/CodexBar/blob/main/Package.swift

---

### [confirmed] Whether SweetCookieKit is a standalone public Swift package repo or just an internal module within CodexBar.

SweetCookieKit is a standalone, public Swift Package Manager package, not an internal module of CodexBar. Primary-source evidence as of June 2026:

1. It has its own public GitHub repository at github.com/steipete/SweetCookieKit ("Native macOS cookie extraction for Safari, Chromium, and Firefox"), 100% Swift, MIT-licensed, with its own Package.swift and SPM install instructions: .package(url: "https://github.com/steipete/SweetCookieKit.git", from: "0.2.1"). It requires macOS 13+ / Swift 6 and ships a self-contained example CLI.

2. It is independently published and discoverable on the Swift Package Index (swiftpackageindex.com/steipete/SweetCookieKit).

3. CodexBar consumes it as an EXTERNAL versioned dependency, not as an internal module. CodexBar's Package.swift declares a conditional dependency that defaults to the remote repo: .package(url: "https://github.com/steipete/SweetCookieKit", from: "0.4.1"), falling back to a local sibling path (../SweetCookieKit) only when the env var CODEXBAR_USE_LOCAL_SWEETCOOKIEKIT=1 is set and the path exists. The local-path option is a developer convenience for working on both repos side by side; it does not make SweetCookieKit internal to CodexBar.

Both authors (Peter Steinberger / steipete) are the same, which is the likely source of the ambiguity, but the package is structurally separate and reusable on its own.

Minor note: the question's framing is a strict either/or; the accurate answer is the first option (standalone public Swift package repo). Version numbers cited differ by source (SweetCookieKit README shows from: 0.2.1; CodexBar pins from: 0.4.1), reflecting that CodexBar tracks a newer release.

**Corrected:** SweetCookieKit is a standalone, public Swift Package Manager package (github.com/steipete/SweetCookieKit, MIT-licensed, also listed on the Swift Package Index), not an internal module of CodexBar. CodexBar depends on it as an external versioned SPM dependency (default: from: "0.4.1"), with an optional local-path override for side-by-side development.

Source: https://github.com/steipete/SweetCookieKit

---

### [confirmed] Whether the macOS 15+ initial requirement was truly backported to 14 or if Sonoma support came in a specific named release [for CodexBar, the steipete/CodexBar macOS menu bar app].

This is a research question about CodexBar (Peter Steinberger's open-source macOS menu-bar app that tracks AI coding usage limits). Primary-source verification resolves both halves of the either/or, and they are not mutually exclusive: both are true.

(1) The initial requirement was truly macOS 15+. The Package.swift platforms array declared `.macOS(.v15)` (macOS 15 Sequoia minimum).

(2) It was truly backported to macOS 14 (Sonoma), not merely relabeled. Commit be4964fa0 ("feat: support macOS 14 and Intel builds", authored 2025-12-28) changed Package.swift from `.macOS(.v15)` to `.macOS(.v14)`. The same commit did real compatibility work for the lower target: it refactored Sources/CodexBar/DisplayLink.swift (+45/-12) and StatusItemController animation code, and the CHANGELOG/release note describes "x86_64 builds + Sonoma fallbacks." So the backport was substantive, not cosmetic.

(3) Sonoma support shipped in a specific named release: CodexBar 0.15.0 (tag v0.15.0), published 2025-12-28T15:54:45Z. The 0.15.0 release notes lead with: "macOS: CodexBar now supports Intel Macs (x86_64 builds + Sonoma fallbacks)."

Current state corroborates persistence of the change: main's Package.swift still declares `.macOS(.v14)`, and both the README ("macOS 14+ (Sonoma)") and the Homebrew cask (depends_on macos >= 14) state macOS 14 as the minimum.

The only imprecision in the claim is its "X or Y" framing, which implies the two possibilities are alternatives. In fact both are simultaneously true: the macOS 15 minimum was truly lowered to 14, AND that change arrived in the specific named release 0.15.0. Note the wording "macOS 15+ initial requirement" is accurate for the recorded history (it was .v15 before this commit); I could not find evidence of any earlier target below 15, so "initial" should be read as "the requirement prior to Sonoma support" rather than the very first commit, which I did not separately verify.

**Corrected:** CodexBar's minimum macOS requirement was truly lowered from macOS 15 (Sequoia) to macOS 14 (Sonoma): the backport was real (Package.swift changed `.macOS(.v15)` to `.macOS(.v14)` plus "Sonoma fallback" code in DisplayLink/animation handling), and it shipped in a specific named release, CodexBar 0.15.0 (commit be4964fa0, published 2025-12-28). Both halves of the either/or hold; they are not alternatives. As of mid-June 2026, main, the README ("macOS 14+ (Sonoma)"), and the Homebrew cask (macos >= 14) all still reflect the macOS 14 minimum.

Source: https://github.com/steipete/CodexBar/commit/be4964fa0

---

### [confirmed] Whether Hacker News ever had a 'Show HN' thread for CodexBar specifically (the HN result found was for a competing tool that cited CodexBar, not a first-party Show HN post).

Verified against Hacker News's official Algolia search API (the authoritative index of all HN submissions and comments). Findings: (1) No first-party Show HN for CodexBar exists. Peter Steinberger (HN user 'steipete'), author of the original CodexBar at github.com/steipete/codexbar, has zero HN story submissions mentioning CodexBar or linking to that repo; his most recent submissions are from mid-2025 (vibetunnel, peekaboo). (2) The only HN 'Show HN' story whose title and URL contain 'CodexBar' is a third-party Android port: 'Show HN: CodexBar for Android - Monitor Claude/Codex quotas on your phone' (objectID 47250848, by user hyunnnchoi, 2026-03-04, 1 point, github.com/hyunnnchoi/CodexBar-android). Its submission text explicitly credits the original: 'I ported CodexBar (a macOS menu bar app by @steipete).' So even this is a derivative tool that cites CodexBar, not a first-party post for the original. (3) CodexBar otherwise surfaces on HN only as a referenced or compared tool inside the comment threads of OTHER tools' Show HN posts (e.g., on 'Show HN: macOS menu bar gauges for your Claude Code quota,' a commenter asks 'What is benefit of this over https://github.com/steipete/codexbar?' and another says 'I use CodexBar, which supports more providers'). All of this confirms the claim's core assertion: the original CodexBar never had its own first-party Show HN thread; the HN result that surfaced was a separate tool that cited/ported CodexBar. One precision nuance: the single Show HN with 'CodexBar' in the title is best described as a third-party PORT that credits the original, while strictly competing tools (e.g., claude-quota) cite CodexBar in their comment threads rather than in a CodexBar-titled post. The distinction does not change the verdict.

**Corrected:** Confirmed with a minor precision refinement: Hacker News never had a first-party 'Show HN' thread for the original CodexBar (github.com/steipete/codexbar, by Peter Steinberger / HN user 'steipete', who made no CodexBar submission at all). The only 'Show HN' post bearing 'CodexBar' in its title is a third-party Android PORT ('Show HN: CodexBar for Android' by user hyunnnchoi) that explicitly credits the original ('I ported CodexBar by @steipete'). Separately, competing menu-bar quota tools reference CodexBar inside their own Show HN comment threads. So the HN appearances of CodexBar are derivative/comparative mentions, not a first-party Show HN.

Source: https://hn.algolia.com/api/v1/search?query=%22CodexBar%22&restrictSearchableAttributes=title&tags=story

---

### [partially-true] RepoBar star count: one source (GitHub page fetch June 2026) returned 2.1k, one search snippet returned 1.1k - live count should be verified at github.com/steipete/RepoBar

I verified against the authoritative primary source, the GitHub REST API (api.github.com/repos/steipete/RepoBar), which returns the exact integer stargazers_count = 2090 (public, not archived, 125 forks). That rounds to 2.1k.

Adjudicating the claim's components:

1. The "GitHub page fetch returned 2.1k" figure is CORRECT and is the accurate live value. My own page fetch independently returned 2.1k, and the API confirms 2,090 stars (which rounds to exactly 2.1k). The 125 forks count is also consistent across the page and API.

2. The "search snippet returned 1.1k" figure is STALE/WRONG, not a competing valid reading. Search-engine snippets cache older star counts. As a control, my own fresh web search returned yet a third stale number (1.3k), demonstrating that search snippets for this repo are unreliable and lag the live count. So the discrepancy the claim flags is real, but it is not a genuine ambiguity about the current value: the page-fetch number is right and the snippet number is simply out of date.

3. The recommendation to "verify the live count at github.com/steipete/RepoBar" is sound advice and is exactly what resolves the discrepancy.

Net: the claim is partially true. It accurately reports the two conflicting observations and correctly recommends live verification, but it leaves the count unresolved when the discrepancy is in fact resolvable. The live, authoritative count is 2,090 stars (2.1k). The 1.1k snippet should be discarded as stale, not treated as a coequal source. The repository exists, is public, and is actively maintained (latest release 0.8.3, June 13, 2026).

**Corrected:** As of June 2026, RepoBar (github.com/steipete/RepoBar) has 2,090 stars per the GitHub REST API (the authoritative source), which displays as 2.1k on the repo page. The 2.1k page-fetch figure is correct and current; the 1.1k search snippet is stale (search-engine caches lag the live count, as evidenced by a fresh search also returning an outdated 1.3k). No live ambiguity remains: the count is ~2.1k (2,090). The repository is public, not archived, has 125 forks, and is actively maintained.</correctedStatement>

Source: https://api.github.com/repos/steipete/RepoBar

---

### [refuted] Fork count of 125 came from the June 2026 GitHub page fetch and should be verified live (RepoBar research lane, re: the Corbis-Plugin GitHub repository).

The claim carries forward a fork count of 125 for the Agentic-Assets/Corbis-Plugin repository and asks that it be verified live. I verified it live against the authoritative primary source (the GitHub REST API, queried with the authenticated gh CLI) on 2026-06-17 at 16:04 UTC. The API reports forks_count=0, network_count=0, and the /forks endpoint enumerates 0 actual forks. The repository is private (which is why an unauthenticated api.github.com call returns 404), has 2 stars, and was last pushed 2026-06-17. The figure 125 is wrong by a wide margin: it is off by 125. As an adversarial cross-check I enumerated every repository in the Agentic-Assets org; the maximum fork count on ANY repo in the org is 4 (corbis-literature-starter-kit), so 125 is not attributable to a mislabeled sibling repo either. "RepoBar" is a real third-party macOS menu-bar GitHub-stats app by steipete (github.com/steipete/RepoBar) that surfaces fork/star counts; the "RepoBar research lane / June 2026 GitHub page fetch" framing describes how the 125 figure was read off such a stats display, but whatever the source, the number does not match the live repository. The only sound element of the claim is its own embedded caveat that the number "should be verified live" (correct hygiene); the substantive figure it transmits is false. Note: in this repo's codebase the literal strings "RepoBar", "fork count", and "125" (as a fork count) do not appear, so 125 is not a value sourced from any tracked file here.

**Corrected:** As of 2026-06-17 (verified live via the authenticated GitHub API), the Agentic-Assets/Corbis-Plugin repository has 0 forks (forks_count=0, network_count=0), not 125. It is a private repository with 2 stars. No repository in the Agentic-Assets organization has more than 4 forks, so a fork count of 125 is not accurate for any repo in scope.

Source: https://api.github.com/repos/Agentic-Assets/Corbis-Plugin

---

### [confirmed] Total release count of 23 was cited in the initial GitHub page fetch; the releases pagination shows at least 20+ but exact count should be verified at github.com/steipete/RepoBar/releases

Verified against the GitHub REST API, which is the authoritative primary source for an exact release count. `gh api repos/steipete/RepoBar/releases --paginate --jq 'length'` returns exactly 23. All 23 are published (draft=false) and non-prerelease (prerelease=false), so the count is not inflated by drafts. This matches the 23 git tags on the repo. The repository steipete/RepoBar exists, is not archived, default branch main, created 2025-11-24, last pushed 2026-06-15. The latest release is v0.8.3 ("RepoBar 0.8.3"), published 2026-06-13. The web releases page (HTML) only renders the first page of roughly 10 to 12 entries (v0.8.3 down to v0.6.2 were visible in the fetch), which is exactly why the claim's hedge that pagination "shows at least 20+ but exact count should be verified" is appropriate: the HTML view paginates, while the API confirms the precise total of 23. The number 23 is accurate as of mid-June 2026 and the recommendation to verify at the source resolves cleanly to 23.

**Corrected:** As of 2026-06-17, github.com/steipete/RepoBar has exactly 23 published releases (confirmed via the GitHub REST API paginated count; all 23 are non-draft, non-prerelease, matching 23 git tags). The HTML releases page paginates at roughly 10 to 12 entries per page, so it does not show the full total at once; the latest release is v0.8.3, published 2026-06-13. The cited count of 23 is accurate.

Source: https://api.github.com/repos/steipete/RepoBar/releases

---

### [confirmed] JWT signing (JWTSigner / RS256) exists in the codebase but DeepWiki states it is not actively wired into production auth flows - this should be verified against the current source tree.

The claim concerns steipete/RepoBar (a macOS GitHub menu-bar app), not the local Corbis-Plugin repo. I verified both halves against primary sources.

(1) DeepWiki's statement, verified by fetching the page directly: DeepWiki's "JWT Signing for GitHub Apps" page says JWTSigner exists at Sources/RepoBar/Support/JWTSigner.swift and provides "a minimal, dependency-free implementation of RS256 (RSA Signature with SHA-256) JWT signing," and explicitly states it "is currently available in the codebase but not actively used by RepoBar's main authentication flows," reserved for potential future GitHub App integration. So the claim accurately reports what DeepWiki says.

(2) The current source tree (the part the claim says to verify), checked by shallow-cloning github.com/steipete/RepoBar at the latest commit on main (67e5b14, dated 2026-06-14, three days before today):
- JWTSigner.swift exists. It implements RS256: header {"alg":"RS256"}, signs with .rsaSignatureMessagePKCS1v15SHA256 via the macOS Security framework. Doc comment: "Minimal RS256 JWT signer for GitHub App authentication."
- grep across all of Sources/ finds ZERO references to JWTSigner outside its own file, and ZERO references in Tests/. It has no callers; it is dead/unused code.
- RS256 / rsaSignature appears ONLY inside JWTSigner.swift, nowhere in any auth path.
- The real production auth path, Sources/RepoBar/Auth/OAuthCoordinator.swift, uses browser + loopback PKCE + refresh tokens with GitHub App USER tokens, and its "Installation token" section now contains only comments: "Installation flow removed: this app now uses user OAuth only." and "PEM resolution removed; GitHub App installation tokens are not used." Installation-token minting is the sole use case JWTSigner exists for, and it has been removed from the flow.

Both halves hold: JWTSigner/RS256 exists, and it is not wired into the production auth flows in the current source tree, matching DeepWiki. The claim is accurate. Caveat: this is a snapshot of main as of commit 67e5b14 (2026-06-14); status could change in future commits.

Relevant local file (no JWT auth code, only pyjwt as a bundled replication dependency and JWT examples in plugin-settings skill docs): the Corbis-Plugin repo itself is unrelated to this claim.

**Corrected:** In steipete/RepoBar (verified at main commit 67e5b14, 2026-06-14), Sources/RepoBar/Support/JWTSigner.swift implements RS256 JWT signing for GitHub App authentication, but it has no callers anywhere in Sources/ or Tests/ and is not wired into the production auth flow. The live OAuthCoordinator uses GitHub App user-only OAuth (PKCE + refresh tokens) and explicitly notes that installation-token PEM resolution was removed. This matches DeepWiki's description, so the claim is confirmed (with the caveat that it reflects the current main snapshot and could change in later commits).

Source: https://github.com/steipete/RepoBar/blob/main/Sources/RepoBar/Auth/OAuthCoordinator.swift

---

### [confirmed] v0.8.3 released June 13, 2026 is cited as the latest release as of the fetch date; a newer version may exist by the time this is read

The claim concerns RepoBar, the macOS menu bar app by Peter Steinberger (github.com/steipete/RepoBar), which is what the "RepoBar research lane" refers to. Verified against two primary sources as of June 17, 2026: (1) The GitHub /releases/latest canonical pointer resolves to v0.8.3, dated 13 June 2026 (11:34 UTC). (2) The CHANGELOG.md on the main branch lists "## 0.8.3 - 2026-06-13" as the most recent dated entry. v0.8.3 is therefore accurately described as the latest published release with the correct date. The claim's forward-looking hedge ("a newer version may exist by the time this is read") is appropriate and well-founded: the changelog already contains a "## 0.8.4 - Unreleased" section, indicating a newer version is in development. As of today (June 17, 2026, four days after the v0.8.3 release) v0.8.4 has not yet been published, so v0.8.3 remains the latest release. The only imprecision is that the claim omits the project name; it is otherwise accurate.

**Corrected:** RepoBar v0.8.3 (github.com/steipete/RepoBar), released June 13, 2026, is the latest published release as of June 17, 2026, confirmed via both the GitHub /releases/latest pointer and the CHANGELOG.md entry "0.8.3 - 2026-06-13". A "0.8.4 - Unreleased" section already exists in the changelog, so a newer version is in development but not yet published.

Source: https://github.com/steipete/RepoBar/releases/latest

---

### [refuted] Requirement of Xcode 26 (cited in AGENTS.md) implies a future/beta Xcode version; should be confirmed against the repo's current requirements.

The claim fails on both its premise and its factual assumption.

PREMISE (repo side): There is no "Xcode 26" string anywhere in this repository, and no AGENTS.md cites any Xcode requirement. A full-repo grep for "xcode" returns only "Xcode Command Line Tools" (unversioned) inside a bundled JFE replication package's R doctor script (e.g. /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/.claude/skills/finance-replication-code-patterns/corpus/packages/jfe/jfe-sxrmkvt3k8-1-2026/r/.../tools/doctor.r). The three AGENTS.md files were inspected directly: the root /Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/AGENTS.md is a 402-line research-pipeline document (a mirror of CLAUDE.md) with zero Xcode references (its only "26" match is the compare-versions skill-routing table row), and the two scaffold files (/Users/caymanseagraves/Documents/GitHub/agentic-assets/Corbis-Plugin/.claude/skills/research-init/assets/scaffold/AGENTS.md and the plugins/ mirror) are one-line stubs that just point to CLAUDE.md. So the asserted citation does not exist; the lane appears to have hallucinated it or confused this repo with another.

FACTUAL ASSUMPTION (Xcode 26 = future/beta): Also wrong as of mid-June 2026. Apple adopted year-based version numbering at WWDC 2025, jumping from Xcode 16 directly to Xcode 26 (no 17 through 25). Xcode 26.0 shipped as a stable general-availability release on September 15-16, 2025, and the line has since advanced to Xcode 26.5 (released May 11, 2026), per xcodereleases.com and Apple Developer release notes. Xcode 26 is the current, shipping major version, not a future or beta build.

**Corrected:** This repository's AGENTS.md files do not cite any Xcode requirement (there is no "Xcode 26" string anywhere in the repo; the only Xcode mention is unversioned "Xcode Command Line Tools" in a bundled JFE replication package's R script). Separately, "Xcode 26" is not a future or beta version: under Apple's year-based numbering adopted at WWDC 2025 (Xcode jumped from 16 to 26), Xcode 26.0 was released as stable GA on September 15-16, 2025, and the current stable release is Xcode 26.5 (May 11, 2026).

Source: https://xcodereleases.com/

---

