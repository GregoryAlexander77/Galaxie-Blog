<!--- Renders one card per Page Collection, laid out the same way blog posts are: horizontal rows via Kendo's .k-card-deck (3 per row on desktop, 1 per row on mobile/when the sidebar shows), wrapping to a new row, not stacked. Mirrors blogContentHtml.cfm/renderKendoCardGrid.cfm's card markup (.k-card/.k-card-body/.k-card-title/.k-card-action) for the same look, since .k-card-deck itself does not wrap (flex-wrap: nowrap) - each row needs its own deck div, same reason blogContentHtml.cfm chunks posts into groups instead of a single flex container. Each card is the Collection's own hero image/title/description (not its members - visiting the Collection's own URL, pageTypeId=20, is what shows its members as cards).
Two callers, two different sources for which Collections to show:
- pageTypeId=22 (Configure Homepage set to one or more Collections): homepageCollectionIdList holds the admin's own explicit, ordered selection.
- pageTypeId=23 (the fixed /collections "browse all" page): homepageCollectionIdList is not set, so this falls back to every visible (2+ member) Collection, alphabetical - same list Configure Homepage's own picker offers. --->
<cfparam name="homepageCollectionIdList" default="">

<!--- Cached as one unit (galaxieCache) - the two branches below show different content (the admin's curated pick
vs every eligible Collection via getEligiblePageCollectionsForHomepage's own N+1 member-count query), so they need
separate cache keys; homepageCollectionIdList itself always reflects the CURRENT Configure Homepage setting (not a
per-request-varying param), so a cache key based only on which branch we're in - not its actual contents - is safe.
Theme is included since numColumns/kCardClass below depend on showSidebar, which is theme-breakpoint-driven. Nothing
after this file reads any of its variables, so it's safe to cache in full. See flushGalaxieCache's "pageCollection"
case (blog.cfc) for invalidation - covers any Page Collection change and any Configure Homepage save. --->
<cfset pageCollectionListCacheKey = buildCacheKey(len(homepageCollectionIdList) ? "pageCollectionListCurated" : "pageCollectionListBrowseAll", themeId)>
<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#pageCollectionListCacheKey#" scope="html" file="#application.baseUrl#/cache/pageCollections/#pageCollectionListCacheKey#.cfm" timeout="#(24*3600)#" debug="false" disabled="#application.disableCache#">
<cfset orderedHomepageCollections = []>
<cfif len(homepageCollectionIdList)>
	<!--- pageTypeId=22: the admin explicitly curated this exact set on Configure Homepage - "Featured" fits. --->
	<cfset collectionListHeading = "Featured Collections">
	<cfset allCollectionsForHomepage = application.blog.getAllPageCollections()>
	<cfloop list="#homepageCollectionIdList#" index="oneHomepageCollectionId">
		<cfloop array="#allCollectionsForHomepage#" index="oneCollectionRow">
			<cfif oneCollectionRow.pageCollectionId eq oneHomepageCollectionId>
				<cfset arrayAppend(orderedHomepageCollections, oneCollectionRow)>
			</cfif>
		</cfloop>
	</cfloop>
<cfelse>
	<!--- pageTypeId=23: the fixed /collections "browse all" page - this is EVERY visible Collection, not a curated
	pick, so "Featured" would be misleading here. --->
	<cfset collectionListHeading = "Collections">
	<cfset orderedHomepageCollections = application.blog.getEligiblePageCollectionsForHomepage()>
</cfif>

<cfobject component="#application.rendererComponentPath#" name="RendererObj">
<cfsilent>
	<!--- Same column logic as blogContentHtml.cfm's condensed card grid: one card per row on mobile or when the sidebar is shown, otherwise 3 across. --->
	<cfif session.isMobile or showSidebar>
		<cfset numColumns = 1>
		<cfset cardWidth = "100">
	<cfelse>
		<cfset numColumns = 3>
		<cfset cardWidth = "31">
	</cfif>
	<cfif not showSidebar>
		<cfset kCardClass = "k-card-deck">
	<cfelse>
		<cfset kCardClass = "k-card-list">
	</cfif>
</cfsilent>

<!--- id must be "blogContent", not "contentInnerContainer" - see pageCollectionContentHtml.cfm's own comment on why: it is the id with display:table-cell in blogContentCss.cfm, which is what makes it sit beside #sidebar (also table-cell) instead of the sidebar dropping below it. --->
<div id="blogContent" class="k-content">

	<h1 class="topContent"><cfoutput>#collectionListHeading#</cfoutput></h1>
	<cfloop from="1" to="#ceiling(arrayLen(orderedHomepageCollections)/numColumns)#" index="rowIndex">
		<div id="cardContainer" style="width: 100%">
			<div class="<cfoutput>#kCardClass#</cfoutput>" style="width:100%">
				<cfloop from="1" to="#numColumns#" index="colIndex">
					<cfset cardIndex = ((rowIndex - 1) * numColumns) + colIndex>
					<cfif cardIndex lte arrayLen(orderedHomepageCollections)>
						<cfset oneCollection = orderedHomepageCollections[cardIndex]>
						<!--- Same link-building pattern as Categories/Tags/Posts (makeCategoryLink/makeTagLink/makeLink) - instance.blogUrl already includes /index.cfm, stripped only when a server-side rewrite rule is actually in place (application.serverRewriteRuleInPlace). A plain application.baseUrl & "/" & alias skips that and produces a broken link whenever no rewrite rule exists. --->
						<cfset collectionUrl = application.blog.makeCollectionLink(oneCollection.pageCollectionId)>
						<div class="k-card" style="width: <cfoutput>#cardWidth#</cfoutput>%;">
							<div class="k-card-body">
								<!--- Carousel, map, video or gradient hero first (see Renderer.cfc's renderPageCollectionHero) - not wrapped in the card link, since the carousel/map/video have their own controls. --->
								<cfset collectionHeroHtml = RendererObj.renderPageCollectionHero(pageCollectionId=oneCollection.pageCollectionId, cardMode=true, showSidebar=showSidebar)>
								<cfif len(collectionHeroHtml)>
									<cfoutput>#collectionHeroHtml#</cfoutput>
								<cfelse>
								<a href="<cfoutput>#collectionUrl#</cfoutput>" aria-label="<cfoutput>#oneCollection.title#</cfoutput>">
									<cfif len(oneCollection.heroImageUrl)>
										<!--- The card-sized copy of the picture when there is one (2026-10-31, Image.cfc getCardImageUrl). --->
										<cfif not structKeyExists(request, "galaxieImageObj")><cfset request.galaxieImageObj = createObject("component", application.imageComponentPath)></cfif>
										<cfset thisCardImage = request.galaxieImageObj.getCardImageUrl(oneCollection.heroImageUrl)>
										<div class="img-hover-zoom img-hover-brightzoom"><img class="fade lazied shown k-card-image" data-type="image" data-src="<cfoutput>#thisCardImage#</cfoutput>" alt="<cfoutput>#oneCollection.title#</cfoutput>" data-lazied="IMG" src="<cfoutput>#thisCardImage#</cfoutput>"></div>
									<cfelse>
										<div class="img-hover-zoom img-hover-brightzoom"><img class="fade lazied shown k-card-image" data-type="image" data-src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png" alt="<cfoutput>#oneCollection.title#</cfoutput>" data-lazied="IMG" src="<cfoutput>#application.baseUrl#</cfoutput>/images/icons/noMedia.png"></div>
									</cfif>
								</a>
								</cfif>
								<hr class="k-card-separator" />
								<h2 class="k-card-title" style="font-size: 14pt; margin: 10px 0px;"><a href="<cfoutput>#collectionUrl#</cfoutput>" aria-label="<cfoutput>#oneCollection.title#</cfoutput>"><cfoutput>#oneCollection.title#</cfoutput></a></h2>
								<cfif len(oneCollection.description)>
									<hr class="k-card-separator" />
									<span class="blog-content"><cfoutput>#oneCollection.description#</cfoutput></span>
								</cfif>
							</div>
							<span class="k-card-action">
								<span class="k-button k-primary" onClick="window.open('<cfoutput>#collectionUrl#</cfoutput>')">View Collection...</span>
							</span>
						</div>
					</cfif>
				</cfloop>
			</div>
		</div>
	</cfloop>
</div>
</cfmodule>
