<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
	An event as a calendar file (2026-10-15): the Download .ics button on the event card (common/cfc/Events.cfc renderCard).
	Only for a released post that has an event; anything else is a 404.
--->
<cfparam name="url.postId" default="">
<cfif not isValid("integer", url.postId) or url.postId lte 0>
	<cfheader statuscode="404">
	<cfcontent reset="true"><cfabort>
</cfif>
<!--- Before the updater has made the BlogEvent table there are no events. --->
<cftry>
	<cfset eventDetails = application.events.getEvent(url.postId)>
	<cfcatch type="any"><cfset eventDetails = {}></cfcatch>
</cftry>
<cfset eventPost = structIsEmpty(eventDetails) ? [] : application.blog.getPostByPostId(url.postId)>
<cfif structIsEmpty(eventDetails) or not isArray(eventPost) or not arrayLen(eventPost)>
	<cfheader statuscode="404">
	<cfcontent reset="true"><cfabort>
</cfif>
<cfset eventUrl = application.blog.makeLink(isPage = eventPost[1]["IsPage"], postAlias = eventPost[1]["PostAlias"], datePosted = eventPost[1]["DatePosted"])>
<cfset fileName = reReplace(lCase(eventPost[1]["PostAlias"]), "[^a-z0-9-]", "", "all")>
<cfheader name="Content-Disposition" value="attachment; filename=""#len(fileName) ? fileName : 'event'#.ics""">
<cfheader name="Cache-Control" value="no-store">
<cfcontent reset="true" type="text/calendar; charset=utf-8"><cfoutput>#application.events.buildIcs(eventDetails, eventPost[1]["Title"], eventUrl)#</cfoutput>
