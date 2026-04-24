# Changelog

All notable changes to this project will be documented in this file. The
format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Docs
- Rewrote `docs/INSTALLATION.md` as a single consolidated guide covering
  prerequisites, source install, VS Code / Claude Desktop / Claude CLI wiring,
  MCP Inspector verification, and a broader troubleshooting table.
- Rewrote `docs/TESTING.md` around the MCP Inspector as the primary manual
  testing path; removed the previous stdio handshake snippet (which didn't
  work end-to-end without keeping the server's stdin open).
- Refreshed `README.md` with a condensed tool catalog by domain and a link
  to this changelog.

## [0.1.0] — 2026-04-23

Initial release. Feature branch: `feature/mcp-server-agent`.

### Added

**Server scaffold**
- .NET 10 solution (`AzureDevOpsReports.sln`) with:
  - `AzureDevOpsReports.McpServer` — Model Context Protocol server over the
    stdio transport, packaged as a dotnet global tool
    (`azdo-reports-mcp`).
  - `AzureDevOpsReports.McpServer.Tests` — xUnit test project (28 tests).
- Dependencies: `ModelContextProtocol 0.3.0-preview.4`,
  `Microsoft.Data.SqlClient 5.2.2`, `Microsoft.Extensions.Hosting 9.0.0`.
- Configuration via the `AZDO_REPORTS_CONNECTION_STRING` environment variable
  (or `ConnectionStrings:AzureDevOpsReports` in `appsettings.json`).

**Safety**
- `ReadOnlySqlValidator` — rejects `INSERT`, `UPDATE`, `DELETE`, `MERGE`,
  `TRUNCATE`, `DROP`, `ALTER`, `CREATE`, `GRANT`, `REVOKE`, `EXEC`,
  `sp_executesql`, `xp_` extended procs, batch separators and multi-statement
  payloads — with awareness of string literals and comments.
- Row cap: default 200 per call, hard cap 5 000.
- `SqlParameter` for every filter; whitelisted switch resolvers for sort /
  metric parameters that would otherwise need to reach the SQL text.

**Tools (28 total)**
- *Schema / introspection (3):* `GetSchemaReference`, `ListTables`,
  `DescribeTable`.
- *Escape hatch (1):* `ExecuteReadOnlySql`.
- *Projects & activity (2):* `ListProjects`, `TopProjectsByActivity`.
- *Process templates & fields (3):* `ListProcesses`, `ListProcessFields`,
  `FindFieldUsage`.
- *Users, groups, PATs (4):* `ListUsers`, `ListUserGroupMemberships`,
  `GroupMembershipSummary`, `ListPersonalAccessTokens`.
- *Repositories, PRs, branches (3):* `ListRepositories`, `ListPullRequests`,
  `ListBranchesAheadBehind`.
- *Team configuration audit (7):* `ListTeams`, `ListTeamWorkingDays`,
  `ListTeamBacklogLevels`, `ListTeamBoardColumns`, `ListTeamBoardLanes`,
  `CompareTeamsInProject`, `DetectTeamConfigurationAnomalies`.
- *Environments & deployment gates (2):* `ListEnvironmentApprovalChecks`,
  `EnvironmentApprovalCoverageSummary`.
- *Feeds & extensions (3):* `ListFeedPackageVersions`,
  `TopFeedPackagesByDownloads`, `ListInstalledExtensions`.

Coverage: every one of the 17 tables in `AllReports/SQLScripts/01_CreateTables.sql`
is reachable through at least one dedicated tool.

**Documentation**
- `README.md` with quick start, features, tool catalog and layout.
- `docs/INSTALLATION.md`, `docs/TESTING.md`, `docs/CONTRIBUTING.md`.
- `examples/vscode-mcp.json`, `examples/claude-desktop.json`.
- `LICENSE` (MIT).

[Unreleased]: https://github.com/vinijmoura/Azure-DevOps/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/vinijmoura/Azure-DevOps/releases/tag/v0.1.0
