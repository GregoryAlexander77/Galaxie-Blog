<cfcomponent displayName="Media" persistent="true" table="Media" output="no" hint="ORM logic for the new Media table, can be an image or a video.">
	
	<cfproperty name="MediaId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many images and videos for a post --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all" missingrowignored="true">
	<!--- Many images can have one mime type (if you have many-to-one you'll recive a 'Cannot insert duplicate key in object 'dbo.Media'. The duplicate key value is (11).' error ')--->
	<cfproperty name="MimeTypeRef" ormtype="int" fieldtype="many-to-one" cfc="MimeType" fkcolumn="MimeTypeRef" cascade="all" missingrowignored="true">
	<cfproperty name="FeaturedMedia" ormtype="boolean" hint="Is this an image or video that should be at the top of a blog post?" default="false">
	<cfproperty name="MediaPath" ormtype="string" length="255" default="">
	<cfproperty name="MediaUrl" ormtype="string" length="255" default="">
	<cfproperty name="MediaTitle" ormtype="string" length="255" default="" hint="Also used for the alt tag.">
	<cfproperty name="MediaWidth" ormtype="string" length="25" default="">
	<cfproperty name="MediaHeight" ormtype="string" length="25" default="">
	<cfproperty name="MediaSize" ormtype="string" length="25" default="">
	<cfproperty name="MediaVideoDuration" ormtype="string" length="25"  default="" hint="Used for video types">
	<cfproperty name="MediaVideoCoverUrl" ormtype="string" length="255" default="" hint="The image URL to cover the video. Used for video types">
	<cfproperty name="MediaVideoSubTitleUrl" ormtype="string" length="255"  default="" hint="The URL to the subtitle file. Used for video types">
	<cfproperty name="Date" ormtype="timestamp" default="" >

</cfcomponent>