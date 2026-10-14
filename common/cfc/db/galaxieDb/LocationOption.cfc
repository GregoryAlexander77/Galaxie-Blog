<cfcomponent displayName="LocationOption" persistent="true" table="LocationOption" output="no" hint="Where a booking (and later an event) happens - in person, online or by phone (2026-10-14). A booking type can offer several, and the visitor chooses one; the confirmation, email and reminder then show only what applies to that choice. Managed by common/cfc/Locations.cfc. See doc/aiDraftArticles/eventsAndFormsDesign.cfm, 'A shared Location'.">

	<cfproperty name="LocationOptionId" fieldtype="id" generator="native" setter="false">
	<!--- Plain numbers, not ORM relationships (as in WebForm.cfc): deleting a location must never cascade to the Blog. --->
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<!--- inPerson, online or phone --->
	<cfproperty name="Kind" ormtype="string" length="20" default="inPerson">
	<!--- What the visitor picks from, eg. "In person (Seattle office)", "Online (Zoom)" or "Phone". --->
	<cfproperty name="Label" ormtype="string" length="125" default="">
	<!--- In person --->
	<cfproperty name="VenueName" ormtype="string" length="255" default="">
	<cfproperty name="Address" ormtype="string" length="1000" default="">
	<!--- Online. OnlineLinkMode: fixed (the link below is sent with the confirmation) or later (the owner emails a link before the meeting). --->
	<cfproperty name="OnlineLinkMode" ormtype="string" length="20" default="fixed">
	<cfproperty name="OnlineUrl" ormtype="string" length="1000" default="">
	<!--- Phone. PhoneDirection: weCall (the visitor gives a number when booking) or youCall (the visitor calls the number below). --->
	<cfproperty name="PhoneDirection" ormtype="string" length="20" default="weCall">
	<cfproperty name="PhoneNumber" ormtype="string" length="50" default="">
	<!--- Directions, parking, how to join, what to have ready - shown with the confirmation for this way to meet. --->
	<cfproperty name="Instructions" ormtype="string" length="2000" default="">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="SortOrder" ormtype="int" default="0" hint="Lower numbers come first.">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
