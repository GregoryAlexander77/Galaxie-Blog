<cfcomponent displayName="SearchQuery" persistent="true" table="SearchQuery" output="no" hint="ORM logic for the new SearchQuery table. This will keep track of all of the search queries made.">
	
	<cfproperty name="SearchQueryId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many searches for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="SearchQuery" ormtype="string" default="" length="255" hint="The search query">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>