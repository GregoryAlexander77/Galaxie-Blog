<cfcomponent displayName="BlogOption" persistent="true" table="BlogOption" output="no" hint="ORM logic for the new BlogOption table">
	
	<cfproperty name="BlogOptionId" fieldtype="id" generator="native" setter="false">
	<!--- There are many blog options for every blog record. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="DefaultThemeRef" ormtype="int" fieldtype="one-to-one" cfc="Theme" fkcolumn="DefaultThemeRef" cascade="all" missingRowIgnored="true">
	<cfproperty name="KendoCommercial" ormtype="boolean" default="false">
	<cfproperty name="IncludeGsap" ormtype="boolean" default="false">
	<cfproperty name="IncludeDisqus" ormtype="boolean" default="true">
	<cfproperty name="DeferScriptsAndCss" ormtype="boolean" default="true">
	<cfproperty name="UseSsl" ormtype="boolean" default="true">
	<cfproperty name="ServerRewriteRuleInPlace" ormtype="boolean" default="false">	
	<cfproperty name="DefaultMediaPlayer" ormtype="string" length="35" default="Plyr" hint="Either 'Plyr' or 'KendoUi'. Plyr is default.">
	<cfproperty name="DefaultLogoImageForSocialMediaShare" length="255" ormtype="string" default="Plyr" hint="The default image that will be used when sharing a post to social media when an enclosure was not made.">
	<cfproperty name="BackgroundImageResolution" ormtype="string" length="35" default="LowRes" hint="Either 'HiRes', 'MedRes', or 'LowRes'. LowRes is default.">
	<cfproperty name="AddThisApiKey" ormtype="string" length="75" default="">
	<cfproperty name="AddThisToolboxString" ormtype="string" length="75" default="">
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