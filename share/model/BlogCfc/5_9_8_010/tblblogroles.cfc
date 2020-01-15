<cfcomponent displayName="tblblogroles" persistent="true" table="tblblogroles" output="no">
	
	<cfproperty name="id" ormtype="string" length="35" fieldtype="id">
	<cfproperty name="role" ormtype="string" length="50">
	<cfproperty name="description" ormtype="string" length="255">

</cfcomponent>