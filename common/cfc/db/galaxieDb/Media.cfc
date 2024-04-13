<cfcomponent displayName="Media" persistent="true" table="Media" output="no" hint="ORM logic for the new Media table, can be an image or a video.">
	
	<cfproperty name="MediaId" fieldtype="id" generator="native" setter="false">
	<!--- Many media can have one media type. Do not use a cascade argument here as it causes errors when a media gallery is uploaded. According to Adobe, cascade should not be used with many-to-one relationships. --->
	<cfproperty name="MediaTypeRef" ormtype="int" fieldtype="many-to-one" cfc="MediaType" fkcolumn="MediaTypeRef" missingrowignored="true">
	<!--- Many media can have one mime type. For the same reasons as the MediaTypeRef, don't use a cascade here. --->
	<cfproperty name="MimeTypeRef" ormtype="int" fieldtype="many-to-one" cfc="MimeType" fkcolumn="MimeTypeRef" missingrowignored="true">
	<cfproperty name="MediaFileName" ormtype="string" length="75" default="">
	<cfproperty name="MediaPath" ormtype="string" length="255" default="">
	<cfproperty name="MediaUrl" ormtype="string" length="255" default="">
	<cfproperty name="MediaThumbnailUrl" ormtype="string" length="255" default="">
	<cfproperty name="MediaTitle" ormtype="string" length="255" default="" hint="Also used for the alt tag.">
	<cfproperty name="MediaWidth" ormtype="string" length="25" default="">
	<cfproperty name="MediaHeight" ormtype="string" length="25" default="">
	<cfproperty name="MediaSize" ormtype="string" length="25" default="">
	<cfproperty name="FacebookOptimized" ormtype="boolean" default="0" hint="Media optimized for Facebook sharing">
	<cfproperty name="TwitterOptimized" ormtype="boolean" default="0" hint="Media optimized for Twitter sharing">
	<cfproperty name="GoogleOptimized" ormtype="boolean" default="0" hint="Media optimized for Google sharing">
	<!--- Video properties (note: video data should be broken out into new Video tables in the next version) --->
	<cfproperty name="MediaVideoDuration" ormtype="string" length="25"  default="" hint="The length of the video">
	<cfproperty name="MediaVideoCoverUrl" ormtype="string" length="255" default="" hint="The image URL to cover the video. Used for video types">
	<cfproperty name="MediaVideoVttFileUrl" ormtype="string" length="255"  default="" hint="The URL to the subtitle file. Used for video types">
	<cfproperty name="ProviderVideoId" ormtype="string" length="25" default="" hint="It is difficult to extract the proper YouTube and VimeoId's from a URL on the server side as the logic is constantly changing. Instead, I am using javascript libraries that are maintained on GIT to extract the ID's and saving them to the database.">
	<cfproperty name="Date" ormtype="timestamp" default="" >

</cfcomponent>