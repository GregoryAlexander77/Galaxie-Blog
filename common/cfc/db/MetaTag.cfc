<cfcomponent displayName="MetaTag" persistent="true" table="MetaTag" output="no" hint="ORM logic for the new MetaTag table. The MetaTag table stores meta tag names and values.">
	
	<cfproperty name="MetaTagId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="PostRef" ormtype="one-to-one" cfc="Post" fkcolumn="PostId">
	<cfproperty name="Title" ormtype="text" default="" hint="The meta tag value for the title, twitter:title and og:title">
	<cfproperty name="Description" ormtype="text" default="" hint="The meta tag value for the description, twitter:description and og:description">
	<cfproperty name="Keywords" ormtype="boolean" default="false">
	<cfproperty name="Canonical" ormtype="text" default="" hint="The cannonical link as well as the og:url">
	<cfproperty name="Robots" ormtype="boolean" default="false">
	<cfproperty name="TwitterAppId" ormtype="text" default="" hint="Optonal twitter App Id">
	<cfproperty name="TwitterCard" ormtype="text" default="" hint="Specifies a value for the twitter:card meta tag">
	<cfproperty name="TwitterSite" ormtype="text" default="" hint="Specifies a value for the twitter:site meta tag">
	<cfproperty name="TwitterCard" ormtype="text" default="" hint="Specifies a value for the twitter:card meta tag">
	<cfproperty name="TwitterImage" ormtype="text" default="" hint="Specifies a value for the twitter:image meta tag">
	<cfproperty name="TwitterPlayer" ormtype="text" default="" hint="The value of the twitter:player when video is present">
	<cfproperty name="FbAppId" ormtype="text" default="" hint="Optonal Facebook App Id">
	<cfproperty name="OpenGraphSiteName" ormtype="text" default="" hint="The value of the og:site_name">
	<cfproperty name="OpenGraphImage" ormtype="text" default="" hint="The value of the og:image when video is present">
	<cfproperty name="OpenGraphType" ormtype="text" default="" hint="The og:type will be 'video.movie' when video is present">
	<cfproperty name="OpenGraphType" ormtype="text" default="" hint="The og:type will be 'video.movie' when video is present">
	<cfproperty name="VideoUrl" ormtype="text" default="" hint="The URL to the video. Populates the og:video, og:video:url and og:video:secure_url">	
	<cfproperty name="VideoWidth" ormtype="text" default="" hint="Populates the twitter:player:width and og:video:width">
	<cfproperty name="VideoHeight" ormtype="text" default="" hint="Populates the twitter:player:height and og:video:height">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>