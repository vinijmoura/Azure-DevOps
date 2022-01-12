CREATE TABLE [dbo].[ProjectsPickLists](
	[TeamProjectId] [VARCHAR](40) NOT NULL,
	[TeamProjectName] [VARCHAR](200) NOT NULL,
	[FieldName] [VARCHAR](100) NOT NULL,
	[FieldReferenceName] [VARCHAR](100) NOT NULL,
	[FieldType] [VARCHAR](30) NOT NULL,
	[FieldPickListId] [VARCHAR](40) NOT NULL,
	[FieldPickListItems] NVARCHAR(MAX) NOT NULL
) 
GO