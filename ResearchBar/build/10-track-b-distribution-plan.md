# 10. Track B distribution plan

This guide covers the parts that should wait until the pulse slice works:
product naming, bundle identifiers, Sparkle, notarization, Homebrew, release
validation, and macOS Tahoe checks.

## Goal

Prepare ResearchBar for direct macOS distribution without destabilizing the
working CodexBar chassis before the product path is proven.

Distribution work should preserve the fork relationship until the product path
is proven. Keep inherited CodexBar provider usage code available during beta
planning, even if the default menu hides it. This keeps upstream pulls easier
and leaves room for a smaller optional AI usage surface after the Corbis pulse
is the clear center of the app.

## Current decision

ResearchBar now owns the shipped app identity:

1. Public product name: `ResearchBar`.
2. Bundle id: `com.corbis.researchbar` (`.debug` for debug builds).
3. App group: `<team>.com.corbis.researchbar` (`.debug` for debug builds).
4. Config path: `~/.config/researchbar/config.json`, with `RESEARCHBAR_CONFIG`
   as the primary override and `CODEXBAR_CONFIG` only as an explicit legacy
   compatibility override.
5. Keychain services: `com.corbis.researchbar` and
   `com.corbis.researchbar.cache`.
6. Local logs and support roots: `ResearchBar`.

The SwiftPM package, executable, helper, widget target, and source folders may
remain `CodexBar*` during beta to preserve upstream sync. Do not treat those
internal target names as public product identity.

## Existing release machinery to preserve

| Existing path | Use |
|---|---|
| `Scripts/package_app.sh` | App bundle packaging. |
| `Scripts/sign-and-notarize.sh` | Developer ID signing and notarization. |
| `Scripts/make_appcast.sh` | Sparkle appcast generation. |
| `Scripts/release.sh` | Release wrapper. |
| `Scripts/mac-release` | Shared release tool bridge. |
| `docs/RELEASING.md` | Release procedure. |
| `.mac-release.env` | Release metadata and signing key paths. |
| `Makefile` | Build, test, lint, package entry points. |

## Rename decision

Treat naming as a release migration, not a search-and-replace.

| Item | Decision needed |
|---|---|
| Public product name | `ResearchBar`. |
| Bundle identifier | `com.corbis.researchbar`. |
| App display name | ResearchBar in Finder, menu bar accessibility, About pane, and release metadata. |
| Sparkle feed | Disabled until a ResearchBar-specific feed is approved. |
| Homebrew cask | No public cask until a ResearchBar-specific cask is approved. |
| Update channel | Separate from CodexBar upstream. |

Do not reuse CodexBar public update feeds for ResearchBar.

## Distribution tracks

| Track | Use when | Scope |
|---|---|---|
| Internal fixture build | Builder testing only | No rename, no notarized release required. |
| Private beta direct build | Small founder-approved group | Product name visible, signed and notarized, manual download. |
| Public direct distribution | Launch-ready | Signed DMG, Sparkle, Homebrew, release notes. |
| App Store variant | Deferred | API-only, no local agent launch, sandbox review required. |

Direct distribution remains the primary route because later agent launch may
spawn local tools.

## Files likely to change after approval

| Path | Change |
|---|---|
| `Package.swift` | Package and executable naming only if the team chooses a high-churn module rename. |
| `Sources/CodexBar/Resources/Info.plist` or generated plist path | Bundle name, identifier, LSUIElement, update metadata. |
| `Sources/CodexBar/About.swift` | Product name, version text, links. Done for ResearchBar identity. |
| `Sources/CodexBar/CodexbarApp.swift` | Logging subsystem and app name strings. Done for ResearchBar identity. |
| `Sources/CodexBar/StatusItemController.swift` | Accessibility title and autosave names. Done for ResearchBar identity. |
| `Scripts/package_app.sh` | Bundle output names and generated Info.plist. Done for ResearchBar identity. |
| `.mac-release.env` | Release app name, bundle id, feed, signing metadata. ResearchBar values set; feed remains disabled. |
| `docs/RELEASING.md` | ResearchBar-specific release checklist. Done. |
| `README.md` | ResearchBar-first repo guide. Done. |

Exact file paths may differ because the current package generates some app
bundle metadata through scripts. Read the scripts before editing.

## Tahoe and menu bar checks

Before beta:

1. Build a fresh app bundle.
2. Launch the bundle, not an old running copy.
3. Verify the menu bar icon is visible on the target display.
4. Open the menu and capture no-overlap screenshots.
5. Check no hidden menu extra coordinates are treated as success.
6. Run the menu with every v0 pulse fixture state.

Use the root `AGENTS.md` warning: menu bar automation must first capture the
target screen and prove the icon is onscreen.

## Release verification

For code health:

```bash
swift build
make test
make check
```

For bundle validation when UI/runtime behavior matters:

```bash
./Scripts/compile_and_run.sh --test
```

For packaging after release metadata is approved:

```bash
./Scripts/package_app.sh
```

Do not run release scripts in the background.

## Deferred

| Item | Reason |
|---|---|
| Global package rename | High churn before the pulse path works. |
| Public Sparkle feed | Needs product name and signing approval. |
| Homebrew cask | Useful after public beta, not needed for fixture work. |
| App Store build | Conflicts with likely local agent launch. |
| New app icon | Product identity decision should come first. |
| Broad provider-code deletion | Decide only after upstream sync and optional AI usage scope are clear. |

## Done when

- Distribution decisions are captured before rename work starts.
- Release scripts are mapped to ResearchBar-specific outputs.
- Tahoe menu validation is part of beta verification.
- Sparkle, Homebrew, and bundle id changes are not mixed with pulse model work.
