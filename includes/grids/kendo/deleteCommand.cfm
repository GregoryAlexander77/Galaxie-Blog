<!--- A Delete button for the admin's Kendo grids (2026-10-24, owner: "it confused me twice now"). Kendo's own "destroy" only marks
a row for deletion; the delete happened when Save was clicked, which was easy to miss (the row vanished, then came back next time).
This asks first - "Delete <name>? This can't be undone." - and deletes at once on Yes. Use it in a grid's columns:
	command: [galaxieGridDeleteCommand("post", ["Title"])]
label names the kind of row; fields lists the columns to name the row by (the first one that has a value); note, optional, replaces
"This can't be undone." for grids whose Delete hides or switches off the row instead (themes, users, posts). Included once per page. --->
<script>
	if (typeof window.galaxieGridDeleteCommand !== "function") {
		window.galaxieGridDeleteCommand = function (label, fields, note) {
			return {
				name: "galaxieDelete",
				text: "Delete",
				iconClass: "k-icon k-i-close",
				click: function (e) {
					e.preventDefault();
					var grid = this;
					var item = grid.dataItem($(e.currentTarget).closest("tr"));
					if (!item) { return; }
					var name = "";
					$.each(fields || [], function (i, field) { if (!name && item[field] !== undefined && item[field] !== null && String(item[field]).length) { name = String(item[field]); } });
					if (name.length > 80) { name = name.slice(0, 80) + "..."; }
					var message = (name ? "Delete &ldquo;" + $("<div/>").text(name).html() + "&rdquo;?" : "Delete this " + label + "?") + " " + (note || "This can't be undone.");
					$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete " + label + "?", message: message, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }))
						.done(function (answer) {
							if (answer && answer.button === "Yes") {
								grid.dataSource.remove(item);
								<!--- Sends the delete now (and any other unsaved change in the grid with it). --->
								grid.dataSource.sync();
							}
						});
				}
			};
		};
	}
</script>
