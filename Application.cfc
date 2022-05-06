<cfcomponent displayname="GalaxieBlog3" sessionmanagement="yes" clientmanagement="yes" output="true">
	<cfsetting requesttimeout="60">
	<cfset this.Name = "GalaxieBlog" /> 
		
	<!--- Putting here as I often restart the app when debugging <cfset applicationStop()> --->
	<cfparam name="doInit" default="false">
	<!--- Print out some of the vars for debugging purposes. --->
	<cfset debug = false>
		
	<!--- Used for testing purposes. Setting these vars to true will allow you to re-run the installer --->
	<cfset reinstallIni = false>
	<cfset reinstallDb = false>

	<!--- 7 day application timeout. Be careful when you change this to a shorter timeout otherwise the variables on the admin pages won't stick --->
	<cfset this.applicationTimeout = createTimeSpan(7,0,0,0) />
	<cfset this.sessionManagement="yes"/>
	<!--- 4 hour session timeout. It can take a long time to create a post and I don't  want to force the user to reload the page --->
	<cfset this.sessiontimeout = createTimeSpan(0,4,0,0) >
	<!--- Since the Ajax requests go through a security mechanism, we need to have the session persist until the user closes the browser. I don't  want the user to type in a long comment only to have it fail if the session timeout has expired. 

	This is a Ben Nadel technique. See https://www.bennadel.com/blog/1131-ask-ben-ending-coldfusion-session-when-user-closes-browser.htm
	When creating session-only cookies so that the user's session ends when the browser is closed, we must turn off ColdFusion's automatic cookie storage. If we let ColdFusion store the cookies, then it will set an expiration date which will cause us trouble.
	--->
	<cfset this.setClientCookies = false />
	<cfset this.enablerobustexception = true />
		
	<!--- Note: do not user mappings here. Mappings do not work with CF ORM. They are causing errors. --->
		
	<!--- 
	Create a reference to this component so that other functions can reset the application vars without a URL. 
	To reinitalize from other templates use application.applicationObj.applicationInit() 
	--->
	<cfset application.applicationObj = this>
		
	<!--- Set the blogIniPath in order to get the variables. --->
	<cfset application.blogIniPath = getBlogIniPath()>
		
	<!--- Enable ORM --->
	<cfset initOrm()>
	
	<!---//****************************************************************************************
				ORM
	//*****************************************************************************************--->
			
	<cffunction name="initOrm"> 
		
		<!--- Put this in a try block as the database might not be set up when installing. --->
		<cfif len(getDsn())>
		
			<cfset this.ormEnabled = "true">
			<!--- Get the datasource from the ini file. This is required as the database may not be set up yet prior to installing the blog and we need somewhere to store the db credentials. --->
			<cfset this.datasource = getDsn()>
			<!--- At this time, the dialect is always 'auto'. --->
			<cfset this.dialect = 'auto'>
			<!--- Allow ColdFusion to update and create the tables when they do not already exist. --->
			<cfset this.ormSettings.dbcreate = "update">
			<!--- Set a pointer to the cfc directory --->
			<cfset this.ormSettings.cfclocation = expandPath(getBaseUrl() & "/common/cfc/db/galaxieDb/")>
			<!--- Note: without this argument, you will have a 'Session is closed!' error everytime you hit a function that processes a database transaction simultaneously. Use a transaction tag to commit the data instead. --->
			<cfset this.ormsettings.flushAtRequestEnd = false>
			<!--- Escape reserved database keywords (such as 'Role') which cause generic errors. --->
			<cfset this.ormsettings.hibernate.globally_quoted_identifiers = true>
			<!--- Enable ORM offset in queries. --->
			<cfset this.ormsettings.legacy_limit_handler = true>
			<!--- Log SQL --->
			<cfset this.ormsettings.logsql = true>
			<!--- Only use this when debugging <cfset this.ormsettings.skipCFCWithError = true> --->
			<!--- Set a flag that ORM has been initialized --->
			<cfset this.ormInitialized = true>
			
		</cfif><!---<cfif len(getDsn())>--->
					
	</cffunction> 
		
	<cffunction name="OnRequestStart">
		
		<!--- Reload the ORM schema --->
		<cfif isDefined("URL.init") or isDefined("URL.reinit")>
			
			<!--- Reset the main app vars --->
			<cfset getRootPath(true)>
			<cfset application.siteUrl = getSiteUrl(true)>
			<!--- The blogHostUrl is the site URL minus the index.cfm. This should be the rootUrl in later versions. --->
			<cfset application.blogHostUrl = replaceNoCase(getSiteUrl(true), '/index.cfm', '')>
			<cfset application.blogDomain = parseUri(application.blogHostUrl).host>
			<cfset application.baseUrl = getBaseUrl(true)>
			<cfset application.rootUrl = getRootUrl(true)>
			<cfset application.dsn = getDsn(true)>
			<cfset application.databaseType = getDatabaseType(true)>
			<cfset application.installed = getInstalled(true)>
			<!--- Ini file --->
			<cfset application.iniFile = expandPath(blogIniPath)>
			<!--- Set the common component paths --->
			<cfset application.baseProxyUrl = getBaseProxyUrl()>
			<cfset application.baseComponentPath = getBaseComponentPath()>
			<!--- Determine if the server supports webp images and woff fonts --->
			<cfset application.serverSupportsWebP = serverSupportsWebP(true)>
			<cfset application.serverSupportsWoff2 = serverSupportsWoff2(true)>

			<!--- Flush our cache. It will not exist when first installing the blog --->
			<cftry>
				<!--- Note: each Kendo Theme has a cache. There are too many caches to try to flush so we are going to flush them all. --->
				<!--- Clear everything from the scopecache library --->
				<cfmodule template="#getBaseUrl()#/tags/scopecache.cfm" scope="application" clearall="true">
				<!--- Clear CF Caching --->
				<cfcache action="flush"></cfcache>
				<cfcatch type="any">
					<cfset error = 'cache does not exist'>
				</cfcatch>
			</cftry>
				
			<!--- And reload ORM --->
			<cfset ORMReload()>
				
			<!--- 
			Debugging note: if you change the blog folder after installation, you may need to print these vars to reset them.
			<cfoutput>getSiteUrl(): #getSiteUrl()# application.BlogDbObj.getBlogUrl(): #application.BlogDbObj.getBlogUrl()# getProfileString(application.blogIniPath, "default", "blogUrl"): #getProfileString(application.blogIniPath, "default", "blogUrl")#<br/></cfoutput>
			--->
				
		</cfif><!---<cfif isDefined("URL.init") or isDefined("URL.reinit")>--->
				
		<cfif isDefined("URL.appStop")>  
			<!--- Stop the application --->  
			<cfset applicationStop()/>
			<!--- Redirect to the home page and the application should start again --->
			<cflocation url="#getBaseUrl()#">
		</cfif>
			
		<!--- Get the CF version. --->
		<cfset application.cfVersion = listGetAt(Server.ColdFusion.ProductVersion, 1, ',')>

		<!--- Set the base template path without the /index.cfm. don't  use the getCurrentTemplatePath() as this changes depending upon the page that you are viewing (for example the admin site). This should something like 'D:\home\gregoryalexander.com\wwwroot\galaxieBlog\'. This function is optimized for performance and you can use 'getRootPath(true)' to reset the path --->
		<cfset application.rootPath = getRootPath() />
		<!--- Get the path to the ini file. This should something like D:\home\gregoryalexander.com\wwwroot\galaxieBlog\test\org\camden\blog\blog.ini.cfm We need to get to the site URL and dsn properties stored in the file. --->
		<cfset application.blogIniPath = getBlogIniPath()>
		<!--- Set the ini file path as a var --->
		<cfset application.iniFile = expandPath(blogIniPath)>

		<!--- Get the database vars. --->
		<cfset application.dsn = getDsn()>
		<cfset application.databaseType = getDatabaseType()>
		<!--- Was the blog installed --->
		<cfset application.installed = getInstalled()>

		<!--- Use the functions to set the siteUrl, rootUrl and baseUrl. The rootUrl is also the siteUrl, the baseUrl is just the directory after the domain name without the last forward slash (ie '/blog'). The entire site structure is driven by these two vars. These functions are optimized for efficiency. --->

		<!--- Get the site URL. This is one of the most essential settings as the entire path structure of the blog is based on this --->
		<cfset application.siteUrl = getSiteUrl()>
		<!--- The blogHostUrl is the site URL minus the index.cfm. This should be the rootUrl in later versions. --->
		<cfset application.blogHostUrl = replaceNoCase(getSiteUrl(), '/index.cfm', '')>
		<!--- Get the domain. This is needed to append the domain to the media path when sending out images. The mediaPath contains the baseUrl which we will append the domain to to get the path to the email images. --->
		<cfset application.blogDomain = parseUri(application.blogHostUrl).host>
		<!--- And get the root and base URL. Note: for now these are the same thing. I'll standardize this in an upcoming version --->
		<cfset application.rootUrl = getBaseUrl()>
		<cfset application.baseUrl = getBaseUrl()>
		<cfset application.baseTemplatePath = getBaseTemplatePath()>
		<!--- Set the common component paths --->
		<cfset application.baseProxyUrl = getBaseProxyUrl()>
		<!--- Set the base component path by replacing the baseProxyURl forward slashes with dots. --->
		<cfset application.baseComponentPath = getBaseComponentPath()>

		<!--- Enable ORM. --->
		<cfset initOrm()>

		<cfif debug>
			<cfoutput>
			getBaseTemplatePath(): #getBaseTemplatePath()#<br/>
			application.rootPath: #application.rootPath#<br/>
			application.blogIniPath: #application.blogIniPath#<br/>
			-- Site vars --<br/>
			getInstalled(): #getInstalled()#<br/>
			getSiteUrl(): #getSiteUrl()#<br/>
			application.siteUrl: #application.siteUrl#<br/>
			application.blogDomain: #application.blogDomain#<br/>
			application.blogHostUrl = #application.blogHostUrl#<br/>
			getRootUrl(): #getRootUrl()#<br/>
			getBaseUrl(): #getBaseUrl()#<br/>
			-- Database vars --<br/>
			getDatabaseType(): #getDatabaseType()#<br/>
			getDsn(): #getDsn()#<br>
			application.dsn: #application.dsn#<br>
			-- Server vars --<br/>
			serverSupportsWebP(): #serverSupportsWebP()#<br/>
			serverSupportsWoff2(): #serverSupportsWoff2()#<br/>
			</cfoutput>
		</cfif>
				
		<!--- Determine if we need to run the installer. Do not run the installer prior to the ORM declaration. --->
		<cfif reinstallIni or (isBoolean(getInstalled()) and not getInstalled() and not len(dsn))>
			<!--- Display the inital welcome screen and get the DSN from the user to create the initial database --->
			<cflocation url="installer/initial/index.cfm?notInstalled" addToken="false">
		</cfif>
			
		<!--- After the ORM has been reloaded in order to create the initial database, continue to install the blog by populating the database. The saveDsnCredentials.cfm template in the install directory has just redirected to the index.cfm page with the init argument. If we continue processing without populating the database we will have errors here. Note: when testing run this from the root home (index.cfm) page --->
		<cfif ( reinstallDb or isBoolean(getInstalled()) and not getInstalled() and len(getDsn()) )>
			<cfinclude template="installer/insertData.cfm">
		</cfif>
			
		<!---//****************************************************************************************
			Common ORM Db objects to get various blog settings.
		//*****************************************************************************************--->

		<!--- Pointer to the Raymond's blog cfc.--->
		<cfset application.blogCfcUrl = getBaseUrl() & '/org/camden/blog/blog.cfc' / >
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.blogComponentPath = application.baseComponentPath & ".org.camden.blog.blog">
		<cfelse>
			<cfset application.blogComponentPath = "org.camden.blog.blog">
		</cfif>

		<!--- Proxy controller --->
		<!--- Append the base URL with the proxyController. if there is a base url. If the site is installed in the root directory, we don't  want to append a dot to the proxyControllerComponentPath. --->
		<!--- Set the URL to the new proxy controller. The ProxyController is used to pass data to the blog.cfc and is extensively used in Ajax operations. --->
		<cfset application.proxyControllerUrl = getBaseUrl() & '/common/cfc/proxyController.cfc' / >
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.proxyControllerComponentPath = application.baseComponentPath & ".common.cfc.proxyController">
		<cfelse>
			<cfset application.proxyControllerComponentPath = "common.cfc.proxyController">
		</cfif>
			
		<!--- Pointer to the cfJson object. Used to read and prepare json data for our HTML5 widgets --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.cfJsonComponentPath = application.baseComponentPath & ".common.cfc.cfJson">
		<cfelse>
			<cfset application.cfJsonComponentPath = "common.cfc.cfJson">
		</cfif>
			
		<!--- Pointer to the common UDF.--->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.udfComponentPath = application.baseComponentPath & ".common.cfc.Udf">
		<cfelse>
			<cfset application.udfComponentPath = "common.cfc.Udf">
		</cfif>

		<!--- Perform the same logic for the Image component which is used to perform actions on images. However, we will not instantiate it and will only use this as needed.  --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.imageComponentPath = application.baseComponentPath & ".common.cfc.Image">
		<cfelse>
			<cfset application.imageComponentPath = "common.cfc.Image">
		</cfif>	

		<!--- The StringUtils component is used to peform string formatting, such as an enhanced trim funtion. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.stringUtilsComponentPath = application.baseComponentPath & ".common.cfc.StringUtils">
		<cfelse>
			<cfset application.stringUtilsComponentPath = "common.cfc.StringUtils">
		</cfif>	

		<!--- Our HTML Utils component is used to create alternating rows in tables --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.htmlUtilsComponentPath = application.baseComponentPath & ".common.cfc.HtmlUtils">
		<cfelse>
			<cfset application.htmlUtilsComponentPath = "common.cfc.HtmlUtils">
		</cfif>	

		<!--- The Render.cfc is used to render client side stuff from the database, such as creating the full image path with the proper classes --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.rendererComponentPath = application.baseComponentPath & ".common.cfc.Renderer">
		<cfelse>
			<cfset application.rendererComponentPath = "common.cfc.Renderer">
		</cfif>	

		<!--- The Moment.cfc is used for dates and sets the blogNow value --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.momentComponentPath = application.baseComponentPath & ".common.cfc.Moment">
		<cfelse>
			<cfset application.momentComponentPath = "common.cfc.Moment">
		</cfif>
			
		<!--- The Javaloader is used to load Jsoup. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.javaLoaderComponentPath = application.baseComponentPath & ".common.java.javaloader.JavaLoader">
		<cfelse>
			<cfset application.javaLoaderComponentPath = "common.java.javaloader.JavaLoader">
		</cfif>	
			
		<!--- JSoup is used to parse and glean data. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.jsoupComponentPath = application.baseComponentPath & ".common.cfc.JSoup">
		<cfelse>
			<cfset application.jsoupComponentPath = "common.cfc.JSoup">
		</cfif>	

		<cfif debug>
			<cfoutput>
			application.baseProxyUrl: #application.baseProxyUrl#<br/>
			application.baseComponentPath: #application.baseComponentPath#<br/>
			application.blogComponentPath: #application.blogComponentPath#<br/>
			</cfoutput>
		</cfif>
			
		<!---//****************************************************************************************
				Check server mime types.
		//*****************************************************************************************--->
			
		<!--- Check to see if the server is set up with the webp mime type. If so, we will deliver images via webp, which is a next gen image format. --->
		<cfset application.serverSupportsWebP = serverSupportsWebP()>
		<!--- Does the server have the woff2 mime type for woff2 fonts? --->
		<cfset application.serverSupportsWoff2 = serverSupportsWoff2()>			
			
		<!---//****************************************************************************************
				Load the blog Db Object
		//*****************************************************************************************--->
			
		<!--- Load the Blog Db object (there is only one record in this version) --->
		<cfset application.BlogDbObj = entityLoadByPK("Blog", 1)>			
		<!--- Load the BlogOptions Db Object (there is only one record in this version) --->
		<cfset application.BlogOptionDbObj = entityLoadByPK("BlogOption", 1)>
			
		<!--- Notes: the blogname reference here is really important to the underlying logic in this application. Raymond coded this. I assumed that this was just a label, or something else inconsequential. its not. It actually is the first line in the blog.ini.cfm file that sets the configuration for the entire application. Unless there is something that I missed, it is essential that you leave this alone.  I am not sure why you should ever edit this, it will break the blog. 
		Raymond's comment: "Edit this line if you are not using a default blog", but I am not sure why and when this would ever apply.
		--->
		<cfset blogname = "Default">
		<!--- load and init blog --->
		<cfset application.blog = createObject("component","#application.blogComponentPath#").init(blogname)>
			
		<!--- load the UDF component --->
		<cfset application.Udf = createObject("component","#application.udfComponentPath#")>
		
		<!---//****************************************************************************************
				Initialize the application and set core application vars.
		//*****************************************************************************************--->
			
		<!--- Load the Utils CFC --->
		<cfset application.utils = createObject("component", "org.camden.blog.utils")>

		<!--- Used to remember the pages we have viewed. Helps keep view count down. --->
		<cfif not structKeyExists(session,"viewedpages")>
			<cfset session.viewedpages = structNew()>
		</cfif>
			
		<!---//****************************************************************************************
				JQuery CDN
		//*****************************************************************************************--->
			
		<!--- Get the jquery CDN path --->
		<cfset  application.jQueryCDNPath = application.BlogOptionDbObj.getJQueryCDNPath()>
			
		<!---//****************************************************************************************
				Kendo Settings
		//*****************************************************************************************--->
			
		<cfset application.kendoCommercial = application.BlogOptionDbObj.getKendoCommercial()>
		<!--- Hardcoded value for testing. <cfset application.kendoCommercial = true>--->
			
		<!--- Get the path to the Kendo UI folder. --->
		<cfset application.kendoFolderPath = application.BlogOptionDbObj.getKendoFolderPath()>

		<!--- Kendo version (is Kendo the open source or commercial version?) default on the open source blog is true. --->
		<cfif application.kendoCommercial>
			<cfset application.kendoOpensource = "false">
			<!--- The location of the commercial Kendo is the application.kendoFolderPath.  --->
			<cfset kendoSourceLocation = application.kendoFolderPath>
		<cfelse>
			<!--- Point to the embedded Kendo Core folder. --->
			<cfset application.kendoOpensource = "true">
			<cfset kendoSourceLocation = getBaseUrl() & "/common/libs/kendoCore">
		</cfif>
		
		<!--- Kendo library locations --->
		<!--- Note: we are using an open source version of the Kendo library, Kendo Core. It does not have all of the bells and whistles of the comercial licence of course. --->
		<cfset application.kendoSourceLocation = kendoSourceLocation><!--- Commercial: /common/libs/kendo (without getBaseUrl() &). Open source: getBaseUrl() & "/common/libs/kendoCore" --->
		<cfset application.kendoUiExtendedLocation = getBaseUrl() & "/common/libs/kendoUiExtended">
		<cfset application.jQueryNotifyLocation = getBaseUrl() & "/common/libs/jQuery/jQueryNotify">
		<!--- Note: the original blogCfc came with an older jQuery UI than the one that I am using and it is creating conflicts. We need to have two different jQuery incluedes, one for the administration part of the site, and the newer jquery UI for the new blogCfc.--->
		<cfset application.adminjQueryUiPath = getBaseUrl() & "/includes/jqueryui/jqueryui.js">
			
		<!--- jSoup (note: this is bracketed as the init function expects an array) --->
		<cfset application.jSoupPath = [expandPath("#getBaseUrl()#/common/java/jSoup/jsoup-1.13.1.jar")]>
		<!--- Create an instance of the jSoup java object --->
		<cfset application.jsoupJavaloader = createObject("component", application.javaLoaderComponentPath).init(application.jSoupPath)>
			
		<!--- //****************************************************************************************
				User defined settings.
		//******************************************************************************************--->
		
		<!--- The blog will always use SSL if it is available. You may turn this setting off in the administrative interface. --->
		<cfset application.useSsl = application.BlogOptionDbObj.getUseSsl()>
		
		<!--- Does the blog use URL rewrite rules to hide index.cfm from the URL? --->
		<cfset application.serverRewriteRuleInPlace = application.BlogOptionDbObj.getServerRewriteRuleInPlace()>
			
		<!--- I minimized some of the code (such as the .css). The only reason to turn it off is to access the prettified source code. --->
		<cfset application.minimizeCode = application.BlogOptionDbObj.getMinimizeCode()>
			
		<!--- The user can turn off the caching features in order to debug stuff --->
		<cfset application.disableCache = application.BlogOptionDbObj.getDisableCache()>
			
		<!--- How many posts should show up on the main blog page? --->
		<cfset application.maxEntries = application.BlogOptionDbObj.getEntriesPerBlogPage()><!--- 10 --->

		<!--- Optional libraries --->
		<!--- GSAP and scrollMagic allows for animations and parallax effects in the blog entries. don't include by default. --->
		<cfset application.includeGsap = application.BlogOptionDbObj.getIncludeGsap()>

		<!--- Determine whether to include the disqus commenting system. If you set this to true, you must also set the optional disqus settings that are right below. Note: this is an application var so that the recentcomments.cfm can access these settings. That template is invoked via a cfmodule tag. --->
		<cfset application.includeDisqus = application.BlogOptionDbObj.getIncludeDisqus()>

		<!--- Setting to determine whether to defer the scripts and css. This is a hardcoded setting. You should only change this to debug to see if the defer is working, but you should leave this at true as it provides a much better google speed score. --->
		<cfset application.deferScriptsAndCss = true>

		<!--- Gravatars allowed? --->
		<cfset application.gravatarsAllowed = application.BlogOptionDbObj.getAllowGravatar()>
			
		<!--- Do we have comment moderation? --->
		<cfset application.commentModeration = application.BlogOptionDbObj.getBlogModerated()>

		<!--- Video player settings. We have several options. Our default player is plyr. It is a full featured HTML5 media player, however, it does not play flash video. This should not be a problem as flash is soon to be depracated. Optionally, we can use the Kendo UI video player if you have a full Kendo license. The original flash player will take over for .flv videos, but will be depracated in 2020. --->
		<cfset application.defaultMediaPlayer = application.BlogOptionDbObj.getDefaultMediaPlayer()><!---You can optionally choose 'KendoUiPlayer' if you have the full lisence. However, the Kendo Media player is lacks quite a few plyr features. The Kendo player is useful if you want the video player to take on the theme that you are using. --->
			
		<!--- This is Googles gtag string and is used for analytics. --->
		<cfset application.googleAnalyticsString = application.BlogOptionDbObj.getGoogleAnalyticsString()>

		<!--- The addThis toolbox string changes depending upon the site and the configuration. --->
		<cfset application.addThisToolboxString = application.BlogOptionDbObj.getAddThisToolboxString()><!---Typically 'addthis_inline_share_toolbox'--->
					
		<!--- The addThis api key is found on the addThis.com site. There is a tutorial how to use this on Gregory's blog. --->
		<cfset application.addThisApiKey = application.BlogOptionDbObj.getAddThisApiKey()>
			
		<!--- Optional Bing Map API (used for Bing Maps) --->
		<cfset application.bingMapsApiKey = application.BlogOptionDbObj.getBingMapsApiKey()>

		<!--- //****************************************************************************************
					Optional disqus settings. Set these if you set includeDisqus to true. The first setting is required, the rest are optional settings.
		//******************************************************************************************--->

		<cfset application.disqusBlogIdentifier = application.BlogOptionDbObj.getDisqusBlogIdentifier()><!--- Required if you're using Disqus. Note: this is intentionally set as an application var. ---> 
		<cfset application.disqusApiKey = application.BlogOptionDbObj.getDisqusApiKey()><!--- Optional if you're using Disqus - if you do not have an API key, leave this blank. Note: this is intentionally set as an application var. --->
		<cfset application.disqusApiSecret = application.BlogOptionDbObj.getDisqusApiSecret()><!--- Optional if you're using Disqus - if you do not have an API Secret, leave this blank. --->
		<cfset application.disqusAuthTokenKey = application.BlogOptionDbObj.getDisqusAuthTokenKey()><!--- Optional if you're using Disqus - if you do not have an API Secret, leave this blank. --->
		<cfset disqusAuthUrl = application.BlogOptionDbObj.getDisqusAuthUrl()><!--- Leave this alone unless you konw what you're doing. --->
		<cfset disqusAuthTokenUrl = application.BlogOptionDbObj.getDisqusAuthTokenUrl()><!--- Leave this alone unless you konw what you're doing. --->

		<!--- Facebook Id --->
		<cfset application.facebookAppId = application.BlogOptionDbObj.getFacebookAppId()>
		<!--- Twitter Id --->
		<cfset application.twitterAppId = application.BlogOptionDbObj.getTwitterAppId()>	

		<!--- 10/26/2018 Gregory Alexander added the following parameters to better customize the blog --->
		<!--- Gregory: Preset the isAdmin session var to false if the user is not logged in. We can infer if the user is not logged in that they are not an admin user. If they are logged in, the login code in the /client/admin/Application.cfm template will set the session.isAdmin to true if all conditions are met (which currently is all of the time if the user is logged in). --->
		<cfif not structKeyExists(session,"loggedin")>
			<cfset session.isAdmin = false>
		</cfif>

		<!---//****************************************************************************************
						The following settings are set in the administrator settings page (/admin/).
		//*****************************************************************************************--->

		<!--- The parent site name (that the blog is hosted on). If this param is entered, the home button on the site will take you to the main site name as well as the main blog page. Leave blank if the blog is the main site. --->
		<cfset application.parentSiteName = application.BlogDbObj.getBlogParentSiteName() />
		<!--- Specify the parent site link. I am setting this as the parent site URL may be located on a different server and I can't assume that it is just the cgi.Server_Name. --->
		<cfset application.parentSiteLink = application.BlogDbObj.getBlogParentSiteUrl() />
		<!---<cfset application.parentSiteLink = urlParts[1] & urlParts[2]>--->

		<!---//****************************************************************************************
						Mobile device detection
		//*****************************************************************************************--->

		<!--- Gregory updated the device detection code on Feb 6 2019 (from http://detectmobilebrowsers.com/)--->
		<cfif 
		(reFindNoCase("(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino",CGI.HTTP_USER_AGENT) GT 0 OR reFindNoCase("1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-",Left(CGI.HTTP_USER_AGENT,4)) GT 0)>
			<cfset session.isMobile = true>
		<cfelse>
			<cfset session.isMobile = false>
		</cfif>

		<!--- Initialize the application if it has not already been done. --->
		<cfif not isDefined("application.init")>
			<cfset init = this.applicationInit()>
		</cfif>
			
		<cfsetting enablecfoutputonly="false"> 
			
	</cffunction>
			
	<!---//****************************************************************************************
						Initialize application vars 
	//*****************************************************************************************--->
			
	<!--- Note: This function is also consumed on the admin settings page in order to get all of the settings --->
	<cffunction name="applicationInit" access="public" returntype="boolean" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page.">

		<!--- Do we need to run the installer? --->
		<!--- Determine if we need to run the installer. Do not run the installer prior to the ORM declaration. --->
		<cfif not getInstalled()>
			<cflocation url="installer/initial/index.cfm?notInstalled" addToken="false">
		</cfif>

		<!--- Path may be different if admin. --->
		<cfset currentPath = getDirectoryFromPath(getCurrentTemplatePath()) />
		<cfset theFile = currentPath & "includes/main" />
		<cfset lylaFile = application.Udf.getRelativePath(currentPath & "includes/captcha.xml") />

		<!--- Use Captcha? --->
		<cfset application.useCaptcha = application.BlogOptionDbObj.getUseCaptcha()>

		<cfif application.usecaptcha>
			<cfset application.captcha = createObject("component","org.captcha.captchaService").init(configFile="#lylaFile#") />
			<cfset application.captcha.setup() />
		</cfif>

		<!--- clear scopecache --->
		<cfmodule template="tags/scopecache.cfm" scope="application" clearall="true">

		<cfset majorVersion = listFirst(server.coldfusion.productversion)>
		<cfset minorVersion = listGetAt(server.coldfusion.productversion,2,",.")>
		<cfset cfversion = majorVersion & "." & minorVersion>

		<cfset application.isColdFusionMX7 = server.coldfusion.productname is "ColdFusion Server" and cfversion gte 7>

		<!--- used for cache purposes is 60 minutes --->
		<cfset application.timeout = 60*60>
			
		<!--- Do we allow file browsing in the admin? --->
		<cfset application.filebrowse = true>

		<!--- Do we allow settings in the admin? --->
		<cfset application.settings = true>

		<!--- Finally, do a DSN check --->
		<!--- We end up throwing away this call, but it should be lightweight --->
		<cftry>
			<cfset void = application.BlogDbObj.getBlogParentSiteName()>
			<cfcatch type="any">
				The DSN is not set up correctly.
				<cfabort>
			</cfcatch>
		</cftry>
			
		<!---Set the application.init flag to true.--->
		<cfset application.init = true>

		<cfreturn true>
		<!---Exit the function.--->
	</cffunction>
			
	<!---//****************************************************************************************
			Functions that set vars based upon the blog.ini file.
			These are written to avoid using the file system again when the variables are already set. Use the reset argument to read the properties from the file.
	//*****************************************************************************************--->
			
	<cffunction name="getRootPath" access="remote" returnType="string"
			hint="Get the site's root path. This returns the full path of the root directory. This does not have any dependencies.">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the root path.">
		
		<cfif isDefined("application.rootPath") and len(application.rootPath) and not arguments.reset>
			<cfset rootPath = application.rootPath>
		<cfelse>
			<cfset rootPath = replaceNoCase( getDirectoryFromPath( getBaseTemplatePath()), "index.cfm", "") />
		</cfif>
		
		<cfreturn rootPath>
		
	</cffunction>
				
	<cffunction name="getBlogIniPath" access="remote" returnType="string"
			hint="Get the path to the ini file which stores our constant variables">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the path.">
		
		<cfif isDefined("application.blogIniPath") and len(application.blogIniPath) and not arguments.reset>
			<cfset blogIniPath = application.blogIniPath>
		<cfelse>
			<cfset blogIniPath = getRootPath(true) & 'org\camden\blog\blog.ini.cfm'>
		</cfif>
		
		<cfreturn blogIniPath>
		
	</cffunction>
				
	<cffunction name="getSiteUrl" access="remote" returnType="string"
			hint="Get the site's URL">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the site url.">
		
		<!--- Return the current application.rootUrl if it exists. --->
		<cfif isDefined("application.siteUrl") and len(application.siteUrl) and not arguments.reset>
			<cfset siteUrl = application.siteUrl>
		<!--- Get the siteUrl from the db. --->
		<cfelseif isDefined("this.ormInitialized") and isDefined("application.BlogDbObj")>
			<!--- Get the siteUrl from the DB  --->
			<cfset siteUrl = application.BlogDbObj.getBlogUrl()>
		<!--- Get the rootUrl from the ini file. --->
		<cfelseif isDefined("application.blogIniPath") and len(application.blogIniPath)>
			<!--- Get the siteUrl from the blog.ini file  --->
			<cftry>
				<cfset siteUrl = getProfileString(application.blogIniPath, "default", "blogUrl")>
				<cfcatch type="any">
					<!--- This should only happen when initially installing the blog. --->
					<cfset siteUrl = ""/>
				</cfcatch>
			</cftry>
		<cfelse>
			<!--- Determine the URL by the current page. --->
			<cfset siteUrl = parseUri().source>
		</cfif>
				
		<cfreturn siteUrl>
		
	</cffunction>
			
	<cffunction name="getRootUrl" access="remote" output="yes" returnType="string"
			hint="The rootUrl is the siteUrl minus the forward slash and the script name (ie. 'https://www.gregoryalexander.com/blog'. Everything filters from the rootUrl. It is imperative that this function gets the correct data and that it is set once. Use this to set the application.rootUrl">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the root url.">
		
		<!--- Return the current application.rootUrl if it exists. --->
		<cfif isDefined("application.rootUrl") and len(application.rootUrl) and not arguments.reset>
			<cfset rootUrl = application.rootUrl>
		<cfelse>
			<!--- Pass the site URL to the parseUri function and get the relative struct key. --->
			<cfset rootUrl = parseUri(getSiteUrl()).relative>
		</cfif>
				
		<cfreturn rootUrl>
		
	</cffunction>
		
	<cffunction name="getBaseUrl" access="remote" returnType="string"
			hint="The baseUrl is the rootUrl minus the domain and the script name. It should look something like this '/galaxieBlog'. It must not have the final forward slash at the end. This is used to set the path on nearly everything in the site and it uses the function above to get the rootUrl. We are using the parseUri function below and getting the relative struct key.">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the base url.">
		
		<!--- Return the current application.rootUrl if it exists. --->
		<cfif isDefined("application.baseUrl") and len(application.baseUrl) and not arguments.reset>
			<cfset baseUrl = application.baseUrl>
		<cfelse>
			<!--- Remove the '/index.cfm' string from the siteUrl --->
			<cfset cleanedUrl = replaceNoCase(getSiteUrl(), "/index.cfm", "")>
			<!--- Get the baseUrl from by parsing the URI using the new URL. --->
			<cfset baseUrl = parseUri(cleanedUrl).relative>
		</cfif>
				
		<cfreturn baseUrl>
		
	</cffunction>
				
	<cffunction name="getDsn" access="remote" returnType="string">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset this var.">
		
		<!--- Return the current application.rootUrl if it exists. --->
		<cfif isDefined("application.dsn") and len(application.dsn) and not arguments.reset>
			<cfset dsn = application.dsn>
		<cfelse>
			<cftry>
				<!--- Get the DSN from the ini file --->
				<cfset dsn = getProfileString(application.blogIniPath, "default", "dsn")>
				<cfcatch type="any">
					<!--- This should only happen when initially installing the blog. --->
					<cfset dsn = ""/>
				</cfcatch>
			</cftry>
		</cfif>
				
		<cfreturn dsn><!---gregorysBlog--->
		
	</cffunction>
			
	<cffunction name="getDatabaseType" access="remote" returnType="string">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset this var.">
		
		<!--- Return the current application.rootUrl if it exists. --->
		<cfif isDefined("application.databaseType") and len(application.databaseType) and not arguments.reset>
			<cfset databaseType = application.databaseType>
		<cfelseif isDefined("this.ormInitialized") and isDefined("application.BlogDbObj")>
			<!--- Get the db type from the DB  --->
			<cfset databaseType = application.BlogDbObj.getBlogDatabaseType()>
		<cfelse>
			<!--- Get the dialect from the ini file --->
			<cftry>
				<cfset databaseType = getProfileString(application.blogIniPath, "default", "databaseType")>
				<cfcatch type="any">
					<!--- This should only happen when initially installing the blog. --->
					<cfset databaseType = ""/>
				</cfcatch>
			</cftry>
		</cfif>
				
		<cfreturn databaseType>
		
	</cffunction>
			
	<cffunction name="getInstalled" access="remote" returnType="string">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset this var.">
		
		<!--- Return the current application.rootUrl if it exists. --->
		<cfif isDefined("application.installed") and isBoolean(application.installed) and not arguments.reset>
			<cfset installed = application.installed>
		<cfelseif isDefined("this.ormInitialized") and isDefined("application.BlogDbObj")>
			<!--- Get it from the db. --->
			<cfif isBoolean(application.BlogDbObj.getBlogInstalled())>
				<cfset installed = application.BlogDbObj.getBlogInstalled()>
			</cfif>
		<cfelse>
			<!--- Get it from the ini file --->
			<cftry>
				<cfset installed = getProfileString(application.blogIniPath, "default", "installed")>
				<cfcatch type="any">
					<!--- This should only happen when initially installing the blog. --->
					<cfset installed = false />
				</cfcatch>
			</cftry>
		</cfif>
				
		<cfreturn installed>
		
	</cffunction>
			
	<cffunction name="getBaseProxyUrl" access="remote" returnType="string"
			hint="Get the path to the ini file which stores our constant variables">
		<cfargument name="reset" type="boolean" default="true" required="false" hint="Set to true to read reset this var.">
		
		<cfif isDefined("application.baseProxyUrl") and len(application.baseProxyUrl) and not arguments.reset>
			<cfset baseProxyUrl = application.baseProxyUrl>
		<cfelse>
			<!--- Remove the first forward slash in the baseUrl. --->
			<cfset baseProxyUrl = replace(getBaseUrl(true), "/", "", "one")>
			<!--- Remove the index.cfm. This may occur when first installing the blog --->
			<cfset baseProxyUrl = replaceNoCase(baseProxyUrl, 'index.cfm', '', 'all')>
		</cfif>
			
		<cfreturn baseProxyUrl>
		
	</cffunction>
			
	<cffunction name="getBaseComponentPath" access="remote" returnType="string"
			hint="Get the base component path">
		<cfargument name="reset" type="boolean" default="true" required="false" hint="Set to true to read reset this var.">
		
		<cfif isDefined("application.baseComponentPath") and len(application.baseComponentPath) and not arguments.reset>
			<cfset baseComponentPath = application.baseComponentPath>
		<cfelse>
			<!--- Set the base component path by replacing the baseProxyURl forward slashes with dots. --->
			<cfset baseComponentPath = replace(getBaseProxyUrl(true), "/", ".", "all")>
		</cfif>
		
		<cfreturn baseComponentPath>
		
	</cffunction>
			
	<!---//****************************************************************************************
			Parse the URL. The 3 functions above use this method to parse the URI
	//*****************************************************************************************--->
			
	<!--- parseUri CF v0.2, originally by Steven Levithan: http://stevenlevithan.com. Minor changes by Gregory --->
	<cffunction name="parseUri" returntype="struct" output="false" hint="Splits any well-formed URI into its components">
		<cfargument name="sourceUri" type="string" required="no" default=""/>

		<!--- If the sourceUri is not passed, use the CGI.HTTP_URL --->
		<cfif not len(arguments.sourceUri)>
			<cfset arguments.sourceUri = CGI.HTTP_URL>
		</cfif>

		<!--- Create an array containing the names of each key we will add to the uri struct --->
		<cfset var uriPartNames = listToArray("source,protocol,authority,userInfo,user,password,host,port,relative,path,directory") />
		<!--- Full list: source,protocol,authority,userInfo,user,password,host,port,relative,path,directory,file,query,anchor --->
		<!--- Get arrays named len and pos, containing the lengths and positions of each URI part (all are optional) --->
		<cfset var uriParts = reFind("^(?:(?![^:@]+:[^:@/]*@)([^:/?##.]+):)?(?://)?((?:(([^:@]*):?([^:@]*))?@)?([^:/?##]*)(?::(\d*))?)(((/(?:[^?##](?![^?##/]*\.[^?##/.]+(?:[?##]|$)))*/?)?([^?##/]*))(?:\?([^##]*))?(?:##(.*))?)",
			sourceUri, 1, true) />
		<cfset var uri = structNew() />
		<cfset var i = 1 />

		<cfloop index="i" from="1" to="#arrayLen(uriPartNames)#">
			<!--- If the part was found in the source URI...
			- The arrayLen() check is needed to prevent a CF error when sourceUri is empty due to a bug,
			  reFind() does not populate backreferences for zero-length capturing groups when run against an empty string
			  (though it does still populate backreference 0).
			- The pos[i] value check is needed to prevent a CF error when mid() is passed a start value of 0, because of
			  the way reFind() considers an optional capturing group that does not match anything to have a pos of 0. --->
			<cfif (arraylen(uriParts.pos) GT 1) AND (uriParts.pos[i] GT 0)>
				<!--- Add the part to its corresponding key in the uri struct --->
				<cfset uri[uriPartNames[i]] = mid(sourceUri, uriParts.pos[i], uriParts.len[i]) />
			<!--- Otherwise, set the key value to an empty string --->
			<cfelse>
				<cfset uri[uriPartNames[i]] = "" />
			</cfif>
		</cfloop>

		<!--- Always end directory with a trailing backslash if a path was present in the source URI.
		Note that a trailing backslash is NOT automatically inserted within or appended to the relative or path parts --->
		<cfif len(uri.directory) gt 0>
			<cfset uri.directory = reReplace(uri.directory, "/?$", "/") />
		</cfif>

		<cfreturn uri />
	</cffunction>
			
	<!---//****************************************************************************************
				Determine if the server supports webp images and .woff2 fonts.
	//*****************************************************************************************--->
				
	<!--- Determine if the server supports webp images and .woff2 fonts. --->
			
	<!--- Determine if the webP mime type is set up on the server. --->
	<cffunction name="serverSupportsWebP" access="public" returntype="boolean" output="yes">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset this var.">
		
		<cfparam name="webp" default="false">
			
		<cfif isDefined("application.serverSupportsWebP") and not arguments.reset>
			<cfset webp = application.serverSupportsWebP>
		<cfelse>
			<cftry>
				<!--- Note: we need to eliminate https from the root URL if it exists. I ran into errors trying this with https (a cryptic certificate error). --->
				<cfset thisUrl = replaceNoCase(application.siteUrl, "https", "http")>
				<!--- The headerBodyDivider image is a tiny .webp image (around 1k). We are going to read this, and if it was found and the mime type is correct, we will assumed that the mime type is correct. Otherwise, we will determine that the server does not support the webp mime type. --->
				<cfhttp method="get" URL="#thisUrl#/images/divider/headerBodyDivider.webp">

				<!--- Was the webp image found? --->
				<cfif cfhttp.mimeType contains 'webp'>
					<cfset webp = true>
				<cfelse>
					<cfset webp = false>
				</cfif>
				<cfcatch type="any">
					<cfset webp = false>	
				</cfcatch>
			</cftry>
		</cfif>

		<!--- Return it. --->
		<cfreturn webp>
	</cffunction>
			
	<!--- Determine if the woff2 mime type is set up on the server. --->
	<cffunction name="serverSupportsWoff2" access="public" returntype="boolean" output="yes">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset this var.">
			
		<cfif isDefined("application.serverSupportsWoff2") and not arguments.reset>
			<cfset woff2 = application.serverSupportsWoff2>
		<cfelse>
			<cftry>
				<!--- Try to get a known font --->
				<cfhttp method="get" URL="#getBaseUrl()#/common/fonts/eras-demi.woff2">

				<!--- Was the woff2 font found? --->
				<cfif cfhttp.mimeType contains 'woff2'>
					<cfset woff2 = true>
				<cfelse>
					<cfset woff2 = false>
				</cfif>
				<cfcatch type="any">
					<cfset woff2 = false>	
				</cfcatch>
			</cftry>
					
		</cfif>
					
		<!--- Return it. --->
		<cfreturn woff2>
	</cffunction>
	
</cfcomponent>