CREATE TABLE [dbo].[IterationPermissions](
	[TeamProjectName] [varchar](100) NULL,
	[IterationPathName] [varchar](150) NULL,
	[SecurityNameSpace] [varchar](100) NULL,
	[UserPrincipalName] [varchar](100) NULL,
	[UserDisplayName] [varchar](100) NULL,
	[GroupDisplayName] [varchar](200) NULL,
	[GroupAccountName] [varchar](200) NULL,
	[IterationCommandName] [varchar](100) NULL,
	[IterationCommandInternalName] [varchar](100) NULL,
	[IterationCommandPermission] [varchar](50) NULL
) ON [PRIMARY]
GO

