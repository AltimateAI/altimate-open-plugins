---
name: altimate-snowflake-teams
description: Team cost on a Snowflake tenant (tools without the databricks_ prefix) - what a team spent in total, per day or on average, which team pays, unattributed spend, and whether each team can see what it pays for. Use when a question names a team or asks about team cost, attribution rules or access rules on Snowflake.
---

# Snowflake team attribution with the Altimate MCP

Use the call rules in the `altimate-mcp` skill and the catalog in `altimate-snowflake`. Choose `team` as in the `altimate-mcp` skill ("Choose the team") and keep the same scope on every call of one workflow; owner-only steps run without `team`.

## Two bases

A team's cost can be read two ways, and they need not agree (see "Two ways to read a team" in `altimate-snowflake`):

- Attribution, the Team Spends figure: `team_cost_by_team`, and the owner-only `team` filter on `warehouse_cost_trend`, `warehouse_cost_by_warehouse`, `query_cost_trend` and the `query_cost_by_*` tools, called without the `team` argument.
- The team's view: the `team` argument on `total_cost` and `overall_cost_trend`, recomputed from the team's rules. It is refused for a rule type it cannot apply.

Answer "what did team X spend" through attribution. Use the view only when the user wants what the team's members see. Say which basis answered; never mix the two in one comparison.

## What did one team spend, per day or on average? (owner)

1. `warehouse_cost_trend`, `granularity: "day"`, `filters: {"team": ["<name>"]}`, no `team` argument, over complete days (end yesterday, or on `provenance.data_through` when earlier). The mean is the sum of the rows divided by the number of days; give the dates.
2. `team_cost_by_team` with `team` over the same window for the total; the daily rows sum to it.
3. Per warehouse or per user inside that team: `warehouse_cost_by_warehouse` or `query_cost_by_user` with the same `team` filter.

A member reads their own team's total with `team_cost_by_team` without `team`; the `team` filter is owner-only. `overall_cost_trend` with `team` gives the team's view per day, a different basis, and can be refused for the team's rule types.

Example, "mean daily spend of data-products over the last seven days", asked on 2026-10-21:

```json
{"tool": "warehouse_cost_trend", "arguments": {"start_date": "2026-10-14", "end_date": "2026-10-20", "granularity": "day", "filters": {"team": ["data-products"]}}}
```

## Which team pays?

`team_cost_by_team` gives each team's spend as the Team Spends page shows it, attributed per warehouse or per query as the tenant is configured. The owner calling without `team` sees every team; a member calling without `team` sees their own teams; a call with `team` returns only that team's row, for an owner and a member alike. Never add those per-team figures into one total, because attribution can overlap.

1. `team_cost_by_team` over the window. Compare with `total_cost` for the same window (owner without `team`) to show how much of the bill teams cover.
2. To explain a team's figure (owner): `team_attribution_rules` filtered to that team lists the warehouses, users, tags and other resources it is charged for. Rules marked `excluded_from_attribution` are not used.

## Unattributed spend (owner)

1. `warehouse_cost_by_warehouse`, `limit: 1000`.
2. `team_attribution_rules` with no filter; page through `next_cursor`. Collect every warehouse named in an active rule that is not excluded.
3. Warehouses in step 1 that no rule names are unattributed. Sum their cost and list the largest.

## Can each team see what it pays for? (owner)

Compare `team_access_rules` with `team_attribution_rules`, team by team. A resource a team is charged for but has no access rule for is a gap worth reporting.
