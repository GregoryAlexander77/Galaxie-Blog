<cfcomponent displayName="MemberSetting" persistent="true" table="MemberSetting" output="no" hint="Member accounts settings for a blog (2026-10-15): whether visitors can sign in, and how long 'Keep me signed in' lasts. One row per blog; edited in Blog Options > Member Accounts. See common/cfc/Members.cfc and doc/aiDraftArticles/memberAccountsDesign.cfm.">

	<cfproperty name="MemberSettingId" fieldtype="id" generator="native" setter="false">
	<cfproperty name="BlogRef" ormtype="int" default="0">
	<!--- Off by default: nothing changes for visitors until the owner turns member accounts on. --->
	<cfproperty name="Enabled" ormtype="boolean" default="false">
	<!--- Days a 'Keep me signed in' cookie lasts. --->
	<cfproperty name="RememberDays" ormtype="int" default="30">
	<cfproperty name="Created" ormtype="timestamp">
	<cfproperty name="Updated" ormtype="timestamp">

</cfcomponent>
