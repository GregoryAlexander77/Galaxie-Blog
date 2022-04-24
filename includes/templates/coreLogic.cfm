	<!---Note: this is already put inside of a cfsilent tag on the index.cfm page --->
		
	<!--- //**************************************************************************************************************
			Create custom security token keys
	//*************************************************************************************************************** --->
		
	<!--- Use to delete the cookies for testing.
	<cfset exists= structdelete(session, 'encryptionKey', true)/>
	<cfset exists= structdelete(session, 'serviceKey', true)/>
	--->

	<!--- See if the encryptionKey and the serviceKey have been created in the session scope. If they don't exist, create them. --->
	<cfif not isDefined("session.encryptionKey") or not isDefined("session.serviceKey")>
		<!--- Create unique token keys --->
		<cfinvoke component="#ProxyControllerObj#" method="createTokenKeys" returnvariable="createTokenKeys" />
		<!--- Store the value in session cookies. --->
		<cfset session.encryptionKey = createTokenKeys.encryptionKey>
		<cfset session.serviceKey = createTokenKeys.serviceKey>
	</cfif>

	<!--- //**************************************************************************************************************
			Determine what to get based upon the URL and set parameters to get the articles
	//********************************************************************************************************************

	Note: in order to debug- remove the cfsilent that wraps around this and the pageSettings.cfm template on the index.cfm page.
	--->
	
	<!--- Raymond's module to inspect the URL to determine what to pass to the getPost method. Get mode also deterines the start and end row determined by what type of page this is (blog or post for example). I am going to rewrite this in version 4ish --->
	<cfmodule template="#application.baseUrl#/tags/getmode.cfm" r_params="params"/>
	<!---  
	Debugging  	
	<cfdump var="#URL#" label="URL">
	<cfdump var="#params#" label="params">
	--->
	
	<!--- //**************************************************************************************************************
			Get the posts. The posts can either be one post, or multiple posts. It is designed this way to keep the output logic the same.
	//****************************************************************************************************************--->
	
	<!--- Get the post count (note: this function must be placed above the getPost invocation below) --->
	<cfset postCount = application.blog.getPostCount(params, previewNonReleasedEntries)>
	<!--- Get the posts ( getPost(params,showRemovedPosts,showJsonLd,showPromoteAtTopOfQuery) ) --->
	<cfset getPost = application.blog.getPost(params,false,true,true)>
		
	<!--- Handle errors when the post was not found --->
	<cfif arrayLen(getPost) eq 0>
		<cfset postFound = false>
	<cfelse>
		<cfset postFound = true>
	</cfif>
	<!--- 
	Debugging: 
	<cfdump var="#params#" label="params">
	<cfdump var="#getPost#" label="getPost">
	--->
		
	<cfif postFound>
		
		<cfswitch expression="#getPageMode()#">

			<!--- //**********************************************************************************************************
				Get the post
			//************************************************************************************************************--->
			<cfcase value = "post">

				<!--- When in post mode, there will only be one element in the getPost array. --->
				<!--- If the blog is in entry or alias mode, set the URL mode to entry --->
				<cfset url.mode = "entry">
				<cfset url.postId = getPost[1]["PostId"]>
				<!--- Set the postId. I don't want to use the array syntax every time I use this variable in the code. --->
				<cfset postId = getPost[1]["PostId"]>
				<cfset title = getPost[1]["Title"]>

				<!--- ********************************************************************************************************
				Increment the view count if the user has not seen this post. 
				********************************************************************************************************  --->

				<!--- Create a new structure to determine what pages have already been viewed in this session. 
				<cfset logViewStruct = structNew()>--->

				<!--- Populate the struct 
				<cfset logViewStruct.postId = postId>
				<cfset logViewStruct.title = title>
				<cfset logViewStruct.entrymode = true>--->

				<!--- Preset the dontLog --->
				<cfset dontLog = false>
				<cfif getPageMode() neq "alias" or structKeyExists(session.viewedpages, postId)>
					<cfset dontLog = true>
				<cfelse>
					<cfset session.viewedpages[postId] = 1>
				</cfif>

				<!--- Increment the view count. --->
				<cfif not structKeyExists(session.viewedpages, postId)>
					<cfset session.viewedpages[postId] = 1>
					<cfset application.blog.logView(postId)>
				</cfif>

			</cfcase>

		</cfswitch>

		<!--- The original include to the layout.cfm template was done here. This include contained logic for the header, the includes, stylesheets, and pods, and then the layout.cfm logic ended. Older logic for the actual posts were resumed after the layout.cfm template include.
		I have redesigned the page from here to include the entire logic for the presentation, including the logic found on the old layout.cfm template. I will be reusing Raymond's server side and ColdFusion functions, but the page has been vastly redesigned. --->

		<!--- //**************************************************************************************************************
				SEO: Meta tags, social media sharing, and cononical url's
		//****************************************************************************************************************--->

		<!--- The title will be overwritten by the description if the blog is in entry mode. --->
		<cfset titleMetaTagValue = htmlEditFormat(application.BlogDbObj.getBlogTitle())>
		<cfset descriptionMetaTagValue = application.BlogDbObj.getBlogDescription()>

		<!--- Add short strings to the title when the user selected category. --->
		<cfif isDefined("attributes.title")>
			<cfset additionalTitle = ": " & attributes.title>
		<cfelse>	
			<cfset additionalTitle = "">

			<!--- Categories. --->
			<cfif getPageMode() eq "category">
				<!--- can be a list --->
				<cfset additionalTitle = "">
				<cfloop index="cat" list="#url.categoryId#">
				<!---<cftry>--->
					<cfset additionalTitle = additionalTitle & ": " & application.blog.getCategory(cat).categoryname>
					<!---<cfcatch></cfcatch>--->
				<!---</cftry>--->
				</cfloop>

				<!--- Add the short category to the Title if the user is viewing the categories --->
				<cfif additionalTitle neq "">
					<cfset titleMetaTagValue = titleMetaTagValue & ": " & additionalTitle>
				</cfif>

			<!--- We're reading a single post. We're going to change the title to be the title of the post here.  --->
			<cfelseif getPageMode() eq "post">

				<!--- On individual entry pages, the title of the page is the title of the post. --->
				<cfset titleMetaTagValue = getPost[1]["Title"]>

				<!--- Get all of the keywords that may be enclosed in the post. The articles body may not be defined when looking at a post that contains the more tag when in blog mode. --->
				<cfif len(getPost[1]["Body"])>
					<cfset xmlKeywords = application.blog.inspectPostContentForXmlKeywords(getPost[1]["Body"])>
				<cfelse>
					<cfset xmlKeywords = "">
				</cfif>

			</cfif><!---<cfif getPageMode() eq "categories">--->
		</cfif>

		<!--- Preset the social media description variable. It may be overwritten later if the social media description is embedded in the xml within a post like so: '<socialMediaDescMetaData:this description></socialMediaDescMetaData>'. --->
		<cfset socialMediaDescMetaTagValue = descriptionMetaTagValue>

		<!--- Preset the default social media image URLs. We will overwrite these later if they're available. --->
		<cfset facebookImageMetaTagValue = thisUrl & getTheme[1]["DefaultLogoImageForSocialMediaShare"]>
		<cfset twitterImageMetaTagValue = thisUrl & getTheme[1]["DefaultLogoImageForSocialMediaShare"]>

		<!--- Default twitter card type. We will rewrite this if the twitterMediaUrlMetaData is defined. --->
		<cfset twitterCardType = "summary_large_image">


		<!--- Is this page displaying a single post?--->
		<cfif getPageMode() eq 'post'>

			<!--- **********************************************************************************************************
				Post Images
			************************************************************************************************************--->
			<!--- Determine if there is an enclosure, and if the social media images exist for this enclosure. We may over-ride these variables later if the social media images are embedded in xml in the post. --->

			<cfif len(getPost[1]["MediaUrl"]) and (getPost[1]["MediaUrl"] contains '.jpg' or getPost[1]["MediaUrl"] contains '.gif' or getPost[1]["MediaUrl"] contains '.png' or getPost[1]["MediaUrl"] contains '.webp')>

				<!--- If social media images are uploaded when a post is made, use the social media URL. --->
				<cfset facebookImageUrl = thisUrl & "/enclosures/facebook/" & getFileFromPath(getPost[1]["MediaUrl"])>
				<cfset twitterImageUrl = thisUrl & "/enclosures/twitter/" & getFileFromPath(getPost[1]["MediaUrl"])>

				<!--- If they exist, overwrite the meta tag vars. --->
				<cfif fileExists(expandPath(application.baseUrl & '/enclosures/facebook/' & getFileFromPath(getPost[1]["MediaUrl"])))>
					<cfset facebookImageMetaTagValue = facebookImageUrl>
				</cfif>
				<cfif fileExists(expandPath(application.baseUrl & '/enclosures/twitter/' & getFileFromPath(getPost[1]["MediaUrl"])))>
					<cfset twitterImageMetaTagValue = twitterImageUrl>
				</cfif>

			</cfif><!---<cfif (getPost[1]["MediaUrl"] contains '.jpg' or getPost[1]["MediaUrl"] contains '.gif' or getPost[1]["MediaUrl"] contains '.png' or getPost[1]["MediaUrl"] contains '.mp3')>--->

			<!--- SEO Meta tags. --->
			<cfif findNoCase("titleMetaTag", xmlKeywords) gt 0> 
				<!--- Overwrite the titleMetaTagValue variable. --->
				<cfset titleMetaTagValue = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'titleMetaTag')>
			</cfif>
			<cfif findNoCase("descMetaTag", xmlKeywords) gt 0> 
				<!--- Overwrite the descriptionMetaTagValue variable. --->
				<cfset descriptionMetaTagValue = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'descMetaTag')>
			</cfif>
			<!--- Check to see if there is a social media description in the post body --->
			<cfif findNoCase("socialMediaDescMetaData", xmlKeywords) gt 0> 
				<!--- Overwrite the socialMediaDescMetaTagValue variable. --->
				<cfset socialMediaDescMetaTagValue = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'socialMediaDescMetaData')>
			</cfif>

			<!--- Social Media Sharing for Images. --->
			<!--- Overwrite the facebookImageMetaTagValue variable --->
			<cfif findNoCase("facebookImageUrlMetaData", xmlKeywords) gt 0> 
				<!--- See if there is meta data inside of the blog post. --->
				<cfset facebookImageMetaTagValue = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'facebookImageUrlMetaData')>
			</cfif>
			<!--- Overwrite the twitterImageMetaTagValue --->
			<cfif findNoCase("twitterImageUrlMetaData", xmlKeywords) gt 0> 
				<!--- See if there is meta data inside of the blog post. --->
				<cfset twitterImageMetaTagValue = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'twitterImageUrlMetaData')>
			</cfif>

		</cfif><!---<cfif isDefined("URL.mode") and (URL.mode is "entry" or URL.mode eq 'alias')>--->

		<!--- //**************************************************************************************************************
		Video and Audio Content
		//****************************************************************************************************************--->

		<cfparam name="videoType" default="" type="string">
		<cfparam name="videoPosterImageUrl" default="" type="string">
		<cfparam name="smallVideoSourceUrl" default="" type="string">
		<cfparam name="mediumVideoSourceUrl" default="" type="string">
		<cfparam name="largeVideoSourceUrl" default="" type="string">
		<cfparam name="videoCaptionsUrl" default="" type="string">

		<!--- Overwrite the vars if the proper xml is embedded in the post. The xml keyword thing is temporary and will be put into the database in the future. --->
		
		<cfif findNoCase("videoType", xmlKeywords) gt 0> 
			<cfset videoType = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'videoType')>
		</cfif>
		<cfif findNoCase("videoPosterImageUrl", xmlKeywords) gt 0> 
			<cfset videoPosterImageUrl = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'videoPosterImageUrl')>
		</cfif>	
		<cfif findNoCase("smallVideoSourceUrl", xmlKeywords) gt 0> 
			<cfset smallVideoSourceUrl = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'smallVideoSourceUrl')>
		</cfif>
		<cfif findNoCase("mediumVideoSourceUrl", xmlKeywords) gt 0> 
			<cfset mediumVideoSourceUrl = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'mediumVideoSourceUrl')>
		</cfif>
		<cfif findNoCase("largeVideoSourceUrl", xmlKeywords) gt 0> 
			<cfset largeVideoSourceUrl = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'largeVideoSourceUrl')>
		</cfif>
		<cfif findNoCase("videoCaptionsUrl", xmlKeywords) gt 0> 
			<cfset videoCaptionsUrl = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'videoCaptionsUrl')>
		</cfif>
		<cfif findNoCase("videoCrossOrigin", xmlKeywords) gt 0> 
			<cfset videoCrossOrigin = application.blog.getXmlKeywordValue(getPost[1]["Body"], 'videoCrossOrigin')>
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

		<!--- //**************************************************************************************************************
		SEO: no index and canonical Url
		//****************************************************************************************************************--->

		<!--- Create a proper canonical rel tag and other SEO's --->
		<!--- Set default params --->
		<cfparam name="noIndex" default="false" type="boolean">
		<cfparam name="canonicalUrl" default="#thisUrl#" type="string">
		<cfparam name="addSocialMediaUnderEntry" default="false" type="boolean">

		<!--- Write a <meta name="robots" content="noindex"> tag for categories, postedBy, month and day in order to eliminate any duplicate content. --->
		<cfif isDefined("url.mode") and (url.mode is "cat" or url.mode is "postedBy" or url.mode is "month" or url.mode is "day")>
			<cfset noIndex = true>
		</cfif>

		<!--- Handle URL's that have arguments (theme, etc) --->
		<!--- Set the canonicalUrl to point to the correct URL (this is a single page app and there will be duplicate pages found in the crawl unfortunately). --->
		<cfif getPageMode() eq 'post'>
			<cftry>
				<cfset canonicalUrl  = application.blog.makeLink(articles.id[1])>
				<cfcatch type="any">
					<!--- This generally shows up when the link has changed. We will create a 404 status in order to drop the page from the search engines. --->
					<cfset error = "Articles or Entry is not defined">
					<cfheader statuscode="404" statustext="Page Not Found">
				</cfcatch>
			</cftry>
			<!--- Check to see if there is a URL rewrite rule in place. If a rewrite rule is in place, remove the 'index.cfm' from teh cannonicalUrl string. --->
			<cfif application.serverRewriteRuleInPlace>
				<cfset canonicalUrl = replaceNoCase(canonicalUrl, '/index.cfm', '')>
			</cfif>
			<cfset addSocialMediaUnderEntry = true>
		</cfif>
	</cfif><!---<cfif postFound>--->