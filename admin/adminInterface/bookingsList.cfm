<!--- Bookings list (window 94, 2026-10-14): the bookings visitors have made, in a grid - Kendo when Kendo Professional is loaded,
jsGrid otherwise (includes/grids/kendo|jsGrid/bookings.cfm). Opened with createAdminInterfaceWindow(94, range), range = upcoming
(the default), past or all. Open shows a booking (window 95), where it can be approved, cancelled or marked completed. Bookings
are never deleted, so their history is kept. --->
<cfset bookingsRange = listFind("upcoming,past,all", URL.optArgs) ? URL.optArgs : "upcoming">
<cfset bookingsPendingCount = 0>
<cfloop array="#application.bookings.getBookingsForList('upcoming')#" index="thisBooking">
	<cfif thisBooking.status eq "pending"><cfset bookingsPendingCount = bookingsPendingCount + 1></cfif>
</cfloop>
<script>
	<!--- Called by the booking window after a change, so the list stays current. --->
	function refreshBookingsListWindow() {
		try {
			$("#bookingsListWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}
	$(document).ready(function() {
		$("#bookingsRange").kendoDropDownList({
			change: function() {
				$("#bookingsListWindow").data("kendoWindow").destroy();
				createAdminInterfaceWindow(94, this.value());
			}
		});
	});
</script>

<p>
	<label for="bookingsRange">Show:</label>
	<select id="bookingsRange" style="width: 200px;">
		<option value="upcoming"<cfif bookingsRange eq "upcoming"> selected</cfif>>Upcoming</option>
		<option value="past"<cfif bookingsRange eq "past"> selected</cfif>>Past</option>
		<option value="all"<cfif bookingsRange eq "all"> selected</cfif>>All</option>
	</select>
	<cfif bookingsPendingCount><cfoutput><b>#bookingsPendingCount# waiting for your approval.</b></cfoutput></cfif>
</p>
<p class="k-form-hint">Times are in your blog's time zone. Open a booking to approve, cancel or mark it completed, and to keep notes.</p>

<cfif application.kendoCommercial>
	<cfinclude template="../../includes/grids/kendo/bookings.cfm">
<cfelse>
	<cfinclude template="../../includes/grids/jsGrid/bookings.cfm">
</cfif>
