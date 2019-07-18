<cfcomponent displayName="ProxyController" output="no" hint="The proxy between the client and the backend blog cfc.">
<!--- 
	*****************************************************************************************************************************************************************
	***************************************************************************************************************************************************************** 
	Gregory Alexanders code. I tried breaking this out into my own cfc, but I got lost in the weeds. I could not get the init function working. I'll try again in version 2?
	Author: Gregory Alexander
	Date: November 11 2018.
	Purpose: Raymond's approach was typical in the mid 2000's. He posted a form to a .cfm page, and the server processed server side logic as well as perorming client side operations, like setting form values on the client. However, Ajax is a different beast. Most of our Kendo HTML5 interfaces do not post to another HTML page. Instead, the UI elements, such as the Kendo window, posts limited data to a function that has to perform all of the logic without refreshing the client page. However, for several reasons, the blog.cfc component does not have all of the information that I need to do this successfully.
	First, we can't get session vars in the main blog.cfc. Raymond (and et-al) had another application.cfm in the org/cambden/blog folder that prevented this component from having access to the session variables set on the /blogCfc/application.cfm template. Cfc's should have access to the session scope unless it finds another application.cfm (or cfc) template, and here, this is the case.
	This poses some problems with ajax. I do not want to have to hard code authentication variables, like the isAdmin, in a javascript ajax post. This is quite insecure.
	I tried in vain to get the blog.cfc component to work for my purposes. After finding and eliminating the 'other' application.cfm template which caused problems accessing the session scope, I was able to obtain session variables, but the elimation of the application.cfm template in the same directory caused new problems. One example is that the isUserInRole function is now erroring out with an '
	You have attempted to dereference a scalar variable of type class java.lang.String as a structure with members.'. This new error was raised throughout the blog.cfc template.
	Another issue is that I suspect that the /blogCfc/org/delmore/coldfishconfig.xml file is not working when the application.cfm template is disabled. This file most likely deals with the cfauthentication tag. 
	In order to have the session scope, and in order to potentially cache the code after an ajax operation, I am using this template as a proxy. I am not using a .cfc component as I need to perform client side operations, such as setting form values, and caching the output of the page. 
	Goals: This template will use Raymond's blog.cfc to perform all database operations. Whenever possible, I will perform server side business logic using Raymonds Blog.cfc.
	*****************************************************************************************************************************************************************  
	***************************************************************************************************************************************************************** 
--->

	<!--- Notes: this template has access to the isLoggedIn() function and other session vars. 
	I intend to use this template like I would using a .cfc. I am going to grab the method URL to invoke the proper function in this page. This is uneccessary if we use a .cfc. --->
	
	<!--- Common libraries. --->
	<!--- Include the resource bundle. --->
	<cfset getResourceBundle = application.utils.getResource>
	<!--- Include the UDF --->
	<cfinclude template="../../includes/udf.cfm">

	
	<!---*****************************************************************************************************************************************  
	Security tokens and keys.
	***************************************************************************************************************************************** --->
	
	<!---******************  Functions to create a random phrase and a key ******************--->
	<cffunction name="createEncryptionPhrase" access="package" returntype="string" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page.">
		<!--- Use the rand function to create a new phrase. --->
		<!--- Local vars --->
		<cfset var result="">
		<cfset var i=0>

		<!--- Create string --->
		<cfloop index="i" from="1" to="15">
			<!--- Random character in range A-Z --->
			<cfset result=result&Chr(randRange(65, 90))>
		</cfloop>
		<!---Return it.--->
		<cfreturn result>

	</cffunction>
			
	<!---What is the key prase used to encrypt and decode the key with?--->
	<cffunction name="getEncryptionPhrase" access="package" returntype="string" hint="Sets our key prase to use in encryption. This is a private function only available to other functions on this page.">
		<cfset encryptionPhrase = application.blog.getProperty("encryptionPhrase")>
		<cfreturn encryptionPhrase>
	</cffunction>

	<cffunction name="createEncryptionKey" access="package" returntype="string" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page.">
		<!--- Generate a secret key. --->
		<cfset encryptionKey = generateSecretKey( "AES" ) />
		<cfreturn encryptionKey>
	</cffunction>
	
	<!--- Generate the 'serviceKey'. This is the encrypted key that is created using the random phrase and the encryption key. I am calling this a 'service key' in order to obsfucate the logic as it is used on the client side. --->
	<cffunction name="createTokenKeys" access="remote" returntype="struct" hint="Generates and saves our service key that is a comination of a phrase and an encryptionKey. Returns the encryption and service keys back to the client as a structure. This should be the only 'key' related security function that is accessible to the client without having to pass in a 'serviceKey'.">

		<!--- Create a random encryption phrase. --->
		<cfset encryptionPhrase = getEncryptionPhrase()>
		<!--- Create a random key (this creates a new key every  single time it is invoked). We are going to store this in a session cookie. --->
		<cfset encryptionKey = createEncryptionKey()>
		<!--- Use the encryption phrase and new key to create the 'serviceKey'. This also will be stored in a session cookie. --->
		<cfset serviceKey = encrypt(encryptionPhrase, encryptionKey,  "AES", "UU") />	

		<!--- Return the keys back to the client. We don't want to return any other keys to the client side for security. --->
		<cfset tokenKeys = {encryptionKey=#encryptionKey#,serviceKey=#serviceKey#}>
		<!---Retrun the struct.--->

		<cfreturn tokenKeys>

	</cffunction>

	<cffunction name="decryptServiceKey" access="package" returntype="string" hint="Decrypts the encrypted key sent by the client. This is a private function only available to other functions on this page.">
		
		<cfargument name="encryptionKey" required="yes" hint="Pass in the encryptionKey. The 'encryptionKey' a key provided using ColdFusion's generateSecretKey function.">
		<cfargument name="serviceKey" required="yes" hint="Pass in the serviceKey. This is the encrypted key that is created using the random phrase and the encryption key. I am calling this a 'service key' in order to obsfucate the logic as it is used on the client side.">
		
		<!--- Get the secret encryption phrase. --->
		<cfinvoke component="#this#" method="getEncryptionPhrase" returnvariable="encryptionPhrase" />

		<!--- The decrypt function takes the service key (which is generated using a key phrase) and an ecyrption key created by the generateSecretKey native ColdFusion method. Once decoded, it should match the 'encryption phrase'. --->
		<cfset decodedServiceKey = decrypt(arguments.serviceKey, arguments.encryptionKey, "AES", "UU") />

		<!--- Return it. It should match the encryption phrase.--->
		<cfreturn decodedServiceKey>

	</cffunction>

	<cffunction name="isClientKeyAuthorized" access="remote" returntype="boolean" hint="Compares the decoded client key and see if it matches the encryptionPhrase. If it does, the client is authorized.">
		
		<cfargument name="encryptionKey" required="yes" hint="The 'encryptionKey' is generated using the generateSecretKey ColdFusion method.">
		<cfargument name="serviceKey" required="yes" hint="The 'serviceKey' is a key created by the combination of a key phrase and an encyption key.">

		<!--- Decode the client key. --->
		<cfinvoke component="#this#" method="decryptServiceKey" returnvariable="decodedClientKey">
			<cfinvokeargument name="encryptionKey" value="#arguments.encryptionKey#">
			<cfinvokeargument name="serviceKey" value="#arguments.serviceKey#">
		</cfinvoke>

		<!---Determine if the client key and the keyPhrase match. IF the keys match, the client is authorized.--->
		<cfif decodedClientKey eq encryptionPhrase>
			<cfset isAuth = true>
		<cfelse>
			<cfset isAuth = false>
		</cfif>

		<cfreturn isAuth>

	</cffunction>
	
	<!---*****************************************************************************************************************************************  
	UI Specific functions
	***************************************************************************************************************************************** --->

	<!--- Include needed cfc's
	Include a reference to the resourceBundle for localization. --->
	<cfset rb = application.utils.getResource>
		
	<!--- UI related functions for display and themes --->
	<!--- Save the users theme preference. --->
	<cffunction name="getTheme" access="remote" returntype="stuct" hint="Allows the users to change the blogs theme.">
		<cfargument name="theme" type="string" required="no" default="">
		
		<cfif theme neq ''>

		<!--- Get the selected value --->
		<cfset kendoTheme = Form.selectedTheme>
		<!--- Determine the method to use (update or insert). --->
		<cfif getUiPreference.recordcount gt 0>
			<cfset UiPreferenceMethod = 'updateUiPreference'>
		<cfelse><!--- <cfif getUiPreference.recordcount gt 0> --->
			<cfset UiPreferenceMethod = 'insertUiPreference'>
		</cfif><!--- <cfif getUiPreference.recordcount gt 0> --->

		<!--- TODO Version 1 Save the record into the database. --->
		<cfif uiPreferenceMethod eq 'updateUiPreference'>
			<cfquery name="updateUiPreference" datasource="#dsn#">
				UPDATE dbo.UiPreference
				SET UserRef = <cfqueryparam value="#getUserId()#" cfsqltype="cf_sql_integer">,
				ApplicationId = <cfqueryparam value="#applicationId#" cfsqltype="cf_sql_integer">,
				PreferenceName = <cfqueryparam value="kendoTheme" cfsqltype="cf_sql_varchar">,
				PreferenceValue = <cfqueryparam value="#kendoTheme#" cfsqltype="cf_sql_varchar">
				WHERE UserRef = <cfqueryparam value="#getUserId()#" cfsqltype="cf_sql_integer">
				AND ApplicationId = <cfqueryparam value="#applicationId#" cfsqltype="cf_sql_integer">
			</cfquery>
		<cfelse><!--- <cfif uiPreferenceMethod eq 'updateUiPreference'> --->
			<!--- Insert the record into the database. --->
			<cfinvoke component="#UiPreferenceObj#" method="#UiPreferenceMethod#" returnvariable="UiPreferenceId">
				<cfinvokeargument name="UserRef" value="#getUserId()#">
				<cfinvokeargument name="ApplicationId" value="#applicationId#">
				<cfinvokeargument name="PreferenceName" value="kendoTheme">
				<cfinvokeargument name="PreferenceValue" value="#kendoTheme#">
			</cfinvoke>
		</cfif><!--- <cfif uiPreferenceMethod eq 'updateUiPreference'> --->
		</cfif><!--- <cfif isDefined("Form.selectedTheme")> --->
	</cffunction>
				
	<!--- Function to get the search results --->
	<cffunction name="getSiteSearchResults" access="remote" returnformat="json" hint="Consumed by the search near the top of the page. ">
		<cfargument name="searchTerm" type="string" required="yes" default="">
		<cfargument name="category" type="string" required="no" default="">
		<cfargument name="startRow" type="numeric" required="no" default="">
		<cfargument name="endRow" type="numeric" required="no" default="">

		<cfif searchTerm neq ''>

			<!--- Break down search parameters --->
			<cfset params = structNew()>
			<cfset params.searchTerms = arguments.searchTerm>
			<cfif arguments.category is not "">
				<cfset params.byCat = arguments.category>
			</cfif>

			<cfset params.startrow = arguments.startRow>
			<cfset params.maxEntries = application.maxEntries>
			<!--- Only get released items --->
			<cfset params.releasedonly = true />

		    <!---  Do the search. --->
			<cfif len(arguments.searchTerm) or arguments.category is not "">
				<cfset data = application.blog.getEntries(params)>
				<cfset searched = true>
			<cfelse>
				<cfset searched = false>
			</cfif>

			
			<cfinvoke component="cfJson" method="convertCfQuery2JsonStruct" returnvariable="jsonString" >
				<cfinvokeargument name="queryObj" value="#data.entries#">
				<cfinvokeargument name="contentType" value="json">
				<cfinvokeargument name="includeTotal" value="false">
				<!--- Don't include the data handle for dropdown menu's ---> 
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
				<!--- Force the column names into lower case. The code writer for the grid converts the case into lCase. --->
				<cfinvokeargument name="convertColumnNamesToLowerCase" value="false">
			</cfinvoke>

			 <cfreturn jsonString>

		</cfif>

	</cffunction>

	<!--- Data to draw the batches for deletion ui interface on the post page. This needs to be dynamic as the batches for deletion are always subject to change.  --->
	<cffunction name="getCaptchaAsJson" access="remote" returnformat="json" output="false" hint="Returns a json object to populate the captcha UI in the addComment and addCommentSub templates. This is used to populate a kendo.observable model (a Kendo UI MVVM framework) on the page.">

		<!--- There are no arguments for this function. --->
		<cfsetting enablecfoutputonly="true" />
		<!--- Create the needed variables from Raymond's blog cfc--->
		<cfset variables.captcha = application.captcha.createHashReference() />
		<!--- Create a two column query, specifying the column data types --->
		<cfset data = queryNew("captchaImageUrl, captchaHashReference", "VarChar, VarChar")> 
		<!--- Add one row. --->
		<cfset newRow = queryAddRow(data, 1)>
		<!--- Populate the image URL--->
		<cfset temp = querySetCell(data, "captchaImageUrl", application.blog.getRootURL() & "showCaptcha.cfm?hashReference=" & variables.captcha.hash, 1)> 
		<!--- Populate the hash reference. --->
		<cfset temp = querySetCell(data, "captchaHashReference", variables.captcha.hash, 1)> 

		<!--- Package the data. --->
		<cfinvoke component="cfJson" method="convertCfQuery2JsonStruct" returnvariable="jsonString" >
			<cfinvokeargument name="queryObj" value="#data#">
			<cfinvokeargument name="contentType" value="json">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- Don't include the data handle for dropdown menu's ---> 
			<cfinvokeargument name="includeDataHandle" value="false">
			<!--- Force the database columns coming from the database into lower case. --->
			<cfinvokeargument name="convertColumnNamesToLowerCase" value="false">
		</cfinvoke>

		<!--- And sent it. --->
		<cfreturn jsonString>

	</cffunction>
	
	<!--- Helper functions for interfaces (addComments, addSub, etc.). Important note on function tags- they must have a returnFormat="json". Otherwise, ColdFusion will return the value wraped in a wddx tag.--->
	<cffunction name="validateCaptcha" access="remote" returnType="boolean" returnFormat="json" output="false" hint="Remote method accessed via ajax. Returns a boolean value to determine if the users entered value matches the captcha image.">
		<cfargument name="captchaText" required="yes" hint="What did the user enter into the form?" />
		<cfargument name="captchaHash" required="yes" hint="The hashed value of the proper answer. This must match the captcha text in order to pass true." />
		<cfargument name="debugging" required="no" type="boolean" default="false" hint="For testing purposes, we may need to not use the session.captchValidated value to prevent a true value from being incorreclty reset." />
		
		<!--- Authorize this request using the security tokens. We don't want anyone trying to hack by programming directly to the proxy cfc. --->
		<cfinvoke component="#this#" method="isClientKeyAuthorized" returnvariable="isAuth">
			<!--- The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
			<cfinvokeargument name="encryptionKey" value="#session.encryptionKey#">
			<cfinvokeargument name="serviceKey" value="#session.serviceKey#">
		</cfinvoke>
		
		<cfif isAuth>
			
			<!--- Does the text that the user entered match the hashed value? --->
			<cfif application.captcha.validateCaptcha(arguments.captchaHash,arguments.captchaText)>
				<cfset captchaPass  = true />
				<!--- Set the captcha validated cookie to true. It will expire in one minute. --->
				<cfcookie name="captchaValidated" expires="#dateAdd('n', 1, now())#" value="true">

			<cfelse>
				<!--- Note: the captcha will only be validated true one time as the encryption tokens get changed on true. However, the kendo validator validates quickly on blur, so there many be a true value overwritten by a false a millisecond later. We don't want to ever change a true value to false and will use session vars to prevent this behavior. You can override this behavior by setting debugging to true. --->
				<cfif not debugging and isDefined("cookie.captchaValidated")>
					<cfset captchaPass  = true />
				<cfelse>
					<cfset captchaPass  = false />
				</cfif>
			</cfif>

			<!---Return it.--->
			<cfreturn captchaPass />
			
		<cfelse><!---<cfif isAuth>--->
			<!--- Return false --->
			<cfreturn false>
		</cfif><!---<cfif isAuth>--->
			
	</cffunction>
	
	<!--- Functions to handle the saving the data. Much of this function's logic was contained in the addComment.cfm template. --->
	<cffunction name="postCommentSubscribe" returnFormat="json" output="true" access="remote" hint="Handles server side processing when a user adds a comment using the addComment interface.">
		
		<cfargument name="entryId" required="true" default="" hint="Pass in the entryId." />
		<cfargument name="uiInterface" required="true" default="" hint="either 'addComment' or 'subscribe'. This function supports both the addComment and subscribe interfaces. We need to know what interface is being used to determine the proper logical pathway." />
		<cfargument name="entryTitle" required="true" default="" hint="Pass in the entry title. This will be used as the subject for the sent email." />
		<cfargument name="commenterName" required="true" default="" hint="Pass in the name." />
		<cfargument name="commenterEmail" required="true" default="" hint="Pass in the email." />
		<cfargument name="commenterWebSite" required="false" default="" hint="Pass in the website." />
		<cfargument name="comments" required="true" default="" hint="Pass in the users comments." />
		<cfargument name="captchaText" required="false" default="" hint="Pass in the captcha that the user entered." />
		<cfargument name="captchaHash" required="false" default="" hint="Pass in the captcha hash that is inside a hidden form." />
		<cfargument name="subscribe" required="true" default="" hint="Does the user want to subscribe?" />
		
		<cfset valid = true>
		<!--- Set the default response object. --->
		<cfset response = {} />
		<cfset response[ "entryId" ] = arguments.entryId />
		<cfset response[ "sucess" ] = true />
		<cfset response[ "validName" ] = true />
		<cfset response[ "validEmail" ] = true />
		<cfset response[ "validWebsite" ] = true />
		<cfset response[ "validComment" ] = true />
		<cfset response[ "errorMessage" ] = "" />
		<cfset response[ "dbSuccess" ] = true />
		<cfset response[ "dbErrorMessage" ] = "" />
		
		<cfset commenterName = trim(arguments.commenterName)>
		<cfset commenterEmail = trim(arguments.commenterEmail)>
		<!--- RBB 11/02/2005: Added new website option --->
		<cfset commenterWebSite = trim(arguments.commenterWebSite)>
		<cfset comments = trim(arguments.comments)>

		<!--- if website is just http://, remove it --->
		<cfif commenterWebSite is "http://">
			<cfset commenterWebSite = "">
		</cfif>
		
		<!--- Track errors. --->
		<cfif arguments.uiInterface neq 'subscribe' and not len(commenterName)>
			<cfset valid = false>
			<cfset response[ "validName" ] = false />
		</cfif>
		<!--- The subscribe interface does not require email --->
		<cfif not len(commenterEmail) or not isValid("email", commenterEmail)>
			<cfset valid = false>
			<cfset response[ "validEmail" ] = false />
		</cfif>
		<!--- The subscribe interface does not require a valid web site url. --->
		<cfif arguments.uiInterface neq 'subscribe' and len(commenterWebSite) and not isValid("URL", commenterWebSite)>
			<cfset valid = false>
			<cfset response[ "validWebsite" ] = false />
		</cfif>
		<!--- And the subscribe interface does not require any comments. --->
		<cfif arguments.uiInterface neq 'subscribe' and not len(Comments)>
			<cfset valid = false>
			<cfset response[ "validComment" ] = false />
		</cfif>
		<!--- The captcha validation has occurred on the UI. The captha backend will validate the captcha once and regenerate a new key. It can't be done twice (that I know of anyway). --->
			
		<!--- Authorize this request using the security tokens. We don't want anyone trying to hack by programming directly to the proxy cfc. --->
		<cfinvoke component="#this#" method="isClientKeyAuthorized" returnvariable="isAuth">
			<!--- The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
			<cfinvokeargument name="encryptionKey" value="#session.encryptionKey#">
			<cfinvokeargument name="serviceKey" value="#session.serviceKey#">
		</cfinvoke>
		
		<cfif isAuth>
		
			<!---See https://www.telerik.com/blogs/extending-the-kendo-ui-validator-with-custom-rules on how we are going to get server side validation working on the client end.--->

			<!---If there are no errors, proceed.--->
			<cfif valid>
				<cfif arguments.uiInterface eq 'contact'>

					<cfset commentTime = dateAdd("h", application.blog.getProperty("offset"), now())>
					<cfsavecontent variable="body">
						<cfoutput>
						<table cellpadding="0" cellspacing="5" border="0" align="left">
							<tr>
								<td align="right" width="225px">#getResourceBundle("commentadded")#</td>
								<td align="left">#application.localeUtils.dateLocaleFormat(commentTime)# / #application.localeUtils.timeLocaleFormat(commentTime)#</td>
							</tr>
							<tr>
								<td align="right">#getResourceBundle("commentmadeby")#</td>
								<td align="left">#commenterName# (#commenterEmail#)</td>
							</tr>
							<tr>
								<td align="right" width="225px">#getResourceBundle("ipofposter")#</td>
								<td align="left">#cgi.REMOTE_ADDR#</td>
							</tr>
							<tr>
								<td align="right" width="225px">Website</td>
								<td align="left">#commenterWebSite#</td>
							</tr>
							<tr>
								<td align="right" width="225px">Comments</td>
								<td align="left">#comments#</td>
							</tr>
						</table>
						</cfoutput>
					</cfsavecontent>

					<!--- Email the owner of the blog. #application.blog.getProperty('owneremail')#--->
					<cfset application.utils.mail(
						to="#application.blog.getProperty('owneremail')#",
						from="#application.blog.getProperty('owneremail')#",
						subject="Message sent via Gregory's Blog",
						body="#body#",
						mailserver="#application.blog.getProperty('mailserver')#",
						mailusername="#application.blog.getProperty('mailusername')#",
						mailpassword="#application.blog.getProperty('mailpassword')#",
						type="html"
					)>

				<cfelse><!---<cfif arguments.uiInterface eq 'contact'>--->

					<!--- RBB 11/02/2005: added website to commentID --->
					<cftry>
						<cfinvoke component="#application.blog#" method="addComment" returnVariable="commentID">
							<cfinvokeargument name="entryid" value="#arguments.entryId#">
							<cfinvokeargument name="name" value="#left(arguments.commenterName, 50)#">
							<cfinvokeargument name="email" value="#left(arguments.commenterEmail,50)#">
							<cfinvokeargument name="website" value="#left(arguments.commenterWebSite, 255)#">
							<cfinvokeargument name="comments" value="#arguments.comments#">
							<cfinvokeargument name="subscribe" value="#arguments.subscribe#">
							<cfif isDefined("session.loggedin")>
								<cfinvokeargument name="overridemoderation" value="true">
							</cfif>
						</cfinvoke>								

						<cfif arguments.uiInterface eq 'postComment'>
							<!--- Form a message about the comment --->
							<cfset subject = "Comment posted to " & application.blog.getProperty("blogTitle") & " : " & arguments.entryTitle>
							<cfset commentTime = dateAdd("h", application.blog.getProperty("offset"), now())>

							<cfsavecontent variable="email">
							<cfoutput>
								<!--- I needed to remove the original doctype, body, html other libraries here (ga) --->
								<body id="blogcommentmail" style="font:10pt Arial,sans-serif;padding: 10px;">
									<table cellspacing=0>
										<tr id="header">
											<td colspan=2>Comment Added to <a href="#application.blog.makeLink(arguments.entryId)###c#commentID#">#htmlEditFormat(application.blog.getProperty("blogTitle"))# : #arguments.entryTitle#</a></td>
										</tr>
										<tr><td colspan=2 style="height:10px"></td></tr>
										<tr id="content" style="padding: 20px;">
											<td id="comment" style="width:75%;">
												#(htmlEditFormat(arguments.comments))#
											</td>
											<td id="commentor" valign=top style="width:25%;background-color: ##edf0c9;height:100%">
												<div id="avatar" style="text-align: center;margin:30px 0 0 0;padding:20px 0 20px 0;width: 100%;height: 100%;">
													<img src="http://www.gravatar.com/avatar/#lcase(hash(arguments.commenterEmail))#?s=80&amp;r=pg&amp;d=#application.rooturl#/images/gravatar.gif" id="avatar_image" border=0 title="#arguments.commenterName#'s Gravatar" style="width:80px;height:80px;padding:5px;background:white; border:1px solid ##e4e8af;" />
													<div id="commentorname" style="text-align: center;padding:20 0 20px 0;"><cfif len(arguments.commenterWebSite)><a href="#arguments.commenterWebSite#"></cfif>#arguments.commenterName#<cfif len(arguments.commenterWebSite)></a></cfif></div>
												</div>
											</td>
										</tr>
										<tr><td colspan=2 style="height:10px"></td></tr>
										<tr id="footer">
											<td><a href="http://blogcfc.com/"><img src="#application.rooturl#/images/logo.png" border=0/></a></td>
											<td id="footerlinks" nowrap style="margin:5px;text-align:right;border-top:1px solid ##e4e8af;padding:0 10px 0 0;">
												%unsubscribe%
												<div id="createdby" style="font-size:8pt;padding:20px 0 0 0;bottom:0px;text-align:right;">
													Created by <a href="http://www.gregoryalexander.com">Raymond Camden and Gregory Alexander</a>
												</div>
											</td>
										</tr>
									</table>
							</cfoutput>
							</cfsavecontent>

							<cfinvoke component="#application.blog#" method="notifyEntry">
								<cfinvokeargument name="entryid" value="#arguments.entryId#">
								<cfinvokeargument name="message" value="#trim(arguments.comments)#">
								<cfinvokeargument name="subject" value="#subject#">
								<cfinvokeargument name="from" value="#arguments.commenterEmail#">
								<cfif application.commentmoderation>
									<cfinvokeargument name="adminonly" value="true">
								</cfif>										
								<cfinvokeargument name="commentid" value="#commentid#">
								<cfinvokeargument name="html" value="true">
							</cfinvoke>
						</cfif><!---<cfif arguments.uiInterface eq 'postComment'>--->

						<cfcatch>
							<cfset valid = false>
							<cfif cfcatch.message eq "Comment blocked for spam.">
								<cfset response[ "errorMessage" ] = "Your comment has been flagged as spam." />
							<cfelse>
								<cfset response[ "errorMessage" ] = cfcatch.message & ',' & cfcatch.detail />		
							</cfif>
						</cfcatch>

					</cftry>
				</cfif><!---<cfif arguments.uiInterface eq 'contact'>--->	

			<cfelse><!---<cfif valid>--->
				<!---If there is an error, add success false to the error array.--->
				<cfset valid = false>
				<cfset response[ "sucess" ] = false />
			</cfif><!---<cfif valid>--->
						
		<cfelse><!---<cfif isAuth>--->
			<!---If there is an error, add success false to the error array.--->
			<cfset valid = false>
			<cfset response[ "sucess" ] = false />
		</cfif><!---<cfif isAuth>--->
			
		<!--- Prepare the response object. --->
		<!---Send the valid argument as success.--->
		<cfset response[ "sucess" ] = valid />
		<!--- Serialize the response --->
    	<cfset serializedResponse = serializeJSON( response ) />
		<!--- Send the response back to the client. --->
		<cfreturn serializedResponse>
		
	</cffunction><!---<cffunction name="postComment"...--->
			
	<!--- Functions to handle the saving the data. Much of this function's logic was contained in the addComment.cfm template. --->
	<cffunction name="subscribe" returnFormat="json" output="true" access="remote" hint="Subscribes a user to the blog. Also sends out an email asking the user to confirm the subscription.">
		
		<cfargument name="email" required="true" default="" hint="Pass in the subscribers email address." />
		
		<!---Set the default response object.--->
		<cfset response = {} />
		<cfset response[ "message" ] = "" />
		
		<!--- Authorize this request using the security tokens. We don't want anyone trying to hack by programming directly to the proxy cfc. --->
		<cfinvoke component="#this#" method="isClientKeyAuthorized" returnvariable="isAuth">
			<!--- The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
			<cfinvokeargument name="encryptionKey" value="#session.encryptionKey#">
			<cfinvokeargument name="serviceKey" value="#session.serviceKey#">
		</cfinvoke>
		
		<cfif isAuth>
		
			<!--- Build the token.--->
			<cfinvoke component="#application.blog#" method="addSubscriber"  returnVariable="token">
				<cfinvokeargument name="email" value="#arguments.email#">
			</cfinvoke>

			<!--- Process the request.--->
			<cfif token is not "">
				<!--- Send confirmation email to subscriber --->
				<cfsavecontent variable="body">
				<cfoutput>
				#application.resourceBundle.getResource("subscribeconfirmation")#
				#application.rooturl#/index.cfm?confirmSubscription&token=#token#
				</cfoutput>
				</cfsavecontent>

				<cfset application.utils.mail(
						to=#arguments.email#,
						from=application.blog.getProperty("owneremail"),
						subject="#application.blog.getProperty("blogtitle")# #application.resourceBundle.getResource("subscribeconfirm")#",
						type="text",
						body=body,
						mailserver=application.blog.getProperty("mailserver"),
						mailusername=application.blog.getProperty("mailusername"),
						mailpassword=application.blog.getProperty("mailpassword")
						)>
				<cfset message = "We have received your request. Please keep an eye on your email; we will send you a link to confirm your subscription.">
			<cfelse>
				<!--- If there is no token, the email has already been subscribed. --->
				<cfset message = " You're already subscribed.">
			</cfif><!---<cfif token is not "">--->	
		
		</cfif><!---<cfif isAuth>--->
			
		<!--- Prepare the response object. --->
		<cfset response[ "message" ] = message />
		<!--- Serialize the response --->
    	<cfset serializedResponse = serializeJSON( response ) />
		<!--- Send the response back to the client. --->
		<cfreturn serializedResponse>

	</cffunction>
			
</cfcomponent>
	