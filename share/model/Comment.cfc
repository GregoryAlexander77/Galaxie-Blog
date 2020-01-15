<cfcomponent displayName="Comment" persistent="true" table="Comment" output="no" hint="ORM logic for the new Comment table">
	
	<cfproperty name="CommentId" fieldtype="id" generator="native" setter="false">
	<!--- Many comments for one blog --->
	<!--- There is one blog for every blog option record. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many comments for one post --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all">
	<!--- Many comments for one User --->
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all" missingrowignored="true" >
	<!--- Many comments for one commenter --->
	<cfproperty name="CommenterRef" ormtype="int" fieldtype="many-to-one" cfc="Commenter" fkcolumn="CommenterRef" cascade="all" missingrowignored="true" >
	<!--- There is no relationshiop for the ParentCommentRef. We will have to use this programmatically. --->
	<cfproperty name="ParentCommentRef" ormtype="int">
	<cfproperty name="CommentUuid" ormtype="string" default="">
	<cfproperty name="Comment" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="DatePosted" ormtype="timestamp">
	<cfproperty name="Subscribe" ormtype="boolean" default="false">
	<cfproperty name="Moderated" ormtype="boolean" default="false">
	<cfproperty name="Approved" ormtype="boolean" default="false">
	<cfproperty name="Promote" ormtype="boolean" default="false">
	<cfproperty name="Hide" ormtype="boolean" default="false">
	<cfproperty name="Spam" ormtype="boolean" default="false">
	<cfproperty name="Remove" ormtype="boolean" default="false">
	<cfproperty name="CommentOrder" ormtype="int">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>