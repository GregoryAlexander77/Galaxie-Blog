<cfcomponent displayName="ThemeSetting" persistent="true" table="ThemeSetting" output="no" hint="ORM logic for the new ThemeSetting table">
	
	<cfproperty name="ThemeSettingId" fieldtype="id" generator="native" setter="false">
	<!---<cfproperty name="ThemeRef" singularname="Theme" ormtype="int" fieldtype="one-to-one" cfc="Theme" fkcolumn="ThemeRef" inverse="true" missingRowIgnored="true">--->
	<!--- Many fonts per theme --->
	<cfproperty name="FontRef" ormtype="int" fieldtype="many-to-one" cfc="Font" fkcolumn="FontRef" missingRowIgnored="true">
	<cfproperty name="FontSize" ormtype="int" default="14">
	<cfproperty name="FontSizeMobile" ormtype="int" default="12">
	<cfproperty name="Breakpoint" ormtype="string" default="" length="5">
	<cfproperty name="ContentWidth" ormtype="string" default="" length="15">
	<cfproperty name="MainContainerWidth" ormtype="string" default="" length="15">
	<cfproperty name="SideBarContainerWidth" ormtype="string" default="" length="15">
	<cfproperty name="SiteOpacity" ormtype="string" default="" length="10">
	<!--- FavIcons --->
	<cfproperty name="FavIconHtml" ormtype="string" length="2000" default="">
	<!--- Backgrounds --->
	<cfproperty name="IncludeBackgroundImages" ormtype="boolean" default="true">
	<cfproperty name="BlogBackgroundImage" ormtype="string" default="" length="255">
	<cfproperty name="BlogBackgroundImageMobile" ormtype="string" default="" length="255">
	<cfproperty name="BlogBackgroundImageRepeat" ormtype="string" default="" length="50">
	<cfproperty name="BlogBackgroundImagePosition" ormtype="string" default="" length="50">
	<cfproperty name="BlogBackgroundColor" ormtype="string" default="" length="25">
	<cfproperty name="HeaderBackgroundColor" ormtype="string" default="" length="25">
	<cfproperty name="HeaderBackgroundImage" ormtype="string" default="" length="255">
	<cfproperty name="HeaderBodyDividerImage" ormtype="string" default="" length="255">
	<cfproperty name="StretchHeaderAcrossPage" ormtype="boolean" default="false">
	<cfproperty name="AlignBlogMenuWithBlogContent" ormtype="boolean" default="true">
	<cfproperty name="TopMenuAlign" ormtype="string" default="" length="15">
	<!--- I am having issues having more than one reference to the font table. I removed this relationship as it is causing errors that I don't know how to resolve other than to perform another query to get to the font table when I need the blog name font stuff.--->
	<cfproperty name="MenuFontRef" ormtype="int">
	<cfproperty name="MenuBackgroundImage" ormtype="string" default="" length="255">
	<cfproperty name="CoverKendoMenuWithMenuBackgroundImage" ormtype="boolean" default="true">
	<!--- Logos --->
	<cfproperty name="LogoImageMobile" ormtype="string" default="" length="255">
	<cfproperty name="LogoMobileWidth" ormtype="string" default="" length="255">
	<cfproperty name="LogoImage" ormtype="string" default="" length="255">
	<cfproperty name="LogoPaddingTop" ormtype="string" default="" length="5">
	<cfproperty name="LogoPaddingRight" ormtype="string" default="" length="5">
	<cfproperty name="LogoPaddingLeft" ormtype="string" default="" length="5">
	<cfproperty name="LogoPaddingBottom" ormtype="string" default="" length="5">
	<cfproperty name="DefaultLogoImageForSocialMediaShare" ormtype="string" default="" length="255">
	<!--- Title --->
	<!--- I am having issues having more than one reference to the font table. I removed this relationship as it is causing errors that I don't know how to resolve other than to perform another query to get to the font table when I need the blog name font stuff.--->
	<cfproperty name="BlogNameFontRef" ormtype="int">
	<cfproperty name="BlogNameTextColor" ormtype="string" default="" length="20">
	<cfproperty name="BlogNameFontSize" ormtype="int" default="28">
	<cfproperty name="BlogNameFontSizeMobile" ormtype="int" default="20">
	<cfproperty name="DisplayBlogName" ormtype="boolean" default="true">
	<!--- Footer --->
	<cfproperty name="FooterImage" ormtype="string" default="" length="255">
	<!--- Are webp image formats included? --->
	<cfproperty name="WebPImagesIncluded" ormtype="boolean" default="false" hint="For the default blog we need to include both jpg/png/gif images as well as webp as we are not sure if the user that has downloaded the blog has webp support enabled on the server. This will allow users to download this package and see the default images from the blog regardless whether their server supports webp formats or not. If this is checked, all of the core images will be replaced with webp formats if the server supports them. If the end users server supports the webp format, any new themes that are created can be set to the webp image format when the images are uploaded.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>