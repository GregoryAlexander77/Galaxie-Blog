<!---<cfdump var="#getTheme#">--->
<cfsilent><!--- Note: this page depends on the pageSettings.cfm template. And, this page is often used in a standalone environment to pass css vars to the tinymce editor. If the page is standalone, we need to include the pageSettings template, remove the style tags and set the page content as css. --->
<cfparam name="URL.standalone" default="" type="any">
<cfif isDefined("URL.standalone") and len(URL.standalone)>
	<cfset standAlone = true>
	<cfset pageTypeId = 1><!--- Blog --->
	<cfinclude template="pageSettings.cfm">	
<cfelse>
	<cfset standAlone = false>
</cfif>

<!--- Get the theme properties --->
<cfset theme = getTheme[1]["Theme"]>
<cfset selectedTheme = getTheme[1]["SelectedTheme"]>
<!--- Get Kendo Theme color properties --->
<cfset accentColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
<cfset baseColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'baseColor')>
<cfset headerBgColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'headerBgColor')>	
<cfset headerTextColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'headerTextColor')>
<cfset hoverBgColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'hoverBgColor')>
<!--- This is the separater color on the standard breadcrumb --->
<cfset hoverBorderColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'hoverBorderColor')>	
<cfset textColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'textColor')>	
<cfset selectedTextColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'selectedTextColor')>	
<cfset contentBorderColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'contentBorderColor')>	
<cfset contentBgColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'contentBgColor')>
<cfset alternateBgColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'alternateBgColor')>	
<cfset errorColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'error')>
<cfset warningColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'warning')>
<cfset successColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'success')>
<cfset infoColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'info')>
	
<!--- Logic to determine what side the padding should occur when the alignBlogMenuWithBlogContent argument is true. --->
<!--- Don't set any padding unless the stretchHeaderAcrossPage is true. Otherwise the header will be scrunched up in the center of the page. --->
<cfif stretchHeaderAcrossPage and alignBlogMenuWithBlogContent>
	<cfif topMenuAlign eq 'left'>
		<cfset topWrapperCssString = "padding-left: var(--contentPaddingPixelWidth);">
	<cfelseif topMenuAlign eq 'right'>
		<cfset topWrapperCssString = "padding-right: var(--contentPaddingPixelWidth);">
	<cfelse>
		<cfset topWrapperCssString = "margin: auto;">
	</cfif>
<cfelse>
	<cfset topWrapperCssString = "margin: auto;">
</cfif>
	
<!--- Breadcrumb and stepper vars. --->
<cfset customSeparater = "#application.baseUrl#/images/separator/cd-custom-separator.svg">
<cfset customIcon = "#application.baseUrl#/images/icons/small/cd-custom-icons-01.svg">
<!--- The following sets the height of the triangles. The height includes additional padding and 15px is aproximately 45pixels in actual height. --->
<cfset breadCrumbTrianagleHeight = "15px">
</cfsilent>
	<!--- Minimized using https://minifycode.com/css-minifier/ --->
<cfif not standAlone>
	<style>
<cfelse>
	<cfcontent type="text/css" />
</cfif>
<!--- We don't want the background images to show up in the tinymce editor --->
	<cfif not standAlone>
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
				
	</cfif><!---<cfif not standAlone>--->
				
		/* Decrease the size of the h1 tag */
		h1 {
			font-size: <cfif session.isMobile>14<cfelse>18</cfif>pt;
		}
			
		/* -------------------------------- 
			Header Styles
		-------------------------------- */
		/* Headers. The H1 header is already set for the blog title and set at 18pt */
		h2 {
		  font-size: 1.2em;
		}
		h3 {
		  font-size: 1.1em;
		}
		
		/* -------------------------------- 
			Link Styles
		-------------------------------- */
		a {
		<cfif darkTheme>color: whitesmoke;
			text-decoration: underline;
			<cfelse>text-decoration: underline;</cfif>
		}
			
		/* States for the header menu */
		ul.k-hover { 
		  background-color: transparent !important;
		  background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
		  border: 0;
		  border-right: none;
		} 

		ul.k-link { 
		  background-color: transparent !important;
		  background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
		  border: 0;
		} 
				
		/* -------------------------------- 
			Flex Classes
		-------------------------------- */
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
		
		/* Reset the z-index of the code-toolbar class as the code will float above the staticly positioned fixedNavBar at the top of the page */
		div.code-toolbar {
			z-index:0 !important;
		}
				
		/* -------------------------------- 
			Header Classes
		-------------------------------- */
		#logo {
			border: 0;
			position: relative;
			padding-top: <cfoutput>#logoPaddingTop#</cfoutput>;
			padding-left: <cfoutput>#logoPaddingLeft#</cfoutput>;
			padding-right: <cfoutput>#logoPaddingRight#</cfoutput>;
			padding-bottom: <cfoutput>#logoPaddingBottom#</cfoutput>;
		}		
		
		/* Fixed navigation menu at the top of the page when the user scrolls down */
		#fixedNavHeader {
			position: fixed;
			z-index: 1;
			visibility: hidden; /* This will be overridden and set to visible when the page fully loads */
			top: 0px;
			height: <cfif kendoTheme contains 'materialblack'><cfif session.isMobile>55<cfelse>65</cfif><cfelse><cfif session.isMobile>35<cfelse>45</cfif></cfif>px;
			width: var(--contentWidth);
			color: <cfoutput>#blogNameTextColor#</cfoutput>; /* text color */
			font-family: <cfoutput>'#menuFont#', #menuFontType#</cfoutput>;
			font-size: <cfif kendoTheme eq 'office365'><cfif session.isMobile>.75em<cfelse>1em</cfif><cfelse><cfif session.isMobile>.9em<cfelse>1em</cfif></cfif>;
		<cfif menuBackgroundImage neq "">
			background-color: transparent !important;
			background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');/* Without this, there is a white ghosting around this div. */
			background-repeat: repeat-x;
		</cfif>
			/* Subtle drop shadow on the header banner that stretches across the page. */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
			/* Center it */
			margin-left: auto;
			margin-right: auto;
		}
		
		/* Main wrapper within the header table. */
		#topWrapper {
			<cfoutput>#topWrapperCssString#</cfoutput>
		}
		
		.headerBackground {
			background: url(<cfoutput>#headerBackgroundImage#</cfoutput>);
			background-repeat: repeat-x;
		}
				
		/* The headerContainer is a *child* flex container of the mainPanel below. This may be counter-intuitive, but the main content is stuffed into the blogContent and I want the header to play nicely and following along. This container will be resized if it does not match the parent mainPanel container using the setScreenProperties function at the top of the page. */
		#headerContainer {
			width: 100%; 
			/* Note: if the headerBackgroundImage is not specified, we will not use a drop shadow here */
			<cfif headerBackgroundImage neq ''>
			/* Subtle drop shadow on the header banner. */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
			</cfif>
		}

		#blogNameContainer {
			/* The blog title at the top of the page */
			font-family: <cfoutput>'#blogNameFont#', #BlogNameFontType#</cfoutput>; 
			font-size: <cfoutput><cfif session.isMobile>#blogNameFontSizeMobile#<cfelse>#blogNameFontSize#</cfif></cfoutput>px; 
			/* The container may need to have some padding as the menu underneath it is not going to left align with the text since the menu is going to start prior to the first text item. */
			padding-left: 13px; 
			text-shadow: 0px 4px 8px rgba(0, 0, 0, 0.19); /* The drop shadow should closely mimick the shadow on the main blog layer.*/
			color: <cfoutput>#blogNameTextColor#</cfoutput>; /* Plain white has too high of a contrast imo. */
			vertical-align: center;
		}

		/* Menu container. Controls the placement of the menu and creates a transparency so that the menu and menu background image is seen */
		#topMenuContainer {
			visibility: none;
			position: relative; 
			left: 0px; 
		<cfif menuBackgroundImage neq "">
			background-color: transparent !important;
		</cfif>
			vertical-align: center;
		}

		/* Menu's */
		#topMenu {	
			/* We need to hide the menu momentarilly on page load as the menu looks scrunched up initially. The menu will fade in as soon as the page loads. However, we also need to remove this when the page is in admin preview mode otherwise the menu will not appear in the preview. */
			visibility: hidden;
		}
		
		#topMenuPreview {	
			visibility: visible;
		}
			
		/* Common properties for the both topMenu and topMenuPreview. */
		#topMenu, #topMenuPreview {	
		<cfif menuBackgroundImage neq "">
			background-color: transparent !important;
			background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');/* Without this, there is a white ghosting around this div. */
			background-repeat: repeat-x;
		</cfif>
			border: 0;
			color: <cfoutput>#blogNameTextColor#</cfoutput>; /* text color */
			font-family: <cfoutput>'#menuFont#', #menuFontType#</cfoutput>;
			font-size: <cfif kendoTheme eq 'office365'><cfif session.isMobile>.75em<cfelse>1em</cfif><cfelse><cfif session.isMobile>.9em<cfelse>1em</cfif></cfif>;
			/* Note: the top menu is handled differently depending upon the version of Kendo */
			<cfif not application.kendoCommercial>top: 32px;</cfif>
			height: 20px;
			/* Note: an incorrect width setting will stretch the table container and skew the center allignment if not set properly. */
		}
		
		/* Apply a little bit of padding to the bars icon */
		.toggleSidebarPanelButton {
			padding-left: 7px;
		}
		
		.siteSearchButton {
			/* Set the site search icon to match the blog text color 
			color: <cfoutput>#blogNameTextColor#</cfoutput>; 
			*/
		}
			
		<cfif kendoTheme eq 'nova'>
		/* Override some of the Kendo buttons to improve the contrast of the text against certain button backgrounds. Added in V4 */
		.k-button {
			color: #000!important;
		}
		</cfif>
		
		/* Remove the vertical border. The borders display a vertical line between the menu items and since we have custom images and colors on the banners, I want to remove these. */
		.k-widget.k-menu-horizontal>.k-item {
		  border: 0;
		}
		
		/* Override the menu and remove some of the extra padding to make it fit the page (default padding is 0.5em 1em 0.4em). When there is not a selected theme, make this even smaller so the header does not wrap */
		.k-menu .k-item>.k-link, .k-menu-scroll-wrapper .k-item>.k-link, .k-popups-wrapper .k-item>.k-link {
			display: block;
    		padding: <cfif !selectedTheme>0.3em .6em<cfelse>0.4em .7em</cfif> 0.4em;
		}
			
		/* Fixed nav menu. Note: the script at the tail end of the page will set this to visible after the page loads. */
		#fixedNavMenu {
			/* Hide the menu on page load */
			visibility: hidden;
			<cfif not stretchHeaderAcrossPage>
			/* Center it */
			left: calc(-50vw + 50vw);
			right: calc(-50vw + 50vw);
			margin-left: auto;
			margin-right: auto;
			</cfif>
		}
		
	 <!--- When a theme is not selected, we must descrease the font size as the theme menu is displayed taking up more room on the page. The menu font size is smaller when using the Delicate Arch theme, otherwise, the menu will wrap as the content size is smaller than usual to show the background --->
	<cfif !selectedTheme and (theme eq 'Delicate Arch' or theme eq 'Joshua Tree')>
		.k-menu .k-menu-item {
        	font-size: 18px; /* Don't wrap the menu */
    	}
	</cfif>
				
	<cfif kendoTheme eq 'default' or kendoTheme eq 'highcontrast' or kendoTheme eq 'material' or kendoTheme eq 'silver'><!--- Both default and high contrast have the same header. Material needs to have a darker text when selecting a menu item--->
		/* fixedNavMenu states. */
		#fixedNavMenu.k-menu .k-state-hover,
		#fixedNavMenu.k-menu .k-state-hover .k-link,
		#fixedNavMenu.k-menu .k-state-border-down
		 /* 
		.k-menu .k-state-hover, (background and selected item when hovering)
		.k-menu .k-state-hover .k-link (background and selected item with a link when hovering)
		.k-menu .k-state-border-down, (backgound and selected item when scrolling down)
		*/
		{
			color: <cfoutput>#blogNameTextColor#</cfoutput>;
			font-family: <cfoutput>'#menuFont#', #menuFontType#</cfoutput>;
			background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
		}
		
		/* topMenu States (also for the preview). This allows the menu to become visible as well as placing the menu background image when the menu is first clicked. This must be applied to both the topMenu and topMenuPreview divs */
		.topMenu.k-menu .k-state-hover,
		.topMenu.k-menu .k-state-hover .k-link,
		.topMenu.k-menu .k-state-border-down
		 /* 
		.k-menu .k-state-hover, (background and selected item when hovering)
		.k-menu .k-state-hover .k-link (background and selected item with a link when hovering)
		.k-menu .k-state-border-down, (backgound and selected item when scrolling down)
		*/
		{
			color: <cfoutput>#blogNameTextColor#</cfoutput>;
			font-family: <cfoutput>'#menuFont#', #menuFontType#</cfoutput>;
			background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
		}
	</cfif><!---<cfif kendoTheme eq 'default' or kendoTheme eq 'highcontrast'>--->
		
	<cfif application.kendoCommercial>
		/* When using Kendo commercial, the link overrides the menu's text color */
		/*#topMenu.k-menu .k-link {*/
		.topMenu.k-item.k-link.k-header {
			color: <cfoutput>#blogNameTextColor#</cfoutput>;
		}
		
		/* Also remove the vertical borders on the menu */
		.topMenu.k-menu-horizontal .k-menu-link {
			border: 0px;
		}
	</cfif>
		
		/* Remove the vertical border. The borders display a vertical line between the menu items and since we have custom images and colors on the banners, I want to remove these. */
		.k-widget.k-menu-horizontal>.k-item {
		  border: 0;
		}
		
		/* Adjust the padding of the menu to try to evenly distribute the search and hamburger icons across devices. */
		.k-menu .k-item>.k-link {
			padding-left: <cfif session.isMobile>.7em<cfelse>1.1</cfif>;/* The default Kendo setting is 1.1em */
			padding-right: <cfif session.isMobile>.7em<cfelse>1.1</cfif>;
		}
		
		/* Kendo class over-rides. */
		<cfif session.isMobile>
		/* Increase the close button on mobile */
		.k-window-titlebar .k-i-close {
			zoom: 1.2;
		}
		</cfif>
		/* Change the window font size (its too big for mobile). The Kendo window is not responsive, and has its own internal properties that are hardcoded, so I need to reset properties using inline styles, such as font-size. */
		.k-window-titlebar {
			font-size: 16px; /* set font-size */
		}
		
		/* -------------------------------- 
			Blog Styles
		-------------------------------- */
		.innerContentContainer { 
			/* Apply padding to all of the elements within a blog post. */ 
			margin-top: 5px; 
			padding-left: 20px; 
			padding-right: 20px; 
			display:block; 
		}
				
		#mainBlog {
			/* This is the main flex container (set by class) and essentially the outer table */
			position: relative;
			display: table;
			width: var(--contentWidth); 
			margin:0 auto;
			/* Subtle drop shadow on the main layer */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
		<cfif session.isMobile>
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
		</cfif>
		}
		
		/* The main container is also the parent flex container for the blogContent and sidebar elements. It also controls the header width after the body is resized using the setScreenProperties function at the top of the page. */
		#mainPanel  {
			display: table-row;
			width: var(--contentWidth); 
		<cfif session.isMobile>
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
		</cfif>
		}
		
		/* This is a child container of the mainPanel. Note: the formatter forces the width of this element to exceed the width of the mainPanel. */		
		#blogContent {
			display: table-cell;
			margin: 0;
		<cfif session.isMobile>
			width: 95%;	
			/* Contstrain the width. */
			max-width: var(--mainContainerWidth);
			/* On mobile devices, cut the padding in half as screen real estate is not cheap. We don't  have to worry about having extra padding to the right as the side-bar element is not used in mobile. */
			padding-top: 10px;
			padding-right: 10px;
			padding-bottom: 10px;
			padding-left: 10px;
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
		<cfelse>
			width: <cfoutput>#mainContainerWidth#</cfoutput>%;
			/* Constrain the width. */
			max-width: var(--mainContainerWidth);
			/* Apply a min width of 600 pixels. We are making an assumption that the minimum display resolution will be 800 pixels and apply the 200 pixels to the outer container. */
			min-width: 600px;
			/* On mobile, apply less padding on the right to keep things uniform. Otherwise, keep the padding consistent. */
			padding-top: 20px;
			padding-right: 20px;
			padding-bottom: 20px;
			padding-left: 20px;
		</cfif>
			vertical-align: top;
			/* clear the floating sidebar */
      		overflow: hidden;
		}

		/* The next three classes will be used to create a calendar date placard */
		.blogPost p.postDate {
		  position: relative;
		  width: 38px;
		  /* The dark theme height must be increased with the dark themes otherwise the line at the bottom will not be displayed. */
		  height: <cfif darkTheme>50px<cfelse>38px</cfif>;
		  display: block;
		  margin: 0;
		  padding: 0px;
		  text-align: center;
		  float: left;
		  line-height: 100%;
		  /* background: #fff url(<cfoutput>#application.blogCfcUrl#</cfoutput>/images/date-bg.png) no-repeat left bottom; */
		  border: 1px solid #fff;
		}

		.blogPost p.postDate span.month {
		  position: absolute;
		  /* Set the font size to 14px */
		  font-size: <cfif session.isMobile>0.55em<cfelse>0.70em</cfif>;
		  /* The next two properties are new as of v4 */
		  color: #<cfoutput>#selectedTextColor#</cfoutput>;
		  background-color: #<cfoutput>#accentColor#</cfoutput>;
		  /* Note: the additional 'k-primary' kendo class attached to the span will set the background */
		  border-bottom: 1px solid #fff;
		  /* The width is set at 36px for the dark themes. If set to 100%, the white line that surrounds the date will disappear on the right side of the date. */
		  width: <cfif darkTheme>34px<cfelse>100%</cfif>;
		  top: 0;
		  left: 0;
		  height: 19px;
		  text-transform: uppercase;
		  padding: 2px;
		}

		.blogPost p.postDate span.day {
		  /* Set the font size to 14px */
		  font-size: <cfif session.isMobile>0.60em<cfelse>0.75em</cfif>;
		  /* Note: the additional 'k-alt' kendo class attached to the span will set the background. The calendar image is rather dificult to control. I would not adjust these settings much. It took me a long time to get it right. */
		  display: table-cell;
		  vertical-align: middle;
		  bottom: 1px;
		  top: 25px;
		  left: 0;
		  height: 19px;/*30%/*
		   /* The width is set at 36px for the dark themes. If set to 100%, the white line that surrounds the date will disappear on the right side of the date. */
		  width: <cfif darkTheme>34px<cfelse>100%</cfif>;
		  padding: 2px;
		  position: absolute;
		}

		.blogPost p.postAuthor span.info {
		  margin-top: 15px;
		  display: block;
		}

		.blogPost p.postAuthor {
		  /*background: transparent url(images/post-info.png) no-repeat left top;*/
		  margin: 0 0 0 <cfif session.isMobile>43<cfelse>0</cfif>px;
		  padding: 0 12px;
		  font-size: 1em;
		  font-style: italic;
		  /* border: 1px solid #f2efe5; */
		  min-height: 38px;
		  color: #75695e;
		  height: auto !important;
		  height: 38px;
		  line-height: 100%;
		}

		.postContent {
			/* Apply padding to post content. */
			margin-top: 5px; 
			display: block;
		}
				
		/* -------------------------------- 
			Image and Map Hero Classes 
		-------------------------------- */
		/* Constraining images to a max width so that they don't  push the content containers out to the right */
		.entryImage img {
			max-width: 100%;
			height: auto; 
			/* Subtle drop shadow on the image layer */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
		}
		
		.entryMap {
			height: <cfif session.isMobile>320<cfelse>564</cfif>px;
			width: 100%; 
			/* Subtle drop shadow on the layer */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
		}
		
		/* -------------------------------- 
			Image Transitions 
		-------------------------------- */
		.img-hover-zoom {
			height: auto;
			overflow: hidden;
		}

		/* Brightness-zoom Container */
		.img-hover-brightzoom img {
			transition: transform 2s, filter 1.5s ease-in-out;
			transform-origin: center center;
			filter: brightness(90%);
		}

		/* The transformation */
		.img-hover-brightzoom:hover img {
			filter: brightness(100%);
			transform: scale(1.2);
		}
		
		/* Login screen needs some extra height otherwise it will be at the top of the screen */
		.login {
			height: 480px;
			margin-bottom: -240px; /* half of width */
			margin-top: -240px;  /* half of height */
			top: 50%;
			left: 50%;
		}
		
		/* -------------------------------- 
			Lazy loading image classes
		-------------------------------- */
		/* hide the element with opacity is set to 0 */
		.fade {
			transition: opacity 500ms ease-in-out;
			opacity: 0;
		}

		/* show it with the 'shown' class */
		.fade.shown {
			opacity: 1;
			background: 0 0;
		}
		
		/* -------------------------------- 
			Panel Classes 
		-------------------------------- */
		/* Class to force the div to expand in width */
		.panel {
			margin: 0;
			/* Set to 100% */
		<cfif session.isMobile>
			/* On mobile devices, cut the padding in half as screen real estate is not cheap. We don't  have to worry about having extra padding to the right as the side-bar element is not used in mobile. */
			padding-top: 10px;
			padding-right: 10px;
			padding-bottom: 10px;
			padding-left: 10px;
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
		<cfelse>
			/* On mobile, apply less padding on the right to keep things uniform. Otherwise, keep the padding consistent. */
			padding-top: 20px;
			padding-right: 20px;
			padding-bottom: 20px;
			padding-left: 20px;
		</cfif>
			vertical-align: top;
			/* clear the floating sidebar */
      		overflow: hidden;
		}
		
		.panel-wrap {
			display: table;
			margin: 0 0 20px;
			/* Controls the width of the container */
			border: 1px solid #e5e5e5;
		}
		
		/* Kendo UI applies default min-width (320px) to left and right panel elements, which causes the difference in width between top and left/right panels. We are overriding this default style with the following CSS rule: */
		.k-rpanel-left, .k-rpanel-right {
			min-width: 0px;
		 }
		
		/* Sidebar elements */
		#sidebar {
			/* We are going to eliminate this sidebar for small screen sizes and mobile. */
			/* todo hide this on mobile. */
			display: <cfif session.isMobile>none<cfelse>table-cell</cfif>;
			margin: 0;
			/* Apply less padding to the left to keep things uniform. On mobile devices, cut the padding in half as screen real estate is not cheap. */
			padding-top: 20px;
			padding-right: 20px;
			padding-bottom: 20px;
			padding-left: 10px;
			width: <cfoutput>#sideBarContainerWidth#</cfoutput>%;
			min-width: 375px;
			vertical-align: top;
			overflow: hidden;
		}
		
		/* The side bar panel is essentially a duplicate of the sidbar div, however, it is a responsive panel used when the screen size gets small. */
		#sidebarPanel {
			/* Hide the sidebarPanel */
			visibility: hidden;
			flex-direction: column;
		<cfif not session.isMobile>/* On desktop, we want the sidebar panel to also scroll with the page. Otherwise, the padding that places it underneath the header is disruped and it looks wierd. */
			position: absolute;
		</cfif>
			height: 100%;
			/* The panel needs to drop down below the page when the page does not have a lot of content */
    		min-height: 1440px;
    		width: <cfif session.isMobile>275px<cfelse>425px</cfif>;
			-webkit-touch-overflow: scroll;
			/* Note: the panel will not scroll with the blog content unless there is a css position: absolute. */
			z-index: 5;
			opacity: <cfoutput>#siteOpacity#</cfoutput>;
			margin: 0;
			/* All padding should be set at 10px */
			padding: 10px 10px 10px 10px;
			vertical-align: top;
			border-right: thin;
		}
		
		/* Place the layer where we want it and put a drop shadow on the panel when it is expanded. Note! the setSidebarPadding javascript function also sets some style properties. */
		#sidebarPanel.k-rpanel-expanded {
		<cfif pageTypeId eq 1>/* The sidebar panel is inside the main container and we don't want any top margin*/<cfelse><cfif session.isMobile>/* On mobile, the table height is 100px. We want to give about 5 pixels more height to allow the divider to be seen. */<cfelse>/* On desktop, the table height is 105px. We want to give about 5 pixels more height to allow the divider to be seen. */</cfif></cfif>
			margin-top: <cfif pageTypeId eq 1>0px<cfelse><cfif session.isMobile>105px<cfelse>110px</cfif></cfif>;
			margin-left: <cfif pageTypeId eq 1>0px<cfelse>var(--contentPaddingPixelWidth)</cfif>;
			-webkit-box-shadow: 0px 0 10px 0 rgba(0,0,0,.3);
    		-moz-box-shadow: 0px 0 10px 0 rgba(0,0,0,.3);
            box-shadow: 0 0 10px rgba(0,0,0,.3);
        }
		
		#sidebarPanelWrapper {
			/* This is both the flex parent and a flex child item. Flex is being used here in order to put up a scroll bar. iOs devices will not allow the panel to be scrolled along with the main container as iOs considers a scroll event past the bottom of the screen to be a screen refresh and this causes the responsive panel to close when scrolled. Instead, we are allowing the user to scroll either the panel or the body. */
			display: flex;
			flex-direction: column;
    		height: 100%;
    		width: 100%;
			/* iOs and mobile */
			-webkit-touch-overflow: scroll;
		}
		
		/* -------------------------------- 
			Calendar Classes 
		-------------------------------- */
		#blogCalendar {
			/* Push this behind the fixedNavContainer */
			z-index: 0;
			/* Align the calendar in the center. We must use the text-align property for this (I know that this is counter-intuitive). */
			text-align: center;
			width: 100%;
		}
		
		#blogCalendarPanel {
			/* Align the calendar in the center. We must use the text-align property for this (I know that this is counter-intuitive). */
			text-align: center;
			width: 100%;
		}
		
		
		/* Title bar of the calendar (we need more space for this widget) */
		.calendarWidget h3.topContent {
			font-size: 1em;
			padding-top: 0px;
			padding-right: 0px;
			padding-bottom: 10px;
			padding-left: 0px;
			border-bottom: 1px solid #e2e2e2;
			text-align: left;
		}
		
		/* The calendar widget should have no padding (we need all of the space that we can get to ensure that it is displayed properly). */
		.calendarWidget {
			padding: 0;
		}
		
		.calendarWidget div {
			padding: 0px;

		}
		
		/* widget class (the panels) */
		.widget {
			margin-top: 0px;
			margin-right: 0px;
			margin-bottom: 20px;
			margin-left: 0px;
			padding: 0;
			border: 1px solid #e2e2e2;
			border-radius: 3px;
			/* cursor: move; */
		}
				
		

		/* This syle affects the div containers within the widget on the left side of the page. */
		.widget div {
			/* padding: 10px; The padding screws up the Kendo media player widget. */
		}
		
		/* Title bar on blog post */
		.widget h1.topContent {
    		margin-bottom: 10px;
		}

		/* Title bar */
		.widget h3.topContent {
			font-size: 1em;
			padding-top: 0px;
			padding-right: 0px;
			padding-bottom: 10px;
			padding-left: 0px;
			border-bottom: 1px solid #e2e2e2;
			text-align: left;
		}

		/* mainBlog bottom bar */
		.widget p.bottomContent {
			padding-top: 10px;
			padding-right: 0px;
			padding-bottom: 0px;
			padding-left: 0px;
			border-top: 1px solid #e2e2e2;
		}

		/* Arrow on to show comments */
		.widget #collapse {
			float: right;
		}
		
		.widget.placeholder {
			opacity: 0.4;
			border: 1px dashed #a6a6a6;
		}
		
		/* Higlighted panel for promoted posts */
		.highlightedWidget {
			margin-top: 0px;
			margin-right: 0px;
			margin-bottom: 20px;
			margin-left: 0px;
			padding: 0;
			border: 3px solid #<cfoutput>#accentColor#</cfoutput> !important;
			border-radius: 4px;
			/* cursor: move; */
		}
		
		/* Nearly identical to the widget class without any boder */
		.author-bio {
			margin-top: 0px;
			margin-right: 0px;
			margin-bottom: 20px;
			margin-left: 0px;
			padding: 0;
			border-radius: 3px;
		}
				
		/* Author name */
		.author-bio h3.topContent {
			font-size: 1em;
			padding-top: 0px;
			padding-right: 0px;
			padding-bottom: 10px;
			padding-left: 0px;
			border-bottom: 1px solid #e2e2e2;
			text-align: left;
		}
		
		/* These arrows are used to indicate that this is a promoted post */
		.arrow-highlight{
			position: relative;
			margin: 0 0.5em;
			padding: 0 0.2em;
			}
		
		/* These arrows are used to indicate that this is a promoted post */
		.arrow-highlight:before{
			content: "";
			z-index: -1;
			left: -0.5em;
			top: 0.1em;
			border-width: 0.5em;
			border-style: solid;
			border-color: #<cfoutput>#accentColor#</cfoutput>;
			position: absolute;
			width: calc(100% - 0.5em);
			border-left-color: transparent;
		}

		/* These arrows are used to indicate that this is a promoted post */
		.arrow-highlight:after{
			content: "";
			z-index: -1;
			right: 0;
			top: 0.1em;
			border-width:0.5em;
			border-style: solid;
			border-color: #<cfoutput>#accentColor#</cfoutput>;
			position: absolute;
			border-top-color: transparent;
			border-bottom-color: transparent;
			border-left-color: transparent;
			transform: rotate(180deg);
			transform-origin: center right;
		}
		
		/* -------------------------------- 
			Media Classes 
		-------------------------------- */
		.mediaPlayer {
			white-space: nowrap;
			overflow: hidden;
			/* The players z-index must be set lower than the rest of the elements, or the media player will bleed through the other elements that should be on top of this */
			z-index: 0;
		}
		
		video {
		  max-width: 100%;
		  height: auto;
		}
		
		/* YouTube and Vimeo Video classes */
		.video-container {
			position: relative;
			padding-bottom: 56.25%; /* - 16:9 aspect ratio (most common) */
			/* padding-bottom: 62.5%; - 16:10 aspect ratio */
			/* padding-bottom: 75%; - 4:3 aspect ratio */
			padding-top: 30px;
			height: 0;
			overflow: hidden;
		}

		.video-container iframe,
		.video-container object,
		.video-container embed {
			border: 0;
			position: absolute;
			top: 0;
			left: 0;
			width: 100%;
			height: 100%;
		}
		
		/* -------------------------------- 
			Table Classes 
		-------------------------------- */
		/* Applies a border on the outside of the table */
		table.tableBorder {
			border: 1px solid <cfif darkTheme>whitesmoke<cfelse>black</cfif>;
			width: 100%;
			border-radius: 3px; 
  			border-spacing: 0;
		}

		.fixedCommentTable {
			table-layout: fixed;
			width: 100%;
		}

		/* Column widths are based on these cells */
		.fixedCommentTablePadding {
			width: 5px;
		}

		.fixedCommentTableContent {
			min-width: 100%;
			width: 100%;
		}

		/* We need to fix all content within the tables in the pods, otherwise, the tables may not be resized. */
		.fixedPodTable {
			table-layout: fixed;
			width: 100%;
		}

		/* Other than the recent comment pod, don't  wrap pod content, and if the text exceeds the size of the html tables, ellipsis the text (like so 'and...')  */
		.fixedPodTable td {
			color: <cfif darkTheme>whitesmoke<cfelse>#2e2e2e</cfif>;
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis;
		}

		/* Other than the recent comment pod, don't  wrap pod content, and if the text exceeds the size of the html tables, ellipsis the text (like so 'and...')  */
		.fixedPodTableWithWrap td {
			color: <cfif darkTheme>whitesmoke<cfelse>#2e2e2e</cfif>;
			overflow: hidden;
			text-overflow: ellipsis;
		}

		td.border {
			border-top: 1px solid #ddd;
		}

		/* Divider styles to get around IE's goofyness. IE 8+ will not render elemetns that are larger than the default font size, so I am setting the font property to 0. Stupid.... */
		.rowDivider{
			font-size: 0px;
			height: 1px; 
			background:#F00;
			border: solid 1px #F00;
			width: 100%;   
			overflow: hidden;
		}
		
		/* Kendo class over-rides */
		td.k-alt {
			font-weight: normal !important;
		}
		
		/* For some odd reason, using width: 100% causes the month toolbar at the top of the calendar to be wider than the calendar widget. I tried 300 px, and that didn't look right either. Sticking with 90% for now. I am assuming that my display css is screwing things up here. */
		.k-widget.k-calendar {
			width: 90%;
		}
		
		.k-widget.k-calendar .k-content tbody td {
			width: 90%;
		}

		/* Make the avatar round. I personally don't  like squares, especially when I put some of the data into Kendo grids (in a later version). */
		.avatar {
			border-radius: 50%;
			-moz-border-radius: 50%;
			-webkit-border-radius: 50%;
		}
	<cfif isDefined("condensedGridView") and condensedGridView>
		/* -------------------------------- 
			Cards 
		-------------------------------- */
		/* Handle the k-cards when in condensed mode (for the categories for example) */
		.cards-container {
			display: flex;
			flex-wrap: wrap;
			justify-content: center;
		}
		
		.k-card-image {
			display: block;
			width: 100%;
			height: auto;
		<cfif not session.isMobile and not showSidebar>
			/* The height of the card should be 150 pixels on desktop devices without the sidebar */
			height: 150px;
		</cfif>
			object-fit: cover;
			object-position: 0 100%;   /*positioned top left of the content box */
			padding-bottom: 5px;
		}
		
		.k-card-media {
			display: block;
			width: 100%;
		<cfif not session.isMobile and showSidebar>
			height: 380px;
		<cfelse>
			height: auto;
		</cfif>
			object-fit: cover;
			object-position: 0 100%;   /*positioned top left of the content box */
			padding-bottom: 5px;
		}

		.k-card-deck {
			box-sizing: border-box;
			margin-left: -16px;
			margin-right: -16px;
			padding-left: 16px;
			/* padding: 16px 16px 16px; */
			overflow-y: hidden;
			overflow-x: hidden;/* used to be auto, changed to remove scrollbars */
			<cfif showSidebar>/* We need to contstrain the height when used for the popular posts widget */
			height: 325px;
			</cfif>
		}
		
		/* Used for the cards in the k-card-deck scroll container when using the sidebar (for example popular posts). This class should replace the k-card-media class to get the media to fit into the small card. */
		.k-card-scroll-image {
			display: block;
			width: 100%;
			height: auto;
			/* The height of the card should always be 150 pixels */
			height: 150px;
			object-fit: cover;
			object-position: 0 100%;   /*positioned top left of the content box */
			padding-bottom: 5px;
		}
		
		.k-card-action {
			/* Witthout this declaration, the button can be quite tall if there are other k-cards in the same row with different dimensions */
			max-height: 40px;
		}
		
		.blog-content {
			white-space: pre-wrap !important;
			word-break: break-word !important;
		}
	</cfif>
				
		/* -------------------------------- 
			Footer Classes 
		-------------------------------- */
		#footerDiv {
			/* Note: opacity and transform will set this block to behave like a z-index:0 on mobile devices, so we need to set a position and a z-index here to make the fixedNavHeader menu float above this layer */
			position: relative;
			z-index: 0;
		<cfif session.isMobile>
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
		<cfelse>
			/* Apply a min width of 600 pixels. We are making an assumption that the minimum display resolution will be 800 pixels and apply the 200 pixels to the outer container. */
			min-width: 600px;
		</cfif>
			width: var(--contentWidth);
			/* Subtle drop shadow on the header banner that stretches across the page. */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
			/* Center it */
			left: calc(-50vw + 50vw);
			right: calc(-50vw + 50vw);
			margin-left: auto;
			margin-right: auto;
			border: 1px solid #e2e2e2;
			border-radius: 3px;
		}
		
		#footerInnerContainer {
			/* Apply padding to all of the elements. */
			margin-top: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			margin-left: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			margin-right: <cfif session.isMobile>10<cfelse>20</cfif>px;
			margin-bottom: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			padding: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			/*background-color: whitesmoke;*/
			display: block;
			border: 1px solid #e2e2e2;
			border-radius: 3px;
		}
		
		/* Title bar for the footer */
		#footerInnerContainer h4 {
			font-size: 1em;
			padding-top: 0px;
			padding-right: 0px;
			padding-bottom: 10px;
			padding-left: 0px;
			border-bottom: 1px solid #e2e2e2;
			text-align: left;
		}

		/* Footer main content */
		#footerInnerContainer p {
			padding-top: 10px;
			padding-right: 0px;
			padding-bottom: 0px;
			padding-left: 0px;
		}
		
		/* Center the logo */
		#footerInnerContainer img {
			display: block;
  			margin-left: auto;
  			margin-right: auto;
		}
		
		/* Center the logo */
		#footerInnerContainer a {
			/* color: whitesmoke; */
		}
				
		/* Breadcrumb and stepper classes */
		/* -------------------------------- 
			xnugget info 
		-------------------------------- */
		.cd-nugget-info {
		  text-align: center;
		  position: absolute;
		  width: 100%;
		  height: 40px;
		  line-height: 40px;
		  top: 0;
		  left: 0;
		}
		.cd-nugget-info a {
		  position: relative;
		  font-size: 14px;
		  color: #<cfoutput>#accentColor#</cfoutput>;
		  -webkit-transition: all 0.2s;
		  -moz-transition: all 0.2s;
		  transition: all 0.2s;
		}
		.no-touch .cd-nugget-info a:hover {
		  opacity: .8;
		}
		.cd-nugget-info span {
		  vertical-align: middle;
		  display: inline-block;
		}
		.cd-nugget-info span svg {
		  display: block;
		}
		.cd-nugget-info .cd-nugget-info-arrow {
		  fill: #<cfoutput>#accentColor#</cfoutput>;
		}
		/* -------------------------------- 
		Basic Breadcrumb Styles
		-------------------------------- */
		.cd-breadcrumb, .cd-multi-steps {
		  max-width: 768px;
		  padding: 0.5em 1em;
		  margin: 1em auto;
		  background-color: #<cfoutput>#alternateBgColor#</cfoutput>;
		  border-radius: .25em;
		}
		.cd-breadcrumb::after, .cd-multi-steps::after {
		  clear: both;
		  content: "";
		  display: table;
		}
		.cd-breadcrumb li, .cd-multi-steps li {
		  display: inline-block;
		  float: left;
		  margin: 0.5em 0;
		}
		.cd-breadcrumb li::after, .cd-multi-steps li::after {
		  /* this is the separator between items */
		  display: inline-block;
		  content: '\00bb';
		  margin: 0 .6em;
		  color: #<cfoutput>#selectedTextColor#</cfoutput>;
		}
		.cd-breadcrumb li:last-of-type::after, .cd-multi-steps li:last-of-type::after {
		  /* hide separator after the last item */
		  display: none;
		}
		.cd-breadcrumb li > *, .cd-multi-steps li > * {
		  /* single step */
		  display: inline-block;
		  font-size: 1.4rem;
		  color: #<cfoutput>#selectedTextColor#</cfoutput>; /*#2c3f4c*/
		}
		.cd-breadcrumb li.current > *, .cd-multi-steps li.current > * {
		  /* selected step */
		  color: #<cfoutput>#selectedTextColor#</cfoutput>;
		}
		.no-touch .cd-breadcrumb a:hover, .no-touch .cd-multi-steps a:hover {
		  /* steps already visited */
		  color: #<cfoutput>#accentColor#</cfoutput>;
		}
		.cd-breadcrumb.custom-separator li::after, .cd-multi-steps.custom-separator li::after {
		  /* replace the default separator with a custom icon */
		  content: '';
		  height: 16px;
		  width: 16px;
		  background: url(<cfoutput>#customSeparater#</cfoutput>) no-repeat center center;
		  vertical-align: middle;
		}
		.cd-breadcrumb.custom-icons li > *::before, .cd-multi-steps.custom-icons li > *::before {
		  /* add a custom icon before each item */
		  content: '';
		  display: inline-block;
		  height: 20px;
		  width: 20px;
		  margin-right: .4em;
		  margin-top: -2px;
		  background: url(<cfoutput>#customIcon#</cfoutput>) no-repeat 0 0;
		  vertical-align: middle;
		}
		.cd-breadcrumb.custom-icons li:not(.current):nth-of-type(2) > *::before, .cd-multi-steps.custom-icons li:not(.current):nth-of-type(2) > *::before {
		  /* change custom icon using image sprites */
		  background-position: -20px 0;
		}
		.cd-breadcrumb.custom-icons li:not(.current):nth-of-type(3) > *::before, .cd-multi-steps.custom-icons li:not(.current):nth-of-type(3) > *::before {
		  background-position: -40px 0;
		}
		.cd-breadcrumb.custom-icons li:not(.current):nth-of-type(4) > *::before, .cd-multi-steps.custom-icons li:not(.current):nth-of-type(4) > *::before {
		  background-position: -60px 0;
		}
		.cd-breadcrumb.custom-icons li.current:first-of-type > *::before, .cd-multi-steps.custom-icons li.current:first-of-type > *::before {
		  /* change custom icon for the current item */
		  background-position: 0 -20px;
		}
		.cd-breadcrumb.custom-icons li.current:nth-of-type(2) > *::before, .cd-multi-steps.custom-icons li.current:nth-of-type(2) > *::before {
		  background-position: -20px -20px;
		}
		.cd-breadcrumb.custom-icons li.current:nth-of-type(3) > *::before, .cd-multi-steps.custom-icons li.current:nth-of-type(3) > *::before {
		  background-position: -40px -20px;
		}
		.cd-breadcrumb.custom-icons li.current:nth-of-type(4) > *::before, .cd-multi-steps.custom-icons li.current:nth-of-type(4) > *::before {
		  background-position: -60px -20px;
		}
		@media only screen and (min-width: 768px) {
		  .cd-breadcrumb, .cd-multi-steps {
			padding: 0 1.2em;
		  }
		  .cd-breadcrumb li, .cd-multi-steps li {
			margin: 1.2em 0;
		  }
		  .cd-breadcrumb li::after, .cd-multi-steps li::after {
			margin: 0 1em;
		  }
		  .cd-breadcrumb li > *, .cd-multi-steps li > * {
			font-size: 1.6rem;
		  }
		}
		/* -------------------------------- 
		Triangle breadcrumb
		-------------------------------- */
		@media only screen and (min-width: 768px) {
		  .cd-breadcrumb.triangle {
			/* reset basic style */
			background-color: transparent;
			padding: 0;
			margin: 0;
			font-size: 20%;
		  }
		  .cd-breadcrumb.triangle li {
			position: relative;
			padding: 0;
			margin: 0px 4px 0px 0;
		  }
		  .cd-breadcrumb.triangle li:last-of-type {
			margin-right: 0;
		  }
		  .cd-breadcrumb.triangle li > * {
			position: relative;
			/* This creates the arrow, oroginal padding: 1em .8em 1em 2.5em; */
			padding: 1em .8em 1em 2.5em;
			margin: 0;
			color: #<cfoutput>#textColor#</cfoutput>;
			background-color: #<cfoutput>#alternateBgColor#</cfoutput>;
			/* the border color is used to style its ::after pseudo-element */
			border-color: #<cfoutput>#alternateBgColor#</cfoutput>;
			font-size: <cfoutput>#breadCrumbTrianagleHeight#</cfoutput>!important;
		  }
		  .cd-breadcrumb.triangle li.current > * {
			/* selected step */
			color: #<cfoutput>#selectedTextColor#</cfoutput>;/*Text color on the selected item */
			background-color: #<cfoutput>#accentColor#</cfoutput>;
			border-color: #<cfoutput>#accentColor#</cfoutput>;
			<cfoutput>#breadCrumbTrianagleHeight#</cfoutput>!important;
		  }
		  .cd-breadcrumb.triangle li:first-of-type > * {
			padding-left: 1.6em;
			border-radius: .25em 0 0 .25em;
		  }
		  .cd-breadcrumb.triangle li:last-of-type > * {
			padding-right: 1.6em;
			border-radius: 0 .25em .25em 0;
		  }
		  .no-touch .cd-breadcrumb.triangle a:hover {
			/* steps already visited */
			color: #<cfoutput>#selectedTextColor#</cfoutput>;/*ffffff*/
			background-color: #<cfoutput>#accentColor#</cfoutput>;/*2c3f4c;*/
			border-color: #<cfoutput>#accentColor#</cfoutput>;/*2c3f4c;*/
		  }
		  .cd-breadcrumb.triangle li::after, .cd-breadcrumb.triangle li > *::after {
			/* 
				li > *::after is the colored triangle after each item
				li::after is the white separator between two items
			*/
			content: '';
			position: absolute;
			top: 0;
			left: 100%;
			content: '';
			height: 0;
			width: 0;
			/* 48px is the height of the <a> element */
			border: 24px solid transparent;
			border-right-width: 0;
			border-left-width: 20px;
		  }
		  .cd-breadcrumb.triangle li::after {
			/* this is the white separator between two items */
			z-index: 1;
			-webkit-transform: translateX(4px);
			-moz-transform: translateX(4px);
			-ms-transform: translateX(4px);
			-o-transform: translateX(4px);
			transform: translateX(4px);
			border-left-color: #ffffff;
			/* reset style */
			margin: 0;
		  }
		  .cd-breadcrumb.triangle li > *::after {
			/* this is the colored triangle after each element */
			z-index: 2;
			border-left-color: inherit;
		  }
		  .cd-breadcrumb.triangle li:last-of-type::after, .cd-breadcrumb.triangle li:last-of-type > *::after {
			/* hide the triangle after the last step */
			display: none;
		  }
		  .cd-breadcrumb.triangle.custom-separator li::after {
			/* reset style */
			background-image: none;
		  }
		  .cd-breadcrumb.triangle.custom-icons li::after, .cd-breadcrumb.triangle.custom-icons li > *::after {
			/* 50px is the height of the <a> element */
			border-top-width: 25px;
			border-bottom-width: 25px;
		  }

		  @-moz-document url-prefix() {
				.cd-breadcrumb.triangle li::after,
				.cd-breadcrumb.triangle li > *::after {
					/* fix a bug on Firefix - tooth edge on css triangle */
					border-left-style: dashed;
			}
		}
		/* -------------------------------- 
		Custom icons hover effects - breadcrumb and multi-steps
		-------------------------------- */
		@media only screen and (min-width: 768px) {
		  .no-touch .cd-breadcrumb.triangle.custom-icons li:first-of-type a:hover::before, .cd-breadcrumb.triangle.custom-icons li.current:first-of-type em::before, .no-touch .cd-multi-steps.text-center.custom-icons li:first-of-type a:hover::before, .cd-multi-steps.text-center.custom-icons li.current:first-of-type em::before {
			/* change custom icon using image sprites - hover effect or current item */
			background-position: 0 -40px;
		  }
		  .no-touch .cd-breadcrumb.triangle.custom-icons li:nth-of-type(2) a:hover::before, .cd-breadcrumb.triangle.custom-icons li.current:nth-of-type(2) em::before, .no-touch .cd-multi-steps.text-center.custom-icons li:nth-of-type(2) a:hover::before, .cd-multi-steps.text-center.custom-icons li.current:nth-of-type(2) em::before {
			background-position: -20px -40px;
		  }
		  .no-touch .cd-breadcrumb.triangle.custom-icons li:nth-of-type(3) a:hover::before, .cd-breadcrumb.triangle.custom-icons li.current:nth-of-type(3) em::before, .no-touch .cd-multi-steps.text-center.custom-icons li:nth-of-type(3) a:hover::before, .cd-multi-steps.text-center.custom-icons li.current:nth-of-type(3) em::before {
			background-position: -40px -40px;
		  }
		  .no-touch .cd-breadcrumb.triangle.custom-icons li:nth-of-type(4) a:hover::before, .cd-breadcrumb.triangle.custom-icons li.current:nth-of-type(4) em::before, .no-touch .cd-multi-steps.text-center.custom-icons li:nth-of-type(4) a:hover::before, .cd-multi-steps.text-center.custom-icons li.current:nth-of-type(4) em::before {
			background-position: -60px -40px;
		  }
		}
		/* -------------------------------- 
		Multi steps indicator 
		-------------------------------- */
		@media only screen and (min-width: 768px) {
		  .cd-multi-steps {
			/* reset style */
			background-color: transparent;
			padding: 0;
			text-align: center;
		  }

		  .cd-multi-steps li {
			position: relative;
			float: none;
			margin: 0.4em 40px 0.4em 0;
		  }
		  .cd-multi-steps li:last-of-type {
			margin-right: 0;
		  }
		  .cd-multi-steps li::after {
			/* this is the line connecting 2 adjacent items */
			position: absolute;
			content: '';
			height: 4px;
			background: #<cfoutput>#alternateBgColor#</cfoutput>;
			/* reset style */
			margin: 0;
		  }
		  .cd-multi-steps li.visited::after {
			background-color: #<cfoutput>#accentColor#</cfoutput>;
		  }
		  .cd-multi-steps li > *, .cd-multi-steps li.current > * {
			position: relative;
			color: #<cfoutput>#accentColor#</cfoutput>/*2c3f4c*/
		  }

		  .cd-multi-steps.custom-separator li::after {
			/* reset style */
			height: 4px;
			background: #<cfoutput>#alternateBgColor#</cfoutput>;
		  }

		  .cd-multi-steps.text-center li::after {
			width: 100%;
			top: 50%;
			left: 100%;
			-webkit-transform: translateY(-50%) translateX(-1px);
			-moz-transform: translateY(-50%) translateX(-1px);
			-ms-transform: translateY(-50%) translateX(-1px);
			-o-transform: translateY(-50%) translateX(-1px);
			transform: translateY(-50%) translateX(-1px);
		  }
		  .cd-multi-steps.text-center li > * {
			z-index: 1;
			padding: .6em 1em;
			border-radius: .25em;
			background-color: #<cfoutput>#alternateBgColor#</cfoutput>;
		  }
		  .no-touch .cd-multi-steps.text-center a:hover {
			background-color: #<cfoutput>#accentColor#</cfoutput>/*2c3f4c*/
		  }
		  .cd-multi-steps.text-center li.current > *, .cd-multi-steps.text-center li.visited > * {
			color: #ffffff;
			background-color: #<cfoutput>#accentColor#</cfoutput>;
		  }
		  .cd-multi-steps.text-center.custom-icons li.visited a::before {
			/* change the custom icon for the visited item - check icon */
			background-position: 0 -60px;
		  }

		  .cd-multi-steps.text-top li, .cd-multi-steps.text-bottom li {
			width: 80px;
			text-align: center;
		  }
		  .cd-multi-steps.text-top li::after, .cd-multi-steps.text-bottom li::after {
			/* this is the line connecting 2 adjacent items */
			position: absolute;
			left: 50%;
			/* 40px is the <li> right margin value */
			width: calc(100% + 40px);
		  }
		  .cd-multi-steps.text-top li > *::before, .cd-multi-steps.text-bottom li > *::before {
			/* this is the spot indicator */
			content: '';
			position: absolute;
			z-index: 1;
			left: 50%;
			right: auto;
			-webkit-transform: translateX(-50%);
			-moz-transform: translateX(-50%);
			-ms-transform: translateX(-50%);
			-o-transform: translateX(-50%);
			transform: translateX(-50%);
			height: 12px;
			width: 12px;
			border-radius: 50%;
			background-color: #<cfoutput>#alternateBgColor#</cfoutput>;
		  }
		  .cd-multi-steps.text-top li.visited > *::before,
		  .cd-multi-steps.text-top li.current > *::before, .cd-multi-steps.text-bottom li.visited > *::before,
		  .cd-multi-steps.text-bottom li.current > *::before {
			background-color: #<cfoutput>#accentColor#</cfoutput>;
		  }
		  .no-touch .cd-multi-steps.text-top a:hover, .no-touch .cd-multi-steps.text-bottom a:hover {
			color: #<cfoutput>#accentColor#</cfoutput>;
		  }
		  .no-touch .cd-multi-steps.text-top a:hover::before, .no-touch .cd-multi-steps.text-bottom a:hover::before {
			box-shadow: 0 0 0 3px rgba(150, 192, 61, 0.3);
		  }

		  .cd-multi-steps.text-top li::after {
			/* this is the line connecting 2 adjacent items */
			bottom: 4px;
		  }
		  .cd-multi-steps.text-top li > * {
			padding-bottom: 10px;
		  }
		  .cd-multi-steps.text-top li > *::before {
			/* this is the spot indicator */
			bottom: 0;
		  }

		  .cd-multi-steps.text-bottom li::after {
			/* this is the line connecting 2 adjacent items */
			top: 3px;
		  }
		  .cd-multi-steps.text-bottom li > * {
			padding-top: 10px;
		  }
		  .cd-multi-steps.text-bottom li > *::before {
			/* this is the spot indicator */
			top: 0;
		  }
		}
		/* -------------------------------- 
		Add a counter to the multi-steps indicator 
		-------------------------------- */
		.cd-multi-steps.count li {
		  counter-increment: steps;
		}

		.cd-multi-steps.count li > *::before {
		  content: counter(steps) " - ";
		}

		@media only screen and (min-width: 768px) {
		  .cd-multi-steps.text-top.count li > *::before,
		  .cd-multi-steps.text-bottom.count li > *::before {
			/* this is the spot indicator */
			content: counter(steps);
			height: 26px;
			width: 26px;
			line-height: 26px;
			font-size: 1.4rem;
			color: #ffffff;
		  }

		  .cd-multi-steps.text-top.count li:not(.current) em::before,
		  .cd-multi-steps.text-bottom.count li:not(.current) em::before {
			/* steps not visited yet - counter color */
			color: #<cfoutput>#accentColor#</cfoutput>/*2c3f4c*/
		  }

		  .cd-multi-steps.text-top.count li::after {
			bottom: 11px;
		  }

		  .cd-multi-steps.text-top.count li > * {
			padding-bottom: 24px;
		  }

		  .cd-multi-steps.text-bottom.count li::after {
			top: 11px;
		  }

		  .cd-multi-steps.text-bottom.count li > * {
			padding-top: 24px;
		  }
		}
		
		/* -------------------------------- 
			Dialogs 
		-------------------------------- */
		/* Hide scrollbar for Chrome, Safari and Opera */
		#extAlertDialog::-webkit-scrollbar {
		  display: none;
		}

		/* Hide scrollbar for IE, Edge and Firefox */
		#extAlertDialog {
		  -ms-overflow-style: none;  /* IE and Edge */
		  scrollbar-width: none;  /* Firefox */
		}
		
		/* Hide scrollbar for Chrome, Safari and Opera */
		#extOkCancelDialog::-webkit-scrollbar {
		  display: none;
		}

		/* Hide scrollbar for IE, Edge and Firefox */
		#extOkCancelDialog {
		  -ms-overflow-style: none;  /* IE and Edge */
		  scrollbar-width: none;  /* Firefox */
		}
		
		/* Hide scrollbar for Chrome, Safari and Opera */
		#yesNoDialog::-webkit-scrollbar {
		  display: none;
		}

		/* Hide scrollbar for IE, Edge and Firefox */
		#yesNoDialog {
		  -ms-overflow-style: none;  /* IE and Edge */
		  scrollbar-width: none;  /* Firefox */
		}
		
		/* -------------------------------- 
			Utility Classes 
		-------------------------------- */
		applyPadding { 
			padding: <cfif session.isMobile>10<cfelse>20</cfif>px !important;
		} 
		
		.wide {
			min-width: 100% !important;
		}
		
		/* The constrainer table will constrain one or many different div's and spans to a certain size. It is handy to use when you are trying to contain the size of elements created by an older libary that does not use responsive design. */
		.constrainerTable {
			/* The parent element (this table) should be positioned relatively. */
			position: relative;
			/* Now that the parent element has a width setting, make sure that the width does not ever exceed this */
			max-width: 100%;
		}	
		
		/* Helper function to the constrainerTable to break the text when it exceeds the table dimensions */
		.constrainerTable .constrainContent {
			/* Use the root width var */
			width: var(--contentWidth);
			max-width: 100%
		}
		
		.constrainerTable th {
			max-width: var(--contentWidth);
		}
		
		.constrainerTable td {
			word-break: break-word;
		}
		
		/* code to make sure that a horizontal scroll bar does not appear in prism's code widget */ 
		code[class*="language-"], pre[class*="language-"] {
			white-space: pre-wrap !important;
			word-break: break-word !important;
		}
		
		.spacer {
			display: inline-block;
			width: 100%;
		}
		
		/* Used to force a cell to only use the space that is necessary to fit its content */
		td.fitwidth {
			width: 1%;
			white-space: nowrap;
		}
		
		/* Remove the padding of the li elements when using the disqus recent comments widget. */
		#removeUlPadding ul  {
			padding: 0;
			list-style-type: none;
		}
		
		/* -------------------------------- 
			Fancybox 
		-------------------------------- */
		.fancybox-effects img {
			border: 1px solid #808080; /* Gray border */
			border-radius: 3px;  /* Rounded border */
			padding: 5px; 
		}

		/* Add a hover effect (blue shadow) */
		.fancybox-effects img:hover {
		  	box-shadow: 0 0 2px 1px rgba(0, 140, 186, 0.5);
			opacity: .82;
		}
				
		.fancybox-custom .fancybox-skin {
			box-shadow: 0 0 25px #808080;/*b4b6ba*/
			border-radius: 3px;
		}
		
		.fancybox-custom .fancybox-skin {
			box-shadow: 0 0 25px #808080;/*b4b6ba*/
			border-radius: 3px;
		}
		
		/* -------------------------------- 
			Kendo FX 
		-------------------------------- */
		 #fxZoom {
			left: 0px;
            position: relative;
            -webkit-transform: translateZ(0);
			width: 500px;
            height: 250px;
        }

        #fxZoom img {
			/* Force the image to 50% */
			-moz-transform:scale(0.5);
    		-webkit-transform:scale(0.5);
    		transform:scale(0.5);
        }
		
		/* FancyBox Thumnails */
		.thumbnail {
			position: relative;
			<cfif darkTheme>/* Darken the image for dark themes */
			filter: brightness(90%);</cfif>
			width: <cfif session.isMobile>100<cfelse>225</cfif>px;
			height: <cfif session.isMobile>100<cfelse>128</cfif>px;
			padding: 5px;
			padding-top: 5px;
			padding-left: 5px;
			padding-right: 5px;
			padding-bottom: 5px;
			box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 4px 8px 0 rgba(0, 0, 0, 0.19);
			overflow: hidden;
		}
		
		.thumbnail img {
			position: absolute;
			left: 50%;
			top: 50%;
			height: 100%;
			width: auto;
			-webkit-transform: translate(-50%,-50%);
			  -ms-transform: translate(-50%,-50%);
				  transform: translate(-50%,-50%);
		}
		
		.thumbnail img.portrait {
		  width: 100%;
		  height: auto;
		}
		
		/* See https://aaronparecki.com/2016/08/13/4/css-thumbnails */
		.squareThumbnail {
			/* set the desired width/height and margin here */
			width: 128px;
			height: 128px;
			<cfif darkTheme>/* Darken the image for dark themes */
			filter: brightness(90%);</cfif>
			margin-right: 1px;
			position: relative;
			overflow: hidden;
			display: inline-block;
		}
		
		.squareThumbnail img {
			position: absolute;
			left: 50%;
			top: 50%;
			height: 100%;
			width: auto;
			-webkit-transform: translate(-50%,-50%);
			  -ms-transform: translate(-50%,-50%);
				  transform: translate(-50%,-50%);
		}
		.squareThumbnail img.portrait {
			width: 100%;
			height: auto;
		}
		
		/* -------------------------------- 
			Kendo Theme Color Properties
		-------------------------------- */
		.kendo-accent-color {background-color: #<cfoutput>#accentColor#</cfoutput>; }
		.kendo-base-color {background-color: #<cfoutput>#baseColor#</cfoutput>; }
		.kendo-header-bg-color {background-color: #<cfoutput>#headerBgColor#</cfoutput>; }
		.kendo-header-text-color {background-color: #<cfoutput>#headerTextColor#</cfoutput>; }
		.kendo-hover-bg-color {background-color: #<cfoutput>#hoverBgColor#</cfoutput>; }
		.kendo-text-color {color: #<cfoutput>#textColor#</cfoutput>; }
		.kendo-selected-text-color {color: #<cfoutput>#selectedTextColor#</cfoutput>; }
		.kendo-content-bg-color {background-color: #<cfoutput>#contentBgColor#</cfoutput>; }
		.kendo-alternate-bg-color {background-color: #<cfoutput>#alternateBgColor#</cfoutput>; }
		.kendo-error-color {background-color: #<cfoutput>#errorColor#</cfoutput>; }
		.kendo-warning-color {background-color: #<cfoutput>#warningColor#</cfoutput>; }
		.kendo-success-color {background-color: #<cfoutput>#successColor#</cfoutput>; }
		.kendo-info-color {background-color: #<cfoutput>#infoColor#</cfoutput>; }
<cfif not standAlone>
	</style>
	<!--- Script to resize the square thumnails. --->
	<script>
		document.addEventListener("DOMContentLoaded", function(event) { 
				var addImageOrientationClass = function(img) {
				if (img.naturalHeight > img.naturalWidth) {
					img.classList.add("portrait");
				}
			}

			// Add "portrait" class to thumbnail images that are portrait orientation
			var images = document.querySelectorAll(".squareThumbnail img");
			for (var i=0; i<images.length; i++) {
				if(images[i].complete) {
					addImageOrientationClass(images[i]);
				} else {
					images[i].addEventListener("load", function(evt) {
						addImageOrientationClass(evt.target);
					});
				}
			}
		});
	</script>
</cfif><!---<cfif not standAlone>--->