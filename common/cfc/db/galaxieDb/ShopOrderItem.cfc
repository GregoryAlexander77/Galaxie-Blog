<cfcomponent displayName="ShopOrderItem" persistent="true" table="ShopOrderItem" output="no" hint="One product in a shop order (2026-10-20), with its name and price as they were when it was bought, and for a digital product the download link's token, use count and expiry. Managed by common/cfc/Shop.cfc.">

	<cfproperty name="ShopOrderItemId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="ShopOrderRef" ormtype="int" default="0">
	<cfproperty name="ProductRef" ormtype="int" default="0">
	<cfproperty name="ProductName" ormtype="string" length="255" default="">
	<!--- physical, digital or service, as the product was when bought --->
	<cfproperty name="Kind" ormtype="string" length="20" default="">
	<cfproperty name="UnitPrice" ormtype="big_decimal" precision="10" scale="2" default="0">
	<cfproperty name="Quantity" ormtype="int" default="1">
	<!--- Digital products, once paid: the download link's token, how often it was used and when it stops working. --->
	<cfproperty name="DownloadToken" ormtype="string" length="64" default="">
	<cfproperty name="DownloadCount" ormtype="int" default="0">
	<cfproperty name="DownloadExpiresAt" ormtype="timestamp">

</cfcomponent>
