<cfcomponent displayName="PostCategoryLookup" persistent="true" table="PostCategoryLookup" output="no" hint="ORM logic for the new PostCategoryLookup table">
	
	<cfproperty name="PostCategoryLookupId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many posts and categories --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" singularname="Post" cascade="all">
	<cfproperty name="CategoryRef" ormtype="int" fieldtype="many-to-one" cfc="Category" fkcolumn="CategoryRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>