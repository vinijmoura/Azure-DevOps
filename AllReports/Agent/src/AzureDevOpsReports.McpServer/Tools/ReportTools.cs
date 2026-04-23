using System.ComponentModel;
using AzureDevOpsReports.McpServer.Database;
using ModelContextProtocol.Server;

namespace AzureDevOpsReports.McpServer.Tools;

[McpServerToolType]
public sealed class ReportTools(
    SqlQueryExecutor executor,
    ReadOnlySqlValidator validator)
{
    [McpServerTool, Description(
        "Returns a description of the Azure DevOps Management Reports database schema " +
        "(tables, columns, and relationships). Call this before writing any SQL.")]
    public string GetSchemaReference() => SchemaReference.Summary;

    [McpServerTool, Description(
        "Lists every user table in the connected database along with an approximate row count.")]
    public Task<string> ListTables(CancellationToken ct)
        => executor.ListTablesAsync(ct);

    [McpServerTool, Description(
        "Describes the columns of a specific table (data types, nullability, identity).")]
    public Task<string> DescribeTable(
        [Description("Table name, e.g. 'Projects'.")] string tableName,
        CancellationToken ct)
        => executor.DescribeTableAsync(tableName, ct);

    [McpServerTool, Description(
        "Executes a read-only SELECT (or WITH ... SELECT) query against the Azure DevOps " +
        "Management Reports database and returns the rows as JSON. " +
        "INSERT/UPDATE/DELETE/DDL are rejected.")]
    public Task<string> ExecuteReadOnlySql(
        [Description("A SELECT or WITH query. Only one statement is allowed.")] string sql,
        [Description("Maximum rows to return. Defaults to 200, hard cap 5000.")] int? maxRows,
        CancellationToken ct)
    {
        validator.EnsureReadOnly(sql);
        return executor.ExecuteJsonAsync(sql, maxRows: maxRows, ct: ct);
    }

    [McpServerTool, Description(
        "Returns projects with aggregate activity metrics (work items, commits, PRs, builds, releases). " +
        "Optional name filter performs a case-insensitive LIKE match.")]
    public Task<string> ListProjects(
        [Description("Optional project name substring to filter by.")] string? nameContains,
        [Description("Maximum rows. Default 100.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectId, p.TeamProjectName, pr.ProcessName,
                   p.TeamProjectCountWorkItemCreated,
                   p.TeamProjectCountWorkItemCompleted,
                   p.TeamProjectCountCommitsPushed,
                   p.TeamProjectCountPRsCreated,
                   p.TeamProjectCountPRsCompleted,
                   p.TeamProjectCountBuilds,
                   p.TeamProjectCountReleases
            FROM Projects p
            LEFT JOIN Processes pr ON pr.ProcessTypeId = p.ProcessTypeId
            WHERE (@name IS NULL OR p.TeamProjectName LIKE '%' + @name + '%')
            ORDER BY p.TeamProjectName;
            """;
        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?> { ["name"] = nameContains },
            maxRows: maxRows ?? 100,
            ct: ct);
    }

    [McpServerTool, Description(
        "Returns users with their license, creation date and last-access date. " +
        "Supports optional display-name or principal-name substring filter.")]
    public Task<string> ListUsers(
        [Description("Optional substring to filter UserDisplayName or UserPrincipalName.")]
        string? nameContains,
        [Description("Maximum rows. Default 100.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT UserId, UserPrincipalName, UserDisplayName,
                   UserLicenseDisplayName, UserDateCreated, UserLastAccessedDate
            FROM Users
            WHERE (@name IS NULL
                   OR UserDisplayName   LIKE '%' + @name + '%'
                   OR UserPrincipalName LIKE '%' + @name + '%')
            ORDER BY UserDisplayName;
            """;
        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?> { ["name"] = nameContains },
            maxRows: maxRows ?? 100,
            ct: ct);
    }

    [McpServerTool, Description(
        "Lists pull requests with filters for project, repository, status and creator. " +
        "Sorted by PullRequestCreatedDate descending.")]
    public Task<string> ListPullRequests(
        [Description("Optional project name filter (TeamProjectName).")] string? projectName,
        [Description("Optional repository name filter (RepositoryName).")] string? repositoryName,
        [Description("Optional status filter (e.g. active, completed, abandoned).")] string? status,
        [Description("Optional creator filter (PullRequestCreatedBy substring).")] string? createdBy,
        [Description("Maximum rows. Default 100.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName, r.RepositoryName,
                   pr.PullRequestId, pr.PullRequestTitle,
                   pr.PullRequestBranchSource, pr.PullRequestBranchTarget,
                   pr.PullRequestCreatedBy, pr.PullRequestCreatedDate,
                   pr.PullRequestStatus, pr.PullRequestReviewers
            FROM RepositoriesPullRequests pr
            INNER JOIN Repositories r ON r.RepositoryId = pr.RepositoryId
            INNER JOIN Projects     p ON p.TeamProjectId = r.TeamProjectId
            WHERE (@project IS NULL OR p.TeamProjectName LIKE '%' + @project + '%')
              AND (@repo    IS NULL OR r.RepositoryName  LIKE '%' + @repo    + '%')
              AND (@status  IS NULL OR pr.PullRequestStatus = @status)
              AND (@creator IS NULL OR pr.PullRequestCreatedBy LIKE '%' + @creator + '%')
            ORDER BY pr.PullRequestCreatedDate DESC;
            """;

        var parameters = new Dictionary<string, object?>
        {
            ["project"] = projectName,
            ["repo"] = repositoryName,
            ["status"] = status,
            ["creator"] = createdBy
        };

        return executor.ExecuteJsonAsync(sql, parameters, maxRows ?? 100, ct);
    }

    [McpServerTool, Description(
        "Lists repositories and their branch protection settings. Optional project name filter.")]
    public Task<string> ListRepositories(
        [Description("Optional project name filter (TeamProjectName substring).")] string? projectName,
        [Description("Maximum rows. Default 200.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName, r.RepositoryId, r.RepositoryName,
                   r.RepositoryURL, r.RepositoryDefaultBranch,
                   r.RepositoryMinimumNumberOfReviewers,
                   r.RepositoryRequiredReviewers,
                   r.RepositoryWorkItemLinking,
                   r.RepositoryCommentRequirements,
                   r.RepositoryBranchBuild
            FROM Repositories r
            INNER JOIN Projects p ON p.TeamProjectId = r.TeamProjectId
            WHERE (@project IS NULL OR p.TeamProjectName LIKE '%' + @project + '%')
            ORDER BY p.TeamProjectName, r.RepositoryName;
            """;
        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?> { ["project"] = projectName },
            maxRows: maxRows ?? 200,
            ct: ct);
    }

    [McpServerTool, Description(
        "Top N most active projects by a chosen metric. Metric must be one of: WorkItemsCreated, " +
        "WorkItemsCompleted, CommitsPushed, PRsCreated, PRsCompleted, Builds, Releases.")]
    public Task<string> TopProjectsByActivity(
        [Description("Metric: WorkItemsCreated | WorkItemsCompleted | CommitsPushed | PRsCreated | PRsCompleted | Builds | Releases")]
        string metric,
        [Description("Number of rows to return. Default 10.")] int? top,
        CancellationToken ct)
    {
        var column = metric switch
        {
            "WorkItemsCreated"   => "TeamProjectCountWorkItemCreated",
            "WorkItemsCompleted" => "TeamProjectCountWorkItemCompleted",
            "CommitsPushed"      => "TeamProjectCountCommitsPushed",
            "PRsCreated"         => "TeamProjectCountPRsCreated",
            "PRsCompleted"       => "TeamProjectCountPRsCompleted",
            "Builds"             => "TeamProjectCountBuilds",
            "Releases"           => "TeamProjectCountReleases",
            _ => throw new ArgumentException(
                    $"Unknown metric '{metric}'. Allowed: WorkItemsCreated, WorkItemsCompleted, " +
                    "CommitsPushed, PRsCreated, PRsCompleted, Builds, Releases.",
                    nameof(metric))
        };

        var rows = Math.Clamp(top ?? 10, 1, 500);

        var sql = $"""
            SELECT TOP (@top)
                   TeamProjectName,
                   {column} AS Metric
            FROM Projects
            ORDER BY {column} DESC;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?> { ["top"] = rows },
            maxRows: rows,
            ct: ct);
    }

    [McpServerTool, Description(
        "Lists installed Azure DevOps extensions (id, publisher, version, last published date).")]
    public Task<string> ListInstalledExtensions(
        [Description("Maximum rows. Default 200.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT ExtensionId, ExtensionName, ExtensionPublisherName,
                   ExtensionVersion, ExtensionLastPublished
            FROM InstalledExtensions
            ORDER BY ExtensionPublisherName, ExtensionName;
            """;
        return executor.ExecuteJsonAsync(sql, maxRows: maxRows ?? 200, ct: ct);
    }

    [McpServerTool, Description(
        "Lists Personal Access Tokens by user, including scope and validity window. " +
        "Useful for security/expiration audits.")]
    public Task<string> ListPersonalAccessTokens(
        [Description("Optional user display-name substring filter.")] string? userContains,
        [Description("If true, returns only PATs whose PATValidTo is in the past.")] bool? expiredOnly,
        [Description("Maximum rows. Default 200.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT u.UserDisplayName, u.UserPrincipalName,
                   pat.PATDisplayName, pat.PATValidFrom, pat.PATValidTo, pat.PATScope
            FROM UsersPersonalAccessTokens pat
            INNER JOIN Users u ON u.UserId = pat.UserId
            WHERE (@user IS NULL OR u.UserDisplayName LIKE '%' + @user + '%')
              AND (@expired = 0 OR pat.PATValidTo < SYSUTCDATETIME())
            ORDER BY pat.PATValidTo ASC;
            """;
        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["user"] = userContains,
                ["expired"] = (expiredOnly ?? false) ? 1 : 0
            },
            maxRows: maxRows ?? 200,
            ct: ct);
    }
}
