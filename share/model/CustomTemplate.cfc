<cfcomponent displayName="CustomTemplate" persistent="true" table="CustomTemplate" output="no" hint="ORM logic for the new CustomTemplate table">
	
	<cfproperty name="CustomTemplateId" fieldtype="id" generator="native" setter="false">
	<!--- There is one custom template record for every theme --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="one-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="CoreLogicTemplate" ormtype="string" length="125" default="">
	<cfproperty name="HeaderTemplate" ormtype="string" length="125" default="">
	<cfproperty name="BodyString" ormtype="string" length="125" default="">
	<cfproperty name="FontTemplate" ormtype="string" length="125" default="">
	<cfproperty name="CssTemplate" ormtype="string" length="125" default="">
	<cfproperty name="TopMenuCssTemplate" ormtype="string" length="125" default="">
	<cfproperty name="TopMenuHtmlTemplate" ormtype="string" length="125" default="">
	<cfproperty name="TopMenuJsTemplate" ormtype="string" length="125" default="">
	<cfproperty name="BlogCssTemplate" ormtype="string" length="125" default="">
	<cfproperty name="BlogJsTemplate" ormtype="string" length="125" default="">
	<cfproperty name="BlogHtmlTemplate" ormtype="string" length="125" default="">
	<cfproperty name="FooterHtmlTemplate" ormtype="string" length="125" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>