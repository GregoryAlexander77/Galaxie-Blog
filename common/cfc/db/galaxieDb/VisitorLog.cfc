<cfcomponent displayName="VisitorLog" persistent="true" table="VisitorLog" output="no" hint="ORM logic for the new VisitorLog table">
	
	<cfproperty name="VisitorLogId" fieldtype="id" generator="native" setter="false">
	<!--- There are many log records for a blog... --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- There are many log records with one user --->
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" missingRowIgnored="true">
	<!--- There are many log records for one anonymous users --->
	<cfproperty name="AnonymousUserRef" ormtype="int" fieldtype="many-to-one" cfc="AnonymousUser" fkcolumn="AnonymousUserRef">
	<!--- There are many log records with one HTTP Referrer --->
	<cfproperty name="HttpReferrerRef" fieldtype="many-to-one" cfc="HttpReferrer" fkcolumn="HttpReferrerRef" missingRowIgnored="true">
	<!--- There are many log records with one post --->
	<cfproperty name="PostRef" ormtype="int" fieldtype="many-to-one" cfc="Post" fkcolumn="PostRef" missingRowIgnored="true">
	<cfproperty name="Date" ormtype="timestamp"> 

</cfcomponent>