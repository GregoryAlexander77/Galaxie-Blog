<!--- Insert Booking window (window 93, 2026-10-14), opened by the post editor's Insert Booking button and Insert > Booking menu item
(includes/templates/js/tinyMce.cfm). Inserts a placeholder for a booking widget into the post:
<div class="galaxieBooking" data-booking="type-alias">[Booking: Name]</div>, or data-booking="*" for every booking type (clients
choose, grouped by category). On the site, common/js/bookings.js shows the widget there; in a feed or an email it becomes a link
to the post. --->
<cfset insertableBookingTypes = [{ "bookingTypeId": 0, "alias": "*", "name": "All bookings (clients choose)" }]>
<cfloop array="#application.bookings.getBookingTypes(activeOnly = true)#" index="thisBookingType">
	<cfset arrayAppend(insertableBookingTypes, { "bookingTypeId": thisBookingType.bookingTypeId, "alias": thisBookingType.alias, "name": (len(thisBookingType.category) ? thisBookingType.category & ": " : "") & thisBookingType.name })>
</cfloop>

<script>
	// Called by the booking type editor (bookingTypeDetail.cfm) after a save, so a type added from here can be placed right away.
	function refreshInsertBookingWindow(bookingTypeId) {
		try {
			window.insertBookingSelectId = bookingTypeId;
			$("#insertBookingWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}

	$(document).ready(function() {
		var insertableBookingTypes = <cfoutput>#serializeJson(insertableBookingTypes)#</cfoutput>;
		var insertBookingChoice = $("#insertBookingChoice").kendoDropDownList({
			dataSource: insertableBookingTypes,
			dataTextField: "name",
			dataValueField: "alias",
			filter: "contains",
			noDataTemplate: $("#insertBookingNoData").html()
		}).data("kendoDropDownList");

		// Select the booking type just added in the editor, if any.
		if (window.insertBookingSelectId) {
			var addedId = window.insertBookingSelectId;
			window.insertBookingSelectId = 0;
			$.each(insertableBookingTypes, function(i, item) {
				if (item.bookingTypeId == addedId) { insertBookingChoice.value(item.alias); }
			});
		}

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

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
<cfif arrayLen(insertableBookingTypes) eq 1>
	<tr><td colspan="2" class="#blockClass#">There are no active booking types yet. <a href="javascript:createAdminInterfaceWindow(91, 0);">Add a booking type</a>, then place it here (this window updates when you save it).</td></tr>
<cfelse>
	<tr><td colspan="2" class="#blockClass#">"All bookings" lists every booking type under its category, and clients pick one. Or choose one type for a page about it. The post shows "[Booking: name]" while you edit it; visitors see the booking calendar.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="insertBookingChoice">Booking:</label></td>
		<td class="#blockClass#"><input id="insertBookingChoice" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="insertBookingSubmit" type="button" class="k-button k-primary">Insert</button></td>
	</tr>
</cfif>
</table>
</cfoutput>

<!--- "Not found? Add it" template for the booking dropdown (common/js/adminDropDowns.js). Outside cfoutput: Kendo templates use #.
The booking type editor calls refreshInsertBookingWindow after the save, which reloads this window with the new type selected. --->
<script id="insertBookingNoData" type="text/x-kendo-tmpl">
	# var value = galaxieTypedText(instance); #
	<div># if (value.length) { #Booking type not found. Do you want to add '#: value #'?# } else { #There are no booking types yet.# } #</div>
	<br />
	<button type="button" class="k-button" onclick="createAdminInterfaceWindow(91, 0, #= kendo.htmlEncode(JSON.stringify(value)) #)">Add Booking Type</button>
</script>
