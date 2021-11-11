CREATE TABLE [dbo].[ProcessesWorkItemsRules](
	[ProcessName] [varchar](100) NULL,
	[ProcessWorkItemTypeName] [varchar](100) NULL,
	[ProcessWorkItemTypeRuleName] [varchar](100) NULL,
	[ProcessWorkItemTypeRuleConditionsTypes] [nvarchar](MAX) NULL,
	[ProcessWorkItemTypeRuleConditionsFields] [nvarchar](MAX) NULL,
	[ProcessWorkItemTypeRuleConditionsValues] [nvarchar](MAX) NULL,
	[ProcessWorkItemTypeRuleActionsTypes] [nvarchar](MAX) NULL,
	[ProcessWorkItemTypeRuleActionsTargetFields] [nvarchar](MAX) NULL,
	[ProcessWorkItemTypeRuleActionsValues] [nvarchar](MAX) NULL
) ON [PRIMARY]
GO
