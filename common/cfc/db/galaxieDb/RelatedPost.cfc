<cfcomponent displayName="RelatedPost" persistent="true" table="RelatedPost" output="no" hint="ORM logic for the new RelatedPost table. This is used to indicate the related posts within the forum. This is a link table and requires special handling. See note below.">
	<!--- Note: this is a link table and should not have any types of relationships (ie. fieldtype, cfc fkcolumn, etc). As a link table, this entity relationtionship is assumed automatically that it is many-to-many. Using a many-to-many field type argument will cause a 'no link table specified' error. Since there is no defined relationships, we can't use objects here to populate the columns. Instead, we need to use primitive datatypes, in this case, an integer. When you try to use objects to populate the data, you will receive a data mismatch error: 'Error casting an object of type to an incompatible type.' --->
	<cfproperty name="RelatedPostId" fieldtype="id" generator="native" setter="false">
	<!--- There are many related posts many posts --->
	<cfproperty name="PostRef" ormtype="int">
	<!--- The related posts that we are pointing to --->
	<cfproperty name="RelatedPostRef" ormtype="int">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
