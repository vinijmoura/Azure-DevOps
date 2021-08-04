CREATE TABLE [dbo].[DeploymentGroupReleases](
	[TeamProjectName] [varchar](100) NULL,
	[ReleaseDefinitionName] [varchar](100) NULL,
	[EnvironmentName] [varchar](150) NULL,
	[DeploymentPhaseName] [varchar](150) NULL,
	[DeploymentGroupName] [varchar](150) NULL,
	[MachineName] [varchar](150) NULL
) ON [PRIMARY]
GO