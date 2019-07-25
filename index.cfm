<cfsilent><!--- Cache this stuff --->
<cfheader name="filesMatch" value="<filesMatch '.(css|jpg|jpeg|png|gif|js|ico)$'>">
<cfheader name="cache-control" value="Cache-Control: max-age=31536000, public">
</cfsilent><!doctype html><!---Note: for html5, this doctype needs to be the first line on the page. (ga 10/27/2018)---> 
<cfprocessingdirective suppressWhiteSpace="true">
<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : Index
	Author       : Gregory Alexander/Raymond Camden 
	Created      : February 10, 2003
	Last Updated : July 25 2019
				 :  -------- Original history --------
	History      : Reset history for version 5.0
				 : Link for more entries fixed (rkc 6/25/06)
				 : Gravatar support (rkc 7/8/06)
				 : Cleanup of area shown when no entries exist (rkc 7/15/06)
				 : Use of rb(), use of icons, other small mods (rkc 8/20/06)
				 ----------------------------------------------------------------
				 Gregory's architecture elboration: the 'rb()' funcion is shorthand for 'application.resourceBundle.getResource'
                 This is Raymond's shorthand notation according to the documentation. In the next version, I will likely rename this from 'rb' to simply getResource().
				 ---------------------------------------------------------------- End Gregory's elaboration
				 : Change how categories are handled (rkc 9/17/06)
				 : Big change to cut down on whitespace (rkc 11/30/06)
				 ----------------------------------------------------------------
				 Gregory removed Raymond's white space approach. I am using cfsilent instead as I don't like to wrap a cfoutput around my javascript code (too many issues with # signs and other stuff.)
                 ----------------------------------------------------------------
				 : comment mod support (rkc 12/7/06)
				 : gravatar fix, thanks Pete F (rkc 12/26/06)
				 : use app.maxentries, digg link (rkc 2/28/07)
				 : fix bug where 11 items showed up, not 10 (rkc 5/18/07)
				 : Purpose: Blog home page
				 	
				 -------- New Kendo redesign history (Gregory Alexander) --------
				 -------------- Kendo Blog Cfc (Gregory Alexander) --------------
				 Re-engineered the code to make it better compatible with as single page application and completely redesigned the page. I want to strip out all styling in order to have the default kendo .css control the page. I also had to eliminate some of the orginal features, such as 'AddThis' as it was using old jQuery libraries and was not compabitle with either the newest version of jQuery, or Kendo. 

--->
	
<!--- //**************************************************************************************************************************************************
			Global settings.
//****************************************************************************************************************************************************--->
<!--- Get the file path of the current directory--->
<cfset currentDir = getDirectoryFromPath(getCurrentTemplatePath())>
	
<!--- //**************************************************************************************************************************************************
			Load common cfc objects and set encryption and service keys.
//****************************************************************************************************************************************************--->

<!--- The proxyController is between the blog.cfc and the client. --->
<cfobject component="#application.proxyControllerComponentPath#" name="ProxyControllerObj">
<!--- The Themes component interacts with the Blog themes. --->
<cfobject component="#application.themesComponentPath#" name="ThemesObj">
<!--- Include the resource bundle. --->
<cfset getResourceBundle = application.utils.getResource>
<!--- Include the UDF (this is not automatically included when using an application.cfc) --->
<cfinclude template="includes/udf.cfm">
<!--- Preset URL vars --->
<cfparam name="URL.startRow" default="0">
	
<!--- Use to delete the cookies for testing.
<cfset exists= structdelete(session, 'encryptionKey', true)/>
<cfset exists= structdelete(session, 'serviceKey', true)/>
--->

<!--- See if the encryptionKey and the serviceKey have been created in the session scope. If they don't exist, create them. --->
<cfif not isDefined("session.encryptionKey") and not isDefined("session.serviceKey")>
	<!--- Create unique token keys --->
	<cfinvoke component="#ProxyControllerObj#" method="createTokenKeys" returnvariable="createTokenKeys" />
	<!--- Store the value in session cookies. --->
	<cfset session.encryptionKey = createTokenKeys.encryptionKey>
	<cfset session.serviceKey = createTokenKeys.serviceKey>
</cfif>
	
<!--- //**************************************************************************************************************************************************
			Global and common params
//****************************************************************************************************************************************************--->
		
<!--- Hardcoded image paths (TODO make this a variable that can be set on the settings page.) --->
<cfset application.defaultLogoImageForSocialMediaShare = "/images/logo/gregorysBlogSocialMediaShare2.png">
	
<!--- Include the displayAndThemes template. This contains display and theme related functions. --->
<cfinclude template="#application.baseUrl#/common/function/displayAndTheme.cfm">
	
<!--- Get the current theme --->
<cfset kendoTheme = trim(getKendoTheme())>
<!--- Get the themeId. We have a lot of theme variables stuck in an application array, and we need to get the indexes so that we can get the information in the array quickly. --->
<cfset themeId = ThemesObj.getThemeIdByTheme(kendoTheme)>
	
<!--- Is this a dark theme (such as Orion)? --->
<cfset darkTheme = application.themeSettingsArray[themeId][3]>

<!--- 
The default width of the containers that hold the blog content. I would suggest leaving this at 66% as I am checking the screen size later on and adjusting the css to this baseline value. I am using a bigger font than most of the blogCfc sites, so I am setting this at 66%, which is a bit wider than 50% which looks the best. This setting also affects the seach and searchResults windows which subtract 10% from this setting. 
Notes: 
The 66% setting looks great with a 20 inch monitor. 
80% works with 1280x768, which is a 19 inch monitor or a 14 Notebook. 
I am adjusting the contentWidth via javascript to ensure proper rendering of the page.
--->
<cfset contentWidth = application.themeSettingsArray[themeId][4]>

<!--- Optional argument. There are three resolutions for the background images: high, medium, and low. This setting affects all of the background images. I tried to get the high res photos around 2.5 mb, med res is around 1.5 mb, and low res around 1 mb. The reason for being so high is that the average size for an individual news article on the web is around 1 mb for the entire page (a lot of this is ad content). My site is a little higher than average as it is also intended to be photography blog. And, I am eventually going to make this a single page site and I can load a bit more stuff as eventually the site will only load one time for every page. --->
<cfset backgroundImageResolution = "LowRes"><!---Either 'HiRes', 'MedRes', or 'LowRes'. LowRes is default. --->
<!---
Properties of the blog content.
There are two sections that display the main blog content. The 'blogContent' div on the left holds the blog posts, interactive buttons and comments, and the side-bar on the right contains the pods, such as the calendar control and recent comments. I designed the page carefully to use 65% of the space for the blogContent, and 35% is used for the side bar, which contain the pods. You can change these settings if you wish, but be careful.
On mobile devices, the blog content width is set at 95% and the side bar is a responsive flyout panel.
--->
<cfif session.isMobile>
	<cfset mainContainerWidth = "95">
	<!--- The sidebar container width does not exist in the mobile design. Instead, it is a responsive panel.--->
	<cfset sideBarContainerWidth = "0">
<cfelse>
	<cfset mainContainerWidth = application.themeSettingsArray[themeId][5]>
	<cfset sideBarContainerWidth = application.themeSettingsArray[themeId][6]>
</cfif>
	
<!--- //**************************************************************************************************************************************************
			Granular settings by theme.
//**************************************************************************************************************************************************  --->
<!--- Trim and set the granular settings stored in a structure that are determined by the theme. The getSettingsByTheme method in the Main.cfc template provides granular ui settings by theme. --->
<!--- The site opacity will make the blog content semi-transparent so that you can see the background image. If you change this, be sure to set this between 80 and 100 as this will impact the readability of the entire site. Site opacity settings show the background image underneath. Each setting is individually set by the theme to ensure better readability. ---> 
<cfset siteOpacity = application.themeSettingsArray[themeId][7]>
<!--- What image do you want displayed as the background? --->
<cfset blogBackgroundImage = application.themeSettingsArray[themeId][8]>
<!--- Do you want the blogBackgroundImage to repeat at the end of the image? The dafualt value is false. --->
<cfset blogBackgroundImageRepeat = application.themeSettingsArray[themeId][9]>
<!--- Set the background image position. See https://www.w3schools.com/cssref/pr_background-position.asp for a full description. --->
<cfset blogBackgroundImagePosition = application.themeSettingsArray[themeId][10]>
	
<!--- What is the width of the header banner? We can either stretch it out across the entire page, or make it identical to the width of the contentWidth. I am adding this setting as some users may want to put more stuff into the header banner and stretching it out allows more room. --->
<cfset stretchHeaderAcrossPage = application.themeSettingsArray[themeId][11]>
<!--- Set the string that we will use in the UI --->
<cfif stretchHeaderAcrossPage>
	<cfset headerBannerWidth = "100%">
<cfelse>
	<cfset headerBannerWidth = contentWidth & "%">
</cfif>
	
<!--- Controls the alignment of the *entire* menu and the header. If it is aligned to the left, the menu will be aligned with the blog content container. I am allowing this to be changed as the user may want to use the same header on their own site and I want to allow them to modify the placement as the end user sees fit. The values are: left, center. --->
<cfset alignBlogMenuWithBlogContent = application.themeSettingsArray[themeId][12]>
<!--- Top menu alignment. This affects the menu placement *within* the header. The top menu contains the logo as well as the menu scripts and search button. Accepted values are left, center, and right. Unlike the alignBlogMenuWithBlogContent argument, this affects the outer container which will be aligned. --->
<cfset topMenuAlign = application.themeSettingsArray[themeId][13]><!---Either left, center, or right--->
<!--- The header background image. You can also leave this blank if you want the blogBackgroundImage to be shown instead of a colored banner on the header. If you choose to leave this blank and not display a colored banner, also leave the menuBackgroundImage blank, otherwise, a colored bar will be displayed. Note: I put a gradient on the banner image, however, the top of the image, which is darker than the bottom, can't be used for the menu as it will look off. So I am separating the background images for the banner and the menu. --->
<cfset headerBackgroundImage = application.themeSettingsArray[themeId][14]>
<!--- The background image for the top menu. This should be a consistent color and not gradiated. --->
<cfset menuBackgroundImage = application.themeSettingsArray[themeId][15]>	
<!--- This setting determines if the whole image should be shown on screen, or if the image should be captured from the left until the image is cut off at the end of the screen. Essentially, setting this to true set the image width t0 be 100%, whereas setting this to false will left justify the image and cut off any overflow. The resolution is quite high, so setting this to false will cut off the right part of most of the images. --->
<cfset coverKendoMenuWithMenuBackgroundImage = application.themeSettingsArray[themeId][16]>
<!--- Both desktop and mobile logos. The mobile logo should be smaller than the desktop obviously. --->
<cfset logoImageMobile = application.themeSettingsArray[themeId][17]>
<cfset logoMobileWidth = application.themeSettingsArray[themeId][18]>
<cfset logoImage = application.themeSettingsArray[themeId][19]>

<!--- Generic Logo Properties.--->
<!--- Padding. The most important setting here is logoPaddingRight which gives space between the logo and the blog text and menu. I have designed the logo image with padding on the right to take care of this without applying this setting. Padding left and bottom can be used to fine tune the placement of the logo but I am not using them currently in my theme designs. --->
<cfset logoPaddingTop = application.themeSettingsArray[themeId][20]>
<cfset logoPaddingRight = application.themeSettingsArray[themeId][21]>
<cfset logoPaddingLeft = application.themeSettingsArray[themeId][22]>
<cfset logoPaddingBottom = application.themeSettingsArray[themeId][23]>
<!---The blog name text color controls the behavior of all text in the menu, including the search icon.--->
<cfset blogNameTextColor = application.themeSettingsArray[themeId][24]>
	
<!--- Logo image check (there may be one common logo for all things). --->
<cfif session.isMobile>
	<cfset logoSourcePath = "#logoImageMobile#">
<cfelse>
	<cfset logoSourcePath = "#logoImage#">
</cfif>
	
<!--- The divider between the header and body --->
<cfset headerBodyDividerImage = application.themeSettingsArray[themeId][25]>
			
<!--- Kendo file locations. --->
<!--- Todo: this is missing in the array. --->
<cfset kendoCommonCssFileLocation = trim(getSettingsByTheme(kendoTheme).kendoCommonCssFileLocation)>
<cfset kendoThemeCssFileLocation = application.themeSettingsArray[themeId][26]>
<cfset kendoThemeMobileCssFileLocation = application.themeSettingsArray[themeId][27]>
<cfset breakPoint = application.themeSettingsArray[themeId][28]>
	
<!--- Optional libraries --->
<!--- GSAP and scrollMagie allows for animations and parallax effects in the blog entries. Don't include by default. --->
<cfset includeGsap = false>
	
<!--- //**************************************************************************************************************************************************
			Custom plugins and strings
//********************************************************************************************************************************************************
Notes: I am planning on incorporating a full plugin structure, however, this will entail making database changes that I am avioding in the
1st version of this blog. For the first version of this software, I want to make minimal changes to the structure, other than to code a new
Kendo interface and make it themeable, in order to keep this version accessible to the current BlogCfc base. For now, if you want to make changes
or to create a new 'plug-in', copy and paste this 'custom' setting logic into a new template and include it either using a cfinclude or a cfmodule 
template in a new folder or a template name that will not be overridden wwen a new version of this software is created ((ie #application.baseUrl#/customTemplateSetting.cfm)'. 
In the next x versions, I want to use the datatabase to store plugins and custom templates, but I am not there yet. However, I am coding this logic in order to 'set the stage' 
for this new functionality that should be available in an upcoming version. At least we can have a general framework how to include custom code and not step on each others 
toes with future updates.
--->	
<!--- Core logic below this section. Deals with the getMode and entry logic. Include the full path of the logical template (ie #application.baseUrl#/plugin/coreLogic.cfm) --->
<cfset customCoreLogicTemplate = application.themeSettingsArray[themeId][29]>
<!--- Content between the head tags can be customized with a custom template. Indicate the full path and the name of the custom template here. --->
<cfset customHeadTemplate = application.themeSettingsArray[themeId][30]>
<!--- Setting to replace the default body string. This should be a <body .... > string. --->
<cfset customBodyString = application.themeSettingsArray[themeId][31]>
<!--- Template to include fonts. --->
<cfset customFontCssTemplate = application.themeSettingsArray[themeId][32]>
<!---Global css variables and the css for the body--->
<cfset customGlobalAndBodyCssTemplate = application.themeSettingsArray[themeId][33]>
<!--- Template to include css rules for the top menu. --->
<cfset customTopMenuCssTemplate = application.themeSettingsArray[themeId][34]>
<!--- Template to include the html for the top menu. --->
<cfset customTopMenuHtmlTemplate = application.themeSettingsArray[themeId][35]>
<!--- Template to include the javascript for the top menu. Note: this template is within the code region of the customTopMenuHtmlTemplate. --->
<cfset customTopMenuJsTemplate = application.themeSettingsArray[themeId][36]>
<!--- Template to include the css rules for the blog content (blog entries). --->
<cfset customBlogContentCssTemplate = application.themeSettingsArray[themeId][37]>
<!--- Template to include Kendo's widget and UI javascripts for the main blog (not the header script) --->
<cfset customBlogJsContentTemplate = application.themeSettingsArray[themeId][38]>
<!--- Template to include blog content HTML (blog entries). This is a rather intensive bit of code that will be broken down further in a later version. --->
<cfset customBlogContentHtmlTemplate = application.themeSettingsArray[themeId][39]>
<!--- Template to include a custom footer. --->
<cfset customFooterHtmlTemplate = application.themeSettingsArray[themeId][40]>

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
			Kendo window settings
//****************************************************************************************************************************************************--->
<!--- Window settings --->
<cfif session.isMobile>
	<cfset kendoWindowIcons = '"Close"'>
<cfelse>
	<cfset kendoWindowIcons = '"Minimize", "Refresh", "Close"'>
</cfif>
	
<!--- Set default width and height for the kendo extended ui window elements (are you sure? There were errors, etc).--->
<cfif session.isMobile>
	<cfset application.kendoExtendedUiWindowWidth = "305px">
	<cfset application.kendoExtendedUiWindowHeight = "215px">
<cfelse>
	<cfset application.kendoExtendedUiWindowWidth = "625px">
	<cfset application.kendoExtendedUiWindowHeight = "215px">
</cfif>
		
<!--- UI Specific business logic--->
<!--- Note: the buttons on the material theme are bigger and we need to decrease the size. --->
<cfif kendoTheme contains 'material'>
	<cfif session.isMobile>
		<cfset kendoButtonStyle = "width:90px; font-size:0.55em;">
	<cfelse>	
		<cfset kendoButtonStyle = "width:125px; font-size:0.70em;">
	</cfif>
<cfelse><!---<cfif kendoTheme contains 'material'>--->
	<cfif session.isMobile>
		<cfset kendoButtonStyle = "width:90px; font-size:0.75em;">
	<cfelse>	
		<cfset kendoButtonStyle = "width:125px; font-size:0.875em;">
	</cfif>
</cfif><!---<cfif kendoTheme contains 'material'>--->
			
<!--- //**************************************************************************************************************************************************
			Check for theme settings issues. 
//****************************************************************************************************************************************************--->
<!--- There are often wierd problems when checking for null values right after a value has been set from a short hand structure. Putting this code right 
after the menuBackgroundImage setting causes an error. Not sure if it is a ColdFusion bug or not, but I have encountered it several times
before in other projects. I suspect that it is reading the entire object when it is set? --->

<!--- If the menuBackgroundImage is not defined, assign it to the headerBackgroundImage. Without it, there will be a ghosted bar above the menu. --->
<cfif len(trim(menuBackgroundImage)) eq 0>
	<cfset menuBackgroundImage = headerBackgroundImage>
</cfif>	
	
<!--- Don't allow the alignBlogMenuWithBlogContent to be set to true unless the stretchHeaderAcrossPage is set to true. Otherwise, the header will be scrunched up as there will be padding on both the left and the right of the centered header.--->
<cfif not stretchHeaderAcrossPage and alignBlogMenuWithBlogContent>
	<cfset alignBlogMenuWithBlogContent = false>
</cfif>

<!--- //**************************************************************************************************************************************************
			Core logic
//****************************************************************************************************************************************************--->
<cfif customCoreLogicTemplate eq "">	
	<!--- Raymond's module to inspect the URL to determine what to pass to the getEntries method. --->
	<cfmodule template="tags/getmode.cfm" r_params="params"/>
	
	<!--- Raymond's comment: Only cache on home page --->
	<cfset disabled = false>
	<cfif url.mode is not "" or len(cgi.query_string) or not structIsEmpty(form)>
		<cfset disabled = true>
	</cfif> 
 
	<!--- Raymond's comment: Try to get the articles. --->
	<cftry>
		<!--- Added a new loggedIn argument to the getEntries function in order to display non released entries when logged in, or a cookie has been set upon prior successful login. --->
		<cfif isDefined("cookie.isAdmin") or isLoggedIn()>
			<cfset previewNonReleasedEntries = true>
		<cfelse>
			<cfset previewNonReleasedEntries = false>
		</cfif>
		<cfset articleData = application.blog.getEntries(params, previewNonReleasedEntries)>
		<cfset articles = articleData.entries>
		<!--- Raymond's comment: if using alias, switch mode to entry --->
		<cfif url.mode is "alias">
			<cfset url.mode = "entry">
			<cfset url.entry = articles.id>
		</cfif>
		<cfcatch>
			<cfset articleData = structNew()>
			<cfset articleData.totalEntries = 0>
			<cfset articles = queryNew("id")>
		</cfcatch>
	</cftry>

	<!--- Raymond's comment: Call layout custom tag. --->
	<cfset data = structNew()>
	<!--- 
	Raymond's comment: I already know what I'm doing - I got it from getMode, so let me bypass the work done normally for by Entry, it is the most
	popular view
	--->
	<cfif url.mode is "entry" and articleData.totalEntries is 1>
		<cfset data.title = articles.title[1]>
		<cfset data.entrymode = true>
		<cfset data.entryid = articles.id[1]>
		<cfif not structKeyExists(session.viewedpages, url.entry)>
			<cfset session.viewedpages[url.entry] = 1>
			<cfset application.blog.logView(url.entry)>
		</cfif>
	</cfif>

	<!--- The original include to the layout.cfm template was done here. This include contained logic for the header, the includes, stylesheets, and pods, and then the layout.cfm logic ended. Older logic for the actual posts were resumed after the layout.cfm template include.
	I have redesigned the page from here to include the entire logic for the presentation, including the logic found on the old layout.cfm template. I will be resuing Raymond's server side and ColdFusion functions, but the page has been vastly redesigned. --->

	<!--- TODO <cfif thisTag.executionMode is "start">--->

	<cfif isDefined("attributes.title")>
		<cfset additionalTitle = ": " & attributes.title>
	<cfelse>	
		<cfset additionalTitle = "">
		<cfif isDefined("url.mode") and url.mode is "cat">
			<!--- can be a list --->
			<cfset additionalTitle = "">
			<cfloop index="cat" list="#url.catid#">
			<cftry>
				<cfset additionalTitle = additionalTitle & " : " & application.blog.getCategory(cat).categoryname>
				<cfcatch></cfcatch>
			</cftry>
			</cfloop>

		<cfelseif isDefined("url.mode") and url.mode is "entry">
			<cftry>
				<!---
				Raymond's comment: Should I add one to views? Only if the user hasn't seen it.
				--->
				<cfset dontLog = false>
				<cfif structKeyExists(session.viewedpages, url.entry)>
					<cfset dontLog = true>
				<cfelse>
					<cfset session.viewedpages[url.entry] = 1>
				</cfif>
				<cfset entry = application.blog.getEntry(url.entry,dontLog)>
				<cfset additionalTitle = ": #entry.title#">
				<cfcatch></cfcatch>
			</cftry>
		</cfif>
	</cfif>
	
	<!--- Added by Gregory to simplify the code on the client. --->
	<cfset descriptionMetaTagValue = application.blog.getProperty("blogDescription") & additionalTitle>
	<cfset titleMetaTagValue = htmlEditFormat(application.blog.getProperty("blogTitle"))>
		
	<!--- Gregory added to get the proper image when sharing. We want the default image that is set when there are multiple entries, but the image that we used for the enclosure when there is only one post. --->
	<cfif url.mode is "entry" and articleData.totalEntries is 1 and (entry.enclosure contains '.jpg' or entry.enclosure contains '.gif' or entry.enclosure contains '.png' or entry.enclosure contains '.mp3')>
		<cfset imageMetaTagValue = application.rootUrl & "/enclosures/" & getFileFromPath(entry.enclosure)>
	<cfelse>
		<cfset imageMetaTagValue = application.rootUrl & application.defaultLogoImageForSocialMediaShare>
	</cfif>
<cfelse>
	<cfmodule template="#customCoreLogicTemplate#" />
</cfif>
<!--- //**************************************************************************************************************************************************
			Page output
//****************************************************************************************************************************************************--->					
</cfsilent>
<cfoutput>
<head>
<cfif customHeadTemplate eq ""> 
	<title>#htmlEditFormat(application.blog.getProperty("blogTitle"))##additionalTitle#</title>
	<meta name="title" content="#descriptionMetaTagValue#" />
	<meta name="description" content="#descriptionMetaTagValue#" />
	<meta name="keywords" content="#application.blog.getProperty("blogKeywords")#" />
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<!-- Twitter meta tags. -->
	<meta name="twitter:card" content="summary_large_image">
	<meta name="twitter:site" content="@gregoryalexander.com">
	<meta name="twitter:title" content="#descriptionMetaTagValue#">
	<meta name="twitter:description" content="#descriptionMetaTagValue#">
	<meta name="twitter:image" content="#imageMetaTagValue#">
	<!-- Open graph meta tags for Facebook. See notes. -->
	<meta property="og:image" content="#imageMetaTagValue#">
	<meta property="og:site_name" content="#htmlEditFormat(application.blog.getProperty("blogTitle"))#" />
	<!--- As of 7/19/19, 1200 x 630 creates a full size image on facebook. However, we want to keep the width and height in the meta tags aat 1200x1200 in order to keep the facebook image at full screen. --->
	<meta property="og:image:width" content="1200" />
	<meta property="og:image:height" content="1200" />
	<meta property="og:title" content="#descriptionMetaTagValue#" />
	<meta property="og:description" content="#descriptionMetaTagValue#" />
	<meta property="og:type" content="blog" />
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<meta name="viewport" content="width=device-width, initial-scale=1"><!---<meta name="viewport" content="968"><meta name="viewport" content="1280">--->
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
	<!--- Optional libraries are included at the tail end of the page. --->
	<cfsilent>
	<!---
	Removed jQuery include as they are now included in the application in the kendoScripts.cfm template (ga 10/27/2018).
	Removed launchComment(id) and launchCommentSub(id) and replaced functions with a Kendo window. (ga)
	Also removed 'tweetback' logic as it was causing errors.
	--->
	</cfsilent>
<cfelse>
	<cfmodule template="#customHeadTemplate#" />
</cfif>
</head>
<cfsilent>
<!--- 
Testing carriage 

Theme:
kendoTheme: '#kendoTheme#' listFindNoCase(application.darkThemes, getKendoTheme()): #listFindNoCase(application.darkThemes, getKendoTheme())# coldFishXmlFileName: #coldFishXmlFileName#
--->
</cfsilent>
</cfoutput>
<!--Script to adjust properties depending upon the device screen size. I am putting the javascript and css front and center here in order to show exactly what I am doing. One of my main goals is to educate, and I don't want to obsufacte the code. -->
<script>
	
	// Set global vars. This is determined by the server (for now).
	isMobile = <cfoutput>#session.isMobile#</cfoutput>;
	// Get the breakpoint. This will be used to hide or show the side bar container ast the right of the page once the breakpoint value has been exceeded. The breakpoint can be set on the admin settings page. Note: the breakpoint is always set high on mobile as we don't have room for the sidebar.
	breakpoint = <cfoutput><cfif session.isMobile>50000<cfelse>#breakpoint#</cfif></cfoutput>;
	
	// Call the method on page load.
	setScreenProperties();
	
	// Set the content width depending upon the screen size.
	function getContentWidthPercent() {
		
		// Get the current dimensions.
		var desiredContentWidth = <cfoutput>#contentWidth#</cfoutput>;
		
		if (desiredContentWidth == 66){
			var windowWidth = $(window).width();
			var windowHeight = $(window).height();

			// Set the content width depending upon the screen size.
			if (windowWidth <= 1140){
				var contentWidthPercent = '95%';
			} else if (windowWidth <= 1280) {
				var contentWidthPercent = '90%';
			} else if (windowWidth <= 1400) {
				var contentWidthPercent = '85%';
			} else if (windowWidth <= 1500) {
				var contentWidthPercent = '80%';
			} else if (windowWidth <= 1600) {
				var contentWidthPercent = '70%';
			} else if (windowWidth <= 1700) {
				var contentWidthPercent = '66%';
			} else if (windowWidth <= 1920) {
				var contentWidthPercent = '60%';
			} else {
				var contentWidthPercent = '50%';
			}
			// Return it.
			return contentWidthPercent;
		} else {
			return <cfoutput>"#contentWidth#%"</cfoutput>;
		}
	}
	
	// Match everything up....
	function setScreenProperties(){
		var desiredContentWidth = <cfoutput>#contentWidth#</cfoutput>;
		var mainContainerWidth = <cfoutput>#mainContainerWidth#</cfoutput>;
		var windowWidth = $(window).width();
		var windowHeight = $(window).height()
		var contentWidthAsInt = getContentWidthPercent();
		var mainContainerWidth =  calculatePercent(mainContainerWidth, getContentPixelWidth())+"px"
		
		/* Notes:
		1) This will be converted into media queries in the next version.
		2) This function will be invoked twice. Once upon page load, and then again when the body detects a resize. 
		3) This was designed to maximize the size of the background image when the desktop or tablet has a wide screen size.
		
		The contentWidth applies to the header, and the outer container that holds the mainContainer and sidebar container elements. 
		Using contentWidth of 66% looks good when the screen width is at least 1600x900, which is the size of a 20 inch monitor.
		The 66% setting looks great with a 20 inch monitor. 
		80% works with 1280x768, which is a 19 inch monitor or a 14 Notebook. 
		I am adjusting the contentWidth via javascript to ensure proper rendering of the page.
		*/
		
		// Handle the sidebar and the sideBarPanels
		if (windowWidth <= 1280){
			// Hide the sidepanel (the responsive panel will takeover here).
			$( "#sidebar" ).hide();
			// Show the responsive panel
			$("#sidebarPanel").show(); 
			// Display the hamburger in the menu (the 5th node).
			$(".k-menu > li:eq(4)").show();
		} else {
			// Is the sidebar hidden?
			if ($("#sidebar").is(":hidden")){
				// Display the sidebar. This should only happen when someone is readjusting their screen sizes.
				$( "#sidebar" ).show();
			}
			// If this is a desktop device, remove the hamburger icon.
			if (!isMobile){
				// remove the hamburger in the menu (the 5th node)..
				$(".k-menu > li:eq(4)").hide();
			}
			// If the sidebarPanel responsive panel is open, hide it if the browser was readjusted to a screen size larger than 1280 pixels. Otherwise, the sidebarPanel will be stuck on the left of the desktop screen with no way to close it.
			$("#sidebarPanel").hide(); 
		}
		
		// Change to root css contentWidth propery to match the desired content width (the percentage that the blog overlay will consume on the screen). */
		document.documentElement.style.setProperty('--contentWidth', getContentWidthPercent());
		// IE css fallback
		if (!getBrowserSupportForCssVars()){
			setContentWidthElements(getContentWidthPercentAsInt());
		}
		
		// Set the getContentPaddingPercent. This is 100 minus the contentWidthPercent divided by 2. 
		document.documentElement.style.setProperty('--contentPaddingPercent', getContentPaddingPercent());
		// Set the contentPaddingPixelWidth to set left and right padding elements in pixels. This is the screen size minus the contentWidth divided by two. 
		document.documentElement.style.setProperty('--contentPaddingPixelWidth', getContentPaddingPixelWidth()+"px");
		 // Set the blog content width
		document.documentElement.style.setProperty('--mainContainerWidth', mainContainerWidth);
		
		// Double check and make sure that the main container and header width matches (it won't match right now as the padding that I had used increases the content size). I'll fix in the next version.
		// Get all of the styles.
		var allStyles = getComputedStyle(document.documentElement);
		// Get the content with value.
		var contentWidthValue = String(allStyles.getPropertyValue('--contentWidth')).trim();
		// Get the width of the main flex container ('mainPanel').
		var parentContainerWidth = $( "#mainPanel" ).width();
		// Get the width of the header container which we need to align.
		var headerContainerWidth = $( "#headerContainer" ).width();
		//alert('contentWidthValue: ' + contentWidthValue + ' parentContainerWidth: ' + parentContainerWidth + ' headerContainerWidth: ' + headerContainerWidth);
		
		// If both the parent and header container widths are not null (when this function first loads), and the header does not match the width of the parent container, resize the header. The sizes are not identical as the padding expands the parent container. I will fix this in an upcoming version.
		if ((!!parentContainerWidth && !!headerContainerWidth) && parentContainerWidth != headerContainerWidth){
		<cfif headerBannerWidth eq '100%'>// The header, fixedNav header, and footer are set to stretch accross the page
		<cfelse>$( "#headerContainer" ).width(parentContainerWidth + "px");
			// Resize the width of the header elements.
			$( "#fixedNavHeader" ).width(parentContainerWidth + "px");
			$( "#footerDiv" ).width(parentContainerWidth + "px");
		</cfif>
		}
	}
	
	// Function to determine if the browser supports global css vars. The else block is used for IE 11 which returns undefined. 
	function getBrowserSupportForCssVars() {
		if (window.CSS && CSS.supports('color', 'var(--fake-var)')){
			return window.CSS && CSS.supports('color', 'var(--fake-var)');
		} else {
			return false;
		}	
	}
	
	// This function is used to set width on the required elements that use the css -contentWidth setting for depracated browsers (IE 11 in particular).
	function setContentWidthElements(width){
		// Manually set the widths of the elements since the root css vars will not be read.
	<cfif headerBannerWidth neq '100%'>// If the headerBannerWidth is 100%, hard code the width value, otherwise, use the content width value 
		$("#fixedNavHeader").width(width + "%");
		$("#headerContainer").width(width + "%");
	</cfif>
		$("#mainBlog").width(width + "%");
		$("#mainPanel").width(width + "%");
		$("#blogContent").width(width + "%");
		$("#constrainerTable").width(width + "%");
	}
	
	// Returns the content width as an int.
	function getContentWidthPercentAsInt(){
		return parseInt(getContentWidthPercent());
	}
	
	// Gets the content width in pixels.
	function getContentPixelWidth(){
		var windowWidth = $(window).width();
		var contentWidthPercent = getContentWidthPercentAsInt();
		var contentPixelWidth = windowWidth*(contentWidthPercent/100);
		return Math.round(contentPixelWidth);
	};
	
	// Gets the background width with is the screen width.minus the content width
	function getContentPaddingPercent(){
		var contentPaddingPercent = Math.round((100-getContentWidthPercentAsInt())/2) + '%';
		return contentPaddingPercent;
	}
	
	// Gets the background width with is the screen width.minus the content width
	function getContentPaddingPixelWidth(){
		var windowWidth = $(window).width();
		var contentPaddingPixelWidth = Math.round((windowWidth - getContentPixelWidth())/2);
		return contentPaddingPixelWidth;
	}
	
	// This function is used to set the max-width for the blogContent and the sideBar. We need to get the number of pixes for a given percent. 
	function calculatePercent(percent, number){
		var val = ((percent/100) * number);
		return Math.round(val);
	}
	
	// Scroll to top with easing
	function scrollToTop(){
		var top = 0;
		$('html, body').animate({
			scrollTop: top
		},500);
		
		// Close the menu that is calling this function (I would do it in the menu, but I can only call a simple function from there).
		// Get a reference to the menu widget
    	var menu = $("#fixedNavHeader").data("kendoMenu");
    	// Close it.
    	menu.close();

		return false;
	}
	
	// Scroll to bottom with easing
	function scrollToBottom(){
		$([document.documentElement, document.body]).animate({
        	scrollTop: $("#pagerAnchor").offset().top
    	}, 500);
		
		// Close the menu that is calling this function (I would do it in the menu, but I can only call a simple function from there).
		// Get a reference to the menu widget
    	var menu = $("#fixedNavHeader").data("kendoMenu");
    	// Close it.
    	menu.close();

		return false;
	}
	
	// Listeners 
	// Script to show the sticky header when a certain scroll position has been reached (i.e. the navigation menu that is shown at the top of the page when you scroll down a little bit).
	$(document).scroll(function() {
		var y = $(this).scrollTop();
		// If the user has scrolled down 40 pixels...
		if (y > 40) {
			$('#fixedNavHeader').fadeIn();
		} else { // or if the user had scrolled up, or is at the top of the page...
			$('#fixedNavHeader').fadeOut();
		}
	});
	
	<cfsilent>
	// Not yet...
	// Determine the scroll events.
	$(function(){
		var _top = $(window).scrollTop();
		var _direction;
		$(window).scroll(function(){
			var _cur_top = $(window).scrollTop();
			if(_top < _cur_top){
				_direction = 'down';
			} else {
				_direction = 'up';
			}
			_top = _cur_top;
			console.log(_direction);
		});
	});
	</cfsilent>	
</script>

<cfif customBodyString eq ""><body onload="if(top != self) top.location.replace(self.location.href); setScreenProperties();" onresize="setScreenProperties()"><cfelse><cfoutput>#customBodyString#</cfoutput></cfif>
	<cfsilent>
	<!---
	Testing carriage.
	 --->
	<!---//**************************************************************************************************************************************************
				Font .css
	//*******************************************************************************************************************************************************
	Notes on css files: I typically use internal stylesheets as I have access to variables in a .cfm page that uses them. If I externalize the css files, I lose the ability to easilly use ColdFusion dynamic variables. --->
	</cfsilent>
	
<cfif customFontCssTemplate eq "">
	<style><cfoutput>
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
	</style></cfoutput>
<cfelse>
	<cfmodule template="#customFontCssTemplate#" />
</cfif>

<cfif customGlobalAndBodyCssTemplate eq "">
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Global .css vars
	//**************************************************************************************************************************************************--->
	</cfsilent>
	<style><cfoutput>
		
		/* ------------------------------------------------------------------------------------------------------------
		Global CSS vars and body.
		Create a content width global css var. We will change this with Javascript depending upon the screen resolution 
		--------------------------------------------------------------------------------------------------------------*/
		:root {
			-- contentWidth: <cfoutput>#contentWidth#</cfoutput>%;
			-- contentPaddingPercent: <cfoutput>#round((contentWidth/2)/2)#</cfoutput>%;
			-- mainContainerWidth: <cfoutput>#mainContainerWidth#</cfoutput>%;
		}

		<cfif session.isMobile>/* This should work to apply a fixed background on iOs */
		body:before {
			content: "";
			display: block;
			position: fixed;
			left: 0;
			top: 0;
			width: 100%;
			height: 100%;
			z-index: -10;
			background: url(<cfoutput>#blogBackgroundImage#</cfoutput>) <cfoutput>#blogBackgroundImageRepeat# #blogBackgroundImagePosition#</cfoutput>;
			-webkit-background-size: cover;
			-moz-background-size: cover;
			-o-background-size: cover;
			background-size: cover;
		}
		
		html, body {
			font-family: Arial, Helvetica, sans-serif;
			/* Set the global font size. Mobile should be two sizes smaller to maximize screen real estate. */
			font-size: 12pt;
		}
			
		<cfelse>body {
			background-image: url("<cfoutput>#blogBackgroundImage#</cfoutput>");
			background-repeat: <cfoutput>#blogBackgroundImageRepeat#</cfoutput>;
			background-position: <cfoutput>#blogBackgroundImagePosition#</cfoutput>; /* Center the image */
			<cfif blogBackgroundImageRepeat eq "no-repeat">background-size: cover;</cfif>
			background-attachment: fixed;
			/* Opacity trick */
			filter: alpha(Opacity=<cfoutput>#siteOpacity#</cfoutput>);
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			/* Set the global font size. */
			font-size: 16pt;
		}</cfif><!---<cfif session.isMobile>--->
		
		/* Set links */	
		a {
		<cfif darkTheme>color: whitesmoke;
			text-decoration: underline;
			<cfelse>text-decoration: underline;</cfif>
		}
				
		/* Flex classes */
		.flexParent {
			display: flex;
			justify-content: center;
			align-items: stretch;
		}
				
		/* Force items to be 100% width, via flex-basis */
		.flexParent > * {
		  flex: 1 100%;
		}

		.flexHeader { 
			order: 1;
		}
		
		.flexMainContent { 
			order: 2; 
		}
		
		.flexSidebar { 
			order: 3; 
		}
				
		.flexFooter { 
			order: 4; 
		}
				
		.flexItem {
  			flex: 0 0 auto; 
		}
		
		/*
		[1]: Make a flex container so all our items align as necessary
		[2]: Prevent items from wrapping
		[3]: Automatic overflow means a scroll bar won’t be present if it isn’t needed
		[4]: Make it smooth scrolling on iOS devices
		[5]: Hide the ugly scrollbars in Edge until the scrollable area is hovered
		[6]: Hide the scroll bar in WebKit browsers
		*/
		.flexScroll {
			display: flex; /* [1] */
			flex-wrap: nowrap; /* [1] */
			overflow-x: auto; /* [1] */
			-webkit-overflow-scrolling: touch; /* [4] */
			-ms-overflow-style: -ms-autohiding-scrollbar; /* [5] */ 
		}

		/* [6] */
		.scroll::-webkit-scrollbar {
			display: none; 
		}
			
	</style></cfoutput>
<cfelse>
	<cfmodule template="#customGlobalAndBodyCssTemplate#" />
</cfif>
	
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Top menu .css
	//**************************************************************************************************************************************************--->
	</cfsilent>
<cfif customTopMenuCssTemplate eq "">
	<style>
		
		/* States for the header menu */
		ul.k-hover { 
		  background-color: transparent !important;
		  background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
		  border: 0;
		  border-right: none;
		} 

		ul.k-link { 
		  background-color: transparent !important;
		  background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
		  border: 0;
		} 

		/* Containers */
		/* Fixed navigation menu at the top of the page when the user scrolls down */
		#fixedNavHeader {
			position: fixed;
			display: none;
			top: 0px;
			height: <cfif kendoTheme contains 'materialblack'><cfif session.isMobile>55<cfelse>65</cfif><cfelse><cfif session.isMobile>35<cfelse>45</cfif></cfif>px;
			width: <cfif headerBannerWidth eq '100%' or session.isMobile>100%<cfelse>var(--contentWidth)</cfif>;
			color: <cfoutput>#blogNameTextColor#</cfoutput>; /* text color */
			font-family: "Eras ITC", "Eras Light ITC", "erasBook", sans-serif;
			font-size: <cfif kendoTheme eq 'office365'><cfif session.isMobile>.75em<cfelse>1em</cfif><cfelse><cfif session.isMobile>.9em<cfelse>1em</cfif></cfif>;
			<cfif menuBackgroundImage neq "">
			background-color: transparent !important;
			background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');/* Without this, there is a white ghosting around this div. */
			background-repeat: repeat-x;
			</cfif>
			/* Subtle drop shadow on the header banner that stretches across the page. */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
			/* Center it */
			left: calc(-50vw + 50%);
			right: calc(-50vw + 50%);
			margin-left: auto;
			margin-right: auto;
			z-index: 1;
		}
		<cfsilent>
		<!--- TODO This needs to be in a function. Logic to determine what side the padding should occur when the alignBlogMenuWithBlogContent argument is true. --->
		<!--- Don't set any padding unless the stretchHeaderAcrossPage is true. Otherwise the header will be scrunched up in the center of the page. --->
		<cfif stretchHeaderAcrossPage and alignBlogMenuWithBlogContent>
			<cfif topMenuAlign eq 'left'>
				<cfset topWrapperCssString = "padding-left: var(--contentPaddingPixelWidth);">
			<cfelseif topMenuAlign eq 'right'>
				<cfset topWrapperCssString = "padding-right: var(--contentPaddingPixelWidth);">
			<cfelse>
				<cfset topWrapperCssString = "margin: auto;">
			</cfif>
		<cfelse>
			<cfset topWrapperCssString = "margin: auto;">
		</cfif>
		</cfsilent>
		/* Main wrapper within the header table. */
		#topWrapper {
			<cfoutput>#topWrapperCssString#</cfoutput>
		}
		
		/* The headerContainer is a *child* flex container of the mainPanel below. This may be counter-intuitive, but the main content is stuffed into the blogContent and I want the header to play nicely and following along. This container will be resized if it does not match the parent mainPanel container using the setScreenProperties function at the top of the page. */
		#headerContainer {
			/* Note: if the headerBackgroundImage is not specified, we will not use a drop shadow here */
			<!--- If the headerBannerWidth is 100%, hard code the width value, otherwise, use the content width value --->
			width: <cfif headerBannerWidth eq '100%'>100%<cfelse>var(--contentWidth)</cfif>;
			<cfif headerBackgroundImage neq ''>
			/* Subtle drop shadow on the header banner that stretches across the page. */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
			</cfif>
		}

		#blogNameContainer {
			font-family: 'Eras Demi'; /* Kaufmann Script Bold */
			font-size: <cfif session.isMobile>1.50em<cfelse>1.75em</cfif>; 
			font-weight: bold;
			/* The container may need to have some padding as the menu underneath it is not going to left align with the text since the menu is going to start prior to the first text item. */
			padding-left: 13px; 
			text-shadow: 0px 4px 8px rgba(0, 0, 0, 0.19); /* The drop shadow should closely mimick the shadow on the main blog layer.*/
			color: <cfoutput>#blogNameTextColor#</cfoutput>; /* Plain white has too high of a contrast imo. */
			vertical-align: center;
		}

		/* Menu container. Controls the placement of the menu. */
		#topMenuContainer {
			visibility: none;
			position: relative; 
			left: 0px; 
			<cfif menuBackgroundImage neq "">
			background-color: transparent !important;
			</cfif>
			vertical-align: center;
		}

		/* Menu's */
		/* the top menu is 60 pixels in height. */
		#topMenu {	
			<cfif menuBackgroundImage neq "">
			background-color: transparent !important;
			background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');/* Without this, there is a white ghosting around this div. */
			background-repeat: repeat-x;
			</cfif>
			border: 0;
			color: <cfoutput>#blogNameTextColor#</cfoutput>; /* text color */
			font-family: "Eras ITC", "Eras Light ITC", "erasBook", sans-serif;
			font-size: <cfif kendoTheme eq 'office365'><cfif session.isMobile>.75em<cfelse>1em</cfif><cfelse><cfif session.isMobile>.9em<cfelse>1em</cfif></cfif>;
			top: 32px;
			height: 20px;
			/* Note: an incorrect width setting will stretch the table container and skew the center allignment if not set properly. */
		}
		
		#siteSearchButton {
			/* Set the site search icon to match the blog text color */
			color: <cfoutput>#blogNameTextColor#</cfoutput>; /* Plain white has too high of a contrast imo. */
		}
		
		/* Remove the vertical border. The borders display a vertical line between the menu items and since we have custom images and colors on the banners, I want to remove these. */
		.k-widget.k-menu-horizontal>.k-item {
		  border: 0;
		}
				
	<cfif kendoTheme eq 'default' or kendoTheme eq 'highcontrast' or kendoTheme eq 'material' or kendoTheme eq 'silver'><!--- Both default and high contrast have the same header. Material needs to have a darker text when selecting a menu item--->
		/* fixedNavHeader states. */
		#fixedNavHeader.k-menu .k-state-hover,
		#fixedNavHeader.k-menu .k-state-hover .k-link,
		#fixedNavHeader.k-menu .k-state-border-down
		 /* 
		.k-menu .k-state-hover, (background and selected item when hovering)
		.k-menu .k-state-hover .k-link (background and selected item with a link when hovering)
		.k-menu .k-state-border-down, (backgound and selected item when scrolling down)
		*/
		{
			color: <cfoutput>#blogNameTextColor#</cfoutput>;
			font-family: "Eras ITC", "Eras Light ITC",  sans-serif ;
			background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
		}
		
		/* topMenu States */
		#topMenu.k-menu .k-state-hover,
		#topMenu.k-menu .k-state-hover .k-link,
		#topMenu.k-menu .k-state-border-down
		 /* 
		.k-menu .k-state-hover, (background and selected item when hovering)
		.k-menu .k-state-hover .k-link (background and selected item with a link when hovering)
		.k-menu .k-state-border-down, (backgound and selected item when scrolling down)
		*/
		{
			color: <cfoutput>#blogNameTextColor#</cfoutput>;
			font-family: "Eras ITC", "Eras Light ITC",  sans-serif ;
			background-image: url('<cfoutput>#menuBackgroundImage#</cfoutput>');
		}
	</cfif><!---<cfif kendoTheme eq 'default' or kendoTheme eq 'highcontrast'>--->
		
		/* Remove the vertical border. The borders display a vertical line between the menu items and since we have custom images and colors on the banners, I want to remove these. */
		.k-widget.k-menu-horizontal>.k-item {
		  border: 0;
		}
		
		#logo {
			border: 0;
			position: relative;
			padding-top: <cfoutput>#logoPaddingTop#</cfoutput>;
			padding-left: <cfoutput>#logoPaddingLeft#</cfoutput>;
			padding-right: <cfoutput>#logoPaddingRight#</cfoutput>;
			padding-bottom: <cfoutput>#logoPaddingBottom#</cfoutput>;
		}
		
		/* Kendo class over-rides. */
		<cfif session.isMobile>
		/* Increase the close button on mobile */
		.k-window-titlebar .k-i-close {
			zoom: 1.2;
		}
		</cfif>
		/* Change the window font size (its too big for mobile). The Kendo window is not responsive, and has it's own internal properties that are hardcoded, so I need to reset properties using inline styles, such as font-size. */
		.k-window-titlebar {
			font-size: 16px; /* set font-size */
		}
		
	</style>
<cfelse>
	<cfmodule template="#customTopMenuCssTemplate#" />
</cfif>
	
	<cfsilent>	
	<!---//**************************************************************************************************************************************************
				Blog html body stylesheet
	//***************************************************************************************************************************************************--->
	</cfsilent>
<cfif customBlogContentCssTemplate eq "">
	<style>

		#mainBlog {
			/* This is the main flex container (set by class) and essentially the outer table */
			position: relative;
			display: table;
			width: var(--contentWidth); 
			margin:0 auto;
			/* Subtle drop shadow on the main layer */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
		<cfif session.isMobile>
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
		</cfif>
		}
		
		/* The main container is also the parent flex container for the blogContent and sidebar elements. It also controls the header width after the body is resized using the setScreenProperties function at the top of the page. */
		#mainPanel {
			display: table-row;
			width: var(--contentWidth); 
		<cfif session.isMobile>
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
			/* Set the global font size. The minimum mobile font size should be no less than 12. */
			font-size: <cfoutput><cfif (application.blogFontSize-4) lt 12>12<cfelse>#application.blogFontSize-4#</cfif></cfoutput>pt;
		<cfelse>
			/* Set the global font size. */
			/* font-size: <cfoutput>#application.blogFontSize#</cfoutput>pt; */
		</cfif>
		}
		
		/* This is a child container of the mainPanel. Note: the formatter forces the width of this element to exceed the width of the mainPanel. */		
		#blogContent {
			display: table-cell;
			margin: 0;
		<cfif session.isMobile>
			width: 95%;	
			/* Contstrain the width. */
			max-width: var(--mainContainerWidth);
			/* On mobile devices, cut the padding in half as screen real estate is not cheap. We don't have to worry about having extra padding to the right as the side-bar element is not used in mobile. */
			padding-top: 10px;
			padding-right: 10px;
			padding-bottom: 10px;
			padding-left: 10px;
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
		<cfelse>
			width: <cfoutput>#mainContainerWidth#</cfoutput>%;
			/* Contstrain the width. */
			max-width: var(--mainContainerWidth);
			/* Apply a min width of 600 pixels. We are making an assumption that the minimum display resolution will be 800 pixels and apply the 200 pixels to the outer container. */
			min-width: 600px;
			/* On mobile, apply less padding on the right to keep things uniform. Otherwise, keep the padding consistent. */
			padding-top: 20px;
			padding-right: 20px;
			padding-bottom: 20px;
			padding-left: 20px;
		</cfif>
			vertical-align: top;
			/* clear the floating sidebar */
      		overflow: hidden;
		}

		/* The next three classes will be used to create a calendar date placard */
		#blogPost p.postDate {
		  position: relative;
		  width: 38px;
		  /* The dark theme height must be increased with the dark themes otherwise the line at the bottom will not be displayed. */
		  height: <cfif darkTheme>50px<cfelse>38px</cfif>;
		  display: block;
		  margin: 0;
		  padding: 0px;
		  text-align: center;
		  float: left;
		  line-height: 100%;
		  /* background: #fff url(<cfoutput>#application.blogCfcUrl#</cfoutput>/images/date-bg.png) no-repeat left bottom; */
		  border: 1px solid #fff;
		}

		#blogPost p.postDate span.month {
		  position: absolute;
		  /* Set the font size to 14px */
		  font-size: <cfif session.isMobile>0.55em<cfelse>0.70em</cfif>;
		  /* Note: the additional 'k-primary' kendo class attached to the span will set the background */
		  border-bottom: 1px solid #fff;
		  /* The width is set at 36px for the dark themes. If set to 100%, the white line that surrounds the date will disappear on the right side of the date. */
		  width: <cfif darkTheme>34px<cfelse>100%</cfif>;
		  top: 0;
		  left: 0;
		  height: 19px;
		  text-transform: uppercase;
		  padding: 2px;
		}

		#blogPost p.postDate span.day {
		  /* Set the font size to 14px */
		  font-size: <cfif session.isMobile>0.60em<cfelse>0.75em</cfif>;
		  /* Note: the additional 'k-alt' kendo class attached to the span will set the background. The calendar image is rather dificult to control. I would not adjust these settings much. It took me a long time to get it right. */
		  display: table-cell;
		  vertical-align: middle;
		  bottom: 1px;
		  top: 25px;
		  left: 0;
		  height: 19px;/*30%/*
		   /* The width is set at 36px for the dark themes. If set to 100%, the white line that surrounds the date will disappear on the right side of the date. */
		  width: <cfif darkTheme>34px<cfelse>100%</cfif>;
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
		  font-size: 1em;
		  font-style: italic;
		  /* border: 1px solid #f2efe5; */
		  min-height: 38px;
		  color: #75695e;
		  height: auto !important;
		  height: 38px;
		  line-height: 100%;
		}
				
		#innerContentContainer {
			/* Apply padding to all of the elements within a blog post. */
			margin-top: 5px; 
			padding-left: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			padding-right: <cfif session.isMobile>10<cfelse>20</cfif>px;
			display:block;
		}
		
		/* The calendar should have minimal padding */
		#calendarInnerContentContainer {
			/* Center the calendar widget */
			text-align: center;
			/* Apply padding to all of the elements within a blog post. */
			margin-top:5px; 
			margin-bottom:20px; 
			padding-right:2px;
			display:block;
		}

		#postContent {
			/* Apply padding to post content. */
			margin-top: 5px; 
			display: block;
		}
		
		/* Constraining images to a max width so that they don't push the content containers out to the right */
		.entryImage img {
			width: 100%;
			/* Subtle drop shadow on the image layer */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
		}

		#sidebar {
			/* We are going to eliminate this sidebar for small screen sizes and mobile. */
			display: table-cell;
			margin: 0;
			/* Apply less padding to the left to keep things uniform. On mobile devices, cut the padding in half as screen real estate is not cheap. */
			padding-top: 20px;
			padding-right: 20px;
			padding-bottom: 20px;
			padding-left: 10px;
			width: <cfoutput>#sideBarContainerWidth#</cfoutput>%;
			min-width: 375px;
			vertical-align: top;
			overflow: hidden;
		}
		
		/* The side bar panel is essentially a duplicate of the sidbar div, however, it is a responsive panel used when the screen size gets small. */
		#sidebarPanel {
			/* We need to hide the sidebarPanel if the device is not mobile. Otherwise, the sidebarPanel is a flex container. */
			display: <cfif session.isMobile>flex<cfelse>none</cfif>;
			flex-direction: column;
		<cfif not session.isMobile>/* On desktop, we want the sidebar panel to also scroll with the page. Otherwise, the padding that places it underneath the header is disruped and it looks wierd. */
			position: absolute;
		</cfif>
    		height: 100%;
    		width: <cfif session.isMobile>275px<cfelse>40%</cfif>;
			-webkit-touch-overflow: scroll;
			/* Note: the panel will not scroll with the blog content unless there is a css position: absolute. */
			z-index: 5;
			opacity: <cfoutput>#siteOpacity#</cfoutput>;
			margin: 0;
			/* All padding should be set at 10px */
			padding: 10px 10px 10px 10px;
			vertical-align: top;
			border-right: thin;
		}
		
		/* Kendo UI applies default min-width (320px) to left and right panel elements, which causes the difference in width between top and left/right panels. We are overriding this default style with the following CSS rule: */
		.k-rpanel-left, .k-rpanel-right {
			min-width: 0px;
		 }
		
		/* Put a drop shadow on the panel when it is expanded. */
		#sidebarPanel.k-rpanel-expanded {
		<cfif session.isMobile>/* On mobile, the table height is 100px. We want to give about 5 pixels more height to allow the divider to be seen. */<cfelse>/* On desktop, the table height is 105px. We want to give about 5 pixels more height to allow the divider to be seen. */</cfif>
			margin-top: <cfif session.isMobile>105px<cfelse>110px</cfif>;
			/* Fallback var for IE 11 */
			margin-left: 5%;
			margin-left: var(--contentPaddingPercent);
			-webkit-box-shadow: 0px 0 10px 0 rgba(0,0,0,.3);
    		-moz-box-shadow: 0px 0 10px 0 rgba(0,0,0,.3);
            box-shadow: 0 0 10px rgba(0,0,0,.3);
        }
		
		#sidebarPanelWrapper {
			/* This is both the flex parent and a flex child item. Flex is being used here in order to put up a scroll bar. iOs devices will not allow the panel to be scrolled along with the main container as iOs considers a scroll event past the bottom of the screen to be a screen refresh and this causes the responsive panel to close when scrolled. Instead, we are allowing the user to scroll either the panel or the body. */
			display: flex;
			flex-direction: column;
    		height: 100%;
    		width: 100%;
			/* iOs and mobile */
			-webkit-touch-overflow: scroll;
		}
		
		/* Title bar of the calendar (we need more space for this widget) */
		.calendarWidget h3.topContent {
			font-size: 1em;
			padding-top: 0px;
			padding-right: 0px;
			padding-bottom: 10px;
			padding-left: 0px;
			border-bottom: 1px solid #e2e2e2;
			text-align: left;
		}
		
		/* The calendar widget should have no padding (we need all of the space that we can get to ensure that it is displayed properly). */
		.calendarWidget {
			padding: 0;
		}
		
		.calendarWidget div {
			padding: 0px;
		}
		
		/* widget class (the panels) */
		.widget {
			margin-top: 0px;
			margin-right: 0px;
			margin-bottom: 20px;
			margin-left: 0px;
			padding: 0;
			border: 1px solid #e2e2e2;
			border-radius: 3px;
			/* cursor: move; */
		}

		/* This syle affects the div containers within the widget on the left side of the page. */
		.widget div {
			/* padding: 10px; The padding screws up the Kendo media player widget. */
		}

		/* Title bar */
		.widget h3.topContent {
			font-size: 1em;
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

		/* Arrow on to show comments */
		.widget #collapse {
			float: right;
		}
		
		.widget.placeholder {
			opacity: 0.4;
			border: 1px dashed #a6a6a6;
		}
				
		.panel-wrap {
			display: table;
			margin: 0 0 20px;
			/* Controls the width of the container */
			border: 1px solid #e5e5e5;
		}

		#blogCalendar {
			/* Align the calendar in the center. We must use the text-align property for this (I know that this is counter-intuitive). */
			text-align: center;
			width: 100%;
		}
		
		#blogCalendarPanel {
			/* Align the calendar in the center. We must use the text-align property for this (I know that this is counter-intuitive). */
			text-align: center;
			width: 100%;
		}
		
		/* Other than the recent comment pod, don't wrap pod content, and if the text exceeds the size of the html tables, ellipsis the text (like so 'and...')  */
		.mediaPlayer {
			white-space: nowrap;
			overflow: hidden;
			/* The players z-index must be set lower than the rest of the elements, or the media player will bleed through the other elements that should be on top of this */
			z-index: 0;
		}

		.fixedCommentTable {
			table-layout: fixed;
			width: 100%;
		}

		/* Column widths are based on these cells */
		.fixedCommentTablePadding {
			width: 5px;
		}

		.fixedCommentTableContent {
			min-width: 100%;
			width: 100%;
		}

		/* We need to fix all content within the tables in the pods, otherwise, the tables may not be resized. */
		.fixedPodTable {
			table-layout: fixed;
			width: 100%;
		}

		/* Other than the recent comment pod, don't wrap pod content, and if the text exceeds the size of the html tables, ellipsis the text (like so 'and...')  */
		.fixedPodTable td {
			color: whitesmoke;
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis;
		}

		/* Other than the recent comment pod, don't wrap pod content, and if the text exceeds the size of the html tables, ellipsis the text (like so 'and...')  */
		.fixedPodTableWithWrap td {
			color: whitesmoke;
			overflow: hidden;
			text-overflow: ellipsis;
		}

		td.border {
			border-top: 1px solid #ddd;
		}

		/* Divider styles to get around IE's goofyness. IE 8+ will not render elemetns that are larger than the default font size, so I am setting the font property to 0. Stupid.... */
		.rowDivider{
			font-size: 0px;
			height: 1px; 
			background:#F00
			border: solid 1px #F00;
			width: 100%;   
			overflow: hidden;
		}
		
		/* For some odd reason, using width: 100% causes the month toolbar at the top of the calendar to be wider than the calendar widget. I tried 300 px, and that didn't look right either. Sticking with 90% for now. I am assuming that my display css is screwing things up here. */
		.k-widget.k-calendar {
			width: 90%;
		}
		.k-widget.k-calendar .k-content tbody td {
			width: 90%;
		}

		/* Make the avatar round. I personally don't like squares, especially when I put some of the data into Kendo grids (in a later version). */
		.avatar {
			border-radius: 50%;
			-moz-border-radius: 50%;
			-webkit-border-radius: 50%;
		}
		
		/* Footer classes */
		#footerDiv {
		<cfif session.isMobile>
			/* Opacity for iOs */
			opacity: 0.<cfoutput>#siteOpacity#</cfoutput>;
			visibility: visible;
		</cfif>
			width: var(--contentWidth);
			/* Subtle drop shadow on the header banner that stretches across the page. */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
			/* Center it */
			left: calc(-50vw + 50%);
			right: calc(-50vw + 50%);
			margin-left: auto;
			margin-right: auto;
			z-index: 1;
			border: 1px solid #e2e2e2;
			border-radius: 3px;
		}
		
		#footerInnerContainer {
			/* Apply padding to all of the elements. */
			margin-top: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			margin-left: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			margin-right: <cfif session.isMobile>10<cfelse>20</cfif>px;
			margin-bottom: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			padding: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			/*background-color: whitesmoke;*/
			display: block;
			border: 1px solid #e2e2e2;
			border-radius: 3px;
		}
		
		/* Title bar for the footer */
		#footerInnerContainer h4 {
			font-size: 1em;
			padding-top: 0px;
			padding-right: 0px;
			padding-bottom: 10px;
			padding-left: 0px;
			border-bottom: 1px solid #e2e2e2;
			text-align: left;
		}

		/* Footer main content */
		#footerInnerContainer p {
			padding-top: 10px;
			padding-right: 0px;
			padding-bottom: 0px;
			padding-left: 0px;
		}
		
		/* Center the logo */
		#footerInnerContainer img {
			display: block;
  			margin-left: auto;
  			margin-right: auto;
		}
		
		/* Center the logo */
		#footerInnerContainer a {
			/* color: whitesmoke; */
		}
		
		/* Utility classes */
		/* The constrainer table will constrain one or many different div's and spans to a certain size. It is handy to use when you are trying to contain the size of elements created by an older libary that does not use responsive design. */
		#constrainerTable {
			/* The parent element (this table) should be positioned relatively. */
			position: relative;
			/* Now that the parent element has a width setting, make sure that the width does not ever exceed this */
			max-width: 100%;
		}	
		
		/* Helper function to the constrainerTable to break the text when it exceeds the table dimensions */
		#constrainerTable .constrainContent {
			/* Use the root width var */
			width: var(--contentWidth);
			max-width: 100%
		}
		
		#constrainerTable th {
			max-width: var(--contentWidth);
		}
		
		#constrainerTable td {
			word-break: break-word;
		}
		
		.spacer {
			display: inline-block;
			width: 100%;
		}
		
		
	</style>
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Blog content css. This handles the content within an entry.
	//***************************************************************************************************************************************************--->
	</cfsilent>
	<style>
		/* Kendo FX */
		 #fxZoom {
			left: 0px;
            position: relative;
            -webkit-transform: translateZ(0);
			width: 500px;
            height: 250px;
        }

        #fxZoom img {
			/* Force the image to 50% */
			-moz-transform:scale(0.5);
    		-webkit-transform:scale(0.5);
    		transform:scale(0.5);
        }
		
		/* FancyBox Thumnails  */
		.thumbnail {
			position: relative;
			<cfif darkTheme>/* Darkent the image for dark themes */
			filter: brightness(90%);</cfif>
			width: 225px;
			height: 128px;
			padding: 5px;
			padding-top: 5px;
			padding-left: 5px;
			padding-right: 5px;
			padding-bottom: 5px;
			box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2), 0 4px 8px 0 rgba(0, 0, 0, 0.19);
			overflow: hidden;
		}
		.thumbnail img {
			position: absolute;
			left: 50%;
			top: 50%;
			height: 100%;
			width: auto;
			-webkit-transform: translate(-50%,-50%);
			  -ms-transform: translate(-50%,-50%);
				  transform: translate(-50%,-50%);
		}
	</style>
	
<cfelse>
	<cfmodule template="#customBlogContentCssTemplate#" />
</cfif>
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Top menu html
	//***************************************************************************************************************************************************--->
	</cfsilent>
<cfif customTopMenuHtmlTemplate eq "">
	<header>
	<!--- This container will be displayed when the user scrolls down past the header. It is intended to allow for navigation when the user is down the page.--->
	<div id="fixedNavHeader">
		<cfif customTopMenuJsTemplate eq "">
			<cfset divName = "fixedNavHeader">
			<cfinclude template="includes/layers/topMenu.cfm">
		<cfelse>
			<cfmodule template="#customTopMenuJsTemplate#" />
		</cfif>	
	</div>
	<cfif session.isMobile>
		<table id="headerContainer" cellpadding="0" cellspacing="0" background="<cfoutput>#headerBackgroundImage#</cfoutput>" align="center" class="flexHeader">
		  <tr>
			<td>
			<!-- Inner table. The width setting in the topMenu css will set the overall width of the table. If the alignment is off, adjust the setting. -->
			<table id="topWrapper" name="topWrapper" cellpadding="0" cellspacing="0" border="0" align="<cfoutput>#topMenuAlign#</cfoutput>" valign="bottom">
				<tr valign="middle">
					<td id="logo" name="logo" valign="middle" width="<cfoutput>#logoMobileWidth#</cfoutput>">
						<!---elimnate hardcoded width below. change logo to around 80 to 120px. maybe make new row.--->
						<cfoutput><img src="#logoSourcePath#" style="padding-left: 10px;" align="left" valign="center" /></cfoutput>
					</td>
					<td id="blogNameContainer">
						<cfoutput>#htmlEditFormat(application.blog.getProperty("blogTitle"))#</cfoutput>
					</td>
				</tr>
				<tr>
					<td id="topMenuContainer" colspan="2"><!-- Holds the menu. -->
					  <ul id="topMenu">
						<cfsilent>
						<!---//**************************************************************************************************************************************************
									Top menu javascript (controls the menu at the top of the page)
						//***************************************************************************************************************************************************--->
						</cfsilent>
						<cfif customTopMenuJsTemplate eq "">
							<cfset divName = "topMenu">
							<cfinclude template="includes/layers/topMenu.cfm">
							<!---<span id="siteSearchButton" class="k-icon k-i-search" style="padding-left: 10px; color: whitesmoke;" onclick="createSearchWindow();"></span>--->
						<cfelse>
							<cfmodule template="#customTopMenuJsTemplate#" />
						</cfif>	
					  </ul>
					</td>
			  </tr>
			</table>
			</td>
		  </tr>
		  <tr>
			<td height="2px" background="<cfoutput>#headerBodyDividerImage#</cfoutput>"></td>
		  </tr>
		</table>
	<cfelse><!---<cfif session.isMobile>--->
		<table id="headerContainer" cellpadding="0" cellspacing="0" background="<cfoutput>#headerBackgroundImage#</cfoutput>" align="center" class="flexHeader">
		  <tr>
			<td>
			<!-- Inner table. The width setting in the topMenu css will set the overall width of the table. If the alignment is off, adjust the setting. -->
			<table id="topWrapper" name="topWrapper" cellpadding="0" cellspacing="0" border="0" align="<cfoutput>#topMenuAlign#</cfoutput>">
				<!-- If you want the blog title lower, increase the tr height below and decrease the tr height in the *next* row to keep everything aligned. -->
				<tr height="50px;" valign="bottom">
					<!-- Give sufficient room for a logo. This row will bleed into the next row (rowspan="2") -->
					<td id="logo" name="logo"  valign="middle" rowspan="2">
						<!---elimnate hardcoded width below. change logo to around 80 to 120px. maybe make new row.--->
						<cfoutput><img src="#logoSourcePath#" style="padding-left: 20px;" align="left" valign="center" /></cfoutput>
					</td>
					<td id="blogNameContainer">
						<cfoutput>#htmlEditFormat(application.blog.getProperty("blogTitle"))#</cfoutput>
					</td>
				</tr>
				<tr>
				  <td id="topMenuContainer" height="55px"><!-- Holds the menu. -->
					  <ul id="topMenu">
						<cfsilent>
						<!---//**************************************************************************************************************************************************
									Top menu javascript (controls the menu at the top of the page)
						//***************************************************************************************************************************************************--->
						</cfsilent>
						<cfif customTopMenuJsTemplate eq "">
							<cfset divName = "topMenu">
							<cfinclude template="includes/layers/topMenu.cfm">
						<cfelse>
							<cfmodule template="#customTopMenuJsTemplate#" />
						</cfif>	
					  </ul>
				 </td>
			  </tr>
			</table>
			</td>
			<td>
			</td>
		  </tr>
		  <tr>
			<td height="2px" background="<cfoutput>#headerBodyDividerImage#</cfoutput>"></td>
		  </tr>
		</table>
	</cfif><!---<cfif session.isMobile>--->
	</header>
		
<cfelse>
	<cfmodule template="#customTopMenuHtmlTemplate#" />
</cfif>
	<!-- End header -->
	
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Javascripts for the blog's Kendo widgets and UI interactions.
	//***************************************************************************************************************************************************--->
	</cfsilent>
	
<cfif customBlogJsContentTemplate eq "">
	<script>	
		//**************************************************************************************************************************************************
		// Kendo window scripts
		//**************************************************************************************************************************************************
		
		// About window -----------------------------------------------------------------------------------------------------------------------------------
		// Search window script
		function createAboutWindow(Id) {

			// Remove the window if it already exists
			if ($("#aboutWindow").length > 0) {
				$("#aboutWindow").parent().remove();
			}
			
			// Set the window title
			if (Id == 1){
				var windowTitle = "About <cfoutput>#htmlEditFormat(application.blog.getProperty('blogTitle'))#</cfoutput>";
			} else if (Id == 2){
				var windowTitle = "About Gregory Alexander";//TODO put in an owner name in the admin section.
			} else if (Id == 3){
				var windowTitle = "Download Gregory's Blog";
			}

			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="aboutWindow"></div>');
			$('#aboutWindow').kendoWindow({
				title: windowTitle,
				// The search window can't be set to full screen per design.
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: true,
				draggable: true,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: '85%',// We must leave room if the user wants to select a bunch of categories.
				iframe: false, // Don't use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/about.cfm?aboutWhat=" + Id,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$('#aboutWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
						  
		}//..function createAboutWindow(Id) {

		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeAboutWindow(){
			$("#aboutWindow").kendoWindow();
			var aboutWindow = $("#aboutWindow").data("kendoWindow");
			setTimeout(function() {
			  aboutWindow.destroy();
			}, 500);
		}
		
		// Search window -----------------------------------------------------------------------------------------------------------------------------------
		// Search window script
		function createSearchWindow() {

			// Remove the window if it already exists
			if ($("#searchWindow").length > 0) {
				$("#searchWindow").parent().remove();
			}

			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="searchWindow"></div>');
			$('#searchWindow').kendoWindow({
				title: "Search",
				// The search window can't be set to full screen per design.
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: true,
				draggable: true,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: '315px',// We must leave room if the user wants to select a bunch of categories.
				iframe: false, // Don't use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/search.cfm",// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$('#searchWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
						  
		}//..function searchWindow(Id) {

		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeSearchWindow(){
			$("#searchWindow").kendoWindow();
			var addCommentWindow = $("#searchWindow").data("kendoWindow");
			setTimeout(function() {
			  searchWindow.destroy();
			}, 500);
		}

		// Search Results Window. This will be placed underneath the search window.  -------------------------------------------------------------------------
		// Seaarch results script
		function createSearchResultWindow(searchTerm, category, startRow) {

			// Remove the window if it already exists
			if ($("#searchResultsWindow").length > 0) {
				$("#searchResultsWindow").parent().remove();
			}

			$(document.body).append('<div id="searchResultsWindow"></div>');
			$('#searchResultsWindow').kendoWindow({
				title: "Search Results",
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: true,
				draggable: true,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: "85%",
				iframe: false, // Don't use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/searchResults.cfm?searchTerm=" + searchTerm + "&category=" + category,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					closeSearchResultsWindow();
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
		}

		// Script to close the window using a button at the end of the page.
		function closeSearchResultsWindow(){
			try {
				$("#searchResultsWindow").kendoWindow();
				var searchResultsWindow = $("#searchResultsWindow").data("kendoWindow");
				searchResultsWindow.close();
			} catch(e) {
				error = 'window no longer initialized';
			}
		}

		// Add comment window ---------------------------------------------------------------------------------------------------------------------------------
		function createAddCommentSubscribeWindow(Id, uiElement, isMobile) {

			// Remove the window if it already exists
			if ($("#addCommentWindow").length > 0) {
				$("#addCommentWindow").parent().remove();
			}

			// Set uiElement vars
			if (uiElement == 'addComment'){
				if (isMobile){
					var windowHeight = '95%'
					var windowTitle = 'Add Comment';
				} else {  
					var windowHeight = '65%'
					var windowTitle = 'Add Comment';
				}
			} else if (uiElement == 'subscribe') {
				if (isMobile){
					var windowHeight = '60%'
					var windowTitle = 'Subscribe';
				} else {
					var windowHeight = '35%'
					var windowTitle = 'Subscribe';
				}
			} else if (uiElement == 'contact') {
				if (isMobile){
					var windowHeight = '95%'
					var windowTitle = 'Contact';
				} else {
					var windowHeight = '65%'
					var windowTitle = 'Contact';
				}
			}

			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="addCommentWindow"></div>');
			$('#addCommentWindow').kendoWindow({
				title: windowTitle,
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: <cfif session.isMobile>false<cfelse>true</cfif>,
				draggable: <cfif session.isMobile>false<cfelse>true</cfif>,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: windowHeight,
				iframe: false, // Don't use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>/addCommentSubscribe.cfm?id=" + Id + '&uiElement=' + uiElement,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$('#addCommentWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
		}//..function createAddCommentSubscribeWindow(Id, uiElement, isMobile) {
		
		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeAddCommentSubscribeWindow(){
			$("#addCommentWindow").kendoWindow();
			var addCommentWindow = $("#addCommentWindow").data("kendoWindow");
			setTimeout(function() {
			  addCommentWindow.destroy();
			}, 500);
		}
		
		// Share media window ---------------------------------------------------------------------------------------------------------------------------------
		function createMediaShareWindow(Id) {

			// Remove the window if it already exists
			if ($("#mediaShareWindow").length > 0) {
				$("#mediaShareWindow").parent().remove();
			}

			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="mediaShareWindow"></div>');
			$('#mediaShareWindow').kendoWindow({
				title: "Share post",
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: true,
				draggable: true,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: "66%",
				iframe: true, // We must use an iframe to include the addthis library. Don't use iframes unless absolutely necessary as is the case here.
				content: "<cfoutput>#application.baseUrl#</cfoutput>/addThis.cfm?id=" + Id,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
			<cfif session.isMobile>
				animation: {
					close: {
						effects: "slideIn:right",
						reverse: true,
						duration: 500
					},
				}
			<cfelse>
				close: function() {
					$('#mediaShareWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();// Center the window.
		}//..function createMediaShareWindow(Id) {
		<cfsilent>
		//*********************************************************************************************************************************************************
		// Listener scripts 
		// Scripts to listen to the URL to determine if we should perform any action after the page loads.
		//*********************************************************************************************************************************************************
		
		<!--- We are using this now to open the comments section when a recent comment entry was clicked. I want this to be elegant and seemless as possible to gently expand the comment section.
		Notes: Raymond (et-al) have developed a creative way to hide the URL properties. We are looking for a URL arg 'alias' containing 'Add-comment-interface', and we are getting the 'entry' URL argument as the entryID. --->
		</cfsilent>
		<cfif isDefined("URL.alias")>
		showComment(<cfoutput>'#URL.entry#'</cfoutput>);

		// When we show the comments, we need to change the down arrow to an up arrow, and expand the comments div.
		function showComment(entryId){
			// Get the name of the element that we want to change.
			openComment = setTimeout(function(){ 

				var spanElement = "#commentControl" + entryId;
				// Remove the down arrow.
				$(spanElement).removeClass("k-i-sort-desc-sm").addClass('k-i-sort-asc-sm');
				// Add the up arrow.
				$(spanElement).addClass("k-i-sort-asc-sm").addClass('k-i-sort-asc-sm');
				// Expand the table. See 'fx effects' on the Terlik website.
				kendo.fx($("#comment" + entryId)).expand("vertical").play();
			}, 500);

			// Get the URL fragment in the url. The fragment is the id of the comment.
			var commentIdInUrlFragment = window.location.hash;
			// Remove the pound sign in the fragment. 
			var commentId = commentIdInUrlFragment.replace('#','');
			// If the commentId is found in the URL fragment...
			if (commentId != '') {
				// After the comment section has opened, scroll to the anchor 
				// Scroll to the anchor. We are using a helper function below. The functions args are: anchorScroll(fromObj, toObj, animateSpeed)
				scrollToComment = setTimeout(function(){ 
					//anchorScroll($("html, body"), $("#addCommentButton"), 500);
					// Scroll to the comment location.
					anchorScroll($("html, body"), $("#" + commentId), 500);
				}, 1000);
			}//..if (commentId != '') {
		}//..function showComment(entryId){
		</cfif>
		
		<cfsilent>
			<!--- Used to confirm subscriptions. For some odd reason, spasmmers will hit this. --->
			<cfif isDefined("URL.confirmSubscription") and isDefined("URL.token")>
				<!--- See if the token in the dastabase matches the token send via email. --->
				<cfset subscribed = application.blog.confirmSubscriptionViaToken(url.token)>
		<cfelse>
				<cfset subscribed = false>
		</cfif>
		</cfsilent>
	<cfif subscribed>
		// Subscription confirmation logic.
		$.when(kendo.ui.ExtAlertDialog.show({ title: "<cfoutput>#getResourceBundle('subscribeconfirm')#", message: "#getResourceBundle('subscribeconfirmbody')#</cfoutput>", icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
			).done(function () {
			// Do nothing
		});
	</cfif>
						  
		<cfsilent>
		//*********************************************************************************************************************************************************
		// Contact form. We want to resuse this contact form for other purposes, so for now, we are using the URL to let the application know to open up the contact form, which is the same form used for adding comments and to subscribe. 
		//*********************************************************************************************************************************************************
		<cfif isDefined("URL.contact")>
			<cfset openContactForm = true>
		<cfelse>
			<cfset openContactForm = false>
		</cfif>
		</cfsilent>
		<cfif openContactForm>
		// Open up the contact form.
		createAddCommentSubscribeWindow('', 'contact', <cfoutput>#session.isMobile#</cfoutput>);
		</cfif>
		<cfsilent>				  
		//*********************************************************************************************************************************************************
		// Search template 
		//*********************************************************************************************************************************************************
		</cfsilent>
		<cfif isDefined("URL.searchBlog")>
			createSearchWindow();
		</cfif>			  
		<cfsilent>
		//*********************************************************************************************************************************************************
		// About template 
		//*********************************************************************************************************************************************************
		</cfsilent>
		<cfif isDefined("URL.aboutBlog")>
			createAboutWindow(1);
		</cfif>
		<cfif isDefined("URL.aboutMe")><!---TODO put in blog owner in admin interface.--->
			createAboutWindow(2);
		</cfif>
		// End listeners.
						  
		//*********************************************************************************************************************************************************
		// Ajax functions 
		//*********************************************************************************************************************************************************

		// Captcha ------------------------------------------------------------------------------------------------------------------------------------------------
		// This function is used by multiple templates, including the add comments and subscribe interfaces.
		function checkCaptcha(captchaText, captchaHash){
			// Submit form via AJAX.
			$.ajax(
				{
					type: "get",
					url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=validateCaptcha",
					data: {
						captchaText: captchaText,
						captchaHash: captchaHash
					},
					dataType: "json",
					cache: false,
					success: function(data) {
						setTimeout(function () {
							checkCaptchaResult(data);
						// Setting this lower than 500 causes some issues.
						}, 500);
					}
				}
			);
		}//..function checkCaptcha(captchaText, captchaHash){

		// Post Comment ----------------------------------------------------------------------------------------------------------------------------------------------
		// Invoked via the addCommentSubscribe.cfm kenow window after Kendo validation occurs.
		function postCommentSubscribe(entryId, uiInterface){
			//alert(uiInterface);
			// Note: the subscribe functionality uses the same logic as postComment with an empty comment and a comment only flag.
			// Get the value of the forms
			var entryTitle = $( "#entryTitle" ).val();
			var uiInterface = uiInterface;
			var commenterName = $( "#commenterName" ).val();
			var commenterEmail = $( "#commenterEmail" ).val();
			var commenterWebSite = $( "#commenterWebSite" ).val();
			var comments = $( "#comments" ).val();
			<cfif application.useCaptcha and not isLoggedIn()>
			var captchaText = $( "#captchaText" ).val();
			var captchaHash = $( "#captchaHash" ).val();
			</cfif>
			var rememberMe = $('#rememberMe').is(':checked')
			var subscribe = $('#subscribe').is(':checked')  // checkbox boolean value.

			// Handle specific uiInteface arguments
			if (uiInterface == 'addComment'){
				windowName = "addCommentWindow";
				pleaseWaitMessage = "Posting comment.";
			} else if (uiInterface == 'subscribe'){
				windowName = "addCommentSubWindow";
				pleaseWaitMessage = "Subscribing.";
			} else if (uiInterface == 'contact'){
				windowName = "contactWindow";
				pleaseWaitMessage = "Sending.";
			}

			// Submit form via AJAX.
			$.ajax({
				type: 'post', 
				// This posts to the proxy controller as it needs to have session vars and performs client side operations.
				url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=postCommentSubscribe",
				data: {
					entryId: entryId,
					uiInterface: uiInterface,
					entryTitle: entryTitle,
					commenterName: commenterName,
					commenterEmail: commenterEmail,
					commenterWebSite: commenterWebSite,
					comments: comments,
					<cfif application.useCaptcha and not isLoggedIn()>
					captchaText: captchaText,
					captchaHash: captchaHash,
					</cfif>
					subscribe: subscribe,
					rememberMe: rememberMe
				},//..data: {
				dataType: "json",
				cache: false,
				success: function(data) {
					// Note: allow around 1/4 of a second before posting.
					setTimeout(function () {
						postCommentSubscribeResponse(data, uiInterface);
					}, 250);//..setTimeout(function () {
				}//..success: function(data) {
			});//..$.ajax({

			// Open the plese wait window. Note: the ExtWaitDialog's are based upon an open source project and not a part of the Kendo official library. I prefer this design over Kendo's dialog offerings. I have extended this library with some of my own designs.
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: pleaseWaitMessage, icon: "k-ext-information" }));
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 2000);
			// Return false in order to prevent any potential redirection.
			return false;
		}//..function postCommentSubscribe(entryId, uiInterface){

		function postCommentSubscribeResponse(response, uiInterface){
			//alert(uiInterface);
			// Extract the data in the response.
			// General vars	
			var entryId = response.entryId;
			var sucess = response.sucess;
			// Error vars
			var validName = response.validName;
			var validEmail = response.validEmail;
			var validWebsite = response.validWebsite;
			var validComment = response.validComment;
			var errorMessage = response.errorMessage;
			// Database vars (placeholder for the next version).
			var dbSuccess = response.dbSuccess;
			var dbErrorMessage = response.dbErrorMessage;

			// Catch errors
			if (!sucess){
				// Set the error message
				var errorMessage = 'Errors were found.';
				if (!validName){
					var errorMessage = errorMessage + ' Name is required<br/>.';
				}
				if (!validEmail){
					var errorMessage = errorMessage + ' Valid email is required.<br/>';
				}
				if (!validWebsite){
					var errorMessage = errorMessage + ' Website URL is not valid.<br/>';
				}
				if (!validWebsite){
					var errorMessage = errorMessage + ' Comment required.<br/>';
				}
				if (!errorMessage){
					var errorMessage = errorMessage + ' ' + errorMessage + '<br/>';
				}
				// Raise the error message.
				$.when(kendo.ui.ExtAlertDialog.show({ title: "Errors were found.", message: errorMessage, icon: "k-ext-error", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>" }) // or k-ext-error, k-ext-information, k-ext-question, k-ext-warning.  You can also specify height.
					).done(function () {
					// Do nothing
				});		
			// Display a success message.	
			} else { 
				// Create the success message.
				var moderateComments = <cfoutput>'application.commentmoderation'</cfoutput>; 
				if (uiInterface == 'addComment'){
					if (moderateComments){
						var successMessage = 'Your comment has been sent to the administrator for approval.';
					} else  {
						var successMessage = 'Your comment has been posted.';
					}
				} else if (uiInterface == 'addComment'){
					var successMessage = 'You are now subscribed to this thread.';
				} else if (uiInterface == 'contact'){
					var successMessage = 'Your message was sent.';
				}
				// Raise the message.
				$.when(kendo.ui.ExtWaitDialog.show({ title: "Sucess.", message: successMessage, icon: "k-ext-information" }));
				// Use a quick set timeout in order for the data to load.
				setTimeout(function() {
					// Close the success message window.
					kendo.ui.ExtWaitDialog.hide();
					// Close the window
					closeAddCommentSubscribeWindow();
				}, 2000);
			}
		}//..function postCommentSubscribeResponse(response, uiInterface){
						  
		// Subscribe to the blog.  ----------------------------------------------------------------------------------------------------------------------------------------------
		// Invoked via the addCommentSubscribe.cfm kenow window after Kendo validation occurs.
		function subscribeToBlog(){
			
			// Get the email address that was typed in.
			var email = $( "#subscriberEmail" ).val();
			// alert(email);
			// Submit form via AJAX.
			$.ajax({
				type: 'post', 
				// This posts to the proxy controller as it needs to have session vars and performs client side operations.
				url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=subscribe",
				data: {
					email: email
				},//..data: {
				dataType: "json",
				cache: false,
				success: function(data) {
					setTimeout(function () {
						subscribeResponse(data);
					}, 500);//..setTimeout(function () {
				}//..success: function(data) {
			});//..$.ajax({

			// Open the plese wait window. Note: the ExtWaitDialog's are based upon an open source project and not a part of the Kendo official library. I prefer this design over Kendo's dialog offerings. I have extended this library with some of my own designs.
			$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Please wait", icon: "k-ext-information" }));
			// Use a quick set timeout in order for the data to load.
			setTimeout(function() {
				// Close the wait window that was launched in the calling function.
				kendo.ui.ExtWaitDialog.hide();
			}, 500);
			// Return false in order to prevent any potential redirection.
			return false;
		}//..function subscribeToBlog(email){
						  
		function subscribeResponse(response){
			//alert(uiInterface);
			// Extract the data in the response.
			var message = response.message;
			// Display it.			  
			$.when(kendo.ui.ExtAlertDialog.show({ title: "Subscribe", message: message, icon: "k-ext-information", width: "<cfoutput>#application.kendoExtendedUiWindowWidth#</cfoutput>", height: "215px"}));
		}
						  
		//****************************************************************************************************************************************************************
		// Helper functions 
		//****************************************************************************************************************************************************************

		// Used to scroll to a particular comment.
		function anchorScroll(fromObj, toObj, animateSpeed) {
			var fromOffset = fromObj.offset();
			var toOffset = toObj.offset();
			var offsetDiff = Math.abs(toObj.top - fromObj.top);

			var speed = (offsetDiff * animateSpeed) / 1000;
			$("html,body").animate({
				scrollTop: toOffset.top
			}, animateSpeed);
		}//..function anchorScroll(fromObj, toObj, animateSpeed) {

		//****************************************************************************************************************************************************************
		// Widget UI settings 
		//****************************************************************************************************************************************************************

		// Document read block. Note: functions inside will not be available.
		$(document).ready(function() {

			// Script that will allow us to expand the post containers to allow the user to see the comments.
			// Expand the routing details
			// When the ascending arrow is clicked on...
			$(".flexParent").on("click", "span.k-i-sort-desc-sm", function(e) {		  
				// We need to get the associated entryId to properly expand the right containter. Here, we will get the id of this emement. It should be commentControl + entryId. 
				var clickedSpan = $(this).attr('id');
				// Remove the 'commentControl' string from the id to just get the Id.
				var entryId = clickedSpan.replace("commentControl", "");
				// The content element's id will be 'comment' + entryId 
				var contentElement = 'comment' + entryId;
				// Change the class of the span (ie change the arrow direction), and expand the table.
				$(e.target)
					.removeClass("k-i-sort-desc-sm")
					.addClass("k-i-sort-asc-sm");
					// Expand the table. See 'fx effects' on the Terlik website.
					kendo.fx($("#" + contentElement)).expand("vertical").play();
			});

			// Collapse the widget. 
			// When the ascending arrow is clicked on...
			$(".flexParent").on("click", "span.k-i-sort-asc-sm", function(e) {
				// We need to get the associated entryId to properly expand the right containter. Here, we will get the id of this emement. It should be commentControl + entryId. 
				var clickedSpan = $(this).attr('id');
				// Remove the 'commentControl' string from the id to just get the Id.
				var entryId = clickedSpan.replace("commentControl", "");
				// The content element's id will be 'comment' + entryId
				var contentElement = 'comment' + entryId;
				// Change the class of the span (ie change the arrow direction), and shrink the table. I am doing this as I don't want to have to traverse the dom and write a bug.
				$(e.target)
					.removeClass("k-i-sort-asc-sm")
					.addClass("k-i-sort-desc-sm");
					// 'reverse' the table. See 'fx effects' on the Terlik website.
					kendo.fx($("#" + contentElement)).expand("vertical").stop().reverse();
			});
						  
			/* Kendo FX */
			/* To place an expading image into the blog content with an entry, use the following code in the entry editor:
			<div id="fxZoom">
				<img src="../../blog/doc/settings/adminUserLink.png" />
			</div>
			*/
			$("#fxZoom img").hover(function() {
				kendo.fx(this).zoom("in").startValue(.5).endValue(1).play();
			}, function() {
				kendo.fx(this).zoom("out").endValue(.5).startValue(1).play();
			});
			
		});//..document ready

	</script>
	<!---End windows (ga 10/27/2018)--->
	
	<!--- Fancybox custom script. This is used to place expanding thumnail images that take up very little space within the blog content. Use the following example and type this into the blog entry editor (in the admin section):
	<a class="fancybox-effects" href="/blog/doc/addThis/2addNewTool.png" data-fancybox-group="steps12" title="Add New Tool"><img src="/blog/doc/addThis/2addNewToolThumb.png" alt="" /></a>
	I may build this functionality in with a new editor (one of these years...).
	--->
	<script type="text/javascript">
		$(document).ready(function() {
			
			// Load fancyBox */
			$('.fancybox').fancybox();

			// Set fancybox custom properties (I am over-riding basic functionality).
			$(".fancybox-effects").fancybox({
				wrapCSS    : 'fancybox-custom', //ga
				padding: 5,
				openEffect : 'elastic',
				openSpeed  : 150,
				closeEffect : 'elastic',
				closeSpeed  : 150,
				closeClick : false,
				helpers : {
					title : {
						 type: 'outside'
					},
					overlay : null
				}
			});

			$('.fancybox-media')
			.attr('rel', 'media-gallery')
			.fancybox({
				openEffect : 'none',
				closeEffect : 'none',
				prevEffect : 'none',
				nextEffect : 'none',
				arrows : false,
				helpers : {
					media : {},
					buttons : {}
				}
			});

		});//..document.ready
	</script>
	
	<style>
		<style type="text/css">
		/* Custom css script (I am keeping both the script and the css together here for simplicity). */
		/* FancyBox */
		.fancybox-effects img {
			border: 1px solid #808080; /* Gray border */
			border-radius: 3px;  /* Rounded border */
			padding: 5px; 
		}

		/* Add a hover effect (blue shadow) */
		.fancybox-effects img:hover {
		  	box-shadow: 0 0 2px 1px rgba(0, 140, 186, 0.5);
			opacity: .82;
		}
				
		.fancybox-custom .fancybox-skin {
			box-shadow: 0 0 25px #808080;/*b4b6ba*/
			border-radius: 5px;
		}
		
		.fancybox-custom .fancybox-skin {
			box-shadow: 0 0 25px #808080;/*b4b6ba*/
			border-radius: 5px;
		}

		body {
			margin: 0 auto;
		}
	</style>
	</style>
<cfelse>
	<cfmodule template="#customBlogJsContentTemplate#" />
</cfif>
	
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Blog content html
	//***************************************************************************************************************************************************--->
	</cfsilent>
						
	<!-- Blog body -->
<cfif customBlogContentHtmlTemplate eq "">
	<!--  Outer container. This container controls the blog width. The 'k-alt' class is used when there are alternating rows and you want to differentiate them. Typically, it is a darker color that 'k-content'. We will set the min width of the container to be 968 pixels and the min width of the blog content to be 640 pixels. This should give approximately 300 miniumum pixels to the side bar on the right. . -->
	<div id="mainBlog" class="k-alt">
		
		<!--- Forms that hold state. --->
		<!---This is the sidebar responsive navigation panel that is triggered when the screen gets to a certain size. It is a duplidate of the sidebar div above, however, I can't properly style the sidebar the way that I want to within the blog content, so it is duplicated withoout the styles here. --->
		<input type="hidden" id="sidebarPanelState" name="sidebarPanelState" value="initial"/>
		
		<div id="mainPanel" class="flexParent">
			<cfsilent>
			<!--- 
			Wide div in the center left of page.
			Note: this is the div that will be refreshed when new entries are made. All of the dynamic elements within this div 
			are refreshed when there are new posts, however, any logic *outside* of this div are not refreshed- so we need to get the query, and supply the arguments.
			--->
			</cfsilent>
			<div id="blogContent">
				<cfsilent><!--- Loop thru the articles. ---></cfsilent>
				<cfset lastDate = "">
				<cfoutput query="articles">
               		<cfsilent><!---Set the entryId. We will use this to identify the rows.---></cfsilent>
                	<cfset entryid = id>
					<div id="blogPost" class="widget k-content">
						<span id="innerContentContainer">
							<h3 class="topContent">
								<a href="#application.blog.makeLink(id)#" class="k-content">#title#</a>
							</h3>

							<p class="postDate">
								<!-- We are using Kendo's 'k-primary' class to render the primary accent color background. The primay color is set by the theme that is declared. -->
								<span class="month k-primary">#dateFormat(posted, "mmm")#</span>
								<span class="day k-alt">#day(posted)#</span>
							</p>

							<p class="postAuthor">
								<span class="info">
									<cfif len(name)>by <a href="#application.blog.makeUserLink(name)#" class="k-content">#name#</a></cfif> 
									<cfset lastid = listLast(structKeyList(categories))>
									<cfloop item="catid" collection="#categories#">
									<a href="#application.blog.makeCategoryLink(catid)#" class="k-content">#categories[currentRow][catid]#</a><cfif catid is not lastid>, </cfif>
									</cfloop>
								</span>
							</p>

							<!-- Post content --> 
							<span id="postContent">		
							<!--- Only constrain the blog body on mobile. --->
							<cfif session.isMobile>
								#application.blog.renderEntry(body,false,enclosure)#
							<cfelse><!---<cfif session.isMobile>--->
								<!--- Blog post (Don't use the constrainer table here- it causes problems. --->
								#application.blog.renderEntry(body,false,enclosure)#
							</cfif><!---<cfif session.isMobile>--->
								
							<!--- Handle any posts that have the content broken into two sections written in the entry editor using the '</more>' tag. This is a neat feature allows the administrator to condense the entry for the front page and create a link to the full post. --->
							<cfif len(morebody) and url.mode is not "entry">
								<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="location.href='#application.blog.makeLink(id)###more';">
									<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
									<i class="fas fa-chevron-circle-down" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;More...
								</button>
							<!---We are looking at the actual post.--->
							<cfelseif len(morebody)>
								#application.blog.renderEntry(morebody)#
							</cfif>
							</span><!--<span id="postContent">-->

							<!---***************************************************************** Media *****************************************************************--->
							<!--- HTML5 supported media will be handled by the jQjuery Kendo video player. Supported formats are mp4, ogv, and webm. Note: the Kendo media player is only availabe in the proffesional edition. --->
							<cfif application.kendoCommercial and (enclosure contains ".mp4" or enclosure contains ".ogv" or enclosure contains ".webm")>
								<div class="k-content wide">
									<div id="mediaplayer#currentRow#" class="mediaPlayer"></div>
									<script>
										$(document).ready(function () {

											$("#chr(35)#mediaplayer#currentRow#").kendoMediaPlayer({
												autoPlay: false,
												navigatable: true,
												media: {
													title: "#title#",
													source: "#application.baseUrl#/enclosures/#getFileFromPath(enclosure)#"
												}
											});
										});
									</script>
								</div><!---<div class="k-content">--->
							</cfif>
							
							<!--- MP3'S will be handled by Flash. This code is intact from the original BlogCfc. --->
							<cfif enclosure contains "mp3">
								<cfset alternative=replace(getFileFromPath(enclosure),".mp3","") />
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
										flashvars.soundFile= "#application.rooturl#/enclosures/#getFileFromPath(enclosure)#";
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

							<p class="bottomContent">
								<!-- Button navigation. -->
								<!-- Set a smaller font in the kendo buttons. Note: adjusting the .k-button class alone also adjusts the k-input in the multi-select so we will set it here.-->
								<button id="addCommentButton" class="k-button" style="#kendoButtonStyle#" onClick="createAddCommentSubscribeWindow('#id#', 'addComment', #session.isMobile#)">
									<i class="fas fa-comments" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Comment
								</button>
								
								<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="createAddCommentSubscribeWindow('#id#', 'subscribe', #session.isMobile#)">
									<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
									<i class="fas fa-envelope-open-text" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Subscribe
								</button>

								<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="createMediaShareWindow('#id#');">
									<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
									<i class="fas fa-share" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Share
								</button>
										
								<!-- The print button is not needed for mobile.-->
								<cfif not session.isMobile>
								<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="location.href='#application.rooturl#/print.cfm?id=#id#';">
									<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
									<i class="fas fa-print" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Print
								</button>
								</cfif><!---<cfif not session.isMobile>--->
										
								<p></p>This entry was posted on #dateFormat(posted, "mmmm d, yyyy")# at #timeFormat(posted, "h:mm tt")# and has received #views# views. </p>
								There are currently <cfif commentCount is "">0<cfelse>#commentCount#</cfif> comments. 
								<cfif len(enclosure)><a href="#application.rooturl#/enclosures/#urlEncodedFormat(getFileFromPath(enclosure))#" class="k-content">Download attachment.</a></cfif>
								<!--- Span to hold the little arrow. Note: the order of the spans in the code are different than the actual display. We need to reverse the order for proper display. We are not going to display this if there are no comments. --->
								<cfif len(commentCount) gt 0><span id="commentControl#entryId#" class="collapse k-icon k-i-sort-desc-sm"></span>&nbsp;&nbsp;Show Comments</cfif>
							</p> 
							
							<cfsilent>
							<!--- ***********************************************************************************************************
								Comments interface.
							*************************************************************************************************************--->
							</cfsilent>
						<cfif len(commentCount) gt 0>
							<!-- Comments that are shown when the user clicks on the arrow button to open the container. -->
							<div id="comment#entryId#" class="widget k-content" style="display:none;">
								<h3 class="topContent">Comments</h3>          

								<table cellpadding="3" cellspacing="0" border="0" class="fixedCommentTable">
								 <tr width="100%">
								 <cftry>
								 <cfset comments = application.blog.getComments(id)>
								 <cfloop query="comments">
								 <!---Note: the URL is appended with an extra 'c' in front of the commentId.--->
								 <tr id="c#id#" name="" class="<cfif currentRow mod 2>k-content<cfelse>k-alt</cfif>">
								  <td class="fixedCommentTableContent">
									 <a class="comment-id" href="#application.blog.makeLink(entryid)###c#id#" class="k-content">###currentRow#</a> by <b>
									 <cfif len(comments.website)>
										<a href="#comments.website#" rel="nofollow">#name#</a>
									 <cfelse>
										#name#
									 </cfif></b> 
									 on #application.localeUtils.dateLocaleFormat(posted,"short")# - #application.localeUtils.timeLocaleFormat(posted)#</p>
								  </td>
								 <tr class="<cfif currentRow mod 2>k-content<cfelse>k-alt</cfif>">
									<td>
										<img src="http://www.gravatar.com/avatar/#lcase(hash(lcase(email)))#?s=64&amp;r=pg&amp;d=#application.rooturl#/images/defaultAvatar.gif" title="#name#'s Gravatar" border="0" class="avatar avatar-64 photo" height="64" width="64" align="left" style="padding: 5px"/>
										#paragraphFormat2(replaceLinks(comment))#
									</td>
								 </tr>
								 <!---If the number of records is even, create the bottom border.--->
							 <cfif comments.recordcount mod 2 is 0>
								 <tr class="<cfif currentRow mod 2>k-alt<cfelse>k-content</cfif>">
									<td class="border"></td>
								 </tr>
							 </cfif>
								 </cfloop>
								 <cfcatch type="any">
									<tr>
										<td>
											#cfcatch.detail#
										</td>
									</tr>
								 </cfcatch>
								 </cftry>
								</table>
							</div><!---<div id="comment#entryId#" class="widget k-content" style="display:none;">--->
						</cfif><!---<cfif len(commentCount) gt 0>--->
						<cfsilent>
						<!--- ***********************************************************************************************************
							Related entries
						*************************************************************************************************************--->
						</cfsilent>
						<cfset qRelatedBlogEntries = application.blog.getRelatedBlogEntries(entryId=id,bDislayFutureLinks=true) />	
						<cfif qRelatedBlogEntries.recordCount>
							<div id="relatedentries">
							<h3 class="topContent">Related Entries</h3>
							<ul id="relatedEntriesList">
							<cfloop query="qRelatedBlogEntries">
							<li><a href="#application.blog.makeLink(entryId=qRelatedBlogEntries.id)#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#qRelatedBlogEntries.title#</a></li>
							</cfloop>			
							</ul>
							</div>
						</cfif>

						</span><!---<span id="innerContentContainer">--->
					</div><!---<div id="blogPost">--->
				</cfoutput><!---<cfoutput query="articles">--->
				<a href="#chr(35)#" id="pagerAnchor"></a>
				<cfsilent>
				<!--- ***********************************************************************************************************
					Pagination
				*************************************************************************************************************--->
				</cfsilent>
				<cfif (URL.startRow gt 1) or (articleData.totalEntries gte URL.startRow + application.maxEntries)>
					<cfsilent>
					<!--- Get the number of pages --->
					<cfset totalPages = ceiling(articleData.totalEntries/application.maxEntries)>
					<!--- Set links --->
					<!--- Get the path if not /index.cfm --->
					<cfset path = rereplace(cgi.path_info, "(.*?)/index.cfm", "")>
					<!--- Clean out startrow from query string --->
					<cfset queryString = cgi.query_string>
					<!--- Safety check. Handle: http://www.coldfusionjedi.com/forums/messages.cfm?threadid=4DF1ED1F-19B9-E658-9D12DBFBCA680CC6 --->
					<cfset queryString = reReplace(queryString, "<.*?>", "", "all")>
					<cfset queryString = reReplace(queryString, "[\<\>]", "", "all")>
					<cfset queryString = reReplaceNoCase(queryString, "&*startrow=[\-0-9]+", "")>
					<!--- Remove the page variable. This is hard coded in the datasource below. --->
					<cfset queryString = reReplaceNoCase(queryString, "&*page=[\-0-9]+", "")>
					<!--- If it is not already defined, preset the URL page var --->
					<cfif not isDefined("URL.page")>
						<cfset URL.page = 0>
					</cfif>
						
					<!---
					url.startRow: #url.startRow# application.maxEntries: #application.maxEntries# articleData.totalEntries: #articleData.totalEntries# lastPageQueryString: #lastPageQueryString# currentPage: #currentPage# totalPages: #totalPages# prevPageEnabled:#prevPageEnabled# nextPageEnabled:#nextPageEnabled#
					--->
					</cfsilent>
					<cfoutput>
						<div id="pager" data-role="pager" class="k-pager-wrap k-widget k-floatwrap k-pager-lg">
						<script>
							// Create the datasource with the URL
							var pagerDataSource = new kendo.data.DataSource({
							data: [<cfset thisStartRow = 0><!--- Loop through the pages. ---><cfloop from="1" to="#totalPages#" index="page"><cfset thisLink = queryString & "&startRow=" & thisStartRow & "&page=" & page>
								{ pagerUrl: "#thisLink#", page: "#page#" }<cfif page lt totalPages>,</cfif><cfset thisStartRow = thisStartRow + application.maxEntries></cfloop>
							],
								pageSize: 1,// Leave this at 1.
								page: #URL.page#
							});

							 var pager = $("#chr(35)#pager").kendoPager({
								dataSource: pagerDataSource,
								messages: {
								  display: "page {0} of {2}"
								},
								change: function() {
									onPagerChange(this.dataSource.data());//this.datasource.productName
								}
							}).data("kendoPager");

							pagerDataSource.read();

							function onPagerChange(data){
								// Get the current page of the pager. The method to extract the current page is 'page()'.
								var currentPage = pager.page();
								// We are going to get the data item held in the datasource using its zero index array, but first we need to subtract 1 from the page value.
								var index = currentPage-1;
								// Get the url that is stored in the datsource using our new index.
								var pagerUrl = "?" + data[index].pagerUrl;
								// Open the page.
								window.location.href = pagerUrl;
							}
						</script>
    					</div>
				
					</cfoutput>
				</cfif>
				
				<!--- ***************************** Logic to display content when no data is found (ie when a user clicks on the wrong date) *****************************--->
				<cfif articles.recordcount eq 0>
					<div id="blogPost" class="widget k-content" style="font-weight: bold;">
						<span id="innerContentContainer">
							<h3 class="topContent">
								No Entries
							</h3> 
							<span id="postContent">
							<cfif url.mode is "day">
								There are no entries for the selected dates. Please select a highlighted date in the calendar control.
								<!---Kind of a hack. Fill the div, otherwise the side content will push to the left (see float left comment near the top of the page.)--->
								&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
								&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
								&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
							<cfelse>
								<!--- Debugging --->
								<!---
								<cfset articleData = application.blog.getEntries(params, isLoggedIn())>
								<cfset articles = articleData.entries>
								<cfdump var="#params#">
								<cfdump var="#articleData#">
								--->
								<!--- This occurs when there is an error, or the blog is completely empty after installation. --->
								There are no blog entries.
							</cfif>
							<br/><br/>
							</span>
						</span><!---<span id="innerContentContainer">--->
					</div><!---<div id="blogPost">--->
				</cfif><!---<cfif articles.recordcount eq 0>--->

			</div><!---blogContent--->
			
			<!--- Side bar is to the right of the main panel container. It is also used as a responsive panel below when the screen size is small. --->
			<div id="sidebar">
				<!---Suppply the sideBarType argument before loading the side bar--->
				<cfset sideBarType = "div">
				<cfinclude template="includes/layers/sidebar.cfm">
			</div><!---<nav id="sidebar">--->
			
		</div><!---<div class="mainPanel hiddenOnNarrow">--->
		
	</div><!--- <div id="mainBlog"> --->					
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Sidebar panel
	//***************************************************************************************************************************************************--->
	</cfsilent>
						
	<!--- Side bar is to the right of the main panel container. It is also used as a responsive panel below when the screen size is small. --->
	<nav id="sidebarPanel" class="k-content">
		<div id="sidebarPanelWrapper" name="sidebarPanelWrapper" class="flexScroll">
			<!---Suppply the sideBarType argument before loading the side bar--->
			<cfset sideBarType = "panel">
			<cfinclude template="includes/layers/sidebar.cfm">
		</div>
	</nav><!---<nav id="sidebar">--->

	<!--- This script must be placed underneath the layer that is being used in order to effectively work as a flyout menu.--->
	<script>
		$("#sidebarPanel").kendoResponsivePanel({
			// On mobile devices, always achieve the breakpoint (50,000 pixels should do it!), otherwise, activate the panel at 1300 pixels. Note: in this implementation, if this screen size matches the breakpoint, the responsive panel is open by default which looks really odd. I am choosing a screen size that is not normal here, ie 1300.
			breakpoint: breakpoint,
			orientation: "left",
			autoClose: true,
			open: onSidebarOpen,
			close: onSidbarClose
		})
		//.on("click", "a", function(e) {
			//$("#sidebarPanel").kendoResponsivePanel("close");
		//});
		
		function onSidebarOpen(){
			// Change the value of the hidden input field to keep track of the state. We need some lag time and need to wait half of a second in order to allow the form to be changed, otherwise, we can't keep an accurate state and the panel will always think that the panel is closed and always open when you click on the button.
			setTimeout(function() {
			  $('#sidebarPanelState').val("open");
			}, 500);
		}
		// Event handler for close event
		function onSidbarClose(){
			// Change the value of the hidden input field to keep track of the state.
			setTimeout(function() {
			  $('#sidebarPanelState').val("closed");
			}, 500);
		};

		function getSidebarPanelState(){
			// Note: There is no way to automatically get the state, so I am toggling a hidden form with the state using the onSideBarOpen and close. Also, when the user clicks on the button the first time, there will be an error 'Uncaught TypeError: Cannot read property 'style' of undefined', so we will put this in a try block and iniitialize the panel if there is an error. 
			
			// The hidden sidebarPanelState form is set to initial on page load. We need to initialize the sidebarPanel css by setting the css to display: 'block'
			if ($('#sidebarPanelState').val() == 'initial'){
				// Set the display property to block. 
				$('#sidebarPanel').css('display', 'block');
				var sidebarPanelState = 'closed';
			} else if (($('#sidebarPanelState').val() == 'open')){
				var sidebarPanelState = 'open';
			} else if (($('#sidebarPanelState').val() == 'closed')){
				var sidebarPanelState = 'closed';
			} else {
				// Default state is closed (if anything goes wrong)
				var sidebarPanelState = 'closed';
			}
			return sidebarPanelState;
		}

		// Function to open the side bar panel. We need to have the name of the div that is consuming this in order to adjust the top padding.
		function toggleSideBarPanel(layer){
			if (layer == 1){// The topMenu element is invoking this method.
				// Set the margin (its different between mobile and desktop).
				if (isMobile){
					// The header is 105px for mobile.
					var marginTop = "105px";
				} else {
					// The header is 110 for desktop.
					var marginTop = "110px";
				}
				var marginTop = marginTop;

				// Set the css margin-top property. We want this underneath the calling menu.
				$('#sidebarPanel').css('margin-top', marginTop);
			} else if (layer == 2){// The fixed 'fixedNavHeader' element is invoking this method.
				// The height of the fixedMenu is 35 or 45 pixels depening upon device.
				// Set the margin (its different between mobile and desktop).
				if (isMobile){
					// The fixedNavHeader is 35 pixels for mobile. We'll add another 2px.
					var marginTop = "37px";
				} else {
					// We need to find out how far from the top we are to figure out how many pixes to drop the Kendo responsive panel down as we have scrolled away from the top of the screen.
					var pixelsToTop = window.pageYOffset || document.documentElement.scrollTop;
					// Add pixels to top to the height of the fixed nav header. The fixedNavHeader is 45 pixels for desktop. We are going to add 2px.
					var marginTop = (pixelsToTop + 47) + "px";
				}
				var marginTop = marginTop;
				// Set the margin-top css property. We want this underneath the calling menu.
				$('#sidebarPanel').css('margin-top', marginTop);
			}
			
			// Now that the padding is set, activate the sideBarPanel and open it.
			if (getSidebarPanelState() == 'open'){ 
					$("#sidebarPanel").kendoResponsivePanel("close");
			} else { //if ($('#sidebarPanel').css('display') == 'none'){ 
					$("#sidebarPanel").kendoResponsivePanel("open");
			}//if ($('#sidebarPanel').css('display') == 'none'){ 
		}

		// Important note: this is a workaround with a google chrome bug and mobile devices. 
		// This prevents the following error: "Intervention] Unable to preventDefault inside passive event listener due to target being treated as passive."
		// See https://github.com/telerik/kendo-ui-core/issues/3556
		$(".k-rpanel-toggle").on("touchstart", function(e) { 
			e.preventDefault();
		});
		
		$(".k-rpanel-toggle").on("touchend", function(e) { 
			e.preventDefault();
		});

		// This is only used on the desktop app for now.
		$(".k-rpanel-toggle").on("click", function(e) { 
			setTimeout(function() {
				toggleSideBarPanel('topMenu');
			}, 100);
		});

	</script>

	<div class="responsive-message"></div>
				
<cfelse>
	<cfmodule template="#customBlogContentHtmlTemplate#" />
</cfif>
			
<cfsilent>
<!---//**************************************************************************************************************************************************
			Footer
//***************************************************************************************************************************************************--->
</cfsilent>
<cfif customFooterHtmlTemplate eq "">
	<br/><br/><br/>
	<div id="footerDiv" name="footerDiv" class="k-content">
		<span id="footerInnerContainer">
			<img src="<cfoutput>#application.baseUrl#</cfoutput>/images/logo/gregoryAlexanderLogo125_190.png" />
			
			<h4 style="display: block; margin-left: auto; margin-right: auto;">Your input and contributions are welcomed!</h4>
			<p>If you have an idea, BlogCfc based code, or a theme that you have built using this site that you want to share, please contribute by making a post here or share it by contacting us! This community can only thrive if we continue to work together.</p>

			<h4>Images and Photography:</h4>
			<p>Gregory Alexander either owns the copyright, or has the rights to use, all images and photographs on the site. If an image is not part of the "Gregory's Blog" open sourced distribution package, and instead is part of a personal blog post or a comment, please contact us and the author of the post or comment to obtain permission if you would like to use a personal image or photograph found on this site.</p>
			
			<h4>Credits:</h4>
			<p>
				Portions of Gregory's Blog are powered on the server side by BlogCfc, an open source blog developed by <a href="https://www.raymondcamden.com/" <cfif darkTheme>style="color:whitesmoke"</cfif>>Raymond Camden</a>. Revitalizing BlogCfc was a part of my orginal inspiration that prompted me to design this site. Some of the major open source contributers to BlogCfc include:
				<ol>
					<li>Peter Farrell: the author of 'Lyla Captcha' that is used on this blog.</li>
					<li><a href="https://www.petefreitag.com/" <cfif darkTheme>style="color:whitesmoke"</cfif>>Pete Freitag</a>: the author of the 'ColdFish' code formatter that is also used on this blog. </li>
				</ol>
			</p>
			<h4>Version:</h4>
			<p>
				Gregory's Blog Version <cfoutput>#application.blog.getVersion()#</cfoutput> July 25th, 2019.
			</p>
		</span>
	</div>
		
<cfelse>
	<cfmodule template="#customFooterHtmlTemplate#" />
</cfif>
			
<!--- Let the users scroll down to see the whole image. --->
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
			
<!--- Include tail end scripts. --->
<!-- Scroll magic and other green sock plugins. -->
<cfif includeGsap>
<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/greenSock/src/uncompressed/TweenMax.js"></script>
<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/scrollMagic/scrollmagic/uncompressed/ScrollMagic.js"></script>
<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/scrollMagic/scrollmagic/uncompressed/plugins/animation.gsap.js"></script>
<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/greenSock/src/uncompressed/plugins/ScrollToPlugin.js"></script>
<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/scrollMagic/scrollmagic/uncompressed/plugins/debug.addIndicators.js"></script>
</cfif>
<cfsilent>
<!-- Custom sroll magic js (and custom kendo notifications from my extended notification UI library) -->
<!---<script src="/common/js/scrollMagic/mainSceneNew.js"></script>--->
<!--- The delicate arch script --->
<!---<script src="/common/js/scrollMagic/delicateArch.js"></script>--->
<!--- Prism is intended to be our new code renderer in a later version. 
<script src="<cfoutput>#application.baseUrl#</cfoutput>/common/libs/prism/prism.js"></script>
--->
</cfsilent>
</body>
</html>
	
</cfprocessingdirective>