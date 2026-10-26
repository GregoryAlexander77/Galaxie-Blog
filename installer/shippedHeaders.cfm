<!--- Solid header colors for the built-in themes (5.0, 2026-10-26, owner). Included by installer/insertData.cfm once the themes are
in, so only a NEW install gets them; an upgraded blog's themes stay as they were.

26 of the 30 built-in themes start with a solid header (Themes > Customize > Header > Style: A solid color) in a deep color taken
from the theme's own picture, chosen to go with its Kendo buttons, and a site name color to suit (the menu text uses it too).
Delicate Arch, Golden Gate, Joshua Tree and Abstract Blue keep their header pictures. Mock-up: test/headerColorIdeas.html.

The header style is kept in the blog's settings (Events setSetting, the same as ThemeEditor.setHeaderStyle). application.events
doesn't exist yet while the installer runs (Application.cfc makes it after insertData.cfm), so a copy of Events.cfc is made here.
A failure is logged and skipped: the themes then simply keep their header pictures. --->
<cfset shippedHeaders = {
	"Abstract Red" = ["##7a0d16", "##ffffff"],
	"Antelope Canyon" = ["##5a2416", "##fbe3c8"],
	"Bahama Bank" = ["##0e3b4a", "##ffffff"],
	"Blue Planet" = ["##14263f", "##ffffff"],
	"Blue Wave" = ["##283a6e", "##ffffff"],
	"Blue Wave Dark" = ["##121a2e", "##c5cae9"],
	"Bootstrap" = ["##2a6496", "##ffffff"],
	"Cobalt" = ["##1c3d6e", "##ffffff"],
	"Cumberland Falls" = ["##2f4a2a", "##f1f6ea"],
	"Flair" = ["##4a0f3d", "##ffffff"],
	"Grand Teton" = ["##34433a", "##eef2ea"],
	"Ice" = ["##0b4a8a", "##ffffff"],
	"Mountain Road" = ["##3b4a24", "##f4f1e4"],
	"Mukilteo" = ["##1f3a52", "##ffffff"],
	"On the ranch" = ["##6e2a14", "##f7efe4"],
	"Orion" = ["##3b1b3f", "##ffffff"],
	"Pillars Of Creation" = ["##1d2733", "##e9d8b4"],
	"Porofino" = ["##12504f", "##ffffff"],
	"Redwood Drive" = ["##4a2a1c", "##f3e7d6"],
	"Snow" = ["##1d3557", "##ffffff"],
	"Spectrum" = ["##2b2d33", "##ffffff"],
	"Sunrise" = ["##6b2a17", "##ffe3b8"],
	"Tropical Wave" = ["##0d4f52", "##ffffff"],
	"Wood Creek" = ["##2e3f2a", "##f2efe2"],
	"Yellowstone" = ["##2a2f36", "##f4af03"],
	"Zion" = ["##6a2e1f", "##fbe9d7"]
}>
<cfset shippedHeadersSet = 0>
<cftry>
	<cfset shippedHeaderEvents = createObject("component", len(application.baseProxyUrl) ? application.baseComponentPath & ".common.cfc.Events" : "common.cfc.Events")>
	<cfloop collection="#shippedHeaders#" item="shippedHeaderTheme">
		<cfset shippedHeaderRows = ormExecuteQuery("SELECT t.ThemeId, t.ThemeSettingRef.ThemeSettingId FROM Theme t WHERE t.ThemeName = :name", { name = shippedHeaderTheme })>
		<cfif arrayLen(shippedHeaderRows)>
			<cfset ormExecuteQuery("UPDATE ThemeSetting SET HeaderBackgroundColor = :header, BlogNameTextColor = :nameColor WHERE ThemeSettingId = :id",
				{ header = shippedHeaders[shippedHeaderTheme][1], nameColor = shippedHeaders[shippedHeaderTheme][2], id = shippedHeaderRows[1][2] })>
			<cfset shippedHeaderEvents.setSetting(0, "themeHeaderStyle_" & shippedHeaderRows[1][1], "color")>
			<cfset shippedHeadersSet++>
		</cfif>
	</cfloop>
	<cfcatch type="any">
		<cflog file="galaxieBlogErrors" type="error" text="Installer: the built-in themes' solid headers couldn't be set (they keep their header pictures): #cfcatch.message#">
	</cfcatch>
</cftry>
<cfif isDefined("debug") and debug><cfoutput>Solid headers set on #shippedHeadersSet# built-in themes.<br/></cfoutput></cfif>
