<cfcomponent displayName="Blog" persistent="true" table="Blog" output="no" hint="ORM logic for the new Blog table">
	
	<cfproperty name="BlogId" fieldtype="id" generator="increment">
	<cfproperty name="BlogName" ormtype="text" length="35">
	<cfproperty name="BlogTitle" ormtype="text" length="75">
	<cfproperty name="BlogUrl" ormtype="text" length="255">
	<cfproperty name="BlogDescription" ormtype="text" length="255">
	<cfproperty name="BlogParentSiteName" ormtype="text" length="255">
	<cfproperty name="BlogParentSiteUrl" ormtype="text" length="255">
	<cfproperty name="BlogDsn" ormtype="text" length="255">
	<cfproperty name="BlogDsnPassword" ormtype="text" length="255">
	<cfproperty name="BlogMailServer" ormtype="text" length="255">
	<cfproperty name="BlogMailServerName" ormtype="text" length="255">
	<cfproperty name="BlogMailServerPassword" ormtype="text" length="255">
	<cfproperty name="BlogEmail" ormtype="text" length="255">
	<cfproperty name="isProd" ormtype="boolean">
	<cfproperty name="BlogInstalled" ormtype="boolean">
	<cfproperty name="BlogInstallDate" ormtype="timestamp">

</cfcomponent>