<cfcomponent displayName="MediaPlatformType" persistent="true" table="MediaPlatformType" output="no" hint="ORM logic for the new MediaPlatformType table. Media is often prepared for certain social media sites, such as Facebook, Twitter, and Google.">
	
	<cfproperty name="MediaPlatformTypeId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="MediaPlatformType" ormtype="string" default="" length="50" hint="The media platform type, ie Facebook or Twitter">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>