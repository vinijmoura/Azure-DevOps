CREATE TABLE [dbo].[LatestReleases](
	[TeamProjectName] [varchar](100) NULL,
	[ReleaseDefinitionId] [varchar](40) NULL,
	[ReleaseDefinitionName] [varchar](150) NULL,
	[ReleaseNumber] [varchar](100) NULL,
	[ReleaseCreatedOn] [datetime] NULL,
	[ReleaseLink] [nvarchar](MAX) NULL,
	[ReleaseEnvironmentName] [varchar](150) NULL,
	[ReleaseEnvironmentResult] [varchar](50) NULL,
	[ReleaseEnvironmentReason] [varchar](50) NULL,
	[ReleaseEnvironmentRequestedFor] [varchar](100) NULL
)
GO