using System.Text.RegularExpressions;

namespace AzureDevOpsReports.McpServer.Database;

public sealed partial class ReadOnlySqlValidator
{
    private static readonly string[] ForbiddenKeywords =
    [
        "INSERT", "UPDATE", "DELETE", "MERGE", "TRUNCATE", "DROP",
        "ALTER", "CREATE", "GRANT", "REVOKE", "EXEC", "EXECUTE",
        "BACKUP", "RESTORE", "SHUTDOWN", "BULK", "xp_", "sp_executesql"
    ];

    public void EnsureReadOnly(string sql)
    {
        if (string.IsNullOrWhiteSpace(sql))
            throw new ArgumentException("Query cannot be empty.", nameof(sql));

        var stripped = StringLiteralRegex().Replace(sql, "''");
        stripped = BlockCommentRegex().Replace(stripped, " ");
        stripped = LineCommentRegex().Replace(stripped, " ");

        var upper = stripped.ToUpperInvariant();

        if (!StartsWithSelectOrWithRegex().IsMatch(upper))
            throw new InvalidOperationException("Only SELECT or WITH (CTE) queries are allowed.");

        foreach (var kw in ForbiddenKeywords)
        {
            var pattern = $@"(^|[\s(;])({Regex.Escape(kw)})([\s(;]|$)";
            if (Regex.IsMatch(upper, pattern))
                throw new InvalidOperationException($"Query contains forbidden keyword: {kw}.");
        }

        if (stripped.Contains(';'))
        {
            var trimmed = stripped.TrimEnd().TrimEnd(';').TrimEnd();
            if (trimmed.Contains(';'))
                throw new InvalidOperationException("Only a single SQL statement is allowed.");
        }
    }

    [GeneratedRegex(@"'([^']|'')*'", RegexOptions.Compiled)]
    private static partial Regex StringLiteralRegex();

    [GeneratedRegex(@"/\*.*?\*/", RegexOptions.Compiled | RegexOptions.Singleline)]
    private static partial Regex BlockCommentRegex();

    [GeneratedRegex(@"--[^\n]*", RegexOptions.Compiled)]
    private static partial Regex LineCommentRegex();

    [GeneratedRegex(@"^\s*(SELECT|WITH)\b", RegexOptions.Compiled)]
    private static partial Regex StartsWithSelectOrWithRegex();
}
