<!--- The Edit Post window's Hero row (11-02, owner: one preview with a "Change hero" button showed the cover, which was confusing).
The hero (what is at the top of the post) and the cover (the picture for cards, Facebook, X and Pinterest) side by side, the same
size, each with its own button; on a narrow window they stack. Included by postDetail.cfm inside #mediaPreview, and by
admin/loadPreview.cfm (previewId=1), which reloadEnclosureThumbnailPreview() calls after any hero or cover window saves.
Needs getPost (getPostByPostId), RendererObj and kendoTheme. Mock-up: test page heroCoverMock.html (owner OK 11-02). --->
<cfsilent>
<cfset hcPost = getPost[1]>
<cfset hcPostId = hcPost["PostId"]>
<cfset hcValue = function (key) { return structKeyExists(hcPost, key) and not isNull(hcPost[key]) ? trim(toString(hcPost[key])) : ""; }>
<cfset hcMediaUrl = hcValue("MediaUrl")>
<cfif not len(hcMediaUrl) and len(hcValue("MediaPath"))>
	<cfset hcMediaUrl = application.blog.getEnclosureUrlFromMediaPath(hcValue("MediaPath"), true)>
</cfif>
<cfset hcMediaType = hcValue("MediaType")>
<cfset hcCoverUrl = hcValue("HeroCoverImageUrl")>

<!--- A scene shown on the post takes the place of its hero (a moving hero is the post's own scene, post-hero-{postId}). --->
<cfset hcScenes = application.blog.getScenes()>
<cfset hcSceneAlias = hcScenes.getPostScene(hcPostId)>
<cfset hcSceneId = len(hcSceneAlias) ? hcScenes.getSceneIdByAlias(hcSceneAlias) : 0>
<cfset hcSceneName = "">
<cfset hcSceneArt = "">
<cfif hcSceneId gt 0>
	<cfset hcScene = hcScenes.getScene(hcSceneId)>
	<cfset hcSceneName = hcScene.name ?: hcSceneAlias>
	<!--- The scene's first section drawn as a still: its layers stacked, or its photo. Other kinds get the layers icon. --->
	<cftry>
		<cfset hcSceneData = deserializeJSON(hcScene.json)>
		<cfset hcFirst = hcSceneData.sections[1]>
		<cfif (hcFirst.kind ?: "") eq "layeredHero" and isArray(hcFirst.layers ?: "")>
			<cfloop array="#hcFirst.layers#" index="hcLayer">
				<cfif len(hcLayer.src ?: "")>
					<cfset hcSceneArt = hcSceneArt & '<img src="' & encodeForHtmlAttribute(replace(hcLayer.src, "{baseUrl}", application.baseUrl, "all")) & '" alt="">'>
				</cfif>
			</cfloop>
		<cfelseif (hcFirst.kind ?: "") eq "photoHero" and len(hcFirst.image ?: "")>
			<cfset hcSceneArt = '<img src="' & encodeForHtmlAttribute(replace(hcFirst.image, "{baseUrl}", application.baseUrl, "all")) & '" alt="">'>
		</cfif>
		<cfcatch type="any"></cfcatch>
	</cftry>
</cfif>
<cfset hcIsMovingHero = (hcSceneAlias eq "post-hero-" & hcPostId)>
<cfset hcIsFullScene = hcSceneId gt 0 and not hcIsMovingHero>

<!--- What the hero is, for the line under the previews and for the cover side. --->
<cfif hcIsMovingHero>
	<cfset hcHeroKind = "Moving hero (" & reReplace(hcSceneName, "\s*\(.*\)$", "") & ")">
<cfelseif hcIsFullScene>
	<cfset hcHeroKind = "scene (" & hcSceneName & ")">
<cfelseif len(hcValue("EnclosureCarouselId"))>
	<cfset hcHeroKind = "carousel">
<cfelseif len(hcValue("EnclosureMapId"))>
	<cfset hcHeroKind = "map">
<cfelseif len(hcMediaUrl) and hcMediaType eq "Image">
	<cfset hcHeroKind = "picture">
<cfelseif len(hcMediaUrl) and left(hcMediaType, 5) eq "Video">
	<cfset hcHeroKind = "video">
<cfelseif len(hcValue("HeroGradient"))>
	<cfset hcHeroKind = "gradient">
<cfelseif len(hcValue("HeroAnimationEffect"))>
	<cfset hcHeroKind = "animation (" & lCase(hcValue("HeroAnimationEffect")) & ")">
<cfelse>
	<cfset hcHeroKind = "">
</cfif>
<cfset hcHeroIsPicture = hcHeroKind eq "picture">

<!--- The hero side. --->
<cfif hcSceneId gt 0>
	<cfif len(hcSceneArt)>
		<cfset hcHeroHtml = '<div class="hcLayers">' & hcSceneArt & '</div>'>
	<cfelse>
		<cfset hcHeroHtml = '<div class="hcPlaceholder k-alt"><i class="fontAwesomeIcon fas fa-layer-group"></i><span>' & encodeForHtml(hcSceneName) & '</span></div>'>
	</cfif>
<cfelseif hcHeroIsPicture>
	<cfset hcHeroHtml = '<img src="' & encodeForHtmlAttribute(hcMediaUrl) & '" alt="">'>
<cfelseif len(hcHeroKind)>
	<cfset hcHeroHtml = RendererObj.renderMediaPreview(kendoTheme = kendoTheme, getPost = getPost, renderThumbnail = true, includeCover = false)>
<cfelse>
	<cfset hcHeroHtml = '<div class="hcEmpty"><i class="fontAwesomeIcon fas fa-image"></i><span>No hero yet. The post starts with its title.</span></div>'>
</cfif>

<!--- The cover side, by the same rule as the cover reminder after a save (ProxyController getCoverImageReminder): a cover is
needed when the hero isn't a picture, unless a share picture is named in the post's header. --->
<cfset hcHeaderPicture = findNoCase("facebookImageUrlMetaData", hcValue("PostHeader")) gt 0>
<!--- While the hero is a picture, cards and sharing show the hero picture and a cover is not used (11-05, owner). --->
<cfset hcCoverUnused = len(hcCoverUrl) and hcHeroIsPicture and hcSceneId eq 0>
<cfif hcCoverUnused>
	<cfset hcCoverHtml = '<img src="' & encodeForHtmlAttribute(hcCoverUrl) & '" alt="" style="opacity: .55;"><span class="hcUses k-content">Used again if the hero changes to something that isn''t a picture</span>'>
	<cfset hcCoverButton = "Change cover">
	<cfset hcCoverState = "set, not used (the hero picture is shared)">
<cfelseif len(hcCoverUrl)>
	<cfset hcCoverHtml = '<img src="' & encodeForHtmlAttribute(hcCoverUrl) & '" alt="">'>
	<cfset hcCoverButton = "Change cover">
	<cfset hcCoverState = "set">
<cfelseif hcHeroIsPicture>
	<cfset hcCoverHtml = '<img src="' & encodeForHtmlAttribute(hcMediaUrl) & '" alt=""><span class="hcUses k-content">Uses the hero picture</span>'>
	<cfset hcCoverButton = "Use a different cover">
	<cfset hcCoverState = "the hero picture">
<cfelseif hcHeroKind eq "video" and len(hcValue("MediaVideoCoverUrl"))>
	<!--- A video's own cover (its poster) is shared when there is no Hero Cover Image (11-05, owner). --->
	<cfset hcCoverHtml = '<img src="' & encodeForHtmlAttribute(hcValue("MediaVideoCoverUrl")) & '" alt=""><span class="hcUses k-content">Uses the video''s cover</span>'>
	<cfset hcCoverButton = "Use a different cover">
	<cfset hcCoverState = "the video's cover">
<cfelseif hcHeaderPicture>
	<cfset hcCoverHtml = '<div class="hcEmpty"><i class="fontAwesomeIcon fas fa-code"></i><span>Set in the post''s header (facebookImageUrlMetaData).</span></div>'>
	<cfset hcCoverButton = "Add a cover">
	<cfset hcCoverState = "in the header">
<cfelseif len(hcHeroKind)>
	<cfset hcCoverHtml = '<blockquote class="hcEmpty k-notification-warning"><i class="fontAwesomeIcon fas fa-triangle-exclamation"></i><b>No cover yet</b><span>Cards and sharing can''t use ' & (left(hcHeroKind, 1) eq "a" ? "an " : "a ") & encodeForHtml(lCase(reReplace(hcHeroKind, "\s*\(.*$", ""))) & '. Add a picture for them.</span></blockquote>'>
	<cfset hcCoverButton = "Add a cover">
	<cfset hcCoverState = "none">
<cfelse>
	<cfset hcCoverHtml = '<div class="hcEmpty"><i class="fontAwesomeIcon fas fa-camera-retro"></i><span>No cover yet. Add a picture for cards and sharing.</span></div>'>
	<cfset hcCoverButton = "Add a cover">
	<cfset hcCoverState = "none">
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
<cfset hcKindText = len(hcHeroKind) ? uCase(left(hcHeroKind, 1)) & mid(hcHeroKind, 2, len(hcHeroKind)) : "None">
<div class="heroSummary" style="padding-top: 10px; margin-bottom: 6px;"><cfoutput><cfif session.isMobile>Hero: </cfif>#encodeForHtml(hcKindText)# &middot; Cover: #hcCoverState#</cfoutput></div>
<div class="hcGrid">
	<div>
		<div class="k-form-hint" style="display: block;"><cfif hcIsFullScene>From the scene <cfoutput>#encodeForHtml(hcSceneName)#</cfoutput><cfelse>At the top of the post</cfif></div>
		<div class="hcArt" title="<cfoutput>#hcIsFullScene ? 'Open the scene' : 'Change hero'#</cfoutput>"><cfoutput>#hcHeroHtml#</cfoutput><span class="hcClick" onclick="<cfoutput>#hcHeroAction#</cfoutput>"></span></div>
		<button type="button" id="enclosure" class="k-button k-primary normalFontWeight" onclick="<cfoutput>#hcHeroAction#</cfoutput>"><cfif hcIsFullScene><i class="fontAwesomeIcon fas fa-layer-group"></i> Open the scene<cfelse><i class="fontAwesomeIcon fas fa-panorama"></i> Change hero</cfif></button>
	</div>
	<!--- The Cover card only once a cover is made (owner 11-03): the reminder after a hero save asks for one when cards and sharing
	need it, and the Hero editor's Cover Image button adds one any time. --->
	<cfif len(hcCoverUrl)>
	<div>
		<div class="k-form-hint" style="display: block;"><cfif hcCoverUnused>The cover, not used while the hero is a picture<cfelseif listFindNoCase("video,map,carousel", hcHeroKind)>The cover, for Facebook, X and Pinterest. Cards show the <cfoutput>#hcHeroKind#</cfoutput>.<cfelse>The cover, on cards, Facebook, X and Pinterest</cfif></div>
		<div class="hcArt" title="<cfoutput>#hcCoverButton#</cfoutput>"><cfoutput>#hcCoverHtml#</cfoutput><span class="hcClick" onclick="<cfoutput>#hcCoverAction#</cfoutput>"></span></div>
		<button type="button" class="k-button normalFontWeight" onclick="<cfoutput>#hcCoverAction#</cfoutput>"><i class="fontAwesomeIcon fas fa-camera-retro"></i> <cfoutput>#hcCoverButton#</cfoutput></button>
	</div>
	</cfif>
</div>
