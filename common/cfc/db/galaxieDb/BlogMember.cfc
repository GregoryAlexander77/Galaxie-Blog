<cfcomponent displayName="BlogMember" persistent="true" table="BlogMember" output="no" hint="(Not called Member: MEMBER is a reserved word in Hibernate's query language.) A visitor with a member account (2026-10-15). Members are NOT admin users: they have no role, no capabilities and never reach the admin site. They sign in with a one-time link emailed to them (no passwords). Their bookings, sign-ups and subscriptions are matched by email address. See common/cfc/Members.cfc.">

	<cfproperty name="MemberId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<!--- Lower case, one account per address per blog. --->
	<cfproperty name="Email" ormtype="string" length="255" default="">
	<cfproperty name="EmailVerified" ormtype="boolean" default="false">
	<cfproperty name="Name" ormtype="string" length="125" default="">
	<cfproperty name="Phone" ormtype="string" length="50" default="">
	<!--- An IANA time zone (eg. America/Los_Angeles), used to show booking times. --->
	<cfproperty name="TimeZone" ormtype="string" length="64" default="">
	<!--- active or blocked (a blocked member can't sign in). --->
	<cfproperty name="Status" ormtype="string" length="20" default="active">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="LastSeen" ormtype="timestamp">

</cfcomponent>
