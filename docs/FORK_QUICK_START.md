---
summary: "Quick start for safe CodexBar-to-ResearchBar synchronization."
read_when:
  - Checking for upstream CodexBar changes
  - Starting a ResearchBar upstream sync
---

# Fork maintenance quick start

ResearchBar's authoritative remote is `Agentic-Assets/ResearchBar`; its inherited code upstream is
`steipete/CodexBar`. See [`UPSTREAM_SYNC.md`](UPSTREAM_SYNC.md) for the complete conflict policy and proof checklist.

## Check the plan

From a clean, up-to-date `main` checkout after the previous sync PR has landed:

```bash
git remote -v
./Scripts/sync_codexbar.sh --plan
```

The plan fetches `origin` and `upstream`, checks the configured upstream URL and last integrated SHA, and prints the
exact base and upstream SHAs without changing the checkout.

## Start an isolated sync

```bash
./Scripts/sync_codexbar.sh --start
```

The script creates a sibling worktree on `chore/sync-codexbar-YYYY-MM-DD` and begins a no-commit merge there. Resolve
conflicts under the policy in `docs/UPSTREAM_SYNC.md`, update the sync marker and dated proof, run the required checks,
and submit the branch for review.

Never merge upstream directly into `main`, never perform the sync in the live checkout, and never auto-push or
auto-merge the result.

For ordinary ResearchBar development, use `docs/DEVELOPMENT.md`; this page covers fork synchronization only.
