<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/themes.cfm. Reused for both the Theme Property grid (case 29,
	themeGridType="themeProperty") and the Theme Content Template grid (case 54,
	themeGridType="contentTemplate"), same as the jsGrid version -- the caller sets themeGridType
	before including this file. Checkboxes are inline editable (batch:false, single-row
	updateThemeViaJsGrid, same reasoning as categories.cfm). Delete reuses the now-fixed
	deleteThemeViaKendoGrid. Note: updateThemeViaJsGrid does not declare a contentWidth argument even
	though the jsGrid client sends one -- this version only sends the arguments the function actually
	declares (themeId, themeSettingId, modernThemeStyle, useTheme, selectedTheme). --->
<cfif themeGridType eq 'themeProperty'>
	<cfset gridName = "themeGrid">
<cfelseif themeGridType eq 'contentTemplate'>
	<cfset gridName = "themeContentGrid">
</cfif>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<cfif themeGridType eq 'themeProperty'>
		<p>All columns are sortable and searchable/filterable. To make a theme your default, check the Selected Theme checkbox and click Save on the toolbar. Click a theme name to view its properties.</p>
		<button id="newThemeBtn" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(37,'newTheme');">Create New Theme</button>
	<cfelseif themeGridType eq 'contentTemplate'>
		<p>Each content template can have one or more themes. This allows you to create customized pages for a blog post or category.</p>
	</cfif>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="themeNameTemplate">
	<cfif themeGridType eq 'themeProperty'>
		<a href="javascript:createAdminInterfaceWindow(30, #: ThemeId #);">#: ThemeName #</a>
	<cfelseif themeGridType eq 'contentTemplate'>
		<a href="javascript:createAdminInterfaceWindow(55, #: ThemeId #);">#: ThemeName #</a>
	</cfif>
</script>
<script type="text/x-kendo-template" id="kendoThemeTemplate">
	<a href="javascript:createAdminInterfaceWindow(30, #: ThemeId #);">#: KendoTheme #</a>
</script>

<script>
	$(document).ready(function() {

		<cfoutput>#gridName#</cfoutput>Ds = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getThemesForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updateThemeViaJsGrid",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteThemeViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "update") {
						return {
							csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
							themeId: options.ThemeId,
							themeSettingId: options.ThemeSettingId,
							modernThemeStyle: options.ModernThemeStyle,
							useTheme: options.UseTheme,
							selectedTheme: options.SelectedTheme
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
					id: "ThemeId",
					fields: {
						ThemeId: { type: "number", editable: false, nullable: false },
						ThemeSettingId: { type: "number", editable: false, nullable: true },
						ThemeName: { type: "string", editable: false, nullable: false },
						KendoTheme: { type: "string", editable: false, nullable: true },
						ModernThemeStyle: { type: "boolean", editable: true, nullable: true },
						UseTheme: { type: "boolean", editable: true, nullable: true },
						SelectedTheme: { type: "boolean", editable: true, nullable: true }
					}
				}
			}
		});

		<!--- If updateThemeViaJsGrid reports a validation failure, show it and reload to discard the bad edit. --->
		<cfoutput>#gridName#</cfoutput>Ds.bind("requestEnd", function(e) {
			if (e.type === "update" && e.response && e.response.success === false) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving theme", message: e.response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" })
					).done(function() { <cfoutput>#gridName#</cfoutput>Ds.read(); });
			}
		});

		<!--- There can only be one selected theme. When a theme is checked, uncheck the others so the grid shows what will be saved. The server also deselects the other themes (updateThemeViaJsGrid). --->
		<cfoutput>#gridName#</cfoutput>Ds.bind("change", function(e) {
			if (e.action === "itemchange" && e.field === "SelectedTheme" && e.items[0].SelectedTheme) {
				var checkedItem = e.items[0];
				$.each(this.data(), function(index, item) {
					if (item.ThemeId !== checkedItem.ThemeId && item.SelectedTheme) {
						item.set("SelectedTheme", false);
					}
				});
				<!--- The grid does not redraw the cells of the rows that were changed here, so redraw them after the current edit is done. --->
				setTimeout(function() { $("#<cfoutput>#gridName#</cfoutput>").data("kendoGrid").refresh(); }, 0);
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: <cfoutput>#gridName#</cfoutput>Ds,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "themes.xlsx",
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
				field: "ThemeName",
				title: "Theme",
				filterable: true,
				width: "<cfif session.isMobile>40<cfelse>20</cfif>%",
				template: kendo.template($("#themeNameTemplate").html())
			}, {
				field: "KendoTheme",
				title: "Kendo Theme",
				filterable: true,
				width: "<cfif session.isMobile>25<cfelse>20</cfif>%",
				template: kendo.template($("#kendoThemeTemplate").html())
			<cfif not session.isMobile>}, {
				field: "ModernThemeStyle",
				title: "Modern Theme?",
				filterable: true,
				width: "10%"
			}, {
				field: "UseTheme",
				title: "Use Theme",
				filterable: true,
				width: "10%"</cfif>
			}, {
				field: "SelectedTheme",
				title: "Selected Theme",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%"
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
