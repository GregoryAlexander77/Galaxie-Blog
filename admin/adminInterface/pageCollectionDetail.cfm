<!--- Page Collection Detail window - opened from the Configure Page Collections grid (createAdminInterfaceWindow(72,
	pageCollectionId), same pattern as postDetail.cfm being opened from the Posts grid). Holds everything that used
	to live in configurePageCollections.cfm's inline expand-in-place row: Hero Image preview/editor, Theme dropdown,
	drag-reorderable member list, Save Order and Delete. Split out into its own window once the flat list became a
	real grid, since a grid's search/filter/sort columns don't have room for this much per-row detail. --->
<cfset pageCollectionId = val(URL.optArgs)>
<cfset allCollectionsForDetail = application.blog.getAllPageCollections()>
<cfset thisCollection = "">
<cfloop array="#allCollectionsForDetail#" index="c">
	<cfif c.pageCollectionId eq pageCollectionId>
		<cfset thisCollection = c>
	</cfif>
</cfloop>
<cfset themeNames = application.blog.getThemeNames()>
<cfset pcMembers = application.blog.getPageCollectionMembers(pageCollectionId)>

<!--- getAllPageCollections() above only carries the plain HeroImageUrl field - a carousel/map hero needs its
own ids, which only getPageCollectionByPageCollectionId() (the Enclosure ORM relationship) returns. Both are
fetched so the hero preview below can show whichever media type is actually set, same as enclosureImageEditor.cfm
already does for the editor window itself. --->
<cfobject component="#application.rendererComponentPath#" name="RendererObj">
<cfset heroEnclosureData = application.blog.getPageCollectionByPageCollectionId(pageCollectionId)>
<!--- Bracket notation with exact case throughout below - a Lucee HQL "SELECT new Map(...)" result is a raw
java.util.HashMap, where dot notation is unreliable (see the case-sensitivity article this project already wrote up). --->
<cfset heroEnclosureMapId = arrayLen(heroEnclosureData) ? heroEnclosureData[1]["EnclosureMapId"] : "">
<cfset heroEnclosureCarouselId = arrayLen(heroEnclosureData) ? heroEnclosureData[1]["EnclosureCarouselId"] : "">
<cfset heroEnclosureMediaType = arrayLen(heroEnclosureData) ? heroEnclosureData[1]["MediaType"] : "">
<cfset heroEnclosureMediaUrl = arrayLen(heroEnclosureData) ? heroEnclosureData[1]["MediaUrl"] : "">

<script>

	$(document).ready(function() {

		<!--- Theme and the member list/sortable only exist in the DOM when this collection actually has members (see the HTML below) - gate the JS the same way, same lesson learned on the Page editor's fields. --->
		<cfif arrayLen(pcMembers)>
		$("#pcTheme-<cfoutput>#pageCollectionId#</cfoutput>").kendoDropDownList({}).data("kendoDropDownList").bind("change", function(e) {
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePageCollectionTheme',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', pageCollectionId: <cfoutput>#pageCollectionId#</cfoutput>, themeRef: this.value() },
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) != true) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save the theme", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		});

		$("#pcMembers-<cfoutput>#pageCollectionId#</cfoutput>").kendoSortable({
			hint: function(element) { return element.clone().addClass("k-state-hover"); },
			placeholder: function(element) { return element.clone().css("visibility", "hidden"); }
		});
		<!--- Go opens that member's own editor (Edit Post window, Id 6). Bound on the list so it works after the list is re-sorted. --->
		$("#pcMembers-<cfoutput>#pageCollectionId#</cfoutput>").on("click", ".pcGoMember", function(e) {
			e.preventDefault();
			e.stopPropagation();
			createAdminInterfaceWindow(6, $(this).closest("li").data("postid"));
		});
		</cfif>

		$("#pcSaveOrder-<cfoutput>#pageCollectionId#</cfoutput>").on('click', function(e) {
			e.preventDefault();
			var orderedIds = $("#pcMembers-<cfoutput>#pageCollectionId#</cfoutput> li").map(function() { return $(this).data("postid"); }).get().join(",");
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePageCollectionMemberOrder',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', pageCollectionId: <cfoutput>#pageCollectionId#</cfoutput>, postIdOrderedList: orderedIds },
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

		<!--- Save Collection sits at the bottom, left of Delete - saves the External URL (the only field on this
		screen that isn't already saved by its own action, e.g. Theme/Member order save immediately on change/Save
		Order, Hero Image saves itself in its own editor window) and closes the window, matching how Delete closes
		it on success too. --->
		$("#pcSaveCollection-<cfoutput>#pageCollectionId#</cfoutput>").on('click', function(e) {
			e.preventDefault();
			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePageCollection',
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					pageCollectionId: <cfoutput>#pageCollectionId#</cfoutput>,
					title: '<cfoutput>#jsStringFormat(thisCollection.title)#</cfoutput>',
					description: '<cfoutput>#jsStringFormat(thisCollection.description)#</cfoutput>',
					<!--- heroImageUrl deliberately NOT sent: this value was baked in when the window opened, so after
					uploading a new hero in the Hero Image Editor (which saves it itself and only reloads the preview
					<img> here) it was stale, and Save Collection wrote the old URL back over the new one. Omitting it
					makes savePageCollection keep the current HeroImageUrl. --->
					externalUrl: $("#pcExternalUrl-<cfoutput>#pageCollectionId#</cfoutput>").val(),
					menuOrder: $("#pcMenuOrder-<cfoutput>#pageCollectionId#</cfoutput>").val(),
					showInMenu: $("#pcShowInMenu-<cfoutput>#pageCollectionId#</cfoutput>").is(":checked")
				},
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						try {
							$("#configurePageCollectionsWindow").data("kendoWindow").refresh();
						} catch (error) {
							<!--- Do nothing - the window probably wasn't open --->
						}
						$('#pageCollectionDetailWindow').kendoWindow('destroy');
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		});

		$("#pcAddPages-<cfoutput>#pageCollectionId#</cfoutput>").on('click', function(e) {
			e.preventDefault();
			createAdminInterfaceWindow(71, <cfoutput>#pageCollectionId#</cfoutput>);
		});

		$("#pcDelete-<cfoutput>#pageCollectionId#</cfoutput>").on('click', function(e) {
			e.preventDefault();
			$.when(kendo.ui.ExtYesNoDialog.show({ title: "Delete this page collection?", message: "This removes '<cfoutput>#jsStringFormat(thisCollection.title)#</cfoutput>'. Its member pages are not affected. This can't be undone.", icon: "k-ext-warning" })).done(function(response) {
				if (response['button'] == 'Yes') {
					jQuery.ajax({
						type: 'post',
						url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deletePageCollection',
						data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', pageCollectionId: <cfoutput>#pageCollectionId#</cfoutput> },
						dataType: "json",
						success: function(response) {
							if (JSON.parse(response.success) == true) {
								try {
									$("#configurePageCollectionsWindow").data("kendoWindow").refresh();
								} catch (error) {
									<!--- Do nothing - the window probably wasn't open --->
								}
								$('#pageCollectionDetailWindow').kendoWindow('destroy');
							} else {
								$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not delete", message: response.errorMessage, icon: "k-ext-warning" }));
							}
						}
					});
				}
			});
		});

	});//...document.ready

</script>

<style>
	<!--- Matches the real post enclosure's own display size exactly (blogContentCss.cfm's .entryImage: max-width:100%,
	height:auto, same drop shadow) instead of a small fixed thumbnail, and the same size used on the Create Page
	Collection screen's hero image widget - so the hero image looks consistent everywhere it's edited. --->
	.pcHeroPreview { max-width: 400px; margin-bottom: 8px; }
	.pcMembers { list-style: none; margin: 6px 0; padding: 0; max-width: 300px; }
	.pcMembers li { display: flex; align-items: center; gap: 8px; padding: 6px 10px; margin-bottom: 4px; border: 1px solid #ddd; border-radius: 4px; cursor: move; }
	.pcMembers li .pcMemberTitle { flex: 1 1 auto; }
	.pcGoMember { flex: 0 0 auto; }
	.pcButtonRow { display: flex; align-items: center; gap: 8px; margin-top: 10px; }
	<!--- Delete Collection now sits in its own alternating k-content/k-alt row, separate from Save Order/Add Pages -
	the row's own background change is the separator, no rule/margin trick needed like before. --->
	.pcDeleteRow { margin-top: 0; }
</style>

<cfif not isStruct(thisCollection)>
	<div style="padding: 30px 20px; text-align: center; color: #888;">
		<p>This page collection no longer exists.</p>
	</div>
<cfelse>
	<cfsilent>
		<!--- Alternating k-content/k-alt row backgrounds, same pattern used throughout the rest of the admin
		(e.g. newPost.cfm) - HtmlUtilsObj is already instantiated once in adminInterface.cfm's shared outer scope. --->
		<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
	</cfsilent>
	<table align="center" class="k-content tableBorder" width="100%" cellpadding="8" cellspacing="0">
		<tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<h2 style="margin-top: 0; margin-bottom: 0;"><cfoutput>#thisCollection.title# Collection</cfoutput></h2>
			</td>
		</tr>
		<!-- Border -->
		<tr height="2px">
			<td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		</tr>
		<cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
		<tr height="2px">
			<td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		</tr>
		<tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<label><b>Hero Image</b> (doubles as this collection's icon):</label><br>
				<div class="entryImage pcHeroPreview" id="pcHeroPreview-<cfoutput>#pageCollectionId#</cfoutput>">
					<cfif len(heroEnclosureCarouselId)>
						<cfoutput>#RendererObj.renderCarouselPreview(heroEnclosureCarouselId, 'postEditor')#</cfoutput>
					<cfelseif len(heroEnclosureMapId)>
						<cfoutput>#RendererObj.renderMapPreview(heroEnclosureMapId, false)#</cfoutput>
					<cfelseif left(heroEnclosureMediaType, 5) eq 'Video' and len(heroEnclosureMediaUrl)>
						<cfoutput>#RendererObj.renderEnclosureVideoPreview(postId="", pageCollectionId=pageCollectionId, mediaUrl=heroEnclosureMediaUrl, mediaId=heroEnclosureData[1]["MediaId"], providerVideoId=heroEnclosureData[1]["ProviderVideoId"], posterUrl=heroEnclosureData[1]["MediaVideoCoverUrl"], videoCaptionsUrl=heroEnclosureData[1]["MediaVideoVttFileUrl"], renderThumbnail=true)#</cfoutput>
					<cfelseif len(thisCollection.heroGradient)>
						<div style="width:100%;height:100%;min-height:150px;background:<cfoutput>#thisCollection.heroGradient#</cfoutput>;display:flex;align-items:center;justify-content:center;box-sizing:border-box;padding:10px;">
							<cfif len(thisCollection.heroOverlayText)>
								<span style="color:<cfoutput>#(len(thisCollection.heroOverlayTextColor) ? thisCollection.heroOverlayTextColor : '##ffffff')#</cfoutput>;font-size:20px;font-weight:bold;text-align:center;"><cfoutput>#thisCollection.heroOverlayText#</cfoutput></span>
							</cfif>
						</div>
					<cfelseif len(thisCollection.heroImageUrl)>
						<!--- Cache-bust: the uploaded file keeps its original name, so re-uploading a hero image with
						the same filename as a prior one (crop the same photo again, re-export from the same source)
						reuses the exact same URL. Without a query string, the browser shows its cached copy of the
						old file and the new hero image never appears to update, even though the server-side file and
						HeroImageUrl are both correct. --->
						<img src="<cfoutput>#thisCollection.heroImageUrl#?v=#getTickCount()#</cfoutput>" alt="">
					<cfelse>
						<img src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png" alt="">
					</cfif>
				</div>
				<button id="pcHeroImage-<cfoutput>#pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button" onclick="javascript:createAdminInterfaceWindow(13,<cfoutput>#pageCollectionId#</cfoutput>,'pageCollection');">Hero Image Editor</button>
			</td>
		</tr>
		<!-- Border -->
		<tr height="2px">
			<td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		</tr>
		<cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
		<tr height="2px">
			<td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		</tr>
		<tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<label for="pcExternalUrl-<cfoutput>#pageCollectionId#</cfoutput>">External URL (makes this a cross-link instead of an internal listing - e.g. linking out to a companion site):</label><br>
				<input type="text" id="pcExternalUrl-<cfoutput>#pageCollectionId#</cfoutput>" value="<cfoutput>#thisCollection.externalUrl#</cfoutput>" placeholder="https://example.com" class="k-textbox" style="width: 320px; margin: 4px 0;">
				<br><label><input type="checkbox" id="pcShowInMenu-<cfoutput>#pageCollectionId#</cfoutput>" <cfif thisCollection.showInMenu>checked</cfif>> Show in the top menu</label>
				<div class="k-form-hint">Lists this collection in the top menu's collections menu (its name is set in Configure Menu). It appears once the collection is live.</div>
				<label for="pcMenuOrder-<cfoutput>#pageCollectionId#</cfoutput>">Menu order (lower numbers appear first):</label><br><input type="number" id="pcMenuOrder-<cfoutput>#pageCollectionId#</cfoutput>" value="<cfoutput>#thisCollection.menuOrder#</cfoutput>" class="k-textbox" style="width: 120px; margin: 4px 0;">
				<p><cfif len(thisCollection.externalUrl)>This collection's link points here instead of its own internal page, and only needs 1 member page to go live (not 2).<cfelse>Leave blank for a normal collection (needs 2+ member pages, links to its own internal listing).</cfif></p>
			</td>
		</tr>
		<!-- Border -->
		<tr height="2px">
			<td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		</tr>
		<cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
		<tr height="2px">
			<td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		</tr>
		<cfif arrayLen(pcMembers)>
			<tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>">
					<label for="pcTheme-<cfoutput>#pageCollectionId#</cfoutput>">Theme (for this collection's own listing view):</label><br>
					<select id="pcTheme-<cfoutput>#pageCollectionId#</cfoutput>" style="width: 220px; margin: 4px 0 10px;">
						<!--- Inherit (ThemeRef=0, same sentinel savePageCollectionTheme's val() already coerces a blank
						choice to) is the default for every collection - it follows whatever theme is currently active
						for the site, rather than locking the collection to one theme that has to be kept in sync by
						hand if the site's theme changes later. --->
						<option value="0" <cfif val(thisCollection.themeRef) eq 0>selected</cfif>>Inherit (site's current theme)</option>
						<cfloop from="1" to="#arrayLen(themeNames)#" index="i">
							<option value="<cfoutput>#themeNames[i]['ThemeId']#</cfoutput>" <cfif thisCollection.themeRef eq themeNames[i]['ThemeId']>selected</cfif>><cfoutput>#themeNames[i]['ThemeName']#</cfoutput></option>
						</cfloop>
					</select><br>

					<label>Members (drag to reorder):</label>
					<ul class="pcMembers k-content" id="pcMembers-<cfoutput>#pageCollectionId#</cfoutput>">
						<cfloop array="#pcMembers#" index="m">
							<li data-postid="<cfoutput>#m.postId#</cfoutput>"><span class="pcMemberTitle">&#9776; <cfoutput>#m.title#</cfoutput></span><button type="button" class="k-button pcGoMember">Go</button></li>
						</cfloop>
					</ul>
					<div class="pcButtonRow">
						<button id="pcSaveOrder-<cfoutput>#pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Save Order</button>
						<button id="pcAddPages-<cfoutput>#pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Add Pages</button>
					</div>
				</td>
			</tr>
		<cfelse>
			<tr>
				<td class="<cfoutput>#thisContentClass#</cfoutput>">
					<cfif session.isMobile>
						<p style="margin-top: 0; color: #888;">No pages assigned yet. Add pages to this collection<cfif len(thisCollection.externalUrl)> (needs 1 to go live, since it's a cross-link)<cfelse> (needs 2 to go live)</cfif>.</p>
						<div class="pcButtonRow">
							<button id="pcAddPages-<cfoutput>#pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Add Pages</button>
						</div>
					<cfelse>
						<!--- Desktop has the room to put the button and its explanation side by side instead of
						stacked - .pcButtonRow is already display:flex/align-items:center, so the message just needs
						to be another child in that same row, after the button. --->
						<div class="pcButtonRow">
							<button id="pcAddPages-<cfoutput>#pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Add Pages</button>
							<p style="margin: 0; color: #888;">No pages assigned yet. Add pages to this collection<cfif len(thisCollection.externalUrl)> (needs 1 to go live, since it's a cross-link)<cfelse> (needs 2 to go live)</cfif>.</p>
						</div>
					</cfif>
				</td>
			</tr>
		</cfif>
		<!-- Border -->
		<tr height="2px">
			<td align="left" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
		</tr>
		<cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
		<tr height="2px">
			<td align="left" valign="top" class="border <cfoutput>#thisContentClass#</cfoutput>"></td>
		</tr>
		<tr>
			<td class="<cfoutput>#thisContentClass#</cfoutput>">
				<div class="pcButtonRow pcDeleteRow">
					<button id="pcSaveCollection-<cfoutput>#pageCollectionId#</cfoutput>" class="k-button k-primary" type="button">Save Collection</button>
					<button id="pcDelete-<cfoutput>#pageCollectionId#</cfoutput>" class="k-button normalFontWeight" type="button">Delete Collection</button>
				</div>
			</td>
		</tr>
	</table>
</cfif>
