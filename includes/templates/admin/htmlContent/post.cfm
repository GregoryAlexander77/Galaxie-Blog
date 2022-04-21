<cfif not application.kendoCommercial>
	<!--- Include the stylesheet for the theme for jsGrid. The Kendo grid stylsheet will be included if we are using the commerial version of Kendo --->
	<cfinclude template="#application.baseUrl#/common/libs/jsGrid/kendoThemeCss.cfm">
</cfif>

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