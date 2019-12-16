<cfcomponent displayName="ThemeSetting" persistent="true" table="ThemeSetting" output="no" hint="ORM logic for the new ThemeSetting table">
	
	<cfproperty name="ThemeSettingId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<!--- For efficiency, there is a one to one relationship between a theme and a theme setting. This table is essentially an extension to the Theme table. --->
	<cfproperty name="ThemeRef" ormtype="one-to-one" cfc="Theme" fkcolumn="ThemeId">
	<cfproperty name="FontRef" ormtype="one-to-one" cfc="Font" fkcolumn="FontId">
	<cfproperty name="FontSize" ormtype="text" default="">
	<cfproperty name="UseCustomTheme" ormtype="boolean" default="false">
	<cfproperty name="CustomThemeName" ormtype="text" default="">
	<cfproperty name="DarkTheme" ormtype="boolean" default="false">
	<cfproperty name="ContentWidth" ormtype="text" default="">
	<cfproperty name="MainContainerWidth" ormtype="text" default="">
	<cfproperty name="SideBarContainerWidth" ormtype="text" default="">
	<cfproperty name="SiteOpacity" ormtype="text" default="">
	<cfproperty name="BlogBackgroundImage" ormtype="text" default="">
	<cfproperty name="BlogBackgroundImageRepeat" ormtype="text" default="">
	<cfproperty name="StretchHeaderAcrossPage" ormtype="text" default="">
	<cfproperty name="AlignBlogMenuWithBlogContent" ormtype="text" default="">
	<cfproperty name="TopMenuAlign" ormtype="text" default="">
	<cfproperty name="HeaderBackgroundImage" ormtype="text" default="">	
	<cfproperty name="MenuBackgroundImage" ormtype="text" default="">
	<cfproperty name="CoverKendoMenuWithMenuBackgroundImage" ormtype="text" default="">
	<cfproperty name="LogoImageMobile" ormtype="text" default="">
	<cfproperty name="LogoPaddingTop" ormtype="text" default="">
	<cfproperty name="LogoPaddingRight" ormtype="text" default="">
	<cfproperty name="LogoPaddingLeft" ormtype="text" default="">
	<cfproperty name="LogoPaddingBottom" ormtype="text" default="">
	<cfproperty name="BlogNameTextColor" ormtype="text" default="">
	<cfproperty name="BlogNameFontRef" ormtype="one-to-many" cfc="Font" fkcolumn="FontId">
	<cfproperty name="HeaderBodyDividerImage" ormtype="text" default="">
	<cfproperty name="Breakpoint" ormtype="text" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>