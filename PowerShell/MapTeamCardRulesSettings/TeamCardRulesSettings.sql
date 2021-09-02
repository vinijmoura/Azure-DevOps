CREATE TABLE [dbo].[TeamCardRuleSettings](
	[TeamProjectName] [varchar](100) NOT NULL,
	[TeamName] [varchar](100) NOT NULL,
	[TeamBackLogLevel] [varchar](40) NOT NULL,
	[TeamCardRuleSettingName] [varchar](40) NOT NULL,
	[TeamCardRuleSettingFilter] [nvarchar](MAX) NOT NULL,
	[TeamCardRuleSettingBackGroundColor] [varchar](20) NOT NULL
) ON [PRIMARY]
GO