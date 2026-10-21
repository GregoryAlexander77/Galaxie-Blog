<!--- description: Galaxie 5.0: adds the columns for the post hero text, glow and hero styles, the carousel text shadow, the post hero style in Blog Options and the Site Setup wizard, creates the Scenes and shop tables, and turns background pictures back on for themes that have one. --->
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
<!--- The shop (2026-10-20): Product, ShopOrder and ShopOrderItem. ORM also adds Payment.ShopOrderRef when it creates them. The shop
stays closed until the owner switches it on in Blog Options. --->
<cfset ensureOrmTables("Product,ShopOrder,ShopOrderItem")>
<!--- Background pictures (2026-10-20): a theme with no background picture, or with "show background pictures" switched off,
shows a plain page, and nothing on the old Themes screen made that easy to spot (the owner found Snow like this on
galaxieblog.org: switched off while testing, and its picture gone). Every built-in theme ships with its picture on, so:
1. a built-in theme with no background picture gets the one it was installed with (installer/dataFiles/getThemeSetting.txt),
   as WebP when the server serves WebP and the file is there, as the installer does;
2. every theme with a background picture has pictures switched on.
Either can be changed again in Themes > Customize > Background. HQL, so the boolean is right on every database. --->
<cfset backgroundsRestored = 0>
<cftry>
	<cffile action="read" file="#expandPath(application.baseUrl & '/installer/dataFiles/getThemeSetting.txt')#" variable="themeSettingWddx">
	<cfwddx action="wddx2cfml" input="#themeSettingWddx#" output="shippedThemeSettings">
	<cfloop query="shippedThemeSettings">
		<cfset shippedPicture = shippedThemeSettings.BlogBackgroundImage>
		<cfset shippedMobile = shippedThemeSettings.BlogBackgroundImageMobile>
		<cfif len(shippedPicture)>
			<cfif isDefined("application.serverSupportsWebP") and application.serverSupportsWebP>
				<cfset webpPicture = reReplaceNoCase(shippedPicture, "\.(png|jpg)$", ".webp")>
				<cfset webpMobile = reReplaceNoCase(shippedMobile, "\.(png|jpg)$", ".webp")>
				<cfif fileExists(expandPath(application.baseUrl & webpPicture))><cfset shippedPicture = webpPicture></cfif>
				<cfif len(shippedMobile) and fileExists(expandPath(application.baseUrl & webpMobile))><cfset shippedMobile = webpMobile></cfif>
			</cfif>
			<cfset missing = ormExecuteQuery("SELECT t.ThemeSettingRef.ThemeSettingId FROM Theme t WHERE t.ThemeName = :name AND (t.ThemeSettingRef.BlogBackgroundImage IS NULL OR t.ThemeSettingRef.BlogBackgroundImage = '')", { name = shippedThemeSettings.ThemeName })>
			<cfif arrayLen(missing)>
				<cfset ormExecuteQuery("UPDATE ThemeSetting SET BlogBackgroundImage = :picture, BlogBackgroundImageMobile = :mobile WHERE ThemeSettingId = :id", { picture = shippedPicture, mobile = len(shippedMobile) ? shippedMobile : shippedPicture, id = missing[1] })>
				<cfset backgroundsRestored++>
			</cfif>
		</cfif>
	</cfloop>
	<cfcatch type="any">
		<cfset addToLog("The built-in background pictures couldn't be read, so none were put back: " & cfcatch.message)>
	</cfcatch>
</cftry>
<cfset backgroundsOff = ormExecuteQuery("SELECT count(*) FROM ThemeSetting WHERE IncludeBackgroundImages = :off AND BlogBackgroundImage IS NOT NULL AND BlogBackgroundImage <> ''", { off = false }, true)>
<cfif backgroundsOff gt 0>
	<cfset ormExecuteQuery("UPDATE ThemeSetting SET IncludeBackgroundImages = :on WHERE IncludeBackgroundImages = :off AND BlogBackgroundImage IS NOT NULL AND BlogBackgroundImage <> ''", { on = true, off = false })>
</cfif>
<cfif backgroundsRestored or backgroundsOff><cfset application.blog.flushGalaxieCache(type = "all")></cfif>
<cfset addToLog("Background pictures: #backgroundsRestored# put back, #backgroundsOff# switched back on.")>
<!--- The settings file (2026-10-20): blogs installed before 4.9 kept the installer's copy of the administrator's password and
security answers in blog.ini.cfm. The administrator is saved with a hashed password, so the copies are emptied here (the
installer has done this itself since 2026-10-12). --->
<cfif structKeyExists(application, "blogIniPath") and fileExists(application.blogIniPath)>
	<cfset clearedIniKeys = 0>
	<!--- Blog Settings keeps the datasource password on the same line (password), so a value that matches the blog's saved
	datasource password is the owner's and stays. --->
	<cfset savedDsnPassword = isNull(application.BlogDbObj.getBlogDsnPassword()) ? "" : application.BlogDbObj.getBlogDsnPassword()>
	<cfloop list="password,securityAnswer1,securityAnswer2,securityAnswer3" index="iniKey">
		<cfif len(getProfileString(application.blogIniPath, "default", iniKey)) and not (iniKey eq "password" and len(savedDsnPassword) and getProfileString(application.blogIniPath, "default", iniKey) eq savedDsnPassword)>
			<cfset setProfileString(application.blogIniPath, "default", iniKey, "")>
			<cfset clearedIniKeys++>
		</cfif>
	</cfloop>
	<cfset addToLog("Settings file: #clearedIniKeys# leftover installer value(s) cleared.")>
</cfif>
