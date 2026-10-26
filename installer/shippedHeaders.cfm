<!--- Solid header colors for the built-in themes (5.0, 2026-10-26, owner). Included by installer/insertData.cfm once the themes are
in, so only a NEW install gets them; an upgraded blog's themes stay as they were.

26 of the 30 built-in themes start with a solid header (Themes > Customize > Header > Style: A solid color) in a deep color taken
from the theme's own picture, chosen to go with its Kendo buttons, and a site name color to suit (the menu text uses it too). Each
also starts with its own sample logo mark (images/logo/themes, 48 pixels, made from images/logo/samples) beside the theme's site
name, and the same mark at twice the size in the footer (footer.cfm siteFooterMark), until the owner picks a logo in the Site
Wizard (which then goes on every theme).
Delicate Arch, Golden Gate, Joshua Tree and Abstract Blue keep their header pictures. Mock-up: test/headerColorIdeas.html.

The header style is kept in the blog's settings (Events setSetting, the same as ThemeEditor.setHeaderStyle). application.events
doesn't exist yet while the installer runs (Application.cfc makes it after insertData.cfm), so a copy of Events.cfc is made here.
A failure is logged and skipped: the themes then simply keep their header pictures. --->
<cfset shippedHeaders = {
	"Abstract Red" = ["##7a0d16", "##ffffff", "club-flame-ring"],
	"Antelope Canyon" = ["##5a2416", "##fbe3c8", "tech-sunrise-orbit"],
	"Bahama Bank" = ["##0e3b4a", "##ffffff", "outdoors-wave-circle"],
	"Blue Planet" = ["##14263f", "##ffffff", "tech-planet"],
	"Blue Wave" = ["##283a6e", "##ffffff", "outdoors-sailboat"],
	"Blue Wave Dark" = ["##121a2e", "##c5cae9", "personal-moon-star"],
	"Bootstrap" = ["##2a6496", "##ffffff", "business-rising-arrows"],
	"Cobalt" = ["##1c3d6e", "##ffffff", "tech-network"],
	"Cumberland Falls" = ["##2f4a2a", "##f1f6ea", "outdoors-waterfall"],
	"Flair" = ["##4a0f3d", "##ffffff", "personal-heart"],
	"Grand Teton" = ["##34433a", "##eef2ea", "outdoors-mountains"],
	"Ice" = ["##0b4a8a", "##ffffff", "business-crescent-wave"],
	"Mountain Road" = ["##3b4a24", "##f4f1e4", "travel-map-pin"],
	"Mukilteo" = ["##1f3a52", "##ffffff", "travel-compass"],
	"On the ranch" = ["##6e2a14", "##f7efe4", "home-house"],
	"Orion" = ["##3b1b3f", "##ffffff", "personal-galaxy"],
	"Pillars Of Creation" = ["##1d2733", "##e9d8b4", "tech-hex-flame"],
	"Porofino" = ["##12504f", "##ffffff", "travel-plane"],
	"Redwood Drive" = ["##4a2a1c", "##f3e7d6", "outdoors-forest"],
	"Snow" = ["##1d3557", "##ffffff", "outdoors-tree"],
	"Spectrum" = ["##2b2d33", "##ffffff", "business-ribbon-strokes"],
	"Sunrise" = ["##6b2a17", "##ffe3b8", "food-coffee"],
	"Tropical Wave" = ["##0d4f52", "##ffffff", "health-lotus"],
	"Wood Creek" = ["##2e3f2a", "##f2efe2", "outdoors-leaf"],
	"Yellowstone" = ["##2a2f36", "##f4af03", "personal-phoenix"],
	"Zion" = ["##6a2e1f", "##fbe9d7", "outdoors-sun-cloud"]
}>
<!--- Abstract Blue (the theme a new install starts on) keeps its header picture, and starts with the orange-flame hex mark (owner,
2026-10-26: tech-hex-flame recolored with the coffee cup's orange) beside its site name. --->
<!--- Delicate Arch, Golden Gate and Joshua Tree also keep their header pictures and start with a mark (owner, 2026-10-26). --->
<cfset shippedLogos = { "Abstract Blue" = "tech-hex-flame-orange", "Delicate Arch" = "personal-camera", "Golden Gate" = "personal-aperture", "Joshua Tree" = "outdoors-sprout" }>
<cfset shippedHeadersSet = 0>
<cftry>
	<cfset shippedHeaderEvents = createObject("component", len(application.baseProxyUrl) ? application.baseComponentPath & ".common.cfc.Events" : "common.cfc.Events")>
	<cfloop collection="#shippedHeaders#" item="shippedHeaderTheme">
		<cfset shippedHeaderRows = ormExecuteQuery("SELECT t.ThemeId, t.ThemeSettingRef.ThemeSettingId FROM Theme t WHERE t.ThemeName = :name", { name = shippedHeaderTheme })>
		<cfif arrayLen(shippedHeaderRows)>
			<cfset ormExecuteQuery("UPDATE ThemeSetting SET HeaderBackgroundColor = :header, BlogNameTextColor = :nameColor, LogoImage = :logo, LogoImageMobile = :logo, FooterImage = :logo, DisplayBlogName = :showName WHERE ThemeSettingId = :id",
				{ header = shippedHeaders[shippedHeaderTheme][1], nameColor = shippedHeaders[shippedHeaderTheme][2], logo = "/images/logo/themes/" & shippedHeaders[shippedHeaderTheme][3] & ".svg", showName = true, id = shippedHeaderRows[1][2] })>
			<cfset shippedHeaderEvents.setSetting(0, "themeHeaderStyle_" & shippedHeaderRows[1][1], "color")>
			<cfset shippedHeadersSet++>
		</cfif>
	</cfloop>
	<cfloop collection="#shippedLogos#" item="shippedHeaderTheme">
		<cfset shippedHeaderRows = ormExecuteQuery("SELECT t.ThemeId, t.ThemeSettingRef.ThemeSettingId FROM Theme t WHERE t.ThemeName = :name", { name = shippedHeaderTheme })>
		<cfif arrayLen(shippedHeaderRows)>
			<cfset ormExecuteQuery("UPDATE ThemeSetting SET LogoImage = :logo, LogoImageMobile = :logo, FooterImage = :logo, DisplayBlogName = :showName WHERE ThemeSettingId = :id",
				{ logo = "/images/logo/themes/" & shippedLogos[shippedHeaderTheme] & ".svg", showName = true, id = shippedHeaderRows[1][2] })>
		</cfif>
	</cfloop>
	<cfcatch type="any">
		<cflog file="galaxieBlogErrors" type="error" text="Installer: the built-in themes' solid headers couldn't be set (they keep their header pictures): #cfcatch.message#">
	</cfcatch>
</cftry>
<cfif isDefined("debug") and debug><cfoutput>Solid headers set on #shippedHeadersSet# built-in themes.<br/></cfoutput></cfif>
