CREATE TABLE [dbo].[BuildApprovalsRequired](
	[TeamProjectName] [varchar](100) NULL,
	[BuildDefinitionId] [varchar](40) NULL,
	[BuildDefinitionName] [varchar](150) NULL,
	[BuildId] [varchar](20) NULL,
	[BuildNumber] [varchar](100) NULL,
	[BuildLink] [nvarchar](MAX) NULL,
	[BuildStageName] [varchar](100) NULL,
	[BuildEnvironmentName] [varchar](100) NULL
)
GO

