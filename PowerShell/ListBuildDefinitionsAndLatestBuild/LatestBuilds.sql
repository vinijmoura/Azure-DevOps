CREATE TABLE [dbo].[LatestBuilds](
	[TeamProjectName] [varchar](100) NULL,
	[BuildDefinitionId] [varchar](40) NULL,
	[BuildDefinitionName] [varchar](150) NULL,
	[BuildNumber] [varchar](100) NULL,
	[BuildResult] [varchar](50) NULL,
	[BuildReason] [varchar](50) NULL,
	[BuildRequestedFor] [varchar](100) NULL,
	[BuildRepository] [varchar](100) NULL,
	[BuildSourceBranch] [varchar](100) NULL,
	[BuildCommit] [varchar](10) NULL,
	[BuildStartTime] [datetime] NULL,
	[BuildTime] [int] NULL,
	[BuildLink] [nvarchar](MAX) null
)
GO