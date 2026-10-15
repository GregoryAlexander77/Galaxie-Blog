<cfcomponent displayName="MemberLoginToken" persistent="true" table="MemberLoginToken" output="no" hint="A one-time sign-in link sent to a member (2026-10-15). Only a SHA-256 hash of the token is kept; the token itself is only in the email. It works once, for 15 minutes. See common/cfc/Members.cfc.">

	<cfproperty name="MemberLoginTokenId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<cfproperty name="TokenHash" ormtype="string" length="64" default="">
	<cfproperty name="Email" ormtype="string" length="255" default="">
	<!--- signIn for now; verifyEmail later (eg. changing the address). --->
	<cfproperty name="Purpose" ormtype="string" length="20" default="signIn">
	<cfproperty name="Expires" ormtype="timestamp">
	<cfproperty name="Used" ormtype="boolean" default="false">
	<cfproperty name="RequestIp" ormtype="string" length="64" default="">
	<cfproperty name="Created" ormtype="timestamp">

</cfcomponent>
