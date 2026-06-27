# GitHub PR housekeeping scripts
# Requires: gh, jq

# Sweep open PRs in a repo:
#  - Assign me to PRs I opened that aren't already assigned to me
#  - Re-request review from reviewers whose review predates my latest commit
#  - Report PRs with merge conflicts or unresolved review comments
#  - Report non-draft PRs with no reviewers
#  - Report non-draft PRs with failing required/CI checks
#
# Usage: gh-pr-sweep <owner/repo|github url>
gh-pr-sweep() {
	emulate -L zsh
	setopt local_options pipefail no_monitor no_notify

	local input="$1"
	if [[ -z "$input" ]]; then
		echo "Usage: gh-pr-sweep <owner/repo|github url>" >&2
		return 1
	fi

	if ! command -v gh >/dev/null 2>&1; then
		echo "gh CLI not found" >&2
		return 1
	fi
	if ! command -v jq >/dev/null 2>&1; then
		echo "jq not found" >&2
		return 1
	fi

	# Retry helper for gh API calls. GitHub returns transient 5xx errors
	# (especially under parallel load). Runs the command up to 3 times with
	# 1s, 2s backoff, suppressing stderr until the final attempt.
	_gh_retry() {
		local attempt
		for attempt in 1 2 3; do
			if ((attempt < 3)); then
				"$@" 2>/dev/null && return 0
				sleep $attempt
			else
				"$@" && return 0
			fi
		done
		return 1
	}

	# Normalize to owner/repo
	local repo="$input"
	repo="${repo#http://github.com/}"
	repo="${repo#https://github.com/}"
	repo="${repo#git@github.com:}"
	repo="${repo%.git}"
	repo="${repo%/}"
	if [[ "$repo" != */* ]]; then
		echo "Could not parse owner/repo from: $input" >&2
		return 1
	fi
	local owner="${repo%%/*}"
	local name="${repo##*/}"

	local me
	me=$(_gh_retry gh api user --jq .login) || return 1

	echo "Sweeping open PRs in $repo as @$me..."

	# Fetch all open PRs I opened, with the fields needed for the actions.
	local mine
	mine=$(_gh_retry gh pr list \
		--repo "$repo" \
		--author "@me" \
		--state open \
		--limit 200 \
		--json number,url,title,isDraft,assignees,reviewRequests,latestReviews,mergeable,mergeStateStatus,reviewDecision,baseRefName,headRefName,headRepositoryOwner,isCrossRepository,statusCheckRollup) || return 1

	if [[ "$(printf '%s' "$mine" | jq 'length')" == "0" ]]; then
		echo "No open PRs authored by you."
		return 0
	fi

	# PRs needing my attention. Each PR is processed independently in a
	# background job and writes its result into per-PR files in $tmpdir,
	# so there's no shared-state dedup needed.

	# Detect terminal width for truncating long titles.
	local cols=${COLUMNS:-0}
	if ((cols == 0)); then
		cols=$(tput cols 2>/dev/null) || cols=80
	fi

	# Format a PR entry as two lines: "  #NUM  <title><suffix>" then the URL
	# indented to align with the title. Title is truncated with ... so the
	# whole first line (including any suffix) fits in $cols.
	_pr_entry() {
		local _num=$1 _title=$2 _url=$3 _suffix=${4:-}
		local _prefix="  #${_num}  "
		local _indent
		printf -v _indent '%*s' ${#_prefix} ''
		local _max=$((cols - ${#_prefix} - ${#_suffix}))
		if ((_max < 4)); then _max=4; fi
		if ((${#_title} > _max)); then
			_title="${_title[1,_max-3]}..."
		fi
		printf '%s%s%s\n%s%s\n' "$_prefix" "$_title" "$_suffix" "$_indent" "$_url"
	}

	# Process one PR. Writes action logs to $log_file and (if the PR needs
	# attention) writes a formatted entry to $att_file. Designed to run in
	# a background subshell so PRs are processed in parallel.
	_process_pr() {
		local pr=$1 log_file=$2 att_file=$3

		# Parse all needed fields in a single jq invocation.
		local -a F
		F=("${(@f)$(jq -r --arg me "$me" '
			. as $pr |
			([(.reviewRequests // [])[] | (.login // .name // "")] | map(select(. != ""))) as $requested |
			([(.statusCheckRollup // [])[] | select(
				((.state // "") == "FAILURE") or ((.state // "") == "ERROR") or
				((.conclusion // "") == "FAILURE") or ((.conclusion // "") == "TIMED_OUT") or
				((.conclusion // "") == "ACTION_REQUIRED") or ((.conclusion // "") == "STARTUP_FAILURE")
			)] | length) as $failing |
			$pr.number,
			$pr.url,
			($pr.title | gsub("[\n\r]"; "  ")),
			$pr.isDraft,
			([$pr.assignees[].login] | index($me) != null),
			$pr.mergeable,
			$pr.mergeStateStatus,
			(((($pr.reviewRequests // []) | length) + (($pr.latestReviews // []) | length)) > 0),
			$pr.baseRefName,
			$pr.headRefName,
			($pr.headRepositoryOwner.login // ""),
			$pr.isCrossRepository,
			$failing,
			($requested | join(","))
		' <<<"$pr")}")
		local num=$F[1] url=$F[2] title=$F[3] is_draft=$F[4] assigned=$F[5]
		local mergeable=$F[6] mss=$F[7] has_reviewer=$F[8]
		local base_ref=$F[9] head_ref=$F[10] head_owner=$F[11] is_cross=$F[12]
		local failing_checks=$F[13] requested_csv=$F[14]

		# Re-request reviewers come from the batched GraphQL pass (filtered to
		# reviewers whose review commit oid != headRefOid). Drop any reviewer
		# already in the current request list.
		local rerequest=""
		if [[ -n "${pr_rerequest[$num]:-}" ]]; then
			local _candidate _r
			local -a _keep
			for _candidate in ${(s:,:)pr_rerequest[$num]}; do
				# Skip self and anyone already in the request list
				if [[ "$_candidate" == "$me" ]]; then continue; fi
				local _skip=0
				for _r in ${(s:,:)requested_csv}; do
					if [[ "$_r" == "$_candidate" ]]; then
						_skip=1
						break
					fi
				done
				((_skip)) || _keep+=("$_candidate")
			done
			rerequest="${(j:,:)_keep}"
		fi

		# One-shot refresh if mergeable/mss is UNKNOWN (no sleep — if still
		# UNKNOWN after one fetch we just skip the conflict check; the compare
		# API below is the authoritative source for "behind base").
		if [[ "$mss" == "UNKNOWN" || "$mergeable" == "UNKNOWN" ]]; then
			local _refresh
			_refresh=$(_gh_retry gh pr view "$num" --repo "$repo" --json mergeable,mergeStateStatus)
			if [[ -n "$_refresh" ]]; then
				local -a R
				R=("${(@f)$(jq -r '.mergeable, .mergeStateStatus' <<<"$_refresh")}")
				mergeable=$R[1]
				mss=$R[2]
			fi
		fi

		# 1. Assign me if not already assigned.
		if [[ "$assigned" != "true" ]]; then
			echo "  [#$num] assigning to @$me" >>"$log_file"
			gh pr edit "$num" --repo "$repo" --add-assignee "$me" >/dev/null 2>&1 ||
				echo "    failed to assign #$num" >>"$log_file"
		fi

		# 2. Re-request review from reviewers whose review commit oid no
		# longer matches the PR head (matches GitHub's UI re-request trigger;
		# skip drafts).
		if [[ "$is_draft" != "true" && -n "$rerequest" ]]; then
			local -a _args
			_args=(--method POST "repos/$repo/pulls/$num/requested_reviewers")
			local _rv
			for _rv in ${(s:,:)rerequest}; do
				_args+=(-f "reviewers[]=$_rv")
			done
			echo "  [#$num] re-requesting review from ${rerequest//,/, }" >>"$log_file"
			gh api "${_args[@]}" >/dev/null 2>&1 ||
				echo "    failed to re-request reviewers on #$num" >>"$log_file"
		fi

		# Attention checks (drafts skip all).
		if [[ "$is_draft" == "true" ]]; then return; fi

		local -a reasons

		# 3a. Merge conflicts.
		if [[ "$mergeable" == "CONFLICTING" || "$mss" == "DIRTY" ]]; then
			reasons+=("conflict")
		fi

		# 3b. Unresolved review threads where I'm not the last commenter.
		# Uses the pre-fetched batched graphql data.
		if ((${pr_threads[$num]:-0} > 0)); then
			reasons+=("${pr_threads[$num]} unresolved")
		fi

		# 3c. No reviewer.
		if [[ "$has_reviewer" != "true" ]]; then
			reasons+=("no reviewer")
		fi

		# 3d. Failing checks.
		if ((${failing_checks:-0} > 0)); then
			reasons+=("$failing_checks checks failing")
		fi

		# 3e. Unread comment (last comment is not from me).
		if [[ -n "${pr_last_comment[$num]:-}" && "${pr_last_comment[$num]}" != "$me" ]]; then
			reasons+=("comment from ${pr_last_comment[$num]}")
		fi

		if ((${#reasons[@]})); then
			local suffix="  (${(j:, :)reasons})"
			_pr_entry "$num" "$title" "$url" "$suffix" >"$att_file"
		fi
	}

	# Spawn a job per PR with a concurrency cap to avoid hammering the API.
	local tmpdir
	tmpdir=$(mktemp -d) || return 1
	# shellcheck disable=SC2064
	trap "rm -rf '$tmpdir'" EXIT INT TERM

	# First pass: collect PR numbers + JSON in order (we need the full list
	# before we can build the batched graphql query).
	local -a nums prs
	local pr num
	while IFS= read -r pr; do
		num=$(jq -r '.number' <<<"$pr")
		nums+=("$num")
		prs+=("$pr")
	done < <(jq -c 'sort_by(.number) | .[]' <<<"$mine")

	# Batched GraphQL: chunk PRs into small parallel queries. One big query
	# is server-side slow because reviewThreads(first:100) expands the cost
	# per PR; splitting into chunks of ~10 and running them in parallel
	# returns the data much faster. We fetch reviewThreads (for the unresolved
	# thread check), plus headRefOid and latestReviews { author, state,
	# commit.oid } so we can detect reviewers whose review predates the
	# current head commit (matches GitHub's UI "Re-request review" trigger).
	# mergeable/mergeStateStatus come from `gh pr list` (with a per-PR REST
	# fallback in _process_pr if they were UNKNOWN), so they stay out of
	# the graphql payload.
	typeset -A pr_threads pr_rerequest pr_last_comment
	if ((${#nums[@]})); then
		local chunk_size=10
		local -a chunk_pids chunk_files
		local chunk_idx=0 chunk_start=1
		while ((chunk_start <= ${#nums[@]})); do
			local chunk_end=$((chunk_start + chunk_size - 1))
			((chunk_end > ${#nums[@]})) && chunk_end=${#nums[@]}
			local chunk_file="$tmpdir/chunk.$chunk_idx.tsv"
			chunk_files+=("$chunk_file")
			(
				local q='query{repository(owner:"'$owner'",name:"'$name'"){'
				local _ci
				for ((_ci = chunk_start; _ci <= chunk_end; _ci++)); do
					q+=" pr${nums[$_ci]}:pullRequest(number:${nums[$_ci]}){headRefOid latestReviews(first:50){nodes{author{login} state commit{oid}}} reviewThreads(first:100){nodes{isResolved comments(last:1){nodes{author{login}}}}} comments(last:1){nodes{author{login}}}}"
				done
				q+='}}'
				_gh_retry gh api graphql -f query="$q" --jq "
					.data.repository | to_entries[] | [
						(.key | sub(\"^pr\"; \"\")),
						([.value.reviewThreads.nodes[]
							| select(.isResolved==false)
							| select((.comments.nodes | last | .author.login) != \"$me\")
						] | length),
						(.value.headRefOid as \$head |
							[.value.latestReviews.nodes[]
								| select(.author.login != \"$me\")
								| select(.state == \"APPROVED\" or .state == \"CHANGES_REQUESTED\")
								| select(.commit.oid != \$head)
								| .author.login
							] | unique | join(\",\") | if . == \"\" then \"-\" else . end),
						(.value.comments.nodes | last | .author.login // \"-\")
					] | @tsv
				" >"$chunk_file" 2>/dev/null
			) &
			chunk_pids+=($!)
			((chunk_start = chunk_end + 1))
			((chunk_idx++))
		done
		# Wait for all chunks
		local _p
		for _p in $chunk_pids; do wait $_p; done
		# Merge results
		local _k _t _rr _cf
		for _cf in $chunk_files; do
			while IFS=$'\t' read -r _k _t _rr _lc; do
				[[ -z "$_k" ]] && continue
				pr_threads[$_k]=$_t
				[[ "$_rr" == "-" ]] && _rr=""
				[[ "$_lc" == "-" ]] && _lc=""
				pr_rerequest[$_k]=$_rr
				pr_last_comment[$_k]=$_lc
			done <"$_cf"
		done
	fi

	local max_concurrent=25
	local -a pids
	local i=1
	for pr in $prs; do
		num=$nums[$i]
		_process_pr "$pr" "$tmpdir/$num.log" "$tmpdir/$num.att" &
		pids+=($!)
		if ((${#pids[@]} >= max_concurrent)); then
			wait $pids[1]
			pids=("${pids[@]:1}")
		fi
		((i++))
	done
	wait

	# Action logs in PR order.
	local n
	for n in $nums; do
		[[ -s "$tmpdir/$n.log" ]] && cat "$tmpdir/$n.log"
	done

	# Attention entries in PR order.
	local attention=()
	for n in $nums; do
		if [[ -s "$tmpdir/$n.att" ]]; then
			attention+=("$(<"$tmpdir/$n.att")")
		fi
	done

	echo
	if ((${#attention[@]})); then
		echo "PRs needing attention:"
		for ((i = 1; i <= ${#attention[@]}; i++)); do
			((i > 1)) && echo
			printf '%s\n' "${attention[i]}"
		done
	else
		echo "All clean."
	fi
}

# List my draft PRs in a repo.
# Usage: gh-pr-drafts <owner/repo|github url>
gh-pr-drafts() {
	emulate -L zsh
	setopt local_options pipefail

	local input="$1"
	if [[ -z "$input" ]]; then
		echo "Usage: gh-pr-drafts <owner/repo|github url>" >&2
		return 1
	fi

	if ! command -v gh >/dev/null 2>&1; then
		echo "gh CLI not found" >&2
		return 1
	fi

	# Normalize to owner/repo
	local repo="$input"
	repo="${repo#http://github.com/}"
	repo="${repo#https://github.com/}"
	repo="${repo#git@github.com:}"
	repo="${repo%.git}"
	repo="${repo%/}"
	if [[ "$repo" != */* ]]; then
		echo "Could not parse owner/repo from: $input" >&2
		return 1
	fi

	local drafts
	drafts=$(gh pr list \
		--repo "$repo" \
		--author "@me" \
		--state open \
		--draft \
		--limit 200 \
		--json number,url,title) || return 1

	local count
	count=$(printf '%s' "$drafts" | jq 'length')
	if [[ "$count" == "0" ]]; then
		echo "No draft PRs."
		return 0
	fi

	local cols=${COLUMNS:-0}
	if ((cols == 0)); then
		cols=$(tput cols 2>/dev/null) || cols=80
	fi

	echo "Draft PRs in $repo ($count):"
	local first=1
	printf '%s' "$drafts" | jq -r 'sort_by(.number) | .[] | [.number, .title, .url] | @tsv' |
		while IFS=$'\t' read -r num title url; do
			((first)) && first=0 || echo
			local prefix="  #${num}  "
			local indent=${(l:${#prefix}:: :)}
			local max=$((cols - ${#prefix}))
			if ((max < 4)); then max=4; fi
			if ((${#title} > max)); then
				title="${title[1,max-3]}..."
			fi
			printf '%s%s\n%s%s\n' "$prefix" "$title" "$indent" "$url"
		done
}

gh-dmikalova-uncommitted() {
	local base_dir="/Users/david.mikalova/Code/github.com/dmikalova"
	for dir in "$base_dir"/*(N/); do
		if git -C "$dir" status --porcelain 2>/dev/null | grep -q .; then
			cd "$dir"
			echo "Uncommitted changes in: ${dir:t}"
			return 0
		fi
	done
	echo "No uncommitted changes found."
}

# Semantic commit and push.
# Stages all changes, uses AI to write a semantic commit message, then pushes.

# Return AI output starting at the first conventional-commit style line.
_from_first_cc_line() {
	local _text="$1"
	printf '%s\n' "$_text" | awk '
		BEGIN { found = 0 }
		{
			if (!found && $0 ~ /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)[(:]/) {
				found = 1
			}
			if (found) print
		}
	'
}

coco() {
	# Don't run from the default branch
	local current_branch
	current_branch=$(git branch --show-current)
	local default_branch
	default_branch=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
	if [[ "$current_branch" == "${default_branch:-main}" ]]; then
		echo "Cannot commit from the default branch ($current_branch)." >&2
		return 1
	fi

	# Check there are changes to commit
	if [[ -z "$(git status --porcelain 2>/dev/null)" ]]; then
		echo "Nothing to commit - working tree is clean." >&2
		return 1
	fi

	# Stage all changes
	echo "Staging all changes..."
	git add -A || return 1

	# Run pre-commit hooks before spending time on AI
	echo "Running pre-commit hooks..."
	git hook run pre-commit || return 1

	# Generate commit message via AI
	echo "Generating commit message..."
	local msg
	msg=$(git diff --cached | copilot -p \
		"Write a semantic commit message (conventional commits format) for this diff. Output ONLY the commit message, nothing else. Use a short subject line and optionally a body separated by a blank line." \
		--model gemini-3.5-flash --effort none -s)
	if [[ -z "$msg" ]]; then
		echo "Failed to generate commit message." >&2
		return 1
	fi

	# Drop any AI preface before the first conventional-commit line.
	msg="$(_from_first_cc_line "$msg")"
	if [[ -z "$msg" ]]; then
		echo "AI output missing a conventional commit title." >&2
		return 1
	fi

	# Show and confirm
	echo "\nCommit message:\n$msg\n"

	# Commit (hooks already passed)
	git commit -n -m "$msg" || return 1

	# Push
	echo "Pushing..."
	git push || return 1
}

# Create a PR with AI-generated description.
# Requires all changes to be already committed.
copr() {
	# Don't run from the default branch
	local current_branch
	current_branch=$(git branch --show-current)
	local default_branch
	default_branch=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
	if [[ -z "$default_branch" ]]; then default_branch="main"; fi
	if [[ "$current_branch" == "$default_branch" ]]; then
		echo "Cannot create PR from the default branch ($current_branch)." >&2
		return 1
	fi

	# Check working tree is clean
	if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
		echo "Uncommitted changes exist. Commit or stash them first." >&2
		return 1
	fi

	# Push current branch
	echo "Pushing..."
	git push -u origin HEAD || return 1

	# Generate PR title and body via AI in a single call
	echo "Generating PR title and description..."
	local diff_content result title body
	diff_content=$(git diff "$default_branch"...HEAD)

	result=$(echo "$diff_content" | copilot -p \
		"Write a PR title and description for this diff. Summarize these changes with high information density, covering all major points without conversational filler. Format: first line is the title (semantic/conventional commits format, no quotes), then a blank line, then the markdown description body with a brief summary and list of key changes. Output ONLY this, nothing else." \
		--model gemini-3.5-flash --effort none -s)
	if [[ -z "$result" ]]; then
		echo "Failed to generate PR description." >&2
		return 1
	fi

	# Drop AI preface and keep output starting from the first valid title line.
	local cc_block
	cc_block="$(_from_first_cc_line "$result")"
	if [[ -n "$cc_block" ]]; then
		result="$cc_block"
	fi

	title="${result%%$'\n'*}"
	body="${result#*$'\n'$'\n'}"
	if [[ "$body" == "$result" ]]; then
		body="${result#*$'\n'}"
	fi

	if ! [[ "$title" =~ '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)[(:]' ]]; then
		title="$(git log --format=%s "$default_branch"...HEAD | head -n 1)"
		if ! [[ "$title" =~ '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)[(:]' ]]; then
			title="chore: summarize branch changes"
		fi
	fi

	echo "\nTitle:\n$title"
	echo "\nDescription:\n$body\n"

	# Create or update the PR
	local existing_pr
	existing_pr=$(gh pr view --json number --jq .number 2>/dev/null)
	if [[ -n "$existing_pr" ]]; then
		echo "Updating existing PR #$existing_pr..."
		gh pr edit "$existing_pr" --title "$title" --body "$body" || return 1
	else
		# --reviewer cbeauroll,cfavroth,malya-reddirouthu --reviewer crunchyroll/devops \
		gh pr create --base "$default_branch" --assignee @me \
			--title "$title" --body "$body" || return 1
	fi
}

# Create a draft PR with AI-generated description.
# Requires all changes to be already committed.
coprd() {
	# Don't run from the default branch
	local current_branch
	current_branch=$(git branch --show-current)
	local default_branch
	default_branch=$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p')
	if [[ -z "$default_branch" ]]; then default_branch="main"; fi
	if [[ "$current_branch" == "$default_branch" ]]; then
		echo "Cannot create PR from the default branch ($current_branch)." >&2
		return 1
	fi

	# Check working tree is clean
	if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
		echo "Uncommitted changes exist. Commit or stash them first." >&2
		return 1
	fi

	# Push current branch
	echo "Pushing..."
	git push -u origin HEAD || return 1

	# Generate PR title and body via AI in a single call
	echo "Generating PR title and description..."
	local diff_content result title body
	diff_content=$(git diff "$default_branch"...HEAD)

	result=$(echo "$diff_content" | copilot -p \
		"Write a PR title and description for this diff. Summarize these changes with high information density, covering all major points without conversational filler. Format: first line is the title (semantic/conventional commits format, no quotes), then a blank line, then the markdown description body with a brief summary and list of key changes. Output ONLY this, nothing else." \
		--model gemini-3.5-flash --effort none -s)
	if [[ -z "$result" ]]; then
		echo "Failed to generate PR description." >&2
		return 1
	fi

	# Drop AI preface and keep output starting from the first valid title line.
	local cc_block
	cc_block="$(_from_first_cc_line "$result")"
	if [[ -n "$cc_block" ]]; then
		result="$cc_block"
	fi

	title="${result%%$'\n'*}"
	body="${result#*$'\n'$'\n'}"
	if [[ "$body" == "$result" ]]; then
		body="${result#*$'\n'}"
	fi

	if ! [[ "$title" =~ '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)[(:]' ]]; then
		title="$(git log --format=%s "$default_branch"...HEAD | head -n 1)"
		if ! [[ "$title" =~ '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)[(:]' ]]; then
			title="chore: summarize branch changes"
		fi
	fi

	echo "\nTitle:\n$title"
	echo "\nDescription:\n$body\n"

	# Create or update the draft PR
	local existing_pr
	existing_pr=$(gh pr view --json number --jq .number 2>/dev/null)
	if [[ -n "$existing_pr" ]]; then
		echo "Updating existing PR #$existing_pr..."
		gh pr edit "$existing_pr" --title "$title" --body "$body" || return 1
	else
		gh pr create --draft --base "$default_branch" --assignee @me \
			--title "$title" --body "$body" || return 1
	fi
}

# Delete local and origin branches whose PRs have been merged upstream.
# Uses `gh pr list --state merged` to find branches (handles squash merges).
# Usage: gh-branch-clean [--dry-run]
gh-branch-clean() {
	local dry_run=0
	[[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]] && dry_run=1

	# Determine fork remote and upstream repo
	local fork_remote="origin"
	local upstream_repo
	upstream_repo=$(git remote get-url upstream 2>/dev/null | sed -E 's|.*github\.com[:/]||;s|\.git$||')
	if [[ -z "$upstream_repo" ]]; then
		echo "No 'upstream' remote found. Run from a fork with an upstream remote." >&2
		return 1
	fi

	local default_branch
	default_branch=$(git symbolic-ref "refs/remotes/upstream/HEAD" 2>/dev/null | sed 's|refs/remotes/upstream/||')
	[[ -z "$default_branch" ]] && default_branch="master"

	# Get merged PR branches from upstream
	local -a merged_branches
	merged_branches=("${(@f)$(gh pr list --repo "$upstream_repo" --author @me --state merged --limit 200 --json headRefName --jq '.[].headRefName')}")

	if [[ ${#merged_branches[@]} -eq 0 || -z "${merged_branches[1]}" ]]; then
		echo "No merged PRs found."
		return 0
	fi

	# Fetch origin to see all remote branches
	git fetch "$fork_remote" --prune -q 2>/dev/null

	# Get local branches (excluding current and default)
	local current_branch
	current_branch=$(git branch --show-current)
	local -a local_branches
	local_branches=("${(@f)$(git branch --format='%(refname:short)')}")

	# Get remote-only branches on fork
	local -a remote_branches
	remote_branches=("${(@f)$(git branch -r --format='%(refname:short)' | grep "^${fork_remote}/" | sed "s|^${fork_remote}/||" | grep -v '^HEAD$')}")

	# Build unique set of branches to delete (local + remote-only)
	local -A to_delete_set
	local branch
	for branch in $local_branches; do
		[[ "$branch" == "$current_branch" || "$branch" == "$default_branch" ]] && continue
		if ((${merged_branches[(Ie)$branch]})); then
			to_delete_set[$branch]=1
		fi
	done
	for branch in $remote_branches; do
		[[ "$branch" == "$default_branch" ]] && continue
		if ((${merged_branches[(Ie)$branch]})); then
			to_delete_set[$branch]=1
		fi
	done

	if [[ ${#to_delete_set} -eq 0 ]]; then
		echo "No merged branches to clean."
		return 0
	fi

	local -a to_delete
	to_delete=("${(@ko)to_delete_set}")

	echo "Branches to delete (merged upstream):"
	printf '  %s\n' "${to_delete[@]}"
	echo

	if ((dry_run)); then
		echo "(dry run — no changes made)"
		return 0
	fi

	for branch in $to_delete; do
		echo "Deleting $branch..."
		git branch -D "$branch" 2>/dev/null
		git push "$fork_remote" --delete "$branch" 2>/dev/null
	done
	echo "Done. Deleted ${#to_delete[@]} branches."
}
