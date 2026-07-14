# ResearchBar menu-bar icon closeout, 2026-07-12

**Branch:** `codex/fix-researchbar-menu-bar-icon`  
**Commit:** `1647aae9` (`Fix ResearchBar status item visibility`)  
**State:** Blocked on no-prompt live menu-bar inspection.

## Goal

Show a clear ResearchBar graduation-cap status item with stable identity, sizing, menu ownership, and placement recovery.

## What shipped

- ResearchBar now owns one merged AppKit status item and applies its template graduation-cap image, fixed status-item treatment, tooltip, and accessibility state without creating provider items.
- Initial construction and visibility recovery both use `researchbar-merged` and the `ResearchBar.StatusItem` accessibility identifier. This removes the first-launch/recovery identity mismatch that had prevented the cap path from running initially.
- Added regression coverage for ResearchBar item construction and replacement, menu attachment, image-only presentation, accessibility identity, and preserved split and merged lifecycle behavior.
- Preserved the existing placement watcher and recovery work in the branch, including the displaced-item predicate tests.

## Verification

- Passed: `swift test --filter StatusItemControllerSplitLifecycleTests` (24 tests).
- Passed: `swift test --filter MenuBarVisibilityWatcherTests` (34 tests).
- Passed: `swift test --filter StatusItemControllerShutdownTests` (2 tests).
- Passed: `make check`.
- Passed: `make test`.
- Built a fresh local ad-hoc bundle with `CODEXBAR_SIGNING=adhoc ./Scripts/package_app.sh`. Its executable timestamp was `2026-07-12T12:35:09-0500`; `./Scripts/launch.sh` launched that exact path as PID 31075.

## Blocker

The fresh application immediately presented a real Keychain prompt for `Claude Code-credentials` before the menu bar could be inspected. The prompt was not answered and no provider probe, browser import, or Keychain read was performed. Therefore the required visible-cap screenshot, open-menu screenshot, and live status-item bounds are not available.

The target display reported as the built-in Liquid Retina XDR display, 3456 by 2234 Retina. The capture before launch and the capture containing the unhandled prompt are saved outside the repository at `/Users/caymanseagraves/.codex/evidence/researchbar-menu-bar-icon-2026-07-12/` because they include unrelated desktop content.

## Decisions made

- Kept the merged status-item identity. It matches the existing placement key, stable ResearchBar accessibility identifier, and the recovery path. Using the Codex provider identity at initial construction made first launch differ from recovery.
- Did not alter the placement sentinel or provider behavior further. The tested identity correction is sufficient for the observed first-launch failure, while the live prompt prevents safe evaluation of any broader change.

## Left to the operator

Provide a no-prompt ResearchBar launch environment or explicitly authorize handling the Keychain prompt, then rerun the live menu-bar capture and open-menu inspection against the fresh bundle. Do not treat this commit as complete live visibility proof until those captures show the cap inside the active display's normal status-item area.

## Continuation, commit `c17378ea`

- Live inspection found the concrete stale migration state `NSStatusItem VisibleCC Item-0 = 0`, while the generic visibility repair had already recorded completion. The new ResearchBar-only migration clears that exact hidden legacy key once, then leaves normal app behavior unchanged.
- Focused suites passed: `StatusItemControllerSplitLifecycleTests` (25 tests) and `MenuBarVisibilityWatcherTests` (34 tests). `make check` passed. The sharded `make test` runner completed after the repair.
- A fresh ad-hoc bundle applied the migration and persisted `NSStatusItem VisibleCC researchbar-merged = 1`. The next fresh launch then presented the macOS dialog “ResearchBar would like to access data from other apps.” No button was pressed. The Control Center window-server list still contained no `researchbar-merged` item before that approval.
- Live rendered cap and open-menu evidence remains blocked by that approval-gated macOS dialog. The temporary `debugDisableKeychainAccess` preference was restored to its prior absent state.

## Continuation, 2026-07-12 approval-gate audit

- Rebuilt the current feature branch with `CODEXBAR_SIGNING=adhoc ./Scripts/package_app.sh` and launched the resulting `ResearchBar.app` with the temporary no-Keychain test gate enabled. The app process was `/Users/caymanseagraves/Documents/GitHub/agentic-assets/ResearchBar/ResearchBar.app/Contents/MacOS/ResearchBar` and the bundle identifier was `com.corbis.researchbar`.
- The target display could be captured, but the fresh app remained behind the macOS “ResearchBar would like to access data from other apps” dialog. Three resumed inspection attempts found only the offscreen `ResearchBarLifecycleKeepalive` window (`x=-5000`, `y=6328`, `20 by 20`) and no visible `researchbar-merged` WindowServer item.
- The final captured blocker evidence is `/Users/caymanseagraves/.codex/evidence/researchbar-menu-bar-icon-2026-07-12/15-third-resumed-tcc-gate.png`. It is intentionally outside the repository because it contains unrelated desktop content.
- No Keychain read or provider probe was performed. The requested cap and open-menu captures remain unproven, so this branch is not a completed visual verification.

## Continuation, 2026-07-12 fixed-width diagnosis

- After macOS approvals were accepted, live debugger inspection confirmed that `researchbar-merged` was visible, held a template `graduationcap` image, and exposed the `ResearchBar` / `ResearchBar.StatusItem` accessibility identity. Its status-item length was nevertheless `NSStatusItem.variableLength` (`-1`), which gave the macOS 26 Control Center scene no rendered width.
- Replaced the variable length with the standard `NSStatusItem.squareLength`, removed the one-point placement sentinel that had been registered before the visible item, and added the one-time cleanup for that sentinel's persisted visibility and placement keys. The lifecycle regression test now asserts the square length and sentinel cleanup.
- Passed: `swift test --filter StatusItemControllerSplitLifecycleTests` (26 tests), `swift test --filter MenuBarVisibilityWatcherTests` (34 tests), `make test` (all 41 shards), and `make check`.
- A fresh ad-hoc bundle built at `2026-07-12T18:28:56Z` launched as the repository's `ResearchBar.app`. Its live status item had square length (`-2`), the cap image, and ResearchBar accessibility identity on the built-in display. Control Center still did not render a visible menu-bar control, so the required cap and menu screenshots remain unavailable. The macOS Menu Bar settings page exposes an `Allow in the Menu Bar` section, which is the remaining OS-level admission path to verify.

## Continuation, 2026-07-13 root cause found and repaired

- Live inspection of the login-launched instance (PID 1866) found it owned zero WindowServer windows, while CodexBar owned its expected windows, and every layer-25 menu-bar window belonged to Control Center. On macOS 26, Control Center composites all status items and keeps a private admission store.
- Read `~/Library/Group Containers/group.com.apple.controlcenter/Library/Preferences/group.com.apple.controlcenter.plist` key `trackedApplications`: Cursor's entry (`com.todesktop.230313mzl4w4u92`, `isAllowed: false`) listed `com.corbis.researchbar` and `com.apple.dt.xctest.tool` in its `menuItemLocations`. ResearchBar's own entry was `isAllowed: true`, which is why the System Settings toggle showed enabled while the icon never rendered. Mechanism matches upstream steipete/CodexBar #1440 and #1945.
- Repair: timestamped backup `group.com.apple.controlcenter.plist.backup-20260713-171105` beside the original, removed the two stale bundle IDs from Cursor's `menuItemLocations`, ran `killall cfprefsd`, killed `ControlCenter`, relaunched the existing Jul-12 bundle with `./Scripts/launch.sh` (no rebuild, so the accepted ad-hoc signature and Keychain approvals stayed valid).
- Live proof: the operator visually confirmed the graduation cap rendering in the menu bar and supplied a screenshot. The relaunched process owned its keepalive window again and Control Center's menu-bar window count rose from 29 to 32. The store recheck showed Cursor's entry clean and ResearchBar's entry intact.
- Ported upstream PR #1954 (Tahoe no-window recovery): `expectedVisibleStatusItemAutosaveNames` intent tracking in `StatusItemController`, `StatusItemStartupVisibilityEvidence` plus `hasAnyTahoeHiddenNoProxyCandidate` in `MenuBarVisibilityWatcher`, `visibilityDefault` reader in `MenuBarStatusItemDefaultsRepair`, and the `detectTahoeBlockedStatusItem` startup wiring, with the ResearchBar forced-visible path recording its intent as well.
- Passed: `swift build`, `swift test --filter MenuBarVisibilityWatcherTests` (39 tests), `swift test --filter StatusItemControllerSplitLifecycleTests` (27 tests), `make check` (0 violations), `make test` (41 shards, exit 0).
- Intentionally did not rebuild or relaunch the app bundle after the code port: the running instance is visibly working, and a rebuilt ad-hoc signature would re-trigger the Keychain and app-group approval prompts with the operator away. The port is exercised by the focused suites; the next normal rebuild picks it up.
