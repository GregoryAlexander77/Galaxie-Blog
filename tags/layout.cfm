<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : layout.cfm
	Author       : Raymond Camden 
	Created      : July 4, 2003
	Last Updated : May 18, 2007
	History      : Changed top level doc type to work with Kendo UI (ga 10/26/2018)
		   	   	   Added Kendo libraries. (ga 10/26/2018)
			   	   Reset history for version 4.0
				   Added trackback js code, switch to request.rooturl (rkc 9/22/05)
				   Switched to app.rooturl (rkc 10/3/05)
				   frame buster code, use tag cloud (rkc 8/22/06)
				   small white space change (rkc 9/5/06)
				   don't log when doing the getEntry (rkc 2/28/07)
				   use podmanager, by Scott P (rkc 4/13/07)
				   support category as list (rkc 5/18/07)
	Purpose		 : Layout
--->

<cfif thisTag.executionMode is "start">

	<cfif isDefined("attributes.title")>
		<cfset additionalTitle = ": " & attributes.title>
	<cfelse>	
		<cfset additionalTitle = "">
		<cfif isDefined("url.mode") and url.mode is "cat">
			<!--- can be a list --->
			<cfset additionalTitle = "">
			<cfloop index="cat" list="#url.catid#">
			<cftry>
				<cfset additionalTitle = additionalTitle & " : " & application.blog.getCategory(cat).categoryname>
				<cfcatch></cfcatch>
			</cftry>
			</cfloop>

		<cfelseif isDefined("url.mode") and url.mode is "entry">
			<cftry>
				<!---
				Should I add one to views? Only if the user hasn't seen it.
				--->
				<cfset dontLog = false>
				<cfif structKeyExists(session.viewedpages, url.entry)>
					<cfset dontLog = true>
				<cfelse>
					<cfset session.viewedpages[url.entry] = 1>
				</cfif>
				<cfset entry = application.blog.getEntry(url.entry,dontLog)>
				<cfset additionalTitle = ": #entry.title#">
				<cfcatch></cfcatch>
			</cftry>
		</cfif>
	</cfif>

	<cfoutput>
	<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
	<head>
		<title>#htmlEditFormat(application.blog.getProperty("blogTitle"))##additionalTitle#</title>
		<meta name="title" content="#application.blog.getProperty("blogTitle")##additionalTitle#" />
		<meta name="description" content="#application.blog.getProperty("blogDescription")##additionalTitle#" />
		<meta name="keywords" content="#application.blog.getProperty("blogKeywords")#" />
		<meta http-equiv="content-type" content="text/html; charset=utf-8" />
		<link rel="alternate" type="application/rss+xml" title="RSS" href="#application.rooturl#/rss.cfm?mode=full" />

		<!---Kendo scripts (GA 10/25/2018)--->
		<cfinclude template="../includes/kendoScripts.cfm">
		<!---End (GA 10/25/2018)--->
		<!--- Removed this script by commenting out. It uses an outdated version of jQuery (ga)
		<script src="#application.rooturl#/includes/jquery.arclite.js" type="text/javascript"></script>
		--->

		<style type="text/css">
		@import "#application.rooturl#/includes/styles/style.css";
		@import "#application.rooturl#/includes/styles/header-default.css";
		@import "#application.rooturl#/includes/styles/content-default.css";
		@import "#application.rooturl#/includes/styles/side-default.css";
		</style>

		<!---
		Removed jQuery include as they are now included in the application in the kendoScripts.cfm template (ga 10/27/2018).
		Removed launchComment(id) and launchCommentSub(id) and replaced functions with a Kendo window. (ga)
		Also removed 'tweetback' logic as it was causing errors.
		--->

	</head>

	<body onload="if(top != self) top.location.replace(self.location.href);">

	 <!-- page -->
	 <div id="page" class="with-sidebar k-content">
	  <div id="header-wrap">
	   <div id="header" class="block-content">
		 <div id="pagetitle">
		  <h1><a href="#application.rootURL#">#htmlEditFormat(application.blog.getProperty("blogTitle"))#</a></h1>
		  <!--- 
			Use a different theme to provide your own header (ga)
		  --->
		  <div class="clear"></div>

		  <!-- search form -->
		  <div class="search-block">
			<div class="searchform-wrap">
			  <form method="get" id="searchform" action="#application.rooturl#/search.cfm">
			   <fieldset>
				<input type="text" name="searchbox" id="searchbox" value="Search" onfocus="if(this.value == 'Search') {this.value = '';}" onblur="if (this.value == '') {this.value = 'Search';}" class="k-textbox" />
				<input type="submit" value="Go" class="go" class="k-button"/>
			   </fieldset>
			  </form>
			</div>
		  </div>
		  <!-- /search form -->

		<!---Kendo windows. Create an empty div that we will use to anchor a dynamic Kendo window to add comments.
		Important note: kendo widgets must be placed into the right defined containter. In this case, it is Raymond's pageTitle div above. I tried placing it above the pageTitle div, 
		and it permenently hid the content behind the kendo window. When converting an existing page to Kendo, you may have to play around with the placement of the Kendo window container
		to get everything right. (ga 10/27/2018) --->
		<div id="addCommentWindow" name="addCommentWindow"></div>
		<div id="addCommentSubWindow" name="addCommentSubWindow"></div>

		<!---Kendo window scripts--->
		<script>	
			// Add comment window -------------------------------------------------------------------------------------------------------------------------------------------

			// Add comment window script
			function createAddCommentWindow(Id) {

				// Remove the window if it already exists
				if ($("#chr(35)#addCommentWindow").length > 0) {
					$("#chr(35)#addCommentWindow").parent().remove();
				}

				jQuery(document.body).append('<div id="addCommentWindow"></div>');
				jQuery('#chr(35)#addCommentWindow').kendoWindow({
					title: "Add Comment",
					actions: ["Minimize", "Maximize", "Refresh", "Close"],
					modal: false,
					resizable: true,
					draggable: true,
					width: '450px',
					height: '625px',
					iframe: false, // Don't use iframes unless it is content derived outside of your own site. 
					content: "/blogCfc/client/addcomment.cfm?id=" + Id,
					close: function() {
						$('#chr(35)#addCommentWindow').kendoWindow('destroy');
					}
				}).data('kendoWindow').center();// Center the window.
			}

			// Add comment subscription window ---------------------------------------------------------------------------------------------------------------------------------

			// Add comment subscription window script
			function createAddCommentSubWindow(Id) {

				// Remove the window if it already exists
				if ($("#chr(35)#addCommentSubWindow").length > 0) {
					$("#chr(35)#addCommentSubWindow").parent().remove();
				}

				jQuery(document.body).append('<div id="addCommentSubWindow"></div>');
				jQuery('#chr(35)#addCommentSubWindow').kendoWindow({
					title: "Subscribe to comments",
					actions: ["Minimize", "Maximize", "Refresh", "Close"],
					modal: false,
					resizable: true,
					draggable: true,
					width: '450px',
					height: '625px',
					iframe: false, // Don't use iframes unless it is content derived outside of your own site. 
					content: "/blogCfc/client/addsub.cfm?id=" + Id,
					close: function() {
						$('#chr(35)#addCommentSubWindow').kendoWindow('destroy');
					}
				}).data('kendoWindow').center();// Center the window.
			}

		</script>
		<!---End windows (ga 10/27/2018)--->

		 </div>

		 <!-- main navigation -->
		 <div id="nav-wrap1">
		  <div id="nav-wrap2">
			<ul id="nav">
			 <li><a href="#application.rooturl#" class="fadeThis"><span>Home</span></a></li>
			 <li><a href="#application.rooturl#/contact.cfm" class="fadeThis"><span>Contact</span></a></li>
			 <li><a href="#application.rooturl#/search.cfm" class="fadeThis"><span>Search</span></a></li>
			 <!---<li><a href="##" class="fadeThis"><span>Background variations</span></a></li>--->

			<!---
			An example menu item with a fly out sub menu.
			 <li><a href="##" class="fadeThis"><span>More color variations</span></a>
			   <ul>
				<li><a href="index-var7.html" class="fadeThis"><span>Green</span></a></li>
				<li><a href="index-var6.html" class="fadeThis"><span>Red</span></a></li>
				<li><a href="index-var5.html" class="fadeThis"><span>Blue</span></a></li>
				<li><a href="index-default.html" class="fadeThis"><span>Brown (Default)</span></a>
				  <ul>
				   <li><a href="##" class="fadeThis"><span>Just testing subs</span></a></li>
				   <li><a href="##" class="fadeThis"><span>Another sub-menu...</span></a></li>
				  </ul>
				</li>
			   </ul>
			 </li>
			 --->
			</ul>
		  </div>
		 </div>
		 <!-- /main navigation -->

	   </div>

	   <div id="main-wrap1">
		<div id="main-wrap2">
		 <div id="main" class="block-content">
		  <div class="mask-main rightdiv">
		   <div class="mask-left">
			<div class="col1">
			  <div id="main-content">
	</cfoutput>
<cfelse><!---<cfif thisTag.executionMode is "start">--->
	<cfoutput>
				</div>
				</div>
			<div class="col2">

			  <ul id="sidebar">

			   <li class="block">

				<cfinclude template="getpods.cfm">

			   </li>

			  </ul>

			</div>
		   </div>
		  </div>
		  <div class="clear-content"></div>
		 </div>
		</div>
	   </div>

	  </div>

	 <!-- footer -->
	 <div id="footer">
	  <div class="block-content">
		 <div class="copyright">
		   <a href="http://www.blogcfc.com">BlogCFC #application.blog.getVersion()#</a> by Raymond Camden | <a href="#application.rootURL#/rss.cfm?mode=full" rel="noindex,nofollow">RSS</a> | Arclite theme by <a href="http://digitalnature.ro/projects/arclite">digitalnature</a>
		 </div>
	  </div>
	 </div>
	 <!-- /footer -->

	 </div>
	 <!-- /page -->

	 <script type="text/javascript">
	  /* <![CDATA[ */
		var isIE6 = false; /* <- do not change! */
		var isIE = false;  /* <- do not change! */
		var lightbox = 1;  /* lightbox on/off ? */
	  /* ]]> */
	 </script>
	 <!--[if lte IE 6]> <script type="text/javascript"> isIE6 = true; isIE = true; </script> <![endif]-->
	 <!--[if gte IE 7]> <script type="text/javascript"> isIE = true; </script> <![endif]-->
	<!-- Go to www.addthis.com/dashboard to customize your tools -->
	<!---AddThis is likely conflicting with Kendo. Removed for now (ga)--->
	<!---<script type="text/javascript" src="//s7.addthis.com/js/300/addthis_widget.js#chr(35)#pubid=ra-5bd6a992a4792f6b"></script>--->

	</body>

	</html>
	</cfoutput>
</cfif><!---<cfif thisTag.executionMode is "start">--->
<cfsetting enablecfoutputonly=false>