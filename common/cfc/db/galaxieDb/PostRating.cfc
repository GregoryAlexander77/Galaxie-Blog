<cfcomponent displayName="PostRating" persistent="true" table="PostRating" output="no" hint="ORM logic for the new PostRating table. This can handle boolean like/dislikes, or a rating system">
	
	<cfproperty name="PostRatingId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many posts with a reaction --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all">
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all">
	<cfproperty name="AnonymousUserRef" ormtype="int" fieldtype="many-to-one" cfc="AnonymousUser" fkcolumn="AnonymousUserRef" cascade="all">
	<cfproperty name="Helpful" ormtype="boolean">
	<cfproperty name="Unhelpful" ormtype="boolean">
	<cfproperty name="Rating" ormtype="integer">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>