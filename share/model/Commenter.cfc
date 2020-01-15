<cfcomponent displayName="Commenter" persistent="true" table="Commenter" output="no" hint="ORM logic for the new Commenter table">
	
	<cfproperty name="CommenterId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="FirstName" ormtype="string" length="125" default="">
	<cfproperty name="LastName" ormtype="string"  length="125" default="">
	<cfproperty name="FullName" ormtype="string" length="255" default="">
	<cfproperty name="Email" ormtype="string" length="150" default="">
	<cfproperty name="Website" ormtype="string" length="255" default="">
	<cfproperty name="IpAddress" ormtype="string" length="30" default="">
	<cfproperty name="HttpUserAgent" ormtype="string" length="500" default="">
	<cfproperty name="Banned" ormtype="boolean" default="false">
	<cfproperty name="ShadowBanned" ormtype="boolean" default="false">
	<cfproperty name="TemporaryBan" ormtype="boolean" default="false">
	<cfproperty name="BanDateStart" ormtype="timestamp" default="">
	<cfproperty name="BanDateEnd" ormtype="timestamp" default="">
	<cfproperty name="HideComments" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>