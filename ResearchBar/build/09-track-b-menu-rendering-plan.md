# 09. Track B menu rendering plan

This guide turns the fixture-tested ResearchBar domain states into a native
menu surface. It keeps the first panel small: one account, one identity, one
pulse, and clear actions.

## Goal

Render ResearchBar v0 using the existing CodexBar menu infrastructure while
keeping research semantics out of quota-monitor types such as `UsageSnapshot`.

## Existing surfaces to reuse

| Existing path | Use |
|---|---|
| `Sources/CodexBar/StatusItemController.swift` | Menu lifecycle and AppKit status item control point. |
| `Sources/CodexBar/MenuDescriptor.swift` | Descriptor pattern for rows, sections, actions, and tests. |
| `Sources/CodexBar/MenuContent.swift` | SwiftUI row rendering reference. |
| `Sources/CodexBar/IconRenderer.swift` | Reference for menu bar icon rendering, not citation math. |
| `Sources/CodexBar/PreferencesView.swift` | Settings tab pattern. |
| `Tests/CodexBarTests/MenuDescriptor*` | Snapshot-style descriptor test examples. |

## Files to add or modify

| Path | Purpose |
|---|---|
| `Sources/CodexBar/ResearchBar/ResearchPulseMenuFactory.swift` | Builds menu descriptor sections from `ResearchPulseMenuModel`. |
| `Sources/CodexBar/ResearchBar/ResearchBarMenuActions.swift` | Refresh, connect, reconnect, open Corbis, open profile link, settings, quit. |
| `Sources/CodexBar/ResearchBar/ResearchBarStatusIconModel.swift` | Text/icon state for no credential, stale, loaded, low confidence, and credit-limited states. |
| `Sources/CodexBar/ResearchBar/CorbisSettingsView.swift` | Native settings surface for connection state and cache clear. |
| `Sources/CodexBar/PreferencesView.swift` | Add a ResearchBar or Corbis tab only after the settings view exists. |
| `Sources/CodexBar/StatusItemController.swift` | Composition only. Do not decode pulse or call network here. |
| `Tests/CodexBarTests/ResearchPulseMenuFactoryTests.swift` | Descriptor coverage for every v0 state. |
| `Tests/CodexBarTests/ResearchBarStatusIconModelTests.swift` | Status icon labels and accessibility text. |
| `Tests/CodexBarTests/CorbisSettingsViewStateTests.swift` | State builder tests without live Keychain prompts. |

## Required menu states

| State | Menu behavior |
|---|---|
| No credential | Show "Connect Corbis" and Settings. No polling. |
| Invalid credential | Show reconnect, last safe cache if available, and Settings. |
| Unlinked (`profileStatus: unlinked`) | Show identity confirmation action. Do not show internal ids. Not an error. |
| Industry profile (`profileStatus: industry_profile`) | Show a professional pulse with null publication metrics. No zeroed citation widgets. |
| Linked, not tracked | Show name, ORCID, affiliation, plan, credits, citations, h-index, paper count, profile links, and tracking-not-started state. |
| Linked, tracking | Same as not tracked, with a "history is accruing" state (`citationHistoryStatus: tracking`). |
| Linked, tracked | Show 7d and 52w deltas plus sparkline only when all trend fields are non-null. |
| Low confidence | Show values plus a concise confidence notice and review action. |
| Stale cache | Label cached values with fetched time and show refresh. |
| Credit limited | Show credits and upgrade or open Corbis action. No automatic refresh. |
| Safe error | Show a short error and actions. Do not show raw payload. |

## Row guidance

The menu should be glanceable. Put long onboarding text in Settings or a
dedicated window later.

Recommended v0 sections:

1. Account and identity.
2. Citation pulse.
3. Trend status.
4. Profile links.
5. Actions.

Keep menu item labels under 30 characters where possible. Longer profile titles
should be summarized in the menu and opened as links.

## Actions

| Action | Behavior |
|---|---|
| Refresh | Calls refresh coordinator if connected and not already refreshing. |
| Connect Corbis | Opens `CorbisSettingsView`. |
| Reconnect | Opens `CorbisSettingsView` with credential field focused. |
| Review identity | Opens Corbis identity confirmation path or Settings placeholder until backend exists. |
| Open Corbis | Opens `https://www.corbis.ai`. |
| Open profile link | Opens URL supplied by `profileLinks`; never constructs source URLs. |
| Clear cache | Lives in Settings, not the menu. |

## Accessibility

Status icon accessibility value should reflect:

| State | Accessibility value |
|---|---|
| No credential | `Not connected` |
| Loaded, not tracked | `Citation tracking not started` |
| Loaded, tracked | Total citations and 7d delta |
| Stale cache | Current value plus stale label |
| Credit limited | Credit-limited label |
| Safe error | Error label without sensitive text |

## Test checklist

1. Every `ResearchPulseMenuModel.State` has descriptor coverage (all four `profileStatus` states included).
2. Not-tracked and tracking states omit sparkline rows.
3. Tracked state includes trends only with complete trend data.
4. Industry-profile state shows null publication metrics, never zeroed citation widgets.
5. Low-confidence state includes review action.
6. Stale cache includes fetched time and refresh action.
7. Credit-limited state contains no automatic refresh action.
8. Leak-like values never reach descriptor rows.
9. Profile link actions use supplied URLs only.
10. Settings tab state can be built with test stores.

## Verification

Focused:

```bash
swift test --filter ResearchPulseMenuFactory
swift test --filter ResearchBarStatusIconModel
```

Before handoff:

```bash
swift build
make test
make check
```

## Done when

- The menu renders all v0 states from fixtures.
- `StatusItemController.swift` remains a composition surface.
- No research pulse code reuses `UsageSnapshot` for citation semantics.
- Settings can connect, reconnect, unlink, and clear cache through testable state.
