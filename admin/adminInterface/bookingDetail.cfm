<!--- One booking (window 95, 2026-10-14), opened from the Bookings list (94) with createAdminInterfaceWindow(95, bookingId). Shows the
booking as the owner's email does (application.bookings.bookingDetailsHtml), and lets the owner approve it, cancel it (with an optional
note to the client), mark it completed or a no-show, and keep private notes. Approving and cancelling email the client.
Saved by ProxyController.cfc's setBookingStatus and saveBookingNotes. --->
<cfset bookingId = val(URL.optArgs)>
<cfset theBooking = application.bookings.getBooking(bookingId = bookingId)>
<cfset bookingIsPast = not structIsEmpty(theBooking) and theBooking.startLocal lte dateTimeFormat(application.blog.blogNow(), "yyyy-mm-dd HH:nn")>

<cfif structIsEmpty(theBooking)>
	<p>That booking no longer exists.</p>
<cfelse>
<script>
	$(document).ready(function() {

		function setStatus(status, message) {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=setBookingStatus',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', bookingId: <cfoutput>#theBooking.bookingId#</cfoutput>, status: status, message: message || "" },
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
		$("#bookingCancel").on("click", function() { $("#bookingCancelRow").show(); $("#bookingCancelMessage").focus(); });
		$("#bookingCancelConfirm").on("click", function() { setStatus("cancelled", $.trim($("#bookingCancelMessage").val())); });

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
<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr><td class="k-header"><b>#encodeForHtml(theBooking.name)#<cfif not structIsEmpty(theBooking.bookingType)> - #encodeForHtml(theBooking.bookingType.name)#</cfif></b></td></tr>
	<tr><td>#application.bookings.bookingDetailsHtml(theBooking, true)#<div style="clear: both;"></div></td></tr>
	<tr>
		<td>
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
			<div class="k-form-hint">
				<cfif theBooking.status eq "pending">Approving emails the client that it's confirmed.</cfif>
				<cfif listFind("pending,confirmed", theBooking.status) and not bookingIsPast>Cancelling frees the time and emails the client.</cfif>
			</div>
		</td>
	</tr>
	<tr id="bookingCancelRow" style="display: none;">
		<td>
			<label for="bookingCancelMessage">A note to the client (optional):</label><br/>
			<textarea id="bookingCancelMessage" class="k-textbox" rows="3" maxlength="2000" style="width: 95%;" placeholder="eg. I'm sorry, I'm unwell that day. Please book another time."></textarea><br/>
			<button type="button" class="k-button k-primary" id="bookingCancelConfirm">Cancel the booking and email the client</button>
		</td>
	</tr>
	<tr><td class="k-header"><b>Notes</b></td></tr>
	<tr>
		<td>
			<textarea id="bookingNotes" class="k-textbox" rows="4" maxlength="2000" style="width: 95%;">#encodeForHtml(theBooking.notes)#</textarea>
			<div class="k-form-hint">Private - only you see these.</div>
			<button type="button" class="k-button" id="bookingNotesSave">Save notes</button> <span id="bookingNotesStatus" role="status"></span>
		</td>
	</tr>
</table>
</cfoutput>
</cfif>
