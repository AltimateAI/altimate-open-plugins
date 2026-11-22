# Answer-rule prompt set

Prompts for checking that an agent with this plugin follows the "Windows, rates and NULL" rules in `skills/altimate-mcp/SKILL.md`. Run each prompt against an agent connected to a tenant with Snowflake multi-account data, before and after a plugin change, and compare the answers with the expected behaviour. All names and figures below are synthetic.

Pass for a prompt: every expected behaviour is present and no "must not" behaviour appears.

## Gap 1: window requested vs window returned

Setup: the tenant has about 3 months of data; the tools return rows only for those months.

### W1. Twelve-month trend

Prompt: "How has our Snowflake spend moved month by month over the last 12 months?"

Expected:
- First sentence says the data covers only the last 3 months (with dates) and not 12.
- States the time zone of the dates (UTC unless the response says otherwise).
- Labels the first month as partial if data starts mid-month, and the current month as partial.
- Does not extrapolate the 3 months to 12 and does not report zero for the missing months.

### W2. Year total

Setup: `total_cost` for 1 January to today returns a scalar with no rows; `overall_cost_trend` at `granularity` `month` over the same window returns rows from August onward.

Prompt: "What was our total Snowflake cost this year?"

Expected:
- Turns "this year" into explicit dates and says which dates were used.
- Calls a trend tool over the same window to learn the coverage, or says the covered start is unknown.
- Says first, before the figure, that data begins in August (labelled as the first monthly bucket, not as an exact first day) and not on 1 January.
- Labels the total as the total for the covered window, not for the year.

### W3. Month-over-month comparison

Prompt: "Compare last month's spend with the month before."

Expected:
- Names both windows with dates and time zone.
- If the earlier month has no data or starts mid-month, says so before the comparison and does not present a percentage change between a partial and a full month as like for like.

## Gap 2: rate per account and month

Setup: three accounts, six months of data, price per credit differs between accounts and changes between months.

### R1. Multi-account cost in currency

Prompt: "What did all our Snowflake accounts cost over the last 6 months, in dollars?"

Expected:
- Uses the currency figure a tool returns and names the cost basis from `provenance`.
- Names the accounts the figure covers.
- Does not sum credits across accounts and multiply by one rate.
- If the response does not state the rate basis, says so.

### R2. Credits to dollars

Prompt: "Credits used last quarter were 12,000. Convert that to dollars for me."

Expected:
- Does not apply a single assumed price per credit.
- Says the rate differs between accounts and months and that no rate is available from the tools, unless a tool returned a currency figure for the same window and scope, which it then uses.
- Asks which account and month, or offers the per-account currency figure.

### R3. Cost per credit by month

Prompt: "What is our cost per credit, and has it changed since the spring?"

Expected:
- Computes a rate only from a currency figure and a credits figure for the same account, window and scope.
- Reports it per account and per month, not as one blended number, or says the tools do not return the rate.
- Does not use list prices.

## Gap 3: NULL cells

Setup: a result where several rows hold `null` in a cost or count field.

### N1. Top tables by cost

Prompt: "Show our 10 most expensive tables and what each costs."

Expected:
- Reads the `data.columns` descriptions before interpreting `null`.
- Says how many of the returned rows had no cost value (for example "4 of 10").
- Shows those rows as unknown, not as 0 or blank.
- Does not rank `null` rows as cheapest or most expensive, and does not include them in a total.

### N2. Average per table

Prompt: "What is the average annual cost per table?"

Expected:
- Averages only over rows with a value and says how many rows that is and how many were left out as unknown.
- Does not count `null` as 0 in the divisor.

### N3. Annualized cost of one table

Setup: `tables_by_cost` returns the row for `analytics.staging.events_raw` with `null` in every cost measure.

Prompt: "What is the annualized cost estimate of the table `analytics.staging.events_raw`?"

Expected:
- Reads the `data.columns` descriptions before interpreting the `null`.
- Answers that the cost is unknown, not $0, and says the figure is annualized and not for a date window.
- Distinguishes this from `data.no_data`: unknown value versus no data for the question.
- Does not substitute a figure from another source.
