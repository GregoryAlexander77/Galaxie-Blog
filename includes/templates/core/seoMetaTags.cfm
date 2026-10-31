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

				<!--- 2026-10-12: the description (meta, Twitter and Open Graph) is the post's own Description when it has one.
				Before this every post and page used the blog's description, so search results and shared links all showed the
				same text (on gregoryalexander.com, just "Gregory's Blog"). Skipped when it is empty or still the Post entity's
				placeholder default. A descMetaTag directive in the post header still wins (see getXmlOverride below). The value
				goes into double-quoted content="..." attributes, so it is encoded here (encodeForHtml escapes quotes, and unlike encodeForHtmlAttribute it leaves spaces readable); the blog description above is left as it was. --->
				<cfif structKeyExists(getPost[1], "Description") and not isNull(getPost[1]["Description"])
					and len(trim(getPost[1]["Description"]))
					and trim(getPost[1]["Description"]) neq "This should be set to a length of 160 in the future">
					<cfset descriptionMetaTagValue = encodeForHtml(trim(getPost[1]["Description"]))>
				</cfif>

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

		<!--- Pictures are files, so their addresses never have /index.cfm in them (2026-10-16): on a site without URL rewriting,
		thisUrl ends in /index.cfm, and https://example.com/index.cfm/enclosures/... returns the blog's home page instead of the
		picture, so link previews on Facebook, X and the like had no picture. --->
		<cfset seoFileBaseUrl = replaceNoCase(thisUrl, "/index.cfm", "")>
		<!--- Preset the default social media image URLs. We will overwrite these later if they're available. --->
		<cfset facebookImageMetaTagValue = seoFileBaseUrl & getTheme[1]["DefaultLogoImageForSocialMediaShare"]>
		<cfset twitterImageMetaTagValue = seoFileBaseUrl & getTheme[1]["DefaultLogoImageForSocialMediaShare"]>
		<!--- Only ever set (non-empty) for an actual post whose Pinterest crop exists - see the pinterest block below. Preset empty here so head.cfm's <cfif len(pinterestImageMetaTagValue)> check always has a defined variable to read on every page type. --->
		<cfset pinterestImageMetaTagValue = "">
		<!--- og:image:width and og:image:height, only when the picture's size is known (2026-10-31). --->
		<cfset facebookImageWidth = "">
		<cfset facebookImageHeight = "">

		<!--- Default twitter card type. We will rewrite this if the twitterMediaUrlMetaData is defined. --->
		<cfset twitterCardType = "summary_large_image">

		<!--- Is this page displaying a single post?--->
		<cfif getPageMode() eq 'post'>

			<!--- **********************************************************************************************************
				Post Images
			************************************************************************************************************--->
			<!--- Determine if there is an enclosure, and if the social media images exist for this enclosure. We may over-ride these variables later if the social media images are embedded in xml in the post. --->

			<!--- The post's share pictures (2026-10-31, owner): from its image enclosure or, failing that, its Hero Cover Image -
			createSocialMediaImages() made the same crops for either at upload time (see ProxyController.cfc uploadImage()).
			Per platform: its own crop -> the classic 1200x900 crop -> the uploaded picture as it is. Each crop is kept in the
			picture's own format (JPG or PNG) and as WebP; the JPG or PNG is used first (it was WebP first): Slack, LinkedIn, some
			chat apps and older Facebook crawlers show no picture for a WebP. A manually typed directive still wins below. --->
			<cfset shareSourceUrl = "">
			<cfif len(getPost[1]["MediaUrl"]) and (getPost[1]["MediaUrl"] contains '.jpg' or getPost[1]["MediaUrl"] contains '.gif' or getPost[1]["MediaUrl"] contains '.png' or getPost[1]["MediaUrl"] contains '.webp')>
				<cfset shareSourceUrl = getPost[1]["MediaUrl"]>
			<cfelseif len(getPost[1]["HeroCoverImageUrl"])>
				<cfset shareSourceUrl = getPost[1]["HeroCoverImageUrl"]>
			</cfif>
			<cfif len(shareSourceUrl)>
				<cfscript>
					shareFileName = getFileFromPath(shareSourceUrl);
					shareFileNoExt = reReplaceNoCase(shareFileName, "\.[^.]+$", "");
					// One platform's crop: the picture's own format first, then WebP. Empty when neither file is there.
					pickShareImage = function (required string folder) {
						var webPath = application.baseUrl & "/enclosures/" & arguments.folder & "/";
						var candidates = [];
						if (!reFindNoCase("\.webp$", shareFileName)) { arrayAppend(candidates, shareFileName); }
						arrayAppend(candidates, shareFileNoExt & ".webp");
						for (var name in candidates) {
							var localPath = expandPath(webPath & name);
							if (fileExists(localPath)) { return { url: seoFileBaseUrl & "/enclosures/" & arguments.folder & "/" & name, path: localPath }; }
						}
						return {};
					};
					// A picture's size for og:image:width and og:image:height, read once (a few milliseconds) and kept until the file
					// changes. Empty when it can't be read.
					shareImageSize = function (required string localPath) {
						var size = { width: "", height: "" };
						try {
							var stamp = getFileInfo(arguments.localPath).lastModified;
							if (!structKeyExists(application, "galaxieShareImageSizes") || structCount(application.galaxieShareImageSizes) > 2000) { application.galaxieShareImageSizes = {}; }
							var kept = application.galaxieShareImageSizes[arguments.localPath] ?: "";
							if (isStruct(kept) && kept.stamp == stamp) { return kept; }
							var picture = imageRead(arguments.localPath);
							size = { width: imageGetWidth(picture), height: imageGetHeight(picture), stamp: stamp };
							application.galaxieShareImageSizes[arguments.localPath] = size;
						} catch (any e) {}
						return size;
					};
					shareFacebook = pickShareImage("facebook");
					if (structIsEmpty(shareFacebook)) { shareFacebook = pickShareImage("classic"); }
					shareTwitter = pickShareImage("twitter");
					if (structIsEmpty(shareTwitter)) { shareTwitter = pickShareImage("classic"); }
					facebookImageMetaTagValue = structIsEmpty(shareFacebook) ? shareSourceUrl : shareFacebook.url;
					twitterImageMetaTagValue = structIsEmpty(shareTwitter) ? shareSourceUrl : shareTwitter.url;
					if (!structIsEmpty(shareFacebook)) {
						shareSize = shareImageSize(shareFacebook.path);
						facebookImageWidth = shareSize.width;
						facebookImageHeight = shareSize.height;
					}
					// Pinterest's 1000x1500 crop only exists when the picture was big enough; there is no fallback for it.
					// Multiple og:image tags are valid; Pinterest looks at all of them for a Rich Pin.
					sharePinterest = pickShareImage("pinterest");
					pinterestImageMetaTagValue = structIsEmpty(sharePinterest) ? "" : sharePinterest.url;
				</cfscript>
			</cfif>
					
			<!--- Galaxie Blog Directive to change the Kendo library for a post. This is handy in order to use the much smaller Kendo Core library for the main site but still be able to include the professional Kendo version (if you have a license) to occassionally handle more advanced stuff, like Kendo grids --->
			<cfif findNoCase("kendoCommercial", xmlKeywords) gt 0>
				<!--- An explicit per-post directive always wins over the automatic detection below. --->
				<cfset thisKendoCommercial = application.blog.getXmlKeywordValue(getPost[1]["PostHeader"], 'kendoCommercial')>
			<cfelseif pageTypeId neq 2><!--- Always (owner, 2026-10-28): public pages use Kendo Core unless a post needs a Professional widget. --->
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
			<cfset shareImageBeforeOverride = facebookImageMetaTagValue>
			<cfset facebookImageMetaTagValue = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "facebookImageUrlMetaData", facebookImageMetaTagValue)>
			<cfif facebookImageMetaTagValue neq shareImageBeforeOverride><cfset facebookImageWidth = ""><cfset facebookImageHeight = ""></cfif>
			<cfset twitterImageMetaTagValue = getXmlOverride(xmlKeywords, getPost[1]["PostHeader"], "twitterImageUrlMetaData", twitterImageMetaTagValue)>

		<cfelseif pageTypeId neq 2><!--- Always (owner, 2026-10-28): public pages use Kendo Core unless a post needs a Professional widget. --->
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
		<cfelse>
			<!--- Every other page - a Page Collection, a category, the collections page, page 2+ of a listing - used to
			fall back to the site's root URL, which told search engines it was a copy of the homepage; Lighthouse
			reports that as "Document does not have a valid rel=canonical" (2026-10-09). Use the page's own address
			instead: the blog's own scheme and host (the www redirect already sends visitors there), plus the path as
			the visitor sees it, before any URL rewrite. Query strings are dropped except startRow, so each page of a
			listing stays its own page. The homepage itself keeps the root URL. --->
			<cfif structKeyExists(cgi, "http_x_original_url") and len(cgi.http_x_original_url)>
				<cfset canonicalPath = cgi.http_x_original_url>
			<cfelseif structKeyExists(cgi, "request_uri") and len(cgi.request_uri)>
				<cfset canonicalPath = cgi.request_uri>
			<cfelse>
				<cfset canonicalPath = cgi.script_name & cgi.path_info>
			</cfif>
			<cfset canonicalPath = listFirst(canonicalPath, "?")>
			<!--- The path comes from the request and head.cfm writes canonicalUrl into several tags unescaped, so keep
			only characters a real Galaxie Blog address uses. --->
			<cfset canonicalPath = reReplace(canonicalPath, "[^A-Za-z0-9/_.~%-]", "", "all")>
			<cfif application.serverRewriteRuleInPlace>
				<cfset canonicalPath = replaceNoCase(canonicalPath, "/index.cfm", "")>
			</cfif>
			<cfset canonicalOrigin = reReplaceNoCase(application.blogHostUrl, "^(https?://[^/]+).*$", "\1")>
			<cfset canonicalBasePath = replace(application.blogHostUrl, canonicalOrigin, "")>
			<!--- Only override for a path below the blog's own root; the root itself stays thisUrl. --->
			<cfif len(canonicalPath) and canonicalPath neq "/" and reReplace(canonicalPath, "/$", "") neq reReplace(canonicalBasePath, "/$", "") and canonicalPath neq canonicalBasePath & "/index.cfm">
				<cfset canonicalUrl = canonicalOrigin & canonicalPath>
			</cfif>
			<cfif isDefined("url.startRow") and isNumeric(url.startRow) and url.startRow gt 1>
				<cfset canonicalUrl = canonicalUrl & (reFind("^https?://[^/]+$", canonicalUrl) ? "/" : "") & "?startRow=" & int(url.startRow)>
			</cfif>
		</cfif>
