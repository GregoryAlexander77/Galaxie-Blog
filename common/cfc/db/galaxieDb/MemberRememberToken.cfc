<cfcomponent displayName="MemberRememberToken" persistent="true" table="MemberRememberToken" output="no" hint="'Keep me signed in' for a member (2026-10-15): a random token in an HttpOnly cookie, kept here only as a SHA-256 hash. Removed by Sign out (that browser), Sign out everywhere (all of them) and deleting the account. See common/cfc/Members.cfc.">

	<cfproperty name="MemberRememberTokenId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="MemberRef" ormtype="int" default="0">
	<cfproperty name="TokenHash" ormtype="string" length="64" default="">
	<cfproperty name="Expires" ormtype="timestamp">
	<!--- Shown in the account so a member can recognise their devices. --->
	<cfproperty name="UserAgent" ormtype="string" length="255" default="">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="LastUsed" ormtype="timestamp">

</cfcomponent>
