<!doctype html><!---Note: for html5, this doctype needs to be the first line on the page. (ga 10/27/2018)---> 
<cfprocessingdirective suppressWhiteSpace="true">
<cfprocessingdirective pageencoding="utf-8">
<cfsilent>
	
<!---
	Name         : Index
	Author       : Gregory Alexander/Raymond Camden 
	Created      : February 10, 2003
	Last Updated : July 25 2019
		 	
	 -------- New Kendo redesign history (Gregory Alexander) --------
	 -------------- Kendo Blog Cfc (Gregory Alexander) --------------
	 Re-engineered the code to make it better compatible with as single page application and completely redesigned the page. I want to strip out all styling in order to have the default kendo .css control the page. I also had to eliminate some of the orginal features, such as 'AddThis' as it was using old jQuery libraries and was not compabitle with either the newest version of jQuery, or Kendo. 
--->
	
<!--- //**************************************************************************************************************************************************
		User defined settings (these will be put in a database in the next major version).

		Notes: as soon as I get ORM integrated into the blog, these settings will move into the database. Currently, I have nearly 500 variables stored in Raymond's initial ini files, and it is realy cumbersome to get dynamic variables there instead of using a database where they really belong. After version 1.35, I forced myself to stop using the ini files and instead am using hardcoded variables for new features. I am going to throw away the logic behind the ini files, so for now, I am going to store these user defined variables here.
//****************************************************************************************************************************************************--->

<!--- Optional libraries --->
<!--- GSAP and scrollMagie allows for animations and parallax effects in the blog entries. Don't include by default. --->
<cfset application.includeGsap = false>

<!--- Determine whether to include the disqus commenting system. If you set this to true, you must also set the optional disqus settings that are right below. Note: this is an application var so that the recentcomments.cfm can access these settings. That template is invoked via a cfmodule tag. --->
<cfset application.includeDisqus = false>

<!--- Setting to determine whether to defer the scripts and css. This is a setting as I need to quickly debug to see if the defer is working, but you should leave this at true as it provides a better google speed score. --->
<cfset application.deferScriptsAndCss = true>

<!--- User defined application settings. 
Note: as soon as I get ORM integrated into the blog, these settings will move into the database. Currently, I have nearly 500 variables stored in Raymond's initial ini files, and it is realy cumbersome to get dynamic variables there instead of using a database where they really belong. After version 1.35, I forced myself to stop using the ini files and instead am using hardcoded variables for new features. I am going to throw away the logic behind the ini files, so for now, I am going to store these user defined variables here. --->

<!--- Video player settings. We have several options. Our default player is plyr. It is a full featured HTML5 media player, however, it does not play flash video. This should not be a problem as flash is soon to be depracated. Optionally, we can use the Kendo UI video player if you have a full Kendo license. The original flash player will take over for .flv videos, but will be depracated in 2020. --->
<cfset application.defaultMediaPlayer = 'plyr'><!---You can optionally choose 'KendoUiPlayer' if you have the full lisence. However, the Kendo Media player is lacks quite a few plyr features. The Kendo player is useful if you want the video player to take on the theme that you are using. --->

<!--- The addThis toolbox string changes depending upon the site and the configuration. --->
<cfset application.addThisToolboxString = "addthis_inline_share_toolbox"><!---Typically 'addthis_inline_share_toolbox'--->

<!--- //**************************************************************************************************************************************************
			Optional disqus settings. Set these if you set includeDisqus to true. The first setting is required, the rest are optional settings.
//****************************************************************************************************************************************************--->

<cfset application.disqusBlogIdentifier = "gregorys-blog"><!--- Required if you're using Disqus. Note: this is intentionally set as an application var. ---> 
<cfset application.disqusApiKey = "EhY9pmLkruL5Jj7cGVO3eab3cWVBFWLTPSmqADfe8tZhLamRpz8YiE7wQk4ta2hf"><!--- Optional if you're using Disqus - if you do not have an API key, leave this blank. Note: this is intentionally set as an application var. --->
<cfset disqusApiSecret = "xxdWJxzwFoSGPUddksrU9mtBQU45hgtSLeIqwnSXpauir5Hsp0gsx1gfDj0m9NtW"><!--- Optional if you're using Disqus - if you do not have an API Secret, leave this blank. --->
<cfset disqusAuthTokenKey = "08c0241af97d4ce7813c22085e61fea2"><!--- Optional if you're using Disqus - if you do not have an API Secret, leave this blank. --->
<cfset disqusAuthUrl = "https://disqus.com/api/oauth/2.0/authorize/"><!--- Leave this alone unless you konw what you're doing. --->
<cfset disqusAuthTokenUrl = "https://disqus.com/api/oauth/2.0/access_token/"><!--- Leave this alone unless you konw what you're doing. --->

<!--- Facebook Id --->
<cfset facebookAppId = "252557132092698">

<!--- //**************************************************************************************************************************************************
			Common custom templates.
//****************************************************************************************************************************************************--->
	
<!--- Do you have your own favorite icons that you want to display for your site? Put this in the /includes/customTemplates folder and include them.--->	
<cfset application.customFavIconTemplate = "includes/customTemplates/favIcon.cfm"><!--- Specify the path to the custom template if you have one. --->
	
<!--- //**************************************************************************************************************************************************
			Logic to set user defined settings
//****************************************************************************************************************************************************--->
	
<!--- Set the type string --->
<cfif application.deferScriptsAndCss>
	<!--- Defers the loading of the script and css using the deferjs library. --->
	<cfset scriptTypeString = "deferjs">
<cfelse>
	<cfset scriptTypeString = "text/javascript">
</cfif>
	
<!--- Do you want the page to automatically redirect using SSL? We are going to read the users setting set in the administrative interface (site URL) to determine if ssl should be enforced. It is is, we will use a server side redirect. You can change this by removing this code and setting useSsl to false.  --->
<cfif findNoCase("https", application.rooturl) eq 1>
	<cfset useSsl = true>
<cfelse>
	<cfset useSsl = false>
</cfif>

<cfif application.serverRewriteRuleInPlace>
	<cfset thisUrl = replaceNoCase(application.rootURL, '/index.cfm', '')>
	<!--- Create a blogUrl var. The thisUrl variable will be overwritten depending upon the page that is being viewed. --->
	<cfset blogUrl = thisUrl>
<cfelse>
	<cfset thisUrl = application.rootURL>
	<cfset blogUrl = thisUrl>
</cfif>
	
<!--- //**************************************************************************************************************************************************
			Global path and URL settings.
//****************************************************************************************************************************************************--->
	
<!--- Helper function to get the base URL. This was found at https://blog.pengoworks.com/index.cfm/2008/5/8/Getting-the-URLweb-folder-path-in-ColdFusion  --->
<cffunction name="getWebPath" access="public" output="false" returntype="string" hint="Gets the absolute path to the current web folder.">
	<cfargument name="url" required="false" default="#getPageContext().getRequest().getRequestURI()#" hint="Defaults to the current path_info" />
	<cfargument name="ext" required="false" default="\.(cfml?.*|html?.*|[^.]+)" hint="Define the regex to find the extension. The default will work in most cases, unless you have really funky urls like: /folder/file.cfm/extra.path/info" />

	<!---// trim the path to be safe //--->
	<cfset var sPath = trim(arguments.url) />
	<!---// find the where the filename starts (should be the last wherever the last period (".") is) //--->
	<cfset var sEndDir = reFind("/[^/]+#arguments.ext#$", sPath) />

	<cfreturn left(sPath, sEndDir) />
</cffunction>
	
<!--- Get the file path of the current directory--->
<cfset currentDir = getDirectoryFromPath(getCurrentTemplatePath())>
<!---Get the base URL (this used to be set in the Application.cfc template, however as of version 1.3, I removed this setting on the index page and am getting it via function here). --->
<cfset application.baseUrl = getWebPath()>
	
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
<cfif not isDefined("session.encryptionKey") or not isDefined("session.serviceKey")>
	<!--- Create unique token keys --->
	<cfinvoke component="#ProxyControllerObj#" method="createTokenKeys" returnvariable="createTokenKeys" />
	<!--- Store the value in session cookies. --->
	<cfset session.encryptionKey = createTokenKeys.encryptionKey>
	<cfset session.serviceKey = createTokenKeys.serviceKey>
</cfif>
	
<!--- //**************************************************************************************************************************************************
			Global and common params
//****************************************************************************************************************************************************--->

<!--- Determine if the http accept header contains webp. The getHttpRequestData().headers is a structure and we are targetting the accept element in the array. Note: nearly all modern browsers will include this if the browser supports the webp next gen image. --->
<cfset acceptHeader = getHttpRequestData().headers["accept"]>
<!--- Does the header accept webp? --->
<cfif findNoCase("webp", acceptHeader) gt 0>
	<cfset clientAcceptsWebP = true>
<cfelse>
	<cfset clientAcceptsWebP = false>
</cfif>
<!--- The logic to determine if the server has the necessary webp mime type was done in the application.cfc template. We will use the application.serverSupportsWebP variable that the mime type is installed on the server. Of course, both the client and the server need to support webp images before we can deliver them.---> 
<cfif application.serverSupportsWebP and clientAcceptsWebP>
	<cfset webpImageSupported = true>
<cfelse>
	<cfset webpImageSupported = false>
</cfif>

<!--- Hardcoded image paths (TODO make this a variable that can be set on the settings page.) --->
<cfset application.defaultLogoImageForSocialMediaShare = "/images/logo/ArehartSocialMediaShare.png">

<!--- Include the displayAndThemes template. This contains display and theme related functions. --->
<cfinclude template="#application.baseUrl#common/function/displayAndTheme.cfm">
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
<cfset blogBackgroundImage = application.baseUrl & application.themeSettingsArray[themeId][8]>
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
<cfset headerBackgroundImage = application.baseUrl & application.themeSettingsArray[themeId][14]>
<cfif webpImageSupported>
	<!---Overwrite the headerBodyDividerImage var and change the extension to .webp--->
	<cfset headerBackgroundImage = replaceNoCase(headerBackgroundImage, '.png', '.webp')>
</cfif>
<!--- The background image for the top menu. This should be a consistent color and not gradiated. --->
<cfset menuBackgroundImage = application.baseUrl & application.themeSettingsArray[themeId][15]>	
<!--- We will try to substitute a webp image here. --->
<cfif webpImageSupported>
	<!---Overwrite the headerBodyDividerImage var and change the extension to .webp--->
	<cfset menuBackgroundImage = replaceNoCase(menuBackgroundImage, '.png', '.webp')>
</cfif>
<!--- This setting determines if the whole image should be shown on screen, or if the image should be captured from the left until the image is cut off at the end of the screen. Essentially, setting this to true set the image width t0 be 100%, whereas setting this to false will left justify the image and cut off any overflow. The resolution is quite high, so setting this to false will cut off the right part of most of the images. --->
<cfset coverKendoMenuWithMenuBackgroundImage = application.themeSettingsArray[themeId][16]>
<!--- Both desktop and mobile logos. The mobile logo should be smaller than the desktop obviously. --->
<cfset logoImageMobile = application.baseUrl & application.themeSettingsArray[themeId][17]>
<cfset logoMobileWidth = application.themeSettingsArray[themeId][18]>
<cfset logoImage = application.baseUrl & application.themeSettingsArray[themeId][19]>

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
<cfset headerBodyDividerImage = application.baseUrl & application.themeSettingsArray[themeId][25]>
<!--- See if we can use a webp image instead of the default png. --->
<cfif webpImageSupported>
	<!---Overwrite the headerBodyDividerImage var and change the extension to .webp--->
	<cfset headerBodyDividerImage = replaceNoCase(headerBodyDividerImage, '.png', '.webp')>
</cfif>
			
<!--- Kendo file locations. --->
<!--- Todo: this is missing in the array. --->
<cfset kendoCommonCssFileLocation = trim(getSettingsByTheme(kendoTheme).kendoCommonCssFileLocation)>
<cfset kendoThemeCssFileLocation = application.themeSettingsArray[themeId][26]>
<cfset kendoThemeMobileCssFileLocation = application.themeSettingsArray[themeId][27]>
	
<!--- //**************************************************************************************************************************************************
			Logic to set vars for the client
//****************************************************************************************************************************************************--->
	
<cfset breakPoint = application.themeSettingsArray[themeId][28]>
<!--- TODO Find out why this broke on the default theme. 
Safety check --->
<cfif not isNumeric(breakPoint) or breakpoint eq "">
	<cfset breakPoint = 1921><!---Was 1300--->
</cfif>
	
<!--- Determine if the blog background image has been changed by the blog owner. If the image is the default image that comes with the installation package, we are going to modify the image if the browser can handle the new webP image format, and change the blog background image depending upon if the client is mobile or desktop. --->
<cfinvoke component="#ThemesObj#" method="getDefaultBlogBackgroundImageByTheme" returnvariable="defaultBlogImageBackground">
	<cfinvokeargument name="uiTheme" value="#kendoTheme#">
</cfinvoke>
<!--- Set a var. We'll use this in javascript in the setCssVars function below. --->
<cfif application.themeSettingsArray[themeId][8] eq defaultBlogImageBackground>
	<cfset defaultBlogImage = true>
<cfelse>
	<cfset defaultBlogImage = false>
</cfif>
	
<!--- Logic to modify the default background image string to specify the webp image extension and determine the mobile version (which is smaller). I am not storing these extra strings in the ini file right now. That must wait until I use a database. --->
<!--- Is this the default blog background image. --->
<cfif defaultBlogImage>
	<cfset blogBackgroundImageWebP = replaceNoCase(blogBackgroundImage, '.jpg', '.webp')>
	<cfset blogBackgroundImageMobileWebP = replaceNoCase(blogBackgroundImage, '.jpg', 'Mobile.webp')>
	<!--- The non-webp desktop image is the default blog backgound image (either selected by the user or the default blog background image set in Themes.cfc). --->
	<cfset blogBackgroundImageMobileJpg = replaceNoCase(blogBackgroundImage, '.jpg', 'Mobile.jpg')>

	<!--- Is webp in the accpet header? --->
	<cfif webpImageSupported>
		<!--- Use the webp image. First, we need to check to see whether the client is mobile or desktop. I scaled the mobile background image down quite a bit. We don't need to have a large image on mobile clients. --->
		<cfif session.isMobile>
			<cfset blogBackgroundImage = blogBackgroundImageMobileWebP>
		<cfelse>
			<cfset blogBackgroundImage = blogBackgroundImageWebP>
		</cfif>
	<cfelse><!---<cfif webpImageSupported>--->
		<!--- Use a jpg. --->
		<cfif session.isMobile>
			<!--- Use the default blog background image (which is a jpg). --->
			<cfset blogBackgroundImage = blogBackgroundImageMobileJpg>
		<cfelse>
			<cfset blogBackgroundImage = blogBackgroundImage>
		</cfif>
	</cfif><!---<cfif webpImageSupported>---> 

</cfif><!---<cfif defaultBlogImage>--->
	
<!--- //**************************************************************************************************************************************************
			Custom plugins and strings
//********************************************************************************************************************************************************
Notes: I am planning on incorporating a full plugin structure, however, this will entail making database changes that I am avioding in the
1st version of this blog. For the first version of this software, I want to make minimal changes to the structure, other than to code a new
Kendo interface and make it themeable, in order to keep this version accessible to the current BlogCfc base. For now, if you want to make changes
or to create a new 'plug-in', copy and paste this 'custom' setting logic into a new template and include it either using a cfinclude or a cfmodule 
template in a new folder or a template name that will not be overridden wwen a new version of this software is created ((ie #application.baseUrl#customTemplateSetting.cfm)'. 
In the next x versions, I want to use the datatabase to store plugins and custom templates, but I am not there yet. However, I am coding this logic in order to 'set the stage' 
for this new functionality that should be available in an upcoming version. At least we can have a general framework how to include custom code and not step on each others 
toes with future updates.
--->	
<!--- Core logic below this section. Deals with the getMode and entry logic. Include the full path of the logical template (ie #application.baseUrl#plugin/coreLogic.cfm) --->
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
<!--- Template to include the javascript for the top menu. Note: this template is within the code region of the customTopMenuHtmlTemplate. 
Custom setting for Arehart --->
<cfset customTopMenuJsTemplate = "/blog/client/includes/customTemplates/topMenu.cfm">
<!--- Original code: <cfset customTopMenuJsTemplate = application.themeSettingsArray[themeId][36]>--->
<!--- Template to include the css rules for the blog content (blog entries). --->
<cfset customBlogContentCssTemplate = application.themeSettingsArray[themeId][37]>
<!--- Template to include Kendo's widget and UI javascripts for the main blog (not the header script) --->
<cfset customBlogJsContentTemplate = application.themeSettingsArray[themeId][38]>
<!--- Template to include blog content HTML (blog entries). This is a rather intensive bit of code that will be broken down further in a later version. --->
<cfset customBlogContentHtmlTemplate = application.themeSettingsArray[themeId][39]>
<!--- Template to include a custom footer. 
Custom setting for Arehart --->
<cfset customFooterHtmlTemplate = "/blog/client/includes/customTemplates/footer.cfm">
<!---Orignal code: <cfset customFooterHtmlTemplate = application.themeSettingsArray[themeId][40]>--->

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
	
	<!--- Get the page mode which depends upon what the page is rendering. The page mode on the index.cfm page is 'blog', when the user is reading a post, the pageMode is post, etc.--->
	<cffunction name="getPageMode" access="public" output="false" returntype="string" hint="Determines what the page is rendering.">
		
		<cfif not isDefined(URL.mode)>
			<cfset pageMode = "blog">	
		<cfelseif URL.mode eq "">
			<cfset pageMode = "blog">
		<cfelse>
			<cfswitch expression="#URL.mode#">
				<cfcase value="alias">
					<cfset pageMode = "post">
				</cfcase>
				<cfcase value="entry">
					<cfset pageMode = "post">
				</cfcase>
				<cfcase value="cat">
					<cfset pageMode = "category">
				</cfcase>
				<cfcase value="postedBy">
					<cfset pageMode = "postedBy">
				</cfcase>
				<cfcase value="month">
					<cfset pageMode = "month">
				</cfcase>
				<cfcase value="day">
					<cfset pageMode = "month">
				</cfcase>
				
			</cfswitch>
		</cfif>
			
		<!--- Return the value --->
		<cfreturn pageMode>
			
	</cffunction>
	
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
			
	<!--- //**************************************************************************************************************************************************
			Functions to inspect the post content for certain XML strings embedded within a post. 
	//****************************************************************************************************************************************************--->
			
	<!--- We can now use cfincludes and other stuff in the post entry itself. I put this into a function as I anticipate that this methodology will be used for other purposes other than a cfinclude.  --->
	<cffunction name="inspectPostContentForXmlKeywords" access="public" returntype="string" hint="Determines if there is any action needed if the post content contains certain keywords. Returns a list of keywords if the xml keyword has been found.">
		<cfargument name="postContent" required="yes" hint="The post content is typically 'application.blog.renderEntry(body,false,enclosure)'.">
		
		<!--- Preset the var as an empty string. --->
		<cfset xmlKeyWords="">
		
		<!--- Use a cfinclude. --->
		<cfif arguments.postContent contains "<cfincludeTemplate:">
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "cfincludeTemplate">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "cfincludeTemplate">
			</cfif>
		</cfif>
					
		<!--- Meta tags. --->
		<cfif arguments.postContent contains "<titleMetaTag:">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "titleMetaTag">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "titleMetaTag">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<descMetaTag:">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "descMetaTag">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "descMetaTag">
			</cfif>
		</cfif>
					
		<!--- Social media sharing. --->
		<!--- Images --->
		<cfif arguments.postContent contains "<facebookImageUrlMetaData:">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "facebookImageUrlMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "facebookImageUrlMetaData">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<twitterImageUrlMetaData:">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "twitterImageUrlMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "twitterImageUrlMetaData">
			</cfif>
		</cfif>	
					
		<!--- Media --->
		<cfif arguments.postContent contains "<facebookVideoUrlMetaData:">
			<!--- Get the facebook video url if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "facebookVideoUrlMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "facebookVideoUrlMetaData">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<twitterVideoUrlMetaData:">
			<!--- Get the twitter video url if available. If this argument is set, the twitter card will change from 'summary_large_image' to 'player'. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "twitterVideoUrlMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "twitterVideoUrlMetaData">
			</cfif>
		</cfif>	
		
		<!--- Custom social media description (I am not using this in Gregory's Blog yet) --->
		<cfif arguments.postContent contains "<socialMediaDescMetaData:">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "socialMediaDescMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "socialMediaDescMetaData">
			</cfif>
		</cfif>
					
		<!--- Media player arguments --->
		<cfif arguments.postContent contains "<videoType:">
			<!--- The video type will be either video/mp4, video/webm, audio/mp3, audio/ogg, YouTube, or Vimeo --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoType">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoType">
			</cfif>
		</cfif>
		<!--- The image on top of the video when it does not play. --->
		<cfif arguments.postContent contains "<videoPosterImageUrl:">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoPosterImageUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoPosterImageUrl">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<smallVideoSourceUrl:">
			<!--- We are supplying different sizes to fit the device. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "smallVideoSourceUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "smallVideoSourceUrl">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<mediumVideoSourceUrl:">
			<!--- We are supplying different sizes to fit the device. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "mediumVideoSourceUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "mediumVideoSourceUrl">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<largeVideoSourceUrl:">
			<!--- We are supplying different sizes to fit the device. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "largeVideoSourceUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "largeVideoSourceUrl">
			</cfif>
		</cfif>
		<!--- Video captions --->
		<cfif arguments.postContent contains "<videoCaptionsUrl:">
			<!--- Supply the link to the WebVTT file --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoCaptionsUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoCaptionsUrl">
			</cfif>
		</cfif>
		<!--- Set videoCrossOrigin to true when using media outside of your own site. --->
		<cfif arguments.postContent contains "<videoCrossOrigin:">
			<!--- Get the cross origin property --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoCrossOrigin">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoCrossOrigin">
			</cfif>
		</cfif>
					
		<!--- The next two blocks, videoWidthMetaData and videoHeightMetaData, apply to both facebook and twitter. --->		
		<cfif arguments.postContent contains "<videoWidthMetaData:">
			<!--- Get the width. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoWidthMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoWidthMetaData">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<videoHeightMetaData:">
			<!--- meta data. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoHeightMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoHeightMetaData">
			</cfif>
		</cfif>	
					
		<!--- YouTube  --->
		<cfif arguments.postContent contains "<youTubeUrl:">
			<!--- Get the url. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "youTubeUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "youTubeUrl">
			</cfif>
		</cfif>	
					
		<!--- Vimeo  --->
		<cfif arguments.postContent contains "<vimeoVideoId:">
			<!--- Get the url. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "vimeoVideoId">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "vimeoVideoId">
			</cfif>
		</cfif>	
					
		<!--- Structured data (Not used yet) --->
		<cfif arguments.postContent contains "<articleStructuredOrgLogoUrl:">
			<!--- Include the full path to the org logo. The org logo should be 112x112px at a minimum. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "articleStructuredOrgLogoUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "articleStructuredOrgLogoUrl">
			</cfif>
		</cfif>
		<!--- Google prefers to have 3 images: a 16/9 image, 4/3 and a 1/1.  --->
		<cfif arguments.postContent contains "<includeGoogleStructuredImage16_9:">
			<!--- The 16x9 image is 1200 pixels wide and 675 wide. The Image.cfc will autormatically create this image when making a post and save it to the /enclosures/google/16_9 directory if it can.  --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "includeGoogleStructuredImage16_9">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "includeGoogleStructuredImage16_9">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<includeGoogleStructuredImage4_3:">
			<!--- The 16x9 image is 1100 pixels wide and 825 wide. The Image.cfc will autormatically create this image when making a post and save it to the /enclosures/google/4_3 directory if it can.  --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "includeGoogleStructuredImage4_3">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "includeGoogleStructuredImage4_3">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<includeGoogleStructuredImage1_1:">
			<!--- The 16x9 image is 630 pixels wide and 630 wide. The Image.cfc will autormatically create this image when making a post and save it to the /enclosures/google/1_1 directory if it can.  --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "includeGoogleStructuredImage1_1">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "includeGoogleStructuredImage1_1">
			</cfif>
		</cfif>
			
		<!--- Return it. --->
		<cfreturn xmlKeyWords>
			
	</cffunction>
		
	<cffunction name="getXmlKeywordValue" access="public" output="true" returntype="string" hint="Gets the variable stuck in one of our xml strings. Note: this is a temporary function and it will be replaced once I redesign the database. This is a temporary workaround.">
		<cfargument name="postContent" required="yes" hint="The post content is typically 'application.blog.renderEntry(body,false,enclosure)'.">
		<cfargument name="xmlKeyword" required="yes" hint="Grab the keyword from the inspectPostContent function.">
			
		<cfparam name="keyWordValue" default="">
			
		<cftry>
		
			<!--- Set the strings that we're searching for. --->
			<cfset keyWordStartString = "<" & arguments.xmlKeyword & ":">
			<cfset keyWordEndString = "</" & arguments.xmlKeyword & ">">

			<!--- Find the start and end position of the keywords. --->
			<cfset keyWordStartPos = findNoCase(keyWordStartString, arguments.postContent)>
			<cfset keyWordEndPos = findNoCase(keyWordEndString, arguments.postContent)>
			<!--- Add the lengh of the keyword to get the proper start position. --->
			<cfset keyWordValueStartPos = keyWordStartPos + len(keyWordStartString)>
			<!--- And determine the count --->
			<cfset valueCount = keyWordEndPos - keyWordValueStartPos>
			<!---<cfoutput>#keyWordStartString# #keyWordEndString# StartPos:#keyWordValueStartPos# EndPos:#keyWordEndPos# count:#valueCount#</cfoutput>--->
			<!--- Get the value in the xml string. --->
			<cfset keyWordValue = mid(arguments.postContent, keyWordValueStartPos, valueCount-1)>
			<!---<cfoutput>keyWordValue:#keyWordValue#</cfoutput>--->
			
			<cfcatch type="any">
				<cfset error = cfcatch.detail>
			</cfcatch>
				
		</cftry>
			
		<!--- Return the value --->
		<cfreturn keyWordValue>
			
	</cffunction>
			
	<!--- Structured data functions --->
	<cffunction name="removeMainEntityOfPageFromPostContent" required="yes"  hint="Removes the mainEntityOfPage block from the ld json string. This is used when the blog owner (like me) hardcodes ld json, but needs to remove the mainEntityOfPage block of code when the blog is showing multipe posts (ie the homepage of the blog) as we can't have two different main identities.">
		<cfargument name="postContent" required="yes" hint="Supply the post content.">

		<!--- Set the strings that we're searching for. --->
		<cfset mainEntityStartString = '"mainEntityOfPage": {'>
		<cfset mainEntityEndString = "},">

		<!--- Find the start and end position of the mainEntityOfPage block. --->
		<cfset startPos = findNoCase(mainEntityStartString, arguments.postContent)>
		<cfset endPos = findNoCase(mainEntityEndString, arguments.postContent)>

		<!--- And determine the count --->
		<cfset mainEntityValueCount = endPos - startPos>
		<!--- Get the value in the string. --->
		<cfset mainEntityStringValue = mid(arguments.postContent, startPos, mainEntityValueCount+len(mainEntityEndString))>
		<!--- Remove the mainEntityOfPage code block from the string --->
		<cfset newJsonLdString = replaceNoCase(arguments.postContent, mainEntityStringValue, '')>

		<!--- Return it. --->
		<cfreturn newJsonLdString>
	</cffunction>
			
	<!--- Function to remove the 'quasi' xml keywords from the post content. Note: this is an ugly hack and will go away once I redesign the database. ---> 
	<cffunction name="removeXmlKeyWordContentFromPost" access="public" returntype="string" hint="Removes the vaarious 'qausi' xml that I am stuffing into an individual post. This will go away once I develop the new database">
		<cfargument name="postContent" required="yes" hint="The post content is typically 'application.blog.renderEntry(body,false,enclosure)'.">
		<cfargument name="xmlKeywords" required="yes" hint="Supply all of the xmlKeywords.">
		
		<!--- Preset our newPostContent content. --->
		<cfset newPostContent = arguments.postContent>
			
		<!--- Loop through the xml keywords --->
		<cfloop list="#arguments.xmlKeywords#" index="i">
			
			<!--- Put this in a try block. --->
			<cftry>
			
				<!--- Isolate the keyword --->
				<cfset thisKeyword = i>

				<!--- Find the start and end position of the keywords. --->
				<cfset keyWordStartString = "<" & thisKeyword & ":">
				<cfset keyWordEndString = "</" & thisKeyword & ">">

				<!--- Find the start and end position of the keywords. --->
				<cfset postDataStartPos = findNoCase(keyWordStartString, newPostContent)>
				<cfset postDataEndPos = findNoCase(keyWordEndString, newPostContent)>

				<!--- And determine the count --->
				<cfset valueCount = postDataEndPos - postDataStartPos>
				<!--- Get the value in the xml string. --->
				<cfset xmlBody = mid(newPostContent, postDataStartPos, valueCount)>

				<!--- Strip the content. --->
				<cfset strippedPostContent = replaceNoCase(newPostContent, xmlBody, "", "all")>
				<!--- Strip the start of the tag --->
				<cfset strippedPostContent = replaceNoCase(strippedPostContent, keyWordStartString, "", "all")>
				<!--- And finally, strip the ending tag --->
				<cfset strippedPostContent = replaceNoCase(strippedPostContent, keyWordEndString, "", "all")>

				<!--- Return new post content --->
				<cfset newPostContent = strippedPostContent>

				<cfcatch type="any">
					<cfset error = cfcatch.detail>
				</cfcatch>
			</cftry>
				
		</cfloop>
			
		<!--- Return it. --->
		<cfreturn newPostContent>
			
	</cffunction>
				
	<cffunction name="replaceStringInContent" access="public" output="true" returntype="string" hint="Removes everything between data found in the post content. Used by the search results template.">
		<cfargument name="content" required="yes" hint="What is the content that we need to search and replace?">
		<cfargument name="startString" required="yes" hint="What is the string that we are looking for?">
		<cfargument name="endString" required="yes" hint="And what is the end of the string?">
		<cfargument name="replaceValueWith" required="no" default="" hint="What do you want to replace the string that is found between the start and end positions with? If you leave this blank, it will remove the content that is found.">

		<cftry>
			<!--- Find the start and end position of the mainEntityOfPage block. --->
			<cfset startPos = findNoCase(arguments.startString, arguments.content)>
			<cfset endPos = findNoCase(arguments.endString, arguments.content)>

			<!--- And determine the count --->
			<cfset valueCount = endPos - startPos>
			<!--- Get the value in the string. --->
			<cfset stringValue = mid(arguments.content, startPos, valueCount+len(arguments.endString))>
			<!--- Remove the ld json code block from the string --->
			<cfset newString = replaceNoCase(arguments.content, stringValue, replaceValueWith)>
				
			<cfcatch type="any">
				<!--- The string was not found. --->
				<cfset newString = arguments.content>
			</cfcatch>
		</cftry>

		<!--- Return new post content --->
		<cfreturn newString>

	</cffunction>
						
	<!--- //**************************************************************************************************************************************************
			SEO: Meta tags, social media sharing, and cononical url's
	//****************************************************************************************************************************************************--->
						
	<!--- The title will be overwritten by the description if the blog is in entry mode. --->
	<cfset titleMetaTagValue = htmlEditFormat(application.blog.getProperty("blogTitle"))>
	<cfset descriptionMetaTagValue = application.blog.getProperty("blogDescription")>
			
	<!--- Add short strings to the title when the user selected category. --->
	<cfif isDefined("attributes.title")>
		<cfset additionalTitle = ": " & attributes.title>
	<cfelse>	
		<cfset additionalTitle = "">
		<!--- Categories. --->
		<cfif isDefined("url.mode") and url.mode is "cat">
			<!--- can be a list --->
			<cfset additionalTitle = "">
			<cfloop index="cat" list="#url.catid#">
			<cftry>
				<cfset additionalTitle = additionalTitle & ": " & application.blog.getCategory(cat).categoryname>
				<cfcatch></cfcatch>
			</cftry>
			</cfloop>
			
			<!--- Add the short category to the Title if the user is viewing the categories --->
			<cfif additionalTitle neq "">
				<cfset titleMetaTagValue = titleMetaTagValue & ": " & additionalTitle>
			</cfif>
		
		<!--- We're reading a single entry. We're going to change the title to be the title of the entry here.  --->
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
				<!--- On individual entry pages, the title of the page is the title of the post. --->
				<cfset titleMetaTagValue = entry.title>
				<!--- Gregory's code. We may be in entry mode based upon logic above that switched us from alias to entry mode (see if using alias, switch mode to entry). If we are, the entry will have no value and we need to get the articles data. I'll need to revise the logic to make it cleaner one day. --->
				<cfcatch>
					<cfset entry = articles>
					<!--- On individual entry pages, the title of the page is the title of the post. --->
					<cfset titleMetaTagValue = entry.title>
				</cfcatch>
			</cftry>
		</cfif>
	</cfif>
						
	<!--- Get all of the keywords that may be enclosed in the post. The articles body may not be defined when looking at a post that contains the more tag when in blog mode. --->
	<cfif isDefined("articles.body")>
		<cfset xmlKeywords = inspectPostContentForXmlKeywords(articles.body)>
	<cfelse>
		<cfset xmlKeywords = "">
	</cfif>
						
	<!--- Preset the social media description variable. It may be overwritten later if the social media description is embedded in the xml within a post like so: '<socialMediaDescMetaData:this description></socialMediaDescMetaData>'. --->
	<cfset socialMediaDescMetaTagValue = descriptionMetaTagValue>
		
	<!--- Preset the default social media image URLs. We will overwrite these later if they're available. --->
	<cfset facebookImageMetaTagValue = thisUrl & application.defaultLogoImageForSocialMediaShare>
	<cfset twitterImageMetaTagValue = thisUrl & application.defaultLogoImageForSocialMediaShare>
		
	<!--- Default twitter card type. We will rewrite this if the twitterMediaUrlMetaData is defined. --->
	<cfset twitterCardType = "summary_large_image">
	
	<!--- Is this page displaying a single post?--->
	<cfif getPageMode() eq 'post'>
								
		<!--- //**************************************************************************************************************************************************
		Post Images
		//****************************************************************************************************************************************************--->
		<!--- Determine if there is an enclosure, and if the social media images exist for this enclosure. We may over-ride these variables later if the social media images are embedded in xml in the post. --->
		<cfif (entry.enclosure contains '.jpg' or entry.enclosure contains '.gif' or entry.enclosure contains '.png' or entry.enclosure contains '.webp')>
		
			<!--- If social media images are uploaded when an entry is made, use the social media URL. --->
			<cfset facebookImageUrl = thisUrl & "/enclosures/facebook/" & getFileFromPath(entry.enclosure)>
			<cfset twitterImageUrl = thisUrl & "/enclosures/twitter/" & getFileFromPath(entry.enclosure)>

			<!--- If they exist, overwrite the meta tag vars. --->
			<cfif fileExists(expandPath(application.baseUrl & '/enclosures/facebook/' & getFileFromPath(entry.enclosure)))>
				<cfset facebookImageMetaTagValue = facebookImageUrl>
			</cfif>
			<cfif fileExists(expandPath(application.baseUrl & '/enclosures/twitter/' & getFileFromPath(entry.enclosure)))>
				<cfset twitterImageMetaTagValue = twitterImageUrl>
			</cfif>

		</cfif><!---<cfif (entry.enclosure contains '.jpg' or entry.enclosure contains '.gif' or entry.enclosure contains '.png' or entry.enclosure contains '.mp3')>--->
			
		<!--- SEO Meta tags. --->
		<cfif findNoCase("titleMetaTag", xmlKeywords) gt 0> 
			<!--- Overwrite the titleMetaTagValue variable. --->
			<cfset titleMetaTagValue = getXmlKeywordValue(articles.body, 'titleMetaTag')>
		</cfif>
		<cfif findNoCase("descMetaTag", xmlKeywords) gt 0> 
			<!--- Overwrite the descriptionMetaTagValue variable. --->
			<cfset descriptionMetaTagValue = getXmlKeywordValue(articles.body, 'descMetaTag')>
		</cfif>
		<!--- Check to see if there is a social media description. in the post body --->
		<cfif findNoCase("socialMediaDescMetaData", xmlKeywords) gt 0> 
			<!--- Overwrite the socialMediaDescMetaTagValue variable. --->
			<cfset socialMediaDescMetaTagValue = getXmlKeywordValue(articles.body, 'socialMediaDescMetaData')>
		</cfif>
		
		<!--- Social Media Sharing for Images. --->
		<!--- Overwrite the facebookImageMetaTagValue variable --->
		<cfif findNoCase("facebookImageUrlMetaData", xmlKeywords) gt 0> 
			<!--- See if there is meta data inside of the blog post. --->
			<cfset facebookImageMetaTagValue = getXmlKeywordValue(articles.body, 'facebookImageUrlMetaData')>
		</cfif>
		<!--- Overwrite the twitterImageMetaTagValue --->
		<cfif findNoCase("twitterImageUrlMetaData", xmlKeywords) gt 0> 
			<!--- See if there is meta data inside of the blog post. --->
			<cfset twitterImageMetaTagValue = getXmlKeywordValue(articles.body, 'twitterImageUrlMetaData')>
		</cfif>
		
	</cfif><!---<cfif isDefined("URL.mode") and (URL.mode is "entry" or URL.mode eq 'alias')>--->
			
	<!--- //**************************************************************************************************************************************************
	Video and Audio Content
	//****************************************************************************************************************************************************--->
	<cfparam name="videoType" default="" type="string">
	<cfparam name="videoPosterImageUrl" default="" type="string">
	<cfparam name="smallVideoSourceUrl" default="" type="string">
	<cfparam name="mediumVideoSourceUrl" default="" type="string">
	<cfparam name="largeVideoSourceUrl" default="" type="string">
	<cfparam name="videoCaptionsUrl" default="" type="string">

	<!--- Overwrite the vars if the proper xml is embedded in the post. The xml keyword thing is temporary and will be put into the database in the future. --->
	<cfif findNoCase("videoType", xmlKeywords) gt 0> 
		<cfset videoType = getXmlKeywordValue(articles.body, 'videoType')>
	</cfif>
	<cfif findNoCase("videoPosterImageUrl", xmlKeywords) gt 0> 
		<cfset videoPosterImageUrl = getXmlKeywordValue(articles.body, 'videoPosterImageUrl')>
	</cfif>	
	<cfif findNoCase("smallVideoSourceUrl", xmlKeywords) gt 0> 
		<cfset smallVideoSourceUrl = getXmlKeywordValue(articles.body, 'smallVideoSourceUrl')>
	</cfif>
	<cfif findNoCase("mediumVideoSourceUrl", xmlKeywords) gt 0> 
		<cfset mediumVideoSourceUrl = getXmlKeywordValue(articles.body, 'mediumVideoSourceUrl')>
	</cfif>
	<cfif findNoCase("largeVideoSourceUrl", xmlKeywords) gt 0> 
		<cfset largeVideoSourceUrl = getXmlKeywordValue(articles.body, 'largeVideoSourceUrl')>
	</cfif>
	<cfif findNoCase("videoCaptionsUrl", xmlKeywords) gt 0> 
		<cfset videoCaptionsUrl = getXmlKeywordValue(articles.body, 'videoCaptionsUrl')>
	</cfif>
	<cfif findNoCase("videoCrossOrigin", xmlKeywords) gt 0> 
		<cfset videoCrossOrigin = getXmlKeywordValue(articles.body, 'videoCrossOrigin')>
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
		
	<!--- //**************************************************************************************************************************************************
	SEO: no index and canonical Url
	//****************************************************************************************************************************************************--->
	<!--- Gregory added the following code to create a proper canonical rel tag and other SEO's --->
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
	<cfif (URL.mode is "entry" or URL.mode eq 'alias')>
		<cfset canonicalUrl  = application.blog.makeLink(articles.id[1])>
		<!--- Check to see if there is a URL rewrite rule in place. If a rewrite rule is in place, remove the 'index.cfm' from teh cannonicalUrl string. --->
		<cfif application.serverRewriteRuleInPlace>
			<cfset canonicalUrl = replaceNoCase(canonicalUrl, '/index.cfm', '')>
		</cfif>
		<cfset addSocialMediaUnderEntry = true>
	</cfif>
		
<cfelse>
	<cfinclude template="#customCoreLogicTemplate#" />
</cfif>
		
<!--- //**************************************************************************************************************************************************
			Header properties and redirects.
//****************************************************************************************************************************************************--->
<!--- Cache this stuff --->
<cfheader name="filesMatch" value="<filesMatch '.(css|jpg|jpeg|png|gif|js|ico)$'>">
<cfheader name="Expires" value="#GetHttpTimeString(dateAdd('m', 1, Now()))#">
<cfheader name="cache-control" value="Cache-Control: max-age=31536000, public">

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

<!--- //**************************************************************************************************************************************************
			Page output
//****************************************************************************************************************************************************--->	
</cfsilent>
<html lang="en-US"><head><cfoutput>
<cfif customHeadTemplate eq ""> 
	<title>#htmlEditFormat(titleMetaTagValue)#</title>
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<meta name="title" content="#titleMetaTagValue#" />
	<meta name="description" content="#descriptionMetaTagValue#" />
	<meta name="keywords" content="#application.blog.getProperty("blogKeywords")#" />
	<link rel="canonical" href="#canonicalUrl#" />
	<meta name="robots" content="<cfif noIndex>noindex<cfelse>index, follow</cfif>" />
	<!-- Twitter meta tags. -->			
	<meta name="twitter:card" content="#twitterCardType#">
	<meta name="twitter:site" content="@#thisUrl#">
	<meta name="twitter:title" content="#titleMetaTagValue#">
	<meta name="twitter:description" content="#descriptionMetaTagValue#">
	<meta name="twitter:image" content="#twitterImageMetaTagValue#?id=#createUuid()#">
<cfif videoType neq "" and getPageMode() eq 'post'>
	<!-- Twitter player card meta types -->
	<!-- The twitter video must be on a mimimal page that just includes the video, and nothing else. -->
	<meta property="twitter:player" content="https://gregoryalexander.com/blog/videoPlayer.cfm?videoUrl=#ogVideo#&poster=#twitterImageMetaTagValue#&id=#createUuid()#">
	<meta property="twitter:player:width" content="#ogVideoWidth#">	
	<meta property="twitter:player:height" content="#ogVideoHeight#">	
</cfif>
	<!-- Open graph meta tags for Facebook. See notes. -->
	<meta property="og:image" content="#facebookImageMetaTagValue#"> 
	<meta property="og:site_name" content="#htmlEditFormat(application.blog.getProperty("blogTitle"))#" />
	<meta property="og:url" content="#canonicalUrl#" />
	<meta property="og:title" content="#titleMetaTagValue#" />
	<meta property="og:description" content="#descriptionMetaTagValue#" />
	<meta property="fb:app_id" content="#facebookAppId#">
<cfif videoType neq "" and getPageMode() eq 'post'>
	<!-- Video meta types -->
	<meta property="og:type" content="video.movie">
	<meta property="og:video:type" content="video/mp4"><!---RFC 4337 § 2, video/mp4 should be the correct Content-Type for MPEG-4 video.--->
	<meta property="og:video" content="#ogVideo#">
	<meta property="og:video:url" content="#ogVideo#">
	<meta property="og:video:secure_url" content="#ogVideo#">
	<meta property="og:video:width" content="#ogVideoWidth#">	
	<meta property="og:video:height" content="#ogVideoHeight#">
</cfif>
	<!--TODO <meta property="og:type" content="blog" />-->
	<meta name="viewport" content="width=device-width, initial-scale=1"><!---<meta name="viewport" content="968"><meta name="viewport" content="1280">--->
 	<link rel="alternate" type="application/rss+xml" title="RSS" href="#thisUrl#/rss.cfm?mode=full" />
<cfif application.customFavIconTemplate neq "">
	<!-- FavIcons -->
	<cfinclude template="#application.customFavIconTemplate#">
</cfif>
	<cfsilent>
	<!--- We are only including the top level ld json when we are not in blog mode. The ld json will be in the body of the post.  ---->
	<cfif getPageMode() neq 'blog'>
		<cfset struturedDataMainEntityOfPage = "Blog"><!--- The URL of a page on which the thing is the main entity. --->
		<cfset struturedDataMainEntityOfPageUrl = blogUrl>
	<cfelse>
		<cfset struturedDataMainEntityOfPage = "BlogPosting"><!--- The URL of a page on which the thing is the main entity. --->
		<cfset struturedDataMainEntityOfPageUrl = canonicalUrl>
	</cfif>
	</cfsilent>
<cfif getPageMode() neq 'blog'>
	<!-- Structured data (see schema.org). -->
	<script type="application/ld+json">
	{
		"@context": "http://schema.org",
		"@type": "Blog",
		"name": "#htmlEditFormat(application.blog.getProperty("blogTitle"))#",
		"url": "#struturedDataMainEntityOfPageUrl#",
		"mainEntityOfPage": {
			  "@type": "#struturedDataMainEntityOfPage#",
			  "@id": "#struturedDataMainEntityOfPageUrl#"
		},
		"description": "#descriptionMetaTagValue#",
		"publisher": {
			"@type": "Organization",
			"name": "#htmlEditFormat(application.blog.getProperty("blogTitle"))#"
		}
	}
	</script>
</cfif>
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
	<!--- Use the 3.4.1 version if using commercial. --->
	<script src="/common/libs/jQuery/jquery-3.4.1.min.js"></script>
	<cfsilent><!---
	Via CDN:
	<script
	  src="https://code.jquery.com/jquery-3.4.1.min.js"
	  integrity="sha256-CSXorXvZcTkaix6Yvo6HppcZGetbYMGWSFlBw8HfCJo="
	  crossorigin="anonymous"></script>
	--->
	</cfsilent>
<cfelse>
		<!--- Otherwise, use the jQuery version embedded in Kendo.core. --->
	<script src="#application.kendoSourceLocation#/js/jquery.min.js"></script>
</cfif>
	<!-- Small library that fixes the Chrome "Added non-passive event listener to a scroll-blocking 'touchstart' event" errors. -->
	<script type="#scriptTypeString#" src="#application.baseUrl#common/libs/passiveScrollEvent/index.js"></script>
	<!-- Kendo scripts -->
	<script type="#scriptTypeString#" src="#application.kendoSourceLocation#/js/<cfif application.kendoCommercial>kendo.all.min<cfelse>kendo.ui.core.min</cfif>.js"></script>
	<!-- Note: the Kendo stylesheets are critical to the look of the site and I am not deferring them. -->
	<script type="text/javascript">
		// Kendo common css. Note: Material black and office 365 themes require a different stylesheet. These are specified in the theme settings.
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#kendoCommonCssFileLocation#') );
		// Less based theme css files.
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#kendoThemeCssFileLocation#') );
		// Mobile less based theme file.
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#kendoThemeMobileCssFileLocation#') );
	</script>
	<!-- Other  libraries  -->
	<!-- Kendo extended API (used for confirm and other dialogs) -->
	<script type="#scriptTypeString#" src="#application.kendoUiExtendedLocation#/js/kendo.web.ext.js"></script>
	<!-- Defer the extended scripts along with my notification library. Note: the blueopal and material black themes are not in the extended lib. -->
	<script type="#scriptTypeString#">
		<cfif kendoTheme neq 'blueOpal' and kendoTheme neq 'materialBlack' and kendoTheme neq 'office365'>$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.kendoUiExtendedLocation#/styles/#kendoTheme#.kendo.ext.css') );</cfif>
		// Notification .css 
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.jQueryNotifyLocation#/ui.notify.css') );
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.jQueryNotifyLocation#/notify.css') );
	</script>
	<!-- Optional libs -->
	<!-- Fontawesome css -->
	<script type="#scriptTypeString#">
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', 'https://use.fontawesome.com/releases/v5.5.0/css/all.css') );
	</script>
	<!-- Fancy box (version 2). -->
	<script type="#scriptTypeString#" src="#application.baseUrl#common/libs/fancyBox/v2/source/jquery.fancybox.js"></script>
	<!-- Defer the fancyBox css. -->
	<script type="#scriptTypeString#">
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.baseUrl#common/libs/fancyBox/v2/source/jquery.fancybox.css') );
	</script>
	<!-- Plyr (our HTML5 media player) -->
	<script type="#scriptTypeString#" src="#application.baseUrl#common/libs/plyr/plyr.js"></script>
	<!-- Defer the plyr css. -->
	<script type="#scriptTypeString#">
		$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', '#application.baseUrl#common/libs/plyr/themeCss/#kendoTheme#.css') );
	</script>
	<cfif addSocialMediaUnderEntry><!-- Go to www.addthis.com/dashboard to customize your tools --> 
	<script type="#scriptTypeString#" src="//s7.addthis.com/js/300/addthis_widget.js#chr(35)#pubid=#application.addThisApiKey#"></script></cfif>
	<!-- Scroll magic and other green sock plugins. -->
<cfif application.includeGsap>
	<!---<cfset scriptTypeString = "text/javascript">--->
	<script type="#scriptTypeString#" src="#application.baseUrl#common/libs/greenSock/src/uncompressed/TweenMax.js"></script>
	<script type="#scriptTypeString#" src="#application.baseUrl#common/libs/scrollMagic/scrollmagic/uncompressed/ScrollMagic.js"></script>
	<script type="#scriptTypeString#" src="#application.baseUrl#common/libs/scrollMagic/scrollmagic/uncompressed/plugins/animation.gsap.js"></script>
	<script type="#scriptTypeString#" src="#application.baseUrl#common/libs/greenSock/src/uncompressed/plugins/ScrollToPlugin.js"></script>
	<script type="#scriptTypeString#" src="#application.baseUrl#common/libs/scrollMagic/scrollmagic/uncompressed/plugins/debug.addIndicators.js"></script>
</cfif>	
	<!--- Some optional libraries are included at the tail end of the page. --->
	<cfsilent>
	<!---
	Removed jQuery include as they are now included in the application in the kendoScripts.cfm template (ga 10/27/2018).
	Removed launchComment(id) and launchCommentSub(id) and replaced functions with a Kendo window. (ga)
	Also removed 'tweetback' logic as it was causing errors.
	--->
	</cfsilent>
<cfelse>
	<cfinclude template="#customHeadTemplate#" />
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
<!-- Script to adjust properties depending upon the device screen size. I am putting the javascript and css front and center here in order to show exactly what I am doing. One of my main goals is to educate, and I don't want to obsfucate the code. -->
<script>
	
	// Set global vars. This is determined by the server (for now).
	isMobile = <cfoutput>#session.isMobile#</cfoutput>;
	// Get the breakpoint. This will be used to hide or show the side bar container ast the right of the page once the breakpoint value has been exceeded. The breakpoint can be set on the admin settings page. Note: the breakpoint is always set high on mobile as we don't have room for the sidebar.
	breakpoint = <cfoutput><cfif session.isMobile>50000<cfelse>#breakpoint#</cfif></cfoutput>;
	
	// Adjust the screen properties immediately.
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
		1) This may be converted into media queries in an upcoming version.
		2) This function will be invoked twice. Once upon page load, and then again when the body detects a resize. 
		3) This was designed to chose the appropriate image and maximize the size of the background image when the desktop or tablet has a wide screen size.
		
		The contentWidth applies to the header, and the outer container that holds the mainContainer and sidebar container elements. 
		Using contentWidth of 66% looks good when the screen width is at least 1600x900, which is the size of a 20 inch monitor.
		The 66% setting looks great with a 20 inch monitor. 
		80% works with 1280x768, which is a 19 inch monitor or a 14 Notebook. 
		I am adjusting the contentWidth via javascript to ensure proper rendering of the page.
		*/
		
		// Handle the sidebar and the sideBarPanels
		if (windowWidth <= breakpoint){
			// Hide the sidepanel (the responsive panel will takeover here).
			$( "#sidebar" ).hide();
			// Show the responsive panel
			$("#sidebarPanel").show(); 
			// Display the hamburger in the menu (the 5th node).
			//$(".k-menu > li:eq(4)").show();
		} else {
			// Is the sidebar hidden?
			if ($("#sidebar").is(":hidden")){
				// Display the sidebar. This should only happen when someone is readjusting their screen sizes.
				$( "#sidebar" ).show();
			}
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
		
		// If both the parent and header container widths are not null (when this function first loads), and the header does not match the width of the parent container, resize the header. The sizes may not identical as the padding expands the parent container by 20 (mobile) or 40 (desktop) pixels. I will fix this in an upcoming version.
		if (!!parentContainerWidth && !!headerContainerWidth && parentContainerWidth != headerContainerWidth){
			// alert('parentContainerWidth:' + parentContainerWidth + 'headerContainerWidth:' + headerContainerWidth);
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
    	var menu = $("#fixedNavMenu").data("kendoMenu");
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
    	var menu = $("#fixedNavMenu").data("kendoMenu");
    	// Close it.
    	menu.close();

		return false;
	}
	
	// Lazy loading images and media.
    // Define a callback function
    // to add a 'shown' class into the element when it is loaded
    var media_loaded = function (media) {
        media.className += ' shown';
    }

    // Then call the deferimg and deferiframe methods
    deferimg('img.fade', 300, 'lazied', media_loaded);
    deferiframe('iframe.fade', 300, 'lazied', media_loaded);
	
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

<cfif customBodyString eq ""><body onload="if(top != self) top.location.replace(self.location.href); setScreenProperties()" onresize="setScreenProperties()"><cfelse><cfoutput>#customBodyString#</cfoutput></cfif>
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
	<cfsilent>
	<!--- If the server has the woff2 mime type setup, we will use the next gen font format, otherwise we will fallback to the woff font. --->
	<cfif  application.serverSupportsWoff2>
		<cfset fontExtension = "woff2">
	<cfelse>
		<cfset fontExtension = "woff">
	</cfif>
	</cfsilent>
	<!--- Preload the fonts (note: this only works with woff2 fonts and probably will not work here). --->
	<style rel="preload" as="font"><cfoutput>
		/* Special fonts */
		@font-face {
			font-family: "Eras Light";
			src: url(#application.baseUrl#common/fonts/erasLight.#fontExtension#) format("#fontExtension#");
		}
		@font-face {
			font-family: "Eras Book";
			src: url(#application.baseUrl#common/fonts/erasBook.#fontExtension#) format("#fontExtension#");
		}
		@font-face {
			font-family: "Eras Bold";
			src: url(#application.baseUrl#common/fonts/erasBold.#fontExtension#) format("#fontExtension#");
		}			
		@font-face {
			font-family: "Eras Demi";
			src: url(#application.baseUrl#common/fonts/erasDemi.#fontExtension#) format("#fontExtension#");
		}
		@font-face {
			font-family: "Eras Med";
			src: url(#application.baseUrl#common/fonts/erasMed.#fontExtension#) format("#fontExtension#");
		}
		@font-face {
			font-family: "Kaufmann Script Bold";
			src: url(#application.baseUrl#common/fonts/kaufmannScriptBold.#fontExtension#) format("#fontExtension#");
		}
	</style></cfoutput>
<cfelse>
	<cfinclude template="#customFontCssTemplate#" />
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
			background-image: url(<cfoutput>#blogBackgroundImage#</cfoutput>);
			background-repeat: <cfoutput>#blogBackgroundImageRepeat#</cfoutput>;
			background-position: <cfoutput>#blogBackgroundImagePosition#</cfoutput>; /* Center the image */
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
			background-image: url(<cfoutput>#blogBackgroundImage#</cfoutput>);
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
				
		/* Decrease the size of the h1 tag */
		h1 {
			font-size: <cfif session.isMobile>14<cfelse>18</cfif>pt;
		}
		

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
	<cfinclude template="#customGlobalAndBodyCssTemplate#" />
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
			display: none; /*Hidden does not work */
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
		<!--- Logic to determine what side the padding should occur when the alignBlogMenuWithBlogContent argument is true. --->
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
			/* Todo: fix the padding issue. This code does not work as the blogContent is padded which stretches the mainPanel container.
			Match the padding of the parent container (20 or 40 pixels). 
			padding-left: <cfif session.isMobile>20<cfelse>40</cfif>px;
			padding-right: <cfif session.isMobile>20<cfelse>40</cfif>px;
			*/
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
			/* Hide the menu on page load */
			visibility: hidden;
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
		
		/* Apply a little bit of padding to the bars icon */
		.toggleSidebarPanelButton {
			padding-left: 7px;
		}
		
		.siteSearchButton {
			/* Set the site search icon to match the blog text color 
			color: <cfoutput>#blogNameTextColor#</cfoutput>; 
			*/
		}
		
		/* Remove the vertical border. The borders display a vertical line between the menu items and since we have custom images and colors on the banners, I want to remove these. */
		.k-widget.k-menu-horizontal>.k-item {
		  border: 0;
		}
			
		/* Fixed nav menu */
		#fixedNavMenu {
			/* Hide the menu on page load */
			visibility: hidden;
		}
		
	<cfif kendoTheme eq 'default' or kendoTheme eq 'highcontrast' or kendoTheme eq 'material' or kendoTheme eq 'silver'><!--- Both default and high contrast have the same header. Material needs to have a darker text when selecting a menu item--->
		/* fixedNavMenu states. */
		#fixedNavMenu.k-menu .k-state-hover,
		#fixedNavMenu.k-menu .k-state-hover .k-link,
		#fixedNavMenu.k-menu .k-state-border-down
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
		
		/* Adjust the padding of the menu to try to evenly distribute the search and hamburger icons across devices. */
		.k-menu .k-item>.k-link {
			padding-left: <cfif session.isMobile>.7em<cfelse>1.1</cfif>;/* The default Kendo setting is 1.1em */
			padding-right: <cfif session.isMobile>.7em<cfelse>1.1</cfif>;
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
	<cfinclude template="#customTopMenuCssTemplate#" />
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
		.blogPost p.postDate {
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

		.blogPost p.postDate span.month {
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

		.blogPost p.postDate span.day {
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

		.blogPost p.postAuthor span.info {
		  /* margin-top: 10px; */
		  display: block;
		}

		.blogPost p.postAuthor {
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
				
		.innerContentContainer {
			/* Apply padding to all of the elements within a blog post. */
			margin-top: 5px; 
			padding-left: <cfif session.isMobile>10<cfelse>20</cfif>px; 
			padding-right: <cfif session.isMobile>10<cfelse>20</cfif>px;
			display:block;
		}

		.postContent {
			/* Apply padding to post content. */
			margin-top: 5px; 
			display: block;

		}
		
		/* Constraining images to a max width so that they don't push the content containers out to the right */
		.entryImage img {
			max-width: 100%;
			height: auto; 
			/* Subtle drop shadow on the image layer */
			box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2), 0 6px 20px 0 rgba(0, 0, 0, 0.19);
		}
		
		/* Lazy loading image classes */
		/* hide the element with opacity is set to 0 */
		.fade {
			transition: opacity 500ms ease-in-out;
			opacity: 0;
		}

		/* show it with the 'shown' class */
		.fade.shown {
			opacity: 1;
			background: 0 0;
		}
		
		/* Sidebar elements */
		#sidebar {
			/* We are going to eliminate this sidebar for small screen sizes and mobile. */
			/* todo hide this on mobile. */
			display: <cfif session.isMobile>none<cfelse>table-cell</cfif>;
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
			/* Hide the sidebarPanel */
			visibility: hidden;
			flex-direction: column;
		<cfif not session.isMobile>/* On desktop, we want the sidebar panel to also scroll with the page. Otherwise, the padding that places it underneath the header is disruped and it looks wierd. */
			position: absolute;
		</cfif>
    		height: 100%;
    		width: <cfif session.isMobile>275px<cfelse>425px</cfif>;
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
		
		video {
		  max-width: 100%;
		  height: auto;
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
			color: <cfif darkTheme>whitesmoke<cfelse>#2e2e2e</cfif>;
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis;
		}

		/* Other than the recent comment pod, don't wrap pod content, and if the text exceeds the size of the html tables, ellipsis the text (like so 'and...')  */
		.fixedPodTableWithWrap td {
			color: <cfif darkTheme>whitesmoke<cfelse>#2e2e2e</cfif>;
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
		.constrainerTable {
			/* The parent element (this table) should be positioned relatively. */
			position: relative;
			/* Now that the parent element has a width setting, make sure that the width does not ever exceed this */
			max-width: 100%;
		}	
		
		/* Helper function to the constrainerTable to break the text when it exceeds the table dimensions */
		.constrainerTable .constrainContent {
			/* Use the root width var */
			width: var(--contentWidth);
			max-width: 100%
		}
		
		.constrainerTable th {
			max-width: var(--contentWidth);
		}
		
		.constrainerTable td {
			word-break: break-word;
		}
		
		.spacer {
			display: inline-block;
			width: 100%;
		}
		
		/* Used to force a cell to only use the space that is necessary to fit it's content */
		td.fitwidth {
			width: 1%;
			white-space: nowrap;
		}
		
		/* Remove the padding of the li elements when using the disqus recent comments widget. */
		#removeUlPadding ul  {
			padding: 0;
			list-style-type: none;
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
	<cfinclude template="#customBlogContentCssTemplate#" />
</cfif>
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Top menu html
	//***************************************************************************************************************************************************--->
	</cfsilent>
<cfif customTopMenuHtmlTemplate eq "">
	<cfset divName = "fixedNavMenu">
	<header>
	<!--- This container will be displayed when the user scrolls down past the header. It is intended to allow for navigation when the user is down the page.--->
	<div id="fixedNavHeader">
		<cfif customTopMenuJsTemplate eq "">
			<cfinclude template="includes/layers/topMenu.cfm">
		<cfelse>
			<cfinclude template="#customTopMenuJsTemplate#" />
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
						<cfoutput><img src="#logoSourcePath#" style="padding-left: 10px;" align="left" valign="center" alt="Header Logo"/></cfoutput>
					</td>
					<td id="blogNameContainer">
						<cfoutput>#htmlEditFormat(application.blog.getProperty("blogTitle"))#</cfoutput>
					</td>
				</tr>
				<tr>
					<td id="topMenuContainer" colspan="2"><!-- Holds the menu. -->
					<cfsilent>
					<!---//**************************************************************************************************************************************************
								Top menu javascript (controls the menu at the top of the page)
					//***************************************************************************************************************************************************--->
					</cfsilent>
					<cfset divName = "topMenu">
					<cfif customTopMenuJsTemplate eq "">
						<cfinclude template="includes/layers/topMenu.cfm">
					<cfelse>
						<cfinclude template="#customTopMenuJsTemplate#" />
					</cfif>	
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
						<cfoutput><img src="#logoSourcePath#" style="padding-left: 20px;" align="left" valign="center" alt="Logo"/></cfoutput>
					</td>
					<td id="blogNameContainer">
						<cfoutput>#htmlEditFormat(application.blog.getProperty("blogTitle"))#</cfoutput>
					</td>
				</tr>
				<tr>
				  <td id="topMenuContainer" height="55px"><!-- Holds the menu. -->
					<cfsilent>
					<!---//**************************************************************************************************************************************************
								Top menu javascript (controls the menu at the top of the page)
					//***************************************************************************************************************************************************--->
					</cfsilent>
					<cfset divName = "topMenu">
					<cfif customTopMenuJsTemplate eq "">
						<cfinclude template="includes/layers/topMenu.cfm">
					<cfelse>
						<cfinclude template="#customTopMenuJsTemplate#" />
					</cfif>	
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
	<cfset divName = "fixedNavMenu">
	<cfinclude template="#customTopMenuHtmlTemplate#" />
</cfif>
	<!-- End header -->
	
	<cfsilent>
	<!---//**************************************************************************************************************************************************
				Javascripts for the blog's Kendo widgets and UI interactions.
	//***************************************************************************************************************************************************--->
	</cfsilent>
	
<cfif customBlogJsContentTemplate eq "">
	<!---Defer this script --->
	<script type="<Cfoutput>#scriptTypeString#</cfoutput>">	
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
				var windowTitle = "Download Galaxie Blog";
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
				content: "<cfoutput>#application.baseUrl#</cfoutput>about.cfm?aboutWhat=" + Id,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
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
				content: "<cfoutput>#application.baseUrl#</cfoutput>search.cfm",// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
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
				content: "<cfoutput>#application.baseUrl#</cfoutput>searchResults.cfm?searchTerm=" + searchTerm + "&category=" + category,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
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
		
		// Note: comments are either provided with the Galaxi Blog interface, or disqus. We need to open up new kendo windows for each interface.
	<cfif application.includeDisqus>
		// Disqus comment window ---------------------------------------------------------------------------------------------------------------------------------
		function createDisqusWindow(Id, alias, url) {

			// Remove the window if it already exists
			if ($("#disqusWindow").length > 0) {
				$("#disqusWindow").parent().remove();
			}


			// Typically we would use a div outside of the script to attach the window to, however, since this is inside of a function call, we are going to dynamically create a div via the append js method. If we were to use a div outside of this script, lets say underneath the 'mainBlog' container, it would cause wierd problems, such as the page disappearing behind the window.
			$(document.body).append('<div id="disqusWindow"></div>');
			$('#disqusWindow').kendoWindow({
				title: "Comments",
				actions: [<cfoutput>#kendoWindowIcons#</cfoutput>],
				modal: false,
				resizable: <cfif session.isMobile>false<cfelse>true</cfif>,
				draggable: <cfif session.isMobile>false<cfelse>true</cfif>,
				// For desktop, we are subtracting 5% off of the content width setting found near the top of this template.
				width: <cfif session.isMobile>getContentWidthPercent()<cfelse>(getContentWidthPercentAsInt()-5 + '%')</cfif>,
				height: "<cfif session.isMobile>95<cfelse>60</cfif>%",
				iframe: false, // Don't use iframes unless it is content derived outside of your own site. 
				content: "<cfoutput>#application.baseUrl#</cfoutput>disqus.cfm?id=" + Id + '&alias=' + alias + '&url=' + url,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
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
					$('#disqusWindow').kendoWindow('destroy');
				}
			</cfif>
			}).data('kendoWindow').center();
		}//..function createDisqusWindow(Id, alias, url) {
		
		// The mobile app has a dedicated button to close the window as the x at the top of the window is small and hard to see 
		function closeDisqusWindow(){
			$("#disqusWindow").kendoWindow();
			var disqusWindow = $("#disqusWindow").data("kendoWindow");
			setTimeout(function() {
			  disqusWindow.destroy();
			}, 500);
		}
	</cfif><!---<cfif application.includeDisqus>--->
		// Add comment window (note: even when including Disqus, this must be here as it is used for the contact form. ------------------------------------------------
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
				content: "<cfoutput>#application.baseUrl#</cfoutput>addCommentSubscribe.cfm?id=" + Id + '&uiElement=' + uiElement,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
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
				content: "<cfoutput>#application.baseUrl#</cfoutput>addThis.cfm?id=" + Id,// Make sure to create an absolute path here. I had problems with a cached index.cfm page being inserted into the Kendo window probably due to the blogCfc caching logic. 
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
				// Use a try block. 
				try {
					// Set the elements that we are going to modify.
					var spanElement = "#commentControl" + entryId;
					var spanLabelElement = "#commentControlLabel" + entryId;
					// Remove the down arrow.
					$(spanElement).removeClass("k-i-sort-desc-sm").addClass('k-i-sort-asc-sm');
					// Add the up arrow.
					$(spanElement).addClass("k-i-sort-asc-sm").addClass('k-i-sort-asc-sm');
					// Change the text of the label
					$(spanLabelElement).text("Hide Comments");
					// Expand the table. See 'fx effects' on the Terlik website.
					kendo.fx($("#comment" + entryId)).expand("vertical").play();
				} catch(e){
					// Do nothing. There is a style error that occurs on rare occassions but it does not affect the functionality of the site ('Cannot read property 'style' of undefined').
				}
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
		// Invoked via the addCommentSubscribe.cfm window after Kendo validation occurs.
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
		// Invoked via the addCommentSubscribe.cfm window after Kendo validation occurs.
		function subscribeToBlog(sideBarType){
			if (sideBarType == 'div'){
				subscribeFormName = 'subscribeViaDiv';
			} else {
				subscribeFormName = 'subscribeViaPanel';
			}

			// Get the email address that was typed in.
			var email = $( "#" + subscribeFormName ).val();
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
			// Expand the commens
			// When the ascending arrow is clicked on...
			$(".flexParent").on("click", "span.k-i-sort-desc-sm", function(e) {	
				// We need to get the associated entryId to properly expand the right containter. Here, we will get the id of this emement. It should be commentControl + entryId. 
				var clickedSpan = $(this).attr('id');
				// Remove the 'commentControl' string from the id to just get the Id.
				var entryId = clickedSpan.replace("commentControl", "");
				// The content element's id will be 'comment' + entryId 
				var contentElement = 'comment' + entryId;
				// We also want to change the label. The lable has the entryId appended to it as well.
				var spanLabelElement = "#commentControlLabel" + entryId;
				// Change the label text
				$(spanLabelElement).text("Hide Comments");
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
				// We also want to change the label. The lable has the entryId appended to it as well.
				var spanLabelElement = "#commentControlLabel" + entryId;
				// Change the label text
				$(spanLabelElement).text("Show Comments");
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
	<script type="<Cfoutput>#scriptTypeString#</cfoutput>">
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
	<cfinclude template="#customBlogJsContentTemplate#" />
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
		<!--- This is the sidebar responsive navigation panel that is triggered when the screen gets to a certain size. It is a duplicate of the sidebar div above, however, I can't properly style the sidebar the way that I want to within the blog content, so it is duplicated withoout the styles here. --->
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
               		<cfsilent>
					<!--- If the application.serverRewriteRuleInPlace variable has been set to true, we need to eliminate 'index.cfm' from the blog post link. --->
					<cfif application.serverRewriteRuleInPlace>
						<cfset entryLink = replaceNoCase(application.blog.makeLink(id), '/index.cfm', '')>
					<cfelse>
						<cfset entryLink = application.blog.makeLink(id)>
					</cfif>
						
					<!--- We need to perform the same logic for the post author (remove the 'index.cfm' string when a rewrite rule is in place). --->
					<cfif application.serverRewriteRuleInPlace>
						<cfset userLink = replaceNoCase(application.blog.makeUserLink(name), '/index.cfm', '')>
					<cfelse>
						<cfset userLink = application.blog.makeUserLink(name)>
					</cfif>
						
					<!--- Set the entryId. We will use this to identify the rows.--->
                	<cfset entryid = id>
						
					</cfsilent>
					<div class="blogPost widget k-content">
						<span class="innerContentContainer">
							<h1 class="topContent">
								<a href="#entryLink#" aria-label="#title#" class="k-content">#title#</a>
							</h1>

							<p class="postDate">
								<!-- We are using Kendo's 'k-primary' class to render the primary accent color background. The primay color is set by the theme that is declared. -->
								<span class="month k-primary">#dateFormat(posted, "mmm")#</span>
								<span class="day k-alt">#day(posted)#</span>
							</p>

							<p class="postAuthor">
								<span class="info">
									<cfif len(name)>by <a href="#userLink#" aria-label="#userLink#" class="k-content">#name#</a></cfif> 
									<cfset lastid = listLast(structKeyList(categories))>
									<cfloop item="catid" collection="#categories#">
									<cfsilent>
									<!--- We need to perform the same logic for the post author (remove the 'index.cfm' string when a rewrite rule is in place). --->
									<cfif application.serverRewriteRuleInPlace>
										<cfset categoryLink = replaceNoCase(application.blog.makeCategoryLink(catid), '/index.cfm', '')>
									<cfelse>
										<cfset categoryLink = application.blog.makeCategoryLink(catid)>
									</cfif>
									</cfsilent>
									<a href="#categoryLink#" aria-label="#categoryLink#" class="k-content">#categories[currentRow][catid]#</a><cfif catid is not lastid>, </cfif>
									</cfloop>
								</span>
							</p>
										
							<!-- Post content --> 
							<span class="postContent">	
							<cfsilent>
								<!--- Inspect the post entry  for reserved xmlKeywords. --->
								<cfset xmlKeywords = inspectPostContentForXmlKeywords(#application.blog.renderEntry(body,false,enclosure)#)>
								<!--- //**************************************************************************************************************************************************
								Use a cfinclude
								//****************************************************************************************************************************************************--->
								<!--- Use a cfinclude if the include xml keyword is present. --->
								<cfif findNoCase("cfincludeTemplate", xmlKeywords) gt 0>
									<cfset includeTemplate = true>
									<!--- Get the path that is in the xml in the post. --->
									<cfset cfincludeTemplatePath = getXmlKeywordValue(application.blog.renderEntry(body,false,enclosure), 'cfincludeTemplate')>
								<cfelse>
									<cfset includeTemplate = false>
								</cfif>
									
								<!--- //**************************************************************************************************************************************************
								Video and Audio Content
								//****************************************************************************************************************************************************--->
								<cfparam name="videoType" default="" type="string">
								<cfparam name="videoPosterImageUrl" default="" type="string">
								<cfparam name="smallVideoSourceUrl" default="" type="string">
								<cfparam name="mediumVideoSourceUrl" default="" type="string">
								<cfparam name="largeVideoSourceUrl" default="" type="string">
								<cfparam name="videoCaptionsUrl" default="" type="string">

								<!--- Overwrite the vars if the proper xml is embedded in the post. The xml keyword thing is temporary and will be put into the database in the future. --->
								<cfif findNoCase("videoType", xmlKeywords) gt 0> 
									<cfset videoType = getXmlKeywordValue(articles.body, 'videoType')>
								</cfif>
								<cfif findNoCase("videoPosterImageUrl", xmlKeywords) gt 0> 
									<cfset videoPosterImageUrl = getXmlKeywordValue(articles.body, 'videoPosterImageUrl')>
								</cfif>	
								<cfif findNoCase("smallVideoSourceUrl", xmlKeywords) gt 0> 
									<cfset smallVideoSourceUrl = getXmlKeywordValue(articles.body, 'smallVideoSourceUrl')>
								</cfif>
								<cfif findNoCase("mediumVideoSourceUrl", xmlKeywords) gt 0> 
									<cfset mediumVideoSourceUrl = getXmlKeywordValue(articles.body, 'mediumVideoSourceUrl')>
								</cfif>
								<cfif findNoCase("largeVideoSourceUrl", xmlKeywords) gt 0> 
									<cfset largeVideoSourceUrl = getXmlKeywordValue(articles.body, 'largeVideoSourceUrl')>
								</cfif>
								<cfif findNoCase("videoCaptionsUrl", xmlKeywords) gt 0> 
									<cfset videoCaptionsUrl = getXmlKeywordValue(articles.body, 'videoCaptionsUrl')>
								</cfif>
								<cfif findNoCase("videoCrossOrigin", xmlKeywords) gt 0> 
									<cfset videoCrossOrigin = getXmlKeywordValue(articles.body, 'videoCrossOrigin')>
								</cfif>
							</cfsilent>
							<cfif includeTemplate>
								<!--- Include the specified template. --->
								<cfinclude template="#cfincludeTemplatePath#">
							</cfif>
							<cfsilent>
								<!--- Reset the includeTempate var--->
								<cfset includeTemplate = false>
								<cfset cfincludeTemplatePath = "">
								<!--- Check to see if we need to modify remove hard coded mainEntityOfPage code blocks when in blog mode. We don't want the mainEnityOfPage there unless we are reading a single post. --->
							
								<!--- Set our blog content. We need to remove all of the quasi xml ---> 
								<cfset postContent = removeXmlKeyWordContentFromPost(application.blog.renderEntry(body,false,enclosure), xmlKeywords)>
							
								<!--- See if we need to eliminate the indivual post ld json scripts when in blog mode. This is necessary as there will be multiple posts that will conflict with the blog ld script. I have tested verarious methods and found out that this is necessary, otherwise you might have a rich google snippet that has no relation to the blog page (such as a recipe rich snippet being made on a blog post). This is what yoast does on their main blog page. --->
								<cfif getPageMode() eq 'blog' and postContent contains 'application/ld+json'>
									<cfset postContent = replaceStringInContent(postContent, '<script type="application/ld+json">', '</script>')>
								</cfif>

								<!---//**************************************************************************************************************************************************
											Media Player
								//*******************************************************************************************************************************************************
								HTML5 supported media will be handled by plyr by default, or the jQjuery Kendo video player. Supported formats are mp3, mp4, ogg, ogv, and webm. Note: the Kendo media player is only availabe in the proffesional edition.
								--->
								</cfsilent>
							
							<cfif (enclosure contains ".mp3" or enclosure contains ".mp4" or enclosure contains ".ogg" or enclosure contains ".ogv" or enclosure contains ".webm"
								  or videoType contains ".mp3" or videoType contains ".mp4" or videoType contains ".ogg" or videoType contains ".ogv" or videoType contains ".webm")>
								<br/>	
								<cfif application.kendoCommercial and application.defaultMediaPlayer eq 'KendoUiPlayer'>
								<div class="k-content wide">
									<div id="mediaplayer#currentRow#" class="mediaPlayer"></div>
									<script type="#scriptTypeString#">
										$(document).ready(function () {

											$("#chr(35)#mediaplayer#currentRow#").kendoMediaPlayer({
												autoPlay: false,
												navigatable: true,
												media: {
													title: "#title#",
													source: "#application.baseUrl#enclosures/#getFileFromPath(enclosure)#" 
												}
											});
										});
									</script>
								</div><!---<div class="k-content">--->
								<cfelse><!---<cfif application.kendoCommercial and application.defaultMediaPlayer eq 'KendoUiPlayer'>--->
								<cfsilent>
								<!--- Preset the videoCrossOrigin var to false if it is not already set. --->
								<cfif not isDefined("videoCrossOrigin")>
									<cfset videoCrossOrigin = false>
								<cfelseif videoCrossOrigin eq "true">
									<cfset videoCrossOrigin = true>
								<cfelse>
									<cfset videoCrossOrigin = false>
								</cfif>
								</cfsilent>
								<div id="mediaplayer#currentRow#" class="mediaPlayer">
									<video
										controls
										<cfif videoCrossOrigin>crossorigin</cfif>
										playsinline
										<cfif videoPosterImageUrl neq ''>poster="#videoPosterImageUrl#"</cfif>
										id="player#currentRow#"
										class="lazy">
										<!-- Video files -->
										<cfif smallVideoSourceUrl neq "">
										<source
											src="#smallVideoSourceUrl#"
											type="video/mp4"
											size="576"
										/>
										</cfif>
										<cfif mediumVideoSourceUrl neq "">
										<source
											src="#mediumVideoSourceUrl#"
											type="video/mp4"
											size="720"
										/>
										</cfif>
										<cfif largeVideoSourceUrl neq "">
										<source
											src="#largeVideoSourceUrl#"
											type="video/mp4"
											size="1080"
										/>
										</cfif>
										<cfif videoCaptionsUrl neq "">
										<!-- Caption files -->
										<track
											kind="captions"
											label="English"
											srclang="en"
											src="#videoCaptionsUrl#"
											default
										/>
										</cfif>
										<cfif smallVideoSourceUrl neq "">
										<!-- Fallback for browsers that don't support the <video> element -->
										<a href="#smallVideoSourceUrl#" download>Download</a>
										</cfif>
									</video>
								</div>
								<!--- Reset the video type arg. --->
								<cfset videoType = "">
								</cfif><!---<cfif application.kendoCommercial and application.defaultMediaPlayer eq 'KendoUiPlayer'>--->
							</cfif><!---<cfif (enclosure contains ".mp3" or enclosure contains ".mp4" or enclosure contains ".ogg" or enclosure contains ".ogv" or enclosure contains ".webm")>--->
									
							<!--- You Tube videos --->
							<cfif findNoCase("youTubeUrl", xmlKeywords) gt 0>
								<cfset youTubeUrl = myTrim(getXmlKeywordValue(articles.body, 'youTubeUrl'))>
								<script type="#scriptTypeString#">
									const mediaplayer#currentRow#Options = {
									  // Autoplay when in post mode. Don't autoplay in blog mode.
									  autoplay: <cfif getPageMode() eq 'post'>true<cfelse>false</cfif>,
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
							</cfif>

							<!--- Vimeo videos --->
							<cfif findNoCase("vimeoVideoId", xmlKeywords) gt 0>
								<cfset vimeoVideoId = myTrim(getXmlKeywordValue(articles.body, 'vimeoVideoId'))>
								<script type="#scriptTypeString#">
									const mediaplayer#currentRow#Options = {
									  // Autoplay when in post mode. Don't autoplay in blog mode.
									  autoplay: <cfif getPageMode() eq 'post'>true<cfelse>false</cfif>,
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
							</cfif>
								
							<cfsilent>
							<!---//**************************************************************************************************************************************************
											Render Post Content
							//***************************************************************************************************************************************************--->
							</cfsilent>
							#postContent#		
							<!-- Handle any posts that have the content broken into two sections written in the entry editor using the '</more>' tag. This is a neat feature allows the administrator to condense the entry for the front page and create a link to the full post. -->
							<cfif len(morebody) and getPageMode() neq 'post'><!--- Chjanged logic. Old logic prior to version 1.45 was: and url.mode is not "entry"--->
								<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="location.href='#entryLink###more';">
									<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
									<i class="fas fa-chevron-circle-down" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;More...
								</button>
							<!-- We are looking at the actual post. -->
							<cfelseif len(morebody)>
								#application.blog.renderEntry(morebody)#
							</cfif>
							</span><!--<span class="postContent">--> 
									
							<p class="bottomContent">
								
							<cfsilent>
							<!--- ***********************************************************************************************************
								Related entries
							*************************************************************************************************************--->
							</cfsilent>
							<cfset qRelatedBlogEntries = application.blog.getRelatedBlogEntries(entryId=id,bDislayFutureLinks=true) />	
							<cfif qRelatedBlogEntries.recordCount>
								<div name="relatedentries">
								<h3 class="topContent">Related Entries</h3>
								<ul name="relatedEntriesList">
								<cfloop query="qRelatedBlogEntries">
								<cfsilent>
								<!--- Is there a URL rewrite rule in place? If so, we need to eliminate the 'index.cfm' string from all of our links. A rewrite rule on the server allows the blog owners to to obsfucate the 'index.cfm' string from the URL. This setting is in the application.cfc template. --->
								<cfif application.serverRewriteRuleInPlace>
									<cfset relatedEntryUrl = replaceNoCase(application.blog.makeLink(entryId=qRelatedBlogEntries.id), '/index.cfm', '')>
								<cfelse>
									<cfset relatedEntryUrl = application.blog.makeLink(entryId=qRelatedBlogEntries.id)>
								</cfif>
								</cfsilent>
								<li><a href="#relatedEntryUrl#" aria-label="#qRelatedBlogEntries.title#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#qRelatedBlogEntries.title#</a></li>
								</cfloop>			
								</ul>
								</div>
							</cfif>
							<cfsilent>
							<!--- ***********************************************************************************************************
								Comment interfaces (Disqus and Galaxie Blog)
							*************************************************************************************************************--->
							</cfsilent>
							
							<cfif application.includeDisqus>
								<cfif url.mode neq "alias">
										<button id="disqusCommentButton" class="k-button" style="#kendoButtonStyle#" onClick="createDisqusWindow('#entryId#', '#alias#', '#entryLink#')">
											<i class="fas fa-comments" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Comment
										</button>
									<cfif not addSocialMediaUnderEntry>
										<!--- Don't display the share button when reading a single entry. --->
										<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="createMediaShareWindow('#id#');">
											<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
											<i class="fas fa-share" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Share
										</button>
									</cfif><!---<cfif not addSocialMediaUnderEntry>--->
								</cfif><!---<cfif url.mode neq "alias">--->
										<p>This entry was posted on #dateFormat(posted, "mmmm d, yyyy")# at #timeFormat(posted, "h:mm tt")# and has received #views# views. </p>
										<!--- The number of comments will be provided with the code below. --->
										<p><a class="disqus-comment-count" data-disqus-url="#entryLink#" onClick="createDisqusWindow('#entryId#', '#alias#', '#entryLink#')"></a></p>
							<cfelse><!---<cfif application.includeDisqus>--->
										<!-- Button navigation. -->
										<!-- Set a smaller font in the kendo buttons. Note: adjusting the .k-button class alone also adjusts the k-input in the multi-select so we will set it here.-->
										<button id="addCommentButton" class="k-button" style="#kendoButtonStyle#" onClick="createAddCommentSubscribeWindow('#id#', 'addComment', #session.isMobile#)">
											<i class="fas fa-comments" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Comment
										</button>

										<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="createAddCommentSubscribeWindow('#id#', 'subscribe', #session.isMobile#)">
											<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
											<i class="fas fa-envelope-open-text" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Subscribe
										</button>

									<cfif not addSocialMediaUnderEntry>
										<!--- Don't display the share button when reading a single entry. --->
										<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="createMediaShareWindow('#id#');">
											<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
											<i class="fas fa-share" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Share
										</button>
									</cfif>		
										<!-- The print button is not needed for mobile.-->
									<cfif not session.isMobile>
										<button type="button" class="k-button" style="#kendoButtonStyle#" onClick="location.href='#thisUrl#/print.cfm?id=#id#';">
											<!--- Use a font icon. There needs to be hard coded non breaking spaces next to the image for some odd reason. A simple space won't work.--->
											<i class="fas fa-print" style="alignment-baseline:middle;"></i>&nbsp;&nbsp;Print
										</button>
									</cfif><!---<cfif not session.isMobile>--->
										<p>This entry was posted on #dateFormat(posted, "mmmm d, yyyy")# at #timeFormat(posted, "h:mm tt")# and has received #views# views. </p>
										<h3 class="topContent">Comments</h3>
										<p>There are currently <cfif commentCount is "">0<cfelse>#commentCount#</cfif> comments.</p> 
									<cfif len(enclosure)><a href="#thisUrl#/enclosures/#urlEncodedFormat(getFileFromPath(enclosure))#" aria-label="Download attachment" class="k-content">Download attachment.</a></cfif>
									<!--- Span to hold the little arrow. Note: the order of the spans in the code are different than the actual display. We need to reverse the order for proper display. We are not going to display this if there are no comments. --->
									<cfif len(commentCount) gt 0>
										<span id="commentControl#entryId#" class="collapse k-icon k-i-sort-desc-sm k-primary" style="width: 35px; height:35px; border-radius: 50%;"></span>&nbsp;&nbsp;<span id="commentControlLabel#entryId#">Show Comments</span><br/><br/>
									</cfif><!---<cfif len(commentCount) gt 0>--->
							</cfif><!---<cfif application.includeDisqus>---> 
								
								<cfsilent>
								<!--- ***********************************************************************************************************
									Disqus - load disqus if we are in looking at an individual entry
								*************************************************************************************************************--->
								</cfsilent>
								<cfif application.includeDisqus and url.mode eq "alias">
									<div id="disqus_thread"></div>
									<script type="deferjs">
										/**
										*  RECOMMENDED CONFIGURATION VARIABLES: EDIT AND UNCOMMENT THE SECTION BELOW TO INSERT DYNAMIC VALUES FROM YOUR PLATFORM OR CMS.
										*  LEARN WHY DEFINING THESE VARIABLES IS IMPORTANT: https://disqus.com/admin/universalcode/#chr(35)#configuration-variables*/
										/*
										var disqus_config = function () {
										var disqus_shortname = '#alias#';
										this.page.url = #entryLink#;  // Replace PAGE_URL with your page's canonical URL variable
										this.page.identifier = #entryId#; // Replace PAGE_IDENTIFIER with your page's unique identifier variable
										};
										*/
										(function() { // DON'T EDIT BELOW THIS LINE
											var d = document, s = d.createElement('script');
											s.src = 'https://gregorys-blog.disqus.com/embed.js';
											s.setAttribute('data-timestamp', +new Date());
											(d.head || d.body).appendChild(s);
										})();
									</script>
								</cfif><!---<cfif application.includeDisqus and url.mode eq "alias">--->


							<cfsilent>
							<!--- ***********************************************************************************************************
								Original comments interface (non Disqus).
							*************************************************************************************************************--->
							</cfsilent>
							
							<cfif len(commentCount) gt 0 and not application.includeDisqus>
								<!-- Comments that are shown when the user clicks on the arrow button to open the container. -->
								<div id="comment#entryId#" class="widget k-content" style="display:none;">         
									<table cellpadding="3" cellspacing="0" border="0" class="fixedCommentTable">
									 <tr width="100%">
									 <cftry>
									 <cfset comments = application.blog.getComments(id)>
									 <cfloop query="comments">
									 <!---Note: the URL is appended with an extra 'c' in front of the commentId.--->
									 <tr id="c#id#" name="" class="<cfif currentRow mod 2>k-content<cfelse>k-alt</cfif>">
										<td class="fixedCommentTableContent">
											 <a class="comment-id" href="#application.blog.makeLink(entryid)###c#id#" aria-label="Comment by #name#" class="k-content">###currentRow#</a> by <b>
											 <cfif len(comments.website)>
												<a href="#comments.website#" aria-label="#name#" rel="nofollow">#name#</a>
											 <cfelse>
												#name#
											 </cfif></b> 
											 on #application.localeUtils.dateLocaleFormat(posted,"short")# - #application.localeUtils.timeLocaleFormat(posted)#</p>
										</td>
									 <tr class="<cfif currentRow mod 2>k-content<cfelse>k-alt</cfif>">
										<td>
											<img src="https://www.gravatar.com/avatar/#lcase(hash(lcase(email)))#?s=64&amp;r=pg&amp;d=#thisUrl#/images/defaultAvatar.gif" title="#name#'s Gravatar" alt="#name#'s Gravatar" border="0" class="avatar avatar-64 photo" height="64" width="64" align="left" style="padding: 5px"  />
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
						</cfif><!---<cfif application.includeDisqus>--->

						</span><!---<span class="innerContentContainer">--->
					</div><!---<div class="blogPost">--->
				</cfoutput><!---<cfoutput query="articles">--->
				<a href="#chr(35)#" id="pagerAnchor" aria-label="Pager+"></a>
				<cfsilent>
				<!--- ***********************************************************************************************************
					Add social media icons when there is only one entry
				*************************************************************************************************************--->
				</cfsilent>
				<cfif addSocialMediaUnderEntry>
				<p class="bottomContent">
					<!-- Go to www.addthis.com/dashboard to customize your tools --> 
					<script type="text/javascript" src="//s7.addthis.com/js/300/addthis_widget.js#pubid=<cfoutput>#application.addThisApiKey#</cfoutput>"></script>
					<div class="<cfoutput>#application.addThisToolboxString#</cfoutput>"></div>
				</p>
				</cfif>
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
						<script  type="#scriptTypeString#">
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
					<div class="blogPost widget k-content" style="font-weight: bold;">
						<span class="innerContentContainer">
							<h1 class="topContent">
								No Entries
							</h1> 
							<span class="postContent">
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
						</span><!---<span class="innerContentContainer">--->
					</div><!---<div class="blogPost">--->
				</cfif><!---<cfif articles.recordcount eq 0>--->
			</div><!---blogContent--->
			
			<!--- Side bar is to the right of the main panel container. It is also used as a responsive panel below when the screen size is small. --->
			<div id="sidebar">
				<!---Suppply the sideBarType argument before loading the side bar--->
				<cfmodule template="includes/layers/sidebar.cfm" sideBarType="div" scriptTypeString="#scriptTypeString#" kendoTheme="#kendoTheme#" darkTheme="#darktheme#">
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
			<cfmodule template="includes/layers/sidebar.cfm" sideBarType="panel" scriptTypeString="#scriptTypeString#" kendoTheme="#kendoTheme#" darkTheme="#darktheme#">
		</div>
	</nav><!---<nav id="sidebar">--->

	<!--- This script must be placed underneath the layer that is being used in order to effectively work as a flyout menu.--->
	<script type="<cfoutput>#scriptTypeString#</cfoutput>">
		$(document).ready(function() {	
			$("#sidebarPanel").kendoResponsivePanel({
				// On mobile devices, always achieve the breakpoint (50,000 pixels should do it!), otherwise, use the breakpoint setting that is defined in the administrative interface.
				breakpoint: breakpoint,
				orientation: "left",
				autoClose: true,// Note: autoclose true will cause the panel to fly off to the left. It looks a bit funny, but it works.. 
				open: onSidebarOpen,
				close: onSidbarClose
			})
		});//..document.ready
		
		function onSidebarOpen(){
			// Change the value of the hidden input field to keep track of the state. We need some lag time and need to wait half of a second in order to allow the form to be changed, otherwise, we can't keep an accurate state and the panel will always think that the panel is closed and always open when you click on the button.
			// Display the sidebar 
			$('#sidebarPanel').fadeTo(0, 500, function(){
				$('#sidebarPanel').css('visibility','visible'); 
				// Set the state
				$('#sidebarPanelState').val("open");
			}); // duration, opacity, callback
		}
		
		// Event handler for close event for mobile devices. Note: this is not consumed with desktop devices.
		function onSidbarClose(){
			// Hide the sideBar
			$('sidebarPanel').css("visibility", "hidden"); 
			$('#sidebarPanel').fadeTo(500, 0, function(){
				// Change the value of the hidden input field to keep track of the state.
				$('#sidebarPanelState').val("closed");
			}); // duration, opacity, callback
		};

		// Function to open the side bar panel. We need to have the name of the div that is consuming this in order to adjust the top padding.
		function toggleSideBarPanel(layer){
			// Determine if we should open or close the sidebar.
			if (getSidebarPanelState() == 'open'){
				// On desktop, set visibility to hidden, otherwise there will be an animation on desktop devices that just looks wierd.
				if (!isMobile){
					$('#sidebarPanel').css("visibility", "hidden"); 
				}
				// Close the sidebar
				$("#sidebarPanel").kendoResponsivePanel("close");
				// Change the value of the hidden input field to keep track of the state.
				$('#sidebarPanelState').val("closed");
			} else { //if ($('#sidebarPanel').css('display') == 'none'){ 
				// Set the padding.
				setSidebarPadding(layer);
				// Open the sidebar
				$("#sidebarPanel").kendoResponsivePanel("open");
			}//if ($('#sidebarPanel').css('display') == 'none'){ 
		}
		
		// Sidebar helper functions.
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
		
		function setSidebarPadding(layer){
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
		}//..function setSidebarPadding(layer){

	</script>

	<div class="responsive-message"></div>
				
<cfelse>
	<cfinclude template="#customBlogContentHtmlTemplate#" />
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
			<img src="<cfoutput>#application.baseUrl#</cfoutput>/images/logo/gregoryAlexanderLogo125_190.png" alt="Footer Logo"/>
			
			<h4 style="display: block; margin-left: auto; margin-right: auto;">Your input and contributions are welcomed!</h4>
			<p>If you have an idea, BlogCfc based code, or a theme that you have built using this site that you want to share, please contribute by making a post here or share it by contacting us! This community can only thrive if we continue to work together.</p>

			<h4>Images and Photography:</h4>
			<p>Gregory Alexander either owns the copyright, or has the rights to use, all images and photographs on the site. If an image is not part of the "Galaxie Blog" open sourced distribution package, and instead is part of a personal blog post or a comment, please contact us and the author of the post or comment to obtain permission if you would like to use a personal image or photograph found on this site.</p>
			
			<h4>Credits:</h4>
			<p>
				Portions of Galaxie Blog are powered on the server side by BlogCfc, an open source blog developed by <a href="https://www.raymondcamden.com/" <cfif darkTheme>style="color:whitesmoke"</cfif>>Raymond Camden</a>. Revitalizing BlogCfc was a part of my orginal inspiration that prompted me to design this site. Some of the major open source contributers to BlogCfc include:
				<ol>
					<li>Peter Farrell: the author of 'Lyla Captcha' that is used on this blog.</li>
					<li><a href="https://www.petefreitag.com/" aria-label="Pete Freitag and ColdFish" <cfif darkTheme>style="color:whitesmoke"</cfif>>Pete Freitag</a>: the author of the 'ColdFish' code formatter that is also used on this blog. </li>
				</ol>
			</p>
			<h4>Version:</h4>
			<p>
				Galaxie Blog Version <cfoutput>#application.blog.getVersion()# #application.blog.getVersionDate()#</cfoutput>
			</p>
		</span>
	</div>
		
<cfelse>
	<cfinclude template="#customFooterHtmlTemplate#" />
</cfif>
			
<!--- Let the users scroll down to see the whole image. --->
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>
			
<!--- Include tail end scripts. --->
<script>
	// Lazy load the images.
	deferimg('img.fade', 100, 'lazied', function(img) {
		img.onload = function() {
			img.className+=' shown';
		}
	});
</script>
						
<!--- When the page has been loaded, fade in the menu's. --->
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	setTimeout(function() {
		$('#topMenu').css('visibility', 'visible');
		// And show the fixed nav menu
		$('#fixedNavMenu').css('visibility', 'visible');
	}, 500);
	
	// Check the alignment of the page containers again and reset if necessary
	setScreenProperties();
</script>
						
<script type="<cfoutput>#scriptTypeString#</cfoutput>">
	// Initialize the plyr.
	const players = Plyr.setup('video', { captions: { active: true } });
	// Expose player so it can be used from the console
	window.players = players;
</script>

<!--- Disqus tail end script to enable the number of vpage iews and the comment count. --->
<script id="dsq-count-scr" type="<cfoutput>#scriptTypeString#</cfoutput>" src="//gregorys-blog.disqus.com/count.js" async></script>
						
<!--- Debugging carriage: --->
<!---
<cfoutput>
xmlKeywords:#xmlKeywords# getXmlKeywordValue(articles.body, 'facebookImageUrlMetaData'): #getXmlKeywordValue(articles.body, 'facebookImageUrlMetaData')#
</cfoutput>
--->

<!--- 
<cfoutput>
#getPageMode()#
</cfoutput>
--->
						
<!--- 
Note: if the Zion theme is screwed up, check the use custom theme setting in the ini file.
<cfoutput>
<cfdump var="#application.themeSettingsArray[3]#">
</cfoutput>
--->
	
<cfsilent>
<!--- Prism is intended to be our new code renderer in a later version. 
<script src="<cfoutput>#application.baseUrl#</cfoutput>common/libs/prism/prism.js"></script>
--->
</cfsilent>
</body>
</html>
	
</cfprocessingdirective>