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
	
<!--- An icon whose list would be empty opens the window to add the first one instead (owner, 10-16), eg. Forms opens a new
form when there are none. One query counts them; if it fails, every icon opens its list as before. --->
<cfset adminHomeCounts = { posts: -1, pages: -1, collections: -1, forms: -1, events: -1, categories: -1, tags: -1, subscribers: -1 }>
<cftry>
	<cfset adminHomeCountQuery = queryExecute("
		SELECT
			(SELECT COUNT(*) FROM Post WHERE BlogRef = :blogId AND IsPage = 0 AND Remove = 0) AS PostCount,
			(SELECT COUNT(*) FROM Post WHERE BlogRef = :blogId AND IsPage = 1 AND Remove = 0) AS PageCount,
			(SELECT COUNT(*) FROM PageCollection WHERE BlogRef = :blogId) AS CollectionCount,
			(SELECT COUNT(*) FROM WebForm WHERE BlogRef = :blogId) AS FormCount,
			(SELECT COUNT(*) FROM BlogEvent WHERE BlogRef = :blogId) AS EventCount,
			(SELECT COUNT(*) FROM Category WHERE BlogRef = :blogId) AS CategoryCount,
			(SELECT COUNT(*) FROM Tag WHERE BlogRef = :blogId) AS TagCount,
			(SELECT COUNT(*) FROM Subscriber WHERE BlogRef = :blogId) AS SubscriberCount",
		{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" } }, { datasource = application.dsn })>
	<cfset adminHomeCounts = {
		posts: val(adminHomeCountQuery.PostCount), pages: val(adminHomeCountQuery.PageCount), collections: val(adminHomeCountQuery.CollectionCount),
		forms: val(adminHomeCountQuery.FormCount), events: val(adminHomeCountQuery.EventCount), categories: val(adminHomeCountQuery.CategoryCount),
		tags: val(adminHomeCountQuery.TagCount), subscribers: val(adminHomeCountQuery.SubscriberCount)
	}>
	<cfcatch type="any"><!--- Keep the lists. ---></cfcatch>
</cftry>

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
	<cfset linkList = listAppend(linkList, adminHomeCounts.posts eq 0 ? "javascript:createAdminInterfaceWindow(24);" : "javascript:createAdminInterfaceWindow(5);")>
	<cfset imageList = listAppend(imageList, "/images/icons/posts.png")>
</cfif>
<!--- A direct shortcut into the same 3-way New chooser (createAdminInterfaceWindow(24,...)) used by "Create Post" above,
pre-selecting the Page radio instead of leaving the owner to land on Post and switch it manually - was parked earlier
("don't do it now") and is being added now. --->
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost')>
	<cfset iconList = listAppend(iconList, 'CreatePage')>
	<cfset titleList = listAppend(titleList, 'Create Page')>
	<!--- iconList/titleList/linkList/imageList are plain comma-delimited lists, so a literal comma inside an appended
	value (as in a multi-argument createAdminInterfaceWindow(24,'newPage') call) silently splits into an extra list
	item and desyncs every icon after it by one position. Use the HTML entity &#44; instead of a literal comma - the
	browser decodes it back to a comma when parsing the href attribute, so the executed JS is unaffected. --->
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(24&##44;'newPage');")>
	<cfset imageList = listAppend(imageList, "/images/icons/newPage.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<cfset iconList = listAppend(iconList, 'Pages')>
	<cfset titleList = listAppend(titleList, 'Pages')>
	<cfset linkList = listAppend(linkList, adminHomeCounts.pages eq 0 ? "javascript:createAdminInterfaceWindow(24&##44;'newPage');" : "javascript:createAdminInterfaceWindow(57);")>
	<cfset imageList = listAppend(imageList, "/images/icons/contentEditor.png")>
</cfif>
<!--- A third shortcut into the same 3-way New chooser used by "Create Post"/"Create Page" above, pre-selecting the
Page Collection radio - completes the Create Post/Posts, Create Page/Pages, Create Page Collection/Page Collections
grouping. Placed right after Pages, with Page Collections (moved down from its old spot near Blog Options) right
next to it, same &#44; comma-escaping trick "Create Page" already uses. --->
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost')>
	<cfset iconList = listAppend(iconList, 'CreatePageCollection')>
	<cfset titleList = listAppend(titleList, 'Create Page Collection')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(24&##44;'newPageCollection');")>
	<cfset imageList = listAppend(imageList, "/images/icons/newCollection.gif")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditPost') gt 0>
	<cfset iconList = listAppend(iconList, 'ConfigurePageCollections')>
	<cfset titleList = listAppend(titleList, 'Page Collections')>
	<cfset linkList = listAppend(linkList, adminHomeCounts.collections eq 0 ? "javascript:createAdminInterfaceWindow(24&##44;'newPageCollection');" : "javascript:createAdminInterfaceWindow(68);")>
	<cfset imageList = listAppend(imageList, "/images/icons/pageCollection.gif")>
</cfif>
<!--- Configure Homepage - the global "what shows as homepage" toggle. Moved here 2026-10-18 (owner), right after Page
Collections and before Configure Menu, so the homepage and menu settings sit together. --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') gt 0>
	<cfset iconList = listAppend(iconList, 'ConfigureHomepage')>
	<cfset titleList = listAppend(titleList, 'Configure Homepage')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(70);")>
	<cfset imageList = listAppend(imageList, "/images/icons/configureSite.gif")>
</cfif>
<!--- Configure Menu (2026-10-10, 4.8): the owner's Menu links and the top menu's names. Same capability as Themes. --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditTheme')>
	<cfset iconList = listAppend(iconList, 'ConfigureMenu')>
	<cfset titleList = listAppend(titleList, 'Configure Menu')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(82);")>
	<cfset imageList = listAppend(imageList, "/images/icons/configureMenu.gif")>
</cfif>
<!--- Scenes (2026-10-19, Galaxie 5): the scrolling heroes for posts and pages. Used in posts, so the same capability as editing posts. --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditPost')>
	<cfset iconList = listAppend(iconList, 'Scenes')>
	<cfset titleList = listAppend(titleList, 'Scenes')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(106);")>
	<cfset imageList = listAppend(imageList, "/images/icons/scenes.gif")>
</cfif>
<!--- Forms (2026-10-13): forms the blog owner builds and places in posts. They collect visitors' personal details, so the
same capability as Blog Settings. --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting')>
	<cfset iconList = listAppend(iconList, 'Forms')>
	<cfset titleList = listAppend(titleList, 'Forms')>
	<cfset linkList = listAppend(linkList, adminHomeCounts.forms eq 0 ? "javascript:createAdminInterfaceWindow(84&##44;0);" : "javascript:createAdminInterfaceWindow(83);")>
	<cfset imageList = listAppend(imageList, "/images/icons/forms.gif")>
</cfif>
<!--- Bookings (2026-10-14): appointments visitors book with the blog owner. Same capability as Forms (visitors' personal
details). --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting')>
	<cfset iconList = listAppend(iconList, 'Bookings')>
	<cfset titleList = listAppend(titleList, 'Bookings')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(87);")>
	<cfset imageList = listAppend(imageList, "/images/icons/bookings.gif")>
</cfif>
<!--- Events (2026-10-15): posts that are events, and who signed up. Made from a post, so the same capability as editing posts. --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditPost')>
	<cfset iconList = listAppend(iconList, 'Events')>
	<cfset titleList = listAppend(titleList, 'Events')>
	<cfset linkList = listAppend(linkList, adminHomeCounts.events eq 0 ? "javascript:createAdminInterfaceWindow(24&##44;'newEvent');" : "javascript:createAdminInterfaceWindow(101);")>
	<cfset imageList = listAppend(imageList, "/images/icons/event.gif")>
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
	<cfset linkList = listAppend(linkList, adminHomeCounts.categories eq 0 ? "javascript:createAdminInterfaceWindow(12);" : "javascript:createAdminInterfaceWindow(25);")>
	<cfset imageList = listAppend(imageList, "/images/icons/categories.png")>
</cfif>	
<cfif listFindNoCase(currentUserCapabilityList, 'AddPost') or listFindNoCase(currentUserCapabilityList, 'EditCategory') or listFindNoCase(currentUserCapabilityList, 'EditPost') or listFindNoCase(currentUserCapabilityList, 'ReleasePost')>
	<cfset iconList = listAppend(iconList, 'Tags')>
	<cfset titleList = listAppend(titleList, 'Tags')>
	<cfset linkList = listAppend(linkList, adminHomeCounts.tags eq 0 ? "javascript:createAdminInterfaceWindow(49);" : "javascript:createAdminInterfaceWindow(50);")>
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
	<cfset linkList = listAppend(linkList, adminHomeCounts.subscribers eq 0 ? "javascript:createAdminInterfaceWindow(27);" : "javascript:createAdminInterfaceWindow(26);")>
	<cfset imageList = listAppend(imageList, "/images/icons/subscriber.png")>
</cfif>
<cfif listFindNoCase(currentUserCapabilityList, 'EditUser') gt 0>
	<cfset iconList = listAppend(iconList, 'Users')>
	<cfset titleList = listAppend(titleList, 'Users')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(28);")>
	<cfset imageList = listAppend(imageList, "/images/icons/users.png")>
</cfif>
<!--- The People icon (2026-10-16) was removed 2026-10-17: profiles on the site are part of Members now, which uses its people.gif (owner). --->
<!--- Members (2026-10-17): everyone who isn't running the blog - accounts, subscribers, bookings, sign-ups, forms and profiles on the site (window 97). Icon: people.gif (owner, 10-17; members.gif is kept in the folder). --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditUser') gt 0>
	<cfset iconList = listAppend(iconList, 'Members')>
	<cfset titleList = listAppend(titleList, 'Members')>
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(97);")>
	<cfset imageList = listAppend(imageList, "/images/icons/people.gif")>
</cfif>
		
<!--- Every user has a profile --->
<cfset iconList = listAppend(iconList, 'userProfile')>
<cfset titleList = listAppend(titleList, 'User Profile')>
<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(7);")>
<cfset imageList = listAppend(imageList, "/images/icons/userProfile.gif")>
	
<!--- Site Setup (5.0, 2026-10-19): the wizard that makes a new install the owner's own site - a full page, not a window.
The icon is a placeholder (a copy of settings.gif) until the owner makes one. --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') gt 0>
	<cfset iconList = listAppend(iconList, 'SiteSetup')>
	<cfset titleList = listAppend(titleList, 'Site Setup')>
	<cfset linkList = listAppend(linkList, application.baseUrl & "/admin/setup.cfm")>
	<cfset imageList = listAppend(imageList, "/images/icons/siteSetup.gif")>
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
<cfif listFindNoCase(currentUserCapabilityList, 'EditTheme') gt 0>
	<cfset iconList = listAppend(iconList, 'Themes')>
	<cfset titleList = listAppend(titleList, 'Themes & Content')>
	<!--- 5.0: the Themes window (110) - themes, branding, content and custom code. It links to the old screen (29) for the rest. --->
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(110);")>
	<cfset imageList = listAppend(imageList, "/images/icons/themes.png")>
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
<!--- Member Log (2026-10-17, owner): every time a member signed in (window 105, admin/adminInterface/memberSignIns.cfm). Icon: userLog.gif (owner). --->
<cfif listFindNoCase(currentUserCapabilityList, 'EditUser') gt 0>
	<cfset iconList = listAppend(iconList, 'MemberLog')>
	<cfset titleList = listAppend(titleList, 'Member Log')>
	<!--- No comma: linkList is a comma-separated list. No member (optArgs) means everyone's sign-ins. --->
	<cfset linkList = listAppend(linkList, "javascript:createAdminInterfaceWindow(105);")>
	<cfset imageList = listAppend(imageList, "/images/icons/userLog.gif")>
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
	<!--- Let the administrator know when the files are newer than the database. See DatabaseUpdater.cfc --->
	<cfif isDefined("application.dbBlogVersion") and val(application.dbBlogVersion) lt val(application.blog.getVersion())>
		<cfset titleList = listAppend(titleList, 'Blog Updates (update needed)')>
	<cfelse>
		<cfset titleList = listAppend(titleList, 'Blog Updates')>
	</cfif>
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

			<span style="text-align: center">What's up next, then everything else in groups.</span>

			<!--- Until the owner finishes the Site Setup wizard (5.0): how many screens are done, and a button to carry on. --->
			<!--- A brand new blog (5.0): the first visit to the administration page in a session opens the wizard, until the owner has
			saved its first screen. Blogs updated from older versions are never sent there (Setup.cfc shouldAutoOpen). --->
			<cfif listFindNoCase(currentUserCapabilityList, 'EditServerSetting') and application.blog.getSetup().shouldAutoOpen()
					and not (structKeyExists(session, "setupAutoOpened") and session.setupAutoOpened)>
				<cfset session.setupAutoOpened = true>
				<script>window.location.replace("<cfoutput>#application.baseUrl#</cfoutput>/admin/setup.cfm");</script>
			</cfif>
			<!--- Finish setting up your site is the first of the Up next suggestions below (5.0, 2026-10-20); it was a banner here. --->

				<!--- 5.0 (2026-10-19, owner's pick C): the everyday actions one click away, everything else in six groups, each group with
				its own page of icons, and what needs the owner shown on the tiles. The icons, their permissions and links are the lists
				above; this only lays them out. Room is left below the groups for charts of traffic and popular posts, some day. --->
				<cfsilent>
					<cfset homeGroups = [
						{ key: "posts", name: "Posts and Pages", image: "/images/icons/posts.png", what: "Write and organise", icons: "addPost,Posts,CreatePage,Pages,Comments,CreatePageCollection,ConfigurePageCollections,Categories,Tags" },
						{ key: "look", name: "Look and Layout", image: "/images/icons/themes.png", what: "Themes, scenes, home page and menu", icons: "Themes,Scenes,Fonts,ConfigureHomepage,ConfigureMenu" },
						{ key: "forms", name: "Forms and Bookings", image: "/images/icons/forms.gif", what: "Forms, bookings and events", icons: "Forms,Bookings,Events" },
						{ key: "people", name: "People", image: "/images/icons/users.png", what: "Users, members and subscribers", icons: "Users,Members,Subscriber,userProfile,BanVisitors,BannedUsers" },
						{ key: "logs", name: "Logs", image: "/images/icons/adminLog.gif", what: "What happened on the site", icons: "ErrorLog,AdminLog,MemberLog,VisitorLog,reactionLog,SearchQuery" },
						{ key: "settings", name: "Settings", image: "/images/icons/settings.gif", what: "Set-up, settings and updates", icons: "SiteSetup,BlogSettings,BlogOptions,BlogUpdate" },
						<!--- Tools (owner, 2026-10-20): the upkeep that isn't a setting, out of Posts and Settings. --->
						{ key: "tools", name: "Tools", image: "/images/icons/tools.svg", what: "Import, refresh and other upkeep", icons: "ImportData,RefreshSite,ReloadOrm" }
					]>
					<!--- Up next (owner, 2026-10-20): Create Post, then up to three things that need this person now, most important first
					(AdminHome.cfc getSuggestions), each with an x to hide it until something new happens. With fewer than three, the rest
					are Create Page, Posts and Comments. --->
					<cfset upNext = []>
					<cftry>
						<cfset upNext = application.blog.getAdminHome().getSuggestions(iconList, linkList, listFindNoCase(currentUserCapabilityList, "EditServerSetting") gt 0, listFindNoCase(titleList, "Blog Updates (update needed)") gt 0)>
						<cfcatch type="any"><cfset upNext = []></cfcatch>
					</cftry>
					<cfset upNextIcons = { setup: "SiteSetup", bookings: "Bookings", comments: "Comments", update: "BlogUpdate", signups: "Forms", errors: "ErrorLog", draft: "Posts", scheduled: "Posts" }>
					<cfset upNextShown = []>
					<cfloop array="#upNext#" index="suggestion">
						<cfif arrayLen(upNextShown) lt 3><cfset arrayAppend(upNextShown, suggestion)></cfif>
					</cfloop>
					<cfset upNextKinds = "">
					<cfloop array="#upNextShown#" index="suggestion"><cfset upNextKinds = listAppend(upNextKinds, suggestion.kind)></cfloop>
					<cfset upNextFallback = "">
					<cfloop list="CreatePage,Posts,Comments" index="key">
						<cfif listLen(upNextFallback) + arrayLen(upNextShown) lt 3 and listFindNoCase(iconList, key) and not (key eq "Comments" and listFind(upNextKinds, "comments"))>
							<cfset upNextFallback = listAppend(upNextFallback, key)>
						</cfif>
					</cfloop>
					<!--- What needs the owner, for the badges: comments waiting, errors in the last day, new sign-ups and bookings this week.
					If the counts can't be read, the tiles simply show none. --->
					<cfset homeStatus = { comments: 0, errors: 0, signUps: 0 }>
					<cftry>
						<cfset homeStatusQuery = queryExecute("
							SELECT
								(SELECT COUNT(*) FROM Comment WHERE BlogRef = :blogId AND (Approved = 0 OR Approved IS NULL) AND (Remove = 0 OR Remove IS NULL) AND (Spam = 0 OR Spam IS NULL)) AS CommentCount,
								(SELECT COUNT(*) FROM ErrorLog WHERE Date >= :dayAgo AND (Resolved = 0 OR Resolved IS NULL)) AS ErrorCount,
								(SELECT COUNT(*) FROM WebFormSubmission s JOIN WebForm f ON f.WebFormId = s.WebFormRef WHERE f.BlogRef = :blogId AND s.Created >= :weekAgo) AS SubmissionCount,
								(SELECT COUNT(*) FROM Booking WHERE BlogRef = :blogId AND Created >= :weekAgo) AS BookingCount",
							{ blogId = { value = application.BlogDbObj.getBlogId(), cfsqltype = "cf_sql_integer" },
							  dayAgo = { value = dateAdd("d", -1, now()), cfsqltype = "cf_sql_timestamp" },
							  weekAgo = { value = dateAdd("d", -7, now()), cfsqltype = "cf_sql_timestamp" } }, { datasource = application.dsn })>
						<cfset homeStatus = { comments: val(homeStatusQuery.CommentCount), errors: val(homeStatusQuery.ErrorCount), signUps: val(homeStatusQuery.SubmissionCount) + val(homeStatusQuery.BookingCount) }>
						<cfcatch type="any"></cfcatch>
					</cftry>
					<cfset homeGroupStatus = {
						forms: homeStatus.signUps ? homeStatus.signUps & " new this week" : "",
						logs: homeStatus.errors ? homeStatus.errors & (homeStatus.errors eq 1 ? " new error" : " new errors") : "",
						settings: listFindNoCase(titleList, "Blog Updates (update needed)") ? "Update needed" : "",
						posts: homeStatus.comments ? homeStatus.comments & (homeStatus.comments eq 1 ? " comment waiting" : " comments waiting") : ""
					}>
				</cfsilent>
				<cfoutput>
				<div id="adminHome">
					<div class="adminHomeSection adminHomeQuick">
						<h5 class="adminHomeHeading">Up next</h5>
						<cfif not arrayLen(upNextShown)><p class="adminHomeCaughtUp">All caught up. Here are some things to do.</p></cfif>
						<div class="adminHomeGrid">
						<cfset i = listFindNoCase(iconList, "addPost")>
						<cfif i>
							<a class="adminHomeTile k-content" id="addPost" href="#listGetAt(linkList, i)#">
								<img src="#application.baseUrl##listGetAt(imageList, i)#" alt="">
								<span class="adminHomeName">#listGetAt(titleList, i)#</span>
							</a>
						</cfif>
						<cfloop array="#upNextShown#" index="suggestion">
							<cfset i = listFindNoCase(iconList, upNextIcons[suggestion.kind] ?: "")>
							<div class="adminHomeSuggestWrap">
								<a class="adminHomeTile adminHomeSuggest k-content" href="#encodeForHtmlAttribute(suggestion.link)#">
									<cfif i><img src="#application.baseUrl##listGetAt(imageList, i)#" alt=""></cfif>
									<span class="adminHomeSuggestText">
										<span class="adminHomeName">#encodeForHtml(suggestion.label)#</span>
										<span class="adminHomeWhat">#encodeForHtml(suggestion.detail)#</span>
									</span>
								</a>
								<button type="button" class="adminHomeHide" title="Hide until something new happens" aria-label="Hide #encodeForHtmlAttribute(suggestion.label)#"
									data-kind="#encodeForHtmlAttribute(suggestion.kind)#" data-signature="#encodeForHtmlAttribute(suggestion.signature)#">&times;</button>
							</div>
						</cfloop>
						<cfloop list="#upNextFallback#" index="key">
							<cfset i = listFindNoCase(iconList, key)>
							<a class="adminHomeTile k-content" id="#listGetAt(iconList, i)#" href="#listGetAt(linkList, i)#">
								<img src="#application.baseUrl##listGetAt(imageList, i)#" alt="">
								<span class="adminHomeName">#listGetAt(titleList, i)#</span>
							</a>
						</cfloop>
						</div>
					</div>
					<!--- Traffic this week (owner, 2026-10-20): four cards drawn by the page itself (no chart library), filled after the page
					shows from ProxyController getAdminTraffic -> AdminHome.cfc getTraffic. Only for someone who may open the Visitor Log. --->
					<cfif listFindNoCase(iconList, "VisitorLog")>
					<div class="adminHomeSection" id="adminTraffic">
						<h5 class="adminHomeHeading">This week</h5>
						<div class="adminTrafficGrid">
							<div class="adminTrafficCard k-content"><div class="adminTrafficTitle">Visitors</div><div id="trafficVisitors" class="adminTrafficBody">Loading...</div></div>
							<div class="adminTrafficCard k-content"><div class="adminTrafficTitle">Most read</div><div id="trafficTop" class="adminTrafficBody"></div></div>
							<div class="adminTrafficCard k-content"><div class="adminTrafficTitle">Where they came from</div><div id="trafficSources" class="adminTrafficBody"></div></div>
							<div class="adminTrafficCard k-content"><div class="adminTrafficTitle">Reading now</div><div id="trafficNow" class="adminTrafficBody"></div></div>
						</div>
					</div>
					</cfif>
					<div class="adminHomeSection">
						<h5 class="adminHomeHeading">Everything else</h5>
						<div class="adminHomeGrid adminHomeGroups">
						<cfloop array="#homeGroups#" index="group">
							<cfset groupCount = 0>
							<cfloop list="#group.icons#" index="key"><cfif listFindNoCase(iconList, key)><cfset groupCount++></cfif></cfloop>
							<cfif groupCount>
							<button type="button" class="adminHomeTile adminHomeGroup k-content" data-group="#group.key#">
								<img src="#application.baseUrl##group.image#" alt="">
								<span class="adminHomeName">#group.name#</span>
								<span class="adminHomeWhat">#group.what#</span>
								<cfif len(homeGroupStatus[group.key] ?: "")><span class="adminHomeStatus<cfif group.key eq 'forms'> adminHomeInfo</cfif>">#homeGroupStatus[group.key]#</span></cfif>
							</button>
							</cfif>
						</cfloop>
						</div>
					</div>
					<!--- Later: charts of traffic and the most popular posts go here. --->
				</div>
				<cfloop array="#homeGroups#" index="group">
				<div class="adminGroupPage" id="adminGroup-#group.key#" style="display: none;">
					<!--- The blog's own breadcrumb (owner, 10-20; cd-breadcrumb in blogContentCss.cfm): the site, the administration home, this group. --->
					<div class="adminHomeCrumb k-content"><nav><ol class="cd-breadcrumb triangle">
						<li><a href="#application.blogHostUrl#" aria-label="Your site"><i class="fas fa-house" style="alignment-baseline:middle;"></i></a></li>
						<li><a href="##" class="adminHomeBack">Administration</a></li>
						<li class="current"><a href="##group-#group.key#" class="k-content">#group.name#</a></li>
					</ol></nav></div>
					<h5 class="adminHomeHeading">#group.name#</h5>
					<div class="adminHomeGrid">
					<cfloop list="#group.icons#" index="key">
						<cfset i = listFindNoCase(iconList, key)>
						<cfif i>
						<a class="adminHomeTile adminHomeIcon k-content" id="#listGetAt(iconList, i)#" href="#listGetAt(linkList, i)#">
							<img src="#application.baseUrl##listGetAt(imageList, i)#" alt="">
							<span class="adminHomeName">#listGetAt(titleList, i)#</span>
							<cfif key eq "Comments" and homeStatus.comments><span class="adminHomeBadge">#homeStatus.comments#</span></cfif>
						</a>
						</cfif>
					</cfloop>
					</div>
				</div>
				</cfloop>
				</cfoutput>
				<script>
					<!--- Traffic cards: drawn here from the numbers (a trend line, bars), so no chart library is downloaded. --->
					(function () {
						if (!document.getElementById("adminTraffic")) { return; }
						var esc = function (t) { return $("<div/>").text(t).html(); };
						jQuery.ajax({ type: "post", url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=getAdminTraffic",
							data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>" }, dataType: "json" }).done(function (response) {
							if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
							if (!response || !response.success) { $("#trafficVisitors").text("The visitor numbers couldn't be read."); return; }
							var t = response.traffic, n = function (x) { return Math.round(+x || 0); };
							// Visitors: this week, the change on last week, a 30-day line.
							var change = "";
							if (n(t.peopleLastWeek) > 0) {
								var pct = Math.round((n(t.peopleThisWeek) - n(t.peopleLastWeek)) / n(t.peopleLastWeek) * 100);
								change = (pct >= 0 ? "\u25B2 " : "\u25BC ") + Math.abs(pct) + "% on last week";
							} else if (n(t.peopleThisWeek) > 0) { change = "None last week"; }
							var points = (t.days || []).map(function (d) { return n(d.people); }), max = Math.max.apply(null, points.concat([1]));
							var line = points.map(function (v, i) { return (i * (300 / Math.max(1, points.length - 1))).toFixed(1) + "," + (56 - v / max * 50).toFixed(1); }).join(" ");
							$("#trafficVisitors").html('<div class="adminTrafficBig">' + n(t.peopleThisWeek) + '</div><div class="adminTrafficNote">' + esc(change || "people this week") + '</div>'
								+ '<svg class="adminTrafficLine" viewBox="0 0 300 60" preserveAspectRatio="none" aria-label="Visitors a day, the last 30 days"><polyline points="' + line + '" fill="none" stroke="currentColor" stroke-width="2" vector-effect="non-scaling-stroke"/></svg>'
								+ '<div class="adminTrafficNote">Last 30 days' + (n(t.botsThisWeek) ? ', plus ' + n(t.botsThisWeek) + ' bots this week (not counted)' : '') + '</div>');
							// Most read.
							var top = t.topPosts || [], most = top.length ? Math.max.apply(null, top.map(function (p) { return n(p.reads); })) : 1;
							$("#trafficTop").html(top.length ? top.map(function (p) {
								return '<div class="adminTrafficRow"><span class="adminTrafficLabel" title="' + esc(p.title) + '">' + esc(p.title) + '</span><span class="adminTrafficCount">' + n(p.reads) + '</span>'
									+ '<span class="adminTrafficBar"><span style="width:' + Math.max(4, n(p.reads) / most * 100) + '%"></span></span></div>';
							}).join("") : '<div class="adminTrafficNote">No reads yet this week.</div>');
							// Where they came from.
							var s = t.sources || {}, parts = [["search", "Search engines"], ["social", "Social media"], ["sites", "Other sites"], ["direct", "Straight in"]];
							var total = parts.reduce(function (a, p) { return a + n(s[p[0]]); }, 0);
							$("#trafficSources").html(total ? '<div class="adminTrafficStack">' + parts.map(function (p, i) {
								return n(s[p[0]]) ? '<span class="adminTrafficPart' + i + '" style="width:' + (n(s[p[0]]) / total * 100) + '%" title="' + p[1] + '"></span>' : "";
							}).join("") + '</div>' + parts.map(function (p, i) {
								return '<div class="adminTrafficRow"><span class="adminTrafficDot adminTrafficPart' + i + '"></span><span class="adminTrafficLabel">' + p[1] + '</span><span class="adminTrafficCount">' + n(s[p[0]]) + '</span></div>';
							}).join("") : '<div class="adminTrafficNote">No visitors yet this week.</div>');
							// Reading now.
							var now = t.now || [];
							$("#trafficNow").html('<div class="adminTrafficBig">' + n(t.nowCount) + '</div><div class="adminTrafficNote">' + (n(t.nowCount) === 1 ? "person" : "people") + ' in the last 15 minutes</div>'
								+ now.map(function (r) { return '<div class="adminTrafficRow"><span class="adminTrafficLabel">' + esc(r.page) + '</span><span class="adminTrafficCount">' + (n(r.minutesAgo) ? n(r.minutesAgo) + " min" : "now") + '</span></div>'; }).join(""));
						}).fail(function () { $("#trafficVisitors").text("The visitor numbers couldn't be read."); });
					})();
					<!--- Up next: the x hides a suggestion until something new happens (AdminHome.cfc hide). --->
					$(document).on("click", ".adminHomeHide", function () {
						var button = $(this), wrap = button.closest(".adminHomeSuggestWrap");
						wrap.fadeTo(150, .3);
						jQuery.ajax({ type: "post", url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=hideUpNext",
							data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", kind: button.data("kind"), signature: String(button.data("signature")) }, dataType: "json" })
							.done(function () { wrap.remove(); }).fail(function () { wrap.fadeTo(150, 1); });
					});
					<!--- A group's page in place of the home; the address carries it (group-logs), so Back and a refresh keep it. --->
					(function () {
						function show() {
							var m = /^#group-([a-z]+)$/.exec(window.location.hash), page = m ? document.getElementById("adminGroup-" + m[1]) : null;
							document.getElementById("adminHome").style.display = page ? "none" : "";
							Array.prototype.forEach.call(document.querySelectorAll(".adminGroupPage"), function (p) { p.style.display = p === page ? "" : "none"; });
						}
						<!--- No page loads: a group is shown in place, and the address changes only after the #, so the browser's Back
						button returns to the home view and a refresh keeps the group open. --->
						Array.prototype.forEach.call(document.querySelectorAll(".adminHomeGroup"), function (b) {
							b.addEventListener("click", function () { window.history.pushState(null, "", "#group-" + b.getAttribute("data-group")); show(); window.scrollTo(0, 0); });
						});
						Array.prototype.forEach.call(document.querySelectorAll(".adminHomeBack"), function (a) {
							a.addEventListener("click", function (e) { e.preventDefault(); window.history.replaceState(null, "", window.location.pathname + window.location.search); show(); });
						});
						window.addEventListener("popstate", show);
						window.addEventListener("hashchange", show);
						show();
					})();
				</script>

			</span>
		</div>

		<!--- The Kendo theme's primary color (owner, 10-20), as its primary buttons use it (blog.cfc getPrimaryColorsByTheme): the
		edge of an Up next suggestion, the new-this-week note on the groups, and the This week line and bars. Blue if it can't be read. --->
		<cftry>
			<cfset homeAccent = application.blog.getPrimaryColorsByTheme(kendoTheme: kendoTheme, setting: "accentColor")>
			<cfcatch type="any"><cfset homeAccent = ""></cfcatch>
		</cftry>
		<cfif not reFindNoCase("^##?[0-9a-f]{3,8}$|^rgba?\(", trim(homeAccent))><cfset homeAccent = "##0969da"></cfif>
		<cfif reFindNoCase("^[0-9a-f]{3,8}$", trim(homeAccent))><cfset homeAccent = "##" & trim(homeAccent)></cfif>
		<!--- Stylesheet for the icon and tooltips. --->
		<style>
			<!--- The regrouped home (5.0). --->
			#adminHome, .adminGroupPage { --homeAccent: <cfoutput>#homeAccent#</cfoutput>; }
			#adminHome, .adminGroupPage { max-width: 980px; margin: 0 auto; }
			.adminHomeSection { margin-top: 14px; }
			.adminHomeHeading { font-size: 13px; text-transform: uppercase; letter-spacing: .06em; opacity: .75; margin: 18px 0 10px; text-align: left; }
			.adminHomeGrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(<cfif session.isMobile>130<cfelse>150</cfif>px, 1fr)); gap: 14px;  grid-auto-rows: 1fr; }
			.adminHomeTile { position: relative; display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 14px 8px 12px; border: 1px solid rgba(128,128,128,.35); border-radius: 8px; text-align: center; text-decoration: none; color: inherit; cursor: pointer; font: inherit; }
			.adminHomeTile:hover, .adminHomeTile:focus { box-shadow: 0 0 2px 1px rgba(0, 140, 186, 0.5); }
			.adminHomeTile img { width: <cfif session.isMobile>56<cfelse>72</cfif>px; height: <cfif session.isMobile>56<cfelse>72</cfif>px; object-fit: contain; }
			.adminHomeName { font-weight: bold; }
			.adminHomeWhat { font-size: 13px; opacity: .75; line-height: 1.3; }
			.adminHomeStatus { font-size: 13px; font-weight: bold; color: #d1242f; }
			.adminHomeStatus.adminHomeInfo { color: var(--homeAccent); }
			.adminHomeBadge { position: absolute; top: 8px; right: 8px; background: #d1242f; color: #ffffff; font-size: 12px; font-weight: bold; border-radius: 10px; padding: 2px 7px; }
			.adminHomeQuick .adminHomeGrid { grid-template-columns: repeat(auto-fill, minmax(<cfif session.isMobile>150<cfelse>200</cfif>px, 1fr)); }
			.adminHomeQuick .adminHomeTile { flex-direction: row; justify-content: flex-start; padding: 10px 12px; text-align: left; }
			.adminHomeQuick .adminHomeTile img { width: 40px; height: 40px; }
			<!--- Up next suggestions (things that need the owner now) have a line in the theme's primary color down the left, and an x at the
			top right; the always-there shortcuts (Create Post, Create Page...) have neither. --->
			.adminHomeSuggestWrap { position: relative; }
			.adminHomeSuggestWrap > .adminHomeTile { box-sizing: border-box; height: 100%; border-left: 4px solid var(--homeAccent); }
			.adminHomeSuggestText { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
			.adminHomeQuick .adminHomeGrid { grid-auto-rows: 1fr; }   <!--- every tile as tall as the tallest, also when the row wraps --->
			.adminHomeQuick .adminHomeGrid > * { align-self: stretch; }
			.adminHomeQuick .adminHomeGrid > a.adminHomeTile { box-sizing: border-box; height: 100%; }
			.adminHomeHide { position: absolute; top: 4px; right: 6px; border: 0; background: none; color: inherit; opacity: .55; font-size: 18px; line-height: 1; cursor: pointer; padding: 2px 4px; }
			.adminHomeHide:hover, .adminHomeHide:focus { opacity: 1; }
			.adminHomeCaughtUp { text-align: left; margin: -4px 0 10px; opacity: .8; }
			<!--- Traffic cards (5.0). --->
			.adminTrafficGrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(<cfif session.isMobile>220<cfelse>210</cfif>px, 1fr)); gap: 14px; text-align: left; }
			.adminTrafficCard { border: 1px solid rgba(128,128,128,.35); border-radius: 8px; padding: 12px 14px; min-width: 0; }
			.adminTrafficTitle { font-weight: bold; margin-bottom: 8px; }
			.adminTrafficBig { font-size: 30px; font-weight: bold; line-height: 1.1; }
			.adminTrafficNote { font-size: 13px; opacity: .75; margin-top: 2px; }
			.adminTrafficLine { display: block; width: 100%; height: 56px; margin-top: 8px; color: var(--homeAccent); }
			.adminTrafficRow { display: grid; grid-template-columns: auto 1fr auto; gap: 2px 8px; align-items: center; font-size: 13px; margin-top: 6px; }
			.adminTrafficRow .adminTrafficLabel { grid-column: 1 / 3; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
			.adminTrafficRow .adminTrafficDot + .adminTrafficLabel { grid-column: 2 / 3; }
			.adminTrafficCount { font-weight: bold; }
			.adminTrafficBar { grid-column: 1 / -1; height: 5px; border-radius: 3px; background: rgba(128,128,128,.2); overflow: hidden; }
			.adminTrafficBar > span { display: block; height: 100%; background: var(--homeAccent); }
			.adminTrafficStack { display: flex; height: 12px; border-radius: 6px; overflow: hidden; background: rgba(128,128,128,.2); margin-bottom: 4px; }
			.adminTrafficDot { width: 10px; height: 10px; border-radius: 50%; }
			.adminTrafficPart0 { background: var(--homeAccent); } .adminTrafficPart1 { background: color-mix(in srgb, var(--homeAccent) 55%, #ffffff); } .adminTrafficPart2 { background: color-mix(in srgb, var(--homeAccent) 60%, #000000); } .adminTrafficPart3 { background: #9aa4ae; }
			.adminHomeCrumb { text-align: left; margin: 10px 0 0; padding: 5px; }

			span.icon {
				<!--- To correctly align image, regardless of content height: --->
				vertical-align: top;
				display: inline-block;
				<!--- To horizontally center images and caption --->
				text-align: center;
				<!--- The width of the container also implies margin around the images. --->
				width: <cfif session.isMobile>105<cfelse>125</cfif>px;
				height: <cfif session.isMobile>130<cfelse>195</cfif>px;
			}

			<!--- Room under the last row, so that a caption that wraps to two lines does not run into the border of the panel. --->
			#iconNavMenu {
				display: block;
				padding-bottom: 25px;
			}

			.icon img {
				width: <cfif session.isMobile>90<cfelse>133</cfif>px;
				height: <cfif session.isMobile>90<cfelse>133</cfif>px;;
			}

			<!--- Add a hover effect (blue shadow) --->
			.icon img:hover {
				box-shadow: 0 0 2px 1px rgba(0, 140, 186, 0.5);
				opacity: .82;
			}

			.caption {
				<!--- Make the caption a block so it occupies its own line. --->
				display: block;
			}

			<!--- Custom classes for the tooltips. These classes will be used to override the base k-tooltip class. --->
			.iconBottomRow {
				width: var(--toolTipWidth);
				height: var(--toolTipHeight);
				font-size: var(--toolTipFontSize);
				border-radius: 10px;
			}

			<!--- Custom classes for the tooltips. These classes will be used to override the base k-tooltip class. --->
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