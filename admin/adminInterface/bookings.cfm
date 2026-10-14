<!--- Bookings (window 87, 2026-10-14): the starting point for appointments - visitors booking a time with the blog owner (a
consultation, a session, a lesson). Opened from the Bookings icon on the admin home page. Each part opens its own window:
Locations (88), Booking types (90) and Hours (92); the bookings list comes with a later step of the Bookings build.
See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 3. --->
<cfset bookingLocationCount = arrayLen(application.locations.getLocations())>
<cfset bookingTypeCount = arrayLen(application.bookings.getBookingTypes())>
<cfset bookingTimeZone = application.blog.getBlogTimeZoneId()>

<p>Let visitors book a time with you: a consultation, a session, a lesson. Set up where you meet, the kinds of bookings you offer, and when you're available.</p>

<table align="center" class="k-content tableBorder" width="100%" cellpadding="8" cellspacing="0" border="0">
	<tr>
		<td width="30%"><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(88);">Locations</button></td>
		<td>Where you meet: in person, online or by phone. A booking type can offer several, and the client chooses. <cfoutput>(#bookingLocationCount# set up)</cfoutput></td>
	</tr>
	<tr>
		<td><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(90);">Booking types</button></td>
		<td>What can be booked: its length, price, where it happens, and the rules for booking it. <cfoutput>(#bookingTypeCount# set up)</cfoutput></td>
	</tr>
	<tr>
		<td><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(92);">Hours</button></td>
		<td>When you're available each week, per location if you like, and your days off.
			<cfif len(bookingTimeZone)><cfoutput>Times are in your blog's time zone, #encodeForHtml(bookingTimeZone)#.</cfoutput><cfelse>Set your time zone in Blog Settings first.</cfif></td>
	</tr>
	<tr>
		<td><button type="button" class="k-button" style="width: 100%;" disabled="disabled">Bookings</button></td>
		<td>Coming next: the bookings people have made.</td>
	</tr>
</table>
