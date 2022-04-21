<cfcomponent displayName="Blog" persistent="true" table="Blog" output="no" hint="ORM logic for the new Blog table">
	
	<cfproperty name="BlogId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogName" ormtype="string" length="50" default="">
	<cfproperty name="BlogTitle" ormtype="string" length="75" default="">
	<cfproperty name="BlogUrl" ormtype="string" length="255" default="">
	<cfproperty name="BlogDescription" ormtype="string" length="255" default="">
	<cfproperty name="BlogMetaKeywords" ormtype="string" length="255" default="">
	<cfproperty name="BlogParentSiteName" ormtype="string" length="255" default="">
	<cfproperty name="BlogParentSiteUrl" ormtype="string" length="255" default="">
	<cfproperty name="BlogLocale" ormtype="string" length="75" default="">
	<cfproperty name="BlogTimeZone" ormtype="string" length="125" default="America/Los_Angeles" hint="Use a java time zone sting that displays the proper time zone for the blog. Generally, this is where the person or business is located. This may be different than where the server resides.">
	<cfproperty name="BlogServerTimeZone" ormtype="string" length="125" default="America/Los_Angeles" hint="Use a java time zone sting that displays the server's time zone. This may be different than where the server time zone.">
	<cfproperty name="BlogServerTimeZoneOffset" ormtype="int" default="0">
	<cfproperty name="BlogDsn" ormtype="string" length="75" default="">
	<cfproperty name="BlogDatabaseType" ormtype="string" length="75" default="">
	<cfproperty name="BlogDsnUserName" ormtype="string" length="75" default="">
	<cfproperty name="BlogDsnPassword" ormtype="string" length="75" default="">
	<cfproperty name="BlogMailServer" ormtype="string" length="125" default="">
	<cfproperty name="BlogMailServerUserName" ormtype="string" length="75" default="">
	<cfproperty name="BlogMailServerPassword" ormtype="string" length="75" default="">
	<cfproperty name="BlogEmailFailToAddress" ormtype="string" length="75" default="">
	<cfproperty name="BlogEmail" ormtype="string" length="125" default="">
	<cfproperty name="CcEmailAddress" ormtype="string" length="125" default="">
	<!--- This works for both SQL Server and MariaDb --->
	<cfproperty name="IpBlockList" ormtype="string" length="2000" default="">
	<cfproperty name="SaltAlgorithm" ormtype="string" length="255" default="">
	<cfproperty name="SaltAlgorithmSize" ormtype="string" length="255" default="">
	<cfproperty name="HashAlgorithm" ormtype="string" length="255" default="">
	<cfproperty name="ServiceKeyEncryptionPhrase" ormtype="string" length="255" default="">
	<cfproperty name="BlogVersion" ormtype="string" default="3">
	<cfproperty name="BlogVersionName" ormtype="string" default="Galaxie Blog 3.0" length="30">
	<cfproperty name="BlogVersionDate" ormtype="timestamp" default="">
	<cfproperty name="IsProd" ormtype="boolean" default="true">
	<cfproperty name="BlogInstalled" ormtype="boolean" default="false">
	<cfproperty name="BlogInstallDate" ormtype="timestamp" default="">
	<cfproperty name="Date" ormtype="timestamp" default="">
		
	<!--- Foreign keys. ---> 
	<!--- One blog to to one options (everything is stored in one row)
	<cfproperty name="BlogBlogOption" fieldtype="one-to-one" cfc="BlogOption" fkcolumn="BlogRef"> --->
	<!--- One Blog to to many Categories 
	<cfproperty name="BlogCategory" fieldtype="one-to-many" cfc="Category" fkcolumn="CategoryRef">--->
	<!--- One Blog to to many Comments 
	<cfproperty name="BlogComment" fieldtype="one-to-one" cfc="Comment" fkcolumn="CommentRef">--->
	<!--- One Blog to to one meta tag 
	<cfproperty name="BlogComment" fieldtype="one-to-one" cfc="Comment" fkcolumn="CommentRef">--->

</cfcomponent>