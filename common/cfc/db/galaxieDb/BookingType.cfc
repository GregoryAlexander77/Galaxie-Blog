<cfcomponent displayName="BookingType" persistent="true" table="BookingType" output="no" hint="Something visitors can book with the blog owner, eg. 'Consultation, 25 minutes' (2026-10-14). It offers one or more LocationOptions (LocationOptionLookup), and its times come from the owner's hours (AvailabilityRule). The payment fields are here from the start so adding payments (the Stripe step) changes nothing else. Managed by common/cfc/Bookings.cfc. See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 3.">

	<cfproperty name="BookingTypeId" fieldtype="id" generator="native" setter="false">
	<!--- Plain numbers, not ORM relationships (as in WebForm.cfc). --->
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="Name" ormtype="string" length="125" default="">
	<!--- Unique per blog; used to place the booking widget in a post, so it doesn't change when the name does. --->
	<cfproperty name="Alias" ormtype="string" length="100" default="">
	<!--- Optional heading the type is listed under, eg. "Existing clients", "Pets", "Youth". --->
	<cfproperty name="Category" ormtype="string" length="100" default="">
	<cfproperty name="Description" ormtype="string" length="4000" default="">
	<!--- An optional picture shown beside the type on the booking page (2026-10-22), in /images/bookings/. --->
	<cfproperty name="ImageUrl" ormtype="string" length="500" default="">
	<cfproperty name="DurationMinutes" ormtype="int" default="60">
	<!--- How often start times are offered: 15, 30, 60, or 0 = back to back (every DurationMinutes). --->
	<cfproperty name="StartIntervalMinutes" ormtype="int" default="30">
	<cfproperty name="BufferBeforeMinutes" ormtype="int" default="0">
	<cfproperty name="BufferAfterMinutes" ormtype="int" default="0">
	<!--- oneOnOne: one booking per time. group: up to GroupSize people per time. --->
	<cfproperty name="BookingMode" ormtype="string" length="20" default="oneOnOne">
	<cfproperty name="GroupSize" ormtype="int" default="1">
	<!--- Payments. Price 0 = free. PricingUnit: perBooking or perPerson (groups). PaymentOption: free, full, deposit or
	visitorChooses. BalanceCollection: inPerson or online. Set up in the Stripe step; stored now so nothing changes then. --->
	<cfproperty name="Price" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="PricingUnit" ormtype="string" length="20" default="perBooking">
	<cfproperty name="PaymentOption" ormtype="string" length="20" default="free">
	<cfproperty name="DepositAmount" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="DepositIsPercent" ormtype="boolean" default="false">
	<cfproperty name="BalanceCollection" ormtype="string" length="20" default="inPerson">
	<cfproperty name="RefundHours" ormtype="int" default="24">
	<!--- The intake form (a WebForm) asked when booking; 0 = none. --->
	<cfproperty name="WebFormRef" ormtype="int" default="0">
	<!--- Booking rules --->
	<cfproperty name="MinNoticeHours" ormtype="int" default="24">
	<cfproperty name="MaxDaysAhead" ormtype="int" default="60">
	<cfproperty name="DailyLimit" ormtype="int" default="0" hint="Most bookings of this type in one day; 0 = no limit.">
	<cfproperty name="RequiresApproval" ormtype="boolean" default="false">
	<cfproperty name="ReminderHours" ormtype="int" default="24" hint="Hours before the booking to send the reminder; 0 = none.">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="SortOrder" ormtype="int" default="0">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
