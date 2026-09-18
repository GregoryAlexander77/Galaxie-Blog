<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/errorLog.cfm. Every field is read only (the jsGrid twin
	declares IsBot as "editing: true" but never wires up a controller.updateItem handler and no
	update endpoint exists in ProxyController.cfc for it, so that flag has never actually been
	functional -- this grid replicates what the jsGrid version actually does today, not the
	vestigial edit flag) except for row deletion, via the destroy command column and
	deleteErrorLogViaKendoGrid.
	You can view this in a couple of ways: normally it shows every error, or -- when opened as
	createAdminInterfaceWindow(59, ipAddressId) -- it's filtered down to just that IP's errors. --->
<cfset gridName = "errorLogGrid">
<cfparam name="pageTitle" default="" type="string">
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getErrorLogForGrid&gridType=kendo'>
<cfif structKeyExists(URL, "optArgs") and isNumeric(URL.optArgs) and URL.optArgs gt 0>
	<cfset getUrl = getUrl & '&ipAddressId=' & URL.optArgs>
	<cfset pageTitle = "Error Log By IP">
</cfif>
<cfset getUrl = getUrl & '&csrfToken=' & csrfToken>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<cfif len(pageTitle)><h2><cfoutput>#pageTitle#</cfoutput></h2></cfif>
	<p>All columns are sortable and searchable/filterable. Click on the ID to see the error detail, or the IP to see every error from that IP. Note: to conserve resources, this query only returns the last 10000 rows of data. However, all of the data inside the retention period specified in the blog options interface is intact in the Error table in the database if you need to perform further manual analysis.</p>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="errorIdTemplate">
	<a href="javascript:createAdminInterfaceWindow(60, #: ErrorLogId #);">#: ErrorLogId #</a>
</script>
<cfif not session.isMobile>
<script type="text/x-kendo-template" id="ipAddressTemplate">
	<a href="javascript:createAdminInterfaceWindow(59, #: IpAddressId #);">#: IpAddress #</a>
</script>
</cfif>

<script>
	$(document).ready(function() {

		errorLogDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#getUrl#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteErrorLogViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "destroy") {
						return { models: kendo.stringify([options]) };
					}
				}
			},
			cache: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "ErrorLogId",
					fields: {
						ErrorLogId: { type: "number", editable: false, nullable: false },
						ErrorMessage: { type: "string", editable: false, nullable: false },
						IpAddress: { type: "string", editable: false, nullable: true },
						IpAddressId: { type: "number", editable: false, nullable: true },
						NumErrors: { type: "number", editable: false, nullable: true },
						Resolved: { type: "string", editable: false, nullable: true },
						IsBot: { type: "boolean", editable: false, nullable: true },
						Date: { type: "string", editable: false, nullable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: errorLogDs,
			editable: true,
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
				field: "ErrorLogId",
				title: "Error Id",
				filterable: true,
				width: "8%",
				template: kendo.template($("#errorIdTemplate").html())
			}, {
				field: "ErrorMessage",
				title: "Error Message",
				filterable: true,
				width: "<cfif session.isMobile>62<cfelse>50</cfif>%"
			<cfif not session.isMobile>}, {
				field: "IpAddress",
				title: "IP Address",
				filterable: true,
				width: "12%",
				template: kendo.template($("#ipAddressTemplate").html())
			}, {
				field: "NumErrors",
				title: "Hits",
				filterable: true,
				width: "6%"
			}, {
				field: "Resolved",
				title: "Resolved",
				filterable: true,
				width: "6%"
			}, {
				field: "IsBot",
				title: "Bot?",
				filterable: true,
				width: "6%",
				template: "#= IsBot ? 'Yes' : 'No' #"</cfif>
			}, {
				field: "Date",
				title: "Date",
				filterable: true,
				width: "<cfif session.isMobile>30<cfelse>12</cfif>%",
				template: "#= dayjs(Date).format('MM/DD/YYYY h:mm A') #"
			}, {
				command: ["destroy"],
				title: "&nbsp;",
				width: "<cfif session.isMobile>20<cfelse>8</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
