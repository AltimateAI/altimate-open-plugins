---
name: altimate-snowflake
description: Tool catalog, access rules and data limits for Snowflake tenants of the Altimate MCP (tools without the databricks_ prefix). Load before picking a Snowflake tool, when the user asks about Snowflake spend, auto-tune savings, warehouses, teams or tables.
---

# Altimate MCP on Snowflake

Applies to tenants whose tools have no `databricks_` prefix. Call shape, team choice, results and errors are in the `altimate-mcp` skill. Each tool answers one question at one grain; read measures, filters and sortable fields from its live schema.

**Snowflake figures** (one number for a window; inputs `start_date`, `end_date`, optional `team`)

| Question | Tool | Who may call |
| --- | --- | --- |
| Total spend; compute, serverless, cloud services | `total_cost`, `compute_cost`, `serverless_cost`, `cloud_services_cost` | Anyone: the owner without `team` gets the account bill, anyone else their team's own cost |
| Storage and AI services spend | `storage_cost`, `ai_services_cost` | Owner, no `team` argument |
| Auto-tune savings | `total_savings`, `autonomous_savings`, `assisted_savings`, `time_saved`, `opportunity_count` | The caller's team scope |
| Annualized table cost | `table_annualized_cost`, `table_insertion_cost`, `table_storage_cost`, `table_clustering_cost` | The caller's team scope; not bound to the window |

**Snowflake aggregates** (rows over a window; one row per period or per name)

| Question | Tool | Who may call |
| --- | --- | --- |
| Spend per day, week or month | `overall_cost_trend` (compute, serverless, cloud services) | Anyone: the owner without `team` gets the bill, anyone else their team's cost |
| What drives one cost category | `overall_cost_by_usage_type`, `filters.category` required (`compute`, `storage`, `serverless`, `cloud_services`, `ai_services`, `other`) | Owner, no `team` argument |
| Spend per Snowflake account | `overall_cost_by_account` | Owner, no `team` argument |
| Warehouse spend over time | `warehouse_cost_trend` | The caller's team rules; owner-only `team` filter for one team's attributed cost |
| Warehouse spend and credits per warehouse | `warehouse_cost_by_warehouse` | The caller's team rules; owner-only `team` filter for one team's attributed cost |
| Each team's spend (Team Spends page) | `team_cost_by_team` | Owner without `team`: every team; with `team`: only that team's row; a member without `team`: their teams |
| Query cost and count over time | `query_cost_trend` | The caller's team rules; owner-only `team` filter for one team's attributed cost |
| Query cost per warehouse, user, role, database, schema or query type | `query_cost_by_warehouse`, `query_cost_by_user`, `query_cost_by_role`, `query_cost_by_database`, `query_cost_by_schema`, `query_cost_by_type` | The caller's team rules; owner-only `team` filter for one team's attributed cost |
| Most expensive tables, with reads and writes | `tables_by_cost` | The caller's team rules |
| Auto-tune savings and decisions over time | `autotune_savings_trend` | The caller's team rules |
| AI services spend per service over time | `ai_services_cost_trend` (switched off unless released for the tenant) | Owner, no `team` argument |

A required filter, such as `category` on `overall_cost_by_usage_type`, is listed as required with its choices.

**Record tools** (lists of things, not numbers; `my_teams` is in `altimate-mcp`)

| Question | Tool | Who may call |
| --- | --- | --- |
| Current warehouses: how many, size, auto-suspend, which have auto-tune on | `warehouses_list` | The caller's row scope |
| Each warehouse's auto-tune savings | `warehouse_auto_tune_savings` | The caller's row scope |
| A team's cost attribution rules | `team_attribution_rules` | Owner, no `team` argument |
| A team's row-level access rules | `team_access_rules` | Owner, no `team` argument |
| My Studio sessions | `studio_sessions` | The caller's own |
| One of my sessions, with messages | `studio_session` | The caller's own |
| What feeds or depends on a table | `table_lineage` | The caller's row scope |

Lineage takes `table` as `database.schema.table`; see `altimate-snowflake-tables`.

For "how many warehouses do I have", call `warehouses_list` with `limit` 1 and read `data.total`; for "which have auto-tune enabled", filter `auto_tune_enabled` `true`. Do not count warehouses from a cost tool: it lists only warehouses with spend in the window.

## Two ways to read a team

- Attribution: the figure the Team Spends page shows. `team_cost_by_team` (with `team` for one team's row), and the owner-only `team` filter on `warehouse_cost_trend`, `warehouse_cost_by_warehouse`, `query_cost_trend` and the `query_cost_by_*` tools, all called without the `team` argument. This is the answer to "what did team X spend", per window, per day, per warehouse or per user.
- The team's view: the `team` argument on `total_cost`, `compute_cost`, `serverless_cost`, `cloud_services_cost` and `overall_cost_trend`. It is what a member of that team sees: cost recomputed from the warehouses, users and roles the team's access rules name. Where cost is attributed by warehouse, user and role rules match no cost, so a team defined only by them has no data; a team with a query tag rule is refused with "an access rule of a type this read cannot apply".

An owner answers a team question through attribution first and uses the view only when the user wants what the team sees. The two bases need not agree; say which one answered.

## Data limits to check before calling

These are client guidance, not access controls.

- The account bill (`overall_cost_trend`, `overall_cost_by_usage_type`, `overall_cost_by_account`) arrives about a day late, so yesterday is usually empty. Empty is not zero spend. For "cost yesterday", use `warehouse_cost_by_warehouse` or `warehouse_cost_trend` and say which tool answered.
- A team's `total_cost` with `team` (the team's view, from its rules) and its `team_cost_by_team` row or `team`-filtered warehouse rows (attribution) read different page specs and need not agree. Say which one answered; never mix them in one comparison.

## Examples

Example, "How has spend moved month by month this year?":

```json
{"tool": "overall_cost_trend", "arguments": {"start_date": "2026-01-01", "end_date": "2026-10-12", "granularity": "month"}}
```

Example, "Top 10 warehouses by cost last week, with credits":

```json
{"tool": "warehouse_cost_by_warehouse", "arguments": {"start_date": "2026-10-05", "end_date": "2026-10-11", "order_by": "total_cost", "limit": 10}}
```
