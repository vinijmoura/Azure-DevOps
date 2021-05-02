CREATE TABLE [dbo].[ProjectLevelPermissions](
	[TeamProjectName] [varchar](100) NULL,
	[SecurityNameSpace] [varchar](100) NULL,
	[UserPrincipalName] [varchar](100) NULL,
	[UserDisplayName] [varchar](100) NULL,
	[GroupDisplayName] [varchar](200) NULL,
	[GroupAccountName] [varchar](200) NULL,
	[ProjectLevelType] [varchar](50) NULL,
	[ProjectLevelCommandName] [varchar](100) NULL,
	[ProjectLevelCommandInternalName] [varchar](100) NULL,
	[ProjectLevelCommandPermission] [varchar](50) NULL
) ON [PRIMARY]
GO

