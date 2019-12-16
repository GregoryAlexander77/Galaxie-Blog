<cfcomponent displayName="PostInclude" persistent="true" table="PostInclude" output="no" hint="ORM logic for the new PostInclude table. This is used to allow multiple inline actions, such as using mutliple <includeTemplate>, <includeScript>, or <includeFancyBox> tags in the blog post. Each PostInclude in a given post will generate a new row in this table. If a type is found, we will use the PostIncludeItem table that will provde the details for each record in this table.">
	
	<cfproperty name="PostIncludeId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="PostRef" ormtype="many-to-one" cfc="Post" fkcolumn="PostId">
	<cfproperty name="PostIncludeTypeRef" ormtype="one-to-one" cfc="PostIncludeType" fkcolumn="PostIncludeTypeId"hint="The action that you want to blog to undertake. Can be includeTemplate, includeScript, includeImage, includeVideo, or includeFancyBoxItem. Each type will have it's own row that is associated with the post. The includeTemplate will use a cfinclude when it encounters the tag, the includeScript will attach a javascript to the post, and the includeFancyBox will include a fancy box widget.">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>