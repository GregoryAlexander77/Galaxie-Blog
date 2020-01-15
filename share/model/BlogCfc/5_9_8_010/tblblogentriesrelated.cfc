<cfcomponent displayName="tblblogentriesrelated" persistent="true" table="tblblogentriesrelated" output="no">
	
	<cfproperty name="entryid" ormtype="string" length="35" fieldtype="id">
	<cfproperty name="relatedid" ormtype="string" length="35">

</cfcomponent>