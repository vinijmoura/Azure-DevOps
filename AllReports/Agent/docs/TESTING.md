# Testing locally

There are three layers of testing, in order of cost:

1. **Unit tests** — fast, no database required.
2. **Manual MCP handshake** — talk to the server over stdio without any client.
3. **End-to-end in a real MCP client** — VS Code / Claude Desktop.

## 1. Unit tests

```bash
cd AllReports/Agent/src
dotnet test
```

These cover:

- `ReadOnlySqlValidator` — accepts / rejects queries correctly, including
  edge cases such as forbidden keywords inside string literals or comments.
- `SchemaReference` — embedded documentation stays in sync with the SQL
  script.

No SQL Server instance is required.

## 2. Manual MCP handshake (no client)

Start the server so it speaks MCP over stdio:

```bash
export AZDO_REPORTS_CONNECTION_STRING="..."
dotnet run --project AzureDevOpsReports.McpServer
```

In another terminal, pipe an `initialize` request in:

```bash
cat <<'EOF' | dotnet run --project AzureDevOpsReports.McpServer
{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"manual","version":"0.0"}}}
EOF
```

You should see a JSON `result` with the server's capabilities. You can
follow up with `tools/list`:

```json
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}
```

…and then invoke one:

```json
{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"ListTables","arguments":{}}}
```

Tip: the **MCP Inspector** (`npx @modelcontextprotocol/inspector`) is the
fastest way to exercise every tool interactively — point it at
`dotnet run --project ...AzureDevOpsReports.McpServer`.

## 3. End-to-end in VS Code

1. Install the server (see `docs/INSTALLATION.md`).
2. Add `examples/vscode-mcp.json` to your workspace as `.vscode/mcp.json`
   (adjust the connection string).
3. Reload VS Code.
4. Open the Chat pane and try:
   - "What tables exist in the reports database?"
   - "Describe the Projects table."
   - "Top 5 projects by pull requests completed."
   - "List expired personal access tokens."
   - "Who is in the 'Project Collection Administrators' group?"
   - "Which process templates are in use and how many projects each has?"
   - "The field 'Severity' is used in which work item types, process
     templates and projects?"
   - "Inside project 'Banking', which teams diverge from the most common
     board configuration?"
   - "List stale branches with BehindCount greater than 500."
   - "Which environments have the fewest approval checks configured?"
   - "Top 10 most downloaded NuGet packages across all feeds."

Each prompt should trigger a tool call that you can inspect in the chat UI.

## 4. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Missing connection string` on startup | env var not set | Export `AZDO_REPORTS_CONNECTION_STRING` |
| `Login failed for user` | wrong SQL credentials | Verify SQL login and firewall rules |
| `Only SELECT or WITH queries are allowed` | attempted DDL/DML | Rephrase as a `SELECT` or use a dedicated tool |
| Client sees no tools | server didn't start | Check stderr — the logger writes to stderr, stdout is reserved for MCP |
