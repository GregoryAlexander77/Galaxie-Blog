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
	#hoursDays td { vertical-align: top; padding-top: 6px; }
	.hoursRange { margin-bottom: 4px; white-space: nowrap; }
	.hoursRange .k-timepicker { width: 120px; }
</style>

<script>
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
			$("#hoursOwnRow").toggle(!isGeneral);
			$("#hoursOwn").prop("checked", own);
			var body = $("#hoursDays").empty();
			for (var d = 0; d < 7; d++) {
				var cell = $('<td class="hoursRanges"></td>').attr("data-day", d);
				$.each(days[d] || [], function(i, range) { cell.append(rangeHtml({ start: range.start || range.START, end: range.end || range.END })); });
				var tr = $('<tr></tr>').append($('<td width="20%"></td>').text(dayNames[d])).append(cell)
					.append($('<td width="20%"></td>').append('<button type="button" class="k-button hoursAdd">Add hours</button>'));
				body.append(tr);
			}
			refreshClosedText();
			refreshOwn();
		}

		<!--- A day with no hours reads "Closed". --->
		function refreshClosedText() {
			$("#hoursDays td.hoursRanges").each(function() {
				$(this).find(".hoursClosed").remove();
				if (!$(this).find(".hoursRange").length) { $(this).append('<span class="hoursClosed">Closed</span>'); }
			});
		}

		<!--- A location that follows the general hours shows them, but they're changed under General hours. --->
		function refreshOwn() {
			var editable = currentLocation === "0" || $("#hoursOwn").is(":checked");
			$("#hoursDaysTable").css("opacity", editable ? 1 : 0.55);
			$("#hoursDays button").prop("disabled", !editable);
			$("#hoursDays input.hoursStart, #hoursDays input.hoursEnd").each(function() {
				var picker = $(this).data("kendoTimePicker");
				if (picker) { picker.enable(editable); }
			});
			$("#hoursFollowNote").toggle(!editable);
		}

		$("#hoursDays").on("click", ".hoursAdd", function() {
			var cell = $(this).closest("tr").find("td.hoursRanges");
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
			var monday = $("#hoursDays td.hoursRanges[data-day=1] .hoursRange").map(function() {
				return { start: kendo.toString($(this).find("input.hoursStart").data("kendoTimePicker").value(), "HH:mm"), end: kendo.toString($(this).find("input.hoursEnd").data("kendoTimePicker").value(), "HH:mm") };
			}).get();
			for (var d = 2; d <= 5; d++) {
				var cell = $("#hoursDays td.hoursRanges[data-day=" + d + "]").empty();
				$.each(monday, function(i, range) { cell.append(rangeHtml(range)); });
			}
			refreshClosedText();
		});

		$("#hoursSubmit").on("click", function() {
			var own = currentLocation === "0" || $("#hoursOwn").is(":checked");
			var days = [];
			$("#hoursDays td.hoursRanges").each(function() {
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
		function refreshExceptionKind() { $("#exceptionHoursRow").toggle($("input[name=exceptionKind]:checked").val() == "hours"); }
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
			var closed = $("input[name=exceptionKind]:checked").val() == "closed";
			var start = $("#exceptionStart").data("kendoTimePicker").value();
			var end = $("#exceptionEnd").data("kendoTimePicker").value();
			sendException('<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveAvailabilityException', {
				csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
				exceptionJson: JSON.stringify({
					date: kendo.toString($("#exceptionDate").data("kendoDatePicker").value(), "yyyy-MM-dd") || "",
					locationOptionId: $("#exceptionLocation").data("kendoDropDownList").value(),
					closed: closed,
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
<p>When you take bookings each week.<cfif len(hoursTimeZone)> Times are in your blog's time zone, <b>#encodeForHtml(hoursTimeZone)#</b>; clients see them in their own.<cfelse> <b>Set your blog's time zone in Blog Settings first.</b></cfif></p>
<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr>
		<td width="20%"><label for="hoursLocation">Hours for:</label></td>
		<td><input id="hoursLocation" style="width: 320px;"></td>
	</tr>
	<tr id="hoursOwnRow">
		<td colspan="2">
			<label><input type="checkbox" class="k-checkbox" id="hoursOwn"> Use different hours for this location</label>
			<div class="k-form-hint" id="hoursFollowNote">This location follows your general hours, shown below. Tick the box to give it its own, eg. the office only on Tuesdays and Thursdays.</div>
		</td>
	</tr>
	<tr>
		<td colspan="2">
			<table id="hoursDaysTable" width="100%" cellpadding="3" cellspacing="0" border="0"><tbody id="hoursDays"></tbody></table>
		</td>
	</tr>
	<tr>
		<td colspan="2">
			<button type="button" class="k-button" id="hoursCopyWeekdays">Copy Monday to Tuesday-Friday</button>
			<button type="button" class="k-button k-primary" id="hoursSubmit" style="float: right;">Save hours</button>
		</td>
	</tr>
</table>

<p>&nbsp;</p>
<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr><td class="k-header" colspan="2"><b>Days off and different hours</b></td></tr>
	<tr>
		<td colspan="2" id="hoursExceptions">
			<cfif not arrayLen(hoursExceptions)>
				None coming up.
			<cfelse>
				<table width="100%" cellpadding="3" cellspacing="0" border="0">
					<cfloop array="#hoursExceptions#" index="thisException">
						<tr>
							<td width="22%">#dateFormat(thisException.date, "ddd, mmm d, yyyy")#</td>
							<td width="22%">#encodeForHtml(structKeyExists(hoursLocationNames, thisException.locationOptionId) ? hoursLocationNames[thisException.locationOptionId] : "A deleted location")#</td>
							<td>#thisException.closed ? "Closed" : timeFormat(thisException.start, "h:mm tt") & " to " & timeFormat(thisException.end, "h:mm tt")##len(thisException.note) ? " - " & encodeForHtml(thisException.note) : ""#</td>
							<td width="10%" align="right"><button type="button" class="k-button exceptionRemove" data-id="#thisException.availabilityExceptionId#">Remove</button></td>
						</tr>
					</cfloop>
				</table>
			</cfif>
		</td>
	</tr>
	<tr>
		<td width="20%"><label for="exceptionDate">Date:</label></td>
		<td><input id="exceptionDate" style="width: 160px;"> <input id="exceptionLocation" style="width: 250px;" aria-label="Where"></td>
	</tr>
	<tr>
		<td>That day:</td>
		<td>
			<label><input type="radio" class="k-radio" name="exceptionKind" value="closed" checked> Closed</label>
			<label style="margin-left: 1em;"><input type="radio" class="k-radio" name="exceptionKind" value="hours"> Different hours</label>
		</td>
	</tr>
	<tr id="exceptionHoursRow">
		<td>Hours:</td>
		<td><input id="exceptionStart" style="width: 120px;" aria-label="From"> to <input id="exceptionEnd" style="width: 120px;" aria-label="To"></td>
	</tr>
	<tr>
		<td><label for="exceptionNote">Note:</label></td>
		<td><input type="text" id="exceptionNote" class="k-textbox" maxlength="255" placeholder="Optional, only you see it, eg. Holiday" style="width: 60%;"> <button type="button" class="k-button k-primary" id="exceptionAdd">Add</button></td>
	</tr>
</table>
</cfoutput>
