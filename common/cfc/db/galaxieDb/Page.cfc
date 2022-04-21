<cfcomponent displayName="Page" persistent="true" table="Page" output="no" hint="ORM logic for the new Page table">
	
	<cfproperty name="PageId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pages for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- A psuedo column to determine the templates for each page. 
	<cfproperty name="PageTemplates" singularname="PageTemplate" ormtype="int" fieldtype="one-to-many" cfc="PageTemplate" fkcolumn="PageRef" cascade="all" inverse="true" missingRowIgnored="true">--->
	<cfproperty name="PageName" ormtype="string" length="155" default="">
	<cfproperty name="PageDescription" ormtype="string" length="250" default="">
	<cfproperty name="PagePath" ormtype="string" length="250" default="">
	<cfproperty name="PageUrl" ormtype="string" length="250" default="">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>