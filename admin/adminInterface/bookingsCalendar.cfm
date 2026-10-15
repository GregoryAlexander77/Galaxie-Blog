<!--- The bookings calendar (window 96, 2026-10-15), opened from the Bookings window (87). Times are the blog's own wall-clock
times (Blog Settings time zone), whatever the computer's time zone is. With Kendo UI Professional loaded it is a Kendo
Scheduler (day, week, month and agenda views); with Kendo Core, which has no Scheduler, it is this page's own month view
and "next 7 days" list. Clicking a booking opens it (window 95). Data: ProxyController.cfc getBookingsForCalendar. --->
<cfset calendarZone = application.blog.getBlogTimeZoneId()>
<cfset calendarToday = dateFormat(application.blog.blogNow(), "yyyy-mm-dd")>

<style>
	#bookingsCalendarMonth table { width: 100%; border-collapse: collapse; table-layout: fixed; }
	#bookingsCalendarMonth th, #bookingsCalendarMonth td { vertical-align: top; padding: 4px; }
	#bookingsCalendarMonth td { height: 80px; }
	#bookingsCalendarMonth .bookingsCalendarOther { opacity: 0.5; }
	#bookingsCalendarMonth a, #bookingsCalendarWeek a { display: block; cursor: pointer; }
</style>

<script>
	$(document).ready(function() {
		var calendarStatusText = { pending: "Waiting for approval", confirmed: "Confirmed", completed: "Completed", noShow: "No-show", held: "Waiting for payment" };

		<!--- "yyyy-mm-dd HH:mm" in the blog's time zone, as a JavaScript date with those same numbers (no time zone shifting). --->
		function wallClock(text) {
			var p = text.split(/[- :]/);
			return new Date(+p[0], +p[1] - 1, +p[2], +p[3] || 0, +p[4] || 0);
		}
		function ymd(date) { return kendo.toString(date, "yyyy-MM-dd"); }
		function openBooking(id) { createAdminInterfaceWindow(95, id); }

		function loadBookings(from, to, done) {
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getBookingsForCalendar',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', fromDate: ymd(from), toDate: ymd(to) },
				dataType: "json",
				success: function(response) { done((response && response.bookings) || []); },
				error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } done([]); }
			});
		}

		<cfoutput>var calendarToday = wallClock("#calendarToday# 00:00");</cfoutput>

		if (kendo.ui.Scheduler) {
			<!--- Kendo UI Professional: the Scheduler, read only. --->
			$("#bookingsCalendarFallback").hide();
			var scheduler = $("#bookingsCalendarScheduler").kendoScheduler({
				date: calendarToday,
				height: 600,
				editable: false,
				views: ["day", { type: "week", selected: true }, "month", "agenda"],
				dataSource: {
					transport: {
						read: function(options) {
							var view = $("#bookingsCalendarScheduler").data("kendoScheduler") ? $("#bookingsCalendarScheduler").data("kendoScheduler").view() : null;
							var from = view ? view.startDate() : new Date(calendarToday.getFullYear(), calendarToday.getMonth() - 1, 1);
							var to = view ? view.endDate() : new Date(calendarToday.getFullYear(), calendarToday.getMonth() + 2, 0);
							loadBookings(from, to, function(bookings) {
								options.success($.map(bookings, function(b) {
									return { id: b.bookingId, title: b.time + " " + b.name + " - " + b.typeName + (b.status === "confirmed" ? "" : " (" + (calendarStatusText[b.status] || b.status) + ")"), start: wallClock(b.startLocal), end: wallClock(b.endLocal) };
								}));
							});
						}
					},
					schema: { model: { id: "id", fields: { id: { type: "number" }, title: { type: "string" }, start: { type: "date" }, end: { type: "date" } } } }
				},
				navigate: function() { var self = this; setTimeout(function() { self.dataSource.read(); }, 0); },
				change: function(e) { if (e.events && e.events.length) { openBooking(e.events[0].id); } },
				selectable: true
			}).data("kendoScheduler");
			return;
		}

		<!--- Kendo Core: this page's own month view and the next 7 days. --->
		$("#bookingsCalendarScheduler").hide();
		var shown = new Date(calendarToday.getFullYear(), calendarToday.getMonth(), 1);

		function drawMonth() {
			var first = new Date(shown.getFullYear(), shown.getMonth(), 1);
			var gridStart = new Date(first); gridStart.setDate(first.getDate() - first.getDay());
			var gridEnd = new Date(gridStart); gridEnd.setDate(gridStart.getDate() + 41);
			$("#bookingsCalendarTitle").text(kendo.toString(first, "MMMM yyyy"));
			loadBookings(gridStart, gridEnd, function(bookings) {
				var byDay = {};
				$.each(bookings, function(i, b) { var key = b.startLocal.substring(0, 10); (byDay[key] = byDay[key] || []).push(b); });
				var table = $('<table class="k-content"><thead><tr></tr></thead><tbody></tbody></table>');
				$.each(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], function(i, name) { table.find("thead tr").append($('<th class="k-header"></th>').text(name)); });
				var day = new Date(gridStart);
				for (var week = 0; week < 6; week++) {
					var row = $("<tr></tr>").appendTo(table.find("tbody"));
					for (var d = 0; d < 7; d++) {
						var key = ymd(day);
						var cell = $('<td class="tableBorder"></td>').appendTo(row);
						if (day.getMonth() !== first.getMonth()) { cell.addClass("bookingsCalendarOther"); }
						cell.append($("<div></div>").html(key === ymd(calendarToday) ? "<b>" + day.getDate() + "</b>" : day.getDate()));
						$.each(byDay[key] || [], function(i, b) {
							$("<a></a>").text(b.time + " " + b.name + (b.status === "confirmed" ? "" : " (" + (calendarStatusText[b.status] || b.status) + ")"))
								.attr("title", b.typeName + " - " + b.locationLabel).on("click", function() { openBooking(b.bookingId); }).appendTo(cell);
						});
						day.setDate(day.getDate() + 1);
					}
				}
				$("#bookingsCalendarMonth").empty().append(table);
			});
		}

		function drawWeek() {
			var end = new Date(calendarToday); end.setDate(end.getDate() + 6);
			loadBookings(calendarToday, end, function(bookings) {
				var box = $("#bookingsCalendarWeek").empty();
				if (!bookings.length) { box.text("No bookings in the next 7 days."); return; }
				$.each(bookings, function(i, b) {
					$("<a></a>").text(kendo.toString(wallClock(b.startLocal), "ddd, MMM d") + ", " + b.time + " - " + b.name + " - " + b.typeName + (b.status === "confirmed" ? "" : " (" + (calendarStatusText[b.status] || b.status) + ")"))
						.on("click", function() { openBooking(b.bookingId); }).appendTo(box);
				});
			});
		}

		$("#bookingsCalendarPrev").on("click", function() { shown.setMonth(shown.getMonth() - 1); drawMonth(); });
		$("#bookingsCalendarNext").on("click", function() { shown.setMonth(shown.getMonth() + 1); drawMonth(); });
		$("#bookingsCalendarToday").on("click", function() { shown = new Date(calendarToday.getFullYear(), calendarToday.getMonth(), 1); drawMonth(); });
		drawMonth();
		drawWeek();
	});
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<p>Times are in your blog's time zone<cfif len(calendarZone)> (#encodeForHtml(calendarZone)#)</cfif>. Click a booking to open it.</p>
<div id="bookingsCalendarScheduler"></div>
<div id="bookingsCalendarFallback">
	<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0">
		<tr>
			<td class="#blockClass#">
				<button type="button" class="k-button" id="bookingsCalendarPrev" aria-label="Previous month">&lt;</button>
				<button type="button" class="k-button" id="bookingsCalendarToday">Today</button>
				<button type="button" class="k-button" id="bookingsCalendarNext" aria-label="Next month">&gt;</button>
				<h4 class="adminBlockHeading" id="bookingsCalendarTitle" style="display: inline-block; margin-left: 10px;"></h4>
			</td>
		</tr>
		<tr class="blockSpacer"><td class="border #blockClass#"></td></tr>
		<tr><td class="#blockClass#" id="bookingsCalendarMonth"></td></tr>
		<tr class="blockSpacer"><td class="#blockClass#"></td></tr>
		<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
		<tr class="blockSpacer"><td class="border #blockClass#"></td></tr>
		<tr><td class="#blockClass#"><h4 class="adminBlockHeading">The next 7 days</h4></td></tr>
		<tr class="blockSpacer"><td class="border #blockClass#"></td></tr>
		<tr><td class="#blockClass#" id="bookingsCalendarWeek"></td></tr>
	</table>
</div>
</cfoutput>
