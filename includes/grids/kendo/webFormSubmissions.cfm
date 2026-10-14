<!doctype html>
<cfsilent>
<!--- Kendo Grid for a form's submissions (window 85, 2026-10-13); the jsGrid version is ../jsGrid/webFormSubmissions.cfm.
	Expects webFormId to be set by webFormSubmissions.cfm. Read-only except for Delete (ProxyController.cfc's
	deleteWebFormSubmission), which removes a submission for good. ValuesHtml is HTML-encoded on the server. --->
<cfset gridName = "webFormSubmissionsGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
</head>
<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script>
	$(document).ready(function() {

		webFormSubmissionsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getWebFormSubmissionsForGrid&gridType=kendo&webFormId=<cfoutput>#webFormId#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteWebFormSubmission",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "destroy") {
						return { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", webFormSubmissionId: options.WebFormSubmissionId };
					}
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>5<cfelse>10</cfif>,
			schema: {
				model: {
					id: "WebFormSubmissionId",
					fields: {
						WebFormSubmissionId: { type: "number", editable: false, nullable: false },
						Sent: { type: "string", editable: false, nullable: false },
						Name: { type: "string", editable: false, nullable: true },
						Email: { type: "string", editable: false, nullable: true },
						ValuesHtml: { type: "string", editable: false, nullable: true },
						ValuesText: { type: "string", editable: false, nullable: true }
					}
				}
			},
			sort: { field: "Sent", dir: "desc" }
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: webFormSubmissionsDs,
			editable: { mode: "inline", confirmation: "Delete this submission for good? This can't be undone." },
			<cfif session.isMobile>mobile: true,</cfif>
			height: 600,
			navigatable: true,
			filterable: true,
			sortable: true,
			pageable: { pageSizes: [10,25,50,100,"All"], refresh: true },
			resizable: true,
			columns: [{
				field: "Sent",
				title: "Sent",
				width: "<cfif session.isMobile>30<cfelse>14</cfif>%",
				template: "#= dayjs(Sent).format('MM/DD/YYYY h:mm A') #"
			<cfif not session.isMobile>}, {
				field: "Name",
				title: "Name",
				width: "14%"
			}, {
				field: "Email",
				title: "Email",
				width: "18%"</cfif>
			}, {
				<!--- Filtering searches the plain text of all the values; the cell shows them under their labels. --->
				field: "ValuesText",
				title: "Values",
				template: "#= ValuesHtml #"
			}, {
				command: ["destroy"],
				title: "&nbsp;",
				width: "<cfif session.isMobile>25<cfelse>10</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
