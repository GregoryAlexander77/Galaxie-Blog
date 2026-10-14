/*
	Galaxie Blog bookings on the site (2026-10-14).

	A booking widget is placed in a post or page as <div class="galaxieBooking" data-booking="type-alias">[Booking: Name]</div>, or
	data-booking="*" for every booking type (the post editor's Insert > Booking). This script is downloaded only on pages that have
	one - see galaxieLoader.bookings in includes/templates/head.cfm and the check in includes/templates/tailEndScripts.cfm - and walks
	the visitor through: the booking type (grouped by category), the way to meet when there's a choice, a day on a calendar, a free
	time shown in the visitor's own time zone, then their details and the type's questions. The server (ProxyController.cfc's
	getBookingWidget, getBookingSlots, getBookingQuestions and submitBooking; common/cfc/Bookings.cfc) works out the free times and
	checks everything again when booking; nothing here is relied on for safety.

	Times: the server lists each free time as the blog's wall-clock time ("local", which it books by) and as a UTC instant ("utc").
	The visitor sees the UTC instant in their chosen time zone, so a day on the calendar is the visitor's day.
*/
var galaxieBookings = (function($) {

	var proxyUrl = "";

	// Layout only. Colors and fonts come from the Kendo theme's classes.
	function addStyles() {
		if ($("#galaxieBookingStyles").length) { return; }
		$("head").append($('<style id="galaxieBookingStyles"></style>').text(
			".galaxieBooking { margin: 1.5em 0; }" +
			".galaxieBookingCategory { margin: 1em 0 0.5em 0; }" +
			".galaxieBookingType { padding: 0.75em 0; border-top: 1px solid rgba(128,128,128,0.25); }" +
			".galaxieBookingType h4 { margin: 0 0 0.25em 0; }" +
			".galaxieBookingMeta { margin-bottom: 0.4em; }" +
			".galaxieBookingStep { margin: 1em 0; }" +
			".galaxieBookingBack { background: none; border: 0; padding: 0; font: inherit; color: inherit; text-decoration: underline; cursor: pointer; }" +
			".galaxieBookingCalendarRow { display: flex; flex-wrap: wrap; gap: 1.5em; align-items: flex-start; }" +
			".galaxieBookingCalendarRow .k-calendar { width: auto; display: inline-block; max-width: 100%; }" +
			".galaxieBookingTimes { flex: 1 1 14em; min-width: 12em; }" +
			".galaxieBookingTimes .k-button { margin: 0 0.4em 0.4em 0; min-width: 6.5em; }" +
			".galaxieBookingField { margin: 0 0 1em 0; }" +
			".galaxieBookingField > label { display: block; margin-bottom: 0.3em; }" +
			".galaxieBookingField .k-textbox, .galaxieBookingField textarea, .galaxieBookingField .k-dropdown, .galaxieBookingField .k-datepicker { width: 100%; max-width: 40em; box-sizing: border-box; }" +
			".galaxieBookingError { display: block; position: static; margin-top: 0.3em; }" +
			".galaxieBookingError[hidden] { display: none; }" +
			".galaxieBookingHp { position: absolute; left: -10000px; top: auto; width: 1px; height: 1px; overflow: hidden; }" +
			".galaxieBookingCaptchaImage img { display: block; margin-bottom: 0.5em; max-width: 100%; }" +
			".galaxieWebFormField { margin: 0 0 1em 0; }" +
			".galaxieWebFormField > label { display: block; margin-bottom: 0.3em; }" +
			".galaxieWebFormGroup { border: 0; margin: 0; padding: 0; }" +
			".galaxieWebFormChoice { margin: 0.25em 0; }" +
			".galaxieWebFormField .k-textbox, .galaxieWebFormField textarea { width: 100%; max-width: 40em; box-sizing: border-box; }" +
			".galaxieWebFormError { display: block; position: static; margin-top: 0.3em; }" +
			".galaxieWebFormError[hidden] { display: none; }"
		));
	}

	function escapeHtml(value) {
		return $("<div/>").text(value === null || value === undefined ? "" : String(value)).html();
	}

	// The visitor's own time zone, and the list to choose from (modern browsers list every zone).
	function browserTimeZone() {
		try { return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC"; } catch (e) { return "UTC"; }
	}
	function timeZoneList(blogZone) {
		var zones = [];
		try { if (Intl.supportedValuesOf) { zones = Intl.supportedValuesOf("timeZone"); } } catch (e) { zones = []; }
		$.each([browserTimeZone(), blogZone, "UTC"], function(i, zone) { if (zone && zones.indexOf(zone) < 0) { zones.unshift(zone); } });
		return zones;
	}
	// yyyy-mm-dd of an instant in a time zone.
	function dayKey(date, zone) {
		var parts = {};
		$.each(new Intl.DateTimeFormat("en-US", { timeZone: zone, year: "numeric", month: "2-digit", day: "2-digit" }).formatToParts(date), function(i, p) { parts[p.type] = p.value; });
		return parts.year + "-" + parts.month + "-" + parts.day;
	}
	function formatTime(utc, zone) {
		return new Date(utc).toLocaleTimeString([], { timeZone: zone, hour: "numeric", minute: "2-digit" });
	}
	function formatWhen(utc, zone) {
		return new Date(utc).toLocaleString([], { timeZone: zone, weekday: "long", month: "long", day: "numeric", year: "numeric", hour: "numeric", minute: "2-digit" });
	}
	function pad(n) { return (n < 10 ? "0" : "") + n; }
	function dateText(date) { return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate()); }
	function formatPrice(type) {
		if (!type.price || Number(type.price) <= 0) { return "Free"; }
		return Number(type.price).toFixed(2) + (type.isGroup && type.pricingUnit === "perPerson" ? " per person" : "");
	}
	function formatLength(minutes) {
		minutes = Number(minutes);
		if (minutes < 60) { return minutes + " minutes"; }
		var hours = Math.floor(minutes / 60), rest = minutes % 60;
		return hours + (hours === 1 ? " hour" : " hours") + (rest ? " " + rest + " minutes" : "");
	}

	function init(options) {
		proxyUrl = ((options && options.baseUrl) || "") + "/common/cfc/ProxyController.cfc";
		addStyles();
		$(".galaxieBooking[data-booking]").each(function() {
			var box = $(this);
			if (box.data("galaxieBookingLoaded")) { return; }
			box.data("galaxieBookingLoaded", true);
			load(box);
		});
	}

	function load(box) {
		$.ajax({ type: "post", url: proxyUrl + "?method=getBookingWidget", data: { alias: box.attr("data-booking") }, dataType: "json", cache: false })
			.done(function(response) {
				if (!response || response.success !== true || !response.types.length) {
					box.empty().attr("hidden", "hidden");
					return;
				}
				var state = {
					box: box,
					types: response.types,
					token: response.token,
					captcha: response.captcha === true,
					blogZone: response.timeZone,
					zone: browserTimeZone(),
					type: null,
					location: null,
					slots: {},
					fetched: {},
					slot: null
				};
				box.removeAttr("hidden");
				if (state.types.length === 1) { chooseType(state, state.types[0]); } else { showTypes(state); }
			})
			.fail(function() { box.empty().attr("hidden", "hidden"); });
	}

	// Step 1: the booking types, under their categories.
	function showTypes(state) {
		var box = state.box.empty();
		var lastCategory = null;
		$.each(state.types, function(i, type) {
			if (type.category !== lastCategory) {
				lastCategory = type.category;
				if (type.category) { box.append($('<h3 class="galaxieBookingCategory"></h3>').text(type.category)); }
			}
			var card = $('<div class="galaxieBookingType"></div>');
			card.append($("<h4></h4>").text(type.name));
			card.append($('<div class="galaxieBookingMeta"></div>').text(formatLength(type.durationMinutes) + " · " + formatPrice(type)));
			if (type.description) { card.append($("<p></p>").html(escapeHtml(type.description).replace(/\n/g, "<br/>"))); }
			card.append($('<button type="button" class="k-button k-primary">Book</button>').on("click", function() { chooseType(state, type); }));
			box.append(card);
		});
	}

	// Step 2: where to meet, when the type offers more than one way.
	function chooseType(state, type) {
		state.type = type;
		state.location = null;
		state.slots = {};
		state.fetched = {};
		state.slot = null;
		var box = state.box.empty();
		if (state.types.length > 1) {
			box.append($('<button type="button" class="galaxieBookingBack"></button>').text("← All bookings").on("click", function() { showTypes(state); }));
		}
		box.append($("<h3></h3>").text(type.name));
		box.append($('<div class="galaxieBookingMeta"></div>').text(formatLength(type.durationMinutes) + " · " + formatPrice(type)));
		if (type.locations.length === 1) {
			state.location = type.locations[0];
			box.append($('<p class="galaxieBookingWhere"></p>').text(state.location.label));
			showCalendar(state);
			return;
		}
		var step = $('<fieldset class="galaxieBookingStep galaxieWebFormGroup"><legend>How would you like to meet?</legend></fieldset>');
		$.each(type.locations, function(i, location) {
			var id = "galaxieBookingLocation_" + type.alias + "_" + location.locationOptionId;
			var radio = $('<input type="radio" class="k-radio" name="galaxieBookingLocation">').attr("id", id).val(location.locationOptionId);
			radio.on("change", function() {
				state.location = location;
				state.slots = {};
				state.fetched = {};
				state.slot = null;
				showCalendar(state);
			});
			step.append($('<div class="galaxieWebFormChoice"></div>').append(radio).append(" ").append($("<label></label>").attr("for", id).text(location.label)));
		});
		box.append(step);
		box.append('<div class="galaxieBookingWhen"></div>');
	}

	// Step 3: a calendar of the days with free times, and the times of the chosen day.
	function showCalendar(state) {
		var when = state.box.find(".galaxieBookingWhen");
		if (!when.length) { when = $('<div class="galaxieBookingWhen"></div>').appendTo(state.box); }
		when.empty();
		var zoneRow = $('<div class="galaxieBookingStep"></div>').append('<label>Times are shown in: </label>');
		var zoneInput = $("<input>").appendTo(zoneRow);
		when.append(zoneRow);
		var row = $('<div class="galaxieBookingCalendarRow galaxieBookingStep"></div>').appendTo(when);
		var calendarDiv = $("<div></div>").appendTo(row);
		var times = $('<div class="galaxieBookingTimes" aria-live="polite"></div>').appendTo(row);
		times.text("Choose a day.");
		when.append('<div class="galaxieBookingDetails"></div>');

		zoneInput.kendoDropDownList({
			dataSource: timeZoneList(state.blogZone),
			value: state.zone,
			filter: "contains",
			change: function() {
				state.zone = this.value();
				state.slot = null;
				when.find(".galaxieBookingDetails").empty();
				refreshCalendar();
				times.text("Choose a day.");
			}
		});

		var refreshing = false;
		var calendar = calendarDiv.kendoCalendar({
			min: new Date(),
			// No "today" link: today usually can't be booked (the minimum notice).
			footer: false,
			disableDates: function(date) { return !hasDay(date); },
			change: function() { showTimes(this.value()); },
			navigate: function() { if (!refreshing) { fetchMonth(this.current()); } }
		}).data("kendoCalendar");

		// The visitor's calendar days, from the free times in their time zone.
		function hasDay(date) {
			return !!byDay()[dateText(date)];
		}
		function byDay() {
			var days = {};
			$.each(state.slots, function(local, slot) {
				var key = dayKey(new Date(slot.utc), state.zone);
				(days[key] = days[key] || []).push(slot);
			});
			return days;
		}
		function refreshCalendar() {
			refreshing = true;
			calendar.navigate(calendar.current(), "month");
			refreshing = false;
		}
		// The free times for the month shown, with a day either side so time zones far from the blog's are covered.
		function fetchMonth(current) {
			var first = new Date(current.getFullYear(), current.getMonth(), 1);
			var last = new Date(current.getFullYear(), current.getMonth() + 1, 0);
			first.setDate(first.getDate() - 1);
			last.setDate(last.getDate() + 1);
			var key = dateText(first);
			if (state.fetched[key]) { return; }
			state.fetched[key] = true;
			$.ajax({
				type: "post", url: proxyUrl + "?method=getBookingSlots", dataType: "json", cache: false,
				data: { alias: state.type.alias, locationOptionId: state.location.locationOptionId, fromDate: dateText(first), toDate: dateText(last) }
			}).done(function(response) {
				if (response && response.success) {
					$.each(response.slots, function(i, slot) { state.slots[slot.local] = slot; });
					refreshCalendar();
					if (!response.slots.length && $.isEmptyObject(state.slots)) { times.text("No free times this month. Try the next month."); }
				}
			});
		}
		function showTimes(date) {
			state.slot = null;
			when.find(".galaxieBookingDetails").empty();
			times.empty();
			var list = (byDay()[dateText(date)] || []).sort(function(a, b) { return a.utc < b.utc ? -1 : 1; });
			if (!list.length) { times.text("No free times on this day."); return; }
			times.append($("<p></p>").text(date.toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" })));
			$.each(list, function(i, slot) {
				var label = formatTime(slot.utc, state.zone) + (state.type.isGroup ? " (" + slot.spotsLeft + (slot.spotsLeft === 1 ? " place" : " places") + " left)" : "");
				times.append($('<button type="button" class="k-button"></button>').text(label).on("click", function() {
					times.find(".k-button").removeClass("k-primary").attr("aria-pressed", "false");
					$(this).addClass("k-primary").attr("aria-pressed", "true");
					state.slot = slot;
					showDetails(state);
				}));
			});
		}
		fetchMonth(new Date());
	}

	// Step 4: the visitor's details and the type's questions.
	function showDetails(state) {
		var box = state.box.find(".galaxieBookingDetails").empty();
		var form = $('<form class="galaxieBookingForm galaxieBookingStep" novalidate="novalidate"></form>').appendTo(box);
		var prefix = "galaxieBooking_" + state.type.alias + "_";
		form.append($('<p class="galaxieBookingSummary"></p>').html("<b>" + escapeHtml(formatWhen(state.slot.utc, state.zone)) + "</b><br/>" + escapeHtml(state.type.name) + " · " + escapeHtml(state.location.label)));
		function field(name, label, input, required) {
			var div = $('<div class="galaxieBookingField"></div>').attr("data-field", name);
			input.attr("id", prefix + name).attr("name", name);
			if (required) { input.attr("required", "required").attr("aria-required", "true"); }
			div.append($("<label></label>").attr("for", prefix + name).text(label + (required ? " *" : ""))).append(input);
			div.append('<div class="galaxieBookingError k-widget k-tooltip k-tooltip-validation k-invalid-msg" role="alert" hidden="hidden"></div>');
			return div;
		}
		form.append(field("name", "Your name", $('<input type="text" class="k-textbox" maxlength="255" autocomplete="name">'), true));
		form.append(field("email", "Email address", $('<input type="email" class="k-textbox" maxlength="255" autocomplete="email">'), true));
		if (state.location.needsPhone) {
			form.append(field("phone", "Phone number to call you on", $('<input type="tel" class="k-textbox" maxlength="50" autocomplete="tel">'), true));
		}
		if (state.type.isGroup) {
			var most = Math.min(state.slot.spotsLeft, state.type.groupSize);
			var select = $("<select></select>");
			for (var n = 1; n <= most; n++) { select.append($("<option></option>").val(n).text(n)); }
			form.append(field("partySize", "How many people", select, true));
			select.kendoDropDownList();
		}
		var questions = $('<div class="galaxieBookingQuestions"></div>').appendTo(form);
		if (state.type.hasQuestions) {
			$.ajax({ type: "post", url: proxyUrl + "?method=getBookingQuestions", data: { alias: state.type.alias }, dataType: "json", cache: false })
				.done(function(response) {
					if (response && response.html) {
						questions.html(response.html);
						questions.find("select").each(function() { $(this).kendoDropDownList({ optionLabel: false }); });
						questions.find("input.galaxieWebFormDate").each(function() { $(this).kendoDatePicker({ format: "yyyy-MM-dd" }); });
					}
				});
		}
		// Spam protection: a field people never see, and the captcha when the blog uses it.
		form.append('<div class="galaxieBookingHp" aria-hidden="true"><label>Leave this empty <input type="text" name="website" tabindex="-1" autocomplete="off"></label></div>');
		if (state.captcha) {
			var captcha = field("captchaText", "Enter the text in the image", $('<input type="text" class="k-textbox" autocomplete="off">'), true);
			captcha.find("label").after('<div class="galaxieBookingCaptchaImage"></div>');
			form.append(captcha);
			loadCaptcha(form);
		}
		form.append($('<button type="submit" class="k-button k-primary"></button>').text(state.type.price > 0 ? "Book" : "Book now"));
		form.append('<div class="galaxieBookingStatus" role="status" aria-live="polite"></div>');
		form.on("submit", function(e) { e.preventDefault(); send(state, form); });
		form.find("input[name=name]").focus();
	}

	function loadCaptcha(form) {
		$.ajax({ type: "post", url: proxyUrl + "?method=getCaptchaAsJson", dataType: "json", cache: false }).done(function(response) {
			var row = $.isArray(response) ? response[0] : response;
			var url = row && (row.captchaImageUrl || row.CAPTCHAIMAGEURL);
			if (url) {
				form.find(".galaxieBookingCaptchaImage").empty().append($('<img alt="Captcha: the text to type">').attr("src", url + "&reload=" + new Date().getTime()));
			}
		});
	}

	// The intake answers, as Forms collects them (see common/js/webForms.js).
	function collectAnswers(form) {
		var values = {};
		form.find(".galaxieBookingQuestions .galaxieWebFormField[data-field]").each(function() {
			var fieldDiv = $(this), name = fieldDiv.attr("data-field"), type = fieldDiv.attr("data-type");
			if (type === "checkboxes") {
				values[name] = fieldDiv.find("input:checked").map(function() { return this.value; }).get().join(",");
			} else if (type === "radio") {
				values[name] = fieldDiv.find("input:checked").val() || "";
			} else if (type === "consent") {
				values[name] = fieldDiv.find("input").is(":checked") ? "yes" : "";
			} else {
				values[name] = $.trim(fieldDiv.find("input, textarea, select").filter("[name='" + name + "']").val() || "");
			}
		});
		return values;
	}

	function send(state, form) {
		form.find(".galaxieBookingError, .galaxieWebFormError").attr("hidden", "hidden").text("");
		form.find(".galaxieBookingStatus").text("");
		// A quick check of the visitor's own details first (the server checks everything again).
		var missing = null;
		form.find(".galaxieBookingField[data-field]").each(function() {
			var input = $(this).find("input[required], select[required]").first();
			if (input.length && !$.trim(input.val() || "").length) {
				$(this).find(".galaxieBookingError").text("This field is required.").removeAttr("hidden");
				if (!missing) { missing = input; }
			}
		});
		if (missing) {
			form.find(".galaxieBookingStatus").text("Please check the highlighted details.");
			missing.focus();
			return;
		}
		var button = form.find("button[type=submit]").prop("disabled", true);
		$.ajax({
			type: "post", url: proxyUrl + "?method=submitBooking", dataType: "json", cache: false,
			data: {
				alias: state.type.alias,
				locationOptionId: state.location.locationOptionId,
				startLocal: state.slot.local,
				partySize: form.find("select[name=partySize]").val() || 1,
				name: $.trim(form.find("input[name=name]").val()),
				email: $.trim(form.find("input[name=email]").val()),
				phone: $.trim(form.find("input[name=phone]").val() || ""),
				visitorTimeZone: state.zone,
				valuesJson: JSON.stringify(collectAnswers(form)),
				token: state.token,
				captchaText: $.trim(form.find("input[name=captchaText]").val() || ""),
				website: form.find("input[name=website]").val(),
				postId: state.box.closest("[data-postid]").attr("data-postid") || 0
			}
		}).done(function(response) {
			if (response && response.success === true) {
				showConfirmation(state, response);
				return;
			}
			button.prop("disabled", false);
			var first = null;
			$.each((response && response.errors) || {}, function(name, text) {
				var target = form.find("[data-field='" + name + "']").first();
				target.find(".galaxieBookingError, .galaxieWebFormError").first().text(text).removeAttr("hidden");
				if (!first) { first = target; }
			});
			form.find(".galaxieBookingStatus").text((response && response.message) || "Please check the highlighted details.");
			if (first) { first.find("input, textarea, select").first().focus(); }
			if (response && response.errors && response.errors.captchaText) {
				form.find("input[name=captchaText]").val("");
				loadCaptcha(form);
			}
			// The time was just taken: show the free times again.
			if (response && response.message && response.message.indexOf("just taken") >= 0) {
				state.fetched = {};
				state.slots = {};
				showCalendar(state);
			}
		}).fail(function() {
			button.prop("disabled", false);
			form.find(".galaxieBookingStatus").text("The booking could not be sent. Please try again in a moment.");
		});
	}

	// Step 5: the confirmation, with the details for the chosen way to meet.
	function showConfirmation(state, response) {
		var box = state.box.empty();
		var done = $('<div class="galaxieBookingConfirmation" role="status" tabindex="-1"></div>').appendTo(box);
		done.append($("<h3></h3>").text(response.status === "pending" ? "Thank you - your request is in" : "You're booked"));
		done.append($("<p></p>").html("<b>" + escapeHtml(state.type.name) + "</b><br/>" + escapeHtml(formatWhen(response.startUtc || state.slot.utc, state.zone)) + " (" + escapeHtml(state.zone.replace(/_/g, " ")) + ")"));
		if (response.status === "pending") {
			done.append($("<p></p>").text("This time is held for you. You'll hear back once it's confirmed."));
		}
		done.append($("<p></p>").text(response.locationLabel));
		done.append(response.detailsHtml || "");
		done.focus();
	}

	return { init: init };

})(jQuery);
