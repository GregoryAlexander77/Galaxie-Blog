<!--- Hours (window 92, 2026-10-14): when the blog owner takes bookings. The general weekly hours apply to every location; a location
can have its own hours instead (eg. the office only on Tuesdays). Below them, days off and days with different hours. Times are
wall-clock times in the blog's time zone (Blog Settings). Saved by ProxyController.cfc's saveBookingHours, saveAvailabilityException
and deleteAvailabilityException -> application.bookings (common/cfc/Bookings.cfc), which checks everything again. --->
<cfset hoursLocations = application.locations.getLocations()>
<cfset hoursByLocation = { "0": application.bookings.getHours(0) }>
<cfloop array="#hoursLocations#" index="thisLocation">
	<cfset hoursByLocation[thisLocation.locationOptionId] = application.bookings.getHours(thisLocation.locationOptionId)>
</cfloop>
<cfset hoursChoices = [{ "value": 0, "text": "General hours (every location)" }]>
<cfloop array="#hoursLocations#" index="thisLocation">
	<cfset arrayAppend(hoursChoices, { "value": thisLocation.locationOptionId, "text": thisLocation.label & (thisLocation.active ? "" : " (not active)") })>
</cfloop>
<cfset hoursExceptions = application.bookings.getExceptions()>
<cfset hoursLocationNames = { "0": "Every location" }>
<cfloop array="#hoursLocations#" index="thisLocation">
	<cfset hoursLocationNames[thisLocation.locationOptionId] = thisLocation.label>
</cfloop>
<cfset hoursTimeZone = application.blog.getBlogTimeZoneId()>

<style>
	#hoursDays tr:not(.blockSpacer) td { vertical-align: top; }
	.hoursRange { margin-bottom: 4px; white-space: nowrap; }
	.hoursRange .k-timepicker { width: 145px; }
<cfif session.isMobile>
	<!--- Phones: a day's hours may wrap, and the pickers are a little narrower, so nothing runs off the screen. --->
	.hoursRange { white-space: normal; }
	.hoursRange .k-timepicker { width: 125px; }
</cfif>
</style>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<script>
	<!--- The colour of the block the day rows sit in (HtmlUtils getKendoClass). --->
	var hoursDaysClass = "<cfoutput>#blockClass#</cfoutput>";
	$(document).ready(function() {

		var hoursByLocation = <cfoutput>#serializeJson(hoursByLocation)#</cfoutput>;
		var dayNames = <cfoutput>#serializeJson(application.bookings.getDayNames())#</cfoutput>;
		var currentLocation = "0";

		<!--- One time range: two Kendo TimePickers that show 9:00 AM but give "HH:mm". --->
		function rangeHtml(range) {
			var row = $('<div class="hoursRange"></div>');
			var start = $('<input class="hoursStart" aria-label="From">');
			var end = $('<input class="hoursEnd" aria-label="To">');
			row.append(start).append(' to ').append(end)
				.append(' <button type="button" class="k-button hoursRemove" aria-label="Remove these hours"><span class="k-icon k-i-close"></span></button>');
			start.kendoTimePicker({ format: "h:mm tt", parseFormats: ["HH:mm", "h:mm tt"], interval: 15, value: range.start || "09:00" });
			end.kendoTimePicker({ format: "h:mm tt", parseFormats: ["HH:mm", "h:mm tt"], interval: 15, value: range.end || "17:00" });
			return row;
		}

		function showHours(locationId) {
			currentLocation = String(locationId);
			var hours = hoursByLocation[currentLocation] || { own: false, days: [[], [], [], [], [], [], []] };
			var own = (hours.own === true || hours.OWN === true);
			var isGeneral = currentLocation === "0";
			<!--- A location without its own hours shows the general hours as they are now (they may have just been saved). --->
			var general = hoursByLocation["0"];
			var days = (isGeneral || own) ? (hours.days || hours.DAYS) : (general.days || general.DAYS);
			$(".hoursOwnRow").toggle(!isGeneral);
			$("#hoursOwn").prop("checked", own);
			var body = $("#hoursDays").empty();
			for (var d = 0; d < 7; d++) {
				var cell = $('<div class="hoursRanges"></div>').attr("data-day", d);
				$.each(days[d] || [], function(i, range) { cell.append(rangeHtml({ start: range.start || range.START, end: range.end || range.END })); });
				<!--- The blog's admin block look: a thin line above each day, the day on the left like the other labels. --->
				body.append($('<tr class="blockSpacer"></tr>').append($('<td colspan="2"></td>').addClass("border " + hoursDaysClass)));
				var tr = $('<tr></tr>').append($('<td align="right"></td>').addClass(hoursDaysClass).text(dayNames[d] + ":"))
					.append($('<td></td>').addClass(hoursDaysClass).append(cell).append('<button type="button" class="k-button hoursAdd">Add hours</button>'));
				body.append(tr);
			}
			refreshClosedText();
			refreshOwn();
		}

		<!--- A day with no hours reads "Closed". --->
		function refreshClosedText() {
			$("#hoursDays div.hoursRanges").each(function() {
				$(this).find(".hoursClosed").remove();
				if (!$(this).find(".hoursRange").length) { $(this).append('<span class="hoursClosed">Closed</span>'); }
			});
		}

		<!--- A location that follows the general hours shows them, but they're changed under General hours. --->
		function refreshOwn() {
			var editable = currentLocation === "0" || $("#hoursOwn").is(":checked");
			$("#hoursDays").css("opacity", editable ? 1 : 0.55);
			$("#hoursDays button").prop("disabled", !editable);
			$("#hoursDays input.hoursStart, #hoursDays input.hoursEnd").each(function() {
				var picker = $(this).data("kendoTimePicker");
				if (picker) { picker.enable(editable); }
			});
			$(".hoursFollowNoteRow").toggle(!editable && currentLocation !== "0");
		}

		$("#hoursDays").on("click", ".hoursAdd", function() {
			var cell = $(this).closest("tr").find("div.hoursRanges");
			var last = cell.find(".hoursRange").last();
			<!--- A second range starts after the first one ends, eg. 13:00-17:00 after a lunch break. --->
			var range = last.length ? { start: kendo.toString(last.find("input.hoursEnd").data("kendoTimePicker").value(), "HH:mm"), end: "18:00" } : { start: "09:00", end: "17:00" };
			cell.append(rangeHtml(range));
			refreshClosedText();
		});
		$("#hoursDays").on("click", ".hoursRemove", function() {
			$(this).closest(".hoursRange").remove();
			refreshClosedText();
		});
		$("#hoursOwn").on("change", function() {
			if ($(this).is(":checked") && !$("#hoursDays .hoursRange").length) {
				<!--- Start from the general hours. --->
				var general = hoursByLocation["0"];
				hoursByLocation[currentLocation] = { own: true, days: general.days || general.DAYS };
				showHours(currentLocation);
				$("#hoursOwn").prop("checked", true);
			}
			refreshOwn();
		});

		$("#hoursLocation").kendoDropDownList({
			dataSource: <cfoutput>#serializeJson(hoursChoices)#</cfoutput>,
			dataTextField: "text",
			dataValueField: "value",
			change: function() { showHours(this.value()); }
		});
		showHours("0");

		$("#hoursCopyWeekdays").on("click", function() {
			<!--- Monday's hours to Tuesday-Friday. --->
			var monday = $("#hoursDays div.hoursRanges[data-day=1] .hoursRange").map(function() {
				return { start: kendo.toString($(this).find("input.hoursStart").data("kendoTimePicker").value(), "HH:mm"), end: kendo.toString($(this).find("input.hoursEnd").data("kendoTimePicker").value(), "HH:mm") };
			}).get();
			for (var d = 2; d <= 5; d++) {
				var cell = $("#hoursDays div.hoursRanges[data-day=" + d + "]").empty();
				$.each(monday, function(i, range) { cell.append(rangeHtml(range)); });
			}
			refreshClosedText();
		});

		$("#hoursSubmit").on("click", function() {
			var own = currentLocation === "0" || $("#hoursOwn").is(":checked");
			var days = [];
			$("#hoursDays div.hoursRanges").each(function() {
				days.push($(this).find(".hoursRange").map(function() {
					var start = $(this).find("input.hoursStart").data("kendoTimePicker").value();
					var end = $(this).find("input.hoursEnd").data("kendoTimePicker").value();
					<!--- An end of midnight means the end of the day. --->
					var endText = end ? kendo.toString(end, "HH:mm") : "";
					return { start: start ? kendo.toString(start, "HH:mm") : "", end: endText === "00:00" ? "24:00" : endText };
				}).get());
			});
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving your hours.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBookingHours',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', locationOptionId: currentLocation, own: own, daysJson: JSON.stringify(days) },
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (JSON.parse(response.success) == true) {
						hoursByLocation[currentLocation] = { own: own, days: own ? days : (hoursByLocation["0"].days || hoursByLocation["0"].DAYS) };
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "Your hours were saved.", icon: "k-ext-information" }));
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR, textStatus, error) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) { createLoginWindow(); }
					else { $.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving your hours", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
				}
			});
		});

		<!--- Days off and different hours --->
		$("#exceptionDate").kendoDatePicker({ format: "yyyy-MM-dd", min: new Date() });
		$("#exceptionLocation").kendoDropDownList({ dataSource: <cfoutput>#serializeJson(hoursChoices)#</cfoutput>, dataTextField: "text", dataValueField: "value" });
		$("#exceptionLocation").data("kendoDropDownList").dataSource.at(0).set("text", "Every location");
		$("#exceptionStart").kendoTimePicker({ format: "h:mm tt", parseFormats: ["HH:mm"], interval: 15, value: "09:00" });
		$("#exceptionEnd").kendoTimePicker({ format: "h:mm tt", parseFormats: ["HH:mm"], interval: 15, value: "12:00" });
		function refreshExceptionKind() {
			var kind = $("input[name=exceptionKind]:checked").val();
			$(".exceptionHoursRow").toggle(kind == "hours" || kind == "busy");
			$("#exceptionHoursLabel").text(kind == "busy" ? "Busy:" : "Hours:");
		}
		$("input[name=exceptionKind]").on("change", refreshExceptionKind);
		refreshExceptionKind();

		function sendException(url, data) {
			jQuery.ajax({
				type: 'post', url: url, data: data, dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						$("#bookingHoursWindow").data("kendoWindow").refresh();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage || "That day could not be changed.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		}
		$("#exceptionAdd").on("click", function() {
			var kind = $("input[name=exceptionKind]:checked").val();
			var closed = kind == "closed";
			var start = $("#exceptionStart").data("kendoTimePicker").value();
			var end = $("#exceptionEnd").data("kendoTimePicker").value();
			sendException('<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveAvailabilityException', {
				csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
				exceptionJson: JSON.stringify({
					date: kendo.toString($("#exceptionDate").data("kendoDatePicker").value(), "yyyy-MM-dd") || "",
					locationOptionId: $("#exceptionLocation").data("kendoDropDownList").value(),
					closed: closed,
					kind: kind,
					start: start ? kendo.toString(start, "HH:mm") : "",
					end: end ? kendo.toString(end, "HH:mm") : "",
					note: $.trim($("#exceptionNote").val())
				})
			});
		});
		$("#hoursExceptions").on("click", ".exceptionRemove", function() {
			sendException('<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteAvailabilityException', {
				csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
				availabilityExceptionId: $(this).attr("data-id")
			});
		});
	});//...document.ready
</script>

<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">When you take bookings each week.<cfif len(hoursTimeZone)> Times are in your blog's time zone, #encodeForHtml(hoursTimeZone)#; clients see them in their own.<cfelse> Set your blog's time zone in Blog Settings first.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">General hours apply everywhere, unless a location has its own.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="hoursLocation">Hours for:</label></td>
		<td class="#blockClass#"><input id="hoursLocation" style="width: 95%; max-width: 450px;"></td>
	</tr>
	<tr class="blockSpacer hoursOwnRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr id="hoursFollowNote" class="hoursFollowNoteRow"><td colspan="2" class="#blockClass#">This location follows your general hours, shown below. Tick Own hours to give it its own, eg. the office only on Tuesdays and Thursdays.</td></tr>
	<tr class="blockSpacer hoursFollowNoteRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr id="hoursOwnRow" class="hoursOwnRow">
		<td class="#blockClass#" align="right"><label for="hoursOwn">Own hours:</label></td>
		<td class="#blockClass#">
			<input type="checkbox" class="k-checkbox" id="hoursOwn">
		</td>
	</tr>
	<!--- One row per day of the week, written by the JavaScript above (showHours). --->
	<tbody id="hoursDays"></tbody>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#">
			<button type="button" class="k-button" id="hoursCopyWeekdays">Copy Monday to Tuesday-Friday</button>
			<button type="button" class="k-button k-primary" id="hoursSubmit">Save hours</button>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Days off, different hours and busy times</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">Coming up:</td>
		<td class="#blockClass#" id="hoursExceptions">
			<cfif not arrayLen(hoursExceptions)>
				None.
			<cfelse>
				<table width="100%" cellpadding="3" cellspacing="0" border="0">
					<cfloop array="#hoursExceptions#" index="thisException">
						<tr>
							<td width="25%">#dateFormat(thisException.date, "ddd, mmm d, yyyy")#</td>
							<td width="25%">#encodeForHtml(structKeyExists(hoursLocationNames, thisException.locationOptionId) ? hoursLocationNames[thisException.locationOptionId] : "A deleted location")#</td>
							<td>#thisException.closed ? "Closed" : (thisException.kind eq "busy" ? "Busy " : "") & timeFormat(thisException.start, "h:mm tt") & " to " & timeFormat(thisException.end, "h:mm tt")##len(thisException.note) ? " - " & encodeForHtml(thisException.note) : ""#</td>
							<td width="12%" align="right"><button type="button" class="k-button exceptionRemove" data-id="#thisException.availabilityExceptionId#">Remove</button></td>
						</tr>
					</cfloop>
				</table>
			</cfif>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Add a day off, a day with different hours, or a time you're busy. Busy times can't be booked, but the rest of that day's hours still can; add as many as you need.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">The day, and where it applies.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="exceptionDate">Date:</label></td>
		<td class="#blockClass#"><input id="exceptionDate" style="width: 160px;"> <input id="exceptionLocation" style="width: 300px;" aria-label="Where"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right">That day:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="exceptionKind" value="closed" checked> Closed</label>
			<label style="margin-left: 1em;"><input type="radio" class="k-radio" name="exceptionKind" value="hours"> Different hours</label>
			<label style="margin-left: 1em;"><input type="radio" class="k-radio" name="exceptionKind" value="busy"> Busy for part of the day</label>
		</td>
	</tr>
	<tr class="blockSpacer exceptionHoursRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr id="exceptionHoursRow" class="exceptionHoursRow">
		<td class="#blockClass#" align="right" id="exceptionHoursLabel">Hours:</td>
		<td class="#blockClass#"><input id="exceptionStart" style="width: 145px;" aria-label="From"> to <input id="exceptionEnd" style="width: 145px;" aria-label="To"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Optional; only you see it.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="exceptionNote">Note:</label></td>
		<td class="#blockClass#"><input type="text" id="exceptionNote" class="k-textbox" maxlength="255" placeholder="eg. Holiday" style="width: 60%;"> <button type="button" class="k-button k-primary" id="exceptionAdd">Add</button></td>
	</tr>
</table>
</cfoutput>
