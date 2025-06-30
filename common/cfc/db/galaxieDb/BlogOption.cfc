<cfcomponent displayName="BlogOption" persistent="true" table="BlogOption" output="no" hint="ORM logic for the new BlogOption table">
	
	<cfproperty name="BlogOptionId" fieldtype="id" generator="native" setter="false">
	<!--- There are many blog options for every blog record. --->
	<!--- Multiple ORM database error occurs below --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="JQueryCDNPath" ormtype="string" length="225" default="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js">
	<cfproperty name="KendoCommercial" ormtype="boolean" default="false">
	<cfproperty name="KendoFolderPath" ormtype="string" length="225" default="/common/libs/kendoCore/">
	<cfproperty name="DeferScriptsAndCss" ormtype="boolean" default="true">
	<cfproperty name="UseSsl" ormtype="boolean" default="true">
	<cfproperty name="ServerRewriteRuleInPlace" ormtype="boolean" default="false">	
	<cfproperty name="MinimizeCode" ormtype="boolean" default="true">
	<cfproperty name="DisableCache" ormtype="boolean" default="false">
	<cfproperty name="EntriesPerBlogPage" ormtype="int" default="10">
	<cfproperty name="UseCaptcha" ormtype="boolean" default="true">
	<cfproperty name="AllowGravatar" ormtype="boolean" default="true">
	<cfproperty name="BlogModerated" ormtype="boolean" default="true">
	<cfproperty name="BackgroundImageResolution" ormtype="string" length="35" default="LowRes" hint="Either 'HiRes', 'MedRes', or 'LowRes'. LowRes is default.">
	<cfproperty name="IncludeGsap" ormtype="boolean" default="false">
	<cfproperty name="IncludeDisqus" ormtype="boolean" default="true">
	<cfproperty name="DefaultMediaPlayer" ormtype="string" length="35" default="Plyr" hint="Either 'Plyr' or 'KendoUi'. Plyr is default.">
	<cfproperty name="GoogleAnalyticsString" ormtype="string"  length="900" default="">
	<cfproperty name="AddThisApiKey" ormtype="string" length="75" default="">
	<cfproperty name="AddThisToolboxString" ormtype="string" length="75" default="">
	<cfproperty name="BingMapsApiKey" ormtype="string" length="100" default="">
	<cfproperty name="AzureMapsApiKey" ormtype="string" length="100" default="">
	<cfproperty name="DisqusBlogIdentifier" ormtype="string" length="75" default="">
	<cfproperty name="DisqusApiKey" ormtype="string" length="75" default="">
	<cfproperty name="DisqusApiSecret" ormtype="string" length="75" default="">
	<cfproperty name="DisqusAuthTokenKey" ormtype="string" length="75" default="">
	<cfproperty name="DisqusAuthUrl" ormtype="string" length="255" default="https://disqus.com/api/oauth/2.0/authorize/">
	<cfproperty name="DisqusAuthTokenUrl" ormtype="string" length="255" default="https://disqus.com/api/oauth/2.0/access_token/">
	<cfproperty name="FacebookAppId" ormtype="string"  length="75" default="">
	<cfproperty name="TwitterAppId" ormtype="string"  length="75" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>