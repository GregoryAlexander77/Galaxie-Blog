<!--- One booking (window 95, 2026-10-14), opened from the Bookings list (94) with createAdminInterfaceWindow(95, bookingId). Shows the
booking as the owner's email does (application.bookings.bookingDetailsHtml), and lets the owner approve it, cancel it (with an optional
note to the client), mark it completed or a no-show, and keep private notes. Approving and cancelling email the client.
Saved by ProxyController.cfc's setBookingStatus and saveBookingNotes. --->
<cfset bookingId = val(URL.optArgs)>
<cfset theBooking = application.bookings.getBooking(bookingId = bookingId)>
<cfset bookingIsPast = not structIsEmpty(theBooking) and theBooking.startLocal lte dateTimeFormat(application.blog.blogNow(), "yyyy-mm-dd HH:nn")>
<!--- Online payments (2026-10-15): what was paid and refunded, and what can still be refunded. --->
<cfset bookingPaymentTotals = structIsEmpty(theBooking) ? { paid: 0, refunded: 0, refundable: 0 } : application.payments.getPaymentTotals(theBooking.bookingId)>

<cfif structIsEmpty(theBooking)>
	<p>That booking no longer exists.</p>
<cfelse>
<script>
	$(document).ready(function() {

		function setStatus(status, message, refund) {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=setBookingStatus',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', bookingId: <cfoutput>#theBooking.bookingId#</cfoutput>, status: status, message: message || "", refund: refund ? "true" : "" },
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (JSON.parse(response.success) == true) {
						try { refreshBookingsListWindow(); } catch (error) {}
						$("#bookingDetailWindow").data("kendoWindow").refresh();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage || "The booking could not be changed.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) { createLoginWindow(); }
				}
			});
		}

		$("#bookingApprove").on("click", function() { setStatus("confirmed"); });
		$("#bookingCompleted").on("click", function() { setStatus("completed"); });
		$("#bookingNoShow").on("click", function() { setStatus("noShow"); });
		$("#bookingCancel").on("click", function() { $(".bookingCancelRow").show(); $("#bookingCancelMessage").focus(); });
		$("#bookingCancelConfirm").on("click", function() { setStatus("cancelled", $.trim($("#bookingCancelMessage").val()), $("#bookingCancelRefund").is(":checked")); });

		<!--- What was left, paid at the session (2026-10-15). --->
		$("#bookingBalancePaid").on("click", function() {
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=markBookingBalancePaid',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', bookingId: <cfoutput>#theBooking.bookingId#</cfoutput> },
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						try { refreshBookingsListWindow(); } catch (error) {}
						$("#bookingDetailWindow").data("kendoWindow").refresh();
					}
				},
				error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});

		<!--- Refund all or part of what was paid online (2026-10-15). --->
		$("#bookingRefund").on("click", function() {
			var amount = parseFloat($("#bookingRefundAmount").val());
			if (!(amount > 0)) { $("#bookingRefundStatus").text("Enter the amount to refund."); return; }
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Refund the client?", message: "Refund " + amount.toFixed(2) + " to the client's card? This can't be undone.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (!answer['button'] || answer['button'] !== 'Yes') { return; }
				$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Refunding.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
				jQuery.ajax({
					type: 'post',
					url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=refundBookingPayment',
					data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', bookingId: <cfoutput>#theBooking.bookingId#</cfoutput>, amount: amount },
					dataType: "json",
					success: function(response) {
						kendo.ui.ExtWaitDialog.hide();
						if (JSON.parse(response.success) == true) {
							try { refreshBookingsListWindow(); } catch (error) {}
							$("#bookingDetailWindow").data("kendoWindow").refresh();
						} else {
							$("#bookingRefundStatus").text(response.errorMessage || "The refund didn't go through.");
						}
					},
					error: function(jqXHR) {
						kendo.ui.ExtWaitDialog.hide();
						if (jqXHR.status === 403) { createLoginWindow(); }
					}
				});
			});
		});

		$("#bookingNotesSave").on("click", function() {
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBookingNotes',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', bookingId: <cfoutput>#theBooking.bookingId#</cfoutput>, notes: $("#bookingNotes").val() },
				dataType: "json",
				success: function(response) {
					$("#bookingNotesStatus").text(JSON.parse(response.success) == true ? "Saved." : "The notes could not be saved.");
				},
				error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});
	});
</script>

<cfoutput>
<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">#encodeForHtml(theBooking.name)#<cfif not structIsEmpty(theBooking.bookingType)> - #encodeForHtml(theBooking.bookingType.name)#</cfif></h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">#application.bookings.bookingDetailsHtml(theBooking, true)#<div style="clear: both;"></div></td></tr>
	<cfif theBooking.status eq "pending" or (listFind("pending,confirmed", theBooking.status) and not bookingIsPast) or (listFind("confirmed,completed,noShow", theBooking.status) and bookingIsPast)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><cfif theBooking.status eq "pending">Approving emails the client that it's confirmed.</cfif>
				<cfif listFind("pending,confirmed", theBooking.status) and not bookingIsPast>Cancelling frees the time and emails the client.</cfif>
				<cfif listFind("confirmed,completed,noShow", theBooking.status) and bookingIsPast>For your own records; the client isn't emailed.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Actions:</td>
		<td class="#blockClass#">
			<cfif theBooking.status eq "pending">
				<button type="button" class="k-button k-primary" id="bookingApprove">Approve</button>
			</cfif>
			<cfif listFind("pending,confirmed", theBooking.status) and not bookingIsPast>
				<button type="button" class="k-button" id="bookingCancel">Cancel booking</button>
			</cfif>
			<cfif listFind("confirmed,completed,noShow", theBooking.status) and bookingIsPast>
				<button type="button" class="k-button" id="bookingCompleted"<cfif theBooking.status eq "completed"> disabled</cfif>>Mark completed</button>
				<button type="button" class="k-button" id="bookingNoShow"<cfif theBooking.status eq "noShow"> disabled</cfif>>Mark no-show</button>
			</cfif>			
		</td>
	</tr>
	</cfif>
	<!--- Shown by the Cancel booking button. --->
	<tr class="blockSpacer bookingCancelRow" style="display: none;"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="bookingCancelRow"><td colspan="2" class="#blockClass#">Optional; it's added to the cancellation email.</td></tr>
	<tr class="blockSpacer bookingCancelRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr id="bookingCancelRow" class="bookingCancelRow" style="display: none;">
		<td class="#blockClass#" align="right"><label for="bookingCancelMessage">Note to the client:</label></td>
		<td class="#blockClass#">
			<textarea id="bookingCancelMessage" class="k-textbox" rows="3" maxlength="2000" style="width: 95%;" placeholder="eg. I'm sorry, I'm unwell that day. Please book another time."></textarea>			
		</td>
	</tr>
	<cfif bookingPaymentTotals.refundable gt 0>
	<tr class="blockSpacer bookingCancelRow" style="display: none;"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="bookingCancelRow" style="display: none;">
		<td class="#blockClass#" align="right"><label for="bookingCancelRefund">Refund:</label></td>
		<td class="#blockClass#">
			<input class="k-checkbox" type="checkbox" id="bookingCancelRefund" checked>
			<span class="k-form-hint">Refund what they paid online (#application.payments.formatMoney(bookingPaymentTotals.refundable, theBooking.currency)#).</span>
		</td>
	</tr>
	</cfif>
	<tr class="blockSpacer bookingCancelRow" style="display: none;"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="bookingCancelRow" style="display: none;">
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" id="bookingCancelConfirm">Cancel the booking and email the client</button></td>
	</tr>

	<cfif bookingPaymentTotals.paid gt 0 or (theBooking.balanceDue gt 0 and theBooking.amountPaid gt 0)>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Payment</h4></td></tr>
	<cfif theBooking.balanceDue gt 0 and not listFind("cancelled,expired,held", theBooking.status)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">For money taken at the session.<cfif application.bookings.canPayBalanceOnline(theBooking)> The client also has a "Pay the rest online" link in their emails.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Still to pay:</td>
		<td class="#blockClass#">
			#application.payments.formatMoney(theBooking.balanceDue, theBooking.currency)#
			<button type="button" class="k-button" id="bookingBalancePaid">Mark the rest as paid</button>			
		</td>
	</tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Paid online:</td>
		<td class="#blockClass#">#application.payments.formatMoney(bookingPaymentTotals.paid, theBooking.currency)#<cfif bookingPaymentTotals.refunded gt 0>, refunded #application.payments.formatMoney(bookingPaymentTotals.refunded, theBooking.currency)#</cfif></td>
	</tr>
	<cfif bookingPaymentTotals.refundable gt 0>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">A refund goes back to the client's card through Stripe. Refunds made in your Stripe dashboard show here too.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingRefundAmount">Refund:</label></td>
		<td class="#blockClass#">
			<input type="number" id="bookingRefundAmount" class="k-textbox" min="0.01" max="#bookingPaymentTotals.refundable#" step="0.01" value="#numberFormat(bookingPaymentTotals.refundable, '0.00')#" style="width: 110px;">
			<button type="button" class="k-button" id="bookingRefund">Refund</button> <span id="bookingRefundStatus" role="status"></span>
			<span class="k-form-hint">Up to #application.payments.formatMoney(bookingPaymentTotals.refundable, theBooking.currency)#.</span>
		</td>
	</tr>
	</cfif>
	</cfif>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Notes</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Private - only you see these.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingNotes">Notes:</label></td>
		<td class="#blockClass#">
			<textarea id="bookingNotes" class="k-textbox" rows="4" maxlength="2000" style="width: 95%;">#encodeForHtml(theBooking.notes)#</textarea>			
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" id="bookingNotesSave">Save notes</button> <span id="bookingNotesStatus" role="status"></span></td>
	</tr>
</table>
</cfoutput>
</cfif>
