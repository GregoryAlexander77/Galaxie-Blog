<cfcomponent displayName="MapType" persistent="true" table="MapType" output="no" hint="ORM logic for the new MapType table.">
	
	<cfproperty name="MapTypeId" fieldtype="id" generator="native" setter="false">
	<!--- There are many MapTypes with one provider --->
	<cfproperty name="MapProviderRef" ormtype="int" fieldtype="many-to-one" cfc="MapProvider" fkcolumn="MapProviderRef" cascade="all" missingrowignored="true" hint="Foreign Key to the MapProvider.MapProviderId">
	<cfproperty name="MapType" ormtype="string" default="" length="255">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

