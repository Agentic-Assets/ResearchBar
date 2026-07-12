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
