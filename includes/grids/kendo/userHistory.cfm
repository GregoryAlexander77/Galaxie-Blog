<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/userHistory.cfm -- read only login history for a single user
	(username passed in via URL.optArgs from createAdminInterfaceWindow(10, username)). --->
<cfset gridName = "userHistoryGrid">
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getUserHistoryForGrid&gridType=kendo&username=' & urlEncodedFormat(URL.optArgs) & '&csrfToken=' & csrfToken>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>Login history for <cfoutput>#encodeForHTML(URL.optArgs)#</cfoutput>. All columns are sortable and searchable/filterable.</p>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<cfif not session.isMobile>
<script type="text/x-kendo-template" id="httpUserAgentTemplate">
	<a href="https://gs.statcounter.com/detect?useragent=#: HttpUserAgent #" target="_blank" rel="noopener noreferrer">#: HttpUserAgent #</a>
</script>
</cfif>

<script>
	$(document).ready(function() {

		userHistoryDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#getUrl#</cfoutput>",
					dataType: "json",
					method: "post"
				}
			},
			cache: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "uid",
					fields: {
						IpAddress: { type: "string", editable: false, nullable: false },
						HttpUserAgent: { type: "string", editable: false, nullable: true },
						LoginDate: { type: "string", editable: false, nullable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: userHistoryDs,
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
				field: "IpAddress",
				title: "IP Address",
				filterable: true,
				width: "<cfif session.isMobile>45<cfelse>30</cfif>%"
			<cfif not session.isMobile>}, {
				field: "HttpUserAgent",
				title: "User Agent",
				filterable: true,
				width: "45%",
				template: kendo.template($("#httpUserAgentTemplate").html())</cfif>
			}, {
				field: "LoginDate",
				title: "Date",
				filterable: true,
				width: "<cfif session.isMobile>55<cfelse>25</cfif>%",
				template: "#= dayjs(LoginDate).format('MM/DD/YYYY h:mm A') #"
			}]
		});

	});//document ready
</script>

</body>
</html>
