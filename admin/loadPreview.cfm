<cfsetting enablecfoutputonly=true>

<!--- This is designed to be extendable similiarly to the adminInterface.cfm template and takes several arguments: URL.previewId, URL.optArgs, URL.otherArgs, and URL.otherArgs1 --->
<!--- <cfdump var="#URL#" label="url"> --->

<!--- Send the postId in via the URL. --->
<cfparam name="URL.previewId" default="">
<cfparam name="URL.optArgs" default="">
<cfparam name="URL.otherArgs" default="">
<cfparam name="URL.otherArgs1" default="">

<cfswitch expression="#URL.previewId#">
	<cfcase value="1">
		<!--- Instantiate the Render.cfc. This will be used to create video and map thumbnails --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">

		<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
		<cfset getPost = application.blog.getPostByPostId(URL.optArgs,true,true)>
		<!---<cfdump var="#getPost#">--->

		<!--- Get the current blog theme --->
		<cfset kendoTheme = application.blog.getSelectedKendoTheme()>

		<!--- The Edit Post window's hero and cover block (11-02), the same template postDetail.cfm shows first. --->
		<cfsetting enablecfoutputonly="false">
		<cfinclude template="adminInterface/heroCoverBlock.cfm">
		<cfsetting enablecfoutputonly="true">
	</cfcase>
	<cfcase value="2">
		<!--- Page Collection hero preview (image/carousel/map/video) - lightweight reload target for
		pageCollectionDetail.cfm's #pcHeroPreview-<id> div, called after any hero upload/selection instead of
		reloading that whole window's content. URL.optArgs is the pageCollectionId. Mirrors pageCollectionDetail.cfm's
		own initial render exactly (same priority order and same two data sources), so a fresh page load and a
		lightweight reload always agree on what's showing. --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		<cfset thisPageCollectionId = val(URL.optArgs)>

		<!--- Carousel/Map/Video ids and the raw MediaUrl/MediaType live on the Enclosure ORM relationship, not on
		the plain HeroImageUrl field - see getPageCollectionByPageCollectionId()'s own hint. --->
		<cfset heroEnclosureData = application.blog.getPageCollectionByPageCollectionId(thisPageCollectionId)>
		<!--- Bracket notation with exact case throughout below - a Lucee HQL "SELECT new Map(...)" result is a raw
		java.util.HashMap, where dot notation is unreliable (see the case-sensitivity article this project already
		wrote up). --->
		<cfset heroEnclosureMapId = arrayLen(heroEnclosureData) ? heroEnclosureData[1]["EnclosureMapId"] : "">
		<cfset heroEnclosureCarouselId = arrayLen(heroEnclosureData) ? heroEnclosureData[1]["EnclosureCarouselId"] : "">
		<cfset heroEnclosureMediaType = arrayLen(heroEnclosureData) ? heroEnclosureData[1]["MediaType"] : "">
		<cfset heroEnclosureMediaUrl = arrayLen(heroEnclosureData) ? heroEnclosureData[1]["MediaUrl"] : "">

		<!--- The plain HeroImageUrl field only - kept as the one source of truth for the plain-image case, same as
		pageCollectionDetail.cfm's own initial render. --->
		<cfset allCollectionsForPreview = application.blog.getAllPageCollections()>
		<cfset thisCollectionForPreview = "">
		<cfloop array="#allCollectionsForPreview#" index="c">
			<cfif c.pageCollectionId eq thisPageCollectionId>
				<cfset thisCollectionForPreview = c>
			</cfif>
		</cfloop>

		<cfoutput>
			<!-- Rendered by the /admin/loadPreview.cfm template -->
			<cfif len(heroEnclosureCarouselId)>
				#RendererObj.renderCarouselPreview(heroEnclosureCarouselId, 'postEditor')#
			<cfelseif len(heroEnclosureMapId)>
				#RendererObj.renderMapPreview(heroEnclosureMapId, false)#
			<cfelseif left(heroEnclosureMediaType, 5) eq 'Video' and len(heroEnclosureMediaUrl)>
				#RendererObj.renderEnclosureVideoPreview(postId="", pageCollectionId=thisPageCollectionId, mediaUrl=heroEnclosureMediaUrl, mediaId=heroEnclosureData[1]["MediaId"], providerVideoId=heroEnclosureData[1]["ProviderVideoId"], posterUrl=heroEnclosureData[1]["MediaVideoCoverUrl"], videoCaptionsUrl=heroEnclosureData[1]["MediaVideoVttFileUrl"], renderThumbnail=true)#
			<cfelseif isStruct(thisCollectionForPreview) and len(thisCollectionForPreview.heroGradient)>
				<div style="width:100%;height:100%;min-height:150px;background:#thisCollectionForPreview.heroGradient#;display:flex;align-items:center;justify-content:center;box-sizing:border-box;padding:10px;">
					<cfif len(thisCollectionForPreview.heroOverlayText)>
						<span style="color:#(len(thisCollectionForPreview.heroOverlayTextColor) ? thisCollectionForPreview.heroOverlayTextColor : '##ffffff')#;font-size:20px;font-weight:bold;text-align:center;">#thisCollectionForPreview.heroOverlayText#</span>
					</cfif>
				</div>
			<cfelseif isStruct(thisCollectionForPreview) and len(thisCollectionForPreview.heroImageUrl)>
				<img src="#thisCollectionForPreview.heroImageUrl#?v=#getTickCount()#" alt="">
			<cfelse>
				<img src="#application.baseUrl#/images/icons/noMedia.png" alt="">
			</cfif>
		</cfoutput>
	</cfcase>
	<cfcase value="3">
		<!--- The Hero editor's preview for a post with no picture, video, carousel or map (11-04): its scene, gradient, animation or
		cover, the same as enclosureImageEditor.cfm shows when it opens. Called by galaxieRefreshHeroEditorPreview() after the moving
		hero or the cover is saved. URL.optArgs is the postId. --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		<cfset getPost = application.blog.getPostByPostId(val(URL.optArgs),true,true)>
		<cfif arrayLen(getPost)>
			<cfoutput>#RendererObj.renderHeroEditorFallback(getPost)#</cfoutput>
		</cfif>
	</cfcase>
	<cfcase value="6">
		<!--- The Hero window's Hero text row (11-05): the heading and its window. URL.optArgs is the postId. --->
		<cfset getPost = application.blog.getPostByPostId(val(URL.optArgs),true,true)>
		<cfif arrayLen(getPost)>
			<cfsetting enablecfoutputonly="false">
			<cfinclude template="adminInterface/heroTextLine.cfm">
			<cfsetting enablecfoutputonly="true">
		</cfif>
	</cfcase>
	<cfcase value="5">
		<!--- The Hero window's line under the preview (11-04): what the hero is, and the cover. URL.optArgs is the postId. --->
		<cfset getPost = application.blog.getPostByPostId(val(URL.optArgs),true,true)>
		<cfif arrayLen(getPost)>
			<cfsetting enablecfoutputonly="false">
			<cfinclude template="adminInterface/heroStatusLine.cfm">
			<cfsetting enablecfoutputonly="true">
		</cfif>
	</cfcase>
	<cfcase value="4">
		<!--- The post's cover picture, as JSON (11-04): the Moving hero wizard's cover step reads it again after the cover window saves.
		URL.optArgs is the postId. --->
		<cfset getPost = application.blog.getPostByPostId(val(URL.optArgs),true,true)>
		<cfcontent type="application/json" reset="true">
		<cfoutput>#serializeJSON({ "coverUrl": arrayLen(getPost) ? (getPost[1]["HeroCoverImageUrl"] ?: "") : "" })#</cfoutput>
	</cfcase>
</cfswitch>