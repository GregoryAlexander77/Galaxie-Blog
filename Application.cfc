<cfcomponent displayname="GalaxieBlog4_65" sessionmanagement="yes" clientmanagement="yes" output="false">
	<cfsetting requesttimeout="60">

	<!--- The name needs to be unique in order to have multiple blogs on the same server: blogs with the same name share the application scope. The name is made unique by adding a short hash of the folder that this file is in, so nothing needs to be edited when a second blog is installed. --->
	<cfset this.name = "GalaxieBlog4_65_" & left(hash(getDirectoryFromPath(getCurrentTemplatePath())), 10) />
	<!--- Preserve the case for database columns --->
	<cfset this.serialization.preserveCaseForQueryColumn = true>
	<!--- Set the root directory. This returns the full path. Note: this will have a forward slash at the end of the string '/' --->
	<cfset this.rootDirectoryPath = getDirectoryFromPath( getCurrentTemplatePath() )>

	<!--- Print out some of the vars for debugging purposes. Change the first line to read output="true" --->
	<cfset debug = false>
		
	<!--- Used for testing purposes only. Setting this var to true will allow you to re-run the 7 part initial in. Note: if you want to run the entire install process, change the installed variable to an empty string in the ini file.  --->
	<cfset reinstallIni = false> 
	<!--- Reinstalls the database from the installer files. Note: this allows you to recover from a partially installed database if there are data errors, timeouts, or database issues, such as too many connections when using MySql. Open the insertData.cfm template in the installer folder to see your available recovery options. When you're done, make sure that you change this back to false! --->
	<cfset reinstallDb = false>
		
	<!--- Allows the owner to access the admin portal without the proper user credentials. --->
	<cfset disableAuth = false>
	<!--- Error logging is typically set in the admin UI, however, when developing you can turn it off manually --->
	<cfset disableErrorLogging = false>

	<!--- 7 day application timeout. Be careful when you change this to a shorter timeout otherwise the variables on the admin pages won't stick --->
	<cfset this.applicationTimeout = createTimeSpan(7,0,0,0) />
	<cfset this.sessionManagement="yes"/>
	<!--- 4 hour session timeout. It can take a long time to create a post and I don't  want to force the user to reload the page --->
	<cfset this.sessiontimeout = createTimeSpan(0,4,0,0) >
	<!--- I had set this to false prior to version 4 as I did not want the user to type in a long comment only to have it fail if the session timeout has expired. However, with Lucee, I can't set sesison variables unless the client has signed in the admin site.
	--->
	<cfset this.setClientCookies = true />
	<cfset this.enablerobustexception = true />
		
	<!--- Turn on script protection. The admin site has this disabled tho --->
	<cfset this.scriptProtect = "all">

	<!--- The administrative site (the /admin/ folder) used to have its own Application.cfc that extended this one, which forced the installer to have you edit an 'extends' path that depended on where the blog was placed. The admin site's settings are now applied here, by checking where the requested template lives on disk, so the blog works in any folder with nothing to configure. The admin login logic is in adminRequestStart() below. --->
	<cfif isAdminRequest()>
		<!--- Authors need to be able to use scripts in their posts. --->
		<cfset this.scriptProtect = "none">
		<!--- 1 hour session timeout on the admin site. --->
		<cfset this.sessiontimeout = createTimeSpan(0,1,0,0)>
	</cfif>

	<!--- Note: do not user mappings here. Mappings do not work with CF ORM. They are causing errors. --->
		
	<!--- 
	Create a reference to this component so that other functions can reset the application vars without a URL. 
	To reinitalize from other templates use application.applicationObj.applicationInit() 
	--->
	<cfset application.applicationObj = this>
		
	<!--- Set the blogIniPath in order to get the variables. --->
	<cfset application.blogIniPath = getBlogIniPath()>
		
	<!---//****************************************************************************************
				jSoup
	//*****************************************************************************************--->
		
	<!--- Note: this may cause an error when you're first installing the blog as the proper paths are not yet set. --->
	<cfif getInstalled()>
		<!--- Create the path. This is bracketed as the init function expects an array --->
		<cfset application.jSoupPath = [expandPath(getBaseUrl() & "/common/java/jSoup/jsoup-1.15.1.jar")]>
		<!--- Load Jsoup using this.javaSettings. Don't create the object until it is needed. This will be done in Jsoup.cfc --->
		<cfset this.javaSettings = { loadPaths = application.jSoupPath, loadColdFusionClassPath=true, reloadOnChange=false }>
	</cfif><!---<cfif getInstalled()>--->
		
	<!--- Enable ORM --->
	<cfset initOrm()>
	
	<!---//****************************************************************************************
				ORM
	//*****************************************************************************************--->
			
	<cffunction name="initOrm"> 
		
		<!--- Put this in a try block as the database might not be set up when installing. --->
		<!--- The datasource and the database type are read straight from the ini file in this folder. This code runs in the constructor, and Lucee also creates this component without an application (to read the settings), and the application scope that is visible then may belong to another blog on the same server. --->
		<cfset ormDsn = getIniValue("dsn")>
		<!--- getDsn() also sets the dsn variable that the other functions in this component use, so it must still be called. --->
		<cfset getDsn()>
		<cfif not len(ormDsn)>
			<cfset ormDsn = getDsn()>
		</cfif>
		<cfif len(ormDsn)>

			<cfset this.ormEnabled = "true">
			<!--- Get the datasource from the ini file, on Adobe ColdFusion and on Lucee. This is required as the database may not be set up yet prior to installing the blog and we need somewhere to store the name of the datasource. The datasource with this name must exist in the Lucee or ColdFusion administrator. This used to be hard coded to GalaxieDb on Lucee, which meant that every Lucee blog had to use a datasource with that name, and two blogs on one server could not have their own databases. The path to the ini file is built from the folder that this file is in (see getBlogIniPath), so it does not depend on the URL. --->
			<cfset this.datasource = ormDsn>
			<!--- At this time, the dialect is always 'auto'. --->
			<cfset this.dialect = 'auto'>
			<!--- Allow ColdFusion to update and create the tables when they do not already exist. Use none *only* if you are migrating between ColdFusion and Lucee --->
			<cfset this.ormSettings.dbcreate = "update"><!---update--->
			<!--- Seven of the entities (Post, Comment, etc.) have long text columns, which each database vendor declares differently (varchar(max), longtext, clob...). Set them to the type of the database that was chosen when the blog was installed. This must happen before ORM reads the entities. --->
			<cfset applyDatabaseOrmTypes()>
			<!--- Set a pointer to the cfc directory. This is a file system path (not built from the blog's URL) so the blog can be installed in the root or in any folder. --->
			<cfset this.ormSettings.cfclocation = this.rootDirectoryPath & "common/cfc/db/galaxieDb/">
			<!--- Note: without this argument, you will have a 'Session is closed!' error everytime you hit a function that processes a database transaction simultaneously. Use a transaction tag to commit the data instead. --->
			<cfset this.ormsettings.flushAtRequestEnd = false>
			<!--- Unfortunately, on occasion, there are database deadlocks. I want to set a quick timeout in order to convserve server resources. --->
			<cfset this.ormSettings.queryTimeout = 5>
			<!--- Escape reserved database keywords (such as 'Role') which cause generic errors. --->
			<cfset this.ormsettings.hibernate.globally_quoted_identifiers = true>
			<!--- Enable ORM offset in queries. --->
			<cfset this.ormsettings.legacy_limit_handler = true>
			<!--- Always throw errors if present --->
			<cfset this.ormsettings.skipCFCWithError = false>
			<!--- Inspects the database for mapping --->
			<cfset this.ormsettings.useDBForMapping = false>
			<!--- Typically we want to enable secondary cache allowing us to use the cachedwithin argument on HQL queries, however, a new CF2023 ColdFusion bug makes this problematic as there are errors. See https://tracker.adobe.com/#/view/CF-4219346.  --->
			<cfset this.ormSettings.secondaryCacheEnabled = false> 
			<!--- Log SQL (set to true in dev environments) --->
			<cfset this.ormsettings.logsql = false>
			<!--- Only use this when debugging <cfset this.ormsettings.skipCFCWithError = true> --->
			<!--- Set a flag that ORM has been initialized --->
			<cfset this.ormInitialized = true>
			
		</cfif><!---<cfif len(getDsn())>--->
					
	</cffunction> 
		
	<cffunction name="OnRequestStart">

		<!--- Requests for templates in the /admin/ folder are handled by the admin logic (logon, session flags, etc.) instead of the site logic below. --->
		<cfif isAdminRequest()>
			<cfset adminRequestStart()>
			<cfreturn true>
		</cfif>

		<!--- We will send copies of any error, minus form values, to the developer for debugging purposes. Note: although this helps me to catch errors, if you don't want to send the errors to the developer (i.e. me), make this an empty string (='') --->
		<cfset application.developerEmailAddress = "gregoryalexander77@gmail.com">

		<!--- //****************************************************************************************
				Error/lock storm throttling - tunable settings and in-memory trackers.
				Used by onError (below) and blog.cfc's isTemporarilyTimedOut/recordDatabaseLockError/
				shouldSendErrorEmail/getAndClearSuppressedErrorEmailCount to stop a bot that is hammering
				the site (and causing org.hibernate.exception.LockAcquisitionException DB lock errors)
				from also flooding the ErrorLog table and the developer/blog owner's inbox.
				Note: this whole block must be guarded by structKeyExists - OnRequestStart runs on
				*every* request (there is no onApplicationStart in this component), so without the guard
				these trackers - and every IP's timeout/lock counts - would be wiped out on every single
				page view instead of persisting for the life of the application.
		//*****************************************************************************************--->
		<cfif not structKeyExists(application, "dbLockTracker")>
			<cflock name="galaxieBlog.initThrottleTrackers" type="exclusive" timeout="10">
				<cfif not structKeyExists(application, "dbLockTracker")>
					<!--- How many org.hibernate.exception.LockAcquisitionException errors from the same IP, within dbLockTimeoutWindowSeconds, before that IP is placed into a temporary timeout. --->
					<cfset application.dbLockTimeoutThreshold = 5>
					<cfset application.dbLockTimeoutWindowSeconds = 60>
					<!--- How long the temporary timeout lasts once triggered. --->
					<cfset application.dbLockTimeoutDurationMinutes = 15>
					<!--- Per-IP sliding-window counters feeding the threshold above: ipAddress -> { windowStart, count }. --->
					<cfset application.dbLockTracker = structNew()>
					<!--- ipAddress -> the date/time its temporary timeout expires. Checked by isTemporarilyTimedOut(); never written to the database. --->
					<cfset application.temporaryTimeouts = structNew()>

					<!--- Global (not per-IP) error email rate limit, so a burst of many *different* errors across many different URLs/IPs can't flood the inbox either - the per-URL+message dedup in saveErrorLog only catches repeats of the exact same error. --->
					<cfset application.errorEmailMaxPerWindow = 5>
					<cfset application.errorEmailWindowSeconds = 300>
					<cfset application.errorEmailThrottle = { windowStart: now(), count: 0, suppressedCount: 0 }>
				</cfif>
			</cflock>
		</cfif>

		<!--- Reload the ORM schema. Note: forcing this to load on every page load will create ORM related errors when including the mapPreview.cfm template. The error is 'Orm not configured...' most likely due to the ORMReload statement interfering with the ORM initialization. ' --->
		<!--- Security: URL.init/URL.reinit resets app-level vars and flushes all caches. Since this has real side effects, only allow it to be triggered via the URL when an administrator is already logged in (application.Udf.isLoggedIn() checks session.loggedin, the same session flag set by ProxyController.cfc's ajaxLogin() on successful admin login) - OR when we're in the middle of installing the blog (not getInstalled()), since the 7 part initial installer (installer/initial/step7Post.cfm) redirects here with ?init=1&install=true before any admin account exists to log into - OR when reinstallIni/reinstallDb are true (the developer-only flags declared at the top of this component, manually flipped by someone who already has file system access, used to force a re-run of the installer/data population). An anonymous request carrying ?init=1/?reinit=1 outside of these cases is silently ignored - no error, no indication the param was seen. --->
		<cfif (isDefined("URL.init") or isDefined("URL.reinit")) and (application.Udf.isLoggedIn() or reinstallIni or reinstallDb or not getInstalled())>

			<!--- Reset the main app vars --->
			<cfset getRootDirectoryPath(true)>
			<cfset application.siteUrl = getSiteUrl(true)>
			<!--- The blogHostUrl is the site URL minus the index.cfm. --->
			<cfset application.blogHostUrl = replaceNoCase(getSiteUrl(true), '/index.cfm', '')>
			<cfset application.blogDomain = parseUri(application.blogHostUrl).host>
			<cfset application.baseUrl = getBaseUrl(true)>
			<cfset application.dsn = getDsn(true)>
			<cfset application.databaseType = getDatabaseType(true)>
			<cfset application.installed = getInstalled(true)>
			<!--- Ini file. Lucee change from application.blogIniPath to getIniPath() --->
			<cfset application.iniFile = expandPath(getBlogIniPath())>
			<!--- Set the common component paths --->
			<cfset application.baseProxyUrl = getBaseProxyUrl(true)>
			<cfset application.baseComponentPath = getBaseComponentPath(true)>
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
			<!--- Delete the cached html files. The pages, comments, bio, cards, pods, header, footer, fonts and rss feeds are cached to disk by galaxieCache, and unlike the caches above they are not cleared by the cache flush, so after uploading new templates the old html would be served until it was cleared by hand. Each file is rebuilt the next time it is needed. This is the same function that clears the cache of a post when it is saved (type 'post'). The blog object may not exist yet when first installing the blog. --->
			<cftry>
				<cfset application.blog.flushGalaxieCache(type='all')>
				<cfcatch type="any">
				</cfcatch>
			</cftry>
			<!--- 
			Debugging note: if you change the blog folder after installation, you may need to print these vars to reset them.
			<cfoutput>getSiteUrl(): #getSiteUrl()# application.BlogDbObj.getBlogUrl(): #application.BlogDbObj.getBlogUrl()# getProfileString(application.blogIniPath, "default", "blogUrl"): #getProfileString(application.blogIniPath, "default", "blogUrl")#<br/></cfoutput>
			--->
				
		</cfif><!---<cfif isDefined("URL.init") or isDefined("URL.reinit")>--->
				
		<!--- TODO Check to see if ORM needs to be reloaded. Since CF2023 I have often had errors that one of the columns is missing in one of the entities. This function will check to see if the column exists. If the logic in this function throws an error, it will return a false and we will reload the page. --->
		<cfif len(dsn)>
			<cftry>
				<cfquery name="Data" dbtype="hql">
					SELECT new Map (
						ThemeSettingRef.DisplayBlogName as DisplayBlogName
					)
					FROM 
						Theme as Theme
				</cfquery>
				<cfcatch type="any">
					<cfset ORMReload()>
				</cfcatch>
			</cftry>
		</cfif>
				
		<!--- Reload ORM --->
		<!--- Security: ORMReload() is expensive and briefly disrupts every in-flight request against the ORM. Only allow ?reloadOrm=1 to trigger it when an administrator is already logged in (same application.Udf.isLoggedIn() check as above), OR when we're mid-install / a developer-forced reinstall is in progress (same reinstallIni/reinstallDb/not getInstalled() bypass used for URL.init/URL.reinit above) - the installer needs to be able to force an ORM reload before any admin account exists. An anonymous request carrying the param outside of these cases is silently ignored. --->
		<cfif isDefined("URL.reloadOrm") and (application.Udf.isLoggedIn() or reinstallIni or reinstallDb or not getInstalled())>
			<cfset ORMReload()>
		</cfif>

		<!--- Security: applicationStop() tears down the entire application for every visitor, forcing a full re-init on the next request. Only allow ?appStop=1 to trigger it when an administrator is already logged in (same application.Udf.isLoggedIn() check as above). Unlike URL.init/URL.reinit/URL.reloadOrm, this is not given an installer bypass, since nothing in the install flow ever sends this param. An anonymous request carrying the param is silently ignored. --->
		<cfif isDefined("URL.appStop") and application.Udf.isLoggedIn()>
			<!--- Stop the application --->
			<cfset applicationStop()/>
			<!--- Redirect to the home page and the application should start again --->
			<cflocation url="#getBaseUrl()#">
		</cfif>
			
		<!--- Get the CF version. --->
		<cfset application.cfVersion = listGetAt(Server.ColdFusion.ProductVersion, 1, ',')>

		<!--- Set the base template path without the /index.cfm. This should something like 'D:\home\gregoryalexander.com\wwwroot\galaxieBlog\'. This function is optimized for performance and you can use 'getRootDirectoryPath(true)' to reset the path --->
		<cfset application.rootDirectoryPath = getRootDirectoryPath() />
		<!--- Get the path to the ini file. This should something like D:\home\gregoryalexander.com\wwwroot\galaxieBlog\org\camden\blog\blog.ini.cfm We need to get to the site URL and dsn properties stored in the file. --->
		<cfset application.blogIniPath = getBlogIniPath()>
		<!--- Set the ini file path as a var --->
		<cfset application.iniFile = expandPath(application.blogIniPath)>

		<!--- Get the database vars. --->
		<cfset application.dsn = getDsn()>
		<cfset application.databaseType = getDatabaseType()>
		<!--- Was the blog installed --->
		<cfset application.installed = getInstalled()>

		<!--- Use the functions to set the siteUrl and baseUrl. The entire site structure is driven by these two vars. These functions are optimized for efficiency. --->

		<!--- Get the site URL. This is one of the most essential settings as the entire path structure of the blog is based on this --->
		<cfset application.siteUrl = getSiteUrl()>
		<!--- The blogHostUrl is the site URL minus the index.cfm. --->
		<cfset application.blogHostUrl = replaceNoCase(getSiteUrl(), '/index.cfm', '')>
		<!--- Get the domain. This is needed to append the domain to the media path when sending out images. The mediaPath contains the baseUrl which we will append the domain to to get the path to the email images. --->
		<cfset application.blogDomain = parseUri(application.blogHostUrl).host>
		<!--- And get the base URL --->
		<cfset application.baseUrl = getBaseUrl()>
		<cfset application.baseTemplatePath = getBaseTemplatePath()>
		<!--- Set the common component paths --->
		<cfset application.baseProxyUrl = getBaseProxyUrl()>
		<!--- Set the base component path by replacing the baseProxyURl forward slashes with dots. --->
		<cfset application.baseComponentPath = getBaseComponentPath()>
		<!--- Get the blog owner. This returns the user name who installed the blog and is used on the bio page. --->
		<cfset application.blogOwner = getBlogOwner()>

		<!--- Enable ORM. --->
		<cfset initOrm()>

		<cfif debug>
			<cfoutput>
			getBaseTemplatePath(): #getBaseTemplatePath()#<br/>
			application.rootDirectoryPath: #application.rootDirectoryPath#<br/>
			application.blogIniPath: #application.blogIniPath#<br/>
			-- Installation vars --<br/>
			reinstallIni: #reinstallIni#<br/>
			reinstallDb: #reinstallDb#<br/>
			getInstalled(): #getInstalled()#<br/>
			<!--- Lucee throws an error here (	Component [galaxie.Application] has no accessible Member with name [ORMINITIALIZED]) --->
			this.ormInitialized: <cftry>#this.ormInitialized#<cfcatch type="any">false</cfcatch></cftry><br/>
			getSiteUrl(): #getSiteUrl()#<br/>
			application.siteUrl: #application.siteUrl#<br/>
			application.blogDomain: #application.blogDomain#<br/>
			application.blogHostUrl = #application.blogHostUrl#<br/>
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
			
		<!--- Determine if we need to run the initial 7 part installer. --->
		<cfif reinstallIni or (not getInstalled() and not len(getDsn()))>
			<cfif debug>Redirecting to installer/initial/index.cfm?notInstalled<br/></cfif>
			<!--- Display the inital welcome screen and get the DSN from the user to create the initial database --->
			<cflocation url="installer/initial/index.cfm?notInstalled" addToken="false">
		</cfif>
			
		<!--- After the ORM has been reloaded in order to create the initial database, continue to install the blog by populating the database. The step7Post.cfm template in the install directory has just redirected to the index.cfm page with the init argument. This should populate the user data and redirect to the home page. If we continue processing without populating the database we will have errors here. 
		Notes: 
		1) when testing, set the installed string to null or false in the ini file and run this from the home page (index.cfm) page
		2) If you're having a too many connections error with MySql, you can break the data insertion into parts by opening up the insertData.cfm template and harcoding the tablesToPopulate variable and only inserting data for a few tables at a time. --->
		<cfif ( reinstallDb or ( len(getDsn()) and not len(getInstalled()) or isBoolean(getInstalled()) and not getInstalled() ) )>
			<cfif debug>
				The initial install has been completed. Trying to insert data by including the installer/insertData.cfm template<br/>
			</cfif>
			<!--- A brand new install starts out at the version of the files that were just installed. See the end of applicationInit(). --->
			<cfset request.blogJustInstalled = true>
			<cfinclude template="#getBaseUrl()#/installer/insertData.cfm">
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
		<cfset application.proxyControllerUrl = getBaseUrl() & '/common/cfc/ProxyController.cfc' / >
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.proxyControllerComponentPath = application.baseComponentPath & ".common.cfc.ProxyController">
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
			
		<!--- The default content object is used to suggest the initial HTML when the user is manually changing the design of the page, such as the composite header. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.defaultContentObjPath = application.baseComponentPath & ".common.cfc.DefaultContent">
		<cfelse>
			<cfset application.defaultContentObjPath = "common.cfc.DefaultContent">
		</cfif>
			
		<!--- The Utils component is used to send out mail and other utility functions. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.utilsComponentPath = application.baseComponentPath & ".org.camden.blog.utils">
		<cfelse>
			<cfset application.utilsComponentPath = "org.camden.blog.utils">
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
			
		<!--- TimeZone.cfc gets and converts date time stamps based upon the time zone. This is used to convert the date stamps if the server resides in a different time zone than the author. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.timeZoneComponentPath = application.baseComponentPath & ".common.cfc.TimeZone">
		<cfelse>
			<cfset application.timeZoneComponentPath = "common.cfc.TimeZone">
		</cfif>
			
		<!--- JSoup is used to parse and glean data. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.jsoupComponentPath = application.baseComponentPath & ".common.cfc.JSoup">
		<cfelse>
			<cfset application.jsoupComponentPath = "common.cfc.JSoup">
		</cfif>	

		<!--- Brings the database up to date after uploading a new version. Run from the administrative site. --->
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.databaseUpdaterComponentPath = application.baseComponentPath & ".common.cfc.DatabaseUpdater">
		<cfelse>
			<cfset application.databaseUpdaterComponentPath = "common.cfc.DatabaseUpdater">
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
		<!--- Brings the database up to date after uploading a new version (see DatabaseUpdater.cfc). --->
		<cfset application.databaseUpdater = createObject("component", application.databaseUpdaterComponentPath).init(this.rootDirectoryPath, getBlogIniPath())>
		
		<!---//****************************************************************************************
				Initialize the application and set core application vars.
		//*****************************************************************************************---> 

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
		<!--- Get the path to the Kendo UI folder. --->
		<cfset application.kendoFolderPath = application.BlogOptionDbObj.getKendoFolderPath()>
		<!--- When true, public-facing pages (not admin) default to Kendo Core instead of the larger Kendo Professional download, only switching to Professional for a specific post when postNeedsKendoCommercial() (blog.cfc) detects it's actually needed - see includes/templates/core/seoMetaTags.cfm. Admin pages always use kendoCommercial above, regardless of this setting. --->
		<!--- The column is NULL on databases that were created before this option existed. --->
		<cfif isNull(application.BlogOptionDbObj.getDeferKendoCommercialOnPublicSite())>
			<cfset application.deferKendoCommercialOnPublicSite = false>
		<cfelse>
			<cfset application.deferKendoCommercialOnPublicSite = application.BlogOptionDbObj.getDeferKendoCommercialOnPublicSite()>
		</cfif>

		<!--- Kendo version (is Kendo the open source or commercial version?) default on the open source blog, Kendo Core, is true. --->
		<cfif application.kendoCommercial>
			<!--- The location of the commercial Kendo is the application.kendoFolderPath.  --->
			<cfset kendoSourceLocation = application.kendoFolderPath>
		<cfelse>
			<!--- Note: this logic is true when the blog owner specifies a Kendo Location in the admin UI  --->
			<cfif len(application.kendoFolderPath) and !isDefined("URL.init") and !isDefined("URL.reinit")>
				<cfset kendoSourceLocation = application.kendoFolderPath>
			<cfelse>
				<!--- Point to the embedded Kendo Core folder. --->
				<cfset kendoSourceLocation = getBaseUrl() & "/common/libs/kendoCore/">
			</cfif>
		</cfif>
		
		<!--- Kendo library locations --->
		<!--- Note: we are using an open source version of the Kendo library, Kendo Core. It does not have all of the bells and whistles of the comercial licence of course. --->
		<cfset application.kendoSourceLocation = kendoSourceLocation><!--- Commercial: /common/libs/kendo (without getBaseUrl() &). Open source: getBaseUrl() & "/common/libs/kendoCore" --->
		<cfset application.kendoUiExtendedLocation = getBaseUrl() & "/common/libs/kendoUiExtended">
		<!--- Note: the original blogCfc came with an older jQuery UI than the one that I am using and it is creating conflicts. We need to have two different jQuery incluedes, one for the administration part of the site, and the newer jquery UI for the new blogCfc.--->
		<cfset application.adminjQueryUiPath = getBaseUrl() & "/includes/jqueryui/jqueryui.js">
			
		<!--- Mapping Service URL's --->
		<!--- Map Controller URL's. We are using version 3 --->
		<cfset application.azureMapsControllerUrl = 'https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.js'>
		<cfset application.azureMapsControllerCssUrl = 'https://atlas.microsoft.com/sdk/javascript/mapcontrol/3/atlas.min.css'>
		<cfset application.azureMapsDirectionsApiUrl = 'https://atlas.microsoft.com/route/directions/json?api-version=1'><!--- https://atlas.microsoft.com/route/directions/json?api-version=2025-01-01 --->
		<!--- Azure Maps Fuzzy Search URL. We are using version 1 for now --->
		<cfset application.azureMapsFuzzySearchUrl = "https://atlas.microsoft.com/search/fuzzy/json?typeahead=true&api-version=1.0&language=en-US&lon=0&lat=0&view=Auto">
		<cfset application.azureMapsSearchUrl = "https://atlas.microsoft.com/search/address/json">
		<!--- Azure Maps Static Marker Cursor. I need to eventually put this in the db --->
		<cfset application.defaultAzureMapsCursor = getBaseUrl() & "/images/mapMarkers/mapMarkerButton.gif">
		
		<!--- Note: the bing maps URL changes. For example, the orginal URL was https://www.bing.com, however, Bing is now recommending to use https://sdk.virtualearth.net/ instead due to the way that the browser handles cookies. --->
		<cfset application.bingMapsUrl = 'https://sdk.virtualearth.net'>	
			
		<!--- //****************************************************************************************
				Database version 
				This may be less than the version indicated in the Blog.cfc template after uploading new files that overwrite the blog version. This is needed to determine if we need to update the database with new information when upgrading versions.
		//******************************************************************************************--->
			
		<cfset application.dbBlogVersion = application.BlogDbObj.getBlogVersion()>
		<!--- A new install starts at the version of the files that were installed. The seed data that the installer inserts carries an older version number, which would make a brand new blog look like it needs to be updated. --->
		<cfif isDefined("request.blogJustInstalled") and request.blogJustInstalled>
			<cfset application.blog.updateBlogVersion(application.blog.getVersion(), application.blog.getVersionName())>
			<cfset entityReload(application.BlogDbObj)>
			<cfset application.dbBlogVersion = application.blog.getVersion()>
		</cfif>
		<!--- //****************************************************************************************
				User defined settings.
		//******************************************************************************************--->
		
		<!--- The blog will always use SSL if it is available. You may turn this setting off in the administrative interface. --->
		<cfset application.useSsl = application.BlogOptionDbObj.getUseSsl()>
		
		<!--- Does the blog use URL rewrite rules to hide index.cfm from the URL? --->
		<cfset application.serverRewriteRuleInPlace = application.BlogOptionDbObj.getServerRewriteRuleInPlace()>
			
		<!--- The user can turn off the caching features in order to debug stuff --->
		<cfset application.disableCache = application.BlogOptionDbObj.getDisableCache()>
		<!--- When true, the html of the page is minimized before it is sent to the browser (comments and unneeded white space are removed from the html, JavaScript and CSS, see /common/cfc/HtmlMinifier.cfc and /includes/templates/core/pageOutput.cfm). --->
		<cfset application.minimizeCode = application.BlogOptionDbObj.getMinimizeCode()>
			
		<!--- Common cache settings --->
		<cfif application.disableCache>
			<cfset application.useCache = false>
		<cfelse>
			<cfset application.useCache = true>
		</cfif>
			
		<!--- How many posts should show up on the main blog page? --->
		<cfset application.maxEntries = 9><!--- Used to be application.BlogOptionDbObj.getEntriesPerBlogPage() --->
			
		
		<!--- Setting to determine whether to defer the scripts and css. This is a hardcoded setting. You should only change this to debug to see if the defer is working, but you should leave this at true as it provides a much better google speed score. --->
		<cfset application.deferScriptsAndCss = true>
		<!--- Gravatars allowed? --->
		<cfset application.gravatarsAllowed = application.BlogOptionDbObj.getAllowGravatar()>	
		<!--- Do we have comment moderation? --->
		<cfset application.commentModeration = application.BlogOptionDbObj.getBlogModerated()>
			
		<!--- Logging settings. These are new to version 4.5 and I need to test for null vars --->
		<!--- Determines whether I should log the visitors. This may slow down the performance a tiny bit --->
		<cfif len(application.BlogOptionDbObj.getLogVisitors())>
			<cfset application.logVisitors = application.BlogOptionDbObj.getLogVisitors()>
		<cfelse>
			<cfset application.logVisitors = true>
		</cfif>
		<!--- Determines how many months to save the visitor logs. The tables can get full pretty quickly so it's best to lower this if there are any storage problems --->
		<cfif len(application.BlogOptionDbObj.getMonthsToRetainVisitorLog())>
			<cfset application.monthsToRetainVisitorLog = application.BlogOptionDbObj.getMonthsToRetainVisitorLog()>
		<cfelse>
			<cfset application.monthsToRetainVisitorLog = 1>
		</cfif>
		
		<!--- The admin log saves all logins. This table should not have a lot of records compared to the visitor logs and can be set higher --->
		<cfif len(application.BlogOptionDbObj.getMonthsToRetainAdminLog())>
			<cfset application.monthsToRetainAdminLog = application.BlogOptionDbObj.getMonthsToRetainAdminLog()>
		<cfelse>
			<cfset application.monthsToRetainAdminLog = 12>
		</cfif>
		
			
		<!--- Emails the blog author (Gregory for now) when errors occur --->
		<cfif len(application.BlogOptionDbObj.getSendDiagnostics())>
			<cfset application.sendDiagnostics = application.BlogOptionDbObj.getSendDiagnostics()>
		<cfelse>
			<cfset application.sendDiagnostics = true>
		</cfif>
			
		<!--- Optional libraries --->
		<!--- GSAP and scrollMagic allows for animations and parallax effects in the blog entries. don't include by default. --->
		<cfset application.includeGsap = application.BlogOptionDbObj.getIncludeGsap()>

		<!--- Determine whether to include the disqus commenting system. If you set this to true, you must also set the optional disqus settings that are right below. Note: this is an application var so that the recentcomments.cfm can access these settings. That template is invoked via a cfmodule tag. --->
		<cfset application.includeDisqus = application.BlogOptionDbObj.getIncludeDisqus()>

		<!--- Video player settings. We have several options. Our default player is plyr. It is a full featured HTML5 media player, however, it does not play flash video. This should not be a problem as flash is soon to be depracated. Optionally, we can use the Kendo UI video player if you have a full Kendo license. The original flash player will take over for .flv videos, but will be depracated in 2020. --->
		<cfset application.defaultMediaPlayer = application.BlogOptionDbObj.getDefaultMediaPlayer()><!---You can optionally choose 'KendoUiPlayer' if you have the full lisence. However, the Kendo Media player is lacks quite a few plyr features. The Kendo player is useful if you want the video player to take on the theme that you are using. --->
			
		<!--- This is Google gtag string and is used for analytics. --->
		<cfset application.googleAnalyticsString = application.BlogOptionDbObj.getGoogleAnalyticsString()>

		<!--- The addThis toolbox string changes depending upon the site and the configuration. --->
		<cfset application.addThisToolboxString = application.BlogOptionDbObj.getAddThisToolboxString()><!---Typically 'addthis_inline_share_toolbox'--->
					
		<!--- The addThis api key is found on the addThis.com site. There is a tutorial how to use this on Gregory's blog. --->
		<cfset application.addThisApiKey = application.BlogOptionDbObj.getAddThisApiKey()>
			
		<!--- Optional Azure Map API (used for Azure Maps) --->
		<cfset application.azureMapsApiKey = application.BlogOptionDbObj.getAzureMapsApiKey()>
		<!--- Optional Bing Map API. This will retire on June 2025 --->
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
		<!--- Determine if the device is a tablet --->
		<cfif find("iPad", CGI.HTTP_USER_AGENT) OR (find("Android", CGI.HTTP_USER_AGENT) and not session.isMobile)>
			<cfset session.isTablet = true>
		<cfelse>
			<cfset session.isTablet = false>
		</cfif>

		<!--- Initialize the application if it has not already been done. --->
		<cfif not isDefined("application.init")>
			<cfset init = this.applicationInit()>
		</cfif>
			
		<!--- If the database is too old for the site to run (see the function), visitors get a 'being updated' page until the database is updated. This is done last, after every application setting has been read, as the administrative site (which the administrator is sent to) and the error handler need those settings. --->
		<cfset databaseUpdateGate()>

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
			<!--- This is the original ACF location, but it does not work with Lucee
			<cflocation url="installer/initial/index.cfm?notInstalled" addToken="false">
			--->
		</cfif>

		<!--- Use Captcha? --->
		<cfset application.useCaptcha = application.BlogOptionDbObj.getUseCaptcha()>

		<cfset application.serverProduct = getServerProduct()>
		<cfset majorVersion = listFirst(Server.coldFusion.productVersion)>
		<cfset minorVersion = listGetAt(server.coldfusion.productVersion,2,",.")>
		<cfset cfversion = majorVersion & "." & minorVersion>		

		<cfset application.isColdFusionMX7 = server.coldFusion.productName is "ColdFusion Server" and cfversion gte 7>

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
				Admin site and database specific ORM files
	//*****************************************************************************************--->

	<cffunction name="isAdminRequest" access="public" returnType="boolean" output="false"
			hint="Determines if the requested template is in the /admin/ folder (or one of its subfolders). This compares the requested template's location on disk with this component's location on disk rather than looking at the URL, so it works when the blog is in the root directory, in a folder named 'blog', or in any other folder, and it does not depend on anything being configured.">

		<cfset var adminDirectory = replace(this.rootDirectoryPath, "\", "/", "all")>
		<cfif right(adminDirectory, 1) neq "/">
			<cfset adminDirectory = adminDirectory & "/">
		</cfif>
		<cfset adminDirectory = adminDirectory & "admin/">

		<cfset var requestedDirectory = replace(getDirectoryFromPath(getBaseTemplatePath()), "\", "/", "all")>

		<!--- The requested directory is either the admin directory or is beneath it. The comparison is case insensitive as the file system may or may not be. --->
		<cfreturn compareNoCase(left(requestedDirectory, len(adminDirectory)), adminDirectory) eq 0>

	</cffunction>

	<cffunction name="databaseUpdateGate" access="private" returnType="void" output="true"
			hint="After new files are uploaded over an old version of the blog, some of the data that the site needs does not exist until the database update has been run (the new columns are empty). Below a certain database version the pages would raise errors, including the administrative site that holds the update button. In that case, visitors get a 'this site is being updated' page (status 503) and the administrator is sent to admin/update.cfm, which does not depend on the rest of the administrative site. A database at or above the minimum version keeps working until the administrator runs the update, as before.">

		<!--- Raise this when a release needs an update script to run before the site can work. 4.5 is the release that added the IsPage and IsBlogPost columns to the Post table, which the 4.5 update script fills in. --->
		<cfset var minimumDatabaseVersion = "4.5">
		<cfset var requestedTemplate = lCase(replace(getBaseTemplatePath(), "\", "/", "all"))>

		<!--- The versions are not known on the first request after the application started, or when the blog is not installed yet. --->
		<cfif not isDefined("application.dbBlogVersion") or not isDefined("application.blog")>
			<cfreturn>
		</cfif>
		<cfif val(application.dbBlogVersion) gte val(minimumDatabaseVersion) or val(application.dbBlogVersion) gte val(application.blog.getVersion())>
			<cfreturn>
		</cfif>

		<!--- The settings that are read further down in OnRequestStart (for example sendDiagnostics) are not set when the request stops here, but onError and saveErrorLog need them. Give them safe defaults so an error on a gated request is logged and does not hide the real error. --->
		<cfif not structKeyExists(application, "sendDiagnostics")>
			<cfset application.sendDiagnostics = false>
		</cfif>

		<!--- Always allow the remote component calls (login and the database update itself) and the installer. --->
		<cfif right(requestedTemplate, 4) eq ".cfc" or find("/installer/", requestedTemplate)>
			<cfreturn>
		</cfif>

		<cfif isAdminRequest()>
			<cfif isDefined("application.Udf") and application.Udf.isLoggedIn()>
				<!--- An administrator (the logon has already been handled) may use the update page, and is sent there from everywhere else. --->
				<cfif right(requestedTemplate, 17) neq "/admin/update.cfm">
					<cflocation url="#getBaseUrl()#/admin/update.cfm" addToken="false">
				</cfif>
			<cfelse>
				<!--- Show a simple login form that does not depend on the database or the rest of the site. It posts to the update page, and the logon is handled by adminRequestStart before the update page is run. --->
				<cfheader name="Cache-Control" value="no-store">
				<cfcontent type="text/html; charset=utf-8" reset="true"><cfoutput><!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="robots" content="noindex">
	<title>Sign in to update the blog</title>
	<style>body { font-family: Arial, Helvetica, sans-serif; max-width: 360px; margin: 12% auto 0 auto; padding: 0 20px; color: ##333; } input { display: block; width: 100%; box-sizing: border-box; margin: 6px 0 14px 0; padding: 8px; font-size: 16px; } button { font-size: 16px; padding: 8px 18px; cursor: pointer; }</style>
</head>
<body>
	<h2>Sign in to update the blog</h2>
	<p>The blog files are newer than the database, so the database has to be updated before the site can run again.</p>
	<form method="post" action="#getBaseUrl()#/admin/update.cfm">
		<label for="userName">User name</label>
		<input type="text" name="userName" id="userName" autocomplete="username" autofocus>
		<label for="password">Password</label>
		<input type="password" name="password" id="password" autocomplete="current-password">
		<button type="submit">Sign in</button>
	</form>
</body>
</html></cfoutput><cfabort>
			</cfif>
		<cfelse>
			<cfheader statuscode="503">
			<cfheader name="Retry-After" value="300">
			<cfheader name="Cache-Control" value="no-store">
			<cfcontent type="text/html; charset=utf-8" reset="true"><cfoutput><!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="robots" content="noindex">
	<title>This site is being updated</title>
	<style>body { font-family: Arial, Helvetica, sans-serif; text-align: center; margin: 15% 20px 0 20px; color: ##333; } a { color: ##555; }</style>
</head>
<body>
	<h1>This site is being updated</h1>
	<p>Please check back in a few minutes.</p>
	<p><small><a href="#getBaseUrl()#/admin/update.cfm" rel="nofollow">Administrator sign in</a></small></p>
</body>
</html></cfoutput><cfabort>
		</cfif>

	</cffunction>

	<cffunction name="applyDatabaseOrmTypes" access="private" returnType="void" output="false"
			hint="Sets the long text columns in the ORM entities to the type that the blog's database uses. The database is the databaseType that the installer saved in the ini file. This runs once for each database type that the application sees, so it costs nothing on normal requests, and it will not write to the file system when the entities are already correct. This also means that copying a new version of the entities over the old ones is not a problem, the columns will be corrected the next time the application starts.">

		<!--- Read the type from the ini file in this folder and not from the application scope, see getIniValue(). --->
		<cfset var databaseType = getIniValue("databaseType")>
		<cfset var databaseOrmTypes = "">
		<cfset var baseComponentPath = "">

		<!--- The database type is not known until the installer gets to that step --->
		<cfif not len(databaseType)>
			<cfreturn>
		</cfif>

		<cfif not (structKeyExists(application, "ormTypesAppliedFor") and application.ormTypesAppliedFor eq databaseType & "|" & this.rootDirectoryPath)>
			<!--- Build the component path from the blog's location, like the other components (application.blogComponentPath and so on). A bare 'common.cfc' path is looked up from the web root, and a site that has its own common folder (ie gregoryalexander.com/common) will not find it. --->
			<cfset baseComponentPath = getBaseComponentPath(true)>
			<cfif len(baseComponentPath)>
				<cfset databaseOrmTypes = createObject("component", baseComponentPath & ".common.cfc.DatabaseOrmTypes")>
			<cfelse>
				<cfset databaseOrmTypes = createObject("component", "common.cfc.DatabaseOrmTypes")>
			</cfif>
			<cfset databaseOrmTypes.apply(databaseType, this.rootDirectoryPath & "common/cfc/db/galaxieDb/")>
			<cfset application.ormTypesAppliedFor = databaseType & "|" & this.rootDirectoryPath><!--- The folder is part of the flag, as the application scope that is visible here can belong to another blog (see getIniValue). --->
		</cfif>

	</cffunction>

	<cffunction name="adminRequestStart" access="private" output="true" hint="The logon and session logic for the administrative site. This was the OnRequestStart function in the admin folder's Application.cfc, which no longer exists. It must be output=true as it displays the login page.">
		
		<!---//*****************************************************************************************
			Mobile Detection
		//******************************************************************************************--->
		
		<!--- This device detection code was updated on Feb 6 2019 (from http://detectmobilebrowsers.com/)--->
		<cfif 
		(reFindNoCase("(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino",CGI.HTTP_USER_AGENT) GT 0 OR reFindNoCase("1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-",Left(CGI.HTTP_USER_AGENT,4)) GT 0)>
			<cfset session.isMobile = true>
		<cfelse>
			<cfset session.isMobile = false>
		</cfif>
			
		<!---//*****************************************************************************************
			Logon
		//******************************************************************************************--->
		
		<!---Logout if the user is on the login page.--->
		<cflogout>
			
		<cflogin>
			<cfif isDefined("form.userName") and isDefined("form.password") and len(trim(form.username)) and len(trim(form.password))>
				
				<!--- Note: there is no way to reconstruct a password. The only thing you can do is to re-create a the same hashed password if you know the existing password and hash key. If you have access to the code, you *can* however add or 1 eq 1 to the following line to log in and change the password. Just change it back after changing it. --->
				<cfif disableAuth or application.blog.authenticate(left(trim(form.username),255),left(trim(form.password),50), cgi.remote_addr, cgi.http_User_Agent)>

					<cfloginuser name="#trim(form.username)#" password="#trim(form.password)#" roles="admin">
					<cfset session.userName = trim(form.username)>
					<cfset session.key = trim(form.password)>
					<!--- Get the current logged in users Id --->
					<cfset session.userId = application.blog.getUserIdByUserName(form.username)>
					<!--- 
						  This was added because CF's built in security system has no way to determine if a user is logged on.
						  In the past, I used getAuthUser(), it would return the username if you were logged in, but
						  it also returns a value if you were authenticated at a web server level. (cgi.remote_user)
						  Therefore, the only say way to check for a user logon is with a flag. 
					--->  
					<cfset session.loggedin = true>
					<!--- Add the blog user's specific roles to the session scope. --->
					<cfset session.roles = application.blog.getUserBlogRoles(form.username, 'roleList')>
					<!--- Set the capabilities. There are one or more capabilities for each role.--->
					<cfset session.capabilityList = application.blog.getCapabilitiesByRole(session.roles, 'capabilityList')>
					<!--- Also get the capability id's --->
					<cfset session.capabilityIdList =  application.blog.getCapabilitiesByRole(session.roles, 'capabilityIdList')>
					<!--- Drop a cookie on this machine to allow administators to preview posts that are not yet released (GA) --->
					<!--- Using the cfcookie tag does not work with dynamic vars in the path. --->
					<cfset cookie.isAdmin = { value="true", path="#application.baseUrl#", expires=30 }>

				<cfelse>
					<!--- Suggested by Shlomy Gantz to slow down brute force attacks --->
					<cfset createObject("java", "java.lang.Thread").sleep(500)>
				</cfif>
					
			</cfif><!---<cfif isDefined("form.userName") and isDefined("form.password") and len(trim(form.username)) and len(trim(form.password))>--->
		</cflogin>

		<!--- Allow the user to logout --->
		<cfif isDefined("url.logout") and application.Udf.isLoggedIn()>
			<cfset structDelete(session,"loggedin")>
			<cflogout>
		</cfif>

		<!--- If the database is too old for the site to run (see the function), send the administrator to the update page. This has to be done before the login page is shown, as the login page does not run either. --->
		<cfset databaseUpdateGate()>
		<cfif findNoCase("/admin", cgi.script_name) and not application.Udf.isLoggedIn()>
			<cfsetting enablecfoutputonly="false">
			<!--- Here we are using a module instead of a cfinclude as the include would essentially place the login.cfm template, which has identical logic to the other admin templates, which causes errors as there are duplicate functions. --->
			<cfmodule template="admin/login.cfm">
			<cfabort>
		</cfif>
				
		<!---//*****************************************************************************************
			Persist login
		//******************************************************************************************--->
				
		<!--- We need to persist the login. It is not persisted with the changes to the application. --->
		<cfif application.Udf.isLoggedIn()>
			<cfloginuser name="admin" password="admin" roles="admin">
			<!--- Set the session var. --->
			<cfset session.loggedin = true>
			<!--- Drop a cookie on this machine to allow administators to preview posts that are not yet released (GA) --->
			<cfif not isDefined("cookie.isAdmin")>
				<!--- Using the cfcookie tag does not work with dynamic vars in the path. --->
				<cfset cookie.isAdmin = { value="true", path="#application.baseUrl#", expires=30 }>
			</cfif>
		</cfif>
			
	</cffunction>

			
	<!---//****************************************************************************************
			System Functions 
			These are written to avoid using the file system again when the variables are already set. Use the reset argument to read the properties from the file.
	//*****************************************************************************************--->
			
	<cffunction name="getServerProduct" access="remote" returnType="string"
			hint="Determines whether the server is using ACF or Lucee. Will return ColdFusion or Lucee">
		<cfargument name="reset" default="false">
		
		<cfif isDefined("application.serverProduct") and not arguments.reset>
			<cfset serverProduct = application.serverProduct>
		<cfelse>
			<cfset serverProduct = server.coldFusion.Productname>
		</cfif>
		
		<!--- Return it --->
		<cfreturn serverProduct>
		
	</cffunction>
			
	<cffunction name="getRootDirectoryPath" access="remote" returnType="string"
			hint="Get the site's root path. This returns the full path of the root directory. This does not have any dependencies.">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the root path.">
		
		<cfif isDefined("application.rootDirectoryPath") and len(application.rootDirectoryPath) and not arguments.reset>
			<cfset rootDirectoryPath = application.rootDirectoryPath>
		<cfelse>
			<cfset rootDirectoryPath = this.rootDirectoryPath />
		</cfif>
		
		<!--- Return it --->
		<cfreturn rootDirectoryPath>
		
	</cffunction>
				
	<cffunction name="getIniValue" access="private" returnType="string" output="false"
			hint="Reads a value from the blog.ini.cfm file in the same folder as this Application.cfc. Unlike getDsn() and getDatabaseType(), this never looks at the application scope. Use it for the settings that are needed when the ORM is set up in the constructor.">
		<cfargument name="key" type="string" required="true">

		<cftry>
			<cfreturn trim(getProfileString(this.rootDirectoryPath & "org/camden/blog/blog.ini.cfm", "default", arguments.key))>
			<cfcatch type="any">
				<!--- The ini file may not be readable yet when first installing the blog. --->
				<cfreturn "">
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="getBlogIniPath" access="remote" returnType="string"
			hint="Get the path to the ini file which stores our constant variables">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the path.">
		
		<cfif isDefined("application.blogIniPath") and len(application.blogIniPath) and not arguments.reset>
			<cfset blogIniPath = application.blogIniPath>
		<cfelse>
			<cfset blogIniPath = this.rootDirectoryPath & 'org\camden\blog\blog.ini.cfm'>
		</cfif>

		<!--- Return it --->
		<cfreturn blogIniPath>
		
	</cffunction>
				
	<cffunction name="getSiteUrl" access="remote" returnType="string"
			hint="Get the site's URL. The site URL is the full URL, with the http or https prefix and index.cfm, typed into the form when installing the blog and is also on the blog settings page and looks like so: https://www.gregoryalexander.com/blog/index.cfm">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the site url.">
		
		<!--- Return the current application.siteUrl if it exists. --->
		<cfif isDefined("application.siteUrl") and len(application.siteUrl) and not arguments.reset>
			<cfset siteUrl = application.siteUrl>
		<!--- Get the URL from the ini file. --->
		<cfelseif isDefined("application.blogIniPath") and len(application.blogIniPath)>
			<!--- Get the siteUrl from the blog.ini file  --->
			<cftry>
				<cfset siteUrl = getProfileString(application.blogIniPath, "default", "blogUrl")>
				<cfcatch type="any">
					<!--- This should only happen when initially installing the blog. --->
					<cfset siteUrl = "" />
				</cfcatch>
			</cftry>
		<cfelse>
			<!--- Determine the URL by the CGI URL. --->
			<cfset siteUrl = CGI.HTTP_URL>
		</cfif>
		
		<!--- Return it --->
		<cfreturn siteUrl>
		
	</cffunction>
			
	<cffunction name="getBlogOwner" access="remote" returnType="string" hint="This gets the user name of the person who installed the blog. It is used to gather the bio">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset this var.">
		
		<!--- Return the current application.DSN if it exists. --->
		<cfif isDefined("application.blogOwner") and len(application.blogOwner) and not arguments.reset>
			<cfset owner = application.blogOwner>
		<cfelse>
			<cftry>
				<!--- Get the username from the ini file --->
				<cfset owner = getProfileString(getBlogIniPath(), "default", "username")>
				<cfcatch type="any">
					<!--- This should only happen when initially installing the blog. --->
					<cfset owner = ""/>
				</cfcatch>
			</cftry>
		</cfif>
				
		<cfreturn owner>
		
	</cffunction>
		
	<cffunction name="getBaseUrl" access="remote" returnType="string"
			hint="The baseUrl is the URL minus the domain and the script name. It should look something like this '/galaxieBlog'. It must not have the final forward slash at the end. This is used to set the path on nearly everything in the site and it uses the function above to get the base URL. We are using the parseUri function below and getting the relative struct key.">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset the base url.">
		
		<!--- Return the current application.baseUrl if it exists. --->
		<cfif isDefined("application.baseUrl") and len(application.baseUrl) and not arguments.reset>
			<cfset baseUrl = application.baseUrl>
		<cfelse>
			<!--- Remove the '/index.cfm' string from the siteUrl --->
			<cfset cleanedUrl = replaceNoCase(getSiteUrl(), "/index.cfm", "")>
			<!--- Get the baseUrl from by parsing the URI using the new URL. --->
			<cfset baseUrl = parseUri(cleanedUrl).relative>
		</cfif>
		<!--- Return it --->
		<cfreturn baseUrl>
		
	</cffunction>
				
	<cffunction name="getDsn" access="remote" returnType="string">
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset this var.">
		
		<!--- Return the current application.DSN if it exists. --->
		<cfif isDefined("application.dsn") and len(application.dsn) and not arguments.reset>
			<cfset dsn = application.dsn>
		<cfelse>
			<cftry>
				<!--- Get the DSN from the ini file --->
				<cfset dsn = getProfileString(getBlogIniPath(), "default", "dsn")>
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
		
		<!--- Return the current application.data base type if it exists. --->
		<cfif isDefined("application.databaseType") and len(application.databaseType) and not arguments.reset>
			<cfset databaseType = application.databaseType>
		<cfelseif isDefined("this.ormInitialized") and isDefined("application.BlogDbObj")>
			<!--- Get the db type from the DB  --->
			<cfset databaseType = application.BlogDbObj.getBlogDatabaseType()>
		<cfelse>
			<!--- Get the dialect from the ini file --->
			<cftry>
				<cfset databaseType = getProfileString(getBlogIniPath(), "default", "databaseType")>
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
		
		<!--- Return the current application.installed if it exists. --->
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
				<cfset installed = getProfileString(getBlogIniPath(), "default", "installed")>
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
		<cfargument name="reset" type="boolean" default="false" required="false" hint="Set to true to read reset this var.">
		
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

		<!--- Create an array containing the names of each key we will add to the uri struct. Note: removing some of these (such as user and password) may cause the function to provide blank values on other fields --->
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
				<cfif CGI.Server_Port eq '443'>
					<cfset thisUrl = application.blogHostUrl>
				<cfelse>
					<!--- Note: we need to eliminate https from the root URL if it exists. I ran into errors trying this with https (a cryptic certificate error). --->
					<cfset thisUrl = replaceNoCase(application.blogHostUrl, "https", "http")>
				</cfif>
				
				<!--- The headerBodyDivider image is a tiny .webp image (around 1k). We are going to read this, and if it was found and the mime type is correct, we will assumed that the mime type is correct. Otherwise, we will determine that the server does not support the webp mime type. --->
				<cfhttp method="get" URL="#trim(thisUrl)#/images/divider/headerBodyDivider.webp">

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
		<!---TODO Hardcoding to false due to memory leak somewhere--->
		<cfreturn woff2>
	</cffunction>
						
	<!---//****************************************************************************************
				Global Error Handling
	//*****************************************************************************************--->
						
	<cffunction name="onError" returnType="void" output="true">
		<!--- These arguments are required for this to work --->
		<cfargument name="exception" type="any" required=true />
		<cfargument name="eventName" type="string" required=true />
		<cfargument name="disable" type="string" default="#disableErrorLogging#" />
		<cfargument name="showOnlyCFErrors" type="string" default="true" />
		
		<!--- Preset params that may not exist --->
		<cfparam name="errorOrigin" default="">
		<cfparam name="errorLine" default="">
		<cfparam name="errorTemplate" default="">
		<cfparam name="errorStacktrace" default="">
		<!--- These are set below when the url has a .cfm or .cfc extension. They are also used when the error is displayed, and a request for a directory (ie /admin/) does not have an extension. --->
		<cfparam name="errorEvent" default="#arguments.eventName#">
		<cfparam name="errorType" default="#arguments.exception.type ?: ''#">
		<cfparam name="errorMessage" default="#arguments.exception.message ?: ''#">
		<cfparam name="errorDetail" default="#arguments.exception.detail ?: ''#">
		<cfparam name="errorDate" default="#dateFormat(now(), 'short')# #timeFormat(now(), 'short')#">
			
		<!--- Always write the error to a ColdFusion log file (galaxieBlogErrors) as well. The error is normally saved to the database by saveErrorLog, which needs the application to be fully started. When that fails, the page only shows the error of the error handler and the real error is lost. --->
		<cftry>
			<cfset local.loggedError = arguments.exception>
			<cfif isDefined("arguments.exception.rootCause") and (isStruct(arguments.exception.rootCause) or isObject(arguments.exception.rootCause))>
				<cfset local.loggedError = arguments.exception.rootCause>
			</cfif>
			<cfif isObject(local.loggedError)>
				<cfset local.loggedText = local.loggedError.toString()>
			<cfelse>
				<cfset local.loggedText = (local.loggedError.type ?: '') & ': ' & (local.loggedError.message ?: '') & ' ' & (local.loggedError.detail ?: '')>
			</cfif>
			<cfif isDefined("arguments.exception.tagContext") and isArray(arguments.exception.tagContext) and arrayLen(arguments.exception.tagContext)>
				<cfset local.loggedText = local.loggedText & ' (' & arguments.exception.tagContext[1].template & ' line ' & arguments.exception.tagContext[1].line & ')'>
			</cfif>
			<cflog file="galaxieBlogErrors" type="error" text="#cgi.script_name# #arguments.eventName#: #local.loggedText#">
			<cfcatch type="any"></cfcatch>
		</cftry>

		<!--- Note: application.blog is not defined during the installation process --->
		<cfif isDefined("application.blog")>
			<cfset errorUrl = application.blog.getPageUrl()>
			<cfset ipAddress = application.blog.getIpAddress()>

			<!--- Bot/lock-storm throttling, step 1: if this IP is already in a temporary timeout (see recordDatabaseLockError below), stop here - no saveErrorLog call, so no DB write and no email. This is deliberately the very first thing onError does, ahead of even the disable/showOnlyCFErrors branching below, since the whole point is to stop doing extra work (including extra DB round trips) for a visitor whose requests are already causing DB lock errors. Checked again, independently, in visitorTracking.cfm ahead of the normal isVisitorBanned() check, so a timed-out IP is actually blocked from loading pages at all rather than merely having its errors go unlogged. --->
			<cfif len(ipAddress) and application.blog.isTemporarilyTimedOut(ipAddress)>
				<cfheader statuscode="429">
				<cfcontent type="text/html" reset="true">Too many requests. Please try again later.
				<cfreturn>
			</cfif>

			<!--- Only log errors generated on CF/Lucee pages --->
			<cfif errorUrl contains '.cfm' or errorUrl contains '.cfc'>
				<cfset errorEvent = arguments.eventName>
				<cfset errorType = arguments.exception.type>
				<cfset errorMessage = arguments.exception.message>
				<cfset errorDetail = arguments.exception.detail>
				<!--- Set the date --->
				<cfset errorDate = "#dateFormat(now(), 'short')# #timeFormat(now(), 'short')#">

				<!--- Get the template and line if available --->
				<cfif isDefined("arguments.exception.tagContext") and arrayLen(arguments.exception.tagContext)>
					<cfset errorOrigin = arguments.exception.tagContext[1]>
					<cfset errorTemplate = errorOrigin.template>
					<cfset errorLine = errorOrigin.line>
				</cfif>

				<!--- Get the stacktrace --->
				<cfif isDefined("arguments.exception.stacktrace")>
					<cfset errorStacktrace = arguments.exception.stacktrace>
				</cfif>

				<!--- Bot/lock-storm throttling, step 2: does this look like a Hibernate lock-acquisition error (org.hibernate.exception.LockAcquisitionException - typically "could not extract ResultSet")? These are the errors a bot hammering the site tends to cause once it starts overwhelming the database, so track them per-IP and, once the same IP crosses the threshold within the tracking window, place it into a temporary timeout (application.dbLockTimeoutThreshold/dbLockTimeoutWindowSeconds/dbLockTimeoutDurationMinutes - set in OnRequestStart above). recordDatabaseLockError returns true only on the call that actually triggers a new timeout, so we can note it once in this error's own email rather than on every request. --->
				<cfset isLockAcquisitionError = findNoCase("LockAcquisitionException", errorType & errorMessage & errorDetail) gt 0>
				<cfset justAppliedTimeout = false>
				<cfif isLockAcquisitionError and len(ipAddress)>
					<cfset justAppliedTimeout = application.blog.recordDatabaseLockError(ipAddress)>
				</cfif>

			</cfif><!---<cfif isDefined("application.blog")>--->

			<cfif arguments.disable>
				<cfoutput>
				<h2>An unexpected error occurred.</h2>
				An error occurred: #errorUrl#<br/>
				Time: #errorDate#<br/>
				Error Event: #errorEvent#<br/>
				Type: #errorType#<br/>
				Message: #errorMessage#<br/>
				Detail: #errorDetail#<br/>
				Template: #errorTemplate#<br/>
				Line: #errorLine#<br/>
				Stacktrace: #errorStacktrace#<br/>
				</cfoutput>
			<cfelse><!---<cfif arguments.disable>--->
				<cfoutput>
					<h2>An unexpected error occurred.</h2>
					<p>We have sent a copy of this error to technical support.</p>
				</cfoutput>

				<!--- Preset params that may not exist --->
				<cfparam name="errorLine" default="">
				<cfparam name="errorTemplate" default="">
				<!--- Set the date --->
				<cfset errorDate = "#dateFormat(now(), 'short')# #timeFormat(now(), 'short')#">

				<!--- Only display errors if the URL contains a .cfm or .cfc extension if showOnlyCFErrors is set to true --->
				<cfif arguments.showOnlyCFErrors>
					<cfif errorUrl contains '.cfm' or errorUrl contains '.cfc'>
						<!--- Save the error to the database and send an email if this is a new error. --->
						<cfinvoke component="#application.blog#" method="saveErrorLog" returnvariable="result">
							<cfinvokeargument name="errorUrl" value="#errorUrl#">
							<cfinvokeargument name="errorEvent" value="#errorEvent#">
							<cfinvokeargument name="errorType" value="#errorType#">
							<cfinvokeargument name="errorMessage" value="#errorMessage#">
							<cfinvokeargument name="errorDetail" value="#errorDetail#">
							<cfinvokeargument name="errorMessage" value="#errorMessage#">
							<cfinvokeargument name="errorTemplate" value="#errorTemplate#">
							<cfinvokeargument name="errorStacktrace" value="#errorStacktrace#">
							<cfinvokeargument name="errorDate" value="#errorDate#">
							<cfinvokeargument name="autoTimeoutApplied" value="#justAppliedTimeout#">
						</cfinvoke>
					</cfif><!---<cfif errorUrl contains '.cfm' or errorUrl contains '.cfc'>--->
				<cfelse>
					<!--- Save all errors to the database and send an email if this is a new error. --->
					<cfinvoke component="#application.blog#" method="saveErrorLog" returnvariable="result">
						<cfinvokeargument name="errorUrl" value="#errorUrl#">
						<cfinvokeargument name="errorEvent" value="#errorEvent#">
						<cfinvokeargument name="errorType" value="#errorType#">
						<cfinvokeargument name="errorMessage" value="#errorMessage#">
						<cfinvokeargument name="errorDetail" value="#errorDetail#">
						<cfinvokeargument name="errorMessage" value="#errorMessage#">
						<cfinvokeargument name="errorTemplate" value="#errorTemplate#">
						<cfinvokeargument name="errorStacktrace" value="#errorStacktrace#">
						<cfinvokeargument name="errorDate" value="#errorDate#">
						<cfinvokeargument name="autoTimeoutApplied" value="#justAppliedTimeout#">
					</cfinvoke>
				</cfif>

			</cfif><!---<cfif errorUrl contains '.cfm' or errorUrl contains '.cfc'>--->

		<cfelse>
			<!--- The application did not start (for example an error in the constructor or in the ORM setup), so there is no blog object to log the error with. Without this branch the page is blank and there is no trace of the error. It is written to the ColdFusion log galaxieBlogStartup, and the details are only shown when the URL has startupDebug=1. --->
			<!--- Errors in an event handler are wrapped in an 'Event handler exception', the real error is in the root cause. --->
			<cfset local.startupError = arguments.exception>
			<!--- The root cause is a struct on Lucee and a Java exception object on Adobe ColdFusion. --->
			<cftry>
				<cfif isDefined("arguments.exception.rootCause") and (isStruct(arguments.exception.rootCause) or isObject(arguments.exception.rootCause))>
					<cfset local.startupError = arguments.exception.rootCause>
				</cfif>
				<cfif isObject(local.startupError)>
					<cfset local.startupMessage = local.startupError.toString()>
				<cfelse>
					<cfset local.startupMessage = (local.startupError.type ?: '') & ': ' & (local.startupError.message ?: '') & ' ' & (local.startupError.detail ?: '')>
				</cfif>
				<cfcatch type="any">
					<cfset local.startupMessage = (arguments.exception.message ?: '')>
				</cfcatch>
			</cftry>
			<cfif isDefined("arguments.exception.tagContext") and isArray(arguments.exception.tagContext) and arrayLen(arguments.exception.tagContext)>
				<cfset local.startupMessage = local.startupMessage & ' (' & arguments.exception.tagContext[1].template & ' line ' & arguments.exception.tagContext[1].line & ')'>
			</cfif>
			<cflog file="galaxieBlogStartup" type="error" text="#local.startupMessage#">
			<cftry><cfheader statuscode="503"><cfcatch type="any"></cfcatch></cftry>
			<cfoutput><h2>This site is not available right now.</h2><p>Please try again in a few minutes.</p></cfoutput>
			<cfif isDefined("url.startupDebug")><cfoutput><pre>#encodeForHTML(local.startupMessage)#</pre></cfoutput></cfif>
		</cfif><!---<cfif isDefined("application.blog")>--->
					
		<!--- Don't return anything --->

	</cffunction>	
						
	<cffunction name="onApplicationEnd">
		<cfargument name="ApplicationScope" required=true/>
		<!--- Do nothing --->
	</cffunction>
	
</cfcomponent>