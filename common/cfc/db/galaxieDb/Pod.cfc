<cfcomponent displayName="Pod" persistent="true" table="Pod" output="no" hint="ORM logic for the new PageType table">
	
	<cfproperty name="PodId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pods for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many pods can have one content template. Do not use a cascade argument here. According to Adobe, cascade should not be used with many-to-one relationships. --->
	<cfproperty name="ContentTemplateRef" ormtype="int" fieldtype="many-to-one" cfc="ContentTemplate" fkcolumn="ContentTemplateRef" missingrowignored="true">
	<cfproperty name="PodName" ormtype="string" length="155" default="">
	<cfproperty name="PodDescription" ormtype="string" length="250" default="">
	<cfproperty name="PodOrder" ormtype="int">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>