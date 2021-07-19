CREATE TABLE [dbo].[TeamSettingsBoards](
	[TeamSettingBoardsId] [int] IDENTITY(1,1),
	[TeamProjectName] [varchar](100) NOT NULL,
	[TeamName] [varchar](100) NOT NULL,
	[TeamBackLogLevel] [varchar](50) NOT NULL,
	CONSTRAINT [PK_TeamSettingsBoards] PRIMARY KEY CLUSTERED
(
	[TeamSettingBoardsId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[TeamSettingsBoardColumns](
	[TeamSettingBoardsId] [INT] NOT NULL,
	[BoardColumnOrder][TINYINT] NOT NULL,
	[BoardColumnName] [varchar](50) NOT NULL,
	[BoardColumnStateMappingsWorkItemType] [varchar](50) NOT NULL,
	[BoardColumnStateMappingsState] [varchar](50) NOT NULL,
	[BoardColumnIsSplit][bit] NOT NULL
	FOREIGN KEY (TeamSettingBoardsId) REFERENCES TeamSettingsBoards(TeamSettingBoardsId)
) 
GO

CREATE TABLE [dbo].[TeamSettingsBoardLanes](
	[TeamSettingBoardsId] [INT] NOT NULL,
	[BoardLaneOrder][TINYINT] NOT NULL,
	[BoardLaneName] [varchar](50) NULL,
	FOREIGN KEY (TeamSettingBoardsId) REFERENCES TeamSettingsBoards(TeamSettingBoardsId)
) 
GO