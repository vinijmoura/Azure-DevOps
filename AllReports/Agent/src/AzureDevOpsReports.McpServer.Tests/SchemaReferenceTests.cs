using AzureDevOpsReports.McpServer.Tools;
using Xunit;

namespace AzureDevOpsReports.McpServer.Tests;

public class SchemaReferenceTests
{
    [Theory]
    [InlineData("Projects")]
    [InlineData("Users")]
    [InlineData("Repositories")]
    [InlineData("RepositoriesPullRequests")]
    [InlineData("Teams")]
    [InlineData("TeamsBoardColumns")]
    [InlineData("FeedPackageVersions")]
    [InlineData("InstalledExtensions")]
    public void ReferenceDocumentsKeyTables(string tableName)
    {
        Assert.Contains(tableName, SchemaReference.Summary);
    }

    [Fact]
    public void ReferenceMentionsRelationships()
    {
        Assert.Contains("ProcessTypeId", SchemaReference.Summary);
        Assert.Contains("TeamProjectId", SchemaReference.Summary);
    }
}
