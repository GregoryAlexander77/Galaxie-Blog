<cfcomponent displayName="Blog" output="no" hint="BlogCFC by Raymond Camden">

	<!--- Load utils immidiately. --->
	<cfset variables.utils = createObject("component", "utils")> 
	<!--- Include the UDF (Raymond's code) --->
	<cfinclude template="../../../includes/udf.cfm">
	<!--- Roles --->
	<cfset variables.roles = structNew()>
		
	<!---//**************************************************************************************************************************************************
		Common ORM Db objects to get various blog settings.
	//***************************************************************************************************************************************************--->
		
	<!--- Load the Blog Db object (there is only one record in this version) --->
	<cfset application.BlogDbObj = entityLoadByPK("Blog", 1)>
	<!--- Load the BlogOptions Db Object (there is only one record in this version) --->
	<cfset application.BlogOptionDbObj = entityLoadByPK("BlogOption", 1)>
		
	<!---//**************************************************************************************************************************************************
		Version
	//***************************************************************************************************************************************************--->
		
	<!--- Current blog version (This is hardcoded, for now...) --->
	<cfset version = "1.50" />
	<cfset versionDate =  "November 22 2019"> 

	<!--- Require version 9 or higher as we are using ORM --->
	<cfset majorVersion = listFirst(server.coldfusion.productversion)>
	<cfset minorVersion = listGetAt(server.coldfusion.productversion,2,".,")>
	<cfset cfversion = majorVersion & "." & minorVersion>
	<cfif (server.coldfusion.productname is "ColdFusion Server" and cfversion lte 9)>
		<cfset variables.utils.throw("Blog must be run under ColdFusion 9 or higher.")>
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
			<cfset instance.ownerEmail = application.BlogDbObj.getBlogEmail()>
			<cfset instance.blogURL = application.BlogDbObj.getBlogUrl()>
			<!--- New settings on admin page. --->
			<cfset instance.parentSiteName = application.BlogDbObj.getBlogParentSiteName()>
			<cfset instance.parentSiteLink = application.BlogDbObj.getBlogParentSiteUrl()>	
			<cfset instance.blogFontSize = application.BlogDbObj.getBlogFontSize()>
			<!---End new settings block--->
			<cfset instance.blogTitle = application.BlogDbObj.getBlogTitle()>
			<cfset instance.blogDescription = application.BlogDbObj.getBlogDescription()>
			<cfset instance.blogDBType = application.BlogDbObj.getBlogDatabaseType()>
			<cfset instance.locale = application.BlogDbObj.getBlogLocale()>
			<!--- I am depracating this (GA). --->
			<cfset instance.commentsFrom = "">
			<cfset instance.failTo = application.BlogDbObj.getBlogEmailFailToAddress()>
			<cfset instance.mailServer = application.BlogDbObj.getBlogMailServer()>
			<cfset instance.mailusername = application.BlogDbObj.getBlogMailServerUserName()>
			<cfset instance.mailpassword = application.BlogDbObj.getBlogMailServerPassword()>
			<!--- Depracated. --->
			<cfset instance.pingurls = "">
			<cfset instance.offset = application.BlogDbObj.getBlogServerTimeZoneOffset()>
			<!--- Depracated. --->
			<cfset instance.trackbackspamlist = "">
			<cfset instance.blogkeywords = application.BlogDbObj.getBlogMetaKeywords()>
			<cfset instance.ipblocklist = application.BlogDbObj.getIpBlockList()>
			<cfset instance.maxentries = application.BlogDbObj.getEntriesPerBlogPage()>
			<cfset instance.moderate = application.BlogDbObj.getBlogModerated()>
			<cfset instance.usecaptcha = application.BlogDbObj.getUseCaptcha()>
			<cfset instance.usecfp = false>
			<cfset instance.allowgravatars = application.BlogDbObj.getAllowGravatar()>
			<!--- Always use file browse --->
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

		<!--- 
		Only real validation we do on instance data (RC)
		Gregory added another check to bypass the error throw if the blog is not installed. 
		--->
		<cfif not isValidDBType(instance.blogDBType) and instance.installed gt 0>
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
					
	<!---//**************************************************************************************************************************************************
		Helper functions
	//***************************************************************************************************************************************************--->
					
	<!--- Get the server offset value. This is used when the server is not in the same time zone as the user. --->
	<cffunction name="getOffsetTime" access="remote" output="false">
		<cfargument name="serverTimeZoneOffset" type="numeric" required="true">
		<cfargument name="date" type="date" required="true">

		<!---Add or subtract the date with the server time zone offset value.--->
		<cfset dateWithServerTimeOffset = dateAdd( "h", arguments.serverTimeZoneOffset, arguments.date )>

		<!--- Return it. --->
		<cfreturn dateWithServerTimeOffset>

	</cffunction>
			
	<!--- Since we're using ORM, some of the joins will not pull up any records for a given table if there are no records, such as the media (images and video for example). When this occurs, the values in the ORM array of structures will be undefined, and you can't use them without an error being raised. This function will check to see if the value is undefined, and set the value appropriately. If the value is undefined, it will set it to an empty string, otherwise, the value will be the actual value comming form the ORM array of structures.  --->
	<cffunction name="setStructValue" access="remote" output="false">
		<cfargument name="stucture" type="numeric" required="true">
		<cfargument name="key" type="date" required="true">
		
		<cfif structKeyExists(arguments.structure, arguments.key)>
				<cfset structValue = arguments.structure.arguments.key>
			<cfelse>
				<cfset structValue = "">
			</cfif>
			
		<!--- Return it. --->
		<cfreturn structValue>

	</cffunction>
				

	<cffunction name="addCategory" access="remote" returnType="uuid" roles="admin,AddCategory,ManageCategory" output="true"
				hint="Adds a category.">
		<cfargument name="name" type="string" required="true">
		<cfargument name="alias" type="string" required="true">

		<cfset var checkC = "">
		<cfset var id = createUUID()>

		<cfif categoryExists(name="#arguments.name#")>
			<cfset variables.utils.throw("#arguments.name# already exists as a category.")>
		</cfif>
			
		<transaction>
			<!--- Load the blog table and get the first record (there only should be one record). This will pass back an object with the value of the blogId. --->
			<cfset BlogRef = entityLoadByPK("Blog", 1)>
			<!--- Load the entity. --->
			<cfset CategoryDbObj = entityNew("Category")>
			<!--- Use the entity objects to set the data. --->
			<cfset CategoryDbObj.setBlogRef(blogRef)>
			<cfset CategoryDbObj.setCategoryUuid(id)>
			<cfset CategoryDbObj.setCategoryAlias(arguments.alias)>
			<cfset CategoryDbObj.setCategory(arguments.name)>
			<cfset CategoryDbObj.setDate(now())>

			<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't have to use entity save after the Entity has been loaded and saved. --->
			<cfset EntitySave(CategoryDbObj)>
		</transaction>

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
		<cfargument name="user" type="string" required="false" default="">
		<cfargument name="ipAddress" type="string" required="false" default="">
		<cfargument name="httpUserAgent" type="string" required="false" default="">
		<cfargument name="subscribe" type="boolean" required="true">
		<cfargument name="subscribeonly" type="boolean" required="false" default="false">
		<cfargument name="overridemoderation" type="boolean" required="false" default="false">
			
		<!---//**************************************************************************************************************************************************
			Prepare the arguments
		//***************************************************************************************************************************************************--->

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
					
		<!--- convert yes/no to 1 or 0 --->
		<cfif arguments.subscribe>
			<cfset arguments.subscribe = 1>
		<cfelse>
			<cfset arguments.subscribe = 0>
		</cfif>
			
		<!--- Has the comment been approved? --->
		<cfif instance.moderate and not arguments.overridemoderation>
			<cfset approved = 0>
		<cfelse>
			<cfset approved = 1>
		</cfif>	
		
		<!--- Wrap the db code with a transaction tag. --->
		<transaction>
			
			<!---//**************************************************************************************************************************************************
				Save the user or commenter
			//***************************************************************************************************************************************************--->
			
			<!--- Is the user logged in and defined? --->
			<cfif arguments.user neq "">
				
				<!--- Load the users object. There should always be a user record when the user is logged in.--->
				<cfset UserRefDbObj = entityLoad("Users", { UserName = arguments.user }, "true" )>
					
				<cfif isDefined("UserRefDbObj")>
					<!--- Save the ip address and user agent --->
					<cfset UserRefDbObj.setIpAddress(arguments.ipAddress)>
					<cfset UserRefDbObj.setHttpUserAgent(arguments.httpUserAgent)>
					<cfset UserRefDbObj.setDate(now())>
					<!--- Save the entity --->
					<cfset EntitySave(UserRefDbObj)>
						
					<!--- Capture the IP address and save it into the IpAddress table. We will capture all IP addresses for comments in order to build a more secure moderation system.--->	
					<!--- Create a new IpAddress identity --->
					<cfset IpAddressDbObj = entityNew("IpAddress")>
					<!--- Save the user id, ip address and user agent --->
					<cfset IpAddressDbObj.setUserRef(UserRefDbObj)>
					<cfset IpAddressDbObj.setIpAddress(arguments.ipAddress)>
					<cfset IpAddressDbObj.setHttpUserAgent(arguments.httpUserAgent)>
					<cfset IpAddressDbObj.setDate(now())>
					<!--- Save the entity --->
					<cfset EntitySave(IpAddressDbObj)>
				</cfif><!---<cfif isDefined("UserRefDbObj")>--->
				
			<cfelse><!---<cfif arguments.user neq "">--->
				
				<!--- Try to load the commenter object to see if the commenter already exists. --->
				<cfset CommenterRefDbObj = entityLoad("Commenter", { Email = arguments.email }, "true" )>
				<!--- If the commenter was not found, create a new commenter object. --->
				<cfif not isDefined("CommenterRefDbObj")>
					<cfset CommenterRefDbObj = entityNew("Commenter")>
				</cfif>
					
				<!--- Save the fullname, email, website, ip address and user agent --->
				<cfset CommenterRefDbObj.setFullName(arguments.name)>
				<cfset CommenterRefDbObj.setEmail(arguments.email)>
				<cfset CommenterRefDbObj.setWebsite(arguments.website)>
				<cfset CommenterRefDbObj.setIpAddress(arguments.ipAddress)>
				<cfset CommenterRefDbObj.setHttpUserAgent(arguments.httpUserAgent)>
				<cfset CommenterRefDbObj.setDate(now())>
				<!--- Save the entity --->
				<cfset EntitySave(CommenterRefDbObj)>

				<!--- Capture the IP address and save it into the IpAddress table. We will capture all IP addresses for comments in order to build a more secure moderation system.--->	
				<!--- Create a new IpAddress identity --->
				<cfset IpAddressDbObj = entityNew("IpAddress")>
				<!--- Save the user id, ip address and user agent --->
				<cfset IpAddressDbObj.setCommenterRef(CommenterRefDbObj)>
				<cfset IpAddressDbObj.setIpAddress(arguments.ipAddress)>
				<cfset IpAddressDbObj.setHttpUserAgent(arguments.httpUserAgent)>
				<cfset IpAddressDbObj.setDate(now())>
				<!--- Save the entity --->
				<cfset EntitySave(IpAddressDbObj)>
	
			</cfif><!---<cfif arguments.user neq "">--->
			
			<!---//**************************************************************************************************************************************************
				Save the comment
			//***************************************************************************************************************************************************--->
			
			<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key and for some odd reason ColdFusion or Hybernate must have an object passed as a reference instead of a hardcoded value. --->
			<cfset BlogRefDbObj = entityLoadByPK("Blog", 1)>
			<!--- Get the post ref --->
			<cfset PostRefDbObj = entityLoad("Post", { PostUuid = arguments.entryId }, "true" )>
			<!--- Load the commenter ref. It may have not been loaded in the prior code block if the commenter was inserted. --->
			<cfset CommenterRefDbObj = entityLoad("Commenter", { Email = arguments.email }, "true" )>

			<!--- Create a new entity. --->
			<cfset CommentDbObj = entityNew("Comment")>
			<!--- Use the entity objects to set the data. --->
			<cfset CommentDbObj.setBlogRef(BlogRefDbObj)>
			<cfset CommentDbObj.setPostRef(PostRefDbObj)>
			<cfif isDefined("UserRefDbObj")>
				<!--- Set the user ref. The UserRef is only defined when the administrator is logged in. --->
				<cfset CommentDbObj.setUserRef(UserRefDbObj)>
			<cfelse>
				<!---Set the commenter ref--->
				<cfset CommentDbObj.setCommenterRef(CommenterRefDbObj)>
			</cfif>
			<cfset CommentDbObj.setComment(arguments.comments)>
			<!--- ParentCommentRef is null right now. I will not use it in this version. --->
			<cfset CommentDbObj.setCommentUuid(newID)>
			<cfset CommentDbObj.setComment(arguments.comments)>
			<cfset CommentDbObj.setDatePosted(blogNow())>
			<cfset CommentDbObj.setSubscribe(arguments.subscribe)>
			<cfset CommentDbObj.setApproved(approved)>
			<cfset CommentDbObj.setPromote(0)>	
			<cfset CommentDbObj.setHide(0)>		
			<!--- KillComment in BlogCfc is a UUID for some odd reason. I'm going to set this to false. --->
			<cfset CommentDbObj.setRemove(false)>	
			<cfset CommentDbObj.setDate(now())>

			<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't have to use entity save after the Entity has been loaded and saved. --->
			<cfset EntitySave(CommentDbObj)>
				
		</transaction>

		<!---//**************************************************************************************************************************************************
			If the commenter unsubscribes from one comment, unsubscribe the commenter from all comments in this particular post.
		//***************************************************************************************************************************************************--->
		<cfif not arguments.subscribe>
			<transaction>
				<!--- Load the comment table with the commenters email address. --->
				<cfset CommenterRefDbObj = entityLoad("Commenter", { Email = arguments.email }, "true" )>
				<!--- If the commenter was found, load the comment object with the current post --->
				<cfif isNumeric("CommenterRefDbObj.getCommenterId()")>
					<!--- Load the post --->
					<cfset PostRefDbObj = entityLoad("Post", { PostUuid = arguments.entryId }, "true" )>
					<!--- ... and unsubscribe them --->
					<cfquery name="Data" dbtype="hql">
						UPDATE Comment
						SET 
							Subscribe = false
						WHERE 
							PostRef = <cfqueryparam value="#PostRefDbObj.getPostId()#" cfsqltype="cf_sql_int">
							AND CommenterRef = <cfqueryparam value="#CommenterRefDbObj.getCommenterId()#" cfsqltype="cf_sql_int">
					</cfquery>
				</cfif>
			</transaction>	
		</cfif><!---<cfif not arguments.subscribe>--->

		<cfreturn newID>
	</cffunction>

	<cffunction name="addEntry" access="remote" returnType="uuid" output="true"
				hint="Adds an entry."><!---roles="admin"---> 
		<cfargument name="title" type="string" required="true">
		<cfargument name="body" type="string" required="true">
		<cfargument name="morebody" type="string" required="false" default="">
		<cfargument name="alias" type="string" required="false" default="">
		<!--- Note: blogNow() is a function that either adds or substracts the server time offset. The author may have a different time than the timestamp as the server might be in a different time zone. --->
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
			
		<!---//**************************************************************************************************************************************************
			Set values
		//***************************************************************************************************************************************************--->

		<cfset var id = createUUID()>
		<cfset var theURL = "">
			
		<!--- Convert a Yes/No into a boolean --->
		<cfif arguments.allowcomments>
			<cfset arguments.allowcomments = 1>
		<cfelse>
			<cfset arguments.allowcomments = 0>
		</cfif>
		
		<!--- Convert a Yes/No into a boolean --->
		<cfif arguments.released>
			<cfset arguments.released = 1>
		<cfelse>
			<cfset arguments.released = 0>
		</cfif>
			
		<!--- Send an email when the post is released the posted date is not in the future. --->
		<cfif arguments.sendEmail and arguments.released and dateCompare(dateAdd("h", instance.offset, arguments.posted), blogNow()) lte 0>
			<cfset sendEmail = true>
		<cfelse>
			<cfset sendEmail = false>
		</cfif>
			
		<!---//**************************************************************************************************************************************************
			Insert the post
		//***************************************************************************************************************************************************--->
		
		<!--- Use a transaction --->
		<cftransaction>
			<!--- Load the blog table and get the first record (there only should be one record at this time). This will pass back an object with the value of the blogId. This is needed as the setBlogRef is a foreign key. ColdFusion and Hibernate must have an object passed as a reference instead of a hardcoded value. --->
			<cfset BlogRefObj = entityLoadByPK("Blog", 1)>
			<!--- Get the user by the username in the Users Obj. --->
			<cfset UserRefObj = entityLoad("Users", { UserName = getAuthUser() }, "true" )>

			<!--- Create a new entity. --->
			<cfset PostDbObj = entityNew("Post")>
			<!--- Use the entity objects to set the data. --->
			<cfset PostDbObj.setBlogRef(BlogRefObj)>
			<cfset PostDbObj.setUserRef(UserRefObj)>
			<cfset PostDbObj.setPostUuid(id)>
			<cfset PostDbObj.setPostAlias(arguments.alias)>
			<cfset PostDbObj.setTitle(#arguments.title#)>
			<!--- Not yet in use: <cfset PostDbObj.setHeadline(summary)>--->
			<cfset PostDbObj.setBody(arguments.body)>
			<cfset PostDbObj.setMoreBody(arguments.morebody)>
			<cfset PostDbObj.setNumViews(0)>
			<cfset PostDbObj.setAllowComment(arguments.allowcomments)>
			<cfset PostDbObj.setMailed(sendEmail)>
			<cfset PostDbObj.setReleased(arguments.released)>	
			<cfset PostDbObj.setDatePosted(arguments.posted)>	
			<cfset PostDbObj.setDate(now())>
			<!--- Save it. --->
			<cfset EntitySave(PostDbObj)>
		</cftransaction>
				
		<!--- **********************************************************************************************
			Populate the Media table. 
		*************************************************************************************************--->
			
		<!--- Save the enclosures into the new media table. --->
		<cfif len(arguments.enclosure) gt 0>
			<!--- Use a transaction --->
			<cftransaction>			
			
				<!--- Get the post record by the PostUuid --->
				<cfset PostRef = entityLoad("Post", { PostUuid = id }, "true" )>
				<!--- Get the mime type --->
				<cfset MimeTypeRefObj = entityLoad("MimeType", { MimeType = arguments.mimetype }, "true" )>

				<!---Instantiate the media obj--->
				<cfset MediaDbObj = entityNew("Media")>
				<!--- The only four pieces of information available are the PostRef, MimeTypeRef, enclosure, and file size in the tblBlogEntries table. --->
				<cfset MediaDbObj.setPostRef(PostRef)>
				<cfset MediaDbObj.setMimeTypeRef(MimeTypeRefObj)>
				<cfset MediaDbObj.setMediaPath(arguments.enclosure)>
				<cfset MediaDbObj.setMediaSize(arguments.filesize)>
				<!--- Save it. --->
				<cfset EntitySave(MediaDbObj)>
		
			</cftransaction>
		</cfif>
						
		<!--- **********************************************************************************************
			Post operations
		*************************************************************************************************--->
		
		<!--- Send out the email --->
		<cfif sendEmail>
			<cfset mailEntry(id)>
		</cfif>

		<!--- Create the related categories. --->
		<cfif len(trim(arguments.relatedEntries)) GT 0>
			<!---<cfset saveRelatedEntries(id, arguments.relatedEntries) />--->
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
		<cfset var Data = "">

		<!--- First, lets see if this guy is already subscribed. --->
		<cfquery name="Data" dbtype="hql">
			SELECT 
				SubscriberEmail
			FROM Subscriber
			WHERE 
				SubscriberEmail = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar" maxlength="50">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<cfif arrayLen(Data) eq 0>
			
			<transaction>
				
				<!--- Create a new entity. --->
				<cfset SubscriberDbObj = entityNew("Subscriber")>
				<!--- Use the entity objects to set the data. --->
				<cfset SubscriberDbObj.setBlogRef(application.BlogDbObj)>
				<!---The postRef should be left blank.It's not an option in BlogCfc.--->
				<cfset SubscriberDbObj.setSubscriberEmail(email)>
				<cfset SubscriberDbObj.setSubscriberToken(token)>
				<!---The user has not yet been verified. The verification process is done in the administrative section--->
				<cfset SubscriberDbObj.setSubscriberVerified(false)>
				<!--- In BlogCfc, all subscribers subsribe to everything. --->
				<cfset SubscriberDbObj.setSubscribeAll(1)>	
				<cfset SubscriberDbObj.setDate(now())>

				<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't have to use entity save after the Entity has been loaded and saved. --->
				<cfset EntitySave(SubscriberDbObj)>
			</transaction>
					
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
			
			<cfquery name="Data" dbtype="hql">
				SELECT 
					UserName
				FROM Users
				WHERE 
					UserName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#" maxlength="50">
					AND BlogRef = #application.BlogDbObj.getBlogId()#
			</cfquery>

			<cfif arrayLen(Data) gt 0>
				<cfset variables.utils.throw("#arguments.name# already exists as a user.")>
			<cfelse><!---<cfif arrayLen(Data) gt 0>--->
				<!--- Wrap the ORM code with a transaction. --->
				<transaction>
					<!--- Create a new entity. --->
					<cfset UserDbObj = entityNew("Users")>
					<!--- Use the entity objects to set the data. --->
					<cfset UserDbObj.setBlogRef(blogRef)>
					<cfset UserDbObj.setFirstName("")>
					<cfset UserDbObj.setLastName("")>
					<cfset UserDbObj.setFullName(arguments.name)>	
					<cfset UserDbObj.setEmail(blogEmail)>
					<cfset UserDbObj.setUserName(arguments.username)>
					<cfset UserDbObj.setPassword(#hash(salt & arguments.password, instance.hashalgorithm)#)>
					<cfset UserDbObj.setSalt(salt)>
					<cfset UserDbObj.setActive(true)>
					<cfset UserDbObj.setDate(now())>
					<!--- Save it --->
					<cfset EntitySave(UserDbObj)>
				</transaction>
			</cfif><!---<cfif arrayLen(Data) gt 0>--->

		</cflock>

	</cffunction>

	<cffunction name="approveComment" access="public" returnType="void" output="false"
				hint="Approves a comment.">
		<cfargument name="commentid" type="uuid" required="true">
			
		<!--- Load the comment entity. --->
		<cfset CommentDbObj = entityLoad("Comment", { CommentUuid = arguments.commentid }, "true" )>
		<!--- Use the entity objects to set the data. --->
		<cfset CommentDbObj.setApproved(1)>
		<cfset CommentDbObj.setDate(now())>

		<!--- Save it. --->
		<cfset EntitySave(CommentDbObj)>

	</cffunction>


	<cffunction name="assignCategory" access="remote" returnType="void" roles="admin,ReleaseEntries" output="false"
				hint="Assigns entry ID to category X">
		<cfargument name="entryid" type="uuid" required="true">
		<cfargument name="categoryid" type="uuid" required="true">
		<cfset var Data = "">
			
		<!--- Get the Category Id  --->
		<cfset CategoryRefObj = entityLoad("Category", { CategoryUuid = arguments.categoryid }, "true" )>
		<!--- Get the Post Id--->
		<cfset PostRefObj = entityLoad("Post", { PostUuid = arguments.entryid }, "true" )>
		
		<!--- Are both of our objects defined? The entityLoad function will only create an object if the filters match existing records. --->
		<cfif isDefined("CategoryRefObj") and isDefined("PostRefObj")>
			<!--- Load the entity. --->
			<cfset PostCategoryObj = entityNew("PostCategoryLookup")>
			<!--- Use the entity objects to set the data. --->
			<cfset PostCategoryObj.setCategoryRef(CategoryRefObj)>
			<cfset PostCategoryObj.setPostRef(PostRefObj)>
			<cfset PostCategoryObj.setDate(now())>

			<!--- Save it. Note: updates will automatically occur on persisted objects if the object notices any change. We don't have to use entity save after the Entity has been loaded and saved. --->
			<cfset EntitySave(PostCategoryObj)>
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
			
		<!--- Load the users table using the username supplied by the user. --->
		<cfset UsersDbObj = entityLoad("Users", { UserName = arguments.username }, "true" )>
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				UserName as UserName,
				Password as Password,
				Salt as Salt
			)
			FROM Users
			WHERE 
				UserName = <cfqueryparam value="#arguments.username#" cfsqltype="cf_sql_varchar" maxlength="35">
		</cfquery>
		
		<!--- If the user name was found, see if the user passed in the proper credentials. --->
		<cfif arrayLen(Data)>
			<cfif (Data[1].Password is hash(Data[1].Salt & arguments.password, instance.hashalgorithm))>
				<cfset authenticated = true>
			</cfif>

			<cfif isDefined("cookie.cftokens")>
				<cfif (cookie.cftokens is hash(Data[1].Salt & Data[1].Password, instance.hashalgorithm))>
					<cfset authenticated = true>
				</cfif>
			</cfif>
		</cfif><!---<cfif arrayLen(Data)>--->

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

	<cffunction name="confirmSubscription" access="public" returnType="void" output="false"
				hint="Confirms a user's subscription to the blog.">
		<cfargument name="token" type="uuid" required="false">
		<cfargument name="email" type="string" required="false">
			
				<!--- Load the entity. --->
		<cfset SubscriberDbObj = entityLoad("Subscriber")>
		<!--- Use the entity objects to set the data. --->
		<cfset SubscriberDbObj.setBlogRef(BlogRef)>
		<!---The postRef should be left blank.It's not an option in BlogCfc.--->
		<cfset SubscriberDbObj.setSubscriberEmail(email)>
		<cfset SubscriberDbObj.setSubscriberToken(token)>
		<cfset SubscriberDbObj.setSubscriberVerified(verified)>
		<!--- In BlogCfc, all subscribers subsribe to everything. --->
		<cfset SubscriberDbObj.setSubscribeAll(1)>	
		<cfset SubscriberDbObj.setDate(now())>
			
		<cfquery name="Data" dbtype="hql">
			UPDATE Subscriber 
			SET
				SubscriberVerified = 1 
			FROM Category
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
	
	<!---Gregory's function. I need to use this on the subscription interface on via the new subscription pod that I wrote. I need to rewrite this as I need to it return information. The current implementation is used on a different page and it fails when the token does not match the UUID in the database. I don't want the index page to always fail as I am writing a SPA application, and need better error handling. However, the previous function which this is based on it used in the admin areas, and I don't want to screw that side up, so here is my new function.--->
	<cffunction name="confirmSubscriptionViaToken" access="public" returnType="boolean" output="false"
				hint="Confirms a user's subscription to the blog via the subscription pod.">
		<cfargument name="token" type="uuid" required="true">
			
		<cfparam name="subscribed" default="false" type="boolean">

		<cfif isValid("UUID", arguments.token)> 
			<cfquery name="Data" dbtype="hql">
				SELECT 
					SubscriberEmail
				FROM
					Subscriber
				WHERE 
					SubscriberVerified = 1 
					AND SubscriberToken = <cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfquery>

			<cfif arrayLen(Data) eq 0>
				<cfquery name="Data" dbtype="hql">
					UPDATE	Subscriber
					SET		SubscriberVerified = 1
					WHERE	SubscriberToken = <cfqueryparam value="#arguments.token#" cfsqltype="cf_sql_varchar" maxlength="35">
				</cfquery>
				<cfset subscribed = true>
			</cfif><!---<cfif arrayLen(Data) eq 0>--->
		</cfif><!---<cfif isValid("UUID", arguments.token)>--->
		<cfreturn subscribed>
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

	</cffunction>

	<cffunction name="deleteComment" access="public" returnType="void" roles="admin,ReleaseEntries" output="false"
				hint="Deletes a comment based on the comment's uuid.">
		<cfargument name="id" type="uuid" required="true">
			
		<!--- Load the Category entity by the CategoryUuid --->
		<cfset CommentDbObj = entityLoad("Comment", { CommentUuid = arguments.id }, "true" )>
		<!--- Delete this record --->
		<cfset EntityDelete(CommentDbObj)>
		<!--- And delete the variable to ensure that the record is deleted from ORM memory. --->
		<cfset void = structDelete( variables, "CommentDbObj" )>

	</cffunction>

	<cffunction name="deleteEntry" access="remote" returnType="void" roles="admin,ReleaseEntries" output="false"
				hint="Deletes an entry, plus all comments.">
		<cfargument name="id" type="uuid" required="true">
		<cfset var entry = "">
		<cfset var enclosure = "">

		<cfif entryExists(arguments.id)>

			<!--- Load the Post entity by the PostUuid in order to delete them --->
			<cfset PostDbObj = entityLoad("Post", { PostUuid = arguments.id }, "true" )>
				
			<!--- Get the various images and videos for this post. --->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					MediaPath as MediaPath
				)
				FROM Media 
				WHERE 
					PostRef = #PostDbObj.getPostId()#
			</cfquery>
				
			<!--- Loop through the array and delete the various media --->
			<cfloop from="1" to="#arrayLen(Data)#" index="i">
				<cfif fileExists(Data[i].MediaPath)>
					<cffile action="delete" file="#Data[i].MediaPath#">
				</cfif>
			</cfloop>
				
			<!--- Load the Post entity by the PostUuid --->
			<cfset PostDbObj = entityLoad("Post", { PostUuid = arguments.id }, "true" )>
			
			<!--- Delete the post --->
			<cfquery name="Data" dbtype="hql">
				DELETE FROM Post
				WHERE 
					PostUuid = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
					AND BlogRef = #application.BlogDbObj.getBlogId()#
			</cfquery>

			<!--- Delete the associated post categories --->
			<cfquery name="Data" dbtype="hql">
				DELETE FROM PostCategoryLookup
				WHERE 
					PostRef = #PostDbObj.getPostId()#
			</cfquery>

			<!--- And delete the comments. --->
			<cfquery name="Data" dbtype="hql">
				DELETE FROM Comment
				WHERE 
					PostRef = #PostDbObj.getPostId()#
			</cfquery>
				
			<!--- Delete the PostDbObj variable to ensure that the record doesn't stick around and is deleted from ORM memory. --->
			<cfset void = structDelete( variables, "PostDbObj" )>
			<!--- Delete the Data variable to ensure that the record doesn't stick around and is deleted from ORM memory. --->
			<cfset void = structDelete( variables, "Data" )>

		</cfif>

	</cffunction>

	<cffunction name="deleteUser" access="public" returnType="void" output="false" hint="Deletes a user.">
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

	<cffunction name="entryExists" access="private" returnType="boolean" output="false"
				hint="Returns true or false if an entry exists.">
		<cfargument name="id" type="uuid" required="true">
			
		<cfset var Data = "[]">

		<cfif not structKeyExists(variables, "existsCache")>
			<cfset variables.existsCache = structNew() />
		</cfif>

		<cfif structKeyExists(variables.existsCache, arguments.id)>
			<cfreturn variables.existsCache[arguments.id]>
		</cfif>
			
		<cfquery name="Data" dbtype="hql">
			SELECT 
				new Map (PostUuid as PostUuid)
			FROM Post
			WHERE BlogRef = #application.BlogDbObj.getBlogId()#
				AND PostUuid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar" maxlength="35">
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
			<!--- Get the category (GA) --->
			<!--- Note: categories are held in an array. The Category is the 2nd element in the array (GA). --->
			<!--- We need to remove the 'index.cfm' string when a rewrite rule is in place. (GA) --->
			<cfif application.serverRewriteRuleInPlace>
				<cfset xmlLink = xmlFormat(replaceNoCase(xmlFormat(makeLink(id)), '/index.cfm', ''))>
			<cfelse>
				<cfset xmlLink = xmlFormat(makeLink(id))>
			</cfif>
			<cfloop item="catid" collection="#categories#">
				<cfset category = categories[currentRow][catid]>
			</cfloop>
			<cfif listFindNoCase(application.eliminateCategoryListInMainFeed, category) eq 0><!---GA--->
			<cfset dateStr = dateFormat(posted,"yyyy-mm-dd")>
			<cfset dateStr = dateStr & "T" & timeFormat(posted,"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & ":00">
			<cfoutput>
		  	<item rdf:about="#xmlLink#">
			<title>#xmlFormat(title)#</title>
			<description><cfif arguments.mode is "short" and len(REReplaceNoCase(body,"<[^>]*>","","ALL")) gte arguments.excerpt>#xmlFormat(left(REReplaceNoCase(body,"<[^>]*>","","ALL"),arguments.excerpt))#...<cfelse>#xmlFormat(body & morebody)#</cfif></description>
			<link>#xmlLink#</link>
			<dc:date>#dateStr#</dc:date>
			<cfloop item="catid" collection="#categories#">
				<cfset catlist = listAppend(catlist, xmlFormat(categories[currentRow][catid]))>
			</cfloop>
			<dc:subject>#xmlFormat(catlist)#</dc:subject>
			</item>
			</cfoutput>
			</cfif><!---<cfif listFindNoCase(application.eliminateCategoryListInMainFeed, category) eq 0>--->
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
			<!--- Get the category (GA) --->
			<!--- Note: categories are held in an array. The Category is the 2nd element in the array (GA). --->
			<!--- We need to remove the 'index.cfm' string when a rewrite rule is in place. (GA) --->
			<cfif application.serverRewriteRuleInPlace>
				<cfset xmlLink = xmlFormat(replaceNoCase(xmlFormat(makeLink(id)), '/index.cfm', ''))>
			<cfelse>
				<cfset xmlLink = xmlFormat(makeLink(id))>
			</cfif>
			<cfloop item="catid" collection="#categories#">
				<cfset category = categories[currentRow][catid]>
			</cfloop>
			<cfif listFindNoCase(application.eliminateCategoryListInMainFeed, category) eq 0><!---GA--->
			<cfset dateStr = dateFormat(posted,"ddd, dd mmm yyyy") & " " & timeFormat(posted,"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & "00">
			<cfoutput>
			<item>
				<title>#xmlFormat(title)#</title>
				<link>#xmlLink#</link>
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
				<guid>#xmlLink#</guid>
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
			</cfif><!---<cfif listFindNoCase(application.eliminateCategoryListInMainFeed, category) eq 0><!---GA--->--->
		 	</cfloop>
			</cfsavecontent>

			<cfset header = replace(header,'{LAST_BUILD_DATE}','#dateFormat(articles.posted[1],"ddd, dd mmm yyyy") & " " & timeFormat(articles.posted[1],"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & "00"#','one')>
			<cfset rssStr = trim(header & items & "</channel></rss>")>

		</cfif>

		<cfreturn rssStr>

	</cffunction>

	<cffunction name="getActiveDays" returnType="string" output="false" hint="Returns a list of unique days that have at least one post.">
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
				<!--- Note: the query may have duplicate dates if more than one post was made during the day. Since we can't extract and group by the day in HQL (at least I don't know how to do this), I am going to inspect the value and make sure that it is not already in the list before putting it in. --->
				<cfif not daysThatHavePosts contains day(Data[i].DatePosted)>
					<!--- Convert the date into a day and stuff it into the list and append a comma.--->
					<cfset daysThatHavePosts = daysThatHavePosts & day(Data[i].DatePosted) & ",">
				</cfif>
			<cfelse>
				<cfif not daysThatHavePosts contains day(Data[i].DatePosted)>
					<!--- This is the last element in the array. We don't need a comma here. --->
					<cfset daysThatHavePosts = daysThatHavePosts & day(Data[i].DatePosted)>
				</cfif>
			</cfif>
		</cfloop>

		<cfreturn daysThatHavePosts>

	</cffunction>
	
	<cffunction name="getArchives" access="public" returnType="array" output="false" hint="I return a query containing all of the past months/years that have entries along with the entry count">
		<cfargument name="archiveYears" type="numeric" required="false" hint="Number of years back to pull archives for. This helps limit the result set that can be returned" default="0">
		
		<cfset var Data = "[]">	
		<cfset var getMonthlyArchives = "" />
		<cfset var fromYear = year(now()) - arguments.archiveYears />
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				month(DatePosted) as PreviousMonths, 
				year(DatePosted) as PreviousYears, 
				count(PostId) as EntryCount
			)
			FROM Post
			WHERE 0=0
				AND YEAR(DatePosted) >= #fromYear#
				AND BlogRef = #application.BlogDbObj.getBlogId()#
			GROUP BY 
				YEAR(DatePosted), MONTH(DatePosted) 
			ORDER BY 
				PreviousYears desc, PreviousMonths desc				
		</cfquery>
		
		<cfreturn Data>
	</cffunction>

	<cffunction name="getBlogRoles" access="public" returnType="array" output="false">
		<cfset var Data = "[]">

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				RoleUuid as RoleUuid, 
				Role as Role, 
				Description as Description
			)
			FROM Role
		</cfquery>

		<cfreturn Data>
	</cffunction>

	<cffunction name="getCategories" access="remote" returnType="array" output="false" hint="Returns a query containing all of the categories as well as their count for a specified blog.">
		<cfargument name="usecache" type="boolean" required="false" default="true">
		<cfset var Data = "[]">
		<cfset var getTotal = "">

		<!--- Note: caching may no longer be necessary here as the new ORM logic should fix some of the performance issues of the original ad-hoc BlogCfc query. --->
		<cfif structKeyExists(variables, "categoryCache") and arguments.usecache>
			<cfreturn variables.categoryCache>
		</cfif>

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category.CategoryUuid as CategoryUuid,
				Category.Category as Category,
				Category.CategoryAlias as CategoryAlias,
				count(Post.PostId) as EntryCount
			)
			FROM  
				PostCategoryLookup as PostCategoryLookup
				JOIN PostCategoryLookup.CategoryRef as Category
				JOIN PostCategoryLookup.PostRef as Post
			WHERE 
				Released = 1
				AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
				AND Category.BlogRef = #application.BlogDbObj.getBlogId()#
			GROUP BY  
				CategoryUuid, 
				Category.Category, 
				Category.CategoryAlias			
		</cfquery>

		<cfset variables.categoryCache = Data>
		<cfreturn variables.categoryCache>
		
	</cffunction>

	<cffunction name="getCategoriesForEntry" access="remote" returnType="array" output="false" hint="Returns a array containing all of the categories for a specific blog entry.">
		<cfargument name="id" type="uuid" required="true">
		<cfset var Data = "[]">

		<cfif not entryExists(arguments.id)>
			<cfset variables.utils.throw("'#arguments.id#' does not exist.")>
		</cfif>
			
		<!--- Load the post object by the PostUuid. This needs to be done as we don't store the PostUuid in the PostCategoryLookup table and it is still the primary key being passed around as of now.  --->
		<cfset PostRefObj = entityLoad("Post", { PostUuid = #arguments.id# }, "true" )>

		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category.CategoryUuid as CategoryUuid, 
				Category.Category as Category
			)
			FROM 
				PostCategoryLookup as PostCategoryLookup,
				Category as Category
			WHERE 
				PostCategoryLookup.CategoryRef = Category.CategoryId
				AND PostCategoryLookup.PostRef = #PostRefObj.getPostId()#		
		</cfquery>

		<cfreturn Data>

	</cffunction>

	<cffunction name="getCategory" access="remote" returnType="array" output="false" hint="Returns an array containing the category name and alias for a specific blog entry.">
		<cfargument name="id" type="uuid" required="true">
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category as Category, 
				Category.CategoryUuid as CategoryUuid
			)
			FROM Category
			WHERE 
				CategoryUuid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar" maxlength="35">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<cfif not arrayLen(Data)>
			<cfset variables.utils.throw("#arguments.id# is not a valid category.")>
		</cfif>
		
		<cfreturn Data>

	</cffunction>

	<cffunction name="getCategoryByAlias" access="remote" returnType="string" output="false" hint="Returns the Category Uuid for a specific category alias.">
		<cfargument name="alias" type="string" required="true">
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category.CategoryUuid as CategoryUuid
			)
			FROM Category
			WHERE 
				CategoryAlias = <cfqueryparam value="#arguments.alias#" cfsqltype="cf_sql_varchar" maxlength="50">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<!--- Gregory's note: the original hint stated that this would return the category name. I suspect that this function is not used, or the original hint was a mistake. --->
		<cfreturn Data[1].CategoryUuid>

	</cffunction>

	<!--- This method originally written for parseses, but is not used. Keeping it around though. --->
	<cffunction name="getCategoryByName" access="remote" returnType="string" output="false" hint="Returns the category uuid for a specific category name.">
		<cfargument name="name" type="string" required="true">
			
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				Category.CategoryUuid as CategoryUuid
			)
			FROM Category
			WHERE 
				Category = <cfqueryparam value="#arguments.name#" cfsqltype="cf_sql_varchar" maxlength="50">
				AND BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<cfreturn Data[1].CategoryUuid>

	</cffunction>

	<cffunction name="getComment" access="remote" returnType="array" output="false"
				hint="Gets a specific comment by comment ID.">
		<cfargument name="id" type="uuid" required="true">
		
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				<!--- Note: ambiguous columns will not show up in the error message. Instead, you will see an 'org.hibernate.hql.internal.ast.QuerySyntaxException: unexpected token:' error. --->
				Comment.CommentId as CommentId,
				Post.PostId as PostId,
				Post.PostUuid as PostUuid,
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
				LEFT OUTER JOIN Comment.UserRef as User
				LEFT OUTER JOIN Comment.CommenterRef as Commenter
				JOIN Comment.PostRef as Post
			WHERE
				CommentUuid = <cfqueryparam value="#arguments.id#" cfsqltype="CF_SQL_VARCHAR" maxlength="35">
				<!--- This was not present in the original BlogCfc, I added it. There is a very tiny and miniscule chance that a duplicate UUID may be formed and it is an easy line to add. --->
				AND Comment.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<cfreturn Data>

	</cffunction>
	
	<!--- RBB 8/23/2010: Added a new method to get comment count for an entry --->
	<cffunction name="getCommentCount" access="remote" returnType="numeric"  output="false"
				hint="Gets the total number of comments for a blog entry">
		<cfargument name="id" type="uuid" required="true">
			
			<!--- Load the post object by the PostUuid. This needs to be done as we don't store the PostUuid in the PostCategoryLookup table and it is still the primary key being passed around as of now.  --->
			<cfset PostRefObj = entityLoad("Post", { PostUuid = arguments.id }, "true" )>

			<cfquery name="Data" dbtype="hql">
				SELECT 
					count(commentId) as commentCount
				FROM Comment
				WHERE 
					PostRef = #PostRefDbObj.getPostId()#
				<cfif instance.moderate>
					AND Moderated = 1
				</cfif>
					AND Subscribe = 0 OR Subscribe IS NULL
			</cfquery>	
			
			<cfif arrayLen(Data)>
				<cfset commentCount =  Data[1].commentCount>
			<cfelse>
				<cfset commentCount = 0>
			</cfif>
	
		<cfreturn commentCount>
	</cffunction>

	<cffunction name="getComments" access="remote" returnType="array" output="false"
				hint="Gets all comments for an entry ID.">
		<cfargument name="id" type="uuid" required="false">
		<cfargument name="sortdir" type="string" required="false" default="asc">
		<cfargument name="includesubscribers" type="boolean" required="false" default="false">
		<cfargument name="search" type="string" required="false">

		<cfset var getC = "">
		<cfset var getO = "">

		<cfif structKeyExists(arguments, "id") and not entryExists(arguments.id)>
			<cfset variables.utils.throw("'#arguments.id#' does not exist.")>
		</cfif>

		<cfif arguments.sortDir is not "asc" and arguments.sortDir is not "desc">
			<cfset arguments.sortDir = "asc">
		</cfif>
			
		<cfset var Data = "[]">
			
		<cfquery name="Data" dbtype="hql">
			SELECT new Map (
				<!--- Note: ambiguous columns will not show up in the error message. Instead, you will see an 'org.hibernate.hql.internal.ast.QuerySyntaxException: unexpected token:' error. --->
				Comment.CommentId as CommentId,
				Post.PostId as PostId,
				Post.PostUuid as PostUuid,
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
				LEFT OUTER JOIN Comment.UserRef as User
				LEFT OUTER JOIN Comment.CommenterRef as Commenter
				JOIN Comment.PostRef as Post
			WHERE 0 = 0
			<cfif structKeyExists(arguments, "search")>
				AND Comment LIKE <cfqueryparam value="%#arguments.search#%" cfsqltype="cf_sql_varchar">
			</cfif>
			<cfif structKeyExists(arguments, "id")>
				AND CommentUuid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			<cfif instance.moderate>
				AND Moderated = <cfqueryparam value="1" cfsqltype="cf_sql_boolean" maxlength="35">
			</cfif>
			<cfif not arguments.includesubscribers>
				AND Subscribe = 0 OR Subscribe IS NULL
			</cfif>
				<!--- This was not present in the original BlogCfc, I added it. There is a very tiny and miniscule chance that a duplicate UUID may be formed and it is an easy line to add. --->
				AND Comment.BlogRef = #application.BlogDbObj.getBlogId()#
				ORDER BY Comment.DatePosted #arguments.sortdir#
		</cfquery>

		<cfreturn Data>

	</cffunction>

	<!--- Deprecated --->
	<cffunction name="getEntry" access="remote" returnType="struct" output="false"
				hint="Returns one particular entry.">
		<cfargument name="id" type="uuid" required="true">
		<cfargument name="dontlog" type="boolean" required="false" default="false">
		
		<cfset var PostStruct = structNew()>
		<cfset var Data= "[]">
		<cfset var getCategories = "">

		<cfif not entryExists(arguments.id)>
			<cfset variables.utils.throw("'#arguments.id#' does not exist.")>
		</cfif>
			
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
				Post.Headline as Headline,
				Post.Body as Body,
				Post.MoreBody as MoreBody,
				MimeType.MimeType as MimeType,
				Media.MediaTitle as MediaTitle,
				Media.MediaWidth as MediaWidth,
				Media.MediaHeight as MediaHeight,
				Media.MediaPath as MediaPath,
				Media.MediaUrl as MediaUrl,
				Post.AllowComment as AllowComment,
				Post.NumViews as NumViews,
				Post.Mailed as Mailed,
				Post.Released as Released,
				Post.DatePosted as DatePosted)
			FROM Post as Post 
			<!--- UserRef is the actual database foreign key pointing to the Users table. --->
			JOIN Post.UserRef as User
			<!--- Assets is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.Assets as Media
			<!--- MimeTypeRef is the actual database foreign key pointing to the MimeType table. --->
			LEFT JOIN Media.MimeTypeRef as MimeType
			WHERE 
				Post.PostUuid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar" maxlength="35">
				AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
		</cfquery>

		<!--- Build the structure. This structure will be wide, but only have one row of data. --->
		<cfif arrayLen(Data)>
			<cfset postRow = Data[1]>
			<cfset PostStruct["UserId"] = Data[1].UserId>
			<cfset PostStruct["FullName"] = Data[1].FullName>
			<cfset PostStruct["Email"] = Data[1].Email>
			<cfset PostStruct["PostId"] = Data[1].PostId>
			<!--- The theme id may not be present. It's optional. --->
			<cfset PostStruct["ThemeRef"] = setStructValue(Data[1], "ThemeRef")>
			<cfset PostStruct["PostUuid"] = Data[1].PostUuid>
			<cfset PostStruct["PostAlias"] = Data[1].PostAlias>
			<cfset PostStruct["Title"] = Data[1].Title>
			<cfset PostStruct["Headline"] = Data[1].Headline>
			<cfset PostStruct["Body"] = Data[1].Body>
			<cfset PostStruct["MoreBody"] = Data[1].MoreBody>
			<!--- There may not be any media. We need to see if the values are defined before setting them. --->
			<cfif structKeyExists(postRow, "MimeType")>
				<cfset PostStruct["MimeType"] = Data[1].MimeType>
			<cfelse>
				<cfset PostStruct["MimeType"] = "">
			</cfif>
			<cfif structKeyExists(postRow, "MediaTitle")>
				<cfset PostStruct["MediaTitle"] = Data[1].MediaTitle>
			<cfelse>
				<cfset PostStruct["MediaTitle"] = "">
			</cfif>
			<cfif structKeyExists(postRow, "MediaWidth")>
				<cfset PostStruct["MediaWidth"] = Data[1].MediaWidth>
			<cfelse>
				<cfset PostStruct["MediaWidth"] = "">
			</cfif>
			<cfif structKeyExists(postRow, "MediaHeight")>
				<cfset PostStruct["MediaHeight"] = Data[1].MediaHeight>
			<cfelse>
				<cfset PostStruct["MediaHeight"] = "">
			</cfif>
			<cfif structKeyExists(postRow, "MediaPath")>
				<cfset PostStruct["MediaPath"] = Data[1].MediaPath>
			<cfelse>
				<cfset PostStruct["MediaPath"] = "">
			</cfif>
			<cfif structKeyExists(postRow, "MediaUrl")>
				<cfset PostStruct["MediaUrl"] = Data[1].MediaUrl>
			<cfelse>
				<cfset PostStruct["MediaUrl"] = "">
			</cfif>
			<cfset PostStruct["AllowComment"] = Data[1].AllowComment>
			<cfset PostStruct["NumViews"] = Data[1].NumViews>
			<cfset PostStruct["Mailed"] = Data[1].Mailed>
			<cfset PostStruct["Released"] = Data[1].Released>
			<!--- Add or subtract the server time offset (used when the server resides in a different time zone). I'll add better date time localization in another version. --->
			<cfset PostStruct["DatePosted"] = getOffsetTime( instance.offset, Data[1].DatePosted)>
		</cfif>
				
		<!--- Load the post object by the PostUuid. This needs to be done as we don't store the PostUuid in the PostCategoryLookup table and it is still the primary key being passed around as of now.  --->
		<cfset PostRefDbObj = entityLoad("Post", { PostUuid = #arguments.id# }, "true" )>

		<!--- Use the PostRefDbObj to get the categories for the given post.--->
		<cfquery name="getCategories" dbtype="hql">
			SELECT new Map (
				Category.CategoryUuid as CategoryUuid, 
				Category.Category as Category
			)
			FROM 
				PostCategoryLookup as PostCategoryLookup,
				Category as Category
			WHERE 
				PostCategoryLookup.CategoryRef = Category.CategoryId
				<!--- Pass in the PostId --->
				AND PostCategoryLookup.PostRef = #PostRefDbObj.getPostId()#		
		</cfquery>

		<!--- Create a new structure that will hold the post categories. This will hold one or more rows of data. --->
		<cfset PostCategoryStruct = structNew()>
		<cfloop from="1" to="#arrayLen(getCategories)#" index="i">
			<cfset PostStruct.Categories[getCategories[i].CategoryUuid] = getCategories[i].Category>
		</cfloop>

		<!--- Increment our view count by one. --->
		<cfif not arguments.dontlog>
			<!--- We've already loaded the PostDbObj above, now increment the number of views by one and save the entity. --->
			<cfset PostRefDbObj.setNumViews(getPosts[1].NumViews + 1)>
			<cfset PostRefDbObj.setDate(now())>
			<!--- Save it. --->
			<cfset EntitySave(PostRefDbObj)>
		</cfif>

		<!--- Return the PostStruct --->
		<cfreturn PostStruct>

	</cffunction>
		
	<cffunction name="getEntries" access="remote" returnType="array" output="true"
				hint="Returns entries. Allows for a params structure to configure what entries are returned.">
		
		<cfargument name="params" type="struct" required="false" default="#structNew()#">
		<cfargument name="loggedIn" type="string" required="false" default="no" hint="Gregory added this argument to allow the administrators to preview entries that are not released.">
		<cfset var getComments = "">
		<cfset var getCategories = "">
		<cfset var validOrderBy = "posted,title,views">
		<cfset var validOrderByDir = "asc,desc">
		<cfset var validMode = "short,full">
		<cfset var getIds = "">
		<cfset var idList = "">
		<cfset var pageIdList = "">
		<cfset var x = "">
		<cfset var PostStruct = structNew()>

		<!--- **********************************************************************************************
			Set vars
		*************************************************************************************************--->	

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
			<cfset arguments.params.maxEntries = 10>
		</cfif>

		<cfif not structKeyExists(arguments.params,"startRow") or (structKeyExists(arguments.params,"startRow") and not val(arguments.params.startRow))>
			<cfset arguments.params.startRow = 1>
		</cfif>
			
		<!--- **********************************************************************************************
			Get an PossUuid list that match the variables that were sent in.
		*************************************************************************************************--->

		<!--- Note: the original BlogCfc logic used date add functions on the sql column to get the proper date with the server offset values. I am performing operations on the where clause value. I don't quite know how to proceed with the byMonth and byYear right now. Extra values may be present if the author makes a post at 11PM on New Years eve and there is a server offset for example, but this should be quite rare and I can live with this for now until I localize the time values for the blog (in another version). I have marked the columns that need this using a todo. --->
		<cfquery name="getIds" dbtype="hql">
			SELECT new Map (
				Post.PostUuid as PostUuid
			)
			FROM Post as Post 
			<!--- UserRef is the actual database foreign key pointing to the Users table. --->
			JOIN Post.UserRef as User
			<!--- Assets is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.Assets as Media
			<!--- MimeTypeRef is the actual database foreign key pointing to the MimeType table. --->
			LEFT JOIN Media.MimeTypeRef as MimeType
			LEFT JOIN Post.Categories as Category
			WHERE 0=0
			<cfif structKeyExists(arguments.params,"lastXDays")>
				AND Post.DatePosted > <cfqueryparam value="#lastXDaysDate#" cfsqltype="cf_sql_date">
			</cfif>
			<!--- Todo: serverOffset --->
			<cfif structKeyExists(arguments.params,"byDay") and not structKeyExists(arguments.params,"byAlias")>
				AND day(Post.DatePosted) = <cfqueryparam value="#day(arguments.params.byDay)#" cfsqltype="cf_sql_date">
			</cfif>
			<!--- Todo: serverOffset --->
			<cfif structKeyExists(arguments.params,"byMonth")>
				AND month(Post.DatePosted) = <cfqueryparam value="#arguments.params.byMonth#" cfsqltype="cf_sql_numeric">
			</cfif>
			<!--- Todo: serverOffset --->
			<cfif structKeyExists(arguments.params,"byYear")>
				AND year(Post.DatePosted) = <cfqueryparam value="#arguments.params.byYear#" cfsqltype="cf_sql_numeric">
			</cfif>
			<cfif structKeyExists(arguments.params,"byTitle")>
				AND Post.Title = <cfqueryparam value="#arguments.params.byTitle#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<cfif structKeyExists(arguments.params,"byCat")>
				AND Category.CategoryUuid IN (<cfqueryparam value="#arguments.params.byCat#" cfsqltype="cf_sql_varchar" maxlength="35" list=true>)
			</cfif>
			<cfif structKeyExists(arguments.params,"byPosted")>
				AND User.UserName =  <cfqueryparam value="#arguments.params.byPosted#" cfsqltype="cf_sql_varchar" maxlength="50" list=true>
			</cfif>
			<cfif structKeyExists(arguments.params,"searchTerms")>
				<cfif not structKeyExists(arguments.params, "dontlogsearch")>
					<cfset logSearch(arguments.params.searchTerms)>
				</cfif>
				AND (
						Post.Title LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
						OR Post.Body LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
						OR Post.MoreBody LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
					)
			</cfif>
			<cfif structKeyExists(arguments.params,"byEntry")>
				AND Post.PostUuid = <cfqueryparam value="#arguments.params.byEntry#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			<cfif structKeyExists(arguments.params,"byAlias")>
				AND Post.PostAlias = <cfqueryparam value="#left(arguments.params.byAlias,100)#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<cfif not isUserInRole("admin") or (structKeyExists(arguments.params, "releasedonly") and arguments.params.releasedonly)>
				AND Post.DatePosted < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
				<cfif arguments.loggedIn eq 'no'>
					AND Post.Released = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				</cfif>
			</cfif>
			<cfif structKeyExists(arguments.params, "released")>
				AND	Post.Released = <cfqueryparam cfsqltype="cf_sql_bit" value="#arguments.params.released#">
			</cfif>
			AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
			<!---ORDER BY #arguments.params.orderBy# #arguments.params.orderByDir#--->
		</cfquery>	
				
		<!--- **********************************************************************************************
			Populate the list from the query
		*************************************************************************************************--->
			
		<!--- If there are records, convert the array to a list. --->
		<cfset idList = "">
		<cfloop from="1" to="#arrayLen(getIds)#" index="i">
			<cfif i lt arrayLen(getIds)>
				<cfset idList = idList & getIds[i].PostUuid & ",">
			<cfelse>
				<cfset idList = idList & getIds[i].PostUuid>
			</cfif>
		</cfloop>
		
		<!--- Create a pageIdList. This essentially limits the number of records to display. --->
		<cfloop index="x" from="#arguments.params.startRow#" to="#min(arguments.params.startRow+arguments.params.maxEntries-1,arrayLen(getIds))#">
			<cfset pageIdList = listAppend(pageIdList, listGetAt(idlist,x))>
		</cfloop>
			
		<!--- Set the number of records to return. --->
		<cfset numRows = arguments.params.maxEntries + arguments.params.startRow-1>
			
		<!--- **********************************************************************************************
			Get the data needed to populate the structure that we will return.
		*************************************************************************************************--->

		<!--- Get all of the posts --->
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
				Post.Headline as Headline,
				Post.Body as Body,
				Post.MoreBody as MoreBody,
				MimeType.MimeType as MimeType,
				Media.MediaTitle as MediaTitle,
				Media.MediaWidth as MediaWidth,
				Media.MediaHeight as MediaHeight,
				Media.MediaPath as MediaPath,
				Media.MediaUrl as MediaUrl,
				Post.AllowComment as AllowComment,
			<cfif arguments.params.mode is "full">
				Category.CategoryUuid as CategoryUuid,
				Category as Category,
			</cfif>
				Post.NumViews as NumViews,
				Post.Mailed as Mailed,
				Post.Released as Released,
				Post.DatePosted as DatePosted)
			FROM Post as Post 
			<!--- UserRef is the actual database foreign key pointing to the Users table. --->
			JOIN Post.UserRef as User
			<!--- Assets is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.Assets as Media
			<!--- MimeTypeRef is the actual database foreign key pointing to the MimeType table. --->
			LEFT JOIN Media.MimeTypeRef as MimeType
		<cfif arguments.params.mode is "full">
			<!--- Comments is a psuedo column which returns an array of comments. --->
			LEFT JOIN Post.Comments as Comment
			LEFT JOIN Post.Categories as Category
		</cfif>
			WHERE 0=0
				AND Post.PostUuid IN (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#pageIdList#">)
		<cfif arguments.params.mode is "full">
			<cfif instance.moderate>
				AND Comment.Moderated = <cfqueryparam value="1" cfsqltype="cf_sql_bit">
			</cfif>
				AND (Comment.Subscribe = <cfqueryparam value="1" cfsqltype="cf_sql_bit"> or Comment.Subscribe is null)
		</cfif>
			<!---ORDER BY #arguments.params.orderBy# #arguments.params.orderByDir#--->
		</cfquery>
			
		<!--- **********************************************************************************************
			Create the PostStruct structure
		*************************************************************************************************--->
		
		<!--- Create our final structure --->
		<cfif arrayLen(Data)>
			<cfloop from="1" to="#arrayLen(Data)#" index="i">
				
				<!--- Get the number of comments if necessary. --->
				<cfif arguments.params.mode is "full">
					<cfquery name="getCommentCount" dbtype="hql">
						SELECT new Map (
							Comment.CommentId as CommentCount
						FROM Post as Post 
						LEFT JOIN Post.Comments as Comment
						WHERE 0=0
							AND Post.PostUuid IN (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#pageIdList#">)
					</cfquery>
				</cfif>
				
				<!--- Set the values in the structure. --->
				<cfset postRow = Data[i]>
				<cfset PostStruct["UserId"] = Data[i].UserId>
				<cfset PostStruct["FullName"] = Data[i].FullName>
				<cfset PostStruct["Email"] = Data[i].Email>
				<cfset PostStruct["PostId"] = Data[i].PostId>
				<!--- The theme id may not be present. It's optional. --->
				<cfset PostStruct["ThemeRef"] = setStructValue(Data[i], "ThemeRef")>
				<cfset PostStruct["PostUuid"] = Data[i].PostUuid>
				<cfset PostStruct["PostAlias"] = Data[i].PostAlias>
				<cfset PostStruct["Title"] = Data[i].Title>
				<cfset PostStruct["Headline"] = Data[i].Headline>
				<cfset PostStruct["Body"] = Data[i].Body>
				<cfset PostStruct["MoreBody"] = Data[i].MoreBody>
				<!--- There may not be any media. We need to see if the values are defined before setting them. --->
				<cfset PostStruct["MimeType"] = setStructValue(Data[i], "MimeType")>
				<cfset PostStruct["MediaTitle"] = setStructValue(Data[i], "MediaTitle")>
				<cfset PostStruct["MediaWidth"] = setStructValue(Data[i], "MediaWidth")>
				<cfset PostStruct["MediaHeight"] = setStructValue(Data[i], "MediaHeight")>
				<cfset PostStruct["MediaPath"] = setStructValue(Data[i], "MediaPath")>
				<cfset PostStruct["MediaUrl"] = setStructValue(Data[i], "MediaUrl")>
				<!--- This value is present. --->
				<cfset PostStruct["AllowComment"] = Data[i].AllowComment>
			<cfif arguments.params.mode is "full">
				<!--- Get the comment count from the getCommentCount query array. --->
				<cfset PostStruct["CommentCount"] = arrayLen(getCommentCount)>
				<cfset PostStruct["CategoryUuid"] = setStructValue(Data[i], "CategoryUuid")>
				<cfset PostStruct["Category"] = setStructValue(Data[i], "Category")>
			</cfif>
				<!--- These values are present. --->
				<cfset PostStruct["NumViews"] = Data[i].NumViews>
				<cfset PostStruct["Mailed"] = Data[i].Mailed>
				<cfset PostStruct["Released"] = Data[i].Released>
				<!--- Add or subtract the server time offset (used when the server resides in a different time zone). I'll add better date time localization in another version. --->
				<cfset PostStruct["DatePosted"] = getOffsetTime( instance.offset, Data[i].DatePosted)>
				<cfset PostStruct.totalEntries = arrayLen(Data)>
			</cfloop>
			
		</cfif>

		<!--- Return the structure. --->
		<cfreturn getIds><!---PostStruct--->

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
			<cfset variables.utils.throw("'#arguments.id#' does not exist.")>
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
							<!---Invoke ColdFish (GA)--->
							<cftry>
								<cfset result = variables.codeRenderer.formatString(trim(codeportion))>
								<!--- Note: Delmore's code formatter is not mobile friendly and it does not use responsive design. This table will constrain the content to a certain variable size (GA). --->
								<cfset result = "<div class='code'><table class='constrainerTable constrainContent'><tr><td>#result#</td></tr></table></div>">
								<cfcatch type="any">
									<!--- Some devices, like iPad Air don't support Java and error out. --->
									<br/><pre class='codePrint'>#trim(htmlEditFormat(codeportion))#</pre><br/> 
								</cfcatch>
							</cftry>
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
			
		<!--- Grrgory's code. Fix the invalidTag issue. This generally is a substitution of 'invaligTag' when a script tag is use, but it could be caused with a meta tag too. This occurs on hostek servers (they have a setting not to allow scripts to be submitted via a form) --->
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

		<!--- New enclosure support. If enclose if a jpg, png, or gif, put it on top, aligned left (added webp support (GA). Note: this needs to be recoded using a database. --->
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
			<cfset variables.utils.throw("'#arguments.id#' does not exist as an entry.")>
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
			
	<cffunction name="getImageInfo" access="public" output="false" returntype="struct" hint="Provides information about an image using the built in ColdFusion cfimage function.">
    	<cfargument name="imageUrl" type="string" required="yes" hint="provide the full path to the image.">
		
	
		<cfimage 
			action = "info"
			source = "#arguments.imageUrl#"
			structname="imageInfo"> 
		
		<!--- Return the structure. --->
		<cfreturn imageInfo>
		
	</cffunction>
			
	<cffunction name="getImageOrientation" access="public" output="false" returntype="string" hint="Returns a string which will be either landscape or portrait.">
		<cfargument name="imageUrl" type="string" required="yes" hint="provide the full path to the image.">

		<cfimage 
			action = "info"
			source = "#arguments.imageUrl#"
			structname="imageInfo"> 

		<cfif imageInfo.width gt imageInfo.height>
			<cfset orientation = "landscape">
		<cfelseif imageInfo.width lt imageInfo.height>
			<cfset orientation = "portrait">
		<cfelse>
			<cfset orientation = "portrait">
		</cfif>

		<!--- Return the orientation. --->
		<cfreturn orientation>

	</cffunction>
			
	

</cfcomponent>
