<!--- The Hero window's one line under the preview (11-04, owner: the window had "a lot of stuff at the bottom" that the wizards and
windows made confusing): what the post's hero is, and its cover, with the cover's window as a link. Included by
enclosureImageEditor.cfm, and by admin/loadPreview.cfm (previewId=5) when galaxieRefreshHeroEditorPreview() redraws it after a save.
Needs getPost (getPostByPostId). The same order the post page picks its hero in (heroCoverBlock.cfm). --->
<cfsilent>
<cfset hsPost = getPost[1]>
<cfset hsPostId = val(hsPost["PostId"])>
<cfset hsValue = function (key) { return structKeyExists(hsPost, key) and not isNull(hsPost[key]) ? trim(toString(hsPost[key])) : ""; }>
<cfset hsStill = application.blog.getScenes().getPostSceneStill(hsPostId)>
<cfset hsMediaType = hsValue("MediaType")>
<cfset hsHasMedia = len(hsValue("MediaUrl")) or len(hsValue("MediaPath"))>
<cfif hsStill.sceneId gt 0 and hsStill.isMovingHero>
	<cfset hsHero = "a moving hero (" & reReplace(hsStill.name, "\s*\(.*\)$", "") & ")">
<cfelseif hsStill.sceneId gt 0>
	<cfset hsHero = "the full-page scene " & hsStill.name>
<cfelseif len(hsValue("EnclosureCarouselId"))>
	<cfset hsHero = "a carousel">
<cfelseif len(hsValue("EnclosureMapId"))>
	<cfset hsHero = "a map">
<cfelseif hsHasMedia and hsMediaType eq "Image">
	<cfset hsHero = "a picture">
<cfelseif hsHasMedia and left(hsMediaType, 5) eq "Video">
	<cfset hsHero = "a video">
<cfelseif len(hsValue("HeroGradient"))>
	<cfset hsHero = "a gradient">
<cfelseif len(hsValue("HeroAnimationEffect"))>
	<cfset hsHero = "an animation (" & lCase(hsValue("HeroAnimationEffect")) & ")">
<cfelse>
	<cfset hsHero = "none yet. Use the buttons above to add one">
</cfif>
<!--- While the hero is a picture, cards and sharing show the hero picture and a cover is not used (seoMetaTags.cfm,
renderKendoCardGrid.cfm). Said so plainly (11-05, owner: "Cover: set" read as if the cover were in use). --->
<cfif len(hsValue("HeroCoverImageUrl")) and hsHero eq "a picture">
	<cfset hsCover = 'set, not used (the hero picture is shared). <a href="javascript:createAdminInterfaceWindow(80, ' & hsPostId & ');">Cover</a>'>
<cfelseif len(hsValue("HeroCoverImageUrl"))>
	<cfset hsCover = 'set. <a href="javascript:createAdminInterfaceWindow(80, ' & hsPostId & ');">Change the cover</a>'>
<cfelseif hsHasMedia and hsMediaType eq "Image">
	<cfset hsCover = 'the hero picture, so no cover is needed'>
<cfelseif hsHasMedia and left(hsMediaType, 5) eq "Video" and len(hsValue("MediaVideoCoverUrl"))>
	<!--- A video's own cover (its poster) is shared when there is no Hero Cover Image (11-05, owner). --->
	<cfset hsCover = 'the video''s cover, for sharing. <a href="javascript:createAdminInterfaceWindow(80, ' & hsPostId & ');">Use a different cover</a>'>
<cfelseif hsHasMedia and left(hsMediaType, 5) eq "Video">
	<cfset hsCover = 'none yet, so sharing has no picture (cards show the video). <a href="javascript:createAdminInterfaceWindow(80, ' & hsPostId & ');">Add a cover</a>'>
<cfelse>
	<cfset hsCover = 'none yet, so cards and sharing have no picture. <a href="javascript:createAdminInterfaceWindow(80, ' & hsPostId & ');">Add a cover</a>'>
</cfif>
</cfsilent>
<cfoutput><span id="heroStatusLine">Hero: #encodeForHtml(hsHero)#. Cover: #hsCover#</span></cfoutput>
