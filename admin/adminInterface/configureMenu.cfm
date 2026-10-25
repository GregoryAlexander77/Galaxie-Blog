<!--- Configure Menu window (window 82, 2026-10-10, Galaxie Blog 4.8). Sets the parts of the top menu the blog owner
controls without replacing the whole menu: their own links in the Menu dropdown (eg. links between their sites), the name
of the collections menu, and the name of the single dropdown that combines Categories and Collections on mobile. Which
collections appear is set per collection (Show in the top menu, in the Page Collection editor). Everything else in the menu
stays automatic. Saved by ProxyController.cfc's saveMenuSettings; drawn by includes/templates/content/header/navigationMenu.cfm. --->
<cfset menuLinks = application.blog.getMenuLinks()>
<cfset menuLabels = application.blog.getMenuLabels()>
<cfset menuCollectionsForHint = application.blog.getMenuCollections()>
<!--- The saved labels themselves (blank means "use the default"), so the boxes show what was typed, not the default. --->
<cfset savedCollectionsLabel = isNull(application.BlogOptionDbObj.getCollectionsMenuLabel()) ? "" : application.BlogOptionDbObj.getCollectionsMenuLabel()>
<cfset savedMobileLabel = isNull(application.BlogOptionDbObj.getMobileMenuLabel()) ? "" : application.BlogOptionDbObj.getMobileMenuLabel()>
<cfset savedCombined = application.blog.getMenuLabels().combined>

<script>
	$(document).ready(function() {

		<!--- The links, as saved. Each row of the table below is built from one of these. --->
		var menuLinkRows = <cfoutput>#serializeJson(menuLinks)#</cfoutput>;

		function menuLinkRowHtml(link) {
			var row = $('<tr class="menuLinkRow"></tr>');
			row.append($('<td></td>').append($('<input type="text" class="k-textbox menuLinkLabel" maxlength="125" placeholder="Label" style="width: 95%;">').val(link.label || link.LABEL || "")));
			row.append($('<td></td>').append($('<input type="text" class="k-textbox menuLinkUrl" maxlength="500" placeholder="https://example.com" style="width: 95%;">').val(link.linkUrl || link.LINKURL || "")));
			var newWindow = (link.newWindow === true || link.NEWWINDOW === true || link.newWindow === "true" || link.NEWWINDOW === "true");
			row.append($('<td align="center"></td>').append($('<input type="checkbox" class="k-checkbox menuLinkNewWindow" aria-label="Open in a new tab">').prop("checked", newWindow)));
			row.append($('<td nowrap="nowrap"></td>')
				.append('<button type="button" class="k-button menuLinkUp" aria-label="Move up"><span class="k-icon k-i-arrow-60-up"></span></button> ')
				.append('<button type="button" class="k-button menuLinkDown" aria-label="Move down"><span class="k-icon k-i-arrow-60-down"></span></button> ')
				.append('<button type="button" class="k-button menuLinkRemove" aria-label="Remove"><span class="k-icon k-i-close"></span></button>'));
			return row;
		}

		function refreshEmptyMessage() {
			$("#menuLinksEmpty").toggle($("#menuLinksBody .menuLinkRow").length === 0);
		}

		for (var i = 0; i < menuLinkRows.length; i++) {
			$("#menuLinksBody").append(menuLinkRowHtml(menuLinkRows[i]));
		}
		refreshEmptyMessage();

		$("#menuLinkAdd").on("click", function() {
			$("#menuLinksBody").append(menuLinkRowHtml({}));
			refreshEmptyMessage();
			$("#menuLinksBody .menuLinkRow:last .menuLinkLabel").focus();
		});
		$("#menuLinksBody").on("click", ".menuLinkUp", function() {
			var row = $(this).closest("tr"); row.prev(".menuLinkRow").before(row);
		});
		$("#menuLinksBody").on("click", ".menuLinkDown", function() {
			var row = $(this).closest("tr"); row.next(".menuLinkRow").after(row);
		});
		$("#menuLinksBody").on("click", ".menuLinkRemove", function() {
			$(this).closest("tr").remove(); refreshEmptyMessage();
		});

		$("#configureMenuSubmit").on("click", function(e) {
			e.preventDefault();
			var links = [];
			var problem = "";
			$("#menuLinksBody .menuLinkRow").each(function() {
				var label = $.trim($(this).find(".menuLinkLabel").val());
				var linkUrl = $.trim($(this).find(".menuLinkUrl").val());
				<!--- A completely empty row is simply dropped. --->
				if (!label.length && !linkUrl.length) { return; }
				if (!label.length || !linkUrl.length) { problem = "Every link needs both a label and an address."; return false; }
				if (!/^(https?:\/\/|\/|mailto:)/i.test(linkUrl)) { problem = "The address for \"" + label + "\" must start with http://, https://, / or mailto:."; return false; }
				links.push({ label: label, linkUrl: linkUrl, newWindow: $(this).find(".menuLinkNewWindow").is(":checked") });
			});
			if (problem.length) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Please check the links", message: problem, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				return;
			}

			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the menu.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveMenuSettings',
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					linksJson: JSON.stringify(links),
					collectionsMenuLabel: $("#collectionsMenuLabel").val(),
					mobileMenuLabel: $("#mobileMenuLabel").val(),
					combineMenus: $("#combineMenus").is(":checked")
				},
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (JSON.parse(response.success) == true) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The menu was saved. Reload a page to see it.", icon: "k-ext-information" })).done(function() {
							$('#configureMenuWindow').kendoWindow('destroy');
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
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveMenuSettings function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				}
			});
		});

	});//...document.ready
</script>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<form id="configureMenuForm" action="##" method="post">
<table align="center" class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
	<colgroup><col style="width: 20%"><col></colgroup>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Menu links</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">Your own links in the Menu dropdown, such as links to your other sites. Your blog's own link always comes first and Contact always comes last. An address can start with http://, https://, / (a page on this site) or mailto:.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">
			<table width="100%" cellpadding="3" cellspacing="0" border="0">
				<thead>
					<tr>
						<th align="left" width="35%">Label</th>
						<th align="left" width="40%">Address</th>
						<th align="center" width="10%">New tab</th>
						<th></th>
					</tr>
				</thead>
				<tbody id="menuLinksBody"></tbody>
			</table>
			<div id="menuLinksEmpty" class="k-form-hint">No links yet.</div>
			<button id="menuLinkAdd" type="button" class="k-button">Add a link</button>
			<div class="k-form-hint">Use the arrows to change the order.</div>
		</td>
	</tr>

	<tr class="blockSpacer"><td colspan="2" class="#blockClass#"></td></tr>
	<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Menu names</h4></td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">The collections menu lists the collections marked Show in the top menu<cfif arrayLen(menuCollectionsForHint)> (#arrayLen(menuCollectionsForHint)# now)<cfelse> (none yet - mark them in Page Collections)</cfif>. Hidden when there are none.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Leave blank for "Collections".</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="collectionsMenuLabel">Collections menu:</label></td>
		<td class="#blockClass#">
			<input type="text" id="collectionsMenuLabel" class="k-textbox" maxlength="50" placeholder="Collections" value="#encodeForHtmlAttribute(savedCollectionsLabel)#" style="width: 220px;">
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td colspan="2" class="#blockClass#">Mobile screens have less room, so Categories and the collections menu are combined into one dropdown with this name. Tick the box below to use the one menu on computers too.</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr><td colspan="2" class="#blockClass#">Leave blank for "Explore".</td></tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#" align="right"><label for="mobileMenuLabel">One-menu name:</label></td>
		<td class="#blockClass#">
			<input type="text" id="mobileMenuLabel" class="k-textbox" maxlength="50" placeholder="Explore" value="#encodeForHtmlAttribute(savedMobileLabel)#" style="width: 220px;">
		</td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<!--- One menu on computers too (2026-10-24, owner). --->
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><label><input type="checkbox" id="combineMenus" class="k-checkbox"<cfif savedCombined> checked</cfif>> Use this one menu on computers too, instead of Categories and the collections menu side by side</label></td>
	</tr>
	<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
	<tr>
		<td class="#blockClass#"></td>
		<td class="#blockClass#"><button id="configureMenuSubmit" name="configureMenuSubmit" class="k-button k-primary" type="button">Save</button></td>
	</tr>
</table>
</form>
</cfoutput>
