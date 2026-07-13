# ResearchBar menu-bar icon: macOS rendering issue (RESOLVED 2026-07-13)

**Status:** Resolved. The graduation-cap status item renders in the menu bar and the root cause is confirmed with direct evidence. Resolution details are recorded below and in the closeout continuation for 2026-07-13.

## Root cause

macOS 26 (Tahoe) renders all status items through Control Center, which keeps a private admission store at
`~/Library/Group Containers/group.com.apple.controlcenter/Library/Preferences/group.com.apple.controlcenter.plist`
under the `trackedApplications` key. ResearchBar's status-item location had been attributed to **Cursor's** tracked-application entry (`com.todesktop.230313mzl4w4u92`, along with `com.apple.dt.xctest.tool`), and that entry carried `isAllowed: false`. Control Center therefore accepted the app-side `NSStatusItem` and silently refused to create any window for it. This matched every observed symptom:

- AppKit reported the item visible, square-length, correct image and accessibility identity, yet the WindowServer contained no window for it at all.
- ResearchBar's own entry in the store said `isAllowed: true`, so the System Settings > Menu Bar toggle showed enabled and toggling it changed nothing.
- The separately installed CodexBar and RepoBar rendered fine because their entries were clean.

The stale attribution was created by launching dev builds and running status-item tests from agent terminals hosted inside Cursor during the 2026-07-12 debugging sessions. This is a documented failure class in the upstream repo: steipete/CodexBar issues #1440 and #1945 (the exact no-window variant), fixed app-side by upstream PR #1954.

## Repair applied (2026-07-13)

1. Backed up the Control Center plist beside itself (`...plist.backup-20260713-171105`), then removed `com.corbis.researchbar` and `com.apple.dt.xctest.tool` from Cursor's `menuItemLocations` array.
2. `killall cfprefsd`, then killed `ControlCenter` (it respawns).
3. Relaunched the existing packaged bundle via `./Scripts/launch.sh`. The cap rendered in the menu bar and the operator confirmed it visually. The relaunched process also owned its expected keepalive window again, and Control Center's menu-bar window count increased accordingly.

## Durable code fix

Ported upstream steipete/CodexBar PR #1954 ("Fix Tahoe no-window menu bar recovery") into this fork: the app now records which autosave names it intends to be visible, and the startup visibility check detects the Tahoe state where an intended-visible item with an enabled `NSStatusItem VisibleCC` default reports non-visible with no window and no matching on-screen Control Center window, then attempts recovery and surfaces the Menu Bar settings guidance instead of failing silently.

## Prevention

Do not launch ResearchBar dev builds or status-item tests from terminal contexts whose host app is disallowed in the Menu Bar (Cursor was the trigger here). `./Scripts/launch.sh` uses `open -n`, which gives the app its own launch attribution and is the safe path. The direct-binary fallback in `Scripts/compile_and_run.sh` is the risky path if `open` fails.

---

The original unresolved report from 2026-07-13 (kept for history) described: a correctly configured square status item that AppKit reported visible while repeated display captures showed no cap, with admission state, CodexBar coexistence, retained placement data, and macOS 26.5.1 behavior all listed as untested hypotheses. The admission-state hypothesis was the correct family; the specific mechanism was the cross-app `trackedApplications` attribution above.
