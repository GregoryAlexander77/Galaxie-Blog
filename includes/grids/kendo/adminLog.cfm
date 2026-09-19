<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/adminLog.cfm -- replicates the same read-only admin login log:
	FullName, a clickable IpAddress (links to ipalyzer.com), a clickable HttpUserAgent (links to
	gs.statcounter.com), and the login Date. The Kendo Grid does not need its own paging/filtering
	logic on the server -- gridType=kendo makes getAdminLogForGrid return a plain JSON array (instead
	of the {data:[...]} shape jsGrid needs) and the grid below paginates/sorts/filters it client side,
	same as every other Kendo grid in this app. No Kendo UI core library script tags are included here
	since the parent adminInterface.cfm / admin index page already loads Kendo (this template is
	injected into a Kendo Window via content: url, not loaded as its own document). --->
<cfset gridName = "adminLogGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>All columns are sortable and searchable/filterable. Note: to conserve resources, this query only returns the last 10000 rows of data. However, all of the data inside the retention period specified in the blog options interface is intact in the AdminLog table in the database if you need to perform further manual analysis.</p>
</head>

<body>

<!--- Container for the grid --->
<div id="<cfoutput>#gridName#</cfoutput>"></div>

<!--- Kendo templates for the linked columns. Using a dedicated template avoids having to escape quotes inline in the column declaration. --->
<script type="text/x-kendo-template" id="ipAddressTemplate">
	<a href="https://www.ipalyzer.com/#: IpAddress #" target="_blank" rel="noopener noreferrer">#: IpAddress #</a>
</script>
<script type="text/x-kendo-template" id="httpUserAgentTemplate">
	<a href="https://gs.statcounter.com/detect?useragent=#: HttpUserAgent #" target="_blank" rel="noopener noreferrer">#: HttpUserAgent #</a>
</script>

<script>
	$(document).ready(function() {

		adminLogDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getAdminLogForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				}
			},
			cache: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					<!--- Note: AdminLog rows have no natural unique id field returned by the query, so we fall back to the grid's own row index. This grid is read only, so a synthetic id (never sent back to the server) is fine here. --->
					id: "uid",
					fields: {
						FullName: { type: "string", editable: false, nullable: false },
						IpAddress: { type: "string", editable: false, nullable: false },
						HttpUserAgent: { type: "string", editable: false, nullable: false },
						Date: { type: "string", editable: false, nullable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: adminLogDs,
			<cfif session.isMobile>mobile: true,</cfif>
			height: 725,
			navigatable: true,
			filterable: true,
			sortable: {
				mode: "multiple",
				allowUnsort: true,
				showIndexes: true
			},
			pageable: {
				pageSizes: [10,20,50,100,"All"],
				refresh: true
			},
			groupable: true,
			selectable: "<cfif session.isMobile>cell<cfelse>multiple cell</cfif>",
			allowCopy: true,
			reorderable: true,
			resizable: true,
			columnMenu: true,
			columns: [{
				field: "FullName",
				title: "User",
				filterable: true,
				width: "<cfif session.isMobile>34<cfelse>20</cfif>%"
			}, {
				field: "IpAddress",
				title: "IP Address",
				filterable: true,
				width: "<cfif session.isMobile>33<cfelse>25</cfif>%",
				template: kendo.template($("#ipAddressTemplate").html())
			<cfif not session.isMobile>}, {
				field: "HttpUserAgent",
				title: "User Agent",
				filterable: true,
				width: "35%",
				template: kendo.template($("#httpUserAgentTemplate").html())</cfif>
			}, {
				field: "Date",
				title: "Date",
				filterable: true,
				width: "<cfif session.isMobile>33<cfelse>20</cfif>%",
				template: "#= dayjs(Date).format('MM/DD/YYYY h:mm A') #"
			}]
		});

	});//document ready
</script>

</body>
</html>
