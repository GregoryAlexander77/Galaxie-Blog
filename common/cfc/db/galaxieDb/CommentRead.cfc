<cfcomponent displayName="CommentRead" persistent="true" table="CommentRead" output="no" hint="ORM logic for the new CommentRead table">
	
	<cfproperty name="CommentReadId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many posts with associated media (images and video) --->
	<cfproperty name="CommentRef" ormtype="int" fieldtype="many-to-one" cfc="Comment" fkcolumn="CommentRef" cascade="all">
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all">
	<cfproperty name="AnonymousUserRef" ormtype="int" fieldtype="many-to-one" cfc="AnonymousUser" fkcolumn="AnonymousUserRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>