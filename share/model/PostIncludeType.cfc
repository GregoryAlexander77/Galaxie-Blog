<cfcomponent displayName="PostIncludeType" persistent="true" table="PostIncludeType" output="no" hint="ORM logic for the new PostIncludeType table. This is used to tie an action to a PostInclude record. Actions can be includeTemplate, includeScript, includeImage, includeVideo, or includeFancyBoxItem.">
	
	<cfproperty name="PostIncludeTypeId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="PostIncludeType" ormtype="string" default="" length="50" hint="The post include type">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
