<cfcomponent displayName="Theme" persistent="true" table="Theme" output="no" hint="ORM logic for the new Theme table">
	
	<cfproperty name="ThemeId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="Theme" ormtype="text" default="">
	<cfproperty name="KendoTheme" ormtype="text" default="">
	<cfproperty name="CssFileLocation" ormtype="text" default="">
	<cfproperty name="MobileCssFileLocation" ormtype="text" default="text">
	<cfproperty name="MobileCssFileLocation" ormtype="text" default="text">
	<cfproperty name="DarkTheme" ormtype="boolean">
	<cfproperty name="UseTheme" ormtype="boolean">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>