<cfcomponent displayName="Scenes" output="false" hint="Galaxie 5 scenes in the database (2026-10-19, phase 3): the scrolling heroes built by common/js/galaxieScene.js. Tables Scene, SceneSection and SceneLayer, created on first use (DatabaseUpdater.createTableIfMissing). Created on first use by blog.cfc getScenes(). A post shows a scene with <galaxieScene>alias</galaxieScene> in its header (Renderer.renderScene). Design: doc/aiDraftArticles/parallaxScenesDesign.cfm.">

<!---
	The scene JSON handed to the engine is put together as a string from the stored JSON, rather than with serializeJSON on a
	struct: Adobe ColdFusion can upper-case struct keys when it serializes, and the engine needs "kind", "sections" and so on
	exactly as written. Strings and numbers going in are still passed through serializeJSON, so they are always escaped.

	Tables:
	  Scene         SceneId, BlogRef, Name, Alias, PageColour, SettingsJson, Active, Created, Updated
	  SceneSection  SceneSectionId, SceneRef, SortOrder, Kind, Heading, Html, DataJson (everything else about the section:
	                colours, gradient, fonts, shadow, overlay, pictures, Vanta options... - new look options need no new column)
	  SceneLayer    SceneLayerId, SceneSectionRef, SortOrder, Src, SrcPhone, Depth
--->

<cfset variables.kinds = "text,imageSlide,layeredHero,photoHero,vantaHero,gradientHero,videoHero">

<!---//*****************************************************************************************************
		Reading
//******************************************************************************************************--->

<cffunction name="getSceneJson" access="public" returntype="string" output="false"
		hint="The scene with this alias as the JSON the engine reads, or an empty string when there is no such active scene.">
	<cfargument name="alias" type="string" required="true">
	<cfargument name="activeOnly" type="boolean" required="false" default="true" hint="False for the editor, which also opens inactive scenes.">
	<cfset var scene = "">
	<cfset var sections = "">
	<cfset var layers = "">
	<cfset var parts = []>
	<cfset var layerParts = []>
	<cfset var sectionJson = "">
	<cfset var extra = "">
	<cfif not reFind("^[A-Za-z0-9_-]{1,80}$", arguments.alias)>
		<cfreturn "">
	</cfif>
	<cfset ensureTables()>
	<cfset scene = queryExecute("SELECT SceneId, Name, PageColour, SettingsJson FROM Scene WHERE BlogRef = :blogId AND Alias = :alias" & (arguments.activeOnly ? " AND Active = 1" : ""),
		{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" }, alias = { value = arguments.alias, cfsqltype = "cf_sql_varchar" } })>
	<cfif not scene.recordCount>
		<cfreturn "">
	</cfif>
	<cfset sections = queryExecute("SELECT SceneSectionId, Kind, Heading, Html, DataJson FROM SceneSection WHERE SceneRef = :sceneId ORDER BY SortOrder, SceneSectionId",
		{ sceneId = { value = scene.SceneId, cfsqltype = "cf_sql_integer" } })>
	<cfloop query="sections">
		<cfset layerParts = []>
		<cfif sections.Kind eq "layeredHero">
			<cfset layers = queryExecute("SELECT Src, SrcPhone, Depth FROM SceneLayer WHERE SceneSectionRef = :sectionId ORDER BY SortOrder, SceneLayerId",
				{ sectionId = { value = sections.SceneSectionId, cfsqltype = "cf_sql_integer" } })>
			<cfloop query="layers">
				<cfset arrayAppend(layerParts, '{"src":' & serializeJSON(toString(layers.Src))
					& (len(layers.SrcPhone) ? ',"srcPhone":' & serializeJSON(toString(layers.SrcPhone)) : '')
					& ',"depth":' & val(layers.Depth) & '}')>
			</cfloop>
		</cfif>
		<!--- The stored DataJson object, with kind, heading, html (and layers) put in front of its own keys. --->
		<cfset extra = trim(sections.DataJson ?: "")>
		<cfset extra = (len(extra) gt 2 and isJSON(extra) and left(extra, 1) eq "{") ? mid(extra, 2, len(extra) - 2) : "">
		<cfset sectionJson = '{"kind":' & serializeJSON(toString(sections.Kind))
			& ',"heading":' & serializeJSON(toString(sections.Heading ?: ""))
			& ',"html":' & serializeJSON(toString(sections.Html ?: ""))
			& (sections.Kind eq "layeredHero" ? ',"layers":[' & arrayToList(layerParts, ",") & ']' : '')
			& (len(trim(extra)) ? ',' & extra : '') & '}'>
		<cfset arrayAppend(parts, sectionJson)>
	</cfloop>
	<cfreturn '{"name":' & serializeJSON(toString(scene.Name))
		& ',"pageColour":' & serializeJSON(toString(scene.PageColour ?: ""))
		& ',"settings":' & (isJSON(scene.SettingsJson ?: "") ? scene.SettingsJson : '{}')
		& ',"sections":[' & arrayToList(parts, ",") & ']}'>
</cffunction>

<cffunction name="getEngineUrl" access="public" returntype="string" output="false"
		hint="The address of the scene engine (common/js/galaxieScene.js) with the file's last-changed time on it, so browsers fetch a changed engine instead of an old cached copy. Worked out once per application start.">
	<cfset var filePath = "">
	<cfif not structKeyExists(variables, "engineUrl")>
		<cfset filePath = expandPath(application.baseUrl & "/common/js/galaxieScene.js")>
		<cfset variables.engineUrl = application.baseUrl & "/common/js/galaxieScene.js" & (fileExists(filePath) ? "?v=" & dateTimeFormat(getFileInfo(filePath).lastModified, "yyyymmddHHnnss") : "")>
	</cfif>
	<cfreturn variables.engineUrl>
</cffunction>

<cffunction name="listScenes" access="public" returntype="query" output="false" hint="Every scene of this blog, for the Scenes window.">
	<cfset ensureTables()>
	<cfreturn queryExecute("SELECT SceneId, Name, Alias, Active, Updated FROM Scene WHERE BlogRef = :blogId ORDER BY Name",
		{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } })>
</cffunction>

<cffunction name="getScene" access="public" returntype="struct" output="false"
		hint="One scene for the Scene editor (window 107): sceneId, name, alias, active and json (the engine's JSON, with {baseUrl} left in). An empty struct when there is no such scene.">
	<cfargument name="sceneId" type="numeric" required="true">
	<cfset var scene = "">
	<cfset ensureTables()>
	<cfset scene = queryExecute("SELECT SceneId, Name, Alias, Active FROM Scene WHERE SceneId = :sceneId AND BlogRef = :blogId",
		{ sceneId = { value = arguments.sceneId, cfsqltype = "cf_sql_integer" }, blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } })>
	<cfif not scene.recordCount>
		<cfreturn {}>
	</cfif>
	<!--- getSceneJson only reads active scenes; the editor needs the scene either way. --->
	<cfreturn { sceneId: scene.SceneId, name: scene.Name, alias: scene.Alias, active: (scene.Active eq 1), json: getSceneJson(scene.Alias, false) }>
</cffunction>

<cffunction name="aliasExists" access="public" returntype="boolean" output="false">
	<cfargument name="alias" type="string" required="true">
	<cfset ensureTables()>
	<cfreturn queryExecute("SELECT SceneId FROM Scene WHERE BlogRef = :blogId AND Alias = :alias",
		{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" }, alias = { value = arguments.alias, cfsqltype = "cf_sql_varchar" } }).recordCount gt 0>
</cffunction>

<cffunction name="getStarters" access="public" returntype="array" output="false"
		hint="The ready-made scenes a new scene can start from: every includes/postContent/scenes/*.json file, as [{ key, name, order, json }], in each file's own order value, then by name. The gallery in the Scene editor.">
	<cfset var folder = expandPath(application.baseUrl & "/includes/postContent/scenes/")>
	<cfset var files = "">
	<cfset var starters = []>
	<cfset var text = "">
	<cfset var data = "">
	<cfif not directoryExists(folder)>
		<cfreturn starters>
	</cfif>
	<cfdirectory action="list" directory="#folder#" filter="*.json" name="files" sort="name asc">
	<cfloop query="files">
		<cfset text = fileRead(folder & files.name, "utf-8")>
		<cfif isJSON(text) and reFind("^[A-Za-z0-9_-]{1,80}\.json$", files.name)>
			<cfset data = deserializeJSON(text)>
			<cfset arrayAppend(starters, { "key": listFirst(files.name, "."), "name": isStruct(data) and structKeyExists(data, "name") ? data.name : listFirst(files.name, "."),
				"order": isStruct(data) and isNumeric(data.order ?: "") ? data.order : 999, "json": text })>
		</cfif>
	</cfloop>
	<!--- In the order the files give ("order"), then by name. --->
	<cfset arraySort(starters, function (a, b) { return a.order neq b.order ? (a.order lt b.order ? -1 : 1) : compareNoCase(a.name, b.name); })>
	<cfreturn starters>
</cffunction>

<cffunction name="getPostIdsUsing" access="public" returntype="array" output="false" hint="The posts and pages that show this scene (their header has <galaxieScene>alias</galaxieScene>), so their cached pages can be cleared after a save.">
	<cfargument name="alias" type="string" required="true">
	<cfset var ids = []>
	<cfset var rows = queryExecute("SELECT PostId FROM Post WHERE BlogRef = :blogId AND PostHeader LIKE :pattern",
		{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" }, pattern = { value = "%<galaxieScene>" & arguments.alias & "</galaxieScene>%", cfsqltype = "cf_sql_varchar" } })>
	<cfloop query="rows">
		<cfset arrayAppend(ids, rows.PostId)>
	</cfloop>
	<cfreturn ids>
</cffunction>

<!---//*****************************************************************************************************
		Writing
//******************************************************************************************************--->

<cffunction name="saveScene" access="public" returntype="numeric" output="false"
		hint="Saves a scene given in the engine's own shape (the JSON text of { name, pageColour, settings, sections: [...] }) under an alias, replacing its sections and layers. Returns the SceneId. Used by importJson now and by the Scene editor later. Takes the JSON text rather than a struct so that key case is kept exactly as written on every engine.">
	<cfargument name="alias" type="string" required="true">
	<cfargument name="sceneJson" type="string" required="true">
	<cfargument name="active" type="boolean" required="false" default="true" hint="An inactive scene isn't shown in posts (they show nothing, or the scene file of the same name).">
	<cfset var data = "">
	<cfset var sceneId = 0>
	<cfset var existing = "">
	<cfset var section = "">
	<cfset var sectionId = 0>
	<cfset var sortOrder = 0>
	<cfset var layerOrder = 0>
	<cfset var layer = "">
	<cfset var nowStamp = now()>
	<cfif not reFind("^[A-Za-z0-9_-]{1,80}$", arguments.alias)>
		<cfthrow type="GalaxieBlog.Scenes" message="A scene alias can only have letters, numbers, dashes and underscores.">
	</cfif>
	<cfif not isJSON(arguments.sceneJson)>
		<cfthrow type="GalaxieBlog.Scenes" message="The scene is not valid JSON.">
	</cfif>
	<cfset data = deserializeJSON(arguments.sceneJson)>
	<cfset ensureTables()>
	<cftransaction>
		<cfset existing = queryExecute("SELECT SceneId FROM Scene WHERE BlogRef = :blogId AND Alias = :alias",
			{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" }, alias = { value = arguments.alias, cfsqltype = "cf_sql_varchar" } })>
		<cfif existing.recordCount>
			<cfset sceneId = existing.SceneId>
			<cfset queryExecute("UPDATE Scene SET Name = :name, PageColour = :colour, SettingsJson = :settings, Active = :active, Updated = :now WHERE SceneId = :sceneId",
				{ name = { value = left(data.name ?: arguments.alias, 125), cfsqltype = "cf_sql_varchar" },
				  colour = { value = left(data.pageColour ?: "", 50), cfsqltype = "cf_sql_varchar" },
				  settings = { value = jsonOf(data, "settings", "{}"), cfsqltype = "cf_sql_longvarchar" },
				  active = { value = arguments.active ? 1 : 0, cfsqltype = "cf_sql_integer" },
				  now = { value = nowStamp, cfsqltype = "cf_sql_timestamp" }, sceneId = { value = sceneId, cfsqltype = "cf_sql_integer" } })>
			<!--- The sections and layers are replaced as a whole: the editor always saves the complete scene. --->
			<cfset queryExecute("DELETE FROM SceneLayer WHERE SceneSectionRef IN (SELECT SceneSectionId FROM SceneSection WHERE SceneRef = :sceneId)", { sceneId = { value = sceneId, cfsqltype = "cf_sql_integer" } })>
			<cfset queryExecute("DELETE FROM SceneSection WHERE SceneRef = :sceneId", { sceneId = { value = sceneId, cfsqltype = "cf_sql_integer" } })>
		<cfelse>
			<cfset queryExecute("INSERT INTO Scene (BlogRef, Name, Alias, PageColour, SettingsJson, Active, Created, Updated) VALUES (:blogId, :name, :alias, :colour, :settings, :active, :now, :now)",
				{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" }, name = { value = left(data.name ?: arguments.alias, 125), cfsqltype = "cf_sql_varchar" },
				  alias = { value = arguments.alias, cfsqltype = "cf_sql_varchar" }, colour = { value = left(data.pageColour ?: "", 50), cfsqltype = "cf_sql_varchar" },
				  settings = { value = jsonOf(data, "settings", "{}"), cfsqltype = "cf_sql_longvarchar" }, active = { value = arguments.active ? 1 : 0, cfsqltype = "cf_sql_integer" },
				  now = { value = nowStamp, cfsqltype = "cf_sql_timestamp" } })>
			<cfset sceneId = queryExecute("SELECT SceneId FROM Scene WHERE BlogRef = :blogId AND Alias = :alias",
				{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" }, alias = { value = arguments.alias, cfsqltype = "cf_sql_varchar" } }).SceneId>
		</cfif>

		<cfloop array="#data.sections ?: []#" index="section">
			<cfif not structKeyExists(section, "kind") or not listFind(variables.kinds, section.kind)>
				<cfcontinue>
			</cfif>
			<cfset sortOrder = sortOrder + 1>
			<cfset queryExecute("INSERT INTO SceneSection (SceneRef, SortOrder, Kind, Heading, Html, DataJson) VALUES (:sceneId, :sortOrder, :kind, :heading, :html, :dataJson)",
				{ sceneId = { value = sceneId, cfsqltype = "cf_sql_integer" }, sortOrder = { value = sortOrder, cfsqltype = "cf_sql_integer" },
				  kind = { value = section.kind, cfsqltype = "cf_sql_varchar" }, heading = { value = left(section.heading ?: "", 500), cfsqltype = "cf_sql_varchar" },
				  html = { value = section.html ?: "", cfsqltype = "cf_sql_longvarchar" },
				  dataJson = { value = sectionDataJson(arguments.sceneJson, sortOrder), cfsqltype = "cf_sql_longvarchar" } })>
			<cfif section.kind eq "layeredHero">
				<cfset sectionId = queryExecute("SELECT SceneSectionId FROM SceneSection WHERE SceneRef = :sceneId AND SortOrder = :sortOrder",
					{ sceneId = { value = sceneId, cfsqltype = "cf_sql_integer" }, sortOrder = { value = sortOrder, cfsqltype = "cf_sql_integer" } }).SceneSectionId>
				<cfset layerOrder = 0>
				<cfloop array="#section.layers ?: []#" index="layer">
					<cfset layerOrder = layerOrder + 1>
					<cfset queryExecute("INSERT INTO SceneLayer (SceneSectionRef, SortOrder, Src, SrcPhone, Depth) VALUES (:sectionId, :sortOrder, :src, :srcPhone, :depth)",
						{ sectionId = { value = sectionId, cfsqltype = "cf_sql_integer" }, sortOrder = { value = layerOrder, cfsqltype = "cf_sql_integer" },
						  src = { value = left(layer.src ?: "", 500), cfsqltype = "cf_sql_varchar" }, srcPhone = { value = left(layer.srcPhone ?: "", 500), cfsqltype = "cf_sql_varchar" },
						  depth = { value = val(layer.depth ?: layerOrder * 100), cfsqltype = "cf_sql_integer" } })>
				</cfloop>
			</cfif>
		</cfloop>
	</cftransaction>
	<cfreturn sceneId>
</cffunction>

<cffunction name="importJson" access="public" returntype="numeric" output="false"
		hint="Imports includes/postContent/scenes/{name}.json into the database under the same alias (how the ready-made scenes get into a blog). Returns the SceneId, or 0 when there is no such file.">
	<cfargument name="name" type="string" required="true">
	<cfset var filePath = "">
	<cfif not reFind("^[A-Za-z0-9_-]{1,80}$", arguments.name)>
		<cfreturn 0>
	</cfif>
	<cfset filePath = expandPath(application.baseUrl & "/includes/postContent/scenes/" & arguments.name & ".json")>
	<cfif not fileExists(filePath)>
		<cfreturn 0>
	</cfif>
	<cfreturn saveScene(arguments.name, fileRead(filePath, "utf-8"))>
</cffunction>

<cffunction name="deleteScene" access="public" returntype="void" output="false">
	<cfargument name="sceneId" type="numeric" required="true">
	<cfset ensureTables()>
	<cftransaction>
		<cfset queryExecute("DELETE FROM SceneLayer WHERE SceneSectionRef IN (SELECT SceneSectionId FROM SceneSection WHERE SceneRef = :sceneId)", { sceneId = { value = arguments.sceneId, cfsqltype = "cf_sql_integer" } })>
		<cfset queryExecute("DELETE FROM SceneSection WHERE SceneRef = :sceneId", { sceneId = { value = arguments.sceneId, cfsqltype = "cf_sql_integer" } })>
		<cfset queryExecute("DELETE FROM Scene WHERE SceneId = :sceneId AND BlogRef = :blogId", { sceneId = { value = arguments.sceneId, cfsqltype = "cf_sql_integer" }, blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } })>
	</cftransaction>
</cffunction>

<cffunction name="getPostScene" access="public" returntype="string" output="false" hint="The alias of the scene a post shows (the <galaxieScene> directive in its header), or an empty string.">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var header = queryExecute("SELECT PostHeader FROM Post WHERE PostId = :postId", { postId = { value = arguments.postId, cfsqltype = "cf_sql_integer" } })>
	<cfset var found = header.recordCount ? reMatchNoCase("<galaxieScene>\s*[A-Za-z0-9_-]{1,80}\s*</galaxieScene>", header.PostHeader ?: "") : []>
	<cfreturn arrayLen(found) ? trim(reReplaceNoCase(found[1], "</?galaxieScene>", "", "all")) : "">
</cffunction>

<cffunction name="setPostScene" access="public" returntype="void" output="false"
		hint="Shows a scene on a post (or none, with an empty alias): adds, replaces or removes the <galaxieScene> directive in the post's header and leaves the rest of the header as it is. Updates the post's last-changed stamp (Post.Date, sent to search engines as dateModified), as saving the post's CSS or JavaScript does; the date visitors see (DatePosted) stays as it is. The Scene window (108) in the post editor.">
	<cfargument name="postId" type="numeric" required="true">
	<cfargument name="alias" type="string" required="true">
	<cfset var post = "">
	<cfset var header = "">
	<cfset var sceneAlias = trim(arguments.alias)>
	<cfif len(sceneAlias) and not (reFind("^[A-Za-z0-9_-]{1,80}$", sceneAlias) and aliasExists(sceneAlias))>
		<cfthrow type="GalaxieBlog.Scenes" message="There is no scene called '#sceneAlias#'.">
	</cfif>
	<cftransaction>
		<cfset post = entityLoad("Post", { postId = arguments.postId }, true)>
		<cfif isNull(post)>
			<cfthrow type="GalaxieBlog.Scenes" message="This post no longer exists.">
		</cfif>
		<cfset header = post.getPostHeader() ?: "">
		<cfset header = trim(reReplaceNoCase(header, "\s*<galaxieScene>[^<]*</galaxieScene>", "", "all"))>
		<cfif len(sceneAlias)>
			<cfset header = (len(header) ? header & chr(10) : "") & "<galaxieScene>" & sceneAlias & "</galaxieScene>">
		</cfif>
		<cfset post.setPostHeader(header)>
		<cfset post.setDate(application.blog.blogNow())>
		<cfset entitySave(post)>
	</cftransaction>
</cffunction>

<cffunction name="getFontFaceCss" access="public" returntype="string" output="false"
		hint="The @font-face rules for the blog fonts a scene uses (its sections' headingFontId and textFontId), so a scene's fonts load wherever it is shown. Web-safe fonts need none.">
	<cfargument name="sceneJson" type="string" required="true">
	<cfset var ids = {}>
	<cfset var m = "">
	<cfset var font = "">
	<cfset var css = "">
	<cfset var ext = application.serverSupportsWoff2 ? "woff2" : "woff">
	<cfset var found = reMatch('"(heading|text)FontId"\s*:\s*"?[0-9]+', arguments.sceneJson)>
	<!--- Fonts named without an id (the ready-made scenes name their fonts, as ids differ from blog to blog): "headingFont": "\"Eagle Lake\", serif". --->
	<cfset var named = reMatch('"(heading|text)Font"\s*:\s*"\\"[^"\\]+\\"', arguments.sceneJson)>
	<cfset var fontName = "">
	<cfset var candidate = "">
	<cfloop array="#found#" index="m">
		<cfset ids[reReplace(m, "[^0-9]", "", "all")] = true>
	</cfloop>
	<cfloop array="#named#" index="m">
		<cfset fontName = reReplace(m, '^.*:\s*"\\"([^"\\]+)\\"$', "\1")>
		<!--- getFont matches a name with LIKE, so only an exact match counts. --->
		<cfloop array="#application.blog.getFont(font = fontName)#" index="candidate">
			<cfif candidate["Font"] eq fontName><cfset ids[candidate["FontId"]] = true></cfif>
		</cfloop>
	</cfloop>
	<cfloop collection="#ids#" item="m">
		<cfset font = application.blog.getFont(fontId = m)>
		<!--- getFont's rows are case-sensitive maps on Adobe ColdFusion (HQL "new Map"), so the keys are written exactly. --->
		<cfif arrayLen(font) and len(font[1]["FileName"] ?: "") and not (isBoolean(font[1]["WebSafeFont"] ?: "") and font[1]["WebSafeFont"])>
			<!--- The same family name as the public pages' own @font-face rules (includes/templates/font.cfm). --->
			<cfset css = css & '@font-face{font-family:"' & replace(font[1]["Font"], '"', '', 'all') & '";src:url(' & application.baseUrl & '/common/fonts/' & font[1]["FileName"] & '.' & ext & ') format("' & ext & '");font-display:swap;}'>
		</cfif>
	</cfloop>
	<cfreturn css>
</cffunction>

<cffunction name="saveUploadedImage" access="public" returntype="struct" output="false"
		hint="Saves a picture uploaded from the Scene editor to enclosures/scenes/ under a new name, plus a smaller copy for phones when it is wide. Returns { location, phoneLocation } with {baseUrl} in front, as scenes store them.">
	<cfargument name="fileField" type="string" required="true">
	<cfset var folder = expandPath(application.baseUrl & "/enclosures/scenes/")>
	<cfset var tempFolder = getTempDirectory()>
	<cfset var uploaded = "">
	<cfset var ext = "">
	<cfset var baseName = "">
	<cfset var img = "">
	<cfset var result = { location: "", phoneLocation: "" }>
	<cfif not directoryExists(folder)>
		<cfdirectory action="create" directory="#folder#">
	</cfif>
	<cffile action="upload" fileField="#arguments.fileField#" destination="#tempFolder#" accept="image/jpeg,image/pjpeg,image/png,image/webp,image/gif" nameConflict="makeUnique" result="uploaded">
	<cfset ext = lCase(uploaded.serverFileExt)>
	<!--- The saved name keeps the picture's own name (made safe), so the layer builder can show "sky", "mountains"... --->
	<cfset baseName = left(reReplace(reReplace(lCase(uploaded.clientFileName), "[^a-z0-9]+", "-", "all"), "^-+|-+$", "", "all"), 40)>
	<cfset baseName = (len(baseName) ? baseName : "scene") & "-" & lCase(left(hash(createUUID() & rand("SHA1PRNG")), 8))>
	<cftry>
		<!--- Only pictures, checked by extension and by reading the file as an image. --->
		<cfif not listFind("jpg,jpeg,png,webp,gif", ext) or uploaded.fileSize gt 15 * 1024 * 1024 or not isImageFile(uploaded.serverDirectory & "/" & uploaded.serverFile)>
			<cfthrow type="GalaxieBlog.Scenes" message="Pick a JPG, PNG, WebP or GIF picture under 15 MB.">
		</cfif>
		<cffile action="move" source="#uploaded.serverDirectory#/#uploaded.serverFile#" destination="#folder##baseName#.#ext#">
		<cfset result.location = "{baseUrl}/enclosures/scenes/" & baseName & "." & ext>
		<!--- A copy 800 pixels wide for phones, when the picture is wider than that (not for GIFs, which may be animated). --->
		<cfif ext neq "gif" and (ext neq "webp" or application.imageEngineSupportsWebP)>
			<cftry>
				<cfset img = imageRead(folder & baseName & "." & ext)>
				<cfif img.width gt 1000>
					<cfset imageResize(img, 800, "", "highestQuality")>
					<cfset imageWrite(img, folder & baseName & "-phone." & ext, 0.85, true)>
					<cfset result.phoneLocation = "{baseUrl}/enclosures/scenes/" & baseName & "-phone." & ext>
				</cfif>
				<cfcatch type="any"><!--- No phone copy; the full picture is used on phones too. ---></cfcatch>
			</cftry>
		</cfif>
		<cfcatch type="any">
			<cfif fileExists(uploaded.serverDirectory & "/" & uploaded.serverFile)>
				<cffile action="delete" file="#uploaded.serverDirectory#/#uploaded.serverFile#">
			</cfif>
			<cfrethrow>
		</cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<!---//*****************************************************************************************************
		Helpers
//******************************************************************************************************--->

<!--- The JSON text of everything in section number {position} except kind, heading, html and layers, cut straight out of the
original text with Java's JSON-free approach below would be fragile, so it is rebuilt key by key from the parsed struct - but the
key NAMES are taken from the original text, so their case survives on Adobe ColdFusion. --->
<cffunction name="sectionDataJson" access="private" returntype="string" output="false">
	<cfargument name="sceneJson" type="string" required="true">
	<cfargument name="position" type="numeric" required="true">
	<cfset var data = deserializeJSON(arguments.sceneJson)>
	<cfset var section = "">
	<cfset var parts = []>
	<cfset var key = "">
	<cfset var originalKeys = keysAsWritten(arguments.sceneJson)>
	<cfset var count = 0>
	<cfset var s = "">
	<cfloop array="#data.sections#" index="s">
		<cfif structKeyExists(s, "kind") and listFind(variables.kinds, s.kind)>
			<cfset count = count + 1>
			<cfif count eq arguments.position><cfset section = s><cfbreak></cfif>
		</cfif>
	</cfloop>
	<cfif not isStruct(section)><cfreturn "{}"></cfif>
	<cfloop collection="#section#" item="key">
		<cfif not listFindNoCase("kind,heading,html,layers", key)>
			<cfset arrayAppend(parts, serializeJSON(structKeyExists(originalKeys, lCase(key)) ? originalKeys[lCase(key)] : key) & ":" & jsonValue(section[key], originalKeys))>
		</cfif>
	</cfloop>
	<cfreturn "{" & arrayToList(parts, ",") & "}">
</cffunction>

<!--- A value as JSON, keeping nested key names as they were written. --->
<cffunction name="jsonValue" access="private" returntype="string" output="false">
	<cfargument name="value" type="any" required="true">
	<cfargument name="originalKeys" type="struct" required="true">
	<cfset var parts = []>
	<cfset var key = "">
	<cfset var item = "">
	<cfif isStruct(arguments.value)>
		<cfloop collection="#arguments.value#" item="key">
			<cfset arrayAppend(parts, serializeJSON(structKeyExists(arguments.originalKeys, lCase(key)) ? arguments.originalKeys[lCase(key)] : key) & ":" & jsonValue(arguments.value[key], arguments.originalKeys))>
		</cfloop>
		<cfreturn "{" & arrayToList(parts, ",") & "}">
	<cfelseif isArray(arguments.value)>
		<cfloop array="#arguments.value#" index="item">
			<cfset arrayAppend(parts, jsonValue(item, arguments.originalKeys))>
		</cfloop>
		<cfreturn "[" & arrayToList(parts, ",") & "]">
	<cfelseif isBoolean(arguments.value) and not isNumeric(arguments.value)>
		<cfreturn arguments.value ? "true" : "false">
	<cfelseif isNumeric(arguments.value) and reFind("^-?[0-9]+(\.[0-9]+)?$", arguments.value)>
		<cfreturn arguments.value>
	<cfelse>
		<cfreturn serializeJSON(toString(arguments.value))>
	</cfif>
</cffunction>

<!--- Every key name in a JSON text, as written, keyed by its lower case: { "pagecolour": "pageColour", ... }. --->
<cffunction name="keysAsWritten" access="private" returntype="struct" output="false">
	<cfargument name="json" type="string" required="true">
	<cfset var found = {}>
	<cfset var matches = reMatch('"([A-Za-z_][A-Za-z0-9_]*)"\s*:', arguments.json)>
	<cfset var m = "">
	<cfset var name = "">
	<cfloop array="#matches#" index="m">
		<cfset name = reReplace(m, '^"([^"]+)".*$', "\1")>
		<cfset found[lCase(name)] = name>
	</cfloop>
	<cfreturn found>
</cffunction>

<cffunction name="jsonOf" access="private" returntype="string" output="false">
	<cfargument name="data" type="struct" required="true">
	<cfargument name="key" type="string" required="true">
	<cfargument name="default" type="string" required="true">
	<cfreturn structKeyExists(arguments.data, arguments.key) ? jsonValue(arguments.data[arguments.key], {}) : arguments.default>
</cffunction>

<cffunction name="blogId" access="private" returntype="numeric" output="false">
	<cfreturn application.BlogDbObj.getBlogId()>
</cffunction>

<cffunction name="ensureTables" access="private" returntype="void" output="false" hint="Creates the three tables the first time they are needed, once per application start.">
	<cfset var updater = "">
	<cfif structKeyExists(variables, "tablesReady")>
		<cfreturn>
	</cfif>
	<cflock name="galaxieSceneTables_#application.applicationName#" type="exclusive" timeout="30">
		<cfif not structKeyExists(variables, "tablesReady")>
			<cfset updater = createObject("component", len(application.baseProxyUrl) ? application.baseComponentPath & ".common.cfc.DatabaseUpdater" : "common.cfc.DatabaseUpdater").init(application.rootDirectoryPath, application.blogIniPath)>
			<!--- createTableIfMissing picks the SQL by application.databaseType, which only the updater sets (see People.cfc ensureTable). --->
			<cfif not len(application.databaseType ?: "")>
				<cfset application.databaseType = getProfileString(application.blogIniPath, "default", "databaseType")>
			</cfif>
			<cfset updater.createTableIfMissing("Scene", {
				sqlServer: "CREATE TABLE Scene (SceneId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, BlogRef INT NOT NULL, Name NVARCHAR(125) NOT NULL, Alias NVARCHAR(80) NOT NULL, PageColour NVARCHAR(50) NULL, SettingsJson NVARCHAR(MAX) NULL, Active BIT NOT NULL DEFAULT 1, Created DATETIME NOT NULL, Updated DATETIME NOT NULL)",
				mySql: "CREATE TABLE Scene (SceneId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, BlogRef INT NOT NULL, Name VARCHAR(125) NOT NULL, Alias VARCHAR(80) NOT NULL, PageColour VARCHAR(50) NULL, SettingsJson LONGTEXT NULL, Active TINYINT(1) NOT NULL DEFAULT 1, Created DATETIME NOT NULL, Updated DATETIME NOT NULL) DEFAULT CHARSET=utf8mb4",
				postgre: "CREATE TABLE Scene (SceneId SERIAL PRIMARY KEY, BlogRef INT NOT NULL, Name VARCHAR(125) NOT NULL, Alias VARCHAR(80) NOT NULL, PageColour VARCHAR(50) NULL, SettingsJson TEXT NULL, Active SMALLINT NOT NULL DEFAULT 1, Created TIMESTAMP NOT NULL, Updated TIMESTAMP NOT NULL)"
			})>
			<cfset updater.createTableIfMissing("SceneSection", {
				sqlServer: "CREATE TABLE SceneSection (SceneSectionId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, SceneRef INT NOT NULL, SortOrder INT NOT NULL, Kind NVARCHAR(30) NOT NULL, Heading NVARCHAR(500) NULL, Html NVARCHAR(MAX) NULL, DataJson NVARCHAR(MAX) NULL)",
				mySql: "CREATE TABLE SceneSection (SceneSectionId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, SceneRef INT NOT NULL, SortOrder INT NOT NULL, Kind VARCHAR(30) NOT NULL, Heading VARCHAR(500) NULL, Html LONGTEXT NULL, DataJson LONGTEXT NULL) DEFAULT CHARSET=utf8mb4",
				postgre: "CREATE TABLE SceneSection (SceneSectionId SERIAL PRIMARY KEY, SceneRef INT NOT NULL, SortOrder INT NOT NULL, Kind VARCHAR(30) NOT NULL, Heading VARCHAR(500) NULL, Html TEXT NULL, DataJson TEXT NULL)"
			})>
			<cfset updater.createTableIfMissing("SceneLayer", {
				sqlServer: "CREATE TABLE SceneLayer (SceneLayerId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, SceneSectionRef INT NOT NULL, SortOrder INT NOT NULL, Src NVARCHAR(500) NOT NULL, SrcPhone NVARCHAR(500) NULL, Depth INT NOT NULL)",
				mySql: "CREATE TABLE SceneLayer (SceneLayerId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, SceneSectionRef INT NOT NULL, SortOrder INT NOT NULL, Src VARCHAR(500) NOT NULL, SrcPhone VARCHAR(500) NULL, Depth INT NOT NULL) DEFAULT CHARSET=utf8mb4",
				postgre: "CREATE TABLE SceneLayer (SceneLayerId SERIAL PRIMARY KEY, SceneSectionRef INT NOT NULL, SortOrder INT NOT NULL, Src VARCHAR(500) NOT NULL, SrcPhone VARCHAR(500) NULL, Depth INT NOT NULL)"
			})>
			<cfset variables.tablesReady = true>
		</cfif>
	</cflock>
</cffunction>

</cfcomponent>
