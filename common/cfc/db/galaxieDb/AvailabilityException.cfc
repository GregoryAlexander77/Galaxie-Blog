<cfcomponent displayName="AvailabilityException" persistent="true" table="AvailabilityException" output="no" hint="A day off, or a day with different hours, eg. a holiday or an afternoon out (2026-10-14). LocationOptionRef 0 = every location. When Closed is false, the StartTime-EndTime range replaces that day's weekly hours. Managed by common/cfc/Bookings.cfc.">

	<cfproperty name="AvailabilityExceptionId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="BookingTypeRef" ormtype="int" default="0">
	<cfproperty name="LocationOptionRef" ormtype="int" default="0">
	<!--- The day, as "yyyy-mm-dd" in the blog's time zone (a string, so no server or database time zone can shift it). --->
	<cfproperty name="ExceptionDate" ormtype="string" length="10" default="">
	<cfproperty name="Closed" ormtype="boolean" default="true">
	<cfproperty name="StartTime" ormtype="string" length="5" default="">
	<cfproperty name="EndTime" ormtype="string" length="5" default="">
	<cfproperty name="Note" ormtype="string" length="255" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
