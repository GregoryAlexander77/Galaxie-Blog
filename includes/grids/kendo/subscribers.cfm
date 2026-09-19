<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/subscribers.cfm. Like categories.cfm, this uses the existing
	single-row updateSubscriberViaJsGrid endpoint (batch:false + parameterMap flattening) since no
	batch *ViaKendoGrid update endpoint exists for subscribers, and reuses the now-fixed
	deleteSubscriberViaKendoGrid for delete. Can optionally be filtered to a single IP address, same
	as createAdminInterfaceWindow(26, ipAddressId). --->
<cfset gridName = "subscribersGrid">
<cfparam name="pageTitle" default="" type="string">
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getSubscribersForGrid&gridType=kendo&verifiedOnly=false'>
<cfif structKeyExists(URL, "optArgs") and isNumeric(URL.optArgs) and URL.optArgs gt 0>
	<cfset getUrl = getUrl & '&ipAddressId=' & URL.optArgs>
	<cfset pageTitle = "Subscribers By IP">
</cfif>
<cfset getUrl = getUrl & '&csrfToken=' & csrfToken>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<cfif len(pageTitle)><h2><cfoutput>#pageTitle#</cfoutput></h2></cfif>
	<p>All columns are sortable and searchable/filterable. To verify a subscription without the visitor having to respond to the confirmation email, check Verified and click Save on the toolbar.</p>
	<button id="newSubscriberBtn" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(27,'addSubscriber');">Create New Subscriber</button>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script>
	$(document).ready(function() {

		subscribersDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#getUrl#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updateSubscriberViaJsGrid",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteSubscriberViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "update") {
						return {
							csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
							subscriberId: options.SubscriberId,
							subscriberEmail: options.SubscriberEmail,
							subscriberToken: options.SubscriberToken,
							subscriberVerified: options.SubscriberVerified
						};
					}
					if (operation === "destroy") {
						return { models: kendo.stringify([options]) };
					}
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "SubscriberId",
					fields: {
						SubscriberId: { type: "number", editable: false, nullable: false },
						SubscriberEmail: { type: "string", editable: true, nullable: false },
						SubscriberToken: { type: "string", editable: true, nullable: true },
						SubscribeAll: { type: "boolean", editable: true, nullable: true },
						SubscriberVerified: { type: "boolean", editable: true, nullable: true },
						Date: { type: "string", editable: false, nullable: true }
					}
				}
			}
		});

		<!--- If updateSubscriberViaJsGrid reports a validation failure, show it and reload to discard the bad edit. --->
		subscribersDs.bind("requestEnd", function(e) {
			if (e.type === "update" && e.response && !e.response.success) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving subscriber", message: e.response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" })
					).done(function() { subscribersDs.read(); });
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: subscribersDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "subscribers.xlsx",
				filterable: true,
				allPages: true
			},
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
				field: "SubscriberEmail",
				title: "Email",
				filterable: true,
				width: "<cfif session.isMobile>45<cfelse>30</cfif>%"
			<cfif not session.isMobile>}, {
				field: "SubscriberToken",
				title: "Token",
				filterable: true,
				width: "30%"</cfif>
			}, {
				field: "SubscribeAll",
				title: "New Posts",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%"
			}, {
				field: "SubscriberVerified",
				title: "Verified",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%"
			<cfif not session.isMobile>}, {
				field: "Date",
				title: "Date",
				filterable: true,
				width: "10%",
				template: "#= Date ? dayjs(Date).format('MM/DD/YYYY h:mm A') : '' #"</cfif>
			}, {
				command: ["destroy"],
				title: "&nbsp;",
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
