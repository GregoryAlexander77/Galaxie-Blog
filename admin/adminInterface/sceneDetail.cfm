<!--- Scene editor (window 107, 2026-10-19, Galaxie 5), opened from the Scenes window (106) with createAdminInterfaceWindow(107,
sceneId); 0 makes a new scene. Side by side (owner's pick, layout A): the sections on the left, the selected section's settings
in the middle, and a live preview on the right (admin/scenePreview.cfm in an iframe, sent the scene on every change). The scene
is edited as the engine's own data ({ name, pageColour, settings, sections: [...] }, see common/js/galaxieScene.js), so keys
this editor doesn't know yet are kept as they are. Saved by ProxyController.cfc's saveScene -> Scenes.cfc saveScene.
To come: rich text, fonts, the picture uploader, colour helper, layer builder and the gallery (design doc, Galaxie 5). --->
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

<style>
	#sceneEditor { display: flex; flex-direction: column; height: 100%; }
	#sceneEditorTop { flex: 0 0 auto; padding: 6px 8px; display: flex; flex-wrap: wrap; align-items: center; gap: 8px 14px; }
	#sceneEditorTop label { white-space: nowrap; }
	#sceneEditorBody { flex: 1 1 auto; display: flex; min-height: 0; }
	#sceneEditorList { flex: 0 0 21%; overflow: auto; padding: 8px; }
	#sceneEditorSettings { flex: 0 0 29%; overflow: auto; padding: 8px 10px; }
	#sceneEditorPreview { flex: 1 1 auto; display: flex; flex-direction: column; min-width: 0; padding: 8px; }
	#scenePreviewBar { flex: 0 0 auto; padding-bottom: 6px; display: flex; flex-wrap: wrap; align-items: center; gap: 6px 14px; }
	#scenePreviewStage { flex: 1 1 auto; min-height: 0; display: flex; justify-content: center; background: #2b2b2b; border-radius: 4px; }
	#scenePreviewFrame { border: 0; width: 100%; height: 100%; background: #222; }
	#scenePreviewStage.phone #scenePreviewFrame { width: 390px; max-width: 100%; }
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
	@media (max-width: 900px) {
		#sceneEditorBody { flex-direction: column; overflow: auto; }
		#sceneEditorList, #sceneEditorSettings { flex: 0 0 auto; overflow: visible; }
		#sceneEditorPreview { flex: 0 0 70vh; }
	}
</style>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfset altClass = HtmlUtilsObj.getKendoClass(blockClass)>
<cfoutput>
<div id="sceneEditor">
	<div id="sceneEditorTop" class="#blockClass#">
	<cfif isNewScene and arrayLen(sceneStarters)>
		<label for="sceneStarter">Start from:</label>
		<select id="sceneStarter" style="width: 180px;">
			<cfloop array="#sceneStarters#" index="thisStarter">
				<option value="#encodeForHtmlAttribute(thisStarter.key)#"<cfif thisStarter.key eq "arch"> selected</cfif>>#encodeForHtml(thisStarter.name)#</option>
			</cfloop>
			<option value="">Empty scene</option>
		</select>
	</cfif>
		<label for="sceneAlias">Name in posts:</label>
		<input type="text" id="sceneAlias" class="k-textbox" maxlength="80" style="width: 220px;" value="<cfif not isNewScene>#encodeForHtmlAttribute(scene.alias)#</cfif>"<cfif not isNewScene> readonly title="A saved scene keeps its name, so the posts that show it keep working."</cfif>>
		<label><input type="checkbox" id="sceneActive" class="k-checkbox"<cfif isNewScene or scene.active> checked</cfif>> Active</label>
		<button id="sceneSave" type="button" class="k-button k-primary">Save</button>
		<span id="sceneSaved" class="k-form-hint"></span>
		<span class="k-form-hint" id="sceneUseHint"></span>
	</div>
	<div id="sceneEditorBody">
		<div id="sceneEditorList" class="#altClass#">
			<div id="sceneSectionList"></div>
			<div style="margin-top: 10px;">
				<select id="sceneAddKind" aria-label="Kind of section to add" style="width: 100%; margin-bottom: 6px;"></select>
				<button id="sceneAddSection" type="button" class="k-button" style="width: 100%;">Add section</button>
			</div>
		</div>
		<div id="sceneEditorSettings" class="#blockClass#"></div>
		<div id="sceneEditorPreview" class="#altClass#">
			<div id="scenePreviewBar">
				<span>
					<button type="button" class="k-button scenePreviewSize" data-size="desktop" aria-pressed="true">Desktop</button>
					<button type="button" class="k-button scenePreviewSize" data-size="phone" aria-pressed="false">Phone</button>
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
	var LOOK = [
		{ group: "Text" },
		{ key: "align", label: "Line up the text", type: "select", options: [["", "Theme default"], ["left", "Left"], ["center", "Centre"], ["right", "Right"]] },
		{ key: "textColour", label: "Text colour", type: "colour" },
		{ key: "shadow", label: "Shadow behind the text", type: "select", options: [["", "None"], ["soft", "Soft"], ["strong", "Strong"], ["glow", "Glow"]], hint: "Makes text stand out on a busy picture." },
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
			{ key: "gradient", label: "Or a gradient (CSS)", type: "text", placeholder: "linear-gradient(to bottom, #9d5931 0%, #62371e 80%)" }
		],
		imageSlide: [
			{ key: "image", label: "Picture", type: "text", placeholder: "/images/...", hint: "The picture uploader comes in a later step." },
			{ key: "imagePhone", label: "Smaller picture for phones (optional)", type: "text" },
			{ key: "alt", label: "Describe the picture (for screen readers)", type: "text" }
		],
		layeredHero: [{ key: "#layers", type: "layers" }, FADE],
		photoHero: [
			{ key: "image", label: "Photo", type: "text", placeholder: "/images/...", hint: "The picture uploader comes in a later step." },
			{ key: "imagePhone", label: "Smaller photo for phones (optional)", type: "text" },
			{ key: "zoom", label: "Zoom while held (1 is none)", type: "number", min: 1, max: 2, step: 0.05, placeholder: "1.15" }
		].concat(OVERLAY, [FADE]),
		vantaHero: [
			{ key: "effect", label: "Animation", type: "select", options: [["WAVES", "Waves"], ["NET", "Net"], ["FOG", "Fog"], ["CLOUDS", "Clouds"], ["CLOUDS2", "Clouds 2"], ["BIRDS", "Birds"], ["GLOBE", "Globe"], ["RINGS", "Rings"]] },
			{ key: "options.color", label: "Animation colour", type: "colour" },
			{ key: "options.backgroundColor", label: "Animation background", type: "colour" },
			FADE
		],
		gradientHero: [{ key: "gradient", label: "Gradient (CSS)", type: "text", placeholder: "linear-gradient(135deg, #1d4350 0%, #a43931 100%)" }, FADE],
		videoHero: [
			{ key: "video", label: "Video file (.mp4)", type: "text", placeholder: "/images/..." },
			{ key: "poster", label: "Picture shown before it plays", type: "text" }
		].concat(OVERLAY, [FADE])
	};
	var COMMON = [
		{ key: "heading", label: "Heading", type: "text" },
		{ key: "html", label: "Text (HTML for now; the rich text editor comes next)", type: "textarea" }
	];

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
	function hex(value) { return /^#[0-9a-f]{6}$/i.test(value) ? value : (/^#[0-9a-f]{3}$/i.test(value) ? "#" + value.charAt(1) + value.charAt(1) + value.charAt(2) + value.charAt(2) + value.charAt(3) + value.charAt(3) : "#000000"); }

	function fieldHtml(field) {
		if (field.group) { return $('<h4 class="adminBlockHeading sceneFieldGroup"></h4>').text(field.group); }
		var wrap = $('<div class="sceneField"></div>');
		var id = "sceneField_" + field.key.replace(/[^A-Za-z0-9]/g, "_");
		if (field.type === "layers") {
			var layers = getValue("layers") || [];
			wrap.append($('<label></label>').text("Layers"));
			wrap.append($('<div></div>').text(layers.length + " picture layer" + (layers.length === 1 ? "" : "s") + ", back to front. The layer builder (upload your own layers and set how far each one moves) comes in a later step."));
			return wrap;
		}
		wrap.append($('<label></label>').attr("for", id).text(field.label));
		var value = getValue(field.key), input;
		if (field.type === "select") {
			input = $('<select></select>').attr("id", id);
			$.each(field.options, function (i, o) { input.append($('<option></option>').attr("value", o[0]).text(o[1])); });
			input.val(String(value === "" ? field.options[0][0] : value));
		} else if (field.type === "textarea") {
			input = $('<textarea class="k-textbox" rows="6"></textarea>').attr("id", id).val(value);
		} else if (field.type === "colour") {
			var text = $('<input type="text" class="k-textbox" placeholder="#rrggbb">').attr("id", id).val(value);
			var picker = $('<input type="color">').attr("aria-label", field.label + " picker").val(hex(String(value)));
			picker.on("input", function () { text.val(this.value).trigger("input"); });
			text.on("input", function () { if (/^#[0-9a-f]{3}([0-9a-f]{3})?$/i.test(this.value)) { picker.val(hex(this.value)); } });
			input = text;
			wrap.append($('<div class="sceneColour"></div>').append(picker, text));
		} else {
			input = $('<input class="k-textbox">').attr({ id: id, type: field.type === "number" ? "number" : "text" }).val(value);
			if (field.type === "number") { input.attr({ min: field.min, max: field.max, step: field.step }); }
		}
		if (field.placeholder) { input.attr("placeholder", field.placeholder); }
		input.on("input change", function () {
			setValue(field.key, typed(field, $.trim($(this).val())));
			if (field.key === "@name" && !aliasTyped && sceneId === 0) { $("#sceneAlias").val(aliasFrom(scene.name || "")); updateUseHint(); }
			if (field.key === "heading") { renderList(); }
			schedulePreview();
		});
		if (field.type !== "colour") { wrap.append(input); }
		if (field.hint) { wrap.append($('<div class="k-form-hint"></div>').text(field.hint)); }
		return wrap;
	}

	function renderSettings() {
		var pane = $("#sceneEditorSettings").empty();
		var fields;
		if (selected < 0) {
			pane.append($('<h4 class="adminBlockHeading"></h4>').text("Scene"));
			fields = FIELDS.scene;
		} else {
			var section = scene.sections[selected];
			pane.append($('<h4 class="adminBlockHeading"></h4>').text(kindLabel(section.kind)));
			fields = COMMON.concat(FIELDS[section.kind] || [], LOOK);
		}
		$.each(fields, function (i, field) { pane.append(fieldHtml(field)); });
		kendoSelects(pane);
	}
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
	function select(i) { selected = i; renderList(); renderSettings(); }
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

	$("#sceneStarter").on("change", function () {
		var key = $(this).val(), found = null;
		$.each(starters, function (i, st) { if (st.key === key) { found = st; } });
		scene = found ? JSON.parse(JSON.stringify(found.json)) : { name: "New scene", pageColour: "#392630", settings: {}, sections: [] };
		scene.settings = scene.settings || {}; scene.sections = scene.sections || [];
		if (!aliasTyped) { $("#sceneAlias").val(aliasFrom(scene.name || "")); updateUseHint(); }
		select(-1);
		schedulePreview();
	});

	<!--- ---------- Preview --->
	function sendPreview() {
		var frame = document.getElementById("scenePreviewFrame");
		if (!previewReady || !frame || !frame.contentWindow) { return; }
		var copy = JSON.parse(JSON.stringify(scene));
		copy.settings.guides = $("#scenePreviewGuides").is(":checked");
		copy.settings.reducedMotion = $("#scenePreviewReduced").is(":checked");
		frame.contentWindow.postMessage({ type: "galaxieScenePreview", json: JSON.stringify(copy) }, origin);
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
		kendoWindow.bind("close", function () { window.removeEventListener("message", onPreviewMessage); });
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
					$("#sceneStarter").prop("disabled", true);
					$("#sceneSaved").text("Saved at " + new Date().toLocaleTimeString([], { hour: "numeric", minute: "2-digit" }));
					try { refreshScenesWindow(); } catch (e) {}
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
});
</script>
