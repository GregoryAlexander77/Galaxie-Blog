<!doctype html>
<cfsilent>
<!--- Kendo Grid for the Booking types window (90, 2026-10-14); the jsGrid version is ../jsGrid/bookingTypes.cfm. Read-only except for
	Delete: a booking type is edited in the booking type editor (window 91), opened from its name or Edit. Delete uses
	ProxyController.cfc's deleteBookingType. --->
<cfset gridName = "bookingTypesGrid">
</cfsilent>
<html>
<head></head>
<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="bookingTypeNameTemplate">
	<a href="javascript:createAdminInterfaceWindow(91, #: BookingTypeId #);">#: Name #</a>
</script>

<script>
	$(document).ready(function() {

		bookingTypesDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getBookingTypesForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteBookingType",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "destroy") {
						return { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", bookingTypeId: options.BookingTypeId };
					}
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "BookingTypeId",
					fields: {
						BookingTypeId: { type: "number", editable: false, nullable: false },
						Name: { type: "string", editable: false, nullable: false },
						Category: { type: "string", editable: false, nullable: true },
						Length: { type: "string", editable: false, nullable: false },
						Price: { type: "string", editable: false, nullable: false },
						Locations: { type: "string", editable: false, nullable: true },
						SortOrder: { type: "number", editable: false, nullable: false },
						Status: { type: "string", editable: false, nullable: false }
					}
				}
			},
			sort: [{ field: "Category", dir: "asc" }, { field: "SortOrder", dir: "asc" }]
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: bookingTypesDs,
			<!--- Not batch: Delete is sent at once (batch mode queued it until Save - see the comments grid, 2026-10-14). --->
			editable: { mode: "inline", confirmation: "Delete this booking type? To stop offering it but keep it for later, edit it and untick Active instead." },
			<cfif session.isMobile>mobile: true,</cfif>
			height: 500,
			navigatable: true,
			filterable: true,
			sortable: true,
			pageable: { pageSizes: [10,20,50,"All"], refresh: true },
			resizable: true,
			columns: [{
				field: "Name",
				title: "Name",
				width: "<cfif session.isMobile>45<cfelse>22</cfif>%",
				template: kendo.template($("#bookingTypeNameTemplate").html())
			}, {
				field: "Category",
				title: "Category",
				width: "<cfif session.isMobile>25<cfelse>12</cfif>%"
			<cfif not session.isMobile>}, {
				field: "Length",
				title: "Length",
				width: "11%"
			}, {
				field: "Price",
				title: "Price",
				width: "8%"
			}, {
				field: "Locations",
				title: "Where"
			}, {
				field: "Status",
				title: "Status",
				width: "9%"</cfif>
			}, {
				command: [{
					name: "editBookingType",
					text: "Edit",
					click: function(e) {
						e.preventDefault();
						var item = this.dataItem($(e.currentTarget).closest("tr"));
						createAdminInterfaceWindow(91, item.BookingTypeId);
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
