<!doctype html>
<cfsilent>
<!--- Kendo Grid version of ../jsGrid/posts.cfm. Note: the previous draft of this file was actually a
	stale, mislabeled copy of the comments grid (it called getCommentsForGrid, referenced an
	undefined "postsGrid" variable and an undefined "commentType" var) -- it never worked and has
	been replaced here with a real posts grid built against getPostsForGrid / updatePostViaKendoGrid
	(released checkbox, batch saved) / removePostViaKendoGrid (delete). Also reused for the Pages
	grid via cfcase 57 in adminInterface.cfm, same as the jsGrid version, by way of the showPages/
	showBlogPosts args. --->
<cfset gridName = "postsGrid">
<cfparam name="showPages" default="false">
<cfparam name="showBlogPosts" default="true">
</cfsilent>
<html>
<head><cfoutput>
	<script type="text/javascript" src="#application.baseUrl#/common/libs/dayjs/dayjs.min.js"></script>
	</cfoutput>
	<p><cfif not session.isMobile>All columns are sortable and searchable/filterable. Blog Posts have a date and are placed on the main blog page. To release a blog post, check the Released checkbox and click Save on the toolbar.</cfif> Click on a post's title or body to view its details.</p>
	<button id="newPostBtn" class="k-button k-primary" type="button" onclick="createAdminInterfaceWindow(24,'newPost');">Create New Post</button>
</head>

<body>

<div id="<cfoutput>#gridName#</cfoutput>"></div>

<script type="text/x-kendo-template" id="titleTemplate">
	<a href="javascript:createAdminInterfaceWindow(6, #: PostId #);">#: Title #</a>
</script>
<cfif not session.isMobile>
<cfsilent><!--- #= var # (unencoded) is used here since the Body field can contain markup/placeholder tags (like postData) that truncateWithEllipses/removeStrBetween need to operate on and that we want stripped rather than shown escaped. ---></cfsilent>
<script type="text/x-kendo-template" id="bodyTemplate">
	<a href="javascript:createAdminInterfaceWindow(6, #: PostId #);">#= truncateWithEllipses(removeStrBetween(Body, "postData"), 125) #</a>
</script>
</cfif>

<script>
	$(document).ready(function() {

		postsDs = new kendo.data.DataSource({
			transport: {
				read: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getPostsForGrid&gridType=kendo&showPages=<cfoutput>#showPages#</cfoutput>&showBlogPosts=<cfoutput>#showBlogPosts#</cfoutput>&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
					dataType: "json",
					method: "post"
				},
				update: {
					url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=updatePostViaKendoGrid&csrfToken=<cfoutput>#csrfToken#</cfoutput>",
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

		// Response from updatePostViaKendoGrid may ask us to prompt for emailing subscribers, same as the jsGrid version.
		postsDs.bind("requestEnd", function(e) {
			if (e.type === "update" && e.response && e.response.promptToEmailSubscriber) {
				$.when(kendo.ui.ExtYesNoDialog.show({
					title: "Email Post?",
					message: "Do you want to email this post to the subscribers?",
					icon: "k-ext-question",
					width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>",
					height: "215px"
				})).done(function(response) {
					if (response['button'] == 'Yes' && e.response.postId) {
						sendEmailToSubscribers(e.response.postId);
					}
				});
			}
		});

		$("#<cfoutput>#gridName#</cfoutput>").kendoGrid({
			dataSource: postsDs,
			editable: true,
			toolbar: ["save", "cancel"],
			excel: {
				fileName: "posts.xlsx",
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
				title: "Post",
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

	function sendEmailToSubscribers(postId) {
		$.ajax({
			type: 'post',
			url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=sendPostEmailToSubscribers",
			dataType: "json",
			data: {
				csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
				postId: postId
			}
		}).fail(function(jqXHR, textStatus, error) {
			if (jqXHR.status === 403) {
				createLoginWindow();
			} else {
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Error while consuming the sendPostEmailToSubscribers function", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })
					).done(function() {});
			}
		});
	}
</script>

</body>
</html>
