<cfcomponent displayName="RelatedPost" persistent="true" table="RelatedPost" output="no" hint="ORM logic for the new RelatedPost table. This is used to indicate the related posts within the forum.">
	
	<cfproperty name="RelatedPostId" fieldtype="id" generator="native" setter="false">
	<!--- There are many related posts for one post --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all" lazy="false">
	<!--- There is one related post that we are pointing to --->
	<cfproperty name="RelatedPostRef" ormtype="int" fieldtype="one-to-one" cfc="Post" fkcolumn="RelatedPostRef" cascade="all" lazy="false">  
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
