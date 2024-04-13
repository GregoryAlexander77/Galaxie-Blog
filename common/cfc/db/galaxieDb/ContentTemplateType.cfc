<cfcomponent displayName="ContentTemplateType" persistent="true" table="ContentTemplateType" output="no" hint="ORM logic for the new ContentTemplateType table.">
	
	<cfproperty name="ContentTemplateTypeId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="ContentTemplateType" ormtype="string" default="" length="255">
	<cfproperty name="ContentTemplateTypeDesc" ormtype="string" default="" length="1200">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

