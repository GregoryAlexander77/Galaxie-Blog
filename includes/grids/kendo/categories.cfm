<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/categories.cfm. Category/Alias are inline editable (batch saved
	via the toolbar). There is no batch-capable *ViaKendoGrid update endpoint for categories, only
	the single-row updateCategoryViaJsGrid (which the jsGrid version already uses), so this grid uses
	batch:false and a parameterMap that flattens the one changed row into that endpoint's flat
	arguments. Delete reuses deleteCategoryViaKendoGrid (fixed elsewhere in this pass -- it used to
	delete Comment entities instead of Category entities). The jsGrid version also declares
	inserting:true with an insertItem handler that just posts to a nonexistent "/items" endpoint --
	that path was never functional; the real "add category" flow is the button below, which opens
	the same New Category window used elsewhere (createAdminInterfaceWindow(12)). --->
<cfset gridName = "categoriesGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>All columns are sortable and searchable/filterable. To change a category, edit the Category or Alias cell and click Save on the toolbar.</p>
	<button id="newCategoryBtn" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(12);">Create New Category</button>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script>
	$(document).ready(function() {

		categoriesDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getCategoriesForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updateCategoryViaJsGrid",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteCategoryViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "update") {
						return {
							csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
							categoryId: options.CategoryId,
							category: options.Category,
							categoryAlias: options.CategoryAlias
						};
					}
					if (operation === "destroy") {
						return { models: kendo.stringify([options]) };
					}
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "CategoryId",
					fields: {
						CategoryId: { type: "number", editable: false, nullable: false },
						Category: { type: "string", editable: true, nullable: false },
						CategoryAlias: { type: "string", editable: true, nullable: false },
						PostCount: { type: "number", editable: false, nullable: true },
						Date: { type: "string", editable: false, nullable: true }
					}
				}
			}
		});

		<!--- If updateCategoryViaJsGrid reports a validation failure (e.g. duplicate category/alias), show it and reload to discard the bad edit. --->
		categoriesDs.bind("requestEnd", function(e) {
			if (e.type === "update" && e.response && !e.response.success) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving category", message: e.response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" })
					).done(function() { categoriesDs.read(); });
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: categoriesDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "categories.xlsx",
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
				field: "Category",
				title: "Category",
				filterable: true,
				width: "<cfif session.isMobile>50<cfelse>35</cfif>%"
			}, {
				field: "CategoryAlias",
				title: "Alias",
				filterable: true,
				width: "<cfif session.isMobile>50<cfelse>35</cfif>%"
			<cfif not session.isMobile>}, {
				field: "PostCount",
				title: "Post Count",
				filterable: true,
				width: "10%"
			}, {
				field: "Date",
				title: "Date",
				filterable: true,
				width: "10%",
				template: "#= Date ? dayjs(Date).format('MM/DD/YYYY h:mm A') : '' #"</cfif>
			}, {
				command: ["destroy"],
				title: "&nbsp;",
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
