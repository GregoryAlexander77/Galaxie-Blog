<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
	The owner's private bookings feed (2026-10-15): an iCalendar feed that Google Calendar, Outlook or Apple Calendar subscribes to.
	The address carries a long secret key (Bookings.cfc getFeedKey, kept in blog.ini.cfm); without the right key there is
	nothing here. The address and a "make a new address" button are in the Bookings window (admin/adminInterface/bookings.cfm).
--->
<cfparam name="url.key" default="">
<cfif not reFind("^[a-f0-9]{64}$", url.key) or compare(url.key, application.bookings.getFeedKey()) neq 0>
	<cfheader statuscode="404">
	<cfcontent reset="true"><cfabort>
</cfif>
<cfheader name="Cache-Control" value="no-store">
<cfcontent reset="true" type="text/calendar; charset=utf-8"><cfoutput>#application.bookings.buildFeed()#</cfoutput>
