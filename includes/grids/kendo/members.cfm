<!doctype html>
<cfsilent>
<!--- Kendo Grid for the Members list (window 97, 2026-10-17), shown when there are more than 10 people; the jsGrid version is
	../jsGrid/members.cfm. Read-only: a member's name and Open show them (window 98). The filter buttons above the grid
	(members.cfm) call membersGridFilter(key). --->
<cfset gridName = "membersGrid">
</cfsilent>
<html>
<head></head>
<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="memberNameTemplate">
	# if (MemberId > 0) { #<a href="javascript:createAdminInterfaceWindow(98, #: MemberId #);">#: Name #</a># } else { ##: Name ## } #<br><a href="mailto:#: Email #">#: Email #</a>
</script>

<script>
	<!--- The filter buttons above the grid: Members, Subscribers, Bookings and so on. --->
	function membersGridFilter(key) {
		var grid = $("#<cfoutput>#gridName#</cfoutput>").data("kendoGrid");
		if (!grid) { return; }
		if (key === "all") {
			grid.dataSource.filter({});
		} else {
			grid.dataSource.filter({ field: "Filters", operator: "contains", value: key });
		}
	}

	$(document).ready(function() {

		membersDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getPeopleForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					return {};
				}
			},
			cache: false,
			batch: false,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "Email",
					fields: {
						Email: { type: "string", editable: false, nullable: false },
						MemberId: { type: "number", editable: false, nullable: false },
						Name: { type: "string", editable: false, nullable: true },
						Labels: { type: "string", editable: false, nullable: true },
						LastActivity: { type: "string", editable: false, nullable: true },
						LastActivityDate: { type: "string", editable: false, nullable: true },
						Since: { type: "string", editable: false, nullable: true },
						Filters: { type: "string", editable: false, nullable: true }
					}
				}
			},
			sort: { field: "LastActivityDate", dir: "desc" }
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: membersDs,
			editable: false,
			<cfif session.isMobile>mobile: true,</cfif>
			height: 500,
			navigatable: true,
			filterable: true,
			sortable: true,
			pageable: { pageSizes: [10,20,50,"All"], refresh: true },
			resizable: true,
			columns: [{
				field: "Name",
				title: "Name",
				width: "<cfif session.isMobile>45<cfelse>27</cfif>%",
				template: kendo.template($("#memberNameTemplate").html())
			}, {
				field: "Labels",
				title: "What they've done",
				width: "<cfif session.isMobile>35<cfelse>25</cfif>%"
			<cfif not session.isMobile>}, {
				field: "LastActivity",
				title: "Last activity",
				<!--- Sorts by the date, not the words. --->
				sortable: { compare: function(a, b) { return (a.LastActivityDate || "").localeCompare(b.LastActivityDate || ""); } }
			}, {
				field: "Since",
				title: "Since",
				width: "10%"</cfif>
			}, {
				command: [{
					name: "openMember",
					text: "Open",
					visible: function(item) { return item.MemberId > 0; },
					click: function(e) {
						e.preventDefault();
						var item = this.dataItem($(e.currentTarget).closest("tr"));
						createAdminInterfaceWindow(98, item.MemberId);
					}
				}],
				title: "&nbsp;",
				width: "<cfif session.isMobile>20<cfelse>10</cfif>%"
			}]
		});

	});//document ready
</script>

</body>
</html>
