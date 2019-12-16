<cfcomponent displayName="Font" persistent="true" table="Font" output="no" hint="ORM logic for the new Font table">
	
	<cfproperty name="FontId" fieldtype="id" generator="increment">
	<cfproperty name="Font" ormtype="text" default="">
	<cfproperty name="KendoTheme" ormtype="text" default="">
	<cfproperty name="FontType" ormtype="text" default="">
	<cfproperty name="CustomFont" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>