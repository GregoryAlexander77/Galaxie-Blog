<!--- description: Creates the PageCollectionMemberLookup and PageCollectionDissolveNotice tables if they're missing. Both are managed with raw SQL rather than an ORM entity, so ORM's automatic table creation never sees them - they previously had to be created by hand on any database missing them. Safe to run more than once. --->
<cfset createTableIfMissing("PageCollectionMemberLookup", {
	"sqlServer": "CREATE TABLE PageCollectionMemberLookup (PageCollectionMemberLookupId INT NOT NULL IDENTITY(1,1) PRIMARY KEY, [Date] DATETIME2 NULL, PostRef INT NULL, PageCollectionRef INT NULL, SortOrder INT NULL)",
	"mySql": "CREATE TABLE PageCollectionMemberLookup (PageCollectionMemberLookupId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, Date DATETIME NULL, PostRef INT NULL, PageCollectionRef INT NULL, SortOrder INT NULL)"
})>
<cfset createTableIfMissing("PageCollectionDissolveNotice", {
	"sqlServer": "CREATE TABLE PageCollectionDissolveNotice (PageCollectionDissolveNoticeId INT NOT NULL IDENTITY(1,1) PRIMARY KEY, BlogRef INT NULL, Message NVARCHAR(500) NULL, Created DATETIME2 NULL, Dismissed BIT NOT NULL DEFAULT 0)",
	"mySql": "CREATE TABLE PageCollectionDissolveNotice (PageCollectionDissolveNoticeId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, BlogRef INT NULL, Message VARCHAR(500) NULL, Created DATETIME NULL, Dismissed TINYINT(1) NOT NULL DEFAULT 0)"
})>
