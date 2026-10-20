<!--- description: Galaxie 5.0: adds the columns for the post hero text, glow and hero styles, the carousel text shadow, the post hero style in Blog Options and the Site Setup wizard, and creates the Scenes tables. --->
<!--- The work is done by DatabaseUpdater.cfc's ensureColumns(), which adds only the columns that are missing (ORM may already have
added them when the blog restarted with the new files). --->
<cfset ensureColumns("Post", [
	{ name: "HeroOverlaySubText", length: 500 },
	{ name: "HeroOverlayFontSizePhone", length: 10 },
	{ name: "HeroOverlayShadow", length: 20 },
	{ name: "HeroOverlayShadowColor", length: 20 },
	{ name: "HeroOverlayGlowColor", length: 20 },
	{ name: "HeroOverlayGlowOpacity", length: 10 },
	{ name: "HeroOverlayGlowSoftness", length: 10 },
	{ name: "HeroStyle", length: 20 }
])>
<cfset ensureColumns("Carousel", [
	{ name: "CarouselTextShadow", length: 20 },
	{ name: "CarouselTextShadowColor", length: 20 }
])>
<cfset ensureColumns("BlogOption", [
	{ name: "PostHeroStyle", length: 20 },
	{ name: "SetupStepsDone", length: 200 },
	{ name: "SetupFinished", length: 30 },
	{ name: "SetupHomeLayout", length: 20 }
])>
<!--- Scenes (Scene, SceneSection, SceneLayer, SceneSetting, SceneTemplate): Scenes.cfc creates its tables the first time it is
used, so listing the scenes makes sure they exist now. --->
<cfset application.blog.getScenes().listScenes()>
<cfset addToLog("The Scenes tables are in place.")>
