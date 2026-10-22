<!--- Scene editor (window 107, 2026-10-19, Galaxie 5), opened from the Scenes window (106) with createAdminInterfaceWindow(107,
sceneId); 0 makes a new scene. Side by side (owner's pick, layout A): the sections on the left, the selected section's settings
in the middle, and a live preview on the right (admin/scenePreview.cfm in an iframe, sent the scene on every change). The scene
is edited as the engine's own data ({ name, pageColour, settings, sections: [...] }, see common/js/galaxieScene.js), so keys
this editor doesn't know yet are kept as they are. Saved by ProxyController.cfc's saveScene -> Scenes.cfc saveScene.
Step 3 (2026-10-19): rich text (one TinyMCE that stays put while sections are picked), the blog's fonts, picture upload
(ProxyController uploadSceneImage), gradients (Grapick, as in the gradient editor) and Kendo color pickers.
Step 4 (2026-10-19): a new scene opens on a gallery of the ready-made scenes (includes/postContent/scenes/*.json), each card
drawn from the scene itself (its layers, photo or gradient), or from the picture named in the file's "thumbnail".
Layer builder (2026-10-19, layout B): the layered hero's layers in a list with depth sliders, Add layers, Even out depths and a
size check; on the preview, Hold the scroll, and an Exploded view in its own Kendo window (owner's request).
Color helper (2026-10-19, option A): a Suggest button on each color field, with colors read from the section's pictures and its
neighbours, and the browser's eyedropper where there is one. --->
<cfset sceneId = val(URL.optArgs)>
<cfset scene = sceneId gt 0 ? application.blog.getScenes().getScene(sceneId) : {}>
<cfset isNewScene = structIsEmpty(scene)>
<cfset sceneStarters = isNewScene ? application.blog.getScenes().getStarters() : []>
<!--- The scene as JSON text for the script: a saved scene, or a new one from the first ready-made scene (the arch when there).
Written as it is ("</" escaped so it can't end the script tag): serializeJSON would upper-case keys on Adobe ColdFusion. --->
<cfif isNewScene>
	<cfset sceneJsonText = '{"name":"New scene","pageColour":"##392630","settings":{},"sections":[]}'>
	<cfloop array="#sceneStarters#" index="thisStarter">
		<cfif thisStarter.key eq "arch" or sceneJsonText contains '"sections":[]'><cfset sceneJsonText = thisStarter.json></cfif>
	</cfloop>
	<cfset starterParts = []>
	<cfloop array="#sceneStarters#" index="thisStarter">
		<cfset arrayAppend(starterParts, '{"key":' & serializeJSON(toString(thisStarter.key)) & ',"name":' & serializeJSON(toString(thisStarter.name)) & ',"json":' & thisStarter.json & '}')>
	</cfloop>
	<cfset startersJsonText = "[" & arrayToList(starterParts, ",") & "]">
<cfelse>
	<cfset sceneJsonText = scene.json>
	<cfset startersJsonText = "[]">
</cfif>
<!--- Nothing in the data can end the script ("</") or open an HTML comment in it ("<!--"). --->
<cfset sceneJsonText = replace(replace(sceneJsonText, "</", "<\/", "all"), "<!--", "<\!--", "all")>
<cfset startersJsonText = replace(replace(startersJsonText, "</", "<\/", "all"), "<!--", "<\!--", "all")>
<!--- The blog's posts and pages (owner, 10-19): for a hero button's "Goes to" list, and for picking the posts and pages that show
this scene. Drafts are listed too (a scene can go on a post before it is released); a button can only go to a released one. --->
<cfquery name="sceneLinkRows" datasource="#application.dsn#">
	SELECT PostId, Title, PostAlias, DatePosted, IsPage, Released
	FROM Post
	WHERE BlogRef = <cfqueryparam value="#application.BlogDbObj.getBlogId()#" cfsqltype="cf_sql_integer">
	AND (Remove IS NULL OR Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">)
	AND Title IS NOT NULL AND DatePosted IS NOT NULL
	ORDER BY Title
</cfquery>
<cfset sceneLinkParts = []>
<cfloop query="sceneLinkRows">
	<cfset thisLinkUrl = application.blog.makeLink(postId = sceneLinkRows.PostId, isPage = sceneLinkRows.IsPage eq 1, postAlias = sceneLinkRows.PostAlias, datePosted = sceneLinkRows.DatePosted)>
	<cfif application.serverRewriteRuleInPlace><cfset thisLinkUrl = replaceNoCase(thisLinkUrl, "/index.cfm", "")></cfif>
	<cfset arrayAppend(sceneLinkParts, '{"id":' & sceneLinkRows.PostId & ',"title":' & serializeJSON(toString(sceneLinkRows.Title)) & ',"page":' & (sceneLinkRows.IsPage eq 1 ? 'true' : 'false')
		& ',"released":' & (sceneLinkRows.Released eq 1 ? 'true' : 'false') & ',"url":' & serializeJSON(toString(thisLinkUrl)) & '}')>
</cfloop>
<!--- The ready-made forms (owner, 10-20): picking one makes this scene its own copy (WebForms.cfc useReadyMade). --->
<cfset sceneReadyParts = []>
<cfif structKeyExists(application, "webForms")>
	<cftry>
		<cfloop array="#application.webForms.getReadyMadeChoices()#" index="thisReady">
			<cfset arrayAppend(sceneReadyParts, '{"key":' & serializeJSON(toString(thisReady.key)) & ',"name":' & serializeJSON(toString(thisReady.name)) & '}')>
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cfif>
<!--- The blog's maps (owner, 10-20), for a Map section: made in a post's editor (Insert > Map), shown here by title or place. --->
<cfset sceneMapParts = []>
<cftry>
	<cfquery name="sceneMapRows" datasource="#application.dsn#">
		SELECT m.MapId, m.MapTitle, m.MapName, m.Location, m.HasMapRoutes, p.Title AS PostTitle
		FROM Map m LEFT JOIN Post p ON p.PostId = m.PostRef
		ORDER BY m.MapId DESC
	</cfquery>
	<cfloop query="sceneMapRows">
		<cfset thisMapName = len(trim(sceneMapRows.MapTitle)) ? sceneMapRows.MapTitle : (len(trim(sceneMapRows.Location)) ? sceneMapRows.Location : (len(trim(sceneMapRows.MapName)) ? sceneMapRows.MapName : "Map " & sceneMapRows.MapId))>
		<cfif len(trim(sceneMapRows.PostTitle))><cfset thisMapName = thisMapName & " (in " & sceneMapRows.PostTitle & ")"></cfif>
		<cfset arrayAppend(sceneMapParts, '{"id":' & sceneMapRows.MapId & ',"title":' & serializeJSON(toString(left(thisMapName, 150))) & ',"routes":' & (sceneMapRows.HasMapRoutes eq 1 ? 'true' : 'false') & '}')>
	</cfloop>
	<cfcatch type="any"></cfcatch>
</cftry>
<!--- The blog's forms (owner, 10-19), for a Form section. --->
<!--- The shop's products (2026-10-21), for a Product section: { alias, name, price }. --->
<cfset sceneProductParts = []>
<cfif structKeyExists(application, "shop")>
	<cftry>
		<cfloop array="#application.shop.listProducts(activeOnly = true)#" index="thisSceneProduct">
			<cfset arrayAppend(sceneProductParts, '{"alias":' & serializeJSON(toString(thisSceneProduct.alias)) & ',"name":' & serializeJSON(toString(thisSceneProduct.name)) & ',"price":' & serializeJSON(toString(thisSceneProduct.priceText)) & '}')>
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cfif>
<!--- Every theme's Header and Body fonts (2026-10-21, owner), for "Fonts from" in Scene settings and the preview. --->
<cfset sceneThemeFonts = []>
<cfset sceneThemeFontFaces = "">
<cftry>
	<cfset sceneThemeFonts = application.blog.getScenes().getThemeFonts()>
	<cfset sceneThemeFontFaces = application.blog.getThemeEditor().getThemeCards(false).fontFaces>
	<cfcatch type="any"></cfcatch>
</cftry>
<cfset sceneFormParts = []>
<cfif structKeyExists(application, "webForms")>
	<cftry>
		<cfloop array="#application.webForms.getForms()#" index="thisSceneForm">
			<cfset arrayAppend(sceneFormParts, '{"id":' & val(thisSceneForm.webFormId) & ',"alias":' & serializeJSON(toString(thisSceneForm.alias)) & ',"title":' & serializeJSON(toString(thisSceneForm.title)) & ',"active":' & (thisSceneForm.active ? 'true' : 'false') & '}')>
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cfif>
<cfset sceneShownOn = isNewScene ? [] : application.blog.getScenes().getPostIdsUsing(scene.alias)>
<cfset sceneLinksJsonText = replace(replace("[" & arrayToList(sceneLinkParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")>
<!--- The blog's fonts, for the heading and text font dropdowns. Each self-hosted font is declared below under its own name, so the
dropdown shows it in its own face, the way the public pages name it (includes/templates/font.cfm). --->
<cfset sceneFonts = []>
<cfset sceneFontFaceCss = "">
<cfset sceneFontExt = application.serverSupportsWoff2 ? "woff2" : "woff">
<!--- getFont's rows are case-sensitive maps on Adobe ColdFusion (HQL "new Map"), so the keys are written exactly. --->
<cfloop array="#application.blog.getFont()#" index="thisFont">
	<cfset thisFileName = thisFont["FileName"] ?: "">
	<cfset thisWebSafe = isBoolean(thisFont["WebSafeFont"] ?: "") and thisFont["WebSafeFont"]>
	<cfset arrayAppend(sceneFonts, { "id": thisFont["FontId"], "name": thisFont["Font"], "fileName": thisFileName, "webSafe": thisWebSafe, "type": thisFont["FontType"] ?: "" })>
	<cfif not thisWebSafe and len(thisFileName)>
		<cfset sceneFontFaceCss = sceneFontFaceCss & '@font-face{font-family:"' & replace(thisFont["Font"], '"', '', 'all') & '";src:url(' & application.baseUrl & '/common/fonts/' & thisFileName & '.' & sceneFontExt & ') format("' & sceneFontExt & '");font-display:swap;}'>
	</cfif>
</cfloop>
<cfset sceneFontsJson = replace(serializeJSON(sceneFonts), "</", "<\/", "all")>
<!--- The drawn scenes that also come in a soft color style (images/scenes/{name}-soft/), for the Flat / Soft switch. --->
<cfdirectory action="list" directory="#expandPath(application.baseUrl & '/images/scenes/')#" type="dir" name="sceneArtFolders">
<cfset sceneSoftSets = []>
<cfloop query="sceneArtFolders">
	<cfif reFindNoCase("^[a-z0-9]+-soft$", sceneArtFolders.name)><cfset arrayAppend(sceneSoftSets, lCase(listFirst(sceneArtFolders.name, "-")))></cfif>
</cfloop>
<!--- Plugin effects (2026-10-19) are offered only when their plugin can be loaded: from cdnjs, or from this server when the owner
chose "this server only" (Scenes window settings). --->
<cfset sceneSplitText = application.blog.getScenes().getSetting("librarySource", "cdn") neq "local" or arrayFind(application.blog.getScenes().getLocalLibraryFiles(), "SplitText.min.js")>

<!--- The rich text editor for a section's text: the blog's shared TinyMCE setup, without the menu bar (tinyMce.cfm, case sceneTextEditor). --->
<cfset selectorId = "sceneTextEditor">
<cfset editorHeight = "240">
<cfset imageHandlerUrl = application.baseUrl & "/common/cfc/ProxyController.cfc?method=uploadSceneImage&csrfToken=" & csrfToken>
<cfset contentVar = "">
<cfset imageMediaIdField = "mediaId">
<cfset imageClass = "entryImage">
<cfset toolbarString = "undo redo | bold italic underline | forecolor | link | bullist numlist | alignleft aligncenter alignright | removeformat">
<cfset includeMaps = false>
<cfset includeCommonCss = false>
<cfinclude template="#application.baseUrl#/includes/templates/js/tinyMce.cfm">
<!--- The scene cards (thumbnails drawn from a scene), shared with the post's Scene window (108). --->
<cfinclude template="sceneCards.cfm">

<style>
	#sceneEditor { display: flex; flex-direction: column; height: 100%; }
	#sceneEditorTop { flex: 0 0 auto; padding: 6px 8px; display: flex; flex-wrap: wrap; align-items: center; gap: 8px 14px; }
	#sceneEditorTop label { white-space: nowrap; }
	#sceneEditorBody { flex: 1 1 auto; display: flex; min-height: 0; }
	#sceneEditorList { flex: 0 0 21%; overflow: auto; padding: 0; }
	<!--- The section list (k-content), then Add a section in a block of its own (k-alt) - owner, 10-20. --->
	#sceneEditorList > .adminDivBlock { padding: 8px; }
	#sceneEditorList .sceneAddHeading { margin: 0 0 8px; }
	#sceneAddSection { width: 100%; }
	<!--- The Add a section window: a card for each kind of section, in two groups. --->
	.sceneKindCards { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 12px; }
	.sceneKindGroup { grid-column: 1 / -1; font-size: 12px; font-weight: bold; text-transform: uppercase; letter-spacing: .05em; opacity: .75; margin: 6px 0 -4px; }
	.sceneKindGroup:first-child { margin-top: 0; }
	.sceneKindCard { border: 2px solid rgba(128,128,128,.35); border-radius: 8px; background: transparent; color: inherit; padding: 0; text-align: left; cursor: pointer; font: inherit; overflow: hidden; display: flex; flex-direction: column; }
	.sceneKindCard:hover, .sceneKindCard:focus { border-color: currentColor; outline: none; }
	.sceneKindCard svg { display: block; width: 100%; height: 96px; }
	.sceneKindText { padding: 8px 10px 10px; }
	.sceneKindText b { display: block; margin-bottom: 3px; }
	.sceneKindText span { font-size: 13px; opacity: .8; line-height: 1.35; }
	#sceneEditorSettings { flex: 0 0 29%; overflow-y: auto; overflow-x: hidden; padding: 0; }
	<!--- The settings in alternating blocks with lines between the fields (owner's admin look; shared .adminDivBlock in blogContentCss.cfm). --->
	#sceneEditorSettings .adminDivBlock > .sceneField, #sceneEditorSettings .adminDivBlock > .sceneFieldGroup { margin: 0; }
	#sceneEditorSettings .adminDivBlock > .sceneField + .sceneField { margin-top: 8px; }
	#sceneSettingsRest > .adminDivBlock:first-child { border-top: 1px solid rgba(128,128,128,.45); }
	#sceneEditorPreview { flex: 1 1 auto; display: flex; flex-direction: column; min-width: 0; padding: 8px; }
	#scenePreviewBar { flex: 0 0 auto; padding-bottom: 6px; display: flex; flex-wrap: wrap; align-items: center; gap: 6px 14px; }
	#scenePreviewStage { flex: 1 1 auto; min-height: 0; display: flex; justify-content: center; background: #2b2b2b; border-radius: 4px; }
	#scenePreviewFrame { border: 0; width: 100%; height: 100%; background: #222; }
	#scenePreviewStage.phone #scenePreviewFrame { width: 390px; max-width: 100%; }
	#scenePreviewStage { position: relative; }
	#sceneHold { width: 120px; vertical-align: middle; }
	.sceneLayerRow { border: 1px solid rgba(128,128,128,.35); border-radius: 4px; padding: 5px 6px; margin-bottom: 6px; cursor: pointer; }
	.sceneLayerRow.selected { border-color: currentColor; border-width: 2px; padding: 4px 5px; }
	.sceneLayerTop { display: flex; align-items: center; gap: 6px; }
	.sceneLayerTop + .sceneLayerTop { margin-top: 4px; }
	.sceneLayerThumb { width: 56px; height: 32px; object-fit: cover; flex: 0 0 56px; border-radius: 2px; background: repeating-conic-gradient(#bbb 0% 25%, #eee 0% 50%) 0 0 / 10px 10px; }
	.sceneLayerName { flex: 1 1 auto; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
	.sceneLayerTools .k-button { padding: 0 4px; min-width: 0; }
	.sceneLayerDepth { flex: 1 1 auto; min-width: 0; }
	.sceneLayerDepthValue { flex: 0 0 36px; text-align: right; }
	<!--- The exploded view, in its own Kendo window: the layers fanned out in 3D, with a checkerboard where a layer is see-through. --->
	#sceneExplodedWindow { padding: 0; }
	#sceneExploded { position: relative; width: 100%; height: 100%; min-height: 300px; background: #2b2b2b; overflow: hidden; perspective: 1400px; }
	.sceneSheet { position: absolute; left: 42%; width: 52%; aspect-ratio: 16 / 9; padding: 0; border: 1px solid rgba(255,255,255,.45); border-radius: 4px; background-size: cover, 16px 16px; background-position: center, 0 0; transform: translate(-50%, -50%) rotateX(58deg) rotateZ(-32deg); cursor: pointer; }
	.sceneSheet:hover, .sceneSheet:focus { border-color: #fff; outline: none; }
	.sceneSheet.selected { outline: 3px solid #4fa3ff; }
	.sceneSheetLabel { position: absolute; left: 74%; right: 8px; transform: translateY(-50%); color: #ddd; font-size: 12px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; pointer-events: none; }
	.sceneSheetLabel.selected { color: #8cc4f0; font-weight: bold; }
	.sceneExplodedHint { position: absolute; left: 10px; bottom: 8px; color: #bbb; font-size: 12px; }
	.sceneSectionItem { border: 1px solid rgba(128,128,128,.35); border-radius: 4px; padding: 6px 8px; margin-bottom: 6px; cursor: pointer; }
	.sceneSectionItem.selected { border-color: currentColor; border-width: 2px; padding: 5px 7px; }
	.sceneSectionItem .sceneSectionKind { font-weight: bold; }
	.sceneSectionItem .sceneSectionHeading { display: block; opacity: .8; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
	.sceneSectionItem .sceneSectionTools { float: right; }
	.sceneSectionItem .sceneSectionTools .k-button { padding: 0 4px; min-width: 0; }
	.sceneField { margin-bottom: 12px; }
	.sceneField > label { display: block; margin-bottom: 3px; }
	.sceneField .k-textbox, .sceneField select, .sceneField textarea { width: 100%; box-sizing: border-box; }
	.sceneColour { display: flex; gap: 6px; align-items: center; }
	.sceneColour input[type=color] { width: 36px; height: 30px; padding: 0; border: 1px solid rgba(128,128,128,.5); background: none; flex: 0 0 36px; }
	.sceneFieldGroup { margin: 16px 0 8px; }
	.sceneRow { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
	.sceneRow .k-textbox { flex: 1 1 auto; min-width: 0; }
	.sceneRow > .k-button { flex: 0 0 auto; }
	.sceneThumb { display: block; max-width: 100%; max-height: 90px; margin-top: 6px; border-radius: 3px; }
	.sceneGradientBar { height: 26px; margin: 8px 6px 22px; }
	<!--- Each band's color is picked with the Band color picker below the bar, not Grapick's own small input. --->
	.sceneGradientBar .grp-handler-cp-c { display: none; }
	.sceneGradient .sceneRow { margin-bottom: 8px; }
	.sceneCardWrap { position: relative; }
	.sceneCardRemove { position: absolute; top: 8px; left: 8px; z-index: 2; min-width: 0; padding: 0 6px; }
	.sceneCardYours { position: absolute; bottom: 8px; left: 8px; padding: 2px 8px; border-radius: 10px; background: rgba(0,0,0,.55); color: #fff; font-size: 12px; }
	#sceneTemplateForm .sceneField { margin-bottom: 10px; }
	.sceneSuggest { margin-top: 6px; padding: 8px; border: 1px solid rgba(128,128,128,.45); border-radius: 6px; }
	.sceneSuggestItem { display: flex; align-items: center; gap: 8px; width: 100%; padding: 4px; margin: 0; border: 0; border-radius: 4px; background: transparent; color: inherit; font: inherit; text-align: left; cursor: pointer; }
	.sceneSuggestItem:hover, .sceneSuggestItem:focus { background: rgba(128,128,128,.18); outline: none; }
	.sceneSuggestSwatch { flex: 0 0 40px; height: 22px; border: 1px solid rgba(128,128,128,.6); border-radius: 3px; }
	.sceneSuggestItem > span:nth-child(2) { flex: 1 1 auto; }
	.sceneSuggestValue { opacity: .7; font-size: 12px; }
	#sceneGallery { flex: 1 1 auto; overflow: auto; padding: 14px 16px; }
	@media (max-width: 900px) {
		#sceneEditorBody { flex-direction: column; overflow: auto; }
		#sceneEditorList, #sceneEditorSettings { flex: 0 0 auto; overflow: visible; }
		#sceneEditorPreview { flex: 0 0 70vh; }
	}
</style>
<style><cfoutput>#sceneFontFaceCss#</cfoutput></style>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfset altClass = HtmlUtilsObj.getKendoClass(blockClass)>
<cfoutput>
<div id="sceneEditor">
	<div id="sceneEditorTop" class="#blockClass#">
	<cfif isNewScene>
		<button id="sceneRestart" type="button" class="k-button" style="display: none;" title="Pick another ready-made scene. What you've changed so far is replaced.">Start again</button>
	</cfif>
		<label for="sceneAlias">Name in posts:</label>
		<input type="text" id="sceneAlias" class="k-textbox" maxlength="80" style="width: 220px;" value="<cfif not isNewScene>#encodeForHtmlAttribute(scene.alias)#</cfif>"<cfif not isNewScene> readonly title="A saved scene keeps its name, so the posts that show it keep working."</cfif>>
		<label><input type="checkbox" id="sceneActive" class="k-checkbox"<cfif isNewScene or scene.active> checked</cfif>> Active</label>
		<button id="sceneSave" type="button" class="k-button k-primary">Save</button>
		<button id="scenePreviewFull" type="button" class="k-button" title="The scene as it is here, saved or not, full size in a new tab">Preview</button>
		<button id="sceneReset" type="button" class="k-button" title="Throw away the changes since the scene was last saved">Reset</button>
		<button id="sceneSaveTemplate" type="button" class="k-button" title="Keep this scene as a starting point in the New scene gallery">Save as ready-made</button>
		<span id="sceneSaved" class="k-form-hint"></span>
		<span class="k-form-hint" id="sceneUseHint"></span>
		<!--- Where the scene shows (owner, 10-19): pick a post or a page, show it there, then preview that post or page. With no
		posts (or pages) yet, the list offers to make one. --->
		<div id="sceneShowOn" style="flex: 1 0 100%; display: flex; flex-wrap: wrap; align-items: center; gap: 8px 12px;">
			<strong>Show this scene on</strong>
			<label for="sceneShowPost">a post</label><input id="sceneShowPost" style="width: 260px;">
			<label for="sceneShowPage">or a page</label><input id="sceneShowPage" style="width: 220px;">
			<button id="sceneShowApply" type="button" class="k-button" disabled>Show it there</button>
			<a id="sceneShowPreview" class="k-button" target="_blank" rel="noopener" style="display: none;" title="The post or page as visitors see it - with the scene as last saved">View the post</a>
			<span id="sceneShownOn" class="k-form-hint"></span>
		</div>
	</div>
<cfif isNewScene>
	<!--- New scene: the gallery comes first; the editor below shows once a starting point is picked. --->
	<div id="sceneGallery" class="#altClass#">
		<h4 class="adminBlockHeading">Pick a starting point</h4>
		<div>Every part of it can be changed: the words, pictures, fonts, colors and motion. You can also start from nothing.</div>
		<div id="sceneGalleryCards" class="sceneCards"></div>
	</div>
</cfif>
	<div id="sceneEditorBody"<cfif isNewScene> style="display: none;"</cfif>>
		<div id="sceneEditorList">
			<div class="adminDivBlock #blockClass#"><div id="sceneSectionList"></div></div>
			<div class="adminDivBlock #altClass#">
				<h4 class="adminBlockHeading sceneAddHeading">Add a section</h4>
				<button id="sceneAddSection" type="button" class="k-button k-primary">Add section...</button>
				<div class="k-form-hint">It goes after the selected section.</div>
			</div>
		</div>
		<div id="sceneEditorSettings" class="#blockClass#">
			<div id="sceneSettingsTop"></div>
			<div id="sceneTextBlock" class="sceneField">
				<label for="#selectorName#">Text</label>
				<textarea id="#selectorName#" name="#selectorName#"></textarea>
			</div>
			<div id="sceneSettingsRest"></div>
		</div>
		<div id="sceneEditorPreview" class="#altClass#">
			<div id="scenePreviewBar">
				<span>
					<button type="button" class="k-button scenePreviewSize" data-size="desktop" aria-pressed="true">Desktop</button>
					<button type="button" class="k-button scenePreviewSize" data-size="phone" aria-pressed="false">Mobile</button>
				</span>
				<button type="button" class="k-button" id="sceneExplodedOpen" style="display: none;" title="The layers fanned out, back to front, in a window of their own. Click one to pick it.">Exploded view</button>
				<span id="sceneHoldWrap" style="display: none;" title="Keeps the preview at one point of the hero's scroll, so you can watch a change in place.">
					<label><input type="checkbox" id="sceneHoldOn" class="k-checkbox"> Hold the scroll at</label>
					<input type="range" id="sceneHold" min="0" max="100" step="1" value="40" aria-label="Hold the scroll at this point of the hero">
					<span id="sceneHoldValue">40%</span>
				</span>
				<label title="Shows where each animation starts and ends. Visitors never see them."><input type="checkbox" id="scenePreviewGuides" class="k-checkbox"> Guides</label>
				<label title="What visitors see when they've asked their device for less motion."><input type="checkbox" id="scenePreviewReduced" class="k-checkbox"> Reduced motion</label>
				<button type="button" class="k-button" id="scenePreviewTop">Back to the top</button>
			</div>
			<div id="scenePreviewStage"><iframe id="scenePreviewFrame" title="Scene preview" src="#application.baseUrl#/admin/scenePreview.cfm"></iframe></div>
		</div>
	</div>
</div>
</cfoutput>

<script>
$(document).ready(function () {
	var sceneId = <cfoutput>#isNewScene ? 0 : scene.sceneId#</cfoutput>;
	var scene = <cfoutput>#sceneJsonText#</cfoutput>;
	var starters = <cfoutput>#startersJsonText#</cfoutput>;
	var LINKS = <cfoutput>#sceneLinksJsonText#</cfoutput>;
	var SHOWN_ON = <cfoutput>#serializeJSON(sceneShownOn)#</cfoutput>;
	var READY_FORMS = <cfoutput>#replace("[" & arrayToList(sceneReadyParts, ",") & "]", "</", "<\/", "all")#</cfoutput>;   <!--- { key, name } --->
	var MAPS = <cfoutput>#replace(replace("[" & arrayToList(sceneMapParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")#</cfoutput>;   <!--- { id, title, routes } --->
	var PRODUCTS = <cfoutput>#replace(replace("[" & arrayToList(sceneProductParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")#</cfoutput>;
	var THEME_FONTS = <cfoutput>#replace(replace(serializeJSON(sceneThemeFonts), "</", "<\/", "all"), "<!--", "<\!--", "all")#</cfoutput>;   <!--- [{ alias, name, headerFont, headerType, bodyFont, bodyType }] --->
	var THEME_FONT_FACES = <cfoutput>#serializeJSON(reReplace(sceneThemeFontFaces, "</?style[^>]*>", "", "all"))#</cfoutput>.replace(/<\/?style[^>]*>/g, "");
	var FORMS = <cfoutput>#replace(replace("[" & arrayToList(sceneFormParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")#</cfoutput>;   <!--- { alias, title, active } --->   <!--- the post ids that show this scene now --->   <!--- the blog's posts and pages: { id, title, page, released, url } --->
	var selected = -1;            <!--- -1 is the scene's own settings; 0... a section --->
	var aliasTyped = sceneId > 0; <!--- a new scene's name in posts follows its title until it is typed in --->
	var previewReady = false;
	var previewTimer = null;
	var origin = window.location.origin;

	var KINDS = [
		{ kind: "layeredHero", label: "Layered hero", hint: "Layers of a picture that move at different speeds." },
		{ kind: "photoHero", label: "Photo hero", hint: "One photo, held in place with a slow zoom." },
		{ kind: "vantaHero", label: "Animated hero", hint: "A Vanta animation behind the text." },
		{ kind: "gradientHero", label: "Gradient hero", hint: "Colors, no pictures." },
		{ kind: "videoHero", label: "Video hero", hint: "A silent looping video." },
		{ kind: "text", label: "Text block", hint: "Heading and text on a color." },
		{ kind: "imageSlide", label: "Image slide", hint: "A picture that moves slower than the page." },
		{ kind: "slideshow", label: "Slideshow", hint: "Pictures with captions; each scroll brings in the next." },
		{ kind: "form", label: "Form", hint: "One of your forms, with a heading and text." },
		{ kind: "map", label: "Map", hint: "One of your Azure maps, live, with a heading and text." },
		{ kind: "product", label: "Product", hint: "Something from your shop, with an Add to cart button." }
	];
	<!--- Kinds whose words are their own (each slide's heading and caption), not the section's heading and text. --->
	var OWN_TEXT = { slideshow: 1 };
	var HERO = { layeredHero: 1, photoHero: 1, vantaHero: 1, gradientHero: 1, videoHero: 1 };
	function kindLabel(kind) { for (var i = 0; i < KINDS.length; i++) { if (KINDS[i].kind === kind) { return KINDS[i].label; } } return kind; }

	scene.settings = scene.settings || {};
	scene.sections = scene.sections || [];

	<!--- ---------- Fields. A field's key is a path into the scene ("settings.scrub") or into the section ("overlay.colour"). --->
	var BASE_URL = "<cfoutput>#jsStringFormat(application.baseUrl)#</cfoutput>";
	var CSRF = "<cfoutput>#csrfToken#</cfoutput>";
	var FONT_EXT = "<cfoutput>#sceneFontExt#</cfoutput>";
	var FONTS = $.map(<cfoutput>#sceneFontsJson#</cfoutput>, function (f) {
		<!--- Adobe ColdFusion may send the keys in capitals. --->
		return { id: String(f.id || f.ID), name: f.name || f.NAME, fileName: f.fileName || f.FILENAME || "", webSafe: (f.webSafe === true || f.WEBSAFE === true), type: String(f.type || f.TYPE || "").toLowerCase() };
	});
	var pending = [];
	var SOFT_SETS = <cfoutput>#serializeJSON(sceneSoftSets)#</cfoutput>;             <!--- set-up that has to wait until a field is on the page (Kendo widgets, Grapick) --->

	var HEADING_SIZES = [["", "Theme default"], ["2rem", "Small"], ["2.75rem", "Medium"], ["3.5rem", "Large"], ["4.5rem", "Very large"], ["6rem", "Huge"]];
	var HEADING_SIZES_PHONE = [["", "Same as on a computer"], ["1.75rem", "Small"], ["2.25rem", "Medium"], ["2.75rem", "Large"], ["3.5rem", "Very large"]];
	var TEXT_SIZES = [["", "Theme default"], ["0.95rem", "Small"], ["1.15rem", "Medium"], ["1.35rem", "Large"], ["1.6rem", "Very large"]];
	var TEXT_SIZES_PHONE = [["", "Same as on a computer"], ["0.9rem", "Small"], ["1rem", "Medium"], ["1.15rem", "Large"]];
	var HEADING = { key: "heading", label: "Heading", type: "text" };
	<!--- A picture can turn while scrolling (2026-10-19, owner): good for a galaxy, gears, a wheel. --->
	var SPIN = { key: "spin", label: "Turn while scrolling", type: "select", options: [["", "No"], ["90", "A quarter turn"], ["180", "Half a turn"], ["360", "A full turn"], ["-90", "A quarter turn, the other way"], ["-180", "Half a turn, the other way"], ["-360", "A full turn, the other way"]], hint: "The picture is shown larger while it turns, so its corners never show." };
	var LOOK = [
		{ group: "Heading" },
		{ key: "headingFont", idKey: "headingFontId", label: "Font", type: "font" },
		{ key: "headingSize", label: "Size", type: "select", options: HEADING_SIZES },
		{ key: "headingSizePhone", label: "Size on mobile", type: "select", options: HEADING_SIZES_PHONE },
	<cfif sceneSplitText>
		<!--- Needs the SplitText plugin; without it the heading simply rises in. --->
		{ key: "headingEffect", label: "How it comes in", type: "select", options: [["", "Rises into place"], ["words", "Word by word"], ["letters", "Letter by letter"]] },
	</cfif>
		{ group: "Text" },
		{ key: "textFont", idKey: "textFontId", label: "Font", type: "font" },
		{ key: "textSize", label: "Size", type: "select", options: TEXT_SIZES },
		{ key: "textSizePhone", label: "Size on mobile", type: "select", options: TEXT_SIZES_PHONE },
		{ group: "Heading and text" },
		{ key: "align", label: "Line up", type: "select", options: [["", "Theme default"], ["left", "Left"], ["center", "Centre"], ["right", "Right"]] },
		{ key: "textColour", label: "Color", type: "colour" },
		{ key: "shadow", label: "Shadow behind them", type: "select", options: [["", "None"], ["soft", "Soft"], ["strong", "Strong"], ["glow", "Glow"]], hint: "Makes text stand out on a busy picture." },
		{ key: "shadowColour", label: "Shadow color", type: "colour" },
		<!--- A glow of its own (owner, 10-19), on its own or with the shadow - the same as the post Hero text window's. --->
		{ group: "Glow" },
		{ key: "glow.colour", label: "Glow color", type: "colour", hint: "A halo around the heading and text. Leave it empty for no glow; try a light or bright color on a dark picture." },
		{ key: "glow.opacity", label: "Glow opacity (0.1 to 1)", type: "number", min: 0.1, max: 1, step: 0.05, placeholder: "0.8" },
		{ key: "glow.softness", label: "Glow softness (pixels)", type: "number", min: 4, max: 60, step: 1, placeholder: "24", hint: "Low is a tight, crisp glow; high spreads it wide and soft." }
	];
	<!--- A button under the heading and text (owner, 10-19), on heroes and text blocks. --->
	var BUTTON = [
		{ group: "Button" },
		{ key: "buttonText", label: "Button words", type: "text", placeholder: "eg. Read the story", hint: "Leave it empty for no button." },
		{ key: "buttonUrl", label: "Goes to", type: "link" },
		{ key: "buttonColour", label: "Button color", type: "colour" },
		{ key: "buttonTextColour", label: "Button text color", type: "colour" }
	];
	var FADE = { key: "fadeColour", label: "Fade into color", type: "colour", hint: "The hero fades into this color at the bottom. Pick the color at the bottom of the picture, or of the next section." };
	var OVERLAY = [
		{ key: "overlay.colour", label: "Tint over the picture", type: "colour" },
		{ key: "overlay.opacity", label: "Tint strength (0 to 1)", type: "number", min: 0, max: 1, step: 0.05 }
	];
	var FIELDS = {
		scene: [
			{ key: "@name", label: "Title", type: "text", hint: "Only you see this, in the Scenes window." },
			<!--- Kind of scene (2026-10-22, owner): a hero parallax scene is a post's hero - see heroParallax in common/js/galaxieScene.js. --->
			{ key: "settings.type", label: "Kind of scene", type: "select", options: [["", "Scene"], ["heroParallax", "Hero parallax scene"]],
				hint: "A hero parallax scene is the hero at the top of a post: its layers move as it scrolls away, and it fades into the post. Its hold, fade color and depth are set for you." },
			{ key: "@pageColour", label: "Page color", type: "colour", hint: "Behind the scene and between its sections." },
			{ key: "settings.fontTheme", label: "Fonts from", type: "select", options: [["", "The theme with this scene's name, or the page's theme"]].concat($.map(THEME_FONTS, function (t) { return [[t.alias, t.name + " (" + (t.headerFont || "default") + " / " + (t.bodyFont || "default") + ")"]]; })),
				hint: "Large headings use that theme's Text font, and the text its Menu font. A font picked for a section still wins." },
			{ group: "Motion" },
			{ key: "settings.scrub", label: "Movement", type: "select", options: [["true", "Follows the scroll exactly"], ["0.5", "Smooth"], ["1", "Smoother"]] },
			{ key: "settings.intensity", label: "Depth (how far the layers move)", type: "number", min: 0.25, max: 2, step: 0.05, placeholder: "1" },
			{ key: "settings.pinLength", label: "How long a hero stays in place", type: "select", options: [["", "Default (twice the screen)"], ["150%", "1.5 screens"], ["200%", "2 screens"], ["250%", "2.5 screens"], ["300%", "3 screens"]] },
			{ key: "settings.fadeHeight", label: "Fade height", type: "select", options: [["", "Default"], ["0vh", "No fade"], ["20vh", "Short"], ["35vh", "Medium"], ["50vh", "Tall"], ["70vh", "Very tall"]] },
			{ key: "settings.rise", label: "How far the text rises (pixels)", type: "number", min: 0, max: 600, step: 10, placeholder: "160" },
			{ key: "settings.phoneMotion", label: "On mobile", type: "select", options: [["", "Full movement"], ["light", "Half the movement"]] }
		],
		text: [
			{ key: "colour", label: "Background color", type: "colour" },
			{ key: "gradient", label: "Or a gradient (used instead of the color)", type: "gradient" }
		],
		imageSlide: [
			{ key: "image", phoneKey: "imagePhone", label: "Picture", type: "image" },
			{ key: "imagePhone", label: "Smaller picture for mobile", type: "image", hint: "Made for you when you upload a large picture." },
			{ key: "alt", label: "Describe the picture (for screen readers)", type: "text" },
			SPIN
		],
		layeredHero: [{ key: "#artStyle", type: "artStyle" }, { key: "#layers", type: "layers" }, FADE],
		photoHero: [
			{ key: "image", phoneKey: "imagePhone", label: "Photo", type: "image" },
			{ key: "imagePhone", label: "Smaller photo for mobile", type: "image", hint: "Made for you when you upload a large photo." },
			{ key: "zoom", label: "Zoom while held (1 is none)", type: "number", min: 1, max: 2, step: 0.05, placeholder: "1.15" },
			SPIN
		].concat(OVERLAY, [FADE]),
		vantaHero: [
			{ key: "effect", label: "Animation", type: "select", options: [["WAVES", "Waves"], ["NET", "Net"], ["FOG", "Fog"], ["CLOUDS", "Clouds"], ["CLOUDS2", "Clouds 2"], ["BIRDS", "Birds"], ["GLOBE", "Globe"], ["RINGS", "Rings"]] },
			FADE
		],
		gradientHero: [{ key: "gradient", label: "Gradient", type: "gradient" }, FADE],
		map: [
			{ key: "mapId", label: "Map", type: "map" },
			{ key: "mapHeight", label: "Map height", type: "select", options: [["50", "Half the screen"], ["70", "Most of the screen"], ["100", "The whole screen"]] },
			{ key: "colour", label: "Background color", type: "colour" },
			{ key: "gradient", label: "Or a gradient (used instead of the color)", type: "gradient" }
		],
		product: [
			{ key: "product", label: "Product", type: "product" },
			{ key: "colour", label: "Background color", type: "colour" },
			{ key: "gradient", label: "Or a gradient (used instead of the color)", type: "gradient" }
		],
		form: [
			{ key: "form", label: "Form", type: "form" },
			{ key: "colour", label: "Background color", type: "colour" },
			{ key: "gradient", label: "Or a gradient (used instead of the color)", type: "gradient" }
		],
		slideshow: [
			{ key: "#slides", type: "slides" },
			{ key: "colour", label: "Color behind the pictures", type: "colour", hint: "Shows while a picture loads, and the hero before it fades into it." }
		],
		videoHero: [
			{ key: "video", label: "Video file (.mp4)", type: "text", placeholder: "/images/...", hint: "Video upload comes later; type the address of an .mp4 file on this site." },
			{ key: "poster", label: "Picture shown before it plays", type: "image" }
		].concat(OVERLAY, [FADE])
	};

	<!--- Each Vanta animation names its colors differently; these are the ones worth changing for each. Vanta takes plain colors
	only, no transparency. --->
	var VANTA_COLOURS = {
		WAVES: [["color", "Water"]],
		NET: [["color", "Lines"], ["backgroundColor", "Background"]],
		FOG: [["highlightColor", "Highlights"], ["midtoneColor", "Middle tones"], ["lowlightColor", "Shadows"], ["baseColor", "Base"]],
		CLOUDS: [["skyColor", "Sky"], ["cloudColor", "Clouds"], ["sunColor", "Sun"]],
		CLOUDS2: [["skyColor", "Sky"], ["cloudColor", "Clouds"], ["lightColor", "Light"]],
		BIRDS: [["backgroundColor", "Background"], ["color1", "Birds"], ["color2", "Birds, second color"]],
		GLOBE: [["color", "Lines"], ["color2", "Dots"], ["backgroundColor", "Background"]],
		RINGS: [["color", "Rings"], ["backgroundColor", "Background"]]
	};
	function sectionFields(section) {
		var fields = (FIELDS[section.kind] || []).slice();
		if (section.kind === "vantaHero") {
			var colours = $.map(VANTA_COLOURS[String(section.effect || "WAVES").toUpperCase()] || [], function (c) { return { key: "options." + c[0], label: c[1], type: "colour", solid: true }; });
			fields.splice(1, 0, { group: "Animation colors" });
			Array.prototype.splice.apply(fields, [2, 0].concat(colours));
		}
		<!--- Every section with a heading and text can have a button. --->
		if (HERO[section.kind] || section.kind === "text" || section.kind === "imageSlide") { fields = fields.concat(BUTTON); }
		return fields;
	}

	function target(key) {
		if (key.charAt(0) === "@") { return { obj: scene, path: [key.substr(1)] }; }
		var path = key.split(".");
		if (selected < 0) { return { obj: scene, path: path }; }
		return { obj: scene.sections[selected], path: path };
	}
	function getValue(key) {
		var t = target(key), o = t.obj;
		for (var i = 0; i < t.path.length; i++) { if (o === undefined || o === null) { return ""; } o = o[t.path[i]]; }
		return (o === undefined || o === null) ? "" : o;
	}
	function setValue(key, value) {
		var t = target(key), o = t.obj;
		for (var i = 0; i < t.path.length - 1; i++) { if (typeof o[t.path[i]] !== "object" || o[t.path[i]] === null) { o[t.path[i]] = {}; } o = o[t.path[i]]; }
		var last = t.path[t.path.length - 1];
		if (value === "" || value === null) { delete o[last]; } else { o[last] = value; }
	}
	<!--- Settings typed as text that the engine needs as numbers or true/false. --->
	function typed(field, raw) {
		if (raw === "") { return ""; }
		if (field.key === "settings.scrub") { return raw === "true" ? true : parseFloat(raw); }
		if (field.type === "number") { var n = parseFloat(raw); return isNaN(n) ? "" : n; }
		return raw;
	}
	function withBase(value) { return String(value || "").split("{baseUrl}").join(BASE_URL); }
	function alertBox(title, message, icon) {
		$.when(kendo.ui.ExtAlertDialog.show({ title: title, message: message, icon: icon || "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
	}

	<!--- Fonts: the engine gets a CSS font-family; the font's id is kept next to it so its file can be loaded wherever the scene is shown. --->
	function fontById(id) { for (var i = 0; i < FONTS.length; i++) { if (FONTS[i].id === String(id)) { return FONTS[i]; } } return null; }
	function fontFamily(f) {
		var fallback = f.type.indexOf("mono") >= 0 ? "monospace" : (f.type.indexOf("serif") >= 0 && f.type.indexOf("sans") < 0 ? "serif" : "sans-serif");
		return '"' + f.name.replace(/"/g, "") + '", ' + fallback;
	}
	<!--- The theme the scene takes its fonts from (2026-10-21): the one picked in Fonts from, else the theme with the scene's name;
	none means the page's own theme (scenePreview.cfm shows the blog's selected theme). Same rule as Scenes.cfc getFontTheme. --->
	function sceneFontTheme() {
		var wanted = (scene.settings || {}).fontTheme || "", name = String(scene.name || "").toLowerCase().replace(/[^a-z0-9]/g, "");
		var norm = function (x) { return String(x || "").toLowerCase().replace(/[^a-z0-9]/g, ""); };
		return $.grep(THEME_FONTS, function (t) { return wanted && t.alias === wanted; })[0]
			|| (name ? $.grep(THEME_FONTS, function (t) { return norm(t.name) === name || norm(t.alias) === name; })[0] : null) || null;
	}
	function sceneFontCss() {
		var css = "", seen = {};
		var theme = sceneFontTheme();
		if (theme) {
			css += THEME_FONT_FACES + ":root{"
				+ (theme.bodyFont ? "--galaxieSceneTextFont:'" + theme.bodyFont + "'" + (theme.bodyType ? "," + theme.bodyType : "") + ";" : "")
				+ (theme.headerFont ? "--galaxieSceneHeadingFont:'" + theme.headerFont + "'" + (theme.headerType ? "," + theme.headerType : "") + ";" : "") + "}";
		}
		$.each(scene.sections, function (i, s) {
			$.each([s.headingFontId, s.textFontId], function (j, id) {
				var f = id ? fontById(id) : null;
				if (f && !f.webSafe && f.fileName && !seen[f.id]) {
					seen[f.id] = true;
					css += '@font-face{font-family:"' + f.name.replace(/"/g, "") + '";src:url(' + BASE_URL + '/common/fonts/' + f.fileName + '.' + FONT_EXT + ') format("' + FONT_EXT + '");font-display:swap;}';
				}
			});
		});
		return css;
	}

	<!--- Pictures go to enclosures/scenes/ (ProxyController uploadSceneImage), which also makes a smaller copy for phones. --->
	function uploadPicture(file, status, done) {
		if (!file) { return; }
		var data = new FormData();
		data.append("csrfToken", CSRF);
		data.append("file", file);
		status.text("Uploading " + file.name + "...");
		jQuery.ajax({
			type: "post",
			url: BASE_URL + "/common/cfc/ProxyController.cfc?method=uploadSceneImage",
			data: data, processData: false, contentType: false, dataType: "json",
			success: function (response) {
				status.text("");
				if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
				if (response && response.success) { done(response); }
				else { alertBox("Could not upload the picture", (response && response.errorMessage) || "The picture could not be uploaded."); }
			},
			error: function (jqXHR, textStatus, error) {
				status.text("");
				if (jqXHR.status === 403) { createLoginWindow(); } else { alertBox("Error while uploading", error, "k-ext-error"); }
			}
		});
	}

	<!--- ---------- The color helper (2026-10-19, option A): a Suggest button on every color field, listing colors worked out in the
	browser from the section's own pictures and its neighbours - above all the bottom edge of the front picture, which is what a
	hero's fade has to melt into - and "Pick from the screen" with the browser's eyedropper where there is one (Chrome, Edge). --->
	function toHex(r, g, b) { return "#" + [r, g, b].map(function (n) { return ("0" + Math.round(n).toString(16)).slice(-2); }).join(""); }
	function loadPicture(src) {
		return new Promise(function (resolve, reject) {
			var img = new Image();
			img.onload = function () { resolve(img); };
			img.onerror = reject;
			img.src = withBase(src);
		});
	}
	<!--- A picture drawn small, to read its pixels quickly. --->
	function pixelsOf(img) {
		var w = Math.min(240, img.naturalWidth || 240), h = Math.max(1, Math.round(w * (img.naturalHeight || 1) / (img.naturalWidth || 1)));
		var canvas = document.createElement("canvas");
		canvas.width = w; canvas.height = h;
		var ctx = canvas.getContext("2d");
		ctx.drawImage(img, 0, 0, w, h);
		return { data: ctx.getImageData(0, 0, w, h).data, w: w, h: h };
	}
	<!--- The average of the bottom few rows, leaving out see-through pixels. --->
	function bottomColour(px) {
		var r = 0, g = 0, b = 0, n = 0, rows = Math.max(2, Math.round(px.h * 0.04));
		for (var y = px.h - rows; y < px.h; y++) {
			for (var x = 0; x < px.w; x++) {
				var i = (y * px.w + x) * 4;
				if (px.data[i + 3] > 200) { r += px.data[i]; g += px.data[i + 1]; b += px.data[i + 2]; n++; }
			}
		}
		return n ? toHex(r / n, g / n, b / n) : null;
	}
	<!--- The most common color, in groups of near colors, averaged within the winning group. --->
	function mainColour(px) {
		var groups = {}, best = null;
		for (var i = 0; i < px.data.length; i += 4) {
			if (px.data[i + 3] < 200) { continue; }
			var key = (px.data[i] >> 4) + "," + (px.data[i + 1] >> 4) + "," + (px.data[i + 2] >> 4);
			var gr = groups[key] || (groups[key] = { n: 0, r: 0, g: 0, b: 0 });
			gr.n++; gr.r += px.data[i]; gr.g += px.data[i + 1]; gr.b += px.data[i + 2];
			if (!best || gr.n > best.n) { best = gr; }
		}
		return best ? toHex(best.r / best.n, best.g / best.n, best.b / best.n) : null;
	}
	<!--- A section's own color: its background color, or the first color of its gradient. --->
	function sectionColour(s) {
		if (!s) { return null; }
		if (s.colour) { return s.colour; }
		var m = /(#[0-9a-f]{3,8}\b|rgba?\([^)]*\))/i.exec(s.gradient || "");
		return m ? m[1] : (s.fadeColour || null);
	}
	<!--- The pictures to read for a section: a layered hero's front layer (and all its layers, drawn together, for the main color);
	otherwise its photo, picture or video poster. --->
	function picturesOf(s) {
		if (!s) { return []; }
		if (s.kind === "layeredHero") { return $.map(s.layers || [], function (l) { return l.src; }); }
		return $.grep([s.image || s.poster], function (v) { return !!v; });
	}
	function suggestColours() {
		var s = selected >= 0 ? scene.sections[selected] : scene.sections[0];
		var srcs = picturesOf(s);
		var list = [];
		function add(label, colour, note) {
			if (!colour) { return; }
			for (var i = 0; i < list.length; i++) { if (String(list[i].colour).toLowerCase() === String(colour).toLowerCase()) { return; } }
			list.push({ label: label, colour: colour, note: note || "" });
		}
		var work = !srcs.length ? Promise.resolve() : Promise.all($.map(srcs, function (src) { return loadPicture(src).catch(function () { return null; }); })).then(function (imgs) {
			imgs = $.grep(imgs, function (img) { return !!img; });
			if (!imgs.length) { return; }
			var front = imgs[imgs.length - 1];
			add(s.kind === "layeredHero" ? "Bottom of the front layer" : "Bottom of the picture", bottomColour(pixelsOf(front)), "best match for the fade");
			<!--- All the layers drawn together, as the visitor sees them. --->
			var w = Math.min(240, front.naturalWidth || 240), h = Math.max(1, Math.round(w * (front.naturalHeight || 1) / (front.naturalWidth || 1)));
			var canvas = document.createElement("canvas");
			canvas.width = w; canvas.height = h;
			var ctx = canvas.getContext("2d");
			$.each(imgs, function (i, img) { ctx.drawImage(img, 0, 0, w, h); });
			add("The picture's main color", mainColour({ data: ctx.getImageData(0, 0, w, h).data, w: w, h: h }));
		});
		return work.catch(function () {}).then(function () {
			var at = selected >= 0 ? selected : 0;
			add("The next section's color", sectionColour(scene.sections[at + 1]));
			if (at > 0) { add("The section before", sectionColour(scene.sections[at - 1])); }
			add("The page color", scene.pageColour);
			return list;
		});
	}
	<!--- The Suggest list under a color field; picking one sets the field (apply) and closes the list. --->
	function showSuggestions(anchor, field, apply) {
		$(".sceneSuggest").remove();
		var box = $('<div class="sceneSuggest" role="listbox"></div>').text("Working out colors...");
		anchor.after(box);
		function close() { box.remove(); $(document).off(".sceneSuggest"); }
		setTimeout(function () {
			$(document).on("mousedown.sceneSuggest", function (e) { if (!$(e.target).closest(".sceneSuggest").length) { close(); } })
				.on("keydown.sceneSuggest", function (e) { if (e.key === "Escape") { close(); } });
		}, 0);
		suggestColours().then(function (list) {
			box.empty();
			if (!list.length) { box.append($('<div class="k-form-hint"></div>').text("No colors to suggest yet: add a picture or a color to this or the next section.")); }
			$.each(list, function (i, item) {
				var colour = field.solid && /^rgba?\(/i.test(item.colour) ? toHex.apply(null, (item.colour.match(/[\d.]+/g) || [0, 0, 0]).slice(0, 3).map(Number)) : item.colour;
				var pick = $('<button type="button" class="sceneSuggestItem" role="option"></button>')
					.append($('<span class="sceneSuggestSwatch"></span>').css("background", colour), $('<span></span>').text(item.label + (item.note ? " (" + item.note + ")" : "")), $('<span class="sceneSuggestValue"></span>').text(colour));
				pick.on("click", function () { apply(colour); close(); });
				box.append(pick);
			});
			if (window.EyeDropper) {
				box.append($('<button type="button" class="k-button" style="margin-top: 6px;">Pick from the screen</button>').on("click", function () {
					close();
					new window.EyeDropper().open().then(function (result) { apply(result.sRGBHex); }).catch(function () { <!--- cancelled ---> });
				}), $('<span class="k-form-hint"> any color you can see, the preview included</span>'));
			}
		});
	}

	function fieldHtml(field) {
		if (field.group) { return $('<h4 class="adminBlockHeading sceneFieldGroup"></h4>').text(field.group); }
		var wrap = $('<div class="sceneField"></div>');
		var id = "sceneField_" + field.key.replace(/[^A-Za-z0-9]/g, "_");
		var value = getValue(field.key), input;
		if (field.type === "layers") { return layersField(wrap); }
		if (field.type === "slides") { return slidesField(wrap); }
		if (field.type === "artStyle") {
			<!--- Flat / Soft (2026-10-19, owner): for a drawn scene that comes in both color styles, swaps every layer between
			images/scenes/{name}/ and images/scenes/{name}-soft/. Not shown for other layers. --->
			var artLayers = getValue("layers") || [];
			var art = artLayers.length ? /\/images\/scenes\/([a-z0-9]+?)(-soft)?\/\d+\.svg$/i.exec(artLayers[0].src || "") : null;
			if (!art || SOFT_SETS.indexOf(art[1].toLowerCase()) < 0) { return $(); }
			var style = $('<select></select>').attr("id", id).append('<option value="flat">Flat colors</option><option value="soft">Soft (ridges blend into each other)</option>').val(art[2] ? "soft" : "flat");
			style.on("change", function () {
				var from = new RegExp("/images/scenes/" + art[1] + "(-soft)?/", "i"), to = "/images/scenes/" + art[1] + ($(this).val() === "soft" ? "-soft" : "") + "/";
				$.each(artLayers, function (i, layer) { layer.src = String(layer.src).replace(from, to); if (layer.srcPhone) { layer.srcPhone = String(layer.srcPhone).replace(from, to); } });
				schedulePreview();
				setTimeout(renderSettings, 0);
			});
			wrap.append($('<label></label>').attr("for", id).text("Color style"), style);
			return wrap;
		}
		wrap.append($('<label></label>').attr("for", id).text(field.label));
		function hint() { if (field.hint) { wrap.append($('<div class="k-form-hint"></div>').text(field.hint)); } return wrap; }

		if (field.type === "map") {
			<!--- Which map (owner, 10-20), and making one right here (owner, 10-21): the same Create Map and Create Map Routes windows
			as a post's, in their scene mode - the map is saved on its own and comes back through galaxieSceneMapSaved below. --->
			var mapButtons = $('<div style="margin-top:6px"></div>');
			$('<button type="button" class="k-button"></button>').text(MAPS.length ? "Make a new map" : "Make a map").on("click", function () { createAdminInterfaceWindow(19, 0, "scene"); }).appendTo(mapButtons);
			mapButtons.append(" ");
			$('<button type="button" class="k-button"></button>').text("Make a route map").on("click", function () { createAdminInterfaceWindow(20, 0, "scene"); }).appendTo(mapButtons);
			if (!MAPS.length) {
				wrap.append($('<div class="k-form-hint"></div>').text("Find a place, or plan a route with stops, and save it: it goes straight into this section."), mapButtons);
				return wrap;
			}
			var mapPick = $('<select></select>').attr("id", id);
			$.each(MAPS, function (i, m) { mapPick.append($('<option></option>').attr("value", m.id).text(m.title + (m.routes ? " - route" : ""))); });
			mapPick.val(String(value || MAPS[0].id));
			mapPick.on("change", function () {
				var m = $.grep(MAPS, function (x) { return String(x.id) === mapPick.val(); })[0];
				setValue("mapId", m.id); setValue("mapType", m.routes ? "route" : "static"); schedulePreview();
			});
			var current = $.grep(MAPS, function (x) { return String(x.id) === String(value || MAPS[0].id); })[0];
			mapButtons.prepend($('<button type="button" class="k-button"></button>').text("Change this map").on("click", function () {
				var m = $.grep(MAPS, function (x) { return String(x.id) === mapPick.val(); })[0] || current;
				createAdminInterfaceWindow(m && m.routes ? 20 : 19, m ? m.id : 0, "scene");
			}), " ");
			wrap.append(mapPick, mapButtons, $('<div class="k-form-hint"></div>').text("The map is live: visitors can move and zoom it. Change this map here, or make a new one."));
			return wrap;
		}
		if (field.type === "product") {
			<!--- Which product (2026-10-21), or every product for a small shop right in the scene. --->
			var productPick = $('<select></select>').attr("id", id);
			if (!value) { productPick.append('<option value="">Choose a product...</option>'); }
			productPick.append($('<option></option>').attr("value", "*").text("All products"));
			$.each(PRODUCTS, function (i, p) { productPick.append($('<option></option>').attr("value", p.alias).text(p.name + " (" + p.price + ")")); });
			productPick.val(value || "");
			productPick.on("change", function () {
				var v = productPick.val();
				if (!v) { return; }
				var p = $.grep(PRODUCTS, function (x) { return x.alias === v; })[0];
				setValue("product", v); setValue("productName", v === "*" ? "All products" : (p ? p.name : v));
				schedulePreview();
			});
			wrap.append(productPick, $('<div class="k-form-hint"></div>').text(PRODUCTS.length ? "Visitors add it to their cart right in the scene. The preview here shows its name; the site shows the card." : "You have no products shown on the site yet. Add one under Forms, Bookings and Shop > Products."));
			return wrap;
		}
		if (field.type === "form") {
			<!--- Which form (owner, 10-19), from the blog's forms or the ready-made ones (owner, 10-20: non-technical owners shouldn't
			have to build a form). A ready-made one becomes this scene's own copy, named after the scene, the moment it's picked. --->
			var formPick = $('<select></select>').attr("id", id);
			if (FORMS.length) {
				var yours = $('<optgroup label="Your forms"></optgroup>').appendTo(formPick);
				$.each(FORMS, function (i, f) { yours.append($('<option></option>').attr("value", f.alias).text(f.title + (f.active ? "" : " (turned off)"))); });
			}
			if (READY_FORMS.length) {
				var ready = $('<optgroup label="Ready-made (a copy is made for this scene)"></optgroup>').appendTo(formPick);
				$.each(READY_FORMS, function (i, r) { ready.append($('<option></option>').attr("value", "ready:" + r.key).text(r.name)); });
			}
			<!--- A ready-made pick is remembered (pendingReadyMade) and the form is made when the scene is saved (owner, 10-20), so a
			scene that is never saved leaves no form behind. --->
			var readyPending = getValue("pendingReadyMade");
			if (!value && !readyPending) { formPick.prepend('<option value="">Choose a form...</option>'); }
			formPick.val(readyPending ? "ready:" + readyPending : (value || ""));
			formPick.on("change", function () {
				var v = formPick.val();
				if (!v) { return; }
				if (v.indexOf("ready:") === 0) {
					var r = $.grep(READY_FORMS, function (x) { return x.key === v.substr(6); })[0];
					setValue("form", ""); setValue("pendingReadyMade", r.key); setValue("formTitle", r.name);
				} else {
					var f = $.grep(FORMS, function (x) { return x.alias === v; })[0];
					setValue("pendingReadyMade", ""); setValue("form", f.alias); setValue("formTitle", f.title);
				}
				renderSettings(); schedulePreview();
			});
			wrap.append(formPick, $('<div class="k-form-hint"></div>').text("Visitors fill it in right in the scene, and you get each answer by email."));
			if (readyPending) {
				wrap.append($('<div class="k-form-hint"></div>').text("This ready-made form is made for this scene when you save the scene. Then you can change its questions here."));
				return wrap;
			}
			var picked = $.grep(FORMS, function (x) { return x.alias === value; })[0];
			if (picked) { wrap.append(quickEditForm(picked)); }
			return wrap;
		}
		if (field.type === "link") {
			<!--- Where a button goes (owner, 10-19): one of the blog's released posts or pages, or any address typed in. --->
			var pick = $('<select></select>').attr("id", id), other = $('<input class="k-textbox" placeholder="https://... or /a-path-on-this-site">').css({ width: "100%", marginTop: "6px" });
			pick.append('<option value="">Choose a post or page...</option>');
			var pagesGroup = $('<optgroup label="Pages"></optgroup>'), postsGroup = $('<optgroup label="Posts"></optgroup>');
			$.each(LINKS, function (i, l) { if (l.released) { (l.page ? pagesGroup : postsGroup).append($('<option></option>').attr("value", l.url).text(l.title)); } });
			pick.append(pagesGroup, postsGroup, '<option value="#other">Another address...</option>');
			var known = $.grep(LINKS, function (l) { return l.released && l.url === value; }).length > 0;
			pick.val(!value ? "" : known ? value : "#other");
			other.val(known ? "" : value).toggle(!!value && !known);
			pick.on("change", function () {
				var v = $(this).val();
				other.toggle(v === "#other");
				if (v !== "#other") { setValue(field.key, v); schedulePreview(); } else { setValue(field.key, $.trim(other.val())); other.trigger("focus"); }
			});
			other.on("input change", function () { setValue(field.key, $.trim($(this).val())); schedulePreview(); });
			wrap.append(pick, other);
			return hint();
		}
		if (field.type === "colour") {
			<!--- Kendo's color picker, with transparency unless the field takes plain colors only. None takes the color away. --->
			input = $('<input>').attr("id", id);
			var none = $('<button type="button" class="k-button">None</button>');
			var suggest = $('<button type="button" class="k-button" title="Colors from the pictures of this section and the sections next to it">Suggest</button>');
			var row = $('<div class="sceneRow"></div>').append(input, none, suggest);
			wrap.append(row);
			pending.push(function () {
				var picker = input.kendoColorPicker({
					value: value || null, opacity: !field.solid, buttons: false, preview: true, input: true,
					change: function () { setValue(field.key, this.value() || ""); schedulePreview(); }
				}).data("kendoColorPicker");
				none.on("click", function () { try { picker.value(null); } catch (e) {} setValue(field.key, ""); schedulePreview(); });
				suggest.on("click", function () {
					showSuggestions(row, field, function (colour) {
						try { picker.value(colour); } catch (e) {}
						setValue(field.key, colour);
						schedulePreview();
					});
				});
			});
			return hint();
		}
		if (field.type === "font") {
			input = $('<input>').attr("id", id);
			wrap.append(input);
			pending.push(function () {
				input.kendoDropDownList({
					dataSource: FONTS, dataTextField: "name", dataValueField: "id", optionLabel: "Theme default",
					template: '<span style="font-family:&quot;#: data.name #&quot;">#: data.name #</span>',
					value: getValue(field.idKey) ? String(getValue(field.idKey)) : "",
					change: function () {
						var f = fontById(this.value());
						setValue(field.key, f ? fontFamily(f) : "");
						setValue(field.idKey, f ? parseInt(f.id, 10) : "");
						schedulePreview();
					}
				});
				input.data("kendoDropDownList").wrapper.css("width", "100%");
			});
			return hint();
		}
		if (field.type === "image") {
			input = $('<input type="text" class="k-textbox" placeholder="Upload a picture, or type its address">').attr("id", id).val(value);
			var upload = $('<button type="button" class="k-button k-primary">Upload</button>');
			var file = $('<input type="file" accept="image/jpeg,image/png,image/webp,image/gif" style="display: none;">').attr("aria-label", field.label);
			var thumb = $('<img class="sceneThumb" alt="">');
			var status = $('<div class="k-form-hint"></div>');
			function showThumb(v) { if (v) { thumb.attr("src", withBase(v)).show(); } else { thumb.hide(); } }
			showThumb(value);
			upload.on("click", function () { file.trigger("click"); });
			file.on("change", function () {
				uploadPicture(this.files[0], status, function (response) {
					setValue(field.key, response.location);
					if (field.phoneKey) { setValue(field.phoneKey, response.phoneLocation || ""); }
					renderSettings();
					schedulePreview();
				});
				this.value = "";
			});
			input.on("input change", function () { setValue(field.key, $.trim($(this).val())); showThumb($.trim($(this).val())); schedulePreview(); });
			wrap.append($('<div class="sceneRow"></div>').append(input, upload), file, thumb, status);
			return hint();
		}
		if (field.type === "gradient") {
			var box = $('<div class="sceneGradient"></div>');
			wrap.append(box);
			pending.push(function () { buildGradient(box, field); });
			return hint();
		}
		if (field.type === "select") {
			input = $('<select></select>').attr("id", id);
			$.each(field.options, function (i, o) { input.append($('<option></option>').attr("value", o[0]).text(o[1])); });
			input.val(String(value === "" ? field.options[0][0] : value));
		} else {
			input = $('<input class="k-textbox">').attr({ id: id, type: field.type === "number" ? "number" : "text" }).val(value);
			if (field.type === "number") { input.attr({ min: field.min, max: field.max, step: field.step }); }
		}
		if (field.placeholder) { input.attr("placeholder", field.placeholder); }
		input.on("input change", function () {
			setValue(field.key, typed(field, $.trim($(this).val())));
			if (field.key === "@name" && !aliasTyped && sceneId === 0) { $("#sceneAlias").val(aliasFrom(scene.name || "")); updateUseHint(); }
			if (field.key === "heading") { renderList(); }
			<!--- Another animation has other colors to set. --->
			if (field.key === "effect") { setTimeout(renderSettings, 0); }
			schedulePreview();
		});
		wrap.append(input);
		return hint();
	}

	<!--- A gradient: Grapick's bar (the same library as the gradient editor) - click the bar to add a band, drag a band to move
	it, and pick its color below. The CSS box shows the result and takes a pasted gradient. --->
	var gradientCount = 0;
	function buildGradient(box, field) {
		var value = getValue(field.key);
		box.empty();
		if (!value) {
			box.append($('<button type="button" class="k-button">Use a gradient</button>').on("click", function () {
				var from = getValue("colour") || scene.pageColour || "#392630";
				setValue(field.key, "linear-gradient(180deg, " + from + " 0%, #1d1218 100%)");
				buildGradient(box, field);
				schedulePreview();
			}));
			return;
		}
		var barId = "sceneGradientBar" + (++gradientCount);
		var bar = $('<div class="sceneGradientBar"></div>').attr("id", barId);
		var shape = $('<select><option value="linear">Straight</option><option value="radial">Round</option></select>').attr("aria-label", "Gradient shape");
		var angle = $('<input type="number" class="k-textbox" min="0" max="360" step="5" style="width: 80px; flex: 0 0 80px;">').attr("aria-label", "Gradient angle in degrees");
		var band = $('<input>');
		var css = $('<input type="text" class="k-textbox">').attr("aria-label", "Gradient as CSS").val(value);
		var off = $('<button type="button" class="k-button">No gradient</button>');
		box.append(bar,
			$('<div class="sceneRow"></div>').append($('<span>Shape</span>'), $('<span style="flex: 1 1 auto;"></span>').append(shape), $('<span>Angle</span>'), angle),
			$('<div class="sceneRow"></div>').append($('<span>Band color</span>'), band),
			$('<div class="sceneRow"></div>').append(css, off),
			$('<div class="k-form-hint">Click the bar to add a color band, drag a band to move it, and click the x above a band to remove it. You can also paste a CSS gradient into the box.</div>'));
		off.on("click", function () { setValue(field.key, ""); buildGradient(box, field); schedulePreview(); });
		galaxieLoader.grapickPickr(function () {
			if (!document.getElementById(barId)) { return; }   <!--- another section was picked meanwhile --->
			var loading = true;
			var gp = new Grapick({ el: "#" + barId, direction: "right" });
			gp.setValue(value);
			var picker = band.kendoColorPicker({ opacity: true, buttons: false, preview: true, input: true,
				change: function () { var h = selectedBand(); if (h) { h.setColor(this.value()); } } }).data("kendoColorPicker");
			<!--- The band the color picker changes: the one picked on the bar, or the first one (a loaded gradient has none picked). --->
			function selectedBand() {
				var h = gp.getSelected();
				if (!h && gp.getHandlers().length) { h = gp.getHandlers()[0]; try { h.select(); } catch (e) {} }
				return h;
			}
			function syncBand() { var h = selectedBand(); if (h) { try { picker.value(h.getColor()); } catch (e) {} } }
			function readBack() {
				shape.data("kendoDropDownList").value(gp.getType ? gp.getType() : (String(value).indexOf("radial") >= 0 ? "radial" : "linear"));
				var m = /(-?[0-9.]+)deg/.exec(gp.getValue());
				angle.val(m ? Math.round(parseFloat(m[1])) : 180).prop("disabled", shape.val() === "radial");
			}
			shape.kendoDropDownList({ change: function () { gp.setType(this.value()); readBack(); } });
			gp.on("handler:select", syncBand);
			gp.on("change", function () {
				if (loading) { return; }
				var v = gp.getValue();
				setValue(field.key, v);
				css.val(v);
				schedulePreview();
			});
			angle.on("input", function () { if ($(this).val() !== "") { gp.setDirection($(this).val() + "deg"); } });
			css.on("change", function () {
				var v = $.trim($(this).val());
				if (/gradient\(/.test(v)) { gp.setValue(v); readBack(); syncBand(); }
			});
			readBack();
			syncBand();
			loading = false;
		});
	}

	<!--- The settings in the owner's admin blocks: the fields above the text and the text in the first block, then a new block, in the
	other color, at each group heading (Look, Motion...). --->
	var SETTINGS_CLASSES = ["<cfoutput>#blockClass#</cfoutput>", "<cfoutput>#altClass#</cfoutput>"];
	function blockSettings() {
		$("#sceneSettingsTop, #sceneTextBlock").attr("class", function () { return (this.id === "sceneTextBlock" ? "sceneField " : "") + "adminDivBlock " + SETTINGS_CLASSES[0]; });
		var rest = $("#sceneSettingsRest"), items = rest.children().detach(), n = 0;
		var block = $('<div class="adminDivBlock"></div>').addClass(SETTINGS_CLASSES[0]).appendTo(rest);
		items.each(function () {
			if ($(this).hasClass("sceneFieldGroup")) { n++; block = $('<div class="adminDivBlock"></div>').addClass(SETTINGS_CLASSES[n % 2]).appendTo(rest); }
			block.append(this);
		});
	}

	<!--- The settings pane: the fields above the text, the text editor (kept in place, see the TinyMCE notes below), the rest. --->
	function renderSettings() {
		var top = $("#sceneSettingsTop").empty(), rest = $("#sceneSettingsRest").empty();
		pending = [];
		if (selected < 0) {
			top.append($('<h4 class="adminBlockHeading"></h4>').text("Scene"));
			$.each(FIELDS.scene, function (i, field) { top.append(fieldHtml(field)); });
		} else {
			var section = scene.sections[selected];
			top.append($('<h4 class="adminBlockHeading"></h4>').text(kindLabel(section.kind)));
			if (!OWN_TEXT[section.kind]) { top.append(fieldHtml(HEADING)); }
			$.each(sectionFields(section).concat(LOOK), function (i, field) { rest.append(fieldHtml(field)); });
		}
		blockSettings();
		kendoSelects("#sceneSettingsTop, #sceneSettingsRest");
		$.each(pending, function (i, fn) { fn(); });
		pending = [];
		showText();
		updatePreviewTools();
	}

	<!--- The section's text, in one TinyMCE editor that stays where it is while sections are picked (a TinyMCE editor that is
	moved around the page loses its content), filled with the picked section's text and hidden for the scene's own settings. --->
	var textEditorId = "<cfoutput>#selectorName#</cfoutput>";
	var textEditor = null;
	var fillingText = false;
	function showText() {
		if (!textEditor) { return; }
		$("#sceneTextBlock").toggle(selected >= 0 && !OWN_TEXT[scene.sections[selected].kind]);
		fillingText = true;
		textEditor.setContent(selected >= 0 ? (scene.sections[selected].html || "") : "");
		fillingText = false;
	}
	(function waitForTextEditor(tries) {
		var editor = window.tinymce ? tinymce.get(textEditorId) : null;
		if (editor && editor.initialized) {
			textEditor = editor;
			editor.on("input change keyup undo redo ExecCommand", function () {
				if (fillingText || selected < 0) { return; }
				var html = editor.getContent();
				if (scene.sections[selected].html !== html) { scene.sections[selected].html = html; schedulePreview(); }
			});
			showText();
		} else if (tries < 200) {
			setTimeout(function () { waitForTextEditor(tries + 1); }, 100);
		}
	})(0);

	<!--- Kendo dropdowns, like the other admin windows. Their change is passed on to the select, where the field listens. --->
	function kendoSelects(where) {
		$(where).find("select").each(function () {
			if (!$(this).data("kendoDropDownList")) { if (!this.style.width) { $(this).css("width", "100%"); } $(this).kendoDropDownList({ change: function () { this.element.trigger("change"); } }); }
		});
	}

	<!--- ---------- The section list --->
	function renderList() {
		var list = $("#sceneSectionList").empty();
		var item = $('<div class="sceneSectionItem"></div>').toggleClass("selected", selected < 0);
		item.append('<span class="sceneSectionKind">Scene settings</span><span class="sceneSectionHeading">Colors and motion</span>');
		item.on("click", function () { select(-1); });
		list.append(item);
		$.each(scene.sections, function (i, section) {
			var it = $('<div class="sceneSectionItem"></div>').toggleClass("selected", selected === i).attr("data-index", i);
			var tools = $('<span class="sceneSectionTools"></span>');
			if (i > 0) { tools.append($('<button type="button" class="k-button" aria-label="Move up"><span class="k-icon k-i-arrow-60-up"></span></button>').on("click", function (e) { e.stopPropagation(); move(i, -1); })); }
			if (i < scene.sections.length - 1) { tools.append($('<button type="button" class="k-button" aria-label="Move down"><span class="k-icon k-i-arrow-60-down"></span></button>').on("click", function (e) { e.stopPropagation(); move(i, 1); })); }
			tools.append($('<button type="button" class="k-button" aria-label="Remove"><span class="k-icon k-i-close"></span></button>').on("click", function (e) { e.stopPropagation(); remove(i); }));
			it.append(tools);
			it.append($('<span class="sceneSectionKind"></span>').text((i + 1) + ". " + kindLabel(section.kind)));
			it.append($('<span class="sceneSectionHeading"></span>').text(section.heading || "No heading"));
			it.on("click", function () { select(i); });
			list.append(it);
		});
		<!--- Drag a section to move it (owner, 10-19). Scene settings stays at the top; the arrows still work. --->
		var old = list.data("kendoSortable"); if (old) { old.destroy(); }
		list.kendoSortable({
			filter: ".sceneSectionItem[data-index]", ignore: "button, .k-icon", cursor: "move", holdToDrag: false,
			placeholder: function (element) { return element.clone().css({ opacity: 0.35 }); },
			hint: function (element) { return element.clone().css({ width: element.width(), background: "#ffffff", boxShadow: "0 4px 14px rgba(0,0,0,.25)" }); },
			change: function (e) {
				var from = e.oldIndex, to = e.newIndex;
				var s = scene.sections.splice(from, 1)[0];
				scene.sections.splice(to, 0, s);
				selected = to;
				setTimeout(function () { renderList(); renderSettings(); }, 0);
				schedulePreview();
			}
		});
	}
	function select(i) { if (i !== selected) { selectedLayer = -1; } selected = i; renderList(); renderSettings(); }
	function move(i, by) {
		var s = scene.sections.splice(i, 1)[0];
		scene.sections.splice(i + by, 0, s);
		selected = i + by;
		renderList(); renderSettings(); schedulePreview();
	}
	function remove(i) {
		scene.sections.splice(i, 1);
		selected = Math.min(selected, scene.sections.length - 1);
		renderList(); renderSettings(); schedulePreview();
	}
	<!--- A map made or changed from a Map section (2026-10-21): it joins the list and goes into the selected section. --->
	window.galaxieSceneMapSaved = function (info) {
		if (!info || !(info.mapId > 0)) { return; }
		var title = $.trim(info.title || "") || ("Map " + info.mapId);
		var known = $.grep(MAPS, function (x) { return String(x.id) === String(info.mapId); })[0];
		if (known) { known.routes = !!info.routes; if ($.trim(info.title || "")) { known.title = title; } }
		else { MAPS.unshift({ id: info.mapId, title: title, routes: !!info.routes }); }
		setValue("mapId", info.mapId); setValue("mapType", info.routes ? "route" : "static");
		renderSettings(); schedulePreview();
	};
	function newSection(kind) {
		var s = { kind: kind, heading: "", html: "" };
		if (kind === "text") { s.heading = "A new heading"; s.html = "<p>Your text.</p>"; s.colour = scene.pageColour || "#392630"; }
		if (kind === "vantaHero") { s.effect = "WAVES"; s.options = { color: "#0e3b5c" }; }
		if (kind === "form") {
			s.heading = "Get in touch"; s.html = "<p>Send us a note and we'll get back to you.</p>"; s.colour = scene.pageColour || "#392630";
			<!--- A Contact form of its own (owner, 10-20), so the section works without any setup; made when the scene is saved. --->
			if ($.grep(READY_FORMS, function (r) { return r.key === "contact"; }).length) { s.pendingReadyMade = "contact"; s.formTitle = "Contact"; }
		}
		if (kind === "slideshow") { s.slides = []; s.colour = "#111111"; delete s.html; }
		if (kind === "product") {
			s.heading = "From the shop"; s.html = ""; s.colour = scene.pageColour || "#392630";
			if (PRODUCTS.length) { s.product = PRODUCTS[0].alias; s.productName = PRODUCTS[0].name; }
		}
		if (kind === "map") { s.heading = "Where to find us"; s.html = ""; s.colour = scene.pageColour || "#392630"; s.mapHeight = "70"; if (MAPS.length) { s.mapId = MAPS[0].id; s.mapType = MAPS[0].routes ? "route" : "static"; } }
		if (kind === "gradientHero") { s.gradient = "linear-gradient(135deg, #1d4350 0%, #a43931 100%)"; }
		if (kind === "layeredHero") {
			<!--- Until the layer builder: the layers of the first ready-made layered scene. --->
			$.each(starters, function (i, st) { $.each(st.json.sections || [], function (j, sec) { if (!s.layers && sec.kind === "layeredHero") { s.layers = JSON.parse(JSON.stringify(sec.layers)); s.fadeColour = sec.fadeColour; } }); });
			s.layers = s.layers || [];
		}
		if (HERO[kind]) { s.heading = "A new hero"; }
		return s;
	}
	kendoSelects("#sceneEditorTop");
	<!--- Add a section (owner, 10-20, option B): a window of cards, one per kind, in two groups, each with a small drawing of what
	it looks like. The new section goes after the selected one, or at the end when Scene settings is selected. --->
	var KIND_GROUPS = [["Heroes - the big picture at the top", ["layeredHero", "photoHero", "vantaHero", "gradientHero", "videoHero"]],
		["Content", ["text", "imageSlide", "slideshow", "form", "map", "product"]]];
	var KIND_SKETCHES = {
		layeredHero: '<rect width="200" height="96" fill="#9fc3e6"/><path d="M0 70 L40 40 L80 62 L120 30 L160 58 L200 38 V96 H0Z" fill="#6c8fb3"/><path d="M0 80 L50 58 L100 76 L150 52 L200 72 V96 H0Z" fill="#3f5f80"/><path d="M0 90 L70 74 L130 88 L200 80 V96 H0Z" fill="#26384d"/>',
		photoHero: '<defs><linearGradient id="kindPhoto" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#f6c38b"/><stop offset="1" stop-color="#c0603b"/></linearGradient></defs><rect width="200" height="96" fill="url(#kindPhoto)"/><circle cx="150" cy="34" r="14" fill="#fff3c4"/><path d="M0 96 L60 60 L110 80 L160 56 L200 72 V96Z" fill="#5b3424"/><rect x="18" y="34" width="70" height="8" rx="2" fill="#fff"/>',
		vantaHero: '<rect width="200" height="96" fill="#0e3b5c"/><path d="M0 50 Q25 30 50 50 T100 50 T150 50 T200 50" stroke="#4fa3d9" stroke-width="3" fill="none"/><path d="M0 66 Q25 46 50 66 T100 66 T150 66 T200 66" stroke="#2e7bb0" stroke-width="3" fill="none"/><path d="M0 34 Q25 14 50 34 T100 34 T150 34 T200 34" stroke="#7cc4f0" stroke-width="2" fill="none"/>',
		gradientHero: '<defs><linearGradient id="kindGradient" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1d4350"/><stop offset="1" stop-color="#a43931"/></linearGradient></defs><rect width="200" height="96" fill="url(#kindGradient)"/><rect x="18" y="38" width="80" height="8" rx="2" fill="#fff"/><rect x="18" y="52" width="56" height="5" rx="2" fill="#fff" opacity=".7"/>',
		videoHero: '<rect width="200" height="96" fill="#2b2b2b"/><circle cx="100" cy="48" r="20" fill="#fff" opacity=".9"/><path d="M94 38 L94 58 L112 48Z" fill="#2b2b2b"/>',
		text: '<rect width="200" height="96" fill="#392630"/><rect x="24" y="22" width="110" height="10" rx="2" fill="#fff"/><rect x="24" y="42" width="150" height="5" rx="2" fill="#fff" opacity=".6"/><rect x="24" y="53" width="140" height="5" rx="2" fill="#fff" opacity=".6"/><rect x="24" y="64" width="120" height="5" rx="2" fill="#fff" opacity=".6"/>',
		imageSlide: '<rect width="200" height="96" fill="#e8ecef"/><rect x="30" y="14" width="140" height="68" rx="3" fill="#7aa874"/><path d="M30 82 L80 46 L120 70 L150 52 L170 64 V82Z" fill="#4c7a47"/><circle cx="140" cy="30" r="8" fill="#f3e9a2"/>',
		slideshow: '<rect width="200" height="96" fill="#111"/><rect x="40" y="12" width="120" height="58" rx="3" fill="#6a7fa8"/><rect x="18" y="20" width="16" height="42" rx="2" fill="#3c4a66"/><rect x="166" y="20" width="16" height="42" rx="2" fill="#3c4a66"/><circle cx="88" cy="82" r="3" fill="#fff"/><circle cx="100" cy="82" r="3" fill="#fff" opacity=".4"/><circle cx="112" cy="82" r="3" fill="#fff" opacity=".4"/>',
		form: '<rect width="200" height="96" fill="#392630"/><rect x="30" y="12" width="90" height="8" rx="2" fill="#fff"/><rect x="30" y="28" width="140" height="12" rx="3" fill="#fff" opacity=".9"/><rect x="30" y="46" width="140" height="12" rx="3" fill="#fff" opacity=".9"/><rect x="30" y="66" width="44" height="14" rx="3" fill="#007bff"/>',
		product: '<rect width="200" height="96" fill="#392630"/><rect x="24" y="14" width="70" height="8" rx="2" fill="#fff"/><rect x="24" y="32" width="152" height="54" rx="5" fill="#fff"/><rect x="32" y="40" width="38" height="38" rx="3" fill="#c98b5b"/><rect x="80" y="44" width="70" height="6" rx="2" fill="#555"/><rect x="80" y="56" width="34" height="6" rx="2" fill="#555"/><rect x="80" y="68" width="40" height="10" rx="3" fill="#007bff"/>',
		map: '<rect width="200" height="96" fill="#e6efe0"/><path d="M0 30 H200 M0 64 H200 M60 0 V96 M140 0 V96" stroke="#fff" stroke-width="6"/><path d="M0 80 Q60 60 100 70 T200 40" stroke="#9ec2e8" stroke-width="8" fill="none"/><path d="M100 22 a10 10 0 1 1 0.1 0 Z" fill="#d1242f"/><path d="M92 30 L100 46 L108 30Z" fill="#d1242f"/><circle cx="100" cy="28" r="4" fill="#fff"/>'
	};
	var KIND_TEXT = {
		layeredHero: "Layers of a picture that move at different speeds as you scroll.", photoHero: "One photo, held in place with a slow zoom.",
		vantaHero: "A moving animation behind the text: waves, fog, clouds, birds...", gradientHero: "Colors that blend, no pictures.", videoHero: "A silent looping video.",
		text: "A heading and text on a color or gradient.", imageSlide: "A picture that moves slower than the page.", slideshow: "Pictures with captions; each scroll brings in the next.",
		form: "A contact form, or one of yours, right in the scene.", map: "One of your Azure maps, live, with a heading and text.",
		product: "Something from your shop, with an Add to cart button."
	};
	function addSection(kind) {
		var at = selected < 0 ? scene.sections.length : selected + 1;
		var section = newSection(kind);
		scene.sections.splice(at, 0, section);
		select(at);
		schedulePreview();
	}
	function openSectionPicker() {
		$("#sceneKindWindow").closest(".k-window").remove();
		var box = $('<div id="sceneKindWindow"></div>').appendTo(document.body);
		var after = selected < 0 || !scene.sections[selected] ? "at the end" : "after " + (selected + 1) + ". " + kindLabel(scene.sections[selected].kind);
		box.append($('<p style="margin: 0 0 12px;"></p>').text("Pick what to add. It goes " + after + "; you can drag it somewhere else later."));
		var cards = $('<div class="sceneKindCards"></div>').appendTo(box);
		$.each(KIND_GROUPS, function (g, group) {
			cards.append($('<div class="sceneKindGroup"></div>').text(group[0]));
			$.each(group[1], function (i, kind) {
				var known = $.grep(KINDS, function (k) { return k.kind === kind; })[0];
				if (!known) { return; }
				cards.append($('<button type="button" class="sceneKindCard"></button>')
					.append('<svg viewBox="0 0 200 96" preserveAspectRatio="xMidYMid slice" aria-hidden="true">' + KIND_SKETCHES[kind] + '</svg>',
						$('<div class="sceneKindText"></div>').append($("<b></b>").text(known.label), $("<span></span>").text(KIND_TEXT[kind] || known.hint)))
					.on("click", function () { win.close(); addSection(kind); }));
			});
		});
		var win = box.kendoWindow({
			title: "Add a section", modal: true, resizable: false, actions: ["Close"],
			width: Math.min(800, $(window).width() - 30), maxHeight: Math.max(300, $(window).height() - 60),
			close: function () { setTimeout(function () { win.destroy(); }, 0); }
		}).data("kendoWindow");
		win.center().open();
		box.find(".sceneKindCard").first().trigger("focus");
	}
	$("#sceneAddSection").on("click", openSectionPicker);

	<!--- ---------- Forms (owner, 10-20): a ready-made form as this scene's own copy, and a quick edit of the picked form ---------- --->
	function sceneLabel() { return $.trim(scene.name || $("#sceneAlias").val() || "") ? $.trim(scene.name || $("#sceneAlias").val()) + " scene" : "scene"; }
	function makeReadyForm(key, done, failed) {
		jQuery.ajax({
			type: "post", url: BASE_URL + "/common/cfc/ProxyController.cfc?method=useReadyMadeForm",
			data: { csrfToken: CSRF, key: key, usedFor: sceneLabel() }, dataType: "json",
			success: function (response) {
				if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
				if (response && response.success) {
					var f = { id: response.webFormId, alias: response.alias, title: response.title, active: true };
					FORMS.unshift(f);
					done(f);
				} else {
					if (failed) { failed(); }
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Form not ready", message: $("<div/>").text(((response && response.errors) || ["The form could not be made."]).join(" ")).html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				}
			},
			error: function (jqXHR) { if (failed) { failed(); } if (jqXHR.status === 403) { createLoginWindow(); } }
		});
	}
	<!--- The quick edit: the words above the form, each question's wording and whether it must be answered (or remove it), the
	button and where answers go. Anything more (choices, new questions) is in the full form editor, a click away. --->
	function quickEditForm(f) {
		var box = $('<div class="sceneQuickEdit"></div>');
		var open = $('<button type="button" class="k-button" style="margin-top: 6px;">Change the questions</button>');
		var full = $('<a href="#" style="margin-left: 10px;">Full form editor</a>').on("click", function (e) { e.preventDefault(); createAdminInterfaceWindow(84, f.id); });
		var panel = $('<div style="display: none; margin-top: 8px;"></div>');
		box.append(open, full, panel);
		open.on("click", function () {
			if (panel.is(":visible")) { panel.hide(); return; }
			panel.show().text("Loading the form...");
			jQuery.ajax({
				type: "post", url: BASE_URL + "/common/cfc/ProxyController.cfc?method=getWebFormQuickEdit",
				data: { csrfToken: CSRF, webFormId: f.id }, dataType: "json",
				success: function (response) {
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (!response || !response.success) { panel.text("This form can't be opened here. Use the full form editor."); return; }
					drawQuickEdit(panel, response.form, f);
				},
				error: function (jqXHR) { panel.text("This form can't be opened here."); if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});
		return box;
	}
	function drawQuickEdit(panel, form, f) {
		panel.empty();
		var words = $('<textarea class="k-textbox" rows="2" style="width: 100%;"></textarea>').val(form.description);
		panel.append($("<label>Words above the form</label>"), words);
		var list = $('<div style="margin-top: 8px;"></div>');
		panel.append($('<label style="display: block; margin-top: 8px;">Questions</label>'), list);
		$.each(form.fields, function (i, q) {
			var row = $('<div class="sceneRow" style="margin-bottom: 6px;"></div>').data("id", q.webFormFieldId);
			var must = $('<input type="checkbox" class="k-checkbox">').prop("checked", q.required).attr("id", "sceneQuickMust" + q.webFormFieldId);
			row.append($('<input type="text" class="k-textbox sceneQuickLabel">').val(q.label),
				$("<label></label>").attr("title", "Must be answered").append(must, " Must answer"),
				$('<button type="button" class="k-button" title="Remove this question">x</button>').on("click", function () { row.remove(); }));
			list.append(row);
		});
		var button = $('<input type="text" class="k-textbox" style="width: 100%;">').val(form.buttonLabel);
		var emails = $('<input type="text" class="k-textbox" style="width: 100%;">').val(form.notifyEmails).attr("placeholder", form.blogEmail || "The blog's email address");
		var status = $('<span class="k-form-hint"></span>');
		var save = $('<button type="button" class="k-button k-primary">Save the form</button>');
		panel.append($('<label style="display: block; margin-top: 8px;">Button</label>'), button,
			$('<label style="display: block; margin-top: 8px;">Send answers to</label>'), emails,
			$('<div class="k-form-hint"></div>').text("Leave it empty to send them to the blog's email address. Separate more than one with commas."),
			$('<div style="margin-top: 8px;"></div>').append(save, " ", status));
		save.on("click", function () {
			var fields = list.children().map(function () {
				return { webFormFieldId: $(this).data("id"), label: $.trim($(this).find(".sceneQuickLabel").val()), required: $(this).find("input[type=checkbox]").is(":checked") };
			}).get();
			if (!fields.length) { status.text("A form needs at least one question."); return; }
			save.prop("disabled", true); status.text("Saving...");
			jQuery.ajax({
				type: "post", url: BASE_URL + "/common/cfc/ProxyController.cfc?method=saveWebFormQuickEdit",
				data: { csrfToken: CSRF, webFormId: f.id, description: words.val(), buttonLabel: button.val(), notifyEmails: emails.val(), fieldsJson: JSON.stringify(fields) }, dataType: "json",
				success: function (response) {
					save.prop("disabled", false);
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					status.text(response && response.success ? "Saved." : ((response && response.errorMessage) || "The form could not be saved."));
				},
				error: function (jqXHR) { save.prop("disabled", false); status.text("The form could not be saved."); if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});
	}

	<!--- ---------- Name in posts --->
	function aliasFrom(text) { return text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").substr(0, 80); }
	function updateUseHint() {
		var alias = $.trim($("#sceneAlias").val());
		$("#sceneUseHint").text(alias.length ? "To show it on a post, put <galaxieScene>" + alias + "</galaxieScene> in the post's header." : "");
	}
	if (sceneId === 0) { $("#sceneAlias").val(aliasFrom(scene.name || "")); }
	$("#sceneAlias").on("input", function () { aliasTyped = true; updateUseHint(); });
	updateUseHint();

	<!--- ---------- The gallery (new scenes) --->
	function cardThumb(data) { return galaxieSceneCardThumb(data, BASE_URL); }
	function startFrom(data) {
		scene = JSON.parse(JSON.stringify(data));
		scene.settings = scene.settings || {}; scene.sections = scene.sections || [];
		<!--- A ready-made scene names its fonts (ids differ from blog to blog): find this blog's font of that name. --->
		$.each(scene.sections, function (i, s) {
			$.each(["heading", "text"], function (j, part) {
				var m = /^"([^"]+)"/.exec(s[part + "Font"] || "");
				if (m && !s[part + "FontId"]) {
					var f = $.grep(FONTS, function (font) { return font.name === m[1]; })[0];
					if (f) { s[part + "FontId"] = parseInt(f.id, 10); }
				}
			});
		});
		delete scene.description; delete scene.thumbnail;
		savedScene = JSON.stringify(scene);
		if (!aliasTyped) { $("#sceneAlias").val(aliasFrom(scene.name || "")); updateUseHint(); }
		$("#sceneGallery").hide();
		$("#sceneEditorTop").css("display", "");
		$("#sceneEditorBody").show();
		$("#sceneRestart").show();
		select(-1);
		<!--- The preview was hidden while the gallery showed, so it is measured again now. --->
		setTimeout(sendPreview, 50);
	}
	function showGallery() {
		var cards = $("#sceneGalleryCards").empty();
		$.each(starters, function (i, st) {
			var thumb = cardThumb(st.json);
			var card = $('<button type="button" class="sceneCard"></button>').append(thumb,
				$('<div class="sceneCardText"></div>').append($('<strong></strong>').text(st.name), $('<span></span>').text(st.json.description || "")));
			card.on("click", function () { startFrom(st.json); });
			if (!st.json.templateId) { cards.append(card); return; }
			<!--- One of the owner's own ready-made scenes: marked as theirs, with a button to remove it from the gallery. --->
			thumb.append('<span class="sceneCardYours">Yours</span>');
			var remove = $('<button type="button" class="k-button sceneCardRemove" title="Remove from the gallery">&times;</button>').attr("aria-label", "Remove " + st.name + " from the gallery");
			remove.on("click", function () { removeTemplate(st); });
			cards.append($('<div class="sceneCardWrap"></div>').append(card, remove));
		});
		var empty = $('<button type="button" class="sceneCard sceneCardEmpty"></button>').append('<div class="sceneCardThumb">+</div>',
			$('<div class="sceneCardText"></div>').append('<strong>Empty scene</strong>', '<span>Start from nothing and add your own sections.</span>'));
		empty.on("click", function () { startFrom({ name: "New scene", pageColour: "#392630", settings: {}, sections: [] }); });
		cards.append(empty);
		$("#sceneEditorBody").hide();
		<!--- Nothing to name or save until a starting point is picked. --->
		$("#sceneEditorTop").css("display", "none");
		$("#sceneGallery").show();
	}
	$("#sceneRestart").on("click", showGallery);

	<!--- ---------- The owner's own ready-made scenes (2026-10-19): Save as ready-made keeps the scene as a starting point in the
	New scene gallery (the SceneTemplate table, so blog updates never touch them). --->
	function removeTemplate(st) {
		$.when(kendo.ui.ExtYesNoDialog.show({ title: "Remove " + $("<div/>").text(st.name).html() + "?", message: "It will no longer be offered in the gallery. Scenes already made from it stay as they are.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function (answer) {
			if (answer['button'] !== 'Yes') { return; }
			jQuery.ajax({
				type: "post", url: BASE_URL + "/common/cfc/ProxyController.cfc?method=deleteSceneTemplate",
				data: { csrfToken: CSRF, templateId: st.json.templateId }, dataType: "json",
				success: function (response) {
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (response && response.success) { starters = $.grep(starters, function (x) { return x !== st; }); showGallery(); }
					else { alertBox("Could not remove it", (response && response.errorMessage) || "The ready-made scene could not be removed."); }
				},
				error: function (jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		});
	}
	$("#sceneSaveTemplate").on("click", function () {
		var box = $('<div id="sceneTemplateWindow"></div>').appendTo("body");
		var name = $('<input type="text" class="k-textbox" maxlength="125" style="width: 100%;">').val(scene.name || "");
		var description = $('<textarea class="k-textbox" rows="3" maxlength="500" style="width: 100%;"></textarea>');
		var saveIt = $('<button type="button" class="k-button k-primary">Save as ready-made</button>');
		var cancel = $('<button type="button" class="k-button">Cancel</button>');
		box.append($('<div id="sceneTemplateForm"></div>').append(
			$('<div></div>').text("Keeps this scene, as it is now, as a starting point in the New scene gallery, marked Yours. Changing or deleting this scene later doesn't change it."),
			$('<div class="sceneField" style="margin-top: 10px;"></div>').append('<label>Name in the gallery</label>', name),
			$('<div class="sceneField"></div>').append('<label>Short description (optional)</label>', description),
			$('<div class="sceneRow"></div>').append(saveIt, cancel)));
		var win = box.kendoWindow({ title: "Save as ready-made", width: "<cfoutput>#session.isMobile ? '95%' : '440px'#</cfoutput>", modal: true, actions: ["Close"],
			close: function () { setTimeout(function () { var w = box.data("kendoWindow"); if (w) { w.destroy(); } }, 0); } }).data("kendoWindow");
		win.center().open();
		cancel.on("click", function () { win.close(); });
		saveIt.on("click", function () {
			if (!$.trim(name.val()).length) { alertBox("Please check", "The ready-made scene needs a name."); return; }
			saveIt.prop("disabled", true);
			jQuery.ajax({
				type: "post", url: BASE_URL + "/common/cfc/ProxyController.cfc?method=saveSceneTemplate",
				data: { csrfToken: CSRF, name: $.trim(name.val()), description: $.trim(description.val()), sceneJson: JSON.stringify(scene) }, dataType: "json",
				success: function (response) {
					saveIt.prop("disabled", false);
					if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
					if (response && response.success) {
						var copy = JSON.parse(JSON.stringify(scene));
						copy.name = $.trim(name.val()); copy.description = $.trim(description.val()); copy.templateId = response.templateId;
						starters.push({ key: "template-" + response.templateId, name: copy.name, order: 10000, json: copy });
						win.close();
						$("#sceneSaved").text("Kept as a ready-made scene.");
					} else {
						alertBox("Could not save", (response && response.errorMessage) || "The ready-made scene could not be saved.");
					}
				},
				error: function (jqXHR, textStatus, error) { saveIt.prop("disabled", false); if (jqXHR.status === 403) { createLoginWindow(); } else { alertBox("Error while saving", error, "k-ext-error"); } }
			});
		});
	});

	<!--- ---------- The layer builder (2026-10-19, layout B): a layered hero's pictures in a list, back to front, each with a depth
	slider; Add layers; Even out depths; a check that the layers are the same size; and, on the preview, Hold the scroll and an
	Exploded view of the layers. Depth: how far a layer moves while the hero is held - the deepest moves a full screen, the others
	in proportion, and 0 stays still. --->
	var selectedLayer = -1;
	var explodedOn = false;
	function fileName(src) { return String(src || "").split("/").pop().split("?")[0] || "Layer"; }
	function sectionLayers() { var s = selected >= 0 ? scene.sections[selected] : null; return s && s.kind === "layeredHero" ? (s.layers = s.layers || []) : null; }
	function evenDepths(layers) {
		var n = layers.length;
		$.each(layers, function (i, layer) { layer.depth = n === 1 ? 100 : Math.round((100 + 600 * i / (n - 1)) / 10) * 10; });
	}
	function layersChanged(rerenderList) {
		if (rerenderList) { renderSettings(); }
		renderExploded();
		schedulePreview();
	}
	function selectLayer(i) {
		selectedLayer = i;
		$("#sceneLayerList .sceneLayerRow").removeClass("selected").eq(i).addClass("selected");
		var row = $("#sceneLayerList .sceneLayerRow").eq(i)[0];
		if (row && row.scrollIntoView) { row.scrollIntoView({ block: "nearest" }); }
		renderExploded();
	}

	<!--- The slideshow's slides (owner, 10-19): each with its picture, heading and caption; up, down and remove; Add pictures takes
	several at once, in file-name order. --->
	function slidesField(wrap) {
		var section = scene.sections[selected];
		var slides = section.slides = section.slides || [];
		var list = $('<div class="sceneSlideList"></div>'), status = $('<span class="k-form-hint"></span>');
		wrap.append($('<label></label>').text("Slides"));
		$.each(slides, function (i, slide) {
			var row = $('<div class="sceneSlideRow" style="display: flex; gap: 8px; align-items: flex-start; padding: 6px 0; border-bottom: 1px solid rgba(128,128,128,.25);"></div>');
			var thumb = $('<img alt="" style="width: 72px; height: 48px; object-fit: cover; border-radius: 4px; flex: none;">').attr("src", withBase(slide.image || ""));
			var fields = $('<div style="flex: 1; min-width: 0;"></div>');
			var heading = $('<input class="k-textbox" placeholder="Heading (optional)" style="width: 100%; margin-bottom: 4px;">').val(slide.heading || "");
			var caption = $('<input class="k-textbox" placeholder="Caption (optional)" style="width: 100%;">').val(slide.caption || "");
			heading.on("input", function () { slide.heading = $(this).val(); if (!slide.heading) { delete slide.heading; } schedulePreview(); });
			caption.on("input", function () { slide.caption = $(this).val(); if (!slide.caption) { delete slide.caption; } schedulePreview(); });
			var tools = $('<div style="display: flex; flex-direction: column; gap: 2px;"></div>');
			if (i > 0) { tools.append($('<button type="button" class="k-button" aria-label="Move up"><span class="k-icon k-i-arrow-60-up"></span></button>').on("click", function () { slides.splice(i - 1, 0, slides.splice(i, 1)[0]); schedulePreview(); renderSettings(); })); }
			if (i < slides.length - 1) { tools.append($('<button type="button" class="k-button" aria-label="Move down"><span class="k-icon k-i-arrow-60-down"></span></button>').on("click", function () { slides.splice(i + 1, 0, slides.splice(i, 1)[0]); schedulePreview(); renderSettings(); })); }
			tools.append($('<button type="button" class="k-button" aria-label="Remove slide"><span class="k-icon k-i-close"></span></button>').on("click", function () { slides.splice(i, 1); schedulePreview(); renderSettings(); }));
			row.append(thumb, fields.append(heading, caption), tools);
			list.append(row);
		});
		if (!slides.length) { list.append($('<div class="k-form-hint"></div>').text("No slides yet. Add two or more pictures; each scroll brings in the next.")); }
		var file = $('<input type="file" accept="image/*" multiple style="display: none;">');
		var add = $('<button type="button" class="k-button k-primary" style="margin-top: 8px;">Add pictures</button>').on("click", function () { file.trigger("click"); });
		file.on("change", function () {
			var files = Array.prototype.slice.call(this.files).sort(function (a, b) { return a.name.localeCompare(b.name, undefined, { numeric: true }); });
			(function next() {
				var f = files.shift();
				if (!f) { schedulePreview(); renderSettings(); return; }
				uploadPicture(f, status, function (response) {
					var slide = { image: response.location };
					if (response.phoneLocation) { slide.imagePhone = response.phoneLocation; }
					slides.push(slide);
					next();
				});
			})();
		});
		wrap.append(list, add, file, status);
		return wrap;
	}

	function layersField(wrap) {
		var layers = sectionLayers() || [];
		wrap.append($('<label></label>').text("Layers, back to front"));
		var list = $('<div id="sceneLayerList"></div>');
		if (!layers.length) { list.append($('<div class="k-form-hint"></div>').text("No layers yet. Add the pictures of a layered drawing: transparent PNG or WebP, all the same size.")); }
		var sizes = [];
		$.each(layers, function (i, layer) {
			var row = $('<div class="sceneLayerRow"></div>').toggleClass("selected", i === selectedLayer);
			var thumb = $('<img class="sceneLayerThumb" alt="">').attr("src", withBase(layer.src));
			var name = $('<span class="sceneLayerName"></span>').text((i + 1) + ". " + fileName(layer.src)).attr("title", layer.src);
			var warn = $('<div class="k-form-hint sceneLayerWarn"></div>').hide();
			var tools = $('<span class="sceneLayerTools"></span>');
			if (i > 0) { tools.append($('<button type="button" class="k-button" aria-label="Move back"><span class="k-icon k-i-arrow-60-up"></span></button>').on("click", function (e) { e.stopPropagation(); var l = layers.splice(i, 1)[0]; layers.splice(i - 1, 0, l); selectedLayer = i - 1; layersChanged(true); })); }
			if (i < layers.length - 1) { tools.append($('<button type="button" class="k-button" aria-label="Move forward"><span class="k-icon k-i-arrow-60-down"></span></button>').on("click", function (e) { e.stopPropagation(); var l = layers.splice(i, 1)[0]; layers.splice(i + 1, 0, l); selectedLayer = i + 1; layersChanged(true); })); }
			tools.append($('<button type="button" class="k-button" aria-label="Remove layer"><span class="k-icon k-i-close"></span></button>').on("click", function (e) { e.stopPropagation(); layers.splice(i, 1); selectedLayer = Math.min(selectedLayer, layers.length - 1); layersChanged(true); }));
			var depth = $('<input type="range" class="sceneLayerDepth" min="0" max="1000" step="10">').attr("aria-label", "Depth of " + fileName(layer.src)).val(layer.depth === undefined ? (i + 1) * 100 : layer.depth);
			var depthValue = $('<span class="sceneLayerDepthValue"></span>').text(depth.val());
			depth.on("input", function () {
				layer.depth = parseInt(this.value, 10);
				depthValue.text(layer.depth === 0 ? "still" : layer.depth);
				if (selectedLayer !== i) { selectLayer(i); } else { renderExploded(); }
				schedulePreview();
			});
			if (+depth.val() === 0) { depthValue.text("still"); }
			row.append($('<div class="sceneLayerTop"></div>').append(thumb, name, tools), $('<div class="sceneLayerTop"></div>').append($('<span>Depth</span>'), depth, depthValue), warn);
			row.on("click", function () { selectLayer(i); });
			list.append(row);
			<!--- The size check: the layers sit exactly on top of each other, so they should all be the same size. --->
			thumb.on("load", function () {
				sizes[i] = this.naturalWidth + " x " + this.naturalHeight;
				var counts = {}, common = "", loaded = 0;
				$.each(sizes, function (j, size) { if (size) { loaded++; counts[size] = (counts[size] || 0) + 1; if (!common || counts[size] > counts[common]) { common = size; } } });
				if (loaded < layers.length) { return; }
				list.find(".sceneLayerWarn").each(function (j) {
					$(this).toggle(sizes[j] !== common).text("This layer is " + sizes[j] + "; the others are " + common + ". Layers of different sizes won't line up.");
				});
			});
		});
		wrap.append(list);
		var status = $('<div class="k-form-hint"></div>');
		var file = $('<input type="file" multiple accept="image/png,image/webp" style="display: none;">').attr("aria-label", "Add layers");
		var add = $('<button type="button" class="k-button k-primary">Add layers</button>').on("click", function () { file.trigger("click"); });
		var even = $('<button type="button" class="k-button">Even out depths</button>').toggle(layers.length > 1)
			.on("click", function () { evenDepths(layers); layersChanged(true); });
		<!--- Several pictures at once, in back-to-front order by file name (1.png, 2.png ... 10.png). --->
		file.on("change", function () {
			var files = Array.prototype.slice.call(this.files).sort(function (a, b) { return a.name.localeCompare(b.name, undefined, { numeric: true }); });
			var wasEmpty = !layers.length, done = 0;
			this.value = "";
			(function next() {
				if (!files.length) {
					status.text("");
					if (wasEmpty) { evenDepths(layers); }
					selectedLayer = layers.length - 1;
					layersChanged(true);
					return;
				}
				var f = files.shift();
				uploadPicture(f, status, function (response) {
					var last = layers.length ? (layers[layers.length - 1].depth || 0) : 0;
					var layer = { src: response.location, depth: Math.min(1000, last + 100) };
					if (response.phoneLocation) { layer.srcPhone = response.phoneLocation; }
					layers.push(layer);
					done++;
					status.text(done + " added...");
					next();
				});
			})();
		});
		wrap.append($('<div class="sceneRow" style="margin-top: 8px;"></div>').append(add, even), file, status,
			$('<div class="k-form-hint"></div>').text("Depth is how far a layer moves while the hero is held: the deepest moves a full screen, the others in proportion, and 0 stays still. Hold the scroll on the preview to watch a layer while you change it."));
		return wrap;
	}

	<!--- The exploded view, in its own Kendo window: the layers fanned out, back at the top and front at the bottom. It follows the
	editor as depths and order change; click a layer to pick it. --->
	function renderExploded() {
		var box = $("#sceneExploded");
		if (!explodedOn || !box.length) { return; }
		var layers = sectionLayers();
		box.empty();
		if (!layers) { box.append('<div class="sceneExplodedHint">Pick a layered hero in the Scene editor to see its layers here.</div>'); return; }
		var n = layers.length;
		if (!n) { box.append('<div class="sceneExplodedHint">Add layers to see them here.</div>'); return; }
		$.each(layers, function (i, layer) {
			var t = n > 1 ? i / (n - 1) : 0.5;
			var top = 14 + t * 62;
			var sheet = $('<button type="button" class="sceneSheet"></button>').toggleClass("selected", i === selectedLayer)
				.css({ top: top + "%", zIndex: i + 1, backgroundImage: 'url("' + withBase(layer.src).replace(/"/g, "%22") + '"), repeating-conic-gradient(#3a3a3a 0% 25%, #303030 0% 50%)' })
				.attr("aria-label", "Layer " + (i + 1) + ", " + fileName(layer.src));
			sheet.on("click", function () { selectLayer(i); });
			var label = $('<span class="sceneSheetLabel"></span>').toggleClass("selected", i === selectedLayer).css("top", top + "%")
				.text((i + 1) + ". " + fileName(layer.src) + " - " + (layer.depth === 0 ? "still" : "depth " + (layer.depth === undefined ? (i + 1) * 100 : layer.depth)));
			box.append(sheet, label);
		});
		box.append('<div class="sceneExplodedHint">Back at the top, front at the bottom. Click a layer to pick it.</div>');
	}
	function openExploded() {
		var existing = $("#sceneExplodedWindow").data("kendoWindow");
		if (existing) { existing.toFront(); return; }
		$('<div id="sceneExplodedWindow"><div id="sceneExploded"></div></div>').appendTo("body").kendoWindow({
			title: "Exploded view", width: "<cfoutput>#session.isMobile ? '95%' : '45%'#</cfoutput>", height: "<cfoutput>#session.isMobile ? '60%' : '65%'#</cfoutput>",
			modal: false, actions: ["Maximize", "Close"],
			close: function () { explodedOn = false; setTimeout(function () { var w = $("#sceneExplodedWindow").data("kendoWindow"); if (w) { w.destroy(); } }, 0); }
		}).data("kendoWindow").center().open();
		explodedOn = true;
		renderExploded();
	}
	function closeExploded() { var w = $("#sceneExplodedWindow").data("kendoWindow"); if (w) { w.close(); } }
	$("#sceneExplodedOpen").on("click", openExploded);

	<!--- Hold the scroll: for a hero, the preview stays at this point of the hero's pin. --->
	function currentHold() {
		var s = selected >= 0 ? scene.sections[selected] : null;
		return ($("#sceneHoldOn").is(":checked") && s && HERO[s.kind]) ? { section: selected, progress: $("#sceneHold").val() / 100 } : null;
	}
	function sendHold() {
		var frame = document.getElementById("scenePreviewFrame");
		$("#sceneHoldValue").text($("#sceneHold").val() + "%");
		if (previewReady && frame && frame.contentWindow) { frame.contentWindow.postMessage({ type: "galaxieScenePreviewHold", hold: currentHold() }, origin); }
	}
	$("#sceneHoldOn, #sceneHold").on("input change", function () {
		if (this.id === "sceneHold" && !$("#sceneHoldOn").is(":checked")) { $("#sceneHoldOn").prop("checked", true); }
		sendHold();
	});
	<!--- The preview tools that only make sense for some sections. --->
	function updatePreviewTools() {
		var s = selected >= 0 ? scene.sections[selected] : null;
		$("#sceneHoldWrap").toggle(!!(s && HERO[s.kind]));
		$("#sceneExplodedOpen").toggle(!!(s && s.kind === "layeredHero"));
		renderExploded();
		sendHold();
	}

	<!--- ---------- Preview --->
	function sendPreview() {
		var frame = document.getElementById("scenePreviewFrame");
		if (!previewReady || !frame || !frame.contentWindow) { return; }
		var copy = JSON.parse(JSON.stringify(scene));
		copy.settings.guides = $("#scenePreviewGuides").is(":checked");
		copy.settings.reducedMotion = $("#scenePreviewReduced").is(":checked");
		frame.contentWindow.postMessage({ type: "galaxieScenePreview", json: JSON.stringify(copy), fontCss: sceneFontCss(), hold: currentHold() }, origin);
	}
	<!--- Preview (owner, 10-20: "we need a preview button"): the scene as it is in the editor, full size in a new tab. The preview page
	reads it from this browser's storage (admin/scenePreview.cfm?full=1). --->
	$("#scenePreviewFull").on("click", function () {
		var copy = JSON.parse(JSON.stringify(scene));
		copy.settings = copy.settings || {};
		copy.settings.guides = false;
		copy.settings.reducedMotion = false;
		try {
			localStorage.setItem("galaxieSceneFullPreview", JSON.stringify({ json: JSON.stringify(copy), fontCss: sceneFontCss() }));
		} catch (e) {
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Preview", message: "This browser won't let the preview be passed to a new tab. Use the preview beside the settings.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
			return;
		}
		window.open(BASE_URL + "/admin/scenePreview.cfm?full=1", "galaxieSceneFullPreview");
	});
	<!--- Every change goes through here, so it also marks the scene as changed since it was last saved. --->
	var unsaved = false;
	<!--- The scene as last saved (or, for a new scene, as its starting point was picked), for Reset (owner, 10-19). --->
	var savedScene = JSON.stringify(scene);
	function schedulePreview() { unsaved = true; clearTimeout(previewTimer); previewTimer = setTimeout(sendPreview, 350); }
	function onPreviewMessage(event) {
		if (event.origin !== origin || !event.data || event.data.type !== "galaxieScenePreviewReady") { return; }
		previewReady = true;
		sendPreview();
	}
	window.addEventListener("message", onPreviewMessage);
	$("#scenePreviewGuides, #scenePreviewReduced").on("change", sendPreview);
	$(".scenePreviewSize").on("click", function () {
		var phone = $(this).data("size") === "phone";
		$("#scenePreviewStage").toggleClass("phone", phone);
		$(".scenePreviewSize").attr("aria-pressed", "false").removeClass("k-primary");
		$(this).attr("aria-pressed", "true").addClass("k-primary");
		<!--- The engine picks phone or desktop motion by width; rebuild once the frame has its new size. --->
		setTimeout(sendPreview, 50);
	});
	$(".scenePreviewSize[data-size=desktop]").addClass("k-primary");
	$("#scenePreviewTop").on("click", function () { try { document.getElementById("scenePreviewFrame").contentWindow.scrollTo(0, 0); } catch (e) {} });

	<!--- The editor fills the window; Kendo gives the window's content a fixed height. --->
	function fit() {
		var content = $("#sceneDetailWindow");
		if (content.length) { $("#sceneEditor").height(content.height()); }
	}
	fit();
	var kendoWindow = $("#sceneDetailWindow").data("kendoWindow");
	if (kendoWindow) {
		kendoWindow.bind("resize", fit);
		<!--- Closing with unsaved changes asks first (2026-10-19, hardening): closing used to drop them without a word. The shared
		window code (blogJsContent.cfm) destroys a window as soon as it starts closing, so its handler is replaced here and the
		window is destroyed only once the close goes ahead. --->
		kendoWindow.unbind("close");
		kendoWindow.bind("close", function (e) {
			if (unsaved) {
				e.preventDefault();
				$.when(kendo.ui.ExtYesNoDialog.show({ title: "Close without saving?", message: "Your changes to this scene haven't been saved.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function (answer) {
					if (answer['button'] === 'Yes') { unsaved = false; kendoWindow.close(); }
				});
				return;
			}
			window.removeEventListener("message", onPreviewMessage);
			closeExploded();
			setTimeout(function () { var w = $("#sceneDetailWindow").data("kendoWindow"); if (w) { w.destroy(); } }, 0);
		});
	}

	<!--- ---------- Show on a post or page (owner, 10-19) --->
	var showTarget = null;
	function linkById(id) { return $.grep(LINKS, function (l) { return l.id === +id; })[0]; }
	function drawShownOn() {
		var box = $("#sceneShownOn").empty();
		if (!SHOWN_ON.length) { box.text("Not shown anywhere yet."); return; }
		box.append(document.createTextNode("Shown on: "));
		$.each(SHOWN_ON, function (i, id) {
			var l = linkById(id); if (!l) { return; }
			if (i) { box.append(document.createTextNode(", ")); }
			box.append($('<a target="_blank" rel="noopener"></a>').attr("href", l.url).text(l.title));
			box.append(" ", $('<a href="#" title="Stop showing the scene there">(remove)</a>').on("click", function (e) { e.preventDefault(); showOn(l, ""); }));
		});
	}
	function newItemTemplate(kind) {
		<!--- Kendo's no-data template: shown when there are no posts (or pages), or none match what was typed. --->
		return function () {
			return '<div style="padding: 8px;">No ' + kind + 's found. <button type="button" class="k-button sceneNewItem" data-kind="' + kind + '">' + (kind === "post" ? "Write a new post" : "Make a new page") + '</button></div>';
		};
	}
	$.each([["#sceneShowPost", false, "post"], ["#sceneShowPage", true, "page"]], function (i, def) {
		$(def[0]).kendoDropDownList({
			dataSource: $.grep(LINKS, function (l) { return l.page === def[1]; }), dataTextField: "title", dataValueField: "id",
			optionLabel: "Choose a " + def[2] + "...", filter: "contains", noDataTemplate: newItemTemplate(def[2]),
			template: function (l) { return $("<div>").text(l.title + (l.released ? "" : " (not released yet)")).html(); },
			change: function () {
				var other = $(i ? "#sceneShowPost" : "#sceneShowPage").data("kendoDropDownList");
				if (this.value()) { other.value(""); }
				showTarget = this.value() ? linkById(this.value()) : null;
				$("#sceneShowApply").prop("disabled", !showTarget);
				$("#sceneShowPreview").toggle(!!showTarget).attr("href", showTarget ? showTarget.url : "#");
			}
		});
	});
	$(document).on("click", ".sceneNewItem", function () {
		$("#sceneShowPost, #sceneShowPage").each(function () { var d = $(this).data("kendoDropDownList"); if (d) { d.close(); } });
		if ($(this).data("kind") === "post") { createAdminInterfaceWindow(24); } else { createAdminInterfaceWindow(24, "newPage"); }
		$("#sceneShownOn").text("Save the new " + $(this).data("kind") + ", then close and reopen this scene to pick it.");
	});
	function showOn(link, alias) {
		if (alias && sceneId === 0) { alertBox("Save the scene first", "A scene shows on a post or page once it has been saved.", "k-ext-information"); return; }
		jQuery.ajax({
			type: "post", url: BASE_URL + "/common/cfc/ProxyController.cfc?method=setPostScene", dataType: "json",
			data: { csrfToken: CSRF, postId: link.id, alias: alias },
			success: function (response) {
				if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
				if (response && response.success) {
					SHOWN_ON = $.grep(SHOWN_ON, function (id) { return id !== link.id; });
					if (alias) { SHOWN_ON.push(link.id); }
					drawShownOn();
					if (alias) { $("#sceneShownOn").prepend($("<strong></strong>").text("Done. ")); }
				} else { alertBox("Could not change it", (response && response.errorMessage) || "The post could not be changed.", "k-ext-warning"); }
			},
			error: function (jqXHR) { if (jqXHR.status === 403) { createLoginWindow(); } }
		});
	}
	$("#sceneShowApply").on("click", function () {
		if (!showTarget) { return; }
		if (unsaved) { alertBox("Save first", "Save your changes, so the " + (showTarget.page ? "page" : "post") + " shows this scene as it is now.", "k-ext-information"); return; }
		showOn(showTarget, $.trim($("#sceneAlias").val()));
	});
	drawShownOn();

	<!--- ---------- Reset: back to the scene as it was last saved (owner, 10-19). --->
	$("#sceneReset").on("click", function () {
		if (!unsaved || JSON.stringify(scene) === savedScene) { $("#sceneSaved").text("Nothing to reset: no changes since the last save."); return; }
		$.when(kendo.ui.ExtYesNoDialog.show({ title: "Reset this scene?", message: "Your changes since the last save will be lost.", icon: "k-ext-question", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })).done(function (answer) {
			if (answer['button'] !== 'Yes') { return; }
			scene = JSON.parse(savedScene);
			scene.settings = scene.settings || {}; scene.sections = scene.sections || [];
			unsaved = false;
			select(-1);
			sendPreview();
			$("#sceneSaved").text("Back to the last save.");
		});
	});

	<!--- ---------- Save --->
	$("#sceneSave").on("click", function () {
		var alias = $.trim($("#sceneAlias").val());
		var problem = "";
		if (!$.trim(scene.name || "").length) { problem = "The scene needs a title (Scene settings)."; }
		else if (!/^[A-Za-z0-9_-]{1,80}$/.test(alias)) { problem = "The name in posts can only have letters, numbers, dashes and underscores."; }
		if (problem.length) {
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Please check the scene", message: problem, icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
			return;
		}
		$("#sceneSave").prop("disabled", true);
		$("#sceneSaved").text("Saving...");
		<!--- The ready-made forms picked since the last save are made now, one by one, each named after this scene; then the scene
		is saved with them in place. If one can't be made, the scene isn't saved, so nothing points at a missing form. --->
		var waiting = $.grep(scene.sections, function (s) { return s.kind === "form" && s.pendingReadyMade; });
		(function makeNext() {
			var s = waiting.shift();
			if (!s) { saveNow(); return; }
			makeReadyForm(s.pendingReadyMade, function (f) { s.form = f.alias; s.formTitle = f.title; delete s.pendingReadyMade; makeNext(); },
				function () { $("#sceneSave").prop("disabled", false); $("#sceneSaved").text(""); });
		})();
	});
	function saveNow() {
		var alias = $.trim($("#sceneAlias").val());
		jQuery.ajax({
			type: "post",
			url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveScene",
			data: { csrfToken: "<cfoutput>#csrfToken#</cfoutput>", sceneId: sceneId, alias: alias, active: $("#sceneActive").is(":checked"), sceneJson: JSON.stringify(scene) },
			dataType: "json",
			success: function (response) {
				$("#sceneSave").prop("disabled", false);
				if (response && response.success) {
					<!--- Saved: from now on this is an existing scene, and its name in posts stays as it is. --->
					sceneId = response.sceneId;
					$("#sceneAlias").prop("readonly", true).attr("title", "A saved scene keeps its name, so the posts that show it keep working.");
					$("#sceneRestart").remove();
					unsaved = false;
					savedScene = JSON.stringify(scene);
					$("#sceneSaved").text("Saved at " + new Date().toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }));
					try { refreshScenesWindow(); } catch (e) {}
					<!--- The post's Scene window (108), when it opened this editor, lists the new scene and picks it. --->
					$(document).trigger("galaxieSceneSaved", [{ sceneId: sceneId, alias: alias }]);
					<!--- A form just made for this scene can now be changed here (its quick edit). --->
					renderSettings();
				} else {
					$("#sceneSaved").text("");
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: (response && response.errorMessage) || "The scene could not be saved.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				}
			},
			error: function (jqXHR, textStatus, error) {
				$("#sceneSave").prop("disabled", false);
				$("#sceneSaved").text("");
				if (jqXHR.status === 403) { createLoginWindow(); }
				else { $.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving the scene", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
			}
		});
	}

	select(-1);
	if (sceneId === 0) { showGallery(); }
});
</script>
