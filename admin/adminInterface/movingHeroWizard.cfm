<!--- The Moving hero wizard (window 119, 11-04, owner: "the interface is quite long and can be confusing. having a new window pop up
would solve that and keep the current step in focus"). It took the place of the Moving hero section that was in the Hero window
(enclosureImageEditor.cfm), one step at a time: 1 the picture, 2 the heading (the same choices as the Hero text window, postHeroText.cfm),
3 where the heading sits and how it gives way to the post, 4 an optional cover picture. Mock-up the owner approved:
https://claude.ai/artifact/9GdzwQPFeTWmFun1KCGkGb. Finish saves it all at once (ProxyController.cfc savePostHeroParallax ->
Scenes.cfc usePostHeroParallax, alias post-hero-{postId}), then the Hero window's preview and summary line redraw. The steps run on
common/js/galaxieWizard.js, as the Site Wizard does. optArgs is the postId. --->
<cfsilent>
<cfset mhwPostId = val(URL.optArgs)>
<cfset mhwPosts = application.blog.getPostByPostId(mhwPostId, true, true)>
<cfif arrayLen(mhwPosts)>
	<cfset mhwPost = mhwPosts[1]>
	<cfset mhwScenes = application.blog.getScenes()>
	<cfset mhwState = mhwScenes.getPostHeroParallax(mhwPostId)>
	<cfset mhwStarters = mhwScenes.getHeroParallaxStarters()>
	<!--- The post's own picture, for "This post's picture (gentle zoom)" and for the cover step. --->
	<cfset mhwPhoto = (len(mhwPost["MediaUrl"] ?: "") and (mhwPost["MediaType"] ?: "") eq "Image") ? mhwPost["MediaUrl"] : "">
	<cfset mhwCover = mhwPost["HeroCoverImageUrl"] ?: "">
	<!--- A full-page scene shown on this post (11-02, one rule: a post shows a hero or a full scene, never both). --->
	<cfset mhwOtherName = "">
	<cfif len(mhwState.otherScene)>
		<cfset mhwOtherName = mhwState.sceneId gt 0 ? (mhwScenes.getScene(mhwState.sceneId).name ?: mhwState.otherScene) : mhwState.otherScene>
	</cfif>
	<!--- The blog's fonts for the Font list and the preview, the same as the Hero text window. --->
	<cfset mhwFonts = application.blog.getFont()>
	<cfset mhwFontCss = "">
	<cfset mhwFontExt = application.serverSupportsWoff2 ? "woff2" : "woff">
	<cfloop array="#mhwFonts#" index="mhwFont">
		<cfif not (isBoolean(mhwFont["WebSafeFont"] ?: "") and mhwFont["WebSafeFont"]) and len(mhwFont["FileName"] ?: "")>
			<cfset mhwFontCss = mhwFontCss & '@font-face{font-family:"' & replace(mhwFont["Font"], '"', '', 'all') & '";src:url(' & application.baseUrl & '/common/fonts/' & mhwFont["FileName"] & '.' & mhwFontExt & ') format("' & mhwFontExt & '");font-display:swap;}'>
		</cfif>
	</cfloop>
	<cfset mhwFontNames = []>
	<cfloop array="#mhwFonts#" index="mhwFont"><cfset arrayAppend(mhwFontNames, mhwFont["Font"])></cfloop>
</cfif>
</cfsilent>
<cfif not arrayLen(mhwPosts)>
	<p>This post no longer exists.</p>
	<cfexit>
</cfif>
<cfif len(mhwOtherName)>
	<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0">
		<tr><td class="<cfoutput>#HtmlUtilsObj.getKendoClass('')#</cfoutput>">This post shows the scene <b><cfoutput>#encodeForHtml(mhwOtherName)#</cfoutput></b>, a full-page scene, so its hero comes from the scene. To change it, or to take it off this post, open the scene from the Scenes icon on the admin home page.</td></tr>
	</table>
	<cfexit>
</cfif>

<style>
	<cfoutput>#mhwFontCss#</cfoutput>
	#movingHeroWizard { padding: 4px 8px; }
	.mhwIntro { margin: 4px 0 10px; }
	.mhwCards { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; }
	.mhwCards.mhwThree { grid-template-columns: repeat(3, minmax(0, 1fr)); }
	@media (max-width: 760px) { .mhwCards, .mhwCards.mhwThree { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
	.mhwCard { border: 2px solid rgba(128,128,128,.35); border-radius: 8px; padding: 4px; background: transparent; color: inherit; font: inherit; text-align: left; cursor: pointer; }
	.mhwCard:hover, .mhwCard:focus { border-color: rgba(128,128,128,.8); outline: none; }
	.mhwCard[aria-checked="true"] { border-color: currentColor; box-shadow: 0 0 0 1px currentColor; }
	.mhwName { display: block; margin-top: 4px; font-size: 13px; line-height: 1.25; }
	.mhwArt { display: block; position: relative; aspect-ratio: 16 / 9; max-width: 100%; border-radius: 4px; overflow: hidden; background: #2b3540; background-size: cover; background-position: center; transition: background-size 2.4s ease-in-out; }
	.mhwArt img { position: absolute; left: 0; top: -12%; width: 100%; height: 125%; object-fit: cover; transition: transform 2.4s ease-in-out; }
	.mhwText { position: absolute; left: 8%; right: 8%; display: flex; flex-direction: column; color: #ffffff; }
	.mhwText b { line-height: 1.1; }
	.mhwText.middle { top: 50%; transform: translateY(-50%); } .mhwText.low { bottom: 10%; }
	.mhwText.left { text-align: left; } .mhwText.center { text-align: center; } .mhwText.right { text-align: right; }
	.mhwBars { position: absolute; left: 8%; right: 8%; display: flex; flex-direction: column; gap: 3px; }
	.mhwBars i { display: block; width: 46%; height: 6px; border-radius: 3px; background: #ffffff; box-shadow: 0 1px 3px rgba(0,0,0,.6); }
	.mhwBars i + i { width: 30%; height: 4px; opacity: .85; }
	.mhwBars.middle { top: 50%; transform: translateY(-50%); } .mhwBars.low { bottom: 10%; }
	.mhwBars.left { align-items: flex-start; } .mhwBars.center { align-items: center; } .mhwBars.right { align-items: flex-end; }
	.mhwPreview { max-width: 620px; margin: 0 auto 10px; }
	.mhwTwo { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 16px; align-items: start; }
	@media (max-width: 760px) { .mhwTwo { grid-template-columns: 1fr; } }
	.mhwCoverArt { aspect-ratio: 16 / 9; max-width: 100%; border-radius: 6px; overflow: hidden; border: 2px dashed rgba(128,128,128,.5); display: flex; align-items: center; justify-content: center; text-align: center; padding: 10px; box-sizing: border-box; }
	.mhwCoverArt img { width: 100%; height: 100%; object-fit: cover; }
	.mhwCoverArt.mhwHas { border-style: solid; padding: 0; }
	.mhwButtons { display: flex; flex-wrap: wrap; gap: 8px; margin: 10px 0; }
	<!--- Kendo buttons are flex boxes, which drop the space between icon and text (11-05, owner): give the icon its own margin. --->
	#movingHeroWizardWindow .k-button .fontAwesomeIcon { margin-right: 6px; }
</style>

<cfset blockClass = HtmlUtilsObj.getKendoClass('')>
<cfoutput>
<div id="movingHeroWizard"></div>

<!--- The steps' content, moved into the wizard below. --->
<div id="mhwSteps" style="display: none;">
	<div id="mhwStep1">
		<p class="mhwIntro">Pick the layered picture for the top of the post. Point at one to see it move; on the post it moves as the reader scrolls.</p>
		<div id="mhwCards" class="mhwCards" role="radiogroup" aria-label="Pictures"></div>
		<p class="k-form-hint" id="mhwPickHint" style="display: none;">Please choose a picture first.</p>
		<!--- Remove, when the post has one (11-04: it was a button in the Hero window). --->
		<cfif mhwState.active>
		<div class="mhwButtons"><button type="button" class="k-button normalFontWeight" id="mhwRemove"><i class="fontAwesomeIcon fas fa-trash-can"></i> Remove the moving hero</button></div>
		</cfif>
	</div>

	<!--- The same rows and controls as the Hero text window (owner 11-04: "the new moving hero font stuff needs to be the same as the
	animated hero font ui"). --->
	<div id="mhwStep2">
		<div class="mhwPreview" id="mhwHeadPreview"></div>
		<table class="k-content adminBlocks" width="100%" cellpadding="5" cellspacing="0" border="0" style="table-layout: fixed">
			<colgroup><col style="width: 20%"><col></colgroup>
			<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Text</h4></td></tr>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr>
				<td class="#blockClass#" align="right"><label for="mhwHeading">Heading:</label></td>
				<td class="#blockClass#"><input type="text" id="mhwHeading" class="k-textbox mhwInput" maxlength="300" style="width: 95%;"></td>
			</tr>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr>
				<td class="#blockClass#" align="right"><label for="mhwLine">Second line:</label></td>
				<td class="#blockClass#"><input type="text" id="mhwLine" class="k-textbox mhwInput" maxlength="300" style="width: 95%;" placeholder="Optional"></td>
			</tr>
			<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Look</h4></td></tr>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr>
				<td class="#blockClass#" align="right"><label for="mhwColor">Color:</label></td>
				<td class="#blockClass#"><input id="mhwColor" value="##ffffff"></td>
			</tr>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr>
				<td class="#blockClass#" align="right"><label for="mhwFont">Font:</label></td>
				<td class="#blockClass#"><input id="mhwFont" style="width: 60%;"></td>
			</tr>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr>
				<td class="#blockClass#" align="right"><label for="mhwSize">Heading size:</label></td>
				<td class="#blockClass#"><input type="range" id="mhwSize" min="16" max="96" step="1" value="56" style="width: 60%;"> <span id="mhwSizeValue"></span></td>
			</tr>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr>
				<td class="#blockClass#" align="right"><label for="mhwSizePhone">On mobile:</label></td>
				<td class="#blockClass#"><input type="range" id="mhwSizePhone" min="14" max="64" step="1" value="30" style="width: 60%;"> <span id="mhwSizePhoneValue"></span></td>
			</tr>
			<cfset blockClass = HtmlUtilsObj.getKendoClass(blockClass)>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr><td colspan="2" class="#blockClass#"><h4 class="adminBlockHeading">Shadow and glow</h4></td></tr>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr>
				<td class="#blockClass#" align="right"><label for="mhwShadow">Shadow:</label></td>
				<td class="#blockClass#">
					<select id="mhwShadow" style="width: 220px;"><option value="none">None</option><option value="soft">Soft</option><option value="strong">Strong</option></select>
					<input id="mhwShadowColor" value="##000000">
					<div class="k-form-hint">Makes the text stand out on a busy picture.</div>
				</td>
			</tr>
			<tr class="blockSpacer"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr>
				<td class="#blockClass#" align="right"><label for="mhwGlowOn">Glow:</label></td>
				<td class="#blockClass#">
					<input type="checkbox" id="mhwGlowOn" class="k-checkbox"> <label for="mhwGlowOn" class="k-checkbox-label">Glow around the text</label>
					<input id="mhwGlowColor" value="##ffd27a">
					<div class="k-form-hint">A halo in a color of its own; try a light or bright color on a dark hero.</div>
				</td>
			</tr>
			<tr class="blockSpacer mhwGlowRow"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr class="mhwGlowRow">
				<td class="#blockClass#" align="right"><label for="mhwGlowOpacity">Glow opacity:</label></td>
				<td class="#blockClass#"><input type="range" id="mhwGlowOpacity" min="10" max="100" step="5" value="80" style="width: 60%;"> <span id="mhwGlowOpacityValue"></span></td>
			</tr>
			<tr class="blockSpacer mhwGlowRow"><td colspan="2" class="border #blockClass#"></td></tr>
			<tr class="mhwGlowRow">
				<td class="#blockClass#" align="right"><label for="mhwGlowSoftness">Glow softness:</label></td>
				<td class="#blockClass#"><input type="range" id="mhwGlowSoftness" min="4" max="60" step="1" value="24" style="width: 60%;"> <span id="mhwGlowSoftnessValue"></span></td>
			</tr>
		</table>
	</div>

	<div id="mhwStep3">
		<div class="mhwTwo">
			<div><div id="mhwStylePreview"></div><div class="k-form-hint">The preview moves on its own here; on the post it follows the scroll.</div></div>
			<div>
				<label class="adminBlockHeading" style="display: block; margin-bottom: 6px;">Where the heading sits</label>
				<div id="mhwPositions" class="mhwCards mhwThree" role="radiogroup" aria-label="Where the heading sits"></div>
				<!--- How it gives way to the post (2026-11-01, owner): Scenes.cfc usePostHeroParallax ending. --->
				<!--- How the heading moves (11-05, owner): Scenes.cfc usePostHeroParallax textMotion. Word by word and letter by letter
				need the SplitText plugin (as in the Scene editor). --->
				<label for="mhwTextMotion" class="adminBlockHeading" style="display: block; margin: 12px 0 6px;">How the heading moves</label>
				<select id="mhwTextMotion" style="width: 95%;">
					<option value="">Rises and fades as you scroll</option>
					<option value="slideIn">Slides up into place, then rises and fades as you scroll</option>
					<cfif application.blog.getScenes().getSetting("librarySource", "cdn") neq "local" or arrayFind(application.blog.getScenes().getLocalLibraryFiles(), "SplitText.min.js")>
					<option value="words">Comes in word by word, then rises and fades</option>
					<option value="letters">Comes in letter by letter, then rises and fades</option>
					</cfif>
					<option value="still">Stays in place on the picture</option>
				</select>
				<label for="mhwEnding" class="adminBlockHeading" style="display: block; margin: 12px 0 6px;">How it gives way to the post</label>
				<select id="mhwEnding" style="width: 95%;">
					<option value="">Scrolls away (the layers move as it goes)</option>
					<option value="edge">Held, then a soft edge (the post's text rises with a soft edge above it)</option>
					<option value="sharp">Held, then a sharp edge (the post slides up over it)</option>
					<option value="fade">Held, then it fades out over the text</option>
				</select>
			</div>
		</div>
	</div>

	<div id="mhwStep4">
		<p class="mhwIntro">Facebook, X, Google and the post cards on your front page show a still picture. They can't show a moving hero. This step is optional: press Finish to skip it.</p>
		<div class="mhwTwo">
			<div><div id="mhwCoverArt" class="mhwCoverArt"></div></div>
			<div>
				<div id="mhwCoverNote"></div>
				<div class="mhwButtons">
					<button type="button" class="k-button normalFontWeight" id="mhwCoverUpload"><i class="fontAwesomeIcon fas fa-camera-retro"></i> Upload a picture...</button>
					<button type="button" class="k-button normalFontWeight" id="mhwCoverStill"><i class="fontAwesomeIcon fas fa-image"></i> Use a still of this picture</button>
				</div>
				<div class="k-form-hint" id="mhwCoverStatus"></div>
				<div class="k-form-hint">You can add or change the cover later with the camera on the Hero window's toolbar.</div>
			</div>
		</div>
	</div>
</div>
</cfoutput>

<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/js/galaxieWizard.js"></script>
<script>
(function () {
	var BASE = "<cfoutput>#application.baseUrl#</cfoutput>";
	var CSRF = "<cfoutput>#csrfToken#</cfoutput>";
	var postId = <cfoutput>#mhwPostId#</cfoutput>;
	var state = <cfoutput>#replace(serializeJSON(mhwState), "</", "<\/", "all")#</cfoutput>;
	var starters = <cfoutput>#replace(serializeJSON(mhwStarters), "</", "<\/", "all")#</cfoutput>;
	var photo = <cfoutput>#serializeJSON(mhwPhoto)#</cfoutput>;
	var cover = <cfoutput>#serializeJSON(mhwCover)#</cfoutput>;
	var fonts = $.map(<cfoutput>#replace(serializeJSON(mhwFontNames), "</", "<\/", "all")#</cfoutput>, function (f) { return { name: f }; });
	var postTitle = <cfoutput>#replace(serializeJSON(mhwPost["Title"] ?: ""), "</", "<\/", "all")#</cfoutput>;
	// The Hero text window's own lists: the positions (as the old Moving hero section had them) and the shadows (galaxieScene.js SHADOWS).
	var POSITIONS = [["center", "", "Middle, center"], ["left", "", "Middle, left"], ["right", "", "Middle, right"], ["left", "bottom", "Low, left (magazine)"], ["center", "bottom", "Low, center"], ["right", "bottom", "Low, right"]];
	var SHADOWS = {
		soft: function (c) { return "0 2px 6px " + rgba(c, 0.65); },
		strong: function (c) { return "0 3px 12px " + rgba(c, 0.85) + ", 0 0 2px " + rgba(c, 0.9); }
	};
	var chosen = state.active ? state.starter : null;
	var align = state.align || "center", low = state.textPosition === "bottom";
	var timers = [];
	var win = $("#movingHeroWizardWindow");

	function rgba(hex, a) {
		var m = /^#?([0-9a-f]{6})$/i.exec(hex || ""); var n = m ? parseInt(m[1], 16) : 0;
		return "rgba(" + ((n >> 16) & 255) + "," + ((n >> 8) & 255) + "," + (n & 255) + "," + a + ")";
	}
	function withBase(v) { return String(v || "").split("{baseUrl}").join(BASE); }
	function starterByKey(k) { for (var i = 0; i < starters.length; i++) { if (starters[i].key === k) { return starters[i]; } } return null; }
	function pickName() { if (chosen === "photo") { return "This post's picture"; } var s = starterByKey(chosen); return s ? s.name : ""; }
	function art(key) {
		var a = $('<span class="mhwArt" aria-hidden="true"></span>');
		if (key === "photo") { a.addClass("mhwPhoto").css("background-image", 'url("' + String(photo).replace(/"/g, "") + '")'); }
		else { var s = starterByKey(key); if (s) { $.each(s.layers, function (i, l) { a.append($('<img alt="">').attr({ src: withBase(l.src), "data-depth": l.depth })); }); } }
		return a;
	}
	function move(box, amount) {
		box.find("img").each(function () { this.style.transform = "translateY(" + (-amount * (Number(this.getAttribute("data-depth")) || 0) / 700) + "%)"; });
		if (box.hasClass("mhwPhoto")) { box.css("background-size", amount ? "125%" : "cover"); }
	}
	// A preview that moves on its own, as the post's moves with the scroll.
	function sway(box) {
		var up = true, go = function () { move(box, up ? 22 : 0); up = !up; };
		setTimeout(go, 50); timers.push(setInterval(go, 2600));
	}
	function stopSway() { $.each(timers, function (i, t) { clearInterval(t); }); timers = []; }

	// The heading's look, from the step 2 controls.
	function look() {
		var picker = function (id, fallback) { var p = $("#" + id).data("kendoColorPicker"); return (p && p.value()) || fallback; };
		var glowOn = $("#mhwGlowOn").is(":checked");
		return {
			heading: $.trim($("#mhwHeading").val()), line: $.trim($("#mhwLine").val()), color: picker("mhwColor", "#ffffff"),
			font: $("#mhwFont").data("kendoDropDownList") ? $("#mhwFont").data("kendoDropDownList").value() : "",
			size: +$("#mhwSize").val(), sizePhone: +$("#mhwSizePhone").val(),
			shadow: $("#mhwShadow").val(), shadowColor: picker("mhwShadowColor", "#000000"),
			glowColor: glowOn ? picker("mhwGlowColor", "#ffffff") : "", glowOpacity: +$("#mhwGlowOpacity").val(), glowSoftness: +$("#mhwGlowSoftness").val()
		};
	}
	// The same as Renderer.cfc getGlowCss and galaxieScene.js: a tight core and a wider, fainter halo.
	function textShadow(l, scale) {
		var parts = [];
		if (SHADOWS[l.shadow]) { parts.push(SHADOWS[l.shadow](l.shadowColor)); }
		if (l.glowColor) {
			var a = l.glowOpacity / 100, s = l.glowSoftness;
			parts.push("0 0 " + Math.max(2, Math.round(s / 2.5)) + "px " + rgba(l.glowColor, a) + ", 0 0 " + s + "px " + rgba(l.glowColor, Math.round(a * 70) / 100));
		}
		return parts.length ? parts.join(", ").replace(/(\d+)px/g, function (m, n) { return Math.round(n * scale * 10) / 10 + "px"; }) : "none";
	}
	// The picture with the heading on it; scale is the preview's size against a post page about 1100px wide.
	function headed(box, scale) {
		var l = look(), where = (low ? "low " : "middle ") + align;
		var font = l.font ? '"' + l.font + '", sans-serif' : "";
		var text = $('<span class="mhwText"></span>').addClass(where).css({ color: l.color, textShadow: textShadow(l, scale), fontFamily: font });
		text.append($("<b></b>").text(l.heading).css("font-size", Math.round(l.size * scale) + "px"));
		if (l.line) { text.append($("<span></span>").text(l.line).css("font-size", Math.max(10, Math.round(20 * scale)) + "px")); }
		var a = art(chosen).append(text);
		box.empty().append(a);
		return a;
	}

	// Step 1: the pictures.
	function drawCards() {
		var box = $("#mhwCards").empty();
		var picks = (photo ? [{ key: "photo", name: "This post's picture (gentle zoom)" }] : []).concat(starters);
		$.each(picks, function (i, p) {
			var card = $('<button type="button" class="mhwCard" role="radio"></button>').attr("aria-checked", chosen === p.key ? "true" : "false");
			var a = art(p.key);
			card.append(a, $('<span class="mhwName"></span>').text(p.name));
			card.on("mouseenter focus", function () { move(a, 14); }).on("mouseleave blur", function () { move(a, 0); });
			card.on("click", function () {
				box.find(".mhwCard").attr("aria-checked", "false"); card.attr("aria-checked", "true");
				// A new picture brings its own shadow, until the heading step changes it.
				if (chosen !== p.key && !state.active) { var s = starterByKey(p.key); setShadow(s && s.shadow ? s.shadow : "soft"); }
				chosen = p.key; $("#mhwPickHint").hide();
			});
			card.on("dblclick", function () { wizard.go(1); });
			box.append(card);
		});
	}
	function setShadow(value) {
		var ddl = $("#mhwShadow").data("kendoDropDownList");
		if (value === "glow") { $("#mhwGlowOn").prop("checked", true); value = "none"; }
		if (ddl) { ddl.value(value); } else { $("#mhwShadow").val(value); }
	}

	// Step 2: the heading. Kendo widgets made once, filled from the post's moving hero (or the defaults for a new one).
	function initHeading() {
		$("#mhwHeading").val(state.active ? state.heading : postTitle);
		$("#mhwLine").val(state.line || "");
		if (state.fontSize) { $("#mhwSize").val(state.fontSize); }
		if (state.fontSizePhone) { $("#mhwSizePhone").val(state.fontSizePhone); }
		if (state.color) { $("#mhwColor").val(state.color); }
		if (state.shadowColor) { $("#mhwShadowColor").val(state.shadowColor); }
		if (state.glowColor) { $("#mhwGlowColor").val(state.glowColor); $("#mhwGlowOn").prop("checked", true); }
		$("#mhwGlowOpacity").val(state.glowOpacity || 80); $("#mhwGlowSoftness").val(state.glowSoftness || 24);
		$("#mhwShadow").val(state.active ? (state.shadow || "none") : "soft");
		$("#mhwColor, #mhwShadowColor, #mhwGlowColor").each(function () { $(this).kendoColorPicker({ opacity: false, buttons: false, preview: true, input: true, change: drawHeading }); });
		$("#mhwShadow").kendoDropDownList({ change: drawHeading });
		$("#mhwFont").kendoDropDownList({
			dataSource: fonts, dataTextField: "name", dataValueField: "name", optionLabel: "The picture's own",
			template: '<span style="font-family:&quot;#: data.name #&quot;">#: data.name #</span>',
			value: state.font || "", change: drawHeading
		});
		$("#mhwGlowOn").on("change", drawHeading);
		$("#mhwSize, #mhwSizePhone, #mhwGlowOpacity, #mhwGlowSoftness").on("input", drawHeading);
		$(".mhwInput").on("input", drawHeading);
	}
	function drawHeading() {
		$(".mhwGlowRow").toggle($("#mhwGlowOn").is(":checked"));
		$("#mhwSizeValue").text($("#mhwSize").val() + "px");
		$("#mhwSizePhoneValue").text($("#mhwSizePhone").val() + "px");
		$("#mhwGlowOpacityValue").text($("#mhwGlowOpacity").val() + "%");
		$("#mhwGlowSoftnessValue").text($("#mhwGlowSoftness").val() + "px");
		stopSway(); sway(headed($("#mhwHeadPreview"), 0.56));
	}

	// Step 3: where the heading sits, and the ending.
	function drawStyle() {
		stopSway(); sway(headed($("#mhwStylePreview"), 0.4));
		var box = $("#mhwPositions").empty();
		$.each(POSITIONS, function (i, pos) {
			var c = $('<button type="button" class="mhwCard" role="radio"></button>').attr("aria-checked", pos[0] === align && (pos[1] === "bottom") === low ? "true" : "false");
			c.append(art(chosen).append('<span class="mhwBars ' + (pos[1] ? "low" : "middle") + ' ' + pos[0] + '"><i></i><i></i></span>'), $('<span class="mhwName"></span>').text(pos[2]));
			c.on("click", function () { align = pos[0]; low = pos[1] === "bottom"; drawStyle(); });
			box.append(c);
		});
	}

	// Step 4: the cover. The post's own picture already serves cards and sharing; otherwise its cover, or a reminder.
	function drawCover() {
		var artBox = $("#mhwCoverArt").removeClass("mhwHas").empty();
		if (cover) {
			artBox.addClass("mhwHas").append($('<img alt="">').attr("src", cover));
			$("#mhwCoverNote").html("<p>This post has a cover picture. Cards and sharing use it.</p>");
			$("#mhwCoverUpload").html('<i class="fontAwesomeIcon fas fa-camera-retro"></i> Change the cover...');
		} else if (photo) {
			artBox.addClass("mhwHas").append($('<img alt="">').attr("src", photo));
			$("#mhwCoverNote").html("<p>Cards and sharing use this post's picture. Add a cover only if you want a different one.</p>");
		} else {
			artBox.append('<span>No cover yet</span>');
			$("#mhwCoverNote").html('<blockquote class="k-notification-warning" style="margin: 0; padding: 8px 10px;">Without a cover, a shared link shows your no-picture choice from Blog Options.</blockquote>');
		}
		// A still needs a layered picture: the post's own picture is already one.
		$("#mhwCoverStill").toggle(chosen !== "photo");
	}
	// The cover window (80) saved: read the post's cover again.
	$(document).off("galaxieHeroCoverSaved.mhw").on("galaxieHeroCoverSaved.mhw", function () {
		jQuery.getJSON(BASE + "/admin/loadPreview.cfm", { previewId: 4, optArgs: postId }, function (r) { cover = (r && r.coverUrl) || ""; drawCover(); $("#mhwCoverStatus").text(cover ? "Cover saved." : ""); });
	});
	$("#mhwCoverUpload").on("click", function () { createAdminInterfaceWindow(80, postId); });
	// A still of the chosen picture: its layers drawn on one 1600x900 canvas the way the post shows them (centered, covering the box),
	// then sent as the cover through the cover window's own upload.
	$("#mhwCoverStill").on("click", function () {
		var s = starterByKey(chosen); if (!s) { return; }
		var button = $(this).prop("disabled", true);
		$("#mhwCoverStatus").text("Making the picture...");
		var canvas = document.createElement("canvas"); canvas.width = 1600; canvas.height = 900;
		var ctx = canvas.getContext("2d");
		var loads = $.map(s.layers, function (l) {
			return new Promise(function (resolve, reject) { var img = new Image(); img.onload = function () { resolve(img); }; img.onerror = reject; img.src = withBase(l.src); });
		});
		Promise.all(loads).then(function (imgs) {
			$.each(imgs, function (i, img) {
				var w = img.naturalWidth || 1600, h = img.naturalHeight || 900, k = Math.max(1600 / w, 900 / h);
				ctx.drawImage(img, (1600 - w * k) / 2, (900 - h * k) / 2, w * k, h * k);
			});
			return new Promise(function (resolve) { canvas.toBlob(resolve, "image/jpeg", 0.9); });
		}).then(function (blob) {
			var form = new FormData();
			form.append("file", blob, (chosen || "moving-hero") + "-cover.jpg");
			return jQuery.ajax({ type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=uploadImage&mediaProcessType=heroCoverImage&mediaType=image&postId=" + postId + "&selectorId=heroCoverImageEditor&csrfToken=" + encodeURIComponent(CSRF),
				data: form, processData: false, contentType: false });
		}).then(function () {
			$(document).trigger("galaxieHeroCoverSaved");
			try { reloadEnclosureThumbnailPreview(postId); } catch (e) {}
		}, function (err) {
			if (err && err.status === 403) { createLoginWindow(); return; }
			$("#mhwCoverStatus").text("");
			$.when(kendo.ui.ExtAlertDialog.show({ title: "The still wasn't made", message: "The picture could not be saved as the cover. Please try again, or upload a picture instead.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
		}).then(function () { button.prop("disabled", false); });
	});

	// Remove the moving hero: the post goes back to its usual hero.
	$("#mhwRemove").on("click", function () {
		galaxieConfirm("Remove the moving hero?", "The post goes back to its usual hero.", function () {
			jQuery.ajax({ type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=savePostHeroParallax", dataType: "json", data: { csrfToken: CSRF, postId: postId, remove: "true" } })
			.done(function (response) {
				if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
				if (response && response.success) {
					if (typeof galaxieHeroSummaryRefresh === "function") { galaxieHeroSummaryRefresh(); }
					if (typeof window.galaxieRefreshHeroEditorPreview === "function") { window.galaxieRefreshHeroEditorPreview(); }
					stopSway();
					win.data("kendoWindow") ? win.data("kendoWindow").destroy() : win.remove();
				} else {
					$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not remove", message: (response && response.errorMessage) || "The moving hero could not be removed.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
				}
			})
			.fail(function (jqXHR, textStatus, error) {
				if (jqXHR.status === 403) { createLoginWindow(); } else { $.when(kendo.ui.ExtAlertDialog.show({ title: "Error while removing", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
			});
		});
	});

	// Finish: save it all.
	function save() {
		var l = look();
		$("#movingHeroWizard .gw-buttons .k-primary").prop("disabled", true);
		jQuery.ajax({
			type: "post", url: BASE + "/common/cfc/ProxyController.cfc?method=savePostHeroParallax", dataType: "json",
			data: { csrfToken: CSRF, postId: postId, starter: chosen, heading: l.heading, line: l.line, align: align, textPosition: low ? "bottom" : "",
				ending: $("#mhwEnding").data("kendoDropDownList").value(), textMotion: $("#mhwTextMotion").data("kendoDropDownList").value(), color: l.color, font: l.font, fontSize: l.size, fontSizePhone: l.sizePhone,
				shadow: l.shadow, shadowColor: l.shadowColor, glowColor: l.glowColor, glowOpacity: l.glowOpacity, glowSoftness: l.glowSoftness, remove: "false" }
		}).done(function (response) {
			if (typeof response === "string") { try { response = JSON.parse(response); } catch (e) {} }
			if (response && response.success) {
				if (typeof window.galaxieMovingHeroSaved === "function") { window.galaxieMovingHeroSaved({ name: pickName(), heading: l.heading, sceneId: +response.sceneId || 0 }); }
				if (typeof galaxieHeroSummaryRefresh === "function") { galaxieHeroSummaryRefresh(); }
				<!--- A video hero came off with this save (savePostHeroParallax clearedVideo), so the preview is redrawn over it. --->
				if (typeof window.galaxieRefreshHeroEditorPreview === "function") { window.galaxieRefreshHeroEditorPreview(!!response.clearedVideo); }
				stopSway();
				win.data("kendoWindow") ? win.data("kendoWindow").destroy() : win.remove();
			} else {
				$("#movingHeroWizard .gw-buttons .k-primary").prop("disabled", false);
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: (response && response.errorMessage) || "The moving hero could not be saved.", icon: "k-ext-warning", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }));
			}
		}).fail(function (jqXHR, textStatus, error) {
			$("#movingHeroWizard .gw-buttons .k-primary").prop("disabled", false);
			if (jqXHR.status === 403) { createLoginWindow(); } else { $.when(kendo.ui.ExtAlertDialog.show({ title: "Error while saving", message: error, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" })); }
		});
	}

	var wizard = $("#movingHeroWizard").galaxieWizard({
		steps: [
			{ title: "Picture", content: $("#mhwStep1"), buttons: ["next"] },
			{ title: "Heading", content: $("#mhwStep2"), buttons: ["previous", "next"] },
			{ title: "Style", content: $("#mhwStep3"), buttons: ["previous", "next"] },
			{ title: "Cover", content: $("#mhwStep4"), buttons: ["previous", { name: "done", text: "Finish" }] }
		],
		<!--- Not linear: galaxieWizard.js's linear mode also stops Next from reaching a step not reached yet (11-04, the owner's Next did
		nothing). The select event below keeps the order that matters: nothing past the picture until one is chosen. --->
		stepper: { linear: false },
		// Nothing past the first step until a picture is chosen.
		select: function (e) { if (e.step.options.index > 0 && !chosen) { e.preventDefault(); $("#mhwPickHint").show(); } },
		activate: function (e) {
			stopSway();
			var i = e.step.options.index;
			if (i === 1) { drawHeading(); } else if (i === 2) { drawStyle(); } else if (i === 3) { drawCover(); }
		},
		done: function () { save(); }
	}).data("galaxieWizard");
	$("#mhwSteps").remove();

	drawCards();
	initHeading();
	$("#mhwEnding").kendoDropDownList();
	$("#mhwEnding").data("kendoDropDownList").value(state.ending || "");
	$("#mhwTextMotion").kendoDropDownList();
	$("#mhwTextMotion").data("kendoDropDownList").value(state.textMotion || "");
	$(".mhwGlowRow").toggle($("#mhwGlowOn").is(":checked"));
	// Stop the moving previews when the window closes.
	win.closest(".k-window").find(".k-window-action").on("click", stopSway);
})();
</script>
