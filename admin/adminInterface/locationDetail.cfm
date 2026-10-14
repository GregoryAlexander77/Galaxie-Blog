<!--- Location editor (window 89, 2026-10-14), opened from the Locations window (88) with createAdminInterfaceWindow(89, locationOptionId);
0 makes a new location. Saved by ProxyController.cfc's saveLocation -> application.locations.saveLocation (common/cfc/Locations.cfc),
which checks everything again on the server and keeps only the details for the chosen kind. --->
<cfset locationOptionId = val(URL.optArgs)>
<cfset bookingLocation = locationOptionId gt 0 ? application.locations.getLocation(locationOptionId) : {}>
<cfset isNewLocation = structIsEmpty(bookingLocation)>
<cfif isNewLocation>
	<cfset bookingLocation = {
		locationOptionId: 0, kind: "inPerson", label: "", venueName: "", address: "", onlineLinkMode: "fixed", onlineUrl: "",
		phoneDirection: "weCall", phoneNumber: "", instructions: "", active: true, sortOrder: arrayLen(application.locations.getLocations()) + 1
	}>
</cfif>

<script>
	$(document).ready(function() {

		<!--- Shows only the details for the chosen way to meet, and suggests a name for it. --->
		var labelHints = {
			inPerson: "eg. In person (Seattle office)",
			online: "eg. Online (Zoom)",
			phone: "eg. Phone call"
		};
		function refreshLocationKind() {
			var kind = $("#locationKind").val();
			$(".locationKindRow").hide();
			$(".locationKind_" + kind).show();
			$("#locationLabel").attr("placeholder", labelHints[kind] || "");
			$("#locationOnlineUrlRow").toggle(kind == "online" && $("input[name=locationOnlineLinkMode]:checked").val() == "fixed");
			$("#locationPhoneNumberRow").toggle(kind == "phone" && $("input[name=locationPhoneDirection]:checked").val() == "youCall");
		}
		$("#locationKind").kendoDropDownList({ change: refreshLocationKind });
		$("input[name=locationOnlineLinkMode], input[name=locationPhoneDirection]").on("change", refreshLocationKind);
		refreshLocationKind();

		$("#locationSubmit").on("click", function() {
			var locationData = {
				locationOptionId: <cfoutput>#bookingLocation.locationOptionId#</cfoutput>,
				kind: $("#locationKind").val(),
				label: $.trim($("#locationLabel").val()),
				venueName: $.trim($("#locationVenueName").val()),
				address: $.trim($("#locationAddress").val()),
				onlineLinkMode: $("input[name=locationOnlineLinkMode]:checked").val(),
				onlineUrl: $.trim($("#locationOnlineUrl").val()),
				phoneDirection: $("input[name=locationPhoneDirection]:checked").val(),
				phoneNumber: $.trim($("#locationPhoneNumber").val()),
				instructions: $.trim($("#locationInstructions").val()),
				sortOrder: $("#locationSortOrder").val(),
				active: $("#locationActive").is(":checked")
			};
			if (!locationData.label.length) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Please check the location", message: "Give the location a name that clients choose from.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}

			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the location.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveLocation',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', locationJson: JSON.stringify(locationData) },
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (JSON.parse(response.success) == true) {
						try { refreshLocationsWindow(); } catch (error) {}
						try { $("#bookingsWindow").data("kendoWindow").refresh(); } catch (error) {}
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The location was saved.", icon: "k-ext-information" })).done(function() {
							$('#locationDetailWindow').kendoWindow('destroy');
						});
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR, textStatus, error) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) {
						createLoginWindow();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving the location", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				}
			});
		});
	});//...document.ready
</script>

<cfoutput>
<form id="locationDetailForm" action="##" method="post" onsubmit="return false;">
<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr>
		<td width="25%"><label for="locationKind">How you meet:</label></td>
		<td>
			<select id="locationKind" style="width: 250px;">
				<cfloop array="#application.locations.getKinds()#" index="thisKind">
					<option value="#thisKind.kind#"<cfif thisKind.kind eq bookingLocation.kind> selected</cfif>>#encodeForHtml(thisKind.label)#</option>
				</cfloop>
			</select>
		</td>
	</tr>
	<tr>
		<td><label for="locationLabel">Name:</label></td>
		<td>
			<input type="text" id="locationLabel" class="k-textbox" maxlength="125" value="#encodeForHtmlAttribute(bookingLocation.label)#" style="width: 95%;">
			<div class="k-form-hint">What clients choose from when a booking type offers more than one way to meet.</div>
		</td>
	</tr>

	<!--- In person --->
	<tr class="locationKindRow locationKind_inPerson">
		<td><label for="locationVenueName">Place:</label></td>
		<td><input type="text" id="locationVenueName" class="k-textbox" maxlength="255" placeholder="eg. Healing Arts Studio" value="#encodeForHtmlAttribute(bookingLocation.venueName)#" style="width: 95%;"><div class="k-form-hint">Optional.</div></td>
	</tr>
	<tr class="locationKindRow locationKind_inPerson">
		<td><label for="locationAddress">Address:</label></td>
		<td><textarea id="locationAddress" class="k-textbox" rows="3" maxlength="1000" style="width: 95%;">#encodeForHtml(bookingLocation.address)#</textarea><div class="k-form-hint">Clients get it with an "Open in maps" link.</div></td>
	</tr>

	<!--- Online --->
	<tr class="locationKindRow locationKind_online">
		<td>Meeting link:</td>
		<td>
			<label><input type="radio" class="k-radio" name="locationOnlineLinkMode" value="fixed"<cfif bookingLocation.onlineLinkMode eq "fixed"> checked</cfif>> The same link every time</label><br/>
			<label><input type="radio" class="k-radio" name="locationOnlineLinkMode" value="later"<cfif bookingLocation.onlineLinkMode eq "later"> checked</cfif>> I'll email a link before each meeting</label>
		</td>
	</tr>
	<tr id="locationOnlineUrlRow" class="locationKindRow">
		<td><label for="locationOnlineUrl">Link:</label></td>
		<td><input type="text" id="locationOnlineUrl" class="k-textbox" maxlength="1000" placeholder="https://zoom.us/j/..." value="#encodeForHtmlAttribute(bookingLocation.onlineUrl)#" style="width: 95%;"><div class="k-form-hint">Your Zoom, Teams or Google Meet room. Clients get it with their confirmation.</div></td>
	</tr>

	<!--- Phone --->
	<tr class="locationKindRow locationKind_phone">
		<td>Who calls:</td>
		<td>
			<label><input type="radio" class="k-radio" name="locationPhoneDirection" value="weCall"<cfif bookingLocation.phoneDirection eq "weCall"> checked</cfif>> I call the client (they give their number when booking)</label><br/>
			<label><input type="radio" class="k-radio" name="locationPhoneDirection" value="youCall"<cfif bookingLocation.phoneDirection eq "youCall"> checked</cfif>> The client calls me</label>
		</td>
	</tr>
	<tr id="locationPhoneNumberRow" class="locationKindRow">
		<td><label for="locationPhoneNumber">Number to call:</label></td>
		<td><input type="text" id="locationPhoneNumber" class="k-textbox" maxlength="50" value="#encodeForHtmlAttribute(bookingLocation.phoneNumber)#" style="width: 250px;"></td>
	</tr>

	<tr>
		<td><label for="locationInstructions">Instructions:</label></td>
		<td><textarea id="locationInstructions" class="k-textbox" rows="3" maxlength="2000" style="width: 95%;">#encodeForHtml(bookingLocation.instructions)#</textarea><div class="k-form-hint">Optional, sent with the confirmation for this way to meet: parking, which door, how to join, what to have ready.</div></td>
	</tr>
	<tr>
		<td><label for="locationSortOrder">Order:</label></td>
		<td><input type="number" id="locationSortOrder" class="k-textbox" min="0" step="1" value="#bookingLocation.sortOrder#" style="width: 90px;"> <span class="k-form-hint">Lower numbers are listed first.</span></td>
	</tr>
	<tr>
		<td colspan="2">
			<label><input type="checkbox" class="k-checkbox" id="locationActive"<cfif bookingLocation.active> checked</cfif>> Active</label>
			<div class="k-form-hint">An inactive location isn't offered to clients.</div>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="right"><button id="locationSubmit" type="button" class="k-button k-primary">Save</button></td>
	</tr>
</table>
</form>
</cfoutput>
