<!doctype html>
<cfprocessingdirective suppressWhiteSpace="true">
<cfsilent>
	
<!---
	Name         	: index.cfm
	Author       	: Gregory Alexander
	Created/Updated : See GalaxieBlog GitHub repository

Note: for html5, this doctype needs to be the first line on the page. (ga 10/27/2018) --->
<!--- When developing for Lucee you may want to place to following code on the first line to flush the cache. --->
<!---<cfset pagePoolClear()>--->
	
<!--- //******************************************************************************************************************
			Page settings.
//********************************************************************************************************************--->
	
<!--- Unique page settings that may vary on each different page. --->
<cfset pageId = 1>
<cfset pageName = "Blog"><!--- Blog --->
<cfset pageTypeId = 1><!--- Blog --->

<!--- Common and theme settings and includes the getMode tag in order to set the params for the getPost query. The pageSettings also determines when we should cache the page depending upon if the user is logged in. --->
<cfinclude template="#application.baseUrl#/includes/templates/pageSettings.cfm">

<!--- //******************************************************************************************************************
			Core logic (queries the database and sets vars)
//********************************************************************************************************************--->
	
<!--- Determine whether we should disable the cache. --->
<cfset disableCache = application.blog.getDisableCache()>	
<!--- Get post information from the db --->
<cfinclude template="#application.baseUrl#/includes/templates/coreLogic.cfm">

<!--- //******************************************************************************************************************
			Page output
//********************************************************************************************************************--->
</cfsilent>
<html lang="en-US"><head><cfoutput>
	
<!---<cfdump var="#getPost#">--->
<cfinclude template="#application.baseUrl#/includes/templates/head.cfm" />
</head>
</cfoutput>	
<cfsilent>
<!--- //******************************************************************************************************************
			Responsive site javascript (handles the width of the containers)
//********************************************************************************************************************--->
<!--- Do not cache this! --->
	
</cfsilent>
<cfinclude template = "#application.baseUrl#/includes/templates/responsiveJs.cfm" />
<cfsilent>
<!--- //******************************************************************************************************************
			Body tag
//********************************************************************************************************************--->
	
</cfsilent>
<!---<cfdump var="#URL#">--->
<body onload="if(top != self) top.location.replace(self.location.href);" onresize="setScreenProperties()">
<cfsilent>
<!---//*******************************************************************************************************************
			Font .css
//********************************************************************************************************************--->

<!--- Set up cache. This needs to use the themeId as the fonts are different for each theme. The fonts should never expire. This code is also minimized. --->
<cfif session.isMobile>
	<cfset cacheName = "fontThemeId=#themeId#Mobile">
<cfelse>
	<cfset cacheName = "fontThemeId=#themeId#">
</cfif>
<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. This can't be in a cfsilent block --->
</cfsilent>
<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/fonts/#cacheName#.cfm" debug="false" disabled="#disableCache#">
<cfinclude template="#application.baseUrl#/includes/templates/font.cfm" />
</cfmodule>

<cfsilent>
<!---//*******************************************************************************************************************
			Global and body .css
//********************************************************************************************************************--->
	
<!--- Cache notes: this template contains dynamic images and other elements that are dependent upon the theme. It should not be cached. --->
</cfsilent>
<cfinclude template="#application.baseUrl#/includes/templates/blogContentCss.cfm" />
<cfsilent>		
<!---//*******************************************************************************************************************
			Top menu html
//********************************************************************************************************************--->
	
<!--  Outer container. This container controls the blog width. The 'k-alt' class is used when there are alternating rows and you want to differentiate them. Typically, it is a darker color that 'k-content'. We will set the min width of the container to be 968 pixels and the min width of the blog content to be 640 pixels. This should give approximately 300 miniumum pixels to the side bar on the right. -->
	
<!--- Set up cache. We need to save the theme and the device type (ie mobile) in the cache name. --->
<cfif session.isMobile>
	<cfset cacheName = "topMenuThemeId=#themeId#Mobile">
<cfelse>
	<cfset cacheName = "topMenuThemeId=#themeId#">
</cfif>
	
<!--- Note: there are two different layouts depending upon the stretchHeaderAcrossPage. --->
</cfsilent>
	
<cfif not stretchHeaderAcrossPage>
<table id="mainBlog" class="k-alt" cellpadding="0" cellspacing="0" align="center">
	<tr>
	 <td>
		<!--- Note: this needs to be an independent layer for the blog menu to keep the z-index intact in order to float over the top of the rest of the layers, such as the footer. !!! We need to use the themeId as each theme uses different background images in the menu --->
		<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/header/#cacheName#.cfm" debug="false" disabled="#disableCache#">
			<cfinclude template="#application.baseUrl#/includes/templates/topMenuHtml.cfm" />
		</cfmodule>
	 </td>
	</tr>
	<cfsilent>
	<!---//***************************************************************************************************************
				Javascript for the blog's Kendo widgets and UI interactions.
	//****************************************************************************************************************--->
	</cfsilent>
<cfelse><!---<cfif not stretchHeaderAcrossPage>--->
	<!--- Note: this needs to be an independent layer for the blog menu to keep the z-index intact in order to float over the top of the rest of the layers, such as the footer. !!! We need to use the themeId as each theme uses different background images in the menu --->
<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/header/#cacheName#.cfm" debug="false" disabled="#disableCache#">
	<cfinclude template="#application.baseUrl#/includes/templates/topMenuHtml.cfm" />
</cfmodule>
	
<table id="mainBlog" class="k-alt" cellpadding="0" cellspacing="0" align="center">
</cfif><!---<cfif not stretchHeaderAcrossPage>--->
   <tr>
	<td>
		<cfinclude template="#application.baseUrl#/includes/templates/blogJsContent.cfm" />
	<cfsilent>
	<!---//***************************************************************************************************************
				Blog content html
	//****************************************************************************************************************--->
		
	<!--- Note: the blog content HTML template is too sophisticated to cache the entire template. Instead, we will cache parts of it  --->
	</cfsilent>			
	<!-- Blog body -->
	<main>
		<cfif pageTypeId eq 1>
			<cfinclude template="#application.baseUrl#/includes/templates/blogContentHtml.cfm" />
		<cfelse>
			<div id='contentInnerContainer' class="k-content"><!--- This must be a content container class --->
				<!-- Dynamic content loaded via jQuery and Ajax. -->
				<cfinclude template="#application.baseUrl##getTemplatePathByPageName(pageName)#" /><!--- The getTemplatePathByPageName is in /common/function/page.cfm --->
			</div><!--<div id='adminContent'>-->
		</cfif><!---<cfif pageTypeId eq 1>--->
	</main>
	<nav><!--Navigation menu invoked from hamburger -->
		<input type="hidden" id="sidebarPanelState" name="sidebarPanelState" value="initial"/>
		<cfsilent>
		<!---//***************************************************************************************************************
				Sidebar div
		In classic mode, the side bar div is always displayed on the right side of the blog page. It is also used as a responsive panel on desktop devices when the screen size is small. We will not include it if the break point is not 0 or is equal or above 50000. If the chosen theme type is classic, this get's loaded first and then the panel below gets loaded. If the device is mobile or the theme is a modern theme, this sidebar does not exist.
		//****************************************************************************************************************--->

		<!--- We need to differentiate material and non-material themes to appy the right settings to the buttons --->
		<cfif kendoTheme contains 'material'>
			<cfset materialTheme = true>
		<cfelse>
			<cfset materialTheme = false>
		</cfif>
		</cfsilent>	
		<cfif breakpoint gt 0>
			<div id="sidebar">
				<!--- The cfmodule below identical to a cfinclude and has no end tag and is not part of galaxieCache. Make sure to supply the sidebar type. This is a duplicate sidebar when using desktop and the theme type is classic --->
				<cfmodule template="#application.baseUrl#/includes/templates/content/pods/index.cfm" sideBarType="div" scriptTypeString="#scriptTypeString#"  materialtheme="#materialTheme#" modernTheme="#modernTheme#" darkTheme="#darktheme#">
			</div><!---<nav id="sidebar">--->
		</cfif>

		<cfsilent>
		<!---//***************************************************************************************************************
					Sidebar panel
		This sidebar panel is always a fly-out panel on the left of the page. This panel is a duplicate of the sidebar div when the theme type is classic. If the theme type is modern or when the device is mobile, this is the only panel on the page. This panel is invoked when the user clicks on the hamburger icon in the menu at the top of the page.
		//****************************************************************************************************************--->

		<!--- We need to differentiate material and non-material themes to appy the right settings to the buttons --->
		<cfif kendoTheme contains 'material'>
			<cfset materialTheme = true>
		<cfelse>
			<cfset materialTheme = false>
		</cfif>
		</cfsilent>	
		<nav id="sidebarPanel" class="k-content">
			<div id="sidebarPanelWrapper" name="sidebarPanelWrapper" class="flexScroll"> 
				<!--- This cfmodule acts like a cfinclude and is not part of galaxieCache. Make sure to suppply the sideBarType argument. DIV --->
				<cfmodule template="#application.baseUrl#/includes/templates/content/pods/index.cfm" sideBarType="panel" scriptTypeString="#scriptTypeString#"  materialTheme="#materialTheme#" modernTheme="#modernTheme#" darkTheme="#darktheme#">
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
	</nav>
	</td>
   </tr>
</table>
<cfif pageTypeId gt 1>
	<cfsilent>	
	<!---//***************************************************************************************************************
			Sidebar	
			Note: when the blogContentHtml template is used, the side bar panel should not be used.
	//****************************************************************************************************************--->
		
	<!--- Set up cache. We need to save the theme and the device type (ie mobile) in the cache name. --->
	<cfif session.isMobile>
		<cfset cacheName = "sideBarPanelHtml#kendoTheme#Mobile">
	<cfelse>
		<cfset cacheName = "sideBarPanelHtml#kendoTheme#">
	</cfif>
	<!--- Note: this needs to be an independent layer for the blog menu to keep the z-index intact in order to float over the top of the rest of the layers, such as the footer. This needs to refresh every 30 minutes. Notes: this is refreshed every 30 minutes. Caching is also applied to some of the individual pod templates --->
	<!-- Side Bar Panel -->
	</cfsilent>			
	<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="application" timeout="#(60*30)#" disabled="#disableCache#">
	<cfinclude template="#application.baseUrl#/includes/templates/sideBarPanel.cfm" />
	</cfmodule>
</cfif><!---<cfif pageTypeId gt 1>--->
<cfsilent>
<!---//*****************************************************************************************************************
			Footer (the administrative interface does not need a footer)
//**************************************************************************************************************--->
		
<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. The module or tag can't be in a cfsilent block --->
<cfif session.isMobile>
	<cfset cachename = 'footerHtmlMobile'>
<cfelse>
	<cfset cachename = 'footerHtml'>
</cfif>
</cfsilent>
<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. This can't be in a cfsilent block --->
<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/footer/#cacheName#.cfm" debug="false" disabled="#disableCache#">
	<cfinclude template="#application.baseUrl#/includes/templates/content/footer/footer.cfm" />
</cfmodule>  
<cfsilent>
	<!---//***************************************************************************************************************
				Tail end scripts
	//****************************************************************************************************************--->	
</cfsilent>
<cfinclude template="#application.baseUrl#/includes/templates/tailEndScripts.cfm" />
<!--- 
Note: if the Zion theme is screwed up, check the use custom theme setting in the ini file.
--->
</body>
</html>
</cfprocessingdirective>