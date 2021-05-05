CREATE TABLE [dbo].[OrganizationLevelPermissions](
	[SecurityNameSpace] [varchar](100) NULL,
	[UserPrincipalName] [varchar](100) NULL,
	[UserDisplayName] [varchar](100) NULL,
	[GroupDisplayName] [varchar](200) NULL,
	[GroupAccountName] [varchar](200) NULL,
	[OrganizationLevelType] [varchar](50) NULL,
	[OrganizationLevelCommandName] [varchar](100) NULL,
	[OrganizationLevelCommandInternalName] [varchar](100) NULL,
	[OrganizationLevelCommandPermission] [varchar](50) NULL
) ON [PRIMARY]
GO

