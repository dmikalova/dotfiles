# To do

- [Onboarding checklist](https://app.notion.com/p/goodship-io/Onboarding-checklist-David-Mikalova-3e224418dc93801d9bded147623f628e)

- Ask Notion "As a new infra hire working on the platform, what documents should I review to get started with the system"

## Home
- can chezmoi run directly off of github link?
- alternative to obsidian?

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
