<cfcomponent displayName="Locations" output="false" hint="Where bookings (and later events) happen: in person, online or by phone (2026-10-14). The blog owner sets these up once under Bookings > Locations, and a booking type offers one or more of them; when it offers several, the visitor picks one. Created once as application.locations in Application.cfc. The entity is LocationOption (common/cfc/db/galaxieDb). See doc/aiDraftArticles/eventsAndFormsDesign.cfm, 'A shared Location'.">

<!---
	Every write is inside a cftransaction: the application sets ormsettings.flushAtRequestEnd = false, so an entity change made
	outside a transaction (without ormFlush) would never reach the database.
--->

<cffunction name="init" access="public" returntype="any" output="false">
	<!--- The kinds, in the order the editor offers them. --->
	<cfset variables.kinds = [
		{ kind: "inPerson", label: "In person" },
		{ kind: "online", label: "Online (video call)" },
		{ kind: "phone", label: "Phone" }
	]>
	<cfset variables.kindList = "inPerson,online,phone">
	<cfreturn this>
</cffunction>

<cffunction name="getKinds" access="public" returntype="array" output="false">
	<cfreturn duplicate(variables.kinds)>
</cffunction>

<!--- ********************************************************************************************************************
	Reading
********************************************************************************************************************* --->

<cffunction name="getLocations" access="public" returntype="array" output="false"
		hint="This blog's locations in their sort order, each as getLocation() returns it.">
	<cfargument name="activeOnly" type="boolean" required="false" default="false">
	<cfset var locations = []>
	<cfset var entity = "">
	<cfset var found = ormExecuteQuery("FROM LocationOption WHERE BlogRef = :blogId ORDER BY SortOrder, LocationOptionId", { blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfloop array="#found#" index="entity">
		<cfif not arguments.activeOnly or isTrue(entity.getActive(), true)>
			<cfset arrayAppend(locations, toStruct(entity))>
		</cfif>
	</cfloop>
	<cfreturn locations>
</cffunction>

<cffunction name="getLocation" access="public" returntype="struct" output="false"
		hint="One location of this blog, or an empty struct when there is no such location.">
	<cfargument name="locationOptionId" required="true">
	<cfset var found = []>
	<cfif isNumeric(arguments.locationOptionId) and arguments.locationOptionId gt 0>
		<cfset found = ormExecuteQuery("FROM LocationOption WHERE LocationOptionId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.locationOptionId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	</cfif>
	<cfreturn arrayLen(found) ? toStruct(found[1]) : {}>
</cffunction>

<cffunction name="toStruct" access="private" returntype="struct" output="false">
	<cfargument name="entity" required="true">
	<cfset var location = {
		locationOptionId: arguments.entity.getLocationOptionId(),
		kind: valueOrEmpty(arguments.entity.getKind()),
		label: valueOrEmpty(arguments.entity.getLabel()),
		venueName: valueOrEmpty(arguments.entity.getVenueName()),
		address: valueOrEmpty(arguments.entity.getAddress()),
		onlineLinkMode: valueOrEmpty(arguments.entity.getOnlineLinkMode()),
		onlineUrl: valueOrEmpty(arguments.entity.getOnlineUrl()),
		phoneDirection: valueOrEmpty(arguments.entity.getPhoneDirection()),
		phoneNumber: valueOrEmpty(arguments.entity.getPhoneNumber()),
		instructions: valueOrEmpty(arguments.entity.getInstructions()),
		active: isTrue(arguments.entity.getActive(), true),
		sortOrder: val(valueOrEmpty(arguments.entity.getSortOrder()))
	}>
	<cfif not listFind(variables.kindList, location.kind)><cfset location.kind = "inPerson"></cfif>
	<cfif location.onlineLinkMode neq "later"><cfset location.onlineLinkMode = "fixed"></cfif>
	<cfif location.phoneDirection neq "youCall"><cfset location.phoneDirection = "weCall"></cfif>
	<cfreturn location>
</cffunction>

<!--- ********************************************************************************************************************
	Saving (admin)
********************************************************************************************************************* --->

<cffunction name="saveLocation" access="public" returntype="struct" output="false"
		hint="Creates or updates a location. Returns { success, locationOptionId, errors[] }; nothing is saved when something is wrong.">
	<cfargument name="data" type="struct" required="true" hint="locationOptionId (0 = new), kind, label, venueName, address, onlineLinkMode, onlineUrl, phoneDirection, phoneNumber, instructions, active, sortOrder.">
	<cfset var result = { success: false, locationOptionId: 0, errors: [] }>
	<cfset var d = arguments.data>
	<cfset var kind = structKeyExists(d, "kind") and listFind(variables.kindList, d.kind) ? d.kind : "">
	<cfset var label = left(trim(structKeyExists(d, "label") ? d.label : ""), 125)>
	<cfset var address = left(trim(replace(structKeyExists(d, "address") ? d.address : "", chr(13), "", "all")), 1000)>
	<cfset var onlineLinkMode = structKeyExists(d, "onlineLinkMode") and d.onlineLinkMode eq "later" ? "later" : "fixed">
	<cfset var onlineUrl = left(trim(structKeyExists(d, "onlineUrl") ? d.onlineUrl : ""), 1000)>
	<cfset var phoneDirection = structKeyExists(d, "phoneDirection") and d.phoneDirection eq "youCall" ? "youCall" : "weCall">
	<cfset var phoneNumber = left(trim(structKeyExists(d, "phoneNumber") ? d.phoneNumber : ""), 50)>
	<cfset var isNew = not (structKeyExists(d, "locationOptionId") and isNumeric(d.locationOptionId) and d.locationOptionId gt 0)>
	<cfset var entity = "">
	<cfset var existing = []>

	<!--- Check everything first. --->
	<cfif not len(kind)>
		<cfset arrayAppend(result.errors, "Choose how people meet: in person, online or phone.")>
	</cfif>
	<cfif not len(label)>
		<cfset arrayAppend(result.errors, "The location needs a name that visitors choose from, eg. ""In person (Seattle office)"".")>
	</cfif>
	<cfif kind eq "inPerson" and not len(address)>
		<cfset arrayAppend(result.errors, "An in-person location needs an address.")>
	</cfif>
	<cfif kind eq "online" and onlineLinkMode eq "fixed">
		<cfif not len(onlineUrl)>
			<cfset arrayAppend(result.errors, "Enter the meeting link, or choose to email the link before each meeting.")>
		<cfelseif not reFindNoCase("^https?://[^\s]+$", onlineUrl)>
			<cfset arrayAppend(result.errors, "The meeting link must start with http:// or https://.")>
		</cfif>
	</cfif>
	<cfif kind eq "phone" and phoneDirection eq "youCall">
		<cfif not len(phoneNumber)>
			<cfset arrayAppend(result.errors, "Enter the number visitors should call.")>
		<cfelseif not reFind("^[0-9+().\-\s]{5,50}$", phoneNumber)>
			<cfset arrayAppend(result.errors, "The phone number can only have digits, spaces and + ( ) . -")>
		</cfif>
	</cfif>
	<cfif not isNew>
		<cfset existing = ormExecuteQuery("FROM LocationOption WHERE LocationOptionId = :id AND BlogRef = :blogId", { id = javacast("int", d.locationOptionId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
		<cfif not arrayLen(existing)>
			<cfset arrayAppend(result.errors, "That location no longer exists.")>
		</cfif>
	</cfif>
	<cfif arrayLen(result.errors)>
		<cfreturn result>
	</cfif>

	<cftransaction>
		<cfif isNew>
			<cfset entity = entityNew("LocationOption")>
			<cfset entity.setBlogRef(application.BlogDbObj.getBlogId())>
			<cfset entity.setCreated(now())>
		<cfelse>
			<cfset entity = existing[1]>
		</cfif>
		<cfset entity.setKind(kind)>
		<cfset entity.setLabel(label)>
		<!--- Only the details for the chosen kind are kept, so switching kind never leaves an old address or link behind. --->
		<cfset entity.setVenueName(kind eq "inPerson" ? left(trim(structKeyExists(d, "venueName") ? d.venueName : ""), 255) : "")>
		<cfset entity.setAddress(kind eq "inPerson" ? address : "")>
		<cfset entity.setOnlineLinkMode(onlineLinkMode)>
		<cfset entity.setOnlineUrl(kind eq "online" and onlineLinkMode eq "fixed" ? onlineUrl : "")>
		<cfset entity.setPhoneDirection(phoneDirection)>
		<cfset entity.setPhoneNumber(kind eq "phone" and phoneDirection eq "youCall" ? phoneNumber : "")>
		<cfset entity.setInstructions(left(trim(replace(structKeyExists(d, "instructions") ? d.instructions : "", chr(13), "", "all")), 2000))>
		<cfset entity.setActive(isTrue(structKeyExists(d, "active") ? d.active : true, true))>
		<cfset entity.setSortOrder(structKeyExists(d, "sortOrder") and isNumeric(d.sortOrder) ? int(d.sortOrder) : 0)>
		<cfset entity.setDate(now())>
		<cfset entitySave(entity)>
	</cftransaction>

	<cfset result.success = true>
	<cfset result.locationOptionId = entity.getLocationOptionId()>
	<cfreturn result>
</cffunction>

<cffunction name="deleteLocation" access="public" returntype="boolean" output="false"
		hint="Deletes a location of this blog. (Once booking types use locations, a location in use will be turned off instead - see the booking types step.)">
	<cfargument name="locationOptionId" type="numeric" required="true">
	<cfset var found = ormExecuteQuery("FROM LocationOption WHERE LocationOptionId = :id AND BlogRef = :blogId", { id = javacast("int", arguments.locationOptionId), blogId = javacast("int", application.BlogDbObj.getBlogId()) })>
	<cfif not arrayLen(found)>
		<cfreturn false>
	</cfif>
	<cftransaction>
		<cfset entityDelete(found[1])>
	</cftransaction>
	<cfreturn true>
</cffunction>

<!--- ********************************************************************************************************************
	What visitors see
********************************************************************************************************************* --->

<cffunction name="getMapUrl" access="public" returntype="string" output="false"
		hint="A link that opens the address in the visitor's map app (Google Maps' universal search link, which phones hand to their own map app).">
	<cfargument name="location" type="struct" required="true">
	<cfset var query = trim(arguments.location.venueName & " " & reReplace(arguments.location.address, "\s+", " ", "all"))>
	<cfif arguments.location.kind neq "inPerson" or not len(query)>
		<cfreturn "">
	</cfif>
	<cfreturn "https://www.google.com/maps/search/?api=1&query=" & encodeForUrl(query)>
</cffunction>

<cffunction name="getSummary" access="public" returntype="string" output="false"
		hint="One line of plain text about how and where people meet, for the admin list, eg. 'In person: 123 Main St, Seattle' or 'Online: link emailed before the meeting'.">
	<cfargument name="location" type="struct" required="true">
	<cfset var l = arguments.location>
	<cfswitch expression="#l.kind#">
		<cfcase value="online">
			<cfreturn "Online: " & (l.onlineLinkMode eq "later" ? "link emailed before the meeting" : l.onlineUrl)>
		</cfcase>
		<cfcase value="phone">
			<cfreturn "Phone: " & (l.phoneDirection eq "youCall" ? "the visitor calls " & l.phoneNumber : "you call the visitor")>
		</cfcase>
		<cfdefaultcase>
			<cfreturn "In person: " & trim((len(l.venueName) ? l.venueName & ", " : "") & reReplace(l.address, "\s*\n\s*", ", ", "all"))>
		</cfdefaultcase>
	</cfswitch>
</cffunction>

<cffunction name="getDetailsHtml" access="public" returntype="string" output="false"
		hint="The details for this way to meet, as HTML for a confirmation page or email: the address and a map link, the meeting link, or the phone arrangement, then the instructions. Every value is encoded here.">
	<cfargument name="location" type="struct" required="true">
	<cfset var l = arguments.location>
	<cfset var html = "">
	<cfset var mapUrl = getMapUrl(l)>
	<cfswitch expression="#l.kind#">
		<cfcase value="online">
			<cfif l.onlineLinkMode eq "later">
				<cfset html = "<p>Online. The meeting link will be emailed to you before the meeting.</p>">
			<cfelse>
				<cfset html = '<p>Online: <a href="' & encodeForHtmlAttribute(l.onlineUrl) & '">' & encodeForHtml(l.onlineUrl) & '</a></p>'>
			</cfif>
		</cfcase>
		<cfcase value="phone">
			<cfif l.phoneDirection eq "youCall">
				<cfset html = '<p>By phone: please call <a href="tel:' & encodeForHtmlAttribute(reReplace(l.phoneNumber, "[^0-9+]", "", "all")) & '">' & encodeForHtml(l.phoneNumber) & '</a> at the time of your booking.</p>'>
			<cfelse>
				<cfset html = "<p>By phone: we'll call you at the number you gave.</p>">
			</cfif>
		</cfcase>
		<cfdefaultcase>
			<cfset html = "<p>" & (len(l.venueName) ? "<b>" & encodeForHtml(l.venueName) & "</b><br/>" : "") & encodeLines(l.address) & "</p>">
			<cfif len(mapUrl)>
				<cfset html = html & '<p><a href="' & encodeForHtmlAttribute(mapUrl) & '">Open in maps</a></p>'>
			</cfif>
		</cfdefaultcase>
	</cfswitch>
	<cfif len(l.instructions)>
		<cfset html = html & "<p>" & encodeLines(l.instructions) & "</p>">
	</cfif>
	<cfreturn html>
</cffunction>

<!--- ********************************************************************************************************************
	Helpers
********************************************************************************************************************* --->

<cffunction name="encodeLines" access="private" returntype="string" output="false"
		hint="Encodes text for HTML and keeps its line breaks as <br/>. Adobe ColdFusion's encodeForHtml turns a newline into &##xa;, Lucee's leaves it as it is (2026-10-14), so both are handled.">
	<cfargument name="text" type="string" required="true">
	<cfreturn replace(replaceNoCase(encodeForHtml(replace(arguments.text, chr(13), "", "all")), "&##xa;", chr(10), "all"), chr(10), "<br/>", "all")>
</cffunction>

<cffunction name="valueOrEmpty" access="private" returntype="string" output="false"
		hint="A property value, or an empty string when it is NULL (rows from before a column existed).">
	<cfargument name="value" required="false">
	<cfif isNull(arguments.value)>
		<cfreturn "">
	</cfif>
	<cfreturn arguments.value>
</cffunction>

<cffunction name="isTrue" access="private" returntype="boolean" output="false"
		hint="A boolean property, with a default for NULL.">
	<cfargument name="value" required="false">
	<cfargument name="defaultValue" type="boolean" required="false" default="false">
	<cfif isNull(arguments.value) or not isBoolean(arguments.value)>
		<cfreturn arguments.defaultValue>
	</cfif>
	<cfreturn arguments.value>
</cffunction>

</cfcomponent>
