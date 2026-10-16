/*
Galaxie Blog admin: "not found? add it" buttons in dropdowns (2026-10-16). Loaded with the other admin scripts in includes/templates/head.cfm.

A dropdown that lists things the owner creates (forms, locations, booking types, categories) has a noDataTemplate with a button:
- For a free-text combo box (eg. the booking type Category), the button calls galaxieAddComboText(id), which adds the typed text
  to the list and selects it.
- For anything with its own editor window, the button calls galaxieAddRequest(id) and opens that editor with the typed text
  (createAdminInterfaceWindow(windowId, 0, typedText)). After a save the editor triggers an event (eg. galaxieWebFormSaved);
  the window holding the dropdown listens for it and calls galaxieAddToDropDown, which adds the new item to the open dropdown
  and selects it in the dropdown that asked. Nothing else in that window is reloaded, so unsaved changes are kept.
*/

var galaxieAddRequestedBy = "";

// Remembers which dropdown asked for a new item, so only that one selects it after the save.
function galaxieAddRequest(dropDownId) {
	galaxieAddRequestedBy = dropDownId;
}

// The text typed in a combo box's search, or in a dropdown list's filter.
function galaxieTypedText(instance) {
	if (instance.filterInput && instance.filterInput.val()) {
		return $.trim(instance.filterInput.val());
	}
	return instance.input && instance.input.val ? $.trim(instance.input.val()) : "";
}

// Adds a saved item to an open dropdown list (or combo box) unless it is already there, and selects it in the dropdown that asked.
function galaxieAddToDropDown(dropDownId, item, valueField) {
	var element = $("#" + dropDownId);
	var widget = element.data("kendoDropDownList") || element.data("kendoComboBox");
	if (!widget) {
		return;
	}
	var found = false;
	$.each(widget.dataSource.data(), function(i, row) {
		if (String(row[valueField]) === String(item[valueField])) {
			found = true;
		}
	});
	if (!found) {
		widget.dataSource.add(item);
	}
	if (galaxieAddRequestedBy === dropDownId) {
		galaxieAddRequestedBy = "";
		widget.dataSource.filter([]);
		widget.value(item[valueField]);
		widget.trigger("change");
	}
}

// Free-text combo box (a list of plain strings): adds the typed text to the list and selects it.
function galaxieAddComboText(comboId) {
	var combo = $("#" + comboId).data("kendoComboBox");
	if (!combo) {
		return;
	}
	var text = $.trim(combo.input.val());
	if (!text.length) {
		return;
	}
	var items = $.map(combo.dataSource.data(), function(value) { return value; });
	if ($.inArray(text, items) === -1) {
		items.push(text);
		items.sort(function(a, b) { return String(a).localeCompare(String(b)); });
	}
	combo.setDataSource(items);
	combo.value(text);
	combo.close();
}
