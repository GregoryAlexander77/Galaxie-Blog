<cfcomponent displayName="PaymentSetting" persistent="true" table="PaymentSetting" output="no" hint="The blog's payment settings (2026-10-14): the currency, how tax is handled, test or live mode, and the owner's own Stripe keys. One row per blog, kept out of the Blog table so the keys are never part of the application-wide Blog object. Managed by common/cfc/Payments.cfc and edited in Blog Settings > Payments. See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 4.">

	<cfproperty name="PaymentSettingId" fieldtype="id" generator="native" setter="false">
	<!--- A plain number, not an ORM relationship (as in WebForm.cfc). --->
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<!--- ISO 4217 code, eg. USD. Every price on the blog is in this currency. --->
	<cfproperty name="Currency" ormtype="string" length="3" default="USD">
	<!--- included (prices include tax, the default) or add (TaxRate percent is added at checkout, shown as TaxName). --->
	<cfproperty name="TaxMode" ormtype="string" length="20" default="included">
	<cfproperty name="TaxName" ormtype="string" length="50" default="">
	<cfproperty name="TaxRate" ormtype="big_decimal" precision="7" scale="3" default="0">
	<!--- True: the test keys are used and no real money moves. --->
	<cfproperty name="TestMode" ormtype="boolean" default="true">
	<!--- Publishable keys are public by design (Stripe puts them in web pages). The secret key and the webhook signing secret
	are stored encrypted (Payments.cfc, with a key kept in blog.ini.cfm), and are never sent to the browser. --->
	<cfproperty name="StripeTestPublishableKey" ormtype="string" length="255" default="">
	<cfproperty name="StripeTestSecretKey" ormtype="string" length="1000" default="">
	<cfproperty name="StripeTestWebhookSecret" ormtype="string" length="1000" default="">
	<cfproperty name="StripeLivePublishableKey" ormtype="string" length="255" default="">
	<cfproperty name="StripeLiveSecretKey" ormtype="string" length="1000" default="">
	<cfproperty name="StripeLiveWebhookSecret" ormtype="string" length="1000" default="">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
