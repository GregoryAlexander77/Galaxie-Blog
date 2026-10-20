<cfcomponent displayName="ThemeEditor" output="false" hint="The Themes window's saves (Galaxie 5, 2026-10-20): admin/adminInterface/themeEditor.cfm (window 110), through ProxyController.cfc saveThemeEditor. Picking the theme in use, a theme's look with a live preview, the site's own pictures (the same in every theme) and the site's custom code.">

<!---
	A theme's look is sent and kept with the same names that blog.cfc getTheme() returns (ContentWidth, FontId, KendoThemeId...),
	so a draft can be laid over getTheme()'s result for the preview without translating anything. Only the names in
	variables.lookFields are ever read; anything else that arrives is ignored, and a value out of range or of the wrong kind is
	dropped (left as it was) rather than refused, so one odd old value never stops the rest from saving.

	The preview: the window sends the draft on every change (saveDraft keeps it in the session), then reloads its preview frame
	with ?previewTheme=<alias>&previewLook=1. blog.cfc getSelectedThemeAlias() shows that theme to a signed-in user, getTheme()
	lays the draft over it, and index.cfm turns the page caches off for that request. Visitors never see a draft.
--->

<cfset variables.lookFields = {
	"KendoThemeId" = { kind = "kendo" },
	"Breakpoint" = { kind = "choice", options = "0,1300" },
	"ContentWidth" = { kind = "int", min = 30, max = 100 },
	"MainContainerWidth" = { kind = "int", min = 40, max = 85 },
	"SideBarContainerWidth" = { kind = "int", min = 15, max = 60 },
	"SiteOpacity" = { kind = "int", min = 75, max = 99 },
	"AlignBlogMenuWithBlogContent" = { kind = "bool" },
	"StretchHeaderAcrossPage" = { kind = "bool" },
	"FontId" = { kind = "font" },
	"FontSize" = { kind = "int", min = 8, max = 24 },
	"FontSizeMobile" = { kind = "int", min = 8, max = 24 },
	"MenuFontId" = { kind = "font" },
	"BlogNameFontId" = { kind = "font" },
	"BlogNameFontSize" = { kind = "int", min = 12, max = 80 },
	"BlogNameFontSizeMobile" = { kind = "int", min = 10, max = 60 },
	"BlogNameTextColor" = { kind = "colour" },
	"DisplayBlogName" = { kind = "bool" },
	"IncludeBackgroundImages" = { kind = "bool" },
	"BlogBackgroundImage" = { kind = "picture" },
	"BlogBackgroundImageMobile" = { kind = "picture" },
	"BlogBackgroundColor" = { kind = "colour" },
	"BlogBackgroundImagePosition" = { kind = "choice", options = "center center|center top|center bottom|50% 25%|left top|left bottom", delimiter = "|" },
	"BlogBackgroundImageRepeat" = { kind = "choice", options = "no-repeat,repeat,repeat-x,repeat-y" },
	"HeaderBackgroundImage" = { kind = "picture" },
	"HeaderBodyDividerImage" = { kind = "picture" },
	"MenuBackgroundImage" = { kind = "picture" },
	"TopMenuAlign" = { kind = "choice", options = "left,center,right" },
	"CoverKendoMenuWithMenuBackgroundImage" = { kind = "bool" }
}>

<!--- The site's own pictures (Branding): the same in every theme. --->
<cfset variables.brandFields = {
	"logo" = { column = "LogoImage", folder = "logo", name = "site-logo" },
	"logoMobile" = { column = "LogoImageMobile", folder = "logo", name = "site-logo-mobile" },
	"social" = { column = "DefaultLogoImageForSocialMediaShare", folder = "logo", name = "site-social" },
	"footer" = { column = "FooterImage", folder = "footer", name = "site-footer" }
}>

<!--- A theme's own pictures (Customize), and the folder an uploaded one goes in. --->
<cfset variables.pictureFolders = {
	"BlogBackgroundImage" = "background", "BlogBackgroundImageMobile" = "background",
	"HeaderBackgroundImage" = "header", "HeaderBodyDividerImage" = "divider", "MenuBackgroundImage" = "header"
}>

<!--- The content the Content tab lists, in the order shown. --->
<cfset variables.contentNames = "aboutWindow,bioWindow,downloadWindow,compositeFooter,navigationMenu,subscribePod,recentPostsPod,recentCommentsPod,categoriesPod,monthlyArchivesPod,blogPostCalendarPod,upcomingEventsPod,downloadPod,cfblogsFeedPod">

<cffunction name="fail" access="private" returntype="void" output="false">
	<cfargument name="message" type="string" required="true">
	<cfthrow type="GalaxieBlog.ThemeEditor" message="#arguments.message#">
</cffunction>

<!---//*****************************************************************************************************
		Reading
//******************************************************************************************************--->

<cffunction name="getThemeList" access="public" returntype="array" output="false" hint="Every theme with its look, for the gallery and the editor: an array of structs keyed like getTheme(), plus ThemeAlias, ThemeName and UseTheme.">
	<cfset var rows = ormExecuteQuery("SELECT ThemeId FROM Theme ORDER BY ThemeName")>
	<cfset var list = []>
	<cfset var themeId = "">
	<cfset var data = "">
	<cfset var themeObj = "">
	<cfloop array="#rows#" index="themeId">
		<cfset data = application.blog.getTheme(themeId = themeId)>
		<cfif arrayLen(data)>
			<cfset themeObj = entityLoadByPK("Theme", themeId)>
			<cfset data[1]["ThemeAlias"] = themeObj.getThemeAlias()>
			<cfset data[1]["ThemeName"] = themeObj.getThemeName()>
			<cfset arrayAppend(list, data[1])>
		</cfif>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="getContentList" access="public" returntype="array" output="false" hint="The content the Content tab lists: each template's name, whether it is shown, and which themes have the owner's own text (an empty ThemeRef is every theme).">
	<cfset var list = []>
	<cfset var name = "">
	<cfset var active = "">
	<cfset var themes = "">
	<cfset var everyTheme = false>
	<cfset var row = "">
	<cfloop list="#variables.contentNames#" index="name">
		<cfset active = ormExecuteQuery("SELECT Active FROM ContentTemplate WHERE ContentTemplateName = :name", { name = name })>
		<cfset themes = queryExecute("
			SELECT co.ThemeRef FROM ContentOutput co JOIN ContentTemplate ct ON ct.ContentTemplateId = co.ContentTemplateRef
			WHERE ct.ContentTemplateName = :name AND ((co.ContentOutput IS NOT NULL AND " & lenFunction() & "(co.ContentOutput) > 0)
				OR (co.ContentOutputMobile IS NOT NULL AND " & lenFunction() & "(co.ContentOutputMobile) > 0))",
			{ name = { value = name, cfsqltype = "cf_sql_varchar" } }, { datasource = application.dsn })>
		<cfset everyTheme = false>
		<cfset row = 0>
		<cfloop query="themes">
			<cfif not len(themes.ThemeRef)><cfset everyTheme = true><cfelse><cfset row++></cfif>
		</cfloop>
		<cfset arrayAppend(list, {
			"name" = name,
			"shown" = arrayLen(active) ? (isBoolean(active[1]) ? active[1] : true) : true,
			"everyTheme" = everyTheme,
			"themeCount" = row
		})>
	</cfloop>
	<cfreturn list>
</cffunction>

<cffunction name="lenFunction" access="private" returntype="string" output="false" hint="The database's length function for long text: DATALENGTH on SQL Server (LEN can't take ntext), LENGTH elsewhere.">
	<cfreturn (application.databaseType ?: "") eq "sqlServer" ? "DATALENGTH" : "LENGTH">
</cffunction>

<cffunction name="getCustomCode" access="public" returntype="struct" output="false" hint="The site's custom code: what goes in the page header and at the end of every page. Taken from the theme in use (or the first theme), and whether every theme has the same.">
	<cfset var settings = entityLoad("ThemeSetting")>
	<cfset var selected = ormExecuteQuery("SELECT ThemeSettingRef.ThemeSettingId FROM Theme WHERE SelectedTheme = 1")>
	<cfset var source = "">
	<cfset var setting = "">
	<cfset var heads = {}>
	<cfset var tails = {}>
	<cfset var icons = {}>
	<cfloop array="#settings#" index="setting">
		<cfif arrayLen(selected) and setting.getThemeSettingId() eq selected[1]><cfset source = setting></cfif>
		<cfset heads[hash(setting.getCustomHeaderHtml() ?: "")] = true>
		<cfset tails[hash(setting.getTailEndScripts() ?: "")] = true>
		<cfset icons[hash(setting.getFavIconHtml() ?: "")] = true>
	</cfloop>
	<cfif not isObject(source) and arrayLen(settings)><cfset source = settings[1]></cfif>
	<cfreturn {
		"head" = isObject(source) ? (source.getCustomHeaderHtml() ?: "") : "",
		"tail" = isObject(source) ? (source.getTailEndScripts() ?: "") : "",
		"favicon" = isObject(source) ? (source.getFavIconHtml() ?: "") : "",
		"same" = structCount(heads) lte 1 and structCount(tails) lte 1 and structCount(icons) lte 1
	}>
</cffunction>

<!---//*****************************************************************************************************
		The theme in use
//******************************************************************************************************--->

<cffunction name="useTheme" access="public" returntype="void" output="false" hint="Makes this theme the site's theme. themeId 0 picks none, so the site shows a different theme each day.">
	<cfargument name="themeId" type="numeric" required="true">
	<cfset var themeObj = "">
	<cfif arguments.themeId gt 0>
		<cfset themeObj = entityLoadByPK("Theme", arguments.themeId)>
		<cfif isNull(themeObj)><cfset fail("That theme isn't there any more.")></cfif>
	</cfif>
	<cftransaction>
		<cfquery dbtype="hql">UPDATE Theme SET SelectedTheme = 0 WHERE SelectedTheme = 1</cfquery>
		<cfif arguments.themeId gt 0>
			<cfquery dbtype="hql">UPDATE Theme SET SelectedTheme = 1, UseTheme = 1 WHERE ThemeId = <cfqueryparam value="#arguments.themeId#" cfsqltype="cf_sql_integer"></cfquery>
		</cfif>
	</cftransaction>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<!---//*****************************************************************************************************
		A theme's look
//******************************************************************************************************--->

<cffunction name="cleanLook" access="public" returntype="struct" output="false" hint="Only the look fields this editor knows, each checked. A value that doesn't pass is left out.">
	<cfargument name="look" type="struct" required="true">
	<cfset var clean = {}>
	<cfset var key = "">
	<cfset var field = "">
	<cfset var value = "">
	<cfloop collection="#variables.lookFields#" item="key">
		<cfif structKeyExists(arguments.look, key)>
			<cfset field = variables.lookFields[key]>
			<cfset value = isSimpleValue(arguments.look[key]) ? trim(arguments.look[key]) : "">
			<cfswitch expression="#field.kind#">
				<cfcase value="int">
					<cfif isNumeric(value) and value gte field.min and value lte field.max><cfset clean[key] = int(value)></cfif>
				</cfcase>
				<cfcase value="bool">
					<cfif isBoolean(value)><cfset clean[key] = value ? true : false></cfif>
				</cfcase>
				<cfcase value="choice">
					<cfif listFind(field.options, value, field.delimiter ?: ",")><cfset clean[key] = value></cfif>
				</cfcase>
				<cfcase value="colour">
					<cfif value eq "" or reFindNoCase("^(##[0-9a-f]{3,8}|rgba?\([0-9., %]+\)|[a-z]{3,20})$", value)><cfset clean[key] = value></cfif>
				</cfcase>
				<cfcase value="picture">
					<!--- A theme picture is a path in the blog's images folder (the base URL is added when the page is drawn). --->
					<cfif value eq "" or (reFind("^/images/[A-Za-z0-9_\-./ ]+\.(jpg|jpeg|png|gif|webp|svg)$", value) and not find("..", value))><cfset clean[key] = value></cfif>
				</cfcase>
				<cfcase value="font">
					<cfif isNumeric(value) and arrayLen(application.blog.getFont(fontId = value))><cfset clean[key] = int(value)></cfif>
				</cfcase>
				<cfcase value="kendo">
					<cfif isNumeric(value) and not isNull(entityLoadByPK("KendoTheme", int(value)))><cfset clean[key] = int(value)></cfif>
				</cfcase>
			</cfswitch>
		</cfif>
	</cfloop>
	<cfreturn clean>
</cffunction>

<cffunction name="saveLook" access="public" returntype="void" output="false" hint="Saves a theme's look (the fields in variables.lookFields), then drops the preview draft and the theme's cached pages.">
	<cfargument name="themeId" type="numeric" required="true">
	<cfargument name="look" type="struct" required="true">
	<cfset var clean = cleanLook(arguments.look)>
	<cfset var themeObj = entityLoadByPK("Theme", arguments.themeId)>
	<cfset var setting = "">
	<cfset var kendoObj = "">
	<cfset var key = "">
	<cfif isNull(themeObj)><cfset fail("That theme isn't there any more.")></cfif>
	<cfset setting = themeObj.getThemeSettingRef()>
	<cftransaction>
		<cfloop collection="#clean#" item="key">
			<cfswitch expression="#key#">
				<cfcase value="KendoThemeId">
					<cfset kendoObj = entityLoadByPK("KendoTheme", clean[key])>
					<cfset themeObj.setKendoThemeRef(kendoObj)>
					<cfset themeObj.setDarkTheme(kendoObj.getDarkTheme() ? true : false)>
				</cfcase>
				<cfcase value="FontId"><cfset setting.setFontRef(entityLoadByPK("Font", clean[key]))></cfcase>
				<cfcase value="MenuFontId"><cfset setting.setMenuFontRef(clean[key])></cfcase>
				<cfcase value="BlogNameFontId"><cfset setting.setBlogNameFontRef(clean[key])></cfcase>
				<cfdefaultcase>
					<!--- The rest are ThemeSetting columns of the same name (only the names above can get here). --->
					<cfinvoke component="#setting#" method="set#key#">
						<cfinvokeargument name="#key#" value="#clean[key]#">
					</cfinvoke>
				</cfdefaultcase>
			</cfswitch>
		</cfloop>
		<cfset setting.setDate(application.blog.blogNow())>
		<cfset entitySave(setting)>
		<cfset entitySave(themeObj)>
	</cftransaction>
	<cfset ormFlush()>
	<cfset clearDraft()>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<!---//*****************************************************************************************************
		The preview draft
//******************************************************************************************************--->

<cffunction name="saveDraft" access="public" returntype="void" output="false" hint="Keeps the look being edited in the session for the preview frame. Never saved to the database.">
	<cfargument name="themeId" type="numeric" required="true">
	<cfargument name="look" type="struct" required="true">
	<cfset session.themeEditorDraft = { themeId = arguments.themeId, look = cleanLook(arguments.look) }>
</cffunction>

<cffunction name="clearDraft" access="public" returntype="void" output="false">
	<cfset structDelete(session, "themeEditorDraft")>
</cffunction>

<cffunction name="isPreviewRequest" access="public" returntype="boolean" output="false" hint="True when this request is the Themes window's preview frame: a signed-in user, with previewTheme in the address.">
	<cfreturn isDefined("url.previewTheme") and isSimpleValue(url.previewTheme) and reFind("^[A-Za-z0-9_\-]{1,100}$", url.previewTheme)
		and structKeyExists(application, "Udf") and application.Udf.isLoggedIn()>
</cffunction>

<cffunction name="applyDraft" access="public" returntype="array" output="false" hint="getTheme()'s result with the preview draft laid over it, when this request is the preview of that theme with previewLook=1. Otherwise the result unchanged.">
	<cfargument name="data" type="array" required="true">
	<cfset var draft = "">
	<cfset var key = "">
	<cfset var row = "">
	<cfset var font = "">
	<cfset var kendoObj = "">
	<cfif not arrayLen(arguments.data) or not isDefined("url.previewLook") or not isPreviewRequest()
			or not structKeyExists(session, "themeEditorDraft") or session.themeEditorDraft.themeId neq arguments.data[1]["ThemeId"]>
		<cfreturn arguments.data>
	</cfif>
	<cfset draft = session.themeEditorDraft.look>
	<cfset row = arguments.data[1]>
	<cfloop collection="#draft#" item="key">
		<cfset row[key] = draft[key]>
	</cfloop>
	<!--- The names and types that come with an id. --->
	<cfif structKeyExists(draft, "FontId")>
		<cfset font = application.blog.getFont(fontId = draft.FontId)>
		<cfif arrayLen(font)><cfset row["Font"] = font[1]["Font"]><cfset row["FontType"] = font[1]["FontType"]></cfif>
	</cfif>
	<cfif structKeyExists(draft, "MenuFontId")>
		<cfset font = application.blog.getFont(fontId = draft.MenuFontId)>
		<cfif arrayLen(font)><cfset row["MenuFont"] = font[1]["Font"]><cfset row["MenuFontType"] = font[1]["FontType"]></cfif>
	</cfif>
	<cfif structKeyExists(draft, "BlogNameFontId")>
		<cfset font = application.blog.getFont(fontId = draft.BlogNameFontId)>
		<cfif arrayLen(font)><cfset row["BlogNameFont"] = font[1]["Font"]><cfset row["BlogNameFontType"] = font[1]["FontType"]></cfif>
	</cfif>
	<cfif structKeyExists(draft, "KendoThemeId")>
		<cfset kendoObj = entityLoadByPK("KendoTheme", draft.KendoThemeId)>
		<cfset row["KendoTheme"] = kendoObj.getKendoTheme()>
		<cfset row["DarkTheme"] = kendoObj.getDarkTheme()>
		<cfset row["KendoCommonCssFileLocation"] = kendoObj.getKendoCommonCssFileLocation()>
		<cfset row["KendoThemeCssFileLocation"] = kendoObj.getKendoThemeCssFileLocation()>
		<cfset row["KendoThemeMobileCssFileLocation"] = kendoObj.getKendoThemeMobileCssFileLocation()>
	</cfif>
	<cfif structKeyExists(draft, "Breakpoint")>
		<cfset row["ModernThemeStyle"] = draft.Breakpoint eq 0 ? 1 : 0>
	</cfif>
	<cfreturn arguments.data>
</cffunction>

<!---//*****************************************************************************************************
		Pictures
//******************************************************************************************************--->

<cffunction name="decodeDataUrl" access="private" returntype="struct" output="false" hint="A base64 data URL as { ext, bytes }.">
	<cfargument name="dataUrl" type="string" required="true">
	<cfset var m = reFind("^data:(image/(svg\+xml|png|gif|jpeg|webp));base64,(.+)$", trim(arguments.dataUrl), 1, true)>
	<cfset var types = { "svg+xml" = "svg", "png" = "png", "gif" = "gif", "jpeg" = "jpg", "webp" = "webp" }>
	<cfif not m.pos[1]><cfset fail("That file isn't a picture. Please use a PNG, GIF, JPG, WebP or SVG.")></cfif>
	<cfreturn { ext = types[mid(trim(arguments.dataUrl), m.pos[3], m.len[3])], bytes = binaryDecode(mid(trim(arguments.dataUrl), m.pos[4], m.len[4]), "base64") }>
</cffunction>

<cffunction name="writePicture" access="private" returntype="string" output="false" hint="Writes an uploaded picture to images/<folder>/ and returns its theme path (/images/<folder>/<file>).">
	<cfargument name="dataUrl" type="string" required="true">
	<cfargument name="folder" type="string" required="true">
	<cfargument name="name" type="string" required="true">
	<cfargument name="maxMb" type="numeric" required="false" default="4">
	<cfset var picture = decodeDataUrl(arguments.dataUrl)>
	<cfset var directory = expandPath(application.baseUrl & "/images/" & arguments.folder)>
	<cfset var fileName = arguments.name & "-" & dateTimeFormat(now(), "yyyymmddHHnnss") & "." & picture.ext>
	<cfif arrayLen(picture.bytes) gt arguments.maxMb * 1024 * 1024><cfset fail("That picture is larger than #arguments.maxMb# MB. Please use a smaller one.")></cfif>
	<cfif picture.ext eq "svg">
		<cfset var svg = toString(picture.bytes, "utf-8")>
		<cfif not reFindNoCase("^\s*(<\?xml[^>]*>\s*)?<svg[\s>]", svg) or reFindNoCase("<script|<foreignObject|<iframe|<embed|<object|\son[a-z]+\s*=|javascript:|<!ENTITY", svg)>
			<cfset fail("That SVG has content a picture can't have (scripts or embedded pages). Please use a plain SVG, or a PNG.")>
		</cfif>
	</cfif>
	<cfif not directoryExists(directory)><cfdirectory action="create" directory="#directory#"></cfif>
	<cffile action="write" file="#directory#/#fileName#" output="#picture.bytes#">
	<cfreturn "/images/" & arguments.folder & "/" & fileName>
</cffunction>

<cffunction name="saveThemePicture" access="public" returntype="string" output="false" hint="An uploaded background, header, divider or menu picture for the editor. Only written to disk; it becomes the theme's when the owner saves the look. Returns its theme path.">
	<cfargument name="field" type="string" required="true">
	<cfargument name="dataUrl" type="string" required="true">
	<cfif not structKeyExists(variables.pictureFolders, arguments.field)><cfset fail("A theme has no picture called that.")></cfif>
	<cfreturn writePicture(arguments.dataUrl, variables.pictureFolders[arguments.field], "own-" & lCase(arguments.field), 8)>
</cffunction>

<cffunction name="saveBrandPicture" access="public" returntype="string" output="false" hint="The site's logo, mobile logo, social media picture or footer picture: written to disk and set on EVERY theme, so it stays when the theme changes. An empty dataUrl clears it. Returns the full address of the new picture.">
	<cfargument name="kind" type="string" required="true" hint="logo, logoMobile, social or footer">
	<cfargument name="dataUrl" type="string" required="true">
	<cfset var field = "">
	<cfset var path = "">
	<cfif not structKeyExists(variables.brandFields, arguments.kind)><cfset fail("The site has no picture called that.")></cfif>
	<cfset field = variables.brandFields[arguments.kind]>
	<cfif len(arguments.dataUrl)>
		<cfset path = writePicture(arguments.dataUrl, field.folder, field.name, 4)>
	</cfif>
	<cfquery dbtype="hql">
		UPDATE ThemeSetting SET #field.column# = <cfqueryparam value="#path#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfset application.blog.flushGalaxieCache(type = "all")>
	<cfreturn len(path) ? application.baseUrl & path : "">
</cffunction>

<!---//*****************************************************************************************************
		Content and custom code
//******************************************************************************************************--->

<cffunction name="setContentShown" access="public" returntype="void" output="false" hint="Shows or hides a window, pod, the menu or the footer (ContentTemplate.Active) - in every theme, as the old Themes screen did.">
	<cfargument name="name" type="string" required="true">
	<cfargument name="shown" type="boolean" required="true">
	<cfif not listFind(variables.contentNames, arguments.name)><cfset fail("There's no content called that.")></cfif>
	<cfquery dbtype="hql">
		UPDATE ContentTemplate SET Active = <cfqueryparam value="#arguments.shown#" cfsqltype="cf_sql_bit">
		WHERE ContentTemplateName = <cfqueryparam value="#arguments.name#" cfsqltype="cf_sql_varchar">
	</cfquery>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

<cffunction name="saveCustomCode" access="public" returntype="void" output="false" hint="The site's custom code, in every theme: head goes in each page's header, tail at the end of each page, favicon is the browser icon's tags (in the header too, on every page including the admin). Both arrive with script, style and meta tags renamed (bypassScriptProtection in blogJsContent.cfm), and are put back here.">
	<cfargument name="head" type="string" required="true">
	<cfargument name="tail" type="string" required="true">
	<cfargument name="favicon" type="string" required="false" default="">
	<cfset var stringUtils = createObject("component", application.stringUtilsComponentPath)>
	<cfset var headCode = len(trim(arguments.head)) ? stringUtils.sanitizeStrForDb(arguments.head) : "">
	<cfset var tailCode = len(trim(arguments.tail)) ? stringUtils.sanitizeStrForDb(arguments.tail) : "">
	<cfset var faviconCode = len(trim(arguments.favicon)) ? stringUtils.sanitizeStrForDb(arguments.favicon) : "">
	<cfif len(headCode) gt 5000 or len(tailCode) gt 5000><cfset fail("Custom code can be up to 5,000 characters in each box.")></cfif>
	<cfif len(faviconCode) gt 2000><cfset fail("The browser icon tags can be up to 2,000 characters.")></cfif>
	<cfquery dbtype="hql">
		UPDATE ThemeSetting
		SET CustomHeaderHtml = <cfqueryparam value="#headCode#" cfsqltype="cf_sql_varchar">,
			CustomHeaderHtmlApplyAcrossThemes = 1,
			TailEndScripts = <cfqueryparam value="#tailCode#" cfsqltype="cf_sql_varchar">,
			TailEndScriptsApplyAcrossThemes = 1,
			FavIconHtml = <cfqueryparam value="#faviconCode#" cfsqltype="cf_sql_varchar">,
			FavIconHtmlApplyAcrossThemes = 1
	</cfquery>
	<cfset application.blog.flushGalaxieCache(type = "all")>
</cffunction>

</cfcomponent>
