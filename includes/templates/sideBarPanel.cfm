
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
				close: onSidbarClose
			})
		});//..document.ready
		
		function onSidebarOpen(){
			// Change the value of the hidden input field to keep track of the state. We need some lag time and need to wait half of a second in order to allow the form to be changed, otherwise, we can't keep an accurate state and the panel will always think that the panel is closed and always open when you click on the button.
			// Display the sidebar 
			$('#sidebarPanel').fadeTo(0, 500, function(){
				$('#sidebarPanel').css('visibility','visible'); 
				// Set the state
				$('#sidebarPanelState').val("open");
			}); // duration, opacity, callback
		}
		
		// Event handler for close event for mobile devices. Note: this is not consumed with desktop devices.
		function onSidbarClose(){
			// Hide the sideBar
			$('sidebarPanel').css("visibility", "hidden"); 
			$('#sidebarPanel').fadeTo(500, 0, function(){
				// Change the value of the hidden input field to keep track of the state.
				$('#sidebarPanelState').val("closed");
			}); // duration, opacity, callback
		};

		// Function to open the side bar panel. We need to have the name of the div that is consuming this in order to adjust the top padding.
		function toggleSideBarPanel(layer){
			// Determine if we should open or close the sidebar.
			if (getSidebarPanelState() == 'open'){
				// On desktop, set visibility to hidden, otherwise there will be an animation on desktop devices that just looks wierd.
				if (!isMobile){
					$('#sidebarPanel').css("visibility", "hidden"); 
				}
				// Close the sidebar
				$("#sidebarPanel").kendoResponsivePanel("close");
				// Change the value of the hidden input field to keep track of the state.
				$('#sidebarPanelState').val("closed");
			} else { //if ($('#sidebarPanel').css('display') == 'none'){ 
				// Set the padding.
				setSidebarPadding(layer);
				// Open the sidebar
				$("#sidebarPanel").kendoResponsivePanel("open");
			}//if ($('#sidebarPanel').css('display') == 'none'){ 
		}
		
		// Sidebar helper functions.
		function getSidebarPanelState(){
			// Note: There is no way to automatically get the state, so I am toggling a hidden form with the state using the onSideBarOpen and close. Also, when the user clicks on the button the first time, there will be an error 'Uncaught TypeError: Cannot read property 'style' of undefined', so we will put this in a try block and iniitialize the panel if there is an error. 
			
			// The hidden sidebarPanelState form is set to initial on page load. We need to initialize the sidebarPanel css by setting the css to display: 'block'
			if ($('#sidebarPanelState').val() == 'initial'){
				// Set the display property to block. 
				$('#sidebarPanel').css('display', 'block');
				var sidebarPanelState = 'closed';
			} else if (($('#sidebarPanelState').val() == 'open')){
				var sidebarPanelState = 'open';
			} else if (($('#sidebarPanelState').val() == 'closed')){
				var sidebarPanelState = 'closed';
			} else {
				// Default state is closed (if anything goes wrong)
				var sidebarPanelState = 'closed';
			}
			return sidebarPanelState;
		}
		
		function setSidebarPadding(layer){
			if (layer == 1){// The topMenu element is invoking this method.
				// Set the margin (its different between mobile and desktop).
				if (isMobile){
					// The header is 105px for mobile.
					var marginTop = "105px";
				} else {
					// The header is 110 for desktop.
					var marginTop = "110px";
				}
				var marginTop = marginTop;

				// Set the css margin-top property. We want this underneath the calling menu.
				$('#sidebarPanel').css('margin-top', marginTop);
			} else if (layer == 2){// The fixed 'fixedNavHeader' element is invoking this method.
				// The height of the fixedMenu is 35 or 45 pixels depening upon device.
				// Set the margin (its different between mobile and desktop).
				if (isMobile){
					// The fixedNavHeader is 35 pixels for mobile. We'll add another 2px.
					var marginTop = "37px";
				} else {
					// We need to find out how far from the top we are to figure out how many pixes to drop the Kendo responsive panel down as we have scrolled away from the top of the screen.
					var pixelsToTop = window.pageYOffset || document.documentElement.scrollTop;
					// Add pixels to top to the height of the fixed nav header. The fixedNavHeader is 45 pixels for desktop. We are going to add 2px.
					var marginTop = (pixelsToTop + 47) + "px";
				}
				var marginTop = marginTop;
				// Set the margin-top css property. We want this underneath the calling menu.
				$('#sidebarPanel').css('margin-top', marginTop);
			}
		}//..function setSidebarPadding(layer){
	</script>