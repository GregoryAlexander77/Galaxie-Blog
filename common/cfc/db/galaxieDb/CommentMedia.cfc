<cfcomponent displayName="CommentMedia" persistent="true" table="CommentMedia" output="no" hint="ORM logic for the new CommentMedia table">
	
	<cfproperty name="CommentMediaId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many comments with many media (images and video) --->
	<cfproperty name="CommentRef" ormtype="int" fieldtype="many-to-one" cfc="Comment" fkcolumn="CommentRef" singularname="Post" cascade="all">
	<cfproperty name="MediaRef" ormtype="int" fieldtype="many-to-one" cfc="Media" fkcolumn="MediaRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>