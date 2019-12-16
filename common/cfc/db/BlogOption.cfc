<cfcomponent displayName="BlogOption" persistent="true" table="BlogOption" output="no" hint="ORM logic for the new BlogOption table">
	
	<cfproperty name="BlogOptionId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="one-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="IncludeGsap" ormtype="boolean" default="false">
	<cfproperty name="IncludeDisqus" ormtype="boolean" default="true">
	<cfproperty name="DeferScriptsAndCss" ormtype="boolean" default="true">
	<cfproperty name="UseSsl" ormtype="boolean" default="false">
	<cfproperty name="DefaultMediaPlayer" ormtype="text" default="Plyr" hint="Either 'Plyr' or 'KendoUi'. Plyr is default.">
	<cfproperty name="DefaultLogoImageForSocialMediaShare" ormtype="text" default="Plyr" hint="The default image that will be used when sharing a post to social media when an enclosure was not made.">
	<cfproperty name="BackgroundImageResolution" ormtype="text" default="LowRes" hint="Either 'HiRes', 'MedRes', or 'LowRes'. LowRes is default.">
	<cfproperty name="AddThisToolboxString" ormtype="text" default="">
	<cfproperty name="DisqusBlogIdentifier" ormtype="text" default="">
	<cfproperty name="DisqusApiSecret" ormtype="text" default="">
	<cfproperty name="DisqusAuthTokenKey" ormtype="text" default="">
	<cfproperty name="DisqusAuthUrl" ormtype="text" default="https://disqus.com/api/oauth/2.0/authorize/">
	<cfproperty name="DisqusAuthTokenUrl" ormtype="text" default="https://disqus.com/api/oauth/2.0/access_token/">
	<cfproperty name="DisqusApiKey" ormtype="text" default="">
	<cfproperty name="FacebookAppId" ormtype="text" default="">
	<cfproperty name="TwitterAppId" ormtype="text" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>