<cfcomponent displayName="tblblogentries" persistent="true" table="tblblogentries" output="no" hint="Original table in BlocCfc version 5.9.08.010">
	
	<cfproperty name="id" ormtype="string" fieldtype="id" length="35">
	<cfproperty name="title" ormtype="string" length="100">
	<cfproperty name="body" ormtype="clob">
	<cfproperty name="posted" ormtype="timestamp">
	<cfproperty name="morebody" ormtype="clob">
	<cfproperty name="alias" ormtype="string" length="100">
	<cfproperty name="username" ormtype="string" length="50">
	<cfproperty name="blog" ormtype="timestamp" length="50">
	<cfproperty name="allowcomments" ormtype="boolean" length="50">
	<cfproperty name="enclosure" ormtype="string" length="255">
	<cfproperty name="filesize" ormtype="int">
	<cfproperty name="mimetype" ormtype="string" length="255">
	<cfproperty name="views" ormtype="int">
	<cfproperty name="released" ormtype="boolean">
	<cfproperty name="mailed" ormtype="boolean">
	<cfproperty name="summary" ormtype="string" length="255">
	<cfproperty name="subtitle" ormtype="string" length="100">
	<cfproperty name="keywords" ormtype="string" length="100">
	<cfproperty name="duration" ormtype="string" length="10">
		
</cfcomponent>
