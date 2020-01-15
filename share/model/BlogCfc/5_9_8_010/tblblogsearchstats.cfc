<cfcomponent displayName="tblblogsearchstats" persistent="true" table="tblblogsearchstats" output="no">
	
	<cfproperty name="searchterm" ormtype="string" length="255" fieldtype="id">
	<cfproperty name="searched" ormtype="timestamp">
	<cfproperty name="blog" ormtype="string" length="50">

</cfcomponent>