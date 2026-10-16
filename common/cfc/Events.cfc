<cfcomponent displayName="Events" output="false" hint="Events (2026-10-15): a blog post with event details - when, where, cost, status - its event card, calendar links and RSVP (sign-ups through a form, counted in people, with cancel links). Created once as application.events in Application.cfc. Entity: BlogEvent (common/cfc/db/galaxieDb); where it happens is the shared LocationOptions (Locations.cfc) through LocationOptionLookup.PostRef. See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 2.">

<!---
	Every write is inside a cftransaction: the application sets ormsettings.flushAtRequestEnd = false, so an entity change
	made outside a transaction (without ormFlush) would never reach the database.

	Times: the owner enters the event's wall-clock time in the event's time zone (an IANA name such as America/Los_Angeles).
	Those are stored as entered ('yyyy-mm-dd HH:mm'), and the UTC instants are worked out with java.time, so daylight saving
	time is always right (see the fixed-GMT-offset article).
--->

<cffunction name="init" access="public" returntype="any" output="false">
	<cfset variables.statuses = "scheduled,postponed,cancelled">
	<cfreturn this>
</cffunction>

<!--- ********************************************************************************************************************
	Reading
********************************************************************************************************************* --->

<cffunction name="getEvent" access="public" returntype="struct" output="false"
		hint="The event on a post, or an empty struct: { eventId, postId, startLocal, endLocal, timeZone, startUtc, endUtc, allDay, status, organizerName, organizerUrl, cost, ticketUrl, locationIds, locations, webFormId, capacity, askPartySize, maxPartySize, rsvpClosesLocal, price (per person, 0 = free), refundHours }.">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var found = ormExecuteQuery("FROM BlogEvent WHERE BlogRef = :blogId AND PostRef = :postId", { blogId = javacast("int", application.BlogDbObj.getBlogId()), postId = javacast("int", arguments.postId) })>
	<cfset var e = "">
	<cfset var ev = {}>
	<cfset var id = "">
	<cfset var place = {}>
	<cfif not arrayLen(found)>
		<cfreturn {}>
	</cfif>
	<cfset e = found[1]>
	<cfset ev = {
		eventId: e.getEventId(),
		postId: arguments.postId,
		startLocal: valueOrEmpty(e.getStartLocal()),
		endLocal: valueOrEmpty(e.getEndLocal()),
		timeZone: valueOrEmpty(e.getTimeZone()),
		startUtc: valueOrEmpty(e.getStartUtc()),
		endUtc: valueOrEmpty(e.getEndUtc()),
		allDay: isTrue(e.getAllDay(), false),
		status: listFind(variables.statuses, valueOrEmpty(e.getStatus())) ? e.getStatus() : "scheduled",
		organizerName: valueOrEmpty(e.getOrganizerName()),
		organizerUrl: valueOrEmpty(e.getOrganizerUrl()),
		cost: valueOrEmpty(e.getCost()),
		ticketUrl: valueOrEmpty(e.getTicketUrl()),
		webFormId: val(valueOrEmpty(e.getWebFormRef())),
		capacity: val(valueOrEmpty(e.getCapacity())),
		askPartySize: isTrue(e.getAskPartySize(), false),
		maxPartySize: max(val(valueOrEmpty(e.getMaxPartySize())), 1),
		rsvpClosesLocal: valueOrEmpty(e.getRsvpClosesLocal()),
		price: val(valueOrEmpty(e.getPrice())),
		refundHours: len(valueOrEmpty(e.getRefundHours())) ? val(e.getRefundHours()) : 24,
		locationIds: getLocationIds(arguments.postId),
		locations: []
	}>
	<cfloop array="#ev.locationIds#" index="id">
		<cfset place = application.locations.getLocation(id)>
		<cfif not structIsEmpty(place)><cfset arrayAppend(ev.locations, place)></cfif>
	</cfloop>
	<cfreturn ev>
</cffunction>

<cffunction name="getEventsForAdmin" access="public" returntype="array" output="false"
		hint="Every event on this blog for the Events window (101): upcoming first (soonest first), then past ones (latest first). [{ postId, title, whenText, status, isPast, hasRsvp, people, capacity, signups }]">
	<cfset var rows = queryExecute("
		SELECT e.PostRef, e.StartUtc, e.EndUtc, e.Status, e.WebFormRef, e.Capacity, p.Title,
			(SELECT SUM(s.PartySize) FROM WebFormSubmission s WHERE s.EventRef = e.EventId AND s.Status = 'confirmed') AS People,
			(SELECT COUNT(*) FROM WebFormSubmission s WHERE s.EventRef = e.EventId AND s.Status = 'confirmed') AS Signups
		FROM BlogEvent e INNER JOIN Post p ON p.PostId = e.PostRef
		WHERE e.BlogRef = :blogId
		ORDER BY e.StartUtc",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfset var upcoming = []>
	<cfset var past = []>
	<cfset var nowUtc = createObject("java", "java.time.Instant").now()>
	<cfset var item = {}>
	<cfset var ev = {}>
	<cfloop query="rows">
		<cfset ev = getEvent(rows.PostRef)>
		<cfif structIsEmpty(ev)><cfcontinue></cfif>
		<cfset item = {
			postId: rows.PostRef,
			title: rows.Title,
			whenText: whenText(ev),
			status: ev.status,
			isPast: not nowUtc.isBefore(createObject("java", "java.time.Instant").parse(ev.endUtc)),
			hasRsvp: ev.webFormId gt 0,
			people: val(rows.People),
			capacity: val(rows.Capacity),
			signups: val(rows.Signups)
		}>
		<cfif item.isPast><cfset arrayPrepend(past, item)><cfelse><cfset arrayAppend(upcoming, item)></cfif>
	</cfloop>
	<cfloop array="#past#" index="item"><cfset arrayAppend(upcoming, item)></cfloop>
	<cfreturn upcoming>
</cffunction>

<cffunction name="getLocationIds" access="public" returntype="array" output="false" hint="The LocationOption ids an event offers, in order.">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var rows = queryExecute("SELECT LocationOptionRef FROM LocationOptionLookup WHERE PostRef = :postId AND BookingTypeRef = 0 ORDER BY SortOrder, LocationOptionLookupId",
		{ postId = { value = arguments.postId, cfsqltype = "cf_sql_integer" } })>
	<cfset var ids = []>
	<cfloop query="rows"><cfset arrayAppend(ids, rows.LocationOptionRef)></cfloop>
	<cfreturn ids>
</cffunction>

<cffunction name="getStatuses" access="public" returntype="array" output="false">
	<cfreturn [ { value: "scheduled", label: "Scheduled" }, { value: "postponed", label: "Postponed" }, { value: "cancelled", label: "Cancelled" } ]>
</cffunction>

<!--- ********************************************************************************************************************
	Saving
********************************************************************************************************************* --->

<cffunction name="saveEvent" access="public" returntype="struct" output="false"
		hint="Adds or updates the event on a post. Returns { success, errors[] }; nothing is saved when something is wrong.">
	<cfargument name="postId" type="numeric" required="true">
	<cfargument name="data" type="struct" required="true" hint="startDate, startTime, endDate, endTime (yyyy-mm-dd / HH:mm), allDay, timeZone, locationIds (list), status, organizerName, organizerUrl, cost, ticketUrl; RSVP: webFormId (0 = none), capacity (0 = no limit), askPartySize, maxPartySize, rsvpClosesDate and rsvpClosesTime (empty = when the event starts); price (per person, 0 = free) and refundHours.">
	<cfset var d = normalize(arguments.data)>
	<cfset var result = { success: false, errors: [] }>
	<cfset var startLocal = "">
	<cfset var endLocal = "">
	<cfset var startUtc = "">
	<cfset var endUtc = "">
	<cfset var found = []>
	<cfset var entity = "">
	<cfset var id = "">
	<cfset var order = 0>
	<cfset var lookup = "">
	<cfset var rsvpClosesLocal = "">
	<cfset var rsvpForm = {}>
	<cfset var rsvpField = "">
	<cfset var hasEmail = false>
	<cfset var post = entityLoadByPK("Post", javacast("int", arguments.postId))>

	<cfif isNull(post)>
		<cfset arrayAppend(result.errors, "The post wasn't found. Save the post first.")>
		<cfreturn result>
	</cfif>
	<!--- When --->
	<cfif not isLocalDate(d.startDate)><cfset arrayAppend(result.errors, "Choose the day the event starts.")></cfif>
	<cfif not len(d.endDate)><cfset d.endDate = d.startDate></cfif>
	<cfif not isLocalDate(d.endDate)><cfset arrayAppend(result.errors, "Choose the day the event ends.")></cfif>
	<cfif not d.allDay>
		<cfif not isTime24(d.startTime)><cfset arrayAppend(result.errors, "Choose the time the event starts.")></cfif>
		<cfif not isTime24(d.endTime)><cfset arrayAppend(result.errors, "Choose the time the event ends.")></cfif>
	</cfif>
	<cfif not isValidTimeZone(d.timeZone)><cfset arrayAppend(result.errors, "Choose the event's time zone from the list.")></cfif>
	<cfif not arrayLen(result.errors)>
		<cfset startLocal = d.startDate & " " & (d.allDay ? "00:00" : d.startTime)>
		<cfset endLocal = d.endDate & " " & (d.allDay ? "23:59" : d.endTime)>
		<cfif endLocal lte startLocal>
			<cfset arrayAppend(result.errors, "The event has to end after it starts.")>
		<cfelse>
			<cfset startUtc = localToUtc(startLocal, d.timeZone)>
			<cfset endUtc = localToUtc(endLocal, d.timeZone)>
		</cfif>
	</cfif>
	<!--- The rest --->
	<cfif not listFind(variables.statuses, d.status)><cfset arrayAppend(result.errors, "Choose the event's status.")></cfif>
	<cfif len(d.organizerName) gt 125><cfset arrayAppend(result.errors, "The organizer's name is too long.")></cfif>
	<cfif len(d.organizerUrl) and not isWebAddress(d.organizerUrl)><cfset arrayAppend(result.errors, "The organizer's link has to start with http:// or https://.")></cfif>
	<cfif len(d.cost) gt 125><cfset arrayAppend(result.errors, "The cost is too long; keep it short, eg. $20 or Free.")></cfif>
	<cfif len(d.ticketUrl) and not isWebAddress(d.ticketUrl)><cfset arrayAppend(result.errors, "The tickets link has to start with http:// or https://.")></cfif>
	<cfloop list="#d.locationIds#" index="id">
		<cfif not isValid("integer", id) or structIsEmpty(application.locations.getLocation(id))>
			<cfset arrayAppend(result.errors, "One of the locations no longer exists. Please choose again.")>
			<cfbreak>
		</cfif>
	</cfloop>
	<!--- RSVP --->
	<cfif d.webFormId gt 0>
		<cfset rsvpForm = application.webForms.getForm(webFormId = d.webFormId)>
		<cfif structIsEmpty(rsvpForm)>
			<cfset arrayAppend(result.errors, "The RSVP form no longer exists. Please choose again.")>
		<cfelse>
			<!--- The confirmation, the cancel link and the duplicate check all need the person's email address. --->
			<cfloop array="#rsvpForm.fields#" index="rsvpField">
				<cfif rsvpField.fieldType eq "email"><cfset hasEmail = true></cfif>
			</cfloop>
			<cfif not hasEmail>
				<cfset arrayAppend(result.errors, "The RSVP form needs an Email field, for the confirmation and the cancel link. Add one in Forms, or choose another form.")>
			</cfif>
		</cfif>
	</cfif>
	<cfif not isValid("integer", d.capacity) or d.capacity lt 0 or d.capacity gt 1000000><cfset arrayAppend(result.errors, "Capacity has to be a whole number of people (or empty for no limit).")></cfif>
	<cfif not isValid("integer", d.maxPartySize) or d.maxPartySize lt 1 or d.maxPartySize gt 50><cfset arrayAppend(result.errors, "The most people per sign-up has to be between 1 and 50.")></cfif>
	<!--- Paid sign-ups: a price per person, paid through Stripe when signing up. --->
	<cfif not reFind("^\d{1,7}(\.\d{1,2})?$", d.price)>
		<cfset arrayAppend(result.errors, "The price has to be an amount such as 20 or 12.50 (or empty for free).")>
	<cfelseif d.price gt 0>
		<cfif d.webFormId lte 0>
			<cfset arrayAppend(result.errors, "A price needs a sign-up form: people pay when they sign up.")>
		<cfelseif not application.payments.getStatus().ready>
			<cfset arrayAppend(result.errors, "To charge for sign-ups, set up Payments in Blog Options first.")>
		</cfif>
	</cfif>
	<cfif not isValid("integer", d.refundHours) or d.refundHours lt 0 or d.refundHours gt 8760><cfset arrayAppend(result.errors, "Refunds has to be a whole number of hours (0 for no refunds).")></cfif>
	<cfif len(d.rsvpClosesDate)>
		<cfif not isLocalDate(d.rsvpClosesDate) or not isTime24(d.rsvpClosesTime)>
			<cfset arrayAppend(result.errors, "Choose the day and time sign-ups close, or leave both empty.")>
		<cfelse>
			<cfset rsvpClosesLocal = d.rsvpClosesDate & " " & d.rsvpClosesTime>
			<cfif len(endLocal) and rsvpClosesLocal gt endLocal>
				<cfset arrayAppend(result.errors, "Sign-ups have to close before the event ends.")>
			</cfif>
		</cfif>
	</cfif>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>

	<cftransaction>
		<cfset found = ormExecuteQuery("FROM BlogEvent WHERE BlogRef = :blogId AND PostRef = :postId", { blogId = javacast("int", application.BlogDbObj.getBlogId()), postId = javacast("int", arguments.postId) })>
		<cfif arrayLen(found)>
			<cfset entity = found[1]>
		<cfelse>
			<cfset entity = entityNew("BlogEvent")>
			<cfset entity.setBlogRef(javacast("int", application.BlogDbObj.getBlogId()))>
			<cfset entity.setPostRef(javacast("int", arguments.postId))>
			<cfset entity.setCreated(now())>
			<cfset entity.setWebFormRef(javacast("int", 0))>
			<cfset entity.setCapacity(javacast("int", 0))>
			<cfset entity.setAskPartySize(false)>
			<cfset entity.setMaxPartySize(javacast("int", 1))>
			<cfset entity.setRsvpClosesLocal("")>
		</cfif>
		<cfset entity.setStartLocal(startLocal)>
		<cfset entity.setEndLocal(endLocal)>
		<cfset entity.setTimeZone(d.timeZone)>
		<cfset entity.setStartUtc(startUtc)>
		<cfset entity.setEndUtc(endUtc)>
		<cfset entity.setAllDay(d.allDay)>
		<cfset entity.setStatus(d.status)>
		<cfset entity.setOrganizerName(d.organizerName)>
		<cfset entity.setOrganizerUrl(d.organizerUrl)>
		<cfset entity.setCost(d.cost)>
		<cfset entity.setTicketUrl(d.ticketUrl)>
		<cfset entity.setWebFormRef(javacast("int", d.webFormId))>
		<cfset entity.setCapacity(javacast("int", d.capacity))>
		<cfset entity.setAskPartySize(d.askPartySize)>
		<cfset entity.setMaxPartySize(javacast("int", d.maxPartySize))>
		<cfset entity.setRsvpClosesLocal(rsvpClosesLocal)>
		<cfset entity.setPrice(javacast("bigdecimal", val(d.price)))>
		<cfset entity.setRefundHours(javacast("int", d.refundHours))>
		<cfset entity.setUpdated(now())>
		<cfset entitySave(entity)>
		<!--- Where: replace the event's locations, in the order given. --->
		<cfset queryExecute("DELETE FROM LocationOptionLookup WHERE PostRef = :postId AND BookingTypeRef = 0", { postId = { value = arguments.postId, cfsqltype = "cf_sql_integer" } })>
		<cfloop list="#d.locationIds#" index="id">
			<cfset order++>
			<cfset lookup = entityNew("LocationOptionLookup")>
			<cfset lookup.setLocationOptionRef(javacast("int", id))>
			<cfset lookup.setBookingTypeRef(javacast("int", 0))>
			<cfset lookup.setPostRef(javacast("int", arguments.postId))>
			<cfset lookup.setSortOrder(javacast("int", order))>
			<cfset lookup.setDate(now())>
			<cfset entitySave(lookup)>
		</cfloop>
	</cftransaction>
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<cffunction name="deleteEvent" access="public" returntype="boolean" output="false" hint="Takes the event off a post (the post itself stays).">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var params = { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, postId = { value = arguments.postId, cfsqltype = "cf_sql_integer" } }>
	<cftransaction>
		<cfset queryExecute("DELETE FROM LocationOptionLookup WHERE PostRef = :postId AND BookingTypeRef = 0", params)>
		<cfset queryExecute("DELETE FROM BlogEvent WHERE BlogRef = :blogId AND PostRef = :postId", params)>
	</cftransaction>
	<cfreturn true>
</cffunction>

<cffunction name="isLocationUsed" access="public" returntype="boolean" output="false" hint="Whether any event offers a location (it can't be deleted while one does).">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cfreturn queryExecute("SELECT COUNT(*) AS n FROM LocationOptionLookup WHERE LocationOptionRef = :id AND PostRef > 0 AND BookingTypeRef = 0",
		{ id = { value = arguments.locationOptionId, cfsqltype = "cf_sql_integer" } }).n gt 0>
</cffunction>

<!--- ********************************************************************************************************************
	Private
********************************************************************************************************************* --->

<cffunction name="normalize" access="private" returntype="struct" output="false">
	<cfargument name="data" type="struct" required="true">
	<cfset var d = {}>
	<cfset var field = "">
	<cfset var ids = "">
	<cfset var id = "">
	<cfloop list="startDate,startTime,endDate,endTime,timeZone,status,organizerName,organizerUrl,cost,ticketUrl,locationIds,rsvpClosesDate,rsvpClosesTime" index="field">
		<cfset d[field] = structKeyExists(arguments.data, field) ? trim(arguments.data[field]) : "">
	</cfloop>
	<cfset d.allDay = structKeyExists(arguments.data, "allDay") and isBoolean(arguments.data.allDay) and arguments.data.allDay>
	<cfif not len(d.status)><cfset d.status = "scheduled"></cfif>
	<cfset d.webFormId = structKeyExists(arguments.data, "webFormId") and isValid("integer", arguments.data.webFormId) ? int(arguments.data.webFormId) : 0>
	<cfset d.capacity = structKeyExists(arguments.data, "capacity") and len(trim(arguments.data.capacity)) ? trim(arguments.data.capacity) : 0>
	<cfset d.askPartySize = structKeyExists(arguments.data, "askPartySize") and isBoolean(arguments.data.askPartySize) and arguments.data.askPartySize>
	<cfset d.maxPartySize = structKeyExists(arguments.data, "maxPartySize") and len(trim(arguments.data.maxPartySize)) ? trim(arguments.data.maxPartySize) : 1>
	<cfif not d.askPartySize><cfset d.maxPartySize = 1></cfif>
	<cfset d.price = structKeyExists(arguments.data, "price") and len(trim(arguments.data.price)) ? reReplace(trim(arguments.data.price), "[^0-9.]", "", "all") : "0">
	<cfif not len(d.price)><cfset d.price = "0"></cfif>
	<cfset d.refundHours = structKeyExists(arguments.data, "refundHours") and len(trim(arguments.data.refundHours)) ? trim(arguments.data.refundHours) : 24>
	<!--- Each location once, in the order given. --->
	<cfloop list="#d.locationIds#" index="id">
		<cfif not listFind(ids, trim(id))><cfset ids = listAppend(ids, trim(id))></cfif>
	</cfloop>
	<cfset d.locationIds = ids>
	<cfreturn d>
</cffunction>

<cffunction name="localToUtc" access="public" returntype="string" output="false" hint="'yyyy-mm-dd HH:mm' in a time zone as an ISO 8601 UTC instant, eg. 2026-11-05T02:00:00Z.">
	<cfargument name="localText" type="string" required="true">
	<cfargument name="zoneId" type="string" required="true">
	<cfset var formatter = createObject("java", "java.time.format.DateTimeFormatter").ofPattern("yyyy-MM-dd HH:mm")>
	<cfset var wallClock = createObject("java", "java.time.LocalDateTime").parse(arguments.localText, formatter)>
	<cfreturn wallClock.atZone(createObject("java", "java.time.ZoneId").of(arguments.zoneId)).toInstant().toString()>
</cffunction>

<cffunction name="isLocalDate" access="private" returntype="boolean" output="false">
	<cfargument name="text" type="string" required="true">
	<cfif not reFind("^\d{4}-\d{2}-\d{2}$", arguments.text)><cfreturn false></cfif>
	<cftry>
		<cfset createObject("java", "java.time.LocalDate").parse(arguments.text)>
		<cfreturn true>
		<cfcatch type="any"><cfreturn false></cfcatch>
	</cftry>
</cffunction>

<cffunction name="isTime24" access="private" returntype="boolean" output="false">
	<cfargument name="text" type="string" required="true">
	<cfreturn reFind("^([01]\d|2[0-3]):[0-5]\d$", arguments.text) gt 0>
</cffunction>

<cffunction name="isValidTimeZone" access="private" returntype="boolean" output="false">
	<cfargument name="zone" type="string" required="true">
	<cfif not len(arguments.zone) or not (reFind("^[A-Za-z]+(/[A-Za-z0-9_+\-]+)+$", arguments.zone) or arguments.zone eq "UTC")>
		<cfreturn false>
	</cfif>
	<cftry>
		<cfset createObject("java", "java.time.ZoneId").of(arguments.zone)>
		<cfreturn true>
		<cfcatch type="any"><cfreturn false></cfcatch>
	</cftry>
</cffunction>

<cffunction name="isWebAddress" access="private" returntype="boolean" output="false">
	<cfargument name="text" type="string" required="true">
	<cfreturn len(arguments.text) lte 500 and reFindNoCase("^https?://[^\s<>""']+$", arguments.text) gt 0>
</cffunction>

<cffunction name="valueOrEmpty" access="private" returntype="string" output="false">
	<cfargument name="value" required="false">
	<cfif isNull(arguments.value)><cfreturn ""></cfif>
	<cfreturn arguments.value>
</cffunction>

<cffunction name="isTrue" access="private" returntype="boolean" output="false">
	<cfargument name="value" required="false">
	<cfargument name="defaultValue" type="boolean" required="false" default="false">
	<cfif isNull(arguments.value) or not isBoolean(arguments.value)><cfreturn arguments.defaultValue></cfif>
	<cfreturn arguments.value>
</cffunction>

<!--- ********************************************************************************************************************
	RSVP (2026-10-15): a form attached to the event. Capacity counts people (a sign-up for 3 takes 3 places); empty capacity
	means no limit. Each sign-up is a WebFormSubmission with EventRef, PartySize and LocationOptionRef, saved as confirmed with
	a ManageToken for its cancel link. ProxyController's submitWebForm checks and saves inside the form's lock, so two people
	can't both take the last place. Cancelled sign-ups stay (shown as cancelled) and free their places. No waitlist.
********************************************************************************************************************* --->

<cffunction name="getRsvpState" access="public" returntype="struct" output="false"
		hint="Whether sign-ups are open right now: { open, message (why not, for the visitor), capacity (0 = no limit), taken (people), placesLeft (-1 = no limit), maxParty (the most one sign-up may bring) }.">
	<cfargument name="ev" type="struct" required="true">
	<cfset var state = { open: false, message: "", capacity: arguments.ev.capacity, taken: 0, placesLeft: -1, maxParty: 1, paid: false, priceText: "" }>
	<cfif arguments.ev.webFormId lte 0>
		<cfreturn state>
	</cfif>
	<!--- Paid (2026-10-15): only while Stripe is set up; otherwise sign-ups pause rather than go through unpaid. --->
	<cfif arguments.ev.price gt 0>
		<cfset state.paid = true>
		<cfset state.priceText = application.payments.formatMoney(arguments.ev.price) & " per person, paid online when you sign up." & (arguments.ev.refundHours gt 0 ? " Cancel at least " & refundWindowText(arguments.ev.refundHours) & " before the start for a full refund." : "")>
	</cfif>
	<cfset state.taken = getPlacesTaken(arguments.ev.eventId)>
	<cfif arguments.ev.capacity gt 0>
		<cfset state.placesLeft = max(arguments.ev.capacity - state.taken, 0)>
	</cfif>
	<cfif arguments.ev.status eq "cancelled">
		<cfset state.message = "This event is cancelled.">
	<cfelseif arguments.ev.status eq "postponed">
		<cfset state.message = "Sign-ups are paused while the event is postponed.">
	<cfelseif not createObject("java", "java.time.Instant").now().isBefore(createObject("java", "java.time.Instant").parse(getRsvpCloseUtc(arguments.ev)))>
		<cfset state.message = "Sign-ups are closed.">
	<cfelseif state.placesLeft eq 0>
		<cfset state.message = "This event is full.">
	<cfelseif state.paid and not application.payments.getStatus().ready>
		<cfset state.message = "Sign-ups are paused for the moment. Please check back soon.">
	<cfelse>
		<cfset state.open = true>
		<cfset state.maxParty = arguments.ev.askPartySize ? arguments.ev.maxPartySize : 1>
		<cfif state.placesLeft gt 0>
			<cfset state.maxParty = min(state.maxParty, state.placesLeft)>
		</cfif>
	</cfif>
	<cfreturn state>
</cffunction>

<cffunction name="getRsvpCloseUtc" access="public" returntype="string" output="false" hint="When sign-ups close: the owner's closing time, or when the event starts.">
	<cfargument name="ev" type="struct" required="true">
	<cfif len(arguments.ev.rsvpClosesLocal)>
		<cftry>
			<cfreturn localToUtc(arguments.ev.rsvpClosesLocal, arguments.ev.timeZone)>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfif>
	<cfreturn arguments.ev.startUtc>
</cffunction>

<cffunction name="getPlacesTaken" access="public" returntype="numeric" output="false" hint="The people counted by an event's confirmed sign-ups.">
	<cfargument name="eventId" type="numeric" required="true">
	<!--- Places held while someone is on the payment page count too, until the hold runs out. --->
	<cfset var rows = queryExecute("SELECT SUM(PartySize) AS People FROM WebFormSubmission WHERE EventRef = :id AND (Status = 'confirmed' OR (Status = 'held' AND HoldExpiresAt > :now))",
		{ id = { value = arguments.eventId, cfsqltype = "cf_sql_integer" }, now = { value = now(), cfsqltype = "cf_sql_timestamp" } })>
	<cfreturn val(rows.People)>
</cffunction>

<cffunction name="isSignedUp" access="public" returntype="boolean" output="false" hint="Whether this email already has a place at the event (confirmed, or held while paying).">
	<cfargument name="eventId" type="numeric" required="true">
	<cfargument name="email" type="string" required="true">
	<cfreturn queryExecute("SELECT COUNT(*) AS n FROM WebFormSubmission WHERE EventRef = :id AND LOWER(Email) = :email AND (Status = 'confirmed' OR (Status = 'held' AND HoldExpiresAt > :now))",
		{ id = { value = arguments.eventId, cfsqltype = "cf_sql_integer" }, email = { value = lCase(trim(arguments.email)), cfsqltype = "cf_sql_varchar" }, now = { value = now(), cfsqltype = "cf_sql_timestamp" } }).n gt 0>
</cffunction>

<cffunction name="checkRsvp" access="public" returntype="struct" output="false"
		hint="Checks the event part of a sign-up (call inside the form's lock, right before saving): open, the party size, the way to attend, duplicates and the places left. Returns { valid, errors: { field: message }, message, partySize, locationOptionId }.">
	<cfargument name="ev" type="struct" required="true">
	<cfargument name="email" type="string" required="true">
	<cfargument name="partySize" required="false" default="1">
	<cfargument name="locationOptionId" required="false" default="0">
	<cfset var state = getRsvpState(arguments.ev)>
	<cfset var result = { valid: false, errors: {}, message: "", partySize: 1, locationOptionId: 0 }>
	<cfif not state.open>
		<cfset result.message = state.message>
		<cfreturn result>
	</cfif>
	<!--- How many --->
	<cfif arguments.ev.askPartySize>
		<cfif not isValid("integer", arguments.partySize) or arguments.partySize lt 1 or arguments.partySize gt arguments.ev.maxPartySize>
			<cfset result.errors[ "rsvpPartySize" ] = "Please choose how many people are coming.">
		<cfelse>
			<cfset result.partySize = int(arguments.partySize)>
		</cfif>
	</cfif>
	<!--- Which way they'll attend: asked only when the event offers more than one. --->
	<cfif arrayLen(arguments.ev.locationIds) eq 1>
		<cfset result.locationOptionId = arguments.ev.locationIds[1]>
	<cfelseif arrayLen(arguments.ev.locationIds) gt 1>
		<cfif isValid("integer", arguments.locationOptionId) and arrayFind(arguments.ev.locationIds, int(arguments.locationOptionId))>
			<cfset result.locationOptionId = int(arguments.locationOptionId)>
		<cfelse>
			<cfset result.errors[ "rsvpLocation" ] = "Please choose how you'll attend.">
		</cfif>
	</cfif>
	<cfif not structIsEmpty(result.errors)>
		<cfreturn result>
	</cfif>
	<cfif isSignedUp(arguments.ev.eventId, arguments.email)>
		<cfset result.message = "You're already signed up - use the link in your confirmation email to cancel." & (arguments.ev.price gt 0 ? " If you just left the payment page, please wait a few minutes and try again." : "")>
		<cfreturn result>
	</cfif>
	<cfif state.placesLeft gte 0 and result.partySize gt state.placesLeft>
		<cfset result.message = state.placesLeft eq 1 ? "Sorry, only 1 place is left." : "Sorry, only #state.placesLeft# places are left.">
		<cfreturn result>
	</cfif>
	<cfset result.valid = true>
	<cfreturn result>
</cffunction>

<cffunction name="renderRsvpExtrasHtml" access="public" returntype="string" output="false"
		hint="The event's own questions, shown after the RSVP form's fields: how many people (when asked) and how they'll attend (when there's more than one way). Marked up like the form's fields; webForms.js sends them as rsvpPartySize and rsvpLocation.">
	<cfargument name="ev" type="struct" required="true">
	<cfargument name="state" type="struct" required="true">
	<cfargument name="idPrefix" type="string" required="true">
	<cfset var html = "">
	<cfset var n = 0>
	<cfset var place = "">
	<cfset var errorDiv = "">
	<cfif arguments.ev.askPartySize and arguments.state.maxParty gt 1>
		<cfset errorDiv = '<div class="galaxieWebFormError k-widget k-tooltip k-tooltip-validation k-invalid-msg" id="' & arguments.idPrefix & 'rsvpPartySize_error" role="alert" hidden="hidden"></div>'>
		<cfset html = html & '<div class="galaxieWebFormField" data-field="rsvpPartySize"><label for="' & arguments.idPrefix & 'rsvpPartySize">How many people are coming, including you? *</label><select id="' & arguments.idPrefix & 'rsvpPartySize" name="rsvpPartySize" style="width: 120px;" aria-describedby="' & arguments.idPrefix & 'rsvpPartySize_error">'>
		<cfloop from="1" to="#arguments.state.maxParty#" index="n">
			<cfset html = html & '<option value="' & n & '">' & n & '</option>'>
		</cfloop>
		<cfset html = html & '</select>' & errorDiv & '</div>'>
	</cfif>
	<cfif arrayLen(arguments.ev.locations) gt 1>
		<cfset html = html & '<div class="galaxieWebFormField" data-field="rsvpLocation" role="radiogroup" aria-labelledby="' & arguments.idPrefix & 'rsvpLocation_label"><div class="galaxieWebFormLabel" id="' & arguments.idPrefix & 'rsvpLocation_label">How will you attend? *</div>'>
		<cfloop array="#arguments.ev.locations#" index="place">
			<cfset html = html & '<div class="galaxieWebFormChoice"><input type="radio" class="k-radio" name="rsvpLocation" id="' & arguments.idPrefix & 'rsvpLocation' & place.locationOptionId & '" value="' & place.locationOptionId & '"> <label class="k-radio-label" for="' & arguments.idPrefix & 'rsvpLocation' & place.locationOptionId & '">' & encodeForHtml(place.label) & '</label></div>'>
		</cfloop>
		<cfset html = html & '<div class="galaxieWebFormError k-widget k-tooltip k-tooltip-validation k-invalid-msg" id="' & arguments.idPrefix & 'rsvpLocation_error" role="alert" hidden="hidden"></div></div>'>
	</cfif>
	<cfreturn html>
</cffunction>

<cffunction name="placesText" access="public" returntype="string" output="false" hint="eg. '12 of 40 places left', or '' with no limit.">
	<cfargument name="state" type="struct" required="true">
	<cfif arguments.state.placesLeft lt 0>
		<cfreturn "">
	</cfif>
	<cfreturn arguments.state.placesLeft & " of " & arguments.state.capacity & (arguments.state.capacity eq 1 ? " place" : " places") & " left">
</cffunction>

<cffunction name="getPostInfo" access="public" returntype="struct" output="false" hint="{ title, url } of the event's post (pending and removed posts too).">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var post = application.blog.getPostByPostId(postId = arguments.postId, showPendingPosts = true, showRemovedPosts = true)>
	<cfif not isArray(post) or not arrayLen(post)>
		<cfreturn { title: "", url: application.blogHostUrl }>
	</cfif>
	<cfreturn { title: post[1]["Title"], url: application.blog.makeLink(isPage = post[1]["IsPage"], postAlias = post[1]["PostAlias"], datePosted = post[1]["DatePosted"]) }>
</cffunction>

<cffunction name="getRsvp" access="public" returntype="struct" output="false"
		hint="One sign-up with its event, by id or by the token in its cancel link; empty when not found. { submissionId, eventId, postId, name, email, partySize, location (struct or empty), status (confirmed, cancelled, held while paying, expired), created, cancelledAt, manageToken, manageUrl, canCancel, paymentStatus, amountTotal, amountPaid, refundOnCancel, ev, title, postUrl, values }.">
	<cfargument name="submissionId" required="false" default="0">
	<cfargument name="token" type="string" required="false" default="">
	<cfset var rows = "">
	<cfset var sql = "SELECT s.WebFormSubmissionId, s.EventRef, s.Name, s.Email, s.PartySize, s.LocationOptionRef, s.Status, s.Created, s.CancelledAt, s.ManageToken, s.ValuesJson, s.PaymentStatus, s.AmountTotal, s.AmountPaid, s.HoldExpiresAt, e.PostRef
		FROM WebFormSubmission s INNER JOIN BlogEvent e ON e.EventId = s.EventRef
		WHERE e.BlogRef = :blogId AND s.EventRef > 0 AND ">
	<cfset var params = { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } }>
	<cfset var r = {}>
	<cfset var info = {}>
	<cfif reFind("^[a-f0-9]{64}$", arguments.token)>
		<cfset params.token = { value = arguments.token, cfsqltype = "cf_sql_varchar" }>
		<cfset rows = queryExecute(sql & "s.ManageToken = :token", params)>
	<cfelseif isValid("integer", arguments.submissionId) and arguments.submissionId gt 0>
		<cfset params.id = { value = arguments.submissionId, cfsqltype = "cf_sql_integer" }>
		<cfset rows = queryExecute(sql & "s.WebFormSubmissionId = :id", params)>
	<cfelse>
		<cfreturn {}>
	</cfif>
	<cfif not rows.recordCount>
		<cfreturn {}>
	</cfif>
	<cfset r = {
		submissionId: rows.WebFormSubmissionId,
		eventId: rows.EventRef,
		postId: rows.PostRef,
		name: valueOrEmpty(rows.Name),
		email: valueOrEmpty(rows.Email),
		partySize: max(val(rows.PartySize), 1),
		location: val(rows.LocationOptionRef) gt 0 ? application.locations.getLocation(rows.LocationOptionRef) : {},
		status: valueOrEmpty(rows.Status),
		created: rows.Created,
		cancelledAt: isNull(rows.CancelledAt) ? "" : rows.CancelledAt,
		manageToken: valueOrEmpty(rows.ManageToken),
		paymentStatus: len(valueOrEmpty(rows.PaymentStatus)) ? rows.PaymentStatus : "none",
		amountTotal: val(valueOrEmpty(rows.AmountTotal)),
		amountPaid: val(valueOrEmpty(rows.AmountPaid)),
		values: len(rows.ValuesJson) and isJSON(rows.ValuesJson) ? deserializeJSON(rows.ValuesJson) : {}
	}>
	<cfset r.manageUrl = application.blogHostUrl & "/?manageRsvp=" & r.manageToken>
	<cfset r.ev = getEvent(r.postId)>
	<cfset info = getPostInfo(r.postId)>
	<cfset r.title = info.title>
	<cfset r.postUrl = info.url>
	<!--- A cancel link stops working once the event has started. --->
	<cfset r.canCancel = r.status eq "confirmed" and not structIsEmpty(r.ev) and createObject("java", "java.time.Instant").now().isBefore(createObject("java", "java.time.Instant").parse(r.ev.startUtc))>
	<cfset r.refundOnCancel = r.canCancel ? getRefundOnCancel(r) : 0>
	<cfreturn r>
</cffunction>

<!--- ********************************************************************************************************************
	Paid sign-ups (2026-10-15), through the blog owner's Stripe account (Payments.cfc). The sign-up is saved as held, which
	takes its places for as long as the payment page stays open (variables.holdMinutes); the verified payment webhook
	(common/services/stripeWebhook.cfm) confirms it and sends the emails - never the browser. Going back from Stripe, or the
	checkout expiring, releases it. Cancelling refunds what was paid when it's at least the event's RefundHours before the start;
	the owner cancelling always refunds.
********************************************************************************************************************* --->

<cffunction name="getHoldMinutes" access="public" returntype="numeric" output="false" hint="How long a place is held while someone pays: a little longer than Stripe's payment page stays open (31 minutes).">
	<cfreturn 34>
</cffunction>

<cffunction name="confirmPaidRsvp" access="public" returntype="boolean" output="false"
		hint="Called for a verified payment webhook: confirms a held sign-up. Returns true when it changed, so a repeated webhook does nothing.">
	<cfargument name="submissionId" type="numeric" required="true">
	<cfargument name="amountPaid" required="true">
	<cfset var done = false>
	<cftransaction>
		<cfset done = queryExecute("SELECT COUNT(*) AS n FROM WebFormSubmission WHERE WebFormSubmissionId = :id AND EventRef > 0 AND Status IN ('held', 'expired')",
			{ id = { value = arguments.submissionId, cfsqltype = "cf_sql_integer" } }).n gt 0>
		<cfif done>
			<cfset queryExecute("UPDATE WebFormSubmission SET Status = 'confirmed', PaymentStatus = 'paid', AmountPaid = :paid WHERE WebFormSubmissionId = :id",
				{ id = { value = arguments.submissionId, cfsqltype = "cf_sql_integer" }, paid = { value = val(arguments.amountPaid), cfsqltype = "cf_sql_decimal", scale = 2 } })>
		</cfif>
	</cftransaction>
	<cfreturn done>
</cffunction>

<cffunction name="expireHeldRsvp" access="public" returntype="boolean" output="false" hint="Releases a sign-up held for payment (they went back, or the checkout expired). Returns true when it was held.">
	<cfargument name="submissionId" type="numeric" required="true">
	<cfset var done = false>
	<cftransaction>
		<cfset done = queryExecute("SELECT COUNT(*) AS n FROM WebFormSubmission WHERE WebFormSubmissionId = :id AND EventRef > 0 AND Status = 'held'",
			{ id = { value = arguments.submissionId, cfsqltype = "cf_sql_integer" } }).n gt 0>
		<cfif done>
			<cfset queryExecute("UPDATE WebFormSubmission SET Status = 'expired', PaymentStatus = 'expired' WHERE WebFormSubmissionId = :id",
				{ id = { value = arguments.submissionId, cfsqltype = "cf_sql_integer" } })>
		</cfif>
	</cftransaction>
	<cfreturn done>
</cffunction>

<cffunction name="refreshRsvpPaymentStatus" access="public" returntype="void" output="false" hint="Sets a sign-up's PaymentStatus from its payments after a refund: refunded or partlyRefunded.">
	<cfargument name="submissionId" type="numeric" required="true">
	<cfset var totals = application.payments.getRsvpPaymentTotals(arguments.submissionId)>
	<cfif totals.refunded lte 0>
		<cfreturn>
	</cfif>
	<cftransaction>
		<cfset queryExecute("UPDATE WebFormSubmission SET PaymentStatus = :status WHERE WebFormSubmissionId = :id",
			{ id = { value = arguments.submissionId, cfsqltype = "cf_sql_integer" }, status = { value = totals.refunded gte totals.paid ? "refunded" : "partlyRefunded", cfsqltype = "cf_sql_varchar" } })>
	</cftransaction>
</cffunction>

<cffunction name="getRefundOnCancel" access="public" returntype="numeric" output="false"
		hint="What the person gets back if they cancel now: everything paid online when it's at least the event's RefundHours before the start, otherwise 0.">
	<cfargument name="rsvp" type="struct" required="true">
	<cfset var totals = "">
	<cfif structIsEmpty(arguments.rsvp.ev) or arguments.rsvp.ev.refundHours lte 0 or arguments.rsvp.amountPaid lte 0>
		<cfreturn 0>
	</cfif>
	<cfif createObject("java", "java.time.Instant").parse(arguments.rsvp.ev.startUtc).minusSeconds(javacast("long", arguments.rsvp.ev.refundHours * 3600)).isBefore(createObject("java", "java.time.Instant").now())>
		<cfreturn 0>
	</cfif>
	<cfset totals = application.payments.getRsvpPaymentTotals(arguments.rsvp.submissionId)>
	<cfreturn totals.refundable>
</cffunction>

<cffunction name="refundWindowText" access="public" returntype="string" output="false" hint="eg. '24 hours', '2 days'.">
	<cfargument name="hours" type="numeric" required="true">
	<cfif arguments.hours gte 48 and arguments.hours mod 24 eq 0>
		<cfreturn (arguments.hours / 24) & " days">
	</cfif>
	<cfreturn arguments.hours & (arguments.hours eq 1 ? " hour" : " hours")>
</cffunction>

<cffunction name="sendRsvpEmails" access="public" returntype="void" output="false"
		hint="The emails for a sign-up: 'confirmed' (to the person, with the calendar file), 'ownerNew' (a paid sign-up, to the form's notify addresses, once paid), 'cancelledByPerson' (to the person and the owner), 'cancelledByOwner' (to the person) or 'eventCancelled' (to the person, from Cancel all and refund). refunded is shown when money went back. A mail problem is logged and never undoes the sign-up.">
	<cfargument name="rsvp" type="struct" required="true" hint="From getRsvp().">
	<cfargument name="kind" type="string" required="true">
	<cfargument name="refunded" required="false" default="0">
	<cfset var r = arguments.rsvp>
	<cfset var renderer = createObject("component", application.rendererComponentPath)>
	<cfset var utils = createObject("component", application.utilsComponentPath)>
	<cfset var owner = application.BlogDbObj.getBlogEmail()>
	<cfset var webForm = application.webForms.getForm(webFormId = r.ev.webFormId)>
	<cfset var recipients = (not structIsEmpty(webForm) and len(webForm.notifyEmails)) ? webForm.notifyEmails : owner>
	<cfset var emailBody = "">
	<cfset var details = "">
	<cfset var recipient = "">
	<cfset var field = "">
	<cfset var refundLine = val(arguments.refunded) gt 0 ? '<p>Refunded: ' & encodeForHtml(application.payments.formatMoney(arguments.refunded)) & '. It usually reaches your card within 5-10 days.</p>' : "">
	<cftry>
		<cfif listFind("confirmed,cancelledByPerson,cancelledByOwner,eventCancelled", arguments.kind) and isValid("email", r.email)>
			<cfset emailBody = renderer.renderEmail(
				email = r.email,
				emailTitle = arguments.kind eq "confirmed" ? "You have a place" : (arguments.kind eq "eventCancelled" ? "This event is cancelled" : "Your place is cancelled"),
				emailDesc = r.title,
				emailBody = rsvpEmailHtml(r, arguments.kind neq "confirmed", arguments.kind eq "cancelledByPerson") & (arguments.kind eq "cancelledByOwner" ? "<p>The organizer cancelled this sign-up. If you think that's a mistake, please reply to this email.</p>" : "") & (arguments.kind eq "eventCancelled" ? "<p>The event is cancelled, so your place is cancelled too. We're sorry for the change of plans.</p>" : "") & refundLine,
				callToActionText = "See the event",
				callToActionLink = r.postUrl
			)>
			<cfif arguments.kind eq "confirmed">
				<cfset utils.mail(to = r.email, cc = "", subject = "You have a place: #r.title#", body = emailBody, attachmentName = "event.ics", attachmentContent = buildIcs(eventForRsvp(r), r.title, r.postUrl), attachmentType = "text/calendar")>
			<cfelse>
				<cfset utils.mail(to = r.email, cc = "", subject = (arguments.kind eq "eventCancelled" ? "Event cancelled: " : "Cancelled: ") & r.title, body = emailBody)>
			</cfif>
		</cfif>
		<!--- The owner: a new paid sign-up (free ones come with the form's own notification), and cancellations by the person. --->
		<cfif arguments.kind eq "ownerNew" or arguments.kind eq "cancelledByPerson">
			<cfif arguments.kind eq "ownerNew">
				<cfset details = '<table cellpadding="5" cellspacing="5" border="0" align="left">'>
				<cfif not structIsEmpty(webForm)>
					<cfloop array="#webForm.fields#" index="field">
						<cfset details = details & '<tr><td align="right" valign="top">' & encodeForHtml(field.label) & ':</td><td align="left">' & encodeForHtml(structKeyExists(r.values, field.fieldName) ? r.values[field.fieldName] : "") & '</td></tr>'>
					</cfloop>
				</cfif>
				<cfset details = details & '<tr><td align="right">People:</td><td align="left">' & r.partySize & '</td></tr>'>
				<cfif not structIsEmpty(r.location)><cfset details = details & '<tr><td align="right">How:</td><td align="left">' & encodeForHtml(r.location.label) & '</td></tr>'></cfif>
				<cfset details = details & '<tr><td align="right">Paid:</td><td align="left">' & encodeForHtml(application.payments.formatMoney(r.amountPaid)) & '</td></tr>'>
				<cfset details = details & '<tr><td align="right">Places taken:</td><td align="left">' & getPlacesTaken(r.eventId) & (r.ev.capacity gt 0 ? " of " & r.ev.capacity : "") & '</td></tr></table>'>
			<cfelse>
				<cfset details = "<p>" & encodeForHtml(len(r.name) ? r.name : r.email) & " (" & encodeForHtml(r.email) & ") cancelled their place" & (r.partySize gt 1 ? " for " & r.partySize & " people" : "") & " at " & encodeForHtml(r.title) & ". The places are free again.</p>" & (val(arguments.refunded) gt 0 ? "<p>Refunded to them: " & encodeForHtml(application.payments.formatMoney(arguments.refunded)) & "</p>" : "")>
			</cfif>
			<cfset emailBody = renderer.renderEmail(
				email = listFirst(recipients),
				emailTitle = arguments.kind eq "ownerNew" ? "New paid sign-up" : "Sign-up cancelled",
				emailDesc = r.title,
				emailBody = details,
				callToActionText = "",
				callToActionLink = ""
			)>
			<cfloop list="#recipients#" index="recipient">
				<cfif isValid("email", trim(recipient))>
					<cfset utils.mail(to = trim(recipient), subject = (arguments.kind eq "ownerNew" ? "New sign-up: " : "Sign-up cancelled: ") & r.title, body = emailBody)>
				</cfif>
			</cfloop>
		</cfif>
		<cfcatch type="any">
			<cflog file="galaxieBlogErrors" type="error" text="Event RSVP #r.submissionId# (#arguments.kind#): the email could not be sent: #cfcatch.message#">
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="cancelRsvp" access="public" returntype="boolean" output="false" hint="Marks a confirmed sign-up cancelled; it stays in the list and its places are free again.">
	<cfargument name="submissionId" type="numeric" required="true">
	<cfset var done = false>
	<cftransaction>
		<cfset done = queryExecute("SELECT COUNT(*) AS n FROM WebFormSubmission WHERE WebFormSubmissionId = :id AND EventRef > 0 AND Status = 'confirmed'",
			{ id = { value = arguments.submissionId, cfsqltype = "cf_sql_integer" } }).n gt 0>
		<cfif done>
			<cfset queryExecute("UPDATE WebFormSubmission SET Status = 'cancelled', CancelledAt = :now WHERE WebFormSubmissionId = :id",
				{ id = { value = arguments.submissionId, cfsqltype = "cf_sql_integer" }, now = { value = now(), cfsqltype = "cf_sql_timestamp" } })>
		</cfif>
	</cftransaction>
	<cfreturn done>
</cffunction>

<cffunction name="getRsvps" access="public" returntype="array" output="false" hint="An event's sign-ups for the owner, confirmed first, then cancelled; each oldest first.">
	<cfargument name="eventId" type="numeric" required="true">
	<cfset var rows = queryExecute("
		SELECT s.WebFormSubmissionId, s.Name, s.Email, s.PartySize, s.LocationOptionRef, s.Status, s.Created, s.CancelledAt, s.ValuesJson, s.PaymentStatus, s.AmountPaid, s.HoldExpiresAt
		FROM WebFormSubmission s INNER JOIN BlogEvent e ON e.EventId = s.EventRef
		WHERE s.EventRef = :id AND e.BlogRef = :blogId
		ORDER BY CASE WHEN s.Status = 'confirmed' THEN 0 ELSE 1 END, s.Created, s.WebFormSubmissionId",
		{ id = { value = arguments.eventId, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfset var list = []>
	<cfset var place = {}>
	<cfloop query="rows">
		<cfset place = val(rows.LocationOptionRef) gt 0 ? application.locations.getLocation(rows.LocationOptionRef) : {}>
		<cfset arrayAppend(list, {
			submissionId: rows.WebFormSubmissionId,
			name: valueOrEmpty(rows.Name),
			email: valueOrEmpty(rows.Email),
			partySize: max(val(rows.PartySize), 1),
			locationLabel: structIsEmpty(place) ? "" : place.label,
			status: valueOrEmpty(rows.Status),
			created: rows.Created,
			cancelledAt: isNull(rows.CancelledAt) ? "" : rows.CancelledAt,
			paymentStatus: len(valueOrEmpty(rows.PaymentStatus)) ? rows.PaymentStatus : "none",
			amountPaid: val(valueOrEmpty(rows.AmountPaid)),
			<!--- held = on the payment page now; expired = left without paying (or the hold ran out). --->
			paying: valueOrEmpty(rows.Status) eq "held" and isDate(rows.HoldExpiresAt) and rows.HoldExpiresAt gt now(),
			values: len(rows.ValuesJson) and isJSON(rows.ValuesJson) ? deserializeJSON(rows.ValuesJson) : {}
		})>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="getRsvpsCsv" access="public" returntype="string" output="false" hint="An event's sign-ups as CSV: the form's fields, then people, how they'll attend, status and dates.">
	<cfargument name="ev" type="struct" required="true">
	<cfset var webForm = application.webForms.getForm(webFormId = arguments.ev.webFormId)>
	<cfset var fields = structIsEmpty(webForm) ? [] : webForm.fields>
	<cfset var field = "">
	<cfset var r = "">
	<cfset var cells = []>
	<cfset var CRLF = chr(13) & chr(10)>
	<cfset var csv = "">
	<cfloop array="#fields#" index="field"><cfset arrayAppend(cells, csvCell(field.label))></cfloop>
	<cfset arrayAppend(cells, "People,How,Status,Paid,Payment,Signed up,Cancelled")>
	<cfset csv = arrayToList(cells, ",") & CRLF>
	<cfloop array="#getRsvps(arguments.ev.eventId)#" index="r">
		<cfset cells = []>
		<cfloop array="#fields#" index="field">
			<cfset arrayAppend(cells, csvCell(structKeyExists(r.values, field.fieldName) ? r.values[field.fieldName] : ""))>
		</cfloop>
		<cfset arrayAppend(cells, r.partySize)>
		<cfset arrayAppend(cells, csvCell(r.locationLabel))>
		<cfset arrayAppend(cells, csvCell(r.status eq "held" and not r.paying ? "expired" : r.status))>
		<cfset arrayAppend(cells, r.amountPaid gt 0 ? numberFormat(r.amountPaid, "0.00") : "")>
		<cfset arrayAppend(cells, csvCell(r.paymentStatus eq "none" ? "" : r.paymentStatus))>
		<cfset arrayAppend(cells, isDate(r.created) ? dateTimeFormat(r.created, "yyyy-mm-dd HH:nn") : "")>
		<cfset arrayAppend(cells, isDate(r.cancelledAt) ? dateTimeFormat(r.cancelledAt, "yyyy-mm-dd HH:nn") : "")>
		<cfset csv = csv & arrayToList(cells, ",") & CRLF>
	</cfloop>
	<cfreturn csv>
</cffunction>

<cffunction name="rsvpEmailHtml" access="public" returntype="string" output="false"
		hint="The body of the email confirming a place (or its cancellation): the event, when, the way they chose to attend with its details, how many people, Add to Google Calendar, and the cancel link. Every value is encoded here.">
	<cfargument name="rsvp" type="struct" required="true" hint="From getRsvp().">
	<cfargument name="cancelled" type="boolean" required="false" default="false">
	<cfargument name="byPerson" type="boolean" required="false" default="true" hint="Cancelled by the person themselves (thanks them), or by the organizer.">
	<cfset var r = arguments.rsvp>
	<cfset var html = "">
	<cfset html = '<p><b>' & encodeForHtml(r.title) & '</b><br/>' & encodeForHtml(whenText(r.ev)) & '</p>'>
	<cfif arguments.cancelled>
		<cfset html = html & '<p>Your place is cancelled' & (r.partySize gt 1 ? ' (' & r.partySize & ' people)' : '') & '.' & (arguments.byPerson ? ' Thank you for letting us know.' : '') & '</p>'>
		<cfreturn html>
	</cfif>
	<cfset html = html & '<p>You have a place' & (r.partySize gt 1 ? ' for ' & r.partySize & ' people' : '') & '.' & (r.amountPaid gt 0 ? ' Paid: ' & encodeForHtml(application.payments.formatMoney(r.amountPaid)) & '.' : '') & '</p>'>
	<cfif not structIsEmpty(r.location)>
		<cfset html = html & '<p><b>' & encodeForHtml(r.location.label) & '</b></p>' & application.locations.getDetailsHtml(r.location)>
	<cfelseif arrayLen(r.ev.locations)>
		<cfset html = html & application.locations.getDetailsHtml(r.ev.locations[1])>
	</cfif>
	<cfset html = html & '<p><a href="' & encodeForHtmlAttribute(googleCalendarUrl(eventForRsvp(r), r.title, r.postUrl)) & '">Add to Google Calendar</a> - or open the attached calendar file (.ics) to add it to Outlook or Apple Calendar.</p>'>
	<cfset html = html & '<p>Can''t come after all? <a href="' & encodeForHtmlAttribute(r.manageUrl) & '">Cancel your place</a>, so someone else can have it.' & (r.amountPaid gt 0 ? (r.ev.refundHours gt 0 ? ' Cancel at least ' & refundWindowText(r.ev.refundHours) & ' before the start for a full refund.' : ' Payments aren''t refunded.') : '') & '</p>'>
	<cfreturn html>
</cffunction>

<cffunction name="eventForRsvp" access="public" returntype="struct" output="false" hint="The event as this person will attend it: only the way they chose, for their calendar link and .ics file.">
	<cfargument name="rsvp" type="struct" required="true">
	<cfset var ev = duplicate(arguments.rsvp.ev)>
	<cfif not structIsEmpty(arguments.rsvp.location)>
		<cfset ev.locations = [ arguments.rsvp.location ]>
	</cfif>
	<cfreturn ev>
</cffunction>

<cffunction name="csvCell" access="private" returntype="string" output="false">
	<cfargument name="value" required="true">
	<cfset var text = isSimpleValue(arguments.value) ? toString(arguments.value) : "">
	<!--- A cell starting with = + - @ would run as a formula in a spreadsheet. --->
	<cfif reFind("^[=+\-@]", text)><cfset text = "'" & text></cfif>
	<cfreturn '"' & replace(text, '"', '""', "all") & '"'>
</cffunction>

<!--- ********************************************************************************************************************
	Around the site (2026-10-15): the Upcoming Events pod (includes/templates/content/pods/upcomingEvents.cfm, a content
	template that Themes can switch off), the Events page (/events, includes/templates/eventListContentHtml.cfm), the public
	calendar feed (common/services/eventsFeed.cfm) and the event summary at the top of the subscriber email (Renderer.cfc).
	Only events on released posts are shown. The pod and the page are cached (cache/events, cleared by flushListings when an
	event changes, and after an hour so finished events move to Past).
********************************************************************************************************************* --->

<cffunction name="getPublicEvents" access="public" returntype="array" output="false"
		hint="Events visitors can see (released, not removed posts): upcoming (not ended yet, soonest first) or past (latest first). [{ postId, title, url, ev, isOver }]">
	<cfargument name="which" type="string" required="false" default="upcoming" hint="upcoming or past">
	<cfargument name="limit" type="numeric" required="false" default="0" hint="0 = all.">
	<cfset var rows = queryExecute("
		SELECT e.PostRef, e.EndUtc, p.Title, p.IsPage, p.PostAlias, p.DatePosted
		FROM BlogEvent e INNER JOIN Post p ON p.PostId = e.PostRef
		WHERE e.BlogRef = :blogId AND p.Released = 1 AND p.Remove = 0
		ORDER BY e.StartUtc", { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfset var list = []>
	<cfset var nowInstant = createObject("java", "java.time.Instant").now()>
	<cfset var isOver = false>
	<cfset var ev = {}>
	<cfset var reversed = []>
	<cfset var n = 0>
	<cfloop query="rows">
		<cftry>
			<cfset isOver = not nowInstant.isBefore(createObject("java", "java.time.Instant").parse(rows.EndUtc))>
			<cfcatch type="any"><cfcontinue></cfcatch>
		</cftry>
		<cfif (arguments.which eq "past") neq isOver>
			<cfcontinue>
		</cfif>
		<cfset ev = getEvent(rows.PostRef)>
		<cfif structIsEmpty(ev)><cfcontinue></cfif>
		<cfset arrayAppend(list, {
			postId: rows.PostRef,
			title: rows.Title,
			url: application.blog.makeLink(isPage = rows.IsPage, postAlias = rows.PostAlias, datePosted = rows.DatePosted),
			ev: ev,
			isOver: isOver
		})>
	</cfloop>
	<cfif arguments.which eq "past">
		<!--- Latest first. --->
		<cfset reversed = []>
		<cfloop from="#arrayLen(list)#" to="1" step="-1" index="n"><cfset arrayAppend(reversed, list[n])></cfloop>
		<cfset list = reversed>
	</cfif>
	<cfif arguments.limit gt 0 and arrayLen(list) gt arguments.limit>
		<cfset list = arraySlice(list, 1, arguments.limit)>
	</cfif>
	<cfreturn list>
</cffunction>

<cffunction name="getEventsPageUrl" access="public" returntype="string" output="false" hint="The Events page, eg. https://example.com/events (a Page or Page Collection with the alias 'events' wins, so link to it the same way).">
	<cfreturn application.blogHostUrl & (application.serverRewriteRuleInPlace ? "" : "/index.cfm") & "/events">
</cffunction>

<cffunction name="getFeedUrl" access="public" returntype="string" output="false" hint="The public calendar feed (iCal) of this blog's events.">
	<cfreturn application.blogHostUrl & "/common/services/eventsFeed.cfm">
</cffunction>

<cffunction name="ensurePodTemplate" access="public" returntype="void" output="false"
		hint="Makes sure the Upcoming Events pod has its ContentTemplate row (so Themes can switch it off). Run by the 4.9 update and, once per application start, by the sidebar; new installs get it the same way. Safe to run more than once.">
	<cfset var found = 0>
	<cfset var entity = "">
	<cfset var templateType = "">
	<cfif structKeyExists(variables, "podTemplateChecked") and variables.podTemplateChecked>
		<cfreturn>
	</cfif>
	<cftry>
		<cfset found = ormExecuteQuery("SELECT COUNT(*) FROM ContentTemplate WHERE ContentTemplateName = :name", { name = "upcomingEventsPod" }, true)>
		<cfif val(found) eq 0>
			<cftransaction>
				<cfset entity = entityNew("ContentTemplate")>
				<cfset templateType = entityLoadByPK("ContentTemplateType", javacast("int", 2))>
				<cfif not isNull(templateType)><cfset entity.setContentTemplateTypeRef(templateType)></cfif>
				<cfset entity.setParentTemplatePath("includes/templates/sideBar.cfm")>
				<cfset entity.setContentTemplateName("upcomingEventsPod")>
				<cfset entity.setContentTemplateDesc("The upcoming events pod")>
				<cfset entity.setContentTemplatePath("includes/layers/sideBar.cfm")>
				<cfset entity.setActive(true)>
				<cfset entity.setDate(now())>
				<cfset entitySave(entity)>
			</cftransaction>
		</cfif>
		<cfset variables.podTemplateChecked = true>
		<cfcatch type="any">
			<cflog file="galaxieBlogErrors" type="error" text="Events: the Upcoming Events pod template could not be added: #cfcatch.message#">
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="flushListings" access="public" returntype="void" output="false" hint="Clears the cached Upcoming Events pod and Events page, so they show an event's changes at once.">
	<cftry>
		<cfset application.blog.flushGalaxieCacheFiles(application.baseUrl & "/cache/events", ".cfm")>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cffunction>

<cffunction name="shortWhenText" access="public" returntype="string" output="false" hint="eg. 'Sat, Oct 17, 7:00 PM PDT' or 'Oct 17 - 18 (all day)'.">
	<cfargument name="ev" type="struct" required="true">
	<cfset var s = zoned(arguments.ev.startUtc, arguments.ev.timeZone)>
	<cfset var e = zoned(arguments.ev.endUtc, arguments.ev.timeZone)>
	<cfif arguments.ev.allDay>
		<cfif s.toLocalDate().equals(e.toLocalDate())>
			<cfreturn s.format(formatter("EEE, MMM d")) & " (all day)">
		</cfif>
		<cfreturn s.format(formatter("MMM d")) & " - " & e.format(formatter("MMM d")) & " (all day)">
	</cfif>
	<cfreturn s.format(formatter("EEE, MMM d, h:mm a z"))>
</cffunction>

<cffunction name="dateBlockHtml" access="private" returntype="string" output="false">
	<cfargument name="ev" type="struct" required="true">
	<cfset var s = zoned(arguments.ev.startUtc, arguments.ev.timeZone)>
	<cfreturn '<div class="galaxieEventDate k-header" aria-hidden="true"><span class="galaxieEventMonth">' & encodeForHtml(uCase(s.format(formatter("MMM")))) & '</span><span class="galaxieEventDay">' & encodeForHtml(s.format(formatter("d"))) & '</span></div>'>
</cffunction>

<cffunction name="statusNote" access="private" returntype="string" output="false">
	<cfargument name="ev" type="struct" required="true">
	<cfif arguments.ev.status eq "cancelled"><cfreturn "Cancelled"></cfif>
	<cfif arguments.ev.status eq "postponed"><cfreturn "Postponed"></cfif>
	<cfreturn "">
</cffunction>

<cffunction name="renderPodHtml" access="public" returntype="string" output="false" hint="The Upcoming Events pod: the next few events, and links to all events and the calendar feed. Empty when there are none.">
	<cfargument name="limit" type="numeric" required="false" default="5">
	<cfset var list = getPublicEvents("upcoming", arguments.limit)>
	<cfset var item = {}>
	<cfset var html = "">
	<cfset var note = "">
	<cfif not arrayLen(list)>
		<cfreturn "">
	</cfif>
	<cfset html = '<ul class="galaxieEventPodList">'>
	<cfloop array="#list#" index="item">
		<cfset note = statusNote(item.ev)>
		<cfset html = html & '<li class="galaxieEventPodItem">' & dateBlockHtml(item.ev) & '<div class="galaxieEventPodText"><a href="' & encodeForHtmlAttribute(item.url) & '">' & encodeForHtml(item.title) & '</a><br/><span class="galaxieEventPodWhen">' & encodeForHtml(shortWhenText(item.ev)) & '</span>' & (len(note) ? ' <strong>' & note & '</strong>' : '') & '</div></li>'>
	</cfloop>
	<cfset html = html & '</ul><p class="galaxieEventPodLinks"><a href="' & encodeForHtmlAttribute(getEventsPageUrl()) & '">All events</a></p>'>
	<cfreturn html>
</cffunction>

<cffunction name="renderEventsPageHtml" access="public" returntype="string" output="false"
		hint="The Events page (/events): a month calendar of the event days, the upcoming events, the recent past ones, and subscribing to the calendar feed. The calendar and 'your time' are drawn in the browser.">
	<cfset var upcoming = getPublicEvents("upcoming")>
	<cfset var past = getPublicEvents("past", 10)>
	<cfset var html = createObject("java", "java.lang.StringBuilder").init()>
	<cfset var item = {}>
	<cfset var days = []>
	<cfset var feed = getFeedUrl()>
	<cfset var webcal = reReplace(feed, "^https?://", "webcal://")>
	<cfset html.append('<h1 class="topContent">Events</h1>')>
	<cfset html.append('<p class="galaxieEventsFeed">Add every event to your own calendar: <a href="' & encodeForHtmlAttribute(webcal) & '">Subscribe in your calendar app</a> &middot; <a href="' & encodeForHtmlAttribute("https://calendar.google.com/calendar/render?cid=" & encodeForUrl(webcal)) & '" rel="noopener" target="_blank">Add to Google Calendar</a>. New events show up there by themselves.</p>')>
	<!--- The month calendar: event days are highlighted; picking one jumps to its events. --->
	<cfloop array="#upcoming#" index="item">
		<cfset arrayAppend(days, zoned(item.ev.startUtc, item.ev.timeZone).toLocalDate().toString())>
	</cfloop>
	<cfloop array="#past#" index="item">
		<cfset arrayAppend(days, zoned(item.ev.startUtc, item.ev.timeZone).toLocalDate().toString())>
	</cfloop>
	<cfset html.append('<div id="galaxieEventsCalendar" class="galaxieEventsCalendar" data-days="' & encodeForHtmlAttribute(serializeJson(days)) & '"></div>')>
	<cfset html.append('<h2 class="galaxieEventsHeading">Coming up</h2>')>
	<!--- The events alternate k-content / k-alt so each one stands apart (owner, 10-16); each list starts on k-content. --->
	<cfset var itemIndex = 0>
	<cfif arrayLen(upcoming)>
		<cfloop array="#upcoming#" index="item"><cfset itemIndex++><cfset html.append(listItemHtml(item, itemIndex))></cfloop>
	<cfelse>
		<cfset html.append('<p>No events are planned right now. Subscribe above to hear about the next one.</p>')>
	</cfif>
	<cfif arrayLen(past)>
		<cfset html.append('<h2 class="galaxieEventsHeading">Past events</h2>')>
		<cfset itemIndex = 0>
		<cfloop array="#past#" index="item"><cfset itemIndex++><cfset html.append(listItemHtml(item, itemIndex))></cfloop>
	</cfif>
	<cfset html.append(eventsPageScript())>
	<cfreturn html.toString()>
</cffunction>

<cffunction name="listItemHtml" access="private" returntype="string" output="false" hint="One event on the Events page.">
	<cfargument name="item" type="struct" required="true">
	<cfargument name="position" type="numeric" required="false" default="1" hint="1-based place in its list: odd is k-content, even is k-alt.">
	<cfset var ev = arguments.item.ev>
	<cfset var place = "">
	<cfset var ways = []>
	<cfset var note = statusNote(ev)>
	<cfset var html = "">
	<cfloop array="#ev.locations#" index="place"><cfset arrayAppend(ways, place.label)></cfloop>
	<cfset html = '<div class="galaxieEventCard galaxieEventsItem ' & (arguments.position mod 2 ? 'k-content' : 'k-alt') & (arguments.item.isOver ? ' galaxieEventIsOver' : '') & '" data-day="' & zoned(ev.startUtc, ev.timeZone).toLocalDate().toString() & '" data-start-utc="' & encodeForHtmlAttribute(ev.startUtc) & '" data-end-utc="' & encodeForHtmlAttribute(ev.endUtc) & '" data-zone="' & encodeForHtmlAttribute(ev.timeZone) & '" data-all-day="' & (ev.allDay ? "true" : "false") & '">'>
	<cfset html = html & dateBlockHtml(ev) & '<div class="galaxieEventBody">'>
	<cfset html = html & '<h3 class="galaxieEventsItemTitle"><a href="' & encodeForHtmlAttribute(arguments.item.url) & '">' & encodeForHtml(arguments.item.title) & '</a></h3>'>
	<cfif len(note)><cfset html = html & '<p class="galaxieEventStatus"><strong>' & note & '</strong></p>'></cfif>
	<cfset html = html & '<p class="galaxieEventWhen">' & encodeForHtml(whenText(ev)) & '<span class="galaxieEventYourTime"></span></p>'>
	<cfif arrayLen(ways)><cfset html = html & '<p>' & encodeForHtml(arrayToList(ways, " or ")) & '</p>'></cfif>
	<cfif ev.price gt 0>
		<cfset html = html & '<p>' & encodeForHtml(application.payments.formatMoney(ev.price)) & ' per person</p>'>
	<cfelseif len(ev.cost)>
		<cfset html = html & '<p>' & encodeForHtml(ev.cost) & '</p>'>
	</cfif>
	<cfif not arguments.item.isOver and ev.status neq "cancelled">
		<cfset html = html & '<p><a class="k-button" href="' & encodeForHtmlAttribute(arguments.item.url) & '">' & (ev.webFormId gt 0 ? "Details and sign-up" : "Details") & '</a></p>'>
	</cfif>
	<cfreturn html & '</div></div>'>
</cffunction>

<cffunction name="eventsPageScript" access="private" returntype="string" output="false"
		hint="The Events page's month calendar (Kendo Calendar, event days marked; picking one scrolls to its events) and each event's time in the visitor's own zone. The page is cached, so this runs in the browser.">
	<cfsavecontent variable="local.script"><script>
	$(function() {
		var box = $("#galaxieEventsCalendar");
		var days = [];
		try { days = JSON.parse(box.attr("data-days") || "[]"); } catch (e) {}
		function dayKey(d) { return kendo.toString(d, "yyyy-MM-dd"); }
		window.galaxieEventDays = days;
		if ($.fn.kendoCalendar && days.length) {
			box.kendoCalendar({
				value: null,
				<!--- A Kendo template (this Kendo version takes a string, not a function). This script isn't inside cfoutput, so its # signs are Kendo's. --->
				month: {
					content: "#= $.inArray(kendo.toString(data.date, 'yyyy-MM-dd'), window.galaxieEventDays || []) >= 0 ? '<span class=\"galaxieEventsDayMark\">' + data.value + '</span>' : data.value #"
				},
				change: function() {
					var hit = $('.galaxieEventsItem[data-day="' + dayKey(this.value()) + '"]').first();
					if (hit.length) {
						$("html, body").animate({ scrollTop: hit.offset().top - 80 }, 300);
						hit.addClass("galaxieEventsPicked");
						setTimeout(function() { hit.removeClass("galaxieEventsPicked"); }, 2000);
					}
				}
			});
		} else {
			box.remove();
		}
		var mine = "";
		try { mine = Intl.DateTimeFormat().resolvedOptions().timeZone; } catch (e) {}
		$(".galaxieEventsItem").each(function() {
			var c = $(this);
			if (c.attr("data-all-day") === "true" || !mine || mine === c.attr("data-zone")) { return; }
			try {
				var t = new Intl.DateTimeFormat(undefined, { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit", timeZoneName: "short" }).format(new Date(c.attr("data-start-utc")));
				c.find(".galaxieEventYourTime").text(" (your time: " + t + ")");
			} catch (e) {}
		});
	});
	</script></cfsavecontent>
	<cfreturn local.script>
</cffunction>

<cffunction name="buildFeed" access="public" returntype="string" output="false"
		hint="The public calendar feed: this blog's events from the last 90 days on, as one iCalendar file that Google, Outlook and Apple Calendar subscribe to. Each event keeps its UID, so changes update the subscribed copy.">
	<cfset var CRLF = chr(13) & chr(10)>
	<cfset var lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Galaxie Blog//Events//EN", "CALSCALE:GREGORIAN", "METHOD:PUBLISH",
		"X-WR-CALNAME:" & icsText(application.BlogDbObj.getBlogTitle() & " events"),
		"REFRESH-INTERVAL;VALUE=DURATION:PT6H", "X-PUBLISHED-TTL:PT6H"]>
	<cfset var item = {}>
	<cfset var line = "">
	<cfset var result = "">
	<cfset var cutoff = createObject("java", "java.time.Instant").now().minusSeconds(javacast("long", 90 * 86400))>
	<cfset var past = getPublicEvents("past")>
	<cfloop array="#past#" index="item">
		<cfif createObject("java", "java.time.Instant").parse(item.ev.endUtc).isAfter(cutoff)>
			<cfloop array="#veventLines(item.ev, item.title, item.url)#" index="line"><cfset arrayAppend(lines, line)></cfloop>
		</cfif>
	</cfloop>
	<cfloop array="#getPublicEvents('upcoming')#" index="item">
		<cfloop array="#veventLines(item.ev, item.title, item.url)#" index="line"><cfset arrayAppend(lines, line)></cfloop>
	</cfloop>
	<cfset arrayAppend(lines, "END:VCALENDAR")>
	<cfloop array="#lines#" index="line">
		<cfset result = result & icsFold(line) & CRLF>
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="renderEmailSummary" access="public" returntype="string" output="false"
		hint="The event at the top of the subscriber email for a post that is an event: when, where, cost, and links to sign up or add it to a calendar. Empty for other posts. Plain markup that mail programs show well.">
	<cfargument name="postId" type="numeric" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="postUrl" type="string" required="true">
	<cfset var ev = {}>
	<cfset var place = "">
	<cfset var ways = []>
	<cfset var html = "">
	<cftry>
		<cfset ev = getEvent(arguments.postId)>
		<cfcatch type="any"><cfreturn ""></cfcatch>
	</cftry>
	<cfif structIsEmpty(ev)>
		<cfreturn "">
	</cfif>
	<cfloop array="#ev.locations#" index="place"><cfset arrayAppend(ways, place.kind eq "inPerson" and len(place.venueName) ? place.venueName : place.label)></cfloop>
	<cfset html = '<table cellpadding="8" cellspacing="0" border="0" width="100%" style="border: 1px solid ##dddddd; margin-bottom: 16px;"><tr><td>'>
	<cfif ev.status eq "cancelled">
		<cfset html = html & '<p><b>This event is cancelled.</b></p>'>
	<cfelseif ev.status eq "postponed">
		<cfset html = html & '<p><b>This event is postponed.</b> New details will follow.</p>'>
	</cfif>
	<cfset html = html & '<p><b>' & encodeForHtml(whenText(ev)) & '</b>'>
	<cfif arrayLen(ways)><cfset html = html & '<br/>' & encodeForHtml(arrayToList(ways, " or "))></cfif>
	<cfif ev.price gt 0>
		<cfset html = html & '<br/>' & encodeForHtml(application.payments.formatMoney(ev.price)) & ' per person'>
	<cfelseif len(ev.cost)>
		<cfset html = html & '<br/>' & encodeForHtml(ev.cost)>
	</cfif>
	<cfset html = html & '</p>'>
	<cfif ev.status neq "cancelled">
		<cfset html = html & '<p>' & (ev.webFormId gt 0 ? '<a href="' & encodeForHtmlAttribute(arguments.postUrl) & '">Sign up on the website</a> &middot; ' : '') & '<a href="' & encodeForHtmlAttribute(googleCalendarUrl(ev, arguments.title, arguments.postUrl)) & '">Add to Google Calendar</a> &middot; <a href="' & encodeForHtmlAttribute(application.blogHostUrl & "/common/services/eventIcs.cfm?postId=" & arguments.postId) & '">Download for Outlook or Apple Calendar</a></p>'>
	</cfif>
	<cfreturn html & '</td></tr></table>'>
</cffunction>

<cffunction name="veventLines" access="private" returntype="array" output="false" hint="One event's VEVENT lines, for a single .ics file or the feed.">
	<cfargument name="ev" type="struct" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="postUrl" type="string" required="true">
	<cfset var lines = ["BEGIN:VEVENT"]>
	<cfset var s = zoned(arguments.ev.startUtc, arguments.ev.timeZone)>
	<cfset var e = zoned(arguments.ev.endUtc, arguments.ev.timeZone)>
	<cfset arrayAppend(lines, "UID:event-" & arguments.ev.eventId & "-" & application.BlogDbObj.getBlogId() & "@" & reReplace(application.blogHostUrl, "^https?://([^/:]+).*$", "\1"))>
	<cfset arrayAppend(lines, "SEQUENCE:" & int(dateDiff("s", createDateTime(2020, 1, 1, 0, 0, 0), now())))>
	<cfset arrayAppend(lines, "DTSTAMP:" & utcStamp(createObject("java", "java.time.Instant").now().toString()))>
	<cfif arguments.ev.allDay>
		<cfset arrayAppend(lines, "DTSTART;VALUE=DATE:" & s.format(formatter("yyyyMMdd")))>
		<cfset arrayAppend(lines, "DTEND;VALUE=DATE:" & e.plusDays(1).format(formatter("yyyyMMdd")))>
	<cfelse>
		<cfset arrayAppend(lines, "DTSTART:" & utcStamp(arguments.ev.startUtc))>
		<cfset arrayAppend(lines, "DTEND:" & utcStamp(arguments.ev.endUtc))>
	</cfif>
	<cfset arrayAppend(lines, "SUMMARY:" & icsText(arguments.title))>
	<cfif len(locationText(arguments.ev))><cfset arrayAppend(lines, "LOCATION:" & icsText(locationText(arguments.ev)))></cfif>
	<cfset arrayAppend(lines, "DESCRIPTION:" & icsText(arguments.postUrl))>
	<cfset arrayAppend(lines, "URL:" & arguments.postUrl)>
	<cfset arrayAppend(lines, "STATUS:" & (arguments.ev.status eq "cancelled" ? "CANCELLED" : (arguments.ev.status eq "postponed" ? "TENTATIVE" : "CONFIRMED")))>
	<cfset arrayAppend(lines, "END:VEVENT")>
	<cfreturn lines>
</cffunction>

<!--- ********************************************************************************************************************
	The event card, calendar links and Google's event data (2026-10-15)
********************************************************************************************************************* --->

<cffunction name="renderCard" access="public" returntype="string" output="false"
		hint="The event card shown at the top of the post: date, time with its time zone, status, where, cost, organizer, Add to Google Calendar, Download .ics and the tickets link, plus schema.org Event JSON-LD. The page is cached, so 'has it ended' and the visitor's own time are worked out in the browser (the small script after the card). Every value is encoded here.">
	<cfargument name="postId" type="numeric" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="postUrl" type="string" required="true">
	<cfset var ev = {}>
	<cfset var html = createObject("java", "java.lang.StringBuilder").init()>
	<cfset var place = "">
	<cfset var placeHtml = "">
	<cfset var startZoned = "">
	<cfset var endZoned = "">
	<cfset var monthText = "">
	<cfset var dayText = "">
	<cfset var whenLabel = "">
	<cfset var rsvpForm = {}>
	<!--- Every post page calls this, so it must never break one: before the updater has made the BlogEvent table there is simply no card. --->
	<cftry>
		<cfset ev = getEvent(arguments.postId)>
		<cfcatch type="any"><cfreturn ""></cfcatch>
	</cftry>
	<cfif structIsEmpty(ev)>
		<cfreturn "">
	</cfif>
	<cfset startZoned = zoned(ev.startUtc, ev.timeZone)>
	<cfset endZoned = zoned(ev.endUtc, ev.timeZone)>
	<cfset monthText = startZoned.format(formatter("MMM"))>
	<cfset dayText = startZoned.format(formatter("d"))>
	<cfset whenLabel = whenText(ev)>

	<cfset html.append('<div class="galaxieEventCard k-content" data-postid="' & arguments.postId & '" data-start-utc="' & encodeForHtmlAttribute(ev.startUtc) & '" data-end-utc="' & encodeForHtmlAttribute(ev.endUtc) & '" data-zone="' & encodeForHtmlAttribute(ev.timeZone) & '" data-all-day="' & (ev.allDay ? "true" : "false") & '" data-status="' & ev.status & '">')>
	<cfset html.append('<div class="galaxieEventDate k-header" aria-hidden="true"><span class="galaxieEventMonth">' & encodeForHtml(uCase(monthText)) & '</span><span class="galaxieEventDay">' & encodeForHtml(dayText) & '</span></div>')>
	<cfset html.append('<div class="galaxieEventBody">')>
	<cfif ev.status eq "cancelled">
		<cfset html.append('<p class="galaxieEventStatus"><strong>This event is cancelled.</strong></p>')>
	<cfelseif ev.status eq "postponed">
		<cfset html.append('<p class="galaxieEventStatus"><strong>This event is postponed.</strong> New details will follow.</p>')>
	</cfif>
	<cfset html.append('<p class="galaxieEventEnded" hidden><strong>This event has ended.</strong></p>')>
	<cfset html.append('<p class="galaxieEventWhen"><strong>' & encodeForHtml(whenLabel) & '</strong><span class="galaxieEventYourTime"></span></p>')>
	<!--- Where --->
	<cfloop array="#ev.locations#" index="place">
		<cfset placeHtml = placeHtml & '<div class="galaxieEventPlace">' & locationHtml(place) & '</div>'>
	</cfloop>
	<cfif len(placeHtml)>
		<cfset html.append(placeHtml)>
		<cfif arrayLen(ev.locations) gt 1>
			<cfset html.append('<p class="galaxieEventChoice">Come whichever way suits you.</p>')>
		</cfif>
	</cfif>
	<!--- A price paid online wins over the Cost text, which is for events that aren't paid here. --->
	<cfif ev.price gt 0>
		<cfset html.append('<p class="galaxieEventCost">Cost: ' & encodeForHtml(application.payments.formatMoney(ev.price)) & ' per person</p>')>
	<cfelseif len(ev.cost)>
		<cfset html.append('<p class="galaxieEventCost">Cost: ' & encodeForHtml(ev.cost) & '</p>')>
	</cfif>
	<cfif len(ev.organizerName)>
		<cfset html.append('<p class="galaxieEventOrganizer">Organized by ' & (len(ev.organizerUrl) ? '<a href="' & encodeForHtmlAttribute(ev.organizerUrl) & '" rel="noopener">' & encodeForHtml(ev.organizerName) & '</a>' : encodeForHtml(ev.organizerName)) & '</p>')>
	</cfif>
	<!--- Buttons (not for a cancelled event) --->
	<cfif ev.status neq "cancelled">
		<cfset html.append('<p class="galaxieEventButtons">')>
		<cfif len(ev.ticketUrl)>
			<cfset html.append('<a class="k-button k-primary" href="' & encodeForHtmlAttribute(ev.ticketUrl) & '" rel="noopener" target="_blank">Tickets</a> ')>
		</cfif>
		<cfset html.append('<a class="k-button galaxieEventCalendarButton" href="' & encodeForHtmlAttribute(googleCalendarUrl(ev, arguments.title, arguments.postUrl)) & '" rel="noopener" target="_blank">Add to Google Calendar</a> ')>
		<cfset html.append('<a class="k-button galaxieEventCalendarButton" href="' & encodeForHtmlAttribute(application.baseUrl & "/common/services/eventIcs.cfm?postId=" & arguments.postId) & '">Download .ics</a>')>
		<cfset html.append('</p>')>
	</cfif>
	<!--- The RSVP: webForms.js loads the form (with the places left, worked out fresh, as the page is cached) or says why sign-ups are closed. --->
	<cfif ev.webFormId gt 0 and ev.status neq "cancelled">
		<cfset rsvpForm = application.webForms.getForm(webFormId = ev.webFormId)>
		<cfif not structIsEmpty(rsvpForm) and rsvpForm.active>
			<cfset html.append('<div class="galaxieEventRsvp"><h4 class="galaxieEventRsvpHeading">' & encodeForHtml(len(rsvpForm.title) ? rsvpForm.title : "RSVP") & '</h4><div class="galaxieWebForm" data-webform="' & encodeForHtmlAttribute(rsvpForm.alias) & '" data-event-post="' & arguments.postId & '"></div></div>')>
		</cfif>
	</cfif>
	<cfset html.append('</div></div>')>
	<cfset html.append(cardScript())>
	<cfset html.append('<script type="application/ld+json">' & replace(serializeJson(jsonLd(ev, arguments.title, arguments.postUrl)), "</", "<\/", "all") & '</script>')>
	<cfreturn html.toString()>
</cffunction>

<cffunction name="whenText" access="public" returntype="string" output="false" hint="eg. 'Saturday, October 17, 2026, 7:00 PM - 9:00 PM PDT', or 'Saturday, October 17 - Sunday, October 18, 2026 (all day)'.">
	<cfargument name="ev" type="struct" required="true">
	<cfset var s = zoned(arguments.ev.startUtc, arguments.ev.timeZone)>
	<cfset var e = zoned(arguments.ev.endUtc, arguments.ev.timeZone)>
	<cfset var sameDay = s.toLocalDate().equals(e.toLocalDate())>
	<cfif arguments.ev.allDay>
		<cfif sameDay>
			<cfreturn s.format(formatter("EEEE, MMMM d, yyyy")) & " (all day)">
		</cfif>
		<cfreturn s.format(formatter("EEEE, MMMM d")) & " - " & e.format(formatter("EEEE, MMMM d, yyyy")) & " (all day)">
	</cfif>
	<cfif sameDay>
		<cfreturn s.format(formatter("EEEE, MMMM d, yyyy, h:mm a")) & " - " & e.format(formatter("h:mm a z"))>
	</cfif>
	<cfreturn s.format(formatter("EEEE, MMMM d, h:mm a")) & " - " & e.format(formatter("EEEE, MMMM d, yyyy, h:mm a z"))>
</cffunction>

<cffunction name="googleCalendarUrl" access="public" returntype="string" output="false" hint="A link that opens Google Calendar's new event page with this event filled in.">
	<cfargument name="ev" type="struct" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="postUrl" type="string" required="true">
	<cfset var dates = "">
	<cfset var s = zoned(arguments.ev.startUtc, arguments.ev.timeZone)>
	<cfset var e = zoned(arguments.ev.endUtc, arguments.ev.timeZone)>
	<cfif arguments.ev.allDay>
		<!--- All day: dates only, and the end is the day after the last day. --->
		<cfset dates = s.format(formatter("yyyyMMdd")) & "/" & e.plusDays(1).format(formatter("yyyyMMdd"))>
	<cfelse>
		<cfset dates = utcStamp(arguments.ev.startUtc) & "/" & utcStamp(arguments.ev.endUtc)>
	</cfif>
	<cfreturn "https://calendar.google.com/calendar/render?action=TEMPLATE&text=" & encodeForUrl(arguments.title)
		& "&dates=" & dates & "&ctz=" & encodeForUrl(arguments.ev.timeZone)
		& "&details=" & encodeForUrl(arguments.postUrl)
		& "&location=" & encodeForUrl(locationText(arguments.ev))>
</cffunction>

<cffunction name="buildIcs" access="public" returntype="string" output="false"
		hint="The event as a calendar file (.ics). The UID stays the same, so adding it again updates the entry instead of making a second one; SEQUENCE grows each time.">
	<cfargument name="ev" type="struct" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="postUrl" type="string" required="true">
	<cfset var CRLF = chr(13) & chr(10)>
	<cfset var lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Galaxie Blog//Events//EN", "CALSCALE:GREGORIAN", "METHOD:PUBLISH"]>
	<cfset var line = "">
	<cfset var result = "">
	<cfloop array="#veventLines(arguments.ev, arguments.title, arguments.postUrl)#" index="line"><cfset arrayAppend(lines, line)></cfloop>
	<cfset arrayAppend(lines, "END:VCALENDAR")>
	<cfloop array="#lines#" index="line">
		<cfset result = result & icsFold(line) & CRLF>
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="jsonLd" access="public" returntype="struct" output="false" hint="schema.org Event data, so search engines can show the post as an event.">
	<cfargument name="ev" type="struct" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="postUrl" type="string" required="true">
	<cfset var data = { "@context": "https://schema.org", "@type": "Event", "name": arguments.title, "url": arguments.postUrl }>
	<cfset var places = []>
	<cfset var place = "">
	<cfset var hasPhysical = false>
	<cfset var hasOnline = false>
	<cfset var isoFormat = arguments.ev.allDay ? "yyyy-MM-dd" : "yyyy-MM-dd'T'HH:mmXXX">
	<cfset data[ "startDate" ] = zoned(arguments.ev.startUtc, arguments.ev.timeZone).format(formatter(isoFormat))>
	<cfset data[ "endDate" ] = zoned(arguments.ev.endUtc, arguments.ev.timeZone).format(formatter(isoFormat))>
	<cfset data[ "eventStatus" ] = arguments.ev.status eq "cancelled" ? "https://schema.org/EventCancelled" : (arguments.ev.status eq "postponed" ? "https://schema.org/EventPostponed" : "https://schema.org/EventScheduled")>
	<cfloop array="#arguments.ev.locations#" index="place">
		<cfif place.kind eq "online">
			<cfset hasOnline = true>
			<cfset arrayAppend(places, { "@type": "VirtualLocation", "url": place.onlineLinkMode eq "fixed" and len(place.onlineUrl) ? place.onlineUrl : arguments.postUrl })>
		<cfelseif place.kind eq "inPerson">
			<cfset hasPhysical = true>
			<cfset arrayAppend(places, { "@type": "Place", "name": len(place.venueName) ? place.venueName : place.label, "address": reReplace(place.address, "\s*\n\s*", ", ", "all") })>
		</cfif>
	</cfloop>
	<cfset data[ "eventAttendanceMode" ] = hasPhysical and hasOnline ? "https://schema.org/MixedEventAttendanceMode" : (hasOnline ? "https://schema.org/OnlineEventAttendanceMode" : "https://schema.org/OfflineEventAttendanceMode")>
	<cfif arrayLen(places) eq 1>
		<cfset data[ "location" ] = places[1]>
	<cfelseif arrayLen(places)>
		<cfset data[ "location" ] = places>
	</cfif>
	<cfif len(arguments.ev.organizerName)>
		<cfset data[ "organizer" ] = { "@type": "Organization", "name": arguments.ev.organizerName }>
		<cfif len(arguments.ev.organizerUrl)><cfset data.organizer[ "url" ] = arguments.ev.organizerUrl></cfif>
	</cfif>
	<cfif len(arguments.ev.ticketUrl)>
		<cfset data[ "offers" ] = { "@type": "Offer", "url": arguments.ev.ticketUrl }>
	<cfelseif arguments.ev.price gt 0>
		<cfset data[ "offers" ] = { "@type": "Offer", "url": arguments.postUrl, "price": numberFormat(arguments.ev.price, "0.00"), "priceCurrency": application.payments.getCurrency() }>
	</cfif>
	<cfreturn data>
</cffunction>

<cffunction name="locationHtml" access="private" returntype="string" output="false" hint="One way to attend, for the event card. Every value is encoded here.">
	<cfargument name="place" type="struct" required="true">
	<cfset var l = arguments.place>
	<cfset var html = "">
	<cfset var mapUrl = application.locations.getMapUrl(l)>
	<cfswitch expression="#l.kind#">
		<cfcase value="online">
			<cfif l.onlineLinkMode eq "fixed" and len(l.onlineUrl)>
				<cfset html = '<p>Online: <a href="' & encodeForHtmlAttribute(l.onlineUrl) & '" rel="noopener" target="_blank">Join online</a></p>'>
			<cfelse>
				<cfset html = "<p>Online. The link is sent before the event.</p>">
			</cfif>
		</cfcase>
		<cfcase value="phone">
			<cfif l.phoneDirection eq "youCall" and len(l.phoneNumber)>
				<cfset html = '<p>By phone: <a href="tel:' & encodeForHtmlAttribute(reReplace(l.phoneNumber, "[^0-9+]", "", "all")) & '">' & encodeForHtml(l.phoneNumber) & '</a></p>'>
			<cfelse>
				<cfset html = "<p>By phone.</p>">
			</cfif>
		</cfcase>
		<cfdefaultcase>
			<cfset html = "<p>" & (len(l.venueName) ? encodeForHtml(l.venueName) & "<br>" : "") & replace(encodeForHtml(reReplace(l.address, "\r", "", "all")), "&##xa;", "<br>", "all") & (len(mapUrl) ? ' <a href="' & encodeForHtmlAttribute(mapUrl) & '" rel="noopener" target="_blank">Open in maps</a>' : "") & "</p>">
			<!--- Lucee's encodeForHtml leaves newlines as they are. --->
			<cfset html = replace(html, chr(10), "<br>", "all")>
		</cfdefaultcase>
	</cfswitch>
	<cfif len(l.instructions)>
		<cfset html = html & '<p class="galaxieEventInstructions">' & replace(replace(encodeForHtml(reReplace(l.instructions, "\r", "", "all")), "&##xa;", "<br>", "all"), chr(10), "<br>", "all") & "</p>">
	</cfif>
	<cfreturn html>
</cffunction>

<cffunction name="locationText" access="private" returntype="string" output="false" hint="Where, as plain text for a calendar entry.">
	<cfargument name="ev" type="struct" required="true">
	<cfset var parts = []>
	<cfset var place = "">
	<cfloop array="#arguments.ev.locations#" index="place">
		<cfif place.kind eq "inPerson">
			<cfset arrayAppend(parts, trim((len(place.venueName) ? place.venueName & ", " : "") & reReplace(place.address, "\s*\n\s*", ", ", "all")))>
		<cfelseif place.kind eq "online">
			<cfset arrayAppend(parts, place.onlineLinkMode eq "fixed" and len(place.onlineUrl) ? place.onlineUrl : "Online")>
		<cfelse>
			<cfset arrayAppend(parts, "By phone" & (place.phoneDirection eq "youCall" and len(place.phoneNumber) ? " " & place.phoneNumber : ""))>
		</cfif>
	</cfloop>
	<cfreturn arrayToList(parts, " / ")>
</cffunction>

<cffunction name="cardScript" access="private" returntype="string" output="false"
		hint="The card's own small script, worked out in the visitor's browser (the page is cached): 'This event has ended', and the time in the visitor's own time zone when it isn't the event's. Written once per page.">
	<cfreturn '<script>(function(){if(window.galaxieEventCards){return;}window.galaxieEventCards=true;function run(){var cards=document.querySelectorAll(".galaxieEventCard");for(var i=0;i<cards.length;i++){var c=cards[i];var end=new Date(c.getAttribute("data-end-utc"));if(!isNaN(end)&&end<new Date()){var ended=c.querySelector(".galaxieEventEnded");if(ended){ended.hidden=false;}c.classList.add("galaxieEventIsOver");}if(c.getAttribute("data-all-day")==="true"){continue;}try{var mine=Intl.DateTimeFormat().resolvedOptions().timeZone;if(mine&&mine!==c.getAttribute("data-zone")){var start=new Date(c.getAttribute("data-start-utc"));var text=new Intl.DateTimeFormat(undefined,{weekday:"short",month:"short",day:"numeric",hour:"numeric",minute:"2-digit",timeZoneName:"short"}).format(start);var span=c.querySelector(".galaxieEventYourTime");if(span){span.textContent=" (your time: "+text+")";}}}catch(e){}}}if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",run);}else{run();}})();</script>'>
</cffunction>

<cffunction name="zoned" access="private" returntype="any" output="false" hint="A UTC instant in the event's time zone (java ZonedDateTime).">
	<cfargument name="utc" type="string" required="true">
	<cfargument name="zoneId" type="string" required="true">
	<cfreturn createObject("java", "java.time.Instant").parse(arguments.utc).atZone(createObject("java", "java.time.ZoneId").of(arguments.zoneId))>
</cffunction>

<cffunction name="formatter" access="private" returntype="any" output="false">
	<cfargument name="pattern" type="string" required="true">
	<cfreturn createObject("java", "java.time.format.DateTimeFormatter").ofPattern(arguments.pattern, createObject("java", "java.util.Locale").ENGLISH)>
</cffunction>

<cffunction name="utcStamp" access="private" returntype="string" output="false" hint="An ISO instant as 20261018T020000Z.">
	<cfargument name="utc" type="string" required="true">
	<cfreturn createObject("java", "java.time.Instant").parse(arguments.utc).atZone(createObject("java", "java.time.ZoneOffset").UTC).format(formatter("yyyyMMdd'T'HHmmss'Z'"))>
</cffunction>

<cffunction name="icsText" access="private" returntype="string" output="false">
	<cfargument name="text" type="string" required="true">
	<cfset var s = replace(arguments.text, "\", "\\", "all")>
	<cfset s = replace(s, ";", "\;", "all")>
	<cfset s = replace(s, ",", "\,", "all")>
	<cfset s = replace(replace(s, chr(13), "", "all"), chr(10), "\n", "all")>
	<cfreturn s>
</cffunction>

<cffunction name="icsFold" access="private" returntype="string" output="false">
	<cfargument name="line" type="string" required="true">
	<cfset var folded = "">
	<cfset var rest = arguments.line>
	<cfloop condition="len(rest) gt 74">
		<cfset folded = folded & mid(rest, 1, 74) & chr(13) & chr(10) & " ">
		<cfset rest = mid(rest, 75, len(rest))>
	</cfloop>
	<cfreturn folded & rest>
</cffunction>

</cfcomponent>
