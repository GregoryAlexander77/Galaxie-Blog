<!--- Choose Animation popup (window id 79 - see includes/templates/blogJsContent.cfm and
includes/windows/adminInterface.cfm's cfcase value=79). Picks a Vanta.js (vantajs.com) effect + its color/speed
options, with a real live Vanta canvas as the preview (unlike gradientEditor.cfm's CSS-only preview - this is
already a canvas widget, no need to fake it). Same lazy-load-on-demand discipline as the Gradient picker -
Three.js/p5.js and the effect's own file only ever load once this window actually opens, via
galaxieLoader.heroAnimationEngine() (head.cfm).

Supported effects: WAVES, NET, RINGS, CLOUDS, BIRDS, FOG, CLOUDS2, GLOBE. TOPOLOGY was in the original v1 scope
but was dropped 2026-09-30 - VANTA.TOPOLOGY() throws "TypeError: l is not a constructor" on init regardless of
which Three.js revision is vendored (tried r121 and r122, same error both times), and this matches a multi-year
history of version-compatibility bugs specific to this one effect in the vanta.js library's own GitHub issues
(not a general Three.js r125 Geometry-removal problem, which this codebase's r121 build is well under). A real
upstream bug, not something fixable from this codebase - see Image.cfc's generateAnimationDefault() for the
matching effect list. GLOBE shares NET's own point/connection engine (just wrapped around a sphere) and has the
same real-but-visually-imperceptible-without-mouse animation characteristic - not a bug, left in deliberately,
see the ANIMATION_EFFECT_PARAMS comment below and the [[vanta-net-animation-too-subtle]] memory.

Two contexts, both flowing through window.currentEnclosureEntityType same as window 77 does:
- URL.entityType eq 'blogOption': the site-wide default (BlogOption.AnimationEffect/AnimationOptions), opened
  from Blog Options' "Configure Animation Defaults" button - URL.optArgs is the blogOptionId. Submit AJAX-saves
  via ProxyController.cfc's saveBlogOptionAnimation.
- Otherwise (the default/empty entityType, same convention gradientEditor.cfm uses for its own Post/TinyMCE
  branch): a Post's own per-post override, opened from TinyMCE's own toolbar icon or Insert > Choose Animation
  (tinyMce.cfm's includeHeroAnimation, same pattern as carousel/gradient - 2026-10-01: replaced the standalone
  button this used to have, for consistency with every other media type) - URL.optArgs is the postId. Submit
  AJAX-saves via savePostHeroAnimation and sets a live preview into the still-open enclosure editor's TinyMCE
  instance - 2026-10-01: this is a real <iframe src="preview/heroAnimation.cfm?postId=..."> now, not a static
  color-swatch placeholder, since an iframe is its own browsing context and can boot the real Vanta/Three.js
  canvas even inside TinyMCE's constrained mini-editor (same trick azureMap.cfm already used for its own live
  map preview). renderMediaPreview()'s own admin-thumbnail branch (Renderer.cfc, used by
  postDetail.cfm/admin/loadPreview.cfm) embeds the exact same iframe, so the enclosure preview and the TinyMCE
  content both show the real animation, not a placeholder - the live canvas on the post's actual public page is
  still the only context with the whole page's own init script (tailEndScripts.cfm) instead of this standalone
  preview page, but all three now render the real thing. 2026-10-03: renamed from vantaEditor.cfm/vanta*
  element IDs/JS function names while still dev-only/unmigrated - the rendering library itself (Vanta.js) is
  unchanged, only our own naming wrapping around it, so this file's choice is unaffected if that library ever
  changes later (e.g. to three.js directly). --->
<cfparam name="URL.optArgs" default="">
<cfparam name="URL.entityType" default="">

<cfset isBlogOptionContext = (isDefined("URL.entityType") and URL.entityType eq 'blogOption')>
<cfset existingEffect = "WAVES">
<cfset existingOptions = {color: "##4facfe", backgroundColor: "##0f2027"}>
<cfset existingOverlayText = "">
<cfset existingOverlayTextColor = "##ffffff">
<cfset existingOverlayFont = "">
<!--- 2026-10-03: same reasoning as gradientEditor.cfm's identical variable - seeded from the real render's own
"16" fallback (Renderer.cfc), not this editor's own larger preview-box font size, which has nothing to do with
the real rendered size. --->
<cfset existingOverlayFontSize = "16">

<cfif isBlogOptionContext>
	<cfif len(application.BlogOptionDbObj.getAnimationEffect())>
		<cfset existingEffect = application.BlogOptionDbObj.getAnimationEffect()>
		<cfif len(application.BlogOptionDbObj.getAnimationOptions())>
			<cfset existingOptions = deserializeJson(application.BlogOptionDbObj.getAnimationOptions())>
		</cfif>
	</cfif>
	<!--- No overlay text/color/font for the BlogOption (site-wide default) context - same scope limit as
	gradientEditor.cfm's own Page Collection branch, out of scope for now (see the 2026-10-01 plan). --->
<cfelseif len(URL.optArgs) and val(URL.optArgs) gt 0>
	<cfset editingPost = entityLoadByPK("Post", val(URL.optArgs))>
	<cfif isObject(editingPost) and len(editingPost.getHeroAnimationEffect())>
		<cfset existingEffect = editingPost.getHeroAnimationEffect()>
		<cfif len(editingPost.getHeroAnimationOptions())>
			<cfset existingOptions = deserializeJson(editingPost.getHeroAnimationOptions())>
		</cfif>
	</cfif>
	<!--- 2026-10-01: overlay text/color/font are shared with Gradient on Post.cfc (see Post.cfc's own comment) -
	restore whatever's currently saved regardless of which hero type set it last, same as gradientEditor.cfm now
	does for its own font field. --->
	<cfif isObject(editingPost)>
		<cfif len(editingPost.getHeroOverlayText())>
			<cfset existingOverlayText = editingPost.getHeroOverlayText()>
		</cfif>
		<cfif len(editingPost.getHeroOverlayTextColor())>
			<cfset existingOverlayTextColor = editingPost.getHeroOverlayTextColor()>
		</cfif>
		<cfif len(editingPost.getHeroOverlayFont())>
			<cfset existingOverlayFont = editingPost.getHeroOverlayFont()>
		</cfif>
		<cfif len(editingPost.getHeroOverlayFontSize())>
			<cfset existingOverlayFontSize = editingPost.getHeroOverlayFontSize()>
		</cfif>
	</cfif>
</cfif>

<!--- Theme-scoped font list, same application.blog.getThemeFonts() call gradientEditor.cfm and tinyMce.cfm's own
font picker already use. themeId is already in scope here (includes/windows/adminInterface.cfm). font.cfm emits
the matching @font-face CSS so the preview can actually render the choice. Post-only, same as the fields
themselves - no point fetching this for the BlogOption context since those rows won't render. --->
<cfif not isBlogOptionContext>
	<cfinvoke component="#application.blog#" method="getThemeFonts" returnvariable="animationThemeFonts">
		<cfinvokeargument name="themeId" value="#themeId#">
		<cfinvokeargument name="selfHosted" value="1">
		<cfinvokeargument name="includeWebSafeFonts" value="1">
	</cfinvoke>
	<cfinclude template="#application.baseUrl#/includes/templates/font.cfm">
</cfif>
<!--- TOPOLOGY was dropped from the supported effect list (2026-09-30) - it throws a constructor error on init
regardless of Three.js version, a real upstream bug in the vanta.js library itself for this one effect (confirmed
against multiple Three.js revisions; multi-year history of the same class of bug in the library's own GitHub
issues). Guard against a stale saved pick from before it was dropped. --->
<cfif existingEffect eq "TOPOLOGY">
	<cfset existingEffect = "WAVES">
</cfif>

<!--- 2026-10-01: pre-select the site's own Kendo theme accent color (the k-primary button color) as the
starting swatch color instead of a generic hardcoded default, per the user's getPrimaryColorsByTheme()
function (see doc/functionToGetKendoThemeProperties and
https://www.gregoryalexander.com/blog/2024/1/16/extracting-kendo-theme-color-properties). kendoTheme is
already in scope here, set by includes/windows/adminInterface.cfm before dispatching to this window. Still
just a seed value for Pickr's setColor() below - fully editable, not locked to the theme. Has a real
cfdefaultcase for an unrecognized theme name, so this never comes back empty. --->
<cfset themeAccentColor = "##" & application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme, setting:'accentColor')>

<cfoutput>
<script>
	<!--- galaxieLoader.heroAnimationEngine() (head.cfm) loads Three.js once (shared by WAVES/NET/RINGS) or p5.js
	once (CLOUDS only), then the specific effect's own small file - same addCss/getScript/whenReady private-closure
	pattern already used for grapickPickr() (see gradientEditor.cfm's identical comment on why callers must go
	through the named method instead of calling addCss/getScript directly). --->
	var animationLibsLoaded = false;
	if ("<cfoutput>#existingEffect#</cfoutput>" === "RANDOM") { animationLibsLoaded = true; initHeroAnimationEditor(); } else galaxieLoader.heroAnimationEngine("<cfoutput>#existingEffect#</cfoutput>", function() {
		animationLibsLoaded = true;
		initHeroAnimationEditor();
	});
	setTimeout(function() {
		if (!animationLibsLoaded) {
			$('##animationPreviewWrap').html('<p style="color:##d9534f;padding:20px;">The Vanta.js/Three.js/p5.js library did not finish loading (common/libs/vanta, common/libs/three, or common/libs/p5) - the effect preview won\'t work until it does. Check the browser console\'s Network tab for the actual error (404, blocked, etc.).</p>');
		}
	}, 8000);
</script>
</cfoutput>

<style>
	#animationPreviewWrap {
		position: relative;
		width: 100%;
		height: 260px;
		border: 1px solid #ccc;
		margin-bottom: 12px;
		overflow: hidden;
		box-sizing: border-box;
	}
	<!--- Same reasoning as gradientEditor.cfm's .pcr-app override - Pickr's own popup hardcodes a z-index lower
	than this admin interface's ambient scale (head.cfm's .tox-tinymce-inline/.modal/.modal-backdrop) and a real
	Kendo Window, so without this it renders correctly but sits invisibly behind the surrounding window. --->
	.pcr-app {
		z-index: 30100 !important;
	}
	.animationSwatch {
		width: 60px;
		height: 26px;
		border: 1px solid #999;
		border-radius: 3px;
		cursor: pointer;
		display: inline-block;
	}
</style>

<table align="left" class="k-content" width="100%" cellpadding="8" cellspacing="0" border="0">
	<tr>
		<td>
			<div id="animationPreviewWrap">
				<!--- 2026-10-01: overlay text preview, positioned over wherever VANTA.{effect}() injects its own
				canvas (see refreshAnimationOverlayPreview() below) - empty/hidden by default, same "always show what
				you'll actually get" intent as refreshAnimationPreview() itself for the effect/colors. --->
				<span id="animationOverlayPreview" style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);z-index:1;font-size:16px;font-weight:bold;text-align:center;display:none;"></span>
			</div>
		</td>
	</tr>
	<tr>
		<td>
			<table align="left" class="k-content" width="100%" cellpadding="5" cellspacing="0" border="0">
				<tr>
					<td style="width: 15%">
						<label for="animationEffect">Effect:</label>
					</td>
					<td colspan="3">
						<select id="animationEffect">
							<option value="BIRDS">Birds</option>
							<option value="CLOUDS">Clouds</option>
							<option value="CLOUDS2">Clouds 2</option>
							<option value="FOG">Fog</option>
							<option value="GLOBE">Globe</option>
							<option value="NET">Net</option>
							<option value="RANDOM">Random (per post)</option>
							<option value="RINGS">Rings</option>
							<option value="WAVES">Waves</option>
						</select>
					</td>
				</tr>
				<tr id="animationSwatchRow1">
					<td style="width: 15%">
						<label id="animationSwatchLabel1" for="animationSwatch1">Color:</label>
					</td>
					<td colspan="3">
						<div class="animationSwatch" id="animationSwatch1"></div>
					</td>
				</tr>
				<tr id="animationSwatchRow2">
					<td style="width: 15%">
						<label id="animationSwatchLabel2" for="animationSwatch2">Background:</label>
					</td>
					<td colspan="3">
						<div class="animationSwatch" id="animationSwatch2"></div>
					</td>
				</tr>
				<!--- 2026-10-03: expanded from 3 to 7 swatch slots to fit CLOUDS' real option set (background +
				sky/cloud/cloudShadow/sun/sunGlare/sunlight) - confirmed against both the vendored vanta.clouds.min.js
				source and the live vantajs.com customizer, replacing the old 3-swatch guess (sky/cloud/sun) that
				turned out to be the wrong key names entirely (this build never read them). Same "created once,
				never recreated, just re-colored/re-labeled/shown-or-hidden" approach as before, just more slots. --->
				<cfloop from="3" to="7" index="animationSwatchLoopIndex">
				<tr id="animationSwatchRow<cfoutput>#animationSwatchLoopIndex#</cfoutput>" style="display:none;">
					<td style="width: 15%">
						<label id="animationSwatchLabel<cfoutput>#animationSwatchLoopIndex#</cfoutput>" for="animationSwatch<cfoutput>#animationSwatchLoopIndex#</cfoutput>">Color:</label>
					</td>
					<td colspan="3">
						<div class="animationSwatch" id="animationSwatch<cfoutput>#animationSwatchLoopIndex#</cfoutput>"></div>
					</td>
				</tr>
				</cfloop>
				<tr>
					<td style="width: 15%">
						<label for="animationSpeed">Speed:</label>
					</td>
					<td colspan="3">
						<input type="range" id="animationSpeed" min="0.3" max="3" step="0.1" value="1" style="width: 100%;">
					</td>
				</tr>
				<!--- 2026-10-03: generic numeric-slider slots, same "created once, shown/hidden/relabeled per
				effect" approach as the color swatches - WAVES needs 4 (shininess/waveHeight/waveSpeed/zoom), NET
				needs 3 (points/maxDistance/spacing), BIRDS needs 7 (the most of any effect -
				birdSize/wingSpan/speedLimit/separation/alignment/cohesion/quantity), which sets this loop's upper
				bound. Ranges are plain guesses around each effect's own default (the live customizer doesn't expose
				min/max, only a default value), generous enough to give real room to adjust without being unusable. --->
				<cfloop from="1" to="7" index="animationNumLoopIndex">
				<tr id="animationNumRow<cfoutput>#animationNumLoopIndex#</cfoutput>" style="display:none;">
					<td style="width: 15%">
						<label id="animationNumLabel<cfoutput>#animationNumLoopIndex#</cfoutput>" for="animationNum<cfoutput>#animationNumLoopIndex#</cfoutput>">Value:</label>
					</td>
					<td colspan="3">
						<input type="range" id="animationNum<cfoutput>#animationNumLoopIndex#</cfoutput>" style="width:80%;">
						<span id="animationNumReadout<cfoutput>#animationNumLoopIndex#</cfoutput>" style="display:inline-block;width:50px;text-align:right;"></span>
					</td>
				</tr>
				</cfloop>
				<!--- NET's showDots is the only boolean option any effect here has - a single reusable checkbox
				slot, same shown/hidden-per-effect idiom as everything else above. --->
				<tr id="animationBoolRow1" style="display:none;">
					<td style="width: 15%">
						<label id="animationBoolLabel1" for="animationBool1">Show Dots:</label>
					</td>
					<td colspan="3">
						<input type="checkbox" id="animationBool1">
					</td>
				</tr>
				<!--- 2026-10-01: overlay text/color/font, new for the animation hero type - mirrors gradientEditor.cfm's own fields
				exactly (same shared Post.cfc columns, see that file's and Post.cfc's own comments). Post-only,
				same as the font list fetch above. --->
				<cfif not isBlogOptionContext>
				<tr>
					<td style="width: 15%">
						<label for="animationOverlayText">Overlay Text:</label>
					</td>
					<td colspan="3">
						<input type="text" id="animationOverlayText" class="k-textbox" placeholder="Optional overlay text" style="width:100%;box-sizing:border-box;" value="<cfoutput>#encodeForHTMLAttribute(existingOverlayText)#</cfoutput>">
					</td>
				</tr>
				<tr>
					<td style="width: 15%">
						<label for="animationOverlayTextColor">Text Color:</label>
					</td>
					<td colspan="3">
						<script>
							$("#animationOverlayTextColor").kendoColorPicker({
								input: false,
								preview: false,
								value: "<cfoutput>#existingOverlayTextColor#</cfoutput>",
								buttons: false,
								views: ["gradient"]
							});
						</script>
						<input id="animationOverlayTextColor" name="animationOverlayTextColor">
					</td>
				</tr>
				<tr>
					<td style="width: 15%">
						<label for="animationOverlayFont">Text Font:</label>
					</td>
					<td colspan="3">
						<select id="animationOverlayFont" style="width: 60%"></select>
					</td>
				</tr>
				<!--- 2026-10-03: same plain range-input convention this file's own Speed slider already uses -
				no Kendo widget needed (kendoTextBox isn't part of Kendo Core, confirmed earlier tonight). --->
				<tr>
					<td style="width: 15%">
						<label for="animationOverlayFontSize">Text Size:</label>
					</td>
					<td colspan="3">
						<input type="range" id="animationOverlayFontSize" min="12" max="72" step="1" value="<cfoutput>#existingOverlayFontSize#</cfoutput>" style="width:80%;">
						<span id="animationOverlayFontSizeReadout" style="display:inline-block;width:40px;text-align:right;"><cfoutput>#existingOverlayFontSize#</cfoutput>px</span>
					</td>
				</tr>
				</cfif>
			</table>
		</td>
	</tr>
	<tr valign="middle" height="30px">
		<td valign="bottom" align="right">
			<button id="animationCancelButton" class="k-button normalFontWeight" type="button" onclick="javascript:$('#heroAnimationEditorWindow').kendoWindow('destroy');">Cancel</button>
			<button id="animationSubmitButton" class="k-button k-primary" type="button" onclick="javascript:onHeroAnimationEditorSubmit();">Submit</button>
		</td>
	</tr>
</table>

<script>
	<!--- 2026-10-03: every list below was verified against BOTH the vendored vanta.*.min.js source (grepped for
	real this.options.X reads, including destructured access the first pass missed) AND the live vantajs.com
	customizer panel, after an earlier guess (CLOUDS: sky/cloud/sun; RINGS: a "color" swatch) turned out wrong on
	both counts - CLOUDS' real option set is completely different (7 colors, not 3, and different names), and
	RINGS has no settable color at all (its own live demo confirms this - it only offers a "Randomize!" button,
	since VANTA.RINGS() procedurally generates its own ring colors internally). TOPOLOGY was dropped 2026-09-30
	(see this file's header comment) - a real upstream vanta.js bug, not something fixable here. BIRDS, FOG,
	CLOUDS2 and GLOBE added 2026-10-03, same verification method. BIRDS also has a "colorMode" option (controls
	how color1/color2 blend) - it's a string enum, not a color, so it isn't listed as a swatch here; it's
	hardcoded to vantajs.com's own default ("varianceGradient") wherever VANTA.BIRDS() is actually called, kept
	out of the saved options JSON entirely so it can't collide with the generic hex-color parsing every render
	call site does on every other saved option. GLOBE shares NET's own point/connection engine (just wrapped
	around a sphere) and has the same real-but-visually-imperceptible-without-mouse animation - see
	[[vanta-net-animation-too-subtle]] memory, left in deliberately per the user, same tradeoff as NET. --->
	var ANIMATION_EFFECT_PARAMS = {
		WAVES:  [{key: "color", label: "Wave Color"}],
		NET:    [{key: "color", label: "Line Color"}, {key: "backgroundColor", label: "Background"}],
		RINGS:  [{key: "backgroundColor", label: "Background"}],
		CLOUDS: [
			{key: "backgroundColor", label: "Background"},
			{key: "skyColor", label: "Sky"},
			{key: "cloudColor", label: "Cloud"},
			{key: "cloudShadowColor", label: "Cloud Shadow"},
			{key: "sunColor", label: "Sun"},
			{key: "sunGlareColor", label: "Sun Glare"},
			{key: "sunlightColor", label: "Sunlight"}
		],
		BIRDS: [
			{key: "color1", label: "Bird Color 1"},
			{key: "color2", label: "Bird Color 2"},
			{key: "backgroundColor", label: "Background"}
		],
		FOG: [
			{key: "baseColor", label: "Base"},
			{key: "highlightColor", label: "Highlight"},
			{key: "lowlightColor", label: "Lowlight"},
			{key: "midtoneColor", label: "Midtone"}
		],
		CLOUDS2: [
			{key: "cloudColor", label: "Cloud"},
			{key: "lightColor", label: "Light"},
			{key: "skyColor", label: "Sky"},
			{key: "backgroundColor", label: "Background"}
		],
		GLOBE: [
			{key: "color", label: "Dot Color"},
			{key: "color2", label: "Line Color"},
			{key: "backgroundColor", label: "Background"}
		]
	};

	<!--- Not a color - WAVES' own backgroundColor swatch was removed (confirmed empirically: the user tested a
	drastically different background color and saw zero change anywhere on the canvas, not even at the edges -
	matches the official customizer, which doesn't expose a background control for WAVES at all). Shininess/
	waveHeight/waveSpeed/zoom ARE real, confirmed-present WAVES options (this.options.shininess etc., all found
	in the vendored source) that simply never had UI built for them before now. Ranges are reasonable guesses
	around each effect's own live-customizer default - that panel doesn't expose min/max, only a starting value. --->
	var ANIMATION_EFFECT_NUMERIC_PARAMS = {
		WAVES: [
			{key: "shininess", label: "Shininess", min: 0, max: 150, step: 1, default: 30},
			{key: "waveHeight", label: "Wave Height", min: 0, max: 50, step: 1, default: 15},
			{key: "waveSpeed", label: "Wave Speed", min: 0, max: 3, step: 0.1, default: 1},
			{key: "zoom", label: "Zoom", min: 0.1, max: 2, step: 0.05, default: 1}
		],
		NET: [
			{key: "points", label: "Points", min: 1, max: 30, step: 1, default: 10},
			{key: "maxDistance", label: "Max Distance", min: 1, max: 50, step: 1, default: 20},
			{key: "spacing", label: "Spacing", min: 1, max: 50, step: 1, default: 15}
		],
		BIRDS: [
			{key: "quantity", label: "Quantity", min: 1, max: 10, step: 1, default: 5},
			{key: "birdSize", label: "Bird Size", min: 0.1, max: 3, step: 0.1, default: 1},
			{key: "wingSpan", label: "Wing Span", min: 5, max: 60, step: 1, default: 30},
			{key: "speedLimit", label: "Speed Limit", min: 1, max: 15, step: 1, default: 5},
			{key: "separation", label: "Separation", min: 1, max: 50, step: 1, default: 20},
			{key: "alignment", label: "Alignment", min: 1, max: 50, step: 1, default: 20},
			{key: "cohesion", label: "Cohesion", min: 1, max: 50, step: 1, default: 20}
		],
		FOG: [
			{key: "blurFactor", label: "Blur Factor", min: 0.1, max: 1, step: 0.05, default: 0.6},
			{key: "zoom", label: "Zoom", min: 0.1, max: 3, step: 0.1, default: 1}
		],
		GLOBE: [
			{key: "points", label: "Points", min: 1, max: 30, step: 1, default: 10},
			{key: "maxDistance", label: "Max Distance", min: 1, max: 50, step: 1, default: 20},
			{key: "spacing", label: "Spacing", min: 1, max: 50, step: 1, default: 15},
			{key: "size", label: "Size", min: 0.1, max: 3, step: 0.1, default: 1}
		]
	};

	<!--- showDots (NET, GLOBE) is the only boolean option across every effect. --->
	var ANIMATION_EFFECT_BOOL_PARAMS = {
		NET: [{key: "showDots", label: "Show Dots", default: true}],
		GLOBE: [{key: "showDots", label: "Show Dots", default: true}]
	};

	<!--- 2026-10-03: real per-effect defaults, read straight off vantajs.com's own demo widgets
	(window.VANTA.current.options there) rather than the site's Kendo theme accent color - the user's
	original instruction to seed from the theme's k-primary color doesn't hold for every effect/swatch, so
	every color param now gets its own correct, effect-specific starting value instead of one color reused
	everywhere. CLOUDS' values here already matched Image.cfc's generateAnimationDefault() palette. RINGS'
	live customizer also exposes a generic "color" in its options object, but that's Vanta's shared base-class
	default, not something RINGS itself reads (confirmed via the vendored source) - omitted here, same as its
	removed swatch. --->
	var ANIMATION_EFFECT_COLOR_DEFAULTS = {
		WAVES:  {color: "#005588"},
		NET:    {color: "#ff3f81", backgroundColor: "#23153c"},
		RINGS:  {backgroundColor: "#202428"},
		CLOUDS: {
			backgroundColor: "#ffffff",
			skyColor: "#68b8d7",
			cloudColor: "#adc1de",
			cloudShadowColor: "#183550",
			sunColor: "#ff9919",
			sunGlareColor: "#ff6633",
			sunlightColor: "#ff9933"
		},
		BIRDS: {color1: "#ff0000", color2: "#00d1ff", backgroundColor: "#07192f"},
		FOG: {
			baseColor: "#ffebeb",
			highlightColor: "#ffc300",
			lowlightColor: "#2d00ff",
			midtoneColor: "#ff1f00"
		},
		CLOUDS2: {cloudColor: "#334d80", lightColor: "#ffffff", skyColor: "#5ca6ca", backgroundColor: "#000000"},
		GLOBE: {color: "#ff3f81", color2: "#ffffff", backgroundColor: "#23153c"}
	};

	var existingOptions = <cfoutput>#serializeJson(existingOptions)#</cfoutput>;
	<!--- Last-resort fallback only - every color param above now has its own real default, so this should
	never actually be reached in practice. --->
	var themeAccentColor = "<cfoutput>#themeAccentColor#</cfoutput>";
	var animationSwatchPickrs = [null, null, null, null, null, null, null];
	var liveAnimationEffect = null;

	function hexToNumber(hex) {
		return parseInt(String(hex).replace("#", ""), 16);
	}

	<!--- Reads whichever color/numeric/boolean rows are currently shown for the selected effect into a plain
	options object (colors as raw "#hex" strings, same as before - refreshAnimationPreview() below is what
	converts them to numbers, since the saved JSON itself should stay human-readable hex), plus the shared speed
	slider every effect has. --->
	function collectAnimationOptions() {
		var effect = $("#animationEffect").val();
		var colorParams = ANIMATION_EFFECT_PARAMS[effect] || [];
		var numericParams = ANIMATION_EFFECT_NUMERIC_PARAMS[effect] || [];
		var boolParams = ANIMATION_EFFECT_BOOL_PARAMS[effect] || [];
		var options = {speed: parseFloat($("#animationSpeed").val())};
		colorParams.forEach(function(p, i) {
			if (animationSwatchPickrs[i]) {
				options[p.key] = animationSwatchPickrs[i].getColor().toHEXA().toString();
			}
		});
		numericParams.forEach(function(p, i) {
			options[p.key] = parseFloat($("#animationNum" + (i + 1)).val());
		});
		boolParams.forEach(function(p, i) {
			options[p.key] = $("#animationBool" + (i + 1)).is(":checked");
		});
		return options;
	}

	<!--- 2026-10-03: two effect-specific options that deliberately never go through the generic
	options-object/saved-JSON pipeline every other option uses, applied directly onto vantaOptions right before
	the VANTA[effect](...) call instead:
	- BIRDS' colorMode controls how color1/color2 blend (a string enum, e.g. "varianceGradient") - not a color
	  itself, not user-editable here, hardcoded to vantajs.com's own default. If this were included in
	  collectAnimationOptions()'s output it would get saved into HeroAnimationOptions JSON and then wrongly
	  run through every render call site's generic typeof-string-means-hex-color parsing, corrupting it.
	- CLOUDS2's texturePath defaults (inside the vendored file itself) to a relative "./gallery/noise.png" that
	  resolves against whatever page happens to be loading it - never a real path on this site. The npm
	  package doesn't even ship that file; it was fetched straight from vantajs.com's own site and vendored
	  here. Always overridden to an absolute, real URL.
	Same two special cases are duplicated in preview/heroAnimation.cfm's and tailEndScripts.cfm's own copies of
	this call - keep all three in sync if either effect's handling ever changes. --->
	function applyEffectSpecificVantaOptions(effect, vantaOptions) {
		if (effect === "BIRDS") {
			vantaOptions.colorMode = "varianceGradient";
		} else if (effect === "CLOUDS2") {
			vantaOptions.texturePath = "<cfoutput>#application.baseUrl#</cfoutput>/common/libs/vanta/noise.png";
		}
	}

	<!--- Destroys and re-creates the live preview canvas with the current effect + option selections - called on
	effect change, swatch color change, and speed change, same "always show what you'll actually get" intent as
	gradientEditor.cfm's refreshGradientPreview(), just with a real canvas instead of a CSS background. Only
	color values need the hex-to-number conversion - collectAnimationOptions() returns colors as "#hex" strings
	and everything else (speed, the new numeric sliders, showDots) as genuine numbers/booleans, so a plain
	typeof check tells them apart with no effect-specific key list needed - same convention
	tailEndScripts.cfm's and preview/heroAnimation.cfm's own copies of this logic now use too, 2026-10-03. --->
	function refreshAnimationPreview() {
		if ($("#animationEffect").val() === "RANDOM") { $("#animationPreviewWrap").html('<p style="padding:20px;">A random Vanta effect is picked for each post.</p>'); return; }
		if (!window.VANTA) { return; }
		var effect = $("#animationEffect").val();
		var options = collectAnimationOptions();
		var vantaOptions = {el: "#animationPreviewWrap", mouseControls: false, touchControls: false, gyroControls: false};
		Object.keys(options).forEach(function(key) {
			vantaOptions[key] = (typeof options[key] === "string") ? hexToNumber(options[key]) : options[key];
		});
		applyEffectSpecificVantaOptions(effect, vantaOptions);
		if (liveAnimationEffect) {
			try { liveAnimationEffect.destroy(); } catch(e) {}
		}
		if (window.VANTA[effect]) {
			liveAnimationEffect = VANTA[effect](vantaOptions);
		}
	}

	<!--- 2026-10-01: updates the overlay text preview sitting on top of the live canvas - separate from
	refreshAnimationPreview() above since this doesn't touch the canvas at all, just the sibling <span>. Guarded
	element lookups since this file renders the overlay fields at all (BlogOption context has none - see the
	cfif around them). --->
	function refreshAnimationOverlayPreview() {
		var span = $("#animationOverlayPreview");
		if (!span.length) { return; }
		var text = $("#animationOverlayText").val() || "";
		if (!text.length) { span.hide(); return; }
		var color = $("#animationOverlayTextColor").val() || "#ffffff";
		if (color.charAt(0) !== "#") { color = "#" + color; }
		var font = $("#animationOverlayFont").val() || "";
		var fontSize = $("#animationOverlayFontSize").val() || "16";
		span.css({
			color: color,
			fontFamily: font ? ('"' + font + '"') : "inherit",
			fontSize: fontSize + "px"
		}).text(text).show();
	}

	<!--- Shows/hides and relabels the color/numeric/boolean rows for whichever effect is selected, seeding each
	control's value from existingOptions on first load (re-opening this editor on an existing pick) or each
	param's own documented default otherwise - same "controls created once, never recreated, just re-valued/
	re-labeled/shown-or-hidden" approach gradientEditor.cfm settled on for its own single swatch, after finding
	that recreating a Pickr instance on every change was unstable (see that file's own comment on the per-handle
	Pickr approach it replaced), now generalized to numeric sliders and a checkbox too. --->
	function applyEffectParams() {
		var effect = $("#animationEffect").val();
		var colorParams = ANIMATION_EFFECT_PARAMS[effect] || [];
		var numericParams = ANIMATION_EFFECT_NUMERIC_PARAMS[effect] || [];
		var boolParams = ANIMATION_EFFECT_BOOL_PARAMS[effect] || [];
		for (var i = 0; i < animationSwatchPickrs.length; i++) {
			var row = $("#animationSwatchRow" + (i + 1));
			if (i < colorParams.length) {
				row.show();
				$("#animationSwatchLabel" + (i + 1)).text(colorParams[i].label + ":");
				var effectDefaults = ANIMATION_EFFECT_COLOR_DEFAULTS[effect] || {};
				var seedColor = existingOptions[colorParams[i].key] || effectDefaults[colorParams[i].key] || themeAccentColor;
				if (animationSwatchPickrs[i]) { animationSwatchPickrs[i].setColor(seedColor); }
			} else {
				row.hide();
			}
		}
		for (var n = 0; n < 7; n++) {
			var numRow = $("#animationNumRow" + (n + 1));
			if (n < numericParams.length) {
				var p = numericParams[n];
				var seedValue = (typeof existingOptions[p.key] !== "undefined") ? existingOptions[p.key] : p.default;
				numRow.show();
				$("#animationNumLabel" + (n + 1)).text(p.label + ":");
				$("#animationNum" + (n + 1)).attr({min: p.min, max: p.max, step: p.step}).val(seedValue);
				$("#animationNumReadout" + (n + 1)).text(seedValue);
			} else {
				numRow.hide();
			}
		}
		var boolRow = $("#animationBoolRow1");
		if (boolParams.length) {
			var bp = boolParams[0];
			var seedChecked = (typeof existingOptions[bp.key] !== "undefined") ? existingOptions[bp.key] : bp.default;
			boolRow.show();
			$("#animationBoolLabel1").text(bp.label + ":");
			$("#animationBool1").prop("checked", !!seedChecked);
		} else {
			boolRow.hide();
		}
		<!--- Switching the dropdown to an effect that hasn't loaded yet this session (eg. the admin opened this
		editor on a WAVES pick and then tries NET) needs its own engine/effect file fetched before the preview can
		actually render it - the window-open load only ever covers the initial effect. galaxieLoader.heroAnimationEngine()
		is itself a no-op re-fetch for anything already loaded (same whenReady() caching every other lazy-loaded
		library here uses), so calling it again on every switch is cheap. --->
		if (effect === "RANDOM") { refreshAnimationPreview(); return; }
		galaxieLoader.heroAnimationEngine(effect, refreshAnimationPreview);
	}

	function initHeroAnimationEditor() {
		for (var i = 0; i < animationSwatchPickrs.length; i++) {
			(function(index) {
				animationSwatchPickrs[index] = Pickr.create({
					el: "#animationSwatch" + (index + 1),
					theme: "classic",
					default: (index === 0 ? themeAccentColor : "#4facfe"),
					comparison: false,
					position: "bottom-middle",
					components: {
						preview: true,
						opacity: false,
						hue: true,
						interaction: { hex: true, rgba: false, input: true, clear: false, save: true }
					}
				});
				animationSwatchPickrs[index].on("change", refreshAnimationPreview).on("save", function(color, instance) {
					instance.hide();
					refreshAnimationPreview();
				});
			})(i);
		}

		$("#animationEffect").val("<cfoutput>#existingEffect#</cfoutput>").kendoDropDownList({
			change: applyEffectParams
		}).data("kendoDropDownList").wrapper.css("width", "60%");

		$("#animationSpeed").val(existingOptions.speed || 1).on("input", refreshAnimationPreview);

		<!--- 2026-10-03: generic numeric-slider/checkbox bindings - same live-refresh-on-input idiom as the
		Speed slider above, reused for whichever of the 4 numeric slots or 1 boolean slot the current effect is
		using (applyEffectParams() shows/hides/relabels them). The readout span just mirrors the slider's own
		raw value, no unit suffix (unlike Text Size's "px") since these are plain numbers (point counts,
		distances, multipliers) with no single shared unit. --->
		for (var numIndex = 1; numIndex <= 7; numIndex++) {
			(function(n) {
				$("#animationNum" + n).on("input", function() {
					$("#animationNumReadout" + n).text(this.value);
					refreshAnimationPreview();
				});
			})(numIndex);
		}
		$("#animationBool1").on("change", refreshAnimationPreview);

		<!--- 2026-10-01: overlay text/color/font - guarded since these rows don't exist at all in the
		BlogOption context (see the cfif around them above). Kendo ColorPicker's own change/select events don't
		fire reliably on every edit (same reasoning gradientEditor.cfm's submit-time reads already work around),
		so poll via 'input' on the hidden bound field like the speed slider does, plus the picker's own explicit
		events as a belt-and-suspenders. --->
		if ($("#animationOverlayText").length) {
			$("#animationOverlayText").on("input", refreshAnimationOverlayPreview);
			$("#animationOverlayTextColor").on("input change", refreshAnimationOverlayPreview);
			<!--- 2026-10-03: the JS-side $("#animationOverlayText").length check above only gates what the
			BROWSER runs - it does nothing to stop ColdFusion itself from trying to evaluate
			#serializeJson(animationThemeFonts)# at template-render time, since CFML has no awareness of
			JavaScript's own runtime conditions. animationThemeFonts is only ever defined in the Post context
			(see the <cfif not isBlogOptionContext> near the top of this file) - evaluating it unconditionally
			here threw "Variable ANIMATIONTHEMEFONTS is undefined" on every single load of the BlogOption
			context ("Configure Animation Defaults"), before this fix. A real CFML-side guard, not just the JS
			one, is required to actually skip the <cfoutput> below in that context. --->
			<cfif not isBlogOptionContext>
			<!--- 2026-10-03: shows each font rendered in its own face while browsing the list - same
			kendo.data.DataSource + template pattern themeSettings.cfm's own bodyFontDropdown (and now
			gradientEditor.cfm's identical field) use. Local inline data since animationThemeFonts is already
			the exact theme-scoped, self-hosted+web-safe list this field needs. --->
			var animationFontDs = new kendo.data.DataSource({
				data: <cfoutput>#serializeJson(animationThemeFonts)#</cfoutput>
			});
			var animationFontDropdown = $("#animationOverlayFont").kendoDropDownList({
				dataTextField: "Font",
				dataValueField: "Font",
				dataSource: animationFontDs,
				optionLabel: "Default",
				template: '<label style="font-family:\'#:data.FontFace#\'">#:data.Font#</label>',
				change: refreshAnimationOverlayPreview
			}).data("kendoDropDownList");
			if (animationFontDropdown) {
				animationFontDropdown.wrapper.css("width", "60%");
				animationFontDropdown.value("<cfoutput>#existingOverlayFont#</cfoutput>");
			}
			</cfif>
			$("#animationOverlayFontSize").on("input", function() {
				$("#animationOverlayFontSizeReadout").text(this.value + "px");
				refreshAnimationOverlayPreview();
			});
			refreshAnimationOverlayPreview();
		}

		applyEffectParams();
	}

	function onHeroAnimationEditorSubmit() {
		var effect = $("#animationEffect").val();
		var options = collectAnimationOptions();
		var optionsJson = JSON.stringify(options);

		<cfif isBlogOptionContext>
			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=saveBlogOptionAnimation",
				data: {
					csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
					blogOptionId: <cfoutput>#URL.optArgs#</cfoutput>,
					animationEffect: effect,
					animationOptions: optionsJson
				},
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						if (liveAnimationEffect) { try { liveAnimationEffect.destroy(); } catch(e) {} }
						$('#heroAnimationEditorWindow').kendoWindow('destroy');
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		<cfelse>
			<!--- 2026-10-01: shared with Gradient on Post.cfc (see that file's and Post.cfc's own comments) -
			read the same way gradientEditor.cfm's submit does. --->
			var overlayText = $("#animationOverlayText").val() || "";
			var overlayTextColor = $("#animationOverlayTextColor").val() || "#ffffff";
			if (overlayTextColor.charAt(0) !== "#") { overlayTextColor = "#" + overlayTextColor; }
			var overlayFont = $("#animationOverlayFont").val() || "";
			var overlayFontSize = $("#animationOverlayFontSize").val() || "";

			jQuery.ajax({
				type: "post",
				url: "<cfoutput>#application.baseUrl#</cfoutput>/common/cfc/ProxyController.cfc?method=savePostHeroAnimation",
				data: {
					csrfToken: "<cfoutput>#csrfToken#</cfoutput>",
					postId: <cfoutput>#URL.optArgs#</cfoutput>,
					animationEffect: effect,
					animationOptions: optionsJson,
					heroOverlayText: overlayText,
					heroOverlayTextColor: overlayTextColor,
					heroOverlayFont: overlayFont,
					heroOverlayFontSize: overlayFontSize
				},
				dataType: "json",
				success: function(response) {
					if (JSON.parse(response.success) == true) {
						<!--- 2026-10-01: a live iframe pointing at preview/heroAnimation.cfm, not a static color-swatch placeholder - a
						real iframe is its own browsing context, so it can boot the actual Vanta/Three.js canvas even
						inside TinyMCE's own constrained mini-editor, same trick azureMap.cfm already uses
						(preview/maps.cfm) for its own live map preview. Reads the just-saved postId/effect/options/
						overlay straight back from the DB rather than rebuilding them client-side, so this always
						matches exactly what savePostHeroAnimation just persisted. --->
						<!--- 2026-10-04: bumped from 235x130, same reasoning/kept in sync with
						enclosureImageEditor.cfm's own reopen-fallback copy of this iframe string. --->
						var animationIframeHtml = '<iframe data-type="animation" data-id="<cfoutput>#URL.optArgs#</cfoutput>" src="<cfoutput>#application.baseUrl#</cfoutput>/preview/heroAnimation.cfm?postId=<cfoutput>#URL.optArgs#</cfoutput>" width="470" height="260" style="border:0;" scrolling="no"></iframe>';
						try { tinymce.activeEditor.setContent(animationIframeHtml); } catch(e) {}
						try { enclosureUppy.cancelAll(); } catch(e) {}
						try { reloadEnclosureThumbnailPreview(<cfoutput>#URL.optArgs#</cfoutput>); } catch(e) {}
						if (liveAnimationEffect) { try { liveAnimationEffect.destroy(); } catch(e) {} }
						$('#heroAnimationEditorWindow').kendoWindow('destroy');
					} else {
						$.when(kendo.ui.ExtAlertDialog.show({ title: "Could not save", message: response.errorMessage, icon: "k-ext-warning" }));
					}
				}
			});
		</cfif>
	}
</script>
