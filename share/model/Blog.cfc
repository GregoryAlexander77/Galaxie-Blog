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
	<cfproperty name="IpBlockList" sqltype="varchar(max)" default="">
	<cfproperty name="EntriesPerBlogPage" ormtype="int" default="10">
	<cfproperty name="BlogModerated" ormtype="boolean" default="true">
	<cfproperty name="UseCaptcha" ormtype="boolean" default="true">
	<cfproperty name="AllowGravatar" ormtype="boolean" default="true">
	<cfproperty name="SaltAlgorithm" ormtype="string" length="255" default="">
	<cfproperty name="SaltAlgorithmSize" ormtype="string" length="255" default="">
	<cfproperty name="HashAlgorithm" ormtype="string" length="255" default="">
	<cfproperty name="ServiceKeyEncryptionPhrase" ormtype="string" length="255" default="">
	<cfproperty name="BlogFontSize" ormtype="string" length="75">
	<cfproperty name="BlogVersion" ormtype="string" default="1.5" length="30">
	<cfproperty name="BlogVersionDate" ormtype="timestamp" default="">
	<cfproperty name="isProd" ormtype="boolean" default="true">
	<cfproperty name="BlogInstalled" ormtype="boolean" default="false">
	<cfproperty name="BlogInstallDate" ormtype="timestamp" default="">
		
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