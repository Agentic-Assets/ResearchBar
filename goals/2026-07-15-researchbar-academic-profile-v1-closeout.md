# ResearchBar academic profile v1 closeout (2026-07-15)

**Branch:** `fix/researchbar-academic-profile-v1`  
**Base:** `origin/main` at merge base `84b54320`  
**Implementation:** `09a3e4e0` (`feat: add source-aware academic profiles`)  
**State:** local implementation and packaging proof complete; live MCP and release proof remain operator-gated

## Goal

Finish the paused native academic-profile prototype against the Corbis public
`academic-profile.v1` contract, integrate the useful pulse-accuracy branch
behavior, and leave ResearchBar with privacy-safe, provider-neutral presentation
and durable verification.

## What shipped

- A typed public academic contract in
  `Sources/CodexBarCore/ResearchBar/AcademicProfile.swift`, including exact
  source/status and reconciliation vocabularies.
- Authoritative nested-profile decoding with safe quarantine for unsupported
  future contracts and no legacy academic alternate truth.
- Credit, indexed-work, and trend compatibility behavior from
  `fix/research-pulse-contract-accuracy` at `d5172e9b`.
- Raw and typed privacy checks for internal IDs, semantic private-field
  variants, credentials, email evidence, and non-public identity records.
- Compact provider-neutral menu sections for overview, evidence, metrics, and
  coverage with consistent source ordinals, scope, freshness, reason, and null
  semantics.
- Updated client contracts, handoff, build plan, changelog, and fixture matrix.

## Verification

- Focused Research Pulse and MCP tests: 6 suites, 88 passed.
- `make check`: passed, including SwiftFormat, strict SwiftLint, parser hash,
  package/release path checks, sharding checks, and locale validation.
- `make test`: passed all 41 shards and 488 test selections.
- `CODEXBAR_SIGNING=adhoc ./Scripts/package_app.sh release`: passed and created
  `ResearchBar.app`. The bundle was not launched.
- Bundled `ResearchBarCLI --version`: passed and reported `ResearchBar 0.36.2`.
- `codesign --verify --deep --strict --verbose=2 ResearchBar.app`: passed. Local
  Gatekeeper assessment rejected the intentionally ad-hoc, non-notarized bundle;
  this is not release or notarization proof.
- Adversarial finder/skeptic review: six confirmed findings fixed; five earlier
  concerns refuted against the final code and tests.
- Live Corbis MCP, Keychain, and provider probes were not run by design.

## Decisions

- Corbis remains the only reconciliation authority. ResearchBar renders supplied
  families and proposals but does not merge records or derive publication types.
- Public source provenance stays in the model; default product copy uses stable
  ordinal labels to avoid exposing backend plumbing.
- The pinned public output schema wins over the richer internal work type.
  Settings-only `venue`, `publicationType`, and `url` fields were removed from
  the client model and fixture.
- An unsupported nested profile produces a calm update state and hides legacy
  academic totals instead of silently changing truth sources.

## Left to the operator

- Review and merge the PR. No merge is authorized by this closeout.
- Authorize a same-session live Corbis MCP and freshly packaged native-app check
  when production proof is desired.
- Decide release timing after live proof and review intake.
