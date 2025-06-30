<cfcomponent displayName="MapRoute" persistent="true" table="MapRoute" output="no" hint="ORM logic for the new MapRoute table. This table stores bing waypoionts">
	
	<cfproperty name="MapRouteId" fieldtype="id" generator="native" setter="false">
	<!--- Many routes to one map --->
	<cfproperty name="MapRef" ormtype="int" fieldtype="many-to-one" cfc="Map" fkcolumn="MapRef" cascade="all" missingrowignored="false" hint="Foreign Key to the Map.MapId">
	<cfproperty name="Location" ormtype="string" default="" length="255">
	<cfproperty name="GeoCoordinates" ormtype="string" default="" length="100">
	<cfproperty name="Latitude" ormtype="string" default="" length="50">
	<cfproperty name="Longitude" ormtype="string" default="" length="50">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

