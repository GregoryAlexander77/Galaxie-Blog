<cfcomponent displayName="PageCollection" persistent="true" table="PageCollection" output="no"
		hint="A themed index that links out to two or more Pages, e.g. a Portfolio or a Services section. Deliberately lightweight - no body, no date, no author, no comments; membership is decided from the Page side (see PageCollectionMemberLookup, managed directly via blog.cfc rather than an ORM many-to-many, since Post's own Categories/Tags many-to-many properties are inverse=true on both sides and silently do not persist through entity setters in this codebase).">
	<cfproperty name="PageCollectionId" fieldtype="id" generator="native" setter="false">
	<!--- Many page collections for one blog. No cascade - Blog is a shared/independent row that must never be deleted or re-saved as a side effect of dissolving a PageCollection (deleting one with cascade="all" here threw "deleted object would be re-saved by cascade: [Blog#1]"). --->
	<cfproperty name="BlogRef" ormtype="int" fieldtype="many-to-one" cfc="Blog" fkcolumn="BlogRef">
	<cfproperty name="Title" ormtype="string" length="125" default="">
	<!--- Its own address, e.g. /blog/portfolio. Only reachable while it has 2+ members - see application.blog.getPageCollectionVisibility(). --->
	<cfproperty name="CollectionAlias" ormtype="string" length="100" default="">
	<!--- Its only real content field - no body, matching a Page Collection's deliberately minimal shape. --->
	<cfproperty name="Description" ormtype="string" length="1250" default="">
	<!--- Legacy plain-string hero image, kept for existing rows/callers - superseded by the real Media-backed
	EnclosureMedia below for anything new. --->
	<cfproperty name="HeroImageUrl" ormtype="string" length="500" default="">
	<!--- A freeform CSS linear/radial-gradient() string (built via the Insert/Edit Gradient popup - see
	gradientEditor.cfm) as a third hero option alongside HeroImageUrl and the Media/Map/Carousel enclosures below.
	Optional overlay title text and its color, rendered centered over the gradient - see admin/loadPreview.cfm's
	previewId=2 case and the public hero renderer for the priority order these are checked in. --->
	<cfproperty name="HeroGradient" ormtype="string" length="1000" default="">
	<cfproperty name="HeroOverlayText" ormtype="string" length="500" default="">
	<cfproperty name="HeroOverlayTextColor" ormtype="string" length="20" default="">
	<!--- Full Post Enclosure/Media system parity (image, video, map, carousel) - same shape as Post's own
	EnclosureMedia/EnclosureMap/EnclosureCarousel below, just pointed at PageCollectionRef instead of PostRef. --->
	<cfproperty name="EnclosureMedia" singularname="Enclosure" ormtype="int" fieldtype="many-to-one" cfc="Media" fkcolumn="EnclosureMediaRef" inversejoincolumn="PageCollectionRef" inverse="true" cascade="all" missingRowIgnored="true">
	<cfproperty name="EnclosureMap" ormtype="int" fieldtype="many-to-one" cfc="Map" fkcolumn="EnclosureMapRef" inversejoincolumn="PageCollectionRef" inverse="true" cascade="all" missingRowIgnored="true">
	<cfproperty name="EnclosureCarousel" ormtype="int" fieldtype="many-to-one" cfc="Carousel" fkcolumn="EnclosureCarouselRef" inversejoincolumn="PageCollectionRef" inverse="true" cascade="all" missingRowIgnored="true">
	<!--- Governs only this Collection's own listing/array view - member Pages keep their own independent theme when viewed directly. Same "no relationship, avoid a required constraint" reasoning as Post.ThemeRef. Defaults to the blog's current default theme at creation time (set in code, not here) and is refined afterward in Configure Page Collections, not chosen up front. --->
	<cfproperty name="ThemeRef" ormtype="int" default="0">
	<!--- When set, this Collection is a pure cross-link (e.g. gregoryalexander.com/blog linking to the companion
	galaxieblog.org docs site) - makeCollectionLink() returns this instead of the internal member-listing page, and
	visiting the Collection's own alias directly redirects here too. Only needs 1 member page to be visible/usable,
	not 2 - the 2-page minimum exists to stop a Collection being used as a disguised single-page icon, which doesn't
	apply to a deliberate external pointer. --->
	<cfproperty name="ExternalUrl" ormtype="string" length="500" default="">
	<cfproperty name="MenuOrder" ormtype="int" default="0" hint="Order of this collection in the top menu's collections menu. Lower numbers come first.">
	<!--- 2026-10-10 (4.8): the collection is listed in the top menu's collections menu (labelled by
	BlogOption.CollectionsMenuLabel). Replaces the old hard-coded rule that listed every collection whose alias started
	with "docs-" under a menu called "Docs". --->
	<cfproperty name="ShowInMenu" ormtype="boolean" default="false">
	<cfproperty name="Created" ormtype="timestamp">
</cfcomponent>
