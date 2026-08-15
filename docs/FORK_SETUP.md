---
summary: "ResearchBar fork remotes and the safe CodexBar synchronization entrypoint."
read_when:
  - Configuring the ResearchBar repository remotes
  - Preparing to synchronize CodexBar upstream changes
---

# ResearchBar fork setup

ResearchBar is the Agentic Assets fork of CodexBar. The current repository remotes are:

- `origin`: `https://github.com/Agentic-Assets/ResearchBar.git`
- `upstream`: `https://github.com/steipete/CodexBar.git`

Verify the checkout rather than copying stale personal-fork URLs:

```bash
git remote -v
git remote get-url origin
git remote get-url upstream
```

If `upstream` is missing, add only the canonical CodexBar repository:

```bash
git remote add upstream https://github.com/steipete/CodexBar.git
git fetch upstream
```

Do not replace the Agentic Assets `origin` with a personal fork. Do not add historical comparison repositories as
authoritative upstreams.

## Synchronize safely

[`UPSTREAM_SYNC.md`](UPSTREAM_SYNC.md) is the canonical workflow. Start with its read-only plan:

```bash
./Scripts/sync_codexbar.sh --plan
```

When the plan is correct, `--start` creates an isolated worktree and a `chore/sync-codexbar-*` branch:

```bash
./Scripts/sync_codexbar.sh --start
```

Never merge upstream changes directly on `main`, in the live checkout, or without review. The sync script does not
commit, push, open a pull request, or merge `main`; complete those steps on the task branch under the repository's
normal review and approval rules.

The old multi-upstream examples formerly kept in this file are historical and are not valid ResearchBar operations.
