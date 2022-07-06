<cfsilent>
<!-- 
Script to adjust properties depending upon the device screen size. 
--->
</cfsilent>
<!-- Script to adjust properties depending upon the device screen size. I am putting the javascript and css front and center here in order to show exactly what I am doing. One of my main goals is to educate, and I don't want to obsfucate the code. -->
<script>
	
	// Set global vars. This is determined by the server (for now).
	isMobile = <cfoutput>#session.isMobile#</cfoutput>;
	// Get the breakpoint. This will be used to hide or show the side bar container ast the right of the page once the breakpoint value has been exceeded. The breakpoint can be set on the admin settings page. Note: the breakpoint is always set high on mobile as we don't have room for the sidebar.
	breakpoint = <cfoutput><cfif session.isMobile>50000<cfelse>#breakpoint#</cfif></cfoutput>;
	
	// Adjust the screen properties immediately.
	setScreenProperties();
	
	// Set a cookie indicating the screen size. We are going to use this to determine what interfaces to use when the the screens are narrow.
	// (setCookie(name,value,days))
	setCookie('screenWidth',$(window).width(),1);
	setCookie('screenHeight',$(window).height(),1);
	
	// Set the content width depending upon the screen size.
	function getContentWidthPercent() {
		
		// Mobile clients always have a 95% content width
		if (isMobile){
			var contentWidthPercent = 95;
			return contentWidthPercent + '%';
		} else {
			// Get the current dimensions.
			var desiredContentWidth = <cfoutput>#contentWidth#</cfoutput>;

			if (desiredContentWidth <= 70){
				var windowWidth = $(window).width();
				var windowHeight = $(window).height();

				// Set the content width depending upon the screen size.
				if (windowWidth < 980){
					var contentWidthPercent = desiredContentWidth + 40;
				} else if (windowWidth <= 1140){
					var contentWidthPercent = desiredContentWidth + 35;
				} else if (windowWidth <= 1280) {
					var contentWidthPercent = desiredContentWidth + 30;
				} else if (windowWidth <= 1400) {
					var contentWidthPercent = desiredContentWidth + 25;
				} else if (windowWidth <= 1500) {
					var contentWidthPercent = desiredContentWidth + 20;
				} else if (windowWidth <= 1600) {
					var contentWidthPercent = desiredContentWidth + 10;
				} else if (windowWidth <= 1700) {
					// Baseline
					var contentWidthPercent = desiredContentWidth;
				} else if (windowWidth <= 1920) {
					var contentWidthPercent = desiredContentWidth - 5;
				} else {
					var contentWidthPercent = desiredContentWidth - 10;
				}

				// The max contentWidthPercent should nver be higher than 95%
				if (contentWidthPercent > 95){
					var contentWidthPercent = 95;
				}
				// Return it with the percentage.
				return contentWidthPercent + '%';
			} else {
				return <cfoutput>"#contentWidth#%"</cfoutput>;
			}//..if (desiredContentWidth <= 70){
		}//..if (isMobile){
	} 
																   
	// Match everything up....
	function setScreenProperties(){
		var desiredContentWidth = <cfoutput>#contentWidth#</cfoutput>;
		var mainContainerWidth = <cfoutput>#mainContainerWidth#</cfoutput>;
		var windowWidth = $(window).width();
		var windowHeight = $(window).height();
		var contentWidthAsInt = getContentWidthPercent();
		var mainContainerWidth =  calculatePercent(mainContainerWidth, getContentPixelWidth())+"px"
		//alert('windowWidth:' + windowWidth);
		//alert('breakpoint:' + breakpoint);
		
		/* Notes:
		1) This may be converted into media queries in an upcoming version.
		2) This function will be invoked twice. Once upon page load, and then again when the body detects a resize. 
		3) This was designed to chose the appropriate image and maximize the size of the background image when the desktop or tablet has a wide screen size.
		
		The contentWidth applies to the header, and the outer container that holds the mainContainer and sidebar container elements. 
		Using contentWidth of 66% looks good when the screen width is at least 1600x900, which is the size of a 20 inch monitor.
		The 66% setting looks great with a 20 inch monitor. 
		80% works with 1280x768, which is a 19 inch monitor or a 14 Notebook. 
		I am adjusting the contentWidth via javascript to ensure proper rendering of the page.
		*/
		
		// Handle the sidebar and the sideBarPanels
		if (windowWidth <= breakpoint){
			// Hide the sidepanel (the responsive panel will takeover here).
			$( "#sidebar" ).hide();
			// Show the responsive panel
			$("#sidebarPanel").show(); 
			// Display the hamburger in the menu (the 5th node).
			//$(".k-menu > li:eq(4)").show();
		} else {
			// Is the sidebar hidden?
			if ($("#sidebar").is(":hidden")){
				// Display the sidebar. This should only happen when someone is readjusting their screen sizes.
				$( "#sidebar" ).show();
			}
		}
		
		// Change to root css contentWidth propery to match the desired content width (the percentage that the blog overlay will consume on the screen). */
		document.documentElement.style.setProperty('--contentWidth', getContentWidthPercent());
		// IE css fallback
		if (!getBrowserSupportForCssVars()){
			setContentWidthElements(getContentWidthPercentAsInt());
		}
		
		// Set the getContentPaddingPercent. This is 100 minus the contentWidthPercent divided by 2. This is used to position the sidebar panel and align it to the left of the content.
		document.documentElement.style.setProperty('--contentPaddingPercent', getContentPaddingPercent()/2);
		// Set the contentPaddingPixelWidth to set left and right padding elements in pixels. This is the screen size minus the contentWidth divided by two. 
		document.documentElement.style.setProperty('--contentPaddingPixelWidth', getContentPaddingPixelWidth()/2+"px");
		 // Set the blog content width
		document.documentElement.style.setProperty('--mainContainerWidth', mainContainerWidth);
		// Set the fixed nav width. We are going to add additional padding to the contentWidth.
		//document.documentElement.style.setProperty('--fixedNavWidth', mainContainerWidth + contentPaddingPixelWidth);
		
		// Double check and make sure that the main container and header width matches (it won't match right now as the padding that I had used increases the content size). I'll fix in the next version.
		// Get all of the styles.
		var allStyles = getComputedStyle(document.documentElement);
		// Get the content with value.
		var contentWidthValue = String(allStyles.getPropertyValue('--contentWidth')).trim();
		// Get the width of the main flex container ('mainBlog').
		var parentContainerWidth = $( "#mainBlog" ).width();
		// Get the width of the header container which we need to align.
		var headerContainerWidth = $( "#headerContainer" ).width();
		// alert('contentWidthValue: ' + contentWidthValue + '\n parentContainerWidth: ' + parentContainerWidth + '\n mainContainerWidth: ' + mainContainerWidth + '\n getContentPaddingPixelWidth(): ' + getContentPaddingPixelWidth() + '\n mainContainerWidth + getContentPaddingPixelWidth(): ' + parentContainerWidth + getContentPaddingPixelWidth() + '\n headerContainerWidth: ' + headerContainerWidth);
		
		// If both the parent and header container widths are not null (when this function first loads), and the header does not match the width of the parent container, resize the header. The sizes may not identical as the padding expands the parent container by 20 (mobile) or 40 (desktop) pixels. I will fix this in an upcoming version.
		if (!!parentContainerWidth && !!headerContainerWidth && parentContainerWidth != headerContainerWidth){
			// alert('parentContainerWidth:' + parentContainerWidth + 'headerContainerWidth:' + headerContainerWidth);
		<cfif headerBannerWidth eq '100%'>// The header, fixedNav header, and footer are set to stretch accross the page
		<cfelse>$( "#headerContainer" ).width(parentContainerWidth + "px");
			// Resize the width of the header elements.
			$( "#fixedNavHeader" ).width(parentContainerWidth + "px");
			$( "#footerDiv" ).width(parentContainerWidth + "px");
		</cfif>
		}
		
	}
	
	// Function to determine if the browser supports global css vars. The else block is used for IE 11 which returns undefined. 
	function getBrowserSupportForCssVars() {
		if (window.CSS && CSS.supports('color', 'var(--fake-var)')){
			return window.CSS && CSS.supports('color', 'var(--fake-var)');
		} else {
			return false;
		}	
	}
	
	// This function is used to set width on the required elements that use the css -contentWidth setting for depracated browsers (IE 11 in particular).
	function setContentWidthElements(width){
		// Manually set the widths of the elements since the root css vars will not be read.
		$("#mainBlog").width(width + "%");
		$("#mainPanel").width(width + "%");
		// We are not setting the blog content width here. It needs to be set at 100% when it is in a modern theme.
		$("#constrainerTable").width(width + "%");
		$("#fixedNav").width(width + "%");
		$("#footerDiv").width(width + "%");
	}
	
	// Gets the content width in pixels.
	function getContentPixelWidth(){
		var windowWidth = $(window).width();
		var contentWidthPercent = getContentWidthPercentAsInt();
		var contentPixelWidth = (windowWidth/100)*contentWidthPercent;
		return Math.round(contentPixelWidth);
	};
	
	// Returns the content width as an int.
	function getContentWidthPercentAsInt(){
		return parseInt(getContentWidthPercent());
	}
	
	// Gets the background width with is the screen width minus the content width
	function getContentPaddingPercent(){
		var contentPaddingPercent = Math.round((100-getContentWidthPercentAsInt())/2) + '%';
		return contentPaddingPercent;
	}
	
	// Gets the background width with is the screen width minus the content width
	function getContentPaddingPixelWidth(){
		var windowWidth = $(window).width();
		var contentPaddingPixelWidth = Math.round((windowWidth - getContentPixelWidth()));
		// alert('windowWidth: ' + windowWidth + 'getContentPixelWidth(): ' + getContentPixelWidth() )
		return contentPaddingPixelWidth;
	}
	
	// This function is used to set the max-width for the blogContent and the sideBar. We need to get the number of pixes for a given percent. 
	function calculatePercent(percent, number){
		var val = ((percent/100) * number);
		return Math.round(val);
	}
	
	// Scroll to top with easing
	function scrollToTop(){
		var top = 0;
		$('html, body').animate({
			scrollTop: top
		},500);
		
		// Close the menu that is calling this function (I would do it in the menu, but I can only call a simple function from there).
		// Get a reference to the menu widget
    	var menu = $("#fixedNavMenu").data("kendoMenu");
    	// Close it.
    	menu.close();

		return false;
	}
	
	// Scroll to bottom with easing
	function scrollToBottom(){
		$([document.documentElement, document.body]).animate({
        	scrollTop: $("#pagerAnchor").offset().top
    	}, 500);
		
		// Close the menu that is calling this function (I would do it in the menu, but I can only call a simple function from there).
		// Get a reference to the menu widget
    	var menu = $("#fixedNavMenu").data("kendoMenu");
    	// Close it.
    	menu.close();

		return false;
	}
	
	// Lazy loading images and media.
    // Define a callback function
    // to add a 'shown' class into the element when it is loaded
    var media_loaded = function (media) {
        media.className += ' shown';
    }

    // Then call the deferimg and deferiframe methods
    deferimg('img.fade', 300, 'lazied', media_loaded);
    deferiframe('iframe.fade', 300, 'lazied', media_loaded);
	
	/* Cookie functions. The original author of this script is unknown */
	function setCookie(name,value,days) {
		var expires = "";
		if (days) {
			var date = new Date();
			date.setTime(date.getTime() + (days*24*60*60*1000));
			expires = "; expires=" + date.toUTCString();
		}
		// The path must be stored in the root in order for ColdFusion to read these cookies
		document.cookie = name + "=" + (value || "")  + expires + "; path=/";
	}

	function getCookie(name) {
		var nameEQ = name + "=";
		var ca = document.cookie.split(';');
		for(var i=0;i < ca.length;i++) {
			var c = ca[i];
			while (c.charAt(0)==' ') c = c.substring(1,c.length);
			if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
		}
		return null;
	}
	
</script>