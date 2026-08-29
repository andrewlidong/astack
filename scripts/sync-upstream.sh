#!/usr/bin/env bash
#
# Sync this mirror with upstream pstack (cursor/plugins, pstack/ subdirectory).
#
# Clones upstream into a temp dir, re-runs `git subtree split` on the pstack
# path, and merges the resulting history into the current branch. The split is
# deterministic, so commits already mirrored here reproduce byte-identically and
# only genuinely new upstream work is merged.
#
#   ./scripts/sync-upstream.sh          merge new upstream commits
#   ./scripts/sync-upstream.sh --check  report what is new, change nothing
#
# Overridable: UPSTREAM_URL, UPSTREAM_BRANCH, UPSTREAM_PREFIX

set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/cursor/plugins.git}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-main}"
UPSTREAM_PREFIX="${UPSTREAM_PREFIX:-pstack}"

check_only=0
case "${1-}" in
  --check|-n|--dry-run) check_only=1 ;;
  "") ;;
  *) echo "usage: $0 [--check]" >&2; exit 2 ;;
esac

die() { echo "error: $*" >&2; exit 1; }

repo_root="$(git rev-parse --show-toplevel)" || die "not inside a git repository"
cd "$repo_root"

if [ "$check_only" -eq 0 ] && ! git diff-index --quiet HEAD --; then
  die "working tree has uncommitted changes; commit or stash them first"
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "==> cloning $UPSTREAM_URL ($UPSTREAM_BRANCH)"
git clone --quiet --branch "$UPSTREAM_BRANCH" "$UPSTREAM_URL" "$work/upstream"

upstream_sha="$(git -C "$work/upstream" rev-parse --short HEAD)"

echo "==> splitting $UPSTREAM_PREFIX/ out of $upstream_sha"
git -C "$work/upstream" subtree split --prefix="$UPSTREAM_PREFIX" -b pstack-only >/dev/null 2>&1 \
  || die "subtree split failed; does $UPSTREAM_PREFIX/ still exist upstream?"

echo "==> fetching split history"
git fetch --quiet "$work/upstream" pstack-only
split_sha="$(git rev-parse FETCH_HEAD)"

if git merge-base --is-ancestor "$split_sha" HEAD; then
  echo "Already up to date with $UPSTREAM_PREFIX @ $upstream_sha."
  exit 0
fi

if ! git merge-base --is-ancestor "$(git rev-list --max-parents=0 "$split_sha" | tail -1)" HEAD; then
  die "no shared history with the upstream split; this branch is not a pstack mirror"
fi

new_count="$(git rev-list --count HEAD.."$split_sha")"
echo
echo "$new_count new upstream commit(s):"
git log --format='  %h %ad %an  %s' --date=short HEAD.."$split_sha"
echo

if [ "$check_only" -eq 1 ]; then
  echo "(--check: nothing merged)"
  exit 0
fi

echo "==> merging"
git merge --no-edit -m "Sync with upstream pstack @ $upstream_sha" "$split_sha"
echo
echo "Merged. Review with: git log --oneline -n $((new_count + 1))"
