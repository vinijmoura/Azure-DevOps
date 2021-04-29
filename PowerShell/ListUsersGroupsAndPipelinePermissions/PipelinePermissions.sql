CREATE TABLE [dbo].[PipelinePermissions](
	[TeamProjectName] [varchar](100) NULL,
	[RepoName] [varchar](100) NULL,
	[SecurityNameSpace] [varchar](100) NULL,
	[UserPrincipalName] [varchar](100) NULL,
	[UserDisplayName] [varchar](100) NULL,
	[GroupDisplayName] [varchar](200) NULL,
	[GroupAccountName] [varchar](200) NULL,
	[PipelineCommandName] [varchar](100) NULL,
	[PipelineCommandInternalName] [varchar](100) NULL,
	[PipelineCommandPermission] [varchar](50) NULL
) ON [PRIMARY]
GO

