<!--- Scene editor (window 107, 2026-10-19, Galaxie 5), opened from the Scenes window (106) with createAdminInterfaceWindow(107,
sceneId); 0 makes a new scene. Side by side (owner's pick, layout A): the sections on the left, the selected section's settings
in the middle, and a live preview on the right (admin/scenePreview.cfm in an iframe, sent the scene on every change). The scene
is edited as the engine's own data ({ name, pageColour, settings, sections: [...] }, see common/js/galaxieScene.js), so keys
this editor doesn't know yet are kept as they are. Saved by ProxyController.cfc's saveScene -> Scenes.cfc saveScene.
Step 3 (2026-10-19): rich text (one TinyMCE that stays put while sections are picked), the blog's fonts, picture upload
(ProxyController uploadSceneImage), gradients (Grapick, as in the gradient editor) and Kendo colour pickers.
Step 4 (2026-10-19): a new scene opens on a gallery of the ready-made scenes (includes/postContent/scenes/*.json), each card
drawn from the scene itself (its layers, photo or gradient), or from the picture named in the file's "thumbnail".
Layer builder (2026-10-19, layout B): the layered hero's layers in a list with depth sliders, Add layers, Even out depths and a
size check; on the preview, Hold the scroll, and an Exploded view in its own Kendo window (owner's request).
Colour helper (2026-10-19, option A): a Suggest button on each colour field, with colours read from the section's pictures and its
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
<cfset sceneJsonText = replace(sceneJsonText, "</", "<\/", "all")>
<cfset startersJsonText = replace(startersJsonText, "</", "<\/", "all")>
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
	#sceneEditorList { flex: 0 0 21%; overflow: auto; padding: 8px; }
	#sceneEditorSettings { flex: 0 0 29%; overflow-y: auto; overflow-x: hidden; padding: 8px 10px; }
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
	<!--- Each band's colour is picked with the Band colour picker below the bar, not Grapick's own small input. --->
	.sceneGradientBar .grp-handler-cp-c { display: none; }
	.sceneGradient .sceneRow { margin-bottom: 8px; }
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
		<span id="sceneSaved" class="k-form-hint"></span>
		<span class="k-form-hint" id="sceneUseHint"></span>
	</div>
<cfif isNewScene>
	<!--- New scene: the gallery comes first; the editor below shows once a starting point is picked. --->
	<div id="sceneGallery" class="#altClass#">
		<h4 class="adminBlockHeading">Pick a starting point</h4>
		<div>Every part of it can be changed: the words, pictures, fonts, colours and motion. You can also start from nothing.</div>
		<div id="sceneGalleryCards" class="sceneCards"></div>
	</div>
</cfif>
	<div id="sceneEditorBody"<cfif isNewScene> style="display: none;"</cfif>>
		<div id="sceneEditorList" class="#altClass#">
			<div id="sceneSectionList"></div>
			<div style="margin-top: 10px;">
				<select id="sceneAddKind" aria-label="Kind of section to add" style="width: 100%; margin-bottom: 6px;"></select>
				<button id="sceneAddSection" type="button" class="k-button" style="width: 100%;">Add section</button>
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
					<button type="button" class="k-button scenePreviewSize" data-size="phone" aria-pressed="false">Phone</button>
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
	var selected = -1;            <!--- -1 is the scene's own settings; 0... a section --->
	var aliasTyped = sceneId > 0; <!--- a new scene's name in posts follows its title until it is typed in --->
	var previewReady = false;
	var previewTimer = null;
	var origin = window.location.origin;

	var KINDS = [
		{ kind: "layeredHero", label: "Layered hero", hint: "Layers of a picture that move at different speeds." },
		{ kind: "photoHero", label: "Photo hero", hint: "One photo, held in place with a slow zoom." },
		{ kind: "vantaHero", label: "Animated hero", hint: "A Vanta animation behind the text." },
		{ kind: "gradientHero", label: "Gradient hero", hint: "Colours, no pictures." },
		{ kind: "videoHero", label: "Video hero", hint: "A silent looping video." },
		{ kind: "text", label: "Text block", hint: "Heading and text on a colour." },
		{ kind: "imageSlide", label: "Image slide", hint: "A picture that moves slower than the page." }
	];
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
	var pending = [];             <!--- set-up that has to wait until a field is on the page (Kendo widgets, Grapick) --->

	var HEADING_SIZES = [["", "Theme default"], ["2rem", "Small"], ["2.75rem", "Medium"], ["3.5rem", "Large"], ["4.5rem", "Very large"], ["6rem", "Huge"]];
	var HEADING_SIZES_PHONE = [["", "Same as on a computer"], ["1.75rem", "Small"], ["2.25rem", "Medium"], ["2.75rem", "Large"], ["3.5rem", "Very large"]];
	var TEXT_SIZES = [["", "Theme default"], ["0.95rem", "Small"], ["1.15rem", "Medium"], ["1.35rem", "Large"], ["1.6rem", "Very large"]];
	var TEXT_SIZES_PHONE = [["", "Same as on a computer"], ["0.9rem", "Small"], ["1rem", "Medium"], ["1.15rem", "Large"]];
	var HEADING = { key: "heading", label: "Heading", type: "text" };
	var LOOK = [
		{ group: "Heading" },
		{ key: "headingFont", idKey: "headingFontId", label: "Font", type: "font" },
		{ key: "headingSize", label: "Size", type: "select", options: HEADING_SIZES },
		{ key: "headingSizePhone", label: "Size on phones", type: "select", options: HEADING_SIZES_PHONE },
		{ group: "Text" },
		{ key: "textFont", idKey: "textFontId", label: "Font", type: "font" },
		{ key: "textSize", label: "Size", type: "select", options: TEXT_SIZES },
		{ key: "textSizePhone", label: "Size on phones", type: "select", options: TEXT_SIZES_PHONE },
		{ group: "Heading and text" },
		{ key: "align", label: "Line up", type: "select", options: [["", "Theme default"], ["left", "Left"], ["center", "Centre"], ["right", "Right"]] },
		{ key: "textColour", label: "Colour", type: "colour" },
		{ key: "shadow", label: "Shadow behind them", type: "select", options: [["", "None"], ["soft", "Soft"], ["strong", "Strong"], ["glow", "Glow"]], hint: "Makes text stand out on a busy picture." },
		{ key: "shadowColour", label: "Shadow colour", type: "colour" }
	];
	var FADE = { key: "fadeColour", label: "Fade into colour", type: "colour", hint: "The hero fades into this colour at the bottom. Pick the colour at the bottom of the picture, or of the next section." };
	var OVERLAY = [
		{ key: "overlay.colour", label: "Tint over the picture", type: "colour" },
		{ key: "overlay.opacity", label: "Tint strength (0 to 1)", type: "number", min: 0, max: 1, step: 0.05 }
	];
	var FIELDS = {
		scene: [
			{ key: "@name", label: "Title", type: "text", hint: "Only you see this, in the Scenes window." },
			{ key: "@pageColour", label: "Page colour", type: "colour", hint: "Behind the scene and between its sections." },
			{ group: "Motion" },
			{ key: "settings.scrub", label: "Movement", type: "select", options: [["true", "Follows the scroll exactly"], ["0.5", "Smooth"], ["1", "Smoother"]] },
			{ key: "settings.intensity", label: "Depth (how far the layers move)", type: "number", min: 0.25, max: 2, step: 0.05, placeholder: "1" },
			{ key: "settings.pinLength", label: "How long a hero stays in place", type: "select", options: [["", "Default (twice the screen)"], ["150%", "1.5 screens"], ["200%", "2 screens"], ["250%", "2.5 screens"], ["300%", "3 screens"]] },
			{ key: "settings.fadeHeight", label: "Fade height", type: "select", options: [["", "Default"], ["0vh", "No fade"], ["20vh", "Short"], ["35vh", "Medium"], ["50vh", "Tall"]] },
			{ key: "settings.rise", label: "How far the text rises (pixels)", type: "number", min: 0, max: 600, step: 10, placeholder: "160" },
			{ key: "settings.phoneMotion", label: "On phones", type: "select", options: [["", "Full movement"], ["light", "Half the movement"]] }
		],
		text: [
			{ key: "colour", label: "Background colour", type: "colour" },
			{ key: "gradient", label: "Or a gradient (used instead of the colour)", type: "gradient" }
		],
		imageSlide: [
			{ key: "image", phoneKey: "imagePhone", label: "Picture", type: "image" },
			{ key: "imagePhone", label: "Smaller picture for phones", type: "image", hint: "Made for you when you upload a large picture." },
			{ key: "alt", label: "Describe the picture (for screen readers)", type: "text" }
		],
		layeredHero: [{ key: "#layers", type: "layers" }, FADE],
		photoHero: [
			{ key: "image", phoneKey: "imagePhone", label: "Photo", type: "image" },
			{ key: "imagePhone", label: "Smaller photo for phones", type: "image", hint: "Made for you when you upload a large photo." },
			{ key: "zoom", label: "Zoom while held (1 is none)", type: "number", min: 1, max: 2, step: 0.05, placeholder: "1.15" }
		].concat(OVERLAY, [FADE]),
		vantaHero: [
			{ key: "effect", label: "Animation", type: "select", options: [["WAVES", "Waves"], ["NET", "Net"], ["FOG", "Fog"], ["CLOUDS", "Clouds"], ["CLOUDS2", "Clouds 2"], ["BIRDS", "Birds"], ["GLOBE", "Globe"], ["RINGS", "Rings"]] },
			FADE
		],
		gradientHero: [{ key: "gradient", label: "Gradient", type: "gradient" }, FADE],
		videoHero: [
			{ key: "video", label: "Video file (.mp4)", type: "text", placeholder: "/images/...", hint: "Video upload comes later; type the address of an .mp4 file on this site." },
			{ key: "poster", label: "Picture shown before it plays", type: "image" }
		].concat(OVERLAY, [FADE])
	};

	<!--- Each Vanta animation names its colours differently; these are the ones worth changing for each. Vanta takes plain colours
	only, no transparency. --->
	var VANTA_COLOURS = {
		WAVES: [["color", "Water"]],
		NET: [["color", "Lines"], ["backgroundColor", "Background"]],
		FOG: [["highlightColor", "Highlights"], ["midtoneColor", "Middle tones"], ["lowlightColor", "Shadows"], ["baseColor", "Base"]],
		CLOUDS: [["skyColor", "Sky"], ["cloudColor", "Clouds"], ["sunColor", "Sun"]],
		CLOUDS2: [["skyColor", "Sky"], ["cloudColor", "Clouds"], ["lightColor", "Light"]],
		BIRDS: [["backgroundColor", "Background"], ["color1", "Birds"], ["color2", "Birds, second colour"]],
		GLOBE: [["color", "Lines"], ["color2", "Dots"], ["backgroundColor", "Background"]],
		RINGS: [["color", "Rings"], ["backgroundColor", "Background"]]
	};
	function sectionFields(section) {
		var fields = (FIELDS[section.kind] || []).slice();
		if (section.kind === "vantaHero") {
			var colours = $.map(VANTA_COLOURS[String(section.effect || "WAVES").toUpperCase()] || [], function (c) { return { key: "options." + c[0], label: c[1], type: "colour", solid: true }; });
			fields.splice(1, 0, { group: "Animation colours" });
			Array.prototype.splice.apply(fields, [2, 0].concat(colours));
		}
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
	function sceneFontCss() {
		var css = "", seen = {};
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

	<!--- ---------- The colour helper (2026-10-19, option A): a Suggest button on every colour field, listing colours worked out in the
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
	<!--- The most common colour, in groups of near colours, averaged within the winning group. --->
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
	<!--- A section's own colour: its background colour, or the first colour of its gradient. --->
	function sectionColour(s) {
		if (!s) { return null; }
		if (s.colour) { return s.colour; }
		var m = /(#[0-9a-f]{3,8}\b|rgba?\([^)]*\))/i.exec(s.gradient || "");
		return m ? m[1] : (s.fadeColour || null);
	}
	<!--- The pictures to read for a section: a layered hero's front layer (and all its layers, drawn together, for the main colour);
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
			add("The picture's main colour", mainColour({ data: ctx.getImageData(0, 0, w, h).data, w: w, h: h }));
		});
		return work.catch(function () {}).then(function () {
			var at = selected >= 0 ? selected : 0;
			add("The next section's colour", sectionColour(scene.sections[at + 1]));
			if (at > 0) { add("The section before", sectionColour(scene.sections[at - 1])); }
			add("The page colour", scene.pageColour);
			return list;
		});
	}
	<!--- The Suggest list under a colour field; picking one sets the field (apply) and closes the list. --->
	function showSuggestions(anchor, field, apply) {
		$(".sceneSuggest").remove();
		var box = $('<div class="sceneSuggest" role="listbox"></div>').text("Working out colours...");
		anchor.after(box);
		function close() { box.remove(); $(document).off(".sceneSuggest"); }
		setTimeout(function () {
			$(document).on("mousedown.sceneSuggest", function (e) { if (!$(e.target).closest(".sceneSuggest").length) { close(); } })
				.on("keydown.sceneSuggest", function (e) { if (e.key === "Escape") { close(); } });
		}, 0);
		suggestColours().then(function (list) {
			box.empty();
			if (!list.length) { box.append($('<div class="k-form-hint"></div>').text("No colours to suggest yet: add a picture or a colour to this or the next section.")); }
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
				}), $('<span class="k-form-hint"> any colour you can see, the preview included</span>'));
			}
		});
	}

	function fieldHtml(field) {
		if (field.group) { return $('<h4 class="adminBlockHeading sceneFieldGroup"></h4>').text(field.group); }
		var wrap = $('<div class="sceneField"></div>');
		var id = "sceneField_" + field.key.replace(/[^A-Za-z0-9]/g, "_");
		var value = getValue(field.key), input;
		if (field.type === "layers") { return layersField(wrap); }
		wrap.append($('<label></label>').attr("for", id).text(field.label));
		function hint() { if (field.hint) { wrap.append($('<div class="k-form-hint"></div>').text(field.hint)); } return wrap; }

		if (field.type === "colour") {
			<!--- Kendo's colour picker, with transparency unless the field takes plain colours only. None takes the colour away. --->
			input = $('<input>').attr("id", id);
			var none = $('<button type="button" class="k-button">None</button>');
			var suggest = $('<button type="button" class="k-button" title="Colours from the pictures of this section and the sections next to it">Suggest</button>');
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
			var upload = $('<button type="button" class="k-button">Upload</button>');
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
			<!--- Another animation has other colours to set. --->
			if (field.key === "effect") { setTimeout(renderSettings, 0); }
			schedulePreview();
		});
		wrap.append(input);
		return hint();
	}

	<!--- A gradient: Grapick's bar (the same library as the gradient editor) - click the bar to add a band, drag a band to move
	it, and pick its colour below. The CSS box shows the result and takes a pasted gradient. --->
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
			$('<div class="sceneRow"></div>').append($('<span>Band colour</span>'), band),
			$('<div class="sceneRow"></div>').append(css, off),
			$('<div class="k-form-hint">Click the bar to add a colour band, drag a band to move it, and click the x above a band to remove it. You can also paste a CSS gradient into the box.</div>'));
		off.on("click", function () { setValue(field.key, ""); buildGradient(box, field); schedulePreview(); });
		galaxieLoader.grapickPickr(function () {
			if (!document.getElementById(barId)) { return; }   <!--- another section was picked meanwhile --->
			var loading = true;
			var gp = new Grapick({ el: "#" + barId, direction: "right" });
			gp.setValue(value);
			var picker = band.kendoColorPicker({ opacity: true, buttons: false, preview: true, input: true,
				change: function () { var h = selectedBand(); if (h) { h.setColor(this.value()); } } }).data("kendoColorPicker");
			<!--- The band the colour picker changes: the one picked on the bar, or the first one (a loaded gradient has none picked). --->
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
			top.append(fieldHtml(HEADING));
			$.each(sectionFields(section).concat(LOOK), function (i, field) { rest.append(fieldHtml(field)); });
		}
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
		$("#sceneTextBlock").toggle(selected >= 0);
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
		item.append('<span class="sceneSectionKind">Scene settings</span><span class="sceneSectionHeading">Colours and motion</span>');
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
	function newSection(kind) {
		var s = { kind: kind, heading: "", html: "" };
		if (kind === "text") { s.heading = "A new heading"; s.html = "<p>Your text.</p>"; s.colour = scene.pageColour || "#392630"; }
		if (kind === "vantaHero") { s.effect = "WAVES"; s.options = { color: "#0e3b5c" }; }
		if (kind === "gradientHero") { s.gradient = "linear-gradient(135deg, #1d4350 0%, #a43931 100%)"; }
		if (kind === "layeredHero") {
			<!--- Until the layer builder: the layers of the first ready-made layered scene. --->
			$.each(starters, function (i, st) { $.each(st.json.sections || [], function (j, sec) { if (!s.layers && sec.kind === "layeredHero") { s.layers = JSON.parse(JSON.stringify(sec.layers)); s.fadeColour = sec.fadeColour; } }); });
			s.layers = s.layers || [];
		}
		if (HERO[kind]) { s.heading = "A new hero"; }
		return s;
	}
	$.each(KINDS, function (i, k) { $("#sceneAddKind").append($('<option></option>').attr("value", k.kind).text(k.label + " - " + k.hint)); });
	$("#sceneAddKind").val("text");
	kendoSelects("#sceneEditorList");
	kendoSelects("#sceneEditorTop");
	$("#sceneAddSection").on("click", function () {
		var at = selected < 0 ? scene.sections.length : selected + 1;
		scene.sections.splice(at, 0, newSection($("#sceneAddKind").val()));
		select(at);
		schedulePreview();
	});

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
			var card = $('<button type="button" class="sceneCard"></button>').append(cardThumb(st.json),
				$('<div class="sceneCardText"></div>').append($('<strong></strong>').text(st.name), $('<span></span>').text(st.json.description || "")));
			card.on("click", function () { startFrom(st.json); });
			cards.append(card);
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
		var add = $('<button type="button" class="k-button">Add layers</button>').on("click", function () { file.trigger("click"); });
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
	function schedulePreview() { clearTimeout(previewTimer); previewTimer = setTimeout(sendPreview, 350); }
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
		kendoWindow.bind("close", function () { window.removeEventListener("message", onPreviewMessage); closeExploded(); });
	}

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
					$("#sceneSaved").text("Saved at " + new Date().toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }));
					try { refreshScenesWindow(); } catch (e) {}
					<!--- The post's Scene window (108), when it opened this editor, lists the new scene and picks it. --->
					$(document).trigger("galaxieSceneSaved", [{ sceneId: sceneId, alias: alias }]);
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
	});

	select(-1);
	if (sceneId === 0) { showGallery(); }
});
</script>
