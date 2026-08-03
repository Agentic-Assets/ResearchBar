---
date: 2026-08-02
type: closeout
tags: [researchbar, corbis, menu-bar, ui, verification]
---

# Closeout: compact ResearchBar research pulse

## Outcome

The Corbis research pulse now renders as a compact, bounded provider card rather than a long audit-style list. It uses the shared provider-card width, presents at most two source-specific metrics, keeps actions readable in two columns, and routes extended research detail to Corbis instead of expanding the menu.

## Branch disposition

`fix/research-pulse-contract-accuracy` was not merged. Its only commit, `d5172e9b`, was reviewed against `origin/main` at `e531e1c8`; the newer academic-profile work already incorporates the useful contract behavior. The branch had no pull request or additional worktree. Replaying it would have created stale documentation and conflict noise without adding product behavior.

## Delivered

- Added the typed `ResearchPulseCardModel` projection, which prevents aggregate cross-source academic metrics, bounds the primary scan path, and fails closed for malformed, unsafe, credit-limited, or identity-unlinked data.
- Replaced the flat Corbis menu dump with a compact SwiftUI card and a two-column action grid. The legacy native menu remains available when menu-card rendering is unavailable.
- Restricted Corbis menu injection to the ResearchBar-owned status item, preventing it from altering Codex or Claude menus.
- Made malformed legacy credit balances unavailable rather than displaying a negative count; retained source-specific status-icon semantics and improved the connection settings controls.
- Added regression coverage for compact-card content, width, action duplication, unsafe data, unsupported contracts, status-item ownership, and height-cache isolation.

## Verification

PASS on implementation commit `4fbe44f9`:

- `swift build`
- `swift test --no-parallel --filter '^CodexBarTests\\.StatusMenuTests/'` (139 tests)
- `make test`: all 41 sharded runs completed and reported passing test runs; the final log contained zero test or build failures.
- `make check`: SwiftFormat reported 0 of 1,177 files needing changes; SwiftLint reported 0 violations.
- `CODEXBAR_SIGNING=adhoc ./Scripts/package_app.sh debug`
- `codesign --verify --deep --strict ResearchBar.app`
- `git diff --check`

The first full-suite run exposed an owner-mode test fixture that had card rendering disabled. The fixture was corrected, the status-menu suite passed, and the clean 41-shard run above was then performed.

## Adversarial review record

Independent review passes found and resolved: stale-branch replay risk, negative-credit fallback display, unsupported academic contract fallback, malformed credit payload exposure, unlinked-identity/profile-link exposure, duplicate/truncated actions, and accidental insertion of the ResearchBar card into ordinary provider menus.

## Deferred gates

No live Corbis account, browser cookie, Keychain credential, production signing, release, or merge was attempted. Those are separate authorization and acceptance gates; they are not implied by the local build and test evidence.
