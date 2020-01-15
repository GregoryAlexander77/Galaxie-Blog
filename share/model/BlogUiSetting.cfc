<cfcomponent displayName="BlogUiSetting" persistent="true" table="BlogUiSetting" output="no" hint="ORM logic for the new BlogUiSetting table. The BlogUiSetting sets UI settings for every page and these properties over-ride any theme settings when they are set. Not all of the settings are available here, the reset of the UI settings are in ThemeSetting.cfc">
	
	<cfproperty name="BlogUiSettingId" fieldtype="id" generator="native" setter="false">
	<!--- There are many blog options for every blog record. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="BlogFontRef" ormtype="int" fieldtype="many-to-one" cfc="Font" fkcolumn="BlogFontRef" cascade="all">
	<cfproperty name="BlogFontSize" ormtype="int" default="14">
	<cfproperty name="ContentWidth" ormtype="string" default="" length="15">
	<cfproperty name="MainContainerWidth" ormtype="string" default="" length="15">
	<cfproperty name="SideBarContainerWidth" ormtype="string" default="" length="15">
	<cfproperty name="SiteOpacity" ormtype="string" default="" length="10">
	<cfproperty name="AlignBlogMenuWithBlogContent" ormtype="boolean" default="true">
	<cfproperty name="TopMenuAlign" ormtype="string" default="" length="15">
	<cfproperty name="Breakpoint" ormtype="string" default="" length="5">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>