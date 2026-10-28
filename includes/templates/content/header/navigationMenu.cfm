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
									<cfsilent>
									<!--- 2026-10-10 (4.8): the owner's own Menu links, the categories that have posts, and the collections marked
									Show in Menu - see blog.cfc's getMenuLinks/getMenuLabels/getMenuCollections and the admin site's Configure
									Menu window. Replaces the hard-coded "Docs" menu (every collection whose alias started with "docs-") and the
									hard-coded links between gregoryalexander.com and galaxieblog.org, which are now ordinary Menu links. --->
									<cfset menuLinks = application.blog.getMenuLinks()>
									<cfset menuLabels = application.blog.getMenuLabels()>
									<cfset menuCollections = application.blog.getMenuCollections()>
									<cfset menuCategories = []>
									<cfloop from="1" to="#arrayLen(parentCategories)#" index="i">
										<cftry>
											<cfif isNumeric(parentCategories[i]["PostCount"]) and parentCategories[i]["PostCount"] gt 0>
												<cfset arrayAppend(menuCategories, { name: parentCategories[i]["Category"], link: application.blog.makeCategoryLink(parentCategories[i]["CategoryId"]) })>
											</cfif>
											<cfcatch type="any"></cfcatch>
										</cftry>
									</cfloop>
									</cfsilent>
									<li>
										Menu
										<ul>
											<!--- Note: the first menu option should not have spaces if you want the menu to be aligned with the blog text. --->
											<cfif menuDivName eq 'fixedNavMenu'><li onclick="javascript:scrollToTop();"><span class="fa fa-arrow-circle-up"></span> Top</li></cfif>
											<li><a href="<cfoutput>#application.siteUrl#</cfoutput>"><cfoutput>#application.BlogDbObj.getBlogTitle()#</cfoutput></a></li>
										<cfif arrayLen(menuLinks)>
											<cfloop array="#menuLinks#" index="menuLink">
											<li><a href="<cfoutput>#encodeForHtmlAttribute(menuLink.linkUrl)#</cfoutput>"<cfif menuLink.newWindow> target="_blank" rel="noopener"</cfif>><cfoutput>#encodeForHtml(menuLink.label)#</cfoutput></a></li>
											</cfloop>
										<cfelseif len(application.parentSiteName)>
											<!--- Until the owner saves their own Menu links, keep showing the older single "parent site" link from Blog Settings. --->
											<li><a href="<cfoutput>#application.parentSiteLink#</cfoutput>"><cfoutput>#application.parentSiteName#</cfoutput></a></li>
										</cfif>
											<!--- Only when the blog can send email (2026-10-27): the contact window emails the message, and a new blog without
											mail settings hung, then lost it (blog.cfc mailIsSetUp). --->
											<cfif application.blog.mailIsSetUp()><li><a href="javascript:createAddCommentSubscribeWindow('', 'contact', <cfoutput>#session.isMobile#</cfoutput>);">Contact</a></li></cfif>
											<cfif menuDivName eq 'fixedNavMenu'><li onclick="javascript:scrollToBottom();"><span class="fa fa-arrow-circle-down"></span> Bottom</li></cfif>
										</ul>
									</li>
								<cfif not session.isMobile and menuLabels.combined and arrayLen(menuCategories) and arrayLen(menuCollections)>
									<!--- One menu on computers too (Configure Menu, 2026-10-24, owner: galaxieblog's Categories held one item next to its
									Docs menu): the phone's combined dropdown, always shown. Not galaxieMenuCombined, which the wrap script hides. --->
									<li>
										<cfoutput>#encodeForHtml(menuLabels.mobile)#</cfoutput>
										<ul>
											<li class="k-state-disabled">Categories</li>
											<cfloop array="#menuCategories#" index="menuCategory"><li><a href="<cfoutput>#menuCategory.link#</cfoutput>"><cfoutput>#menuCategory.name#</cfoutput></a></li></cfloop>
											<li class="k-separator"></li>
											<li class="k-state-disabled"><cfoutput>#encodeForHtml(menuLabels.collections)#</cfoutput></li>
											<cfloop array="#menuCollections#" index="menuCollection"><li><a href="<cfoutput>#application.blog.makeCollectionLink(menuCollection.pageCollectionId)#</cfoutput>"><cfoutput>#menuCollection.title#</cfoutput></a></li></cfloop>
										</ul>
									</li>
								<cfelseif not session.isMobile>
									<!--- Desktop: Categories and the collections menu side by side, each hidden when it has nothing in it. --->
									<cfif arrayLen(menuCategories)>
									<li class="galaxieMenuSplit">
										Categories
										<ul>
											<cfloop array="#menuCategories#" index="menuCategory"><li><a href="<cfoutput>#menuCategory.link#</cfoutput>"><cfoutput>#menuCategory.name#</cfoutput></a></li></cfloop>
										</ul>
									</li>
									</cfif>
									<cfif arrayLen(menuCollections)>
									<li class="galaxieMenuSplit">
										<cfoutput>#encodeForHtml(menuLabels.collections)#</cfoutput>
										<ul>
											<cfloop array="#menuCollections#" index="menuCollection"><li><a href="<cfoutput>#application.blog.makeCollectionLink(menuCollection.pageCollectionId)#</cfoutput>"><cfoutput>#menuCollection.title#</cfoutput></a></li></cfloop>
										</ul>
									</li>
									</cfif>
									<!--- The phone's combined dropdown, hidden: when a narrow window or a tablet wraps the menu, the script at the end
									of this template shows it instead of the two above (2026-10-22, owner). --->
									<cfif arrayLen(menuCategories) and arrayLen(menuCollections)>
									<li class="galaxieMenuCombined" style="display: none;">
										<cfoutput>#encodeForHtml(menuLabels.mobile)#</cfoutput>
										<ul>
											<li class="k-state-disabled">Categories</li>
											<cfloop array="#menuCategories#" index="menuCategory"><li><a href="<cfoutput>#menuCategory.link#</cfoutput>"><cfoutput>#menuCategory.name#</cfoutput></a></li></cfloop>
											<li class="k-separator"></li>
											<li class="k-state-disabled"><cfoutput>#encodeForHtml(menuLabels.collections)#</cfoutput></li>
											<cfloop array="#menuCollections#" index="menuCollection"><li><a href="<cfoutput>#application.blog.makeCollectionLink(menuCollection.pageCollectionId)#</cfoutput>"><cfoutput>#menuCollection.title#</cfoutput></a></li></cfloop>
										</ul>
									</li>
									</cfif>
								<cfelseif arrayLen(menuCategories) and arrayLen(menuCollections)>
									<!--- Phones have less room: one dropdown with both lists, each under a heading. The headings are disabled
									menu items so a tap on them does nothing. --->
									<li>
										<cfoutput>#encodeForHtml(menuLabels.mobile)#</cfoutput>
										<ul>
											<li class="k-state-disabled">Categories</li>
											<cfloop array="#menuCategories#" index="menuCategory"><li><a href="<cfoutput>#menuCategory.link#</cfoutput>"><cfoutput>#menuCategory.name#</cfoutput></a></li></cfloop>
											<li class="k-separator"></li>
											<li class="k-state-disabled"><cfoutput>#encodeForHtml(menuLabels.collections)#</cfoutput></li>
											<cfloop array="#menuCollections#" index="menuCollection"><li><a href="<cfoutput>#application.blog.makeCollectionLink(menuCollection.pageCollectionId)#</cfoutput>"><cfoutput>#menuCollection.title#</cfoutput></a></li></cfloop>
										</ul>
									</li>
								<cfelseif arrayLen(menuCategories)>
									<!--- Phones with only one of the two: show it on its own, under its own name. --->
									<li>
										Categories
										<ul>
											<cfloop array="#menuCategories#" index="menuCategory"><li><a href="<cfoutput>#menuCategory.link#</cfoutput>"><cfoutput>#menuCategory.name#</cfoutput></a></li></cfloop>
										</ul>
									</li>
								<cfelseif arrayLen(menuCollections)>
									<li>
										<cfoutput>#encodeForHtml(menuLabels.collections)#</cfoutput>
										<ul>
											<cfloop array="#menuCollections#" index="menuCollection"><li><a href="<cfoutput>#application.blog.makeCollectionLink(menuCollection.pageCollectionId)#</cfoutput>"><cfoutput>#menuCollection.title#</cfoutput></a></li></cfloop>
										</ul>
									</li>
								</cfif>
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
									<li class="galaxieAdminMenuItem">
									<!--- Admin. --->
									<!--- The same for everyone (2026-10-28): this menu is cached for all visitors, so a signed-in administrator's
									Administration / Log out menu is added by tailEndScripts.cfm, outside the cache. It used to be decided here, and
									showed only when an administrator happened to be the one whose visit made the cached menu. --->
									<a href="<cfoutput>#application.baseUrl#/admin/</cfoutput>" aria-label="Sign in or administration"><span class="k-icon k-i-user"></span></a>
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