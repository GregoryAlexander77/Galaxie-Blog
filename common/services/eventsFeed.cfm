<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
	The public calendar feed of this blog's events (2026-10-15): an iCalendar file that Google Calendar, Outlook and Apple
	Calendar subscribe to ("Subscribe in your calendar app" on the Events page). Events on released posts only, from the last
	90 days on (common/cfc/Events.cfc buildFeed). Before the updater has made the BlogEvent table, it is an empty calendar.
--->
<cftry>
	<cfset eventsFeed = application.events.buildFeed()>
	<cfcatch type="any">
		<cfset eventsFeed = "BEGIN:VCALENDAR#chr(13)##chr(10)#VERSION:2.0#chr(13)##chr(10)#PRODID:-//Galaxie Blog//Events//EN#chr(13)##chr(10)#END:VCALENDAR#chr(13)##chr(10)#">
	</cfcatch>
</cftry>
<cfheader name="Cache-Control" value="public, max-age=900">
<cfheader name="Content-Disposition" value="inline; filename=""events.ics""">
<cfcontent reset="true" type="text/calendar; charset=utf-8"><cfoutput>#eventsFeed#</cfoutput>
