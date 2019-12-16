<cfcomponent displayName="PostIncludeType" persistent="true" table="PostIncludeType" output="no" hint="ORM logic for the new PostIncludeType table. This is used to tie an action to a PostInclude record. Actions can be includeTemplate, includeScript, includeImage, includeVideo, or includeFancyBoxItem.">
	
	<cfproperty name="PostIncludeTypeId" fieldtype="id" generator="increment">
	<cfproperty name="PostIncludeRef" ormtype="one-to-one" cfc="PostInclude" fkcolumn="PostIncludeId">
	<cfproperty name="PostIncludeType" ormtype="text" default="" hint="The post include type, such as ">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
