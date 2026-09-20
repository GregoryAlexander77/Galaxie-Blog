<cfcomponent displayName="PostRead" persistent="true" table="PostRead" output="no" hint="ORM logic for the new PostRead table">
	
	<cfproperty name="PostReadId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many posts with associated media (images and video) --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all">
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all">
	<cfproperty name="AnonymousUserRef" ormtype="int" fieldtype="many-to-one" cfc="AnonymousUser" fkcolumn="AnonymousUserRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>