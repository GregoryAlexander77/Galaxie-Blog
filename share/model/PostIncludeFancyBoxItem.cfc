<cfcomponent displayName="PostIncludeFancyBoxItem" persistent="true" table="PostIncludeFancyBoxItem" output="no" hint="ORM logic for the new PostIncludeFancyBoxItem table. This table will have multiple records for each PostInclude record. Each record will be an individual fancy box thing.">
	
	<cfproperty name="PostIncludeFancyBoxItemId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many fancy box items for each post --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostId" cascade="all">
	<!--- There can be many fancy box items for include --->
	<cfproperty name="PostIncludeRef" ormtype="int" fieldtype="many-to-one" cfc="PostInclude" fkcolumn="PostIncludeId" cascade="all">
	<cfproperty name="FancyBoxGroup" ormtype="string" default="" length="50" hint="The fancy box group.">
	<cfproperty name="FancyBoxTitle" ormtype="string" default="" length="125" hint="The title of the fancybox thing">
	<cfproperty name="FancyBoxThumbNailUrl" ormtype="string" default="" length="255" hint="The path used for the thumbnail">
	<cfproperty name="FancyBoxImagerl" ormtype="string" default="" length="255" hint="The path used for the large image once the thumbnail has been clicked.">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>

