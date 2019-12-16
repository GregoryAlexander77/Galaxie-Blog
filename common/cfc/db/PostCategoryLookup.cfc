<cfcomponent displayName="PostCategoryLookup" persistent="true" table="PostCategoryLookup" output="no" hint="ORM logic for the new PostCategoryLookup table">
	
	<cfproperty name="PostCategoryLookupId" fieldtype="id" generator="increment">
	<cfproperty name="PostRef" ormtype="many-to-one" cfc="Post" fkcolumn="PostId">
	<cfproperty name="CategoryRef" ormtype="many-to-one" cfc="Category" fkcolumn="CategoryId">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>