<cfcomponent displayName="StructuredData" persistent="true" table="StructuredData" output="no" hint="ORM logic for the new StructuredData table. This is used to populate our ld json script.">
	
	<cfproperty name="StructuredDataId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many structured data blocks for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- However, there should be only one structured data block for one post. --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" singularname="Post" lazy="false" cascade="all">
	<!--- There is only one type per include. --->
	<cfproperty name="StructuredDataTypeRef" ormtype="int" fieldtype="one-to-one" cfc="StructuredDataType" fkcolumn="StructuredDataTypeRef" cascade="all">
	<!--- There is only one main entity of page type. --->
	<cfproperty name="mainEntityOfPageTypeRef" ormtype="int" fieldtype="one-to-one" cfc="mainEntityOfPageType" fkcolumn="mainEntityOfPageTypeRef"  cascade="all" hint="Supported types are blog, blogPosting, and article.">
	<cfproperty name="mainEntityOfPageUrl" ormtype="string" default="" length="255" hint="This will be either the canonical link or a link to the article.">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>