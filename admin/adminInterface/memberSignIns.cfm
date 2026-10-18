<!--- Member sign-ins (window 105, 2026-10-17, owner): every time a member signed in - like the admin log for admin users - with
their picture and name (opening their page in Members), IP address, browser, how they signed in and when. In a grid - Kendo when
Kendo Professional is loaded, jsGrid otherwise (includes/grids/kendo|jsGrid/memberSignIns.cfm). Opened from Members (all) or a
member's page with createAdminInterfaceWindow(105, memberId). Data: ProxyController.cfc getMemberSignInsForGrid ->
Members.cfc getSignInsForAdmin. --->
<cfset signInsMemberId = isValid("integer", URL.optArgs) ? val(URL.optArgs) : 0>
<cfset signInsMember = signInsMemberId gt 0 ? application.members.getMember(signInsMemberId) : {}>
<p><cfoutput><cfif not structIsEmpty(signInsMember)>Every time #encodeForHtml(len(signInsMember.name) ? signInsMember.name : signInsMember.email)# signed in, newest first.<cfelse>Every time a member signed in, newest first.</cfif> Members sign in with a link the blog emails them. The last 10000 sign-ins are shown.</cfoutput></p>
<cfif application.kendoCommercial>
	<cfinclude template="../../includes/grids/kendo/memberSignIns.cfm">
<cfelse>
	<cfinclude template="../../includes/grids/jsGrid/memberSignIns.cfm">
</cfif>
