# Codex Goal - Make the ResearchBar Menu Bar Icon Reliably Visible

## Goal

Make the freshly built ResearchBar application display one clear, correctly sized graduation-cap icon in the normal macOS status-item area, with a usable menu attached and an accessibility identity of ResearchBar. The durable end state is not merely that the Swift code requests `graduationcap`, but that automated checks protect the relevant status-item lifecycle and current live-render evidence proves the icon is visibly present on the target display. Preserve current `main` behavior except for changes required to repair ResearchBar menu-bar visibility, sizing, placement recovery, or lifecycle ownership.

## Boundaries

Work only in `/Users/caymanseagraves/Documents/GitHub/agentic-assets/ResearchBar` on the existing feature branch `codex/fix-researchbar-menu-bar-icon`. Preserve all pre-existing branch changes and inspect them before editing. The expected implementation surface is the ResearchBar status-item composition and the smallest shared lifecycle or visibility-recovery code needed to make it reliable, primarily under `Sources/CodexBar/ResearchBar/`, `Sources/CodexBar/StatusItemController*`, `Sources/CodexBar/MenuBarVisibilityWatcher.swift`, and focused tests under `Tests/CodexBarTests/`.

Use the standard monochrome macOS status-item treatment, preferably the existing `graduationcap` SF Symbol as a template image with dimensions appropriate for the system menu bar. Keep the item in the ordinary AppKit status area, with its menu, accessibility description, stable identity, and placement behavior intact. Treat clickability, a running process, successful packaging, or an offscreen status-item window as insufficient visibility proof.

Do not redesign the ResearchBar menu, change Corbis MCP behavior, alter provider data, introduce a new dependency, replace the Finder or application `.icns` icon, broadly rename inherited CodexBar modules, or refactor unrelated status-menu behavior. Do not perform real provider probes, browser-cookie imports, real Keychain reads, or other checks that can display a Keychain prompt. Do not discard, overwrite, or silently absorb unrelated user changes. Never push to `main` or merge a pull request.

## Iteration Policy

Begin by auditing the active diff and tracing status-item creation, icon application, visibility detection, recovery, teardown, and menu ownership. Form a specific failure hypothesis before changing code. Make the smallest durable correction, then run focused tests. If a test exposes a shared lifecycle defect, repair the shared seam only when the evidence shows it is necessary for ResearchBar visibility and add regression coverage for preserved provider and merged-item behavior.

After automated checks pass, build and launch the fresh ResearchBar bundle using the repository scripts. Capture the target screen before interacting with the menu bar. Confirm that the rendered graduation cap is inside the bounds of an active display and in the normal status-item region, then open its menu and capture evidence. If live proof fails, inspect the fresh process, bundle, status-item window bounds, macOS placement state, and logs, revise the hypothesis, and iterate. Do not claim success from coordinate-based automation alone.

Pause before any material expansion beyond this scope. Record discoveries that are useful but unnecessary for this repair as follow-up items rather than mixing them into the implementation. Completion depends on evidence, not elapsed time or budget.

## Verification

Run focused tests covering ResearchBar cap rendering, fixed sizing, accessibility identity, status-item lifecycle, placement repair, visibility recovery, and preservation of split and merged provider items. At minimum, run the directly affected XCTest filters, then run `make check` and `make test` before handoff. Use test stores, stubs, and `KeychainNoUIQuery` compatible paths only.

For runtime proof, build and relaunch the current source with `./Scripts/compile_and_run.sh` only when bundle-level validation is required, or use `./Scripts/package_app.sh` followed by `./Scripts/launch.sh` when that is the narrower valid path. Verify the launched executable belongs to the newly built `ResearchBar.app`. Save a screenshot showing the cap visibly present on the target display and a second screenshot showing the ResearchBar menu opened from that same status item. Record the display bounds, observed status-item bounds, build command, test commands, and results in the closeout evidence.

Done means automated checks pass, the working tree contains only intentional scoped changes, and fresh live evidence shows a clear, correctly sized, interactive graduation-cap status item without regression in existing menu ownership or lifecycle behavior. Partial means code or tests improved but live visibility proof or the full required checks remain incomplete.

## Deliverables

1. The minimal Swift implementation required for reliable ResearchBar status-item visibility and sizing.
2. Focused regression tests for the repaired failure mode and preserved status-item behavior.
3. Live screenshots and a concise verification record identifying the fresh bundle, target display, commands run, and observed result.
4. A clean, scoped feature-branch commit and push with no unrelated files, plus the repository-required closeout log and separate forward queue if follow-up work remains. Do not create a pull request unless Cayman separately authorizes PR creation for this repo and item.

## Blocked Stop Condition

Stop and report blocked if macOS prevents screen or menu-bar inspection, the target display cannot be captured, the fresh bundle cannot be launched without an approval-gated action, validation would require a real Keychain or provider prompt, existing user changes cannot be safely separated, or the fix requires a product redesign or broad architecture change. Report the exact completed checks, current branch and diff state, concrete blocker, saved evidence, and next useful action. Never label the goal complete without live rendered visibility proof.
