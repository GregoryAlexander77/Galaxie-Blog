<cfprocessingdirective pageencoding="utf-8">
<cfsetting showdebugoutput="false" requesttimeout="120">
<!---
Booking reminders (2026-10-14). Called every 15 minutes by the blog's recurring cfschedule task (Bookings.cfc's ensureReminderTask,
named galaxieBookingReminders<blogId>), the same way scheduled posts use handleFuturePost.cfm. Sends each reminder that is due
(the booking type's ReminderHours before the start) once; a booking is marked before its email goes out. Calling it at other
times does no harm: it only ever sends reminders that are due and not yet sent.
--->
<cfif structKeyExists(application, "bookings")>
	<cfset remindersSent = application.bookings.sendDueReminders()>
	<cfcontent reset="true" type="text/plain"><cfoutput>reminders sent: #remindersSent#</cfoutput>
</cfif>
