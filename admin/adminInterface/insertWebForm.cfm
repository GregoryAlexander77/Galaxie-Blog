<!--- Insert Form window (window 86, 2026-10-13), opened by the post editor's Insert Form button and Insert > Form menu item (includes/templates/js/tinyMce.cfm).
Inserts a placeholder for the chosen form into the post: <div class="galaxieWebForm" data-webform="alias">[Form: Title]</div>.
For a form whose sign-up list is public it can also insert the list, <div class="galaxieWebFormList" data-webform="alias">[Sign-up list: Title]</div>.
On the site, common/js/webForms.js replaces them with the real form and list; in a feed or an email they become links to the post.
The dropdown is searchable. When nothing matches, its Build Form button opens the form editor (window 84) with the typed
text as the new form's title; saving there calls refreshInsertWebFormWindow (below), which reloads this window and selects
the new form - the same "not found, add it?" pattern as the Author dropdown on a new post.
Ready-made forms (2026-10-17, owner): the dropdown also lists every starter form not used yet, under "Ready-made forms", so a
form can be placed as it is without the form editor; it's made the first time it's placed (ProxyController.cfc useReadyMadeForm
-> WebForms.cfc useReadyMade). Edit this form opens the form editor (window 84) for the one chosen. --->
<cfset insertableWebForms = []>
<cfloop array="#application.webForms.getForms()#" index="thisWebForm">
	<cfif thisWebForm.active>
		<cfset arrayAppend(insertableWebForms, { "webFormId": thisWebForm.webFormId, "alias": thisWebForm.alias, "title": thisWebForm.title, "publicList": thisWebForm.publicList, "group": "Your forms", "readyMade": "" })>
	</cfif>
</cfloop>
<cfloop array="#application.webForms.getReadyMadeChoices()#" index="thisReadyMade">
	<cfset arrayAppend(insertableWebForms, { "webFormId": 0, "alias": "readyMade:" & thisReadyMade.key, "title": thisReadyMade.name, "publicList": thisReadyMade.publicList, "group": "Ready-made forms", "readyMade": thisReadyMade.key })>
</cfloop>

<script>
	// Called by the form editor (webFormDetail.cfm) after a save, so a form built from here can be placed right away.
	function refreshInsertWebFormWindow(webFormId) {
		try {
			window.insertWebFormSelectId = webFormId;
			$("#insertWebFormWindow").data("kendoWindow").refresh();
		} catch (error) {
			<!--- The window may not be open. --->
		}
	}

	$(document).ready(function() {
		var insertableWebForms = <cfoutput>#serializeJson(insertableWebForms)#</cfoutput>;

		var insertWebFormChoice = $("#insertWebFormChoice").kendoDropDownList({
			<!--- Your forms first, then Ready-made forms. --->
			dataSource: new kendo.data.DataSource({ data: insertableWebForms, group: { field: "group", dir: "desc" } }),
			dataTextField: "title",
			dataValueField: "alias",
			optionLabel: "Select a form...",
			filter: "contains",
			noDataTemplate: $("#insertWebFormNoData").html(),
			change: function() { refreshInsertWhat(); }
		}).data("kendoDropDownList");

		<!--- What to insert: the sign-up list choices only for a form whose list is public (its "Show sign-ups publicly" switch). --->
		function refreshInsertWhat() {
			var item = insertWebFormChoice.dataItem();
			var isPublic = !!(item && insertWebFormChoice.value() && item.publicList);
			$(".insertWebFormWhatRow").toggle(isPublic);
			if (!isPublic) { $("#insertWebFormWhatForm").prop("checked", true); }
		}

		// Select the form just built in the editor, if any.
		if (window.insertWebFormSelectId) {
			var builtId = window.insertWebFormSelectId;
			window.insertWebFormSelectId = 0;
			$.each(insertableWebForms, function(i, item) {
				if (item.webFormId == builtId) { insertWebFormChoice.value(item.alias); }
			});
		}
		refreshInsertWhat();

		<!--- The chosen form, ready to use: a ready-made one is made the first time (useReadyMadeForm), then done(form) gets
		{ webFormId, alias, title, publicList } either way. --->
		function withChosenForm(done) {
			var item = insertWebFormChoice.dataItem();
			if (!insertWebFormChoice.value() || !item) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Choose a form", message: "Please choose the form to place in the post.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			if (!item.readyMade) {
				done({ webFormId: item.webFormId, alias: item.alias, title: item.title, publicList: item.publicList });
				return;
			}
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=useReadyMadeForm",
				data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", key: item.readyMade },
				dataType: "json",
				success: function(response) {
					if (response && response.success) {
						done({ webFormId: response.webFormId, alias: response.alias, title: response.title, publicList: response.publicList });
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Form not ready", message: $("<div/>").text(((response && response.errors) || ["The form could not be set up."]).join(" ")).html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				},
				error: function(jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		}

		$("#insertWebFormSubmit").on("click", function() {
			var editor = tinymce.activeEditor;
			if (!editor) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "No editor", message: "Open the post in the editor first.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			withChosenForm(function(form) {
				var title = $('<div/>').text(form.title).html();
				var alias = $('<div/>').text(form.alias).html().replace(/"/g, "&quot;");
				var what = $("input[name=insertWebFormWhat]:checked").val() || "form";
				var html = "";
				if (what != "list") { html += '<div class="galaxieWebForm" data-webform="' + alias + '">[Form: ' + title + ']</div>'; }
				if (what != "form") { html += '<div class="galaxieWebFormList" data-webform="' + alias + '">[Sign-up list: ' + title + ']</div>'; }
				editor.insertContent(html + '<p>&nbsp;</p>');
				$('#insertWebFormWindow').kendoWindow('destroy');
			});
		});

		<!--- Edit this form: the form editor (window 84) for the chosen form; saving there reloads this window with it chosen. --->
		$("#insertWebFormEdit").on("click", function() {
			withChosenForm(function(form) {
				window.insertWebFormSelectId = form.webFormId;
				createAdminInterfaceWindow(84, form.webFormId);
				try { $("#insertWebFormWindow").data("kendoWindow").refresh(); } catch (error) {}
			});
		});
	});
</script>

<!--- Shown in the dropdown when no form matches the search, or when there are no forms yet. --->
<script id="insertWebFormNoData" type="text/x-kendo-tmpl">
	<div>
		# if (instance.filterInput && instance.filterInput.val()) { #
			Form not found. Do you want to build '#: instance.filterInput.val() #'?
		# } else { #
			There are no forms yet.
		# } #
	</div>
	<br />
	<button class="k-button" onclick="createAdminInterfaceWindow(84, 0, #= kendo.htmlEncode(JSON.stringify(encodeURIComponent(instance.filterInput ? instance.filterInput.val() : ''))) #)">Build Form</button>
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#">Choose a form and click Insert. The ready-made forms work as they are: messages are emailed to you, and the spam check is on. To change a form's questions or wording, click Edit this form. Move or delete it in the post like any other paragraph.</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="insertWebFormChoice">Form:</label></td>
		<td class="#blockClass#"><input id="insertWebFormChoice" style="width: 70%;"> <button id="insertWebFormEdit" type="button" class="k-button">Edit this form</button></td>
	</tr>
	<tr class="blockSpacer insertWebFormWhatRow" style="display: none;"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr class="insertWebFormWhatRow"><td colspan="2" class="#blockClass#">This form shows its sign-ups publicly, so you can place the list too.</td></tr>
	<tr class="blockSpacer insertWebFormWhatRow"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr id="insertWebFormWhatRow" class="insertWebFormWhatRow" style="display: none;">
		<td class="#blockClass#" align="right">Insert:</td>
		<td class="#blockClass#">
			<label><input type="radio" class="k-radio" name="insertWebFormWhat" id="insertWebFormWhatForm" value="form" checked> The form</label><br/>
			<label><input type="radio" class="k-radio" name="insertWebFormWhat" value="formAndList"> The form and its sign-up list</label><br/>
			<label><input type="radio" class="k-radio" name="insertWebFormWhat" value="list"> The sign-up list</label>			
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="insertWebFormSubmit" type="button" class="k-button k-primary">Insert</button></td>
	</tr>
</table>
</cfoutput>
