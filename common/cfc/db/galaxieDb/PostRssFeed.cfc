<cfcomponent displayName="PostRssFeed" persistent="true" table="PostRssFeed" output="no" hint="ORM logic for the new PostRssFeed table">
	
	<cfproperty name="PostRssFeedId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many posts and categories --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" singularname="Post" cascade="all">
	<cfproperty name="RssFeedRef" ormtype="int" fieldtype="many-to-one" cfc="RssFeed" fkcolumn="RssFeedRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>