CREATE TABLE [dbo].[TeamSettings](
	[TeamSettingId] [int] IDENTITY(1,1),
	[TeamProjectName] [varchar](100) NOT NULL,
	[TeamName] [varchar](100) NOT NULL,
	[TeamWorkingWithBugs] [varchar](20) NOT NULL,
	CONSTRAINT [PK_TeamSettings] PRIMARY KEY CLUSTERED
(
	[TeamSettingId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE [dbo].[TeamSettingsBackLogLevels](
	[TeamSettingId] [INT] NOT NULL,
	[TeamBackLogLevel] [varchar](50) NOT NULL,
	FOREIGN KEY (TeamSettingId) REFERENCES TeamSettings(TeamSettingId)
) 
GO

CREATE TABLE [dbo].[TeamSettingsWorkingDays](
	[TeamSettingId] [INT] NOT NULL,
	[TeamWorkingDay] [varchar](20) NULL,
	FOREIGN KEY (TeamSettingId) REFERENCES TeamSettings(TeamSettingId)
) 
GO