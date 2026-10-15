<cfcomponent displayName="WebFormSubmission" persistent="true" table="WebFormSubmission" output="no" hint="What a visitor sent with a WebForm (2026-10-13). Every field's value is in ValuesJson, keyed by the field's FieldName, so a submission survives fields being added, renamed or removed later. Email and Name are copied out so the admin grid can search and sort on them. Deleting a submission really deletes it.">

	<cfproperty name="WebFormSubmissionId" fieldtype="id" generator="native" setter="false">
	<!--- Plain numbers, not ORM relationships (see WebForm.cfc). --->
	<cfproperty name="WebFormRef" ormtype="int" default="0">
	<cfproperty name="PostRef" ormtype="int" default="0" hint="The post or page the form was sent from.">
	<cfproperty name="Email" ormtype="string" length="255" default="">
	<cfproperty name="Name" ormtype="string" length="255" default="">
	<!--- Long text: the column type is set for the blog's database by DatabaseOrmTypes.cfc. --->
	<cfproperty name="ValuesJson" ormtype="string" sqltype="varchar(max)" default="">
	<!--- received (a plain form), hidden (taken off the public list), or for an event RSVP confirmed / cancelled. --->
	<cfproperty name="Status" ormtype="string" length="20" default="received">
	<!--- A random token for links in emails (eg. an RSVP's cancel link). Empty for a plain form. --->
	<cfproperty name="ManageToken" ormtype="string" length="64" default="">
	<!--- An event RSVP (2026-10-15): the event (BlogEvent.EventId, 0 = a plain form), how many people it counts for, the way they chose to attend (LocationOptionId, 0 = not asked) and when it was cancelled. Status is then confirmed or cancelled. --->
	<cfproperty name="EventRef" ormtype="int" default="0">
	<cfproperty name="PartySize" ormtype="int" default="1">
	<cfproperty name="LocationOptionRef" ormtype="int" default="0">
	<cfproperty name="CancelledAt" ormtype="timestamp">
	<!--- A paid RSVP (2026-10-15): while the person is on Stripe's payment page the sign-up is held (Status held) until HoldExpiresAt; the verified payment webhook confirms it. PaymentStatus: none, pending, paid, partlyRefunded, refunded or expired. --->
	<cfproperty name="PaymentStatus" ormtype="string" length="20" default="none">
	<cfproperty name="AmountTotal" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="AmountPaid" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="HoldExpiresAt" ormtype="timestamp">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
