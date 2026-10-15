<!--- Booking type editor (window 91, 2026-10-14), opened from the Booking types window (90) with createAdminInterfaceWindow(91, bookingTypeId);
0 makes a new one. Saved by ProxyController.cfc's saveBookingType -> application.bookings.saveBookingType (common/cfc/Bookings.cfc),
which checks everything again on the server. How a priced type is paid - in full or a deposit online (Stripe), or at the session - and
its refund window are in the Price section (2026-10-15). --->
<cfset bookingTypeId = val(URL.optArgs)>
<cfset bookingType = bookingTypeId gt 0 ? application.bookings.getBookingType(bookingTypeId = bookingTypeId) : {}>
<cfset isNewBookingType = structIsEmpty(bookingType)>
<cfif isNewBookingType>
	<cfset bookingType = {
		bookingTypeId: 0, name: "", category: "", description: "", durationMinutes: 60, startIntervalMinutes: 30,
		bufferBeforeMinutes: 0, bufferAfterMinutes: 0, bookingMode: "oneOnOne", groupSize: 1, price: 0, pricingUnit: "perBooking",
		webFormId: 0, minNoticeHours: 24, maxDaysAhead: 60, dailyLimit: 0, requiresApproval: false, reminderHours: 24,
		active: true, sortOrder: 0, locationIds: [],
		paymentOption: "full", depositAmount: 0, depositIsPercent: false, balanceCollection: "inPerson", refundHours: 24
	}>
</cfif>
<cfset bookingTypeLocations = application.locations.getLocations()>
<cfset bookingTypeCategories = application.bookings.getCategories()>
<cfset bookingTypeForms = [{ "webFormId": 0, "title": "None" }]>
<cfloop array="#application.webForms.getForms()#" index="thisWebForm">
	<cfif thisWebForm.active or thisWebForm.webFormId eq bookingType.webFormId>
		<cfset arrayAppend(bookingTypeForms, { "webFormId": thisWebForm.webFormId, "title": thisWebForm.title })>
	</cfif>
</cfloop>

<script>
	$(document).ready(function() {

		<!--- Category: pick one already used, or type a new one. --->
		$("#bookingTypeCategory").kendoComboBox({
			dataSource: <cfoutput>#serializeJson(bookingTypeCategories)#</cfoutput>,
			filter: "contains",
			placeholder: "No category",
			value: <cfoutput>#serializeJson(bookingType.category)#</cfoutput>
		});
		$("#bookingTypeStartInterval").kendoDropDownList();
		$("#bookingTypePricingUnit").kendoDropDownList();
		$("#bookingTypeWebForm").kendoDropDownList({
			dataSource: <cfoutput>#serializeJson(bookingTypeForms)#</cfoutput>,
			dataTextField: "title",
			dataValueField: "webFormId",
			value: <cfoutput>#bookingType.webFormId#</cfoutput>
		});

		function refreshBookingMode() {
			var isGroup = $("input[name=bookingTypeMode]:checked").val() == "group";
			$(".bookingTypeGroupRow").toggle(isGroup);
		}
		$("input[name=bookingTypeMode]").on("change", refreshBookingMode);
		refreshBookingMode();

		<!--- The payment rows (2026-10-15): only for a priced type; the deposit and what's left only for a deposit; refunds only when
		something is paid online. --->
		$("#bookingTypeDepositUnit").kendoDropDownList();
		function refreshPaymentRows() {
			var priced = parseFloat($("#bookingTypePrice").val()) > 0;
			var option = $("input[name=bookingTypePaymentOption]:checked").val();
			$(".bookingTypePaidRow").toggle(priced);
			$(".bookingTypeDepositRow").toggle(priced && option == "deposit");
			$(".bookingTypeOnlineRow").toggle(priced && option != "atSession");
		}
		$("#bookingTypePrice").on("input change", refreshPaymentRows);
		$("input[name=bookingTypePaymentOption]").on("change", refreshPaymentRows);
		refreshPaymentRows();

		$("#bookingTypeSubmit").on("click", function() {
			var category = $("#bookingTypeCategory").data("kendoComboBox");
			var typeData = {
				bookingTypeId: <cfoutput>#bookingType.bookingTypeId#</cfoutput>,
				name: $.trim($("#bookingTypeName").val()),
				category: $.trim(category.text()),
				description: $.trim($("#bookingTypeDescription").val()),
				durationMinutes: $("#bookingTypeDuration").val(),
				startIntervalMinutes: $("#bookingTypeStartInterval").val(),
				bufferBeforeMinutes: $("#bookingTypeBufferBefore").val() || 0,
				bufferAfterMinutes: $("#bookingTypeBufferAfter").val() || 0,
				bookingMode: $("input[name=bookingTypeMode]:checked").val(),
				groupSize: $("#bookingTypeGroupSize").val(),
				price: $("#bookingTypePrice").val() || 0,
				pricingUnit: $("#bookingTypePricingUnit").val(),
				paymentOption: $("input[name=bookingTypePaymentOption]:checked").val() || "full",
				depositAmount: $("#bookingTypeDepositAmount").val() || 0,
				depositIsPercent: $("#bookingTypeDepositUnit").val() === "percent",
				balanceCollection: $("input[name=bookingTypeBalance]:checked").val() || "inPerson",
				refundHours: $("#bookingTypeRefundHours").val() || 0,
				locationIds: $("input.bookingTypeLocation:checked").map(function() { return parseInt(this.value, 10); }).get(),
				webFormId: $("#bookingTypeWebForm").data("kendoDropDownList").value(),
				minNoticeHours: $("#bookingTypeMinNotice").val() || 0,
				maxDaysAhead: $("#bookingTypeMaxDays").val() || 60,
				dailyLimit: $("#bookingTypeDailyLimit").val() || 0,
				requiresApproval: $("#bookingTypeApproval").is(":checked"),
				reminderHours: $("#bookingTypeReminder").val() || 0,
				sortOrder: $("#bookingTypeSortOrder").val() || 0,
				active: $("#bookingTypeActive").is(":checked")
			};
			var problem = "";
			if (!typeData.name.length) { problem = "Give the booking type a name."; }
			else if (!typeData.locationIds.length) { problem = "Choose at least one location - where or how you meet."; }
			if (problem.length) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Please check the booking type", message: problem, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}

			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the booking type.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBookingType',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', bookingTypeJson: JSON.stringify(typeData) },
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (JSON.parse(response.success) == true) {
						try { refreshBookingTypesWindow(); } catch (error) {}
						try { $("#bookingsWindow").data("kendoWindow").refresh(); } catch (error) {}
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The booking type was saved.", icon: "k-ext-information" })).done(function() {
							$('#bookingTypeDetailWindow').kendoWindow('destroy');
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
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving the booking type", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				}
			});
		});
	});//...document.ready
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<form id="bookingTypeDetailForm" action="##" method="post" onsubmit="return false;">
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeName">Name:</label></td>
		<td class="#blockClass#"><input type="text" id="bookingTypeName" class="k-textbox" maxlength="125" placeholder="eg. Consultation" value="#encodeForHtmlAttribute(bookingType.name)#" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">Optional: booking types are listed under their category, eg. "Existing clients", "Pets" or "Youth". Pick one or type a new one.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeCategory">Category:</label></td>
		<td class="#blockClass#"><input id="bookingTypeCategory" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">What clients read before they choose a time.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeDescription">Description:</label></td>
		<td class="#blockClass#"><textarea id="bookingTypeDescription" class="k-textbox" rows="4" maxlength="4000" style="width: 95%;">#encodeForHtml(bookingType.description)#</textarea></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Time</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeDuration">Length:</label></td>
		<td class="#blockClass#"><input type="number" id="bookingTypeDuration" class="k-textbox" min="5" max="1440" step="5" value="#bookingType.durationMinutes#" style="width: 90px;"> minutes</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">How often a booking can start, eg. every 30 minutes: 9:00, 9:30, 10:00. Back to back offers one time after another, the length of the booking apart.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeStartInterval">Start times:</label></td>
		<td class="#blockClass#">
			<select id="bookingTypeStartInterval" style="width: 300px;">
				<cfloop list="15,30,60,0" index="thisInterval">
					<option value="#thisInterval#"<cfif thisInterval eq bookingType.startIntervalMinutes> selected</cfif>>#thisInterval eq 0 ? "Back to back" : "Every " & thisInterval & " minutes"#</option>
				</cfloop>
			</select>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">Free time kept around each booking, to prepare, travel or rest. Other bookings can't use it.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Time between bookings:</td>
		<td class="#blockClass#">
			<input type="number" id="bookingTypeBufferBefore" class="k-textbox" min="0" max="480" step="5" value="#bookingType.bufferBeforeMinutes#" style="width: 80px;" aria-label="Minutes before"> minutes before,
			<input type="number" id="bookingTypeBufferAfter" class="k-textbox" min="0" max="480" step="5" value="#bookingType.bufferAfterMinutes#" style="width: 80px;" aria-label="Minutes after"> minutes after
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Who</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Booking:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="bookingTypeMode" value="oneOnOne"<cfif bookingType.bookingMode neq "group"> checked</cfif>> One-on-one - one booking per time</label><br/>
			<label><input type="radio" class="k-radio" name="bookingTypeMode" value="group"<cfif bookingType.bookingMode eq "group"> checked</cfif>> Group - several people can book the same time</label>
		</td>
	</tr>
	<tr class="blockSpacer bookingTypeGroupRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="bookingTypeGroupRow">
		<td class="#blockClass#" align="right"><label for="bookingTypeGroupSize">Group size:</label></td>
		<td class="#blockClass#"><input type="number" id="bookingTypeGroupSize" class="k-textbox" min="2" max="1000" value="#max(bookingType.groupSize, 2)#" style="width: 90px;"> people at most</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Where</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">Tick every way this can happen. With more than one, clients choose - eg. in person or a remote session.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Locations:</td>
		<td class="#blockClass#">
			<cfif not arrayLen(bookingTypeLocations)>
				Set up a location first under Bookings &gt; Locations.
			<cfelse>
				<cfloop array="#bookingTypeLocations#" index="thisLocation">
					<cfif thisLocation.active or arrayFind(bookingType.locationIds, thisLocation.locationOptionId)>
						<label><input type="checkbox" class="k-checkbox bookingTypeLocation" value="#thisLocation.locationOptionId#"<cfif arrayFind(bookingType.locationIds, thisLocation.locationOptionId)> checked</cfif>> #encodeForHtml(thisLocation.label)#<cfif not thisLocation.active> (not active)</cfif></label><br/>
					</cfif>
				</cfloop>
			</cfif>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Price</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">0 = free. The currency is set in Blog Options &gt; Payments.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypePrice">Price (#application.payments.getCurrency()#):</label></td>
		<td class="#blockClass#">
			<input type="number" id="bookingTypePrice" class="k-textbox" min="0" step="0.01" value="#numberFormat(bookingType.price, '0.00')#" style="width: 110px;">
			<span class="bookingTypeGroupRow">
				<select id="bookingTypePricingUnit" style="width: 180px;">
					<option value="perBooking"<cfif bookingType.pricingUnit neq "perPerson"> selected</cfif>>per booking</option>
					<option value="perPerson"<cfif bookingType.pricingUnit eq "perPerson"> selected</cfif>>per person</option>
				</select>
			</span>			
		</td>
	</tr>
	<tr class="blockSpacer bookingTypePaidRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<cfif not application.payments.getStatus().ready>
	<tr class="bookingTypePaidRow">
		<td colspan="2" class="#blockClass#">Paying online needs your Stripe keys in Blog Options &gt; Payments. Until they're saved, clients see the price and pay at the session.</td>
	</tr>
	<tr class="blockSpacer bookingTypePaidRow"><td colspan="2" class="border #blockClass#"></td></tr>
	</cfif>
	<tr class="bookingTypePaidRow">
		<td class="#blockClass#" align="right">Payment:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="bookingTypePaymentOption" value="full"<cfif bookingType.paymentOption neq "deposit" and bookingType.paymentOption neq "atSession"> checked</cfif>> Paid online in full when booking</label><br>
			<label><input type="radio" class="k-radio" name="bookingTypePaymentOption" value="deposit"<cfif bookingType.paymentOption eq "deposit"> checked</cfif>> A deposit online when booking:</label>
			<input type="number" id="bookingTypeDepositAmount" class="k-textbox" min="0" step="0.01" value="#bookingType.depositAmount gt 0 ? numberFormat(bookingType.depositAmount, '0.00') : ''#" style="width: 90px;" aria-label="Deposit">
			<select id="bookingTypeDepositUnit" style="width: 110px;" aria-label="Deposit as an amount or a percentage">
				<option value="amount"<cfif not bookingType.depositIsPercent> selected</cfif>>#encodeForHtml(application.payments.getCurrency())#</option>
				<option value="percent"<cfif bookingType.depositIsPercent> selected</cfif>>%</option>
			</select><br>
			<label><input type="radio" class="k-radio" name="bookingTypePaymentOption" value="atSession"<cfif bookingType.paymentOption eq "atSession"> checked</cfif>> Paid at the session (not online)</label>
		</td>
	</tr>
	<tr class="blockSpacer bookingTypePaidRow bookingTypeDepositRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="bookingTypePaidRow bookingTypeDepositRow">
		<td class="#blockClass#" align="right">The rest:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="bookingTypeBalance" value="inPerson"<cfif bookingType.balanceCollection neq "online"> checked</cfif>> Paid at the session (you mark it paid in Bookings)</label><br>
			<label><input type="radio" class="k-radio" name="bookingTypeBalance" value="online"<cfif bookingType.balanceCollection eq "online"> checked</cfif>> Paid online: the reminder email has a "Pay the rest" link</label>
		</td>
	</tr>
	<tr class="blockSpacer bookingTypePaidRow bookingTypeOnlineRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="bookingTypePaidRow bookingTypeOnlineRow"><td colspan="2" class="#blockClass#">0 = no automatic refunds. You can always refund from the booking in Bookings.</td></tr>
	<tr class="blockSpacer bookingTypePaidRow bookingTypeOnlineRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="bookingTypePaidRow bookingTypeOnlineRow">
		<td class="#blockClass#" align="right"><label for="bookingTypeRefundHours">Refunds:</label></td>
		<td class="#blockClass#">
			A client who cancels at least <input type="number" id="bookingTypeRefundHours" class="k-textbox" min="0" max="8760" value="#bookingType.refundHours#" style="width: 80px;"> hours before is refunded what they paid online.			
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Booking rules</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">How soon a time can be booked, eg. 24 = not within the next day.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeMinNotice">Notice:</label></td>
		<td class="#blockClass#"><input type="number" id="bookingTypeMinNotice" class="k-textbox" min="0" max="8760" value="#bookingType.minNoticeHours#" style="width: 90px;"> hours at least </td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeMaxDays">Book ahead:</label></td>
		<td class="#blockClass#"><input type="number" id="bookingTypeMaxDays" class="k-textbox" min="1" max="730" value="#bookingType.maxDaysAhead#" style="width: 90px;"> days at most</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeDailyLimit">Per day:</label></td>
		<td class="#blockClass#"><input type="number" id="bookingTypeDailyLimit" class="k-textbox" min="0" max="1000" value="#bookingType.dailyLimit#" style="width: 90px;"> bookings at most <span class="k-form-hint">(0 = no limit)</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeReminder">Reminder:</label></td>
		<td class="#blockClass#"><input type="number" id="bookingTypeReminder" class="k-textbox" min="0" max="336" value="#bookingType.reminderHours#" style="width: 90px;"> hours before <span class="k-form-hint">(0 = no reminder email)</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">The time is held, and the client is told it's confirmed once you approve it.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeApproval">Approve first:</label></td>
		<td class="#blockClass#">
			<input type="checkbox" class="k-checkbox" id="bookingTypeApproval"<cfif bookingType.requiresApproval> checked</cfif>>			
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">Optional: a form from Forms that clients fill in when they book, eg. what they'd like help with. Name and email are always asked.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeWebForm">Questions:</label></td>
		<td class="#blockClass#"><input id="bookingTypeWebForm" style="width: 95%;"></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Options</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeSortOrder">Order:</label></td>
		<td class="#blockClass#"><input type="number" id="bookingTypeSortOrder" class="k-textbox" min="0" step="1" value="#bookingType.sortOrder#" style="width: 90px;"> <span class="k-form-hint">Lower numbers are listed first within a category.</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingTypeActive">Active:</label></td>
		<td class="#blockClass#">
			<input type="checkbox" class="k-checkbox" id="bookingTypeActive"<cfif bookingType.active> checked</cfif>>
			<span class="k-form-hint">An inactive booking type can't be booked.</span>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="bookingTypeSubmit" type="button" class="k-button k-primary">Save</button></td>
	</tr>
</table>
</form>
</cfoutput>
