<cfcomponent displayName="Category" persistent="true" table="Category" output="no" hint="ORM logic for the new Category table">
	
	<cfproperty name="CategoryId" fieldtype="id" generator="native" setter="false">
	<!--- Many categories for one blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- This is a psuedo column used by the object that will not be placed into the actual databae. We are using the PostCategoryLookup table as an intermediatory table to store the many to many relationsships between a post and a category. This is different than all of the other relationship types. --->
	<cfproperty name="Posts" singularname="Post" ormtype="int" fieldtype="many-to-many" cfc="Post" fkcolumn="CategoryRef" inversejoincolumn="PostRef" linktable="PostCategoryLookup" type="array" cascade="all" inverse="true" missingRowIgnored="true">
	<cfproperty name="CategoryUuid" ormtype="string"  length="75" default="">
	<cfproperty name="CategoryAlias" ormtype="string"  length="75" default="">
	<cfproperty name="Category" ormtype="string"  length="125" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>