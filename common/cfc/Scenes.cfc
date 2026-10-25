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

<!--- product (2026-10-21): a product from the shop, with a heading and text. --->
<cfset variables.kinds = "text,imageSlide,layeredHero,photoHero,vantaHero,gradientHero,videoHero,slideshow,form,map,product">

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

<!---//*****************************************************************************************************
		Settings, and where the animation library comes from
//******************************************************************************************************--->

<cffunction name="getSetting" access="public" returntype="string" output="false" hint="A blog-wide scene setting, or the default when it isn't set.">
	<cfargument name="name" type="string" required="true">
	<cfargument name="default" type="string" required="false" default="">
	<cfset var row = "">
	<cfif not structKeyExists(variables, "settings")>
		<cfset ensureTables()>
		<cfset variables.settings = {}>
		<cfset row = queryExecute("SELECT SettingName, SettingValue FROM SceneSetting WHERE BlogRef = :blogId", { blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } })>
		<cfloop query="row">
			<cfset variables.settings[row.SettingName] = row.SettingValue ?: "">
		</cfloop>
	</cfif>
	<cfreturn structKeyExists(variables.settings, arguments.name) ? variables.settings[arguments.name] : arguments.default>
</cffunction>

<cffunction name="setSetting" access="public" returntype="void" output="false">
	<cfargument name="name" type="string" required="true">
	<cfargument name="value" type="string" required="true">
	<cfset var params = { blogId = { value = blogId(), cfsqltype = "cf_sql_integer" }, name = { value = arguments.name, cfsqltype = "cf_sql_varchar" }, value = { value = arguments.value, cfsqltype = "cf_sql_varchar" } }>
	<cfset ensureTables()>
	<cfif queryExecute("SELECT SceneSettingId FROM SceneSetting WHERE BlogRef = :blogId AND SettingName = :name", params).recordCount>
		<cfset queryExecute("UPDATE SceneSetting SET SettingValue = :value WHERE BlogRef = :blogId AND SettingName = :name", params)>
	<cfelse>
		<cfset queryExecute("INSERT INTO SceneSetting (BlogRef, SettingName, SettingValue) VALUES (:blogId, :name, :value)", params)>
	</cfif>
	<cfset structDelete(variables, "settings")>
</cffunction>

<cffunction name="getLocalLibraryFiles" access="public" returntype="array" output="false"
		hint="The GSAP files this server has in common/libs/gsap3/ (the fallback when cdnjs can't be reached, or the only source when the owner chose this server only).">
	<cfset var folder = expandPath(application.baseUrl & "/common/libs/gsap3/")>
	<cfset var found = []>
	<cfset var name = "">
	<cfloop list="gsap.min.js,ScrollTrigger.min.js,SplitText.min.js" index="name">
		<cfif fileExists(folder & name)><cfset arrayAppend(found, name)></cfif>
	</cfloop>
	<cfreturn found>
</cffunction>

<cffunction name="getEngineConfigScript" access="public" returntype="string" output="false"
		hint="The script that tells the scene engine where to load GSAP from: window.GalaxieSceneConfig = { source, localBase, local }. 'cdn' (cdnjs, then this server if cdnjs fails) is the default; 'local' is this server only, and only when this server has the core files.">
	<cfset var libFiles = getLocalLibraryFiles()>
	<cfset var source = getSetting("librarySource", "cdn") eq "local" and arrayFind(libFiles, "gsap.min.js") and arrayFind(libFiles, "ScrollTrigger.min.js") ? "local" : "cdn">
	<cfset var parts = []>
	<cfset var name = "">
	<cfloop array="#libFiles#" index="name"><cfset arrayAppend(parts, serializeJSON(name))></cfloop>
	<!--- still (2026-10-20): GreenSock switched off in Blog Options - the engine loads nothing and shows the scene without movement. --->
	<cfset var still = structKeyExists(application, "includeGsap") and isBoolean(application.includeGsap) and not application.includeGsap>
	<cfreturn '<script>window.GalaxieSceneConfig = { "source": "' & source & '", "still": ' & (still ? 'true' : 'false') & ', "localBase": ' & serializeJSON(application.baseUrl & "/common/libs/gsap3/") & ', "local": [' & arrayToList(parts, ",") & '] };</script>'>
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
	<cfset addStarterScenes()>
	<cfreturn queryExecute("SELECT SceneId, Name, Alias, Active, Updated FROM Scene WHERE BlogRef = :blogId ORDER BY Name",
		{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } })>
</cffunction>

<!--- The starter scenes (5.0, owner 2026-10-23): six ready-made scenes every blog starts with, so the Scenes window and the
post editor's scene picker aren't empty. Never the private Delicate Arch scene (arch.json), which is the owner's own art. --->
<cfset variables.starterScenes = "space,dusk,lookout,wilderness,tallulah,waves">

<cffunction name="addStarterScenes" access="public" returntype="void" output="false"
		hint="Adds the starter scenes to this blog once (new blogs and blogs updated to 5.0 alike, the first time a scene list is read). A scene with the same alias is left as it is, and one the owner deletes later doesn't come back: the SceneSetting startersAdded records that this has run.">
	<cfset var name = "">
	<cfif len(getSetting("startersAdded"))>
		<cfreturn>
	</cfif>
	<cflock name="galaxieStarterScenes_#application.applicationName#" type="exclusive" timeout="30">
		<cfset structDelete(variables, "settings")>
		<cfif not len(getSetting("startersAdded"))>
			<cfloop list="#variables.starterScenes#" index="name">
				<cftry>
					<cfif not aliasExists(name)><cfset importJson(name)></cfif>
					<cfcatch type="any">
						<cflog file="galaxieBlogErrors" type="warning" text="Starter scene #name# wasn't added: #cfcatch.message#">
					</cfcatch>
				</cftry>
			</cfloop>
			<cfset setSetting("startersAdded", dateTimeFormat(now(), "yyyy-mm-dd HH:nn"))>
		</cfif>
	</cflock>
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
	<!--- The owner's own ready-made scenes follow the built-in ones, newest first. --->
	<cfset arrayAppend(starters, getTemplateStarters(), true)>
	<!--- In the order the files give ("order"), then by name. --->
	<cfset arraySort(starters, function (a, b) { return a.order neq b.order ? (a.order lt b.order ? -1 : 1) : compareNoCase(a.name, b.name); })>
	<cfreturn starters>
</cffunction>

<!---//*****************************************************************************************************
		The owner's own ready-made scenes
//******************************************************************************************************--->

<cffunction name="getTemplateStarters" access="public" returntype="array" output="false"
		hint="The owner's own ready-made scenes, shaped like getStarters' entries ({ key, name, order, json }). The stored scene JSON gets its name, description and templateId set at the end, so they win over any copy inside it.">
	<cfset var rows = "">
	<cfset var found = []>
	<cfset var text = "">
	<cfset var position = 0>
	<cfset ensureTables()>
	<cfset rows = queryExecute("SELECT SceneTemplateId, Name, Description, SceneJson FROM SceneTemplate WHERE BlogRef = :blogId ORDER BY Created DESC, SceneTemplateId DESC",
		{ blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } })>
	<cfloop query="rows">
		<cfset position = position + 1>
		<cfset text = trim(rows.SceneJson ?: "")>
		<cfif isJSON(text) and right(text, 1) eq "}" and len(text) gt 2>
			<cfset text = left(text, len(text) - 1) & ',"name":' & serializeJSON(toString(rows.Name)) & ',"description":' & serializeJSON(toString(rows.Description ?: "")) & ',"templateId":' & rows.SceneTemplateId & '}'>
			<cfset arrayAppend(found, { "key": "template-" & rows.SceneTemplateId, "name": rows.Name, "order": 10000 + position, "json": text })>
		</cfif>
	</cfloop>
	<cfreturn found>
</cffunction>

<cffunction name="saveTemplate" access="public" returntype="numeric" output="false"
		hint="Keeps a scene as one of the owner's own ready-made scenes, shown in the New scene gallery. Takes the scene as JSON text, as the editor has it.">
	<cfargument name="name" type="string" required="true">
	<cfargument name="description" type="string" required="false" default="">
	<cfargument name="sceneJson" type="string" required="true">
	<cfset var nowStamp = now()>
	<cfif not len(trim(arguments.name))>
		<cfthrow type="GalaxieBlog.Scenes" message="The ready-made scene needs a name.">
	</cfif>
	<cfif not isJSON(arguments.sceneJson) or not isStruct(deserializeJSON(arguments.sceneJson)) or len(arguments.sceneJson) gt 500000>
		<cfthrow type="GalaxieBlog.Scenes" message="The scene could not be read.">
	</cfif>
	<cfset ensureTables()>
	<cfset queryExecute("INSERT INTO SceneTemplate (BlogRef, Name, Description, SceneJson, Created) VALUES (:blogId, :name, :description, :json, :created)", {
		blogId = { value = blogId(), cfsqltype = "cf_sql_integer" }, name = { value = left(trim(arguments.name), 125), cfsqltype = "cf_sql_varchar" },
		description = { value = left(trim(arguments.description), 500), cfsqltype = "cf_sql_varchar" }, json = { value = trim(arguments.sceneJson), cfsqltype = "cf_sql_longvarchar" },
		created = { value = nowStamp, cfsqltype = "cf_sql_timestamp" } })>
	<cfreturn queryExecute("SELECT MAX(SceneTemplateId) AS NewId FROM SceneTemplate WHERE BlogRef = :blogId", { blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } }).NewId>
</cffunction>

<cffunction name="deleteTemplate" access="public" returntype="void" output="false" hint="Removes one of the owner's own ready-made scenes from the gallery. Scenes already made from it are not touched.">
	<cfargument name="templateId" type="numeric" required="true">
	<cfset ensureTables()>
	<cfset queryExecute("DELETE FROM SceneTemplate WHERE SceneTemplateId = :id AND BlogRef = :blogId",
		{ id = { value = arguments.templateId, cfsqltype = "cf_sql_integer" }, blogId = { value = blogId(), cfsqltype = "cf_sql_integer" } })>
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
	<cfif len(arguments.sceneJson) gt 500000>
		<cfthrow type="GalaxieBlog.Scenes" message="The scene is too large to save. Pictures are stored as addresses, so this usually means very long text in a section.">
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

<!---//*****************************************************************************************************
		A post's parallax hero, from the Hero editor (2026-10-25)
//******************************************************************************************************--->

<!--- Owner 10-25: "a shortcut for the users who just want a parallax hero image without having to go to the scene UI". The Hero
editor's Parallax hero panel picks a ready-made layered picture (or the post's own photo, with a slow zoom), a heading and where it
sits; that makes the post its own hero parallax scene, alias post-hero-{postId}, so changing it later updates the same copy and each
post keeps its own heading. The picture it came from is kept in the scene's settings (heroStarter). --->

<cffunction name="getHeroParallaxStarters" access="public" returntype="array" output="false"
		hint="The ready-made pictures the Hero editor offers: every starter scene whose first section is a layered hero, as [{ key, name, layers: [{ src, depth }] }] with {baseUrl} left in the addresses.">
	<cfset var result = []>
	<cfset var starter = "">
	<cfset var data = "">
	<cfset var layer = "">
	<cfset var layers = []>
	<cfloop array="#getStarters()#" index="starter">
		<cftry>
			<cfset data = deserializeJSON(starter.json)>
			<cfif isStruct(data) and isArray(data.sections ?: "") and arrayLen(data.sections) and (data.sections[1].kind ?: "") eq "layeredHero" and isArray(data.sections[1].layers ?: "")>
				<cfset layers = []>
				<cfloop array="#data.sections[1].layers#" index="layer">
					<cfif isStruct(layer) and len(layer.src ?: "")><cfset arrayAppend(layers, { "src": layer.src, "depth": val(layer.depth ?: 0) })></cfif>
				</cfloop>
				<cfif arrayLen(layers)><cfset arrayAppend(result, { "key": starter.key, "name": data.name ?: starter.key, "layers": layers })></cfif>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>
	</cfloop>
	<cfreturn result>
</cffunction>

<cffunction name="getPostHeroParallax" access="public" returntype="struct" output="false"
		hint="The post's parallax hero for the Hero editor: { active, starter, heading, line, align, textPosition, otherScene }. otherScene is the alias of a scene the post shows that the panel didn't make (set in the Scene window), or empty.">
	<cfargument name="postId" type="numeric" required="true">
	<cfset var result = { "active": false, "starter": "", "heading": "", "line": "", "align": "center", "textPosition": "", "otherScene": "" }>
	<cfset var alias = getPostScene(arguments.postId)>
	<cfset var data = "">
	<cfset var section = "">
	<cfif not len(alias)><cfreturn result></cfif>
	<cfif alias neq "post-hero-" & arguments.postId>
		<cfset result.otherScene = alias>
		<cfreturn result>
	</cfif>
	<cftry>
		<cfset data = deserializeJSON(getSceneJson(alias, false))>
		<cfset section = data.sections[1]>
		<cfset result.active = true>
		<cfset result.starter = data.settings.heroStarter ?: "">
		<cfset result.heading = section.heading ?: "">
		<cfset result.line = trim(reReplace(section.html ?: "", "<[^>]*>", "", "all"))>
		<cfset result.align = section.align ?: "center">
		<cfset result.textPosition = section.textPosition ?: "">
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfreturn result>
</cffunction>

<cffunction name="usePostHeroParallax" access="public" returntype="string" output="false"
		hint="Makes (or changes) the post's own parallax hero and shows it on the post: starter is a ready-made picture's key, or 'photo' for the post's own picture with a slow zoom. Returns the scene's alias.">
	<cfargument name="postId" type="numeric" required="true">
	<cfargument name="starter" type="string" required="true">
	<cfargument name="heading" type="string" required="false" default="">
	<cfargument name="line" type="string" required="false" default="">
	<cfargument name="align" type="string" required="false" default="center">
	<cfargument name="textPosition" type="string" required="false" default="">
	<cfset var alias = "post-hero-" & arguments.postId>
	<!--- The title and picture as the post page has them (the picture is in the media table, not on Post). --->
	<cfset var posts = application.blog.getPostByPostId(arguments.postId, true, true)>
	<cfset var post = arrayLen(posts) ? posts[1] : {}>
	<cfset var section = {}>
	<cfset var source = "">
	<cfset var sourceName = "">
	<cfset var filePath = "">
	<cfset var scene = {}>
	<cfif structIsEmpty(post)>
		<cfthrow type="GalaxieBlog.Scenes" message="This post no longer exists.">
	</cfif>
	<cfif arguments.starter eq "photo">
		<cfif not len(post["MediaUrl"] ?: "") or (post["MediaType"] ?: "") eq "Video">
			<cfthrow type="GalaxieBlog.Scenes" message="This post has no picture yet. Add one above, or choose one of the ready-made pictures.">
		</cfif>
		<cfset section = { "kind": "photoHero", "image": post["MediaUrl"], "zoom": 1.15 }>
		<cfset sourceName = "Photo hero">
	<cfelse>
		<cfif not reFind("^[A-Za-z0-9_-]{1,80}$", arguments.starter)>
			<cfthrow type="GalaxieBlog.Scenes" message="Please choose a picture.">
		</cfif>
		<cfset filePath = expandPath(application.baseUrl & "/includes/postContent/scenes/" & arguments.starter & ".json")>
		<cfif not fileExists(filePath)>
			<cfthrow type="GalaxieBlog.Scenes" message="That picture isn't on this blog.">
		</cfif>
		<cfset source = deserializeJSON(fileRead(filePath, "utf-8"))>
		<cfif not (isArray(source.sections ?: "") and arrayLen(source.sections) and (source.sections[1].kind ?: "") eq "layeredHero")>
			<cfthrow type="GalaxieBlog.Scenes" message="That picture can't be used as a parallax hero.">
		</cfif>
		<cfset section = { "kind": "layeredHero", "layers": source.sections[1].layers }>
		<cfif len(source.sections[1].shadow ?: "")><cfset section["shadow"] = source.sections[1].shadow></cfif>
		<cfset sourceName = source.name ?: arguments.starter>
	</cfif>
	<cfset section["heading"] = left(trim(arguments.heading), 300)>
	<cfif len(trim(arguments.line))><cfset section["html"] = "<p>" & encodeForHtml(left(trim(arguments.line), 300)) & "</p>"></cfif>
	<cfset section["align"] = listFind("left,center,right", arguments.align) ? arguments.align : "center">
	<cfif arguments.textPosition eq "bottom"><cfset section["textPosition"] = "bottom"></cfif>
	<cfset scene = {
		"name": left(sourceName & " (" & (post["Title"] ?: "") & ")", 120),
		"pageColour": "auto",
		"settings": { "type": "heroParallax", "scrub": true, "heroStarter": arguments.starter },
		"sections": [ section ]
	}>
	<cfset saveScene(alias, serializeJSON(scene))>
	<cfset setPostScene(arguments.postId, alias)>
	<cfreturn alias>
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
			<!--- Scene settings (2026-10-19): blog-wide choices, such as where the animation library is loaded from. --->
			<cfset updater.createTableIfMissing("SceneSetting", {
				sqlServer: "CREATE TABLE SceneSetting (SceneSettingId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, BlogRef INT NOT NULL, SettingName NVARCHAR(80) NOT NULL, SettingValue NVARCHAR(500) NULL)",
				mySql: "CREATE TABLE SceneSetting (SceneSettingId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, BlogRef INT NOT NULL, SettingName VARCHAR(80) NOT NULL, SettingValue VARCHAR(500) NULL) DEFAULT CHARSET=utf8mb4",
				postgre: "CREATE TABLE SceneSetting (SceneSettingId SERIAL PRIMARY KEY, BlogRef INT NOT NULL, SettingName VARCHAR(80) NOT NULL, SettingValue VARCHAR(500) NULL)"
			})>
			<!--- The owner's own ready-made scenes (2026-10-19): kept in the database, so a blog update never touches them. --->
			<cfset updater.createTableIfMissing("SceneTemplate", {
				sqlServer: "CREATE TABLE SceneTemplate (SceneTemplateId INT IDENTITY(1,1) NOT NULL PRIMARY KEY, BlogRef INT NOT NULL, Name NVARCHAR(125) NOT NULL, Description NVARCHAR(500) NULL, SceneJson NVARCHAR(MAX) NOT NULL, Created DATETIME NOT NULL)",
				mySql: "CREATE TABLE SceneTemplate (SceneTemplateId INT NOT NULL AUTO_INCREMENT PRIMARY KEY, BlogRef INT NOT NULL, Name VARCHAR(125) NOT NULL, Description VARCHAR(500) NULL, SceneJson LONGTEXT NOT NULL, Created DATETIME NOT NULL) DEFAULT CHARSET=utf8mb4",
				postgre: "CREATE TABLE SceneTemplate (SceneTemplateId SERIAL PRIMARY KEY, BlogRef INT NOT NULL, Name VARCHAR(125) NOT NULL, Description VARCHAR(500) NULL, SceneJson TEXT NOT NULL, Created TIMESTAMP NOT NULL)"
			})>
			<cfset variables.tablesReady = true>
		</cfif>
	</cflock>
</cffunction>

<!---//*****************************************************************************************************
		A scene's fonts from a theme (2026-10-21, owner): its large headings in that theme's Text font and its text in the
		theme's Menu font, wherever the scene is shown. The theme is the one picked in Scene settings (settings.fontTheme), or else the theme
		with the scene's name (the Delicate Arch scene and the Delicate Arch theme). With neither, the scene keeps the page's
		own theme fonts (blogContentCss.cfm). A font picked for a section still wins (galaxieScene.js applyLook).
//******************************************************************************************************--->

<cffunction name="getFontTheme" access="public" returntype="struct" output="false" hint="The theme a scene takes its fonts from: { alias, name, headerFont, headerType, bodyFont, bodyType }, or an empty struct.">
	<cfargument name="sceneJson" type="string" required="true">
	<cfset var parsed = isJSON(arguments.sceneJson) ? deserializeJSON(arguments.sceneJson) : {}>
	<cfset var wanted = isStruct(parsed) and isStruct(parsed.settings ?: "") ? toString(parsed.settings.fontTheme ?: "") : "">
	<cfset var sceneName = isStruct(parsed) ? lCase(reReplace(toString(parsed.name ?: ""), "[^A-Za-z0-9]", "", "all")) : "">
	<cfset var theme = "">
	<cfloop array="#getThemeFonts()#" index="theme">
		<cfif len(wanted) and theme.alias eq wanted><cfreturn theme></cfif>
	</cfloop>
	<cfif len(sceneName)>
		<cfloop array="#getThemeFonts()#" index="theme">
			<cfif lCase(reReplace(theme.name, "[^A-Za-z0-9]", "", "all")) eq sceneName or lCase(reReplace(theme.alias, "[^A-Za-z0-9]", "", "all")) eq sceneName><cfreturn theme></cfif>
		</cfloop>
	</cfif>
	<cfreturn {}>
</cffunction>

<cffunction name="getThemeFonts" access="public" returntype="array" output="false" hint="Every theme's name and the fonts a scene takes from it, kept for five minutes: headerFont (for headings) is the theme's Text font, bodyFont (for text) its Menu font.">
	<cfset var list = []>
	<cfset var cards = "">
	<cfset var t = "">
	<cfif structKeyExists(variables, "themeFontsCache") and dateDiff("s", variables.themeFontsCache.made, now()) lt 300>
		<cfreturn variables.themeFontsCache.list>
	</cfif>
	<cftry>
		<cfset cards = application.blog.getThemeEditor().getThemeCards(false)>
		<cfloop array="#cards.themes#" index="t">
			<cfset arrayAppend(list, { "alias": toString(t.ThemeAlias ?: ""), "name": toString(t.ThemeName ?: ""),
				"headerFont": toString(t.Font ?: ""), "headerType": toString(t.FontType ?: ""),
				"bodyFont": toString(t.MenuFont ?: ""), "bodyType": toString(t.MenuFontType ?: "") })>
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
	<cfset variables.themeFontsCache = { made: now(), list: list }>
	<cfreturn list>
</cffunction>

<cffunction name="getFontThemeStyle" access="public" returntype="string" output="false" hint="The style for one scene on the page: its theme's two fonts as the variables galaxieScene.js reads, on the scene's own container, with their @font-face rules. Empty when the scene has no font theme.">
	<cfargument name="sceneJson" type="string" required="true">
	<cfargument name="selector" type="string" required="true" hint="The scene's container, eg. ##galaxieScene12.">
	<cfset var theme = getFontTheme(arguments.sceneJson)>
	<cfset var renderer = "">
	<cfset var vars = "">
	<cfset var faces = "">
	<cfif structIsEmpty(theme)><cfreturn ""></cfif>
	<cfset renderer = createObject("component", application.rendererComponentPath)>
	<cfif len(theme.bodyFont)>
		<cfset vars = vars & "--galaxieSceneTextFont:'" & theme.bodyFont & "'" & (len(theme.bodyType) ? ", " & theme.bodyType : "") & ";">
		<cfset faces = faces & renderer.getOverlayFontFaceStyle(theme.bodyFont)>
	</cfif>
	<cfif len(theme.headerFont)>
		<cfset vars = vars & "--galaxieSceneHeadingFont:'" & theme.headerFont & "'" & (len(theme.headerType) ? ", " & theme.headerType : "") & ";">
		<cfif theme.headerFont neq theme.bodyFont><cfset faces = faces & renderer.getOverlayFontFaceStyle(theme.headerFont)></cfif>
	</cfif>
	<cfreturn faces & (len(vars) ? "<style>" & arguments.selector & "{" & vars & "}</style>" : "")>
</cffunction>

</cfcomponent>
