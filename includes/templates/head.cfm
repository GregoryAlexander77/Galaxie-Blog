<cfsilent>
<!--- Debugging --->
<!---<cfoutput>#application.Udf.isLoggedIn()#</cfoutput>--->
<!---<cfdump var="#URL#" label="URL">--->
<!---<cfdump var="#pageId#" label="pageId">--->
<!---<cfdump var="#getPost#">--->
<!---<cfdump var="#URL.mode#" label="URL.mode">--->
<!---<cfdump var="#getPageMode()#" label="getPageMode()">--->
<!---<cfdump var="#titleMetaTagValue#" label="titleMetaTagValue">--->

<!--- Default values. This is only needed when the post does not exist. --->
<cfparam name="addSocialMediaUnderEntry" default="false">
	
<!--- //******************************************************************************************************
			Header properties and redirects.
//********************************************************************************************************--->
<!--- Cache this stuff --->
<cfheader name="filesMatch" value="<filesMatch '.(css|jpg|jpeg|png|gif|js|ico)$'>">

<!--- Enforce ssl if necessary. --->
<cfif useSsl and (CGI.https eq "off")>
	<cfheader statuscode="308">
	<!--- Determine the proper URL. We need to use the alias in the URL property if it exists. --->
	<cfif URL.mode eq "alias">
		<cfheader name="Location" value="#application.blog.makeLink(articles.id[1])#">
	<cfelse><!---<cfif URL.mode eq "alias">--->
		<cfif len(cgi.query_string) gt 0>
			<cfheader name="Location" value="https://#cgi.http_host##cgi.script_name#?#cgi.query_string#">
		<cfelse>
			<cfheader name="Location" value="https://#cgi.http_host##cgi.script_name#">
		</cfif>
	</cfif><!---<cfif URL.mode eq "alias">--->
</cfif><!---<cfif useSsl and (CGI.https eq "off")>--->

<!--- Handle the title when the post is not found --->
<cfif postFound>
	<cfset titleMetaTagValue = titleMetaTagValue>
<cfelse>
	<cfset titleMetaTagValue = "Post Not Found">
</cfif>
	
<!--- Determine if we should disable the robots for dev sites. The no index var is already determined when in prod --->
<cfif not application.BlogDbObj.getIsProd()>
	<cfset noIndex = true>
<cfelse>
	<cfset noIndex = false>
</cfif>
</cfsilent>
<!--- Don't show the Google Analytics script on the admin page or if the string does not exist in the database. Note: there can be many gtag measurement Ids, we are going to grab the first one for the script and loop through all of them in the config line at the bottom of the script --->
<cfif pageId neq 2 and len(application.googleAnalyticsString)>
<!-- Global site tag (gtag.js) - Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=<cfoutput>#listGetAt(application.googleAnalyticsString, 1)#</cfoutput>"></script>
<script>
	window.dataLayer = window.dataLayer || [];
	function gtag(){dataLayer.push(arguments);}
	gtag('js', new Date());
<cfloop list="#application.googleAnalyticsString#" index="i">
	gtag('config', '<cfoutput>#i#</cfoutput>');
</cfloop>
</script></cfif>
<cfoutput><title>#titleMetaTagValue#</title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="title" content="#titleMetaTagValue#" /><cfif len(application.BlogDbObj.getBlogMetaKeywords())>
<meta name="keywords" content="#application.BlogDbObj.getBlogMetaKeywords()#" /></cfif>
<meta name="robots" content="<cfif noIndex>noindex<cfelse>index, follow</cfif>" />
<cfif len(favIconHtml)>
	<cfsilent>
		<!--- Fix ColdFusions script protection where it substitues meta name wtih InvalidTag name. This should not occur as we are handling this programmatically, but it is here just in case --->
		<cfset favIconHtml = replaceNoCase(favIconHtml, 'InvalidTag name', 'meta name', 'all')>
	</cfsilent>
<!-- FavIcons --> 
#favIconHtml#
</cfif>
<cfif postFound>
<meta name="description" content="#descriptionMetaTagValue#" />
<link rel="canonical" href="#canonicalUrl#" />
<!-- Twitter meta tags. -->			
<meta name="twitter:card" content="#twitterCardType#">
<meta name="twitter:site" content="@#canonicalUrl#">
<meta name="twitter:title" content="#titleMetaTagValue#">
<meta name="twitter:description" content="#descriptionMetaTagValue#">
<!-- The twitter image is still required with player cards -->
<meta name="twitter:image" content="#twitterImageMetaTagValue#?id=#createUuid()#">
<cfif videoType neq "" and getPageMode() eq 'post'>
<!-- Twitter player card meta types -->
<!-- The twitter video must be on a mimimal page that just includes the video, and nothing else. Also, the providerMediaId must be passed here. -->
<meta property="twitter:player" content="<cfoutput>#application.blogHostUrl#/galaxiePlayer.cfm?postId=#getPost[1]['PostId']#&videoUrl=#ogVideo#&providerVideoId=#getPost[1]['ProviderVideoId']#</cfoutput>">
<meta property="twitter:player:width" content="#ogVideoWidth#">	
<meta property="twitter:player:height" content="#ogVideoHeight#">	
</cfif><!---<cfif videoType neq "" and getPageMode() eq 'post'>--->
<!-- Open graph meta tags for Facebook. See notes. -->
<meta property="og:image" content="#facebookImageMetaTagValue#"> 
<meta property="og:site_name" content="#application.BlogDbObj.getBlogTitle()#" />
<meta property="og:url" content="#canonicalUrl#" />
<meta property="og:title" content="#titleMetaTagValue#" />
<meta property="og:description" content="#descriptionMetaTagValue#" />
<cfif len(application.facebookAppId)>
<meta property="fb:app_id" content="#application.facebookAppId#">
</cfif>
<cfif videoType neq "" and getPageMode() eq 'post'>
<!-- Video meta types -->
<meta property="og:type" content="article">
<meta property="og:video:type" content="video/mp4"><!---RFC 4337 § 2, video/mp4 should be the correct Content-Type for MPEG-4 video.--->
<meta property="og:video" content="#ogVideo#">
<!-- We are omitting the og:video:url, it is the same as the og:video -->
<meta property="og:video:secure_url" content="#ogVideo#">
<meta property="og:video:width" content="#ogVideoWidth#">	
<meta property="og:video:height" content="#ogVideoHeight#">
</cfif><!---<cfif videoType neq "" and getPageMode() eq 'post'>--->
<!--TODO <meta property="og:type" content="blog" />-->
<link rel="alternate" type="application/rss+xml" title="RSS" href="#thisUrl#/rss.cfm?mode=full" />
<cfsilent>
<!--- We are only including the top level ld json when we are not in blog mode. The ld json will be in the body of the post.  ---->
<cfif getPageMode() eq 'blog'>
	<cfset struturedDataMainEntityOfPage = "Blog"><!--- The URL of a page on which the thing is the main entity. --->
	<cfset struturedDataMainEntityOfPageUrl = blogUrl>
<cfelse>
	<cfset struturedDataMainEntityOfPage = "BlogPosting"><!--- The URL of a page on which the thing is the main entity. --->
	<cfset struturedDataMainEntityOfPageUrl = canonicalUrl>
</cfif>
</cfsilent>
<cfif getPageMode() eq 'blog'>
<!-- Structured data (see schema.org). -->
<script type="application/ld+json">
{
	"@context": "http://schema.org",
	"@type": "Blog",
	"name": "#application.BlogDbObj.getBlogTitle()#",
	"url": "#struturedDataMainEntityOfPageUrl#",
	"mainEntityOfPage": {
		  "@type": "#struturedDataMainEntityOfPage#",
		  "@id": "#struturedDataMainEntityOfPageUrl#"
	},
	"description": "#descriptionMetaTagValue#",
	"publisher": {
		"@type": "Organization",
		"name": "#application.BlogDbObj.getBlogTitle()#"
	}
}
</script>
<cfelse>
	<cfif len(getPost[1]["JsonLd"])>
		<cfset jsonLd = getPost[1]["JsonLd"]>
	<cfelse>
		<!--- Instantiate our renderer obj --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		<!--- Render the json from the db (renderLdJson(getPost, prettity)) --->
		<cfset jsonLd = RendererObj.renderLdJson(getPost, false)>
	</cfif>
<!-- Structured data (see schema.org). -->
<script type="application/ld+json">
	#jsonLd#
</script>
</cfif><!---<cfif getPageMode() neq 'blog'>--->
</cfif><!---<cfif postFound>--->
	<!--- Load resources and scripts. --->
<script>
	<!--- Script to defer script resources. See https://appseeds.net/defer.js/demo.html. /*!@shinsenter/defer.js@3.9.0 --->
	!(function(r,c,f){function u(e,n,t,i){I?q(e,n):(1<(t=t===f?u.lazy:t)&&(i=e,N.push(e=function(){i&&(i(),i=f)},t)),(t?S:N).push(e,Math.max(t?350:0,n)))}function s(e){return"string"==typeof(e=e||{})?{id:e}:e}function a(n,e,t,i){l(e.split(" "),function(e){(i||r)[n+"EventListener"](e,t||o)})}function l(e,n){e.map(n)}function d(e,n){l(z.call(e.attributes),function(e){n(e.name,e.value)})}function p(e,n,t,i,o,r){if(o=E.createElement(e),t&&a(w,b,t,o),n)for(r in n)o[j](r,n[r]);return i&&E.head.appendChild(o),o}function m(e,n){return z.call((n||E).querySelectorAll(e))}function h(i,e){l(m("source,img",i),h),d(i,function(e,n,t){(t=y.exec(e))&&i[j](t[1],n)}),"string"==typeof e&&(i.className+=" "+e),i[b]&&i[b]()}function e(e,n,t){u(function(i){l(i=m(e||"script[type=deferjs]"),function(e,t){e[A]&&(t={},d(e,function(e,n){e!=C&&(t[e==A?"href":e]=n)}),t.as=g,t.rel="preload",p(v,t,f,r))}),(function o(e,t,n){(e=i[k]())&&(t={},h(e),d(e,function(e,n){e!=C&&(t[e]=n)}),n=t[A]&&!("async"in t),(t=p(g,t)).text=e.text,e.parentNode.replaceChild(t,e),n?a(w,b+" error",o,t):o())})()},n,t)}function o(e,n){for(n=I?(a(t,i),S):(a(t,x),I=u,S[0]&&a(w,i),N);n[0];)q(n[k](),n[k]())}var y=/^data-(.+)/,v="link",g="script",b="load",n="pageshow",w="add",t="remove",i="keydown mousemove mousedown touchstart wheel",x="on"+n in r?n:b,j="setAttribute",k="shift",A="src",C="type",D=r.IntersectionObserver,E=r.document,I=/p/.test(E.readyState),N=[],S=[],q=r.setTimeout,z=N.slice;u.all=e,u.dom=function(e,n,i,o,r){u(function(n){function t(e){n&&n.unobserve(e),o&&!1===o(e)||h(e,i)}n=D?new D(function(e){l(e,function(e){e.isIntersecting&&t(e.target)})},r):f,l(m(e||"[data-src]"),function(e){e[c]||(e[c]=u,n?n.observe(e):t(e))})},n,!1)},u.css=function(e,n,t,i,o){(n=s(n)).href=e,n.rel="stylesheet",u(function(){p(v,n,i,r)},t,o)},u.js=function(e,n,t,i,o){(n=s(n)).src=e,u(function(){p(g,n,i,r)},t,o)},u.reveal=h,r[c]=u,I||a(w,x),e()})(this,"Defer"),(function(e,n){n=e.defer=e.Defer,e.deferimg=e.deferiframe=n.dom,e.deferstyle=n.css,e.deferscript=n.js})(this);
</script>

<script>
	<!--- WebP support detection. Revised a script found on stack overflow: https://stackoverflow.com/questions/5573096/detecting-webp-support. It is the quickest loading script to determine webP that I have found so far. --->
	function webPImageSupport() {
		<!--- Detemine if the webp mime type is on the server. This is saved as a ColdFusion application variable. --->
		var serverSupportsWebP = <cfoutput>#application.serverSupportsWebP#</cfoutput>;
		var elem = document.createElement('canvas');

		if (serverSupportsWebP && !!(elem.getContext && elem.getContext('2d'))) {
			<!--- Is able to get WebP representation? --->
			return elem.toDataURL('image/webp').indexOf('data:image/webp') == 0;
		}
		<!--- Canvas is not supported on older browsers such as IE. --->
		return false;
	}
</script>
	<cfsilent>
		<!--- The thisKendoCommercial is a post directive (or the automatic postNeedsKendoCommercial() detection - see seoMetaTags.cfm) that overwrites the default application kendoCommercial variable. Note: this checks isDefined() alone, not "and thisKendoCommercial" - an explicit false (a post directive that turns Kendo Commercial off, or automatic detection finding the post doesn't need it) must be honored rather than silently falling through to the site default below. --->
		<cfif isDefined("thisKendoCommercial")>
			<!--- Use the value in the post directive, or the automatic detection result --->
			<cfset kendoCommercial = thisKendoCommercial>
		<cfelse>
			<!--- Use the value that is in the blog options UI --->
			<cfset kendoCommercial = application.kendoCommercial>
		</cfif>
		<!--- Apply the same logic for the source. For the directives to work with the commercial edition of Kendo, we need both the kendoCommercial and kendoSource directives for a given post. Note: this is computed fresh per-request from application.kendoFolderPath/application.baseUrl rather than reusing application.kendoSourceLocation - that value is resolved once at application start from the site-wide application.kendoCommercial only, so it's wrong for any request whose per-request kendoCommercial (above) differs from the site-wide default, which is exactly the deferKendoCommercialOnPublicSite case. --->
		<cfif isDefined("thisKendoSourceLocation") and len(thisKendoSourceLocation)>
			<!--- Use the value in the post directive --->
			<cfset kendoSourceLocation = thisKendoSourceLocation>
		<cfelseif kendoCommercial>
			<!--- This request needs Kendo Commercial - use the folder the blog owner configured for their licensed copy, same as application.kendoFolderPath is used when Commercial is the site-wide default. --->
			<cfset kendoSourceLocation = application.kendoFolderPath>
		<cfelseif len(application.kendoFolderPath) and not application.kendoCommercial and !isDefined("URL.init") and !isDefined("URL.reinit")>
			<!--- This request uses Core, and so does the site-wide default, with a folder path configured for it (a blog owner can point Core at a custom folder too, eg. a locally-modified copy) - reuse it, matching what application.kendoSourceLocation would already resolve to in this exact case. --->
			<cfset kendoSourceLocation = application.kendoFolderPath>
		<cfelse>
			<!--- This request uses Core but there's no Core-specific folder configured (either because Core is simply the default with nothing custom set, or because the site-wide default is actually Commercial and application.kendoFolderPath is configured for that instead, which is no good for Core). Point at the embedded Kendo Core package. --->
			<cfset kendoSourceLocation = application.baseUrl & "/common/libs/kendoCore/">
		</cfif>
		<!--- Safety net: a folder path taken from the post directive or the blog options admin UI (the three branches above that don't already build from application.baseUrl) may have been entered as webroot-relative (eg. "/common/libs/kendoCore/") instead of app-relative (eg. "/blog/common/libs/kendoCore/"), which 404s everything built from it. Only touch it if it doesn't already start with the app's own base path or an absolute URL (an http(s):// CDN location is a valid thing to configure here and must be left alone). --->
		<cfif len(kendoSourceLocation) and left(kendoSourceLocation, 4) neq "http" and findNoCase(application.baseUrl, kendoSourceLocation) neq 1>
			<cfset kendoSourceLocation = application.baseUrl & kendoSourceLocation>
		</cfif>
		<!--- The Kendo CSS locations need to follow the same per-request edition as the JS above (they used to be computed once in pageSettings.cfm from the site-wide default only, which mismatched the JS bundle on any page where the per-request edition differed from the site default - eg. every deferred page once deferKendoCommercialOnPublicSite is turned on). --->
		<cfset kendoCommonCssFileLocation = trim(kendoSourceLocation & getTheme[1]["KendoCommonCssFileLocation"])>
		<cfset kendoThemeCssFileLocation = trim(kendoSourceLocation & getTheme[1]["KendoThemeCssFileLocation"])>
		<cfset kendoThemeMobileCssFileLocation = trim(kendoSourceLocation & getTheme[1]["KendoThemeMobileCssFileLocation"])>
		<!--- Which Kendo Core bundle to load. kendo.ui.core.min.js has every Kendo Core widget (about 900 KB), but this blog only uses a few of them. The public site loads kendo.galaxie.public.min.js, the administrative site loads kendo.galaxie.admin.min.js, and a post that uses a widget that is not in the public bundle gets the full bundle. See /common/libs/kendoCore/build-galaxie-bundle.sh. Kendo Professional (kendo.all.min.js) is not affected, and neither is Kendo Core that is loaded from a folder that is not the embedded Kendo Core folder. --->
		<cfset kendoJsFile = "kendo.ui.core.min">
		<cfif not kendoCommercial and left(kendoSourceLocation, 4) neq "http" and findNoCase("/common/libs/kendoCore/", kendoSourceLocation)>
			<!--- Make sure that the bundles were uploaded (this is remembered until the application is restarted) --->
			<cfif not structKeyExists(application, "kendoGalaxieBundlesExist")>
				<cfset application.kendoGalaxieBundlesExist = fileExists(expandPath(application.baseUrl & "/common/libs/kendoCore/js/kendo.galaxie.public.min.js")) and fileExists(expandPath(application.baseUrl & "/common/libs/kendoCore/js/kendo.galaxie.admin.min.js"))>
			</cfif>
			<cfif application.kendoGalaxieBundlesExist>
				<cfif pageTypeId eq 2 or application.Udf.isLoggedIn()>
					<cfset kendoJsFile = "kendo.galaxie.admin.min">
				<cfelse>
					<cfset kendoJsFile = "kendo.galaxie.public.min">
					<!--- A post may use a widget that is not in the public bundle --->
					<cfif isDefined("url.mode") and (url.mode is "entry" or url.mode is "alias") and arrayLen(getPost)>
						<cfset kendoPostText = "">
						<cfloop list="Body,MoreBody,JavaScript,PostHeader" index="kendoPostColumn">
							<cfif structKeyExists(getPost[1], kendoPostColumn)>
								<cfset kendoPostText = kendoPostText & " " & getPost[1][kendoPostColumn]>
							</cfif>
						</cfloop>
						<cfif application.blog.postNeedsFullKendoCore(kendoPostText)>
							<cfset kendoJsFile = "kendo.ui.core.min">
						</cfif>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
		<!--- The Kendo mobile stylesheet (kendo.<theme>.mobile.min.css) is only for the Kendo mobile widgets and a few badge and app bar styles that this blog does not use. It is not needed with the Kendo Core bundles of this blog (they do not have the mobile widgets). It is still loaded with Kendo Professional, and with the full Kendo Core file (which has the mobile widgets) that a post that needs it, or a custom Kendo folder, gets. --->
		<cfset loadKendoMobileCss = kendoCommercial or kendoJsFile eq "kendo.ui.core.min">
	</cfsilent>
 	<!--- The jQuery script can't be defered as the Kendo controls won't work. We're using jQuery 1.2. Later jQuery versions don't work with Kendo UI core unfortunately. --->
<cfif kendoCommercial>
<!--- Use the 3.5.1 version if using commercial. --->
<script rel="preconnect"
	src="https://code.jquery.com/jquery-3.5.1.min.js"
	integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0="
	crossorigin="anonymous"></script>
<cfelse>
<!--- 
Use the jQuery 3.7.1 CDN for Kendo Core. 
Either use https://code.jquery.com/jquery-3.7.1.min.js or https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js. The full link from jQuery is:
<script
  src="https://code.jquery.com/jquery-3.7.1.min.js"
  integrity="sha256-CSXorXvZcTkaix6Yvo6HppcZGetbYMGWSFlBw8HfCJo="
  crossorigin="anonymous"></script>
--->
<script rel="preconnect"
  src="#application.jQueryCDNPath#"
  crossorigin="anonymous"></script>
</cfif>
<cfsilent>
<!--- The Kendo css locations are set in the includes/templates/pageSettings.cfm template and use the Kendo folder path when using Kendo commercial. Otherwise they point to the embedded Kendo Core package. --->
</cfsilent>	
<!-- Kendo scripts. Do not defer these! -->
<script type="text/javascript" src="#kendoSourceLocation#js/<cfif kendoCommercial>kendo.all.min<cfelse>#kendoJsFile#</cfif>.js"></script>
<!-- Note: the Kendo stylesheets are critical to the look of the site and I am not deferring them. -->
<script type="text/javascript">
<cfif isDefined("thisKendoSourceLocation") and len(thisKendoSourceLocation)><!--- Allow the blog user to switch over to Kendo commercial using XML directives in the post header --->
	<!--- Kendo common css. Note: Material black and office 365 themes require a different stylesheet. These are specified in the theme settings. --->
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#thisKendoSourceLocation#styles/kendo.common.min.css') );
	<!--- Less based theme css files. --->
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#thisKendoSourceLocation#styles/kendo.default.min.css') );
	<cfif loadKendoMobileCss>
	<!--- Mobile less based theme file. --->
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#thisKendoSourceLocation#styles/kendo.default.mobile.min.css') );
	</cfif>
<cfelse>
	<!--- Kendo common css. Note: Material black and office 365 themes require a different stylesheet. These are specified in the theme settings. --->
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#trim(kendoCommonCssFileLocation)#') );
	<!--- Less based theme css files. --->
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#trim(kendoThemeCssFileLocation)#') );
	<cfif loadKendoMobileCss>
	<!--- Mobile less based theme file. --->
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#trim(kendoThemeMobileCssFileLocation)#') );
	</cfif>
</cfif>
</script>
<!-- Other  libraries  -->
<!-- Kendo extended API (used for confirm and other dialogs) -->
<script type="#scriptTypeString#" src="#application.kendoUiExtendedLocation#/js/kendo.web.ext.js"></script>
<cfsilent>
	<!--- Determine the prism theme. --->
	<cfif darkTheme>
		<cfset prismTheme = "prismOkaidia">
	<cfelse>
		<cfset prismTheme = "prismCoy">
	</cfif>
</cfsilent>
<!-- Defer the extended stylesheet. Note: the blueopal and material black themes are not in the extended lib. -->
<script type="#scriptTypeString#">
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.kendoUiExtendedLocation#/styles/#lCase(kendoTheme)#.kendo.ext.css') );
</script>
<!-- Note: Prism (our code highlighter) is not loaded here. It is only downloaded when a page has code to highlight, see galaxieLoader below and tailEndScripts.cfm. -->
<cfif pageId eq 2 and application.Udf.isLoggedIn()>
<!--- Load scripts used for the admin page. We don't want the extra resources to be downloaded unless the is already logged in the admin site --->
<!-- TinyMce must also be placed in the head in order for the set and get content methods to work. Read the notes in the /includes/templates/js/tinymce.cfm template for more information. -->
<script src="#application.baseUrl#/common/libs/tinymce/tinymce.min.js"></script>
<script src="#application.baseUrl#/common/libs/tinymce/jquery.tinymce.min.js"></script>
<!-- Uppy Css (only used when logged on) -->
<cfinclude template="#application.baseUrl#/common/libs/uppy/uppyCss.cfm">
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/uppy/uppy.min.js"></script>
<!-- Load codemirror (only used when logged on) -->
<link rel="stylesheet" href="#application.baseUrl#/common/libs/codemirror5/lib/codemirror.css">
<link rel="stylesheet" href="#application.baseUrl#/common/libs/codemirror5/addon/hint/show-hint.css">
<script src="#application.baseUrl#/common/libs/codemirror5/lib/codemirror.js"></script>
<!-- Include the auto refresh script- otherwise the content will not load unless you click on the editors div -->
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/addon/display/autorefresh.js"></script>
<!-- Codemirror Addons -->
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/addon/edit/matchtags.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/addon/edit/closebrackets.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/addon/fold/xml-fold.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/addon/hint/html-hint.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/addon/hint/show-hint.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/addon/hint/xml-hint.js"></script>
<!-- Codemirror Modes -->
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/mode/css/css.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/mode/javascript/javascript.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/mode/htmlmixed/htmlmixed.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/mode/markdown/markdown.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/mode/sql/sql.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/codemirror5/mode/xml/xml.js"></script>
</cfif>
<!-- Optional libs -->
<!-- FontAwesome 6.1 -->
<script type="#scriptTypeString#">
	$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', 'https://use.fontawesome.com/releases/v6.1.0/css/all.css') );
</script>
<!-- Fancy box (version 2), Plyr (our HTML5 media player) and Prism (our code highlighter) are not needed on most pages, so they are not downloaded with every page. The first time that a page needs one of them, galaxieLoader downloads it and then runs the callback. Calling it again does not download it again. Used in blogJsContent.cfm, tailEndScripts.cfm and Renderer.cfc. -->
<script>
var galaxieLoader = (function() {
	var libraries = {};
	<!--- Runs the callback when the library is ready, and only loads the library the first time that it is asked for. --->
	function whenReady(name, load, callback) {
		var library = libraries[name];
		if (!library) {
			library = libraries[name] = { ready: false, started: false, callbacks: [] };
		}
		if (library.ready) {
			if (callback) { callback(); }
			return;
		}
		if (callback) { library.callbacks.push(callback); }
		if (library.started) { return; }
		library.started = true;
		load(function() {
			library.ready = true;
			var callbacks = library.callbacks;
			library.callbacks = [];
			for (var i = 0; i < callbacks.length; i++) { callbacks[i](); }
		});
	}
	function addCss(href) {
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', href) );
	}
	function getScript(url) {
		return $.ajax({ url: url, dataType: 'script', cache: true });
	}
	return {
		fancyBox: function(callback) {
			whenReady('fancyBox', function(ready) {
				addCss('#application.baseUrl#/common/libs/fancyBox/v2/source/jquery.fancybox.css');
				getScript('#application.baseUrl#/common/libs/fancyBox/v2/source/jquery.fancybox.js').done(ready);
			}, callback);
		},
		plyr: function(callback) {
			whenReady('plyr', function(ready) {
				addCss('#application.baseUrl#/common/libs/plyr/themeCss/#kendoTheme#.css');
				getScript('#application.baseUrl#/common/libs/plyr/plyr.min.js').done(ready);
			}, callback);
		},
		prism: function(callback) {
			whenReady('prism', function(ready) {
				addCss('#application.baseUrl#/common/libs/prism/prism.min.css');
				addCss('#application.baseUrl#/common/libs/prism/themes/#prismTheme#.css');
				<!--- Prism highlights the page as soon as it loads, which would be before the line numbers plugin is there. Highlight it ourselves when both are loaded. --->
				window.Prism = window.Prism || {};
				window.Prism.manual = true;
				getScript('#application.baseUrl#/common/libs/prism/prism.min.js').done(function() {
					getScript('#application.baseUrl#/common/libs/prism/plugins/prism-line-numbers.min.js').done(function() {
						Prism.highlightAll();
						ready();
					});
				});
			}, callback);
		}
	};
})();
</script>
<cfif addSocialMediaUnderEntry><!-- Add this is depracated as of May 2023 --></cfif>
<cfif arrayLen(getPost) and getPost[1]['LoadScrollMagic'] and application.includeGsap>
<!-- Scroll magic and other green sock plugins. -->
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/greenSock/src/minified/TweenMax.min.js"></script>
<!--- Note: using the minified version of scrollmagic causes issues- the text is not displayed --->
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/scrollMagic/scrollmagic/minified/ScrollMagic.min.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/scrollMagic/scrollmagic/minified/plugins/animation.gsap.min.js"></script>
<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/greenSock/src/minified/plugins/ScrollToPlugin.min.js"></script>
<!---<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/scrollMagic/scrollmagic/uncompressed/plugins/debug.addIndicators.js"></script>--->
</cfif></cfoutput>
				
<script>
<!--- Passive event listener. This should remove many of the touchstart errors that Chrome reports: 'Added non-passive event listener to a scroll-blocking <some> event. Consider marking event handler as 'passive' to make the page more responsive.' --->
(function () {
    if (typeof EventTarget !== "undefined") {
        let func = EventTarget.prototype.addEventListener;
        EventTarget.prototype.addEventListener = function (type, fn, capture) {
            this.func = func;
            if(typeof capture !== "boolean"){
                capture = capture || {};
                capture.passive = false;
            }
            this.func(type, fn, capture);
        };
    };
}());
</script>
<!--- Some optional libraries are included at the tail end of the page. --->
<!---
<cfset thisDirectory = application.baseUrl & '/cache/header'>
<cfdirectory action="list" directory="#expandPath(thisDirectory)#" name="cacheFiles"/>
<cfdump var="#cacheFiles#">
<cfoutput> #application.baseUrl#/cache/header #expandPath(thisDirectory)#</cfoutput>
<cfset application.blog.flushGalaxieCacheFiles(directory="#application.baseUrl#/cache/header", fileFilter="topMenuThemeId=28")>
<cfset application.blog.flushGalaxieCache(type='theme', themeId='28')>
--->