# Synchronizing CodexBar safely

ResearchBar can absorb current CodexBar changes while retaining its Corbis-first product surface. The fork is intentionally structured around this: SwiftPM target and module names remain `CodexBar*`, while public identity and Corbis code have narrow, explicit ownership boundaries.

Never synchronize directly on `main`, in the live checkout, or by pushing/merging automatically.

## Routine workflow

Start from a clean, up-to-date `main` checkout after the last sync PR has landed.

```bash
./Scripts/sync_codexbar.sh --plan
./Scripts/sync_codexbar.sh --start
```

The first command fetches `origin` and `upstream`, verifies the configured CodexBar URL and the last integrated upstream SHA, then prints the exact base and upstream SHAs. It makes no changes.

The second command creates a sibling worktree on `chore/sync-codexbar-YYYY-MM-DD` and performs `git merge --no-commit --no-ff upstream/main` there. It never changes the live checkout, commits, pushes, opens a pull request, or merges `main`.

Use `--branch` or `--worktree` for a unique retry, for example:

```bash
./Scripts/sync_codexbar.sh --start \
  --branch chore/sync-codexbar-2026-08-12-retry \
  --worktree ../researchbar-sync-2026-08-12-retry
```

After resolving, update `ResearchBar/upstream-sync.toml` with the exact merged upstream SHA and add a dated note under `ResearchBar/upstream-syncs/`. Commit that proof on the chore branch. Before merging a reviewed PR, prove the upstream commit is an ancestor of the branch:

```bash
git merge-base --is-ancestor <upstream-sha> HEAD
```

## Conflict policy

Use upstream architecture first, then reapply only ResearchBar product behavior.

| Conflict area | Resolution rule |
| --- | --- |
| `ResearchBar/**`, `Sources/*/ResearchBar/**`, ResearchBar fixtures, `ResearchBar/branding/**` | Product-owned. Preserve deliberately, but review every upstream collision. |
| Provider/CLI/Core implementation | Take current upstream structure. These are inherited machinery, not ResearchBar customization points. |
| `PreferencesView` and `StatusItemController*` | Semantic merge. Keep the upstream provider-instance architecture and graft Corbis in as a provider-independent ResearchBar tab. |
| Packaging, release metadata, app identity, About text, localizations | Retain ResearchBar values via `ResearchBar/branding/identity.env`; fold upstream packaging improvements around them. |
| CI, dependencies, package manifest, generated files | Take upstream, then re-run the repository checks. |

Do not use a repo-wide merge driver, `-X ours`, `-X theirs`, or a whole-file checkout for shared controller code. Those approaches hide API drift and caused the most expensive class of conflicts in this sync.

The upstream JavaScript provider-plugin layer is also not the ResearchBar integration point: Corbis needs native UI, Keychain-backed credentials, and product-specific interactions.

## Required proof

Run these from the isolated sync worktree after the merge is resolved:

```bash
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' --glob '!*.xcodeproj/**'
./Scripts/check_researchbar_identity.sh
swift build
swift build -c release
make check
make test
```

For the final macOS bundle check, use the branding-aware package script and fresh launcher only after the command-line checks pass. The package script is pinned to Apple's Bash because the Homebrew Bash on this host can block while writing large heredocs:

```bash
CODEXBAR_SIGNING=adhoc /bin/bash ./Scripts/package_app.sh release
./Scripts/launch.sh
plutil -extract CFBundleIdentifier raw -o - ResearchBar.app/Contents/Info.plist
codesign --verify --deep --strict --verbose=2 ResearchBar.app
```

`make test` and `make check` are the required Keychain-safe checks. Do not substitute live provider probes, browser imports, or real account reads.

## Current baseline

The 2026-08-05 synchronization incorporates CodexBar commit `4cdb349cbc57780e524d3e874ef582078b9bf7c2`. The previous shared ancestor was `05545feba362ba7626e92d24bf643650a7dff740`.
