<!--- Configure Homepage window - a stand-alone, narrow icon/window rather than a Blog Options panel (see doc/pageCollectionsDesign for the design). Shows the current homepage state in plain language, plus three INDEPENDENT, additive toggles, stacked in a fixed order when live: Featured Pages, then Featured Collections, then recent Blog Posts. EXCEPTION: Pages on with exactly one page selected makes that Page's own full content the entire homepage instead of a card - see index.cfm's pageTypeId 9 vs 24 split. --->
<cfset homepageSettings = application.blog.getHomepageSettings()>
<cfset allPages = application.blog.getPagesForDropdown()>
<cfset eligibleCollections = application.blog.getEligiblePageCollectionsForHomepage()>

<script>

	$(document).ready(function() {

		<!--- A plain <select multiple> bound to a Kendo MultiSelect does NOT preserve click order in its own value() once the user starts selecting/deselecting - it re-renders tags in the underlying dataSource's order instead. Track selection order ourselves via the select/deselect events and use this array (not .value()) when submitting. Seeded from the server-rendered order (homepageSettings.pageIdList/collectionIdList), which is already the saved selection order. --->
		var pageSelectionOrder = [<cfloop list="#homepageSettings.pageIdList#" index="tid"><cfoutput>"#tid#",</cfoutput></cfloop>];
		var collectionSelectionOrder = [<cfloop list="#homepageSettings.collectionIdList#" index="tid"><cfoutput>"#tid#",</cfoutput></cfloop>];

		<!--- Auto-bound from the <option> tags already rendered on the <select> - same approach as the Page Collections multi-select on the Page editor. noDataTemplate offers a way out when there's nothing to pick yet, same "not found, add it?" pattern used throughout the admin. --->
		var homepagePageMultiSelect = $("#homepagePageId").kendoMultiSelect({
			autoBind: true,
			filter: "contains",
			noDataTemplate: $("#addPageNoData").html(),
			placeholder: "Select one or more pages...",
			select: function(e) {
				<!--- Auto-bound from plain <option value>text</option> tags, so Kendo's default dataItem schema is {text, value} - not {postId, title}. --->
				var selectedId = String(this.dataItem(e.item).value);
				if (pageSelectionOrder.indexOf(selectedId) === -1) {
					pageSelectionOrder.push(selectedId);
				}
			},
			deselect: function(e) {
				var deselectedId = String(e.dataItem.value);
				pageSelectionOrder = pageSelectionOrder.filter(function(id) { return id !== deselectedId; });
			}
		}).data("kendoMultiSelect");
		var homepageCollectionMultiSelect = $("#homepageCollectionId").kendoMultiSelect({
			autoBind: true,
			filter: "contains",
			noDataTemplate: $("#addCollectionNoData").html(),
			placeholder: "Select one or more collections...",
			select: function(e) {
				<!--- Same {text, value} schema as the pages multiselect above - auto-bound from plain <option value>text</option> tags. --->
				var selectedId = String(this.dataItem(e.item).value);
				if (collectionSelectionOrder.indexOf(selectedId) === -1) {
					collectionSelectionOrder.push(selectedId);
				}
			},
			deselect: function(e) {
				var deselectedId = String(e.dataItem.value);
				collectionSelectionOrder = collectionSelectionOrder.filter(function(id) { return id !== deselectedId; });
			}
		}).data("kendoMultiSelect");
		<!--- Kendo measures the underlying <select>'s width when the widget initializes, which happens while
		#homepageCollectionPicker is still hidden (0 width) - a CSS percentage on the select itself gets ignored
		in that case, so the wrapper is resized explicitly here instead. --->
		homepageCollectionMultiSelect.wrapper.css("width", "60%");

		function togglePickerVisibility() {
			$("#homepagePagePicker").toggle($("#homepageShowPages").is(':checked'));
			$("#homepageCollectionPicker").toggle($("#homepageShowCollections").is(':checked'));
		}
		$("#homepageShowPages, #homepageShowCollections").on('change', togglePickerVisibility);
		togglePickerVisibility();

		var configureHomepageSubmit = $('#configureHomepageSubmit');
		configureHomepageSubmit.on('click', function(e) {
			e.preventDefault();

			var showPages = $("#homepageShowPages").is(':checked');
			var showCollections = $("#homepageShowCollections").is(':checked');
			var showBlogPosts = $("#homepageShowBlogPosts").is(':checked');
			var pageIdList = showPages ? pageSelectionOrder.join(",") : "";
			var collectionIdList = showCollections ? collectionSelectionOrder.join(",") : "";

			if (showPages && !pageIdList) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Pick at least one", message: "Choose one or more pages to show, or turn Pages off.", icon: "k-ext-warning" }));
				return;
			}
			if (showCollections && !collectionIdList) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Pick at least one", message: "Choose one or more collections to show, or turn Collections off.", icon: "k-ext-warning" }));
				return;
			}

			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Saving the homepage setting.", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", icon: "k-ext-information" }));

			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveHomepageSettings',
				data: {
					csrfToken: '<cfoutput>#csrfToken#</cfoutput>',
					homepageShowPages: showPages,
					homepagePageIdList: pageIdList,
					homepageShowCollections: showCollections,
					homepageCollectionIdList: collectionIdList,
					homepageShowBlogPosts: showBlogPosts
				},
				dataType: "json",
				success: function(response) {
					kendo.ui.ExtWaitDialog.hide();
					if (JSON.parse(response.success) == true) {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Saved", message: "The homepage setting was saved.", icon: "k-ext-information" })).done(function() {
							$('#configureHomepageWindow').kendoWindow('destroy');
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
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the saveHomepageSettings function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				}
			});
		});

	});//...document.ready

</script>

<form id="configureHomepageForm" action="#" method="post" data-role="validator">
<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0">
  <cfsilent>
	<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
	<cfset thisColSpan = "2">
  </cfsilent>
  <tr height="1px">
	  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>

  <tr height="30px">
	<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<!--- Counts only - the chosen pages and collections are already listed in the dropdowns below, so the titles
		in getHomepageSettings()'s currentText just repeated them. A single page is the exception: that page IS the
		homepage, so its title stays (currentText already says "the page '...'"). --->
		<cfsilent>
		<cfif homepageSettings.showPages and listLen(homepageSettings.pageIdList) eq 1>
			<cfset homepageSummaryText = homepageSettings.currentText>
		<cfelse>
			<cfset homepageSummaryParts = []>
			<cfif homepageSettings.showPages and listLen(homepageSettings.pageIdList)>
				<cfset arrayAppend(homepageSummaryParts, listLen(homepageSettings.pageIdList) & " featured pages")>
			</cfif>
			<cfif homepageSettings.showCollections and listLen(homepageSettings.collectionIdList)>
				<cfset arrayAppend(homepageSummaryParts, listLen(homepageSettings.collectionIdList) & " featured " & (listLen(homepageSettings.collectionIdList) eq 1 ? "collection" : "collections"))>
			</cfif>
			<cfif homepageSettings.showBlogPosts>
				<cfset arrayAppend(homepageSummaryParts, "the latest blog posts")>
			</cfif>
			<cfset homepageSummaryText = arrayLen(homepageSummaryParts) ? arrayToList(homepageSummaryParts, ", then ") : "the latest posts">
		</cfif>
		</cfsilent>
		Right now your homepage shows <strong><cfoutput>#homepageSummaryText#</cfoutput></strong>. You can change this below.
	</td>
  </tr>

  <tr height="2px"><td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>

  <tr valign="top">
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		Sections appear in this order. Leave all unchecked for the plain blog listing.
	</td>
  </tr>
  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <tr>
  	<td colspan="2" class="">Pick one page to show its full content as the entire homepage, or two or more to show them as cards, in the order you pick them.</td>
  </tr>
  <tr height="2px">
  	<td align="left" valign="top" colspan="2" class="border "></td>
  </tr>
  <tr valign="top">
	<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
		<label for="homepageShowPages">Featured Pages</label>
	</td>
	<td class="<cfoutput>#thisContentClass#</cfoutput>">
		<input class="k-checkbox" type="checkbox" id="homepageShowPages" name="homepageShowPages" <cfif homepageSettings.showPages>checked</cfif>>
		<div id="homepagePagePicker" style="margin: 6px 0 0 0;">
			<select id="homepagePageId" name="homepagePageId" multiple="multiple" style="width: 250px">
				<cfloop array="#allPages#" index="pg">
					<option value="<cfoutput>#pg.postId#</cfoutput>" <cfif listFind(homepageSettings.pageIdList, pg.postId)>selected</cfif>><cfoutput>#pg.title#</cfoutput></option>
				</cfloop>
			</select>			
			<script id="addPageNoData" type="text/x-kendo-tmpl">
				<div>
					No pages exist yet.
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(24,'newPage')" ontouchend="createAdminInterfaceWindow(24,'newPage')">Create a page</button>
			</script>
		</div>
	</td>
  </tr>
  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <tr>
  	<td colspan="2" class="">One card per collection, in the order you pick them - same as pages.</td>
  </tr>
  <tr height="2px">
  	<td align="left" valign="top" colspan="2" class="border "></td>
  </tr>
  <tr valign="top">
	<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
		<label for="homepageShowCollections">Featured Collections</label>
	</td>
	<td class="<cfoutput>#thisContentClass#</cfoutput>">
		<input class="k-checkbox" type="checkbox" id="homepageShowCollections" name="homepageShowCollections" <cfif homepageSettings.showCollections>checked</cfif>>
		<div id="homepageCollectionPicker" style="margin: 6px 0 0 0;">
			<select id="homepageCollectionId" name="homepageCollectionId" multiple="multiple" style="width: 60%">
				<cfloop array="#eligibleCollections#" index="pc">
					<option value="<cfoutput>#pc.pageCollectionId#</cfoutput>" <cfif listFind(homepageSettings.collectionIdList, pc.pageCollectionId)>selected</cfif>><cfoutput>#pc.title#</cfoutput></option>
				</cfloop>
			</select>			
			<script id="addCollectionNoData" type="text/x-kendo-tmpl">
				<div>
					No page collections are ready yet - a collection needs at least 2 pages before it can be featured here.
				</div>
				<br />
				 <button class="k-button" onclick="createAdminInterfaceWindow(68)" ontouchend="createAdminInterfaceWindow(68)">Manage Page Collections</button>
			</script>
		</div>
	</td>
  </tr>
  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <tr>
  	<td colspan="2" class="">Your most recent posts, with a View All Posts link.</td>
  </tr>
  <tr height="2px">
  	<td align="left" valign="top" colspan="2" class="border "></td>
  </tr>
  <tr valign="top">
	<td align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
		<label for="homepageShowBlogPosts">Blog Posts</label>
	</td>
	<td class="<cfoutput>#thisContentClass#</cfoutput>">
		<input class="k-checkbox" type="checkbox" id="homepageShowBlogPosts" name="homepageShowBlogPosts" <cfif homepageSettings.showBlogPosts>checked</cfif>>		
	</td>
  </tr>

  <tr height="2px"><td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>

  <tr valign="middle" height="30px">
	<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">&nbsp;</td>
	<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<button id="configureHomepageSubmit" name="configureHomepageSubmit" class="k-button k-primary" type="button">Save</button>
	</td>
  </tr>

</table>
</form>
