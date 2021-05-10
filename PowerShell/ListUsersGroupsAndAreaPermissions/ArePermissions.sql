CREATE TABLE [dbo].[AreaPermissions](
	[TeamProjectName] [varchar](100) NULL,
	[AreaPathName] [varchar](150) NULL,
	[SecurityNameSpace] [varchar](100) NULL,
	[UserPrincipalName] [varchar](100) NULL,
	[UserDisplayName] [varchar](100) NULL,
	[GroupDisplayName] [varchar](200) NULL,
	[GroupAccountName] [varchar](200) NULL,
	[AreaCommandName] [varchar](100) NULL,
	[AreaCommandInternalName] [varchar](100) NULL,
	[AreaCommandPermission] [varchar](50) NULL
) ON [PRIMARY]
GO

