CREATE TABLE RepoBranchPolicies
(
	TeamProjectId										VARCHAR(50),
	TeamProjectName										VARCHAR(100),
	RepositoryId										VARCHAR(50),
	RepositoryName										VARCHAR(50),
	RepositoryURL										VARCHAR(300),
	RepositoryDefaultBranch								VARCHAR(50),
	RepositoryDefaultBranchMinimumNumberOfReviewers		BIT,
	RepositoryDefaultBranchRequiredReviewers			BIT,
	RepositoryDefaultBranchWorkItemLinking				BIT,
	RepositoryDefaultBranchCommentRequirements			BIT,
	RepositoryDefaultBranchBuild						BIT
)