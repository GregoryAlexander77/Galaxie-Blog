<!--- Note: this page depends on the pageSettings.cfm template. And, this page is often used in a standalone environment to pass css vars to the tinymce editor. If the page is standalone, we need to include the pageSettings template. --->
<cfparam name="standalone" default="false" type="boolean">
<cfif standalone>
	<cfset pageTypeId = 1><!--- Blog --->
	<cfinclude template="pageSettings.cfm">	
</cfif>
<!--- Get the themes accent color --->
<cfset accentColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
	
	<!--- Minimized using https://minifycode.com/css-minifier/ --->
	<style>
	<!--- Minimize again before going live... --->
	<cfif application.minimizeCode and 1 eq 2>
		#mainBlog{position:relative;display:table;width:var(--contentWidth);margin:0 auto;box-shadow:0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);<cfif session.isMobile> opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;visibility:visible;</cfif>}#mainPanel{display:table-row;width:var(--contentWidth);<cfif session.isMobile> opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;visibility:visible;font-size: <cfoutput><cfif (fontSize-4) lt 12>12<cfelse>#fontSize-4#</cfif></cfoutput>pt;<cfelse></cfif>}#blogContent{display:table-cell;margin:0;<cfif session.isMobile> width: 95%;max-width:var(--mainContainerWidth);padding-top:10px;padding-right:10px;padding-bottom:10px;padding-left:10px;opacity:0.<cfoutput>#siteOpacity#</cfoutput>;visibility:visible;<cfelse> width: <cfoutput>#mainContainerWidth#</cfoutput>%;max-width:var(--mainContainerWidth);min-width:600px;padding-top:20px;padding-right:20px;padding-bottom:20px;padding-left:20px;</cfif> vertical-align: top;overflow:hidden}.blogPost p.postDate{position:relative;width:38px;height: <cfif darkTheme>50px<cfelse>38px</cfif>;display:block;margin:0;padding:0px;text-align:center;float:left;line-height:100%;border:1px solid #fff}.blogPost p.postDate span.month{position:absolute;font-size: <cfif session.isMobile>0.55em<cfelse>0.70em</cfif>;border-bottom:1px solid #fff;width: <cfif darkTheme>34px<cfelse>100%</cfif>;top:0;left:0;height:19px;text-transform:uppercase;padding:2px}.blogPost p.postDate span.day{font-size: <cfif session.isMobile>0.60em<cfelse>0.75em</cfif>;display:table-cell;vertical-align:middle;bottom:1px;top:25px;left:0;height:19px;width: <cfif darkTheme>34px<cfelse>100%</cfif>;padding:2px;position:absolute}.blogPost p.postAuthor span.info{display:block}.blogPost p.postAuthor{margin:0 0 0 43px;padding:0 12px;font-size:1em;font-style:italic;min-height:38px;color:#75695e;height:auto !important;height:38px;line-height:100%}.innerContentContainer{margin-top:5px;padding-left: <cfif session.isMobile>10<cfelse>20</cfif>px;padding-right: <cfif session.isMobile>10<cfelse>20</cfif>px;display:block}.postContent{margin-top:5px;display:block}.entryImage img{max-width:100%;height:auto;box-shadow:0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0,0,0,0.19)}.entryMap{height:<cfif session.isMobile>320<cfelse>564</cfif>px;width: auto; box-shadow:0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0,0,0,0.19)}.panel{margin:0;<cfif session.isMobile> padding-top: 10px;padding-right:10px;padding-bottom:10px;padding-left:10px;opacity:0.<cfoutput>#siteOpacity#</cfoutput>;visibility:visible;<cfelse> padding-top: 20px;padding-right:20px;padding-bottom:20px;padding-left:20px;</cfif> vertical-align: top;overflow:hidden}.login{height:480px;margin-bottom:-240px;margin-top:-240px;top:50%;left:50%}applyPadding{padding: <cfif session.isMobile>10<cfelse>20</cfif>px !important}.wide{min-width:100% !important}.fade{transition:opacity 500ms ease-in-out;opacity:0}.fade.shown{opacity:1;background:0 0}#sidebar{display: <cfif session.isMobile>none<cfelse>table-cell</cfif>;margin:0;padding-top:20px;padding-right:20px;padding-bottom:20px;padding-left:10px;width: <cfoutput>#sideBarContainerWidth#</cfoutput>%;min-width:375px;vertical-align:top;overflow:hidden}#sidebarPanel{visibility:hidden;flex-direction:column;<cfif not session.isMobile> position: absolute;</cfif> height: 100%;width: <cfif session.isMobile>275px<cfelse>425px</cfif>;-webkit-touch-overflow:scroll;z-index:5;opacity: <cfoutput>#siteOpacity#</cfoutput>;margin:0;padding:10px 10px 10px 10px;vertical-align:top;border-right:thin}.k-rpanel-left,.k-rpanel-right{min-width:0px}#sidebarPanel.k-rpanel-expanded{<cfif session.isMobile> <cfelse> </cfif> margin-top: <cfif session.isMobile>105px<cfelse>110px</cfif>;margin-left:5%;margin-left:var(--contentPaddingPercent);-webkit-box-shadow:0px 0 10px 0 rgba(0,0,0,.3);-moz-box-shadow:0px 0 10px 0 rgba(0,0,0,.3);box-shadow:0 0 10px rgba(0,0,0,.3)}#sidebarPanelWrapper{display:flex;flex-direction:column;height:100%;width:100%;-webkit-touch-overflow:scroll}.calendarWidget h3.topContent{font-size:1em;padding-top:0px;padding-right:0px;padding-bottom:10px;padding-left:0px;border-bottom:1px solid #e2e2e2;text-align:left}.calendarWidget{padding:0}.calendarWidget div{padding:0px}.widget{margin-top:0px;margin-right:0px;margin-bottom:20px;margin-left:0px;padding:0;border:1px solid #e2e2e2;border-radius:3px}.widget div{}.widget h3.topContent{font-size:1em;padding-top:0px;padding-right:0px;padding-bottom:10px;padding-left:0px;border-bottom:1px solid #e2e2e2;text-align:left}.widget p.bottomContent{padding-top:10px;padding-right:0px;padding-bottom:0px;padding-left:0px;border-top:1px solid #e2e2e2}.widget #collapse{float:right}.widget.placeholder{opacity:0.4;border:1px dashed #a6a6a6}.panel-wrap{display:table;margin:0 0 20px;border:1px solid #e5e5e5}#blogCalendar{text-align:center;width:100%}#blogCalendarPanel{text-align:center;width:100%}.mediaPlayer{white-space:nowrap;overflow:hidden;z-index:0}video{max-width:100%;height:auto}table.tableBorder{border:1px solid <cfif darkTheme>whitesmoke<cfelse>black</cfif>;width:100%;border-radius:3px;border-spacing:0}.fixedCommentTable{table-layout:fixed;width:100%}.fixedCommentTablePadding{width:5px}.fixedCommentTableContent{min-width:100%;width:100%}.fixedPodTable{table-layout:fixed;width:100%}.fixedPodTable td{color: <cfif darkTheme>whitesmoke<cfelse>#2e2e2e</cfif>;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.fixedPodTableWithWrap td{color: <cfif darkTheme>whitesmoke<cfelse>#2e2e2e</cfif>;overflow:hidden;text-overflow:ellipsis}td.border{border-top:1px solid #ddd}.rowDivider{font-size:0px;height:1px;background:#F00 border: solid 1px #F00;width:100%;overflow:hidden}td.k-alt{font-weight:normal !important}.k-widget.k-calendar{width:90%}.k-widget.k-calendar .k-content tbody td{width:90%}.avatar{border-radius:50%;-moz-border-radius:50%;-webkit-border-radius:50%}#footerDiv{<cfif session.isMobile> opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;visibility:visible;</cfif> width: var(--contentWidth);box-shadow:0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);left:calc(-50vw + 50%);right:calc(-50vw + 50%);margin-left:auto;margin-right:auto;z-index:1;border:1px solid #e2e2e2;border-radius:3px}#footerInnerContainer{margin-top: <cfif session.isMobile>10<cfelse>20</cfif>px;margin-left: <cfif session.isMobile>10<cfelse>20</cfif>px;margin-right: <cfif session.isMobile>10<cfelse>20</cfif>px;margin-bottom: <cfif session.isMobile>10<cfelse>20</cfif>px;padding: <cfif session.isMobile>10<cfelse>20</cfif>px;display:block;border:1px solid #e2e2e2;border-radius:3px}#footerInnerContainer h4{font-size:1em;padding-top:0px;padding-right:0px;padding-bottom:10px;padding-left:0px;border-bottom:1px solid #e2e2e2;text-align:left}#footerInnerContainer p{padding-top:10px;padding-right:0px;padding-bottom:0px;padding-left:0px}#footerInnerContainer img{display:block;margin-left:auto;margin-right:auto}#footerInnerContainer a{}.constrainerTable{position:relative;max-width:100%}.constrainerTable .constrainContent{width:var(--contentWidth);max-width:100%}.constrainerTable th{max-width:var(--contentWidth)}.constrainerTable td{word-break:break-word}code[class*="language-"],pre[class*="language-"]{white-space:pre-wrap !important;word-break:break-word !important}.spacer{display:inline-block;width:100%}td.fitwidth{width:1%;white-space:nowrap}#removeUlPadding ul{padding:0;list-style-type:none}.fancybox-effects img{border:1px solid #808080;border-radius:3px;padding:5px}.fancybox-effects img:hover{box-shadow:0 0 2px 1px rgba(0, 140, 186, 0.5);opacity: .82}.fancybox-custom .fancybox-skin{box-shadow:0 0 25px #808080;border-radius:3px}.fancybox-custom .fancybox-skin{box-shadow:0 0 25px #808080;border-radius:3px}#fxZoom{left:0px;position:relative;-webkit-transform:translateZ(0);width:500px;height:250px}#fxZoom img{-moz-transform:scale(0.5);-webkit-transform:scale(0.5);transform:scale(0.5)}.thumbnail{position:relative;<cfif darkTheme> filter: brightness(90%);</cfif> width: 225px;height:128px;padding:5px;padding-top:5px;padding-left:5px;padding-right:5px;padding-bottom:5px;box-shadow:0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 4px 8px 0 rgba(0, 0, 0, 0.19);overflow:hidden}.thumbnail img{position:absolute;left:50%;top:50%;height:100%;width:auto;-webkit-transform:translate(-50%,-50%);-ms-transform:translate(-50%,-50%);transform:translate(-50%,-50%)}.thumbnail img.portrait{width:100%;height:auto}.squareThumbnail{width:128px;height:128px;<cfif darkTheme> filter: brightness(90%);</cfif> margin-right: 1px;position:relative;overflow:hidden;display:inline-block}.squareThumbnail img{position:absolute;left:50%;top:50%;height:100%;width:auto;-webkit-transform:translate(-50%,-50%);-ms-transform:translate(-50%,-50%);transform:translate(-50%,-50%)}.squareThumbnail img.portrait{width:100%;height:auto}
	<cfelse><!---<cfif application.minimizeCode>--->
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
		  /* margin-top: 10px; */
		  display: block;
		}

		.blogPost p.postAuthor {
		  /*background: transparent url(images/post-info.png) no-repeat left top;*/
		  margin: 0 0 0 43px;
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
				
		.innerContentContainer {
			/* Apply padding to all of the elements within a blog post. */
			margin-top: 5px; 
			padding-left: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			padding-right: <cfif session.isMobile>10<cfelse>20</cfif>px;
			display:block;
		}

		.postContent {
			/* Apply padding to post content. */
			margin-top: 5px; 
			display: block;

		}
		
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
		
		/* Login screen needs some extra height otherwise it will be at the top of the screen */
		.login {
			height: 480px;
			margin-bottom: -240px; /* half of width */
			margin-top: -240px;  /* half of height */
			top: 50%;
			left: 50%;
		}
		
		applyPadding { 
			padding: <cfif session.isMobile>10<cfelse>20</cfif>px !important;
		} 
		
		.wide {
			min-width: 100% !important;
		}
		
		/* Lazy loading image classes */
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
		
		/* Kendo UI applies default min-width (320px) to left and right panel elements, which causes the difference in width between top and left/right panels. We are overriding this default style with the following CSS rule: */
		.k-rpanel-left, .k-rpanel-right {
			min-width: 0px;
		 }
		
		/* Place the layer where we want it and put a drop shadow on the panel when it is expanded. Note! the setSidebarPadding javascript function also sets some style properties. */
		#sidebarPanel.k-rpanel-expanded {
		<cfif pageTypeId eq 1>/* The sidebar panel is inside the main container and we don't  want any top margin*/<cfelse><cfif session.isMobile>/* On mobile, the table height is 100px. We want to give about 5 pixels more height to allow the divider to be seen. */<cfelse>/* On desktop, the table height is 105px. We want to give about 5 pixels more height to allow the divider to be seen. */</cfif></cfif>
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
			border: 1px solid #<cfoutput>#accentColor#</cfoutput>;
			border-radius: 4px;
			/* cursor: move; */
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
			border-color: <cfoutput>#accentColor#</cfoutput>;
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
			border-color: <cfoutput>#accentColor#</cfoutput>;
			position: absolute;
			border-top-color: transparent;
			border-bottom-color: transparent;
			border-left-color: transparent;
			transform: rotate(180deg);
			transform-origin: center right;
		}
				
		.panel-wrap {
			display: table;
			margin: 0 0 20px;
			/* Controls the width of the container */
			border: 1px solid #e5e5e5;
		}

		#blogCalendar {
			/* Align the calendar in the center. We must use the text-align property for this (I know that this is counter-intuitive). */
			text-align: center;
			width: 100%;
		}
		
		#blogCalendarPanel {
			/* Align the calendar in the center. We must use the text-align property for this (I know that this is counter-intuitive). */
			text-align: center;
			width: 100%;
		}
		
		/* Other than the recent comment pod, don't  wrap pod content, and if the text exceeds the size of the html tables, ellipsis the text (like so 'and...')  */
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
		
		/* Table classes */
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
			background:#F00
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
		
		/* Footer classes */
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
		
		/* Utility classes */
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
		
		/* FancyBox */
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
		
		/* Kendo FX */
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
	</cfif><!---<cfif application.minimizeCode>--->	
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