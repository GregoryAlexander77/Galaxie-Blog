<!--- Insert Booking window (window 93, 2026-10-14), opened by the post editor's Insert Booking button and Insert > Booking menu item
(includes/templates/js/tinyMce.cfm). Inserts a placeholder for a booking widget into the post:
<div class="galaxieBooking" data-booking="type-alias">[Booking: Name]</div>, or data-booking="*" for every booking type (clients
choose, grouped by category). On the site, common/js/bookings.js shows the widget there; in a feed or an email it becomes a link
to the post. --->
<cfset insertableBookingTypes = [{ "alias": "*", "name": "All bookings (clients choose)" }]>
<cfloop array="#application.bookings.getBookingTypes(activeOnly = true)#" index="thisBookingType">
	<cfset arrayAppend(insertableBookingTypes, { "alias": thisBookingType.alias, "name": (len(thisBookingType.category) ? thisBookingType.category & ": " : "") & thisBookingType.name })>
</cfloop>

<script>
	$(document).ready(function() {
		var insertBookingChoice = $("#insertBookingChoice").kendoDropDownList({
			dataSource: <cfoutput>#serializeJson(insertableBookingTypes)#</cfoutput>,
			dataTextField: "name",
			dataValueField: "alias",
			filter: "contains"
		}).data("kendoDropDownList");

		$("#insertBookingSubmit").on("click", function() {
			var item = insertBookingChoice.dataItem();
			var editor = tinymce.activeEditor;
			if (!item || !editor) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Choose a booking", message: "Open the post in the editor and choose what to place.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			var label = item.alias === "*" ? "All bookings" : item.name;
			var alias = $('<div/>').text(item.alias).html().replace(/"/g, "&quot;");
			editor.insertContent('<div class="galaxieBooking" data-booking="' + alias + '">[Booking: ' + $('<div/>').text(label).html() + ']</div><p>&nbsp;</p>');
			$('#insertBookingWindow').kendoWindow('destroy');
		});
	});
</script>

<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0" border="0">
<cfif arrayLen(insertableBookingTypes) eq 1>
	<tr>
		<td colspan="2">There are no active booking types yet. Set them up under Bookings in the admin site, then come back to place them here.</td>
	</tr>
<cfelse>
	<tr>
		<td width="25%"><label for="insertBookingChoice">Booking:</label></td>
		<td><input id="insertBookingChoice" style="width: 95%;"></td>
	</tr>
	<tr>
		<td colspan="2">
			<div class="k-form-hint">"All bookings" lists every booking type under its category, and clients pick one. Or choose one type for a page about it. The post shows "[Booking: name]" while you edit it; visitors see the booking calendar.</div>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="right"><button id="insertBookingSubmit" type="button" class="k-button k-primary">Insert</button></td>
	</tr>
</cfif>
</table>
