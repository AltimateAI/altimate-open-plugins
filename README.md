# Altimate open plugins

Plugins that connect AI coding agents to Altimate. One repository serves both **Claude Code** and **Codex**: each client reads its own marketplace file and installs the same plugin.

| Plugin | What it does |
| --- | --- |
| [`altimate-mcp`](plugins/altimate-mcp) | Connects the Altimate MCP (Snowflake and Databricks cost, usage, auto-tune, team rules, Studio sessions, table lineage) and adds eleven skills for using it well. |

## Why skills as well as the MCP

The MCP gives an agent about 40 tools per platform, one per question and grain. The skills help it choose the smallest useful call, interpret the result, and answer the question directly. They also describe known data limits, such as the account bill arriving a day late; access is still enforced by the server.

| Skill | Teaches the agent to |
| --- | --- |
| **Shared** | |
| `altimate-mcp` | Pick the minimum tools needed, choose the team, read results with their scope and material caveats, and give a focused answer |
| `altimate-mcp-setup` | Connect or repair the connection, including team errors and other common errors |
| **Snowflake** | |
| `altimate-snowflake` | Pick the right Snowflake tool: catalog, who may call each tool, data limits |
| `altimate-snowflake-cost` | Explain Snowflake spend: why it changed, where it goes, unit cost, AI cost drivers |
| `altimate-snowflake-autotune` | Work out the return on auto-tune: realized savings, savings per warehouse, candidates |
| `altimate-snowflake-teams` | Answer team questions: what a team spent (total, per day, average), which team pays, unattributed spend, whether each team can see what it pays for |
| `altimate-snowflake-tables` | Answer table questions: busiest tables, what feeds a table, what breaks if it changes, rough pipeline cost |
| **Databricks** | |
| `altimate-databricks` | Pick the right Databricks tool: catalog, who may call each tool, known gaps |
| `altimate-databricks-cost` | Explain Databricks spend: why it changed, where it goes, serving unit cost, AI/ML spend |
| `altimate-databricks-autotune` | Work out the return on auto-tune: savings against cost, decisions per resource |
| `altimate-databricks-lineage` | Answer lineage questions: what feeds a table, what breaks if it changes |

## Before you install

You need:

- An Altimate API key of your own (in the Altimate app, Settings, API key). Never use a shared admin key: the MCP answers with your own access rights.
- Your tenant name, as in your Altimate URL (`<tenant>.<domain>`).
- Network access to the MCP endpoint. The default endpoint is `https://mcp.getaltimate.com/mcp` (production, Altimate US platform).
- Git access to this repository, so the client can clone the marketplace (for example `gh auth login` if your client uses your GitHub credentials).

Set these in your shell profile (`~/.zshrc` or `~/.bashrc`), then open a new terminal:

```sh
export ALTIMATE_API_KEY="<your Altimate API key>"
export ALTIMATE_TENANT="<your tenant>"
# Optional
export ALTIMATE_TIMEZONE="Asia/Kolkata"          # default UTC
export ALTIMATE_MCP_URL="https://<endpoint>/mcp"  # default: https://mcp.getaltimate.com/mcp
```

The plugin reads the key from the environment each time the client starts. It is never written to a config file.

## Install in Claude Code

Inside Claude Code:

```text
/plugin marketplace add AltimateAI/altimate-open-plugins
/plugin install altimate-mcp@altimate-open-plugins
```

Or from a terminal:

```sh
claude plugin marketplace add AltimateAI/altimate-open-plugins
claude plugin install altimate-mcp@altimate-open-plugins
```

Restart Claude Code. `claude mcp list` should show `plugin:altimate-mcp:altimate ... ✔ Connected`. The skills appear as `/altimate-mcp:altimate-mcp`, `/altimate-mcp:altimate-snowflake-cost` and so on, and Claude also picks them up on its own when a question matches.

To enable it for everyone working in a repository, add this to that repository's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "altimate-open-plugins": {
      "source": { "source": "github", "repo": "AltimateAI/altimate-open-plugins" }
    }
  },
  "enabledPlugins": {
    "altimate-mcp@altimate-open-plugins": true
  }
}
```

## Install in Codex

```sh
codex plugin marketplace add AltimateAI/altimate-open-plugins
codex plugin add altimate-mcp@altimate-open-plugins
```

Restart Codex. `codex mcp list` should show `altimate` with bearer token variable `ALTIMATE_API_KEY`. In Codex you can also call a skill explicitly, for example `$altimate-snowflake-cost`.

Codex can run its sessions on a shared background server (`codex app-server`). MCP connections are made there, with that server's environment, not your terminal's. If the server started before the variables were set, or was started by macOS rather than your shell, `/mcp` shows `altimate: failed (0 tools)` even though your terminal has the variables. Either start Codex with `codex --no-daemon`, or stop the server and start Codex again from a terminal that has the variables:

```sh
codex app-server daemon stop   # interrupts other Codex sessions using it
codex
```

## Teams

The connection carries no team. If your tenant scopes access by team, the agent picks the team for each call and passes it as the tool's `team` argument:

- It first asks the MCP which teams you belong to (the `my_teams` tool, on both platforms).
- If your question names a team ("what did data-products spend last week?"), it uses that team.
- If you are in one team, it uses that team without asking.
- If you are in several and the question names none, it asks which team, or offers to answer for each of your teams separately. Per-team figures are never added into one total, because attribution can overlap.
- Tenant owners get the tenant-wide view unless they ask about a team.

You never need to give a team id, and changing team does not need a restart.

### Your own connection (optional)

`plugins/altimate-mcp/scripts/configure.sh` registers a user-level server called `altimate-user` in Claude Code and Codex, whichever is installed, without the plugin. Use it if you want only the MCP connection, or a second connection (for example one per tenant). Run `configure.sh --help` for every option: `--client claude|codex|both`, `--tenant`, `--url`, `--timezone`, `--name` and `--remove`.

A connection that plugin 0.1.x's `configure.sh` registered with a team (named `altimate-team` by default) now fails with `unsupported_header`. To fix it, remove the old connection with `configure.sh --remove --name altimate-team` (or the `--name` you used), then restart the client. The plugin's `altimate` server needs no team; run `configure.sh` again only if you want a standalone connection.

## Check it works

First confirm that the running client's MCP status shows Altimate tools. `codex mcp list` shows registration, not whether this session can call them. Ask "Which teams am I in, and am I an owner?" (the `my_teams` tool). It shows whose key the client sent: if the role is not yours, the client started from a terminal or editor opened before you set the key (open a new terminal and start it again). Then ask "What did our Snowflake warehouses cost yesterday?" (`warehouse_cost_by_warehouse`). The answer should give the value, tenant, team scope and window without unrelated breakdowns. Do not test with yesterday's account bill (`overall_cost_trend`): it arrives about a day late, so yesterday is usually empty. Databricks tools ship switched off and are released per tenant, so on a Databricks tenant the first check is `my_teams` and the tool list.

Every tool reads the same dataset or summary an Altimate page shows, with the same team scope, so team-scoped reads work for team members as they do on the page. Owner-only figures (storage and AI services cost, cost by usage type or account, the team rules) are refused for anyone else. A tool that is switched off for your tenant, or belongs to the other platform, answers `not_found`.

If calls fail, ask the agent to use the `altimate-mcp-setup` skill, or see its troubleshooting table. The most common causes:

| Symptom | Fix |
| --- | --- |
| `unauthenticated` | Check `ALTIMATE_API_KEY` and `ALTIMATE_TENANT`, then restart the client |
| `team_required` | You are in several teams: name the team in your question, or ask for each of your teams |
| `forbidden` on every call, or "Which teams am I in?" shows the wrong role | Most often the client started with an old key: profile changes reach only new terminals, so open a new terminal (or fully quit and reopen your editor) and start the client there. Otherwise the team named is not one of yours, a team was passed on a tenant that does not scope by team, or you are in no team: ask "Which teams am I in?", or ask your Altimate administrator |
| `unsupported_header` | A connection registered with a team by plugin 0.1.x's `configure.sh`: run `configure.sh --remove --name altimate-team` (or the `--name` you used) and restart the client |
| No Altimate tools | Check the running client's MCP tool status, plugin state, process environment and endpoint; a configured entry alone does not prove discovery |
| Codex `/mcp` shows `altimate: failed (0 tools)` with the variables set | Codex's background server lacks them: see [Install in Codex](#install-in-codex) |
| `codex mcp list` shows a key value in the bearer token variable column | `bearer_token_env_var` must name a variable, not hold the key: `codex mcp remove <name>` and re-register |

## Update and remove

| | Claude Code | Codex |
| --- | --- | --- |
| Update | `claude plugin marketplace update altimate-open-plugins`, then `claude plugin update altimate-mcp@altimate-open-plugins` | `codex plugin marketplace upgrade` |
| Remove | `claude plugin uninstall altimate-mcp@altimate-open-plugins` | `codex plugin remove altimate-mcp` |

An older standalone skill named `altimate-mcp-reads` (for the original 20-tool release) is replaced by this plugin. Remove it from `~/.codex/skills/` or `~/.claude/skills/` if you have it.

Upgrading from 0.3: `altimate-cost-analysis` and `altimate-lineage-and-usage` are replaced by per-platform skills. Cost workflows moved to `altimate-snowflake-cost` and `altimate-databricks-cost`, team and auto-tune workflows to `altimate-snowflake-teams`, `altimate-snowflake-autotune` and `altimate-databricks-autotune`, and table usage and lineage to `altimate-snowflake-tables` and `altimate-databricks-lineage`. Update any prompt or setting that names the old skills.

## Repository layout

```text
.claude-plugin/marketplace.json       Claude Code marketplace
.agents/plugins/marketplace.json      Codex marketplace
plugins/altimate-mcp/
  .claude-plugin/plugin.json          Claude Code plugin manifest
  .codex-plugin/plugin.json           Codex plugin manifest
  .mcp.json                           MCP server for Claude Code (environment variables expanded at runtime)
  codex.mcp.json                      MCP server for Codex (bearer token and headers read from the environment)
  skills/<name>/SKILL.md              Skills, shared by both clients
  scripts/configure.sh                Registers a standalone or per-tenant connection
```

## Contributing and security

This repository accepts issues only, not pull requests: see [CONTRIBUTING.md](CONTRIBUTING.md). Report vulnerabilities as described in [SECURITY.md](SECURITY.md).

## Develop

```sh
claude plugin validate .                      # marketplace
claude plugin validate plugins/altimate-mcp   # plugin
claude plugin marketplace add ./              # try it from a local clone
codex plugin marketplace add ./
```

Skills are plain Markdown: keep each one focused on one job, and keep tool names in step with the MCP's live tool list. Add a new plugin under `plugins/` and list it in both marketplace files.

© 2026 Altimate AI. All rights reserved.
