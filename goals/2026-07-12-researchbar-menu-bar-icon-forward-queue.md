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

- **Document the app-group approval prerequisite for fresh local verification** (priority: high, confidence: verified gap)
  After the legacy visibility migration persisted `researchbar-merged = 1`, a fresh app launch prompted for macOS access to data from other apps. That approval has now been accepted. The remaining admission control is macOS Menu Bar settings, where ResearchBar must appear under and be enabled in `Allow in the Menu Bar` before visual proof is possible.
