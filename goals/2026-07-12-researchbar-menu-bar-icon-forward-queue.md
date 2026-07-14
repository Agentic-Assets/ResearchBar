# Forward queue after ResearchBar menu-bar icon work, 2026-07-12

Candidate work surfaced during this session. This is a menu, not a roadmap.

## Evaluation

- **Complete the no-prompt visual proof** (resolved 2026-07-13)
  The Control Center `trackedApplications` repair made the cap render and the operator confirmed it visually. Remaining live check: after the next rebuild, confirm the ported Tahoe no-window detection against a fresh bundle in a prompt-safe launch window, and open the attached menu from the rendered item for a menu screenshot.

## New items, 2026-07-13

- **Do not launch dev builds or status-item tests from disallowed host apps** (priority: high, confidence: verified root cause)
  Launching from agent terminals inside Cursor attributed the ResearchBar status item to Cursor's disallowed Menu Bar entry, which silently blocked rendering. Prefer `./Scripts/launch.sh` (`open -n`). Consider removing or guarding the direct-binary fallback in `Scripts/compile_and_run.sh`, and document the diagnosis commands (read `trackedApplications`; `log stream --predicate 'category == "appStatusItems"'`).

- **CodexBar Keychain prompt loop** (priority: medium, separate app)
  The installed CodexBar repeatedly prompts for the `Claude Code-credentials` Keychain item even after Always Allow, and its menu reports the expired-token background-repair suppression message. ResearchBar inherits the same credential machinery, so the same loop can appear here after rebuilds because each ad-hoc signature invalidates the item ACL. Track a durable policy (test-only credential gate or documented approval flow).

- **Status item vertical alignment polish** (priority: low, confidence: operator observation)
  The operator noted the rendered cap "maybe not completely aligned" with neighboring items. Compare the 16 pt symbol configuration and square-length treatment against neighboring items on the notched built-in display before adjusting.

## Robustness

- **Make startup credential prompts observable and avoidable in UI verification** (priority: high, confidence: verified gap)
  The fresh bundle displayed a Keychain prompt before visibility could be inspected. Add or document a test-only startup configuration that guarantees `KeychainNoUIQuery` compatible behavior without changing production credential policy.

## Hardening

- **Add a focused owner-shutdown assertion** (priority: medium, confidence: hypothesis)
  The current generic shutdown suite covers status-item cleanup, and the branch removes the ResearchBar placement sentinel during shutdown. A ResearchBar-owner-specific test would confirm that the sentinel and merged item are both removed without affecting normal provider lifecycle coverage.

- **Capture the placement sentinel in live diagnostics** (priority: low, confidence: hypothesis)
  The sentinel is intentionally excluded from current visibility snapshots. If live placement diagnosis remains difficult after no-prompt verification, add an explicit diagnostic record that distinguishes the visible cap item from the one-point placement helper.

- **Document the app-group approval prerequisite for fresh local verification** (priority: high, confidence: verified gap; superseded 2026-07-13)
  After the legacy visibility migration persisted `researchbar-merged = 1`, a fresh app launch prompted for macOS access to data from other apps. That approval has now been accepted. This item originally flagged macOS Menu Bar settings admission as the remaining blocker before visual proof would be possible; the actual root cause was Control Center's `trackedApplications` attribution to Cursor (see the 2026-07-13 unresolved-issue doc), and visual proof succeeded after that repair without a Menu Bar settings change.

## Documentation audit flags, 2026-07-13

A three-agent docs audit fixed stale markdown (test-framework description, Tahoe issue status, release-doc signing description, upstream Homebrew playbook banner, Sparkle doc naming) and flagged the following non-markdown risks. These need founder decisions or a dedicated pass; none were edited.

- **Release chain still signs as the upstream maintainer** (priority: high, founder decision)
  `.mac-release.env`, `Scripts/sign-and-notarize.sh:7`, and `Scripts/package_app.sh:199,445` default to `Developer ID Application: Peter Steinberger (Y5PE65HELJ)`, and `Sources/CodexBarCore/AppIdentity.swift:7` hardcodes that team ID and derives the app-group entitlement from it (load-bearing, not just tooling). Any non-adhoc release today would sign under the upstream identity. Needs an Agentic Assets signing identity decision before any real release; `build/10-track-b-distribution-decisions.md` already tracks this.

- **Upstream web artifacts would misdirect if published** (priority: medium)
  `docs/CNAME` points at `codexbar.app`, and `docs/index.html` plus `docs/llms.txt` are the unmodified upstream landing page and index linking to `github.com/steipete/CodexBar`. Root `appcast.xml` holds live upstream CodexBar release entries. Regenerate or replace before enabling GitHub Pages or shipping a release.

- **Fork-workflow docs describe the wrong fork** (priority: medium)
  `docs/FORK_SETUP.md`, `docs/FORK_QUICK_START.md`, `docs/FORK_ROADMAP.md`, and `docs/UPSTREAM_STRATEGY.md` document the `topoffunnel/CodexBar` intermediate fork, not `Agentic-Assets/ResearchBar`. Followed verbatim they set wrong remotes and PR targets. Correct or archive in a dedicated pass.

- **Client integration guide is a committed copy, not the documented symlink** (priority: low)
  `ResearchBar/RESEARCHBAR-CLIENT-INTEGRATION-GUIDE.md` is a regular committed file, while `ResearchBar/CLAUDE.md`, `README.md`, and `BUILD.md` describe it as a symlink into the sibling Corbis repo. Decide whether to re-symlink or keep a materialized copy, then align the descriptions.

- **Product-naming founder row already decided** (priority: low)
  `ResearchBar/OPEN-ISSUES.md` still lists product naming as an unresolved founder decision, but `build/10-track-b-distribution-decisions.md` records it decided (ResearchBar, `com.corbis.researchbar`). Close the row on the next OPEN-ISSUES pass.
