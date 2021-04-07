CREATE TABLE [dbo].[ReleaseDefinitionsClassic](
	[TeamProjectId] [varchar](50) NULL,
	[TeamProjectName] [varchar](100) NULL,
	[ReleaseDefinitionId] [int] NULL,
	[ReleaseDefintionName] [varchar](50) NULL,
	[ReleaseDefinitionURL] [varchar](300) NULL,
	[ReleaseDefintionEnvironmentName] VARCHAR(50) NULL,
	[ReleaseDefinitionEnvironmentRank] TINYINT NULL,
	[ReleaseDefinitionEnvironmentPreDeployApprovalsName] VARCHAR (200) NULL,
	[ReleaseDefinitionEnvironmentPostDeployApprovalsName] VARCHAR (200) NULL
) ON [PRIMARY]

