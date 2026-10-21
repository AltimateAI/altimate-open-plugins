---
name: altimate-databricks-lineage
description: Table lineage on a Databricks tenant (tools prefixed databricks_) - what feeds a table and what breaks if it changes. Use when the user asks about Databricks table dependencies or impact of a change.
---

# Databricks table lineage with the Altimate MCP

Tool: `databricks_table_lineage`, switched off unless released for the tenant; list the tools first. See `altimate-mcp` for inputs and errors and `altimate-databricks` for the catalog. Databricks has no table usage tool.

## Facts to keep straight

- Lineage takes one table as `catalog.schema.table`, a `direction` of `upstream` or `downstream`, and `depth` 1 to 3 (default 1).
- Names match case-insensitively and come back in lower case. Each edge appears once, at the first hop that reaches it.
- Lineage covers the last month.
- More than 5000 edges is cut: the first page comes back with `truncated` true and no `next_cursor`; lower the depth for a complete answer.
- A call with `team` (or from a caller in one team) sees only edges that team's rules cover: the workspace or account. `scope` names the team. Choose `team` as in the `altimate-mcp` skill.
- A table with no edges returns no records. An empty result can mean "no lineage" or "outside your scope"; say both are possible.

Answer with the requested table, its upstream or downstream dependencies, and the scope of the result. Give hop counts only when they help answer the question. Keep the scope caveat for an empty or team-scoped result.

## What feeds this table?

`databricks_table_lineage`, `direction: "upstream"`, `depth: 3`. Present sources by hop.

## What breaks if this table changes?

`databricks_table_lineage`, `direction: "downstream"`, `depth: 3`. Answer with the dependent tables, ordered by hop. Databricks has no table usage tool, so say that how busy each dependent table is cannot be shown.
