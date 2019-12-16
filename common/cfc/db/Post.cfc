<cfcomponent displayName="Post" persistent="true" table="Post" output="no" hint="ORM logic for the new Post table">
	
	<cfproperty name="PostId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="one-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="ThemeRef" ormtype="one-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="PostUuid" ormtype="text" default="">
	<cfproperty name="PostAlias" ormtype="text" default="">
	<cfproperty name="Title" ormtype="text" default="">
	<cfproperty name="Body" ormtype="text" default="">
	<cfproperty name="MoreBody" ormtype="text" default="">
	<cfproperty name="AllowComment" ormtype="boolean" default="true">
	<cfproperty name="NumViews" ormtype="int" default="">
	<cfproperty name="Released" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>