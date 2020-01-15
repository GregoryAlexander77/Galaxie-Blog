<cfcomponent displayName="tblblogcategories" persistent="true" table="tblblogcategories" output="no" hint="Original table in BlocCfc version 5.9.08.010">
	
	<cfproperty name="ormId" fieldtype="id" generator="native">
	<cfproperty name="categoryid" ormtype="string" fieldtype="id" length="35">
	<cfproperty name="categoryname" ormtype="string" length="50">
	<cfproperty name="categoryalias" ormtype="string" length="50">
	<cfproperty name="blog" ormtype="string" length="50">
		
</cfcomponent>
