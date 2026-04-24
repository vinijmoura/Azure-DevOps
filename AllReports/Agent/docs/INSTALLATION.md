# Installation

This document covers everything a user needs to get the Azure DevOps Management
Reports MCP server talking to VS Code, Claude Desktop, or the Claude CLI.

- [Prerequisites](#prerequisites)
- [Install from source](#install-from-source) (recommended today)
- [Configure your MCP client](#configure-your-mcp-client)
  - [VS Code](#vs-code-199)
  - [Claude Desktop](#claude-desktop)
  - [Claude CLI](#claude-cli-claude)
- [Verify the installation](#verify-the-installation)
- [Security notes](#security-notes)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before you start, confirm the following:

- [ ] **.NET 10 SDK** installed — <https://dotnet.microsoft.com/download>
      (the SDK is required today because the server is installed from source;
      when a pre-built NuGet package is published, the runtime alone will
      suffice).
- [ ] **An MCP-compatible client**, one of:
  - VS Code **1.99+** (MCP support is built in — check `Help → About`).
  - GitHub Copilot Chat extension (preview, with MCP support enabled).
  - Claude Desktop (latest).
  - Claude CLI (`npm i -g @anthropic-ai/claude-cli` or equivalent).
- [ ] **Network access** from your machine to the SQL Server / Azure SQL
      instance hosting the `azuredevopsreports` database.
- [ ] **SQL credentials** with `db_datareader` role (minimum). A read-only
      login is strongly preferred over a DBO account.
- [ ] **Firewall rule** for Azure SQL — your client IP must be allow-listed.
- [ ] **The reports database itself**, populated by
      `AllReports/SQLScripts/01_CreateTables.sql` +
      `AllReports/PowerShell/Processes.ps1`. Without at least one ETL run
      there is nothing to query.

## Install from source

There is no public NuGet package yet, so the current install path is
clone + build.

```bash
git clone https://github.com/vinijmoura/Azure-DevOps.git
cd Azure-DevOps/AllReports/Agent/src
dotnet restore
dotnet build -c Release
dotnet test    # optional but recommended — 28 unit tests
```

This produces the server DLL at
`AzureDevOpsReports.McpServer/bin/Release/net10.0/AzureDevOpsReports.McpServer.dll`
and an executable/launcher alongside it (platform dependent).

> **Heads-up:** the `.csproj` already has `<PackAsTool>true</PackAsTool>`, so
> the same project can be packed (`dotnet pack -c Release`) and installed as
> a dotnet global tool named `azdo-reports-mcp`. Once a public NuGet release
> exists, the install step will collapse to:
>
> ```bash
> dotnet tool install --global AzureDevOpsReports.McpServer
> ```
>
> This document will be updated on first release.

## Configure your MCP client

Pick the `command` and `args` that match your install path.

**Option 1 — `dotnet run` (when running from the cloned source tree)**

```jsonc
"command": "dotnet",
"args": [
  "run",
  "--project",
  "C:/path/to/Azure-DevOps/AllReports/Agent/src/AzureDevOpsReports.McpServer",
  "--no-build",
  "-c",
  "Release"
]
```

**Option 2 — run the built DLL directly (no rebuild on every start)**

```jsonc
"command": "dotnet",
"args": [
  "C:/path/to/Azure-DevOps/AllReports/Agent/src/AzureDevOpsReports.McpServer/bin/Release/net10.0/AzureDevOpsReports.McpServer.dll"
]
```

**Option 3 — global tool (future, once on NuGet)**

```jsonc
"command": "azdo-reports-mcp"
```

In every case, the environment variable `AZDO_REPORTS_CONNECTION_STRING` must
be set for the server process. The JSON examples below use the `env` block to
pass it without exporting it globally.

### VS Code 1.99+

Create `.vscode/mcp.json` in your workspace (or add under `"mcp.servers"` in
your user `settings.json`):

```jsonc
{
  "servers": {
    "azdo-reports": {
      "type": "stdio",
      "command": "dotnet",
      "args": [
        "C:/path/to/Azure-DevOps/AllReports/Agent/src/AzureDevOpsReports.McpServer/bin/Release/net10.0/AzureDevOpsReports.McpServer.dll"
      ],
      "env": {
        "AZDO_REPORTS_CONNECTION_STRING": "Server=tcp:<server>.database.windows.net,1433;Database=azuredevopsreports;User Id=<user>;Password=<password>;Encrypt=True;"
      }
    }
  }
}
```

A ready-to-adapt template lives in [`examples/vscode-mcp.json`](../examples/vscode-mcp.json).

After saving the file:

1. `Ctrl+Shift+P` → **Developer: Reload Window**
2. Open the Chat panel.
3. Click the 🔌 (tools) icon — confirm `azdo-reports` shows up with 28 tools.

### Claude Desktop

Edit the config file:

- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Linux: `~/.config/Claude/claude_desktop_config.json`

```jsonc
{
  "mcpServers": {
    "azdo-reports": {
      "command": "dotnet",
      "args": [
        "/absolute/path/to/Azure-DevOps/AllReports/Agent/src/AzureDevOpsReports.McpServer/bin/Release/net10.0/AzureDevOpsReports.McpServer.dll"
      ],
      "env": {
        "AZDO_REPORTS_CONNECTION_STRING": "..."
      }
    }
  }
}
```

Restart Claude Desktop. Tools appear under the 🔌 icon in the composer.

A template is provided at [`examples/claude-desktop.json`](../examples/claude-desktop.json).

### Claude CLI (`claude`)

```bash
claude mcp add azdo-reports \
  --command dotnet \
  --args "/absolute/path/.../AzureDevOpsReports.McpServer.dll" \
  --env "AZDO_REPORTS_CONNECTION_STRING=Server=tcp:...;"
```

Then run `claude` and ask: *"List the reports database tables."*

## Verify the installation

Fastest path — use the **MCP Inspector** (no client configuration needed):

```bash
npx @modelcontextprotocol/inspector \
  dotnet /absolute/path/.../AzureDevOpsReports.McpServer.dll
```

Make sure `AZDO_REPORTS_CONNECTION_STRING` is exported in the same shell, or
pass it with `--env`.

The Inspector opens a browser UI where you can:

1. Confirm the 28 tools are listed.
2. Call `ListTables` to verify the SQL connection works.
3. Try each tool with concrete arguments before moving to a real chat client.

## Security notes

- The connection string is **never** logged. Logs go to **stderr** only;
  stdout is reserved for the MCP stdio transport.
- The MCP process only exposes `SELECT` / `WITH` queries. Every input is
  validated by `ReadOnlySqlValidator` before it reaches SQL Server. Still,
  prefer a SQL login with **read-only** (`db_datareader`) permissions so a
  future bug cannot do damage.
- A hard row cap of 5 000 protects the client from accidental full-table
  scans.
- Do not commit your actual connection string. The `examples/` files ship
  with placeholders on purpose.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Missing connection string` on startup | env var not set for the process | Set `AZDO_REPORTS_CONNECTION_STRING` in the `env` block of your MCP config, not just in your shell |
| `Login failed for user` | wrong SQL credentials | Verify SQL login and that the user has at least `db_datareader` on `azuredevopsreports` |
| `Cannot open server '<name>' requested by the login` | Azure SQL firewall | Allow-list your client IP in the Azure SQL firewall rules |
| `A network-related or instance-specific error…` | port 1433 blocked | Check corporate firewall / VPN |
| `Only SELECT or WITH queries are allowed` | tried DDL/DML via `ExecuteReadOnlySql` | Rephrase as `SELECT`, or use a dedicated tool |
| `Unknown orderBy 'X'` | invalid value for a whitelisted sort parameter | Use one of the documented values in the tool description |
| Client reports 0 tools | server didn't start | Check stderr of the process — the logger writes there; stdout is reserved for MCP |
| `dotnet: command not found` in VS Code output | PATH differences in GUI apps | Use the absolute path to `dotnet` in `command` (`/usr/local/share/dotnet/dotnet`, `C:/Program Files/dotnet/dotnet.exe`, …) |
| Tool call hangs > 30 s | SQL command timeout | Review the query; `ExecuteReadOnlySql` has a 30-second command timeout on purpose |
