<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/emailLog.cfm (2026-10-31): the Email Log (window 118), what the blog sent in the last 90 days.
Read-only; Kendo filters and sorts in the browser (ProxyController getEmailLogForGrid, EmailLog.cfc). --->
<cfset gridName = "emailLogGrid">
<cfparam name="pageTitle" default="" type="string">
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getEmailLogForGrid&gridType=kendo&csrfToken=' & csrfToken>
<cfset exportUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=exportEmailLog&csrfToken=' & csrfToken>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>Every email the blog sent in the last 90 days, newest first. "Sent" means your mail server took it; a message it refuses later (a wrong address, a full mailbox) is reported to your blog's fail-to address, not here. Messages themselves are never kept. All columns can be sorted and filtered.</p>
</head>

<body>

<cfinclude template="../exportButton.cfm">
<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script>
	$(document).ready(function() {

		var emailLogDs = new kendo.data.DataSource({
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
					id: "EmailLogId",
					fields: {
						EmailLogId: { type: "number", editable: false },
						Sent: { type: "date", editable: false },
						ToAddress: { type: "string", editable: false },
						Kind: { type: "string", editable: false },
						Subject: { type: "string", editable: false },
						Status: { type: "string", editable: false },
						ErrorMessage: { type: "string", editable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: emailLogDs,
			<cfif session.isMobile>mobile: true,</cfif>
			height: 725,
			filterable: true,
			sortable: { mode: "multiple", allowUnsort: true, showIndexes: true },
			pageable: { pageSizes: [10,20,50,100,"All"], refresh: true },
			groupable: true,
			reorderable: true,
			resizable: true,
			columnMenu: true,
			columns: [{
				field: "Sent",
				title: "Sent",
				width: "<cfif session.isMobile>25<cfelse>15</cfif>%",
				template: "#= dayjs(Sent).format('MM/DD/YYYY h:mm A') #"
			}, {
				field: "ToAddress",
				title: "To",
				width: "<cfif session.isMobile>35<cfelse>22</cfif>%"
			<cfif not session.isMobile>}, {
				field: "Kind",
				title: "Kind",
				width: "12%"</cfif>
			}, {
				field: "Subject",
				title: "Subject",
				width: "<cfif session.isMobile>28<cfelse>39</cfif>%"
			}, {
				field: "Status",
				title: "Status",
				width: "<cfif session.isMobile>12<cfelse>12</cfif>%",
				<!--- A failed email shows in red, with the mail server's answer on hover. --->
				template: function (r) {
					return r.Status === "Failed"
						? '<span style="color:#b00020;font-weight:bold" title="' + kendo.htmlEncode(r.ErrorMessage || "") + '">Failed</span>'
						: kendo.htmlEncode(r.Status || "");
				}
			}]
		});

	});//document ready
</script>

</body>
</html>
