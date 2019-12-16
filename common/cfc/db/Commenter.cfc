<cfcomponent displayName="Commenter" persistent="true" table="Commenter" output="no" hint="ORM logic for the new Commenter table">
	
	<cfproperty name="CommenterId" fieldtype="id" generator="increment">
	<cfproperty name="UserRef" ormtype="many-to-one" cfc="User" fkcolumn="UserId">
	<cfproperty name="FirstName" ormtype="text" default="">
	<cfproperty name="LastName" ormtype="text" default="">
	<cfproperty name="FullName" ormtype="text" default="">
	<cfproperty name="Email" ormtype="text" default="">
	<cfproperty name="Website" ormtype="text" default="">
	<cfproperty name="IpAddress" ormtype="text" default="">
	<cfproperty name="UserAgent" ormtype="text" default="">
	<cfproperty name="Banned" ormtype="boolean" default="false">
	<cfproperty name="ShadowBanned" ormtype="boolean" default="false">
	<cfproperty name="TemporaryBan" ormtype="boolean" default="false">
	<cfproperty name="BanDateStart" ormtype="timestamp" default="">
	<cfproperty name="BanDateEnd" ormtype="timestamp" default="false">
	<cfproperty name="HideComments" ormtype="boolean" default="false">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>