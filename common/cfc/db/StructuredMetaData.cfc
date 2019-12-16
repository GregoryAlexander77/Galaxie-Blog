<cfcomponent displayName="StructuredData" persistent="true" table="StructuredData" output="no" hint="ORM logic for the new StructuredData table. This is used to populate our ld json script.">
	
	<cfproperty name="StructuredDataId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="PostRef" ormtype="one-to-one" cfc="Post" fkcolumn="PostId">
	<cfproperty name="StructuredDataType" ormtype="text" default="" hint="The schema.org type. Currently supported values are blog and article.">
	<cfproperty name="mainEntityOfPageType" ormtype="text" default="" hint="Supported types are blog, blogPosting, and article. The first two values are used when the page is in blog mode, and the article is used when in post mode.">
	<cfproperty name="mainEntityOfPageUrl" ormtype="text" default="" hint="This will be either the canonical link or a link to the article.">
	<cfproperty name="StructuredDataHeadline" ormtype="text" default="" hint="A very brief headline. If this is not specified, we'll use the description. Used for articles.">
	<cfproperty name="BlogLogoUrl" ormtype="text" default="" hint="Path to the organization's logo image. Used for articles.">
	<cfproperty name="BlogPostImageUrl16By9" ormtype="text" default="" hint="The URL to the 16x9 post blog image if available. Used for articles.">
	<cfproperty name="BlogPostImageUrl14By3" ormtype="text" default="" hint="The URL to the 16x9 post blog image if available. Used for articles.">
	<cfproperty name="BlogPostImageUrl11By1" ormtype="text" default="" hint="The URL to the 16x9 post blog image if available. Used for articles.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>