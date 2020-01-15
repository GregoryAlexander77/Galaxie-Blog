<cfcomponent displayName="tbluserroles" persistent="true" table="tbluserroles" output="no">
	
	<cfproperty name="username" ormtype="string" length="50" fieldtype="id">
	<cfproperty name="password" ormtype="string" length="256">
	<cfproperty name="salt" ormtype="string" length="256">
	<cfproperty name="name" ormtype="string" length="50">
	<cfproperty name="blog" ormtype="string" length="255">

</cfcomponent>