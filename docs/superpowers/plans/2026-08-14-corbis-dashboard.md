# Corbis Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the ResearchBar Corbis card a richer, truthful dashboard that exposes its existing plan and credit balance and renders its valid citation history as a full-width figure.

**Architecture:** Keep `ResearchPulseCardModel` as the redaction-checked projection boundary and add only presentation-ready plan and credit values derived from the existing Corbis pulse contract. Extract the inherited provider detail chart renderer into a shared menu-card primitive, then compose it in `ResearchBarMenuContent` only when the already-gated citation history is valid. The fallback `ResearchPulseMenuModel`, refresh coordinator, credential store, and provider usage stores remain unchanged.

**Tech Stack:** Swift 6, SwiftUI/AppKit, Swift Testing, existing `ProviderDetailSection.Chart` and menu-card styling utilities.

## Global Constraints

- Render only values supplied by a clean, semantically valid `ResearchPulse`; do not read Corbis credentials or raw tokens from a view or card model.
- Use `ResearchPulse.resolvedCreditBalance`, which gives the typed balance precedence over the legacy field; finite credit is a remaining value, not a quota.
- Show `"<formatted> credits remaining"` for a finite balance and `"Unlimited credits"` for an unlimited balance; omit unknown or malformed balances.
- Do not display a credit percentage, progress bar, allowance, reset date, usage history, account email, account identifier, cost, or token-derived identity until an authenticated Corbis contract provides authoritative data.
- Preserve `ResearchPulseCardModel` as the sole source-aware academic metric selection path. Do not mix Corbis identity or usage data with Codex or Claude stores.
- Any Corbis chart or figure must use the full available card content width. Render a citation chart only for valid tracked history; tracking, unavailable, malformed, and unsupported states retain text-only status.
- Preserve no-network launch, cache/refresh behavior, existing actions, error redaction, and compact fallback plan/credit rows.
- Use no new dependencies and no live Corbis, browser-cookie, real Keychain, packaging, or app-launch validation. Test with fixtures and `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1`.
- Run focused tests, `swift build`, `make check`, and `make test` before handoff. Do not change upstream-identical adaptive refresh timer code or tests to address host-load flakes.

---

## File structure

- `Sources/CodexBarCore/ResearchBar/ResearchPulseCardModel.swift` remains the safe, presentation-ready Corbis projection. It gains `plan` and `credit` values without exposing raw contract plumbing.
- `Sources/CodexBar/ProviderDetailSectionsContent.swift` owns the provider-neutral full-width chart renderer. Its chart view becomes reusable by any menu card without changing its drawing behavior.
- `Sources/CodexBar/ResearchBar/ResearchBarMenuContent.swift` owns the ResearchBar-specific header, credit section, and citation chart composition.
- `Tests/CodexBarTests/ResearchPulseCardModelTests.swift` covers safe plan and credit projection.
- `Tests/CodexBarTests/ProviderDetailSectionsContentTests.swift` covers the reusable chart renderer's full-width layout.
- `Tests/CodexBarTests/ResearchBarMenuCardLayoutTests.swift` covers chart gating and the final hosted card's compact size.

### Task 1: Project truthful Corbis plan and credit presentation values

**Files:**
- Modify: `Sources/CodexBarCore/ResearchBar/ResearchPulseCardModel.swift:18-137,169-320`
- Modify: `Tests/CodexBarTests/ResearchPulseCardModelTests.swift:5-103`

**Interfaces:**
- Consumes: `ResearchPulse.plan: String`, `ResearchPulse.resolvedCreditBalance: CreditBalance?`, `ResearchPulseRedactor.isClean(_:)`, and `ResearchPulseCardModel.number(_:)`.
- Produces: `ResearchPulseCardModel.plan: String?` and `ResearchPulseCardModel.credit: ResearchPulseCardModel.Credit?` where `Credit.summary: String` is safe for direct SwiftUI rendering.

- [ ] **Step 1: Write failing card-projection tests**

```swift
@Test
func `card projects plan and finite credits without a quota`() throws {
    let pulse = try ResearchBarFixtures.pulse("pulse-contract-limited")
    let model = ResearchPulseCardModel.make(from: .loaded(pulse: pulse, fromStaleCache: false))

    #expect(model.plan == pulse.plan)
    #expect(model.credit?.summary == "12.5 credits remaining")
}

@Test
func `card projects unlimited and omits unavailable credits`() throws {
    let unlimited = ResearchPulseCardModel.make(from: .loaded(
        pulse: ResearchBarFixtures.pulse("pulse-contract-unlimited"),
        fromStaleCache: false))
    let unavailable = ResearchPulseCardModel.make(from: .loaded(
        pulse: ResearchBarFixtures.pulse("pulse-contract-no-balances"),
        fromStaleCache: false))

    #expect(unlimited.credit?.summary == "Unlimited credits")
    #expect(unavailable.credit == nil)
}
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchPulseCardModelTests`

Expected: FAIL because `ResearchPulseCardModel` does not yet expose `plan` or `credit`.

- [ ] **Step 3: Add the minimal presentation-only projection**

```swift
public struct Credit: Equatable, Sendable {
    public let summary: String

    public init(summary: String) {
        self.summary = summary
    }
}

public let plan: String?
public let credit: Credit?
```

In `make(from:)`, populate both only after `safePulse` succeeds. Trim `pulse.plan` and make an empty plan `nil`. Add a private helper that maps `pulse.resolvedCreditBalance` exactly as follows:

```swift
switch balance {
case let .limited(remaining):
    Credit(summary: "\(self.number(remaining)) credits remaining")
case .unlimited:
    Credit(summary: "Unlimited credits")
}
```

Thread `plan: nil` and `credit: nil` through `emptyCard`. Do not add a denominator, percentage, reset, history, or progress property.

- [ ] **Step 4: Complete the fixture and redaction coverage**

Add assertions that `pulse-contract-malformed-new-fields` projects `"9.25 credits remaining"` through the existing valid legacy fallback, while a JSON mutation with `creditsRemaining = -1` yields `credit == nil`. Extend the existing visible-text redaction loop to include `model.plan` and `model.credit?.summary`; retain the credit-limited assertion that refresh is absent and add an assertion that a clean limited pulse still shows its balance.

- [ ] **Step 5: Run the focused Core suite**

Run: `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchPulseCardModelTests`

Expected: PASS, including finite, unlimited, unavailable, malformed-fallback, negative, credit-limited, source-aware, and redaction cases.

- [ ] **Step 6: Commit the independently tested projection**

```bash
git add Sources/CodexBarCore/ResearchBar/ResearchPulseCardModel.swift Tests/CodexBarTests/ResearchPulseCardModelTests.swift
git commit -m "feat: project Corbis account balances"
```

### Task 2: Reuse the inherited full-width menu-card chart primitive

**Files:**
- Modify: `Sources/CodexBar/ProviderDetailSectionsContent.swift:45-167`
- Modify: `Tests/CodexBarTests/ProviderDetailSectionsContentTests.swift:8-42`

**Interfaces:**
- Consumes: `ProviderDetailSection.Chart`, `UsageChartScale`, and `MenuHighlightStyle`.
- Produces: internal `MenuCardChartContent(chart:color:)` that preserves the existing bar/line rendering and accessibility behavior while claiming the full width offered by its menu-card parent.

- [ ] **Step 1: Write a failing full-width renderer test**

```swift
@Test
func `generic chart renderer fills the offered menu-card width`() throws {
    let chart = try ProviderDetailSection.Chart(
        kind: .line,
        title: nil,
        unit: "citations",
        points: [
            .init(label: "Week 1", value: 10),
            .init(label: "Week 2", value: 12),
        ])
    let width: CGFloat = 282
    let size = NSHostingController(rootView: MenuCardChartContent(chart: chart, color: .blue))
        .sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))

    #expect(abs(size.width - width) <= 0.5)
    #expect(size.height >= 58)
}
```

- [ ] **Step 2: Run the focused test to verify it fails**

Run: `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ProviderDetailSectionsContentTests`

Expected: FAIL because `MenuCardChartContent` is not visible outside `ProviderDetailSectionsContent`.

- [ ] **Step 3: Extract the existing chart without changing its semantics**

Rename `private struct ProviderDetailChartContent` to internal `struct MenuCardChartContent`, update `ProviderDetailSectionsContent` to construct the renamed view, and add this width contract to the reusable view's root stack:

```swift
.frame(maxWidth: .infinity, alignment: .leading)
```

Keep the `58`-point figure height, `bars` and `line` drawing, `UsageChartScale`, baseline overlay, highlight treatment, and chart accessibility label unchanged. Do not route this shared view through Codex or Claude usage stores.

- [ ] **Step 4: Run the renderer tests**

Run: `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ProviderDetailSectionsContentTests`

Expected: PASS for both existing bar/line rendering and the new full-width chart measurement.

- [ ] **Step 5: Commit the reusable chart extraction**

```bash
git add Sources/CodexBar/ProviderDetailSectionsContent.swift Tests/CodexBarTests/ProviderDetailSectionsContentTests.swift
git commit -m "refactor: share menu card chart renderer"
```

### Task 3: Compose the Corbis dashboard and full-width citation trend

**Files:**
- Modify: `Sources/CodexBar/ResearchBar/ResearchBarMenuContent.swift:17-256`
- Modify: `Tests/CodexBarTests/ResearchBarMenuCardLayoutTests.swift:8-29`

**Interfaces:**
- Consumes: `ResearchPulseCardModel.plan`, `ResearchPulseCardModel.credit`, `ResearchPulseCardModel.Trend`, and `MenuCardChartContent(chart:color:)` from Task 2.
- Produces: `ResearchBarMenuContent.citationChart(for:) -> ProviderDetailSection.Chart?`, an internal pure view-construction seam returning a full-width line chart only for nonempty, nonnegative trend points.

- [ ] **Step 1: Write failing dashboard-composition tests**

```swift
@Test
func `tracked research history becomes a full width chart while tracking stays textual`() throws {
    let tracked = ResearchPulseCardModel.make(from: .loaded(
        pulse: ResearchBarFixtures.pulse("pulse-linked-tracked"),
        fromStaleCache: false))
    let tracking = ResearchPulseCardModel.make(from: .loaded(
        pulse: ResearchBarFixtures.pulse("pulse-linked-tracking"),
        fromStaleCache: false))

    #expect(ResearchBarMenuContent.citationChart(for: try #require(tracked.trend))?.kind == .line)
    #expect(ResearchBarMenuContent.citationChart(for: try #require(tracking.trend)) == nil)
}
```

Extend the hosted card test to use `pulse-linked-tracked`, assert it still fits `StatusItemController.menuCardBaseWidth`, and bound its height below `340` points. Assert the model passed to that view includes its truthful `plan` and finite `credit` summary.

- [ ] **Step 2: Run the focused UI test to verify it fails**

Run: `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchBarMenuCardLayoutTests`

Expected: FAIL because `citationChart(for:)` and the dashboard sections do not exist.

- [ ] **Step 3: Compose plan, credits, and the full-width trend figure**

Refactor the header into leading identity and trailing account metadata so a nonempty `model.plan` is shown with the accessibility label `"Research plan: \(plan)"`; keep `freshness` in that trailing metadata and preserve title/subtitle truncation.

Immediately after the header, conditionally render a `Credits` section only when `model.credit` exists:

```swift
VStack(alignment: .leading, spacing: 2) {
    Text("Credits")
        .font(.caption.weight(.semibold))
        .foregroundStyle(MenuHighlightStyle.secondary(self.isHighlighted))
    Text(credit.summary)
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Credits: \(credit.summary)")
```

Do not add a progress bar: this contract has no authoritative limit. Keep the section absent when the balance is unknown.

Replace the trailing Unicode sparkline with a labeled trend section. `citationChart(for:)` must construct `ProviderDetailSection.Chart(kind: .line, title: nil, unit: "citations", points: ...)` using labels `Week 1` through `Week N`, only when `trend.sparkline` is nonempty and every value is nonnegative. Use `try?` and return `nil` if validation fails. When the chart exists, render:

```swift
MenuCardChartContent(chart: chart, color: .accentColor)
    .frame(maxWidth: .infinity, alignment: .leading)
```

When it does not exist, retain the icon and the textual trend summary but render no figure. Remove the obsolete `sparkline(for:)` Unicode-glyph helper. Preserve existing action grid, data-quality, notice, and safe action routing.

- [ ] **Step 4: Run the focused Corbis UI tests**

Run: `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchBarMenuCardLayoutTests`

Expected: PASS with a full-width tracked-history chart, no figure for the tracking fixture, compact-width hosting, and bounded height.

- [ ] **Step 5: Commit the Corbis dashboard composition**

```bash
git add Sources/CodexBar/ResearchBar/ResearchBarMenuContent.swift Tests/CodexBarTests/ResearchBarMenuCardLayoutTests.swift
git commit -m "feat: expand Corbis dashboard"
```

## Final verification and delivery

After all three task reviews are clean, run this ordered, non-live proof path from the feature worktree:

```bash
git diff --check
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchPulseDecodingTests
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchPulseCardModelTests
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ProviderDetailSectionsContentTests
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchBarMenuCardLayoutTests
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchPulseMenuModelTests
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchPulseRefreshCoordinatorTests
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --filter ResearchPulseRedactorTests
swift build
make check
make test
```

`make test` is the repository-required broad suite and its wrapper suppresses test Keychain access by default. If the previously observed upstream-identical adaptive refresh timer failure recurs under unrelated host CPU load, retain its output and distinguish it from this dashboard diff; do not alter the timer implementation or test to mask it.

For the deferred backend capability, create the user-authorized Linear issue only after an authenticated read confirms the `AGENTIC` team, `Corbis` project, and `Agentic-Assets/agentic-assets-app` repo label. Use the title and complete Objective, Required response semantics, and Definition of done in `docs/superpowers/specs/2026-08-14-corbis-dashboard-design.md`. Do not set an assignee, delegate, priority, cycle, or control label by inference. If the `agenticassets` Linear workspace remains unauthenticated, report that external-authentication gate without exporting or recording any credential.
