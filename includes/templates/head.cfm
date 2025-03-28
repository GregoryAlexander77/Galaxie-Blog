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
<cfif pageId eq 1>
<cfheader name="Expires" value="#getHttpTimeString(dateAdd('yyyy', 1, Now()))#">
<cfheader name="cache-control" value="Cache-Control: max-age=31536000, public">
</cfif>

<!--- Enforce ssl if necessary. --->
<cfif useSsl and (CGI.https eq "off")>
	<cfheader statuscode="308" statustext="Moved permanently">
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
<meta name="title" content="#titleMetaTagValue#" />
<meta name="keywords" content="#application.BlogDbObj.getBlogMetaKeywords()#" />
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
		/* Script to defer script resources. See https://appseeds.net/defer.js/demo.html. 
		// @shinsenter/defer.js */
		!function(e,o,t,n,i,r){function c(e,t){r?n(e,t||32):i.push(e,t)}function f(e,t,n,i){return t&&o.getElementById(t)||(i=o.createElement(e||'SCRIPT'),t&&(i.id=t),n&&(i.onload=n),o.head.appendChild(i)),i||{}}r=/p/.test(o.readyState),e.addEventListener('on'+t in e?t:'load',function(){for(r=t;i[0];)c(i.shift(),i.shift())}),c._=f,e.defer=c,e.deferscript=function(t,n,e,i){c(function(e){f(0,n,i).src=t},e)}}(this,document,'pageshow',setTimeout,[]),function(u,n){var a='IntersectionObserver',d='src',l='lazied',h='data-',p=h+l,y='load',m='forEach',r='appendChild',b='getAttribute',c=n.head,g=Function(),v=u.defer||g,f=v._||g;function I(e,t){return[].slice.call((t||n).querySelectorAll(e))}function e(s){return function(e,t,o,r,c,f){v(function(n,t){function i(n){!1!==(r||g).call(n,n)&&(I('SOURCE',n)[m](i),(f||['srcset',d,'style'])[m](function(e,t){(t=n[b](h+e))&&(n[e]=t)}),y in n&&n[y]()),n.className+=' '+(o||l)}t=a in u?(n=new u[a](function(e){e[m](function(e,t){e.isIntersecting&&(t=e.target)&&(n.unobserve(t),i(t))})},c)).observe.bind(n):i,I(e||s+'['+h+d+']:not(['+p+'])')[m](function(e){e[b](p)||(e.setAttribute(p,s),t(e))})},t)}}function t(){v(function(t,n,i,o){t=[].concat(I((i='script[type=deferjs]')+':not('+(o='[async]')+')'),I(i+o)),function e(){if(0!=t){for(o in n=f(),(i=t.shift()).parentNode.removeChild(i),i.removeAttribute('type'),i)'string'==typeof i[o]&&n[o]!=i[o]&&(n[o]=i[o]);n[d]&&!n.hasAttribute('async')?(n.onload=n.onerror=e,c[r](n)):(c[r](n),v(e,.1))}}()},4)}t(),u.deferstyle=function(t,n,e,i){v(function(e){(e=f('LINK',n,i)).rel='stylesheet',e.href=t},e)},u.deferimg=e('IMG'),u.deferiframe=e('IFRAME'),v.all=t}(this,document);
	</script>
	
	<script>
		// WebP support detection. Revised a script found on stack overflow: https://stackoverflow.com/questions/5573096/detecting-webp-support. It is the quickest loading script to determine webP that I have found so far.
		function webPImageSupport() {
			// Detemine if the webp mime type is on the server. This is saved as a ColdFusion application variable.
			var serverSupportsWebP = <cfoutput>#application.serverSupportsWebP#</cfoutput>;
    		var elem = document.createElement('canvas');
			
    		if (serverSupportsWebP && !!(elem.getContext && elem.getContext('2d'))) {
        		// Is able to get WebP representation?
        		return elem.toDataURL('image/webp').indexOf('data:image/webp') == 0;
    		}
    		// Canvas is not supported on older browsers such as IE.
    		return false;
		}
	</script>
 	<!--- The jQuery script can't be defered as the Kendo controls won't work. Wa're using jQuery 1.2. Later jQuery versions don't work with Kendo UI core unfortunately. --->
<cfif application.kendoCommercial>
	<!--- Use the 3.5.1 version if using commercial. --->
	<script rel="preconnect"
  		src="https://code.jquery.com/jquery-3.5.1.min.js"
  		integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0="
  		crossorigin="anonymous"></script>
<cfelse>
	<!--- 
	Use the jQuery 3.4.1 CDN for Kendo Core. 
	Either use https://code.jquery.com/jquery-3.4.1.min.js or https://ajax.googleapis.com/ajax/libs/jquery/3.1.1/jquery.min.js. The full link from jQuery is:
	<script
	  src="https://code.jquery.com/jquery-3.4.1.min.js"
	  integrity="sha256-CSXorXvZcTkaix6Yvo6HppcZGetbYMGWSFlBw8HfCJo="
	  crossorigin="anonymous"></script>
	--->
	<script rel="preconnect"
	  src="#application.jQueryCDNPath#"
	  crossorigin="anonymous"></script>
</cfif>
	<!-- Load jQuery UI via CDN (for notification script) -->
	<script type="#scriptTypeString#" src="https://ajax.googleapis.com/ajax/libs/jqueryui/1/jquery-ui.min.js" ></script>
	<!-- Load the notify script -->
	<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/jQuery/jQueryNotify/src/jquery.notify.min.js"></script>
<cfsilent>
<!--- The Kendo css locations are set in the includes/templates/pageSettings.cfm template and use the Kendo folder path when using Kendo commercial. Otherwise they point to the embedded Kendo Core package. --->
</cfsilent>	
	<!-- Kendo scripts -->
	<script type="#scriptTypeString#" src="#application.kendoSourceLocation#js/<cfif application.kendoCommercial>kendo.all.min<cfelse>kendo.ui.core.min</cfif>.js"></script>
	<!-- Note: the Kendo stylesheets are critical to the look of the site and I am not deferring them. -->
	<script type="text/javascript">
		// Kendo common css. Note: Material black and office 365 themes require a different stylesheet. These are specified in the theme settings.
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#trim(kendoCommonCssFileLocation)#') );
		// Less based theme css files.
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#trim(kendoThemeCssFileLocation)#') );
		// Mobile less based theme file.
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#trim(kendoThemeMobileCssFileLocation)#') );
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
	<!-- Defer the extended scripts along with my notification library. Note: the blueopal and material black themes are not in the extended lib. -->
	<script type="#scriptTypeString#">
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.kendoUiExtendedLocation#/styles/#lCase(kendoTheme)#.kendo.ext.css') );
		// Notification .css 
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.jQueryNotifyLocation#/ui.notify.css') );
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.jQueryNotifyLocation#/notify.css') );
		// Prism.css (must be in between the head tags)
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.baseUrl#/common/libs/prism/prism.min.css') );
		// Prism theme (must be in between the head tags)
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.baseUrl#/common/libs/prism/themes/#prismTheme#.css') );
	</script>
	<!-- Note: the prism.min.js library (our code hightlighter) should not be placed here in the header. It is in the footer prior to the end body tag. This library must be placed between the body tags. -->
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
	<!-- Fancy box (version 2). -->
	<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/fancyBox/v2/source/jquery.fancybox.js"></script>
	<!-- Defer the fancyBox css. -->
	<script type="#scriptTypeString#">
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.baseUrl#/common/libs/fancyBox/v2/source/jquery.fancybox.css') );
	</script>
	<!-- Plyr (our HTML5 media player) -->
	<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/plyr/plyr.min.js"></script>
	<!-- Defer the plyr css. -->
	<script type="#scriptTypeString#">
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.baseUrl#/common/libs/plyr/themeCss/#kendoTheme#.css') );
	</script>
	<cfif addSocialMediaUnderEntry><!-- Add this is depracated as of May 2023 --></cfif>
<cfif arrayLen(getPost) and getPost[1]['LoadScrollMagic'] and application.includeGsap>
	<!-- Scroll magic and other green sock plugins. -->
	<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/greenSock/src/uncompressed/TweenMax.js"></script>
	<!--- Note: using the minified version of scrollmagic causes issues- the text is not displayed --->
	<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/scrollMagic/scrollmagic/uncompressed/ScrollMagic.js"></script>
	<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/scrollMagic/scrollmagic/uncompressed/plugins/animation.gsap.js"></script>
	<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/greenSock/src/uncompressed/plugins/ScrollToPlugin.js"></script>
	<!---<script type="#scriptTypeString#" src="#application.baseUrl#/common/libs/scrollMagic/scrollmagic/uncompressed/plugins/debug.addIndicators.js"></script>--->
</cfif></cfoutput>
				
<script>
// Passive event listener. This should remove many of the touchstart errors that Chrome reports: 'Added non-passive event listener to a scroll-blocking <some> event. Consider marking event handler as 'passive' to make the page more responsive.'
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