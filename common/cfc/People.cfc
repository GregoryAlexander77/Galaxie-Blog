<cfcomponent displayName="People" output="false" hint="People cards (2026-10-16): the author card that opens from a byline or an event's organizer - picture, name, biography, links, and a contact form that emails the person directly. Every active admin user has a card built from their own profile (Users); admins can also add cards for people who never sign in, eg. a guest presenter (the PersonCard table). A card is referred to as 'user:5' or 'guest:3'. Use getPeople() in ProxyController / Events.cfc, which creates this component on demand (it is not wired into Application.cfc).">

<!--- ********************************************************************************************************************
	The PersonCard table is plain SQL (not an ORM entity), so it can be added to a running blog without an ORM reload or a
	database update: it is created the first time this component starts.
********************************************************************************************************************* --->

<cffunction name="init" access="public" returntype="any" output="false">
	<cfset ensureTable()>
	<cfreturn this>
</cffunction>

<cffunction name="ensureTable" access="private" returntype="void" output="false" hint="Creates the PersonCard table if it isn't there yet (DatabaseUpdater.createTableIfMissing).">
	<cfset var updaterPath = len(application.baseProxyUrl) ? application.baseComponentPath & ".common.cfc.DatabaseUpdater" : "common.cfc.DatabaseUpdater">
	<cfset var updater = createObject("component", updaterPath).init(application.rootDirectoryPath, application.blogIniPath)>
	<!--- createTableIfMissing picks the SQL by application.databaseType, which only the updater sets; read it from the ini, as
	DatabaseUpdater.ensureOrmTables does. --->
	<cfif not len(application.databaseType ?: "")>
		<cfset application.databaseType = getProfileString(application.blogIniPath, "default", "databaseType")>
	</cfif>
	<cfset updater.createTableIfMissing("PersonCard", {
		sqlServer: "CREATE TABLE PersonCard (PersonCardId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, BlogRef INT NOT NULL, DisplayName NVARCHAR(125) NOT NULL, Email NVARCHAR(255) NOT NULL, Website NVARCHAR(500) NULL, ProfilePicture NVARCHAR(500) NULL, Biography NVARCHAR(4000) NULL, FacebookUrl NVARCHAR(500) NULL, LinkedInUrl NVARCHAR(500) NULL, InstagramUrl NVARCHAR(500) NULL, TwitterUrl NVARCHAR(500) NULL, Active BIT NOT NULL, Created DATETIME NOT NULL, Updated DATETIME NOT NULL)",
		mySql: "CREATE TABLE PersonCard (PersonCardId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, BlogRef INT NOT NULL, DisplayName VARCHAR(125) NOT NULL, Email VARCHAR(255) NOT NULL, Website VARCHAR(500) NULL, ProfilePicture VARCHAR(500) NULL, Biography TEXT NULL, FacebookUrl VARCHAR(500) NULL, LinkedInUrl VARCHAR(500) NULL, InstagramUrl VARCHAR(500) NULL, TwitterUrl VARCHAR(500) NULL, Active TINYINT(1) NOT NULL, Created DATETIME NOT NULL, Updated DATETIME NOT NULL) DEFAULT CHARSET=utf8mb4",
		postgre: "CREATE TABLE PersonCard (PersonCardId SERIAL PRIMARY KEY, BlogRef INT NOT NULL, DisplayName VARCHAR(125) NOT NULL, Email VARCHAR(255) NOT NULL, Website VARCHAR(500) NULL, ProfilePicture VARCHAR(500) NULL, Biography TEXT NULL, FacebookUrl VARCHAR(500) NULL, LinkedInUrl VARCHAR(500) NULL, InstagramUrl VARCHAR(500) NULL, TwitterUrl VARCHAR(500) NULL, Active BOOLEAN NOT NULL, Created TIMESTAMP NOT NULL, Updated TIMESTAMP NOT NULL)"
	})>
</cffunction>

<!--- ********************************************************************************************************************
	Reading
********************************************************************************************************************* --->

<cffunction name="isRef" access="public" returntype="boolean" output="false" hint="Whether a value is a card reference, 'user:5' or 'guest:3'.">
	<cfargument name="ref" type="string" required="true">
	<cfreturn reFind("^(user|guest):[0-9]+$", arguments.ref) gt 0>
</cffunction>

<cffunction name="getCards" access="public" returntype="array" output="false"
		hint="Every card for the admin's dropdowns and the People window: the active users first (alphabetical), then the guest cards. No email addresses (getCard with includeEmail for that).">
	<cfargument name="includeInactiveGuests" type="boolean" required="false" default="false">
	<cfset var cards = []>
	<cfset var rows = "">
	<cfset rows = queryExecute("
		SELECT UserId FROM Users WHERE BlogRef = :blogId AND Active = 1 ORDER BY FullName",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
	<cfloop query="rows">
		<cfset arrayAppend(cards, getCard("user:" & rows.UserId))>
	</cfloop>
	<cfset rows = queryExecute("
		SELECT PersonCardId FROM PersonCard WHERE BlogRef = :blogId" & (arguments.includeInactiveGuests ? "" : " AND Active = 1") & " ORDER BY DisplayName",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
	<cfloop query="rows">
		<cfset arrayAppend(cards, getCard("guest:" & rows.PersonCardId))>
	</cfloop>
	<cfreturn arrayFilter(cards, function(card) { return not structIsEmpty(card); })>
</cffunction>

<cffunction name="getCard" access="public" returntype="struct" output="false"
		hint="One card, or an empty struct: { ref, kind (user|guest), id, name, picture, biography, website, facebookUrl, linkedInUrl, instagramUrl, twitterUrl, postsUrl (users with released posts), active }, plus email when includeEmail (never shown on the site unless a user's profile chooses to show it).">
	<cfargument name="ref" type="string" required="true">
	<cfargument name="includeEmail" type="boolean" required="false" default="false">
	<cfset var card = {}>
	<cfset var kind = listFirst(arguments.ref, ":")>
	<cfset var id = val(listLast(arguments.ref, ":"))>
	<cfset var row = "">
	<cfset var posts = "">
	<cfif not isRef(arguments.ref)>
		<cfreturn {}>
	</cfif>
	<cfif kind eq "user">
		<cfset row = queryExecute("
			SELECT UserId, FullName, DisplayName, Email, DisplayEmailOnBio, Website, ProfilePicture, Biography, FacebookUrl, LinkedInUrl, InstagramUrl, TwitterUrl, Active
			FROM Users WHERE UserId = :id AND BlogRef = :blogId",
			{ id = { value = id, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
		<cfif not row.recordCount>
			<cfreturn {}>
		</cfif>
		<cfset posts = queryExecute("
			SELECT COUNT(*) AS PostCount FROM Post WHERE UserRef = :id AND Released = 1 AND Remove = 0 AND IsPage = 0",
			{ id = { value = id, cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
		<cfset card = {
			ref: arguments.ref, kind: "user", id: id,
			name: len(trim(valueOrEmpty(row.DisplayName))) ? trim(row.DisplayName) : trim(valueOrEmpty(row.FullName)),
			picture: valueOrEmpty(row.ProfilePicture), biography: valueOrEmpty(row.Biography), website: valueOrEmpty(row.Website),
			facebookUrl: valueOrEmpty(row.FacebookUrl), linkedInUrl: valueOrEmpty(row.LinkedInUrl), instagramUrl: valueOrEmpty(row.InstagramUrl), twitterUrl: valueOrEmpty(row.TwitterUrl),
			postsUrl: val(posts.PostCount) ? application.blog.makeUserLink(valueOrEmpty(row.FullName)) : "",
			showEmail: isBoolean(row.DisplayEmailOnBio) and row.DisplayEmailOnBio,
			active: isBoolean(row.Active) and row.Active
		}>
		<cfif card.showEmail or arguments.includeEmail><cfset card[ "email" ] = valueOrEmpty(row.Email)></cfif>
	<cfelse>
		<cfset row = queryExecute("
			SELECT PersonCardId, DisplayName, Email, Website, ProfilePicture, Biography, FacebookUrl, LinkedInUrl, InstagramUrl, TwitterUrl, Active
			FROM PersonCard WHERE PersonCardId = :id AND BlogRef = :blogId",
			{ id = { value = id, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
		<cfif not row.recordCount>
			<cfreturn {}>
		</cfif>
		<cfset card = {
			ref: arguments.ref, kind: "guest", id: id, name: trim(row.DisplayName),
			picture: valueOrEmpty(row.ProfilePicture), biography: valueOrEmpty(row.Biography), website: valueOrEmpty(row.Website),
			facebookUrl: valueOrEmpty(row.FacebookUrl), linkedInUrl: valueOrEmpty(row.LinkedInUrl), instagramUrl: valueOrEmpty(row.InstagramUrl), twitterUrl: valueOrEmpty(row.TwitterUrl),
			postsUrl: "", showEmail: false, active: isTrue(row.Active)
		}>
		<cfif arguments.includeEmail><cfset card[ "email" ] = valueOrEmpty(row.Email)></cfif>
	</cfif>
	<cfreturn card>
</cffunction>

<cffunction name="getEventsUsing" access="public" returntype="array" output="false" hint="The titles of the posts whose event names this card as its organizer.">
	<cfargument name="ref" type="string" required="true">
	<cfset var rows = queryExecute("
		SELECT p.Title FROM BlogEvent e INNER JOIN Post p ON p.PostId = e.PostRef
		WHERE e.BlogRef = :blogId AND e.OrganizerUrl = :url",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, url = { value = "person:" & arguments.ref, cfsqltype = "cf_sql_varchar" } }, { datasource = application.dsn })>
	<cfreturn listToArray(valueList(rows.Title, chr(30)), chr(30))>
</cffunction>

<!--- ********************************************************************************************************************
	Guest cards (admin)
********************************************************************************************************************* --->

<cffunction name="saveGuest" access="public" returntype="struct" output="false"
		hint="Adds or updates a guest card. Name and email are required (the contact form always emails the person). Returns { success, errors, ref }.">
	<cfargument name="data" type="struct" required="true" hint="personCardId (0 = new), displayName, email, website, profilePicture, biography, facebookUrl, linkedInUrl, instagramUrl, twitterUrl, active.">
	<cfset var result = { success: false, errors: [], ref: "" }>
	<cfset var d = {}>
	<cfset var field = "">
	<cfset var id = val(structKeyExists(arguments.data, "personCardId") ? arguments.data.personCardId : 0)>
	<cfset var params = {}>
	<cfset var inserted = "">
	<cfloop list="displayName,email,website,profilePicture,biography,facebookUrl,linkedInUrl,instagramUrl,twitterUrl" index="field">
		<cfset d[field] = structKeyExists(arguments.data, field) ? trim(toString(arguments.data[field])) : "">
	</cfloop>
	<cfset d.active = structKeyExists(arguments.data, "active") and isTrue(arguments.data.active)>
	<cfif not len(d.displayName)><cfset arrayAppend(result.errors, "Enter the person's name.")></cfif>
	<cfif len(d.displayName) gt 125><cfset arrayAppend(result.errors, "The name is too long.")></cfif>
	<cfif not len(d.email) or not isValid("email", d.email)><cfset arrayAppend(result.errors, "Enter a valid email address: visitors' messages are sent there.")></cfif>
	<cfif len(d.biography) gt 4000><cfset arrayAppend(result.errors, "The biography is too long (4000 characters at most).")></cfif>
	<cfloop list="website,profilePicture,facebookUrl,linkedInUrl,instagramUrl,twitterUrl" index="field">
		<cfif len(d[field]) and not (reFindNoCase("^https?://", d[field]) or (field eq "profilePicture" and left(d[field], 1) eq "/"))>
			<cfset arrayAppend(result.errors, "The " & (field eq "profilePicture" ? "picture" : (field eq "website" ? "website" : replaceNoCase(field, "Url", ""))) & " link has to start with http:// or https://" & (field eq "profilePicture" ? " (or /, for a picture on this site)" : "") & ".")>
		</cfif>
		<cfif len(d[field]) gt 500><cfset arrayAppend(result.errors, "A link is too long.")></cfif>
	</cfloop>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>
	<cfset params = {
		blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" },
		displayName = { value = d.displayName, cfsqltype = "cf_sql_varchar" }, email = { value = d.email, cfsqltype = "cf_sql_varchar" },
		website = { value = d.website, cfsqltype = "cf_sql_varchar" }, profilePicture = { value = d.profilePicture, cfsqltype = "cf_sql_varchar" },
		biography = { value = d.biography, cfsqltype = "cf_sql_longvarchar" },
		facebookUrl = { value = d.facebookUrl, cfsqltype = "cf_sql_varchar" }, linkedInUrl = { value = d.linkedInUrl, cfsqltype = "cf_sql_varchar" },
		instagramUrl = { value = d.instagramUrl, cfsqltype = "cf_sql_varchar" }, twitterUrl = { value = d.twitterUrl, cfsqltype = "cf_sql_varchar" },
		active = { value = d.active, cfsqltype = "cf_sql_bit" }, now = { value = now(), cfsqltype = "cf_sql_timestamp" }
	}>
	<cfif id gt 0>
		<cfset params.id = { value = id, cfsqltype = "cf_sql_integer" }>
		<cfset queryExecute("
			UPDATE PersonCard SET DisplayName = :displayName, Email = :email, Website = :website, ProfilePicture = :profilePicture, Biography = :biography,
				FacebookUrl = :facebookUrl, LinkedInUrl = :linkedInUrl, InstagramUrl = :instagramUrl, TwitterUrl = :twitterUrl, Active = :active, Updated = :now
			WHERE PersonCardId = :id AND BlogRef = :blogId", params, { datasource = application.dsn })>
	<cfelse>
		<cfset queryExecute("
			INSERT INTO PersonCard (BlogRef, DisplayName, Email, Website, ProfilePicture, Biography, FacebookUrl, LinkedInUrl, InstagramUrl, TwitterUrl, Active, Created, Updated)
			VALUES (:blogId, :displayName, :email, :website, :profilePicture, :biography, :facebookUrl, :linkedInUrl, :instagramUrl, :twitterUrl, :active, :now, :now)",
			params, { datasource = application.dsn, result = "inserted" })>
		<cfset id = val(structKeyExists(inserted, "generatedKey") ? inserted.generatedKey : (structKeyExists(inserted, "IDENTITYCOL") ? inserted.IDENTITYCOL : 0))>
	</cfif>
	<cfset result.success = true>
	<cfset result.ref = "guest:" & id>
	<cfreturn result>
</cffunction>

<cffunction name="deleteGuest" access="public" returntype="struct" output="false" hint="Deletes a guest card, unless an event names it as its organizer. Returns { success, errorMessage }.">
	<cfargument name="personCardId" type="numeric" required="true">
	<cfset var usedBy = getEventsUsing("guest:" & arguments.personCardId)>
	<cfif arrayLen(usedBy)>
		<cfreturn { success: false, errorMessage: "This person organizes " & arrayToList(usedBy, ", ") & ". Choose another organizer for " & (arrayLen(usedBy) eq 1 ? "that event" : "those events") & " first, or make the card inactive." }>
	</cfif>
	<cfset queryExecute("DELETE FROM PersonCard WHERE PersonCardId = :id AND BlogRef = :blogId",
		{ id = { value = arguments.personCardId, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
	<cfreturn { success: true, errorMessage: "" }>
</cffunction>

<!--- ********************************************************************************************************************
	Messages from the site
********************************************************************************************************************* --->

<cffunction name="sendMessage" access="public" returntype="struct" output="false"
		hint="Emails a visitor's message straight to the person on the card. The person's address is never shown; a reply goes to the visitor (replyTo). Returns { success, errors }.">
	<cfargument name="ref" type="string" required="true">
	<cfargument name="fromName" type="string" required="true">
	<cfargument name="fromEmail" type="string" required="true">
	<cfargument name="message" type="string" required="true">
	<cfset var result = { success: false, errors: [] }>
	<cfset var card = getCard(arguments.ref, true)>
	<cfset var body = "">
	<cfset var blogTitle = application.BlogDbObj.getBlogTitle()>
	<cfif structIsEmpty(card) or not card.active or not len(card.email)>
		<cfset arrayAppend(result.errors, "This person can't be contacted here.")>
		<cfreturn result>
	</cfif>
	<cfif not len(trim(arguments.fromName))><cfset arrayAppend(result.errors, "Enter your name.")></cfif>
	<cfif not isValid("email", trim(arguments.fromEmail))><cfset arrayAppend(result.errors, "Enter a valid email address, so they can reply.")></cfif>
	<cfif not len(trim(arguments.message))><cfset arrayAppend(result.errors, "Enter your message.")></cfif>
	<cfif len(arguments.message) gt 5000><cfset arrayAppend(result.errors, "The message is too long.")></cfif>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>
	<cfset body = "<p>" & encodeForHtml(trim(arguments.fromName)) & " (" & encodeForHtml(trim(arguments.fromEmail)) & ") sent you a message through " & encodeForHtml(blogTitle) & ":</p>"
		& "<blockquote style=""border-left: 3px solid ##ccc; margin: 0; padding: 0 0 0 12px;"">" & replace(encodeForHtml(trim(arguments.message)), chr(10), "<br/>", "all") & "</blockquote>"
		& "<p>Reply to this email to answer them.</p>">
	<cfset createObject("component", application.utilsComponentPath).mail(
		to = card.email,
		subject = trim(arguments.fromName) & " sent you a message through " & blogTitle,
		body = body,
		cc = "",
		replyTo = trim(arguments.fromEmail))>
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	Helpers
********************************************************************************************************************* --->

<cffunction name="valueOrEmpty" access="private" returntype="string" output="false">
	<cfargument name="value" required="false">
	<cfif isNull(arguments.value)><cfreturn ""></cfif>
	<cfreturn toString(arguments.value)>
</cffunction>

<cffunction name="isTrue" access="private" returntype="boolean" output="false">
	<cfargument name="value" required="false">
	<cfreturn not isNull(arguments.value) and isBoolean(arguments.value) and arguments.value>
</cffunction>

</cfcomponent>
