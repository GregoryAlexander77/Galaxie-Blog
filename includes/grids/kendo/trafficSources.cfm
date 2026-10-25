<!--- Traffic Sources (window 117, 2026-10-25, owner), the Kendo grid: one row per site people came from in the period, most people
first. The period buttons and the bar by type are in ../trafficSourcesTop.cfm; the jsGrid twin is ../jsGrid/trafficSources.cfm.
A period's sites are few (one row each), so the grid sorts, filters and pages them in the browser. --->
<cfinclude template="../trafficSourcesTop.cfm">
<div id="trafficSourcesGrid"></div>
<script>
	$(document).ready(function () {
		var trafficSourcesDs = new kendo.data.DataSource({
			data: [],
			pageSize: 25,
			sort: { field: "people", dir: "desc" },
			schema: {
				model: {
					fields: {
						site: { type: "string" }, type: { type: "string" }, people: { type: "number" }, visits: { type: "number" },
						first: { type: "string" }, last: { type: "string" }, topPost: { type: "string" }
					}
				}
			}
		});
		$("#trafficSourcesGrid").kendoGrid({
			dataSource: trafficSourcesDs,
			<cfif session.isMobile>mobile: true,</cfif>
			sortable: true,
			filterable: true,
			pageable: { pageSizes: [25, 50, 100] },
			noRecords: { template: "No visits in this period yet." },
			resizable: true,
			columns: [
				{ field: "site", title: "Site", width: "<cfif session.isMobile>40<cfelse>22</cfif>%", template: function (item) { return trafficSourcesSite(item); } },
				{ field: "type", title: "Type", width: "<cfif session.isMobile>25<cfelse>11</cfif>%" },
				{ field: "people", title: "People", width: "<cfif session.isMobile>17<cfelse>9</cfif>%", filterable: false },
				{ field: "visits", title: "Visits", width: "<cfif session.isMobile>18<cfelse>9</cfif>%", filterable: false }<cfif not session.isMobile>,
				{ field: "first", title: "First seen", width: "11%", filterable: false, template: function (item) { return trafficSourcesDate(item.first); } },
				{ field: "last", title: "Last seen", width: "11%", filterable: false, template: function (item) { return trafficSourcesDate(item.last); } },
				{ field: "topPost", title: "Landed on most", width: "27%", template: function (item) { return trafficSourcesText(item.topPost); } }</cfif>
			]
		});
		var show = function (rows) { trafficSourcesDs.data(rows); trafficSourcesDs.page(1); };
		$("#trafficSourcesTop .trafficPeriods").on("click", ".k-button", function () { trafficSourcesLoad($(this).data("days"), show); });
		trafficSourcesLoad(trafficSourcesDays, show);
	});
</script>
