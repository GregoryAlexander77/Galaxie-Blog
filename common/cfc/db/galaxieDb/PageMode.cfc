<cfcomponent displayName="PageMode" persistent="true" table="PageMode" output="no" hint="ORM logic for the new PageMode table">
	
	<cfproperty name="PageModeId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pages for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="PageModeAlias" ormtype="string" length="155" default="">
	<cfproperty name="PageModeName" ormtype="string" length="155" default="">
	<cfproperty name="PageModeDescription" ormtype="string" length="250" default="">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>