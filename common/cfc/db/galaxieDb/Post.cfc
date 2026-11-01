<cfcomponent displayName="Post" persistent="true" table="Post" output="no" hint="ORM logic for the new Post table">
	<cfproperty name="PostId" fieldtype="id" generator="native" setter="false">
	<!--- Many posts for one blog. --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef" cascade="all">
	<!--- UserRef is the db key to attach a post to a user (right now the person that created the post) --->
	<cfproperty name="UserRef" ormtype="int" fieldtype="many-to-one" cfc="Users" fkcolumn="UserRef" cascade="all">
	
	<!--- There can many posts that have one enclosure (from the media table). Generally, this is a one to one relationship, but many posts can share the same image. --->
	<cfproperty name="EnclosureMedia" singularname="Enclosure" ormtype="int" fieldtype="many-to-one" cfc="Media" fkcolumn="EnclosureMediaRef" inversejoincolumn="PostRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- There can be many posts to one map. If there was a unique map for every post, this would be a one to one relationship. However, many posts don't have maps (where there would be multipe nulls) and many posts can share the same map. --->
	<cfproperty name="EnclosureMap" ormtype="int" fieldtype="many-to-one" cfc="Map" fkcolumn="EnclosureMapRef" inversejoincolumn="PostRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- There can be many posts to one carousel. If there was a unique carousel for every post, this would be a one to one relationship. However, many posts don't have carousels (where there would be multipe nulls) and many posts can share the same carousel. --->
	<cfproperty name="EnclosureCarousel" ormtype="int" fieldtype="many-to-one" cfc="Carousel" fkcolumn="EnclosureCarouselRef" inversejoincolumn="PostRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- A freeform CSS linear/radial-gradient() string (built via the Insert/Edit Gradient popup - see
	gradientEditor.cfm) as an alternative hero/enclosure option alongside EnclosureMedia/Map/Carousel above.
	Optional overlay title text, its color, and (2026-10-01) its font, rendered centered over the gradient - see
	Renderer.cfc's renderMediaPreview()/renderEnclosure() for the priority order these are checked in relative to
	the other enclosure types. Same shape as PageCollection.cfc's own HeroGradient/HeroOverlayText/
	HeroOverlayTextColor (that one doesn't have HeroOverlayFont yet - Page Collections are out of scope for the
	font picker for now, same as they are for the live animation). HeroOverlayText/HeroOverlayTextColor/
	HeroOverlayFont are shared with HeroAnimation below, not duplicated per hero type - only one hero type is
	ever active on a post at a time (see savePostHeroGradient()/savePostHeroAnimation() in
	org/camden/blog/blog.cfc), so whichever one is
	currently picked owns these three columns. HeroOverlayFont is a font NAME (matches a Font.Font value from
	application.blog.getThemeFonts()), not a file path - the actual @font-face CSS comes from
	includes/templates/font.cfm, same font-serving mechanism tinyMce.cfm's own font picker already uses. --->
	<cfproperty name="HeroGradient" ormtype="string" length="1000" default="">
	<cfproperty name="HeroOverlayText" ormtype="string" length="500" default="">
	<cfproperty name="HeroOverlayTextColor" ormtype="string" length="20" default="">
	<cfproperty name="HeroOverlayFont" ormtype="string" length="100" default="">
	<!--- 2026-10-03: the pixel size of HeroOverlayText, stored as digits only (eg. "26"), empty meaning "use
	whichever default the render call site already falls back to" - same empty-string-means-unset convention as
	HeroOverlayFont above. A string, not an int, for the same reason HeroOverlayTextColor is a string: this gets
	built straight into an inline style="font-size:...px" attribute at render time, never arithmetic on its own,
	and a string sidesteps ORM needing a non-empty numeric default for "not set yet". Shared with HeroAnimation
	below, same as every other HeroOverlay* column. --->
	<cfproperty name="HeroOverlayFontSize" ormtype="string" length="10" default="">
	<!--- 5.0 (2026-10-19, owner): more for the hero's text, on image, gradient and animated heroes alike. A second line under
	the heading; the heading size on phones (digits, like HeroOverlayFontSize; empty = scaled down from it); and a shadow
	behind the text - none, soft, strong or glow - in a color of its own (empty = black, or the text color for glow). --->
	<cfproperty name="HeroOverlaySubText" ormtype="string" length="500" default="">
	<cfproperty name="HeroOverlayFontSizePhone" ormtype="string" length="10" default="">
	<cfproperty name="HeroOverlayShadow" ormtype="string" length="20" default="">
	<cfproperty name="HeroOverlayShadowColor" ormtype="string" length="20" default="">
	<!--- 5.0 (2026-10-19, owner): a glow around the text, on its own or with the shadow above: its color (empty = no glow),
	opacity (10-100, percent) and softness (how far it spreads, 4-60 px). --->
	<cfproperty name="HeroOverlayGlowColor" ormtype="string" length="20" default="">
	<cfproperty name="HeroOverlayGlowOpacity" ormtype="string" length="10" default="">
	<cfproperty name="HeroOverlayGlowSoftness" ormtype="string" length="10" default="">
	<!--- 5.0 (2026-10-19, owner): how this post's image, gradient or animated hero is shown on its own page - classic, held,
	band or magazine (Renderer.cfc getPostHeroStyle); empty uses the blog's choice (BlogOption.PostHeroStyle). --->
	<cfproperty name="HeroStyle" ormtype="string" length="20" default="">
	<!--- A live animated background (currently rendered via Vanta.js, see heroAnimationEditor.cfm) as another
	alternative hero/enclosure option, alongside EnclosureMedia/Map/Carousel and HeroGradient above. Named
	generically (not after Vanta specifically) so the rendering library can change later without a column
	rename - 2026-10-03, renamed from HeroVantaEffect/HeroVantaOptions while still dev-only/unmigrated, the
	cheapest time to do it. HeroAnimationEffect is one of 'WAVES'/'NET'/'RINGS'/'CLOUDS' (TOPOLOGY was dropped
	2026-09-30 - a real upstream vanta.js bug, see heroAnimationEditor.cfm's header comment) - these are
	Vanta's own effect names, out of scope for this rename. HeroAnimationOptions is a raw JSON string of that
	effect's color/speed parameters, parsed only client-side. Mutually exclusive with HeroGradient - as of
	2026-10-01 both savePostHeroAnimation() and savePostHeroGradient() SET the shared HeroOverlayText/
	HeroOverlayTextColor/HeroOverlayFont columns above from their own form (previously savePostHeroAnimation()
	only ever cleared them) - whichever hero type was saved most recently owns the current overlay values (see
	org/camden/blog/blog.cfc). Only ever rendered live on a post's own single-post page (never in a card/grid
	context or on mobile) - see Renderer.cfc's renderEnclosure()/getHeroFallbackHtml(). --->
	<cfproperty name="HeroAnimationEffect" ormtype="string" length="20" default="">
	<cfproperty name="HeroAnimationOptions" ormtype="string" length="1000" default="">
	<!--- 2026-10-01: a static uploaded photo shown on cards/listings and used to drive the social-media share
	images (og:image/twitter:image), for a post whose hero is Gradient/the live animation/the auto-generated
	fallback art - none of which have a real photo to show on a card or share to social media. Orthogonal to
	HeroGradient/HeroAnimationEffect above (not mutually exclusive with either - savePostHeroCoverImage() in
	blog.cfc never touches those fields), and never used on the post's own single-post page, where the real
	Gradient/animation keeps rendering live regardless - see Renderer.cfc's renderMediaPreview()/card-grid templates (which DO use
	this) vs. renderEnclosure()/getHeroFallbackHtml() (which deliberately don't). Replaces the old per-post
	practice of hand-typing <facebookImageUrlMetaData:...>/<twitterImageUrlMetaData:...> XML Post Directives
	into the Post Header field for this exact purpose (see seoMetaTags.cfm) - a manually-typed directive, if one
	still exists on an older post, still wins over this for backward compatibility. --->
	<cfproperty name="HeroCoverImageUrl" ormtype="string" length="500" default="">
	<!--- The PostAssests column below is a psuedo column that is used by this object. The PostMedia table is our link table. There are many posts with many different types of media (images and video) --->
	<cfproperty name="PostAssets" singularname="PostAsset" ormtype="int" fieldtype="one-to-many" cfc="PostMedia" fkcolumn="PostRef" inversejoincolumn="MediaRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- A post can either be embedded into an external page or the blog --->
	<cfproperty name="IsPage" ormtype="boolean" default="false">
	<cfproperty name="IsBlogPost" ormtype="boolean" default="false">
	<!--- Psuedo column that will not be placed into the actual database. We are using the PostCategoryLookup table as an intermediatory table to store the many to many relationships between a post and a category.  --->
	<cfproperty name="Categories" singularname="Category" ormtype="int" fieldtype="many-to-many" cfc="Category" fkcolumn="PostRef" inversejoincolumn="CategoryRef" inverse="true" linktable="PostCategoryLookup" type="array" cascade="all" missingRowIgnored="true">
	<!--- Psuedo column that will not be placed into the actual database. We are using the PostTagLookup table as an intermediatory table to store the many to many relationships between a post and a tag.  --->
	<cfproperty name="Tags" singularname="Tag" ormtype="int" fieldtype="many-to-many" cfc="Tag" fkcolumn="PostRef" inversejoincolumn="TagRef" inverse="true" linktable="PostTagLookup" type="array" cascade="all" missingRowIgnored="true">
	<!--- A psuedo column to determine related posts. --->
	<cfproperty name="RelatedPosts" singularname="RelatedPost" ormtype="int" fieldtype="many-to-many" cfc="Post" fkcolumn="PostRef" inversejoincolumn="RelatedPostRef" inverse="true" linktable="RelatedPost" type="array" missingRowIgnored="true">
	<cfproperty name="Comments" singularname="Comment" ormtype="int" fieldtype="one-to-many" cfc="Comment" fkcolumn="PostRef" type="array" inverse="true" missingRowIgnored="true">
	<!--- The ThemeRef is optional. I am not going to make a relationship here as it will make a required constraint. --->
	<cfproperty name="ThemeRef" ormtype="int" default="0">
	<cfproperty name="PostUuid" ormtype="string" length="35" default="">
	<cfproperty name="PostAlias" ormtype="string" length="100" default="">
	<cfproperty name="Title" ormtype="string" length="125" default="">
	<cfproperty name="Description" ormtype="string" length="1250" default="This should be set to a length of 160 in the future">
	<!--- SEO Stuff (I will break this into it's own table in a future version) --->
	<cfproperty name="NoIndex" ormtype="boolean" default="false">
	<cfproperty name="DisplayOnRss" ormtype="boolean" default="true">
	<cfproperty name="CanonicalURL" ormtype="string" length="1000" default="">
	<!--- Long text column. The type of this column is different for each database, so Application.cfc rewrites it to match the database that the blog was installed on (see /common/cfc/DatabaseOrmTypes.cfc). This file is shipped set up for SQL Server. --->
	<cfproperty name="JsonLd" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="PostHeader" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="CSS" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="JavaScript" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="Body" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="MoreBody" ormtype="string" sqltype="varchar(max)" default="">
	<cfproperty name="Released" ormtype="boolean" default="false">
	<cfproperty name="Promote" ormtype="boolean" default="false">
	<cfproperty name="AllowComment" ormtype="boolean" default="true">
	<cfproperty name="Remove" ormtype="boolean" default="false">
	<cfproperty name="RedirectUrl" ormtype="string" length="250" default="" hint="A post can be redirected when removed">
	<cfproperty name="RedirectType" ormtype="string" length="35" default="" hint="Either permanent or tempoary">
	<cfproperty name="NumViews" ormtype="int" default="0">
	<cfproperty name="Mailed" ormtype="boolean" default="false">
	<cfproperty name="BlogSortDate" ormtype="timestamp" hint="This is used change the sort order of the articles on the main blog.">
	<cfproperty name="DatePosted" ormtype="timestamp">
	<!--- We need an actual date property without the timestamp for the date search. --->
	<cfproperty name="Date" ormtype="date">

</cfcomponent>