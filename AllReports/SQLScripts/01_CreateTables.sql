CREATE TABLE [dbo].[FeedPackageVersions](
	FeedId									VARCHAR(40) NOT NULL,
	FeedName								VARCHAR(100) NOT NULL,
	FeedDescription							NVARCHAR(MAX) NOT NULL,
	FeedPackageName							VARCHAR(100) NOT NULL,
	FeedPackageType							VARCHAR(30) NOT NULL,
	FeedPackageSource						VARCHAR(30) NOT NULL,
	FeedPackageVersion						VARCHAR(50) NOT NULL,
	FeedPackageVersionLatest				BIT NOT NULL,
	FeedPackageVersionDate					DATETIME NOT NULL,
	FeedPackageVersionDownloadCount			INT NOT NULL,
	FeedPackageVersionDownloadUniqueUsers	INT NOT NULL
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[InstalledExtensions](
	ExtensionId					VARCHAR(100) NOT NULL,
	ExtensionName				VARCHAR(100) NOT NULL,
	ExtensionPublisherName		VARCHAR(100) NOT NULL,
	ExtensionVersion			VARCHAR(40) NOT NULL,
	ExtensionLastPublished		DATETIME NOT NULL
)
GO

CREATE TABLE [dbo].[Users]
(
	UserId						VARCHAR(40) NOT NULL,
	UserPrincipalName			VARCHAR(100) NOT NULL,
	UserDisplayName				VARCHAR(100) NOT NULL,
	UserPictureLink				NVARCHAR(MAX) NOT NULL,
	UserDateCreated				DATETIME NOT NULL,
	UserLastAccessedDate		DATETIME NOT NULL,
	UserLicenseDisplayName		VARCHAR(100) NOT NULL,
	CONSTRAINT [PK_Users] 		PRIMARY KEY CLUSTERED
(
	UserId ASC
) ON [PRIMARY]
)

GO

CREATE TABLE [dbo].[UsersGroups]
(
	UserId						VARCHAR(40) NOT NULL,
	GroupName					VARCHAR(150) NOT NULL,
	FOREIGN KEY (UserId)		REFERENCES Users(UserId),
)

GO

CREATE TABLE [dbo].[UsersPersonalAccessTokens](
	UserId						VARCHAR(40)	NOT NULL,
	PATDisplayName				VARCHAR(200) NOT NULL,
	PATValidFrom				DATETIME NOT NULL,
	PATValidTo					DATETIME NOT NULL,
	PATScope					NVARCHAR(MAX) NOT NULL,
	FOREIGN KEY (UserId)		REFERENCES Users(UserId),
)

GO

CREATE TABLE [dbo].[Processes]
(
	ProcessTypeId                   VARCHAR(40) NOT NULL,
	ProcessName		                VARCHAR(100) NOT NULL,
	ProcessReferenceName			VARCHAR(100) NULL,
	ProcessCustomizationType		VARCHAR(10) NOT NULL,
	CONSTRAINT [PK_Processes] 		PRIMARY KEY CLUSTERED
(
	ProcessTypeId ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
)

GO

CREATE TABLE [dbo].[ProcessesWorkItemsFields]
(
	ProcessTypeId								VARCHAR(40) NOT NULL,
	ProcessWorkItemTypeName						VARCHAR(100) NOT NULL,
	ProcessWorkItemTypeCustomationType			VARCHAR(40) NOT NULL,
	ProcessWorkItemTypeFieldName				VARCHAR(100) NOT NULL,
	ProcessWorkItemTypeFieldReferenceName		VARCHAR(150) NOT NULL,
	ProcessWorkItemTypeFieldCustomizationType	VARCHAR(40) NOT NULL,
	ProcessWorkItemTypeFieldTypeName			VARCHAR(30) NOT NULL,
	FOREIGN KEY (ProcessTypeId)					REFERENCES Processes(ProcessTypeId),
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Projects]
(
	TeamProjectId						VARCHAR(40) NOT NULL,
	TeamProjectName   					VARCHAR(100) NOT NULL,
	ProcessTypeId						VARCHAR(40) NOT NULL,
	TeamProjectCountWorkItemCreated   	SMALLINT NOT NULL,
	TeamProjectCountWorkItemCompleted   SMALLINT NOT NULL,
	TeamProjectCountCommitsPushed   	SMALLINT NOT NULL,
	TeamProjectCountPRsCreated   		SMALLINT NOT NULL,
	TeamProjectCountPRsCompleted   		SMALLINT NOT NULL,
    TeamProjectCountBuilds   			SMALLINT NOT NULL,
	TeamProjectCountReleases   			SMALLINT NOT NULL,
	FOREIGN KEY (ProcessTypeId)			REFERENCES Processes(ProcessTypeId),	
	CONSTRAINT [PK_Projects] 			PRIMARY KEY CLUSTERED
(
	[TeamProjectId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) 
GO

CREATE TABLE [dbo].[Teams]
(
	TeamProjectId					VARCHAR(40) NOT NULL,
	TeamId							VARCHAR(40) NOT NULL,
	TeamName						VARCHAR(100) NOT NULL,
	TeamWorkingWithBugs				VARCHAR(20) NOT NULL,
	FOREIGN KEY (TeamProjectId)		REFERENCES Projects(TeamProjectId),
	CONSTRAINT [PK_Teams]			PRIMARY KEY CLUSTERED
(
	[TeamId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
)
GO

CREATE TABLE [dbo].[TeamsWorkingDays]
(
	TeamId							VARCHAR(40) NOT NULL,
	TeamWorkingDay					VARCHAR(20) NOT NULL,
	FOREIGN KEY (TeamId)			REFERENCES Teams(TeamId)
) 
GO

CREATE TABLE [dbo].[TeamsBackLogLevels]
(
	TeamId							VARCHAR(40) NOT NULL,
	TeamBackLogLevel				VARCHAR(50) NOT NULL,
	FOREIGN KEY (TeamId)			REFERENCES Teams(TeamId),
	CONSTRAINT [PK_TeamsBackLogLevels] PRIMARY KEY (TeamId, TeamBackLogLevel)
) 
GO

CREATE TABLE [dbo].[TeamsBoardColumns]
(
	TeamId											VARCHAR(40) NOT NULL,
	TeamBackLogLevel								VARCHAR(50) NOT NULL,
	BoardColumnOrder								TINYINT NOT NULL,
	BoardColumnName									VARCHAR(50) NOT NULL,
	BoardColumnStateMappingsWorkItemType			VARCHAR(50) NOT NULL,
	BoardColumnStateMappingsState					VARCHAR(50) NOT NULL,
	BoardColumnIsSplit								BIT NOT NULL,
	FOREIGN KEY (TeamId, TeamBacklogLevel)			REFERENCES TeamsBackLogLevels(TeamId, TeamBacklogLevel)
) 
GO

CREATE TABLE [dbo].[TeamsBoardLanes]
(
	TeamId											VARCHAR(40) NOT NULL,
	TeamBackLogLevel								VARCHAR(50) NOT NULL,
	BoardLaneOrder									TINYINT NOT NULL,
	BoardLaneName									VARCHAR(50) NULL,
	FOREIGN KEY (TeamId, TeamBacklogLevel)			REFERENCES TeamsBackLogLevels(TeamId, TeamBacklogLevel)
) 
GO

CREATE TABLE [dbo].[EnvironmentsApprovalsChecks]
(
	TeamProjectId					VARCHAR(40) NOT NULL,
	EnvironmentId					INT NULL,
	EnvironmentName					VARCHAR(150) NULL,
	EnvironmentCheckName			VARCHAR(100) NULL,
	EnvironmentCheckDisplayName		VARCHAR(100) NULL,
	FOREIGN KEY (TeamProjectId)		REFERENCES Projects(TeamProjectId),
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[Repositories]
(
	TeamProjectId							VARCHAR(40) NOT NULL,
	RepositoryId							VARCHAR(40) NOT NULL,
	RepositoryName							VARCHAR(100) NOT NULL,
	RepositoryURL							VARCHAR(300) NOT NULL,
	RepositoryDefaultBranch					VARCHAR(100) NOT NULL,
	RepositoryMinimumNumberOfReviewers		BIT NOT NULL,
	RepositoryRequiredReviewers				BIT NOT NULL,
	RepositoryWorkItemLinking				BIT NOT NULL,
	RepositoryCommentRequirements			BIT NOT NULL,
	RepositoryBranchBuild					BIT NOT NULL,
	FOREIGN KEY (TeamProjectId)				REFERENCES Projects(TeamProjectId),
	CONSTRAINT [PK_Repositories]			PRIMARY KEY CLUSTERED
(
	[RepositoryId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
)
GO

CREATE TABLE [dbo].[RepositoriesAheadBehind]
(
	RepositoryId							VARCHAR(40) NOT NULL,
	RepositoryBranchName					VARCHAR(100) NOT NULL,
	RepositoryBranchAheadCount				INT NOT NULL,
	RepositoryBranchBehindCount				INT NOT NULL,
	RepositoryBranchIsBaseVersion			BIT NOT NULL,
	FOREIGN KEY (RepositoryId)				REFERENCES Repositories(RepositoryId)
)
GO

CREATE TABLE [dbo].[RepositoriesPullRequests]
(
	RepositoryId							VARCHAR(40) NOT NULL,
	PullRequestId							INT NOT NULL,
	PullRequestTitle						NVARCHAR(MAX) NOT NULL,
	PullRequestBranchSource					VARCHAR(100) NOT NULL,
	PullRequestBranchTarget					VARCHAR(100) NOT NULL,
	PullRequestCreatedBy					VARCHAR(100) NOT NULL,
	PullRequestCreatedDate					DATETIME NOT NULL,
	PullRequestStatus						VARCHAR(50) NOT NULL,
	PullRequestReviewers					NVARCHAR(MAX) NOT NULL,
	FOREIGN KEY (RepositoryId)				REFERENCES Repositories(RepositoryId)
)
GO
