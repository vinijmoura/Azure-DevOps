# Testing locally

Three layers of testing, in order of cost:

1. **Unit tests** — fast, no database required.
2. **MCP Inspector** — interactive UI to exercise every tool without any chat client.
3. **End-to-end in a real MCP client** — VS Code / Claude Desktop / Claude CLI.

## 1. Unit tests

```bash
cd AllReports/Agent/src
dotnet test
```

Current coverage (28 tests):

- `ReadOnlySqlValidator` — accepts/rejects SQL correctly, including forbidden
  keywords inside string literals and inside comments.
- `SchemaReference` — embedded documentation stays in sync with the SQL
  script.

No SQL Server instance is required.

## 2. MCP Inspector

The Inspector is the fastest way to verify a live database connection and to
exercise every one of the 28 tools.

```bash
# one-time
npm install -g @modelcontextprotocol/inspector

# run against the built DLL (adjust the path)
export AZDO_REPORTS_CONNECTION_STRING="Server=tcp:...;"
npx @modelcontextprotocol/inspector \
  dotnet /absolute/path/.../AzureDevOpsReports.McpServer.dll
```

What to check once the UI loads:

1. **Tools tab** lists 28 entries.
2. Call `ListTables` — you should get 17 rows back (one per table).
3. Call `GetSchemaReference` — returns the embedded schema doc.
4. Call `ListProjects` with no arguments — should return up to 100 rows.
5. Try a read-only query via `ExecuteReadOnlySql`:
   `SELECT TOP 5 TeamProjectName FROM Projects ORDER BY TeamProjectName`
6. Confirm an invalid query is rejected — paste
   `DELETE FROM Projects` into `ExecuteReadOnlySql` and expect
   `Only SELECT or WITH queries are allowed`.

## 3. End-to-end in VS Code

1. Install the server (see [`INSTALLATION.md`](INSTALLATION.md)).
2. Copy `examples/vscode-mcp.json` to your workspace as `.vscode/mcp.json`
   and adjust the path + connection string.
3. Reload VS Code (`Ctrl+Shift+P` → *Developer: Reload Window*).
4. Open the Chat pane and try these prompts:

   **Discovery**
   - "What tables exist in the reports database?"
   - "Describe the Projects table."

   **Projects and activity**
   - "Top 5 projects by pull requests completed."
   - "List active pull requests in project *Banking*."

   **Users & permissioning**
   - "Who is in the 'Project Collection Administrators' group?"
   - "List expired personal access tokens."
   - "Which groups have more than 50 members?"

   **Process templates & fields**
   - "Which process templates are in use and how many projects each has?"
   - "The field *Severity* is used in which work item types, process
     templates and projects?"
   - "Show all custom fields of the Scrum process."

   **Team configuration audit**
   - "In project *Banking*, which teams diverge from the most common board
     configuration?"
   - "List teams with fewer than 4 columns on their Stories board."
   - "Which teams don't include bugs on the backlog?"

   **Branches, environments, feeds**
   - "List stale branches with BehindCount greater than 500."
   - "Which environments have the fewest approval checks configured?"
   - "Top 10 most downloaded NuGet packages across all feeds."

Each prompt should trigger a tool call that you can inspect in the chat UI.

## 4. Troubleshooting

See [`INSTALLATION.md#troubleshooting`](INSTALLATION.md#troubleshooting) for
the shared table. Test-specific tips:

- If `dotnet test` fails on restore, make sure the .NET 10 SDK is active
  (`dotnet --version`). A `global.json` in `src/` pins the minimum.
- If the Inspector shows tools but every call times out, the server is
  reaching SQL but queries aren't completing — check the SQL Activity Monitor
  for blocking sessions.
- If the Inspector can't start the server at all, run the same
  `dotnet /path/to/.dll` command directly in the shell first and look at the
  stderr output.
