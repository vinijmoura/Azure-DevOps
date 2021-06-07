CREATE TABLE [dbo].[EnvironmentsDeploys](
	[TeamProjectName] [varchar](100) NULL,
	[EnvironmentId] [int] NULL,
	[EnvironmentName] [varchar](150) NULL,
	[EnvironmentDeployDefinitionName] [varchar](100) NULL,
	[EnvironmentDeployStageName] [varchar](150) NULL,
	[EnvironmentDeployJobName] [varchar](150) NULL,
	[EnvironmentDeployResult] [varchar](50) NULL,
	[EnvironmentDeployQueueTime] [datetime] NULL,
	[EnvironmentDeployStartTime] [datetime] NULL,
	[EnvironmentDeployFinishTime] [datetime] NULL
) ON [PRIMARY]
GO

