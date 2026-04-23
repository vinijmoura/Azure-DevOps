# Installation

This guide covers both **developer** installs (run from source) and **end-user**
installs (run as a global tool).

## 1. Prerequisites

- .NET 10 SDK — <https://dotnet.microsoft.com/download>
- An Azure DevOps Management Reports SQL database, already populated by the
  ETL scripts under `AllReports/SQLScripts` and `AllReports/PowerShell`.
- An MCP-compatible client:
  - VS Code 1.99+ (built-in MCP support), or the GitHub Copilot Chat preview.
  - Claude Desktop.
  - Anthropic `claude` CLI.

## 2. Developer install (run from source)

```bash
git clone https://github.com/vinijmoura/Azure-DevOps.git
cd Azure-DevOps/AllReports/Agent/src
dotnet restore
dotnet build -c Release
```

Set the connection string (bash):

```bash
export AZDO_REPORTS_CONNECTION_STRING="Server=tcp:<server>.database.windows.net,1433;Database=azuredevopsreports;User Id=<user>;Password=<password>;Encrypt=True;"
```

PowerShell:

```powershell
$env:AZDO_REPORTS_CONNECTION_STRING = 'Server=tcp:<server>.database.windows.net,1433;Database=azuredevopsreports;User Id=<user>;Password=<password>;Encrypt=True;'
```

Run:

```bash
dotnet run --project AzureDevOpsReports.McpServer
```

The server starts on **stdio** — the standard MCP transport. The process will
wait silently for a client to speak MCP over stdin/stdout.

## 3. End-user install (global .NET tool)

Pack once from source:

```bash
cd AllReports/Agent/src/AzureDevOpsReports.McpServer
dotnet pack -c Release -o ./nupkg
```

Install globally:

```bash
dotnet tool install --global --add-source ./nupkg AzureDevOpsReports.McpServer
```

The command `azdo-reports-mcp` is now on `PATH`. Uninstall with
`dotnet tool uninstall --global AzureDevOpsReports.McpServer`.

## 4. Wiring it into VS Code

VS Code 1.99+ reads MCP servers from `.vscode/mcp.json` (workspace) or from
your user `settings.json` under `"mcp.servers"`.

Example `.vscode/mcp.json` (also provided in `examples/vscode-mcp.json`):

```jsonc
{
  "servers": {
    "azdo-reports": {
      "type": "stdio",
      "command": "azdo-reports-mcp",
      "env": {
        "AZDO_REPORTS_CONNECTION_STRING": "Server=tcp:<server>.database.windows.net,1433;Database=azuredevopsreports;User Id=<user>;Password=<password>;Encrypt=True;"
      }
    }
  }
}
```

If you are running from source instead of the global tool:

```jsonc
{
  "servers": {
    "azdo-reports": {
      "type": "stdio",
      "command": "dotnet",
      "args": [
        "run",
        "--project",
        "C:/path/to/Azure-DevOps/AllReports/Agent/src/AzureDevOpsReports.McpServer",
        "--no-build"
      ],
      "env": {
        "AZDO_REPORTS_CONNECTION_STRING": "..."
      }
    }
  }
}
```

Open the **Chat** view in VS Code, click the tools icon, and verify that the
`azdo-reports` tools appear in the list.

## 5. Wiring it into Claude Desktop

Edit `%APPDATA%\Claude\claude_desktop_config.json` (Windows) or
`~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

```jsonc
{
  "mcpServers": {
    "azdo-reports": {
      "command": "azdo-reports-mcp",
      "env": {
        "AZDO_REPORTS_CONNECTION_STRING": "..."
      }
    }
  }
}
```

Restart Claude Desktop and confirm the tools show up under the 🔌 icon.

## 6. Security notes

- The connection string is **never** logged.
- The MCP process only exposes `SELECT`/`WITH` queries — every input is
  validated by `ReadOnlySqlValidator` before it reaches SQL Server. Still,
  prefer a SQL login with **read-only** (`db_datareader`) permissions.
- A hard row cap of 5 000 protects the client from accidental full-table scans.
