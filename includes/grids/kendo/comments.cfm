<!DOCTYPE html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/comments.cfm -- editable (Approved checkbox, batch saved via the
	toolbar save button) with a delete/destroy command and an "edit" command that opens the full
	comment detail window. Reuses the existing updateCommentViaKendoGrid / deleteCommentViaKendoGrid
	endpoints that were already built for this grid. Cleaned up from the prior draft of this file:
	switched application.blog.getRootUrl() to application.baseUrl (the convention used everywhere
	else in this app), and added the csrfToken that was missing from the read/update/destroy URLs
	(without it, updateCommentViaKendoGrid/deleteCommentViaKendoGrid would always fail their
	"Invalid token" check). Also dropped the recentComments/allComments URL.optArgs branch -- the
	jsGrid twin never uses it either (case 1 in adminInterface.cfm never passes optArgs here), so it
	was dead, unreachable logic that risked an undefined-variable error if optArgs was ever absent. --->
<cfset gridName = "commentsGrid">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p>All columns are sortable and searchable/filterable. Check/uncheck Approved and click Save on the toolbar to approve or unapprove comments (in bulk if you like). Click Edit to view the full comment and post details, or the delete icon to remove a comment.</p>
</head>
<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="postTemplate">
<cfif session.isMobile>
	<a href="javascript:createAdminInterfaceWindow(2, #: CommentId #);" rel="noopener noreferrer">#: PostTitle #</a>
<cfelse>
	<a href="javascript:createAdminInterfaceWindow(6, #: PostId #);" rel="noopener noreferrer">#: PostTitle #</a>
</cfif>
</script>

<cfsilent><!--- Note: #= var # (as opposed to #: var #) does not HTML-encode the output, which is needed here since truncateWithEllipses(Comment,...) may contain markup we want rendered rather than shown as escaped tags. ---></cfsilent>
<script type="text/x-kendo-template" id="commentTemplate">
	<a href="javascript:createAdminInterfaceWindow(2, #: CommentId #);" rel="noopener noreferrer">#= truncateWithEllipses(cleanCommentString(Comment), <cfif session.isMobile>25<cfelse>200</cfif>) #</a>
</script>

<script>
	<!--- Strip out embedded iframes/images/galleries before truncating, same as the jsGrid version's cleanCommentString. --->
	function cleanCommentString(str) {
		var str = removeStrBetween(str, 'iframe');
		var str = removeStrBetween(str, "img");
		return removeStrBetween(str, "gallery");
	}

	$(document).ready(function() {

		commentsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getCommentsForGrid&gridType=kendo&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updateCommentViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteCommentViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation !== "read" && options.models) {
						return { models: kendo.stringify(options.models) };
					}
				}
			},
			cache: false,
			batch: true,
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>,
			schema: {
				model: {
					id: "CommentId",
					fields: {
						CommentId: { type: "number", editable: false, nullable: false },
						CommenterFullName: { type: "string", editable: false, nullable: false },
						PostTitle: { type: "string", editable: false, nullable: true },
						PostId: { type: "number", editable: false, nullable: true },
						<!--- Note: the date coming from the ColdFusion HQL query (hibernate) is not an actual date, it's a string. --->
						DatePosted: { type: "string", editable: false, nullable: false },
						Comment: { type: "string", editable: false, nullable: false },
						Approved: { type: "boolean", editable: true, nullable: false }
					}
				}
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: commentsDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "comments.xlsx",
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
				field: "CommentId",
				title: "I.D.",
				hidden: true,
				filterable: false
			}, {
				field: "CommenterFullName",
				title: "Name",
				filterable: true,
				width: "<cfif session.isMobile>30<cfelse>15</cfif>%"
			<cfif not session.isMobile>}, {
				field: "PostTitle",
				title: "Post",
				filterable: true,
				width: "20%",
				template: kendo.template($("#postTemplate").html())
			}, {
				field: "DatePosted",
				title: "Date",
				filterable: true,
				width: "10%",
				template: "#= dayjs(DatePosted).format('MM/DD/YYYY h:mm A') #"</cfif>
			}, {
				field: "Comment",
				title: "Comment",
				filterable: true,
				width: "<cfif session.isMobile>45<cfelse>40</cfif>%",
				template: kendo.template($("#commentTemplate").html())
			}, {
				field: "Approved",
				<cfif session.isMobile>headerTemplate: '<i class="far fa-thumbs-up"></i>',<cfelse>title: "Approved",</cfif>
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%"
			}, {
				command: [
					{ name: "edit", iconClass: "k-icon k-i-edit", text: "View", click: showCommentDetails },
					"destroy"
				],
				title: "&nbsp;",
				width: "<cfif session.isMobile>10<cfelse>155</cfif>px"
			}]
		});

	});//document ready

	function showCommentDetails(e) {
		e.preventDefault();
		var dataItem = this.dataItem($(e.currentTarget).closest("tr"));
		createAdminInterfaceWindow(2, dataItem['CommentId']);
	}
</script>

</body>
</html>
