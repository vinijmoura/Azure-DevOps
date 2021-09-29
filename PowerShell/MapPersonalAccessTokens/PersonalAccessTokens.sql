CREATE TABLE [dbo].[PersonalAccessTokens](
	[UserDisplayName] [varchar](200) NULL,
	[UserMailAddress] [varchar](200) NULL,
	[PATDisplayName] [varchar](200) NULL,
	[PATValidFrom] [DATETIME] NULL,
	[PATValidTo] [DATETIME] NULL,
	[PATScope] [nvarchar](MAX) NULL
)
GO

