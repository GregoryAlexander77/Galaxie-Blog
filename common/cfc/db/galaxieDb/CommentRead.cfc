<cfcomponent displayName="CommentRead" persistent="true" table="CommentRead" output="no" hint="ORM logic for the new CommentRead table">
	
	<cfproperty name="CommentReadId" fieldtype="id" generator="native" setter="false">
	<!--- A comment can only be read once --->
	<cfproperty name="CommentRef" ormtype="int" fieldtype="one-to-one" cfc="Comment" fkcolumn="CommentRef" cascade="all">
	<!--- A user (and a commenter) can read many comments --->
	<cfproperty name="UserRef" ormtype="int" fieldtype="one-to-many" cfc="Users" fkcolumn="UserRef" cascade="all">
	<cfproperty name="CommenterRef" ormtype="int" fieldtype="one-to-many" cfc="Commenter" fkcolumn="CommenterRef" cascade="all">
	<cfproperty name="CommentRead" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>