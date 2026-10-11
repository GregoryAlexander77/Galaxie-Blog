<!--- description: Fills in default values for the columns added since 4.7 (Page Collection Show in Menu and the two top menu names, Post hero overlay font size, cover image, animation effect and options; BlogOption image quality, no-image fallback mode, carousel count, animation defaults). ORM adds the columns themselves on restart (dbcreate="update"); this only fills rows that were created before those columns existed, so existing posts and blog options don't read as NULL. Safe to run more than once. --->
<cfquery name="backfillPostHeroText" dbtype="hql">
	UPDATE Post SET HeroOverlayFontSize = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	WHERE HeroOverlayFontSize IS NULL
</cfquery>
<cfquery name="backfillPostHeroCover" dbtype="hql">
	UPDATE Post SET HeroCoverImageUrl = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	WHERE HeroCoverImageUrl IS NULL
</cfquery>
<cfquery name="backfillPostHeroAnimation" dbtype="hql">
	UPDATE Post SET HeroAnimationEffect = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	WHERE HeroAnimationEffect IS NULL
</cfquery>
<cfquery name="backfillPostHeroAnimationOptions" dbtype="hql">
	UPDATE Post SET HeroAnimationOptions = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	WHERE HeroAnimationOptions IS NULL
</cfquery>
<cfquery name="backfillBlogOptionImageQuality" dbtype="hql">
	UPDATE BlogOption SET DefaultImageQuality = <cfqueryparam value="0.8" cfsqltype="cf_sql_float">
	WHERE DefaultImageQuality IS NULL
</cfquery>
<cfquery name="backfillBlogOptionFallbackMode" dbtype="hql">
	UPDATE BlogOption SET NoImageFallbackMode = <cfqueryparam value="generic" cfsqltype="cf_sql_varchar">
	WHERE NoImageFallbackMode IS NULL
</cfquery>
<cfquery name="backfillBlogOptionCarouselCount" dbtype="hql">
	UPDATE BlogOption SET HeroCarouselImageCount = <cfqueryparam value="1" cfsqltype="cf_sql_integer">
	WHERE HeroCarouselImageCount IS NULL
</cfquery>
<cfquery name="backfillBlogOptionAnimationEffect" dbtype="hql">
	UPDATE BlogOption SET AnimationEffect = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	WHERE AnimationEffect IS NULL
</cfquery>
<cfquery name="backfillBlogOptionAnimationOptions" dbtype="hql">
	UPDATE BlogOption SET AnimationOptions = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	WHERE AnimationOptions IS NULL
</cfquery>

<!--- 2026-10-10: the 4.8 top menu (Configure Menu). Fill the new columns' blanks, carry the old single "parent site" link
from Blog Settings over as the first Menu link, and keep a menu of "docs-" collections (which the old menu listed
automatically under "Docs") showing under the same name. Each step only fills in what is missing. --->
<cfquery name="backfillPageCollectionShowInMenu" dbtype="hql">
	UPDATE PageCollection SET ShowInMenu = <cfqueryparam value="false" cfsqltype="cf_sql_bit">
	WHERE ShowInMenu IS NULL
</cfquery>
<cfquery name="backfillBlogOptionCollectionsMenuLabel" dbtype="hql">
	UPDATE BlogOption SET CollectionsMenuLabel = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	WHERE CollectionsMenuLabel IS NULL
</cfquery>
<cfquery name="backfillBlogOptionMobileMenuLabel" dbtype="hql">
	UPDATE BlogOption SET MobileMenuLabel = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	WHERE MobileMenuLabel IS NULL
</cfquery>
<cfset menuMigrationBlog = entityLoadByPK("Blog", 1)>
<cfif isObject(menuMigrationBlog)
		and arrayLen(ormExecuteQuery("FROM MenuLink WHERE BlogRef = :blogId", { blogId = menuMigrationBlog.getBlogId() })) eq 0
		and not isNull(menuMigrationBlog.getBlogParentSiteName()) and len(trim(menuMigrationBlog.getBlogParentSiteName()))
		and not isNull(menuMigrationBlog.getBlogParentSiteUrl()) and len(trim(menuMigrationBlog.getBlogParentSiteUrl()))>
	<cfset menuMigrationLink = entityNew("MenuLink")>
	<cfset menuMigrationLink.setBlogRef(menuMigrationBlog.getBlogId())>
	<cfset menuMigrationLink.setLabel(trim(menuMigrationBlog.getBlogParentSiteName()))>
	<cfset menuMigrationLink.setLinkUrl(trim(menuMigrationBlog.getBlogParentSiteUrl()))>
	<cfset menuMigrationLink.setNewWindow(false)>
	<cfset menuMigrationLink.setSortOrder(1)>
	<cfset menuMigrationLink.setDate(now())>
	<cfset entitySave(menuMigrationLink)>
</cfif>
<cfset menuMigrationDocsCollections = ormExecuteQuery("FROM PageCollection WHERE CollectionAlias LIKE 'docs-%'")>
<cfif arrayLen(menuMigrationDocsCollections)>
	<cfloop array="#menuMigrationDocsCollections#" index="menuMigrationCollection">
		<cfif isNull(menuMigrationCollection.getShowInMenu()) or not menuMigrationCollection.getShowInMenu()>
			<cfset menuMigrationCollection.setShowInMenu(true)>
			<cfset entitySave(menuMigrationCollection)>
		</cfif>
	</cfloop>
	<cfquery name="nameDocsMenu" dbtype="hql">
		UPDATE BlogOption SET CollectionsMenuLabel = <cfqueryparam value="Docs" cfsqltype="cf_sql_varchar">
		WHERE CollectionsMenuLabel IS NULL OR CollectionsMenuLabel = <cfqueryparam value="" cfsqltype="cf_sql_varchar">
	</cfquery>
</cfif>
