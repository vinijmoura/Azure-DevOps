using AzureDevOpsReports.McpServer.Database;
using Xunit;

namespace AzureDevOpsReports.McpServer.Tests;

public class ReadOnlySqlValidatorTests
{
    private readonly ReadOnlySqlValidator _sut = new();

    [Theory]
    [InlineData("SELECT 1")]
    [InlineData("select * from Projects")]
    [InlineData("  SELECT TeamProjectName FROM Projects WHERE TeamProjectName LIKE '%bank%';")]
    [InlineData("WITH t AS (SELECT 1 x) SELECT * FROM t")]
    [InlineData("SELECT 'INSERT INTO faux VALUES(1)' AS safe_literal")]
    public void AcceptsReadOnlyStatements(string sql)
    {
        var ex = Record.Exception(() => _sut.EnsureReadOnly(sql));
        Assert.Null(ex);
    }

    [Theory]
    [InlineData("INSERT INTO Projects VALUES ('x')")]
    [InlineData("UPDATE Projects SET TeamProjectName = 'x'")]
    [InlineData("DELETE FROM Projects")]
    [InlineData("DROP TABLE Projects")]
    [InlineData("ALTER TABLE Projects ADD col INT")]
    [InlineData("EXEC sp_who")]
    [InlineData("TRUNCATE TABLE Projects")]
    [InlineData("MERGE Projects AS t USING Projects AS s ON 1=1")]
    [InlineData("SELECT 1; DELETE FROM Projects")]
    [InlineData("   ")]
    [InlineData("")]
    public void RejectsForbiddenStatements(string sql)
    {
        Assert.ThrowsAny<Exception>(() => _sut.EnsureReadOnly(sql));
    }

    [Fact]
    public void AllowsTrailingSemicolon()
    {
        var ex = Record.Exception(() => _sut.EnsureReadOnly("SELECT 1;"));
        Assert.Null(ex);
    }

    [Fact]
    public void IgnoresForbiddenKeywordsInsideStringLiterals()
    {
        var ex = Record.Exception(() =>
            _sut.EnsureReadOnly("SELECT 'DELETE' AS word, 'INSERT INTO' AS phrase"));
        Assert.Null(ex);
    }

    [Fact]
    public void IgnoresForbiddenKeywordsInsideComments()
    {
        var ex = Record.Exception(() =>
            _sut.EnsureReadOnly("""
                /* DROP TABLE Projects */
                -- UPDATE Projects SET x = 1
                SELECT 1
                """));
        Assert.Null(ex);
    }
}
