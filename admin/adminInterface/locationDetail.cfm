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
	<!--- A new location added from a dropdown's "not found" button starts with the name typed there (otherArgs).
	createAdminInterfaceWindow sends the text "undefined" when no otherArgs is given. --->
	<cfif structKeyExists(URL, "otherArgs") and len(trim(URL.otherArgs)) and not listFindNoCase("undefined,null", trim(URL.otherArgs))>
		<cfset bookingLocation.label = left(trim(URL.otherArgs), 125)>
	</cfif>
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
			$(".locationOnlineUrlRow").toggle(kind == "online" && $("input[name=locationOnlineLinkMode]:checked").val() == "fixed");
			$(".locationPhoneNumberRow").toggle(kind == "phone" && $("input[name=locationPhoneDirection]:checked").val() == "youCall");
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
						<!--- Open location dropdowns (booking hours) add the new location; the one whose New Location button opened this selects it. --->
						$(document).trigger("galaxieLocationSaved", [{ locationOptionId: response.locationOptionId, label: locationData.label }]);
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

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<form id="locationDetailForm" action="##" method="post" onsubmit="return false;">
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr>
		<td class="#blockClass#" align="right"><label for="locationKind">How you meet:</label></td>
		<td class="#blockClass#">
			<select id="locationKind" style="width: 250px;">
				<cfloop array="#application.locations.getKinds()#" index="thisKind">
					<option value="#thisKind.kind#"<cfif thisKind.kind eq bookingLocation.kind> selected</cfif>>#encodeForHtml(thisKind.label)#</option>
				</cfloop>
			</select>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">The name is what clients choose from when a booking type offers more than one way to meet.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="locationLabel">Name:</label></td>
		<td class="#blockClass#"><input type="text" id="locationLabel" class="k-textbox" maxlength="125" placeholder="eg. In person (my office)" value="#encodeForHtmlAttribute(bookingLocation.label)#" style="width: 95%;"></td>
	</tr>

	<!--- Only one of the in person / online / phone blocks shows (the JavaScript shows the rows for the chosen kind), so they share one colour. --->
	<cfset kindBlockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<cfloop list="inPerson,online,phone" index="thisKindBlock">
	<tr class="blockSpacer locationKindRow locationKind_#thisKindBlock#"><td colspan="2" class="#blockClass#"></td></tr>
	<tr class="blockSpacer locationKindRow locationKind_#thisKindBlock#"><td colspan="2" class="border #kindBlockClass#"></td></tr>
	<tr class="locationKindRow locationKind_#thisKindBlock#"><td colspan="2" class="#kindBlockClass#"><h4 class="adminBlockHeading">#thisKindBlock eq "inPerson" ? "The place" : (thisKindBlock eq "online" ? "The meeting link" : "The phone call")#</h4></td></tr>
	</cfloop>
	<cfset blockClass = kindBlockClass>

	<!--- In person --->
	<tr class="blockSpacer locationKindRow locationKind_inPerson"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="locationKindRow locationKind_inPerson"><td colspan="2" class="#blockClass#">Optional.</td></tr>
	<tr class="blockSpacer locationKindRow locationKind_inPerson"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="locationKindRow locationKind_inPerson">
		<td class="#blockClass#" align="right"><label for="locationVenueName">Place:</label></td>
		<td class="#blockClass#"><input type="text" id="locationVenueName" class="k-textbox" maxlength="255" placeholder="eg. Main Street Studio" value="#encodeForHtmlAttribute(bookingLocation.venueName)#" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer locationKindRow locationKind_inPerson"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="locationKindRow locationKind_inPerson"><td colspan="2" class="#blockClass#">Clients get it with an "Open in maps" link.</td></tr>
	<tr class="blockSpacer locationKindRow locationKind_inPerson"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="locationKindRow locationKind_inPerson">
		<td class="#blockClass#" align="right"><label for="locationAddress">Address:</label></td>
		<td class="#blockClass#"><textarea id="locationAddress" class="k-textbox" rows="3" maxlength="1000" style="width: 95%;">#encodeForHtml(bookingLocation.address)#</textarea></td>
	</tr>

	<!--- Online --->
	<tr class="blockSpacer locationKindRow locationKind_online"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="locationKindRow locationKind_online">
		<td class="#blockClass#" align="right">Meeting link:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="locationOnlineLinkMode" value="fixed"<cfif bookingLocation.onlineLinkMode eq "fixed"> checked</cfif>> The same link every time</label><br/>
			<label><input type="radio" class="k-radio" name="locationOnlineLinkMode" value="later"<cfif bookingLocation.onlineLinkMode eq "later"> checked</cfif>> I'll email a link before each meeting</label>
		</td>
	</tr>
	<tr class="blockSpacer locationKindRow locationOnlineUrlRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="locationKindRow locationOnlineUrlRow"><td colspan="2" class="#blockClass#">Your Zoom, Teams or Google Meet room; clients get it with their confirmation.</td></tr>
	<tr class="blockSpacer locationKindRow locationOnlineUrlRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr id="locationOnlineUrlRow" class="locationKindRow locationOnlineUrlRow">
		<td class="#blockClass#" align="right"><label for="locationOnlineUrl">Link:</label></td>
		<td class="#blockClass#"><input type="text" id="locationOnlineUrl" class="k-textbox" maxlength="1000" placeholder="https://zoom.us/j/..." value="#encodeForHtmlAttribute(bookingLocation.onlineUrl)#" style="width: 95%;"></td>
	</tr>

	<!--- Phone --->
	<tr class="blockSpacer locationKindRow locationKind_phone"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="locationKindRow locationKind_phone">
		<td class="#blockClass#" align="right">Who calls:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="locationPhoneDirection" value="weCall"<cfif bookingLocation.phoneDirection eq "weCall"> checked</cfif>> I call the client (they give their number when booking)</label><br/>
			<label><input type="radio" class="k-radio" name="locationPhoneDirection" value="youCall"<cfif bookingLocation.phoneDirection eq "youCall"> checked</cfif>> The client calls me</label>
		</td>
	</tr>
	<tr class="blockSpacer locationKindRow locationPhoneNumberRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr id="locationPhoneNumberRow" class="locationKindRow locationPhoneNumberRow">
		<td class="#blockClass#" align="right"><label for="locationPhoneNumber">Number to call:</label></td>
		<td class="#blockClass#"><input type="text" id="locationPhoneNumber" class="k-textbox" maxlength="50" value="#encodeForHtmlAttribute(bookingLocation.phoneNumber)#" style="width: 250px;"><span class="k-form-hint">Clients get it with their confirmation.</span></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Details</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Optional instructions, sent with the confirmation for this way to meet: parking, which door, how to join, what to have ready.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="locationInstructions">Instructions:</label></td>
		<td class="#blockClass#"><textarea id="locationInstructions" class="k-textbox" rows="3" maxlength="2000" style="width: 95%;">#encodeForHtml(bookingLocation.instructions)#</textarea></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="locationSortOrder">Order:</label></td>
		<td class="#blockClass#"><input type="number" id="locationSortOrder" class="k-textbox" min="0" step="1" value="#bookingLocation.sortOrder#" style="width: 90px;"><span class="k-form-hint">Lower numbers are listed first.</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">An inactive location isn't offered to clients.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="locationActive">Active:</label></td>
		<td class="#blockClass#">
			<input type="checkbox" class="k-checkbox" id="locationActive"<cfif bookingLocation.active> checked</cfif>>			
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="locationSubmit" type="button" class="k-button k-primary">Save</button></td>
	</tr>
</table>
</form>
</cfoutput>
