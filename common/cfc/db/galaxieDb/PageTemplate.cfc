<cfcomponent displayName="PageTemplate" persistent="true" table="PageTemplate" output="no" hint="ORM logic for the new PageTemplate table">
	
	<cfproperty name="PageTemplateId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pages for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many Pages for each template. --->
	<cfproperty name="PageRef" ormtype="int" fieldtype="many-to-one" cfc="Page" fkcolumn="PageId" cascade="all">
	<!--- A psuedo column to determine the templates for each page. --->
	<cfproperty name="PageTemplateName" singularname="PageTemplate" ormtype="int" fieldtype="one-to-many" cfc="PageTemplate" fkcolumn="PageRef" cascade="all" inverse="true" missingRowIgnored="true">
	<cfproperty name="PageTemplatePath" ormtype="string" length="250" default="">
	<cfproperty name="PageTemplateUrl" ormtype="string" length="250" default="">
	<cfproperty name="LastCached" ormtype="date" default="">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>