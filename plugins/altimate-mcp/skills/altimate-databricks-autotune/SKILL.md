---
name: altimate-databricks-autotune
description: Work out the return on auto-tune for a Databricks tenant (tools prefixed databricks_) - savings against cost over time and decisions per resource. Use when the user asks what auto-tune saved or what it decided on Databricks.
---

# Databricks auto-tune return with the Altimate MCP

Use the call rules in the `altimate-mcp` skill and the catalog in `altimate-databricks`. Every Databricks tool ships switched off: list the tools first. Choose `team` as in the `altimate-mcp` skill and keep it on every call of one workflow.

Tools:

- Savings: `databricks_total_savings`, `databricks_autonomous_savings`, `databricks_assisted_savings`, `databricks_time_saved`, `databricks_autotune_savings_trend`, `databricks_autotune_savings_split`.
- Decisions: `databricks_autotune_events_trend`, `databricks_autotune_events_by_entity`.

Enabling or disabling auto-tune is done in the Altimate app, not through a tool.

## Auto-tune return

`databricks_autotune_savings_trend` by month against `databricks_cost_trend` by month; `databricks_autotune_events_by_entity` for the decisions per resource.

## Realized and potential savings

Keep realized and potential savings separate. Never present potential savings as money already saved. Call the remainder "potential savings", never "missed" savings, and give it only when the user asks what is still available, as one total rather than per month.
