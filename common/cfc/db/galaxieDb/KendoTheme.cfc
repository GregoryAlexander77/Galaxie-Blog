<cfcomponent displayName="KendoTheme" persistent="true" table="KendoTheme" output="no" hint="ORM logic for the new Kendo Theme table">
	
	<cfproperty name="KendoThemeId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="KendoTheme" ormtype="string" length="50" default="">
	<cfproperty name="KendoCommonCssFileLocation" ormtype="string" length="255" default="">
	<cfproperty name="KendoThemeCssFileLocation" ormtype="string" length="255" default="">
	<cfproperty name="KendoThemeMobileCssFileLocation" ormtype="string" length="255" default="text">
	<cfproperty name="DarkTheme" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp" default="">

</cfcomponent>