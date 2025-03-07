<cfsilent>
<!--- //******************************************************************************************************************
			Core logic (queries the database and sets vars)
//********************************************************************************************************************--->
	
<!--- Determine whether we should disable the cache. We are only using cache on non admin sites for Lucee --->
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
	<cfset cacheName = "fontTemplateMobile#themeId#">
<cfelse>
	<cfset cacheName = "fontTemplate#themeId#">
</cfif>
</cfsilent>
<!--- Lucee's cfcache tag seems to cache the entire page and does not differentiate using the key for some odd reason. This causes the differentiation between mobile and desktop clients to be rendered the same. I am using scopecache insted of cfcache with Lucee --->
<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" cachename="#cachename#" scope="application" timeout="#application.timeout#" disabled="#disableCache#">
	<cfinclude template="#application.baseUrl#/includes/templates/font.cfm" />
</cfmodule>
<cfsilent>
<!---//*******************************************************************************************************************
			Global and body .css
//********************************************************************************************************************--->
	
<!--- Cache notes: this template contains dynamic images and other elements that are dependent upon the theme. It should not be cached. It won't matter much as this code is minimized. --->
</cfsilent>
<cfinclude template="#application.baseUrl#/includes/templates/blogContentCss.cfm" />
<cfsilent>			
<!---//*******************************************************************************************************************
			Top menu html
//********************************************************************************************************************--->
	
<!--  Outer container. This container controls the blog width. The 'k-alt' class is used when there are alternating rows and you want to differentiate them. Typically, it is a darker color that 'k-content'. We will set the min width of the container to be 968 pixels and the min width of the blog content to be 640 pixels. This should give approximately 300 miniumum pixels to the side bar on the right. -->
	
<!--- Set up cache. We need to save the theme and the device type (ie mobile) in the cache name. --->
<cfif session.isMobile>
	<cfset cacheName = "topMenuHtml#themeId#Mobile">
<cfelse>
	<cfset cacheName = "topMenuHtml#themeId#">
</cfif>
	
<!--- Note: there are two different layouts depending upon the stretchHeaderAcrossPage. --->
</cfsilent>
	
<cfif not stretchHeaderAcrossPage>
<table id="mainBlog" class="k-alt" cellpadding="0" cellspacing="0" align="center">
	<tr>
	 <td>
		<!--- Note: this needs to be an independent layer for the blog menu to keep the z-index intact in order to float over the top of the rest of the layers, such as the footer. !!! We need to use the themeId as each theme uses different background images in the menu --->
		<cfif pageId eq 1>
			<!--- Lucee's cfcache tag seems to cache the entire page and does not differentiate using the key for some odd reason. This causes the differentiation between mobile and desktop clients to be rendered the same. I am using scopecache insted of cfcache with Lucee --->
			<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" cachename="#cachename#" scope="application" timeout="#application.timeout#" disabled="#disableCache#">
				<cfinclude template="#application.baseUrl#/includes/templates/topMenuHtml.cfm" />
			</cfmodule>
		<cfelse>
			<cfinclude template="#application.baseUrl#/includes/templates/topMenuHtml.cfm" />
		</cfif>
	 </td>
	</tr>
	<cfsilent>
	<!---//***************************************************************************************************************
				Javascript for the blog's Kendo widgets and UI interactions.
	//****************************************************************************************************************--->
	</cfsilent>
<cfelse><!---<cfif not stretchHeaderAcrossPage>--->
	<!--- Note: this needs to be an independent layer for the blog menu to keep the z-index intact in order to float over the top of the rest of the layers, such as the footer. !!! We need to use the themeId as each theme uses different background images in the menu --->
<cfif pageId eq 1>
	<!--- Lucee's cfcache tag seems to cache the entire page and does not differentiate using the key for some odd reason. This causes the differentiation between mobile and desktop clients to be rendered the same. I am using scopecache insted of cfcache with Lucee --->
	<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" cachename="#cachename#" scope="application" timeout="#application.timeout#" disabled="#disableCache#">
		<cfinclude template="#application.baseUrl#/includes/templates/topMenuHtml.cfm" />
	</cfmodule>
<cfelse>
	<cfinclude template="#application.baseUrl#/includes/templates/topMenuHtml.cfm" />
</cfif>
	
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
		<cfelseif pageTypeId eq 2>
			<!-- Dynamic content loaded via jQuery and Ajax. Never cache this -->
		<div id='adminContent'>
			<cfinclude template="#application.baseUrl##getTemplatePathByPageName(pageName)#" />
		</div><!---<div id='adminContent'>--->
		</cfif><!---<cfelseif pageTypeId eq 2>--->
	</main>
	</td>
   </tr>
</table>
<cfif pageTypeId gt 1>
	<cfsilent>	
	<!---//***************************************************************************************************************
			Sidebar	
			Note: when the blogContentHtml template is used, the side bar panel should not be used here.
	//****************************************************************************************************************--->

	<!--- Set up cache. We need to save the theme and the device type (ie mobile) in the cache name. --->
	<cfif session.isMobile>
		<cfset cacheName = "sideBarPanelHtml#kendoTheme#Mobile">
	<cfelse>
		<cfset cacheName = "sideBarPanelHtml#kendoTheme#">
	</cfif>

	</cfsilent>			
	<!--- Note: this needs to be an independent layer for the blog menu to keep the z-index intact in order to float over the top of the rest of the layers, such as the footer. This needs to refresh every 30 minutes --->
	<cfif pageId eq 1>
		<!--- Lucee's cfcache tag seems to cache the entire page and does not differentiate using the key for some odd reason. This causes the differentiation between mobile and desktop clients to be rendered the same. I am using scopecache insted of cfcache with Lucee --->
		<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" cachename="#cachename#" scope="application" timeout="#application.timeout#" disabled="#disableCache#">
			<!-- Side Bar Panel -->
			<cfinclude template="#application.baseUrl#/includes/templates/sideBarPanel.cfm" />
		</cfmodule>
	<cfelse>
		<cfinclude template="#application.baseUrl#/includes/templates/sideBarPanel.cfm" />
	</cfif>
</cfif><!---<cfif pageTypeId gt 1>--->
<cfsilent>
<!---//*****************************************************************************************************************
			Footer (the administrative interface does not need a footer)
//**************************************************************************************************************--->
		
	<!--- Note: the blog content HTML template uses ColdFusion's cache instead of scopecache as we need to capture all of the URL variables. --->
	<cfif session.isMobile>
		<cfset cacheKey = 'footerHtmlMobile'>
	<cfelse>
		<cfset cacheKey = 'footerHtml'>
	</cfif>
	<!--- Determine whether to use the cache or not depending upon the disableCache variable. --->
	<cfif disableCache>
		<cfset useCache = false>
	<cfelse>
		<cfset useCache = true>
	</cfif>
</cfsilent>
<!--- This template is cached by both the main blog and admin page --->
<!---<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" cachename="#cachename#" scope="application" disabled="#disableCache#">--->
	<cfinclude template="#application.baseUrl#/includes/templates/content/footer/footer.cfm" />
<!---</cfmodule>--->
