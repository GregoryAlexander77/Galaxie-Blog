<cfcomponent displayName="ChangeLogType" persistent="true" table="ChangeLogType" output="no" hint="ORM logic for the new ChangeLogType table">
	
	<cfproperty name="ChangeLogTypeId" fieldtype="id" generator="native" setter="false">
	<!--- Many posts for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="ChangeLogType" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="ChangeLogTypeDesc" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>