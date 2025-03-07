<cfcomponent displayName="Theme" persistent="true" table="Theme" output="no" hint="ORM logic for the new Theme table">
	
	<cfproperty name="ThemeId" fieldtype="id" generator="native" setter="false">
	<!--- There are many themes for a blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- There are many themes to one kendo theme --->
	<cfproperty name="KendoThemeRef" ormtype="int" fieldtype="many-to-one" cfc="KendoTheme" fkcolumn="KendoThemeRef">
	<!--- There is one setting per theme --->
	<cfproperty name="ThemeSettingRef" ormtype="int" fieldtype="one-to-one" cfc="ThemeSetting" fkcolumn="ThemeSettingRef" cascade="all">
	<cfproperty name="ThemeAlias" ormtype="string" length="50" default="">
	<cfproperty name="ThemeName" ormtype="string" length="100" default="">
	<cfproperty name="ThemeGenre" ormtype="string" length="125" default="">	
	<cfproperty name="SelectedTheme" ormtype="boolean" default="true" hint="This will be set to true if this is the theme that you want to be displayed at all times. The user can also choose other themes for a single post however.">
	<cfproperty name="UseTheme" ormtype="boolean" default="true" hint="What themes do you want available for the blog? If the SelectedTheme is not selected, multiple themes will be displayed that rotate.">
	<cfproperty name="DarkTheme" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp" default="">

</cfcomponent>