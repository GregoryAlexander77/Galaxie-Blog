<cfcomponent displayName="MimeType" persistent="true" table="MimeType" output="no" hint="ORM logic for the new MimeType table">
	
	<cfproperty name="MimeTypeId" fieldtype="id" generator="native" setter="false">
	<!--- The Media column below is a psuedo column that is used by this object. It will not be placed into the database, but it will be used to create a pointer to the MimeType column in the media table. This is the inverse of the actual foreign key in the Media table. --->
	<cfproperty name="Assets" ormtype="int" fieldtype="one-to-many" cfc="Media" fkcolumn="MimeTypeRef" cascade="all" inverse="true" missingRowIgnored="true">
	<cfproperty name="MimeType" ormtype="string" default="" length="25" hint="The mime type">
	<cfproperty name="Extension" ormtype="string" default="" length="25" hint="The mime type extension">
	<cfproperty name="Description" ormtype="string" default="" length="25" hint="The mime type description">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>