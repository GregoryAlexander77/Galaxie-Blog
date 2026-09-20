<cfcomponent displayName="PostSubscriber" persistent="true" table="PostSubscriber" output="no" hint="ORM logic for the new PostSubscriber table">
	
	<cfproperty name="PostSubscriberId" fieldtype="id" generator="native" setter="false">
	<!--- There can be many posts with associated media (images and video) --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" cascade="all">
	<cfproperty name="SubscriberRef" ormtype="int" fieldtype="many-to-one" cfc="Subscriber" fkcolumn="SubscriberRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>