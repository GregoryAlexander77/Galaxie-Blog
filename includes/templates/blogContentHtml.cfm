	<cfsilent>
	<!--- Forms that hold state. --->
	<!--- This is the sidebar responsive navigation panel that is triggered when the screen gets to a certain size. It is a duplicate of the sidebar div above, however, I can't properly style the sidebar the way that I want to within the blog content, so it is duplicated withoout the styles here. --->

	<!--- Instantiate the Render.cfc. This will be used to build the HTML for the image if the MediaUrl is present in the database. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<!--- Set the default max entries. --->
	<cfset maxEntries = application.maxEntries>

	<!--- Page 2+ of the curated homepage's Blog Posts section (pageTypeId 24) caps at a flat 15 per page, instead
	of the flat application.maxEntries every other page here uses. index.cfm already over-fetched to 15 before this
	array arrived, so this just trims down to it.
	2026-10-04: this used to multiply by homepageNumColumns (5 rows * 1 column on mobile = 5, vs 5 rows * 3 columns
	= 15 on desktop) to visually match page 1's own row-capped grid - but that meant a mobile reader needed 3x as
	many "next page" clicks as a desktop reader to get through the same content, which is worse UX on the device
	where clicking is more friction, not less. Page 2+ has no Featured Pages/Collections competing for vertical
	space the way page 1 does (see curatedHomepageContentHtml.cfm's 7-row budget comment), so there's no real
	reason to cap it by row count at all here - a flat, column-independent total keeps page COUNT (not grid shape)
	consistent between mobile and desktop: desktop still renders 5 rows of 3, mobile renders the same 15 posts
	stacked as one column, 15 deep. --->
	<cfif pageTypeId eq 24>
		<cfset maxEntries = 15>
		<cfif arrayLen(getPost) gt maxEntries>
			<cfset getPost = arraySlice(getPost, 1, maxEntries)>
		</cfif>
	</cfif>

	<!--- 
	Wide div in the center left of page.
	Note: this is the div that will be refreshed when new entries are made. All of the dynamic elements within this div 
	are refreshed when there are new posts, however, any logic *outside* of this div are not refreshed- so we need to get the query, and supply the arguments.
	--->
	</cfsilent>
	<div id="blogContent">		
		<!--- Optional hero interface. --->
		<div id="hero">
	<cfif showPopularPosts><!--- showPopularPosts is only shown on the front blog page. This var is set in the coreLogic.cfm template --->
		<cfsilent>
		<!---Cache this for one day--->
		<cfif session.isMobile>
			<cfset cacheKey = 'popularPosts#themeId#Mobile'>
		<cfelse>
			<cfset cacheKey = 'popularPosts#themeId#'>
		</cfif>
		</cfsilent>
		<!--- Cache this for a day. Bug fix: this previously referenced the stale "cachename"/"cacheName" variable
		left over from whatever cache was last set earlier in the request (e.g. the header/topMenu cache), not the
		cacheKey computed just above - it still worked (each cache still wrote to its own distinct file), but it
		shared its server-scope cache-metadata bookkeeping (timeout/hit count) with that unrelated cache. Now uses
		cacheKey, like it was clearly meant to. --->
		<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cacheKey#" scope="html" file="#application.baseUrl#/cache/cards/#cacheKey#.cfm" timeout="#(24*3600)#" debug="false" disabled="#application.disableCache#">
			<cfinvoke component="#application.blog#" method="getPost" returnvariable="getPosts">
				<cfinvokeargument name="showPopularPosts" value="true">
				<cfinvokeargument name="showPages" value="false">
				<cfinvokeargument name="showBlogPosts" value="true">
			</cfinvoke>
		<cfif arrayLen(getPost)>
			<cfset postScrollWidgetType = "popularPosts">
			<cfinclude template="popularPosts.cfm"><!--- This template is used for popular posts and related posts --->
		</cfif><!---<cfif arrayLen(getPost)>--->
	</cfmodule>
	</cfif><!---<cfif showPopularPosts>--->
		</div>

		<cfsilent><!--- Default blog modes --->
		<!--- Loop thru the articles. --->
		<cfset lastDate = "">
		<!--- Note: getPost is an array and contains one or more posts. It is used when in blog mode (multiple posts), or when in post mode (one post).--->
		</cfsilent>
	<cfif arrayLen(getPost)>
		<!--- The condensedGridView is a condensed view using Kendo cards with the post description --->
		<cfif condensedGridView>
			<cfsilent>
			<!--- ********************************************************************************************
					Handle Post Cards
			**********************************************************************************************--->

			<cfset isDebug = 0>

			<cfset columnCount = 0>
			<cfset rowCount = 1>
			<!--- When dealing with multiple posts, there is 1 card per row with mobile clients or when the sidebar is shown, otherwise, there are 3 columns shown --->				
			<cfif session.isMobile or showSidebar>
				<cfset numColumns = 1>
				<cfset loopCount = arrayLen(getPost)>
				<cfset cardWidth = "100">
				<cfset mainContainerWidth = 65>
				<cfset buttonWidth = "155px">
				<cfset renderMediumCard = true>
			<cfelse>
				<cfset numColumns = 3>
				<cfset loopCount = ceiling(arrayLen(getPost)/3)>
				<cfset cardWidth = "31">
				<cfset mainContainerWidth = 65>
				<cfset buttonWidth = "175px">
				<cfset renderMediumCard = false>
			</cfif>

			<!--- If it is not already defined, preset the URL page var --->
			<cfif not isDefined("URL.page")>
				<cfset URL.page = 0>
			</cfif>

			<!--- Create the label for the condensed view --->
			<cfif pageTypeId eq 21>
				<!--- Configure Homepage set to 2+ specific Pages (the multi-select homepage feature) - this shares
				blogContentHtml.cfm's rendering with the real "All Blogs" main listing (pageTypeId 1), but that
				generic label is wrong here since this is a curated, ad-hoc set of Pages, not the blog itself. Same
				name as the sidebar pod showing this same set (includes/templates/content/pods/homepagePages.cfm). --->
				<cfset condensedCardViewLabel = "Featured Pages">
			<cfelseif pageTypeId eq 20>
				<!--- A Page Collection's own page (eg. /docs-writing-and-editing-posts) also renders here, and fell through to
				getPageMode() eq 'blog' below - so its member pages were headed "All Blogs". Use the collection's own title. --->
				<cfset labelCollection = entityLoadByPK("PageCollection", homepageCollectionId)>
				<cfset condensedCardViewLabel = isObject(labelCollection) ? labelCollection.getTitle() : "Pages">
			<cfelseif getPageMode() eq 'category'>
				<!--- Get the category name and desc. --->
				<cfset getCategory = application.blog.getCategory(categoryId=URL.categoryId)>
				<cfset condensedCardViewLabel = getCategory[1]["Category"] & " related posts">
			<cfelseif getPageMode() eq 'postedBy'>
				<cfset condensedCardViewLabel = "Posts by " & replace(URL.authorName, "_", " ", "all")>
			<cfelseif getPageMode() eq 'day' or getPageMode() eq 'month' or getPageMode() eq 'year'>
				<cfif structKeyExists(URL, "month")>
					<cfset condensedCardViewLabel = monthAsString(URL.month)>
				</cfif>
				<cfif structKeyExists(URL, "day")>
					<cfset condensedCardViewLabel = condensedCardViewLabel & ' ' & URL.day>
				</cfif>
				<cfif structKeyExists(URL, "year")>
					<cfset condensedCardViewLabel = condensedCardViewLabel & ' ' & URL.year>
				</cfif>
				<cfset condensedCardViewLabel = "Posts made on " & condensedCardViewLabel>
			<cfelseif getPageMode() eq 'blog'>
				<cfset condensedCardViewLabel = "All Blogs">	
			<cfelse>
				<cfset condensedCardViewLabel = "">
			</cfif> 

			<!--- Determine the k-card class- when the cards are in a row, use k-card-deck, when each card is in a single column, use k-card-list. --->
			<cfif not showSidebar>
				<cfset kCardClass = "k-card-deck"><!--- 3x3 card grid --->
			<cfelse>
				<cfset kCardClass = "k-card-list"><!--- one card per row --->
			</cfif>

			<!--- ********************************************************************************************
				Render card output
			**********************************************************************************************--->
			</cfsilent>
			<!--- Page Collection breadcrumb: a single Collection shows Home > Blog > Collection, the same way a category archive shows its category. --->
			<cfif pageTypeId eq 20 and not session.isMobile>
				<cfset breadcrumbCollection = entityLoadByPK("PageCollection", homepageCollectionId)>
				<div class="k-content" style="padding:5px; width: 100%;">
				<nav>
					<ol class="cd-breadcrumb triangle">
						<li><a href="<cfoutput>#application.parentSiteLink#</cfoutput>" aria-label="Home"><i class="fas fa-house" style="alignment-baseline:middle;"></i></a></li>
						<li><a href="<cfoutput>#application.blogHostUrl#</cfoutput>" aria-label="Blog">Blog</a></li>
						<li class="current"><a href="<cfoutput>#application.blog.makeCollectionLink(homepageCollectionId)#</cfoutput>" class="k-content"><cfoutput>#breadcrumbCollection.getTitle()#</cfoutput></a></li>
					</ol>
				</nav>
				</div>
			</cfif>
			<cfif getPageMode() eq 'category' and not session.isMobile>
				<!--- Get the all of the parent categories. Unlike the rest of the blog, this returns a regular ColdFusion query object as it was easy to create within the function to return all of the parent categories. --->
				<cfset getParentCategories = application.blog.getParentCategoryQuery(URL.categoryId)>
				<!--- Category Breadcrumb Navigation --->
				<div class="k-content" style="padding:5px; width: 100%;">
				<nav>
					<ol class="cd-breadcrumb triangle">
						<li><a href="<cfoutput>#application.parentSiteLink#</cfoutput>" aria-label="Home"><i class="fas fa-house" style="alignment-baseline:middle;"></i></a></li>
						<li><a href="<cfoutput>#application.blogHostUrl#</cfoutput>" aria-label="Blog">Blog</a></li>
						<cfoutput query="getParentCategories">
						<cfif getParentCategories.recordcount>
						<li><a href="#CategoryLink#" aria-label="#CategoryLink#" class="k-content" aria-label="Blog Category">#category#</a></li>
						<cfelse>
						<li class="current"><a href="#categoryLink#" aria-label="#categoryLink#" class="k-content" aria-label="Blog Category">#category#</a></li>
						</cfif>	
						</cfoutput>
					</ol>
				</nav>
				</div>
			</cfif><!---<cfif getPageMode() eq 'category' and not session.isMobile>--->
				<h1 class="topContent" <cfif darkTheme>style="color:ivory"</cfif>><cfoutput>#condensedCardViewLabel#</cfoutput></h1>
			<cfloop from="1" to="#loopCount#" index="i">
				<div id="cardContainer" style="width: 100%">
					<div class="<cfoutput>#kCardClass#</cfoutput>" style="width:100%">
						<cfinclude template="#application.baseUrl#/includes/templates/renderKendoCardGrid.cfm">
						<cfif not showSidebar>
							<cfinclude template="#application.baseUrl#/includes/templates/renderKendoCardGrid.cfm">
							<cfinclude template="#application.baseUrl#/includes/templates/renderKendoCardGrid.cfm">
						</cfif>
					</div><!---<div class="k-card-deck" style="width:100%">--->	
				</div><!---<div id="cardContainer" style="width: 100%">--->	
			</cfloop>
			<br/><!-- Give an extra space between the cards and pagination --->
			<!--- End Card Cache --->
		<cfelse><!---<cfif condensedGridView>--->	
			<cfsilent>
			<!--- ********************************************************************************************
				Handle complete posts
			**********************************************************************************************--->
			</cfsilent>	
			<!--- Loop through the array --->
			<cfloop from="1" to="#arrayLen(getPost)#" index="i">
				<cfsilent>
				<!--- Set the variable values. I want to shorten the long variable names here. --->
				<cfset postId = getPost[i]["PostId"]>
				<!--- Read here, not where it is used: the Related Posts/Tags/etc. loops further down reuse i as their own index, so getPost[i] is no longer this post by then. --->
				<cfset postIsPage = getPost[i]["IsPage"]>
				<cfset postAlias = getPost[i]["PostAlias"]>
				<cfset postUuid = getPost[i]["PostUuid"]>
				<cfset themeId = getPost[i]["ThemeRef"]>
				<cfset promotedPost = getPost[i]["Promoted"]>
				<cfset title = getPost[i]["Title"]>
				<!---<cfset description = getPost[i]["Description"]>--->
				<cfset postHeader = getPost[i]["PostHeader"]>
				<cfset body = getPost[i]["Body"]>
				<cfset userId = getPost[i]["UserId"]>
				<cfset email = getPost[i]["Email"]>
				<cfset fullName = getPost[i]["FullName"]>
				<cfset displayName = getPost[i]["DisplayName"]>
				<!--- Media (videos and images) --->
				<cfset mediaType = getPost[1]["MediaType"]>
				<!--- The mime type may not be available when using external sources due to forbidden errors when trying to read the file. --->
				<cfset mimeType = getPost[i]["MimeType"]>
				<cfset mediaHeight = getPost[i]["MediaHeight"]>
				<cfset mediaPath = getPost[i]["MediaPath"]>
				<cfset mediaTitle = getPost[i]["MediaTitle"]>
				<cfset mediaUrl = getPost[i]["MediaUrl"]>
				<cfset mediaWidth = getPost[i]["MediaWidth"]>
				<!--- We need the providers video id (i.e. the YouTube or Vimeo video Id.) This is captured when creating or updating the enclosure --->
				<cfset providerVideoId = getPost[i]["ProviderVideoId"]>
				<cfset moreBody = getPost[i]["MoreBody"]>
				<cfset allowComment = getPost[i]["AllowComment"]>
				<cfset released = getPost[i]["Released"]>
				<cfset mailed = getPost[i]["Mailed"]>
				<cfset numViews = getPost[i]["NumViews"]>
				<cfset datePosted = getPost[i]["DatePosted"]>
				<!--- Set the enclosureMapIdList. We only need to get the value of the first item in the list as all of the values are the same --->
				<cfset enclosureMapIdList = getPost[1]["EnclosureMapIdList"]>
				<!--- Get the map Id of the current row in the list. --->
				<cfset enclosureMapId = getPost[i]["EnclosureMapId"]>
				<!--- Get the enclosure carousel --->
				<cfset enclosureCarouselId = getPost[i]["EnclosureCarouselId"]>

				<!--- Parent link logic- if the parent site is specified in the admin site, link it to the home button. Otherwise, link to the blog. --->
				<cfif len(application.parentSiteLink)>
					<cfset parentSite = true>
					<cfset parentLink = application.parentSiteLink>
					<cfset parentLabel = application.parentSiteName>
					<cfset parentLoopIndex = 2>
				<cfelse>
					<cfset parentSite = false>
					<cfset parentLink = application.blogHostUrl>
					<cfset parentLabel = application.BlogDbObj.getBlogTitle()>
					<cfset parentLoopIndex = 1>
				</cfif>

				<!--- Get the categories for this post. --->
				<cfset getCategories = application.blog.getCategoriesByPostId(getPost[i]["PostId"])>
				<!--- Parent categories first (2026-10-15), so the breadcrumb and its structured data read eg. Tech > Uppy instead of
				Uppy > Tech, and getCategories[1] below really is the top level; categories on the same level keep their order. A
				simple insertion sort on CategorySubLevel, which is stable (arraySort isn't guaranteed to be). Its own loop
				variables, as i is this post loop's counter. --->
				<cfloop from="2" to="#arrayLen(getCategories)#" index="categorySortIndex">
					<cfset categorySortItem = getCategories[categorySortIndex]>
					<cfset categorySortLevel = structKeyExists(categorySortItem, "CategorySubLevel") ? val(categorySortItem["CategorySubLevel"]) : 0>
					<cfset categorySortPosition = categorySortIndex - 1>
					<cfloop condition="categorySortPosition gte 1 and (structKeyExists(getCategories[categorySortPosition], 'CategorySubLevel') ? val(getCategories[categorySortPosition]['CategorySubLevel']) : 0) gt categorySortLevel">
						<cfset getCategories[categorySortPosition + 1] = getCategories[categorySortPosition]>
						<cfset categorySortPosition = categorySortPosition - 1>
					</cfloop>
					<cfset getCategories[categorySortPosition + 1] = categorySortItem>
				</cfloop>
				<!--- Get the top level category in the hiearchy --->
				<cfif arrayLen(getCategories)>
					<cfset parentCategory = getCategories[1]["Category"]>
				<cfelse>
					<cfset parentCategory = ""/>
				</cfif>
				<!--- Get the tags for this post. --->
				<cfset getTags = application.blog.getTagsByPostId(postId)>

				<!--- Get the comment count for this post. --->
				<cfset commentCount = application.blog.getCommentCountByPostId(postId)>
				<!--- Get the post link. The makeLink function will be used within the makeLink function for server side rewrite rules --->
				<!--- Create the link --->
				<cfset postLink = application.blog.makeLink(
					isPage=getPost[i]["IsPage"], 
					postAlias=getPost[i]["PostAlias"], 
					datePosted=getPost[i]["DatePosted"])>
				<!--- We need to perform the same logic for the post author (remove the 'index.cfm' string when a rewrite rule is in place). --->
				<cfset userLink = application.blog.makeUserLink(getPost[i]["FullName"])>
				<!--- Render the post. This will render cfinclude and video directives if present, the encosure and the body. --->
				<cfset post = RendererObj.renderPost(kendoTheme,getPost,i,(getPageMode() eq 'post'))>
				<!--- Get the post content --->
				<cfset postContent = RendererObj.renderBody(body, mediaPath, getPageMode())>

				<!--- Cache the post html to disk using my new GalaxieCache custom tag. The post will be cached permently unless the post has been editted. --->

				<!--- Set the cache name. The +noAnimation suffix matters even for a post that doesn't use the
				'animation' fallback mode at all: without it, this same postId+themeId cache file would be shared
				by every page mode that renders a full post through this loop (the post's own permalink AND the
				blog roll/category/postedBy/month listings that also render full posts here) - whichever mode
				rendered a given post first would "win" the cache for every other mode until the post is next
				edited. A post viewed first via a listing would cache without its live animation and then never
				show it on the permalink page; a post viewed first via its permalink would cache WITH a live
				canvas that then shows up inside a multi-post listing - exactly the "more than one live animation
				on a page" outcome the whole feature exists to prevent. Same idiom the existing +mobile suffix
				already uses to partition this cache by device. 2026-10-03: renamed from +noVanta/vantaEligible
				while still dev-only/unmigrated. --->
				<cfset animationEligible = (getPageMode() eq 'post' and not session.isMobile)>
				<cfif session.isMobile>
					<cfset cacheName = 'postId=' & getPost[1]["PostId"] & '+themeId=' & themeId & '+mobile'>
				<cfelse>
					<cfset cacheName = 'postId=' & getPost[1]["PostId"] & '+themeId=' & themeId & (animationEligible ? '' : '+noAnimation')>
				</cfif>
				<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. This can't be in a cfsilent block --->
				</cfsilent>
				<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/posts/#cacheName#.cfm" debug="false" disabled="#disableCache#">
				<cfsilent>		
				<!--- For desktop clients, handle multiple maps on a page. If there are multiple maps, we need to create a script that will load all of the maps at the top of the page. If we are using a mobile device and there are multiple maps- we will use an iframe to display the map. --->
				<cfif not session.isMobile and i eq 1 and listLen(enclosureMapIdList) gt 1>
					<!--- Invoke the renderLoadMapScript function --->
					<cfinvoke component="#RendererObj#" method="renderLoadMapScript" returnvariable="loadMapScript">
						<cfinvokeargument name="kendoTheme" value="#kendoTheme#">
						<cfinvokeargument name="enclosureMapIdList" value="#enclosureMapIdList#">
						<cfinvokeargument name="currentRow" value="#i#">
					</cfinvoke>
				<cfelse>
					<cfset loadMapScript = ''>
				</cfif>
				</cfsilent>
				<cfoutput>
			<cfif len(loadMapScript)><!-- Load the javascript to handle multiple maps on one page -->
				#loadMapScript#
			</cfif>
				<!--- Breadcrumb LD-Json. 2026-10-15: built from a list and escaped, instead of written by hand. The hand-written version
				always printed "},{" after the first item, so a post or page without categories (most pages) ended with an empty {}
				in itemListElement - Google Search Console: "Invalid object type for field itemListElement". Names weren't escaped
				either (a quote in a category name broke the JSON) and positions could skip or repeat. It now follows the visible
				breadcrumb below: home, the page's collections (a page) or Blog (a post, when there is a parent site), the
				categories, then this post or page. --->
				<cfsilent>
				<cfset crumbList = [ { name: parentLabel, url: parentLink } ]>
				<cfif isPageMode()>
					<cfloop array="#application.blog.getPageCollectionsForPost(postId)#" index="crumbCollection">
						<cfset arrayAppend(crumbList, { name: crumbCollection.title, url: application.blog.makeCollectionLink(crumbCollection.pageCollectionId) })>
					</cfloop>
				<cfelseif parentSite>
					<cfset arrayAppend(crumbList, { name: "Blog", url: application.blogHostUrl })>
				</cfif>
				<cfloop from="1" to="#arrayLen(getCategories)#" index="crumbIndex">
					<cfset arrayAppend(crumbList, { name: getCategories[crumbIndex]["Category"], url: application.blog.makeCategoryLink(getCategories[crumbIndex]["CategoryId"]) })>
				</cfloop>
				<cfset arrayAppend(crumbList, { name: title, url: postLink })>
				<cfset crumbJson = "">
				<cfloop from="1" to="#arrayLen(crumbList)#" index="crumbIndex">
					<!--- JSON strings by hand: serializeJSON would turn a name such as "2024" into a number on Adobe ColdFusion. --->
					<cfset crumbName = replace(replace(replace(reReplace(crumbList[crumbIndex].name, "[\x00-\x1F]", " ", "all"), "\", "\\", "all"), '"', '\"', "all"), "</", "<\/", "all")>
					<cfset crumbUrl = replace(replace(replace(reReplace(crumbList[crumbIndex].url, "[\x00-\x1F]", "", "all"), "\", "\\", "all"), '"', '\"', "all"), "</", "<\/", "all")>
					<cfset crumbJson = crumbJson & (crumbIndex gt 1 ? "," : "") & '{"@type":"ListItem","position":' & crumbIndex & ',"name":"' & crumbName & '","item":"' & crumbUrl & '"}'>
				</cfloop>
				</cfsilent>
				<script type="application/ld+json">{"@context":"https://schema.org","@type":"BreadcrumbList","itemListElement":[#crumbJson#]}</script>
				<!-- Render the article for postId <cfoutput>#postId#</cfoutput> -->
				<!--- data-postid: a form placed in the post sends it with each submission (common/js/webForms.js, 2026-10-13). --->
				<article data-postid="<cfoutput>#postId#</cfoutput>">
					<div class="blogPost <cfif promotedPost>highlightedWidget<cfelse>widget</cfif> k-content"><!--- Highlight the post with the themes accent color if it is promoted. --->
						<span class="innerContentContainer">
							<h1 class="topContent">
							<!--- Don't show the link in the title when looking at an individual post. --->
							<cfif getPageMode() eq 'post'>
								#title# 
							<cfelse>
								<a href="#postLink#" aria-label="#title#" class="k-content">#title#</a> 
							</cfif>
							<cfif promotedPost>&nbsp;<i class="fa fa-bullhorn" aria-hidden="true" style="font-size: 14pt" title="Announcement"></i></cfif>
							</h1>
							<cfsilent><!--- Debugging: currentRow(i): #i# arrayLen(getPost): #arrayLen(getPost)# postId: #postId#<br/>---></cfsilent>
						<cfif session.isMobile>
							<!--- The postDate is not displayed for pages --->
							<cfif !isPageMode()>
							<p class="postDate">
								<!--- We are getting the accent color to set the color in the month class instead of using Kendo's 'k-primary' class to render the primary accent color background. This is a change that I implemented chasing a perfect Google Lighthouse Score (background and foreground contrast issue ) --->
								<span class="month">#dateFormat(datePosted, "mmm")#</span>
								<span class="day k-alt">#day(datePosted)#</span>
							</p>
							</cfif><!---<cfif isPageMode()>--->
							<p class="postAuthor">
								<span class="info">
									<cfif len(fullName)>by <a href="#userLink#" aria-label="#userLink#" class="k-content"><cfif len(displayName)>#displayName#<cfelse>#fullName#</cfif></a></cfif>
									<!--- Loop through the categories array. --->
									<cfloop from="1" to="#arrayLen(getCategories)#" index="i">
										<cfsilent>
										<cfset category = getCategories[i]["Category"]>
										<cfset categoryId = getCategories[i]["CategoryId"]>
										<cfset categoryLink = application.blog.makeCategoryLink(CategoryId)>
										</cfsilent>
										<a href="#categoryLink#" aria-label="#categoryLink#" class="k-content">#category#</a><cfif i lt arrayLen(getCategories)> > </cfif> 
									</cfloop>
								</span>
							</p>
						<cfelse><!---<cfif session.isMobile>--->
							<cfsilent>
							<!--- ********************************************************************************************
								Breadcrumbs 
							**********************************************************************************************--->
							</cfsilent>
							<table cellpadding="0" cellspacing="0">
								<tr>
								<!--- The postDate is not displayed for pages --->
								<cfif !isPageMode()>
									<td style="vertical-align: top">
										<p class="postDate">
											<!--- We are getting the accent color to set the color in the month class instead of using Kendo's 'k-primary' class to render the primary accent color background. This is a change that I implemented chasing a perfect Google Lighthouse Score (background and foreground contrast issue ) --->
											<span class="month">#dateFormat(datePosted, "mmm")#</span>
											<span class="day k-alt">#day(datePosted)#</span>
										</p>
									</td>
									<td width="20"></td>
								</cfif><!---<cfif isPageMode()>--->
									<td>
										<nav>
											<ol class="cd-breadcrumb triangle">
												<li><a href="<cfoutput>#parentLink#</cfoutput>" aria-label="Home"><i class="fas fa-house" style="alignment-baseline:middle;"></i></a></li>
											<!--- Page Collection crumbs: a page that belongs to a Collection shows it, the same way a post shows its categories. --->
<cfif isPageMode()>
	<cfset pageCollectionCrumbs = application.blog.getPageCollectionsForPost(postId)>
	<cfloop from="1" to="#arrayLen(pageCollectionCrumbs)#" index="pcIndex">
		<li class="<cfif arrayLen(getCategories) eq 0 and pcIndex eq arrayLen(pageCollectionCrumbs)>current</cfif>"><a href="<cfoutput>#application.blog.makeCollectionLink(pageCollectionCrumbs[pcIndex].pageCollectionId)#</cfoutput>" aria-label="<cfoutput>#pageCollectionCrumbs[pcIndex].title#</cfoutput>" class="k-content"><cfoutput>#pageCollectionCrumbs[pcIndex].title#</cfoutput></a></li>
	</cfloop>
</cfif>
											<cfif parentSite and !isPageMode()>
												<li><a href="<cfoutput>#application.blogHostUrl#</cfoutput>"  aria-label="Blog">Blog</a></li>
											</cfif>
												<cfloop from="1" to="#arrayLen(getCategories)#" index="i">
												<cfsilent>
												<cfset category = getCategories[i]["Category"]>
												<cfset categoryId = getCategories[i]["CategoryId"]>
												<cfset categoryLink = application.blog.makeCategoryLink(categoryId)>
												</cfsilent>
												<cfif i lt arrayLen(getCategories)>
												<li><a href="#categoryLink#" aria-label="#categoryLink#" class="k-content">#category#</a></li>
												<cfelse>
												<li class="current"><a href="#categoryLink#" aria-label="#categoryLink#" class="k-content">#category#</a></li>
												</cfif>	
												</cfloop>
											</ol>
										</nav>
									</td>
								</tr>
							</table>
							<p class="postAuthor">
								<span class="info">
									<cfif len(fullName)>by <a href="#userLink#" aria-label="#userLink#" class="k-content"><cfif len(displayName)>#displayName#<cfelse>#fullName#</cfif></a></cfif>
								</span>
							</p>							
						</cfif><!---<cfif session.isMobile>--->
							<!-- Post content --> 
							<span class="postContent">	
								<cfsilent>
								<!--- ********************************************************************************************
											Render the post. 
								**********************************************************************************************--->
								</cfsilent>
								<!--- The event card (2026-10-15), when the post is an event: date, where, Add to calendar (common/cfc/Events.cfc renderCard). --->
								<cfif getPageMode() eq 'post' and structKeyExists(application, "events")>#application.events.renderCard(postId, title, postLink)#</cfif>
								#post#	
								<!--- If the more tag exists and we are not looking at a page, summarize the content (done when we set the postContent in logic above) and render a button to get to the full post. --->
							<cfif len(morebody)>
								<!--- Show a button in single page mode --->
								<cfif getPageMode() neq 'post'>
									<button type="button" class="k-button" style="width:225px; font-size:0.875em;" onClick="location.href='#postLink###more';">
										<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
										<i class="fas fa-chevron-circle-down" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Continue Reading...
									</button>
								<cfelse>
									<!--- Show the more body in addition to the post --->
									#moreBody#
								</cfif>
							</cfif><!---<cfif len(morebody)>--->
							<!--- Forms assigned to this post under "Show on" in the form editor (2026-10-13): the form, its sign-up list or both,
							below the post's text. Only placeholders are written here, as the page is cached; common/js/webForms.js fetches them. --->
							<cfif getPageMode() eq 'post' and structKeyExists(application, "webForms")>
								<cfloop array="#application.webForms.getPlacementsForPost(postId)#" index="webFormPlacement">
									<cfif webFormPlacement.showForm><div class="galaxieWebForm" data-webform="#encodeForHtmlAttribute(webFormPlacement.alias)#"></div></cfif>
									<cfif webFormPlacement.showList><div class="galaxieWebFormList" data-webform="#encodeForHtmlAttribute(webFormPlacement.alias)#"></div></cfif>
								</cfloop>
							</cfif>
							</span><!--<span class="postContent">-->
							<cfsilent>
							<!--- ********************************************************************************************
								Like/Dislike
							**********************************************************************************************--->
							</cfsilent>
							<cfif getPageMode() eq 'post' and application.logVisitors>
								<cfsilent>
								<!--- Note: this is inside of the post cache, so the html is shared by all visitors. Nothing that belongs to a visitor (their vote, the totals or their anonymous user id) can be output here, or every visitor would see and change the votes of whoever viewed the post first. The totals and the visitor's vote are requested after the page loads (see getPostReactionState in ProxyController.cfc). --->
								<!--- Set the class for the vote buttons. The Kendo primary class indicates how the visitor voted. Otherwise, use muted buttons --->
								<!--- Like classes --->
								<cfset likeButtonClassSelected = 'k-icon k-primary btn btn-default like'>
								<cfset likeButtonClassUnselected = 'k-icon k-alt btn btn-default like likeOutline'>
								<!--- Dislike classes --->
								<cfset dislikeButtonClassSelected = 'k-icon k-primary btn btn-default dislike'>
								<cfset dislikeButtonClassUnselected = 'k-icon k-alt btn btn-default dislike dislikeOutline'>
								</cfsilent>

								<h2 class="topContent">Reactions</h2>
								<script>
									<!--- Reactions. The user can like or dislike a post and can change their mind, but cannot remove a vote. The post html is cached and shared by all visitors, so it can't contain the totals or the visitor's vote. They are requested after the page loads, and the server identifies the visitor with the gauid cookie. --->
									$(document).ready(function(){
										var $rating = $('#chr(35)#rating');
										var $likeButton = $('#chr(35)#likeButton');
										var $dislikeButton = $('#chr(35)#dislikeButton');
										<!--- My current vote: 'like', 'dislike' or '' if I have not voted yet, and the totals of all visitors (which include my vote). --->
										var myVote = '';
										var totalLikes = 0;
										var totalDislikes = 0;
										var busy = false;

										<!--- The Kendo primary class shows how I voted. --->
										var classes = {
											likeSelected: '<cfoutput>#likeButtonClassSelected#</cfoutput>',
											likeUnselected: '<cfoutput>#likeButtonClassUnselected#</cfoutput>',
											dislikeSelected: '<cfoutput>#dislikeButtonClassSelected#</cfoutput>',
											dislikeUnselected: '<cfoutput>#dislikeButtonClassUnselected#</cfoutput>'
										};

										function showVote() {
											$likeButton.attr('class', myVote === 'like' ? classes.likeSelected : classes.likeUnselected);
											$dislikeButton.attr('class', myVote === 'dislike' ? classes.dislikeSelected : classes.dislikeUnselected);
											$rating.find('.likes').text(totalLikes);
											$rating.find('.dislikes').text(totalDislikes);
										}

										<!--- Get the totals and how this visitor voted. This can't be cached, so it always asks the server. --->
										function loadReactions() {
											$.ajax({
												type: 'post',
												url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=getPostReactionState",
												data: { postId: '<cfoutput>#postId#</cfoutput>' },
												dataType: "json",
												cache: false
											}).done(function(data) {
												if (data) {
													totalLikes = parseInt(data.likes, 10) || 0;
													totalDislikes = parseInt(data.dislikes, 10) || 0;
													myVote = (data.myVote === 'like' || data.myVote === 'dislike') ? data.myVote : '';
													showVote();
												}
											});
										}

										function react(choice) {
											<!--- Ignore clicks when I have already voted this way or the last vote is still being saved. --->
											if (busy || choice === myVote) return;
											busy = true;
											$.ajax({
												type: 'post',
												<!--- This posts to the proxy controller as it needs to have session vars. The server knows who is voting from the gauid cookie. --->
												url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=saveReaction",
												data: {
													postId: '<cfoutput>#postId#</cfoutput>',
													selectedId: choice
												},
												dataType: "json",
												cache: false
											}).done(function(data) {
												<!--- The server returns [{like: 1, dislike: 0}] or [{like: 0, dislike: 1}], or zeros if the vote was not saved. --->
												if (data && data.length && (data[0].like == 1 || data[0].dislike == 1)) {
													<!--- Take my previous vote out of the totals and add the new one. --->
													if (myVote === 'like') totalLikes--;
													if (myVote === 'dislike') totalDislikes--;
													myVote = data[0].like == 1 ? 'like' : 'dislike';
													if (myVote === 'like') totalLikes++; else totalDislikes++;
													showVote();
												}
											}).always(function() {
												busy = false;
											});
										}

										<!--- Use the button (the circle) and not just the small icon inside of it. Both buttons are also reachable with the keyboard. --->
										$likeButton.attr({ role: 'button', tabindex: 0, 'aria-label': 'Like this post' });
										$dislikeButton.attr({ role: 'button', tabindex: 0, 'aria-label': 'Dislike this post' });
										$likeButton.on('click', function() { react('like'); });
										$dislikeButton.on('click', function() { react('dislike'); });
										$rating.on('keydown', '[role=button]', function(e) {
											if (e.which === 13 || e.which === 32) {
												e.preventDefault();
												$(this).trigger('click');
											}
										});

										loadReactions();
									});
								</script>

								<style>
									.dislike {
										<!--- Step 1: Make the button a perfect circle --->
										width: 40px;
										height: 40px;
										border-radius: 50%;
										display: flex;
										justify-content: center; /* Centers horizontally */
										align-items: center;     /* Centers vertically */
										font-size: 16pt;
									}

									.like {
										<!--- Step 1: Make the button a perfect circle --->
										width: 40px;
										height: 40px;
										border-radius: 50%;
										display: flex;
										justify-content: center; /* Centers horizontally */
										align-items: center;     /* Centers vertically */
										font-size: 16pt;
									}
									
									.dislikeOutline {
										outline: 1px solid orange;
									}

									.likeOutline {
										outline: 1px solid green;
									}

								</style>
								<div class="rating" id="rating">
									<!-- I need a table to align the buttons properly and remove the page break -->
									<table align="left" class="k-content" width="200px" cellpadding="5" cellspacing="0" border="0">
										<tr>
											<td width="25%">
												<span id="likeButton" class="<cfoutput>#likeButtonClassUnselected#</cfoutput>"><i id="like" class="far fa-thumbs-up"></i></span>
											</td>
											<td>
												<span class="likes">&nbsp;</span>
											</td>
											<td width="25%">
												<span id="dislikeButton" class="<cfoutput>#dislikeButtonClassUnselected#</cfoutput>"><i id="dislike" class="far fa-thumbs-down"></i></span>
											</td>
											<td>
												<span class="dislikes">&nbsp;</span>
											</td>
										</tr>
									</table>
								</div><br/><br/>
								<h3 class="topContent"></h3>
							</cfif>
							<cfsilent>
							<!--- ********************************************************************************************
								Related entries
							**********************************************************************************************--->
							</cfsilent>
							<cfset getRelatedPosts = application.blog.getRelatedPosts(postId=postId) />	
							<!---<cfdump var="#getRelatedPosts#">--->
							<cfif arrayLen(getRelatedPosts)>
								<cfset postIdList = ""/>
								<cfloop from="1" to="#arrayLen(getRelatedPosts)#" index="i">
									<cfset postIdList = listAppend(postIdList, getRelatedPosts[i]["PostId"])>
								</cfloop>

								<cfinvoke component="#application.blog#" method="getPost" returnvariable="getPosts">
									<!--- Show both layers and pages --->
									<cfinvokeargument name="showPages" value="true">
									<cfinvokeargument name="showBlogPosts" value="true">
									<cfinvokeargument name="showPendingPosts" value="false">
									<cfinvokeargument name="showRemovedPosts" value="false">
									<cfinvokeargument name="showJsonLd" value="false">
									<cfinvokeargument name="showPromoteAtTopOfQuery" value="false">
									<!--- Send the postId's to be shown --->
									<cfinvokeargument name="postIdList" value="#postIdList#">
								</cfinvoke>
								<cfset postScrollWidgetType = "Related Blogs">
								<cfinclude template="popularPosts.cfm">

							</cfif>
							<cfsilent>
							<!--- ********************************************************************************************
								Related Pages - Pages only. Unlike the manually-curated Related Posts above, this is
								sourced automatically from Page Collection membership (see getRelatedPagesByCollection()
								in blog.cfc) - a Page in no Collection simply shows nothing here, no fallback.
							**********************************************************************************************--->
							</cfsilent>
							<cfif postIsPage>
								<cfset getRelatedPages = application.blog.getRelatedPagesByCollection(postId=postId) />
								<cfif arrayLen(getRelatedPages)>
									<cfset postIdList = ""/>
									<cfloop from="1" to="#arrayLen(getRelatedPages)#" index="i">
										<cfset postIdList = listAppend(postIdList, getRelatedPages[i]["PostId"])>
									</cfloop>

									<cfinvoke component="#application.blog#" method="getPost" returnvariable="getPosts">
										<!--- Show both layers and pages --->
										<cfinvokeargument name="showPages" value="true">
										<cfinvokeargument name="showBlogPosts" value="true">
										<cfinvokeargument name="showPendingPosts" value="false">
										<cfinvokeargument name="showRemovedPosts" value="false">
										<cfinvokeargument name="showJsonLd" value="false">
										<cfinvokeargument name="showPromoteAtTopOfQuery" value="false">
										<!--- Send the postId's to be shown --->
										<cfinvokeargument name="postIdList" value="#postIdList#">
									</cfinvoke>
									<cfset postScrollWidgetType = "Related Pages">
									<cfinclude template="popularPosts.cfm">

								</cfif>
							</cfif>
							<cfsilent>
							<!--- ********************************************************************************************
								Tags
							**********************************************************************************************--->
							</cfsilent>
						<cfif arrayLen(getTags)>
							<h2 class="topContent">Tags</h2>
							<span>
								<!--- Loop through the tags array. --->
								<cfloop from="1" to="#arrayLen(getTags)#" index="i">
									<cfsilent>
									<cfset tag = getTags[i]["Tag"]>
									<cfset tagId = getTags[i]["TagId"]>
									<cfset tagLink = application.blog.makeTagLink(tagId)>
									</cfsilent>
									<a href="#tagLink#" aria-label="#tagLink#" class="k-content" rel="noindex,nofollow">#tag#</a><cfif i lt arrayLen(getTags)>, </cfif> 
								</cfloop>
							</span>	
							<h3 class="topContent"></h3>
						</cfif><!---<cfif arrayLen(getTags)>--->
						</cfoutput>
						</cfmodule><!--- End Post Cache --->
						<cfsilent>
						<cfif getPageMode() eq 'post' and application.logVisitors>
							<!--- Log that the post has been read --->
							<cftry>
								<cfif isDefined("AnonymousUserDbObj")>
									<cfset logPostRead = application.blog.logPostRead(postId=postId,AnonymousUserDbObj=AnonymousUserDbObj)>
								<cfelse>
									<cfset logPostRead = application.blog.logPostRead(postId=postId)>
								</cfif>
								<cfcatch type="any">
									<!--- Do nothing --->
								</cfcatch>
							</cftry>
						</cfif>
						<!--- ********************************************************************************************
							Author Bio
						**********************************************************************************************--->
						<!--- Get the author from the user table --->
						<cfset authorData = application.blog.getUser(userId=userId, includeSecurityCredentials=false)>

						<!--- Set the cache name --->
						<cfif session.isMobile>
							<cfset cacheName = 'bioUserId=' & userId & '+themeId=' & themeId & '+mobile'>
						<cfelse>
							<cfset cacheName = 'bioUserId=' & userId & '+themeId=' & themeId>
						</cfif> 
						<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. This can't be in a cfsilent block --->
						</cfsilent>
						<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/bio/#cacheName#.cfm" debug="false" disabled="#disableCache#">
						<cfoutput>
						<!---<cfdump var="#authorData#">--->
						<!--- Guard against an empty authorData: getUser() can come back with no row (for example, a userId that does not resolve the way it usually does when a post is reached through the pageTypeId=9 custom-page path rather than its own URL), and authorData[1] would otherwise raise an error here. --->
						<cfif arrayLen(authorData) and len( authorData[1]["Biography"] ) >
							<table align="center" class="k-content" width="100%" cellpadding="0" cellspacing="0" border="0">
								<tr>
									<td width="100">
										<img src="<cfoutput>#authorData[1]['ProfilePicture']#</cfoutput>" title="<cfoutput>#authorData[1]['FullName']#</cfoutput> Profile" alt="<cfoutput>#authorData[1]['FullName']#</cfoutput> Profile" border="0" class="avatar avatar-64 photo" height="85" width="85" align="left">
									</td>
									<td>
										<div class="author-bio k-content flexItem">
											<h3 class="topContent"><cfoutput>#authorData[1]['FullName']#</cfoutput></h3>
										</div>
										<div class="author-bio k-content flexItem">
										<cfif structKeyExists(authorData[1], "FacebookUrl") and len(authorData[1]['FacebookUrl'])>
											<a href="<cfoutput>#authorData[1]['FacebookUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['FacebookUrl']#</cfoutput>" class="k-content"><button id="facebookUrl" aria-label="facebook" class="k-button" style="#kendoIconButtonStyle#">
												&nbsp;<i class="fa-brands fa-facebook"></i>&nbsp;
											</button></a>
										</cfif><cfif structKeyExists(authorData[1], "LinkedInUrl") and len(authorData[1]['LinkedInUrl'])>
											<a href="<cfoutput>#authorData[1]['LinkedInUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['LinkedInUrl']#</cfoutput>" class="k-content"><button id="linkedInUrl" aria-label="linkedIn" class="k-button" style="#kendoIconButtonStyle#">
												&nbsp;<i class="fa-brands fa-linkedin"></i>&nbsp;
											</button></a>
										</cfif><cfif structKeyExists(authorData[1], "InstagramUrl") and len(authorData[1]['InstagramUrl'])>
											<a href="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" class="k-content"><button id="instagramUrl" aria-label="instagram" class="k-button" style="#kendoIconButtonStyle#">
												&nbsp;<i class="fa-brands fa-instagram"></i>&nbsp;
											</button></a>
										</cfif><cfif structKeyExists(authorData[1], "TwitterUrl") and len(authorData[1]['InstagramUrl'])>
											<a href="<cfoutput>#authorData[1]['TwitterUrl']#</cfoutput>" aria-label="<cfoutput>#authorData[1]['InstagramUrl']#</cfoutput>" class="k-content"><button id="twitterUrl" aria-label="twitter" class="k-button" style="#kendoIconButtonStyle#">
												&nbsp;<i class="fa-brands fa-twitter"></i>&nbsp;
											</button></a>
										</cfif><cfif structKeyExists(authorData[1], "DisplayEmailOnBio") and authorData[1]["DisplayEmailOnBio"]>
											<a href="mailto:<cfoutput>#authorData[1]['Email']#</cfoutput>" aria-label="mailto:<cfoutput>#authorData[1]['Email']#</cfoutput>" class="k-content"><button id="email" aria-label="email" class="k-button" style="#kendoIconButtonStyle#">
												&nbsp;<i class="fa-solid fa-envelope"></i>&nbsp;
											</button></a>
										</cfif>
										</div>
									</td>
								</tr>
								<tr>
									<td colspan="2">
										<cfoutput>#authorData[1]["Biography"]#</cfoutput>
									</td>
								</tr>
							</table>
							<h3 class="topContent"></h3>
						</cfif><!---<cfif len( authorData[1]["Biography"] ) >--->
						</cfoutput>	
						</cfmodule><!--- End Bio Cache --->
						<cfsilent>
						<!--- ********************************************************************************************
							Comment interfaces (Disqus and Galaxie Blog)
						**********************************************************************************************--->
							
						<!--- We will not show the comment interface at all if this is a page and if the user did not turn on commenting when saving the page  --->
						<cfif isPageMode()>
							<cfif allowComment>
								<cfset showCommentInterface = true>
							<cfelse>
								<cfset showCommentInterface = false>
							</cfif>
						<cfelse>
							<cfset showCommentInterface = true>
						</cfif>
								
						</cfsilent>
						<cfoutput>
						<cfif showCommentInterface>
						<!-- Button navigation. -->
						<!-- Set a smaller font in the kendo buttons. Note: adjusting the .k-button class alone also adjusts the k-input in the multi-select so we will set it here.-->
						<cfif allowComment>
							<cfif application.includeDisqus>
								<cfif URL.mode neq 'entry' and URL.mode neq 'alias'>
								<!-- The Disqus comment button should not be shown when in blog mode. -->
								<button id="disqusCommentButton" class="k-button" style="#kendoButtonStyle#" onClick="createDisqusWindow('#postId#', '#postAlias#', '#postLink#')">
									<i class="fas fa-comments" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Comment
								</button>
								</cfif>
							<cfelse>
								<button id="addCommentButton" class="k-button" style="#kendoButtonStyle#" onClick="createAddCommentSubscribeWindow('#postId#', 'addComment', #session.isMobile#)">
									<i class="fas fa-comments" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Comment
								</button>
							</cfif>
						</cfif><!---<cfif allowComment>--->
							<!--- The default comment subscribe interface won't work with Disqus --->
							<cfif not application.includeDisqus>
								<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="createAddCommentSubscribeWindow('#postId#', 'subscribe', #session.isMobile#)">
									<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
									<i class="fas fa-envelope-open-text" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Subscribe
								</button>
							</cfif>
								<p>This entry was posted on #dateFormat(datePosted, "mmmm d, yyyy")# at #timeFormat(datePosted, "h:mm tt")# and has received #numViews# views. </p>
						<cfif not application.includeDisqus> 
								<h3 class="topContent">Comments</h3>
								<p>There are <cfif commentCount is "">0<cfelse>#commentCount#</cfif> comments.</p> 
							<cfif not allowComment>
								<p>Comments are disabled.</p>
							</cfif>
							<!--- Span to hold the little arrow. Note: the order of the spans in the code are different than the actual display. We need to reverse the order for proper display. We are not going to display this if there are no comments. --->
							<cfif commentCount gt 0>
								<span id="commentControl#postId#" class="collapse k-icon k-i-sort-desc-sm k-primary" style="width: 35px; height:35px; border-radius: 50%;" onClick="handleComments()"></span>&nbsp;&nbsp;<span id="commentControlLabel#postId#">Show Comments</span><br/><br/>
							</cfif><!---<cfif len(commentCount) gt 0>--->
						</cfif><!---<cfif not application.includeDisqus>--->
							<cfsilent>
							<!--- ****************************************************************************************
								Disqus - load disqus if we are in looking at an individual entry
							******************************************************************************************--->
							</cfsilent>
							<cfif application.includeDisqus and (url.mode eq "alias" or URL.mode eq 'entry')>
								<div id="disqus_thread"></div>
								<script type="#application.blog.getScriptTypeString()#">
									<!--- RECOMMENDED CONFIGURATION VARIABLES: EDIT AND UNCOMMENT THE SECTION BELOW TO INSERT DYNAMIC VALUES FROM YOUR PLATFORM OR CMS. LEARN WHY DEFINING THESE VARIABLES IS IMPORTANT: https://disqus.com/admin/universalcode/#chr(35)#configuration-variables --->
									<!--- var disqus_config = function () { var disqus_shortname = '#postAlias#'; this.page.url = #postLink#; // Replace PAGE_URL with your page's canonical URL variable this.page.identifier = #postId#; // Replace PAGE_IDENTIFIER with your page's unique identifier variable }; --->
									(function() { // don't EDIT BELOW THIS LINE
										var d = document, s = d.createElement('script');
										s.src = 'https://gregorys-blog.disqus.com/embed.js';
										s.setAttribute('data-timestamp', +new Date());
										(d.head || d.body).appendChild(s);
									})();
								</script>
							</cfif><!---<cfif application.includeDisqus and url.mode eq "alias">--->

							<cfsilent>
							<!--- ********************************************************************************************
								Original comments interface (non Disqus).
							**********************************************************************************************--->
							<!--- We will not show the comment interface at all if this is a page and if the user did not turn on commenting when saving the page  --->
							</cfsilent>
							<!---<cfdump var="#AnonymousUserDbObj#" label="AnonymousUserDbObj">--->
							<cfif len(commentCount) gt 0 and not application.includeDisqus>
								<cfsilent>
								<!--- Set the cache name --->
								<cfif session.isMobile>
									<cfset cacheName = 'commentPostId=' & postId & '+mobile'>
								<cfelse>
									<cfset cacheName = 'commentPostId=' & postId>
								</cfif> 
								<!--- galaxieCache will read content between the cfmodule tags (or a normal tag) and save the content to the file system. This can't be in a cfsilent block --->
								</cfsilent>
								<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cachename#" scope="html" file="#application.baseUrl#/cache/comments/#cacheName#.cfm" debug="false" disabled="#disableCache#">
								<!-- Comments that are shown when the user clicks on the arrow button to open the container. -->
								<div id="comment#postId#" class="widget k-content" style="display:none;"> 
									<table cellpadding="5" cellspacing="0" border="0" class="fixedCommentTable">
									 <tr width="100%">
									 <cftry>
									 <!--- Get the comments and loop through them. --->
									 <cfset comments = application.blog.getComments(postId)>
									 <cfparam name="commentLoopCount" default="1">
								<cfloop from="1" to="#arrayLen(comments)#" index="i">
									 <cfsilent>
									 <!--- Set the vars. --->
									 <cfset isPage = comments[i]["IsPage"]>
									 <cfset commentId = comments[i]["CommentId"]>
									 <cfset commentUuid = comments[i]["CommentUuid"]>
									 <cfset comment = comments[i]["Comment"]>
									 <!--- Visitors type the name and website, so both are encoded for the page; a website that isn't an
									 http(s) address is left out (2026-10-14). --->
									 <cfset commenterFullName = encodeForHtml(comments[i]["CommenterFullName"])>
									 <!--- This column may be null in the db --->
									 <cfif structKeyExists(comments[i],"CommenterEmail")>
										<cfset commenterEmail = comments[i]["CommenterEmail"]>
									 <cfelse>
										<cfset commenterEmail = "">
									 </cfif>
									 <!--- This column may be null in the db --->
									 <cfif structKeyExists(comments[i],"CommenterWebsite")>
										 <cfset commenterWebsite = reFindNoCase("^https?://[^\s""'<>]+$", trim(comments[i]["CommenterWebsite"])) ? encodeForHtmlAttribute(trim(comments[i]["CommenterWebsite"])) : "">
									 <cfelse>
										 <cfset commenterWebsite = "">
									 </cfif>
									 <cfset commentDatePosted = comments[i]["DatePosted"]>
									 <!--- Create the comment link --->
									 <cfset commentLink = application.blog.makeLink(
										isPage=comments[i]["IsPage"], 
										postAlias=comments[i]["PostAlias"], 
										datePosted=comments[i]["DatePosted"],
										commentId=comments[i]["CommentId"])>
									 </cfsilent>
									 <!--- Note: the URL is appended with an extra 'c' in front of the commentId. --->
									 <tr id="c#CommentId#" name="" class="<cfif commentLoopCount mod 2>k-content<cfelse>k-alt</cfif>">
										<td class="fixedCommentTableContent">
											 <a class="comment-id" href="#commentLink#" aria-label="Comment by #commenterFullName#" class="k-content">###i#</a> by <b>
											 <cfif len(commenterWebsite)>
												<a href="#commenterWebsite#" aria-label="#commenterFullName#" rel="nofollow">#commenterFullName#</a>
											 <cfelse>
												#commenterFullName#
											 </cfif></b> 
											 on #dateFormat(commentDatePosted, "mmmm d, yyyy")# at #timeFormat(commentDatePosted, "h:mm tt")#</p>
										</td>
									 <tr class="<cfif commentLoopCount mod 2>k-content<cfelse>k-alt</cfif>">
										<td>
											<img src="https://www.gravatar.com/avatar/#lcase(hash(lcase(commenterEmail)))#?s=64&amp;r=pg&amp;d=#application.blogHostUrl#/images/defaultAvatar.gif" title="#commenterFullName#'s Gravatar" alt="#commenterFullName#'s Gravatar" border="0" class="avatar avatar-64 photo" height="64" width="64" align="left" style="padding: 5px"  />
											#application.Udf.paragraphFormat2(comment)#
											<cfsilent><!---
											The replaceLinks function is removed with V2 and the new tinymce editor
											#paragraphFormat2(replaceLinks(comment))# 
											---></cfsilent>
										</td>
									 </tr>
									 <!--- If the number of records is even, create the bottom border.--->
								 <cfif arrayLen(comments) mod 2 is 0>
									 <tr class="<cfif commentLoopCount mod 2>k-alt<cfelse>k-content</cfif>">
										<td class="border"></td>
									 </tr>
								 </cfif>
								 <cfset commentLoopCount = commentLoopCount + 1>
							</cfloop>
								 <cfcatch type="any">
									<tr>
										<td>
											#cfcatch.detail#
										</td>
									</tr>
								 </cfcatch>
								 </cftry>
								</table>
							</div><!---<div id="comment#CommentId#" class="widget k-content" style="display:none;">--->
							</cfmodule><!--- End Cache Comment --->
						</cfif><!---<cfif application.includeDisqus>--->
						</cfif><!---<cfif showCommentInterface>--->
						</span><!---<span class="innerContentContainer">--->
					</div><!---<div class="blogPost">--->
				</article>
			</cfoutput></cfloop><!---<cfloop from="1" to="#arrayLen(getPost)#" index="i">--->
		</cfif><!---<cfif condensedGridView>--->
	</cfif><!---<cfif arrayLen(getPost)>--->
	<a href="#" id="pagerAnchor" aria-label="Pager+"></a><!--- This anchor is used to quickly scroll to the bottom of the page using the menu --->	
	<cfif (URL.startRow gt 1) or (arrayLen(getPost) gte maxEntries)>	
		<cfsilent>
		<!--- *******************************************************************************************************
			Pagination 
		**********************************************************************************************************--->
		<!---  
		Debugging: <cfoutput>url.startRow: #url.startRow# maxEntries: #maxEntries# arrayLen(getPost): #arrayLen(getPost)# URL.startRow + maxEntries: #round(URL.startRow + maxEntries)# postCount:#postCount# </cfoutput>
		<cfdump var="#getPost#">--->

		<!--- Get the number of pages. If a "fps" (first page size) query param is present, page 1 was a different
		size than every page after it - see curatedHomepageContentHtml.cfm, whose page 1 shows a dynamic row count
		instead of the standard maxEntries, and passes fps forward on its own pager links so this shared pager keeps
		computing correct offsets for page 3+. When fps is absent (every pre-existing caller), effectiveFirstPageSize
		equals maxEntries and this produces the exact same totalPages/links as before - a strict generalization, not
		a behavior change for pageTypeId 1/9/20/21. --->
		<cfset effectiveFirstPageSize = (isDefined("URL.fps") and isNumeric(URL.fps) and val(URL.fps) gt 0) ? val(URL.fps) : maxEntries>
		<cfset totalPages = 1 + ceiling(max(0, postCount - effectiveFirstPageSize) / maxEntries)>

		<!--- Set links --->
		<!--- Get the path if not /index.cfm --->
		<cfset path = rereplace(cgi.path_info, "(.*?)/index.cfm", "")>
		<!--- Clean out startrow from query string --->
		<cfset queryString = cgi.query_string>
		<!--- Safety check. Handle: http://www.coldfusionjedi.com/forums/messages.cfm?threadid=4DF1ED1F-19B9-E658-9D12DBFBCA680CC6 --->
		<cfset queryString = reReplace(queryString, "<.*?>", "", "all")>
		<cfset queryString = reReplace(queryString, "[\<\>]", "", "all")>
		<cfset queryString = reReplaceNoCase(queryString, "&*startrow=[\-0-9]+", "")>
		<!--- Remove the page variable. This is hard coded in the datasource below. --->
		<cfset queryString = reReplaceNoCase(queryString, "&*page=[\-0-9]+", "")>
		<!--- Remove any existing fps too - it gets re-added below (or dropped) as this page's own links are rebuilt. --->
		<cfset queryString = reReplaceNoCase(queryString, "&*fps=[\-0-9]+", "")>
		<!--- If it is not already defined, preset the URL page var --->
		<cfif not isDefined("URL.page")>
			<cfset URL.page = 0>
		</cfif>
		<!---
		Debugging:
		url.startRow: #url.startRow# maxEntries: #maxEntries# lastPageQueryString: #lastPageQueryString# currentPage: #currentPage# totalPages: #totalPages# prevPageEnabled:#prevPageEnabled# nextPageEnabled:#nextPageEnabled#--->

		</cfsilent>
			<cfoutput>
				<div id="pager" data-role="pager" class="k-pager-wrap k-widget k-floatwrap k-pager-lg">
				<script  type="#scriptTypeString#">
					<!--- Create the datasource with the URL --->
					var pagerDataSource = new kendo.data.DataSource({
					data: [<!--- Page 1 always starts at row 0; every page after it steps by the standard maxEntries from wherever page 1 actually left off (effectiveFirstPageSize), not from a naive (page-1)*maxEntries - that's what keeps this correct when page 1 was an odd size. fps is carried on every link so the SAME effectiveFirstPageSize keeps being used if this pager is rebuilt again from page 3, 4, etc. --->
					<cfloop from="1" to="#totalPages#" index="page">
						<cfset thisStartRow = (page eq 1) ? 0 : (effectiveFirstPageSize + ((page - 2) * maxEntries))>
						<cfset thisLink = queryString & "&startRow=" & thisStartRow & "&page=" & page & "&fps=" & effectiveFirstPageSize>
						{ pagerUrl: "#thisLink#", page: "#page#" }<cfif page lt totalPages>,</cfif>
					</cfloop>
					],
						pageSize: 1,// Leave this at 1.
						page: #URL.page#
					});

					 var pager = $("#chr(35)#pager").kendoPager({
						dataSource: pagerDataSource,
						messages: {
						  display: "page {0} of {2}"
						},
						change: function() {
							onPagerChange(this.dataSource.data());//this.datasource.productName
						}
					}).data("kendoPager");

					pagerDataSource.read();

					function onPagerChange(data){
						<!--- Get the current page of the pager. The method to extract the current page is 'page()'. --->
						var currentPage = pager.page();
						<!--- We are going to get the data item held in the datasource using its zero index array, but first we need to subtract 1 from the page value. --->
						var index = currentPage-1;
						<!--- Get the url that is stored in the datsource using our new index. --->
						var pagerUrl = "?" + data[index].pagerUrl;
						<!--- Open the page. --->
						window.location.href = pagerUrl;
					}
				</script>
				</div>
			</cfoutput>
		</cfif>
		<cfsilent>
			<!--- ****************************************************************************************
				Display current visitors for admins
			******************************************************************************************--->
		</cfsilent>
		<cfif application.logVisitors and application.Udf.isLoggedIn()>
			<cfsilent>
			<!--- Get the current visitors --->
			<!--- Determine if the visitor is on the home page --->
			<cfif application.siteUrl contains getPageContext().getRequest().getRequestURI()>
				<cfset isHomePage = true>
			<cfelse>
				<cfset isHomePage = false>
			</cfif>
			</cfsilent>
			<!--- Only show visitors if the user agent is reading a post or visiting the home page (index.cfm) --->
			<cfif isHomePage or structKeyExists(URL,"postId")>
				<cfsilent>
				<cfinvoke component="#application.blog#" method="getVisitorLog" returnvariable="getVisitorDbObj">
					<cfif structKeyExists(URL,"postId")>
						<cfinvokeargument name="postId" value="#URL.postId#">
					<cfelse>
						<cfinvokeargument name="visitingHome" value="true">
					</cfif>
					<cfinvokeargument name="onlyShowCurrentVisitors" value="true">
				</cfinvoke>
				<!---<cfdump var="#visitor#">--->
				</cfsilent>		
				<cfif arrayLen(getVisitorDbObj)>
				<!--- The visitors' browsers are identified on the server. This used to be done in the browser with the ua-parser.js library. --->
				<p><div id="currentVisitors" name="currentVisitors" style="font-size: 12pt;">Visitors: 
				<cfloop from="1" to="#arrayLen(getVisitorDbObj)#" index="i">
					<cfset visitorBrowser = application.blog.parseBrowser(getVisitorDbObj[i]['HttpUserAgent'])>
					<cfoutput><a href="https://www.ipalyzer.com/#encodeForHTMLAttribute(getVisitorDbObj[i]['IpAddress'])#" target="_new">#encodeForHTML(trim(visitorBrowser.family & " " & visitorBrowser.major))#</a><cfif i lt arrayLen(getVisitorDbObj)>, </cfif></cfoutput>
				</cfloop>
				</div></p>
				<cfelse><!---<cfif arrayLen(getVisitorDbObj)>--->
				<!--- The anonymous visitor may not have a stored user agent yet (for example on a new local install), so only show the browser when one exists. --->
				<cfset currentVisitorUserAgent = "">
				<cfif isDefined("AnonymousUserDbObj") and isObject(AnonymousUserDbObj) and isObject(AnonymousUserDbObj.getHttpUserAgentRef())>
					<cfset currentVisitorUserAgent = AnonymousUserDbObj.getHttpUserAgentRef().getHttpUserAgent()>
				</cfif>
				<cfif len(currentVisitorUserAgent)>
					<cfset currentVisitorBrowser = application.blog.parseBrowser(currentVisitorUserAgent)>
					<p><div id="currentVisitors" name="currentVisitors" style="font-size: 12pt;"> Visitors: <cfoutput><a href="https://www.ipalyzer.com/#encodeForHTMLAttribute(application.blog.getIpAddress())#" target="_new">#encodeForHTML(trim(currentVisitorBrowser.family & " " & currentVisitorBrowser.major))#</a></cfoutput></div></p>
				</cfif>
				</cfif><!---<cfif arrayLen(getVisitorDbObj)>--->
				
			</cfif><!---<cfif isHomePage or structKeyExists(URL,"postId")>--->
		</cfif><!---<cfif application.logVisitors and application.Udf.isLoggedIn()>--->
		<!--- **** Logic to display content when no data is found (ie when a user clicks on the wrong date) ****--->
		<cfif arrayLen(getPost) eq 0>
			<!--- Diagnostic-only logging for the 2026-09-30 "No Entries" pager bug (unconfirmed root cause, see
			[[pager-no-entries-bug-2026-09-30]] memory) - scoped tightly to the one suspicious shape: a page N>1
			request (has a startRow beyond the first page) that came back with zero rows, which a normal 404'd
			alias/day/empty-blog case never has. Wrapped in its own cftry so a logging problem can never break the
			page itself. Safe to remove once the real cause is confirmed and fixed - this is a trap, not a
			permanent feature. --->
			<cftry>
				<cfif isDefined("URL.startRow") and val(URL.startRow) gt 0>
					<cflog file="galaxieBlogPagerNoEntries" type="information" text="url.mode=#(isDefined('url.mode') ? url.mode : '')# startRow=#URL.startRow# page=#(isDefined('URL.page') ? URL.page : '')# fps=#(isDefined('URL.fps') ? URL.fps : '')# isMobile=#session.isMobile# postCount=#(isDefined('postCount') ? postCount : '')# maxEntries=#(isDefined('maxEntries') ? maxEntries : '')# themeId=#(isDefined('themeId') ? themeId : '')# referrer=#cgi.http_referer# queryString=#cgi.query_string# alias=#(isDefined('URL.alias') ? URL.alias : '')# categoryId=#(isDefined('URL.categoryId') ? URL.categoryId : '')# pathInfo=#cgi.path_info# userAgent=#cgi.http_user_agent#">
				</cfif>
				<cfcatch type="any"></cfcatch>
			</cftry>
			<div class="blogPost widget k-content" style="font-weight: bold;">
				<span class="innerContentContainer">
					<h1 class="topContent">
						No Entries
					</h1> 
					<span class="postContent">
					<cfif url.mode is "day">
						There are no entries for the selected dates. Please select a highlighted date in the calendar control.
						<!--- Kind of a hack. Fill the div, otherwise the side content will push to the left (see float left comment near the top of the page.)--->
						&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
						&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
						&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
					<cfelse>
						<!--- Handle errors when the post alias in the URL was not found. This could be the result of someone manually changing the URL, or if the post has not yet been released yet. --->
						<cfif not postFound>
						Post not available or found.&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
						&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
						<cfelse>
						<!--- This occurs when there is an error, or the blog is completely empty after installation. --->
						There are no blog entries.
						</cfif>
					</cfif>
					<br/><br/>
					</span>
				</span><!---<span class="innerContentContainer">--->
			</div><!---<div class="blogPost">--->
		</cfif><!---<cfif articles.recordcount eq 0>--->
	</div><!-- blogContent -->