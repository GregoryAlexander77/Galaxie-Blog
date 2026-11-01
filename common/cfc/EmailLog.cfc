<cfcomponent displayName="EmailLog" output="false" hint="The email sent log (5.0.x, 2026-10-31, owner): what the blog sent - when, to whom, what kind, the subject, and whether it went to the mail server or failed. Never the message itself, so never a sign-in link. Written by org/camden/blog/utils.cfc mail() for every email; shown in the admin's Email Log window (118). One table, made on first use like AdminNotes.cfc; kept for 90 days. Used through blog.cfc getEmailLog().">

<!--- What sent it: the function that called utils.cfc mail(), in words. A function not listed here shows its own name. --->
<cfset variables.kinds = {
	"sendPostEmailToSubscribers": "New post",
	"addComment": "Comment",
	"saveComment": "Comment",
	"postCommentSubscribe": "Comment or contact",
	"updateCommentViaJsGrid": "Comment approved",
	"updateCommentViaKendoGrid": "Comment approved",
	"sendCommentReplyEmail": "Comment reply",
	"subscribe": "Subscription",
	"emailWebFormSubmission": "Form",
	"sendRsvpEmails": "Event sign-up",
	"sendSignInEmail": "Member sign-in link",
	"sendMessage": "Message",
	"saveUser": "New user",
	"saveErrorLog": "Error",
	"sendEmail": "Error summary",
	"sendTestEmail": "Test",
	"sendSettingsTestEmail": "Test"
}>
<!--- A sendOneEmail is a booking's or an order's, told apart by the component. --->
<cfset variables.kindsByTemplate = { "Bookings.cfc": "Booking", "Shop.cfc": "Shop order", "newBlogHello.cfm": "New blog note" }>
<cfset variables.keepDays = 90>

<cffunction name="add" access="public" returntype="void" output="false" hint="Records one email. Never throws: a log that can't be written must not stop the email.">
	<cfargument name="to" type="string" required="true">
	<cfargument name="subject" type="string" required="true">
	<cfargument name="status" type="string" required="true" hint="Sent or Failed.">
	<cfargument name="kind" type="string" required="false" default="" hint="Empty: worked out from the function that sent it.">
	<cfargument name="errorMessage" type="string" required="false" default="">
	<cftry>
		<cfset ensureTable()>
		<cfset queryExecute("INSERT INTO EmailLog (BlogRef, Sent, ToAddress, Subject, Kind, Status, ErrorMessage) VALUES (:blogId, :sent, :toAddress, :subject, :kind, :status, :errorMessage)", {
			blogId: { value: application.BlogDbObj.getBlogId(), cfsqltype: "cf_sql_integer" },
			sent: { value: now(), cfsqltype: "cf_sql_timestamp" },
			toAddress: { value: left(trim(arguments.to), 500), cfsqltype: "cf_sql_varchar" },
			subject: { value: left(trim(arguments.subject), 300), cfsqltype: "cf_sql_varchar" },
			kind: { value: left(len(arguments.kind) ? arguments.kind : kindOfCaller(), 60), cfsqltype: "cf_sql_varchar" },
			status: { value: left(arguments.status, 20), cfsqltype: "cf_sql_varchar" },
			errorMessage: { value: left(arguments.errorMessage, 500), cfsqltype: "cf_sql_varchar" }
		})>
		<cfset pruneDaily()>
		<cfcatch type="any">
			<cflog file="galaxieBlogErrors" type="warning" text="Email log not written: #cfcatch.message#">
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="getRows" access="public" returntype="array" output="false" hint="The newest emails first, at most 5,000 (everything kept is 90 days). Each row: EmailLogId, Sent, ToAddress, Kind, Subject, Status, ErrorMessage.">
	<cfset var q = "">
	<cfset var rows = []>
	<cfset ensureTable()>
	<cfset q = queryExecute("SELECT EmailLogId, Sent, ToAddress, Kind, Subject, Status, ErrorMessage FROM EmailLog WHERE BlogRef = :blogId ORDER BY Sent DESC, EmailLogId DESC",
		{ blogId: { value: application.BlogDbObj.getBlogId(), cfsqltype: "cf_sql_integer" } }, { maxrows: 5000 })>
	<cfloop query="q">
		<!--- Quoted keys keep their case on Adobe ColdFusion (the grids read them by name). --->
		<cfset arrayAppend(rows, {
			"EmailLogId": q.EmailLogId,
			"Sent": q.Sent,
			"ToAddress": toString(q.ToAddress),
			"Kind": toString(q.Kind),
			"Subject": toString(q.Subject),
			"Status": toString(q.Status),
			"ErrorMessage": toString(q.ErrorMessage)
		})>
	</cfloop>
	<cfreturn rows>
</cffunction>

<!--- What called utils.cfc mail(): the first function on the call stack that isn't mail() itself. --->
<cffunction name="kindOfCaller" access="private" returntype="string" output="false">
	<cfset var frame = "">
	<cfset var template = "">
	<cfset var functionName = "">
	<cftry>
		<cfloop array="#callStackGet()#" index="frame">
			<cfset template = getFileFromPath(frame.template ?: "")>
			<cfset functionName = frame.function ?: "">
			<cfif template eq "EmailLog.cfc" or (template eq "utils.cfc" and functionName eq "mail")><cfcontinue></cfif>
			<cfif structKeyExists(variables.kindsByTemplate, template)><cfreturn variables.kindsByTemplate[template]></cfif>
			<cfif structKeyExists(variables.kinds, functionName)><cfreturn variables.kinds[functionName]></cfif>
			<cfreturn len(functionName) ? functionName : reReplaceNoCase(template, "\.cf[cm]$", "")>
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfreturn "">
</cffunction>

<!--- Rows older than 90 days go, at most once a day. --->
<cffunction name="pruneDaily" access="private" returntype="void" output="false">
	<cfset var today = dateFormat(now(), "yyyy-mm-dd")>
	<cfif (variables.prunedOn ?: "") eq today><cfreturn></cfif>
	<cfset variables.prunedOn = today>
	<cfset queryExecute("DELETE FROM EmailLog WHERE BlogRef = :blogId AND Sent < :cutoff", {
		blogId: { value: application.BlogDbObj.getBlogId(), cfsqltype: "cf_sql_integer" },
		cutoff: { value: dateAdd("d", -variables.keepDays, now()), cfsqltype: "cf_sql_timestamp" } })>
</cffunction>

<cffunction name="ensureTable" access="private" returntype="void" output="false" hint="Creates the EmailLog table the first time it's needed, once per application start.">
	<cfset var updater = "">
	<cfif structKeyExists(variables, "tableReady")>
		<cfreturn>
	</cfif>
	<cflock name="galaxieEmailLog_#application.applicationName#" type="exclusive" timeout="30">
		<cfif not structKeyExists(variables, "tableReady")>
			<cfset updater = createObject("component", len(application.baseProxyUrl) ? application.baseComponentPath & ".common.cfc.DatabaseUpdater" : "common.cfc.DatabaseUpdater").init(application.rootDirectoryPath, application.blogIniPath)>
			<!--- createTableIfMissing picks the SQL by application.databaseType, which only the updater sets (see AdminNotes.cfc). --->
			<cfif not len(application.databaseType ?: "")>
				<cfset application.databaseType = getProfileString(application.blogIniPath, "default", "databaseType")>
			</cfif>
			<cfset updater.createTableIfMissing("EmailLog", {
				sqlServer: "CREATE TABLE EmailLog (EmailLogId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, BlogRef INT NOT NULL, Sent DATETIME NOT NULL, ToAddress NVARCHAR(500) NULL, Subject NVARCHAR(300) NULL, Kind NVARCHAR(60) NULL, Status NVARCHAR(20) NOT NULL, ErrorMessage NVARCHAR(500) NULL)",
				mySql: "CREATE TABLE EmailLog (EmailLogId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, BlogRef INT NOT NULL, Sent DATETIME NOT NULL, ToAddress VARCHAR(500) NULL, Subject VARCHAR(300) NULL, Kind VARCHAR(60) NULL, Status VARCHAR(20) NOT NULL, ErrorMessage VARCHAR(500) NULL, INDEX (Sent)) DEFAULT CHARSET=utf8mb4",
				postgre: "CREATE TABLE EmailLog (EmailLogId SERIAL PRIMARY KEY, BlogRef INT NOT NULL, Sent TIMESTAMP NOT NULL, ToAddress VARCHAR(500) NULL, Subject VARCHAR(300) NULL, Kind VARCHAR(60) NULL, Status VARCHAR(20) NOT NULL, ErrorMessage VARCHAR(500) NULL)"
			})>
			<cfset variables.tableReady = true>
		</cfif>
	</cflock>
</cffunction>

</cfcomponent>
