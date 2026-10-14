<!--- Insert Form window (window 86, 2026-10-13), opened by the post editor's Insert Form button (includes/templates/js/tinyMce.cfm).
Inserts a placeholder for the chosen form into the post: <div class="galaxieWebForm" data-webform="alias">[Form: Title]</div>.
On the site, common/js/webForms.js replaces it with the real form; in a feed or an email it reads as "[Form: Title]". --->
<cfset insertableWebForms = []>
<cfloop array="#application.webForms.getForms()#" index="thisWebForm">
	<cfif thisWebForm.active>
		<cfset arrayAppend(insertableWebForms, { "alias": thisWebForm.alias, "title": thisWebForm.title })>
	</cfif>
</cfloop>

<script>
	$(document).ready(function() {
		var insertableWebForms = <cfoutput>#serializeJson(insertableWebForms)#</cfoutput>;

		$("#insertWebFormChoice").kendoDropDownList({
			dataSource: insertableWebForms,
			dataTextField: "title",
			dataValueField: "alias",
			optionLabel: "Select a form..."
		});

		$("#insertWebFormSubmit").on("click", function() {
			var dropDown = $("#insertWebFormChoice").data("kendoDropDownList");
			var item = dropDown.dataItem();
			if (!dropDown.value() || !item) {
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

<table align="center" class="k-content tableBorder" width="100%" cellpadding="5" cellspacing="0" border="0">
<cfif not arrayLen(insertableWebForms)>
	<tr>
		<td colspan="2">There are no active forms yet. Build one in the admin site under Forms, then come back to place it here.</td>
	</tr>
<cfelse>
	<tr>
		<td width="25%"><label for="insertWebFormChoice">Form:</label></td>
		<td><input id="insertWebFormChoice" style="width: 95%;"></td>
	</tr>
	<tr>
		<td colspan="2">
			<div class="k-form-hint">The post shows "[Form: title]" while you edit it; visitors see the form itself. Move or delete it like any other paragraph.</div>
		</td>
	</tr>
	<tr>
		<td colspan="2" align="right"><button id="insertWebFormSubmit" type="button" class="k-button k-primary">Insert</button></td>
	</tr>
</cfif>
</table>
