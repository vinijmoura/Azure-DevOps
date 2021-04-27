CREATE TABLE [dbo].[GitRepositoriesPermissions](
	[TeamProjectName] [varchar](100) NULL,
        [RepoName] [varchar](100) NULL,
	[SecurityNameSpace] [varchar](100) NULL,
	[UserPrincipalName] [varchar](100) NULL,
	[UserDisplayName] [varchar](100) NULL,
	[GroupDisplayName] [varchar](200) NULL,
	[GroupAccountName] [varchar](200) NULL,
	[GitCommandName] [varchar](100) NULL,
	[GitCommandInternalName] [varchar](100) NULL,
	[GitCommandPermission] [varchar](50) NULL
) ON [PRIMARY]

