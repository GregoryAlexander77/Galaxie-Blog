<cfcomponent displayName="AdminNotes" output="false" hint="Private notes on the things an admin manages (2026-10-22, owner: like the notes fields in the ColdFusion Administrator): a post, a product, an order, a booking type, an event, a form, a scene, a theme, Blog Options and Blog Settings. One table for all of them; shown only in the admin, never on the site. Used through blog.cfc getAdminNotes() and admin/adminInterface/adminNotes.cfm.">

<!--- What a note can be on. Blog Options and Blog Settings have one note each (item 1). --->
<cfset variables.kinds = "post,product,order,bookingType,event,form,scene,theme,blogOptions,blogSettings">

<cffunction name="isKind" access="public" returntype="boolean" output="false">
	<cfargument name="kind" type="string" required="true">
	<cfreturn listFind(variables.kinds, arguments.kind) gt 0>
</cffunction>

<cffunction name="getNote" access="public" returntype="struct" output="false" hint="{ note, updatedBy, updated } - empty when there is no note.">
	<cfargument name="kind" type="string" required="true">
	<cfargument name="itemId" type="numeric" required="true">
	<cfset var result = { note: "", updatedBy: "", updated: "" }>
	<cfset var row = "">
	<cfif not isKind(arguments.kind) or arguments.itemId lte 0>
		<cfreturn result>
	</cfif>
	<cfset ensureTable()>
	<cfset row = queryExecute("SELECT Note, UpdatedBy, Updated FROM AdminNote WHERE BlogRef = :blogId AND Kind = :kind AND ItemId = :itemId",
		{ blogId: { value: blogId(), cfsqltype: "cf_sql_integer" }, kind: { value: arguments.kind, cfsqltype: "cf_sql_varchar" },
		  itemId: { value: arguments.itemId, cfsqltype: "cf_sql_integer" } })>
	<cfif row.recordCount>
		<cfset result.note = toString(row.Note)>
		<cfset result.updatedBy = toString(row.UpdatedBy)>
		<cfset result.updated = isDate(row.Updated) ? dateFormat(row.Updated, "mmm d, yyyy") & " " & timeFormat(row.Updated, "h:mm tt") : "">
	</cfif>
	<cfreturn result>
</cffunction>

<cffunction name="saveNote" access="public" returntype="struct" output="false" hint="Saves (or, when empty, removes) a note. Returns getNote's shape.">
	<cfargument name="kind" type="string" required="true">
	<cfargument name="itemId" type="numeric" required="true">
	<cfargument name="note" type="string" required="true">
	<cfargument name="updatedBy" type="string" required="false" default="">
	<cfset var params = "">
	<cfset var found = "">
	<cfif not isKind(arguments.kind) or arguments.itemId lte 0>
		<cfthrow message="Notes can't be saved on that.">
	</cfif>
	<cfset ensureTable()>
	<cfset params = { blogId: { value: blogId(), cfsqltype: "cf_sql_integer" }, kind: { value: arguments.kind, cfsqltype: "cf_sql_varchar" },
		itemId: { value: arguments.itemId, cfsqltype: "cf_sql_integer" } }>
	<cfif not len(trim(arguments.note))>
		<cfset queryExecute("DELETE FROM AdminNote WHERE BlogRef = :blogId AND Kind = :kind AND ItemId = :itemId", params)>
		<cfreturn { note: "", updatedBy: "", updated: "" }>
	</cfif>
	<cfset params.note = { value: left(arguments.note, 20000), cfsqltype: "cf_sql_longvarchar" }>
	<cfset params.updatedBy = { value: left(arguments.updatedBy, 125), cfsqltype: "cf_sql_varchar" }>
	<cfset params.updated = { value: now(), cfsqltype: "cf_sql_timestamp" }>
	<cfset found = queryExecute("SELECT AdminNoteId FROM AdminNote WHERE BlogRef = :blogId AND Kind = :kind AND ItemId = :itemId", params)>
	<cfif found.recordCount>
		<cfset queryExecute("UPDATE AdminNote SET Note = :note, UpdatedBy = :updatedBy, Updated = :updated WHERE AdminNoteId = :id",
			{ note: params.note, updatedBy: params.updatedBy, updated: params.updated, id: { value: found.AdminNoteId, cfsqltype: "cf_sql_integer" } })>
	<cfelse>
		<cfset queryExecute("INSERT INTO AdminNote (BlogRef, Kind, ItemId, Note, UpdatedBy, Updated) VALUES (:blogId, :kind, :itemId, :note, :updatedBy, :updated)", params)>
	</cfif>
	<cfreturn getNote(arguments.kind, arguments.itemId)>
</cffunction>

<cffunction name="blogId" access="private" returntype="numeric" output="false">
	<cfreturn application.BlogDbObj.getBlogId()>
</cffunction>

<cffunction name="ensureTable" access="private" returntype="void" output="false" hint="Creates the AdminNote table the first time it's needed, once per application start.">
	<cfset var updater = "">
	<cfif structKeyExists(variables, "tableReady")>
		<cfreturn>
	</cfif>
	<cflock name="galaxieAdminNotes_#application.applicationName#" type="exclusive" timeout="30">
		<cfif not structKeyExists(variables, "tableReady")>
			<cfset updater = createObject("component", len(application.baseProxyUrl) ? application.baseComponentPath & ".common.cfc.DatabaseUpdater" : "common.cfc.DatabaseUpdater").init(application.rootDirectoryPath, application.blogIniPath)>
			<!--- createTableIfMissing picks the SQL by application.databaseType, which only the updater sets (see Scenes.cfc ensureTables). --->
			<cfif not len(application.databaseType ?: "")>
				<cfset application.databaseType = getProfileString(application.blogIniPath, "default", "databaseType")>
			</cfif>
			<cfset updater.createTableIfMissing("AdminNote", {
				sqlServer: "CREATE TABLE AdminNote (AdminNoteId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, BlogRef INT NOT NULL, Kind NVARCHAR(30) NOT NULL, ItemId INT NOT NULL, Note NVARCHAR(MAX) NULL, UpdatedBy NVARCHAR(125) NULL, Updated DATETIME NOT NULL)",
				mySql: "CREATE TABLE AdminNote (AdminNoteId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, BlogRef INT NOT NULL, Kind VARCHAR(30) NOT NULL, ItemId INT NOT NULL, Note LONGTEXT NULL, UpdatedBy VARCHAR(125) NULL, Updated DATETIME NOT NULL) DEFAULT CHARSET=utf8mb4",
				postgre: "CREATE TABLE AdminNote (AdminNoteId SERIAL PRIMARY KEY, BlogRef INT NOT NULL, Kind VARCHAR(30) NOT NULL, ItemId INT NOT NULL, Note TEXT NULL, UpdatedBy VARCHAR(125) NULL, Updated TIMESTAMP NOT NULL)"
			})>
			<cfset variables.tableReady = true>
		</cfif>
	</cflock>
</cffunction>

</cfcomponent>
