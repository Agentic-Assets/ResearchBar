---
summary: "ResearchBar's current CodexBar upstream strategy and source-of-truth links."
read_when:
  - Deciding how to absorb upstream CodexBar changes
  - Resolving an upstream-sync conflict
---

# Upstream strategy

ResearchBar has one authoritative inherited-code upstream:

- Product repository: `https://github.com/Agentic-Assets/ResearchBar.git` (`origin`)
- Inherited CodexBar repository: `https://github.com/steipete/CodexBar.git` (`upstream`)

The long multi-upstream strategy previously documented here described an older personal fork and is obsolete. Do not
use its personal `origin`, comparison remotes, direct-merge commands, or historical automation examples.

## Current policy

[`UPSTREAM_SYNC.md`](UPSTREAM_SYNC.md) is the canonical operational guide. In summary:

1. Run `./Scripts/sync_codexbar.sh --plan` from a clean, current `main` checkout.
2. Run `./Scripts/sync_codexbar.sh --start` to create an isolated `chore/sync-codexbar-*` worktree and no-commit merge.
3. Prefer upstream architecture for inherited provider, CLI, core, dependency, CI, and generated-file changes.
4. Reapply ResearchBar's Corbis-first product behavior and identity only at the owned boundaries defined in the
   canonical guide.
5. Record the exact integrated upstream SHA in `ResearchBar/upstream-sync.toml` and add the dated sync note.
6. Run the required proof suite and submit the task branch for review.

Never synchronize directly on `main`, never sync in the live checkout, and never commit, push, open a pull request, or
merge automatically as part of the synchronization script.

## Contributing inherited fixes upstream

Keep an upstream contribution narrowly scoped to generally useful CodexBar behavior. Exclude ResearchBar branding,
Corbis product behavior, Agentic Assets release configuration, and ResearchBar-only evidence. Base the contribution on
the current `upstream/main`, review its diff against `upstream/main`, and follow the upstream repository's own
contribution rules. This is separate from integrating upstream changes into ResearchBar.
