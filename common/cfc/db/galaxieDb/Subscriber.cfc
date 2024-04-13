<cfcomponent displayName="Subscriber" persistent="true" table="Subscriber" output="no" hint="ORM logic for the new Subscriber table">
	
	<cfproperty name="SubscriberId" fieldtype="id" generator="native" setter="false">
	<!--- Many subscribers to one blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many subscribers to one post. This may be set to null when the user is subscribing to the entire blog. --->
	<!---<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" lazy="false" cascade="all" missingrowignored="true">--->
	<cfproperty name="PostRef" ormtype="int" default="0">
	<cfproperty name="SubscriberEmail" ormtype="string" length="255" default="">
	<cfproperty name="SubscriberToken" ormtype="string" length="35" default="" hint="">
	<cfproperty name="SubscriberVerified" ormtype="boolean" default="false">
	<cfproperty name="SubscribeAll" ormtype="boolean" default="false">
	<cfproperty name="Active" ormtype="boolean" default="true">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>