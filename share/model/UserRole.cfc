<cfcomponent displayName="UserRole" persistent="true" table="UserRole" output="no" hint="ORM logic for the new UserRole table. This Provides the role of the logged in user.">
	
	<cfproperty name="UserRoleId" fieldtype="id" generator="native" setter="false">
	<!--- Many roles for each blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many user roles for each user. --->
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all">
	<!--- Many user roles for each role. --->
	<cfproperty name="RoleRef" ormtype="int" fieldtype="many-to-one" cfc="Role" fkcolumn="RoleRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
