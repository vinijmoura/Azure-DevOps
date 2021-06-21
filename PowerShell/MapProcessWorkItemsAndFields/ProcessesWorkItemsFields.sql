/****** Object:  Table [dbo].[ProcessesWorkItemsFields]    Script Date: 6/21/2021 3:59:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ProcessesWorkItemsFields](
	[ProcessName] [varchar](100) NULL,
	[ProcessCustomizationType] [varchar](40) NULL,
	[ProcessWorkItemTypeName] [varchar](100) NULL,
	[ProcessWorkItemTypeCustomationType] [varchar](40) NULL,
	[ProcessWorkItemTypeFieldName] [varchar](100) NULL,
	[ProcessWorkItemTypeFieldReferenceName] [varchar](150) NULL,
	[ProcessWorkItemTypeFieldCustomizationType] [varchar](40) NULL,
	[ProcessWorkItemTypeFieldTypeName] [varchar](30) NULL
) ON [PRIMARY]
GO