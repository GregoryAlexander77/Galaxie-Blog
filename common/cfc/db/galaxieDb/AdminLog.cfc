<cfcomponent displayName="AdminLog" persistent="true" table="AdminLog" output="no" hint="ORM logic for the new AdminLog table">
	
	<cfproperty name="AdminLogId" fieldtype="id" generator="native" setter="false">
	<!--- There are many http referrers for a blog... --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all" missingRowIgnored="true">
	<!--- The anonymous user table stores IP addresses, http user agents and http referrer strings. --->
	<cfproperty name="AnonymousUserRef" ormtype="int" fieldtype="many-to-one" cfc="AnonymousUser" fkcolumn="AnonymousUserRef" cascade="all"  missingRowIgnored="true">
	<cfproperty name="Date" ormtype="timestamp"> 

</cfcomponent>