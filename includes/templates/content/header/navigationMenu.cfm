<cfsilent>
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "navigationMenu">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- This template drives the navigation menu and is a unordered HTML list. This template uses the getContentOutputData function to determine the content. It will display custom content that is in the database or use the default code below if no custom code exists  --->
<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
	<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
	<cfinvokeargument name="isMobile" value="#session.isMobile#">
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<cfinvokeargument name="themeRef" value="#URL.optArgs#">
	</cfif>
</cfinvoke>		
		
<!--- Determine if we should display the data or use the default HTML --->
<cfif len(contentOutputData)>
	<!-- Replace the menuDivName and layerNumber strings with the actual strings specified by the menuDivName and layerNumber CF variables. This logic is a one off --->
	<cfset contentOutputData = replace(contentOutputData, 'menuDivName', menuDivName, 'one')>
	<cfset contentOutputData = replace(contentOutputData, 'layerNumber', layerNumber, 'one')>
	<cfset displayContentOutputData = true>		
</cfif>
<!--- ********* End content template logic *********--->
			
<cfparam name="menuDivName" default="">
<cfparam name="layerNumber" default="">

</cfsilent>				
							<cfif displayContentOutputData>
								<!--- Include the content template for the navigation script --->
								<cfoutput>#contentOutputData#</cfoutput>
							<cfelse>
								<ul id="<cfoutput>#menuDivName#</cfoutput>" class="topMenu">
									<li class="toggleSidebarPanelButton">
										<a href="javascript:toggleSideBarPanel(<cfoutput>#layerNumber#</cfoutput>)" aria-label="Menu"><span class="fa fa-bars"></span></a>
									</li>
									<li>
										Menu
										<ul>
											<!--- Note: the first menu option should not have spaces if you want the menu to be aligned with the blog text. --->
											<cfif menuDivName eq 'fixedNavMenu'><li onclick="javascript:scrollToTop();"><span class="fa fa-arrow-circle-up"></span> Top</li></cfif>
											<li><a href="<cfoutput>#application.siteUrl#</cfoutput>"><cfoutput>#application.BlogDbObj.getBlogTitle()#</cfoutput></a></li>
											<cfif cgi.http_host contains 'galaxieblog.org'><li><a href="https://gregoryalexander.com/blog/">Gregory's Blog</a></li><cfelseif cgi.http_host contains 'gregoryalexander.com'><li><a href="https://galaxieblog.org/">Galaxie Blog Documentation</a></li></cfif>
										<cfif len(application.parentSiteName)>
											<li><a href="<cfoutput>#application.parentSiteLink#</cfoutput>"><cfoutput>#application.parentSiteName#</cfoutput></a></li>
										</cfif>
											<li><a href="javascript:createAddCommentSubscribeWindow('', 'contact', <cfoutput>#session.isMobile#</cfoutput>);">Contact</a></li>
											<!--- or <li><a href="http://www.gregoryalexander.com/blog/?contact">Contact</a></li>--->
											<cfif menuDivName eq 'fixedNavMenu'><li onclick="javascript:scrollToBottom();"><span class="fa fa-arrow-circle-down"></span> Bottom</li></cfif>
										</ul>
									</li>
									<li>
										Categories
										<ul>
										<cfloop from="1" to="#arrayLen(parentCategories)#" index="i">
											<cfsilent>
											<cftry>
												<!--- Extract the data --->
												<cfset parentCategoryId = parentCategories[i]["CategoryId"]>
												<cfset parentCategory = parentCategories[i]["Category"]>
												<cfset parentCategoryLink = application.blog.makeCategoryLink(parentCategoryId)>
												<cfset parentCategoryPostCount = parentCategories[i]["PostCount"]>
												<cfcatch type="any">
													<cfset parentCategoryId = "">
													<cfset parentCategory = "">
													<cfset parentCategoryLink = "">
												</cfcatch>
											</cftry>
											</cfsilent>
											<cfif isNumeric(parentCategoryPostCount) and parentCategoryPostCount gt 0><li><cfoutput><a href="#parentCategoryLink#">#parentCategory#</a></cfoutput></li></cfif>
										</cfloop>
										</ul>
									</li>
									<li>
										About
										<ul>
											<li><a href="javascript:createAboutWindow(1);">About this Blog</a></li>
											<li><a href="javascript:createAboutWindow(2);">Biography</a></li>
											<li><a href="javascript:createAboutWindow(3);">Download</a></li>
										</ul>
									</li>
									<!--- Only show the theme menu when a theme has not yet been selected. Once a theme has been selected, that becomes the only available theme. Also, the themes are not shown on mobile clients --->
									<cfif not selectedTheme and not session.isMobile>
									<li>
										Themes 
										<ul>
											<cfloop from="1" to="#arrayLen(themeNames)#" index="i"><cfoutput><li><a href="#application.baseUrl#?theme=#themeNames[i]['ThemeAlias']#">#themeNames[i]['ThemeName']#</a></li></cfoutput></cfloop>
										</ul>
									</li>
									</cfif>
									<!--- Don't show the admin link with mobile. There is not enough room. --->
									<cfif not session.isMobile>
									<li>
									<!--- Admin. --->
									<a href="<cfoutput>#application.baseUrl#/admin/</cfoutput>" aria-label="<cfif not application.Udf.isLoggedIn()>Login<cfelse>Blog Administration</cfif>"><span class="k-icon k-i-user"></span></a>
									<!--- Allow the user to logout. --->
									<cfif application.Udf.isLoggedIn()>
										<ul>
											<li><a href="<cfoutput>#application.baseUrl#/admin/?logout=1</cfoutput>">Logout</a></li>
										</ul>
									</cfif>
									</li>
									</cfif>
									<li class="siteSearchButton">
										<cfsilent>
										<!--- Set the font size of the search and menu icons. This logic sets the icons to be (2 for desktop, 0 for mobile) tenths of a percentage less than the font size of the menu font's above. --->
										<cfif kendoTheme eq 'office365'>
											<cfif session.isMobile>
												<cfset searchAndMenuFontSize = ".75em">
											<cfelse>
												<cfset searchAndMenuFontSize = ".8em">
											</cfif>
										<cfelse>
											<cfif session.isMobile>
												<cfset searchAndMenuFontSize = "1em">
											<cfelse>
												<cfset searchAndMenuFontSize = ".8em">
											</cfif>
										</cfif>
										</cfsilent>
										<a href="javascript:createSearchWindow();" aria-label="Search"><span class="fa fa-search" style="font-size:<cfoutput>#searchAndMenuFontSize#</cfoutput>"></span></a>
									</li>
								</ul>
							</cfif><!---<cfif displayContentOutputData>--->