# ResearchBar menu-bar icon: unresolved macOS rendering issue

**Status:** Unresolved. ResearchBar is not yet working correctly as a visible menu-bar app on this Mac.

## What is happening

A freshly packaged and launched `ResearchBar.app` creates a status item that is configured as a normal, square menu-bar item. Debugger inspection confirmed that the item:

- is visible to AppKit;
- uses the template `graduationcap` image;
- has `NSStatusItem.squareLength` rather than variable length;
- has the `ResearchBar` accessibility title and `ResearchBar.StatusItem` identifier;
- is attached to the built-in display; and
- has an attached menu.

Despite that state, the graduation-cap icon has not appeared in the captured macOS menu bar. The expected Control Center status-item control is absent, so its menu cannot be opened for the required visual verification.

## Why this is a confirmed failure

This is not only an icon-selection or process-launch problem. The current bundle launched from this repository, and live inspection found the intended ResearchBar item with its fixed dimensions and accessibility identity. Repeated display captures still did not show a visible cap in the normal status-item area. On macOS 26.5.1, the Control Center scene appears not to render or admit this otherwise valid status item.

That is enough to establish that the requested visible behavior is failing. It is not enough to establish the underlying macOS cause. We cannot yet say why the system is suppressing the control.

## Observed symptoms and history

- Earlier launches were blocked first by a Keychain prompt and then by the macOS "ResearchBar would like to access data from other apps" approval. Those approvals no longer explain the current failure.
- A legacy hidden-status-item preference and a variable-length item were found and repaired. The current live item reports square length, but it still does not render visibly.
- macOS Menu Bar settings includes an `Allow in the Menu Bar` admission section. ResearchBar needs to be present and enabled there, but the system has not yet produced a visible ResearchBar control after the approval and code repairs.
- The icon was reported as visible at one point during earlier work. That observation shows the behavior has not been uniformly absent, but it was not reproduced in the latest fresh-bundle captures.
- The original CodexBar application is also installed on this computer at the same time as ResearchBar. Both applications derive from the same status-item architecture. A collision in macOS placement, saved status-item state, or menu-bar admission is plausible, but has not been demonstrated. It remains a hypothesis, not a diagnosis.

## What we do not know

We do not currently know whether macOS is withholding the item because of its menu-bar admission state, a collision with the installed CodexBar app, retained Control Center placement data, a macOS 26.5.1 behavior, or another system-level condition. The application-level status-item state is correct enough that further source changes without new evidence would be speculative.

## Evidence and next diagnostic step

The fresh-bundle inspection and display captures are recorded in the closeout note at `goals/2026-07-12-researchbar-menu-bar-icon-closeout.md`. Screenshots remain outside the repository at `/Users/caymanseagraves/.codex/evidence/researchbar-menu-bar-icon-2026-07-12/` because they include unrelated desktop content.

The most useful next check is to confirm that ResearchBar is enabled under **System Settings > Menu Bar > Allow in the Menu Bar**, then relaunch a fresh bundle and capture the built-in display. If it remains absent, temporarily quitting the separately installed original CodexBar and checking whether ResearchBar appears would test the coexistence hypothesis without claiming that it is the cause.
