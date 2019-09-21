<cfcomponent displayName="Blog" output="no" hint="BlogCFC by Raymond Camden">

	<!--- Load utils immidiately. --->
	<cfset variables.utils = createObject("component", "utils")>
	<!--- Include the UDF (Raymond's code) --->
	<cfinclude template="../../../includes/udf.cfm">

	<cfset variables.roles = structNew()>
		
	<!--- Current blog version (GA) --->
	<cfset version = "1.35" />
	<cfset versionDate = "September 6 2019">


	<!--- Require 6.1 or higher --->
	<cfset majorVersion = listFirst(server.coldfusion.productversion)>
	<cfset minorVersion = listGetAt(server.coldfusion.productversion,2,".,")>
	<cfset cfversion = majorVersion & "." & minorVersion>
	<cfif (server.coldfusion.productname is "ColdFusion Server" and cfversion lte 6)
		  or
		  (server.coldfusion.productname is "BlueDragon" and cfversion lte 6.1)>
		<cfset variables.utils.throw("Blog must be run under ColdFusion 6.1, BlueDragon 6.2, or higher.")>
	</cfif>
	<cfset variables.isColdFusionMX8 = server.coldfusion.productname is "ColdFusion Server" and cfversion gte 8>

	<!--- Valid database types --->
	<cfset validDBTypes = "MSACCESS,MYSQL,MSSQL,ORACLE">

	<!--- cfg file --->
	<cfset variables.cfgFile = "#getDirectoryFromPath(GetCurrentTemplatePath())#/blog.ini.cfm">

	<!--- used for rendering --->
	<cfset variables.renderMethods = structNew()>

	<!--- used for settings --->
	<cfset variables.instance = "">

	<!--- Note: when adding a new element in the settings page, you must put it here if it is usign Raymond's logic in blog.cfc. If you don't, you will get a 'xx is not a valid property.' error thrown from the utils.cfc, the new property has not been added to this list. --->
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
			<cfset instance.ownerEmail = variables.utils.configParam(variables.cfgFile, arguments.name, "owneremail")>
			<cfset instance.blogURL = variables.utils.configParam(variables.cfgFile, arguments.name, "blogURL")>
			<!--- New settings on admin page. --->
			<cfset instance.parentSiteName = variables.utils.configParam(variables.cfgFile, arguments.name, "parentSiteName")>
			<cfset instance.parentSiteLink = variables.utils.configParam(variables.cfgFile, arguments.name, "parentSiteLink")>	
			<cfset instance.blogFontSize = variables.utils.configParam(variables.cfgFile, arguments.name, "blogFontSize")>
			<!---End new settings block--->
			<cfset instance.blogTitle = variables.utils.configParam(variables.cfgFile, arguments.name, "blogTitle")>
			<cfset instance.blogDescription = variables.utils.configParam(variables.cfgFile, arguments.name, "blogDescription")>
			<cfset instance.blogDBType = variables.utils.configParam(variables.cfgFile, arguments.name, "blogDBType")>
			<cfset instance.locale = variables.utils.configParam(variables.cfgFile, arguments.name, "locale")>
			<cfset instance.commentsFrom = variables.utils.configParam(variables.cfgFile,arguments.name,"commentsFrom")>
			<cfset instance.failTo = variables.utils.configParam(variables.cfgFile,arguments.name,"failTo")>
			<cfset instance.mailServer = variables.utils.configParam(variables.cfgFile,arguments.name,"mailserver")>
			<cfset instance.mailusername = variables.utils.configParam(variables.cfgFile,arguments.name,"mailusername")>
			<cfset instance.mailpassword = variables.utils.configParam(variables.cfgFile,arguments.name,"mailpassword")>
			<cfset instance.pingurls = variables.utils.configParam(variables.cfgFile,arguments.name,"pingurls")>
			<cfset instance.offset = variables.utils.configParam(variables.cfgFile, arguments.name, "offset")>
			<cfset instance.trackbackspamlist = variables.utils.configParam(variables.cfgFile, arguments.name, "trackbackspamlist")>
			<cfset instance.blogkeywords = variables.utils.configParam(variables.cfgFile, arguments.name, "blogkeywords")>
			<cfset instance.ipblocklist = variables.utils.configParam(variables.cfgFile, arguments.name, "ipblocklist")>
			<cfset instance.maxentries = variables.utils.configParam(variables.cfgFile, arguments.name, "maxentries")>
			<cfset instance.moderate = variables.utils.configParam(variables.cfgFile, arguments.name, "moderate")>
			<cfset instance.usecaptcha = variables.utils.configParam(variables.cfgFile, arguments.name, "usecaptcha")>
			<cfset instance.usecfp = variables.utils.configParam(variables.cfgFile, arguments.name, "usecfp")>
			<cfset instance.allowgravatars = variables.utils.configParam(variables.cfgFile, arguments.name, "allowgravatars")>
			<cfset instance.filebrowse = variables.utils.configParam(variables.cfgFile, arguments.name, "filebrowse")>
			<cfset instance.settings = variables.utils.configParam(variables.cfgFile, arguments.name, "settings")>
			<cfset instance.imageroot = variables.utils.configParam(variables.cfgFile, arguments.name, "imageroot")>
			<cfset instance.itunesSubtitle = variables.utils.configParam(variables.cfgFile, arguments.name, "itunesSubtitle")>
			<cfset instance.itunesSummary = variables.utils.configParam(variables.cfgFile, arguments.name, "itunesSummary")>
			<cfset instance.itunesKeywords = variables.utils.configParam(variables.cfgFile, arguments.name, "itunesKeywords")>
			<cfset instance.itunesAuthor = variables.utils.configParam(variables.cfgFile, arguments.name, "itunesAuthor")>
			<cfset instance.itunesImage = variables.utils.configParam(variables.cfgFile, arguments.name, "itunesImage")>
			<cfset instance.itunesExplicit = variables.utils.configParam(variables.cfgFile, arguments.name, "itunesExplicit")>
			<cfset instance.usetweetbacks = variables.utils.configParam(variables.cfgFile, arguments.name, "usetweetbacks")>
			<cfset instance.installed = variables.utils.configParam(variables.cfgFile, arguments.name, "installed")>
			<cfset instance.saltalgorithm = variables.utils.configParam(variables.cfgFile, arguments.name, "saltalgorithm")>
			<cfset instance.saltkeysize = variables.utils.configParam(variables.cfgFile, arguments.name, "saltkeysize")>
			<cfset instance.hashalgorithm = variables.utils.configParam(variables.cfgFile, arguments.name, "hashalgorithm")>
			<!---Added by Gregory --->
			<cfset instance.addThisApiKey = variables.utils.configParam(variables.cfgFile,arguments.name,"addThisApiKey")>
			<cfset instance.encryptionPhrase = variables.utils.configParam(variables.cfgFile,arguments.name,"encryptionPhrase")>
				

		</cfif>

		<!--- Name the blog --->
		<cfset instance.name = arguments.name>

		<!--- Only real validation we do on instance data. --->
		<cfif not isValidDBType(instance.blogDBType)>
			<cfset variables.utils.throw("#instance.blogDBType# is not a supported value (#getValidDBTypes()#)")>
		</cfif>

		<!--- If FailTo is blank, use Admin email --->
		<cfif instance.failTo is "">
			<cfset instance.failTo = instance.ownerEmail>
		</cfif>
		
		<!--- get a copy of ping --->
		<cfif variables.isColdFusionMX8>
			<cfset variables.ping = createObject("component", "ping8")>
		<cfelse>
			<cfset variables.ping = createObject("component", "ping7")>
		</cfif>

		<!--- get a copy of textblock --->
		<cfset variables.textblock = createObject("component","textblock").init(dsn=instance.dsn, username=instance.username, password=instance.password, blog=instance.name)>

		<!--- prepare rendering --->
		<cfset renderDir = getDirectoryFromPath(GetCurrentTemplatePath()) & "/render/">
		<!--- get my kids --->
		<cfdirectory action="list" name="renderCFCs" directory="#renderDir#" filter="*.cfc">

		<cfloop query="renderCFCs">
			<cfset cfcName = listDeleteAt(renderCFCs.name, listLen(renderCFCs.name, "."), ".")>

			<cfif cfcName is not "render">
				<!--- store the name --->
				<cfset variables.renderMethods[cfcName] = structNew()>
				<!--- create an instance of the CFC. It better have a render method! --->
				<cfset variables.renderMethods[cfcName].cfc = createObject("component", "render.#cfcName#")>
				<cfset md = getMetaData(variables.renderMethods[cfcName].cfc)>
				<cfif structKeyExists(md, "instructions")>
					<cfset variables.renderMethods[cfcName].instructions = md.instructions>
				</cfif>
			</cfif>

		</cfloop>

		<cfreturn this>

	</cffunction>

	<cffunction name="addCategory" access="remote" returnType="uuid" roles="admin,AddCategory,ManageCategory" output="false"
				hint="Adds a category.">
		<cfargument name="name" type="string" required="true">
		<cfargument name="alias" type="string" required="true">

		<cfset var checkC = "">
		<cfset var id = createUUID()>

		<cflock name="blogcfc.addCategory" type="exclusive" timeout=30>

			<cfif categoryExists(name="#arguments.name#")>
				<cfset variables.utils.throw("#arguments.name# already exists as a category.")>
			</cfif>

			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				insert into tblblogcategories(categoryid,categoryname,categoryalias,blog)
				values(
					<cfqueryparam value="#id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">,
					<cfqueryparam value="#arguments.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">,
					<cfqueryparam value="#arguments.alias#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">,
					<cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">)
			</cfquery>

		</cflock>

		<cfreturn id>
	</cffunction>

	<cffunction name="addComment" access="remote" returnType="uuid" output="false"
				hint="Adds a comment.">
		<cfargument name="entryid" type="uuid" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="email" type="string" required="true">
		<!--- RBB 11/02/2005:  Added website argument --->
		<cfargument name="website" type="string" required="true">
		<cfargument name="comments" type="string" required="true">
		<cfargument name="subscribe" type="boolean" required="true">
		<cfargument name="subscribeonly" type="boolean" required="false" default="false">
		<cfargument name="overridemoderation" type="boolean" required="false" default="false">

		<cfset var newID = createUUID()>
		<cfset var entry = "">
		<cfset var spam = "">
		<cfset var kill = createUUID()>

		<!--- 
		Gregory: with the new kendo editor, we are not using htmlEditFormat to store the comments. 
		<cfset arguments.comments = htmleditformat(arguments.comments)>
		--->
		<cfset arguments.comments = htmleditformat(arguments.comments)>
		<cfset arguments.name = left(htmlEditFormat(arguments.name),50)>
		<cfset arguments.email = left(htmlEditFormat(arguments.email),50)>
		<!--- RBB 11/02/2005:  Added website element --->
		<cfset arguments.website = left(htmlEditFormat(arguments.website),255)>

		<cfif not entryExists(arguments.entryid)>
			<cfset variables.utils.throw("#arguments.entryid# is not a valid entry.")>
		</cfif>

		<!--- get the entry so we can check for allowcomments --->
		<cfset entry = getEntry(arguments.entryid,true)>
		<cfif not entry.allowcomments>
			<cfset variables.utils.throw("#arguments.entryid# does not allow for comments.")>
		</cfif>

		<!--- only check spam if not a sub --->
		<cfif not arguments.subscribeonly>
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

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		<!--- RBB 11/02/2005:  Added website element --->
		insert into tblblogcomments(id,entryidfk,name,email,website,comment<cfif instance.blogDBTYPE is "ORACLE">s</cfif>,posted,subscribe,moderated,killcomment,subscribeonly)
		values(<cfqueryparam value="#newID#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">,
			   <cfqueryparam value="#arguments.entryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">,
			   <cfqueryparam value="#arguments.name#" maxlength="50">,
			   <cfqueryparam value="#arguments.email#" maxlength="50">,
			   <!--- RBB 11/02/2005:  Added website element --->
		       <cfqueryparam value="#arguments.website#" maxlength="255">,
		 	<cfif instance.blogDBType is "ORACLE">
				<cfqueryparam value="#arguments.comments#" cfsqltype="CF_SQL_CLOB">,
			<cfelse>
			   <cfqueryparam value="#arguments.comments#" cfsqltype="CF_SQL_LONGVARCHAR">,
			</cfif>
			 <cfqueryparam value="#blogNow()#" cfsqltype="CF_SQL_TIMESTAMP">,
			   <cfif instance.blogDBType is "MSSQL" or instance.blogDBType is "MSACCESS">
				   <cfqueryparam value="#arguments.subscribe#" cfsqltype="CF_SQL_BIT">
			   <cfelse>
   			   		<!--- convert yes/no to 1 or 0 --->
			   		<cfif arguments.subscribe>
			   			<cfset arguments.subscribe = 1>
			   		<cfelse>
			   			<cfset arguments.subscribe = 0>
			   		</cfif>
				   <cfqueryparam value="#arguments.subscribe#" cfsqltype="CF_SQL_TINYINT">
			   </cfif>
			   ,<cfif instance.moderate and not arguments.overridemoderation>0<cfelse>1</cfif>,
			   <cfqueryparam value="#kill#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">,
			   <cfqueryparam value="#arguments.subscribeonly#" cfsqltype="CF_SQL_TINYINT">
			   )
		</cfquery>

		<!--- If subscribe is no, auto set older posts in thread by this author to no --->
		<cfif not arguments.subscribe>

			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			update	tblblogcomments
			set		subscribe = 0
			where	entryidfk = <cfqueryparam value="#arguments.entryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and		email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfquery>

		</cfif>

		<cfreturn newID>
	</cffunction>

	<cffunction name="addEntry" access="remote" returnType="uuid" output="true"
				hint="Adds an entry."><!---roles="admin"---> 
		<cfargument name="title" type="string" required="true">
		<cfargument name="body" type="string" required="true">
		<cfargument name="morebody" type="string" required="false" default="">
		<cfargument name="alias" type="string" required="false" default="">
		<cfargument name="posted" type="date" required="false" default="#blogNow()#">
		<cfargument name="allowcomments" type="boolean" required="false" default="true">
		<cfargument name="enclosure" type="string" required="false" default="">
		<cfargument name="filesize" type="numeric" required="false" default="0">
		<cfargument name="mimetype" type="string" required="false" default="">
		<cfargument name="released" type="boolean" required="false" default="true">
		<cfargument name="relatedEntries" type="string" required="false" default="">
		<cfargument name="sendemail" type="boolean" required="false" default="true">
		<cfargument name="duration" type="string" required="false" default="">
		<cfargument name="subtitle" type="string" required="false" default="">
		<cfargument name="summary" type="string" required="false" default="">
		<cfargument name="keywords" type="string" required="false" default="">

		<cfset var id = createUUID()>
		<cfset var theURL = "">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			insert into tblblogentries(id,title,body,posted
				<cfif len(arguments.morebody)>,morebody</cfif>
				<cfif len(arguments.alias)>,alias</cfif>
				,username,blog,allowcomments,enclosure,summary,subtitle,keywords,duration,filesize,mimetype,released,views,mailed)
			values(
				<cfqueryparam value="#id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">,
				<cfqueryparam value="#arguments.title#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">,
				<cfif instance.blogDBTYPE is "ORACLE">
					<cfqueryparam cfsqltype="cf_sql_clob" value="#arguments.body#">,
				<cfelse>
					<cfqueryparam value="#arguments.body#" cfsqltype="CF_SQL_LONGVARCHAR">,
				</cfif>

				<cfqueryparam value="#arguments.posted#" cfsqltype="CF_SQL_TIMESTAMP">
				<cfif len(arguments.morebody)>
					<cfif instance.blogDBType is "ORACLE">
						,<cfqueryparam cfsqltype="cf_sql_clob" value="#arguments.morebody#">
					<cfelse>
						,<cfqueryparam value="#arguments.morebody#" cfsqltype="CF_SQL_LONGVARCHAR">
					</cfif>
				</cfif>
				<cfif len(arguments.alias)>
					,<cfqueryparam value="#arguments.alias#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
				</cfif>
				,<cfqueryparam value="#getAuthUser()#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">,
				<cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">,
			    <cfif instance.blogDBType is not "MYSQL" AND instance.blogDBType is not "ORACLE">
					<cfqueryparam value="#arguments.allowcomments#" cfsqltype="CF_SQL_BIT">
			   <cfelse>
   			   		<!--- convert yes/no to 1 or 0 --->
			   		<cfif arguments.allowcomments>
			   			<cfset arguments.allowcomments = 1>
			   		<cfelse>
			   			<cfset arguments.allowcomments = 0>
			   		</cfif>
					<cfqueryparam value="#arguments.allowcomments#" cfsqltype="CF_SQL_TINYINT">
			   </cfif>
   				,<cfqueryparam value="#arguments.enclosure#" cfsqltype="CF_SQL_VARCHAR" maxlength="255">
				,<cfqueryparam value="#arguments.summary#" cfsqltype="CF_SQL_VARCHAR" maxlength="255">
				,<cfqueryparam value="#arguments.subtitle#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
				,<cfqueryparam value="#arguments.keywords#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
				,<cfqueryparam value="#arguments.duration#" cfsqltype="CF_SQL_VARCHAR" maxlength="10">
   				,<cfqueryparam value="#arguments.filesize#" cfsqltype="CF_SQL_NUMERIC">
   				,<cfqueryparam value="#arguments.mimetype#" cfsqltype="CF_SQL_VARCHAR" maxlength="255">
   				,<cfif instance.blogDBType is not "MYSQL" and instance.blogDBType is not "ORACLE">
					<cfqueryparam value="#arguments.released#" cfsqltype="CF_SQL_BIT">
			   <cfelse>
   			   		<!--- convert yes/no to 1 or 0 --->
			   		<cfif arguments.released>
			   			<cfset arguments.released = 1>
			   		<cfelse>
			   			<cfset arguments.released = 0>
			   		</cfif>
					<cfqueryparam value="#arguments.released#" cfsqltype="CF_SQL_TINYINT">
			   </cfif>
				,0
				,<cfif instance.blogDBType is not "MYSQL" AND instance.blogDBType is not "ORACLE">
					<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
			   <cfelse>
					<cfqueryparam value="0" cfsqltype="CF_SQL_TINYINT">
			   </cfif>
				)
		</cfquery>

		<cfif len(trim(arguments.relatedEntries)) GT 0>
			<cfset saveRelatedEntries(id, arguments.relatedEntries) />
		</cfif>

		<!---
			  Only mail if released = true, and posted not in the future
		--->
		<cfif arguments.sendEmail and arguments.released and dateCompare(dateAdd("h", instance.offset,arguments.posted), blogNow()) lte 0>

			<cfset mailEntry(id)>

		</cfif>

		<cfif arguments.released>

			<cfif arguments.sendEmail and dateCompare(dateAdd("h", instance.offset,arguments.posted), blogNow()) is 1>
				<!--- Handle delayed posting --->
				<cfset theURL = getRootURL()>
				<cfset theURL = theURL & "admin/notify.cfm?id=#id#">
				<cfschedule action="update" task="BlogCFC Notifier #id#" operation="HTTPRequest"
							startDate="#arguments.posted#" startTime="#arguments.posted#" url="#theURL#" interval="once">
			<cfelse>
				<cfset variables.ping.pingAggregators(instance.pingurls, instance.blogtitle, instance.blogurl)>
			</cfif>

		</cfif>


		<cfreturn id>

	</cffunction>

	<cffunction name="addSubscriber" access="remote" returnType="string" output="true"
				hint="Adds a subscriber to the blog.">
		<cfargument name="email" type="string" required="true">
		<cfset var token = createUUID()>
		<cfset var getMe = "">

		<!--- First, lets see if this guy is already subscribed. --->
		<cfquery name="getMe" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	email
		from	tblblogsubscribers
		where	email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="50">
		and		blog = <cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="50">
		</cfquery>

		<cfif getMe.recordCount is 0>
			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			insert into tblblogsubscribers(email,
			token,
			blog,
			verified)
			values(<cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="50">,
			<cfqueryparam value="#token#" cfsqltype="cf_sql_varchar" maxlength="35">,
			<cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="50">,
			0
			)
			</cfquery>

			<cfreturn token>

		<cfelse>

			<cfreturn "">

		</cfif>

	</cffunction>

	<cffunction name="addUser" access="public" returnType="void" output="false" hint="Adds a user.">
		<cfargument name="username" type="string" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="password" type="string" required="true">
		<cfset var q = "">
		<cfset var salt = generateSalt()>

		<cflock name="blogcfc.adduser" type="exclusive" timeout="60">
			<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	username
			from	tblusers
			where	username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
			and		blog = <cfqueryparam cfsqltype="cf_sql_varchar" value="#instance.name#" maxlength="50">
			</cfquery>

			<cfif q.recordCount>
				<cfset variables.utils.throw("#arguments.name# already exists as a user.")>
			</cfif>

			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			insert into tblusers(username, name, password, blog, salt)
			values(
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.name#" maxlength="50">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(salt & arguments.password, instance.hashalgorithm)#" maxlength="256">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#instance.name#" maxlength="50">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#salt#" maxlength="256">
			)
			</cfquery>
		</cflock>

	</cffunction>

	<cffunction name="approveComment" access="public" returnType="void" output="false"
				hint="Approves a comment.">
		<cfargument name="commentid" type="uuid" required="true">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		update tblblogcomments
		set	   moderated =
			<cfif instance.blogDBType is "MSSQL" or instance.blogDBType is "MSACCESS">
				<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
			<cfelse>
				<cfqueryparam value="1" cfsqltype="CF_SQL_TINYINT">
			</cfif>
		where	id = <cfqueryparam value="#arguments.commentid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

	</cffunction>


	<cffunction name="assignCategory" access="remote" returnType="void" roles="admin,ReleaseEntries" output="false"
				hint="Assigns entry ID to category X">
		<cfargument name="entryid" type="uuid" required="true">
		<cfargument name="categoryid" type="uuid" required="true">
		<cfset var checkEC = "">

		<cfquery name="checkEC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	categoryidfk
			from	tblblogentriescategories
			where	categoryidfk = <cfqueryparam value="#arguments.categoryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and		entryidfk = <cfqueryparam value="#arguments.entryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

		<cfif entryExists(arguments.entryid) and categoryExists(id=arguments.categoryID) and not checkEC.recordCount>
			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				insert into tblblogentriescategories(categoryidfk,entryidfk)
				values(<cfqueryparam value="#arguments.categoryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">,<cfqueryparam value="#arguments.entryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">)
			</cfquery>
		</cfif>

	</cffunction>

	<cffunction name="assignCategories" access="remote" returnType="void" roles="admin,ReleaseEntries" output="false"
				hint="Assigns entry ID to multiple categories">
		<cfargument name="entryid" type="uuid" required="true">
		<cfargument name="categoryids" type="string" required="true">

		<cfset var i=0>

		<!--- Loop through categories --->
		<cfloop index="i" from="1" to="#listLen(arguments.categoryids)#">
			<cfset assignCategory(arguments.entryid,listGetAt(categoryids,i))>
		</cfloop>

	</cffunction>

	<cffunction name="authenticate" access="public" returnType="boolean" output="false" hint="Authenticates a user.">
		<cfargument name="username" type="string" required="true">
		<cfargument name="password" type="string" required="true">

		<cfset var q = "">
		<cfset var authenticated = false>

		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select 	username, password, salt
			from	tblusers
			where	username = <cfqueryparam value="#arguments.username#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			and		blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfquery>

		<cfif (q.recordCount eq 1) AND (q.password is hash(q.salt & arguments.password, instance.hashalgorithm))>
			<cfset authenticated = true>
		</cfif>
		
		<cfif isDefined("cookie.cftokens")>
			<cfif (cookie.cftokens is hash(q.salt & q.password, instance.hashalgorithm))>
				<cfset authenticated = true>
			</cfif>
		</cfif>

		<cfreturn authenticated>

	</cffunction>

	<cffunction name="blogNow" access="public" returntype="date" output="false"
				hint="Returns now() with the offset.">
			<cfreturn dateAdd("h", instance.offset, now())>
	</cffunction>

	<cffunction name="categoryExists" access="private" returnType="boolean" output="false"
				hint="Returns true or false if an entry exists.">
		<cfargument name="id" type="uuid" required="false">
		<cfargument name="name" type="string" required="false">
		<cfset var checkC = "">

		<!--- must pass either ID or name, but not obth --->
		<cfif (not isDefined("arguments.id") and not isDefined("arguments.name")) or (isDefined("arguments.id") and isDefined("arguments.name"))>
			<cfset variables.utils.throw("categoryExists method must be passed id or name, but not both.")>
		</cfif>

		<cfquery name="checkC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	categoryid
			from	tblblogcategories
			where
				<cfif isDefined("arguments.id")>
				categoryid = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
				</cfif>
				<cfif isDefined("arguments.name")>
				categoryname = <cfqueryparam value="#arguments.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
				</cfif>
				and blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">

		</cfquery>

		<cfreturn checkC.recordCount gte 1>

	</cffunction>

	<cffunction name="confirmSubscription" access="public" returnType="void" output="false"
				hint="Confirms a user's subscription to the blog.">
		<cfargument name="token" type="uuid" required="false">
		<cfargument name="email" type="string" required="false">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		update	tblblogsubscribers
		set		verified = 1
		<cfif structKeyExists(arguments, "token")>
		where	token = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="35" value="#arguments.token#">
		<cfelseif structKeyExists(arguments, "email")>
		where	email = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="255" value="#arguments.email#">
		<cfelse>
			<cfthrow message="Invalid call to confirmSubscription. Must pass token or email.">
		</cfif>
		</cfquery>

	</cffunction>
	
	<!---Gregory's function. I need to use this on the subscription interface on via the new subscription pod that I wrote. I need to rewrite this as I need to it return information. The current implementation is used on a different page and it fails when the token does not match the UUID in the database. I don't want the index page to always fail as I am writing a SPA application, and need better error handling. However, the previous function which this is based on it used in the admin areas, and I don't want to screw that side up, so here is my new function.--->
	<cffunction name="confirmSubscriptionViaToken" access="public" returnType="boolean" output="false"
				hint="Confirms a user's subscription to the blog via the subscription pod.">
		<cfargument name="token" type="uuid" required="true">
			
		<cfparam name="subscribed" default="false" type="boolean">

		<cfif isValid("UUID", arguments.token)> 
			<cfquery name="isSubscribed" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				SELECT Email
				FROM tblblogsubscribers
				WHERE	verified = 1
				AND	token = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="35" value="#arguments.token#">
			</cfquery>
			<cfif isSubscribed.recordcount gt 0>
				<cfquery name="isSubscribed" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
					UPDATE	tblblogsubscribers
					SET		verified = 1
					WHERE	token = <cfqueryparam cfsqltype="cf_sql_varchar" maxlength="35" value="#arguments.token#">
				</cfquery>
				<cfset subscribed = true>
			</cfif>
		</cfif>
		<cfreturn subscribed>
	</cffunction>

	<cffunction name="deleteCategory" access="public" returnType="void" roles="admin,ManageCategories" output="false"
				hint="Deletes a category.">
		<cfargument name="id" type="uuid" required="true">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			delete from tblblogentriescategories
			where categoryidfk = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			delete from tblblogcategories
			where categoryid = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

	</cffunction>

	<cffunction name="deleteComment" access="public" returnType="void" roles="admin,ReleaseEntries" output="false"
				hint="Deletes a comment based on the comment's uuid.">
		<cfargument name="id" type="uuid" required="true">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			delete from tblblogcomments
			where id = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

	</cffunction>

	<cffunction name="deleteEntry" access="remote" returnType="void" roles="admin,ReleaseEntries" output="false"
				hint="Deletes an entry, plus all comments.">
		<cfargument name="id" type="uuid" required="true">
		<cfset var entry = "">
		<cfset var enclosure = "">

		<cfif entryExists(arguments.id)>

			<!--- get the entry. we need it to clean up enclosure --->
			<cfset entry = getEntry(arguments.id)>

			<cfif entry.enclosure neq "">
				<cfif fileExists(entry.enclosure)>
					<cffile action="delete" file="#entry.enclosure#">
				</cfif>
			</cfif>

			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				delete from tblblogentries
				where id = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
				and	  blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			</cfquery>

			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				delete from tblblogentriescategories
				where entryidfk = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			</cfquery>

			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				delete from tblblogcomments
				where entryidfk = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			</cfquery>

		</cfif>

	</cffunction>

	<cffunction name="deleteUser" access="public" returnType="void" output="false" hint="Deletes a user.">
		<cfargument name="username" type="string" required="true">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		delete from tblusers
		where	blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		and		username = <cfqueryparam value="#arguments.username#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfquery>

	</cffunction>

	<cffunction name="entryExists" access="private" returnType="boolean" output="false"
				hint="Returns true or false if an entry exists.">
		<cfargument name="id" type="uuid" required="true">
		<cfset var getIt = "">

		<cfif not structKeyExists(variables, "existsCache")>
			<cfset variables.existsCache = structNew() />
		</cfif>

		<cfif structKeyExists(variables.existsCache, arguments.id)>
			<cfreturn variables.existsCache[arguments.id]>
		</cfif>
		
		<cfquery name="getIt" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select		tblblogentries.id
			from		tblblogentries
			where		tblblogentries.id = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and			tblblogentries.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			<cfif not isUserInRole("admin")>
			and			posted < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
			and			released = 1
			</cfif>
		</cfquery>

		<cfset variables.existsCache[arguments.id] = getit.recordCount gte 1>
		<cfreturn variables.existsCache[arguments.id]>

	</cffunction>


	<cffunction name="generateRSS" access="remote" returnType="string" output="false"
				hint="Attempts to generate RSS v1 or v2">
		<cfargument name="mode" type="string" required="false" default="short" hint="If mode=short, show EXCERPT chars of entries. Otherwise, show all.">
		<cfargument name="excerpt" type="numeric" required="false" default="250" hint="If mode=short, this how many chars to show.">
		<cfargument name="params" type="struct" required="false" default="#structNew()#" hint="Passed to getEntries. Note, maxEntries can't be bigger than 15.">
		<cfargument name="version" type="numeric" required="false" default="2" hint="RSS verison, Options are 1 or 2">
		<cfargument name="additionalTitle" type="string" required="false" default="" hint="Adds a title to the end of your blog title. Used mainly by the cat view.">

		<cfset var articles = "">
		<cfset var z = getTimeZoneInfo()>
		<cfset var header = "">
		<cfset var channel = "">
		<cfset var items = "">
		<cfset var dateStr = "">
		<cfset var rssStr = "">
		<cfset var utcPrefix = "">
		<cfset var rootURL = "">
		<cfset var cat = "">
		<cfset var lastid = "">
		<cfset var catid = "">
		<cfset var catlist = "">

		<!--- Right now, we force this in. Useful to limit throughput of RSS feed. I may remove this later. --->
		<cfif (structKeyExists(arguments.params,"maxEntries") and arguments.params.maxEntries gt 15) or not structKeyExists(arguments.params,"maxEntries")>
			<cfset arguments.params.maxEntries = 15>
		</cfif>

		<cfset articles = getEntries(arguments.params)>
		<!--- copy over just the actual query --->
		<cfset articles = articles.entries>

		<cfif not find("-", z.utcHourOffset)>
			<cfset utcPrefix = " -">
		<cfelse>
			<cfset z.utcHourOffset = right(z.utcHourOffset, len(z.utcHourOffset) -1 )>
			<cfset utcPrefix = " +">
		</cfif>


		<cfif arguments.version is 1>

			<cfsavecontent variable="header">
			<cfoutput>
			<?xml version="1.0" encoding="utf-8"?>

			<rdf:RDF
				xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##"
				xmlns:dc="http://purl.org/dc/elements/1.1/"
				xmlns="http://purl.org/rss/1.0/"
			>
			</cfoutput>
			</cfsavecontent>

			<cfsavecontent variable="channel">
			<cfoutput>
			<channel rdf:about="#xmlFormat(instance.blogURL)#">
			<title>#xmlFormat(instance.blogTitle)##xmlFormat(arguments.additionalTitle)#</title>
			<description>#xmlFormat(instance.blogDescription)#</description>
			<link>#xmlFormat(instance.blogURL)#</link>

			<items>
				<rdf:Seq>
					<cfloop query="articles">
					<rdf:li rdf:resource="#xmlFormat(makeLink(id))#" />
					</cfloop>
				</rdf:Seq>
			</items>

			</channel>
			</cfoutput>
			</cfsavecontent>

			<cfsavecontent variable="items">
			<cfloop query="articles">
			<cfset dateStr = dateFormat(posted,"yyyy-mm-dd")>
			<cfset dateStr = dateStr & "T" & timeFormat(posted,"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & ":00">
			<cfoutput>
		  	<item rdf:about="#xmlFormat(makeLink(id))#">
			<title>#xmlFormat(title)#</title>
			<description><cfif arguments.mode is "short" and len(REReplaceNoCase(body,"<[^>]*>","","ALL")) gte arguments.excerpt>#xmlFormat(left(REReplaceNoCase(body,"<[^>]*>","","ALL"),arguments.excerpt))#...<cfelse>#xmlFormat(body & morebody)#</cfif></description>
			<link>#xmlFormat(makeLink(id))#</link>
			<dc:date>#dateStr#</dc:date>
			<cfloop item="catid" collection="#categories#">
				<cfset catlist = listAppend(catlist, xmlFormat(categories[currentRow][catid]))>
			</cfloop>
			<dc:subject>#xmlFormat(catlist)#</dc:subject>
			</item>
			</cfoutput>
		 	</cfloop>
			</cfsavecontent>

			<cfset rssStr = trim(header & channel & items & "</rdf:RDF>")>

		<cfelseif arguments.version eq "2">

			<cfset rootURL = reReplace(instance.blogURL, "(.*)/index.cfm", "\1")>

			<cfsavecontent variable="header">
			<cfoutput>
			<?xml version="1.0" encoding="utf-8"?>

			<rss version="2.0" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns##" xmlns:cc="http://web.resource.org/cc/" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd">

			<channel>
			<title>#xmlFormat(instance.blogTitle)##xmlFormat(arguments.additionalTitle)#</title>
			<link>#xmlFormat(instance.blogURL)#</link>
			<description>#xmlFormat(instance.blogDescription)#</description>
			<language>#replace(lcase(instance.locale),'_','-','one')#</language>
			<pubDate>#dateFormat(blogNow(),"ddd, dd mmm yyyy") & " " & timeFormat(blogNow(),"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & "00"#</pubDate>
			<lastBuildDate>{LAST_BUILD_DATE}</lastBuildDate>
			<generator>BlogCFC</generator>
			<docs>http://blogs.law.harvard.edu/tech/rss</docs>
			<managingEditor>#xmlFormat(instance.owneremail)#</managingEditor>
			<webMaster>#xmlFormat(instance.owneremail)#</webMaster>
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
			<itunes:author>#xmlFormat(instance.itunesAuthor)#</itunes:author>
			<itunes:owner>
				<itunes:email>#xmlFormat(instance.owneremail)#</itunes:email>
				<itunes:name>#xmlFormat(instance.itunesAuthor)#</itunes:name>
			</itunes:owner>
			<cfif len(instance.itunesImage)>
			<itunes:image href="#xmlFormat(instance.itunesImage)#" />
			<image>
				<url>#xmlFormat(instance.itunesImage)#</url>
				<title>#xmlFormat(instance.blogTitle)#</title>
				<link>#xmlFormat(instance.blogURL)#</link>
			</image>
			</cfif>
			<itunes:explicit>#xmlFormat(instance.itunesExplicit)#</itunes:explicit>
			</cfoutput>
			</cfsavecontent>

			<cfsavecontent variable="items">
			<cfloop query="articles">
			<cfset dateStr = dateFormat(posted,"ddd, dd mmm yyyy") & " " & timeFormat(posted,"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & "00">
			<cfoutput>
			<item>
				<title>#xmlFormat(title)#</title>
				<link>#xmlFormat(makeLink(id))#</link>
				<description>
				<!--- Regex operation removes HTML code from blog body output --->
				<cfif arguments.mode is "short" and len(REReplaceNoCase(body,"<[^>]*>","","ALL")) gte arguments.excerpt>
				#xmlFormat(left(REReplace(body,"<[^>]*>","","All"),arguments.excerpt))#...
				<cfelse>#xmlFormat(body & morebody)#</cfif>
				</description>
				<cfset lastid = listLast(structKeyList(categories))>
				<cfloop item="catid" collection="#categories#">
				<category>#xmlFormat(categories[currentRow][catid])#</category>
				</cfloop>
				<pubDate>#dateStr#</pubDate>
				<guid>#xmlFormat(makeLink(id))#</guid>
				<!---
				<author>
				<name>#xmlFormat(name)#</name>
				</author>
				--->
				<cfif len(enclosure)>
				<enclosure url="#xmlFormat("#rootURL#/enclosures/#getFileFromPath(enclosure)#")#" length="#filesize#" type="#mimetype#"/>
				<cfif mimetype IS "audio/mpeg">
				<itunes:author>#xmlFormat(instance.itunesAuthor)#</itunes:author>
				<itunes:explicit>#xmlFormat(instance.itunesExplicit)#</itunes:explicit>
				<itunes:duration>#xmlFormat(duration)#</itunes:duration>
				<itunes:keywords>#xmlFormat(keywords)#</itunes:keywords>
				<itunes:subtitle>#xmlFormat(subtitle)#</itunes:subtitle>
				<itunes:summary>#xmlFormat(summary)#</itunes:summary>
				<itunes:image href="#xmlFormat(instance.itunesImage)#" />
				</cfif>
				</cfif>
			</item>
			</cfoutput>
		 	</cfloop>
			</cfsavecontent>

			<cfset header = replace(header,'{LAST_BUILD_DATE}','#dateFormat(articles.posted[1],"ddd, dd mmm yyyy") & " " & timeFormat(articles.posted[1],"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & "00"#','one')>
			<cfset rssStr = trim(header & items & "</channel></rss>")>

		</cfif>

		<cfreturn rssStr>

	</cffunction>

	<cffunction name="getActiveDays" returnType="string" output="false" hint="Returns a list of days with Entries.">
		<cfargument name="year" type="numeric" required="true">
		<cfargument name="month" type="numeric" required="true">

		<cfset var dtMonth = createDateTime(arguments.year,arguments.month,1,0,0,0)>
		<cfset var dtEndOfMonth = createDateTime(arguments.year,arguments.month,daysInMonth(dtMonth),23,59,59)>
		<cfset var days = "">
		<cfset var posted = "">

		<cfif instance.blogDBType is "MSSQL">
			<cfset posted = "dateAdd(hh, #instance.offset#, tblblogentries.posted)">
		<cfelseif instance.blogDBType is "MSACCESS">
			<cfset posted = "dateAdd('h', #instance.offset#, tblblogentries.posted)">
		<cfelseif instance.blogDBType is "MYSQL">
			<cfset posted = "date_add(posted, interval #instance.offset# hour)">
		<cfelseif instance.blogDBType is "ORACLE">
			<cfset posted = "tblblogentries.posted + (#instance.offset#/24)">
		</cfif>

		<cfquery datasource="#instance.dsn#" name="days" username="#instance.username#" password="#instance.password#">
			select distinct
				<cfif instance.blogDBType is "MSSQL">
					datepart(dd, #preserveSingleQuotes(posted)#)
				<cfelseif instance.blogDBType is "MYSQL">
					extract(day from #preserveSingleQuotes(posted)#)
				<cfelseif instance.blogDBType is "MSACCESS">
					datepart('d', #preserveSingleQuotes(posted)#)
				<cfelseif instance.blogDBType is "ORACLE">
					to_char(#preserveSingleQuotes(posted)#, 'dd')
				</cfif> as posted_day
			from tblblogentries
			where
				#preserveSingleQuotes(posted)# >= <cfqueryparam value="#dtMonth#" cfsqltype="CF_SQL_TIMESTAMP">
				and
				#preserveSingleQuotes(posted)# <= <cfqueryparam value="#dtEndOfMonth#" cfsqltype="CF_SQL_TIMESTAMP">
				and blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
				and	#preserveSingleQuotes(posted)# < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#blogNow()#">
				and	released = 1
		</cfquery>

		<cfreturn valueList(days.posted_day)>

	</cffunction>
	
	<cffunction name="getArchives" access="public" returnType="query" output="false" hint="I return a query containing all of the past months/years that have entries along with the entry count">
		<cfargument name="archiveYears" type="numeric" required="false" hint="Number of years back to pull archives for. This helps limit the result set that can be returned" default="0">
		<cfset var getMonthlyArchives = "" />
		<cfset var fromYear = year(now()) - arguments.archiveYears />
		
		<cfquery name="getMonthlyArchives" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			SELECT MONTH(tblblogentries.posted) AS PreviousMonths, 
			       YEAR(tblblogentries.posted) AS PreviousYears, 
				   COUNT(tblblogentries.id) AS entryCount
			FROM tblblogentries
			WHERE tblblogentries.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			<cfif arguments.archiveYears gt 0>
			AND YEAR(tblblogentries.posted) >= #fromYear#
			</cfif>
			GROUP BY YEAR(tblblogentries.posted), MONTH(tblblogentries.posted) 
			ORDER BY PreviousYears DESC, PreviousMonths DESC				
		</cfquery>	
		
		<cfreturn getMonthlyArchives>
	</cffunction>

	<cffunction name="getBlogRoles" access="public" returnType="query" output="false">
		<cfset var q = "">

		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	id, role, description
		from	tblblogroles
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="getCategories" access="remote" returnType="query" output="false" hint="Returns a query containing all of the categories as well as their count for a specified blog.">
		<cfargument name="usecache" type="boolean" required="false" default="true">
		<cfset var getC = "">
		<cfset var getTotal = "">

		<!---
		Update on May 10, 2006
		So I wanted to update the code to handle cats with 0 entries. This proved difficult.
		My friend Tai sent code that he said would work on both mssql and mysql,
		but it only worked on mssql for me.

		So for now I'm going to use the "nice" method for mssql, and the "hack" method
		for the others. The hack method will be slower, but it should not be terrible.
		--->

		<!--- get cats is expensive when not mssql, and really, it doesn't change too often, so I'm adding a cache --->

		<cfif structKeyExists(variables, "categoryCache") and arguments.usecache>
			<cfreturn variables.categoryCache>
		</cfif>

		<cfif instance.blogDBType is "mssql">

			<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				select	tblblogcategories.categoryid, tblblogcategories.categoryname, tblblogcategories.categoryalias, count(tblblogentriescategories.entryidfk) as entryCount
				from	(tblblogcategories
				left outer join
				tblblogentriescategories ON tblblogcategories.categoryid = tblblogentriescategories.categoryidfk)
				left join tblblogentries on tblblogentriescategories.entryidfk = tblblogentries.id
				where	tblblogcategories.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
				<cfif structKeyExists(session,"loggedin")>
				<!--- Old logic
				Don't allow future posts unless logged in.
				<cfif not isUserInRole("admin")>
						and isNull(tblblogentries.posted, '1/1/1900') < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#blogNow()#">
					 	and isNull(tblblogentries.released, 1) = 1
				--->
				</cfif>
				group by tblblogcategories.categoryid, tblblogcategories.categoryname, tblblogcategories.categoryalias
				order by tblblogcategories.categoryname
			</cfquery>

		<cfelse>

			<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	tblblogcategories.categoryid, tblblogcategories.categoryname, tblblogcategories.categoryalias
			from	tblblogcategories
			where	tblblogcategories.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			order by tblblogcategories.categoryname
			</cfquery>

			<cfset queryAddColumn(getC, "entrycount", arrayNew(1))>

			<cfloop query="getC">
				<cfquery name="getTotal" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				select	count(tblblogentriescategories.entryidfk) as total
				from	tblblogentriescategories, tblblogentries
				where	tblblogentriescategories.categoryidfk = <cfqueryparam value="#categoryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
				and    tblblogentriescategories.entryidfk = tblblogentries.id
				and    tblblogentries.released = 1
				</cfquery>
				<cfif getTotal.recordCount>
					<cfset querySetCell(getC, "entrycount", getTotal.total, currentRow)>
				<cfelse>
					<cfset querySetCell(getC, "entrycount", 0, currentRow)>
				</cfif>
			</cfloop>
		</cfif>

		<cfset variables.categoryCache = getC>
		<cfreturn variables.categoryCache>
		
	</cffunction>

	<cffunction name="getCategoriesForEntry" access="remote" returnType="query" output="false" hint="Returns a query containing all of the categories for a specific blog entry.">
		<cfargument name="id" type="uuid" required="true">
		<cfset var getC = "">

		<cfif not entryExists(arguments.id)>
			<cfset variables.utils.throw("#arguments.id# does not exist.")>
		</cfif>

		<!--- updated "variables.dsn" to "instance.dsn" (DS 8/22/06) --->
		<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	tblblogcategories.categoryID, tblblogcategories.categoryname
			from	tblblogcategories, tblblogentriescategories
			where	tblblogcategories.categoryID = tblblogentriescategories.categoryidfk
			and		tblblogentriescategories.entryidfk = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>
		<cfreturn getC>

	</cffunction>

	<cffunction name="getCategory" access="remote" returnType="query" output="false" hint="Returns a query containing the category name and alias for a specific blog entry.">
		<cfargument name="id" type="uuid" required="true">
		<cfset var getC = "">

		<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	categoryname, categoryalias
			from	tblblogcategories
			where	categoryid = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and		blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfquery>

		<cfif not getC.recordCount>
			<cfset variables.utils.throw("#arguments.id# is not a valid category.")>
		</cfif>
		
		<cfreturn getC>

	</cffunction>

	<cffunction name="getCategoryByAlias" access="remote" returnType="string" output="false" hint="Returns the category name for a specific category alias.">
		<cfargument name="alias" type="string" required="true">
		<cfset var getC = "">

		<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	categoryid
			from	tblblogcategories
			where	categoryalias = <cfqueryparam value="#arguments.alias#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			and		blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfquery>

		<cfreturn getC.categoryid>

	</cffunction>

	<!--- This method originally written for parseses, but is not used. Keeping it around though. --->
	<cffunction name="getCategoryByName" access="remote" returnType="string" output="false" hint="Returns the category id for a specific category name.">
		<cfargument name="name" type="string" required="true">
		<cfset var getC = "">

		<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	categoryid
			from	tblblogcategories
			where	categoryname = <cfqueryparam value="#arguments.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			and		blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfquery>

		<cfreturn getC.categoryid>

	</cffunction>

	<cffunction name="getComment" access="remote" returnType="query" output="false"
				hint="Gets a specific comment by comment ID.">
		<cfargument name="id" type="uuid" required="true">
		<cfset var getC = "">

		<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select		id, entryidfk, name, email, website, comment<cfif instance.blogDBTYPE is "ORACLE">s</cfif>, posted, subscribe, moderated, killcomment
			from		tblblogcomments
			where		id = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

		<!--- DS 8/22/06: if this is oracle, do a q of q to return the data with column named "comment" --->
		<cfif instance.blogDBType is "ORACLE">
			<cfquery name="getC" dbtype="query">
				select		id, entryidfk, name, email, website, comments AS comment, posted, subscribe, moderated, killcomment
				from		getC
			</cfquery>
		</cfif>
		<cfreturn getC>

	</cffunction>
	
	<!--- RBB 8/23/2010: Added a new method to get comment count for an entry --->
	<cffunction name="getCommentCount" access="remote" returnType="numeric"  output="false"
				hint="Gets the total number of comments for a blog entry">
		<cfargument name="id" type="uuid" required="true">		
				
		<cfquery name="getCommentCount" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select count(id) as commentCount
			from 	tblblogcomments
			where	entryidfk = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">

			<cfif instance.moderate>
				and moderated = 1
			</cfif>
			and (subscribeonly = 0 or subscribeonly is null)
		</cfquery>				
	
		<cfreturn getCommentCount.commentCount>
	</cffunction>

	<cffunction name="getComments" access="remote" returnType="query" output="false"
				hint="Gets all comments for an entry ID.">
		<cfargument name="id" type="uuid" required="false">
		<cfargument name="sortdir" type="string" required="false" default="asc">
		<cfargument name="includesubscribers" type="boolean" required="false" default="false">
		<cfargument name="search" type="string" required="false">

		<cfset var getC = "">
		<cfset var getO = "">

		<cfif structKeyExists(arguments, "id") and not entryExists(arguments.id)>
			<cfset variables.utils.throw("#arguments.id# does not exist.")>
		</cfif>

		<cfif arguments.sortDir is not "asc" and arguments.sortDir is not "desc">
			<cfset arguments.sortDir = "asc">
		</cfif>

		<!--- RBB 11/02/2005: Added website to query --->
		<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select		tblblogcomments.id, tblblogcomments.name, tblblogcomments.email, tblblogcomments.website,
						<cfif instance.blogDBTYPE is NOT "ORACLE">tblblogcomments.comment<cfelse>to_char(tblblogcomments.comments) as comments</cfif>, tblblogcomments.posted, tblblogcomments.subscribe, tblblogentries.title as entrytitle, tblblogcomments.entryidfk
			from		tblblogcomments, tblblogentries
			where		tblblogcomments.entryidfk = tblblogentries.id
			<cfif structKeyExists(arguments, "search")>
			and
						(
						<cfif instance.blogDBTYpe is not "ORACLE">
						tblblogcomments.comment
						<cfelse>
						comments
						</cfif> like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.search#%">
						or
						tblblogcomments.name like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.search#%">
						)
			</cfif>
			<cfif structKeyExists(arguments, "id")>
			and			tblblogcomments.entryidfk = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			</cfif>
			and			tblblogentries.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			<!--- added 12/5/2006 by Trent Richardson --->
			<cfif instance.moderate>
				and tblblogcomments.moderated = 1
			</cfif>
			<cfif not arguments.includesubscribers>
			and (subscribeonly = 0 or subscribeonly is null)
			</cfif>
			order by	tblblogcomments.posted #arguments.sortdir#
		</cfquery>

		<!--- DS 8/22/06: if this is oracle, do a q of q to return the data with column named "comment" --->
		<cfif instance.blogDBType is "ORACLE">
			<cfquery name="getO" dbtype="query">
			select		id, name, email, website,
						comments AS comment, posted, subscribe, entrytitle, entryidfk
			from		getC
			order by	posted #arguments.sortdir#
			</cfquery>

			<cfreturn getO>
		</cfif>

		<cfreturn getC>

	</cffunction>

	<!--- Deprecated --->
	<cffunction name="getEntry" access="remote" returnType="struct" output="false"
				hint="Returns one particular entry.">
		<cfargument name="id" type="uuid" required="true">
		<cfargument name="dontlog" type="boolean" required="false" default="false">
		<cfset var getIt = "">
		<cfset var s = structNew()>
		<cfset var col = "">
		<cfset var getCategories = "">

		<cfif not entryExists(arguments.id)>
			<cfset variables.utils.throw("#arguments.id# does not exist.")>
		</cfif>

		<cfquery name="getIt" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select		tblblogentries.id, tblblogentries.title,
						<!--- Handle offset --->
						<cfif instance.blogDBType is "MSACCESS">
						dateAdd('h', #instance.offset#, tblblogentries.posted) as posted,
						<cfelseif instance.blogDBType is "MSSQL">
						dateAdd(hh, #instance.offset#, tblblogentries.posted) as posted,
						<cfelseif instance.blogDBType is "ORACLE">
						tblblogentries.posted + (#instance.offset#/24) as posted,
						<cfelse>
						date_add(posted, interval #instance.offset# hour) as posted,
						</cfif>
						tblblogentries.body,
						tblblogentries.morebody, tblblogentries.alias, tblusers.name, tblblogentries.allowcomments,
						tblblogentries.enclosure, tblblogentries.filesize, tblblogentries.mimetype, tblblogentries.released, tblblogentries.mailed,
						tblblogentries.summary, tblblogentries.keywords, tblblogentries.subtitle, tblblogentries.duration
			from		tblblogentries, tblusers
			where		tblblogentries.id = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and			tblblogentries.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			and			tblblogentries.username = tblusers.username
		</cfquery>

		<cfquery name="getCategories" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	categoryid,categoryname
			from	tblblogcategories, tblblogentriescategories
			where	tblblogentriescategories.entryidfk = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and		tblblogentriescategories.categoryidfk = tblblogcategories.categoryid
		</cfquery>

		<cfloop index="col" list="#getIt.columnList#">
			<cfset s[col] = getIt[col][1]>
		</cfloop>

		<cfset s.categories = structNew()>
		<cfloop query="getCategories">
			<cfset s.categories[categoryid] = categoryname>
		</cfloop>

		<!--- Handle view --->
		<cfif not arguments.dontlog>
			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			update	tblblogentries
			set		views = views + 1
			where	id = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			</cfquery>
		</cfif>

		<cfreturn s>

	</cffunction>
		
	<cffunction name="getEntries" access="remote" returnType="struct" output="false"
				hint="Returns entries. Allows for a params structure to configure what entries are returned.">
		<cfargument name="params" type="struct" required="false" default="#structNew()#">
		<cfargument name="loggedIn" type="string" required="false" default="no" hint="Gregory added this argument to allow the administrators to preview entries that are not released.">
		<cfset var getEm = "">
		<cfset var getComments = "">
		<cfset var getCategories = "">
		<cfset var getTrackbacks = "">
		<cfset var validOrderBy = "posted,title,views">
		<cfset var validOrderByDir = "asc,desc">
		<cfset var validMode = "short,full">
		<cfset var pos = "">
		<cfset var id = "">
		<cfset var catdata = "">
		<cfset var getIds = "">
		<cfset var idList = "">
		<cfset var pageIdList = "">
		<cfset var x = "">
		<cfset var r = structNew()>

		<!--- By default, order the results by posted col --->
		<cfif not structKeyExists(arguments.params,"orderBy") or not listFindNoCase(validOrderBy,arguments.params.orderBy)>
			<cfset arguments.params.orderBy = "posted">
		</cfif>
		<!--- By default, order the results direction desc --->
		<cfif not structKeyExists(arguments.params,"orderByDir") or not listFindNoCase(validOrderByDir,arguments.params.orderByDir)>
			<cfset arguments.params.orderByDir = "desc">
		</cfif>
		<!--- If lastXDays is passed, verify X is int between 1 and 365 --->
		<cfif structKeyExists(arguments.params,"lastXDays")>
			<cfif not val(arguments.params.lastXDays) or val(arguments.params.lastXDays) lt 1 or val(arguments.params.lastXDays) gt 365>
				<cfset structDelete(arguments.params,"lastXDays")>
			<cfelse>
				<cfset arguments.params.lastXDays = val(arguments.params.lastXDays)>
			</cfif>
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
			<cfset arguments.params.maxEntries = 10>
		</cfif>

		<cfif not structKeyExists(arguments.params,"startRow") or (structKeyExists(arguments.params,"startRow") and not val(arguments.params.startRow))>
			<cfset arguments.params.startRow = 1>
		</cfif>

		<!--- I get JUST the ids --->
		<cfquery name="getIds" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	tblblogentries.id
		from	tblblogentries, tblusers
			<cfif structKeyExists(arguments.params,"byCat")>,tblblogentriescategories</cfif>
			where		1=1
						and tblblogentries.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
						and tblblogentries.username = tblusers.username
						<!--- fix suggested by William Steiner --->
						and	tblblogentries.blog = tblusers.blog
			<cfif structKeyExists(arguments.params,"lastXDays")>
				and tblblogentries.posted >= <cfqueryparam value="#dateAdd("d",-1*arguments.params.lastXDays,blogNow())#" cfsqltype="CF_SQL_DATE">
			</cfif>
			<!--- Gregory's notes: I am suprised, but I found a bug here when using an offset of -2. The post does not show when I click on the title and One of my posts does not get picked up. I am eliminating this logic when alias is used. --->
			<cfif structKeyExists(arguments.params,"byDay") and not structKeyExists(arguments.params,"byAlias")>
				<cfif instance.blogDBType is "MSSQL">
					and day(dateAdd(hh, #instance.offset#, tblblogentries.posted))
				<cfelseif  instance.blogDBType is "MSACCESS">
					and day(dateAdd('h', #instance.offset#, tblblogentries.posted))
				<cfelseif instance.blogDBType is "MYSQL">
					and dayOfMonth(date_add(posted, interval #instance.offset# hour))
				<cfelseif instance.blogDBType is "ORACLE">
					and to_number(to_char(tblblogentries.posted + (#instance.offset#/24), 'dd'))
				</cfif>
					<cfif instance.blogDBType is not "ORACLE">
					= <cfqueryparam value="#arguments.params.byDay#" cfsqltype="CF_SQL_NUMERIC">
					<cfelse>
					= <cfqueryparam value="#arguments.params.byDay#" cfsqltype="CF_SQL_integer">
					</cfif>
			</cfif>
			<cfif structKeyExists(arguments.params,"byMonth")>
				<cfif instance.blogDBType is "MSSQL">
					and month(dateAdd(hh, #instance.offset#, tblblogentries.posted)) = <cfqueryparam value="#arguments.params.byMonth#" cfsqltype="CF_SQL_NUMERIC">
				<cfelseif instance.blogDBType is "MSACCESS">
					and month(dateAdd('h', #instance.offset#, tblblogentries.posted)) = <cfqueryparam value="#arguments.params.byMonth#" cfsqltype="CF_SQL_NUMERIC">
				<cfelseif instance.blogDBType is "MYSQL">
					and month(date_add(posted, interval #instance.offset# hour)) = <cfqueryparam value="#arguments.params.byMonth#" cfsqltype="CF_SQL_NUMERIC">
				<cfelseif instance.blogDBType is "ORACLE">
					and to_number(to_char(tblblogentries.posted + (#instance.offset#/24), 'MM')) = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.params.byMonth#">
				</cfif>
			</cfif>
			<cfif structKeyExists(arguments.params,"byYear")>
				<cfif instance.blogDBType is "MSSQL">
					and year(dateAdd(hh, #instance.offset#, tblblogentries.posted)) = <cfqueryparam value="#arguments.params.byYear#" cfsqltype="CF_SQL_NUMERIC">
				<cfelseif instance.blogDBType is "MSACCESS">
					and year(dateAdd('h', #instance.offset#, tblblogentries.posted)) = <cfqueryparam value="#arguments.params.byYear#" cfsqltype="CF_SQL_NUMERIC">
				<cfelseif instance.blogDBType is "MYSQL">
					and year(date_add(posted, interval #instance.offset# hour)) = <cfqueryparam value="#arguments.params.byYear#" cfsqltype="CF_SQL_NUMERIC">
				<cfelseif instance.blogDBType is "ORACLE">
					and to_number(to_char(tblblogentries.posted + (#instance.offset#/24), 'YYYY')) = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.params.byYear#">
				</cfif>

			</cfif>
			<cfif structKeyExists(arguments.params,"byTitle")>
				and tblblogentries.title = <cfqueryparam value="#arguments.params.byTitle#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
			</cfif>
			<cfif structKeyExists(arguments.params,"byCat")>
				and tblblogentriescategories.entryidfk = tblblogentries.id
				and tblblogentriescategories.categoryidfk in (<cfqueryparam value="#arguments.params.byCat#" cfsqltype="CF_SQL_VARCHAR" maxlength="35" list=true>)
			</cfif>
			<cfif structKeyExists(arguments.params,"byPosted")>
				and tblblogentries.username =  <cfqueryparam value="#arguments.params.byPosted#" cfsqltype="CF_SQL_VARCHAR" maxlength="50" list=true>
			</cfif>				
			<cfif structKeyExists(arguments.params,"searchTerms")>
				<cfif not structKeyExists(arguments.params, "dontlogsearch")>
					<cfset logSearch(arguments.params.searchTerms)>
				</cfif>
				<cfif instance.blogDBType is not "ORACLE">
					and (tblblogentries.title like '%#arguments.params.searchTerms#%' OR tblblogentries.body like '%#arguments.params.searchTerms#%' or tblblogentries.morebody like '%#arguments.params.searchTerms#%')
				<cfelse>
				and (lower(tblblogentries.title) like '%#lcase(arguments.params.searchTerms)#%' OR lower(tblblogentries.body) like '%#lcase(arguments.params.searchTerms)#%' or lower(tblblogentries.morebody) like '%#lcase(arguments.params.searchTerms)#%')
				</cfif>
			</cfif>
			<cfif structKeyExists(arguments.params,"byEntry")>
				and tblblogentries.id = <cfqueryparam value="#arguments.params.byEntry#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments.params,"byAlias")>
				and tblblogentries.alias = <cfqueryparam value="#left(arguments.params.byAlias,100)#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
			</cfif>
			<!--- Don't allow future posts unless logged in. --->
			<cfif not isUserInRole("admin") or (structKeyExists(arguments.params, "releasedonly") and arguments.params.releasedonly)>
				<cfif instance.blogDBType IS "ORACLE">
					 and			to_char(tblblogentries.posted + (#instance.offset#/24), 'YYYY-MM-DD HH24:MI:SS') <= <cfqueryparam cfsqltype="cf_sql_varchar" value="#dateformat(now(), 'YYYY-MM-DD')# #timeformat(now(), 'HH:mm:ss')#">
				<cfelse>
					and			posted < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
				</cfif>
				<cfif arguments.loggedIn eq 'no'>
					and			released = 1
				</cfif>
			</cfif>

			<cfif structKeyExists(arguments.params, "released")>
			and	released = <cfqueryparam cfsqltype="cf_sql_bit" value="#arguments.params.released#">
			</cfif>

			order by 	tblblogentries.#arguments.params.orderBy# #arguments.params.orderByDir#
		</cfquery>

		<!--- we now have a query from row 1 to our max, we need to get a 'page' of IDs --->
		<cfset idList = valueList(getIds.id)>
		<cfif idList eq "">
			<!---// the we need the "title" column for the spryproxy.cfm //--->
			<cfset r.entries = queryNew("id, title, posted")>
			<cfset r.totalEntries = 0>
			<cfreturn r>
		</cfif>

		<cfloop index="x" from="#arguments.params.startRow#" to="#min(arguments.params.startRow+arguments.params.maxEntries-1,getIds.recordCount)#">
			<cfset pageIdList = listAppend(pageIdList, listGetAt(idlist,x))>
		</cfloop>

		<!--- I now get the full info --->
		<cfquery name="getEm" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#" maxrows="#arguments.params.maxEntries+arguments.params.startRow-1#">
		<!--- DS 8/22/06: added Oracle pseudo top n code --->
			select
					tblblogentries.id, tblblogentries.title,
					tblblogentries.alias,
					<!--- Handle offset --->
					<cfif instance.offset neq '' and isNumeric(instance.offset)>
						<cfif instance.blogDBType is "MSACCESS">
							dateAdd('h', #instance.offset#, tblblogentries.posted) as posted,
						<cfelseif instance.blogDBType is "MSSQL">
							dateAdd(hh, #instance.offset#, tblblogentries.posted) as posted,
						<cfelseif instance.blogDBType is "ORACLE">
							tblblogentries.posted + (#instance.offset#/24) as posted,
						<cfelse>
						date_add(posted, interval #instance.offset# hour) as posted,
						</cfif>
					</cfif>
					tblusers.name, tblblogentries.allowcomments,
					tblblogentries.enclosure, tblblogentries.filesize, tblblogentries.mimetype, tblblogentries.released, tblblogentries.views,
					tblblogentries.summary, tblblogentries.subtitle, tblblogentries.keywords, tblblogentries.duration
				<cfif arguments.params.mode is "full">, tblblogentries.body, tblblogentries.morebody</cfif>
			from	tblblogentries, tblusers
			where
				tblblogentries.id in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#pageIdList#">)
						and tblblogentries.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
						and tblblogentries.username = tblusers.username
						<!--- fix by Amy Wilson --->
						and	tblblogentries.blog = tblusers.blog

			order by 	tblblogentries.#arguments.params.orderBy# #arguments.params.orderByDir#
		</cfquery>

		<cfif arguments.params.mode is "full" and getEm.recordCount>
			<cfset queryAddColumn(getEm,"commentCount",arrayNew(1))>
			<cfquery name="getComments" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				select count(id) as commentCount, entryidfk
				from 	tblblogcomments
				where	entryidfk in (<cfqueryparam value="#valueList(getEm.id)#" cfsqltype="CF_SQL_VARCHAR" list="Yes">)
				<!--- added 12/5/2006 by Trent Richardson --->
				<cfif instance.moderate>
					and moderated = 1
				</cfif>
				and (subscribeonly = 0 or subscribeonly is null)
				group by entryidfk
			</cfquery>
			<cfif getComments.recordCount>
				<!--- for each row, need to find in getEm --->
				<cfloop query="getComments">
					<cfset pos = listFindNoCase(valueList(getEm.id),entryidfk)>
					<cfif pos>
						<cfset querySetCell(getEm,"commentCount",commentCount,pos)>
					</cfif>
				</cfloop>
			</cfif>
			<cfset queryAddColumn(getEm,"categories",arrayNew(1))>
			<cfloop query="getEm">
				<cfquery name="getCategories" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
					select	categoryid,categoryname
					from	tblblogcategories, tblblogentriescategories
					where	tblblogentriescategories.entryidfk = <cfqueryparam value="#getEm.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
					and		tblblogentriescategories.categoryidfk = tblblogcategories.categoryid
				</cfquery>
				<!---
				<cfset querySetCell(getEm,"categoryids",valueList(getCategories.categoryID),currentRow)>
				<cfset querySetCell(getEm,"categorynames",valueList(getCategories.categoryname),currentRow)>
				--->
				<cfset catData = structNew()>
				<cfloop query="getCategories">
					<cfset catData[categoryID] = categoryName>
				</cfloop>
				<cfset querySetCell(getEm,"categories",catData,currentRow)>
			</cfloop>

		</cfif>
		<cfset r.entries = getEm>
		<cfset r.totalEntries = getIds.recordCount>

		<cfreturn r>

	</cffunction>
	
	<!--- RBB 8/24/2010: New method to get the date an entry was posted. Added as 
			a method since it's used by several other methods --->
	<cffunction name="getEntryPostedDate" access="public" returnType="date" output="false"
				hint="Returns the date/time an entry was posted">
		<cfargument name="entryId" type="uuid" required="true" hint="UUID of the entry you want to get post date for.">
		
		<cfset var getPostedDate = "" />
		
	    <cfquery name="getPostedDate" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
      		select posted
      		from tblblogentries
      		where id = <cfqueryparam value="#arguments.entryId#" cfsqltype="CF_SQL_VARCHAR" maxlength="35" />
    	</cfquery>
    	
		<cfreturn getPostedDate.posted>
	</cffunction>

	<cffunction name="getNameForUser" access="public" returnType="string" output="false"
				hint="Returns the full name of a user.">
		<cfargument name="username" type="string" required="true" />
		<cfset var q = "" />

		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	name
		from	tblusers
		where	username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
		</cfquery>

		<cfreturn q.name>
	</cffunction>

	<cffunction name="getNumberUnmoderated" access="public" returntype="numeric" output="false"
				hint="Returns the number of unmodderated comments for a specific blog entry.">
		<cfset var getUnmoderated = "" />
		<cfquery name="getUnmoderated" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select count(c.moderated) as unmoderated
			from tblblogcomments c, tblblogentries e
			where c.moderated=0
			and	 e.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			and c.entryidfk = e.id
		</cfquery>

		<cfreturn getUnmoderated.unmoderated>
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

	<cffunction name="getRecentComments" access="remote" returnType="query" output="false"
                hint="Returns the last N comments for a specific blog.">
        <cfargument name="maxEntries" type="numeric" required="false" default="10">
        

		<cfset var getRecentComments = "" />
		<cfset var getO = "" />
		<!--- Added by Gregory. The offeset may not be defined and it causes an error. I suspect that Raymond set the instance offset to 0 in the ini file wherease I did not, but this works too and adds more safetly. --->
		<cfif isNumeric(instance.offset) and len(instance.offset) gt 0>
			<cfset instance.offset = instance.offset>
		<cfelse>
			<cfset instance.offset = 0>
		</cfif>

		<cfquery datasource="#instance.dsn#" name="getRecentComments" username="#instance.username#" password="#instance.password#">
		<!--- DS 8/22/06: Added Oracle pseudo "top n" code --->
		<cfif instance.blogDBTYPE is "ORACLE">
		SELECT 	* FROM (
		</cfif>

		select <cfif instance.blogDBType is not "MYSQL" AND instance.blogDBType is not "ORACLE">
                    top #arguments.maxEntries#
                </cfif>
		e.id as entryID,
		e.title,
		c.id,
		c.entryidfk,
		c.name,
		c.email, <!--- RBB 8/25/2010: Added email column ---> 
		<cfif instance.blogDBType is NOT "ORACLE">c.comment<cfelse>to_char(c.comments) as comments</cfif>,
		<!--- Handle offset --->
		<cfif instance.blogDBType is "MSACCESS">
		    dateAdd('h', #instance.offset#, c.posted) as posted
		<cfelseif instance.blogDBType is "MSSQL">
		    dateAdd(hh, #instance.offset#, c.posted) as posted
		<cfelseif instance.blogDBType is "ORACLE">
			c.posted + (#instance.offset#/24) as posted
		<cfelse>
		    date_add(c.posted, interval #instance.offset# hour) as posted
		</cfif>
		from tblblogcomments c
		inner join tblblogentries e on c.entryidfk = e.id
		where	 blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		<!--- added 12/5/2006 by Trent Richardson --->
		<cfif instance.moderate>
			and c.moderated = 1
		</cfif>
		order by c.posted desc
		<cfif instance.blogDBType is "MYSQL">limit #arguments.maxEntries#</cfif>

		<cfif instance.blogDBType is "ORACLE">
		)
		WHERE	rownum <= #arguments.maxEntries#
		</cfif>
		</cfquery>

		<cfif instance.blogDBType is "ORACLE">
			<cfquery name="getO" dbtype="query">
			SELECT 	entryID, title, id, entryidfk, name, email, comments AS comment, posted <!--- RBB 8/25/2010: Added email column ---> 
			FROM	getRecentComments
			ORDER BY posted desc
			</cfquery>

			<cfreturn getO>
		</cfif>


        <cfreturn getRecentComments>

    </cffunction>

	<!--- TODO: Take a look at this, something seems wrong. --->
	<cffunction name="getRelatedBlogEntries" access="remote" returntype="query" output="true" 
				hint="returns related entries for a specific blog entry.">
	    <cfargument name="entryId" type="uuid" required="true" />
	    <cfargument name="bDislayBackwardRelations" type="boolean" hint="Displays related entries that set from another entry" default="true" />
	    <cfargument name="bDislayFutureLinks" type="boolean" hint="Displays related entries that occur after the posted date of THIS entry" default="true" />
	    <cfargument name="bDisplayForAdmin" type="boolean" hint="If admin, we can show future links not released to public" default="false" />

	    <cfset var qEntries = "" />

		<!--- BEGIN : added categoryID to related blog entry query : cjg : 31 december 2005 --->
		<!--- <cfset var qRelatedEntries = queryNew("id,title,posted,alias") />	--->
		<cfset var qRelatedEntries = queryNew("id,title,posted,alias,categoryName") />
		<!--- END : added categoryID to related blog entry query : cjg : 31 december 2005 --->

	    <cfset var qThisEntry = "" />
	    <cfset var getRelatedIds = "" />
		<cfset var getThisRelatedEntry = "" />
		<!--- RBB 8/23/2010: Refactored to use new method getEntryPostedDate --->
		<cfset var postedDate = "" />

        <cfif bdislayfuturelinks is false>
			<!--- RBB 8/23/2010: Refactored to use new method getEntryPostedDate --->
			<cfset postedDate = application.blog.getEntryPostedDate(entryID=#arguments.entryId#)>
		</cfif>
	    <cfquery name="getRelatedIds" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
	      select distinct relatedid
	      from tblblogentriesrelated
	      where entryid = <cfqueryparam value="#arguments.entryId#" cfsqltype="CF_SQL_VARCHAR" maxlength="35" />

	      <cfif bDislayBackwardRelations>
	      union

	      select distinct entryid as relatedid
	      from tblblogentriesrelated
	      where relatedid = <cfqueryparam value="#arguments.entryId#" cfsqltype="CF_SQL_VARCHAR" maxlength="35" />
	      </cfif>
	    </cfquery>
	    <cfloop query="getRelatedIds">
		  <cfquery name="getThisRelatedEntry" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select
				tblblogentries.id,
				tblblogentries.title,
				tblblogentries.posted,
				tblblogentries.alias,
				tblblogcategories.categoryname
			from
				(tblblogcategories
				inner join tblblogentriescategories on
					tblblogcategories.categoryid = tblblogentriescategories.categoryidfk)
				inner join tblblogentries on
					tblblogentriescategories.entryidfk = tblblogentries.id
	        where tblblogentries.id = <cfqueryparam value="#getrelatedids.relatedid#" cfsqltype="cf_sql_varchar" maxlength="35" />
	        and   tblblogentries.blog = <cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="255">
	        <cfif bdislayfuturelinks is false>
				<cfif instance.blogDBType is not "ORACLE">
				and tblblogentries.posted <= #createodbcdatetime(postedDate)#
				<cfelse>
				and tblblogentries.posted <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#postedDate#">
				</cfif>
	        </cfif>

			<cfif not arguments.bDisplayForAdmin>
				<cfif instance.blogDBType IS "ORACLE">
					 and			to_char(tblblogentries.posted + (#instance.offset#/24), 'YYYY-MM-DD HH24:MI:SS') <= <cfqueryparam cfsqltype="cf_sql_varchar" value="#dateformat(now(), 'YYYY-MM-DD')# #timeformat(now(), 'HH:mm:ss')#">
				<cfelse>
					and			posted < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
				</cfif>
				and			released = 1
			</cfif>

			<!--- END : added categoryName to query : cjg : 31 december 2005 --->
	      </cfquery>

	      <cfif getThisRelatedEntry.recordCount>
	        <cfset queryAddRow(qRelatedEntries, 1) />
	        <cfset querySetCell(qRelatedEntries, "id", getThisRelatedEntry.id) />
	        <cfset querySetCell(qRelatedEntries, "title", getThisRelatedEntry.title) />
	        <cfset querySetCell(qRelatedEntries, "posted", getThisRelatedEntry.posted) />
	        <cfset querySetCell(qRelatedEntries, "alias", getThisRelatedEntry.alias) />
			<!--- BEGIN : added categoryName to query : cjg : 31 december 2005 --->
			<cfset querySetCell(qRelatedEntries, "categoryName", getThisRelatedEntry.categoryName) />
			<!--- END : added categoryName to query : cjg : 31 december 2005 --->
	      </cfif>
	    </cfloop>
	    <cfif qRelatedEntries.recordCount>
	      <!--- Order By --->
	      <cfquery name="qRelatedEntries" dbtype="query">
	        select *
	        from qrelatedentries
	        order by posted desc
	      </cfquery>
	    </cfif>

		<cfreturn qRelatedEntries />
	</cffunction>
	<!--- END : get related entries method : cjg  --->
	
	<!--- RBB 8/23/2010: Added a new method to get related blog entry count for a given entry --->
	<cffunction name="getRelatedBlogEntryCount" access="remote" returnType="numeric"  output="false"
				hint="Gets the total number of related blog entriess for for a specific blog entry">
		<cfargument name="entryId" type="uuid" required="true" hint="UUID of the entry you want to get the count for.">
	    <cfargument name="bDislayBackwardRelations" type="boolean" hint="Display related entries that set from another entry" default="true" />
		<cfargument name="bDislayFutureLinks" type="boolean" hint="Display related entries that occur after the posted date of THIS entry. If true, this will return the count for items that have a future publishing date." default="true" />
		<cfargument name="bDisplayForAdmin" type="boolean" hint="If admin, we can show future links not released to public" default="false" />
		
		<cfset var postedDate = "" />
		<cfset var getRelatedBlogEntryCount = "" />
		
		<cfif arguments.bDislayFutureLinks is false>
			<cfset postedDate = application.blog.getEntryPostedDate(entryID=#arguments.entryId#)>
		</cfif>
		
		<cfquery name="getRelatedBlogEntryCount" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			SELECT count(entryId) AS relatedEntryCount
				FROM tblblogentriesrelated, tblblogentries
				WHERE tblblogentriesrelated.entryID = tblblogentries.id
				AND (tblblogentriesrelated.entryid = <cfqueryparam value="#arguments.entryId#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			<cfif arguments.bDislayBackwardRelations>
				OR tblblogentriesrelated.relatedid = <cfqueryparam value="#arguments.entryId#" cfsqltype="CF_SQL_VARCHAR" maxlength="35" />
			</cfif>					
				)
	        <cfif bdislayfuturelinks is false>
				<cfif instance.blogDBType is not "ORACLE">
				AND tblblogentries.posted <= #createodbcdatetime(postedDate)#
				<cfelse>
				AND tblblogentries.posted <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#postedDate#">
				</cfif>
	        </cfif>				
				
			<cfif arguments.bDisplayForAdmin is false>	
				<cfif instance.blogDBType IS "ORACLE">
			 		AND	to_char(tblblogentries.posted + (#instance.offset#/24), 'YYYY-MM-DD HH24:MI:SS') <= <cfqueryparam cfsqltype="cf_sql_varchar" value="#dateformat(now(), 'YYYY-MM-DD')# #timeformat(now(), 'HH:mm:ss')#">
				<cfelse>
					AND	tblblogentries.posted < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
				</cfif>
			</cfif>			
				AND	tblblogentries.released = 1
		</cfquery>
		
		<cfreturn getRelatedBlogEntryCount.relatedEntryCount>
	</cffunction>

	<cffunction name="getRelatedEntriesSelects" access="remote" returntype="query" output="false"
				hint="Returns a query containing all entries - designed to be used in the admin for 
				selecting related entries.">
		<cfset var getRelatedP = "" />

		<cfquery name="getRelatedP" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select
				tblblogcategories.categoryname,
				tblblogentries.id,
				tblblogentries.title,
				tblblogentries.posted
			from
				tblblogentries inner join
					(tblblogcategories inner join tblblogentriescategories on tblblogcategories.categoryid = tblblogentriescategories.categoryidfk) on
						tblblogentries.id = tblblogentriescategories.entryidfk

			where tblblogcategories.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			order by
				tblblogcategories.categoryname,
				tblblogentries.posted,
				tblblogentries.title
		</cfquery>

		<cfreturn getRelatedP />
	</cffunction>

	<cffunction name="getRootURL" access="public" returnType="string" output="false"
				hint="Simple helper function to get root url.">

		<cfset var theURL = replace(instance.blogurl, "index.cfm", "")>
		<cfreturn theURL>

	</cffunction>

	<cffunction name="getSubscribers" access="public" returnType="query" output="false"
				hint="Returns all people subscribed to the blog.">
		<cfargument name="verifiedonly" type="boolean" required="false" default="false">
		<cfset var getPeople = "">

		<cfquery name="getPeople" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select		email, token, verified
		from		tblblogsubscribers
		where		blog = <cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="50">
		<cfif		arguments.verifiedonly>
		and			verified = 1
		</cfif>
		order by	email asc
		</cfquery>

		<cfreturn getPeople>
	</cffunction>

	<cffunction name="getUnmoderatedComments" access="remote" returnType="query" output="false"
				hint="Gets unmoderated comments for an entry.">
		<cfargument name="id" type="uuid" required="false">
		<cfargument name="sortdir" type="string" required="false" default="asc">

		<cfset var getC = "">
		<cfset var getO = "">

		<cfif structKeyExists(arguments, "id") and not entryExists(arguments.id)>
			<cfset variables.utils.throw("#arguments.id# does not exist.")>
		</cfif>

		<cfif arguments.sortDir is not "asc" and arguments.sortDir is not "desc">
			<cfset arguments.sortDir = "asc">
		</cfif>

		<!--- RBB 11/02/2005: Added website to query --->
		<cfquery name="getC" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select		tblblogcomments.id, tblblogcomments.name, tblblogcomments.email, tblblogcomments.website,
						<cfif instance.blogDBTYPE is NOT "ORACLE">tblblogcomments.comment<cfelse>to_char(tblblogcomments.comments) as comments</cfif>, tblblogcomments.posted, tblblogcomments.subscribe, tblblogentries.title as entrytitle, tblblogcomments.entryidfk
			from		tblblogcomments, tblblogentries
			where		tblblogcomments.entryidfk = tblblogentries.id
			<cfif structKeyExists(arguments, "id")>
			and			tblblogcomments.entryidfk = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			</cfif>
			and			tblblogentries.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
			<!--- added 12/5/2006 by Trent Richardson --->
			and tblblogcomments.moderated = 0

			order by	tblblogcomments.posted #arguments.sortdir#
		</cfquery>

		<!--- DS 8/22/06: if this is oracle, do a q of q to return the data with column named "comment" --->
		<cfif instance.blogDBType is "ORACLE">
			<cfquery name="getO" dbtype="query">
			select		id, name, email, website,
						comments AS comment, posted, subscribe, entrytitle, entryidfk
			from		getC
			order by	posted #arguments.sortdir#
			</cfquery>

			<cfreturn getO>
		</cfif>

		<cfreturn getC>

	</cffunction>

	<cffunction name="getUser" access="public" returnType="struct" output="false" hint="Returns a user for a blog.">
		<cfargument name="username" type="string" required="true">
		<cfset var q = "">
		<cfset var s = structNew()>

		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	username, password, name
		from	tblusers
		where	blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		and		username = <cfqueryparam value="#arguments.username#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfquery>
		<cfif q.recordCount>
			<cfset s.username = q.username>
			<cfset s.password = q.password>
			<cfset s.name = q.name>
			<cfreturn s>
		<cfelse>
			<cfthrow message="Unknown user #arguments.username# for blog.">
		</cfif>

	</cffunction>

	<cffunction name="getUserByName" access="public" returnType="string" output="false"
				hint="Get username based on encoded name.">
		<cfargument name="name" type="string" required="true">
		<cfset var q = "">
		
		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	username
		from	tblusers
		where	name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#replace(arguments.name,"_"," ","all")#" maxlength="50">
		</cfquery>
		
		<cfreturn q.username>

	</cffunction>
	
	<cffunction name="getUserBlogRoles" access="public" returnType="string" output="false"
				hint="Returns a list of the roles for a specific user.">
		<cfargument name="username" type="string" required="true">
		<cfset var q = "">

		<!--- MSACCESS fix provided by Andy Florino --->
		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		<cfif instance.blogDBType is "MSACCESS">
		select tblblogroles.id
		from tblblogroles, tbluserroles, tblusers
		where (tblblogroles.id = tbluserroles.roleidfk and tbluserroles.username = tblusers.username)
		and tblusers.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
		and tblusers.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		<cfelse>
		select	tblblogroles.id
		from	tblblogroles
		left join tbluserroles on tbluserroles.roleidfk = tblblogroles.id
		left join tblusers on tbluserroles.username = tblusers.username
		where tblusers.username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
		and tblusers.blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfif>
		</cfquery>

		<cfreturn valueList(q.id)>
	</cffunction>

	<cffunction name="getUsers" access="public" returnType="query" output="false" hint="Returns users for a blog.">
		<cfset var q = "">

		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	username, name
		from	tblusers
		where	blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfquery>

		<cfreturn q>
	</cffunction>

	<cffunction name="getValidDBTypes" access="public" returnType="string" output="false"
				hint="Returns the valid database types.">
		<cfreturn variables.validDBTypes>
	</cffunction>

	<cffunction name="getVersion" access="remote" returnType="string" output="false"
				hint="Returns the version of the blog.">
		<cfreturn variables.version>
	</cffunction>
		
	<cffunction name="getVersionDate" access="remote" returnType="string" output="false"
				hint="Returns the version of the blog.">
		<cfreturn variables.versionDate>
	</cffunction>

	<cffunction name="isBlogAuthorized" access="public" returnType="boolean" output="false" 
			hint="Simple wrapper to check session roles and see if you are cool to do stuff. Admin role can do all.">
		<cfargument name="role" type="string" required="true">
		<!--- Roles are IDs, but to make code simpler, we allow you to specify a string, so do a cached lookup conversion. --->
		<cfset var q = "">

		<!--- cache admin once --->
		<cfif not structKeyExists(variables.roles, 'admin')>
			<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	id
			from	tblblogroles
			where	role = <cfqueryparam cfsqltype="cf_sql_varchar" value="Admin" maxlength="50">
			</cfquery>
			<cfset variables.roles['admin'] = q.id>
		</cfif>

		<cfif not structKeyExists(variables.roles, arguments.role)>
			<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	id
			from	tblblogroles
			where	role = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.role#" maxlength="50">
			</cfquery>
			<cfset variables.roles[arguments.role] = q.id>
		</cfif>

		<cfreturn (listFindNoCase(session.roles, variables.roles[arguments.role]) or listFindNoCase(session.roles, variables.roles['admin']))>
	</cffunction>

	<cffunction name="isValidDBType" access="private" returnType="boolean" output="false"
				hint="Checks to see if a db type is valid for the blog.">
		<cfargument name="dbtype" type="string" required="true">

		<cfreturn listFindNoCase(getValidDBTypes(), arguments.dbType) gte 1>

	</cffunction>

	<cffunction name="killComment" access="public" returnType="void" output="false"
				hint="Deletes a comment based on a separate uuid to identify the comment in email to the blog admin.">
		<cfargument name="kid" type="uuid" required="true">
		<cfset var q = "">

		<!--- delete comment based on kill --->
		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			delete from tblblogcomments
			where killcomment = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.kid#" maxlength="35">
		</cfquery>

	</cffunction>

	<cffunction name="logSearch" access="private" returnType="void" output="false"
				hint="Logs the search.">
		<cfargument name="searchterm" type="string" required="true">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		insert into tblblogsearchstats(searchterm, searched, blog)
		values(
			<cfqueryparam value="#arguments.searchterm#" cfsqltype="cf_sql_varchar" maxlength="255">,
			<cfqueryparam value="#blogNow()#" cfsqltype="cf_sql_timestamp">,
			<cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="50">
		)
		</cfquery>

	</cffunction>

	<cffunction name="logView" access="public" returnType="void" output="false"
				hint="Handles adding a view to an entry.">
		<cfargument name="entryid" type="uuid" required="true">
	
		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		update	tblblogentries
		set		views = views + 1
		where	id = <cfqueryparam value="#arguments.entryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

	</cffunction>
	
	<cffunction name="mailEntry" access="public" returnType="void" output="false"
				hint="Handles email for the blog.">
		<cfargument name="entryid" type="uuid" required="true">
		<cfset var entry = getEntry(arguments.entryid,true)>
		<cfset var subscribers = getSubscribers(true)>
		<cfset var theMessage = "">
		<cfset var mailBody = "">
		<cfset var renderedText = renderEntry(entry.body,true,entry.enclosure)>
		<cfset var theLink = makeLink(entry.id)>
		<cfset var rootURL = getRootURL()>

		<cfloop query="subscribers">

			<cfsavecontent variable="theMessage">
			<cfoutput>
<h2>#entry.title#</h2>
<b>URL:</b> <a href="#theLink#">#theLink#</a><br />
<b>Author:</b> #entry.name#<br />

#renderedText#<cfif len(entry.morebody)>
<a href="#theLink#">[Continued at Blog]</a></cfif>

<p>
You are receiving this email because you have subscribed to this blog.<br />
To unsubscribe, please go to this URL:
<a href="#rooturl#unsubscribe.cfm?email=#email#&amp;token=#token#">#rooturl#unsubscribe.cfm?email=#email#&amp;token=#token#</a>
</p>
			</cfoutput>
			</cfsavecontent>
			<cfset utils.mail(to=email,from=instance.owneremail,subject="#variables.utils.htmlToPlainText(htmlEditFormat(instance.blogtitle))# / #variables.utils.htmlToPlainText(entry.title)#",type="html",body=theMessage, failTo=instance.failTo, mailserver=instance.mailserver, mailusername=instance.mailusername, mailpassword=instance.mailpassword)>
		</cfloop>

		<!---
			update the record to mark it mailed.
			note: it is possible that an entry will never be marked mailed if your blog has
			no subscribers. I don't think this is an issue though.
		--->
		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		update tblblogentries
		set		mailed =
				<cfif instance.blogDBType is not "MYSQL">
					<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
			   <cfelse>
  						<cfqueryparam value="1" cfsqltype="CF_SQL_TINYINT">
			   </cfif>
		where	id = <cfqueryparam value="#arguments.entryid#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>


	</cffunction>

	<cffunction name="makeCategoryLink" access="public" returnType="string" output="false"
				hint="Generates links for a category.">
		<cfargument name="catid" type="uuid" required="true">
		<cfset var q = "">

		<!---// make sure the cache exists //--->
		<cfif not structKeyExists(variables, "catAliasCache")>
			<cfset variables.catAliasCache = structNew() />
		</cfif>

		<cfif structKeyExists(variables.catAliasCache, arguments.catid)>
			<cfreturn variables.catAliasCache[arguments.catid]>
		</cfif>
		
		<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	categoryalias
		from	tblblogcategories
		where	categoryid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.catid#" maxlength="35">
		</cfquery>

		<cfif q.categoryalias is not "">
			<cfset variables.catAliasCache[arguments.catid] = "#instance.blogURL#/#q.categoryalias#">
		<cfelse>
			<cfset variables.catAliasCache[arguments.catid] = "#instance.blogURL#?mode=cat&amp;catid=#arguments.catid#">
		</cfif>
		<cfreturn variables.catAliasCache[arguments.catid]>
	</cffunction>

	<cffunction name="makeUserLink" access="public" returnType="string" output="false"
				hint="Generates links for viewing blog posts by user/blog poster.">
		<cfargument name="name" type="string" required="true">

		<cfreturn "#instance.blogURL#/postedby/#replace(arguments.name," ","_","all")#">

	</cffunction>

	<cffunction name="cacheLink" access="public" returnType="struct" output="false"
				hint="Caches a link.">
		<cfargument name="entryid" type="uuid" required="true" />
		<cfargument name="alias" type="string" required="true" />
		<cfargument name="posted" type="date" required="true" />

		<!---// make sure the cache exists //--->
		<cfif not structKeyExists(variables, "lCache")>
			<cfset variables.lCache = structNew() />
		</cfif>

		<cfset variables.lCache[arguments.entryid] = structNew() />
		<cfset variables.lCache[arguments.entryid].alias = arguments.alias />
		<cfset variables.lCache[arguments.entryid].posted = arguments.posted />

		<cfreturn arguments />
	</cffunction>

	<cffunction name="makeLink" access="public" returnType="string" output="false"
				hint="Generates links for an entry.">
		<cfargument name="entryid" type="uuid" required="true" />
		<cfargument name="updateCache" type="boolean" required="false" default="false" />
		<cfset var q = "">
		<cfset var realdate = "">

		<cfif not structKeyExists(variables, "lCache")>
			<cfset variables.lCache = structNew()>
		</cfif>

		<!---// if forcing the cache to be updated, remove the key //--->
		<cfif arguments.updateCache>
			<cfset structDelete(variables.lCache, arguments.entryid, true) />
		</cfif>

		<cfif not structKeyExists(variables.lCache, arguments.entryid)>
			<cflock name="variablesLCache_#instance.name#" timeout="30" type="exclusive">
				<cfif not structKeyExists(variables.lCache, arguments.entryid)>
					<cfquery name="q" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
					select	posted, alias
					from	tblblogentries
					where	id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.entryid#" maxlength="35">
					</cfquery>
					<!---// cache the link //--->
					<cfset realdate = dateAdd("h", instance.offset, q.posted)>
					<cfset cacheLink(entryid=arguments.entryid, alias=q.alias, posted=realdate) />
				<cfelse>
					<!--- There was an error here after deleting an entry (Element alias is undefined in a CFML structure referenced as part of an expression). Added a try block (ga) --->
					<cftry>
						<cfset q = structNew()>
						<cfset q.alias = variables.lCache[arguments.entryid].alias>
						<cfset q.posted = variables.lCache[arguments.entryid].posted>
					<cfcatch type="any">
						<cfset error = cfcatch.message>

					</cfcatch>
					</cftry>
				</cfif>
				</cflock>
		<cfelse>
			<cfset q = structNew()>
			<cfset q.alias = variables.lCache[arguments.entryid].alias>
			<cfset q.posted = variables.lCache[arguments.entryid].posted>
		</cfif>

		<cfif q.alias is not "">
			<cfreturn "#instance.blogURL#/#year(q.posted)#/#month(q.posted)#/#day(q.posted)#/#q.alias#">
		<cfelse>
			<cfreturn "#instance.blogURL#?mode=entry&amp;entry=#arguments.entryid#">
		</cfif>
	</cffunction>

	<cffunction name="makeTitle" access="public" returnType="string" output="false"
				hint="Formats the title.">
		<cfargument name="title" type="string" required="true">

		<!--- Remove non alphanumeric but keep spaces. --->
		<!--- Changed to be more strict - Martin Baur noticed foreign chars getting through. THey
		ARE valid alphanumeric chars, but we don't want them. --->
		<!---
		<cfset arguments.title = reReplace(arguments.title,"[^[:alnum:] ]","","all")>
		--->
		<!---// replace the & symbol with the word "and" //--->
		<cfset arguments.title = replace(arguments.title, "&amp;", "and", "all") />
		<!---// remove html entities //--->
		<cfset arguments.title = reReplace(arguments.title, "&[^;]+;", "", "all") />
		<cfset arguments.title = reReplace(arguments.title,"[^0-9a-zA-Z ]","","all")>
		<!--- change spaces to - --->
		<cfset arguments.title = replace(arguments.title," ","-","all")>

		<cfreturn arguments.title>
	</cffunction>

	<cffunction name="notifyEntry" access="public" returnType="void" output="false"
				hint="Sends a message to everyone in an entry.">
		<cfargument name="entryid" type="uuid" required="true">
		<cfargument name="message" type="string" required="true">
		<cfargument name="subject" type="string" required="true">
		<cfargument name="from" type="string" required="true">

		<!--- Both of these are related to comment moderation. --->
		<cfargument name="adminonly" type="boolean" required="false">
		<cfargument name="noadmin" type="boolean" required="false">
		<cfargument name="html" type="boolean" required="false" default="false">

		<!--- used so we can get the kill switch --->
		<cfargument name="commentid" type="string" required="false">

		<cfset var emailAddresses = structNew()>
		<cfset var folks = "">
		<cfset var folk = "">
		<cfset var comments = "">
		<cfset var address = "">
		<cfset var ulink = "">
		<cfset var theMessage = "">
		<cfset var comment = getComment(arguments.commentid)>
		<cfset var fromtouse = arguments.from>
		<cfset var mailType = "text">
		
		<cfif arguments.html>
			<cfset mailType = "html">
		</cfif>
		
		<cfif len(instance.commentsFrom)>
			<cfset fromtouse = instance.commentsFrom>
		</cfif>
		
		<!--- is it a valid entry? --->
		<cfif not entryExists(arguments.entryid)>
			<cfset variables.utils.throw("#entryid# isn't a valid entry.")>
		</cfif>

		<!--- argument allows us to only send to the admin. --->
		<cfif not structKeyExists(arguments, "adminonly") or not arguments.adminonly>

			<!--- First, get everyone in the thread --->
			<cfinvoke method="getComments" returnVariable="comments">
				<cfinvokeargument name="id" value="#arguments.entryid#">
				<cfinvokeargument name="includesubscribers" value="true">
			</cfinvoke>

			<cfloop query="comments">
				<cfif isBoolean(subscribe) and subscribe and not structKeyExists(emailAddresses, email)>
					<!--- We store the id of the comment, this is used in unsub  notices --->
					<cfset emailAddresses[email] = id>
				</cfif>
			</cfloop>


		</cfif>

		<!--- Send email to admin --->
		<cfif not structKeyExists(arguments, "noadmin") or not arguments.noadmin>
			<cfset emailAddresses[instance.ownerEmail] = "">
		</cfif>

		<!--- Don't send email to from --->
		<cfset structDelete(emailAddresses, arguments.from)>

		<cfif not structIsEmpty(emailAddresses)>
			<!---
				Determine if we have a commentsFrom property. If so, it overrides this setting.
			--->
			<cfif getProperty("commentsFrom") neq "">
				<cfset arguments.from = getProperty("commentsFrom")>
			</cfif>

			<cfloop item="address" collection="#emailAddresses#">
				<!--- determine if msg has an unsub token, if so, prepare the link --->
				<!---
					Note, right now, the email sent to the admin will have a blank
					commentID. Since the admin can't unsub anyway I don't think it
					is a huge deal.
					
					Btw - I've got some of the HTML design emedded in here. This because web based
					email readers require inline CSS. I could have passed it in as an argument but
					said frack it. 
				--->
				<cfif findNoCase("%unsubscribe%", arguments.message)>
					<cfif address is not instance.ownerEmail>
						<cfset ulink = getRootURL() & "unsubscribe.cfm" &
						"?commentID=#emailAddresses[address]#&amp;email=#address#">
						<cfif mailType is "html">
							<cfset ulink = "<a href=""#ulink#"" style=""font-size:8pt;text-decoration:underline;color:##7d8524;text-decoration:none;"">Unsubscribe</a>">
						<cfelse>
							<cfset ulink = "Unsubscribe from Entry: #ulink#">
						</cfif>
					<cfelse>
						<cfset ulink = "">
						<!--- We get a bit fancier now as well as we will be allowing for kill switches --->
						<cfif mailType is "text">
							<cfset ulink = ulink & "#chr(10)#Delete this comment: #getRootURL()#index.cfm?killcomment=#comment.killcomment#">
						<cfelse>
							<cfset ulink = ulink & " <a href=""#getRootURL()#index.cfm?killcomment=#comment.killcomment#"" style=""font-size:8pt;text-decoration:underline;color:##7d8524;text-decoration:none;"">Delete</a>">
						</cfif>
						<!--- also allow for approving --->
						<cfif instance.moderate>
							<cfif mailType is "text">
								<cfset ulink = ulink & "#chr(10)#Approve this comment: #getRootURL()#index.cfm?approvecomment=#comment.id#">
							<cfelse>
								<cfset ulink = ulink & " <a href=""#getRootURL()#index.cfm?approvecomment=#comment.id#"" style=""font-size:8pt;text-decoration:underline;color:##7d8524;text-decoration:none;"">Approve</a>">
							</cfif>
						</cfif>
					</cfif>
					<cfset theMessage = replaceNoCase(arguments.message, "%unsubscribe%", ulink, "all")>
				<cfelse>
					<cfset theMessage = arguments.message>
				</cfif>

				<cfset utils.mail(to=address,from=fromtouse,subject=variables.utils.htmlToPlainText(arguments.subject),type=mailType,body=theMessage, failTo=instance.failTo, mailserver=instance.mailserver, mailusername=instance.mailusername, mailpassword=instance.mailpassword)>

			</cfloop>
		</cfif>

	</cffunction>

	<cffunction name="removeCategory" access="remote" returnType="void" roles="admin" output="false"
				hint="remove entry ID from category X">
		<cfargument name="entryid" type="uuid" required="true">
		<cfargument name="categoryid" type="uuid" required="true">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			delete from tblblogentriescategories
			where categoryidfk = <cfqueryparam value="#arguments.categoryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and entryidfk = <cfqueryparam value="#arguments.entryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

	</cffunction>

	<cffunction name="removeCategories" access="remote" returnType="void" roles="admin" output="false"
				hint="Remove all categories from an entry.">
		<cfargument name="entryid" type="uuid" required="true">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			delete from tblblogentriescategories
			where	entryidfk = <cfqueryparam value="#arguments.entryid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>
	</cffunction>

	<cffunction name="removeSubscriber" access="remote" returnType="boolean" output="false"
				hint="Removes a subscriber user.">
		<cfargument name="email" type="string" required="true">
		<cfargument name="token" type="uuid" required="false">
		<cfset var getMe = "">

		<cfif not isUserInRole("admin") and not structKeyExists(arguments,"token")>
			<cfset variables.utils.throw("Unauthorized removal.")>
		</cfif>

		<!--- First, lets see if this guy is already subscribed. --->
		<cfquery name="getMe" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	email
		from	tblblogsubscribers
		where	email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="50">
		<cfif structKeyExists(arguments, "token")>
		and		token = <cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar" maxlength="35">
		</cfif>
		</cfquery>

		<cfif getMe.recordCount is 1>
			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			delete	from tblblogsubscribers
			where	email = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="50">
			<cfif structKeyExists(arguments, "token")>
			and		token = <cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			and		blog = <cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="50">
			</cfquery>

			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>

	</cffunction>

	<cffunction name="removeUnverifiedSubscribers" access="remote" returnType="void" output="false" roles="admin"
				hint="Removes all subscribers who are not verified.">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		delete	from tblblogsubscribers
		where	blog = <cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="50">
		and		verified = 0
		</cfquery>

	</cffunction>

	<cffunction name="renderEntry" access="public" returnType="string" output="false"
				hint="Handles rendering the blog entry.">
		<cfargument name="string" type="string" required="true">
		<cfargument name="printformat" type="boolean" required="false" default="false">
		<cfargument name="enclosure" type="string" required="false" default="">
		<cfargument name="ignoreParagraphFormat" type="boolean" required="false" default="false"/>
		<cfset var counter = "">
		<cfset var codeblock = "">
		<cfset var codeportion = "">
		<cfset var result = "">
		<cfset var newbody = "">
		<cfset var style = "">
		<cfset var imgURL = "">
		<cfset var rootURL = "">
		<cfset var textblock = "">
		<cfset var tbRegex = "">
		<cfset var textblockLabel = "">
		<cfset var textblockTag = "">
		<cfset var newContent = "">

		<cfset var cfc = "">
		<cfset var newstring = "">

		<!---// check to see if we should paragraph format this string //--->
		<cfif not structKeyExists(arguments, "ignoreParagraphFormat")>
			<!---
			<cfset arguments.ignoreParagraphFormat = yesNoFormat(reFindNoCase('<p[^e>]*>', arguments.string, 0, false))>
			--->
		</cfif>
		
		<!--- Check for code blocks --->
		<cfif findNoCase("<code>",arguments.string) and findNoCase("</code>",arguments.string)>
			<cfset counter = findNoCase("<code>",arguments.string)>
			<cfloop condition="counter gte 1">
                <cfset codeblock = reFindNoCase("(?s)(.*)(<code>)(.*)(</code>)(.*)",arguments.string,1,1)>
				<cfif arrayLen(codeblock.len) gte 6>
                    <cfset codeportion = mid(arguments.string, codeblock.pos[4], codeblock.len[4])>
                    <cfif len(trim(codeportion))>
						<cfif arguments.printformat>
							<cfset result = "<br/><pre class='codePrint'>#trim(htmlEditFormat(codeportion))#</pre><br/>">
						<cfelse>
							<!--- Invoke ColdFish (ga) --->
							<cfset result = variables.codeRenderer.formatString(trim(codeportion))>
							<!--- Note: Delmore's code formatter is not mobile friendly and it does not use responsive design. This table will constrain the content to a certain variable size (GA). --->
							<cfset result = "<div class='code'><table class='constrainerTable constrainContent'><tr><td>#result#</td></tr></table></div>">
						</cfif>
					<cfelse>
						<cfset result = "">
					</cfif>
					<cfset newbody = mid(arguments.string, 1, codeblock.len[2]) & result & mid(arguments.string,codeblock.pos[6],codeblock.len[6])>

                    <cfset arguments.string = newbody>
					<cfset counter = findNoCase("<code>",arguments.string,counter)>
				<cfelse>
					<!--- bad crap, maybe <code> and no ender, or maybe </code><code> --->
					<cfset counter = 0>
				</cfif>
			</cfloop>
		</cfif><!---<cfif findNoCase("<code>",arguments.string) and findNoCase("</code>",arguments.string)>--->
						
		<cfif findNoCase("<attachScript",arguments.string) and findNoCase("</attachScript>",arguments.string)>
		<!--- Gregory's code. I need to allow users to include script tags in the blog entry. My current provider, Hostek, has 'enable global script protection' turned on creating an invalidTag response when submitting code that includes scripts. The following code injects the script tags if the user entered in the folllowing tag: <attachScript> </attachScript>. You can also use <attachScript type="deferjs"> to defer the script. --->
			<cfset arguments.string = replaceNoCase(arguments.string, "attachScript", "script", "all")>	
		</cfif>
			
		<!--- Grrgory's code. Fix the invalidTag issue. This occurs on hostek servers (they have a setting not to allow scripts to be submitted via a form) --->
		<cfif findNoCase("InvalidTag",arguments.string)>
			<cfset arguments.string = replaceNoCase(arguments.string, "InvalidTag", "script", "all")>
		</cfif>
			
		<!--- Don't put in paragraphs if the style sheet was attached (Gregory's logic.) --->
		<cfif findNoCase("<style>",arguments.string) and findNoCase("</style>",arguments.string)>
			<cfset arguments.ignoreParagraphFormat = true>
		</cfif>

		<!--- call our render funcs (fancy logic by Ray (comment by GA)) --->
		<cfloop item="cfc" collection="#variables.renderMethods#">
			<cfinvoke component="#variables.renderMethods[cfc].cfc#" method="renderDisplay" argumentCollection="#arguments#" returnVariable="newstring" />
			<cfset arguments.string = newstring>
		</cfloop>

		<!--- New enclosure support. If enclose if a jpg, png, or gif, put it on top, aligned left (added webp support (GA). --->
		<cfif len(arguments.enclosure) and listFindNoCase("gif,jpg,png,webp", listLast(arguments.enclosure, "."))>
			<cfset rootURL = replace(instance.blogURL, "index.cfm", "")>
			<cfset imgURL = "#rootURL#enclosures/#urlEncodedFormat(getFileFromPath(enclosure))#">
			<!--- Gregory renamed the autoImage div to entryImage. I did not see any autoImage classes elsewhere and want the name to be related to a blog post. I am also lazy loading this now and constraining the image with .css. Note: I am decoding the image URL as it won't work with the lazy loading approach if it is encoded. --->
			<cfset arguments.string = "<div class=""entryImage""><img class=""fade"" data-src=""#urlDecode(imgURL)#"" alt=""""></div>" & arguments.string>
		<!--- bmeloche - 06/13/2008 - Adding podcast support. --->
		<cfelseif len(arguments.enclosure) and listFindNoCase("mp3", listLast(arguments.enclosure, "."))>
			<cfset rootURL = replace(instance.blogURL, "index.cfm", "")>
			<cfset imgURL = "#rootURL#enclosures/#urlEncodedFormat(getFileFromPath(enclosure))#">
			<cfset arguments.string = "<div id=""#urlEncodedFormat(getFileFromPath(enclosure))#""></div>" & arguments.string>
		</cfif>

		<!--- textblock support --->
		<cfset tbRegex = "<textblock[[:space:]]+label[[:space:]]*=[[:space:]]*""(.*?)"">">
		<cfif reFindNoCase(tbRegex,arguments.string)>
			<cfset counter = reFindNoCase(tbRegex,arguments.string)>
			<cfloop condition="counter gte 1">
				<cfset textblock = reFindNoCase(tbRegex,arguments.string,1,1)>
				<cfif arrayLen(textblock.pos) is 2>
					<cfset textblockTag = mid(arguments.string, textblock.pos[1], textblock.len[1])>
					<cfset textblockLabel = mid(arguments.string, textblock.pos[2], textblock.len[2])>
					<cfset newContent = variables.textblock.getTextBlockContent(textblockLabel)>
					<cfset arguments.string = replaceNoCase(arguments.string, textblockTag, newContent)>
				</cfif>
				<cfset counter = reFindNoCase(tbRegex,arguments.string, counter)>
			</cfloop>
		</cfif>

		<cfif not arguments.ignoreParagraphFormat>
			<cfset arguments.string = xhtmlParagraphFormat(arguments.string) />
		</cfif>

		<cfreturn arguments.string />
	</cffunction>

	<cffunction name="saveCategory" access="remote" returnType="void" roles="admin" output="false"
				hint="Saves a category.">
		<cfargument name="id" type="uuid" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="alias" type="string" required="true">
		<cfset var oldName = getCategory(arguments.id).categoryname>

		<cflock name="blogcfc.addCategory" type="exclusive" timeout=30>

			<!--- new name? --->
			<cfif oldName neq arguments.name>
				<cfif categoryExists(name="#arguments.name#")>
					<cfset variables.utils.throw("#arguments.name# already exists as a category.")>
				</cfif>
			</cfif>

			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			update	tblblogcategories
			set		categoryname = <cfqueryparam value="#arguments.name#" cfsqltype="cf_sql_varchar" maxlength="50">,
					categoryalias = <cfqueryparam value="#arguments.alias#" cfsqltype="cf_sql_varchar" maxlength="50">
			where	categoryid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfquery>

		</cflock>

	</cffunction>

	<cffunction name="saveComment" access="public" returnType="uuid" output="false"
				hint="Saves a comment.">
		<cfargument name="commentid" type="uuid" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="email" type="string" required="true">
		<cfargument name="website" type="string" required="true">
		<cfargument name="comments" type="string" required="true">
		<cfargument name="subscribe" type="boolean" required="true">
		<cfargument name="moderated" type="boolean" required="true">

		<cfset arguments.comments = htmleditformat(arguments.comments)>
		<cfset arguments.name = left(htmlEditFormat(arguments.name),50)>
		<cfset arguments.email = left(htmlEditFormat(arguments.email),50)>
		<cfset arguments.website = left(htmlEditFormat(arguments.website),255)>


		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		update tblblogcomments
		set name = <cfqueryparam value="#arguments.name#" maxlength="50">,
		email = <cfqueryparam value="#arguments.email#" maxlength="50">,
		website = <cfqueryparam value="#arguments.website#" maxlength="255">,
		<cfif instance.blogDBType is not "ORACLE">
		comment = <cfqueryparam value="#arguments.comments#" cfsqltype="CF_SQL_LONGVARCHAR">,
		<cfelse>
		comments = <cfqueryparam cfsqltype="cf_sql_clob" value="#arguments.comments#">,
		</cfif>
		subscribe =
			   <cfif instance.blogDBType is "MSSQL" or instance.blogDBType is "MSACCESS">
				   <cfqueryparam value="#arguments.subscribe#" cfsqltype="CF_SQL_BIT">
			   <cfelse>
   			   		<!--- convert yes/no to 1 or 0 --->
			   		<cfif arguments.subscribe>
			   			<cfset arguments.subscribe = 1>
			   		<cfelse>
			   			<cfset arguments.subscribe = 0>
			   		</cfif>
				   <cfqueryparam value="#arguments.subscribe#" cfsqltype="CF_SQL_TINYINT">
			   </cfif>,
		moderated=
			<cfif instance.blogDBType is "MSSQL" or instance.blogDBType is "MSACCESS">
				<cfqueryparam value="#arguments.moderated#" cfsqltype="CF_SQL_BIT">
			<cfelse>
				<cfqueryparam value="#arguments.moderated#" cfsqltype="CF_SQL_TINYINT">
			</cfif>
		where	id = <cfqueryparam value="#arguments.commentid#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

		<cfreturn arguments.commentid>
	</cffunction>

	<cffunction name="saveEntry" access="remote" returnType="void" roles="admin" output="false"
				hint="Saves an entry.">
		<cfargument name="id" type="uuid" required="true">
		<cfargument name="title" type="string" required="true">
		<cfargument name="body" type="string" required="true">
		<cfargument name="morebody" type="string" required="false" default="">
		<cfargument name="alias" type="string" required="false" default="">
		<!--- I use "any" so I can default to a blank string --->
		<cfargument name="posted" type="any" required="false" default="">
		<cfargument name="allowcomments" type="boolean" required="false" default="true">
		<cfargument name="enclosure" type="string" required="false" default="">
		<cfargument name="filesize" type="numeric" required="false" default="0">
		<cfargument name="mimetype" type="string" required="false" default="">
		<cfargument name="released" type="boolean" required="false" default="true">
		<cfargument name="relatedPPosts" type="string" required="true" default="">
		<cfargument name="sendemail" type="boolean" required="false" default="true">
		<cfargument name="duration" type="string" required="false" default="">
		<cfargument name="subtitle" type="string" required="false" default="">
		<cfargument name="summary" type="string" required="false" default="">
		<cfargument name="keywords" type="string" required="false" default="">

		<cfset var theURL = "" />
		<cfset var entry = "" />

		<cfif not entryExists(arguments.id)>
			<cfset variables.utils.throw("#arguments.id# does not exist as an entry.")>
		</cfif>

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			update tblblogentries
			set		title = <cfqueryparam value="#arguments.title#" cfsqltype="CF_SQL_CHAR" maxlength="100">,
					<cfif instance.blogDBType is not "ORACLE">
					body = <cfqueryparam value="#arguments.body#" cfsqltype="CF_SQL_LONGVARCHAR">
					<cfelse>
					body = <cfqueryparam value="#arguments.body#" cfsqltype="CF_SQL_CLOB">
					</cfif>
					<cfif len(arguments.morebody)>
						<cfif instance.blogDBType is not "ORACLE">
						,morebody = <cfqueryparam value="#arguments.morebody#" cfsqltype="CF_SQL_LONGVARCHAR">
						<cfelse>
						,morebody = <cfqueryparam value="#arguments.morebody#" cfsqltype="CF_SQL_CLOB">
						</cfif>
					<!--- ME - 04/27/2005 - fix this to overwrite more/ on edit --->
				    <cfelse>
						<cfif instance.blogDBType is not "ORACLE">
     					,morebody = <cfqueryparam null="yes" cfsqltype="CF_SQL_LONGVARCHAR">
						<cfelse>
						,morebody = <cfqueryparam null="yes" cfsqltype="CF_SQL_CLOB">
						</cfif>
					</cfif>
					<cfif len(arguments.alias)>
						,alias = <cfqueryparam value="#arguments.alias#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
					</cfif>
					<cfif (len(trim(arguments.posted)) gt 0) and isDate(arguments.posted)>
						,posted = <cfqueryparam value="#arguments.posted#" cfsqltype="CF_SQL_TIMESTAMP">
					</cfif>
				    <cfif instance.blogDBType is not "MYSQL" AND instance.blogDBType is not "ORACLE">
					,allowcomments = <cfqueryparam value="#arguments.allowcomments#" cfsqltype="CF_SQL_BIT">
			   		<cfelse>
				   		<!--- convert yes/no to 1 or 0 --->
				   		<cfif arguments.allowcomments>
				   			<cfset arguments.allowcomments = 1>
				   		<cfelse>
				   			<cfset arguments.allowcomments = 0>
				   		</cfif>
						,allowcomments = <cfqueryparam value="#arguments.allowcomments#" cfsqltype="CF_SQL_TINYINT">
			   		</cfif>
			   		,enclosure = <cfqueryparam value="#arguments.enclosure#" cfsqltype="CF_SQL_CHAR" maxlength="255">
					,summary = <cfqueryparam value="#arguments.summary#" cfsqltype="CF_SQL_VARCHAR" maxlength="255">
					,subtitle = <cfqueryparam value="#arguments.subtitle#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
					,keywords = <cfqueryparam value="#arguments.keywords#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
					,duration = <cfqueryparam value="#arguments.duration#" cfsqltype="CF_SQL_VARCHAR" maxlength="10">
	  				,filesize = <cfqueryparam value="#arguments.filesize#" cfsqltype="CF_SQL_NUMERIC">
   					,mimetype = <cfqueryparam value="#arguments.mimetype#" cfsqltype="CF_SQL_VARCHAR" maxlength="255">
   					<cfif instance.blogDBType is not "MYSQL" AND instance.blogDBType is not "ORACLE">
					,released = <cfqueryparam value="#arguments.released#" cfsqltype="CF_SQL_BIT">
			   		<cfelse>
				   		<!--- convert yes/no to 1 or 0 --->
				   		<cfif arguments.released>
				   			<cfset arguments.released = 1>
				   		<cfelse>
				   			<cfset arguments.released = 0>
				   		</cfif>
						,released = <cfqueryparam value="#arguments.released#" cfsqltype="CF_SQL_TINYINT">
			   		</cfif>

			where	id = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and		blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
		</cfquery>

		<cfset saveRelatedEntries(arguments.ID, arguments.relatedpposts) />

		<!---// get the entry //--->
		<cfset entry = getEntry(arguments.id, true) />

		<!---// update the link cache //--->
		<cfset cacheLink(entryid=arguments.id, alias=entry.alias, posted=entry.posted) />

		<cfif arguments.released>

			<cfif arguments.sendEmail>
				<cfif dateCompare(dateAdd("h", instance.offset, entry.posted), blogNow()) is 1>
					<!--- Handle delayed posting --->
					<cfset theURL = getRootURL()>
					<cfset theURL = theURL & "admin/notify.cfm?id=#id#">
					<cfschedule action="update" task="BlogCFC Notifier #id#" operation="HTTPRequest"
								startDate="#entry.posted#" startTime="#entry.posted#" url="#theURL#" interval="once">
				<cfelse>
					<cfset mailEntry(arguments.id)>
				</cfif>
			</cfif>

			<cfif dateCompare(dateAdd("h", instance.offset, entry.posted), blogNow()) is not 1>
				<cfset variables.ping.pingAggregators(instance.pingurls, instance.blogtitle, instance.blogurl)>
			</cfif>

		</cfif>

	</cffunction>

	<cffunction name="saveRelatedEntries" access="public" returntype="void" roles="admin" output="false"
		hint="I add/update related blog entries">
		<cfargument name="ID" type="UUID" required="true" />
		<cfargument name="relatedpposts" type="string" required="true" />

		<cfset var ppost = "" />

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			delete from
				tblblogentriesrelated
			where
				entryid = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
		</cfquery>

		<cfloop list="#arguments.relatedpposts#" index="ppost">
			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				insert into
					tblblogentriesrelated(
						entryid,
						relatedid
					) values (
						<cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">,
						<cfqueryparam value="#ppost#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
					)
			</cfquery>
		</cfloop>

	</cffunction>

	<cffunction name="saveUser" access="public" returnType="void" output="false"
				hint="Saves a user.">
		<cfargument name="username" type="string" required="true">
		<cfargument name="name" type="string" required="true">
		<cfargument name="password" type="string" required="false">
		<cfset var salt = generateSalt()>
		
		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		update	tblusers
		set		name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.name#" maxlength="50">
				<!--- RBB 1/17/11: if no password is passed in, we can assume that only the user's name is being updated --->
				<cfif structKeyExists(arguments, "password")>
					<!--- RBB 1/17/11: generate new salt. I like to do this whenever a password is changed --->
					
					,password = <cfqueryparam value="#hash(salt & arguments.password, instance.hashalgorithm)#" cfsqltype="cf_sql_varchar" maxlength="256">,
					salt = <cfqueryparam value="#salt#" cfsqltype="cf_sql_varchar" maxlength="256">
				</cfif>
		where	username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
		and		blog = <cfqueryparam cfsqltype="cf_sql_varchar" value="#instance.name#" maxlength="50">
		</cfquery>

	</cffunction>

	<cffunction name="setCodeRenderer" access="public" returnType="void" output="false" hint="Injector for coldfish">
		<cfargument name="renderer" type="any" required="true">
		<cfset variables.coderenderer = arguments.renderer>
	</cffunction>

	<cffunction name="setProperty" access="public" returnType="void" output="false"><!--- roles="admin"--->
		<cfargument name="property" type="string" required="true">
		<cfargument name="value" type="string" required="true">

		<cfset instance[arguments.property] = arguments.value>
		<cfset setProfileString(variables.cfgFile, instance.name, arguments.property, arguments.value)>

	</cffunction>

	<cffunction name="setModeratedComment" access="public" returnType="void" output="false" roles="admin" 
				hint="Sets a comment to approved">
		<cfargument name="id" type="string" required="true">

		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			update tblblogcomments set moderated=1 where id=<cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar">
		</cfquery>

	</cffunction>

	<cffunction name="setUserBlogRoles" access="public" returnType="void" output="false" roles="admin" 
				hint="Sets a user's blog roles">
		<cfargument name="username" type="string" required="true" />
		<cfargument name="roles" type="string" required="true" />
			
		<cfset var r = "" />
		<!--- first, nuke old roles --->
		<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		delete from tbluserroles
		where username = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
		and blog = <cfqueryparam cfsqltype="cf_sql_varchar" value="#instance.name#" maxlength="50">
		</cfquery>

		<cfloop index="r" list="#arguments.roles#">
			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			insert into tbluserroles(username, roleidfk, blog)
			values(
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#r#" maxlength="35">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#instance.name#" maxlength="50">
			)
			</cfquery>
		</cfloop>

	</cffunction>

	<cffunction name="unsubscribeThread" access="public" returnType="boolean" output="false"
				hint="Removes a user from a thread.">
		<cfargument name="commentID" type="UUID" required="true" />
		<cfargument name="email" type="string" required="true" />
		
		<cfset var verifySubscribe = "" />

		<!--- First ensure that the commentID equals the email --->
		<cfquery name="verifySubscribe" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			select	entryidfk
			from	tblblogcomments
			where	id = <cfqueryparam value="#arguments.commentID#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
			and		email = <cfqueryparam value="#arguments.email#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
		</cfquery>

		<!--- If we have a result, then set subscribe=0 for this user for ALL comments in the thread --->
		<cfif verifySubscribe.recordCount>

			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
				update	tblblogcomments
				set		subscribe = 0
				where	entryidfk = <cfqueryparam value="#verifySubscribe.entryidfk#"
									cfsqltype="CF_SQL_VARCHAR" maxlength="35">
				and		email = <cfqueryparam value="#arguments.email#" cfsqltype="CF_SQL_VARCHAR" maxlength="100">
			</cfquery>

			<cfreturn true />
		</cfif>

		<cfreturn false />
	</cffunction>

	<cffunction name="updatePassword" access="public" returnType="boolean" output="false"
				hint="Updates the current user's password.">
		<cfargument name="oldpassword" type="string" required="true" />
		<cfargument name="newpassword" type="string" required="true" />
		
		<cfset var checkit = "" />
		<cfset var salt = generateSalt()>

		<cfquery name="checkit" datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
		select	password, salt
		from	tblusers
		where	username = <cfqueryparam value="#getAuthUser()#" cfsqltype="cf_sql_varchar" maxlength="50">
		<!---
		and		password = <cfqueryparam value="#arguments.oldpassword#" cfsqltype="cf_sql_varchar" maxlength="255">
		--->		
		and		blog = <cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="50">
		</cfquery>

		<cfif checkit.recordCount is 1 AND checkit.password is hash(checkit.salt & arguments.oldpassword, instance.hashalgorithm)>
			<!--- generate a new salt --->
			
			<cfquery datasource="#instance.dsn#" username="#instance.username#" password="#instance.password#">
			update	tblusers
			set		password = <cfqueryparam value="#hash(salt & arguments.newpassword, instance.hashalgorithm)#" cfsqltype="cf_sql_varchar" maxlength="256">,
					salt = <cfqueryparam value="#salt#" cfsqltype="cf_sql_varchar" maxlength="256">
			where	username = <cfqueryparam value="#getAuthUser()#" cfsqltype="cf_sql_varchar" maxlength="50">
			and		blog = <cfqueryparam value="#instance.name#" cfsqltype="cf_sql_varchar" maxlength="50">
			</cfquery>
			<cfreturn true />			
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>

	<cffunction name="XHTMLParagraphFormat" returntype="string" output="false">
		<cfargument name="strTextBlock" required="true" type="string" />
		<cfreturn REReplace("<p>" & arguments.strTextBlock & "</p>", "\r+\n\r+\n", "</p><p>", "ALL") />
	</cffunction>
	
	<cffunction name="generateSalt" returnType="string" output="false" access="public" hint="I generate salt for use in hashing user passwords">
		
		<cfreturn generateSecretKey(instance.saltAlgorithm, instance.saltKeySize)>
	</cffunction>
	
	<!--- 
	*****************************************************************************************************************************************************************
	***************************************************************************************************************************************************************** 
	Gregory Alexanders code. I tried breaking this out into my own cfc, but I got lost in the weeds. I could not get the init function working. I'll try again in version 2?
	*****************************************************************************************************************************************************************  
	***************************************************************************************************************************************************************** 
	--->
	
	<!--- Gregory Alexander Helper functions
	Note: Session variables do not work on this component as there is another application.cfm (or application.cfc) that overrides the base applications application.cfm (or cfc) in the same directory. Here, Raymond has another application.cfm in the org/cambden/blog folder that prevents this component from having access to the session variables. 
	I tried to get session variables to work here, but this attempt was in vain. After finding eliminating the 'other' application.cfm template which causesd problems accessing the session scope, it caused new problems. The isUserInRole function is now erroring out with an '
	You have attempted to dereference a scalar variable of type class java.lang.String as a structure with members.' error when consuming the 'getIt' query. The problem is found in this line:
	<cfif not isUserInRole("admin")>
	I suspect that the /blogCfc/org/delmore/coldfishconfig.xml file is not working now. I will vary my approach and instead of using this blog.cfc component, I will  use a proxy controller found in /blogCfc/common/proxy/controller.cfm template. The proxy controller will be used to call this component to perform serverside logic via ajax posts. This component will be used for database operations that don't involve client side logic. See further notes there.
	--->
	
	<!---Functions for pod controls on the index.cfm template.--->
	
	<!--- Gregory's adaption of Raymond's getActiveDays function. This returns a query object of all of the days with a blog post and it is used for the Kendo calendar.--->
	<cffunction name="getAllActiveDates" returnType="query" output="false" hint="Returns query object of all of the posted dates. This will be used for the new Kendo calendar control.">
		
		<cfquery datasource="#instance.dsn#" name="data" username="#instance.username#" password="#instance.password#">
			select distinct
				posted 
			from tblblogentries
			where
				0=0
				and blog = <cfqueryparam value="#instance.name#" cfsqltype="CF_SQL_VARCHAR" maxlength="50">
				and	released = 1
		</cfquery>

		<!---Return the query object.--->
		<cfreturn data>

	</cffunction>
	
	<!---Utility functions--->
	
	<!--- Dan's getWebPath function (blog.pengoworks.com)
	What makes this function unique is that Dan found a way to use the getPageContext().getRequest().getRequestURI() in order to get the absolute URL to the document. I don't want to append a http or a https on an ajax post as it is brittle. Dan's function allows me to get the absolute page without the server prefix and host name.--->
	<cffunction name="getWebPath" access="public" output="false" returntype="string" hint="Gets the absolute path to the current web folder.">
		<cfargument name="url" required="false" default="#getPageContext().getRequest().getRequestURI()#" hint="Defaults to the current path_info" />
		<cfargument name="ext" required="false" default="\.(cfml?.*|html?.*|[^.]+)" hint="Define the regex to find the extension. The default will work in most cases, unless you have really funky urls like: /folder/file.cfm/extra.path/info" />
		<!---// trim the path to be safe //--->
		<cfset var sPath = trim(arguments.url) />
		<!---// find the where the filename starts (should be the last wherever the last period (".") is) //--->
		<cfset var sEndDir = reFind("/[^/]+#arguments.ext#$", sPath) />
		<cfreturn left(sPath, sEndDir) />
	</cffunction>

</cfcomponent>
