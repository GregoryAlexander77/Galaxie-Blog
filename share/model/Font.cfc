<cfcomponent displayName="Font" persistent="true" table="Font" output="no" hint="ORM logic for the new Font table">
	
	<cfproperty name="FontId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="Font" ormtype="string" default="" length="25">
	<cfproperty name="FontType" ormtype="string" length="75" default="">
	<cfproperty name="GoogleFont" ormtype="boolean" default="false">
	<cfproperty name="CustomFont" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>