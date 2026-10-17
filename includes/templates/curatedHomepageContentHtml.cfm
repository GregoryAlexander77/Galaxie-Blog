<!--- The additive/curated homepage (index.cfm, pageTypeId=24, page 1 only - see index.cfm's own comment on why page 2+
of the Blog Posts section falls through to blogContentHtml.cfm instead of this file) - independently toggled sections,
stacked in a fixed order: Featured Pages, then Featured Collections, then Popular Blogs + All Blogs together (the
Popular Blogs carousel sits just above All Blogs, sharing its showBlogPosts gate, not shown independently). Each section only renders
if its toggle is on and it actually has something to show. NOT used when Pages is on with exactly one Page selected -
that's the pre-existing pageTypeId=9 full-page-takeover override, resolved in index.cfm before this pageTypeId is ever
set, so "showPages" here always means 2+ Pages when it's true. Featured Pages/Collections reuse the shared
includes/templates/cardGridSection.cfm grid renderer, fed with plain {title, description, imageUrl, linkUrl} data
built independently per section below - this bypasses the normal getPost.cfm/params.byPostIdList pipeline entirely
(that pipeline assumes ONE getPost array for the whole page, which doesn't fit three independent sections on one page).

Blog Posts row budget: the Featured Pages/Collections rows above eat into a fixed total of 7 "icon rows" across the
whole page-1 view, so Blog Posts shows fewer rows the more space Featured content already took, always leaving at
least 1 row and never showing more than 5 (the plain default when nothing else is on). See the row-count comments
inline below for the exact table this implements. --->
<cfset curatedHomepageSettings = application.blog.getHomepageSettings()>

<!--- Same column logic as cardGridSection.cfm's own internal computation - needed here too so the row-count math
(below) agrees with how each section will actually render. --->
<cfset homepageNumColumns = (session.isMobile or showSidebar) ? 1 : 3>

<!--- Cheap, cache-independent count used only to detect the "every section is empty" case at the bottom of this
file (see the closing block below) - the Popular Blogs/All Blogs sections themselves are computed inside their own
galaxieCache blocks further down, so their own item arrays aren't reliably available out here on a cache hit. This
is the same count getBlogPostCount() already provides for the pager math later in this file, just called once,
early, independent of caching. --->
<cfset totalBlogPostCountForEmptyCheck = curatedHomepageSettings.showBlogPosts ? application.blog.getBlogPostCount() : 0>

<!--- id must be "blogContent", not "contentInnerContainer" - see pageCollectionContentHtml.cfm's own comment on why: it
is the id with display:table-cell in blogContentCss.cfm, which is what makes it sit beside #sidebar (also table-cell)
instead of the sidebar dropping below it. ONE wrapper for all three sections, not one per section, to keep that layout
mechanism working (it needs exactly one #blogContent sibling next to #sidebar). --->
<div id="blogContent" class="k-content">

<cfset featuredPagesRowCount = 0>
<cfif curatedHomepageSettings.showPages and listLen(curatedHomepageSettings.pageIdList) gt 1>
	<cfset featuredPagesItems = []>
	<cfloop list="#curatedHomepageSettings.pageIdList#" index="oneFeaturedPageId">
		<cfset oneFeaturedPage = entityLoadByPK("Post", oneFeaturedPageId)>
		<cfif isObject(oneFeaturedPage)>
			<cfset arrayAppend(featuredPagesItems, {
				title: oneFeaturedPage.getTitle(),
				description: oneFeaturedPage.getDescription(),
				imageUrl: "",
				mediaHtml: "",
				suppressImage: false,
				linkUrl: application.blog.makeLink(postId=oneFeaturedPageId)
			})>
		</cfif>
	</cfloop>
	<cfif arrayLen(featuredPagesItems)>
		<cfset featuredPagesRowCount = ceiling(arrayLen(featuredPagesItems) / homepageNumColumns)>
		<cfset cardGridHeading = "Featured Pages">
		<cfset cardGridItems = featuredPagesItems>
		<cfset cardGridButtonText = "Read More...">
		<cfset cardGridFooterLink = "">
		<cfinclude template="cardGridSection.cfm">
	</cfif>
</cfif>

<cfset featuredCollectionsRowCount = 0>
<cfif curatedHomepageSettings.showCollections and len(curatedHomepageSettings.collectionIdList)>
	<cfset allCollectionsForCurated = application.blog.getAllPageCollections()>
	<cfset featuredCollectionsItems = []>
	<!--- For each collection's carousel/map/video/gradient hero (mediaHtml below) - the RendererObj further down this file is created after this section. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<cfloop list="#curatedHomepageSettings.collectionIdList#" index="oneFeaturedCollectionId">
		<cfloop array="#allCollectionsForCurated#" index="oneCollectionRow">
			<cfif oneCollectionRow.pageCollectionId eq oneFeaturedCollectionId and oneCollectionRow.visible>
				<cfset arrayAppend(featuredCollectionsItems, {
					title: oneCollectionRow.title,
					description: oneCollectionRow.description,
					imageUrl: oneCollectionRow.heroImageUrl,
					mediaHtml: RendererObj.renderPageCollectionHero(pageCollectionId=oneCollectionRow.pageCollectionId, cardMode=true, showSidebar=showSidebar),
					suppressImage: false,
					linkUrl: application.blog.makeCollectionLink(oneCollectionRow.pageCollectionId)
				})>
			</cfif>
		</cfloop>
	</cfloop>
	<cfif arrayLen(featuredCollectionsItems)>
		<cfset featuredCollectionsRowCount = ceiling(arrayLen(featuredCollectionsItems) / homepageNumColumns)>
		<cfset cardGridHeading = "Featured Collections">
		<cfset cardGridItems = featuredCollectionsItems>
		<cfset cardGridButtonText = "View Collection...">
		<cfset cardGridFooterLink = "">
		<cfinclude template="cardGridSection.cfm">
	</cfif>
</cfif>

<cfif curatedHomepageSettings.showBlogPosts>
	<!--- Popular Blogs - the same reusable includes/templates/popularPosts.cfm widget (a Kendo card-deck-scrollwrap
	carousel) blogContentHtml.cfm's own main listing already uses for this exact purpose, in its own #hero div -
	reused as-is here rather than rebuilt. Positioned just above the Blog Posts/All Blogs section (not at the very
	top of the page) per explicit instruction, inside the same showBlogPosts gate since the two are shown/hidden
	together. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<div id="hero">
		<cfsilent>
			<cfif session.isMobile>
				<cfset cacheKey = 'popularPosts#themeId#Mobile'>
			<cfelse>
				<cfset cacheKey = 'popularPosts#themeId#'>
			</cfif>
			<!--- Popular Blogs card width (see popularPosts.cfm): narrow/fixed-width when this is a plain
			latest-posts homepage (matches current production), aligned/responsive as soon as Featured Pages or
			Featured Collections are also showing, since multiple stacked card-grid sections read better when
			they all line up. --->
			<cfset renderNarrowPopularPostCard = (featuredPagesRowCount eq 0 and featuredCollectionsRowCount eq 0)>
		</cfsilent>
		<!--- Bug fix: this previously referenced the stale "cachename"/"cacheName" variable left over from the
		header/topMenu cache earlier in index.cfm's own execution, not the cacheKey computed just above (which is
		the one that's actually theme/mobile-aware for this widget). It still worked (each cache still wrote to its
		own distinct file), but it shared its server-scope cache-metadata bookkeeping (timeout/hit count) with the
		unrelated topMenu cache. Now uses cacheKey, like it was clearly meant to. --->
		<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#cacheKey#" scope="html" file="#application.baseUrl#/cache/cards/#cacheKey#.cfm" timeout="#(24*3600)#" debug="false" disabled="#application.disableCache#">
			<cfinvoke component="#application.blog#" method="getPost" returnvariable="getPosts">
				<cfinvokeargument name="showPopularPosts" value="true">
				<cfinvokeargument name="showPages" value="false">
				<cfinvokeargument name="showBlogPosts" value="true">
			</cfinvoke>
			<cfif arrayLen(getPosts)>
				<cfset postScrollWidgetType = "popularPosts">
				<cfinclude template="popularPosts.cfm">
			</cfif>
		</cfmodule>
	</div>

	<!--- The 7-row budget: Featured Pages + Featured Collections rows come out of a shared total of 7 "icon rows"
	across page 1. Blog Posts always gets at least enough rows for 3 posts and never more than 5 (the plain
	default when nothing else is on) - e.g. 2 combined rows above -> 5 blog rows, 3 -> 4, 4 -> 3, 5 -> 2, 6+ -> the
	3-post floor (overflowing the 7-row budget rather than squeezing Blog Posts away entirely).
	2026-10-04: the floor used to be a flat "at least 1 row", which on mobile's 1-column layout meant "at least 1
	post" - heavily-featured homepages (several Featured Pages/Collections) could squeeze mobile's Blog Posts down
	to a single card while desktop still got a full row of 3, since the same number of featured items costs mobile
	3x the rows (1 column) that it costs desktop (3 columns). The floor is now column-aware - ceil(3/
	homepageNumColumns) - so it guarantees 3 actual POSTS on both mobile and desktop, not 3 rows: 3 rows on
	mobile's 1 column, same 1 row desktop already had with 3 columns. --->
	<cfset minBlogRowsForThreePosts = ceiling(3 / homepageNumColumns)>

	<!--- Everything from here down through the pager is cached as one unit (galaxieCache, same proven pattern as the
	Popular Blogs carousel above) - on a cache hit this skips two getPost() calls and a getBlogPostCount() call
	entirely. Safe to cache as a whole: nothing outside this block (or after it - see this file's own header
	comment on why page 2+ never reaches this file) reads any variable set inside it, and featuredPagesRowCount/
	featuredCollectionsRowCount (needed for the row-budget math on a cache MISS) are already computed above,
	outside this cache block, so a cache HIT skipping this block's body doesn't lose them. The pager's own links
	bake in cgi.query_string/URL.page at cache-write time - fine here since this file only ever renders page 1 (so
	URL.page is always its default), but be aware a stray query-string param would get baked in for every visitor
	until the cache expires or is flushed. See flushGalaxieCache's "pageCollection" case (blog.cfc) for
	invalidation - it flushes this on any Page Collection change and on Configure Homepage saves, since either can
	change the row budget above. --->
	<cfset blogPostsCacheKey = buildCacheKey("curatedBlogPosts", themeId)>
	<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#blogPostsCacheKey#" scope="html" file="#application.baseUrl#/cache/cards/#blogPostsCacheKey#.cfm" timeout="#(24*3600)#" debug="false" disabled="#application.disableCache#">
	<cfset combinedFeaturedRows = featuredPagesRowCount + featuredCollectionsRowCount>
	<cfset preliminaryBlogRows = max(minBlogRowsForThreePosts, min(5, 7 - combinedFeaturedRows))>

	<!--- Own independent params struct/maxEntries, not the shared getPost.cfm pipeline's params (this needs a
	different, dynamically-computed page size that nothing else on the page shares). A promoted post still pins
	itself at the top of the query (showPromoteAtTopOfQuery) but no longer eats one of Blog Posts' rows to make
	room for it - on desktop's 3-column grid it just merges into the existing row structure, and on mobile's
	1-column layout it's an accepted extra post rather than a shrunk page. --->
	<cfset blogPostsParams = {}>
	<cfset blogPostsParams.maxEntries = preliminaryBlogRows * homepageNumColumns>
	<cfset blogPostsParams.startRow = 1>
	<cfinvoke component="#application.blog#" method="getPost" returnvariable="recentBlogPostsForHomepage">
		<cfinvokeargument name="params" value="#blogPostsParams#">
		<cfinvokeargument name="showPages" value="false">
		<cfinvokeargument name="showBlogPosts" value="true">
		<cfinvokeargument name="showPromoteAtTopOfQuery" value="true">
	</cfinvoke>

	<cfset finalBlogRows = preliminaryBlogRows>
	<cfset finalBlogPageSize = finalBlogRows * homepageNumColumns>
	<cfif arrayLen(recentBlogPostsForHomepage) gt finalBlogPageSize>
		<cfset recentBlogPostsForHomepage = arraySlice(recentBlogPostsForHomepage, 1, finalBlogPageSize)>
	</cfif>

	<cfset blogPostItems = []>
	<!--- Events (2026-10-16): the events among these posts, looked up once (Events.cfc getCardEvents). An event post's card shows the event under its title (eventHtml, see cardGridSection.cfm), and a date tile instead of the no-image picture. --->
	<cfset curatedCardPostIds = []>
	<cfloop from="1" to="#arrayLen(recentBlogPostsForHomepage)#" index="i"><cfset arrayAppend(curatedCardPostIds, recentBlogPostsForHomepage[i]["PostId"])></cfloop>
	<cfset curatedCardEvents = structKeyExists(application, "events") ? application.events.getCardEvents(curatedCardPostIds) : {}>
	<cfloop from="1" to="#arrayLen(recentBlogPostsForHomepage)#" index="i">
		<cfset cardEvent = structKeyExists(curatedCardEvents, recentBlogPostsForHomepage[i]["PostId"]) ? curatedCardEvents[recentBlogPostsForHomepage[i]["PostId"]] : {}>
		<cfset cardEventTile = false>
		<!--- cardGridSection.cfm supports a ready-to-insert widget via mediaHtml (its own top display priority - see
		its comment), same as renderKendoCardGrid.cfm/popularPosts.cfm's thumbnailCarousel slot - so this calls
		getHeroFallbackHtml with allowHtml=true (default) and routes isHtml=true content into mediaHtml, instead of
		skipping 'pool'/carousel mode with allowHtml=false. Without this, NoImageFallbackMode='pool' with
		HeroPoolDisplayMode='carousel' silently fell back to 'generated' art here even though every other card view
		(Popular Blogs, the plain blog listing) rendered the real carousel. --->
		<cfset thisBlogPostImageUrl = recentBlogPostsForHomepage[i]["MediaUrl"]>
		<cfset thisBlogPostMediaHtml = "">
		<cfset thisBlogPostSuppressImage = false>
		<!--- The no-media fallback chain (gradient aside - see below) should only ever run when the post truly has
		no media at all. MediaUrl already covers Image/Video (both come off the same Post.EnclosureMedia join), but
		Map and Carousel are separate joins (Post.EnclosureMap/Post.EnclosureCarousel) that never populate MediaUrl -
		so a map-only or carousel-only post with no HeroGradient used to fall all the way through to the
		generic-mode noMedia.png placeholder, wrongly implying the post has nothing when it actually has real media,
		just not a still image this card can show. "Map Routes" isn't a separate enclosure type (HasMapRoutes is
		just a flag on the same Map row - see Map.cfc), so checking EnclosureMapId alone covers both. --->
		<!--- 2026-10-01: a Hero Cover Image (static uploaded photo, for a post with no real Image/Video/Map/
		Carousel) takes priority over the Gradient/Map/Carousel/generated-fallback chain below, same relative
		priority renderKendoCardGrid.cfm/popularPosts.cfm give it. Plain imageUrl, same as a real Image
		enclosure's own thisBlogPostImageUrl - no mediaHtml widget needed, it's just a photo. --->
		<cfif not len(thisBlogPostImageUrl) and len(recentBlogPostsForHomepage[i]["HeroCoverImageUrl"])>
			<cfset thisBlogPostImageUrl = recentBlogPostsForHomepage[i]["HeroCoverImageUrl"]>
		<!--- An explicit gradient the user picked (see gradientEditor.cfm/Post.cfc's HeroGradient) is a real,
		deliberate hero choice - checked before the Map/Carousel widgets and the auto-generated-art fallback below,
		same priority reasoning as Renderer.cfc's renderEnclosure()/renderMediaPreview(). Routes into mediaHtml,
		same as this template's own isHtml=true fallback content (see this loop's own header comment above). --->
		<cfelseif not len(thisBlogPostImageUrl) and len(recentBlogPostsForHomepage[i]["HeroGradient"])>
			<!--- Renderer.cfc.renderHeroGradientHtml() - single point of truth for this HTML, shared with
			Renderer.cfc's own renderMediaPreview()/renderEnclosure() and the other two card templates. --->
			<!--- Named arguments (2026-10-09) - see renderKendoCardGrid.cfm: a positional "true" here landed in heroOverlayFont, not cardMode. --->
			<cfset thisBlogPostMediaHtml = RendererObj.renderHeroGradientHtml(heroGradient=recentBlogPostsForHomepage[i]["HeroGradient"], heroOverlayText=recentBlogPostsForHomepage[i]["HeroOverlayText"], heroOverlayTextColor=recentBlogPostsForHomepage[i]["HeroOverlayTextColor"], heroOverlayFont=(structKeyExists(recentBlogPostsForHomepage[i], "HeroOverlayFont") ? recentBlogPostsForHomepage[i]["HeroOverlayFont"] : ""), heroOverlayFontSize=(structKeyExists(recentBlogPostsForHomepage[i], "HeroOverlayFontSize") ? recentBlogPostsForHomepage[i]["HeroOverlayFontSize"] : ""), cardMode=true)>
		<!--- Render the same widgets renderKendoCardGrid.cfm/popularPosts.cfm already render for these enclosure
		types, instead of just hiding the image area - renderMapPreview's renderThumbnail=true path returns a
		cached static snapshot image (via the map provider's static-image API), not a live interactive iframe, so
		this stays cheap to show on a listing page. renderMediumCard=false/showSidebar matches this grid's own
		always-small card format (see homepageNumColumns above - this section never renders the wider sidebar-card
		layout renderKendoCardGrid.cfm's renderMediumCard=true path is for). --->
		<cfelseif not len(thisBlogPostImageUrl) and len(recentBlogPostsForHomepage[i]["EnclosureMapId"])>
			<cfset thisBlogPostMediaHtml = RendererObj.renderMapPreview(recentBlogPostsForHomepage[i]["EnclosureMapId"], true, true, false, showSidebar)>
		<cfelseif not len(thisBlogPostImageUrl) and len(recentBlogPostsForHomepage[i]["EnclosureCarouselId"])>
			<cfset thisBlogPostMediaHtml = RendererObj.renderCarousel(recentBlogPostsForHomepage[i]["EnclosureCarouselId"], true)>
		<!--- An event with no picture of its own: its date tile (2026-10-16). --->
		<cfelseif not len(thisBlogPostImageUrl) and not structIsEmpty(cardEvent)>
			<cfset thisBlogPostMediaHtml = application.events.renderDateTileHtml(cardEvent)>
			<cfset cardEventTile = true>
		<cfelseif not len(thisBlogPostImageUrl)>
			<cfset thisHeroFallback = RendererObj.getHeroFallbackHtml(postId=recentBlogPostsForHomepage[i]["PostId"], cardMode=true)>
			<cfif thisHeroFallback.isHtml>
				<cfset thisBlogPostMediaHtml = thisHeroFallback.content>
			<cfelseif thisHeroFallback.suppressImage>
				<cfset thisBlogPostSuppressImage = true>
			<cfelseif len(thisHeroFallback.content)>
				<cfset thisBlogPostImageUrl = thisHeroFallback.content>
			</cfif>
		</cfif>
		<!--- An event with its own picture, gradient, map or carousel: the calendar page in the middle of it (owner, 10-16); clicks go through it. --->
		<cfset cardEventOverlay = not structIsEmpty(cardEvent) and not cardEventTile and not thisBlogPostSuppressImage and (len(thisBlogPostImageUrl) or len(thisBlogPostMediaHtml))>
		<cfset arrayAppend(blogPostItems, {
			title: recentBlogPostsForHomepage[i]["Title"],
			description: recentBlogPostsForHomepage[i]["Description"],
			imageUrl: thisBlogPostImageUrl,
			mediaHtml: thisBlogPostMediaHtml,
			suppressImage: thisBlogPostSuppressImage,
			eventHtml: structIsEmpty(cardEvent) ? "" : application.events.renderCardStripHtml(ev = cardEvent, hasTile = cardEventTile or cardEventOverlay),
			eventOverlayHtml: cardEventOverlay ? application.events.renderSheetOverlayHtml(cardEvent) : "",
			<!--- 2026-10-01: the "thin border around promoted posts" treatment (cardGridSection.cfm's own
			highlightedWidget/bullhorn-icon support, mirroring renderKendoCardGrid.cfm's older promotedPost logic)
			never got wired up here when this curated homepage was built - this card template's items simply had
			no promoted key at all, so a promoted post looked like any other post on this page even though the
			plain blog listing still highlighted it correctly. structKeyExists guards the same Lucee HQL Map
			NULL-key-omission gotcha renderKendoCardGrid.cfm's own check already guards against. --->
			promoted: structKeyExists(recentBlogPostsForHomepage[i], "Promoted") ? recentBlogPostsForHomepage[i]["Promoted"] : false,
			linkUrl: application.blog.makeLink(isPage=false, postAlias=recentBlogPostsForHomepage[i]["PostAlias"], datePosted=recentBlogPostsForHomepage[i]["DatePosted"])
		})>
	</cfloop>
	<cfif arrayLen(blogPostItems)>
		<!--- "All Blogs", matching the plain main listing's own heading (blogContentHtml.cfm's getPageMode() eq 'blog'
		case) and the production site's convention - not "Recent Posts", now that this section paginates like a real
		listing instead of being a fixed-size teaser. --->
		<cfset cardGridHeading = "All Blogs">
		<cfset cardGridItems = blogPostItems>
		<cfset cardGridButtonText = "Read More...">
		<!--- No more "View All Posts" text link - real pagination (below) replaces it now that this section is a
		genuine paginated view, not just a fixed-size teaser. --->
		<cfset cardGridFooterLink = "">
		<cfinclude template="cardGridSection.cfm">

		<!--- Pagination - same Kendo Pager markup/mechanism blogContentHtml.cfm's own listing uses, generalized to
		start from finalBlogPageSize (this page's own, possibly-dynamic size) instead of assuming every page
		including page 1 is the standard application.maxEntries. Every generated link carries "fps" so
		blogContentHtml.cfm (which renders page 2+, see index.cfm) keeps computing correct offsets for page 3+. --->
		<cfset totalBlogPostCount = application.blog.getBlogPostCount()>
		<!--- Page 2+ of this section shows a flat 15 posts (see blogContentHtml.cfm's pageTypeId 24 maxEntries and
		index.cfm's matching over-fetch), not application.maxEntries - so this pager has to step by the same 15.
		Stepping by application.maxEntries (9) here offered more pages than really exist and pointed page 3+ at
		posts page 2 had already shown, while page 2's own pager (built by blogContentHtml.cfm) correctly stepped
		by 15 - the two pagers disagreed on the page count. Keep this in sync with blogContentHtml.cfm. --->
		<cfset laterBlogPageSize = 15>
		<cfset totalBlogPages = 1>
		<cfif totalBlogPostCount gt finalBlogPageSize>
			<cfset totalBlogPages = 1 + ceiling((totalBlogPostCount - finalBlogPageSize) / laterBlogPageSize)>
		</cfif>
		<cfif totalBlogPages gt 1>
			<cfsilent>
				<!--- Deliberately NOT built from cgi.query_string. This whole block is cached (one copy per theme) and
				served to every visitor, so whatever query string the request that rebuilt the cache happened to carry
				(a bot's junk params, a tracking tag, ?mode=category&categoryId=...) got baked into everyone's pager links
				for up to 24 hours - page 2+ then ran that stray mode and showed "No Entries", while caching was on. This
				view is only ever page 1 of the bare homepage, so the links need nothing but startRow/page/fps. --->
				<cfset homepagePagerQueryString = "">
				<cfif not isDefined("URL.page")>
					<cfset URL.page = 0>
				</cfif>
			</cfsilent>
			<cfoutput>
				<div id="pager" data-role="pager" class="k-pager-wrap k-widget k-floatwrap k-pager-lg">
				<script type="#scriptTypeString#">
					var homepagePagerDataSource = new kendo.data.DataSource({
					data: [<cfloop from="1" to="#totalBlogPages#" index="page">
						<cfset thisStartRow = (page eq 1) ? 0 : (finalBlogPageSize + ((page - 2) * laterBlogPageSize))>
						<cfset thisLink = homepagePagerQueryString & "&startRow=" & thisStartRow & "&page=" & page & "&fps=" & finalBlogPageSize>
						{ pagerUrl: "#thisLink#", page: "#page#" }<cfif page lt totalBlogPages>,</cfif>
					</cfloop>
					],
						pageSize: 1,// Leave this at 1.
						page: #URL.page#
					});

					var homepagePager = $("#chr(35)#pager").kendoPager({
						dataSource: homepagePagerDataSource,
						messages: {
						  display: "page {0} of {2}"
						},
						change: function() {
							onHomepagePagerChange(this.dataSource.data());
						}
					}).data("kendoPager");

					homepagePagerDataSource.read();

					function onHomepagePagerChange(data){
						var currentPage = homepagePager.page();
						var index = currentPage-1;
						var pagerUrl = "?" + data[index].pagerUrl;
						window.location.href = pagerUrl;
					}
				</script>
				</div>
			</cfoutput>
		</cfif>
	</cfif>
	</cfmodule>
</cfif>

<!--- Same "There are no blog entries." wording the classic listing (blogContentHtml.cfm) already shows for a
genuinely empty blog - this page had no equivalent, so a brand new install (or every section toggled off/empty at
once) silently rendered nothing here, with the page's own unconditional footer content visually filling the gap
instead. Checked last, after every section above has had its chance to render, using the row counts/count computed
above rather than re-deriving anything from inside the cached blocks. --->
<cfif featuredPagesRowCount eq 0 and featuredCollectionsRowCount eq 0 and totalBlogPostCountForEmptyCheck eq 0>
	<div class="k-content" style="text-align: center; padding: 40px 20px;">
		<h2 class="topContent">There are no blog entries.</h2>
	</div>
</cfif>

</div>
