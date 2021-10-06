CREATE TABLE [dbo].[ServiceHooks](
	[ProjectName] [varchar](200) NULL,
	[eventDescription] [nvarchar](max) NULL,
	[eventType] [varchar](100) NULL,
	[publisherId] [varchar](200) NULL,
	[consumerId] [varchar](200) NULL,
	[consumerActionId] [nvarchar](max) NULL,
	[actionDescription] [nvarchar](max) NULL,
	[createdBy] [varchar](100) NULL
)
GO