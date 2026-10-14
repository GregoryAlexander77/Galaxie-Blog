<!--- Form editor (window 84, 2026-10-13), opened from the Forms window (83) with createAdminInterfaceWindow(84, webFormId);
0 makes a new form. Saved by ProxyController.cfc's saveWebForm -> application.webForms.saveForm (common/cfc/WebForms.cfc),
which checks everything again on the server. A field keeps its id while it is edited, so its stored key (FieldName) - and
the submissions already received - stay matched to it when the label changes. --->
<cfset webFormId = val(URL.optArgs)>
<cfset webForm = webFormId gt 0 ? application.webForms.getForm(webFormId = webFormId) : {}>
<cfset isNewWebForm = structIsEmpty(webForm)>
<!--- A new form starts from one of the starter templates (WebForms.cfc's getStarterTemplates): Contact until the owner picks another under "Start from". --->
<cfset webFormStarterTemplates = isNewWebForm ? application.webForms.getStarterTemplates() : []>
<cfset webFormTitleFromSearch = "">
<cfif isNewWebForm>
	<cfset webFormStarter = webFormStarterTemplates[1]>
	<cfloop array="#webFormStarterTemplates#" index="thisStarter">
		<cfif thisStarter.key eq "contact"><cfset webFormStarter = thisStarter></cfif>
	</cfloop>
	<cfset webForm = {
		webFormId: 0, title: webFormStarter.title, alias: "", description: webFormStarter.description, buttonLabel: webFormStarter.buttonLabel,
		confirmationMessage: webFormStarter.confirmationMessage, confirmationUrl: "", notifyEmails: "",
		offerSubscribe: webFormStarter.offerSubscribe, requireCaptcha: application.useCaptcha, active: true,
		fields: webFormStarter.fields
	}>
	<!--- A new form built from the Insert Form window (86) starts with the title typed in its search (otherArgs), whichever template is picked. --->
	<!--- createAdminInterfaceWindow sends the text "undefined" when no otherArgs is given. --->
	<cfif structKeyExists(URL, "otherArgs") and len(trim(URL.otherArgs)) and not listFindNoCase("undefined,null", trim(URL.otherArgs))>
		<cfset webFormTitleFromSearch = left(trim(URL.otherArgs), 125)>
		<cfset webForm.title = webFormTitleFromSearch>
	</cfif>
</cfif>
<cfset webFormFieldTypes = application.webForms.getFieldTypes()>
<!--- What the script below needs: the fields as saved, and the field types for the dropdown. --->
<cfset webFormFieldsForJs = []>
<cfloop array="#webForm.fields#" index="thisField">
	<cfset arrayAppend(webFormFieldsForJs, { "webFormFieldId": thisField.webFormFieldId, "label": thisField.label, "fieldType": thisField.fieldType, "required": thisField.required, "placeholder": thisField.placeholder, "helpText": thisField.helpText, "options": thisField.options, "choiceLimits": structKeyExists(thisField, "choiceLimits") ? thisField.choiceLimits : {} })>
</cfloop>

<style>
	#webFormFieldsBody .webFormFieldRow > td { border-top: 1px solid #e2e2e2; vertical-align: top; padding-top: 8px; }
	.webFormFieldMore { margin-top: 6px; }
	.webFormFieldMore label { display: block; margin-top: 4px; }
</style>

<script>
	$(document).ready(function() {

		var webFormFieldTypes = <cfoutput>#serializeJson(webFormFieldTypes)#</cfoutput>;
		var webFormFieldRows = <cfoutput>#serializeJson(webFormFieldsForJs)#</cfoutput>;
		var choiceTypes = ["select", "radio", "checkboxes"];

		function fieldTypeOptionsHtml(selected) {
			var html = "";
			for (var i = 0; i < webFormFieldTypes.length; i++) {
				var type = webFormFieldTypes[i].type || webFormFieldTypes[i].TYPE;
				var label = webFormFieldTypes[i].label || webFormFieldTypes[i].LABEL;
				html += '<option value="' + type + '"' + (type == selected ? ' selected' : '') + '>' + $('<div/>').text(label).html() + '</option>';
			}
			return html;
		}

		<!--- Shows the Choices box only for the types that use it, and labels it for a consent box. --->
		function refreshFieldRow(row) {
			var type = row.find("select.webFormFieldType").val();
			var isChoice = choiceTypes.indexOf(type) >= 0;
			var isConsent = type == "consent";
			row.find(".webFormFieldOptionsWrap").toggle(isChoice || isConsent);
			row.find(".webFormFieldOptionsLabel").text(isConsent ? "What the person agrees to:" : "Choices (one per line):");
			row.find(".webFormFieldPlaceholderWrap").toggle(!isChoice && !isConsent && type != "date");
			row.find(".webFormFieldLimitWrap").toggle(isChoice);
			renderChoiceLimits(row);
		}

		<!--- Choice limits (2026-10-13): with "Limit how many people can pick each choice" checked, each choice gets a number box;
		an empty box means no limit for that choice. The numbers typed are remembered by choice while the choices are edited. --->
		function readChoiceLimits(row) {
			var limits = $.extend({}, row.data("choiceLimits") || {});
			row.find("input.webFormFieldLimit").each(function() {
				var choice = $(this).data("choice");
				var value = parseInt($(this).val(), 10);
				if (value >= 1) { limits[choice] = value; } else { delete limits[choice]; }
			});
			row.data("choiceLimits", limits);
			return limits;
		}

		function renderChoiceLimits(row) {
			var box = row.find(".webFormFieldLimits");
			var type = row.find("select.webFormFieldType").val();
			var limits = readChoiceLimits(row);
			box.empty();
			if (choiceTypes.indexOf(type) < 0 || !row.find(".webFormFieldLimitOn").is(":checked")) {
				box.hide();
				return;
			}
			var choices = $.grep(row.find(".webFormFieldOptions").val().split("\n"), function(choice) { return $.trim(choice).length > 0; });
			if (!choices.length) {
				box.append($('<div class="k-form-hint"></div>').text("Type the choices above first."));
			}
			var table = $('<table cellpadding="2" cellspacing="0" border="0"></table>');
			$.each(choices, function(i, choice) {
				choice = $.trim(choice);
				var input = $('<input type="number" min="1" step="1" class="k-textbox webFormFieldLimit" style="width: 90px;" placeholder="No limit">').data("choice", choice).val(limits[choice] || "");
				input.attr("aria-label", "Limit for " + choice);
				table.append($('<tr></tr>').append($('<td style="padding-right: 10px;"></td>').text(choice)).append($('<td></td>').append(input)));
			});
			box.append(table).show();
		}

		function fieldRowHtml(field) {
			var row = $('<tr class="webFormFieldRow"></tr>').data("webFormFieldId", field.webFormFieldId || field.WEBFORMFIELDID || 0);
			var main = $('<td></td>');
			main.append($('<input type="text" class="k-textbox webFormFieldLabel" maxlength="255" placeholder="Label, eg. Your name" style="width: 95%;">').val(field.label || field.LABEL || ""));
			var more = $('<div class="webFormFieldMore"></div>');
			more.append($('<span class="webFormFieldPlaceholderWrap"><label>Placeholder (optional):</label></span>').append($('<input type="text" class="k-textbox webFormFieldPlaceholder" maxlength="255" style="width: 95%;">').val(field.placeholder || field.PLACEHOLDER || "")));
			more.append($('<span class="webFormFieldOptionsWrap"><label class="webFormFieldOptionsLabel">Choices (one per line):</label></span>').append($('<textarea class="k-textbox webFormFieldOptions" rows="3" style="width: 95%;"></textarea>').val(field.options || field.OPTIONS || "")));
			var choiceLimits = field.choiceLimits || field.CHOICELIMITS || {};
			row.data("choiceLimits", $.extend({}, choiceLimits));
			var limitWrap = $('<div class="webFormFieldLimitWrap"></div>');
			limitWrap.append($('<label><input type="checkbox" class="k-checkbox webFormFieldLimitOn"> Limit how many people can pick each choice</label>').find("input").prop("checked", !$.isEmptyObject(choiceLimits)).end());
			limitWrap.append('<div class="webFormFieldLimits" style="display: none;"></div>');
			limitWrap.append('<div class="k-form-hint">Visitors see how many spots are left, and a full choice can\'t be picked. Deleting a submission frees its spot.</div>');
			more.append(limitWrap);
			more.append($('<label>Help text (optional):</label>')).append($('<input type="text" class="k-textbox webFormFieldHelpText" maxlength="500" style="width: 95%;">').val(field.helpText || field.HELPTEXT || ""));
			main.append(more);
			row.append(main);
			row.append($('<td></td>').append($('<select class="webFormFieldType" aria-label="Field type" style="width: 100%;"></select>').html(fieldTypeOptionsHtml(field.fieldType || field.FIELDTYPE || "text"))));
			var required = (field.required === true || field.REQUIRED === true || field.required === "true" || field.REQUIRED === "true");
			row.append($('<td align="center"></td>').append($('<input type="checkbox" class="k-checkbox webFormFieldRequired" aria-label="Required">').prop("checked", required)));
			row.append($('<td nowrap="nowrap"></td>')
				.append('<button type="button" class="k-button webFormFieldUp" aria-label="Move up"><span class="k-icon k-i-arrow-60-up"></span></button> ')
				.append('<button type="button" class="k-button webFormFieldDown" aria-label="Move down"><span class="k-icon k-i-arrow-60-down"></span></button> ')
				.append('<button type="button" class="k-button webFormFieldRemove" aria-label="Remove"><span class="k-icon k-i-close"></span></button>'));
			return row;
		}

		<!--- Each row's type is a Kendo DropDownList (in Kendo Core as well as Professional), created once the row is in the page. Kendo copies the
		select's class onto its wrapper, so the select is always found as select.webFormFieldType - a plain .webFormFieldType finds the
		wrapper first, whose value is empty. --->
		function initFieldRow(row) {
			row.find("select.webFormFieldType").kendoDropDownList({
				change: function() { refreshFieldRow(row); }
			});
			refreshFieldRow(row);
		}

		for (var i = 0; i < webFormFieldRows.length; i++) {
			var newRow = fieldRowHtml(webFormFieldRows[i]);
			$("#webFormFieldsBody").append(newRow);
			initFieldRow(newRow);
		}
		<cfif isNewWebForm>
		<!--- Start from: picking a template replaces the fields and the texts below them. The title changes too, unless the owner
		typed their own (or brought one from the Insert Form search). --->
		var webFormStarterTemplates = <cfoutput>#serializeJson(webFormStarterTemplates)#</cfoutput>;
		var webFormTitleFromSearch = <cfoutput>#serializeJson(webFormTitleFromSearch)#</cfoutput>;
		var webFormStarterTitles = $.map(webFormStarterTemplates, function(starter) { return starter.title; });

		function applyStarterTemplate(starter) {
			var currentTitle = $.trim($("#webFormTitle").val());
			if (!webFormTitleFromSearch.length && (!currentTitle.length || webFormStarterTitles.indexOf(currentTitle) >= 0)) {
				$("#webFormTitle").val(starter.title);
			}
			$("#webFormDescription").val(starter.description);
			$("#webFormButtonLabel").val(starter.buttonLabel);
			$("#webFormConfirmationMessage").val(starter.confirmationMessage);
			$("#webFormOfferSubscribe").prop("checked", starter.offerSubscribe === true);
			$("#webFormFieldsBody select.webFormFieldType").each(function() {
				var dropDown = $(this).data("kendoDropDownList");
				if (dropDown) { dropDown.destroy(); }
			});
			$("#webFormFieldsBody").empty();
			for (var i = 0; i < starter.fields.length; i++) {
				var starterRow = fieldRowHtml(starter.fields[i]);
				$("#webFormFieldsBody").append(starterRow);
				initFieldRow(starterRow);
			}
		}

		$("#webFormStarter").kendoDropDownList({
			dataSource: webFormStarterTemplates,
			dataTextField: "name",
			dataValueField: "key",
			value: "contact",
			change: function() {
				var starter = this.dataItem();
				if (starter) { applyStarterTemplate(starter.toJSON ? starter.toJSON() : starter); }
			}
		});
		</cfif>

		$("#webFormFieldsBody").on("click", ".webFormFieldUp", function() { var row = $(this).closest("tr"); row.prev().before(row); });
		$("#webFormFieldsBody").on("click", ".webFormFieldDown", function() { var row = $(this).closest("tr"); row.next().after(row); });
		$("#webFormFieldsBody").on("click", ".webFormFieldRemove", function() { $(this).closest("tr").remove(); });
		$("#webFormFieldsBody").on("change", ".webFormFieldLimitOn", function() { renderChoiceLimits($(this).closest("tr.webFormFieldRow")); });
		$("#webFormFieldsBody").on("input", ".webFormFieldOptions", function() { renderChoiceLimits($(this).closest("tr.webFormFieldRow")); });
		$("#webFormFieldsBody").on("input", ".webFormFieldLimit", function() { readChoiceLimits($(this).closest("tr.webFormFieldRow")); });
		$("#webFormFieldAdd").on("click", function() {
			var row = fieldRowHtml({ fieldType: "text" });
			$("#webFormFieldsBody").append(row);
			initFieldRow(row);
			row.find(".webFormFieldLabel").focus();
		});

		$("#webFormSubmit").on("click", function() {
			var fields = [];
			var problem = "";
			$("#webFormFieldsBody .webFormFieldRow").each(function(index) {
				var label = $.trim($(this).find(".webFormFieldLabel").val());
				var type = $(this).find("select.webFormFieldType").val();
				var options = $.trim($(this).find(".webFormFieldOptions").val());
				if (!label.length) { problem = "Field " + (index + 1) + " needs a label."; return false; }
				if (choiceTypes.indexOf(type) >= 0 && !options.length) { problem = "\"" + label + "\" needs at least one choice, one per line."; return false; }
				fields.push({
					webFormFieldId: $(this).data("webFormFieldId") || 0,
					label: label,
					fieldType: type,
					required: $(this).find(".webFormFieldRequired").is(":checked"),
					placeholder: $.trim($(this).find(".webFormFieldPlaceholder").val()),
					helpText: $.trim($(this).find(".webFormFieldHelpText").val()),
					options: options,
					choiceLimits: $(this).find(".webFormFieldLimitOn").is(":checked") ? readChoiceLimits($(this)) : {}
				});
			});
			if (!problem.length && !$.trim($("#webFormTitle").val()).length) { problem = "The form needs a title."; }
			if (!problem.length && !fields.length) { problem = "The form needs at least one field."; }
			if (problem.length) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Please check the form", message: problem, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			var formData = {
				webFormId: <cfoutput>#webForm.webFormId#</cfoutput>,
				title: $.trim($("#webFormTitle").val()),
				description: $.trim($("#webFormDescription").val()),
				buttonLabel: $.trim($("#webFormButtonLabel").val()),
				confirmationMessage: $.trim($("#webFormConfirmationMessage").val()),
				confirmationUrl: $.trim($("#webFormConfirmationUrl").val()),
				notifyEmails: $.trim($("#webFormNotifyEmails").val()),
				offerSubscribe: $("#webFormOfferSubscribe").is(":checked"),
				requireCaptcha: $("#webFormRequireCaptcha").is(":checked"),
				active: $("#webFormActive").is(":checked"),
				fields: fields
			};

			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the form.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveWebForm',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', formJson: JSON.stringify(formData) },
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (JSON.parse(response.success) == true) {
						try { refreshWebFormsWindow(); } catch (error) {}
						try { refreshInsertWebFormWindow(response.webFormId); } catch (error) {}
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The form was saved.", icon: "k-ext-information" })).done(function() {
							$('#webFormDetailWindow').kendoWindow('destroy');
						});
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR, textStatus, error) {
					kendo.ui.ExtWaitDialog.hide();
					if (jqXHR.status === 403) {
						createLoginWindow();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving the form", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				}
			});
		});
	});//...document.ready
</script>

<cfoutput>
<form id="webFormDetailForm" action="##" method="post" onsubmit="return false;">
<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr>
		<td class="k-header" colspan="2"><b><cfif isNewWebForm>New form<cfelse>#encodeForHtml(webForm.title)#</cfif></b></td>
	</tr>
<cfif isNewWebForm>
	<tr>
		<td width="25%"><label for="webFormStarter">Start from:</label></td>
		<td>
			<input id="webFormStarter" style="width: 220px;">
			<div class="k-form-hint">A ready-made starting point. Change anything below before you save; picking another one replaces the fields.</div>
		</td>
	</tr>
</cfif>
	<tr>
		<td width="25%"><label for="webFormTitle">Title:</label></td>
		<td>
			<input type="text" id="webFormTitle" class="k-textbox" maxlength="125" value="#encodeForHtmlAttribute(webForm.title)#" style="width: 95%;">
			<cfif not isNewWebForm><div class="k-form-hint">Placed in posts as <b>#encodeForHtml(webForm.alias)#</b>. That stays the same if you change the title.</div></cfif>
		</td>
	</tr>
	<tr>
		<td><label for="webFormDescription">Text above the fields:</label></td>
		<td><textarea id="webFormDescription" class="k-textbox" rows="2" maxlength="1000" style="width: 95%;">#encodeForHtml(webForm.description)#</textarea><div class="k-form-hint">Optional.</div></td>
	</tr>
	<tr>
		<td class="k-header" colspan="2"><b>Fields</b></td>
	</tr>
	<tr>
		<td colspan="2">
			<div class="k-form-hint">Shown in this order. Use the arrows to move a field, and the X to remove it.</div>
			<table width="100%" cellpadding="3" cellspacing="0" border="0">
				<thead>
					<tr>
						<th align="left" width="55%">Label</th>
						<th align="left" width="25%">Type</th>
						<th align="center" width="8%">Required</th>
						<th></th>
					</tr>
				</thead>
				<tbody id="webFormFieldsBody"></tbody>
			</table>
			<button id="webFormFieldAdd" type="button" class="k-button">Add a field</button>
		</td>
	</tr>
	<tr>
		<td class="k-header" colspan="2"><b>After sending</b></td>
	</tr>
	<tr>
		<td><label for="webFormButtonLabel">Button text:</label></td>
		<td><input type="text" id="webFormButtonLabel" class="k-textbox" maxlength="50" value="#encodeForHtmlAttribute(webForm.buttonLabel)#" style="width: 220px;"></td>
	</tr>
	<tr>
		<td><label for="webFormConfirmationMessage">Confirmation message:</label></td>
		<td><textarea id="webFormConfirmationMessage" class="k-textbox" rows="2" maxlength="2000" style="width: 95%;">#encodeForHtml(webForm.confirmationMessage)#</textarea></td>
	</tr>
	<tr>
		<td><label for="webFormConfirmationUrl">Or go to this page:</label></td>
		<td><input type="text" id="webFormConfirmationUrl" class="k-textbox" maxlength="500" placeholder="/thank-you" value="#encodeForHtmlAttribute(webForm.confirmationUrl)#" style="width: 95%;"><div class="k-form-hint">Optional. When set, the visitor is sent to this page instead of seeing the message. It can start with http://, https:// or / (a page on this site).</div></td>
	</tr>
	<tr>
		<td><label for="webFormNotifyEmails">Email each submission to:</label></td>
		<td><input type="text" id="webFormNotifyEmails" class="k-textbox" maxlength="1000" placeholder="#encodeForHtmlAttribute(application.BlogDbObj.getBlogEmail())#" value="#encodeForHtmlAttribute(webForm.notifyEmails)#" style="width: 95%;"><div class="k-form-hint">Separate several addresses with commas. Leave it empty to use the blog's own email address.</div></td>
	</tr>
	<tr>
		<td class="k-header" colspan="2"><b>Options</b></td>
	</tr>
	<tr>
		<td colspan="2">
			<label><input type="checkbox" class="k-checkbox" id="webFormOfferSubscribe"<cfif webForm.offerSubscribe> checked</cfif>> Offer "Email me new posts" at the end of the form</label>
			<div class="k-form-hint">Someone who checks it is sent the usual subscriber confirmation email, and only becomes a subscriber after confirming.</div>
			<label><input type="checkbox" class="k-checkbox" id="webFormRequireCaptcha"<cfif webForm.requireCaptcha> checked</cfif>> Ask for the captcha (the text in an image)</label>
			<div class="k-form-hint">Stops simple spam bots. It can't be read with a screen reader, so you may want it off for a form everyone must be able to use; the form has other spam protection either way.</div>
			<label><input type="checkbox" class="k-checkbox" id="webFormActive"<cfif webForm.active> checked</cfif>> Active</label>
			<div class="k-form-hint">An inactive form is not shown in posts and does not accept anything.</div>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="right">
			<button id="webFormSubmit" type="button" class="k-button k-primary">Save</button>
		</td>
	</tr>
</table>
</form>
</cfoutput>
