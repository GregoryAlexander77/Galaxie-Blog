<cfcomponent displayName="Tag" persistent="true" table="Tag" output="no" hint="ORM logic for the new Tag table">
	
	<cfproperty name="TagId" fieldtype="id" generator="native" setter="false">
	<!--- Many categories for one blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- This is a psuedo column used by the object that will not be placed into the actual database. We are using the PostCategoryLookup table as an intermediatory table to store the many to many relationsships between a post and a category. This is different than all of the other relationship types. --->
	<cfproperty name="Posts" singularname="Post" ormtype="int" fieldtype="many-to-many" cfc="Post" fkcolumn="TagRef" inversejoincolumn="PostRef" linktable="PostTagLookup" type="array" cascade="all" inverse="true" missingRowIgnored="true">		
	<cfproperty name="TagUuid" ormtype="string"  length="75" default="">
	<cfproperty name="TagAlias" ormtype="string"  length="75" default="">
	<cfproperty name="Tag" ormtype="string"  length="125" default="">
	<cfproperty name="TagDesc" ormtype="string" length="1250" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>