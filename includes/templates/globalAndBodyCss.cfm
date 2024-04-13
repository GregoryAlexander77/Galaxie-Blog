	<style><cfoutput>
		
		/* ------------------------------------------------------------------------------------------------------------
		Global CSS vars and body.
		Create a content width global css var. We will change this with Javascript depending upon the screen resolution 
		--------------------------------------------------------------------------------------------------------------*/
		
		html {
			/* The scroll position needs to be adjusted due to the floating menu at the top of the page. When clicking on an anchor, without this, the content is behind the nav menu */
		   	scroll-padding-top: 70px; 
		}
		
		:root {
			-- contentWidth: <cfoutput><cfif session.isMobile>95<cfelse>#contentWidth#</cfif></cfoutput>%;
			-- contentPaddingPercent: <cfoutput>#round((contentWidth/2)/2)#</cfoutput>%;
			-- mainContainerWidth: <cfoutput>#mainContainerWidth#</cfoutput>%;
		}

		<cfif session.isMobile>/* This should work to apply a fixed background on iOs */
		body:before {
			content: "";
			display: block;
			position: fixed;
			left: 0;
			top: 0;
			width: 100%;
			height: 100%;
			z-index: -10;
			<cfif includeBackgroundImages>background-image: url(<cfoutput>#application.baseUrl##blogBackgroundImage#</cfoutput>);
			background-repeat: <cfoutput>#blogBackgroundImageRepeat#</cfoutput>;
			background-position: <cfoutput>#blogBackgroundImagePosition#</cfoutput>; /* Center the image */
			-webkit-background-size: cover;
			-moz-background-size: cover;
			-o-background-size: cover;
			background-size: cover;
			<cfelseif len(blogBackgroundColor)>background-color: <cfoutput>#blogBackgroundColor#</cfoutput>;</cfif>
		}
		
		html, body {
			font-family: <cfoutput>'#font#', #fontType#</cfoutput>;
			/* Set the global font size. Mobile should be two sizes smaller to maximize screen real estate. */
			font-size: <cfoutput>#fontSizeMobile#</cfoutput>pt;
		}
			
		<cfelse>body {
			<cfif includeBackgroundImages>background-image: url(<cfoutput>#application.baseUrl##blogBackgroundImage#</cfoutput>);
			background-repeat: <cfoutput>#blogBackgroundImageRepeat#</cfoutput>;
			background-position: <cfoutput>#blogBackgroundImagePosition#</cfoutput>; /* Center the image */
			<cfif blogBackgroundImageRepeat eq "no-repeat">background-size: cover;</cfif>
			background-attachment: fixed;
			<cfelseif len(blogBackgroundColor)>background-color: <cfoutput>#blogBackgroundColor#</cfoutput>;</cfif>
			/* Opacity trick */
			filter: alpha(Opacity=<cfoutput>#siteOpacity#</cfoutput>);
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			/* Set the global font properties. */
			font-family: <cfoutput>'#font#', #fontType#</cfoutput>;
			font-size: <cfoutput>#fontSize#</cfoutput>pt;
		}</cfif><!---<cfif session.isMobile>--->
				
		/* Decrease the size of the h1 tag */
		h1 {
			font-size: <cfif session.isMobile>14<cfelse>18</cfif>pt;
		}
		

		/* Set links */	
		a {
		<cfif darkTheme>color: whitesmoke;
			text-decoration: underline;
			<cfelse>text-decoration: underline;</cfif>
		}
				
		/* Flex classes */
		.flexParent {
			display: flex;
			justify-content: center;
			align-items: stretch;
		}
				
		/* Force items to be 100% width, via flex-basis */
		.flexParent > * {
		  flex: 1 100%;
		}

		.flexHeader { 
			order: 1;
		}
		
		.flexMainContent { 
			order: 2; 
		}
		
		.flexSidebar { 
			order: 3; 
		}
				
		.flexFooter { 
			order: 4; 
		}
				
		.flexItem {
  			flex: 0 0 auto; 
		}
		
		/*
		[1]: Make a flex container so all our items align as necessary
		[2]: Prevent items from wrapping
		[3]: Automatic overflow means a scroll bar won’t be present if it isn’t needed
		[4]: Make it smooth scrolling on iOS devices
		[5]: Hide the ugly scrollbars in Edge until the scrollable area is hovered
		[6]: Hide the scroll bar in WebKit browsers
		*/
		.flexScroll {
			display: flex; /* [1] */
			flex-wrap: nowrap; /* [1] */
			overflow-x: auto; /* [1] */
			-webkit-overflow-scrolling: touch; /* [4] */
			-ms-overflow-style: -ms-autohiding-scrollbar; /* [5] */ 
		}

		/* [6] */
		.scroll::-webkit-scrollbar {
			display: none; 
		}
	</style></cfoutput>