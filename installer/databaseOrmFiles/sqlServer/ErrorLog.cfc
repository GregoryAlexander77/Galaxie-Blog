<cfcomponent displayName="ErrorLog" persistent="true" table="ErrorLog" output="no" hint="ORM logic for the new ErrorLog table. Tracks errors caught in a global onError in the Application.cfc">
	
	<cfproperty name="ErrorLogId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="ErrorURL" ormtype="string" default="" length="250">
	<cfproperty name="ErrorEvent" ormtype="string" default="" length="125">
	<cfproperty name="ErrorType" ormtype="string" default="" length="125">
	<cfproperty name="ErrorMessage" ormtype="string" default="" length="500">
	<cfproperty name="ErrorDetail" ormtype="string" default="" length="1500">
	<cfproperty name="ErrorTemplate" ormtype="string" default="" length="500" hint="This string can get quite large">
	<cfproperty name="ErrorLine" ormtype="string" default="" length="7">
	<cfproperty name="Stacktrace" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="DiagnosticsSent" ormtype="boolean" default="false">
	<cfproperty name="NumErrors" ormtype="integer" default="1">
	<cfproperty name="Resolved" ormtype="boolean" default="false">
	<cfproperty name="ResolutionNotes" ormtype="string" default="" length="2500"> 
	<cfproperty name="Date" ormtype="timestamp" default="">
		
</cfcomponent>