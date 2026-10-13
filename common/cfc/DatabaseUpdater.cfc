<cfcomponent displayname="DatabaseUpdater" output="false" hint="Brings an existing blog's database (and files) up to the version of the code that was uploaded over it.">

	<!---
	How updating works
	- The version of the code is in blog.cfc (application.blog.getVersion()). The version of the database is in the Blog.BlogVersion column (application.blog.getDbBlogVersion()).
	- ORM already adds new tables and columns by itself when the application restarts, so schema changes need nothing here. This component handles everything else: adding new reference data (fonts, themes, etc.), filling in values on new columns, and removing files that a release no longer ships.
	- Each release that needs something beyond that gets a script named after the version in /installer/updates/, for example 4.66.cfm. When the database version is lower than the code version, every script whose version is greater than the database version and no greater than the code version is run, oldest first, and the database version is saved after each one succeeds. A script that fails stops the update, and running the update again picks up at that script.
	- Scripts must be safe to run more than once, and must never overwrite the user's own settings or data. See the helper functions at the bottom of this component, which the scripts call.
	- Versions are compared as decimal numbers (4.65 is lower than 4.66, and 4.66 is lower than 4.7). Do not release a 4.10 after a 4.9.
	- This is run from the administrative site by a logged in administrator (see the runDatabaseUpdate function in ProxyController.cfc). It never runs by itself.
	--->

	<cfset variables.rootDirectory = "">
	<cfset variables.iniPath = "">
	<cfset variables.updatesDirectory = "">
	<cfset variables.runLog = []>

	<cffunction name="init" access="public" returnType="any" output="false">
		<cfargument name="rootDirectory" type="string" required="true" hint="The full path of the blog's root directory.">
		<cfargument name="iniPath" type="string" required="true" hint="The full path of the blog.ini.cfm file.">

		<cfset variables.rootDirectory = arguments.rootDirectory>
		<cfif not listFind("/,\", right(variables.rootDirectory, 1))>
			<cfset variables.rootDirectory = variables.rootDirectory & "/">
		</cfif>
		<cfset variables.iniPath = arguments.iniPath>
		<cfset variables.updatesDirectory = variables.rootDirectory & "installer/updates/">

		<cfreturn this>

	</cffunction>

	<!---//****************************************************************************************
		Status
	//*****************************************************************************************--->

	<cffunction name="getPendingMigrations" access="public" returnType="array" output="false"
			hint="Returns the update scripts that have not been run yet, oldest first. Each item has the version, the file name and a description that comes from the script's header comment.">
		<cfargument name="databaseVersion" type="string" required="true">
		<cfargument name="codeVersion" type="string" required="true">

		<cfset var pending = []>
		<cfset var scripts = "">
		<cfset var version = "">
		<cfset var source = "">
		<cfset var description = "">
		<cfset var descriptionMatch = "">

		<cfif not directoryExists(variables.updatesDirectory)>
			<cfreturn pending>
		</cfif>

		<cfdirectory action="list" directory="#variables.updatesDirectory#" name="scripts" filter="*.cfm">

		<cfloop query="scripts">
			<!--- The file name is the version, ie 4.66.cfm. Ignore anything else. --->
			<cfset version = reReplaceNoCase(scripts.name, "\.cfm$", "")>
			<cfif reFind("^[0-9]+(\.[0-9]+)*$", version)
					and val(version) gt val(arguments.databaseVersion)
					and val(version) lte val(arguments.codeVersion)>

				<cffile action="read" file="#variables.updatesDirectory##scripts.name#" variable="source" charset="utf-8">
				<cfset description = "">
				<cfset descriptionMatch = reFindNoCase("<!---\s*description:\s*(.*?)\s*--->", source, 1, true)>
				<cfif descriptionMatch.pos[1] gt 0>
					<cfset description = mid(source, descriptionMatch.pos[2], descriptionMatch.len[2])>
				</cfif>

				<cfset arrayAppend(pending, { version: version, file: scripts.name, description: description })>
			</cfif>
		</cfloop>

		<cfset arraySort(pending, function(a, b) {
			if (val(a.version) lt val(b.version)) { return -1; }
			if (val(a.version) gt val(b.version)) { return 1; }
			return 0;
		})>

		<cfreturn pending>

	</cffunction>

	<cffunction name="getStatus" access="public" returnType="struct" output="false"
			hint="Returns the version of the code, the version of the database, whether the database needs to be updated and the scripts that will be run.">

		<cfset var status = {}>

		<cfset status.codeVersion = application.blog.getVersion()>
		<cfset status.databaseVersion = application.blog.getDbBlogVersion()>
		<cfset status.updateNeeded = val(status.databaseVersion) lt val(status.codeVersion)>
		<cfset status.pending = getPendingMigrations(status.databaseVersion, status.codeVersion)>

		<cfreturn status>

	</cffunction>

	<!---//****************************************************************************************
		Running the update
	//*****************************************************************************************--->

	<cffunction name="run" access="public" returnType="struct" output="false"
			hint="Runs every pending update script in order and saves the new version. Returns a struct with a success flag, a message and a log of what was done.">

		<!--- The keys are in quotes so that Adobe ColdFusion keeps their case when this is sent to the browser as json. Without quotes it sends SUCCESS and MESSAGE. --->
		<cfset var result = { "success": true, "message": "", "log": [], "fromVersion": "", "toVersion": "", "failedVersion": "" }>
		<cfset var status = "">
		<cfset var migration = "">
		<cfset var ranUpdate = false>

		<cflock name="galaxieBlog.databaseUpdate" type="exclusive" timeout="5" throwOnTimeout="false">

			<cfset ranUpdate = true>
			<cfset variables.runLog = []>

			<cfset status = getStatus()>
			<cfset result.fromVersion = status.databaseVersion>
			<cfset result.toVersion = status.databaseVersion>

			<cfif not status.updateNeeded>
				<cfset result.message = "The database is already up to date.">
			<cfelse>

				<cfloop array="#status.pending#" index="migration">

					<cfset addToLog("Running the #migration.version# update. #migration.description#")>

					<cftry>
						<!--- The scripts run here, so they can call the helper functions below. Note: the path is relative to this component. --->
						<cfinclude template="../../installer/updates/#migration.file#">
						<!--- 2026-10-13: write any entity changes the script made. The application sets
						ormsettings.flushAtRequestEnd = false, so an entitySave() that updates an existing row (eg. 4.8's ShowInMenu on
						the docs collections) is otherwise only kept in memory and lost at the end of the request; new rows are
						inserted at once, which is why most scripts never noticed. --->
						<cfset ormFlush()>
						<cfset stampVersion(migration.version, "Galaxie Blog " & migration.version)>
						<cfset result.toVersion = migration.version>
						<cfset addToLog("Finished the #migration.version# update.")>
						<cfcatch type="any">
							<cfset result.success = false>
							<cfset result.failedVersion = migration.version>
							<cfset result.message = "The #migration.version# update failed and nothing after it was run: #cfcatch.message#">
							<cfif len(cfcatch.detail)>
								<cfset result.message = result.message & " " & cfcatch.detail>
							</cfif>
							<cfset addToLog("FAILED: " & result.message)>
						</cfcatch>
					</cftry>

					<cfif not result.success>
						<cfbreak>
					</cfif>

				</cfloop>

				<!--- There may not have been a script for this version (ORM handles the schema by itself). If everything went well, the database is now at the version of the code. --->
				<cfif result.success>
					<cfif val(result.toVersion) lt val(status.codeVersion)>
						<cfset stampVersion(status.codeVersion, application.blog.getVersionName())>
						<cfset result.toVersion = status.codeVersion>
					</cfif>
					<cfset result.message = "The database was updated to version #result.toVersion#.">
					<cfset addToLog(result.message)>
				</cfif>

			</cfif>

		</cflock>

		<cfif not ranUpdate>
			<cfset result.success = false>
			<cfset result.message = "Another update is already running. Please try again in a minute.">
		</cfif>

		<cfset result.log = variables.runLog>

		<cfreturn result>

	</cffunction>

	<cffunction name="stampVersion" access="private" returnType="void" output="false"
			hint="Saves the version of the database.">
		<cfargument name="version" type="string" required="true">
		<cfargument name="versionName" type="string" required="true">

		<cfset application.blog.updateBlogVersion(arguments.version, arguments.versionName)>
		<cfset application.dbBlogVersion = arguments.version>

		<!--- The cached Blog object no longer has the new version. --->
		<cftry>
			<cfset entityReload(application.BlogDbObj)>
			<cfcatch type="any"></cfcatch>
		</cftry>

	</cffunction>

	<!---//****************************************************************************************
		Helpers for the update scripts in /installer/updates/
	//*****************************************************************************************--->

	<cffunction name="addToLog" access="public" returnType="void" output="false"
			hint="Adds a line to the log that is shown to the administrator when the update finishes.">
		<cfargument name="message" type="string" required="true">

		<cfset arrayAppend(variables.runLog, arguments.message)>

	</cffunction>

	<cffunction name="createTableIfMissing" access="public" returnType="void" output="false"
			hint="Creates a table with raw SQL if it does not already exist. For a table that is managed directly with hand-written <cfquery> SQL rather than an ORM entity (see PageCollectionMemberLookup/PageCollectionDissolveNotice for the two that exist so far) - ORM's own dbcreate='update' only ever creates tables it knows about from a <cfproperty>-declared entity, so a raw-SQL table like this is otherwise never created for a fresh install or an existing install missing it. Safe to run more than once - does nothing if the table is already there.">
		<cfargument name="tableName" type="string" required="true">
		<cfargument name="createSqlByFlavor" type="struct" required="true" hint="Keys are DatabaseOrmTypes.cfc flavor names (sqlServer, mySql, etc. - see its own aliases struct, which already folds mariaDB into mySql) - each value is the full CREATE TABLE statement for that flavor. A flavor with no entry here is skipped (logged, not thrown), same as DatabaseOrmTypes.cfc's own leave-alone behavior for a database it doesn't recognize.">

		<cfset var alreadyExists = "">
		<cfset var databaseOrmTypesObj = "">
		<cfset var flavorName = "">
		<cfset var createSql = "">

		<!--- The table names come from the update scripts, never from a user, but only plain names are allowed here as they go into the SQL below. --->
		<cfif not reFind("^[A-Za-z][A-Za-z0-9_]*$", arguments.tableName)>
			<cfset addToLog("Skipped the table '#arguments.tableName#': not a valid table name.")>
			<cfreturn>
		</cfif>

		<!--- Does the table exist in the blog's own database? Selecting nothing from it succeeds if it does and errors if it does not. This used to look the name up in INFORMATION_SCHEMA.TABLES, but on MySQL and MariaDB that lists the tables of every database on the server, so when another Galaxie Blog database on the same server already had the table, it was never created for this blog (found in the 4.8 install test on Lucee and MariaDB, 2026-10-11). --->
		<cfset alreadyExists = true>
		<cftry>
			<cfquery datasource="#application.dsn#">
				SELECT 1 FROM #arguments.tableName# WHERE 1 = 0
			</cfquery>
			<cfcatch type="database">
				<cfset alreadyExists = false>
			</cfcatch>
		</cftry>
		<cfif alreadyExists>
			<cfset addToLog("The #arguments.tableName# table already exists.")>
			<cfreturn>
		</cfif>

		<!--- Same root-vs-subfolder instantiation pattern Application.cfc's own applyDatabaseOrmTypes() uses. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset databaseOrmTypesObj = createObject("component", application.baseComponentPath & ".common.cfc.DatabaseOrmTypes")>
		<cfelse>
			<cfset databaseOrmTypesObj = createObject("component", "common.cfc.DatabaseOrmTypes")>
		</cfif>
		<cfset flavorName = databaseOrmTypesObj.getFlavorName(application.databaseType)>

		<cfif not len(flavorName) or not structKeyExists(arguments.createSqlByFlavor, flavorName)>
			<cfset addToLog("Could not create the #arguments.tableName# table - no CREATE TABLE statement is defined for this database (#application.databaseType#). Create it by hand; see the pagecollectionmemberlookup-missing-table-lucee memory for the SQL Server/MySQL versions.")>
			<cfreturn>
		</cfif>

		<!--- No preserveSingleQuotes() needed - these CREATE TABLE statements have no single-quoted literals in
		them (no DEFAULT values, no string columns with quoted defaults), so a plain variable reference is
		correct. preserveSingleQuotes() was tried here first and rejected by ACF with "Complex constructs are not
		supported with function preserveSingleQuotes" the moment its argument was a struct-key lookup rather than
		a bare variable - moot now since it isn't needed at all, but worth remembering if this function ever needs
		to accept a CREATE TABLE with a quoted default value in the future (assign the struct lookup to its own
		local variable first, then pass that variable - not the lookup expression itself). --->
		<cfset createSql = arguments.createSqlByFlavor[flavorName]>
		<cftry>
			<cfquery datasource="#application.dsn#">
				#createSql#
			</cfquery>
			<cfcatch type="database">
				<!--- Another request may have created the table between the check above and this statement (two requests finishing a new install at the same time, 2026-10-12). That is fine; anything else is a real error. --->
				<cfset var createError = cfcatch>
				<cftry>
					<cfquery datasource="#application.dsn#">
						SELECT 1 FROM #arguments.tableName# WHERE 1 = 0
					</cfquery>
					<cfset addToLog("The #arguments.tableName# table was created by another request.")>
					<cfreturn>
					<cfcatch type="database">
						<cfthrow object="#createError#">
					</cfcatch>
				</cftry>
			</cfcatch>
		</cftry>
		<cfset addToLog("Created the #arguments.tableName# table.")>

	</cffunction>

	<cffunction name="ensureRawSqlTables" access="public" returnType="void" output="false"
			hint="Creates the tables that are managed with raw SQL rather than an ORM entity (ORM's automatic table creation never sees them) if they are missing. Called by the 4.7 update script for existing blogs, and by Application.cfc when a brand new blog is installed - a new install starts at the current version, so it never runs the 4.7 script (found in the 4.8 install test, 2026-10-11: 'Invalid object name PageCollectionMemberLookup' when opening the first post). Safe to run more than once.">

		<cfset createTableIfMissing("PageCollectionMemberLookup", {
			"sqlServer": "CREATE TABLE PageCollectionMemberLookup (PageCollectionMemberLookupId INT NOT NULL IDENTITY(1,1) PRIMARY KEY, [Date] DATETIME2 NULL, PostRef INT NULL, PageCollectionRef INT NULL, SortOrder INT NULL)",
			"mySql": "CREATE TABLE PageCollectionMemberLookup (PageCollectionMemberLookupId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, Date DATETIME NULL, PostRef INT NULL, PageCollectionRef INT NULL, SortOrder INT NULL)"
		})>
		<cfset createTableIfMissing("PageCollectionDissolveNotice", {
			"sqlServer": "CREATE TABLE PageCollectionDissolveNotice (PageCollectionDissolveNoticeId INT NOT NULL IDENTITY(1,1) PRIMARY KEY, BlogRef INT NULL, Message NVARCHAR(500) NULL, Created DATETIME2 NULL, Dismissed BIT NOT NULL DEFAULT 0)",
			"mySql": "CREATE TABLE PageCollectionDissolveNotice (PageCollectionDissolveNoticeId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, BlogRef INT NULL, Message VARCHAR(500) NULL, Created DATETIME NULL, Dismissed TINYINT(1) NOT NULL DEFAULT 0)"
		})>

	</cffunction>

	<cffunction name="seedTables" access="public" returnType="void" output="false"
			hint="Adds the reference data that is in the /installer/dataFiles/ folder to the database. By default this only adds the records that are missing and leaves existing records (and any changes that the user made to them) alone. Only pass updateRecords as true for tables that the user can't change.">
		<cfargument name="tables" type="string" required="true" hint="A list of tables. Any table that application.blog.updateDb() handles, ie Font, Theme, MapProvider or MapType.">
		<cfargument name="updateRecords" type="boolean" required="false" default="false">

		<cfset var table = "">

		<cfloop list="#arguments.tables#" index="table">
			<cfset application.blog.updateDb(tablesToPopulate=table, updateRecords=arguments.updateRecords)>
			<cfset addToLog("Checked the #table# table for missing records.")>
		</cfloop>

	</cffunction>

	<cffunction name="removeFiles" access="public" returnType="void" output="false"
			hint="Removes files and folders that a release no longer uses. The paths are relative to the blog's root directory. Nothing outside of the blog's directory can be removed. A file that can't be removed (ie no permission) is reported in the log, it does not stop the update.">
		<cfargument name="paths" type="array" required="true">

		<cfset var relativePath = "">
		<cfset var fullPath = "">
		<cfset var canonicalRoot = createObject("java", "java.io.File").init(variables.rootDirectory).getCanonicalPath()>
		<cfset var canonicalPath = "">
		<cfset var isSafePath = false>
		<!--- Files that must never be removed. --->
		<cfset var protectedPaths = "Application.cfc,index.cfm,org/camden/blog/blog.ini.cfm">

		<cfloop array="#arguments.paths#" index="relativePath">

			<cfset relativePath = replace(trim(relativePath), "\", "/", "all")>
			<cfset fullPath = variables.rootDirectory & relativePath>

			<!--- Only look at the path on disk after the simple checks pass, and treat a path that the operating system rejects as unsafe. --->
			<cfset isSafePath = len(relativePath)
					and left(relativePath, 1) neq "/"
					and not find("..", relativePath)
					and not find(":", relativePath)
					and not listFindNoCase(protectedPaths, relativePath)>
			<cfif isSafePath>
				<cftry>
					<cfset canonicalPath = createObject("java", "java.io.File").init(fullPath).getCanonicalPath()>
					<cfset isSafePath = compareNoCase(left(canonicalPath, len(canonicalRoot)), canonicalRoot) eq 0>
					<cfcatch type="any">
						<cfset isSafePath = false>
					</cfcatch>
				</cftry>
			</cfif>

			<cfif not isSafePath>
				<cfset addToLog("Skipped '#relativePath#', it is not a path that can be removed.")>
			<cfelseif fileExists(fullPath)>
				<cftry>
					<cffile action="delete" file="#fullPath#">
					<cfset addToLog("Removed the file #relativePath#.")>
					<cfcatch type="any">
						<cfset addToLog("Could not remove the file #relativePath# (#cfcatch.message#). It is no longer used, you can delete it yourself.")>
					</cfcatch>
				</cftry>
			<cfelseif directoryExists(fullPath)>
				<cftry>
					<cfdirectory action="delete" directory="#fullPath#" recurse="true">
					<cfset addToLog("Removed the folder #relativePath#.")>
					<cfcatch type="any">
						<cfset addToLog("Could not remove the folder #relativePath# (#cfcatch.message#). It is no longer used, you can delete it yourself.")>
					</cfcatch>
				</cftry>
			<cfelse>
				<cfset addToLog("#relativePath# was already removed.")>
			</cfif>

		</cfloop>

	</cffunction>

	<cffunction name="addMissingIniKeys" access="public" returnType="void" output="false"
			hint="Adds keys to the blog.ini.cfm file if they are not in it yet. Existing values are never changed.">
		<cfargument name="keys" type="struct" required="true" hint="The key names and the default values.">

		<cfset var iniText = "">
		<cfset var keyName = "">

		<cffile action="read" file="#variables.iniPath#" variable="iniText" charset="utf-8">

		<cfloop collection="#arguments.keys#" item="keyName">
			<cfif not reFindNoCase("(^|[\r\n])\s*#keyName#\s*=", iniText)>
				<cfset setProfileString(variables.iniPath, "default", keyName, arguments.keys[keyName])>
				<cfset addToLog("Added #keyName# to the ini file.")>
			</cfif>
		</cfloop>

	</cffunction>

</cfcomponent>
