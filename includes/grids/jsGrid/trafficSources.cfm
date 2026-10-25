<!--- Traffic Sources (window 117, 2026-10-25, owner), the jsGrid: one row per site people came from in the period, most people
first. The period buttons and the bar by type are in ../trafficSourcesTop.cfm; the Kendo twin is ../kendo/trafficSources.cfm.
A period's sites are few (one row each), so the grid sorts and pages them in the browser. --->
<cfoutput>
	<link type="text/css" rel="stylesheet" href="#application.baseUrl#/common/libs/jsGrid/jsgrid.min.css" />
	<cfinclude template="#application.baseUrl#/common/libs/jsGrid/kendoThemeCss.cfm">
	<script type="text/javascript" src="#application.baseUrl#/common/libs/jsGrid/jsgrid.min.js"></script>
</cfoutput>
<cfinclude template="../trafficSourcesTop.cfm">
<div id="trafficSourcesGrid"></div>
<script>
	$(document).ready(function () {
		var pageWidth = $("#trafficSourcesGrid").parent().width() - 60;
		var show = function (rows) {
			$("#trafficSourcesGrid").jsGrid({
				width: "100%",
				sorting: true,
				paging: true,
				pageSize: 25,
				noDataContent: "No visits in this period yet.",
				data: rows,
				fields: [
					{ name: "site", title: "Site", type: "text", width: pageWidth * (<cfif session.isMobile>40<cfelse>22</cfif> / 100), itemTemplate: function (value, item) { return trafficSourcesSite(item); } },
					{ name: "type", title: "Type", type: "text", width: pageWidth * (<cfif session.isMobile>25<cfelse>11</cfif> / 100) },
					{ name: "people", title: "People", type: "number", width: pageWidth * (<cfif session.isMobile>17<cfelse>9</cfif> / 100) },
					{ name: "visits", title: "Visits", type: "number", width: pageWidth * (<cfif session.isMobile>18<cfelse>9</cfif> / 100) }<cfif not session.isMobile>,
					{ name: "first", title: "First seen", type: "text", width: pageWidth * (11 / 100), itemTemplate: function (value) { return trafficSourcesDate(value); } },
					{ name: "last", title: "Last seen", type: "text", width: pageWidth * (11 / 100), itemTemplate: function (value) { return trafficSourcesDate(value); } },
					{ name: "topPost", title: "Landed on most", type: "text", width: pageWidth * (27 / 100), itemTemplate: function (value) { return trafficSourcesText(value); } }</cfif>
				]
			});
		};
		$("#trafficSourcesTop .trafficPeriods").on("click", ".k-button", function () { trafficSourcesLoad($(this).data("days"), show); });
		trafficSourcesLoad(trafficSourcesDays, show);
	});
</script>
