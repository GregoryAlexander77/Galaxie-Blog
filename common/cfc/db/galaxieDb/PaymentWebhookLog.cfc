<cfcomponent displayName="PaymentWebhookLog" persistent="true" table="PaymentWebhookLog" output="no" hint="Every payment webhook received (2026-10-15): the provider's event id, so a repeated delivery is acted on once, whether its signature checked out, and what was done. See common/services/stripeWebhook.cfm and common/cfc/Payments.cfc.">

	<cfproperty name="PaymentWebhookLogId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="Provider" ormtype="string" length="20" default="stripe">
	<cfproperty name="EventId" ormtype="string" length="255" default="">
	<cfproperty name="EventType" ormtype="string" length="100" default="">
	<cfproperty name="SignatureValid" ormtype="boolean" default="false">
	<!--- What was done with it, in a few words (never secrets). --->
	<cfproperty name="Result" ormtype="string" length="500" default="">
	<cfproperty name="TestMode" ormtype="boolean" default="true">
	<cfproperty name="Received" ormtype="timestamp">

</cfcomponent>
