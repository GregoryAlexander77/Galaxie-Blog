<cfif not application.kendoCommercial>
	<!--- Include the stylesheet for the theme for jsGrid. The Kendo grid stylsheet will be included if we are using the commerial version of Kendo --->
	<cfinclude template="#application.baseUrl#/common/libs/jsGrid/kendoThemeCss.cfm">
</cfif>
<cfsilent>

<!--- Get a CSRF token for the Refresh Site / Reload ORM Objects icons below. forceNew=false reuses the
	existing session token (matching the same csrfGenerateToken("admin", false) call used in
	adminInterface.cfm and latestVersionCheck.cfm) rather than minting a new one. --->
<cfset csrfToken = csrfGenerateToken("admin", false)>

<!--- Clean up the logs. This will delete records that fall outside of the specified retention period. --->
<cfset logCleanup = application.blog.cleanUpLogs()>
	
<!--- Get roles and capabilities. This is used to determine what to display depending upon the permissions --->
<!--- Get the list of roles (a user should only be one role at in V2). We can either extract a roleId list, or a role list. Here, we want to get the actual role name (roleList) --->
<cfset currentUserRole = application.blog.getUserBlogRoles(session.userName, 'roleList')>
<!--- Return a list of capabilities. We need this to determine whether to show the log button that displays all of the user logins (by looking at the editUser capability) --->
<cfset currentUserCapabilityList = application.blog.getCapabilitiesByRole(currentUserRole, 'capabilityList')>
	
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
	<cfset iconList = listAppend(iconList, 'Pages')>
	<cfset titleList = listAppend(titleList, 'Pages')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(57);")>
	<cfset imageList = listAppend(imageList, "/images/icons/contentEditor.png")>
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
	<!--- Categories --->
	<cfset iconList = listAppend(iconList, 'Categories')>
	<cfset titleList = listAppend(titleList, 'Categories')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(25);")>
	<cfset imageList = listAppend(imageList, "/images/icons/categories.png")>
</cfif>	
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditCategory') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<cfset iconList = listAppend(iconList, 'Tags')>
	<cfset titleList = listAppend(titleList, 'Tags')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(50);")>
	<cfset imageList = listAppend(imageList, "/images/icons/tags.png")>
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
<cfif listFindNoCase(currentUserCapabilityList, 'EditUser') gt 0>
	<cfset iconList = listAppend(iconList, 'Users')>
	<cfset titleList = listAppend(titleList, 'Users')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(28);")>
	<cfset imageList = listAppend(imageList, "/images/icons/users.png")>
</cfif>
		
<!--- Every user has a profile --->
<cfset iconList = listAppend(iconList, 'userProfile')>
<cfset titleList = listAppend(titleList, 'User Profile')>
<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(7);")>
<cfset imageList = listAppend(imageList, "/images/icons/userProfile.gif")>
	
<cfif listFindNoCase(currentUserCapabilityList, 'EditTheme') gt 0>
	<cfset iconList = listAppend(iconList, 'Themes')>
	<cfset titleList = listAppend(titleList, 'Themes & Content')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(29);")>
	<cfset imageList = listAppend(imageList, "/images/icons/themes.png")>
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
<!--- There are occassional ORM lock issues on occassion since the logging requires capturing data for each visitor ---> 
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditCategory') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<!--- Visitor Log --->
	<cfset iconList = listAppend(iconList, 'VisitorLog')>
	<cfset titleList = listAppend(titleList, 'Visitor Log')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(48);")>
	<cfset imageList = listAppend(imageList, "/images/icons/visitorLog.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditUser') gt 0>
	<!--- Ban Visitors by IP address or HTTP User-Agent string --->
	<cfset iconList = listAppend(iconList, 'BanVisitors')>
	<cfset titleList = listAppend(titleList, 'Ban Visitors')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(66);")>
	<cfset imageList = listAppend(imageList, "/images/icons/banUser.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditUser') gt 0>
	<!--- Grid of anonymous visitors currently blocked by a banned IP address or User-Agent --->
	<cfset iconList = listAppend(iconList, 'BannedUsers')>
	<cfset titleList = listAppend(titleList, 'Banned Users')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(67);")>
	<cfset imageList = listAppend(imageList, "/images/icons/banUserGrid.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditCategory') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<!--- Visitor Log --->
	<cfset iconList = listAppend(iconList, 'AdminLog')>
	<cfset titleList = listAppend(titleList, 'Admin Log')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(58);")>
	<cfset imageList = listAppend(imageList, "/images/icons/adminLog.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditCategory') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<!--- Visitor Log --->
	<cfset iconList = listAppend(iconList, 'ErrorLog')>
	<cfset titleList = listAppend(titleList, 'Error Log')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(59);")>
	<cfset imageList = listAppend(imageList, "/images/icons/errorLog.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditCategory') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<!--- Reaaction Log --->
	<cfset iconList = listAppend(iconList, 'reactionLog')>
	<cfset titleList = listAppend(titleList, 'Reaction Log')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(62);")>
	<cfset imageList = listAppend(imageList, "/images/icons/likes.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditCategory') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<!--- Visitor Log --->
	<cfset iconList = listAppend(iconList, 'SearchQuery')>
	<cfset titleList = listAppend(titleList, 'Search Queries')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(61);")>
	<cfset imageList = listAppend(imageList, "/images/icons/searchQuery.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') gt 0>
	<cfset iconList = listAppend(iconList, 'ImportData')>
	<cfset titleList = listAppend(titleList, 'Import Data')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(41);")>
	<cfset imageList = listAppend(imageList, "/images/icons/import.png")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') gt 0>
	<cfset iconList = listAppend(iconList, 'BlogUpdate')>
	<cfset titleList = listAppend(titleList, 'Blog Updates')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(40);")>
	<cfset imageList = listAppend(imageList, "/images/icons/blogUpdates.gif")>
</cfif>
<!--- Note: this used to be a plain href to "#application.baseUrl#/?reinit=1", which navigated the
	whole browser away from the admin page to reinitialize the site. It's now a javascript: call so we
	can show a small Kendo confirmation window instead -- the refreshSite() function (defined below)
	makes an AJAX request back to this same "?reinit=1" URL param, which Application.cfc's
	onRequestStart still processes exactly as before, and then reports success/failure. --->
<cfset iconList = listAppend(iconList, 'RefreshSite')>
<cfset titleList = listAppend(titleList, 'Refresh Site')>
<cfset linkList = listAppend(linkList, "javascript:refreshSite();")>
<cfset imageList = listAppend(imageList, "/images/icons/refresh.gif")>

<!--- Reload the ColdFusion ORM (Hibernate) object metadata. Same pattern as Refresh Site above -- the
	reloadOrmObjects() function makes an AJAX request carrying "?reloadOrm=1", which Application.cfc's
	onRequestStart already knows how to handle, and then reports success/failure in a Kendo window. --->
<cfset iconList = listAppend(iconList, 'ReloadOrm')>
<cfset titleList = listAppend(titleList, 'Reload ORM Objects')>
<cfset linkList = listAppend(linkList, "javascript:reloadOrmObjects();")>
<cfset imageList = listAppend(imageList, "/images/icons/refreshOrm.gif")>

<!--- Get any new recent comments and prompt the user if they want to review them. --->
<cfset recentCommentCount = application.blog.getRecentCommentCount()>
</cfsilent>
<!--- Refresh Site / Reload ORM Objects. Both follow the same shape: show a "please wait" window,
	make an AJAX call to a ProxyController function whose URL also carries the same reinit/reloadOrm
	param that Application.cfc's onRequestStart already knows how to process, then swap the "please
	wait" window for a small Kendo confirmation (or error) window once the response comes back. --->
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	function refreshSite(){

		// Open the please wait window while the request is in flight.
		$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Refreshing the site...", icon: "k-ext-information" }));

		$.ajax({
			type: 'post',
			// The reinit=1 param is what Application.cfc's onRequestStart looks for to reset the app
			// vars and flush the caches -- it runs before this method's own code executes.
			url: '<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=refreshSite&reinit=1',
			data: {
				csrfToken: '<cfoutput>#csrfToken#</cfoutput>'
			},
			dataType: "json",
			cache: false,
			success: function(data){
				kendo.ui.ExtWaitDialog.hide();
				if (data && data.success){
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Site Refreshed", message: "The site has been successfully refreshed.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Refresh Failed", message: "Unable to refresh the site" + (data && data.errorMessage ? ": " + data.errorMessage : "."), icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
				}
			},
			error: function(){
				kendo.ui.ExtWaitDialog.hide();
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Refresh Failed", message: "Unable to refresh the site.", icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
			}
		});

		// Prevent the anchor's href from doing anything else.
		return false;
	}//..function refreshSite()

	function reloadOrmObjects(){

		// Open the please wait window while the request is in flight.
		$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Reloading the ORM objects...", icon: "k-ext-information" }));

		$.ajax({
			type: 'post',
			// The reloadOrm=1 param is what Application.cfc's onRequestStart looks for to call
			// ORMReload() -- it runs before this method's own code executes.
			url: '<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=reloadOrmObjects&reloadOrm=1',
			data: {
				csrfToken: '<cfoutput>#csrfToken#</cfoutput>'
			},
			dataType: "json",
			cache: false,
			success: function(data){
				kendo.ui.ExtWaitDialog.hide();
				if (data && data.success){
					$.when(kendo.ui.ExtAlertDialog.show({ title: "ORM Objects Reloaded", message: "The ORM objects have been successfully reloaded.", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Reload Failed", message: "Unable to reload the ORM objects" + (data && data.errorMessage ? ": " + data.errorMessage : "."), icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
				}
			},
			error: function(){
				kendo.ui.ExtWaitDialog.hide();
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Reload Failed", message: "Unable to reload the ORM objects.", icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
			}
		});

		// Prevent the anchor's href from doing anything else.
		return false;
	}//..function reloadOrmObjects()
</script>
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
<!--- 
	Debugging
	<input type="hidden" id="sidebarPanelState" name="sidebarPanelState" value="initial"/>
	<cfset iconLoopIndex = 1>
	<cfloop list="#iconList#" index="icon">
		<cfoutput>#iconLoopIndex# #icon#</cfoutput><br/>
		<cfset iconLoopIndex = iconLoopIndex + 1>
	</cfloop>
	<cfset linkLoopIndex = 1>
	<cfloop list="#linkList#" index="link">
		<cfoutput>#linkLoopIndex# #link#</cfoutput><br/>
		<cfset linkLoopIndex = linkLoopIndex + 1>
	</cfloop>
--->
	
<!--- Forms that hold state. --->
<!--- This is the sidebar responsive navigation panel that is triggered when the screen gets to a certain size. It is a duplicate of the sidebar div above, however, I can't properly style the sidebar the way that I want to within the blog content, so it is duplicated withoout the styles here. --->
</cfsilent>

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
							<!--- Note: we already know that this is the profile icon, but we need to append an additional argument to the list (the 3rd argument is otherArgs) for the link to know what type of user is being edited to change the window title. The link is hardcoded --->
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
							<!--- The ninth icon, the edit profile link, is hardcorded with an extra argument in the link structure --->
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
							<cfset i = 14>
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
							<cfset i = 15>
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
							<cfset i = 16>
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
							<cfset i = 17>
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
							<cfset i = 18>
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
							<cfset i = 19>
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
							<cfset i = 20>
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
							<cfset i = 21>
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
							<cfset i = 22>
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
							<cfset i = 23>
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
							<cfset i = 24>
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