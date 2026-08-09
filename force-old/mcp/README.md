# @force/mcp

Model Context Protocol server for [Force](https://force.app) — read and update your contract, quotes, goals, and reflection from Claude (or any MCP client).

## Install + configure

1. In the Force web app, go to **Settings → API keys** and create a new key. Copy it (you can only see it once).
2. Add this server to your Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

   ```json
   {
     "mcpServers": {
       "force": {
         "command": "npx",
         "args": ["-y", "@force/mcp"],
         "env": {
           "FORCE_API_KEY": "fc_live_..."
         }
       }
     }
   }
   ```

3. Restart Claude Desktop.

To point at a self-hosted Force instance, set `FORCE_API_BASE=https://your-host`.

## Tools

| Tool | Purpose |
| --- | --- |
| `get_contract` | Read the contract Markdown |
| `update_contract` | Replace the whole contract |
| `append_to_contract` | Append text to the end of the contract |
| `list_quotes` / `add_quote` / `delete_quote` | Manage motivational quotes |
| `list_goals` / `set_goals` | Manage the daily goals checklist |
| `get_reflection` / `set_reflection` | Read or replace the free-form reflection |

## Development

```bash
pnpm install
pnpm build
FORCE_API_KEY=fc_live_... FORCE_API_BASE=http://localhost:3000 node dist/index.js
```
