<cfsilent>
<!--- Self-contained live Vanta.js preview - same "own browsing context, own JS" trick preview/maps.cfm uses for
the Azure/Bing Maps SDKs. Needed because a live WebGL/canvas effect can't boot inside the admin's TinyMCE
mini-editor or the post-list/post-detail enclosure preview area: those contexts never load head.cfm/
tailEndScripts.cfm's page-level init script (see that file's own [data-animation-effect] boot code, which this page
duplicates in miniature below), so embedding this page in an <iframe> is the only way to show the real
animation instead of a static placeholder in either spot. 2026-10-01. 2026-10-03: renamed from preview/vanta.cfm/
vantaEffect/.entryVanta/data-vanta-* while still dev-only/unmigrated - the rendering library itself (Vanta.js)
is unchanged, only our own naming wrapping around it. --->
<cfparam name="URL.postId" default="">
<!--- noText=1: no heading (the Hero editor draws its own heading layer over this frame). --->
<cfparam name="URL.noText" default="0">

<cfset animationEffect = "WAVES">
<cfset animationOptionsStruct = structNew()>
<cfset overlayText = "">
<cfset overlayTextColor = "##ffffff">
<cfset overlayFont = "">
<cfset overlayFontSize = "">
<!--- The rest of the Hero text window's choices (11-03, owner: the preview had no shadow): the second line, phone size, shadow and glow. --->
<cfset heroTextMore = {}>
<cfset previewPostId = val(URL.postId)>

<cfif previewPostId gt 0>
	<cfset editingPost = entityLoadByPK("Post", previewPostId)>
	<cfif isObject(editingPost) and len(editingPost.getHeroAnimationEffect())>
		<cfset animationEffect = editingPost.getHeroAnimationEffect()>
		<cfif len(editingPost.getHeroAnimationOptions())>
			<cfset animationOptionsStruct = deserializeJson(editingPost.getHeroAnimationOptions())>
		</cfif>
		<cfif len(editingPost.getHeroOverlayText())>
			<cfset overlayText = editingPost.getHeroOverlayText()>
		</cfif>
		<cfif len(editingPost.getHeroOverlayTextColor())>
			<cfset overlayTextColor = editingPost.getHeroOverlayTextColor()>
		</cfif>
		<cfif len(editingPost.getHeroOverlayFont())>
			<cfset overlayFont = editingPost.getHeroOverlayFont()>
		</cfif>
		<cfif len(editingPost.getHeroOverlayFontSize())>
			<cfset overlayFontSize = editingPost.getHeroOverlayFontSize()>
		</cfif>
		<cfloop list="SubText,FontSizePhone,Shadow,ShadowColor,GlowColor,GlowOpacity,GlowSoftness" index="heroTextKey">
			<cfset heroTextMore["heroOverlay" & heroTextKey] = invoke(editingPost, "getHeroOverlay" & heroTextKey) ?: "">
		</cfloop>
		<cfif URL.noText eq 1><cfset overlayText = ""></cfif>
	</cfif>
</cfif>

<!--- Guard against a stale saved pick from before TOPOLOGY was dropped (see heroAnimationEditor.cfm's header
comment) - same fallback that editor already applies. --->
<cfif animationEffect eq "TOPOLOGY">
	<cfset animationEffect = "WAVES">
</cfif>

<!--- Only Vanta's TRUNK and TOPOLOGY are p5.js effects. CLOUDS is a Three.js effect (vanta.clouds.min.js reads
THREE.Color) - loading p5 for it threw "Cannot read properties of undefined (reading 'Color')". Keep in sync with
head.cfm's heroAnimationEngine. --->
<cfset usesP5 = listFindNoCase("TRUNK,TOPOLOGY", animationEffect) gt 0>

<cfobject component="#application.rendererComponentPath#" name="RendererObj">
<!--- The theme's font (2026-11-04, owner: the Edit Post Hero card showed the heading in Times New Roman). With no font of its own
from the Hero text window, the heading takes the font of the page it is on, the theme's; this frame loads no theme, so the browser
fell back to its default. The post's own theme when it has one, as on the post's page (pageSettings.cfm), else the blog's. --->
<cfset previewThemeFont = "">
<cfset previewThemeFontType = "sans-serif">
<cfset previewThemeFontCss = "">
<cftry>
	<cfset previewTheme = []>
	<cfif isDefined("editingPost") and isObject(editingPost) and val(editingPost.getThemeRef() ?: 0) gt 0>
		<cfset previewTheme = application.blog.getTheme(themeId = val(editingPost.getThemeRef()))>
	</cfif>
	<cfif not arrayLen(previewTheme)>
		<cfset previewTheme = application.blog.getTheme(themeAlias = trim(application.blog.getSelectedThemeAlias()))>
	</cfif>
	<cfif arrayLen(previewTheme)>
		<cfset previewThemeFont = previewTheme[1]["Font"] ?: "">
		<cfset previewThemeFontType = len(previewTheme[1]["FontType"] ?: "") ? previewTheme[1]["FontType"] : "sans-serif">
		<cfset previewThemeFontCss = RendererObj.getOverlayFontFaceStyle(previewThemeFont)>
	</cfif>
	<cfcatch type="any"></cfcatch>
</cftry>
<cfset animationHtml = RendererObj.renderHeroAnimationHtml(postId=previewPostId, animationEffect=animationEffect, animationOptions=animationOptionsStruct, heroOverlayText=overlayText, heroOverlayTextColor=overlayTextColor, heroOverlayFont=overlayFont, heroOverlayFontSize=overlayFontSize, cardMode=false, argumentCollection=heroTextMore)>
</cfsilent>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
<style>
	html, body {
		width: 100%;
		height: 100%;
		padding: 0;
		margin: 0;
		overflow: hidden;
	}
	.entryAnimation {
		width: 100%;
		height: 100%;
		position: relative;
	}
	.galaxieHeroText { width: 90%; }
<cfif len(previewThemeFont)>	body { font-family: <cfoutput>'#replace(replace(previewThemeFont, "'", "", "all"), '"', '', 'all')#', #reReplace(previewThemeFontType, "[^A-Za-z, -]", "", "all")#</cfoutput>; }
</cfif></style>
<cfoutput>#previewThemeFontCss#</cfoutput>
<cfoutput>
<cfif usesP5>
<script src="#application.baseUrl#/common/libs/p5/p5.min.js"></script>
<cfelse>
<script src="#application.baseUrl#/common/libs/three/three.min.js"></script>
</cfif>
<script src="#application.baseUrl#/common/libs/vanta/vanta.#lCase(animationEffect)#.min.js"></script>
</cfoutput>
</head>
<body>
<cfoutput>#animationHtml#</cfoutput>
<script>
(function() {
	var animationEl = document.querySelector('[data-animation-effect]');
	if (!animationEl) { return; }
	var effect = animationEl.getAttribute('data-animation-effect');
	var options = {};
	try { options = JSON.parse(animationEl.getAttribute('data-animation-options') || '{}'); } catch(e) {}
	var vantaOptions = {el: animationEl, mouseControls: false, touchControls: false, gyroControls: false};
	<!--- 2026-10-03: only color values (saved as "#hex" strings) need the hex-to-number conversion - speed and
	the newer per-effect numeric/boolean options are already genuine numbers/booleans from JSON.parse() above,
	so a typeof check tells them apart with no hardcoded key list to keep in sync. --->
	Object.keys(options).forEach(function(key) {
		vantaOptions[key] = (typeof options[key] === 'string') ? parseInt(options[key].replace('#', ''), 16) : options[key];
	});
	<!--- 2026-10-03: BIRDS' colorMode and CLOUDS2's texturePath never go through the saved-options pipeline
	above - see heroAnimationEditor.cfm's applyEffectSpecificVantaOptions() for why. Keep this block in sync
	with that function and tailEndScripts.cfm's own copy if either effect's handling ever changes. --->
	if (effect === 'BIRDS') {
		vantaOptions.colorMode = 'varianceGradient';
	} else if (effect === 'CLOUDS2') {
		vantaOptions.texturePath = '<cfoutput>#application.baseUrl#</cfoutput>/common/libs/vanta/noise.png';
	}
	// The heading is drawn for a post page about 1100px wide; scale it to this frame, as the Hero editor's text layer does.
	var heroText = document.querySelector('.galaxieHeroText');
	if (heroText) { heroText.style.zoom = Math.max(0.35, Math.min(1, window.innerWidth / 1100)); }
	if (window.VANTA && window.VANTA[effect]) {
		window.VANTA[effect](vantaOptions);
	}
})();
</script>
</body>
</html>
