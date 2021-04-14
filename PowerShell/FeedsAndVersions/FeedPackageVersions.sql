CREATE TABLE [dbo].[FeedPackageVersions](
	[FeedName] [varchar](100) NULL,
	[FeedDescription] [nvarchar](max) NULL,
	[FeedPackageName] [varchar](100) NULL,
	[FeedPackageType] [varchar](30) NULL,
	[FeedPackageSource] [varchar](30) NULL,
	[FeedPackageVersion] [varchar](50) NULL,
	[FeedPackageVersionLatest] [bit] NULL,
	[FeedPackageVersionDate] [datetime] NULL,
	[FeedPackageVersionDownloadCount] [int] NULL,
	[FeedPackageVersionDownloadUniqueUsers] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

