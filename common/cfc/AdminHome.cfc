<cfcomponent displayName="AdminHome" output="false" hint="The admin home's Up next row (5.0, 2026-10-20): what needs the owner now, most important first. Used by includes/templates/admin/index.cfm; blog.cfc getAdminHome().">

<!---
	Order (owner, 2026-10-20): finish setting up the site, bookings waiting for an OK, comments waiting, the update, new sign-ups
	and form answers, new errors, a recent draft, a post going out soon. New errors jump to the top when the site looks broken
	(one error 20 or more times in the last hour).

	Errors count only new KINDS since the person last opened the Error Log (owner): a message not seen before then. Opening the
	Error Log (window 59) records the time (markErrorsSeen).

	Each suggestion can be hidden with its x until something new happens: hide() keeps the suggestion's signature (its count and
	newest id), and it shows again once the signature changes. Per user, kept as settings in BlogEventSetting (Events.cfc
	getSetting / setSetting, post 0), like the ready-made forms were.
--->

<cffunction name="settingKey" access="private" returntype="string" output="false">
	<cfargument name="name" type="string" required="true">
	<cfreturn arguments.name & ":" & val(session.userId ?: 0)>
</cffunction>

<cffunction name="getHidden" access="private" returntype="struct" output="false">
	<cfset var raw = "">
	<cftry>
		<cfset raw = application.events.getSetting(0, settingKey("upNextHidden"), "{}")>
		<cfcatch type="any"><cfreturn {}></cfcatch>
	</cftry>
	<cfif isJSON(raw)>
		<cfset raw = deserializeJSON(raw)>
		<cfif isStruct(raw)><cfreturn raw></cfif>
	</cfif>
	<cfreturn {}>
</cffunction>

<cffunction name="hide" access="public" returntype="void" output="false" hint="Hides one suggestion until its signature changes.">
	<cfargument name="kind" type="string" required="true">
	<cfargument name="signature" type="string" required="true">
	<cfset var hidden = getHidden()>
	<cfset hidden[left(reReplace(arguments.kind, "[^A-Za-z]", "", "all"), 30)] = left(arguments.signature, 100)>
	<cfset application.events.setSetting(0, settingKey("upNextHidden"), serializeJSON(hidden))>
</cffunction>

<cffunction name="markErrorsSeen" access="public" returntype="void" output="false" hint="The Error Log was opened: errors before now are no longer new.">
	<cftry>
		<cfset application.events.setSetting(0, settingKey("errorsSeen"), dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"))>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cffunction>

<cffunction name="getSuggestions" access="public" returntype="array" output="false"
		hint="What needs this person now, most important first: [{ kind, label, detail, count, link, signature }]. iconList and linkList are the admin home's own lists of what they may open (and how), so nothing is suggested that they can't do.">
	<cfargument name="iconList" type="string" required="true">
	<cfargument name="linkList" type="string" required="true">
	<cfargument name="canSetUp" type="boolean" required="true">
	<cfargument name="updateNeeded" type="boolean" required="true">
	<cfset var list = []>
	<cfset var hidden = getHidden()>
	<cfset var blogId = application.BlogDbObj.getBlogId()>
	<cfset var q = "">
	<cfset var setup = "">
	<cfset var seen = "">
	<cfset var item = {}>
	<cfset var result = []>
	<cfset var broken = false>
	<!--- The admin home's own link for one of its icons (these lists are per request, so they're passed in, not kept). --->
	<cfset var iconNames = arguments.iconList>
	<cfset var iconLinks = arguments.linkList>
	<cfset var linkOf = function (icon) { var i = listFindNoCase(iconNames, icon); return i ? listGetAt(iconLinks, i) : "##"; }>

	<!--- 1. Finish setting up the site --->
	<cfif arguments.canSetUp>
		<cftry>
			<cfset setup = application.blog.getSetup()>
			<cfif not setup.isFinished()>
				<cfset arrayAppend(list, { kind: "setup", label: "Finish setting up your site",
					detail: setup.stepsDoneCount() ? setup.stepsDoneCount() & " of 6 steps done" : "Your name, look, logo and a few pages",
					count: 0, link: application.baseUrl & "/admin/setup.cfm", signature: "setup" & setup.stepsDoneCount() })>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>

	<!--- 2. Bookings waiting for the owner's OK --->
	<cfif listFindNoCase(arguments.iconList, "Bookings")>
		<cftry>
			<cfset q = queryExecute("SELECT COUNT(*) AS N, MAX(BookingId) AS Newest FROM Booking WHERE BlogRef = :blogId AND Status = 'pending'",
				{ blogId = { value = blogId, cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
			<cfif val(q.N)>
				<cfset arrayAppend(list, { kind: "bookings", label: "Confirm " & q.N & (q.N eq 1 ? " booking" : " bookings"), detail: "Waiting for your OK",
					count: val(q.N), link: linkOf("Bookings"), signature: q.N & "-" & q.Newest })>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>

	<!--- 3. Comments waiting --->
	<cfif listFindNoCase(arguments.iconList, "Comments")>
		<cftry>
			<cfset q = queryExecute("SELECT COUNT(*) AS N, MAX(CommentId) AS Newest FROM Comment WHERE BlogRef = :blogId AND (Approved = 0 OR Approved IS NULL) AND (Remove = 0 OR Remove IS NULL) AND (Spam = 0 OR Spam IS NULL)",
				{ blogId = { value = blogId, cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
			<cfif val(q.N)>
				<cfset arrayAppend(list, { kind: "comments", label: "Approve " & q.N & (q.N eq 1 ? " comment" : " comments"), detail: "Readers are waiting",
					count: val(q.N), link: linkOf("Comments"), signature: q.N & "-" & q.Newest })>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>

	<!--- 4. The update --->
	<cfif arguments.updateNeeded and listFindNoCase(arguments.iconList, "BlogUpdate")>
		<cfset arrayAppend(list, { kind: "update", label: "Update to " & application.blog.getVersion(), detail: "Finish installing the new version",
			count: 0, link: linkOf("BlogUpdate"), signature: "update" & application.blog.getVersion() })>
	</cfif>

	<!--- 5. New sign-ups and form answers (this week) --->
	<cfif listFindNoCase(arguments.iconList, "Forms")>
		<cftry>
			<cfset q = queryExecute("SELECT COUNT(*) AS N, MAX(s.WebFormSubmissionId) AS Newest FROM WebFormSubmission s JOIN WebForm f ON f.WebFormId = s.WebFormRef WHERE f.BlogRef = :blogId AND s.Created >= :weekAgo",
				{ blogId = { value = blogId, cfsqltype = "cf_sql_integer" }, weekAgo = { value = dateAdd("d", -7, now()), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
			<cfif val(q.N)>
				<cfset arrayAppend(list, { kind: "signups", label: "See " & q.N & (q.N eq 1 ? " new answer" : " new answers"), detail: "Sign-ups and forms, this week",
					count: val(q.N), link: linkOf("Forms"), signature: q.N & "-" & q.Newest })>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>

	<!--- 6. New kinds of errors since the Error Log was last opened; at the top when one error keeps happening. --->
	<cfif listFindNoCase(arguments.iconList, "ErrorLog")>
		<cftry>
			<cfset seen = application.events.getSetting(0, settingKey("errorsSeen"), "")>
			<cfset seen = isDate(seen) ? parseDateTime(seen) : dateAdd("d", -1, now())>
			<cfset q = queryExecute("
				SELECT COUNT(DISTINCT e.ErrorMessage) AS N, MAX(e.ErrorLogId) AS Newest FROM ErrorLog e
				WHERE e.Date > :seen AND (e.Resolved = 0 OR e.Resolved IS NULL)
				AND NOT EXISTS (SELECT 1 FROM ErrorLog o WHERE o.ErrorMessage = e.ErrorMessage AND o.Date <= :seen AND o.Date > :since)",
				{ seen = { value = seen, cfsqltype = "cf_sql_timestamp" }, since = { value = dateAdd("d", -90, seen), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
			<cfset broken = queryExecute("SELECT COUNT(*) AS N FROM ErrorLog WHERE Date > :hourAgo GROUP BY ErrorMessage HAVING COUNT(*) >= 20",
				{ hourAgo = { value = dateAdd("h", -1, now()), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn }).recordCount gt 0>
			<cfif val(q.N) or broken>
				<cfset item = { kind: "errors", label: broken ? "Your site may have a problem" : "Check " & q.N & (q.N eq 1 ? " new error" : " new kinds of errors"),
					detail: broken ? "The same error many times in the last hour" : "Since you last looked", count: val(q.N), link: linkOf("ErrorLog"), signature: q.N & "-" & q.Newest & (broken ? "-broken" : "") }>
				<cfset arrayAppend(list, item)>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>

	<!--- 7. A recent draft, and 8. a post going out soon --->
	<cfif listFindNoCase(arguments.iconList, "Posts")>
		<cftry>
			<cfset q = queryExecute("
				SELECT PostId, Title, DatePosted, Date FROM Post
				WHERE BlogRef = :blogId AND (Released = 0 OR Released IS NULL) AND (Remove = 0 OR Remove IS NULL) AND Date >= :monthAgo
				ORDER BY Date DESC",
				{ blogId = { value = blogId, cfsqltype = "cf_sql_integer" }, monthAgo = { value = dateAdd("d", -30, now()), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
			<cfloop query="q">
				<cfif isDate(q.DatePosted) and q.DatePosted gt now()>
					<cfif dateDiff("h", now(), q.DatePosted) lte 72 and not arrayLen(arrayFilter(list, function (x) { return x.kind eq "scheduled"; }))>
						<cfset arrayAppend(list, { kind: "scheduled", label: "Going out " & (dateDiff("d", now(), q.DatePosted) lt 1 ? "today" : dateFormat(q.DatePosted, "dddd")), detail: left(q.Title, 60),
							count: 0, link: "javascript:createAdminInterfaceWindow(6," & q.PostId & ");", signature: q.PostId & "-" & dateTimeFormat(q.DatePosted, "yyyymmddHHnn") })>
					</cfif>
				<cfelseif not arrayLen(arrayFilter(list, function (x) { return x.kind eq "draft"; }))>
					<cfset arrayAppend(list, { kind: "draft", label: "Finish your draft", detail: left(q.Title, 60),
						count: 0, link: "javascript:createAdminInterfaceWindow(6," & q.PostId & ");", signature: "draft" & q.PostId })>
				</cfif>
			</cfloop>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>

	<!--- In the owner's order; an error that keeps happening first. --->
	<cfset arraySort(list, function (a, b) {
		var order = "setup,bookings,comments,update,signups,errors,draft,scheduled";
		var rankA = (a.kind eq "errors" and a.signature contains "broken") ? 0 : listFind(order, a.kind);
		var rankB = (b.kind eq "errors" and b.signature contains "broken") ? 0 : listFind(order, b.kind);
		return rankA lt rankB ? -1 : (rankA gt rankB ? 1 : 0);
	})>

	<!--- Without the ones hidden until something new happens. --->
	<cfloop array="#list#" index="item">
		<cfif not (structKeyExists(hidden, item.kind) and hidden[item.kind] eq item.signature)>
			<cfset arrayAppend(result, item)>
		</cfif>
	</cfloop>
	<cfreturn result>
</cffunction>


<!---//*****************************************************************************************************
		Traffic (owner, 2026-10-20): the four cards on the admin home
//******************************************************************************************************--->

<cffunction name="getTraffic" access="public" returntype="struct" output="false"
		hint="The admin home's traffic cards, from the visitor log: people (not bots) this week and last week, a 30-day line, the bots this week, the five most-read posts this week, where people came from this week, and who is reading now (the last 15 minutes). Kept for five minutes. Times are the blog's (VisitorLog.Date is blogNow()).">
	<cfset var cacheKey = "galaxieAdminTraffic" & application.BlogDbObj.getBlogId()>
	<cfset var nowTime = application.blog.blogNow()>
	<cfset var result = {}>
	<cfset var q = "">
	<cfset var days = {}>
	<cfset var day = "">
	<cfset var i = 0>
	<cfset var sources = { "search": 0, "social": 0, "sites": 0, "direct": 0 }>
	<cfset var host = "">
	<cfset var ownHost = lCase(cgi.server_name)>
	<cfset var seen = {}>
	<cfset var weekAgo = dateAdd("d", -7, nowTime)>
	<cfset var people = "(a.IsBot = 0 OR a.IsBot IS NULL)">
	<cfif structKeyExists(application, cacheKey) and dateDiff("n", application[cacheKey].made, now()) lt 5>
		<cfreturn application[cacheKey].data>
	</cfif>
	<cfset result = { "peopleThisWeek": 0, "peopleLastWeek": 0, "botsThisWeek": 0, "days": [], "topPosts": [], "sources": sources, "nowCount": 0, "now": [] }>

	<!--- This week and last week: each visitor counted once. --->
	<cfset q = queryExecute("
		SELECT
			COUNT(DISTINCT CASE WHEN v.Date >= :weekAgo AND #people# THEN v.AnonymousUserRef END) AS PeopleThisWeek,
			COUNT(DISTINCT CASE WHEN v.Date < :weekAgo AND #people# THEN v.AnonymousUserRef END) AS PeopleLastWeek,
			COUNT(DISTINCT CASE WHEN v.Date >= :weekAgo AND a.IsBot = 1 THEN v.AnonymousUserRef END) AS BotsThisWeek
		FROM VisitorLog v LEFT JOIN AnonymousUser a ON a.AnonymousUserId = v.AnonymousUserRef
		WHERE v.Date >= :twoWeeksAgo",
		{ weekAgo = { value = weekAgo, cfsqltype = "cf_sql_timestamp" }, twoWeeksAgo = { value = dateAdd("d", -14, nowTime), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
	<cfset result.peopleThisWeek = val(q.PeopleThisWeek)>
	<cfset result.peopleLastWeek = val(q.PeopleLastWeek)>
	<cfset result.botsThisWeek = val(q.BotsThisWeek)>

	<!--- The last 30 days, a point a day (days with no visits are 0). --->
	<cfset q = queryExecute("
		SELECT CAST(v.Date AS DATE) AS VisitDay, COUNT(DISTINCT v.AnonymousUserRef) AS People
		FROM VisitorLog v LEFT JOIN AnonymousUser a ON a.AnonymousUserId = v.AnonymousUserRef
		WHERE v.Date >= :since AND #people#
		GROUP BY CAST(v.Date AS DATE)",
		{ since = { value = dateAdd("d", -29, dateFormat(nowTime, "yyyy-mm-dd")), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
	<cfloop query="q"><cfset days[dateFormat(q.VisitDay, "yyyy-mm-dd")] = val(q.People)></cfloop>
	<cfloop from="29" to="0" step="-1" index="i">
		<cfset day = dateFormat(dateAdd("d", -i, nowTime), "yyyy-mm-dd")>
		<cfset arrayAppend(result.days, { "day": day, "people": days[day] ?: 0 })>
	</cfloop>

	<!--- The five most-read posts this week (people only). --->
	<cfset q = queryExecute("
		SELECT p.PostId, p.Title, COUNT(*) AS ReadCount
		FROM VisitorLog v JOIN Post p ON p.PostId = v.PostRef LEFT JOIN AnonymousUser a ON a.AnonymousUserId = v.AnonymousUserRef
		WHERE v.Date >= :weekAgo AND #people#
		GROUP BY p.PostId, p.Title
		ORDER BY COUNT(*) DESC",
		{ weekAgo = { value = weekAgo, cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn, maxrows = 5 })>
	<cfloop query="q"><cfset arrayAppend(result.topPosts, { "postId": q.PostId, "title": toString(q.Title), "reads": val(q.ReadCount) })></cfloop>

	<!--- Where people came from this week: search engines, social media, other sites, or straight in (no referrer, or this site). --->
	<cfset q = queryExecute("
		SELECT h.HttpReferrer, COUNT(DISTINCT v.AnonymousUserRef) AS People
		FROM VisitorLog v LEFT JOIN HttpReferrer h ON h.HttpReferrerId = v.HttpReferrerRef LEFT JOIN AnonymousUser a ON a.AnonymousUserId = v.AnonymousUserRef
		WHERE v.Date >= :weekAgo AND #people#
		GROUP BY h.HttpReferrer",
		{ weekAgo = { value = weekAgo, cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
	<cfloop query="q">
		<cfset host = lCase(reReplace(reReplace(toString(q.HttpReferrer), "^[a-z]+://", ""), "[/:?##].*$", ""))>
		<cfif not len(host) or host eq ownHost or right(host, len(ownHost) + 1) eq "." & ownHost>
			<cfset sources.direct = sources.direct + val(q.People)>
		<cfelseif reFind("(^|\.)(google|bing|duckduckgo|yahoo|baidu|yandex|ecosia|startpage|brave|qwant)\.", host)>
			<cfset sources.search = sources.search + val(q.People)>
		<cfelseif reFind("(^|\.)(facebook|fb|t\.co|twitter|x\.com|linkedin|lnkd|reddit|instagram|pinterest|youtube|mastodon|threads|bsky)", host)>
			<cfset sources.social = sources.social + val(q.People)>
		<cfelse>
			<cfset sources.sites = sources.sites + val(q.People)>
		</cfif>
	</cfloop>
	<cfset result.sources = sources>

	<!--- Reading now: people in the last 15 minutes, each with the newest page they opened. --->
	<cfset q = queryExecute("
		SELECT v.AnonymousUserRef, v.Date, p.Title, v.VisitingHomePage
		FROM VisitorLog v LEFT JOIN Post p ON p.PostId = v.PostRef LEFT JOIN AnonymousUser a ON a.AnonymousUserId = v.AnonymousUserRef
		WHERE v.Date >= :since AND #people#
		ORDER BY v.Date DESC",
		{ since = { value = dateAdd("n", -15, nowTime), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn, maxrows = 200 })>
	<cfloop query="q">
		<cfif not structKeyExists(seen, q.AnonymousUserRef)>
			<cfset seen[q.AnonymousUserRef] = true>
			<cfif arrayLen(result.now) lt 8>
				<cfset arrayAppend(result.now, { "page": len(toString(q.Title)) ? toString(q.Title) : "The home page", "minutesAgo": max(0, dateDiff("n", q.Date, nowTime)) })>
			</cfif>
		</cfif>
	</cfloop>
	<cfset result.nowCount = structCount(seen)>

	<cfset application[cacheKey] = { made = now(), data = result }>
	<cfreturn result>
</cffunction>

</cfcomponent>
