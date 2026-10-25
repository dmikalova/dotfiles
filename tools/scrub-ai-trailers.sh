#!/usr/bin/env bash
# Remove Claude and Copilot attribution lines from the commit messages on the
# default branch of each repo that the owner has. Dry run by default.
#
#   scrub-ai-trailers.sh                  report, change nothing
#   scrub-ai-trailers.sh --local REPO...  rewrite in a temp clone, no push
#   scrub-ai-trailers.sh --apply [REPO...] rewrite and force push
#
# Only the commits from the oldest match to the tip are rewritten. Each one is
# signed again with your key and gets you as committer, because the "main"
# ruleset requires verified signatures. The original dates stay. Tags on the
# rewritten commits move to the new commits.
#
# The ruleset blocks force pushes, so --apply sets it to disabled for the push
# and sets it back to active after, also on failure.
#
# Forks and archived repos are skipped. Other branches are not rewritten. A
# warning names them, because they still hold the old commits.
set -euo pipefail

owner=dmikalova
mode=report
repos=()
for arg in "$@"; do
  case "$arg" in
  --apply) mode=apply ;;
  --local) mode=local ;;
  -*)
    echo "unknown flag: $arg" >&2
    exit 2
    ;;
  *) repos+=("$arg") ;;
  esac
done

# ERE for git log --grep, and the same match in Perl for the message filter.
grep_re='^co-authored-by:.*(claude|copilot|anthropic)|generated with \[?claude code'
# shellcheck disable=SC2016 # expanded by filter-branch, not here
msg_filter='perl -ne '\''print unless /^co-authored-by:.*(claude|copilot|anthropic)/i || /generated with \[?claude code/i'\'' | git stripspace'

name=$(git config user.name)
email=$(git config user.email)
commit_filter="GIT_COMMITTER_NAME='$name' GIT_COMMITTER_EMAIL='$email' git commit-tree -S \"\$@\""

work=$(mktemp -d)
ruleset=""
current=""

restore() {
  if [ -n "$ruleset" ]; then
    gh api -X PUT "repos/$owner/$current/rulesets/$ruleset" -f enforcement=active >/dev/null &&
      echo "  ruleset active again" ||
      echo "  FAILED to set the ruleset of $current to active; fix it by hand" >&2
    ruleset=""
  fi
}
cleanup() {
  restore
  if [ "$mode" = local ]; then
    echo "clones kept in $work"
  else
    rm -rf "$work"
  fi
}
trap cleanup EXIT

if [ ${#repos[@]} -eq 0 ]; then
  mapfile -t repos < <(gh repo list "$owner" --source --no-archived --limit 500 --json name --jq '.[].name')
fi

for repo in "${repos[@]}"; do
  dir="$work/$repo"
  git clone -q "https://github.com/$owner/$repo.git" "$dir" 2>/dev/null || {
    echo "$repo: clone failed, skipped"
    continue
  }
  branch=$(git -C "$dir" symbolic-ref --short HEAD)
  if ! git -C "$dir" rev-parse -q --verify HEAD >/dev/null; then
    echo "$repo: empty"
    continue
  fi

  mapfile -t hits < <(git -C "$dir" log --format=%H -E -i --grep="$grep_re" "$branch")
  if [ ${#hits[@]} -eq 0 ]; then
    echo "$repo: clean"
    continue
  fi
  oldest=${hits[${#hits[@]} - 1]}
  total=$(git -C "$dir" rev-list --count "$branch" ^"$oldest^" 2>/dev/null || git -C "$dir" rev-list --count "$branch")
  echo "$repo: ${#hits[@]} commits with attribution; $total commits to rewrite on $branch"
  echo "  oldest: $(git -C "$dir" log -1 --format='%h %ad %s' --date=short "$oldest")"

  others=$(git -C "$dir" branch -r --format='%(refname:short)' | grep -v -e '^origin$' -e '^origin/HEAD$' -e "^origin/$branch\$" || true)
  [ -z "$others" ] || echo "  warning: other branches keep the old commits: $(echo "$others" | tr '\n' ' ')"

  [ "$mode" = report ] && continue

  old_tip=$(git -C "$dir" rev-parse "$branch")
  old_tree=$(git -C "$dir" rev-parse "$branch^{tree}")
  mapfile -t tags < <(git -C "$dir" tag --contains "$oldest")
  bound=()
  if git -C "$dir" rev-parse -q --verify "$oldest^" >/dev/null; then
    bound=("^$oldest^")
  fi

  (
    cd "$dir"
    FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f \
      --msg-filter "$msg_filter" \
      --commit-filter "$commit_filter" \
      --tag-name-filter cat \
      -- "$branch" "${tags[@]/#/refs/tags/}" "${bound[@]}" >/dev/null 2>&1
  )

  left=$(git -C "$dir" log --format=%H -E -i --grep="$grep_re" "$branch" | wc -l | tr -d ' ')
  new_tree=$(git -C "$dir" rev-parse "$branch^{tree}")
  if [ "$left" != 0 ] || [ "$new_tree" != "$old_tree" ]; then
    echo "  FAILED: $left matches left, tree same: $([ "$new_tree" = "$old_tree" ] && echo yes || echo no)" >&2
    exit 1
  fi
  echo "  rewritten: $old_tip -> $(git -C "$dir" rev-parse "$branch"), ${#tags[@]} tags moved"

  [ "$mode" = local ] && continue

  current=$repo
  ruleset=$(gh api "repos/$owner/$repo/rulesets" --jq '.[] | select(.name == "main") | .id')
  if [ -n "$ruleset" ]; then
    gh api -X PUT "repos/$owner/$repo/rulesets/$ruleset" -f enforcement=disabled >/dev/null
  fi
  git -C "$dir" push -q --force-with-lease="$branch:$old_tip" origin "$branch"
  for tag in "${tags[@]}"; do
    git -C "$dir" push -q -f origin "refs/tags/$tag"
  done
  restore
  echo "  pushed. In a local clone run: git fetch -f --tags && git reset --hard origin/$branch"
done
