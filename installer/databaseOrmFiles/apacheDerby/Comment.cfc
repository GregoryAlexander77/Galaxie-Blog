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
	<!--- There is no relationship for the ParentCommentRef. We will have to use this programmatically. --->
	<cfproperty name="ParentCommentRef" ormtype="int">
	<!--- The CommentAssets column below is a psuedo column that is used by this object. The CommentMedia table is our link table. There are many comments with many different types of media (images and video) --->
	<cfproperty name="CommentAssets" singularname="CommentAsset" ormtype="int" fieldtype="one-to-many" cfc="CommentMedia" fkcolumn="CommentRef" inversejoincolumn="MediaRef" cascade="all" inverse="true" missingRowIgnored="true">
	<cfproperty name="CommentUuid" ormtype="string" default="">
	<!--- This is configured for Derby. Manually change the clob property if you use another db --->
	<cfproperty name="Comment" ormtype="clob" default="">
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