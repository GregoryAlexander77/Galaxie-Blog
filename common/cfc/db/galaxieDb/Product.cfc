<cfcomponent displayName="Product" persistent="true" table="Product" output="no" hint="Something the blog sells (2026-10-20): a physical item (shipped, one flat shipping price), a digital file (a download link that expires) or a service. Placed in posts, pages and scenes like a form, and sold through Stripe's hosted checkout. Managed by common/cfc/Shop.cfc.">

	<cfproperty name="ProductId" fieldtype="id" generator="native" setter="false">
	<!--- Plain numbers, not ORM relationships (as in WebForm.cfc). --->
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="Name" ormtype="string" length="255" default="">
	<!--- The product's short name in the placeholder that puts it in a post (data-product="..."). --->
	<cfproperty name="Alias" ormtype="string" length="100" default="">
	<!--- Long text: the column type is set for the blog's database by DatabaseOrmTypes.cfc. --->
	<cfproperty name="Description" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="ImageUrl" ormtype="string" length="500" default="">
	<!--- physical, digital or service --->
	<cfproperty name="Kind" ormtype="string" length="20" default="physical">
	<cfproperty name="Price" ormtype="big_decimal" precision="10" scale="2" default="0">
	<!--- Physical products: the flat shipping price (0 = free). An order pays the highest of its products' prices, once. --->
	<cfproperty name="ShippingPrice" ormtype="big_decimal" precision="10" scale="2" default="0">
	<!--- Stock: only counted when TrackStock is on; at 0 the product shows Sold out. --->
	<cfproperty name="TrackStock" ormtype="boolean" default="false">
	<cfproperty name="Stock" ormtype="int" default="0">
	<!--- Digital products: the stored file's name (random, in the shop's private folder) and the name the buyer downloads it as. --->
	<cfproperty name="FileName" ormtype="string" length="255" default="">
	<cfproperty name="FileDisplayName" ormtype="string" length="255" default="">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>
