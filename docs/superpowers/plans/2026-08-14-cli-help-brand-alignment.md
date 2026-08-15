# ResearchBar CLI Help Brand Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the three CLI help surfaces exercised by the suite consistently describe the shipped `ResearchBar` application and `researchbar` command, then unblock the complete safe test suite.

**Architecture:** Keep the inherited command parser, SwiftPM target names, provider names, and compatibility environment variables untouched. Update only rendered text returned by `usageHelp`, `diagnoseHelp`, and `rootHelp`; derive headings from the canonical `AppIdentity.displayName` while retaining the literal installed executable spelling `researchbar` in invocation examples.

**Tech Stack:** Swift 6, Swift Testing, SwiftPM, existing Makefile verification.

## Global Constraints

- Do not change provider behavior, configuration loading, compatibility identifiers, package or binary target names, or the `CODEXBAR_*` bridge variables.
- Do not access real providers, browser cookies, or macOS Keychain; every test command must set `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1`.
- The only user-facing command spelling in the three targeted help strings is `researchbar`; product headings use `AppIdentity.displayName`.
- Preserve all existing flags, provider names, examples, formatting, and help semantics other than the product/command identity.
- Run focused tests, `make check`, and `make test`; record any remaining external failure with exact evidence.

---

### Task 1: Align tested CLI help identity

**Files:**
- Modify: `Sources/CodexBarCLI/CLIHelp.swift:59-110,343-366,430-510`
- Modify: `Tests/CodexBarTests/CLIDiagnoseCommandTests.swift:7-17`
- Modify: `Tests/CodexBarTests/CLIProviderSelectionTests.swift:7-45`

**Interfaces:**
- Consumes: `AppIdentity.displayName` (`String`, canonical product label) from `CodexBarCore` and the literal installed command `researchbar`.
- Produces: `CodexBarCLI.usageHelp(version:)`, `diagnoseHelp(version:)`, and `rootHelp(version:)` whose headings and command examples match the shipped ResearchBar CLI.

- [ ] **Step 1: Strengthen the existing failing help assertions**

Add the following expectations to the existing help tests, after each help string is created:

```swift
#expect(help.hasPrefix("ResearchBar 0.0.0"))
#expect(!help.contains("codexbar"))
```

For the provider-selection test, apply both assertions to `usage` and `root`; for the diagnose test, apply them to `help`. Retain the existing assertions for concrete `researchbar` invocations and provider flags.

- [ ] **Step 2: Run the focused tests to demonstrate the inherited mismatch**

Run:

```bash
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --no-parallel --filter 'CLIDiagnoseCommandTests|CLIProviderSelectionTests'
```

Expected: FAIL because the current strings use `CodexBar` and `codexbar`.

- [ ] **Step 3: Update only the three rendered help strings**

In each target function, replace the title line with:

```swift
\(AppIdentity.displayName) \(version)
```

Replace each standalone command token `codexbar` in that function's Usage and Examples blocks with `researchbar`. In `usageHelp`, change the sentence `resolved CodexBar config file` to `resolved ResearchBar config file`. Do not change uppercase compatibility variable names, Swift target names, provider product labels such as `Codex`, or any non-target help function.

- [ ] **Step 4: Run focused tests to verify the help output**

Run:

```bash
CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --no-parallel --filter 'CLIDiagnoseCommandTests|CLIProviderSelectionTests'
```

Expected: PASS with all selected tests green.

- [ ] **Step 5: Perform a targeted content audit**

Run:

```bash
rg -n -i 'codexbar' Sources/CodexBarCLI/CLIHelp.swift Tests/CodexBarTests/CLIDiagnoseCommandTests.swift Tests/CodexBarTests/CLIProviderSelectionTests.swift
```

Expected: no lowercase `codexbar` remains inside the three target help functions or their assertions; occurrences outside those function ranges remain unchanged and are not part of this task.

- [ ] **Step 6: Commit the scoped repair**

```bash
git add Sources/CodexBarCLI/CLIHelp.swift Tests/CodexBarTests/CLIDiagnoseCommandTests.swift Tests/CodexBarTests/CLIProviderSelectionTests.swift
git commit -m "fix: align ResearchBar CLI help"
```

## Verification

- [ ] `CODEXBAR_SUPPRESS_TEST_KEYCHAIN_ACCESS=1 swift test --no-parallel --filter 'CLIDiagnoseCommandTests|CLIProviderSelectionTests'`
- [ ] `make check`
- [ ] `make test`
