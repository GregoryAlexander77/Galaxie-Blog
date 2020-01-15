<cfcomponent displayName="PostIncludeItem" persistent="true" table="PostIncludeItem" output="no" hint="ORM logic for the new PostIncludeItem table. This is used to allow multiple inline actions, such as using mutliple <includeTemplate>, <includeScript>, <includeImage>, <includeVideo> or <includeFancyBox> tags in the blog post. Each PostInclude in a given post will generate a new row in this table. If a type is found, we will use the PostIncludeItem table that will provde the details for each record in this table.">
	
	<cfproperty name="PostIncludeItemId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many include items for a post. I am not fully normalizing this column as I want to carry this key. --->
	<cfproperty name="Posts" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" singularname="Post" lazy="false" cascade="all">
	<!--- An item is a detail record of the post include --->
	<cfproperty name="PostIncludeRef" ormtype="int" fieldtype="one-to-one" cfc="PostInclude" fkcolumn="PostIncludeRef" cascade="all">
	<!--- includeTemplate vars --->
	<cfproperty name="IncludeTemplatePath" ormtype="string" default="" length="75" hint="The path used in the cfinclude">
	<!--- includeScript vars --->
	<cfproperty name="IncludeScript" ormtype="clob" default="" hint="The javascript without the start and end script tags.">
	<!--- includeImage and video vars --->
	<cfproperty name="includeMediaRef" ormtype="string" hint="The MediaId in the media table. Used when you want to include extra images or videos that are underneath the featured media, which is the top image or video of the post. This should not be used for featured media. The featured media is indicated by the FeaturedMedia column in the Media table when set to true.">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
