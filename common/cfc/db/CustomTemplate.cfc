<cfcomponent displayName="CustomTemplate" persistent="true" table="CustomTemplate" output="no" hint="ORM logic for the new CustomTemplate table">
	
	<cfproperty name="CustomTemplateId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="one-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="ThemeRef" ormtype="one-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="CoreLogicTemplate" ormtype="text" default="">
	<cfproperty name="HeaderTemplate" ormtype="text" default="">
	<cfproperty name="BodyString" ormtype="text" default="">
	<cfproperty name="FontTemplate" ormtype="text" default="">
	<cfproperty name="CssTemplate" ormtype="text" default="">
	<cfproperty name="TopMenuCssTemplate" ormtype="text" default="">
	<cfproperty name="TopMenuJsTemplate" ormtype="text" default="">
	<cfproperty name="BlogCssTemplate" ormtype="text" default="">
	<cfproperty name="BlogJsTemplate" ormtype="text" default="">
	<cfproperty name="BlogHtmlTemplate" ormtype="text" default="">
	<cfproperty name="FooterHtmlTemplate" ormtype="text" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>