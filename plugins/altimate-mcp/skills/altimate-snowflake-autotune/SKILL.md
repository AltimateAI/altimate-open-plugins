---
name: altimate-snowflake-autotune
description: Work out the return on auto-tune for a Snowflake tenant (tools without the databricks_ prefix) - realized savings, per-warehouse savings, candidates and savings over time. Use when the user asks what auto-tune saved or which Snowflake warehouses would benefit.
---

# Snowflake auto-tune return with the Altimate MCP

Use the call rules in the `altimate-mcp` skill and the catalog in `altimate-snowflake`. Choose `team` as in the `altimate-mcp` skill and keep it on every call of one workflow.

Tools:

- Figures: `total_savings`, `autonomous_savings`, `assisted_savings`, `time_saved`, `opportunity_count` (the caller's team scope).
- `warehouse_auto_tune_savings`: each warehouse's savings (the caller's row scope).
- `autotune_savings_trend`: savings and decisions over time (the caller's team rules).

Enabling or disabling auto-tune is done in the Altimate app, not through a tool.

## Auto-tune return

1. `total_savings` (with `autonomous_savings` and `assisted_savings` when the split matters) over the window.
2. `warehouse_auto_tune_savings` for each warehouse's realized and annualized savings and whether auto-tune is on.
3. `warehouse_cost_by_warehouse`, same window. Realized savings as a share of each warehouse's cost ranks the return; warehouses with auto-tune off and high cost are candidates.
4. `autotune_savings_trend` for savings and agent decisions per period.

## Realized and potential savings

Keep realized and potential savings separate. Never present potential savings as money already saved. Call the remainder "potential savings", never "missed" savings, and give it only when the user asks what is still available, as one total rather than per month.
