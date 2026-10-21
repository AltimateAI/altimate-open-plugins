---
name: altimate-mcp
description: Core rules for answering Snowflake or Databricks cost, usage, auto-tune savings, team attribution and access rules, Studio session and table lineage questions with the Altimate MCP - team choice, call shape, results, errors. Use whenever the user asks about Altimate tenant data, cloud data warehouse spend, warehouse or query cost, AI services cost, table usage or lineage; then load the platform skill it points to.
---

# Altimate MCP

The Altimate MCP answers questions about one Altimate tenant with the caller's own API key. Every tool reads the same dataset or summary an Altimate page shows, through the same engine and the same team scope, so a figure here is the figure the page shows.

## Before the first call

1. Find the server. Its tools appear under the server name the user configured, usually `altimate`. Use the discovered tool identifiers; do not guess prefixes.
2. If no Altimate tools are available, use the `altimate-mcp-setup` skill. A configured server is not proof that this session can call its tools. Do not silently substitute hand-written HTTP requests.
3. Read each tool's live description and input schema once. Use the live schema for tool identifiers, filters, sortable fields and accepted values. A tenant is served only the tools switched on for it: every Databricks tool ships switched off and is released per tenant, so list the tools before planning a call, and say plainly when the tool a question needs is not listed.
4. Identify the platform from the tool list. Tools prefixed `databricks_` mean a Databricks tenant; other data tools mean Snowflake. A list with only `my_teams` does not show the platform: Databricks tools ship switched off, and any tool can be switched off for a tenant. Say that no data tools are released for this tenant and ask which platform the user is on; do not guess. Then load `altimate-snowflake` or `altimate-databricks` for the catalog and data limits.

Answer Altimate tenant questions from the Altimate MCP tools only. Do not query Altimate databases, ClickHouse, PostgreSQL, Snowflake or Databricks directly, and do not use another skill, connection or command line to get the figure, even when one is available. If no tool answers the question, say so; a number from another source cannot be checked against the product.

Tenant and timezone are connection headers; keep them as configured. The team is a per-call `team` argument, chosen as described below. Never drop a `team` the user asked for, or switch to another connection, to get past a refusal.

For a single total or comparison, call only the tool needed to answer it. Use the platform skills (see "Which skill next") for a requested explanation or drill-down, not to expand a simple question into unrelated breakdowns.

## Choose the team

Every tool except `my_teams` takes an optional `team` argument: the exact team name. Never show or ask for team ids.

1. Call `my_teams` once per conversation, before the first other call; a caller already known to be a tenant owner may skip it until a question names a team. It is the same tool on Snowflake and Databricks, takes no arguments and returns `is_owner`, `team_scoped_tenant` and `teams` (each with `name` and `description`). If `team_scoped_tenant` is false, never pass `team`: the server refuses it; answer tenant-wide or explain that the tenant does not scope by team. `my_teams` describes the key the client actually sent: if its `is_owner` or team list differs from what the user expects (for example they say they are an owner), tell them the client is probably running with another or an old key and point them to `altimate-mcp-setup`; do not answer as if the reported role were certainly theirs.
2. The question names a team (for example "data-products"): pass `team` with that exact name from `my_teams`. Names match case-sensitively. If none matches exactly, show the closest names and ask which one was meant.
3. The caller is in one team: pass no `team`; the server uses that team.
4. The caller is in several teams and the question names none (for example "get me 10 warehouses"): ask which team, offering the names and "each of my teams". For "each", call once per team and present the results per team, labelled from each response's `scope`. Never add team figures into one total: attribution can overlap.
5. A call returns `team_required`: do the same as step 4, using the names in `details.teams`.
6. Owners: no `team` gives the tenant-wide view. When the user asks what a team spent, an owner reads it through attribution, without the `team` argument: `team_cost_by_team`, or the owner-only `team` filter on the tools that offer it (the platform skill lists them). Pass `team` only for the team's own view, what its members see: that view is recomputed from the team's rules and is refused, or empty, for a rule type it cannot apply. Owner-only tools and the owner-only `team` filter need an owner calling without `team`. When the user asked for the team's view, report a refusal; do not drop `team` to get past it.

## Pick the tool

A tenant sees only its own platform's tools; the platform skill lists them. Each tool answers one question at one grain: there is no `metrics` or `group_by` argument, and a different breakdown is a different tool (for example `query_cost_by_user` for query cost per user). Read each tool's measures, filters and sortable fields from its live schema.

| Question | Tool | Who may call |
| --- | --- | --- |
| My role and teams | `my_teams` (Snowflake and Databricks) | Anyone |

Not available: query text or ids, who reads a table, other users' Studio sessions, login history, opportunities, forecasts, and a free grouping the tools do not offer. No tool changes anything today (for example enabling or disabling auto-tune): point the user to the Altimate app. Say so plainly; do not approximate with another tool or reach the data another way.

## Call a metric tool

- `start_date` and `end_date` are required, inclusive UTC days, at most 366 days. Turn "last month", "this quarter" or "this year" into explicit calendar dates and say which dates you used. When the question names no window, choose one that fits the question and say so in the answer.
- A figure tool takes only the window and `team`; anything else is `invalid_input`.
- On an aggregate tool with a period, `granularity` (`day`, `week`, `month`) sets the bucket. A tool without a period returns one row per name over the whole window.
- `filters` is `{filter: [values]}`, only the filters the tool's schema lists; a row matches any listed value, up to 50 values. Values are exact business names, as a row of that tool returns them. A required filter is listed as required with its choices.
- `order_by` and `descending` sort by one of the tool's sortable fields. `limit` is 1 to the tool's maximum, default 100.
- "Mean", "average per day" or "the last N days": call a trend tool at `granularity` `day` over N complete days, ending yesterday, or on the day of `provenance.data_through` when that is earlier. Never include today: it is partial. The mean is the sum of the daily rows divided by N; say the dates. A tool without a period returns the window total, which answers "how much"; divide it by N only when the user asked for a per-day figure, and say so.
- `team` is the exact team name, chosen as in "Choose the team". Never pass `sql`, `where`, `metrics`, `group_by`, ids or a tenant. They are refused as `invalid_input`.

## Call a record tool

Record tools take `filters`, `cursor` and `limit`. `data.total` counts every matching record across pages, so `limit` 1 answers "how many". When the result has `data.next_cursor`, pass it back as `cursor` with the same filters and limit to get the next page. Lineage inputs (`table`, `direction`, `depth`) are in `altimate-snowflake-tables` and `altimate-databricks-lineage`.

## Read the result

- Check `isError` first. A failure is `code: message`; see below.
- Show business names only, as the product shows them. Never show internal Altimate ids (instance ids, resource keys, uuids, record ids, Studio session handles) or internal codes. Leave out any returned value that looks like an id or code the product would not show.
- An aggregate's `data.rows` holds the answer, keyed by business names, and `data.columns` gives each column's description and unit (`currency`, `credits`, `count`, `tokens`, `dbus`). A figure's answer is `data.metric` (`name`, `value`, `unit`, `description`).
- `scope` names the tenant and the team the call ran under. Mention it when it is narrower than the user may assume, and use it to label results when you called once per team.
- `provenance` gives the source, the cost basis and `caveats`. Carry caveats that affect the answer into your reply.
- `data.no_data` true means there is no data for the question: say so, never report $0. `null` means unknown, not zero. A filter value that matches nothing returns no rows: check the exact name in an unfiltered result before saying a named resource had no spend.
- When `data.limit_reached` is true, the rows are the first ones in the requested order, not the whole breakdown. Do not sum them as a total; take the total from the matching figure tool (for example `total_cost`) or a trend tool.
- Ranked results can put `null` before real values, and `too_large` can be raised before `limit` is applied. Check the returned rows before calling them a top N; narrow the window or filters when necessary.
- Keep realized and potential savings separate. Never present potential savings as money already saved. Call the remainder "potential savings", never "missed" savings, and give it only when the user asks what is still available, as one total rather than per month.

## Errors

| Code | Meaning | What to do |
| --- | --- | --- |
| `unauthenticated` | Missing or invalid API key or tenant | Fix the connection; see `altimate-mcp-setup` |
| `forbidden` | The caller's role may not make this call, the `team` is not one of the caller's teams, the tenant does not scope by team, or the caller is in no team | Explain the requirement (for example owner-only, or the caller's team names from `my_teams`); do not retry unchanged |
| `forbidden` saying the team has "an access rule of a type this read cannot apply" | The call passed `team` (or the caller is a member of that team) and the team's view of this tool cannot apply one of the team's rule types | For a team's cost, an owner switches to attribution without `team` (`team_cost_by_team`, the owner-only `team` filter); a member needs their Altimate administrator to review the team's rules. Do not retry the same read |
| `team_required` | The caller is in several teams and passed no `team` | Ask which team, offering `details.teams` and "each of my teams" |
| `invalid_input` | An argument or value the tool does not accept | Correct it against the live schema |
| `unavailable` | No such record for this caller, or the page behind the tool is not enabled for the tenant | Report it; never substitute zero |
| `not_found` | No such tool for this tenant (switched off, the other platform's, or unknown): the text is `not_found: No such tool is available to you. List the tools to see the ones you can call.` and names no tool. Also no such table for lineage | List the tools and use a listed one, or say the question cannot be answered here |
| `too_large` | The result is over the size budget | Narrow the window, filters or lineage depth |
| `timeout` | The read ran past the server deadline | Retry once; a first call on a cold server can be slow |
| `busy`, `rate_limited` | The server is busy or throttling | Retry at most twice with backoff |
| `upstream_error` | The read failed | Retry once only if a transient failure is plausible; otherwise report the failure and scope |
| `contract_mismatch` | The server returned an unexpected shape | Report it; do not guess a value |

## Which skill next

| Skill | Load when |
| --- | --- |
| `altimate-mcp-setup` | No Altimate tools, every call fails, or the user asks how to connect |
| `altimate-snowflake` | Snowflake tenant: tool catalog, who may call, data limits; before picking a Snowflake tool |
| `altimate-snowflake-cost` | Snowflake spend needs an explanation: why it changed, where it goes, unit cost, AI cost drivers |
| `altimate-snowflake-autotune` | Snowflake auto-tune return or savings per warehouse |
| `altimate-snowflake-teams` | Snowflake team questions: what a team spent (total, per day, average), which team pays, unattributed spend, access gaps |
| `altimate-snowflake-tables` | Snowflake table usage, lineage, impact of a change, pipeline cost |
| `altimate-databricks` | Databricks tenant: tool catalog, who may call, gaps; before picking a Databricks tool |
| `altimate-databricks-cost` | Databricks spend needs an explanation, unit cost, AI/ML spend |
| `altimate-databricks-autotune` | Databricks auto-tune return or decisions |
| `altimate-databricks-lineage` | Databricks table lineage and impact of a change |

## Answer the question

Lead with the requested value or finding, its tenant and team scope (from `scope`) and date window. Add the unit and one caveat only when it changes the interpretation. For realized and potential savings, give the two figures separately. Do not add a table by default; use one only when the user asks for a breakdown or a series, such as daily cost. Stop once the question is answered; offer a deeper breakdown only if it would help the user's next decision. Never paste the tool catalog, raw response or unrelated limitations into the answer.
