/*
	Galaxie Blog forms on the site (2026-10-13).

	A form is placed in a post or page as <div class="galaxieWebForm" data-webform="its-alias">[Form: Title]</div> (the post
	editor's Form button inserts it). This script is downloaded only on pages that have one - see galaxieLoader.webForms in
	includes/templates/head.cfm and the check in includes/templates/tailEndScripts.cfm - and:
	- asks the server for the form (ProxyController.cfc's getWebFormForPage), which also hands out a one-time token;
	- turns its dropdowns and dates into Kendo widgets, and shows the captcha when the form uses it;
	- sends it (submitWebForm) and shows the confirmation, or the problems next to the fields.
	The form is fetched after the page has loaded, because the page itself is cached and served the same to every visitor.
	The server checks everything again; nothing here is relied on for safety.
*/
var galaxieWebForms = (function($) {

	var baseUrl = "";
	var proxyUrl = "";

	// Layout only - spacing, widths, and hiding the bots' field. Colors and fonts come from the Kendo theme's classes.
	function addStyles() {
		if ($("#galaxieWebFormStyles").length) { return; }
		$("head").append($('<style id="galaxieWebFormStyles"></style>').text(
			".galaxieWebForm { margin: 1.5em 0; }" +
			".galaxieWebFormField { margin: 0 0 1em 0; }" +
			".galaxieWebFormField > label { display: block; margin-bottom: 0.3em; }" +
			".galaxieWebFormField .k-textbox, .galaxieWebFormField textarea, .galaxieWebFormField .k-dropdown, .galaxieWebFormField .k-datepicker { width: 100%; max-width: 40em; box-sizing: border-box; }" +
			".galaxieWebFormGroup { border: 0; margin: 0; padding: 0; }" +
			".galaxieWebFormGroup legend { padding: 0; margin-bottom: 0.3em; }" +
			".galaxieWebFormChoice { margin: 0.25em 0; }" +
			".galaxieWebFormField.galaxieWebFormChoice > label { display: inline; margin: 0 0 0 0.4em; }" +
			".galaxieWebFormHelp { margin-top: 0.25em; }" +
			".galaxieWebFormError { display: block; position: static; margin-top: 0.3em; }" +
			".galaxieWebFormError[hidden] { display: none; }" +
			".galaxieWebFormCaptchaImage img { display: block; margin-bottom: 0.5em; max-width: 100%; }" +
			".galaxieWebFormHp { position: absolute; left: -10000px; top: auto; width: 1px; height: 1px; overflow: hidden; }" +
			".galaxieWebFormStatus { margin-top: 0.75em; }" +
			// The public sign-up list. On a phone each row becomes a small card, with the column name before each value.
			".galaxieWebFormList { margin: 1.5em 0; }" +
			".galaxieWebFormListTools { margin: 0.5em 0; }" +
			".galaxieWebFormListSearch { width: 100%; max-width: 20em; box-sizing: border-box; }" +
			".galaxieWebFormListCount { margin-left: 0.5em; }" +
			".galaxieWebFormListTable { width: 100%; border-collapse: collapse; }" +
			".galaxieWebFormListTable th, .galaxieWebFormListTable td { text-align: left; padding: 0.4em 0.6em; vertical-align: top; }" +
			".galaxieWebFormListTable tbody tr { border-top: 1px solid rgba(128,128,128,0.25); }" +
			".galaxieWebFormListSort { background: none; border: 0; padding: 0; font: inherit; color: inherit; cursor: pointer; }" +
			"@media (max-width: 600px) {" +
				".galaxieWebFormListTable thead { display: none; }" +
				".galaxieWebFormListTable tr { display: block; padding: 0.5em 0; }" +
				".galaxieWebFormListTable td { display: block; padding: 0.15em 0; }" +
				".galaxieWebFormListTable td:empty { display: none; }" +
				".galaxieWebFormListTable td::before { content: attr(data-label) ': '; font-weight: bold; }" +
			"}"
		));
	}

	function init(options) {
		baseUrl = (options && options.baseUrl) || "";
		proxyUrl = baseUrl + "/common/cfc/ProxyController.cfc";
		addStyles();
		$(".galaxieWebForm[data-webform]").each(function() {
			var placeholder = $(this);
			if (placeholder.data("galaxieWebFormLoaded")) { return; }
			placeholder.data("galaxieWebFormLoaded", true);
			loadForm(placeholder);
		});
		$(".galaxieWebFormList[data-webform]").each(function() {
			var placeholder = $(this);
			if (placeholder.data("galaxieWebFormLoaded")) { return; }
			placeholder.data("galaxieWebFormLoaded", true);
			loadList(placeholder);
		});
	}

	// A form's public sign-up list (WebForms.cfc's renderPublicListHtml), fetched after the page loads like the form, so the
	// cached page never shows an old list. A form whose list isn't public shows nothing.
	function loadList(placeholder) {
		$.ajax({
			type: "post",
			url: proxyUrl + "?method=getWebFormListForPage",
			data: { alias: placeholder.attr("data-webform") },
			dataType: "json",
			cache: false
		}).done(function(response) {
			if (!response || response.success !== true || !response.html) {
				placeholder.empty().attr("hidden", "hidden");
				return;
			}
			placeholder.html(response.html).removeAttr("hidden");
			setUpList(placeholder);
		}).fail(function() {
			placeholder.empty().attr("hidden", "hidden");
		});
	}

	// Lists of the same form on this page, reloaded after someone signs up so they see their own row.
	function reloadLists(alias) {
		$(".galaxieWebFormList").filter(function() { return $(this).attr("data-webform") === alias; }).each(function() {
			loadList($(this));
		});
	}

	function setUpList(placeholder) {
		var table = placeholder.find(".galaxieWebFormListTable");
		var rows = table.find("tbody tr");
		var count = placeholder.find(".galaxieWebFormListCount");
		var total = rows.length;
		placeholder.find(".galaxieWebFormListSearch").on("input", function() {
			var text = $.trim($(this).val()).toLowerCase();
			var shown = 0;
			rows.each(function() {
				var match = !text.length || $(this).text().toLowerCase().indexOf(text) >= 0;
				$(this).toggle(match);
				if (match) { shown++; }
			});
			count.text(text.length ? shown + " of " + total : total + (total === 1 ? " sign-up" : " sign-ups"));
		});
		// Click a heading to sort by it; click again to reverse. Numbers sort as numbers.
		placeholder.find(".galaxieWebFormListSort").each(function(column) {
			$(this).on("click", function() {
				var ascending = $(this).attr("data-sort") !== "asc";
				placeholder.find(".galaxieWebFormListSort").removeAttr("data-sort").closest("th").removeAttr("aria-sort");
				$(this).attr("data-sort", ascending ? "asc" : "desc").closest("th").attr("aria-sort", ascending ? "ascending" : "descending");
				var sorted = rows.get().sort(function(a, b) {
					var x = $.trim($(a).children().eq(column).text()), y = $.trim($(b).children().eq(column).text());
					var result = ($.isNumeric(x) && $.isNumeric(y)) ? x - y : x.localeCompare(y, undefined, { sensitivity: "base" });
					return ascending ? result : -result;
				});
				table.find("tbody").append(sorted);
			});
		});
	}

	function loadForm(placeholder) {
		$.ajax({
			type: "post",
			url: proxyUrl + "?method=getWebFormForPage",
			data: { alias: placeholder.attr("data-webform") },
			dataType: "json",
			cache: false
		}).done(function(response) {
			if (!response || response.success !== true) {
				// An inactive or deleted form shows nothing in its place.
				placeholder.empty().attr("hidden", "hidden");
				return;
			}
			placeholder.html(response.html).removeAttr("hidden");
			var form = placeholder.find("form.galaxieWebFormForm");
			form.data("token", response.token);
			setUpWidgets(form);
			if (response.captcha === true) { loadCaptcha(form); }
			form.on("submit", function(e) {
				e.preventDefault();
				send(form, placeholder);
			});
		}).fail(function() {
			placeholder.empty().attr("hidden", "hidden");
		});
	}

	function setUpWidgets(form) {
		if ($.fn.kendoDropDownList) {
			form.find("select").each(function() {
				var select = $(this);
				// A choice that is full (see choice limits in WebForms.cfc) comes as a disabled option, which Kendo's list doesn't
				// know about: it is shown greyed out and can't be picked.
				var full = select.find("option:disabled").map(function() { return this.value; }).get();
				// The items are passed in, as Kendo (2020) leaves disabled options out when it reads them from the select.
				var items = select.find("option").map(function() { return { text: $(this).text(), value: this.value }; }).get();
				select.kendoDropDownList({
					dataSource: items,
					dataTextField: "text",
					dataValueField: "value",
					optionLabel: false,
					template: function(item) {
						var text = $("<div/>").text(item.text).html();
						return full.indexOf(item.value) >= 0 ? '<span class="k-state-disabled">' + text + '</span>' : text;
					},
					select: function(e) {
						if (e.dataItem && full.indexOf(e.dataItem.value) >= 0) { e.preventDefault(); }
					}
				});
			});
		}
		if ($.fn.kendoDatePicker) {
			form.find("input.galaxieWebFormDate").each(function() {
				$(this).kendoDatePicker({ format: "yyyy-MM-dd" });
			});
		}
	}

	// The same captcha as the comment form: the server keeps the word in the visitor's session and returns its image.
	function loadCaptcha(form) {
		$.ajax({
			type: "post",
			url: proxyUrl + "?method=getCaptchaAsJson",
			dataType: "json",
			cache: false
		}).done(function(response) {
			var row = $.isArray(response) ? response[0] : response;
			var url = row && (row.captchaImageUrl || row.CAPTCHAIMAGEURL);
			if (url) {
				form.find(".galaxieWebFormCaptchaImage").empty().append($('<img alt="Captcha: the text to type">').attr("src", url + "&reload=" + new Date().getTime()));
			}
		});
	}

	function collectValues(form) {
		var values = {};
		form.find(".galaxieWebFormField[data-field]").each(function() {
			var field = $(this);
			var name = field.attr("data-field");
			var type = field.attr("data-type");
			if (!type) { return; } // the captcha, sent separately
			if (type === "checkboxes") {
				values[name] = field.find("input:checked").map(function() { return this.value; }).get().join(",");
			} else if (type === "radio") {
				values[name] = field.find("input:checked").val() || "";
			} else if (type === "consent") {
				values[name] = field.find("input").is(":checked") ? "yes" : "";
			} else {
				values[name] = $.trim(field.find("input, textarea, select").filter("[name='" + name + "']").val() || "");
			}
		});
		return values;
	}

	function clearProblems(form) {
		form.find(".galaxieWebFormError").attr("hidden", "hidden").text("");
		form.find("[aria-invalid]").removeAttr("aria-invalid");
		form.find(".galaxieWebFormStatus").text("");
	}

	function showProblems(form, errors, message) {
		var first = null;
		$.each(errors || {}, function(name, text) {
			var field = form.find(".galaxieWebFormField[data-field='" + name + "']");
			field.find(".galaxieWebFormError").text(text).removeAttr("hidden");
			field.find("input, textarea, select").attr("aria-invalid", "true");
			if (!first) { first = field; }
		});
		form.find(".galaxieWebFormStatus").text(message || (first ? "Please check the highlighted fields." : ""));
		if (first) { first.find("input, textarea, select").first().focus(); }
	}

	function send(form, placeholder) {
		clearProblems(form);
		var button = form.find("button[type='submit']");
		button.prop("disabled", true);
		$.ajax({
			type: "post",
			url: proxyUrl + "?method=submitWebForm",
			data: {
				alias: form.attr("data-alias"),
				token: form.data("token"),
				valuesJson: JSON.stringify(collectValues(form)),
				captchaText: $.trim(form.find("input[name='captchaText']").val() || ""),
				website: form.find("input[name='website']").val(),
				subscribeToBlog: form.find("input[name='subscribeToBlog']").is(":checked") ? "yes" : "",
				postId: placeholder.closest("[data-postid]").attr("data-postid") || 0
			},
			dataType: "json",
			cache: false
		}).done(function(response) {
			if (response && response.success === true) {
				reloadLists(form.attr("data-alias"));
				if (response.confirmationUrl) {
					window.location.href = response.confirmationUrl;
					return;
				}
				var confirmation = $('<p class="galaxieWebFormConfirmation" role="status" tabindex="-1"></p>').text(response.confirmationMessage || "Thank you. Your form was sent.");
				form.replaceWith(confirmation);
				confirmation.focus();
				return;
			}
			button.prop("disabled", false);
			showProblems(form, response && response.errors, response && response.message);
			// A wrong captcha word gets a new image to try again with.
			if (response && response.errors && response.errors.captchaText) {
				form.find("input[name='captchaText']").val("");
				loadCaptcha(form);
			}
		}).fail(function() {
			button.prop("disabled", false);
			form.find(".galaxieWebFormStatus").text("The form could not be sent. Please try again in a moment.");
		});
	}

	return { init: init };

})(jQuery);
