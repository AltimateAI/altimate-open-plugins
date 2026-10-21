---
name: altimate-databricks
description: Tool catalog, access rules and gaps for Databricks tenants of the Altimate MCP (tools prefixed databricks_). Load before picking a Databricks tool, when the user asks about Databricks spend, DBUs, SQL statements, AI/ML, auto-tune, warehouses or lineage.
---

# Altimate MCP on Databricks

Applies to tenants whose tools are prefixed `databricks_`. Call shape, team choice, results and errors are in the `altimate-mcp` skill. Every Databricks tool ships switched off and is released per tenant: list the tools first, and say plainly when the tool a question needs is not listed. Each tool answers one question at one grain; read measures, filters and sortable fields from its live schema.

| Question | Tools |
| --- | --- |
| Total cost, DBUs, active workspaces | `databricks_total_cost`, `databricks_total_dbus`, `databricks_active_workspaces` |
| Cost over time, and by category, product, SKU or workspace | `databricks_cost_trend`, `databricks_cost_by_category`, `databricks_cost_by_product`, `databricks_cost_by_sku`, `databricks_cost_by_workspace` |
| SQL statement cost, count and bytes | `databricks_query_total_cost`, `databricks_query_count`, `databricks_query_read_bytes`, `databricks_query_spilled_bytes`, `databricks_query_cost_by_user` |
| AI/ML spend | `databricks_ai_ml_total_cost`, `databricks_model_serving_cost`, `databricks_vector_search_cost`, `databricks_ai_gateway_cost`, `databricks_ai_ml_cost_trend`, `databricks_ai_ml_endpoints` |
| Model serving traffic | `databricks_serving_usage_trend`, `databricks_serving_usage_by_model`, `databricks_serving_usage_by_status`, `databricks_serving_usage_by_workspace` |
| Auto-tune savings | `databricks_total_savings`, `databricks_autonomous_savings`, `databricks_assisted_savings`, `databricks_time_saved`, `databricks_autotune_savings_trend`, `databricks_autotune_savings_split` |
| Auto-tune decisions | `databricks_autotune_events_trend`, `databricks_autotune_events_by_entity` |

**Record tools** (lists of things, not numbers; `my_teams` is in `altimate-mcp`)

| Question | Tool | Who may call |
| --- | --- | --- |
| Current SQL warehouses | `databricks_sql_warehouses_list` | The caller's row scope |
| A team's cost attribution rules | `databricks_team_attribution_rules` | Owner, no `team` argument |
| A team's row-level access rules | `databricks_team_access_rules` | Owner, no `team` argument |
| My Studio sessions | `databricks_studio_sessions` | The caller's own |
| One of my sessions, with messages | `databricks_studio_session` | The caller's own |
| What feeds or depends on a table | `databricks_table_lineage` | The caller's row scope |

For "how many SQL warehouses do I have", call `databricks_sql_warehouses_list` with `limit` 1 and read `data.total`.

## Gaps

Say so plainly; do not approximate with another tool or reach the data another way.

- No Databricks table usage.
- No Databricks cost by custom tag.
- Databricks has no per-team cost tool yet; say so.
- Serving usage keeps only the most recent month of requests.
- Lineage covers the last month.

Use `altimate-databricks-cost`, `altimate-databricks-autotune` and `altimate-databricks-lineage` for those workflows.
