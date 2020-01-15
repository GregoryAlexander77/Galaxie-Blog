<cfcomponent displayName="Post" persistent="true" table="Post" output="no" hint="ORM logic for the new Post table">
	
	<cfproperty name="PostId" fieldtype="id" generator="native" setter="false">
	<!--- Many posts for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all" >
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all">
	<!--- The Media column below is a psuedo column that is used by this object. It will not be placed into the database, but it will be used to create a pointer to the PostRef column in the media table. This is the inverse of the actual foreign key in the Media table. --->
	<cfproperty name="Assets" ormtype="int" fieldtype="one-to-many" cfc="Media" fkcolumn="PostRef" cascade="all" inverse="true" type="array" missingRowIgnored="true">
	<!--- This is a psuedo column that will not be placed into the actual database. We are using the PostCategoryLookup table as an intermediatory table to store the many to many relationsships between a post and a category. This is different than all of the other relationship types. --->
	<cfproperty name="Categories" singularname="Category" ormtype="int" fieldtype="many-to-many" cfc="Category" fkcolumn="PostRef" inversejoincolumn="CategoryRef" linktable="PostCategoryLookup" type="array" cascade="all" inverse="true" missingRowIgnored="true">
	<!--- A psuedo column to extract the comments. --->
	<cfproperty name="Comments" singularname="Comment" ormtype="int" fieldtype="one-to-many" cfc="Comment" fkcolumn="PostRef" type="array" cascade="all" inverse="true" missingRowIgnored="true">
	<!--- The ThemeRef is optional. I am not going to make a relationship here as it will make a required constraint. --->
	<cfproperty name="ThemeRef" ormtype="int" default="">
	<cfproperty name="PostUuid" ormtype="string" length="35" default="">
	<cfproperty name="PostAlias" ormtype="string" length="100" default="">
	<cfproperty name="Title" ormtype="string" length="125" default="">
	<cfproperty name="Headline" ormtype="string" length="110" default="">
	<cfproperty name="Body"  ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="MoreBody" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="AllowComment" ormtype="boolean" default="true">
	<cfproperty name="NumViews" ormtype="int" default="">
	<cfproperty name="Mailed" ormtype="boolean" default="false">
	<cfproperty name="Released" ormtype="boolean" default="false">
	<cfproperty name="DatePosted" ormtype="timestamp" default="">
	<cfproperty name="Date" ormtype="timestamp" default="">

</cfcomponent>