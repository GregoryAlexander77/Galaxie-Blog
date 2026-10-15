<cfcomponent displayName="Payment" persistent="true" table="Payment" output="no" hint="One online payment attempt (2026-10-15): a Stripe Checkout Session for a booking (later an RSVP), its amounts and what happened to it. No card data is ever stored; the provider's ids link to its dashboard. Managed by common/cfc/Payments.cfc. See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 4.">

	<cfproperty name="PaymentId" fieldtype="id" generator="native" setter="false">
	<!--- Plain numbers, not ORM relationships (as in WebForm.cfc). --->
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="BookingRef" ormtype="int" default="0">
	<cfproperty name="WebFormSubmissionRef" ormtype="int" default="0">
	<!--- stripe (paypal later) --->
	<cfproperty name="Provider" ormtype="string" length="20" default="stripe">
	<!--- The Checkout Session id (cs_...) and, once paid, the PaymentIntent id (pi_...). --->
	<cfproperty name="ProviderSessionId" ormtype="string" length="255" default="">
	<cfproperty name="ProviderPaymentId" ormtype="string" length="255" default="">
	<!--- What this payment is for: full or deposit (balance later). --->
	<cfproperty name="Purpose" ormtype="string" length="20" default="full">
	<cfproperty name="Amount" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="TaxAmount" ormtype="big_decimal" precision="10" scale="2" default="0">
	<!--- What Stripe actually took (after any promotion code), in the currency below. --->
	<cfproperty name="AmountPaid" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="RefundedAmount" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="Currency" ormtype="string" length="3" default="">
	<!--- pending, paid, expired, cancelled, refunded, partlyRefunded --->
	<cfproperty name="Status" ormtype="string" length="20" default="pending">
	<cfproperty name="TestMode" ormtype="boolean" default="true">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
