<cfcomponent displayName="HttpUserAgent" persistent="true" table="HttpUserAgent" output="no" hint="ORM logic for the new HttpUserAgent table">
	
	<cfproperty name="HttpUserAgentId" fieldtype="id" generator="native" setter="false">
	<!--- There are many IP addresses for a blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="HttpUserAgent" ormtype="string" length="500" default="">
	<cfproperty name="Date" ormtype="timestamp"> 

</cfcomponent>