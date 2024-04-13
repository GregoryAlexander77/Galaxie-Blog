<cfcomponent displayName="ContentOutput" persistent="true" table="ContentOutput" output="no" hint="ORM logic for the new ContentOutput table. This table will store the all of the various content by certain conditions, such as if the device is mobile.">
	
	<cfproperty name="ContentOutputId" fieldtype="id" generator="native" setter="false">
	<!--- Many content to one content template --->
	<cfproperty name="ContentTemplateRef" ormtype="int" fieldtype="many-to-one" cfc="ContentTemplate" fkcolumn="ContentTemplateRef" cascade="all" missingrowignored="true" hint="Foreign Key to the ContentTemplate.ContentTemplateId">
		
	<!--- This is a psuedo column used by the object that will not be placed into the actual database. We are using the ContentTemplateTheme table as an intermediatory table to store the many to many relationships between a template and a theme. This is different than all of the other relationship types. Note: this is an optional setting and only used when the user wants to create unique content for a particular theme. --->
	<cfproperty name="Themes" singularname="Theme" ormtype="int" fieldtype="many-to-many" cfc="Theme" fkcolumn="ContentOutputRef" inversejoincolumn="ThemeRef" linktable="ContentOutputTheme" type="array" inverse="true" cascade="all" missingRowIgnored="true" hint="This is an optional setting and only used when the user wants to create unique content for a particular theme.">
		
	<cfproperty name="Condition" ormtype="string" length="125" default="">
	<cfproperty name="SubCondition" ormtype="string" length="125" default="">
	<cfproperty name="ConditionDesc" ormtype="string" length="1200" default="">
	<!--- The following two columns are configured for SQL Server. Manually change the varchar(max) property if you use another db --->
	<cfproperty name="Content" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="ContentMobile" ormtype="string" sqltype="varchar(max)" default="">
	
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="LastCached" ormtype="date" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>