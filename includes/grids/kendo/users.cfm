<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/users.cfm. FirstName/LastName are inline editable (batch:false,
	single-row updateUserViaJsGrid, same reasoning as categories.cfm/subscribers.cfm). Delete reuses
	the already-correct deleteUserViaKendoGrid. Note: updateUserViaJsGrid only accepts csrfToken,
	userId, firstName, lastName, email -- it has no userName/active arguments even though the jsGrid
	version's client code sends them; those extra fields are simply not used server-side (and, per
	this file's own June-2025 CF14 strict-argument-matching comments elsewhere, sending arguments a
	remote function doesn't declare can itself throw an error). This Kendo version only sends the
	fields the function actually declares. --->
<cfset gridName = "usersGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>All columns are sortable and searchable/filterable. To change a user's name, edit the First/Last Name cell and click Save on the toolbar. Click the user name to view full user details.</p>
	<button id="newUserBtn" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(7,'','addUser');">Create New User</button>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="userNameTemplate">
	<a href="javascript:createAdminInterfaceWindow(7, #: UserId #, 'editUser');">#: UserName #</a>
</script>

<script>
	$(document).ready(function() {

		usersDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getUsersForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updateUserViaJsGrid",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteUserViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation === "update") {
						return {
							csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
							userId: options.UserId,
							firstName: options.FirstName,
							lastName: options.LastName,
							email: options.Email
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
					id: "UserId",
					fields: {
						UserId: { type: "number", editable: false, nullable: false },
						UserName: { type: "string", editable: false, nullable: false },
						FirstName: { type: "string", editable: true, nullable: false },
						LastName: { type: "string", editable: true, nullable: false },
						Email: { type: "string", editable: false, nullable: true },
						Date: { type: "string", editable: false, nullable: true }
					}
				}
			}
		});

		<!--- If updateUserViaJsGrid reports a validation failure (e.g. duplicate email), show it and reload to discard the bad edit. --->
		usersDs.bind("requestEnd", function(e) {
			if (e.type === "update" && e.response && !e.response.success) {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error saving user", message: e.response.errorMessage, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "125px" })
					).done(function() { usersDs.read(); });
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: usersDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "users.xlsx",
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
				field: "UserName",
				title: "User Name",
				filterable: true,
				width: "<cfif session.isMobile>20<cfelse>20</cfif>%",
				template: kendo.template($("#userNameTemplate").html())
			}, {
				field: "FirstName",
				title: "First Name",
				filterable: true,
				width: "<cfif session.isMobile>30<cfelse>20</cfif>%"
			}, {
				field: "LastName",
				title: "Last Name",
				filterable: true,
				width: "<cfif session.isMobile>30<cfelse>20</cfif>%"
			<cfif not session.isMobile>}, {
				field: "Email",
				title: "Email",
				filterable: true,
				width: "20%"
			}, {
				field: "Date",
				title: "Created",
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
