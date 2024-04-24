<cfcomponent displayname="Renderer" hint="Functions to render client side code." name="Renderer">
	
	<!--- Note: the bing maps URL changes. For example, the orginal URL was https://www.bing.com, however, Bing is now recommending to use https://sdk.virtualearth.net/ instead due to the way that the browser handles cookies. --->
	<cfset bingMapsUrl = 'https://sdk.virtualearth.net'>	
		
	<!--- //************************************************************************************************
		Helper functions
	//**************************************************************************************************--->
		
	<cffunction name="getIframeDimensions" access="public" returnType="string" output="true"
			hint="Determines the size of the iframe when rendering maps and carousels">
		<cfargument name="renderThumbnail" type="boolean" required="false" default="false">
		<cfargument name="renderMediumCard" type="boolean" required="false" default="false">
			
		<!---To get the dimensions, use something like this:
		<cfset iframeDimensions = this.getIframeDimensions(true,true)>
		<cfset height = getIframeDimensions.height>
		--->
	
		<!--- Set the default iframe dimensions --->
		<cfif arguments.renderThumbnail>
			<cfif arguments.renderMediumCard>
				<cfset width = "615">
				<cfset height = "380"><!--- Corresponds to the k-card-media css declaration --->
			<cfelse>
				<cfset width = "235">
				<cfset height = "130">
			</cfif>
		<cfelse>
			<cfset width = "750">
			<cfset height = "432">
		</cfif>
				
		<cfset dimensions = {width=#width#,height=#height#}>
			
		<cfreturn dimensions>
			
	</cffunction>
		
	<!--- //************************************************************************************************
		Composite post injection functions
	//**************************************************************************************************--->
			
	<cffunction name="renderPost" access="public" returnType="string" output="true"
			hint="Renders html for a post. This will also render the directives from the post header, the enclosure images and media, and the post.">
		<cfargument name="kendoTheme" type="string" required="false" default="">
		<cfargument name="getPost" type="any" required="false" default="">
		<cfargument name="currentRow" type="string" required="false" default="1" hint="If there is more than one row, we may be in blog mode (or category, tag, etc), if there is only one post, we are most likely reading a single post.">
		
		<!--- Extract the needed data from the query --->
		<cfset postHeader = getPost[currentRow]["PostHeader"]>
		<cfset css = getPost[currentRow]["CSS"]>
		<cfset javaScript = getPost[currentRow]["JavaScript"]>
		<cfset body = getPost[currentRow]["Body"]>
			
		<!--- Notes: 
			ColdFish (a CF code syntax library) is no longer included. We are using PrismJs instead
			The more functionality is in the blogContentHtml.cfm template. The MoreBody is now stored in the database making it easier to identify the more blocks.
		--->
			
		<!--- Inspect the post header for reserved xmlKeywords. Here we are looking for cfincludes and video directives. --->
		<cfif len(postHeader)>
			
			<!--- Set vars --->
			<cfset scriptDirective=false>
			<cfset videoDirective=false>
			
			<!--- First things first... I need to allow users to include script tags in the blog entry. My current provider, Hostek, has 'enable global script protection' turned on creating an invalidTag response when submitting code that includes scripts. The following code injects the script tags if the user entered in the folllowing tag: <attachScript> </attachScript>. You can also use <attachScript type="deferjs"> to defer the script. --->
			<cfif findNoCase("<attachScript",postHeader) and findNoCase("</attachScript>",postHeader)>
				<cfset postHeader = replaceNoCase(postHeader, "attachScript", "script", "all")>
				<cfset scriptDirective = true>
			</cfif>	

			<!--- Now inspect they xml keywords for directives. --->
			<cfset xmlKeywords = application.blog.inspectPostContentForXmlKeywords(postHeader)>
			<!---<cfoutput>xmlKeywords: #xmlKeywords#</cfoutput>--->
				
			<!--- Cfinclude. This takes precedent above the enclosure and post. If an include was made, no other post content will be displayed --->
			<cfif findNoCase("cfincludeTemplate", xmlKeywords) gt 0>
				<!--- Inject the include. Note: there is no enclosure or body here. --->
				<cfset cfincludePath = application.blog.getXmlKeywordValue(postHeader, 'cfincludeTemplate')>
				<cfset post = injectCfinclude(cfincludePath)>
				
			<cfelse><!---<cfif findNoCase("cfincludeTemplate", xmlKeywords) gt 0>--->
				
				<!--- Handle video directives. --->				
				<!--- Determine if there are video related directives --->
				<cfif findNoCase("youTubeUrl", xmlKeywords) gt 0> 
					<cfset youTubeUrl = application.blog.getXmlKeywordValue(postHeader, 'youTubeUrl')>
					<cfset videoDirective = true>
				</cfif>
				<cfif findNoCase("vimeoVideoId", xmlKeywords) gt 0> 
					<cfset vimeoVideoId = application.blog.getXmlKeywordValue(postHeader, 'vimeoVideoId')>
					<cfset videoDirective = true>
				</cfif>
				<cfif findNoCase("videoType", xmlKeywords) gt 0> 
					<cfset videoType = application.blog.getXmlKeywordValue(postHeader, 'videoType')>
					<cfset videoDirective = true>
				</cfif>
				<cfif findNoCase("videoPosterImageUrl", xmlKeywords) gt 0> 
					<cfset videoPosterImageUrl = application.blog.getXmlKeywordValue(postHeader, 'videoPosterImageUrl')>
					<cfset videoDirective = true>
				</cfif>	
				<cfif findNoCase("smallVideoSourceUrl", xmlKeywords) gt 0> 
					<cfset smallVideoSourceUrl = application.blog.getXmlKeywordValue(postHeader, 'smallVideoSourceUrl')>
					<cfset videoDirective = true>
				</cfif>
				<cfif findNoCase("mediumVideoSourceUrl", xmlKeywords) gt 0> 
					<cfset mediumVideoSourceUrl = application.blog.getXmlKeywordValue(postHeader, 'mediumVideoSourceUrl')>
					<cfset videoDirective = true>
				</cfif>
				<cfif findNoCase("largeVideoSourceUrl", xmlKeywords) gt 0> 
					<cfset largeVideoSourceUrl = application.blog.getXmlKeywordValue(postHeader, 'largeVideoSourceUrl')>
					<cfset videoDirective = true>
				</cfif>
				<cfif findNoCase("videoCaptionsUrl", xmlKeywords) gt 0> 
					<cfset videoCaptionsUrl = application.blog.getXmlKeywordValue(postHeader, 'videoCaptionsUrl')>
					<cfset videoDirective = true>
				</cfif>
				<cfif findNoCase("videoCrossOrigin", xmlKeywords) gt 0> 
					<cfset videoCrossOrigin = application.blog.getXmlKeywordValue(postHeader, 'videoCrossOrigin')>
					<cfset videoDirective = true>
				</cfif>
					
				<cfif videoDirective>
					<!--- //**************************************************************************************
					Video and Audio Content
					//****************************************************************************************--->
					<cfparam name="videoEnclosure" default="" type="string">
					<cfparam name="videoType" default="" type="string">
					<cfparam name="videoPosterImageUrl" default="" type="string">
					<cfparam name="smallVideoSourceUrl" default="" type="string">
					<cfparam name="mediumVideoSourceUrl" default="" type="string">
					<cfparam name="largeVideoSourceUrl" default="" type="string">
					<cfparam name="videoCaptionsUrl" default="" type="string">
					<!--- Display the video --->
						
					<!--- You Tube videos --->
					<cfif findNoCase("youTubeUrl", xmlKeywords) gt 0>
						<cfsavecontent variable="videoEnclosure">
						<script type="#application.blog.getScriptTypeString()#">
							const mediaplayer#currentRow#Options = {
							  autoplay: false,
							  playsinline: true,
							  clickToPlay: false,
							  controls: ["play", "progress", "mute", "current-time", "mute", "volume", "captions", "settings", "pip", "airplay", "fullscreen"],
							  debug: true,
							  loop: { active: true }
							}

							const mediaplayer#currentRow# = new Plyr('#chr(35)#mediaplayer#currentRow#', mediaplayer#currentRow#Options);
						</script>
						<div class="k-content wide">
							<br/>
							<div id="mediaplayer#currentRow#" data-plyr-embed-id="#youTubeUrl#" data-plyr-provider="youtube" class="mediaPlayer lazy"></div>
						</div>
						</cfsavecontent>
					</cfif><!---<cfif findNoCase("youTubeUrl", xmlKeywords) gt 0>--->

					<!--- Vimeo videos --->
					<cfif findNoCase("vimeoVideoId", xmlKeywords) gt 0>
						<cfsavecontent variable="videoEnclosure">
						<script type="#application.blog.getScriptTypeString()#">
							const mediaplayer#currentRow#Options = {
							  autoplay: false,
							  playsinline: true,
							  clickToPlay: false,
							   controls: ["play", "progress", "mute", "current-time", "mute", "volume", "captions", "settings", "pip", "airplay", "fullscreen"],
							  debug: true,
							  loop: { active: true }
							}

							const mediaplayer#currentRow# = new Plyr('#chr(35)#mediaplayer#currentRow#', mediaplayer#currentRow#Options);
						</script>
						<div class="k-content wide">
							<br/>
							<div id="mediaplayer#currentRow#" data-plyr-provider="vimeo" data-plyr-embed-id="#vimeoVideoId#" class="mediaPlayer lazy"></div>
						</div>
						</cfsavecontent>
						
					</cfif><!---<cfif findNoCase("vimeoVideoId", xmlKeywords) gt 0>--->
						
					<!--- Local videos --->
					<cfif findNoCase("mediumVideoSourceUrl", xmlKeywords) gt 0>
						
						<cfsavecontent variable="videoEnclosure">
						<div id="mediaplayer#currentRow#" class="mediaPlayer">
							<video
								controls
								playsinline
							<cfif len(videoPosterImageUrl)>
								poster="#videoPosterImageUrl#"
							</cfif>
								id="player#currentRow#"
								class="lazy">
								<!-- Sources -->
							<cfif len(smallVideoSourceUrl)>
								<source
									src="#smallVideoSourceUrl#"
									type="video/mp4"
									size="576"
								/></cfif>
							<cfif len(mediumVideoSourceUrl)>
								<source
									src="#mediumVideoSourceUrl#"
									type="video/mp4"
									size="720"
								/></cfif>
							<cfif len(largeVideoSourceUrl)>
								<source
									src="#largeVideoSourceUrl#"
									type="video/mp4"
									size="1080"
								/></cfif>
							<cfif len(videoCaptionsUrl)>
								<!-- Caption files -->
								<track
									kind="captions"
									label="English"
									srclang="en"
									src="#videoCaptionsUrl#"
									default
								/></cfif>
							</video>
						</div>
						</cfsavecontent>
					</cfif>

					<cfif scriptDirective>
						<!--- Render the script, video enclosure and the body--->
						<cfset post = postHeader & videoEnclosure & '<br/>' & renderCssAndScript(css, javaScript) & renderBody(body)>
					<cfelse>
						<!--- Render the video enclosure and body --->
						<cfset post = videoEnclosure & '<br/>' & renderCssAndScript(css, javaScript) & renderBody(body)>
					</cfif>
						
				<cfelse><!---<cfif videoDirective>--->
					
					<!--- This is the standard pathway if there are no cfincludes, attachScripts or video directives. --->
					<!--- Render the enclosure. We need to pass in the kendoTheme, getPost query and the current row. This will render all of the enclosure types- images, video's and maps. --->
					<cfset enclosure = renderEnclosure(arguments.kendoTheme,arguments.getPost,arguments.currentRow)>
					<cfif scriptDirective>
						<!--- Render the postHeader, enclosure and body --->
						<cfif len(enclosure)>
							<cfset post = postHeader & enclosure & '<br/>' & renderCssAndScript(css, javaScript) & renderBody(body)>
						<cfelse>
							<cfset post = postHeader & enclosure & renderCssAndScript(css, javaScript) & renderBody(body)>
						</cfif>
					<cfelse>
						<!--- Render the enclosure and body --->
						<cfif len(enclosure)>
							<cfset post = enclosure & '<br/>' & renderCssAndScript(css, javaScript) & renderBody(body)>
						<cfelse>
							<cfset post = enclosure & renderCssAndScript(css, javaScript) & renderBody(body)>
						</cfif>
					</cfif>
						
				</cfif><!---<cfif videoDirective>--->
				
			</cfif><!---<cfif findNoCase("cfincludeTemplate", xmlKeywords) gt 0>--->
		
		<cfelse><!---<cfif len(postHeader)>--->
			
			<!--- This is the standard pathway if there are no cfinclude or video directives. --->
			<!--- Render the enclosure. We need to pass in the kendoTheme, getPost query and the current row. This will render all of the enclosure types- images, video's and maps. --->
			<cfset enclosure = renderEnclosure(arguments.kendoTheme,arguments.getPost,arguments.currentRow)>
			<!--- Render the body --->
			<cfif len(enclosure)>
				<cfset post = enclosure & '<br/>' & renderCssAndScript(css, javaScript) & renderBody(body)>
			<cfelse>
				<cfset post = enclosure & renderCssAndScript(css, javaScript) & renderBody(body)>
			</cfif>
		</cfif><!---<cfif len(postHeader)>--->

		<!--- Return the entire post --->
		<cfreturn post />
	</cffunction>
				
	<cffunction name="renderPostHeader" returntype="string" output="true"
			hint="This cleans up any changes to the code that ColdFusion's Global Script protection makes to the header">
		<cfargument name="postHeader" type="any" required="yes" hint="Pass in the postHeader">
		<!--- Fix script tags if they exist --->
		<!--- Allow users to include script tags in the blog entry. The following code injects the script tags if the user entered in the folllowing tag: <attachScript> </attachScript>. You can also use <attachScript type="deferjs"> to defer the script. --->
		<cfif findNoCase("<attachScript",arguments.postHeader) and findNoCase("</attachScript>",arguments.postHeader)>
			<cfset postHeader =replaceNoCase(arguments.postHeader, "attachScript", "script", "all")>	
		</cfif>

		<!--- InvalidTag (bypassing CF Global Script Protection) --->
		<cfif findNoCase("InvalidTag",arguments.body)>
			<cfset postHeader = postHeader & replaceNoCase(arguments.postHeader, "InvalidTag", "script", "all")>
		</cfif>
			
		<!--- Return it --->
		<cfreturn postHeader>
	</cffunction>
			
	<cffunction name="renderCssAndScript" returntype="string" output="true"
			hint="Renders any css and or scripts that are attached to a given post">
		<cfargument name="css" type="any" required="no"  default="" hint="The CSS for a post. Stored in the Post.CSS column">
		<cfargument name="javaScript" type="any" required="no" default="" hint="The CSS for a post. Stored in the Post.CSS column">
			
		<cfparam name="thisCssAndScript" default="">
		<cfparam name="thisCss" default="">
		<cfparam name="thisScript" default="">	
			
		<!--- Set the style along with the opening and closing tags --->
		<cfif len(arguments.css)>
			<cfset thisCss = '<style>' & arguments.css & '</style>'>
			<!--- Set the value of the var that will be returned. --->
			<cfset thisCssAndScript = thisCss>
		</cfif>
			
		<!--- Do the same for javascript --->
		<cfif len(arguments.javaScript)>
			<!--- Determine the script type (either javascript or deferjs) --->
			<cfif application.deferScriptsAndCss>
				<!--- Defers the loading of the script and css using the deferjs library. --->
				<cfset scriptTypeString = "deferjs">
			<cfelse>
				<cfset scriptTypeString = "text/javascript">
			</cfif>
			<cfset openingScript = '<script type="' & scriptTypeString & '">'>
			<cfset script = arguments.javaScript>
			<cfset closingScript = '</script>'>
			<cfset thisScript = openingScript & script & closingScript>
			<!--- Set the value of the var that will be returned. --->
			<cfset thisCssAndScript = thisCssAndScript & thisScript>
		</cfif>
			
		<cfreturn thisCssAndScript>
		
	</cffunction>
			
	<cffunction name="renderBody" returntype="string" output="true"
			hint="Renders the the body of the post">
		<cfargument name="body" type="any" required="yes" hint="This takes the body column from the post and injects textblocks if they exist. Note: this does not handle more tag logic. That is done in the blogContentHtml template.">
		
		<!--- Inject text blocks (note: this has not been tested) --->
		<cfset body = injectTextBlocks(arguments.body)>
			
		<cfreturn body>
		
	</cffunction>
		
	<cffunction name="renderEnclosure" returntype="string" output="true"
			hint="Renders the enclosure for the top of the post. This is designed to render all of the media types">
		<cfargument name="kendoTheme" type="any" required="yes" hint="Pass in the kendo theme">
		<cfargument name="getPost" type="any" required="yes" hint="Pass in the getPost HQL query">
		<cfargument name="currentRow" type="any" required="no" default="1" hint="What row of the query to you want extracted? This is needed as the blog may have many rows. Specify 1 if there is only 1 row, otherwise, put in the current row that you want inspected. The default value is 1.">
			
		<!--- Preset the vars --->
		<cfset enclosureHtml=''>
		<cfset mediaId = ''>
		<cfset mediaUrl = ''>
		<cfset mediaPath = ''>
		<cfset mediaType = ''>
		<cfset mimeType = ''>
		<!--- Optional video stuff --->
		<cfset providerVideoId = ''>
		<cfset mediaVideoCoverUrl = ''>
		<cfset mediaVideoVttFileUrl = ''>
		<!--- Maps --->
		<cfset enclosureMapId = ''>
		<!--- Carousel --->
		<cfset enclosureCarouselId = ''>
	
		<!--- There are two references to the media, a path and a URL. The previous versions of BlogCfc did not use the URL so we need to check if the mediaUrl is present and extract it from the path if it does not exist. --->
		<cfset mediaId = getPost[currentRow]["MediaId"]>
		<cfset mediaUrl = getPost[currentRow]["MediaUrl"]>
		<cfset mediaPath = getPost[currentRow]["MediaPath"]>
		<cfset mediaType = getPost[currentRow]["MediaType"]>
		<!--- Note: for external links, the mime type will not be available (YouTube and other media sources don't  always have a easilly read extension) --->
		<cfset mimeType = getPost[currentRow]["MimeType"]>
		<cfif not len(mediaUrl)>
			<!--- We are only getting the path and not the entire URL --->
			<cfset mediaUrl = application.blog.getEnclosureUrlFromMediaPath(mediaPath, true)>
		</cfif>
		<!--- Optional video stuff --->
		<cfset providerVideoId = getPost[currentRow]["ProviderVideoId"]>
		<cfset mediaVideoCoverUrl = getPost[currentRow]["MediaVideoCoverUrl"]>
		<cfset mediaVideoVttFileUrl = getPost[currentRow]["MediaVideoVttFileUrl"]>
		<!--- Maps --->
		<cfset enclosureMapId = getPost[currentRow]["EnclosureMapId"]>
		<!--- Used to determine if there are multiple maps --->
		<cfset enclosureMapCount = getPost[currentRow]["EnclosureMapCount"]>
		<cfset enclosureMapIdList = getPost[currentRow]["EnclosureMapIdList"]>
		<!--- Carousel --->
		<cfset enclosureCarouselId = getPost[currentRow]["enclosureCarouselId"]>

		<!---*********************    Handle the map  *********************--->
				
		<!--- Extract the map id --->
		<cfif len(enclosureMapId)>
			
			<!--- Get the map data --->
			<cfset getMap = application.blog.getMapByMapId(enclosureMapId)>
				
			<!--- If there are multiple maps when looking at the blog on a mobile device, render the maps in an iframe. --->
			<cfif session.isMobile and currentRow gt 1>
				<!--- Render the map inside an iframe if this is a mobile device. Mobile can't handle multiple maps renderMapPreview(mapId, thumbnail, renderKCardMediaClass, renderMediumCard, showSidebar)  --->
				<cfset enclosureHtml = renderMapPreview(enclosureMapId, false)>
			<cfelse>
				<!--- Render the map using the bing maps api --->
				<cfinvoke component="#this#" method="renderMap" returnvariable="enclosureHtml">
					<cfinvokeargument name="kendoTheme" value="#arguments.kendoTheme#">
					<cfinvokeargument name="getMap" value="#getMap#">
					<cfinvokeargument name="enclosureMapIdList" value="#enclosureMapIdList#">
					<cfinvokeargument name="currentRow" value="#arguments.currentRow#">
				</cfinvoke>
			</cfif>
		</cfif>
						
		<!---*********************    Handle the carousel  *********************--->
		<cfif len(enclosureCarouselId)>	
			<!--- Render the carousel using the renderCarousel method: renderCarousel(carouselId,renderCard) --->
			<cfset enclosureHtml = this.renderCarousel(enclosureCarouselId,0)>
		</cfif>
						
		<!---*********************    Handle the enclosure  *********************--->
						
		<cfif len(mediaUrl)>
			<!--- We don't  always have a mime type. External links for example don't  always have a readable extension --->
			<cfif mediaType eq 'Image'>
				<!--- Render the image --->
				<cfinvoke component="#this#" method="renderEnclosureImage" returnvariable="enclosureHtml">
					<cfinvokeargument name="mediaUrl" value="#mediaUrl#">
					<cfinvokeargument name="mediaId" value="#mediaId#">
					<cfinvokeargument name="useFadeClass" value="true">
				</cfinvoke>
				
			<!--- The media type string for video is Video - Large, Video - YouTube URL, etc. All of the video types start with 'Video' --->
			<cfelseif left(mediaType, 5) eq 'Video'>
				<!--- Render the video --->
				<cfinvoke component="#this#" method="renderEnclosureVideo" returnvariable="enclosureHtml">
					<cfinvokeargument name="getPost" value="#getPost#">
					<cfinvokeargument name="currentRow" value="#arguments.currentRow#">
				</cfinvoke>
			</cfif>
		</cfif>
		<!---<cfdump var="#mediaHtml#" label="mediaHtml">--->
			
		<cfreturn enclosureHtml>
			
	</cffunction>
			
	<cffunction name="renderMediaPreview" returntype="string" output="true"
			hint="Renders the media thumbnail for the admin edit post editor page">
		<cfargument name="kendoTheme" type="string" required="yes" hint="Pass in the Kendo Theme">
		<cfargument name="getPost" type="any" required="yes" hint="Pass in the getPost HQL query">
		<cfargument name="renderThumbnail" type="boolean" required="yes" hint="You can render a preview for the tinymce editor or a thumbnail">
		<cfargument name="showSidebar" type="boolean" required="false" default="false" hint="When the sidebar is shown, the popular posts cards need a separate class than the rest of the cards.">
		<!---Debugging: <cfdump var="#getPost#">--->
			
		<cfparam name="thumbnailHtml" default="">
	
		<!---*********************     Handle media thumbnail      *********************--->
		<!--- There are two references to the media, a path and a URL. The previous versions of BlogCfc did not use the URL so we need to check if the mediaUrl is present and extract it from the path if it does not exist. --->
		<cfset mediaId = getPost[1]["MediaId"]>
		<cfset mediaUrl = getPost[1]["MediaUrl"]>
		<cfset thumbnailUrl = getPost[1]["MediaThumbnailUrl"]>
		<cfset mediaPath = getPost[1]["MediaPath"]>
		<cfset mediaType = getPost[1]["MediaType"]>
		<!--- Note: for external links, the mime type will not be available (YouTube and other media sources don't always have a easilly read extension) --->
		<cfset mimeType = getPost[1]["MimeType"]>
		<cfif not len(mediaUrl)>
			<!--- We are only getting the path and not the entire URL --->
			<cfset mediaUrl = application.blog.getEnclosureUrlFromMediaPath(mediaPath, true)>
		</cfif>
		<!--- Optional video stuff --->
		<cfset providerVideoId = getPost[1]["ProviderVideoId"]>
		<cfset mediaVideoCoverUrl = getPost[1]["MediaVideoCoverUrl"]>
		<cfset mediaVideoVttFileUrl = getPost[1]["MediaVideoVttFileUrl"]>
		<!--- Maps --->
		<cfset enclosureMapId = getPost[1]["EnclosureMapId"]>
		<!--- Carousel --->
		<cfset enclosureCarouselId = getPost[1]["EnclosureCarouselId"]>

		<cfif len(mediaUrl)>
			<!--- We don't  always have a mime type. External links for example don't  always have a readable extension --->
			<cfif mediaType eq 'Image' and arguments.renderThumbnail>
				<!--- Determine if the image is self hosted or from an external source. --->
				<cfif len(thumbnailUrl)>
					<cfset thumnailSource = thumbnailUrl>
				<cfelse>
					<cfset thumnailSource = mediaUrl>
				</cfif>
				<!--- Render the image HTML string --->
				<cfset thumbnailHtml = '<a class="fancybox-effects" aria-label="Thumnail Image Url" onClick="javascript:createAdminInterfaceWindow(13,' & URL.optArgs & ')"><img id="thumbnailImage" data-src="' & thumnailSource & '" alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="' & thumnailSource & '"></a>'>
			<!--- The media type string for video is Video - Large, Video - YouTube URL, etc. All of the video types start with 'Video' --->
			<cfelseif left(mediaType, 5) eq 'Video'>
				<!--- Note: this will return an iframe. --->
				<cfinvoke component="#this#" method="renderEnclosureVideoPreview" returnvariable="thumbnailHtml">
					<cfinvokeargument name="mediaId" value="#mediaId#">
					<cfinvokeargument name="mediaUrl" value="#mediaUrl#">
					<cfinvokeargument name="providerVideoId" value="#providerVideoId#">
					<cfinvokeargument name="posterUrl" value="#mediaVideoCoverUrl#">
					<cfinvokeargument name="videoCaptionsUrl" value="#mediaVideoVttFileUrl#">
					<cfinvokeargument name="renderThumbnail" value="#arguments.renderThumbnail#">
					<cfinvokeargument name="showSidebar" value="#arguments.showSidebar#">
				</cfinvoke>
			</cfif>
		</cfif><!---<cfif len(mediaUrl)>--->
		<!---<cfdump var="#mediaHtml#" label="mediaHtml">--->

		<!---*********************    Handle the map  *********************--->
		<!--- Extract the map id --->
		<cfif len(enclosureMapId)>
			<!--- Render the map. This returns a iframe. When renderMediumCard is true, a large map will be rendered. renderMapPreview(mapId, thumbnail, renderKCardMediaClass, renderMediumCard, showSidebar). --->
			<cfset thumbnailHtml = renderMapPreview(enclosureMapId, arguments.renderThumbnail, false, false, false)>
		</cfif>
		
		<!---******************    Handle the carousel  ******************--->
		<cfif len(enclosureCarouselId)>
			<!--- Get the HTML for this carousel. renderCarouselPreview(carouselId, interface) --->
			<cfset thumbnailHtml = this.renderCarouselPreview(enclosureCarouselId,'postEditor')>
		</cfif>
			
		<!--- Insert an circular image with a line to indicate that the media does not exist for this post. --->
		<cfif renderThumbnail and thumbnailHtml eq ''>
			<cfset thumbnailHtml = '<a class="fancybox-effects" aria-label="Thumnail Image Url" onClick="javascript:createAdminInterfaceWindow(13,' & URL.optArgs & ')"><img id="thumbnailImage" data-src="#application.baseUrl#/images/icons/noMedia.png" alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="#application.baseUrl#/images/icons/noMedia.png"></a>'>
		</cfif>
			
		<cfreturn thumbnailHtml>
			
	</cffunction>
	
	<cffunction name="renderThumnail" returntype="string" output="true"
			hint="Renders a thumbnail">
		<cfargument name="url" type="string" required="yes">
	
		<cfset thumbNailHtml = '<a class="fancybox-effects" aria-label="Image URL" href="<cfoutput>#arguments.url#</cfoutput>"><img data-src="<cfoutput>#arguments.url#</cfoutput>" alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="<cfoutput>#arguments.url#</cfoutput>"></a>'>
		
		<cfreturn thumbNailHtml>
				
	</cffunction>
			
	<!--- //************************************************************************************************
		Independent functions
	//**************************************************************************************************--->
			
	<!--- Functions to handle strings that are formatted to bypass CF's Global Script Protection --->
	<cffunction name="renderScriptsToDb" returntype="string" output="false" hint="Not used yet!">
		<cfargument name="str" type="string" required="yes">
			
		<!--- Replaces the comment outside of the script tags. The comment is necessary to render the script in the tinymce editor. This may occur when the user is editting an existing post with a script. --->
		<cfif findNoCase("<!--<attachScript",str) and findNoCase("</attachScript>-->",str)>
			<!--- Replace the opening comment --->
			<cfset str = replaceNoCase(str, "<!--<attachScript", "<script", "all")>
			<!--- Replace the end comment --->
			<cfset str = replaceNoCase(str, "</attachScript>-->", "</script>", "all")>
		</cfif>
		<!--- Replaces <attachScript with <script. This may occur when a new post is made with a script. --->
		<cfif findNoCase("<attachScript",str) and findNoCase("</attachScript>",str)>
			<cfset str = replaceNoCase(str, "attachScript", "script", "all")>
		</cfif>	
		<!--- Allows for style sheets. --->
		<cfif findNoCase("<attachStyle",str) and findNoCase("</attachStyle>",str)>
			<cfset str = replaceNoCase(str, "attachStyle", "style", "all")>
		</cfif>
			
		<cfreturn str>
	</cffunction>
			
	<cffunction name="renderScriptsToTinyMce" returntype="string" output="false" 
			hint="Renders script tags surrounded by HTML comments before sending to TinyMce. TinyMce does not allow scripts to be inside of the setContent method which we use so we need to escape theme.">
		<cfargument name="str" type="string" required="yes">
			
		<cfif str contains '<script' and str contains '</script>'>
			<!--- Put comments around the opening tag --->
			<cfset str = replaceNoCase(str,'<script','<!--<script','all')>
			<!--- and the closing tag --->
			<cfset str = replaceNoCase(str,'</script>','</script>-->','all')>
		</cfif>
		<cfreturn str>
			
	</cffunction>
			
	<!--- Fix tinymce limitations that require us to use comments and symbols around custom HTML tags. --->
	<cffunction name="renderMoreTagFromTinyMce" returntype="string" output="false" 
			hint="Renders the more tag when it is encountered. We can't use <more> in the tinymce editor as it will remove it, so we are surrounding the more tag with &lt; and &gt;. We also can surround it using an HTML comment">
		<cfargument name="str" type="string" required="yes">
		
		<!--- Depracated cases when there are &lt; + &gt; codes --->
		<cfif findNoCase(arguments.str, '&lt;more/&gt;')>
			<cfset arguments.str = replaceNoCase(arguments.str, '&lt;more/&gt;', '<more/>', 'all')>
		</cfif>
			
		<!--- New more logic. TinyMce puts in a closing more tag --->
		<cfif findNoCase(arguments.str, '<more>') and findNoCase(arguments.str, '</more>')>
			<cfset arguments.str = replaceNoCase(arguments.str, '<more></more>', '<more/>', 'all')>
		</cfif>
			
		<cfreturn arguments.str>
	</cffunction>
			
	<cffunction name="injectCfinclude" returntype="string" output="true"
			hint="Note: this function takes precendent over all other post content functions">
		<cfargument name="cfincludeTemplatePath" type="string" required="yes" default="" hint="template path to include">

		<!--- Include the specified template. --->
		<cfsavecontent variable="cfinclude">
			<cftry>
				<cfinclude template="#arguments.cfincludeTemplatePath#">
				<cfcatch type="any">
					Error with cfinclude: <cfoutput>#cfcatch.message#<br/>#cfcatch.detail#</cfoutput>
				</cfcatch>
			</cftry>
		</cfsavecontent>			
			
		<cfreturn cfinclude>
			
	</cffunction>
			
	<cffunction name="injectTextBlocks" returntype="string" output="true"
			hint="Allows for textblocks in the post body">
		<cfargument name="body" type="string" required="yes" hint="Pass in the post body.">
			
		<!--- Preset stuff --->
		<cfset var counter = "">
		<cfset var codeblock = "">
		<cfset var codeportion = "">
		<cfset var result = "">
		<cfset var newbody = "">
			
		<!--- Regex to determine if a text block is in post --->
		<cfset tbRegex = "<textblock[[:space:]]+label[[:space:]]*=[[:space:]]*""(.*?)"">">
		<cfif reFindNoCase(tbRegex,arguments.body)>
			<cfset counter = reFindNoCase(tbRegex,arguments.body)>
			<cfloop condition="counter gte 1">
				<cfset textblock = reFindNoCase(tbRegex,arguments.body,1,1)>
				<cfif arrayLen(textblock.pos) is 2>
					<cfset textblockTag = mid(arguments.body, textblock.pos[1], textblock.len[1])>
					<cfset textblockLabel = mid(arguments.body, textblock.pos[2], textblock.len[2])>
					<cfset newContent = variables.textblock.getTextBlockContent(textblockLabel)>
					<cfset newBody = replaceNoCase(arguments.body, textblockTag, newContent)>
				</cfif>
				<cfset counter = reFindNoCase(tbRegex,arguments.string, counter)>
			</cfloop>
		<cfelse>
			<cfset newBody = arguments.body>
		</cfif>
			
		<cfreturn newBody>
			
	</cffunction>
	
	<cffunction name="renderImage" returntype="string" output="true"
			hint="Renders an image. This is used on all images, not just an enclosure image.">
		<cfargument name="imageUrl" type="string" required="yes">
		<cfargument name="mediaId" type="string" required="no" hint="Only pass this when a mediaId exists. This will often be null for generic images as it is not stored into the media table, such as a map location cursor.">
		<cfargument name="useFadeClass" type="boolean" required="no" default="false" hint="The front blog page uses a fade class to fade the images in when the image is in the viewport. This should not be used if you're trying to use the image in the tinymce editor.">
			
		<cfparam name="imageHtmlStr" default="">
		
		<!--- Now that we have the proper path, build the HTML string --->
		<cfif len(arguments.imageUrl) and listFindNoCase("gif,jpg,png,webp", listLast(arguments.imageUrl, "."))>
			<!--- Wrap the image with the entryImage class. I am also lazy loading this now and constraining the image with .css. Note: I am decoding the image URL as it won't work with the lazy loading approach if it is encoded. --->
			<cfif useFadeClass>
				<cfset mediaHtmlStr = "<div class=""entryImage""><img class=""fade"" data-type=""image"" data-id=""#arguments.mediaId#"" data-src=""#arguments.imageUrl#"" alt=""""></div>">
			<cfelse>
				<cfset mediaHtmlStr = "<div class=""entryImage""><img src=""#arguments.imageUrl#"" alt=""""></div>">
			</cfif>
		</cfif>
			
		<cfreturn imageHtmlStr>
				
	</cffunction>
	
	<cffunction name="renderEnclosureImage" returntype="string" output="true"
			hint="Renders the enclosure image at the top of a post">
		<cfargument name="mediaUrl" type="string" required="yes">
		<cfargument name="mediaId" type="string" default="" required="no">
		<cfargument name="useFadeClass" type="boolean" required="no" default="false" hint="The front blog page uses a fade class to fade the images in when the image is in the viewport. This should not be used if you're trying to use the image in the tinymce editor.">
			
		<cfparam name="mediaHtmlStr" default="">
		
		<!--- Now that we have the proper path, build the HTML string --->
		<cfif len(arguments.mediaUrl)>
			<!--- Wrap the image with the entryImage class. I am also lazy loading this now and constraining the image with .css. Note: I am decoding the image URL as it won't work with the lazy loading approach if it is encoded. --->
			<cfif useFadeClass>
				<cfset mediaHtmlStr = "<div class=""entryImage""><img class=""fade"" data-type=""image"" data-id=""#arguments.mediaId#"" data-src=""#arguments.mediaUrl#"" alt=""""></div>">
			<cfelse>
				<cfset mediaHtmlStr = "<div class=""entryImage""><img data-type=""image"" data-id=""#arguments.mediaId#"" src=""#arguments.mediaUrl#"" alt=""""></div>">
			</cfif>
		</cfif>
			
		<cfreturn mediaHtmlStr>
				
	</cffunction>
					
	<cffunction name="renderImageGalleryPreview" returntype="string" output="true"
			hint="Renders a gallery preview within an iframe. This is used in the tinymce editor.">
		<cfargument name="galleryId" type="string" required="yes">
		<cfargument name="numImages" type="numeric" required="yes">
		<cfargument name="darkTheme" type="boolean" default="false" required="no">
			
		<cfparam name="width" default="750">
			
		<!--- Set the height based upon the number of images. --->
		<cfset baseHeight = 150>
		<cfif numImages lte 3>
			<cfset height = baseHeight>
		<cfelseif numImages gt 3 and numImages lte 6>
			<cfset height = (baseHeight * 2)>
		<cfelseif numImages gt 6 and numImages lte 9>
			<cfset height = (baseHeight * 3)>
		<cfelseif numImages gt 9 and numImages lte 12>
			<cfset height = (baseHeight * 4)>
		</cfif>
			
		<!--- Create a custom tag and iframe --->
		<cfset galleryHtmlStr = '<div data-type="gallery" data-id="' & arguments.galleryId & '" onDblClick="createAdminInterfaceWindow(14,' & galleryId & ')">'>
		<cfset galleryHtmlStr = galleryHtmlStr & '<iframe title="gallery" data-type="gallery" data-id="#arguments.galleryId#" src="#application.baseUrl#/preview/gallery.cfm?galleryId=' & arguments.galleryId & '&darkTheme=' & arguments.darkTheme>
		<cfset galleryHtmlStr = galleryHtmlStr & '" width="' & width & '" height="' & height & '" allowfullscreen="allowfullscreen" frameBorder="0" scrolling="no"></iframe></div'>
			
		<cfreturn galleryHtmlStr>
	
	</cffunction>
			
	<cffunction name="renderEnclosureVideo" returntype="string" output="true"
			hint="Renders the enclosure video at the top of a post">
		<cfargument name="getPost" type="any" required="yes">
		<cfargument name="currentRow" type="any" required="no" default="1" hint="What row of the query to you want extracted? This is needed as the blog may have many rows. Specify 1 if there is only 1 row, otherwise, put in the current row that you want inspected. The default value is 1.">
			
		<!--- Preset and populate the data --->
		<!--- Set everything to null --->
		<cfset mediaId = ''>
		<cfset mediaUrl = ''>
		<cfset mediaPath = ''>
		<cfset mediaType = ''>
		<!--- Optional video stuff --->
		<cfset providerVideoId = ''>
		<cfset mediaVideoCoverUrl = ''>
		<cfset mediaVideoVttFileUrl = ''>
			
		<!--- Populate the vars from the db --->
		<cfset mediaId = getPost[currentRow]["MediaId"]>
		<cfset mediaUrl = getPost[currentRow]["MediaUrl"]>
		<cfset mediaPath = getPost[currentRow]["MediaPath"]>
		<cfif not len(mediaUrl)>
			<!--- We are only getting the path and not the entire URL --->
			<cfset mediaUrl = application.blog.getEnclosureUrlFromMediaPath(mediaPath, true)>
		</cfif>
		<cfset mediaType = getPost[currentRow]["MediaType"]>
		<!--- Optional video stuff --->
		<cfset providerVideoId = getPost[currentRow]["ProviderVideoId"]>
		<cfset mediaVideoCoverUrl = getPost[currentRow]["MediaVideoCoverUrl"]>
		<cfset mediaVideoVttFileUrl = getPost[currentRow]["MediaVideoVttFileUrl"]>
			
		<!---Debugging: <cfoutput>currentRow: #currentRow# mediaId: #mediaId# mediaUrl: #mediaUrl#</cfoutput>--->
		<cfif mediaType eq 'Video - Vimeo URL'>
			
			<cfsavecontent variable="videoHtml">
				<cfoutput>
				<script type="#application.blog.getScriptTypeString()#">
					const mediaplayer#mediaId#Options = {
					  // Autoplay when in post mode. don't  autoplay in blog mode.
					  autoplay: false,
					  playsinline: true,
					  clickToPlay: false,
					   controls: ["play", "progress", "mute", "current-time", "mute", "volume", "captions", "settings", "pip", "airplay", "fullscreen"],
					  debug: true,
					  loop: { active: true }
					}

					const mediaplayer#mediaId# = new Plyr('#chr(35)#mediaplayer#mediaId#', mediaplayer#mediaId#Options);
				</script>
				<div class="k-content wide">
					<br/>
					<div id="mediaplayer#mediaId#" data-plyr-provider="vimeo" data-plyr-embed-id="#providerVideoId#" class="mediaPlayer lazy"></div>
				</div>
				</cfoutput>
			</cfsavecontent>
			
		<cfelseif mediaType eq 'Video - YouTube URL'>
			
			<cfsavecontent variable="videoHtml">
				<cfoutput>
				<script type="#application.blog.getScriptTypeString()#">
					const mediaplayer#mediaId#Options = {
					  // Autoplay when in post mode. don't  autoplay in blog mode.
					  autoplay: false,
					  playsinline: true,
					  clickToPlay: false,
					  controls: ["play", "progress", "mute", "current-time", "mute", "volume", "captions", "settings", "pip", "airplay", "fullscreen"],
					  debug: true,
					  loop: { active: true }
					}

					const mediaplayer#mediaId# = new Plyr('#chr(35)#mediaplayer#mediaId#', mediaplayer#mediaId#Options);
				</script>
				<div class="k-content wide">
					<br/>
					<div id="mediaplayer#mediaId#" data-plyr-embed-id="#providerVideoId#" data-plyr-provider="youtube" class="mediaPlayer lazy"></div>
				</div>
				</cfoutput>
			</cfsavecontent>
			
		<cfelse>
			
			<cfsavecontent variable="videoHtml">
				<cfoutput>
				<script type="#application.blog.getScriptTypeString()#">
					const mediaplayer#mediaId#Options = {
					  autoplay: false,
					  playsinline: true,
					  clickToPlay: false,
					  controls: ["play", "progress", "mute", "current-time", "mute", "volume", "captions", "settings", "pip", "airplay", "fullscreen"],
					  debug: true,
					  loop: { active: true }
					}

					const mediaplayer#mediaId# = new Plyr('#chr(35)#mediaplayer#mediaId#', mediaplayer#mediaId#Options);
				</script>
				<div id="mediaPlayer#mediaId#" class="mediaPlayer">
					<video
						controls
						crossorigin
						playsinline
						<cfif mediaVideoCoverUrl neq ''>poster="#mediaVideoCoverUrl#"</cfif>
						id="mediaPlayer#mediaId#"
						preload="metadata"
						class="lazy">
						<!-- Video files -->
						<source
							src="#mediaUrl#"
							type="video/mp4"
							/>
						<cfif mediaVideoVttFileUrl neq "">
						<!-- Caption files -->
						<track
							kind="captions"
							label="English"
							srclang="en"
							src="#mediaVideoVttFileUrl#"
							default
						/>
						</cfif>
						<!-- Fallback for browsers that don't  support the <video> element -->
						<a href="#mediaUrl#" download>Download</a>
					</video>
				</div>
				</cfoutput>
			</cfsavecontent>
			
		</cfif>
			
		<cfreturn videoHtml>
	</cffunction>
					
	<cffunction name="renderEnclosureVideoPreview" returntype="string" output="true"
			hint="Renders the enclosure video at the top of a post">
		<cfargument name="mediaUrl" type="string" required="yes">
		<!--- Optional args --->
		<cfargument name="mediaId" type="string" required="no">
		<cfargument name="provider" default="" type="string" required="no">
		<cfargument name="providerVideoId" default="" type="string" required="no">
		<cfargument name="posterUrl"  default="" type="string" required="no">
		<cfargument name="videoCaptionsUrl" default="" type="string" required="no">
		<cfargument name="renderThumbnail" type="boolean" required="no" default="false">
		<cfargument name="renderKCardMediaClass" type="boolean" required="no" default="false">
		<cfargument name="renderMediumCard" type="boolean" required="no" default="false">
		<cfargument name="showSidebar" type="boolean" required="no" default="false" hint="determines the class of the thumbnail presentation">
		
			
		<!--- Set a shorter kCard var for the URL. We don't want to pass in renderKCardMediaClass in the URL --->
		<cfif arguments.renderKCardMediaClass>
			<cfset kcard = true>
		<cfelse>
			<cfset kcard = false>
		</cfif>
			
		<!--- Set the default iframe dimensions --->
		<cfif arguments.renderThumbnail>
			<cfif arguments.renderMediumCard>
				<cfset width = "615">
				<cfset height = "380"><!--- Corresponds to the k-card-media css declaration --->
			<cfelse>
				<cfset width = "235">
				<cfset height = "130">
			</cfif>
		<cfelse>
			<cfset width = "750">
			<cfset height = "432">
		</cfif>
				
		<!--- When the sidebar is shown, we want to use the k-card-scroll-image for the popular posts at the top of the page. Otherwise, use the k-card-media class since all of the card sizes will be the same for both popular and the main posts. --->
		<cfif arguments.renderMediumCard><!---Changed from  <cfif arguments.showSidebar and not arguments.renderMediumCard>---> 
			<cfset kCardVideoClass = "k-card-media">
		<cfelse>
			<cfset kCardVideoClass = "k-card-scroll-image">
		</cfif>
			
		<!--- Note: we will not have an extension that we can read on an external URL --->
		<cfset mediaHtmlStr = '<iframe title="media player" data-type="video" data-id="#arguments.mediaId#" src="#application.baseUrl#/galaxiePlayer.cfm?videoUrl=' & arguments.mediaUrl & '&thumbnail=' & renderThumbnail & '&kcard=' & kcard>
		<cfif len(arguments.provider) and len(arguments.providerVideoId)>
			<cfset mediaHtmlStr = mediaHtmlStr & '&provider=' & arguments.provider & '&providerVideoId=' & arguments.providerVideoId>
		</cfif>
		<cfif len(arguments.posterUrl)>
			<cfset mediaHtmlStr = mediaHtmlStr & '&posterUrl=' & arguments.posterUrl>
		</cfif>
		<cfif len(arguments.videoCaptionsUrl)>
			<cfset mediaHtmlStr = mediaHtmlStr & '&videoCaptionsUrl=' & arguments.videoCaptionsUrl>
		</cfif>
		<cfif renderKCardMediaClass>
			<!--- Height is missing here and the k-card-media class is used. --->
			<cfset mediaHtmlStr = mediaHtmlStr & '" width="' & width & '" allowfullscreen="allowfullscreen" class="' & kCardVideoClass & '" frameBorder="0" scrolling="no"></iframe>'>
		<cfelse>
			<cfset mediaHtmlStr = mediaHtmlStr & '" width="' & width &'" height="' & height & '" allowfullscreen="allowfullscreen" frameBorder="0" scrolling="no"></iframe>'>
		</cfif>
		
		<cfreturn mediaHtmlStr>
	
	</cffunction>
			
	<cffunction name="renderImageGalleryFromDb" returntype="string" output="true"
			hint="Renders the HTML for an image gallery via the database. This is used to insert the code into the databasepreview the gallery in the tinymce editor.">
		<cfargument name="mediaGalleryId" type="string" required="yes">
		<cfargument name="generateTinyMcePreview" type="boolean" required="no" default="false">
			
		<cfset generateTinyMcePreview = false>
		<!--- 
		Load the media gallery table for debugging purposes:
		<cfset MediaGalleryDbObj = entityLoadByPK("MediaGallery", URL.mediaGalleryId)>
		<cfdump var="#MediaGalleryDbObj#">
		--->

		<!--- Get the media gallery items --->
		<cfquery name="getGallery" dbtype="hql">
			SELECT new Map (
				MediaGallery.MediaGalleryId as MediaGalleryId,
				MediaGallery.MediaGalleryName as MediaGalleryName,
				MediaGallery.MediaGalleryTitle as MediaGalleryTitle,
				MediaGalleryItem.MediaGalleryItemId as MediaGalleryItemId,
				MediaGalleryItem.MediaGalleryItemTitle as MediaGalleryItemTitle,
				Media.MediaId as MediaId,
				Media.MediaUrl as MediaUrl,
				Media.MediaThumbnailUrl as MediaThumbnailUrl
			)
			FROM MediaGallery as MediaGallery
			JOIN MediaGallery.MediaGalleryItems as MediaGalleryItem
			JOIN MediaGalleryItem.MediaRef as Media
			WHERE MediaGallery.MediaGalleryId = <cfqueryparam value="#arguments.mediaGalleryId#">
		</cfquery>
			
		<!--- Create the final HTML. It should look something like this:
		<a class="fancybox-effects" href="/blog/images/documentation/cfimage/tobyOrig.jpg" data-fancybox-group="toby" title="Original Image"><img data-src="/blog/images/documentation/cfimage/tobyOrigThumb.jpg" alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="/blog/images/documentation/cfimage/tobyOrigThumb.jpg"></a>
		--->	
		<cfloop from="1" to="#arrayLen(getGallery)#" index="i">
			<cfset galleryId = getGallery[i]["MediaGalleryId"]>
			<cfset galleryName = getGallery[i]["MediaGalleryName"]>
			<cfset galleryTitle = getGallery[i]["MediaGalleryTitle"]>
			<cfset galleryItemId = getGallery[i]["MediaGalleryItemId"]>
			<cfset galleryItemTitle = getGallery[i]["MediaGalleryItemTitle"]>
			<cfset galleryItemThumbnailUrl = getGallery[i]["MediaThumbnailUrl"]>
			<cfif generateTinyMcePreview>
				<cfset galleryItemLink = "createAdminInterfaceWindow(14," & galleryId & ");">
			<cfelse>
				<cfset galleryItemLink = getGallery[i]["MediaUrl"]>
			</cfif>

			<!--- Wrap the gallery with a '<gallery>' tag --->
			<cfif i eq 1>
				<cfset htmlStr = '<gallery data-galleryid="#galleryId#" data-name="' & galleryName & '">'>	
			</cfif>	
			<!--- Construct our anchor tag. --->
			<cfif generateTinyMcePreview>
				<cfset htmlStr = htmlStr & '<a aria-label="Image Link" class="fancybox-effects" data-fancybox-group="' & galleryName & '" title="' & galleryItemTitle & '" onDblClick="javascript:' & galleryItemLink & '">'>
			<cfelse>
				<cfset htmlStr = htmlStr & '<a aria-label="Image Link" class="fancybox-effects" href="' & galleryItemLink & '" data-fancybox-group="' & galleryName & '" title="' & galleryItemTitle & '">'>
			</cfif>
			
			<!--- And now construct the image --->
			<cfset htmlStr = htmlStr & '<img data-src="' & galleryItemThumbnailUrl & '" data-galleryid="' & galleryId & '" data-galleryitemid="' & galleryItemId & '"  alt="" class="fade thumbnail lazied shown" data-lazied="IMG" src="' & galleryItemThumbnailUrl & '"></a>'>
			<!--- Create the end gallery tag --->
			<cfif i eq arrayLen(getGallery)>
				<cfset htmlStr = htmlStr & '</gallery>'>
			</cfif>

		</cfloop><!---<cfloop from="1" to="#arrayLen(getGallery)#" index="i">--->
				
		<!--- Return the HTML --->
		<cfreturn htmlStr>
	
	</cffunction>
				
	<cffunction name="renderCarousel" returntype="string" output="true"
			hint="Renders a carousel">
		<cfargument name="carouselId" type="string" required="yes">
		<cfargument name="card" type="boolean" required="no" default="false">
		<cfargument name="width" type="any" required="no" default="100%">
		<cfargument name="height" type="any" required="no" default="">
			
		<cfparam name="debug" default="false">
		
		<!--- Preset the return value --->
		<cfparam name="carouselHtml" default="">
			
		<!--- Get the theme in order to get the font properties --->
		<cfset themeAlias = application.blog.getSelectedThemeAlias()>
			
		<!--- Preset carousel height when not sent in --->
		<cfif not len(arguments.height)>
			<cfif arguments.card eq true>
				<cfset height = "150px">
			<cfelse>
				<cfset height = "534px">
			</cfif>
		</cfif>
					
		<!--- Set the width when using card layout --->
		<cfif not len(arguments.width) and arguments.card>
			<cfset width = "295px">
		</cfif>
			
		<!--- Get the theme related font --->
		<cfquery name="getTheme" dbtype="hql">
			SELECT new Map (
				KendoThemeRef.KendoTheme as KendoTheme,
				ThemeSettingRef.BlogNameFontRef as BlogNameFontRef,
				ThemeSettingRef.FontRef.Font as Font
			)
			FROM 
				Theme as Theme
			WHERE Theme.ThemeAlias = <cfqueryparam value="#themeAlias#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<!--- Get the theme related font info --->
		<cfset getBlogNameFont = application.blog.getFont(fontId=getTheme[1]["BlogNameFontRef"])>

		<cfif arrayLen(getBlogNameFont)>
			<cfset blogNameFont = getBlogNameFont[1]["Font"]>
			<cfset blogNameFontType = getBlogNameFont[1]["FontType"]>
		<cfelse>
			<cfset blogNameFont = ''>
			<cfset blogNameFontType = ''>
		</cfif>
		
		<!--- Set the Kendo Theme --->
		<cfset kendoTheme = getTheme[1]["KendoTheme"]>
			
		<cfset alternateBgColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'alternateBgColor')>
			
		<!--- Get the data --->
		<cfset getCarousel = application.blog.getCarousel(arguments.carouselId)>
			
		<!--- Don't proceed if there is no data --->
		<cfif arrayLen(getCarousel)>
			<!--- Set the global vars --->
			<cfset carouselEffect = getCarousel[1]["CarouselEffect"]><!---This is always GL for now.--->
			<cfset carouselShader = getCarousel[1]["CarouselShader"]>
			<!--- Font properties --->
			<cfset carouselFont = getCarousel[1]["Font"]>
			<cfset carouselItemTitleFontColor = getCarousel[1]["CarouselItemTitleFontColor"]>
			<cfset carouselItemTitleFontSize = getCarousel[1]["CarouselItemTitleFontSize"]>
			<cfset carouselItemBodyFontColor = getCarousel[1]["CarouselItemBodyFontColor"]>
			<cfset carouselItemBodyFontSize = getCarousel[1]["CarouselItemBodyFontSize"]>

			<!--- Create the HTML --->
			<cfsavecontent variable="carouselHtml">
				<!---<cfdump var="#getCarousel#">--->
				<cfif debug>Debug card: #card# width: #width# height: #height#</cfif>
				<style>
					/** Swiper styles **/
					:root {
						--swiper-pagination-color: <cfoutput>#chr(35)#</cfoutput>FFF;
						--swiper-pagination-bullet-inactive-color: <cfoutput>#chr(35)#</cfoutput>FFF;
					}

					.swiper {
						user-select: none;
						box-sizing: border-box;
						overflow: hidden;
						width: <cfoutput>#width#</cfoutput>;/*was 100%*/
						height: <cfoutput>#height#</cfoutput>;/*height should always be set, was 534px*/
						padding: 0px 0px;
					}

					.swiper-slide {
						display: flex;
						align-items: center;
						justify-content: center;
						width: 100%;
						height: height:<cfoutput>#height#</cfoutput>;/*height should always be set, was 534px*/
						position: relative;
						box-sizing: border-box;
						overflow: hidden;
						border-radius: 0px;
					}

					.swiper-slide-content {
						width: 100%;/* Container width */
						height: 100%;/* Container height */
						display: flex;
						flex-direction: column;
						position: relative;
						z-index: 1;
						box-sizing: border-box;
						padding: 48px 48px;
						align-items: flex-start;
						justify-content: flex-end;
						transform: translate3d(0, 0, 0);
					}

					.swiper-slide-title {
						/* The blog title at the top of the page */
						font-family: <cfoutput>'#blogNameFont#', #BlogNameFontType#</cfoutput>; 
						font-size: <cfoutput><cfif session.isMobile>18<cfelse>32</cfif></cfoutput>px; 
						/* The container may need to have some padding as the menu underneath it is not going to left align with the text since the menu is going to start prior to the first text item. */
						padding-left: 13px; 
						text-shadow: 0px 4px 8px rgba(0, 0, 0, 0.19); /* The drop shadow should closely mimick the shadow on the main blog layer.*/
						color: <cfoutput>#carouselItemTitleFontColor#</cfoutput>;
					}

					.swiper-slide-text {
						/* max-width: 640px; */
						font-size: <cfoutput>#carouselItemBodyFontSize#</cfoutput>px;
						line-height: 1.4;
						transform-origin: left bottom;
						color: <cfoutput>#carouselItemBodyFontColor#</cfoutput>;
					}

					.swiper-slide-title + .swiper-slide-text {
						margin-top: 8px;
					}

					.swiper-slide-image {
						border-radius: 0px;
						position: absolute;
						object-fit: cover;
						left: -10%;
						top: -10%;
						width: 120%;
						height: 120%;
						z-index: 0;
					}
					
					/* back button */
					.swiper-button-next:after,.swiper-button-next:after {
						color: azure
					}
					/* forward button */
					.swiper-button-next:after,.swiper-button-prev:after {
						color: azure
					}
				</style>
				
				<div class="swiper">
					<div class="swiper-wrapper">
						<cfloop from="1" to="#arrayLen(getCarousel)#" index="i">
						<cfsilent>
						<!--- Set the variable values. I want to shorten the long variable names here. --->
						<!--- In card mode, grab the small thumbnail image. --->
						<cfif arguments.card>
							<cfset carouselItemMediaUrl = getCarousel[i]["MediaThumbnailUrl"]>
						<cfelse>
							<cfset carouselItemMediaUrl = getCarousel[i]["MediaUrl"]>
						</cfif>
						<cfset carouselItemTitle = getCarousel[i]["CarouselItemTitle"]>
						<cfset carouselItemBody = getCarousel[i]["CarouselItemBody"]>
						</cfsilent>
						<div class="swiper-slide">
							
							<img id="cid<cfoutput>#carouselId#</cfoutput>" 
								class="swiper-slide-image swiper-gl-image"  
	 							src="<cfoutput>#carouselItemMediaUrl#</cfoutput>"
								loading="lazy">
							<!---<div class="swiper-lazy-preloader swiper-lazy-preloader-white"></div>--->
							<div class="swiper-slide-content">
								<div class="swiper-slide-title" data-swiper-parallax="-100">
									<cfif not arguments.card><cfoutput>#carouselItemTitle#</cfoutput></cfif>
								</div>

								<div class="swiper-slide-text" data-swiper-parallax="-200">
									<cfif not arguments.card><cfoutput>#carouselItemBody#</cfoutput></cfif>
								</div>
							</div><!---<div class="swiper-slide-content">--->
							<div class="swiper-button-next"></div>
    						<div class="swiper-button-prev"></div>
						</div><!---<div class="swiper-slide">--->
						</cfloop>
					</div><!---<div class="swiper-wrapper">--->

					<div class="swiper-pagination"></div>
				</div><!--<div class="swiper">-->

				<!--- Include the Swiper scripts --->
				<script src="https://cdn.jsdelivr.net/npm/swiper@10/swiper-bundle.min.js"></script>
				<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/swiper/viper/swiper-gl.min.js"></script>

				<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swiper@10/swiper-bundle.min.css" />
				<link rel="stylesheet" href="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/swiper/viper/swiper-gl.min.css" />

				<script>
				  var swiper<cfoutput>#carouselId#</cfoutput> = new Swiper(".swiper", {
					modules: [SwiperGL],
					threshold: 5,
					observer: true,
					observeParents: true,
					// Disable preloading of images
    				preloadImages: false,
					watchSlidesProgress: true,
					autoplay: { enabled: true },
					grabCursor: true,
					effect: "gl",
					<cfif len(carouselShader)>gl: { shader: "<cfoutput>#carouselShader#</cfoutput>" },</cfif>
					slidesPerGroupAuto: false,
					creativeEffect: {
					  next: { shadow: true },
					  prev: { shadow: true },
					  limitProgress: 5,
					},
					navigation: {
					  nextEl: '.swiper-button-next',
					  prevEl: '.swiper-button-prev',
					},
					pagination: {
					  clickable: true,
					  dynamicBullets: true,
					  el: ".swiper-pagination",
					},
					parallax: { enabled: true },
					speed: 600,
					keyboard: { enabled: true },
				  });
				</script>
			</cfsavecontent>
						
		</cfif><!---<cfif arrayLen(getCarousel)>--->
		
		<!--- Return the HTML --->
		<cfreturn carouselHtml>
	
	</cffunction>
				
	<cffunction name="renderLoadMapScript" returntype="string" output="true"
			hint="Renders a script to load multiple maps on a page">
		<cfargument name="kendoTheme" type="string" required="yes" hint="Required to determine the polygon colors">
		<cfargument name="enclosureMapIdList" type="string" required="yes">
		<cfargument name="currentRow" type="numeric" required="false" default="1">
			
				
		<!--- Create the loadMaps script. This will load every map found in the getPost query. --->
		<cfif arguments.currentRow eq 1>
			
			<cfset mapBodyScript = ''>
			<cfset thisMapBodyScript = ''>

			<!--- Sort the mapIdList --->
			<cfset enclosureMapIdList = listSort(enclosureMapIdList,"numeric","asc",",")>

			<!--- Create a loop counter. We need to perform certain logic depending upon this counter. --->
			<cfset enclosureMapIdLoopCounter = 1>

			<!--- Loop through the map list --->
			<cfloop list="#enclosureMapIdList#" index="thisMapId">

				<!--- Get the map data for the current map in the list --->
				<cfset getThisMap = application.blog.getMapByMapId(thisMapId)>

				<cfif arrayLen(getThisMap)>
					<cfset thisGeoCoordinates = getThisMap[1]["GeoCoordinates"]>
					<cfset thisLocation = getThisMap[1]["Location"]>
					<cfset thisZoom = getThisMap[1]["Zoom"]>
					<cfset thisCustomMarkerUrl = getThisMap[1]["CustomMarkerUrl"]>
					<cfset thisOutlineMap = getThisMap[1]["OutlineMap"]>
					<cfset thisHasMapRoutes = getThisMap[1]["HasMapRoutes"]>
				</cfif>

				<!--- See if the map has routes and set the map type property --->
				<cfif thisHasMapRoutes>
					<cfset thisMapType = "route">
				<cfelse>
					<cfset thisMapType = "static">
				</cfif>

				<cfif thisMapType eq 'route'>	

					<!--- Render the common part of our map route--->
					<cfinvoke component="#this#" method="renderCommonMapScript" returnvariable="thisMapBodyScript">
						<cfinvokeargument name="kendoTheme" value="#arguments.kendoTheme#">
						<cfinvokeargument name="mapType" value="route">
						<cfinvokeargument name="mapId" value="#thisMapId#">
						<cfinvokeargument name="geoCoordinates" value="#thisGeoCoordinates#">
						<cfinvokeargument name="location" value="#thisLocation#">
					</cfinvoke>

					<cfsavecontent variable="thisMapBodyScript">
						<!--- Output the map routes --->
						<cfoutput>#thisMapBodyScript#</cfoutput>
					</cfsavecontent>

				<cfelse><!---<cfif mapType eq 'route'>--->

					<!--- Determine which marker to use. --->
					<cfif isDefined("customMarkerUrl") and len(customMarkerUrl)>
						<cfset mapLocationMarker = customMarkerUrl>
					<cfelse>
						<cfset mapLocationMarker = '/images/mapMarkers/mapMarkerButton.gif'>
					</cfif>

					<!--- Render the common part of our static map--->
					<cfinvoke component="#this#" method="renderCommonMapScript" returnvariable="thisMapBodyScript">
						<cfinvokeargument name="kendoTheme" value="#arguments.kendoTheme#">
						<cfinvokeargument name="mapType" value="static">
						<cfinvokeargument name="mapId" value="#thisMapId#">
						<cfinvokeargument name="geoCoordinates" value="#thisGeoCoordinates#">
						<cfinvokeargument name="location" value="#thisLocation#">
					</cfinvoke>

					<cfsavecontent variable="thisMapBodyScript">
						<!--- Output the map routes --->
						<cfoutput>#thisMapBodyScript#</cfoutput>
					</cfsavecontent>

				</cfif><!---<cfif mapType eq 'route'>--->

				<!--- Append the script --->
				<cfset mapBodyScript = mapBodyScript & thisMapBodyScript>

				<!--- At the very end of the loop, create the bing maps callback script. --->

				<cfif enclosureMapIdLoopCounter eq listLen(enclosureMapIdList)>
					<cfsavecontent variable="bingMapsCallbackScript">
						<script type='text/javascript' src='<cfoutput>#bingMapsUrl#</cfoutput>/api/maps/mapcontrol?key=<cfoutput>#application.bingMapsApiKey#</cfoutput>&callback=loadMaps()' async defer></script>
					</cfsavecontent>
				</cfif>

				<!--- Increment our counter --->
				<!--- Create a loop counter. We need to perform certain logic depending upon this counter. --->
				<cfset enclosureMapIdLoopCounter = enclosureMapIdLoopCounter + 1>

			</cfloop>

			<!--- Build the final html --->
			<cfsavecontent variable="loadMapScript">
				<script>
					// This script will load multiple Bing maps on a single page.
					function loadMaps() {
						try {
							<cfoutput>#mapBodyScript#</cfoutput>
						} catch (error) {
							error = "Can't load map";
						}
					}
				</script>
				<!-- The callback script should be underneath the loadMaps function and the map div's. Note: as of September 2021 you must use Bings experimental branch to render multiple maps at one time. -->
				<script type='text/javascript' src='<cfoutput>#bingMapsUrl#</cfoutput>/api/maps/mapcontrol?branch=experimental&callback=loadMaps&key=<cfoutput>#application.bingMapsApiKey#</cfoutput>' async defer></script>
			</cfsavecontent>

		</cfif><!---<cfif arguments.currentRow eq 1>--->

		<cfreturn loadMapScript>
								
	</cffunction>
				
	<cffunction name="renderMap" returntype="string" output="true"
			hint="Renders the enclosure map at the top of a post">
		<cfargument name="kendoTheme" type="string" required="yes" hint="Required to determine the polygon colors">
		<cfargument name="getMap" type="array" required="yes" hint="Pass in the getMap query">
		<cfargument name="enclosureMapIdList" type="string" required="yes">
		<cfargument name="currentRow" type="numeric" required="false" default="1">
			
		<!--- Set the vars. --->
		<cfset mapId = getMap[1]["MapId"]>
		<cfset geoCoordinates = getMap[1]["GeoCoordinates"]>
		<cfset location = getMap[1]["Location"]>
		<cfset zoom = getMap[1]["Zoom"]>
		<cfset customMarkerUrl = getMap[1]["CustomMarkerUrl"]>
		<cfset outlineMap = getMap[1]["OutlineMap"]>
		<cfset hasMapRoutes = getMap[1]["HasMapRoutes"]>
			
		<!--- See if the map has routes and set the map type property --->
		<cfset hasMapRoutes = getMap[1]["HasMapRoutes"]>
		<cfif hasMapRoutes>
			<cfset mapType = "route">
		<cfelse>
			<cfset mapType = "static">
		</cfif>
			
		<!--- Maps require some special handling as all of the maps needed for a given page need to be loaded using a single function. There is no way to load the maps using their own individual scripts, so we need to idenfity if there is more than one map to create the map loading script. We need to use a single callback script that loads the maps at the same time. --->
		
		<!--- //************************************************************************************************
			Render the div's used with the loadMapScript for multiple maps.
		//**************************************************************************************************--->
		<cfif listLen(enclosureMapIdList) gt 1>
				
			<cfsavecontent variable="enclosureHtml">
				<div id="printoutPanel"></div>
				<div id="map<cfoutput>#mapId#</cfoutput>" class="entryMap"></div>
			</cfsavecontent>
		
		<!--- //************************************************************************************************
			Render a single map
		//**************************************************************************************************--->
		<cfelse><!---<cfif listLen(enclosureMapIdList) gt 1>--->
			
			<cfif mapType eq 'route'>	
			
				<!--- Render the common part of our map route--->
				<cfinvoke component="#this#" method="renderCommonMapScript" returnvariable="mapRouteScript">
					<cfinvokeargument name="kendoTheme" value="#arguments.kendoTheme#">
					<cfinvokeargument name="mapType" value="route">
					<cfinvokeargument name="mapId" value="#mapId#">
					<cfinvokeargument name="geoCoordinates" value="#geoCoordinates#">
					<cfinvokeargument name="location" value="#location#">
				</cfinvoke>

				<cfsavecontent variable="enclosureHtml">
					<!--- Build the javascript --->
					<script type='text/javascript'>
						function getMap<cfoutput>#mapId#</cfoutput>() {
							<!--- Output the map routes --->
							<cfoutput>#mapRouteScript#</cfoutput>
						}
					</script>

					<!--- Content containers --->
					<div id="printoutPanel"></div>
					<div id="map<cfoutput>#mapId#</cfoutput>" class="entryMap"></div>
					<!-- The type argument is a Galaxie Blog argument -->
					<script type='text/javascript' src='<cfoutput>#bingMapsUrl#</cfoutput>/api/maps/mapcontrol?key=<cfoutput>#application.bingMapsApiKey#</cfoutput>&callback=getMap<cfoutput>#mapId#</cfoutput>&type=route' async defer></script>
				</cfsavecontent>

			<cfelse><!---<cfif mapType eq 'route'>--->

				<!--- Determine which marker to use. --->
				<cfif isDefined("customMarkerUrl") and len(customMarkerUrl)>
					<cfset mapLocationMarker = customMarkerUrl>
				<cfelse>
					<cfset mapLocationMarker = '/images/mapMarkers/mapMarkerButton.gif'>
				</cfif>

				<!--- Render the common part of our static map--->
				<cfinvoke component="#this#" method="renderCommonMapScript" returnvariable="staticMapScript">
					<cfinvokeargument name="kendoTheme" value="#arguments.kendoTheme#">
					<cfinvokeargument name="mapType" value="static">
					<cfinvokeargument name="mapId" value="#mapId#">
					<cfinvokeargument name="geoCoordinates" value="#geoCoordinates#">
					<cfinvokeargument name="location" value="#location#">
				</cfinvoke>

				<cfsavecontent variable="enclosureHtml">
					<!--- Build the javascript --->
					<script type='text/javascript'>
						function getMap<cfoutput>#mapId#</cfoutput>() {
							<!--- Output the common static map part --->
							<cfoutput>#staticMapScript#</cfoutput>
						}
					</script>
					<!-- The type argument is a Galaxie Blog argument -->
					<script type='text/javascript' src='<cfoutput>#bingMapsUrl#</cfoutput>/api/maps/mapcontrol?key=<cfoutput>#application.bingMapsApiKey#</cfoutput>&callback=getMap<cfoutput>#mapId#</cfoutput>&type=static' async defer></script>

					<div id="map<cfoutput>#mapId#</cfoutput>" class="entryMap"></div>
				</cfsavecontent>

			</cfif><!---<cfif mapType eq 'route'>--->
		</cfif><!---<cfif listLen(enclosureMapIdList) gt 1>--->
				
		<cfreturn enclosureHtml>
				
	</cffunction>
					
	<cffunction name="renderCommonMapScript" returntype="string" output="true"
			hint="Renders certain parts of a map. This is meant to be able to reuse code as there are multiple map related functions that share the common map elements.">
		<cfargument name="kendoTheme" type="string" required="yes" hint="Required to determine the polygon colors">
		<cfargument name="mapType" type="string" required="no" default="road" hint="Either: route or static at this time">
		<cfargument name="mapId" type="string" required="yes">
		<cfargument name="geoCoordinates" type="string" required="yes">
		<cfargument name="location" type="string" required="yes">
		<!--- Optional args --->
		<cfargument name="thumbnail" type="boolean" default="false" required="no">
		<cfargument name="entityType" type="string" default="PopulatedPlace" required="no">
		<cfargument name="mapLocationMarkerUrl" type="string" default="" required="no">
		<cfargument name="outlineMap" type="boolean" default="false" required="no">
		<cfargument name="zoom" type="numeric" default="12" required="no">
		
		<!--- Note: this function does not render the beginning or ending script tags. This is by design as the script tags will vary depending upon how many maps are in the query. The script tags will be rendered by the renderEnclosure function. --->
		
		<!--- Get the accent color of the selected theme. We will use this to color the map to match the theme. --->
		<cfset accentColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>
			
		<cfsavecontent variable="commonMapHtml">
						// ***********************************************************************
						// Script for Map <cfoutput>#arguments.mapId#</cfoutput>
						// ***********************************************************************
			<cfsilent><!--- The GeoCoordinates will be blank with map routes ---></cfsilent>
			<cfif len(arguments.GeoCoordinates)>
						// Create a location. This should be outside of the map declaration when drawing multiple maps on a page. However, this works when there is just one map, or there are many, so we are using this approach with both map options.
						var location<cfoutput>#arguments.mapId#</cfoutput> = new Microsoft.Maps.Location(<cfoutput>#arguments.GeoCoordinates#</cfoutput>);
			</cfif>
						// Create a compact horizontal navigation bar
						var navigationBarMode<cfoutput>#arguments.mapId#</cfoutput> = Microsoft.Maps.NavigationBarMode;

						// Map declaration
						var map<cfoutput>#arguments.mapId#</cfoutput> = new Microsoft.Maps.Map(document.getElementById('map<cfoutput>#arguments.mapId#</cfoutput>'), {
							// compact navigation bar	
							navigationBarMode: navigationBarMode<cfoutput>#arguments.mapId#</cfoutput>.compact, 
						<cfsilent><!--- The GeoCoordinates (and thus the location) will be blank with map routes ---></cfsilent>
						<cfif len(arguments.GeoCoordinates)>
							// Use our unique location
							center: location<cfoutput>#arguments.mapId#</cfoutput>,
						</cfif>
							mapTypeId: Microsoft.Maps.MapTypeId.road,
							zoom: <cfoutput>#arguments.zoom#</cfoutput>
						});
					<cfif session.isMobile or thumbnail>
						// Set map options
						map<cfoutput>#arguments.mapId#</cfoutput>.setOptions({
							showLocateMeButton: false,
							showMapTypeSelector: false,
							showZoomButtons: false,
							showScalebar: false
						});
					</cfif>
		</cfsavecontent>
			
		<cfif arguments.mapType eq 'static'>
			
			<!--- Note: we are not including the script tags. These tags will be different depending upon if there are multiple maps or not. This will be handed by a different function. We are just rendering common elements here. --->
			<cfsavecontent variable="staticMapHtml">
						#commonMapHtml#

						// Create a center variable for the pushpin
						var center<cfoutput>#arguments.mapId#</cfoutput> = map<cfoutput>#arguments.mapId#</cfoutput>.getCenter();

						// Create custom Pushpin
						var pin = new Microsoft.Maps.Pushpin(center<cfoutput>#arguments.mapId#</cfoutput>, {
							<cfif len(arguments.mapLocationMarkerUrl)>icon: '<cfoutput>#arguments.mapLocationMarkerUrl#</cfoutput>'<cfelse>color:'#chr(35)#<cfoutput>#accentColor#</cfoutput>',</cfif>
							anchor: new Microsoft.Maps.Point(12, 39)
						});

						// Add the pushpin to the map
						map<cfoutput>#arguments.mapId#</cfoutput>.entities.push(pin);

					<cfif outlineMap>
						var geoDataRequestOptions = {
							entityType: '<cfoutput>#arguments.entityType#</cfoutput>',
							getAllPolygons: true
						};
						Microsoft.Maps.loadModule('Microsoft.Maps.SpatialDataService', function () {
							//Use the GeoData API manager to get the boundary
							var polygonStyle = {
								fillColor: 'rgba(161,224,255,0.4)',
								strokeColor: '#chr(35)#<cfoutput>#accentColor#</cfoutput>',
								strokeThickness: 2
							};
							Microsoft.Maps.SpatialDataService.GeoDataAPIManager.getBoundary('<cfoutput>#arguments.Location#</cfoutput>', geoDataRequestOptions, map<cfoutput>#arguments.mapId#</cfoutput>, function (data) {
								if (data.results && data.results.length > 0) {
									map<cfoutput>#arguments.mapId#</cfoutput>.entities.push(data.results[0].Polygons);
								}
							}, polygonStyle, function errCallback(networkStatus, statusMessage) {
								console.log(networkStatus);
								console.log(statusMessage);
							});

						});
					</cfif><!---<cfif outlineMap>--->
			</cfsavecontent>
			
			<cfset returnValue = staticMapHtml>
			
		<cfelseif mapType eq 'route'>
			
			<!--- Get route data --->
			<cfset Data = application.blog.getMapRoutesByMapId(mapId)>
			
			<cfsavecontent variable="MapRouteHtml">
						#commonMapHtml#

						// Routes for map#arguments.mapId# ***************************************
						Microsoft.Maps.loadModule('Microsoft.Maps.Directions', function () {
							var directionsManager = new Microsoft.Maps.Directions.DirectionsManager(map<cfoutput>#mapId#</cfoutput>);
							// Set Route Mode to driving
							directionsManager.setRequestOptions({ routeMode: Microsoft.Maps.Directions.RouteMode.driving });
							// Use the primary color of our theme for the routes
							directionsManager.setRenderOptions({
								drivingPolylineOptions: {
									strokeColor: '#chr(35)#<cfoutput>#accentColor#</cfoutput>'
								}
							});
							// Create our waypoints
						<cfloop from="1" to="#arrayLen(Data)#" index="i"><cfoutput>
							var waypoint#i# = new Microsoft.Maps.Directions.Waypoint({ address: '#Data[i]["Location"]#', location: new Microsoft.Maps.Location(#Data[i]["GeoCoordinates"]#) });
							directionsManager.addWaypoint(waypoint#i#);
						</cfoutput></cfloop>
							// Set the element in which the itinerary will be rendered
							//directionsManager.setRenderOptions({ itineraryContainer: document.getElementById('printoutPanel') });
							directionsManager.calculateDirections();
						});
			</cfsavecontent>
			
			<cfset returnValue = mapRouteHtml>
		
		</cfif>
				
		<cfreturn returnValue>
				
	</cffunction>
			
	<cffunction name="renderMapPreview" returntype="string" output="true"
			hint="Renders the map thumbnail at the top of a post. Note: there are two sizes of the card, one when used with the sidebar, and one without. When there is no sidebar, all of the posts are in a small card format and both the popular posts and regular posts are using the same class, however, with the sidebar, the posts are in a medium sized card format but the popular posts at the top of the page need a separate class to render correctly.">
		<cfargument name="mapId" type="string" required="yes">
		<cfargument name="renderThumbnail" type="boolean" required="no" default="false">
		<cfargument name="renderKCardMediaClass" type="boolean" required="no" default="false">
		<cfargument name="renderMediumCard" type="boolean" required="no" default="true">
		<cfargument name="showSidebar" type="boolean" required="no" default="false">
			
		<!--- There are two different types of maps- static and route. --->
		<!--- Get the map data to determine if this is a static or route map --->
		<cfset getMap = application.blog.getMapByMapId(mapId)>
		<!--- See if the map has routes and set the map type property --->
		<cfset hasMapRoutes = getMap[1]["HasMapRoutes"]>
		<cfif hasMapRoutes>
			<cfset mapType = "route">
		<cfelse>
			<cfset mapType = "static">
		</cfif>
			
		<!--- Set the default iframe dimensions --->
		<cfif renderThumbnail>
			<cfif renderMediumCard>
				<cfset width = "100%">
				<cfset height = "640"><!--- Corresponds to the k-card-media css declaration --->
			<cfelse>
				<cfset width = "246">
				<cfset height = "135">
			</cfif>
		<!--- Rendering the iframe in a mobile client--->
		<cfelseif session.isMobile>
			<cfset width="100%">
			<cfset height="390">
		<cfelse>
			<cfset width = "750">
			<cfset height = "432">
		</cfif>
				
		<!--- When the sidebar is shown, we want to use the k-card-scroll-image for the popular posts at the top of the page. Otherwise, use the k-card-media class since all of the card sizes will be the same for both popular and the main posts. --->
		<cfif arguments.renderMediumCard>
			<cfset kCardMapClass = "k-card-media">
		<cfelse>
			<cfset kCardMapClass = "k-card-scroll-image">
		</cfif>
			
		<!--- Note: we will not have an extension that we can read on an external URL --->
		<cfif arguments.renderThumbnail>
			<cfset mapHtmlStr = '<iframe title="map route" data-type="mapRoute" data-id="#arguments.mapId#" src="#application.baseUrl#/preview/maps.cfm?mapId=' & arguments.mapId & '&mapType=' & mapType & '&thumbnail=true'>
		<cfelse>
			<cfset mapHtmlStr = '<iframe title="map route" data-type="mapRoute" data-id="#arguments.mapId#" src="#application.baseUrl#/preview/maps.cfm?mapId=' & arguments.mapId & '&mapType=' & mapType & '&thumbnail=false'>
		</cfif>
		<cfif renderKCardMediaClass>
			<!--- Render the map for a Kendo card --->
			<cfset mapHtmlStr = mapHtmlStr & '" width="' & width & '" height="' & height & '" allowfullscreen="allowfullscreen" class="' & kCardMapClass & '" frameBorder="0" scrolling="no"></iframe>'>
		<cfelse>
			<cfset mapHtmlStr = mapHtmlStr & '" width="' & width & '" height="' & height & '" allowfullscreen="allowfullscreen" frameBorder="0" scrolling="no"></iframe>'>
		</cfif>
		
		<cfreturn mapHtmlStr>
	
	</cffunction>
			
	<cffunction name="renderCarouselPreview" returntype="string" output="true"
			hint="Renders the carousel thumbnail at the top of a post on for the condensed cars and admin page. This is not used in the tinymce editor, only for the post and enclosure image editors">
		<cfargument name="carouselId" type="string" required="yes">
		<cfargument name="interface" type="string" required="no" default="postEditor" hint="either an empty string, postEditor or enclosureEditor. When this is specified, none of the other arguments are required or sent in">	
			
		<!--- Handle carousels for the editors. Note: the height and width logic is inside an iframe and needs to be a bit smaller than the iframes to remove scrollbars --->
		<cfif arguments.interface eq 'postEditor' or arguments.interface eq 'card'>
			<cfset thumbnail = true>
			<!--- Smaller size --->
			<cfif session.isMobile>
				<cfset width = "225">
				<cfset height = "105">
			<cfelse>
				<!--- This is used for both the popular cards and when in card layout --->
				<cfset width = "255">
				<cfset height = "150">
			</cfif>
		<cfelseif arguments.interface eq 'enclosureEditor'>
			<cfset thumbnail = false>
			<!--- Medium size (not full size like on a post) --->
			<cfif session.isMobile>
				<cfset width = "285">
				<cfset height = "147">
			<cfelse>
				<cfset width = "825">
				<cfset height = "580">
			</cfif>
		<cfelseif arguments.interface eq 'mediumCard'>
			<!--- Handle previews for the main blog page --->
			<cfset thumbnail = false>
			<cfif session.isMobile>
				<cfset width = "100%">
				<cfset height = "285">
			<cfelse>
				<cfset width = "100%">
				<cfset height = "640">
			</cfif>
		</cfif>
			
		<cfsavecontent variable="carouselHtmlStr">
			<iframe title="carousel" data-type="carousel" data-id="#arguments.carouselId#" src="#application.baseUrl#/preview/carousel.cfm?carouselId=#arguments.carouselId#&interface=#arguments.interface#&thumbnail=#thumbnail#" width="#width#" height="#height#" frameBorder="0" scrolling="no"></iframe>
		</cfsavecontent> 
		
		<cfreturn carouselHtmlStr>
	
	</cffunction>
			
	<!--- //************************************************************************************************
		Independent string escape functions
	//**************************************************************************************************--->
			
	<!--- Common HTML escape functions --->
	<cffunction name="simpleHtmlEscape" returntype="string" output="true"
			hint="Note: I often need to escape the HTML tag characters, and only the tags, when converting text to be used in the tinyMce editor and for Prism. ColdFusion does not have a simple escape/unescape function, and I don't  want to have to worry about escaping/unescaping everything- I just need the tags to be escaped. This function is used primarilly to remove the opening and closing tags in code blocks for prism.">
		<cfargument name="str" type="string" required="yes" hint="Pass in the string">
		
		<!--- What are we going to replace? --->
		<cfset ltTag = '<'>
		<cfset gtTag = '>'>
		<cfset escapedLtTag = '&lt;'>
		<cfset escapedGtTag = '&gt;'>
			
		<cfset str = replaceNoCase(arguments.str, ltTag, escapedLtTag, 'all')>
		<cfset str = replaceNoCase(str, gtTag, escapedGtTag, 'all')>
				
		<cfreturn str>
				
	</cffunction>
				
	<cffunction name="simpleHtmlUnescape" returntype="string" output="true"
			hint="Note: I often need to escape the HTML tag characters, and only the tags, when converting text to be used in the tinyMce editor and for Prism. ColdFusion does not have a simple escape/unescape function, and I don't  want to have to worry about escaping/unescaping everything- I just need the tags to be escaped">
		<cfargument name="str" type="string" required="yes" hint="Pass in the string">
		<cfargument name="action" type="string" required="no" default="escape" hint="Either escape or unescape">
		
		<!--- What are we going to replace? --->
		<cfset ltTag = '<'>
		<cfset gtTag = '>'>
		<cfset escapedLtTag = '&lt;'>
		<cfset escapedGtTag = '&gt;'>

		<cfset newStr = replaceNoCase(str, escapedLtTag, ltTag, 'all')>
		<cfset newStr = replaceNoCase(newStr, escapedGtTag, gtTag, 'all')>
				
		<cfreturn newStr>
				
	</cffunction>
			
	<!--- //************************************************************************************************
		Render for TinyMce
	//**************************************************************************************************--->
			
	<!--- TinyMce does not render our Galaxie Blog directives. In order to have them be seen, we need to replace the first opening tag with a &lt; symbol. We will replace the symbols again when we insert the record into the database (see function below) --->
	<cffunction name="renderGalaxieDirectiveToTinyMce" returntype="string" output="true"
			hint="Render the Galaxie directive without the opening tag. Replace the opening tag with a &lt; symbol">
		<cfargument name="postContent" type="string" required="yes" hint="Pass in the post body.">
			
		<cfset newBody = arguments.postContent>
			
		<!--- Loop through the Galaxie Blog Directive list --->
		<cfset directiveList = application.blog.getGalaxieBlogDirectives()>
			
		<cfloop list="#directiveList#" index="i">
			<!--- Modify the body --->
			<cfset newBody = this.renderDirectiveTagsForTinyMce(postContent=newBody,directive=i)>
		</cfloop> 
			
		<cfreturn newBody>
			
	</cffunction>
			
	<cffunction name="renderGalaxieDirectiveFromTinyMceToDb" returntype="string" output="true"
			hint="Render the Galaxie directive with the opening tag. Replace the &lt; &gt symbols with tags. This is not used but I am keeping it around in case this type of logic needs to be applied to a post in the future.">
		<cfargument name="postContent" type="string" required="yes" hint="Pass in the post body.">
			
		<cfset newBody = arguments.postContent>
			
		<!--- Loop through the Galaxie Blog Directive list --->
		<cfset directiveList = application.blog.getGalaxieBlogDirectives()>
			
		<cfloop list="#directiveList#" index="i">
			<!--- Modify the body --->
			<cfset newBody = this.renderDirectiveTagsFromTinyMceToDb(postContent=newBody,directive=i)>
			<!---<cfoutput>i: #i# newBody: #newBody#<br/></cfoutput>--->
		</cfloop> 
			
		<cfreturn newBody>
			
	</cffunction>
				
	<!--- Directive tag helpers. --->
	<cffunction name="renderDirectiveTagsForTinyMce" returntype="string" output="true"
			hint="Removes the opening and closing tags to allow the directive to be previewed with tinymce">
		<cfargument name="postContent" type="string" required="yes" hint="Pass in the post content.">
		<cfargument name="directive" type="string" required="yes" hint="Pass in the directive.">
			
		<cfset newBody = arguments.postContent>
			
		<!--- Set the opening tag vars --->
		<cfset openingTagToReplace = '<' & directive>
		<cfset openingTagStr = '&lt;' & directive>
		<!--- And the closing vars. There are two symbols here, '&lt;&gt;' to handle the closing tag of the opening directive and opening tag of the closing directive. --->
		<cfset closingTagToReplace = '</' & directive & '>'>
		<cfset closingTagStr = '&lt;/' & directive & '&gt;'>
			
		<cfif findNoCase(openingTagToReplace,postContent) and findNoCase(closingTagToReplace,postContent)>
			<!--- Replace the tags in the body --->
			<cfset newBody = replaceNoCase(newBody, openingTagToReplace, openingTagStr, "all")>
			<cfset newBody = replaceNoCase(newBody, closingTagToReplace, closingTagStr, "all")>
		</cfif>
			
		<cfreturn newBody>
			
	</cffunction>
			
	<cffunction name="renderDirectiveTagsFromTinyMceToDb" returntype="string" output="true"
			hint="Recreate the opening and closing tags to allow the directive to be saved to the database properly from tinymce. This is depracated in version 3">
		<cfargument name="postContent" type="string" required="yes" hint="Pass in the post content.">
		<cfargument name="directive" type="string" required="yes" hint="Pass in the directive.">
			
		<cfset newBody = arguments.postContent>
			
		<!--- Set the opening tag vars --->
		<cfset openingTagToReplace = '<p>&lt;' & directive>
		<cfset openingTagStr = '<' & directive>
		<!--- And the closing vars. There are two symbols here, '&lt;&gt;' to handle the closing tag of the opening directive and opening tag of the closing directive. --->
		<cfset closingTagToReplace = '&gt;&lt;/' & directive & '&gt;</p>'>
		<cfset closingTagStr = '></' & directive & '>'>
			
		<cfif findNoCase(openingTagToReplace,newBody) and findNoCase(closingTagToReplace,newBody)>
			<!--- Replace the tags in the body --->
			<cfset newBody = replaceNoCase(newBody, openingTagToReplace, openingTagStr, "all")>
			<cfset newBody = replaceNoCase(newBody, closingTagToReplace, closingTagStr, "all")>
		</cfif>
			
		<cfreturn newBody>
			
	</cffunction>
				
	<!--- //************************************************************************************************
		Render for Prism
	//**************************************************************************************************--->
				
	<cffunction name="renderPreTagsForPrism" returntype="string" output="true"
			hint="For prism to work, we need to render all of the code tags with a pre tag">
		<cfargument name="postContent" type="string" required="yes" hint="Pass in the string">
		<cfargument name="renderScriptTags" type="boolean" required="no" default="false" hint="Set to true if you want to put a script around the code. This should only be done if the content between the code tags is not escaped.">
			
		<!--- Wrap all of the code blocks with script and pre tags --->
		<cfif renderScriptTags>
			<cfset newContent = replaceNoCase(arguments.postContent, '<code>', '<pre class="language-markup"><code><script type="prism-html-markup">', 'all')>
			<cfset newContent = replaceNoCase(newContent, '</code>', '</script></code></pre>', 'all')>
		<cfelse>
			<cfset newContent = replaceNoCase(arguments.postContent, '<code>', '<pre class="language-markup"><code>', 'all')>
			<cfset newContent = replaceNoCase(newContent, '</code>', '</code></pre>', 'all')>
		</cfif>
		
		<!--- Remove any extra paragraph tags --->
		<cfset newContent = replaceNoCase(newContent, '<p>', '', 'all')>
		<cfset newContent = replaceNoCase(newContent, '</p>', '', 'all')>

		<cfreturn newContent>
				
	</cffunction>
				
	<cffunction name="renderCodeForPrism" returntype="string" output="true"
			hint="For prism to work, we need to render all of the code tags with a pre tag and remove the opening and closing tags between the code blocks.">
		<cfargument name="postContent" type="string" required="yes" hint="Pass in the string">
		<cfargument name="action" type="string" required="no" default="cleanForPrism" hint="Either 'renderPreTags' which will keep the opening and closing brackets and add a pre and script tag around the code blocks or 'cleanForPrism' which will clean the code for prism. 'cleanForPrism' will be the default setting.">
				
		<!--- Instantiate the Jsoup.cfc. We need to get to the renderCodeBlocksForPrism function. --->
		<cfobject component="#application.jsoupComponentPath#" name="JSoupObj">
		<!--- Remove the opening and closing tags in the content between any code tags --->
		<cfset newContent = JSoupObj.renderCodeBlocksForPrism(arguments.postContent)>
				
		<cfreturn newContent>
				
	</cffunction>
				
	<!--- //************************************************************************************************
		Email related functions
	//**************************************************************************************************--->
		
	<!--- //************************************************************************************************
		Global email function. All emails and email related functions should eventually use this composite function
	//**************************************************************************************************--->
	
	<cffunction name="renderEmail" returntype="string" output="true"
			hint="Renders an email with a title, description, and body.">
		<cfargument name="email" type="string" required="yes">
		<cfargument name="emailTitle" type="string" required="yes">
		<cfargument name="emailTitleLink" type="string" required="no" default="">
		<cfargument name="emailDesc" type="string" required="no" default="">
		<cfargument name="mediaUrl" type="string" required="no" default="">
		<cfargument name="emailBody" type="string" required="yes">
		<cfargument name="callToActionText" type="string" required="no" default="">
		<cfargument name="callToActionLink" type="string" required="no" default="">
		<cfargument name="unSubscribeLink" type="string" required="no" default="">
			
		<!---<cfoutput>application.blogHostUrl: #application.blogHostUrl# application.siteUrl: #application.siteUrl# application.blogDomain: #application.blogDomain#</cfoutput>--->
			
		<!--- Set display properties --->
		<cfset maxWidth = "720">
			
		<!--- Get the theme in order to get the font properties --->
		<cfset themeAlias = application.blog.getSelectedThemeAlias()>

		<cfquery name="getTheme" dbtype="hql">
			SELECT new Map (
				KendoThemeRef.KendoTheme as KendoTheme,
				ThemeSettingRef.FontRef.Font as Font,
				ThemeSettingRef.FontSize as FontSize,
				ThemeSettingRef.BlogNameFontRef as BlogNameFontId, 
				ThemeSettingRef.BlogNameTextColor as BlogNameTextColor,
				ThemeSettingRef.BlogNameFontSize as BlogNameFontSize,
				ThemeSettingRef.HeaderBackgroundColor as HeaderBackgroundColor,
				ThemeSettingRef.HeaderBackgroundImage as HeaderBackgroundImage,
				ThemeSettingRef.BlogBackgroundImage as BlogBackgroundImage,
				ThemeSettingRef.MenuBackgroundImage as MenuBackgroundImage
			)
			FROM 
				Theme as Theme
			WHERE Theme.ThemeAlias = <cfqueryparam value="#themeAlias#" cfsqltype="cf_sql_varchar">
		</cfquery>
		<!--- Set the Kendo Theme --->
		<cfset kendoTheme = getTheme[1]["KendoTheme"]>

		<!--- Leaving here for future: Get the blog name font. This is not used yet but it is here for future use (when email clients finally start supporting fonts) 
		<cfset getBlogNameFont = application.blog.getFont(fontId=getTheme[1]["BlogNameFontId"])>
		<cfif arrayLen(getBlogNameFont)>
			<cfset blogNameFont = getBlogNameFont[1]["Font"]>
			<cfset blogNameFontType = getBlogNameFont[1]["FontType"]>
		<cfelse>
			<cfset blogNameFont = ''>
			<cfset blogNameFontType = ''>
		</cfif>
		--->

		<!--- Get the logo for the selected theme --->
		<cfset logoPath = application.blog.getLogoPathByTheme()>
		<!--- Blog title --->
		<cfset blogTitle = htmlEditFormat(application.BlogDbObj.getBlogTitle())>
		<!--- Display oriented vars --->
		<cfset headerBgImage = getTheme[1]["HeaderBackgroundImage"]>
		<!--- Get the blog name font size --->
		<cfset blogNameFontSize = getTheme[1]["BlogNameFontSize"]>
		<!--- ... text color --->
		<cfset BlogNameTextColor = getTheme[1]["BlogNameTextColor"]>
		<!--- ... the headerBackgroundColor --->
		<cfset headerBackgroundColor = getTheme[1]["HeaderBackgroundColor"]>
		<!--- ... the headerBackgroundImage (not used yet) --->
		<cfset headerBackgroundImage = getTheme[1]["HeaderBackgroundImage"]>
		<!--- ... and finally the primary button color --->
		<cfset primaryButtonColor = application.blog.getPrimaryColorsByTheme(kendoTheme:kendoTheme,setting:'accentColor')>

		<!--- Content --->
		<cfsavecontent variable="emailBody">
		<!DOCTYPE html>
		<html xml:lang="en" lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">

			 <head>
				  <!-- Help character display properly -->
				  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
				  <!-- Set the initial scale of the email -->
				  <meta name="viewport" content="width=device-width, initial-scale=1">
				  <!-- Force Outlook clients to render with a better MS engine. -->
				  <meta http-equiv="X-UA-Compatible" content="IE=Edge">
				  <!-- Help prevent blue links and autolinking -->
				  <meta name="format-detection" content="telephone=no, date=no, address=no, email=no">
				  <!-- Prevent Apple from reformatting and zooming messages. -->
				  <meta name="x-apple-disable-message-reformatting">

				  <!-- Target dark mode -->
				  <meta name="color-scheme" content="light dark">
				  <meta name="supported-color-schemes" content="light dark only">

				  <!-- Allow for better image rendering on Windows hi-DPI displays. -->
				  <!--[if mso]>
				  <noscript>
				  <xml>
				  <o:OfficeDocumentSettings>
				  <o:AllowPNG/>
				  <o:PixelsPerInch>96</o:PixelsPerInch>
				  </o:OfficeDocumentSettings>
				  </xml>
				  </noscript>
				  <![endif]-->

				  <!-- Support dark mode meta tags -->
				  <style type="text/css">
					   :root {
							color-scheme: light dark;
							supported-color-schemes: light dark;
					   }
				  </style>

				  <!--webfont code goes here-->
				  <!--[if (gte mso 9)|(IE)]><!-->
				  <!--webfont <link /> goes here-->
				  <style>
					   /*Web font over ride goes here
					   h1, h2, h3, h4, h5, p, a, img, span, ul, ol, li { font-family: 'webfont name', Arial, Helvetica, sans-serif !important; } */
				  </style>
				  <!--<![endif]-->

				  <style type="text/css">
					   .body-fix {
							height: 100% !important;
							margin: 0 auto !important;
							padding: 0 !important;
							width: 100% !important;
							-webkit-text-size-adjust: 100%;
							-ms-text-size-adjust: 100%;
							-webkit-font-smoothing: antialiased;
							word-spacing: normal;
					   }

					   div[style*="margin:16px 0"] {
							margin: 0 !important;
					   }

					   table, td {
							border-collapse: collapse !important;
							mso-table-lspace: 0pt;
							mso-table-rspace: 0pt;
							-webkit-text-size-adjust: 100%;
							-ms-text-size-adjust: 100%;
					   }

					   img {
							border: 0;
							line-height: 100%;
							outline: none;
							text-decoration: none;
							display: block;
					   }

					   p, h1, h2, h3 {
							padding: 0;
							margin: 0;
					   }

					   a[x-apple-data-detectors] {
							color: inherit !important;
							text-decoration: none !important;
							font-size: inherit !important;
							font-family: inherit !important;
							font-weight: inherit !important;
							line-height: inherit !important;
					   }

					   u+<cfoutput>#chr(35)#</cfoutput>body a {
							color: inherit;
							text-decoration: none;
							font-size: inherit;
							font-family: inherit;
							font-weight: inherit;
							line-height: inherit;
					   }

					   <cfoutput>#chr(35)#</cfoutput>MessageViewBody a {
							color: inherit;
							text-decoration: none;
							font-size: inherit;
							font-family: inherit;
							font-weight: inherit;
							line-height: inherit;
					   }

					   .link:hover { text-decoration: none !important; }

					   .fadeimg {
							transition: 0.3s !important;
							opacity: 1 !important;
					   }

					   .fadeimg:hover {
							transition: 0.3s !important;
							opacity: 0.5 !important;
					   }

					   /* start CTA HOVER EFFECTS */
					   .cta { transition: 0.3s !important; }
					   .cta span { transition: 0.3s !important; }
					   .cta:hover {
							transition: 0.5s !important;
							background-color: <cfoutput>#chr(35)##primaryButtonColor#</cfoutput> !important;
							transform: scale(1.05);
					   }
					   .cta:hover span { transition: 0.3s !important; }
					   .cta-border:hover { border-bottom: 3px solid transparent !important; }
					   /* end CTA HOVER EFFECTS */

					   .mobile { display: none; }

					   /* start rating stars effect */
					   .star > a:hover, .star > a:hover ~ a { color: <cfoutput>#chr(35)#</cfoutput>26de81 !important; }
					   /* end rating stars effect */
				  </style>

				  <!-- Mobile styles -->
				  <style>
				  @media screen and (max-width: <cfoutput>#maxWidth#px</cfoutput>) {
					   .w90p { width: 90% !important; }
					   .w95p { width: 95% !important; }
					   .w100p { width: 100% !important; }

					   .imgFull { width: 100% !important; height: auto !important; }

					   .desktop { width: 0 !important; display: none !important; }
					   .mobile { display: block !important; }

					   h1 { font-size: 50px !important; line-height: 60px !important; }
					   .std { font-size: 18px !important; line-height: 28px !important; }

					   .cTxt { text-align: center !important; }

					   .tPad-0 { padding-top: 0 !important; }
					   .rPad-0 { padding-right: 0 !important; }
					   .lPad-0 { padding-left: 0 !important; }
					   .bPad-30 { padding-bottom: 30px !important; }
					  
					   .star a { font-size: 40px !important; }
				  }
				  </style>

				  <!-- Dark mode styles -->
				  <style>
				  @media (prefers-color-scheme: dark) {
					   /* Shows Dark Mode-Only Content, Like Images */
					   .dark-img {
							display: block !important;
							width: auto !important;
							overflow: visible !important;
							float: none !important;
							max-height: inherit !important;
							max-width: inherit !important;
							line-height: auto !important;
							margin-top: 0px !important;
							visibility: inherit !important;
					   }

					   /* Hides Light Mode-Only Content, Like Images */
					   .light-img { display: none; display: none !important; }

					   /* Custom Dark Mode Background Color */
					   .darkmode { background-color: <cfoutput>#chr(35)#</cfoutput>100E11 !important; }
					   .darkmode2 { background-color: <cfoutput>#chr(35)#</cfoutput>020203 !important; }
					   .darkmode3 { background-color: <cfoutput>#chr(35)#</cfoutput>222023 !important; }

					   /* Custom Dark Mode Font Colors */
					   h1, h3, p, span, a { color: <cfoutput>#chr(35)#</cfoutput>fdfdfd !important; }
					   h2, h2 a { color: <cfoutput>#chr(35)#</cfoutput>028383 !important; }
					   .white { color: <cfoutput>#chr(35)#</cfoutput>fdfdfd !important; }


					   /* Custom Dark Mode Text Link Color */
					   .link { color: <cfoutput>#chr(35)#</cfoutput>028383 !important; }
					   .footer a.link { color: <cfoutput>#chr(35)#</cfoutput>fdfdfd !important; }
				  }

				  /* Copy dark mode styles for android support */
				  /* Shows Dark Mode-Only Content, Like Images */
				  [data-ogsc] .dark-img {
					   display: block !important;
					   width: auto !important;
					   overflow: visible !important;
					   float: none !important;
					   max-height: inherit !important;
					   max-width: inherit !important;
					   line-height: auto !important;
					   margin-top: 0px !important;
					   visibility: inherit !important;
				  }

				  /* Hides Light Mode-Only Content, Like Images */
				  [data-ogsc] .light-img {
					   display: none;
					   display: none !important;
				  }

				  /* Custom Dark Mode Background Color */
				  [data-ogsc] .darkmode { background-color: <cfoutput>#chr(35)#</cfoutput>100E11 !important; }
				  [data-ogsc] .darkmode2 { background-color: <cfoutput>#chr(35)#</cfoutput>020203 !important; }
				  [data-ogsc] .darkmode3 { background-color: <cfoutput>#chr(35)#</cfoutput>222023 !important; }

				  /* Custom Dark Mode Font Colors */
				  [data-ogsc] h1, [data-ogsc] h3, [data-ogsc] p, [data-ogsc] span, [data-ogsc] a { color: <cfoutput>#chr(35)#</cfoutput>fdfdfd !important; }
				  [data-ogsc] h2, [data-ogsc] h2 a { color: <cfoutput>#chr(35)#</cfoutput>028383 !important; }
				  [data-ogsc] .white { color: <cfoutput>#chr(35)#</cfoutput>fdfdfd !important; }

				  /* Custom Dark Mode Text Link Color */
				  [data-ogsc] .link { color: <cfoutput>#chr(35)#</cfoutput>028383 !important; }
				  [data-ogsc] .footer a.link { color: <cfoutput>#chr(35)#</cfoutput>fdfdfd !important; }
				  </style>

				  <!--- Correct superscripts in Outlook --->
				  <!--[if (gte mso 9)|(IE)]>
				  <style>
				  sup{font-size:100% !important;}
				  </style>
				  <![endif]-->
				  <title><cfoutput>#arguments.emailTitle#</cfoutput></title>
			 </head>

			  <body id="body" class="darkmode body body-fix">
				  <div role="article" aria-roledescription="email" aria-label="<cfoutput>#blogTitle#</cfoutput>" xml:lang="en" lang="en">

					   <!--- Start of email --->
					   <table class="darkmode" cellpadding="0" cellspacing="0" border="0" role="presentation" style="width:100%; background: ##eeeeee;">
							<!--- Main content --->
							<tr>
								 <td class="tPad-0" align="center" valign="top" style="padding-top: 10px;">
									  <table class="w100p darkmode2" cellpadding="0" cellspacing="0" border="0" role="presentation" style="width: <cfoutput>#maxWidth#</cfoutput>px; background-color: ##ffffff;">
										   <tr>
												<td align="center" valign="top" style="padding:10px 0; background-color: <cfoutput>#headerBackgroundColor#</cfoutput>">
												<!--- Header with logo --->
													 <!--- Light mode logo --->
													 <a href="<cfoutput>#application.blogHostUrl#</cfoutput>" target="_blank"><img class="light-img" src="<cfoutput>#application.blogHostUrl##logoPath#</cfoutput>" alt="<cfoutput>#blogTitle#</cfoutput>"
													 style="color: ##4a4a4a; font-family: 'Trebuchet MS', Arial, sans-serif; text-align:center; font-weight:bold; font-size:24px; line-height:28x; text-decoration: none; padding: 0;">
														  <!--- Dark mode logo--->
														  <!--[if !mso]><! -->
														  <div class="dark-img" style="display:none; overflow:hidden; width:0px; max-height:0px; max-width:0px; line-height:0px; visibility:hidden;" align="center">
															   <img src="<cfoutput>#application.blogHostUrl##logoPath#</cfoutput>" alt="<cfoutput>#blogTitle#</cfoutput>" style="color: ##4a4a4a; font-family: 'Trebuchet MS', Arial, sans-serif; text-align:center; font-weight:bold; font-size:24px; line-height:28px; text-decoration: none; padding: 0;" border="0" />
														  </div>
														  <!--<![endif]-->
													 </a>
												</td>
										   </tr>
										   <tr>
												<td align="center" valign="top" style="padding:0 0 10px;">
													<!--- Headline --->
													<h2 style="font-family: 'Trebuchet MS', Arial, sans-serif; margin: 0;font-size: 36px; line-height: 46px; text-align: center; color: ##028383; font-weight: normal;">
													<cfif len(arguments.emailTitleLink)>
														<a href="<cfoutput>#arguments.emailTitleLink#</cfoutput>" target="_blank" style="color: ##0a080b; text-decoration: none;">
													</cfif>
													<cfoutput>#arguments.emailTitle#</cfoutput>
													<cfif len(arguments.emailTitleLink)></a></cfif>
													</h2>
												</td>
										   </tr>
										<cfif len(arguments.emailDesc)>
										   <tr>
												<td align="center" valign="top" style="padding:0 0 10px;">
													 <!--- Post Description --->
													 <p class="std" style="font-family: 'Trebuchet MS', Arial, sans-serif; margin: 0 20px; font-size: 22px; line-height: 40px; font-weight: normal; color: ##0A080B;"><cfoutput>#arguments.emailDesc#</cfoutput></p>
												</td>
										   </tr>
										</cfif>
										<cfif len(arguments.mediaUrl)>
										   	<tr>
												<td align="center" valign="top" style="padding: 0 0 10px;">
													 <!--- Full width image (no LR padding) --->
													 <a href="http://<cfoutput>#application.blogDomain##mediaUrl#</cfoutput>" target="_blank"><img src="http://<cfoutput>#application.blogDomain##mediaUrl#</cfoutput>" class="fadeimg" width="<cfoutput>#maxWidth#</cfoutput>" height="400" alt="<cfoutput>#arguments.emailTitle#</cfoutput>" style="width: 100%; max-width: <cfoutput>#maxWidth#px</cfoutput>px; height: auto;" /></a>
												</td>
										   	</tr>
										</cfif><!---<cfif len(arguments.mediaUrl)>--->
										   <tr>
												<td align="center" valign="top" style="padding:0 10px 20px;">
													 <!---Divider--->
													 <hr style="border: 0; height: 1px; margin: 0; background: ##999;" />
												</td>
										   </tr>
										   <tr>
												<td align="left" valign="top" style="padding: 0 10px 20px; font-family: 'Trebuchet MS', Arial, sans-serif; margin: 0 20px; font-size: 16px; font-weight: normal;">
													 <cfoutput>#arguments.emailBody#</cfoutput>
												</td>
										   </tr>
										<cfif len(arguments.callToActionText) and len(arguments.callToActionLink)>
										   <tr>
												<td align="center" valign="top" style="padding:0 10px 20px;">
													 <!---Divider--->
													 <hr style="border: 0; height: 1px; margin: 0; background: ##999;" />
												</td>
										   </tr>
										   <tr>
												<td align="center" valign="top" style="padding:0 0 50px;">
													 <!--- CTA button --->
													<a href="<cfoutput>#arguments.callToActionLink#</cfoutput>" class="cta" style="background-color: ##<cfoutput>#primaryButtonColor#</cfoutput>; font-size: 18px; font-family: 'Trebuchet MS', Arial, sans-serif; font-weight:bold; text-decoration: none; padding: 14px 20px; color: ##ffffff; display:inline-block; mso-padding-alt:0;"> <!--[if mso]><i style="letter-spacing: 25px;mso-font-width:-100%;mso-text-raise:30pt">&nbsp;</i><![endif]--><span style="mso-text-raise:15pt;"><cfoutput>#arguments.callToActionText#</cfoutput></span><!--[if mso]><i style="letter-spacing: 25px;mso-font-width:-100%">&nbsp;</i><![endif]--></a>
												</td>
										   </tr>
										</cfif> 
										   <tr>
												<td align="center" valign="top" style="padding:0 10px 20px;">
													 <!---Divider--->
													 <hr style="border: 0; height: 1px; margin: 0; background: ##999;" />
												</td>
										   </tr>
										   <tr>
												<td class="darkmode footer" align="center" valign="top" style="padding:50px 30px; background: ##eeeeee;">
													 <!--Footer-->
													 <p style="font-family: 'Trebuchet MS', Arial, sans-serif;font-size:14px;line-height:24px;mso-line-height-rule:exactly;color:##0a080b;margin-bottom:20px;"><cfoutput>#blogTitle#</cfoutput><br><br>
													 <a href="<cfoutput>#application.blogHostUrl#</cfoutput>/?about" class="link" target="_blank" style="color: ##0a080b; text-decoration: underline;">About</a>
													&nbsp;&nbsp;|&nbsp;&nbsp;<a href="<cfoutput>#application.blogHostUrl#</cfoutput>/?contact" class="link" target="_blank" style="color: ##0a080b; text-decoration: underline;">Contact</a>
												<cfif len(arguments.unSubscribeLink)>
													&nbsp;&nbsp;|&nbsp;&nbsp;<a href="<cfoutput>#arguments.unSubscribeLink#</cfoutput>/" class="link" target="_blank" style="color: ##0a080b; text-decoration: underline;">Unsubscribe</a>
												</cfif><!---<cfif len(arguments.unSubscribeLink)>--->
													 </p>
												</td>
										   </tr>

									  </table>
								 </td>
							</tr>
					   </table>
				  </div>

			 <!-- analytics (in an upcoming version...) -->

			 </body>

		</html>
		</cfsavecontent>
			
		<!--- Return it --->
		<cfreturn emailBody>
			
	</cffunction>
			
	<!--- //************************************************************************************************
		Specific common email functions 
	//**************************************************************************************************--->
			
	<cffunction name="renderPostEmailToSubscribers" returntype="string" output="true"
			hint="Renders and sends out an email to the subscriber when a new post is made. Pass in the postId.">
		<cfargument name="postId" type="string" required="yes">
		<cfargument name="email" type="string" required="yes">
		<cfargument name="token" type="string" required="yes">
			
		<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
		<cfset getPost = application.blog.getPostByPostId(arguments.postId,false,false)>
			
		<!--- Get the suscriber info from the HQL result --->
		<cfset email = arguments.email>
		<cfset emailTitle = getPost[1]["Title"]>
		<cfset emailTitleLink = application.blog.makeLink(arguments.postId)>
		<cfset emailDesc = getPost[1]["Description"]>
		<cfset mediaUrl = getPost[1]["MediaUrl"]>
		<cfset emailBody = this.renderBody(getPost[1]["body"], getPost[1]["mediaPath"])>
		<cfset callToActionText = "View on Web">
		<cfset callToActionLink = "#emailTitleLink#">
		<cfset unSubscribeLink = "#application.blogHostUrl#/?unsubscribe&email=#arguments.email#&amp;token=#arguments.token#">

		<!--- Invoke the render email function --->
		<cfinvoke component="#this#" method="renderEmail" returnvariable="emailBody">
			<cfinvokeargument name="email" value="#email#">
			<cfinvokeargument name="emailTitle" value="#emailTitle#">
			<cfinvokeargument name="emailTitleLink" value="#emailTitleLink#">
			<cfinvokeargument name="emailDesc" value="#emailDesc#">
			<cfinvokeargument name="mediaUrl" value="#mediaUrl#">
			<cfinvokeargument name="emailBody" value="#emailBody#">
			<cfinvokeargument name="callToActionText" value="#callToActionText#">
			<cfinvokeargument name="callToActionLink" value="#callToActionLink#">
			<cfinvokeargument name="unSubscribeLink" value="#unSubscribeLink#">
		</cfinvoke>

		<!--- Return it --->
		<cfreturn emailBody>
				
	</cffunction>
			
	<cffunction name="renderCommentEmailToPostSubscribers" returntype="string" output="true"
			hint="Renders email that will be sent to the post subscribers when a comment is made or approved.">
		<!--- Required args --->
		<cfargument name="commentId" type="any" required="yes" hint="Pass in the commentId">
		<cfargument name="emailTo" type="any" required="yes" hint="Who are you emailing this too?">
		<!--- Optional args. Only use these to modify the default behavior --->
		<cfargument name="postId" type="any" required="no" default="" hint="Pass in the postId. This is needed to generate a link">
		<cfargument name="postTitle" type="any" required="no"  default="" hint="What is the title of the post?">
		<cfargument name="commenterName" type="any" required="no"  default="" hint="Pass in the commenter name">
		<cfargument name="commenterEmail" type="any" required="no"  default="" hint="Pass in the commenter email">
		<cfargument name="commenterWebsite" type="any" required="no"  default="" hint="Pass in the commenter website">
		<cfargument name="comments" type="any" required="no"  default="" hint="Pass in the comments">
		<cfargument name="callToActionText" type="any" required="no"  default="" hint="What is the text of the CTA button?">
		<cfargument name="callToActionLink" type="any" required="no"  default="" hint="What is the link of the CTA link?">
		<cfargument name="unSubscribeLink" type="any" required="no"  default="" hint="What is the link to unsubscribe?">
			
		<!--- Get the comment. The comment table will have the postId --->
		<cfset getComment = application.blog.getComment(commentId=#commentId#)>
		<!--- Get the subsriber, in particular the commenterToken to buid the unsubscribe link --->
		<cfset getSubscriber = application.blog.getSubscriber(subscriberEmail=#getComment[1]["CommenterEmail"]#, postId=#getComment[1]["PostId"]#)>
			
		<!--- Set the values --->
		<cfif not len(arguments.postId)>
			<cfset postId = getComment[1]["PostId"]>
		<cfelse>
			<cfset postId = arguments.postId>	
		</cfif>
			
		<cfif not len(arguments.postTitle)>
			<cfset postTitle = getComment[1]["PostTitle"]>
		<cfelse>
			<cfset postTitle = arguments.postTitle>
		</cfif>
			
		<cfif not len(arguments.commenterName)>
			<cfset commenterName = getComment[1]["CommenterFullName"]>
		<cfelse>
			<cfset commenterName =arguments.commenterName>	
		</cfif>
			
		<cfif not len(arguments.commenterEmail)>
			<cfset commenterEmail = getComment[1]["CommenterEmail"]>
		<cfelse>
			<cfset commenterEmail =arguments.commenterEmail>
		</cfif>
			
		<cfif not len(arguments.comments)>
			<cfset comments = getComment[1]["PostTitle"]>
		<cfelse>
			<cfset comments =arguments.comments>	
		</cfif>
			
		<cfif not len(arguments.callToActionText)>
			<cfset callToActionText = "View on Web">
		<cfelse>
			<cfset callToActionText =arguments.callToActionText>
		</cfif>
			
		<cfif not len(arguments.callToActionLink)>
			<cfset callToActionLink = "#application.blog.makeLink(postId)###c#commentId#">
		<cfelse>
			<cfset callToActionLink = arguments.callToActionLink>
		</cfif>
			
		<cfif not len(arguments.unsubscribeLink)>
			<cfset unsubscribeLink = application.blogHostUrl & "/?unsubscribe&email=& " & commenterEmail & "&token=" & getSubscriber[1]["SubscriberToken"]>
		<cfelse>
			<cfset unsubscribeLink = arguments.unsubscribeLink>
		</cfif>
			
		<!--- Create the main email content --->
		<cfsavecontent variable="contentBody">
		<cfoutput>
			<table cellpadding="5" cellspacing="5" border="0" align="left">
				<tr>
					<td>
						<div id="avatar" style="text-align: center;margin:30px 0 0 0; padding:20px 0 20px 0; width: 100%; height: 100%;">
							<img src="http://www.gravatar.com/avatar/#lcase(hash(lcase(commenterEmail)))#?s=64&amp;r=pg&amp;d=#application.blogHostUrl#/images/defaultAvatar.gif" id="avatar_image" border="0" title="#commenterName#'s Gravatar" align="left" style="width:80px; height:80px; padding:5px; background:white; border:1px solid ##e4e8af; border-radius: 50%; -moz-border-radius: 50%; -webkit-border-radius: 50%;" />
							<cfif len(commenterWebSite)><a href="#commenterWebSite#"></cfif>#commenterName#<cfif len(commenterWebSite)></a></cfif>
						</div>
					</td>
				</tr>
				<tr>
					<td colspan="2">
						#(htmlEditFormat(comments))#
					</td>
				</tr>
			</table>
		</cfoutput>
		</cfsavecontent>

		<!--- Now that we have the content body, pass it to the render component and render the rest of the email --->
		<cfinvoke component="#this#" method="renderEmail" returnvariable="emailBody">
			<cfinvokeargument name="email" value="#application.BlogDbObj.getBlogEmail()#">
			<cfinvokeargument name="emailTitle" value="Comment added to #postTitle#">
			<cfinvokeargument name="emailTitleLink" value="#application.blog.makeLink(postId)###c#commentId#">
			<cfinvokeargument name="emailDesc" value="#commenterName# added a comment">
			<cfinvokeargument name="emailBody" value="#contentBody#">
			<cfinvokeargument name="callToActionText" value="#callToActionText#">
			<cfinvokeargument name="callToActionLink" value="#callToActionLink#">
			<cfinvokeargument name="unSubscribeLink" value="#unSubscribeLink#">
		</cfinvoke>
				
		<!--- Return it --->
		<cfreturn emailBody>
			
	</cffunction>
			
	<!--- //************************************************************************************************
		LD Json injection
	//**************************************************************************************************--->
		
	<cffunction name="renderLdJson" returntype="string" output="true"
			hint="Renders the enclosure video at the top of a post">
		<cfargument name="getPost" type="any" required="yes" hint="Pass in the getPost HQL query">
		<cfargument name="prettify" type="boolean" required="no" default="false">
		<!--- <cfdump var="#getPost#"> --->
			
		<!--- Preset some vars that may not be available --->
		<cfparam name="ldJson" default="">
		<cfparam name="numGoogleImages" default="0">
		<cfparam name="google16_9Thumbnail" default="">
		<cfparam name="google4_3Thumbnail" default="">
		<cfparam name="google1_1Thumbnail" default="">
	
		<!--- Get the URL. its created dynamically. --->
		<cfset postUrl = application.blog.getPostUrlByPostId(getPost[1]["PostId"])>
		
		<cfset title = getPost[1]["Title"]>
		<cfset description = getPost[1]["Description"]>
		<cfset body = getPost[1]["Body"]>
		<cfset datePosted = getPost[1]["DatePosted"]>
		<cfset fullName = getPost[1]["FullName"]>
		<!--- Extract our media from the post (videos and images) --->
		<cfset mediaType = getPost[1]["MediaType"]>
		<!--- The mime type may not be available when using external sources due to forbidden errors when trying to read the file. --->
		<cfset mimeType = getPost[1]["MimeType"]>
		<cfset mediaHeight = getPost[1]["MediaHeight"]>
		<cfset mediaPath = getPost[1]["MediaPath"]>
		<cfset mediaTitle = getPost[1]["MediaTitle"]>
		<cfset mediaPath = getPost[1]["MediaPath"]><!--- An absolute path, ie: D:\home\gregorysblog.org\wwwroot\enclosures\dumDum.png --->
		<cfset mediaUrl = getPost[1]["MediaUrl"]>
		<cfset mediaWidth = getPost[1]["MediaWidth"]>
		<!--- We need the providers video id (i.e. the YouTube or Vimeo video Id.) This is captured when creating or updating the enclosure --->
		<cfset providerVideoId = getPost[1]["ProviderVideoId"]>
		<cfset mediaVideoCoverUrl = getPost[1]["MediaVideoCoverUrl"]>
		<!--- Maps --->
		<cfset enclosureMapId = getPost[1]["EnclosureMapId"]>
		<cfset released = getPost[1]["Released"]>
		<cfset datePosted = getPost[1]["DatePosted"]>
		<cfset date = getPost[1]["Date"]>
			
		<!--- Get data from application variables --->
		<cfset blogName = application.BlogDbObj.getBlogName()>
		<cfset logo = application.baseUrl & '/' & application.blog.getLogoPathByTheme(kendoTheme=trim(application.blog.getSelectedKendoTheme()))>
			
		<!--- Get the google thumbnails. These have the same name as the enclosure and they are in the google folders. --->
			
		<!--- Get the image name and path --->
		<cfset enclosureImageName = listLast(mediaPath, "\")>
		<cfset imageBasePath = replaceNoCase(mediaPath, enclosureImageName, '')>
		<cfset imageBaseUrl = application.blogHostUrl & replaceNoCase(mediaUrl, enclosureImageName, '')>
			
		<!--- Note: there may not be an enclosure.--->
		<cfif enclosureImageName neq "">
			<!--- Set the paths. --->
			<cfset google16_9ThumbnailPath = imageBasePath & 'google\16_9\' & enclosureImageName>
			<cfset google16_9Url = imageBaseUrl & 'google/16_9/' & enclosureImageName>
			<cfset google4_3ThumbnailPath = imageBasePath & 'google\4_3\' & enclosureImageName>
			<cfset google4_3Url = imageBaseUrl & 'google/4_3/' & enclosureImageName>
			<cfset google1_1ThumbnailPath = imageBasePath & 'google\1_1\' & enclosureImageName>
			<cfset google1_1Url = imageBaseUrl & 'google/1_1/' & enclosureImageName>
			<!--- Debugging:
			<cfoutput>
				imageBasePath: #imageBasePath#<br/>
				enclosureImageName: #enclosureImageName#<br/>
				google16_9ThumbnailPath: #google16_9ThumbnailPath#<br/>
				google4_3ThumbnailPath: #google4_3ThumbnailPath#<br/>
				google1_1ThumbnailPath: #google1_1ThumbnailPath#<br/>
			</cfoutput>--->
			
			<!--- Set the vars if the file exists. We need to know how many google images to use in order to determine if we should use an image array. --->
			<cfset numGoogleImages = 0>
			<cfif fileExists(google16_9ThumbnailPath)>
				<cfset google16_9Thumbnail = google16_9Url>
				<cfset numGoogleImages = numGoogleImages + 1>
			</cfif>	
			<cfif fileExists(google4_3ThumbnailPath)>
				<cfset google4_3Thumbnail = google4_3Url>
				<cfset numGoogleImages = numGoogleImages + 1>
			</cfif>	
			<cfif fileExists(google1_1ThumbnailPath)>
				<cfset google1_1Thumbnail = google1_1Url>
				<cfset numGoogleImages = numGoogleImages + 1>
			</cfif>
		</cfif><!---<cfif enclosureImageName neq "">--->
		
		
			
		<!--- Get the largest thumbnail for the article image --->
		<cfif isDefined("google16_9Thumbnail") and len(google16_9Thumbnail)>
			<cfset articleImage = google16_9Thumbnail>
		<cfelseif isDefined("google4_3Url") and len(google4_3Url)>
			<cfset articleImage = google4_3Url>
		<cfelseif isDefined("google1_1ThumbnailPath") and len(google1_1ThumbnailPath)>
			<cfset articleImage = google1_1ThumbnailPath>	
		<cfelse>
			<cfset articleImage = "">	
		</cfif>
			
		<!--- The body was removed. It is not necessary for articles. 
		Use JSoup to clean the HTML out of the body. 
		<cfinvoke component="#application.jsoupComponentPath#" method="jsoupConvertHtmlToText" returnvariable="articleBody">
			<cfinvokeargument name="html" value="#body#">
		</cfinvoke>--->
			
		<cfif prettify>
			<cfset cr = '<br/>'>
			<cfset tab = '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'>
		</cfif>
		
		<!--- Yes, I know that this is a horrendous way of doing this, but it is fast and it works. Next version write a function to handle the formatting.--->
		<cfoutput>
		<!---<cfset ldJson = '<postData>'>--->
		<!---<cfset ldJson = ldJson & '<attachScript type="application/ld+json">'>--->
		<cfset ldJson = ''>
		<cfset ldJson = ldJson & '{'>
		  <cfset ldJson = ldJson & '"@context":"http://schema.org",'>
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '"@type":"Article",'>
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <!--- If there is only one Google image, set the image string here --->
		  <cfif numGoogleImages lt 2 and len(articleImage)>
		  	<cfset ldJson = ldJson & '"image":"' & articleImage & '",'>
		  	<cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  </cfif>
		  <cfset ldJson = ldJson & '"mainEntityOfPage":{'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<cfif prettify><cfset ldJson = ldJson & tab></cfif>
			<cfset ldJson = ldJson & '"@type":"Article",'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<cfif prettify><cfset ldJson = ldJson & tab></cfif>
			<cfset ldJson = ldJson & '"@id":"https://google.com/article"'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '},'>
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '"headline":"' & title & '",'>
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '"author":{'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<cfif prettify><cfset ldJson = ldJson & tab></cfif>
			<cfset ldJson = ldJson & '"@type":"Person",'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<cfif prettify><cfset ldJson = ldJson & tab></cfif>
			<cfset ldJson = ldJson & '"name":"' & fullName & '"'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '},'>
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		<cfset ldJson = ldJson & '"publisher":{'>
		<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<cfif prettify><cfset ldJson = ldJson & tab></cfif>
			<cfset ldJson = ldJson & '"@type":"Organization",'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<cfif prettify><cfset ldJson = ldJson & tab></cfif>
			<cfset ldJson = ldJson & '"name":"' & blogName & '",'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<cfif prettify><cfset ldJson = ldJson & tab></cfif>
			<cfset ldJson = ldJson & '"logo":{'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			  <cfif prettify><cfset ldJson = ldJson & tab & tab></cfif>
			  <cfset ldJson = ldJson & '"@type":"ImageObject",'>
			  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
			  <cfif prettify><cfset ldJson = ldJson & tab & tab></cfif>
			  <cfset ldJson = ldJson & '"url":"' & logo & '"'>
			  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<cfif prettify><cfset ldJson = ldJson & tab></cfif>
			<cfset ldJson = ldJson & '}'>
			<cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '},'><cfif prettify>
		  <cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '"url":"' & postUrl & '",'>
		  <!--- Image array if there is more than one google image --->
		  <cfif numGoogleImages gt 1 >
			  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
			  <cfset ldJson = ldJson & '"image":['>
				<cfif prettify><cfset ldJson = ldJson & cr></cfif>
				<cfif len(google16_9Thumbnail)>
					<cfif prettify><cfset ldJson = ldJson & tab></cfif>
					<cfset ldJson = ldJson & '"' & google16_9Thumbnail & '",'>
					<cfif prettify><cfset ldJson = ldJson & cr></cfif>
				</cfif>
				<cfif len(google4_3Thumbnail)>
					<cfif prettify><cfset ldJson = ldJson & tab></cfif>
					<cfset ldJson = ldJson & '"' & google4_3Thumbnail & '",'>
					<cfif prettify><cfset ldJson = ldJson & cr></cfif>
				</cfif>
				<cfif len(google1_1Thumbnail)>
					<cfif prettify><cfset ldJson = ldJson & tab></cfif>
					<cfset ldJson = ldJson & '"' & google1_1Thumbnail & '"'>
					<cfif prettify><cfset ldJson = ldJson & cr></cfif>
				</cfif>
			  <cfset ldJson = ldJson & '],'>
		  </cfif>
		  
		  <!--- Maps --->
		  <cfif len(enclosureMapId)>
		  	<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			<!--- Note: hasMap is not supported by the article schema. We will use image instead. --->
			<cfset ldJson = ldJson & '"image":"#application.baseUrl#/preview/maps.cfm?mapId=' & enclosureMapId & '",'>
		  </cfif>
		  <!---
		  The body was removed. It is not necessary.
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '"articleBody":"' & articleBody & '",'>
			--->
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '"datePublished":"' & application.Udf.getIsoTimeString(datePosted) & '",'>
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		  <cfset ldJson = ldJson & '"dateModified":"' & application.Udf.getIsoTimeString(date) & '"'>
		  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
		<cfset ldJson = ldJson & '}'>
		<!--- Add the comma if there is a video --->
		<cfif mimeType eq 'video/mp4'>
			<cfset ldJson = ldJson & ','>
		</cfif>
		<cfif prettify><cfset ldJson = ldJson & cr></cfif>
		<!---<cfset ldJson = ldJson & '</attachScript>'>
		<cfset ldJson = ldJson & '</postData>'>--->
			
		<!--- Note: videos should be attached at the end of the document --->
		<cfif mimeType eq 'video/mp4'>
			  <cfif prettify><cfset ldJson = ldJson></cfif>
			  <cfset ldJson = ldJson & '{'>
			  <cfif prettify><cfset ldJson = ldJson & cr></cfif>
			  	<cfif prettify><cfset ldJson = ldJson & tab></cfif>
				<cfset ldJson = ldJson & '"@type":"VideoObject",'>
				<cfif prettify><cfset ldJson = ldJson & cr></cfif>
				<cfif prettify><cfset ldJson = ldJson & tab></cfif>
		  		<cfset ldJson = ldJson & '"name":"' & title & '",'>
				<cfif prettify><cfset ldJson = ldJson & cr></cfif>
				<cfif len(mediaVideoCoverUrl)>
					<cfif prettify><cfset ldJson = ldJson & tab & tab></cfif>
					<cfset ldJson = ldJson & '"thumbnailUrl":"' & mediaVideoCoverUrl & '",'>
					<cfif prettify><cfset ldJson = ldJson & cr></cfif>
				</cfif>
				<cfif prettify><cfset ldJson = ldJson & tab></cfif>
				<cfset ldJson = ldJson & '"contentUrl":"#application.baseUrl#/galaxiePlayer.cfm?videoUrl=' & mediaUrl & '",'>
				<cfif prettify><cfset ldJson = ldJson & cr></cfif>
			  	<cfif prettify><cfset ldJson = ldJson & tab></cfif>
				<cfset ldJson = ldJson & '"uploadDate":"' & application.Udf.getIsoTimeString(datePosted)>
				<cfif prettify><cfset ldJson = ldJson & cr></cfif>
				<cfset ldJson = ldJson & '}'>
			</cfif>
		</cfoutput>	
			  
		<cfreturn ldJson>
		
	</cffunction>
		
</cfcomponent>			