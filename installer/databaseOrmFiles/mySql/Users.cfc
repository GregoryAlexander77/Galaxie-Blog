<cfcomponent displayName="Users" persistent="true" table="Users" output="no" hint="ORM logic for the new Users table">
	
	<cfproperty name="UserId" fieldtype="id" generator="native" setter="false">
	<!--- Many users per blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- A psuedo column to extract the user roles. --->
	<cfproperty name="UserRoles" singularname="UserRole" ormtype="int" fieldtype="one-to-many" cfc="UserRole" fkcolumn="UserRef" type="array" cascade="all" inverse="true" missingRowIgnored="true">
	<cfproperty name="MediaRef" ormtype="int" fieldtype="many-to-one" cfc="Media" fkcolumn="MediaRef" cascade="all">
	<cfproperty name="UserToken" ormtype="string" length="35" default="" hint="">
	<cfproperty name="FirstName" ormtype="string" default="" length="125">
	<cfproperty name="LastName" ormtype="string" default="" length="125">
	<cfproperty name="FullName" ormtype="string" default="" length="255">
	<cfproperty name="DisplayName" ormtype="string" default="" length="225">
	<cfproperty name="Email" ormtype="string" default="" length="255">
	<cfproperty name="Website" ormtype="string" default="" length="255">
	<!--- The ProfileBody can be HTML that creates a page. --->
	<!--- This is configured for MySql. Manually change this property if you use another db --->
	<cfproperty name="Biography" ormtype="text" sqltype="longtext" default="">
	<cfproperty name="Status" ormtype="string" default="" length="255">
	<!--- An email can be used as the user name. Authentication may be broken out into a new table eventually. --->
	<cfproperty name="UserName" ormtype="string" default="" length="255">
	<cfproperty name="Password" ormtype="string" default="" length="255">
	<cfproperty name="TemporaryPassword" ormtype="string" default="" length="255">
	<cfproperty name="ChangePasswordOnLogin" ormtype="boolean" default="false">
	<!--- The generic security questions are: favororite pet, favorite place, favorite childhood friend, and a random question. These are only used when requesting a forgotten password. --->
	<cfproperty name="SecurityAnswer1" ormtype="string" default="" length="125">
	<cfproperty name="SecurityAnswer2" ormtype="string" default="" length="125">
	<cfproperty name="SecurityAnswer3" ormtype="string" default="" length="125">
	<!--- The random security question allows the user to create a random key pair for extra security. --->
	<cfproperty name="SecurityRandomQuestion" ormtype="string" default="" length="125">
	<cfproperty name="SecurityRandomAnswer" ormtype="string" default="" length="35">
	<cfproperty name="Salt" ormtype="string" default="" length="255">
	<cfproperty name="LastLogin" ormtype="timestamp" default="">
	<cfproperty name="Active" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp" default="">

</cfcomponent>