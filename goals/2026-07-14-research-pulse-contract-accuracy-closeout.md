# Research Pulse contract accuracy closeout, 2026-07-14

**Branch:** `fix/research-pulse-contract-accuracy`  
**Server counterpart:** `fix/research-pulse-data-accuracy` in `Agentic-Assets/agentic-assets-app`  
**State:** verified locally; commit and remote ref recorded in the Linear and session handoffs

## Outcome

ResearchBar now decodes the additive pulse contract without breaking old payloads, renders unlimited and finite credit balances truthfully, labels authored output as indexed works, and accepts honest early trend history before a 52-week comparator exists.

## What shipped

- Added tolerant `creditBalance` decoding while preserving the optional legacy numeric balance.
- Added presence-aware `indexedWorksCount` decoding. A present authoritative value, including explicit `null`, does not revive a stale legacy alias; absent or malformed new fields fall back for compatibility.
- Rendered `Unlimited`, exact finite balances, and `Indexed works`; unavailable values are omitted.
- Made a tracked pulse valid when it has a non-null 7-day comparator and non-empty real sparkline. The 52-week row is independently optional and appears only when its comparator exists.
- Added current-server, old-server, explicit-null, malformed-new-field, no-balance, future-post-window, and tracked-without-52-week fixtures plus cache, MCP, decoder, menu-model, and menu-factory coverage.
- Updated the living integration and build contracts to match current dual emission and trend requirements.

## TDD and verification

- Initial contract work passed 65 focused tests, then all 41 `make test` shards and `make check`.
- Final adversarial RED used a current-backend tracked fixture with 7-day data, a valid sparkline, and no 52-week comparator: 42 focused tests produced eight expected assertion issues.
- The narrow GREEN repair passed 43 focused tests across three suites. Separate guards prove missing 7-day data or a missing sparkline still invalidates a tracked pulse.
- The final full `make test` rerun passed all shards. `make check` reported zero SwiftFormat or SwiftLint findings, and `git diff --check` passed.

One first full-suite attempt had a transient unrelated failure in a 204-test shard; the failure-only output was truncated. The complete rerun passed, and no production behavior was weakened to accommodate it.

## Rollout boundary

Deploy this compatible client before the server starts emitting the new unlimited union. The legacy numeric field cannot represent unlimited and intentionally remains `0` during the compatibility window, which an old client would display literally.

No app bundle deployment, pull request, or live UI proof is claimed by this branch.
