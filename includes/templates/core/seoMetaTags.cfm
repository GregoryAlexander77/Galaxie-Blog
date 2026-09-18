<!--- //**************************************************************************************************************
		SEO: meta tags, social sharing, canonical URL. Assumes postFound is true (see postViewTracking.cfm note).
//****************************************************************************************************************--->
<!--- Split out of coreLogic.cfm (item 7 of the index.cfm/coreLogic.cfm rewrite proposal) so each concern is easier to find. Assumes it is included from coreLogic.cfm, which is itself included from within a <cfsilent> block on index.cfm. --->

		<!--- The original include to the layout.cfm template was done here. This include contained logic for the header, the includes, stylesheets, and pods, and then the layout.cfm logic ended. Older logic for the actual posts were resumed after the layout.cfm template include.
		I have redesigned the page from here to include the entire logic for the presentation, including the logic found on the old layout.cfm template. I will be reusing Raymond's server side and ColdFusion functions, but the page has been vastly redesigned. --->

		<!--- //**************************************************************************************************************
				SEO: Meta tags, social media sharing, and cononical url's
		//****************************************************************************************************************--->

		<!--- The title will be overwritten by the description if the blog is in entry mode. --->
		<cfset titleMetaTagValue = encodeForHTML(application.BlogDbObj.getBlogTitle())>
		<cfset descriptionMetaTagValue = application.BlogDbObj.getBlogDescription()>

		<!--- Add short strings to the title when the user selected category. --->
		<cfif isDefined("attributes.title")>
			<cfset additionalTitle = ": " & attributes.title>
		<cfelse>	
			<cfset additionalTitle = "">

			<!--- Categories. --->
			<cfif getPageMode() eq "category">
				<!--- This might be a list --->
				<cfset additionalTitle = "">
				<cfset categoryLoopCount = "1">
				<cfloop index="thisCategoryId" list="#URL.categoryId#">
					<cfset getTitle = application.blog.getCategory(thisCategoryId)>
					<cfset additionalTitle = additionalTitle & ": " & getTitle[1]['Category']>
					<cfset categoryLoopCount = categoryLoopCount + 1>
				</cfloop>
				<!--- Reset the loop count to an empty string --->
				<cfset categoryLoopCount = "">

				<!--- Add the category to the Title if the user is viewing the categories --->
				<cfif additionalTitle neq "">
					<cfset titleMetaTagValue = titleMetaTagValue & additionalTitle>
				</cfif>
				
			<!--- We're reading a single post. We're going to change the title to be the title of the post here.  --->
			<cfelseif getPageMode() eq "post">

				<!--- On individual entry pages, the title of the page is the title of the post. --->
				<cfset titleMetaTagValue = getPost[1]["Title"]>

				<!--- Get all of the keywords that may be enclosed in the post header. --->
				<cfif len(getPost[1]["PostHeader"])>
					<cfset xmlKeywords = application.blog.inspectPostContentForXmlKeywords(getPost[1]["PostHeader"])>
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
				<cfelse>
					<!--- I am manually converting files to webp in the enlosure directory and often the image won't be found in the facebook or twitter directories. If this is the case, just use the enclosure URL --->
					<cfset facebookImageMetaTagValue = getPost[1]["MediaUrl"]>
				</cfif>
				<cfif fileExists(expandPath(application.baseUrl & '/enclosures/twitter/' & getFileFromPath(getPost[1]["MediaUrl"])))>
					<cfset twitterImageMetaTagValue = twitterImageUrl>
				<cfelse>
					<cfset twitterImageMetaTagValue = getPost[1]["MediaUrl"]>
				</cfif>

			</cfif><!---<cfif (getPost[1]["MediaUrl"] contains '.jpg' or getPost[1]["MediaUrl"] contains '.gif' or getPost[1]["MediaUrl"] contains '.png' or getPost[1]["MediaUrl"] contains '.mp3')>--->
					
			<!--- Galaxie Blog Directive to change the Kendo library for a post. This is handy in order to use the much smaller Kendo Core library for the main site but still be able to include the professional Kendo version (if you have a license) to occassionally handle more advanced stuff, like Kendo grids --->
			<cfif findNoCase("kendoCommercial", xmlKeywords) gt 0>
				<!--- An explicit per-post directive always wins over the automatic detection below. --->
				<cfset thisKendoCommercial = application.blog.getXmlKeywordValue(getPost[1]["PostHeader"], 'kendoCommercial')>
			<cfelseif pageTypeId neq 2 and application.deferKendoCommercialOnPublicSite>
				<!--- No explicit directive on this post, and the blog owner wants public-facing pages to default to Kendo Core, only pulling in the larger Kendo Professional download when this specific post actually needs it (eg. it embeds a Kendo Grid). Never applies to admin pages (pageTypeId 2), which always use the site-wide kendoCommercial setting. --->
				<cfset thisKendoCommercial = application.blog.postNeedsKendoCommercial(getPost[1]["Body"], getPost[1]["MoreBody"])>
			</cfif>
			<cfif findNoCase("kendoSourceLocation", xmlKeywords) gt 0> 
				<cfset thisKendoSourceLocation = application.blog.getXmlKeywordValue(getPost[1]["PostHeader"], 'kendoSourceLocation')>
			</cfif>

			<!--- Galaxie Blog Directives to handle SEO Meta tags. getXmlOverride() (common/function/page.cfm) uses the keyword's XML value when present, otherwise keeps the value already computed above, so each of these collapses to one line. --->
			<cfset titleMetaTagValue = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "titleMetaTag", titleMetaTagValue)>
			<cfset descriptionMetaTagValue = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "descMetaTag", descriptionMetaTagValue)>
			<!--- Check to see if there is a social media description in the post body --->
			<cfset socialMediaDescMetaTagValue = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "socialMediaDescMetaData", socialMediaDescMetaTagValue)>

			<!--- Social Media Sharing for Images. --->
			<cfset facebookImageMetaTagValue = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "facebookImageUrlMetaData", facebookImageMetaTagValue)>
			<cfset twitterImageMetaTagValue = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "twitterImageUrlMetaData", twitterImageMetaTagValue)>

		<cfelseif pageTypeId neq 2 and application.deferKendoCommercialOnPublicSite>
			<!--- Listing-style pages (home, category, tag, month, day, search, etc.) only ever show post excerpts, never the full Body/MoreBody, so a Kendo Grid embed here is not a realistic case - default straight to Kendo Core instead of scanning every displayed excerpt. Never applies to admin pages (pageTypeId 2), which always use the site-wide kendoCommercial setting. --->
			<cfset thisKendoCommercial = false>
		</cfif><!---<cfif isDefined("URL.mode") and (URL.mode is "entry" or URL.mode eq 'alias')>--->
		<!--- //**************************************************************************************************************
		SEO: no index and canonical Url
		//****************************************************************************************************************--->

		<!--- Create a proper canonical rel tag and other SEO's --->
		<!--- Set default params --->
		<cfparam name="noIndex" default="false" type="boolean">
		<cfparam name="canonicalUrl" default="#thisUrl#" type="string">
		<cfparam name="addSocialMediaUnderEntry" default="false" type="boolean">

		<!--- Write a <meta name="robots" content="noindex"> meta tag for tags, postedBy, month and day in order to eliminate any duplicate content. Note: we are allowing categories as there is a breadcrumb widget --->
		<cfif isDefined("url.mode") and (url.mode is "tag" or url.mode is "postedBy" or url.mode is "month" or url.mode is "day")>
			<cfset noIndex = true>
		</cfif>

		<!--- Handle URL's that have arguments (theme, etc) --->
		<!--- Set the canonicalUrl to point to the correct URL (this is a single page app and there will be duplicate pages found in the crawl unfortunately). --->
		<cfif getPageMode() eq 'post'>
			<cftry>
				<!---
				Original code using the postId 
				<cfset canonicalUrl  = application.blog.makeLink(postId)>
				--->
				<cfset canonicalUrl = application.blog.makeLink(
					isPage=getPost[1]["IsPage"], 
					postAlias=getPost[1]["PostAlias"], 
					datePosted=getPost[1]["DatePosted"])>
				
				<cfcatch type="any">
					<!--- This generally shows up when the link has changed. We will create a 404 status in order to drop the page from the search engines. --->
					<cfset error = "Articles or Entry is not defined">
					<cfheader statuscode="404">
				</cfcatch>
			</cftry>
			<!--- Check to see if there is a URL rewrite rule in place. If a rewrite rule is in place, remove the 'index.cfm' from teh cannonicalUrl string. --->
			<cfif application.serverRewriteRuleInPlace>
				<cfset canonicalUrl = replaceNoCase(canonicalUrl, '/index.cfm', '')>
			</cfif>
			<cfset addSocialMediaUnderEntry = true>
		</cfif>
