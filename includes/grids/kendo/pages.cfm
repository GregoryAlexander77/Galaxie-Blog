<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/pages.cfm. The post and page grids are nearly identical (both
	built on getPostsForGrid/updatePostViaKendoGrid/removePostViaKendoGrid) but kept as separate
	templates just like the jsGrid versions are, differing in the showPages/showBlogPosts flags,
	wording, and the fact that pages never prompt to email subscribers on release. --->
<cfset gridName = "pagesGrid">
<cfset showPages = true>
<cfset showBlogPosts = false>
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p><cfif not session.isMobile>All columns are sortable and searchable/filterable. Pages are different than blog posts as they don't have a date and are not placed on the main blog page. To release a page, check the Released checkbox and click Save on the toolbar.</cfif> Click on a page's title or body to view its details.</p>
	<button id="newPageBtn" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(24,'newPage');">Create New Page</button>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="titleTemplate">
	<a href="javascript:createAdminInterfaceWindow(6, #: PostId #);">#: Title #</a>
</script>
<cfif not session.isMobile>
<script type="text/x-kendo-template" id="bodyTemplate">
	<a href="javascript:createAdminInterfaceWindow(6, #: PostId #);">#= truncateWithEllipses(removeStrBetween(Body, "postData"), 125) #</a>
</script>
</cfif>

<script>
	$(document).ready(function() {

		pagesDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getPostsForGrid&gridType=kendo&showPages=<cfoutput>#showPages#</cfoutput>&showBlogPosts=<cfoutput>#showBlogPosts#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updatePostViaKendoGrid&emailSubscriber=false&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				destroy: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=removePostViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
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
					id: "PostId",
					fields: {
						PostId: { type: "number", editable: false, nullable: false },
						FullName: { type: "string", editable: false, nullable: true },
						Title: { type: "string", editable: false, nullable: false },
						Body: { type: "string", editable: false, nullable: true },
						BlogSortDate: { type: "string", editable: false, nullable: true },
						DatePosted: { type: "string", editable: false, nullable: true },
						ViewsPerDay: { type: "number", editable: false, nullable: true },
						Released: { type: "boolean", editable: true, nullable: false }
					}
				}
			}
		});
		<!--- Note: pages never prompt to email subscribers on release (emailSubscriber=false above), same as the jsGrid version. --->

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: pagesDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "pages.xlsx",
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
				field: "PostId",
				title: "I.D.",
				hidden: true,
				filterable: false
			}, {
				field: "FullName",
				title: "Author",
				filterable: true,
				width: "<cfif session.isMobile>25<cfelse>10</cfif>%"
			}, {
				field: "Title",
				title: "Title",
				filterable: true,
				width: "<cfif session.isMobile>40<cfelse>20</cfif>%",
				template: kendo.template($("#titleTemplate").html())
			<cfif not session.isMobile>}, {
				field: "Body",
				title: "Page",
				filterable: true,
				width: "28%",
				template: kendo.template($("#bodyTemplate").html())
			}, {
				field: "BlogSortDate",
				title: "Sort Date",
				filterable: true,
				width: "8%",
				template: "#= BlogSortDate ? dayjs(BlogSortDate).format('MM/DD/YYYY h:mm A') : '' #"
			}, {
				field: "DatePosted",
				title: "Posted",
				filterable: true,
				width: "8%",
				template: "#= DatePosted ? dayjs(DatePosted).format('MM/DD/YYYY h:mm A') : '' #"
			}, {
				field: "ViewsPerDay",
				title: "Monthly Views",
				filterable: true,
				width: "8%"</cfif>
			}, {
				field: "Released",
				<cfif session.isMobile>headerTemplate: '<i class="fas fa-thumbs-up"></i>',<cfelse>title: "Released",</cfif>
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>8</cfif>%"
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
