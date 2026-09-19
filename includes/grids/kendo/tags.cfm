<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/tags.cfm. Tag/Alias are inline editable (batch:false, single-row
	updateTagViaJsGrid, same reasoning as categories.cfm). Delete reuses the already-correct
	deleteTagViaKendoGrid. Like categories.cfm, the jsGrid version's inserting:true/insertItem was a
	non-functional stub (posts to "/items"); the real add-tag flow is the button below. --->
<cfset gridName = "tagsGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>All columns are sortable and searchable/filterable. To change a tag, edit the Tag or Alias cell and click Save on the toolbar.</p>
	<button id="newTagBtn" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(49);">Create New Tag</button>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script>
	$(document).ready(function() {

		tagsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getTagsForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updateTagViaJsGrid",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteTagViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "update") {
						return {
							csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
							tagId: options.TagId,
							tag: options.Tag,
							tagAlias: options.TagAlias
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
					id: "TagId",
					fields: {
						TagId: { type: "number", editable: false, nullable: false },
						Tag: { type: "string", editable: true, nullable: false },
						TagAlias: { type: "string", editable: true, nullable: false },
						PostCount: { type: "number", editable: false, nullable: true },
						Date: { type: "string", editable: false, nullable: true }
					}
				}
			}
		});

		<!--- If updateTagViaJsGrid reports a validation failure (e.g. duplicate tag/alias), show it and reload to discard the bad edit. --->
		tagsDs.bind("requestEnd", function(e) {
			if (e.type === "update" && e.response && !e.response.success) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving tag", message: e.response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" })
					).done(function() { tagsDs.read(); });
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: tagsDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "tags.xlsx",
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
				field: "Tag",
				title: "Tag",
				filterable: true,
				width: "<cfif session.isMobile>50<cfelse>35</cfif>%"
			}, {
				field: "TagAlias",
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
