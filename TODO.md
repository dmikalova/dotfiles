# To do

## Home

- quiet keyboard setup for office
- ghostty opening double with hammerspoon
- Prevent AWS privilege escalation
- project standards should add more info on what is changed - eg update gitignore, update go mod to version xyz - https://github.com/dmikalova/diatom/commit/f4de75664458f4be29826b601a9b9c637865c28b
- can chezmoi run directly off of github link?
- alternative to obsidian?
- bitwarden as ssh server
- clean up mklv configs
- clean up mage commands in vex
- delete repos (brocket, lists, recipes)
- github notifications app
- Discord server lists open PRs:

Performance & Build Metrics
WASM Binary Size Bloat: If a PR inflates a WebAssembly bundle size beyond a specific threshold (e.g., >5%), trigger an alert. This catches unintended dependency weight before it impacts frontend load times.

Benchmark Regressions: Pipe go test -bench diffs directly into Discord. If a PR significantly degrades CPU time or memory allocations in a core loop—like a Monte Carlo Tree Search simulation—flag it immediately for review.

Flaky Test Detection: Rather than alerting on every single failed run, report when a test fails on a branch but passes on an immediate retry, isolating flaky tests for the reliability backlog.

Infrastructure & Deployments
Infrastructure as Code (IaC) Plans: When a PR modifies infrastructure, post a truncated summary of the resulting plan (e.g., +3 added, ~1 changed, -2 destroyed) so the scope of the change is visible at a glance.

Rollback Events: If an automated rollback fires due to health check failures, report the exact metric that triggered the abort and the prior stable version that was restored.

Security & Dependencies
Critical Vulnerability Alerts: Filter out the noise of minor version bumps. Only push High/Critical Dependabot or Renovate alerts directly to chat. Also major version upgrades can be highlighted

Merge Conflict Blockers: Alert the author if an open PR suddenly develops merge conflicts with main due to another deployment, preventing surprise rebases right when they intend to merge.

Stale Review Digests: Instead of real-time pings for old PRs, use a cron job to send a single daily digest summarizing PRs that have been waiting for a review for more than 48 hours.

Page status: if page is down ping discord
