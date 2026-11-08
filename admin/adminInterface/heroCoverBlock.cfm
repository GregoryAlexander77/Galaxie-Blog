<!--- The Edit Post window's Hero row (11-02, owner: one preview with a "Change hero" button showed the cover, which was confusing).
The hero (what is at the top of the post) and the cover (the picture for cards, Facebook, X and Pinterest) side by side, the same
size, each with its own button; on a narrow window they stack. Included by postDetail.cfm inside #mediaPreview, and by
admin/loadPreview.cfm (previewId=1), which reloadEnclosureThumbnailPreview() calls after any hero or cover window saves.
Needs getPost (getPostByPostId), RendererObj and kendoTheme. Mock-up: test page heroCoverMock.html (owner OK 11-02). --->
<cfsilent>
<cfset hcPost = getPost[1]>
<cfset hcPostId = hcPost["PostId"]>
<!--- What the hero is, and which picture cards and sharing use, from Hero.cfc (2026-11-06, the hero pipeline: this row, the Hero
window, the cards and sharing all give the same answer). This template only draws it. --->
<cfset hcHero = application.blog.getHeroes().getAdminHero(hcPost)>
<cfset hcSceneId = hcHero.sceneId>
<cfset hcSceneName = hcHero.sceneName>
<cfset hcIsFullScene = hcHero.kind eq "scene">
<cfset hcCoverUrl = hcHero.coverUrl>
<cfset hcCoverUnused = hcHero.cover.unused>
<cfset hcCoverState = hcHero.cover.state>

<!--- The hero side. --->
<cfif hcSceneId gt 0>
	<cfif len(hcHero.sceneArt)>
		<cfset hcHeroHtml = '<div class="hcLayers">' & hcHero.sceneArt & '</div>'>
	<cfelse>
		<cfset hcHeroHtml = '<div class="hcPlaceholder k-alt"><i class="fontAwesomeIcon fas fa-layer-group"></i><span>' & encodeForHtml(hcSceneName) & '</span></div>'>
	</cfif>
<cfelseif hcHero.kind eq "picture">
	<!--- The hero text on the picture, as on the post page (11-06, owner: the text didn't show here after saving it). A gradient's and an
	animation's previews (renderMediaPreview below) already draw their own. --->
	<cfset hcText = RendererObj.getHeroTextHtml(text = hcPost["HeroOverlayText"] ?: "", subText = hcPost["HeroOverlaySubText"] ?: "",
		color = hcPost["HeroOverlayTextColor"] ?: "", font = hcPost["HeroOverlayFont"] ?: "", size = hcPost["HeroOverlayFontSize"] ?: "",
		sizePhone = hcPost["HeroOverlayFontSizePhone"] ?: "", shadow = hcPost["HeroOverlayShadow"] ?: "", shadowColor = hcPost["HeroOverlayShadowColor"] ?: "",
		glowColor = hcPost["HeroOverlayGlowColor"] ?: "", glowOpacity = hcPost["HeroOverlayGlowOpacity"] ?: "", glowSoftness = hcPost["HeroOverlayGlowSoftness"] ?: "",
		positioned = true)>
	<cfset hcHeroHtml = '<div><img src="' & encodeForHtmlAttribute(hcHero.heroPictureUrl) & '" alt="" style="width: 100%; height: 100%; object-fit: cover; display: block;">' & hcText & '</div>'>
<cfelseif hcHero.kind neq "none">
	<cfset hcHeroHtml = RendererObj.renderMediaPreview(kendoTheme = kendoTheme, getPost = getPost, renderThumbnail = true, includeCover = false)>
<cfelse>
	<cfset hcHeroHtml = '<div class="hcEmpty"><i class="fontAwesomeIcon fas fa-image"></i><span>No hero yet. The post starts with its title.</span></div>'>
</cfif>

<!--- The cover side. --->
<cfif hcCoverUnused>
	<cfset hcCoverHtml = '<img src="' & encodeForHtmlAttribute(hcCoverUrl) & '" alt="" style="opacity: .55;"><span class="hcUses k-content">' & encodeForHtml(hcHero.cover.unusedReason) & '</span>'>
	<cfset hcCoverButton = "Change cover">
<cfelseif len(hcCoverUrl)>
	<cfset hcCoverHtml = '<img src="' & encodeForHtmlAttribute(hcCoverUrl) & '" alt="">'>
	<cfset hcCoverButton = "Change cover">
<cfelseif len(hcHero.cover.usesUrl)>
	<cfset hcCoverHtml = '<img src="' & encodeForHtmlAttribute(hcHero.cover.usesUrl) & '" alt=""><span class="hcUses k-content">' & encodeForHtml(hcHero.cover.usesLabel) & '</span>'>
	<cfset hcCoverButton = "Use a different cover">
<cfelseif hcHero.cover.state eq "in the header">
	<cfset hcCoverHtml = '<div class="hcEmpty"><i class="fontAwesomeIcon fas fa-code"></i><span>Set in the post''s header (facebookImageUrlMetaData).</span></div>'>
	<cfset hcCoverButton = "Add a cover">
<cfelseif hcHero.kind neq "none">
	<!--- Cards show a video, map or carousel itself, so only sharing lacks a picture then. --->
	<cfset hcCoverHtml = '<blockquote class="hcEmpty k-notification-warning"><i class="fontAwesomeIcon fas fa-triangle-exclamation"></i><b>No cover yet</b><span>' & (hcHero.cardShowsMedia ? "Sharing" : "Cards and sharing") & ' can''t use ' & encodeForHtml(hcHero.kind eq "movingHero" ? "a moving hero" : (hcHero.kind eq "scene" ? "a scene" : application.blog.getHeroes().describe(hcHero.kind))) & '. Add a picture for ' & (hcHero.cardShowsMedia ? "it" : "them") & '.</span></blockquote>'>
	<cfset hcCoverButton = "Add a cover">
<cfelse>
	<cfset hcCoverHtml = '<div class="hcEmpty"><i class="fontAwesomeIcon fas fa-camera-retro"></i><span>No cover yet. Add a picture for cards and sharing.</span></div>'>
	<cfset hcCoverButton = "Add a cover">
</cfif>
<cfset hcHeroAction = hcIsFullScene ? "createAdminInterfaceWindow(107, " & hcSceneId & ")" : "createAdminInterfaceWindow(13, " & hcPostId & ")">
<cfset hcCoverAction = "createAdminInterfaceWindow(80, " & hcPostId & ")">
</cfsilent>
<style>
	<!--- Two columns even when only the hero shows, so the hero keeps the same size with or without a cover. --->
	.hcGrid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; max-width: 900px; }
	<!--- The two previews line up even when one caption wraps to more lines (11-05, owner): each caption takes the spare height
	and sits on its picture. --->
	.hcGrid > div { display: flex; flex-direction: column; align-items: flex-start; }
	.hcGrid > div > .k-form-hint { flex: 1 0 auto; display: flex !important; align-items: flex-end; }
	.hcGrid > div > .hcArt { align-self: stretch; }
	@media (max-width: 560px) { .hcGrid { grid-template-columns: 1fr; } }
	.hcArt { position: relative; aspect-ratio: 16 / 9; overflow: hidden; border-radius: 4px; cursor: pointer; }
	<!--- Every preview fills the same 16:9 box (the gradient and animation previews come with a fixed 235x130 size). --->
	.hcArt > img, .hcArt > iframe, .hcArt > div, .hcArt > a, .hcArt > a > img, .hcArt > video { position: absolute; inset: 0; width: 100% !important; height: 100% !important; object-fit: cover; border: 0; }
	<!--- Previews that are iframes (animation, video, map, carousel) would take the click; this layer opens the window instead. --->
	.hcArt .hcClick { position: absolute; inset: 0; z-index: 2; }
	.hcLayers { position: absolute; inset: 0; }
	<!--- The heading is drawn for a post page about 1100px wide; these previews are about 420px (11-03, owner: the text was too big). --->
	.hcArt .galaxieHeroText { zoom: .38; width: 90%; }
	.hcLayers img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; }
	<!--- The warning is a callout (a blockquote with k-notification-warning), drawn soft by blogContentCss.cfm like the callouts in posts. --->
	.hcPlaceholder, .hcEmpty { box-sizing: border-box; margin: 0 !important; position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; text-align: center; padding: 10px 16px; }
	div.hcEmpty { border: 2px dashed rgba(128,128,128,.45); border-radius: 4px; }
	.hcUses { position: absolute; left: 0; right: 0; bottom: 0; padding: 4px 8px; opacity: .92; }
	<!--- Every button icon the same size and width (owner 11-02). --->
	.hcGrid .fontAwesomeIcon { width: 1.25em; text-align: center; }
	.hcGrid .k-button .fontAwesomeIcon { margin-right: 4px; }
	.hcGrid .k-button { margin-top: 8px; }
</style>
<!--- What the hero is and the cover, at the top beside the row's Hero label (11-05, owner: it was at the bottom, and a second bold
"Hero" heading repeated the label). On a phone there is no label beside it, so the line says Hero itself. --->
<cfset hcKindText = hcIsFullScene ? hcSceneName : hcHero.label>
<div class="heroSummary" style="padding-top: 10px; margin-bottom: 6px;"><cfoutput><cfif session.isMobile>#hcIsFullScene ? "Scene" : "Hero"#: </cfif>#encodeForHtml(hcKindText)# &middot; Cover: #hcCoverState#</cfoutput></div>
<div class="hcGrid">
	<div>
		<div class="k-form-hint" style="display: block;"><cfif hcIsFullScene>Readers start here<cfelse>At the top of the post</cfif></div>
		<div class="hcArt" title="<cfoutput>#hcIsFullScene ? 'Open the scene' : 'Change hero'#</cfoutput>"><cfoutput>#hcHeroHtml#</cfoutput><span class="hcClick" onclick="<cfoutput>#hcHeroAction#</cfoutput>"></span></div>
		<button type="button" id="enclosure" class="k-button k-primary normalFontWeight" onclick="<cfoutput>#hcHeroAction#</cfoutput>"><cfif hcIsFullScene><i class="fontAwesomeIcon fas fa-layer-group"></i> Open the scene<cfelse><i class="fontAwesomeIcon fas fa-panorama"></i> Change hero</cfif></button>
		<!--- A scene post (2026-11-08): another scene, or none. With no Hero window to reach it from, its cover is added here too. --->
		<cfif hcIsFullScene>
		<div>
			<button type="button" class="k-button normalFontWeight" onclick="createAdminInterfaceWindow(108, <cfoutput>#hcPostId#</cfoutput>)">Choose another</button>
			<button type="button" class="k-button normalFontWeight" onclick="galaxieTakeSceneOff()">Take it off</button>
			<cfif not len(hcCoverUrl)><button type="button" class="k-button normalFontWeight" onclick="<cfoutput>#hcCoverAction#</cfoutput>"><i class="fontAwesomeIcon fas fa-camera-retro"></i> <cfoutput>#hcCoverButton#</cfoutput></button></cfif>
		</div>
		</cfif>
	</div>
	<!--- The Cover card only once a cover is made (owner 11-03): the reminder after a hero save asks for one when cards and sharing
	need it, and the Hero editor's Cover Image button adds one any time. --->
	<cfif len(hcCoverUrl)>
	<div>
		<div class="k-form-hint" style="display: block;"><cfif hcCoverUnused>The cover, not used now<cfelseif hcHero.cardShowsMedia>The cover, for Facebook, X and Pinterest. Cards show the <cfoutput>#hcHero.mediaKind#</cfoutput>.<cfelse>The cover, on cards, Facebook, X and Pinterest</cfif></div>
		<div class="hcArt" title="<cfoutput>#hcCoverButton#</cfoutput>"><cfoutput>#hcCoverHtml#</cfoutput><span class="hcClick" onclick="<cfoutput>#hcCoverAction#</cfoutput>"></span></div>
		<button type="button" class="k-button normalFontWeight" onclick="<cfoutput>#hcCoverAction#</cfoutput>"><i class="fontAwesomeIcon fas fa-camera-retro"></i> <cfoutput>#hcCoverButton#</cfoutput></button>
	</div>
	</cfif>
</div>
<!--- Layout (2026-11-08): this row is the one place that knows, so each time it's drawn it sets the Layout buttons, its label and the note
above the text (postDetail.cfm). --->
<script>
	window.galaxiePostSceneOn = <cfoutput>#hcIsFullScene ? "true" : "false"#</cfoutput>;
	window.galaxiePostHeroKind = "<cfoutput>#encodeForJavaScript(hcHero.kind)#</cfoutput>";
	$("input[name=postLayout][value=" + (window.galaxiePostSceneOn ? "scene" : "standard") + "]").prop("checked", true);
	$("#heroRowLabel").text(window.galaxiePostSceneOn ? "Scene:" : "Hero:");
	$("#postLayoutNote").css("display", window.galaxiePostSceneOn ? "block" : "none");
</script>
