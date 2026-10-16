/*
	Galaxie Blog member accounts on the site (2026-10-15).

	Visitors sign in with a one-time link emailed to them - there are no passwords. This script is downloaded only when the
	blog's owner has turned member accounts on (Blog Options > Member Accounts): see galaxieLoader.members in
	includes/templates/head.cfm and the call in includes/templates/tailEndScripts.cfm. Pages are cached, so nothing about the
	visitor is in the page itself: on each page this asks the server who is signed in (ProxyController.cfc's memberStatus) and
	adds "Sign in" or the member's name to the menu.

	The emailed link brings the visitor back to the page they were on with ?memberSignIn=<token>. The token is only used when
	they click Sign in on that page (a POST), so a mail scanner that opens links can't use it up. The server checks
	everything (common/cfc/Members.cfc); nothing here is relied on for safety.
*/
var galaxieMembers = (function($) {

	var proxyUrl = "";
	var baseUrl = "";
	var blogTitle = "";
	var state = { enabled: false, signedIn: false, member: {}, csrf: "" };
	var statusRequest = null;

	// Layout only. Colors and fonts come from the Kendo theme's classes.
	function addStyles() {
		if ($("#galaxieMemberStyles").length) { return; }
		$("head").append($('<style id="galaxieMemberStyles"></style>').text(
			".galaxieMemberForm .galaxieMemberField { margin: 0 0 1em 0; }" +
			".galaxieMemberForm .galaxieMemberField > label { display: block; margin-bottom: 0.3em; }" +
			".galaxieMemberForm .k-textbox, .galaxieMemberForm .k-dropdown { width: 100%; box-sizing: border-box; }" +
			".galaxieMemberHp { position: absolute; left: -10000px; top: auto; width: 1px; height: 1px; overflow: hidden; }" +
			".galaxieMemberMessage { margin: 0 0 1em 0; }" +
			".galaxieMemberButtons .k-button { margin: 0 0.5em 0.5em 0; }" +
			// Hints read like normal text (the owner's admin look), not Kendo's small hint font.
			".galaxieMemberForm .k-form-hint { display: block; font-size: inherit; margin: 0 0 0.3em 0; }" +
			".galaxieMemberSection { margin: 0 0 1.25em 0; }" +
			".galaxieMemberSection h4 { margin: 0 0 0.5em 0; }" +
			".galaxieMemberItem { padding: 0.6em 0; border-top: 1px solid rgba(128,128,128,0.25); }" +
			".galaxieMemberFacts { margin-top: 0.2em; }" +
			".galaxieMemberItem .galaxieMemberButtons { margin-top: 0.5em; }" +
			".galaxieMemberFollowed { margin-top: 0.3em; }" +
			".galaxieMemberLink { background: none; border: 0; padding: 0; font: inherit; color: inherit; text-decoration: underline; cursor: pointer; }"
		));
	}

	function post(method, data) {
		return $.ajax({ type: "post", url: proxyUrl + "?method=" + method, data: data || {}, dataType: "json", cache: false });
	}

	function esc(text) { return $("<div/>").text(text == null ? "" : String(text)).html(); }

	function openWindow(title, content, width) {
		var box = $("<div></div>").addClass("galaxieMemberForm").append(content).appendTo("body");
		var dialog = box.kendoWindow({
			title: title, modal: true, visible: false, resizable: false,
			width: Math.min(width || 520, $(window).width() - 30),
			maxHeight: Math.round($(window).height() * 0.85),
			close: function() { this.destroy(); }
		}).data("kendoWindow");
		dialog.center().open();
		return dialog;
	}

	// The current page without a sign-in token (the link comes back to the page the visitor asked from).
	function currentPage() {
		return window.location.href.split("#")[0].replace(/([?&])memberSignIn=[^&]*&?/, "$1").replace(/[?&]$/, "");
	}

	// ---------------------------------------------------------------------------------------------------------- menu

	function menuText() {
		if (!state.signedIn) { return "Sign in"; }
		return state.member.name ? state.member.name : "My account";
	}

	// Adds "Sign in" / the member's name to both menus (the one under the title and the one fixed to the top when scrolling).
	// Where the words would make the menu wrap to a second line (phones, or a long name), a person icon is shown instead,
	// with the words as its label and tooltip.
	function updateMenus() {
		$("#topMenu, #fixedNavMenu").each(function() {
			var menuElement = $(this);
			var menu = menuElement.data("kendoMenu");
			var item = menuElement.find("> li.galaxieMemberMenuItem");
			if (!item.length) {
				var markup = '<span class="galaxieMemberMenuText"></span>';
				var before = menuElement.find("> li.siteSearchButton");
				if (menu && before.length) {
					menu.insertBefore({ text: markup, encoded: false, cssClass: "galaxieMemberMenuItem" }, before);
				} else if (menu) {
					menu.append({ text: markup, encoded: false, cssClass: "galaxieMemberMenuItem" });
				} else {
					menuElement.append($('<li class="galaxieMemberMenuItem"></li>').html(markup));
				}
				item = menuElement.find("> li.galaxieMemberMenuItem");
			}
			item.find(".galaxieMemberMenuText").text(menuText()).removeClass("galaxieMemberMenuIcon").removeAttr("aria-label title role");
		});
		// The menu fixed to the top is hidden until the page scrolls, so the menu under the title decides for both.
		var measured = $("#topMenu:visible");
		if (!measured.length) { measured = $("#fixedNavMenu:visible"); }
		if (measured.length && menuWraps(measured)) {
			$("#topMenu, #fixedNavMenu").find("> li.galaxieMemberMenuItem .galaxieMemberMenuText").each(function() {
				$(this).empty().addClass("galaxieMemberMenuIcon")
					.attr({ "aria-label": menuText(), title: menuText(), role: "img" })
					.append('<span class="k-icon k-i-user" aria-hidden="true"></span>');
			});
		}
	}

	// True when the menu's items no longer fit on one line (an item starts lower than the first one).
	function menuWraps(menuElement) {
		var items = menuElement.children("li:visible");
		if (items.length < 2) { return false; }
		var top = items.first()[0].getBoundingClientRect().top;
		var wraps = false;
		items.each(function() { if (this.getBoundingClientRect().top > top + 4) { wraps = true; return false; } });
		return wraps;
	}

	// The phone turned, or the window changed size: the words may fit now (or no longer).
	var resizeTimer = null;
	$(window).on("resize orientationchange", function() {
		clearTimeout(resizeTimer);
		resizeTimer = setTimeout(function() { if (state.enabled) { updateMenus(); } }, 250);
	});

	$(document).on("click", ".galaxieMemberMenuItem", function(e) {
		e.preventDefault();
		if (state.signedIn) { openAccount(); } else { openSignIn(); }
	});

	// ------------------------------------------------------------------------------------------------------- sign in

	function openSignIn(message) {
		var content = $(
			'<form novalidate>' +
				'<p class="galaxieMemberMessage"></p>' +
				'<div class="galaxieMemberField"><label for="galaxieMemberEmail">Your email address</label>' +
				'<input type="email" id="galaxieMemberEmail" class="k-textbox" maxlength="255" autocomplete="email" required></div>' +
				'<div class="galaxieMemberHp" aria-hidden="true"><label>Leave this empty <input type="text" name="website" tabindex="-1" autocomplete="off"></label></div>' +
				'<div class="galaxieMemberButtons"><button type="submit" class="k-button k-primary">Email me a sign-in link</button></div>' +
				'<div class="k-form-hint">No password needed: we email you a link that signs you in. It works once, for 15 minutes.</div>' +
			'</form>'
		);
		content.find(".galaxieMemberMessage").text(message || "Sign in to see your bookings and sign-ups, and have your details filled in for you.");
		var dialog = openWindow("Sign in to " + blogTitle, content);
		content.find("#galaxieMemberEmail").focus();
		content.on("submit", function(e) {
			e.preventDefault();
			var button = content.find("button[type=submit]").prop("disabled", true);
			post("memberRequestSignIn", { email: $.trim(content.find("#galaxieMemberEmail").val()), returnUrl: currentPage(), website: content.find("input[name=website]").val() })
				.done(function(response) {
					if (response && response.success) {
						content.empty().append($('<p class="galaxieMemberMessage"></p>').text(response.message))
							.append($('<div class="k-form-hint"></div>').text("Check your inbox (and the spam folder). You can close this window."));
					} else {
						content.find(".galaxieMemberMessage").text((response && response.message) || "Something went wrong. Please try again.");
						button.prop("disabled", false);
					}
				})
				.fail(function() {
					content.find(".galaxieMemberMessage").text("Something went wrong. Please try again.");
					button.prop("disabled", false);
				});
		});
		return dialog;
	}

	// The page an emailed link opens: one click finishes signing in.
	function completeSignIn(token) {
		var content = $(
			'<div>' +
				'<p class="galaxieMemberMessage"></p>' +
				'<div class="galaxieMemberField"><label><input type="checkbox" class="k-checkbox" id="galaxieMemberRemember" checked> Keep me signed in on this device</label></div>' +
				'<div class="k-form-hint">Uncheck this on a shared or public computer.</div>' +
				'<div class="galaxieMemberButtons" style="margin-top: 1em;"><button type="button" class="k-button k-primary galaxieMemberGo">Sign in</button></div>' +
			'</div>'
		);
		content.find(".galaxieMemberMessage").text("Welcome back. Click Sign in to finish signing in to " + blogTitle + ".");
		var dialog = openWindow("Sign in", content);
		// The token is no longer needed in the address bar (or in a bookmark of this page).
		if (window.history && window.history.replaceState) { window.history.replaceState(null, "", currentPage()); }
		content.find(".galaxieMemberGo").on("click", function() {
			var button = $(this).prop("disabled", true);
			post("memberCompleteSignIn", { token: token, remember: content.find("#galaxieMemberRemember").is(":checked") })
				.done(function(response) {
					if (response && response.success) {
						state.signedIn = true;
						state.member = response.member || {};
						state.csrf = response.csrf || "";
						updateMenus();
						$(document).trigger("galaxieMemberChanged", [state]);
						dialog.close();
						if (!state.member.name) { openAccount("You're signed in. Add your name so it can be filled in for you."); }
					} else {
						content.empty().append($('<p class="galaxieMemberMessage"></p>').text((response && response.message) || "This sign-in link can't be used."))
							.append($('<div class="galaxieMemberButtons"><button type="button" class="k-button k-primary">Email me a new link</button></div>'));
						content.find("button").on("click", function() { dialog.close(); openSignIn(); });
					}
				})
				.fail(function() {
					content.find(".galaxieMemberMessage").text("Something went wrong. Please try again.");
					button.prop("disabled", false);
				});
		});
	}

	// ------------------------------------------------------------------------------------------------------ account

	function timeZoneOptions(selected) {
		var zones = [];
		try { zones = Intl.supportedValuesOf("timeZone"); } catch (error) { zones = []; }
		var guess = "";
		try { guess = Intl.DateTimeFormat().resolvedOptions().timeZone; } catch (error) { guess = ""; }
		var value = selected || guess || "";
		if (value && zones.indexOf(value) < 0) { zones.unshift(value); }
		// The label reads "America/Los Angeles"; the value keeps the real id, "America/Los_Angeles".
		var items = $.map(zones, function(zone) { return { text: zone.replace(/_/g, " "), value: zone }; });
		return { zones: items, value: value };
	}

	// My account: the member's bookings, sign-ups and emails (ProxyController.cfc's memberAccount), then their details.
	function openAccount(message) {
		var m = state.member || {};
		var content = $(
			'<div>' +
				'<p class="galaxieMemberMessage"></p>' +
				'<div class="galaxieMemberSection galaxieMemberBookings"><h4>Your bookings</h4><div class="galaxieMemberList">Loading...</div></div>' +
				'<div class="galaxieMemberSection galaxieMemberSignups"><h4>Your sign-ups</h4><div class="galaxieMemberList">Loading...</div></div>' +
				'<div class="galaxieMemberSection galaxieMemberEmails"><h4>Emails</h4><div class="galaxieMemberList">Loading...</div></div>' +
				'<form novalidate class="galaxieMemberSection galaxieMemberDetails"><h4>Your details</h4>' +
					'<div class="galaxieMemberField"><label>Email</label><div class="galaxieMemberEmail"></div></div>' +
					'<div class="galaxieMemberField"><label for="galaxieMemberName">Name</label><input type="text" id="galaxieMemberName" class="k-textbox" maxlength="125" autocomplete="name"></div>' +
					'<div class="galaxieMemberField"><label for="galaxieMemberPhone">Phone</label><div class="k-form-hint">Optional. Filled in when you book.</div><input type="tel" id="galaxieMemberPhone" class="k-textbox" maxlength="50" autocomplete="tel"></div>' +
					'<div class="galaxieMemberField"><label for="galaxieMemberTimeZone">Time zone</label><div class="k-form-hint">Booking times are shown in this time zone.</div><input id="galaxieMemberTimeZone"></div>' +
					'<div class="galaxieMemberButtons"><button type="submit" class="k-button k-primary">Save my details</button> <span class="galaxieMemberSaved" role="status"></span></div>' +
				'</form>' +
				'<div class="galaxieMemberSection"><h4>Your data</h4>' +
					'<div class="k-form-hint">Download a copy of everything this site keeps about you, or delete your account.</div>' +
					'<div class="galaxieMemberButtons"><button type="button" class="k-button galaxieMemberDownload">Download my data</button><button type="button" class="k-button galaxieMemberDelete">Delete my account</button></div>' +
				'</div>' +
				'<div class="galaxieMemberSection"><h4>Signing out</h4>' +
					'<div class="k-form-hint">Sign out everywhere also signs you out of every device that was kept signed in.</div>' +
					'<div class="galaxieMemberButtons"><button type="button" class="k-button galaxieMemberSignOut">Sign out</button><button type="button" class="k-button galaxieMemberSignOutAll">Sign out everywhere</button></div>' +
				'</div>' +
			'</div>'
		);
		content.find(".galaxieMemberMessage").text(message || "");
		content.find(".galaxieMemberMessage").toggle(!!message);
		content.find(".galaxieMemberEmail").text(m.email || "");
		content.find("#galaxieMemberName").val(m.name || "");
		content.find("#galaxieMemberPhone").val(m.phone || "");
		var dialog = openWindow("My account", content, 720);
		loadAccount(content, dialog);

		var tz = timeZoneOptions(m.timeZone);
		var zonePicker = null;
		galaxieLoader.kendoDropDownList(function() {
			zonePicker = content.find("#galaxieMemberTimeZone").kendoDropDownList({ dataSource: tz.zones, dataTextField: "text", dataValueField: "value", value: tz.value, filter: "contains" }).data("kendoDropDownList");
		});
		content.find("form.galaxieMemberDetails").on("submit", function(e) {
			e.preventDefault();
			var button = $(this).find("button[type=submit]").prop("disabled", true);
			var saved = content.find(".galaxieMemberSaved").text("");
			post("memberSaveProfile", { csrf: state.csrf, name: $.trim(content.find("#galaxieMemberName").val()), phone: $.trim(content.find("#galaxieMemberPhone").val()), timeZone: zonePicker ? zonePicker.value() : tz.value })
				.done(function(response) {
					button.prop("disabled", false);
					if (response && response.success) {
						state.member = response.member;
						updateMenus();
						$(document).trigger("galaxieMemberChanged", [state]);
						saved.text("Saved.");
						// Booking times follow the time zone.
						loadAccount(content, dialog);
					} else {
						saved.text(((response && response.errors) || ["Something went wrong."]).join(" "));
					}
				})
				.fail(function() { button.prop("disabled", false); saved.text("Something went wrong. Please try again."); });
		});
		content.find(".galaxieMemberDownload").on("click", function() { downloadData($(this)); });
		content.find(".galaxieMemberDelete").on("click", function() { openDeleteAccount(dialog); });
		content.find(".galaxieMemberSignOut, .galaxieMemberSignOutAll").on("click", function() {
			var everywhere = $(this).hasClass("galaxieMemberSignOutAll");
			post("memberSignOut", { csrf: state.csrf, everywhere: everywhere }).always(function() {
				state = { enabled: true, signedIn: false, member: {}, csrf: "" };
				updateMenus();
				$(document).trigger("galaxieMemberChanged", [state]);
				dialog.close();
			});
		});
	}

	function loadAccount(content, dialog) {
		post("memberAccount", { csrf: state.csrf }).done(function(response) {
			if (!response || !response.success) {
				content.find(".galaxieMemberList").text("Please sign in again.");
				return;
			}
			renderBookings(content.find(".galaxieMemberBookings .galaxieMemberList"), response.bookings || [], content, dialog);
			renderSignups(content.find(".galaxieMemberSignups .galaxieMemberList"), response.signups || []);
			renderEmails(content.find(".galaxieMemberEmails .galaxieMemberList"), response.subscriptions || {}, content, dialog);
			dialog.center();
		}).fail(function() {
			content.find(".galaxieMemberList").text("Your account couldn't be loaded. Please try again.");
		});
	}

	function renderBookings(box, bookings, content, dialog) {
		box.empty();
		var upcoming = $.grep(bookings, function(b) { return b.upcoming && b.status !== "cancelled"; });
		var past = $.grep(bookings, function(b) { return !(b.upcoming && b.status !== "cancelled"); });
		if (!bookings.length) { box.text("You haven't booked anything yet."); return; }
		if (!upcoming.length) { box.append($('<div class="galaxieMemberItem"></div>').text("Nothing coming up.")); }
		$.each(upcoming, function(i, b) { box.append(bookingItem(b, content, dialog)); });
		if (past.length) {
			var toggle = $('<button type="button" class="galaxieMemberLink"></button>').text("Show past and cancelled bookings (" + past.length + ")");
			var pastBox = $('<div class="galaxieMemberPast"></div>').hide();
			$.each(past, function(i, b) { pastBox.append(bookingItem(b, content, dialog)); });
			toggle.on("click", function() { pastBox.toggle(); toggle.text((pastBox.is(":visible") ? "Hide" : "Show") + " past and cancelled bookings (" + past.length + ")"); dialog.center(); });
			box.append($('<div class="galaxieMemberItem"></div>').append(toggle)).append(pastBox);
		}
	}

	function bookingItem(b, content, dialog) {
		var item = $('<div class="galaxieMemberItem"></div>');
		item.append($("<div></div>").append($("<strong></strong>").text(b.typeName)).append(document.createTextNode(", " + b.when)));
		var facts = [];
		if (b.location) { facts.push(b.location); }
		facts.push(b.statusText);
		if (b.paid) { facts.push("Paid " + b.paid); }
		if (b.refunded) { facts.push("Refunded " + b.refunded); }
		if (b.stillToPay) { facts.push("Still to pay " + b.stillToPay); }
		item.append($('<div class="galaxieMemberFacts"></div>').text(facts.join(" · ")));
		var buttons = $('<div class="galaxieMemberButtons"></div>');
		if (b.manageToken) {
			$('<button type="button" class="k-button">Change or cancel</button>').on("click", function() {
				galaxieLoader.bookings(function() {
					galaxieBookings.manage(b.manageToken, { baseUrl: baseUrl });
					refreshWhenClosed(content, dialog);
				});
			}).appendTo(buttons);
		}
		if (b.payToken) {
			$('<button type="button" class="k-button k-primary">Pay the rest</button>').on("click", function() {
				galaxieLoader.bookings(function() {
					galaxieBookings.payBalance(b.payToken, { baseUrl: baseUrl });
				});
			}).appendTo(buttons);
		}
		if (buttons.children().length) { item.append(buttons); }
		return item;
	}

	// Download my data: the server sends a JSON file (ProxyController.cfc's memberExportData), saved under the name it gives.
	function downloadData(button) {
		button.prop("disabled", true);
		var body = new URLSearchParams();
		body.append("csrf", state.csrf);
		fetch(proxyUrl + "?method=memberExportData", { method: "POST", body: body, credentials: "same-origin", cache: "no-store" })
			.then(function(response) {
				if (!response.ok) { throw new Error("status " + response.status); }
				var name = /filename="([^"]+)"/.exec(response.headers.get("Content-Disposition") || "");
				return response.blob().then(function(blob) { return { blob: blob, name: name ? name[1] : "my-data.json" }; });
			})
			.then(function(file) {
				var link = document.createElement("a");
				link.href = URL.createObjectURL(file.blob);
				link.download = file.name;
				document.body.appendChild(link);
				link.click();
				setTimeout(function() { URL.revokeObjectURL(link.href); link.remove(); }, 1000);
			})
			.catch(function() { alertMessage("Your data couldn't be downloaded. Please sign in again and try once more."); })
			.then(function() { button.prop("disabled", false); });
	}

	function alertMessage(text) {
		openWindow("My account", $("<p></p>").text(text));
	}

	// Delete my account: says what goes and what stays, and asks for the email address to confirm.
	function openDeleteAccount(accountDialog) {
		var content = $(
			'<form novalidate>' +
				'<p class="galaxieMemberMessage">Deleting your account signs you out everywhere and removes your account, your details and the devices you stay signed in on. You can make a new account later by signing in again.</p>' +
				'<p class="galaxieMemberUpcoming" hidden></p>' +
				'<p>Your bookings, payments, form sign-ups and comments stay with the site owner for their records.</p>' +
				'<div class="galaxieMemberField"><label><input type="checkbox" class="k-checkbox" id="galaxieMemberStopEmails" checked> Also stop every email from this site (new posts and new comments)</label></div>' +
				'<div class="galaxieMemberField"><label for="galaxieMemberConfirmEmail">To confirm, type your email address</label><input type="email" id="galaxieMemberConfirmEmail" class="k-textbox" autocomplete="off"></div>' +
				'<p class="galaxieMemberDeleteError" role="alert"></p>' +
				'<div class="galaxieMemberButtons"><button type="submit" class="k-button">Delete my account</button><button type="button" class="k-button galaxieMemberKeep">Keep my account</button></div>' +
			'</form>'
		);
		var dialog = openWindow("Delete my account", content);
		post("memberAccountDeleteInfo", { csrf: state.csrf }).done(function(response) {
			if (response && response.upcomingBookings > 0) {
				content.find(".galaxieMemberUpcoming").prop("hidden", false).text("You have " + response.upcomingBookings + " upcoming booking" + (response.upcomingBookings === 1 ? "" : "s") + ". Deleting your account doesn't cancel " + (response.upcomingBookings === 1 ? "it" : "them") + "; to cancel, use Change or cancel in My account first.");
			}
		});
		content.find(".galaxieMemberKeep").on("click", function() { dialog.close(); });
		content.on("submit", function(e) {
			e.preventDefault();
			var button = content.find("button[type=submit]").prop("disabled", true);
			post("memberDeleteAccount", { csrf: state.csrf, confirmEmail: $.trim(content.find("#galaxieMemberConfirmEmail").val()), stopEmails: content.find("#galaxieMemberStopEmails").is(":checked") })
				.done(function(response) {
					if (response && response.success) {
						state = { enabled: true, signedIn: false, member: {}, csrf: "" };
						updateMenus();
						$(document).trigger("galaxieMemberChanged", [state]);
						dialog.close();
						accountDialog.close();
						alertMessage("Your account was deleted.");
					} else {
						button.prop("disabled", false);
						content.find(".galaxieMemberDeleteError").text((response && response.message) || "Something went wrong. Please try again.");
					}
				})
				.fail(function() { button.prop("disabled", false); content.find(".galaxieMemberDeleteError").text("Something went wrong. Please try again."); });
		});
	}

	// After a booking is changed or cancelled in its own window (bookings.js), list the bookings again once that window closes.
	function refreshWhenClosed(content, dialog) {
		var before = $(".k-window:visible").length;
		var opened = false;
		var timer = setInterval(function() {
			var now = $(".k-window:visible").length;
			if (now > before) { opened = true; }
			if (opened && now <= before) { clearInterval(timer); if (dialog.element.is(":visible")) { loadAccount(content, dialog); } }
			if (!dialog.element.closest(".k-window").length) { clearInterval(timer); }
		}, 500);
	}

	function renderSignups(box, signups) {
		box.empty();
		if (!signups.length) { box.text("You haven't signed up for anything yet."); return; }
		$.each(signups, function(i, s) {
			var item = $('<div class="galaxieMemberItem"></div>');
			item.append($("<strong></strong>").text(s.formTitle));
			if (s.postTitle) {
				item.append(document.createTextNode(", on "));
				item.append(s.postUrl ? $("<a></a>").attr("href", s.postUrl).text(s.postTitle) : $("<span></span>").text(s.postTitle));
			}
			item.append($('<div class="galaxieMemberFacts"></div>').text(s.date));
			// An event sign-up (2026-10-15): when, how many, and a way to cancel until the event starts.
			if (s.event && s.event.when) {
				var facts = s.event.when + ". " + (s.event.people > 1 ? s.event.people + " people" : "1 person") + (s.event.how ? ", " + s.event.how : "") + (s.event.paid ? ". Paid " + s.event.paid : "") + (s.event.status === "cancelled" ? ". Cancelled." : ".");
				item.append($('<div class="galaxieMemberFacts"></div>').text(facts));
				if (s.event.canCancel && s.event.token) {
					var status = $('<div class="galaxieMemberFacts" role="status" aria-live="polite"></div>');
					$('<button type="button" class="k-button">Cancel my place</button>').appendTo(item).on("click", function() {
						var button = $(this).prop("disabled", true);
						$.ajax({ type: "post", url: proxyUrl + "?method=cancelManagedRsvp", data: { token: s.event.token }, dataType: "json", cache: false })
							.done(function(response) {
								if (response && response.success === true) { button.remove(); status.text("Your place is cancelled."); }
								else { button.prop("disabled", false); status.text((response && response.message) || "Your place could not be cancelled."); }
							})
							.fail(function() { button.prop("disabled", false); status.text("Your place could not be cancelled. Please try again."); });
					});
					item.append(status);
				}
			}
			box.append(item);
		});
	}

	function renderEmails(box, subs, content, dialog) {
		box.empty();
		var newPosts = $('<div class="galaxieMemberItem"></div>');
		var checkbox = $('<input type="checkbox" class="k-checkbox" id="galaxieMemberNewPosts">').prop("checked", subs.newPosts === "on" || subs.newPosts === "unconfirmed");
		newPosts.append($('<label for="galaxieMemberNewPosts"></label>').append(checkbox).append(document.createTextNode(" Email me new posts")));
		var status = $('<span class="galaxieMemberSaved" role="status"></span>');
		newPosts.append(" ").append(status);
		checkbox.on("change", function() {
			var on = checkbox.is(":checked");
			status.text("");
			post("memberSetNewPostEmails", { csrf: state.csrf, on: on }).done(function(response) {
				status.text(response && response.success ? (on ? "On." : "Off.") : "Something went wrong.");
			});
		});
		box.append(newPosts);
		var posts = subs.posts || [];
		var followed = $('<div class="galaxieMemberItem"></div>');
		if (!posts.length) {
			followed.text("You aren't following any posts' comments.");
		} else {
			followed.append($("<div></div>").text("New comments on these posts are emailed to you:"));
			$.each(posts, function(i, p) {
				var row = $('<div class="galaxieMemberFollowed"></div>');
				row.append($("<a></a>").attr("href", p.url).text(p.title)).append(" ");
				$('<button type="button" class="galaxieMemberLink">Stop</button>').on("click", function() {
					post("memberStopFollowingPost", { csrf: state.csrf, postId: p.postId }).done(function(response) {
						if (response && response.success) { row.remove(); if (!followed.find(".galaxieMemberFollowed").length) { followed.text("You aren't following any posts' comments."); } }
					});
				}).appendTo(row);
				followed.append(row);
			});
		}
		box.append(followed);
	}

	// -------------------------------------------------------------------------------------------------- filling in

	// A signed-in member's name, email and phone go into empty fields marked data-member-fill="name|email|phone": the booking
	// widget (bookings.js), forms placed in posts (WebForms.cfc), the comment/subscribe/contact window and the Subscribe pod.
	// Only empty fields, and each field once, so nothing the visitor typed (or cleared) is ever overwritten.
	function prefill(root) {
		if (!state.signedIn) { return; }
		var values = { name: state.member.name || "", email: state.member.email || "", phone: state.member.phone || "" };
		$(root).find("[data-member-fill]").addBack("[data-member-fill]").each(function() {
			var field = $(this);
			var value = values[field.attr("data-member-fill")];
			if (field.data("memberFilled") || !value || $.trim(field.val()).length) { return; }
			field.data("memberFilled", true).val(value).trigger("change");
		});
	}

	// Fields added later (a booking's details step, a comment window opening) are filled as they appear.
	function watchForFields() {
		if (!window.MutationObserver) { return; }
		new MutationObserver(function(mutations) {
			if (!state.signedIn) { return; }
			for (var i = 0; i < mutations.length; i++) {
				for (var j = 0; j < mutations[i].addedNodes.length; j++) {
					var node = mutations[i].addedNodes[j];
					if (node.nodeType === 1 && (node.hasAttribute("data-member-fill") || node.querySelector("[data-member-fill]"))) { prefill(node); }
				}
			}
		}).observe(document.body, { childList: true, subtree: true });
	}

	$(document).on("galaxieMemberChanged", function(e, changed) {
		if (changed && changed.signedIn) { prefill(document.body); }
	});

	// ------------------------------------------------------------------------------------------------------- start

	function init(options) {
		baseUrl = options.baseUrl;
		proxyUrl = options.baseUrl + "/common/cfc/ProxyController.cfc";
		blogTitle = options.blogTitle || "this site";
		addStyles();
		var token = /[?&]memberSignIn=([a-f0-9]{64})/.exec(window.location.search);
		statusRequest = post("memberStatus").done(function(response) {
			if (!response || !response.enabled) { return; }
			watchForFields();
			state = { enabled: true, signedIn: response.signedIn === true, member: response.member || {}, csrf: response.csrf || "" };
			updateMenus();
			$(document).trigger("galaxieMemberChanged", [state]);
			if (token) { completeSignIn(token[1]); }
		});
	}

	// For other scripts (bookings, forms): the signed-in member, once known. callback(state)
	function whenKnown(callback) {
		if (statusRequest) { statusRequest.always(function() { callback(state); }); } else { callback(state); }
	}

	return { init: init, openSignIn: openSignIn, openAccount: openAccount, whenKnown: whenKnown };

})(jQuery);
