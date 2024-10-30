
	<input type="hidden" id="sidebarPanelState" name="sidebarPanelState" value="initial"/>
	<!--- Side bar is to the right of the main panel container. It is also used as a responsive panel below when the screen size is small. We will not include it if the break point is not 0 or is equal or above 50000 --->
	<cfif breakpoint gt 0>
		<div id="sidebar">
			<!---Suppply the sideBarType argument before loading the side bar--->
			<cfmodule template="#application.baseUrl#/includes/layers/sidebar.cfm" sideBarType="div" scriptTypeString="#scriptTypeString#" kendoTheme="#kendoTheme#" modernTheme="#modernTheme#" darkTheme="#darktheme#">
		</div><!---<nav id="sidebar">--->
		</cfif>
	</div><!---<div class="mainPanel hiddenOnNarrow">--->
	<!--- Side bar is to the right of the main panel container. It is also used as a responsive panel below when the screen size is small. --->
	<nav id="sidebarPanel" class="k-content">
		<div id="sidebarPanelWrapper" name="sidebarPanelWrapper" class="flexScroll">
			<!---Suppply the sideBarType argument before loading the side bar--->
			<cfmodule template="#application.baseUrl#/includes/layers/sidebar.cfm" sideBarType="panel" scriptTypeString="#scriptTypeString#" kendoTheme="#kendoTheme#" modernTheme="#modernTheme#" darkTheme="#darktheme#">
		</div>
	</nav><!---<nav id="sidebar">--->
	<!--- This script must be placed underneath the layer that is being used in order to effectively work as a flyout menu.--->
	<script type="<cfoutput>#scriptTypeString#</cfoutput>">
		$(document).ready(function() {	
			$("#sidebarPanel").kendoResponsivePanel({
				// On mobile devices, always achieve the breakpoint by setting it to 0, otherwise, use the breakpoint setting that is defined in the administrative interface.
				breakpoint: breakpoint,
				orientation: "left",
				autoClose: true,// Note: autoclose true will cause the panel to fly off to the left. It looks a bit funny, but it works.. 
				open: onSidebarOpen,
				close: onSidebarClose
			})
		});//..document.ready
	</script>