<cfcomponent displayName="Page" persistent="true" table="Page" output="no" hint="ORM logic for the new Page table">
	
	<cfproperty name="PageId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pages for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many pages can have one page type. Do not use a cascade argument here as it causes errors when a media gallery is uploaded. According to Adobe, cascade should not be used with many-to-one relationships. --->
	<cfproperty name="PageTypeRef" ormtype="int" fieldtype="many-to-one" cfc="PageType" fkcolumn="PageTypeRef" missingrowignored="true">
		
	<!--- There can one page with many zones. --->
	<cfproperty name="PageZones" singularname="PageZone" ormtype="int" fieldtype="one-to-many" cfc="ContentZone" fkcolumn="PageRef" inversejoincolumn="ContentZoneRef" cascade="all" inverse="true" missingRowIgnored="true">
	
	<!--- This is a psuedo column used by the object that will not be placed into the actual database. We are using the PageContentTemplate table as an intermediatory table to store the many to many relationships between a page and a zone. This is different than all of the other relationship types. --->
	<cfproperty name="ContentTemplates" singularname="ContentTemplate" ormtype="int" fieldtype="many-to-many" cfc="ContentTemplate" fkcolumn="PageRef" inversejoincolumn="ContentTemplateRef" linktable="PageContentTemplate" type="array" cascade="all" inverse="true" missingRowIgnored="true">
	
	<cfproperty name="PageName" ormtype="string" length="155" default="">
	<cfproperty name="PageDescription" ormtype="string" length="250" default="">
	<cfproperty name="PagePath" ormtype="string" length="250" default="">
	<cfproperty name="PageUrl" ormtype="string" length="250" default="">
	<cfproperty name="Active" ormtype="boolean" default="false">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>