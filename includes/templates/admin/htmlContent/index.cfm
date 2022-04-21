<cfif not application.kendoCommercial>
	<!--- Include the stylesheet for the theme for jsGrid. The Kendo grid stylsheet will be included if we are using the commerial version of Kendo --->
	<cfinclude template="#application.baseUrl#/common/libs/jsGrid/kendoThemeCss.cfm">
</cfif>
	
<!--- Get roles and capabilities. This is used to determine what to display depending upon the permissions --->
<!--- Get the list of roles (a user should only be one role at in V2). We can either extract a roleId list, or a role list. Here, we want to get the actual role name (roleList) --->
<cfset currentUserRole = application.blog.getUserBlogRoles(session.userName, 'roleList')>
<!--- Return a list of capabilities. We need this to determine whether to show the log button that displays all of the user logins (by looking at the editUser capability) --->
<cfset currentUserCapabilityList = application.blog.getCapabilitiesByRole(currentUserRole, 'capabilityList')>
<!---<cfdump var="#currentUserCapabilityList#">--->
	
<!--- Determine if the post should be shown --->
	
<!--- Create an empty list --->
<cfparam name="iconList" type="string" default="">
<cfparam name="titleList" type="string" default="">
<cfparam name="linkList" type="string" default="">
<cfparam name="imageList" type="string" default="">
	
<!--- Append the values to the list --->
<!--- See if the posts should be shown --->
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost')>
	<cfset iconList = listAppend(iconList, 'addPost')>
	<cfset titleList = listAppend(titleList, 'Create Post')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(24);")>
	<cfset imageList = listAppend(imageList, "/images/icons/post.png")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<cfset iconList = listAppend(iconList, 'Posts')>
	<cfset titleList = listAppend(titleList, 'Posts')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(5);")>
	<cfset imageList = listAppend(imageList, "/images/icons/posts.png")>
</cfif>
<!--- Don't include the comment interface with Disqus --->
<cfif not application.includeDisqus and (listFindNoCase(currentUserCapabilityList, 'EditComment') or listFindNoCase(currentUserCapabilityList, 'EditPost'))>
	<cfset iconList = listAppend(iconList, 'Comments')>
	<cfset titleList = listAppend(titleList, 'Comments')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(1);")>
	<cfset imageList = listAppend(imageList, "/images/icons/comments.png")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditCategory') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<cfset iconList = listAppend(iconList, 'Categories')>
	<cfset titleList = listAppend(titleList, 'Categories')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(25);")>
	<cfset imageList = listAppend(imageList, "/images/icons/categories.png")>
</cfif>	
<cfif listFindNoCase(currentUserCapabilityList, 'EditTheme')>
	<cfset iconList = listAppend(iconList, 'Fonts')>
	<cfset titleList = listAppend(titleList, 'Fonts')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(33);")>
	<cfset imageList = listAppend(imageList, "/images/icons/fonts.png")>
</cfif>		
<cfif listFindNoCase(currentUserCapabilityList, 'EditSubscriber') gt 0>
	<cfset iconList = listAppend(iconList, 'Subscriber')>
	<cfset titleList = listAppend(titleList, 'Subscribers')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(26);")>
	<cfset imageList = listAppend(imageList, "/images/icons/subscriber.png")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditTheme') gt 0>
	<cfset iconList = listAppend(iconList, 'Themes')>
	<cfset titleList = listAppend(titleList, 'Themes')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(29);")>
	<cfset imageList = listAppend(imageList, "/images/icons/themes.png")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditUser') gt 0>
	<cfset iconList = listAppend(iconList, 'Users')>
	<cfset titleList = listAppend(titleList, 'Users')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(28);")>
	<cfset imageList = listAppend(imageList, "/images/icons/users.png")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') gt 0>
	<cfset iconList = listAppend(iconList, 'BlogSettings')>
	<cfset titleList = listAppend(titleList, 'Blog Settings')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(39);")>
	<cfset imageList = listAppend(imageList, "/images/icons/serverSettings.gif")>
</cfif>	
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') gt 0>
	<cfset iconList = listAppend(iconList, 'BlogOptions')>
	<cfset titleList = listAppend(titleList, 'Blog Options')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(38);")>
	<cfset imageList = listAppend(imageList, "/images/icons/settings.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') gt 0>
	<cfset iconList = listAppend(iconList, 'BlogUpdate')>
	<cfset titleList = listAppend(titleList, 'Blog Updates')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(40);")>
	<cfset imageList = listAppend(imageList, "/images/icons/blogUpdates.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') gt 0>
	<cfset iconList = listAppend(iconList, 'ImportData')>
	<cfset titleList = listAppend(titleList, 'Import Data')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(41);")>
	<cfset imageList = listAppend(imageList, "/images/icons/import.png")>
</cfif>
<cfset iconList = listAppend(iconList, 'RefreshSite')> 
<cfset titleList = listAppend(titleList, 'Refresh Site')>
<cfset linkList = listAppend(linkList, "#application.baseUrl#/?reinit=1")>
<cfset imageList = listAppend(imageList, "/images/icons/refresh.gif")>
	
<!--- Get any new recent comments and prompt the user if they want to review them. --->
<cfset recentCommentCount = application.blog.getRecentCommentCount()>
	
<!--- If there are any unapproved comments, launch a prompt asking the user if they want to review the comments. --->
<cfif recentCommentCount gt 0>
	
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	// Prompt the user
	$.when(kendo.ui.ExtYesNoDialog.show({ 
		title: "Unapproved Comments.", 
		message: "There are <cfoutput>#recentCommentCount#</cfoutput> comments that have not been approved. Do you want to review?",
		icon: "k-ext-question" })
	).done(function (response) {
		// If the user clicked 'yes', launch the grid.
		if (response['button'] == 'Yes'){// remember that js is case sensitive.
			// Launch the grid
			createAdminInterfaceWindow(1, 'recentComments');
		}
	});
</script>
</cfif><!---<cfif recentCommentCount gt 0>--->
	
<cfsilent>
<!--- Forms that hold state. --->
<!--- This is the sidebar responsive navigation panel that is triggered when the screen gets to a certain size. It is a duplicate of the sidebar div above, however, I can't properly style the sidebar the way that I want to within the blog content, so it is duplicated withoout the styles here. --->
</cfsilent>
<input type="hidden" id="sidebarPanelState" name="sidebarPanelState" value="initial"/>

<div id="pagePanel" class="panel">
	<cfsilent>
	<!--- 
	Wide div in the center left of page.
	Note: this is the div that will be refreshed when new entries are made. All of the dynamic elements within this div are refreshed when there are new posts, however, any logic *outside* of this div are not refreshed- so we need to get the query, and supply the arguments.
	--->
	</cfsilent>
	<div id="adminContent">
		
		<div class="blogPost widget k-content" style="padding: 10px">
			<!--- This is our container that we will use to swap templates using SWUP. --->
			<span id="innerContentContainer">

				<h4 class="topContent">
					Blog Administration
				</h4>

				<p class="bottomContent">

					<!-- Content --> 
					<span id="iconNavMenu" class="postContent">	

						<span style="text-align: center">Click on one of the categories below to continue.</span>

							<table id="iconMenu" cellpadding="0" cellspacing="0" border="0" width="100%">
								<tr>
									<td colspan="3">&nbsp;</td>
								</tr>
								<tr>  
									<td width="33%" style="text-align:center">
										<cfset i = 1>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td width="33%" style="text-align:center">
										<cfset i = 2>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td width="33%" style="text-align:center">
										<cfset i = 3>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
								</tr>
							<!--- Provide extra space for mobile clients otherwise the icons are squished together --->
							<cfif session.isMobile>
								<tr>
									<td colspan="3" style="height: 20px">&nbsp;</td>
								</tr>
							</cfif>
								<tr>
									<td colspan="3">&nbsp;</td>
								</tr>
								<tr>
									<td style="text-align:center">
										<cfset i = 4>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td style="text-align:center">
										<cfset i = 5>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td style="text-align:center">
										<cfset i = 6>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
								</tr>
								<!--- Provide extra space for mobile clients otherwise the icons are squished together --->
							<cfif session.isMobile>
								<tr>
									<td colspan="3" style="height: 20px">&nbsp;</td>
								</tr>
							</cfif>
								<tr>
									<td colspan="3">&nbsp;</td>
								</tr>
								<tr>
									<td style="text-align:center">
										<cfset i = 7>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td style="text-align:center">
										<cfset i = 8>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td style="text-align:center">
										<cfset i = 9>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
								</tr>
							<!--- Provide extra space for mobile clients otherwise the icons are squished together --->
							<cfif session.isMobile>
								<tr>
									<td colspan="3" style="height: 20px">&nbsp;</td>
								</tr>
							</cfif>
								<tr>
									<td colspan="3">&nbsp;</td>
								</tr>
								<tr>
									<td style="text-align:center">
										<cfset i = 10>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td style="text-align:center">
										<cfset i = 11>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td style="text-align:center">
										<cfset i = 12>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
								</tr>
								<!--- Provide extra space for mobile clients otherwise the icons are squished together --->
							<cfif session.isMobile>
								<tr>
									<td colspan="3" style="height: 20px">&nbsp;</td>
								</tr>
							</cfif>
								<tr>
									<td colspan="3">&nbsp;</td>
								</tr>
								<tr>
									<td style="text-align:center">
										<cfset i = 13>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>
									</td>
									<td style="text-align:center">
										<!---<cfset i = 11>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>--->
									</td>
									<td style="text-align:center">
										<!---<cfset i = 12>
										<cfif listLen(iconList) gte i>
										<span id="<cfoutput>#listGetAt(iconList, i)#</cfoutput>" title="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" data-desc="<cfoutput>#listGetAt(titleList, i)#</cfoutput>" class="iconTopRow icon">
											<a href="<cfoutput>#listGetAt(linkList, i)#</cfoutput>">
											<img src="<cfoutput>#application.baseUrl##listGetAt(imageList, i)#</cfoutput>">
											<span class="caption"><cfoutput>#listGetAt(titleList, i)#</cfoutput></span>
											</a>
										</span>
										</cfif>--->
									</td>
								</tr>
								<!--- Provide extra space for mobile clients otherwise the icons are squished together --->
							<cfif session.isMobile>
								<tr>
									<td colspan="3" style="height: 20px">&nbsp;</td>
								</tr>
							</cfif>
							</table>

						</span>
					</div>

					<!--- Stylesheet for the icon and tooltips. --->
					<style>

						span.icon {
							/* To correctly align image, regardless of content height: */
							vertical-align: top;
							display: inline-block;
							/* To horizontally center images and caption */
							text-align: center;
							/* The width of the container also implies margin around the images. */
							width: <cfif session.isMobile>105<cfelse>125</cfif>px;
							height: <cfif session.isMobile>105<cfelse>175</cfif>px;
						}

						.icon img {
							width: <cfif session.isMobile>90<cfelse>133</cfif>px;
							height: <cfif session.isMobile>90<cfelse>133</cfif>px;;
						}

						/* Add a hover effect (blue shadow) */
						.icon img:hover {
							box-shadow: 0 0 2px 1px rgba(0, 140, 186, 0.5);
							opacity: .82;
						}

						.caption {
							/* Make the caption a block so it occupies its own line. */
							display: block;
						}

						/* Custom classes for the tooltips. These classes will be used to override the base k-tooltip class. */
						.iconBottomRow {
							width: var(--toolTipWidth);
							height: var(--toolTipHeight);
							font-size: var(--toolTipFontSize);
							border-radius: 10px;
						}

						/* Custom classes for the tooltips. These classes will be used to override the base k-tooltip class. */
						.iconTopRow {
							width: var(--toolTipWidth);
							height: var(--toolTipHeight);
							font-size: var(--toolTipFontSize);
							border-radius: 10px;
						}

						.tooltipTemplateWrapper h3 {
							font-size: <cfif session.isMobile>12px<cfelse>1em</cfif>;
							font-weight: bold;
							padding: 0px 10px 5px;
							border-bottom: 1px solid #e2e2e2;
							text-align: left;
						}

						.tooltipTemplateWrapper p {
							font-size: <cfif session.isMobile>12px<cfelse>1em</cfif>;
							padding-top: 0px;
							padding-right: 10px;
							padding-bottom: 10px;
							padding-left: 10px;
							text-align: left;
						}
					</style>

					</span><!---<span id="iconNavMenu" class="postContent">	--->

				</p><!---<p class="bottomContent">--->

			</div><!---<span id="innerContentContainer" class="transition-fade">--->
		</div><!---<div class="blogPost widget k-content">--->
	</div><!---<div class="blogContent">--->
</div><!---<div id="pagePanel" class="panel">--->