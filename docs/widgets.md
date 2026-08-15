---
summary: "WidgetKit snapshot pipeline + visibility troubleshooting for ResearchBar widgets."
read_when:
  - Modifying WidgetKit extension behavior or snapshot format
  - Debugging widget update timing
  - Widget gallery shows no ResearchBar widgets
---

# Widgets

## Snapshot pipeline
- `WidgetSnapshotStore` writes compact JSON snapshots to the app-group container.
- Widgets read the snapshot and render usage/credits/history states.
- The app writes snapshots after the main refresh pipeline and token-usage refreshes; narrow single-provider refresh paths may wait for the next snapshot write.
- Automatic token/cost refresh eligibility follows the global refresh frequency. One- and two-minute settings are
  clamped to a five-minute minimum, both Adaptive modes use their nominal five-minute heuristic interval, and Manual
  disables the automatic token timer. The floor limits repeated local-history scans and extra WidgetKit reload requests
  so widgets do not exhaust the system-managed refresh budget.
- Claude local cost/token history remains eligible for widget snapshots when its account does not expose numeric
  session or weekly quota data.
- If no snapshot is available, widgets fall back to preview/empty data.

## Extension
- `Sources/CodexBarWidget` contains timeline + views; inherited SwiftPM target paths intentionally retain the CodexBar name.
- `WidgetExtension/CodexBarWidgetExtension.xcodeproj` builds those sources as the packaged macOS WidgetKit app extension.
- Keep data shape in sync with `WidgetSnapshot` in the main app.

## Widget types
- **ResearchBar Switcher** (`ResearchBarSwitcherWidget`): static provider switcher widget, small/medium/large.
- **ResearchBar Usage** (`ResearchBarUsageWidget`): configurable provider usage widget, small/medium/large.
- **ResearchBar History** (`ResearchBarHistoryWidget`): configurable usage-history chart, medium/large.
- **ResearchBar Metric** (`ResearchBarCompactWidget`): compact credits/today-cost/30-day-cost widget, small only.
- **ResearchBar Burn Down** (`ResearchBarBurnDownWidget`): configurable session or weekly burn-down chart, medium only.
- **ResearchBar Burn Down (Combined)** (`ResearchBarCombinedBurnDownWidget`): session and weekly burn-down charts, medium only.

## Provider picker support
The configurable provider widgets currently expose:
Codex, Claude, Cursor, Gemini, Alibaba, Antigravity, z.ai, Copilot, MiniMax, Kilo, OpenCode, and OpenCode Go.

Providers without a `ProviderChoice` case can still be present in the app snapshot, but they are not selectable from the widget configuration UI yet.

Burn-down widgets currently support Codex and Claude. Their dedicated configuration intents keep existing Usage and History widget configurations unchanged.

## Visibility troubleshooting (macOS 14+)
When widgets do not appear in the gallery at all, the issue is almost always
registration, signing, or daemon caching (not SwiftUI code).

### 1) Verify the extension bundle exists where macOS expects it
```
APP="/Applications/ResearchBar.app"
WAPPEX="$APP/Contents/PlugIns/ResearchBarWidget.appex"
WIDGET_ID="com.corbis.researchbar.widget"

ls -la "$WAPPEX" "$WAPPEX/Contents" "$WAPPEX/Contents/MacOS"
```

### 2) PlugInKit registration (pkd)
```
pluginkit -m -p com.apple.widgetkit-extension -v | grep -i researchbar || true
pluginkit -m -p com.apple.widgetkit-extension -i "$WIDGET_ID" -vv
```
Notes:
- `+` = elected to use, `-` = ignored (PlugInKit elections).
- If missing or ignored, force-add and re-elect:
```
pluginkit -a "$WAPPEX"
pluginkit -e use -p com.apple.widgetkit-extension -i "$WIDGET_ID"
```
- Check for duplicates (old installs or version precedence):
```
pluginkit -m -D -p com.apple.widgetkit-extension -i "$WIDGET_ID" -vv
```
If multiple paths appear, delete older installs and bump `CFBundleVersion`.

### 3) Code signing + Gatekeeper assessment
Widgets are loaded by system daemons. Any signing failure can hide the widget.
```
codesign --verify --deep --strict --verbose=4 /Applications/ResearchBar.app
codesign --verify --strict --verbose=4 "$WAPPEX"
codesign --verify --strict --verbose=4 "$WAPPEX/Contents/MacOS/ResearchBarWidget"
spctl --assess --type execute --verbose=4 /Applications/ResearchBar.app
```

### 4) Restart the right daemons (NotificationCenter alone is not enough)
```
killall -9 pkd || true
sudo killall -9 chronod || true
killall Dock NotificationCenter || true
```

### 5) Watch logs while opening the widget gallery
```
log stream --style compact --predicate '(process == "pkd" OR process == "chronod" OR subsystem CONTAINS "PlugInKit" OR subsystem CONTAINS "WidgetKit")'
```

### 6) Packaging sanity checks
- Widget bundle id is derived by packaging from the app bundle id: `com.corbis.researchbar.widget` for the configured ResearchBar identity. Verify the packaged extension's Info.plist rather than assuming a debug variant.
- `NSExtensionPointIdentifier` must be `com.apple.widgetkit-extension`.
- Bundle folder name should match: `ResearchBarWidget.appex`.

Optional: re-seed LaunchServices (rarely helps, but low risk):
```
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -seed
```

## Common post-visibility issue: stale data
If the widget appears but always shows preview data:
- App writes snapshot to fallback path while widget reads app-group container.
- Validate that both app and widget resolve the same app-group container.

See also: `docs/ui.md`, `docs/packaging.md`.
