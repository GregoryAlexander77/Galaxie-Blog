<!--- description: Galaxie 5.02: makes the Privacy page (linked from every footer) and the Email Log table. --->
<!--- The Privacy page (Privacy.cfc) is also made the first time the admin home opens, but on gregoryalexander.com and galaxieblog.org
(10-31) that didn't happen until a later visit, and the footer had no Privacy link until then. Updating the database is a step every
upgrade takes, signed in, so the page is made here too. A page already titled Privacy is used as it is. A failure here is logged and
never stops the update; the admin home tries again. --->
<cftry>
	<cfset application.blog.getPrivacy().ensurePage(val(session.userId ?: 0))>
	<cfset addToLog("Privacy page: " & application.blog.getPrivacy().getPageUrl())>
	<cfcatch type="any">
		<cflog file="galaxieBlogErrors" type="warning" text="Privacy page not made (5.02 update): #cfcatch.message#">
		<cfset addToLog("The Privacy page wasn't made (#cfcatch.message#); opening the admin home will try again.")>
	</cfcatch>
</cftry>
<!--- The Email Log table (EmailLog.cfc) makes itself on first use; reading it once makes it now. --->
<cfset application.blog.getEmailLog().getRows()>
