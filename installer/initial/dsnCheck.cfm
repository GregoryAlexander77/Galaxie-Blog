<!---
	Datasource check for the installer (2026-10-12). Included by step5SaveDatabase.cfm, step6UserProfile.cfm and step7Post.cfm.

	getInstallDsnProblem(dsn) returns an empty string when the datasource can be used to install a new blog, otherwise a
	message saying why not. A datasource can only be used when:
	  - a name was entered;
	  - a datasource with that name exists and connects;
	  - its database does not already contain a Galaxie Blog.

	The last check is the important one. The first version of step 4 suggested the name "GalaxieDb", which is the name a
	Galaxie Blog that is already running on the same server is likely to use. On 2026-10-12 a test install kept that
	suggestion, the datasource existed and connected, and the installer wrote its starter data into the live blog's
	database, overwriting its settings. The installer only ever installs into an empty database, so it now refuses any
	database that already has a blog or users in it.
--->
<cffunction name="getInstallDsnProblem" access="public" returntype="string" output="false">
	<cfargument name="dsn" type="string" required="true">

	<cfset var thisDsn = trim(arguments.dsn)>
	<cfset var existingRows = 0>
	<cfset var tableName = "">
	<cfset var countQuery = "">

	<cfif not len(thisDsn)>
		<cfreturn "Please enter the name of the datasource that you created for the new, empty database.">
	</cfif>

	<!--- Does the datasource exist and connect? --->
	<cftry>
		<cfquery name="countQuery" datasource="#thisDsn#">
			SELECT 1 AS DsnCheck
		</cfquery>
		<cfcatch type="any">
			<cfreturn "The datasource '#thisDsn#' could not be used: #cfcatch.message# #cfcatch.detail# Check that a datasource with exactly this name exists in the ColdFusion or Lucee administrator, and that it verifies.">
		</cfcatch>
	</cftry>

	<!--- Is there already a blog in this database? A table that does not exist yet is fine - a new database has none. --->
	<cfloop list="Blog,Users,Post" index="tableName">
		<cftry>
			<cfquery name="countQuery" datasource="#thisDsn#">
				SELECT COUNT(*) AS RowsFound FROM #tableName#
			</cfquery>
			<cfset existingRows = existingRows + val(countQuery.RowsFound)>
			<cfcatch type="database">
				<!--- The table does not exist. --->
			</cfcatch>
		</cftry>
	</cfloop>
	<cfif existingRows gt 0>
		<cfreturn "The datasource '#thisDsn#' points to a database that already contains a Galaxie Blog. The installer only installs into a new, empty database, so that it can never overwrite an existing blog. Create a new, empty database and a datasource for it, and enter that datasource's name here.">
	</cfif>

	<cfreturn "">
</cffunction>
