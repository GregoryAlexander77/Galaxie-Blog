<cfcomponent displayName="PostIncludeItem" persistent="true" table="PostIncludeItem" output="no" hint="ORM logic for the new PostIncludeItem table. This is used to allow multiple inline actions, such as using mutliple <includeTemplate>, <includeScript>, <includeImage>, <includeVideo> or <includeFancyBox> tags in the blog post. Each PostInclude in a given post will generate a new row in this table. If a type is found, we will use the PostIncludeItem table that will provde the details for each record in this table.">
	
	<cfproperty name="PostIncludeItemId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="PostRef" ormtype="many-to-one" cfc="Post" fkcolumn="PostId">
	<cfproperty name="PostIncludeRef" ormtype="one-to-one" cfc="PostInclude" fkcolumn="PostIncludeId">
	<!--- includeTemplate vars --->
	<cfproperty name="IncludeTemplatePath" ormtype="text" default="" hint="The path used in the cfinclude">
	<!--- includeScript vars --->
	<cfproperty name="IncludeScript" ormtype="text" default="" hint="The javascript without the start and end script tags.">
	<!--- includeImage vars --->
	<cfproperty name="includeImageUrl" ormtype="text" default="" hint="The full path of the image.">
	<cfproperty name="includeImageAlt" ormtype="text" default="" hint="The alt description of the image.">
	<!--- includeVideo vars --->
	<cfproperty name="includeVideoUrl" ormtype="text" default="" hint="The full path of the video.">
	<cfproperty name="includeVideoImageCoverUrl" ormtype="text" default="" hint="The full path of the image that is used to cover the video while loading.">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
