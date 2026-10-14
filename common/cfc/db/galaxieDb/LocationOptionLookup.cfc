<cfcomponent displayName="LocationOptionLookup" persistent="true" table="LocationOptionLookup" output="no" hint="Which LocationOptions a booking type (and later an event, by PostRef) offers (2026-10-14). Managed by common/cfc/Bookings.cfc.">

	<cfproperty name="LocationOptionLookupId" fieldtype="id" generator="native" setter="false">
	<!--- Plain numbers, not ORM relationships, so a delete never cascades. --->
	<cfproperty name="LocationOptionRef" ormtype="int" default="0">
	<cfproperty name="BookingTypeRef" ormtype="int" default="0">
	<!--- For events later (an event is a post); 0 for a booking type. --->
	<cfproperty name="PostRef" ormtype="int" default="0">
	<cfproperty name="SortOrder" ormtype="int" default="0">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
