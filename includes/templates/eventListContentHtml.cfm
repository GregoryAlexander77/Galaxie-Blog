<!--- The Events page (2026-10-15), /events when no Page or Page Collection already uses that address (index.cfm, pageTypeId
25). Upcoming events, recent past ones, a month calendar of the event days and the calendar feed - common/cfc/Events.cfc
renderEventsPageHtml. Cached for an hour (finished events move to Past) and cleared when an event changes (flushListings).
The id must be "blogContent" so it sits beside the sidebar, as on the Collections page. --->
<cfset eventsPageCacheKey = "eventsPage" & (session.isMobile ? "Mobile" : "")>
<div id="blogContent" class="k-content">
	<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#eventsPageCacheKey#" scope="html" file="#application.baseUrl#/cache/events/#eventsPageCacheKey#.cfm" timeout="#(60*60)#" disabled="#application.disableCache#">
		<cftry>
			<cfoutput>#application.events.renderEventsPageHtml()#</cfoutput>
			<cfcatch type="any">
				<h1 class="topContent">Events</h1>
				<p>No events yet.</p>
			</cfcatch>
		</cftry>
	</cfmodule>
</div>
