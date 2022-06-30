<cfcomponent displayName="PodContainer" persistent="true" table="PodContainer" output="no" hint="ORM logic for the new PodContainer table">

	<cfproperty name="PodContainerId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pages for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- A psuedo column to determine the templates for each page. --->
	<cfproperty name="PodContainerName" ormtype="string" missingRowIgnored="true">
	<!--- This is configured for MySql. Manually change this property if you use another db --->
	<cfproperty name="PodContainerContent" ormtype="text" sqltype="longtext" default="">
	<cfproperty name="PodContainerPath" ormtype="string" length="250" default="">
	<cfproperty name="PodContainerUrl" ormtype="string" length="250" default="">
	<cfproperty name="PodContainerOrder" ormtype="int" default="">
	<cfproperty name="LastCached" ormtype="date" default="">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>