<!--- Booking page (window 104, 2026-10-17), opened with createAdminInterfaceWindow(104, postId) from the post editor's Booking
details button, New post > Booking, and the Bookings window. A booking page is a Page whose text is followed by the booking
widget, offering every booking type, one category or one booking type (common/cfc/Bookings.cfc, Booking pages). Saved straight
away by ProxyController.cfc's saveBookingPage; Make it an ordinary page takes the widget off (removeBookingPage). --->
<cfset bookingPagePostId = val(URL.optArgs)>
<cfset bookingPagePost = application.blog.getPostByPostId(postId = bookingPagePostId, showPendingPosts = true, showRemovedPosts = true)>
<cfset bookingPageOffer = application.bookings.getPageOffer(bookingPagePostId)>
<cfset bookingPageChoices = application.bookings.getOfferChoices()>
<cfset bookingPageTypeCount = arrayLen(application.bookings.getBookingTypes(activeOnly = true))>

<script>
	$(document).ready(function() {
		var bookingPageChoices = <cfoutput>#serializeJson(bookingPageChoices)#</cfoutput>;
		var offerList = $("#bookingPageOffer").kendoDropDownList({
			dataSource: bookingPageChoices,
			dataTextField: "text",
			dataValueField: "value",
			filter: "contains"
		}).data("kendoDropDownList");
		offerList.value(<cfoutput>#serializeJson(len(bookingPageOffer) ? bookingPageOffer : "*")#</cfoutput>);

		function closeWindow() {
			try { $("#bookingPageWindow").data("kendoWindow").close(); } catch (error) {}
		}

		$("#bookingPageSave").on("click", function() {
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBookingPage",
				data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#bookingPagePostId#</cfoutput>, offer: offerList.value() },
				dataType: "json",
				success: function(response) {
					if (!response || !response.success) {
						kendo.ui.ExtAlertDialog.show({ title: "Not saved", message: $("<div>").text((response && response.errorMessage) || "The booking page could not be saved.").html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
						return;
					}
					<!--- The post editor keeps its Post Type row current. --->
					$(document).trigger("galaxieBookingPageSaved", [{ postId: <cfoutput>#bookingPagePostId#</cfoutput>, label: response.label }]);
					closeWindow();
				},
				error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});

		$("#bookingPageRemove").on("click", function() {
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Make it an ordinary page?", message: "The booking form comes off the page. The page and its text stay.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removeBookingPage",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#bookingPagePostId#</cfoutput> },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							$(document).trigger("galaxieBookingPageRemoved", [{ postId: <cfoutput>#bookingPagePostId#</cfoutput> }]);
							closeWindow();
						}
					},
					error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
				});
			});
		});
	});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<!--- No heading (owner, 10-22): the window title already says "Booking page", like the Shop page window. --->
	<tr><td colspan="2" class="#blockClass#">A booking page is a page where visitors book a time with you. It stays up for as long as you offer the booking: it isn't dated and doesn't go out in your RSS feed. The page's own text shows first, then the booking form.</td></tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">What visitors can book here: every kind of booking you offer, one category of them, or one booking type. <a href="javascript:createAdminInterfaceWindow(#bookingPageTypeCount ? 90 : '91, 0'#);">Booking types</a></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingPageOffer">Offers:</label></td>
		<td class="#blockClass#"><input id="bookingPageOffer" style="width: 90%;"><cfif not bookingPageTypeCount><div class="k-form-hint">You have no active booking types yet, so the page won't show a booking form until you add one.</div></cfif></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" id="bookingPageSave">Save</button><cfif len(bookingPageOffer)> <button type="button" class="k-button" id="bookingPageRemove">Make it an ordinary page</button></cfif></td>
	</tr>
</table>
</cfoutput>
