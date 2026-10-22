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

<!--- New and changed bookings (owner, 2026-10-21): a booking that doesn't need the owner's OK never showed on the home, so Up next
also has "See 2 new bookings" and "1 booking changed" (cancelled or moved by the client from their manage link), until the
bookings list or calendar is opened. The owner's own changes aren't counted. --->
<cffunction name="markBookingsSeen" access="public" returntype="void" output="false" hint="The bookings list or calendar was opened: the bookings so far are no longer new.">
	<cftry>
		<cfset application.events.setSetting(0, settingKey("bookingsSeen"), dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"))>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cffunction>

<cffunction name="noteBookingChange" access="public" returntype="void" output="false" hint="A client cancelled or moved a booking (ProxyController cancelManagedBooking / rescheduleManagedBooking). The last 15 are kept for the whole blog, as id:kind:time.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfargument name="kind" type="string" required="true" hint="cancelled or moved">
	<cfset var changes = []>
	<cftry>
		<cflock name="galaxieBookingChanges_#application.BlogDbObj.getBlogId()#" type="exclusive" timeout="10">
			<cfset changes = listToArray(application.events.getSetting(0, "bookingChanges", ""))>
			<cfset arrayAppend(changes, int(arguments.bookingId) & ":" & (arguments.kind eq "moved" ? "moved" : "cancelled") & ":" & dateTimeFormat(now(), "yyyymmddHHnnss"))>
			<cfloop condition="arrayLen(changes) gt 15"><cfset arrayDeleteAt(changes, 1)></cfloop>
			<cfset application.events.setSetting(0, "bookingChanges", arrayToList(changes))>
		</cflock>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cffunction>

<cffunction name="bookingWhen" access="private" returntype="string" output="false" hint="A booking's start (StartLocal, yyyy-mm-dd HH:mm in the blog's time) as Today 1:30 PM, Tomorrow 9:00 AM or Tue Oct 27, 10:00 AM.">
	<cfargument name="startLocal" type="string" required="true">
	<cfset var start = "">
	<cfset var today = dateFormat(application.blog.blogNow(), "yyyy-mm-dd")>
	<cfif not reFind("^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$", arguments.startLocal)><cfreturn arguments.startLocal></cfif>
	<cfset start = createDateTime(left(arguments.startLocal, 4), mid(arguments.startLocal, 6, 2), mid(arguments.startLocal, 9, 2), mid(arguments.startLocal, 12, 2), right(arguments.startLocal, 2), 0)>
	<cfif left(arguments.startLocal, 10) eq today>
		<cfreturn "Today " & timeFormat(start, "h:mm tt")>
	<cfelseif left(arguments.startLocal, 10) eq dateFormat(dateAdd("d", 1, today), "yyyy-mm-dd")>
		<cfreturn "Tomorrow " & timeFormat(start, "h:mm tt")>
	</cfif>
	<cfreturn dateFormat(start, "ddd mmm d") & ", " & timeFormat(start, "h:mm tt")>
</cffunction>

<cffunction name="getComingUp" access="public" returntype="struct" output="false"
		hint="The admin home's Coming up card (owner, 2026-10-21): the next bookings in the two weeks ahead, soonest first. { show: the blog has booking types, total, items: [{ bookingId, when, name, typeName, location, pending }] } - up to five.">
	<cfset var result = { show: false, total: 0, items: [] }>
	<cfset var blogId = application.BlogDbObj.getBlogId()>
	<cfset var nowTime = application.blog.blogNow()>
	<cfset var q = "">
	<cftry>
		<cfset q = queryExecute("SELECT COUNT(*) AS N FROM BookingType WHERE BlogRef = :blogId", { blogId = { value = blogId, cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
		<cfif not val(q.N)><cfreturn result></cfif>
		<cfset result.show = true>
		<!--- StartLocal is text in the blog's time (yyyy-mm-dd HH:mm), so it compares as text. --->
		<cfset q = queryExecute("
			SELECT b.BookingId, b.Name, b.StartLocal, b.Status, t.Name AS TypeName, l.Label AS LocationLabel
			FROM Booking b LEFT JOIN BookingType t ON t.BookingTypeId = b.BookingTypeRef LEFT JOIN LocationOption l ON l.LocationOptionId = b.LocationOptionRef
			WHERE b.BlogRef = :blogId AND b.Status IN ('confirmed', 'pending') AND b.StartLocal >= :fromLocal AND b.StartLocal <= :toLocal
			ORDER BY b.StartLocal",
			{ blogId = { value = blogId, cfsqltype = "cf_sql_integer" },
			  fromLocal = { value = dateTimeFormat(nowTime, "yyyy-mm-dd HH:nn"), cfsqltype = "cf_sql_varchar" },
			  toLocal = { value = dateFormat(dateAdd("d", 14, nowTime), "yyyy-mm-dd") & " 23:59", cfsqltype = "cf_sql_varchar" } }, { datasource = application.dsn })>
		<cfset result.total = q.recordCount>
		<cfloop query="q" endrow="5">
			<cfset arrayAppend(result.items, { bookingId: q.BookingId, when: bookingWhen(q.StartLocal), name: toString(q.Name), typeName: toString(q.TypeName),
				location: toString(q.LocationLabel), pending: q.Status eq "pending" })>
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfreturn result>
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

	<!--- 2b. New bookings, and bookings the client cancelled or moved, since the bookings were last opened (owner, 2026-10-21).
	A first look counts the last week. --->
	<cfif listFindNoCase(arguments.iconList, "Bookings")>
		<cftry>
			<cfset seen = application.events.getSetting(0, settingKey("bookingsSeen"), "")>
			<cfset seen = isDate(seen) ? parseDateTime(seen) : dateAdd("d", -7, now())>
			<cfset q = queryExecute("SELECT BookingId, Name, StartLocal FROM Booking WHERE BlogRef = :blogId AND Status = 'confirmed' AND Created >= :after ORDER BY BookingId DESC",
				<!--- seen is kept to the second and Created has milliseconds, so new means from the next whole second. --->
				{ blogId = { value = blogId, cfsqltype = "cf_sql_integer" }, after = { value = dateAdd("s", 1, seen), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
			<cfset item = { changed: {}, newest: "" }>
			<cfloop list="#application.events.getSetting(0, 'bookingChanges', '')#" index="local.change">
				<cfif listLen(local.change, ":") eq 3 and reFind("^\d{14}$", listLast(local.change, ":"))>
					<cfset local.at = listLast(local.change, ":")>
					<cfset local.at = createDateTime(left(local.at, 4), mid(local.at, 5, 2), mid(local.at, 7, 2), mid(local.at, 9, 2), mid(local.at, 11, 2), right(local.at, 2))>
					<cfif local.at gt seen>
						<cfset item.changed[listFirst(local.change, ":")] = listGetAt(local.change, 2, ":")>
						<cfset item.newest = local.change>
					</cfif>
				</cfif>
			</cfloop>
			<cfset local.changedCount = structCount(item.changed)>
			<cfif q.recordCount or local.changedCount>
				<cfif q.recordCount>
					<cfset local.label = "See " & q.recordCount & (q.recordCount eq 1 ? " new booking" : " new bookings")>
					<cfif local.changedCount>
						<cfset local.detail = "And " & local.changedCount & " changed by the client">
					<cfelseif q.recordCount eq 1>
						<cfset local.detail = left(q.Name, 30) & ", " & bookingWhen(q.StartLocal)>
					<cfelse>
						<cfset local.detail = "Since you last looked">
					</cfif>
				<cfelse>
					<cfset local.label = local.changedCount & (local.changedCount eq 1 ? " booking changed" : " bookings changed")>
					<cfset local.detail = "Cancelled or moved by the client">
				</cfif>
				<!--- Cancelled ones only show in the list's All view. --->
				<cfset arrayAppend(list, { kind: "newBookings", label: local.label, detail: local.detail, count: q.recordCount + local.changedCount,
					link: "javascript:createAdminInterfaceWindow(94, '" & (local.changedCount ? "all" : "upcoming") & "');",
					signature: val(q.BookingId) & "-" & local.changedCount & "-" & hash(item.newest, "MD5") })>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>

	<!--- 2c. Paid shop orders waiting to be shipped (2026-10-21). --->
	<cfif listFindNoCase(arguments.iconList, "Orders")>
		<cftry>
			<cfset local.toShip = application.shop.getAdminCounts().toShip>
			<cfif local.toShip>
				<cfset arrayAppend(list, { kind: "shipOrders", label: "Ship " & local.toShip & (local.toShip eq 1 ? " order" : " orders"), detail: "Paid and waiting to be shipped",
					count: local.toShip, link: "javascript:createAdminInterfaceWindow(113, 'toShip');", signature: "ship" & local.toShip })>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>

	<!--- 3. Comments waiting --->
	<cfif listFindNoCase(arguments.iconList, "Comments")>
		<cftry>
			<cfset q = queryExecute("SELECT COUNT(*) AS N, MAX(CommentId) AS Newest FROM Comment WHERE BlogRef = :blogId AND Approved = 0 AND (Remove = 0 OR Remove IS NULL) AND (Spam = 0 OR Spam IS NULL)",
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

	<!--- 5. New sign-ups and form answers (this week). From one form, the tile opens that form's answers (window 85, owner
	10-20); from several, the Forms list, which shows each form's count. --->
	<cfif listFindNoCase(arguments.iconList, "Forms")>
		<cftry>
			<cfset q = queryExecute("
				SELECT f.WebFormId, f.Title, COUNT(*) AS N, MAX(s.WebFormSubmissionId) AS Newest
				FROM WebFormSubmission s JOIN WebForm f ON f.WebFormId = s.WebFormRef
				WHERE f.BlogRef = :blogId AND s.Created >= :weekAgo
				GROUP BY f.WebFormId, f.Title
				ORDER BY COUNT(*) DESC",
				{ blogId = { value = blogId, cfsqltype = "cf_sql_integer" }, weekAgo = { value = dateAdd("d", -7, now()), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
			<cfif q.recordCount>
				<cfset item = { total: 0, newest: 0 }>
				<cfloop query="q"><cfset item.total = item.total + val(q.N)><cfset item.newest = max(item.newest, val(q.Newest))></cfloop>
				<cfset arrayAppend(list, { kind: "signups", label: "See " & item.total & (item.total eq 1 ? " new answer" : " new answers"),
					detail: q.recordCount eq 1 ? left(q.Title, 50) & ", this week" : "In " & q.recordCount & " forms, this week",
					count: item.total, link: q.recordCount eq 1 ? "javascript:createAdminInterfaceWindow(85, " & q.WebFormId & ");" : linkOf("Forms"),
					signature: item.total & "-" & item.newest })>
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
		var order = "setup,bookings,newBookings,shipOrders,comments,update,signups,errors,draft,scheduled";
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
