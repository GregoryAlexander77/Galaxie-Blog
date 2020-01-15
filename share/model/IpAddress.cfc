<cfcomponent displayName="IpAddress" persistent="true" table="IpAddress" output="no" hint="ORM logic for the new IPAddress table">
	
	<cfproperty name="IpAddressId" fieldtype="id" generator="native" setter="false">
	<!--- There are many themes for a blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all" missingRowIgnored="true">
	<cfproperty name="CommenterRef" ormtype="int" fieldtype="many-to-one" cfc="Commenter" fkcolumn="CommenterRef" cascade="all" missingRowIgnored="true">
	<cfproperty name="IpAddress" ormtype="string" length="25" default="">
	<cfproperty name="HttpUserAgent" ormtype="string" length="500" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>