<cfcomponent displayName="PostIncludeFancyBoxItem" persistent="true" table="PostIncludeFancyBoxItem" output="no" hint="ORM logic for the new PostIncludeFancyBoxItem table. This table will have multiple records for each PostInclude record. Each record will be an individual fancy box thing.">
	
	<cfproperty name="PostIncludeFancyBoxItemId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="PostRef" ormtype="many-to-one" cfc="Post" fkcolumn="PostId">
	<cfproperty name="PostIncludeRef" ormtype="one-to-one" cfc="PostInclude" fkcolumn="PostIncludeId">
	<cfproperty name="FancyBoxGroup" ormtype="text" default="" hint="The fancy box group.">
	<cfproperty name="FancyBoxTitle" ormtype="text" default="" hint="The title of the fancybox thing">
	<cfproperty name="FancyBoxThumbNailUrl" ormtype="text" default="" hint="The path used for the thumbnail">
	<cfproperty name="FancyBoxImagerl" ormtype="text" default="" hint="The path used for the large image once the thumbnail has been clicked.">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

