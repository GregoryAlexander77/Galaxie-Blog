<!--- Booking types (window 90, 2026-10-14): what visitors can book, in a grid - Kendo when Kendo Professional is loaded, jsGrid
otherwise (includes/grids/kendo|jsGrid/bookingTypes.cfm), like the other admin grids. New booking type and Edit open the booking
type editor (window 91). The work is done by application.bookings (common/cfc/Bookings.cfc). --->
<script>
	<!--- Called by the booking type editor after a save, so the grid stays current. --->
	function refreshBookingTypesWindow() {
		try {
			$("#bookingTypesWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}
</script>

<p>What clients can book with you, for example "Consultation, 25 minutes" or "Individual Healing Session, 1 hour". Group them under categories if you like, as in "Pets" or "Youth".</p>
<cfif not arrayLen(application.locations.getLocations())>
	<p><b>Set up a location first</b> (<a href="javascript:createAdminInterfaceWindow(89, 0);">add a location</a>): every booking type says where or how you meet.</p>
</cfif>
<p><button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(91, 0);">New booking type</button></p>

<cfif application.kendoCommercial>
	<cfinclude template="../../includes/grids/kendo/bookingTypes.cfm">
<cfelse>
	<cfinclude template="../../includes/grids/jsGrid/bookingTypes.cfm">
</cfif>
