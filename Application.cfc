<cfcomponent displayname="GregorysBlog" sessionmanagement="yes" clientmanagement="yes" output="true">
	<cfset this.Name = "GregorysBlog" />
	<cfset this.applicationTimeout = createTimeSpan(7,0,0,0) />
	<cfset this.sessionManagement="yes"/>
	<cfset this.enablerobustexception = true />

	<cffunction name="OnRequestStart">  
		
		<!--- Notes: the blogname reference here is really important to the underlying logic in this application. Raymond coded this. I assumed that this was just a label, or something else inconsequential. It's not. It actually is the first line in the blog.ini.cfm file that sets the configuration for the entire application. Unless there is something that I missed, it is essential that you leave this alone.  I am not sure why you should ever edit this, it will break the blog. 
		Raymond's comment: "Edit this line if you are not using a default blog", but I am not sure why and when this would ever apply.
		--->
		<cfset blogname = "Default">
			
		<!--- Create a reference to this component so that other functions can reset the application vars without a URL. To reinitalize from other templates use application.applicationObj.applicationInit() --->
		<cfset application.applicationObj = this>
		
		<!--- load and init blog --->
		<cfset application.blog = createObject("component","org.camden.blog.blog").init(blogname)>
		
		<!--- Default params. --->
		<!--- Common pointers. --->
		<cfset application.rootURL = application.blog.getProperty("blogURL")>
		<!--- per documentation - rooturl should be http://www.foo.com/something/something/index.cfm --->
		<cfset application.rootURL = reReplace(application.rootURL, "(.*)/index.cfm", "\1")>
		<!--- Gregory added the following vars to point to various new cfc's. Note: my original code, reReplace(getPageContext().getRequest().getRequestURI(), "(.*)/index.cfm", "\1"), does not work with blogCfc after you click on a link. The link abstraction technique that Raymond employs breaks this logic. --->
			
		<!---//**************************************************************************************************************************************************
						File locations and URL settings
		//***************************************************************************************************************************************************--->
		<!--- Get the parts of the URL from the blogUrl property. This is a Ben Nadel technique. --->
		<cfset urlParts = reMatch(
			"^\w+://|[^\/:]+|[\w\W]*$",
			 application.rootURL
			) />
		<!--- If the blog is installed in the root directory, the urlParts[3] will not be defined. --->
		<cftry>
			<!--- Get the baseUrl, which is the third item in the array. --->
			<cfset baseUrl = urlParts[3]>
			<cfcatch type="any">
				<cfset baseUrl = "">
			</cfcatch>
		</cftry>
		<!--- Set it --->
		<cfset application.baseUrl = baseUrl>
		<!--- Pointer to the Raymond's blog cfc.--->
		<cfset blogCfcUrl = baseUrl & '/org/camden/blog/blog.cfc' / >
		<!--- Pointer to the ini configuration file. --->
		<cfset application.iniFile = expandPath(baseUrl & "/org/camden/blog/blog.ini.cfm")>
		<!--- Pointer to the Raymond's blog cfc.--->
		<cfset application.blogCfcUrl = baseUrl & '/org/camden/blog/blog.cfc' / >
		<!--- Gregory's proxy controller --->
		<!--- Remove the first forward slash in the baseUrl. --->
		<cfset baseProxyUrl = replace(baseUrl, "/", "", "one")>
		<!--- Replace forward slashes with dots. --->
		<cfset application.baseComponentPath = replace(baseProxyUrl, "/", ".", "all")>
		<!--- Append the base URL with the proxyController. if there is a base url. If the site is installed in the root directory, we don't want to append a dot to the proxyControllerComponentPath. --->
		<cfif len(baseProxyUrl) gt 0>
			<cfset application.proxyControllerComponentPath = application.baseComponentPath & ".common.cfc.proxyController">
		<cfelse>
			<cfset application.proxyControllerComponentPath = "common.cfc.proxyController">
		</cfif>
		<!--- Set the URL to the new proxy controller. --->
		<cfset application.proxyControllerUrl = application.baseUrl & '/common/cfc/proxyController.cfc' / >
		<!--- URL to the themes component. --->
		<cfset application.themeComponentUrl = application.baseUrl & '/common/cfc/themes.cfc' / >
		<!--- Append the base URL with the themes.cfc if there is a base url. If the site is installed in the root directory, we don't want to append a dot to the themesComponentPath. --->
		<cfif len(baseProxyUrl) gt 0>
			<cfset application.themesComponentPath = application.baseComponentPath & ".common.cfc.themes">
		<cfelse>
			<cfset application.themesComponentPath = "common.cfc.themes">
		</cfif>
		<!--- Gregory's json wrapper.--->
		<cfset application.jsonArray = application.baseUrl & '/common/cfc/cfJson.cfc' / >

		<!--- Kendo library locations --->
		<!--- Note: we are using an open source version of the Kendo library, Kendo Core. It does not have all of the bells and whistles of the comercial licence of course. --->
		<cfset application.kendoSourceLocation = application.baseUrl & "/common/libs/kendoCore"><!---Commercial /common/libs/kendo--->
		<cfset application.kendoUiExtendedLocation = application.baseUrl & "/common/libs/kendoUiExtended">
		<cfset application.jQueryNotifyLocation = application.baseUrl & "/common/libs/jQuery/jQueryNotify">
		<!--- Note: the original blogCfc came with an older jQuery UI than the one that I am using and it is creating conflicts. We need to have two different jQuery incluedes, one for the administration part of the site, and the newer jquery UI for the new blogCfc.--->
		<cfset application.adminjQueryUiPath = application.baseUrl & "/includes/jqueryui/jqueryui.js">
		<!--- Kendo version (is Kendo the open source or commercial version?) --->
		<cfset application.kendoOpensource = "true">
		<cfset application.kendoCommercial = "false">
			
		<!---//**************************************************************************************************************************************************
				Administative section variables.
		//***************************************************************************************************************************************************--->
		<!--- There are two coldfusion application templates that I use in the administrative page, the legacy application.cfm template, and the modern application.cfc template. I am having problems with the cfc template as it requires a hard coded mapping. There are ways around this, but for this particular version, its easier just to use the original application.cfm extension until I can re-write the administrative section. This is a workaround. However, I need to set a applicationTemplateType flag in order to still use the application.cfc template for my own personal debugging (my hosting provider requires it). --->
		<cfset application.adminApplicationTemplateType = "cfm"><!---Note: the default installation value is "cfm"--->
		
		<!---//**************************************************************************************************************************************************
				Initialize the application and set core application vars.
		//***************************************************************************************************************************************************--->
		
		<!--- Include the UDF (Raymond's code) --->
		<cfinclude template="includes/udf.cfm">
			
		<!--- Set the path to other cfc's that are needed to consume the init function. --->
		<!--- The Themes component interacts with the Blog themes. --->
		<cfobject component="common.cfc.themes" name="ThemesObj">
			
		<cfif not isDefined("application.init") or isDefined("url.reinit") or isDefined("cookie.reinit")>
			<!--- Initialize the applicationInit method below to set the core application vars. --->
			<cfset initializeApplicationVars = this.applicationInit()>
			<!--- Initialize the themes --->
			<cfset initializeThemeVars = ThemesObj.initThemes()>
			<!---Set the application.init flag to true.--->
			<cfset application.init = true>
			<!--- Delete the reinit cookie --->
			<cfcookie name="reinit" value="false" expires="now">
		</cfif>
				
		<!--- 
		Let's make a pointer to our resource bundle (Gregory changed this from 'rb' to 'getResourceBundle' throughout the application). 
		In case you are curious, the line below makes a pointer to the struct.
		--->
		<cfset getResourceBundle = application.utils.getResource>

		<!--- Used to remember the pages we have viewed. Helps keep view count down. --->
		<cfif not structKeyExists(session,"viewedpages")>
			<cfset session.viewedpages = structNew()>
		</cfif>

		<!--- KillSwitch for comments. We don't authenticate because this kill uuid is something only the admin can get. --->
		<cfif structKeyExists(url, "killcomment")>
			<cfset application.blog.killComment(url.killcomment)>
		</cfif>
			
		<!--- Quick approval for comments --->
		<cfif structKeyExists(url, "approvecomment")>
			<cfset application.blog.approveComment(url.approvecomment)>
		</cfif>

		<!---//**************************************************************************************************************************************************
						Listener for social media posts. 
		//***************************************************************************************************************************************************--->
		<!--- 
		Notes: I could not find a way to pass in a valid URL that is different than the URL used to share social media posts, so when the user is reading a social media post and clicks on the link, it will direct the user to the addThis.cfm template. I need to add a listner to redirect to the proper link when the addThis.cfm page is called from an external source.

		However... just when you think that you have social media sharing figured out, you often notice that your solution causes new problems. I can't seem to figure social media buttons out. There is something going on behind the scenes either with the addThis library or the social media library. You can't assume that you can get away with filling out the meta tags just right. There is some inspection going on behind the scenes that quite often leads to screwy results. 

		For example, when I add this listner and share a post to facebook, the image disappears and the logo on the index.cfm page is shown on the facebook post complety incorrecttly. It appears that facebook needs to inspect this URL and will override whatever I sent to it using the open graph meta tags. So I need to allow facebook to inspect the addThis.cfm template, but not the home page. I have noticed when I click on the post that I shared on facebook, extra arguments are made to the URL, such as ''&fbclid=IwAR3seiSLhOuOzdlq0brbBnAG739_qEatzQX-f-YKoM-4DoRoxkSYoD9m55E#.XClxxsa2UBg.facebook', Perhaps I can use this. 

		Sure enough, that worked. I added sctructCount(URL) gt 1 to the logic below and it seemed to work. Facebook is inspecting the page when posting, but when the post was shared and the link was clicked on facebook, the additional arguments allow me to modify the listener yet allow facebook to inspect and scrape this page. Now I need to test and see if this works with the other social media sites. 

		Logic: 
		findNoCase(CGI.Server_Name, CGI.Http_Referer) the referer is different than the current site.
		and (structCount(URL) gt 1) works for facebook
		or CGI.Http_Referer contains 't.co/' works with twitter.
		or CGI.Http_Referer contains '/t.umblr.' works with tumbler
		CGI.Http_Referer contains 'pinterest' works with pinterest.
		--->
		<cfif CGI.Script_Name contains 'addThis.cfm' and findNoCase(CGI.Server_Name, CGI.Http_Referer) eq 0 and 
			(structCount(URL) gt 1 or
			 CGI.Http_Referer contains 't.co/' or
			 CGI.Http_Referer contains '/t.umblr.' or
			 CGI.Http_Referer contains 'pinterest'
			 )>
			<!---Build the link--->
			<cfset entryLink = application.blog.makeLink(id)>
			<!--- Redirect the user to the proper link --->
			<cflocation url="#entryLink#">
		</cfif>

		<!--- 10/26/2018 Gregory Alexander added the following parameters to better customize the blog --->
		<!--- Gregory: Preset the isAdmin session var to false if the user is not logged in. We can infer if the user is not logged in that they are not an admin user. If they are logged in, the login code in the /client/admin/Application.cfm template will set the session.isAdmin to true if all conditions are met (which currently is all of the time if the user is logged in). --->
		<cfif not structKeyExists(session,"loggedin")>
			<cfset session.isAdmin = false>
		</cfif>

		<!---//**************************************************************************************************************************************************
						The following settings are set in the administrator settings page (/admin/).
		//***************************************************************************************************************************************************--->

		<!--- Blog font size in points (set this smaller if you want to adjust the contentWidth param down from 66). Don't make it too small, it is not nice on the eyes. --->
		<cfset application.blogFontSize = getProfileString("#application.iniFile#", "default", "blogFontSize") />
		<!--- The parent site name (that the blog is hosted on). If this param is entered, the home button on the site will take you to the main site name as well as the main blog page. Leave blank if the blog is the main site. --->
		<cfset application.parentSiteName = getProfileString("#application.iniFile#", "default", "parentSiteName") />
		<!--- Specify the parent site link. I am setting this as the parent site URL may be located on a different server and I can't assume that it is just the cgi.Server_Name. --->
		<cfset application.parentSiteLink = getProfileString("#application.iniFile#", "default", "parentSiteLink") />
		<!---<cfset application.parentSiteLink = urlParts[1] & urlParts[2]>--->

		<!---//**************************************************************************************************************************************************
						UI appearance and theme functions 
		//***************************************************************************************************************************************************--->
		<!--- Get the default kendo themes. This is a comma separated list of themes and will control what themes are available in the themes dropdown menu at the top of the page. --->
		<cfset application.defaultKendoThemes = getProfileString("#application.iniFile#", "themes", "defaultKendoThemes") />
		<!--- Get the custom name for the Kendo theme. --->
		<cfset application.customThemeNames = getProfileString("#application.iniFile#", "themes", "customThemeNames") />
		<!---What is the default theme that should be shown if the user has not selected their own theme?--->
		<cfset application.kendoTheme = "metro"><!---TODO This needs to be a setting.--->
		<!--- Specify the dark themes. Note: this is a setting in the settings.cfm page, but the setting is not used as yet. --->
		<cfset application.darkThemes = "black,materialblack,highcontrast,moonlight">
		<!--- The addThis api key is found on the addThis.com site. There is a tutorial how to use this on Gregory's blog. --->
		<cfset application.addThisApiKey = application.blog.getProperty("addThisApiKey")>

		<!--- Gregory updated the device detection code on Feb 6 2019 (from http://detectmobilebrowsers.com/)--->
		<cfif 
		(reFindNoCase("(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino",CGI.HTTP_USER_AGENT) GT 0 OR reFindNoCase("1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-",Left(CGI.HTTP_USER_AGENT,4)) GT 0)>
			<cfset session.isMobile = true>
		<cfelse>
			<cfset session.isMobile = false>
		</cfif>

		<cfsetting enablecfoutputonly="false">
			
	</cffunction>
			
	<!---//**************************************************************************************************************************************************
						Initialize application vars 
	//***************************************************************************************************************************************************--->
			
	<!--- Note: This function is also consumed on the admin settings page in order to get all of the settings --->
	<cffunction name="applicationInit" access="public" returntype="boolean" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page.">

		<!--- load and init blog --->
		<cfset application.blog = createObject("component","org.camden.blog.blog").init(blogname)>

		<!--- Do we need to run the installer? --->
		<cfif application.blog.getProperty("installed") is 0>
			<cflocation url="./installer/index.cfm?blog=#urlEncodedFormat(blogname)#" addToken="false">
		</cfif>

		<!--- Root folder for uploaded images, used under images folder --->
		<cfset application.imageroot = application.blog.getProperty("imageroot")>

		<!--- locale related --->
		<cfset application.resourceBundle = createObject("component","org.hastings.locale.resourcebundle")>

		<!--- Path may be different if admin. --->
		<cfset currentPath = getDirectoryFromPath(getCurrentTemplatePath()) />
		<cfset theFile = currentPath & "includes/main" />
		<cfset lylaFile = getRelativePath(currentPath & "includes/captcha.xml") />
		<cfset slideshowdir = currentPath & "images/slideshows/" & application.imageroot />

		<cfset application.resourceBundle.loadResourceBundle(theFile, application.blog.getProperty("locale"))>
		<cfset application.resourceBundleData = application.resourceBundle.getResourceBundleData()>
		<cfset application.localeutils = createObject("component","org.hastings.locale.utils")>
		<cfset application.localeutils.loadLocale(application.blog.getProperty("locale"))>

		<!--- load slideshow --->
		<cfset application.slideshow = createObject("component", "org.camden.blog.slideshow").init(slideshowdir)>

		<!--- Use Captcha? --->
		<cfset application.usecaptcha = application.blog.getProperty("usecaptcha")>

		<!--- Use CFFORMProtect? --->
		<cfset application.usecfp = application.blog.getProperty("usecfp")>

		<cfif application.usecaptcha>
			<cfset application.captcha = createObject("component","org.captcha.captchaService").init(configFile="#lylaFile#") />
			<cfset application.captcha.setup() />
		</cfif>

		<!--- use tweetbacks? --->
		<cfset application.usetweetbacks = application.blog.getProperty("usetweetbacks")>
		<cfif not isBoolean(application.usetweetbacks)>
			<cfset application.usetweetbacks = false>
		</cfif>
		<cfif application.usetweetbacks>
			<cfset application.sweetTweets = createObject("component","org.sweettweets.SweetTweets").init()/>
		</cfif>

		<!--- clear scopecache --->
		<cfmodule template="tags/scopecache.cfm" scope="application" clearall="true">


		<cfset majorVersion = listFirst(server.coldfusion.productversion)>
		<cfset minorVersion = listGetAt(server.coldfusion.productversion,2,",.")>
		<cfset cfversion = majorVersion & "." & minorVersion>

		<cfset application.isColdFusionMX7 = server.coldfusion.productname is "ColdFusion Server" and cfversion gte 7>

		<!--- used for cache purposes is 60 minutes --->
		<cfset application.timeout = 60*60>

		<!--- how many entries? --->
		<cfset application.maxEntries = 10><!---50 application.blog.getProperty("maxentries")--->

		<!--- Gravatars allowed? --->
		<cfset application.gravatarsAllowed = application.blog.getProperty("allowgravatars")>

		<!--- Load the Utils CFC --->
		<cfset application.utils = createObject("component", "org.camden.blog.utils")>

		<!--- Load the Page CFC --->
		<cfset application.page = createObject("component", "org.camden.blog.page").init(dsn=application.blog.getProperty("dsn"), username=application.blog.getProperty("username"), password=application.blog.getProperty("password"),blog=blogname)>

		<!--- Load the TB CFC --->
		<cfset application.textblock = createObject("component", "org.camden.blog.textblock").init(dsn=application.blog.getProperty("dsn"), username=application.blog.getProperty("username"), password=application.blog.getProperty("password"),blog=blogname)>

		<!--- Do we have comment moderation? --->
		<cfset application.commentmoderation = application.blog.getProperty("moderate")>

		<!--- Do we allow file browsing in the admin? --->
		<cfset application.filebrowse = application.blog.getProperty("filebrowse")>

		<!--- Do we allow settings in the admin? --->
		<cfset application.settings = application.blog.getProperty("settings")>

		<!--- load pod --->
		<cfset application.pod = createObject("component", "org.camden.blog.pods")>

		<!--- Finally, do a DSN check --->
		<!--- We end up throwing away this call, but it should be lightweight --->
		<cfset foo = application.blog.getNameForUser(createUUID())>

		<!--- Gregory's logic. --->
		<cfset application.baseUrl = reReplace(getPageContext().getRequest().getRequestURI(), "(.*)/index.cfm", "\1") />

		<cfreturn true>
		<!---Exit the function.--->
	</cffunction>
	
</cfcomponent>