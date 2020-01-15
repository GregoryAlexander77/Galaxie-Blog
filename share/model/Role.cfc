<cfcomponent displayName="Role" persistent="true" table="Role" output="no" hint="ORM logic for the new UserRole table. This Provides the role of the logged in user.">
	
	<cfproperty name="RoleId" fieldtype="id" generator="native" setter="false">
	<!--- Many roles for each blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="RoleUuid" ormtype="string" default="" length="35">
	<cfproperty name="Role" ormtype="string" default="" length="50">
	<cfproperty name="Description" ormtype="string" default="" length="125">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
