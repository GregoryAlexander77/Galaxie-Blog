<cfcomponent displayName="ContentOutputTheme" persistent="true" table="ContentOutputTheme" output="no" hint="ORM logic for the new ContentOutputTheme table. This is a link table">
	
	<cfproperty name="ContentOutputThemeId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many templates and zones --->
	<cfproperty name="ContentOutputRef" ormtype="int" fieldtype="many-to-one" cfc="ContentOutput" fkcolumn="ContentOutputRef" cascade="all">
	<cfproperty name="ThemeRef" ormtype="int" fieldtype="many-to-one" cfc="Theme" fkcolumn="ThemeRef" cascade="all">
	<cfproperty name="LightTheme" ormtype="yes_no" default="no">
	<cfproperty name="DarkTheme" ormtype="yes_no" default="no">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>