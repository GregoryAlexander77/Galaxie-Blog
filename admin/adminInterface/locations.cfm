<!--- Locations (window 88, 2026-10-14): where bookings happen - in person, online or by phone - in a grid, Kendo when Kendo
Professional is loaded, jsGrid otherwise (includes/grids/kendo|jsGrid/locations.cfm), like the other admin grids. New location
and Edit open the location editor (window 89). The work is done by application.locations (common/cfc/Locations.cfc). --->
<script>
	<!--- Called by the location editor after a save, so the grid stays current. --->
	function refreshLocationsWindow() {
		try {
			$("#locationsWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}
</script>

<p>Where you meet clients. Make one for each way you meet - for example your office, your video call link and the phone - and a booking type can then offer one or several of them. When it offers more than one, the client picks; their confirmation shows only the details for that choice.</p>
<p><button type="button" class="k-button k-primary" onclick="createAdminInterfaceWindow(89, 0);">New location</button></p>

<cfif application.kendoCommercial>
	<cfinclude template="../../includes/grids/kendo/locations.cfm">
<cfelse>
	<cfinclude template="../../includes/grids/jsGrid/locations.cfm">
</cfif>
