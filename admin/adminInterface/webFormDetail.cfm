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
		publicList: webFormStarter.publicList, showOnMode: webFormStarter.showOnMode, showOnPosts: [],
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
	<cfset arrayAppend(webFormFieldsForJs, { "webFormFieldId": thisField.webFormFieldId, "label": thisField.label, "fieldType": thisField.fieldType, "required": thisField.required, "placeholder": thisField.placeholder, "helpText": thisField.helpText, "options": thisField.options, "choiceLimits": structKeyExists(thisField, "choiceLimits") ? thisField.choiceLimits : {}, "showPublic": structKeyExists(thisField, "showPublic") and thisField.showPublic })>
</cfloop>
<!--- On the site (2026-10-13): every post and page for "Show on", and the ones the form is on now. --->
<cfset webFormPostChoices = application.webForms.getPostChoices()>
<cfset webFormShowOnIds = []>
<cfloop array="#webForm.showOnPosts#" index="thisShowOnPost">
	<cfset arrayAppend(webFormShowOnIds, thisShowOnPost.postId)>
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
			<!--- "Show in the public sign-up list": only with the form's privacy switch on, and never for email or phone. --->
			row.find(".webFormFieldPublicWrap").toggle($("#webFormPublicList").is(":checked") && privateTypes.indexOf(type) < 0);
			renderChoiceLimits(row);
		}
		var privateTypes = ["email", "phone"];

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
			var showPublic = (field.showPublic === true || field.SHOWPUBLIC === true || field.showPublic === "true");
			more.append($('<div class="webFormFieldPublicWrap"></div>').append($('<label><input type="checkbox" class="k-checkbox webFormFieldShowPublic"> Show in the public sign-up list</label>').find("input").prop("checked", showPublic).end()));
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
			$("#webFormPublicList").prop("checked", starter.publicList === true);
			$("#webFormShowOnMode").data("kendoDropDownList").value(starter.showOnMode || "form");
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
			refreshPublicList();
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

		<!--- On the site (2026-10-13). "Show sign-ups publicly" is the privacy switch: off, the form's submissions stay private, the
		per-field ticks are hidden and only "Form only" can be chosen. "Show on" lists every post and page; when the one wanted
		doesn't exist yet, its Create Page button makes a draft page with the typed title and selects it. --->
		var webFormShowOnMode = $("#webFormShowOnMode").kendoDropDownList({
			dataSource: [
				{ text: "Form only", value: "form" },
				{ text: "Form and sign-up list", value: "formAndList" },
				{ text: "Sign-up list only", value: "list" }
			],
			dataTextField: "text",
			dataValueField: "value",
			value: <cfoutput>#serializeJson(webForm.showOnMode)#</cfoutput>
		}).data("kendoDropDownList");

		function refreshPublicList() {
			var isPublic = $("#webFormPublicList").is(":checked");
			if (!isPublic) { webFormShowOnMode.value("form"); }
			webFormShowOnMode.enable(isPublic);
			$(".webFormPublicHint").toggle(isPublic);
			$("#webFormFieldsBody .webFormFieldRow").each(function() { refreshFieldRow($(this)); });
		}
		$("#webFormPublicList").on("change", refreshPublicList);

		var webFormShowOn = $("#webFormShowOn").kendoMultiSelect({
			dataSource: <cfoutput>#serializeJson(webFormPostChoices)#</cfoutput>,
			dataTextField: "title",
			dataValueField: "postId",
			value: <cfoutput>#serializeJson(webFormShowOnIds)#</cfoutput>,
			filter: "contains",
			placeholder: "Choose posts or pages...",
			itemTemplate: function(post) { return $("<div/>").text(post.title).html() + (post.released ? "" : " (draft)"); },
			noDataTemplate: $("#webFormShowOnNoData").html()
		}).data("kendoMultiSelect");

		<!--- Called by the Create Page button in the list above. --->
		window.createPageForWebForm = function() {
			var title = $.trim(webFormShowOn.input.val());
			if (!title.length) { return; }
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=createPageForWebForm',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', title: title },
				dataType: "json",
				success: function(response) {
					if (response && JSON.parse(response.success) == true) {
						webFormShowOn.dataSource.add({ postId: response.postId, title: response.title, released: false });
						webFormShowOn.value(webFormShowOn.value().concat([response.postId]));
						webFormShowOn.input.val("");
						webFormShowOn.close();
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Page created", message: "The draft page \"" + $("<div/>").text(response.title).html() + "\" was created and the form will show on it. Fill it in and release it under Pages. Remember to save this form.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not create the page", message: (response && response.errorMessage) || "The page could not be created.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR) {
					if (jqXHR.status === 403) { createLoginWindow(); }
				}
			});
		};
		refreshPublicList();

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
					choiceLimits: $(this).find(".webFormFieldLimitOn").is(":checked") ? readChoiceLimits($(this)) : {},
					showPublic: $(this).find(".webFormFieldShowPublic").is(":checked")
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
				publicList: $("#webFormPublicList").is(":checked"),
				showOnPostIds: $("#webFormShowOn").data("kendoMultiSelect").value(),
				showOnMode: $("#webFormShowOnMode").data("kendoDropDownList").value(),
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
						<!--- Open form dropdowns (booking type, event) add the new form; the one whose Build Form button opened this selects it. --->
						$(document).trigger("galaxieWebFormSaved", [{ webFormId: response.webFormId, title: formData.title }]);
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

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<form id="webFormDetailForm" action="##" method="post" onsubmit="return false;">
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading"><cfif isNewWebForm>New form<cfelse>#encodeForHtml(webForm.title)#</cfif></h4></td></tr>
<cfif isNewWebForm>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Start from a ready-made form and change anything below before you save. Picking another one replaces the fields.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormStarter">Start from:</label></td>
		<td class="#blockClass#"><input id="webFormStarter" style="width: 300px;"></td>
	</tr>
</cfif>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><cfif isNewWebForm>Visitors see the title above the form.<cfelse>Placed in posts as #encodeForHtml(webForm.alias)#; that stays the same if you change the title.</cfif></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormTitle">Title:</label></td>
		<td class="#blockClass#">
			<input type="text" id="webFormTitle" class="k-textbox" maxlength="125" value="#encodeForHtmlAttribute(webForm.title)#" style="width: 95%;">
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Optional.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormDescription">Text above the fields:</label></td>
		<td class="#blockClass#"><textarea id="webFormDescription" class="k-textbox" rows="2" maxlength="1000" style="width: 95%;">#encodeForHtml(webForm.description)#</textarea></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Fields</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Shown in this order. Use the arrows to move a field, and the X to remove it. Changes, including removing a field, aren't saved until you click Save at the bottom; close the window without saving to undo them.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
			<!--- On a phone the columns share the screen's width (fixed layout) instead of growing past it. --->
			<cfif session.isMobile>
			<style>
				<!--- Phones: the move/remove buttons may wrap under each other instead of pushing the table off the screen. --->
				##webFormFieldsBody td { white-space: normal !important; }
			</style>
			</cfif>
			<table width="100%" cellpadding="3" cellspacing="0" border="0"<cfif session.isMobile> style="table-layout: fixed;"</cfif>>
				<thead>
					<tr>
						<th align="left" width="<cfif session.isMobile>42%<cfelse>55%</cfif>">Label</th>
						<th align="left" width="25%">Type</th>
						<th align="center" width="<cfif session.isMobile>13%<cfelse>8%</cfif>"><cfif session.isMobile>Req.<cfelse>Required</cfif></th>
						<th<cfif session.isMobile> width="20%"</cfif>></th>
					</tr>
				</thead>
				<tbody id="webFormFieldsBody"></tbody>
			</table>
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><button id="webFormFieldAdd" type="button" class="k-button">Add a field</button></td></tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">After sending</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormButtonLabel">Button text:</label></td>
		<td class="#blockClass#"><input type="text" id="webFormButtonLabel" class="k-textbox" maxlength="50" value="#encodeForHtmlAttribute(webForm.buttonLabel)#" style="width: 300px;"><span class="k-form-hint">eg. Send, Sign up, Register.</span></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">What visitors see after sending.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormConfirmationMessage">Confirmation message:</label></td>
		<td class="#blockClass#"><textarea id="webFormConfirmationMessage" class="k-textbox" rows="2" maxlength="2000" style="width: 95%;">#encodeForHtml(webForm.confirmationMessage)#</textarea></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Optional: send the visitor to a page instead of showing the message. It can start with http://, https:// or / (a page on this site).</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormConfirmationUrl">Or go to this page:</label></td>
		<td class="#blockClass#"><input type="text" id="webFormConfirmationUrl" class="k-textbox" maxlength="500" placeholder="/thank-you" value="#encodeForHtmlAttribute(webForm.confirmationUrl)#" style="width: 95%;"></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Separate addresses with commas; empty uses the blog's own email.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormNotifyEmails">Email each submission to:</label></td>
		<td class="#blockClass#"><input type="text" id="webFormNotifyEmails" class="k-textbox" maxlength="1000" placeholder="#encodeForHtmlAttribute(application.BlogDbObj.getBlogEmail())#" value="#encodeForHtmlAttribute(webForm.notifyEmails)#" style="width: 95%;"></td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">On the site</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Off: what people send stays private, here in the admin site. On: a sign-up list can be shown on the site with the fields you check ("Show in the public sign-up list"), for example who is bringing what to a potluck. Email and phone fields are never shown.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormPublicList">Show sign-ups publicly:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="webFormPublicList"<cfif webForm.publicList> checked</cfif>></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">The posts and pages this form appears on, below their text. Type to search; if the page doesn't exist yet, you can create it here as a draft. You can also place the form anywhere in a post with the editor's Insert &gt; Form.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormShowOn">Show on:</label></td>
		<td class="#blockClass#"><select id="webFormShowOn" multiple="multiple" style="width: 95%;"></select></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Needs "Show sign-ups publicly" for the list.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormShowOnMode">What shows there:</label></td>
		<td class="#blockClass#"><input id="webFormShowOnMode" style="width: 300px;"></td>
	</tr>
	<tr class="blockSpacer webFormPublicHint"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr id="webFormPublicHint" class="webFormPublicHint"><td colspan="2" class="#blockClass#">The sign-up list updates as people sign up. To leave someone out of it, hide their sign-up under Submissions; it still holds its spot under any choice limits.</td></tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Options</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Offer "Email me new posts" at the end of the form. Someone who checks it is sent the usual subscriber confirmation email, and only becomes a subscriber after confirming.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormOfferSubscribe">Offer subscribing:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="webFormOfferSubscribe"<cfif webForm.offerSubscribe> checked</cfif>></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">The captcha (the text in an image) stops simple spam bots. It can't be read with a screen reader, so you may want it off for a form everyone must be able to use; the form has other spam protection either way.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormRequireCaptcha">Ask for the captcha:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="webFormRequireCaptcha"<cfif webForm.requireCaptcha> checked</cfif>></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">An inactive form isn't shown in posts and doesn't accept anything.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="webFormActive">Active:</label></td>
		<td class="#blockClass#"><input type="checkbox" class="k-checkbox" id="webFormActive"<cfif webForm.active> checked</cfif>></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="webFormSubmit" type="button" class="k-button k-primary">Save</button></td>
	</tr>
</table>
</form>
</cfoutput>

<!--- Shown in the "Show on" list when no post or page matches what was typed: the same "not found, add it?" pattern as the
Author dropdown on a new post. Outside cfoutput, as Kendo's #: # template marks would be read as ColdFusion's. --->
<script id="webFormShowOnNoData" type="text/x-kendo-tmpl">
	<div>
		# if (instance.input && instance.input.val()) { #
			Page not found. Do you want to create '#: instance.input.val() #'?
		# } else { #
			There are no posts or pages yet.
		# } #
	</div>
	<br />
	<button type="button" class="k-button" onclick="createPageForWebForm()">Create Page</button>
</script>
