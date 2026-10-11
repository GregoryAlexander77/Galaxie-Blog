<!--- Renders a Page Collection's own listing: its hero image + description, then a plain list of links to its member pages. Deliberately unstyled/theme-agnostic (the Collection's own Theme setting, from Configure Page Collections, governs this view - not baked into the markup here). Used both when a Page Collection is set as the homepage (index.cfm, pageTypeId=20) and, eventually, when visited at its own URL.

Cached as one unit (galaxieCache) since nothing after this file reads pageCollection/pcMembers - safe to skip the entity load + member query entirely on a cache hit. Theme/device-agnostic per the comment above, so the cache key is just the collection id, shared across every theme/device. See flushGalaxieCache's "pageCollection" case (blog.cfc) for invalidation - covers any edit, membership change, or delete. --->
<cfset pageCollectionDetailCacheKey = "pageCollectionDetail" & homepageCollectionId>
<cfmodule template="#application.baseUrl#/tags/galaxieCache.cfm" cachename="#pageCollectionDetailCacheKey#" scope="html" file="#application.baseUrl#/cache/pageCollections/#pageCollectionDetailCacheKey#.cfm" timeout="#(24*3600)#" debug="false" disabled="#application.disableCache#">
<cfset pageCollection = entityLoadByPK("PageCollection", homepageCollectionId)>
<cfset pcMembers = application.blog.getPageCollectionMembers(homepageCollectionId)>

<cfif isObject(pageCollection)>
<!--- id must be "blogContent", not "contentInnerContainer" - that's the id blogContentHtml.cfm's own wrapper uses, and it's the one with display:table-cell in blogContentCss.cfm, which is what makes it sit beside #sidebar (also table-cell) as CSS-generated anonymous table siblings inside <main>. Without it, this div falls out of that layout and the sidebar drops below instead of beside it. --->
<div id="blogContent" class="k-content pageCollectionListing">
	<!--- Carousel, map, video or gradient hero first (see Renderer.cfc's renderPageCollectionHero), then the plain hero image. --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
	<cfset pageCollectionHeroHtml = RendererObj.renderPageCollectionHero(pageCollectionId=homepageCollectionId)>
	<cfif len(pageCollectionHeroHtml)>
		<cfoutput>#pageCollectionHeroHtml#</cfoutput>
	<cfelseif len(pageCollection.getHeroImageUrl())>
		<img src="<cfoutput>#pageCollection.getHeroImageUrl()#</cfoutput>" alt="<cfoutput>#pageCollection.getTitle()#</cfoutput>" style="max-width: 100%;">
	</cfif>
<h1><cfoutput>#pageCollection.getTitle()#</cfoutput></h1>
	<cfif len(pageCollection.getDescription())>
		<p><cfoutput>#pageCollection.getDescription()#</cfoutput></p>
	</cfif>
	<ul class="pageCollectionMemberList">
		<cfloop array="#pcMembers#" index="m">
			<cfset memberUrl = application.blog.makeLink(postId=m.postId, isPage=true, postAlias=m.postAlias, datePosted=m.datePosted)>
			<li><a href="<cfoutput>#memberUrl#</cfoutput>"><cfoutput>#m.title#</cfoutput></a></li>
		</cfloop>
	</ul>
</div>
</cfif>
</cfmodule>
