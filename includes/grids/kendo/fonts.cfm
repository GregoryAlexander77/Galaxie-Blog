<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/fonts.cfm. Unlike the other CRUD grids in this pass, there is no
	*ViaKendoGrid endpoint at all for fonts (update or delete), so both operations here reuse the
	existing single-row updateFontViaJsGrid / deleteFontViaJsGrid endpoints directly via
	batch:false + parameterMap (deleteFontViaJsGrid takes a plain fontId argument, not the
	"models" json-array shape the *ViaKendoGrid family uses, so destroy is flattened the same way
	update is here). --->
<cfset gridName = "fontsGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>All columns are sortable and searchable/filterable. Edit a checkbox and click Save on the toolbar to change it. Click a font name to view or edit its details.</p>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="fontNameTemplate">
	<a href="javascript:createAdminInterfaceWindow(34, #: FontId #);">#: Font #</a>
</script>

<script>
	$(document).ready(function() {

		fontsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getFontsForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updateFontViaJsGrid",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteFontViaJsGrid",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "update") {
						return {
							csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
							fontId: options.FontId,
							fontWeight: options.FontWeight,
							italic: options.Italic,
							webSafeFont: options.WebSafeFont,
							useFont: options.UseFont
						};
					}
					if (operation === "destroy") {
						return {
							csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
							fontId: options.FontId
						};
					}
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "FontId",
					fields: {
						FontId: { type: "number", editable: false, nullable: false },
						Font: { type: "string", editable: false, nullable: false },
						FontWeight: { type: "string", editable: true, nullable: true },
						Italic: { type: "boolean", editable: true, nullable: true },
						WebSafeFont: { type: "boolean", editable: true, nullable: true },
						FileName: { type: "string", editable: false, nullable: true },
						UseFont: { type: "boolean", editable: true, nullable: true }
					}
				}
			}
		});

		<!--- If updateFontViaJsGrid reports a validation failure, show it and reload to discard the bad edit. --->
		fontsDs.bind("requestEnd", function(e) {
			if (e.type === "update" && e.response && e.response.success === false) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving font", message: e.response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" })
					).done(function() { fontsDs.read(); });
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: fontsDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "fonts.xlsx",
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
				field: "Font",
				title: "Font",
				filterable: true,
				width: "<cfif session.isMobile>50<cfelse>25</cfif>%",
				template: kendo.template($("#fontNameTemplate").html())
			}, {
				field: "FontWeight",
				title: "Font Weight",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%"
			}, {
				field: "Italic",
				title: "Italic?",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%"
			<cfif not session.isMobile>}, {
				field: "WebSafeFont",
				title: "Web Safe?",
				filterable: true,
				width: "10%"
			}, {
				field: "FileName",
				title: "File Name",
				filterable: true,
				width: "25%"
			}, {
				field: "UseFont",
				title: "Use Font",
				filterable: true,
				width: "10%"</cfif>
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
