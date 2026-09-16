<cfcomponent displayName="AnonymousUser" persistent="true" table="AnonymousUser" output="no" hint="ORM logic for the new AnonymousUser table. Anonymous users are unique visitors that have an IP and User agent string">
	
	<cfproperty name="AnonymousUserId" fieldtype="id" generator="native" setter="false">
	<!--- There are many anon users for one blog, etc... --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">	
	<!--- Many errors to one unique anonymous user. Stores the IP address and other user information --->
	<cfproperty name="AnonymousUserRef" ormtype="int" fieldtype="many-to-one" cfc="AnonymousUser" fkcolumn="AnonymousUserRef" cascade="all">
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all" missingRowIgnored="true" hint="An anonymous user can also be a Galaxie Blog admin with a user record that is not yet logged in.">	
	<cfproperty name="IpAddressRef" ormtype="int" fieldtype="many-to-one" cfc="IpAddress" fkcolumn="IpAddressRef" cascade="all" missingRowIgnored="true">
	<cfproperty name="HttpUserAgentRef" ormtype="int" fieldtype="many-to-one" cfc="HttpUserAgent" fkcolumn="HttpUserAgentRef" cascade="all" missingRowIgnored="true">
	<cfproperty name="IsBot" ormtype="boolean" default="false">
	<cfproperty name="HitCount" ormtype="int" default="0">
	<cfproperty name="ScreenHeight" ormtype="int" default="0">
	<cfproperty name="ScreenWidth" ormtype="int" default="0">
	<cfproperty name="Note" ormtype="string" default="" length="255">
	<cfproperty name="Date" ormtype="timestamp"> 

</cfcomponent>