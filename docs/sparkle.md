---
summary: "ResearchBar Sparkle dependency, disabled-feed state, keys, and release flow."
read_when:
  - Touching Sparkle settings, feed URL, or keys
  - Generating or troubleshooting the Sparkle appcast
  - Validating update toggles or updater UI
---

# Sparkle integration

- Framework: Sparkle 2, minimum version 2.9.3 via SwiftPM (`Package.swift`).
- Updater: `SPUStandardUpdaterController` owned by `AppDelegate` (see `Sources/CodexBar/CodexbarApp.swift:1`).
- Feed: current packaging writes an empty `SUFeedURL` and `SUEnableAutomaticChecks=false`. Updates remain disabled until
  an approved ResearchBar feed is configured and verified.
- `SUPublicEDKey` is the public verification key embedded in the app. It is not a signing credential. Private signing
  key resolution is `SPARKLE_PRIVATE_KEY_FILE` first, then `.mac-release.env` `MAC_RELEASE_SIGNING_KEY_FILE`, then the
  release helper's Keychain fallback. Never copy private key material into documentation or commands.
- UI: update controls do not make updates operational while the feed is empty. Once a feed is approved, the auto-check
  toggle enables auto-downloads and the menu shows “Update ready, restart now?” only after an update is downloaded.
- LSUIElement: supported; after a feed is enabled, the updater window can show while checking. The app is non-sandboxed.
- Once a feed is enabled, stable and beta can share one appcast. Beta items use `sparkle:channel="beta"`; About →
  Update Channel controls `allowedChannels`.

## Release flow
1) Build and notarize with `./Scripts/sign-and-notarize.sh`, producing
   `ResearchBar-macos-universal-<version>.zip`. The release workflow signs nested helpers, the widget, and the app
   individually with hardened runtime and timestamps; it does not use `codesign --deep` as the signing operation.
2) After a ResearchBar feed is approved, generate the appcast entry with Sparkle `generate_appcast` using the Ed25519
   private key resolved in the precedence above. HTML release notes come from `CHANGELOG.md` via
   `Scripts/changelog-to-html.sh`. For beta releases, set `SPARKLE_CHANNEL=beta` to tag the entry.
3) Upload `appcast.xml` + zip to GitHub Releases (feed URL stays stable).
4) Tag/release.

## Notes
- HTML release notes are embedded in the appcast entry; the Sparkle update dialog should show formatted bullets (not raw tags).
- Do not hand-edit a packaged Info.plist. Configure the approved feed/key through release configuration and packaging,
  then rebuild and bump the app.
- Auto-check toggle is persisted via Sparkle; manual “Check for Updates…” remains in About.
- ResearchBar disables Sparkle in Homebrew and unsigned builds; those installs should be updated via `brew` or reinstalling from Releases. ResearchBar does not currently ship a Homebrew cask (see `docs/RELEASING.md`), so only the unsigned-build case applies today.
