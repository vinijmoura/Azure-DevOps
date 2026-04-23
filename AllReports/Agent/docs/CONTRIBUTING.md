# Contributing

Thank you for your interest in improving the Azure DevOps Management Reports
MCP server. This document explains how to get a dev loop running, what kinds
of contributions are welcome, and the conventions we follow.

## Getting started

1. Fork <https://github.com/vinijmoura/Azure-DevOps> and clone your fork.
2. Install the .NET 10 SDK.
3. Restore, build and test:

   ```bash
   cd AllReports/Agent/src
   dotnet restore
   dotnet build
   dotnet test
   ```

4. Create a feature branch named `feature/<short-topic>` or `fix/<short-topic>`.

## What we welcome

- **New MCP tools** that surface useful queries on top of the existing schema
  (e.g. "cycle time", "stale PRs", "inactive users over N days").
- **Schema additions** — if the upstream `01_CreateTables.sql` gains new
  tables, update both `SchemaReference.Summary` and the tool set in the same PR.
- **Additional safety** — false positives / negatives in
  `ReadOnlySqlValidator` are treated as bugs. Add an `[InlineData]` row and
  fix the regex/logic.
- **Performance** — connection pooling, streaming results, async best
  practices.
- **Docs and examples** — especially for non-VS-Code MCP clients.

## Conventions

- **Language / style** — C# with `Nullable` enabled; follow the existing file
  layout (`Database/` for data access, `Tools/` for MCP surface).
- **Naming** — tool methods are in `PascalCase`; tool descriptions are written
  in English because they are surfaced to LLMs.
- **Read-only guarantee** — any new SQL path must go through
  `ReadOnlySqlValidator` *or* use parameterized, hard-coded statements
  internal to a tool. Never concatenate user input into SQL.
- **Tests** — add xUnit tests in `AzureDevOpsReports.McpServer.Tests`. Tests
  must not require a live database; use the validator / schema tests as a
  template.
- **Commits** — short imperative subject (`Add ListTeams tool`), a body
  explaining *why* when non-obvious.

## Pull request checklist

- [ ] `dotnet test` passes locally.
- [ ] New/changed tools are documented in `README.md`.
- [ ] If the database schema changed, `SchemaReference.Summary` was updated
      and the relevant tools were adjusted.
- [ ] No secrets (connection strings, PATs) in tests, samples, or commit
      history.

## Reporting issues

Open an issue on the upstream repo at
<https://github.com/vinijmoura/Azure-DevOps/issues> with:

- .NET SDK version (`dotnet --version`).
- MCP client and version (VS Code, Claude Desktop, …).
- Minimal repro — the exact prompt or JSON-RPC message, and the observed
  response or stderr output.

## Code of conduct

Be kind, be specific, and assume good faith. Reviews focus on the code, not
the contributor.
