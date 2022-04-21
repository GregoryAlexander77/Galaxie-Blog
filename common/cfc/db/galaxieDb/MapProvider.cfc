<cfcomponent displayName="MapProvider" persistent="true" table="MapProvider" output="no" hint="ORM logic for the new MapProvider table.">
	
	<cfproperty name="MapProviderId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="MapProvider" ormtype="string" default="" length="75" hint="Currently only Bing. May support Google maps in the future">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

