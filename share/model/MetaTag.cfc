<cfcomponent displayName="MetaTag" persistent="true" table="MetaTag" output="no" hint="ORM logic for the new MetaTag table. The MetaTag table stores meta tag names and values.">
	
	<cfproperty name="MetaTagId" fieldtype="id" generator="native" setter="false">
	<!--- A blog can only have one Meta Tag record. --->
	<!--- There is one blog for every blog option record. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="one-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- A post can only have one Meta Tag record. --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="one-to-one" cfc="Post" fkcolumn="PostRef" singularname="Post" lazy="false" cascade="all">
	<cfproperty name="Title" ormtype="string" length="100" default="" hint="The meta tag value for the title, twitter:title and og:title">
	<cfproperty name="Description" ormtype="string" length="255" default="" hint="The meta tag value for the description, twitter:description and og:description">
	<cfproperty name="Keywords" ormtype="string" default="" length="255" >
	<cfproperty name="Canonical" ormtype="string" default="" length="255" hint="The cannonical link as well as the og:url">
	<cfproperty name="Robots" ormtype="boolean" default="false" length="255">
	<cfproperty name="TwitterAppId" ormtype="string" default="" length="50" hint="Optonal twitter App Id">
	<cfproperty name="TwitterCard" ormtype="string" default="" length="50" hint="Specifies a value for the twitter:card meta tag">
	<cfproperty name="TwitterSite" ormtype="string" default="" length="255" hint="Specifies a value for the twitter:site meta tag">
	<cfproperty name="TwitterImage" ormtype="string" default="" length="255" hint="Specifies a value for the twitter:image meta tag">
	<cfproperty name="TwitterPlayer" ormtype="string" default="" length="50" hint="The value of the twitter:player when video is present">
	<cfproperty name="FbAppId" ormtype="string" default="" length="50" hint="Optonal Facebook App Id">
	<cfproperty name="OpenGraphSiteName" ormtype="string" default="" length="255" hint="The value of the og:site_name">
	<cfproperty name="OpenGraphImage" ormtype="string" default="" length="255" hint="The value of the og:image when video is present">
	<cfproperty name="OpenGraphType" ormtype="string" default="" length="50" hint="The og:type will be 'video.movie' when video is present">
	<cfproperty name="VideoUrl" ormtype="string" default="" length="255" hint="The URL to the video. Populates the og:video, og:video:url and og:video:secure_url">	
	<cfproperty name="VideoWidth" ormtype="string" default="" length="25" hint="Populates the twitter:player:width and og:video:width">
	<cfproperty name="VideoHeight" ormtype="string" default="" length="25" hint="Populates the twitter:player:height and og:video:height">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>