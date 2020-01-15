<cfcomponent displayName="tblblogcomments" persistent="true" table="tblblogcomments" output="no" hint="Original table in BlocCfc version 5.9.08.010">
	
	<cfproperty name="id" ormtype="string" fieldtype="id" length="35">
	<cfproperty name="entryidfk" ormtype="string" length="35">
	<cfproperty name="name" ormtype="string" length="50">
	<cfproperty name="email" ormtype="string" length="50">
	<cfproperty name="comment" ormtype="string" length="50">
	<cfproperty name="posted" ormtype="timestamp" length="50">
	<cfproperty name="subscribe" ormtype="boolean" length="50">
	<cfproperty name="website" ormtype="string" length="50">
	<cfproperty name="moderate" ormtype="boolean" length="50">
	<cfproperty name="subscribeonly" ormtype="boolean" length="50">
	<cfproperty name="killcomment" ormtype="boolean" length="50">
		
</cfcomponent>
