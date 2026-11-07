<!--- The Forms wizard (window 123, 11-07, owner; mock-up approved 11-06): a form in three steps, with its preview beside it - 1 what it's
for (the ready-made forms, or something else), 2 the questions (each one's wording, kind of answer and Required; choices for a choice
question; add, remove, move; the button's text), 3 after it's sent (the thank-you message, who gets each reply, spam protection, and
for sign-up forms whether the sign-ups show on the page). Finish saves it (ProxyController.cfc saveWebForm, as the form editor does).
It doesn't ask where the form goes: like scenes, forms go into posts from the post's side (Insert, Form). Started from Insert Form's
Build form, the new form is handed back there (refreshInsertWebFormWindow) to be put in. The full form editor (window 84,
webFormDetail.cfm) keeps everything else: help text, error wording, going to a page instead of the message, where it shows, Active.
optArgs is 0; otherArgs is a title typed in Insert Form's search, or empty. --->
<cfsilent>
<cfset fwStarters = arrayFilter(application.webForms.getStarterTemplates(), function (s) { return s.key neq "eventSignup"; })>
<!--- Something else (the blank form) last. --->
<cfset fwOrdered = arrayFilter(fwStarters, function (s) { return s.key neq "blank"; })>
<cfset arrayAppend(fwOrdered, arrayFilter(fwStarters, function (s) { return s.key eq "blank"; }), true)>
<cfset fwTitle = "">
<cfif isDefined("URL.otherArgs") and len(trim(URL.otherArgs)) and URL.otherArgs neq "undefined">
	<cfset fwTitle = left(trim(URL.otherArgs), 125)>
</cfif>
</cfsilent>
<style>
	#formWizardWindow .k-button .fontAwesomeIcon { margin-right: 6px; }
	.fwLayout { display: grid; grid-template-columns: minmax(0, 1.2fr) minmax(0, 1fr); gap: 16px; }
	@media (max-width: 900px) { .fwLayout { grid-template-columns: 1fr; } }
	.fwCards { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px; }
	.fwCard { text-align: left; padding: 10px; border: 1px solid rgba(128,128,128,.35); border-radius: 6px; background: transparent; color: inherit; font: inherit; cursor: pointer; }
	.fwCard:hover, .fwCard:focus { border-color: currentColor; outline: none; }
	.fwCard.selected { border-width: 3px; border-color: currentColor; padding: 8px; }
	.fwCard strong { display: block; margin-bottom: 4px; }
	.fwCard span { font-size: 12px; opacity: .8; }
	.fwQuestion { border: 1px solid rgba(128,128,128,.35); border-radius: 6px; padding: 8px 10px; margin-bottom: 8px; }
	.fwQuestionTop { display: flex; gap: 6px; align-items: center; }
	.fwQuestionTop .k-textbox { flex: 1 1 auto; }
	.fwQuestionKind { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; margin-top: 6px; }
	.fwQuestion textarea { width: 100%; box-sizing: border-box; margin-top: 6px; min-height: 54px; }
	.fwRow { margin-bottom: 12px; }
	.fwRow > label { display: block; font-weight: bold; margin-bottom: 4px; }
	.fwPreview { border: 1px solid rgba(128,128,128,.35); border-radius: 8px; padding: 14px; }
	.fwPreview .fwField { margin-bottom: 10px; }
	.fwPreview .fwBox { height: 30px; border: 1px solid rgba(128,128,128,.5); border-radius: 4px; }
	.fwPreview .fwBox.fwTall { height: 70px; }
	.fwDone { padding: 20px 6px; }
	.fwDone .k-button { margin: 4px 8px 4px 0; }
</style>

<cfoutput>
<div class="fwLayout">
	<div><div id="formWizard"></div></div>
	<div><div class="k-form-hint" style="margin-bottom: 4px;">Preview</div><div id="fwPreview" class="fwPreview"></div></div>
</div>

<div id="fwSteps" style="display: none;">
	<div id="fwStep1">
		<p>What is this form for? Each ready-made form comes with its questions; you can change them next.</p>
		<div id="fwCards" class="fwCards" role="radiogroup" aria-label="What the form is for"></div>
	</div>
	<div id="fwStep2">
		<div class="fwRow"><label for="fwTitle">Title</label><input type="text" id="fwTitle" class="k-textbox" maxlength="125" style="width: 95%;"><div class="k-form-hint">Visitors see it above the form.</div></div>
		<div id="fwQuestions"></div>
		<div style="display: flex; flex-wrap: wrap; gap: 10px; align-items: center; margin-top: 8px;">
			<button type="button" class="k-button normalFontWeight" id="fwAddQuestion"><i class="fontAwesomeIcon fas fa-plus"></i>Add a question</button>
			<label for="fwButton">Button text</label><input type="text" id="fwButton" class="k-textbox" maxlength="60" style="width: 160px;">
		</div>
	</div>
	<div id="fwStep3">
		<div class="fwRow"><label for="fwThanks">Thank-you message</label><textarea id="fwThanks" class="k-textbox" style="width: 95%; min-height: 60px;"></textarea><div class="k-form-hint">Shown after someone sends the form.</div></div>
		<div class="fwRow"><label for="fwEmail">Email each reply to</label><input type="text" id="fwEmail" class="k-textbox" style="width: 95%;" placeholder="Your blog's own email"><div class="k-form-hint">Separate addresses with commas. Empty uses the blog's own email.</div></div>
		<div class="fwRow"><input type="checkbox" id="fwSpam" class="k-checkbox"> <label for="fwSpam" class="k-checkbox-label" style="display: inline;">Protect from spam (the captcha)</label></div>
		<div class="fwRow" id="fwListRow" style="display: none;"><input type="checkbox" id="fwList" class="k-checkbox"> <label for="fwList" class="k-checkbox-label" style="display: inline;">Show the sign-ups on the page, so people can see who's coming</label></div>
	</div>
</div>
</cfoutput>

<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/js/galaxieWizard.js"></script>
<script>
(function () {
	var BASE = "<cfoutput>#application.baseUrl#</cfoutput>";
	var CSRF = "<cfoutput>#csrfToken#</cfoutput>";
	var STARTERS = <cfoutput>#replace(serializeJSON(fwOrdered), "</", "<\/", "all")#</cfoutput>;
	var TYPED_TITLE = <cfoutput>#serializeJSON(fwTitle)#</cfoutput>;
	var CAPTCHA = <cfoutput>#application.useCaptcha ? "true" : "false"#</cfoutput>;
	<!--- The kinds of answer, in plain words (WebForms.cfc fieldTypes). --->
	var KINDS = [["text", "Short answer"], ["textarea", "Long answer"], ["email", "Email address"], ["phone", "Phone number"], ["number", "Number"], ["date", "Date"],
		["radio", "Pick one"], ["checkboxes", "Pick any"], ["select", "Dropdown"], ["consent", "\"I agree\" checkbox"]];
	var CHOICE = { radio: 1, checkboxes: 1, select: 1 };
	var win = $("#formWizardWindow");
	var starter = null, form = null;

	function esc(s) { return $("<div/>").text(String(s || "")).html(); }
	function pick(s) {
		starter = s;
		form = JSON.parse(JSON.stringify(s));
		<!--- Adobe ColdFusion may send the keys in capitals. --->
		form = lower(form);
		if (TYPED_TITLE) { form.title = TYPED_TITLE; }
		if (s.key === "blank" && !form.title) { form.title = "New form"; }
		form.requireCaptcha = CAPTCHA;
		form.notifyEmails = "";
	}
	function lower(o) {
		if ($.isArray(o)) { return $.map(o, function (x) { return [lower(x)]; }); }
		if (o && typeof o === "object") { var r = {}; $.each(o, function (k, v) { r[k.charAt(0).toLowerCase() + k.slice(1)] = lower(v); }); return r; }
		return o;
	}

	<!--- ---------- Preview --->
	function preview() {
		var p = $("#fwPreview").empty();
		if (!form) { return; }
		p.append($("<h4></h4>").text(form.title || ""));
		if (form.description) { p.append($("<p></p>").text(form.description)); }
		$.each(form.fields || [], function (i, f) {
			var box = $('<div class="fwField"></div>').append($("<div></div>").text(f.label + (f.required ? " *" : "")));
			if (CHOICE[f.fieldType] && f.fieldType !== "select") {
				$.each(String(f.options || "").split(/\r?\n/), function (j, c) { if ($.trim(c)) { box.append($("<div></div>").html('<i class="fontAwesomeIcon ' + (f.fieldType === "radio" ? "far fa-circle" : "far fa-square") + '"></i> ' + esc(c))); } });
			} else if (f.fieldType === "consent") {
				box.html('<i class="fontAwesomeIcon far fa-square"></i> ' + esc(f.label) + (f.required ? " *" : ""));
			} else {
				box.append($('<div class="fwBox"></div>').toggleClass("fwTall", f.fieldType === "textarea"));
			}
			p.append(box);
		});
		if (form.requireCaptcha) { p.append('<div class="k-form-hint" style="margin-bottom: 8px;"><i class="fontAwesomeIcon fas fa-shield-halved"></i> Spam check</div>'); }
		p.append($('<button type="button" class="k-button k-primary" tabindex="-1"></button>').text(form.buttonLabel || "Send"));
	}

	<!--- ---------- Step 1 --->
	function drawCards() {
		var box = $("#fwCards").empty();
		$.each(STARTERS, function (i, s0) {
			var s = lower(s0);
			var labels = $.map(s.fields || [], function (f) { return f.label; }).join(", ");
			var card = $('<button type="button" class="fwCard" role="radio"></button>').toggleClass("selected", !!starter && starter.key === s.key)
				.append($("<strong></strong>").text(s.key === "blank" ? "Something else" : s.name), $("<span></span>").text(s.key === "blank" ? "Start with no questions and add your own." : labels));
			card.on("click", function () { pick(s); drawCards(); preview(); });
			card.on("dblclick", function () { wizard.select(1); });
			box.append(card);
		});
	}

	<!--- ---------- Step 2 --->
	function drawQuestions() {
		$("#fwTitle").val(form.title || "");
		$("#fwButton").val(form.buttonLabel || "Send");
		var box = $("#fwQuestions").empty();
		$.each(form.fields, function (i, f) {
			var row = $('<div class="fwQuestion"></div>');
			var text = $('<input type="text" class="k-textbox" aria-label="Question">').val(f.label).on("input", function () { f.label = $(this).val(); preview(); });
			var top = $('<div class="fwQuestionTop"></div>').append(text,
				$('<button type="button" class="k-button" title="Move up"><i class="fontAwesomeIcon fas fa-arrow-up" style="margin:0"></i></button>').prop("disabled", i === 0).on("click", function () { move(i, -1); }),
				$('<button type="button" class="k-button" title="Move down"><i class="fontAwesomeIcon fas fa-arrow-down" style="margin:0"></i></button>').prop("disabled", i === form.fields.length - 1).on("click", function () { move(i, 1); }),
				$('<button type="button" class="k-button" title="Take this question out"><i class="fontAwesomeIcon fas fa-trash-can" style="margin:0"></i></button>').on("click", function () { form.fields.splice(i, 1); drawQuestions(); preview(); }));
			var kind = $('<select aria-label="Kind of answer"></select>');
			$.each(KINDS, function (j, k) { kind.append($("<option></option>").attr("value", k[0]).text(k[1])); });
			kind.val(f.fieldType);
			var req = $('<input type="checkbox" class="k-checkbox">').attr("id", "fwReq" + i).prop("checked", !!f.required).on("change", function () { f.required = this.checked; preview(); });
			row.append(top, $('<div class="fwQuestionKind"></div>').append(kind, req, $('<label class="k-checkbox-label"></label>').attr("for", "fwReq" + i).text("Required")));
			if (CHOICE[f.fieldType]) {
				row.append($('<textarea class="k-textbox" aria-label="Choices, one per line" placeholder="The choices, one per line"></textarea>').val(f.options || "").on("input", function () { f.options = $(this).val(); preview(); }));
			}
			box.append(row);
			kind.kendoDropDownList({ change: function () { f.fieldType = this.value(); if (CHOICE[f.fieldType] && !$.trim(f.options || "")) { f.options = "First choice\nSecond choice"; } drawQuestions(); preview(); } });
		});
	}
	function move(i, by) { var j = i + by; if (j < 0 || j >= form.fields.length) { return; } var f = form.fields.splice(i, 1)[0]; form.fields.splice(j, 0, f); drawQuestions(); preview(); }
	$("#fwAddQuestion").on("click", function () {
		form.fields.push({ webFormFieldId: 0, label: "A new question", fieldType: "text", required: false, placeholder: "", helpText: "", options: "", choiceLimits: {}, showPublic: false });
		drawQuestions(); preview();
	});
	$("#fwTitle").on("input", function () { form.title = $(this).val(); preview(); });
	$("#fwButton").on("input", function () { form.buttonLabel = $(this).val(); preview(); });

	<!--- ---------- Step 3 --->
	function drawAfter() {
		$("#fwThanks").val(form.confirmationMessage || "");
		$("#fwEmail").val(form.notifyEmails || "");
		$("#fwSpam").prop("checked", !!form.requireCaptcha);
		<!--- Sign-up forms (RSVP, potluck, volunteer...): the ready-made ones that can show a public list. --->
		$("#fwListRow").toggle(starter && starter.publicList !== undefined && !!starter.publicList);
		$("#fwList").prop("checked", !!form.publicList);
	}
	$("#fwThanks").on("input", function () { form.confirmationMessage = $(this).val(); });
	$("#fwEmail").on("input", function () { form.notifyEmails = $(this).val(); });
	$("#fwSpam").on("change", function () { form.requireCaptcha = this.checked; preview(); });
	$("#fwList").on("change", function () { form.publicList = this.checked; });

	<!--- ---------- Finish --->
	function alertBox(title, message) { $.when(kendo.ui.ExtAlertDialog.show({ title: title, message: esc(message), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
	function finish() {
		var problem = "";
		if (!$.trim(form.title || "")) { problem = "The form needs a title (Questions step)."; }
		else if (!form.fields.length) { problem = "Add at least one question."; }
		else { $.each(form.fields, function (i, f) {
			if (!$.trim(f.label)) { problem = "Question " + (i + 1) + " needs some words."; return false; }
			if (CHOICE[f.fieldType] && !$.trim(f.options || "")) { problem = "\"" + f.label + "\" needs at least one choice, one per line."; return false; }
		}); }
		if (problem) { alertBox("Please check the form", problem); return; }
		var data = {
			webFormId: 0, title: $.trim(form.title), description: form.description || "", buttonLabel: $.trim(form.buttonLabel || "") || "Send",
			confirmationMessage: $.trim(form.confirmationMessage || ""), confirmationUrl: "", notifyEmails: $.trim(form.notifyEmails || ""),
			offerSubscribe: !!form.offerSubscribe, requireCaptcha: !!form.requireCaptcha, active: true, publicList: !!form.publicList,
			showOnPostIds: [], showOnMode: form.showOnMode || "form",
			fields: $.map(form.fields, function (f) { return { webFormFieldId: 0, label: $.trim(f.label), fieldType: f.fieldType, required: !!f.required, placeholder: f.placeholder || "",
				helpText: f.helpText || "", options: CHOICE[f.fieldType] ? $.map(String(f.options || "").split(/\r?\n/), function (c) { return $.trim(c) || null; }).join("\n") : "", choiceLimits: f.choiceLimits || {}, showPublic: !!f.showPublic }; })
		};
		var buttons = $("#formWizard .gw-buttons .k-button").prop("disabled", true);
		jQuery.ajax({
			type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=saveWebForm", dataType: "json",
			data: { csrfToken: CSRF, formJson: JSON.stringify(data) },
			success: function (r) {
				if (typeof r === "string") { try { r = JSON.parse(r); } catch (e) {} }
				if (r && (r.success === true || r.success === "true")) {
					try { refreshWebFormsWindow(); } catch (e) {}
					$(document).trigger("galaxieWebFormSaved", [{ webFormId: r.webFormId, title: data.title }]);
					<!--- From Insert Form: it lists the new form, picked, ready to put in. --->
					if (typeof refreshInsertWebFormWindow === "function" && $("#insertWebFormWindow").length) { refreshInsertWebFormWindow(r.webFormId); closeWindow(); return; }
					done(r.webFormId, data.title);
				} else {
					buttons.prop("disabled", false);
					alertBox("Could not save", (r && (r.errorMessage || (r.errors && r.errors.join(" ")))) || "The form could not be saved.");
				}
			},
			error: function (jqXHR, textStatus, error) { buttons.prop("disabled", false); if (jqXHR.status === 403) { createLoginWindow(); } else { alertBox("Error while saving", error); } }
		});
	}
	function done(webFormId, title) {
		var box = $('<div class="fwDone"></div>');
		box.append($("<h3></h3>").html('<i class="fontAwesomeIcon fas fa-check" style="color:#37b400"></i> &ldquo;' + esc(title) + '&rdquo; is saved'));
		box.append($("<p></p>").text("To put it in a post or page, open it in its editor and choose Insert, Form."));
		box.append($('<button type="button" class="k-button"><i class="fontAwesomeIcon fas fa-sliders"></i>Fine-tune in the advanced editor</button>').on("click", function () { closeWindow(); createAdminInterfaceWindow(84, webFormId); }));
		box.append($('<button type="button" class="k-button">Close</button>').on("click", closeWindow));
		$("#formWizard").empty().append(box);
	}
	function closeWindow() { var w = win.data("kendoWindow"); if (w) { w.close(); } }

	var wizard = $("#formWizard").galaxieWizard({
		steps: [
			{ title: "What it's for", content: $("#fwStep1"), buttons: ["next"] },
			{ title: "Questions", content: $("#fwStep2"), buttons: ["previous", "next"] },
			{ title: "After it's sent", content: $("#fwStep3"), buttons: ["previous", { name: "done", text: "Finish" }] }
		],
		stepper: { linear: false },
		activate: function (e) { var i = e.step.options.index; if (i === 1) { drawQuestions(); } else if (i === 2) { drawAfter(); } },
		done: function (e) { if (e && e.preventDefault) { e.preventDefault(); } finish(); }
	}).data("galaxieWizard");
	$("#fwSteps").remove();

	<!--- Start on Contact, so the preview shows something straight away. --->
	var first = $.grep(STARTERS, function (s) { return lower(s).key === "contact"; })[0] || STARTERS[0];
	if (first) { pick(lower(first)); }
	drawCards();
	preview();
})();
</script>
