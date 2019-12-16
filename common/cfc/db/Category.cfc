<cfcomponent displayName="Category" persistent="true" table="Category" output="no" hint="ORM logic for the new Category table">
	
	<cfproperty name="CategoryId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="CategoryUuid" ormtype="text" default="">
	<cfproperty name="CategoryAlias" ormtype="text" default="">
	<cfproperty name="Category" ormtype="text" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>