<cfcomponent displayName="Hero" output="false" hint="What a post's hero is, and which picture its cards and sharing use: one answer for every screen and template (2026-11-05, the hero pipeline). Created by blog.cfc getHero(). Read only: nothing here saves. Plan: Claude/reports/hero-pipeline-plan-2026-11-05.md.">

<!---
	Why this exists: about 22 places each worked this out for themselves, in different orders and with different tests for "is it a
	picture", and they disagreed (the Edit Post window said one thing, the cards did another, sharing a third). Each place now asks
	getHero() and only decides how to draw the answer.

	The rules, in one place:
	1. A scene in the post's header (<galaxieScene>alias</galaxieScene>) is what the post page shows at the top. post-hero-{postId} is the
	   post's own moving hero; any other alias is a full-page scene. Lists and cards don't draw scenes.
	2. Under it (or with no scene), the post's media, first match wins, in the order the post page draws it (Renderer.renderPost and
	   renderEnclosure): a video named in the header (older posts), the picture or video, the carousel, the map, the gradient, the
	   animation. Since "last hero wins" (11-05) a post saved now has only one of these; older posts can have several.
	3. A picture is MediaType "Image" (or no MediaType and a picture's file name: older posts; sharing went by the file name); a video is
	   any MediaType starting with "Video". The address is MediaUrl, else made from MediaPath.
	4. Share picture, first match wins: a share picture typed into the header (facebookImageUrlMetaData, older posts), the hero picture,
	   the cover, a picture under a scene or under a video typed into the header, the video's own cover. None: the caller uses the theme's logo.
	   uploadedSharePicture is the same without the typed one: the blog's own upload, which has the per-platform crops (getShareCrop).
	5. Card picture: a video, map or carousel card shows the media itself (cardShowsMedia). Otherwise the share picture's chain. None:
	   the caller uses the no-picture art (BlogOption NoImageFallbackMode).
	6. The cover is used when nothing before it in rule 4 wins.
--->

<cfset variables.headerVideoKeys = "youTubeUrl,vimeoVideoId,videoType,videoPosterImageUrl,smallVideoSourceUrl,mediumVideoSourceUrl,largeVideoSourceUrl">

<cffunction name="getHero" access="public" returntype="struct" output="false"
		hint="The post's hero and pictures. post is one row of getPostByPostId (or a listing row with the same columns; missing columns count as empty). Returns kind (scene, movingHero, picture, video, carousel, map, gradient, animation, none), mediaKind (the same without the scene: what lists and cards draw), sceneAlias, isMovingHero, heroPictureUrl, mediaUrl, thumbnailUrl, videoCoverUrl, coverUrl, coverUsed, headerSharePicture, sharePicture, sharePictureSource, uploadedSharePicture, uploadedSharePictureSource, cardPicture, cardPictureSource, cardShowsMedia, headerVideo.">
	<cfargument name="post" type="struct" required="true">
	<cfset var p = arguments.post>
	<cfset var value = function (key) { return structKeyExists(p, key) and not isNull(p[key]) ? trim(toString(p[key])) : ""; }>
	<cfset var hero = {
		"kind": "none", "mediaKind": "none", "sceneAlias": "", "isMovingHero": false,
		"heroPictureUrl": "", "mediaUrl": "", "thumbnailUrl": "", "videoCoverUrl": "", "coverUrl": "", "coverUsed": false,
		"headerSharePicture": "", "sharePicture": "", "sharePictureSource": "none", "uploadedSharePicture": "", "uploadedSharePictureSource": "none",
		"cardPicture": "", "cardPictureSource": "none", "cardShowsMedia": false, "headerVideo": false
	}>
	<cfset var header = value("PostHeader")>
	<cfset var mediaType = value("MediaType")>
	<cfset var isPicture = false>
	<cfset var found = []>
	<cfset var key = "">

	<!--- The media's address. --->
	<cfset hero.mediaUrl = value("MediaUrl")>
	<cfif not len(hero.mediaUrl) and len(value("MediaPath"))>
		<cfset hero.mediaUrl = application.blog.getEnclosureUrlFromMediaPath(value("MediaPath"), true)>
	</cfif>
	<cfset hero.thumbnailUrl = value("MediaThumbnailUrl")>
	<cfset hero.videoCoverUrl = value("MediaVideoCoverUrl")>
	<cfset hero.coverUrl = value("HeroCoverImageUrl")>

	<!--- Rule 1: the scene. The same pattern Scenes.getPostScene uses, read from the row (no query per card). --->
	<cfif len(header)>
		<cfset found = reMatchNoCase("<galaxieScene>\s*[A-Za-z0-9_-]{1,80}\s*</galaxieScene>", header)>
		<cfif arrayLen(found)>
			<cfset hero.sceneAlias = trim(reReplaceNoCase(found[1], "</?galaxieScene>", "", "all"))>
			<cfset hero.isMovingHero = hero.sceneAlias eq "post-hero-" & value("PostId")>
		</cfif>
		<!--- Older posts: a video, or a share picture, typed into the header. A cheap look first; JSoup only when it is there. --->
		<cfloop list="#variables.headerVideoKeys#" index="key">
			<cfif findNoCase(key, header)><cfset hero.headerVideo = true><cfbreak></cfif>
		</cfloop>
		<cfif findNoCase("facebookImageUrlMetaData", header)>
			<cfset hero.headerSharePicture = trim(application.blog.getXmlKeywordValue(header, "facebookImageUrlMetaData"))>
		</cfif>
	</cfif>

	<!--- Rule 2 and 3: the media, in the order the post page draws it. --->
	<cfset isPicture = len(hero.mediaUrl) and (mediaType eq "Image" or (not len(mediaType) and reFindNoCase("\.(jpe?g|png|gif|webp)(\?|$)", hero.mediaUrl)))>
	<cfif hero.headerVideo>
		<cfset hero.mediaKind = "video">
		<!--- A picture saved under a video typed into the header is still shared (as it was before the pipeline). --->
		<cfif isPicture><cfset hero.heroPictureUrl = hero.mediaUrl></cfif>
	<cfelseif isPicture>
		<cfset hero.mediaKind = "picture">
		<cfset hero.heroPictureUrl = hero.mediaUrl>
	<cfelseif len(hero.mediaUrl) and left(mediaType, 5) eq "Video">
		<cfset hero.mediaKind = "video">
	<cfelseif len(value("EnclosureCarouselId"))>
		<cfset hero.mediaKind = "carousel">
	<cfelseif len(value("EnclosureMapId"))>
		<cfset hero.mediaKind = "map">
	<cfelseif len(value("HeroGradient"))>
		<cfset hero.mediaKind = "gradient">
	<cfelseif len(value("HeroAnimationEffect"))>
		<cfset hero.mediaKind = "animation">
	</cfif>
	<cfif len(hero.sceneAlias)>
		<cfset hero.kind = hero.isMovingHero ? "movingHero" : "scene">
	<cfelse>
		<cfset hero.kind = hero.mediaKind>
	</cfif>

	<!--- Rule 4: the share picture. First the blog's own upload, then a picture typed into the header goes before it. --->
	<cfif hero.kind eq "picture">
		<cfset hero.uploadedSharePicture = hero.heroPictureUrl>
		<cfset hero.uploadedSharePictureSource = "heroPicture">
	<cfelseif len(hero.coverUrl)>
		<cfset hero.uploadedSharePicture = hero.coverUrl>
		<cfset hero.uploadedSharePictureSource = "cover">
	<cfelseif len(hero.sceneAlias) and len(hero.heroPictureUrl)>
		<cfset hero.uploadedSharePicture = hero.heroPictureUrl>
		<cfset hero.uploadedSharePictureSource = "pictureUnderScene">
	<cfelseif hero.headerVideo and len(hero.heroPictureUrl)>
		<cfset hero.uploadedSharePicture = hero.heroPictureUrl>
		<cfset hero.uploadedSharePictureSource = "pictureUnderHeaderVideo">
	<cfelseif hero.mediaKind eq "video" and len(hero.videoCoverUrl)>
		<cfset hero.uploadedSharePicture = hero.videoCoverUrl>
		<cfset hero.uploadedSharePictureSource = "videoCover">
	</cfif>
	<cfif len(hero.headerSharePicture)>
		<cfset hero.sharePicture = hero.headerSharePicture>
		<cfset hero.sharePictureSource = "header">
	<cfelse>
		<cfset hero.sharePicture = hero.uploadedSharePicture>
		<cfset hero.sharePictureSource = hero.uploadedSharePictureSource>
		<cfset hero.coverUsed = hero.sharePictureSource eq "cover">
	</cfif>

	<!--- Rule 5: the card picture. Cards don't draw scenes, so they go by mediaKind. --->
	<cfif listFind("video,map,carousel", hero.mediaKind)>
		<cfset hero.cardShowsMedia = true>
		<cfset hero.cardPictureSource = hero.mediaKind>
	<cfelseif len(hero.headerSharePicture)>
		<cfset hero.cardPicture = hero.headerSharePicture>
		<cfset hero.cardPictureSource = "header">
	<cfelseif hero.mediaKind eq "picture">
		<cfset hero.cardPicture = len(hero.thumbnailUrl) ? hero.thumbnailUrl : hero.heroPictureUrl>
		<cfset hero.cardPictureSource = "heroPicture">
	<cfelseif len(hero.coverUrl)>
		<cfset hero.cardPicture = hero.coverUrl>
		<cfset hero.cardPictureSource = "cover">
		<cfset hero.coverUsed = true>
	</cfif>

	<cfreturn hero>
</cffunction>

<cffunction name="getAdminHero" access="public" returntype="struct" output="false"
		hint="getHero plus what the admin screens show (the Edit Post hero row, the Hero window's status line): sceneId, sceneName and sceneArt (the scene's first section as a still), label ('Moving hero (Galaxie space)', 'Picture', 'None'), sentence ('a moving hero (Galaxie space)', 'a picture', 'none yet'), and cover: { state, unused, unusedReason, usesUrl, usesLabel }.">
	<cfargument name="post" type="struct" required="true">
	<cfset var hero = getHero(arguments.post)>
	<cfset var still = "">
	<cfset var shortName = "">
	<cfset var effect = structKeyExists(arguments.post, "HeroAnimationEffect") and not isNull(arguments.post["HeroAnimationEffect"]) ? lCase(trim(toString(arguments.post["HeroAnimationEffect"]))) : "">
	<cfset hero.sceneId = 0>
	<cfset hero.sceneName = "">
	<cfset hero.sceneArt = "">
	<cfif len(hero.sceneAlias)>
		<cfset still = application.blog.getScenes().getPostSceneStill(val(arguments.post["PostId"]))>
		<cfif still.sceneId gt 0>
			<cfset hero.sceneId = still.sceneId>
			<cfset hero.sceneName = still.name>
			<cfset hero.sceneArt = still.art>
		<cfelse>
			<!--- The header names a scene that no longer exists: the admin goes by what is under it. --->
			<cfset hero.kind = hero.mediaKind>
		</cfif>
	</cfif>
	<!--- A moving hero's scene is named "Picture (post title)"; the admin shows the picture's name only. --->
	<cfset shortName = reReplace(hero.sceneName, "\s*\(.*\)$", "")>
	<cfswitch expression="#hero.kind#">
		<cfcase value="movingHero"><cfset hero.label = "Moving hero (" & shortName & ")"><cfset hero.sentence = "a moving hero (" & shortName & ")"></cfcase>
		<cfcase value="scene"><cfset hero.label = "Scene (" & hero.sceneName & ")"><cfset hero.sentence = "the full-page scene " & hero.sceneName></cfcase>
		<cfcase value="animation"><cfset hero.label = "Animation" & (len(effect) ? " (" & effect & ")" : "")><cfset hero.sentence = "an animation" & (len(effect) ? " (" & effect & ")" : "")></cfcase>
		<cfcase value="none"><cfset hero.label = "None"><cfset hero.sentence = "none yet"></cfcase>
		<cfdefaultcase><cfset hero.sentence = describe(hero.kind)><cfset hero.label = uCase(left(hero.kind, 1)) & mid(hero.kind, 2, 50)></cfdefaultcase>
	</cfswitch>

	<!--- The cover, by the share picture's chain (rule 4): what is shared, and whether the cover is the one. --->
	<cfset hero.cover = { "state": "none", "unused": false, "unusedReason": "", "usesUrl": "", "usesLabel": "" }>
	<cfif len(hero.coverUrl) and hero.sharePictureSource eq "cover">
		<cfset hero.cover.state = "set">
	<cfelseif len(hero.coverUrl)>
		<cfset hero.cover.unused = true>
		<cfif hero.sharePictureSource eq "header">
			<cfset hero.cover.state = "set, not used (the share picture in the post's header is used)">
			<cfset hero.cover.unusedReason = "The share picture in the post's header is used instead">
		<cfelse>
			<cfset hero.cover.state = "set, not used (the hero picture is shared)">
			<cfset hero.cover.unusedReason = "Used again if the hero changes to something that isn't a picture">
		</cfif>
	<cfelseif hero.sharePictureSource eq "heroPicture">
		<cfset hero.cover.state = "the hero picture">
		<cfset hero.cover.usesUrl = hero.heroPictureUrl>
		<cfset hero.cover.usesLabel = "Uses the hero picture">
	<cfelseif hero.sharePictureSource eq "pictureUnderScene">
		<cfset hero.cover.state = "the picture under the scene">
		<cfset hero.cover.usesUrl = hero.heroPictureUrl>
		<cfset hero.cover.usesLabel = "Uses the picture under the scene">
	<cfelseif hero.sharePictureSource eq "pictureUnderHeaderVideo">
		<cfset hero.cover.state = "the post's picture">
		<cfset hero.cover.usesUrl = hero.heroPictureUrl>
		<cfset hero.cover.usesLabel = "Uses the post's picture">
	<cfelseif hero.sharePictureSource eq "videoCover">
		<cfset hero.cover.state = "the video's cover">
		<cfset hero.cover.usesUrl = hero.videoCoverUrl>
		<cfset hero.cover.usesLabel = "Uses the video's cover">
	<cfelseif hero.sharePictureSource eq "header">
		<cfset hero.cover.state = "in the header">
	</cfif>
	<cfreturn hero>
</cffunction>

<cffunction name="getShareCrop" access="public" returntype="struct" output="false"
		hint="One platform's crop of an uploaded share picture (Image.cfc createSocialMediaImages, made at upload): { url (the web address, no host), path (on disk) }, or an empty struct when it isn't there. folder is facebook, twitter, pinterest, classic, google/16_9, google/4_3 or google/1_1. The crop is kept in the folder of the same name under /enclosures/ (plus the picture's own subfolder, eg. videos/ for a video's cover), in the picture's own format first (JPG or PNG: Slack, LinkedIn and older Facebook crawlers show no WebP), then WebP.">
	<cfargument name="pictureUrl" type="string" required="true">
	<cfargument name="folder" type="string" required="true">
	<cfset var fileName = getFileFromPath(arguments.pictureUrl)>
	<cfset var subFolder = "">
	<cfset var candidates = []>
	<cfset var name = "">
	<cfset var webPath = "">
	<cfif not len(fileName) or not findNoCase("/enclosures/", arguments.pictureUrl)><cfreturn {}></cfif>
	<cfset subFolder = reReplaceNoCase(reReplaceNoCase(arguments.pictureUrl, "^.*?/enclosures/", ""), "[^/]+$", "")>
	<cfif not reFindNoCase("\.webp$", fileName)><cfset arrayAppend(candidates, fileName)></cfif>
	<cfset arrayAppend(candidates, reReplaceNoCase(fileName, "\.[^.]+$", "") & ".webp")>
	<cfloop array="#candidates#" index="name">
		<cfset webPath = application.baseUrl & "/enclosures/" & arguments.folder & "/" & subFolder & name>
		<cfif fileExists(expandPath(webPath))>
			<cfreturn { "url": webPath, "path": expandPath(webPath) }>
		</cfif>
	</cfloop>
	<cfreturn {}>
</cffunction>

<cffunction name="describe" access="public" returntype="string" output="false"
		hint="A few words for the admin about what the hero is, eg. 'a moving hero', 'a picture'. Scene names are added by the caller.">
	<cfargument name="kind" type="string" required="true">
	<cfswitch expression="#arguments.kind#">
		<cfcase value="movingHero"><cfreturn "a moving hero"></cfcase>
		<cfcase value="scene"><cfreturn "a full-page scene"></cfcase>
		<cfcase value="picture"><cfreturn "a picture"></cfcase>
		<cfcase value="video"><cfreturn "a video"></cfcase>
		<cfcase value="carousel"><cfreturn "a carousel"></cfcase>
		<cfcase value="map"><cfreturn "a map"></cfcase>
		<cfcase value="gradient"><cfreturn "a gradient"></cfcase>
		<cfcase value="animation"><cfreturn "an animation"></cfcase>
	</cfswitch>
	<cfreturn "">
</cffunction>

</cfcomponent>
