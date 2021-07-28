CREATE TABLE [dbo].[TeamSettingsTaskBoardColumns](
	[TeamSettingsTaskBoardColumnsId] [int] IDENTITY(1,1),
	[TeamProjectName] [varchar](100) NOT NULL,
	[TeamName] [varchar](100) NOT NULL,
	[TeamSettingsTaskBoardColumnName] [varchar](50) NOT NULL,
	[TeamSettingsTaskBoardColumnOrder][TINYINT] NOT NULL,
	CONSTRAINT [PK_TeamSettingsTaskBoardColumns] PRIMARY KEY CLUSTERED
(
	[TeamSettingsTaskBoardColumnsId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[TeamSettingsTaskBoardColumnsWorkItemType](
	[TeamSettingsTaskBoardColumnsId] [INT] NOT NULL,
	[WorkItemType] [varchar](50) NOT NULL,
	[WorkItemState] [varchar](50) NOT NULL
	FOREIGN KEY (TeamSettingsTaskBoardColumnsId) REFERENCES TeamSettingsTaskBoardColumns(TeamSettingsTaskBoardColumnsId)
) 
GO