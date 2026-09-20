<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/rating.cfm -- votes/reactions grid. Read only except for a
	delete (remove vote) action. There is no dedicated *ViaKendoGrid delete endpoint for reactions,
	so this reuses the existing deleteReactionViaJsGrid endpoint directly (it just needs postRatingId
	+ csrfToken, which works fine called from either grid library) via a custom command button
	instead of Kendo's built in destroy transport, using the same ExtYesNoDialog confirm pattern
	used elsewhere in this app rather than jsGrid's deleteConfirm option. --->
<cfset gridName = "ratingGrid">
<cfparam name="pageTitle" default="" type="string">
<cfset getUrl = application.baseUrl & '/common/cfc/ProxyController.cfc?method=getReactionsForGrid&gridType=kendo'>
<cfif structKeyExists(URL, "optArgs") and isNumeric(URL.optArgs) and URL.optArgs gt 0>
	<cfset getUrl = getUrl & '&ipAddressId=' & URL.optArgs>
	<cfset pageTitle = "Reactions By IP">
</cfif>
<cfset getUrl = getUrl & '&csrfToken=' & csrfToken>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<cfif len(pageTitle)><h2><cfoutput>#pageTitle#</cfoutput></h2></cfif>
	<p>All columns are sortable and searchable/filterable. Click the delete icon on a row to remove that vote.</p>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="anonymousUserIdTemplate">
	<a href="javascript:createAdminInterfaceWindow(63, #: AnonymousUserId #);">#: AnonymousUserId #</a>
</script>
<script type="text/x-kendo-template" id="ipAddressTemplate">
	<a href="https://www.ipalyzer.com/#: IpAddress #" target="_blank" rel="noopener noreferrer">#: IpAddress #</a>
</script>
<script type="text/x-kendo-template" id="titleTemplate">
	<a href="javascript:createAdminInterfaceWindow(6, #: PostId #);">#: Title #</a>
</script>
<cfif not session.isMobile>
<script type="text/x-kendo-template" id="httpUserAgentTemplate">
	<a href="https://gs.statcounter.com/detect?useragent=#: HttpUserAgent #" target="_blank" rel="noopener noreferrer">#: HttpUserAgent #</a>
</script>
</cfif>

<script>
	function deleteReaction(postRatingId) {
		$.when(kendo.ui.ExtYesNoDialog.show({ title: "Confirm Delete", message: "Do you really want to delete this vote?", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
		).done(function(response) {
			if (response['button'] == 'Yes') {
				$.ajax({
					type: "post",
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteReactionViaJsGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					data: { postRatingId: postRatingId },
					dataType: "json",
					cache: false
				}).then(function(result) {
					ratingDs.read();
				}).fail(function(jqXHR, textStatus, error) {
					if (jqXHR.status === 403) {
						createLoginWindow();
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the deleteReactionViaJsGrid function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
							).done(function() {});
					}
				});
			}
		});
	}

	$(document).ready(function() {

		ratingDs = new kendo.data.DataSource({
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
					id: "PostRatingId",
					fields: {
						PostRatingId: { type: "number", editable: false, nullable: false },
						AnonymousUserId: { type: "number", editable: false, nullable: true },
						IpAddress: { type: "string", editable: false, nullable: true },
						Title: { type: "string", editable: false, nullable: true },
						PostId: { type: "number", editable: false, nullable: true },
						HttpUserAgent: { type: "string", editable: false, nullable: true },
						Helpful: { type: "boolean", editable: false, nullable: true },
						UnHelpful: { type: "boolean", editable: false, nullable: true },
						Date: { type: "string", editable: false, nullable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: ratingDs,
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
				field: "AnonymousUserId",
				title: "UserId",
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%",
				template: kendo.template($("#anonymousUserIdTemplate").html())
			}, {
				field: "IpAddress",
				title: "IP Address",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%",
				template: kendo.template($("#ipAddressTemplate").html())
			}, {
				field: "Title",
				title: "Post",
				filterable: true,
				width: "<cfif session.isMobile>25<cfelse>20</cfif>%",
				template: kendo.template($("#titleTemplate").html())
			<cfif not session.isMobile>}, {
				field: "HttpUserAgent",
				title: "User Agent",
				filterable: true,
				width: "25%",
				template: kendo.template($("#httpUserAgentTemplate").html())</cfif>
			}, {
				field: "Helpful",
				title: "Like",
				filterable: true,
				width: "<cfif session.isMobile>10<cfelse>5</cfif>%",
				template: "#= Helpful ? 'Yes' : 'No' #"
			}, {
				field: "UnHelpful",
				title: "Dislike",
				filterable: true,
				width: "<cfif session.isMobile>10<cfelse>5</cfif>%",
				template: "#= UnHelpful ? 'Yes' : 'No' #"
			}, {
				field: "Date",
				title: "Date",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%",
				template: "#= dayjs(Date).format('MM/DD/YYYY h:mm A') #"
			}, {
				command: [{
					name: "destroy",
					text: "",
					click: function(e) {
						e.preventDefault();
						var row = $(e.target).closest("tr");
						var item = this.dataItem(row);
						deleteReaction(item.PostRatingId);
					}
				}],
				title: "&nbsp;",
				width: "<cfif session.isMobile>10<cfelse>5</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
