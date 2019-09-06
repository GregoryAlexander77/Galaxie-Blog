<!doctype html><!---Note: for html5, this doctype needs to be the first line on the page. (ga 10/27/2018)--->
<cfsilent>
<!---
	Name         : share.cfm
	Author       : Gregory Alexander
	Created      : December 27 2018
	History      : Using a new version of the add this libary. I am replicating the layout that is used in blogger (link: https://www.addthis.com/academy/adding-tools-to-blogger/). I suspect that is may be easier   	   	    	: the long run to create custom share buttons, but have noticed that no one has provided an open source tool for custom media sharing and I don't want to step on any toes here.
--->
	
<!--- 
Notes: we will pass the id and get the entry the by byEntry'. The object return is a query object stuffed into a structure.

AddThis toobox notes: don't use the javascript code that is provided on the addthis.com to pass meta data to Facebook- it does not work. Instead, I tried to use open graph meta tags.
If you are coding your own blog- or trying to use addThis for your own website, the documentation provides the following javascript code:
var addthis_share = {
	   url: "The URL",
	   title: "Blog title",
	   description: "Blog post content"
	}
For Facebook; this does not work! The addThis.com website has pretty bad documentation here.
Instead, for Facebook; we have to use open graph meta tags like so (I have no clue why the URL needs to be URLEncoded, probably as it is a non-standard link, but it works, well sort of):
<meta property="og:url" content="#URLEncodedFormat(application.blog.makeLink(id))#" />
<meta property="og:title" content="#entry.title#" />
<meta property="og:description" content="#entry.body#" />
<meta property="og:image" content="http://www.example.com/logo.gif" />

In order to accomplish this for testing purposes, I had to create an iframe in this kendo window, and used all of the html properties I would use in the index.cfm page, such as the head, body, and other html tags as I would in any normal html page. 

I also need to determine if the blog post has an image associated with it. If the entry query object contains an image, I will use Raymond's logic found in his handy renderEntry function. If there is an image associated with the post, I will pass the image patch value into the og:image meta tag, otherwise, I will pass in the path of the blog icon.

The default image size that you pass should be 1200x1200 pixels for facebook. Anything smaller than  400x400 will cause the image to be improperly cropped and put into a container to the left of the post content which is provided by the description open graph meta tag. See https://www.h3xed.com/web-and-internet/how-to-use-og-image-meta-tag-facebook-reddit for more information.

However, this approach did not work as well. The specified URL was not being captured, and instead of a proper link to the home page being made, the user was redirected to this very page, but not the blogs index page. Also, the image was not being displayed properly. I could get the logo to be displayed at facebook, but not the actual image that was assinged to the post. Also, the logo image was just huge and it bled off of the facebook page. Sigh, time to dig in a bit more. 

CHECK FACEBOOK DEBUGGER https://www.sangfroidwebdesign.com/web-design/facebook-share-image-is-wrong/

After further research, I stumbled upon addThis oexchange endpoints and the addThis core API. An 'endpoint' is a link that is sent to addThis for further processing without having to embed the addThis code at the bottom of the page. If using the core API does not work; I'll give this a shot as well and settle on whatever works. I am afraid that I am going to have to settle for a compromise solution as nothing has worked the way that I had wanted in the first place.

Next up- I will try the addThis core API. Here is the link to the core API: https://www.addthis.com/academy/addthis-core-share-follow-api/. I would not be suprised if this link is no longer working by the time that you read this. However, I will try to comment this approach, even if it does not work. 

Some reference links:
<a href="http://api.addthis.com/oexchange/0.8/forward/facebook/offer?swfurl=http://www.example.com/test.swf&url=http://www.example.com&title=My Custom Title&description=My Custom description that will go here&height=1&width=1&screenshot=http://t0.gstatic.com/images?q=tbn:1Xot2cGj_zPGMM" target="_blank">Facebook</a>
https://our.umbraco.com/forum/templating/templates-and-document-types/22079-Define-content-to-share-with-AddThis 

I am not impressed at all with the addThis documentation. I have also noticed that many links that I found on the web pointed to the home page of the addThis academy and had no content at all. AddThis must do a much better job in the future to annotate their api and share services. 

The open graph meta tag solution was posted at https://stackoverflow.com/questions/7127578/addthis-changing-description-title-and-url-being-sent
--->
	
<!---Include our common function to get the logo by the theme--->
<!--- Include the displayAndThemes template. This contains display and theme related functions. --->
<cfinclude template="#application.baseUrl#/common/function/displayAndTheme.cfm">
<!--- Include the UDF (this is not automatically included when using an application.cfc) --->
<cfinclude template="includes/udf.cfm">
	
<!--- Get the entry by the id --->
<cfset params.byEntry = url.Id>
<cfset entryStruct = application.blog.getEntries(params)>
<cfset entry = entryStruct.entries>
<cfset entryid = id>
	
<!--- Get the file path of the current directory--->
<cfset currentDir = getDirectoryFromPath(getCurrentTemplatePath())>

<!--- 
Pass in the proper server name.
More social media facebook madness.... sigh. The image is screwy if you don't append 'www.' to the URL. There will be two images, one that is correct (with 'www.'), and the very same image will be skewed if  you don't add 'www.'. I suspect that when facebook inspects the page, if the url does not exactly match the URL sent into the open graph meta tag, facebook is ignoring the values in the meta tags and instead tries to do some additional site scraping and makes adjustments to the logo image. So... I can't use the application.rootUrl application variable as it may not exactly match what the user has typed into the screen (or clicked on a bookmark or link) to load the blog page. I need to instead send the cgi.server name and append this to the default social meaid share image in teh application.cfm template.

Take 1000 on social media sharing. I am wrong again! Suprise! Facebook does not care if the URL value in the open graph meta tag matches the actual URL from the site that is being used to submit the page- instead, facebook requires the 'www.' prefix! Ok, take 1001.
--->
	
<!--- The Themes component interacts with the Blog themes. --->
<cfobject component="#application.themesComponentPath#" name="ThemesObj">
<!--- Get the Kendo theme. --->
<cfset kendoTheme = trim(getKendoTheme())>
<!--- Get the themeId. We have a lot of theme variables stuck in an application array, and we need to get the indexes so that we can get the information in the array quickly. --->
<cfset themeId = ThemesObj.getThemeIdByTheme(kendoTheme)>
<!--- Is this a dark theme (such as Orion)? --->
<cfset darkTheme = application.themeSettingsArray[themeId][3]>
<!--- Kendo file locations. --->
<!--- Todo: this is missing in the array. --->
<cfset kendoCommonCssFileLocation = trim(getSettingsByTheme(kendoTheme).kendoCommonCssFileLocation)>
<cfset kendoThemeCssFileLocation = application.themeSettingsArray[themeId][26]>
<cfset kendoThemeMobileCssFileLocation = application.themeSettingsArray[themeId][27]>
	
<!--- Is 'www.' in the CGI Server_Name var? Facebook wants this.--->
<cfif CGI.Server_Name contains 'www.'>
	<cfset serverNamePrefix = "http://" & cgi.server_name>
<cfelse>
	<cfset serverNamePrefix = "http://www." & cgi.server_name>
</cfif>
	
<!--- Determine if there is an associated image with the post --->
<cfif entry.enclosure contains '.jpg' or entry.enclosure contains '.gif' or entry.enclosure contains '.png' or entry.enclosure contains '.mp3'>
	<!--- This is identical logic found in the renderEntry method in blog.cfc --->
	<cfset imgURL = serverNamePrefix & application.baseURL & "/enclosures/" & getFileFromPath(entry.enclosure)>
<cfelse>
	<!--- Use the default image for sharing. --->
	<cfset imgURL = serverNamePrefix & application.baseURL & application.defaultLogoImageForSocialMediaShare>
	<!--- Pass in the blog's logo. 
	<cfset imgURL = application.themeSettingsArray[themeId][19]>
	--->
</cfif>
	
<!--- //**************************************************************************************************************************************************
			Load coldfish. This is not dependent upon a theme setting right now (but it may be if I can get around to using prism).
//****************************************************************************************************************************************************--->

<!--- Determine if we need the file for light or a dark theme.--->
<cfif darkTheme>
	<cfset coldFishXmlFileName = 'coldfishconfig-dark.xml'>
<cfelse>
	<cfset coldFishXmlFileName = 'coldfishconfig-light.xml'>
</cfif>
		
<!--- Include xml sheet for the theme. Every Kendo theme must have its own xml file. I added this as the default xml properties look terrible on the dark themes. --->
<cfset coldfish = createObject("component", "org.delmore.coldfish").init(currentDir & '\org\delmore\' & coldFishXmlFileName)>
<!--- inject it --->
<cfset application.blog.setCodeRenderer(coldfish)>
	
<!--- //**************************************************************************************************************************************************
			Create the content for the description meta tags.
//****************************************************************************************************************************************************--->

<!--- The original include to the layout.cfm template was done here. This include contained logic for the header, the includes, stylesheets, and pods, and then the layout.cfm logic ended. Older logic for the actual posts were resumed after the layout.cfm template include.
I have redesigned the page from here to include the entire logic for the presentation, including the logic found on the old layout.cfm template. I will be resuing Raymond's server side and ColdFusion functions, but the page has been vastly redesigned. --->

<!--- Build the title.--->
<cfif isDefined("attributes.title")>
	<cfset additionalTitle = ": " & attributes.title>
<cfelse>	
	<cfset additionalTitle = "">
	<cftry>
		<cfset additionalTitle = ": #entry.title#">
		<cfcatch></cfcatch>
	</cftry>
</cfif>

<!--- Set the meta tags. --->
<cfset descriptionMetaTagValue = application.blog.getProperty("blogDescription") & additionalTitle>
<cfset titleMetaTagValue = htmlEditFormat(application.blog.getProperty("blogTitle"))>

<!--- //**************************************************************************************************************************************************
			Page output
//****************************************************************************************************************************************************--->					
</cfsilent>
<cfoutput>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
<head>
	<!--- Important note: we must use the encodeForHTML function, otherwise, any content in the code blocks will escape the meta tags. --->
	<title>#htmlEditFormat(application.blog.getProperty("blogTitle"))#</title>
	<meta name="title" content="#encodeForHTML(entry.title)#" />
	<meta name="description" content="#descriptionMetaTagValue#" />
	<meta name="keywords" content="#encodeForHTML(application.blog.getProperty("blogKeywords"))#" />
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1"><!---<meta name="viewport" content="968"><meta name="viewport" content="1280">--->
	<!-- Twitter meta tags. -->
	<meta name="twitter:card" content="summary_large_image">
	<meta name="twitter:site" content="@gregoryalexander.com">
	<meta name="twitter:title" content="#descriptionMetaTagValue#">
	<meta name="twitter:description" content="#descriptionMetaTagValue#">
	<meta name="twitter:image" content="#imgURL#">
	<!-- Open graph meta tags for Facebook. See notes. -->
	<meta property="og:image" content="#imgURL#">
	<meta property="og:site_name" content="#htmlEditFormat(application.blog.getProperty("blogTitle"))#" />
	<!--- As of 7/19/19, 1200 x 630 creates a full size image on facebook. However, we want to keep the width and height in the meta tags aat 1200x1200 in order to keep the facebook image at full screen. --->
	<meta property="og:image:width" content="1200" />
	<meta property="og:image:height" content="1200" />
	<meta property="og:title" content="#descriptionMetaTagValue#" />
	<meta property="og:description" content="#descriptionMetaTagValue#" />
	<meta property="og:type" content="blog" />
<cfif entry.enclosure contains ".mp3" or entry.enclosure contains ".mp4" or entry.enclosure contains ".ogv" or entry.enclosure contains ".webm">
	<meta property="og:video:type" content="<cfif entry.enclosure contains ".mp3">application/x-shockwave-flash<cfelse>video/mp4</cfif>" />
	<meta property="og:video" content="#application.baseUrl#/enclosures/#getFileFromPath(entry.enclosure)#" />
	<meta property="og:video:type" content="application/x-shockwave-flash" />
</cfif>
	<!-- I am not sure why- but using the URL meta tag eliminates the image and the description. Don't use it here. -->
	<!---Rss--->
 	<link rel="alternate" type="application/rss+xml" title="RSS" href="#application.rooturl#/rss.cfm?mode=full" />
 	<!--- Kendo scripts (GA 10/25/2018)--->
    <script src="#application.kendoSourceLocation#/js/jquery.min.js"></script>
	<script src="#application.kendoSourceLocation#/js/<cfif application.kendoCommercial>kendo.all.min<cfelse>kendo.ui.core.min</cfif>.js"></script>
	<!--- Kendo common css. Note: Material black and office 365 themes require a different stylesheet. These are specified in the theme settings. --->
	<link href="#kendoCommonCssFileLocation#" rel="stylesheet">
	<!--- Less based theme css files. --->
	<link href="#kendoThemeCssFileLocation#" rel="stylesheet">
	<!-- Mobile less based theme file. -->
	<link rel="stylesheet" href="#kendoThemeMobileCssFileLocation#" />
	<!--- Other  libraries  --->
	<!--- Kendo extended API (used for confirm and other dialogs) --->
	<script src="#application.kendoUiExtendedLocation#/js/kendo.web.ext.js"></script>
	<link href="#application.kendoUiExtendedLocation#/styles/#kendoTheme#.kendo.ext.css" rel="stylesheet">
	<!--- Notification .css  --->
	<link type="text/css" rel="stylesheet" href="#application.jQueryNotifyLocation#/ui.notify.css">
	<link type="text/css" rel="stylesheet" href="#application.jQueryNotifyLocation#/notify.css">
	<!--- Optional libs --->
	<!--- Fontawesome --->
	<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.5.0/css/all.css" integrity="sha384-B4dIYHKNBt8Bc12p+WXckhzcICo0wtJAoU8YZTY5qE0Id1GSseTk6S+L3BlXeVIU" crossorigin="anonymous">
	<!--- Fancy box (version 2). --->
	<script type="text/javascript" src="#application.baseUrl#/common/libs/fancyBox/v2/source/jquery.fancybox.js"></script>
	<link rel="stylesheet" type="text/css" href="#application.baseUrl#/common/libs/fancyBox/v2/source/jquery.fancybox.css" media="screen">
</head>
</cfoutput>	
<!--- Optional libraries --->
<!--- GSAP and scrollMagie allows for animations and parallax effects in the blog entries. Don't include by default. --->
<cfset includeGsap = true>
<style>
	
	html, body {
		font-family: Arial, Helvetica, sans-serif;
		/* Set the global font size. Mobile should be two sizes smaller to maximize screen real estate. */
		font-size: <cfoutput><cfif session.isMobile>#round(application.blogFontSize-4)#<cfelse>#application.blogFontSize#</cfif></cfoutput>pt;
	}
	
	/* The next three classes will be used to create a calendar date placard */
	#blogPost p.postDate {
	  width: 38px;
	  height: 38px;
	  display: block;
	  margin: 0;
	  padding: 0px;
	  position: relative;
	  text-align: center;
	  float: left;
	  line-height: 100%;
	  /* background: #fff url(<cfoutput>#application.blogCfcUrl#</cfoutput>/images/date-bg.png) no-repeat left bottom; */
	  border: 1px solid #fff;
	}

	#blogPost p.postDate span.month {
	  /* Set the font size to 14px */
	  font-size: 12px;
	  /* Note: the additional 'k-primary' kendo class attached to the span will set the background */
	  border-bottom: 1px solid #fff;
	  /* The width is set at 85% for the dark themes. If set to 100%, the white line that surrounds the date will disappear on the right side of the date. */
	  width: 85%;
	  position: absolute;
	  top: 0;
	  left: 0;
	  text-transform: uppercase;
	  padding: 2px;
	}

	#blogPost p.postDate span.day {
	  /* Set the font size to 14px */
	  font-size: 14px;
	  /* Note: the additional 'k-alt' kendo class attached to the span will set the background. The calendar image is rather dificult to control. I would not adjust these settings much. It took me a long time to get it right. */
	  display: table-cell;
	  vertical-align: middle;
	  bottom: 1px;
	  top: 10px;
	  left: 0;
	  top: 15px;
	  height: 30%;
	  /* The width is set at 85% for the dark themes. If set to 100%, the white line that surrounds the date will disappear on the right side of the date. */
	  width: 85%;
	  padding: 2px;
	  position: absolute;
	}

	#blogPost p.postAuthor span.info {
	  /* margin-top: 10px; */
	  display: block;
	}

	#blogPost p.postAuthor {
	  /*background: transparent url(images/post-info.png) no-repeat left top;*/
	  margin: 0 0 0 43px;
	  padding: 0 12px;
	  font-size: 110%;
	  font-style: italic;
	  /* border: 1px solid #f2efe5; */
	  min-height: 38px;
	  color: #75695e;
	  height: auto !important;
	  height: 38px;
	  line-height: 100%;
	}

	#postContent {
		/* Apply padding to post content. */
		margin-top:5px; 
		display:block;
	}
	
	/* Constraining images to a max width so that they don't push the content containers out to the right */
	.entryImage img {
		max-width: 100%;
		/* Subtle drop shadow on the image layer */
		box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
	}
	
	/* mainBlog title bar */
	.widget h3.topContent {
		padding-top: 0px;
		padding-right: 0px;
		padding-bottom: 10px;
		padding-left: 0px;
		border-bottom: 1px solid #e2e2e2;
		text-align: left;
	}

	/* mainBlog bottom bar */
	.widget p.bottomContent {
		padding-top: 10px;
		padding-right: 0px;
		padding-bottom: 0px;
		padding-left: 0px;
		border-top: 1px solid #e2e2e2;
	}
	
	<cfoutput>
	/* Special fonts */
	@font-face {
		font-family: "Eras Light";
		src: url(#application.baseUrl#/common/fonts/erasLight.woff) format("woff");
	}
	@font-face {
		font-family: "Eras Book";
		src: url(#application.baseUrl#/common/fonts/erasBook.woff) format("woff");
	}
	@font-face {
		font-family: "Eras Bold";
		src: url(#application.baseUrl#/common/fonts/erasBold.woff) format("woff");
	}			
	@font-face {
		font-family: "Eras Demi";
		src: url(#application.baseUrl#/common/fonts/erasDemi.woff) format("woff");
	}
	@font-face {
		font-family: "Eras Med";
		src: url(#application.baseUrl#/common/fonts/erasMed.woff) format("woff");
	}
	@font-face {
		font-family: "Kaufmann Script Bold";
		src: url(#application.baseUrl#/common/fonts/kaufmannScriptBold.woff) format("woff");
	}
	</cfoutput>
	
</style>
		
<body>
<cfoutput>

<!--- Listener script to redirect the user if they are coming from linkedIn. Linked in does not send a http_referer string, so I have no way of determining if the addThis.cfm window is being called from linked in. We need to capture the URL hash and redirect if the hash contains 'linkedin'.--->
<script>
	// Set global vars. This is determined by the server (for now).
	isMobile = <cfoutput>#session.isMobile#</cfoutput>;
	
	var blogLink = "<cfoutput>#application.blog.makeLink(id)#</cfoutput>";
	// Get the URL fragment in the url. The fragment is the id of the comment.
	var urlFragment = window.location.hash;
	// If linked in is found in the URL fragment...
	if (urlFragment.search('linkedin') > 0){
		window.location.replace(blogLink);
	}
</script>
	
<!-- This is needed to specify the image for Pinterest. -->
<div class="addthis_sharing_toolbox" 
	data-url="#application.blog.makeLink(id)#" 
	data-title="#entry.title#" 
	data-media="#imgURL#">
</div>
</cfoutput>	
<cfsilent>	
<!---
<cfdump var="#cgi#">
#CGI.Query_String#
--->

<!--- Uncomment to get the proper link if you want to view the this particular page for debugging. Use: http://gregoryalexander.com/blogCfc/client/addThis.cfm?id=#id# to extract the proper link. --->
</cfsilent>

<cfoutput>
<div id="mainBlog" class="k-alt">
	<div id="blogContent">
		<div id="blogPost" class="widget k-content">
			<span id="blogContentContainer">
				<h3 class="topContent">
					<a href="#application.blog.makeLink(id)#" class="k-content">#entry.title#</a>
				</h3>

				<p class="postDate">
					<!-- We are using Kendo's 'k-primary' class to render the primary accent color background. The primay color is set by the theme that is declared. -->
					<span class="month k-primary">#dateFormat(entry.posted, "mmm")#</span>
					<span class="day k-alt">#day(entry.posted)#</span>
				</p>

				<p class="postAuthor">
					<span class="info">
						<cfif len(entry.name)>by <a href="#application.blog.makeUserLink(entry.name)#" class="k-content">#entry.name#</a></cfif> 
					</span>
				</p>
				
				<!-- Post content --> 
				<span id="postContent">
				<!--- Only constrain the blog body on mobile. --->
				<cfif session.isMobile>
					<!--- Note: Delmore's code formatter is not mobile friendly and it does not use responsive design. This table will onstrain the content to a certain variable size. --->
					<table id="constrainerTable" class="constrainContent">
						<tr>
							<td>
								<!--- Blog post. --->
								#application.blog.renderEntry(entry.body,false,entry.enclosure)#
							</td>
						</tr>
					</table>
				<cfelse><!---<cfif session.isMobile>--->
					<!--- Blog post. --->
					#application.blog.renderEntry(entry.body,false,entry.enclosure)#
				</cfif><!---<cfif session.isMobile>--->
				</span><!--<span id="postContent">-->

				<!---***************************************************************** Media *****************************************************************--->
				<!--- HTML5 supported media will be handled by the jQjuery Kendo video player. Supported formats are mp4, ogv, and webm--->
				<cfif entry.enclosure contains ".mp4" or entry.enclosure contains ".ogv" or entry.enclosure contains ".webm">
					<div class="k-content mediaPlayer">
						<div id="mediaplayer" class="k-content"></div>
						<script>
							$(document).ready(function () {
								$("#chr(35)#mediaplayer").kendoMediaPlayer({
									autoPlay: false,
									navigatable: true,
									media: {
										title: "#entry.title#",
										source: "#application.baseUrl#/enclosures/#getFileFromPath(entry.enclosure)#"
									}
								});
							});
							
						</script>
					</div>
				</cfif>
				<cfif entry.enclosure contains "mp3">
					<cfset alternative=replace(getFileFromPath(entry.enclosure),".mp3","") />
					<div class="audioPlayerParent">
						<div id="#alternative#" class="audioPlayer">
						</div>
					</div>
					<script type="text/javascript">
						// <![CDATA[
							var flashvars = {};
							// unique ID
							flashvars.playerID = "#alternative#";
							// load the file
							flashvars.soundFile= "#application.rooturl#/enclosures/#getFileFromPath(entry.enclosure)#";
							// Load width and Height again to fix IE bug
							flashvars.width = "470";
							flashvars.height = "24";
							// Add custom variables
							var params = {};
							params.allowScriptAccess = "sameDomain";
							params.quality = "high";
							params.allowfullscreen = "true";
							params.wmode = "transparent";
							var attributes = false;
							swfobject.embedSWF("#application.rooturl#/includes/audio-player/player.swf", "#alternative#", "470", "24", "8.0.0","/includes/audio-player/expressinstall.swf", flashvars, params, attributes);
						// ]]>
					</script>
				</cfif><!---<cfif enclosure contains "mp3">--->
				</cfoutput>

				<p class="bottomContent">
					<!-- Go to www.addthis.com/dashboard to customize your tools --> 
					<div class="addthis_inline_share_toolbox"></div>
				</p>
			</span><!---<span id="blogContentContainer">--->
		</div><!---<div id="blogPost">--->
	</div><!---<div id="blogContent">--->
<cfsilent>
<!---//**************************************************************************************************************************************************
			Add this and GSAP
//***************************************************************************************************************************************************--->
</cfsilent>
	<!---<cftry>--->
		<!-- Go to www.addthis.com/dashboard to customize your tools --> 
		<script type="text/javascript" src="//s7.addthis.com/js/300/addthis_widget.js#pubid=<cfoutput>#application.addThisApiKey#</cfoutput>"></script>
		<div class="addthis_inline_share_toolbox_zyuh"></div>
		<!---<cfcatch type="any">
			The addThis.com server may be down.
		</cfcatch>
	</cftry>--->
	<cfif includeGsap>
	<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/greenSock/src/uncompressed/TweenMax.js"></script>
	<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/scrollMagic/scrollmagic/uncompressed/ScrollMagic.js"></script>
	<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/scrollMagic/scrollmagic/uncompressed/plugins/animation.gsap.js"></script>
	<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/greenSock/src/uncompressed/plugins/ScrollToPlugin.js"></script>
	<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/scrollMagic/scrollmagic/uncompressed/plugins/debug.addIndicators.js"></script>
	</cfif>
</body>
</html>


