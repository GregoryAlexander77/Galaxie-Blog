<cfcomponent displayName="ArticleStructuredData" persistent="true" table="ArticleStructuredData" output="no" hint="ORM logic for the new ArticleStructuredData table. This is used to populate the ld json script for articles.">
	
	<cfproperty name="ArticleStructuredDataId" fieldtype="id" generator="native" setter="false">
	<!--- There is one article structured data for a structured data record --->
	<cfproperty name="StructuredDataRef" ormtype="int" fieldtype="one-to-one" cfc="StructuredData" fkcolumn="StructuredDataRef" cascade="all">
	<cfproperty name="StructuredDataHeadline" ormtype="string" default="" hint="A very brief headline. If this is not specified, we'll use the description.">
	<cfproperty name="BlogLogoUrl" ormtype="string" default="" hint="Path to the organization's logo image. Used for articles.">
	<cfproperty name="CondensedArticleBody" ormtype="clob" default="" hint="The condensed form of the article body">
	<cfproperty name="Google16By9MediaRef" ormtype="int" fieldtype="one-to-one" cfc="Media" fkcolumn="Google16By9MediaRef" cascade="all" hint="The URL to the 16x9 featured blog image if available.">
	<cfproperty name="Google14By3MediaRef" ormtype="int" fieldtype="one-to-one" cfc="Media" fkcolumn="Google14By3MediaRef" cascade="all" hint="The URL to the 4x3 featured blog image if available.">
	<cfproperty name="Google1By1MediaRef" ormtype="int" fieldtype="one-to-one" cfc="Media" fkcolumn="Google1By1MediaRef" cascade="all" hint="The URL to the 1x1 featured blog image if available.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>