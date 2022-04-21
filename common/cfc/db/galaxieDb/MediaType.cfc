<cfcomponent displayName="MediaType" persistent="true" table="MediaType" output="no" hint="ORM logic for the new MediaType table. This table is a generic table that allows us to specify the intent of the image, such as a Twitter Large Card image, or a Google 4x3 image, etc.">
	
	<cfproperty name="MediaTypeId" fieldtype="id" generator="native" setter="false">
	<!--- The Media column below is a psuedo column that is used by this object. It will not be placed into the database, but it will be used to create a pointer to the MimeType column in the media table. This is the inverse of the actual foreign key in the Media table. --->
	<cfproperty name="Media" ormtype="int" fieldtype="one-to-many" cfc="Media" fkcolumn="MediaTypeRef" cascade="all" inverse="true" missingRowIgnored="true">
	<cfproperty name="MediaTypeStrId" ormtype="string" default="" length="50" hint="A short string identifier (ie static).">
	<cfproperty name="MediaType" ormtype="string" default="" length="75" hint="The media type.">
	<cfproperty name="Description" ormtype="string" default="" length="225" hint="The media type description">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>