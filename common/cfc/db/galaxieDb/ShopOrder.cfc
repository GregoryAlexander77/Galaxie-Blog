<cfcomponent displayName="ShopOrder" persistent="true" table="ShopOrder" output="no" hint="One shop order (2026-10-20): who bought, where it ships, the amounts and its status. Made when the buyer goes to Stripe's checkout (pending) and only marked paid by Stripe's verified webhook. Managed by common/cfc/Shop.cfc; its products are in ShopOrderItem.">

	<cfproperty name="ShopOrderId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<!--- A random token for the buyer's links (the thank-you page, downloads). --->
	<cfproperty name="OrderToken" ormtype="string" length="64" default="">
	<cfproperty name="Name" ormtype="string" length="255" default="">
	<cfproperty name="Email" ormtype="string" length="255" default="">
	<!--- The signed-in member who bought it (BlogMember.MemberId), or 0. --->
	<cfproperty name="MemberRef" ormtype="int" default="0">
	<!--- The shipping address Stripe collected (physical products only). --->
	<cfproperty name="ShipName" ormtype="string" length="255" default="">
	<cfproperty name="ShipLine1" ormtype="string" length="255" default="">
	<cfproperty name="ShipLine2" ormtype="string" length="255" default="">
	<cfproperty name="ShipCity" ormtype="string" length="255" default="">
	<cfproperty name="ShipState" ormtype="string" length="255" default="">
	<cfproperty name="ShipPostalCode" ormtype="string" length="50" default="">
	<cfproperty name="ShipCountry" ormtype="string" length="10" default="">
	<cfproperty name="NeedsShipping" ormtype="boolean" default="false">
	<cfproperty name="Subtotal" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="ShippingAmount" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="TaxAmount" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="DiscountAmount" ormtype="big_decimal" precision="10" scale="2" default="0">
	<!--- What Stripe took (after any promotion code). --->
	<cfproperty name="Total" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="Currency" ormtype="string" length="3" default="">
	<!--- pending, paid, shipped, refunded, partlyRefunded, expired, cancelled --->
	<cfproperty name="Status" ormtype="string" length="20" default="pending">
	<cfproperty name="TestMode" ormtype="boolean" default="true">
	<cfproperty name="PaidAt" ormtype="timestamp">
	<cfproperty name="ShippedAt" ormtype="timestamp">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
