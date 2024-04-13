<cfcomponent displayName="PageType" persistent="true" table="PageType" output="no" hint="ORM logic for the new PageType table">
	
	<cfproperty name="PageTypeId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pages for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="PageTypeName" ormtype="string" length="155" default="">
	<cfproperty name="PageTypeDescription" ormtype="string" length="250" default="">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>