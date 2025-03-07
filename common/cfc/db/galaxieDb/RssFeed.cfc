<cfcomponent displayName="RssFeed" persistent="true" table="RssFeed" output="no" hint="ORM logic for the new RssFeed table">
	
	<cfproperty name="RssFeedId" fieldtype="id" generator="native" setter="false">
	<!--- Many Pages for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Psuedo column that will not be placed into the actual database. We are using the PostRssFeed table as an intermediatory table to store the many to many relationships between a post and a RSS feed. We are not using the category and tag tables here as this is already available when selecting posts for an rss feed --->
	<cfproperty name="Posts" singularname="Post" ormtype="int" fieldtype="many-to-many" cfc="Post" fkcolumn="RssFeedRef" inversejoincolumn="PostRef" linktable="PostRssFeed" type="array" cascade="all" inverse="true" missingRowIgnored="true">	
	
	<cfproperty name="RssFeedName" ormtype="string" length="155" default="">
	<cfproperty name="RssFeedDescription" ormtype="string" length="250" default="">
	<cfproperty name="RssFeedUrl" ormtype="string" length="250" default="">
	<cfproperty name="Active" ormtype="boolean" default="false">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date" default="">

</cfcomponent>