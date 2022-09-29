CREATE TABLE [dbo].[DeploymentGroupsMachinesCapabilities](
	[TeamProjectName] [varchar](100) NULL,
	[DeploymentGroupName] [varchar](100) NULL,
	[MachineName] [varchar](150) NULL,
	[CapabilityName] [varchar](150) NULL,
	[CapabilityValue] [nvarchar](MAX) NULL
	
) ON [PRIMARY]
GO