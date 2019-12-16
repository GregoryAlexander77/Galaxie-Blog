<cfcomponent displayName="CommentRead" persistent="true" table="CommentRead" output="no" hint="ORM logic for the new CommentRead table">
	
	<cfproperty name="CommentReadId" fieldtype="id" generator="increment">
	<cfproperty name="Comment" ormtype="many-to-one" cfc="Comment" fkcolumn="CommentId">
	<cfproperty name="UserRef" ormtype="many-to-one" cfc="User" fkcolumn="UserId">
	<cfproperty name="CommenterRef" ormtype="many-to-one" cfc="Commenter" fkcolumn="CommenterId">
	<cfproperty name="CommentRead" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>