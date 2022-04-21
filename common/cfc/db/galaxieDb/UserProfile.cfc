<!--- Not used
<cfcomponent displayName="UserProfile" persistent="true" table="UserProfile" output="no" hint="ORM logic for the new UserProfile table">
	
	<cfproperty name="UserProfileId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">	
	<cfproperty name="UserRef" ormtype="int" fieldtype="one-to-one" cfc="Users" fkcolumn="UserId" cascade="all">
	<cfproperty name="MediaRef" ormtype="int" fieldtype="one-to-one" cfc="Media" fkcolumn="MediaRef" cascade="all">
	<cfproperty name="DisplayName" ormtype="string" default="" length="225">
	<cfproperty name="Website" ormtype="string" default="" length="255">
	<cfproperty name="Biography" sqltype="long" default="">
	<cfproperty name="Status" ormtype="string" default="" length="255">
	<cfproperty name="Date" ormtype="timestamp" default="">

</cfcomponent>--->