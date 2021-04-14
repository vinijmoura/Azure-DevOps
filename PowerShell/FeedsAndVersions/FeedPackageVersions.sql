CREATE TABLE FeedPackageVersions
(
	FeedName									VARCHAR(100),
    FeedDescription							    NVARCHAR(MAX),
    FeedPackageName								VARCHAR(100),
    FeedPackageType								VARCHAR(30),
	FeedPackageSource							VARCHAR(30),
    FeedPackageVersion							VARCHAR(50),
    FeedPackageVersionLatest					BIT,
    FeedPackageVersionDate						DATETIME,
    FeedPackageVersionDownloadCount				INT,
    FeedPackageVersionDownloadUniqueUsers		INT
)