CREATE TABLE [dbo].[TaskGroups](
	[TeamProjectName] [varchar](100) NULL,
	[TaskGroupId] [varchar](40) NULL,
	[TaskGroupName] [varchar](150) NULL,
	[TaskGroupIconURL] [nvarchar](max) NULL,
	[TaskGroupVersion] [varchar](30) NULL,
	[TaskGroupCategory] [varchar](30) NULL,
	[TaskGroupTaskDisplayName] [varchar](150) NULL,
	[TaskGroupTaskReferenceId] [varchar](40) NULL,
	[TaskGroupTaskVersionSpec] [varchar](30) NULL,
	[TaskGroupTaskEnabled] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO