<cfcomponent displayName="PostMedia" persistent="true" table="PostMedia" output="no" hint="ORM logic for the new PostMedia table">
	
	<cfproperty name="PostMediaId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many posts with associated media (images and video) --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all">
	<cfproperty name="MediaRef" ormtype="int" fieldtype="many-to-one" cfc="Media" fkcolumn="MediaRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>