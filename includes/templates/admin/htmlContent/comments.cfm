<cfif not application.kendoCommercial>
	<!--- Include the stylesheet for the theme for jsGrid. The Kendo grid stylsheet will be included if we are using the commerial version of Kendo --->
	<cfinclude template="#application.baseUrl#/common/libs/jsGrid/kendoThemeCss.cfm">
</cfif>
	
<!--- Get any new recent comments and prompt the user if they want to review them. --->
<cfset recentCommentCount = application.blog.getRecentCommentCount()>
	
<!--- If there are any unapproved comments, launch a prompt asking the user if they want to review the comments. --->
<cfif recentCommentCount gt 0>
	
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	// Prompt the user
	$.when(kendo.ui.ExtYesNoDialog.show({ 
		title: "Unapproved Comments.", 
		message: "There are <cfoutput>#recentCommentCount#</cfoutput> comments that have not been approved. Do you want to review?",
		icon: "k-ext-question" })
	).done(function (response) {
		// If the user clicked 'yes', launch the grid.
		if (response['button'] == 'Yes'){// remember that js is case sensitive.
			// Launch the grid
			createAdminInterfaceWindow(1, 'recentComments');
		}
	});
</script>
</cfif><!---<cfif recentCommentCount gt 0>--->
	
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	// When we show the version upgrade details, we need to change the down arrow to an up arrow, and expand the comments div.
	function showUpgradeDetails(){
		// Expand the version details
		// When the ascending arrow is clicked on...
		$(".flexParent").on("click", "span.k-i-sort-desc-sm", function(e) {	
			// The content element
			var contentElement = 'upgradeDetails';
			// We also want to change the label. The label has the postId appended to it as well.
			var spanLabelElement = "#upgradeDetailsLabel";
			// Change the label text
			$(spanLabelElement).text("Show Details");
			// Change the class of the span (ie change the arrow direction), and expand the table.
			$(e.target)
				.removeClass("k-i-sort-desc-sm")
				.addClass("k-i-sort-asc-sm");
				// Expand the table. See 'fx effects' on the Terlik website.
				kendo.fx($("#" + contentElement)).expand("vertical").play();
		});

		// Collapse the widget. 
		// When the ascending arrow is clicked on...
		$(".flexParent").on("click", "span.k-i-sort-asc-sm", function(e) {
			// The content element
			var contentElement = 'upgradeDetails';
			// We also want to change the label. The lable has the postId appended to it as well.
			var spanLabelElement = "#upgradeDetailsLabel";
			// Change the label text
			$(spanLabelElement).text("Hide Details");
			// Change the class of the span (ie change the arrow direction), and shrink the table. I am doing this as I don't want to have to traverse the dom and write a bug.
			$(e.target)
				.removeClass("k-i-sort-asc-sm")
				.addClass("k-i-sort-desc-sm");
				// 'reverse' the table. See 'fx effects' on the Terlik website.
				kendo.fx($("#" + contentElement)).expand("vertical").stop().reverse();
		});

	}//..function showUpgradeDetails{
	
	$(document).ready(function() {
		// See if this version is out of date and show a summary of the blog version
		$("#latestVersionCheck").html("<p>Checking to see if your blog is up to date. Please wait.</p>").load("latestversioncheck.cfm?version=2&type=summary");<!---#application.blog.getVersion()#--->
		// Get the details
		$("#upgradeDetails").html("<p>Checking to see if your blog is up to date. Please wait.</p>").load("latestversioncheck.cfm?version=2&type=detail");<!---#application.blog.getVersion()#--->
	});//..document ready
</script>

<!--- Forms that hold state. --->
<!--- This is the sidebar responsive navigation panel that is triggered when the screen gets to a certain size. It is a duplicate of the sidebar div above, however, I can't properly style the sidebar the way that I want to within the blog content, so it is duplicated withoout the styles here. --->
<input type="hidden" id="sidebarPanelState" name="sidebarPanelState" value="initial"/>

<div id="adminPanel" class="panel">
	<cfsilent>
	<!--- 
	Wide div in the center left of page.
	Note: this is the div that will be refreshed when new entries are made. All of the dynamic elements within this div 
	are refreshed when there are new posts, however, any logic *outside* of this div are not refreshed- so we need to get the query, and supply the arguments.
	--->
	</cfsilent>
	
	<main class="wrapper transition-fade" id="swup">
		
		<div class="blogPost widget k-content" style="padding: 10px">
			<!--- This is our container that we will use to swap templates using SWUP. See my blog article if you want more information. --->
			<span id="innerContentContainer">
				<p class="bottomContent">
					Comments	
					<a href="index.cfm" data-swup="true">Home</a>

				</p><!---<p class="bottomContent">--->

			</div><!---<span id="innerContentContainer" class="transition-fade">--->
		</div><!---<div class="blogPost widget k-content">--->
	</main><!---<div class="mainContent">--->
</div><!---<div id="adminPanel" class="panel">--->