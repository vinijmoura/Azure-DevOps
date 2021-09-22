CREATE TABLE [dbo].[ProjectStats](
	[TeamProjectName] [varchar](200) NOT NULL,
	[TeamProjectCountWorkItemCreated] [smallint] NOT NULL,
	[TeamProjectCountWorkItemCompleted] [smallint] NOT NULL,
	[TeamProjectCountCommitsPushed] [smallint] NOT NULL,
	[TeamProjectCountPRsCreated] [smallint] NOT NULL,
	[TeamProjectCountPRsCompleted] [smallint] NOT NULL,
    [TeamProjectCountBuilds] [smallint] NOT NULL,
	[TeamProjectCountReleases] [smallint] NOT NULL
) 
GO