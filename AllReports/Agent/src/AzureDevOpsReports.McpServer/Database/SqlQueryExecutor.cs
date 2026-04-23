using System.Data;
using System.Text;
using System.Text.Json;
using Microsoft.Data.SqlClient;

namespace AzureDevOpsReports.McpServer.Database;

public sealed class SqlQueryExecutor(SqlConnectionFactory factory)
{
    private const int DefaultMaxRows = 200;
    private const int HardMaxRows = 5_000;
    private const int CommandTimeoutSeconds = 30;

    public async Task<string> ExecuteJsonAsync(
        string sql,
        IReadOnlyDictionary<string, object?>? parameters = null,
        int? maxRows = null,
        CancellationToken ct = default)
    {
        var cap = Math.Clamp(maxRows ?? DefaultMaxRows, 1, HardMaxRows);

        await using var conn = await factory.OpenAsync(ct);
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = sql;
        cmd.CommandTimeout = CommandTimeoutSeconds;

        if (parameters is not null)
        {
            foreach (var (name, value) in parameters)
            {
                var p = cmd.CreateParameter();
                p.ParameterName = name.StartsWith('@') ? name : "@" + name;
                p.Value = value ?? DBNull.Value;
                cmd.Parameters.Add(p);
            }
        }

        await using var reader = await cmd.ExecuteReaderAsync(ct);

        var columns = new string[reader.FieldCount];
        for (var i = 0; i < reader.FieldCount; i++)
            columns[i] = reader.GetName(i);

        var rows = new List<Dictionary<string, object?>>();
        var truncated = false;

        while (await reader.ReadAsync(ct))
        {
            if (rows.Count >= cap)
            {
                truncated = true;
                break;
            }

            var row = new Dictionary<string, object?>(reader.FieldCount);
            for (var i = 0; i < reader.FieldCount; i++)
            {
                var value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                row[columns[i]] = NormalizeValue(value);
            }
            rows.Add(row);
        }

        var payload = new
        {
            rowCount = rows.Count,
            truncated,
            columns,
            rows
        };

        return JsonSerializer.Serialize(payload, new JsonSerializerOptions
        {
            WriteIndented = true
        });
    }

    public async Task<string> ListTablesAsync(CancellationToken ct = default)
    {
        const string sql = """
            SELECT
                s.name AS [Schema],
                t.name AS [Table],
                (SELECT SUM(p.rows)
                 FROM sys.partitions p
                 WHERE p.object_id = t.object_id AND p.index_id IN (0,1)) AS ApproxRowCount
            FROM sys.tables t
            INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
            ORDER BY s.name, t.name;
            """;

        return await ExecuteJsonAsync(sql, maxRows: HardMaxRows, ct: ct);
    }

    public async Task<string> DescribeTableAsync(string tableName, CancellationToken ct = default)
    {
        const string sql = """
            SELECT
                c.name                AS ColumnName,
                TYPE_NAME(c.user_type_id) AS DataType,
                c.max_length          AS MaxLength,
                c.precision           AS [Precision],
                c.scale               AS Scale,
                c.is_nullable         AS IsNullable,
                c.is_identity         AS IsIdentity
            FROM sys.columns c
            INNER JOIN sys.tables t ON t.object_id = c.object_id
            WHERE t.name = @table
            ORDER BY c.column_id;
            """;

        return await ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?> { ["table"] = tableName },
            maxRows: HardMaxRows,
            ct: ct);
    }

    private static object? NormalizeValue(object? value) => value switch
    {
        null => null,
        byte[] bytes => Convert.ToBase64String(bytes),
        DateTime dt => dt.ToString("O"),
        DateTimeOffset dto => dto.ToString("O"),
        Guid g => g.ToString(),
        _ => value
    };
}
