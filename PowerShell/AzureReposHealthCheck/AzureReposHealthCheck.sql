CREATE TABLE [dbo].[Projects](
	[TeamProjectId]				VARCHAR(100) NOT NULL,
	[TeamProjectName]			VARCHAR(100) NOT NULL,
	CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED
(
	[TeamProjectId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE Repositories
(
	TeamProjectId											VARCHAR(100) NOT NULL,
	RepositoryId											VARCHAR(50) NOT NULL,
	RepositoryName											VARCHAR(50) NOT NULL,
	RepositoryURL											VARCHAR(300) NOT NULL,
	RepositoryDefaultBranch									VARCHAR(50) NOT NULL,
	RepositoryDefaultBranchMinimumNumberOfReviewers			BIT NOT NULL,
	RepositoryDefaultBranchRequiredReviewers				BIT NOT NULL,
	RepositoryDefaultBranchWorkItemLinking					BIT NOT NULL,
	RepositoryDefaultBranchCommentRequirements				BIT NOT NULL,
	RepositoryDefaultBranchBuild							BIT NOT NULL,
	FOREIGN KEY (TeamProjectId) REFERENCES Projects(TeamProjectId),
	CONSTRAINT [PK_Repositories] PRIMARY KEY CLUSTERED
(
	[RepositoryId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
)

GO

CREATE TABLE [dbo].[RepositoriesAheadBehind](
	[RepositoryId]						VARCHAR(50)			NOT NULL,
	[RepositoryBranchName]				VARCHAR(100)		NOT NULL,
	[RepositoryBranchAheadCount]		INT					NOT NULL,
	[RepositoryBranchBehindCount]		INT					NOT NULL,
	[RepositoryBranchIsBaseVersion]		BIT					NOT NULL,
	FOREIGN KEY (RepositoryId) REFERENCES Repositories(RepositoryId)
)
GO

CREATE TABLE [dbo].[RepositoriesPullRequests](
	[RepositoryId]						VARCHAR(50)			NOT NULL,
	[PullRequestId]						INT					NOT NULL,
	[PullRequestTitle]					NVARCHAR(MAX)		NOT NULL,
	[PullRequestBranchSource]			VARCHAR(100)		NOT NULL,
	[PullRequestBranchTarget]			VARCHAR(100)		NOT NULL,
	[PullRequestCreatedBy]				VARCHAR(100)		NOT NULL,
	[PullRequestCreatedDate]			DATETIME			NOT NULL,
	[PullRequestStatus]					VARCHAR(50)			NOT NULL,
	[PullRequestReviewers]				NVARCHAR(MAX)		NOT NULL,
	FOREIGN KEY (RepositoryId) REFERENCES Repositories(RepositoryId)
)
GO