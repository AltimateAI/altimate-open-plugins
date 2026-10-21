---
name: altimate-snowflake-cost
description: Investigate Snowflake spend with several Altimate MCP calls - why spend changed, where it goes, unit cost and AI cost drivers. Use on a Snowflake tenant (tools without the databricks_ prefix) when a cost question needs a drill-down or a comparison rather than one number.
---

# Snowflake cost analysis with the Altimate MCP

Use the tools and data limits in the `altimate-snowflake` skill and the call rules in the `altimate-mcp` skill. These workflows are for questions that require an explanation or comparison. For a single number, use the one relevant tool and answer directly. Join results on business names (warehouse, account, usage type), with the same window and scope. Choose the `team` argument as in the `altimate-mcp` skill ("Choose the team") before the first call, and keep the same team scope on every call of one workflow; owner-only steps run without `team`.

Each tool answers one grain, so a drill-down is a sequence of tools, not one tool with a different `group_by`. List the tools first: a step whose tool is not served to the tenant (`ai_services_cost_trend` ships switched off) cannot run; say which step is missing.

Rules for every workflow:

- Start broad and narrow down. Each step uses a value the previous step returned, exactly as returned, as a filter on the next tool.
- Compare like with like: same window, same platform, same scope. Check each response's `scope` names the tenant and team you meant.
- A result with `limit_reached` true is incomplete. Get the total from a figure tool or a trend tool without a breakdown.
- Owner-only steps are marked. If the caller gets `forbidden`, say which step needs an owner and stop that branch.
- `data.no_data` true is "no data", never zero spend.

## Why did spend change?

1. `overall_cost_trend`, `granularity: "day"` (or `"week"`), over a window that covers before and after. Find the category (compute, serverless, cloud services) and day that moved.
2. Owner, when storage, AI services or another category moved: `overall_cost_by_usage_type` with `filters.category` set to that category, same window. Find the usage type that moved.
3. If compute moved: `warehouse_cost_by_warehouse` over the day or week that moved, and the same window before it. Find the warehouses that moved.
4. `query_cost_by_user` filtered to those warehouses, then `query_cost_by_type` or `query_cost_by_role`. Name what drove it.
5. Owner, if AI moved: `ai_services_cost_trend` by period, then `query_cost_by_user` for the `ai_cost` measure.

Report the change in money and percent, the top contributors, and what stayed flat.

## Where does the money go?

`overall_cost_by_usage_type` per category (owner); `warehouse_cost_by_warehouse` (top 10); `query_cost_by_database` or `query_cost_by_user`; `tables_by_cost` for the most expensive tables.

## Unit cost

Cost per query: `query_cost_trend` with `granularity: "week"`; divide `total_cost` by `query_count` per period.

## AI cost drivers (owner)

1. `ai_services_cost_trend` by period: Cortex and other AI services per service.
2. `query_cost_by_user`, reading its `ai_cost` measure: AI functions inside SQL, per user. The tool sorts by cost or query count, not by `ai_cost`, so read every row (or raise `limit`) before naming the top users.
3. `ai_services_cost` for the window's billed AI total. These cover a wider scope than step 2, so explain the difference rather than reconciling to the cent.

## Writing the answer

Lead with the requested answer, currency, scope and window. Use a small table only when comparing several values. Include only caveats that change that answer, such as incomplete top-N rows or different cost bases. Do not list every tool call or broaden a single-number question into a spend audit. Keep realized savings and potential savings separate.
