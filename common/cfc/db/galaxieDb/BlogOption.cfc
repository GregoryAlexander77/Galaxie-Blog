<cfcomponent displayName="BlogOption" persistent="true" table="BlogOption" output="no" hint="ORM logic for the new BlogOption table">
	
	<cfproperty name="BlogOptionId" fieldtype="id" generator="native" setter="false">
	<!--- There are many blog options for every blog record. --->
	<!--- Multiple ORM database error occurs below --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<cfproperty name="JQueryCDNPath" ormtype="string" length="225" default="https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js">
	<cfproperty name="KendoCommercial" ormtype="boolean" default="false">
	<cfproperty name="KendoFolderPath" ormtype="string" length="225" default="">
	<cfproperty name="DeferKendoCommercialOnPublicSite" ormtype="boolean" default="true">
	<cfproperty name="DeferScriptsAndCss" ormtype="boolean" default="true">
	<cfproperty name="UseSsl" ormtype="boolean" default="true">
	<cfproperty name="ServerRewriteRuleInPlace" ormtype="boolean" default="false">	
	<cfproperty name="MinimizeCode" ormtype="boolean" default="true">
	<cfproperty name="DisableCache" ormtype="boolean" default="false">
	<cfproperty name="EntriesPerBlogPage" ormtype="int" default="10">
	<cfproperty name="DefaultImageQuality" ormtype="float" default="0.8" hint="Site-wide default for the image-upload compression slider (0.1-1.0, matching cfimage's own quality attribute range) - pre-fills the per-upload slider in enclosureImageEditor.cfm, which can still be adjusted per image. Only meaningful for lossy formats (jpg/webp) - a no-op for png/gif.">
	<cfproperty name="VideoMaxFileSizeMB" ormtype="int" default="100" hint="Rejects an enclosure video upload over this size (ProxyController.cfc's uploadVideo). Was a hardcoded 100MB constant - moved here so each site can tune it without a code change.">
	<cfproperty name="UseCaptcha" ormtype="boolean" default="true">
	<cfproperty name="AllowGravatar" ormtype="boolean" default="true">
	<cfproperty name="BlogModerated" ormtype="boolean" default="true">
	<cfproperty name="LogVisitors" ormtype="boolean" default="true">
	<cfproperty name="MonthsToRetainVisitorLog" ormtype="integer" default="true">
	<cfproperty name="MonthsToRetainAdminLog" ormtype="integer" default="true">
	<cfproperty name="SendDiagnostics" ormtype="boolean" default="true">
	<cfproperty name="BackgroundImageResolution" ormtype="string" length="35" default="LowRes" hint="Either 'HiRes', 'MedRes', or 'LowRes'. LowRes is default.">
	<cfproperty name="IncludeGsap" ormtype="boolean" default="false">
	<cfproperty name="IncludeDisqus" ormtype="boolean" default="true">
	<cfproperty name="DefaultMediaPlayer" ormtype="string" length="35" default="Plyr" hint="Either 'Plyr' or 'KendoUi'. Plyr is default.">
	<cfproperty name="GoogleAnalyticsString" ormtype="string"  length="900" default="">
	<cfproperty name="AddThisApiKey" ormtype="string" length="75" default="">
	<!--- Add this is depracated --->
	<cfproperty name="AddThisToolboxString" ormtype="string" length="75" default="">
	<cfproperty name="BingMapsApiKey" ormtype="string" length="100" default="">
	<cfproperty name="AzureMapsApiKey" ormtype="string" length="100" default="">
	<cfproperty name="DisqusBlogIdentifier" ormtype="string" length="75" default="">
	<cfproperty name="DisqusApiKey" ormtype="string" length="75" default="">
	<cfproperty name="DisqusApiSecret" ormtype="string" length="75" default="">
	<cfproperty name="DisqusAuthTokenKey" ormtype="string" length="75" default="">
	<cfproperty name="DisqusAuthUrl" ormtype="string" length="255" default="https://disqus.com/api/oauth/2.0/authorize/">
	<cfproperty name="DisqusAuthTokenUrl" ormtype="string" length="255" default="https://disqus.com/api/oauth/2.0/access_token/">
	<cfproperty name="FacebookAppId" ormtype="string"  length="75" default="">
	<cfproperty name="TwitterAppId" ormtype="string"  length="75" default="">
	<!--- What shows at the site root - independently toggled, additive sections (Configure Homepage), stacked in a fixed order: Featured Pages, then Featured Collections, then recent Blog Posts. EXCEPTION: if HomepageShowPages is true and HomepagePageIdList has exactly ONE page, that Page's own full content becomes the ENTIRE homepage instead (no other sections render) - the admin's explicit call, since a single curated page and "here are several featured things" are different intents. This replaced an earlier single-mode-radio design (latestPosts/page/collection) - that never shipped to any real site, so there is no old data to migrate. --->
	<cfproperty name="HomepageShowPages" ormtype="boolean" default="false">
	<cfproperty name="HomepagePageIdList" ormtype="string" length="500" default="" hint="Comma separated, ORDERED list of PostIds - only meaningful when HomepageShowPages is true. Exactly one entry means that Page's full content IS the homepage; two or more means each renders as a card in the Featured Pages section, in this order.">
	<cfproperty name="HomepageShowCollections" ormtype="boolean" default="false">
	<cfproperty name="HomepageCollectionIdList" ormtype="string" length="500" default="" hint="Comma separated, ORDERED list of PageCollectionIds - the Featured Collections section, in this order. Only meaningful when HomepageShowCollections is true.">
	<cfproperty name="HomepageShowBlogPosts" ormtype="boolean" default="true" hint="Shows a fixed, non-paginated set of the most recent blog posts (EntriesPerBlogPage worth) with a 'View All Posts' link - not a curated pick like Pages/Collections, just an on/off switch. Defaults true so a fresh/default blog behaves like the original latestPosts-only homepage.">
	<!--- What renders in place of noImage.jpg for a post with no enclosure image, at the call sites that used to hardcode noImage.jpg (renderKendoCardGrid.cfm, popularPosts.cfm, cardGridSection.cfm) plus the single-post hero (Renderer.cfc's renderEnclosure, which previously rendered nothing at all when a post had no enclosure). 'generic' keeps today's behavior unchanged at every call site. 'generated' shows a deterministic, per-post CSS/SVG gradient hero (Image.cfc's generateHeroArt), seeded off PostId so it never changes on an edit. 'pool' shows either a single image or a rotating carousel (see HeroPoolDisplayMode) drawn from HeroImagePoolCarouselRef below, deterministically picked by PostId - falls back to 'generated' if the pool has no items yet, or if the calling context can't render a carousel widget at all (see getHeroFallbackHtml's allowHtml argument). 'animation' shows a live animated background (currently Vanta.js, see AnimationEffect/AnimationOptions below - renamed from 'vanta'/VantaEffect/VantaOptions 2026-10-03, while still dev-only/unmigrated, so the value isn't tied to one specific rendering library) - but ONLY on a post's own single-post page, never in a card/grid context and never on mobile (a continuous WebGL/canvas render loop is too expensive to ever show more than one at a time); every other context falls back to 'generated' instead, same fallthrough idiom 'pool' already uses. 'none' shows no image area at all, at every call site. --->
	<cfproperty name="NoImageFallbackMode" ormtype="string" length="20" default="generic" hint="'generic' (today's noImage.jpg / nothing), 'generated' (per-post CSS/SVG gradient art), 'pool' (single image or rotating carousel from HeroImagePoolCarouselRef), 'animation' (live animated background, single-post desktop only - see AnimationEffect/AnimationOptions), or 'none' (no image area at all).">
	<!--- The blog's single, reusable pool of hero photos for NoImageFallbackMode='pool' - a normal Carousel/CarouselItem pair (same entities and same admin editor as a Post's own enclosure carousel), just owned by BlogOption instead of a Post/PageCollection. Created lazily on first use, not at install time. --->
	<cfproperty name="HeroImagePoolCarouselRef" ormtype="int" fieldtype="many-to-one" cfc="Carousel" fkcolumn="HeroImagePoolCarouselRef" missingRowIgnored="true">
	<!--- How many images from the pool above show per post in 'pool' mode, when HeroPoolDisplayMode='carousel' (ignored for 'single', which always shows exactly one) - a single site-wide number (moved here from a per-theme ThemeSetting field per feedback: a per-theme count would need its own "copy this setting" handling whenever a theme is duplicated, which isn't worth it for one number). --->
	<cfproperty name="HeroCarouselImageCount" ormtype="int" default="1">
	<!--- 'carousel' (default, today's behavior - a real Swiper carousel widget, HeroCarouselImageCount images) or 'single' (one deterministically-picked pool image, rendered as a plain <img> - no Swiper CSS/JS/markup at all, so it also works in contexts that can't render a widget, like cardGridSection.cfm's homepage grid, the same way 'generated' mode already does). --->
	<cfproperty name="HeroPoolDisplayMode" ormtype="string" length="20" default="carousel" hint="'carousel' (Swiper widget, HeroCarouselImageCount images) or 'single' (one plain image, no carousel machinery).">
	<!--- The site-wide default effect + options for NoImageFallbackMode='animation', used whenever a post hasn't
	picked its own HeroAnimationEffect override (see Post.cfc). AnimationEffect is one of 'WAVES'/'NET'/'RINGS'/
	'CLOUDS' (TOPOLOGY was dropped 2026-09-30 - a real upstream vanta.js bug, see heroAnimationEditor.cfm's
	header comment) - these are Vanta's own effect names, out of scope for this rename. AnimationOptions is a
	raw JSON string of that effect's color/speed parameters, set via heroAnimationEditor.cfm (window 79)
	launched from Blog Options' "Configure Animation Defaults" button, same shape as the per-post override.
	2026-10-03: renamed from VantaEffect/VantaOptions while still dev-only/unmigrated. --->
	<cfproperty name="AnimationEffect" ormtype="string" length="20" default="">
	<!--- 5.0 (2026-10-19): how a post's image, gradient and animated hero is shown on its own page. 'classic' as in 4.8 (inside
	the post, below the title), or drawn by the scene engine (common/js/galaxieScene.js), full width and fading into the post:
	'held' (full screen, held while the text rises and fades), 'band' (three quarters of the screen, scrolls away) or
	'magazine' (full screen, a large heading low on the left). A post can pick its own (Post.HeroStyle). Carousels, maps and
	videos are the same in every style. See Renderer.cfc getPostHeroStyle. --->
	<cfproperty name="PostHeroStyle" ormtype="string" length="20" default="classic">
	<!--- 5.0 (2026-10-19): the Site Wizard (admin/setup.cfm, common/cfc/Setup.cfc). SetupStepsDone lists the screens saved
	(site, look, logo, about, home, starter); SetupFinished is when the owner pressed Done. A blog that has been through the
	About screen shows the owner's own biography in the Bio window instead of the built-in text. --->
	<cfproperty name="SetupStepsDone" ormtype="string" length="200" default="">
	<cfproperty name="SetupFinished" ormtype="string" length="30" default="">
	<cfproperty name="SetupHomeLayout" ormtype="string" length="20" default="">
	<cfproperty name="AnimationOptions" ormtype="string" length="1000" default="">
	<!--- 2026-10-10 (4.8): top menu labels, set in the admin site's Configure Menu window. Blank uses the default.
	CollectionsMenuLabel names the dropdown listing the Page Collections marked Show in Menu (default "Collections").
	MobileMenuLabel names the single dropdown that combines Categories and Collections on phones (default "Explore"). --->
	<cfproperty name="CollectionsMenuLabel" ormtype="string" length="50" default="">
	<cfproperty name="MobileMenuLabel" ormtype="string" length="50" default="">
	<!--- 2026-10-12: what happens when a blog post is saved as released (Blog Options, Subscriber Email). 'prompt' (the
	default, also used when this is empty) asks whether to email the subscribers each time a released post is saved; 'auto'
	emails them the first time the post is saved as released. A post scheduled for a later date is always emailed when it
	goes live, whatever this is set to. See blog.cfc's getReleasedPostEmailMode(). --->
	<cfproperty name="ReleasedPostEmailMode" ormtype="string" length="10" default="prompt">
	<cfproperty name="Date" ormtype="timestamp">

</cfcomponent>