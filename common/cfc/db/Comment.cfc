<cfcomponent displayName="Comment" persistent="true" table="Comment" output="no" hint="ORM logic for the new Comment table">
	
	<cfproperty name="CommentId" fieldtype="id" generator="increment">
	<cfproperty name="BlogRef" ormtype="many-to-one" cfc="Blog" fkcolumn="BlogId">
	<cfproperty name="PostRef" ormtype="many-to-one" cfc="Post" fkcolumn="PostId">
	<cfproperty name="UsersRef" ormtype="many-to-one" cfc="Users" fkcolumn="UserId">
	<cfproperty name="CommenterRef" ormtype="many-to-one" cfc="Commenter" fkcolumn="CommenterId">
	<cfproperty name="ParentCommentRef" ormtype="int">
	<cfproperty name="CommentUuid" ormtype="text" default="">
	<cfproperty name="Comment" ormtype="text" default="">
	<cfproperty name="DatePosted" ormtype="timestamp">
	<cfproperty name="Preview" ormtype="boolean" default="false">
	<cfproperty name="Subscribe" ormtype="boolean" default="false">
	<cfproperty name="Approved" ormtype="boolean" default="false">
	<cfproperty name="Promote" ormtype="boolean" default="false">
	<cfproperty name="Hide" ormtype="boolean" default="false">
	<cfproperty name="Spam" ormtype="boolean" default="false">
	<cfproperty name="Remove" ormtype="boolean" default="false">
	<cfproperty name="CommentOrder" ormtype="int">
	<cfproperty name="DatePosted" ormtype="timestamp">

</cfcomponent>