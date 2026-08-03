# ResearchBar Corbis peer tab closeout

Date: 2026-08-03

## Scope

Make Corbis a dedicated peer tab in the ResearchBar menu instead of showing its
pulse card above every provider tab. Keep provider data and Corbis data isolated.

## Delivered behavior

- The compact switcher renders Overview, Codex, Claude, and Corbis as peer tabs
  when those providers and Corbis are available.
- The tab rail remains a single 30-point row within the existing 310-point menu
  width.
- Corbis content and its refresh action render only while the Corbis tab is
  selected. Provider tabs do not show Corbis content.
- The Corbis tab retains global Settings, About, and Quit actions.
- Command-R routes to Corbis refresh on the Corbis tab and to the selected
  provider elsewhere.
- Keyboard and pointer navigation reach and leave the Corbis tab, including
  zero-provider and single-provider configurations.

## Adversarial review and remediation

Independent review identified and the implementation repaired these issues:

- Global application actions initially disappeared on the Corbis tab.
- The generic provider refresh action could duplicate the Corbis refresh action
  and Command-R could target the wrong data source.
- Coverage was missing the pointer-up selection transition and some sparse
  provider configurations.

The final skeptical review found no remaining release-blocking issue in the
implemented menu behavior.

## Verification

- Focused tab, switcher, persistent-refresh, and menu-height test suites passed.
- `make test` passed on the exact final source state.
- `make check` passed.
- `swift build` passed.
- `git diff --check` passed.
- The widget extension built successfully with Xcode after its dependencies were
  resolved.
- A fresh debug bundle was created with `CODEXBAR_SIGNING=adhoc
  ./Scripts/package_app.sh debug`, then passed `codesign --verify --deep --strict
  ResearchBar.app`.

## Packaging environment note

On its first clean derived-data bootstrap, the Xcode widget build resolved all
packages but made no progress into compilation and hit the script's 900-second
timeout. Re-running the same Xcode widget build against that resolved derived
data succeeded in under a minute. The package script then rebuilt the current
app and widget successfully while preserving only that one-run dependency cache.
No application source or packaging-script behavior changed as part of this
workaround.

## Deliberately not performed

No live provider probe, Keychain access, browser-cookie import, or account-backed
menu session was run. Those operations can prompt macOS or consume live account
capacity and require explicit authorization. The package script was used without
launching the app.

## Handoff

Branch: `fix/researchbar-corbis-tab`

The associated forward queue is
`goals/2026-08-03-researchbar-corbis-peer-tab-forward-queue.md`.
