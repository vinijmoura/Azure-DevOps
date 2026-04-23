# Azure DevOps Management Reports — MCP Server

An MCP (Model Context Protocol) server, written in .NET, that plugs the Azure
DevOps Management Reports SQL database
([Azure-DevOps/AllReports](https://github.com/vinijmoura/Azure-DevOps/tree/master/AllReports))
into AI chat experiences such as **VS Code Chat**, **Claude Desktop**, or any
other MCP-compatible client.

Once connected, you can ask natural-language questions against the ETL data
produced by the PowerShell extractor:

- "Which projects created the most pull requests last quarter?"
- "List PATs about to expire in the next 14 days."
- "Show me all repositories without branch protection."

The server will translate those requests into safe, **read-only** SQL queries
over the `azuredevopsreports` database.

## Features

- Built-in MCP tools:
  - `GetSchemaReference` — embedded documentation of all tables and relationships.
  - `ListTables`, `DescribeTable` — live introspection of the connected database.
  - `ListProjects`, `ListUsers`, `ListPullRequests`, `ListRepositories`,
    `ListInstalledExtensions`, `ListPersonalAccessTokens`.
  - `ListUserGroupMemberships`, `GroupMembershipSummary` — permissioning /
    audit over the `UsersGroups` table ("who is in group X?", counts per group).
  - `ListFeedPackageVersions`, `TopFeedPackagesByDownloads` — Azure Artifacts
    feed insights (filter by feed/package/type/source, rank by download
    aggregates).
  - `TopProjectsByActivity` — pre-built aggregation over the `Projects` metrics columns.
  - `ExecuteReadOnlySql` — run an arbitrary `SELECT` / `WITH` query (DDL/DML rejected).
- Strict read-only validator: rejects `INSERT`, `UPDATE`, `DELETE`, `MERGE`,
  `TRUNCATE`, `DROP`, `ALTER`, `CREATE`, `GRANT`, `REVOKE`, `EXEC`, batch
  separators, and multi-statement payloads — even when hidden in comments.
- Row-cap safety net (default 200, hard cap 5 000).
- Ships as a .NET global tool (`azdo-reports-mcp`) — single binary, trivial to
  distribute.

## Quick start

```bash
# 1. Restore, build and test
cd AllReports/Agent/src
dotnet test

# 2. Set the connection string
export AZDO_REPORTS_CONNECTION_STRING="Server=tcp:<your-server>.database.windows.net,1433;Database=azuredevopsreports;User Id=<user>;Password=<password>;Encrypt=True;"

# 3. Run the MCP server (stdio transport)
dotnet run --project AzureDevOpsReports.McpServer
```

See [`docs/INSTALLATION.md`](docs/INSTALLATION.md) for VS Code / Claude Desktop
wiring, [`docs/TESTING.md`](docs/TESTING.md) for local testing flows, and
[`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) for how to contribute.

## Repository layout

```
AllReports/Agent/
  src/
    AzureDevOpsReports.sln
    AzureDevOpsReports.McpServer/          # the MCP server (.NET 10)
    AzureDevOpsReports.McpServer.Tests/    # xUnit tests
  docs/
    INSTALLATION.md
    TESTING.md
    CONTRIBUTING.md
  examples/
    vscode-mcp.json
    claude-desktop.json
```

## Data source

This server is intended to run against the SQL database populated by
`AllReports/SQLScripts/01_CreateTables.sql` and the PowerShell extractor
(`AllReports/PowerShell/Processes.ps1`). Make sure those have completed at
least once before you point the MCP server at the database.

## License

MIT — see [`LICENSE`](LICENSE).
