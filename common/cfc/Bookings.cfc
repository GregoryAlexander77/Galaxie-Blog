<cfcomponent displayName="Bookings" output="false" hint="Appointments visitors book with the blog owner (2026-10-14): booking types, the owner's weekly hours and days off - and, in the next steps, the bookings themselves. Created once as application.bookings in Application.cfc. Entities: BookingType, LocationOptionLookup, AvailabilityRule and AvailabilityException (common/cfc/db/galaxieDb); locations are in Locations.cfc. See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 3.">

<!---
	Every write is inside a cftransaction: the application sets ormsettings.flushAtRequestEnd = false, so an entity change made
	outside a transaction (without ormFlush) would never reach the database.

	Times: the owner's hours are wall-clock times ("09:00") in the blog's time zone (Blog Settings, blog.cfc's getBlogTimeZoneId),
	and days off are "yyyy-mm-dd" strings in that zone. Nothing stores a number of hours, so daylight saving changes never move them.
--->

<cffunction name="init" access="public" returntype="any" output="false">
	<cfset variables.dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]>
	<cfreturn this>
</cffunction>

<cffunction name="getDayNames" access="public" returntype="array" output="false">
	<cfreturn duplicate(variables.dayNames)>
</cffunction>

<!--- ********************************************************************************************************************
	Booking types
********************************************************************************************************************* --->

<cffunction name="getBookingTypes" access="public" returntype="array" output="false"
		hint="This blog's booking types by category, order and name, each as getBookingType() returns it.">
	<cfargument name="activeOnly" type="boolean" required="false" default="false">
	<cfset var types = []>
	<cfset var entity = "">
	<cfset var found = ormExecuteQuery("FROM BookingType WHERE BlogRef = :blogId ORDER BY Category, SortOrder, Name", { blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfloop array="#found#" index="entity">
		<cfif not arguments.activeOnly or isTrue(entity.getActive(), true)>
			<cfset arrayAppend(types, toStruct(entity))>
		</cfif>
	</cfloop>
	<cfreturn types>
</cffunction>

<cffunction name="getBookingType" access="public" returntype="struct" output="false"
		hint="One booking type of this blog, by id or alias, with its location ids in order. Empty struct when there is none.">
	<cfargument name="bookingTypeId" required="false" default="">
	<cfargument name="alias" type="string" required="false" default="">
	<cfset var found = []>
	<cfif isNumeric(arguments.bookingTypeId) and arguments.bookingTypeId gt 0>
		<cfset found = ormExecuteQuery("FROM BookingType WHERE BookingTypeId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.bookingTypeId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfelseif len(trim(arguments.alias))>
		<cfset found = ormExecuteQuery("FROM BookingType WHERE Alias = :alias AND BlogRef = :blogId", { alias = trim(arguments.alias), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	</cfif>
	<cfreturn arrayLen(found) ? toStruct(found[1]) : {}>
</cffunction>

<cffunction name="getCategories" access="public" returntype="array" output="false"
		hint="The categories already used by this blog's booking types, for the editor's list.">
	<cfset var categories = []>
	<cfset var rows = queryExecute("SELECT DISTINCT Category FROM BookingType WHERE BlogRef = :blogId AND Category IS NOT NULL AND Category <> '' ORDER BY Category",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cfset arrayAppend(categories, rows.Category)>
	</cfloop>
	<cfreturn categories>
</cffunction>

<cffunction name="toStruct" access="private" returntype="struct" output="false">
	<cfargument name="entity" required="true">
	<cfset var e = arguments.entity>
	<cfset var bookingType = {
		bookingTypeId: e.getBookingTypeId(),
		name: valueOrEmpty(e.getName()),
		alias: valueOrEmpty(e.getAlias()),
		category: valueOrEmpty(e.getCategory()),
		description: valueOrEmpty(e.getDescription()),
		durationMinutes: intOr(e.getDurationMinutes(), 60),
		startIntervalMinutes: intOr(e.getStartIntervalMinutes(), 30),
		bufferBeforeMinutes: intOr(e.getBufferBeforeMinutes(), 0),
		bufferAfterMinutes: intOr(e.getBufferAfterMinutes(), 0),
		bookingMode: valueOrEmpty(e.getBookingMode()) eq "group" ? "group" : "oneOnOne",
		groupSize: intOr(e.getGroupSize(), 1),
		price: isNull(e.getPrice()) ? 0 : val(e.getPrice()),
		pricingUnit: valueOrEmpty(e.getPricingUnit()) eq "perPerson" ? "perPerson" : "perBooking",
		paymentOption: len(valueOrEmpty(e.getPaymentOption())) ? e.getPaymentOption() : "free",
		depositAmount: isNull(e.getDepositAmount()) ? 0 : val(e.getDepositAmount()),
		depositIsPercent: isTrue(e.getDepositIsPercent()),
		balanceCollection: valueOrEmpty(e.getBalanceCollection()) eq "online" ? "online" : "inPerson",
		refundHours: intOr(e.getRefundHours(), 24),
		webFormId: intOr(e.getWebFormRef(), 0),
		minNoticeHours: intOr(e.getMinNoticeHours(), 24),
		maxDaysAhead: intOr(e.getMaxDaysAhead(), 60),
		dailyLimit: intOr(e.getDailyLimit(), 0),
		requiresApproval: isTrue(e.getRequiresApproval()),
		reminderHours: intOr(e.getReminderHours(), 24),
		active: isTrue(e.getActive(), true),
		sortOrder: intOr(e.getSortOrder(), 0),
		locationIds: []
	}>
	<cfset var rows = queryExecute("SELECT LocationOptionRef FROM LocationOptionLookup WHERE BookingTypeRef = :id ORDER BY SortOrder, LocationOptionLookupId",
		{ id = { value = bookingType.bookingTypeId, cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cfset arrayAppend(bookingType.locationIds, rows.LocationOptionRef)>
	</cfloop>
	<cfreturn bookingType>
</cffunction>

<cffunction name="saveBookingType" access="public" returntype="struct" output="false"
		hint="Creates or updates a booking type and the locations it offers. Returns { success, bookingTypeId, errors[] }; nothing is saved when something is wrong.">
	<cfargument name="data" type="struct" required="true">
	<cfset var result = { success: false, bookingTypeId: 0, errors: [] }>
	<cfset var d = arguments.data>
	<cfset var name = left(trim(structKeyExists(d, "name") ? d.name : ""), 125)>
	<cfset var isNew = not (structKeyExists(d, "bookingTypeId") and isNumeric(d.bookingTypeId) and d.bookingTypeId gt 0)>
	<cfset var duration = wholeNumber(d, "durationMinutes", 60)>
	<cfset var startInterval = wholeNumber(d, "startIntervalMinutes", 30)>
	<cfset var bookingMode = structKeyExists(d, "bookingMode") and d.bookingMode eq "group" ? "group" : "oneOnOne">
	<cfset var groupSize = bookingMode eq "group" ? wholeNumber(d, "groupSize", 2) : 1>
	<cfset var price = structKeyExists(d, "price") and isNumeric(d.price) ? round(d.price * 100) / 100 : 0>
	<cfset var locationIds = []>
	<cfset var activeLocationIds = {}>
	<cfset var thisLocation = "">
	<cfset var locationId = "">
	<cfset var webFormId = wholeNumber(d, "webFormId", 0)>
	<cfset var entity = "">
	<cfset var existing = []>
	<cfset var lookup = "">
	<cfset var position = 0>

	<!--- Only this blog's locations are kept. --->
	<cfloop array="#application.locations.getLocations()#" index="thisLocation">
		<cfset activeLocationIds[thisLocation.locationOptionId] = true>
	</cfloop>
	<cfif structKeyExists(d, "locationIds") and isArray(d.locationIds)>
		<cfloop array="#d.locationIds#" index="locationId">
			<cfif isNumeric(locationId) and structKeyExists(activeLocationIds, int(locationId)) and not arrayFind(locationIds, int(locationId))>
				<cfset arrayAppend(locationIds, int(locationId))>
			</cfif>
		</cfloop>
	</cfif>

	<!--- Check everything first. --->
	<cfif not len(name)><cfset arrayAppend(result.errors, "The booking type needs a name.")></cfif>
	<cfif duration lt 5 or duration gt 1440><cfset arrayAppend(result.errors, "The length must be between 5 minutes and 24 hours.")></cfif>
	<cfif not listFind("0,5,10,15,20,30,45,60,90,120", startInterval)><cfset arrayAppend(result.errors, "Choose how often start times are offered.")></cfif>
	<cfif bookingMode eq "group" and (groupSize lt 2 or groupSize gt 1000)><cfset arrayAppend(result.errors, "A group needs room for 2 to 1000 people.")></cfif>
	<cfif price lt 0><cfset arrayAppend(result.errors, "The price can't be negative.")></cfif>
	<cfif not arrayLen(locationIds)><cfset arrayAppend(result.errors, "Choose at least one location - where or how you meet.")></cfif>
	<cfif webFormId gt 0 and structIsEmpty(application.webForms.getForm(webFormId = webFormId))><cfset arrayAppend(result.errors, "That intake form no longer exists.")></cfif>
	<cfif not isNew>
		<cfset existing = ormExecuteQuery("FROM BookingType WHERE BookingTypeId = :id AND BlogRef = :blogId", { id = javacast("int", d.bookingTypeId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
		<cfif not arrayLen(existing)><cfset arrayAppend(result.errors, "That booking type no longer exists.")></cfif>
	</cfif>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>

	<cftransaction>
		<cfif isNew>
			<cfset entity = entityNew("BookingType")>
			<cfset entity.setBlogRef(application.BlogDbObj.getBlogId())>
			<!--- The alias is made once, from the name, and stays when the name changes, so posts that use it keep working. --->
			<cfset entity.setAlias(makeUniqueAlias(name))>
			<cfset entity.setCreated(now())>
		<cfelse>
			<cfset entity = existing[1]>
		</cfif>
		<cfset entity.setName(name)>
		<cfset entity.setCategory(left(trim(structKeyExists(d, "category") ? d.category : ""), 100))>
		<cfset entity.setDescription(left(trim(replace(structKeyExists(d, "description") ? d.description : "", chr(13), "", "all")), 4000))>
		<cfset entity.setDurationMinutes(duration)>
		<cfset entity.setStartIntervalMinutes(startInterval)>
		<cfset entity.setBufferBeforeMinutes(min(wholeNumber(d, "bufferBeforeMinutes", 0), 480))>
		<cfset entity.setBufferAfterMinutes(min(wholeNumber(d, "bufferAfterMinutes", 0), 480))>
		<cfset entity.setBookingMode(bookingMode)>
		<cfset entity.setGroupSize(groupSize)>
		<cfset entity.setPrice(javacast("bigdecimal", price))>
		<cfset entity.setPricingUnit(bookingMode eq "group" and structKeyExists(d, "pricingUnit") and d.pricingUnit eq "perPerson" ? "perPerson" : "perBooking")>
		<!--- Until payments are set up (the Stripe step), a priced type is "full" and a free one "free". --->
		<cfif isNew or isNull(entity.getPaymentOption()) or not len(entity.getPaymentOption()) or (price eq 0) or (entity.getPaymentOption() eq "free")>
			<cfset entity.setPaymentOption(price gt 0 ? "full" : "free")>
		</cfif>
		<cfif isNew>
			<cfset entity.setDepositAmount(javacast("bigdecimal", 0))>
			<cfset entity.setDepositIsPercent(false)>
			<cfset entity.setBalanceCollection("inPerson")>
			<cfset entity.setRefundHours(24)>
		</cfif>
		<cfset entity.setWebFormRef(webFormId)>
		<cfset entity.setMinNoticeHours(min(wholeNumber(d, "minNoticeHours", 24), 8760))>
		<cfset entity.setMaxDaysAhead(max(1, min(wholeNumber(d, "maxDaysAhead", 60), 730)))>
		<cfset entity.setDailyLimit(min(wholeNumber(d, "dailyLimit", 0), 1000))>
		<cfset entity.setRequiresApproval(isTrue(structKeyExists(d, "requiresApproval") ? d.requiresApproval : false))>
		<cfset entity.setReminderHours(min(wholeNumber(d, "reminderHours", 24), 336))>
		<cfset entity.setActive(isTrue(structKeyExists(d, "active") ? d.active : true, true))>
		<cfset entity.setSortOrder(wholeNumber(d, "sortOrder", 0))>
		<cfset entity.setDate(now())>
		<cfset entitySave(entity)>

		<!--- The locations it offers, in the order given. --->
		<cfquery name="local.deleteLookups" dbtype="hql">
			DELETE FROM LocationOptionLookup WHERE BookingTypeRef = <cfqueryparam value="#entity.getBookingTypeId()#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfloop array="#locationIds#" index="locationId">
			<cfset position = position + 1>
			<cfset lookup = entityNew("LocationOptionLookup")>
			<cfset lookup.setLocationOptionRef(locationId)>
			<cfset lookup.setBookingTypeRef(entity.getBookingTypeId())>
			<cfset lookup.setPostRef(0)>
			<cfset lookup.setSortOrder(position)>
			<cfset lookup.setDate(now())>
			<cfset entitySave(lookup)>
		</cfloop>
	</cftransaction>

	<cfif entity.getReminderHours() gt 0>
		<cfset ensureReminderTask()>
	</cfif>
	<cfset result.success = true>
	<cfset result.bookingTypeId = entity.getBookingTypeId()>
	<cfreturn result>
</cffunction>

<cffunction name="deleteBookingType" access="public" returntype="boolean" output="false"
		hint="Deletes a booking type and its location choices. (Once bookings exist - the next step - a type with bookings is turned off instead, so their history is kept.)">
	<cfargument name="bookingTypeId" type="numeric" required="true">
	<cfset var found = ormExecuteQuery("FROM BookingType WHERE BookingTypeId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.bookingTypeId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif not arrayLen(found)>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfquery name="local.deleteLookups" dbtype="hql">
			DELETE FROM LocationOptionLookup WHERE BookingTypeRef = <cfqueryparam value="#arguments.bookingTypeId#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfset entityDelete(found[1])>
	</cftransaction>
	<cfreturn true>
</cffunction>

<cffunction name="getTypesUsingLocation" access="public" returntype="array" output="false"
		hint="The names of the booking types that offer a location - a location in use can't be deleted (it can be made inactive).">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cfset var names = []>
	<cfset var rows = queryExecute("
		SELECT t.Name FROM LocationOptionLookup l INNER JOIN BookingType t ON t.BookingTypeId = l.BookingTypeRef
		WHERE l.LocationOptionRef = :id AND t.BlogRef = :blogId ORDER BY t.Name
	", { id = { value = arguments.locationOptionId, cfsqltype = "cf_sql_integer" }, blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cfset arrayAppend(names, rows.Name)>
	</cfloop>
	<cfreturn names>
</cffunction>

<!--- ********************************************************************************************************************
	The owner's hours
********************************************************************************************************************* --->

<cffunction name="getHours" access="public" returntype="struct" output="false"
		hint="The weekly hours for the general schedule (locationOptionId 0) or one location: { own: has its own hours, days: [ 7 arrays of { start, end } ], Sunday first }. A location without its own hours shows the general hours, with own = false.">
	<cfargument name="locationOptionId" type="numeric" required="false" default="0">
	<cfset var hours = { own: false, days: [[], [], [], [], [], [], []] }>
	<cfset var rows = readRules(arguments.locationOptionId)>
	<cfif arguments.locationOptionId gt 0 and rows.recordCount>
		<cfset hours.own = true>
	<cfelseif arguments.locationOptionId gt 0>
		<cfset rows = readRules(0)>
	</cfif>
	<cfloop query="rows">
		<cfif rows.DayOfWeek gte 1 and rows.DayOfWeek lte 7>
			<cfset arrayAppend(hours.days[rows.DayOfWeek], { "start": rows.StartTime, "end": rows.EndTime })>
		</cfif>
	</cfloop>
	<cfreturn hours>
</cffunction>

<cffunction name="readRules" access="private" returntype="query" output="false">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cfreturn queryExecute("
		SELECT DayOfWeek, StartTime, EndTime FROM AvailabilityRule
		WHERE BlogRef = :blogId AND LocationOptionRef = :locationId AND BookingTypeRef = 0
		ORDER BY DayOfWeek, StartTime
	", { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, locationId = { value = arguments.locationOptionId, cfsqltype = "cf_sql_integer" } })>
</cffunction>

<cffunction name="saveHours" access="public" returntype="struct" output="false"
		hint="Replaces the weekly hours of the general schedule (0) or one location. own = false for a location removes its own hours, so it follows the general ones again. Returns { success, errors[] }.">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cfargument name="own" type="boolean" required="true">
	<cfargument name="days" type="array" required="true" hint="7 arrays (Sunday first) of { start, end } in HH:mm.">
	<cfset var result = { success: false, errors: [] }>
	<cfset var ranges = []>
	<cfset var day = 0>
	<cfset var range = "">
	<cfset var previousEnd = "">
	<cfset var rule = "">

	<cfif arguments.locationOptionId gt 0 and structIsEmpty(application.locations.getLocation(arguments.locationOptionId))>
		<cfset arrayAppend(result.errors, "That location no longer exists.")>
		<cfreturn result>
	</cfif>
	<!--- Check every range: valid times, start before end, and no overlaps within a day. --->
	<cfif arguments.own or arguments.locationOptionId eq 0>
		<cfloop from="1" to="7" index="day">
			<cfset previousEnd = "">
			<cfset ranges = arrayLen(arguments.days) gte day and isArray(arguments.days[day]) ? arguments.days[day] : []>
			<cfset ranges = sortRanges(ranges)>
			<cfloop array="#ranges#" index="range">
				<cfif not isTime24(range.start) or not isTime24(range.end)>
					<cfset arrayAppend(result.errors, variables.dayNames[day] & ": enter times like 09:00 or 17:30.")>
				<cfelseif range.end lte range.start>
					<cfset arrayAppend(result.errors, variables.dayNames[day] & ": " & range.start & " to " & range.end & " ends before it starts.")>
				<cfelseif len(previousEnd) and range.start lt previousEnd>
					<cfset arrayAppend(result.errors, variables.dayNames[day] & ": the times overlap.")>
				</cfif>
				<cfset previousEnd = range.end>
			</cfloop>
			<cfset arguments.days[day] = ranges>
		</cfloop>
	</cfif>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>

	<cftransaction>
		<cfquery name="local.deleteRules" dbtype="hql">
			DELETE FROM AvailabilityRule
			WHERE BlogRef = <cfqueryparam value="#application.BlogDbObj.getBlogId()#" cfsqltype="cf_sql_integer">
			AND LocationOptionRef = <cfqueryparam value="#arguments.locationOptionId#" cfsqltype="cf_sql_integer">
			AND BookingTypeRef = 0
		</cfquery>
		<cfif arguments.own or arguments.locationOptionId eq 0>
			<cfloop from="1" to="7" index="day">
				<cfloop array="#arguments.days[day]#" index="range">
					<cfset rule = entityNew("AvailabilityRule")>
					<cfset rule.setBlogRef(application.BlogDbObj.getBlogId())>
					<cfset rule.setBookingTypeRef(0)>
					<cfset rule.setLocationOptionRef(arguments.locationOptionId)>
					<cfset rule.setDayOfWeek(day)>
					<cfset rule.setStartTime(range.start)>
					<cfset rule.setEndTime(range.end)>
					<cfset rule.setDate(now())>
					<cfset entitySave(rule)>
				</cfloop>
			</cfloop>
		</cfif>
	</cftransaction>
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<cffunction name="sortRanges" access="private" returntype="array" output="false"
		hint="The well-formed { start, end } ranges of one day, earliest first.">
	<cfargument name="ranges" type="array" required="true">
	<cfset var keys = []>
	<cfset var kept = []>
	<cfset var range = "">
	<cfset var key = "">
	<!--- "HH:mm|HH:mm" sorts as text in time order. --->
	<cfloop array="#arguments.ranges#" index="range">
		<cfif isStruct(range) and structKeyExists(range, "start") and structKeyExists(range, "end") and isSimpleValue(range.start) and isSimpleValue(range.end)>
			<cfset arrayAppend(keys, trim(range.start) & "|" & trim(range.end))>
		</cfif>
	</cfloop>
	<cfset arraySort(keys, "text")>
	<cfloop array="#keys#" index="key">
		<cfset arrayAppend(kept, { "start": listFirst(key, "|"), "end": listLast(key, "|") })>
	</cfloop>
	<cfreturn kept>
</cffunction>

<!--- ********************************************************************************************************************
	Days off and changed hours
********************************************************************************************************************* --->

<cffunction name="getExceptions" access="public" returntype="array" output="false"
		hint="Days off and days with different hours, from today on (in the blog's time zone), earliest first: [{ availabilityExceptionId, date, locationOptionId, closed, start, end, note }].">
	<cfset var exceptions = []>
	<cfset var rows = queryExecute("
		SELECT AvailabilityExceptionId, ExceptionDate, LocationOptionRef, Closed, StartTime, EndTime, Note
		FROM AvailabilityException
		WHERE BlogRef = :blogId AND ExceptionDate >= :today
		ORDER BY ExceptionDate, LocationOptionRef
	", { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, today = { value = dateFormat(application.blog.blogNow(), "yyyy-mm-dd"), cfsqltype = "cf_sql_varchar" } })>
	<cfloop query="rows">
		<cfset arrayAppend(exceptions, {
			"availabilityExceptionId": rows.AvailabilityExceptionId,
			"date": rows.ExceptionDate,
			"locationOptionId": val(rows.LocationOptionRef),
			"closed": isTrue(rows.Closed, true),
			"start": valueOrEmpty(rows.StartTime),
			"end": valueOrEmpty(rows.EndTime),
			"note": valueOrEmpty(rows.Note)
		})>
	</cfloop>
	<cfreturn exceptions>
</cffunction>

<cffunction name="saveException" access="public" returntype="struct" output="false"
		hint="Adds a day off or a day with different hours. Returns { success, errors[] }.">
	<cfargument name="data" type="struct" required="true" hint="date (yyyy-mm-dd), locationOptionId (0 = all), closed, start, end, note.">
	<cfset var result = { success: false, errors: [] }>
	<cfset var d = arguments.data>
	<cfset var exceptionDate = structKeyExists(d, "date") ? trim(d.date) : "">
	<cfset var closed = isTrue(structKeyExists(d, "closed") ? d.closed : true, true)>
	<cfset var startTime = structKeyExists(d, "start") ? trim(d.start) : "">
	<cfset var endTime = structKeyExists(d, "end") ? trim(d.end) : "">
	<cfset var locationOptionId = wholeNumber(d, "locationOptionId", 0)>
	<cfset var entity = "">
	<cfif not reFind("^\d{4}-\d{2}-\d{2}$", exceptionDate) or not isDate(exceptionDate)>
		<cfset arrayAppend(result.errors, "Choose the date.")>
	<cfelseif exceptionDate lt dateFormat(application.blog.blogNow(), "yyyy-mm-dd")>
		<cfset arrayAppend(result.errors, "That date has already passed.")>
	</cfif>
	<cfif not closed and (not isTime24(startTime) or not isTime24(endTime) or endTime lte startTime)>
		<cfset arrayAppend(result.errors, "Enter the hours for that day, like 09:00 to 12:00.")>
	</cfif>
	<cfif locationOptionId gt 0 and structIsEmpty(application.locations.getLocation(locationOptionId))>
		<cfset arrayAppend(result.errors, "That location no longer exists.")>
	</cfif>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>
	<cftransaction>
		<cfset entity = entityNew("AvailabilityException")>
		<cfset entity.setBlogRef(application.BlogDbObj.getBlogId())>
		<cfset entity.setBookingTypeRef(0)>
		<cfset entity.setLocationOptionRef(locationOptionId)>
		<cfset entity.setExceptionDate(exceptionDate)>
		<cfset entity.setClosed(closed)>
		<cfset entity.setStartTime(closed ? "" : startTime)>
		<cfset entity.setEndTime(closed ? "" : endTime)>
		<cfset entity.setNote(left(trim(structKeyExists(d, "note") ? d.note : ""), 255))>
		<cfset entity.setDate(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<cffunction name="deleteException" access="public" returntype="boolean" output="false">
	<cfargument name="availabilityExceptionId" type="numeric" required="true">
	<cfset var found = ormExecuteQuery("FROM AvailabilityException WHERE AvailabilityExceptionId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.availabilityExceptionId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif not arrayLen(found)>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfset entityDelete(found[1])>
	</cftransaction>
	<cfreturn true>
</cffunction>

<cffunction name="deleteLocationSchedule" access="public" returntype="void" output="false"
		hint="Removes a location's own hours and days off, when the location is deleted.">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cftransaction>
		<cfquery name="local.deleteRules" dbtype="hql">
			DELETE FROM AvailabilityRule WHERE LocationOptionRef = <cfqueryparam value="#arguments.locationOptionId#" cfsqltype="cf_sql_integer">
			AND BlogRef = <cfqueryparam value="#application.BlogDbObj.getBlogId()#" cfsqltype="cf_sql_integer">
		</cfquery>
		<cfquery name="local.deleteExceptions" dbtype="hql">
			DELETE FROM AvailabilityException WHERE LocationOptionRef = <cfqueryparam value="#arguments.locationOptionId#" cfsqltype="cf_sql_integer">
			AND BlogRef = <cfqueryparam value="#application.BlogDbObj.getBlogId()#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cftransaction>
</cffunction>

<!--- ********************************************************************************************************************
	What visitors see: the booking types, the free times, and booking one (2026-10-14)

	How free times are worked out (getSlots), all in the blog's time zone, in minutes from midnight:
	1. The day's hours: a day off (for every location, or this one) closes it; a day with different hours replaces the weekly
	   hours (this location's change first, then one for every location); otherwise the location's own weekly hours, or the
	   general ones.
	2. Start times every StartIntervalMinutes from the start of each range (or back to back), where the whole booking fits.
	3. Not sooner than MinNoticeHours from now, nor more than MaxDaysAhead days away; no more than DailyLimit of this type a day.
	4. Not overlapping another booking - of any type, at any location, since the owner is one person - each with its gaps
	   before and after. A group type shares its own session: the places left are GroupSize less the people already booked.
	A place held for payment counts until its hold expires (the Stripe step).
********************************************************************************************************************* --->

<cffunction name="getPublicTypes" access="public" returntype="array" output="false"
		hint="The active booking types (all, or the one with this alias) with their active locations, as visitors see them. Nothing private is included. Types without an active location are left out.">
	<cfargument name="alias" type="string" required="false" default="">
	<cfset var types = []>
	<cfset var bookingType = "">
	<cfset var locations = {}>
	<cfset var thisLocation = "">
	<cfset var locationId = "">
	<cfset var offered = []>
	<cfloop array="#application.locations.getLocations(activeOnly = true)#" index="thisLocation">
		<cfset locations[thisLocation.locationOptionId] = thisLocation>
	</cfloop>
	<cfloop array="#getBookingTypes(activeOnly = true)#" index="bookingType">
		<cfif not len(arguments.alias) or bookingType.alias eq arguments.alias>
			<cfset offered = []>
			<cfloop array="#bookingType.locationIds#" index="locationId">
				<cfif structKeyExists(locations, locationId)>
					<cfset arrayAppend(offered, {
						"locationOptionId": locationId,
						"label": locations[locationId].label,
						"kind": locations[locationId].kind,
						"needsPhone": locations[locationId].kind eq "phone" and locations[locationId].phoneDirection eq "weCall"
					})>
				</cfif>
			</cfloop>
			<cfif arrayLen(offered)>
				<cfset arrayAppend(types, {
					"alias": bookingType.alias,
					"name": bookingType.name,
					"category": bookingType.category,
					"description": bookingType.description,
					"durationMinutes": bookingType.durationMinutes,
					"price": bookingType.price,
					"pricingUnit": bookingType.pricingUnit,
					"isGroup": bookingType.bookingMode eq "group",
					"groupSize": bookingType.groupSize,
					"locations": offered,
					"hasQuestions": bookingType.webFormId gt 0
				})>
			</cfif>
		</cfif>
	</cfloop>
	<cfreturn types>
</cffunction>

<cffunction name="getSlots" access="public" returntype="array" output="false"
		hint="The times a booking type can be booked at a location between two dates (inclusive, 'yyyy-mm-dd' in the blog's time zone): [{ local: 'yyyy-mm-dd HH:mm', utc: ISO 8601, spotsLeft }], earliest first. See the notes above.">
	<cfargument name="bookingType" type="struct" required="true" hint="As getBookingType() returns it.">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cfargument name="fromDate" type="string" required="true">
	<cfargument name="toDate" type="string" required="true">
	<cfargument name="excludeBookingId" type="numeric" required="false" default="0" hint="A booking to leave out, so it can be moved (rescheduling).">
	<cfset var t = arguments.bookingType>
	<cfset var slots = []>
	<cfset var zoneId = application.blog.getBlogTimeZoneId()>
	<cfset var blogNow = application.blog.blogNow()>
	<cfset var earliest = dateTimeFormat(dateAdd("n", t.minNoticeHours * 60, blogNow), "yyyy-mm-dd HH:nn")>
	<cfset var lastDate = dateFormat(dateAdd("d", t.maxDaysAhead, blogNow), "yyyy-mm-dd")>
	<cfset var fromText = arguments.fromDate>
	<cfset var toText = arguments.toDate lt lastDate ? arguments.toDate : lastDate>
	<cfset var weekly = getHours(arguments.locationOptionId).days>
	<cfset var exceptions = getExceptionsBetween(fromText, toText)>
	<cfset var booked = getActiveBookingsBetween(fromText, toText, arguments.excludeBookingId)>
	<cfset var currentDay = "">
	<cfset var dateText = "">
	<cfset var ranges = []>
	<cfset var range = "">
	<cfset var step = t.startIntervalMinutes gt 0 ? t.startIntervalMinutes : t.durationMinutes>
	<cfset var start = 0>
	<cfset var finish = 0>
	<cfset var localText = "">
	<cfset var b = "">
	<cfset var conflict = false>
	<cfset var seatsTaken = 0>
	<cfset var typeCountToday = 0>
	<cfset var capacity = t.bookingMode eq "group" ? t.groupSize : 1>

	<cfif not len(zoneId) or not isValidDate(fromText) or not isValidDate(toText) or toText lt fromText>
		<cfreturn slots>
	</cfif>
	<!--- Never more than 62 days in one call. --->
	<cfif dateDiff("d", parseDate(fromText), parseDate(toText)) gt 62>
		<cfset toText = dateFormat(dateAdd("d", 62, parseDate(fromText)), "yyyy-mm-dd")>
	</cfif>

	<cfset currentDay = parseDate(fromText)>
	<cfloop condition="dateFormat(currentDay, 'yyyy-mm-dd') lte toText">
		<cfset dateText = dateFormat(currentDay, "yyyy-mm-dd")>
		<cfset ranges = getDayRanges(dateText, dayOfWeek(currentDay), arguments.locationOptionId, weekly, exceptions)>
		<!--- The daily limit for this type. --->
		<cfset typeCountToday = 0>
		<cfloop array="#booked#" index="b">
			<cfif left(b.startLocal, 10) eq dateText and b.bookingTypeId eq t.bookingTypeId>
				<cfset typeCountToday = typeCountToday + 1>
			</cfif>
		</cfloop>
		<cfif t.dailyLimit gt 0 and typeCountToday gte t.dailyLimit>
			<cfset ranges = []>
		</cfif>
		<cfloop array="#ranges#" index="range">
			<cfset start = range.start>
			<cfloop condition="start + t.durationMinutes lte range.end">
				<cfset finish = start + t.durationMinutes>
				<cfset localText = dateText & " " & minutesToTime(start)>
				<cfif localText gte earliest>
					<cfset conflict = false>
					<cfset seatsTaken = 0>
					<cfloop array="#booked#" index="b">
						<cfif left(b.startLocal, 10) eq dateText>
							<cfif t.bookingMode eq "group" and b.bookingTypeId eq t.bookingTypeId and b.locationOptionId eq arguments.locationOptionId and b.startMinutes eq start>
								<!--- The same group session: share its places. --->
								<cfset seatsTaken = seatsTaken + b.partySize>
							<cfelseif (start - t.bufferBeforeMinutes) lt (b.endMinutes + b.bufferAfterMinutes) and (b.startMinutes - b.bufferBeforeMinutes) lt (finish + t.bufferAfterMinutes)>
								<cfset conflict = true>
								<cfbreak>
							</cfif>
						</cfif>
					</cfloop>
					<cfif not conflict and seatsTaken lt capacity>
						<cfset arrayAppend(slots, { "local": localText, "utc": toUtc(dateText, start, zoneId), "spotsLeft": capacity - seatsTaken })>
					</cfif>
				</cfif>
				<cfset start = start + step>
			</cfloop>
		</cfloop>
		<cfset currentDay = dateAdd("d", 1, currentDay)>
	</cfloop>
	<cfreturn slots>
</cffunction>

<cffunction name="getDayRanges" access="private" returntype="array" output="false"
		hint="One day's open ranges for a location, in minutes from midnight, after days off and changed hours: [{ start, end }].">
	<cfargument name="dateText" type="string" required="true">
	<cfargument name="dayOfWeek" type="numeric" required="true">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cfargument name="weekly" type="array" required="true">
	<cfargument name="exceptions" type="array" required="true">
	<cfset var ranges = []>
	<cfset var e = "">
	<cfset var forLocation = "">
	<cfset var forAll = "">
	<cfset var range = "">
	<cfloop array="#arguments.exceptions#" index="e">
		<cfif e.date eq arguments.dateText and (e.locationOptionId eq 0 or e.locationOptionId eq arguments.locationOptionId)>
			<cfif e.closed>
				<cfreturn []>
			</cfif>
			<cfif e.locationOptionId eq arguments.locationOptionId><cfset forLocation = e><cfelse><cfset forAll = e></cfif>
		</cfif>
	</cfloop>
	<cfif isStruct(forLocation)>
		<cfreturn [{ start: timeToMinutes(forLocation.start), end: timeToMinutes(forLocation.end) }]>
	<cfelseif isStruct(forAll)>
		<cfreturn [{ start: timeToMinutes(forAll.start), end: timeToMinutes(forAll.end) }]>
	</cfif>
	<cfloop array="#arguments.weekly[arguments.dayOfWeek]#" index="range">
		<cfset arrayAppend(ranges, { start: timeToMinutes(range.start), end: timeToMinutes(range.end) })>
	</cfloop>
	<cfreturn ranges>
</cffunction>

<cffunction name="getExceptionsBetween" access="private" returntype="array" output="false">
	<cfargument name="fromDate" type="string" required="true">
	<cfargument name="toDate" type="string" required="true">
	<cfset var exceptions = []>
	<cfset var rows = queryExecute("
		SELECT ExceptionDate, LocationOptionRef, Closed, StartTime, EndTime FROM AvailabilityException
		WHERE BlogRef = :blogId AND ExceptionDate >= :fromDate AND ExceptionDate <= :toDate
	", { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, fromDate = { value = arguments.fromDate, cfsqltype = "cf_sql_varchar" }, toDate = { value = arguments.toDate, cfsqltype = "cf_sql_varchar" } })>
	<cfloop query="rows">
		<cfset arrayAppend(exceptions, { date: rows.ExceptionDate, locationOptionId: val(rows.LocationOptionRef), closed: isTrue(rows.Closed, true), start: valueOrEmpty(rows.StartTime), end: valueOrEmpty(rows.EndTime) })>
	</cfloop>
	<cfreturn exceptions>
</cffunction>

<cffunction name="getActiveBookingsBetween" access="private" returntype="array" output="false"
		hint="The bookings that take up time between two dates: confirmed, waiting for approval, or held for payment until the hold expires.">
	<cfargument name="fromDate" type="string" required="true">
	<cfargument name="toDate" type="string" required="true">
	<cfargument name="excludeBookingId" type="numeric" required="false" default="0">
	<cfset var booked = []>
	<cfset var rows = queryExecute("
		SELECT BookingId, BookingTypeRef, LocationOptionRef, StartLocal, EndLocal, PartySize, BufferBeforeMinutes, BufferAfterMinutes, Status, HoldExpiresAt
		FROM Booking
		WHERE BlogRef = :blogId AND StartLocal >= :fromLocal AND StartLocal <= :toLocal AND Status IN ('confirmed', 'pending')
	", { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, fromLocal = { value = arguments.fromDate & " 00:00", cfsqltype = "cf_sql_varchar" }, toLocal = { value = arguments.toDate & " 23:59", cfsqltype = "cf_sql_varchar" } })>
	<cfloop query="rows">
		<!--- A hold for payment that has run out no longer counts. --->
		<cfif not (isDate(rows.HoldExpiresAt) and rows.HoldExpiresAt lt now()) and rows.BookingId neq arguments.excludeBookingId>
			<cfset arrayAppend(booked, {
				bookingTypeId: val(rows.BookingTypeRef),
				locationOptionId: val(rows.LocationOptionRef),
				startLocal: rows.StartLocal,
				startMinutes: timeToMinutes(right(rows.StartLocal, 5)),
				endMinutes: left(rows.EndLocal, 10) eq left(rows.StartLocal, 10) ? timeToMinutes(right(rows.EndLocal, 5)) : 1440,
				partySize: max(val(rows.PartySize), 1),
				bufferBeforeMinutes: val(rows.BufferBeforeMinutes),
				bufferAfterMinutes: val(rows.BufferAfterMinutes)
			})>
		</cfif>
	</cfloop>
	<cfreturn booked>
</cffunction>

<cffunction name="createBooking" access="public" returntype="struct" output="false"
		hint="Books a time, after checking it is still free. The caller holds a lock around this (ProxyController's submitBooking), so two visitors can't take the same time. Returns { success, errors: { field: message }, message, bookingId, status }.">
	<cfargument name="bookingType" type="struct" required="true" hint="As getBookingType() returns it.">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cfargument name="startLocal" type="string" required="true" hint="yyyy-mm-dd HH:mm in the blog's time zone.">
	<cfargument name="partySize" type="numeric" required="true">
	<cfargument name="name" type="string" required="true">
	<cfargument name="email" type="string" required="true">
	<cfargument name="phone" type="string" required="true">
	<cfargument name="visitorTimeZone" type="string" required="false" default="">
	<cfargument name="intakeValues" type="struct" required="false" default="#{}#" hint="Checked answers (WebForms.validateSubmission's values), when the type asks questions.">
	<cfargument name="postId" type="numeric" required="false" default="0">
	<cfset var t = arguments.bookingType>
	<cfset var result = { success: false, errors: {}, message: "", bookingId: 0, status: "" }>
	<cfset var meetLocation = application.locations.getLocation(arguments.locationOptionId)>
	<cfset var slots = []>
	<cfset var slot = "">
	<cfset var found = "">
	<cfset var party = t.bookingMode eq "group" ? max(int(arguments.partySize), 1) : 1>
	<cfset var startMinutes = 0>
	<cfset var amount = 0>
	<cfset var submissionId = 0>
	<cfset var entity = "">
	<cfset var zoneId = application.blog.getBlogTimeZoneId()>

	<cfif not arrayFind(t.locationIds, arguments.locationOptionId) or structIsEmpty(meetLocation) or not meetLocation.active>
		<cfset result.message = "Please choose where to meet again.">
		<cfreturn result>
	</cfif>
	<cfif not reFind("^\d{4}-\d{2}-\d{2} ([01]\d|2[0-3]):[0-5]\d$", arguments.startLocal)>
		<cfset result.message = "Please choose a time again.">
		<cfreturn result>
	</cfif>
	<cfif not len(trim(arguments.name))><cfset result.errors["name"] = "Please enter your name."></cfif>
	<cfif not isValid("email", trim(arguments.email))><cfset result.errors["email"] = "Please enter a valid email address."></cfif>
	<cfif meetLocation.kind eq "phone" and meetLocation.phoneDirection eq "weCall" and not reFind("^[0-9+().\-\s]{5,50}$", trim(arguments.phone))>
		<cfset result.errors["phone"] = "Please enter the number to call you on.">
	<cfelseif len(trim(arguments.phone)) and not reFind("^[0-9+().\-\s]{5,50}$", trim(arguments.phone))>
		<cfset result.errors["phone"] = "Please enter a phone number.">
	</cfif>
	<cfif t.bookingMode eq "group" and (party lt 1 or party gt t.groupSize)>
		<cfset result.errors["partySize"] = "Please choose how many people.">
	</cfif>
	<cfif not structIsEmpty(result.errors)>
		<cfreturn result>
	</cfif>

	<!--- Is the time still free, with room for everyone? --->
	<cfset slots = getSlots(t, arguments.locationOptionId, left(arguments.startLocal, 10), left(arguments.startLocal, 10))>
	<cfloop array="#slots#" index="slot">
		<cfif slot.local eq arguments.startLocal><cfset found = slot><cfbreak></cfif>
	</cfloop>
	<cfif not isStruct(found)>
		<cfset result.message = "Sorry, that time was just taken. Please choose another.">
		<cfreturn result>
	</cfif>
	<cfif found.spotsLeft lt party>
		<cfset result.message = "Sorry, there " & (found.spotsLeft eq 1 ? "is only 1 place" : "are only " & found.spotsLeft & " places") & " left at that time.">
		<cfreturn result>
	</cfif>

	<cfset startMinutes = timeToMinutes(right(arguments.startLocal, 5))>
	<cfset amount = t.price * (t.pricingUnit eq "perPerson" ? party : 1)>
	<!--- The intake answers are kept as a submission of the type's form, so they show under Forms > Submissions too. --->
	<cfif t.webFormId gt 0 and not structIsEmpty(arguments.intakeValues)>
		<cfset submissionId = application.webForms.saveSubmission(application.webForms.getForm(webFormId = t.webFormId), arguments.intakeValues, arguments.postId)>
	</cfif>
	<cftransaction>
		<cfset entity = entityNew("Booking")>
		<cfset entity.setBlogRef(application.BlogDbObj.getBlogId())>
		<cfset entity.setBookingTypeRef(t.bookingTypeId)>
		<cfset entity.setLocationOptionRef(arguments.locationOptionId)>
		<cfset entity.setStartLocal(arguments.startLocal)>
		<cfset entity.setEndLocal(left(arguments.startLocal, 10) & " " & minutesToTime(min(startMinutes + t.durationMinutes, 1439)))>
		<cfset entity.setTimeZone(zoneId)>
		<cfset entity.setStartUtc(found.utc)>
		<cfset entity.setVisitorTimeZone(left(reReplace(arguments.visitorTimeZone, "[^A-Za-z0-9_/+\-]", "", "all"), 64))>
		<cfset entity.setBufferBeforeMinutes(t.bufferBeforeMinutes)>
		<cfset entity.setBufferAfterMinutes(t.bufferAfterMinutes)>
		<cfset entity.setPartySize(party)>
		<cfset entity.setName(left(trim(arguments.name), 255))>
		<cfset entity.setEmail(left(trim(arguments.email), 255))>
		<cfset entity.setPhone(left(trim(arguments.phone), 50))>
		<cfset entity.setWebFormSubmissionRef(submissionId)>
		<cfset entity.setStatus(t.requiresApproval ? "pending" : "confirmed")>
		<!--- Until payments are set up (the Stripe step), a price is owed in full and paid outside the blog. --->
		<cfset entity.setPaymentStatus("none")>
		<cfset entity.setPaymentChoice(amount gt 0 ? "full" : "")>
		<cfset entity.setAmountTotal(javacast("bigdecimal", amount))>
		<cfset entity.setAmountPaid(javacast("bigdecimal", 0))>
		<cfset entity.setBalanceDue(javacast("bigdecimal", amount))>
		<cfset entity.setManageToken(lCase(hash(createUUID() & rand("SHA1PRNG") & getTickCount(), "SHA-256")))>
		<cfset entity.setNotes("")>
		<cfset entity.setPostRef(arguments.postId)>
		<cfset entity.setReminderSent(false)>
		<cfset entity.setCreated(now())>
		<cfset entity.setDate(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfif t.reminderHours gt 0>
		<cfset ensureReminderTask()>
	</cfif>
	<cfset result.success = true>
	<cfset result.bookingId = entity.getBookingId()>
	<cfset result.status = entity.getStatus()>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	Managing bookings (2026-10-14): reading them for the admin list and the visitor's own page, changing their status,
	moving them, and the emails. The visitor's link ("Cancel or change this booking") is the blog's address with
	?manageBooking=<ManageToken>; common/js/bookings.js shows their booking there.
********************************************************************************************************************* --->

<cffunction name="getBooking" access="public" returntype="struct" output="false"
		hint="One booking of this blog, by id or by its manage token, with its type, location and intake answers. Empty struct when there is none.">
	<cfargument name="bookingId" required="false" default="0">
	<cfargument name="manageToken" type="string" required="false" default="">
	<cfset var found = []>
	<cfset var e = "">
	<cfset var b = {}>
	<cfset var answers = []>
	<cfset var webForm = "">
	<cfset var values = {}>
	<cfset var field = "">
	<cfset var submission = "">
	<cfif isNumeric(arguments.bookingId) and arguments.bookingId gt 0>
		<cfset found = ormExecuteQuery("FROM Booking WHERE BookingId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.bookingId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfelseif reFind("^[a-f0-9]{64}$", arguments.manageToken)>
		<cfset found = ormExecuteQuery("FROM Booking WHERE ManageToken = :token AND BlogRef = :blogId", { token = arguments.manageToken, blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	</cfif>
	<cfif not arrayLen(found)>
		<cfreturn b>
	</cfif>
	<cfset e = found[1]>
	<cfset b = {
		bookingId: e.getBookingId(),
		bookingTypeId: intOr(e.getBookingTypeRef(), 0),
		locationOptionId: intOr(e.getLocationOptionRef(), 0),
		startLocal: valueOrEmpty(e.getStartLocal()),
		endLocal: valueOrEmpty(e.getEndLocal()),
		timeZone: valueOrEmpty(e.getTimeZone()),
		startUtc: valueOrEmpty(e.getStartUtc()),
		visitorTimeZone: valueOrEmpty(e.getVisitorTimeZone()),
		partySize: intOr(e.getPartySize(), 1),
		name: valueOrEmpty(e.getName()),
		email: valueOrEmpty(e.getEmail()),
		phone: valueOrEmpty(e.getPhone()),
		status: valueOrEmpty(e.getStatus()),
		paymentStatus: valueOrEmpty(e.getPaymentStatus()),
		amountTotal: isNull(e.getAmountTotal()) ? 0 : val(e.getAmountTotal()),
		balanceDue: isNull(e.getBalanceDue()) ? 0 : val(e.getBalanceDue()),
		manageToken: valueOrEmpty(e.getManageToken()),
		notes: valueOrEmpty(e.getNotes()),
		postId: intOr(e.getPostRef(), 0),
		reminderSent: isTrue(e.getReminderSent()),
		created: e.getCreated(),
		bookingType: getBookingType(bookingTypeId = intOr(e.getBookingTypeRef(), 0)),
		location: application.locations.getLocation(intOr(e.getLocationOptionRef(), 0)),
		answers: []
	}>
	<!--- The intake answers, under their questions, in the form's order. --->
	<cfif intOr(e.getWebFormSubmissionRef(), 0) gt 0 and not structIsEmpty(b.bookingType) and b.bookingType.webFormId gt 0>
		<cfset submission = queryExecute("SELECT ValuesJson FROM WebFormSubmission WHERE WebFormSubmissionId = :id", { id = { value = e.getWebFormSubmissionRef(), cfsqltype = "cf_sql_integer" } })>
		<cfset webForm = application.webForms.getForm(webFormId = b.bookingType.webFormId)>
		<cfif submission.recordCount and not structIsEmpty(webForm)>
			<cftry>
				<cfset values = deserializeJSON(submission.ValuesJson)>
				<cfcatch type="any"><cfset values = {}></cfcatch>
			</cftry>
			<cfloop array="#webForm.fields#" index="field">
				<cfif isStruct(values) and structKeyExists(values, field.fieldName) and isSimpleValue(values[field.fieldName]) and len(values[field.fieldName])>
					<cfset arrayAppend(b.answers, { "label": field.label, "value": values[field.fieldName] })>
				</cfif>
			</cfloop>
		</cfif>
	</cfif>
	<cfreturn b>
</cffunction>

<cffunction name="getBookingsForList" access="public" returntype="array" output="false"
		hint="This blog's bookings for the admin list: upcoming (from today, earliest first), past (latest first) or all.">
	<cfargument name="range" type="string" required="false" default="upcoming">
	<cfset var list = []>
	<cfset var today = dateFormat(application.blog.blogNow(), "yyyy-mm-dd") & " 00:00">
	<cfset var sql = "SELECT b.BookingId, b.StartLocal, b.EndLocal, b.Name, b.Email, b.Phone, b.PartySize, b.Status, b.AmountTotal, b.BalanceDue, t.Name AS TypeName, l.Label AS LocationLabel
		FROM Booking b LEFT JOIN BookingType t ON t.BookingTypeId = b.BookingTypeRef LEFT JOIN LocationOption l ON l.LocationOptionId = b.LocationOptionRef
		WHERE b.BlogRef = :blogId">
	<cfset var rows = "">
	<cfif arguments.range eq "past">
		<cfset sql = sql & " AND b.StartLocal < :today ORDER BY b.StartLocal DESC">
	<cfelseif arguments.range eq "all">
		<cfset sql = sql & " AND (b.StartLocal >= :today OR b.StartLocal < :today) ORDER BY b.StartLocal DESC">
	<cfelse>
		<cfset sql = sql & " AND b.StartLocal >= :today ORDER BY b.StartLocal">
	</cfif>
	<cfset rows = queryExecute(sql, { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" }, today = { value = today, cfsqltype = "cf_sql_varchar" } })>
	<cfloop query="rows">
		<cfset arrayAppend(list, {
			bookingId: rows.BookingId, startLocal: rows.StartLocal, endLocal: rows.EndLocal, name: rows.Name, email: rows.Email,
			phone: valueOrEmpty(rows.Phone), partySize: val(rows.PartySize), status: rows.Status,
			amountTotal: val(rows.AmountTotal), balanceDue: val(rows.BalanceDue),
			typeName: valueOrEmpty(rows.TypeName), locationLabel: valueOrEmpty(rows.LocationLabel)
		})>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="setStatus" access="public" returntype="boolean" output="false"
		hint="Changes a booking's status: confirmed (approve), cancelled, completed or noShow. A cancelled booking frees its time.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfargument name="status" type="string" required="true">
	<cfset var found = ormExecuteQuery("FROM Booking WHERE BookingId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.bookingId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif not arrayLen(found) or not listFind("confirmed,cancelled,completed,noShow", arguments.status)>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfset found[1].setStatus(arguments.status)>
		<cfset found[1].setDate(now())>
		<cfset entitySave(found[1])>
	</cftransaction>
	<cfreturn true>
</cffunction>

<cffunction name="saveNotes" access="public" returntype="boolean" output="false" hint="The owner's private notes on a booking.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfargument name="notes" type="string" required="true">
	<cfset var found = ormExecuteQuery("FROM Booking WHERE BookingId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.bookingId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif not arrayLen(found)>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfset found[1].setNotes(left(trim(replace(arguments.notes, chr(13), "", "all")), 2000))>
		<cfset entitySave(found[1])>
	</cftransaction>
	<cfreturn true>
</cffunction>

<cffunction name="canChange" access="public" returntype="boolean" output="false"
		hint="Whether the visitor can still cancel or move a booking: it is confirmed or waiting for approval, and hasn't started.">
	<cfargument name="booking" type="struct" required="true">
	<cfreturn listFind("confirmed,pending", arguments.booking.status) and arguments.booking.startLocal gt dateTimeFormat(application.blog.blogNow(), "yyyy-mm-dd HH:nn")>
</cffunction>

<cffunction name="rescheduleBooking" access="public" returntype="struct" output="false"
		hint="Moves a booking to another free time of the same type and way to meet. The caller holds the bookings lock. Returns { success, message }.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfargument name="startLocal" type="string" required="true">
	<cfset var result = { success: false, message: "" }>
	<cfset var b = getBooking(bookingId = arguments.bookingId)>
	<cfset var slot = "">
	<cfset var found = "">
	<cfset var entity = "">
	<cfset var startMinutes = 0>
	<cfif structIsEmpty(b) or structIsEmpty(b.bookingType) or not canChange(b)>
		<cfset result.message = "This booking can't be changed any more.">
		<cfreturn result>
	</cfif>
	<cfif not reFind("^\d{4}-\d{2}-\d{2} ([01]\d|2[0-3]):[0-5]\d$", arguments.startLocal)>
		<cfset result.message = "Please choose a time again.">
		<cfreturn result>
	</cfif>
	<cfloop array="#getSlots(b.bookingType, b.locationOptionId, left(arguments.startLocal, 10), left(arguments.startLocal, 10), b.bookingId)#" index="slot">
		<cfif slot.local eq arguments.startLocal><cfset found = slot><cfbreak></cfif>
	</cfloop>
	<cfif not isStruct(found) or found.spotsLeft lt b.partySize>
		<cfset result.message = "Sorry, that time was just taken. Please choose another.">
		<cfreturn result>
	</cfif>
	<cfset startMinutes = timeToMinutes(right(arguments.startLocal, 5))>
	<cftransaction>
		<cfset entity = entityLoadByPK("Booking", b.bookingId)>
		<cfset entity.setStartLocal(arguments.startLocal)>
		<cfset entity.setEndLocal(left(arguments.startLocal, 10) & " " & minutesToTime(min(startMinutes + b.bookingType.durationMinutes, 1439)))>
		<cfset entity.setStartUtc(found.utc)>
		<cfset entity.setTimeZone(application.blog.getBlogTimeZoneId())>
		<cfset entity.setReminderSent(false)>
		<cfset entity.setDate(now())>
		<cfset entitySave(entity)>
	</cftransaction>
	<cfset result.success = true>
	<cfreturn result>
</cffunction>

<!--- ********************************************************************************************************************
	Emails (2026-10-14). The visitor sees times in their own time zone (the one they booked in), the owner in the blog's.
********************************************************************************************************************* --->

<cffunction name="sendBookingEmails" access="public" returntype="void" output="false"
		hint="Sends the emails for something that happened to a booking. event: booked, approved, cancelledByVisitor, cancelledByOwner, rescheduled or reminder. Mail errors are logged, never shown to the visitor.">
	<cfargument name="bookingId" type="numeric" required="true">
	<cfargument name="event" type="string" required="true">
	<cfargument name="ownerMessage" type="string" required="false" default="" hint="A note from the owner to the visitor, eg. why it was cancelled.">
	<cfset var b = getBooking(bookingId = arguments.bookingId)>
	<cfset var ownerAddress = application.BlogDbObj.getBlogEmail()>
	<cfset var blogTitle = application.BlogDbObj.getBlogTitle()>
	<cfset var typeName = "">
	<cfset var visitorSubject = "">
	<cfset var visitorIntro = "">
	<cfset var ownerSubject = "">
	<cfset var ownerIntro = "">
	<cfset var showManageLink = false>
	<cfif structIsEmpty(b)>
		<cfreturn>
	</cfif>
	<cfset typeName = structIsEmpty(b.bookingType) ? "Booking" : b.bookingType.name>
	<cfswitch expression="#arguments.event#">
		<cfcase value="booked">
			<cfif b.status eq "pending">
				<cfset visitorSubject = "Booking request received: " & typeName>
				<cfset visitorIntro = "Thank you - your request is in, and the time is held for you. You'll get another email once it's confirmed.">
				<cfset ownerSubject = "Booking request to approve: " & typeName & " with " & b.name>
				<cfset ownerIntro = "A new booking is waiting for your approval. Approve or cancel it under Bookings in the admin site.">
			<cfelse>
				<cfset visitorSubject = "Booking confirmed: " & typeName>
				<cfset visitorIntro = "You're booked. Here are the details.">
				<cfset ownerSubject = "New booking: " & typeName & " with " & b.name>
				<cfset ownerIntro = "You have a new booking.">
			</cfif>
			<cfset showManageLink = true>
		</cfcase>
		<cfcase value="approved">
			<cfset visitorSubject = "Booking confirmed: " & typeName>
			<cfset visitorIntro = "Good news - your booking is confirmed.">
			<cfset showManageLink = true>
		</cfcase>
		<cfcase value="cancelledByVisitor">
			<cfset visitorSubject = "Booking cancelled: " & typeName>
			<cfset visitorIntro = "Your booking is cancelled. You're welcome to book another time.">
			<cfset ownerSubject = "Booking cancelled: " & typeName & " with " & b.name>
			<cfset ownerIntro = b.name & " cancelled this booking. The time is free again.">
		</cfcase>
		<cfcase value="cancelledByOwner">
			<cfset visitorSubject = "Booking cancelled: " & typeName>
			<cfset visitorIntro = "Unfortunately this booking has been cancelled.">
		</cfcase>
		<cfcase value="rescheduled">
			<cfset visitorSubject = "Booking moved: " & typeName>
			<cfset visitorIntro = "Your booking has been moved to the new time below.">
			<cfset ownerSubject = "Booking moved: " & typeName & " with " & b.name>
			<cfset ownerIntro = b.name & " moved this booking to the time below.">
			<cfset showManageLink = true>
		</cfcase>
		<cfcase value="reminder">
			<cfset visitorSubject = "Reminder: " & typeName>
			<cfset visitorIntro = "A reminder of your booking.">
			<cfset showManageLink = true>
		</cfcase>
		<cfdefaultcase>
			<cfreturn>
		</cfdefaultcase>
	</cfswitch>
	<!--- Each email on its own, so a problem with the visitor's address never stops the owner hearing about the booking. --->
	<cftry>
		<cfif len(visitorSubject) and isValid("email", b.email)>
			<cfset sendOneEmail(b.email, visitorSubject & " - " & blogTitle, visitorSubject, visitorIntro, bookingDetailsHtml(b, false, arguments.ownerMessage), showManageLink ? getManageUrl(b) : "", false)>
		</cfif>
		<cfcatch type="any">
			<cflog file="galaxieBlogErrors" type="error" text="Booking #arguments.bookingId# (#arguments.event#): the email to the visitor could not be sent: #cfcatch.message#">
		</cfcatch>
	</cftry>
	<cftry>
		<cfif len(ownerSubject) and isValid("email", ownerAddress)>
			<cfset sendOneEmail(ownerAddress, ownerSubject, ownerSubject, ownerIntro, bookingDetailsHtml(b, true, ""), "", true)>
		</cfif>
		<cfcatch type="any">
			<cflog file="galaxieBlogErrors" type="error" text="Booking #arguments.bookingId# (#arguments.event#): the email to the owner could not be sent: #cfcatch.message#">
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="sendOneEmail" access="private" returntype="void" output="false">
	<cfargument name="to" type="string" required="true">
	<cfargument name="subject" type="string" required="true">
	<cfargument name="title" type="string" required="true">
	<cfargument name="intro" type="string" required="true">
	<cfargument name="detailsHtml" type="string" required="true">
	<cfargument name="manageUrl" type="string" required="true">
	<cfargument name="toOwner" type="boolean" required="true">
	<cfset var renderer = createObject("component", application.rendererComponentPath)>
	<cfset var utils = createObject("component", application.utilsComponentPath)>
	<cfset var emailBody = renderer.renderEmail(
		email = arguments.to,
		emailTitle = arguments.title,
		emailDesc = arguments.intro,
		emailBody = arguments.detailsHtml,
		callToActionText = len(arguments.manageUrl) ? "Cancel or change this booking" : "",
		callToActionLink = arguments.manageUrl
	)>
	<!--- Not copied to the blog's CC address: a visitor's email is theirs, and the owner gets their own notice. --->
	<cfset utils.mail(to = arguments.to, subject = arguments.subject, body = emailBody, cc = "")>
</cffunction>

<cffunction name="getManageUrl" access="public" returntype="string" output="false"
		hint="The visitor's private link to their booking, where they can cancel or move it.">
	<cfargument name="booking" type="struct" required="true">
	<cfreturn application.blogHostUrl & "/?manageBooking=" & arguments.booking.manageToken>
</cffunction>

<cffunction name="bookingDetailsHtml" access="public" returntype="string" output="false"
		hint="The details of a booking as HTML for an email or the admin: what, when, where (with the location's details for the visitor), and for the owner the client's details and answers. Every value is encoded here.">
	<cfargument name="booking" type="struct" required="true">
	<cfargument name="forOwner" type="boolean" required="true">
	<cfargument name="message" type="string" required="false" default="">
	<cfset var b = arguments.booking>
	<cfset var zone = arguments.forOwner or not len(b.visitorTimeZone) ? b.timeZone : b.visitorTimeZone>
	<cfset var html = "">
	<cfset var answer = "">
	<cfset var statusText = { "pending": "Waiting for approval", "confirmed": "Confirmed", "cancelled": "Cancelled", "completed": "Completed", "noShow": "No-show" }>
	<cfif len(trim(arguments.message))>
		<cfset html = html & "<p>" & encodeLines(arguments.message) & "</p>">
	</cfif>
	<cfset html = html & '<table cellpadding="5" cellspacing="5" border="0" align="left">'>
	<cfset html = html & detailRow("What", structIsEmpty(b.bookingType) ? "Booking" : b.bookingType.name & " (" & b.bookingType.durationMinutes & " minutes)")>
	<cfset html = html & detailRow("When", formatInZone(b.startUtc, zone))>
	<cfif arguments.forOwner and len(b.visitorTimeZone) and b.visitorTimeZone neq b.timeZone>
		<cfset html = html & detailRow("Their time", formatInZone(b.startUtc, b.visitorTimeZone))>
	</cfif>
	<cfset html = html & detailRow("Where", structIsEmpty(b.location) ? "" : b.location.label)>
	<cfif b.partySize gt 1><cfset html = html & detailRow("People", b.partySize)></cfif>
	<cfif b.amountTotal gt 0><cfset html = html & detailRow("Price", numberFormat(b.amountTotal, "0.00"))></cfif>
	<cfset html = html & detailRow("Status", structKeyExists(statusText, b.status) ? statusText[b.status] : b.status)>
	<cfif arguments.forOwner>
		<cfset html = html & detailRow("Name", b.name)>
		<cfset html = html & detailRow("Email", b.email)>
		<cfif len(b.phone)><cfset html = html & detailRow("Phone", b.phone)></cfif>
		<cfloop array="#b.answers#" index="answer">
			<cfset html = html & detailRow(answer.label, answer.value)>
		</cfloop>
	</cfif>
	<cfset html = html & "</table>">
	<!--- The visitor gets the details for their way to meet: the address and a map link, the meeting link, or the phone arrangement. --->
	<cfif not arguments.forOwner and not structIsEmpty(b.location) and listFind("confirmed,pending", b.status)>
		<cfset html = html & '<div style="clear: both;"></div>' & application.locations.getDetailsHtml(b.location)>
	</cfif>
	<cfreturn html>
</cffunction>

<cffunction name="detailRow" access="private" returntype="string" output="false">
	<cfargument name="label" type="string" required="true">
	<cfargument name="value" type="string" required="true">
	<cfreturn '<tr><td align="right" valign="top">' & encodeForHtml(arguments.label) & ':</td><td align="left">' & encodeLines(arguments.value) & '</td></tr>'>
</cffunction>

<cffunction name="formatInZone" access="public" returntype="string" output="false"
		hint="A UTC instant (ISO 8601) as eg. 'Tuesday, October 20, 2026 at 10:00 AM (America/Los_Angeles)'.">
	<cfargument name="utc" type="string" required="true">
	<cfargument name="zoneId" type="string" required="true">
	<cfset var formatter = "">
	<cftry>
		<cfset formatter = createObject("java", "java.time.format.DateTimeFormatter").ofPattern("EEEE, MMMM d, yyyy 'at' h:mm a", createObject("java", "java.util.Locale").ENGLISH)>
		<cfreturn createObject("java", "java.time.Instant").parse(arguments.utc).atZone(createObject("java", "java.time.ZoneId").of(arguments.zoneId)).format(formatter) & " (" & replace(arguments.zoneId, "_", " ", "all") & ")">
		<cfcatch type="any">
			<cfreturn arguments.utc>
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="encodeLines" access="private" returntype="string" output="false"
		hint="Encodes text for HTML and keeps its line breaks (Adobe ColdFusion's encodeForHtml makes a newline &##xa;, Lucee's leaves it).">
	<cfargument name="text" type="string" required="true">
	<cfreturn replace(replaceNoCase(encodeForHtml(replace(arguments.text, chr(13), "", "all")), "&##xa;", chr(10), "all"), chr(10), "<br/>", "all")>
</cffunction>

<!--- ********************************************************************************************************************
	Reminders (2026-10-14): one recurring task per blog (cfschedule, like scheduled posts) calls
	/common/services/bookingReminders.cfm every 15 minutes, which sends the reminders that are due.
********************************************************************************************************************* --->

<cffunction name="sendDueReminders" access="public" returntype="numeric" output="false"
		hint="Emails a reminder for each confirmed booking whose reminder time (its type's ReminderHours before the start) has come and hasn't passed the start. Returns how many were sent.">
	<cfset var sent = 0>
	<cfset var nowInstant = createObject("java", "java.time.Instant").now()>
	<cfset var rows = queryExecute("
		SELECT b.BookingId, b.StartUtc, t.ReminderHours FROM Booking b INNER JOIN BookingType t ON t.BookingTypeId = b.BookingTypeRef
		WHERE b.BlogRef = :blogId AND b.Status = 'confirmed' AND (b.ReminderSent IS NULL OR b.ReminderSent = 0) AND t.ReminderHours > 0
	", { blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } })>
	<cfset var startInstant = "">
	<cfset var entity = "">
	<cfloop query="rows">
		<cftry>
			<cfset startInstant = createObject("java", "java.time.Instant").parse(rows.StartUtc)>
			<cfif startInstant.isAfter(nowInstant) and not startInstant.minusSeconds(javacast("long", rows.ReminderHours * 3600)).isAfter(nowInstant)>
				<!--- Marked first, so a slow mail server can't make the next run send it twice. --->
				<cftransaction>
					<cfset entity = entityLoadByPK("Booking", rows.BookingId)>
					<cfset entity.setReminderSent(true)>
					<cfset entitySave(entity)>
				</cftransaction>
				<cfset sendBookingEmails(rows.BookingId, "reminder")>
				<cfset sent = sent + 1>
			</cfif>
			<cfcatch type="any">
				<cflog file="galaxieBlogErrors" type="error" text="Booking reminder #rows.BookingId#: #cfcatch.message#">
			</cfcatch>
		</cftry>
	</cfloop>
	<cfreturn sent>
</cffunction>

<cffunction name="getReminderTaskName" access="public" returntype="string" output="false">
	<cfreturn "galaxieBookingReminders" & application.BlogDbObj.getBlogId()>
</cffunction>

<cffunction name="ensureReminderTask" access="public" returntype="void" output="false"
		hint="Creates the recurring reminder task if this server doesn't have it yet. Called when booking types are saved and bookings are made; costs one task listing.">
	<cfset var tasks = "">
	<cfset var name = getReminderTaskName()>
	<cftry>
		<cfschedule action="list" result="tasks">
		<cfquery name="local.existing" dbtype="query">
			SELECT Task FROM tasks WHERE Task = <cfqueryparam value="#name#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<cfif not local.existing.recordCount>
			<cfschedule action="update"
				task="#name#"
				operation="HTTPRequest"
				startDate="#dateFormat(now())#"
				startTime="#timeFormat(now())#"
				url="#application.blogHostUrl#/common/services/bookingReminders.cfm"
				interval="900">
		</cfif>
		<cfcatch type="any">
			<cflog file="galaxieBlogErrors" type="error" text="The booking reminder task could not be created: #cfcatch.message#">
		</cfcatch>
	</cftry>
</cffunction>

<cffunction name="toUtc" access="public" returntype="string" output="false"
		hint="A wall-clock time on a date in a time zone, as an ISO 8601 UTC instant (java.time handles daylight saving; a time skipped by the clocks going forward moves to the next valid time).">
	<cfargument name="dateText" type="string" required="true">
	<cfargument name="minutes" type="numeric" required="true">
	<cfargument name="zoneId" type="string" required="true">
	<cfset var localDateTime = createObject("java", "java.time.LocalDateTime").parse(arguments.dateText & "T" & minutesToTime(arguments.minutes))>
	<cfreturn localDateTime.atZone(createObject("java", "java.time.ZoneId").of(arguments.zoneId)).toInstant().toString()>
</cffunction>

<cffunction name="timeToMinutes" access="private" returntype="numeric" output="false">
	<cfargument name="value" type="string" required="true" hint="HH:mm">
	<cfif not reFind("^\d{1,2}:\d{2}$", arguments.value)><cfreturn 0></cfif>
	<cfreturn val(listFirst(arguments.value, ":")) * 60 + val(listLast(arguments.value, ":"))>
</cffunction>

<cffunction name="minutesToTime" access="private" returntype="string" output="false">
	<cfargument name="minutes" type="numeric" required="true">
	<cfreturn numberFormat(int(arguments.minutes / 60), "00") & ":" & numberFormat(arguments.minutes mod 60, "00")>
</cffunction>

<cffunction name="parseDate" access="private" returntype="date" output="false" hint="'yyyy-mm-dd' as a date, without any time zone.">
	<cfargument name="value" type="string" required="true">
	<cfreturn createDate(val(listGetAt(arguments.value, 1, "-")), val(listGetAt(arguments.value, 2, "-")), val(listGetAt(arguments.value, 3, "-")))>
</cffunction>

<cffunction name="isValidDate" access="private" returntype="boolean" output="false">
	<cfargument name="value" type="string" required="true">
	<cfreturn reFind("^\d{4}-\d{2}-\d{2}$", arguments.value) and isDate(arguments.value)>
</cffunction>

<!--- ********************************************************************************************************************
	Helpers
********************************************************************************************************************* --->

<cffunction name="makeUniqueAlias" access="private" returntype="string" output="false"
		hint="A URL-safe alias from the name, unique among this blog's booking types (eg. consultation, consultation-2).">
	<cfargument name="name" type="string" required="true">
	<cfset var base = left(reReplace(reReplace(lCase(trim(arguments.name)), "[^a-z0-9]+", "-", "all"), "^-+|-+$", "", "all"), 90)>
	<cfset var alias = "">
	<cfset var suffix = 1>
	<cfif not len(base)><cfset base = "booking"></cfif>
	<cfset alias = base>
	<cfloop condition="aliasIsTaken(alias)">
		<cfset suffix = suffix + 1>
		<cfset alias = base & "-" & suffix>
	</cfloop>
	<cfreturn alias>
</cffunction>

<cffunction name="aliasIsTaken" access="private" returntype="boolean" output="false">
	<cfargument name="alias" type="string" required="true">
	<cfreturn arrayLen(ormExecuteQuery("FROM BookingType WHERE Alias = :alias AND BlogRef = :blogId", { alias = arguments.alias, blogId = javacast("int", application.BlogDbObj.getBlogId()) })) gt 0>
</cffunction>

<cffunction name="isTime24" access="private" returntype="boolean" output="false" hint="HH:mm, 00:00 to 24:00.">
	<cfargument name="value" type="string" required="true">
	<cfreturn reFind("^([01]\d|2[0-3]):[0-5]\d$", arguments.value) or arguments.value eq "24:00">
</cffunction>

<cffunction name="wholeNumber" access="private" returntype="numeric" output="false"
		hint="A whole number of at least 0 from the data, or the default.">
	<cfargument name="data" type="struct" required="true">
	<cfargument name="key" type="string" required="true">
	<cfargument name="defaultValue" type="numeric" required="true">
	<cfif structKeyExists(arguments.data, arguments.key) and isNumeric(arguments.data[arguments.key]) and arguments.data[arguments.key] gte 0>
		<cfreturn int(arguments.data[arguments.key])>
	</cfif>
	<cfreturn arguments.defaultValue>
</cffunction>

<cffunction name="intOr" access="private" returntype="numeric" output="false">
	<cfargument name="value" required="false">
	<cfargument name="defaultValue" type="numeric" required="true">
	<cfif isNull(arguments.value) or not isNumeric(arguments.value)>
		<cfreturn arguments.defaultValue>
	</cfif>
	<cfreturn int(arguments.value)>
</cffunction>

<cffunction name="valueOrEmpty" access="private" returntype="string" output="false">
	<cfargument name="value" required="false">
	<cfif isNull(arguments.value)>
		<cfreturn "">
	</cfif>
	<cfreturn arguments.value>
</cffunction>

<cffunction name="isTrue" access="private" returntype="boolean" output="false">
	<cfargument name="value" required="false">
	<cfargument name="defaultValue" type="boolean" required="false" default="false">
	<cfif isNull(arguments.value) or not isBoolean(arguments.value)>
		<cfreturn arguments.defaultValue>
	</cfif>
	<cfreturn arguments.value>
</cffunction>

</cfcomponent>
