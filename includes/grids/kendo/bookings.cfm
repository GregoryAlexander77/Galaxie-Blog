<!doctype html>
<cfsilent>
<!--- Kendo Grid for the Bookings list (window 94, 2026-10-14); the jsGrid version is ../jsGrid/bookings.cfm. Read-only: Open shows
	a booking (window 95). Expects bookingsRange (upcoming, past or all) from bookingsList.cfm. No delete: bookings keep their history. --->
<cfset gridName = "bookingsGrid">
</cfsilent>
<html>
<head></head>
<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="bookingWhenTemplate">
	<a href="javascript:createAdminInterfaceWindow(95, #: BookingId #);">#: When #</a>
</script>

<script>
	$(document).ready(function() {

		bookingsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getBookingsForGrid&gridType=kendo&range=<cfoutput>#bookingsRange#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					return {};
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "BookingId",
					fields: {
						BookingId: { type: "number", editable: false, nullable: false },
						When: { type: "string", editable: false, nullable: false },
						TypeName: { type: "string", editable: false, nullable: true },
						LocationLabel: { type: "string", editable: false, nullable: true },
						ClientName: { type: "string", editable: false, nullable: true },
						Email: { type: "string", editable: false, nullable: true },
						StatusLabel: { type: "string", editable: false, nullable: true }
					}
				}
			},
			sort: { field: "When", dir: "<cfif bookingsRange eq "upcoming">asc<cfelse>desc</cfif>" }
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: bookingsDs,
			<!--- Not batch: Delete is sent at once (batch mode queued it until Save - see the comments grid, 2026-10-14). --->
			editable: false,
			<cfif session.isMobile>mobile: true,</cfif>
			height: 500,
			navigatable: true,
			filterable: true,
			sortable: true,
			pageable: { pageSizes: [10,20,50,"All"], refresh: true },
			resizable: true,
			columns: [{
				field: "When",
				title: "When",
				width: "<cfif session.isMobile>40<cfelse>17</cfif>%",
				template: kendo.template($("#bookingWhenTemplate").html())
			}, {
				field: "ClientName",
				title: "Client",
				width: "<cfif session.isMobile>30<cfelse>15</cfif>%"
			<cfif not session.isMobile>}, {
				field: "TypeName",
				title: "Booking"
			}, {
				field: "LocationLabel",
				title: "Where",
				width: "17%"
			}, {
				field: "Email",
				title: "Email",
				width: "16%"</cfif>
			}, {
				field: "StatusLabel",
				title: "Status",
				width: "<cfif session.isMobile>30<cfelse>13</cfif>%"
			}, {
				command: [{
					name: "openBooking",
					text: "Open",
					click: function(e) {
						e.preventDefault();
						var item = this.dataItem($(e.currentTarget).closest("tr"));
						createAdminInterfaceWindow(95, item.BookingId);
					}
				}],
				title: "&nbsp;",
				width: "<cfif session.isMobile>20<cfelse>9</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
