@charset "utf-8";
/* CSS Document */
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

/* Containers */
/* Fixed navigation menu at the top of the page when the user scrolls down */
#fixedNavHeader {
	position: fixed;
	display: none;
	top: 0px;
	height: <cfif kendoTheme contains 'materialblack'><cfif session.isMobile>55<cfelse>65</cfif><cfelse><cfif session.isMobile>35<cfelse>45</cfif></cfif>px;
	width: <cfif headerBannerWidth eq '100%' or session.isMobile>100%<cfelse>var(--contentWidth)</cfif>;
	color: <cfoutput>#blogNameTextColor#</cfoutput>; /* text color */
	font-family: "Eras ITC", "Eras Light ITC", "erasBook", sans-serif;
	font-size: <cfif kendoTheme eq 'office365'><cfif session.isMobile>.75em<cfelse>1em</cfif><cfelse><cfif session.isMobile>.9em<cfelse>1em</cfif></cfif>;
	<cfif menuBackgroundImage neq "">
	background-color: transparent !important;
	background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');/* Without this, there is a white ghosting around this div. */
	background-repeat: repeat-x;
	</cfif>
	/* Subtle drop shadow on the header banner that stretches across the page. */
	box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
	/* Center it */
	left: calc(-50vw + 50%);
	right: calc(-50vw + 50%);
	margin-left: auto;
	margin-right: auto;
	z-index: 1;
}
<cfsilent>
<!--- TODO This needs to be in a function. Logic to determine what side the padding should occur when the alignBlogMenuWithBlogContent argument is true. --->
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
</cfsilent>
/* Main wrapper within the header table. */
#topWrapper {
	<cfoutput>#topWrapperCssString#</cfoutput>
}

/* The headerContainer is a *child* flex container of the mainPanel below. This may be counter-intuitive, but the main content is stuffed into the blogContent and I want the header to play nicely and following along. This container will be resized if it does not match the parent mainPanel container using the setScreenProperties function at the top of the page. */
#headerContainer {
	/* Note: if the headerBackgroundImage is not specified, we will not use a drop shadow here */
	<!--- If the headerBannerWidth is 100%, hard code the width value, otherwise, use the content width value --->
	width: <cfif headerBannerWidth eq '100%'>100%<cfelse>var(--contentWidth)</cfif>;
	<cfif headerBackgroundImage neq ''>
	/* Subtle drop shadow on the header banner that stretches across the page. */
	box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
	</cfif>
}

#blogNameContainer {
	font-family: 'Eras Demi'; /* Kaufmann Script Bold */
	font-size: <cfif session.isMobile>1.50em<cfelse>1.75em</cfif>; 
	font-weight: bold;
	/* The container may need to have some padding as the menu underneath it is not going to left align with the text since the menu is going to start prior to the first text item. */
	padding-left: 13px; 
	text-shadow: 0px 4px 8px rgba(0, 0, 0, 0.19); /* The drop shadow should closely mimick the shadow on the main blog layer.*/
	color: <cfoutput>#blogNameTextColor#</cfoutput>; /* Plain white has too high of a contrast imo. */
	vertical-align: center;
}

/* Menu container. Controls the placement of the menu. */
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
/* the top menu is 60 pixels in height. */
#topMenu {	
	<cfif menuBackgroundImage neq "">
	background-color: transparent !important;
	background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');/* Without this, there is a white ghosting around this div. */
	background-repeat: repeat-x;
	</cfif>
	border: 0;
	color: <cfoutput>#blogNameTextColor#</cfoutput>; /* text color */
	font-family: "Eras ITC", "Eras Light ITC", "erasBook", sans-serif;
	font-size: <cfif kendoTheme eq 'office365'><cfif session.isMobile>.75em<cfelse>1em</cfif><cfelse><cfif session.isMobile>.9em<cfelse>1em</cfif></cfif>;

	top: 32px;
	height: 20px;
	/* Note: an incorrect width setting will stretch the table container and skew the center allignment if not set properly. */
}

#siteSearchButton {
	/* Set the site search icon to match the blog text color */
	color: <cfoutput>#blogNameTextColor#</cfoutput>; /* Plain white has too high of a contrast imo. */
}

/* Remove the vertical border. The borders display a vertical line between the menu items and since we have custom images and colors on the banners, I want to remove these. */
.k-widget.k-menu-horizontal>.k-item {
  border: 0;
}

<cfif kendoTheme eq 'default' or kendoTheme eq 'highcontrast' or kendoTheme eq 'material' or kendoTheme eq 'silver'><!--- Both default and high contrast have the same header. Material needs to have a darker text when selecting a menu item--->
/* fixedNavHeader states. */
#fixedNavHeader.k-menu .k-state-hover,
#fixedNavHeader.k-menu .k-state-hover .k-link,
#fixedNavHeader.k-menu .k-state-border-down
 /* 
.k-menu .k-state-hover, (background and selected item when hovering)
.k-menu .k-state-hover .k-link (background and selected item with a link when hovering)
.k-menu .k-state-border-down, (backgound and selected item when scrolling down)
*/
{
	color: <cfoutput>#blogNameTextColor#</cfoutput>;
	font-family: "Eras ITC", "Eras Light ITC",  sans-serif ;
	background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
}

/* topMenu States */
#topMenu.k-menu .k-state-hover,
#topMenu.k-menu .k-state-hover .k-link,
#topMenu.k-menu .k-state-border-down
 /* 
.k-menu .k-state-hover, (background and selected item when hovering)
.k-menu .k-state-hover .k-link (background and selected item with a link when hovering)
.k-menu .k-state-border-down, (backgound and selected item when scrolling down)
*/
{
	color: <cfoutput>#blogNameTextColor#</cfoutput>;
	font-family: "Eras ITC", "Eras Light ITC",  sans-serif ;
	background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
}
</cfif><!---<cfif kendoTheme eq 'default' or kendoTheme eq 'highcontrast'>--->

/* Remove the vertical border. The borders display a vertical line between the menu items and since we have custom images and colors on the banners, I want to remove these. */
.k-widget.k-menu-horizontal>.k-item {
  border: 0;
}

#logo {
	border: 0;
	position: relative;
	padding-top: <cfoutput>#logoPaddingTop#</cfoutput>;
	padding-left: <cfoutput>#logoPaddingLeft#</cfoutput>;
	padding-right: <cfoutput>#logoPaddingRight#</cfoutput>;
	padding-bottom: <cfoutput>#logoPaddingBottom#</cfoutput>;
}

/* Kendo class over-rides. */
<cfif session.isMobile>
/* Increase the close button on mobile */
.k-window-titlebar .k-i-close {
	zoom: 1.2;
}
</cfif>
/* Change the window font size (its too big for mobile). The Kendo window is not responsive, and has it's own internal properties that are hardcoded, so I need to reset properties using inline styles, such as font-size. */
.k-window-titlebar {
	font-size: 16px; /* set font-size */
}