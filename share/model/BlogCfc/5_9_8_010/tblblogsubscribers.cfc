<cfcomponent displayName="tblblogsubscribers" persistent="true" table="tblblogsubscribers" output="no">
	
	<cfproperty name="email" ormtype="string" length="50" fieldtype="id">
	<cfproperty name="token" ormtype="string" length="35">
	<cfproperty name="blog" ormtype="string" length="50">
	<cfproperty name="verified" ormtype="boolean">

</cfcomponent>