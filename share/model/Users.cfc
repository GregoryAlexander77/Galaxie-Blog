<cfcomponent displayName="Users" persistent="true" table="Users" output="no" hint="ORM logic for the new Users table">
	
	<cfproperty name="UserId" fieldtype="id" generator="native" setter="false">
	<!--- Many users per blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="FirstName" ormtype="string" default="" length="125">
	<cfproperty name="LastName" ormtype="string" default="" length="125">
	<cfproperty name="FullName" ormtype="string" default="" length="255">
	<cfproperty name="Email" ormtype="string" default="" length="255">
	<cfproperty name="Website" ormtype="string" default="" length="255">
	<cfproperty name="IpAddress" ormtype="string" default="" length="255">
	<cfproperty name="UserAgent" ormtype="string" default="" length="255">
	<cfproperty name="UserName" ormtype="string" default="" length="20">
	<cfproperty name="Password" ormtype="string" default="" length="255">
	<cfproperty name="Salt" ormtype="string" default="" length="255">
	<cfproperty name="LastLogin" ormtype="timestamp" default="">
	<cfproperty name="Active" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp" default="">

</cfcomponent>