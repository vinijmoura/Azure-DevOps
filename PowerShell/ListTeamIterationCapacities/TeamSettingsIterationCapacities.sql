CREATE TABLE [dbo].[TeamSettingsIterationCapacities](
	[TeamProjectName] [varchar](100) NOT NULL,
	[TeamName] [varchar](100) NOT NULL,
	[IterationName] [varchar](100) NOT NULL,
	[IterationStartDate] [datetime] NOT NULL,
	[IterationFinishDate] [datetime] NOT NULL,
	[totalIterationCapacityPerDay] DECIMAL(10,2) NOT NULL,
	[totalIterationDaysOff] DECIMAL(10,2) NOT NULL
) 
GO

