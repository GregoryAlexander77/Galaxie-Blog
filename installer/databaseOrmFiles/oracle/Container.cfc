<cfcomponent displayName="Container" persistent="true" table="Container" output="no" hint="ORM logic for the new Container table">
	
	<cfproperty name="ContentContainerId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pages for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- A psuedo column to determine the templates for each page. --->
	<cfproperty name="ContainerName" ormtype="string" missingRowIgnored="true">
	<!--- This is configured for Oracle. Manually change this property if you use another db --->
	<cfproperty name="ContainerContent" ormtype="clob" default="">
	<cfproperty name="ContainerPath" ormtype="string" length="250" default="">
	<cfproperty name="ContainerUrl" ormtype="string" length="250" default="">
	<cfproperty name="LastCached" ormtype="date" default="">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>