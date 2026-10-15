<!--- Add Pages to Collection - a quick-add multiselect opened from Configure Page Collections' "open Pages" link (window id 71), so the admin can pick pages for a Collection in one step instead of visiting the full Pages grid and opening each page's own editor one at a time. Additive only - see blog.cfc's addPagesToPageCollection, which never touches a Page's other Collection memberships (unlike setPageCollectionsForPost on the Page editor, which replaces a Page's whole membership list wholesale). --->
<cfset pageCollectionId = val(URL.optArgs)>
<cfset allCollections = application.blog.getAllPageCollections()>
<cfset thisCollectionTitle = "this collection">
<cfloop array="#allCollections#" index="c">
	<cfif c.pageCollectionId eq pageCollectionId>
		<cfset thisCollectionTitle = c.title>
	</cfif>
</cfloop>
<cfset currentMembers = application.blog.getPageCollectionMembers(pageCollectionId)>
<cfset currentMemberIdList = "">
<cfloop array="#currentMembers#" index="m">
	<cfset currentMemberIdList = listAppend(currentMemberIdList, m.postId)>
</cfloop>
<cfset allPages = application.blog.getPagesForDropdown()>
<cfset eligiblePages = []>
<cfloop array="#allPages#" index="p">
	<cfif not listFind(currentMemberIdList, p.postId)>
		<cfset arrayAppend(eligiblePages, p)>
	</cfif>
</cfloop>

<script>

	$(document).ready(function() {

		<!--- Reads its options straight from the server-rendered <option> list, same approach as the Page editor's own Page Collections multiselect. noDataTemplate offers a way out when there's nothing left to add. --->
		$("#addPagesMultiSelect").kendoMultiSelect({
			autoBind: true,
			filter: "contains",
			noDataTemplate: $("#addPagesNoData").html(),
			placeholder: "Select pages to add..."
		});

		$("#addPagesSubmit").on('click', function(e) {
			e.preventDefault();
			var selected = $("#addPagesMultiSelect").data("kendoMultiSelect").value();
			if (!selected || selected.length === 0) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Pick at least one page", message: "Choose one or more pages to add to this collection.", icon: "k-ext-warning" }));
				return;
			}

			jQuery.ajax({
				type: 'post',
				url: '<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=addPagesToPageCollection',
				data: { csrfToken: '<cfoutput>#csrfToken#</cfoutput>', pageCollectionId: <cfoutput>#pageCollectionId#</cfoutput>, postIdList: selected.join(",") },
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						jQuery('#addPagesToCollectionWindow').kendoWindow('destroy');
						<!--- Refresh Configure Page Collections so the newly-added pages show up right away, same pattern used after creating a new Page Collection. --->
						try {
							$("#configurePageCollectionsWindow").data("kendoWindow").refresh();
						} catch (error) {
							<!--- Do nothing - the window probably wasn't open --->
						}
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not add pages", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				},
				error: function(jqXHR, textStatus, error) {
					if (jqXHR.status === 403) {
						createLoginWindow();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the addPagesToPageCollection function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
					}
				}
			});
		});

	});//...document.ready

</script>

<form id="addPagesToCollectionForm" action="#" method="post" data-role="validator">
<input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#csrfToken#</cfoutput>" />
<table align="center" class="k-content tableBorder" width="100%" cellpadding="2" cellspacing="0" border="0" style="padding: 4px;">
  <cfsilent>
	<cfset thisContentClass = HtmlUtilsObj.getKendoClass('')>
	<cfset thisColSpan = "2">
  </cfsilent>
  <tr height="1px">
	  <td align="left" valign="top" colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td>
  </tr>

  <tr height="30px">
	<td align="left" class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		Pick which pages belong in <strong><cfoutput>#thisCollectionTitle#</cfoutput></strong>. This only adds pages - it won't remove any collection a page already belongs to.
	</td>
  </tr>

  <tr height="2px"><td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>

<cfif session.isMobile>
  <tr valign="top">
	<td class="<cfoutput>#thisContentClass#</cfoutput>" colspan="2">
		<label for="addPagesMultiSelect">Pages:</label><br>
		<select id="addPagesMultiSelect" multiple="multiple" style="width: 95%">
			<cfloop array="#eligiblePages#" index="p">
				<option value="<cfoutput>#p.postId#</cfoutput>"><cfoutput>#p.title#</cfoutput></option>
			</cfloop>
		</select>
		<script id="addPagesNoData" type="text/x-kendo-tmpl">
			<div>
				<cfif arrayLen(allPages) eq 0>
				No pages exist yet.
				<cfelse>
				Every existing page is already in this collection.
				</cfif>
			</div>
			<br />
			 <button class="k-button" onclick="createAdminInterfaceWindow(24,'newPage')" ontouchend="createAdminInterfaceWindow(24,'newPage')">Create a page</button>
		</script>
		<div class="k-form-hint">Only pages not yet in this collection are listed.</div>
	</td>
  </tr>
<cfelse><!---<cfif session.isMobile>--->
  <tr>
  	<td colspan="2" class="">Only pages not yet in this collection are listed.</td>
  </tr>
  <tr height="2px">
  	<td align="left" valign="top" colspan="2" class="border "></td>
  </tr>
  <tr valign="top">
	<td align="right" valign="top" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">
		<label for="addPagesMultiSelect">Pages:</label>
	</td>
	<td class="<cfoutput>#thisContentClass#</cfoutput>">
		<select id="addPagesMultiSelect" multiple="multiple" style="width: 95%">
			<cfloop array="#eligiblePages#" index="p">
				<option value="<cfoutput>#p.postId#</cfoutput>"><cfoutput>#p.title#</cfoutput></option>
			</cfloop>
		</select>
		<script id="addPagesNoData" type="text/x-kendo-tmpl">
			<div>
				<cfif arrayLen(allPages) eq 0>
				No pages exist yet.
				<cfelse>
				Every existing page is already in this collection.
				</cfif>
			</div>
			<br />
			 <button class="k-button" onclick="createAdminInterfaceWindow(24,'newPage')" ontouchend="createAdminInterfaceWindow(24,'newPage')">Create a page</button>
		</script>		
	</td>
  </tr>
</cfif><!---<cfif session.isMobile>--->

  <tr height="2px"><td colspan="2" class="<cfoutput>#thisContentClass#</cfoutput>"></td></tr>
  <cfsilent><cfset thisContentClass = HtmlUtilsObj.getKendoClass(thisContentClass)></cfsilent>
  <tr height="2px"><td colspan="2" class="border <cfoutput>#thisContentClass#</cfoutput>"></td></tr>

  <tr valign="middle" height="30px">
	<td valign="bottom" align="right" class="<cfoutput>#thisContentClass#</cfoutput>" style="width: 20%">&nbsp;</td>
	<td valign="bottom" align="left" class="<cfoutput>#thisContentClass#</cfoutput>">
		<button id="addPagesSubmit" name="addPagesSubmit" class="k-button k-primary" type="button">Add to Collection</button>
	</td>
  </tr>

</table>
</form>
