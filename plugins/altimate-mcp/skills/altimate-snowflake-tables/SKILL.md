---
name: altimate-snowflake-tables
description: Table usage and lineage on a Snowflake tenant (tools without the databricks_ prefix) - busiest tables, usage of a table, schema or database, what feeds a table, what breaks if it changes, rough pipeline cost. Use when the user asks about Snowflake tables, dependencies or impact of a change.
---

# Snowflake table usage and lineage with the Altimate MCP

Tools: `tables_by_cost` and the table figures (`table_annualized_cost` and its siblings), `table_lineage`. See `altimate-mcp` for inputs and errors and `altimate-snowflake` for the catalog.

## Facts to keep straight

- Lineage takes one table as `database.schema.table`, a `direction` of `upstream` or `downstream`, and `depth` 1 to 3 (default 1).
- Names match case-insensitively and come back in lower case. Each edge appears once, at the first hop that reaches it.
- An edge to or from a stage has that end `null` and is not followed.
- More than 5000 edges is cut: the first page comes back with `truncated` true and no `next_cursor`; lower the depth for a complete answer.
- A call with `team` (or from a caller in one team) sees only edges that team's rules cover: the database or schema of either table. A team whose rules name only accounts, warehouses, users, roles or tags sees no lineage. `scope` names the team. Choose `team` as in the `altimate-mcp` skill.
- A table that is missing, deleted or outside the caller's scope is `not_found`; a table that exists but has no edges returns no records. An empty result can mean "no lineage" or "outside your scope"; say both are possible.
- `tables_by_cost` lists tables as the Tables page does: each row carries `database`, `schema_name`, `table`, `owner`, `account` and the measures (annualized cost, reads, writes). `database.schema_name.table` is the name to pass to `table_lineage`. Its filters are named `database`, `schema` and `table`. Its figures are annualized estimates: the date window does not change them. A table missing from it is not proof that the table is unused.
- There is no "who reads this table".

Answer with the requested table, its upstream or downstream dependencies, and the scope of the result. Give hop counts or usage only when they help answer the question. Keep the scope caveat for an empty or team-scoped result; do not include unrelated cost or catalog detail.

## Busiest tables

`tables_by_cost`, `order_by: "reads"`, `limit: 20`. Use `order_by: "writes"` for the most written tables, or `"total_cost"` for the most expensive.

## Usage of one table, schema or database

- One table: `tables_by_cost` filtered by `database`, `schema` and `table`.
- Every table in a schema: filter `database` and `schema`.
- Every table in a database: filter `database`.
- The totals for the tables the caller can see: `table_annualized_cost`, `table_storage_cost`, `table_insertion_cost`, `table_clustering_cost`.

## What feeds this table?

`table_lineage`, `direction: "upstream"`, `depth: 3`. Present sources by hop. Note stage ends.

## What breaks if this table changes?

1. `table_lineage`, `direction: "downstream"`, `depth: 3`.
2. `tables_by_cost` filtered to the downstream tables' databases and schemas, to show how busy each consumer is (`reads`, `writes`).
3. Match each dependent table to its `tables_by_cost` row on `database`, `schema_name` and `table`. Answer with the dependent tables, ordered by hop and then by reads, and say which ones `tables_by_cost` did not list.

## What feeds our busiest tables?

1. Busiest tables as above (top 5 to 10).
2. `table_lineage` upstream at depth 1 or 2 for each, passing `database.schema_name.table` from its row.
3. Tables that feed several busy tables are the critical sources.

## Roughly what does a pipeline cost?

1. `table_lineage` upstream from the output table.
2. `tables_by_cost` filtered to the upstream tables' databases and schemas: each table's annualized cost (storage, insertion, clustering).
3. Optionally `query_cost_by_schema` filtered to those databases and schemas, same window, for the query cost run in them.
4. Say clearly that step 2 is annualized and step 3 is schema-level query cost, not the cost of these tables alone; do not add the two.
