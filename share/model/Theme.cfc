<cfcomponent displayName="Theme" persistent="true" table="Theme" output="no" hint="ORM logic for the new Theme table">
	
	<cfproperty name="ThemeId" fieldtype="id" generator="native" setter="false">
	<!--- There are many themes for a blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="UseTheme" ormtype="boolean" default="true">
	<cfproperty name="Theme" ormtype="string" length="50" default="">
	<cfproperty name="KendoTheme" ormtype="string" length="50" default="">
	<cfproperty name="KendoThemeCssFileLocation" ormtype="string" length="255" default="">
	<cfproperty name="KendoThemeMobileCssFileLocation" ormtype="string" length="255" default="text">
	<cfproperty name="DarkTheme" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp" default="">

</cfcomponent>