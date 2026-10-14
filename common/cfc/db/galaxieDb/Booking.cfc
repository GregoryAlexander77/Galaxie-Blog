<cfcomponent displayName="Booking" persistent="true" table="Booking" output="no" hint="A time a visitor booked with the blog owner (2026-10-14). Times are kept as wall-clock times in the blog's time zone (StartLocal, EndLocal, 'yyyy-mm-dd HH:mm'), which is what the owner's hours and every comparison use, so daylight saving changes never move a booking; StartUtc is the same moment for calendars and emails. The payment fields are here from the start (the Stripe step fills them). Managed by common/cfc/Bookings.cfc.">

	<cfproperty name="BookingId" fieldtype="id" generator="native" setter="false">
	<!--- Plain numbers, not ORM relationships (as in WebForm.cfc), so deleting a type or location never cascades to bookings. --->
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="BookingTypeRef" ormtype="int" default="0">
	<!--- The way to meet the visitor chose. --->
	<cfproperty name="LocationOptionRef" ormtype="int" default="0">
	<cfproperty name="StartLocal" ormtype="string" length="16" default="">
	<cfproperty name="EndLocal" ormtype="string" length="16" default="">
	<!--- The blog's time zone when it was booked, eg. America/Los_Angeles. --->
	<cfproperty name="TimeZone" ormtype="string" length="64" default="">
	<!--- ISO 8601 UTC, eg. 2026-10-20T17:00:00Z. --->
	<cfproperty name="StartUtc" ormtype="string" length="25" default="">
	<!--- The visitor's own time zone, to show times to them in their zone in emails. --->
	<cfproperty name="VisitorTimeZone" ormtype="string" length="64" default="">
	<!--- Copies of the type's buffers when booked, so later changes to the type don't move what this booking blocks. --->
	<cfproperty name="BufferBeforeMinutes" ormtype="int" default="0">
	<cfproperty name="BufferAfterMinutes" ormtype="int" default="0">
	<cfproperty name="PartySize" ormtype="int" default="1">
	<cfproperty name="Name" ormtype="string" length="255" default="">
	<cfproperty name="Email" ormtype="string" length="255" default="">
	<cfproperty name="Phone" ormtype="string" length="50" default="">
	<!--- The intake answers, a WebFormSubmission; 0 = none. --->
	<cfproperty name="WebFormSubmissionRef" ormtype="int" default="0">
	<!--- pending (waiting for the owner's approval, or later for payment), confirmed, cancelled, completed, noShow --->
	<cfproperty name="Status" ormtype="string" length="20" default="confirmed">
	<!--- Payments (the Stripe step): none, pending, depositPaid, paid, refunded, partlyRefunded, expired --->
	<cfproperty name="PaymentStatus" ormtype="string" length="20" default="none">
	<cfproperty name="PaymentChoice" ormtype="string" length="20" default="">
	<cfproperty name="AmountTotal" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="AmountPaid" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="BalanceDue" ormtype="big_decimal" precision="10" scale="2" default="0">
	<!--- A place held while paying expires at this time (the Stripe step). --->
	<cfproperty name="HoldExpiresAt" ormtype="timestamp">
	<!--- Long random token for the visitor's cancel and reschedule links (the emails step). --->
	<cfproperty name="ManageToken" ormtype="string" length="64" default="">
	<!--- The owner's private notes. --->
	<cfproperty name="Notes" ormtype="string" length="2000" default="">
	<!--- The post or page the booking was made from. --->
	<cfproperty name="PostRef" ormtype="int" default="0">
	<cfproperty name="ReminderSent" ormtype="boolean" default="false">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
