<cfcomponent displayName="RoleCapability" persistent="true" table="RoleCapability" output="no" hint="ORM logic for the new RoleCapability table. This table will map out the capabilities for each role.">
	
	<cfproperty name="RoleCapabilityId" fieldtype="id" generator="native" setter="false">
	<!--- Many capabilities for each blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- Many capabilities for each role. --->
	<cfproperty name="RoleRef" ormtype="int" fieldtype="many-to-one" cfc="Role" fkcolumn="RoleRef" cascade="all">
	<cfproperty name="CapabilityRef"  ormtype="int" fieldtype="many-to-one" cfc="Capability" fkcolumn="CapabilityRef" cascade="all">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
