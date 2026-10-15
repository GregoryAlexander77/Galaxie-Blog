<cfcomponent displayName="BlogEvent" persistent="true" table="BlogEvent" output="no" hint="An event (2026-10-15): a blog post with event details - one event per post. (Not called Event: EVENT is a keyword in MariaDB and a risky name for Hibernate.) Times are kept as the event's own wall-clock time in its time zone, plus the UTC instant for sorting and calendar files. Where it happens is one or more LocationOptions through LocationOptionLookup.PostRef. See common/cfc/Events.cfc and doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 2.">

	<cfproperty name="EventId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<!--- The post this event belongs to (plain number, not an ORM relationship, so deleting never cascades). --->
	<cfproperty name="PostRef" ormtype="int" default="0">
	<!--- 'yyyy-mm-dd HH:mm' in the event's time zone. An all-day event runs from 00:00 on the first day to 23:59 on the last. --->
	<cfproperty name="StartLocal" ormtype="string" length="16" default="">
	<cfproperty name="EndLocal" ormtype="string" length="16" default="">
	<!--- An IANA time zone name (eg. America/Los_Angeles), never a fixed number of hours. --->
	<cfproperty name="TimeZone" ormtype="string" length="64" default="">
	<!--- ISO 8601 UTC instants worked out from the local times, for sorting, 'has it ended' and calendar files. --->
	<cfproperty name="StartUtc" ormtype="string" length="25" default="">
	<cfproperty name="EndUtc" ormtype="string" length="25" default="">
	<cfproperty name="AllDay" ormtype="boolean" default="false">
	<!--- scheduled, postponed or cancelled. --->
	<cfproperty name="Status" ormtype="string" length="20" default="scheduled">
	<cfproperty name="OrganizerName" ormtype="string" length="125" default="">
	<cfproperty name="OrganizerUrl" ormtype="string" length="500" default="">
	<!--- What it costs, as the owner writes it (eg. Free, $20, $15 students). Paid RSVPs use their own price. --->
	<cfproperty name="Cost" ormtype="string" length="125" default="">
	<!--- A page that sells tickets or takes registrations elsewhere. --->
	<cfproperty name="TicketUrl" ormtype="string" length="500" default="">
	<!--- RSVP (next step): the form used as the RSVP (0 = none), capacity in people (0 = no limit), party size, and when sign-ups close. --->
	<cfproperty name="WebFormRef" ormtype="int" default="0">
	<cfproperty name="Capacity" ormtype="int" default="0">
	<cfproperty name="AskPartySize" ormtype="boolean" default="false">
	<cfproperty name="MaxPartySize" ormtype="int" default="1">
	<cfproperty name="RsvpClosesLocal" ormtype="string" length="16" default="">
	<!--- Paid sign-ups (2026-10-15): the price per person, paid online through Stripe when signing up (0 = free), and how many hours before the start a cancelled place is still refunded (0 = no refunds). --->
	<cfproperty name="Price" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="RefundHours" ormtype="int" default="24">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Updated" ormtype="timestamp">

</cfcomponent>
