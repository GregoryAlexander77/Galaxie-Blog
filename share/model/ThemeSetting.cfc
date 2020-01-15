<cfcomponent displayName="ThemeSetting" persistent="true" table="ThemeSetting" output="no" hint="ORM logic for the new ThemeSetting table">
	
	<cfproperty name="ThemeSettingId" fieldtype="id" generator="native" setter="false">
	<!--- For efficiency, there is a one to one relationship between a theme and a theme setting. This table is essentially an extension to the Theme table. --->
	<cfproperty name="ThemeRef" ormtype="int" fieldtype="one-to-one" cfc="Theme" fkcolumn="ThemeRef" missingRowIgnored="true">
	<!--- Many fonts per theme --->
	<cfproperty name="FontRef" ormtype="int" fieldtype="many-to-one" cfc="Font" fkcolumn="FontRef" missingRowIgnored="true">
	<cfproperty name="FontSize" ormtype="string" default="" length="15">
	<cfproperty name="ContentWidth" ormtype="string" default="" length="15">
	<cfproperty name="MainContainerWidth" ormtype="string" default="" length="15">
	<cfproperty name="SideBarContainerWidth" ormtype="string" default="" length="15">
	<cfproperty name="SiteOpacity" ormtype="string" default="" length="10">
	<cfproperty name="BlogBackgroundImage" ormtype="string" default="" length="255">
	<cfproperty name="BlogBackgroundImageRepeat" ormtype="string" default="" length="50">
	<cfproperty name="blogBackgroundImagePosition" ormtype="string" default="" length="50">	
	<cfproperty name="StretchHeaderAcrossPage" ormtype="boolean" default="false">
	<cfproperty name="AlignBlogMenuWithBlogContent" ormtype="boolean" default="true">
	<cfproperty name="TopMenuAlign" ormtype="string" default="" length="15">
	<cfproperty name="HeaderBackgroundImage" ormtype="string" default="" length="255">	
	<cfproperty name="MenuBackgroundImage" ormtype="string" default="" length="255">
	<cfproperty name="CoverKendoMenuWithMenuBackgroundImage" ormtype="boolean" default="true">
	<cfproperty name="LogoImageMobile" ormtype="string" default="" length="255">
	<cfproperty name="logoMobileWidth" ormtype="string" default="" length="255">
	<cfproperty name="logoImage" ormtype="string" default="" length="255">
	<cfproperty name="LogoPaddingTop" ormtype="string" default="" length="5">
	<cfproperty name="LogoPaddingRight" ormtype="string" default="" length="5">
	<cfproperty name="LogoPaddingLeft" ormtype="string" default="" length="5">
	<cfproperty name="LogoPaddingBottom" ormtype="string" default="" length="5">
	<cfproperty name="BlogNameTextColor" ormtype="string" default="" length="20">
	<cfproperty name="BlogNameFontRef" ormtype="int" fieldtype="one-to-one" cfc="Font" fkcolumn="BlogNameFontRef" missingRowIgnored="true">
	<cfproperty name="HeaderBodyDividerImage" ormtype="string" default="" length="255">
	<cfproperty name="Breakpoint" ormtype="string" default="" length="5">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>