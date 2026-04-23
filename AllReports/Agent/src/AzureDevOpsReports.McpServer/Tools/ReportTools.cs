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
        "Lists process templates (Agile, Scrum, CMMI, custom inherited processes…) with aggregate " +
        "counts per template: number of projects using it, number of work item types customized, " +
        "and total number of work-item-type fields tracked.")]
    public Task<string> ListProcesses(
        [Description("Optional ProcessName substring filter.")] string? nameContains,
        [Description("Optional exact match on ProcessCustomizationType (e.g. 'system', 'inherited', 'custom').")]
        string? customizationType,
        [Description("Maximum rows. Default 100.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.ProcessTypeId,
                   p.ProcessName,
                   p.ProcessReferenceName,
                   p.ProcessCustomizationType,
                   (SELECT COUNT(*)
                      FROM Projects pr
                     WHERE pr.ProcessTypeId = p.ProcessTypeId)            AS ProjectCount,
                   (SELECT COUNT(DISTINCT ProcessWorkItemTypeName)
                      FROM ProcessesWorkItemsFields f
                     WHERE f.ProcessTypeId = p.ProcessTypeId)             AS WorkItemTypeCount,
                   (SELECT COUNT(*)
                      FROM ProcessesWorkItemsFields f
                     WHERE f.ProcessTypeId = p.ProcessTypeId)             AS FieldCount
            FROM Processes p
            WHERE (@name IS NULL OR p.ProcessName LIKE '%' + @name + '%')
              AND (@type IS NULL OR p.ProcessCustomizationType = @type)
            ORDER BY ProjectCount DESC, p.ProcessName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["name"] = nameContains,
                ["type"] = customizationType
            },
            maxRows: maxRows ?? 100,
            ct: ct);
    }

    [McpServerTool, Description(
        "Lists work item type fields across process templates (from ProcessesWorkItemsFields " +
        "joined with Processes). Filters by process name, work item type, field name, and an " +
        "optional exact-match on FieldCustomizationType. Useful for auditing custom fields.")]
    public Task<string> ListProcessFields(
        [Description("Optional ProcessName substring filter.")] string? processName,
        [Description("Optional work item type name substring (e.g. 'Bug', 'User Story').")] string? workItemType,
        [Description("Optional field name substring.")] string? fieldName,
        [Description("Optional exact match on ProcessWorkItemTypeFieldCustomizationType (e.g. 'custom', 'system', 'inherited').")]
        string? fieldCustomizationType,
        [Description("Maximum rows. Default 500.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.ProcessName,
                   f.ProcessWorkItemTypeName,
                   f.ProcessWorkItemTypeCustomationType,
                   f.ProcessWorkItemTypeFieldName,
                   f.ProcessWorkItemTypeFieldReferenceName,
                   f.ProcessWorkItemTypeFieldCustomizationType,
                   f.ProcessWorkItemTypeFieldTypeName
            FROM ProcessesWorkItemsFields f
            INNER JOIN Processes p ON p.ProcessTypeId = f.ProcessTypeId
            WHERE (@proc  IS NULL OR p.ProcessName                             LIKE '%' + @proc  + '%')
              AND (@wit   IS NULL OR f.ProcessWorkItemTypeName                 LIKE '%' + @wit   + '%')
              AND (@field IS NULL OR f.ProcessWorkItemTypeFieldName            LIKE '%' + @field + '%')
              AND (@fcust IS NULL OR f.ProcessWorkItemTypeFieldCustomizationType = @fcust)
            ORDER BY p.ProcessName,
                     f.ProcessWorkItemTypeName,
                     f.ProcessWorkItemTypeFieldName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proc"]  = processName,
                ["wit"]   = workItemType,
                ["field"] = fieldName,
                ["fcust"] = fieldCustomizationType
            },
            maxRows: maxRows ?? 500,
            ct: ct);
    }

    [McpServerTool, Description(
        "Impact analysis for a field: given a field name or reference name, returns every " +
        "(process template, work item type, field) combination where it appears, plus the count " +
        "of projects inheriting that template and a sample of up to 20 project names. Answers " +
        "the common audit question: 'field X is used in which work items, process templates and " +
        "projects?'. Fuzzy LIKE match on both FieldName and FieldReferenceName.")]
    public Task<string> FindFieldUsage(
        [Description("Field name or reference name substring (e.g. 'Severity', 'Custom.Team').")]
        string fieldNameOrReference,
        [Description("Optional ProcessName substring filter.")] string? processName,
        [Description("Optional work item type name substring (e.g. 'Bug', 'User Story').")] string? workItemType,
        [Description("Maximum rows. Default 500.")] int? maxRows,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(fieldNameOrReference))
            throw new ArgumentException(
                "fieldNameOrReference is required and cannot be empty.",
                nameof(fieldNameOrReference));

        const string sql = """
            WITH Matched AS (
                SELECT p.ProcessTypeId,
                       p.ProcessName,
                       p.ProcessCustomizationType,
                       f.ProcessWorkItemTypeName                   AS WorkItemType,
                       f.ProcessWorkItemTypeCustomationType        AS WorkItemTypeCustomization,
                       f.ProcessWorkItemTypeFieldName              AS FieldName,
                       f.ProcessWorkItemTypeFieldReferenceName     AS FieldReferenceName,
                       f.ProcessWorkItemTypeFieldTypeName          AS FieldType,
                       f.ProcessWorkItemTypeFieldCustomizationType AS FieldCustomizationType
                FROM ProcessesWorkItemsFields f
                INNER JOIN Processes p ON p.ProcessTypeId = f.ProcessTypeId
                WHERE (f.ProcessWorkItemTypeFieldName          LIKE '%' + @field + '%'
                    OR f.ProcessWorkItemTypeFieldReferenceName LIKE '%' + @field + '%')
                  AND (@proc IS NULL OR p.ProcessName              LIKE '%' + @proc + '%')
                  AND (@wit  IS NULL OR f.ProcessWorkItemTypeName  LIKE '%' + @wit  + '%')
            )
            SELECT m.ProcessName,
                   m.ProcessCustomizationType,
                   m.WorkItemType,
                   m.WorkItemTypeCustomization,
                   m.FieldName,
                   m.FieldReferenceName,
                   m.FieldType,
                   m.FieldCustomizationType,
                   pc.ProjectCount,
                   ps.SampleProjects
            FROM Matched m
            CROSS APPLY (
                SELECT COUNT(*) AS ProjectCount
                FROM Projects pr
                WHERE pr.ProcessTypeId = m.ProcessTypeId
            ) pc
            OUTER APPLY (
                SELECT STRING_AGG(TeamProjectName, ', ')
                    WITHIN GROUP (ORDER BY TeamProjectName) AS SampleProjects
                FROM (
                    SELECT TOP (20) TeamProjectName
                    FROM Projects
                    WHERE ProcessTypeId = m.ProcessTypeId
                    ORDER BY TeamProjectName
                ) s
            ) ps
            ORDER BY m.ProcessName, m.WorkItemType, m.FieldName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["field"] = fieldNameOrReference,
                ["proc"]  = processName,
                ["wit"]   = workItemType
            },
            maxRows: maxRows ?? 500,
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
        "Audit-oriented list of user-to-group memberships. Joins Users with UsersGroups. " +
        "Supports filtering by user (display name or principal name substring) and/or group " +
        "name substring. Answers questions like 'who is in group X?' or 'what groups does user Y " +
        "belong to?'. Results ordered by GroupName, then UserDisplayName.")]
    public Task<string> ListUserGroupMemberships(
        [Description("Optional substring to filter UserDisplayName or UserPrincipalName.")] string? userContains,
        [Description("Optional substring to filter GroupName (e.g. 'Admin', 'Contributors').")] string? groupContains,
        [Description("Maximum rows. Default 500.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT u.UserDisplayName,
                   u.UserPrincipalName,
                   u.UserLicenseDisplayName,
                   ug.GroupName
            FROM UsersGroups ug
            INNER JOIN Users u ON u.UserId = ug.UserId
            WHERE (@user IS NULL
                    OR u.UserDisplayName   LIKE '%' + @user + '%'
                    OR u.UserPrincipalName LIKE '%' + @user + '%')
              AND (@grp  IS NULL OR ug.GroupName LIKE '%' + @grp + '%')
            ORDER BY ug.GroupName, u.UserDisplayName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["user"] = userContains,
                ["grp"]  = groupContains
            },
            maxRows: maxRows ?? 500,
            ct: ct);
    }

    [McpServerTool, Description(
        "Aggregated group membership summary: one row per group with member count and up to 5 " +
        "sample member display names (comma-separated). Ordered by MemberCount DESC. " +
        "Great for high-level permissioning audits ('which groups have the most users?').")]
    public Task<string> GroupMembershipSummary(
        [Description("Optional substring filter on GroupName.")] string? groupContains,
        [Description("Maximum rows. Default 200.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            WITH Ranked AS (
                SELECT ug.GroupName,
                       u.UserDisplayName,
                       ROW_NUMBER() OVER (PARTITION BY ug.GroupName ORDER BY u.UserDisplayName) AS rn
                FROM UsersGroups ug
                INNER JOIN Users u ON u.UserId = ug.UserId
                WHERE (@grp IS NULL OR ug.GroupName LIKE '%' + @grp + '%')
            )
            SELECT GroupName,
                   COUNT(*) AS MemberCount,
                   STRING_AGG(CASE WHEN rn <= 5 THEN UserDisplayName END, ', ')
                       WITHIN GROUP (ORDER BY UserDisplayName) AS SampleMembers
            FROM Ranked
            GROUP BY GroupName
            ORDER BY MemberCount DESC, GroupName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?> { ["grp"] = groupContains },
            maxRows: maxRows ?? 200,
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
        "Per-team configuration overview: one row per team with project, TeamWorkingWithBugs flag " +
        "and aggregate counts of working days, backlog levels, board columns and board lanes. " +
        "Useful to spot teams with missing/empty configuration (any count = 0).")]
    public Task<string> ListTeams(
        [Description("Optional project name substring filter.")] string? projectName,
        [Description("Optional team name substring filter.")] string? teamName,
        [Description("Maximum rows. Default 500.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName,
                   t.TeamId,
                   t.TeamName,
                   t.TeamWorkingWithBugs,
                   (SELECT COUNT(*) FROM TeamsWorkingDays   w WHERE w.TeamId = t.TeamId) AS WorkingDaysCount,
                   (SELECT COUNT(*) FROM TeamsBackLogLevels b WHERE b.TeamId = t.TeamId) AS BacklogLevelsCount,
                   (SELECT COUNT(*) FROM TeamsBoardColumns  c WHERE c.TeamId = t.TeamId) AS BoardColumnsCount,
                   (SELECT COUNT(*) FROM TeamsBoardLanes    l WHERE l.TeamId = t.TeamId) AS BoardLanesCount
            FROM Teams t
            INNER JOIN Projects p ON p.TeamProjectId = t.TeamProjectId
            WHERE (@proj IS NULL OR p.TeamProjectName LIKE '%' + @proj + '%')
              AND (@team IS NULL OR t.TeamName        LIKE '%' + @team + '%')
            ORDER BY p.TeamProjectName, t.TeamName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proj"] = projectName,
                ["team"] = teamName
            },
            maxRows: maxRows ?? 500,
            ct: ct);
    }

    [McpServerTool, Description(
        "Raw list of configured working days per team (TeamsWorkingDays joined with Teams and " +
        "Projects). Supports project/team filters. Useful to compare calendar assumptions across " +
        "squads.")]
    public Task<string> ListTeamWorkingDays(
        [Description("Optional project name substring filter.")] string? projectName,
        [Description("Optional team name substring filter.")] string? teamName,
        [Description("Maximum rows. Default 1000.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName, t.TeamName, wd.TeamWorkingDay
            FROM TeamsWorkingDays wd
            INNER JOIN Teams    t ON t.TeamId        = wd.TeamId
            INNER JOIN Projects p ON p.TeamProjectId = t.TeamProjectId
            WHERE (@proj IS NULL OR p.TeamProjectName LIKE '%' + @proj + '%')
              AND (@team IS NULL OR t.TeamName        LIKE '%' + @team + '%')
            ORDER BY p.TeamProjectName, t.TeamName, wd.TeamWorkingDay;
            """;
        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proj"] = projectName,
                ["team"] = teamName
            },
            maxRows: maxRows ?? 1000,
            ct: ct);
    }

    [McpServerTool, Description(
        "Raw list of backlog levels (Epics, Features, Stories, …) configured per team. Surfaces " +
        "squads that opted in/out of specific hierarchy levels.")]
    public Task<string> ListTeamBacklogLevels(
        [Description("Optional project name substring filter.")] string? projectName,
        [Description("Optional team name substring filter.")] string? teamName,
        [Description("Maximum rows. Default 1000.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName, t.TeamName, b.TeamBackLogLevel
            FROM TeamsBackLogLevels b
            INNER JOIN Teams    t ON t.TeamId        = b.TeamId
            INNER JOIN Projects p ON p.TeamProjectId = t.TeamProjectId
            WHERE (@proj IS NULL OR p.TeamProjectName LIKE '%' + @proj + '%')
              AND (@team IS NULL OR t.TeamName        LIKE '%' + @team + '%')
            ORDER BY p.TeamProjectName, t.TeamName, b.TeamBackLogLevel;
            """;
        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proj"] = projectName,
                ["team"] = teamName
            },
            maxRows: maxRows ?? 1000,
            ct: ct);
    }

    [McpServerTool, Description(
        "Kanban board columns per team and backlog level, including WIT/state mappings and split " +
        "flag (doing/done). Essential to diagnose WIP misconfiguration and state-mapping drift " +
        "across squads.")]
    public Task<string> ListTeamBoardColumns(
        [Description("Optional project name substring filter.")] string? projectName,
        [Description("Optional team name substring filter.")] string? teamName,
        [Description("Optional exact backlog level (e.g. 'Stories', 'Features', 'Epics').")] string? backlogLevel,
        [Description("Maximum rows. Default 2000.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName,
                   t.TeamName,
                   c.TeamBackLogLevel,
                   c.BoardColumnOrder,
                   c.BoardColumnName,
                   c.BoardColumnStateMappingsWorkItemType,
                   c.BoardColumnStateMappingsState,
                   c.BoardColumnIsSplit
            FROM TeamsBoardColumns c
            INNER JOIN Teams    t ON t.TeamId        = c.TeamId
            INNER JOIN Projects p ON p.TeamProjectId = t.TeamProjectId
            WHERE (@proj  IS NULL OR p.TeamProjectName LIKE '%' + @proj + '%')
              AND (@team  IS NULL OR t.TeamName        LIKE '%' + @team + '%')
              AND (@level IS NULL OR c.TeamBackLogLevel = @level)
            ORDER BY p.TeamProjectName, t.TeamName, c.TeamBackLogLevel, c.BoardColumnOrder;
            """;
        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proj"]  = projectName,
                ["team"]  = teamName,
                ["level"] = backlogLevel
            },
            maxRows: maxRows ?? 2000,
            ct: ct);
    }

    [McpServerTool, Description(
        "Swimlanes (board lanes) per team and backlog level. Reveals teams using custom lanes " +
        "for expedite/bugs/tech-debt vs. teams with the default single-lane setup.")]
    public Task<string> ListTeamBoardLanes(
        [Description("Optional project name substring filter.")] string? projectName,
        [Description("Optional team name substring filter.")] string? teamName,
        [Description("Optional exact backlog level (e.g. 'Stories', 'Features').")] string? backlogLevel,
        [Description("Maximum rows. Default 1000.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName,
                   t.TeamName,
                   l.TeamBackLogLevel,
                   l.BoardLaneOrder,
                   l.BoardLaneName
            FROM TeamsBoardLanes l
            INNER JOIN Teams    t ON t.TeamId        = l.TeamId
            INNER JOIN Projects p ON p.TeamProjectId = t.TeamProjectId
            WHERE (@proj  IS NULL OR p.TeamProjectName LIKE '%' + @proj + '%')
              AND (@team  IS NULL OR t.TeamName        LIKE '%' + @team + '%')
              AND (@level IS NULL OR l.TeamBackLogLevel = @level)
            ORDER BY p.TeamProjectName, t.TeamName, l.TeamBackLogLevel, l.BoardLaneOrder;
            """;
        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proj"]  = projectName,
                ["team"]  = teamName,
                ["level"] = backlogLevel
            },
            maxRows: maxRows ?? 1000,
            ct: ct);
    }

    [McpServerTool, Description(
        "Side-by-side pivot of every team inside a single project, aggregating working days, " +
        "backlog levels, columns-per-level and lanes-per-level into comma-separated strings. " +
        "Ideal to visually compare squads in a project and spot drift ('why does team A have 7 " +
        "columns on Stories but team B has 4?').")]
    public Task<string> CompareTeamsInProject(
        [Description("Project name substring (required).")] string projectName,
        [Description("Maximum rows. Default 200.")] int? maxRows,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(projectName))
            throw new ArgumentException("projectName is required.", nameof(projectName));

        const string sql = """
            WITH T AS (
                SELECT t.TeamId, t.TeamName, t.TeamWorkingWithBugs, p.TeamProjectName
                FROM Teams t
                INNER JOIN Projects p ON p.TeamProjectId = t.TeamProjectId
                WHERE p.TeamProjectName LIKE '%' + @proj + '%'
            )
            SELECT T.TeamProjectName,
                   T.TeamName,
                   T.TeamWorkingWithBugs,
                   (SELECT STRING_AGG(TeamWorkingDay, ', ')
                           WITHIN GROUP (ORDER BY TeamWorkingDay)
                    FROM TeamsWorkingDays WHERE TeamId = T.TeamId) AS WorkingDays,
                   (SELECT STRING_AGG(TeamBackLogLevel, ', ')
                           WITHIN GROUP (ORDER BY TeamBackLogLevel)
                    FROM TeamsBackLogLevels WHERE TeamId = T.TeamId) AS BacklogLevels,
                   (SELECT STRING_AGG(CONCAT(TeamBackLogLevel, ':', CAST(cnt AS VARCHAR(10))), ', ')
                           WITHIN GROUP (ORDER BY TeamBackLogLevel)
                    FROM (SELECT TeamBackLogLevel, COUNT(*) AS cnt
                          FROM TeamsBoardColumns
                          WHERE TeamId = T.TeamId
                          GROUP BY TeamBackLogLevel) cc) AS ColumnsPerLevel,
                   (SELECT STRING_AGG(CONCAT(TeamBackLogLevel, ':', CAST(cnt AS VARCHAR(10))), ', ')
                           WITHIN GROUP (ORDER BY TeamBackLogLevel)
                    FROM (SELECT TeamBackLogLevel, COUNT(*) AS cnt
                          FROM TeamsBoardLanes
                          WHERE TeamId = T.TeamId
                          GROUP BY TeamBackLogLevel) ll) AS LanesPerLevel
            FROM T
            ORDER BY T.TeamName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?> { ["proj"] = projectName },
            maxRows: maxRows ?? 200,
            ct: ct);
    }

    [McpServerTool, Description(
        "Flags teams whose configuration diverges from the 'majority' (mode) inside their own " +
        "project. Returns only deviating rows. Checked dimensions: working days, backlog levels, " +
        "total board columns, total board lanes, TeamWorkingWithBugs. Each row shows the team's " +
        "value next to the project's most common value — quick way to catch standardization gaps.")]
    public Task<string> DetectTeamConfigurationAnomalies(
        [Description("Optional project name substring filter. If null, scans all projects.")] string? projectName,
        [Description("Maximum rows. Default 500.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            WITH TeamConfigs AS (
                SELECT t.TeamProjectId,
                       p.TeamProjectName,
                       t.TeamId,
                       t.TeamName,
                       t.TeamWorkingWithBugs,
                       ISNULL((SELECT STRING_AGG(TeamWorkingDay, ',')
                                       WITHIN GROUP (ORDER BY TeamWorkingDay)
                               FROM TeamsWorkingDays WHERE TeamId = t.TeamId), '') AS WorkingDays,
                       ISNULL((SELECT STRING_AGG(TeamBackLogLevel, ',')
                                       WITHIN GROUP (ORDER BY TeamBackLogLevel)
                               FROM TeamsBackLogLevels WHERE TeamId = t.TeamId), '') AS BacklogLevels,
                       (SELECT COUNT(*) FROM TeamsBoardColumns WHERE TeamId = t.TeamId) AS TotalColumns,
                       (SELECT COUNT(*) FROM TeamsBoardLanes   WHERE TeamId = t.TeamId) AS TotalLanes
                FROM Teams t
                INNER JOIN Projects p ON p.TeamProjectId = t.TeamProjectId
                WHERE (@proj IS NULL OR p.TeamProjectName LIKE '%' + @proj + '%')
            ),
            Projs AS (SELECT DISTINCT TeamProjectId FROM TeamConfigs),
            Modes AS (
                SELECT pr.TeamProjectId,
                       (SELECT TOP 1 WorkingDays
                        FROM TeamConfigs tc
                        WHERE tc.TeamProjectId = pr.TeamProjectId
                        GROUP BY WorkingDays
                        ORDER BY COUNT(*) DESC, MIN(TeamName))           AS ModeWorkingDays,
                       (SELECT TOP 1 BacklogLevels
                        FROM TeamConfigs tc
                        WHERE tc.TeamProjectId = pr.TeamProjectId
                        GROUP BY BacklogLevels
                        ORDER BY COUNT(*) DESC, MIN(TeamName))           AS ModeBacklogLevels,
                       (SELECT TOP 1 TotalColumns
                        FROM TeamConfigs tc
                        WHERE tc.TeamProjectId = pr.TeamProjectId
                        GROUP BY TotalColumns
                        ORDER BY COUNT(*) DESC, MIN(TeamName))           AS ModeTotalColumns,
                       (SELECT TOP 1 TotalLanes
                        FROM TeamConfigs tc
                        WHERE tc.TeamProjectId = pr.TeamProjectId
                        GROUP BY TotalLanes
                        ORDER BY COUNT(*) DESC, MIN(TeamName))           AS ModeTotalLanes,
                       (SELECT TOP 1 TeamWorkingWithBugs
                        FROM TeamConfigs tc
                        WHERE tc.TeamProjectId = pr.TeamProjectId
                        GROUP BY TeamWorkingWithBugs
                        ORDER BY COUNT(*) DESC, MIN(TeamName))           AS ModeBugsSetting
                FROM Projs pr
            )
            SELECT tc.TeamProjectName,
                   tc.TeamName,
                   CASE WHEN tc.WorkingDays        <> m.ModeWorkingDays     THEN 1 ELSE 0 END AS WorkingDaysDeviates,
                   CASE WHEN tc.BacklogLevels      <> m.ModeBacklogLevels   THEN 1 ELSE 0 END AS BacklogLevelsDeviates,
                   CASE WHEN tc.TotalColumns       <> m.ModeTotalColumns    THEN 1 ELSE 0 END AS ColumnsCountDeviates,
                   CASE WHEN tc.TotalLanes         <> m.ModeTotalLanes      THEN 1 ELSE 0 END AS LanesCountDeviates,
                   CASE WHEN ISNULL(tc.TeamWorkingWithBugs,'') <> ISNULL(m.ModeBugsSetting,'')
                        THEN 1 ELSE 0 END AS BugsSettingDeviates,
                   tc.WorkingDays,         m.ModeWorkingDays     AS ProjectCommonWorkingDays,
                   tc.BacklogLevels,       m.ModeBacklogLevels   AS ProjectCommonBacklogLevels,
                   tc.TotalColumns,        m.ModeTotalColumns    AS ProjectCommonTotalColumns,
                   tc.TotalLanes,          m.ModeTotalLanes      AS ProjectCommonTotalLanes,
                   tc.TeamWorkingWithBugs, m.ModeBugsSetting     AS ProjectCommonBugsSetting
            FROM TeamConfigs tc
            INNER JOIN Modes m ON m.TeamProjectId = tc.TeamProjectId
            WHERE tc.WorkingDays      <> m.ModeWorkingDays
               OR tc.BacklogLevels    <> m.ModeBacklogLevels
               OR tc.TotalColumns     <> m.ModeTotalColumns
               OR tc.TotalLanes       <> m.ModeTotalLanes
               OR ISNULL(tc.TeamWorkingWithBugs,'') <> ISNULL(m.ModeBugsSetting,'')
            ORDER BY tc.TeamProjectName, tc.TeamName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?> { ["proj"] = projectName },
            maxRows: maxRows ?? 500,
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
        "Lists rows from the FeedPackageVersions table (Azure Artifacts feeds). " +
        "Supports filters for feed name, package name, package type (nuget/npm/maven/pypi/…), " +
        "source (local/upstream) and an optional flag to return only the latest version of each " +
        "package. Sortable by Downloads (default), UniqueUsers, Date or Version.")]
    public Task<string> ListFeedPackageVersions(
        [Description("Optional FeedName substring filter.")] string? feedNameContains,
        [Description("Optional FeedPackageName substring filter.")] string? packageNameContains,
        [Description("Optional exact match for FeedPackageType (e.g. nuget, npm, maven, pypi).")] string? packageType,
        [Description("Optional exact match for FeedPackageSource (e.g. local, upstream).")] string? packageSource,
        [Description("If true, returns only rows where FeedPackageVersionLatest = 1.")] bool? latestOnly,
        [Description("Sort key: Downloads (default) | UniqueUsers | Date | Version.")] string? orderBy,
        [Description("Maximum rows. Default 100.")] int? maxRows,
        CancellationToken ct)
    {
        var order = (orderBy ?? "Downloads").Trim().ToLowerInvariant() switch
        {
            "downloads"   => "FeedPackageVersionDownloadCount DESC",
            "uniqueusers" => "FeedPackageVersionDownloadUniqueUsers DESC",
            "date"        => "FeedPackageVersionDate DESC",
            "version"     => "FeedName, FeedPackageName, FeedPackageVersionDate DESC",
            _ => throw new ArgumentException(
                    $"Unknown orderBy '{orderBy}'. Allowed: Downloads, UniqueUsers, Date, Version.",
                    nameof(orderBy))
        };

        var sql = $"""
            SELECT FeedId, FeedName, FeedPackageName, FeedPackageType, FeedPackageSource,
                   FeedPackageVersion, FeedPackageVersionLatest, FeedPackageVersionDate,
                   FeedPackageVersionDownloadCount, FeedPackageVersionDownloadUniqueUsers
            FROM FeedPackageVersions
            WHERE (@feed   IS NULL OR FeedName        LIKE '%' + @feed + '%')
              AND (@pkg    IS NULL OR FeedPackageName LIKE '%' + @pkg  + '%')
              AND (@type   IS NULL OR FeedPackageType   = @type)
              AND (@source IS NULL OR FeedPackageSource = @source)
              AND (@latest = 0     OR FeedPackageVersionLatest = 1)
            ORDER BY {order};
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["feed"]   = feedNameContains,
                ["pkg"]    = packageNameContains,
                ["type"]   = packageType,
                ["source"] = packageSource,
                ["latest"] = (latestOnly ?? false) ? 1 : 0
            },
            maxRows: maxRows ?? 100,
            ct: ct);
    }

    [McpServerTool, Description(
        "Top N most downloaded packages across all feeds (aggregated across versions). " +
        "Useful to identify the most-consumed artifacts.")]
    public Task<string> TopFeedPackagesByDownloads(
        [Description("Optional FeedPackageType filter (e.g. nuget, npm).")] string? packageType,
        [Description("Number of rows to return. Default 10.")] int? top,
        CancellationToken ct)
    {
        var rows = Math.Clamp(top ?? 10, 1, 500);

        const string sql = """
            SELECT TOP (@top)
                   FeedName,
                   FeedPackageName,
                   FeedPackageType,
                   SUM(FeedPackageVersionDownloadCount)       AS TotalDownloads,
                   SUM(FeedPackageVersionDownloadUniqueUsers) AS TotalUniqueUsers,
                   COUNT(*)                                   AS VersionCount
            FROM FeedPackageVersions
            WHERE (@type IS NULL OR FeedPackageType = @type)
            GROUP BY FeedName, FeedPackageName, FeedPackageType
            ORDER BY TotalDownloads DESC;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["top"] = rows,
                ["type"] = packageType
            },
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

    [McpServerTool, Description(
        "Lists repository branches with their ahead/behind counts relative to the default branch " +
        "(from RepositoriesAheadBehind). Ideal for spotting stale branches (high BehindCount), " +
        "long-running feature branches, or branches with work ready to merge (high AheadCount). " +
        "Filter by project/repository/branch and minimum thresholds; sort by Behind (default), " +
        "Ahead or Branch.")]
    public Task<string> ListBranchesAheadBehind(
        [Description("Optional project name substring filter.")] string? projectName,
        [Description("Optional repository name substring filter.")] string? repositoryName,
        [Description("Optional branch name substring filter.")] string? branchNameContains,
        [Description("Minimum BehindCount filter (inclusive). Null means no filter.")] int? minBehindCount,
        [Description("Minimum AheadCount filter (inclusive). Null means no filter.")] int? minAheadCount,
        [Description("If true, includes only base-version rows; if false, excludes them. Null = no filter.")]
        bool? baseVersionOnly,
        [Description("Sort key: Behind (default) | Ahead | Branch.")] string? orderBy,
        [Description("Maximum rows. Default 200.")] int? maxRows,
        CancellationToken ct)
    {
        var order = (orderBy ?? "Behind").Trim().ToLowerInvariant() switch
        {
            "behind" => "ab.RepositoryBranchBehindCount DESC",
            "ahead"  => "ab.RepositoryBranchAheadCount DESC",
            "branch" => "p.TeamProjectName, r.RepositoryName, ab.RepositoryBranchName",
            _ => throw new ArgumentException(
                    $"Unknown orderBy '{orderBy}'. Allowed: Behind, Ahead, Branch.",
                    nameof(orderBy))
        };

        var sql = $"""
            SELECT p.TeamProjectName,
                   r.RepositoryName,
                   r.RepositoryDefaultBranch,
                   ab.RepositoryBranchName,
                   ab.RepositoryBranchAheadCount,
                   ab.RepositoryBranchBehindCount,
                   ab.RepositoryBranchIsBaseVersion
            FROM RepositoriesAheadBehind ab
            INNER JOIN Repositories r ON r.RepositoryId   = ab.RepositoryId
            INNER JOIN Projects     p ON p.TeamProjectId  = r.TeamProjectId
            WHERE (@proj     IS NULL OR p.TeamProjectName      LIKE '%' + @proj + '%')
              AND (@repo     IS NULL OR r.RepositoryName       LIKE '%' + @repo + '%')
              AND (@branch   IS NULL OR ab.RepositoryBranchName LIKE '%' + @branch + '%')
              AND (@minBehind IS NULL OR ab.RepositoryBranchBehindCount >= @minBehind)
              AND (@minAhead  IS NULL OR ab.RepositoryBranchAheadCount  >= @minAhead)
              AND (@baseOnly IS NULL
                    OR (@baseOnly = 1 AND ab.RepositoryBranchIsBaseVersion = 1)
                    OR (@baseOnly = 0 AND ab.RepositoryBranchIsBaseVersion = 0))
            ORDER BY {order};
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proj"]      = projectName,
                ["repo"]      = repositoryName,
                ["branch"]    = branchNameContains,
                ["minBehind"] = minBehindCount,
                ["minAhead"]  = minAheadCount,
                ["baseOnly"]  = baseVersionOnly is null ? null : (object)(baseVersionOnly.Value ? 1 : 0)
            },
            maxRows: maxRows ?? 200,
            ct: ct);
    }

    [McpServerTool, Description(
        "Lists environment approval & check rules per project (from EnvironmentsApprovalsChecks). " +
        "Useful to audit deployment gates: which environments have which checks configured. " +
        "Supports substring filters on project, environment and check.")]
    public Task<string> ListEnvironmentApprovalChecks(
        [Description("Optional project name substring filter.")] string? projectName,
        [Description("Optional environment name substring filter.")] string? environmentName,
        [Description("Optional check name / display-name substring filter.")] string? checkContains,
        [Description("Maximum rows. Default 500.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName,
                   e.EnvironmentId,
                   e.EnvironmentName,
                   e.EnvironmentCheckName,
                   e.EnvironmentCheckDisplayName
            FROM EnvironmentsApprovalsChecks e
            INNER JOIN Projects p ON p.TeamProjectId = e.TeamProjectId
            WHERE (@proj  IS NULL OR p.TeamProjectName          LIKE '%' + @proj  + '%')
              AND (@env   IS NULL OR e.EnvironmentName          LIKE '%' + @env   + '%')
              AND (@check IS NULL OR e.EnvironmentCheckName        LIKE '%' + @check + '%'
                                  OR e.EnvironmentCheckDisplayName LIKE '%' + @check + '%')
            ORDER BY p.TeamProjectName, e.EnvironmentName, e.EnvironmentCheckDisplayName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proj"]  = projectName,
                ["env"]   = environmentName,
                ["check"] = checkContains
            },
            maxRows: maxRows ?? 500,
            ct: ct);
    }

    [McpServerTool, Description(
        "Aggregated environment gate coverage: one row per environment with CheckCount and a " +
        "comma-separated list of configured check names. Ordered by CheckCount ASC so environments " +
        "with the fewest (or zero) gates surface first — quick way to spot under-protected " +
        "production environments.")]
    public Task<string> EnvironmentApprovalCoverageSummary(
        [Description("Optional project name substring filter.")] string? projectName,
        [Description("Optional environment name substring filter.")] string? environmentName,
        [Description("Maximum rows. Default 500.")] int? maxRows,
        CancellationToken ct)
    {
        const string sql = """
            SELECT p.TeamProjectName,
                   e.EnvironmentId,
                   e.EnvironmentName,
                   COUNT(*) AS CheckCount,
                   STRING_AGG(e.EnvironmentCheckDisplayName, ', ')
                       WITHIN GROUP (ORDER BY e.EnvironmentCheckDisplayName) AS Checks
            FROM EnvironmentsApprovalsChecks e
            INNER JOIN Projects p ON p.TeamProjectId = e.TeamProjectId
            WHERE (@proj IS NULL OR p.TeamProjectName LIKE '%' + @proj + '%')
              AND (@env  IS NULL OR e.EnvironmentName LIKE '%' + @env  + '%')
            GROUP BY p.TeamProjectName, e.EnvironmentId, e.EnvironmentName
            ORDER BY CheckCount ASC, p.TeamProjectName, e.EnvironmentName;
            """;

        return executor.ExecuteJsonAsync(
            sql,
            parameters: new Dictionary<string, object?>
            {
                ["proj"] = projectName,
                ["env"]  = environmentName
            },
            maxRows: maxRows ?? 500,
            ct: ct);
    }
}
