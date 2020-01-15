<cfcomponent displayName="PostInclude" persistent="true" table="PostInclude" output="no" hint="ORM logic for the new PostInclude table. This is used to allow multiple inline actions, such as using mutliple <includeTemplate>, <includeScript>, or <includeFancyBox> tags in the blog post. Each PostInclude in a given post will generate a new row in this table. If a type is found, we will use the PostIncludeItem table that will provde the details for each record in this table.">
	
	<cfproperty name="PostIncludeId" fieldtype="id" generator="native" setter="false">
	<!--- Many includes can be made for a single post --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all" missingrowignored="true">
	<!--- There can only be one include type for each include --->
	<cfproperty name="PostIncludeTypeRef" ormtype="int" fieldtype="one-to-one" cfc="PostIncludeType" fkcolumn="PostIncludeTypeRef" cascade="all" hint="The action that you want to blog to undertake. Can be includeTemplate, includeScript, includeMedia, or includeFancyBoxItem. Each type will have it's own row that is associated with the post. The includeTemplate will use a cfinclude when it encounters the tag, the includeScript will attach a javascript to the post, and the includeFancyBox will include a fancy box widget.">>
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>