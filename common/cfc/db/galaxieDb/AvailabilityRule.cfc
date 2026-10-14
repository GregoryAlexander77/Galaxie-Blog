<cfcomponent displayName="AvailabilityRule" persistent="true" table="AvailabilityRule" output="no" hint="One weekly time range when the blog owner takes bookings, eg. Tuesday 09:00-12:00 (2026-10-14). Times are wall-clock times in the blog's time zone (Blog Settings), so daylight saving changes never move them. LocationOptionRef 0 = the general hours; a location with its own rules uses those instead. BookingTypeRef is kept for per-type hours later (0 = every type). Managed by common/cfc/Bookings.cfc.">

	<cfproperty name="AvailabilityRuleId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="BookingTypeRef" ormtype="int" default="0">
	<cfproperty name="LocationOptionRef" ormtype="int" default="0">
	<!--- 1 = Sunday ... 7 = Saturday, as ColdFusion's dayOfWeek(). --->
	<cfproperty name="DayOfWeek" ormtype="int" default="2">
	<!--- "HH:mm", 24-hour. --->
	<cfproperty name="StartTime" ormtype="string" length="5" default="09:00">
	<cfproperty name="EndTime" ormtype="string" length="5" default="17:00">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
