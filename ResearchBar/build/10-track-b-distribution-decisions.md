# 10b. Track B distribution decisions (captured)

Companion to [`10-track-b-distribution-plan.md`](10-track-b-distribution-plan.md). The plan says *what to decide and when*; this file *captures the decisions and the concrete migration surface*. As of 2026-06-27, the user-facing macOS app identity is ResearchBar with bundle id `com.corbis.researchbar`. SwiftPM target/module names still carry inherited `CodexBar*` names for upstream-sync stability.

Grounded in the live release config at the 2026-06-27 audit: `.mac-release.env`, `Scripts/package_app.sh`, `docs/RELEASING.md`, `version.env` (marketing `0.36.2`, build `89`).

## Gate (do not start rename or a public release until all hold)

1. Slice 06 fixture pulse tests pass. **Met.**
2. Slice 08 live MCP client is behind a validated Corbis Phase 0 gate. **Met** (Phase 0 live smoke passed 2026-06-26; client code is fixture-tested and gated).
3. Slice 09 menu renders all v0 states from real or captured-clean pulse data. **Met at the model/factory level.**
4. **Cayman approves the public product name and bundle identity.** **Met for client identity:** `ResearchBar`, `com.corbis.researchbar`.
5. The team decides whether inherited CodexBar AI-usage code is hidden, optional, or removed for the first beta. *Open founder decision.*

Item 5 blocks a public launch, not further client code.

## Current upstream values vs ResearchBar values

Everything below is an upstream `steipete/CodexBar` value that a ResearchBar build must replace. None should be reused for a ResearchBar public release (a ResearchBar build must never publish to CodexBar's update feed).

| Item | Current (upstream CodexBar) | ResearchBar value needed | Source to change |
|---|---|---|---|
| App name | `CodexBar` | `ResearchBar` | `.mac-release.env` `MAC_RELEASE_APP_NAME`; generated `Info.plist` |
| Bundle id | `com.steipete.codexbar` | `com.corbis.researchbar` (`.debug` for debug builds) | `Scripts/package_app.sh`; `.mac-release.env` `MAC_RELEASE_BUNDLE_ID` |
| App group | `<team>.com.steipete.codexbar` | `<team>.com.corbis.researchbar` (`.debug` for debug builds) | `Scripts/package_app.sh`; `AppIdentity` |
| GitHub repo | `steipete/CodexBar` | `Agentic-Assets/ResearchBar` | `.mac-release.env` `MAC_RELEASE_REPO` |
| Sparkle feed URL | `raw.githubusercontent.com/steipete/CodexBar/main/appcast.xml` | disabled until a ResearchBar feed is approved | `.mac-release.env` `MAC_RELEASE_FEED_URL`, `MAC_RELEASE_DOWNLOAD_URL_PREFIX` |
| Code-sign identity | `Developer ID Application: Peter Steinberger (Y5PE65HELJ)` | Agentic Assets Developer ID | `.mac-release.env` `MAC_RELEASE_CODESIGN_IDENTITY` |
| Notary credentials | Steinberger ASC keys (`APP_STORE_CONNECT_*`) | Agentic Assets ASC keys | release env, `docs/RELEASING.md` prereqs |
| Sparkle signing key | shared legacy AGCY key | ResearchBar key decision | `.mac-release.env` signing-key path |
| Artifact prefixes | `CodexBar-macos-...`, `CodexBarCLI-...` | `ResearchBar-macos-...`; no CodexBar CLI asset wait | `.mac-release.env` `MAC_RELEASE_ARTIFACT_PREFIX`, asset patterns |

## Founder decisions required (none are mine to make)

- **Product name** (gate item 4). Decided for client identity: `ResearchBar`.
- **Bundle identifier + app group** (gate item 4). Decided for client identity: `com.corbis.researchbar` and `<team>.com.corbis.researchbar`.
- **Code-sign identity + notary credentials.** ResearchBar needs Agentic Assets' Developer ID and App Store Connect keys. Notarization cannot run without them; do not reuse the upstream identity for a public artifact.
- **Sparkle feed + signing key.** A ResearchBar appcast URL and key; never the CodexBar public feed.
- **Homebrew cask.** New cask, or none for a private beta.
- **Update channel.** Separate from CodexBar upstream.
- **App Store variant.** Deferred. Conflicts with later local agent launch (sandbox).
- **Inherited AI-usage surface disposition** (gate item 5): hidden machinery, an optional advanced panel, or removed for the first beta. This is a product-surface call (see [`../OPEN-ISSUES.md`](../OPEN-ISSUES.md) and [`00`](00-what-this-means-for-researchbar.md)).

## Distribution tracks

| Track | Use when | Scope |
|---|---|---|
| Internal fixture build | builder/testing only | no rename, no notarized release; `swift build` + `make test` |
| Private beta direct build | small founder-approved group | product name visible, signed + notarized, manual download |
| Public direct distribution | launch-ready | signed DMG, Sparkle, Homebrew, release notes |
| App Store variant | deferred | API-only, no local agent launch, sandbox review |

Direct distribution stays primary because later agent launch may spawn local tools.

## Identity migration checklist

Treat identity work as a release migration, not a search-and-replace. Read each script before editing; some bundle metadata is script-generated.

1. `Scripts/package_app.sh`: bundle id, app group, generated bundle name, and output bundle name. **Done for ResearchBar.**
2. `.mac-release.env`: app name, repo, bundle id, feed URL, download prefix, artifact prefixes, asset patterns. **Done for ResearchBar; signing identity remains environment-controlled until Agentic Assets certs are available.**
3. `Sources/CodexBarCore/AppIdentity.swift`: app group, Keychain service, config namespace, support/cache/log directories. **Done for ResearchBar.**
4. `Sources/CodexBar/Resources` plist path: bundle name, identifier, `LSUIElement`, update metadata. **Generated by `Scripts/package_app.sh`; no static app plist.**
5. `Sources/CodexBar/About.swift`, `CodexbarApp.swift`: remaining human-visible strings. **Partially deferred while inherited AI-provider surface remains optional/internal.**
6. `Sources/CodexBar/StatusItemController.swift`: accessibility title and autosave names. **ResearchBar tooltip/accessibility now overlays the status item; full status-item autosave rename is deferred with the menu-surface decision.**
6. `docs/RELEASING.md`: ResearchBar prereqs (certs, ASC keys, feed).
7. `README.md`: user-facing install instructions.
8. Optional `Package.swift`: only if the executable product is renamed (high churn; keep SwiftPM target names `CodexBar`, `CodexBarCore`, and `CodexBarCLI` stable through the first beta unless a later branch takes the full module rename).

Keep the SwiftPM target/module names (`CodexBar`, `CodexBarCore`) stable through the first beta if possible; user-facing identity (display name, bundle id, feed) is what must change. This keeps upstream syncs cheap.

## Release-script to output mapping

| Script | Produces | Changes at rename |
|---|---|---|
| `Scripts/build_icon.sh` | `Icon.icns` from `Icon.icon` | new app icon (deferred; identity decision first) |
| `Scripts/package_app.sh` | the `.app` bundle | bundle id, app group, output name |
| `Scripts/sign-and-notarize.sh` | signed + notarized `.app` | Developer ID, notary creds |
| `Scripts/make_appcast.sh` | Sparkle `appcast.xml` | feed URL, signing key |
| `Scripts/release.sh` | end-to-end tag + GitHub release + appcast | repo, feed, asset names |
| `Scripts/mac-release` | shared release-tool bridge | resolves `MAC_RELEASE_TOOL` / `agent-scripts` |

Do not run release scripts in the background; keep them in the foreground until they finish.

## Tahoe and menu-bar verification (part of every beta build)

1. Build a fresh app bundle; launch the bundle, not an old running copy.
2. Confirm the menu-bar icon is visible on the target display (capture the screen first).
3. Open the menu and capture no-overlap screenshots.
4. Reject any click result whose coordinates fall outside display bounds; a hidden menu extra is not click proof.
5. Run the menu through every v0 pulse fixture state (the slice-06/09 fixtures cover all four `profileStatus` and three `citationHistoryStatus` states).
6. Verify no research code path renders a citation value sourced from a quota `UsageSnapshot`.

## Deferred (decide only after the pulse path and naming are settled)

Global package rename, public Sparkle feed, Homebrew cask, App Store build, new app icon, and broad provider-code deletion. Each waits on a founder decision above; none should be mixed into pulse-model or client work.
