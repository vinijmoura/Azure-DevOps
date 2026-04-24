# Azure DevOps Management Reports — MCP Server

An MCP (Model Context Protocol) server, written in .NET, that plugs the Azure
DevOps Management Reports SQL database
([Azure-DevOps/AllReports](https://github.com/vinijmoura/Azure-DevOps/tree/master/AllReports))
into AI chat experiences such as **VS Code Chat**, **Claude Desktop**, the
**Claude CLI**, or any other MCP-compatible client.

Once connected, you can ask natural-language questions against the ETL data
produced by the PowerShell extractor:

- "Which projects created the most pull requests last quarter?"
- "List PATs about to expire in the next 14 days."
- "The field *Severity* is used in which work items, templates and projects?"
- "In project *Banking*, which teams diverge from the common board configuration?"
- "Top 10 most downloaded NuGet packages across all feeds."
- "Which environments have the fewest approval checks configured?"

The server translates those requests into safe, **read-only** SQL queries over
the `azuredevopsreports` database.

## Features

- **28 MCP tools** covering every table in the reports database. See the
  [tool catalog](#tool-catalog) below or call the built-in `GetSchemaReference`
  tool from chat for a live summary.
- **Strict read-only validator** rejects `INSERT`, `UPDATE`, `DELETE`, `MERGE`,
  `TRUNCATE`, `DROP`, `ALTER`, `CREATE`, `GRANT`, `REVOKE`, `EXEC`, batch
  separators, and multi-statement payloads — even when hidden in comments or
  string literals.
- **Row-cap safety net** — default 200 rows per call, hard cap 5 000.
- **Parameterized queries** everywhere; user input never reaches the SQL text.
- Ships as a .NET global tool (`azdo-reports-mcp`) — single binary once built.
- **Multi-language aware** — tool descriptions are in English (for LLM tool
  selection), responses come back in whatever language the user asks in.

## Quick start (developers)

```bash
# 1. Clone and test
git clone https://github.com/vinijmoura/Azure-DevOps.git
cd Azure-DevOps/AllReports/Agent/src
dotnet test

# 2. Set the connection string
export AZDO_REPORTS_CONNECTION_STRING="Server=tcp:<server>.database.windows.net,1433;Database=azuredevopsreports;User Id=<user>;Password=<password>;Encrypt=True;"

# 3. Run the MCP server (stdio transport)
dotnet run --project AzureDevOpsReports.McpServer
```

See [`docs/INSTALLATION.md`](docs/INSTALLATION.md) for full setup including
VS Code, Claude Desktop and Claude CLI wiring, [`docs/TESTING.md`](docs/TESTING.md)
for local testing flows, and [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) for
how to contribute. Release history lives in [`CHANGELOG.md`](CHANGELOG.md).

## Tool catalog

The 28 tools are grouped by domain. Call `GetSchemaReference` from chat to get
the embedded schema documentation at any time.

| Domain | Tools |
|---|---|
| Schema / introspection | `GetSchemaReference`, `ListTables`, `DescribeTable` |
| Escape hatch | `ExecuteReadOnlySql` |
| Projects & activity | `ListProjects`, `TopProjectsByActivity` |
| Process templates & fields | `ListProcesses`, `ListProcessFields`, `FindFieldUsage` |
| Users, groups, PATs | `ListUsers`, `ListUserGroupMemberships`, `GroupMembershipSummary`, `ListPersonalAccessTokens` |
| Repositories, PRs, branches | `ListRepositories`, `ListPullRequests`, `ListBranchesAheadBehind` |
| Team configuration audit | `ListTeams`, `ListTeamWorkingDays`, `ListTeamBacklogLevels`, `ListTeamBoardColumns`, `ListTeamBoardLanes`, `CompareTeamsInProject`, `DetectTeamConfigurationAnomalies` |
| Environments & deployment gates | `ListEnvironmentApprovalChecks`, `EnvironmentApprovalCoverageSummary` |
| Feeds & extensions | `ListFeedPackageVersions`, `TopFeedPackagesByDownloads`, `ListInstalledExtensions` |

## Repository layout

```
AllReports/Agent/
  README.md
  CHANGELOG.md
  LICENSE
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
