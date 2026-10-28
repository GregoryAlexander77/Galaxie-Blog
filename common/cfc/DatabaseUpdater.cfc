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

	<cffunction name="ensureOrmTables" access="public" returnType="void" output="false"
			hint="Makes sure the tables of new ORM entities exist (added for Forms, 2026-10-13). ORM creates them by itself when the application restarts (dbcreate='update'), but only if the entity's long text columns were already set for this database (DatabaseOrmTypes.cfc) - otherwise, on MySQL and MariaDB, the table is silently not created. If any table is missing, this sets the column types, reloads ORM and checks again. A table that is still missing stops the update with a message, so running the update again retries it. Safe to run more than once.">
		<cfargument name="tableNames" type="string" required="true" hint="A list of the entities' table names, eg. 'WebForm,WebFormField,WebFormSubmission'.">

		<cfset var tableName = "">
		<cfset var missing = "">
		<cfset var databaseType = "">

		<cfloop list="#arguments.tableNames#" index="tableName">
			<cfif not tableExists(tableName)>
				<cfset missing = listAppend(missing, tableName)>
			</cfif>
		</cfloop>
		<cfif not len(missing)>
			<cfset addToLog("The #replace(arguments.tableNames, ',', ', ', 'all')# tables already exist.")>
			<cfreturn>
		</cfif>

		<cfset addToLog("Missing: #replace(missing, ',', ', ', 'all')#. Setting the column types for this database and reloading ORM to create them.")>
		<cfset databaseType = getProfileString(variables.iniPath, "default", "databaseType")>
		<cfif len(databaseType)>
			<cfset createObject("component", replace(application.databaseUpdaterComponentPath, "DatabaseUpdater", "DatabaseOrmTypes")).apply(databaseType, variables.rootDirectory & "common/cfc/db/galaxieDb/")>
			<!--- Application.cfc then knows the types are set for this database and does not apply them again. --->
			<cfset application.ormTypesAppliedFor = databaseType & "|" & variables.rootDirectory>
		</cfif>
		<cfset ORMReload()>

		<cfloop list="#missing#" index="tableName">
			<cfif not tableExists(tableName)>
				<cfthrow message="The #tableName# table could not be created. Make sure every file of this version was uploaded (including the common/cfc/db/galaxieDb folder), restart the blog and run the update again.">
			</cfif>
			<cfset addToLog("Created the #tableName# table.")>
		</cfloop>

	</cffunction>

	<cffunction name="ensureColumns" access="public" returnType="void" output="false"
			hint="Adds text columns that a release added to an entity, if they are missing (5.0, 2026-10-19). ORM adds them by itself when the application starts with the new entity files, but until it does every page that reads them fails; this makes the update itself certain. Each column is added as a nullable VARCHAR of its length, as ORM makes them. Safe to run more than once.">
		<cfargument name="tableName" type="string" required="true">
		<cfargument name="columns" type="array" required="true" hint="An array of { name, length } structs, eg. [ { name: 'HeroStyle', length: 20 } ].">

		<cfset var column = "">
		<cfset var flavorName = "">
		<cfset var databaseOrmTypesObj = "">
		<cfset var quote = "">
		<cfset var alterSql = "">

		<cfif not reFind("^[A-Za-z][A-Za-z0-9_]*$", arguments.tableName) or not tableExists(arguments.tableName)>
			<cfset addToLog("Skipped the columns of '#arguments.tableName#': there is no such table.")>
			<cfreturn>
		</cfif>
		<cfif not len(application.databaseType ?: "")>
			<cfset application.databaseType = getProfileString(variables.iniPath, "default", "databaseType")>
		</cfif>
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset databaseOrmTypesObj = createObject("component", application.baseComponentPath & ".common.cfc.DatabaseOrmTypes")>
		<cfelse>
			<cfset databaseOrmTypesObj = createObject("component", "common.cfc.DatabaseOrmTypes")>
		</cfif>
		<cfset flavorName = databaseOrmTypesObj.getFlavorName(application.databaseType)>
		<!--- PostgreSQL keeps the mixed-case names ORM made only inside double quotes (globally_quoted_identifiers). --->
		<cfset quote = flavorName eq "postgre" ? '"' : "">

		<cfloop array="#arguments.columns#" index="column">
			<cfif not reFind("^[A-Za-z][A-Za-z0-9_]*$", column.name) or not isNumeric(column.length)>
				<cfset addToLog("Skipped the column '#column.name#': not a valid column.")>
				<cfcontinue>
			</cfif>
			<cfif columnExists(arguments.tableName, column.name, quote)>
				<cfcontinue>
			</cfif>
			<cfswitch expression="#flavorName#">
				<cfcase value="sqlServer"><cfset alterSql = "ALTER TABLE #arguments.tableName# ADD #column.name# VARCHAR(#int(column.length)#) NULL"></cfcase>
				<cfcase value="mySql"><cfset alterSql = "ALTER TABLE #arguments.tableName# ADD COLUMN #column.name# VARCHAR(#int(column.length)#) NULL"></cfcase>
				<cfcase value="postgre"><cfset alterSql = 'ALTER TABLE "#arguments.tableName#" ADD COLUMN "#column.name#" VARCHAR(#int(column.length)#) NULL'></cfcase>
				<cfdefaultcase>
					<cfset addToLog("Could not add #arguments.tableName#.#column.name# on this database (#application.databaseType#); restarting the blog lets ORM add it.")>
					<cfcontinue>
				</cfdefaultcase>
			</cfswitch>
			<cftry>
				<cfquery datasource="#application.dsn#">#alterSql#</cfquery>
				<cfset addToLog("Added the column #arguments.tableName#.#column.name#.")>
				<cfcatch type="database">
					<!--- Another request (or ORM, on an application start) may have added it in the meantime. --->
					<cfif not columnExists(arguments.tableName, column.name, quote)>
						<cfrethrow>
					</cfif>
				</cfcatch>
			</cftry>
		</cfloop>

	</cffunction>

	<cffunction name="ensureLogIndexes" access="public" returnType="void" output="false"
			hint="The indexes the visitor log and its lookups need (2026-10-27). ORM creates these tables with primary keys only, so a blog's visitor tracking, ban checks, traffic cards and log clean-up read through whole tables, and got slower as the logs grew (gregoryalexander.com and galaxieblog.org, 10-23 to 10-27). Run by a new install and by the 5.0 update; adds only what is missing, never fails the caller.">
		<cfset ensureIndexes([
			{ name: "IX_IpAddress_IpAddress", table: "IpAddress", columns: [ { name: "IpAddress", prefix: 64 } ] },
			{ name: "IX_HttpUserAgent_HttpUserAgent", table: "HttpUserAgent", columns: [ { name: "HttpUserAgent", prefix: 191 } ] },
			{ name: "IX_HttpReferrer_HttpReferrer", table: "HttpReferrer", columns: [ { name: "HttpReferrer", prefix: 191 } ] },
			{ name: "IX_AnonymousUser_IpAddressRef_HttpUserAgentRef", table: "AnonymousUser", columns: [ { name: "IpAddressRef" }, { name: "HttpUserAgentRef" } ] },
			{ name: "IX_AnonymousUser_Date", table: "AnonymousUser", columns: [ { name: "Date" } ] },
			{ name: "IX_VisitorLog_AnonymousUserRef", table: "VisitorLog", columns: [ { name: "AnonymousUserRef" } ] },
			{ name: "IX_VisitorLog_Date", table: "VisitorLog", columns: [ { name: "Date" } ] },
			{ name: "IX_VisitorLog_HttpReferrerRef", table: "VisitorLog", columns: [ { name: "HttpReferrerRef" } ] },
			{ name: "IX_VisitorLog_PostRef_Date", table: "VisitorLog", columns: [ { name: "PostRef" }, { name: "Date" } ] },
			{ name: "IX_PostRead_AnonymousUserRef", table: "PostRead", columns: [ { name: "AnonymousUserRef" } ] },
			{ name: "IX_PostRead_Date_PostRef", table: "PostRead", columns: [ { name: "Date" }, { name: "PostRef" } ] },
			{ name: "IX_AdminLog_AnonymousUserRef", table: "AdminLog", columns: [ { name: "AnonymousUserRef" } ] },
			{ name: "IX_ErrorLog_AnonymousUserRef", table: "ErrorLog", columns: [ { name: "AnonymousUserRef" } ] },
			{ name: "IX_PostRating_AnonymousUserRef", table: "PostRating", columns: [ { name: "AnonymousUserRef" } ] },
			{ name: "IX_Subscriber_AnonymousUserRef", table: "Subscriber", columns: [ { name: "AnonymousUserRef" } ] },
			{ name: "IX_SearchQuery_AnonymousUserRef", table: "SearchQuery", columns: [ { name: "AnonymousUserRef" } ] }
		])>
	</cffunction>

	<cffunction name="ensureIndexes" access="public" returnType="void" output="false"
			hint="Adds indexes that are missing (2026-10-27). Each is an { name, table, columns: [ { name, prefix (optional: how many characters of a text column MySQL/MariaDB index) } ] }. Skipped when the table or a column is missing, or when the table already has an index that starts with the same column (whatever its name: one made by hand, or the one MySQL makes for a foreign key). Errors are logged, never thrown.">
		<cfargument name="indexes" type="array" required="true">
		<cfset var ix = "">
		<cfset var col = "">
		<cfset var flavorName = "">
		<cfset var databaseOrmTypesObj = "">
		<cfset var found = "">
		<cfset var colList = "">
		<cfset var createSql = "">
		<cfset var valid = true>
		<cftry>
			<cfif not len(application.databaseType ?: "")>
				<cfset application.databaseType = getProfileString(variables.iniPath, "default", "databaseType")>
			</cfif>
			<cfif len(application.baseProxyUrl ?: "") gt 0>
				<cfset databaseOrmTypesObj = createObject("component", application.baseComponentPath & ".common.cfc.DatabaseOrmTypes")>
			<cfelse>
				<cfset databaseOrmTypesObj = createObject("component", "common.cfc.DatabaseOrmTypes")>
			</cfif>
			<cfset flavorName = databaseOrmTypesObj.getFlavorName(application.databaseType)>
			<cfcatch type="any">
				<cfset addToLog("Indexes skipped: the database type could not be read (#cfcatch.message#).")>
				<cfreturn>
			</cfcatch>
		</cftry>
		<cfloop array="#arguments.indexes#" index="ix">
			<cftry>
				<cfset valid = reFind("^[A-Za-z][A-Za-z0-9_]*$", ix.name) and tableExists(ix.table)>
				<cfif valid>
					<cfloop array="#ix.columns#" index="col">
						<cfif not reFind("^[A-Za-z][A-Za-z0-9_]*$", col.name) or not columnExists(ix.table, col.name, flavorName eq "postgre" ? '"' : "")><cfset valid = false></cfif>
					</cfloop>
				</cfif>
				<cfif not valid>
					<cfcontinue>
				</cfif>
				<!--- Already indexed on this column? --->
				<cfswitch expression="#flavorName#">
					<cfcase value="sqlServer">
						<cfquery name="found" datasource="#application.dsn#">
							SELECT COUNT(*) AS n FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
							WHERE ic.object_id = OBJECT_ID(<cfqueryparam value="#ix.table#" cfsqltype="cf_sql_varchar">) AND ic.key_ordinal = 1
							AND c.name = <cfqueryparam value="#ix.columns[1].name#" cfsqltype="cf_sql_varchar">
						</cfquery>
					</cfcase>
					<cfcase value="mySql">
						<cfquery name="found" datasource="#application.dsn#">
							SELECT COUNT(*) AS n FROM information_schema.STATISTICS
							WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = <cfqueryparam value="#ix.table#" cfsqltype="cf_sql_varchar">
							AND COLUMN_NAME = <cfqueryparam value="#ix.columns[1].name#" cfsqltype="cf_sql_varchar"> AND SEQ_IN_INDEX = 1
						</cfquery>
					</cfcase>
					<cfcase value="postgre">
						<cfquery name="found" datasource="#application.dsn#">
							SELECT COUNT(*) AS n FROM pg_indexes WHERE indexname IN (<cfqueryparam value="#lCase(ix.name)#" cfsqltype="cf_sql_varchar">, <cfqueryparam value="#ix.name#" cfsqltype="cf_sql_varchar">)
						</cfquery>
					</cfcase>
					<cfdefaultcase>
						<cfset addToLog("Index #ix.name# not added: no index statement for this database (#application.databaseType#).")>
						<cfcontinue>
					</cfdefaultcase>
				</cfswitch>
				<cfif val(found.n) gt 0>
					<cfcontinue>
				</cfif>
				<cfset colList = "">
				<cfloop array="#ix.columns#" index="col">
					<cfswitch expression="#flavorName#">
						<cfcase value="sqlServer"><cfset colList = listAppend(colList, "[#col.name#]")></cfcase>
						<cfcase value="mySql">
							<!--- A prefix only on a text column longer than it (MySQL refuses a prefix as long as the column, eg. IpAddress). --->
							<cfif structKeyExists(col, "prefix")>
								<cfquery name="found" datasource="#application.dsn#">
									SELECT CHARACTER_MAXIMUM_LENGTH AS len FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()
									AND TABLE_NAME = <cfqueryparam value="#ix.table#" cfsqltype="cf_sql_varchar"> AND COLUMN_NAME = <cfqueryparam value="#col.name#" cfsqltype="cf_sql_varchar">
								</cfquery>
							</cfif>
							<cfset colList = listAppend(colList, "`#col.name#`" & (structKeyExists(col, "prefix") and (not isNumeric(found.len) or found.len gt col.prefix) ? "(#int(col.prefix)#)" : ""))>
						</cfcase>
						<cfcase value="postgre"><cfset colList = listAppend(colList, '"#col.name#"')></cfcase>
					</cfswitch>
				</cfloop>
				<cfswitch expression="#flavorName#">
					<cfcase value="sqlServer"><cfset createSql = "CREATE NONCLUSTERED INDEX [#ix.name#] ON [#ix.table#] (#colList#)"></cfcase>
					<cfcase value="mySql"><cfset createSql = "CREATE INDEX `#ix.name#` ON `#ix.table#` (#colList#)"></cfcase>
					<cfcase value="postgre"><cfset createSql = 'CREATE INDEX IF NOT EXISTS "#ix.name#" ON "#ix.table#" (#colList#)'></cfcase>
				</cfswitch>
				<cfquery datasource="#application.dsn#">#createSql#</cfquery>
				<cfset addToLog("Added the index #ix.name#.")>
				<cfcatch type="any">
					<cfset addToLog("Index #ix.name# not added: #cfcatch.message#")>
				</cfcatch>
			</cftry>
		</cfloop>
	</cffunction>

	<cffunction name="columnExists" access="private"returnType="boolean" output="false" hint="Whether a column exists: selecting it from no rows succeeds if it does.">
		<cfargument name="tableName" type="string" required="true">
		<cfargument name="columnName" type="string" required="true">
		<cfargument name="quote" type="string" required="false" default="">
		<cftry>
			<cfquery datasource="#application.dsn#">
				SELECT #arguments.quote##arguments.columnName##arguments.quote# FROM #arguments.quote##arguments.tableName##arguments.quote# WHERE 1 = 0
			</cfquery>
			<cfreturn true>
			<cfcatch type="database">
				<cfreturn false>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="tableExists" access="private" returnType="boolean" output="false"
			hint="Whether a table exists in the blog's own database: selecting nothing from it succeeds if it does. (INFORMATION_SCHEMA is not used, as on MySQL and MariaDB it lists the tables of every database on the server - see createTableIfMissing.)">
		<cfargument name="tableName" type="string" required="true">

		<cfif not reFind("^[A-Za-z][A-Za-z0-9_]*$", arguments.tableName)>
			<cfreturn false>
		</cfif>
		<cftry>
			<cfquery datasource="#application.dsn#">
				SELECT 1 FROM #arguments.tableName# WHERE 1 = 0
			</cfquery>
			<cfreturn true>
			<cfcatch type="database">
				<cfreturn false>
			</cfcatch>
		</cftry>

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
