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
