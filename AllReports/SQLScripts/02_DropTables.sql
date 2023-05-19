IF OBJECT_ID('RepositoriesPullRequests', 'U') IS NOT NULL
    DROP TABLE RepositoriesPullRequests;
GO
IF OBJECT_ID('RepositoriesAheadBehind', 'U') IS NOT NULL
    DROP TABLE RepositoriesAheadBehind;
GO
IF OBJECT_ID('Repositories', 'U') IS NOT NULL
    DROP TABLE Repositories;
GO
IF OBJECT_ID('TeamsBoardColumns', 'U') IS NOT NULL
    DROP TABLE TeamsBoardColumns;
GO
IF OBJECT_ID('TeamsBoardLanes', 'U') IS NOT NULL
    DROP TABLE TeamsBoardLanes;
GO
IF OBJECT_ID('TeamsBackLogLevels', 'U') IS NOT NULL
    DROP TABLE TeamsBackLogLevels;
GO
IF OBJECT_ID('TeamsWorkingDays', 'U') IS NOT NULL
    DROP TABLE TeamsWorkingDays;
GO
IF OBJECT_ID('Teams', 'U') IS NOT NULL
    DROP TABLE Teams;
GO
IF OBJECT_ID('EnvironmentsApprovalsChecks', 'U') IS NOT NULL
    DROP TABLE EnvironmentsApprovalsChecks;
GO
IF OBJECT_ID('Projects', 'U') IS NOT NULL
    DROP TABLE Projects;
GO
IF OBJECT_ID('ProcessesWorkItemsFields', 'U') IS NOT NULL
    DROP TABLE ProcessesWorkItemsFields;
GO
IF OBJECT_ID('Processes', 'U') IS NOT NULL
    DROP TABLE Processes;
GO
IF OBJECT_ID('UsersPersonalAccessTokens', 'U') IS NOT NULL
    DROP TABLE UsersPersonalAccessTokens;
GO
IF OBJECT_ID('UsersGroups', 'U') IS NOT NULL
    DROP TABLE UsersGroups;
GO
IF OBJECT_ID('Users', 'U') IS NOT NULL
    DROP TABLE Users;
GO
IF OBJECT_ID('InstalledExtensions', 'U') IS NOT NULL
    DROP TABLE InstalledExtensions;
GO
IF OBJECT_ID('FeedPackageVersions', 'U') IS NOT NULL
    DROP TABLE FeedPackageVersions;
GO
