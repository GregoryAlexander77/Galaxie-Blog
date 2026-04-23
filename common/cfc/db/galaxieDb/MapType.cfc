<cfcomponent displayName="MapType" persistent="true" table="MapType" output="no" hint="ORM logic for the new MapType table.">
	
	<cfproperty name="MapTypeId" fieldtype="id" generator="native" setter="false">
	<!--- I don't want a relationship here. I only have this column in order to limit records to a map provider --->
	<cfproperty name="MapProviderRef" ormtype="int">
	<cfproperty name="MapType" ormtype="string" default="" length="255">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

