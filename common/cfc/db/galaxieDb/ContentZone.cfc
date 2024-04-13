<cfcomponent displayName="ContentZone" persistent="true" table="ContentZone" output="no" hint="ORM logic for the new ContentZone table.">
	
	<cfproperty name="ContentZoneId" fieldtype="id" generator="native" setter="false">
	<!--- Many zones for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many zones for one page. --->
	<cfproperty name="PageRef" ormtype="int" fieldtype="many-to-one" cfc="Page" fkcolumn="PageRef" cascade="all">
	<!--- This is a psuedo column used by the object that will not be placed into the actual database. We are using the ContentTemplateContentPost table as an intermediatory table to store the many to many relationships between a zone and a template. This is different than all of the other relationship types.---> 
	<cfproperty name="ContentTemplates" singularname="ContentTemplate" ormtype="int" fieldtype="many-to-many" cfc="ContentTemplate" fkcolumn="ContentZoneRef" inversejoincolumn="ContentTemplateRef" linktable="ContentTemplateContentZone" type="array" cascade="all" inverse="true" missingRowIgnored="true">
		
	<cfproperty name="ContentZoneName" ormtype="string" default="" length="255">
	<cfproperty name="ContentZoneDesc" ormtype="string" default="" length="1200">
	<cfproperty name="DefaultZone" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>