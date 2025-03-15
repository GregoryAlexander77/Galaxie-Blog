<!DOCTYPE html>
<cfsilent>
<!--- This template serves to get recent comments, and all comments. The url.optArgs setting depends upon the URL.optArgs argument which is either recentComments or allComments. --->
<cfif URL.optArgs eq 'recentComments'>
	<cfset commentType = "recentComments">
<cfelse>
	<cfset commentType = "allComments">
</cfif>
<!--- This argument is not really needed, but here if this template is used as a standalone template for demonstration purposes. --->
<cfparam name="kendoTheme" default="default">
</cfsilent>
<html>
<head>
	<script type="text/javascript" src="<cfoutput>#application.blog.getRootUrl()#</cfoutput>/common/libs/dayjs/dayjs.min.js"></script>
</head>
<body>
<script src="//cdnjs.cloudflare.com/ajax/libs/jszip/2.4.0/jszip.min.js"></script>

<!--- Div where the grid will initialize. --->
<div id="commentsGrid"></div>
	
<!--- Kendo templates. These templates will be used in the post and comment columns in the grid. I could have used simple inline templates within the grid column declarations, however, its easier in a dedicated template as the qoutes need to be escaped. --->
<!--- Create a link to the post. For mobile clients, this will open up an editor window. For desktop it will direct to the link on the main blog page. --->
<script type="text/x-kendo-template" id="postTemplate">
<cfif session.isMobile>
	<a href="javascript:createAdminInterfaceWindow(2, #: CommentId #);" rel="noopener noreferrer"> rel="noopener noreferrer">#: PostTitle  #</a>
<cfelse>
	<a href="<cfoutput>#application.blog.getRootUrl()#</cfoutput>/index.cfm/#: makePostLink( DatePosted, PostAlias) #" target="_blank" rel="noopener noreferrer">#: PostTitle  #</a>
</cfif>
</script>
	
<cfsilent><!--- Create a link to the comment. Note: notice the #= var # instead of the #: surrounding the comment (ie #= truncateWithEllipses(Comment, 200) #). This encodes the html and displays it properly. This is the same as using encoding: false on the column definition when there is no template. Another way of saying this is that when we use #: var #, it will show the html tags instead of, let's say an image (ie <img src...). However, when we use #= var # it will display the image in the grid cell. ---></cfsilent>
<script type="text/x-kendo-template" id="commentTemplate">
<cfif session.isMobile>
	<a href="javascript:createAdminInterfaceWindow(2, #: CommentId #);" rel="noopener noreferrer">#= truncateWithEllipses(Comment, 25) #</a>
<cfelse>
	<a href="<cfoutput>#application.blog.getRootUrl()#</cfoutput>/index.cfm/#: makeCommentLink( DatePosted, PostAlias, CommentId) #" target="_blank" rel="noopener noreferrer">#= truncateWithEllipses(Comment, 200) #</a>
</cfif>
</script>
	
<script>
	$(document).ready(function() {

		commentsDs = new kendo.data.DataSource({
			// Determines which method and cfc to get and set data.
			transport: {
			   read:  {
					url: "<cfoutput>#application.blog.getRootUrl()#</cfoutput>/common/cfc/ProxyController.cfc?method=getCommentsForGrid&commentType=<cfoutput>#commentType#</cfoutput>&gridType=kendo", // the cfc component which processes the query and returns a json string. 
					dataType: "json", // Use json if the template is on the current server. If not, use jsonp for cross domain reads.
					method: "post" // Note: when the method is set to "get", the query will be cached by default. This is not ideal. 
				},
				update: {
                   	url: "<cfoutput>#application.blog.getRootUrl()#</cfoutput>/common/cfc/ProxyController.cfc?method=updateCommentViaKendoGrid", // the cfc component which processes upates the database. 
					dataType: "json",
					method: "post"
				},
				destroy: {
                   	url: "<cfoutput>#application.blog.getRootUrl()#</cfoutput>/common/cfc/ProxyController.cfc?method=deleteCommentViaKendoGrid", // the cfc component which processes deletions in the database. 
					dataType: "json",
					method: "post"
				},
				parameterMap: function(options, operation) {
					if (operation !== "read" && options.models) {
						return {models: kendo.stringify(options.models)};
					}
				}
			},
			cache: false,
			batch: true, // determines if changes will be send to the server individually or as batch. Note: the batch arg must be in the datasource declaration, and not in the grid. Otherwise, a post to the cfc will not be made. 
			pageSize: <cfif session.isMobile>7<cfelse>15</cfif>, // The number of rows within a grid.
			schema: {
				model: {
					id: "CommentId", // Note: in editiable grids- the id MUST be put in here, otherwise you will get a cryptic error 'Unable to get value of the property 'data': object is null or undefined'
					fields: {
						CommenterFullName: { type: "string", editable: false, nullable: false },
						PostTitle: { type: "string", editable: false, nullable: false },
						// Note: the date coming from the ColdFusion HQL query (hibernate) is not an actual date. its a string for some odd reason. For regular database queries, use date.
						DatePosted: { type: "string", editable: false, nullable: false },
						Comment: { type: "string", editable: false, nullable: false },
						// Create a template to show true and false next to the checkbox.
						Approved: { type: "boolean", editable: true, nullable: false, template: "#= BooleanVal ? 'true' : 'false' #" },
						Remove: { type: "boolean", editable: true, nullable: false, template: "#= BooleanVal ? 'true' : 'false' #" }
					}//fields:
				}//model:
			}//schema
		});//commentsDs = new kendo.data.DataSource

		$("#commentsGrid").kendoGrid({
			dataSource: commentsDs,
			// Edit arguments
			editable: true,
			// Toolbars. 
			toolbar: [ "save", "cancel" ],
			excel: {
				fileName: "comments.xlsx",
				proxyURL: "utilities/excelExport.cfm",
				filterable: true, 
				allPages: true
			},
			<cfif session.isMobile>mobile: true,</cfif>
			// General grid elements.
			height: 725,// Percentages will not work here.
			navigatable: true,
			filterable: true,
			sortable: {
				mode: "multiple",
				allowUnsort: true,
				showIndexes: true
			},
			pageable: {
				pageSizes: [10,20,50,100,"All"],
				refresh: true
			},
			groupable: true,
			<cfif session.isMobile>
			mobile: true,
			// Mobile clients can't have multiple selections and be able to scroll.
			</cfif>
			selectable: "<cfif session.isMobile>cell<cfelse>multiple cell</cfif>",
			allowCopy: true,
			reorderable: true,
			resizable: true,
			columnMenu: true,
			columns: [{
				// Columns
				field:"CommentId",
				title: "I.D.",
				hidden: true,
				filterable: false
			}, {
				field:"CommenterFullName",
				title: "Name",
				filterable: true,
				width: "<cfif session.isMobile>42<cfelse>25</cfif>%"
			<cfif not session.isMobile>}, {
				field:"PostTitle",
				title: "Post",
				filterable: true,
				width: "25%",
				template: kendo.template($("#postTemplate").html())
			}, {
				field:"DatePosted",
				title: "Date",
				filterable: true,
				width: "10%",
				// We are going to use moment.js to format this string. Note: the date coming from the ColdFusion HQL query is not an actual date.
				template: "#= dayjs(DatePosted).format('MM/DD/YYYY h:mm A') #"</cfif><!---<cfif not session.isMobile>--->
			}, {
				field:"Comment",
				title: "Comment",
				filterable: true,
				width: "<cfif session.isMobile>42<cfelse>40</cfif>%",
				template: kendo.template($("#commentTemplate").html())
			}, {
				field:"Approved",
				<cfif session.isMobile>// Here, we are using a Kendo header template to place a fontawesome icon in the column in order to preserve more space for mobile clients
				headerTemplate: '<i class="far fa-thumbs-up"></i>',
				<cfelse>title: "Approved",</cfif><!---<cfif not session.isMobile>--->
				filterable: true,
				width: "<cfif session.isMobile>15<cfelse>10</cfif>%"
			<!--- Only show the command button for non mobile clients. We just don't have the room for this on mobile devices. --->
			<cfif not session.isMobile>
			}, {
				command: 
					// Define multiple commands in an array
					[ 
						
						{ name: "edit", iconClass:"k-icon k-i-edit", text:"Edit", click: showCommentDetails },
					], 
					//headerTemplate: '<i class="fas fa-trash-alt"></i>',
					title: " ", 
					width: "155px"
			</cfif>
			}
			]// columns:
		});// $("#commentsGrid").kendoGrid({

	});//document ready
	
	// Department Detail window.  **********************************************************************************
	function showCommentDetails(e) {
		e.preventDefault();
		// Get the Id
		var dataItem = this.dataItem($(e.currentTarget).closest("tr"));
		selectedId = (dataItem['CommentId']);
		// Create the edit comment window and pass along the selected CommentId.
		createAdminInterfaceWindow(2, selectedId);
	}		
	
	// Helper functions (these need to be outside of the ready block)
	function makePostLink(datePosted, postAlias){
		var dt = new Date(datePosted);
		var yyyy = dt.getFullYear();
		var m = dt.getMonth()+1;
		var d = dt.getDay()+1;
		return yyyy + "/" + m + "/" + d + "/" + postAlias;
	}

	// The comment link is the post link with a ''#c' + commentId 
	function makeCommentLink(datePosted, postAlias, commentId){
		var postLink = makePostLink(datePosted, postAlias);
		var commentLink = postLink + "#c" + commentId;
		return commentLink;
	}
	
</script>
	
</html>