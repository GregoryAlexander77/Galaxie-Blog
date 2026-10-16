<!doctype html>
<cfsilent>
<!--- Kendo Grid for the Locations window (88, 2026-10-14); the jsGrid version is ../jsGrid/locations.cfm. Read-only except for
	Delete: a location is edited in the location editor (window 89), opened from its name or Edit. Delete uses ProxyController.cfc's
	deleteLocation. --->
<cfset gridName = "locationsGrid">
</cfsilent>
<html>
<head></head>
<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="locationLabelTemplate">
	<a href="javascript:createAdminInterfaceWindow(89, #: LocationOptionId #);">#: Label #</a>
</script>

<script>
	$(document).ready(function() {

		locationsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getLocationsForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteLocation",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "destroy") {
						return { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", locationOptionId: options.LocationOptionId };
					}
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "LocationOptionId",
					fields: {
						LocationOptionId: { type: "number", editable: false, nullable: false },
						Label: { type: "string", editable: false, nullable: false },
						KindLabel: { type: "string", editable: false, nullable: false },
						Details: { type: "string", editable: false, nullable: true },
						SortOrder: { type: "number", editable: false, nullable: false },
						Status: { type: "string", editable: false, nullable: false }
					}
				}
			},
			sort: { field: "SortOrder", dir: "asc" }
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: locationsDs,
			<!--- Not batch: Delete is sent at once (batch mode queued it until Save - see the comments grid, 2026-10-14). --->
			editable: { mode: "inline", confirmation: "Delete this location? To stop offering it but keep it for later, edit it and untick Active instead." },
			<cfif session.isMobile>mobile: true,</cfif>
			height: 500,
			navigatable: true,
			filterable: true,
			sortable: true,
			pageable: { pageSizes: [10,20,50,"All"], refresh: true },
			resizable: true,
			columns: [{
				field: "Label",
				title: "Name",
				width: "<cfif session.isMobile>45<cfelse>22</cfif>%",
				template: kendo.template($("#locationLabelTemplate").html())
			}, {
				field: "KindLabel",
				title: "How",
				width: "<cfif session.isMobile>25<cfelse>9</cfif>%"
			<cfif not session.isMobile>}, {
				field: "Details",
				title: "Details"
			}, {
				field: "SortOrder",
				title: "Order",
				width: "<cfif session.isMobile>8<cfelse>7</cfif>%"
			}, {
				field: "Status",
				title: "Status",
				width: "<cfif session.isMobile>10<cfelse>9</cfif>%"</cfif>
			}, {
				command: [{
					name: "editLocation",
					text: "Edit",
					click: function(e) {
						e.preventDefault();
						var item = this.dataItem($(e.currentTarget).closest("tr"));
						createAdminInterfaceWindow(89, item.LocationOptionId);
					}
				}, "destroy"],
				title: "&nbsp;",
				width: "<cfif session.isMobile>30<cfelse>17</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
