#!/bin/bash
# Prepare, never complete, a CodexBar upstream synchronization in an isolated worktree.
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "ERROR: Run this command inside the ResearchBar repository." >&2
  exit 1
}
cd "$ROOT"

CONFIG="$ROOT/ResearchBar/upstream-sync.toml"
MODE="plan"
BRANCH=""
WORKTREE=""

usage() {
  cat <<'EOF'
Usage: ./Scripts/sync_codexbar.sh [--plan | --start] [--branch NAME] [--worktree PATH]

  --plan     Fetch and print the exact merge plan. This is the default and makes no changes.
  --start    Create an isolated chore/sync-codexbar-* worktree and begin a no-commit merge there.

The script never commits, pushes, opens a pull request, or merges main.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan) MODE="plan" ;;
    --start) MODE="start" ;;
    --branch)
      shift
      BRANCH="${1:-}"
      ;;
    --worktree)
      shift
      WORKTREE="${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Missing synchronization manifest: $CONFIG" >&2
  exit 1
fi

toml_value() {
  local key="$1"
  sed -n -E "s/^${key}[[:space:]]*=[[:space:]]*\"([^\"]+)\"[[:space:]]*$/\1/p" "$CONFIG" | head -1
}

REMOTE=$(toml_value remote)
EXPECTED_URL=$(toml_value url)
UPSTREAM_BRANCH=$(toml_value branch)
LAST_MERGED_SHA=$(toml_value last_merged_sha)

if [[ -z "$REMOTE" || -z "$EXPECTED_URL" || -z "$UPSTREAM_BRANCH" || -z "$LAST_MERGED_SHA" ]]; then
  echo "ERROR: Synchronization manifest is incomplete: $CONFIG" >&2
  exit 1
fi

canonical_remote_url() {
  local url="$1"
  url="${url%.git}"
  url="${url#https://github.com/}"
  url="${url#http://github.com/}"
  url="${url#git@github.com:}"
  printf '%s\n' "$url"
}

if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "ERROR: Required remote '$REMOTE' is not configured. Add $EXPECTED_URL explicitly, then retry." >&2
  exit 1
fi
ACTUAL_URL=$(git remote get-url "$REMOTE")
if [[ "$(canonical_remote_url "$ACTUAL_URL")" != "$(canonical_remote_url "$EXPECTED_URL")" ]]; then
  echo "ERROR: Remote '$REMOTE' is '$ACTUAL_URL', not the expected CodexBar repository '$EXPECTED_URL'." >&2
  exit 1
fi

if [[ -n "$(git rev-parse -q --verify MERGE_HEAD 2>/dev/null || true)" ||
      -n "$(git rev-parse -q --verify CHERRY_PICK_HEAD 2>/dev/null || true)" ||
      -n "$(git rev-parse -q --verify REBASE_HEAD 2>/dev/null || true)" ]]; then
  echo "ERROR: Finish or abort the current Git operation before preparing another upstream sync." >&2
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: The live checkout is not clean. Commit, stash, or use a separate checkout first." >&2
  exit 1
fi

git fetch origin --prune
git fetch "$REMOTE" --prune

BASE_REF="origin/main"
UPSTREAM_REF="$REMOTE/$UPSTREAM_BRANCH"
git rev-parse --verify -q "$BASE_REF" >/dev/null || {
  echo "ERROR: Missing $BASE_REF after fetch." >&2
  exit 1
}
git rev-parse --verify -q "$UPSTREAM_REF" >/dev/null || {
  echo "ERROR: Missing $UPSTREAM_REF after fetch." >&2
  exit 1
}

if ! git merge-base --is-ancestor "$LAST_MERGED_SHA" "$BASE_REF"; then
  echo "ERROR: last_merged_sha is not an ancestor of $BASE_REF. Review the marker or a history rewrite." >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$LAST_MERGED_SHA" "$UPSTREAM_REF"; then
  echo "ERROR: last_merged_sha is not an ancestor of $UPSTREAM_REF. Upstream history may have been rewritten." >&2
  exit 1
fi

BASE_SHA=$(git rev-parse "$BASE_REF")
UPSTREAM_SHA=$(git rev-parse "$UPSTREAM_REF")
read -r BASE_ONLY UPSTREAM_ONLY < <(git rev-list --left-right --count "$BASE_REF...$UPSTREAM_REF")

echo "ResearchBar CodexBar sync plan"
echo "  base:     $BASE_REF ($BASE_SHA)"
echo "  upstream: $UPSTREAM_REF ($UPSTREAM_SHA)"
echo "  marker:   $LAST_MERGED_SHA"
echo "  commits:  $BASE_ONLY ResearchBar-only, $UPSTREAM_ONLY upstream-only"
echo
git diff --stat "$BASE_REF...$UPSTREAM_REF"

if [[ "$MODE" == "plan" ]]; then
  echo
  echo "No changes made. Re-run with --start to create an isolated merge worktree."
  exit 0
fi

DATE=$(date +%Y-%m-%d)
if [[ -z "$BRANCH" ]]; then
  BRANCH="chore/sync-codexbar-$DATE"
fi
if [[ -z "$WORKTREE" ]]; then
  WORKTREE="$(dirname "$ROOT")/researchbar-sync-$DATE"
fi

if git show-ref --verify --quiet "refs/heads/$BRANCH" || git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  echo "ERROR: Branch '$BRANCH' already exists. Supply a distinct --branch name." >&2
  exit 1
fi
if [[ -e "$WORKTREE" ]]; then
  echo "ERROR: Worktree path already exists: $WORKTREE" >&2
  exit 1
fi

git worktree add -b "$BRANCH" "$WORKTREE" "$BASE_REF"
echo "\nStarted isolated sync worktree: $WORKTREE"
echo "Branch: $BRANCH"
echo "Merging $UPSTREAM_REF without committing..."
if git -C "$WORKTREE" merge --no-commit --no-ff "$UPSTREAM_REF"; then
  echo "\nMerge applied with no textual conflicts. Review the diff, run the documented checks, and commit only when ready."
else
  echo "\nMerge stopped with conflicts in $WORKTREE. Resolve them semantically; do not use a blanket ours/theirs strategy."
  echo "Run: git -C '$WORKTREE' diff --name-only --diff-filter=U"
  exit 2
fi
