<cfcomponent displayName="Login" persistent="true" table="Login" output="no" hint="ORM logic for the new Login table">
	
	<cfproperty name="LoginId" fieldtype="id" generator="native" setter="false">
	<!--- There are many logins addresses for a blog --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many logins for a user --->
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all" missingRowIgnored="true">
	<!--- Many IP's for a login --->
	<cfproperty name="IpAddressRef" ormtype="int" fieldtype="many-to-one" cfc="IpAddress" fkcolumn="IpAddressRef" cascade="all" missingRowIgnored="true">
	<!--- Many user agent strings for a login --->
	<cfproperty name="HttpUserAgentRef" ormtype="int" fieldtype="many-to-one" cfc="HttpUserAgent" fkcolumn="HttpUserAgentRef" cascade="all" missingRowIgnored="true">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>