<!--- An event's sign-ups (window 100, 2026-10-15), opened from the Event window (99) or the Events list (101) with
createAdminInterfaceWindow(100, postId). Confirmed sign-ups first, then cancelled ones; the people count against the capacity;
Cancel frees a sign-up's places, refunds what they paid online and emails the person (ProxyController.cfc's adminCancelRsvp);
Export to CSV downloads them all (exportEventRsvps). Cancel all and refund (adminCancelAllRsvps) does Cancel for every
confirmed sign-up at once, eg. when the event is cancelled. Paid events also show sign-ups on the payment page now (Paying) and ones
that left without paying (Not paid). See common/cfc/Events.cfc. --->
<cfset rsvpPostId = val(URL.optArgs)>
<cfset rsvpEvent = application.events.getEvent(rsvpPostId)>
<cfset rsvpPost = application.events.getPostInfo(rsvpPostId)>
<cfif structIsEmpty(rsvpEvent)>
	<p>This post isn't an event any more.</p>
	<cfexit>
</cfif>
<cfset rsvpState = application.events.getRsvpState(rsvpEvent)>
<cfset rsvpList = application.events.getRsvps(rsvpEvent.eventId)>
<cfset rsvpConfirmed = 0>
<cfset rsvpIsPaid = rsvpEvent.price gt 0>
<cfset rsvpPaidTotal = 0>
<cfloop array="#rsvpList#" index="thisRsvp"><cfif thisRsvp.status eq "confirmed"><cfset rsvpConfirmed++></cfif><cfif thisRsvp.amountPaid gt 0 and thisRsvp.paymentStatus neq "refunded"><cfset rsvpPaidTotal = rsvpPaidTotal + thisRsvp.amountPaid></cfif><cfif thisRsvp.amountPaid gt 0 or rsvpIsPaid><cfset rsvpIsPaid = true></cfif></cfloop>

<script>
	$(document).ready(function() {
		$("#eventRsvpCancelAll").on("click", function() {
			var button = $(this);
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Cancel all sign-ups?", message: button.attr("data-question"), icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (answer.button !== "Yes") { return; }
				$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Cancelling the sign-ups and making the refunds.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminCancelAllRsvps",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#rsvpPostId#</cfoutput> },
					dataType: "json",
					success: function(response) {
						kendo.ui.ExtWaitDialog.hide();
						if (!response || !response.success) { return; }
						var message = response.cancelled + (response.cancelled === 1 ? " sign-up was" : " sign-ups were") + " cancelled and everyone was emailed." + (response.refunded ? " Refunded: " + response.refunded + "." : "") + (response.refundProblems ? " " + response.refundProblems + " refund(s) didn't go through; please make those in your Stripe dashboard." : "");
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Done", message: $("<div>").text(message).html(), icon: response.refundProblems ? "k-ext-warning" : "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function() {
							try { $("#eventRsvpsWindow").data("kendoWindow").close(); } catch (error) {}
							createAdminInterfaceWindow(100, <cfoutput>#rsvpPostId#</cfoutput>);
						});
					},
					error: function(jqXHR) { kendo.ui.ExtWaitDialog.hide(); if (jqXHR.status === 403) { createLoginWindow(); } }
				});
			});
		});

		$("#eventRsvpRows").on("click", ".eventRsvpCancel", function() {
			var button = $(this);
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Cancel this sign-up?", message: "Their places are freed for someone else, anything they paid online is refunded in full, and they're emailed that the organizer cancelled it. The sign-up stays in this list, shown as cancelled.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (answer.button !== "Yes") { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminCancelRsvp",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", submissionId: button.attr("data-id") },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							<!--- Reopen the window, so the counts are right. --->
							try { $("#eventRsvpsWindow").data("kendoWindow").close(); } catch (error) {}
							createAdminInterfaceWindow(100, <cfoutput>#rsvpPostId#</cfoutput>);
						}
					},
					error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
				});
			});
		});
	});
</script>

<script>
	<!--- Add a sign-up (owner, 10-16): for someone who signed up by phone, by email or in person. ProxyController.cfc's adminAddRsvp. --->
	$(document).ready(function() {
		$("#eventRsvpAdd").on("click", function() {
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Adding the sign-up.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminAddRsvp",
				data: {
					csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
					postId: <cfoutput>#rsvpPostId#</cfoutput>,
					name: $.trim($("#eventRsvpAddName").val()),
					email: $.trim($("#eventRsvpAddEmail").val()),
					partySize: $("#eventRsvpAddPeople").val() || 1,
					locationOptionId: $("#eventRsvpAddHow").val() || 0,
					sendEmail: $("#eventRsvpAddSendEmail").is(":checked")
				},
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (!response || !response.success) {
						kendo.ui.ExtAlertDialog.show({ title: "Not added", message: $("<div>").text((response && response.errorMessage) || "The sign-up could not be added.").html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
						return;
					}
					try { $("#eventRsvpsWindow").data("kendoWindow").close(); } catch (error) {}
					createAdminInterfaceWindow(100, <cfoutput>#rsvpPostId#</cfoutput>);
				},
				error: function(jqXHR) { kendo.ui.ExtWaitDialog.hide(); if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});
	});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">#encodeForHtml(rsvpPost.title)#</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">When:</td>
		<td class="#blockClass#">#encodeForHtml(application.events.whenText(rsvpEvent))#</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Coming:</td>
		<td class="#blockClass#">#rsvpState.taken#<cfif rsvpEvent.capacity gt 0> of #rsvpEvent.capacity#</cfif> <cfif rsvpState.taken eq 1 and rsvpEvent.capacity eq 0>person<cfelse>people</cfif> (#rsvpConfirmed# sign-up<cfif rsvpConfirmed neq 1>s</cfif>)<cfif not rsvpState.open and len(rsvpState.message)><span class="k-form-hint">#encodeForHtml(rsvpState.message)#</span></cfif></td>
	</tr>
	<cfif rsvpIsPaid>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Paid:</td>
		<td class="#blockClass#">#encodeForHtml(application.payments.formatMoney(rsvpPaidTotal))#<span class="k-form-hint">online, not counting refunded sign-ups</span></td>
	</tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><a class="k-button" href="#application.baseUrl#/common/cfc/ProxyController.cfc?method=exportEventRsvps&amp;postId=#rsvpPostId#&amp;csrfToken=#encodeForUrl(csrfToken)#">Export to CSV</a> <button type="button" class="k-button" onclick="createAdminInterfaceWindow(99, #rsvpPostId#);">Event settings</button><cfif rsvpConfirmed gt 0> <button type="button" class="k-button" id="eventRsvpCancelAll" data-question="#encodeForHtmlAttribute('Cancel all ' & rsvpConfirmed & (rsvpConfirmed eq 1 ? ' sign-up' : ' sign-ups') & '? Everyone is emailed that their place is cancelled' & (rsvpEvent.status eq 'cancelled' ? ' because the event is cancelled' : '') & (rsvpPaidTotal gt 0 ? ', and what they paid online is refunded in full' : '') & '. This can''t be undone.')#">Cancel all<cfif rsvpPaidTotal gt 0> and refund</cfif></button></cfif></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
		<cfif not arrayLen(rsvpList)>
			No sign-ups yet.
		<cfelse>
			<table width="100%" cellpadding="4" cellspacing="0" border="0">
				<cfif not session.isMobile>
				<thead>
					<tr>
						<th align="left">Name</th>
						<th align="left">Email</th>
						<th align="left">People</th>
						<cfif arrayLen(rsvpEvent.locations) gt 1><th align="left">How</th></cfif>
						<th align="left">Signed up</th>
						<cfif rsvpIsPaid><th align="left">Paid</th></cfif>
						<th align="left">Status</th>
						<th></th>
					</tr>
				</thead>
				</cfif>
				<tbody id="eventRsvpRows">
				<cfloop array="#rsvpList#" index="thisRsvp">
					<cfif thisRsvp.status eq "cancelled">
						<cfset thisStatus = "Cancelled" & (isDate(thisRsvp.cancelledAt) ? " " & dateFormat(thisRsvp.cancelledAt, "mmm d") : "")>
					<cfelseif thisRsvp.status eq "held" and thisRsvp.paying>
						<cfset thisStatus = "Paying now">
					<cfelseif listFind("held,expired", thisRsvp.status)>
						<cfset thisStatus = "Not paid">
					<cfelse>
						<cfset thisStatus = "Confirmed">
					</cfif>
					<cfset thisPaid = thisRsvp.amountPaid gt 0 ? application.payments.formatMoney(thisRsvp.amountPaid) & (thisRsvp.paymentStatus eq "refunded" ? " (refunded)" : (thisRsvp.paymentStatus eq "partlyRefunded" ? " (partly refunded)" : "")) : "">
					<cfif session.isMobile>
					<!--- Mobile: each sign-up as a small card. --->
					<tr>
						<td style="border-top: 1px solid ##ddd; padding: 8px 0;">
							<b>#len(thisRsvp.name) ? encodeForHtml(thisRsvp.name) : "(no name)"#</b><br>
							#encodeForHtml(thisRsvp.email)#<br>
							#thisRsvp.partySize# <cfif thisRsvp.partySize eq 1>person<cfelse>people</cfif><cfif len(thisRsvp.locationLabel)>, #encodeForHtml(thisRsvp.locationLabel)#</cfif><br>
							Signed up #isDate(thisRsvp.created) ? dateFormat(thisRsvp.created, "mmm d, yyyy") : ""#. #thisStatus#<cfif len(thisPaid)>. Paid #encodeForHtml(thisPaid)#</cfif>
							<cfif thisRsvp.status eq "confirmed"><br><button type="button" class="k-button eventRsvpCancel" data-id="#thisRsvp.submissionId#">Cancel</button></cfif>
						</td>
					</tr>
					<cfelse>
					<tr>
						<td style="border-top: 1px solid ##ddd;">#len(thisRsvp.name) ? encodeForHtml(thisRsvp.name) : "(no name)"#</td>
						<td style="border-top: 1px solid ##ddd;">#encodeForHtml(thisRsvp.email)#</td>
						<td style="border-top: 1px solid ##ddd;">#thisRsvp.partySize#</td>
						<cfif arrayLen(rsvpEvent.locations) gt 1><td style="border-top: 1px solid ##ddd;">#encodeForHtml(thisRsvp.locationLabel)#</td></cfif>
						<td style="border-top: 1px solid ##ddd;">#isDate(thisRsvp.created) ? dateFormat(thisRsvp.created, "mmm d, yyyy") : ""#</td>
						<cfif rsvpIsPaid><td style="border-top: 1px solid ##ddd;">#encodeForHtml(thisPaid)#</td></cfif>
						<td style="border-top: 1px solid ##ddd;">#thisStatus#</td>
						<td style="border-top: 1px solid ##ddd;" align="right"><cfif thisRsvp.status eq "confirmed"><button type="button" class="k-button eventRsvpCancel" data-id="#thisRsvp.submissionId#">Cancel</button></cfif></td>
					</tr>
					</cfif>
				</cfloop>
				</tbody>
			</table>
		</cfif>
		</td>
	</tr>

	<!--- Add a sign-up (owner, 10-16). --->
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Add a sign-up</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">For someone who signed up by phone, by email or in person. Their place is confirmed straight away, with nothing to pay online, even after sign-ups close or when the event is full.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventRsvpAddName">Name:</label></td>
		<td class="#blockClass#"><input type="text" id="eventRsvpAddName" class="k-textbox" maxlength="125" style="width: 60%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventRsvpAddEmail">Email:</label></td>
		<td class="#blockClass#"><input type="email" id="eventRsvpAddEmail" class="k-textbox" maxlength="255" style="width: 60%;"></td>
	</tr>
	<cfif rsvpEvent.askPartySize>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventRsvpAddPeople">People:</label></td>
		<td class="#blockClass#"><input type="number" id="eventRsvpAddPeople" class="k-textbox" min="1" max="99" value="1" style="width: 80px;"><span class="k-form-hint">including them</span></td>
	</tr>
	</cfif>
	<cfif arrayLen(rsvpEvent.locations) gt 1>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventRsvpAddHow">How:</label></td>
		<td class="#blockClass#"><select id="eventRsvpAddHow" class="k-textbox" style="width: 60%;"><cfloop array="#rsvpEvent.locations#" index="thisPlace"><option value="#thisPlace.locationOptionId#">#encodeForHtml(thisPlace.label)#</option></cfloop></select></td>
	</tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="eventRsvpAddSendEmail" checked> <label for="eventRsvpAddSendEmail">Email them a confirmation</label><span class="k-form-hint">with the calendar file and a link to cancel</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" id="eventRsvpAdd">Add sign-up</button></td>
	</tr>
</table>
</cfoutput>
