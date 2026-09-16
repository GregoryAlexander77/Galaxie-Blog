<cfcomponent displayName="Subscriber" persistent="true" table="Subscriber" output="no" hint="ORM logic for the new Subscriber table">
	
	<cfproperty name="SubscriberId" fieldtype="id" generator="native" setter="false">
	<!--- Many subscribers to one blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Stores the IP address and other user information. --->
	<cfproperty name="AnonymousUserRef" ormtype="int" fieldtype="many-to-one" cfc="AnonymousUser" fkcolumn="AnonymousUserRef" missingrowignored="true">
	<!--- Psuedo column that will not be placed into the actual database. We are using the PostSubscriber table as an intermediatory table to store the many to many relationships between a post and a subscriber.  --->
	<cfproperty name="SubscriberPosts" singularname="SubscriberPost" ormtype="int" fieldtype="many-to-many" cfc="Post" fkcolumn="SubscriberRef" inversejoincolumn="PostRef" inverse="true" linktable="PostSubscriber" type="array" cascade="all" missingRowIgnored="true">
	<cfproperty name="SubscriberEmail" ormtype="string" length="255" default="">
	<cfproperty name="SubscriberToken" ormtype="string" length="35" default="" hint="">
	<cfproperty name="SubscriberVerified" ormtype="boolean" default="false">
	<cfproperty name="SubscribeAll" ormtype="boolean" default="false">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>