# To do

- [Onboarding checklist](https://app.notion.com/p/goodship-io/Onboarding-checklist-David-Mikalova-3e224418dc93801d9bded147623f628e)

- time off
- What does it mean that duck db is columnar compared to postgres
- Why does `AWS_PROFILE=sb   yarn nx run infra-<project>:diff-sb` have to declare sb twice?
-

## Home
- can chezmoi run directly off of github link?
- alternative to obsidian?
- bitwarden as ssh server
- clean up mklv configs
- clean up mage commands in vex
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

Teams:
- Alex Saucet leads the Procurement team
- Chris Watson leads the Orchestration team
- Hailey and David Golke work on Laney, the GoodShip's AI offering. Iku works on Laney and DIP (our team)
- DIP is Data/Infra/Pipelines. that would be you, me, Teban. though we will be all up in everyone's business all the time :joy:
- Rob, Ben and Riley work on Analytics Engineering, which is ETL implementation and maintenance



dip:from firefighters to force multipliers

local devx - running mmultiple copies locally (teban)
cicd
SLAs/metrics
AAR - after action reports (from outages)
status page
segregate data to separate aws accounts
ephemeral environments
data and ai
test db instead of local data
temporal and nx
nextjs zones
fan out and parallelize tests in cicd
- codeowners for infra work - automatically ping in slack

pure infra:
- stand up stg env
- currently sandbox (tag PR) and production
- stg on PoCs and sales accounts
- presales env - same product, different data
- incident management
-

- psql 15
- learn more about motherduck
- supervisord
- ecs scaling
- get off of sst.dev
- https://linear.app/goodship/issue/DIP-2647/in-app-outage-banner-maintenance-mode-ability-to-shut-off-traffic-to
  - goodship config > maintenance mode
  - shut it down mode > deploy level script
