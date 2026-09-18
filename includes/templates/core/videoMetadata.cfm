<!--- //**************************************************************************************************************
		Video/audio metadata extraction (XML keyword overrides + DB fallbacks) and Open Graph video meta tag values. Assumes postFound is true (see postViewTracking.cfm note).
//****************************************************************************************************************--->
<!--- Split out of coreLogic.cfm (item 7 of the index.cfm/coreLogic.cfm rewrite proposal) so each concern is easier to find. Assumes it is included from coreLogic.cfm, which is itself included from within a <cfsilent> block on index.cfm. --->

		<!--- //**************************************************************************************************************
		Video and Audio Content. We need to capture data from XML as well as the DB.
		//****************************************************************************************************************--->

		<cfparam name="videoType" default="" type="string">
		<cfparam name="videoPosterImageUrl" default="" type="string">
		<cfparam name="smallVideoSourceUrl" default="" type="string">
		<cfparam name="mediumVideoSourceUrl" default="" type="string">
		<cfparam name="largeVideoSourceUrl" default="" type="string">
		<cfparam name="videoCaptionsUrl" default="" type="string">
			   
		<!--- Overwrite the vars if the proper xml is embedded in the post header or the db. getXmlOverride() (common/function/page.cfm) uses the keyword's XML value when present, otherwise the fallback computed on the line above it. --->
		<!--- YouTube and Vimeo are nearly always .mp4 at this time. We may have to revisit this in the future. --->
		<cfset videoTypeFallback = (structKeyExists(getPost[1], "MediaType") and getPost[1]["MediaType"] contains 'Video') ? '.mp4' : videoType>
		<cfset videoType = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "videoType", videoTypeFallback)>

		<!--- Media Cover --->
		<cfset videoPosterImageFallback = (structKeyExists(getPost[1], "MediaVideoCoverUrl") and len(getPost[1]["MediaVideoCoverUrl"])) ? getPost[1]["MediaVideoCoverUrl"] : videoPosterImageUrl>
		<cfset videoPosterImageUrl = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "videoPosterImageUrl", videoPosterImageFallback)>

		<!--- The WYSIWYG interface does not have different sources. This is only available using XML Directives. If the video is in the db, use the medium source URL --->
		<cfset smallVideoSourceUrl = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "smallVideoSourceUrl", smallVideoSourceUrl)>

		<!--- Medium sized URL --->
		<cfset mediumVideoSourceFallback = (structKeyExists(getPost[1], "MediaUrl") and len(getPost[1]["MediaUrl"])) ? getPost[1]["MediaUrl"] : mediumVideoSourceUrl>
		<cfset mediumVideoSourceUrl = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "mediumVideoSourceUrl", mediumVideoSourceFallback)>

		<cfset largeVideoSourceUrl = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "largeVideoSourceUrl", largeVideoSourceUrl)>

		<!--- Local videos may have captions, however, YouTube and Vimeo will have them embedded in the video --->
		<!--- Bug fix: this previously assigned the MediaVideoVttFileUrl fallback to videoPosterImageUrl instead of videoCaptionsUrl (a copy-paste slip), so a post's caption-track URL silently overwrote the poster image URL instead of populating captions whenever no explicit videoCaptionsUrl XML keyword was present. --->
		<cfset videoCaptionsFallback = (structKeyExists(getPost[1], "MediaVideoVttFileUrl") and len(getPost[1]["MediaVideoVttFileUrl"])) ? getPost[1]["MediaVideoVttFileUrl"] : videoCaptionsUrl>
		<cfset videoCaptionsUrl = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "videoCaptionsUrl", videoCaptionsFallback)>

		<!--- Left as a plain cfif (not collapsed into getXmlOverride): unlike the fields above, videoCrossOrigin has no cfparam default, so it's meant to stay undefined when no XML keyword is present. Routing it through getXmlOverride would always define it (as "" when absent), which could change isDefined("videoCrossOrigin") checks elsewhere. --->
		<cfif findNoCase("videoCrossOrigin", xmlKeywords) gt 0> 
			<cfset videoCrossOrigin = application.blog.getXmlKeywordValue(getPost[1]["PostHeader"], 'videoCrossOrigin')>
		</cfif>

		<!--- Create the video meta tags --->
		<!--- Preset the open graph default values. --->
		<cfset ogVideo = "">
		<cfset ogVideoSecureUrl = "">
		<cfset ogVideoWidth = "">
		<cfset ogVideoHeight = "">

		<!--- If the video type is defined, and this page displaying a single post, create the video meta tags. --->
		<cfif videoType neq "" and getPageMode() eq 'post'>
			<!--- Facebook currently recommends mp4 video at 720p. --->
			<cfset ogVideo = mediumVideoSourceUrl>
			<!--- Both Facebook and Twitter also recommends 1280 x 720 (2048K bitrate). --->
			<cfset ogVideoWidth = "1280">
			<cfset ogVideoHeight = "720">
			<!--- Twitter --->
			<!--- Note: the twitter video length must be under 140 seconds. --->
			<!--- Change the twitter card to player --->
			<cfset twitterCardType = "player">
		</cfif>