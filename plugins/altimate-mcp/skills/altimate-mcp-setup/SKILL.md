---
name: altimate-mcp-setup
description: Connect or repair the Altimate MCP connection in Claude Code or Codex - environment variables, the configure script, team errors, and fixes for unauthenticated, forbidden or unreachable errors. Use when Altimate tools are missing, every call fails, or the user asks how to set up the Altimate MCP.
---

# Setting up the Altimate MCP

The plugin registers a server named `altimate`. It reads the user's settings from environment variables, so nothing secret is stored in a file.

## What the user needs

| Variable | Required | Meaning |
| --- | --- | --- |
| `ALTIMATE_API_KEY` | yes | The user's own Altimate API key (Settings, API key in the Altimate app). Never a shared admin key. |
| `ALTIMATE_TENANT` | yes | The tenant name, as in the Altimate URL (`<tenant>.<domain>`). |
| `ALTIMATE_MCP_URL` | no | The MCP endpoint. Defaults to production, `https://mcp.getaltimate.com/mcp`. |
| `ALTIMATE_TIMEZONE` | no | IANA timezone for date buckets. Defaults to UTC. |

Everyone needs only the two required variables, owners and team members alike. The connection carries no team: the agent passes the team name as the `team` argument of each tool call (see the `altimate-mcp` skill).

## Steps

1. Ask the user to set the variables in their shell profile (for example `~/.zshrc`). Do not ask them to paste the key into the chat, and never print it.
   A client reads the variables once, when it starts, from the process that launched it. A profile change reaches only terminals opened afterwards: a client started from an older terminal tab, or from an editor (Zed, VS Code) opened before the change, keeps the old key. Have the user open a new terminal (or fully quit and reopen the editor) and start the client from it.
2. The plugin's bundled server works as installed for every user. `scripts/configure.sh` is only for a connection outside the plugin, or a second one (for example one per tenant); it still reads the key from the environment.
3. Check that this client session discovers the server's tools. Then call `my_teams` (the same tool on Snowflake and Databricks): it is cheap and shows whether the caller is an owner and which teams they can pass as `team`. A `forbidden` "You are not part of any team" from it means the connection works but the user needs a team from their Altimate administrator. A Databricks tenant lists only `my_teams` and the tools released for it: every other Databricks tool ships switched off. A server listed by `codex mcp list` may still expose no tools to the running session.

Run `scripts/configure.sh --help` for every option, including `--client claude|codex|both` and `--name` for a second connection (for example one per tenant).

## When calls fail

| Symptom | Cause | Fix |
| --- | --- | --- |
| No Altimate tools in this session | Plugin not enabled, the client/server did not inherit the variables, endpoint unreachable, or tool discovery failed | Check `/plugin` (Claude) or `codex plugin list`, then the client's live MCP tool status; verify variables are present in the process that connects, and restart that client if needed. Do not treat `codex mcp list` alone as a connection test or bypass missing tools with raw HTTP |
| Codex shows `altimate: failed (0 tools)` although the variables are set in the terminal | Codex runs MCP connections on its shared background server (`codex app-server`), which did not inherit the variables | Start Codex with `codex --no-daemon`, or run `codex app-server daemon stop` (interrupts other Codex sessions) and start Codex again from a terminal with the variables |
| Codex lists a key value as the bearer token variable | `bearer_token_env_var` holds the key instead of a variable name | `codex mcp remove <name>`, then re-register with the variable name; the key is now exposed in the config, so rotate it |
| `unauthenticated` on every call | Key or tenant missing, wrong or expired | Check both variables; a key belongs to one tenant only |
| `team_required` | The caller is in several teams and the call named none | Pass `team` with one of the names in `details.teams`; this is not a connection problem |
| `my_teams` reports the wrong role or teams (for example a non-owner with one team for a user who is an owner) | The client started with an old or another user's key (step 1) | Open a new terminal, compare `echo "$ALTIMATE_API_KEY" \| shasum \| cut -c1-8` with the old terminal's, and restart the client from the new one |
| `forbidden` on every call | An old key (see the row above), a `team` the caller is not in, a `team` on a tenant that does not scope by team, or a caller in no team ("You are not part of any team") | Check the names from `my_teams` and pass one exactly, or none; a caller in no team must ask their Altimate administrator. Re-registering the connection does not fix it |
| `forbidden` on some tools | Owner-only tools (team rules, storage and AI services cost, cost by usage type or account, the `team` filter), a call with `team` to a tool that needs an owner without one, or a tool the role may not use | Expected; explain it |
| `unsupported_header` on every call | A connection registered with `configure.sh --team` (plugin 0.1.x) sends an `X-Team` header, or an older one sends `X-Team-Id` or `X-User-Group-Id`; the server refuses all three | Run `scripts/configure.sh --remove --name altimate-team` (or the `--name` used then), then restart the client. The plugin's `altimate` server needs no team; the team is chosen per call. Register again with `configure.sh` only for a standalone connection |
| `not_found: No such tool is available to you.` for a tool the user expects | The tool is switched off for the tenant, belongs to the other platform, or was renamed (for example `teams` is now `my_teams`, `warehouses` is now `warehouses_list`) | Use a tool from the live list; ask an Altimate administrator to release a switched-off tool |
| Connection refused or DNS error | The endpoint is unreachable from this network, or `ALTIMATE_MCP_URL` points elsewhere | Check network and VPN, or point `ALTIMATE_MCP_URL` at a reachable endpoint |
