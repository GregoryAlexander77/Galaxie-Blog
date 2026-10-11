<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/pageCollections.cfm. Read-only except for Delete - Title/Description/Hero
	Image/Theme/member order all edit together in the Page Collection Detail window
	(createAdminInterfaceWindow(72, pageCollectionId)), not inline in the grid, since editing the member order
	needs a drag-reorderable list that doesn't fit an inline grid cell. Delete reuses the same deletePageCollection
	endpoint the old combined list+expand interface used (configurePageCollections.cfm, now superseded by this
	grid + pageCollectionDetail.cfm) - its {success,errorMessage} shape already fits a destroy transport, no new
	*ViaKendoGrid wrapper needed. --->
<cfset gridName = "pageCollectionsGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>All columns are sortable and searchable/filterable. Click a collection's title to edit its hero image, theme, and member order.</p>
	<button id="newPageCollectionBtn" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(24,'newPageCollection');">Create New Page Collection</button>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="pcTitleTemplate">
	<a href="javascript:createAdminInterfaceWindow(72, #: PageCollectionId #);">#: Title #</a>
</script>
<script type="text/x-kendo-template" id="pcStatusTemplate">
	# if (Status === "Live") { # #: Status # # } else { # <a href="javascript:createAdminInterfaceWindow(71, #: PageCollectionId #);" title="Add pages to this collection">#: Status #</a> # } #
</script>

<script>
	$(document).ready(function() {

		<!--- One-time dissolve notice, shown when the admin next opens this grid (see doc/pageCollectionsDesign - "pops up only once", batched if more than one is pending). Moved here from the old configurePageCollections.cfm since this grid is now the first stop for Page Collections. --->
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

		pageCollectionsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getPageCollectionsForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deletePageCollection",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "destroy") {
						return { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", pageCollectionId: options.PageCollectionId };
					}
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "PageCollectionId",
					fields: {
						PageCollectionId: { type: "number", editable: false, nullable: false },
						Title: { type: "string", editable: false, nullable: false },
						Description: { type: "string", editable: false, nullable: true },
						MemberCount: { type: "number", editable: false, nullable: false },
						Status: { type: "string", editable: false, nullable: false },
						Created: { type: "string", editable: false, nullable: true }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: pageCollectionsDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "pageCollections.xlsx",
				filterable: true,
				allPages: true
			},
			<cfif session.isMobile>mobile: true,</cfif>
			height: 725,
			navigatable: true,
			filterable: true,
			sortable: { mode: "multiple", allowUnsort: true, showIndexes: true },
			pageable: { pageSizes: [10,20,50,100,"All"], refresh: true },
			groupable: true,
			selectable: "<cfif session.isMobile>cell<cfelse>multiple cell</cfif>",
			allowCopy: true,
			reorderable: true,
			resizable: true,
			columnMenu: true,
			columns: [{
				field: "Title",
				title: "Title",
				filterable: true,
				width: "<cfif session.isMobile>50<cfelse>30</cfif>%",
				template: kendo.template($("#pcTitleTemplate").html())
			<cfif not session.isMobile>}, {
				field: "Description",
				title: "Description",
				filterable: true,
				width: "25%"</cfif>
			}, {
				field: "MemberCount",
				title: "Pages",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>8</cfif>%"
			}, {
				field: "Status",
				title: "Status",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>12</cfif>%",
				template: kendo.template($("#pcStatusTemplate").html())
			<cfif not session.isMobile>}, {
				field: "Created",
				title: "Created",
				filterable: true,
				width: "10%",
				template: "#= Created ? dayjs(Created).format('MM/DD/YYYY h:mm A') : '' #"</cfif>
			}, {
				<!--- Open goes straight to Page Collection Detail (window 72) for this row. Kendo's own button styling keeps it readable on any theme. --->
				command: [{
					name: "openPageCollection",
					text: "Open",
					click: function(e) {
						e.preventDefault();
						var item = $("#<cfoutput>#gridName#</cfoutput>").data("kendoGrid").dataItem($(e.currentTarget).closest("tr"));
						createAdminInterfaceWindow(72, item.PageCollectionId);
					}
				}, "destroy"],
				title: "&nbsp;",
				width: "<cfif session.isMobile>25<cfelse>14</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
