<!--- //******************************************************************************************************
			Get the post(s)
//********************************************************************************************************--->

<cfinclude template="#application.baseUrl#/includes/templates/getPost.cfm">

<!--- //******************************************************************************************************
			Global page settings and cache
//********************************************************************************************************--->

<!--- Include the functions that are used in the UI --->
<cfinclude template="#application.baseUrl#/common/function/page.cfm">

<!--- //******************************************************************************************************
			Common custom templates (ad-hoc scripts if the database does not contain the logic).
//********************************************************************************************************

Note: in order to debug- remove the cfsilent that wraps around the pageSettings.cfm template on the index.cfm page.
--->
	
<!--- //******************************************************************************************************
			Logic to set user defined settings
//********************************************************************************************************--->
	
<!--- Set the type string --->
<cfif application.deferScriptsAndCss>
	<!--- Defers the loading of the script and css using the deferjs library. --->
	<cfset scriptTypeString = "deferjs">
<cfelse>
	<cfset scriptTypeString = "text/javascript">
</cfif>
	
<!--- Do you want the page to automatically redirect using SSL? We are going to read the users setting set in the administrative interface (site URL) to determine if ssl should be enforced. It is is, we will use a server side redirect. You can change this by removing this code and setting useSsl to false.  --->
<cfif application.useSsl and findNoCase("https", application.rooturl) eq 1>
	<cfset useSsl = true>
<cfelse>
	<cfset useSsl = false>
</cfif>

<cfif application.serverRewriteRuleInPlace>
	<cfset thisUrl = replaceNoCase(application.siteUrl, '/index.cfm', '')>
	<!--- Create a blogUrl var. The thisUrl variable will be overwritten depending upon the page that is being viewed. --->
	<cfset blogUrl = thisUrl>
<cfelse>
	<cfset thisUrl = application.siteUrl>
	<cfset blogUrl = thisUrl>
</cfif>
	
<!--- //******************************************************************************************************
			Load common cfc objects and set encryption and service keys.
//********************************************************************************************************--->

<!--- The proxyController is between the blog.cfc and the client. --->
<cfobject component="#application.proxyControllerComponentPath#" name="ProxyControllerObj">
<!--- Preset URL vars --->
<cfparam name="URL.startRow" default="0">
	
<!--- Use to delete the cookies for testing.
<cfset exists = structdelete(session, 'encryptionKey', true)/>
<cfset exists = structdelete(session, 'serviceKey', true)/>
--->
	
<!--- //******************************************************************************************************
			Global and common params
//********************************************************************************************************--->

<!--- Determine if the http accept header contains webp. The getHttpRequestData().headers is a structure and we are targetting the accept element in the array. Note: nearly all modern browsers will include this if the browser supports the webp next gen image. --->
<cftry>
	<cfset acceptHeader = getHttpRequestData().headers["accept"]>
	<!--- Does the header accept webp? --->
	<cfif findNoCase("webp", acceptHeader) gt 0>
		<cfset clientAcceptsWebP = true>
	<cfelse>
		<cfset clientAcceptsWebP = false>
	</cfif>
<cfcatch type="any">
	<cfset clientAcceptsWebP = false>	
</cfcatch>
</cftry>
<!--- The logic to determine if the server has the necessary webp mime type was done in the application.cfc template. We will use the application.serverSupportsWebP variable that the mime type is installed on the server. Of course, both the client and the server need to support webp images before we can deliver them.---> 
<cfif application.serverSupportsWebP and clientAcceptsWebP>
	<cfset webpImageSupported = true>
<cfelse>
	<cfset webpImageSupported = false>
</cfif>
	
<!--- Preset the xmlKeywords. --->
<cfparam name="xmlKeyWords" default="" type="string">
	
<!--- Get the post theme ref (if available) --->
<cftry>
	<cfset postThemeId = getPost[1]["ThemeRef"]>
	<cfcatch type="any">
		<cfset postThemeId = 0>
	</cfcatch>
</cftry>

<!--- When we are looking at a post and the post theme is defined, get the theme. Otherwise get the current selected theme. --->
<cfif getPageMode() eq 'post' and isDefined("postThemeId") and postThemeId gt 0>
	<!--- Get the theme data by the theme id. --->
	<cfset getTheme = application.blog.getTheme(themeId=postThemeId)>	
<cfelse>
	<!--- Get the current theme --->
	<cfset selectedThemeAlias = trim(application.blog.getSelectedThemeAlias())>
	<!--- Get the Theme data for this theme. --->
	<cfset getTheme = application.blog.getTheme(themeAlias=selectedThemeAlias)>	
</cfif>
<cfif not arrayLen(getTheme)>
	<cfset getTheme = application.blog.getTheme(themeAlias="Delicate-Arch")>		
</cfif>
<!---	
Debugging:
<cfoutput>selectedThemeAlias: #selectedThemeAlias#</cfoutput>
<cfdump var="#getTheme#">
--->
<!--- Get the ThemeId --->
<cfset themeId = getTheme[1]["ThemeId"]>
<!--- Get the Kendo theme. --->
<cfset kendoTheme = getTheme[1]["KendoTheme"]>
<!--- Is this a dark theme (such as Orion)? --->
<cfset darkTheme = getTheme[1]["DarkTheme"]>
<!--- We need to know if this is a modern theme to handle the side bar Disqus widget (among other potential things) --->
<cfset modernTheme = getTheme[1]["ModernThemeStyle"]>

<!--- 
The default width of the containers that hold the blog content. I would suggest leaving this at 66% as I am checking the screen size later on and adjusting the css to this baseline value. I am using a bigger font than most of the blogCfc sites, so I am setting this at 66%, which is a bit wider than 50% which looks the best. This setting also affects the seach and searchResults windows which subtract 10% from this setting. 
Notes: 
The 66% setting looks great with a 20 inch monitor. 
80% works with 1280x768, which is a 19 inch monitor or a 14 Notebook. 
I am adjusting the contentWidth via javascript to ensure proper rendering of the page.
--->
<cfset contentWidth = getTheme[1]["ContentWidth"]>

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
	<cfset mainContainerWidth = getTheme[1]["MainContainerWidth"]>
	<cfset sideBarContainerWidth = getTheme[1]["SideBarContainerWidth"]>
</cfif>
	
<!--- //******************************************************************************************************
			Granular settings by theme.
//******************************************************************************************************  --->
<!--- Trim and set the granular settings stored in a structure that are determined by the theme. The getSettingsByTheme method in the Main.cfc template provides granular ui settings by theme. --->
<!--- The site opacity will make the blog content semi-transparent so that you can see the background image. If you change this, be sure to set this between 80 and 100 as this will impact the readability of the entire site. Site opacity settings show the background image underneath. Each setting is individually set by the theme to ensure better readability. ---> 

<!--- The Kendo css locations use the Kendo folder path when using Kendo commercial. Otherwise they point to the root folder and the embedded Kendo Core package. --->
<!--- Kendo file locations. --->		
<cfset kendoCommonCssFileLocation = trim(application.kendoFolderPath & getTheme[1]["KendoCommonCssFileLocation"])>
<cfset kendoThemeCssFileLocation = trim(application.kendoFolderPath & getTheme[1]["KendoThemeCssFileLocation"])>
<!--- The mobile theme has an appended 'mobile' string. --->
<cfset kendoThemeMobileCssFileLocation = trim(application.kendoFolderPath & getTheme[1]["KendoThemeMobileCssFileLocation"])>
<cfset kendoThemeMobileCssFileLocation = trim(application.kendoFolderPath & getTheme[1]["KendoThemeMobileCssFileLocation"])>
	
<!--- When using the Kendo Core package, add the root folder to the location --->
<cfif not application.kendoCommercial>
	<cfset kendoCommonCssFileLocation = application.baseUrl & kendoCommonCssFileLocation>
	<cfset kendoThemeCssFileLocation = application.baseUrl & kendoThemeCssFileLocation>
	<cfset kendoThemeMobileCssFileLocation = application.baseUrl & kendoThemeMobileCssFileLocation>
</cfif>
	
<!--- Is a theme selected? --->
<cfset selectedTheme = getTheme[1]["SelectedTheme"]>
	
<!--- Body Fonts --->
<cfset font = getTheme[1]["Font"]>
<cfset fontType = getTheme[1]["FontType"]>
<cfset fontSize = getTheme[1]["FontSize"]> 
<cfset fontSizeMobile = getTheme[1]["FontSizeMobile"]>
	
<!--- Opacity --->
<cfset siteOpacity = getTheme[1]["SiteOpacity"]>
	
<!--- Are the webp image formats included? This is only relevant for the distribution package of the blog. Users that have donloaded the blog are recommended to use the webp format if the server supports it. --->
<cfset webPImagesIncluded = getTheme[1]["WebPImagesIncluded"]>
<!---Does the user want background images?--->
<cfset includeBackgroundImages = getTheme[1]["IncludeBackgroundImages"]>
<!--- What image do you want displayed as the background? --->
<cfset blogBackgroundImage = getTheme[1]["BlogBackgroundImage"]>
<cfset blogBackgroundImageMobile = getTheme[1]["BlogBackgroundImageMobile"]>
<!--- If the blog background images are not included, the user can specify a blog background color instead. --->
<cfset blogBackgroundColor = getTheme[1]["BlogBackgroundColor"]>
	
<!--- Logic to modify the default background image string to specify the webp image extension and determine the mobile version (which is smaller). --->
<!--- Are the webp images included in this theme and is webp in the accept header? --->
<cfif webPImagesIncluded and webpImageSupported>
	<!--- Use the webp image. First, we need to check to see whether the client is mobile or desktop. I scaled the mobile background image down quite a bit. We don't  need to have a large image on mobile clients. --->
	<cfif session.isMobile>
		<cfset blogBackgroundImage = replaceNoCase(blogBackgroundImageMobile, '.png', '.webp')>
	<cfelse>
		<cfset blogBackgroundImage = replaceNoCase(blogBackgroundImage, '.png', '.webp')>
	</cfif>
<cfelse><!---<cfif webpImageSupported>--->
	<!--- Use a jpg. --->
	<cfif session.isMobile>
		<!--- Use the default blog background image (which is a jpg). --->
		<cfset blogBackgroundImage = blogBackgroundImageMobile>
	<cfelse>
		<cfset blogBackgroundImage = blogBackgroundImage>
	</cfif>
</cfif><!---<cfif webpImageSupported>---> 

<!--- Do you want the blogBackgroundImage to repeat at the end of the image? The dafualt value is false. --->
<cfset blogBackgroundImageRepeat = getTheme[1]["BlogBackgroundImageRepeat"]>
<!--- Set the background image position. See https://www.w3schools.com/cssref/pr_background-position.asp for a full description. --->
<cfset blogBackgroundImagePosition = getTheme[1]["BlogBackgroundImagePosition"]>
	
<!--- What is the width of the header banner? We can either stretch it out across the entire page, or make it identical to the width of the contentWidth. I am adding this setting as some users may want to put more stuff into the header banner and stretching it out allows more room. --->
<cfset stretchHeaderAcrossPage = getTheme[1]["StretchHeaderAcrossPage"]>
<!--- Set the string that we will use in the UI --->
<cfif stretchHeaderAcrossPage>
	<cfset headerBannerWidth = "100%">
<cfelse>
	<cfset headerBannerWidth = contentWidth & "%">
</cfif>
	
<!--- Controls the alignment of the *entire* menu and the header. If it is aligned to the left, the menu will be aligned with the blog content container. I am allowing this to be changed as the user may want to use the same header on their own site and I want to allow them to modify the placement as the end user sees fit. The values are: left, center. --->
<cfset alignBlogMenuWithBlogContent = getTheme[1]["AlignBlogMenuWithBlogContent"]>
<!--- Top menu alignment. This affects the menu placement *within* the header. The top menu contains the logo as well as the menu scripts and search button. Accepted values are left, center, and right. Unlike the alignBlogMenuWithBlogContent argument, this affects the outer container which will be aligned. --->
<cfset topMenuAlign = getTheme[1]["TopMenuAlign"]><!---Either left, center, or right--->
<!--- The header background image. You can also leave this blank if you want the blogBackgroundImage to be shown instead of a colored banner on the header. If you choose to leave this blank and not display a colored banner, also leave the menuBackgroundImage blank, otherwise, a colored bar will be displayed. Note: I put a gradient on the banner image, however, the top of the image, which is darker than the bottom, can't be used for the menu as it will look off. So I am separating the background images for the banner and the menu. --->
<cfset headerBackgroundImage = application.baseUrl & getTheme[1]["HeaderBackgroundImage"]>
<cfif webPImagesIncluded and webpImageSupported>
	<!--- Overwrite the headerBodyDividerImage var and change the extension to .webp--->
	<cfset headerBackgroundImage = replaceNoCase(headerBackgroundImage, '.png', '.webp')>
</cfif>
<!--- The background image for the top menu. This should be a consistent color and not gradiated. --->
<cfset menuBackgroundImage = application.baseUrl & getTheme[1]["MenuBackgroundImage"]>	
<!--- We will try to substitute a webp image here. --->
<cfif webPImagesIncluded and webpImageSupported>
	<!--- Overwrite the headerBodyDividerImage var and change the extension to .webp--->
	<cfset menuBackgroundImage = replaceNoCase(menuBackgroundImage, '.png', '.webp')>
</cfif>
<!--- Menu font properties --->
<cfset menuFont = getTheme[1]["MenuFont"]>
<cfset menuFontType = getTheme[1]["MenuFontType"]>
<!--- This setting determines if the whole image should be shown on screen, or if the image should be captured from the left until the image is cut off at the end of the screen. Essentially, setting this to true set the image width t0 be 100%, whereas setting this to false will left justify the image and cut off any overflow. The resolution is quite high, so setting this to false will cut off the right part of most of the images. --->
<cfset coverKendoMenuWithMenuBackgroundImage = getTheme[1]["CoverKendoMenuWithMenuBackgroundImage"]>
<!--- Both desktop and mobile logos. The mobile logo should be smaller than the desktop obviously. --->
<cfset logoImageMobile = application.baseUrl & getTheme[1]["LogoImageMobile"]>
<cfset logoMobileWidth = getTheme[1]["LogoMobileWidth"]>
<cfset logoImage = application.baseUrl & getTheme[1]["LogoImage"]>

<!--- Generic Logo Properties.--->
<!--- Padding. The most important setting here is logoPaddingLeft which gives space between the logo and the blog text and menu. I have designed the logo image with padding on the left to take care of this without applying this setting. Padding right and bottom can be used to fine tune the placement of the logo but I am not using them currently in my theme designs. --->
<cfset logoPaddingTop = getTheme[1]["LogoPaddingTop"]>
<cfset logoPaddingRight = getTheme[1]["LogoPaddingRight"]>
<cfset logoPaddingLeft = getTheme[1]["LogoPaddingLeft"]>
<cfset logoPaddingBottom = getTheme[1]["LogoPaddingBottom"]>
<!---The blog name text color controls the behavior of all text in the menu, including the search icon.--->
<cfset blogNameTextColor = getTheme[1]["BlogNameTextColor"]>
<!--- Blog title font --->
<cfset blogNameFont = getTheme[1]["BlogNameFont"]>
<cfset blogNameFontType = getTheme[1]["BlogNameFontType"]>
<cfset blogNameFontSize = getTheme[1]["BlogNameFontSize"]>
<cfset blogNameFontSizeMobile = getTheme[1]["BlogNameFontSizeMobile"]>
<!--- FavIcon --->
<cfset favIconHtml = getTheme[1]["FavIconHtml"]>
	
<!--- Logo image check (there may be one common logo for all things). --->
<cfif session.isMobile>
	<cfset logoSourcePath = "#logoImageMobile#">
<cfelse>
	<cfset logoSourcePath = "#logoImage#">
</cfif>
	
<!--- The divider between the header and body --->
<cfset headerBodyDividerImage = application.baseUrl & getTheme[1]["HeaderBodyDividerImage"]>
<!--- See if we can use a webp image instead of the default png. --->
<cfif webPImagesIncluded and webpImageSupported>
	<!---Overwrite the headerBodyDividerImage var and change the extension to .webp--->
	<cfset headerBodyDividerImage = replaceNoCase(headerBodyDividerImage, '.png', '.webp')>
</cfif>
<!--- Footer image --->
<cfset footerImage = trim(getTheme[1]["FooterImage"])>
	
<!--- //******************************************************************************************************
			Logic to set vars for the client
//********************************************************************************************************--->
	
<cfif pageTypeId eq 1>
	<cfset breakPoint = getTheme[1]["Breakpoint"]>
	<!--- Safety check --->
	<cfif not isNumeric(breakPoint) or breakPoint eq "">
		<cfset breakPoint = 1921><!---Was 1300--->
	</cfif>
<!--- The administrative pages do not contain a breakpoint. We will hide the sidebar.cfm template and all of the pods to the right of the page.--->
<cfelseif pageTypeId eq 2><!--- Administrative pages --->
	<cfset breakPoint = 0><!--- 0 eliminates the sidebar --->
</cfif>
	
<!--- //******************************************************************************************************
			Custom plugins and strings
//************************************************************************************************************
Notes: this is a template driven system. its not full featured at this time, however, the templates are stored in the database and this will be enhanced in future versions.
--->	
			
<!--- Get the custom template --->
<cfset getCustomTemplate = application.blog.getCustomTemplate()>
<!---<cfdump var="#getCustomTemplate#">--->
	
<!--- Core logic below this section. Deals with the getMode and entry logic. Include the full path of the logical template (ie #application.baseUrl#/plugin/coreLogic.cfm) --->
<cfset customCoreLogicTemplate = getCustomTemplate[1]["CoreLogicTemplate"]>
<!--- Content between the head tags can be customized with a custom template. Indicate the full path and the name of the custom template here. --->
<cfset customHeadTemplate = getCustomTemplate[1]["HeaderTemplate"]>
<!--- Setting to replace the default body string. This should be a <body .... > string. --->
<cfset customBodyString = getCustomTemplate[1]["BodyString"]>
<!--- Template to include fonts. --->
<cfset customFontCssTemplate = getCustomTemplate[1]["FontTemplate"]>
<!---Global css variables and the css for the body--->
<cfset customGlobalAndBodyCssTemplate = getCustomTemplate[1]["CssTemplate"]>
<!--- Template to include css rules for the top menu. --->
<cfset customTopMenuCssTemplate = getCustomTemplate[1]["TopMenuCssTemplate"]>
<!--- Template to include the html for the top menu. --->
<cfset customTopMenuHtmlTemplate = getCustomTemplate[1]["TopMenuHtmlTemplate"]>
<!--- Template to include the javascript for the top menu. Note: this template is within the code region of the customTopMenuHtmlTemplate. --->
<cfset customTopMenuJsTemplate = getCustomTemplate[1]["TopMenuJsTemplate"]>
<!--- Template to include the css rules for the blog content (blog posts). --->
<cfset customBlogContentCssTemplate = getCustomTemplate[1]["BlogCssTemplate"]>
<!--- Template to include Kendo's widget and UI javascripts for the main blog (not the header script) --->
<cfset customBlogJsContentTemplate = getCustomTemplate[1]["BlogJsTemplate"]>
<!--- Template to include blog content HTML (blog posts). This is a rather intensive bit of code that will be broken down further in a later version. --->
<cfset customBlogContentHtmlTemplate = getCustomTemplate[1]["BlogHtmlTemplate"]>
<!--- Template for the side bar panel --->
<cfset customSideBarPanelHtmlTemplate =  getCustomTemplate[1]["SideBarPanelHtmlTemplate"]>
<!--- Template to include a custom footer. --->
<cfset customFooterHtmlTemplate = getCustomTemplate[1]["FooterHtmlTemplate"]>

<!--- //******************************************************************************************************
			Kendo window settings
//********************************************************************************************************--->
		
<!--- Window settings --->
<cfif session.isMobile>
	<cfset kendoWindowIcons = '"Minimize", "Refresh", "Close"'>
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
			
<!--- //******************************************************************************************************
			Check for theme settings issues. 
//********************************************************************************************************--->
			
<!--- There are often wierd problems when checking for null values right after a value has been set from a short hand structure. Putting this code right 
after the menuBackgroundImage setting causes an error. Not sure if it is a ColdFusion bug or not, but I have encountered it several times
before in other projects. I suspect that it is reading the entire object when it is set? --->

<!--- If the menuBackgroundImage is not defined, assign it to the headerBackgroundImage. Without it, there will be a ghosted bar above the menu. --->
<cfif len(trim(menuBackgroundImage)) eq 0>
	<cfset menuBackgroundImage = headerBackgroundImage>
</cfif>	
	
<!--- don't allow the alignBlogMenuWithBlogContent to be set to true unless the stretchHeaderAcrossPage is set to true. Otherwise, the header will be scrunched up as there will be padding on both the left and the right of the centered header.--->
<cfif not stretchHeaderAcrossPage and alignBlogMenuWithBlogContent>
	<cfset alignBlogMenuWithBlogContent = false>
</cfif>