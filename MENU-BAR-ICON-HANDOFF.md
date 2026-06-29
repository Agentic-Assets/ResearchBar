# ResearchBar menu bar icon: issue handoff

## Goal
ResearchBar (Corbis-gated macOS menu bar app, a CodexBar fork; SwiftPM
targets/modules stay `CodexBar*`, bundle id `com.corbis.researchbar`) must show a
clear, always-visible menu bar icon so the user can find it, click it, and go to
Settings, Research, then paste a `corbis_mcp_` token. Branding decided: graduation
cap (monochrome template) for the menu bar; Corbis "C" (navy) for the app icon,
the Settings Research pane, and the menu header; AA monogram for the About window.

## Symptom
The menu bar icon renders as a near-invisible faint dot, lost among ~13 other
status items. The user repeatedly could not find or recognize it.

## Root cause
The status item is owned by the inherited CodexBar `StatusItemController`. Its icon
is drawn by `updateIcons()` / `applyIcon()` from AI usage providers. ResearchBar
never drew its own brand icon: `updateResearchBarStatusAccessibility()` only set
the tooltip and accessibility value, not the button image. With ResearchBar's
provider state the inherited render is blank, so it shows as a dot.

## What worked
- Build, install, run are healthy. `make check` and full `make test` are green.
- Accessibility confirms the item exists: menu bar 2, pos approx 724,4, size 36x24,
  desc "status menu" (it is the LEFTMOST status icon, just left of Tailscale).
  Tooltip reads "ResearchBar: ...".
- Coexists fine with the separately installed CodexBar (`com.steipete.codexbar`):
  different bundle ids, both run at once. CodexBar is not the blocker.
- Confirmed in System Settings, Control Center, Menu Bar: ResearchBar is listed and
  toggled on. Ad-hoc signed. Spotlight "open" does nothing because it is LSUIElement
  (no window); that is expected.

## What did not work (the bug to fix)
Added `applyResearchBarBrandIconIfNeeded()` in
`Sources/CodexBar/ResearchBar/StatusItemController+ResearchBar.swift` to draw the
`graduationcap` SF Symbol. It is gated on
`store.enabledProvidersForDisplay().isEmpty`. That guard returns early because a
provider or fallback is enabled (the item is visible via `updateVisibility`'s
`anyEnabled`), so the cap is never drawn. The build is current; the code path is
just skipped.

## Fix needed
Make ResearchBar render its own status icon UNCONDITIONALLY (research first): drop
the `isEmpty` guard, set `button.image` to the template `graduationcap`, and keep
`statusItem.isVisible = true`. `updateIcons()` calls
`updateResearchBarStatusAccessibility()` LAST, so the image set there should win,
but verify it is not re-clobbered by `applyIcon`, the merged-icon signature cache,
or `updateVisibility` ordering (watch for flicker). Note: `screencapture` is
TCC-blocked for the agent, so verify via accessibility plus the user, not a
screenshot.

## Verify
1. `make check`
2. `./Scripts/compile_and_run.sh`
3. Accessibility: status item still present at menu bar 2.
4. User sees a graduation cap as the leftmost menu bar icon, hover tooltip
   "ResearchBar: Not connected".
