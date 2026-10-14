<!doctype html>
<cfsilent>
<!--- Kendo Grid for the Forms window (83, 2026-10-13); the jsGrid version is ../jsGrid/webForms.cfm. Read-only except for
	Delete: a form and its fields are edited in the form editor (window 84), opened from the title or Edit. Delete uses
	ProxyController.cfc's deleteWebForm, which also deletes the form's submissions. --->
<cfset gridName = "webFormsGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
</head>
<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="webFormTitleTemplate">
	<a href="javascript:createAdminInterfaceWindow(84, #: WebFormId #);">#: Title #</a>
</script>

<script>
	$(document).ready(function() {

		webFormsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getWebFormsForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteWebForm",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "destroy") {
						return { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", webFormId: options.WebFormId };
					}
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "WebFormId",
					fields: {
						WebFormId: { type: "number", editable: false, nullable: false },
						Title: { type: "string", editable: false, nullable: false },
						Alias: { type: "string", editable: false, nullable: false },
						FieldCount: { type: "number", editable: false, nullable: false },
						SubmissionCount: { type: "number", editable: false, nullable: false },
						LastSubmission: { type: "string", editable: false, nullable: true },
						Status: { type: "string", editable: false, nullable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: webFormsDs,
			editable: { mode: "inline", confirmation: "Delete this form? Its submissions are deleted too - export them first if you want to keep them. Any post that shows this form will show nothing in its place." },
			<cfif session.isMobile>mobile: true,</cfif>
			height: 560,
			navigatable: true,
			filterable: true,
			sortable: { mode: "multiple", allowUnsort: true, showIndexes: true },
			pageable: { pageSizes: [10,20,50,100,"All"], refresh: true },
			reorderable: true,
			resizable: true,
			columnMenu: true,
			columns: [{
				field: "Title",
				title: "Title",
				width: "<cfif session.isMobile>45<cfelse>26</cfif>%",
				template: kendo.template($("#webFormTitleTemplate").html())
			<cfif not session.isMobile>}, {
				field: "Alias",
				title: "Placed in posts as",
				width: "18%"
			}, {
				field: "FieldCount",
				title: "Fields",
				width: "7%"</cfif>
			}, {
				field: "SubmissionCount",
				title: "Submissions",
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%"
			<cfif not session.isMobile>}, {
				field: "LastSubmission",
				title: "Last submission",
				width: "14%",
				template: "#= LastSubmission ? dayjs(LastSubmission).format('MM/DD/YYYY h:mm A') : '' #"
			}, {
				field: "Status",
				title: "Status",
				width: "9%"</cfif>
			}, {
				command: [{
					name: "editWebForm",
					text: "Edit",
					click: function(e) {
						e.preventDefault();
						var item = this.dataItem($(e.currentTarget).closest("tr"));
						createAdminInterfaceWindow(84, item.WebFormId);
					}
				}, {
					name: "webFormSubmissions",
					text: "Submissions",
					click: function(e) {
						e.preventDefault();
						var item = this.dataItem($(e.currentTarget).closest("tr"));
						createAdminInterfaceWindow(85, item.WebFormId);
					}
				}, "destroy"],
				title: "&nbsp;",
				width: "<cfif session.isMobile>35<cfelse>16</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
