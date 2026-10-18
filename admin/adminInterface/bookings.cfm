<!--- Bookings (window 87, 2026-10-14): the starting point for appointments - visitors booking a time with the blog owner (a
consultation, a session, a lesson). Opened from the Bookings icon on the admin home page. Each part opens its own window:
Locations (88), Booking types (90), Hours (92) and the Bookings list (94).
See doc/aiDraftArticles/eventsAndFormsDesign.cfm, Part 3. --->
<cfset bookingLocationCount = arrayLen(application.locations.getLocations())>
<cfset bookingTypeCount = arrayLen(application.bookings.getBookingTypes())>
<!--- A button that would open an empty list opens the window to add one instead (owner, 10-16). --->
<!--- (Locations and Booking types below open the editor for a new one while there are none.) --->
<cfset bookingTimeZone = application.blog.getBlogTimeZoneId()>
<!--- Booking pages (2026-10-17): the pages visitors book on. --->
<cfset bookingPages = application.bookings.getBookingPages()>
<cfset bookingUpcoming = application.bookings.getBookingsForList("upcoming")>
<cfset bookingPendingCount = 0>
<cfloop array="#bookingUpcoming#" index="thisBooking">
	<cfif thisBooking.status eq "pending"><cfset bookingPendingCount = bookingPendingCount + 1></cfif>
</cfloop>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<!--- adminHub: a clearer line between the sections (owner, 10-16). See blogContentCss.cfm. --->
<table align="center" class="k-content adminBlocks adminHub" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">Let visitors book a time with you: a consultation, a session, a lesson. Set up where you meet, the kinds of bookings you offer, and when you're available.</td></tr>
	<!--- How visitors get to book (owner, 2026-10-17): the window only set things up, so it wasn't clear how a booking reaches the site.
	The buttons (owner, 2026-10-17): daily use first (Bookings, Calendar), then New booking page, then the setup (Booking types, Locations, Hours). --->
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><b>How to start taking bookings:</b> set up your Booking types, Locations and Hours below, then click <b>New booking page</b> to make a page where visitors book. To add bookings to a page you already have instead, open the page and choose <b>Insert &gt; Booking</b> (or the calendar button in the editor's toolbar).</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(94, 'upcoming');">Bookings</button></td>
		<td class="#blockClass#">The bookings clients have made: approve, cancel, and keep notes. (#arrayLen(bookingUpcoming)# upcoming<cfif bookingPendingCount>, #bookingPendingCount# waiting for your approval</cfif>)</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(96);">Calendar</button></td>
		<td class="#blockClass#">Your bookings on a calendar: by month, week or day.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(24, 'newBooking');">New booking page</button></td>
		<td class="#blockClass#">Where visitors book: a page with your text and the booking form. It stays up, isn't dated and isn't in your RSS feed.<cfif arrayLen(bookingPages)><cfloop array="#bookingPages#" index="thisBookingPage"><br/><a href="#encodeForHtmlAttribute(thisBookingPage.url)#" target="_blank" rel="noopener">#encodeForHtml(thisBookingPage.title)#</a> (#encodeForHtml(thisBookingPage.label)#<cfif not thisBookingPage.released>, not released</cfif>) <a href="javascript:createAdminInterfaceWindow(6, #thisBookingPage.postId#);">Edit</a></cfloop><cfelse> (none yet)</cfif></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(#bookingTypeCount ? 90 : '91, 0'#);">Booking types</button></td>
		<td class="#blockClass#">What can be booked: its length, price, where it happens, and the rules for booking it. (#bookingTypeCount# set up)</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(#bookingLocationCount ? 88 : '89, 0'#);">Locations</button></td>
		<td class="#blockClass#">Where you meet: in person, online or by phone. A booking type can offer several, and the client chooses. (#bookingLocationCount# set up)</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" style="width: 100%;" onclick="createAdminInterfaceWindow(92);">Hours</button></td>
		<td class="#blockClass#">When you're available each week, per location if you like, and your days off. <cfif len(bookingTimeZone)>Times are in your blog's time zone, #encodeForHtml(replace(bookingTimeZone, "_", " ", "all"))# (<a href="javascript:createAdminInterfaceWindow(39);">Blog Settings</a>).<cfelse>Set your time zone in <a href="javascript:createAdminInterfaceWindow(39);">Blog Settings</a> first.</cfif></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Your calendar</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<!--- The private calendar feed (2026-10-15) - see Bookings.cfc getFeedUrl and common/services/bookingsFeed.cfm. --->
	<tr><td colspan="2" class="#blockClass#">Subscribe to this private address and your bookings appear in your own calendar. Google Calendar: Other calendars &gt; + &gt; From URL. Outlook: Add calendar &gt; Subscribe from web. Apple Calendar: File &gt; New Calendar Subscription. Calendars check it every few hours, so a new booking can take a while to show.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Keep it to yourself; if it's ever shared by mistake, make a new one.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="bookingFeedUrl">Address:</label></td>
		<td class="#blockClass#">
			<textarea id="bookingFeedUrl" class="k-textbox" readonly rows="2" style="width: 95%; resize: none; word-break: break-all;" onclick="this.select();">#encodeForHtml(application.bookings.getFeedUrl())#</textarea>			
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button" id="bookingFeedNew">Make a new address</button> <span id="bookingFeedStatus" role="status"></span></td>
	</tr>
</table>
</cfoutput>
<script>
	$("#bookingFeedNew").on("click", function() {
		$.when(kendo.ui.ExtYesNoDialog.show({ title: "Make a new address?", message: "The old address will stop working right away. Any calendar you subscribed with it (Google, Outlook, Apple) stops updating until you subscribe it to the new address.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
			if (!answer['button'] || answer['button'] !== 'Yes') { return; }
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=newBookingsFeedAddress',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>' },
				dataType: "json",
				success: function(response) {
					if (response && response.feedUrl) { $("#bookingFeedUrl").val(response.feedUrl); $("#bookingFeedStatus").text("New address made."); }
					else { $("#bookingFeedStatus").text("The address couldn't be changed."); }
				},
				error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});
	});
</script>
