<!--- SUPERSEDED 2026-09-23, no longer included anywhere - window id 68 now renders includes/grids/kendo(or jsGrid)/pageCollections.cfm (a real searchable/sortable/filterable grid) instead of this flat list, with the per-collection Hero Image/Theme/member-order editing that used to live in this file's inline expand-in-place row moved to its own window, admin/adminInterface/pageCollectionDetail.cfm (window id 72). Left in place rather than deleted, matching this codebase's convention for superseded-but-possibly-still-instructive files (see e.g. includes/templates/pageCollectionContentHtml.cfm). --->
<!--- Configure Page Collections window - the management hub for every Page Collection: list + member count + status, click a row to expand it in place (not a separate popup window, per the design doc) showing its Theme and a drag-reorderable member list. Does not duplicate Collection creation, which stays owned by the New chooser. --->
<cfset allCollections = application.blog.getAllPageCollections()>
<cfset themeNames = application.blog.getThemeNames()>
<!--- Computed once here and reused by both the script loop below (which needs to know whether to wire up the Theme dropdown at all) and the HTML loop further down, instead of querying it twice per collection. --->
<cfset membersByCollection = {}>
<cfloop array="#allCollections#" index="pcForMembers">
	<cfset membersByCollection[pcForMembers.pageCollectionId] = application.blog.getPageCollectionMembers(pcForMembers.pageCollectionId)>
</cfloop>

<script>

	$(document).ready(function() {

		<!--- One-time dissolve notice, shown when the admin next opens the admin UI (see doc/pageCollectionsDesign - "pops up only once", batched if more than one is pending). This window is as good a place as any first-admin-visit hook, but any admin window would do; wiring it here since this is one of the two most likely first stops after Page Collections changed something. --->
		jQuery.ajax({
			type: 'post',
			url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getAndDismissPendingDissolveNotices',
			data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>' },
			dataType: "json",
			success: function(response) {
				if (JSON.parse(response.hasNotice) == true) {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "A page collection was removed", message: response.message, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				}
			}
		});

		$(".pcRow").on('click', function() {
			$("#pcDetails-" + $(this).data("pcid")).toggle();
		});

		<cfloop array="#allCollections#" index="pc">
		<cfset pcId = pc.pageCollectionId>
		<!--- Theme and the member list/sortable only exist in the DOM when this collection actually has members (see the HTML below) - gate the JS the same way, same lesson learned on the Page editor's fields. --->
		<cfif arrayLen(membersByCollection[pcId])>
		$("#pcTheme-<cfoutput>#pcId#</cfoutput>").kendoDropDownList({}).data("kendoDropDownList").bind("change", function(e) {
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePageCollectionTheme',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', pageCollectionId: <cfoutput>#pcId#</cfoutput>, themeRef: this.value() },
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) != true) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save the theme", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		});

		$("#pcMembers-<cfoutput>#pcId#</cfoutput>").kendoSortable({
			hint: function(element) { return element.clone().addClass("k-state-hover"); },
			placeholder: function(element) { return element.clone().css("visibility", "hidden"); }
		});
		</cfif>

		$("#pcSaveOrder-<cfoutput>#pcId#</cfoutput>").on('click', function(e) {
			e.preventDefault();
			var orderedIds = $("#pcMembers-<cfoutput>#pcId#</cfoutput> li").map(function() { return $(this).data("postid"); }).get().join(",");
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePageCollectionMemberOrder',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', pageCollectionId: <cfoutput>#pcId#</cfoutput>, postIdOrderedList: orderedIds },
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The order was saved.", icon: "k-ext-information" }));
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save the order", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		});

		$("#pcAddPages-<cfoutput>#pcId#</cfoutput>").on('click', function(e) {
			e.preventDefault();
			createAdminInterfaceWindow(71, <cfoutput>#pcId#</cfoutput>);
		});

		$("#pcDelete-<cfoutput>#pcId#</cfoutput>").on('click', function(e) {
			e.preventDefault();
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete this page collection?", message: "This removes '<cfoutput>#jsStringFormat(pc.title)#</cfoutput>'. Its member pages are not affected. This can't be undone.", icon: "k-ext-warning" })).done(function(response) {
				if (response['button'] == 'Yes') {
					jQuery.ajax({
						type: 'post',
						url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deletePageCollection',
						data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', pageCollectionId: <cfoutput>#pcId#</cfoutput> },
						dataType: "json",
						success: function(response) {
							if (JSON.parse(response.success) == true) {
								$("#pcListItem-<cfoutput>#pcId#</cfoutput>").remove();
							} else {
								$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not delete", message: response.errorMessage, icon: "k-ext-warning" }));
							}
						}
					});
				}
			});
		});
		</cfloop>

	});//...document.ready

</script>

<style>
	.pcList { list-style: none; margin: 0; padding: 0; }
	.pcRow { cursor: pointer; padding: 8px 10px; border-bottom: 1px solid #ddd; display: flex; align-items: center; gap: 8px; }
	.pcRow img.pcThumb { width: 32px; height: 32px; object-fit: cover; border-radius: 4px; background: #eee; flex-shrink: 0; }
	.pcRow .pcTitle { font-weight: 600; }
	.pcRow .pcCount { color: #888; font-size: 12px; }
	.pcStatus { font-size: 11px; padding: 2px 8px; border-radius: 10px; border-style: solid; border-width: 1px; }
	.pcDetails { display: none; padding: 10px 10px 14px 52px; background: #fafafa; border-bottom: 1px solid #ddd; }
	.pcMembers { list-style: none; margin: 6px 0; padding: 0; max-width: 300px; }
	.pcMembers li { padding: 6px 10px; margin-bottom: 4px; background: #fff; border: 1px solid #ddd; border-radius: 4px; cursor: move; }
	.pcButtonRow { display: flex; align-items: center; gap: 8px; margin-top: 10px; }
	.pcHeroPreview { display: block; width: 260px; height: 150px; object-fit: contain; border: 1px solid #ddd; border-radius: 4px; background: #fff; margin-bottom: 8px; }
	<!--- Delete Collection sits where a submit/primary button normally would, so it's pulled visually apart from
	the row above (Save Order / Add Pages) with a rule plus extra top margin, rather than sharing that row - an
	accidental click here isn't reversible. --->
	.pcDeleteSeparator { border: none; border-top: 1px solid #ddd; margin: 16px 0 0 0; }
	.pcDeleteRow { margin-top: 10px; }
</style>

<cfif arrayLen(allCollections) eq 0>
	<div style="padding: 30px 20px; text-align: center; color: #888;">
		<p>No page collections yet.</p>
		<button class="k-button k-primary normalFontWeight" type="button" onclick="createAdminInterfaceWindow(24,'newPageCollection')">+ New Page Collection</button>
	</div>
<cfelse>
	<ul class="pcList">
	<cfloop array="#allCollections#" index="pc">
		<li id="pcListItem-<cfoutput>#pc.pageCollectionId#</cfoutput>">
			<div class="pcRow" data-pcid="<cfoutput>#pc.pageCollectionId#</cfoutput>">
				<cfif len(pc.heroImageUrl)>
					<img class="pcThumb" src="<cfoutput>#pc.heroImageUrl#</cfoutput>" alt="">
				<cfelse>
					<img class="pcThumb" src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png" alt="">
				</cfif>
				<span class="pcTitle"><cfoutput>#pc.title#</cfoutput></span>
				<span class="pcCount"><cfoutput>#pc.memberCount#</cfoutput> page<cfif pc.memberCount neq 1>s</cfif></span>
				<cfif pc.visible>
					<span class="pcStatus k-state-success">Live</span>
				<cfelse>
					<span class="pcStatus k-state-warning">Needs <cfoutput>#(2 - pc.memberCount)#</cfoutput> more page<cfif (2 - pc.memberCount) neq 1>s</cfif></span>
				</cfif>
			</div>
			<div class="pcDetails" id="pcDetails-<cfoutput>#pc.pageCollectionId#</cfoutput>">
				<label>Hero Image (doubles as this collection's icon):</label><br>
				<cfif len(pc.heroImageUrl)>
					<img class="pcHeroPreview" src="<cfoutput>#pc.heroImageUrl#</cfoutput>" alt="">
				<cfelse>
					<img class="pcHeroPreview" src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png" alt="">
				</cfif>
				<button id="pcHeroImage-<cfoutput>#pc.pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button" onclick="javascript:createAdminInterfaceWindow(35,<cfoutput>#pc.pageCollectionId#</cfoutput>,'pageCollectionHero','<cfoutput>#pc.heroImageUrl#</cfoutput>');">Change Hero Image</button>

				<!-- Border -->
				<hr style="margin: 14px 0; border: none; border-top: 1px solid #ddd;">

				<cfset pcMembers = membersByCollection[pc.pageCollectionId]>
				<cfif arrayLen(pcMembers)>
					<!--- Theme only makes sense once there's actually something to render in the listing view it governs - no point offering it for an empty collection. --->
					<label for="pcTheme-<cfoutput>#pc.pageCollectionId#</cfoutput>">Theme (for this collection's own listing view):</label><br>
					<select id="pcTheme-<cfoutput>#pc.pageCollectionId#</cfoutput>" style="width: 220px; margin: 4px 0 10px;">
						<cfloop from="1" to="#arrayLen(themeNames)#" index="i">
							<option value="<cfoutput>#themeNames[i]['ThemeId']#</cfoutput>" <cfif pc.themeRef eq themeNames[i]['ThemeId']>selected</cfif>><cfoutput>#themeNames[i]['ThemeName']#</cfoutput></option>
						</cfloop>
					</select><br>

					<label>Members (drag to reorder):</label>
					<ul class="pcMembers" id="pcMembers-<cfoutput>#pc.pageCollectionId#</cfoutput>">
						<cfloop array="#pcMembers#" index="m">
							<li data-postid="<cfoutput>#m.postId#</cfoutput>">&#9776; <cfoutput>#m.title#</cfoutput></li>
						</cfloop>
					</ul>
					<div class="pcButtonRow">
						<button id="pcSaveOrder-<cfoutput>#pc.pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Save Order</button>
					</div>
					<hr class="pcDeleteSeparator">
					<div class="pcButtonRow pcDeleteRow">
						<button id="pcDelete-<cfoutput>#pc.pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Delete Collection</button>
					</div>
				<cfelse>
					<p style="color: #888;">No pages assigned yet. Add pages to this collection.</p>
					<div class="pcButtonRow">
						<button id="pcAddPages-<cfoutput>#pc.pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Add Pages</button>
					</div>
					<hr class="pcDeleteSeparator">
					<div class="pcButtonRow pcDeleteRow">
						<button id="pcDelete-<cfoutput>#pc.pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Delete Collection</button>
					</div>
				</cfif>
			</div>
		</li>
	</cfloop>
	</ul>
</cfif>
