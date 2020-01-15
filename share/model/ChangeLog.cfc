<cfcomponent displayName="ChangeLog" persistent="true" table="ChangeLog" output="no" hint="ORM logic for the new ChangeLog table">
	
	<cfproperty name="ChangeLogId" fieldtype="id" generator="native" setter="false">
	<!--- Many posts for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="ChangeLogTypeRef" ormtype="int" fieldtype="many-to-one" cfc="ChangeLogType" fkcolumn="ChangeLogTypeRef" cascade="all">
	<cfproperty name="ChangeLog" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="ChangeLogDesc" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="ChangeLogError" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="Success" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>