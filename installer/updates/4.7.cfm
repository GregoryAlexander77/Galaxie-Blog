<!--- description: Creates the PageCollectionMemberLookup and PageCollectionDissolveNotice tables if they're missing. Both are managed with raw SQL rather than an ORM entity, so ORM's automatic table creation never sees them - they previously had to be created by hand on any database missing them. Safe to run more than once. --->
<!--- The CREATE TABLE statements live in DatabaseUpdater.cfc's ensureRawSqlTables(), which a brand new install also calls (a new install never runs this script). --->
<cfset ensureRawSqlTables()>
