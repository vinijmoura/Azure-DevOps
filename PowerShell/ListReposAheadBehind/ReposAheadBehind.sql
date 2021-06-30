CREATE TABLE [dbo].[ReposAheadBehind](
	[TeamProjectName] [varchar](100) NULL,
	[RepositoryId] [varchar](40) NULL,
	[RepositoryName] [varchar](150) NULL,
	[RepositoryBranchName] [nvarchar](max) NULL,
	[RepositoryBranchAheadCount] [int] NULL,
	[RepositoryBranchBehindCount] [int] NULL,
	[RepositoryBranchIsBaseVersion] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO