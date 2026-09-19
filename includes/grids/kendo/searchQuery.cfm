<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/searchQuery.cfm -- replicates the same read-only search query
	log: a clickable AnonymousUserId (opens the visitor detail window, id 63), FullName, a clickable
	IpAddress (links to ipalyzer.com), a clickable HttpUserAgent (links to gs.statcounter.com), the
	SearchQuery terms themselves, and the Date. The Kendo Grid does not need its own paging/filtering
	logic on the server -- gridType=kendo makes getSearchQueryForGrid return a plain JSON array
	(instead of the {data:[...]} shape jsGrid needs) and the grid below paginates/sorts/filters it
	client side, same as every other Kendo grid in this app. No Kendo UI core library script tags are
	included here since the parent adminInterface.cfm / admin index page already loads Kendo (this
	template is injected into a Kendo Window via content: url, not loaded as its own document). --->
<cfset gridName = "searchQueryGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>All columns are sortable and searchable/filterable. Click on the User Id to see the visitor detail.</p>
</head>

<body>

<!--- Container for the grid --->
<div id="<cfoutput>#gridName#</cfoutput>"></div>

<!--- Kendo templates for the linked columns. Using a dedicated template avoids having to escape quotes inline in the column declaration. --->
<script type="text/x-kendo-template" id="anonymousUserIdTemplate">
	<a href="javascript:createAdminInterfaceWindow(63, #: AnonymousUserId #);">#: AnonymousUserId #</a>
</script>
<script type="text/x-kendo-template" id="ipAddressTemplate">
	<a href="https://www.ipalyzer.com/#: IpAddress #" target="_blank" rel="noopener noreferrer">#: IpAddress #</a>
</script>
<script type="text/x-kendo-template" id="httpUserAgentTemplate">
	<a href="https://gs.statcounter.com/detect?useragent=#: HttpUserAgent #" target="_blank" rel="noopener noreferrer">#: HttpUserAgent #</a>
</script>

<script>
	$(document).ready(function() {

		searchQueryDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getSearchQueryForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				}
			},
			cache: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					<!--- Note: SearchQuery rows have no natural unique id field returned by the query, so we fall back to the grid's own row index. This grid is read only, so a synthetic id (never sent back to the server) is fine here. --->
					id: "uid",
					fields: {
						AnonymousUserId: { type: "number", editable: false, nullable: true },
						FullName: { type: "string", editable: false, nullable: true },
						IpAddress: { type: "string", editable: false, nullable: false },
						HttpUserAgent: { type: "string", editable: false, nullable: false },
						SearchQuery: { type: "string", editable: false, nullable: false },
						Date: { type: "string", editable: false, nullable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: searchQueryDs,
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
				field: "AnonymousUserId",
				title: "User Id",
				filterable: true,
				width: "<cfif session.isMobile>10<cfelse>8</cfif>%",
				template: kendo.template($("#anonymousUserIdTemplate").html())
			}, {
				field: "FullName",
				title: "User",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>15</cfif>%"
			}, {
				field: "IpAddress",
				title: "IP Address",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>15</cfif>%",
				template: kendo.template($("#ipAddressTemplate").html())
			<cfif not session.isMobile>}, {
				field: "HttpUserAgent",
				title: "User Agent",
				filterable: true,
				width: "27%",
				template: kendo.template($("#httpUserAgentTemplate").html())</cfif>
			}, {
				field: "SearchQuery",
				title: "Search Terms",
				filterable: true,
				width: "<cfif session.isMobile>35<cfelse>25</cfif>%"
			}, {
				field: "Date",
				title: "Date",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%",
				template: "#= dayjs(Date).format('MM/DD/YYYY h:mm A') #"
			}]
		});

	});//document ready
</script>

</body>
</html>
