<cfcomponent displayName="Members" output="false" hint="Member accounts (2026-10-15): visitors sign in with a one-time link emailed to them - no passwords - and get their own account. Created once as application.members in Application.cfc. Entities: MemberSetting, BlogMember, MemberLoginToken, MemberRememberToken (common/cfc/db/galaxieDb). Remote calls: ProxyController.cfc's member* methods; the visitor side is common/js/members.js. See doc/aiDraftArticles/memberAccountsDesign.cfm.">

<!---
	Members are NOT admin users. Nothing here touches the admin login (cflogin, session roles, the Users table): a member
	session lives only in session.galaxieMember, and the admin site never reads it. A member can't reach an admin window.

	Every write is inside a cftransaction: the application sets ormsettings.flushAtRequestEnd = false, so an entity change
	made outside a transaction (without ormFlush) would never reach the database.

	Tokens (the emailed sign-in link and the 'Keep me signed in' cookie) are long random values; only their SHA-256 hash
	is stored, so a copy of the database can't be used to sign in.
--->

<cffunction name="init" access="public" returntype="any" output="false">
	<!--- How long an emailed sign-in link works. --->
	<cfset variables.linkMinutes = 15>
	<!--- Sign-in emails allowed in 15 minutes, per address and per visitor IP address, so the form can't flood an inbox. --->
	<cfset variables.perEmailLimit = 3>
	<cfset variables.perIpLimit = 10>
	<cfset variables.settingsCache = {}>
	<cfreturn this>
</cffunction>

<!--- ********************************************************************************************************************
	Settings (Blog Options > Member Accounts)
********************************************************************************************************************* --->

<cffunction name="getSettings" access="public" returntype="struct" output="false" hint="{ enabled, rememberDays }">
	<cfset var entity = loadSettingsEntity()>
	<cfset var settings = { enabled: false, rememberDays: 30 }>
	<cfif not isNull(entity)>
		<cfset settings.enabled = isTrue(entity.getEnabled(), false)>
		<cfset settings.rememberDays = val(valueOrEmpty(entity.getRememberDays())) gt 0 ? val(entity.getRememberDays()) : 30>
	</cfif>
	<cfreturn settings>
</cffunction>

<cffunction name="isEnabled" access="public" returntype="boolean" output="false">
	<cfreturn cachedSettings().enabled>
</cffunction>

<cffunction name="saveSettings" access="public" returntype="struct" output="false" hint="Returns { success, errors[] }.">
	<cfargument name="enabled" type="boolean" required="true">
	<cfargument name="rememberDays" required="true">
	<cfset var result = { success: false, errors: [] }>
	<cfset var entity = "">
	<cfif not isNumeric(arguments.rememberDays) or int(arguments.rememberDays) lt 1 or int(arguments.rememberDays) gt 365>
		<cfset arrayAppend(result.errors, "Keep members signed in for 1 to 365 days.")>
		<cfreturn result>
	</cfif>
	<cftransaction>
		<cfset entity = loadSettingsEntity()>
		<cfif isNull(entity)>
			<cfset entity = entityNew("MemberSetting")>
			<cfset entity.setBlogRef(javacast("int", application.BlogDbObj.getBlogId()))>
			<cfset entity.setCreated(now())>
		</cfif>
		<cfset entity.setEnabled(arguments.enabled)>
		<cfset entity.setRememberDays(javacast("int", int(arguments.rememberDays)))>
		<cfset entity.setUpdated(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset variables.settingsCache = {}>
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	Signing in with an emailed link
********************************************************************************************************************* --->

<cffunction name="requestSignIn" access="public" returntype="struct" output="false"
		hint="Emails a one-time sign-in link. Returns { success, message }. The message is the same whether or not the address has an account, so the form can't be used to find out who does.">
	<cfargument name="email" type="string" required="true">
	<cfargument name="returnUrl" type="string" required="false" default="" hint="The page the visitor asked from; the link brings them back to it.">
	<cfargument name="ipAddress" type="string" required="false" default="">
	<cfset var result = { success: false, message: "" }>
	<cfset var address = lCase(trim(arguments.email))>
	<cfset var token = "">
	<cfset var link = "">
	<cfset var entity = "">
	<cfset var member = "">
	<cfif not isEnabled()>
		<cfset result.message = "Member accounts aren't available on this site.">
		<cfreturn result>
	</cfif>
	<cfif not len(address) or len(address) gt 255 or not isValid("email", address)>
		<cfset result.message = "Please enter a valid email address.">
		<cfreturn result>
	</cfif>
	<cfif not allowRequest(address, arguments.ipAddress)>
		<cfset result.message = "Too many sign-in emails were asked for. Please wait a few minutes and try again.">
		<cfreturn result>
	</cfif>
	<cfset result.success = true>
	<cfset result.message = "If that address can be used here, a sign-in link is on its way. It works once, for #variables.linkMinutes# minutes.">
	<!--- A blocked member gets the same reply but no email. --->
	<cfset member = findMemberByEmail(address)>
	<cfif isStruct(member) and member.status eq "blocked">
		<cfreturn result>
	</cfif>
	<cfset token = newToken()>
	<cftransaction>
		<cfset removeOldLoginTokens()>
		<cfset entity = entityNew("MemberLoginToken")>
		<cfset entity.setBlogRef(javacast("int", application.BlogDbObj.getBlogId()))>
		<cfset entity.setTokenHash(hashToken(token))>
		<cfset entity.setEmail(address)>
		<cfset entity.setPurpose("signIn")>
		<cfset entity.setExpires(dateAdd("n", variables.linkMinutes, now()))>
		<cfset entity.setUsed(false)>
		<cfset entity.setRequestIp(left(arguments.ipAddress, 64))>
		<cfset entity.setCreated(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset link = signInLink(token, arguments.returnUrl)>
	<cftry>
		<cfset sendSignInEmail(address, link)>
		<cfcatch type="any">
			<cflog file="galaxieMembers" type="error" text="The sign-in email couldn't be sent: #cfcatch.message#">
			<cfset result.success = false>
			<cfset result.message = "The sign-in email couldn't be sent. Please try again later.">
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<cffunction name="completeSignIn" access="public" returntype="struct" output="false"
		hint="Uses an emailed sign-in token: signs the visitor in (making their account on the first sign-in). Returns { success, message, member }.">
	<cfargument name="token" type="string" required="true">
	<cfargument name="remember" type="boolean" required="false" default="false">
	<cfargument name="userAgent" type="string" required="false" default="">
	<cfset var result = { success: false, message: "This sign-in link has expired or was already used. Please ask for a new one.", member: {} }>
	<cfset var found = []>
	<cfset var loginToken = "">
	<cfset var address = "">
	<cfset var entity = "">
	<cfif not isEnabled() or not reFind("^[a-f0-9]{64}$", arguments.token)>
		<cfreturn result>
	</cfif>
	<cftransaction>
		<cfset found = ormExecuteQuery("FROM MemberLoginToken WHERE BlogRef = :blogId AND TokenHash = :tokenHash AND Purpose = 'signIn'", { blogId = javacast("int", application.BlogDbObj.getBlogId()), tokenHash = hashToken(arguments.token) })>
		<cfif not arrayLen(found)>
			<cftransaction action="rollback"/>
			<cfreturn result>
		</cfif>
		<cfset loginToken = found[1]>
		<cfif isTrue(loginToken.getUsed(), true) or dateCompare(loginToken.getExpires(), now()) lt 0>
			<cftransaction action="rollback"/>
			<cfreturn result>
		</cfif>
		<!--- Used once, even if what follows fails. --->
		<cfset loginToken.setUsed(true)>
		<cfset entitySave(loginToken)>
		<cfset address = loginToken.getEmail()>
		<cfset found = ormExecuteQuery("FROM BlogMember WHERE BlogRef = :blogId AND Email = :email", { blogId = javacast("int", application.BlogDbObj.getBlogId()), email = address })>
		<cfif arrayLen(found)>
			<cfset entity = found[1]>
		<cfelse>
			<cfset entity = entityNew("BlogMember")>
			<cfset entity.setBlogRef(javacast("int", application.BlogDbObj.getBlogId()))>
			<cfset entity.setEmail(address)>
			<cfset entity.setName("")>
			<cfset entity.setPhone("")>
			<cfset entity.setTimeZone("")>
			<cfset entity.setStatus("active")>
			<cfset entity.setCreated(now())>
		</cfif>
		<cfif valueOrEmpty(entity.getStatus()) eq "blocked">
			<cfset entitySave(entity)>
			<cfset result.message = "This account can't be used. Please contact the site's owner.">
			<cfreturn result>
		</cfif>
		<!--- Clicking the link proves the address is theirs. --->
		<cfset entity.setEmailVerified(true)>
		<cfset entity.setLastSeen(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset startSession(entity)>
	<cfif arguments.remember>
		<cfset setRememberCookie(entity.getMemberId(), arguments.userAgent)>
	</cfif>
	<cfset result.success = true>
	<cfset result.message = "">
	<cfset result.member = getCurrentMember()>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	The signed-in member
********************************************************************************************************************* --->

<cffunction name="getCurrentMember" access="public" returntype="struct" output="false"
		hint="The signed-in member { memberId, email, name, phone, timeZone } or an empty struct. Signs the visitor back in from a 'Keep me signed in' cookie when their session has ended.">
	<cfset var member = "">
	<cfif not isEnabled()>
		<cfreturn {}>
	</cfif>
	<cfif not (structKeyExists(session, "galaxieMember") and isStruct(session.galaxieMember) and structKeyExists(session.galaxieMember, "memberId"))>
		<cfset restoreFromCookie()>
	</cfif>
	<cfif not (structKeyExists(session, "galaxieMember") and isStruct(session.galaxieMember) and structKeyExists(session.galaxieMember, "memberId"))>
		<cfreturn {}>
	</cfif>
	<!--- Read the member each time, so a blocked or deleted account stops working at once. --->
	<cfset member = getMember(session.galaxieMember.memberId)>
	<cfif structIsEmpty(member) or member.status neq "active">
		<cfset endSession()>
		<cfreturn {}>
	</cfif>
	<cfreturn member>
</cffunction>

<cffunction name="getMember" access="public" returntype="struct" output="false" hint="{ memberId, email, name, phone, timeZone, status, created, lastSeen } or an empty struct.">
	<cfargument name="memberId" type="numeric" required="true">
	<cfset var found = ormExecuteQuery("FROM BlogMember WHERE BlogRef = :blogId AND MemberId = :id", { blogId = javacast("int", application.BlogDbObj.getBlogId()), id = javacast("int", arguments.memberId) })>
	<cfif not arrayLen(found)>
		<cfreturn {}>
	</cfif>
	<cfreturn memberStruct(found[1])>
</cffunction>

<cffunction name="getCsrfToken" access="public" returntype="string" output="false" hint="The token a member's own changes must carry (one per session).">
	<cfif not structKeyExists(session, "galaxieMemberCsrf") or not len(session.galaxieMemberCsrf)>
		<cfset session.galaxieMemberCsrf = newToken()>
	</cfif>
	<cfreturn session.galaxieMemberCsrf>
</cffunction>

<cffunction name="checkCsrfToken" access="public" returntype="boolean" output="false">
	<cfargument name="token" type="string" required="true">
	<cfreturn structKeyExists(session, "galaxieMemberCsrf") and len(session.galaxieMemberCsrf) and compare(arguments.token, session.galaxieMemberCsrf) eq 0>
</cffunction>

<cffunction name="saveProfile" access="public" returntype="struct" output="false" hint="The signed-in member's own name, phone and time zone. Returns { success, errors[], member }.">
	<cfargument name="name" type="string" required="true">
	<cfargument name="phone" type="string" required="true">
	<cfargument name="timeZone" type="string" required="true">
	<cfset var result = { success: false, errors: [], member: {} }>
	<cfset var member = getCurrentMember()>
	<cfset var entity = "">
	<cfset var zone = trim(arguments.timeZone)>
	<cfif structIsEmpty(member)>
		<cfset arrayAppend(result.errors, "Please sign in again.")>
		<cfreturn result>
	</cfif>
	<cfif len(trim(arguments.name)) gt 125><cfset arrayAppend(result.errors, "The name is too long.")></cfif>
	<cfif len(trim(arguments.phone)) gt 50 or (len(trim(arguments.phone)) and not reFind("^[0-9+()\-. ]+$", trim(arguments.phone)))>
		<cfset arrayAppend(result.errors, "Please enter a phone number with digits, spaces and + ( ) - . only.")>
	</cfif>
	<cfif len(zone) and not isValidTimeZone(zone)><cfset arrayAppend(result.errors, "Please choose a time zone from the list.")></cfif>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>
	<cftransaction>
		<cfset entity = entityLoadByPK("BlogMember", javacast("int", member.memberId))>
		<cfset entity.setName(trim(arguments.name))>
		<cfset entity.setPhone(trim(arguments.phone))>
		<cfset entity.setTimeZone(zone)>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset result.success = true>
	<cfset result.member = getMember(member.memberId)>
	<cfreturn result>
</cffunction>

<cffunction name="signOut" access="public" returntype="void" output="false" hint="Signs out this browser, or every browser the member is signed in on.">
	<cfargument name="everywhere" type="boolean" required="false" default="false">
	<cfset var member = getCurrentMember()>
	<cfset var cookieToken = readRememberCookie()>
	<cftransaction>
		<cfif arguments.everywhere and not structIsEmpty(member)>
			<cfset ormExecuteQuery("DELETE FROM MemberRememberToken WHERE BlogRef = :blogId AND MemberRef = :memberId", { blogId = javacast("int", application.BlogDbObj.getBlogId()), memberId = javacast("int", member.memberId) })>
		<cfelseif len(cookieToken)>
			<cfset ormExecuteQuery("DELETE FROM MemberRememberToken WHERE BlogRef = :blogId AND TokenHash = :tokenHash", { blogId = javacast("int", application.BlogDbObj.getBlogId()), tokenHash = hashToken(cookieToken) })>
		</cfif>
	</cftransaction>
	<cfset clearRememberCookie()>
	<cfset endSession()>
</cffunction>

<!--- ********************************************************************************************************************
	My account (2026-10-15): the member's bookings, form sign-ups and email subscriptions, found by their email address (the
	address they proved is theirs by signing in), so things done before the account existed show up too.
********************************************************************************************************************* --->

<cffunction name="getAccountBookings" access="public" returntype="array" output="false"
		hint="The member's bookings, newest first: [{ typeName, when, upcoming, status, statusText, location, paid, stillToPay, refunded, manageToken (when it can still be changed), payToken (when the rest can be paid online) }].">
	<cfargument name="member" type="struct" required="true">
	<cfset var rows = queryExecute("SELECT BookingId FROM Booking WHERE BlogRef = :blogId AND LOWER(Email) = :email AND Status NOT IN ('held', 'expired') ORDER BY StartUtc DESC",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, email = { value = lCase(arguments.member.email), cfsqltype = "cf_sql_varchar" } })>
	<cfset var list = []>
	<cfset var b = {}>
	<cfset var zone = "">
	<cfset var statusText = { "pending": "Waiting for approval", "confirmed": "Confirmed", "cancelled": "Cancelled", "completed": "Completed", "noShow": "Missed" }>
	<cfset var nowInstant = createObject("java", "java.time.Instant").now()>
	<cfset var upcoming = false>
	<cfloop query="rows">
		<cfset b = application.bookings.getBooking(bookingId = rows.BookingId)>
		<cfif structIsEmpty(b)><cfcontinue></cfif>
		<!--- Their own time zone first, then the one they booked in, then the blog's. --->
		<cfset zone = len(arguments.member.timeZone) ? arguments.member.timeZone : (len(b.visitorTimeZone) ? b.visitorTimeZone : b.timeZone)>
		<cftry>
			<cfset upcoming = createObject("java", "java.time.Instant").parse(b.startUtc).isAfter(nowInstant)>
			<cfcatch type="any"><cfset upcoming = false></cfcatch>
		</cftry>
		<cfset arrayAppend(list, {
			"bookingId": b.bookingId,
			"typeName": structIsEmpty(b.bookingType) ? "Booking" : b.bookingType.name,
			"when": application.bookings.formatInZone(b.startUtc, zone),
			"upcoming": upcoming,
			"status": b.status,
			"statusText": structKeyExists(statusText, b.status) ? statusText[b.status] : b.status,
			"location": structIsEmpty(b.location) ? "" : b.location.label,
			"paid": b.amountPaid gt 0 ? application.payments.formatMoney(b.amountPaid, b.currency) : "",
			"refunded": b.amountRefunded gt 0 ? application.payments.formatMoney(b.amountRefunded, b.currency) : "",
			"stillToPay": b.balanceDue gt 0 and listFind("confirmed,pending", b.status) ? application.payments.formatMoney(b.balanceDue, b.currency) : "",
			"manageToken": upcoming and application.bookings.canChange(b) ? b.manageToken : "",
			"payToken": upcoming and application.bookings.canPayBalanceOnline(b) ? b.manageToken : ""
		})>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="getAccountSignups" access="public" returntype="array" output="false"
		hint="The member's form sign-ups, newest first (not the questions answered when booking, which belong to the booking): [{ formTitle, postTitle, postUrl, date, event }]. For an event RSVP, event is { when, people, status, canCancel, token } - the token is their own cancel link's, so My account can cancel through cancelManagedRsvp.">
	<cfargument name="member" type="struct" required="true">
	<cfset var rows = queryExecute("
		SELECT s.WebFormSubmissionId, s.Created, s.PostRef, s.EventRef, w.Title AS FormTitle, p.Title AS PostTitle
		FROM WebFormSubmission s
			INNER JOIN WebForm w ON w.WebFormId = s.WebFormRef
			LEFT JOIN Post p ON p.PostId = s.PostRef
		WHERE w.BlogRef = :blogId AND LOWER(s.Email) = :email
			AND s.WebFormSubmissionId NOT IN (SELECT b.WebFormSubmissionRef FROM Booking b WHERE b.WebFormSubmissionRef > 0)
			AND (s.Status IS NULL OR s.Status NOT IN ('held', 'expired'))
		ORDER BY s.Created DESC",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, email = { value = lCase(arguments.member.email), cfsqltype = "cf_sql_varchar" } })>
	<cfset var list = []>
	<cfset var rsvp = {}>
	<cfset var eventInfo = {}>
	<cfloop query="rows">
		<cfset eventInfo = {}>
		<cfif val(rows.EventRef) gt 0 and structKeyExists(application, "events")>
			<cfset rsvp = application.events.getRsvp(submissionId = rows.WebFormSubmissionId)>
			<cfif not structIsEmpty(rsvp) and not structIsEmpty(rsvp.ev)>
				<cfset eventInfo = { "when": application.events.whenText(rsvp.ev), "people": rsvp.partySize, "how": structIsEmpty(rsvp.location) ? "" : rsvp.location.label, "status": rsvp.status, "canCancel": rsvp.canCancel, "token": rsvp.canCancel ? rsvp.manageToken : "", "paid": rsvp.amountPaid gt 0 ? application.payments.formatMoney(rsvp.amountPaid) : "" }>
			</cfif>
		</cfif>
		<cfset arrayAppend(list, {
			"event": eventInfo,
			"formTitle": rows.FormTitle,
			"postTitle": isNull(rows.PostTitle) ? "" : rows.PostTitle,
			"postUrl": val(rows.PostRef) gt 0 and len(rows.PostTitle) ? application.blog.getPostUrlByPostId(rows.PostRef) : "",
			"date": isDate(rows.Created) ? dateFormat(rows.Created, "mmmm d, yyyy") : ""
		})>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="getAccountSubscriptions" access="public" returntype="struct" output="false"
		hint="{ newPosts: on|off|unconfirmed, posts: [{ postId, title, url }] } - new-post emails, and the posts whose new comments they're emailed about (from following a post, or ticking 'notify me' on their own comment).">
	<cfargument name="member" type="struct" required="true">
	<cfset var params = { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, email = { value = lCase(arguments.member.email), cfsqltype = "cf_sql_varchar" } }>
	<cfset var all = queryExecute("SELECT SubscriberVerified, Active FROM Subscriber WHERE BlogRef = :blogId AND LOWER(SubscriberEmail) = :email AND SubscribeAll = 1", params)>
	<cfset var followed = queryExecute("
		SELECT DISTINCT p.PostId, p.Title
		FROM PostSubscriber ps
			INNER JOIN Subscriber s ON s.SubscriberId = ps.SubscriberRef
			INNER JOIN Post p ON p.PostId = ps.PostRef
		WHERE s.BlogRef = :blogId AND LOWER(s.SubscriberEmail) = :email AND (s.Active = 1 OR s.Active IS NULL)
		UNION
		SELECT DISTINCT p.PostId, p.Title
		FROM Comment c
			INNER JOIN Commenter m ON m.CommenterId = c.CommenterRef
			INNER JOIN Post p ON p.PostId = c.PostRef
		WHERE c.BlogRef = :blogId AND LOWER(m.Email) = :email AND c.Subscribe = 1", params)>
	<cfset var result = { "newPosts": "off", "posts": [] }>
	<cfloop query="all">
		<cfif isTrue(all.Active, true)>
			<cfset result[ "newPosts" ] = isTrue(all.SubscriberVerified, false) ? "on" : "unconfirmed">
		</cfif>
	</cfloop>
	<cfloop query="followed">
		<cfset arrayAppend(result.posts, { "postId": followed.PostId, "title": followed.Title, "url": application.blog.getPostUrlByPostId(followed.PostId) })>
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="setNewPostEmails" access="public" returntype="boolean" output="false"
		hint="Turns new-post emails on or off for the signed-in member. On needs no confirmation email: signing in already proved the address is theirs.">
	<cfargument name="on" type="boolean" required="true">
	<cfset var member = getCurrentMember()>
	<cfset var params = {}>
	<cfset var rows = "">
	<cfset var entity = "">
	<cfif structIsEmpty(member)>
		<cfreturn false>
	</cfif>
	<cfset params = { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, email = { value = lCase(member.email), cfsqltype = "cf_sql_varchar" } }>
	<cftransaction>
		<cfset rows = queryExecute("SELECT SubscriberId FROM Subscriber WHERE BlogRef = :blogId AND LOWER(SubscriberEmail) = :email ORDER BY SubscribeAll DESC, SubscriberId", params)>
		<cfif arguments.on>
			<cfif rows.recordCount>
				<cfset queryExecute("UPDATE Subscriber SET SubscribeAll = 1, SubscriberVerified = 1, Active = 1 WHERE SubscriberId = :id", { id = { value = rows.SubscriberId[1], cfsqltype = "cf_sql_integer" } })>
			<cfelse>
				<cfset entity = entityNew("Subscriber")>
				<cfset entity.setBlogRef(application.BlogDbObj)>
				<cfset entity.setSubscriberEmail(lCase(member.email))>
				<cfset entity.setSubscriberToken(createUUID())>
				<cfset entity.setSubscriberVerified(true)>
				<cfset entity.setSubscribeAll(true)>
				<cfset entity.setActive(true)>
				<cfset entity.setDate(application.blog.blogNow())>
				<cfset entitySave(entity)>
			</cfif>
		<cfelse>
			<!--- Off: posts they follow keep coming (they're stopped one by one below). --->
			<cfset queryExecute("UPDATE Subscriber SET SubscribeAll = 0 WHERE BlogRef = :blogId AND LOWER(SubscriberEmail) = :email", params)>
		</cfif>
	</cftransaction>
	<cfreturn true>
</cffunction>

<cffunction name="stopFollowingPost" access="public" returntype="boolean" output="false"
		hint="Stops the new-comment emails for one post, however the member started them.">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var member = getCurrentMember()>
	<cfset var params = {}>
	<cfif structIsEmpty(member)>
		<cfreturn false>
	</cfif>
	<cfset params = { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, email = { value = lCase(member.email), cfsqltype = "cf_sql_varchar" }, postId = { value = arguments.postId, cfsqltype = "cf_sql_integer" } }>
	<cftransaction>
		<cfset queryExecute("DELETE FROM PostSubscriber WHERE PostRef = :postId AND SubscriberRef IN (SELECT SubscriberId FROM Subscriber WHERE BlogRef = :blogId AND LOWER(SubscriberEmail) = :email)", params)>
		<cfset queryExecute("UPDATE Comment SET Subscribe = 0 WHERE BlogRef = :blogId AND PostRef = :postId AND CommenterRef IN (SELECT CommenterId FROM Commenter WHERE LOWER(Email) = :email)", params)>
	</cftransaction>
	<cfreturn true>
</cffunction>

<!--- ********************************************************************************************************************
	Download my data and Delete my account (2026-10-15)
********************************************************************************************************************* --->

<cffunction name="exportData" access="public" returntype="struct" output="false"
		hint="Everything the blog keeps about the signed-in member, for 'Download my data': profile, bookings (with their answers, not the owner's private notes), form sign-ups (with their answers), subscriptions, comments and the devices kept signed in. Keys are quoted so they keep their case in the JSON on every engine.">
	<cfargument name="member" type="struct" required="true">
	<cfset var params = { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, email = { value = lCase(arguments.member.email), cfsqltype = "cf_sql_varchar" } }>
	<cfset var data = {
		"exported": dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
		"site": application.BlogDbObj.getBlogTitle(),
		"siteAddress": application.blogHostUrl,
		"profile": {
			"email": arguments.member.email, "name": arguments.member.name, "phone": arguments.member.phone, "timeZone": arguments.member.timeZone,
			"joined": isDate(arguments.member.created) ? dateTimeFormat(arguments.member.created, "yyyy-mm-dd HH:nn") : "",
			"lastSeen": isDate(arguments.member.lastSeen) ? dateTimeFormat(arguments.member.lastSeen, "yyyy-mm-dd HH:nn") : ""
		},
		"bookings": [], "signUps": [], "subscriptions": getAccountSubscriptions(arguments.member), "comments": [], "signedInDevices": []
	}>
	<cfset var rows = "">
	<cfset var b = {}>
	<cfset var answers = []>
	<cfset var answer = "">
	<cfset var forms = {}>
	<cfset var values = {}>
	<cfset var field = "">
	<cfset var labelled = []>

	<!--- Bookings --->
	<cfset rows = queryExecute("SELECT BookingId FROM Booking WHERE BlogRef = :blogId AND LOWER(Email) = :email ORDER BY StartUtc DESC", params)>
	<cfloop query="rows">
		<cfset b = application.bookings.getBooking(bookingId = rows.BookingId)>
		<cfif structIsEmpty(b)><cfcontinue></cfif>
		<cfset answers = []>
		<cfloop array="#b.answers#" index="answer">
			<cfset arrayAppend(answers, { "question": answer.label, "answer": answer.value })>
		</cfloop>
		<cfset arrayAppend(data.bookings, {
			"what": structIsEmpty(b.bookingType) ? "Booking" : b.bookingType.name,
			"startsUtc": b.startUtc, "startsLocal": b.startLocal, "timeZone": b.timeZone,
			"where": structIsEmpty(b.location) ? "" : b.location.label,
			"people": b.partySize, "status": b.status,
			"name": b.name, "email": b.email, "phone": b.phone,
			"total": b.amountTotal, "paid": b.amountPaid, "refunded": b.amountRefunded, "stillToPay": b.balanceDue, "currency": b.currency,
			"answers": answers,
			"made": isDate(b.created) ? dateTimeFormat(b.created, "yyyy-mm-dd HH:nn") : ""
		})>
	</cfloop>

	<!--- Form sign-ups, answers under their questions --->
	<cfset rows = queryExecute("
		SELECT s.WebFormSubmissionId, s.WebFormRef, s.Created, s.Name, s.Email, s.ValuesJson, w.Title AS FormTitle, p.Title AS PostTitle
		FROM WebFormSubmission s
			INNER JOIN WebForm w ON w.WebFormId = s.WebFormRef
			LEFT JOIN Post p ON p.PostId = s.PostRef
		WHERE w.BlogRef = :blogId AND LOWER(s.Email) = :email
			AND s.WebFormSubmissionId NOT IN (SELECT b.WebFormSubmissionRef FROM Booking b WHERE b.WebFormSubmissionRef > 0)
		ORDER BY s.Created DESC", params)>
	<cfloop query="rows">
		<cfset values = len(rows.ValuesJson) and isJSON(rows.ValuesJson) ? deserializeJSON(rows.ValuesJson) : {}>
		<cfif not structKeyExists(forms, rows.WebFormRef)>
			<cfset forms[rows.WebFormRef] = application.webForms.getForm(webFormId = rows.WebFormRef)>
		</cfif>
		<cfset labelled = []>
		<cfif structKeyExists(forms[rows.WebFormRef], "fields")>
			<cfloop array="#forms[rows.WebFormRef].fields#" index="field">
				<cfif structKeyExists(values, field.fieldName)>
					<cfset arrayAppend(labelled, { "question": field.label, "answer": isArray(values[field.fieldName]) ? arrayToList(values[field.fieldName], ", ") : values[field.fieldName] })>
				</cfif>
			</cfloop>
		</cfif>
		<cfset arrayAppend(data.signUps, {
			"form": rows.FormTitle, "page": rows.PostTitle, "name": rows.Name, "email": rows.Email,
			"sent": isDate(rows.Created) ? dateTimeFormat(rows.Created, "yyyy-mm-dd HH:nn") : "",
			"answers": labelled
		})>
	</cfloop>

	<!--- Comments --->
	<cfset rows = queryExecute("
		SELECT c.Comment, c.DatePosted, p.Title AS PostTitle
		FROM Comment c
			INNER JOIN Commenter m ON m.CommenterId = c.CommenterRef
			LEFT JOIN Post p ON p.PostId = c.PostRef
		WHERE c.BlogRef = :blogId AND LOWER(m.Email) = :email
		ORDER BY c.DatePosted DESC", params)>
	<cfloop query="rows">
		<cfset arrayAppend(data.comments, { "post": rows.PostTitle, "posted": isDate(rows.DatePosted) ? dateTimeFormat(rows.DatePosted, "yyyy-mm-dd HH:nn") : "", "comment": rows.Comment })>
	</cfloop>

	<!--- Devices kept signed in --->
	<cfset rows = queryExecute("SELECT UserAgent, Created, LastUsed, Expires FROM MemberRememberToken WHERE BlogRef = :blogId AND MemberRef = :memberId ORDER BY LastUsed DESC",
		{ blogId = params.blogId, memberId = { value = arguments.member.memberId, cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cfset arrayAppend(data.signedInDevices, {
			"browser": rows.UserAgent,
			"signedIn": isDate(rows.Created) ? dateTimeFormat(rows.Created, "yyyy-mm-dd HH:nn") : "",
			"lastUsed": isDate(rows.LastUsed) ? dateTimeFormat(rows.LastUsed, "yyyy-mm-dd HH:nn") : "",
			"until": isDate(rows.Expires) ? dateTimeFormat(rows.Expires, "yyyy-mm-dd") : ""
		})>
	</cfloop>
	<cfreturn data>
</cffunction>

<cffunction name="countUpcomingBookings" access="public" returntype="numeric" output="false" hint="Upcoming bookings still on (shown before deleting the account).">
	<cfargument name="member" type="struct" required="true">
	<cfset var count = 0>
	<cfset var b = "">
	<cfloop array="#getAccountBookings(arguments.member)#" index="b">
		<cfif b.upcoming and listFind("confirmed,pending", b.status)><cfset count++></cfif>
	</cfloop>
	<cfreturn count>
</cffunction>

<cffunction name="deleteAccount" access="public" returntype="struct" output="false"
		hint="Deletes the signed-in member's account: the member, their sign-in links and the devices kept signed in, and (when asked) every email subscription. Bookings, payments, form sign-ups and comments are the site owner's records and are kept. Returns { success, message }.">
	<cfargument name="confirmEmail" type="string" required="true" hint="The member types their address, so it can't happen by accident.">
	<cfargument name="stopEmails" type="boolean" required="true">
	<cfset var member = getCurrentMember()>
	<cfset var params = {}>
	<cfif structIsEmpty(member)>
		<cfreturn { success: false, message: "Please sign in again." }>
	</cfif>
	<cfif lCase(trim(arguments.confirmEmail)) neq lCase(member.email)>
		<cfreturn { success: false, message: "Type your email address exactly as it's shown to confirm." }>
	</cfif>
	<cfset removeMember(member.memberId, member.email, arguments.stopEmails)>
	<cflog file="galaxieMembers" type="information" text="Member #member.memberId# deleted their account.">
	<cfset clearRememberCookie()>
	<cfset endSession()>
	<cfreturn { success: true, message: "" }>
</cffunction>

<cffunction name="adminDeleteMember" access="public" returntype="boolean" output="false"
		hint="The site owner deletes a member (Members window): the same as the member deleting their own account. They're signed out everywhere at once, because every page checks the account still exists.">
	<cfargument name="memberId" type="numeric" required="true">
	<cfargument name="stopEmails" type="boolean" required="true">
	<cfset var member = getMember(arguments.memberId)>
	<cfif structIsEmpty(member)>
		<cfreturn false>
	</cfif>
	<cfset removeMember(member.memberId, member.email, arguments.stopEmails)>
	<cflog file="galaxieMembers" type="information" text="Member #member.memberId# was deleted by #getAuthUser()#.">
	<cfreturn true>
</cffunction>

<cffunction name="removeMember" access="private" returntype="void" output="false"
		hint="Deletes a member, their sign-in links and remembered devices, and (when asked) their email subscriptions. Bookings, payments, form sign-ups and comments are the site owner's records and are kept.">
	<cfargument name="memberId" type="numeric" required="true">
	<cfargument name="email" type="string" required="true">
	<cfargument name="stopEmails" type="boolean" required="true">
	<cfset var params = { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, email = { value = lCase(arguments.email), cfsqltype = "cf_sql_varchar" }, memberId = { value = arguments.memberId, cfsqltype = "cf_sql_integer" } }>
	<cftransaction>
		<cfset queryExecute("DELETE FROM MemberRememberToken WHERE BlogRef = :blogId AND MemberRef = :memberId", params)>
		<cfset queryExecute("DELETE FROM MemberLoginToken WHERE BlogRef = :blogId AND LOWER(Email) = :email", params)>
		<cfif arguments.stopEmails>
			<cfset queryExecute("DELETE FROM PostSubscriber WHERE SubscriberRef IN (SELECT SubscriberId FROM Subscriber WHERE BlogRef = :blogId AND LOWER(SubscriberEmail) = :email)", params)>
			<cfset queryExecute("DELETE FROM Subscriber WHERE BlogRef = :blogId AND LOWER(SubscriberEmail) = :email", params)>
			<cfset queryExecute("UPDATE Comment SET Subscribe = 0 WHERE BlogRef = :blogId AND CommenterRef IN (SELECT CommenterId FROM Commenter WHERE LOWER(Email) = :email)", params)>
		</cfif>
		<cfset queryExecute("DELETE FROM BlogMember WHERE BlogRef = :blogId AND MemberId = :memberId", params)>
	</cftransaction>
</cffunction>

<cffunction name="countRememberedDevices" access="public" returntype="numeric" output="false" hint="Devices the member is kept signed in on (Members window).">
	<cfargument name="memberId" type="numeric" required="true">
	<cfreturn queryExecute("SELECT COUNT(*) AS n FROM MemberRememberToken WHERE BlogRef = :blogId AND MemberRef = :memberId AND Expires > :now",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, memberId = { value = arguments.memberId, cfsqltype = "cf_sql_integer" }, now = { value = now(), cfsqltype = "cf_sql_timestamp" } }).n>
</cffunction>

<!--- ********************************************************************************************************************
	Admin: the Members window
********************************************************************************************************************* --->

<cffunction name="getMembersForAdmin" access="public" returntype="array" output="false" hint="Every member, newest first: [{ memberId, email, name, phone, status, created, lastSeen }].">
	<cfset var rows = ormExecuteQuery("FROM BlogMember WHERE BlogRef = :blogId ORDER BY MemberId DESC", { blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfset var members = []>
	<cfset var row = "">
	<cfloop array="#rows#" index="row">
		<cfset arrayAppend(members, memberStruct(row))>
	</cfloop>
	<cfreturn members>
</cffunction>

<cffunction name="getPeopleForAdmin" access="public" returntype="array" output="false"
		hint="The combined Members list (2026-10-17, owner): everyone who isn't running the blog, one entry per email address, matched across member accounts, subscribers, bookings, event sign-ups, form sends and the profiles shown on the site. Built from the existing tables when the window opens; nothing is copied. Commenters are left out (owner). Newest activity first: [{ email, name, phone, memberId, memberStatus, isMember, onSite, personCardId, isSubscriber, subscriberConfirmed, bookings, signUps, forms, isUser, labels[], lastActivity, lastActivityText, since }].">
	<cfset var params = { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, yes = { value = true, cfsqltype = "cf_sql_bit" } }>
	<cfset var people = {}>
	<cfset var rows = "">
	<cfset var key = "">
	<cfset var person = {}>
	<cfset var list = []>

	<!--- One entry per lower-cased email; the name and phone come from the newest record that has one. --->
	<cfscript>
	var touch = function(required string email, string name = "", string phone = "", any when = "", string what = "") {
		var k = lCase(trim(arguments.email));
		if (!len(k) || !isValid("email", k)) { return {}; }
		if (!structKeyExists(people, k)) {
			people[k] = { email: k, name: "", phone: "", nameDate: "", memberId: 0, memberStatus: "", isMember: false, onSite: false, personCardId: 0,
				isSubscriber: false, subscriberConfirmed: false, bookings: 0, signUps: 0, forms: 0, isUser: false,
				labels: [], lastActivity: "", lastActivityText: "", since: "" };
		}
		var p = people[k];
		if (isDate(arguments.when)) {
			if (len(trim(arguments.name)) && (!isDate(p.nameDate) || dateCompare(arguments.when, p.nameDate) gt 0)) { p.name = trim(arguments.name); p.nameDate = arguments.when; }
			if (!isDate(p.lastActivity) || dateCompare(arguments.when, p.lastActivity) gt 0) { p.lastActivity = arguments.when; p.lastActivityText = arguments.what; }
			if (!isDate(p.since) || dateCompare(arguments.when, p.since) lt 0) { p.since = arguments.when; }
		} else if (len(trim(arguments.name)) && !len(p.name)) {
			p.name = trim(arguments.name);
		}
		if (len(trim(arguments.phone)) && !len(p.phone)) { p.phone = trim(arguments.phone); }
		return p;
	};
	</cfscript>

	<!--- Member accounts --->
	<cfset rows = queryExecute("SELECT MemberId, Email, Name, Phone, Status, Created, LastSeen FROM BlogMember WHERE BlogRef = :blogId", params)>
	<cfloop query="rows">
		<cfset person = touch(rows.Email, rows.Name, rows.Phone, rows.Created, "Created an account")>
		<cfif not structIsEmpty(person)>
			<cfset person.isMember = true>
			<cfset person.memberId = rows.MemberId>
			<cfset person.memberStatus = len(rows.Status) ? rows.Status : "active">
			<cfif isDate(rows.LastSeen)><cfset touch(rows.Email, "", "", rows.LastSeen, "Signed in")></cfif>
		</cfif>
	</cfloop>

	<!--- Subscribers: unsubscribed ones are left out; ones who never confirmed are shown, marked. --->
	<cfset rows = queryExecute("SELECT SubscriberEmail, SubscriberVerified, Date FROM Subscriber WHERE BlogRef = :blogId AND Active = :yes", params)>
	<cfloop query="rows">
		<cfset person = touch(rows.SubscriberEmail, "", "", rows.Date, "Subscribed")>
		<cfif not structIsEmpty(person)>
			<cfset person.isSubscriber = true>
			<cfif isBoolean(rows.SubscriberVerified) and rows.SubscriberVerified><cfset person.subscriberConfirmed = true></cfif>
		</cfif>
	</cfloop>

	<!--- Bookings (not the ones held for a payment that never came) --->
	<cfset rows = queryExecute("
		SELECT b.Email, b.Name, b.Phone, b.Created, t.Name AS TypeName
		FROM Booking b
			LEFT JOIN BookingType t ON t.BookingTypeId = b.BookingTypeRef
		WHERE b.BlogRef = :blogId AND (b.Status IS NULL OR b.Status NOT IN ('held', 'expired'))", params)>
	<cfloop query="rows">
		<cfset person = touch(rows.Email, rows.Name, rows.Phone, rows.Created, "Booked " & (len(rows.TypeName) ? rows.TypeName : "a session"))>
		<cfif not structIsEmpty(person)><cfset person.bookings++></cfif>
	</cfloop>

	<!--- Event sign-ups and form sends (the answers given when booking belong to the booking) --->
	<cfset rows = queryExecute("
		SELECT s.Email, s.Name, s.Created, s.EventRef, w.Title AS FormTitle, p.Title AS PostTitle
		FROM WebFormSubmission s
			INNER JOIN WebForm w ON w.WebFormId = s.WebFormRef
			LEFT JOIN Post p ON p.PostId = s.PostRef
		WHERE w.BlogRef = :blogId
			AND s.WebFormSubmissionId NOT IN (SELECT bk.WebFormSubmissionRef FROM Booking bk WHERE bk.WebFormSubmissionRef > 0)
			AND (s.Status IS NULL OR s.Status NOT IN ('held', 'expired'))", params)>
	<cfloop query="rows">
		<cfif val(rows.EventRef) gt 0>
			<cfset person = touch(rows.Email, rows.Name, "", rows.Created, "Signed up for " & (len(rows.PostTitle) ? rows.PostTitle : "an event"))>
			<cfif not structIsEmpty(person)><cfset person.signUps++></cfif>
		<cfelse>
			<cfset person = touch(rows.Email, rows.Name, "", rows.Created, "Sent " & (len(rows.FormTitle) ? rows.FormTitle : "a form"))>
			<cfif not structIsEmpty(person)><cfset person.forms++></cfif>
		</cfif>
	</cfloop>

	<!--- Profiles shown on the site (People.cfc's cards for people who don't run the blog) --->
	<cftry>
		<cfset rows = queryExecute("SELECT PersonCardId, DisplayName, Email, Active, Created FROM PersonCard WHERE BlogRef = :blogId", params)>
		<cfloop query="rows">
			<cfset person = touch(rows.Email, rows.DisplayName, "", rows.Created, "Added to the site")>
			<cfif not structIsEmpty(person)>
				<cfset person.personCardId = rows.PersonCardId>
				<cfif isBoolean(rows.Active) and rows.Active><cfset person.onSite = true></cfif>
			</cfif>
		</cfloop>
		<!--- No PersonCard table yet: it's made the first time People is used. --->
		<cfcatch type="database"></cfcatch>
	</cftry>

	<!--- Also a user: only noted, users are never added to the list. --->
	<cfset rows = queryExecute("SELECT Email FROM Users WHERE BlogRef = :blogId", params)>
	<cfloop query="rows">
		<cfset key = lCase(trim(rows.Email))>
		<cfif len(key) and structKeyExists(people, key)><cfset people[key].isUser = true></cfif>
	</cfloop>

	<cfloop collection="#people#" item="key">
		<cfset person = people[key]>
		<cfif person.isMember><cfset arrayAppend(person.labels, person.memberStatus eq "blocked" ? "Member (blocked)" : "Member")></cfif>
		<cfif person.onSite><cfset arrayAppend(person.labels, "On the site")></cfif>
		<cfif person.isSubscriber><cfset arrayAppend(person.labels, person.subscriberConfirmed ? "Subscriber" : "Subscriber (not confirmed)")></cfif>
		<cfif person.bookings><cfset arrayAppend(person.labels, "Booked " & person.bookings)></cfif>
		<cfif person.signUps><cfset arrayAppend(person.labels, "Signed up " & person.signUps)></cfif>
		<cfif person.forms><cfset arrayAppend(person.labels, "Forms " & person.forms)></cfif>
		<cfset structDelete(person, "nameDate")>
		<cfset arrayAppend(list, person)>
	</cfloop>
	<cfset arraySort(list, function(a, b) {
		if (!isDate(a.lastActivity)) { return 1; }
		if (!isDate(b.lastActivity)) { return -1; }
		return dateCompare(b.lastActivity, a.lastActivity);
	})>
	<cfreturn list>
</cffunction>

<cffunction name="getPersonForAdmin" access="public" returntype="struct" output="false"
		hint="One person from the combined Members list, by email address (window 98, 2026-10-17), or an empty struct. Also gives 'member': their account (getMember) when they have one, otherwise the same shape built from what they've sent, so the account functions below (bookings, sign-ups, emails, exportData) work for everyone.">
	<cfargument name="email" type="string" required="true">
	<cfset var key = lCase(trim(arguments.email))>
	<cfset var person = {}>
	<cfset var found = {}>
	<cfloop array="#getPeopleForAdmin()#" index="person">
		<cfif person.email eq key><cfset found = person><cfbreak></cfif>
	</cfloop>
	<cfif structIsEmpty(found)>
		<cfreturn {}>
	</cfif>
	<cfif found.isMember>
		<cfset found.member = getMember(found.memberId)>
	</cfif>
	<cfif not structKeyExists(found, "member") or structIsEmpty(found.member)>
		<cfset found.member = { memberId: 0, email: found.email, name: found.name, phone: found.phone, timeZone: "", status: "", created: "", lastSeen: "" }>
	</cfif>
	<cfreturn found>
</cffunction>

<cffunction name="getDeleteBlockers" access="public" returntype="array" output="false"
		hint="What stops a person being deleted from Members (2026-10-17, owner): an upcoming booking, a place at an upcoming event, or an event they host. Each is a sentence saying what to do first; an empty array means they can be deleted.">
	<cfargument name="email" type="string" required="true">
	<cfset var key = lCase(trim(arguments.email))>
	<cfset var blockers = []>
	<cfset var b = {}>
	<cfset var rows = "">
	<cfset var nowInstant = createObject("java", "java.time.Instant").now()>
	<cfset var person = getPersonForAdmin(key)>
	<cfset var hosted = []>
	<cfset var title = "">
	<!--- Upcoming bookings still on --->
	<cfloop array="#getAccountBookings({ email: key, timeZone: application.blog.getBlogTimeZoneId() })#" index="b">
		<cfif b.upcoming and listFind("confirmed,pending", b.status)>
			<cfset arrayAppend(blockers, "They have a booking on " & b.when & ". Cancel it first (open it under Bookings on their page).")>
		</cfif>
	</cfloop>
	<!--- Places at upcoming events --->
	<cfset rows = queryExecute("
		SELECT e.EndUtc, e.Status AS EventStatus, p.Title AS PostTitle
		FROM WebFormSubmission s
			INNER JOIN BlogEvent e ON e.EventId = s.EventRef
			LEFT JOIN Post p ON p.PostId = e.PostRef
		WHERE e.BlogRef = :blogId AND s.EventRef > 0 AND LOWER(s.Email) = :email AND s.Status = 'confirmed'",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, email = { value = key, cfsqltype = "cf_sql_varchar" } })>
	<cfloop query="rows">
		<cftry>
			<cfif rows.EventStatus neq "cancelled" and len(rows.EndUtc) and nowInstant.isBefore(createObject("java", "java.time.Instant").parse(rows.EndUtc))>
				<cfset arrayAppend(blockers, "They have a place at " & (len(rows.PostTitle) ? rows.PostTitle : "an upcoming event") & ". Cancel their place first, under the event's Sign-ups.")>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfloop>
	<!--- Events they host --->
	<cfif not structIsEmpty(person) and person.personCardId gt 0 and structKeyExists(application, "events")>
		<cfset hosted = application.events.getPeople().getEventsUsing("guest:" & person.personCardId)>
		<cfloop array="#hosted#" index="title">
			<cfset arrayAppend(blockers, "They host " & title & ". Choose another host for it first.")>
		</cfloop>
	</cfif>
	<cfreturn blockers>
</cffunction>

<cffunction name="adminDeletePerson" access="public" returntype="struct" output="false"
		hint="Delete everything (Members, 2026-10-17, owner's choice b): their account (signed out everywhere), sign-in links, email subscriptions and profile on the site are deleted; on past bookings, sign-ups and form sends the name, email, phone and answers are replaced with 'Deleted person', keeping the dates and amounts for the owner's records. Payments hold no personal details. Comments are left as they are. Refused while getDeleteBlockers finds anything. Returns { success, blockers[] }.">
	<cfargument name="email" type="string" required="true">
	<cfset var key = lCase(trim(arguments.email))>
	<cfset var result = { success: false, blockers: [] }>
	<cfset var person = {}>
	<cfset var params = {}>
	<cfif not len(key) or not isValid("email", key)>
		<cfreturn result>
	</cfif>
	<cfset person = getPersonForAdmin(key)>
	<cfif structIsEmpty(person)>
		<cfreturn result>
	</cfif>
	<cfset result.blockers = getDeleteBlockers(key)>
	<cfif arrayLen(result.blockers)>
		<cfreturn result>
	</cfif>
	<cfset params = {
		blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" },
		email = { value = key, cfsqltype = "cf_sql_varchar" },
		deleted = { value = "Deleted person", cfsqltype = "cf_sql_varchar" },
		empty = { value = "", cfsqltype = "cf_sql_varchar" },
		emptyJson = { value = "{}", cfsqltype = "cf_sql_longvarchar" }
	}>
	<!--- The account first: removeMember has its own transaction, and deletes the subscriptions too. --->
	<cfif person.member.memberId gt 0>
		<cfset removeMember(person.member.memberId, key, true)>
	</cfif>
	<cftransaction>
		<cfset queryExecute("UPDATE Booking SET Name = :deleted, Email = :empty, Phone = :empty, ManageToken = :empty WHERE BlogRef = :blogId AND LOWER(Email) = :email", params)>
		<cfset queryExecute("
			UPDATE WebFormSubmission SET Name = :deleted, Email = :empty, ValuesJson = :emptyJson, ManageToken = :empty
			WHERE LOWER(Email) = :email AND WebFormRef IN (SELECT WebFormId FROM WebForm WHERE BlogRef = :blogId)", params)>
		<cfset queryExecute("DELETE FROM PostSubscriber WHERE SubscriberRef IN (SELECT SubscriberId FROM Subscriber WHERE BlogRef = :blogId AND LOWER(SubscriberEmail) = :email)", params)>
		<cfset queryExecute("DELETE FROM Subscriber WHERE BlogRef = :blogId AND LOWER(SubscriberEmail) = :email", params)>
		<cfset queryExecute("UPDATE Comment SET Subscribe = 0 WHERE BlogRef = :blogId AND CommenterRef IN (SELECT CommenterId FROM Commenter WHERE LOWER(Email) = :email)", params)>
		<cfset queryExecute("DELETE FROM MemberLoginToken WHERE BlogRef = :blogId AND LOWER(Email) = :email", params)>
		<cftry>
			<cfset queryExecute("DELETE FROM PersonCard WHERE BlogRef = :blogId AND LOWER(Email) = :email", params)>
			<!--- No PersonCard table yet: nothing to delete. --->
			<cfcatch type="database"></cfcatch>
		</cftry>
	</cftransaction>
	<cflog file="galaxieMembers" type="information" text="A person was deleted from Members by #getAuthUser()#.">
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<cffunction name="setMemberStatus" access="public" returntype="boolean" output="false" hint="Blocks (signed out everywhere at once) or unblocks a member.">
	<cfargument name="memberId" type="numeric" required="true">
	<cfargument name="status" type="string" required="true">
	<cfset var entity = "">
	<cfif not listFind("active,blocked", arguments.status)>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfset entity = entityLoadByPK("BlogMember", javacast("int", arguments.memberId))>
		<cfif isNull(entity) or entity.getBlogRef() neq application.BlogDbObj.getBlogId()>
			<cfreturn false>
		</cfif>
		<cfset entity.setStatus(arguments.status)>
		<cfset entitySave(entity)>
		<cfif arguments.status eq "blocked">
			<cfset ormExecuteQuery("DELETE FROM MemberRememberToken WHERE BlogRef = :blogId AND MemberRef = :memberId", { blogId = javacast("int", application.BlogDbObj.getBlogId()), memberId = javacast("int", arguments.memberId) })>
		</cfif>
	</cftransaction>
	<cfreturn true>
</cffunction>

<!--- ********************************************************************************************************************
	Private
********************************************************************************************************************* --->

<cffunction name="startSession" access="private" returntype="void" output="false">
	<cfargument name="entity" type="any" required="true">
	<!--- A new session id on sign-in would be ideal; ColdFusion's own session rotation isn't the same on ACF and Lucee, so the
	member key is replaced instead and a fresh CSRF token issued. --->
	<cfset session.galaxieMember = { memberId: arguments.entity.getMemberId(), signedIn: now() }>
	<cfset session.galaxieMemberCsrf = newToken()>
</cffunction>

<cffunction name="endSession" access="private" returntype="void" output="false">
	<cfset structDelete(session, "galaxieMember")>
	<cfset structDelete(session, "galaxieMemberCsrf")>
</cffunction>

<cffunction name="memberStruct" access="private" returntype="struct" output="false">
	<cfargument name="entity" type="any" required="true">
	<cfreturn {
		memberId: arguments.entity.getMemberId(),
		email: valueOrEmpty(arguments.entity.getEmail()),
		name: valueOrEmpty(arguments.entity.getName()),
		phone: valueOrEmpty(arguments.entity.getPhone()),
		timeZone: valueOrEmpty(arguments.entity.getTimeZone()),
		status: len(valueOrEmpty(arguments.entity.getStatus())) ? arguments.entity.getStatus() : "active",
		created: isNull(arguments.entity.getCreated()) ? "" : arguments.entity.getCreated(),
		lastSeen: isNull(arguments.entity.getLastSeen()) ? "" : arguments.entity.getLastSeen()
	}>
</cffunction>

<cffunction name="findMemberByEmail" access="private" returntype="any" output="false" hint="The member struct for an address, or an empty string.">
	<cfargument name="email" type="string" required="true">
	<cfset var found = ormExecuteQuery("FROM BlogMember WHERE BlogRef = :blogId AND Email = :email", { blogId = javacast("int", application.BlogDbObj.getBlogId()), email = lCase(trim(arguments.email)) })>
	<cfreturn arrayLen(found) ? memberStruct(found[1]) : "">
</cffunction>

<cffunction name="signInLink" access="private" returntype="string" output="false"
		hint="The emailed link: the page the visitor asked from (only on this blog) with ?memberSignIn=<token>.">
	<cfargument name="token" type="string" required="true">
	<cfargument name="returnUrl" type="string" required="true">
	<cfset var base = application.blogHostUrl & "/">
	<cfset var target = trim(arguments.returnUrl)>
	<!--- Only a page on this blog; anything else (or nothing) goes to the home page. --->
	<cfif not len(target) or left(target, len(application.blogHostUrl)) neq application.blogHostUrl or reFind("[\r\n<>""]", target)>
		<cfset target = base>
	</cfif>
	<!--- Drop an old sign-in or booking-return parameter, and anything after a ##. --->
	<cfset target = listFirst(target, "##")>
	<cfset target = reReplace(target, "([?&])(memberSignIn|bookingCheckout|bookingCancelled|manageBooking|payBalance)=[^&]*&?", "\1", "all")>
	<cfset target = reReplace(target, "[?&]$", "")>
	<cfreturn target & (find("?", target) ? "&" : "?") & "memberSignIn=" & arguments.token>
</cffunction>

<cffunction name="sendSignInEmail" access="private" returntype="void" output="false">
	<cfargument name="to" type="string" required="true">
	<cfargument name="link" type="string" required="true">
	<cfset var renderer = createObject("component", application.rendererComponentPath)>
	<cfset var utils = createObject("component", application.utilsComponentPath)>
	<cfset var blogTitle = application.BlogDbObj.getBlogTitle()>
	<cfset var emailBody = renderer.renderEmail(
		email = arguments.to,
		emailTitle = "Sign in to " & blogTitle,
		emailDesc = "Click the button to sign in. The link works once, for #variables.linkMinutes# minutes.",
		emailBody = "<p>If you didn't ask to sign in, you can ignore this email; nothing changes until the link is used.</p>",
		callToActionText = "Sign in",
		callToActionLink = arguments.link
	)>
	<cfset utils.mail(to = arguments.to, subject = "Your sign-in link for " & blogTitle, body = emailBody, cc = "")>
</cffunction>

<cffunction name="allowRequest" access="private" returntype="boolean" output="false" hint="False when an address or IP asked for too many sign-in emails in the last 15 minutes.">
	<cfargument name="email" type="string" required="true">
	<cfargument name="ipAddress" type="string" required="true">
	<cfset var cutoff = dateAdd("n", -15, now())>
	<cfset var key = "">
	<cfset var kept = []>
	<cfset var stamp = "">
	<cfset var allowed = true>
	<cflock name="galaxieMemberRateLimit_#application.BlogDbObj.getBlogId()#" type="exclusive" timeout="10">
		<cfif not structKeyExists(application, "memberSignInRateLimit") or not isStruct(application.memberSignInRateLimit)>
			<cfset application.memberSignInRateLimit = {}>
		</cfif>
		<!--- Forget old requests. --->
		<cfloop collection="#application.memberSignInRateLimit#" item="key">
			<cfset kept = []>
			<cfloop array="#application.memberSignInRateLimit[key]#" index="stamp">
				<cfif dateCompare(stamp, cutoff) gt 0><cfset arrayAppend(kept, stamp)></cfif>
			</cfloop>
			<cfif arrayLen(kept)><cfset application.memberSignInRateLimit[key] = kept><cfelse><cfset structDelete(application.memberSignInRateLimit, key)></cfif>
		</cfloop>
		<cfif structKeyExists(application.memberSignInRateLimit, "e:" & arguments.email) and arrayLen(application.memberSignInRateLimit["e:" & arguments.email]) gte variables.perEmailLimit>
			<cfset allowed = false>
		</cfif>
		<cfif len(arguments.ipAddress) and structKeyExists(application.memberSignInRateLimit, "i:" & arguments.ipAddress) and arrayLen(application.memberSignInRateLimit["i:" & arguments.ipAddress]) gte variables.perIpLimit>
			<cfset allowed = false>
		</cfif>
		<cfif allowed>
			<cfloop list="#'e:' & arguments.email#,#len(arguments.ipAddress) ? 'i:' & arguments.ipAddress : ''#" index="key">
				<cfif not structKeyExists(application.memberSignInRateLimit, key)><cfset application.memberSignInRateLimit[key] = []></cfif>
				<cfset arrayAppend(application.memberSignInRateLimit[key], now())>
			</cfloop>
		</cfif>
	</cflock>
	<cfreturn allowed>
</cffunction>

<cffunction name="removeOldLoginTokens" access="private" returntype="void" output="false" hint="Deletes sign-in links that expired more than a day ago. Called inside a transaction.">
	<cfset ormExecuteQuery("DELETE FROM MemberLoginToken WHERE BlogRef = :blogId AND Expires < :cutoff", { blogId = javacast("int", application.BlogDbObj.getBlogId()), cutoff = dateAdd("d", -1, now()) })>
</cffunction>

<!--- 'Keep me signed in' --->

<cffunction name="rememberCookieName" access="private" returntype="string" output="false">
	<cfreturn "galaxieMember" & application.BlogDbObj.getBlogId()>
</cffunction>

<cffunction name="setRememberCookie" access="private" returntype="void" output="false">
	<cfargument name="memberId" type="numeric" required="true">
	<cfargument name="userAgent" type="string" required="true">
	<cfset var token = newToken()>
	<cfset var days = cachedSettings().rememberDays>
	<cfset var entity = "">
	<cftransaction>
		<cfset ormExecuteQuery("DELETE FROM MemberRememberToken WHERE BlogRef = :blogId AND Expires < :now", { blogId = javacast("int", application.BlogDbObj.getBlogId()), now = now() })>
		<cfset entity = entityNew("MemberRememberToken")>
		<cfset entity.setBlogRef(javacast("int", application.BlogDbObj.getBlogId()))>
		<cfset entity.setMemberRef(javacast("int", arguments.memberId))>
		<cfset entity.setTokenHash(hashToken(token))>
		<cfset entity.setExpires(dateAdd("d", days, now()))>
		<cfset entity.setUserAgent(left(arguments.userAgent, 255))>
		<cfset entity.setCreated(now())>
		<cfset entity.setLastUsed(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset writeCookie(token, days)>
</cffunction>

<cffunction name="restoreFromCookie" access="private" returntype="void" output="false">
	<cfset var token = readRememberCookie()>
	<cfset var found = []>
	<cfset var member = "">
	<cfif not len(token)>
		<cfreturn>
	</cfif>
	<cftransaction>
		<cfset found = ormExecuteQuery("FROM MemberRememberToken WHERE BlogRef = :blogId AND TokenHash = :tokenHash", { blogId = javacast("int", application.BlogDbObj.getBlogId()), tokenHash = hashToken(token) })>
		<cfif not arrayLen(found) or dateCompare(found[1].getExpires(), now()) lt 0>
			<cftransaction action="rollback"/>
			<cfset clearRememberCookie()>
			<cfreturn>
		</cfif>
		<cfset found[1].setLastUsed(now())>
		<cfset entitySave(found[1])>
		<cfset member = entityLoadByPK("BlogMember", javacast("int", found[1].getMemberRef()))>
		<cfif isNull(member) or valueOrEmpty(member.getStatus()) eq "blocked">
			<cftransaction action="rollback"/>
			<cfset clearRememberCookie()>
			<cfreturn>
		</cfif>
		<cfset member.setLastSeen(now())>
		<cfset entitySave(member)>
	</cftransaction>
	<cfset startSession(member)>
</cffunction>

<cffunction name="readRememberCookie" access="private" returntype="string" output="false">
	<cfset var value = structKeyExists(cookie, rememberCookieName()) ? cookie[rememberCookieName()] : "">
	<cfreturn reFind("^[a-f0-9]{64}$", value) ? value : "">
</cffunction>

<cffunction name="writeCookie" access="private" returntype="void" output="false" hint="Written as a raw Set-Cookie header so HttpOnly, Secure and SameSite are the same on ACF and Lucee.">
	<cfargument name="value" type="string" required="true">
	<cfargument name="days" type="numeric" required="true">
	<cfset var path = len(application.baseUrl) ? application.baseUrl & "/" : "/">
	<cfset var expires = dateAdd("d", arguments.days, dateConvert("local2utc", now()))>
	<cfset var secure = left(application.blogHostUrl, 8) eq "https://" ? "; Secure" : "">
	<cfheader name="Set-Cookie" value="#rememberCookieName()#=#arguments.value#; Path=#path#; Expires=#dateFormat(expires, 'ddd, dd mmm yyyy')# #timeFormat(expires, 'HH:mm:ss')# GMT; Max-Age=#arguments.days * 86400#; HttpOnly; SameSite=Lax#secure#">
</cffunction>

<cffunction name="clearRememberCookie" access="private" returntype="void" output="false">
	<cfset var path = len(application.baseUrl) ? application.baseUrl & "/" : "/">
	<cfif structKeyExists(cookie, rememberCookieName())>
		<cfheader name="Set-Cookie" value="#rememberCookieName()#=; Path=#path#; Expires=Thu, 01 Jan 1970 00:00:00 GMT; Max-Age=0; HttpOnly; SameSite=Lax">
	</cfif>
</cffunction>

<!--- Helpers --->

<cffunction name="newToken" access="private" returntype="string" output="false" hint="64 hex characters (256 bits) from the platform's secure random generator.">
	<cfset var bytes = createObject("java", "java.security.SecureRandom").init()>
	<cfset var raw = javacast("byte[]", listToArray(repeatString("0,", 32)))>
	<cfset bytes.nextBytes(raw)>
	<cfreturn lCase(binaryEncode(raw, "hex"))>
</cffunction>

<cffunction name="hashToken" access="private" returntype="string" output="false">
	<cfargument name="token" type="string" required="true">
	<cfreturn lCase(hash(arguments.token, "SHA-256", "UTF-8"))>
</cffunction>

<cffunction name="isValidTimeZone" access="private" returntype="boolean" output="false">
	<cfargument name="zone" type="string" required="true">
	<cftry>
		<cfset createObject("java", "java.time.ZoneId").of(arguments.zone)>
		<cfreturn reFind("^[A-Za-z]+(/[A-Za-z0-9_+\-]+)+$", arguments.zone) gt 0 or arguments.zone eq "UTC">
		<cfcatch type="any"><cfreturn false></cfcatch>
	</cftry>
</cffunction>

<cffunction name="cachedSettings" access="private" returntype="struct" output="false" hint="getSettings(), kept until the next save - read on every page view by the members script.">
	<cfif not structKeyExists(variables.settingsCache, "enabled")>
		<!--- Every page asks whether member accounts are on, so this must never break a page: until the member tables exist
		(files uploaded before the database update has run, or before an ORM reload), member accounts are simply off. Not
		cached in that case, so they work as soon as the tables are there. --->
		<cftry>
			<cfset variables.settingsCache = getSettings()>
			<cfcatch type="any">
				<cfreturn { enabled: false, rememberDays: 30 }>
			</cfcatch>
		</cftry>
	</cfif>
	<cfreturn variables.settingsCache>
</cffunction>

<cffunction name="loadSettingsEntity" access="private" returntype="any" output="false" hint="This blog's MemberSetting row, or null.">
	<cfset var found = ormExecuteQuery("FROM MemberSetting WHERE BlogRef = :blogId ORDER BY MemberSettingId", { blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif arrayLen(found)>
		<cfreturn found[1]>
	</cfif>
</cffunction>

<cffunction name="valueOrEmpty" access="private" returntype="string" output="false"
		hint="A property value, or an empty string when it is NULL (rows from before a column existed).">
	<cfargument name="value" required="false">
	<cfif isNull(arguments.value)>
		<cfreturn "">
	</cfif>
	<cfreturn arguments.value>
</cffunction>

<cffunction name="isTrue" access="private" returntype="boolean" output="false" hint="A boolean property, with a default for NULL.">
	<cfargument name="value" required="false">
	<cfargument name="defaultValue" type="boolean" required="false" default="false">
	<cfif isNull(arguments.value) or not isBoolean(arguments.value)>
		<cfreturn arguments.defaultValue>
	</cfif>
	<cfreturn arguments.value>
</cffunction>

</cfcomponent>
