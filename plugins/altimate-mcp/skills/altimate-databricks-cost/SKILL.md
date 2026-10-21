---
name: altimate-databricks-cost
description: Investigate Databricks spend with several Altimate MCP calls - why spend changed, where it goes, serving unit cost and AI/ML spend. Use on a Databricks tenant (tools prefixed databricks_) when a cost question needs a drill-down or a comparison rather than one number.
---

# Databricks cost analysis with the Altimate MCP

Use the tools and gaps in the `altimate-databricks` skill and the call rules in the `altimate-mcp` skill. These workflows are for questions that require an explanation or comparison. For a single number, use the one relevant tool and answer directly. Join results on business names (workspace, product, SKU), with the same window and scope. Choose the `team` argument as in the `altimate-mcp` skill ("Choose the team") before the first call, and keep the same team scope on every call of one workflow.

Each tool answers one grain, so a drill-down is a sequence of tools, not one tool with a different `group_by`. List the tools first: a step whose tool is not served to the tenant (every Databricks tool ships switched off) cannot run; say which step is missing.

Rules for every workflow:

- Start broad and narrow down. Each step uses a value the previous step returned, exactly as returned, as a filter on the next tool.
- Compare like with like: same window, same platform, same scope. Check each response's `scope` names the tenant and team you meant.
- A result with `limit_reached` true is incomplete. Get the total from a figure tool or a trend tool without a breakdown.
- If the caller gets `forbidden`, say which step needs an owner and stop that branch.
- `data.no_data` true is "no data", never zero spend.

## Why did spend change?

`databricks_cost_trend` by day, then `databricks_cost_by_product` and `databricks_cost_by_workspace` over the days that moved, then `databricks_query_cost_by_user` or the AI/ML tools for the product that moved.

Report the change in money and percent, the top contributors, and what stayed flat.

## Where does the money go?

`databricks_cost_by_category` and `databricks_cost_by_product`, then `databricks_cost_by_workspace` and `databricks_cost_by_sku`.

## Unit cost

Serving cost per thousand tokens: `databricks_model_serving_cost` for the window, divided by the tokens `databricks_serving_usage_trend` returns over the same window and scope. Serving usage keeps only the most recent month of requests, so keep the window inside it.

## AI/ML spend

- Total and trend: `databricks_ai_ml_total_cost`, `databricks_ai_ml_cost_trend`.
- Endpoints: `databricks_ai_ml_endpoints`.
- By kind: `databricks_model_serving_cost`, `databricks_vector_search_cost`, `databricks_ai_gateway_cost`.
- Traffic: `databricks_serving_usage_trend`, `databricks_serving_usage_by_model`, `databricks_serving_usage_by_status`, `databricks_serving_usage_by_workspace`.

## Writing the answer

Lead with the requested answer, currency, scope and window. Use a small table only when comparing several values. Include only caveats that change that answer, such as incomplete top-N rows or different cost bases. Do not list every tool call or broaden a single-number question into a spend audit. Keep realized savings and potential savings separate.
