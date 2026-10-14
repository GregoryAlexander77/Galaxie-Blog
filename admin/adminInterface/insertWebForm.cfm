<!--- Insert Form window (window 86, 2026-10-13), opened by the post editor's Insert Form button and Insert > Form menu item (includes/templates/js/tinyMce.cfm).
Inserts a placeholder for the chosen form into the post: <div class="galaxieWebForm" data-webform="alias">[Form: Title]</div>.
On the site, common/js/webForms.js replaces it with the real form; in a feed or an email it reads as "[Form: Title]".
The dropdown is searchable. When nothing matches, its Build Form button opens the form editor (window 84) with the typed
text as the new form's title; saving there calls refreshInsertWebFormWindow (below), which reloads this window and selects
the new form - the same "not found, add it?" pattern as the Author dropdown on a new post. --->
<cfset insertableWebForms = []>
<cfloop array="#application.webForms.getForms()#" index="thisWebForm">
	<cfif thisWebForm.active>
		<cfset arrayAppend(insertableWebForms, { "webFormId": thisWebForm.webFormId, "alias": thisWebForm.alias, "title": thisWebForm.title })>
	</cfif>
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
			dataSource: insertableWebForms,
			dataTextField: "title",
			dataValueField: "alias",
			optionLabel: "Select a form...",
			filter: "contains",
			noDataTemplate: $("#insertWebFormNoData").html()
		}).data("kendoDropDownList");

		// Select the form just built in the editor, if any.
		if (window.insertWebFormSelectId) {
			var builtId = window.insertWebFormSelectId;
			window.insertWebFormSelectId = 0;
			$.each(insertableWebForms, function(i, item) {
				if (item.webFormId == builtId) { insertWebFormChoice.value(item.alias); }
			});
		}

		$("#insertWebFormSubmit").on("click", function() {
			var item = insertWebFormChoice.dataItem();
			if (!insertWebFormChoice.value() || !item) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Choose a form", message: "Please choose the form to place in the post.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			var title = $('<div/>').text(item.title).html();
			var alias = $('<div/>').text(item.alias).html().replace(/"/g, "&quot;");
			var editor = tinymce.activeEditor;
			if (!editor) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "No editor", message: "Open the post in the editor first.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}
			editor.insertContent('<div class="galaxieWebForm" data-webform="' + alias + '">[Form: ' + title + ']</div><p>&nbsp;</p>');
			$('#insertWebFormWindow').kendoWindow('destroy');
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

<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0" border="0">
	<tr>
		<td width="25%"><label for="insertWebFormChoice">Form:</label></td>
		<td><input id="insertWebFormChoice" style="width: 95%;"></td>
	</tr>
	<tr>
		<td colspan="2">
			<div class="k-form-hint">Type to search your forms, or build a new one from the list. The post shows "[Form: title]" while you edit it; visitors see the form itself. Move or delete it like any other paragraph.</div>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="right"><button id="insertWebFormSubmit" type="button" class="k-button k-primary">Insert</button></td>
	</tr>
</table>
