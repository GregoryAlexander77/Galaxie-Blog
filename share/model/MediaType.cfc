<cfcomponent displayName="MediaType" persistent="true" table="MediaType" output="no" hint="ORM logic for the new MediaType table. This table is a generic table that allows us to specify the intent of the image, such as a Twitter Large Card image, or a Google 4x3 image, etc.">
	
	<cfproperty name="MediaTypeId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="MediaType" ormtype="string" default="" length="25" hint="The media type.">
	<cfproperty name="Description" ormtype="string" default="" length="25" hint="The media type description">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>