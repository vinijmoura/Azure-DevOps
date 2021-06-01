CREATE TABLE [dbo].[VariableGroups](
	[TeamProjectName] [varchar](100) NULL,
	[VariableGroupName] [varchar](150) NULL,
	[VariableGroupType] [varchar](50) NULL,
	[VariableGroupKeyVaultName] [varchar](100) NULL,
	[VariableGroupVariableName] [varchar](100) NULL,
	[VariableGroupVariableValue] [nvarchar](MAX) NULL
) ON [PRIMARY]
GO

