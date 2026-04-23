namespace AzureDevOpsReports.McpServer.Tools;

public static class SchemaReference
{
    public const string Summary = """
        Azure DevOps Management Reports database (azuredevopsreports).

        Tables:
          - FeedPackageVersions (FeedId, FeedName, FeedDescription, FeedPackageName,
            FeedPackageType, FeedPackageSource, FeedPackageVersion,
            FeedPackageVersionLatest, FeedPackageVersionDate,
            FeedPackageVersionDownloadCount, FeedPackageVersionDownloadUniqueUsers)
          - InstalledExtensions (ExtensionId, ExtensionName, ExtensionPublisherName,
            ExtensionVersion, ExtensionLastPublished)
          - Users (UserId PK, UserPrincipalName, UserDisplayName, UserPictureLink,
            UserDateCreated, UserLastAccessedDate, UserLicenseDisplayName)
          - UsersGroups (UserId FK, GroupName)
          - UsersPersonalAccessTokens (UserId FK, PATDisplayName,
            PATValidFrom, PATValidTo, PATScope)
          - Processes (ProcessTypeId PK, ProcessName, ProcessReferenceName,
            ProcessCustomizationType)
          - ProcessesWorkItemsFields (ProcessTypeId FK, ProcessWorkItemTypeName,
            ProcessWorkItemTypeCustomationType, ProcessWorkItemTypeFieldName,
            ProcessWorkItemTypeFieldReferenceName,
            ProcessWorkItemTypeFieldCustomizationType,
            ProcessWorkItemTypeFieldTypeName)
          - Projects (TeamProjectId PK, TeamProjectName, ProcessTypeId FK,
            TeamProjectCountWorkItemCreated, TeamProjectCountWorkItemCompleted,
            TeamProjectCountCommitsPushed, TeamProjectCountPRsCreated,
            TeamProjectCountPRsCompleted, TeamProjectCountBuilds,
            TeamProjectCountReleases)
          - Teams (TeamProjectId FK, TeamId PK, TeamName, TeamWorkingWithBugs)
          - TeamsWorkingDays (TeamId FK, TeamWorkingDay)
          - TeamsBackLogLevels (TeamId FK, TeamBackLogLevel; PK TeamId+TeamBackLogLevel)
          - TeamsBoardColumns (TeamId FK, TeamBackLogLevel FK, BoardColumnOrder,
            BoardColumnName, BoardColumnStateMappingsWorkItemType,
            BoardColumnStateMappingsState, BoardColumnIsSplit)
          - TeamsBoardLanes (TeamId FK, TeamBackLogLevel FK,
            BoardLaneOrder, BoardLaneName)
          - EnvironmentsApprovalsChecks (TeamProjectId FK, EnvironmentId,
            EnvironmentName, EnvironmentCheckName, EnvironmentCheckDisplayName)
          - Repositories (TeamProjectId FK, RepositoryId PK, RepositoryName,
            RepositoryURL, RepositoryDefaultBranch,
            RepositoryMinimumNumberOfReviewers, RepositoryRequiredReviewers,
            RepositoryWorkItemLinking, RepositoryCommentRequirements,
            RepositoryBranchBuild)
          - RepositoriesAheadBehind (RepositoryId FK, RepositoryBranchName,
            RepositoryBranchAheadCount, RepositoryBranchBehindCount,
            RepositoryBranchIsBaseVersion)
          - RepositoriesPullRequests (RepositoryId FK, PullRequestId,
            PullRequestTitle, PullRequestBranchSource, PullRequestBranchTarget,
            PullRequestCreatedBy, PullRequestCreatedDate, PullRequestStatus,
            PullRequestReviewers)

        Relationships:
          Projects.ProcessTypeId -> Processes.ProcessTypeId
          Teams.TeamProjectId    -> Projects.TeamProjectId
          Repositories.TeamProjectId -> Projects.TeamProjectId
          RepositoriesPullRequests.RepositoryId -> Repositories.RepositoryId
          UsersGroups.UserId    -> Users.UserId
        """;
}
