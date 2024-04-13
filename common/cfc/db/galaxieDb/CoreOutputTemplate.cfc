<cfcomponent displayName="CoreOutputTemplate" persistent="true" table="CoreOutputTemplate" output="no" hint="ORM logic for the new CoreOutputTemplate table">
	
	<cfproperty name="CoreOutputTemplateId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="CoreOutputTemplateName" ormtype="string" length="125" default="">
	<cfproperty name="CoreOutputTemplatePath" ormtype="string" length="240" default="">
	<cfproperty name="CoreOutputTemplateDesc" ormtype="string" length="1200" default="">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>