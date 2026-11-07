<!--- The Scene wizard (window 121, 11-06, owner; mock-up approved the same day): a whole scene for a post or page, one step at a time,
with a live preview beside it - 1 the look (a ready-made scene, or the post's own picture), 2 the words (each section's heading and
text; add a Text, Picture, Form or Map section, remove or move one), 3 the motion (how the hero gives way, how headings come in, a
moving gradient's motion), 4 where it shows. Finish makes any ready-made form, saves the scene (ProxyController.cfc saveScene) and
shows it on the post or page (setPostScene). The advanced Scene editor (window 107, sceneDetail.cfm) keeps everything else: layer
depths, pin length, fades, fonts and colors per section, videos and slideshows. The preview is the editor's own (admin/scenePreview.cfm),
the cards are sceneCards.cfm, and the steps run on common/js/galaxieWizard.js like the Moving hero wizard.
optArgs (11-07, owner: scenes go into posts from the post's side, so the wizard no longer asks where): 0 saves the scene to the library
(the Scenes window); "new:{postId}" also puts it at the top of that post or page (Create, Scene, or a post's Scene window);
"insert:{postId}" hands it to the Insert Scene window (window 122, galaxieInsertSceneChosen), which puts it where the owner chose. --->
<cfsilent>
<cfset swMode = reFind("^(new|insert):[0-9]+$", URL.optArgs ?: "") ? listFirst(URL.optArgs, ":") : "">
<cfset swForPostId = len(swMode) ? val(listLast(URL.optArgs, ":")) : 0>
<cfset swStarters = application.blog.getScenes().getStarters()>
<cfset swStarterParts = []>
<cfloop array="#swStarters#" index="swStarter">
	<cfset arrayAppend(swStarterParts, '{"key":' & serializeJSON(toString(swStarter.key)) & ',"json":' & swStarter.json & '}')>
</cfloop>
<cfset swStartersJson = replace(replace("[" & arrayToList(swStarterParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")>
<!--- The posts and pages it can show on, drafts too (a scene can go on a post before it is released). --->
<cfquery name="swPostRows" datasource="#application.dsn#">
	SELECT PostId, Title, PostAlias, DatePosted, IsPage
	FROM Post
	WHERE BlogRef = <cfqueryparam value="#application.BlogDbObj.getBlogId()#" cfsqltype="cf_sql_integer">
	AND (Remove IS NULL OR Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">)
	AND Title IS NOT NULL AND DatePosted IS NOT NULL
	ORDER BY Title
</cfquery>
<cfset swPostParts = []>
<cfloop query="swPostRows">
	<cfset swUrl = application.blog.makeLink(postId = swPostRows.PostId, isPage = swPostRows.IsPage eq 1, postAlias = swPostRows.PostAlias, datePosted = swPostRows.DatePosted)>
	<cfif application.serverRewriteRuleInPlace><cfset swUrl = replaceNoCase(swUrl, "/index.cfm", "")></cfif>
	<cfset arrayAppend(swPostParts, '{"id":' & swPostRows.PostId & ',"title":' & serializeJSON(toString(swPostRows.Title)) & ',"page":' & (swPostRows.IsPage eq 1 ? 'true' : 'false') & ',"url":' & serializeJSON(toString(swUrl)) & '}')>
</cfloop>
<cfset swPostsJson = replace(replace("[" & arrayToList(swPostParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")>
<!--- The post's own picture, for a "This post's picture" look. --->
<cfset swPhoto = "">
<cfif swForPostId gt 0>
	<cftry>
		<cfset swPostRow = application.blog.getPostByPostId(swForPostId, true, true)>
		<cfif arrayLen(swPostRow)>
			<cfset swPhoto = swPostRow[1]["MediaUrl"] ?: "">
			<cfif not len(swPhoto) and len(swPostRow[1]["MediaPath"] ?: "")><cfset swPhoto = application.blog.getEnclosureUrlFromMediaPath(swPostRow[1]["MediaPath"], true)></cfif>
			<cfif len(swPhoto) and not listFindNoCase("Image", swPostRow[1]["MediaType"] ?: "Image")><cfset swPhoto = ""></cfif>
		</cfif>
		<cfcatch type="any"><cfset swPhoto = ""></cfcatch>
	</cftry>
</cfif>
<!--- The ready-made forms, and the blog's maps (made in a post's editor, Insert, Map), for Form and Map sections. --->
<cfset swReadyParts = []>
<cfif structKeyExists(application, "webForms")>
	<cftry>
		<cfloop array="#application.webForms.getReadyMadeChoices()#" index="swReady">
			<cfset arrayAppend(swReadyParts, '{"key":' & serializeJSON(toString(swReady.key)) & ',"name":' & serializeJSON(toString(swReady.name)) & '}')>
		</cfloop>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cfif>
<cfset swMapParts = []>
<cftry>
	<cfquery name="swMapRows" datasource="#application.dsn#">
		SELECT m.MapId, m.MapTitle, m.MapName, m.Location, m.HasMapRoutes, p.Title AS PostTitle
		FROM Map m LEFT JOIN Post p ON p.PostId = m.PostRef
		ORDER BY m.MapId DESC
	</cfquery>
	<cfloop query="swMapRows">
		<cfset swMapName = len(trim(swMapRows.MapTitle)) ? swMapRows.MapTitle : (len(trim(swMapRows.Location)) ? swMapRows.Location : (len(trim(swMapRows.MapName)) ? swMapRows.MapName : "Map " & swMapRows.MapId))>
		<cfif len(trim(swMapRows.PostTitle))><cfset swMapName = swMapName & " (in " & swMapRows.PostTitle & ")"></cfif>
		<cfset arrayAppend(swMapParts, '{"id":' & swMapRows.MapId & ',"title":' & serializeJSON(toString(left(swMapName, 150))) & ',"routes":' & (swMapRows.HasMapRoutes eq 1 ? 'true' : 'false') & '}')>
	</cfloop>
	<cfcatch type="any"></cfcatch>
</cftry>
<cfset swSplitText = application.blog.getScenes().getSetting("librarySource", "cdn") neq "local" or arrayFind(application.blog.getScenes().getLocalLibraryFiles(), "SplitText.min.js")>
</cfsilent>
<cfinclude template="sceneCards.cfm">
<style>
	#sceneWizardWindow .k-button .fontAwesomeIcon { margin-right: 6px; }
	.swLayout { display: grid; grid-template-columns: minmax(0, 1.1fr) minmax(0, 1fr); gap: 16px; height: 100%; }
	@media (max-width: 900px) { .swLayout { grid-template-columns: 1fr; } }
	.swPreviewSide { display: flex; flex-direction: column; min-height: 420px; }
	.swPreviewBar { display: flex; align-items: center; gap: 8px; padding-bottom: 6px; }
	.swPreviewStage { flex: 1 1 auto; min-height: 380px; background: #2b2b2b; border-radius: 4px; overflow: hidden; }
	.swPreviewStage iframe { border: 0; width: 100%; height: 100%; display: block; }
	.swIntro { margin: 4px 0 10px; }
	.swSection { border: 1px solid rgba(128,128,128,.35); border-radius: 6px; padding: 8px 10px; margin-bottom: 8px; }
	.swSectionTop { display: flex; align-items: center; gap: 8px; margin-bottom: 6px; }
	.swSectionTop strong { flex: 1 1 auto; }
	.swSection .k-textbox, .swSection textarea { width: 100%; box-sizing: border-box; }
	.swSection textarea { min-height: 54px; }
	.swSection label { display: block; margin: 6px 0 2px; }
	.swThumb { max-width: 160px; max-height: 90px; display: block; margin-top: 6px; border-radius: 4px; }
	.swAdd { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; margin-top: 10px; }
	.swRow { margin-bottom: 12px; }
	.swRow > label { display: block; font-weight: bold; margin-bottom: 4px; }
	.swRadio label { display: block; margin: 4px 0; font-weight: normal; }
	.swDone { padding: 20px 6px; }
	.swDone h3 { margin-top: 0; }
	.swDone .k-button { margin: 4px 8px 4px 0; }
</style>

<cfoutput>
<div class="swLayout">
	<div><div id="sceneWizard"></div></div>
	<div class="swPreviewSide">
		<div class="swPreviewBar">
			<span>Live preview</span>
			<button type="button" class="k-button normalFontWeight" id="swReplay" title="Back to the top and play the page opening again"><i class="fontAwesomeIcon fas fa-rotate-left"></i>Replay</button>
			<span class="k-form-hint">Scroll inside the preview to see the rest of the scene.</span>
		</div>
		<div class="swPreviewStage"><iframe id="swPreviewFrame" title="Scene preview" src="#application.baseUrl#/admin/scenePreview.cfm"></iframe></div>
	</div>
</div>

<div id="swSteps" style="display: none;">
	<div id="swStep1">
		<p class="swIntro">Pick a look for your scene. Each one is complete: you can change its words next, and everything else later in the advanced Scene editor if you ever want to.</p>
		<div id="swCards" class="sceneCards" role="radiogroup" aria-label="Looks"></div>
	</div>
	<div id="swStep2">
		<p class="swIntro">The words for each part of the scene, top to bottom. Add a section, take one out, or move it up or down.</p>
		<div id="swSections"></div>
		<div class="swAdd">
			<span>Add a section:</span>
			<button type="button" class="k-button normalFontWeight" data-add="text"><i class="fontAwesomeIcon fas fa-align-left"></i>Text</button>
			<button type="button" class="k-button normalFontWeight" data-add="imageSlide"><i class="fontAwesomeIcon fas fa-image"></i>Picture</button>
			<button type="button" class="k-button normalFontWeight" data-add="form"><i class="fontAwesomeIcon fab fa-wpforms"></i>Form</button>
			<button type="button" class="k-button normalFontWeight" data-add="map" id="swAddMap"><i class="fontAwesomeIcon fas fa-map-location-dot"></i>Map</button>
		</div>
		<p class="k-form-hint" id="swNoMaps" style="display: none;">A Map section shows a map made in a post's editor (Insert, Map). Make one there first.</p>
	</div>
	<div id="swStep3">
		<div class="swRow swRadio">
			<label>How the picture at the top gives way</label>
			<label><input type="radio" name="swGives" value="scroll" class="k-radio"> It scrolls away with the page as you read</label>
			<label><input type="radio" name="swGives" value="held" class="k-radio"> It stays in place while its layers move, then gives way</label>
		</div>
		<div class="swRow">
			<label for="swHeads">How headings come in</label>
			<select id="swHeads" style="width: 95%;">
				<option value="slideInStay">Slides up into place</option>
				<option value="">Rises and fades as you scroll</option>
				<option value="slideIn">Fades up into place, then rises and fades as you scroll</option>
				<cfif swSplitText>
				<option value="words">Comes in word by word</option>
				<option value="letters">Comes in letter by letter</option>
				</cfif>
				<option value="still">Stays in place</option>
			</select>
			<div class="k-form-hint">For every heading in the scene. The preview plays it; Replay plays it again.</div>
		</div>
		<div class="swRow" id="swGradientMotion" style="display: none;">
			<label for="swMotion">The colors at the top</label>
			<select id="swMotion" style="width: 45%;">
				<option value="">Stay still</option>
				<option value="drift">Drift: slowly wander</option>
				<option value="shift">Shift: slowly change</option>
				<option value="breathe">Breathe: gently grow and shrink</option>
			</select>
			<select id="swSpeed" style="width: 45%;">
				<option value="">At a normal speed</option>
				<option value="slow">Slowly</option>
				<option value="fast">Quickly</option>
			</select>
		</div>
	</div>
</div>
</cfoutput>

<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/js/galaxieWizard.js"></script>
<script>
(function () {
	var BASE = "<cfoutput>#application.baseUrl#</cfoutput>";
	var CSRF = "<cfoutput>#csrfToken#</cfoutput>";
	var STARTERS = <cfoutput>#swStartersJson#</cfoutput>;
	var POSTS = <cfoutput>#swPostsJson#</cfoutput>;
	var READY_FORMS = <cfoutput>#replace("[" & arrayToList(swReadyParts, ",") & "]", "</", "<\/", "all")#</cfoutput>;
	var MAPS = <cfoutput>#replace(replace("[" & arrayToList(swMapParts, ",") & "]", "</", "<\/", "all"), "<!--", "<\!--", "all")#</cfoutput>;
	var FOR_POST = <cfoutput>#swForPostId#</cfoutput>;
	var MODE = "<cfoutput>#swMode#</cfoutput>";
	var PHOTO = <cfoutput>#serializeJSON(swPhoto)#</cfoutput>;
	var HERO = { layeredHero: 1, photoHero: 1, vantaHero: 1, gradientHero: 1, videoHero: 1 };
	var KIND_NAMES = { layeredHero: "The picture at the top", photoHero: "The picture at the top", vantaHero: "The animation at the top", gradientHero: "The colors at the top",
		videoHero: "The video at the top", text: "Text", imageSlide: "Picture", form: "Form", map: "Map", slideshow: "Slideshow", product: "Product" };
	var win = $("#sceneWizardWindow");
	var scene = null, chosenKey = null, previewReady = false;

	function clone(o) { return JSON.parse(JSON.stringify(o)); }
	function withBase(v) { return String(v || "").split("{baseUrl}").join(BASE); }
	function esc(s) { return $("<div/>").text(String(s || "")).html(); }
	<!--- The ready-made text is simple HTML (paragraphs); here it is plain text, a blank line between paragraphs. --->
	function htmlToText(html) {
		var d = $("<div/>").html(String(html || "").replace(/<br\s*\/?>/gi, "\n").replace(/<\/p>\s*/gi, "\n\n"));
		return $.trim(d.text());
	}
	function textToHtml(text) {
		return $.map($.trim(String(text || "")).split(/\n\s*\n/), function (p) { return p ? "<p>" + esc($.trim(p)).replace(/\n/g, "<br>") + "</p>" : null; }).join("");
	}
	function starterByKey(k) { for (var i = 0; i < STARTERS.length; i++) { if (STARTERS[i].key === k) { return STARTERS[i]; } } return null; }

	<!--- ---------- Preview: the Scene editor's preview page, sent the scene on every change. --->
	var previewTimer = null;
	function sendPreview() {
		clearTimeout(previewTimer);
		previewTimer = setTimeout(function () {
			var frame = document.getElementById("swPreviewFrame");
			if (!previewReady || !scene || !frame || !frame.contentWindow) { return; }
			var copy = clone(scene); copy.settings = copy.settings || {};
			frame.contentWindow.postMessage({ type: "galaxieScenePreview", json: JSON.stringify(copy), fontCss: "" }, window.location.origin);
		}, 150);
	}
	$("#swPreviewFrame").on("load", function () { previewReady = true; sendPreview(); });
	$("#swReplay").on("click", function () { try { document.getElementById("swPreviewFrame").contentWindow.scrollTo(0, 0); } catch (e) {} sendPreview(); });

	<!--- ---------- Step 1: the look. --->
	function looks() {
		var list = $.map(STARTERS, function (s) { return { key: s.key, data: s.json }; });
		<!--- The post's own picture, on the Photo story scene's layout. --->
		var photoStarter = starterByKey("photo");
		if (PHOTO && photoStarter) {
			var d = clone(photoStarter.json);
			d.name = "This post's picture"; d.description = "Your post's own picture at the top, held in place with a slow zoom.";
			if (d.sections && d.sections[0]) { d.sections[0].image = PHOTO; d.sections[0].imagePhone = PHOTO; }
			delete d.thumbnail;
			list.unshift({ key: "postPhoto", data: d });
		}
		return list;
	}
	function drawCards() {
		var box = $("#swCards").empty();
		$.each(looks(), function (i, l) {
			var card = $('<button type="button" class="sceneCard" role="radio"></button>').toggleClass("selected", l.key === chosenKey).attr("aria-checked", l.key === chosenKey ? "true" : "false");
			card.append(galaxieSceneCardThumb(l.data, BASE), $('<div class="sceneCardText"></div>').append($("<strong></strong>").text(l.data.name || l.key), $("<span></span>").text(l.data.description || "")));
			card.on("click", function () {
				chosenKey = l.key; scene = clone(l.data); delete scene.order; delete scene.description; delete scene.thumbnail;
				applyMotion(); drawCards(); sendPreview();
			});
			card.on("dblclick", function () { wizard.select(1); });
			box.append(card);
		});
	}

	<!--- ---------- Step 2: the words. --->
	function sectionColour() {
		var last = null;
		$.each(scene.sections, function (i, s) { if (s.kind === "text") { last = s; } });
		return last ? { colour: last.colour, gradient: last.gradient, textColour: last.textColour } : { colour: scene.pageColour || "#222222" };
	}
	function drawSections() {
		var box = $("#swSections").empty();
		$("#swAddMap").prop("disabled", !MAPS.length); $("#swNoMaps").toggle(!MAPS.length);
		$.each(scene.sections, function (i, s) {
			var hero = !!HERO[s.kind];
			var row = $('<div class="swSection"></div>');
			var top = $('<div class="swSectionTop"></div>').append($("<strong></strong>").text((i + 1) + ". " + (KIND_NAMES[s.kind] || s.kind)));
			if (!hero) {
				top.append($('<button type="button" class="k-button normalFontWeight" title="Move up"><i class="fontAwesomeIcon fas fa-arrow-up" style="margin:0"></i></button>').prop("disabled", i < 2 && HERO[(scene.sections[0] || {}).kind]).on("click", function () { move(i, -1); }));
				top.append($('<button type="button" class="k-button normalFontWeight" title="Move down"><i class="fontAwesomeIcon fas fa-arrow-down" style="margin:0"></i></button>').prop("disabled", i === scene.sections.length - 1).on("click", function () { move(i, 1); }));
				top.append($('<button type="button" class="k-button normalFontWeight" title="Take this section out"><i class="fontAwesomeIcon fas fa-trash-can" style="margin:0"></i></button>').on("click", function () {
					galaxieConfirm("Take this section out?", "", function () { scene.sections.splice(i, 1); drawSections(); sendPreview(); });
				}));
			}
			row.append(top);
			if (s.kind === "slideshow") {
				row.append($('<div class="k-form-hint"></div>').text("A slideshow of pictures, kept as it is. Change it in the advanced Scene editor."));
			} else {
				var head = $('<input type="text" class="k-textbox" aria-label="Heading">').val(s.heading || "").attr("placeholder", "Heading");
				head.on("input", function () { s.heading = $(this).val(); sendPreview(); });
				var text = $('<textarea class="k-textbox" aria-label="Text"></textarea>').val(htmlToText(s.html)).attr("placeholder", hero ? "A line or two under the heading (optional)" : "The text (a blank line starts a new paragraph)");
				text.on("input", function () { s.html = textToHtml($(this).val()); sendPreview(); });
				row.append($("<label></label>").text("Heading"), head, $("<label></label>").text("Text"), text);
			}
			if (s.kind === "imageSlide") {
				var file = $('<input type="file" accept="image/*" style="display:none;">');
				var status = $('<span class="k-form-hint"></span>');
				var thumb = s.image ? $('<img class="swThumb" alt="">').attr("src", withBase(s.image)) : $('<div class="k-form-hint">No picture yet.</div>');
				var pick = $('<button type="button" class="k-button normalFontWeight"><i class="fontAwesomeIcon fas fa-upload"></i>' + (s.image ? "Change the picture" : "Upload a picture") + '</button>').on("click", function () { file.trigger("click"); });
				file.on("change", function () { upload(this.files && this.files[0], status, function (r) { s.image = r.location; if (r.phoneLocation) { s.imagePhone = r.phoneLocation; } drawSections(); sendPreview(); }); });
				row.append($("<label></label>").text("Picture"), pick, status, file, thumb);
			}
			if (s.kind === "form") {
				var sel = $("<select></select>").css("width", "95%");
				if (s.form && !s.pendingReadyMade) { sel.append($("<option></option>").attr("value", "").text(s.formTitle || "This scene's form")); }
				$.each(READY_FORMS, function (j, r) { sel.append($("<option></option>").attr("value", r.key).text(r.name)); });
				sel.val(s.pendingReadyMade || "");
				sel.on("change", function () {
					var v = $(this).val();
					if (v) { var r = $.grep(READY_FORMS, function (x) { return x.key === v; })[0]; s.pendingReadyMade = v; s.formTitle = r ? r.name : v; delete s.form; }
					sendPreview();
				});
				row.append($("<label></label>").text("Form"), sel);
			}
			if (s.kind === "map") {
				var msel = $("<select></select>").css("width", "95%");
				$.each(MAPS, function (j, m) { msel.append($("<option></option>").attr("value", m.id).text(m.title)); });
				msel.val(String(s.mapId || ""));
				msel.on("change", function () { var m = $.grep(MAPS, function (x) { return String(x.id) === $(msel).val(); })[0]; if (m) { s.mapId = m.id; s.mapType = m.routes ? "route" : "static"; } sendPreview(); });
				row.append($("<label></label>").text("Map"), msel);
			}
			box.append(row);
		});
		box.find("select").each(function () { $(this).kendoDropDownList(); });
	}
	function move(i, by) {
		var j = i + by;
		if (j < 0 || j >= scene.sections.length || HERO[scene.sections[j].kind]) { return; }
		var s = scene.sections.splice(i, 1)[0]; scene.sections.splice(j, 0, s);
		drawSections(); sendPreview();
	}
	function upload(file, status, done) {
		if (!file) { return; }
		var data = new FormData(); data.append("csrfToken", CSRF); data.append("file", file);
		status.text("Uploading " + file.name + "...");
		jQuery.ajax({
			type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=uploadSceneImage", data: data, processData: false, contentType: false, dataType: "json",
			success: function (r) {
				status.text("");
				if (typeof r === "string") { try { r = JSON.parse(r); } catch (e) {} }
				if (r && r.success) { done(r); } else { alert2("Could not upload the picture", (r && r.errorMessage) || "The picture could not be uploaded."); }
			},
			error: function (jqXHR, textStatus, error) { status.text(""); if (jqXHR.status === 403) { createLoginWindow(); } else { alert2("Error while uploading", error); } }
		});
	}
	function alert2(title, message) { $.when(kendo.ui.ExtAlertDialog.show({ title: title, message: $("<div/>").text(message).html(), icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
	$("#swSteps [data-add]").on("click", function () {
		var kind = $(this).attr("data-add"), look = sectionColour();
		var s = { kind: kind, align: "center" };
		if (kind === "text") { s.heading = "A new section"; s.html = "<p>Your words here.</p>"; $.extend(s, look); }
		if (kind === "imageSlide") { s.heading = "A picture"; s.html = ""; s.image = ""; }
		if (kind === "form") {
			s.heading = "Get in touch"; s.html = ""; $.extend(s, look);
			var contact = $.grep(READY_FORMS, function (r) { return r.key === "contact"; })[0] || READY_FORMS[0];
			if (contact) { s.pendingReadyMade = contact.key; s.formTitle = contact.name; }
		}
		if (kind === "map") { s.heading = "Where to find us"; s.html = ""; s.mapHeight = "70"; $.extend(s, look); if (MAPS.length) { s.mapId = MAPS[0].id; s.mapType = MAPS[0].routes ? "route" : "static"; } }
		scene.sections.push(s);
		applyMotion(); drawSections(); sendPreview();
		var list = document.getElementById("swSections"); if (list) { list.lastElementChild.scrollIntoView({ block: "nearest" }); }
	});

	<!--- ---------- Step 3: the motion, for every section at once. --->
	var motion = { gives: null, heads: "slideInStay", gradient: "", speed: "" };
	function hero() { var s = scene && scene.sections[0]; return s && HERO[s.kind] ? s : null; }
	function applyMotion() {
		if (!scene) { return; }
		var h = hero();
		if (h) {
			if (motion.gives === "scroll") { h.pin = false; } else if (motion.gives === "held") { delete h.pin; }
			if (h.kind === "gradientHero") {
				if (motion.gradient) { h.motion = motion.gradient; } else { delete h.motion; }
				if (motion.gradient && motion.speed) { h.motionSpeed = motion.speed; } else { delete h.motionSpeed; }
			}
		}
		$.each(scene.sections, function (i, s) {
			if (s.kind === "slideshow") { return; }
			delete s.textMotion; delete s.headingEffect;
			var v = motion.heads;
			if (v === "words" || v === "letters") { s.headingEffect = v; }
			else if (HERO[s.kind]) { if (v) { s.textMotion = v; } }
			<!--- The other sections have no scroll motion: Slides up and Stays in place carry over, the rest fade up as before. --->
			else if (v === "slideInStay" || v === "still") { s.textMotion = v; }
		});
	}
	function drawMotion() {
		var h = hero();
		if (motion.gives === null) { motion.gives = h && h.pin === false ? "scroll" : "held"; }
		$("input[name=swGives][value=" + motion.gives + "]").prop("checked", true);
		$("input[name=swGives]").closest(".swRow").toggle(!!h);
		$("#swGradientMotion").toggle(!!(h && h.kind === "gradientHero"));
		if (h && h.kind === "gradientHero" && !motion.gradient && h.motion) { motion.gradient = h.motion; motion.speed = h.motionSpeed || ""; }
		$("#swHeads").data("kendoDropDownList").value(motion.heads);
		$("#swMotion").data("kendoDropDownList").value(motion.gradient);
		$("#swSpeed").data("kendoDropDownList").value(motion.speed);
	}
	$("input[name=swGives]").on("change", function () { motion.gives = $(this).val(); applyMotion(); sendPreview(); });
	$("#swHeads").kendoDropDownList({ change: function () { motion.heads = this.value(); applyMotion(); $("#swReplay").trigger("click"); } });
	$("#swMotion").kendoDropDownList({ change: function () { motion.gradient = this.value(); applyMotion(); sendPreview(); } });
	$("#swSpeed").kendoDropDownList({ change: function () { motion.speed = this.value(); applyMotion(); sendPreview(); } });

	<!--- ---------- Finish: forms, then the scene, then the post. --->
	function aliasFrom(text) { return String(text || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").substr(0, 60); }
	function finish() {
		var missing = $.grep(scene.sections, function (s) { return s.kind === "imageSlide" && !s.image; });
		if (missing.length) { alert2("A picture is missing", "Upload a picture for each Picture section, or take the section out."); wizard.select(1); return; }
		<!--- The post it's for: Create, Scene puts it at the top of that post; Insert, Scene gets it back to place it. --->
		var post = { id: 0, title: "", url: "" };
		if (FOR_POST) { $.each(POSTS, function (i, p) { if (p.id === FOR_POST) { post = { id: p.id, title: (p.page ? "Page: " : "") + p.title, url: p.url }; } }); }
		var lookName = scene.name || "Scene";
		scene.name = post.id ? lookName.replace(/\s*\(.*\)$/, "") + " (" + post.title.replace(/^Page: /, "") + ")" : lookName;
		var alias = (aliasFrom(post.id ? post.title.replace(/^Page: /, "") : lookName) || "scene") + "-" + Date.now().toString(36).slice(-4);
		var buttons = $("#sceneWizard .gw-buttons .k-button").prop("disabled", true);
		var waiting = $.grep(scene.sections, function (s) { return s.kind === "form" && s.pendingReadyMade; });
		var failed = function () { buttons.prop("disabled", false); };
		var makeForms = function () {
			var s = waiting.shift();
			if (!s) { save(); return; }
			jQuery.ajax({
				type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=useReadyMadeForm", dataType: "json",
				data: { csrfToken: CSRF, key: s.pendingReadyMade, usedFor: post.id ? post.title.replace(/^Page: /, "") : lookName },
				success: function (r) {
					if (typeof r === "string") { try { r = JSON.parse(r); } catch (e) {} }
					if (r && r.success) { s.form = r.alias; s.formTitle = r.title; delete s.pendingReadyMade; makeForms(); }
					else { failed(); alert2("The form could not be made", ((r && r.errors) || ["The form could not be made."]).join(" ")); }
				},
				error: function (jqXHR) { failed(); if (jqXHR.status === 403) { createLoginWindow(); } }
			});
		};
		var save = function () {
			jQuery.ajax({
				type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=saveScene", dataType: "json",
				data: { csrfToken: CSRF, sceneId: 0, alias: alias, active: true, sceneJson: JSON.stringify(scene) },
				success: function (r) {
					if (typeof r === "string") { try { r = JSON.parse(r); } catch (e) {} }
					if (!(r && r.success)) { failed(); alert2("Could not save", (r && r.errorMessage) || "The scene could not be saved."); return; }
					var sceneId = r.sceneId;
					try { refreshScenesWindow(); } catch (e) {}
					$(document).trigger("galaxieSceneSaved", [{ sceneId: sceneId, alias: alias }]);
					if (MODE === "insert") {
						if (typeof window.galaxieInsertSceneChosen === "function") { window.galaxieInsertSceneChosen(alias, scene.name); }
						closeWindow(); return;
					}
					if (MODE !== "new" || !post.id) { done(sceneId, null); return; }
					jQuery.ajax({
						type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=setPostScene", dataType: "json",
						data: { csrfToken: CSRF, postId: post.id, alias: alias },
						success: function (r2) {
							if (typeof r2 === "string") { try { r2 = JSON.parse(r2); } catch (e) {} }
							if (r2 && r2.success) { done(sceneId, post); } else { done(sceneId, null); alert2("Saved, but not shown on the post", (r2 && r2.errorMessage) || "Show it from the post's Scene window."); }
						},
						error: function () { done(sceneId, null); }
					});
				},
				error: function (jqXHR, textStatus, error) { failed(); if (jqXHR.status === 403) { createLoginWindow(); } else { alert2("Error while saving", error); } }
			});
		};
		makeForms();
	}
	function done(sceneId, post) {
		var box = $('<div class="swDone"></div>');
		box.append($("<h3></h3>").html('<i class="fontAwesomeIcon fas fa-check" style="color:#37b400"></i> ' + (post ? "Your scene is on &ldquo;" + esc(post.title.replace(/^Page: /, "")) + "&rdquo;" : "Your scene is saved")));
		box.append($("<p></p>").text(post ? "Visitors see it at the top of that " + (/^Page: /.test(post.title) ? "page" : "post") + "." : "To show it, open a post or page in its editor and choose Insert, Scene."));
		if (post && post.url) { box.append($('<a class="k-button k-primary" target="_blank" rel="noopener"><i class="fontAwesomeIcon fas fa-arrow-up-right-from-square"></i>View it</a>').attr("href", post.url + (post.url.indexOf("?") < 0 ? "?" : "&") + "showPendingPosts")); }
		box.append($('<button type="button" class="k-button"><i class="fontAwesomeIcon fas fa-sliders"></i>Fine-tune in the advanced editor</button>').on("click", function () { closeWindow(); createAdminInterfaceWindow(107, sceneId); }));
		box.append($('<button type="button" class="k-button">Close</button>').on("click", closeWindow));
		$("#sceneWizard").empty().append(box);
	}
	function closeWindow() { var w = win.data("kendoWindow"); if (w) { w.close(); } }

	var wizard = $("#sceneWizard").galaxieWizard({
		steps: [
			{ title: "Look", content: $("#swStep1"), buttons: ["next"] },
			{ title: "Words", content: $("#swStep2"), buttons: ["previous", "next"] },
			{ title: "Motion", content: $("#swStep3"), buttons: ["previous", { name: "done", text: "Finish" }] }
		],
		stepper: { linear: false },
		select: function (e) { if (e.step.options.index > 0 && !scene) { e.preventDefault(); alert2("Pick a look first", "Choose one of the looks to start from."); } },
		activate: function (e) {
			var i = e.step.options.index;
			if (i === 1) { drawSections(); } else if (i === 2) { drawMotion(); }
		},
		done: function (e) { if (e && e.preventDefault) { e.preventDefault(); } finish(); }
	}).data("galaxieWizard");
	$("#swSteps").remove();

	<!--- Start on the first look, so the preview shows something straight away. --->
	var first = looks()[0];
	if (first) { chosenKey = first.key; scene = clone(first.data); delete scene.order; delete scene.description; delete scene.thumbnail; applyMotion(); }
	drawCards();
	sendPreview();
})();
</script>
