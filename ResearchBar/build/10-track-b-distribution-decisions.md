# 10b. Track B distribution decisions (captured)

Companion to [`10-track-b-distribution-plan.md`](10-track-b-distribution-plan.md). The plan says *what to decide and when*; this file *captures the decisions and the concrete migration surface* so that, once Cayman approves, the rename and first signed release are a checklist rather than a discovery exercise. Nothing here is executed yet: the package is still named `CodexBar` and still carries upstream signing metadata by design.

Grounded in the live release config at the 2026-06-27 audit: `.mac-release.env`, `Scripts/package_app.sh`, `docs/RELEASING.md`, `version.env` (marketing `0.36.2`, build `89`).

## Gate (do not start rename or a public release until all hold)

1. Slice 06 fixture pulse tests pass. **Met.**
2. Slice 08 live MCP client is behind a validated Corbis Phase 0 gate. **Met** (Phase 0 live smoke passed 2026-06-26; client code is fixture-tested and gated).
3. Slice 09 menu renders all v0 states from real or captured-clean pulse data. **Met at the model/factory level.**
4. **Cayman approves the public product name and bundle identity.** *Open founder decision.*
5. The team decides whether inherited CodexBar AI-usage code is hidden, optional, or removed for the first beta. *Open founder decision.*

Items 4 and 5 block a public launch, not further client code.

## Current upstream values vs ResearchBar values needed

Everything below is an upstream `steipete/CodexBar` value that a ResearchBar build must replace with an Agentic Assets value. None should be reused for a ResearchBar public release (a ResearchBar build must never publish to CodexBar's update feed).

| Item | Current (upstream CodexBar) | ResearchBar value needed | Source to change |
|---|---|---|---|
| App name | `CodexBar` | TBD (`ResearchBar` or a Corbis-branded name) | `.mac-release.env` `MAC_RELEASE_APP_NAME` |
| Bundle id | `com.steipete.codexbar` | TBD (for example `ai.agenticassets.researchbar`) | `Scripts/package_app.sh:186,190`; `.mac-release.env` `MAC_RELEASE_BUNDLE_ID` |
| App group | `<team>.com.steipete.codexbar` | matches the new bundle id | `Scripts/package_app.sh:200,202` |
| GitHub repo | `steipete/CodexBar` | `Agentic-Assets/ResearchBar` | `.mac-release.env` `MAC_RELEASE_REPO` |
| Sparkle feed URL | `raw.githubusercontent.com/steipete/CodexBar/main/appcast.xml` | a ResearchBar feed (or private beta feed) | `.mac-release.env` `MAC_RELEASE_FEED_URL`, `MAC_RELEASE_DOWNLOAD_URL_PREFIX` |
| Code-sign identity | `Developer ID Application: Peter Steinberger (Y5PE65HELJ)` | Agentic Assets Developer ID | `.mac-release.env` `MAC_RELEASE_CODESIGN_IDENTITY` |
| Notary credentials | Steinberger ASC keys (`APP_STORE_CONNECT_*`) | Agentic Assets ASC keys | release env, `docs/RELEASING.md` prereqs |
| Sparkle signing key | shared legacy AGCY key | ResearchBar key decision | `.mac-release.env` signing-key path |
| Artifact prefixes | `CodexBar-macos-...`, `CodexBarCLI-...` | ResearchBar-named artifacts | `.mac-release.env` `MAC_RELEASE_ARTIFACT_PREFIX`, asset patterns |

## Founder decisions required (none are mine to make)

- **Product name** (gate item 4). Keep all brand strings configurable so a rename is a small, contained change, not a sweep.
- **Bundle identifier + app group** (gate item 4). A new identity, or a temporary CodexBar id for an internal-only beta.
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

## Rename migration checklist (run only after gate items 4 and 5 clear)

Treat as a release migration, not a search-and-replace. Read each script before editing; some bundle metadata is script-generated.

1. `Scripts/package_app.sh`: bundle id (`:186,190`), app group (`:200,202`), bundle/output names.
2. `.mac-release.env`: app name, repo, bundle id, feed URL, download prefix, code-sign identity, artifact prefixes, asset patterns.
3. `Sources/CodexBar/Resources` plist path: bundle name, identifier, `LSUIElement`, update metadata.
4. `Sources/CodexBar/About.swift`, `CodexbarApp.swift`: product name strings, logging subsystem.
5. `Sources/CodexBar/StatusItemController.swift`: accessibility title and autosave names.
6. `docs/RELEASING.md`: ResearchBar prereqs (certs, ASC keys, feed).
7. `README.md`: user-facing install instructions.
8. Optional `Package.swift`: only if the executable product is renamed (high churn; weigh keeping the SwiftPM target name `CodexBar` while changing only user-facing identity).

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
