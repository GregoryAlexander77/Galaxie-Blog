<!--- Notes (2026-10-22, owner: "like the ColdFusion Administrator's notes on a lot of its interfaces"): a private note at the bottom
of a detail window, on the thing it edits. Saves itself as you type (and when you leave the box); shown only in the admin, never on
the site. Stored by common/cfc/AdminNotes.cfc (one AdminNote table for every kind).

Before including it, set:
	notesKind    post, product, order, bookingType, event, form, scene, theme, blogOptions or blogSettings
	notesItemId  the record's id (0 for something not saved yet: the box then waits until it is); 1 for Blog Options and Blog Settings
	notesLayout  "rows" (default): table rows for an adminBlocks table, continuing the window's alternating rows from its blockClass
	             (needs blockClass and HtmlUtilsObj, like the rest of the window); "div": a block of its own, for windows built otherwise.
	notesDomId   optional: the box's id, for a window that switches records (the Themes window): it then calls
	             galaxieAdminNoteBoxes[notesDomId].setItem(id) and the box loads that record's note. --->
<cfparam name="notesLayout" default="rows">
<cfparam name="notesDomId" default="">
<cfset notesItemId = val(notesItemId)>
<cfset notesData = application.blog.getAdminNotes().getNote(notesKind, notesItemId)>
<cfif not len(notesDomId)><cfset notesDomId = "adminNotes" & replace(createUUID(), "-", "", "all")></cfif>
<cfif notesLayout eq "rows">
	<!--- The next shade in the window's alternating rows. --->
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<cfset notesClass = blockClass>
<cfelse>
	<cfset notesClass = "k-alt">
</cfif>
<cfsavecontent variable="notesBody"><cfoutput>
	<h4 class="adminBlockHeading">Notes</h4>
	<div class="k-form-hint" style="margin: 0 0 6px 0;">Private: only shown here in the admin, never on your site. Saved as you type.</div>
	<textarea id="#notesDomId#" class="k-textbox" rows="4" style="width: 100%; box-sizing: border-box;<cfif notesItemId lte 0> display: none;</cfif>" maxlength="20000" placeholder="Reminders, sources, why it's set up this way...">#encodeForHtml(notesData.note)#</textarea>
	<div id="#notesDomId#Status" class="k-form-hint" style="margin-top: 4px;"><cfif notesItemId lte 0>Save this first, then you can add notes.<cfelseif len(notesData.updated)>Last changed #encodeForHtml(notesData.updated)#<cfif len(notesData.updatedBy)> by #encodeForHtml(notesData.updatedBy)#</cfif>.</cfif></div>
</cfoutput></cfsavecontent>
<cfoutput>
<cfif notesLayout eq "rows">
	<tr class="blockSpacer"><td colspan="2" class="border #notesClass#"></td></tr>
	<tr><td colspan="2" class="#notesClass#">#notesBody#</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="#notesClass#"></td></tr>
<cfelse>
	<div class="#notesClass#" style="padding: 10px 12px; margin-top: 12px; border-top: 1px solid rgba(128,128,128,.35);">#notesBody#</div>
</cfif>
</cfoutput>
<script>
$(function () {
	var domId = "<cfoutput>#jsStringFormat(notesDomId)#</cfoutput>", kind = "<cfoutput>#jsStringFormat(notesKind)#</cfoutput>", itemId = <cfoutput>#notesItemId#</cfoutput>;
	var box = $("#" + domId), status = $("#" + domId + "Status"), saved = box.val(), timer = null;
	var proxy = "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=";
	function parse(response) { if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} } return response; }
	function changed(r) { return r.updated ? "Last changed " + r.updated + (r.updatedBy ? " by " + r.updatedBy : "") + "." : ""; }
	function save() {
		clearTimeout(timer);
		var text = box.val();
		if (itemId <= 0 || text === saved) { return; }
		status.text("Saving...");
		jQuery.ajax({
			type: "post", url: proxy + "saveAdminNote", dataType: "json",
			data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", kind: kind, itemId: itemId, note: text },
			success: function (response) {
				response = parse(response);
				if (!response || !response.success) { status.text((response && response.errorMessage) || "The note could not be saved."); return; }
				saved = text;
				status.text(text.length ? "Saved. " + changed(response) : "Note removed.");
			},
			error: function () { status.text("The note could not be saved. Check your connection and type again."); }
		});
	}
	box.on("input", function () { clearTimeout(timer); status.text("Not saved yet..."); timer = setTimeout(save, 900); }).on("blur", save);
	<!--- For a window that switches records: save what's typed, then show the other record's note. --->
	window.galaxieAdminNoteBoxes = window.galaxieAdminNoteBoxes || {};
	window.galaxieAdminNoteBoxes[domId] = {
		setItem: function (id) {
			save();
			itemId = parseInt(id, 10) || 0;
			if (itemId <= 0) { box.hide().val(""); saved = ""; status.text("Save this first, then you can add notes."); return; }
			box.show().prop("disabled", true);
			status.text("");
			jQuery.ajax({
				type: "post", url: proxy + "getAdminNote", dataType: "json", data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", kind: kind, itemId: itemId },
				success: function (response) {
					response = parse(response) || {};
					box.val(response.note || "").prop("disabled", false);
					saved = box.val();
					status.text(changed(response));
				},
				error: function () { box.prop("disabled", false); status.text("The note could not be loaded."); }
			});
		}
	};
});
</script>
<!--- Cleared, so a later include in the same request starts from its own settings. --->
<cfset structDelete(variables, "notesLayout")><cfset structDelete(variables, "notesDomId")>
