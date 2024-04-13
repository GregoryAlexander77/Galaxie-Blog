<cfcomponent displayName="PostTagLookup" persistent="true" table="PostTagLookup" output="no" hint="ORM logic for the new PostTagLookup table">
	
	<cfproperty name="PostTagLookupId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many posts and categories --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" singularname="Post" cascade="all">
	<cfproperty name="TagRef" ormtype="int" fieldtype="many-to-one" cfc="Tag" fkcolumn="TagRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>