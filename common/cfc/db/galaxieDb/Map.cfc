<cfcomponent displayName="Map" persistent="true" table="Map" output="no" hint="ORM logic for the new Map table.">
	
	<cfproperty name="MapId" fieldtype="id" generator="native" setter="false">
	<!--- The MapRoutes column below is a psuedo column that is used by this object. There one map with many routes --->
	<cfproperty name="MapRoutes" singularname="MapRoute" ormtype="int" fieldtype="one-to-many" cfc="MapRoute" fkcolumn="MapRef" type="array" cascade="all" inverse="true" missingRowIgnored="true">
	<!--- Many map types to one map --->
	<cfproperty name="MapTypeRef" ormtype="int" fieldtype="many-to-one" cfc="MapType" fkcolumn="MapTypeRef" cascade="all" missingrowignored="true" hint="Foreign Key to the MapType.MapTypeId">
	<!--- There are many maps with one provider --->
	<cfproperty name="MapProviderRef" ormtype="int" fieldtype="many-to-one" cfc="MapProvider" fkcolumn="MapProviderRef" cascade="all" missingrowignored="true" hint="Foreign Key to the MapProvider.MapProviderId">
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all" missingrowignored="true" hint="Foreign Key to the Post.PostId">
	<cfproperty name="HasMapRoutes" ormtype="boolean" default="false">
	<cfproperty name="MapName" ormtype="string" default="" length="75">
	<cfproperty name="MapTitle" ormtype="string" default="" length="255">
	<cfproperty name="Location" ormtype="string" default="" length="125">
	<cfproperty name="GeoCoordinates" ormtype="string" default="" length="255">
	<cfproperty name="MinZoom" ormtype="int" default="1">
	<cfproperty name="MaxZoom" ormtype="int" default="20">
	<cfproperty name="Zoom" ormtype="int" default="15">
	<cfproperty name="OutlineMap" ormtype="boolean" default="false">
	<cfproperty name="CustomMarkerUrl" ormtype="string" default="" length="255">
	<cfproperty name="TileSourceUrl" ormtype="string" default="" length="255">
	<cfproperty name="TileSourceBounds" ormtype="string" default="" length="255">
	<cfproperty name="TileSourceMinZoom" ormtype="int" default="1">
	<cfproperty name="TileSourceMaxZoom" ormtype="int" default="20">
	<cfproperty name="TileSourceZoom" ormtype="int" default="15">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

