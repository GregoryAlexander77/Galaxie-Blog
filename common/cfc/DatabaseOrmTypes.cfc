<cfcomponent displayname="DatabaseOrmTypes" output="false" hint="Sets the long text column types in the ORM entities to the type that the chosen database uses.">

	<!---
	Every database vendor names its 'long text' column type differently (varchar(max), longtext, clob, long...), and seven of the ORM entities have long text columns (the post body, comments, etc.). Instead of having the person installing the blog copy a different set of files over the entities for their database, Application.cfc calls the apply function below, which rewrites the type on those columns to match the databaseType that the installer saved in the ini file. The entities are shipped set up for SQL Server, so nothing is changed on a SQL Server installation.

	Note: the entities must stay in the same folder, ColdFusion resolves the relationships between entities (cfc="Post") using the folder of the entity that has the relationship.
	--->

	<!--- The long text properties in each entity. --->
	<cfset variables.longTextProperties = {
		"Comment": ["Comment"],
		"Container": ["ContainerContent"],
		"ContentOutput": ["ContentOutput", "ContentOutputMobile"],
		"CustomWindowContent": ["Content"],
		"ErrorLog": ["Stacktrace"],
		"Post": ["JsonLd", "PostHeader", "CSS", "JavaScript", "Body", "MoreBody"],
		"Users": ["Biography"]
	}>

	<!--- How each database declares a long text column. --->
	<cfset variables.flavors = {
		"sqlServer": { ormtype: "string", sqltype: "varchar(max)" },
		"mySql": { ormtype: "text", sqltype: "longtext" },
		"postgre": { ormtype: "text", sqltype: "" },
		"oracle": { ormtype: "clob", sqltype: "" },
		"db2": { ormtype: "string", sqltype: "varchar(32764)" },
		"apacheDerby": { ormtype: "clob", sqltype: "" },
		"sybase": { ormtype: "long", sqltype: "" }
	}>

	<!--- Individual columns that do not follow their database's usual type. --->
	<cfset variables.overrides = {
		"mySql": {
			"ContentOutput.ContentOutput": { ormtype: "string", sqltype: "longtext" },
			"ContentOutput.ContentOutputMobile": { ormtype: "string", sqltype: "longtext" },
			"ErrorLog.Stacktrace": { ormtype: "text", sqltype: "" }
		},
		"sybase": {
			"ErrorLog.Stacktrace": { ormtype: "text", sqltype: "" }
		}
	}>

	<!--- Every value that the installer (or an older installer) may have saved as the databaseType, in lower case, and the flavor that it maps to. --->
	<cfset variables.aliases = {
		"sqlserver": "sqlServer",
		"mysql": "mySql",
		"mariadb": "mySql",
		"postgre": "postgre",
		"postgres": "postgre",
		"postgresql": "postgre",
		"oracle": "oracle",
		"db2": "db2",
		"sybase": "sybase",
		"apachederby": "apacheDerby",
		"derby": "apacheDerby"
	}>

	<cffunction name="getFlavorName" access="public" returnType="string" output="false"
			hint="Returns the name of the flavor (sqlServer, mySql, postgre, oracle, db2, apacheDerby or sybase) for the databaseType that the installer saved, or an empty string if the database type is not one that we know.">
		<cfargument name="databaseType" type="string" required="true">

		<cfset var key = lcase(trim(arguments.databaseType))>

		<cfif structKeyExists(variables.aliases, key)>
			<cfreturn variables.aliases[key]>
		</cfif>

		<cfreturn "">

	</cffunction>

	<cffunction name="getTypeAttributes" access="public" returnType="string" output="false"
			hint="Returns the ormtype and sqltype attributes, as they should be written in the cfproperty tag, of a long text property for a database.">
		<cfargument name="flavorName" type="string" required="true">
		<cfargument name="entityName" type="string" required="true">
		<cfargument name="propertyName" type="string" required="true">

		<cfset var flavor = variables.flavors[arguments.flavorName]>
		<cfset var overrideKey = arguments.entityName & "." & arguments.propertyName>
		<cfset var typeAttributes = "">

		<!--- Use the database's usual type unless this specific column has an override. --->
		<cfif structKeyExists(variables.overrides, arguments.flavorName) and structKeyExists(variables.overrides[arguments.flavorName], overrideKey)>
			<cfset flavor = variables.overrides[arguments.flavorName][overrideKey]>
		</cfif>

		<cfset typeAttributes = 'ormtype="' & flavor.ormtype & '"'>
		<cfif len(flavor.sqltype)>
			<cfset typeAttributes = typeAttributes & ' sqltype="' & flavor.sqltype & '"'>
		</cfif>

		<cfreturn typeAttributes>

	</cffunction>

	<cffunction name="apply" access="public" returnType="array" output="false"
			hint="Changes the long text properties in the entities that are in the entityDirectory to the types that the database uses. Files are only written when something needs to change. Returns an array of the names of the files that were changed.">
		<cfargument name="databaseType" type="string" required="true" hint="The databaseType that the installer saved in the ini file.">
		<cfargument name="entityDirectory" type="string" required="true" hint="The full path of the directory that holds the ORM entities. It must end with a slash.">

		<cfset var changedFiles = []>
		<cfset var flavorName = getFlavorName(arguments.databaseType)>
		<cfset var entityName = "">
		<cfset var propertyName = "">
		<cfset var filePath = "">
		<cfset var original = "">
		<cfset var updated = "">
		<cfset var propertyPattern = "">

		<!--- Leave the entities alone if we don't know the database. --->
		<cfif not len(flavorName)>
			<cfreturn changedFiles>
		</cfif>

		<cfloop collection="#variables.longTextProperties#" item="entityName">

			<cfset filePath = arguments.entityDirectory & entityName & ".cfc">
			<cffile action="read" file="#filePath#" variable="original" charset="utf-8">
			<cfset updated = original>

			<cfloop array="#variables.longTextProperties[entityName]#" index="propertyName">

				<!--- The property tag starts with the name, followed by the ormtype and an optional sqltype. --->
				<cfset propertyPattern = '(<cfproperty\s+name="#propertyName#"\s+)ormtype="[^"]*"(\s+sqltype="[^"]*")?'>

				<cfif not reFind(propertyPattern, updated)>
					<cfthrow type="GalaxieBlog.DatabaseOrmTypes" message="The #entityName#.#propertyName# property could not be found in #filePath#. The cfproperty tag must start with the name, ormtype and (optionally) sqltype attributes, in that order.">
				</cfif>

				<cfset updated = reReplace(updated, propertyPattern, "\1" & getTypeAttributes(flavorName, entityName, propertyName), "one")>

			</cfloop>

			<cfif compare(original, updated) neq 0>
				<cftry>
					<cffile action="write" file="#filePath#" output="#updated#" charset="utf-8" addNewLine="false">
					<cfcatch type="any">
						<cfthrow type="GalaxieBlog.DatabaseOrmTypes" message="Galaxie Blog needs to change the long text columns in #filePath# to work with your #flavorName# database, but the file could not be updated (#cfcatch.message#). Give the account that runs ColdFusion or Lucee permission to write to the #arguments.entityDirectory# folder.">
					</cfcatch>
				</cftry>
				<cfset arrayAppend(changedFiles, entityName & ".cfc")>
			</cfif>

		</cfloop>

		<cfreturn changedFiles>

	</cffunction>

</cfcomponent>
