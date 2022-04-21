<cfcomponent displayName="Capability" persistent="true" table="Capability" output="no" hint="ORM logic for the new Capability table. A given role has many capabilities">
	
	<cfproperty name="CapabilityId" fieldtype="id" generator="native" setter="false">
	<!--- Note: the role capability relationship should already be defined and the relationship is between RoleCapability.CapabilityRef and Capability.CapabilityId --->
	<!--- Many capabilities for each blog. --->
	<!---'org.hibernate.MappingException: Capability refers to an unmapped class' error with two blogs
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">--->
	<cfproperty name="CapabilityUuid" ormtype="string" default="" length="50">
	<cfproperty name="CapabilityName" ormtype="string" default="" length="50">
	<cfproperty name="CapabilityUiLabel" ormtype="string" default="" length="75">
	<cfproperty name="CapabilityDescription" ormtype="string" default="" length="125">
	<cfproperty name="Date" ormtype="timestamp">
		
</cfcomponent>
