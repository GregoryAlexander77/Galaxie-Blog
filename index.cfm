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
<!--- Straight after a new install (5.0): on to the Site Wizard, which asks the new owner to sign in first. Only the one
request that finished the install has this flag (Application.cfc), so every other visit is unaffected. --->
<!--- Section timings (2026-10-27): ?galaxieTimings=1 adds an X-Galaxie-Timings response header with the milliseconds at the end of each part of the page (curl -sI "...?galaxieTimings=1"). Nothing is shown on the page, and without the parameter it does nothing. ---><cfset request.galaxieTimeIt = structKeyExists(url, "galaxieTimings")><cfset request.galaxieT0 = getTickCount()><cfset request.galaxieMarks = "">
<cfif isDefined("request.blogJustInstalled") and request.blogJustInstalled>
	<cflocation url="#application.baseUrl#/admin/setup.cfm" addToken="false">
</cfif>
	
<!--- //******************************************************************************************************************
			Page settings.
//********************************************************************************************************************--->
	
<!--- Unique page settings that may vary on each different page. --->
<cfscript>
	pageId = 1;
	pageName = "Blog"; // Blog
	pageTypeId = 1; // Blog

	// Homepage override: what shows at the site root, set via Configure Homepage. Only applies to an actual
	// visit to the root itself (no path after index.cfm) - every other address (a post, a page, a category,
	// a Page Collection's own URL) is completely unaffected. See doc/pageCollectionsDesign for the design.
	urlAfterIndexCfm = trim(reReplaceNoCase(trim(cgi.path_info), '.+\.cfm/? *', ''));
	// The regex above only strips a literal ".cfm/" prefix, which is what a front-end pretty-URL rewrite
	// forwards. A request that reaches this file directly (path_info with no ".cfm" in it at all, e.g. hitting
	// /index.cfm/something straight from the app server with nothing rewriting it first) leaves the leading
	// slash untouched, which would otherwise make urlAfterIndexCfm never match a single-segment alias below.
	urlAfterIndexCfm = reReplaceNoCase(urlAfterIndexCfm, '^/+', '');
	if (len(urlAfterIndexCfm) eq 0 and isDefined("application.blog")) {
		homepageSettings = application.blog.getHomepageSettings();
		// One page ALONE is the whole homepage; one page with blog posts (or collections) is an introduction above them, on the
		// curated homepage below (2026-10-20: Site Wizard's "Your About page, then your latest posts" used to show only the page).
		if (homepageSettings.showPages and listLen(homepageSettings.pageIdList) eq 1 and not homepageSettings.showBlogPosts and not homepageSettings.showCollections) {
			// The single-page override: Pages is on and exactly one Page is selected - that Page's own full
			// content becomes the ENTIRE homepage (site chrome still shows), ignoring whatever Collections/Blog
			// Posts toggles say. Only when 0 or 2+ pages are selected does the additive/stacked model below apply.
			pageId = listFirst(homepageSettings.pageIdList);
			pageName = "FrontPage";
			pageTypeId = 9;
			postId = listFirst(homepageSettings.pageIdList);
		} else if (homepageSettings.showPages or homepageSettings.showCollections or homepageSettings.showBlogPosts) {
			// The additive/curated homepage - any independent combination of Featured Pages (2+), Featured
			// Collections, and/or recent Blog Posts, stacked in that fixed order. pageTypeId 24 is this file's own
			// sentinel; see the <cfelseif pageTypeId eq 24> branch below and
			// includes/templates/curatedHomepageContentHtml.cfm, which reads the same getHomepageSettings() struct
			// directly rather than through params/getPost.cfm (it needs several independent Post/Collection
			// fetches on one page, not the shared single-array pipeline getmode.cfm/getPost.cfm assume).
			pageTypeId = 24;
		}
		// Neither showPages, showCollections, nor showBlogPosts is on: falls through to the untouched default,
		// pageTypeId 1 (the plain paginated main blog listing) - the same behavior a fresh/default blog always had.
	}

	// A Page Collection's own URL (e.g. /portfolio), independent of the homepage setting above. Only a
	// single-segment path is a candidate (matching how parseses.cfm treats a single segment as a page-or-category
	// alias) - checked only when this isn't already the root (handled above) and only when it did not already
	// get routed to a Page Collection as the homepage.
	// Only a LIVE page (released, not removed) wins over a Collection here. pageExists() also counts drafts and
	// removed pages, so an old unpublished page sharing a Collection's alias used to take the URL and then show
	// "Post Not Found" (the post itself is never displayed unless released and not removed).
	livePageOwnsAlias = false;
	if (len(urlAfterIndexCfm) and not find("/", urlAfterIndexCfm) and isDefined("application.blog")) {
		livePageOwnsAlias = arrayLen(ormExecuteQuery(
			"SELECT PostId FROM Post WHERE BlogRef = #application.BlogDbObj.getBlogId()# AND IsPage = 1 AND PostAlias = :alias AND Remove = 0 AND Released = 1",
			{ alias = urlAfterIndexCfm }
		)) gt 0;
	}
	if (len(urlAfterIndexCfm) and not find("/", urlAfterIndexCfm) and isDefined("application.blog") and not livePageOwnsAlias) {
		// A real Page's own alias always wins over a same-named Collection alias, same precedence as
		// parseses.cfm already gives a page over a category for a single-segment URL.
		matchedPageCollectionId = application.blog.getPageCollectionByAlias(urlAfterIndexCfm);
		if (matchedPageCollectionId gt 0) {
			// A cross-link Collection (ExternalUrl set) isn't really an internal listing - redirect straight to its
			// external destination rather than rendering its (1+) member pages as cards. See
			// [[front-page-page-groups-design-rethink]]/PageCollection.cfc's own comment on ExternalUrl.
			matchedPageCollectionEntity = entityLoadByPK("PageCollection", matchedPageCollectionId);
			if (isObject(matchedPageCollectionEntity) and len(matchedPageCollectionEntity.getExternalUrl())) {
				location(url=matchedPageCollectionEntity.getExternalUrl(), addToken=false);
			}
			pageTypeId = 20;
			homepageCollectionId = matchedPageCollectionId;
		// The fixed "browse all Page Collections" page (e.g. /blog/collections), analogous to a Category archive
		// but for every visible Collection instead of one Category's posts. Only reached when nothing real (a Page
		// or a specific Collection) already owns this exact alias, same real-content-always-wins precedence as above.
		} else if (urlAfterIndexCfm eq "collections") {
			pageTypeId = 23;
		// The Events page (2026-10-15, e.g. /blog/events): upcoming and past events, a month calendar and the calendar feed.
		// Same precedence: a real Page or Collection called "events" wins.
		} else if (urlAfterIndexCfm eq "events" and structKeyExists(application, "events")) {
			pageTypeId = 25;
		}
	}

	// A Page Collection renders through the exact same pipeline as everything else (Category/Tag archives,
	// the main blog list) - real themed post cards via blogContentHtml.cfm, not a bespoke template. The only
	// thing special about a Collection is WHICH posts end up in the getPost array: its members, in their
	// stored SortOrder. That's handed to getPost.cfm below via params.byPostIdList (see that file and
	// blog.cfc's getPost()'s existing postIdList argument - already used by the Related Posts widget).
	if (pageTypeId eq 20) {
		homepageCollectionMembers = application.blog.getPageCollectionMembers(homepageCollectionId);
		homepageCollectionPostIdList = "";
		for (member in homepageCollectionMembers) {
			homepageCollectionPostIdList = listAppend(homepageCollectionPostIdList, member.postId);
		}
	}
</cfscript>
<!---
Custom page example:
<cfset pageId = unique number>
<cfset pageName = "unique string">
<cfset pageTypeId = 9>

Optional custom page variables 
postId: Id allows to create content from a unique post in the database. This usually is not necessary as you can create dynamic pages from a post using the admin page that sets the isPage column to true in the database.
customPageTemplate: path allows to use a custom template using a hardcoded cfinclude. 
--->	
	
<!--- //******************************************************************************************************************
			Inspect the URL 
//********************************************************************************************************************--->

<!--- This template gets the number of forward slashes in a year and determines what is being sent by the positions of the elements in the URL. --->
<cfmodule template="#application.baseUrl#/tags/parseses.cfm" /> 
	
<!--- Raymond's module to inspect the URL to determine what to pass to the getPost method. Get mode also deterines the start and end row determined by what type of page this is (blog or post for example). This works in conjunction with parses.cfm above. I may rewrite this in a future version. --->
<cfmodule template="#application.baseUrl#/tags/getmode.cfm" r_params="params"/>
<!---<cfdump var="#params#" label="params">--->

<!--- A Page Collection's members, or an ad-hoc multi-page homepage selection, override whatever url.mode/getmode.cfm
	decided (this is not a normal category/tag/day address) - hand getPost.cfm the ordered postId list instead, see
	the cfscript block up top. --->
<cfif pageTypeId eq 20 or pageTypeId eq 21>
	<!--- parseses.cfm/getmode.cfm have already read this single-segment address as a page or category alias. If a
	(draft/removed) page or a category shares the Collection's alias, their byAlias/byCat filter stayed in params
	alongside byPostIdList, so no member matched both and the Collection showed "Post Not Found". Reset to the same
	state a Collection with no clashing alias gets: no filters, mode "full". --->
	<cfloop list="byAlias,byEntry,byDay,byMonth,byYear,byCat,byTag,byPosted,searchTerms" index="collectionClearParam">
		<cfset structDelete(params, collectionClearParam)>
	</cfloop>
	<cfset url.mode = "full">
	<cfset params.byPostIdList = homepageCollectionPostIdList>
	<!--- Show every member on one page. getmode.cfm set maxEntries to the site's page size (application.maxEntries,
	9 on galaxieblog.org), so a Collection with more members than that silently lost the extras - the 12-page
	"Writing and Editing Posts" docs collection showed only 9 (2026-10-09). A Collection has no pager. --->
	<cfset params.maxEntries = max(listLen(homepageCollectionPostIdList), 1)>
	<cfset params.startrow = 1>
</cfif>

<!--- Page 2+ of the curated homepage's Blog Posts section (pageTypeId 24, see the cfelseif pageTypeId eq 24 branch
further down) should show the same "up to 5 rows" the curated homepage's own page 1 shows, not the flat
application.maxEntries (9, exactly 3 rows on desktop). The real column-aware row count isn't known yet here -
showSidebar isn't set until pageSettings.cfm runs, further down - so this over-fetches to the max any column
count could need (5 rows * 3 columns) and blogContentHtml.cfm trims it back down to the real column-aware count
once showSidebar is known, the same way curatedHomepageContentHtml.cfm already sizes its own page 1. --->
<cfif pageTypeId eq 24>
	<cfset params.maxEntries = 15>
</cfif>

<!--- //******************************************************************************************************************
			Get the post(s)
//********************************************************************************************************************--->

<cfinclude template="#application.baseUrl#/includes/templates/getPost.cfm">
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "getPost=" & (getTickCount() - request.galaxieT0) & " "></cfif>
<!---<cfdump var="#getPost#" label="getPost">--->
	
<!--- //******************************************************************************************************************
			Global page settings and cache
//********************************************************************************************************************--->

<!--- Include the functions that are used in the UI --->
<cfinclude template="#application.baseUrl#/common/function/page.cfm">
	
<!--- //******************************************************************************************************************
			Get the page properties
//********************************************************************************************************************--->
	
<!--- The pageSettings also determines when we should cache the page depending upon if the user is logged in. --->
<cfinclude template="#application.baseUrl#/includes/templates/pageSettings.cfm">

<!--- //******************************************************************************************************************
			Core logic (queries the database and sets vars)
//********************************************************************************************************************--->
	
<!--- Determine whether we should disable the cache. --->
<cfset disableCache = application.blog.getDisableCache()>	
<!--- The Themes window's preview frame (5.0) is drawn fresh each time, with the look being edited. --->
<cfif isDefined("url.previewTheme") and application.blog.getThemeEditor().isPreviewRequest()>
	<cfset disableCache = true>
</cfif>
<!--- Site Wizard's previews of an unsaved home layout or post picture style (2026-10-20) are never cached either. --->
<cfif (isDefined("url.previewHome") or isDefined("url.previewHeroStyle")) and application.Udf.isLoggedIn()>
	<cfset disableCache = true>
</cfif>
<!--- We need to differentiate material and non-material themes to apply the right settings to the buttons. Computed once here instead of twice further down (sidebar div and sidebar panel both need it). --->
<cfif kendoTheme contains 'material'>
	<cfset materialTheme = true>
<cfelse>
	<cfset materialTheme = false>
</cfif>
<!--- Get post information from the db --->
<cfinclude template="#application.baseUrl#/includes/templates/coreLogic.cfm">
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "coreLogic=" & (getTickCount() - request.galaxieT0) & " "></cfif>

<!--- //******************************************************************************************************************
			Page output
//********************************************************************************************************************--->
</cfsilent>
<cfsavecontent variable="pageHtml"><html lang="en-US"><head><cfoutput>
<cfinclude template="#application.baseUrl#/includes/templates/head.cfm" />
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "head=" & (getTickCount() - request.galaxieT0) & " "></cfif>
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
<!--- Breaks out of a frame on another site; the blog's own pages may frame it (the Site Wizard's live preview, 2026-10-19). --->
<body onload="if (top != self) { var ownSite = false; try { ownSite = top.location.host === self.location.host; } catch (e) {} if (!ownSite) top.location.replace(self.location.href); }" onresize="setScreenProperties()">
<cfsilent>
<!---//*******************************************************************************************************************
			Font .css
//********************************************************************************************************************--->

<!--- Set up cache. This needs to use the themeId as the fonts are different for each theme. The fonts should never expire. This code is also minimized. --->
<cfset cacheName = buildCacheKey("font", themeId)>
<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. This can't be in a cfsilent block --->
</cfsilent>
<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cacheName#" scope="html" file="#application.baseUrl#/cache/fonts/#cacheName#.cfm" debug="false" disabled="#disableCache#">
<cfinclude template="#application.baseUrl#/includes/templates/font.cfm" />
</cfmodule>

<cfsilent>
<!---//*******************************************************************************************************************
			Global and body .css
//********************************************************************************************************************--->
	
<!--- Cache notes: this template contains dynamic images and other elements that are dependent upon the theme. It should not be cached. --->
</cfsilent>
<cfinclude template="#application.baseUrl#/includes/templates/blogContentCss.cfm" />
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "css=" & (getTickCount() - request.galaxieT0) & " "></cfif>
<cfsilent>		
<!---//*******************************************************************************************************************
			Top menu html
//********************************************************************************************************************--->
	
<!--  Outer container. This container controls the blog width. The 'k-alt' class is used when there are alternating rows and you want to differentiate them. Typically, it is a darker color that 'k-content'. We will set the min width of the container to be 968 pixels and the min width of the blog content to be 640 pixels. This should give approximately 300 miniumum pixels to the side bar on the right. -->
	
<!--- Set up cache. We need to save the theme and the device type (ie mobile) in the cache name. --->
<cfset cacheName = buildCacheKey("topMenu", themeId)>

<!--- Note: there are two different layouts depending upon the stretchHeaderAcrossPage. Render the cached header once into a variable, then only branch on where it gets placed relative to the <table> tag. --->
</cfsilent>

<!--- Note: this needs to be an independent layer for the blog menu to keep the z-index intact in order to float over the top of the rest of the layers, such as the footer. !!! We need to use the themeId as each theme uses different background images in the menu --->
<cfsavecontent variable="headerHtml">
<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cacheName#" scope="html" file="#application.baseUrl#/cache/header/#cacheName#.cfm" debug="false" disabled="#disableCache#">
	<cfinclude template="#application.baseUrl#/includes/templates/topMenuHtml.cfm" />
</cfmodule>
</cfsavecontent>

<cfif not stretchHeaderAcrossPage>
<table id="mainBlog" class="k-alt" cellpadding="0" cellspacing="0" align="center">
	<tr>
	 <td>
		<cfoutput>#headerHtml#</cfoutput>
	 </td>
	</tr>
	<cfsilent>
	<!---//***************************************************************************************************************
				Javascript for the blog's Kendo widgets and UI interactions.
	//****************************************************************************************************************--->
	</cfsilent>
<cfelse><!---<cfif not stretchHeaderAcrossPage>--->
	<cfoutput>#headerHtml#</cfoutput>

<table id="mainBlog" class="k-alt" cellpadding="0" cellspacing="0" align="center">
</cfif><!---<cfif not stretchHeaderAcrossPage>--->
   <tr>
	<td>
		<cfinclude template="#application.baseUrl#/includes/templates/blogJsContent.cfm" />
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "js=" & (getTickCount() - request.galaxieT0) & " "></cfif>
	<cfsilent>
	<!---//***************************************************************************************************************
				Blog content html
	//****************************************************************************************************************--->
		
	<!--- Note: the blog content HTML template is too sophisticated to cache the entire template. Instead, we will cache parts of it  
		
	Debugging
	<cfoutput>getPageMode(): #getPageMode()# condensedGridView: #condensedGridView#</cfoutput>
	<cfdump var="#params#" label="params">
	<cfdump var="#URL#" label="URL">
	--->
	</cfsilent>		
	
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "beforeContent=" & (getTickCount() - request.galaxieT0) & " "></cfif>
	<!-- Blog body -->
	<main>
		<cfif pageTypeId eq 1>
			<!--- Main blog --->
			<cfinclude template="#application.baseUrl#/includes/templates/blogContentHtml.cfm" />
		<cfelseif pageTypeId eq 9>
			<cfif isDefined("customPageTemplate") and len(customPageTemplate)>
				<!--- Custom page with a hardcoded template --->
				<cfinclude template="#customPageTemplate#">
			<cfelse>
				<!--- Standard page --->
				<cfinclude template="#application.baseUrl#/includes/templates/blogContentHtml.cfm" />
			</cfif>
		<cfelseif pageTypeId eq 20 or pageTypeId eq 21>
			<!--- A Page Collection (20) or an ad-hoc multi-page homepage selection (21) - see the sentinel comments
			above. Both render through the exact same pipeline as a Category/Tag archive: getPost.cfm already
			populated the getPost array with the right posts (in their stored/selected order) via params.byPostIdList,
			so this is just the normal card-grid renderer, same as pageTypeId 1/9. See doc/pageCollectionsDesign for why
			this replaced the old pageCollectionContentHtml.cfm (a single collection-level card + a plain link list) -
			that file is kept for now, likely to be reused for a future "browse all collections" listing instead. --->
			<cfinclude template="#application.baseUrl#/includes/templates/blogContentHtml.cfm" />
		<cfelseif pageTypeId eq 22 or pageTypeId eq 23>
			<!--- pageTypeId 22: one or more Page Collections selected as the homepage (the multi-select-collections
			feature) - one card per Collection, same as blog posts. pageTypeId 23: the fixed "browse all Page
			Collections" page (e.g. /blog/collections) - every visible Collection, same card rendering. Neither
			expands into a Collection's own members (that's pageTypeId 20, visiting its own URL directly). See the
			cfscript block above and includes/templates/pageCollectionListContentHtml.cfm. --->
			<cfinclude template="#application.baseUrl#/includes/templates/pageCollectionListContentHtml.cfm" />
		<cfelseif pageTypeId eq 25>
			<!--- The Events page (/events) - see the cfscript block above and includes/templates/eventListContentHtml.cfm. --->
			<cfinclude template="#application.baseUrl#/includes/templates/eventListContentHtml.cfm" />
		<!--- Not for a filtered address (2026-10-18): ?mode=month (the sidebar calendar), a day, category, tag, author or search
		showed the curated homepage instead, and its "All Blogs" page 2 then applied the month filter 15 rows in - an empty page
		(the "No Entries" bug, galaxieBlogPagerNoEntries.log 10/08). A filtered address falls through to the normal listing
		below. isPlainBlogListing is set by getPost.cfm. --->
		<cfelseif pageTypeId eq 24 and (not isDefined("URL.startRow") or val(URL.startRow) lte 1) and (not isDefined("isPlainBlogListing") or isPlainBlogListing)>
			<!--- The additive/curated homepage, page 1 only - Featured Pages, Featured Collections and/or Blog Posts,
			any independent combination, stacked in that order. Reads getHomepageSettings() directly rather than through
			getPost.cfm's single-array params pipeline, since it needs several independent fetches on one page. --->
			<cfinclude template="#application.baseUrl#/includes/templates/curatedHomepageContentHtml.cfm" />
		<cfelseif pageTypeId eq 24>
			<!--- Paging past page 1 of the curated homepage's Blog Posts section drops Featured Pages/Collections
			entirely and falls through to the exact same plain paginated post-card rendering pageTypeId=1 uses -
			getPost.cfm already populated the shared getPost array using the standard params/maxEntries pipeline for
			this case (pageTypeId 24 isn't one of the special-cased ids that pipeline branches on), so this is not a
			special case to render, just the normal listing. See curatedHomepageContentHtml.cfm's own pager, which
			carries the "fps" (first page size) query param forward so blogContentHtml.cfm's pager can keep computing
			correct offsets for page 3+ even though page 1 was a different size. --->
			<cfinclude template="#application.baseUrl#/includes/templates/blogContentHtml.cfm" />
		<cfelse>
			<div id='contentInnerContainer' class="k-content"><!--- This must be a content container class --->
				<cfif pageTypeId eq 2><!--- Admin pages --->
					<!-- Dynamic content loaded via jQuery and Ajax. -->
					<cfinclude template="#application.baseUrl##getTemplatePathByPageName(pageName)#" /><!--- The getTemplatePathByPageName is in /common/function/page.cfm --->
				</cfif>
			</div><!--<div id='contentInnerContainer' class="k-content">-->
		</cfif><!---<cfif pageTypeId eq 1>--->
		<cfsilent>
		<!---//***************************************************************************************************************
					Sidebar div
		In classic mode, the side bar div is always displayed on the right side of the blog page. It is also used as a responsive panel on desktop devices when the screen size is small. We will not include it if the break point is not 0 or is equal or above 50000. If the chosen theme type is classic, this get's loaded first and then the panel below gets loaded. If the device is mobile or the theme is a modern theme, this sidebar does not exist.
		//****************************************************************************************************************--->

		</cfsilent>	
		<cfif breakpoint gt 0>
			<div id="sidebar">
				<!--- The cfmodule below identical to a cfinclude and has no end tag and is not part of galaxieCache. Make sure to supply the sidebar type. This is a duplicate sidebar when using desktop and the theme type is classic --->
				<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "beforePodsDiv=" & (getTickCount() - request.galaxieT0) & " "></cfif>
<cfmodule template="#application.baseUrl#/includes/templates/content/pods/index.cfm" sideBarType="div" scriptTypeString="#scriptTypeString#"  materialtheme="#materialTheme#" modernTheme="#modernTheme#" darkTheme="#darktheme#">
			</div><!---<nav id="sidebar">--->
		</cfif>
		</div><!---<div id="mainPanel" class="flexParent">--->

		<cfsilent>
		<!---//***************************************************************************************************************
					Sidebar panel
		This sidebar panel is always a fly-out panel on the left of the page. This panel is a duplicate of the sidebar div when the theme type is classic. If the theme type is modern or when the device is mobile, this is the only panel on the page. This panel is invoked when the user clicks on the hamburger icon in the menu at the top of the page.
		//****************************************************************************************************************--->

		</cfsilent>	
		<nav id="sidebarPanel" class="k-content">
			<div id="sidebarPanelWrapper" name="sidebarPanelWrapper" class="flexScroll"> 
				<!--- This cfmodule acts like a cfinclude and is not part of galaxieCache. Make sure to suppply the sideBarType argument. DIV --->
				<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "beforePodsPanel=" & (getTickCount() - request.galaxieT0) & " "></cfif>
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
		<!--- End Sidebar --->
		<!--- The right-hand #sidebar column was just rendered above. sideBarPanel.cfm (included further down for page types above 1) must still run - its hidden sidebarPanelState field and fly-out panel are what the floating menu's hamburger opens - but it must not render the #sidebar column a second time, or a second set of pods stacks up below the main panel (the 4.8 curated home page is page type 24, found in the 4.8 install test, 2026-10-12). --->
		<cfset inlineSidebarRendered = true>
	</main>
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
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "sideBarPanel=" & (getTickCount() - request.galaxieT0) & " "></cfif>
	</cfmodule>
</cfif><!---<cfif pageTypeId gt 1>--->
<cfsilent>
<!---//*****************************************************************************************************************
			Footer (the administrative interface does not need a footer)
//**************************************************************************************************************--->
		
<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. The module or tag can't be in a cfsilent block. Bug fix: this cache key previously omitted themeId entirely ('footerHtml'/'footerHtmlMobile'), so every theme after the first served a stale, wrong-theme footer from cache. Now theme-aware like the header and font cache keys. --->
<cfset cacheName = buildCacheKey("footer", themeId)>
</cfsilent>
<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. This can't be in a cfsilent block --->
<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cacheName#" scope="html" file="#application.baseUrl#/cache/footer/#cacheName#.cfm" debug="false" disabled="#disableCache#">
	<cfinclude template="#application.baseUrl#/includes/templates/content/footer/footer.cfm" />
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "footer=" & (getTickCount() - request.galaxieT0) & " "></cfif>
</cfmodule>  
<!--- The footer above is cached for every visitor, so its "customize this footer" hint for admins is revealed here, outside the cache. --->
<cfif application.Udf.isLoggedIn()><script>var footerHint = document.getElementById("footerCustomizeHint"); if (footerHint) { footerHint.hidden = false; }</script></cfif>
<cfsilent>
	<!---//***************************************************************************************************************
				Tail end scripts
	//****************************************************************************************************************--->	
</cfsilent>
<cfinclude template="#application.baseUrl#/includes/templates/tailEndScripts.cfm" />
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfset request.galaxieMarks &= "tailEnd=" & (getTickCount() - request.galaxieT0) & " "></cfif>
<!--- 
Note: if the Zion theme is screwed up, check the use custom theme setting in the ini file.
--->
</body>
</html>
</cfsavecontent>
<cfif structKeyExists(request, "galaxieTimeIt") and request.galaxieTimeIt><cfheader name="X-Galaxie-Timings" value="#request.galaxieMarks#total=#getTickCount() - request.galaxieT0#"></cfif>
<cfinclude template="#application.baseUrl#/includes/templates/core/pageOutput.cfm" />
</cfprocessingdirective>
