<cfcomponent displayName="ContentTemplateContentZone" persistent="true" table="ContentTemplateContentZone" output="no" hint="ORM logic for the new ContentTemplateContentZone table. This is a link table">
	
	<cfproperty name="ContentTemplateContentZoneId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many templates and zones --->
	<cfproperty name="ContentTemplateRef" ormtype="int" fieldtype="many-to-one" cfc="ContentTemplate" fkcolumn="ContentTemplateRef" cascade="all">
	<cfproperty name="ContentZoneRef" ormtype="int" fieldtype="many-to-one" cfc="ContentZone" fkcolumn="ContentZoneRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>