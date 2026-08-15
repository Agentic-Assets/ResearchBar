# ResearchBar documentation audit closeout (2026-08-14)

**Branch:** `docs/researchbar-current-doc-audit`  
**Base:** `cf45942db413118e32245bb9c8b8b903165c2ca6`  
**Commit:** `922a29b12b340404e03fb91d77304261714eae6e`  
**State:** local-only documentation branch; no push, PR, merge, release, or runtime launch

## Goal

Remove misleading ResearchBar guidance and make active build, configuration, release, upstream, Corbis-contract, and agent-context documentation agree with current source and packaging behavior.

## What shipped

- Corrected the canonical `CLAUDE.md` bridge, removed literal signing-key material from `AGENTS.md`, and aligned source/module, bundle, logging, widget, config, CLI, release, and upstream-sync guidance with current ResearchBar code and scripts.
- Reclassified June ResearchBar plans, concept reports, and research material as historical evidence where appropriate; current source and current Corbis backend source now own implementation and wire facts.
- Updated the local Corbis wire-contract reference from `agentic-assets-app` `origin/main` commit `c7c87a1527bbc45cc1c201d27fb39f24f99f4075`: POST-only native use, supported protocol versions, and production bearer-token rules.
- Documented two verified implementation gaps honestly: the in-app CLI installer still searches the inherited helper and ResearchBar packaging currently omits a CloudKit entitlement, so the corresponding supported path and unavailable state are explicit.

## Verification

- Independent documentation review found six blocker groups, including stale MCP transport/auth facts, CLI installation guidance, historical authority claims, Sparkle/release drift, and CloudKit claims. One correction wave plus scoped re-review left no Critical or Important finding.
- At commit `922a29b12`, `make check` passed: repository link checks, generated-manifest checks, package/release shell guards, SwiftFormat, and SwiftLint (0 violations in 1,838 files).
- `make docs-list` and `git diff --check` passed. No code tests or live provider, browser, Keychain, package, or launch surfaces ran because this is documentation-only work.

## Decisions made

- Prefer an explicit historical banner over rewriting dated evidence. It preserves provenance without allowing old tool counts, credit assumptions, or implementation phases to masquerade as current instructions.
- Treat the local Corbis guide as a maintained reference, never as a symlink or backend source of truth. Backend source must be rechecked on contract changes.
- Document verified broken/unavailable behavior instead of implying it works. The task did not authorize source or packaging changes.

## Left to the operator

- Decide whether to push `docs/researchbar-current-doc-audit` and open a documentation PR. No remote mutation occurred in this audit.
- Prioritize the verified CLI-installer and CloudKit alignment defects if those features are needed for a release.
