<cfcomponent displayName="ErrorDigest" output="false" hint="Error emails (2026-10-18): one summary email a night instead of one email per new error. Created on first use by blog.cfc getErrorDigest() (application.errorDigest). Settings are kept in BlogEventSetting under post 0 (Events.cfc getSetting/setSetting): errorEmailMode (daily | immediate), errorDigestHour (0-23, blog time), errorDigestLastSent, errorDigestLastId. Turning error emails off altogether is still Blog Options' Send Diagnostics checkbox. The summary is sent by the first page view after the summary time (see maybeSend) - not by a scheduled task, which ColdFusion's outbound network policy can silently block.">

<cfset variables.burstWindowMinutes = 10>
<cfset variables.burstThreshold = 100>
<cfset variables.burstAlertEveryHours = 6>
<cfset variables.maxRows = 25>
<!--- Messages that are almost always bots asking for things that don't exist. They are shown as one line at the end of the summary. --->
<cfset variables.botPatterns = "File not found|could not be found|for CFSQLTYPE|is required but was not passed|Invalid characters|Invalid construct|The value .* cannot be converted to a number">

<!---//*****************************************************************************************************
		Settings
//******************************************************************************************************--->

<cffunction name="mode" access="public" returntype="string" output="false" hint="'daily' (default) or 'immediate'.">
	<cfif not structKeyExists(application, "errorEmailMode")>
		<cfset application.errorEmailMode = setting("errorEmailMode", "daily")>
		<cfif not listFind("daily,immediate", application.errorEmailMode)>
			<cfset application.errorEmailMode = "daily">
		</cfif>
	</cfif>
	<cfreturn application.errorEmailMode>
</cffunction>

<cffunction name="digestHour" access="public" returntype="numeric" output="false" hint="The hour (0-23, the blog's time zone) after which the nightly summary is sent. Default 2 AM.">
	<cfset var hour = setting("errorDigestHour", "2")>
	<cfreturn (isNumeric(hour) and hour gte 0 and hour lte 23) ? int(hour) : 2>
</cffunction>

<cffunction name="saveSettings" access="public" returntype="void" output="false">
	<cfargument name="mode" type="string" required="true">
	<cfargument name="hour" type="numeric" required="true">
	<cfset application.events.setSetting(0, "errorEmailMode", listFind("daily,immediate", arguments.mode) ? arguments.mode : "daily")>
	<cfset application.events.setSetting(0, "errorDigestHour", min(23, max(0, int(arguments.hour))))>
	<cfset structDelete(application, "errorEmailMode")>
	<cfset structDelete(application, "errorDigestNextCheck")>
</cffunction>

<cffunction name="setting" access="private" returntype="string" output="false">
	<cfargument name="name" type="string" required="true">
	<cfargument name="default" type="string" required="true">
	<cftry>
		<cfreturn application.events.getSetting(0, arguments.name, arguments.default)>
		<cfcatch type="any"><cfreturn arguments.default></cfcatch>
	</cftry>
</cffunction>

<!---//*****************************************************************************************************
		Called for every error
//******************************************************************************************************--->

<cffunction name="isBurst" access="public" returntype="boolean" output="false"
		hint="Counts every error, new or known. True once when there are more than burstThreshold errors within burstWindowMinutes (the site may be broken), and then not again for burstAlertEveryHours - so even with a daily summary, a real outage still sends one email right away.">
	<cfset var alert = false>
	<cflock name="galaxieErrorBurst_#application.applicationName#" type="exclusive" timeout="5">
		<cfif not structKeyExists(application, "errorBurst") or dateDiff("n", application.errorBurst.started, now()) gte variables.burstWindowMinutes>
			<cfset application.errorBurst = { started: now(), count: 0, lastAlert: structKeyExists(application, "errorBurst") ? application.errorBurst.lastAlert : "" }>
		</cfif>
		<cfset application.errorBurst.count++>
		<cfif application.errorBurst.count gte variables.burstThreshold
			and (not isDate(application.errorBurst.lastAlert) or dateDiff("h", application.errorBurst.lastAlert, now()) gte variables.burstAlertEveryHours)>
			<cfset application.errorBurst.lastAlert = now()>
			<cfset alert = true>
		</cfif>
	</cflock>
	<cfreturn alert>
</cffunction>

<cffunction name="sendBurstAlert" access="public" returntype="void" output="false">
	<cfargument name="errorMessage" type="string" required="true">
	<cfargument name="errorUrl" type="string" required="true">
	<cfset var body = "<p><b>" & variables.burstThreshold & " or more errors in the last " & variables.burstWindowMinutes & " minutes.</b> The site may be having a problem right now.</p>"
		& "<p>The latest one: " & encodeForHtml(arguments.errorMessage) & "<br>at " & encodeForHtml(arguments.errorUrl) & "</p>"
		& "<p>You'll get this at most once every " & variables.burstAlertEveryHours & " hours. The details will be in tonight's summary, and in the "
		& "<a href=""" & application.blogHostUrl & "/admin/"">Error Log</a>.</p>">
	<cfset sendEmail("Galaxie Blog: many errors right now", "Many errors right now", body)>
</cffunction>

<!---//*****************************************************************************************************
		The nightly summary
//******************************************************************************************************--->

<cffunction name="maybeSend" access="public" returntype="void" output="false"
		hint="Called on every page view. Almost always returns at once (one date compare in memory). After the summary time, the first page view sends the summary in its own thread, so the visitor doesn't wait.">
	<cfset var nowBlog = "">
	<cfset var due = "">
	<cfset var lastSent = "">
	<cfif structKeyExists(application, "errorDigestNextCheck") and now() lt application.errorDigestNextCheck>
		<cfreturn>
	</cfif>
	<!--- Look again in 5 minutes at the earliest, whatever happens below. --->
	<cfset application.errorDigestNextCheck = dateAdd("n", 5, now())>
	<cfif mode() neq "daily" or not application.sendDiagnostics>
		<cfreturn>
	</cfif>
	<cfset nowBlog = application.blog.blogNow()>
	<cfset due = createDateTime(year(nowBlog), month(nowBlog), day(nowBlog), digestHour(), 0, 0)>
	<cfset lastSent = setting("errorDigestLastSent", "")>
	<cfif nowBlog lt due or (isDate(lastSent) and parseDateTime(lastSent) gte due)>
		<cfreturn>
	</cfif>
	<cflock name="galaxieErrorDigest_#application.applicationName#" type="exclusive" timeout="1" throwontimeout="false">
		<!--- Someone else may have sent it while this request waited. --->
		<cfset lastSent = setting("errorDigestLastSent", "")>
		<cfif isDate(lastSent) and parseDateTime(lastSent) gte due>
			<cfreturn>
		</cfif>
		<!--- Mark it sent first, so a failure can't turn into an email on every page view. --->
		<cfset application.events.setSetting(0, "errorDigestLastSent", dateTimeFormat(nowBlog, "yyyy-mm-dd HH:nn:ss"))>
	</cflock>
	<cfthread action="run" name="galaxieErrorDigest_#createUUID()#" since="#lastSent#">
		<cftry>
			<cfset send(attributes.since)>
			<cfcatch type="any">
				<cflog file="galaxieBlogErrors" type="error" text="Error summary could not be sent: #cfcatch.message#">
			</cfcatch>
		</cftry>
	</cfthread>
</cffunction>

<cffunction name="send" access="public" returntype="struct" output="false"
		hint="Builds and sends the summary of the errors since 'since' (blog time; default the last 24 hours). Returns { errors, distinct, sent }. Also used by Blog Options' 'Send a summary now'.">
	<cfargument name="since" type="string" required="false" default="">
	<cfset var nowBlog = application.blog.blogNow()>
	<cfset var fromDate = isDate(arguments.since) ? parseDateTime(arguments.since) : dateAdd("h", -24, nowBlog)>
	<cfset var lastId = val(setting("errorDigestLastId", "0"))>
	<cfset var rows = "">
	<cfset var previous = "">
	<cfset var snapshot = {}>
	<cfset var items = []>
	<cfset var bots = { count: 0, distinct: 0 }>
	<cfset var item = "">
	<cfset var delta = 0>
	<cfset var total = 0>
	<cfset var newCount = 0>
	<cfset var maxId = lastId>
	<cfset var body = "">
	<cfset var shown = 0>
	<cfset var i = 0>
	<cfset var result = { errors: 0, distinct: 0, sent: false }>

	<cfset ensureCountTable()>
	<cfset rows = queryExecute("SELECT ErrorLogId, ErrorType, ErrorMessage, ErrorTemplate, ErrorLine, ErrorURL, NumErrors, Date FROM ErrorLog WHERE Date >= :since ORDER BY ErrorLogId",
		{ since = { value = fromDate, cfsqltype = "cf_sql_timestamp" } })>
	<cfif rows.recordCount>
		<cfset previous = queryExecute("SELECT ErrorLogRef, NumErrors FROM ErrorDigestCount WHERE ErrorLogRef >= :firstId", { firstId = { value = rows.ErrorLogId[1], cfsqltype = "cf_sql_integer" } })>
		<cfloop query="previous">
			<cfset snapshot[previous.ErrorLogRef] = previous.NumErrors>
		</cfloop>
	</cfif>

	<cfloop query="rows">
		<cfset delta = val(rows.NumErrors) - (structKeyExists(snapshot, rows.ErrorLogId) ? snapshot[rows.ErrorLogId] : 0)>
		<cfset maxId = max(maxId, rows.ErrorLogId)>
		<cfif delta lte 0>
			<cfcontinue>
		</cfif>
		<cfset total += delta>
		<cfif reFindNoCase(variables.botPatterns, rows.ErrorMessage)>
			<cfset bots.count += delta>
			<cfset bots.distinct++>
		<cfelse>
			<cfset arrayAppend(items, {
				id: rows.ErrorLogId, isNew: rows.ErrorLogId gt lastId, count: delta, total: val(rows.NumErrors),
				message: rows.ErrorMessage, template: rows.ErrorTemplate, line: rows.ErrorLine, url: rows.ErrorURL, last: rows.Date
			})>
			<cfif rows.ErrorLogId gt lastId><cfset newCount++></cfif>
		</cfif>
	</cfloop>

	<!--- New errors first, then the most frequent. --->
	<cfset arraySort(items, function(a, b) {
		if (a.isNew neq b.isNew) { return a.isNew ? -1 : 1; }
		return b.count - a.count;
	})>
	<cfset result.errors = total>
	<cfset result.distinct = arrayLen(items) + bots.distinct>

	<cfif total gt 0>
		<cfsavecontent variable="body"><cfoutput>
			<p><b>#numberFormat(total)# error#total eq 1 ? "" : "s"#</b> (#result.distinct# different) since #dateTimeFormat(fromDate, "mmm d, h:nn tt")#<cfif newCount>, <b>#newCount# new</b></cfif>.</p>
			<cfif arrayLen(items)>
			<table cellpadding="6" cellspacing="0" border="1" style="border-collapse: collapse; width: 100%; font-size: 14px;">
				<tr><th align="left">Error</th><th align="right">Times</th><th align="left">Last</th></tr>
				<cfloop array="#items#" index="item">
					<cfset shown++>
					<cfif shown gt variables.maxRows><cfbreak></cfif>
					<tr valign="top">
						<td><cfif item.isNew><b>NEW</b> - </cfif>#encodeForHtml(left(item.message, 300))#
							<br><small>#encodeForHtml(listLast(item.template, "\/"))#<cfif len(item.line)> line #encodeForHtml(item.line)#</cfif> - #encodeForHtml(left(item.url, 120))#</small></td>
						<td align="right">#numberFormat(item.count)#<cfif item.total gt item.count><br><small>(#numberFormat(item.total)# in all)</small></cfif></td>
						<td>#isDate(item.last) ? dateTimeFormat(item.last, "mmm d, h:nn tt") : ""#</td>
					</tr>
				</cfloop>
			</table>
			<cfif arrayLen(items) gt variables.maxRows><p>And #arrayLen(items) - variables.maxRows# more.</p></cfif>
			</cfif>
			<cfif bots.count>
			<p>#numberFormat(bots.count)# more from #bots.distinct# kind#bots.distinct eq 1 ? "" : "s"# of request that look like bots probing for files and pages that don't exist (not found, bad values in the address). Usually nothing to do.</p>
			</cfif>
			<p>All the details, with stack traces, are in the <a href="#application.blogHostUrl#/admin/">Error Log</a>. You get this summary once a night at most, and only when there were errors; change it in Blog Options.</p>
		</cfoutput></cfsavecontent>
		<cfset result.sent = sendEmail("Galaxie Blog: #numberFormat(total)# error#total eq 1 ? '' : 's'#" & (newCount ? ", #newCount# new" : ""), "Errors since #dateTimeFormat(fromDate, 'mmm d')#", body)>
	</cfif>

	<!--- Remember the counts, so the next summary only counts what happened after this one. --->
	<cfloop query="rows">
		<cfset queryExecute("DELETE FROM ErrorDigestCount WHERE ErrorLogRef = :id", { id = { value = rows.ErrorLogId, cfsqltype = "cf_sql_integer" } })>
		<cfset queryExecute("INSERT INTO ErrorDigestCount (ErrorLogRef, NumErrors) VALUES (:id, :n)", { id = { value = rows.ErrorLogId, cfsqltype = "cf_sql_integer" }, n = { value = val(rows.NumErrors), cfsqltype = "cf_sql_integer" } })>
	</cfloop>
	<cfset application.events.setSetting(0, "errorDigestLastId", maxId)>
	<cfreturn result>
</cffunction>

<!---//*****************************************************************************************************
		Helpers
//******************************************************************************************************--->

<cffunction name="sendEmail" access="private" returntype="boolean" output="false" hint="Same recipients as the single error emails: the blog's email, and developerEmail from blog.ini.cfm when it is set.">
	<cfargument name="subject" type="string" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="body" type="string" required="true">
	<cfset var recipients = "">
	<cfset var blogEmail = trim(application.BlogDbObj.getBlogEmail())>
	<cfset var emailBody = "">
	<!--- mail() stops the request when the blog email address has not been set up. --->
	<cfif not len(blogEmail)>
		<cfreturn false>
	</cfif>
	<cfset recipients = blogEmail>
	<cfif len(trim(application.developerEmailAddress ?: "")) and not listFindNoCase(recipients, trim(application.developerEmailAddress))>
		<cfset recipients = listAppend(recipients, trim(application.developerEmailAddress))>
	</cfif>
	<cfset emailBody = createObject("component", application.rendererComponentPath).renderEmail(email = recipients, emailTitle = arguments.title, emailTitleLink = application.blogHostUrl & "/admin/", emailBody = arguments.body)>
	<cfset createObject("component", application.utilsComponentPath).mail(to = recipients, subject = arguments.subject, body = emailBody)>
	<cfreturn true>
</cffunction>

<cffunction name="ensureCountTable" access="private" returntype="void" output="false" hint="Creates the ErrorDigestCount table (each error's count at the last summary) the first time it is needed, once per application start.">
	<cfset var updater = "">
	<cfif structKeyExists(variables, "countTableReady")>
		<cfreturn>
	</cfif>
	<cfset updater = createObject("component", len(application.baseProxyUrl) ? application.baseComponentPath & ".common.cfc.DatabaseUpdater" : "common.cfc.DatabaseUpdater").init(application.rootDirectoryPath, application.blogIniPath)>
	<!--- createTableIfMissing picks the SQL by application.databaseType, which only the updater sets (see People.cfc ensureTable). --->
	<cfif not len(application.databaseType ?: "")>
		<cfset application.databaseType = getProfileString(application.blogIniPath, "default", "databaseType")>
	</cfif>
	<cfset updater.createTableIfMissing("ErrorDigestCount", {
		sqlServer: "CREATE TABLE ErrorDigestCount (ErrorLogRef INT NOT NULL PRIMARY KEY, NumErrors INT NOT NULL)",
		mySql: "CREATE TABLE ErrorDigestCount (ErrorLogRef INT NOT NULL PRIMARY KEY, NumErrors INT NOT NULL) DEFAULT CHARSET=utf8mb4",
		postgre: "CREATE TABLE ErrorDigestCount (ErrorLogRef INT NOT NULL PRIMARY KEY, NumErrors INT NOT NULL)"
	})>
	<cfset variables.countTableReady = true>
</cffunction>

</cfcomponent>
