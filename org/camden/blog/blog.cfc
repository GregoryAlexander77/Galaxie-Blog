<cfcomponent displayName="Blog" output="yes" hint="Galaxie Blog's main cfc. Handles database and other system functions. Originally written by Raymond Camden">

	<!--- Load utils immidiately. --->
	<cfset variables.utils = createObject("component", "utils")>
	<!--- Roles --->
	<cfset variables.roles = structNew()>
	<!--- Instantiate the Render.cfc to render stuff --->
	<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		
	<!---//*****************************************************************************************
		Version
	//******************************************************************************************--->
		
	<!--- Current blog version (This is hardcoded, for now...) --->
	<cfset version = "3.57" />
	<cfset versionName = "3.57 Gold (Toby's Edition)" />
	<cfset versionDate =  "April 10th 2024"> 

	<!--- Require version 9 or higher as we are using ORM --->
	<cfset majorVersion = listFirst(server.coldfusion.productversion)>
	<cfset minorVersion = listGetAt(server.coldfusion.productversion,2,".,")>
	<cfset cfversion = majorVersion & "." & minorVersion>
	<cfif (server.coldfusion.productname is "ColdFusion Server" and cfversion lte 9)>
		<cfset variables.utils.throw("Blog must be run under ColdFusion 9 or higher.")>
	</cfif>
	<cfset variables.isColdFusionMX8 = server.coldfusion.productname is "ColdFusion Server" and cfversion gte 8>

	<!--- cfg file --->
	<cfset variables.cfgFile = "#getDirectoryFromPath(getCurrentTemplatePath())#/blog.ini.cfm">

	<!--- used for rendering --->
	<cfset variables.renderMethods = structNew()>

	<!--- used for settings --->
	<cfset variables.instance = "">

	<!--- Note: when adding a new element in the settings page, you must put it here if it is usign Raymond's logic in blog.cfc. If you don't , you will get a 'xx is not a valid property.' error thrown from the utils.cfc, the new property has not been added to this list. --->
	<cffunction name="init" access="public" returnType="blog" output="false"
		hint="Initialize the blog engine">

		<cfargument name="name" type="string" required="false" default="default" hint="Blog name, defaults to default in blog.ini">
		<cfargument name="instanceData" type="struct" required="false" hint="Allows you to specify BlogCFC info at runtime.">

		<cfset var renderDir = "">
		<cfset var renderCFCs = "">
		<cfset var cfcName = "">
		<cfset var md = "">

		<cfif isDefined("arguments.instanceData")>
			<cfset instance = duplicate(arguments.instanceData)>
		<cfelse>
			<cfif not listFindNoCase(structKeyList(getProfileSections(variables.cfgFile)),name)>
				<cfset variables.utils.throw("#arguments.name# isn't registered as a valid blog.")>
			</cfif>
			<cfset instance = structNew()>
			<cfset instance.dsn = variables.utils.configParam(variables.cfgFile,arguments.name,"dsn")>
			<cfset instance.username = variables.utils.configParam(variables.cfgFile,arguments.name,"username")>
			<cfset instance.password = variables.utils.configParam(variables.cfgFile,arguments.name,"password")>
			<cfset instance.ownerEmail = application.BlogDbObj.getBlogEmail()>
			<cfset instance.ccEmail = application.BlogDbObj.getCcEmailAddress()>
			<cfset instance.blogUrl = application.BlogDbObj.getblogUrl()>
			<!--- Settings. --->
			<cfset instance.parentSiteName = application.BlogDbObj.getBlogParentSiteName()>
			<cfset instance.parentSiteLink = application.BlogDbObj.getBlogParentSiteUrl()>	
			<cfset instance.blogTitle = application.BlogDbObj.getBlogTitle()>
			<cfset instance.blogDescription = application.BlogDbObj.getBlogDescription()>
			<cfset instance.blogDBType = application.BlogDbObj.getBlogDatabaseType()>
			<cfset instance.locale = application.BlogDbObj.getBlogLocale()>
			<!--- I am depracating this. --->
			<cfset instance.commentsFrom = "">
			<cfset instance.failTo = application.BlogDbObj.getBlogEmailFailToAddress()>
			<cfset instance.mailServer = application.BlogDbObj.getBlogMailServer()>
			<cfset instance.mailusername = application.BlogDbObj.getBlogMailServerUserName()>
			<cfset instance.mailpassword = application.BlogDbObj.getBlogMailServerPassword()>
			<!--- Depracated. --->
			<cfset instance.pingurls = "">
			<cfset instance.blogTimeZone = application.BlogDbObj.getBlogTimeZone()>
			<cfset instance.offset = application.BlogDbObj.getBlogServerTimeZoneOffset()>
			<!--- Depracated. --->
			<cfset instance.trackbackspamlist = "">
			<cfset instance.blogkeywords = application.BlogDbObj.getBlogMetaKeywords()>
			<cfset instance.ipblocklist = application.BlogDbObj.getIpBlockList()>
			<!--- Blog option settings --->
			<cfset instance.maxentries = application.BlogOptionDbObj.getEntriesPerBlogPage()>
			<cfset instance.moderate = application.BlogOptionDbObj.getBlogModerated()>
			<cfset instance.usecaptcha = application.BlogOptionDbObj.getUseCaptcha()>
			<cfset instance.allowgravatars = application.BlogOptionDbObj.getAllowGravatar()>
			<!--- Static settings --->	
			<cfset instance.usecfp = false>
			<cfset instance.filebrowse = true>
			<cfset instance.settings = true>
			<!--- The following settings are depracated. --->
			<cfset instance.imageroot = "">
			<cfset instance.itunesSubtitle = "">
			<cfset instance.itunesSummary = "">
			<cfset instance.itunesKeywords = "">
			<cfset instance.itunesAuthor = "">
			<cfset instance.itunesImage = "">
			<cfset instance.itunesExplicit = "">
			<cfset instance.usetweetbacks = false>
			<cfset instance.installed = application.BlogDbObj.getBlogInstalled()>
			<cfset instance.saltalgorithm = application.BlogDbObj.getSaltAlgorithm()>
			<cfset instance.saltkeysize = application.BlogDbObj.getSaltAlgorithmSize()>
			<cfset instance.hashalgorithm = application.BlogDbObj.getHashAlgorithm()>
			<!---Added by Gregory --->
			<cfset instance.addThisApiKey = application.BlogOptionDbObj.getAddThisApiKey()>
			<cfset instance.encryptionPhrase = application.BlogDbObj.getServiceKeyEncryptionPhrase()>
				
		</cfif>

		<!--- Name the blog --->
		<cfset instance.name = arguments.name>

		<!--- If FailTo is blank, use Admin email --->
		<cfif instance.failTo is "">
			<cfset instance.failTo = instance.ownerEmail>
		</cfif>

		<cfreturn this>

	</cffunction>
			
	<!---//*****************************************************************************************
		Check to see if ORM is loaded TODO
	//******************************************************************************************--->
			
	<cffunction name="doOrmReload" access="public" output="false" returntype="boolean" 
		hint="Since CF2021, there is an ORM related error that says 'org.hibernate.QueryException: could not resolve property: DisplayBlogName'. This error occurs daily for some odd reason, but is resolved when ORM is reloaded. Check the query to see if it throws an exception and reload ORM if the error occurs">
		
		<cfset reloadOrm = false>
			
		<cftry>
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					ThemeSettingRef.DisplayBlogName as DisplayBlogName
				)
				FROM 
					Theme as Theme
			</cfquery>
			<cfcatch type="any">
				<cfset reloadOrm = true>
			</cfcatch>
		</cftry>
				
		<cfreturn reloadOrm>
		
	</cffunction>
					
	<!---//*****************************************************************************************
		Helper functions
	//******************************************************************************************--->
			
	<cffunction name="getWebPath" access="public" output="false" returntype="string" 
		hint="Gets the absolute path to the current web folder. If your blog is at https://www.gregoryalexander.com/blog/ for example, this should return '/blog/'. There is another script that Dan wrote (see  https://blog.pengoworks.com/index.cfm/2008/5/8/Getting-the-URLweb-folder-path-in-ColdFusion) with the same name, however, that particular function does not provide a path if you just provide a simple URL (ie http://www.google.com). I need to return a blank string if the URL does not contain a forward slash.">

		<cfargument name="url" required="false" default="#getPageContext().getRequest().getRequestURI()#" hint="Defaults to the current path_info. When viewing pages outside of the main site, we can pass in the root URL, for example from the database." />

		<!--- Replace the index.cfm, index2.cfm, etc (I often develop a new page by appending a 2 after 'index'). Note: we also want to remove the forward slash in the URL. --->
		<cfset cleanedUrl = replaceNoCase(arguments.url, "/index.cfm", "")>
		<cfset cleanedUrl = replaceNoCase(cleanedUrl, "/index2.cfm", "")>

		<!--- Get the parts of the URL --->
		<cfset urlParts = reMatch(
			"^\w+://|[^\/:]+|[\w\W]*$",
			 cleanedUrl
			) />

		<!--- If the blog is installed in the root directory, the urlParts[3] will not be defined and it will raise an error. --->
		<cftry>
			<cfset webPath = urlParts[3]>
			<cfcatch type="any">
				<!--- Return a blank string --->
				<cfset webPath = "">
			</cfcatch>
		</cftry>

		<!--- Return it --->
		<cfreturn webPath>
	</cffunction>
			
	<!--- Determine the base path from the page that is being viewed. --->
	<cffunction name="getBaseUrlFromDatabase" access="public" returntype="string" output="no" hint="This returns the path of the blog from the database. This value was set into the Blog URL field by the blog owner during installation.">
		
		<!--- Get the blog URL from the database and remove the index.cfm extension. --->
		<cfset baseUrl = reReplace(application.BlogDbObj.getBlogUrl(), "(.*)/.cfm", "\1") />
		
		<cfreturn baseUrl>
	</cffunction>
		
	<cffunction name="getBaseUrlFromPage" access="public" returntype="string" output="no" hint="This returns the path of the blog by inspecting the page that the blog resides in.">
		
		<cfset baseUrl = reReplace(getPageContext().getRequest().getRequestURI(), "(.*)/.cfm", "\1") />
		
		<cfreturn baseUrl>
	</cffunction>
		
	<cffunction name="getVersion" access="public" returnType="string" output="false"
				hint="Returns the version of the blog.">
		<cfreturn variables.version>
	</cffunction>

	<cffunction name="getVersionName" access="public" returnType="string" output="false"
				hint="Returns the version of the blog.">
		<cfreturn variables.versionName>
	</cffunction>
		
	<cffunction name="getVersionDate" access="public" returnType="string" output="false"
				hint="Returns the version of the blog.">
		<cfreturn variables.versionDate>
	</cffunction>
		
	<!--- Get the server offset value. This is used when the server is not in the same time zone as the user. --->
	<cffunction name="getOffsetTime" access="public" output="false">
		<cfargument name="serverTimeZoneOffset" type="numeric" required="true">
		<cfargument name="date" type="date" required="true">

		<!---Add or subtract the date with the server time zone offset value.--->
		<cfset dateWithServerTimeOffset = dateAdd( "h", arguments.serverTimeZoneOffset, arguments.date )>

		<!--- Return it. --->
		<cfreturn dateWithServerTimeOffset>

	</cffunction>
	
	<cffunction name="getScriptTypeString" access="public" output="false">
		<!--- Set the type string --->
		<cfif application.deferScriptsAndCss>
			<!--- Defers the loading of the script and css using the deferjs library. --->
			<cfset scriptTypeString = "deferjs">
		<cfelse>
			<cfset scriptTypeString = "text/javascript">
		</cfif>
		
		<cfreturn scriptTypeString>
			
	</cffunction>
			
	<!---//*****************************************************************************************
		User Information
	//******************************************************************************************--->
			
	<cffunction name="getUsersId" access="public" returnType="numeric" output="true" hint="Gets the userId of the user when logged in. If the user is not logged in, will return a zero">
		<!--- Determine if the user is logged in --->
		<cfif structKeyExists(session,"userId")>
			<cfset usersId = session.userId>
		<cfelse>
			<cfset usersId = 0>
		</cfif>
		<cfreturn usersId>
	</cffunction>
			
	<!---//*****************************************************************************************
		Authentication and security
	//******************************************************************************************--->

	<cffunction name="authenticate" access="public" returnType="boolean" output="true" hint="Authenticates a user.">
		<cfargument name="username" type="string" required="true">
		<cfargument name="password" type="string" required="true">
		<!--- The IP address is not required for every single login. We don't  want to log the IP every single time that we authenticate, for example, when we require extra authentication for the same session before a user password changed. --->
		<cfargument name="ipAddress" type="string" required="false" default="">
		<cfargument name="remoteAgent" type="string" required="false" default="">

		<cfset var authenticated = false>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				UserId as UserId,
				UserName as UserName,
				Password as Password,
				Salt as Salt
			)
			FROM Users
			WHERE 
				UserName = <cfqueryparam value="#arguments.username#" cfsqltype="cf_sql_varchar" maxlength="255">
				AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
		</cfquery>
		
		<!--- If the user name was found, see if the user passed in the proper credentials. --->
		<cfif arrayLen(Data)>
			<cfset thisPassword = Data[1]["Password"]>
			<cfset thisSalt = Data[1]["Salt"]>
			<cfset thisUserId = Data[1]["UserId"]>
			<cfif (thisPassword is hash(thisSalt & arguments.password, instance.hashalgorithm))>
				
				<cfset authenticated = true>
					
				<cftransaction>
					<!--- Log the login --->
					<cfset UsersDbObj = entityLoadByPK("Users", thisUserId)>
					<cfset UsersDbObj.setLastLogin(blogNow())>
					<!--- Save the users object --->
					<cfset EntitySave(UsersDbObj)>
						
					<!--- Create a record in the admin log --->
					<cfinvoke component="#application.blog#" method="saveAdminLog" returnVariable="adminLog">
						<cfinvokeargument name="userId" value="#thisUserId#">
						<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#">
						<cfinvokeargument name="HttpUserAgent" value="#arguments.remoteAgent#">
					</cfinvoke>
							
					<cfinvoke component="#application.blog#" method="associateAnonymousUserWithUserId" returnVariable="sucess">
						<cfinvokeargument name="userId" value="#thisUserId#">
						<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#">
						<cfinvokeargument name="HttpUserAgent" value="#arguments.remoteAgent#">
					</cfinvoke>
				
				</cftransaction>
	
			</cfif><!---<cfif (thisPassword is hash(thisSalt & arguments.password, instance.hashalgorithm))>--->

			<cfif isDefined("cookie.cftokens")>
				<cfif (cookie.cftokens is hash(thisSalt & thisPassword, instance.hashalgorithm))>
					<cfset authenticated = true>
				</cfif>
			</cfif>
		</cfif><!---<cfif arrayLen(Data)>--->

		<cfreturn authenticated>

	</cffunction>
							
	<!---//*****************************************************************************************
		Logging Functions
	//******************************************************************************************--->
						
	<!--- ************************** Admin Logs ************************** 
	Note: there is no get function as we are always inserting a new record.
	--->
							
	<cffunction name="saveAdminLog" access="public" returnType="numeric" output="true" hint="Gets an anonymous web user and returns the new id.">
		<cfargument name="userId" type="string" required="false" default="">
		<cfargument name="ipAddress" type="string" required="false" default="">
		<cfargument name="httpUserAgent" type="string" required="false" default="">
			
		<cfparam name="httpUserAgentId" default="0">
			
		<!--- Save the admin log. This will always create a new record --->
		<!--- Load the blog entity. --->
		<cfset BlogDbObj = entityLoadByPk("Blog", 1)>
		<!--- Load the user entity when the userId is passed in --->
		<cfif len(arguments.userId)>
			<cfset UserDbObj = entityLoadByPk("Users", arguments.userId)>
		</cfif>
		<!--- Get or save the IP Address Id --->
		<cfinvoke component="#application.blog#" method="saveIpAddress" returnVariable="ipAddressId">
			<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#">
		</cfinvoke>
		<!--- Load the Ip Address entity --->
		<cfset IpAddressDbObj = entityLoadByPK("IpAddress", ipAddressId)>

		<!--- Get or save the http remote agent --->
		<cfinvoke component="#application.blog#" method="saveHttpUserAgent" returnVariable="httpUserAgentId">
			<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#">
		</cfinvoke>
		<!--- Load the http referrer entity --->
		<cfset HttpUserAgentDbObj = entityLoadByPK("HttpUserAgent", httpUserAgentId)>
			
		<cftransaction>
			<!--- Create a new entity --->
			<cfset AdminLogDbObj = entityNew("AdminLog")>
			<!--- Save it --->
			<cfset AdminLogDbObj.setBlogRef(BlogDbObj)>
			<cfif len(arguments.userId)>
				<cfset AdminLogDbObj.setUserRef(UserDbObj)>
			</cfif>
			<cfif ipAddressId>
				<cfset AdminLogDbObj.setIpAddressRef(IpAddressDbObj)>
			</cfif>
			<cfif httpUserAgentId>
				<cfset AdminLogDbObj.setHttpUserAgentRef(HttpUserAgentDbObj)>
			</cfif>
			<cfset AdminLogDbObj.setDate(blogNow())>
			<cfset EntitySave(AdminLogDbObj)>

			<!--- Get the new ID --->
			<cfset AdminLogId = AdminLogDbObj.getAdminLogId()>
		</cftransaction>
			
		<!--- Return the new id --->
		<cfreturn AdminLogId>
			
	</cffunction>
				
	<cffunction name="associateAnonymousUserWithUserId" access="public" returnType="numeric" output="true" hint="Function used to associate the visitor logs with a user Id">
		<cfargument name="userId" type="string" required="true" default="">
		<cfargument name="ipAddress" type="string" required="true" default="">
		<cfargument name="httpUserAgent" type="string" required="true" default="">
			
		<!--- Get the user. This will return a query object. --->
		<cfinvoke component="#application.blog#" method="getAnonymousUser" returnVariable="anonymousUser">
			<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#">
			<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#">
		</cfinvoke>

		<!--- If the record was found, update the userRef with the userId. --->
		<cfif arrayLen(anonymousUser)>
			<cftransaction>
				<!--- Load the user entity --->
				<cfset UserDbObj = entityLoadByPk("Users", arguments.userId)>

				<!--- Load the anonymousUser entity --->
				<cfset AnonymousUserDbObj = entityLoadByPk("AnonymousUser", anonymousUser[1]["AnonymousUserId"])>
				<!--- Save it --->
				<cfset AnonymousUserDbObj.setUserRef(UserDbObj)>
				<cfset AnonymousUserDbObj.setDate(blogNow())>
				<cfset EntitySave(AnonymousUserDbObj)>
			</cftransaction>
			<cfreturn 1>
		</cfif>
		<cfreturn 0>	
	</cffunction>
							
	<!--- ************************** Visitor Logs ************************** --->
			
	<cffunction name="getVisitorLog" access="public" returnType="array" output="true" hint="Gets the visitor log by a variety of args. This returns a ColdFusion query object.">
		<cfargument name="anonymousUserId" type="string" required="false" default="">
		<cfargument name="userId" type="string" required="false" default="">
		<cfargument name="fullName" type="string" required="false" default="">
		<cfargument name="hitCount" type="string" required="false" default="">
		<cfargument name="ipAddress" type="string" required="false" default="">
		<cfargument name="httpUserAgent" type="string" required="false" default="">
		<cfargument name="postId" type="string" required="false" default="">
			
		<!--- This needs to be limited to the first 10000 rows --->			
		<cfquery name="Data" dbtype="hql" ormoptions="#{maxresults=10000}#">		
			SELECT new Map (
				VisitorLog.VisitorLogId as VisitorLogId,
				IpAddress.IpAddressId as IpAddressId,
				IpAddress.IpAddress as IpAddress,
			 	HttpUserAgent.HttpUserAgentId as HttpUserAgentId,
			 	HttpUserAgent.HttpUserAgent as HttpUserAgent,
				HttpReferrer.HttpReferrer as HttpReferrer,
				AnonymousUser.AnonymousUserId as AnonymousUserId,
				AnonymousUser.HitCount as HitCount,
				AnonymousUser.ScreenHeight as ScreenHeight,
				AnonymousUser.ScreenWidth as ScreenWidth,
				Users.UserId as UserId,
				Users.FullName as FullName,
				Post.PostId as PostId,
				Post.Title as Title,
				VisitorLog.Date as Date
			)
			FROM 
				VisitorLog as VisitorLog
				LEFT OUTER JOIN VisitorLog.AnonymousUserRef as AnonymousUser
				LEFT OUTER JOIN VisitorLog.AnonymousUserRef.HttpUserAgentRef as HttpUserAgent
				LEFT OUTER JOIN VisitorLog.HttpReferrerRef as HttpReferrer
				LEFT OUTER JOIN VisitorLog.AnonymousUserRef.IpAddressRef as IpAddress
				LEFT OUTER JOIN VisitorLog.PostRef as Post
				LEFT OUTER JOIN VisitorLog.AnonymousUserRef.UserRef as Users
				WHERE 0=0
			<cfif len(arguments.anonymousUserId)>
				AND AnonymousUser.AnonymousUserId = <cfqueryparam value="#arguments.anonymousUserId#" cfsqltype="integer"> 
			</cfif>
			<cfif len(arguments.userId)>
				AND Users.UserId = <cfqueryparam value="#arguments.userId#" cfsqltype="integer"> 
			</cfif>
			<cfif len(arguments.fullName)>
				AND Users.FullName = <cfqueryparam value="#arguments.fullName#" cfsqltype="varchar"> 
			</cfif>
			<cfif len(arguments.hitCount)>
				AND AnonymousUser.HitCount = <cfqueryparam value="#arguments.hitCount#" cfsqltype="integer"> 
			</cfif>
			<cfif len(arguments.ipAddress)>
				AND AnonymousUser.IpAddressRef.IpAddress = <cfqueryparam value="#arguments.ipAddress#" cfsqltype="varchar">
			</cfif>
			<cfif len(arguments.httpUserAgent)>
				AND AnonymousUser.HttpUserAgentRef.HttpUserAgent = <cfqueryparam value="#arguments.httpUserAgent#" cfsqltype="varchar">
			</cfif>
			<cfif len(arguments.postId) and isNumeric(postId)>
				AND Post = <cfqueryparam value="#arguments.postId#" cfsqltype="integer">
			</cfif>
				ORDER BY VisitorLog.Date DESC
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
							
	<cffunction name="saveVisitorLog" access="public" returnType="numeric" output="true" hint="Gets an anonymous web user and returns the new id.">
		<cfargument name="anonymousUserId" type="string" required="true" default="">
		<cfargument name="userId" type="string" required="false" default="">
		<cfargument name="httReferrer" type="string" required="false" default="">
		<cfargument name="postId" type="string" required="false" default="">
			
		<cfparam name="visitorLogId" default="0">
				
		<!--- Save the visitor log. This will always create a new record --->
		<!--- Load the blog entity. --->
		<cfset BlogDbObj = entityLoadByPk("Blog", 1)>
		<!--- Load the anonymous user entity --->
		<cfset AnonymousUserDbObj = entityLoadByPk("AnonymousUser", arguments.anonymousUserId)>
		<!--- Load the user entity when the userId is passed in --->
		<cfif len(arguments.userId)>
			<cfset UserDbObj = entityLoadByPk("Users", arguments.userId)>
		</cfif>
		<!--- Save the http referrer. This will pass back the id. --->
		<cfinvoke component="#application.blog#" method="saveHttpReferrer" returnVariable="httpReferrerId">
			<cfinvokeargument name="HttpReferrer" value="#CGI.Http_Referer#">
		</cfinvoke>
		<!--- Load the referrer entity if it was passed in. --->
		<cfif httpReferrerId>
			<cfset HttpReferrerDbObj = entityLoadByPk("HttpReferrer", httpReferrerId)>
		</cfif>
		<!--- Load the post --->
		<cfif len(postId)>
			<cfset PostDbObj = entityLoadByPk("Post", arguments.postId)>
		</cfif>
			
		<cftry>
			<cftransaction>
				<!--- Create a new entity --->
				<cfset VisitorLogDbObj = entityNew("VisitorLog")>
				<!--- Save it --->
				<cfset VisitorLogDbObj.setBlogRef(BlogDbObj)>
				<cfif len(arguments.userId)>
					<cfset VisitorLogDbObj.setUserRef(UserDbObj)>
				</cfif>
				<cfset VisitorLogDbObj.setAnonymousUserRef(AnonymousUserDbObj)>
				<cfif httpReferrerId>
					<cfset VisitorLogDbObj.setHttpReferrerRef(HttpReferrerDbObj)>
				</cfif>
				<cfif len(postId)>
					<cfset VisitorLogDbObj.setPostRef(PostDbObj)>
				</cfif>
				<cfset VisitorLogDbObj.setDate(blogNow())>
				<cfset EntitySave(VisitorLogDbObj)>

				<!--- Get the new ID --->
				<cfset visitorLogId = VisitorLogDbObj.getVisitorLogId()>
			</cftransaction>
			<cfcatch type="any">
				<!--- TODO Occasionally, I am having a 'A different object with the same identiier value was already associated with the sesion [blog#1]' error here that I am escaping. --->
				<cfset visitorLogId = 0>
			</cfcatch>
		</cftry>
			
		<!--- Return the new id --->
		<cfreturn visitorLogId>
			
	</cffunction>
							
	<!--- ************************** Anonymous Users ************************** 
	Note: this table can store a bunch of other data, such as the time-zone, language, etc, however, I am only trying to get the IP and user agent to see who views certain posts and made comments. You can easilly use google analytics or another software if you want better user tracking here.
	--->
	<cffunction name="getAnonymousUser" access="public" returnType="array" output="true" hint="Gets an anonymous web user and returns a HQL array.">
		<cfargument name="anonymousUserId" type="string" required="false" default="">
		<cfargument name="ipAddress" type="string" required="false" default="">
		<cfargument name="httpUserAgent" type="string" required="false" default="">
			
		<cfparam name="httpUserAgentId" default="0">
			
		<!--- Get the IpAddress and HttpUserAgent Id's. These methods will save the ip and remote user if they are not there. --->
		<cfinvoke component="#application.blog#" method="saveIpAddress" returnVariable="ipAddressId">
			<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#">
		</cfinvoke>
		<cfinvoke component="#application.blog#" method="saveHttpUserAgent" returnVariable="httpUserAgentId">
			<cfinvokeargument name="HttpUserAgent" value="#arguments.httpUserAgent#">
		</cfinvoke>
					
		<!--- Note: the following query does not work with cfqueryparam. I get an invalid integer message no matter what I do (and this is typical of some ORM queries). It is not a security issue here as I am checking to see if it is a siple numeric value --->			
		<cfquery name="Data" dbtype="hql" ormoptions="#{maxresults=1}#">		
			SELECT new Map (
				AnonymousUserId as AnonymousUserId,
				IpAddressRef.IpAddressId as IpAddressId,
				IpAddressRef.IpAddress as IpAddress,
				HttpUserAgentRef.HttpUserAgentId as HttpUserAgentId,
				HttpUserAgentRef.HttpUserAgent as HttpUserAgent,
				HitCount as HitCount,
				ScreenHeight as ScreenHeight,
				ScreenWidth as ScreenWidth
			)
			FROM 
				AnonymousUser as tblAnonymousUser
			WHERE 
				BlogRef = 1
			<cfif len(arguments.anonymousUserId)>
				AND AnonymousUserId = <cfqueryparam value="#arguments.anonymousUserId#"> 
			</cfif>
			<cfif len(ipAddressId) and isNumeric(ipAddressId)>
				AND IpAddressRef = #ipAddressId#
			</cfif>
			<cfif len(httpUserAgentId) and isNumeric(httpUserAgentId)>
				AND HttpUserAgentRef = #httpUserAgentId#
			</cfif>
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
				
	<!--- Save the anonymous user --->
	<cffunction name="saveAnonymousUser" access="public" returnType="any" output="true" hint="Saves an anonymous web user and returns the anonymous user entity back to the client.">
		<cfargument name="anonymousUserId" type="string" required="false" default="">
		<cfargument name="ipAddress" type="string" required="false" default="">
		<cfargument name="httpUserAgent" type="string" required="false" default="">
		<cfargument name="httpReferrer" type="string" required="false" default="">
		<cfargument name="ScreenWidth" type="string" required="false" default="">
		<cfargument name="ScreenHeight" type="string" required="false" default="">
			
		<cfparam name="httpUserAgentId" default="0">
			
		<!--- Get the user. This will return a query object. --->
		<cfinvoke component="#application.blog#" method="getAnonymousUser" returnVariable="anonymousUser">
			<cfinvokeargument name="anonymousUserId" value="#arguments.anonymousUserId#">
			<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#">
			<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#">
		</cfinvoke>
				
		<!--- Set the hit count --->
		<cftry>
			<cfset hitCount = round(anonymousUser[1]["HitCount"] + 1)>
			<cfcatch type="any">
				<cfset hitCount = 1>
			</cfcatch>
		</cftry>
					
		<cfif not arrayLen(anonymousUser)>
			
			<!--- Get or save the IP Address Id --->
			<cfinvoke component="#application.blog#" method="saveIpAddress" returnVariable="ipAddressId">
				<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#">
			</cfinvoke>
			<!--- Load the Ip Address entity --->
			<cfset IpAddressDbObj = entityLoadByPK("IpAddress", ipAddressId)>
				
			<!--- Get or save the http remote agent --->
			<cfinvoke component="#application.blog#" method="saveHttpUserAgent" returnVariable="httpUserAgentId">
				<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#">
			</cfinvoke>
			<!--- Load the http referrer entity --->
			<cfset HttpUserAgentDbObj = entityLoadByPK("HttpUserAgent", httpUserAgentId)>
				
			<!--- Get or save the http referrer --->
			<cfinvoke component="#application.blog#" method="saveHttpReferrer" returnVariable="httpReferrerId">
				<cfinvokeargument name="httpReferrer" value="#arguments.httpReferrer#">
			</cfinvoke>
			<!--- Load the http referrer entity --->
			<cfset HttpReferrerDbObj = entityLoadByPK("HttpReferrer", httpReferrerId)>
				
			<!--- Load the blog entity. --->
			<cfset BlogDbObj = entityLoadByPk("Blog", 1)>
			
			<cftransaction>
				<!--- Create a new entity --->
				<cfset AnonymousUserDbObj = entityNew("AnonymousUser")>
				<!--- Save it --->
				<cfset AnonymousUserDbObj.setBlogRef(BlogDbObj)>
				<cfset AnonymousUserDbObj.setIpAddressRef(IpAddressDbObj)>
				<cfset AnonymousUserDbObj.setHttpUserAgentRef(HttpUserAgentDbObj)>
				<cfset AnonymousUserDbObj.setScreenWidth(arguments.screenWidth)>
				<cfset AnonymousUserDbObj.setScreenHeight(arguments.screenHeight)>
				<cfset AnonymousUserDbObj.setHitCount(1)>
				<cfset AnonymousUserDbObj.setDate(blogNow())>
				<cfset EntitySave(AnonymousUserDbObj)>

				<!--- Get the new Ip Address ID --->
				<cfset anonymousUserId = AnonymousUserDbObj.getAnonymousUserId()>
			</cftransaction>
		<cfelse>
			<cfset anonymousUserId = anonymousUser[1]["AnonymousUserId"]>
			
			<cftransaction>
				<!--- Load the entity --->
				<cfset AnonymousUserDbObj = entityLoadByPk("AnonymousUser", anonymousUserId)>
				<!--- Save data --->
				<cfset AnonymousUserDbObj.setScreenWidth(arguments.screenWidth)>
				<cfset AnonymousUserDbObj.setScreenHeight(arguments.screenHeight)>
				<cfset AnonymousUserDbObj.setHitCount(hitCount)>
				<cfset AnonymousUserDbObj.setDate(blogNow())>
				<cfset EntitySave(AnonymousUserDbObj)>
			</cftransaction>
		</cfif>
			
		<!--- Return the entire ORM object --->
		<cfreturn AnonymousUserDbObj>
			
	</cffunction>
				
	<!--- ************************** Ip Address for logging (visits, comments, and admin logins) ************************** --->
	<cffunction name="getIpAddressId" access="public" returnType="string" output="true" hint="Gets an IP address.">
		<cfargument name="ipAddress" type="string" required="true">
			
		<!--- Get the IP. ---> 	
		<cfquery name="getIpAddressId" dbtype="hql" ormoptions="#{maxresults=1}#">		
			SELECT new Map (
				IpAddressId as IpAddressId)
			<!--- Prefix the IP address table name as it will conflict with the identical column name. --->
			FROM IpAddress as tblIpAddress 
			WHERE IpAddress = <cfqueryparam value="#arguments.ipAddress#">
		</cfquery>
		<!--- Return the first item in the query array --->
		<cfif arrayLen(getIpAddressId)>
			<cfset ipAddressId = getIpAddressId[1]["IpAddressId"]>
		<cfelse>
			<cfset ipAddressId = 0>
		</cfif>
		<cfreturn ipAddressId>
	</cffunction>
			
	<cffunction name="saveIpAddress" access="public" returnType="string" output="true" hint="Saves a unique IP to the db.">
		<cfargument name="ipAddress" type="string" required="true" default="">
		<!--- Get the IP. ---> 
		<cfset ipAddressId = this.getIpAddressId(arguments.ipAddress)>
		<cfif ipAddressId eq 0>
			<!--- Load the blog entity. This is not functional at the moment to have several blogs on a site, but the logic is in the database. --->
			<cfset BlogDbObj = entityLoadByPk("Blog", 1)>

			<!--- Create a new entity --->
			<cfset IpAddressDbObj = entityNew("IpAddress")>
			<!--- Save it --->
			<cfset IpAddressDbObj.setBlogRef(BlogDbObj)>
			<cfset IpAddressDbObj.setIpAddress(arguments.ipAddress)>
			<cfset IpAddressDbObj.setDate(blogNow())>
			<cfset EntitySave(IpAddressDbObj)>
			<!--- Get the new Ip Address ID --->
			<cfset ipAddressId = IpAddressDbObj.getIpAddressId()>
		</cfif>
		<!--- Return the ipAddressId --->
		<cfreturn ipAddressId>
	</cffunction>
			
	<!--- ************************** Http User Agent strings for logging (visits, comments, and admin logins) ************************** --->
	<cffunction name="getHttpUserAgentId" access="public" returnType="string" output="true" hint="Gets a HTTP Remote Agent Id.">
		<cfargument name="httpUserAgent" type="string" required="true">
			
		<!--- Get the remote agent from the db. ---> 
		<cfquery name="getHttpUserAgent" dbtype="hql" ormoptions="#{maxresults=1}#">		
			SELECT new Map (
				HttpUserAgentId as HttpUserAgentId)
			<!--- Prefix the HttpUserAgent table name as it will conflict with the identical column name. --->
			FROM HttpUserAgent as tblHttpUserAgent 
			WHERE HttpUserAgent = <cfqueryparam value="#arguments.httpUserAgent#" cfsqltype="varchar">
		</cfquery>
		<!--- Return the first item in the query array --->
		<cfif arrayLen(getHttpUserAgent)>
			<cfset httpUserAgentId = getHttpUserAgent[1]["HttpUserAgentId"]>
		<cfelse>
			<cfset httpUserAgentId = 0>
		</cfif>
		<cfreturn httpUserAgentId>
	</cffunction>
			
	<cffunction name="saveHttpUserAgent" access="public" returnType="string" output="true" hint="Saves a remote agent and passes back the HttpUserAgentId.">
		<cfargument name="httpUserAgent" type="string" required="true">
		<!--- Get the user agent. ---> 
		<cfset httpUserAgentId = this.getHttpUserAgentId(arguments.httpUserAgent)>
		<cfif httpUserAgentId eq 0>
			<!--- Load the blog entity. This is not functional at the moment to have several blogs on a site, but the logic is in the database. --->
			<cfset BlogDbObj = entityLoadByPk("Blog", 1)>
				
			<!--- Create a new entity --->
			<cfset HttpUserAgentObj = entityNew("HttpUserAgent")>
			<!--- Save it --->
			<cfset HttpUserAgentObj.setBlogRef(BlogDbObj)>
			<cfset HttpUserAgentObj.setHttpUserAgent(arguments.httpUserAgent)>
			<cfset HttpUserAgentObj.setDate(blogNow())>
			<cfset EntitySave(HttpUserAgentObj)>
			<!--- Get the new ID --->
			<cfset httpUserAgentId = HttpUserAgentObj.getHttpUserAgentId()>
		</cfif>
		<!--- Return the userAgentId --->
		<cfreturn httpUserAgentId>
	</cffunction>
			
	<!--- ************************** Http Referrer strings ************************** --->
	<cffunction name="getHttpReferrerId" access="public" returnType="string" output="true" hint="Gets a HTTP Referrer Id.">
		<cfargument name="httpReferrer" type="string" required="true">
			
		<!--- Get the remote agent from the db. ---> 
		<cfquery name="getHttpReferrer" dbtype="hql" ormoptions="#{maxresults=1}#">		
			SELECT new Map (
				HttpReferrerId as HttpReferrerId)
			<!--- Prefix the HttpReferrer table name as it will conflict with the identical column name. --->
			FROM HttpReferrer as tblHttpReferrer
			WHERE HttpReferrer = <cfqueryparam value="#arguments.httpReferrer#">
		</cfquery>
		<!--- Return the first item in the query array --->
		<cfif arrayLen(getHttpReferrer)>
			<cfset httpReferrerId = getHttpReferrer[1]["HttpReferrerId"]>
		<cfelse>
			<cfset httpReferrerId = 0>
		</cfif>
		<cfreturn httpReferrerId>
	</cffunction>
			
	<cffunction name="saveHttpReferrer" access="public" returnType="string" output="true" hint="Saves a HttpReferrer and passes back the HttpReferrerId.">
		<cfargument name="httpReferrer" type="string" required="true">
		
		<cfparam name="httpReferrerId" default="0">
			
		<cfif len(httpReferrer)>
			<!--- Get the referrer. ---> 
			<cfset httpReferrerId = this.getHttpReferrerId(arguments.httpReferrer)>
			<cfif httpReferrerId gt 0>
				<!--- Load the blog entity. This is not functional at the moment to have several blogs on a site, but the logic is in the database. --->
				<cfset BlogDbObj = entityLoadByPk("Blog", 1)>

				<!--- Create a new entity --->
				<cfset HttpReferrerObj = entityNew("HttpReferrer")>
				<!--- Save it --->
				<cfset HttpReferrerObj.setBlogRef(BlogDbObj)>
				<cfset HttpReferrerObj.setHttpReferrer(arguments.httpReferrer)>
				<cfset HttpReferrerObj.setDate(blogNow())>
				<cfset EntitySave(HttpReferrerObj)>
				<!--- Return the new id --->
				<cfset httpReferrerId = HttpReferrerObj.getHttpReferrerId()>
			<cfelse>
				<cfset httpReferrerId = 0>
			</cfif>
		</cfif>
		<cfreturn httpReferrerId>
		
	</cffunction>
							
	<!---//*****************************************************************************************
		Cache functions
	//******************************************************************************************--->
							
	<cffunction name="clearScopeCache" access="public" returntype="boolean" output="false"
			hint="Clears the scope cache. Returns a boolean value to indicate if the cache was cleared">
		
		<!--- Flush our cache. It will not exist when first installing the blog --->
		<cftry>
			<!--- Note: each Kendo Theme has a cache. There are too many caches to try to flush so we are going to flush them all. --->
			<!--- Clear everything from the scopecache library --->
			<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" scope="application" clearall="true">
			<!--- Clear CF Caching --->
			<cfcache action="flush"></cfcache>
			<cfcatch type="any">
				<cfset error = 'cache does not exist'>
			</cfcatch>
		</cftry>
				
		<cfreturn 1>
			
	</cffunction>
			
	<cffunction name="getDisableCache" access="remote" output="yes" returntype="boolean" 
			hint="Determines whether the cache should be disabled. This is used to refresh the contents of the site when needed. I expect this function to become more complex to allow for granular caching in the future">
		
		<cfparam name="disableCache" default="false">

		<!--- Disable the cache when the URL argument is found --->
		<cfif structKeyExists(URL, "disableCache")>
			<cfset disableCache = true>
		<cfelse>
			<cfset disableCache = application.disableCache>
		</cfif>

		<cfreturn disableCache>

	</cffunction> 
							
	<!---//*****************************************************************************************
		Generic blog functions
	//******************************************************************************************--->

	<!--- Date and time functions. --->
	<cffunction name="blogNow" access="public" returntype="date" output="false"
			hint="Returns now() with the offset.">
			
		<!--- Get the local time. MomentCfc requires the new keyword to initialize. See https://github.com/AlumnIQ/momentcfc/blob/master/readme.md for documentation. Note: this requires the time zone string to work right now and it is not used.
		<cfset blogDateTime = new "#application.momentComponentPath#"( now() ).tz( instance.blogTimeZone ).time> --->
		<cfset blogDateTime = dateAdd("h", instance.offset, now())>
			
		<cfreturn blogDateTime>
	</cffunction>
			
	<cffunction name="getBlogDateTime" access="public" returntype="date" output="false"
			hint="Takes a date and returns what time it should be for the blog.">
		<cfargument name="dateTime" type="date" required="true" />
			
		<!--- Get the local time. MomentCfc requires the new keyword to initialize. See https://github.com/AlumnIQ/momentcfc/blob/master/readme.md for documentation. Note: this requires the time zone string to work right now and it is not used.
		<cfset blogDateTime = new "#application.momentComponentPath#"( now() ).tz( instance.blogTimeZone ).time> --->
		<cfset blogDateTime = dateAdd("h", instance.offset, arguments.dateTime)>
			
		<cfreturn blogDateTime>
	</cffunction>
			
	<cffunction name="getServerDateTime" access="public" returntype="date" output="false"
			hint="Takes a date from the client and returns the date that it should be on the Server. This is used to schedule tasks on the server from the front end.">
		<cfargument name="dateTime" type="date" required="true" />
		
		<!--- Invoke the Time Zone cfc --->
		<cfobject component="#application.timeZoneComponentPath#" name="TimeZoneObj">
		
		<!--- Get the time zone identifier on the server (ie America/Los_Angeles) from the TimeZone component --->
		<cfset serverTimeZoneId = TimeZoneObj.getServerId()>
		<!--- Get the blog time zone offset (-8) from the database and is populated by the Blog Time interface. We probably should be storing the actual identifier (America/Los_Angeles) in the database in the future to get the proper DST --->
		<cfset blogTimeZone = application.BlogDbObj.getBlogTimeZone()>
		<!--- Get the time zone identifier (America/Los_Angeles) by the GMT offset. This will pull up multiple options, but we just need a working identifier and will select the first one.  --->
		<cfset blogTimeZoneList = TimeZoneObj.getTZByOffset(blogTimeZone)>
		<!--- Get the first value in the array. We don't need this to be accurate, we just need a valid identifier to use. --->
		<cfset blogTimeZoneId = blogTimeZoneList[1]>
			
		<!--- Now use the convertTZ function to convert the blog time to server time. The blog time is the time zone of the site administrator that is writing the articles. We may want to add time zones for all blog users with the edit post role in the future. 
		convertTz(thisDate,	fromTZ, toTZ) --->
		<cfset serverDateTime = TimeZoneObj.convertTZ(arguments.dateTime, blogTimeZoneId, serverTimeZoneId)>
			
		<!--- Return it. --->
		<cfreturn serverDateTime>
			
	</cffunction>
			
	<!--- File and paths --->
	<cffunction name="getRootUrl" access="public" returnType="string" output="false"
			hint="Simple helper function to get root url.">

		<cfset var theURL = replace(instance.blogUrl, "index.cfm", "")>
		
		<!--- Return it --->
		<cfreturn theURL>

	</cffunction>
			
	<!---******************************************************************************************************** 
		Links 
	*********************************************************************************************************--->

	<cffunction name="makeCategoryLink" access="public" returnType="string" output="false"
			hint="Generates links for a category.">
		<cfargument name="categoryId" type="numeric" required="true">
		
		<cfset var Data = []>

		<!---// make sure the cache exists //--->
		<cfif not structKeyExists(variables, "catAliasCache")>
			<cfset variables.catAliasCache = structNew() />
		</cfif>

		<cfif structKeyExists(variables.catAliasCache, arguments.categoryId)>
			<cfreturn variables.catAliasCache[arguments.categoryId]>
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				CategoryAlias as CategoryAlias
			)
			FROM  
				Category
			WHERE 0=0
				AND CategoryId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.categoryId#" maxlength="35">
				AND BlogRef = #application.BlogDbObj.getBlogId()#			
		</cfquery>

		<cfif arrayLen(Data)>
			<cfset categoryLink = instance.blogUrl & '/' & Data[1]["CategoryAlias"]>
		<cfelse>
			<cfset categoryLink = instance.blogUrl & '?mode=cat&amp;categoryId=' & arguments.categoryId>
		</cfif>
		<!--- Make the link safe for server side rewrite rules --->
		<cfset variables.catAliasCache[arguments.categoryId] = makeRewriteRuleSafeLink(categoryLink)>
		
		<!--- Return it --->
		<cfreturn variables.catAliasCache[arguments.categoryId]>
			
	</cffunction>
			
	<cffunction name="makeTagLink" access="public" returnType="string" output="false"
			hint="Generates links for a tag.">
		<cfargument name="tagId" type="numeric" required="true">
		
		<cfset var Data = []>

		<!---// make sure the cache exists //--->
		<cfif not structKeyExists(variables, "tagAliasCache")>
			<cfset variables.tagAliasCache = structNew() />
		</cfif>

		<cfif structKeyExists(variables.tagAliasCache, arguments.tagId)>
			<cfreturn variables.tagAliasCache[arguments.tagId]>
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				TagAlias as TagAlias
			)
			FROM  
				Tag
			WHERE 0=0
				AND TagId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.tagId#" maxlength="35">
				AND BlogRef = #application.BlogDbObj.getBlogId()#			
		</cfquery>

		<cfif arrayLen(Data)>
			<cfset tagLink = instance.blogUrl & '/tag/' & Data[1]["TagAlias"]>
		<cfelse>
			<cfset tagLink = instance.blogUrl & '?mode=cat&amp;tagId=' & arguments.tagId>
		</cfif>
		<!--- Make the link safe for server side rewrite rules --->
		<cfset variables.tagAliasCache[arguments.tagId] = makeRewriteRuleSafeLink(tagLink)>
		
		<!--- Return it --->
		<cfreturn variables.tagAliasCache[arguments.tagId]>
			
	</cffunction>

	<cffunction name="makeUserLink" access="public" returnType="string" output="false"
				hint="Generates links for viewing blog posts by user/blog poster.">
		<cfargument name="name" type="string" required="true">
			
		<cfset link = instance.blogUrl & '/postedby/' & replace(arguments.name," ","_", "all")>

		<cfreturn makeRewriteRuleSafeLink(link)>

	</cffunction>

	<cffunction name="makeLink" access="public" returnType="string" output="true"
		hint="Generates links for a post.">
		
		<cfargument name="postId" type="numeric" required="true" />
		<cfargument name="updateCache" type="boolean" required="false" default="false" />
		
		<!--- Include the string utilities. --->
		<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
		
		<cfset var q = "">
		<cfset var realdate = "">

		<!--- I turned off the caching as the links went awry --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Post.PostId as PostId,
				PostUuid as PostUuid,
				PostAlias as PostAlias,
				DatePosted as DatePosted)
			FROM Post as Post 
			WHERE 0=0
				<!-----AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">--->
				AND PostId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.postId#" maxlength="35">
				AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		<!---<cfdump var="#Data#">--->

		<!--- Set the return string --->
		<cfset returnStr = instance.blogUrl & "/" & year(Data[1]["DatePosted"]) & "/" & month(Data[1]["DatePosted"]) & "/" & day(Data[1]["DatePosted"]) & "/" & Data[1]["PostAlias"]>

		<!--- Return it --->
		<cfreturn StringUtilsObj.trimStr(makeRewriteRuleSafeLink(returnStr))>
	
	</cffunction>
				
	<cffunction name="makeCommentLink" access="public" returnType="string" output="false"
		hint="Generates links for a comment. We don't  need to cache this as we already have all of the date in the recent comments query object.">
		
		<cfargument name="postId" type="numeric" required="true" />
		<cfargument name="datePosted" type="date" required="true" />
		<cfargument name="postAlias" type="string" required="true" />
		<cfargument name="commentId" type="numeric" required="true" />
		
		<cfset commentLink = instance.blogUrl & "/" 
			   & year(arguments.datePosted) & "/" 
			   & month(arguments.datePosted) & "/" 
			   & day(arguments.datePosted) & "/" 
			   & arguments.postAlias & "#chr(35)#" 
			   & "c" & commentId>
		
		<cfreturn commentLink>
		
	</cffunction>
			
	<cffunction name="makeRewriteRuleSafeLink" access="public" returnType="string" output="false"
			hint="Removes the index.cfm from links. This is necessary for the server side rewrite rule.">
		<cfargument name="link" required="yes" hint="Pass in the link">
			
		<cfif application.serverRewriteRuleInPlace>
			<cfset newLink = replaceNoCase(arguments.link, '/index.cfm', '')>
		<cfelse>
			<cfset newLink = arguments.link>
		</cfif>
		
		<cfreturn newLink>

	</cffunction>
	
	<cffunction name="cacheLink" access="public" returnType="struct" output="false"
			hint="Caches a link.">
		<cfargument name="postId" type="numeric" required="true" />
		<cfargument name="alias" type="string" required="true" />
		<cfargument name="posted" type="date" required="true" />

		<!---// make sure the cache exists //--->
		<cfif not structKeyExists(variables, "lCache")>
			<cfset variables.lCache = structNew() />
		</cfif>

		<cfset variables.lCache[arguments.postId] = structNew() />
		<cfset variables.lCache[arguments.postId].alias = arguments.alias />
		<cfset variables.lCache[arguments.postId].posted = arguments.posted />

		<cfreturn arguments />
	</cffunction>

	<cffunction name="makeAlias" access="public" returnType="string" output="false"
			hint="Formats the title for SES (search engine safe).">
		<cfargument name="title" type="string" required="true">

		<!--- Remove non alphanumeric but keep spaces. --->
		<!---// replace the & symbol with the word "and" //--->
		<cfset arguments.title = replace(arguments.title, "&amp;", "and", "all") />
		<!---// remove html entities //--->
		<cfset arguments.title = reReplace(arguments.title, "&[^;]+;", "", "all") />
		<cfset arguments.title = reReplace(arguments.title,"[^0-9a-zA-Z ]","","all")>
		<!--- change spaces to - --->
		<cfset arguments.title = replace(arguments.title," ","-","all")>

		<cfreturn lCase(arguments.title)>
	</cffunction>
				
	<!--- //************************************************************************************************************
			Calendar functions
	//**************************************************************************************************************--->

	<cffunction name="getActiveDays" returnType="string" output="false" 
			hint="Returns a list of unique days that have at least one post.">
		<cfargument name="year" type="numeric" required="true">
		<cfargument name="month" type="numeric" required="true">

		<cfset var Data = "[]">
		<cfset var dtMonth = createDateTime(arguments.year,arguments.month,1,0,0,0)>
		<cfset var dtEndOfMonth = createDateTime(arguments.year,arguments.month,daysInMonth(dtMonth),23,59,59)>
		<cfset var days = "">
		<cfset var posted = "">
			
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT
				new Map (DatePosted as DatePosted)
			FROM Post
			WHERE
				DatePosted >= <cfqueryparam value="#dtMonth#" cfsqltype="cf_sql_timestamp">
				AND DatePosted <= <cfqueryparam value="#dtEndOfMonth#" cfsqltype="cf_sql_timestamp">
		</cfquery>

		<!--- Prepare the list. --->
		<cfparam name="daysThatHavePosts" default="" type="string">
		<!--- Loop through the data --->
		<cfloop from="1" to="#arrayLen(Data)#" index="i">
			<cfif i lt arrayLen(Data)>
				<!--- Note: the query may have duplicate dates if more than one post was made during the day. Since we can't extract and group by the day in HQL (at least I don't  know how to do this), I am going to inspect the value and make sure that it is not already in the list before putting it in. --->
				<cfif not daysThatHavePosts contains day(Data[i]["DatePosted"])>
					<!--- Convert the date into a day and stuff it into the list and append a comma.--->
					<cfset daysThatHavePosts = daysThatHavePosts & day(Data[i]["DatePosted"]) & ",">
				</cfif>
			<cfelse>
				<cfif not daysThatHavePosts contains day(Data[i]["DatePosted"])>
					<!--- This is the last element in the array. We don't  need a comma here. --->
					<cfset daysThatHavePosts = daysThatHavePosts & day(Data[i]["DatePosted"])>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn daysThatHavePosts>

	</cffunction>
	
	<cffunction name="getArchives" access="public" returnType="array" output="false" 
			hint="I return a query containing all of the past months/years that have entries along with the entry count">
		<cfargument name="archiveYears" type="numeric" required="false" hint="Number of years back to pull archives for. This helps limit the result set that can be returned" default="0">
		
		<cfset var Data = "[]">	
		<cfset var getMonthlyArchives = "" />
		<cfset var fromYear = year(blogNow()) - arguments.archiveYears />
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				month(DatePosted) as PreviousMonths, 
				year(DatePosted) as PreviousYears, 
				count(PostId) as EntryCount
			)
			FROM Post
			WHERE 0=0
				AND Released = 1
				AND Remove = 0
				AND YEAR(DatePosted) >= #fromYear#
				AND BlogRef = #application.BlogDbObj.getBlogId()#
			GROUP BY 
				YEAR(DatePosted), MONTH(DatePosted) 
			ORDER BY 
				PreviousYears desc, PreviousMonths desc				
		</cfquery>
		
		<cfreturn Data>
	</cffunction>
			
	<!---//*****************************************************************************************
		CMS Content functions
	//******************************************************************************************--->
			
	<!---//*****************************************************************************************
		Custom Windows
	//******************************************************************************************--->
			
	<cffunction name="getCustomWindowContent" access="public" returnType="any" output="false"
			hint="Gets the custom windows for a post">
		<cfargument name="postId" type="string" required="false" default="">

			
		<!--- Get the custom windows from the db --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				CustomWindowContentId as CustomWindowContentId, 
				PostRef as PostRef,
				CfincludePath as CfincludePath,
				CustomWindowShortDesc as CustomWindowShortDesc,
				Content as Content,
				ButtonName as ButtonName,
				ButtonLabel as ButtonLabel,
				ButtonOptArgs as ButtonOptArgs,
				WindowName as WindowName,
				WindowTitle as WindowTitle,
				WindowHeight as WindowHeight,
				WindowWidth as WindowWidth
			)
			FROM CustomWindowContent
			WHERE Active = <cfqueryparam value="1" cfsqltype="bit">
			<cfif len(arguments.postId)>AND PostRef = <cfqueryparam value="#arguments.postId#" cfsqltype="integer"></cfif>
		</cfquery>
			
		<cfreturn Data>

	</cffunction>
			
	<cffunction name="getCustomWindowContentById" access="public" returnType="any" output="false"
				hint="Handles adding a view to an entry.">
		<cfargument name="customWindowId" type="numeric" required="true">
			
			<!--- Get the custom windows from the db --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				CustomWindowContentId as CustomWindowContentId, 
				PostRef as PostRef,
				CfincludePath as CfincludePath,
				CustomWindowShortDesc as CustomWindowShortDesc,
				Content as Content,
				ButtonName as ButtonName,
				ButtonLabel as ButtonLabel,
				ButtonOptArgs as ButtonOptArgs,
				WindowName as WindowName,
				WindowTitle as WindowTitle,
				WindowHeight as WindowHeight,
				WindowWidth as WindowWidth
			)
			FROM CustomWindowContent
			WHERE CustomWindowContentId = <cfqueryparam value="#arguments.customWindowId#" cfsqltype="numeric">
			AND Active = <cfqueryparam value="1" cfsqltype="bit">
		</cfquery>
			
		<cfreturn Data>

	</cffunction>
			
	<!---//*****************************************************************************************
		Email functions
	//******************************************************************************************--->
			
	<cffunction name="promptToEmailToSubscribers" access="public" returnType="boolean" output="false"
			hint="Determines if the client should prompt the user to see if they want to send an email out to the subscribers. This is used to check to see when we should raise the prompt.">
		<cfargument name="postId" type="string" required="true">
			
		<!--- Set this to true and overwrite it if necessary --->
		<cfset promptToEmailToSubscribers = true>
			
		<!--- Error checking --->
		<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
		<cfset getPost = application.blog.getPostByPostId(arguments.postId,true,false)>

		<!--- Is the post released? --->
		<cfif not getPost[1]["Released"]>
			<cfset promptToEmailToSubscribers = false>
		</cfif>

		<!--- Was this already mailed? --->
		<cfif getPost[1]["Mailed"]>
			<cfset promptToEmailToSubscribers = false>
		</cfif>

		<!--- Is posted less than now? --->
		<cfif dateCompare(getPost[1]["DatePosted"], application.blog.blogNow()) is 1>
			<cfset promptToEmailToSubscribers = false>
		</cfif>
			
		<!--- Return it --->
		<cfreturn promptToEmailToSubscribers>
			
	</cffunction>
			
	<cffunction name="sendPostEmailToSubscribers" access="public" returnFormat="json" output="true"
			hint="Sends a new post to the blog subscribers">
		<cfargument name="postId" type="string" required="true">
		<cfargument name="byPassErrors" type="boolean" required="false" default="false">
			
		<cfparam name="error" default="false">
		<cfparam name="errorMessage" default="">
			
		<cfset response = {} />
			
		<!--- Error checking --->
		<!--- Get the post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) )--->
		<cfset getPost = application.blog.getPostByPostId(arguments.postId,true,false)>

		<!--- Is the post released? --->
		<cfif not getPost[1]["Released"]>
			<cfset error = true>
			<cfset response[ "notReleased" ] = true />
		</cfif>

		<!--- Was this already mailed? --->
		<cfif getPost[1]["Mailed"]>
			<cfset error = true>
			<cfset response[ "aldreadyMailed" ] = true />
		</cfif>

		<!--- Is posted less than now? --->
		<cfif dateCompare(getPost[1]["DatePosted"], application.blog.blogNow()) is 1>
			<cfset error = true>
			<cfset response[ "futurePost" ] = true />
		</cfif>
			
		<!--- Send the email if there are no errors. The byPassErrors can be used to send the email anyway if the post has been revised and should be sent again. --->
		<cfif arguments.byPassErrors or not error>

			<!--- Blog title --->
			<cfset blogTitle = htmlEditFormat(application.BlogDbObj.getBlogTitle())>

			<!--- Get our subscribers. This will return the subscriber email addresses. --->
			<cfinvoke component="#application.blog#" method="getSubscribers" returnVariable="getSubscribers">
				<cfinvokeargument name="verifiedOnly" value="false">
			</cfinvoke>

			<!--- Loop through the subscribers --->
			<cfloop from="1" to="#arrayLen(getSubscribers)#" index="i">

				<cfset email = getSubscribers[i]["SubscriberEmail"]>

				<!--- Get the subscriber details. The getSubscribers function only returns the email address. --->
				<cfset getSubscriberDetail = application.blog.getSubscriber(email=getSubscribers[i]["SubscriberEmail"])>
					
				<!--- The user may not come back if they were deleted (ie set active=false) --->
				<cfif arrayLen(getSubscriberDetail)>
					<!--- Render the email --->
					<cfinvoke component="#RendererObj#" method="renderPostEmailToSubscribers" returnvariable="emailBody">
						<cfinvokeargument name="postId" value="#arguments.postId#">
						<cfinvokeargument name="email" value="#email#">
						<cfinvokeargument name="token" value="#getSubscriberDetail[1]['SubscriberToken']#">
					</cfinvoke>

					<!--- Email it --->
					<cfset utils.mail(
						to=email,
						subject="#blogTitle# / #getPost[1]['Title']#",
						body=emailBody)>
				</cfif><!---<cfif arrayLen(getSubscriberDetail)>--->

			</cfloop><!---<cfloop from="1" to="#arrayLen(subscribers)#" index="i">--->

			<!--- Indicate that the post was mailed. --->
			<cfquery name="Data" dbtype="hql">
				UPDATE Post
				SET Mailed = <cfqueryparam value="1" cfsqltype="bit">
				WHERE PostId = <cfqueryparam value="#arguments.postId#" cfsqltype="integer" maxlength="35">
			</cfquery>
				
			<cfset response[ "sentEmail" ] = true />
				
		</cfif><!---<cfif arguments.byPassErrors or not error>--->
				
		<!--- Return the response --->
		<cfreturn serializeJson(response)>
			
	</cffunction>
				
	<!--- //************************************************************************************************************
			Generic Blog Table functions
	//**************************************************************************************************************--->	
				
	<cffunction name="getDbBlogVersion" access="public" returnType="string" output="false" 
			hint="Retrieves the value in the blog.BlogVesion column">
		
		<!--- Get the current blogId --->
		<cfquery name="getData" dbtype="hql" ormoptions="#{maxresults=1}#">
			SELECT BlogId FROM Blog
		</cfquery>
		
		<!--- Save the record into the table. --->
		<cftransaction>
			
			<cfquery name="getBlogVersion" dbtype="hql">
				SELECT BlogVersion
				FROM Blog
				WHERE BlogId = <cfqueryparam value="1" cfsqltype="integer">
			</cfquery>

		</cftransaction>

		<cfset blogVersion = getBlogVersion[1]>
			
		<cfreturn blogVersion>
			
	</cffunction>
		
	<cffunction name="updateBlogVersion" access="public" returnType="numeric" output="false" 
			hint="Updates the blog version in the Blog table. This is used when updating the database to a new version">
		<cfargument name="blogVersion" type="string" required="true">
		<cfargument name="blogVersionName" type="string" required="true" default="false">
		
		<!--- Get the current blogId --->
		<cfquery name="getData" dbtype="hql" ormoptions="#{maxresults=1}#">
			SELECT BlogId FROM Blog
		</cfquery>
		
		<!--- Save the record into the table. --->
		<cftransaction>
			
			<cfquery name="updateBlogVersion" dbtype="hql">
				UPDATE Blog
				SET BlogVersion = <cfqueryparam value="#arguments.blogVersion#" cfsqltype="varchar">,
				BlogVersionName = <cfqueryparam value="#arguments.blogVersionName#" cfsqltype="varchar">
				WHERE BlogId = <cfqueryparam value="1" cfsqltype="integer">
			</cfquery>

		</cftransaction>

		<cfset blogId = getData[1]>
			
		<cfreturn blogId>
			
	</cffunction>
			
	<!--- //************************************************************************************************************
			Themes
	//**************************************************************************************************************--->
			
	<cffunction name="getThemes" access="public" returnType="array" output="false" 
			hint="Returns a query containing all of the categories as well as their count for a specified blog.">
		<cfargument name="themeName" type="string" required="false" default="">
		<cfargument name="kendoTheme" type="string" required="false" default="">
		<cfargument name="themeGenre" type="string" required="false" default="">
			
		<cfset var Data = []>

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				ThemeId as ThemeId,
				ThemeSettingRef.ThemeSettingId as ThemeSettingId,
				ThemeAlias as ThemeAlias,
				ThemeName as ThemeName,
				KendoThemeRef.KendoThemeId as KendoThemeId,
				KendoThemeRef.KendoTheme as KendoTheme,
				ThemeSettingRef.ContentWidth as ContentWidth,
				ThemeSettingRef.Breakpoint as Breakpoint,
				0 as ModernThemeStyle,
				KendoThemeRef.DarkTheme as DarkTheme,
				UseTheme as UseTheme,
				SelectedTheme as SelectedTheme
			)
			FROM 
				Theme as Theme
			WHERE 0=0
			<cfif arguments.themeName neq ''>
				AND ThemeName LIKE <cfqueryparam value="%#arguments.themeName#%" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.kendoTheme neq ''>
				AND KendoThemeRef.KendoTheme = <cfqueryparam value="#arguments.kendoTheme#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.themeGenre neq ''>
				AND Theme.ThemeGenre = <cfqueryparam value="#arguments.themeGenre#" cfsqltype="cf_sql_varchar">
			</cfif>
			ORDER BY Theme.ThemeName
		</cfquery>
				
		<!--- Loop through the data and set the modern theme style. ORM does not have reliable case statements. --->
		<cfloop from="1" to="#arrayLen(Data)#" index="i">
			<!--- A modern theme has 0 as the breakpoint. --->
			<cfif Data[i]["Breakpoint"] eq 0>
				<cfset Data[i]["ModernThemeStyle"] = 1>
			</cfif>	
		</cfloop>

		<cfreturn Data>
		
	</cffunction>
			
	<cffunction name="getThemeNames" access="public" returntype="array">
		<cfset var Data = []>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				ThemeId as ThemeId,
				ThemeAlias as ThemeAlias,
				ThemeName as ThemeName,
				KendoThemeRef.KendoTheme as KendoTheme
			)
			FROM 
				Theme as Theme
			WHERE 
				UseTheme =  <cfqueryparam value="1" cfsqltype="cf_sql_bit">
			ORDER BY ThemeName
		</cfquery>
		
		<cfreturn Data>
	</cffunction>
			
	<cffunction name="getSelectedThemeAlias" access="public" returnType="string" hint="This will return the ThemeAlias">
		
		<!--- Get the selected theme. --->
		<cfquery name="getSelectedThemeAlias" dbtype="hql">
			SELECT new Map (
				ThemeAlias as ThemeAlias
			)
			FROM 
				Theme as Theme
			WHERE SelectedTheme = <cfqueryparam value="1" cfsqltype="cf_sql_integer">
		</cfquery>
		
		<!--- Is a theme selected? --->
		<cfif arrayLen(getSelectedThemeAlias)>
			<cfset theme = getSelectedThemeAlias[1]["ThemeAlias"]>
		<!--- Is the theme in the URL or cookie? --->
		<cfelseif isDefined("URL.theme")>
			<!--- Drop a cookie to use to store the theme --->
			<cfcookie name="theme" value="#URL.theme#">
			<cfset theme = URL.theme>
		<cfelseif isDefined("cookie.theme")>
			<cfset theme = cookie.theme>
		<cfelse>
			<!--- Get a random theme by the day. --->
			<cfset theme = getThemeAliasByDay()>
		</cfif>

		<!--- Safety check in case something goes wrong. --->
		<cfif theme eq "">
			<cfset theme = "zion">
		</cfif>

		<!--- Return it --->
		<cfreturn theme>
			
	</cffunction>
			
	<cffunction name="getSelectedKendoTheme" access="public" returnType="string" 
			hint="This will return the selected kendo theme, or the default kendo theme by day if one is not selected.">
		
		<!--- Get the selected theme alias. --->
		<cfset themeAlias = this.getSelectedThemeAlias()>
		<!--- Get the theme from the db --->
		<cfset getTheme = application.blog.getTheme(themeAlias=themeAlias)>
		<!--- Now get the Kendo theme --->
		<cfset kendoTheme = getTheme[1]["KendoTheme"]>

		<!--- Return it --->
		<cfreturn kendoTheme>
			
	</cffunction>

	<!--- Since we have a bunch of different themes, we am going to show a different theme each day to keep the site looking fresh and to show off the themes. --->
	<cffunction name="getThemeAliasByDay" access="public" returntype="string" hint="This will return the ThemeAlias">
		<!--- The blogNow() will return the current date minus the offset. --->
		<cfset thisDay = day(application.blog.blogNow())>
		<cfset theme = "">

		<cfif thisDay eq 1 or thisDay eq 14 or thisDay eq 27>
			<cfset theme = "zion"><!---default--->
		<cfelseif thisDay eq 2 or thisDay eq 15 or thisDay eq 28>
			<cfset theme = "pillars-of-creation">
		<cfelseif thisDay eq 3 or thisDay eq 16 or thisDay eq 29>
			<cfset theme = "blue-planet">
		<cfelseif thisDay eq 4 or thisDay eq 17 or thisDay eq 30>
			<cfset theme = "bahama-bank">
		<cfelseif thisDay eq 5 or thisDay eq 18 or thisDay eq 31>		
			<cfset theme = "orion">
		<cfelseif thisDay eq 6 or thisDay eq 19>		
			<cfset theme = "blue-wave">
		<cfelseif thisDay eq 7 or thisDay eq 20>		
			<cfset theme = "blue-wave-dark">
		<cfelseif thisDay eq 8 or thisDay eq 21>		
			<cfset theme = "grand-teton">
		<cfelseif thisDay eq 9 or thisDay eq 22>		
			<cfset theme = "yellowstone">
		<cfelseif thisDay eq 10 or thisDay eq 23>		
			<cfset theme = "mukilteo">
		<cfelseif thisDay eq 11 or thisDay eq 24>		
			<cfset theme = "abstract-blue">
		<cfelseif thisDay eq 12 or thisDay eq 25>		
			<cfset theme = "cobalt">
		<cfelseif thisDay eq 13 or thisDay eq 26>		
			<cfset theme = "sunrise">
		</cfif>
		<cfreturn theme>
	</cffunction>
			
	<cffunction name="getKendoThemeByTheme" access="public" returnType="string">
		<cfargument name="themeAlias" type="string" required="false" default="">
			<!--- See if the user has selected a theme from the database. --->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					KendoThemeRef.KendoTheme as KendoTheme
				)
				FROM 
					Theme as Theme
				WHERE ThemeAlias = <cfqueryparam value="#arguments.themeAlias#" cfsqltype="cf_sql_varchar">
			</cfquery>

		<!---Return it--->
		<cfreturn Data[1]["KendoTheme"]>
			
	</cffunction>
			
	<cffunction name="getTheme" access="public" returntype="array" output="true" hint="Returns theme data by the theme id, theme name, or the kendo theme">
		<cfargument name="themeId" type="string" required="false" default="">
		<cfargument name="themeAlias" type="string" required="false" default="">
		<cfset var Data = []> 
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				ThemeId as ThemeId,
				ThemeName as Theme,
				ThemeGenre as ThemeGenre,
				UseTheme as UseTheme,
				SelectedTheme as SelectedTheme,
				KendoThemeRef.KendoThemeId as KendoThemeId,
				KendoThemeRef.KendoTheme as KendoTheme,
				KendoThemeRef.KendoCommonCssFileLocation as KendoCommonCssFileLocation,
				KendoThemeRef.KendoThemeCssFileLocation as KendoThemeCssFileLocation,
				KendoThemeRef.KendoThemeMobileCssFileLocation as KendoThemeMobileCssFileLocation,
				KendoThemeRef.DarkTheme as DarkTheme,
				ThemeSettingRef.ThemeSettingId as ThemeSettingId,
				ThemeSettingRef.Breakpoint as Breakpoint,
				0 as ModernThemeStyle,
				ThemeSettingRef.FontRef.FontId as FontId,
				ThemeSettingRef.FontRef.Font as Font,
				ThemeSettingRef.FontRef.FontType as FontType,
				ThemeSettingRef.FontSize as FontSize,
				ThemeSettingRef.FontSizeMobile as FontSizeMobile,
				ThemeSettingRef.ContentWidth as ContentWidth,
				ThemeSettingRef.MainContainerWidth as MainContainerWidth,
				ThemeSettingRef.SideBarContainerWidth as SideBarContainerWidth,
				ThemeSettingRef.SiteOpacity as SiteOpacity,
				ThemeSettingRef.WebPImagesIncluded as WebPImagesIncluded,
				ThemeSettingRef.FavIconHtml as FavIconHtml,
				ThemeSettingRef.IncludeBackgroundImages as IncludeBackgroundImages,
				ThemeSettingRef.BlogBackgroundImage as BlogBackgroundImage,
				ThemeSettingRef.BlogBackgroundImageMobile as BlogBackgroundImageMobile,
				ThemeSettingRef.BlogBackgroundImageRepeat as BlogBackgroundImageRepeat,
				ThemeSettingRef.BlogBackgroundImagePosition as BlogBackgroundImagePosition,
				ThemeSettingRef.BlogBackgroundColor as BlogBackgroundColor,
				<!---Fix ThemeSettingRef.HeaderBackgroundColor as HeaderBackgroundColor,--->
				'' as HeaderBackgroundColor,
				ThemeSettingRef.HeaderBackgroundImage as HeaderBackgroundImage,
				ThemeSettingRef.HeaderBodyDividerImage as HeaderBodyDividerImage,
				ThemeSettingRef.StretchHeaderAcrossPage as StretchHeaderAcrossPage,
				ThemeSettingRef.AlignBlogMenuWithBlogContent as AlignBlogMenuWithBlogContent,
				ThemeSettingRef.TopMenuAlign as TopMenuAlign,
				ThemeSettingRef.MenuFontRef as MenuFontId,
				'' as MenuFont,
				'' as MenuFontType,
				ThemeSettingRef.MenuBackgroundImage as MenuBackgroundImage,
				ThemeSettingRef.CoverKendoMenuWithMenuBackgroundImage as CoverKendoMenuWithMenuBackgroundImage,
				ThemeSettingRef.LogoImageMobile as LogoImageMobile,
				ThemeSettingRef.LogoMobileWidth as LogoMobileWidth,
				ThemeSettingRef.LogoImage as LogoImage,
				ThemeSettingRef.LogoPaddingTop as LogoPaddingTop,
				ThemeSettingRef.LogoPaddingRight as LogoPaddingRight,
				ThemeSettingRef.LogoPaddingLeft as LogoPaddingLeft,
				ThemeSettingRef.LogoPaddingBottom as LogoPaddingBottom,
				ThemeSettingRef.DefaultLogoImageForSocialMediaShare as DefaultLogoImageForSocialMediaShare,
				ThemeSettingRef.BlogNameFontRef as BlogNameFontId,
				'' as BlogNameFont,
				'' as BlogNameFontType,
				ThemeSettingRef.DisplayBlogName as DisplayBlogName,
				ThemeSettingRef.BlogNameTextColor as BlogNameTextColor,
				ThemeSettingRef.BlogNameFontSize as BlogNameFontSize,
				ThemeSettingRef.BlogNameFontSizeMobile as BlogNameFontSizeMobile,
				ThemeSettingRef.FooterImage as FooterImage
			)
			FROM 
				Theme as Theme
			WHERE 0 = 0
		<cfif arguments.themeId neq ''>
			AND Theme.ThemeId = #arguments.themeId#
		<cfelseif arguments.themeAlias neq ''>
			AND Theme.ThemeAlias = <cfqueryparam value="#arguments.themeAlias#" cfsqltype="cf_sql_varchar">
		</cfif>
		</cfquery>
			
		<!--- Error handling. Use the delicate arch theme if there is no data --->
		<cfif not arrayLen(Data)>
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					ThemeId as ThemeId,
					ThemeName as Theme,
					ThemeGenre as ThemeGenre,
					UseTheme as UseTheme,
					SelectedTheme as SelectedTheme,
					KendoThemeRef.KendoThemeId as KendoThemeId,
					KendoThemeRef.KendoTheme as KendoTheme,
					KendoThemeRef.KendoCommonCssFileLocation as KendoCommonCssFileLocation,
					KendoThemeRef.KendoThemeCssFileLocation as KendoThemeCssFileLocation,
					KendoThemeRef.KendoThemeMobileCssFileLocation as KendoThemeMobileCssFileLocation,
					KendoThemeRef.DarkTheme as DarkTheme,
					ThemeSettingRef.ThemeSettingId as ThemeSettingId,
					ThemeSettingRef.Breakpoint as Breakpoint,
					0 as ModernThemeStyle,
					ThemeSettingRef.FontRef.FontId as FontId,
					ThemeSettingRef.FontRef.Font as Font,
					ThemeSettingRef.FontRef.FontType as FontType,
					ThemeSettingRef.FontSize as FontSize,
					ThemeSettingRef.FontSizeMobile as FontSizeMobile,
					ThemeSettingRef.ContentWidth as ContentWidth,
					ThemeSettingRef.MainContainerWidth as MainContainerWidth,
					ThemeSettingRef.SideBarContainerWidth as SideBarContainerWidth,
					ThemeSettingRef.SiteOpacity as SiteOpacity,
					ThemeSettingRef.WebPImagesIncluded as WebPImagesIncluded,
					ThemeSettingRef.FavIconHtml as FavIconHtml,
					ThemeSettingRef.IncludeBackgroundImages as IncludeBackgroundImages,
					ThemeSettingRef.BlogBackgroundImage as BlogBackgroundImage,
					ThemeSettingRef.BlogBackgroundImageMobile as BlogBackgroundImageMobile,
					ThemeSettingRef.BlogBackgroundImageRepeat as BlogBackgroundImageRepeat,
					ThemeSettingRef.BlogBackgroundImagePosition as BlogBackgroundImagePosition,
					ThemeSettingRef.BlogBackgroundColor as BlogBackgroundColor,
					<!---Fix ThemeSettingRef.HeaderBackgroundColor as HeaderBackgroundColor,--->
					'' as HeaderBackgroundColor,
					ThemeSettingRef.HeaderBackgroundImage as HeaderBackgroundImage,
					ThemeSettingRef.HeaderBodyDividerImage as HeaderBodyDividerImage,
					ThemeSettingRef.StretchHeaderAcrossPage as StretchHeaderAcrossPage,
					ThemeSettingRef.AlignBlogMenuWithBlogContent as AlignBlogMenuWithBlogContent,
					ThemeSettingRef.TopMenuAlign as TopMenuAlign,
					ThemeSettingRef.MenuFontRef as MenuFontId,
					'' as MenuFont,
					'' as MenuFontType,
					ThemeSettingRef.MenuBackgroundImage as MenuBackgroundImage,
					ThemeSettingRef.CoverKendoMenuWithMenuBackgroundImage as CoverKendoMenuWithMenuBackgroundImage,
					ThemeSettingRef.LogoImageMobile as LogoImageMobile,
					ThemeSettingRef.LogoMobileWidth as LogoMobileWidth,
					ThemeSettingRef.LogoImage as LogoImage,
					ThemeSettingRef.LogoPaddingTop as LogoPaddingTop,
					ThemeSettingRef.LogoPaddingRight as LogoPaddingRight,
					ThemeSettingRef.LogoPaddingLeft as LogoPaddingLeft,
					ThemeSettingRef.LogoPaddingBottom as LogoPaddingBottom,
					ThemeSettingRef.DefaultLogoImageForSocialMediaShare as DefaultLogoImageForSocialMediaShare,
					ThemeSettingRef.BlogNameFontRef as BlogNameFontId,
					'' as BlogNameFont,
					'' as BlogNameFontType,
					ThemeSettingRef.DisplayBlogName as DisplayBlogName,
					ThemeSettingRef.BlogNameTextColor as BlogNameTextColor,
					ThemeSettingRef.BlogNameFontSize as BlogNameFontSize,
					ThemeSettingRef.BlogNameFontSizeMobile as BlogNameFontSizeMobile,
					ThemeSettingRef.FooterImage as FooterImage
				)
				FROM 
					Theme as Theme
				WHERE 0 = 0
				AND Theme.ThemeId = 11
			</cfquery>
			
		</cfif>
			
		<!--- We need to extract font information for the blog name and menu fonts. Only do this if there are theme records. --->
		<cfif arrayLen(Data)>
			
			<cfset getMenuFont = application.blog.getFont(fontId=Data[1]["MenuFontId"])>
			<cfif arrayLen(getMenuFont)>
				<!--- Set the value --->
				<cfset Data[1]["MenuFont"] = getMenuFont[1]["Font"]>
				<cfset Data[1]["MenuFontType"] = getMenuFont[1]["FontType"]>
			<cfelse>
				<cfset Data[1]["MenuFont"] = ''>
				<cfset Data[1]["MenuFontType"] = ''>
			</cfif>

			<cfset getBlogNameFont = application.blog.getFont(fontId=Data[1]["BlogNameFontId"])>
			<cfif arrayLen(getBlogNameFont)>
				<!--- Set the value --->
				<cfset Data[1]["BlogNameFont"] = getBlogNameFont[1]["Font"]>
				<cfset Data[1]["BlogNameFontType"] = getBlogNameFont[1]["FontType"]>
			<cfelse>
				<cfset Data[1]["BlogNameFont"] = ''>
				<cfset Data[1]["BlogNameFontType"] = ''>
			</cfif>
		</cfif>
				
		<!--- Loop through the data and set the modern theme style. ORM does not have reliable case statements. --->
		<cfloop from="1" to="#arrayLen(Data)#" index="i">
			<!--- A modern theme has 0 as the breakpoint. --->
			<cfif Data[i]["Breakpoint"] eq 0>
				<cfset Data[i]["ModernThemeStyle"] = 1>
			</cfif>	
		</cfloop>
				
		<cfreturn Data>
			
	</cffunction>
				
	<cffunction name="getThemeList" access="public" returntype="string" output="false" 
			hint="Returns a list of themes. Used to validate if the theme is unique when creating a new theme.">
		<cfparam name="themeList" default="">
		<cfset var Data = []> 
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				ThemeName as Theme
			)
			FROM 
				Theme as Theme
			ORDER BY ThemeName
		</cfquery>
		<!--- Loop through the data and build the list --->
		<cfif arrayLen(Data)>
			<!--- Loop through the array and set the subscribe flag to false.--->
			<cfloop from="1" to="#arrayLen(Data)#" index="i">
				<cfset themeList = listAppend(themeList, Data[i]["Theme"])>
			</cfloop>
		</cfif>
			
		<cfreturn themeList>
			
	</cffunction>
			
	<cffunction name="getKendoThemes" access="public" returntype="array" output="false" hint="Returns the kendo themes">
		<cfargument name="kendoThemeId" type="string" required="false" default="">
		<cfargument name="kendoTheme" type="string" required="false" default="">
		<cfset var Data = []> 
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				KendoThemeId as KendoThemeId,
				KendoTheme.KendoTheme as KendoTheme,
				KendoCommonCssFileLocation as KendoCommonCssFileLocation,
				KendoThemeCssFileLocation as KendoThemeCssFileLocation,
				KendoThemeMobileCssFileLocation as KendoThemeMobileCssFileLocation,
				DarkTheme as DarkTheme
			)
			FROM 
				KendoTheme as KendoTheme
			<!--- Don't get metroblack --->
			WHERE KendoThemeId < 15
		<!--- Validate the kendo theme Id to prevent injection. We cant use binding here due to a CF ORM issue with entity keys. --->
		<cfif arguments.kendoThemeId neq '' and isNumeric(arguments.kendoThemeId) and len(arguments.kendoThemeId) lt 5>
			AND KendoTheme.KendoThemeId = #arguments.kendoThemeId#
		<cfelseif arguments.kendoTheme neq ''>
			AND KendoTheme.KendoTheme = <cfqueryparam value="#arguments.kendoTheme#" cfsqltype="cf_sql_varchar">
		</cfif>
			ORDER BY KendoTheme.KendoTheme
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="getLogoPathByTheme" access="public" returntype="string" output="false" 
			hint="Returns the path of the logo. This is used for branding purposes, such as placing the logo in our correspondence.">
		<cfargument name="themeId" type="string"  default="" required="false" hint="Either the themeId, theme, or kendoTheme is required">
		<cfargument name="themeName" type="string" required="false" default="">
			
		<!--- First we need to get the theme if it has not been passed --->
		<cfif  arguments.themeId eq '' and arguments.themeName eq ''>
			<cfset themeAlias = application.blog.getSelectedThemeAlias()>
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				ThemeSettingRef.LogoImage as LogoImage
			)
			FROM 
				Theme as Theme
			WHERE 0 = 0
		<cfif arguments.themeId neq ''>
			AND Theme.ThemeId = <cfqueryparam value="#arguments.themeId#">
		<cfelseif arguments.themeName neq ''>
			AND Theme.ThemeName = <cfqueryparam value="#arguments.themeName#" cfsqltype="cf_sql_varchar">
		<cfelse>
			AND Theme.ThemeAlias = <cfqueryparam value="#themeAlias#" cfsqltype="cf_sql_varchar">
		</cfif>
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset logoImage = Data[1]["LogoImage"]>
		<cfelse>
			<cfset logoImage = "">
		</cfif>
		<cfreturn logoImage>
			
	</cffunction>
			
	<cffunction name="getPrimaryColorsByTheme">
		<cfargument name="kendoTheme"  required="true" hint="Pass in the Kendo theme name."/>
		<cfargument name="setting"  required="true" hint="What setting name do you want to see?"/>
		<cfswitch expression="#kendoTheme#">
			<cfcase value="black">
				<cfset buttonAccentColor = "db4240">
				<cfset accentColor = "0066cc">
				<cfset baseColor = "292525">
				<cfset headerBgColor = "292525">
				<cfset headerTextColor = "fff">
				<cfset hoverBgColor = "3d3d3d">
				<cfset hoverBorderColor = "4d4d4d">
				<cfset textColor = "ffffff">
				<cfset selectedTextColor = "ffffff">
				<cfset contentBgColor = "4d4d4d">
				<cfset contentBorderColor = "000">
				<cfset alternateBgColor = "555">
				<cfset error = "db4240">
				<cfset warning = "ffc000">
				<cfset success = "2b893c">
				<cfset info = "0066cc">
			</cfcase>
			<cfcase value="blueOpal">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "326891">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "E3EFF7">
				<cfset headerTextColor = "000">
				<cfset hoverBgColor = "A1D6F7">
				<cfset hoverBorderColor = "3d3d3d">
				<cfset textColor = "000">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "a3d0e4">
				<cfset alternateBgColor = "e6f2f8">
				<cfset error = "db4240">
				<cfset warning = "ffb400">
				<cfset success = "37b400">
				<cfset info = "0066cc">
			</cfcase>
			<cfcase value="bootstrap">
				<cfset buttonAccentColor = "428bca">
				<cfset accentColor = "428bca">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "f5f5f5">
				<cfset headerTextColor = "333333">
				<cfset hoverBgColor = "ebebeb">
				<cfset hoverBorderColor = "333333">
				<cfset textColor = "333333">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "dfdfdf">
				<cfset alternateBgColor = "f5f5f5">
				<cfset error = "ffe0d9">
				<cfset warning = "fbeed5">
				<cfset success = "eaf7ec">
				<cfset info = "e5f5fa">
			</cfcase>
			<cfcase value="default">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "f35800">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "eae8e8">
				<cfset headerTextColor = "000">
				<cfset hoverBgColor = "bcb4b0">
				<cfset hoverBorderColor = "3d3d3d">
				<cfset textColor = "000">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "d5d5d5">
				<cfset alternateBgColor = "f1f1f1">
				<cfset error = "db4240">
				<cfset warning = "ffc000">
				<cfset success = "37b400">
				<cfset info = "0066cc">
			</cfcase>
			<cfcase value="flat">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "10c4b2">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "363940">
				<cfset headerTextColor = "fff">
				<cfset hoverBgColor = "2eb3a6">
				<cfset hoverBorderColor = "3d3d3d">
				<cfset textColor = "000">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "fff">
				<cfset alternateBgColor = "f5f5f5">
				<cfset error = "ffdfd7">
				<cfset warning = "fff4d7">
				<cfset success = "eefbf0">
				<cfset info = "e6f9ff">
			</cfcase>
			<cfcase value="highContrast">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "870074">
				<cfset baseColor = "2B232B">
				<cfset headerBgColor = "2c232b">
				<cfset headerTextColor = "fff">
				<cfset hoverBgColor = "a7008f">
				<cfset hoverBorderColor = "3d3d3d">
				<cfset textColor = "ffffff">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "2c232b">
				<cfset contentBorderColor = "674c63">
				<cfset alternateBgColor = "2c232b">
				<cfset error = "be5138">
				<cfset warning = "e9a71d">
				<cfset success = "2b893c">
				<cfset info = "007da7">
			</cfcase>
			<cfcase value="material">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "5e6cbf">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "fafafa">
				<cfset headerTextColor = "000">
				<cfset hoverBgColor = "ebebeb">
				<cfset hoverBorderColor = "3d3d3d">
				<cfset textColor = "000">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "e6e6e6">
				<cfset alternateBgColor = "F2F2F1">
				<cfset error = "ffcdd2">
				<cfset warning = "fdefba">
				<cfset success = "c8e6c9">
				<cfset info = "bbdefb">
			</cfcase>
			<cfcase value="materialBlack">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "3f51b5">
				<cfset baseColor = "363636">
				<cfset headerBgColor = "5a5a5a">
				<cfset headerTextColor = "fff">
				<cfset hoverBgColor = "606060">
				<cfset hoverBorderColor = "3d3d3d">
				<cfset textColor = "fff">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "363636">
				<cfset contentBorderColor = "4d4d4d">
				<cfset alternateBgColor = "5a5a5a">
				<cfset error = "c93b31">
				<cfset warning = "cdaa1d">
				<cfset success = "429246">
				<cfset info = "207ec8">
			</cfcase>
			<cfcase value="metro">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "7ea700">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "fff">
				<cfset headerTextColor = "000">
				<cfset hoverBgColor = "8ebc00">
				<cfset hoverBorderColor = "3d3d3d">
				<cfset textColor = "000">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "dbdbdb">
				<cfset alternateBgColor = "f5f5f5">
				<cfset error = "ffb8a9">
				<cfset warning = "ffe44d">
				<cfset success = "ddffd0">
				<cfset info = "d0f8ff">
			</cfcase>
			<cfcase value="moonlight">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "f4af03">
				<cfset baseColor = "424550">
				<cfset headerBgColor = "1f2a35">
				<cfset headerTextColor = "fff">
				<cfset hoverBgColor = "62656F">
				<cfset hoverBorderColor = "3d3d3d">
				<cfset textColor = "fff">
				<cfset selectedTextColor = "000">
				<cfset contentBgColor = "484c58">
				<cfset contentBorderColor = "232d36">
				<cfset alternateBgColor = "484c58">
				<cfset error = "be5138">
				<cfset warning = "ea9d07">
				<cfset success = "2b893c">
				<cfset info = "0c779b">
			</cfcase>
			<cfcase value="nova">
				<cfset buttonAccentColor = "e51a5f">
				<cfset accentColor = "ff5763">
				<cfset baseColor = "fafafa">
				<cfset headerBgColor = "fafafa">
				<cfset headerTextColor = "000">
				<cfset hoverBgColor = "f5f6f6">
				<cfset hoverBorderColor = "FAFAFA">
				<cfset textColor = "000">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "FAFAFA">
				<cfset alternateBgColor = "fafafa">
				<cfset error = "ffbfc4">
				<cfset warning = "ffecc7">
				<cfset success = "a5d6a7">
				<cfset info = "80deea">
			</cfcase>
			<cfcase value="office365">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "005b9d">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "fff">
				<cfset headerTextColor = "000">
				<cfset hoverBgColor = "f4f4f4">
				<cfset hoverBorderColor = "c9c9c9">
				<cfset textColor = "000">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "ffff0">
				<cfset alternateBgColor = "fff">
				<cfset error = "fccbc7">
				<cfset warning = "fff19d">
				<cfset success = "cbe9cc">
				<cfset info = "bbd9f7">
			</cfcase>
			<cfcase value="silver">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "1984c8">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "f3f3f4">
				<cfset headerTextColor = "000">
				<cfset hoverBgColor = "b6bdca">
				<cfset hoverBorderColor = "F6F6F6">
				<cfset textColor = "000">
				<cfset selectedTextColor = "fff">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "dedee0">
				<cfset alternateBgColor = "fbfbfb">
				<cfset error = "d92800">
				<cfset warning = "ff9800">
				<cfset success = "3ea44e">
				<cfset info = "2498bc">
			</cfcase>
			<cfcase value="uniform">
				<cfset buttonAccentColor = "0066cc">
				<cfset accentColor = "747474">
				<cfset baseColor = "fff">
				<cfset headerBgColor = "f5f5f5">
				<cfset headerTextColor = "000">
				<cfset hoverBgColor = "F6F6F6">
				<cfset hoverBorderColor = "F6F6F6">
				<cfset textColor = "000">
				<cfset selectedTextColor = "FFF">
				<cfset contentBgColor = "fff">
				<cfset contentBorderColor = "dedee0">
				<cfset alternateBgColor = "f5f5f5">
				<cfset error = "d92800">
				<cfset warning = "ff9800">
				<cfset success = "3ea44e">
				<cfset info = "2498bc">
			</cfcase>
		</cfswitch>
		<!--- Return the setting that was requested --->
		<cfreturn evaluate("#arguments.setting#")>
	</cffunction>
					
	<cffunction name="saveTheme" access="public" returntype="string" output="false" 
			hint="Updates the theme database">
		<cfargument name="themeId" type="string"  default="" required="false" hint="Either the themeId, theme, or kendoTheme is required">
		<cfargument name="kendoThemeId" type="string" required="false" default="" >
		<cfargument name="theme" type="string" required="false" default="">
		<!--- The following 3 args are checkboxes --->
		<cfargument name="useTheme" type="string" required="false" default="">
		<cfargument name="selectedTheme" type="string" required="false" default="">
		<cfargument name="darkTheme" type="string" required="false" default="">
		<!--- Kendo Theme settings --->
		<cfargument name="kendoCommonCssFileLocation" type="string" required="false" default="">
		<cfargument name="kendoThemeCssFileLocation" type="string" required="false" default="">
		<cfargument name="kendoThemeMobileCssFileLocation" type="string" required="false" default="">
		<!--- Fonts --->
		<cfargument name="fontId" type="string" required="false" default="">
		<cfargument name="menuFontId" type="string" required="false" default="">
		<cfargument name="blogNameFontId" type="string" required="false" default="">
		<!--- Container dimensions --->
		<cfargument name="contentWidth" type="string" required="false" default="">
		<cfargument name="mainContainerWidth" type="string" required="false" default="">
		<cfargument name="sideBarContainerWidth" type="string" required="false" default="">
		<!--- Backgrounds --->
		<cfargument name="includeBackgroundImages" type="string" required="false" default="">
		<cfargument name="blogBackgroundImage" type="string" required="false" default="">
		<cfargument name="blogBackgroundImageMobile" type="string" required="false" default="">
		<cfargument name="blogBackgroundImageRepeat" type="string" required="false" default="">
		<cfargument name="blogBackgroundImagePosition" type="string" required="false" default="">
		<cfargument name="siteOpacity" type="string" required="false" default="">
		<!--- Header --->
		<cfargument name="stretchHeaderAcrossPage" type="string" required="false" default="">
		<cfargument name="headerBackgroundImage" type="string" required="false" default="">
		<cfargument name="headerBodyDividerImage" type="string" required="false" default="">
		<!--- Title ---> 
		<cfargument name="blogNameTextColor" type="string" required="false" default="">
		<cfargument name="blogNameFontSize" type="string" required="false" default="">
		<cfargument name="blogNameFontSizeMobile" type="string" required="false" default="">
		<!--- Menu --->
		<cfargument name="alignBlogMenuWithBlogContent" type="string" required="false" default="">
		<cfargument name="topMenuAlign" type="string" required="false" default="">
		<cfargument name="menuBackgroundImage" type="string" required="false" default="">
		<cfargument name="coverKendoMenuWithMenuBackgroundImage" type="string" required="false" default="">
		<!--- Responsive breakpoint --->
		<cfargument name="breakpoint" type="string" required="false" default="">
		<!--- Logos --->
		<cfargument name="logoImage" type="string" required="false" default="">
		<cfargument name="logoImageMobile" type="string" required="false" default="">
		<cfargument name="logoMobileWidth" type="string" required="false" default="">
		<cfargument name="logoPaddingTop" type="string" required="false" default="">
		<cfargument name="logoPaddingRight" type="string" required="false" default="">
		<cfargument name="logoPaddingLeft" type="string" required="false" default="">
		<cfargument name="logoPaddingBottom" type="string" required="false" default="">
		<cfargument name="defaultLogoImageForSocialMediaShare" type="string" required="false" default="">
		<!--- Footer --->
		<cfargument name="footerImage" type="string" required="false" default="">
		
		<cftransaction>
			
			<!--- First, if a theme was selected, deselect any other selected themes. There can only be on selected theme. --->
			<cfif len(arguments.selectedTheme)>
				<cfquery name="selectNoTheme" dbtype="hql">
					UPDATE Theme
					SET SelectedTheme = ''
					WHERE SelectedTheme = 1
				</cfquery>
			</cfif>
			
			<!---Updating current theme records --->
			<cfif len(arguments.themeId)>
				<!--- Load the theme entity --->
				<cfset ThemeDbObj = entityLoadByPK("Theme", arguments.themeId)>
				<!--- Load the Kendo Theme entity ---> 
				<cfif len(arguments.kendoThemeId)>
					<!--- Change the Kendo theme ref column if the kendoThemeId was send in --->
					<cfset ThemeDbObj.setKendoThemeRef = arguments.kendoThemeId>					
				</cfif>
				<!--- And load the KendoTheme entity. Note: the getKendoThemeRef() will retrive the KendoTheme object, and the getKendoThemeId() is a method in this object to get its Id. --->
				<cfset KendoThemeDbObj = entityLoadByPK("KendoTheme", ThemeDbObj.getKendoThemeRef().getKendoThemeId())>
				<!--- The ThemeSetting entity has a one to one relationship with the Theme table. Note: the getThemeSettingRef() will get the ThemeSettingObject, and the getThemeSettingId() will retrieve the ThemeSettingId. --->
				<cfset ThemeSettingDbObj = entityLoadByPK("ThemeSetting", ThemeDbObj.getThemeSettingRef().getThemeSettingId())>
					
			<!--- Create a new theme from an existing theme.--->
			<cfelse>
				
				<!--- Create a new theme entity --->
				<cfset ThemeDbObj = entityNew("Theme")>
				<!--- Load the Kendo theme entity --->
				<cfset KendoThemeDbObj = entityLoadByPK("KendoTheme", arguments.kendoThemeId)>
				<!--- Set the Kendo theme ref in the Theme table --->
				<cfset ThemeDbObj.setKendoThemeRef(KendoThemeDbObj)>
				<!--- Create a new theme setting entity. The ThemeSetting entity has a one to one relationship with the Theme table. --->
				<cfset ThemeSettingDbObj = entityNew("ThemeSetting")>
				<!--- Set the theme setting reference in the Theme table --->
				<cfset ThemeDbObj.setThemeSettingRef(ThemeSettingDbObj)>
				<!--- And finally, load the blog entity. This is not functional at the moment to have several blogs on a site, but the logic is in the database. --->
				<cfset BlogDbObj = entityLoadByPk("Blog", 1)>
				<!--- Set the blog ref the Theme table --->
				<cfset ThemeDbObj.setBlogRef(BlogDbObj)>
					
			</cfif>

			<!--- Set the data --->
			<cfif len(arguments.theme)>
				<cfset ThemeDbObj.setThemeName(arguments.theme)>
				<cfset ThemeDbObj.setThemeAlias(makeAlias(arguments.theme))>
			</cfif>
			<!--- Theme table properties --->
			<cfif len(arguments.useTheme)>
				<cfset ThemeDbObj.setUseTheme(true)>
			</cfif>
			<cfif len(arguments.selectedTheme)>
				<!--- Select the theme. --->
				<cfset ThemeDbObj.setSelectedTheme(true)>
			</cfif>
			<cfset ThemeDbObj.setDate(blogNow())>
			<!--- Kendo Theme settings --->
			<cfif len(arguments.kendoCommonCssFileLocation)>
				<cfset KendoThemeDbObj.setKendoCommonCssFileLocation(arguments.kendoCommonCssFileLocation)>
			</cfif>
			<cfif len(arguments.kendoThemeCssFileLocation)>
				<cfset KendoThemeDbObj.setKendoThemeCssFileLocation(arguments.kendoThemeCssFileLocation)>
			</cfif>
			<cfif len(arguments.kendoThemeMobileCssFileLocation)>
				<cfset KendoThemeDbObj.setKendoThemeMobileCssFileLocation(arguments.kendoThemeMobileCssFileLocation)>
			</cfif>
			<cfif len(arguments.darkTheme)>
				<cfset KendoThemeDbObj.setDarkTheme(arguments.darkTheme)>
			</cfif>
			<!--- Responsive breakpoint --->
			<cfif len(arguments.breakpoint)>
				<cfset ThemeSettingDbObj.setBreakpoint(arguments.breakpoint)>
			</cfif>
			<!--- Fonts --->
			<cfif len(arguments.fontId)>
				<!--- Load the font entity. This only needs to be done for the fontId. The other font properties (menuFontId and blogNameFontId) do not need the objects loaded. --->
				<cfset FontDbObj = entityLoadByPk("Font", arguments.fontId)>
				<cfset ThemeSettingDbObj.setFontRef(FontDbObj)>
			</cfif>
			<cfif len(arguments.menuFontId)>
				<cfset ThemeSettingDbObj.setMenuFontRef(arguments.menuFontId)>
			</cfif>
			<cfif len(arguments.blogNameFontId)>
				<cfset ThemeSettingDbObj.setBlogNameFontRef(arguments.blogNameFontId)>
			</cfif>
			<!--- Container dimensions --->
			<cfif len(arguments.contentWidth)>
				<cfset ThemeSettingDbObj.setContentWidth(arguments.contentWidth)>
			</cfif>
			<cfif len(arguments.mainContainerWidth)>
				<cfset ThemeSettingDbObj.setMainContainerWidth(arguments.mainContainerWidth)>
			</cfif>
			<cfif len(arguments.sideBarContainerWidth)>
				<cfset ThemeSettingDbObj.setSideBarContainerWidth(arguments.sideBarContainerWidth)>
			</cfif>
			<!--- Backgrounds --->
			<cfif len(arguments.includeBackgroundImages)>
				<cfset ThemeSettingDbObj.setIncludeBackgroundImages(arguments.includeBackgroundImages)>
			</cfif>
			<cfif len(arguments.blogBackgroundImage)>
				<cfset ThemeSettingDbObj.setBlogBackgroundImage(arguments.blogBackgroundImage)>
			</cfif>
			<cfif len(arguments.blogBackgroundImageMobile)>
				<cfset ThemeSettingDbObj.setBlogBackgroundImageMobile(arguments.blogBackgroundImageMobile)>
			</cfif>
			<cfif len(arguments.blogBackgroundImageRepeat)>
				<cfset ThemeSettingDbObj.setBlogBackgroundImageRepeat(arguments.blogBackgroundImageRepeat)>
			</cfif>
			<cfif len(arguments.blogBackgroundImagePosition)>
				<cfset ThemeSettingDbObj.setBlogBackgroundImagePosition(arguments.blogBackgroundImagePosition)>
			</cfif>
			<cfif len(arguments.siteOpacity)>
				<cfset ThemeSettingDbObj.setSiteOpacity(arguments.siteOpacity)>
			</cfif>
			<!--- Header --->
			<cfif len(arguments.stretchHeaderAcrossPage)>
				<cfset ThemeSettingDbObj.setStretchHeaderAcrossPage(arguments.stretchHeaderAcrossPage)>
			</cfif>
			<cfif len(arguments.headerBackgroundImage)>
				<cfset ThemeSettingDbObj.setHeaderBackgroundImage(arguments.headerBackgroundImage)>
			</cfif>
			<cfif len(arguments.headerBodyDividerImage)>
				<cfset ThemeSettingDbObj.setHeaderBodyDividerImage(arguments.headerBodyDividerImage)>
			</cfif>
			<!--- Title --->
			<cfif len(arguments.blogNameTextColor)>
				<cfset ThemeSettingDbObj.setBlogNameTextColor(arguments.blogNameTextColor)>
			</cfif>
			<cfif len(arguments.blogNameFontSize)>
				<cfset ThemeSettingDbObj.setBlogNameFontSize(arguments.blogNameFontSize)>
			</cfif>
			<cfif len(arguments.blogNameFontSizeMobile)>
				<cfset ThemeSettingDbObj.setBlogNameFontSizeMobile(arguments.blogNameFontSizeMobile)>
			</cfif>
			<!--- Menu --->
			<cfif len(arguments.alignBlogMenuWithBlogContent)>
				<cfset ThemeSettingDbObj.setAlignBlogMenuWithBlogContent(arguments.alignBlogMenuWithBlogContent)>
			</cfif>
			<cfif len(arguments.topMenuAlign)>
				<cfset ThemeSettingDbObj.setTopMenuAlign(arguments.topMenuAlign)>
			</cfif>
			<cfif len(arguments.menuBackgroundImage)>
				<cfset ThemeSettingDbObj.setMenuBackgroundImage(arguments.menuBackgroundImage)>
			</cfif>
			<cfif len(arguments.coverKendoMenuWithMenuBackgroundImage)>
				<cfset ThemeSettingDbObj.setCoverKendoMenuWithMenuBackgroundImage(arguments.coverKendoMenuWithMenuBackgroundImage)>
			</cfif>
			<!--- Logos --->
			<cfif len(arguments.logoImage)>
				<cfset ThemeSettingDbObj.setLogoImage(arguments.logoImage)>
			</cfif>
			<cfif len(arguments.logoImageMobile)>
				<cfset ThemeSettingDbObj.setLogoImageMobile(arguments.logoImageMobile)>
			</cfif>
			<cfif len(arguments.logoMobileWidth)>
				<cfset ThemeSettingDbObj.setLogoMobileWidth(arguments.logoMobileWidth)>
			</cfif>
			<cfif len(arguments.logoPaddingTop)>
				<cfset ThemeSettingDbObj.setLogoPaddingTop(arguments.logoPaddingTop)>
			</cfif>
			<cfif len(arguments.logoPaddingRight)>
				<cfset ThemeSettingDbObj.setLogoPaddingRight(arguments.logoPaddingRight)>
			</cfif>
			<cfif len(arguments.logoPaddingLeft)>
				<cfset ThemeSettingDbObj.setLogoPaddingLeft(arguments.logoPaddingLeft)>
			</cfif>
			<cfif len(arguments.logoPaddingBottom)>
				<cfset ThemeSettingDbObj.setLogoPaddingBottom(arguments.logoPaddingBottom)>
			</cfif>
			<cfif len(arguments.defaultLogoImageForSocialMediaShare)>
				<cfset ThemeSettingDbObj.setDefaultLogoImageForSocialMediaShare(arguments.defaultLogoImageForSocialMediaShare)>
			</cfif>
			<!--- Footer Image --->
			<cfif len(arguments.footerImage)>
				<cfset ThemeSettingDbObj.setFooterImage(arguments.footerImage)>
			</cfif>
			<cfset ThemeSettingDbObj.setDate(blogNow())>
			<!--- Save it --->
			<cfif isDefined("KendoThemeDbObj")>
				<cfset EntitySave(KendoThemeDbObj)>
			</cfif>
			<cfset EntitySave(ThemeSettingDbObj)>
			<cfset EntitySave(ThemeDbObj)>
		</cftransaction>
				
		<!--- Clear the scope cache --->
		<cfset application.blog.clearScopeCache()>
		
		<!--- Return the id --->
		<cfreturn ThemeDbObj.getThemeId()>
			
	</cffunction>
			
	<!--- //************************************************************************************************************
			Page content
	//**************************************************************************************************************--->
					
	<!--- //************************************************************************************************************
			Fonts
	//**************************************************************************************************************--->
			
	<cffunction name="getDefaultFontId" access="public" returntype="numeric" 
		hint="Gets the fondId of the Arial font, for now...">	
		
		<cfquery name="getDefaultFont" dbtype="hql">
			SELECT new Map (
				FontId as FontId
			)
			FROM 
				Font as Font
			WHERE 
				Font.Font = <cfqueryparam value="Arial" cfsqltype="cf_sql_varchar">
		</cfquery>
			
		<cfif arrayLen(getDefaultFont)>
			<cfreturn getDefaultFont[1]["FontId"]>
		<cfelse>
			<cfreturn 0>
		</cfif>
	</cffunction>
					
	<cffunction name="fontExists" access="public" returntype="numeric" hint="returns a zero  or the fontId">	
		<cfargument name="font" required="yes" type="string">
		<cfargument name="fileName" required="yes" type="string">
		
		<cfquery name="getFontId" dbtype="hql">
			SELECT new Map (
				FontId as FontId
			)
			FROM 
				Font as Font
			WHERE 
				Font.Font = <cfqueryparam value="#trim(font)#" cfsqltype="cf_sql_varchar">
				OR Font.FileName = <cfqueryparam value="#trim(arguments.fileName)#" cfsqltype="cf_sql_varchar">
		</cfquery>
			
		<cfif arrayLen(getFontId)>
			<cfreturn getFontId[1]["FontId"]>
		<cfelse>
			<cfreturn 0>
		</cfif>
	</cffunction>
				
	<cffunction name="getThemeFonts" access="public" returntype="array" 
			hint="This function finds all of the fonts associated with a given theme or fonts that are marked as being used and returns the font data in a query">
		<cfargument name="themeId" required="true" type="numeric" />
		<cfargument name="selfHosted" required="false" type="boolean" default="true" />
		<cfargument name="includeWebSafeFonts" required="false" type="boolean" default="true" />
		
		<cfset var Data = []>
		
		<cfquery name="getThemeFonts" dbtype="hql">
			SELECT new Map (
				ThemeSettingRef.FontRef.FontId as FontId,
				ThemeSettingRef.MenuFontRef as MenuFontId,
				ThemeSettingRef.BlogNameFontRef as BlogNameFontId
			)
			FROM 
				Theme as Theme
			WHERE 0 = 0
			AND Theme.ThemeId = #arguments.themeId#
		</cfquery>
			
		<cfparam name="fontIdList" default="">
		<!--- Loop through the dataset and build a list of fontIds --->
		<cfif arrayLen(getThemeFonts)>
			<cfloop from="1" to="#arrayLen(getThemeFonts)#" index="i">
				<!--- Note: the fonts may be defined so extra logic is required --->
				<cfif getThemeFonts[i]["FontId"]>
					<cfset fontId = getThemeFonts[i]["FontId"]>
				<cfelse>
					<cfset fontId = getDefaultFontId()><!---Arial--->
				</cfif>
				<cfif getThemeFonts[i]["MenuFontId"]>
					<cfset menuFontId = getThemeFonts[i]["MenuFontId"]>
				<cfelse>
					<cfset menuFontId = getDefaultFontId()><!---Arial--->
				</cfif>
				<cfif getThemeFonts[i]["BlogNameFontId"]>
					<cfset blogFontId = getThemeFonts[i]["BlogNameFontId"]>
				<cfelse>
					<cfset blogFontId = getDefaultFontId()><!---Arial--->
				</cfif>
					
				<cfif len(fontId)>
					<cfset fontIdList = listAppend(fontIdList, fontId)>
				</cfif>
				<cfif len(menuFontId)>
					<cfset fontIdList = listAppend(fontIdList, menuFontId)>
				</cfif>
				<cfif len(blogFontId)>
					<cfset fontIdList = listAppend(fontIdList, blogFontId)>
				</cfif>
			</cfloop>
			<!--- Remove the dups in the list --->
			<cfset fontIdList = listRemoveDuplicates(fontIdList)>
					
			<!--- Query the fonts.--->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					FontId as FontId, 
					Font.Font as Font, 
					FontAlias as FontAlias,
					FontWeight as FontWeight,
					Font.Font as FontFace,
					Italic as Italic,
					FileName as FileName,
					SelfHosted as SelfHosted,
					FontType as FontType, 
					WebSafeFont as WebSafeFont, 
					WebSafeFallback as WebSafeFallback,
					GoogleFont as GoogleFont, 
					Woff as Woff, 
					Woff2 as Woff2, 
					UseFont as UseFont
				)
				FROM 
					Font as Font
			<cfif arguments.selfHosted>
				WHERE (FontId IN (#fontIdList#) OR (UseFont = <cfqueryparam value="1" cfsqltype="bit">))
				AND SelfHosted = <cfqueryparam value="1" cfsqltype="bit">
			<cfelse>
				WHERE (FontId IN (#fontIdList#))
			</cfif>
			<cfif arguments.includeWebSafeFonts>
				OR WebSafeFont = <cfqueryparam value="1" cfsqltype="bit">
			</cfif>
				ORDER BY Font.Font
			</cfquery>
		</cfif><!---<cfif arrayLen(getThemeFonts)>--->
		
		<cfreturn Data>
	</cffunction>
					
	<cffunction name="getFont" access="public" returntype="array">
		<cfargument name="fontId" required="false" default="" />
		<cfargument name="font" required="false" default="" />
		<cfargument name="fontAlias" required="false" default="" />
		<cfargument name="fontWeight" required="false" default="" />
		<cfargument name="italic" required="false" default="" />
		<cfargument name="fontType" required="false" default="" />
		<cfargument name="fileName" required="false" default="" />
		<cfargument name="webSafeFont" required="false" default="" hint="Certain fonts, such as Arial, are standard across platforms and do not need to be loaded." />
		<cfargument name="googleFont" required="false" default="" hint="Is this a google font? This blog can have many google fonts." />
		<cfargument name="SelfHosted" required="false" default="" hint="Is this font hosted on the server? Note: this is not used yet." />
		<cfargument name="useFont" required="false" default="" hint="Determines whether this font will be loaded on the page."/>
		<cfset var Data = []>
			
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT new Map (
				FontId as FontId, 
				Font.Font as Font, 
				'' as FontFace,
				FontAlias as FontAlias,
				FontWeight as FontWeight,
				Italic as Italic,
				FileName as FileName,
				Woff as Woff,
				Woff2 as Woff2,
				SelfHosted as SelfHosted,
				FontType as FontType, 
				WebSafeFont as WebSafeFont, 
				GoogleFont as GoogleFont, 
				UseFont as UseFont
			)
			FROM 
				Font as Font
			WHERE 0=0
			<cfif arguments.fontId neq ''>
				AND FontId = <cfqueryparam value="#arguments.fontId#" cfsqltype="cf_sql_integer">
			</cfif>
			<cfif arguments.font neq ''>
				AND Font.Font LIKE <cfqueryparam value="%#arguments.font#%" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.fontAlias neq ''>
				AND FontAlias =  <cfqueryparam value="#arguments.fontAlias#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.fontWeight neq ''>
				AND FontWeight =  <cfqueryparam value="#arguments.fontWeight#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.italic neq ''>
				AND Italic =  <cfqueryparam value="#arguments.italic#" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif arguments.fontType neq ''>
				AND FontType =  <cfqueryparam value="#arguments.fontType#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.fileName neq ''>
				AND FileName LIKE <cfqueryparam value="%#arguments.fileName#%" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.selfHosted neq ''>
				AND SelfHosted = <cfqueryparam value="#arguments.selfHosted#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.webSafeFont neq ''>
				AND WebSafeFont = <cfqueryparam value="#arguments.webSafeFont#" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif arguments.googleFont neq ''>
				AND GoogleFont =  <cfqueryparam value="#arguments.googleFont#" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif arguments.useFont neq ''>
				AND UseFont = <cfqueryparam value="#arguments.useFont#" cfsqltype="cf_sql_bit">
			</cfif>
			ORDER BY Font.Font
		</cfquery>
				
		<!--- Loop through this again and set the font face. This is determined if the font is self hosted and if it is a websafe font. --->
		<cfloop from="1" to="#arrayLen(Data)#" index="i">
			<cfif Data[i]["WebSafeFont"]>
				<cfset Data[i]["FontFace"] = Data[i]["Font"]>
			<cfelseif Data[i]["SelfHosted"]>
				<cfset Data[i]["FontFace"] = Data[i]["FileName"]>
			</cfif>
		</cfloop>
		
		<cfreturn Data>
	</cffunction>
				
	<cffunction name="insertFontRecord" access="public" returnType="string" output="true"
			hint="Inserts a font database record after a file upload">
		<cfargument name="fileName" type="string" required="true">
		<!--- Optional args --->
		<cfargument name="woff" type="boolean" default="false" required="false">
		<cfargument name="woff2" type="boolean" default="false" required="false">
		<cfargument name="webSafeFont" type="boolean" default="false" required="false">
		<cfargument name="googleFont" type="boolean" default="false" required="false">
		<cfargument name="selfHosted" type="boolean" default="false" required="false">
		<cfargument name="useFont" type="boolean" default="false" required="false">
			
		<!--- We don't want to save the extension in the file name. We will determine it dyncamically based upon the woff and woff2 columns in the font table. --->
			
		<!--- I am receiving the following error: identifier of an instance of Font was altered from 533 to 534 --->
		<cfset fileNameWithoutExtension = trim(listGetAt(fileName, 1, '.'))>
		
		<!--- Check to see if the entity exists before loading the entity. --->
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT new Map (
				FontId as FontId
			)
			FROM 
				Font as Font
			WHERE FileName = <cfqueryparam value="#fileNameWithoutExtension#" cfsqltype="cf_sql_varchar">
		</cfquery>
			
		<!--- Instantiate the font object --->
		<cfif not arrayLen(Data)>
			<cftransaction>
				<cfset FontDbObj = entityNew("Font")>
				<cfset FontDbObj.setFileName(fileNameWithoutExtension)>
				<!--- Insert the woff and woff2 records if true --->
				<cfif arguments.woff>
					<cfset FontDbObj.setWoff(arguments.woff)>
				</cfif>
				<cfif arguments.woff2>
					<cfset FontDbObj.setWoff2(arguments.woff2)>
				</cfif>
				<cfset FontDbObj.setWebSafeFont(0)>
				<cfset FontDbObj.setSelfHosted(1)>
				<cfset FontDbObj.setDate(application.blog.blogNow())>
				<!--- Save the media entity. --->
				<cfset EntitySave(FontDbObj)>

			</cftransaction>
		</cfif>
				
		<cfset thisFontId = FontDbObj.getFontId()>

		<!--- And return the fontId --->
		<cfreturn thisFontId>
	
	</cffunction>
					
	<cffunction name="updateFontRecordAfterUpload" access="public" returnType="string" output="true"
			hint="Inserts a font database record after a file upload">
		<cfargument name="fontId" type="string" required="true">
		<!--- Optional args --->
		<cfargument name="woff" type="boolean" default="false" required="false">
		<cfargument name="woff2" type="boolean" default="false" required="false">
		
		<!--- Update the font record and update the woff and woff2 columns --->
		<!--- Load the entity --->
		<cftransaction>
			<cfset FontDbObj = entityLoadByPK("Font", arguments.fontId)>
			<!--- Set the values. The only values that we are concerned here are the woff and woff2 values. Only set the values if the current record is true, otherwise we will overwrite the first record. --->
			<cfif woff>
				<cfset FontDbObj.setWoff(woff)>
			</cfif>
			<cfif woff2>
				<cfset FontDbObj.setWoff2(woff2)>
			</cfif>
		
			<!--- Save the media entity. --->
			<cfset EntitySave(FontDbObj)>
			<cfset ormFlush()>
		</cftransaction>
			
		<cfreturn fontId>
	</cffunction>
				
	<cffunction name="saveFont" access="public" returnType="string" output="true"
			hint="Updates a font in the database">
		<cfargument name="fontId" type="numeric" required="true">
		<!--- Optional args --->
		<cfargument name="fileName" type="string" default="" required="false">
		<cfargument name="font" type="string" default="" required="false">
		<cfargument name="fontAlias" type="string" default="" required="false">
		<cfargument name="fontWeight" type="string" default="" required="false">
		<cfargument name="italic" type="boolean" default="false" required="false">
		<cfargument name="fontType" type="string" default="" required="false">
		<cfargument name="webSafeFont" type="string" default="" required="false">
		<cfargument name="googleFont" type="string" default="" required="false">
		<cfargument name="selfHosted" type="string" default="" required="false">
		<cfargument name="useFont" type="string" default="" required="false"> 
			
		<cfparam name="fontAlias" type="string" default="">
			
		<!--- Create an alias --->
		<cfif len(arguments.font)>
			<cfset fontAlias = application.blog.makeAlias(arguments.font)>
		</cfif>
			
		<cftransaction>
				
			<!--- ************************* Save the data into the database ************************* --->
			<!--- Instantiate the font object --->
			<cfset FontDbObj = entityLoadByPK("Font", arguments.fontId)>
			<cfif isDefined("FontDbObj")>
				<!--- Set the values --->
				<cfset FontDbObj.setFont(arguments.font)>
				<cfset FontDbObj.setFileName(arguments.fileName)>
				<cfif fontAlias neq ''>
					<cfset FontDbObj.setFontAlias(fontAlias)>
				</cfif>
				<cfif arguments.fontWeight neq ''>
					<cfset FontDbObj.setFontWeight(arguments.fontWeight)>
				</cfif>
				<cfif arguments.italic neq ''>
					<cfset FontDbObj.setItalic(arguments.italic)>
				</cfif>
				<cfif arguments.fontType neq ''>
					<cfset FontDbObj.setFontType(arguments.fontType)>
				</cfif>
				<cfif arguments.selfHosted neq ''>
					<cfset FontDbObj.setSelfHosted(arguments.selfHosted)>
				</cfif>
				<cfif arguments.useFont neq ''>
					<cfset FontDbObj.setUseFont(arguments.useFont)>
				</cfif>
				<cfset FontDbObj.setDate(application.blog.blogNow())>
				<!--- Save the media entity. --->
				<cfset EntitySave(FontDbObj)>
			</cfif>
			
		</cftransaction>

		<!--- And return the fontId --->
		<cfreturn arguments.fontId>
	
	</cffunction>
					
	<!--- //************************************************************************************************************
			Templates
	//**************************************************************************************************************--->
			
	<cffunction name="getCoreOutputTemplatePath" dbtype="hql">
		<cfargument name="templateName" default="">
		<cfif templateName neq "">
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					CoreOutputTemplatePath as CoreOutputTemplatePath
				)
				FROM 
					CoreOutputTemplate as CoreOutputTemplate
				WHERE 
					CoreOutputTemplateName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.templateName#">
			</cfquery>
			<cfreturn Data>
		<cfelse>
			<cfreturn "Error: template not passed in.">	
		</cfif>
	</cffunction>
			
	<!--- //************************************************************************************************************
			Categories
	//**************************************************************************************************************--->
		
	<cffunction name="getCategoryList" access="public" returnType="string" output="false" 
			hint="Returns a list of category id's or names depending upon the listType argument.">
		<cfargument name="listType" type="string" required="true" hint="Either categoryList, categoryIdList, or categoryAliasList. This is  used in the add category admin UI">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category.CategoryId as CategoryId,
				Category.Category as Category, 
				Category.CategoryDesc as CategoryDesc, 
				Category.CategoryAlias as CategoryAlias
				
			)
			FROM Category
			WHERE 
				BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		
		<cfif arguments.listType eq 'categoryIdList'>
			<cfparam name="categoryIdList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset categoryIdList = categoryIdList & Data[i]["CategoryId"] & ",">
					<cfelse>
						<cfset categoryIdList = categoryIdList & Data[i]["CategoryId"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of id's --->
			<cfreturn categoryIdList>
				
		<cfelseif listType eq 'categoryList'>
			<cfparam name="categoryList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset categoryList = categoryList & Data[i]["Category"] & ",">
					<cfelse>
						<cfset categoryList = categoryList & Data[i]["Category"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of categories --->
			<cfreturn categoryList>
				
		<cfelseif arguments.listType eq 'categoryAliasList'>
			<cfparam name="categoryAliasList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset categoryAliasList = categoryAliasList & Data[i]["CategoryAlias"] & ",">
					<cfelse>
						<cfset categoryAliasList = categoryAliasList & Data[i]["CategoryAlias"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of id's --->
			<cfreturn categoryAliasList>
		</cfif>
						
	</cffunction>

	<cffunction name="getCategory" access="public" returnType="array" output="true" 
			hint="Returns an array containing the category name and alias for a specific blog entry. This is used in coreLogic.cfm, blogContentHtml.cfm, adminInterface.cfm, parsesses.cfm and xmlpc.cfm along with other places.">
		<!--- All of the types are strings as empty strings are passed in --->
		<cfargument name="categoryId" type="string" default="" required="false">
		<cfargument name="parentCategoryId" type="string" default="" required="false">
		<cfargument name="categoryUuid" type="string" default="" required="false">
		<cfargument name="category" type="string" default="" required="false">
		<cfargument name="categoryAlias" type="string" default="" required="false">
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category.CategoryId as CategoryId,
				Category.ParentCategoryRef as ParentCategoryRef,
				Category.CategorySubLevel as CategorySubLevel,
				Category.Category as Category, 
				Category.Category as CategoryDesc, 
				Category.CategoryAlias as CategoryAlias,
				Category.CategoryUuid as CategoryUuid
			)
			FROM Category as Category
			WHERE 0=0
			<cfif len(arguments.categoryId)>
				AND CategoryId = <cfqueryparam value="#arguments.categoryId#" cfsqltype="cf_sql_integer">
			</cfif>
			<cfif len(arguments.categoryUuid)>
				AND CategoryUuid = <cfqueryparam value="#arguments.categoryUuid#" cfsqltype="cf_sql_varchar" maxlength="75">
			</cfif>
			<cfif len(arguments.category)>
				AND Category.Category = <cfqueryparam value="#arguments.category#" cfsqltype="cf_sql_varchar" maxlength="125">
			</cfif>
			<cfif len(arguments.categoryAlias)>
				AND CategoryAlias = <cfqueryparam value="#arguments.categoryAlias#" cfsqltype="cf_sql_varchar" maxlength="75">
			</cfif>
			<cfif len(arguments.parentCategoryId)>
				AND ParentCategoryRef = <cfqueryparam value="#arguments.parentCategoryId#" cfsqltype="cf_sql_integer">
			</cfif>
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		
		<cfreturn Data>

	</cffunction>
			
	<cffunction name="getCategories" access="public" returnType="array" output="false" 
			hint="Returns a query containing all of the categories as well as their count for a specified blog. This is uses in the search.cfm, searchResults.cfm, ProxyController.cfc, adminInterface.cfm xmlrpc.cfm and blogContentHtml.cfm templates">
		
		<cfargument name="parentCategory" type="boolean" default="false" required="false">
		<cfargument name="childCategory" type="boolean" default="false" required="false">
		
		<cfset var getCategories = []>
		<cfset var getTotal = "">

		<cfquery name="getCategories" dbtype="hql">
			SELECT new Map (
				Category.CategoryId as CategoryId,
				Category.ParentCategoryRef as ParentCategoryRef,
				Category.CategoryUuid as CategoryUuid,
				Category.Category as Category,
				Category.CategoryAlias as CategoryAlias,
				'' as PostCount
			)
			FROM  
				Category as Category
			WHERE 
				0=0
			<cfif arguments.parentCategory>
				AND ParentCategoryRef = 0
			</cfif>
			<cfif arguments.childCategory>
				AND ParentCategoryRef > 0 
			</cfif>
				AND Category.BlogRef = #application.BlogDbObj.getBlogId()#	
			ORDER BY Category
		</cfquery>
		<!---<cfdump var="#getCategories#">--->

		<!--- Loop thru the categories and get the post count. The post count is used on some interfaces to show how many posts belong to a given category. --->
		<cfif arrayLen(getCategories)>
			<cfloop from="1" to="#arrayLen(getCategories)#" index="i">

				<cfset categoryId = getCategories[i]["CategoryId"]>

				<cfquery name="getCategoryPostCount" dbtype="hql">
					SELECT new Map (
						count(Post.PostId) as PostCount
					)
					FROM  
						PostCategoryLookup as PostCategoryLookup
						JOIN PostCategoryLookup.CategoryRef as Category
						JOIN PostCategoryLookup.PostRef as Post
					WHERE 
						PostCategoryLookup.CategoryRef = #getCategories[i]["CategoryId"]#
						AND Released = 1
						AND Post.Remove = 0
						AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
						AND Category.BlogRef = #application.BlogDbObj.getBlogId()#
					GROUP BY  
						CategoryId			
				</cfquery>

				<!--- Set the post count --->
				<cfif arrayLen(getCategoryPostCount) and isNumeric(getCategoryPostCount[1]["PostCount"])>
					<cfset postCount = getCategoryPostCount[1]["PostCount"]>
				<cfelse>
					<cfset postCount = 0>
				</cfif>

				<!--- Modify the array values and add the post count --->
				<cfset getCategories[i]["PostCount"] = postCount>
			</cfloop>
		</cfif><!---<cfif arrayLen(getCategories)>--->

		<cfreturn getCategories>
		
	</cffunction>
			
	<cffunction name="getCategoriesForGrid" access="public" returnType="array" output="false" 
			hint="Returns a query containing all of the categories as well as their count for a specified blog. This is used in ProxyController.cfc and the categories grid">
		<cfargument name="category" type="string" required="false" default="">
		<cfargument name="alias" type="string" required="false" default="">
		<cfargument name="date" type="string" required="false" default="">
			
		<cfset var getCategories = []>
		<cfset var getTotal = "">

		<!--- Note: caching may no longer be necessary here as the new ORM logic should fix some of the performance issues of the original ad-hoc BlogCfc query. --->
		<cfif structKeyExists(variables, "categoryCache") and arguments.usecache>
			<cfreturn variables.categoryCache>
		</cfif>

		<cfquery name="getCategories" dbtype="hql">
			SELECT new Map (
				Category.CategoryId as CategoryId,
				Category.CategoryUuid as CategoryUuid,
				Category.Category as Category,
				Category.CategoryAlias as CategoryAlias,
				'' as PostCount,
				Category.Date as Date
			)
			FROM  
				Category as Category
			WHERE 
				0=0
			<cfif arguments.category neq ''>
				AND Category.Category LIKE <cfqueryparam value="%#arguments.category#%">
			</cfif>
			<cfif arguments.alias neq ''>
				AND Category.CategoryAlias LIKE <cfqueryparam value="%#arguments.alias#%">
			</cfif>
			<cfif arguments.date neq ''>
				AND Category.Date LIKE <cfqueryparam value="%#arguments.date#%">
			</cfif>
				AND Category.BlogRef = #application.BlogDbObj.getBlogId()#	
				ORDER BY Category.Category
		</cfquery>
		<!---<cfdump var="#getCategories#">--->

		<!--- Loop thru the categories and get the post count. The post count is used on some interfaces to show how many posts belong to a given category. --->
		<cfif arrayLen(getCategories)>
			<cfloop from="1" to="#arrayLen(getCategories)#" index="i">

				<cfset categoryId = getCategories[i]["CategoryId"]>

				<cfquery name="getCategoryPostCount" dbtype="hql">
					SELECT new Map (
						count(Post.PostId) as PostCount
					)
					FROM  
						PostCategoryLookup as PostCategoryLookup
						JOIN PostCategoryLookup.CategoryRef as Category
						JOIN PostCategoryLookup.PostRef as Post
					WHERE 
						PostCategoryLookup.CategoryRef = #categoryId#
						AND Released = 1
						AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
						AND Category.BlogRef = #application.BlogDbObj.getBlogId()#
					GROUP BY  
						CategoryId			
				</cfquery>

				<!--- Set the post count --->
				<cfif arrayLen(getCategoryPostCount)>
					<cfset postCount = getCategoryPostCount[1]["PostCount"]>
				<cfelse>
					<cfset postCount = 0>
				</cfif>
				<!--- postCount: <cfoutput>#postCount#</cfoutput> --->

				<!--- Modify the array values and add the post count --->
				<cfset getCategories[i]["PostCount"] = postCount>
			</cfloop>
		</cfif><!---<cfif arrayLen(getCategories)>--->

		
		<cfreturn getCategories>
		
	</cffunction>

	<cffunction name="getCategoriesForPost" access="public" returnType="array" output="false" 
			hint="Returns a array containing all of the categories for a specific blog entry. Used in the adminInterface.cfm and xmlrpc.cfm templates">
		<cfargument name="postId" type="numeric" required="true">
		<cfset var Data = "[]">

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("'#arguments.postId#' does not exist.")>
		</cfif>

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category.CategoryId as CategoryId,
				Category.ParentCategoryRef as ParentCategoryRef,
				Category.CategoryUuid as CategoryUuid, 
				Category.Category as Category
			)
			FROM 
				PostCategoryLookup as PostCategoryLookup,
				Category as Category
			WHERE 
				PostCategoryLookup.CategoryRef = Category.CategoryId
				AND PostCategoryLookup.PostRef = #arguments.postId#		
		</cfquery>

		<cfreturn Data>

	</cffunction>
			
	<cffunction name="getCategoriesByPostId" access="public" returntype="array" output="false"
		hint="Returns the categories for a given post id. Used in the blogContentHtml.cfm and Blog.cfc templates">	
		<cfargument name="postId" type="numeric" required="true">
			
		<!--- Get the categories. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category.CategoryId as CategoryId,
				Category.ParentCategoryRef as ParentCategoryRef,
				Category.CategorySubLevel as CategorySubLevel,
				Category.CategoryUuid as CategoryUuid, 
				Category.Category as Category
			)
			FROM 
				PostCategoryLookup as PostCategoryLookup,
				Category as Category
			WHERE 
				PostCategoryLookup.CategoryRef = Category.CategoryId
				<!--- Pass in the PostId --->
				AND PostCategoryLookup.PostRef = #arguments.postId#
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="getParentCategoryQuery" 
			hint="Finds and returns a query object of the parent categories to generate breadcrumb navigation.">
		<cfargument name="categoryId" required="true" hint="Pass in the initial cateoryId to start things off">
		<cfargument name="parentCategoriesQuery" required="false" default="" hint="this is the final list that will be returned when there are no more parentCategoryId's left">

		<!---
		Example usage:
		<cfset categoryList = getParentCategoryQuery(56,'')> 
		<cfdump var="#categoryList#">
		--->

		<!--- Get the current category (this is a HQL array) --->
		<cfset getCategory = application.blog.getCategory(categoryId=arguments.categoryId)>
		<!--- Extract the data --->
		<cfset parentCategoryId = getCategory[1]["ParentCategoryRef"]>
		<cfset categoryId = getCategory[1]["CategoryId"]>
		<cfset category = getCategory[1]["Category"]>
		<cfset categoryLevel = getCategory[1]["CategorySubLevel"]>

		<!--- Create a new three-column query, specifying the column data types ---> 
		<cfif not isQuery(parentCategoriesQuery)>
			<cfset parentCategoriesQuery = queryNew("CategoryId, ParentCategoryId, Category, CategoryLink, CategoryLevel", "integer, integer, varchar, varchar, integer")> 
			<!--- Create new rows in the query. We need as many rows as we have category levels ---> 
			<cfset queryAddRow(parentCategoriesQuery, categoryLevel)>

		</cfif><!---<cfif not isQuery(parentCategoriesQuery)>--->

		<!--- Fallback condition --->
		<cfif parentCategoriesQuery.recordcount gte 7>

			<!---There should never be more than 7 rows in this query. Send the data back as is.--->
			<cfreturn parentCategoriesQuery>

		<cfelse><!---<cfif parentCategoriesQuery.recordcount gte 7>--->
			<!--- Set the values of the cells in the query ---> 
			<cfset querySetCell(parentCategoriesQuery, "CategoryId", categoryId, categoryLevel)> 
			<cfset querySetCell(parentCategoriesQuery, "ParentCategoryId", parentCategoryId, categoryLevel)> 
			<cfset querySetCell(parentCategoriesQuery, "Category", category, categoryLevel)> 
			<cfset querySetCell(parentCategoriesQuery, "CategoryLink", application.blog.makeCategoryLink(categoryId), categoryLevel)> 
			<cfset querySetCell(parentCategoriesQuery, "CategoryLevel", categoryLevel, categoryLevel)> 

			<!--- If there is a parentCategoryId, call this function recursively and pass in the new parentCategoryId. Otherwise, return the categoryIdList. Note: we must use a cfreturn to call the function recursively, otherwise the categoryIdList will not be returned properly. --->
			<cfif parentCategoryId>
				<cfreturn getParentCategoryQuery(parentCategoryId,parentCategoriesQuery)>			
			<cfelse>
				<cfreturn parentCategoriesQuery>
			</cfif>

		</cfif><!---<cfif parentCategoriesQuery.recordcount gte 7>--->

	</cffunction>
			
	<cffunction name="categoryExists" access="private" returnType="boolean" output="false"
			hint="Returns true or false if an entry exists. Used in this cfc and ProxyController.cfc to verify that the category does not exist.">
		<cfargument name="id" type="uuid" required="false">
		<cfargument name="name" type="string" required="false">
		
		<cfset var checkC = "">

		<!--- must pass either ID or name, but not obth --->
		<cfif (not isDefined("arguments.id") and not isDefined("arguments.name")) or (isDefined("arguments.id") and isDefined("arguments.name"))>
			<cfset variables.utils.throw("categoryExists method must be passed id or name, but not both.")>
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT 
				CategoryId
			FROM Category
			WHERE 0=0
			<cfif isDefined("arguments.id")>
				AND CategoryUuid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			<cfif isDefined("arguments.name")>
				AND Category = <cfqueryparam value="#arguments.name#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset categoryFound = true>
		<cfelse>
			<cfset categoryFound = false>
		</cfif>
		
		<cfreturn categoryFound>

	</cffunction>
			
	<cffunction name="postCategoryExists" access="private" returnType="boolean" output="false"
			hint="Returns true or false if the relationship between a post and a category exists. Used to determine whether to insert records into the PostCategoryLookup table in order to prevent duplicate records.">
		<cfargument name="postId" type="numeric" required="true">
		<!--- Either the category, categoryId or the categoryUuid must be sent in --->
		<cfargument name="category" type="string" default="" required="false">
		<cfargument name="categoryId" type="numeric" default="" required="false">
		<cfargument name="categoryUuid" type="any" default="" required="false">
			
		<!--- Load the category object by the categoryId  --->
		<cfif len(arguments.categoryId) and isNumeric(categoryId)>
			<cfset CategoryRefObj = entityLoadByPK("Category", arguments.categoryId)>
		<cfelseif len(arguments.category)>
			<!--- Load the category object by the category  --->
			<cfset CategoryRefObj = entityLoad("Category", { Category = arguments.category }, "true" )>
		<cfelseif len(arguments.categoryUuid)>
			<!--- Load the category object with the category UUID  --->
			<cfset CategoryRefObj = entityLoad("Category", { CategoryUuid = arguments.categoryUuid }, "true" )>
		</cfif>
			
		<!--- Get the Post Id--->
		<cfset PostRefObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
			
		<cfif isDefined("CategoryRefObj") and isDefined("PostRefObj")>
			<cfquery name="Data" dbtype="hql">
				SELECT new Map(
					PostCategoryLookupId as PostCategoryLookupId
				)
				FROM PostCategoryLookup
				WHERE 0=0
					AND CategoryRef = #CategoryRefObj.getCategoryId()#
					AND PostRef = #arguments.postId#
			</cfquery>

			<cfif arrayLen(Data)>
				<cfset postCategoryExists = true>
			<cfelse>
				<cfset postCategoryExists = false>
			</cfif>
		<cfelse>
			<cfset postCategoryExists = false>
		</cfif>
		
		<cfreturn postCategoryExists>

	</cffunction>
			
	<cffunction name="assignCategory" access="public" returnType="numeric" output="false"
			hint="Assigns postId to a category">
		<cfargument name="postId" type="numeric" required="true">
		<!--- Either the category, categoryId or the categoryUuid must be sent in --->
		<cfargument name="category" type="string" default="" required="false">
		<cfargument name="categoryId" type="numeric" default="" required="false">
		<cfargument name="categoryUuid" type="any" default="" required="false">
		
		<cfset var Data = "">
			
		<!--- Load the category object by the categoryId  --->
		<cfif len(arguments.categoryId) and isNumeric(categoryId)>
			<cfset CategoryRefObj = entityLoadByPK("Category", arguments.categoryId)>
		<cfelseif len(arguments.category)>
			<!--- Load the category object by the category  --->
			<cfset CategoryRefObj = entityLoad("Category", { Category = arguments.category }, "true" )>
		<cfelseif len(arguments.categoryUuid)>
			<!--- Load the category object with the category UUID  --->
			<cfset CategoryRefObj = entityLoad("Category", { CategoryUuid = arguments.categoryUuid }, "true" )>
		</cfif>
			
		<!--- Get the Post Id--->
		<cfset PostRefObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
		
		<!--- Are both of our objects defined? The entityLoad function will only create an object if the filters match existing records. --->
		<cfif isDefined("CategoryRefObj") and isDefined("PostRefObj")>
			
			<!--- See if the relationship exists. Note: HQL does not like when the primary keys are in a cfqueryparam tag. Sigh. I think that this is OK here. --->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map(
					PostCategoryLookupId as PostCategoryLookupId
				)
				FROM PostCategoryLookup
				WHERE 0=0
					AND CategoryRef = #CategoryRefObj.getCategoryId()#
					AND PostRef = #arguments.postId#
			</cfquery>

			<cfif arrayLen(Data)>
				<cfreturn Data[1]["PostCategoryLookupId"]>
			<cfelse><!---<cfif arrayLen(Data)>--->
				<!--- Load the entity. --->
				<cfset PostCategoryObj = entityNew("PostCategoryLookup")>
				<!--- Use the entity objects to set the data. --->
				<cfset PostCategoryObj.setCategoryRef(CategoryRefObj)>
				<cfset PostCategoryObj.setPostRef(PostRefObj)>
				<cfset PostCategoryObj.setDate(blogNow())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(PostCategoryObj)>

				<!--- Return the categoryId --->
				<cfreturn PostCategoryObj.getPostCategoryLookupId()>
			</cfif><!---<cfif arrayLen(Data)>--->
		<cfelse><!---<cfif isDefined("CategoryRefObj") and isDefined("PostRefObj")>--->
			<!--- Return a zero indicating that something went wrong. The category or post does not exist. --->
			<cfreturn 0>
		</cfif><!---<cfif isDefined("CategoryRefObj") and isDefined("PostRefObj")>--->
				
	</cffunction>

	<cffunction name="assignCategories" access="public" returnType="void" output="false"
			hint="Assigns a postId to multiple categories">
		<cfargument name="postId" type="numeric" required="true">
		<cfargument name="categoryids" type="string" required="true">

		<cfset var i=0>

		<!--- Loop through categories --->
		<cfloop index="i" from="1" to="#listLen(arguments.categoryids)#">
			<cfset assignCategory(postId=arguments.postId,categoryUuid=listGetAt(categoryids,i))>
		</cfloop>

	</cffunction>
			
	<cffunction name="addCategory" access="public" returnType="uuid" roles="admin,AddCategory,ManageCategory" output="true"
			hint="Adds a category.">
		<cfargument name="name" type="string" required="true">
		<cfargument name="alias" type="string" required="false">

		<cfset var checkC = "">
		<cfset var uuid = createUUID()>

		<!--- Don't create multiple categories. A new child category may be created programmatically tho. --->
		<cfif categoryExists(name="#arguments.name#")>
			<cfset variables.utils.throw("#arguments.name# already exists as a category.")>
		</cfif>
			
		<!--- Create the alias if it was not sent --->
		<cfif not len(arguments.alias)>
			<!--- If the alias was not sent, create a new SES friendly alias using the category --->
			<cfset arguments.alias = application.blog.makeAlias(arguments.category)>
		</cfif>
			
		<cftransaction>
			<!--- Load the blog table and get the first record (there only should be one record). This will pass back an object with the value of the blogId. --->
			<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>
			<!--- Load the entity. --->
			<cfset CategoryDbObj = entityNew("Category")>
			<!--- Use the entity objects to set the data. --->
			<cfset CategoryDbObj.setBlogRef(blogRef)>
			<cfset CategoryDbObj.setCategoryUuid(uuid)>
			<cfset CategoryDbObj.setCategoryAlias(arguments.alias)>
			<cfset CategoryDbObj.setCategory(arguments.name)>
			<cfset CategoryDbObj.setDate(blogNow())>

			<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
			<cfset EntitySave(CategoryDbObj)>
		</cftransaction>
				
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

		<cfreturn id>
	</cffunction>

	<cffunction name="saveCategory" access="public" returnType="numeric" output="false"
			hint="Saves a category.">
		<!--- Pass in the categoryId if you want to update the record. The category is always required. --->
		<cfargument name="categoryId" type="any" default="" required="false">
		<cfargument name="parentCategoryId" type="any" default="0" required="false">
		<cfargument name="categoryUuid" type="any" default="" required="false" hint="Used when importing data from previous versions of BlogCfc">
		<cfargument name="category" type="string" required="true">
		<cfargument name="categoryAlias" type="string" default="" required="false">
			
		<!--- Create the alias --->
		<cfif not len(arguments.categoryAlias)>
			<!--- If the alias was not sent, create a new SES friendly alias using the category --->
			<cfset newAlias = application.blog.makeAlias(arguments.category)>
		<cfelse>
			<!--- Check to see if the alias is formatted properly. --->
			<cfif reFind("[^[:alnum:] -]", arguments.categoryAlias)>
				<!--- The alias contains something other than letters, numbers, spaces, or hyphens. Create a new alias using the category and continue. --->
				<!--- Create a new SES friendly alias using the category --->
				<cfset newAlias = application.blog.makeAlias(arguments.category)>
			<cfelse>
				<!--- Use the provided alias --->
				<cfset newAlias = arguments.categoryAlias>
			</cfif>
		</cfif>
					
		<!--- See if the record exists --->
		<cfset getCategory = this.getCategory(category=arguments.category)>
		<cfif arrayLen(getCategory) and isNumeric(getCategory[1]["CategoryId"])>
			<!--- Set the categoryId --->
			<cfset arguments.categoryId = getCategory[1]["CategoryId"]>
		</cfif>
		
		<!--- Insert or update the record. --->
		<cfif len(arguments.categoryId)>
			<cftransaction>
				<!--- Update the record. --->
				<cfquery name="Data" dbtype="hql">
					UPDATE Category
					SET
					<cfif len(arguments.categoryUuid)>
						CategoryUuid = <cfqueryparam value="#arguments.categoryUuid#" cfsqltype="cf_sql_varchar" maxlength="75">,
					</cfif>
					<cfif len(arguments.categoryAlias)>
						CategoryAlias = <cfqueryparam value="#arguments.categoryAlias#" cfsqltype="cf_sql_varchar" maxlength="75">,
					</cfif>
						ParentCategoryRef = <cfqueryparam value="#arguments.parentCategoryId#" cfsqltype="cf_sql_integer">,
						Category = <cfqueryparam value="#arguments.category#" cfsqltype="cf_sql_varchar" maxlength="50">
					WHERE 0=0
						AND CategoryId = <cfqueryparam value="#arguments.categoryId#" cfsqltype="cf_sql_integer">
				</cfquery>
			</cftransaction>
			<cfreturn arguments.categoryId>
				
		<cfelse><!---<cfif len(arguments.categoryId)>--->
			
			<!--- Insert the record --->
			<cfif len(arguments.categoryUuid)>
				<cfset categoryUuid = arguments.categoryUuid>
			<cfelse>
				<cfset categoryUuid = createUUID()>
			</cfif>
			<cftransaction>
				<!--- Create a new category entity --->
				<cfset CategoryDbObj = entityNew("Category")>
				<cfset CategoryDbObj.setCategoryUuid(categoryUuid)>
				<cfset CategoryDbObj.setParentCategoryRef(arguments.parentCategoryId)>
				<cfset CategoryDbObj.setCategory(arguments.category)>
				<cfset CategoryDbObj.setCategoryAlias(newAlias)>
				<cfset CategoryDbObj.setDate(blogNow())> 
				<cfset CategoryDbObj.setBlogRef(application.BlogDbObj)>
				<!---Save it--->
				<cfset EntitySave(CategoryDbObj)>
			</cftransaction>
			
			<!--- Return the new Id --->
			<cfreturn CategoryDbObj.getCategoryId()>
		
		</cfif><!---<cfif len(arguments.categoryId)>--->
					
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>
			
	<cffunction name="savePostCategories" access="public" returnType="string" output="true"
			hint="Attaches a list of categories to a given post.">
		<!--- Pass in the categoryId if you want to update the record. The category is always required. --->
		<cfargument name="postId" type="any" default="" required="true">
		<cfargument name="categoryIdList" type="string" required="true">
			
		<!--- Paramaterize the arguments since these are entities and can't use cfqueryparam. --->
		<cfparam name="thisPostId" default="#arguments.postId#" type="integer" maxlength="9">
		<cfparam name="thisCategoryIdList" default="#arguments.categoryIdList#" type="string" maxlength="35">
		<cfparam name="thisBlogId" default="#application.BlogDbObj.getBlogId()#" type="integer" maxlength="9">
	
		<!--- Debugging carriage. Set output to true when debugging. You will have json errors when debugging due to the extra white space --->
		<cfset debug = 0>

		<!---******************************************************************************************************** 
			Delete categories that are no longer used
		*********************************************************************************************************--->

		<!--- Note: 'PostCategoryLookup.CategoryRef as CategoryId' alone brings back the entire category entity object. --->
		<cfquery name="getCategoriesNotInList" dbtype="hql">
			SELECT new Map (
				PostCategoryLookup.CategoryRef.CategoryId as CategoryId
			)
			FROM  
				PostCategoryLookup as PostCategoryLookup
				JOIN PostCategoryLookup.CategoryRef as Category
				JOIN PostCategoryLookup.PostRef as Post
			WHERE 
				PostCategoryLookup.PostRef = #thisPostId#
				AND PostCategoryLookup.CategoryRef NOT IN (#thisCategoryIdList#)
				AND Post.BlogRef = #thisBlogId#		
		</cfquery>

		<!--- Loop through the recordset and delete these records in the PostCategoryLookup table. Unfortunately there is no clean way that I know of to get a value list from an Orm query, so we will do this one by one. --->
		<cfif arrayLen(getCategoriesNotInList)>
			<cfloop from="1" to="#arrayLen(getCategoriesNotInList)#" index="i">
				<cfset categoryId = getCategoriesNotInList[i]["CategoryId"]>
				<cfif debug><cfdump var="#categoryId#"></cfif>
				<cfquery name="deleteExcessCategories" dbtype="hql">
					DELETE
					FROM  
						PostCategoryLookup as PostCategoryLookup
					WHERE 
						PostCategoryLookup.CategoryRef = #categoryId#		
				</cfquery>
			</cfloop>
		</cfif>

		<!---******************************************************************************************************** 
			Determine whether to insert or update the record
		*********************************************************************************************************--->

		<!--- Create a counter --->
		<cfset categoryListCounter = 1>
			
		<!--- Loop through the new category id list. There can be multple categories in this list- the first catgory found is a parent category and every category found later is a subcategory. --->
		<cfloop list="#categoryIdList#" index="i">
			
			<!--- Reset the getPostCategory array prior to making a new query --->
			<cfset getPostCategory = []>
				
			<!--- Determine if this is a parent or child category --->
			<cfif categoryListCounter eq 1>
				<cfset parentCategory = true>
				<!--- The parentCategoryId is 0 --->
				<cfset parentCategoryId = 0>
			<cfelse>
				<cfset parentCategory = false>
				<!--- Get the parentCategoryId, which is the previous CategoryId in the list. --->
				<cfset parentCategoryId = listGetAt(categoryIdList, categoryListCounter-1)>
			</cfif>
			<cfif debug><cfoutput>i:#i# categoryListCounter:#categoryListCounter# parentCategory:#parentCategory# parentCategoryId:#parentCategoryId#</cfoutput><br/></cfif>

			<!--- 
			Determine if this is record is already in the PostCategoryLookup table. However, we also need to get the proper sublevel so we will make a preliminary query based upon the category counter.
			Note: 'PostCategoryLookup.CategoryRef as CategoryId' alone brings back the entire category entity object. 
			--->
			<cfquery name="getPostCategoryAndSubLevel" dbtype="hql">
				SELECT new Map (
					PostCategoryLookup.PostCategoryLookupId as PostCategoryLookupId
				)
				FROM  
					PostCategoryLookup as PostCategoryLookup
					JOIN PostCategoryLookup.CategoryRef as Category
					JOIN PostCategoryLookup.PostRef as Post
				WHERE 
					PostCategoryLookup.PostRef = #thisPostId#
					AND Post.BlogRef = #thisBlogId#		
			</cfquery>
			<cfif debug><cfdump var="#getPostCategoryAndSubLevel#"></cfif>
					
			<!--- Try to get the proper Id by the sublevel --->
			<cfif categoryListCounter lte arrayLen(getPostCategoryAndSubLevel)>
				<cfset thisPostCategoryId = getPostCategoryAndSubLevel[categoryListCounter]["PostCategoryLookupId"]>
				<cfif debug><br/>thisPostCategoryId: <cfoutput>#thisPostCategoryId#</cfoutput><br/></cfif>
					
				<!--- Get the data --->
				<cfquery name="getPostCategory" dbtype="hql">
					SELECT new Map (
						PostCategoryLookup.PostCategoryLookupId as PostCategoryLookupId,
						PostCategoryLookup.CategoryRef.CategoryId as CategoryId,
						PostCategoryLookup.CategoryRef.Category as Category
					)
					FROM  
						PostCategoryLookup as PostCategoryLookup
						JOIN PostCategoryLookup.CategoryRef as Category
						JOIN PostCategoryLookup.PostRef as Post
					WHERE 
						PostCategoryLookup.PostRef = #thisPostId#
						AND PostCategoryLookup.PostCategoryLookupId = #thisPostCategoryId#
						AND Post.BlogRef = #thisBlogId#		
				</cfquery>
				<!---
				Test query
				SELECT     
					PostCategoryLookup.PostCategoryLookupId, 
					Category.ParentCategoryRef, 
					Category.CategorySubLevel, 
					Category.Category
				FROM        PostCategoryLookup INNER JOIN
					  Category ON PostCategoryLookup.CategoryRef = Category.CategoryId
				WHERE PostCategoryLookup.PostRef = 4153
				--->
					
			<cfelse>
				<!--- Set the getPostCategory to null in order to insert a new record. --->
				<cfset getPostCategory = []>
			</cfif>
				
			<cfif debug><cfdump var="#getPostCategory#"><br/></cfif>

			<!---******************************************************************************************************** 
					If the record is not found, insert it into the PostCategoryLookup table. Otherwise leave the current record intact
			*********************************************************************************************************--->
			<cfif arrayLen(getPostCategory) eq 0>
				<cfif debug>Inserting new category <cfoutput>i:#i#</cfoutput><br/><br/></cfif>
				<!--- Load the entities that will be used to populate the PostCategoryLookup entity --->
				<cfset PostDbObj = entityLoadByPK("Post", postId)>
				
				<!---******************************************************************************************************** 
					Update the ParentCategoryRef into the category table
				*********************************************************************************************************--->
				<cftransaction>
					<!--- Get a reference to the category entity --->
					<cfset CategoryDbObj = entityLoadByPK("Category", i)>
					<!--- Update the parentCategoryRef... --->
					<cfset CategoryDbObj.setParentCategoryRef(parentCategoryId)>
					<!--- And save the entity --->
					<cfset EntitySave(CategoryDbObj)>
				</cftransaction>
				
				<!---******************************************************************************************************** 
					Now, create a new post lookup entity
				*********************************************************************************************************--->
				<cftransaction>
					<cfset PostCategoryLookupDbObj = entityNew("PostCategoryLookup")>
					<cfset PostCategoryLookupDbObj.setPostRef(PostDbObj)>
					<cfset PostCategoryLookupDbObj.setCategoryRef(CategoryDbObj)>
					<cfset CategoryDbObj.setCategorySubLevel(categoryListCounter)>
					<cfset PostCategoryLookupDbObj.setDate(blogNow())>
					<!--- Save it --->
					<cfset EntitySave(PostCategoryLookupDbObj)>
				</cftransaction>
					
			<!---******************************************************************************************************** 
					Update the category and PostCategoryLookup tables. 
			*********************************************************************************************************--->
			<cfelse>
				
				<cfif debug><cfoutput>Updating record. i:#i# getPostCategory[1]["Category"]:#getPostCategory[1]["Category"]# PostCategoryLookupId:#getPostCategory[1]["PostCategoryLookupId"]#</cfoutput><br/><br/></cfif>
				
				<!--- Update the ParentCategoryRef and SubLevel into the category table --->
				<cftransaction>
					<!--- Get a reference to the category entity --->
					<cfset CategoryDbObj = entityLoadByPK("Category", i)>
					<!--- Update the parentCategoryRef... --->
					<cfset CategoryDbObj.setParentCategoryRef(parentCategoryId)>
					<!--- Update the sublevel --->
					<cfset CategoryDbObj.setCategorySubLevel(categoryListCounter)>
					<!--- And save the entity --->
					<cfset EntitySave(CategoryDbObj)>
				</cftransaction>
					
				<!--- Update the existing post category lookup record. This needs to be done as the category order may have been changed --->
				<cftransaction>
					<cfset PostCategoryLookupDbObj = entityLoadByPk("PostCategoryLookup", getPostCategory[1]["PostCategoryLookupId"])>
					<cfset PostCategoryLookupDbObj.setCategoryRef(CategoryDbObj)>
					<cfset PostCategoryLookupDbObj.setDate(blogNow())>
					<!--- Save it --->
					<cfset EntitySave(PostCategoryLookupDbObj)>
				</cftransaction>
						
			</cfif>
			<!--- Increment our counter --->
			<cfset categoryListCounter = categoryListCounter + 1>
		</cfloop>
						
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>
		
		<cfreturn arguments.categoryIdList>

	</cffunction>
					
	<cffunction name="removeCategory" access="public" returnType="void" output="false"
			hint="Deletes a relationshp between a post and a category.">
		<cfargument name="postId" type="numeric" required="true">
		<cfargument name="categoryid" type="numeric" required="true">
			
		<!--- Load the post object --->
		<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
		<!--- Load the category object --->
		<cfset CategoryDbObj = entityLoad("Category", { CategoryUuid = arguments.categoryid }, "true" )>
			
		<!--- Delete the record in the lookup table. --->
		<cfquery name="Data" dbtype="hql">
			DELETE FROM PostCategoryLookup
			WHERE PostRef = #PostDbObj#
			AND CategoryRef = #CategoryDbObj#
		</cfquery>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>

	<cffunction name="removeCategories" access="public" returnType="void" output="false"
			hint="Remove all categories from an entry.">
		<cfargument name="postId" type="numeric" required="true">
			
		<!--- Load the post object --->
		<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
			
		<!--- Delete the record in the lookup table. --->
		<cfquery name="Data" dbtype="hql">
			DELETE FROM PostCategoryLookup
			WHERE PostRef = #PostDbObj#
		</cfquery>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>

	<cffunction name="deleteCategory" access="public" returnType="void" roles="admin,ManageCategories" output="false"
			hint="Deletes a category.">
		<cfargument name="id" type="uuid" required="true">
			
		<!--- Load the Category entity by the CategoryUuid --->
		<cfset CategoryDbObj = entityLoad("Category", { CategoryUuid = arguments.id }, "true" )>
		<!--- Delete this record --->
		<cfset EntityDelete(CategoryDbObj)>
		<!--- And delete the variable to ensure that the record is deleted from ORM memory. --->
		<cfset void = structDelete( variables, "CategoryDbObj" )>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>
			
			
	<!--- //************************************************************************************************************
			Tags
	//**************************************************************************************************************--->
		
	<cffunction name="getTagList" access="public" returnType="string" output="false" 
			hint="Returns a list of tag id's or names depending upon the listType argument.">
		<cfargument name="listType" type="string" required="true" hint="Either tagList, tagIdList, or tagAliasList. This is  used in the add category admin UI">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Tag.TagId as TagId,
				Tag.Tag as Tag, 
				Tag.TagDesc as TagDesc, 
				Tag.TagAlias as TagAlias
				
			)
			FROM Tag
			WHERE 
				BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		
		<cfif arguments.listType eq 'tagIdList'>
			<cfparam name="tagIdList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset tagIdList = tagIdList & Data[i]["TagId"] & ",">
					<cfelse>
						<cfset tagIdList = tagIdList & Data[i]["TagId"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of id's --->
			<cfreturn tagIdList>
				
		<cfelseif listType eq 'tagList'>
			<cfparam name="tagList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset tagList = tagList & Data[i]["Tag"] & ",">
					<cfelse>
						<cfset tagList = tagList & Data[i]["Tag"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of categories --->
			<cfreturn tagList>
				
		<cfelseif arguments.listType eq 'tagAliasList'>
			<cfparam name="tagAliasList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset tagAliasList = tagAliasList & Data[i]["TagAlias"] & ",">
					<cfelse>
						<cfset tagAliasList = tagAliasList & Data[i]["TagAlias"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of id's --->
			<cfreturn tagAliasList>
		</cfif>
						
	</cffunction>

	<cffunction name="getTag" access="public" returnType="array" output="true" 
			hint="Returns an array containing the tag name and alias for a specific blog entry. This is used in coreLogic.cfm, blogContentHtml.cfm, adminInterface.cfm, parsesses.cfm and xmlpc.cfm along with other places.">
		<!--- All of the types are strings as empty strings are passed in --->
		<cfargument name="tagId" type="string" default="" required="false">
		<cfargument name="tagUuid" type="string" default="" required="false">
		<cfargument name="tag" type="string" default="" required="false">
		<cfargument name="tagAlias" type="string" default="" required="false">
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Tag.TagId as TagId,
				Tag.Tag as Tag, 
				Tag.Tag as TagDesc, 
				Tag.TagAlias as TagAlias,
				Tag.TagUuid as TagUuid
			)
			FROM Tag as Tag
			WHERE 0=0
			<cfif len(arguments.tagId)>
				AND TagId = <cfqueryparam value="#arguments.tagId#" cfsqltype="cf_sql_integer">
			</cfif>
			<cfif len(arguments.tagUuid)>
				AND TagUuid = <cfqueryparam value="#arguments.tagUuid#" cfsqltype="cf_sql_varchar" maxlength="75">
			</cfif>
			<cfif len(arguments.tag)>
				AND Tag.Tag = <cfqueryparam value="#arguments.tag#" cfsqltype="cf_sql_varchar" maxlength="125">
			</cfif>
			<cfif len(arguments.tagAlias)>
				AND TagAlias = <cfqueryparam value="#arguments.tagAlias#" cfsqltype="cf_sql_varchar" maxlength="75">
			</cfif>
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		
		<cfreturn Data>

	</cffunction>
			
	<cffunction name="getTags" access="public" returnType="array" output="false" 
			hint="Returns a query containing all of the tags as well as their count for a specified blog. This is uses in the search.cfm, searchResults.cfm, ProxyController.cfc, adminInterface.cfm xmlrpc.cfm and blogContentHtml.cfm templates">
		<cfset var getTags = []>
		<cfset var getTotal = "">

		<cfquery name="getTags" dbtype="hql">
			SELECT DISTINCT new Map (
				Tag.TagId as TagId,
				Tag.TagUuid as TagUuid,
				Tag.Tag as Tag,
				Tag.TagAlias as TagAlias,
				'' as PostCount
			)
			FROM  
				Tag as Tag
			WHERE 
				0=0
				AND Tag.BlogRef = #application.BlogDbObj.getBlogId()#	
			ORDER BY Tag
		</cfquery>
		<!---<cfdump var="#getCategories#">--->

		<!--- Loop thru the categories and get the post count. The post count is used on some interfaces to show how many posts belong to a given tag. --->
		<cfif arrayLen(getTags)>
			<cfloop from="1" to="#arrayLen(getTags)#" index="i">

				<cfset tagId = getTags[i]["TagId"]>

				<cfquery name="getTagPostCount" dbtype="hql">
					SELECT new Map (
						count(Post.PostId) as PostCount
					)
					FROM  
						PostTagLookup as PostTagLookup
						JOIN PostTagLookup.TagRef as Tag
						JOIN PostTagLookup.PostRef as Post
					WHERE     
						PostTagLookup.TagRef = #getTags[i]["TagId"]#
						AND Released = 1
						AND Post.Remove = 0
						AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
						AND Tag.BlogRef = #application.BlogDbObj.getBlogId()#
					GROUP BY  
						TagId			
				</cfquery>

				<!--- Set the post count --->
				<cfif arrayLen(getTagPostCount) and isNumeric(getTagPostCount[1]["PostCount"])>
					<cfset postCount = getTagPostCount[1]["PostCount"]>
				<cfelse>
					<cfset postCount = 0>
				</cfif>
				<!--- postCount: <cfoutput>#postCount#</cfoutput> --->

				<!--- Modify the array values and add the post count --->
				<cfset getTags[i]["PostCount"] = postCount>
			</cfloop>
		</cfif><!---<cfif arrayLen(getTags)>--->

		<cfreturn getTags>
		
	</cffunction>
			
	<cffunction name="getTagsForGrid" access="public" returnType="array" output="false" 
			hint="Returns a query containing all of the tags as well as their count for a specified blog. This is used in ProxyController.cfc and the tags grid">
		<cfargument name="tag" type="string" required="false" default="">
		<cfargument name="alias" type="string" required="false" default="">
		<cfargument name="date" type="string" required="false" default="">
			
		<cfset var getTags = []>
		<cfset var getTotal = "">

		<!--- Note: caching may no longer be necessary here as the new ORM logic should fix some of the performance issues of the original ad-hoc BlogCfc query. --->
		<cfif structKeyExists(variables, "tagCache") and arguments.usecache>
			<cfreturn variables.tagCache>
		</cfif>

		<cfquery name="getTags" dbtype="hql">
			SELECT new Map (
				Tag.TagId as TagId,
				Tag.TagUuid as TagUuid,
				Tag.Tag as Tag,
				Tag.TagAlias as TagAlias,
				'' as PostCount,
				Tag.Date as Date
			)
			FROM  
				Tag as Tag
			WHERE 
				0=0
			<cfif arguments.tag neq ''>
				AND Tag.Tag LIKE <cfqueryparam value="%#arguments.tag#%">
			</cfif>
			<cfif arguments.alias neq ''>
				AND Tag.TagAlias LIKE <cfqueryparam value="%#arguments.alias#%">
			</cfif>
			<cfif arguments.date neq ''>
				AND Tag.Date LIKE <cfqueryparam value="%#arguments.date#%">
			</cfif>
				AND Tag.BlogRef = #application.BlogDbObj.getBlogId()#			
		</cfquery>
		<!---<cfdump var="#getCategories#">--->

		<!--- Loop thru the categories and get the post count. The post count is used on some interfaces to show how many posts belong to a given tag. --->
		<cfif arrayLen(getTags)>
			<cfloop from="1" to="#arrayLen(getTags)#" index="i">

				<cfset tagId = getTags[i]["TagId"]>

				<cfquery name="getTagPostCount" dbtype="hql">
					SELECT new Map (
						count(Post.PostId) as PostCount
					)
					FROM  
						PostTagLookup as PostTagLookup
						JOIN PostTagLookup.TagRef as Tag
						JOIN PostTagLookup.PostRef as Post
					WHERE 
						PostTagLookup.TagRef = #tagId#
						AND Released = 1
						AND Post.Remove = 0
						AND Tag.BlogRef = #application.BlogDbObj.getBlogId()#
					GROUP BY  
						Tag.TagId			
				</cfquery>

				<!--- Set the post count --->
				<cfif arrayLen(getTagPostCount)>
					<cfset postCount = getTagPostCount[1]["PostCount"]>
				<cfelse>
					<cfset postCount = 0>
				</cfif>
				<!--- postCount: <cfoutput>#postCount#</cfoutput> --->

				<!--- Modify the array values and add the post count --->
				<cfset getTags[i]["PostCount"] = postCount>
			</cfloop>
		</cfif><!---<cfif arrayLen(getTags)>--->
		
		<cfreturn getTags>
		
	</cffunction>

	<cffunction name="getTagsForPost" access="public" returnType="array" output="false" 
			hint="Returns a array containing all of the categories for a specific blog entry. Used in the adminInterface.cfm and xmlrpc.cfm templates">
		<cfargument name="postId" type="numeric" required="true">
		<cfset var Data = "[]">

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("'#arguments.postId#' does not exist.")>
		</cfif>

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Tag.TagId as TagId,
				Tag.TagUuid as TagUuid, 
				Tag.Tag as Tag
			)
			FROM 
				PostTagLookup as PostTagLookup,
				Tag as Tag
			WHERE 
				PostTagLookup.TagRef = Tag.TagId
				AND PostTagLookup.PostRef = #arguments.postId#		
		</cfquery>

		<cfreturn Data>

	</cffunction>
			
	<cffunction name="getTagsByPostId" access="public" returntype="array" output="false"
		hint="Returns the tags for a given post id. Used in the blogContentHtml.cfm and Blog.cfc templates">	
		<cfargument name="postId" type="numeric" required="true">
			
		<!--- Get the categories. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Tag.TagId as TagId,
				Tag.TagUuid as TagUuid, 
				Tag.Tag as Tag
			)
			FROM 
				PostTagLookup as PostTagLookup,
				Tag as Tag
			WHERE 
				PostTagLookup.TagRef = Tag.TagId
				<!--- Pass in the PostId --->
				AND PostTagLookup.PostRef = #arguments.postId#
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="tagExists" access="private" returnType="boolean" output="false"
			hint="Returns true or false if an entry exists. Used in this cfc and ProxyController.cfc to verify that the category does not exist.">
		<cfargument name="id" type="uuid" required="false">
		<cfargument name="name" type="string" required="false">
		<cfset var checkC = "">

		<!--- must pass either ID or name, but not obth --->
		<cfif (not isDefined("arguments.id") and not isDefined("arguments.name")) or (isDefined("arguments.id") and isDefined("arguments.name"))>
			<cfset variables.utils.throw("tagExists method must be passed id or name, but not both.")>
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT 
				TagId
			FROM Tag
			WHERE 0=0
			<cfif isDefined("arguments.id")>
				AND TagUuid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			<cfif isDefined("arguments.name")>
				AND Tag = <cfqueryparam value="#arguments.name#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset TagFound = true>
		<cfelse>
			<cfset TagFound = false>
		</cfif>
		
		<cfreturn TagFound>

	</cffunction>
			
	<cffunction name="postTagExists" access="private" returnType="boolean" output="false"
			hint="Returns true or false if the relationship between a post and a tag exists. Used to determine whether to insert records into the PostTagLookup table in order to prevent duplicate records.">
		<cfargument name="postId" type="numeric" required="true">
		<!--- Either the tag, tagId or the tagUuid must be sent in --->
		<cfargument name="tag" type="string" default="" required="false">
		<cfargument name="tagId" type="numeric" default="" required="false">
		<cfargument name="tagUuid" type="any" default="" required="false">
			
		<!--- Load the tag object by the tagId  --->
		<cfif len(arguments.tagId) and isNumeric(tagId)>
			<cfset TagRefObj = entityLoadByPK("Tag", arguments.tagId)>
		<cfelseif len(arguments.tag)>
			<!--- Load the tag object by the tag  --->
			<cfset TagRefObj = entityLoad("Tag", { Tag = arguments.tag }, "true" )>
		<cfelseif len(arguments.tagUuid)>
			<!--- Load the tag object with the tag UUID  --->
			<cfset TagRefObj = entityLoad("Tag", { TagUuid = arguments.tagUuid }, "true" )>
		</cfif>
			
		<!--- Get the Post Id--->
		<cfset PostRefObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
			
		<cfif isDefined("TagRefObj") and isDefined("PostRefObj")>
			<cfquery name="Data" dbtype="hql">
				SELECT new Map(
					PostTagLookupId as PostTagLookupId
				)
				FROM PostTagLookup
				WHERE 0=0
					AND TagRef = #TagRefObj.getTagId()#
					AND PostRef = #arguments.postId#
			</cfquery>

			<cfif arrayLen(Data)>
				<cfset postTagExists = true>
			<cfelse>
				<cfset postTagExists = false>
			</cfif>
		<cfelse>
			<cfset postTagExists = false>
		</cfif>
		
		<cfreturn postTagExists>

	</cffunction>
			
	<cffunction name="assignTag" access="public" returnType="numeric" output="false"
			hint="Assigns postId to a Tag">
		<cfargument name="postId" type="numeric" required="true">
		<!--- Either the Tag, TagId or the TagUuid must be sent in --->
		<cfargument name="tag" type="string" default="" required="false">
		<cfargument name="tagId" type="numeric" default="" required="false">
		<cfargument name="tagUuid" type="any" default="" required="false">
		
		<cfset var Data = "">
			
		<!--- Load the Tag object by the TagId  --->
		<cfif len(arguments.tagId) and isNumeric(tagId)>
			<cfset TagRefObj = entityLoadByPK("Tag", arguments.TagId)>
		<cfelseif len(arguments.tag)>
			<!--- Load the tag object by the tag  --->
			<cfset TagRefObj = entityLoad("Tag", { Tag = arguments.tag }, "true" )>
		<cfelseif len(arguments.tagUuid)>
			<!--- Load the tag object with the tag UUID  --->
			<cfset TagRefObj = entityLoad("Tag", { TagUuid = arguments.tagUuid }, "true" )>
		</cfif>
			
		<!--- Get the Post Id--->
		<cfset PostRefObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
		
		<!--- Are both of our objects defined? The entityLoad function will only create an object if the filters match existing records. --->
		<cfif isDefined("TagRefObj") and isDefined("PostRefObj")>
			
			<!--- See if the relationship exists. Note: HQL does not like when the primary keys are in a cfqueryparam tag. Sigh. I think that this is OK here. --->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map(
					PostTagLookupId as PostTagLookupId
				)
				FROM PostTagLookup
				WHERE 0=0
					AND TagRef = #TagRefObj.getTagId()#
					AND PostRef = #arguments.postId#
			</cfquery>

			<cfif arrayLen(Data)>
				<cfreturn Data[1]["PostTagLookupId"]>
			<cfelse><!---<cfif arrayLen(Data)>--->
				<!--- Load the entity. --->
				<cfset PostTagObj = entityNew("PostTagLookup")>
				<!--- Use the entity objects to set the data. --->
				<cfset PostTagObj.setTagRef(TagRefObj)>
				<cfset PostTagObj.setPostRef(PostRefObj)>
				<cfset PostTagObj.setDate(blogNow())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(PostTagObj)>

				<!--- Return the TagId --->
				<cfreturn PostTagObj.getPostTagLookupId()>
			</cfif><!---<cfif arrayLen(Data)>--->
		<cfelse><!---<cfif isDefined("TagRefObj") and isDefined("PostRefObj")>--->
			<!--- Return a zero indicating that something went wrong. The Tag or post does not exist. --->
			<cfreturn 0>
		</cfif><!---<cfif isDefined("TagRefObj") and isDefined("PostRefObj")>--->
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>
				
	</cffunction>

	<cffunction name="assignTags" access="public" returnType="void" output="false"
			hint="Assigns a postId to multiple categories">
		<cfargument name="postId" type="numeric" required="true">
		<cfargument name="tagids" type="string" required="true">

		<cfset var i=0>

		<!--- Loop through categories --->
		<cfloop index="i" from="1" to="#listLen(arguments.tagids)#">
			<cfset assignTag(postId=arguments.postId,tagUuid=listGetAt(tagids,i))>
		</cfloop>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>
			
	<cffunction name="addTag" access="public" returnType="uuid" roles="admin,AddTag,ManageTag" output="true"
			hint="Adds a tag.">
		<cfargument name="name" type="string" required="true">
		<cfargument name="alias" type="string" required="false">

		<cfset var checkC = "">
		<cfset var uuid = createUUID()>

		<cfif tagExists(name="#arguments.name#")>
			<cfset variables.utils.throw("#arguments.name# already exists as a tag.")>
		</cfif>
			
		<!--- Create the alias if it was not sent --->
		<cfif not len(arguments.alias)>
			<!--- If the alias was not sent, create a new SES friendly alias using the tag --->
			<cfset arguments.alias = application.blog.makeAlias(arguments.tag)>
		</cfif>
			
		<cftransaction>
			<!--- Load the blog table and get the first record (there only should be one record). This will pass back an object with the value of the blogId. --->
			<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>
			<!--- Load the entity. --->
			<cfset TagDbObj = entityNew("Tag")>
			<!--- Use the entity objects to set the data. --->
			<cfset TagDbObj.setBlogRef(blogRef)>
			<cfset TagDbObj.setTagUuid(uuid)>
			<cfset TagDbObj.setTagAlias(arguments.alias)>
			<cfset TagDbObj.setTag(arguments.name)>
			<cfset TagDbObj.setDate(blogNow())>

			<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
			<cfset EntitySave(TagDbObj)>
		</cftransaction>
				
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

		<cfreturn id>
	</cffunction>

	<cffunction name="saveTag" access="public" returnType="numeric" output="false"
			hint="Saves a tag.">
		<!--- Pass in the tagId if you want to update the record. The tag is always required. --->
		<cfargument name="tagId" type="any" default="" required="false">
		<cfargument name="tagUuid" type="any" default="" required="false" hint="Used when importing data from previous versions of BlogCfc">
		<cfargument name="tag" type="string" required="true">
		<cfargument name="tagAlias" type="string" default="" required="false">
			
		<!--- Create the alias --->
		<cfif not len(arguments.tagAlias)>
			<!--- If the alias was not sent, create a new SES friendly alias using the tag --->
			<cfset newAlias = application.blog.makeAlias(arguments.tag)>
		<cfelse>
			<!--- Check to see if the alias is formatted properly. --->
			<cfif reFind("[^[:alnum:] -]", arguments.tagAlias)>
				<!--- The alias contains something other than letters, numbers, spaces, or hyphens. Create a new alias using the tag and continue. --->
				<!--- Create a new SES friendly alias using the tag --->
				<cfset newAlias = application.blog.makeAlias(arguments.tag)>
			<cfelse>
				<!--- Use the provided alias --->
				<cfset newAlias = arguments.tagAlias>
			</cfif>
		</cfif>
					
		<!--- See if the record exists --->
		<cfset getTag = this.getTag(tag=arguments.tag)>
		<cfif arrayLen(getTag) and isNumeric(getTag[1]["TagId"])>
			<!--- Set the TagId --->
			<cfset arguments.tagId = getTag[1]["TagId"]>
		</cfif>
		
		<!--- Insert or update the record. --->
		<cfif len(arguments.tagId)>
			<cftransaction>
				<!--- Update the record. --->
				<cfquery name="Data" dbtype="hql">
					UPDATE Tag
					SET
					<cfif len(arguments.tagUuid)>
						TagUuid = <cfqueryparam value="#arguments.tagUuid#" cfsqltype="cf_sql_varchar" maxlength="75">,
					</cfif>
					<cfif len(arguments.tagAlias)>
						TagAlias = <cfqueryparam value="#arguments.tagAlias#" cfsqltype="cf_sql_varchar" maxlength="75">,
					</cfif>
						Tag = <cfqueryparam value="#arguments.tag#" cfsqltype="cf_sql_varchar" maxlength="50">
					WHERE 0=0
						AND TagId = <cfqueryparam value="#arguments.tagId#" cfsqltype="cf_sql_integer">
				</cfquery>
			</cftransaction>
			<cfreturn arguments.tagId>
				
		<cfelse><!---<cfif len(arguments.tagId)>--->
			
			<!--- Insert the record --->
			<cfif len(arguments.tagUuid)>
				<cfset tagUuid = arguments.tagUuid>
			<cfelse>
				<cfset tagUuid = createUUID()>
			</cfif>
			<cftransaction>
				<!--- Create a new tag entity --->
				<cfset TagDbObj = entityNew("Tag")>
				<cfset TagDbObj.setTagUuid(TagUuid)>
				<cfset TagDbObj.setTag(arguments.tag)>
				<cfset TagDbObj.setTagAlias(newAlias)>
				<cfset TagDbObj.setDate(blogNow())> 
				<cfset TagDbObj.setBlogRef(application.BlogDbObj)>
				<!---Save it--->
				<cfset EntitySave(TagDbObj)>
			</cftransaction>
			
			<!--- Return the new Id --->
			<cfreturn TagDbObj.getTagId()>
		
		</cfif><!---<cfif len(arguments.tag)>--->
					
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>
			
	<cffunction name="savePostTags" access="public" returnType="string" output="false"
			hint="Attaches a list of categories to a given post.">
		<!--- Pass in the tagId if you want to update the record. The tag is always required. --->
		<cfargument name="postId" type="any" default="" required="true">
		<cfargument name="tagIdList" type="string" required="true">
			
		<!--- Paramaterize the arguments since these are entities and can't use cfqueryparam. --->
		<cfparam name="thisPostId" default="#arguments.postId#" type="integer" maxlength="9">
		<cfparam name="thisTagIdList" default="#arguments.tagIdList#" type="string" maxlength="35">
		<cfparam name="thisBlogId" default="#application.BlogDbObj.getBlogId()#" type="integer" maxlength="9">
	
		<!---Debugging carriage--->
		<cfset debug = 0>

		<!---******************************************************************************************************** 
			Delete categories that are no longer used
		*********************************************************************************************************--->

		<!--- Note: 'PostTagLookup.TagRef as TagId' alone brings back the entire Tag entity object. --->
		<cfquery name="getTagsNotInList" dbtype="hql">
			SELECT new Map (
				PostTagLookup.TagRef.TagId as TagId
			)
			FROM  
				PostTagLookup as PostTagLookup
				JOIN PostTagLookup.TagRef as Tag
				JOIN PostTagLookup.PostRef as Post
			WHERE 
				PostTagLookup.PostRef = #thisPostId#
				AND PostTagLookup.TagRef NOT IN (#thisTagIdList#)
				AND Post.BlogRef = #thisBlogId#		
		</cfquery>

		<!--- Loop through the recordset and delete these records in the PostTagLookup table. Unfortunately there is no clean way that I know of to get a value list from an Orm query, so we will do this one by one. --->
		<cfif arrayLen(getTagsNotInList)>
			<cfloop from="1" to="#arrayLen(getTagsNotInList)#" index="i">
				<cfset tagId = getTagsNotInList[i]["TagId"]>
				<cfif debug><cfdump var="#tagId#"></cfif>
				<cfquery name="deleteExcessTags" dbtype="hql">
					DELETE
					FROM  
						PostTagLookup as PostTagLookup
					WHERE 
						PostTagLookup.TagRef = #tagId#		
				</cfquery>
			</cfloop>
		</cfif>

		<!---******************************************************************************************************** 
			Determine whether to insert the record
		*********************************************************************************************************--->

		<!--- Loop through the new tag id list --->
		<cfloop list="#tagIdList#" index="i">
			<cfif debug><cfoutput>i: #i#</cfoutput><br/></cfif>

			<!---Reset the getPostTag array prior to making a new query--->
			<cfset getPostTag = []>

			<!--- 
			Determine if this is record is already in the PostTagLookup table. 
			Note: 'PostTagLookup.TagRef as TagId' alone brings back the entire tag entity object. 
			--->
			<cfquery name="getPostTag" dbtype="hql">
				SELECT new Map (
					PostTagLookup.TagRef.TagId as TagId
				)
				FROM  
					PostTagLookup as PostTagLookup
					JOIN PostTagLookup.TagRef as Tag
					JOIN PostTagLookup.PostRef as Post
				WHERE 
					PostTagLookup.PostRef = #thisPostId#
					AND PostTagLookup.TagRef = #i#
					AND Post.BlogRef = #thisBlogId#		
			</cfquery>
			<cfif debug><cfdump var="#getPostTag#"></cfif>

			<!--- If the record is not found, insert it. Otherwise leave the current record intact. --->
			<cfif arrayLen(getPostTag) eq 0>
				<cfif debug>Insert tagId: <cfoutput>#i#</cfoutput></cfif>
				<!--- Load the entities that will be used to populate the PostTagLookup entity --->
				<cfset PostDbObj = entityLoadByPK("Post", postId)>
				<cfset TagDbObj = entityLoadByPK("Tag", i)>

				<!--- Create a new post lookup entity --->
				<cfset PostTagLookupDbObj = entityNew("PostTagLookup")>
				<cfset PostTagLookupDbObj.setPostRef(PostDbObj)>
				<cfset PostTagLookupDbObj.setTagRef(TagDbObj)>
				<cfset PostTagLookupDbObj.setDate(blogNow())>
				<!--- Save it --->
				<<cfset EntitySave(PostTagLookupDbObj)>
			</cfif>

		</cfloop>
					
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>
		
		<cfreturn arguments.tagIdList>

	</cffunction>
					
	<cffunction name="removeTag" access="public" returnType="void" output="false"
			hint="Deletes a relationshp between a post and a tag.">
		<cfargument name="postId" type="numeric" required="true">
		<cfargument name="tagId" type="numeric" required="true">
			
		<!--- Load the post object --->
		<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
		<!--- Load the tag object --->
		<cfset TagDbObj = entityLoad("Tag", { TagUuid = arguments.tagId }, "true" )>
			
		<!--- Delete the record in the lookup table. --->
		<cfquery name="Data" dbtype="hql">
			DELETE FROM PostTagLookup
			WHERE PostRef = #PostDbObj#
			AND TagRef = #TagDbObj#
		</cfquery>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>

	<cffunction name="removeTags" access="public" returnType="void" output="false"
			hint="Remove all tags from an entry.">
		<cfargument name="postId" type="numeric" required="true">
			
		<!--- Load the post object --->
		<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
			
		<!--- Delete the record in the lookup table. --->
		<cfquery name="Data" dbtype="hql">
			DELETE FROM PostTagLookup
			WHERE PostRef = #PostDbObj#
		</cfquery>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>

	<cffunction name="deleteTag" access="public" returnType="void" roles="admin,ManageTags" output="false"
			hint="Deletes a tag.">
		<cfargument name="id" type="uuid" required="true">
			
		<!--- Load the tag entity by the TagUuid --->
		<cfset TagDbObj = entityLoad("Tag", { TagUuid = arguments.id }, "true" )>
		<!--- Delete this record --->
		<cfset EntityDelete(TagDbObj)>
		<!--- And delete the variable to ensure that the record is deleted from ORM memory. --->
		<cfset void = structDelete( variables, "TagDbObj" )>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>
			
	<!--- //************************************************************************************************************
			Comments
	//**************************************************************************************************************--->

	<cffunction name="getComment" access="public" returnType="array" output="false"
			hint="Gets a specific comment by the commentId.">
		<cfargument name="commentId" type="numeric" required="true">
		
		<cfset var Data = "[]">
			
		<cftransaction>
			
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					Comment.CommentId as CommentId,
					Post.PostId as PostId,
					Post.PostUuid as PostUuid,
					Post.Title as PostTitle,
					Post.PostAlias as PostAlias,
					Comment.CommentUuid as CommentUuid,
					Comment.Comment as Comment,
					User.UserName as UserName,
					Commenter.FullName as CommenterFullName,
					Commenter.Email as CommenterEmail,
					Commenter.Website as CommenterWebsite,
					Comment.DatePosted as DatePosted,
					Comment.Subscribe as Subscribe,
					Comment.Moderated as Moderated,
					Comment.Approved as Approved,
					Comment.Promote as Promote,
					Comment.Hide as Hide,
					Comment.Spam as Spam,
					Comment.Remove as Remove
				)
				FROM 
					Comment as Comment
					LEFT OUTER JOIN Comment.UserRef as User
					LEFT OUTER JOIN Comment.CommenterRef as Commenter
					JOIN Comment.PostRef as Post
				WHERE 0 = 0
					AND Comment.CommentId = <cfqueryparam value="#arguments.commentId#" cfsqltype="integer">
			</cfquery>
			
		</cftransaction>

		<cfreturn Data>

	</cffunction>
			
	<cffunction name="getCommentByDate" access="public" returnType="array" output="true"
			hint="Gets a specific comment by the date including milliseconds.">
		<cfargument name="datePosted" type="string" required="true">
		
		<cfset var Data = "[]">
			
		<cftransaction>
			
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					Comment.CommentId as CommentId,
					Post.PostId as PostId,
					Post.PostUuid as PostUuid,
					Post.Title as PostTitle,
					Post.PostAlias as PostAlias,
					Comment.CommentUuid as CommentUuid,
					Comment.Comment as Comment,
					User.UserName as UserName,
					Commenter.FullName as CommenterFullName,
					Commenter.Email as CommenterEmail,
					Commenter.Website as CommenterWebsite,
					Comment.DatePosted as DatePosted,
					Comment.Subscribe as Subscribe,
					Comment.Moderated as Moderated,
					Comment.Approved as Approved,
					Comment.Promote as Promote,
					Comment.Hide as Hide,
					Comment.Spam as Spam,
					Comment.Remove as Remove
				)
				FROM 
					Comment as Comment
					LEFT OUTER JOIN Comment.UserRef as User
					LEFT OUTER JOIN Comment.CommenterRef as Commenter
					JOIN Comment.PostRef as Post
				WHERE 0 = 0
					<!--- Note: this does not work with a cfqueryparam. I have tried everything trying to match a certain date/time with ORM and a cfquery parmams- its probably a stupid CF ORM thing. I have some validation below --->
				<cfif len(datePosted) lt 125 and isSimpleValue(datePosted)>
					AND Comment.DatePosted = '#dateTimeFormat(arguments.datePosted, "medium")#'
				</cfif>
			</cfquery>
			
		</cftransaction>

		<cfreturn Data>

	</cffunction>

	<cffunction name="getComments" access="public" returnType="array" output="false"
			hint="Gets comments by a variety of options">
		<cfargument name="postId" type="numeric" required="false">
		<cfargument name="commentId" type="numeric" required="false">
		<cfargument name="commenterFullName" required="no" default="">
		<cfargument name="CommenterFullNameLike" required="no" default="">	
		<cfargument name="postTitle" required="no" default="">
		<cfargument name="datePosted" required="no" default="">
		<cfargument name="approved" required="no" default="">
		<cfargument name="subscribe" required="no" default="">
		<cfargument name="hide" required="no" default="">
		<!--- Calculated logic --->
		<cfargument name="new" required="no" default="">
		<cfargument name="commentLike" type="string" required="false" default="">
		<cfargument name="sortDir" type="string" required="false" default="asc">

		<cfset var getC = "">
		<cfset var getO = "">

		<cfif structKeyExists(arguments, "postId") and not postExists(arguments.postId)>
			<cfset variables.utils.throw("'#arguments.postId#' does not exist.")>
		</cfif>

		<cfif arguments.sortDir is not "asc" and arguments.sortDir is not "desc">
			<cfset arguments.sortDir = "asc">
		</cfif>
			
		<cfset var Data = "[]">
			
		<!--- Note: ambiguous columns will not show up in the error message. Instead, you will see an 'org.hibernate.hql.internal.ast.QuerySyntaxException: unexpected token:' error. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Comment.CommentId as CommentId,
				Post.PostId as PostId,
				Post.PostUuid as PostUuid,
				Post.Title as PostTitle,
				Post.AllowComment as AllowComment,
				Post.PostAlias as PostAlias,
				Comment.CommentUuid as CommentUuid,
				Comment.Comment as Comment,
				User.UserName as UserName,
				Commenter.FullName as CommenterFullName,
				Commenter.Email as CommenterEmail,
				Commenter.Website as CommenterWebsite,
				Comment.DatePosted as DatePosted,
				Comment.Subscribe as Subscribe,
				Comment.Moderated as Moderated,
				Comment.Approved as Approved,
				Comment.Promote as Promote,
				Comment.Hide as Hide,
				Comment.Spam as Spam,
				Comment.Remove as Remove
			)
			FROM 
				Comment as Comment
				LEFT OUTER JOIN Comment.UserRef as User
				LEFT OUTER JOIN Comment.CommenterRef as Commenter
				JOIN Comment.PostRef as Post
			WHERE 0 = 0
				AND Comment.Remove <> <cfqueryparam value="1" cfsqltype="cf_sql_bit">
				AND Comment.Spam <> <cfqueryparam value="1" cfsqltype="cf_sql_bit">
			<cfif structKeyExists(arguments, "postId") and len(arguments.postId)>
				AND Post.PostId = <cfqueryparam value="#arguments.postId#" cfsqltype="cf_sql_integer" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments, "commentId") and len(arguments.commentId)>
				AND Comment.CommentId = <cfqueryparam value="#arguments.commentId#" cfsqltype="cf_sql_integer" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments, "commenterFullName") and len(arguments.commenterFullName)>
				AND Commenter.FullName = <cfqueryparam value="#arguments.commenterFullName#" cfsqltype="cf_sql_varchar" maxlength="210">
			</cfif>
			<cfif structKeyExists(arguments, "commenterFullNameLike") and len(arguments.commenterFullNameLike)>
				AND Commenter.FullName LIKE <cfqueryparam value="%#arguments.CommenterFullName#%" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif structKeyExists(arguments, "postTitle") and len(arguments.postTitle)>
				AND Post.Title = <cfqueryparam value="#arguments.postTitle#" cfsqltype="cf_sql_varchar" maxlength="210">
			</cfif>
			<cfif structKeyExists(arguments, "datePosted") and len(arguments.datePosted)>
				AND Comment.DatePosted = <cfqueryparam value="#arguments.datePosted#" cfsqltype="cf_sql_varchar" maxlength="210">
			</cfif>
			<cfif structKeyExists(arguments, "approved") and len(arguments.approved)>
				AND Comment.Approved = <cfqueryparam value="#arguments.approved#" cfsqltype="cf_sql_boolean" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments, "moderated") and len(arguments.moderated)>
				AND Comment.Moderated = <cfqueryparam value="#arguments.moderated#" cfsqltype="cf_sql_boolean" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments, "subscribe") and len(arguments.subscribe)>
				AND Comment.Subscribe = <cfqueryparam value="#arguments.subscribe#" cfsqltype="cf_sql_boolean" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments, "hide") and len(arguments.hide)>
				AND Comment.Hide = <cfqueryparam value="#arguments.hide#" cfsqltype="cf_sql_boolean" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments, "new") and len(arguments.new)>
				AND Comment.Approved IS NULL
			</cfif>
			<cfif structKeyExists(arguments, "commentLike") and len(arguments.commentLike)>
				AND Comment.Comment LIKE <cfqueryparam value="%#arguments.commentLike#%" cfsqltype="cf_sql_varchar">
			</cfif>
				AND Comment.BlogRef = #application.BlogDbObj.getBlogId()#
				ORDER BY 
					Comment.DatePosted, 
					Post.Title,
					Commenter.FullName
					#arguments.sortdir#
		</cfquery>

		<cfreturn Data>

	</cffunction>
				
	<cffunction name="getRecentCommentCount" access="public" returnType="numeric"  output="false"
			hint="Gets the number of recent comments that are not yet approved. This is used on the admin page to determine to prompt the admin to approve new comments.">

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				count(CommentId) as CommentCount
			)
			FROM Comment
			WHERE 
				Comment.Approved IS NULL
		</cfquery>	

		<cfif arrayLen(Data)>
			<cfset commentCount =  Data[1]["CommentCount"]>
		<cfelse>
			<cfset commentCount = 0>
		</cfif>
	
		<cfreturn CommentCount>
	</cffunction>
				
	<cffunction name="getCommentCountByPostId" access="public" returntype="numeric" output="false"
		hint="Returns number of comments for a postId.">	
		<cfargument name="postId" type="numeric" required="true">
		<!--- Get the number of comments --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				count(Comment.CommentId) as CommentCount
			)
			FROM Post as Post 
			LEFT JOIN Post.Comments as Comment
			WHERE 0=0
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				AND Post.PostId = #arguments.postId#
		</cfquery>
			
		<cfreturn Data[1]["CommentCount"]>
			
	</cffunction>
	
	<!--- Get the comment count for a given post --->
	<cffunction name="getCommentCount" access="public" returnType="numeric"  output="false"
				hint="Gets the total number of comments for a blog entry">
		<cfargument name="id" type="numeric" required="true">

			<cfquery name="Data" dbtype="hql">
				SELECT  new Map (
					count(CommentId) as CommentCount
				)
				FROM Comment
				WHERE 
					PostRef = #arguments.id#
				<cfif instance.moderate>
					AND Moderated = 1
				</cfif>
					AND Subscribe = 0 OR Subscribe IS NULL
			</cfquery>	
			
			<cfif arrayLen(Data)>
				<cfset CommentCount =  Data[1]["CommentCount"]>
			<cfelse>
				<cfset CommentCount = 0>
			</cfif>
	
		<cfreturn CommentCount>
	</cffunction>
				
	<cffunction name="getUnmoderatedComments" access="public" returnType="array" output="false"
				hint="Gets unmoderated comments for an entry.">
		<cfargument name="id" type="numeric" required="false">
		<cfargument name="sortdir" type="string" required="false" default="asc">

		<cfset var Data = "[]">

		<cfif structKeyExists(arguments, "id") and not postExists(arguments.id)>
			<cfset variables.utils.throw("'#arguments.id#' does not exist.")>
		</cfif>

		<cfif arguments.sortDir is not "asc" and arguments.sortDir is not "desc">
			<cfset arguments.sortDir = "asc">
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				<!--- Note: ambiguous columns will not show up in the error message. Instead, you will see an 'org.hibernate.hql.internal.ast.QuerySyntaxException: unexpected token:' error. --->
				Comment.CommentId as CommentId,
				Post.PostId as PostId,
				Post.PostUuid as PostUuid,
				Post.Title as Title,
				Comment.CommentUuid as CommentUuid,
				Comment.Comment as Comment,
				User.UserName as UserName,
				Commenter.FullName as CommenterFullName,
				Commenter.Website as Website,
				Comment.DatePosted as DatePosted,
				Comment.Subscribe as Subscribe,
				Comment.Moderated as Moderated,
				Comment.Approved as Approved,
				Comment.Promote as Promote,
				Comment.Hide as Hide,
				Comment.Spam as Spam,
				Comment.Remove as Remove
			)
			FROM 
				Comment as Comment
				<!--- A comment can have either a User or a Commenter. --->
				LEFT OUTER JOIN Comment.UserRef as User
				LEFT OUTER JOIN Comment.CommenterRef as Commenter
				JOIN Comment.PostRef as Post
			WHERE 0=0
			<cfif structKeyExists(arguments, "id")>
				CommentUuid = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			</cfif>
				AND Comment.Moderated = <cfqueryparam value="1" cfsqltype="bit">
				<!--- This was not present in the original BlogCfc, I added it. There is a very tiny and miniscule chance that a duplicate UUID may be formed and it is an easy line to add. --->
				AND Comment.BlogRef = #application.BlogDbObj.getBlogId()#
			ORDER BY Post.DatePosted #arguments.sortdir#
		</cfquery>

		<cfreturn Data>

	</cffunction>
				
	<cffunction name="addComment" access="public" returnType="numeric" output="false"
		hint="Adds a comment.">
		
		<cfargument name="postId" type="numeric" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="email" type="string" required="true">
		<cfargument name="website" type="string" required="true">
		<cfargument name="comments" type="string" required="true">
		<cfargument name="user" type="string" required="false" default="">
		<cfargument name="ipAddress" type="string" required="false" default="">
		<cfargument name="httpUserAgent" type="string" required="false" default="">
		<cfargument name="subscribe" type="boolean" required="true">
		<cfargument name="subscribeOnly" type="boolean" required="false" default="false">
		<cfargument name="overrideModeration" type="boolean" required="false" default="false">
		<cfargument name="sendEmail" type="boolean" required="false" default="true" hint="Sometimes you will want to override sending email out, for example, when importing data when upgrading to a newer version of the blog">
		<cfargument name="datePosted" cfsqltype="cf_sql_varchar" maxlength="210" required="false" default="">
			
		<!---//*****************************************************************************************
			Prepare the arguments
		//******************************************************************************************--->
			
		<cfset var newUuid = createUUID()>
		<cfset var entry = "">
		<cfset var spam = "">
		<cfset var kill = createUUID()>

		<!--- 
		With the new kendo editor, we are not using htmlEditFormat to store the comments. 
		<cfset arguments.comments = htmleditformat(arguments.comments)>
		--->
		<cfset arguments.comments = htmleditformat(arguments.comments)>
		<cfset arguments.name = left(htmlEditFormat(arguments.name),125)>
		<cfset arguments.email = left(htmlEditFormat(arguments.email),125)>
		<cfset arguments.website = left(htmlEditFormat(arguments.website),255)>

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("#arguments.postId# is not a valid entry.")>
		</cfif>

		<!--- Get the entry so we can check for allowcomments ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
		<cfset getPost = getPostByPostId(arguments.postId,false,false)>
		<cfif not getPost[1]["AllowComment"]>
			<cfset variables.utils.throw("#arguments.postId# does not allow for comments.")>
		</cfif>

		<!--- Check the spam list if the user made an actual comment and is just not subsribing to a post --->
		<cfif not arguments.subscribeOnly>
			<!--- check spam and IPs --->
			<cfloop index="spam" list="#instance.trackbackspamlist#">
				<cfif findNoCase(spam, arguments.comments) or
					  findNoCase(spam, arguments.name) or
					  findNoCase(spam, arguments.website) or
					  findNoCase(spam, arguments.email)>
					<cfset variables.utils.throw("Comment blocked for spam.")>
				</cfif>
			</cfloop>
			<cfloop list="#instance.ipblocklist#" index="spam">
				<cfif spam contains "*" and reFindNoCase(replaceNoCase(spam, '.', '\.','all'), cgi.REMOTE_ADDR)>
					<cfset variables.utils.throw("Comment blocked for spam.")>
				<cfelseif spam is cgi.REMOTE_ADDR>
					<cfset variables.utils.throw("Comment blocked for spam.")>
				</cfif>
	      	</cfloop>
		</cfif>
					
		<!--- Convert the subscribe to a boolean value --->
		<cfif arguments.subscribe>
			<cfset arguments.subscribe = 1>
		<cfelse>
			<cfset arguments.subscribe = 0>
		</cfif>
			
		<!--- The comment will be automatically approved if: the admin created the subscription: blog moderation is not turned on and: the override argument is set to false. --->
		<cfif not application.Udf.isLoggedIn() and instance.moderate and not arguments.overrideModeration>
			<cfset approved = 0>
		<cfelse>
			<cfset approved = 1>
		</cfif>	
			
		<!--- See if the comment exists. This gets the comment to the millisecond. --->
		<cfset getComment = this.getCommentByDate(datePosted=arguments.datePosted)>
		<cfif not arrayLen(getComment)>
		
			<!--- Wrap the db code with a transaction tag. --->

			<!---//************************************************************************************************************
				Save the user or commenter
			//*********************************************************************************************************--->

			<!--- Notes:
			I need to set the unique argument in order to load an entity that allows me to use its set methods to save the data, however, there may  be more than one row. I could use the additional maxresults argument to limit the records to one record, however, it does not work when supplying the unique argument. 
			I will get around these barriers by using a hql query to get the top record in the commenter table and using the primary key to load the entity. --->

			<!--- Is the user logged in and defined? --->
			<cfif arguments.user neq "">

				<!--- Get the top record that matches the email in the commenter table. --->
				<cfquery name="getUser" dbtype="hql" ormoptions="#{maxresults=1}#">		
					SELECT new Map (
						UserId as UserId)
					FROM Users as Users 
					WHERE Email = <cfqueryparam value="#arguments.email#">
					AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				</cfquery>

				<!--- If there are existing records, load the Comment object by the primary key. --->
				<cfif arrayLen(getUser)>
					<cfset UserRefDbObj = EntityLoadByPK("Users", getUser[1]["UserId"])>
				<!--- If the commenter was not found, create a new commenter object. --->
				<cfelse>
					<cfset UserRefDbObj = entityNew("Users")>
				</cfif>

			<!--- Handle commenter and post subscribers --->
			<cfelse><!---<cfif arguments.user neq "">--->

				<!--- Get the top record that matches the email in the commenter table. --->
				<cfquery name="getCommenter" dbtype="hql" ormoptions="#{maxresults=1}#">		
					SELECT new Map (
						CommenterId as CommenterId)
					FROM Commenter as Commenter 
					WHERE Email = <cfqueryparam value="#arguments.email#">
				</cfquery>

				<!--- If there are existing records, load the Comment object by the primary key. --->
				<cfif arrayLen(getCommenter)>
					<cfset CommenterRefDbObj = EntityLoadByPK("Commenter", getCommenter[1]["CommenterId"])>
				<!--- If the commenter was not found, create a new commenter object. --->
				<cfelse>
					<cfset CommenterRefDbObj = entityNew("Commenter")>
				</cfif>

			</cfif><!---<cfif arguments.user neq "">--->

			<!--- Capture the IP address and save it into the IpAddress table. We will capture all IP addresses for comments in order to build a more secure moderation system. Note: this can be an annonymous commenter or a known user --->	
			<cfif len(CommenterRefDbObj.getCommenterId()) or len(arguments.user) and len(UserRefDbObj.getUserId())>
				<!--- If the commenter exists, get the top record that matches the Ip address, commenter, and user agent in the IP adress table. 
				Note: we can't put a cfqueryparam on columns that have a field type as these columns expect objects.--->
				<cfquery name="getIpAddress" dbtype="hql" ormoptions="#{maxresults=1}#">		
					SELECT new Map (
						IpAddressId as IpAddressId)
					<!--- Prefix the IP address table name as it will conflict with the identical column name. --->
					FROM IpAddress as tblIpAddress 
				<cfif isDefined("UserRefDbObj") and len(UserRefDbObj.getUserId())>
					WHERE UserRef = #CommenterRefDbObj.getCommenterId()#
				<cfelseif isDefined("CommenterRefDbObj") and len(CommenterRefDbObj.getCommenterId())>
					WHERE CommenterRef = #CommenterRefDbObj.getCommenterId()#
				</cfif>
					AND IpAddress = <cfqueryparam value="#arguments.ipAddress#">
					AND HttpUserAgent = <cfqueryparam value="#arguments.httpUserAgent#">
					ORDER BY Date ASC
				</cfquery>

				<cfif arrayLen(getIpAddress)>
				<!--- Load the Ip adress object --->
					<cfset IpAddressDbObj = entityLoadByPk("IpAddress", getIpAddress[1]["IpAddressId"] )>
				<cfelse>
					<!--- If the commenter or user was not found, load the Ip address object --->
					<cfset IpAddressDbObj = entityNew("IpAddress")>
				</cfif>
			<cfelse><!---<cfif len(CommenterRefDbObj.getCommenterId()) or len(UserRefDbObj.getUserId())>--->
				<!--- create a new Ip address object. --->
				<cfset IpAddressDbObj = entityNew("IpAddress")>
			</cfif><!---<cfif len(CommenterRefDbObj.getCommenterId()) or len(UserRefDbObj.getUserId())>--->

			<cftransaction>

				<!--- Save the user id, ip address and user agent --->
				<cfif isDefined("UserRefDbObj")>
					<cfset IpAddressDbObj.setCommenterRef(UserRefDbObj)>
				</cfif>
				<cfif isDefined("CommenterRefDbObj")>
					<cfset IpAddressDbObj.setCommenterRef(CommenterRefDbObj)>
				</cfif>
				<cfset IpAddressDbObj.setIpAddress(arguments.ipAddress)>
				<cfset IpAddressDbObj.setHttpUserAgent(arguments.httpUserAgent)>
				<cfset IpAddressDbObj.setDate(blogNow())>
				<!--- And finally, save the fullname, email, website, ip address and user agent of the person whom made the comment or the person subscri bing to the post. --->
				<cfset CommenterRefDbObj.setFullName(arguments.name)>
				<cfset CommenterRefDbObj.setEmail(arguments.email)>
				<cfset CommenterRefDbObj.setWebsite(arguments.website)>
				<cfset CommenterRefDbObj.setIpAddress(arguments.ipAddress)>
				<cfset CommenterRefDbObj.setHttpUserAgent(arguments.httpUserAgent)>
				<cfset CommenterRefDbObj.setDate(blogNow())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<!--- Save the Ip adress entity --->
				<cfset EntitySave(IpAddressDbObj)>
				<!--- Save the commenter entity --->
				<cfset EntitySave(CommenterRefDbObj)>

				<!---//**************************************************************************************************************************
					Save the comment
				//************************************************************************************************--->

				<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
				<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>
				<!--- Get the post ref --->
				<cfset PostRefDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
				<!--- Create a new comment entity. --->
				<cfset CommentDbObj = entityNew("Comment")>

				<!--- Use the entity objects to set the data. --->
				<cfset CommentDbObj.setBlogRef(BlogDbObj)>
				<cfset CommentDbObj.setPostRef(PostRefDbObj)>
				<cfif isDefined("UserRefDbObj")>
					<!--- Set the user ref. The UserRef is only defined when the administrator is logged in. --->
					<cfset CommentDbObj.setUserRef(UserRefDbObj)>
				<cfelse>
					<!--- Set the commenter ref --->
					<cfset CommentDbObj.setCommenterRef(CommenterRefDbObj)>
				</cfif>
				<cfset CommentDbObj.setComment(arguments.comments)>
				<!--- ParentCommentRef is null right now. I will not use it in this version. --->
				<cfset CommentDbObj.setCommentUuid(newUuid)>
				<cfset CommentDbObj.setComment(arguments.comments)>
				<cfif len(arguments.datePosted)>
					<cfset CommentDbObj.setDatePosted(arguments.datePosted)>
				<cfelse>
					<cfset CommentDbObj.setDatePosted(application.blog.blogNow())>
				</cfif>
				<cfset CommentDbObj.setSubscribe(arguments.subscribe)>
				<cfset CommentDbObj.setApproved(approved)>
				<cfset CommentDbObj.setPromote(0)>	
				<cfset CommentDbObj.setHide(0)>		
				<!--- KillComment in BlogCfc is a UUID for some odd reason. I'm going to set this to false. --->
				<cfset CommentDbObj.setRemove(false)>	
				<cfset CommentDbObj.setDate(application.blog.blogNow())>

				<!---//*****************************************************************************************
					If the commenter unsubscribes from one comment, unsubscribe the commenter from all comments in this particular post.
				//******************************************************************************************--->
				<cfif not arguments.subscribe and len(CommenterRefDbObj.getCommenterId())>

					<cfquery name="Data" dbtype="hql">
						UPDATE Comment
						SET 
							Subscribe = false
						WHERE 
							PostRef = #PostRefDbObj.getPostId()#
							AND CommenterRef = #CommenterRefDbObj.getCommenterId()#
					</cfquery>
				</cfif><!---<cfif not arguments.subscribe>--->

				<!--- And save the comment entity --->
				<!---<cfset Post.addComment(CommentDbObj)>--->
				<cfset EntitySave(CommentDbObj)>

			</cftransaction>	

			<!--- Send out email to the subscribers if the comment was approved and the sendEmail argument is true (which it is by default). --->
			<cfif approved and arguments.sendEmail>

				<!--- Get the commentId from the entity --->
				<cfset commentId = CommentDbObj.getCommentId()>
				<!--- Get the comment. The comment table will have the postId --->
				<cfset getComment = application.blog.getComment(commentId=commentId)>
				<!--- Get all post subscribers --->
				<cfset getPostSubscribers = application.blog.getSubscribers(postId=postId, verifiedOnly=true)>

				<!--- Loop through the post subscribers --->
				<cfloop from="1" to="#arrayLen(getPostSubscribers)#" index="i">

					<!--- Set the recipient --->
					<cfset emailTo = getPostSubscribers[1]["SubscriberEmail"]>

					<!--- Render the email --->
					<cfinvoke component="#RendererObj#" method="renderCommentEmailToPostSubscribers" returnvariable="postSubscriberEmail">
						<cfinvokeargument name="commentId" value="#commentId#">
						<cfinvokeargument name="emailTo" value="#emailTo#">
					</cfinvoke>

					<!--- Email the rendered content to the post subscribers --->
					<cfset application.utils.mail(
						to=#emailTo#,
						subject="Message sent via #application.BlogDbObj.getBlogTitle()#",
						body=postSubscriberEmail)>

				</cfloop>

			</cfif><!---<cfif arguments.approved>--->

			<!--- Return the commentId --->
			<cfreturn CommentDbObj.getCommentId()>
			
		<cfelse>
			<!---Return the existing commentId --->
			<cfreturn getComment[1]["CommentId"]>
		</cfif>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>
		
	</cffunction>
				
	<cffunction name="approveComment" access="public" returnType="void" output="false"
			hint="Approves a comment.">
		<cfargument name="commentid" type="uuid" required="true">
			
		<!--- Load the comment entity. --->
		<cfset CommentDbObj = entityLoad("Comment", { CommentUuid = arguments.commentid }, "true" )>
		<!--- Use the entity objects to set the data. --->
		<cfset CommentDbObj.setApproved(1)>
		<cfset CommentDbObj.setDate(blogNow())>

		<!--- Save it. --->
		<cfset EntitySave(CommentDbObj)>
			
		<!--- Send an email to the post subscribers. --->
		<!--- Get the commentId from the entity --->
		<cfset commentId = arguments.commentId>
		<!--- Get the comment. The comment table will have the postId --->
		<cfset getComment = application.blog.getComment(commentId=commentId)>
		<!--- Get all post subscribers --->
		<cfset getPostSubscribers = application.blog.getSubscribers(postId=getComment[1]["PostId"], verifiedOnly=true)>

		<!--- Loop through the post subscribers --->
		<cfloop from="1" to="#arrayLen(getPostSubscribers)#" index="i">

			<!--- Set the recipient --->
			<cfset emailTo = getPostSubscribers[1]["SubscriberEmail"]>

			<!--- Render the email --->
			<cfinvoke component="#RendererObj#" method="renderCommentEmailToPostSubscribers" returnvariable="postSubscriberEmail">
				<cfinvokeargument name="commentId" value="#commentId#">
				<cfinvokeargument name="emailTo" value="#emailTo#">
			</cfinvoke>

			<!--- Email the rendered content to the post subscribers --->
			<cfset application.utils.mail(
				to=#emailTo#,
				subject="Message sent via #application.BlogDbObj.getBlogTitle()#",
				body=postSubscriberEmail)>

		</cfloop>
					
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>
			
	<cffunction name="deleteComment" access="public" returnType="void" roles="admin,ReleaseEntries" output="false"
			hint="Deletes a comment based on the comment's uuid.">
		<cfargument name="id" type="uuid" required="true">
			
		<!--- Load the comment entity by the CommentUuid --->
		<cfset CommentDbObj = entityLoad("Comment", { CommentUuid = arguments.id }, "true" )>
		<!--- Delete this record --->
		<cfset EntityDelete(CommentDbObj)>
		<!--- And delete the variable to ensure that the record is deleted from ORM memory. --->
		<cfset void = structDelete( variables, "CommentDbObj" )>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>

	</cffunction>

	<cffunction name="getProperties" access="public" returnType="struct" output="false">
		<cfreturn duplicate(instance)>
	</cffunction>

	<cffunction name="getProperty" access="public" returnType="any" output="false">
		<cfargument name="property" type="string" required="true">

		<cfif not structKeyExists(instance,arguments.property)>
			<cfset variables.utils.throw("#arguments.property# is not a valid property.")>
		</cfif>

		<cfreturn instance[arguments.property]>

	</cffunction>
			
	<!---******************************************************************************************************** 
		Subscribers
	*********************************************************************************************************--->
			
	<cffunction name="hasSubscriberBeenVerified" access="public" returnType="boolean" output="false"
			hint="Determines if a subscriber has previously been verified. We don't  want to have a subsriber re-verify themselves everytime they want to subscribe to a post.">
		<cfargument name="subscriberEmail" type="string" required="true" default="">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				SubscriberId as SubscriberId
			)
			FROM Subscriber	
			WHERE SubscriberEmail = <cfqueryparam value="#arguments.subscriberEmail#" cfsqltype="cf_sql_varchar">
			AND SubscriberVerified = <cfqueryparam value="1" cfsqltype="cf_sql_bit">
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset subscriberVerified = true>
		<cfelse>
			<cfset subscriberVerified = false>
		</cfif>

		<cfreturn subscriberVerified>
	</cffunction>
			
	<cffunction name="getSubscriberEmailList" access="public" returnType="string" output="false"
			hint="Returns a list of all people subscribed to the blog.">
		
		<cfparam name="subscriberEmailList" default="" type="string">
			
		<!--- Get the data.--->
		<cfinvoke method="getSubscribers" returnVariable="Data">
			<cfinvokeargument name="verifiedOnly" value="false">
		</cfinvoke>

		<!--- Loop through the data and build the list --->
		<cfif arrayLen(Data)>
			<!--- Loop through the array and set the subscribe flag to false.--->
			<cfloop from="1" to="#arrayLen(Data)#" index="i">
				<cfset subscriberEmailList = listAppend(subscriberEmailList, Data[i]["SubscriberEmail"])>
			</cfloop>
		</cfif>
			
		<cfreturn subscriberEmailList>
			
	</cffunction>
			
	<cffunction name="getSubscribers" access="public" returnType="array" output="false"
			hint="Returns all people subscribed to the blog.">
		<cfargument name="subscriberId" type="string" required="false" default="">
		<cfargument name="postId" type="string" required="false" default="">
		<cfargument name="subscriberEmail" type="string" required="false" default="">
		<cfargument name="subscriberToken" type="string" required="false" default="">
		<cfargument name="verifiedOnly" type="boolean" required="false" default="false">
		<cfargument name="subscribeAll" type="boolean" required="false" default="true">
		<cfargument name="active" type="boolean" required="false" default="true">
		
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT new Map (
				SubscriberId as SubscriberId,
				SubscriberEmail as SubscriberEmail,
				SubscriberToken as SubscriberToken,
				SubscriberVerified as SubscriberVerified,
				SubscribeAll as SubscribeAll,
				PostRef as PostRef
			)
			FROM Subscriber as Subscriber 
			WHERE 0=0
				<!---AND SubscriberId = 3--->
				AND SubscriberEmail <> ''
				AND SubscriberToken <> ''
			<cfif len(arguments.subscriberId)>
				AND SubscriberId = <cfqueryparam value="#arguments.subscriberId#" cfsqltype="cf_sql_integer">
			</cfif>
			<cfif len(arguments.postId)>
				<!--- Validate the postId. This is an object so we can't use a cfqueryparam --->
				<cfif isValid("integer", arguments.postId)> 
					AND PostRef = #arguments.postId#
				</cfif>
			</cfif>
			<cfif len(arguments.subscriberEmail)>
				AND SubscriberEmail LIKE <cfqueryparam value="%#arguments.subscriberEmail#%" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif len(arguments.subscriberToken)>
				AND SubscriberToken = <cfqueryparam value="#arguments.subscriberToken#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif len(arguments.subscribeAll)>
				AND SubscribeAll = <cfqueryparam value="#arguments.subscribeAll#" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif arguments.verifiedOnly>
				AND SubscriberVerified = <cfqueryparam value="1" cfsqltype="cf_sql_bit">
			</cfif>
			ORDER BY SubscriberEmail
		</cfquery>

		<cfreturn Data>
	</cffunction>
				
	<cffunction name="getSubscriber" access="public" returnType="array" output="false"
			hint="Get the subscriber details.">
		<cfargument name="subscriberId" type="string" required="false" default="">
		<cfargument name="postId" type="string" required="false" default="">
		<cfargument name="subscriberEmail" type="string" required="false" default="">
		<cfargument name="subscriberToken" type="string" required="false" default="">
		<cfargument name="verifiedOnly" type="boolean" required="false" default="false">
		<cfargument name="subscribeAll" type="boolean" required="false" default="true">
		<cfargument name="active" type="boolean" required="false" default="true">
		
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT new Map (
				SubscriberId as SubscriberId,
				SubscriberEmail as SubscriberEmail,
				SubscriberToken as SubscriberToken,
				SubscriberVerified as SubscriberVerified,
				SubscribeAll as SubscribeAll,
				Date as Date,
				Active as Active
			)
			FROM Subscriber	
			WHERE 0=0
			<cfif len(arguments.subscriberId)>
				AND SubscriberId = <cfqueryparam value="#arguments.subscriberId#" cfsqltype="cf_sql_integer">
			</cfif>
			<cfif len(arguments.subscriberEmail)>
				AND SubscriberEmail = <cfqueryparam value="#arguments.subscriberEmail#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif len(arguments.subscriberToken)>
				AND SubscriberToken = <cfqueryparam value="#arguments.subscriberToken#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.verifiedOnly>
				AND SubscriberVerified = <cfqueryparam value="#arguments.verifiedOnly#" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif len(arguments.subscribeAll)>
				AND SubscribeAll = <cfqueryparam value="#arguments.subscribeAll#" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif len(arguments.postId)>
				<!--- Validate the postId. This is an object so we can't use a cfqueryparam --->
				<cfif isValid("integer", arguments.postId)> 
					AND PostRef = #arguments.postId#
				</cfif>
			</cfif>
			<cfif len(arguments.active)>
				AND Active = <cfqueryparam value="#arguments.active#" cfsqltype="cf_sql_bit">
			</cfif>
				AND BlogRef = #application.BlogDbObj.getBlogId()#
			ORDER BY SubscriberEmail
		</cfquery>

		<cfreturn Data>
	</cffunction>
			
	<cffunction name="addSubscriber" access="public" returnType="string" output="true"
			hint="Adds a subscriber to the blog.">
		<cfargument name="email" type="string" required="true">
		<cfargument name="postId" type="string" required="false" default="" hint="Allows a user to subscribe to a particular post. Only used when the user clicks on the subscribe button for a post.">
			
		<cfset var token = createUUID()>
		<cfset var Data = "">
			
		<!--- Load the post object if the user is only subscribing to a post. --->
		<cfif len(arguments.postId)>
			<!--- Verify the postId --->
			<cfif isValid("integer", arguments.postId)> 
				<!--- Load the post entity --->
				<cfset PostDbObj = entityLoadByPK("Post", postId)>
			</cfif>
		</cfif>

		<!--- First, lets see if this user is already subscribed. --->
		<cfquery name="Data" dbtype="hql">
			SELECT 
				SubscriberEmail
			FROM Subscriber
			WHERE 
				SubscriberEmail = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="50">
				AND SubscribeAll = <cfqueryparam value="1" cfsqltype="cf_sql_bit">
			<cfif len(arguments.postId) and isDefined("PostDbObj")>
				AND PostRef = #PostDbObj.getPostId()#
			</cfif>
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<cfif arrayLen(Data) eq 0>
			
			<cftransaction>
				
				<!--- Create a new entity. --->
				<cfset SubscriberDbObj = entityNew("Subscriber")>
				<!--- Use the entity objects to set the data. --->
				<cfset SubscriberDbObj.setBlogRef(application.BlogDbObj)>
				<!---The postRef should be left blank.It's not an option in BlogCfc.--->
				<cfset SubscriberDbObj.setSubscriberEmail(email)>
				<cfset SubscriberDbObj.setSubscriberToken(token)>
				<!--- The user has not yet been verified. The verification process is done in the administrative section--->
				<cfset SubscriberDbObj.setSubscriberVerified(false)>
				<cfif len(arguments.postId)>
					<!--- Subscribe to a post --->
					<cfset SubscriberDbObj.setPostRef(PostDbObj)>	
					<!--- Subscribe to everything. --->
					<cfset SubscriberDbObj.setSubscribeAll(0)>	
				<cfelse>
					<!--- Subscribe to everything. --->
					<cfset SubscriberDbObj.setSubscribeAll(1)>	
				</cfif>
				<cfset SubscriberDbObj.setActive(1)>
				<cfset SubscriberDbObj.setDate(blogNow())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't  have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(SubscriberDbObj)>
			</cftransaction>
				
			<!--- Return the token --->
			<cfreturn token>
		<cfelse>
			<!--- Return an empty string --->
			<cfreturn "">
		</cfif>

	</cffunction>
			
	<cffunction name="confirmSubscription" access="public" returnType="void" output="false"
			hint="Confirms a user's subscription to the blog.">
		<cfargument name="token" type="uuid" required="false">
		<cfargument name="email" type="string" required="false">
			
		<!--- Load the entity by the email. --->
		<cfset CommentDbObj = entityLoad("Subscriber", { Email = arguments.email }, "true" )>
		<!--- Use the entity objects to set the data. --->
		<cfset SubscriberDbObj.setBlogRef(BlogRef)>
		<!--- The postRef should be left blank. its not an option in BlogCfc.--->
		<cfset SubscriberDbObj.setSubscriberEmail(email)>
		<cfset SubscriberDbObj.setSubscriberToken(token)>
		<cfset SubscriberDbObj.setSubscriberVerified(verified)>
		<!--- In BlogCfc, all subscribers subsribe to everything. --->
		<cfset SubscriberDbObj.setSubscribeAll(1)>	
		<cfset SubscriberDbObj.setDate(blogNow())>
			
		<cfquery name="Data" dbtype="hql">
			UPDATE Subscriber 
			SET
				SubscriberVerified = 1 
			WHERE 
				BlogRef = #application.BlogDbObj.getBlogId()#
			<cfif structKeyExists(arguments, "token")>
				AND SubscriberToken = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="35" value="#arguments.token#">
			<cfelseif structKeyExists(arguments, "email")>
				AND SubscriberEmail = <cfqueryparam value="#arguments.name#" cfsqltype="cf_sql_varchar" maxlength="100">
			<cfelse>
				<cfthrow message="Invalid call to confirmSubscription. Must pass token or email.">
			</cfif>
		</cfquery>

	</cffunction>
	
	<!--- I need to use this on the subscription interface on via the new subscription pod that I wrote. I need to rewrite this as I need to it return information. The current implementation is used on a different page and it fails when the token does not match the UUID in the database. I don't  want the index page to always fail as I am writing a SPA application, and need better error handling. However, the previous function which this is based on it used in the admin areas, and I don't  want to screw that side up, so here is my new function.--->
	<cffunction name="confirmSubscriptionViaToken" access="public" returnType="boolean" output="false"
			hint="Confirms a user's subscription to the blog. This should also confirm any post subscriptions.">
		<cfargument name="token" type="uuid" required="true">
			
		<cfparam name="subscribed" default="false" type="boolean">

		<cfif isValid("UUID", arguments.token)> 
			<!--- Get the email address from the token --->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					SubscriberEmail as SubscriberEmail
				)
				FROM
					Subscriber
				WHERE SubscriberToken = <cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfquery>

			<cfif arrayLen(Data)>
				<cfquery name="updateSubscriber" dbtype="hql">
					UPDATE	Subscriber
					SET		SubscriberVerified = 1
					WHERE	SubscriberEmail = <cfqueryparam value="#Data[1]["SubscriberEmail"]#" cfsqltype="cf_sql_varchar" maxlength="125">
				</cfquery>
				<cfset subscribed = true>
			</cfif><!---<cfif arrayLen(Data) eq 0>--->
		</cfif><!---<cfif isValid("UUID", arguments.token)>--->
				
		<cfreturn subscribed>
	</cffunction>
			
	<cffunction name="unSubscribeFromPost" access="public" returnType="boolean" output="false"
			hint="Removes a subscriber from a post. This is not used yet.">
		<cfargument name="subscriberToken" type="string" required="true" />
		
		<cftransaction>
			<!--- Load the entity by the subscriberToken. --->
			<cfset SubscriberDbObj = entityLoad("Subscriber", { SubscriberToken = arguments.subscriberToken }, "true" )>
			<!--- Delete the entity --->
			<cfset EntityDelete(SubscriberDbObj)>
		</cftransaction>
			
		<cfreturn true />
	</cffunction>

	<cffunction name="removeSubscriber" access="public" returnType="boolean" output="false"
			hint="Removes a subscriber. This will remove all of the users subscriptions including posts.">
		<cfargument name="email" type="string" required="true">
		<cfargument name="token" type="uuid" required="false">

		<cfif not isUserInRole("admin") and not structKeyExists(arguments,"token")>
			<cfset variables.utils.throw("Unauthorized removal.")>
		</cfif>
			
		<!--- Verify the token before removing. This is a safety check. --->
		<cfquery name="Data" dbtype="hql">
			SELECT SubscriberEmail
			FROM Subscriber
			WHERE SubscriberEmail = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="125">
			AND SubscriberToken =  <cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar" maxlength="75">
		</cfquery>	

		<cfif arrayLen(Data)>

			<cftransaction>
				<!--- Load the entity by the subscriberToken. --->
				<cfset SubscriberDbObj = entityLoad("Subscriber", { SubscriberEmail = arguments.email }, "true" )>
				<!--- Delete the entity --->
				<cfset EntityDelete(SubscriberDbObj)>
			</cftransaction>
			
			<!--- Return true --->
			<cfreturn true>
		<cfelse>
			<!--- Return false --->
			<cfreturn false>
		</cfif>
				
	</cffunction>

	<cffunction name="removeUnverifiedSubscribers" access="public" returnType="void" output="false" 
			hint="Removes all subscribers who are not verified.">
		
		<cfif not isUserInRole("admin")>
			<cfset variables.utils.throw("Unauthorized removal.")>
		</cfif>
		
		<cfquery name="deleteSubscriber" dbtype="hql">
			DELETE FROM Subscriber
			WHERE Verified = <cfqueryparam value="0" cfsqltype="bit">
			AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

	</cffunction>
				
	<!---******************************************************************************************************** 
		Comments
	*********************************************************************************************************--->
			
	<cffunction name="getRecentComments" access="public" returnType="array" output="false"
        	hint="Returns the last N comments for a specific blog.">
        <cfargument name="maxEntries" type="numeric" required="false" default="10">
        
		<cfset var Data = [] />
			
		<cfquery name="Data" dbtype="hql" ormoptions="#{maxresults=arguments.maxEntries}#">
			SELECT new Map (
				Comment.CommentId as CommentId,
				Comment.CommentUuid as CommentUuid,
				Comment.Comment as Comment,
				Post.PostId as PostId,
				Post.PostUuid as PostUuid,
				Post.PostAlias as PostAlias,
				Post.Title as PostTitle,
				Post.DatePosted as PostDatePosted,
				User.UserId as UserId,
				User.FullName as UserFullName,
				User.Email as UserEmail,
				Commenter.FullName as CommenterFullName,
				Commenter.Email as CommenterEmail,
				Comment.DatePosted as DatePosted
			)
			FROM Post as Post 
			<!--- UserRef is the actual database foreign key pointing to the Users table. --->
			LEFT JOIN Post.UserRef as User
			<!--- Comments is a psuedo ORM column in the Post cfc --->
			LEFT JOIN Post.Comments as Comment
			<!--- CommenterRef is an actual DB key in the Comment table. --->
			JOIN Comment.CommenterRef as Commenter
			WHERE 0=0
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			<!---<cfif instance.moderate>
				AND Comment.Moderated = <cfqueryparam value="1" cfsqltype="cf_sql_integer">
			</cfif>--->
				AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
			ORDER BY Post.DatePosted DESC
		</cfquery>

        <cfreturn Data>

    </cffunction>
			
	<cffunction name="getNumberUnmoderated" access="public" returntype="numeric" output="false"
			hint="Returns the number of unmodderated comments for a specific blog entry.">
		<cfset var Data = "[]" />
		
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				count(Comment.Moderated )as NumModeratedPosts
			)
			FROM Comment as Comment 
			WHERE Comment.BlogRef = <cfqueryparam cfsqltype="cf_sql_integer" value="#application.BlogDbObj#">
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset numModeratedPosts = Data[1]["NumModeratedPosts"]>
		<cfelse>
			<cfset numModeratedPosts = 0>
		</cfif>

		<cfreturn numModeratedPosts>
	</cffunction>

	<cffunction name="saveComment" access="public" output="true"
			hint="Saves a comment.">
		<cfargument name="commentId" type="numeric" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="email" type="string" required="true">
		<cfargument name="website" type="string" required="true">
		<cfargument name="ipAddress" type="string" required="true">
		<cfargument name="userAgent" type="string" required="true">
		<cfargument name="comments" type="string" required="true">
		<cfargument name="approved" type="boolean" required="true" default="false">
		<cfargument name="remove" type="boolean" required="false" default="false">
		<cfargument name="spam" type="boolean" required="false" default="false">
		<cfargument name="subscribe" type="boolean" required="false" default="false">
		<cfargument name="moderated" type="boolean" required="false" default="false">
		<cfargument name="promote" type="boolean" required="false" default="false">

		<!--- Note: comments are encoded on the proxyController page if they need to be --->
		<cfset arguments.comments = arguments.comments>
		<cfset arguments.name = left(encodeForHTML(arguments.name),125)>
		<cfset arguments.email = left(encodeForHTML(arguments.email),125)>
		<cfset arguments.website = left(encodeForHTML(arguments.website),255)>
			
		<!--- Automatically approve the comment if moderation is not turned on or if the user is logged in --->
		<cfif not arguments.moderated or application.Udf.isLoggedIn()>
			<cfset approved = 1>
		</cfif>	
			
		<cftransaction>
			
			<!--- **********************************************************************************************
			Save the user or commenter
			*************************************************************************************************--->

			<!--- The comment will use a UserRef if the commenter is a blog user (ie an admin or other role) --->
			<cfset UserDbObj = entityLoad("Users", { Email = trim(arguments.email) }, "true" )>
			<!--- The person making the comment is a generic commenter.  --->
			<cfif not isDefined("UserDbObj")>
				<!--- See if the commenter already exists. --->
				<cfset CommenterDbObj = entityLoad("Commenter", { Email = trim(arguments.email) }, "true" )>
				<!--- If commenter does not exist, create a new commenter entity. --->
				<cfif not isDefined("CommenterDbObj")>
					<cfset CommenterDbObj =  entityNew("Commenter")>
				</cfif>
					
				<!--- Use the set methods in the object to insert or update the record. --->
				<cfset CommenterDbObj.setFullName(arguments.name)>
				<cfset CommenterDbObj.setEmail(arguments.email)>
				<cfset CommenterDbObj.setWebsite(arguments.website)>
				<cfset CommenterDbObj.setIpAddress(arguments.ipAddress)>
				<cfset CommenterDbObj.setHttpUserAgent(arguments.userAgent)>
				<!--- Ban the user if this is spam --->
				<cfif arguments.spam>
					<cfset CommenterDbObj.setBanned(true)>
				</cfif>

			</cfif><!---<cfif not isDefined("UserDbObj")>--->
					
			<!--- **********************************************************************************************
			Save the comment
			*************************************************************************************************--->

			<!--- Load the entity by the comment id. This is only available on update. --->
			<cfif len(arguments.commentId)>
				<cfset CommentDbObj = entityLoad("Comment", { CommentId = trim(arguments.commentId) }, "true" )>
			<cfelse>
				<cfset CommentDbObj = entityNew("Comment")>
			</cfif>
			<!--- Save the user or commenter --->
			<cfif isDefined("UserDbObj")>
				<cfset CommentDbObj.setUserRef(UserDbObj)>
			<cfelse>
				<cfset CommentDbObj.setCommenterRef(CommenterDbObj)>
			</cfif>
			<cfset CommentDbObj.setComment(arguments.comments)>
			<!--- don't  update the date posted if we are editing an existing comment --->
			<cfif not len(arguments.commentId)>
				<cfset CommentDbObj.setDatePosted(blogNow())>
			</cfif>
			<cfset CommentDbObj.setSubscribe(arguments.subscribe)>
			<cfset CommentDbObj.setModerated(arguments.moderated)>
			<cfset CommentDbObj.setApproved(arguments.approved)>
			<cfset CommentDbObj.setSpam(arguments.spam)>		
			<cfset CommentDbObj.setRemove(arguments.remove)>
			<!--- Hide is not yet used. It is intended to allow the post to be seen by someone that is under a temporary ban without showing it to the general public. I am not yet there in my code. --->
			<cfset CommentDbObj.setHide(0)>	
			<!--- Promote is not yet used. --->
			<cfset CommentDbObj.setPromote(0)>
			<cfset CommentDbObj.setDate(blogNow())>

			<!--- Save the commenter --->
			<cfset EntitySave(CommenterDbObj)>
			<!--- Save the comment. --->
			<cfset EntitySave(CommentDbObj)>
				
			<!--- **********************************************************************************************
			Email the post subscribers
			*************************************************************************************************--->
				
			<!--- Email the post subscribers if the comment was approved --->
			<cfif arguments.approved>

				<!--- Get the commentId from the entity --->
				<cfset commentId = CommentDbObj.getCommentId()>
				<!--- Get the comment. The comment table will have the postId --->
				<cfset getComment = application.blog.getComment(commentId=commentId)>
				<!--- Get all post subscribers --->
				<cfset getPostSubscribers = application.blog.getSubscribers(postId=getComment[1]["PostId"], verifiedOnly=true)>

				<!--- Loop through the post subscribers --->
				<cfloop from="1" to="#arrayLen(getPostSubscribers)#" index="i">

					<!--- Set the recipient --->
					<cfset emailTo = getPostSubscribers[1]["SubscriberEmail"]>

					<!--- Render the email --->
					<cfinvoke component="#RendererObj#" method="renderCommentEmailToPostSubscribers" returnvariable="postSubscriberEmail">
						<cfinvokeargument name="commentId" value="#commentId#">
						<cfinvokeargument name="emailTo" value="#emailTo#">
					</cfinvoke>

					<!--- Email the rendered content to the post subscribers --->
					<cfset application.utils.mail(
						to=#emailTo#,
						subject="Message sent via #application.BlogDbObj.getBlogTitle()#",
						body=postSubscriberEmail)>

				</cfloop>

			</cfif><!---<cfif arguments.approved>--->
				
			<!--- **********************************************************************************************
			Remove ALL of the users comments if this is spam (note: we're not deleting, just removing for now)
			*************************************************************************************************--->
			<cfif arguments.spam>
				
				<!--- Load the commenter object that was just saved. --->
				<cfset CommentDbObj = entityLoad("Comment", { CommentId = trim(arguments.commentId) }, "true" )>
					
				<!--- Get all of the records for this user or commenter and set them to spam --->
				<cfquery name="updateComment" dbtype="hql">
					UPDATE Comment
					SET 
						Spam = <cfqueryparam value="1" cfsqltype="bit">,
						Remove = <cfqueryparam value="1" cfsqltype="bit">
					WHERE 0=0
						AND CommenterRef = #CommenterDbObj.getCommenterId()#
				</cfquery>
			
			</cfif><!---<cfif arguments.spam>--->
					
		</cftransaction>
					
		<!--- Clear the scope cache --->
		<cfset application.blog.clearScopeCache()>

		<cfreturn serializeJson(arguments.commentId)>
	</cffunction>
					
	<cffunction name="setModeratedComment" access="public" returnType="void" output="false" 
				hint="Sets a comment to approved">
		<cfargument name="id" type="string" required="true">
			
		<cfquery name="Data" dbtype="hql">
			UPDATE Post
			SET Moderated = <cfqueryparam value="1" cfsqltype="bit">
			WHERE PostId = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
		</cfquery>

	</cffunction>
			
	<cffunction name="killComment" access="public" returnType="void" output="false"
				hint="Deletes a comment based on a separate id to identify the comment in email to the blog admin.">
		<cfargument name="kid" type="numeric" required="true">
		<cfset var q = "">
			
		<cfquery name="Data" dbtype="hql">
			DELETE FROM Comment
			WHERE Remove = <cfqueryparam value="1" cfsqltype="bit">
		</cfquery>

	</cffunction>
			
	<!---******************************************************************************************************** 
		Posts (an entry is a post)
	*********************************************************************************************************--->
			
	<cffunction name="postExists" access="private" returnType="boolean" output="false"
			hint="Returns true or false if an entry exists.">
		<cfargument name="id" type="numeric" required="true">
			
		<cfset var Data = []>

		<cfif not structKeyExists(variables, "existsCache")>
			<cfset variables.existsCache = structNew() />
		</cfif>

		<cfif structKeyExists(variables.existsCache, arguments.id)>
			<cfreturn variables.existsCache[arguments.id]>
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT 
				new Map (PostId as PostId)
			FROM Post
			WHERE BlogRef = #application.BlogDbObj.getBlogId()#
				AND PostId = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar" maxlength="35">
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset postFound = true>
		<cfelse>
			<cfset postFound = false>
		</cfif>

		<!--- I'm not sure what this really does, but I'll leave it and set it like Raymond did. --->
		<cfset variables.existsCache[arguments.id] = postFound>
			
		<!--- Return it. --->
		<cfreturn postFound>

	</cffunction>
			
	<cffunction name="getPostsTitleAndId" access="public" returnType="array" output="true"
			hint="This only gets the PostId and Title and is used for the widgets that only need a tiny subset of the post data">
		<cfargument name="released" type="boolean" required="false" default="true" hint="If true, only displays posts that have been released.">
			
		<cfset var Data = []>
			
		<!--- **********************************************************************************************
			Get the posts that match the variables that were sent in.
		*************************************************************************************************--->

		<!--- Note: the original BlogCfc logic used date add functions on the sql column to get the proper date with the server offset values. I am performing operations on the where clause value. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Post.PostId as PostId,
				Post.Title as Title)
			FROM Post as Post 
			WHERE 0=0
			AND Post.Remove = <cfqueryparam value="0" cfsqltype="bit">
		<cfif arguments.released eq true>
			AND Post.Released = <cfqueryparam value="1" cfsqltype="bit">
		</cfif>
			AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
			ORDER BY 
				Post.DatePosted DESC, 
				Post.Title ASC
		</cfquery>	
						
		<!--- Return the data. --->
		<cfreturn Data><!---Debugging (change the return type when testing) --->

	</cffunction>
			
	<cffunction name="getPostAlias" access="public" returnType="string" output="true"
			hint="Gets a post alias. Used to validate that an alias is unique">
		<cfargument name="postAlias" type="string" required="true">
		
		<!--- Get the alias. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				PostAlias as PostAlias
			)
			FROM Post
			WHERE 
				PostAlias = <cfqueryparam value="#arguments.postAlias#" cfsqltype="cf_sql_varchar">
				AND Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfreturn Data[1]["PostAlias"]>
		<cfelse>
			<cfreturn ''>
		</cfif>
		
	</cffunction>
				
	<cffunction name="getPostTitle" access="public" returnType="string" output="true"
			hint="Gets a post title. Used to validate that a title is unique">
		<cfargument name="postTitle" type="string" required="true">
		
		<!--- Get the alias. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Title as Title
			)
			FROM Post
			WHERE 
				Title = <cfqueryparam value="#arguments.postTitle#" cfsqltype="cf_sql_varchar">
				AND Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		
		<cfif arrayLen(Data)>
			<cfreturn Data[1]["Title"]>
		<cfelse>
			<cfreturn ''>
		</cfif>
			
	</cffunction>
				
	<cffunction name="getPostByTitle" access="public" returnType="array" output="true"
			hint="Gets the post details by the title. Determines whether the post is unique">
		<cfargument name="postTitle" type="string" required="true">
		
		<!--- Get the alias. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				PostId as PostId,
				Title as Title,
				PostAlias as PostAlias
			)
			FROM Post
			WHERE 
				Title = <cfqueryparam value="#arguments.postTitle#" cfsqltype="cf_sql_varchar">
				AND Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="getPostList" access="public" returnType="string" output="false" 
			hint="Returns a list of post id's or names depending upon the listType argument.">
		<cfargument name="listType" type="string" required="true" hint="Either postIdList, postTitleList, or postAliasList">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				PostId as PostId,
				Title as Title, 
				PostAlias as PostAlias
			)
			FROM Post
			WHERE 
				Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		
		<cfif arguments.listType eq 'postIdList'>
			<cfparam name="postIdList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset postIdList = postIdList & Data[i]["PostId"] & ",">
					<cfelse>
						<cfset postIdList = postIdList & Data[i]["PostId"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of id's --->
			<cfreturn postIdList>
				
		<cfelseif listType eq 'postTitleList'>
			<cfparam name="postTitleList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset postTitleList = postTitleList & Data[i]["Title"] & ",">
					<cfelse>
						<cfset postTitleList = postTitleList & Data[i]["Title"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of titles --->
			<cfreturn postTitleList>
				
		<cfelseif arguments.listType eq 'postAliasList'>
			<cfparam name="postAliasList" default="">
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset postAliasList = postAliasList & Data[i]["PostAlias"] & ",">
					<cfelse>
						<cfset postAliasList = postAliasList & Data[i]["PostAlias"]>
					</cfif>
				</cfloop>
			</cfif> 
			<!--- Return the list of aliases --->
			<cfreturn postAliasList>
		</cfif>
						
	</cffunction>
					
	<cffunction name="getPostByPostUuid" access="public" returnType="array" output="true"
			hint="Gets the post details by the post UUID. Used to get the postId when importing data from previous versions of BlogCfc">
		<cfargument name="postUuid" type="string" required="true">
		
		<!--- Get the alias. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				PostId as PostId,
				Title as Title,
				PostAlias as PostAlias
			)
			FROM Post
			WHERE 
				PostUuid = <cfqueryparam value="#arguments.postUuid#" cfsqltype="cf_sql_varchar">
				AND Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="getPostUrlByPostId" access="public" returnType="string" output="true"
			hint="The post URL is created dynamically. Use this function to get the postUrl by a given Post.PostId">
		<cfargument name="postId" required="yes">
		
		<!--- If the application.serverRewriteRuleInPlace variable has been set to true, we need to eliminate 'index.cfm' from the blog post link. --->
		<cfif application.serverRewriteRuleInPlace>
			<cfset postUrl = replaceNoCase(application.blog.makeLink(arguments.postId), '/index.cfm', '')>
		<cfelse>
			<cfset postUrl = application.blog.makeLink(arguments.postId)>
		</cfif>
		
		<cfreturn postUrl>
			
	</cffunction>
			
	<cffunction name="getPostByPostId" access="public" returntype="any" output="true"
			hint="Helper function for the getPost method. The getPost method expects a structure, so here we will take a postId and turn it into a structure that will be passed to the get post method that will allow us to use a single postId. Typically invoked with ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) )">	
		<cfargument name="postId" type="numeric" required="true">
		<cfargument name="showPendingPosts" type="boolean" required="false" default="false">
		<cfargument name="showRemovedPosts" type="boolean" required="false" default="false">
		
		<!--- Create our parameters struct --->
		<cfset params = structNew()>
		<!--- Stuff the postId into the new struct. --->
		<cfset params.byEntry = val(postId)>
		<!--- Invoke the getPost method sending in the new struct ((getPost(params, showPendingPosts, showRemovedPosts, showJsonLd, showPromoteAtTopOfQuery))). --->
		<cfset getPost = application.blog.getPost(params,showPendingPosts,showRemovedPosts,true,false)>
			
		<!--- Return it. --->
		<cfreturn getPost>
			
	</cffunction>
			
	<cffunction name="getDatePosted" access="public" returnType="date" output="false"
		hint="Returns the date/time the post was posted">
		<cfargument name="postId" type="numeric" required="true" hint="Supply the postId.">
		
		<cfset var Data = "[]" />
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Post.DatePosted as DatePosted
			)
			FROM Post as Post 
			WHERE 0=0
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				AND Post.PostId = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.postId#">
		</cfquery>
    	
		<cfreturn Data[1]["DatePosted"]>
	</cffunction>
			
	<cffunction name="getTotalPostCount" access="public" returntype="numeric" output="false"
		hint="Returns the total number of posts in the blog minus any posts that have been removed.">

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				count(Post.PostId) as PostCount
			)
			FROM Post as Post 
			WHERE Post.Released = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
			AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			</cfquery>
		<cfreturn Data[1]["PostCount"]>

	</cffunction>
	
	<cffunction name="getRecentPosts" access="public" returntype="array" output="false"
		hint="Returns the last 5 posts.">
		
		<cfquery name="Data" dbtype="hql" ormoptions="#{maxresults=5}#">		
			SELECT new Map (
				Post.PostId as PostId,
				Post.PostUuid as PostUuid,
				Post.PostAlias as PostAlias,
				Post.Title as Title,
				Post.DatePosted as DatePosted)
			FROM Post as Post 
			WHERE Post.Released = 1
			AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			ORDER BY Post.DatePosted DESC
		</cfquery>
		
		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="getRelatedPosts" access="public" returntype="array" output="true" 
			hint="returns related posts for a specific blog post.">
	    <cfargument name="postId" type="numeric" required="true" />
	
		<!--- Initialize our data object.--->
		<cfset Data = [] />
		
		<!--- Note: ColdFusion ORM (Hibernate) does not support unions at this time so we will have to break out this query into individual parts. BlogThis under UNION --->
		<!--- Create an empty list to store the postId --->
		<cfset relatedPosts="">

		<!--- Get the related post. This will get the RelatedPostRef by the PostRef --->
		<cfquery name="getRelatedPost" dbtype="hql">
			SELECT DISTINCT new Map (
				RelatedPost.PostId as PostId
			)
			FROM Post as Post 
			JOIN Post.RelatedPosts as RelatedPost	
			WHERE Post.PostId = <cfqueryparam value="#postId#" cfsqltype="cf_sql_integer" maxlength="35" />
			<cfif not application.Udf.isLoggedIn()>
				AND Post.Released = <cfqueryparam value="1" cfsqltype="cf_sql_bit">
			</cfif>
			<!--- Do not include removed posts --->
			AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		<!---<cfdump var="#getRelatedPost#">--->

		<!--- Collect the related post ID's --->
		<cfloop from="1" to="#arrayLen(getRelatedPost)#" index="i">
			  <cfset relatedPosts = listAppend(relatedPosts, getRelatedPost[i]["PostId"])>
		</cfloop>

		<!--- Get the backwards related post. This will get the PostRef by the RelatedPostRef --->
		<cfquery name="getBackwardRelatedPost" dbtype="hql">
			SELECT DISTINCT new Map (
				Post.PostId as PostId
			)
			FROM Post as Post 
			JOIN Post.RelatedPosts as RelatedPost	
			WHERE RelatedPost.PostId = <cfqueryparam value="#postId#" cfsqltype="cf_sql_integer" maxlength="35" />
			<cfif not application.Udf.isLoggedIn()>
				AND Post.Released = <cfqueryparam value="1" cfsqltype="cf_sql_bit">
			</cfif>
			<!--- Do not include removed posts --->
			AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		<!---<cfdump var="#getBackwardRelatedPost#">--->

		<!--- Collect the backward post ID's --->
		<cfloop from="1" to="#arrayLen(getBackwardRelatedPost)#" index="i">
			  <cfset relatedPosts = listAppend(relatedPosts, getBackwardRelatedPost[i]["PostId"])>
		</cfloop>	
		<!---<cfdump var="#relatedPosts#">--->

		<!--- Now that we have collected our Id's, make the query that will be returned to the client. --->
		<cfif len(relatedPosts)>
			<cfquery name="Data" dbtype="hql">
				SELECT DISTINCT new Map (
					Post.PostId as PostId,
					Post.PostUuid as PostUuid,
					Post.PostAlias as PostAlias,
					Post.Title as Title,
					Post.DatePosted as DatePosted)
				FROM Post as Post 
				WHERE Post.PostId IN (<cfoutput>#relatedPosts#</cfoutput>)
				<!--- don't  include the current post --->
				AND Post.PostId <> <cfqueryparam value="#postId#" cfsqltype="cf_sql_integer" maxlength="35" />
				<!--- Do not include removed posts --->
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				ORDER BY Post.DatePosted ASC
			</cfquery>
			<!---<cfdump var="#Data#">--->
		</cfif>
					
		<!--- Return the array ---> 
		<cfreturn Data>

	</cffunction>
			
	<cffunction name="getPosts" access="public" returnType="array" output="true"
			hint="New function to get posts from the database. Used as the base query for various grid widgets. Note: to prevent a wierd Hibernate AST error, we need to limit the query to one query clause.">
		
		<cfargument name="user" required="no" default="">
		<cfargument name="alias" required="no" default="">
		<cfargument name="title" required="no" default="">
		<cfargument name="description" required="no" default="">
		<cfargument name="body" required="no" default="">
		<cfargument name="moreBody" required="no" default="">
		<cfargument name="numViews" required="no" default="">
		<cfargument name="posted" required="no" default="">
			
		<cfset var Data = []>
			
		<!--- **********************************************************************************************
			Get the posts that match the variables that were sent in.
		*************************************************************************************************--->

		<!--- Note: the original BlogCfc logic used date add functions on the sql column to get the proper date with the server offset values. I am performing operations on the where clause value. --->
		<!--- Note: I needed to remove some of the clauses prevent the following error: QuerySyntaxException: unexpected AST node: --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				User.UserId as UserId,
				User.FullName as FullName,
				User.Email as Email,
				Post.PostId as PostId,
				Post.ThemeRef as ThemeRef,
				Post.PostUuid as PostUuid,
				Post.PostAlias as PostAlias,
				Post.Title as Title,
				Post.Description as Description,
				Post.Body as Body,
				Post.MoreBody as MoreBody,
				Enclosure.MediaId as MediaId,
				Enclosure.MediaTitle as MediaTitle,
				Enclosure.MediaPath as MediaPath,
				Enclosure.MediaUrl as MediaUrl,
				Enclosure.MediaHeight as MediaHeight,
				Enclosure.MediaSize as MediaSize,
				MediaType.MediaType as MediaType,
				MimeType.MimeTypeId as MimeTypeId,
				MimeType.MimeType as MimeType,
				Post.AllowComment as AllowComment,
				Post.NumViews as NumViews,
				Post.NumViews/(month(current_date())-month(DatePosted)+12*(year(current_date())-year(DatePosted))+1) as ViewsPerDay, 
				Post.Mailed as Mailed,
				Post.Released as Released,
				Post.BlogSortDate as BlogSortDate,
				Post.DatePosted as DatePosted, 
				Post.Date as Date)
			FROM Post as Post 
			<!--- UserRef is the actual database foreign key pointing to the Users table. --->
			JOIN Post.UserRef as User
			<!--- EnclosureMedia is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.EnclosureMedia as Enclosure
			<!--- We need to traverse the Post.EnclosureMedia object to get to the MimeTypeRef and MediaType objects --->
			LEFT JOIN Enclosure.MediaTypeRef as MediaType 
			LEFT JOIN Enclosure.MimeTypeRef as MimeType
			WHERE 0=0
			<cfif arguments.alias neq "">
				AND Post.PostAlias = <cfqueryparam value="#left(arguments.alias,100)#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<cfif arguments.title neq "">
				AND Post.Title LIKE <cfqueryparam value="%#arguments.title#%" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<cfif arguments.description neq "">
				AND Post.Description = <cfqueryparam value="#left(arguments.description,160)#" cfsqltype="cf_sql_varchar" maxlength="160">
			</cfif>
			<cfif body neq "">
				AND Post.Body LIKE <cfqueryparam value="%#arguments.body#%" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif numViews neq "">
				AND Post.NumViews = <cfqueryparam value="#arguments.numViews#" cfsqltype="cf_sql_integer">
			</cfif>
			<cfif posted neq "">
				AND date(Post.DatePosted) = <cfqueryparam value="#arguments.datePosted#" cfsqltype="cf_sql_date">
			</cfif>
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			ORDER BY 
				Post.BlogSortDate DESC,
				Post.DatePosted DESC, 
				Post.Title ASC
		</cfquery>	
						
		<!--- Return the data. --->
		<cfreturn Data><!---Debugging (change the return type when testing) --->

	</cffunction>
				
	<!--- Inspect a post for any more blocks --->
	<cffunction name="getMoreBlocksFromPost" returntype="any" output="true"
			hint="Creates a structure of any more blocks found in the post content">
		<cfargument name="postContent" type="string" required="yes">
			
		<cfparam name="error" default="">
		<cfparam name="moreBody" default="">
			
		<cfset moreStr = "<more/>">
		<cfset moreStart = findNoCase(moreStr,arguments.postContent)>
		<cfif moreStart gt 1>
			<cfset moreBody = trim(mid(arguments.postContent,(moreStart+len(moreStr)),len(postContent)))>
			<cfset body = trim(left(arguments.postContent,moreStart-1))>
		<cfelseif moreStart is 1>
			<cfset error = "Post content not found">
		<cfelse>
			<cfset body = arguments.postContent>
			<cfset moreBody = "">
		</cfif>
			
		<cfif error neq ''>
			<cfreturn error>
		<cfelse>
			<!--- Return ani implicit structure of the moreBody and newBody --->
			<cfset moreBody = {
				"body" = body,
				"moreBody" = moreBody
			}>
			<!--- Return it --->
			<cfreturn moreBody>
		</cfif>
			
	</cffunction>
	
	<cffunction name="getPost" access="public" returnType="any" output="true"
			hint="This is Raymonds original function with major changes. Returns one more more posts. Allows for a params structure to configure what entries are returned. I am going to revise this in the next version as the params are hard to identify and want to pass in the arguments in the params struct instead. Note: this is often invoked using getPost(params,showPendingPosts,showRemovedPosts,showJsonLd,showPromoteAtTopOfQuery)">
		
		<cfargument name="params" type="struct" required="false" default="#structNew()#">
		<cfargument name="showPendingPosts" type="boolean" required="false" default="false">
		<cfargument name="showRemovedPosts" type="boolean" required="false" default="false">
		<cfargument name="showJsonLd" type="boolean" required="false" default="false" hint="The Json Ld sting can be quite large and it should not be included unless it is needed.">
		<cfargument name="showPromoteAtTopOfQuery" type="boolean" required="false" default="true" hint="The RSS template needs to order the query by the date and can't have the promoted posts at the top of the query">
		<cfargument name="showPopularPosts" type="boolean" required="false" default="false" hint="Orders the posts by the average number of monthly views.">	
			
		<cfset debug = false>
			
		<!--- Preset vars. --->
		<cfset var getComments = "">
		<cfset var getCategories = "">
		<cfset var validOrderBy = "Post.DatePosted, Post.Title, Post.NumViews">
		<cfset var validOrderByDir = "ASC, DESC">
		<cfset var validMode = "short,full">
		<cfset var getIds = "">
		<cfset var idList = "">
		<cfset var pageIdList = "">
		<cfset var x = "">
		<cfset var loadScrollMagic = false>
		<cfset var Data = []>
		<!--- And set the initial EnclosureMapCount --->
		<cfset enclosureMapCount = 0>

		<!--- **********************************************************************************************
			Set vars
		*************************************************************************************************--->	

		<!--- By default, order the results by the date posted --->
		<cfif not structKeyExists(arguments.params,"orderBy") or not listFindNoCase(validOrderBy,arguments.params.orderBy)>
			<cfset arguments.params.orderBy = "Post.DatePosted">
		</cfif>
		<!--- By default, order the results direction desc --->
		<cfif not structKeyExists(arguments.params,"orderByDir") or not listFindNoCase(validOrderByDir,arguments.params.orderByDir)>
			<cfset arguments.params.orderByDir = "DESC">
		</cfif>
		<!--- If lastXDays is passed, verify X is int between 1 and 365 --->
		<cfif structKeyExists(arguments.params,"lastXDays")>
			<cfif not val(arguments.params.lastXDays) or val(arguments.params.lastXDays) lt 1 or val(arguments.params.lastXDays) gt 365>
				<cfset structDelete(arguments.params,"lastXDays")>
			<cfelse>
				<cfset arguments.params.lastXDays = val(arguments.params.lastXDays)>
			</cfif>
			<cfset lastXDaysDate = dateAdd("d", -1 * arguments.params.lastXDays, blogNow())>
		</cfif>
		<!--- If byDay is passed, verify X is int between 1 and 31 --->
		<cfif structKeyExists(arguments.params,"byDay")>
			<cfif not val(arguments.params.byDay) or val(arguments.params.byDay) lt 1 or val(arguments.params.byDay) gt 31>
				<cfset structDelete(arguments.params,"byDay")>
			<cfelse>
				<cfset arguments.params.byDay = val(arguments.params.byDay)>
			</cfif>
		</cfif>
		<!--- If byMonth is passed, verify X is int between 1 and 12 --->
		<cfif structKeyExists(arguments.params,"byMonth")>
			<cfif not val(arguments.params.byMonth) or val(arguments.params.byMonth) lt 1 or val(arguments.params.byMonth) gt 12>
				<cfset structDelete(arguments.params,"byMonth")>
			<cfelse>
				<cfset arguments.params.byMonth = val(arguments.params.byMonth)>
			</cfif>
		</cfif>
		<!--- If byYear is passed, verify X is int  --->
		<cfif structKeyExists(arguments.params,"byYear")>
			<cfif not val(arguments.params.byYear)>
				<cfset structDelete(arguments.params,"byYear")>
			<cfelse>
				<cfset arguments.params.byYear = val(arguments.params.byYear)>
			</cfif>
		</cfif>
		<!--- If byTitle is passed, verify we have a length  --->
		<cfif structKeyExists(arguments.params,"byTitle")>
			<cfif not len(trim(arguments.params.byTitle))>
				<cfset structDelete(arguments.params,"byTitle")>
			<cfelse>
				<cfset arguments.params.byTitle = trim(arguments.params.byTitle)>
			</cfif>
		</cfif>

		<!--- By default, get body, commentCount and categories as well, requires additional lookup --->
		<cfif not structKeyExists(arguments.params,"mode") or not listFindNoCase(validMode,arguments.params.mode)>
			<cfset arguments.params.mode = "full">
		</cfif>
		<!--- handle searching --->
		<cfif structKeyExists(arguments.params,"searchTerms") and not len(trim(arguments.params.searchTerms))>
			<cfset structDelete(arguments.params,"searchTerms")>
		</cfif>
		<!--- Limit number returned. Thanks to Rob Brooks-Bilson --->
		<cfif not structKeyExists(arguments.params,"maxEntries") or (structKeyExists(arguments.params,"maxEntries") and not val(arguments.params.maxEntries))>
			<cfset arguments.params.maxEntries = 12>
		</cfif>

		<cfif not structKeyExists(arguments.params,"startRow") or (structKeyExists(arguments.params,"startRow") and not val(arguments.params.startRow))>
			<cfset arguments.params.startRow = 1>
		</cfif>
			
		<!--- Set the number of records to return. This is required for pagination. --->
		<cfif structKeyExists(arguments.params,"byAlias")>
			<!--- When looking at an individual post, there is one row. --->
			<cfset numRows = 1>
			<!--- There is no offset when looking at an individual post. --->
			<cfset offset = 0>
		<cfelse>
			<cfset numRows = arguments.params.maxEntries>
			<!--- The offset only occurs when the start row is greater than 1 when the user has already paginated to the 2nd or greater page. --->
			<cfif arguments.params.startRow gt 1>
				<cfset offset = arguments.params.startRow>
			<cfelse>
				<!--- Set the offset to zero or you'll miss the first record in the dataset. --->
				<cfset offset = 0>
			</cfif>
		</cfif>
		<!--- Debugging: --->
		<cfif debug>
			<cfdump var="#arguments.params#">
			numRows: #numRows# offset: #offset#
		</cfif>
			
		<!--- **********************************************************************************************
			Get the posts that match the variables that were sent in.
		*************************************************************************************************--->

		<!--- Note: the original BlogCfc logic used date add functions on the sql column to get the proper date with the server offset values. I am performing operations on the where clause value. --->
		<cfquery name="Data" dbtype="hql" ormoptions="#{maxresults=numRows, offset=offset}#">
			SELECT new Map (
				Post.PostId as PostId,
				Post.Promote as Promoted,
				User.UserId as UserId,
				User.FullName as FullName,
				User.Email as Email,
				Post.ThemeRef as ThemeRef,
				Post.PostUuid as PostUuid,
				Post.PostAlias as PostAlias,
				Post.Title as Title,
				Post.Description as Description,
				Post.PostHeader as PostHeader,
				Post.CSS as CSS,
				Post.JavaScript as JavaScript,
				Post.Body as Body,
				Post.MoreBody as MoreBody,
			<cfif showJsonLd>
				Post.JsonLd as JsonLd,
			</cfif>
				Post.Remove as Remove,
				Enclosure.MediaId as MediaId,
				Enclosure.MediaTitle as MediaTitle,
				Enclosure.MediaPath as MediaPath,
				Enclosure.MediaUrl as MediaUrl,
				Enclosure.MediaThumbnailUrl as MediaThumbnailUrl,
				Enclosure.MediaHeight as MediaHeight,
				Enclosure.MediaSize as MediaSize,
				Enclosure.MediaVideoCoverUrl as MediaVideoCoverUrl,
				Enclosure.MediaVideoVttFileUrl as MediaVideoVttFileUrl,
				Enclosure.ProviderVideoId as ProviderVideoId,
				EnclosureMap.MapId as EnclosureMapId,
				EnclosureCarousel.CarouselId as EnclosureCarouselId,
				MediaType.MediaType as MediaType,
				MimeType.MimeTypeId as MimeTypeId,
				MimeType.MimeType as MimeType,
				Post.AllowComment as AllowComment,
				Post.Promote as Promote,
				Post.NumViews as NumViews,
				Post.NumViews/(month(current_date())-month(DatePosted)+12*(year(current_date())-year(DatePosted))+1) as ViewsPerDay, 
				Post.Mailed as Mailed,
				Post.Released as Released,
				Post.BlogSortDate as BlogSortDate,
				Post.DatePosted as DatePosted, 
				Post.Date as Date
			)
			FROM Post as Post 
			<!--- UserRef is the actual database foreign key pointing to the Users table. --->
			LEFT JOIN Post.UserRef as User
			<!--- EnclosureMedia is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.EnclosureMedia as Enclosure
			<!--- We need to traverse the Post.EnclosureMedia object to get to the MimeTypeRef and MediaType objects --->
			LEFT JOIN Enclosure.MediaTypeRef as MediaType  
			LEFT JOIN Enclosure.MimeTypeRef as MimeType
			<!--- Get the Enclosure Map (there can only be one) --->
			LEFT JOIN Post.EnclosureMap as EnclosureMap
			<!--- Get the carousel, there is only one --->
			LEFT JOIN Post.EnclosureCarousel as EnclosureCarousel
			WHERE 0=0
			<cfif not showRemovedPosts>
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif structKeyExists(arguments.params,"lastXDays")>
				AND date(Post.DatePosted) > <cfqueryparam value="#createDate(params.byYear, params.byMonth, params.byDay)#" cfsqltype="cf_sql_date">
			</cfif>
			<!--- Todo: serverOffset --->
			<cfif structKeyExists(arguments.params,"byDay") and not structKeyExists(arguments.params,"byAlias")>
			 	<!--- I am going to search between 24 hours on the given date. --->
				AND Post.DatePosted > <cfqueryparam value="#CreateDateTime(params.byYear, params.byMonth, params.byDay, '00', '00')#" cfsqltype="timestamp">
				AND Post.DatePosted < <cfqueryparam value="#CreateDateTime(params.byYear, params.byMonth, params.byDay, '23', '59')#" cfsqltype="timestamp">
			</cfif>
			<cfif structKeyExists(arguments.params,"byTitle")>
				AND Post.Title = <cfqueryparam value="#arguments.params.byTitle#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<cfif structKeyExists(arguments.params,"byCat") and arguments.params.byCat neq 'all'>
				AND Post.PostId IN (
					SELECT PostRef
					FROM PostCategoryLookup
					WHERE CategoryRef IN (#arguments.params.byCat#)
				)
			</cfif>
			<cfif structKeyExists(arguments.params,"byTag") and arguments.params.byTag neq 'all'>
				AND Post.PostId IN (
					SELECT PostRef
					FROM PostTagLookup
					WHERE TagRef IN (#arguments.params.byTag#)
				)
			</cfif>
			<cfif structKeyExists(arguments.params,"byPosted")>
				AND User.UserName =  <cfqueryparam value="#arguments.params.byPosted#" cfsqltype="cf_sql_varchar" maxlength="50" list=true>
			</cfif>
			<cfif structKeyExists(arguments.params,"searchTerms")>
				<cfif not structKeyExists(arguments.params, "don'tlogsearch")>
					<cfset logSearch(arguments.params.searchTerms)>
				</cfif>
				AND (
						Post.Title LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
						OR Post.Body LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
						OR Post.MoreBody LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
					)
			</cfif>
			<cfif structKeyExists(arguments.params,"byEntry")>
				AND Post.PostId = <cfqueryparam value="#arguments.params.byEntry#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments.params,"byAlias")>
				AND Post.PostAlias = <cfqueryparam value="#left(arguments.params.byAlias,100)#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<!--- Date operations --->
			<cfif structKeyExists(arguments.params,"byDay")>
				AND day(Post.DatePosted) = <cfqueryparam value="#arguments.params.byDay#" cfsqltype="integer">
			</cfif>
			<cfif structKeyExists(arguments.params,"byMonth")>
				AND month(Post.DatePosted) = <cfqueryparam value="#arguments.params.byMonth#" cfsqltype="integer">
			</cfif>
			<cfif structKeyExists(arguments.params,"byYear")>
				AND year(Post.DatePosted) = <cfqueryparam value="#arguments.params.byYear#" cfsqltype="integer">
			</cfif>
			<!--- Allow admin's to see non-released posts and future posts. --->
			<cfif not arguments.showPendingPosts or (structKeyExists(arguments.params, "releasedOnly") and arguments.params.releasedonly)>
				AND Post.DatePosted < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#blogNow()#">
			</cfif>
			<cfif not arguments.showPendingPosts>
				AND Post.Released = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
			</cfif>
				AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
		<cfif showPopularPosts>
				ORDER BY NumViews/(month(current_date())-month(DatePosted)+12*(year(current_date())-year(DatePosted))+1) #arguments.params.orderByDir#
		<cfelse>
			<cfif showPromoteAtTopOfQuery>
				ORDER BY Post.Promote DESC, Post.BlogSortDate DESC, Post.DatePosted #arguments.params.orderByDir#
			<cfelse>
				ORDER BY #arguments.params.orderBy# #arguments.params.orderByDir#
			</cfif>
		</cfif>
			<!--- ORDER BY #arguments.params.orderBy# #arguments.params.orderByDir# --->
		</cfquery>	
		<!---<cfdump var="#Data#">--->
				
		<!--- **********************************************************************************************
			Create the PostStruct structure
		*************************************************************************************************--->
			
		<!--- Create the array that we will place the structure into. --->
		<cfset PostArray = arrayNew(1)>
		
		<!--- Create our final structure --->
		<cfif arrayLen(Data)>
			
			<!--- Preset the map count. We will increment this every time a map is found and store it in the final structure. --->
			<cfset mapCount="0">
			<cfset mapIds="">
			
			<!--- Loop through the data to get the proper map count --->
			<cfloop from="1" to="#arrayLen(Data)#" index="i">
				<!--- Create a new struct --->
				<cfset PostStruct = structNew()>
				
				<!--- Set the values in the structure. --->
				<cfset postRow = Data[i]>
					
				<!--- Does the map exist? --->
				<cfif structKeyExists(postRow, "EnclosureMapId")>
					<!--- Store the enclosure mapId's --->
					<cfif mapIds eq ''>
						<cfset mapIds = Data[i]["EnclosureMapId"]>
					<cfelse>
						<cfset mapIds = mapIds & ',' & Data[i]["EnclosureMapId"]>
					</cfif>
					<!--- Increment the map count property --->
					<cfset mapCount = mapCount + 1> 
				</cfif>
						
				<!--- Determine if there is a scroll magic scene. We are doing this in order to load scroll magic only when it is needed. We only know if there may be a scene if the post header contains a cfinclude, or when there is a script with the string 'new ScrollMagic'. --->
				<cfif Data[i]["PostHeader"] contains '<cfincludeTemplate>' or Data[i]["PostHeader"] contains 'new ScrollMagic'>
					<cfset loadScrollMagic = true>
				</cfif>
			</cfloop>
			
			<!--- And loop through the data again to set the vars. --->
			<cfloop from="1" to="#arrayLen(Data)#" index="i">
				
				<!--- Create a new struct --->
				<cfset PostStruct = structNew()>
				
				<!--- Set the values in the structure. --->
				<cfset postRow = Data[i]>
				<cfset PostStruct["UserId"] = Data[i]["UserId"]>
				<cfset PostStruct["FullName"] = Data[i]["FullName"]>
				<cfset PostStruct["Email"] = Data[i]["Email"]>
				<cfset PostStruct["PostId"] = Data[i]["PostId"]>
				<!--- The theme id may not be present. its optional. --->
				<cfif structKeyExists(postRow, "ThemeRef")>
					<cfset PostStruct["ThemeRef"] = Data[i]["ThemeRef"]>
				<cfelse>
					<cfset PostStruct["ThemeRef"] = "">
				</cfif>
				<cfset PostStruct["Promoted"] = Data[i]["Promoted"]>
				<cfset PostStruct["PostUuid"] = Data[i]["PostUuid"]>
				<cfset PostStruct["PostAlias"] = Data[i]["PostAlias"]>
				<cfset PostStruct["Title"] = Data[i]["Title"]>
				<cfset PostStruct["Description"] = Data[i]["Description"]>
				<cfif showJsonLd>
					<!--- Json Ld may not exist --->
					<cfif structKeyExists(postRow, "JsonLd")>
						<cfset PostStruct["JsonLd"] = Data[i]["JsonLd"]>
					<cfelse>
						<cfset PostStruct["JsonLd"] = "">
					</cfif>
				</cfif>
				<cfset PostStruct["Remove"] = Data[i]["Remove"]>
				<!--- The post header may be null as well --->
				<cfif structKeyExists(postRow, "PostHeader")>
					<cfset PostStruct["PostHeader"] = Data[i]["PostHeader"]>
				<cfelse>
					<cfset PostStruct["PostHeader"] = "">
				</cfif>
				<!--- Perform the same steps for CSS and Javascript --->
				<cfif structKeyExists(postRow, "CSS")>
					<cfset PostStruct["CSS"] = Data[i]["CSS"]>
				<cfelse>
					<cfset PostStruct["CSS"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "JavaScript")>
					<cfset PostStruct["JavaScript"] = Data[i]["JavaScript"]>
				<cfelse>
					<cfset PostStruct["JavaScript"] = "">
				</cfif>
				<cfset PostStruct["Body"] = Data[i]["Body"]>
				<cfset PostStruct["MoreBody"] = Data[i]["MoreBody"]>
				<!--- There may not be any media. We need to see if the values are defined before setting them. --->
				<cfif structKeyExists(postRow, "MediaId")>
					<cfset PostStruct["MediaId"] = Data[i]["MediaId"]>
				<cfelse>
					<cfset PostStruct["MediaId"] = "">
				</cfif>
				<!--- Get the media type. The mime type may not always be available when there are external links. --->
				<cfif structKeyExists(postRow, "MediaType")>
					<cfset PostStruct["MediaType"] = Data[i]["MediaType"]>
				<cfelse>
					<cfset PostStruct["MediaType"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MimeType")>
					<cfset PostStruct["MimeType"] = Data[i]["MimeType"]>
				<cfelse>
					<cfset PostStruct["MimeType"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MediaTitle")>
					<cfset PostStruct["MediaTitle"] = Data[i]["MediaTitle"]>
				<cfelse>
					<cfset PostStruct["MediaTitle"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MediaWidth")>
					<cfset PostStruct["MediaWidth"] = Data[i]["MediaWidth"]>
				<cfelse>
					<cfset PostStruct["MediaWidth"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MediaHeight")>
					<cfset PostStruct["MediaHeight"] = Data[i]["MediaHeight"]>
				<cfelse>
					<cfset PostStruct["MediaHeight"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MediaSize")>
					<cfset PostStruct["MediaSize"] = Data[i]["MediaSize"]>
				<cfelse>
					<cfset PostStruct["MediaSize"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MediaPath")>
					<cfset PostStruct["MediaPath"] = Data[i]["MediaPath"]>
				<cfelse>
					<cfset PostStruct["MediaPath"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MediaUrl")>
					<cfset PostStruct["MediaUrl"] = Data[i]["MediaUrl"]>
				<cfelse>
					<cfset PostStruct["MediaUrl"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MediaThumbnailUrl")>
					<cfset PostStruct["MediaThumbnailUrl"] = Data[i]["MediaThumbnailUrl"]>
				<cfelse>
					<cfset PostStruct["MediaThumbnailUrl"] = "">
				</cfif>	
				<cfif structKeyExists(postRow, "MediaVideoCoverUrl")>
					<cfset PostStruct["MediaVideoCoverUrl"] = Data[i]["MediaVideoCoverUrl"]>
				<cfelse>
					<cfset PostStruct["MediaVideoCoverUrl"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "MediaVideoVttFileUrl")>
					<cfset PostStruct["MediaVideoVttFileUrl"] = Data[i]["MediaVideoVttFileUrl"]>
				<cfelse>
					<cfset PostStruct["MediaVideoVttFileUrl"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "ProviderVideoId")>
					<cfset PostStruct["ProviderVideoId"] = Data[i]["ProviderVideoId"]>
				<cfelse>
					<cfset PostStruct["ProviderVideoId"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "EnclosureMapId")>
					<cfset PostStruct["EnclosureMapId"] = Data[i]["EnclosureMapId"]>
				<cfelse>
					<cfset PostStruct["EnclosureMapId"] = "">
				</cfif>
				<cfif structKeyExists(postRow, "EnclosureCarouselId")>
					<cfset PostStruct["EnclosureCarouselId"] = Data[i]["EnclosureCarouselId"]>
				<cfelse>
					<cfset PostStruct["EnclosureCarouselId"] = "">
				</cfif>
				<!--- These values should always be present. --->
				<cfset PostStruct["AllowComment"] = Data[i]["AllowComment"]>
				<cfset PostStruct["NumViews"] = Data[i]["NumViews"]>
				<cfset PostStruct["ViewsPerDay"] = Data[i]["ViewsPerDay"]>
				<cfset PostStruct["Mailed"] = Data[i]["Mailed"]>
				<cfset PostStruct["Released"] = Data[i]["Released"]>
				<!--- Note: we are now getting the proper time when we are inserting the records instead of manipulating the data after it is in the database. --->
				<cfset PostStruct["BlogSortDate"] = Data[i]["BlogSortDate"]>
				<cfset PostStruct["DatePosted"] = Data[i]["DatePosted"]>
				<cfset PostStruct["Date"] = Data[i]["Date"]>
					
				<!--- Reset these values at the very end. --->
				<cfset PostStruct["LoadScrollMagic"] = loadScrollMagic>
				<cfset PostStruct["EnclosureMapCount"] = mapCount>
				<cfset PostStruct["EnclosureMapIdList"] = mapIds>
					
				<!--- Append the final structure inside of an array. --->
				<cfset arrayAppend(PostArray, PostStruct)>
			
			</cfloop>
			
		</cfif>
					
		<!--- Return the structure. --->
		<cfreturn PostArray><!---Debugging (change the return type when testing) --->
		
	</cffunction>
					
	<cffunction name="getPostCount" access="public" returnType="numeric" output="true"
			hint="Gets the post count or the mapCount of the getPost function wich is used all over this blog to determine pagination and how to render the maps. Other than the ORDER BY statement, this must be identical to the top portion of the getPost function.">
		
		<cfargument name="params" type="struct" required="false" default="#structNew()#">
		<cfargument name="showRemovedPosts" type="boolean" required="false" default="false">
			
		<cfset var Data = []>

		<!--- **********************************************************************************************
			Set vars
		*************************************************************************************************--->	

		<!--- By default, order the results by posted col --->
		<cfif not structKeyExists(arguments.params,"orderBy") or not listFindNoCase(validOrderBy,arguments.params.orderBy)>
			<cfset arguments.params.orderBy = "Post.DatePosted">
		</cfif>
		<!--- By default, order the results direction desc --->
		<cfif not structKeyExists(arguments.params,"orderByDir") or not listFindNoCase(validOrderByDir,arguments.params.orderByDir)>
			<cfset arguments.params.orderByDir = "DESC">
		</cfif>
		<!--- If lastXDays is passed, verify X is int between 1 and 365 --->
		<cfif structKeyExists(arguments.params,"lastXDays")>
			<cfif not val(arguments.params.lastXDays) or val(arguments.params.lastXDays) lt 1 or val(arguments.params.lastXDays) gt 365>
				<cfset structDelete(arguments.params,"lastXDays")>
			<cfelse>
				<cfset arguments.params.lastXDays = val(arguments.params.lastXDays)>
			</cfif>
			<cfset lastXDaysDate = dateAdd("d", -1 * arguments.params.lastXDays, blogNow())>
		</cfif>
		<!--- If byDay is passed, verify X is int between 1 and 31 --->
		<cfif structKeyExists(arguments.params,"byDay")>
			<cfif not val(arguments.params.byDay) or val(arguments.params.byDay) lt 1 or val(arguments.params.byDay) gt 31>
				<cfset structDelete(arguments.params,"byDay")>
			<cfelse>
				<cfset arguments.params.byDay = val(arguments.params.byDay)>
			</cfif>
		</cfif>
		<!--- If byMonth is passed, verify X is int between 1 and 12 --->
		<cfif structKeyExists(arguments.params,"byMonth")>
			<cfif not val(arguments.params.byMonth) or val(arguments.params.byMonth) lt 1 or val(arguments.params.byMonth) gt 12>
				<cfset structDelete(arguments.params,"byMonth")>
			<cfelse>
				<cfset arguments.params.byMonth = val(arguments.params.byMonth)>
			</cfif>
		</cfif>
		<!--- If byYear is passed, verify X is int  --->
		<cfif structKeyExists(arguments.params,"byYear")>
			<cfif not val(arguments.params.byYear)>
				<cfset structDelete(arguments.params,"byYear")>
			<cfelse>
				<cfset arguments.params.byYear = val(arguments.params.byYear)>
			</cfif>
		</cfif>
		<!--- If byTitle is passed, verify we have a length  --->
		<cfif structKeyExists(arguments.params,"byTitle")>
			<cfif not len(trim(arguments.params.byTitle))>
				<cfset structDelete(arguments.params,"byTitle")>
			<cfelse>
				<cfset arguments.params.byTitle = trim(arguments.params.byTitle)>
			</cfif>
		</cfif>

		<!--- By default, get body, commentCount and categories as well, requires additional lookup --->
		<cfif not structKeyExists(arguments.params,"mode") or not listFindNoCase(validMode,arguments.params.mode)>
			<cfset arguments.params.mode = "full">
		</cfif>
		<!--- handle searching --->
		<cfif structKeyExists(arguments.params,"searchTerms") and not len(trim(arguments.params.searchTerms))>
			<cfset structDelete(arguments.params,"searchTerms")>
		</cfif>
		<!--- Limit number returned. Thanks to Rob Brooks-Bilson --->
		<cfif not structKeyExists(arguments.params,"maxEntries") or (structKeyExists(arguments.params,"maxEntries") and not val(arguments.params.maxEntries))>
			<cfset arguments.params.maxEntries = 12>
		</cfif>

		<cfif not structKeyExists(arguments.params,"startRow") or (structKeyExists(arguments.params,"startRow") and not val(arguments.params.startRow))>
			<cfset arguments.params.startRow = 1>
		</cfif>
			
		<!--- Set the number of records to return. This is required for pagination. --->
		<cfif structKeyExists(arguments.params,"byAlias")>
			<!--- When looking at an individual post, there is one row. --->
			<cfset numRows = 1>
			<!--- There is no offset when looking at an individual post. --->
			<cfset offset = 0>
		<cfelse>
			<cfset numRows = arguments.params.maxEntries + arguments.params.startRow-1>
			<!--- The offset only occurs when the start row is greater than 1 when the user has already paginated to the 2nd or greater page. --->
			<cfif arguments.params.startRow gt 1>
				<cfset offset = arguments.params.startRow>
			<cfelse>
				<!--- Set the offset to zero or you'll miss the first record in the dataset. --->
				<cfset offset = 0>
			</cfif>
		</cfif>
		<!--- Debugging: <cfdump var="#arguments.params#">--->
			
		<!--- **********************************************************************************************
			Get the posts that match the variables that were sent in.
		*************************************************************************************************--->

		<!--- Note: the original BlogCfc logic used date add functions on the sql column to get the proper date with the server offset values. I am performing operations on the where clause value. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				count(PostId) as PostCount
			)
			FROM Post as Post 
			<!--- UserRef is the actual database foreign key pointing to the Users table. --->
			LEFT JOIN Post.UserRef as User
			<!--- EnclosureMedia is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.EnclosureMedia as Enclosure
			<!--- We need to traverse the Post.EnclosureMedia object to get to the MimeTypeRef and MediaType objects --->
			LEFT JOIN Enclosure.MediaTypeRef as MediaType  
			LEFT JOIN Enclosure.MimeTypeRef as MimeType
			<!--- Get the Enclosure Map (there can only be one) --->
			LEFT JOIN Post.EnclosureMap as EnclosureMap
			WHERE 0=0
			<cfif not showRemovedPosts>
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif structKeyExists(arguments.params,"lastXDays")>
				AND date(Post.DatePosted) > <cfqueryparam value="#createDate(params.byYear, params.byMonth, params.byDay)#" cfsqltype="cf_sql_date">
			</cfif>
			<!--- Todo: serverOffset --->
			<cfif structKeyExists(arguments.params,"byDay") and not structKeyExists(arguments.params,"byAlias")>
			 	<!--- I am going to search between 24 hours on the given date. --->
				AND Post.DatePosted > <cfqueryparam value="#CreateDateTime(params.byYear, params.byMonth, params.byDay, '00', '00')#" cfsqltype="timestamp">
				AND Post.DatePosted < <cfqueryparam value="#CreateDateTime(params.byYear, params.byMonth, params.byDay, '23', '59')#" cfsqltype="timestamp">
			</cfif>
			<cfif structKeyExists(arguments.params,"byTitle")>
				AND Post.Title = <cfqueryparam value="#arguments.params.byTitle#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<cfif structKeyExists(arguments.params,"byCat")>
				AND Post.PostId IN (
					SELECT PostRef
					FROM PostCategoryLookup
					WHERE CategoryRef IN (#arguments.params.byCat#)
				)
			</cfif>
			<cfif structKeyExists(arguments.params,"byTag")>
				AND Post.PostId IN (
					SELECT PostRef
					FROM PostTagLookup
					WHERE TagRef IN (#arguments.params.byTag#)
				)
			</cfif>
			<cfif structKeyExists(arguments.params,"byPosted")>
				AND User.UserName =  <cfqueryparam value="#arguments.params.byPosted#" cfsqltype="cf_sql_varchar" maxlength="50" list=true>
			</cfif>
			<cfif structKeyExists(arguments.params,"searchTerms")>
				<cfif not structKeyExists(arguments.params, "don'tlogsearch")>
					<cfset logSearch(arguments.params.searchTerms)>
				</cfif>
				AND (
						Post.Title LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
						OR Post.Body LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
						OR Post.MoreBody LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
					)
			</cfif>
			<cfif structKeyExists(arguments.params,"byEntry")>
				AND Post.PostId = <cfqueryparam value="#arguments.params.byEntry#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments.params,"byAlias")>
				AND Post.PostAlias = <cfqueryparam value="#left(arguments.params.byAlias,100)#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<!--- Date operations --->
			<cfif structKeyExists(arguments.params,"byDay")>
				AND day(Post.DatePosted) = <cfqueryparam value="#arguments.params.byDay#" cfsqltype="integer">
			</cfif>
			<cfif structKeyExists(arguments.params,"byMonth")>
				AND month(Post.DatePosted) = <cfqueryparam value="#arguments.params.byMonth#" cfsqltype="integer">
			</cfif>
			<cfif structKeyExists(arguments.params,"byYear")>
				AND year(Post.DatePosted) = <cfqueryparam value="#arguments.params.byYear#" cfsqltype="integer">
			</cfif>
			<!--- Allow admin's to see non-released posts and future posts. --->
			<cfif not application.Udf.isLoggedIn() or (structKeyExists(arguments.params, "releasedOnly") and arguments.params.releasedonly)>
				AND Post.DatePosted < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#blogNow()#">
				<cfif not application.Udf.isLoggedIn()>
					AND Post.Released = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				</cfif>
			</cfif>
			<cfif structKeyExists(arguments.params, "released")>
				AND	Post.Released = <cfqueryparam cfsqltype="cf_sql_bit" value="#arguments.params.released#">
			</cfif>
			AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>	
				
		<cfreturn Data[1]["PostCount"]>
				
	</cffunction>
						
	<cffunction name="insertNewPost" access="public" returnType="numeric" output="true"
			hint="Saves an entry.">
		<cfargument name="author" type="string" required="true" hint="Pass in the userId of the post author">
		<cfargument name="title" type="string" required="true">
		<cfargument name="description" type="string" required="true">
		<cfargument name="datePosted" type="any" required="false" default="">
		<cfargument name="timePosted" type="any" required="false" default="">
		<cfargument name="postUuid" type="string" required="false" default="" hint="Used when importing data from previous versions of BlogCfc">
			
		<!--- See if the post exists by the title --->
		<cfset getPost = getPostByTitle(title)>
			
		<cfif arrayLen(getPost)>
			<!--- If the title exists, return the current postId and don't  insert. The postId is required for the import tasks --->
			<cfreturn getPost[1]["PostId"]>
		<cfelse>
			
			<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
			<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>

			<!--- Create a new alias since the title may change. This won't change unless the title was changed. --->
			<cfset postAlias = application.blog.makeAlias(arguments.title)>
			<!--- Set the UUID --->
			<cfif len(arguments.postUuid)>
				<cfset uuid = arguments.postUuid>
			<cfelse>
				<cfset uuid = createUUID()>
			</cfif>

			<!--- Set the date time. Note: the default date time on the dropdown is the current users time so no extra time zone calculations need to be done here. --->
			<cfif len(arguments.datePosted) and len(arguments.timePosted)>
				<!--- Extract the date.--->
				<cfset dateTimePosted = lsParseDateTime(arguments.datePosted & ' ' & arguments.timePosted)>
			<cfelse>
				<cfset dateTimePosted = blogNow()>	
			</cfif>
			<!---<cfoutput>dateTimePosted #dateTimePosted#</cfoutput>--->

			<!--- **********************************************************************************************
			Populate the Post table. 
			*************************************************************************************************--->

			<cftransaction>
				<!--- Get the user by the username in the Users Obj. --->
				<cfset UserDbObj = entityLoad("Users", { UserId = arguments.author }, "true" )>

				<!--- Create a new Post entity --->
				<cfset PostDbObj = entityNew("Post")>
				<!--- Use the entity objects to set the data. --->
				<cfset PostDbObj.setBlogRef(BlogDbObj)>
				<cfset PostDbObj.setUserRef(UserDbObj)>
				<cfset PostDbObj.setPostAlias(postAlias)>
				<cfset PostDbObj.setTitle(arguments.title)>
				<cfset PostDbObj.setDescription(arguments.description)>
				<!--- The blog sort date here is the same as the date posted --->
				<cfset PostDbObj.setBlogSortDate(dateTimePosted)>
				<cfset PostDbObj.setDatePosted(dateTimePosted)>
				<cfset PostDbObj.setPostUuid(uuid)>
				<cfset PostDbObj.setDate(blogNow())>
				<!--- Save the Post. --->
				<cfset EntitySave(PostDbObj)>
			</cftransaction>

			<cfreturn PostDbObj.getPostId()>
				
		</cfif><!---<cfif arrayLen(getPostByTitle)>--->

	</cffunction>

	<cffunction name="savePost" access="public" returnType="numeric" output="true"
			hint="Saves a post.">
		<cfargument name="postId" type="numeric" required="false">
		<cfargument name="postUuid" type="string" required="false" default="">
		<cfargument name="alias" type="string" required="false" default="">
		<cfargument name="title" type="string" required="true">
		<cfargument name="description" type="string" required="true">
		<cfargument name="themeId" type="string" required="false" default="0">
		<cfargument name="jsonLd" type="string" required="false" default="">
		<cfargument name="postHeader" type="any" required="false" default="">
		<cfargument name="post" type="any" required="false" default="">
		<cfargument name="blogSortDate" type="any" required="false" default="">
		<cfargument name="datePosted" type="any" required="false" default="">
		<cfargument name="timePosted" type="any" required="false" default="">
		<cfargument name="allowcomments" type="boolean" required="false" default="true">
		<cfargument name="mediaId" type="string" required="false" default="">
		<cfargument name="released" type="boolean" required="false" default="true">
		<cfargument name="promote" type="boolean" required="false" default="false">
		<cfargument name="remove" type="boolean" required="false" default="false">
		<cfargument name="postCategories" type="string" required="false" default="">
		<cfargument name="postTags" type="string" required="false" default="">
		<cfargument name="relatedPosts" type="string" required="false" default="">
		<cfargument name="numViews" type="string" required="false" default="">
		<cfargument name="emailSubscriber" type="boolean" required="false" default="false">

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("The post, '#arguments.postid#', does not exist.")>
		</cfif>
			
		<!--- We need to inspect this post to determine if it had been released ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ). --->
		<cfset getPost = application.blog.getPostByPostId(arguments.postId,true,false)>
		<!---<cfdump var="#getPost#" label="getPost"><br/>--->
			
		<!--- Only certain authorized users may release a post. However, we don't  want to change a currently released post if the editor changed some of the text. Note: the session.capabilityList will not be present when importing data from a previous blog version. --->
		<cftry>
			<cfif arguments.postId and not application.blog.isCapabilityAuthorized(session.capabilityList,'ReleasePost')>
				<!--- Is the post in non released status? --->
				<cfif getPost[1]["Released"] neq 1>
					<!--- Keep it non released --->
					<cfset released = 0>
				</cfif>
			<cfelse>
				<cfset released = arguments.released>
			</cfif>
			<cfcatch type="any">
				<cfset released = arguments.released>
			</cfcatch>
		</cftry>

		<!--- Create a new alias since the title may change. This won't change unless the title was changed. --->
		<cfset postAlias = application.blog.makeAlias(arguments.title)>
			
		<!--- Handle the post --->
		<!--- Fix the tags that may come in with a &lt; and &gt; characters that tinyMce puts in. Most of the directives will be used using the postHeader interface which uses a textaread instead of tiny mce. --->
		<cfset arguments.post = RendererObj.renderMoreTagFromTinyMce(arguments.post)>

		<!--- Determine if there are any more blocks --->
		<cfset moreStruct = getMoreBlocksFromPost(arguments.post)>
		<!--- Get the body and more body from the struct. The body is everything before the more tag, more body is everything after. --->
		<cfset body = moreStruct.body>
		<cfset moreBody = moreStruct.moreBody>

		<!--- Set the date time. --->
		<cfif len(arguments.datePosted) and len(arguments.timePosted)>
			<!--- don't modify the date that the user sent in --->
			<cfset dateTimePosted = arguments.datePosted & ' ' & arguments.timePosted>
		<cfelse>
			<!--- Blog now already has the time zone info --->
			<cfset dateTimePosted = blogNow()>	
		</cfif>
			
		<!--- Handle the sort date. This is only different than the date posted when the user wants to sort a blog post in a different order than the sort date. It will only be sent in on occassion. --->
		<cfif len(arguments.blogSortDate)>
			<cfset blogSortDate = arguments.blogSortDate>
		<cfelse>
			<cfset blogSortDate = dateTimePosted>
		</cfif>
			
		<!--- **********************************************************************************************
		Populate the Post table. 
		*************************************************************************************************--->
			
		<cftransaction>
			<!--- Get the user by the username in the Users Obj. --->
			<cfset UserDbObj = entityLoad("Users", { UserId = arguments.author }, "true" )>

			<cfif arguments.postId>
				<!--- Load the entity. --->
				<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
			<cfelse>
				<!--- Create a new Post entity --->
				<cfset PostDbObj = entityNew("Post")>
			</cfif>
			<!--- Use the entity objects to set the data. --->
			<cfif len(arguments.postUuid)>
				<cfset PostDbObj.setPostUuid(arguments.postUuid)>
			</cfif>
			<cfset PostDbObj.setUserRef(UserDbObj)>
			<cfset PostDbObj.setThemeRef(arguments.themeId)>
			<cfset PostDbObj.setPostAlias(postAlias)>
			<cfset PostDbObj.setTitle(arguments.title)>
			<cfset PostDbObj.setDescription(arguments.description)>
			<cfif len(arguments.postHeader)>
				<cfset PostDbObj.setPostHeader(arguments.postHeader)>
			</cfif>
			<cfset PostDbObj.setBody(body)>
			<cfset PostDbObj.setMoreBody(moreBody)>
			<cfset PostDbObj.setReleased(released)>	
			<cfset PostDbObj.setAllowComment(arguments.allowcomments)>
			<cfset PostDbObj.setPromote(arguments.promote)>	
			<cfset PostDbObj.setRemove(arguments.remove)>
			<cfif isNumeric(arguments.numViews)>
				<cfset PostDbObj.setNumViews(arguments.numViews)>
			</cfif>
			<cfset PostDbObj.setBlogSortDate(blogSortDate)>
			<cfset PostDbObj.setDatePosted(dateTimePosted)>
			<cfset PostDbObj.setDate(blogNow())>
				
			<!--- **********************************************************************************************
			When inserting new records, if the mediaId was sent, insert a post reference into the Media table. 
			Note: when updating records, the save media function handles this for us.
			*************************************************************************************************--->

			<cfif not arguments.postId and arguments.mediaId>
				<!--- Instantiate the media obj--->
				<cfset MediaDbObj = entityLoadByPK("Media", arguments.mediaId)>
				<!--- Insert the PostRef into the media table --->
				<cfset MediaDbObj.setPostRef(PostDbObj)>
				<!--- Save Media. --->
				<cfset EntitySave(MediaDbObj)>
					
				<!--- Also, insert the EnclosureMediaRef into the Post table. --->
				<cfset PostDbObj.setEnclosureMediaRef = MediaDbObj>
			</cfif><!---<cfif arguments.mediaId>--->
					
			<!--- **********************************************************************************************
			When inserting new records, if the mapId was sent, insert the post reference into the Map table. 
			Note: when updating records, the save map function does this for us.
			*************************************************************************************************--->
					
			<cfif not arguments.postId and arguments.mapId>
				<!--- Instantiate the media obj--->
				<cfset MapDbObj = entityLoadByPK("Map", arguments.mediaId)>
				<!--- Insert the PostRef into the media table --->
				<cfset MapDbObj.setPostRef(PostDbObj)>
				<!--- Save Media. --->
				<cfset EntitySave(MapDbObj)>
					
				<!--- Also, insert the EnclosureMediaRef into the Post table. --->
				<cfset PostDbObj.setEnclosureMapRef = MapDbObj>
			</cfif><!---<cfif arguments.mediaId>--->
					
			<!--- Finally, save the Post. --->
			<cfset EntitySave(PostDbObj)>
		</cftransaction>
					
		<!--- **********************************************************************************************
		Save post categories 
		*************************************************************************************************--->
		<cfif len(arguments.postCategories)>
			<cfset savePostCategories(arguments.postId, arguments.postCategories) />
		</cfif>
					
		<!--- **********************************************************************************************
		Save post tags 
		*************************************************************************************************--->
		<cfif len(arguments.postTags)>
			<cfset savePostTags(arguments.postId, arguments.postTags) />
		</cfif>
					
		<!--- **********************************************************************************************
		Save the related posts 
		*************************************************************************************************--->
		<cfset saveRelatedPosts(arguments.postId, arguments.relatedPosts) />

		<!--- **********************************************************************************************
		Update cache, and schedule potential future posts.
		*************************************************************************************************--->

		<!--- Update the link cache --->
		<cfif arrayLen(getPost)>
			<!--- For existing posts... --->
			<!---<cfoutput>getPost[1]["PostAlias"]: #getPost[1]["PostAlias"]# getPost[1]["DatePosted"]: #getPost[1]["DatePosted"]#</cfoutput><br/>--->
			<cfset cacheLink(postId=arguments.postId, alias=getPost[1]["PostAlias"], posted=getPost[1]["DatePosted"]) />
		<cfelse>
			<!--- For new posts... --->
			<cfset cacheLink(postId=PostDbObj.getPostId(), alias=postAlias, posted=dateTimePosted) />
		</cfif>

		<!--- Email to the subscribers --->
		<cfif arguments.emailSubscriber>
			
			<!--- Email the post --->
			<cfinvoke component="#application.blog#" method="sendPostEmailToSubscribers" returnvariable="emailSent">
				<cfinvokeargument name="postId" value="#arguments.postId#">
				<!--- Bypass any errors since the admin already confirmed that they want to send the email. --->
				<cfinvokeargument name="byPassErrors" value="true">
			</cfinvoke>

		</cfif><!---<cfif arguments.emailSubscriber>--->
			
		<!--- Handle future posts. --->
		<cfif dateCompare(dateTimePosted, blogNow()) is 1>
			
			<!--- Delete any previous tasks. --->
			<cftry>
				<cfschedule action="delete" task="schedulePost#URL.postId#">
				<cfcatch type="any"><cfset error="Task can't be found"></cfcatch>
			</cftry>
				
			<!--- To shedule the task to run at the correct date, translate the client date to the date on the server. The server may reside in a different time zone than the blog owner --->
			<cfset serverDateTime = application.blog.getServerDateTime(dateTimePosted)>
				
			<!--- Create a task to email and release the post in the future. --->
			<cfschedule action="update" 
				task="schedulePost#postId#" 
				operation="HTTPRequest"
				startDate="#dateFormat(serverDateTime)#" 
				startTime="#timeFormat(serverDateTime)#" 
				url="#application.blogHostUrl#/common/services/handleFuturePost.cfm?postId=#arguments.postId#" 
				interval="once">
		
		</cfif><!---<cfif dateCompare(getPost[1]["DatePosted"], blogNow()) is 1>--->
		
		<!--- Clear the scope cache when the post is released --->
		<cfif released>
			<cfset application.blog.clearScopeCache()>
		</cfif>
			
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>
						
		<cfreturn PostDbObj.getPostId()>

	</cffunction>
			
	<cffunction name="releaseFuturePosts" access="public" returnType="numeric" output="true"
			hint="Handles future posts">
		<cfargument name="postId" type="numeric" required="true">

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("The post, '#arguments.postId#', does not exist.")>
		</cfif>

		<!--- **********************************************************************************************
		Release the post. 
		*************************************************************************************************--->
			
		<cftransaction>
			<!--- Load the entity. --->
			<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
			<cfset PostDbObj.setReleased(true)>
			<cfset PostDbObj.setDate(blogNow())>		
			<!--- Save the Post. --->
			<cfset EntitySave(PostDbObj)>
		</cftransaction>
				
		<!--- **********************************************************************************************
		Send email
		*************************************************************************************************--->
				
		<cfinvoke component="#application.blog#" method="sendPostEmailToSubscribers" returnvariable="emailSent">
			<cfinvokeargument name="postId" value="#arguments.postId#">
			<!--- Bypass any errors since the admin already confirmed that they want to send the email. --->
			<cfinvokeargument name="byPassErrors" value="true">
		</cfinvoke>
		
		<!--- Clear the cache --->
		<cfset application.blog.clearScopeCache()>
						
		<cfreturn PostDbObj.getPostId()>

	</cffunction>
				
	<cffunction name="savePostHeader" access="public" returnType="numeric" output="true"
			hint="Saves the post header.">
		<cfargument name="postId" type="numeric" required="false">
		<cfargument name="postHeader" type="string" required="false" default="">

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("The post, '#arguments.postId#', does not exist.")>
		</cfif>

		<!--- **********************************************************************************************
		Populate the Post Header. 
		*************************************************************************************************--->
			
		<cftransaction>
			<!--- Load the entity. --->
			<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
			<cfset PostDbObj.setPostHeader(arguments.postHeader)>
			<cfset PostDbObj.setDate(blogNow())>		
			<!--- Save the Post. --->
			<cfset EntitySave(PostDbObj)>
		</cftransaction>
						
		<cfreturn PostDbObj.getPostId()>

	</cffunction>
				
	<cffunction name="savePostCss" access="public" returnType="numeric" output="true"
			hint="Saves the post CSS.">
		<cfargument name="postId" type="numeric" required="false">
		<cfargument name="postCss" type="string" required="false" default="">

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("The post, '#arguments.postId#', does not exist.")>
		</cfif>

		<!--- **********************************************************************************************
		Populate the Post CSS. 
		*************************************************************************************************--->
			
		<cftransaction>
			<!--- Load the entity. --->
			<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
			<cfset PostDbObj.setCSS(arguments.postCss)>
			<cfset PostDbObj.setDate(blogNow())>		
			<!--- Save the Post. --->
			<cfset EntitySave(PostDbObj)>
		</cftransaction>
						
		<cfreturn PostDbObj.getPostId()>

	</cffunction>
				
	<cffunction name="savePostJavaScript" access="public" returnType="numeric" output="true"
			hint="Saves the post JavaScript.">
		<cfargument name="postId" type="numeric" required="false">
		<cfargument name="postJavaScript" type="string" required="false" default="">

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("The post, '#arguments.postId#', does not exist.")>
		</cfif>

		<!--- **********************************************************************************************
		Populate the Post CSS. 
		*************************************************************************************************--->
			
		<cftransaction>
			<!--- Load the entity. --->
			<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
			<cfset PostDbObj.setJavaScript(arguments.postJavaScript)>
			<cfset PostDbObj.setDate(blogNow())>		
			<!--- Save the Post. --->
			<cfset EntitySave(PostDbObj)>
		</cftransaction>
						
		<cfreturn PostDbObj.getPostId()>

	</cffunction>
						
	<cffunction name="savePostAlias" access="public" returnType="numeric" output="true"
			hint="Saves the post alias.">
		<cfargument name="postId" type="numeric" required="false">
		<cfargument name="postAlias" type="string" required="false" default="">

		<cfif not postExists(arguments.postId)>
			<cfset variables.utils.throw("The post, '#arguments.postId#', does not exist.")>
		</cfif>

		<!--- **********************************************************************************************
		Populate the Post Alias. 
		*************************************************************************************************--->
			
		<cftransaction>
			<!--- Load the entity. --->
			<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
			<cfset PostDbObj.setPostAlias(arguments.postAlias)>
			<cfset PostDbObj.setDate(blogNow())>		
			<!--- Save the Post. --->
			<cfset EntitySave(PostDbObj)>
		</cftransaction>
				
		<!--- Clear the scope cache --->
		<cfset application.blog.clearScopeCache()>
						
		<cfreturn PostDbObj.getPostId()>

	</cffunction>
		
	<cffunction name="deletePost" access="public" returnType="void" output="false"
			hint="Replaces the deleteEntry function">
		<cfargument name="postId" type="numeric" required="true">
			
		<cftransaction>
			
			<!--- Load the post object --->
			<cfset PostDbObj = entityLoadByPK("Post", arguments.postId)>
			<!--- Remove the enclosures so that we don't get a constraint errors --->
			<cfset PostDbObj.setEnclosureMedia(javaCast("null",""))>
			<!--- Set the enclosureMap column to null. --->
			<cfset PostDbObj.setEnclosureMap(javaCast("null",""))>
			<!---And set the enclosureCarousel to null--->
			<cfset PostDbObj.setEnclosureCarousel(javaCast("null",""))>
				
			<!--- Delete the post media --->
			<cfquery name="Data" dbtype="hql">
				DELETE FROM PostMedia
				WHERE 
					PostRef = #PostDbObj.getPostId()#
			</cfquery>
					
			<!--- Delete the associated post categories --->
			<cfquery name="Data" dbtype="hql">
				DELETE FROM PostCategoryLookup
				WHERE 
					PostRef = #PostDbObj.getPostId()#
			</cfquery>
				
			<!--- Delete related posts. --->
			<cfquery name="Data" dbtype="hql">
				DELETE FROM RelatedPost
				WHERE 
					PostRef = #PostDbObj.getPostId()#
					OR RelatedPostRef = #PostDbObj.getPostId()#
			</cfquery>

			<!--- And delete the comments. --->
			<cfquery name="Data" dbtype="hql">
				DELETE FROM Comment
				WHERE 
					PostRef = #PostDbObj.getPostId()#
			</cfquery>
					
			<!--- Finally, delete the post record --->
			<cfquery name="Data" dbtype="hql">
				DELETE FROM Post
				WHERE 
					PostId = #PostDbObj.getPostId()#
			</cfquery>
				
			<!--- Delete the PostDbObj variable to ensure that the record doesn't stick around and is deleted from ORM memory. --->
			<cftry>
				<cfset void = structDelete( variables, "PostDbObj" )>
				<cfcatch type="Any"></cfcatch>
			</cftry>
			
		</cftransaction>
				
		<!--- Clear the scope cache --->
		<cfset application.blog.clearScopeCache()>
				
	</cffunction>
				
	<cffunction name="removeAllEnclosures" access="remote" output="true" returnformat="json"
			hint="This removes all post enclosures from a post. This function is not used yet">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="postId" default="" required="yes">
		
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<cfset debug = false>
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfreturn serializeJSON(false)>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
		
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<!---<cfoutput>arguments.externalUrl: #arguments.externalUrl#</cfoutput>--->
			
		<cfif application.Udf.isLoggedIn()>
			
			<cftransaction>
				<!--- Load the entity. --->
				<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
				<!--- Set the enclosureMedia column. Note: this is a psuedo name. The actual column is Post.EnclosureMediaRef --->
				<cfset PostDbObj.setEnclosureMedia(javaCast("null",""))>
				<!--- Set the enclosureMap column to null. --->
				<cfset PostDbObj.setEnclosureMap(javaCast("null",""))>
				<!---And set the enclosureCarousel to null--->
				<cfset PostDbObj.setEnclosureCarousel(javaCast("null",""))>
				
				<!--- Save the Post. --->
				<cfset EntitySave(PostDbObj)>
			</cftransaction>
			
			<cfreturn arguments.postId>
		<cfelse>
			<cfreturn 0>
		</cfif>
					
	</cffunction>
				
	<!--- //***********************************************************************************************
			Post Inspection Functions
	//*************************************************************************************************--->

	<!--- We can now use cfincludes and other stuff in the post. I put this into a function as I anticipate that this methodology will be used for other purposes other than a cfinclude.  --->
	<cffunction name="inspectPostContentForXmlKeywords" access="public" returntype="string" 
			hint="Determines if there is any action needed if the post content contains certain keywords. Returns a list of keywords if the xml keyword has been found.">
		<cfargument name="postContent" required="yes" hint="Pass in the post body">

		<!--- Preset the var as an empty string. --->
		<cfset xmlKeyWords="">
				
		<!--- 
		Notes: as of version 3, all of these are placed in the PostHeader column.
		Some may wonder why I chose this weird format for the directives. Prior to version 3 I needed to include these tags in the actual post, and the original method allowed me to hide the tags and code from being displayed. Using <cfincludeTemplate>path</cfincludeTemplate> would show the content between the tags (ie path) and it was quick to deploy. However, in version 3 I don't need to display these tags in the actual post and am instead putting them in a different column in the database. 
		--->
		<!--- Use a cfinclude. --->
		<cfif arguments.postContent contains "<cfincludeTemplate:" or arguments.postContent contains "<cfincludeTemplate>">
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "cfincludeTemplate">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "cfincludeTemplate">
			</cfif>
		</cfif>

		<!--- Meta tags. --->
		<cfif arguments.postContent contains "<titleMetaTag:" or arguments.postContent contains "<titleMetaTag>">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "titleMetaTag">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "titleMetaTag">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<descMetaTag:" or arguments.postContent contains "<descMetaTag>">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "descMetaTag">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "descMetaTag">
			</cfif>
		</cfif>

		<!--- Social media sharing. --->
		<!--- Images --->
		<cfif arguments.postContent contains "<facebookImageUrlMetaData:" or arguments.postContent contains "<facebookImageUrlMetaData>">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "facebookImageUrlMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "facebookImageUrlMetaData">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<twitterImageUrlMetaData:" or arguments.postContent contains "<twitterImageUrlMetaData>">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "twitterImageUrlMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "twitterImageUrlMetaData">
			</cfif>
		</cfif>	

		<!--- Media --->
		<cfif arguments.postContent contains "<facebookVideoUrlMetaData:" or arguments.postContent contains "<facebookVideoUrlMetaData>">
			<!--- Get the facebook video url if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "facebookVideoUrlMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "facebookVideoUrlMetaData">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<twitterVideoUrlMetaData:" or arguments.postContent contains "<twitterVideoUrlMetaData>">
			<!--- Get the twitter video url if available. If this argument is set, the twitter card will change from 'summary_large_image' to 'player'. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "twitterVideoUrlMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "twitterVideoUrlMetaData">
			</cfif>
		</cfif>	

		<!--- Custom social media description (I am not using this in Gregory's Blog yet) --->
		<cfif arguments.postContent contains "<socialMediaDescMetaData:" or arguments.postContent contains "<socialMediaDescMetaData>">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "socialMediaDescMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "socialMediaDescMetaData">
			</cfif>
		</cfif>

		<!--- Media player arguments --->
		<cfif arguments.postContent contains "<videoType:" or arguments.postContent contains "<videoType>">
			<!--- The video type will be either video/mp4, video/webm, audio/mp3, audio/ogg, YouTube, or Vimeo --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoType">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoType">
			</cfif>
		</cfif>
		<!--- The image on top of the video when it does not play. --->
		<cfif arguments.postContent contains "<videoPosterImageUrl:" or arguments.postContent contains "<videoPosterImageUrl>">
			<!--- Get the social media image description if available. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoPosterImageUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoPosterImageUrl">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<smallVideoSourceUrl:" or arguments.postContent contains "<smallVideoSourceUrl>">
			<!--- We are supplying different sizes to fit the device. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "smallVideoSourceUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "smallVideoSourceUrl">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<mediumVideoSourceUrl:" or arguments.postContent contains "<mediumVideoSourceUrl>">
			<!--- We are supplying different sizes to fit the device. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "mediumVideoSourceUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "mediumVideoSourceUrl">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<largeVideoSourceUrl:" or arguments.postContent contains "<largeVideoSourceUrl>">
			<!--- We are supplying different sizes to fit the device. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "largeVideoSourceUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "largeVideoSourceUrl">
			</cfif>
		</cfif>
		<!--- Video captions --->
		<cfif arguments.postContent contains "<videoCaptionsUrl:" or arguments.postContent contains "<videoCaptionsUrl>">
			<!--- Supply the link to the WebVTT file --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoCaptionsUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoCaptionsUrl">
			</cfif>
		</cfif>
		<!--- Set videoCrossOrigin to true when using media outside of your own site. --->
		<cfif arguments.postContent contains "<videoCrossOrigin:" or arguments.postContent contains "<videoCrossOrigin>">
			<!--- Get the cross origin property --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoCrossOrigin">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoCrossOrigin">
			</cfif>
		</cfif>

		<!--- The next two blocks, videoWidthMetaData and videoHeightMetaData, apply to both facebook and twitter. --->
		<cfif arguments.postContent contains "<videoWidthMetaData:" or arguments.postContent contains "<videoWidthMetaData>">
			<!--- Get the width. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoWidthMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoWidthMetaData">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<videoHeightMetaData:" or arguments.postContent contains "<videoHeightMetaData>">
			<!--- meta data. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "videoHeightMetaData">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "videoHeightMetaData">
			</cfif>
		</cfif>	

		<!--- YouTube  --->
		<cfif arguments.postContent contains "<youTubeUrl:" or arguments.postContent contains "<youTubeUrl>">
			<!--- Get the url. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "youTubeUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "youTubeUrl">
			</cfif>
		</cfif>	

		<!--- Vimeo  --->
		<cfif arguments.postContent contains "<vimeoVideoId:" or arguments.postContent contains "<vimeoVideoId>">
			<!--- Get the url. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "vimeoVideoId">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "vimeoVideoId">
			</cfif>
		</cfif>	

		<!--- Structured data (Not used yet) --->
		<cfif arguments.postContent contains "<articleStructuredOrgLogoUrl:" or arguments.postContent contains "<articleStructuredOrgLogoUrl>">
			<!--- Include the full path to the org logo. The org logo should be 112x112px at a minimum. --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "articleStructuredOrgLogoUrl">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "articleStructuredOrgLogoUrl">
			</cfif>
		</cfif>
		<!--- Google prefers to have 3 images: a 16/9 image, 4/3 and a 1/1.  --->
		<cfif arguments.postContent contains "<includeGoogleStructuredImage16_9:" or arguments.postContent contains "<includeGoogleStructuredImage16_9>">
			<!--- The 16x9 image is 1200 pixels wide and 675 wide. The Image.cfc will autormatically create this image when making a post and save it to the /enclosures/google/16_9 directory if it can.  --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "includeGoogleStructuredImage16_9">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "includeGoogleStructuredImage16_9">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<includeGoogleStructuredImage4_3:" or arguments.postContent contains "<includeGoogleStructuredImage4_3>">
			<!--- The 16x9 image is 1100 pixels wide and 825 wide. The Image.cfc will autormatically create this image when making a post and save it to the /enclosures/google/4_3 directory if it can.  --->
			<cfif xmlKeyWords eq "">
				<cfset xmlKeyWords = "includeGoogleStructuredImage4_3">
			<cfelse>
				<cfset xmlKeyWords = xmlKeyWords & "," & "includeGoogleStructuredImage4_3">
			</cfif>
		</cfif>
		<cfif arguments.postContent contains "<includeGoogleStructuredImage1_1:" or arguments.postContent contains "<includeGoogleStructuredImage1_1>">
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
					
	<cffunction name="getXmlKeywordStruct" access="public" returnType="any" output="true"
			hint="Gets the XML keywords from the post header">
		<cfargument name="postHeader" type="string" required="false" default="">

		<!--- Inspect they xml keywords for directives. --->
		<cfset xmlKeywords = application.blog.inspectPostContentForXmlKeywords(postHeader)>
		<!---<cfoutput>xmlKeywords: #xmlKeywords#</cfoutput>--->
			
		<!--- Preset vars --->
		<cfscript>
		cfincludePath = "";
		videoDirective = "";
		videoType = "";
		youTubeUrl = "";
		vimeoVideoId = "";
		videoPosterImageUrl = "";
		smallVideoSourceUrl = "";
		mediumVideoSourceUrl = "";
		largeVideoSourceUrl = "";
		videoCaptionsUrl = "";
		videoCrossOrigin = "";			
		</cfscript>

		<!--- Get all of the xml keywords --->
		<!--- Cfinclude. This takes precedent above the enclosure and post. If an include was made, no other post content will be displayed --->
		<cfif findNoCase("cfincludeTemplate", xmlKeywords) gt 0>
			<!--- Inject the include. Note: there is no enclosure or body here. --->
			<cfset cfincludePath = application.blog.getXmlKeywordValue(postHeader, 'cfincludeTemplate')>
		<cfelse><!---<cfif findNoCase("cfincludeTemplate", xmlKeywords) gt 0>--->

			<!--- Handle video directives. --->				
			<!--- Determine if there are video related directives --->
			<cfif findNoCase("videoType", xmlKeywords) gt 0> 
				<cfset videoType = application.blog.getXmlKeywordValue(postHeader, 'videoType')>
				<cfset videoDirective = true>
			</cfif>
			<cfif findNoCase("youTubeUrl", xmlKeywords) gt 0> 
				<cfset youTubeUrl = application.blog.getXmlKeywordValue(postHeader, 'youTubeUrl')>
				<cfset videoDirective = true>
			</cfif>
			<cfif findNoCase("vimeoVideoId", xmlKeywords) gt 0> 
				<cfset vimeoVideoId = application.blog.getXmlKeywordValue(postHeader, 'vimeoVideoId')>
				<cfset videoDirective = true>
			</cfif>
			<cfif findNoCase("videoPosterImageUrl", xmlKeywords) gt 0> 
				<cfset videoPosterImageUrl = application.blog.getXmlKeywordValue(postHeader, 'videoPosterImageUrl')>
				<cfset videoDirective = true>
			</cfif>	
			<cfif findNoCase("smallVideoSourceUrl", xmlKeywords) gt 0> 
				<cfset smallVideoSourceUrl = application.blog.getXmlKeywordValue(postHeader, 'smallVideoSourceUrl')>
				<cfset videoDirective = true>
			</cfif>
			<cfif findNoCase("mediumVideoSourceUrl", xmlKeywords) gt 0> 
				<cfset mediumVideoSourceUrl = application.blog.getXmlKeywordValue(postHeader, 'mediumVideoSourceUrl')>
				<cfset videoDirective = true>
			</cfif>
			<cfif findNoCase("largeVideoSourceUrl", xmlKeywords) gt 0> 
				<cfset largeVideoSourceUrl = application.blog.getXmlKeywordValue(postHeader, 'largeVideoSourceUrl')>
				<cfset videoDirective = true>
			</cfif>
			<cfif findNoCase("videoCaptionsUrl", xmlKeywords) gt 0> 
				<cfset videoCaptionsUrl = application.blog.getXmlKeywordValue(postHeader, 'videoCaptionsUrl')>
				<cfset videoDirective = true>
			</cfif>
			<cfif findNoCase("videoCrossOrigin", xmlKeywords) gt 0> 
				<cfset videoCrossOrigin = application.blog.getXmlKeywordValue(postHeader, 'videoCrossOrigin')>
				<cfset videoDirective = true>
			</cfif>
		</cfif>

		<!--- Preset vars and create a structure --->
		<cfscript>			
		xmlKeywordsStruct=StructNew();
			
		xmlKeywordsStruct.cfincludePath = cfincludePath;
		xmlKeywordsStruct.videoDirective = videoDirective;
		xmlKeywordsStruct.youTubeUrl = youTubeUrl;
		xmlKeywordsStruct.vimeoVideoId = vimeoVideoId;
		xmlKeywordsStruct.videoType = videoType;
		xmlKeywordsStruct.videoPosterImageUrl = videoPosterImageUrl;
		xmlKeywordsStruct.smallVideoSourceUrl = smallVideoSourceUrl;
		xmlKeywordsStruct.mediumVideoSourceUrl = mediumVideoSourceUrl;
		xmlKeywordsStruct.largeVideoSourceUrl = largeVideoSourceUrl;
		xmlKeywordsStruct.videoCaptionsUrl = videoCaptionsUrl;
		xmlKeywordsStruct.videoCrossOrigin = videoCrossOrigin;
		</cfscript>

		<cfreturn xmlKeywordsStruct>

	</cffunction>

	<cffunction name="getXmlKeywordValue" access="public" output="true" returntype="string" 
			hint="Gets the variable in one of our xml strings.">
		<cfargument name="postContent" required="yes" hint="The post content is typically 'RendererObj.renderBody(body,mediaPath)'.">
		<cfargument name="xmlKeyword" required="yes" hint="Grab the keyword from the inspectPostContent function.">
		<cfargument name="xmlVersion" required="no" default="2" hint="I changed the structure to a more standard format on version 2.">
		
		<cfparam name="keyWordValue" default="">
			
		<cfif xmlVersion eq 2>
			<!--- Get the keyword using jSoup --->
			<cfobject component="#application.jsoupComponentPath#" name="JSoupObj">
			<cfset keyWordValue = JSoupObj.getTagFromPost(postContent,xmlKeyword)>
		
		<cfelse>
			<!---Get the keyword by the string position--->
			<cftry>

				<!--- Set the strings that we're searching for. --->
				<cfset keyWordStartString = "<" & arguments.xmlKeyword & ">">
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
				<cfset keyWordValue = mid(arguments.postContent, keyWordValueStartPos, valueCount)>
				<!---<cfoutput>keyWordValue:#keyWordValue#</cfoutput>--->

				<cfcatch type="any">
					<cfset error = cfcatch.detail>
				</cfcatch>

			</cftry>
					
		</cfif>

		<!--- Return the value --->
		<cfreturn keyWordValue>

	</cffunction>
				
	<!---******************************************************************************************************** 
		Post Logging and Statistics
	*********************************************************************************************************--->

	<cffunction name="logSearch" access="private" returnType="void" output="false"
			hint="Logs the search.">
		<cfargument name="searchterm" type="string" required="true">
			
		<!--- Sanitize the search term --->
		<cfset sanitizedSearchTerm = sanitizeString(arguments.searchTerm)>
			
		<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
		<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>

		<!--- Load the entity. --->
		<cfset SearchQueryObj = entityNew("SearchQuery")>
		<!--- Use the entity objects to set the data. --->
		<cfset SearchQueryObj.setBlogRef(BlogDbObj)>
		<cfset SearchQueryObj.setSearchQuery(sanitizedSearchTerm)>
		<cfset SearchQueryObj.setDate(blogNow())>

		<!--- Save it. --->
		<cfset EntitySave(SearchQueryObj)>

	</cffunction>

	<cffunction name="logView" access="public" returnType="void" output="false"
				hint="Handles adding a view to an entry.">
		<cfargument name="postId" type="numeric" required="true">
			
		<cfquery name="Data" dbtype="hql">
			UPDATE Post
			SET NumViews = NumViews + 1
			WHERE PostId = <cfqueryparam value="#arguments.postId#" cfsqltype="integer" maxlength="35">
		</cfquery>

	</cffunction>
				
	<!---******************************************************************************************************** 
		Media functions
	*********************************************************************************************************--->
				
	<cffunction name="getPostEnclosureMediaIdByUrl" access="public" returnType="numeric" output="false"
			hint="Used to determine if the media exists by a given postId and url. Used on media uploads to determine if we should update the media record or insert a new one.">
		<cfargument name="postId" type="numeric" required="true">
		<cfargument name="mediaUrl" type="string" required="true">
	
		<!--- Get the current enclosure for this post --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				<!--- Traverse Media object to get the MediaId. --->
				Enclosure.MediaId as MediaId,
				Enclosure.MediaUrl as MediaUrl
			)
			FROM Post as Post 
			<!--- Assets is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.EnclosureMedia as Enclosure
			WHERE 0=0
				AND Post.PostId = <cfqueryparam value="#arguments.postId#">	
				AND Enclosure.MediaUrl = <cfqueryparam value="#arguments.mediaUrl#">	
				AND Enclosure.MediaId <> ''
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset mediaId = Data[1]["MediaId"]>
		<cfelse>
			<cfset mediaId = 0>
		</cfif>
			
		<!--- Return it --->
		<cfreturn mediaId>
			
	</cffunction>
		
	<cffunction name="getEnclosureMediaIdByPostId" access="public" returnType="numeric" output="false"
			hint="This returns the mediaId of the post enclosure">
		<cfargument name="postId" type="numeric" required="true">
	
		<!--- Get the current enclosure for this post --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				<!--- Traverse Media object to get the MediaId. --->
				Enclosure.MediaId as MediaId
			)
			FROM Post as Post 
			<!--- Assets is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.EnclosureMedia as Enclosure
			WHERE 0=0
				AND Post.PostId = <cfqueryparam value="#arguments.postId#">	
				AND Enclosure.MediaId <> ''
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset mediaId = Data[1]["MediaId"]>
		<cfelse>
			<cfset mediaId = 0>
		</cfif>
			
		<!--- Return it --->
		<cfreturn mediaId>
			
	</cffunction>
			
	<cffunction name="getMediaUrlByMediaId" access="public" returnType="string" output="false"
			hint="Extract the media URL for a given mediaId">
		<cfargument name="mediaId" type="numeric" required="true">
			
		<cfparam name="mediaUrl" default="">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				MediaUrl as MediaUrl,
				MediaThumbnailUrl as MediaThumbnailUrl
			)
			FROM Media
			WHERE MediaId = <cfqueryparam value="#arguments.mediaId#" cfsqltype="integer">
		</cfquery>
			
		<!--- Return it --->
		<cfif arrayLen(Data)>
			<cfset mediaUrl = Data[1]["MediaUrl"]>
		</cfif>
		<cfreturn mediaUrl>
			
	</cffunction>
			
	<cffunction name="getEnclosureUrlFromMediaPath" access="public" returnType="string" output="true"
			hint="Helper function to extract the enclosures mediaUrl from the mediaPath.">
		<cfargument name="mediaPath" type="string" required="true">
		<cfargument name="returnAbsolutePath" type="boolean" required="false" default="true" hint="If set to true, this only returns the absolute path minus the domain name (ie https://www.google.com)">
			
		<cfparam name="enclosureUrl" default="">
		
		<!--- Note: the getFileFromPath is a native ColdFusion function. --->
		<cfif arguments.returnAbsolutePath>
			<cfset enclosureUrl = application.baseUrl & "/enclosures/" & getFileFromPath(arguments.mediaPath)>
		<cfelse>
			<cfset enclosureUrl = application.baseUrl & "/enclosures/" & arguments.mediaPath>
		</cfif>
			
		<cfreturn enclosureUrl>
			
	</cffunction>
		
	<cffunction name="getPostMedia" access="public" returnType="array" output="false"
			hint="Gets all of the media for a given post. The other functions just return the enclosure record.">
		<cfargument name="postId" type="string" required="true">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				<!--- The PostMedia.MediaRef is an ORM obect that we are traversing to get the featured image from. This data is in the Media table and has a many to many relationship, but since there is only one featured image, there won't be duplicate records here. --->
				PostAssets.MediaRef.MediaId as MediaId,
				PostAssets.MediaRef.MediaHeight as MediaHeight,
				PostAssets.MediaRef.MediaTypeRef.MediaType as MediaType,
				PostAssets.MediaRef.MimeTypeRef.MimeType as MimeType,
				PostAssets.MediaRef.MediaTitle as MediaTitle,
				PostAssets.MediaRef.MediaWidth as MediaWidth,
				PostAssets.MediaRef.MediaHeight as MediaHeight,
				PostAssets.MediaRef.MediaPath as MediaPath,
				PostAssets.MediaRef.MediaUrl as MediaUrl)
			FROM Post as Post 
			LEFT JOIN Post.PostAssets as PostAssets
			WHERE 0=0
				AND Post.PostId = <cfqueryparam value="#arguments.postId#">
				AND MediaId <> ''
		</cfquery>
		
		<cfreturn Data>
			
	</cffunction>
		
	<cffunction name="insertMediaRecord" access="public" returnType="string" output="true"
			hint="Inserts a media database record after a file upload">
		<cfargument name="mediaPath" type="string" required="true">
		<cfargument name="mediaUrl" type="string" required="true">
		<cfargument name="mediaThumbnailUrl" type="string" default="" required="false">
		<cfargument name="mediaType" type="string" required="true">
		<!--- Optional args --->
		<!--- Mime types may not be available for external links --->
		<cfargument name="mimeType" type="string" default="" required="false">
		<cfargument name="enclosure" type="boolean" default="false" required="false">
		<cfargument name="mediaTitle" type="string" default="" required="false">
		<cfargument name="mediaHeight" type="string" default="" required="false">
		<cfargument name="mediaWidth" type="string" default="" required="false">
		<cfargument name="mediaSize" type="string" default="" required="false">
		<cfargument name="providerVideoId" type="string" default="" required="false">
		<!--- Media can be placed into either a comment or a post. --->
		<cfargument name="postId"  default="" required="false">
		<cfargument name="commentId" default="" required="false">
			
		<cftransaction>
					
			<!--- Load the media type and media ORM database objects. --->
			<cfif len(arguments.mediaType)>
				<cfset MediaTypeDbObj = entityLoad("MediaType", { MediaTypeStrId = arguments.mediaType }, "true" )>
			</cfif> 
			<!--- Load the mime type --->
			<cfif len(arguments.mimeType)>
				<cfset MimeTypeDbObj = entityLoad("MimeType", { MimeType = arguments.mimeType }, "true" )>
			</cfif>
			<!--- If this is an enclosure, load the post object --->
			<cfif arguments.enclosure and arguments.postId neq ''>
				<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
			</cfif>

			<!--- ************************* Save the data into the database ************************* --->
			<!--- Instantiate the media object --->
			<cfset MediaDbObj = entityNew("Media")>
			<cfif arguments.mediaType neq "">
				<cfset MediaDbObj.setMediaTypeRef(MediaTypeDbObj)>
			</cfif>
			<!--- The mime type may be coming in incorrectly and is not being properly loaded in the code above. Check on next version. --->
			<cfif len(arguments.mimeType) and isDefined("MimeTypeDbObj")>
				<cfset MediaDbObj.setMimeTypeRef(MimeTypeDbObj)>
			</cfif>
			<cfset MediaDbObj.setMediaTitle(arguments.mediaTitle)>
			<cfset MediaDbObj.setMediaPath(arguments.mediaPath)><!---destination & UploadFileObj.serverFile--->
			<cfset MediaDbObj.setMediaUrl(arguments.mediaUrl)><!---imageUrl--->
			<cfset MediaDbObj.setMediaThumbnailUrl(arguments.mediaThumbnailUrl)><!---imageUrl--->
			<cfset MediaDbObj.setMediaHeight(arguments.mediaHeight)><!---imageInfo.height--->
			<cfset MediaDbObj.setMediaWidth(arguments.mediaWidth)><!---imageInfo.width--->
			<cfset MediaDbObj.setMediaSize(arguments.mediaSize)><!---UploadFileObj.filesize--->
			<cfset MediaDbObj.setProviderVideoId(arguments.providerVideoId)>
			<cfset MediaDbObj.setDate(application.blog.blogNow())>

			<!--- Save the postId and commentId into the junction tables if they were supplied. --->

			<!--- Save the postId into the junction table when updating a post. --->
			<cfif len(arguments.postId)>
				<!--- Load the post entity --->
				<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
				<!--- If this is an enclosure, populate the enclosure column with the mediaId --->
				<cfif arguments.enclosure>
					<!--- Set the enclosureMedia column. Note: this is a psuedo name. The actual column is Post.EnclosureMediaRef --->
					<cfset PostDbObj.setEnclosureMedia(MediaDbObj)>
					
					<!--- Remove all other enclosure types --->
					<!--- Set the enclosureMap column to null. --->
					<cfset PostDbObj.setEnclosureMap(javaCast("null",""))>
					<!--- And set the enclosureCarousel to null--->
					<cfset PostDbObj.setEnclosureCarousel(javaCast("null",""))>
				</cfif>
					
				<!--- Create a new PostMedia entity --->
				<cfset PostMediaDbObj = entityNew("PostMedia")>
				<!--- Set data in the post media table --->
				<cfset PostMediaDbObj.setPostRef(PostDbObj)>
				<cfset PostMediaDbObj.setMediaRef(MediaDbObj)>
				<cfset PostMediaDbObj.setDate(application.blog.blogNow())>
				<!--- Save it --->
				<cfset EntitySave(PostMediaDbObj)>
			</cfif>
					
			<!--- Save the commentId into the junction table when updating a comment. --->
			<cfif len(arguments.commentId)>
				<!--- Load the comment entity --->
				<cfset CommentDbObj = entityLoad("Comment", { CommentId = arguments.commentId }, "true" )>
				<!--- Create a new CommentMedia entity --->
				<cfset CommentMediaDbObj = entityNew("CommentMedia")>
				<!--- Set data --->
				<cfset CommentMediaDbObj.setCommentRef(CommentDbObj)>
				<cfset CommentMediaDbObj.setMediaRef(MediaDbObj)>
				<cfset CommentMediaDbObj.setDate(application.blog.blogNow())>
				<!--- Save it --->
				<cfset EntitySave(CommentMediaDbObj)>
			</cfif>

			<!--- Save the post object if the postId was sent in --->
			<cfif len(arguments.postId) gt 0>
				<cfset EntitySave(PostDbObj)>
			</cfif>
			<!--- Save the media entity. --->
			<cfset EntitySave(MediaDbObj)>
			
		</cftransaction>

		<!--- And return the MediaId --->
		<cfreturn MediaDbObj.getMediaId()>
	
	</cffunction>
				
	<cffunction name="updateMediaRecord" access="public" returnType="string" output="true"
			hint="Updates a media database record after a file upload or a url to an external image source has been provided.">
		<!--- The mediaId argument is the only required argument. All other args are not required. --->
		<cfargument name="mediaId" type="string" required="true">
		<!--- Non required args --->
		<cfargument name="mediaPath" type="string" default="" required="false">
		<cfargument name="mediaUrl" type="string" default="" required="false">
		<cfargument name="mediaThumbnailUrl" type="string" default="" required="false">
		<cfargument name="mediaType" type="string" default="" required="false">
		<!--- Optional args --->
		<cfargument name="mimeType" type="string" default="" required="false">
		<cfargument name="enclosure" type="boolean" default="false" required="false">
		<cfargument name="mediaTitle" type="string" default="" required="false">
		<cfargument name="mediaWidth" type="string" default="" required="false">
		<cfargument name="mediaHeight" type="string" default="" required="false">
		<cfargument name="mediaSize" type="string" default="" required="false">
		<!--- Video captions and cover --->
		<cfargument name="mediaVideoCoverUrl" type="string" default="" required="false">
		<cfargument name="mediaVideoVttFileUrl" type="string" default="" required="false">
		<cfargument name="providerVideoId" type="string" default="" required="false">
		<!--- Media can be placed into either a comment or a post. --->
		<cfargument name="postId"  default="" required="false">
		<cfargument name="commentId" default="" required="false">
			
		<cftransaction>
					
			<!--- Load the media type and media ORM database objects if the arguments are present. --->
			<cfif len(arguments.MediaType) gt 0> 
				<cfset MediaTypeObj = entityLoad("MediaType", { MediaTypeStrId = arguments.mediaType }, "true" )> 
			</cfif>
			<!--- Load the mime type --->
			<cfif len(arguments.mimeType) gt 0> 
				<cfset MimeTypeDbObj = entityLoad("MimeType", { MimeType = arguments.mimeType }, "true" )>
			</cfif>
			<!--- If this is an enclosure, load the post object --->
			<cfif arguments.enclosure and arguments.postId neq ''>
				<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
			</cfif>

			<!--- ************************* Save the data into the database ************************* --->
			<!--- Instantiate the media object --->
			<cfset MediaDbObj = entityLoad("Media", { MediaId = arguments.mediaId }, "true" )>
			<cfif len(arguments.MediaType) gt 0 and isDefined("MediaTypeObj")> 
				<cfset MediaDbObj.setMediaTypeRef(MediaTypeObj)>
			</cfif>
			<cfif len(arguments.mimeType) gt 0 and isDefined("MimeTypeDbObj")> 
				<cfset MediaDbObj.setMimeTypeRef(MimeTypeDbObj)>
			</cfif>
			<cfif len(arguments.mediaTitle) gt 0>
				<cfset MediaDbObj.setMediaTitle(arguments.mediaTitle)>
			</cfif>
			<cfif len(arguments.mediaPath) gt 0>
				<cfset MediaDbObj.setMediaPath(arguments.mediaPath)>
			</cfif>
			<cfif len(arguments.mediaUrl) gt 0>
				<cfset MediaDbObj.setMediaUrl(arguments.mediaUrl)>
			</cfif>
			<cfif len(arguments.mediaThumbnailUrl) gt 0>
				<cfset MediaDbObj.setMediaThumbnailUrl(arguments.mediaThumbnailUrl)>
			</cfif>
			<cfif len(arguments.mediaHeight) gt 0>
				<cfset MediaDbObj.setMediaHeight(arguments.mediaHeight)><!---imageInfo.height--->
			</cfif>
			<cfif len(arguments.mediaWidth) gt 0>
				<cfset MediaDbObj.setMediaWidth(arguments.mediaWidth)><!---imageInfo.width--->
			</cfif>
			<cfif len(arguments.mediaSize) gt 0>
				<cfset MediaDbObj.setMediaSize(arguments.mediaSize)><!---UploadFileObj.filesize--->
			</cfif>
			<!--- Video captions and image cover --->
			<cfif len(arguments.mediaVideoCoverUrl) gt 0>
				<cfset MediaDbObj.setMediaVideoCoverUrl(arguments.mediaVideoCoverUrl)>
			</cfif>
			<cfif len(arguments.mediaVideoVttFileUrl) gt 0>
				<cfset MediaDbObj.setMediaVideoVttFileUrl(arguments.mediaVideoVttFileUrl)>
			</cfif>
			<cfif len(arguments.providerVideoId) gt 0>
				<cfset MediaDbObj.setProviderVideoId(arguments.providerVideoId)>
			</cfif>
			<cfset MediaDbObj.setDate(application.blog.blogNow())>

			<!--- Save the postId and commentId into the junction tables if they were supplied. --->

			<!--- Save the postId into the junction table when updating a post. --->
			<cfif arguments.enclosure and arguments.postId neq ''>
				<!--- Load the post entity --->
				<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
				<!--- If this is an enclosure, populate the enclosure column with the mediaId --->
				<!--- Note: this is a psuedo name. The actual column is Post.EnclosureMediaRef --->
				<cfset PostDbObj.setEnclosureMedia(MediaDbObj)>
					
				<!--- Remove other enclosures --->
				<cfset PostDbObj.setEnclosureMap(javaCast("null",""))>
				<!---And set the enclosureCarousel to null--->
				<cfset PostDbObj.setEnclosureCarousel(javaCast("null",""))>
			</cfif>

			<!--- Save the post object if this is an enclosure --->
			<cfif arguments.enclosure and arguments.postId neq ''>
				<cfset EntitySave(PostDbObj)>
			</cfif>
			<!--- Save the media entity. --->
			<cfset EntitySave(MediaDbObj)>
			
		</cftransaction>

		<!--- And return the MediaId --->
		<cfreturn MediaDbObj.getMediaId()>
	
	</cffunction>
				
	<!---******************************************************************************************************** 
		Media Helpers
	*********************************************************************************************************--->
				
	<cffunction name="getMediaTypeByVideoProvider" access="public" returnType="string" output="false"
			hint="Determines the media type record for a video provider (i.e. Vimeo or YouTube)">
		<cfargument name="provider" type="string" required="true" hint="Either Vimeo or youTube.">
		<cfargument name="returnType" type="string" default="mediaTypeStrId" required="false" hint="mediaTypeStrId, mediaType">
			
		<!--- Translate the provider into the string we have in the MediaType table --->
		<cfswitch expression="#arguments.provider#">
			<cfcase value="youtube">
				<cfset mediaTypeStrId = "youTube">
				<cfset mediaTypeId = "Video - YouTube URL">
			</cfcase>
			<cfcase value="vimeo">
				<cfset mediaTypeStrId = "vimeo">
				<cfset mediaTypeId = "Video - Vimeo URL">
			</cfcase>
		</cfswitch>
				
		<!--- Return it --->
		<cfswitch expression="#returnType#">
			<cfcase value="mediaTypeStrId">
				<cfreturn mediaTypeStrId>
			</cfcase>
			<cfcase value="mediaType">
				<cfreturn mediaType>
			</cfcase>
		</cfswitch>
			
	</cffunction>
			
	<cffunction name="getYouTubeVideoId" returnType="string" 
			hint="Function to get the YouTube ID. This should work for most URL's. Gregory Alexander modified an approach suggested by Ray Camden">
		<cfargument name="youTubeUrl" default="" required="yes">

		<!---Check to see if this is a short YouTube URL (http://youtu.be/f89niPP64Hg) --->
		<cfif listGetAt(arguments.youTubeUrl, 2, '/') eq 'youtu.be'>
			<cfset youTubeId = listLast(arguments.youTubeUrl, '/')>
		<cfelse>
			<cfset youTubeId = reReplaceNoCase(arguments.youTubeUrl, ".*?v=([a-z0-9\-_]+).*","\1")>
		</cfif>

		<cfreturn youTubeId>

	</cffunction>
			
	<cffunction name="getVimeoVideoId" returnType="string" 
			hint="Function to get the Vimeo ID. This should work for most URL's. This gets all of the numeric values in a string">
		<cfargument name="vimeoUrl" default="" required="yes">

		<cfset arrUrl = rematch("[\d]+",arguments.vimeoUrl)>

		<cfreturn arrUrl[1]>

	</cffunction>
			
			
			
	<!---******************************************************************************************************** 
		Map functions
	*********************************************************************************************************--->
			
	<cffunction name="getMapProviderIdByProviderStr" access="public" returnType="string" output="false"
			hint="Determines the MapProviderId by a provider (i.e. Bing or Google)">
		<cfargument name="provider" type="string" required="true" hint="Either Vimeo or youTube.">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				MapProviderId 
				)
			FROM MapProvider as MapProvider 
			WHERE 0=0
				AND MapProvider.MapProvider = <cfqueryparam value="#arguments.provider#">
		</cfquery>
		
		<cfreturn Data[1]["MapProviderId"]>
			
	</cffunction>
			
	<cffunction name="getMapRoutesByMapId" access="public" returnType="array" output="false"
			hint="Get's the routes for a given map id">
		<cfargument name="mapId" type="string" required="true" hint="Pass in the map id.">
			
		<!--- Load the map entity. We need to do this as using a cfqueryparam does not work when using values for a primary or a foriegn key. --->
		<cfset MapDbObj = entityLoadByPK("Map", arguments.mapId)>

		<!--- Get the routes --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				MapRoute.Location as Location,
				MapRoute.GeoCoordinates as GeoCoordinates
			)
			FROM MapRoute as MapRoute
			WHERE 
				MapRoute.MapRef = #MapDbObj.getMapId()#
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="getMapByMapId" access="public" returnType="array" output="false"
			hint="Get's the map for a given map id">
		<cfargument name="mapId" type="string" required="true" hint="Pass in the map id.">
			
		<!--- Load the map entity. We need to do this as using a cfqueryparam does not work when using values for a primary or a foriegn key. --->
		<cfset MapDbObj = entityLoadByPK("Map", arguments.mapId)>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Map.MapId as MapId,
				MapTypeRef.MapType as MapType,
				PostRef.PostId as PostId,
				Map.HasMapRoutes as HasMapRoutes,
				Map.MapName as MapName,
				Map.MapTitle as MapTitle,
				Map.Location as Location,
				Map.GeoCoordinates as GeoCoordinates,
				Map.Zoom as Zoom,
				Map.OutlineMap as OutlineMap,
				Map.CustomMarkerUrl as CustomMarkerUrl
			)
			FROM Map as Map
			WHERE 0=0
				AND Map.MapId = #MapDbObj.getMapId()#
		</cfquery>
			
		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="saveMap" access="public" returnType="string" output="true"
			hint="Saves a map into the database">
		
		<cfargument name="isEnclosure" type="string" required="false" default="" hint="We need to know if this map will be used for an enclosure or in the post body.">
		<cfargument name="provider" type="string" required="false" default="Bing Maps" hint="Pass in the provider (Bing Maps is currently the only choice).">
		<cfargument name="postId" type="string" required="true" default="" hint="Pass in the postId">
		<cfargument name="mapId" type="string" required="false" default="" hint="Pass in the mapId if present">
		<cfargument name="mapName" type="string" required="false" default="" hint="Not used in this version">
		<cfargument name="mapType" type="string" required="true" default="" hint="Pass in the mapType">
		<cfargument name="mapZoom" type="string" required="false" default="" hint="Pass in zoom level. It is a number between 1 and 19">
		<cfargument name="mapAddress" type="string" required="true" default="" hint="Pass in the location or address">
		<cfargument name="mapCoordinates" type="string" required="true" default="" hint="Pass in latitude and longitude separated by a comma">
		<cfargument name="outlineMap" type="boolean" required="false" default="false" hint="This is a boolean value">
		<cfargument name="customMarker" type="string" required="false" default="" hint="Pass in the URL of your custom marker, if any">
		
		<cftransaction>
			<!--- Get the provider. Right now there is only one (bing) --->
			<cfset ProviderDbObj = entityLoad("MapProvider", { MapProvider = arguments.provider }, "true" )>
			<!--- And the map type. Our default is aerial --->
			<cfset MapTypeDbObj = entityLoad("MapType", { MapType = arguments.mapType }, "true" )>
		
			<cfif arguments.mapId neq ''>
				<!--- Load the Map entity --->
				<cfset MapDbObj = entityLoadByPK("Map", arguments.mapId)>
			<cfelse>
				<!--- Create a new Map entity --->
				<cfset MapDbObj = entityNew("Map")>
			</cfif>
			<!--- Set the values --->
			<cfset MapDbObj.setMapProviderRef(ProviderDbObj)>
			<cfset MapDbObj.setMapTypeRef(MapTypeDbObj)>
			<cfset MapDbObj.setMapName(arguments.mapName)>
			<cfset MapDbObj.setZoom(arguments.mapZoom)>
			<cfset MapDbObj.setLocation(arguments.mapAddress)>
			<cfset MapDbObj.setGeoCoordinates(arguments.mapCoordinates)>
			<cfset MapDbObj.setCustomMarkerUrl(arguments.customMarker)>
			<cfset MapDbObj.setOutlineMap(arguments.outlineMap)>
			<!--- Note: for routes, we don't  need the geocoordinates on the map --->
			<cfset MapDbObj.setDate(application.blog.blogNow())>

			<!--- Finally, save the MapId into the post table. --->
			<cfif arguments.postId neq ''>
				<!--- Load the post entity --->
				<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
				<!--- Save the PostRef --->
				<cfset MapDbObj.setPostRef(PostDbObj)>
				<!--- If this is an enclosure, remove the media enclosure and set the new map encosure with the map id --->
				<cfif arguments.isEnclosure>
					<!--- Set the enclosureMap. The actual column is Post.EnclosureMapRef. --->
					<cfset PostDbObj.setEnclosureMap(MapDbObj)>

					<!--- Remove other enclosures --->
					<cfset PostDbObj.setEnclosureMedia(javaCast("null",""))>
					<cfset PostDbObj.setEnclosureCarousel(javaCast("null",""))>
						
					<!--- Save it --->
					<cfset EntitySave(PostDbObj)>
				</cfif>
			</cfif>
			<!--- Save the map. --->
			<cfset EntitySave(MapDbObj)>
		</cftransaction>
		
		<!--- Return the mapId --->
		<cfreturn MapDbObj.getMapId()>
			
	</cffunction>
			
	<cffunction name="saveMapRoute" access="public" returnType="string" output="true"
			hint="Saves a map into the database">
		<cfargument name="mapId" type="string" required="false" default="" hint="Pass in the mapId if present">
		<cfargument name="mapRouteId" type="string" required="false" default="" hint="Pass in the mapRouteId if present">
		<cfargument name="postId" type="string" required="true" default="" hint="Pass in the postId">
		<cfargument name="isEnclosure" type="boolean" required="true" default="true" hint="We need to determine if this is an enclosure in order to create the proper relationships in the database.">
		<cfargument name="mapName" type="string" required="false" default="" hint="Pass in the map name">
		<cfargument name="mapTitle" type="string" required="false" default="" hint="Pass in the map title">
		<cfargument name="provider" type="string" required="false" default="Bing Maps" hint="Pass in the provider (Bing Maps is currently the only choice).">
		<cfargument name="location" type="string" required="false" default="" hint="Pass in the location">
		<cfargument name="locationGeoCoordinates" type="string" required="false" default="" hint="Pass in the address, and latitude and longitude separated by a comma. The locationGeoCoordinates should be a CF list object. The data should be formatted like so: address_geoCoordinates_address1_geoCoordinates1_address2_geoCoordinates2_ etc">
		
		<cftransaction>
			<!--- Get the provider. Right now there is only one (bing) --->
			<cfset ProviderDbObj = entityLoad("MapProvider", { MapProvider = arguments.provider }, "true" )>
			<!--- And the map type. Our default is aerial --->
			<cfset MapTypeDbObj = entityLoad("MapType", { MapType = "aerial" }, "true" )>
		
			<cfif arguments.mapId neq ''>
				<!--- Load the Map entity --->
				<cfset MapDbObj = entityLoadByPK("Map", arguments.mapId)>
				<!--- Load the MapRoute entity --->
				<cfset MapRouteDbObj = entityLoad("MapRoute", { MapRef = MapDbObj }, "false" )>
				<!--- And delete the map route records. According to my limited testing, is probably the most efficient way to delete bulk records. --->	
				<cfquery name="deleteMapRoutes" dbtype="hql">
					DELETE MapRoute
					WHERE MapRef = #MapDbObj.getMapId()#
				</cfquery>
			<cfelse>
				<!--- Create a new Map entity --->
				<cfset MapDbObj = entityNew("Map")>
			</cfif>
			<!--- Set the values --->
			<cfset MapDbObj.setMapProviderRef(ProviderDbObj)>
			<cfset MapDbObj.setMapTypeRef(MapTypeDbObj)>
			<cfset MapDbObj.setHasMapRoutes(true)>
			<cfset MapDbObj.setMapName(arguments.mapName)>
			<cfset MapDbObj.setLocation(arguments.location)>
			<!--- Note: for routes, we don't  need the geocoordinates on the map --->
			<cfset MapDbObj.setDate(application.blog.blogNow())>

			<!--- Save the the routes into the database --->
			<!--- Loop through our custom location geo coordinate object that was sent --->
			<cfloop from="1" to="#listLen(arguments.locationGeoCoordinates, '*')#" index="i">
				<!--- Extract the data from the list. --->
				<cfset geoLocObject = listGetAt(arguments.locationGeoCoordinates, i, '*')>
				<cfset routeLocation = listGetAt(geoLocObject, 1, '_')>
				<cfset routeLatitude = listGetAt(geoLocObject, 2, '_')>
				<cfset routeLongitude = listGetAt(geoLocObject, 3, '_')>
				<!---<cfoutput>#routeLocation#<br/></cfoutput>--->
				<!--- If this is an enclosure, delete any previous map routes --->

				<cftransaction>
					<cfset MapRouteDbObj = entityNew("MapRoute")>
					<!---Debugging: 
					i:#i# locObject: #locObject# location: #location# latitude: #latitude# longitude: #longitude#<br/>
					--->
					<!--- Set the values --->
					<cfset MapRouteDbObj.setMapRef(MapDbObj)>
					<!--- Loop through the location geocoordinate list that was sent in. --->
					<cfset MapRouteDbObj.setLocation(routeLocation)>
					<cfset MapRouteDbObj.setGeoCoordinates(routeLatitude & ',' & routeLongitude)>
					<!--- Note: for routes, we don't  need the geocoordinates on the map --->
					<cfset MapRouteDbObj.setDate(application.blog.blogNow())>
					<!--- Save it --->
					<cfset EntitySave(MapRouteDbObj)>
				</cftransaction>
			</cfloop>

			<!--- Finally, save the MapId into the post table. --->
			<cfif arguments.postId neq ''>
				<!--- Load the post entity --->
				<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
					
				<!--- Save the PostRef --->
				<cfset MapDbObj.setPostRef(PostDbObj)>
				<!--- If this is an enclosure, remove the media enclosure and set the new map encosure with the map id --->
				<cfif arguments.isEnclosure>
					<!--- Set the enclosureMap. The actual column is Post.EnclosureMapRef --->
					<cfset PostDbObj.setEnclosureMap(MapDbObj)>
					
					<!--- Remove other enclosures --->
					<cfset PostDbObj.setEnclosureMedia(javaCast("null",""))>
					<cfset PostDbObj.setEnclosureCarousel(javaCast("null",""))>
				</cfif>
				<cfset EntitySave(PostDbObj)>
			</cfif>
			<!--- Save the map. --->
			<cfset EntitySave(MapDbObj)>
		</cftransaction>
		
		<!--- Return the mapId --->
		<cfreturn MapDbObj.getMapId()>
			
	</cffunction>
						
	<!---****************************************************************************************************
		Carousel functions
	******************************************************************************************************--->
				
	<cffunction name="getCarousel" access="public" returnType="any" output="true"
			hint="Returns the carousel data for a given post">
		<cfargument name="carouselId" required="true">
				
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Carousel.CarouselId as CarouselId, 
				Carousel.CarouselName as CarouselName, 
				Carousel.CarouselTitle as CarouselTitle, 
				Carousel.CarouselEffect as CarouselEffect, 
				Carousel.CarouselShader as CarouselShader,
				CarouselItem.CarouselItemId as CarouselItemId,
				CarouselItem.CarouselItemTitle as CarouselItemTitle, 
				CarouselItem.CarouselItemTitleFontColor as CarouselItemTitleFontColor, 
				CarouselItem.CarouselItemTitleFontSize as CarouselItemTitleFontSize, 
				CarouselItem.CarouselItemBody as CarouselItemBody, 
				CarouselItem.CarouselItemBodyFontColor as CarouselItemBodyFontColor, 
				CarouselItem.CarouselItemBodyFontSize as CarouselItemBodyFontSize, 
				CarouselItem.CarouselItemUrl as CarouselItemUrl,
				CarouselItem.MediaRef.MediaUrl as MediaUrl,
				CarouselItem.MediaRef.MediaThumbnailUrl as MediaThumbnailUrl,
				Font.FontId as FontId,
				Font.Font as Font
			)
			FROM 
				Carousel as Carousel
				JOIN Carousel.CarouselItems as CarouselItem
				JOIN CarouselItem.CarouselItemTitleFontRef as Font
			WHERE Carousel.CarouselId = <cfqueryparam value="#arguments.carouselId#" cfsqltype="cf_sql_integer">
		</cfquery>
		
		<!--- Return the array. --->
		<cfreturn Data>
    
	</cffunction>
								
	<!---******************************************************************************************************** 
		Related posts
	*********************************************************************************************************--->
						
	<cffunction name="saveRelatedPost" access="public" returnType="string" output="true"
			hint="Checks to see if both the post and related post exists, and if they don't , inserts a new relatedPost record. Use this if you have a one to one relationship between a post and a related post.">
		<cfargument name="postId" type="numeric" required="true" />
		<cfargument name="relatedPostId" type="string" required="true" hint="This can be either one or more related post id's"/>
		
		<!--- I put in a debugging carriage as the logic was getting obnoxious. Set output to true when debugging. --->
		<cfset debug = 0>
		
		<!--- Determine if the record exists --->
		<cfquery name="getRelatedPost" dbtype="hql">
			SELECT new Map (
				Post.PostId as PostId,
				RelatedPost.PostId as RelatedPostId
			)
			FROM Post as Post
			JOIN Post.RelatedPosts as RelatedPost
			WHERE Post.PostId = <cfqueryparam value="#arguments.postId#" cfsqltype="cf_sql_integer" maxlength="35" />
			AND RelatedPost.PostId = <cfqueryparam value="#arguments.relatedPostId#" cfsqltype="cf_sql_integer" maxlength="35" />
		</cfquery>
		<cfif debug>
			getRelatedPost: <cfdump var="#getRelatedPost#"><br/>
		</cfif>
		
		<cfif arrayLen(getRelatedPost)>
			<!--- Return the relatedPostId --->
			<cfset relatedPostId = getRelatedPost[1]["RelatedPostId"]>
		<cfelse>
			<cftransaction>
				<!--- Create a new related post entity. --->
				<cfset RelatedPostObj = entityNew("RelatedPost")>
				<!--- We need to use primitive datatypes to set the arguments since this is a link table with no relationships --->
				<cfset RelatedPostObj.setPostRef(arguments.postId)>
				<cfset RelatedPostObj.setRelatedPostRef(arguments.relatedPostId)>
				<cfset RelatedPostObj.setDate(blogNow())>
				<!--- Save it. --->
				<cfset entitySave(RelatedPostObj)>
				<cfset relatedPostId = RelatedPostObj.getRelatedPostId()>
			</cftransaction>
		</cfif>
		
		<cfreturn relatedPostId>
	
	</cffunction>

	<cffunction name="saveRelatedPosts" access="public" returnType="string" output="true"
			hint="Checks to see if there are any related posts to delete from the database, and then inserts new related posts if necessary. Send in the postId and one or more related post Id's. Note: this was designed to keep the current relatedPostId and to have one post and one or more relalated posts. It does not work if you have multiple posts sent in that are the same.">
		<cfargument name="postId" type="numeric" required="true" />
		<cfargument name="relatedPosts" type="string" required="true" hint="This can be either one or more related post id's"/>
		
		<!--- I put in a debugging carriage as the logic was getting obnoxious. Set output to true when debugging. --->
		<cfset debug = 0>
		<!--- Create a list of current posts found in the database. --->
		<cfparam name="currentRelatedPosts" type="string" default="">
		<!--- Create a var to hold the records that need to be deleted. --->
		<cfparam name="deleteRelatedPostList" type="string" default=""> 
		
		<!--- Load the Post entity for the given postId. We will need this later to perform inserts --->
		<cfset PostDbObj = entityLoadByPk("Post", arguments.postId)>
		<cfif debug>
			PostId: #arguments.postId# title: #PostDbObj.getTitle()#<br/>
		</cfif>
		
		<!--- **********************************************************************************************
		Are there related posts to delete?
		*************************************************************************************************--->
		
		<!--- Loop through the related posts and see if the current data matches what is in the list before we delete anything. The original logic deleted everything and reinserted what was in the arguments. I don't  want to do this as I would like to keep the key sequence somewhat relevant. --->
		
		<!--- Determine if this post Id exists in the related posts. This query will not return the postId if there is *not* a related post. --->
		<cfquery name="getRelatedPostId" dbtype="hql">
			SELECT new Map (
				RelatedPost.PostId as RelatedPostId
			)
			FROM Post as Post
			JOIN Post.RelatedPosts as RelatedPost
			WHERE Post.PostId = <cfqueryparam value="#arguments.postId#" cfsqltype="cf_sql_integer" maxlength="35" />
		</cfquery>
		<cfif debug>
			Current Related Posts Obj: <cfdump var="#getRelatedPostId#"><br/>
		</cfif>
		
		<!--- Create some lists to determine if we need to delete records from the db. --->
		<cfif arrayLen(getRelatedPostId)>
			
			<!--- Loop through the database records --->
			<cfloop from="1" to="#arrayLen(getRelatedPostId)#" index="i">
				<!--- Create a list of the current posts. --->
				<cfset currentRelatedPosts = listAppend(currentRelatedPosts, getRelatedPostId[i]["RelatedPostId"])>
			</cfloop>
			<cfif debug>
				Current Related Posts List: #currentRelatedPosts#<br/>
			</cfif>
				
			<!--- **********************************************************************************************
			Should we delete some of the current related posts?
			*************************************************************************************************--->
			<cfloop list="#currentRelatedPosts#" item="currentRelatedPost"> 
				<cfif debug>
					<cfoutput>
						currentRelatedPost: #currentRelatedPost#<br/>
						listFind(arguments.relatedPosts,currentRelatedPost): #listFind(arguments.relatedPosts,currentRelatedPost)#<br/>
					</cfoutput>
				</cfif>
				<!--- See if the related post is in the supplied arguments. If it was not found, delete it. --->
				<cfif listFind(arguments.relatedPosts,currentRelatedPost) eq 0>
					<!--- Create a list of related posts to delete. --->
					<cfset deleteRelatedPostList = listAppend(deleteRelatedPostList, currentRelatedPost)>
				</cfif>
			</cfloop>
			<cfif debug>
				Delete Related Post List: <cfdump var="#deleteRelatedPostList#"><br/>
			</cfif>
		</cfif><!---<cfif arrayLen(getRelatedPostId)>--->
			
		<cfif len(deleteRelatedPostList)>
			<!--- Delete any records that are not in the supplied related post list if they were found. --->
			<cfquery name="deleteRelatedPosts" dbtype="hql">
				DELETE FROM RelatedPost
				WHERE PostRef IN (#deleteRelatedPostList#)
			</cfquery>
		</cfif>
			
		<!--- **********************************************************************************************
		Are there new related posts to insert?
		*************************************************************************************************--->
		<cfif debug>	
			<cfoutput>relatedPosts: #arguments.relatedPosts# currentRelatedPosts: #currentRelatedPosts#</cfoutput><br/>
		</cfif>
		
		<!--- Now, we need to go the other way and see if new related posts should be inserted into the db. --->
		<cfloop list="#arguments.relatedPosts#" index="relatedPost">
			
			<!--- Note: the relatedPost can't be paramaritized using a cfqueryparam here so I am setting a cfparam instead. --->
			<cfparam name="relatedPost" type="integer" default="#relatedPost#">
				
			<cfif debug>
				listFind(currentRelatedPosts, relatedPost): <cfoutput>#listFind(currentRelatedPosts, relatedPost)#</cfoutput><br/>
			</cfif>
				
			<!--- If it does not exist, insert the new related post. --->
			<cfif listFind(currentRelatedPosts, relatedPost) eq 0>
				<cfif debug>
					relatedPostNotFound for <cfoutput>#relatedPost#</cfoutput><br/>
				</cfif>
				<cftransaction>
					<!--- Get the Post object for the *related post*. Note: this is a manually built link table with no defined relationships (ie. one-to-one, many-to-many etc) as it is assumed that the relationship will automatically be a many-to-many. Since there is no defined relationships, we can't use objects here to populate the columns. Instead, we need to use primitive datatypes, in this case, and integer. --->

					<!--- Create a new related post entity. --->
					<cfset RelatedPostObj = entityNew("RelatedPost")>
					<!--- We need to use primitive datatypes to set the arguments since this is a link table with no relationships --->
					<cfset RelatedPostObj.setPostRef(arguments.postId)>
					<cfset RelatedPostObj.setRelatedPostRef(relatedPost)>
					<cfset RelatedPostObj.setDate(blogNow())>
					<!--- Save it. --->
					<cfset entitySave(RelatedPostObj)>
				</cftransaction>
			</cfif><!---<cfif listFind(currentRelatedPosts, relatedPost) eq 0>--->
					
		</cfloop><!---<cfloop list="#arguments.relatedPosts#" index="relatedPost">--->

	</cffunction>
						
	<!---******************************************************************************************************** 
		JSON LD
	*********************************************************************************************************--->
	
	<cffunction name="cleanJsonLd" access="public" returnType="string" output="false" 
			hint="Cleans a JSON LD string by removing the HTML that we use to prettify the string.">
		<cfargument name="jsonLd" type="string" required="true" default="">
			
		<!--- We need to clean up the html and other special characters from the json ---> 
		<!--- Remove non breaking spaces --->
		<cfset jsonLd = replaceNoCase(jsonLd, '&nbsp;', '', "all")>
		<!--- Remove page breaks --->
		<cfset jsonLd = replaceNoCase(jsonLd, '<br/>', '', "all")>
		<cfset jsonLd = replaceNoCase(jsonLd, '<br>', '', "all")>
		<!--- And replace the HTML colons that we use when prettifying the string. --->
		<cfset jsonLd = replaceNoCase(arguments.jsonLd, '&##58;', ':', 'all')>
			
		<cfreturn jsonLd>
			
	</cffunction>
						
	<cffunction name="saveJsonLd" access="public" returnType="boolean" output="false" hint="Saves a JSON LD in the Post.JsonLd column.">
		<cfargument name="postId" type="string" required="true" default="">
		<cfargument name="jsonLd" type="string" required="true" default="">
			
		<cftransaction>
			<!--- Load the post entity --->
			<cfset PostDbObj = entityLoadByPk("Post", arguments.postId)>

			<!--- Create a new related post entity. --->
			<cfset PostDbObj.setJsonLd(jsonLd)>
			<cfset PostDbObj.setDate(blogNow())>
			<!--- Save it. --->
			<cfset entitySave(PostDbObj)>
		</cftransaction>
				
		<cfreturn true>
			
	</cffunction>
				
	<!---******************************************************************************************************** 
		Anonymous Users
	*********************************************************************************************************--->
						
	<!---******************************************************************************************************** 
		Users
	*********************************************************************************************************--->
			
	<cffunction name="getUser" access="public" returnType="array" output="false" hint="Returns a HQL query object for  users.">
		<cfargument name="userName" type="string" required="false" default="">
		<cfargument name="userId" type="string" required="false" default="">
		<cfargument name="userToken" type="string" required="false" default="">
		<cfargument name="firstName" type="string" required="false" default="">
		<cfargument name="lastName" type="string" required="false" default="">
		<cfargument name="email" type="string" required="false" default="">
		<cfargument name="active" type="boolean" required="false" default="true">
		<cfargument name="includeSecurityCredentials" type="boolean" required="false" default="true">
			
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				User.UserName as UserName,
				User.UserToken as UserToken,
				User.FirstName as FirstName,
				User.LastName as LastName,
				User.FullName as FullName,
				User.DisplayName as DisplayName,
				User.Email as Email,
				User.Website as Website
			<cfif arguments.includeSecurityCredentials>
				,User.Password as Password,
				User.SecurityAnswer1 as SecurityAnswer1,
				User.SecurityAnswer2 as SecurityAnswer2,
				User.SecurityAnswer3 as SecurityAnswer3
			</cfif>
			)
			FROM 
				Users as User
			WHERE 0=0
			<cfif arguments.userId neq ''>
				AND UserId = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
			</cfif>
			<cfif arguments.userToken neq ''>
				AND UserToken = <cfqueryparam value="#arguments.userToken#" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif arguments.userName neq ''>
				AND UserName = <cfqueryparam value="#arguments.userName#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			<cfif arguments.firstName neq ''>
				AND FirstName = <cfqueryparam value="#arguments.firstName#" cfsqltype="cf_sql_varchar" maxlength="50">
			</cfif>
			<cfif arguments.lastName neq ''>
				AND LastName = <cfqueryparam value="#arguments.lastName#" cfsqltype="cf_sql_varchar" maxlength="50">
			</cfif>
			<cfif arguments.email neq ''>
				AND Email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="50">
			</cfif>
			<cfif arguments.active>
				AND Active = <cfqueryparam value="#arguments.active#" cfsqltype="cf_sql_bit">
			</cfif>
				AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<cfreturn Data>
		
	</cffunction>
				
	<cffunction name="getUsers" access="public" returnType="array" output="false" 
			hint="Returns users for a blog.">
		<cfargument name="firstName" type="string" required="false" default="">
		<cfargument name="lastName" type="string" required="false" default="">
		<cfargument name="email" type="string" required="false" default="">
		
		
		<cfset var Data = "[]">

		<!--- Note: ambiguous columns will not show up in the error message. Instead, you will see an 'org.hibernate.hql.internal.ast.QuerySyntaxException: unexpected token:' error. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				User.UserId as UserId,
				User.UserToken as UserToken,
				User.UserName as UserName,
				User.FirstName as FirstName,
				User.LastName as LastName,
				User.FullName as FullName,
				User.DisplayName as DisplayName,
				User.Email as Email,
				User.Website as Website
			)
			FROM 
				Users as User
			WHERE 0=0
			<cfif arguments.firstName neq ''>
				AND FirstName LIKE <cfqueryparam value="%#arguments.firstName#%" cfsqltype="cf_sql_varchar" maxlength="50">
			</cfif>
			<cfif arguments.lastName neq ''>
				AND LastName LIKE <cfqueryparam value="%#arguments.lastName#%" cfsqltype="cf_sql_varchar" maxlength="50">
			</cfif>
			<cfif arguments.email neq ''>
				AND Email LIKE <cfqueryparam value="%#arguments.email#%" cfsqltype="cf_sql_varchar" maxlength="50">
			</cfif>
				AND Active = <cfqueryparam value="1">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<cfreturn Data>
	</cffunction>
			
	<cffunction name="getUserAsStruct" access="public" returnType="struct" output="false" 
			hint="Returns a user struct for a blog.">
		<cfargument name="userName" type="string" required="true">
		<cfset var Data = "[]">
		<cfset var userStruct = structNew()>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				UserName as UserName,
				Password as Password,
				FullName as FullName
			)
			FROM Users
			WHERE 
				UserName = <cfqueryparam value="#arguments.username#" cfsqltype="cf_sql_varchar" maxlength="35">
				AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<!--- Create our struct--->
		<cfif arrayLen(Data)>
			<cfset userStruct.UserName = Data[1]["UserName"]>
			<cfset userStruct.Password = Data[1]["Password"]>
			<cfset userStruct.FullName = Data[1]["FullName"]>
		<cfelse>
			<cfthrow message="Unknown user #arguments.username# for blog.">
		</cfif>

		<cfreturn userStruct>
		
	</cffunction>
		
	<cffunction name="getUserIdByUserName" access="public" returnType="numeric" output="false"
			hint="Get userId by the username. Will return a 0 if nothing was found.">
		<cfargument name="userName" type="string" required="true">
			
		<!--- Get the user Id. We have multiple user entities to load and it is more efficient to load them by the Id --->
		<cfquery name="Data" dbtype="hql" ormoptions="#{maxresults=1}#">		
			SELECT new Map (
				UserId as UserId)
			FROM Users as Users 
			WHERE UserName = <cfqueryparam value="#arguments.userName#">
			AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset userId = Data[1]["UserId"]>
		<cfelse>
			<cfset userId = 0>
		</cfif>
		
		<!--- Return it --->
		<cfreturn userId>

	</cffunction>

	<cffunction name="getUserByName" access="public" returnType="string" output="false"
			hint="Get username based on encoded name.">
		<cfargument name="name" type="string" required="true">
			
		<cfset var Data = "[]">
		<cfset var userName = ''>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				UserName as UserName
			)
			FROM Users
			WHERE 
				FullName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#replace(arguments.name,"_"," ","all")#" maxlength="50">
				AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<cfif arrayLen(Data)>
			<cfset userName = Data[1]["UserName"]>
		</cfif>
		
		<cfreturn userName>

	</cffunction>
			
	<cffunction name="getNameForUser" access="public" returnType="string" output="false"
			hint="Returns the full name of a user.">
		<cfargument name="username" type="string" required="true" />
		<cfset var Data = "[]" />

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				User.FullName as FullName
			)
			FROM Users as User 
			WHERE User.UserName = <cfqueryparam cfsqltype="cf_sql_varchar" value="admin">
			AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
		</cfquery>

		<cfreturn Data[1]["FullName"]>
	</cffunction>
			
	<cffunction name="getCurrentUserNameList" access="public" returnType="string" output="false" 
			hint="Gets all user names for validation to ensure that the assigned roles are unique.">
			
		<!--- Get all user names for validation. We will use client side logic (and server side) to ensure that the assigned roles are unique. --->
		<cfset currentUserNames = getUsers()>
		<cfparam name="currentUserNameList" default="">

		<cfif arrayLen(currentUserNames)>
			<!--- Loop through the array and get the user names --->
			<cfloop from="1" to="#arrayLen(currentUserNames)#" index="i">
				<cfif i lt arrayLen(currentUserNames)>
					<cfset currentUserNameList = currentUserNameList & currentUserNames[i]["UserName"] & ",">
				<cfelse>
					<cfset currentUserNameList = currentUserNameList & currentUserNames[i]["UserName"]>
				</cfif>
			</cfloop>
		</cfif><!---<cfif arrayLen(currentUserNames)>--->
		
		<!--- Return it --->
		<cfreturn currentUserNameList>
			
	</cffunction>
					
	<cffunction name="getUserLoginHistory" access="public" returnType="array" output="false"
			hint="Returns the users login history with IP addresses and the user agent.">
		<cfargument name="userName" type="string" required="true" />
		<cfargument name="ipAddress" required="no" default="">
		<cfargument name="userAgent" required="no" default="">
		<cfargument name="loginDate" required="no" default="">
		
		<cfset var Data = "[]" />

		<cfset UserDbObj = entityLoad("Users", { UserName = arguments.userName }, "true" )>
		
		<!--- Note: we need to specify the IpAddress table using an alias (IpAddress.IpAddress) to ensure that we will not get the IP address object stored in the Users table if I load the Users entity. --->
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				AdminLogId as AdminLogId,
				UserRef.UserId as UserId,
				UserRef.FullName as FullName,
				IpAddressRef.IpAddressId as IpAddressId,
				IpAddressRef.IpAddress as IpAddress,
				HttpUserAgentRef.HttpUserAgentId as HttpUserAgentIdId,
				HttpUserAgentRef.HttpUserAgent as HttpUserAgent,
				AdminLog.Date as Date
			)
			FROM   AdminLog as AdminLog
			WHERE 0=0
				AND UserRef.UserId = #UserDbObj.getUserId()#
			<cfif arguments.ipAddress neq ''>
				AND IpAddressRef.IpAddress = <cfqueryparam value="#arguments.ipAddress#" cfsqltype="varchar">
			</cfif>
			<cfif arguments.userAgent neq ''>
				AND HttpUserAgentRef.HttpUserAgent = <cfqueryparam value="#arguments.userAgent#" cfsqltype="varchar">
			</cfif>
			<cfif arguments.loginDate neq ''>
				AND AdminLog.Date = <cfqueryparam value="#arguments.loginDate#" cfsqltype="timestamp">
			</cfif>
			ORDER BY AdminLog.Date DESC
		</cfquery>

		<cfreturn Data>
			
	</cffunction>
			
	<cffunction name="addUser" access="public" returnType="void" output="false" hint="Adds a user.">
		<cfargument name="username" type="string" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="password" type="string" required="true">
		
		<cfset var q = "">
		<cfset var salt = generateSalt()>
		<cfset var uuid = createUUID()>

		<cflock name="blogcfc.adduser" type="exclusive" timeout="60">
			
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					UserName as UserName
				)
				FROM Users
				WHERE 
					UserName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
					AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
					AND BlogRef = #application.BlogDbObj.getBlogId()#
			</cfquery>

			<cfif arrayLen(Data) gt 0>
				<cfset variables.utils.throw("#arguments.name# already exists as a user.")>
			<cfelse><!---<cfif arrayLen(Data) gt 0>--->
				<!--- Wrap the ORM code with a transaction. --->
				<cftransaction>
					<!--- Create a new entity. --->
					<cfset UserDbObj = entityNew("Users")>
					<!--- Use the entity objects to set the data. --->
					<cfset UserDbObj.setBlogRef(blogRef)>
					<cfset UserDbObj.setUserToken(uuid)>
					<cfset UserDbObj.setFirstName("")>
					<cfset UserDbObj.setLastName("")>
					<cfset UserDbObj.setFullName(arguments.name)>	
					<cfset UserDbObj.setEmail(blogEmail)>
					<cfset UserDbObj.setUserName(arguments.username)>
					<cfset UserDbObj.setPassword(#hash(salt & arguments.password, instance.hashalgorithm)#)>
					<cfset UserDbObj.setSalt(salt)>

					<cfset UserDbObj.setActive(true)>
					<cfset UserDbObj.setDate(blogNow())>
					<!--- Save it --->
					<cfset EntitySave(UserDbObj)>
				</cftransaction>
			</cfif><!---<cfif arrayLen(Data) gt 0>--->

		</cflock>

	</cffunction>

	<cffunction name="saveUser" access="public" returnType="void" output="true"
			hint="Saves a user.">
		<cfargument name="action" type="string" required="true">
		<cfargument name="currentUser" type="string" required="true">	
		<cfargument name="firstName" type="string" required="true">
		<cfargument name="lastName" type="string" required="true">
		<cfargument name="displayName" type="string" required="true">
		<cfargument name="email" type="string" required="true">
		<cfargument name="webSite" type="string" default="" required="false">
		<cfargument name="userName" type="string" required="true">
		<cfargument name="password" type="string" default="" required="false">
		<cfargument name="confirmedPasword" type="string" default="" required="false">
		<cfargument name="securityAnswer1" type="string" default="" required="false">
		<cfargument name="securityAnswer2" type="string" default="" required="false">
		<cfargument name="securityAnswer3" type="string" default="" required="false">
		<cfargument name="notify" type="string" default="false" required="false">
		<cfargument name="roleId" type="string"  default="" required="false">
		<cfargument name="newRole" type="string" default="" required="false">
		<cfargument name="newRoleDesc" type="string"  default="" required="false">
		<cfargument name="capabilities" type="string" default="" required="false">
		
		<cfset var salt = generateSalt()>
		<cfset var uuid = createUUID()>
			
		<!--- Use a transaction --->
		<cftransaction>
			<!--- ******************** Save the user ******************** --->
			<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
			<cfset BlogDbObj = entityLoadByPK("Blog", application.BlogDbObj.getBlogId())>
				
			<cfquery name="getUserId" dbtype="hql">
				SELECT UserId 
				FROM Users 
				WHERE UserName = <cfqueryparam value="#arguments.userName#">
				AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
			</cfquery>
				
			<!--- Load the entity. --->
			<cfif arrayLen(getUserId)>
				<!--- Load the entity by the username --->
				<cfset UserDbObj = entityLoadByPk("Users", getUserId[1])>
			<cfelse>
				<!--- Create a new entity --->
				<cfset UserDbObj = entityNew("Users")>
			</cfif>
			<!--- Use the entity objects to set the data. --->
			<cfset UserDbObj.setBlogRef(BlogDbObj)>
			<!--- Create the UUID for new records. --->
			<cfif not arrayLen(getUserId)>
				<cfset UserDbObj.setUserToken(uuid)>
			</cfif>
			<cfset UserDbObj.setFirstName(arguments.firstName)>
			<cfset UserDbObj.setLastName(arguments.lastName)>
			<cfset UserDbObj.setDisplayName(arguments.displayName)>
			<cfset UserDbObj.setFullName("#arguments.firstName# #arguments.lastName#")>	
			<cfset UserDbObj.setEmail(arguments.email)>
			<cfset UserDbObj.setWebsite(arguments.website)>
			<cfset UserDbObj.setUserName(arguments.username)>
			<!--- The confirmedPassword will only be sent when the password is being changed. --->
			<cfif len(arguments.password)>
				<cfset UserDbObj.setPassword(#hash(salt & arguments.password, instance.hashalgorithm)#)>
				<cfset UserDbObj.setSalt(salt)>
			</cfif>
			<cfif len(arguments.securityAnswer1) and len(securityAnswer2) and len(securityAnswer3)>
				<cfset UserDbObj.setSecurityAnswer1(arguments.securityAnswer1)>
				<cfset UserDbObj.setSecurityAnswer2(arguments.securityAnswer2)>
				<cfset UserDbObj.setSecurityAnswer3(arguments.securityAnswer3)>
			</cfif>
			<!--- The notify argument will only be true when an admin is creating a new user account and has clicked the notify user checkbox. --->
			<cfif arguments.action eq 'insert' and arguments.notify>
				<cfset UserDbObj.setChangePasswordOnLogin(true)>
			</cfif>
			<!--- The new user is updating their profile. Change the change password on next login to false. --->
			<cfif action neq 'updateProfile'>
				<cfset UserDbObj.setChangePasswordOnLogin(false)>
			</cfif>
			<cfset UserDbObj.setLastLogin("")>
			<cfset UserDbObj.setActive(true)>
			<cfset UserDbObj.setDate(blogNow())>
				
			<!--- ******************** Save the role ******************** --->
				
			<!--- Instantiate the Role entity. its an existing role that needs to be editted if the newRole arg was not sent in and is an emtpy string --->
			<cfif arguments.newRole eq ''>
				<!--- Load the role object. --->
				<cfset RoleDbObj = entityLoadByPK("Role", arguments.roleId)>
				<!--- We don't  need to save anything. We just need to instantiate the role entity --->
			<cfelse>
				<!--- Set a role uuid --->
				<cfset roleUuid = createUUID()>

				<!--- Create a new Role entity and save the data --->
				<cfset RoleDbObj = entityNew("Role")>
				<!--- Save it --->
				<cfset RoleDbObj.setBlogRef(BlogDbObj)>
				<cfset RoleDbObj.setRoleUuid(roleUuid)>
				<cfset RoleDbObj.setRoleName(arguments.newRole)>
				<cfset RoleDbObj.setDescription(arguments.newRoleDesc)>
				<cfset RoleDbObj.setDate(blogNow())>
			</cfif>

			<!--- ******************** Save the user role ******************** --->

			<!--- Does the user role exist? --->
			<cfset getUserRole = getUserBlogRoles(arguments.roleId)>
			<cfif arrayLen(getUserRole)>
				<!--- Load the user role object with the users and role objects as filters. --->
				<cfset UserRoleDbObj = entityLoadByPK("UserRole", arguments.roleId)>
			<cfelse>
				<!--- Create a new entity --->
				<cfset UserRoleDbObj = entityNew("UserRole")>
			</cfif>
			<cfset UserRoleDbObj.setBlogRef(BlogDbObj)>
			<cfset UserRoleDbObj.setRoleRef(RoleDbObj)>
			<cfset UserRoleDbObj.setUserRef(UserDbObj)>
			<cfset UserRoleDbObj.setDate(blogNow())>

			<!--- ******************** Save capabilities ******************** --->

			<!--- The capabilities only need to be stored when a new role was made. The client side will create a prompt for a new role when the default capabilities for an existing role changed. --->
			<cfif arguments.newRole neq ''>
				<!--- Loop through the passed in capabilities and populate the db --->
				<cfloop list="#arguments.capabilities#" index="i">
					<!--- Create a new role capability entity --->
					<cfset RoleCapabilityDbObj = entityNew("RoleCapability")>
					<!--- Load the capability entity (the user can't create new capabilities) --->
					<cfset CapabilityDbObj = entityLoadByPK("Capability", i)>
					<!--- Populate it --->
					<cfset RoleCapabilityDbObj.setBlogRef(BlogDbObj)>
					<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
					<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj)>
					<cfset RoleCapabilityDbObj.setDate(blogNow())>
					<!--- Save the entity. Nothing else is dependent upon this entity object --->
					<cfset EntitySave(RoleCapabilityDbObj)>
				</cfloop><!---<cfloop list="#arguments.capabilities#" index="i">--->
			</cfif><!---<cfif not arrayLen(getRole)>--->

			<!--- Save the entities in reverse order that they were instantiated --->
			<cfset EntitySave(UserRoleDbObj)>
			<cfset EntitySave(RoleDbObj)>
			<cfset EntitySave(UserDbObj)>
				
		</cftransaction>
			
		<cfif arguments.notify>

			<!--- Get the logo image --->
			<!--- First we need to get the theme --->
			<cfset kendoTheme = this.getSelectedKendoTheme()>
			<!--- Get the logo path  --->
			<cfset logoPath = application.blog.getLogoPathByTheme(kendoTheme='default')>

			<!--- Email the new user --->
			<cfsavecontent variable="mainBody">
				<cfoutput>
				<h2>New user account setup</h2>
				<p>Hello #firstName# #lastName#,<br/>
				#arguments.currentUser# has set up a new #instance.blogTitle# account for you.</p>

				<p>Please click on the 'Setup Account' button below to complete your account setup.</p>
				</cfoutput>
			</cfsavecontent>
				
			<!--- Send email to the new user --->
			<!--- ************* Render email to new user asking them to setup their new account ************* --->
			<cfset email = arguments.email>
			<cfset emailTitle = instance.blogTitle & " user confirmation">
			<cfset emailTitleLink = application.blogHostUrl & '/admin/?ukey=#uuid#&pkey=#hash(salt & arguments.password, instance.hashalgorithm)#'>
			<cfset emailDesc = "Please setup your new user account">
			<cfset callToActionText = "Setup Acccount">
			<cfset callToActionLink = emailTitleLink>

			<!--- Render the email --->
			<cfinvoke component="#RendererObj#" method="renderEmail" returnvariable="emailBody">
				<cfinvokeargument name="email" value="#email#">
				<cfinvokeargument name="emailTitle" value="A new #variables.utils.htmlToPlainText(htmlEditFormat(instance.blogtitle))# user account has been set up for you.">
				<cfinvokeargument name="emailTitleLink" value="#emailTitleLink#">
				<cfinvokeargument name="emailDesc" value="#emailDesc#">
				<cfinvokeargument name="emailBody" value="#mainBody#">
				<cfinvokeargument name="callToActionText" value="#callToActionText#">
				<cfinvokeargument name="callToActionLink" value="#callToActionLink#">
			</cfinvoke>

			<!--- Email the new user asking them to confirm ---> 
			<cfset application.utils.mail(
				to=#email#,
				subject="A new #variables.utils.htmlToPlainText(htmlEditFormat(instance.blogtitle))# user account has been set up for you",
				body=emailBody)>

		</cfif><!---<cfif arguments.action eq 'insert' and arguments.notify>--->
				
	</cffunction>
				
	<cffunction name="deleteUser" access="public" returnType="void" output="false" 
			hint="Deletes a user.">
		<cfargument name="username" type="string" required="true">
			
		<!--- Delete the user. --->
		<cfquery dbtype="hql">
			DELETE FROM Users
			WHERE 
				UserName = <cfqueryparam value="#arguments.username#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<!--- Delete the PostDbObj variable to ensure that the record doesn't stick around and is deleted from ORM memory. --->
		<cfset void = structDelete( variables, "Data" )>

	</cffunction>
				
	<cffunction name="updatePassword" access="public" returnType="boolean" output="false"
			hint="Updates the current user's password.">
		<cfargument name="userName" type="string" required="false" default="" />
		<cfargument name="password" type="string" required="true" />
		
		<cfset var Data = "[]" />
		<cfset var salt = generateSalt()>
			
		<cfif arguments.userName eq ''>
			<cfset userName = getAuthUser()>
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				UserId as UserId,
				UserName as UserName,
				Password as Password,
				Salt as Salt
			)
			FROM Users
			WHERE 
				UserName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userName#" maxlength="50">
				AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<!--- Update the database. --->
		<cfif arrayLen(Data)>
			
			<!--- Wrap the ORM code with a transaction. --->
			<cftransaction>
				<!--- Load the user entity. --->
				<cfset UsersDbObj = entityLoadByPK("Users", Data[1]["UserId"])>
				<!--- Set the values. --->
				<cfset UsersDbObj.setPassword(#hash(salt & arguments.password, instance.hashalgorithm)#)>
				<cfset UsersDbObj.setSalt(salt)>
				<cfset UsersDbObj.setDate(blogNow())>
				<!--- Save it --->
				<cfset EntitySave(UsersDbObj)>
			</cftransaction>
					
			<cfreturn true />			
		<cfelse>
			<cfreturn false />
		</cfif>
					
	</cffunction>
					
	<cffunction name="generateSalt" returnType="string" output="false" access="public" hint="I generate salt for use in hashing user passwords">
		
		<cfreturn generateSecretKey(instance.saltAlgorithm, instance.saltKeySize)>
	</cffunction>
		
	<!---******************************************************************************************************** 
		Roles
	*********************************************************************************************************--->
		
	<cffunction name="getRoleByRoleName" access="public" returnType="array" output="false"
			hint="Gets role data by the role name">
		<cfargument name="roleName" type="string" required="true">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				RoleId as RoleId,
				RoleUuid as RoleUuid,
				RoleName as RoleName,
				Description as Description
			)
			FROM 
				Role as Role
			WHERE 0=0
				AND RoleName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.roleName#" maxlength="50">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<!--- Return the HQL array --->
		<cfreturn Data>
			
	</cffunction>
		
	<cffunction name="getBlogRoles" access="public" returnType="array" output="false">
		
		<cfset var Data = "[]">

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				RoleId as RoleId,
				RoleName as RoleName, 
				Description as Description
			)
			FROM Role
		</cfquery>

		<cfreturn Data>
	</cffunction>
				
	<cffunction name="getBlogRolesList" access="public" returnType="string" output="false">
		
		<!--- Get all blog roles for validation. We will use client side logic (and server side) to ensure that the assigned roles are unique. --->
		<cfset currentBlogRoles = getBlogRoles()>
		<cfparam name="currentBlogRolesList" default="">

		<cfif arrayLen(currentBlogRoles)>
			<!--- Loop through the array and get the user names --->
			<cfloop from="1" to="#arrayLen(currentBlogRoles)#" index="i">
				<cfif i lt arrayLen(currentBlogRoles)>
					<cfset currentBlogRolesList = currentBlogRolesList & currentBlogRoles[i]["RoleName"] & ",">
				<cfelse>
					<cfset currentBlogRolesList = currentBlogRolesList & currentBlogRoles[i]["RoleName"]>
				</cfif>
			</cfloop>
		</cfif><!---<cfif arrayLen(currentBlogRoles)>--->

		<cfreturn currentBlogRolesList>
	</cffunction>
				
	<cffunction name="getUserBlogRoles" access="public" returnType="any" output="false"
			hint="The return type is specified in the returnType argument. This can return a list of RoleId's (returnType=roleIdList), a list of Role Names (returnType=roleList), or by default a HQL query object.">
		<cfargument name="username" type="string" required="true">
		<cfargument name="returnType" type="string" required="false" default="" hint="Either an emtpyString (''), 'roleIdList', 'roleList', or HQL. This can return a list of the roles, or a HQL query array of structs object">
			
		<cfset var Data = "[]">
		<cfset var roleIdList = "">
		<cfset var roleList = "">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				UserRole.UserRoleId as UserRoleId,
				Role.RoleId as RoleId,
				Role.RoleName as RoleName
			)	
			FROM 
				Users as User
				JOIN User.UserRoles as UserRole
				JOIN UserRole.RoleRef as Role
			WHERE 0=0
				AND User.UserName = <cfqueryparam value="#arguments.username#">
				AND User.Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				AND User.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
			
		<cfif returnType eq 'roleIdList'>
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset roleIdList = roleIdList & Data[i]["RoleId"] & ",">
					<cfelse>
						<cfset roleIdList = roleIdList & Data[i]["RoleId"]>
					</cfif>
				</cfloop>
			<cfelse>
				<!--- Return the guest role --->
				<cfset roleIdList = 5>
			</cfif> 
			<!--- Return the list of the role id's --->
			<cfreturn roleIdList>
				
		<cfelseif returnType eq 'roleList'>
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<cfif i lt arrayLen(Data)>
						<cfset roleList = roleList & Data[i]["RoleName"] & ",">
					<cfelse>
						<cfset roleList = roleList & Data[i]["RoleName"]>
					</cfif>
				</cfloop>
			<cfelse>
				<!--- Return the guest role --->
				<cfset roleIdList = "Guest">
			</cfif> 
			<!--- Return the list of roles --->
			<cfreturn roleList>
				
		<cfelse>
			<!--- Return the HQL object --->
			<cfreturn Data>
		</cfif>

	</cffunction>

	<cffunction name="updateUserBlogRoles" access="public" returnType="void" output="true" 
			hint="Sets a user's blog roles">
		<cfargument name="username" type="string" required="true" />
		<cfargument name="roles" type="string" required="true" />
		
		<cfset var getRoles = "[]">
			
		<!--- Get the user Id. We have multiple user entities to load and it is more efficient to load them by the Id --->
		<cfset getUserId = getUserIdByUserName(arguments.username)>
			
		<!--- **********************************************************************************************
		Are there user roles to delete?
		*************************************************************************************************--->
		
		<!--- Loop through the roles and see if the current data matches what is in the list before we delete anything. The original logic deleted everything and reinserted what was in the arguments. I don't  want to do this as I would like to keep the key sequence somewhat relevant. --->
		<cfquery name="getUserRole" dbtype="hql">
			SELECT new Map (
				User.UserId as UserId,
				Role.RoleId as RoleId,
				Role.RoleName as RoleName
			)
			FROM 
				Users as User
				LEFT OUTER JOIN User.UserRoles as UserRole
				JOIN UserRole.RoleRef as Role
			WHERE 0=0
				AND Role.RoleName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.roles#" maxlength="50">
				AND User.UserName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
				AND User.Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				AND User.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>
		
		<!--- If user roles exist in the db, loop through the current db records. --->
		<cfif arrayLen(getUserRole)>
			
			<cfloop from="1" to="#arrayLen(getUserRole)#" index="i">
				<!--- See if the related post is in the supplied arguments. --->
				<cfif not arguments.roles contains getUserRole[i]["Role"]>
					<cftransaction>
						<!--- Delete this record as it is not contained in the list. --->
						<!--- Load the users object --->
						<cfset UsersDbObj = entityLoadByPK("Users", getUserId)>
						<!--- And the role object. --->
						<cfset RoleDbObj = entityLoadByPK("Role", getUserRole[i]["Role"])>
						<!--- Now load the user role object with the users and role objects as filters. --->
						<cfset UserRoleDbObj = entityLoad("UserRole", { UserRef = UsersDbObj, RoleRef = RoleDbObj }, "true" )>
						<!--- Delete the entity --->
						<cfset EntityDelete(UserRoleDbObj)>
					</cftransaction>
				</cfif>
			</cfloop>
		</cfif><!---<cfif arrayLen(getUserRole)>--->
			
		<!--- **********************************************************************************************
		Are there new roles to insert?
		*************************************************************************************************--->
		
		<!--- Now, we need to go the other way and see if new roles should be inserted into the db. --->
		<cfloop list="#arguments.roles#" index="userRole">
			
			<!--- Does the user role already exist in the database? --->
			<cfquery name="getUserRole" dbtype="hql">
				SELECT new Map (
					User.UserId as UserId,
					Role.RoleId as RoleId,
					Role.RoleName as Role
				)
				FROM 
					Users as User
					LEFT OUTER JOIN User.UserRoles as UserRole
					JOIN UserRole.RoleRef as Role
				WHERE 0=0
					AND Role.RoleName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#userRole#" maxlength="50">
					AND User.UserName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
					AND User.Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
					AND User.BlogRef = #application.BlogDbObj.getBlogId()#
			</cfquery>
			
			<!--- If it does not exist, insert it. --->
			<cfif not arrayLen(getUserRole)>
				<cftransaction>
					<!--- Add the new role. --->
					<!--- Load the entity by the userId --->
					<cfset UsersDbObj = entityLoadByPK("Users", getUserId)>
					<!--- And the role object. --->
					<cfset RoleDbObj = entityLoad("Role", { RoleName = userRole }, "true" )>
					<!--- Now load the user role object with the users and role objects as filters. --->
					<cfset UserRoleDbObj = entityLoad("UserRole", { UserRef = UsersDbObj, RoleRef = RoleDbObj }, "true" )>
					<!--- Save the entity --->
					<cfset EntitySave(UserRoleDbObj)>
				</cftransaction>
			</cfif><!---<cfif not arrayLen(getUserRole)>--->
					
		</cfloop><!---<cfloop list="#arguments.roles#" index="userRole">--->

	</cffunction>
					
	<!---******************************************************************************************************** 
		Capabilities
	*********************************************************************************************************--->
					
	<cffunction name="getCapabilitiesByRole" access="public" returnType="any" output="true"
			hint="The return type is specified in the returnType argument. This can return a list of CapabilityId's, a list of capabilities, or a HQL query object for a given role.">
		<cfargument name="roles" type="string" required="true" hint="Pass in the session roles variable. This can (and often is) a list.">
		<cfargument name="returnType" type="string" required="false" default="capabilityIdList" hint="Either capabilityIdList, capabilityList, or HQL. This can return a list of the capabilities, or a HQL query array of structs object">
			
		<!--- Preset the lists. --->
		<cfparam name="capabilityIdList" default="">
		<cfparam name="capabilityList" default="">
			
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT new Map (
				Role.RoleName as RoleName,
				Capability.CapabilityId as CapabilityId,
				Capability.CapabilityName as CapabilityName
			)
			FROM 
				Role as Role
				<!--- After establishing a pointer to the UserRole table, we need to get to the RoleCapability table which is another array. --->
				JOIN Role.RoleCapability as RoleCapability
				<!--- Finally, we need to traverse to the actual CapabilityRef column in the Capability table that holds an array of capability data. --->
				JOIN RoleCapability.CapabilityRef as Capability
			WHERE 0=0
				AND Role.RoleName IN (<cfqueryparam cfsqltype="varchar" value="#arguments.roles#" list="yes">)
				AND Role.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<cfif returnType eq 'capabilityIdList'>
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<!--- Make sure that there is unique data. There may be multiple items in this list. --->
					<cfif listFindNoCase(capabilityIdList, Data[i]["CapabilityId"]) eq 0>
						<cfif i lt arrayLen(Data)>
							<cfset capabilityIdList = capabilityIdList & Data[i]["CapabilityId"] & ",">
						<cfelse>
							<cfset capabilityIdList = capabilityIdList & Data[i]["CapabilityId"]>
						</cfif><!---<cfif i lt arrayLen(Data)>--->
					</cfif><!---<cfif listFindNoCase(capabilityIdList, Data[i]["CapabilityId"]) eq 0>--->
				</cfloop>
			</cfif><!---<cfif arrayLen(Data)>--->
			<!--- Return the list of capabilities --->
			<cfreturn capabilityIdList>
				
		<cfelseif returnType eq 'capabilityList'>
			<cfif arrayLen(Data)>
				<!--- Loop through the array and get the roles --->
				<cfloop from="1" to="#arrayLen(Data)#" index="i">
					<!--- Make sure that there is unique data. There may be multiple items in this list. --->
					<cfif listFindNoCase(capabilityList, Data[i]["CapabilityName"]) eq 0>
						<cfif i lt arrayLen(Data)>
							<cfset capabilityList = capabilityList & Data[i]["CapabilityName"] & ",">
						<cfelse>
							<cfset capabilityList = capabilityList & Data[i]["CapabilityName"]>
						</cfif>
					</cfif><!---<cfif listFindNoCase(capabilityList, Data[i]["CapabilityName"]) eq 0>--->
				</cfloop>
			</cfif><!---<cfif arrayLen(Data)>--->
			<!--- Return the list of capabilities --->
			<cfreturn capabilityList>
				
		<cfelse>
			<!--- Return the HQL object --->
			<cfreturn Data>
		</cfif>
				
	</cffunction>

	<cffunction name="isCapabilityAuthorized" access="public" returnType="boolean" output="true" 
			hint="Simple wrapper to check session capabilities for authorization.">
		
		<cfargument name="userCapabilities" type="string" required="true" hint="Typically the session capabilities is passed in.">
		<cfargument name="authorizedCapability" type="string" required="true" hint="What capability do you want to test.">
		
			
		<cfif arguments.userCapabilities contains arguments.authorizedCapability>
			<cfset capabilityAuth = true>
		<cfelse>
			<cfset capabilityAuth = false>
		</cfif>

		<cfreturn capabilityAuth>
	</cffunction>
			
	<!---******************************************************************************************************** 
		Directives
	*********************************************************************************************************--->
			
	<cffunction name="getGalaxieBlogDirectives" access="public" returnType="string" output="false"
			hint="Get a list of the Galaxie Blog Directives">
		
		<!--- Galaxie Blog Directives. ---> 
		<cfset directiveList = "postData,attachScript,cfincludeTemplate,titleMetaTagValue,descriptionMetaTagValue,socialMediaDescMetaTagValue,facebookImageMetaTagValue,twitterImageMetaTagValue,videoPosterImageUrl,smallVideoSourceUrl,mediumVideoSourceUrl,largeVideoSourceUrl,videoCaptionsUrl,videoWidthMetaData,videoHeightMetaData,youTubeUrl,vimeoVideoId">
		
		<!--- Return it --->
		<cfreturn directiveList>
			
	</cffunction>
			
	<!---//*****************************************************************************************
		RSS
	//******************************************************************************************--->

	<cffunction name="generateRSS" access="public" returnType="string" output="false"
			hint="Generates RSSa 2 feeds. This was updated and validated in Galaxie Blog 3.0">
		<cfargument name="mode" type="string" required="false" default="short" hint="If mode=short, show EXCERPT chars of entries. Otherwise, show all.">
		<cfargument name="excerpt" type="numeric" required="false" default="750" hint="If mode=short, this how many chars to show. The excerpt only applies to the body.">
		<cfargument name="params" type="struct" required="false" default="#structNew()#" hint="Passed to getPost. Note, maxEntries can't be bigger than 30.">
		<cfargument name="version" type="numeric" required="false" default="2" hint="Depracated. No longer supporting version 1">
		<cfargument name="additionalTitle" type="string" required="false" default="" hint="Adds a title to the end of your blog title. Used mainly by the cat view.">
			
		<!--- 
		Important note: the feed now works with a ?category=categoryId in the url (ie https://gregoryalexander.com/blog/rss.cfm?category=59)
		You can also use the original method to restrict by category, such as https://www.gregoryalexander.com/blog/rss.cfm?mode=full&mode2=cat&catid=59.
		--->

		<cfset var articles = "">
		<cfset var z = getTimeZoneInfo()>
		<cfset var header = "">
		<cfset var channel = "">
		<cfset var items = "">
		<cfset var dateStr = "">
		<cfset var rssStr = "">
		<!--- Note: we are not using the UTC Previx in v3. Keeping around just in case --->
		<cfset var utcPrefix = "">
		<cfset var rootUrl = "">
		<cfset var cat = "">
		<cfset var categoryId = "">
		<cfset var catlist = "">
			
		<!--- Include the string utilities cfc. --->
		<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
		<!--- Get the blog time zone --->
		<cfset blogTimeZone = application.BlogDbObj.getBlogTimeZone()>

		<!--- Right now, we force this in. Useful to limit throughput of RSS feed. I may remove this later. --->
		<cfif (structKeyExists(arguments.params,"maxEntries") and arguments.params.maxEntries gt 15) or not structKeyExists(arguments.params,"maxEntries")>
			<cfset arguments.params.maxEntries = 15>
		</cfif>
		<!--- Allow the feed to be queried by the category alias. This is a new feature added in version GB 3.57. Note: this must use the categoryId, not the category name! --->
		<cfif structKeyExists(url, 'category') and trim(url.category) neq "">
			<cfset arguments.params.byCat = URL.category>
		</cfif>
		<!--- Get the array from the database. Do not show the promoted posts at the top of the query (getPost(params, showPendingPosts, showRemovedPosts, showJsonLd, showPromoteAtTopOfQuery)).  --->
		<cfset getPost = application.blog.getPost(arguments.params,false,false,false,false)>
		<!---<cfdump var="#getPost#">--->

		<cfif find("-", blogTimeZone)>
			<!--- Note: we are not using the UTC Previx in v3. Keeping around just in case --->
			<cfset utcPrefix = " -">
		<cfelse>
			<cfset blogTimeZone = right(blogTimeZone, len(blogTimeZone) -1 )>
			<!--- Note: we are not using the UTC Previx in v3. Keeping around just in case --->
			<cfset utcPrefix = " +">
		</cfif>

		<cfsavecontent variable="header">
			<cfoutput><?xml version="1.0" encoding="utf-8"?>

			<rss version="2.0" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##" xmlns:cc="http://web.resource.org/cc/" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">

			<channel>
			<title>#xmlFormat(instance.blogTitle)##xmlFormat(arguments.additionalTitle)#</title>
			<link>#StringUtilsObj.trimStr(xmlFormat(application.blogHostUrl))#</link>
			<description>#xmlFormat(instance.blogDescription)#</description>
			<language>en</language>
			<pubDate>#dateFormat(blogNow(),"ddd, dd mmm yyyy") & " " & timeFormat(blogNow(),"HH:mm:ss") & " " & numberFormat(blogTimeZone,"00") & "00"#</pubDate>
			<lastBuildDate>{LAST_BUILD_DATE}</lastBuildDate>
			<generator>Galaxie Blog</generator>
			<docs>http://blogs.law.harvard.edu/tech/rss</docs>
			<managingEditor>#xmlFormat(instance.owneremail)# (#xmlFormat(getPost[1]["FullName"])#)</managingEditor>
			<webMaster>#xmlFormat(instance.owneremail)# (#xmlFormat(getPost[1]["FullName"])#)</webMaster>
			<itunes:subtitle>#xmlFormat(instance.itunesSubtitle)#</itunes:subtitle>
			<itunes:summary>#xmlFormat(instance.itunesSummary)#</itunes:summary>
			<itunes:category text="Technology" />
			<itunes:category text="Technology">
				<itunes:category text="Podcasting" />
			</itunes:category>
			<itunes:category text="Technology">
				<itunes:category text="Tech News" /> 
			</itunes:category>
			<itunes:keywords>#xmlFormat(instance.itunesKeywords)#</itunes:keywords>
			<itunes:author>#xmlFormat(getPost[1]["Email"])#</itunes:author> 
			<itunes:owner>
				<itunes:email>#xmlFormat(getPost[1]["Email"])#</itunes:email>
				<itunes:name>#xmlFormat(getPost[1]["FullName"])#</itunes:name>
			</itunes:owner>
			<cfif len(instance.itunesImage)>
			<itunes:image href="#xmlFormat(instance.itunesImage)#" />
			<image>
				<url>#xmlFormat(instance.itunesImage)#</url>
				<title>#xmlFormat(instance.blogTitle)#</title>
				<link>#xmlFormat(instance.blogUrl)#</link>
			</image>
			</cfif>
			<itunes:explicit>#xmlFormat('false')#</itunes:explicit>
			</cfoutput>
		</cfsavecontent>

		<cfsavecontent variable="items">
		<cfloop from="1" to="#arrayLen(getPost)#" index="i">
			<!--- Extract data from the post --->
			<cfset postId = getPost[i]["PostId"]>
			<cfset fullName = getPost[i]["FullName"]>
			<cfset email = getPost[i]["Email"]>
			<cfset mediaPath = getPost[i]["MediaPath"]>
			<cfset mediaType = getPost[i]["MediaType"]>
			<cfset mediaSize = getPost[i]["MediaSize"]>
			<cfset mimeType = getPost[i]["MimeType"]>
			<cfset title = getPost[i]["Title"]>
			<cfset description = getPost[i]["Description"]>
			<cfset body = StringUtilsObj.getTextFromBody(getPost[i]["Body"])>
			<cfset moreBody = getPost[i]["MoreBody"]>
			<cfset datePosted = getPost[i]["DatePosted"]>
			<!--- We need to remove the 'index.cfm' string when a rewrite rule is in place. --->
			<cfif application.serverRewriteRuleInPlace>
				<cfset xmlLink = xmlFormat(replaceNoCase(xmlFormat(makeLink(postId)), '/index.cfm', ''))>
			<cfelse>
				<cfset xmlLink = xmlFormat(makeLink(postId))>
			</cfif>
				
			<cfset dateStr = dateFormat(datePosted,"ddd, dd mmm yyyy") & " " & timeFormat(datePosted,"HH:mm:ss") & " " & numberFormat(blogTimeZone,"00") & "00">
				
			<!--- Description. --->
			<cfif len(description)>
				<cfset thisDesc = description>
			<cfelse>
				<!--- Set the description if it is not available. --->
				<cfif arguments.mode is "short" and len(body) gte arguments.excerpt>
					<!--- Remove the HTML tags and get the first x characters of the text. --->
					<cfset thisDesc = left( body, arguments.excerpt ) & "...">
				<cfelse>
					<cfset thisDesc = body & morebody>
				</cfif>
			</cfif>
	
			<cfoutput>
			<item>
				<title>#xmlFormat(title)#</title>
				<link>#xmlLink#</link>
				<description>#xmlFormat(thisDesc)#</description>
			<cfset getCategoriesArray = application.blog.getCategoriesByPostId(postId)>
			<cfloop from="1" to="#arrayLen(getCategoriesArray)#" index="i">
				<category>#xmlFormat(getCategoriesArray[i]["Category"])#</category>
			</cfloop>
				<pubDate>#dateStr#</pubDate>
				<guid>#xmlLink#</guid>
				<author>#xmlFormat(email)# (#xmlFormat(fullName)#)</author>
				<cfif len(mediaPath)>
				<cfif mimetype neq "">
				<enclosure url="#xmlFormat( application.blogHostUrl & '/enclosures/' & getFileFromPath(mediaPath) )#" length="#mediaSize#" type="#mimetype#"></enclosure>
				<cfelse><!---<cfif len(mediaPath)>--->
				<enclosure url="#xmlFormat( application.blogHostUrl & '/enclosures/' & getFileFromPath(mediaPath) )#" length="#mediaSize#" type="image/jpeg"></enclosure>
				</cfif><!---<cfif len(mediaPath)>--->
				<cfif mimetype eq "audio/mpeg">
				<itunes:author>#xmlFormat(email)# (#xmlFormat(fullName)#)</itunes:author>
				<itunes:explicit>#xmlFormat('no')#</itunes:explicit> 
				<itunes:duration>#xmlFormat(duration)#</itunes:duration>
				<itunes:keywords>#xmlFormat(keywords)#</itunes:keywords>
				<itunes:subtitle>#xmlFormat(subtitle)#</itunes:subtitle>
				<itunes:summary>#xmlFormat(summary)#</itunes:summary>
				<itunes:image href="#xmlFormat(instance.itunesImage)#" />
				</cfif><!---<cfif mimetype eq "audio/mpeg">--->
				</cfif><!---<cfif len(mediaPath)>--->
			</item>
			</cfoutput>
		 	</cfloop>
		</cfsavecontent>

		<cfset header = replace(header,'{LAST_BUILD_DATE}','#dateFormat(getPost[1]["DatePosted"],"ddd, dd mmm yyyy") & " " & timeFormat(getPost[1]["DatePosted"],"HH:mm:ss") & " " & numberFormat(blogTimeZone,"00") & "00"#','one')>
		<cfset rssStr = trim(header & items & "</channel></rss>")>

		<cfreturn rssStr>

	</cffunction>
					
	<!---******************************************************************************************************** 
		Ini Settings
	*********************************************************************************************************--->

	<cffunction name="setProperty" access="public" returnType="void" output="false"><!--- roles="admin"--->
		<cfargument name="property" type="string" required="true">
		<cfargument name="value" type="string" required="true">

		<cfset instance[arguments.property] = arguments.value>
		<cfset setProfileString(variables.cfgFile, instance.name, arguments.property, arguments.value)>

	</cffunction>
			
	<!---******************************************************************************************************** 
		Version Database Upgrades
	*********************************************************************************************************--->
			
	<cffunction name="updateDb" access="public" returnType="void" output="false"><!--- roles="admin"--->
		<cfargument name="tablesToPopulate" type="string" required="true">
		<cfargument name="updateRecords" type="boolean" required="true">
		<cfargument name="resetTables" type="boolean" required="false" default="false" hint="Setting this to true will delete data from the tables and reseed the index. Only use in development. This only works with SQL Server. I may use ORM's truncate statement if this causes any issues.">
		<cfargument name="debug" type="boolean" required="false" default="false">
			
		<!--- This is consumed when updating the blog version. --->
			
		<cfif isDefined("debug") and debug>invoking the updateDatabaseAfterVersionUpgrade function.<br/></cfif>

		<cfset dir = application.rootPath & "/installer/dataFiles/">

		<!--- Let's insert the data. First we need to populate the database. --->

		<!--- ******************************************************************************************
		Populate the blog table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'Blog' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM Blog;
					DBCC CHECKIDENT ('[Blog]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getBlog.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfquery name="getData" dbtype="hql" ormoptions="#{maxresults=1}#">
				SELECT BlogId FROM Blog
			</cfquery>
			<!---<cfdump var="#getData#">--->

			<!--- Get the blog url from the ini file --->
			<cfset thisBlogUrl = getProfileString(application.blogIniPath, "default", "blogUrl")>
			<!--- Get the blog title from the ini file --->
			<cfset thisBlogTitle = getProfileString(application.blogIniPath, "default", "blogTitle")>

			<!--- Save the records into the table. --->
			<cftransaction>
				<cfif arrayLen(getData) eq 0>
					<cfset BlogDbObj = EntityNew("Blog")>
				<cfelse>
					<cfset BlogDbObj = EntityLoadByPk("Blog", getData[1])>
				</cfif>

				<!--- Only update records when the updateRecords flag is set or there are no existing records --->
				<cfif not arrayLen(getData) or updateRecords>
					<!--- Set blog meta data --->
					<cfoutput query="Data" maxrows="1">
						<!--- Make the name unique. --->
						<cfset BlogDbObj.setBlogName('GalaxieBlog3_' & BlogDbObj.getBlogId())>
						<cfset BlogDbObj.setBlogTitle(thisBlogTitle)>
						<cfset BlogDbObj.setBlogDescription(blogDescription)>
						<cfset BlogDbObj.setBlogUrl(thisBlogUrl)>
						<!--- This is an optional field. --->
						<cfset BlogDbObj.setBlogMetaKeywords('')>
						<!--- Parent site (optional) --->
						<cfset BlogDbObj.setBlogParentSiteName('')>
						<cfset BlogDbObj.setBlogParentSiteUrl('')>
						<!--- Time zone --->
						<cfset BlogDbObj.setBlogTimeZone('')>
						<cfset BlogDbObj.setBlogServerTimeZoneOffset(0)>
						<!--- DSN (this is also saved in the ini file) --->
						<cfset BlogDbObj.setBlogDsn(dsn)>
						<!--- Mail server settings --->
						<cfset BlogDbObj.setBlogMailServer('')>
						<cfset BlogDbObj.setBlogMailServerUserName('')>
						<cfset BlogDbObj.setBlogMailServerPassword('')>
						<cfset BlogDbObj.setBlogEmailFailToAddress('')>	
						<cfset BlogDbObj.setBlogEmail('')>
						<!--- Encryption --->
						<cfset BlogDbObj.setSaltAlgorithm('AES')>
						<cfset BlogDbObj.setSaltAlgorithmSize('256')>
						<cfset BlogDbObj.setHashAlgorithm('SHA-512')>
						<cfset BlogDbObj.setServiceKeyEncryptionPhrase(generateRandomPhrase())>	
						<!--- IP Block list --->
						<cfset BlogDbObj.setIpBlockList(ipBlockList)>
						<cfset BlogDbObj.setBlogVersionName(version)>
						<cfset BlogDbObj.setBlogVersionName(versionName)>
						<!--- Installed --->
						<cfset BlogDbObj.setBlogInstalled(true)>
						<!--- Date --->
						<cfset BlogDbObj.setDate(now())>
						<!--- Save it --->
						<cfset EntitySave(BlogDbObj)>
					</cfoutput>
				</cfif>
			</cftransaction>

			<cfset blogId = BlogDbObj.getBlogId()>
		</cfif>	
		<cfif isDefined("debug") and debug>Blog Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the blog option table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'BlogOption' or tablesToPopulate eq 'all'>		
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM BlogOption;
					DBCC CHECKIDENT ('[BlogOption]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getBlogOption.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<!--- Get the useSsl var from the ini file --->
			<cfset thisUseSsl = getProfileString(application.blogIniPath, "default", "useSsl")>

			<cfquery name="getData" dbtype="hql" ormoptions="#{maxresults=1}#">
				SELECT BlogOptionId FROM BlogOption
			</cfquery>

			<!--- Save the records into the table. --->
			<cftransaction>
				<cfif arrayLen(getData) eq 0>
					<cfset OptionDbObj = EntityNew("BlogOption")>
				<cfelse>
					<cfset OptionDbObj = EntityLoadByPk("BlogOption", getData[1])>
				</cfif>

				<!--- Only update records when the updateRecords flag is set or there are no existing records --->
				<cfif not arrayLen(getData) or updateRecords>
					<!--- Set blog meta data --->
					<cfoutput query="Data" maxrows="1">

						<cfset OptionDbObj.setUseSsl(thisUseSsl)>
						<cfset OptionDbObj.setDeferScriptsAndCss(deferScriptsAndCss)>
						<cfset OptionDbObj.setMinimizeCode(minimizeCode)>
						<!--- Set disable cache to be true when installing --->
						<cfset OptionDbObj.setDisableCache(true)>
						<cfset OptionDbObj.setKendoCommercial(kendoCommercial)>
						<cfset OptionDbObj.setIncludeDisqus(includeDisqus)>
						<cfset OptionDbObj.setIncludeGsap(includeGsap)>
						<!--- These are strings coming from textboxes. --->
						<cfset OptionDbObj.setJQueryCDNPath(jQueryCDNPath)>
						<cfset OptionDbObj.setKendoFolderPath(kendoFolderPath)>
						<cfset OptionDbObj.setAddThisApiKey(addThisApiKey)>
						<cfset OptionDbObj.setAddThisToolboxString(addThisToolboxString)>
						<cfset OptionDbObj.setAddThisApiKey(addThisApiKey)>
						<cfset OptionDbObj.setDisqusBlogIdentifier(disqusBlogIdentifier)>
						<cfset OptionDbObj.setDisqusApiKey(disqusApiKey)>
						<cfset OptionDbObj.setDisqusApiSecret(disqusApiSecret)>
						<cfset OptionDbObj.setDisqusAuthTokenKey(disqusAuthTokenKey)>
						<cfset OptionDbObj.setDisqusAuthUrl(disqusAuthUrl)>
						<cfset OptionDbObj.setDisqusAuthTokenUrl(disqusAuthTokenUrl)>
						<cfset OptionDbObj.setDate(now())>
						<!--- Save it --->
						<cfset EntitySave(OptionDbObj)>
					</cfoutput>	
				</cfif>

			</cftransaction>

			<cfset blogOptionId = OptionDbObj.getBlogOptionId()>
		</cfif>
		<cfif isDefined("debug") and debug>Blog Option Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the capability table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'Capability' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM Capability;
					DBCC CHECKIDENT ('[Capability]', RESEED, 0);
				</cfquery>
			</cfif>


			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getCapability.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfoutput query="Data">

				<cftransaction>

					<cfquery name="getData" dbtype="hql">
						SELECT CapabilityId FROM Capability WHERE CapabilityName = <cfqueryparam value="#capabilityName#" cfsqltype="varchar">
					</cfquery>

					<!--- Save the records into the table. --->
					<cfif arrayLen(getData) eq 0>
						<cfset CapabilityDbObj = EntityNew("Capability")>
					<cfelse>
						<cfset CapabilityDbObj = EntityLoadByPk("Capability", getData[1])>
					</cfif>

					<!--- Only update records when the updateRecords flag is set or there are no existing records --->
					<cfif not arrayLen(getData) or updateRecords>
						<!--- Set the values. --->
						<!--- Remove this when using multiple blogs: 
						<cfset CapabilityDbObj.setBlogRef(BlogDbObj)> --->
						<cfset CapabilityDbObj.setCapabilityUuid(capabilityUuid)>
						<cfset CapabilityDbObj.setCapabilityName(capabilityName)>
						<cfset CapabilityDbObj.setCapabilityUiLabel(capabilityUiLabel)>
						<cfset CapabilityDbObj.setCapabilityDescription(capabilityDescription)>
						<cfset CapabilityDbObj.setDate(now())>
						<!--- Save it --->
						<cfset EntitySave(CapabilityDbObj)>
					</cfif>
				</cftransaction>

			</cfoutput>

			<cfset CapabilityId = CapabilityDbObj.getCapabilityId()>
		</cfif>
		<cfif isDefined("debug") and debug>Capability Table succesfully populated.<br/></cfif>	

		<!--- ******************************************************************************************
		Populate the Font table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'Font' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM Font;
					DBCC CHECKIDENT ('[Font]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getFont.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<!--- Save the records into the table. --->
			<cftransaction>
				<cfoutput query="Data">

					<cfquery name="getData" dbtype="hql">
						SELECT FontId FROM Font WHERE Font = <cfqueryparam value="#font#" cfsqltype="varchar">
					</cfquery>

					<cfif arrayLen(getData) eq 0>
						<cfset FontDbObj = EntityNew("Font")>
					<cfelse>
						<cfset FontDbObj = EntityLoadByPk("Font", getData[1])>
					</cfif>

					<!--- Only update records when the updateRecords flag is set or there are no existing records --->
					<cfif not arrayLen(getData) or updateRecords>

						<!--- Set the values. --->
						<cfset FontDbObj.setFont(Font)>
						<cfset FontDbObj.setFontWeight(fontWeight)>
						<cfset FontDbObj.setItalic(italic)>
						<cfset FontDbObj.setFontType(fontType)>
						<cfset FontDbObj.setFileName(fileName)>
						<cfset FontDbObj.setWebSafeFont(webSafeFont)>
						<cfset FontDbObj.setWebSafeFallback(webSafeFallback)>
						<cfset FontDbObj.setGoogleFont(googleFont)>
						<cfset FontDbObj.setSelfHosted(selfHosted)>
						<cfset FontDbObj.setWoff(woff)>
						<cfset FontDbObj.setWoff2(woff2)>
						<cfset FontDbObj.setUseFont(useFont)>
						<cfset FontDbObj.setDate(now())>
						<!--- Save it --->
						<cfset EntitySave(FontDbObj)>

					</cfif>
				</cfoutput>

			</cftransaction>

			<cfset FontId = FontDbObj.getFontId()>
		</cfif>	
		<cfif isDefined("debug") and debug>Font Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the Kendo Theme table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'KendoTheme' or tablesToPopulate eq 'all'>
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM KendoTheme;
					DBCC CHECKIDENT ('[KendoTheme]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getKendoTheme.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfoutput query="Data">

				<!--- Save the records into the table. --->
				<cftransaction>

					<cfquery name="getData" dbtype="hql">
						SELECT KendoThemeId FROM KendoTheme WHERE KendoTheme = <cfqueryparam value="#kendoTheme#" cfsqltype="varchar">
					</cfquery>

					<cfif arrayLen(getData) eq 0>
						<cfset KendoThemeDbObj = EntityNew("KendoTheme")>
					<cfelse>
						<cfset KendoThemeDbObj = EntityLoadByPk("KendoTheme", getData[1])>
					</cfif>

					<!--- Only update records when the updateRecords flag is set or there are no existing records --->
					<cfif not arrayLen(getData) or updateRecords>

						<!--- Set the values. --->
						<cfset KendoThemeDbObj.setKendoTheme(kendoTheme)>
						<cfset KendoThemeDbObj.setKendoCommonCssFileLocation(kendoCommonCssFileLocation)>
						<cfset KendoThemeDbObj.setKendoThemeCssFileLocation(kendoThemeCssFileLocation)>
						<cfset KendoThemeDbObj.setKendoThemeMobileCssFileLocation(kendoThemeMobileCssFileLocation)>
						<cfset KendoThemeDbObj.setDarkTheme(darkTheme)>
						<cfset KendoThemeDbObj.setDate(now())>
						<!--- Save it --->
						<cfset EntitySave(KendoThemeDbObj)>

					</cfif>

				</cftransaction>

			</cfoutput>

			<cfset KendoThemeId = KendoThemeDbObj.getKendoThemeId()>
		</cfif>	
		<cfif isDefined("debug") and debug>Kendo Theme Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the Map Provider table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'MapProvider' or tablesToPopulate eq 'all'>
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM MapProvider;
					DBCC CHECKIDENT ('[MapProvider]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getMapProvider.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfoutput query="Data">

				<!--- Save the records into the table. --->
				<cftransaction>

					<cfquery name="getData" dbtype="hql">
						SELECT MapProviderId FROM MapProvider WHERE MapProvider= <cfqueryparam value="#mapProvider#" cfsqltype="varchar">
					</cfquery>

					<cfif arrayLen(getData) eq 0>
						<cfset MapProviderDbObj = EntityNew("MapProvider")>
					<cfelse>
						<cfset MapProviderDbObj = EntityLoadByPk("MapProvider", getData[1])>
					</cfif>

					<!--- Set the values. We don't need to worry about updating existing records here --->
					<cfset MapProviderDbObj.setMapProvider(mapProvider)>
					<cfset MapProviderDbObj.setDate(now())>
					<!--- Save it --->
					<cfset EntitySave(MapProviderDbObj)>

				</cftransaction>

			</cfoutput>

			<cfset mapProviderId = MapProviderDbObj.getMapProviderId()>
		</cfif>
		<cfif isDefined("debug") and debug>Map Provider Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the Map Type table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'MapType' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM MapType;
					DBCC CHECKIDENT ('[MapType]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getMapType.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfoutput query="Data">

				<!--- Save the records into the table. --->
				<cftransaction>

					<cfquery name="getData" dbtype="hql">
						SELECT MapTypeId FROM MapType WHERE MapType = <cfqueryparam value="#mapType#" cfsqltype="varchar">
					</cfquery>

					<cfif arrayLen(getData) eq 0>
						<cfset MapTypeDbObj = EntityNew("MapType")>
					<cfelse>
						<cfset MapTypeDbObj = EntityLoadByPk("MapType", getData[1])>
					</cfif>

					<!--- Load the MapProvider object --->
					<cfset MapProviderObj = entityLoad("MapProvider", { MapProvider = mapProvider }, "true" )>
					<!--- Set the values. --->
					<cfset MapTypeDbObj.setMapType(mapType)>
					<!--- Pass the Map Provider obj --->
					<cfset MapTypeDbObj.setMapProviderRef(MapProviderObj)>
					<cfset MapTypeDbObj.setDate(now())>
					<!--- Save it --->
					<cfset EntitySave(MapTypeDbObj)>

				</cftransaction>

			</cfoutput>

			<cfset mapTypeId = MapTypeDbObj.getMapTypeId()>
		</cfif>
		<cfif isDefined("debug") and debug>Map Type Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the Media Type table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'MediaType' or tablesToPopulate eq 'all'>
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM MediaType;
					DBCC CHECKIDENT ('[MediaType]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getMediaType.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfoutput query="Data">

				<!--- Save the records into the table. --->
				<cftransaction>

					<cfquery name="getData" dbtype="hql">
						SELECT MediaTypeId FROM MediaType WHERE MediaType = <cfqueryparam value="#mediaType#" cfsqltype="varchar">
					</cfquery>

					<cfif arrayLen(getData) eq 0>
						<cfset MediaTypeDbObj = EntityNew("MediaType")>
					<cfelse>
						<cfset MediaTypeDbObj = EntityLoadByPk("MediaType", getData[1])>
					</cfif>

					<!--- Set the values. --->
					<cfset MediaTypeDbObj.setMediaTypeStrId(mediaTypeStrId)>
					<cfset MediaTypeDbObj.setMediaType(mediaType)>
					<cfset MediaTypeDbObj.setDescription(description)>
					<cfset MediaTypeDbObj.setDate(now())>
					<!--- Save it --->
					<cfset EntitySave(MediaTypeDbObj)>

				</cftransaction>

			</cfoutput>

			<cfset mediaTypeId = MediaTypeDbObj.getMediaTypeId()>
		</cfif>
		<cfif isDefined("debug") and debug>Media Type Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the Mime Type table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'MimeType' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM MimeType;
					DBCC CHECKIDENT ('[MimeType]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getMimeType.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfoutput query="Data">

				<!--- Save the records into the table. --->
				<cftransaction>

					<cfquery name="getData" dbtype="hql">
						SELECT MimeTypeId FROM MimeType WHERE MimeType = <cfqueryparam value="#mimeType#" cfsqltype="varchar">
					</cfquery>

					<cfif arrayLen(getData) eq 0>
						<cfset MimeTypeDbObj = EntityNew("MimeType")>
					<cfelse>
						<cfset MimeTypeDbObj = EntityLoadByPk("MimeType", getData[1])>
					</cfif>

					<!--- Set the values. --->
					<cfset MimeTypeDbObj.setMimeType(mimeType)>
					<cfset MimeTypeDbObj.setExtension(extension)>
					<cfset MimeTypeDbObj.setDescription(description)>
					<cfset MimeTypeDbObj.setDate(now())>
					<!--- Save it --->
					<cfset EntitySave(MimeTypeDbObj)>

				</cftransaction>

			</cfoutput>

			<cfset mimeTypeId = MimeTypeDbObj.getMimeTypeId()>
		</cfif>	
		<cfif isDefined("debug") and debug>Mime Type Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the Role table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'Role' or tablesToPopulate eq 'all'>
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM Role;
					DBCC CHECKIDENT ('[Role]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getRole.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfoutput query="Data">

				<!--- Save the records into the table. --->
				<cftransaction>

				<cfquery name="getData" dbtype="hql">
					SELECT RoleId FROM Role WHERE RoleName = <cfqueryparam value="#roleName#" cfsqltype="varchar">
				</cfquery>

				<cfif arrayLen(getData) eq 0>
					<cfset RoleDbObj = EntityNew("Role")>
				<cfelse>
					<cfset RoleDbObj = EntityLoadByPk("Role", getData[1])>
				</cfif>

				<!--- Only update records when the updateRecords flag is set or there are no existing records --->
				<cfif not arrayLen(getData) or updateRecords>

					<!--- Set the values. --->
					<cfset RoleDbObj.setBlogRef(BlogDbObj)>
					<cfset RoleDbObj.setRoleUuid(roleUuid)>
					<cfset RoleDbObj.setRoleName(roleName)>
					<cfset RoleDbObj.setDescription(description)>
					<cfset RoleDbObj.setDate(now())>
					<!--- Save it --->
					<cfset EntitySave(RoleDbObj)>

				</cfif>


				</cftransaction>

			</cfoutput>

			<cfset roleId = RoleDbObj.getRoleId()>
		</cfif>	
		<cfif isDefined("debug") and debug>Role Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the Role Capability table.
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'RoleCapability' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM RoleCapability;
					DBCC CHECKIDENT ('[RoleCapability]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data stored in the ini file. --->
			<cfset fileName = "getRoleCapability.txt">
			<cffile action="read" file="#dir##fileName#" variable="QueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #QueryObj# output = "Data">
			<!---<cfdump var="#Data#">--->

			<cfoutput query="Data">

				<!--- Save the records into the table. --->
				<cftransaction>

					<cfquery name="getRole" dbtype="hql">
						SELECT RoleId FROM Role 
						WHERE RoleName = <cfqueryparam value="#roleName#" cfsqltype="varchar">
					</cfquery>
					<!---<cfdump var="#getRole#">--->

					<cfquery name="getCapability" dbtype="hql">
						SELECT CapabilityId FROM Capability 
						WHERE CapabilityName = <cfqueryparam value="#capabilityName#" cfsqltype="varchar">
					</cfquery>
					<!---<cfdump var="#getCapability#">--->

					<!--- Note: using cfqueryparam will not work here due to an ORM expecting an object. --->
					<cfquery name="getData" dbtype="hql">
						SELECT RoleCapabilityId FROM RoleCapability 
						WHERE CapabilityRef = #getCapability[1]#
						AND RoleRef = #getRole[1]#
					</cfquery>

					<!---Load the RoleCapability object--->
					<cfif arrayLen(getData) eq 0>
						<cfset RoleCapabilityDbObj = EntityNew("RoleCapability")>
					<cfelse>
						<cfset RoleCapabilityDbObj = EntityLoadByPk("RoleCapability", getData[1])>
					</cfif>

					<!--- Load the RoleDb Object --->
					<cfset RoleDbObj = entityLoad("Role", { RoleName = trim(roleName) }, "true" )>
					<!---<cfdump var="#RoleDbObj#">--->

					<!--- And load the Capability object --->
					<cfset CapabilityDbObj = entityLoad("Capability", { CapabilityName = capabilityName }, "true" )>
					<!---<cfdump var="#CapabilityDbObj#">--->

					<!--- Only update records when the updateRecords flag is set or there are no existing records --->
					<cfif not arrayLen(getData) or updateRecords>

						<!--- Set the values. --->
						<cfset RoleCapabilityDbObj.setBlogRef(BlogDbObj)>
						<cfset RoleCapabilityDbObj.setRoleRef(RoleDbObj)>
						<cfset RoleCapabilityDbObj.setCapabilityRef(CapabilityDbObj)>
						<cfset RoleCapabilityDbObj.setDate(now())>
						<!--- Save it --->
						<cfset EntitySave(RoleCapabilityDbObj)>

					</cfif>

				</cftransaction>

			</cfoutput>

			<cfset roleCapabilityId = RoleCapabilityDbObj.getRoleCapabilityId()>
		</cfif>	
		<cfif isDefined("debug") and debug>Role Capability Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the Theme and Theme Setting tables at the same time. This one is tricky...
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'Theme' or tablesToPopulate eq 'all'>	
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM Theme;
					DBCC CHECKIDENT ('[Theme]', RESEED, 0);
					DELETE FROM ThemeSetting;
					DBCC CHECKIDENT ('[ThemeSetting]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the theme data stored in the ini file. --->
			<cfset themeFileName = "getTheme.txt">
			<cffile action="read" file="#dir##themeFileName#" variable="ThemeQueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #ThemeQueryObj# output = "ThemeData">
			<!---<cfdump var="#ThemeData#">--->

			<!--- Now get the theme setting data stored in the ini file. --->
			<cfset themeSettingFileName = "getThemeSetting.txt">
			<cffile action="read" file="#dir##themeSettingFileName#" variable="ThemeSettingQueryObj">

			<!--- Convert the wddx to a ColdFusion query object --->
			<cfwddx action = "wddx2cfml" input = #ThemeSettingQueryObj# output = "ThemeSettingData">
			<!---<cfdump var="#ThemeSettingData#">--->

			<!--- The Theme and ThemeSetting must have the same number of records. We can use the Theme query object to drive the query. --->
			<cfoutput query="ThemeData">

				<!--- Save the records into the table. --->
				<cftransaction>

					<!--- We are querying the query here in order to get the right theme setting by the theme.--->
					<cfquery name="getThemeSettingByTheme" dbtype="query">
						SELECT * FROM ThemeSettingData WHERE ThemeName = <cfqueryparam value="#themeName#" cfsqltype="varchar">
					</cfquery>
					<!---<cfdump var="#getThemeSettingByTheme#" label="getThemeSettingByTheme">--->

					<!--- Get the new fontId's from the current database. We used an ORDER on the data files and the orignal ID is not going to be the new Id.--->
					<!--- Get the new menu FontId from the current database --->
					<cfquery name="getMenuFontId" dbtype="hql">
						SELECT FontId FROM Font
						WHERE Font = <cfqueryparam value="#getThemeSettingByTheme.MenuFont#" cfsqltype="varchar">
					</cfquery>

					<!--- Get the new blog name FontId from the current database --->
					<cfquery name="getBlogNameFontId" dbtype="hql">
						SELECT FontId FROM Font
						WHERE Font = <cfqueryparam value="#getThemeSettingByTheme.BlogNameFont#" cfsqltype="varchar">
					</cfquery>

					<!--- Try to get the themeId.  --->
					<cfquery name="getThemeId" dbtype="hql">
						SELECT ThemeId FROM Theme
						WHERE ThemeName = <cfqueryparam value="#themeName#" cfsqltype="varchar">
					</cfquery>

					<!--- Instantiate the ThemeObj --->
					<cfif arrayLen(getThemeId) eq 0>
						<!--- Load the Theme obj --->
						<cfset ThemeDbObj = EntityNew("Theme")>
						<!--- Load the theme setting entity --->
						<cfset ThemeSettingDbObj = EntityNew("ThemeSetting")>
					<cfelse>
						<cfset ThemeDbObj = EntityLoadByPk("Theme", getThemeId[1])>
						<!--- The indexes should be the same between both tables --->
						<cfset ThemeSettingDbObj = EntityLoadByPk("ThemeSetting", getThemeId[1])>
					</cfif>

					<!--- Load the blog object if we are only populating the theme oriented tables --->
					<cfif tablesToPopulate eq 'Theme'>
						<cfset BlogDbObj = entityLoadByPk("Blog", 1)>
					</cfif>

					<!--- Populate the Theme table --->
					<!--- Load the Kendo Theme object --->
					<cfset KendoThemeDbObj = entityLoad("KendoTheme", { KendoTheme = kendoTheme }, "true" )>

					<!--- Only update records when the updateRecords flag is set or there are no existing records. Note: the query name here is getThemeId. --->
					<cfif not arrayLen(getThemeId) or updateRecords>
						<!--- Set the values. --->
						<cfset ThemeDbObj.setBlogRef(BlogDbObj)>
						<cfset ThemeDbObj.setKendoThemeRef(KendoThemeDbObj)>
						<!---Save the theme setting. --->
						<cfset ThemeDbObj.setThemeSettingRef(ThemeSettingDbObj)>
						<cfset ThemeDbObj.setThemeAlias(themeAlias)>
						<cfset ThemeDbObj.setThemeGenre(themeGenre)>
						<!--- Always set the selected theme to false. --->
						<cfset ThemeDbObj.setSelectedTheme(0)>
						<!--- And set UseTheme to true --->
						<cfset ThemeDbObj.setUseTheme(1)>
						<cfset ThemeDbObj.setThemeName(themeName)>
						<cfset ThemeDbObj.setDarkTheme(darkTheme)>
						<cfset ThemeDbObj.setDate(now())>

						<!--- Now set the values for the Theme Setting table. --->
						<!--- Load the Font object --->
						<cfset FontDbObj = entityLoad("Font", { Font = getThemeSettingByTheme.BodyFont }, "true" )>

						<!--- Set the values. --->
						<cfset ThemeSettingDbObj.setFontRef(FontDbObj)>
						<cfset ThemeSettingDbObj.setFontSize(getThemeSettingByTheme.FontSize)>
						<cfset ThemeSettingDbObj.setFontSizeMobile(getThemeSettingByTheme.FontSizeMobile)>
						<cfset ThemeSettingDbObj.setBreakpoint(getThemeSettingByTheme.Breakpoint)>
						<cfset ThemeSettingDbObj.setContentWidth(getThemeSettingByTheme.ContentWidth)>
						<cfset ThemeSettingDbObj.setMainContainerWidth(getThemeSettingByTheme.MainContainerWidth)>
						<cfset ThemeSettingDbObj.setSideBarContainerWidth(getThemeSettingByTheme.SideBarContainerWidth)>
						<cfset ThemeSettingDbObj.setBlogBackgroundImage(getThemeSettingByTheme.BlogBackgroundImage)>
						<cfset ThemeSettingDbObj.setBlogBackgroundImageMobile(getThemeSettingByTheme.BlogBackgroundImageMobile)>
						<cfset ThemeSettingDbObj.setIncludeBackgroundImages(getThemeSettingByTheme.IncludeBackgroundImages)>
						<cfset ThemeSettingDbObj.setBlogBackgroundImageRepeat(getThemeSettingByTheme.BlogBackgroundImageRepeat)>
						<cfset ThemeSettingDbObj.setBlogBackgroundImagePosition(getThemeSettingByTheme.BlogBackgroundImagePosition)>
						<cfset ThemeSettingDbObj.setBlogBackgroundColor(getThemeSettingByTheme.BlogBackgroundColor)>
						<cfset ThemeSettingDbObj.setStretchHeaderAcrossPage(getThemeSettingByTheme.StretchHeaderAcrossPage)>
						<cfset ThemeSettingDbObj.setHeaderBackgroundImage(getThemeSettingByTheme.HeaderBackgroundImage)>
						<cfif arraylen(getMenuFontId)>
							<cfset ThemeSettingDbObj.setMenuFontRef(getMenuFontId[1])>
						</cfif>
						<cfset ThemeSettingDbObj.setCoverKendoMenuWithMenuBackgroundImage(getThemeSettingByTheme.CoverKendoMenuWithMenuBackgroundImage)>
						<cfset ThemeSettingDbObj.setLogoImageMobile(getThemeSettingByTheme.LogoImageMobile)>
						<cfset ThemeSettingDbObj.setLogoMobileWidth(getThemeSettingByTheme.LogoMobileWidth)>
						<cfset ThemeSettingDbObj.setLogoImage(getThemeSettingByTheme.LogoImage)>
						<cfset ThemeSettingDbObj.setLogoPaddingTop(getThemeSettingByTheme.LogoPaddingTop)>
						<cfset ThemeSettingDbObj.setLogoPaddingRight(getThemeSettingByTheme.LogoPaddingRight)>
						<cfset ThemeSettingDbObj.setLogoPaddingLeft(getThemeSettingByTheme.LogoPaddingLeft)>
						<cfset ThemeSettingDbObj.setLogoPaddingBottom(getThemeSettingByTheme.LogoPaddingBottom)>
						<cfset ThemeSettingDbObj.setDefaultLogoImageForSocialMediaShare(getThemeSettingByTheme.DefaultLogoImageForSocialMediaShare)>
						<cfset ThemeSettingDbObj.setBlogNameTextColor(getThemeSettingByTheme.BlogNameTextColor)>
						<cfif arrayLen(getBlogNameFontId)>
							<cfset ThemeSettingDbObj.setBlogNameFontRef(getBlogNameFontId[1])><!--- This field does not require an object --->
						</cfif>
						<cfset ThemeSettingDbObj.setBlogNameFontSize(getThemeSettingByTheme.BlogNameFontSize)>
						<cfset ThemeSettingDbObj.setBlogNameFontSizeMobile(getThemeSettingByTheme.BlogNameFontSizeMobile)>
						<cfset ThemeSettingDbObj.setHeaderBackgroundColor(getThemeSettingByTheme.HeaderBackgroundColor)>
						<cfset ThemeSettingDbObj.setMenuBackgroundImage(getThemeSettingByTheme.MenuBackgroundImage)>
						<cfset ThemeSettingDbObj.setAlignBlogMenuWithBlogContent(getThemeSettingByTheme.AlignBlogMenuWithBlogContent)>
						<cfset ThemeSettingDbObj.setTopMenuAlign(getThemeSettingByTheme.TopMenuAlign)>
						<cfset ThemeSettingDbObj.setFooterImage(getThemeSettingByTheme.FooterImage)>
						<!--- For distribution, set the WebPImagesIncluded to false otherwise they will have to upload webp versions of any new background images. I'll add a better interface to handle this in the next version. --->
						<cfset ThemeSettingDbObj.setWebPImagesIncluded(false)>
						<cfset ThemeSettingDbObj.setDate(now())>
						<!--- Save the theme setting --->
						<cfset EntitySave(ThemeSettingDbObj)>
						<!--- Save the theme --->
						<cfset EntitySave(ThemeDbObj)>

					</cfif>
				</cftransaction>

			</cfoutput>
			<cfset themeId = ThemeDbObj.getThemeId()>
			<cfset themeSettingId = ThemeSettingDbObj.getThemeSettingId()> 
		</cfif>
		<cfif isDefined("debug") and debug>Theme Setting Table succesfully populated.<br/></cfif>

		<!--- ******************************************************************************************
		Populate the User table using the form values sent in
		********************************************************************************************--->
		<cfif tablesToPopulate eq 'User' or tablesToPopulate eq 'all'>
			<cfif resetTables>
				<cfquery name="reset">
					DELETE FROM UserRole;
					DBCC CHECKIDENT ('[UserRole]', RESEED, 0);
					DELETE FROM Users;
					DBCC CHECKIDENT ('[Users]', RESEED, 0);
				</cfquery>
			</cfif>

			<!--- Get the data from the .ini file --->
			<cfset firstName = getProfileString(application.blogIniPath, "default", "firstName")>
			<cfset lastName = getProfileString(application.blogIniPath, "default", "lastName")>
			<cfset profileDisplayName = getProfileString(application.blogIniPath, "default", "profileDisplayName")>
			<cfset email = getProfileString(application.blogIniPath, "default", "email")>
			<cfset website = getProfileString(application.blogIniPath, "default", "website")>
			<cfset userName = getProfileString(application.blogIniPath, "default", "userName")>
			<cfset password = getProfileString(application.blogIniPath, "default", "password")>
			<cfset securityAnswer1 = getProfileString(application.blogIniPath, "default", "securityAnswer1")>
			<cfset securityAnswer2 = getProfileString(application.blogIniPath, "default", "securityAnswer2")>
			<cfset securityAnswer3 = getProfileString(application.blogIniPath, "default", "securityAnswer3")>

			<cfset salt = generateSecretKey('AES', 256)>
			<cfset uuid = createUUID()>

			<cfif isDefined("debug") and debug>Captured profile information.<br/></cfif>

			<!--- Use a transaction --->
			<cftransaction>
				<!--- ******************** Save the user ******************** --->
				<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
				<cfset BlogDbObj = entityLoadByPk("Blog", 1)>

				<cfquery name="getUserId" dbtype="hql">
					SELECT new Map ( 
						UserId as UserId 
					)
					FROM Users 
					WHERE UserName = <cfqueryparam value="#userName#">
					AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				</cfquery>
				<!---<cfdump var="#getUserId#" label="getUserId">--->

				<!--- Load the entity. --->
				<cfif arrayLen(getUserId)>
					<cfset userId = getUserId[1]["UserId"]>
					<!--- Load the entity by the username --->
					<cfset UserDbObj = entityLoadByPk("Users", userId)>
				<cfelse>
					<!--- Create a new entity --->
					<cfset UserDbObj = entityNew("Users")>
				</cfif>

				<!--- Only update records when the updateRecords flag is set or there are no existing records --->
				<cfif not arrayLen(getUserId) or updateRecords>
					<!--- Use the entity objects to set the data. --->
					<cfset UserDbObj.setBlogRef(BlogDbObj)>
					<!--- Create the UUID for new records. --->
					<cfif not arrayLen(getUserId)>
						<cfset UserDbObj.setUserToken(uuid)>
					</cfif>
					<cfset UserDbObj.setFirstName(firstName)>
					<cfset UserDbObj.setLastName(lastName)>
					<cfset UserDbObj.setDisplayName(profileDisplayName)>
					<cfset UserDbObj.setFullName("#firstName# #lastName#")>	
					<cfset UserDbObj.setEmail(email)>
					<cfset UserDbObj.setWebsite(website)>
					<cfset UserDbObj.setUserName(userName)>
					<cfset UserDbObj.setPassword(#hash(salt & password, "SHA-512")#)>
					<cfset UserDbObj.setSalt(salt)>
					<cfif len(securityAnswer1) and len(securityAnswer2) and len(securityAnswer3)>
						<cfset UserDbObj.setSecurityAnswer1(securityAnswer1)>
						<cfset UserDbObj.setSecurityAnswer2(securityAnswer2)>
						<cfset UserDbObj.setSecurityAnswer3(securityAnswer3)>
					</cfif>
					<cfset UserDbObj.setChangePasswordOnLogin(false)>
					<cfset UserDbObj.setLastLogin("")>
					<cfset UserDbObj.setActive(true)>
					<cfset UserDbObj.setDate(now())>

				</cfif>

				<cfif isDefined("debug") and debug>User Table succesfully populated.<br/></cfif>

				<!--- ******************** Save the user role ******************** --->

				<!--- When inserting the original data, always load the administrator role --->
				<cfset RoleDbObj = entityLoad("Role", { RoleName = 'Administrator' }, "true" )>
				<cfif arrayLen(getUserId)>
					<cfset UserRoleDbObj = entityLoadByPK("UserRole", 1)>
				<cfelse><!---<cfif arrayLen(getUserId)>--->
					<!--- Create a new entity --->
					<cfset UserRoleDbObj = entityNew("UserRole")>
				</cfif><!---<cfif arrayLen(getUserId)>--->
				<cfset UserRoleDbObj.setBlogRef(BlogDbObj)>
				<cfset UserRoleDbObj.setRoleRef(RoleDbObj)>
				<cfset UserRoleDbObj.setUserRef(UserDbObj)>
				<cfset UserRoleDbObj.setDate(now())>

				<!--- Save the entities in reverse order that they were instantiated --->
				<cfset EntitySave(UserRoleDbObj)>
				<cfset EntitySave(RoleDbObj)>
				<cfset EntitySave(UserDbObj)>

			</cftransaction>

			<!--- Mark the blog as installed in the ini file--->
			<cfset setProfileString(application.blogIniPath, "default", "installed", true)>

		</cfif>

		<cfif isDefined("debug") and debug>Completed installation.<br/></cfif>
				
	</cffunction>
			
	<!---******************************************************************************************************** 
		Formatting
	*********************************************************************************************************--->

	<cffunction name="XHTMLParagraphFormat" returntype="string" output="false">
		<cfargument name="strTextBlock" required="true" type="string" />
		<cfreturn REReplace("<p>" & arguments.strTextBlock & "</p>", "\r+\n\r+\n", "</p><p>", "ALL") />
	</cffunction>
	
	<!--- ****************************************************************************************************** 
	Helper functions
	********************************************************************************************************--->
	
	<!--- Gregory's adaption of Raymond's getActiveDays function. This returns a query object of all of the days with a blog post and it is used for the Kendo calendar.--->
	<cffunction name="getAllActiveDates" returnType="array" output="false" 
		hint="Returns query object of all of the posted dates. This will be used for the new Kendo calendar control.">
		
		<cfset var Data = "[]" />
		
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT new Map (
				Post.DatePosted as DatePosted
			)
			FROM Post as Post
			WHERE 0=0
				AND Released = <cfqueryparam value="1">
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<!---Return the query object.--->
		<cfreturn data>

	</cffunction>
			
	<!--- From https://cflib.org/udf/listCompare
	Compares one list against another to find the elements in the first list that don't exist in the second list.
	v2 mod by Scott Coldwell

	@param List1      	Full list of delimited values. (Required)
	@param List2      	Delimited list of values you want to compare to List1. (Required)
	@param Delim1      Delimiter used for List1.  Default is the comma. (Optional)
	@param Delim2      Delimiter used for List2.  Default is the comma. (Optional)
	@param Delim3      Delimiter to use for the list returned by the function.  Default is the comma. (Optional)
	@return Returns a delimited list of values. 
	@author Rob Brooks-Bilson (rbils@amkor.com) 
	@version 2, June 25, 2009 
	--->
	<cffunction name="listCompare" output="false" returnType="string">
		<cfargument name="list1" type="string" required="true" />
		<cfargument name="list2" type="string" required="true" />
		<cfargument name="delim1" type="string" required="false" default="," />
		<cfargument name="delim2" type="string" required="false" default="," />
		<cfargument name="delim3" type="string" required="false" default="," />

		<cfset var list1Array = ListToArray(arguments.List1,Delim1) />
		<cfset var list2Array = ListToArray(arguments.List2,Delim2) />

		<!--- Remove the subset List2 from List1 to get the diff --->
		<cfset list1Array.removeAll(list2Array) />

		<!--- Return in list format --->
		<cfreturn arrayToList(list1Array, Delim3) />
	</cffunction>
			
	<cffunction name="sanitizeString" access="public" returnType="string" output="false" 
			hint="Sanitizes the HTML from a string. This function uses Jsoup and should be used prior to inserting data into the database to sanitize a string. Note: this is a slower function so don't use it when looping through tons of strings.">
		<cfargument name="str" type="string" required="true" default="">
			
		<!--- We need to clean up the html and other special characters from the json ---> 
		<!--- Remove non breaking spaces --->
		<cfset str = replaceNoCase(str, '&nbsp;', '', "all")>
		<!--- And remove other HTML... --->
		<cfinvoke component="#application.jsoupComponentPath#" method="jsoupSanitize" returnvariable="sanitizedStr">
			<cfinvokeargument name="str" value="#str#">
		</cfinvoke>
			
		<cfreturn sanitizedStr>
			
	</cffunction>
			
	<!--- Modified function taken from http://adampresley.github.io/2009/03/19/coldfusion-random-id-generation.html --->
	<cffunction name="generateRandomString" returntype="string" access="public" output="false">
		<cfargument name="numCharacters" type="numeric" required="false" default="8" />

		<cfset var chars = "abcdefghijklmnopqrstuvwxyz1234567890" />
		<cfset var random = createObject("java", "java.util.Random").init() />
		<cfset var result = createObject("java", "java.lang.StringBuffer").init(javaCast("int", arguments.numCharacters)) />
		<cfset var index = 0 />

		<cfloop from="1" to="#arguments.numCharacters#" index="index">
			<cfset result.append(chars.charAt(random.nextInt(chars.length()))) />
		</cfloop>

		<cfreturn result.toString() />
	</cffunction>
			
</cfcomponent>
