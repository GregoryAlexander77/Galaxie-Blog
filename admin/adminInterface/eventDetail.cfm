<!--- Event (window 99, 2026-10-15), opened from the post editor's Event button with createAdminInterfaceWindow(99, postId). Turns the post
into an event: when (with its own time zone), where (the shared Locations), status, organizer, cost and an outside tickets link. Saved
straight away by ProxyController.cfc's saveEvent (no need to save the post); Remove event takes it off the post. Sign-ups (RSVP):
a form people fill in on the event card, an optional capacity in people, "how many are coming", and when sign-ups close; See
sign-ups opens window 100. Paid sign-ups (a price per person, paid through Stripe when signing up, refunded when cancelled early
enough) need Payments set up in Blog Options. See common/cfc/Events.cfc. --->
<cfset eventPostId = val(URL.optArgs)>
<cfset eventPost = application.blog.getPostByPostId(postId = eventPostId, showPendingPosts = true, showRemovedPosts = true)>
<!--- The blog owner is the default organizer (owner, 10-16): someone else may write the post for them. Falls back to the post's author. --->
<cfset eventOwnerUserId = len(application.blogOwner ?: "") ? application.blog.getUserIdByUserName(application.blogOwner) : 0>
<cfset eventDefaultOrganizerRef = eventOwnerUserId gt 0 ? "user:" & eventOwnerUserId : (arrayLen(eventPost) and val(eventPost[1]["UserId"]) ? "user:" & eventPost[1]["UserId"] : "")>
<cfset theEvent = application.events.getEvent(eventPostId)>
<cfset isNewEvent = structIsEmpty(theEvent)>
<cfset eventLocations = application.locations.getLocations()>
<cfset eventBlogZone = application.blog.getBlogTimeZoneId()>
<!--- A new event starts as next Saturday 7-9 PM, in the blog's time zone. --->
<cfif isNewEvent>
	<cfset eventStartDefault = dateAdd("d", 7 - dayOfWeek(application.blog.blogNow()) + (dayOfWeek(application.blog.blogNow()) eq 7 ? 7 : 0), application.blog.blogNow())>
	<cfset theEvent = { startLocal: dateFormat(eventStartDefault, "yyyy-mm-dd") & " 19:00", endLocal: dateFormat(eventStartDefault, "yyyy-mm-dd") & " 21:00", timeZone: eventBlogZone, allDay: false, status: "scheduled", organizerName: "", organizerUrl: (len(eventDefaultOrganizerRef) ? "person:" & eventDefaultOrganizerRef : ""), cost: "", ticketUrl: "", locationIds: [], webFormId: 0, capacity: 0, askPartySize: false, maxPartySize: 4, rsvpClosesLocal: "", price: 0, refundHours: 24 }>
</cfif>
<!--- Time zones with region names (eg. Europe/London), sorted. --->
<cfset eventZones = []>
<cfloop array="#createObject('java', 'java.time.ZoneId').getAvailableZoneIds().toArray()#" index="thisZone">
	<cfif reFind("^(Africa|America|Antarctica|Asia|Atlantic|Australia|Europe|Indian|Pacific)/", thisZone)><cfset arrayAppend(eventZones, thisZone)></cfif>
</cfloop>
<cfset arraySort(eventZones, "textnocase")>
<!--- The dropdown reads "America/Los Angeles"; the value keeps the real id, "America/Los_Angeles". --->
<cfset eventZoneChoices = []>
<cfloop array="#eventZones#" index="thisZone"><cfset arrayAppend(eventZoneChoices, { "text": replace(thisZone, "_", " ", "all"), "value": thisZone })></cfloop>
<!--- RSVP: the forms to choose from, and how many are coming so far. --->
<cfset eventForms = application.webForms.getForms()>
<!--- Organizer (2026-10-16): one of the People cards (the blog owner by default) (common/cfc/People.cfc - the admin users and guest cards), this blog, or
someone else typed in. A card is stored as person:user:5 / person:guest:3 in OrganizerUrl. --->
<cfset eventPeople = application.events.getPeople().getCards()>
<cfif left(theEvent.organizerUrl, 7) eq "person:">
	<cfset eventOrganizerMode = "person">
	<cfset eventOrganizerRef = mid(theEvent.organizerUrl, 8, 50)>
<cfelseif not len(theEvent.organizerName) or (theEvent.organizerName eq application.BlogDbObj.getBlogTitle() and (not len(theEvent.organizerUrl) or theEvent.organizerUrl eq application.blogHostUrl))>
	<cfset eventOrganizerMode = "blog">
	<cfset eventOrganizerRef = eventDefaultOrganizerRef>
<cfelse>
	<cfset eventOrganizerMode = "other">
	<cfset eventOrganizerRef = eventDefaultOrganizerRef>
</cfif>
<cfset eventOrganizerChoices = []>
<cfloop array="#eventPeople#" index="thisPerson">
	<cfset arrayAppend(eventOrganizerChoices, { "ref": thisPerson.ref, "name": thisPerson.name & (thisPerson.kind eq "guest" ? " (guest)" : "") })>
</cfloop>
<cfset eventRsvpState = isNewEvent ? {} : application.events.getRsvpState(theEvent)>
<cfset eventPaymentsReady = application.payments.getStatus().ready>
<cfset arrayPrepend(eventZones, "UTC")>

<script>
	$(document).ready(function() {
		var eventZones = <cfoutput>#serializeJson(eventZoneChoices)#</cfoutput>;
		$("#eventStartDate, #eventEndDate").kendoDatePicker({ format: "MMMM d, yyyy", parseFormats: ["yyyy-MM-dd"] });
		$("#eventStartTime, #eventEndTime").kendoTimePicker({ format: "h:mm tt", parseFormats: ["HH:mm", "h:mm tt"], interval: 15 });
		$("#eventTimeZone").kendoDropDownList({ dataSource: eventZones, dataTextField: "text", dataValueField: "value", filter: "contains" });
		$("#eventStatus").kendoDropDownList();
		<!--- A location added from here joins the list, checked (locationDetail.cfm triggers this on save). --->
		$(document).off("galaxieLocationSaved.event").on("galaxieLocationSaved.event", function(e, savedLocation) {
			if (!$("#eventLocationList").length || $("#eventLocationList input.eventLocation[value='" + savedLocation.locationOptionId + "']").length) { return; }
			$("#eventNoLocations").remove();
			var checkbox = $('<input type="checkbox" class="k-checkbox eventLocation" checked>').val(savedLocation.locationOptionId);
			$("#eventLocationList").append($("<label/>").append(checkbox).append(document.createTextNode(" " + savedLocation.label)), "<br/>");
		});
		$("#eventRsvpForm").kendoDropDownList({ filter: "contains", noDataTemplate: $("#eventRsvpFormNoData").html() });
		<!--- A form built from the Build Form button joins the list and is selected (webFormDetail.cfm triggers this on save). --->
		$(document).off("galaxieWebFormSaved.event").on("galaxieWebFormSaved.event", function(e, form) {
			galaxieAddToDropDown("eventRsvpForm", { value: String(form.webFormId), text: form.title }, "value");
		});
		<!--- Organizer (2026-10-16): a person (People cards), this blog, or someone else typed in. --->
		$("#eventOrganizerPerson").kendoDropDownList({
			dataSource: <cfoutput>#serializeJson(eventOrganizerChoices)#</cfoutput>,
			dataTextField: "name",
			dataValueField: "ref",
			filter: "contains",
			value: <cfoutput>#serializeJson(eventOrganizerRef)#</cfoutput>
		});
		function refreshOrganizerRows() {
			var mode = $("input[name=eventOrganizerMode]:checked").val();
			$(".eventOrganizerPersonRow").toggle(mode === "person");
			$(".eventOrganizerOtherRow").toggle(mode === "other");
		}
		$("input[name=eventOrganizerMode]").on("change", refreshOrganizerRows);
		refreshOrganizerRows();
		window.eventOrganizer = function() {
			var mode = $("input[name=eventOrganizerMode]:checked").val();
			if (mode === "person") { return { name: "", url: "person:" + ($("#eventOrganizerPerson").data("kendoDropDownList").value() || "") }; }
			if (mode === "blog") { return { name: <cfoutput>#serializeJson(application.BlogDbObj.getBlogTitle())#</cfoutput>, url: <cfoutput>#serializeJson(application.blogHostUrl)#</cfoutput> }; }
			return { name: $.trim($("#eventOrganizerName").val()), url: $.trim($("#eventOrganizerUrl").val()) };
		};
		<!--- A card added with Add a person joins the list and is selected (personDetail.cfm triggers this on save). --->
		$(document).off("galaxiePersonSaved.event").on("galaxiePersonSaved.event", function(e, person) {
			galaxieAddToDropDown("eventOrganizerPerson", { ref: person.ref, name: person.name + " (guest)" }, "ref");
		});
		$("#eventRsvpClosesDate").kendoDatePicker({ format: "MMMM d, yyyy", parseFormats: ["yyyy-MM-dd"] });
		$("#eventRsvpClosesTime").kendoTimePicker({ format: "h:mm tt", parseFormats: ["HH:mm", "h:mm tt"], interval: 15 });

		<!--- The most per sign-up only matters when people are asked how many are coming. --->
		<!--- A disabled field also gets Kendo's disabled class, so it looks disabled (owner, 10-16). --->
		function setDisabled(field, disabled) { $(field).prop("disabled", disabled).toggleClass("k-state-disabled", disabled); }
		function refreshPartySize() { setDisabled("#eventMaxPartySize", !$("#eventAskPartySize").is(":checked")); }
		$("#eventAskPartySize").on("change", refreshPartySize);
		refreshPartySize();
		<!--- Refunds only matter when there is a price (and the price needs Payments set up, see the Price field). --->
		function refreshRefunds() {
			var price = parseFloat($("#eventPrice").val());
			setDisabled("#eventRefundHours", $("#eventPrice").prop("disabled") || !(price > 0));
		}
		$("#eventPrice").on("input change", refreshRefunds);
		$("#eventPrice").toggleClass("k-state-disabled", $("#eventPrice").prop("disabled"));
		refreshRefunds();

		<!--- Times aren't needed for an all-day event. --->
		function refreshAllDay() {
			var allDay = $("#eventAllDay").is(":checked");
			$("#eventStartTime").data("kendoTimePicker").enable(!allDay);
			$("#eventEndTime").data("kendoTimePicker").enable(!allDay);
		}
		$("#eventAllDay").on("change", refreshAllDay);
		refreshAllDay();

		<!--- Moving the start date moves the end date with it, when the end was the same day or earlier. --->
		$("#eventStartDate").data("kendoDatePicker").bind("change", function() {
			var start = this.value(), endPicker = $("#eventEndDate").data("kendoDatePicker");
			if (start && (!endPicker.value() || endPicker.value() < start)) { endPicker.value(start); }
		});

		function dateText(picker) { var value = $(picker).data("kendoDatePicker").value(); return value ? kendo.toString(value, "yyyy-MM-dd") : ""; }
		function timeText(picker) { var value = $(picker).data("kendoTimePicker").value(); return value ? kendo.toString(value, "HH:mm") : ""; }

		$("#eventSubmit").on("click", function() {
			var data = {
				csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
				postId: <cfoutput>#eventPostId#</cfoutput>,
				startDate: dateText("#eventStartDate"), startTime: timeText("#eventStartTime"),
				endDate: dateText("#eventEndDate"), endTime: timeText("#eventEndTime"),
				allDay: $("#eventAllDay").is(":checked"),
				timeZone: $("#eventTimeZone").data("kendoDropDownList").value(),
				locationIds: $(".eventLocation:checked").map(function() { return this.value; }).get().join(","),
				status: $("#eventStatus").data("kendoDropDownList").value(),
				organizerName: eventOrganizer().name,
				organizerUrl: eventOrganizer().url,
				cost: $.trim($("#eventCost").val()),
				ticketUrl: $.trim($("#eventTicketUrl").val()),
				webFormId: $("#eventRsvpForm").data("kendoDropDownList").value(),
				capacity: $.trim($("#eventCapacity").val()),
				askPartySize: $("#eventAskPartySize").is(":checked"),
				maxPartySize: $.trim($("#eventMaxPartySize").val()),
				rsvpClosesDate: dateText("#eventRsvpClosesDate"),
				rsvpClosesTime: timeText("#eventRsvpClosesTime"),
				price: $.trim($("#eventPrice").val() || ""),
				refundHours: $.trim($("#eventRefundHours").val() || "")
			};
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the event.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveEvent",
				data: data,
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					<!--- The post editor shows Event as the post's type, with this summary (2026-10-16). --->
					if (response && response.success) { $(document).trigger("galaxieEventSaved", [{ postId: <cfoutput>#eventPostId#</cfoutput>, when: response.when || "" }]); }
					if (response && response.success && response.signupsLeft > 0) {
						<!--- Cancelled with people still signed up: offer to cancel their places (and refund) in one go. --->
						$.when(kendo.ui.ExtYesNoDialog.show({ title: "People are still signed up", message: "The event is saved as cancelled, but " + response.signupsLeft + (response.signupsLeft === 1 ? " person is" : " people are") + " still signed up. Cancel all their places now? Each person is emailed that the event is cancelled, and anything paid online is refunded in full.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
							try { $("#eventDetailWindow").data("kendoWindow").close(); } catch (error) {}
							if (answer.button !== "Yes") { return; }
							$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Cancelling the sign-ups and making the refunds.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
							jQuery.ajax({
								type: "post",
								url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=adminCancelAllRsvps",
								data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#eventPostId#</cfoutput> },
								dataType: "json",
								success: function(result) {
									kendo.ui.ExtWaitDialog.hide();
									if (!result || !result.success) { return; }
									var message = result.cancelled + (result.cancelled === 1 ? " sign-up was" : " sign-ups were") + " cancelled and everyone was emailed." + (result.refunded ? " Refunded: " + result.refunded + "." : "") + (result.refundProblems ? " " + result.refundProblems + " refund(s) didn't go through; please make those in your Stripe dashboard." : "");
									kendo.ui.ExtAlertDialog.show({ title: "Done", message: $("<div>").text(message).html(), icon: result.refundProblems ? "k-ext-warning" : "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
								},
								error: function(jqXHR) { kendo.ui.ExtWaitDialog.hide(); if (jqXHR.status === 403) { createLoginWindow(); } }
							});
						});
					} else if (response && response.success) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The event was saved. It shows on the post now.", icon: "k-ext-information" })).done(function() {
							try { $("#eventDetailWindow").data("kendoWindow").close(); } catch (error) {}
						});
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Please check the event", message: $("<div>").text(((response && response.errors) || ["The event could not be saved."]).join(" ")).html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) { createLoginWindow(); }
				}
			});
		});

		$("#eventDelete").on("click", function() {
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Remove the event?", message: "This takes the event details off the post. The post itself stays.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function(answer) {
				if (!answer['button'] || answer['button'] !== 'Yes') { return; }
				jQuery.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteEvent",
					data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", postId: <cfoutput>#eventPostId#</cfoutput> },
					dataType: "json",
					success: function(response) {
						if (response && response.success) {
							$(document).trigger("galaxieEventRemoved", [{ postId: <cfoutput>#eventPostId#</cfoutput> }]);
							try { $("#eventDetailWindow").data("kendoWindow").close(); } catch (error) {}
						} else if (response && response.errorMessage) {
							<!--- Refused while someone has paid for a place (2026-10-16): they are cancelled and refunded first. --->
							kendo.ui.ExtAlertDialog.show({ title: "The event stays", message: $("<div>").text(response.errorMessage).html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" });
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
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading"><cfif arrayLen(eventPost)>#encodeForHtml(eventPost[1]["Title"])#<cfelse>Event</cfif></h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">This post becomes an event: visitors see an event card with the date, time and place, and buttons to add it to their calendar. Search engines can show it as an event too. Saving here saves the event straight away.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Postponed or cancelled shows clearly on the event card, so people who planned to come know.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventStatus">Status:</label></td>
		<td class="#blockClass#">
			<select id="eventStatus" style="width: 220px;">
				<cfloop array="#application.events.getStatuses()#" index="thisStatus">
					<option value="#thisStatus.value#"<cfif thisStatus.value eq theEvent.status> selected</cfif>>#thisStatus.label#</option>
				</cfloop>
			</select>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">When</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventAllDay">All day:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="eventAllDay"<cfif theEvent.allDay> checked</cfif>></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventStartDate">Starts:</label></td>
		<td class="#blockClass#"><input id="eventStartDate" value="#listFirst(theEvent.startLocal, ' ')#" style="width: 210px;" aria-label="Start date"> <input id="eventStartTime" value="#listLast(theEvent.startLocal, ' ')#" style="width: 150px;" aria-label="Start time"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventEndDate">Ends:</label></td>
		<td class="#blockClass#"><input id="eventEndDate" value="#listFirst(theEvent.endLocal, ' ')#" style="width: 210px;" aria-label="End date"> <input id="eventEndTime" value="#listLast(theEvent.endLocal, ' ')#" style="width: 150px;" aria-label="End time"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">The times are in the event's own time zone. Visitors also see them in their own time zone when it's different.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventTimeZone">Time zone:</label></td>
		<td class="#blockClass#"><select id="eventTimeZone" style="width: 300px;"><option value="#encodeForHtmlAttribute(len(theEvent.timeZone) ? theEvent.timeZone : eventBlogZone)#" selected>#encodeForHtml(replace(len(theEvent.timeZone) ? theEvent.timeZone : eventBlogZone, "_", " ", "all"))#</option></select></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Where</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Check every location people can attend. With more than one (eg. in person or online), people say which when they sign up. Locations are shared with Bookings.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Locations:</td>
		<td class="#blockClass#">
			<cfset eventShownLocations = 0>
			<span id="eventLocationList">
			<cfloop array="#eventLocations#" index="thisLocation">
				<cfif thisLocation.active or arrayFind(theEvent.locationIds, thisLocation.locationOptionId)>
					<cfset eventShownLocations++>
					<label><input type="checkbox" class="k-checkbox eventLocation" value="#thisLocation.locationOptionId#"<cfif arrayFind(theEvent.locationIds, thisLocation.locationOptionId)> checked</cfif>> #encodeForHtml(thisLocation.label)#<cfif not thisLocation.active> (not active)</cfif></label><br>
				</cfif>
			</cfloop>
			</span>
			<cfif not eventShownLocations><span id="eventNoLocations">No locations yet.</span></cfif>
			<!--- With no locations yet, the button opens a new location straight away (owner, 10-16); a location saved there joins the list, checked. --->
			<button type="button" class="k-button" onclick="createAdminInterfaceWindow(#arrayLen(eventLocations) ? 88 : '89, 0'#);" style="margin-top: 6px;">Set up locations</button>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Details</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Who runs the event. A person's name on the event opens their card: picture, biography and a form that emails them directly. Add people who don't sign in, eg. a guest presenter, under <a href="javascript:createAdminInterfaceWindow(102);">People</a>.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Organizer:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="eventOrganizerMode" value="person"<cfif eventOrganizerMode eq "person"> checked</cfif>> A person</label> &nbsp;
			<label><input type="radio" class="k-radio" name="eventOrganizerMode" value="blog"<cfif eventOrganizerMode eq "blog"> checked</cfif>> This blog</label> &nbsp;
			<label><input type="radio" class="k-radio" name="eventOrganizerMode" value="other"<cfif eventOrganizerMode eq "other"> checked</cfif>> Someone else</label>
		</td>
	</tr>
	<tr class="blockSpacer eventOrganizerPersonRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="eventOrganizerPersonRow">
		<td class="#blockClass#" align="right"><label for="eventOrganizerPerson">Person:</label></td>
		<td class="#blockClass#"><input id="eventOrganizerPerson" style="width: 300px;"> <a href="javascript:galaxieAddRequest('eventOrganizerPerson'); createAdminInterfaceWindow(103, 0);">Add a person</a></td>
	</tr>
	<tr class="blockSpacer eventOrganizerOtherRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="eventOrganizerOtherRow">
		<td class="#blockClass#" align="right"><label for="eventOrganizerName">Name:</label></td>
		<td class="#blockClass#"><input type="text" id="eventOrganizerName" class="k-textbox" maxlength="125" value="#encodeForHtmlAttribute(eventOrganizerMode eq 'other' ? theEvent.organizerName : '')#" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer eventOrganizerOtherRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="eventOrganizerOtherRow">
		<td class="#blockClass#" align="right"><label for="eventOrganizerUrl">Link:</label></td>
		<td class="#blockClass#"><input type="text" id="eventOrganizerUrl" class="k-textbox" maxlength="500" placeholder="https://" value="#encodeForHtmlAttribute(eventOrganizerMode eq 'other' ? theEvent.organizerUrl : '')#" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventCost">Cost:</label></td>
		<td class="#blockClass#"><input type="text" id="eventCost" class="k-textbox" maxlength="125" placeholder="eg. Free, $20" value="#encodeForHtmlAttribute(theEvent.cost)#" style="width: 220px;"><span class="k-form-hint">Optional. With a price under Sign-ups, the price shows instead.</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Optional: a page where people buy tickets or register, when that happens on another site. It shows as a button on the event card.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventTicketUrl">Tickets link:</label></td>
		<td class="#blockClass#"><input type="text" id="eventTicketUrl" class="k-textbox" maxlength="500" placeholder="https://" value="#encodeForHtmlAttribute(theEvent.ticketUrl)#" style="width: 95%;"></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Sign-ups (RSVP)</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">To let people sign up, choose a form. It shows on the event card, and each person gets a confirmation email with a calendar file and a link to cancel. The form needs an Email field. Don't also insert the same form into the post.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventRsvpForm">Sign-up form:</label></td>
		<td class="#blockClass#">
			<select id="eventRsvpForm" style="width: 300px;">
				<option value="0">No sign-ups</option>
				<cfloop array="#eventForms#" index="thisForm">
					<cfif thisForm.active or thisForm.webFormId eq theEvent.webFormId>
						<option value="#thisForm.webFormId#"<cfif thisForm.webFormId eq theEvent.webFormId> selected</cfif>>#encodeForHtml(thisForm.title)#<cfif not thisForm.active> (not active)</cfif></option>
					</cfif>
				</cfloop>
			</select>
			<!--- A button that would open an empty list opens the window to add one instead (owner, 10-16). --->
			<button type="button" class="k-button" onclick="<cfif arrayLen(eventForms)>createAdminInterfaceWindow(83);<cfelse>galaxieAddRequest('eventRsvpForm'); createAdminInterfaceWindow(84, 0);</cfif>">Set up forms</button>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Capacity counts people, not sign-ups: someone coming with two friends takes 3 places. When it's full, the form is replaced by "This event is full". Leave it empty for no limit.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventCapacity">Capacity:</label></td>
		<td class="#blockClass#"><input type="text" id="eventCapacity" class="k-textbox" inputmode="numeric" maxlength="7" value="#theEvent.capacity gt 0 ? theEvent.capacity : ''#" style="width: 120px;"><span class="k-form-hint">people</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventAskPartySize">Ask how many:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="eventAskPartySize"<cfif theEvent.askPartySize> checked</cfif>> <label for="eventAskPartySize">Ask how many people are coming</label></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventMaxPartySize">Most per sign-up:</label></td>
		<td class="#blockClass#"><input type="text" id="eventMaxPartySize" class="k-textbox" inputmode="numeric" maxlength="2" value="#theEvent.askPartySize ? theEvent.maxPartySize : 4#" style="width: 120px;"><span class="k-form-hint">people, including the person signing up</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">To charge for a place, enter a price per person: people pay online through Stripe when they sign up, and their place is confirmed once the payment goes through. Leave it empty for a free event.<cfif not eventPaymentsReady> Payments aren't set up yet: turn them on in <a href="javascript:createAdminInterfaceWindow(38, 'payments');">Blog Options &gt; Payments</a> first.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventPrice">Price:</label></td>
		<td class="#blockClass#"><input type="text" id="eventPrice" class="k-textbox" inputmode="decimal" maxlength="10" value="#theEvent.price gt 0 ? numberFormat(theEvent.price, '0.00') : ''#" style="width: 120px;"<cfif not eventPaymentsReady and theEvent.price lte 0> disabled</cfif>><span class="k-form-hint">per person, in #encodeForHtml(application.payments.getCurrency())#</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventRefundHours">Refunds:</label></td>
		<td class="#blockClass#"><input type="text" id="eventRefundHours" class="k-textbox" inputmode="numeric" maxlength="4" value="#theEvent.refundHours#" style="width: 120px;"><span class="k-form-hint">hours before the start a cancelled place is still refunded; 0 for no refunds</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Optional: stop sign-ups earlier, eg. the day before, to plan food or seating. Leave empty to take sign-ups until the event starts. In the event's time zone.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="eventRsvpClosesDate">Sign-ups close:</label></td>
		<td class="#blockClass#"><input id="eventRsvpClosesDate" value="#len(theEvent.rsvpClosesLocal) ? listFirst(theEvent.rsvpClosesLocal, ' ') : ''#" style="width: 210px;" aria-label="Day sign-ups close"> <input id="eventRsvpClosesTime" value="#len(theEvent.rsvpClosesLocal) ? listLast(theEvent.rsvpClosesLocal, ' ') : ''#" style="width: 150px;" aria-label="Time sign-ups close"></td>
	</tr>
	<cfif not isNewEvent and theEvent.webFormId gt 0>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Coming:</td>
		<td class="#blockClass#">#eventRsvpState.taken#<cfif theEvent.capacity gt 0> of #theEvent.capacity#</cfif> <cfif eventRsvpState.taken eq 1 and theEvent.capacity eq 0>person<cfelse>people</cfif> <button type="button" class="k-button" onclick="createAdminInterfaceWindow(100, #eventPostId#);">See sign-ups</button></td>
	</tr>
	</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button type="button" class="k-button k-primary" id="eventSubmit">Save event</button><cfif not isNewEvent> <button type="button" class="k-button" id="eventDelete">Remove event</button></cfif></td>
	</tr>
</table>
</cfoutput>

<!--- "Not found? Add it" template for the sign-up form dropdown (common/js/adminDropDowns.js). Outside cfoutput: Kendo templates use #. --->
<script id="eventRsvpFormNoData" type="text/x-kendo-tmpl">
	# var value = galaxieTypedText(instance); #
	<div># if (value.length) { #Form not found. Do you want to build '#: value #'?# } else { #There are no forms yet.# } #</div>
	<br />
	<button type="button" class="k-button" onclick="galaxieAddRequest('eventRsvpForm'); createAdminInterfaceWindow(84, 0, #= kendo.htmlEncode(JSON.stringify(encodeURIComponent(value))) #)">Build Form</button>
</script>
