<cfcomponent displayName="tbluserroles" persistent="true" table="tbluserroles" output="no">
	
	<cfproperty name="username" ormtype="string" length="50" fieldtype="id">
	<cfproperty name="roleidfk" ormtype="string" length="35">
	<cfproperty name="blog" ormtype="string" length="50">

</cfcomponent>