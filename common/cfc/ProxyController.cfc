<cfcomponent displayName="ProxyController" output="false" hint="The proxy between the client and the backend blog cfc."> 
	
<!--- 
	*************************************************************************************************************
	************************************************************************************************************* 
	Author: Gregory Alexander
	Date: November 11 2018.
	Purpose: Raymond's approach was typical in the mid 2000's. He posted a form to a .cfm page, and the server processed server side logic as well as perorming client side operations, like setting form values on the client. However, Ajax is a different beast. Most of our Kendo HTML5 interfaces do not post to another HTML page. Instead, the UI elements, such as the Kendo window, posts limited data to a function that has to perform all of the logic without refreshing the client page. However, for several reasons, the blog.cfc component does not have all of the information that I need to do this successfully.
	First, we can't get session vars in the main blog.cfc. Raymond (and et-al) had another application.cfm in the org/cambden/blog folder that prevented this component from having access to the session variables set on the /blogCfc/application.cfm template. Cfc's should have access to the session scope unless it finds another application.cfm (or cfc) template, and here, this is the case.
	This poses some problems with ajax. I do not want to have to hard code authentication variables, like the isAdmin, in a javascript ajax post. This is quite insecure.
	I tried in vain to get the blog.cfc component to work for my purposes. After finding and eliminating the 'other' application.cfm template which caused problems accessing the session scope, I was able to obtain session variables, but the elimation of the application.cfm template in the same directory caused new problems. One example is that the isUserInRole function is now erroring out with an '
	You have attempted to dereference a scalar variable of type class java.lang.String as a structure with members.'. This new error was raised throughout the blog.cfc template.
	In order to have the session scope, and in order to potentially cache the code after an ajax operation, I am using this template as a proxy.
	Goals: This template will use Raymond's blog.cfc to perform all database operations. Whenever possible, I will perform server side business logic using Raymonds Blog.cfc.
	*************************************************************************************************************
	************************************************************************************************************* 
--->

	<!--- Notes: this template has access to the isLoggedIn() function and other session vars. However, ColdFusion's native isUserLoggedIn() is not available here. --->
	
	<!--- Common libraries. --->
	<!--- We need the image object to save an manipulate images. These may fail when initally installing the blog with Lucee. If the stringUtilsObj is not initialized later on due to some error, comment out the try block to see if it fixes the problem. I had an issue when the ftp progam was deleting the cfc's --->
	<cftry>
		<cfobject component="#application.imageComponentPath#" name="ImageObj">
		<!--- The jsonArray function turns a native ColdFusion query into an array of structs that can be easily used with jQuery. ---> 
		<cfobject component="#application.cfJsonComponentPath#" name="jsonArray">
		<!--- Include our string utils object to trim strings --->
		<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
		<!--- Instantiate the Render.cfc. --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
		<!--- Object to send mail --->
		<cfobject component="#application.utilsComponentPath#" name="UtilsObj">
	<cfcatch type="any"></cfcatch>
	</cftry>

	<!---******************************************************************************************************
		Security tokens and keys.
	******************************************************************************************************--->
		
	<cffunction name="verifyCsrfToken" access="remote" output="false"
			hint="Used to determine if the csrf token is valid. This is also used to diagnose security issues when the csrf token fails.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
			
		<!--- Trim the token --->
		<cfset token = StringUtilsObj.trimStr(arguments.csrfToken)>
			
		<!--- The token must pass ColdFusion's own check (2026-10-19: a cookie comparison that was meant as a backup here never
		took effect and has been removed, along with the cookie). --->
		<cfset tokenAuth = isdefined("arguments.csrfToken") and len(token) and CSRFVerifyToken(token, 'admin')>

		<!--- Return it --->
		<cfreturn tokenAuth>
			
	</cffunction>
	
	<cffunction name="secureFunction" access="package" output="yes" returntype="boolean"
			hint="This is meant to be placed on top of a function to secure it against unauthorized use. It returns a 403 header if this is being called from an ajax request">
		<cfargument name="capabilities" required="no" default="" hint="What capabilities are authorized for this function?">
		<cfargument name="pkey" required="no" default="" hint="A temporary password as a string. We need a way to temporary bypass the isLogged in when a new user has been setup and they need to change the password that was assigned to them. This key will be authenticated against the database to determine if they whould be allowed in.">
		<cfargument name="pkeyUserName" required="no" default="" hint="The username the pkey is claimed to belong to. Required to use the pkey bypass -- the pkey must match the Password column for THIS specific user, never any active user in the table.">

		<!--- Secure this function. We are going to use an approach suggested by Chris Tierney. --->
		<cfset auth = true>

		<!--- One off branch. Allow the user to bypass having to be logged in by authenticating a string against the password in the users table. This is only meant to let a newly-invited user complete their own account setup, so it is deliberately restricted two ways versus the original implementation: (1) the pkey must be bound to a specific, named account via pkeyUserName -- it is no longer matched against "any" active user's Password column -- and (2) it can only ever satisfy a request for the self-service 'EditProfile' capability, never an administrative capability such as EditUser, no matter what the calling function asks for. Note: there is still no expiry on the pkey itself (that would require a schema change to add a expiry column), so an old invite link remains valid indefinitely -- flagged as a follow-up. --->
		<cfif len(arguments.pkey) and len(arguments.pkeyUserName) and arguments.capabilities eq 'EditProfile'>

			<!--- Verify that the userName and password are correct in the link --->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					UserName as UserName
				)
				FROM Users
				WHERE
					UserName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pkeyUserName#" maxlength="255">
					AND Password = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pkey#" maxlength="255">
					AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				<cfif isSimpleValue(application.BlogDbObj.getBlogId())>
					AND BlogRef = #application.BlogDbObj.getBlogId()#
				</cfif>
			</cfquery>

			<!--- The pkey and/or the username it was claimed to belong to was not valid --->
			<cfif not arrayLen(Data)>
				<!--- Set our auth flag to false. --->
				<cfset auth = false>
			</cfif>
		<cfelseif len(arguments.pkey)>
			<!--- A pkey was supplied, but either it was not bound to a specific username, or it is
				being used to try to authorize something beyond self-profile-editing. Reject outright
				rather than falling through to the standard isLoggedIn() branch below -- a bare,
				unbound, or over-scoped pkey must never be treated as equivalent to a real login. --->
			<cfset auth = false>
		<!--- Standard logical branch --->
		<cfelse>
			<!--- Check to see if the user is logged in and handle ajax requests. --->
			<cfif not application.Udf.isLoggedIn()>
				<cfset auth = false>
			<cfelse><!---<cfif not application.Udf.isLoggedIn()>--->
				<!--- Check the capabilities --->
				<cfset auth = authorizedCapability(arguments.capabilities)>
			</cfif><!---<cfif not application.Udf.isLoggedIn()>--->
		</cfif>

		<!--- Terminate any ajax calls with a 403 status (forbidden or denied) --->
		<cfif not auth>
			<cfif isAjaxRequest()>
				<!--- Set the resonse header to 403 (denied) --->
				<cfset getpagecontext().getresponse().setstatus(403)>
			</cfif>
			<!--- And abort further processing --->
			<cfabort>
		</cfif>

		<cfreturn auth>
	</cffunction>
				
	<cffunction name="authorizedCapability" access="public" returntype="boolean" 
			hint="Verifies the capabilities for a given function">
		<cfargument name="authorizedCapabilities" required="yes" default="" hint="What are capabilities required to execute this function?">
			
		<cfparam name="capabilityAuth" default="false" type="boolean">

		<!--- All users may edit their own profile -- but ONLY when EditProfile is the sole
			capability being requested. When EditProfile is bundled with other capabilities
			(e.g. "EditProfile,EditUser"), the free pass for self-profile-editing must never be
			allowed to unlock capabilities (like EditUser) that were never actually verified
			against the session. --->
		<cfif listLen(arguments.authorizedCapabilities) eq 1 and arguments.authorizedCapabilities eq 'EditProfile'>
			<cfset capabilityAuth = true>
		<cfelse>
			<!--- The authorizedCapabilities is either a string or a ColdFusion list --->
			<cfloop list="#arguments.authorizedCapabilities#" index="i">
				<cfif findNoCase(i, session.capabilityList)>
					<cfset capabilityAuth = true>
				</cfif>
			</cfloop>
		</cfif>
		<cfreturn capabilityAuth>
	</cffunction>
	
	<!--- Is this an ajax request?
	Function created by Dan Switzer (also an approach suggested on his blog by Raymond Camden). 
	See https://blog.pengoworks.com/index.cfm/2009/4/9/ColdFusion-UDF-for-detecting-jQuery-AJAX-operations
	--->
	<cffunction name="isAjaxRequest" output="false" returntype="boolean" access="public">
		<cfset var headers = getHttpRequestData().headers />
		<cfreturn structKeyExists(headers, "X-Requested-With") and (headers["X-Requested-With"] eq "XMLHttpRequest") />
	</cffunction>
				
	<cffunction name="ajaxLogin" output="false" access="remote" returnformat="json"
		hint="Allows the user to log in via a HTML Kendo window.">
		
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="userName" required="yes" default="" hint="Pass in the userName">
		<cfargument name="password" required="yes" default="" hint="Pass in the password">

		<!--- Verify the csrf token before attempting to authenticate. This was previously declared as a
			required argument but never actually checked, which meant a forged cross-site request could
			reach application.blog.authenticate() without ever having loaded the login form and obtained a
			valid, session-bound token. The adminInterface.cfm window already generates this token via
			csrfGenerateToken("admin", false) before the login form is rendered, so a legitimate login
			always has one to send. --->
		<cfif (not isDefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset session.loggedin = false>
			<cfreturn serializeJSON(false)>
		</cfif>

		<cfif application.blog.authenticate(left(trim(form.username),50),left(trim(form.password),50))>
			<cfloginuser name="#trim(arguments.username)#" password="#trim(arguments.password)#" roles="admin">
			<cfset session.userName = trim(username)>
			<cfset session.key = trim(password)>
			<!--- Get the current logged in user's Id. Application.cfc's adminRequestStart() (the full-page form
				login) sets this; this ajax login window is a second, separate login path that must set the
				same session vars or anything that reads session.userId later - like newPost.cfm's author
				dropdown default - breaks for any session established through this window instead. --->
			<cfset session.userId = application.blog.getUserIdByUserName(username)>
			<!---
				  This was added because CF's built in security system has no way to determine if a user is logged on.
				  In the past, I used getAuthUser(), it would return the username if you were logged in, but
				  it also returns a value if you were authenticated at a web server level (cgi.remote_user).
				  Here we are checking whether a flag was set to check for a user logon.
			--->
			<cfset session.loggedin = true>
			<!--- Add the blog user's specific roles to the session scope. We just want to get a list of roleNames (note the roleList arg) --->
			<cfset session.roles = application.blog.getUserBlogRoles(username, 'roleList')>
			<!--- Set the capabilities. There are one or more capabilities for each role.--->
			<cfset session.capabilityList = application.blog.getCapabilitiesByRole(session.roles, 'capabilityList')>
			<!--- Also get the capability id's --->
			<cfset session.capabilityIdList =  application.blog.getCapabilitiesByRole(session.roles, 'capabilityIdList')>
			<!--- Generate the session Cross-Site Request Forgery (CSRF) token. This will be validated on the server prior to the login logic for security. --->
			<!--- The forceNew argument does not work for versions less than 2018, however, CF2021 needs this argument or the token will change every time causing errors. Note: while the forceNew argument was not introduced until 2018, having csrfGenerateToken on the page with a forceNew argument will cause an error with 2016, even if you put it in a catch block or have two logical branches depending upon the version. --->
			<cfset csrfToken = csrfGenerateToken("admin", false)><!---forceNew=false--->
			<!--- Drop a cookie. Using the cfcookie tag does not work with dynamic vars in the path. --->
			<cfset cookie.isAdmin = { value="true", path="#application.baseUrl#", expires=30 }>	
		<cfelse>
			<cfset session.loggedin = false>
			<!--- Suggested by Shlomy Gantz to slow down brute force attacks (orginal BlogCfc code)--->
			<cfset createObject("java", "java.lang.Thread").sleep(500)>
		</cfif>
			 
		<cfreturn serializeJSON(session.loggedin)>	
	</cffunction>
	
	<!---******************  Functions to create a random phrase and a key ******************--->
	<cffunction name="createEncryptionPhrase" access="package" returntype="string" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page. This function is deprecated.">
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
			
	<!--- What is the key prase used to encrypt and decode the key with? --->
	<cffunction name="getEncryptionPhrase" access="package" returntype="string" hint="Sets our key prase to use in encryption. This is a private function only available to other functions on this page. This function is depracated.">
		<cfset encryptionPhrase = application.BlogDbObj.getServiceKeyEncryptionPhrase()>
		<cfreturn encryptionPhrase>
	</cffunction>
	
	<!--- Generate the 'serviceKey'. This is the encrypted key that is created using the random phrase and the encryption key. I am calling this a 'service key' in order to obsfucate the logic as it is used on the client side. --->
	<cffunction name="createTokenKeys" access="public" returntype="struct" hint="Generates and saves our service key that is a comination of a phrase and an encryptionKey. Returns the encryption and service keys back to the client as a structure. This should be the only 'key' related security function that is accessible to the client without having to pass in a 'serviceKey'. This function is depracated.">

		<!--- Create a random encryption phrase. --->
		<cfset encryptionPhrase = getEncryptionPhrase()>
		<!--- Create a random key (this creates a new key every  single time it is invoked). We are going to store this in a session cookie. --->
		<cfset encryptionKey = createEncryptionKey()>
		<!--- Use the encryption phrase and new key to create the 'serviceKey'. This also will be stored in a session cookie. --->
		<cfset serviceKey = encrypt(encryptionPhrase, encryptionKey,  "AES", "UU") />	

		<!--- Return the keys back to the client. We don't  want to return any other keys to the client side for security. --->
		<cfset tokenKeys = {encryptionKey=#encryptionKey#,serviceKey=#serviceKey#}>
			
		<!--- Return the struct.--->
		<cfreturn tokenKeys>

	</cffunction>
			
	<cffunction name="createEncryptionKey" access="package" returntype="string" hint="Generates an key to use for encryption. This is a private function only available to other functions on this page. This function is depracated.">
		<!--- Generate a secret key. --->
		<cfset encryptionKey = generateSecretKey( "AES" ) />
		<cfreturn encryptionKey>
	</cffunction>

	<cffunction name="decryptServiceKey" access="package" returntype="string" hint="Decrypts a security key sent by the client. This is a private function only available to other functions on this page. This function is depracated.">
		
		<cfargument name="encryptionKey" required="yes" hint="Pass in the encryptionKey. The 'encryptionKey' a key provided using ColdFusion's generateSecretKey function.">
		<cfargument name="serviceKey" required="yes" hint="Pass in the serviceKey. This is the encrypted key that is created using the random phrase and the encryption key. I am calling this a 'service key' in order to obsfucate the logic as it is used on the client side.">
		
		<!--- Get the secret encryption phrase. --->
		<cfinvoke component="#this#" method="getEncryptionPhrase" returnvariable="encryptionPhrase" />

		<!--- The decrypt function takes the service key (which is generated using a key phrase) and an ecyrption key created by the generateSecretKey native ColdFusion method. Once decoded, it should match the 'encryption phrase'. --->
		<cfset decodedServiceKey = decrypt(arguments.serviceKey, arguments.encryptionKey, "AES", "UU") />

		<!--- Return it. It should match the encryption phrase.--->
		<cfreturn decodedServiceKey>

	</cffunction>
			
	<cffunction name="isClientKeyAuthorized" access="public" returntype="boolean" hint="Compares the decoded client key and see if it matches the encryptionPhrase. If it does, the client is authorized. This function is depracated.">
		
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
			
	<!---******************************************************************************************************
		JSON functions
	*******************************************************************************************************--->
	<cffunction name="serializeMessage" access="remote" returnformat="json" hint="Returns a json string back to the client for both ColdFusion and Lucee. This should only be used to send back simple strings such as 'invalid token'">
		<cfargument name="message" required="yes" default="">
			
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn arguments.message>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( arguments.message ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>		
			
	</cffunction>
	
	<!---******************************************************************************************************
		UI Specific functions
	*******************************************************************************************************--->

	<!--- Captcha.  --->
	<cffunction name="getCaptchaAsJson" access="remote" returnformat="json" output="false" 
			hint="Returns a json object to populate the captcha UI in the addComment and addCommentSub templates. This is used to populate a kendo.observable model (a Kendo UI MVVM framework) on the page.">
		<cfargument name="csrfToken" required="yes" default="">
			
		<!--- Anyone can access this function --->

		<!--- There are no arguments for this function. --->
		<cfsetting enablecfoutputonly="true" />
				
		<!--- Create a random string --->
		<cfset session.captchaText = application.blog.makeRandomString()>
		<!--- A random reference for the image, unrelated to the word (2026-10-14). The word itself is checked on the server. --->
		<cfset session.captchaHash = lCase(hash(createUUID() & rand("SHA1PRNG"), "SHA-256"))>
		<!--- Create a URL --->
		<cfset captchaUrl = application.baseUrl & "/showCaptcha.cfm?hashReference=" & session.captchaHash>
			
		<!--- Create a two column query with the hash and URL, specifying the column data types --->
		<cfset data = queryNew("captchaImageUrl, captchaHash", "varchar, varchar")> 
		<!--- Add one row. --->
		<cfset newRow = queryAddRow(data, 1)>
		<!--- Populate the image URL--->
		<cfset temp = querySetCell(data, "captchaImageUrl", captchaUrl, 1)> 
		<!--- Populate the hash reference with the session var. --->
		<cfset temp = querySetCell(data, "captchaHash", session.captchaHash, 1)> 

		<!--- Since Lucee automatically converts a ColdFusion object to JSON when the returnformat="json" is set, and that we need to serialize the query to a structure using serializeJson(data,"struct"), we will serialize the query to a structure and then deserialize it to a plain object and return it. --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Serialize the ColdFusion query into an array of structures --->
			<cfset data = serializeJson(data,"struct")>
			<!--- Now deserialize --->
			<cfset jsonString = deserializeJSON(data)>
		<cfelse>
			<!--- Package the data. --->
			<cfinvoke component="cfJson" method="convertCfQuery2JsonStruct" returnvariable="jsonString" >
				<cfinvokeargument name="queryObj" value="#data#">
				<cfinvokeargument name="contentType" value="json">
				<cfinvokeargument name="includeTotal" value="false">
				<!--- don't  include the data handle for dropdown menu's ---> 
				<cfinvokeargument name="includeDataHandle" value="false">
				<!--- Force the database columns coming from the database into lower case. --->
				<cfinvokeargument name="convertColumnNamesToLowerCase" value="false">
			</cfinvoke>
		</cfif>

		<!--- And sent it. --->
		<cfreturn jsonString>

	</cffunction>
	
	<!--- Helper functions for interfaces (addComments, addSub, etc.). Important note on function tags- they must have a returnFormat="json". Otherwise, ColdFusion will return the value wraped in a wddx tag.--->
	<cffunction name="validateCaptcha" access="remote" returnType="boolean" returnFormat="json" output="false" 
			hint="Remote method accessed via ajax. Returns a boolean value to determine if the users entered value matches the captcha image.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="captchaText" required="yes" hint="What did the user enter into the form?" />
		<cfargument name="captchaHash" required="yes" hint="The hashed value of the proper answer. This must match the captcha text in order to pass true." />
		<cfargument name="debugging" required="no" type="boolean" default="false" hint="For testing purposes, we may need to not use the session.captchValidated value to prevent a true value from being incorreclty reset." />
			
		<!--- Does the text that the user entered match the word in the session (the one drawn in the image)? This only helps the
		form tell the visitor while they type; postCommentSubscribe checks the word again on the server when the form is sent.
		2026-10-12: removed the shortcut that also answered true whenever the request carried a captchaValidated cookie - any
		client can send that cookie. It isn't needed: the word stays the same until the comment is accepted, so checking again on
		blur gives the same answer. --->
		<cfset var captchaPass = structKeyExists(session, "captchaText") and len(session.captchaText) and len(trim(arguments.captchaText)) and trim(arguments.captchaText) eq session.captchaText>

		<!---Return it.--->
		<cfreturn captchaPass />
			
	</cffunction>
			
	<!---****************************************************************************************************
		Subscribe
	******************************************************************************************************--->
				
	<cffunction name="subscribe" returnFormat="json" output="false" access="remote" 
			hint="Subscribes a user to the blog. Also sends out an email asking the user to confirm the subscription.">
		<cfargument name="email" required="true" default="" hint="Pass in the subscribers email address." />
		
		<!---Set the default response object.--->
		<cfset response = {} />
		<cfset response[ "message" ] = "" />
			
		<!--- The csrftoken logic will not work here as the user is not always logged in. --->
		
		<!--- Build the token.--->
		<cfinvoke component="#application.blog#" method="addSubscriber" returnVariable="token">
			<cfinvokeargument name="email" value="#arguments.email#">
		</cfinvoke>

		<!--- Process the request.--->
		<cfif token is not "">
			<!--- Send confirmation email to subscriber --->
			<!--- ************* Render email to new subscriber asking them to double opt in ************* --->
			<cfset email = arguments.email>
			<cfset emailTitle = application.BlogDbObj.getBlogTitle() & " subscription confirmation">
			<cfset emailTitleLink = application.baseUrl & '?confirmSubscription=true&token=' & token>
			<cfset emailDesc = "Please confirm your subscription to " & application.BlogDbObj.getBlogTitle()>
			<cfset emailBody = "Please click on the 'Confirm Subscription' button below to confirm your subscription.">
			<cfset callToActionText = "Confirm Subscription">
			<cfset callToActionLink = emailTitleLink>

			<!--- Render the email --->
			<cfinvoke component="#RendererObj#" method="renderEmail" returnvariable="emailBody">
				<cfinvokeargument name="email" value="#email#">
				<cfinvokeargument name="emailTitle" value="#emailTitle#">
				<cfinvokeargument name="emailTitleLink" value="#emailTitleLink#">
				<cfinvokeargument name="emailDesc" value="#emailDesc#">
				<cfinvokeargument name="emailBody" value="#emailBody#">
				<cfinvokeargument name="callToActionText" value="#callToActionText#">
				<cfinvokeargument name="callToActionLink" value="#callToActionLink#">
			</cfinvoke>

			<!--- Email the subscriber asking them to confirm ---> 
			<cfset UtilsObj.mail(
				to=#email#,
				subject="Subscription Confirmation",
				body=emailBody)>

			<cfset message = "We have received your request. Please keep an eye on your email; we will send you a link to confirm your subscription.">
		<cfelse>
			<!--- If there is no token, the email has already been subscribed. --->
			<cfset message = " You're already subscribed.">
		</cfif><!---<cfif token is not "">--->	
			
		<!--- Prepare the response object. --->
		<cfset response[ "message" ] = message />
			
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>

	</cffunction>
					
	<cffunction name="postCommentSubscribe" returnFormat="json" output="false" access="remote" 
			hint="Handles the generic web contact, subscribe to a given post, and adding a comment to a post.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken. This is not used yet to handle non authenticated users.">
		<cfargument name="anonymousUserId" required="false" default="" hint="Pass in the anonymousUserId if it exists for logging purposes." />
		<cfargument name="postId" required="true" default="" hint="Pass in the postId." />
		<cfargument name="uiInterface" required="true" default="" hint="either 'addComment' or 'subscribe'. This function supports both the addComment and subscribe interfaces. We need to know what interface is being used to determine the proper logical pathway." />
		<cfargument name="postTitle" required="true" default="" hint="Pass in the entry title. This will be used as the subject for the sent email." />
		<cfargument name="commenterName" required="true" default="" hint="Pass in the name." />
		<cfargument name="commenterEmail" required="true" default="" hint="Pass in the email." />
		<cfargument name="commenterWebSite" required="false" default="" hint="Pass in the website." />
		<cfargument name="comments" required="true" default="" hint="Pass in the users comments." />
		<cfargument name="captchaText" required="false" default="" hint="Pass in the captcha that the user entered." />
		<cfargument name="captchaHash" required="false" default="" hint="Pass in the captcha hash that is inside a hidden form." />
		<cfargument name="subscribe" required="false" default="true" hint="Does the user want to subscribe?" />
		<!--- Args required after CF Update in May 25 --->
		<cfargument name="rememberMe" required="false" default="true" hint="Drops a cookie on client machine for identification purposes" />
		
		<cfset valid = true>
		<!--- Set the default response object. --->
		<cfset response = {} />
		<cfset response[ "validToken" ] = true />
		<cfset response[ "isAuth" ] = true />
		<cfset response[ "postId" ] = arguments.postId />
		<cfset response[ "success" ] = true />
		<cfset response[ "valid" ] = true />
		<cfset response[ "validName" ] = true />
		<cfset response[ "validEmail" ] = true />
		<cfset response[ "validWebsite" ] = true />
		<cfset response[ "validComment" ] = true />
		<cfset response[ "sessionExpired" ] = false />
		<cfset response[ "errorMessage" ] = "" />
		<cfset response[ "dbSuccess" ] = true />
		<cfset response[ "dbErrorMessage" ] = "" />
		<!--- Commenter responses --->
		<cfset commenterName = trim(arguments.commenterName)>
		<cfset commenterEmail = trim(arguments.commenterEmail)>
		<cfset commenterWebSite = trim(arguments.commenterWebSite)>
		<cfset comments = trim(arguments.comments)>
		<!--- Subscription responses --->
		<cfset response[ "alreadySubscribed" ] = false />
		<!--- Email related responses --->
		<cfset response[ "adminEmailedContact" ] = false />
		<cfset response[ "adminEmailedNewComment" ] = false />
		<cfset response[ "confirmationEmailSent" ] = false />
		<cfset response[ "newCommentEmailSentToPostSubscribers" ] = false />

		<!--- if website is just http://, remove it --->
		<cfif commenterWebSite is "http://" or commenterWebsite eq "https://">
			<cfset commenterWebSite = "">
		</cfif>
		
		<!--- Track errors. --->
		<!--- Authorize this request using my custom security tokens. This is used to prevent cross site injection. The csrfToken method is only used for authenticated users and these custom tokens are only used for external requests. If the session has expired, the encryptionKey will not be available. For now, we will allow the user to continue as the default blog setting is using captcha and this should prevent any tampering. --->
		<cfif isDefined("session.encryptionKey")>
			<cfinvoke component="#this#" method="isClientKeyAuthorized" returnvariable="isAuth">
				<!--- The 'serviceKey' is actually a key created by the combination of a key phrase and an encyption key created using ColdFusion's generateKey method. --->
				<cfinvokeargument name="encryptionKey" value="#session.encryptionKey#">
				<cfinvokeargument name="serviceKey" value="#session.serviceKey#">
			</cfinvoke>
			<cfset response[ "isAuth" ] = isAuth />
		<cfelse>
			<cfset response[ "sessionExpired" ] = true />
			<cfset response[ "isAuth" ] = false />
		</cfif>
				
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
			
		<!--- Captcha, checked here on the server (2026-10-12). It used to be checked only in the browser (validateCaptcha, while
		typing), so anything posting straight to this method - which is what spam bots do - skipped it. The rule is the same one the
		comment window uses to show the captcha and blogJsContent.cfm uses to send it: Use Captcha is on and nobody is signed in.
		The word is the one getCaptchaAsJson put in the session for the image. It is used once: after a comment is accepted it is
		removed, so the same request can't be replayed, and the next comment gets a new image when the window opens. --->
		<cfset response[ "validCaptcha" ] = true />
		<cfif captchaRequired()>
			<cfif not structKeyExists(session, "captchaText") or not len(session.captchaText) or not len(trim(arguments.captchaText)) or trim(arguments.captchaText) neq session.captchaText>
				<cfset valid = false>
				<cfset response[ "validCaptcha" ] = false />
			</cfif>
		</cfif>
		<cfif not isDefined("session.encryptionKey")>
			<cfset response[ "sessionExpired" ] = true />
		</cfif>
		<!--- Set the valid response. success follows it: an invalid request used to come back with success true, so the page said
		the comment was posted when nothing was saved. --->
		<cfset response[ "valid" ] = valid />
		<cfset response[ "success" ] = valid />
		<cfif valid and captchaRequired()>
			<cfset structDelete(session, "captchaText")>
		</cfif>
		
		<!--- See https://www.telerik.com/blogs/extending-the-kendo-ui-validator-with-custom-rules on how we are going to get server side validation working on the client end. --->

		<!--- If there are no errors, proceed. --->
		<cfif valid>
			<!--- Remember me (2026-10-22): the comment window fills in the name, email and website from these cookies
			(includes/windows/addCommentSubscribe.cfm), but nothing ever saved them. Kept for a year; unticking the box forgets them. --->
			<cftry>
				<cfif isBoolean(arguments.rememberMe) and arguments.rememberMe>
					<cfset local.rememberSecure = (cgi.https eq "on" or cgi.server_port_secure eq 1)>
					<cfif len(trim(arguments.commenterName))><cfset cookie.blog_name = { value = left(trim(arguments.commenterName), 255), path = "/", expires = 365, httponly = true, secure = local.rememberSecure }></cfif>
					<cfif len(trim(arguments.commenterEmail))><cfset cookie.blog_email = { value = left(trim(arguments.commenterEmail), 150), path = "/", expires = 365, httponly = true, secure = local.rememberSecure }></cfif>
					<cfif len(trim(arguments.commenterWebSite))><cfset cookie.blog_website = { value = left(trim(arguments.commenterWebSite), 255), path = "/", expires = 365, httponly = true, secure = local.rememberSecure }></cfif>
				<cfelse>
					<!--- In capitals: that is how they were saved, and a browser treats blog_name and BLOG_NAME as two cookies. --->
					<cfloop list="blog_name,blog_email,blog_website" index="local.rememberCookie">
						<cfif structKeyExists(cookie, local.rememberCookie)><cfset cookie[uCase(local.rememberCookie)] = { value = "", path = "/", expires = "now" }></cfif>
					</cfloop>
				</cfif>
				<cfcatch type="any"></cfcatch>
			</cftry>

			<!--- Handle the contact form. Note: this does not save the data to the db --->
			<cfif arguments.uiInterface eq 'contact'>
				
				<!--- *************Render email to blog owner informing them of a new contanct message --->
				<cfset commentTime = application.blog.blogNow()>
				<cfsavecontent variable="contactEmailBody">
					<cfoutput>
					<table cellpadding="5" cellspacing="5" border="0" align="left">
						<tr>
							<td align="right" width="20%">Blog Contact</td>
							<td align="left">#dateFormat(commentTime)# / #timeFormat(commentTime)#</td> 
						</tr>
						<tr>
							<td align="right">Name:</td>
							<td align="left">#commenterName# (#commenterEmail#)</td>
						</tr>
						<tr>
							<td align="right">Message:</td>
							<td align="left">#comments#</td>
						</tr>
						<tr>
							<td align="right">Website:</td>
							<td align="left">#commenterWebSite#</td>
						</tr>
						<tr>
							<td align="right">IP Address:</td>
							<td align="left">#cgi.REMOTE_ADDR#</td>
						</tr>
					</table>
					</cfoutput>
				</cfsavecontent>
					
				<!--- Now that we have the content body, pass it to the render component and render the rest of the email --->
				<cfinvoke component="#RendererObj#" method="renderEmail" returnvariable="emailBody">
					<cfinvokeargument name="email" value="#application.BlogDbObj.getBlogEmail()#">
					<cfinvokeargument name="emailTitle" value="#commenterName# has contacted you">
					<cfinvokeargument name="emailDesc" value="Message sent via #application.BlogDbObj.getBlogTitle()#">
					<cfinvokeargument name="emailBody" value="#contactEmailBody#">
					<!--- There is no call to action button here. --->
					<cfinvokeargument name="callToActionText" value="">
					<cfinvokeargument name="callToActionLink" value="">
				</cfinvoke>

				<!--- Email the owner of the blog. --->
				<cfset UtilsObj.mail(
					to=#application.BlogDbObj.getBlogEmail()#,
					subject="Message sent via #application.BlogDbObj.getBlogTitle()#",
					body=emailBody)>
					
				<!--- Send a response indicating that an email was sent to the admin --->
				<cfset response[ "adminEmailedContact" ] = true />
				
			<!--- This subscribes a user to a given post. This allows the subscriber to be notified when there are new comments. --->
			<cfelseif arguments.uiInterface eq 'subscribe'>
				
				<!--- Add the subscriber and assign them to a post. This will add the user to the subscriber table and set the PostRef. We don't  need to do anything else or email anything when a user subscribes to a post. Note: this will return the new subscriber token --->
				<cfset subscribeToPostAndReturnToken = application.blog.addSubscriber(arguments.commenterEmail, arguments.postId)>
					
				<!--- See if the user has confirmed a prior subscription (there are subscriptions to the blog as well as individual posts) --->
				<cfset hasSubscriberBeenVerified = application.blog.hasSubscriberBeenVerified(arguments.commenterEmail)>
					
				<cfif not hasSubscriberBeenVerified>
					
					<!--- ************* Render email to new subscriber asking them to double opt in ************* --->
					<cfset email = arguments.commenterEmail>
					<cfset emailTitle = application.BlogDbObj.getBlogTitle() & " subscription confirmation">
					<cfset emailTitleLink = application.baseUrl & '?confirmSubscription=true&token=' & subscribeToPostAndReturnToken>
					<cfset emailDesc = "Please confirm your subscription to " & application.BlogDbObj.getBlogTitle()>
					<cfset emailBody = "Please click on the 'Confirm Subscription' button below to confirm your subscription.">
					<cfset callToActionText = "Confirm Subscription">
					<cfset callToActionLink = emailTitleLink>
				
					<!--- Render the email --->
					<cfinvoke component="#RendererObj#" method="renderEmail" returnvariable="emailBody">
						<cfinvokeargument name="email" value="#email#">
						<cfinvokeargument name="emailTitle" value="#emailTitle#">
						<cfinvokeargument name="emailTitleLink" value="#emailTitleLink#">
						<cfinvokeargument name="emailDesc" value="#emailDesc#">
						<cfinvokeargument name="emailBody" value="#emailBody#">
						<cfinvokeargument name="callToActionText" value="#callToActionText#">
						<cfinvokeargument name="callToActionLink" value="#callToActionLink#">
					</cfinvoke>

					<!--- Email the subscriber asking them to confirm ---> 
					<cfset UtilsObj.mail(
						to=#email#,
						subject="Subscription Confirmation",
						body=emailBody)>
						
					<!--- Send a response back to the client to determine the messages shown in the popup --->
					<cfset response[ "confirmationEmailSent" ] = true />
						
				<cfelse><!---<cfif not hasSubscriberBeenVerified>--->
					<!--- Send a response back to the client to determine the messages shown in the popup --->
					<cfset response[ "alreadySubscribed" ] = true />
				</cfif><!---<cfif not hasSubscriberBeenVerified>--->
					
			<!--- The user is adding a comment. --->
			<cfelseif arguments.uiInterface eq 'addComment'><!---<cfif arguments.uiInterface eq 'contact'>--->

				<cftry>
					<cfinvoke component="#application.blog#" method="addComment" returnVariable="commentId">
						<cfinvokeargument name="postId" value="#arguments.postId#">
						<cfinvokeargument name="name" value="#left(arguments.commenterName, 255)#">
						<cfinvokeargument name="email" value="#left(arguments.commenterEmail,150)#">
						<cfinvokeargument name="website" value="#left(arguments.commenterWebSite, 255)#">
						<cfinvokeargument name="comments" value="#arguments.comments#">
						<cfinvokeargument name="subscribe" value="#arguments.subscribe#">
						<cfif application.Udf.isLoggedIn()>
							<cfinvokeargument name="overrideModeration" value="true">
						</cfif>
					</cfinvoke>	
							
					<!--- ******** Render email to blog owner and potentially to the post subscribers informing them of a new comment ******** --->

					<!--- Create the main email content --->
					<cfsavecontent variable="contentBody">
					<cfoutput>
						<table cellpadding="5" cellspacing="5" border="0" align="left">
							<tr>
								<td>
									<div id="avatar" style="text-align: center;margin:30px 0 0 0; padding:20px 0 20px 0; width: 100%; height: 100%;">
										<img src="http://www.gravatar.com/avatar/#lcase(hash(lcase(commenterEmail)))#?s=64&amp;r=pg&amp;d=#application.blogHostUrl#/images/defaultAvatar.gif" id="avatar_image" border="0" title="#arguments.commenterName#'s Gravatar" align="left" style="width:80px; height:80px; padding:5px; background:white; border:1px solid ##e4e8af; border-radius: 50%; -moz-border-radius: 50%; -webkit-border-radius: 50%;" />
										<cfif len(arguments.commenterWebSite)><a href="#arguments.commenterWebSite#"></cfif>#arguments.commenterName#<cfif len(arguments.commenterWebSite)></a></cfif>
									</div>
								</td>
							</tr>
							<tr>
								<td colspan="2">
									#(encodeForHTML(arguments.comments))#
								</td>
							</tr>
						</table>
					</cfoutput>
					</cfsavecontent>
							
					<!--- Now that we have the content body, pass it to the render component and render the rest of the email --->
					<cfinvoke component="#RendererObj#" method="renderEmail" returnvariable="emailBody">
						<cfinvokeargument name="email" value="#application.BlogDbObj.getBlogEmail()#">
						<cfinvokeargument name="emailTitle" value="Comment added to #arguments.postTitle#">
						<cfinvokeargument name="emailTitleLink" value="#application.blog.makeLink(arguments.postId)###c#commentId#">
						<cfinvokeargument name="emailDesc" value="#arguments.commenterName# added a comment">
						<cfinvokeargument name="emailBody" value="#contentBody#">
						<cfif application.commentModeration>
							<cfinvokeargument name="callToActionText" value="Approve Comment">
							<!--- The full address (2026-10-22): baseUrl is only the path (eg. /blog), which an email can't open. --->
							<cfinvokeargument name="callToActionLink" value="#application.blogHostUrl#/admin/">
						</cfif>
					</cfinvoke>
							
					<!--- Email the owner of the blog - not about a comment they wrote themselves while signed in (2026-10-22): it is already
					approved, and the email's Approve Comment button made it look as if it wasn't. --->
					<cfif not application.Udf.isLoggedIn()>
					<cfset UtilsObj.mail(
						to=#application.BlogDbObj.getBlogEmail()#,
						subject="New comment made by #arguments.commenterName#",
						body=emailBody)>
					</cfif>
						
					<!--- Send a response back to the client to determine the messages shown in the popup (only when the email went out). --->
					<cfset response[ "adminEmailedNewComment" ] = not application.Udf.isLoggedIn() />
						
					<!--- ************* Render email to all post subscribers informing them of the new comment ************* --->
					<!--- Note: if one of the admins is creating the comment it does not need to be approved. --->
					<cfif not application.BlogOptionDbObj.getBlogModerated() or application.Udf.isLoggedIn()>
						
						<!--- Get all post subscribers --->
						<cfset postSubscribers = application.blog.getSubscriber(postId=arguments.postId, verifiedOnly=true)>
							
						<cfif arrayLen(postSubscribers)>
							
							<!--- Loop through the subscribers --->
							<cfloop from="1" to="#arrayLen(postSubscribers)#" index="i">
								<cfset thisSubscriberEmail = postSubscribers[i]["SubscriberEmail"]>
									
								<!--- Craft the email. We have already created the email content above. --->
								<cfinvoke component="#RendererObj#" method="renderEmail" returnvariable="emailBody">
									<cfinvokeargument name="email" value="#thisSubscriberEmail#">
									<cfinvokeargument name="emailTitle" value="Comment added to #arguments.postTitle#">
									<cfinvokeargument name="emailTitleLink" value="#application.blog.makeLink(arguments.postId)###c#commentId#">
									<cfinvokeargument name="emailDesc" value="#arguments.commenterName# added a comment">
									<cfinvokeargument name="emailBody" value="#contentBody#">
									<cfinvokeargument name="callToActionText" value="View on web">
									<cfinvokeargument name="callToActionLink" value="#application.blog.makeLink(arguments.postId)###c#commentId#">
								</cfinvoke>
							
								<!--- Email the post subscriber. --->
								<cfset UtilsObj.mail(
									to=#thisSubscriberEmail#,
									subject="New comment made by #arguments.commenterName#",
									body=emailBody)>

							</cfloop><!---<cfloop from="1" to="#arrayLen(postSubscribers)#" index="i">--->
					
							<!--- Send a response back to the client to determine the messages shown in the popup --->
							<cfset response[ "newCommentEmailSentToPostSubscribers" ] = true />
										
						</cfif><!---<cfif arrayLen(postSubscribers)>--->
						
					</cfif><!---<cfif not application.BlogOptionDbObj.getBlogModerated() or application.Udf.isLoggedIn()>--->

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

		</cfif><!---<cfif valid>--->
			
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>
		
	</cffunction>
							
	<cffunction name="confirmSubscription" returnFormat="json" output="false" access="remote" 
			hint="Confirms a user subscription to the blog. This is used on the admin interfaces.">
		<cfargument name="email" required="true" default="" hint="Pass in the subscribers email address." />
		<cfargument name="token" required="true" default="" hint="Pass in the user token." />
		
		<!--- Preset the message var --->
		<cfset message = "">
		
		<!--- Set the default response object. --->
		<cfset response = {} />
		<cfset response[ "message" ] = "" />
			
		<!--- The csrftoken logic will not work here as the user is not always logged in. --->
			
		<!--- Confirm the subscription --->
		<cfif len(arguments.email) and len(arguments.token)>
			<cfinvoke component="#application.blog#" method="confirmSubscription" returnVariable="confirmSubscription">
				<cfinvokeargument name="email" value="#arguments.email#">
				<cfinvokeargument name="token" value="#arguments.token#">
			</cfinvoke>
			<cfif confirmSubscription>
				<cfset message = " Thank-you for your confirmation.">
			</cfif>
		</cfif>
			
		<!--- Prepare the response object. --->
		<cfset response[ "message" ] = message />
					
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>

	</cffunction>
					
	<cffunction name="confirmSubscriptionViaToken" returnFormat="json" output="false" access="remote" 
			hint="Confirms a user subscription to the blog. The confirm subscription email is sent out with just the token and an Ajax request is made to confirm the users subscription once the user clicks on the call to action link.">
		<cfargument name="token" required="true" default="" hint="Pass in the subscription token." />
		
		<!--- Preset the message var --->
		<cfset message = "">
		
		<!--- Set the default response object. --->
		<cfset response = {} />
		<cfset response[ "message" ] = "" />
			
		<!--- The csrftoken logic will not work here as the user is not always logged in. --->
			
		<!--- Confirm the subscription --->
		<cfif len(arguments.token)>
			<cfinvoke component="#application.blog#" method="confirmSubscriptionViaToken" returnVariable="confirmSubscription">
				<cfinvokeargument name="token" value="#arguments.token#">
			</cfinvoke>
			<cfif confirmSubscription>
				<cfset message = " Thank-you for your confirmation">
			<cfelse>
				<cfset message = "Subscription record does not exist">
			</cfif>
		<cfelse>
			<cfset message = "Invalid token">
		</cfif>
			
		<!--- Prepare the response object. --->
		<cfset response[ "message" ] = message />
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>

	</cffunction>
								
	<cffunction name="unSubscribe" returnFormat="json" output="false" access="remote" 
			hint="Unsubscribes a user to the blog.">
		<cfargument name="email" required="true" default="" hint="Pass in the subscribers email address." />
		<cfargument name="token" required="true" default="" hint="Pass in the user token." />
		<cfargument name="postId" required="false" default="" hint="Pass in the postId if unsubscribing to a post." />
		
		<!--- Preset the message var --->
		<cfset message = "">
		
		<!--- Set the default response object. --->
		<cfset response = {} />
		<cfset response[ "message" ] = "" />
			
		<!--- The csrftoken logic will not work here as the user is not always logged in. --->
		
		<!--- Unsubscribe from a post.--->
		<cfif len(arguments.postId)>
			<cfinvoke component="#application.blog#" method="unSubscribeFromPost" returnVariable="unSubscribeFromPost">
				<cfinvokeargument name="postId" value="#arguments.postId#">
				<cfinvokeargument name="email" value="#arguments.email#">
			</cfinvoke>
			<cfset message = "You are now usubscribed from this post.">
		</cfif>
			
		<!--- Unsubscribe from the blog --->
		<cfif len(arguments.email) and len(arguments.token)>
			<cfinvoke component="#application.blog#" method="removeSubscriber" returnVariable="unsubscribeBlog">
				<cfinvokeargument name="email" value="#arguments.email#">
				<cfinvokeargument name="token" value="#arguments.token#">
			</cfinvoke>
			<cfif unsubscribeBlog>
				<cfset message = " You are now usubscribed.">
			</cfif>
		</cfif>
			
		<!--- Prepare the response object. --->
		<cfset response[ "message" ] = message />
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>

	</cffunction>
				
	<!---****************************************************************************************************
		Reactions
	******************************************************************************************************--->
				
	<!--- Reaction grid functions --->
				
	<cffunction name="getReactionsForGrid" access="remote" returnformat="json" output="false" 
		hint="Returns a json array to populate the recent comments grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either kendo or jsGrid">			
			
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="anonymousUserId" required="no" default="">
		<cfargument name="title" required="no" default="">
		<cfargument name="httpUserAgent" required="no" default="">
		<cfargument name="ipAddressId" required="no" default="">
		<cfargument name="ipAddress" required="no" default="">
		<cfargument name="helpful" required="no" default="">
		<cfargument name="unhelpful" required="no" default="">
		<cfargument name="date" required="no" default="">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = false>
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will set a 403 status code and abort the page if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<cfinvoke component="#application.blog#" method="getReactions" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->
			<cfif arguments.anonymousUserId neq ''>
				<cfinvokeargument name="anonymousUserId" value="#arguments.anonymousUserId#"/>
			</cfif>
			<cfif arguments.title neq ''>
				<cfinvokeargument name="postTitle" value="#arguments.title#"/>
			</cfif>
			<cfif arguments.httpUserAgent neq ''>
				<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#"/>
			</cfif>
			<cfif arguments.ipAddressId neq ''>
				<cfinvokeargument name="ipAddressId" value="#arguments.ipAddressId#"/>
			</cfif>
			<cfif arguments.ipAddress neq ''>
				<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#"/>
			</cfif>
			<cfif arguments.helpful neq ''>
				<cfinvokeargument name="helpful" value="#arguments.helpful#"/>
			</cfif>
			<cfif arguments.unhelpful neq ''>
				<cfinvokeargument name="unhelpful" value="#arguments.unhelpful#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
					
	<cffunction name="deleteReactionViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Deletes a reaction via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="postRatingId" hint="Pass in the Post Rating Id" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort further processing --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost,ReleasePost')>
			
		<cftransaction>

			<!--- Update the database. --->
			<!--- Load the post rating entity. --->
			<cfset PostRatingDbObj = entityLoad("PostRating", { PostRatingId = arguments.postRatingId }, "true" )>
			<!--- Remove the postRef so that we don't get a constraint errors --->
			<cfset PostRatingDbObj.setPostRef(javaCast("null",""))>
			<!--- And the anonymous user ref --->
			<cfset PostRatingDbObj.setAnonymousUserRef(javaCast("null",""))>
			<!--- Delete it --->
			<cfset EntityDelete(PostRatingDbObj)>

		</cftransaction>

		<!--- Set the response --->
		<cfset response = arguments.postRatingId>
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
	</cffunction>
					
	<cffunction name="getReactionVisitorId" access="private" returnType="string" output="false"
			hint="Returns the anonymous user id of the current visitor, or an empty string if the visitor is not known. The visitor is identified by the gauid cookie that the visitor tracking sets. The id must come from the cookie and not from the page: the post html is cached and shared by all visitors, so anything that is embedded in it belongs to whoever viewed the post first.">

		<cfif structKeyExists(cookie, "gauid") and isNumeric(cookie.gauid) and not isNull(entityLoadByPK("AnonymousUser", cookie.gauid))>
			<cfreturn int(cookie.gauid)>
		</cfif>

		<cfreturn "">
	</cffunction>

	<cffunction name="getPostReactionState" access="remote" returnformat="json" output="false"
			hint="Returns the total likes and dislikes of a post and how the current visitor voted. This is requested by the post page after it loads, as the post html is cached and can't contain anything that is specific to the visitor.">
		<cfargument name="postId" required="true">

		<cfset var response = { "likes": 0, "dislikes": 0, "myVote": "" }>
		<cfset var visitorId = "">
		<cfset var myVotes = "">

		<cfif isNumeric(arguments.postId)>
			<cfset response["likes"] = application.blog.getPostLikeCount(arguments.postId)>
			<cfset response["dislikes"] = application.blog.getPostDislikeCount(arguments.postId)>
			<!--- How did this visitor vote? myVotes returns a list separated by an underscore (likes_dislikes) --->
			<cfset visitorId = getReactionVisitorId()>
			<cfif len(visitorId)>
				<cfset myVotes = application.blog.myVotes(arguments.postId, visitorId)>
				<cfif listGetAt(myVotes, 1, "_") gt 0>
					<cfset response["myVote"] = "like">
				<cfelseif listGetAt(myVotes, 2, "_") gt 0>
					<cfset response["myVote"] = "dislike">
				</cfif>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response and send it back to the client. --->
			<cfreturn serializeJSON( response )>
		</cfif>

	</cffunction>

	<cffunction name="saveReaction" access="remote" returnformat="json" output="false"
			hint="Saves a user reaction (like/dislike). The visitor is identified by the gauid cookie and not by the anonymousUserId argument, which is only accepted for the pages that were cached before this change (the post html is cached, and the id in it belongs to whoever viewed the post first).">
		<cfargument name="postId" required="true">
		<cfargument name="anonymousUserId" required="false" default="" hint="Ignored. The visitor comes from the gauid cookie.">
		<cfargument name="selectedId" default="" />

		<cfset var success = 0>
		<cfset var visitorId = getReactionVisitorId()>

		<!--- Set the default response object. --->
		<cfset response = {} />

		<!--- Save the vote if we know who is voting. --->
		<cfif len(visitorId) and isNumeric(arguments.postId) and listFindNoCase("like,dislike", arguments.selectedId)>
			<cfinvoke component="#application.blog#" method="saveReaction" returnvariable="success">
				<cfinvokeargument name="postId" value="#arguments.postId#">
				<cfinvokeargument name="anonymousUserId" value="#visitorId#">
				<cfinvokeargument name="selectedId" value="#arguments.selectedId#">
			</cfinvoke>
		</cfif>
			
		<!--- Create a JSON response to send back to the client --->
		<cfif success eq 1>
			<!--- Note: using cfset response["data"] = x will create a handle. We don't want this here --->
			<cfif arguments.selectedId eq 'like'>
				<cfset response = [{ "like": 1, "dislike": 0 }]>
			<cfelse>
				<cfset response = [{ "like": 0, "dislike": 1 }]>
			</cfif>
		<cfelse>
			<cfset response = [{ "like": 0, "dislike": 0 }]>
		</cfif>
				
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
				
	</cffunction>
			
	<!---****************************************************************************************************
		Subscriber Grid
	******************************************************************************************************--->
			
	<cffunction name="getSubscribersForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the subscribers grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="false" default="kendo" />
		<cfargument name="ipAddressId" required="false" default="" />
		<cfargument name="subscriberName" required="false" default="" />
		<cfargument name="subscriberEmail" required="false" default="" />
		<cfargument name="subscriberToken"  required="false" default="" />
		<cfargument name="subscribeAll" required="false" default="true" />
		<cfargument name="verifiedOnly" required="false" default="" />
		<!--- This is a duplicate of verified only and used by the grid which requires the actual db column name --->
		<cfargument name="subscriberVerified" required="false" default="" />
		<!--- Unused argument needed after CF update in June of 2025 --->
		<cfargument name="date" required="false" default="" />
			
		<!--- If the SubscriberVerified column is filled out, change the value of the verifiedOnly local variable --->
		<cfif len(arguments.subscriberVerified)>
			<cfset arguments.verifiedOnly = arguments.subscriberVerified>
		</cfif>
		
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn false>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( false ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditSubscriber')>
			
		<!--- Get the categories, don't  use the cached values. --->
		<cfinvoke component="#application.blog#" method="getSubscriber" returnvariable="Data">
			<cfinvokeargument name="ipAddressId" value="#arguments.ipAddressId#">
			<cfinvokeargument name="subscriberName" value="#arguments.subscriberName#">
			<cfinvokeargument name="subscriberEmail" value="#arguments.SubscriberEmail#">
			<cfinvokeargument name="subscriberToken" value="#arguments.subscriberToken#">
			<cfinvokeargument name="verifiedOnly" value="#arguments.verifiedOnly#">
			<cfinvokeargument name="subscribeAll" value="#arguments.subscribeAll#">
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="updateSubscriberViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the subscriber via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="subscriberId" type="numeric" required="no">
		<cfargument name="subscriberEmail" type="string" required="no">
		<cfargument name="subscriberToken" type="string" required="no">
		<cfargument name="subscriberVerified" type="boolean" required="no">
		<cfargument name="subscribeAll" type="boolean" required="no">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- See if the subscriber email and token exists before proceeding. --->
		<cfinvoke component="#application.blog#" method="getSubscriber" returnvariable="getSubscriberEmail">
			<cfinvokeargument name="subscriberEmail" value="#arguments.subscriberEmail#">
		</cfinvoke>
		<cfinvoke component="#application.blog#" method="getSubscriber" returnvariable="getSubscriberToken">
			<cfinvokeargument name="subscriberToken" value="#arguments.subscriberToken#">
		</cfinvoke>
			
		<!--- Validate the data --->
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Invalid token</li>">
		</cfif>
		<cfif arrayLen(getSubscriberToken) and getSubscriberToken[1]["SubscriberToken"] neq arguments.subscriberToken>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Subscriber token does not match</li>">
		</cfif>
			
		<cfif not error>
			
			<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
			<cfset secureFunction('EditSubscriber')>

			<cftransaction>

				<!--- Update the database. --->
				<!--- Load the entity. --->
				<cfset SubscriberDbObj = entityLoad("Subscriber", { SubscriberId = arguments.subscriberId }, "true" )>
				<!--- Set the values --->
				<cfset SubscriberDbObj.setSubscriberEmail( arguments.subscriberEmail )>
				<cfset SubscriberDbObj.setSubscriberToken( arguments.subscriberToken )>
				<cfset SubscriberDbObj.setSubscriberVerified( arguments.subscriberVerified )>
				<!--- Save it --->
				<cfset EntitySave(SubscriberDbObj)>

			</cftransaction>

			<!---For the jsGrid, we need to return: updatedItem: 1 (ie the primary key)--->
			<cfset response[ "success" ] = true />
			<cfset response[ "subscriberId" ] = arguments.subscriberId />
		
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->
			<cfset response[ "success" ] = false />
			<cfset response[ "errorMessage" ] = errorMessage />
		</cfif>
		
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
		
	</cffunction>
				
	<cffunction name="deleteSubscriberViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the comments grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="yes" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort further processing --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost,ReleasePost')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>

		<cftransaction>
			<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- Extract the needed fields. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="commentId" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset commentId = i['CommentId']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the comment entity. --->
				<cfset CommentDbObj = entityLoad("Comment", { CommentId = commentId }, "true" )>
				<!--- Set the remove column to true --->
				<cfset CommentDbObj.setRemove(1)>
				<!--- Save it --->
				<cfset EntitySave(CommentDbObj)>

			</cfloop>

		</cftransaction>
								
    	<cfset jsonString = []><!--- '{"data":null}', --->
    	
		<cfreturn jsonString>
	</cffunction>
				
	<cffunction name="deleteSubscriberViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Deletes a comment via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="subscriberId" hint="Pass in the subscriberId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort processing --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditSubscriber')>
			
			<cftransaction>
				<!--- Delete the association to the blog table. --->
				<!--- Load the comment entity. --->
				<cfset SubscriberDbObj = entityLoad("Subscriber", { SubscriberId = arguments.subscriberId }, "true" )>
				<!--- Remove the reference sin order to delete this record --->
				<cfset SubscriberDbObj.setBlogRef(javaCast("null",""))>
				<cfset SubscriberDbObj.setPostRef(javaCast("null",""))>
				<!--- Save it --->
				<cfset EntitySave(SubscriberDbObj)>
			</cftransaction>
					
			<cftransaction>
				<!--- Now, in a different transaction, delete the record. --->
				<!--- Load the entity. --->
				<cfset SubscriberDbObj = entityLoad("Subscriber", { SubscriberId = arguments.subscriberId }, "true" )>
				<!--- Delete it --->
				<cfset EntityDelete(SubscriberDbObj)>
			</cftransaction>
			<!--- Set the response --->
			<cfset response = arguments.subscriberId>
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
				
	</cffunction>
							
	<!---*****************************************************************************************************
		Comment grid functions
	******************************************************************************************************--->
				
	<cffunction name="getCommentsForGrid" access="remote" returnformat="json" output="false" 
		hint="Returns a json array to populate the recent comments grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		<cfargument name="commentType" required="yes" default="all" hint="Either recent or all">
			
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="commenterFullName" required="no" default="">
		<cfargument name="commenterFullNameLike" required="no" default="">
		<cfargument name="postTitle" required="no" default="">
		<cfargument name="datePosted" required="no" default="">
		<cfargument name="comment" required="no" default="">
		<cfargument name="approved" required="no" default="">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = false>
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will set a 403 status code and abort the page if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<cfinvoke component="#application.blog#" method="getComments" returnvariable="Data">
			<!--- Get either the new comments (where approved is either 0 or null) or all comments depending upon the comment type URL arg. --->
			<cfif arguments.commentType eq 'recentComments'>
				<!--- Get recent comments --->
				<cfinvokeargument name="new" value="1"/>
			</cfif>
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->
			<cfif arguments.CommenterFullNameLike neq ''>
				<cfinvokeargument name="commenterFullNameLike" value="#arguments.commenterFullName#"/>
			</cfif>
			<cfif arguments.PostTitle neq ''>
				<cfinvokeargument name="postTitle" value="#arguments.postTitle#"/>
			</cfif>
			<cfif arguments.DatePosted neq ''>
				<cfinvokeargument name="datePosted" value="#arguments.datePosted#"/>
			</cfif>
			<cfif arguments.Comment neq ''>
				<cfinvokeargument name="commentLike" value="#arguments.comment#"/>
			</cfif>
			<cfif arguments.approved neq ''>
				<cfinvokeargument name="approved" value="#arguments.approved#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
			
	<cffunction name="updateCommentViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the comments via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="commentId" type="numeric" required="yes" 
			hint="Pass in the commentId">
		<cfargument name="approved" type="boolean" required="yes"
			hint="Is this comment approved?">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort further processing --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost')>

		<cftransaction>

			<!--- Update the database. --->
			<!--- Load the comment entity. --->
			<cfset CommentDbObj = entityLoad("Comment", { CommentId = arguments.commentId }, "true" )>
			<!--- Set the approved column --->
			<cfset CommentDbObj.setApproved( "#arguments.approved#" )>
			<!--- Save it --->
			<cfset EntitySave(CommentDbObj)>

		</cftransaction>
				
		<!--- Email the post subscribers if the comment was approved --->
		<cfif arguments.approved>

			<!--- Get the commentId from the entity --->
			<cfset commentId = arguments.commentId>
			<!--- Get the comment. The comment table will have the postId --->
			<cfset getComment = application.blog.getComment(commentId=commentId)>
			<!--- Get all post subscribers --->
			<cfset getPostSubscribers = application.blog.getSubscriber(postId=getComment[1]["PostId"], verifiedOnly=true)>

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
				<cfset UtilsObj.mail(
					to=#emailTo#,
					subject="Message sent via #application.BlogDbObj.getBlogTitle()#",
					body=postSubscriberEmail)>

			</cfloop>
						
		</cfif>
				
		<!--- For the jsGrid, we need to return: updatedItem: 1 (ie the commentId)--->
   
		<!--- Set the response --->
		<cfset response = arguments.commentId>
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
		
	</cffunction>
				
	<cffunction name="deleteCommentViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the comments grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="yes" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort further processing --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost,ReleasePost')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>

		<cfset local.removedFromPostIds = []>
		<cftransaction>
			<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- Extract the needed fields. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="commentId" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset commentId = i['CommentId']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the comment entity. --->
				<cfset CommentDbObj = entityLoad("Comment", { CommentId = commentId }, "true" )>
				<!--- Set the remove column to true --->
				<cfset CommentDbObj.setRemove(1)>
				<!--- Save it --->
				<cfset EntitySave(CommentDbObj)>
				<!--- The post whose cached comments must be cleared (2026-10-14). --->
				<cfif not isNull(CommentDbObj.getPostRef())>
					<cfset arrayAppend(local.removedFromPostIds, CommentDbObj.getPostRef().getPostId())>
				</cfif>

			</cfloop>

		</cftransaction>

		<!--- Clear the cached comments of those posts (2026-10-14), or visitors kept seeing a deleted comment until the cache expired. --->
		<cfloop array="#local.removedFromPostIds#" index="local.removedFromPostId">
			<cftry>
				<cfset application.blog.flushGalaxieCache(type = "comment", postId = local.removedFromPostId)>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfloop>
								
    	<cfset jsonString = []><!--- '{"data":null}', --->
    	
		<cfreturn jsonString>
	</cffunction>
				
	<cffunction name="deleteCommentViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Deletes a comment via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="commentId" hint="Pass in the commentId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort further processing --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost,ReleasePost')>
			
		<cftransaction>

			<!--- Update the database. --->
			<!--- Load the comment entity. --->
			<cfset CommentDbObj = entityLoad("Comment", { CommentId = arguments.commentId }, "true" )>
			<!--- Set the remove column to true --->
			<cfset CommentDbObj.setRemove(1)>
			<!--- Save it --->
			<cfset EntitySave(CommentDbObj)>

		</cftransaction>

		<!--- Clear the post's cached comments (2026-10-14), or visitors kept seeing the deleted comment until the cache expired. --->
		<cftry>
			<cfif not isNull(CommentDbObj.getPostRef())>
				<cfset application.blog.flushGalaxieCache(type = "comment", postId = CommentDbObj.getPostRef().getPostId())>
			</cfif>
			<cfcatch type="any"></cfcatch>
		</cftry>

		<!--- Set the response --->
		<cfset response = arguments.commentId>
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
	</cffunction>
			
	<cffunction name="saveComment" access="remote" returnformat="json" output="false" 
			hint="Saves data from the comment detail page.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="action" hint="Either insert or update" default="">
		<cfargument name="commentId" type="numeric" required="true">
		<cfargument name="commenter" type="string" required="true">
		<cfargument name="commenterEmail" type="string" required="true">
		<cfargument name="commenterWebsite" type="string" required="true">
		<cfargument name="commenterIp" type="string" required="true">
		<cfargument name="commenterHttpUserAgent" type="string" required="true">
		<cfargument name="comment" type="string" required="true">
		<cfargument name="approved" type="boolean" required="false">
		<cfargument name="remove" type="boolean" required="false">
		<cfargument name="spam" type="boolean" required="false">
		<cfargument name="subscribe" type="boolean" required="false">
		<cfargument name="moderated" type="boolean" required="false">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = false>
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost')>
		
		<cfif arguments.action eq 'update'>
			<!--- Only admins can update this. --->
			<cfif application.Udf.isLoggedIn()>
				
				<!--- Validate the data --->
				<cfif not isValid("email", arguments.commenterEmail)>
					<cfset error = true>
					<cfset errorMessage = "<li>Email is not valid</li>">
				</cfif>
				<cfif len(commenterWebsite) and not isValid("url", arguments.commenterWebsite)>
					<cfset error = true>
					<cfset errorMessage = errorMessage & "<li>Website is not valid</li>">
				</cfif>
				<cfif not len(comment)>
					<cfset error = true>
					<cfset errorMessage = errorMessage & "<li>Comment is required</li>">
				</cfif>
						
				<cfif not error>
					<!--- Update the comment --->
					<cfinvoke component="#application.blog#" method="saveComment">
						<cfinvokeargument name="commentId" value="#arguments.commentId#">
						<cfinvokeargument name="name" value="#arguments.commenter#">
						<cfinvokeargument name="email" value="#arguments.commenterEmail#">
						<cfinvokeargument name="website" value="#arguments.commenterWebsite#">
						<cfinvokeargument name="ipAddress" value="#arguments.commenterIp#">
						<cfinvokeargument name="userAgent" value="#arguments.commenterHttpUserAgent#">
						<cfinvokeargument name="comments" value="#arguments.comment#">
						<cfinvokeargument name="approved" value="#arguments.approved#">
						<cfinvokeargument name="remove" value="#arguments.remove#">
						<cfinvokeargument name="spam" value="#arguments.spam#">
						<cfinvokeargument name="subscribe" value="#arguments.subscribe#">
						<cfinvokeargument name="moderated" value="#arguments.moderated#">
					</cfinvoke>
					<!--- Set the success resopnse --->
					<cfset response[ "success" ] = true />
				</cfif><!---<cfif not error>--->
			<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
			</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		</cfif><!---<cfif arguments.action eq 'update'>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>

		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	

	</cffunction>
				
	<!---//*****************************************************************************************
		Email functions
	//******************************************************************************************--->
			
	<cffunction name="sendPostEmailToSubscribers" access="remote" returnformat="json" output="false"
			hint="Allows new posts to be emailed to the subscribers via ajax functions. Used when an admin approves a post using the grids.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="postId" required="yes">
		
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = false>
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
				
		<cfset secureFunction('ReleasePost')>
			
		<cfinvoke component="#application.blog#" method="sendPostEmailToSubscribers" returnvariable="emailSent">
			<cfinvokeargument name="postId" value="#arguments.postId#"/>
		</cfinvoke>
			
		<cfset response[ "emailSent" ] = emailSent />
			
		<!--- Set the response --->
		<cfset response = "sucess">
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
	
	</cffunction>
				
	<!---*****************************************************************************************************
		Theme functions
	******************************************************************************************************--->
				
	<!--- Save the users theme preference. --->
	<cffunction name="getTheme" access="public" returntype="stuct" hint="Allows the users to change the blogs theme.">
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
				
	<!---*****************************************************************************************************
		Theme grid functions
	******************************************************************************************************--->
				
	<cffunction name="getThemesForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the recent comments grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		<cfargument name="commentType" required="yes" default="all" hint="Either recent or all">
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="themeName" required="no" default="">
		<cfargument name="kendoTheme" required="no" default="">
		<cfargument name="darkTheme" required="no" default="">
		<cfargument name="selectedTheme" required="no" default="">
		<cfargument name="useTheme" required="no" default="">
		<cfargument name="modernThemeStyle" required="no" default="">	
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Abort the process if the token is not validated. --->
			<!--- Set the response --->
			<cfset response = false>
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will set a 403 status code and abort the page if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<cfinvoke component="#application.blog#" method="getThemes" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->
			<cfif arguments.themeName neq ''>
				<cfinvokeargument name="themeName" value="#arguments.themeName#"/>
			</cfif>
			<cfif arguments.kendoTheme neq ''>
				<cfinvokeargument name="kendoTheme" value="#arguments.kendoTheme#"/>
			</cfif>
			<cfif arguments.useTheme neq ''>
				<cfinvokeargument name="useTheme" value="#arguments.useTheme#"/>
			</cfif>
			<cfif arguments.selectedTheme neq ''>
				<cfinvokeargument name="selectedTheme" value="#arguments.selectedTheme#"/>
			</cfif>
			<cfif arguments.modernThemeStyle neq ''>
				<cfinvokeargument name="modernThemeStyle" value="#arguments.modernThemeStyle#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="updateCommentViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the comments grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="no" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>
		<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 
		
		<cftransaction>
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- We are only looking for the CommentId. If we were editing other fields, use the column name and extract them. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="commentId" default="" type="any">
				<cfparam name="approved" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset commentId = i['CommentId']>
					<cfset approved = i['Approved']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the comment entity. --->
				<cfset CommentDbObj = entityLoad("Comment", { CommentId = commentId }, "true" )>
				<!--- Set the approved column --->
				<cfset CommentDbObj.setApproved( "#approved#" )>
				<!--- Save it --->
				<cfset EntitySave(CommentDbObj)>
					
				<!--- Email the post subscribers if the comment was approved --->
				<cfif arguments.approved>

					<!--- Get the commentId from the entity --->
					<cfset commentId = arguments.commentId>
					<!--- Get the comment. The comment table will have the postId --->
					<cfset getComment = application.blog.getComment(commentId=commentId)>
					<!--- Get all post subscribers --->
					<cfset getPostSubscribers = application.blog.getSubscriber(postId=getComment[1]["PostId"], verifiedOnly=true)>

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
						<cfset UtilsObj.mail(
							to=#emailTo#,
							subject="Message sent via #application.BlogDbObj.getBlogTitle()#",
							body=postSubscriberEmail)>

					</cfloop>
				
				</cfif><!---<cfif arguments.approved>--->

			</cfloop><!---<cfloop array="#thisStruct#" index="i">--->

		</cftransaction>
    
    	<cfset jsonString = []><!--- '{"data":null}', --->
    
    	<cfreturn jsonString>
		
	</cffunction>
			
	<cffunction name="updateThemeViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the comments via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="themeId" type="string" required="yes" hint="Pass in the themeId">
		<cfargument name="themeSettingId" type="string" required="yes">
		<cfargument name="modernThemeStyle" type="string" required="no">
		<cfargument name="useTheme" type="string" required="no">
		<cfargument name="selectedTheme" type="string" required="no">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Inavalid Token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('editTheme')>
			
		<!--- Was this theme selected? The grids send true or false. There can only be one selected theme. --->
		<cfset isSelectedTheme = structKeyExists(arguments, "selectedTheme") and isBoolean(arguments.selectedTheme) and arguments.selectedTheme>

		<cftransaction>
			<!--- If this theme was selected, deselect all of the other themes first (the theme settings form does the same). --->
			<cfif isSelectedTheme>
				<cfquery name="deselectAllThemes" dbtype="hql">
					UPDATE Theme
					SET SelectedTheme = ''
					WHERE SelectedTheme = 1
				</cfquery>
			</cfif>
			<!--- Load the theme entity. --->
			<cfset ThemeDbObj = entityLoadByPK("Theme", arguments.themeId)>
			<!--- Load the theme setting entity --->
			<cfset ThemeSettingDbObj = entityLoad("ThemeSetting", { ThemeSettingId = arguments.themeSettingId }, "true" )>

			<!--- Set the values. 5.0 (2026-10-19): modernThemeStyle and useTheme are optional - a grid that leaves one out no longer
			fails the save ("Element MODERNTHEMESTYLE is undefined"); a value that isn't sent is left as it is. --->
			<cfif structKeyExists(arguments, "modernThemeStyle") and isBoolean(arguments.modernThemeStyle) and arguments.modernThemeStyle>
				<cfset ThemeSettingDbObj.setBreakpoint(0)>
				<!--- Set the content width to 50 if it was not already been changed. The Kendo grid does not send the contentWidth. --->
				<cfif structKeyExists(arguments, "contentWidth") and arguments.contentWidth eq '66'>
					<cfset ThemeSettingDbObj.setContentWidth('50')>
				</cfif>
			</cfif>
			<cfset ThemeDbObj.setSelectedTheme(isSelectedTheme)>
			<cfif structKeyExists(arguments, "useTheme") and isBoolean(arguments.useTheme)>
				<cfset ThemeDbObj.setUseTheme(arguments.useTheme)>
			</cfif>				
			<!--- Save the entities --->
			<cfset EntitySave(ThemeSettingDbObj)>
			<cfset EntitySave(ThemeDbObj)>
		</cftransaction>
			
		<!--- Set the response vars --->
		<cfset response[ "success" ] = true />
		<cfset response[ "themeId" ] = ThemeDbObj.getThemeId() />
    
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
		
	</cffunction>
				
	<cffunction name="saveTheme" access="remote" returnformat="json" output="yes" 
			hint="Saves the theme details.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="themeId" required="no" default="" hint="When editting an existing theme, pass in the theme Id">
		<cfargument name="themeSettingId" required="no" default="" hint="When editting an existing theme, pass in the themeSettingId">
		<cfargument name="theme" required="no" default="" hint="Pass in the theme">
		<cfargument name="kendoThemeId" required="yes" default="" hint="Pass in the Kendo theme Id">
		<cfargument name="useTheme" required="no" default="">
		<cfargument name="selectedTheme" required="no" default="">
		<cfargument name="darkTheme" required="no" default="">
		<cfargument name="themeStyle" required="no" default="modern">
		<cfargument name="themeGenre" required="no" default="">
		<!--- Fonts (note: these are form names serialized by the UI and the form is very long). --->
		<cfargument name="blogNameFontDropdown" required="no" default="" hint="Derived from the BlogNameFontRef column">
		<cfargument name="menuFontDropdown" required="no" default="" hint="Derived from the MenuFontRef column">
		<cfargument name="bodyFontDropdown" required="no" default="" hint="Derived from the FontRef column">
		<!--- Font arguments that are not named for the UI (used by the newTheme function) --->
		<cfargument name="blogNameFontRef" required="no" default="" hint="Derived from the BlogNameFontRef column">
		<cfargument name="menuFontRef" required="no" default="" hint="Derived from the MenuFontRef column">
		<cfargument name="fontRef" required="no" default="" hint="Derived from the FontRef column">
		<!--- Font sizes --->
		<cfargument name="fontSize" required="no" hint="14">
		<cfargument name="fontSizeMobile" required="no" hint="12">
		<!--- Containers --->
		<cfargument name="contentWidth" required="no" default="66">
		<cfargument name="mainContainerWidth" required="no" default="66">	
		<cfargument name="sideBarContainerWidth" required="no" default="34">
		<cfargument name="siteOpacity" required="no" default="93">
		<!--- Header HTML --->
		<cfargument name="customHeaderHtmlCode" required="no" default="">
		<cfargument name="applyCustomHeaderHtmlAcrossThemes" required="no" default="">
		<!--- Favicon --->
		<cfargument name="favIconHtmlCode" required="no" default="">
		<cfargument name="applyFavIconToAllThemes" required="no" default="">
		<!--- Logos --->
		<cfargument name="logoImage" required="no" default="">
		<cfargument name="logoImageMobile" required="no" default="">
		<cfargument name="logoMobileWidth" required="no" default="60">
		<cfargument name="logoPaddingLeft" required="no" default="10">
		<cfargument name="defaultLogoImageForSocialMediaShare" required="no" default="">
		<!--- Backgrounds --->
		<cfargument name="includeBackgroundImages" required="no" default="10">
		<cfargument name="blogBackgroundImage" required="no" default="">
		<cfargument name="blogBackgroundImageMobile" required="no" default="">
		<cfargument name="BlogBackgroundImagePosition" required="no" default="center center">
		<cfargument name="BlogBackgroundImageRepeat" required="no" default="no-repeat">
		<cfargument name="BlogBackgroundColor" required="no" default="">
		<!--- Title --->
		<cfargument name="displayBlogName" required="no" default="">
		<cfargument name="blogNameTextColor" required="no" default="whitesmoke">
		<cfargument name="blogNameFontSize" required="no" default="28">
		<cfargument name="blogNameFontSizeMobile" required="no" default="20">
		<!--- Header --->
		<cfargument name="headerBackgroundColor" required="no" default="true">
		<cfargument name="headerBackgroundImage" required="no" default="">
		<cfargument name="headerBodyDividerImage" required="no" default="">
		<cfargument name="alignBlogMenuWithBlogContent" required="no" default="true">
		<cfargument name="stretchHeaderAcrossPage" required="no" default="">
		<!--- Menu --->
		<cfargument name="menuBackgroundImage" required="no" default="true">
		<cfargument name="coverKendoMenuWithMenuBackgroundImage" required="no" default="true">
		<cfargument name="topMenuAlign" required="no" default="left">
		<!--- Footer --->
		<cfargument name="footerImage" required="no" default="">
		<!--- Content related variables --->
		<!--- Content templates: navigationMenu, aboutWindow, bioWindow, downloadWindow, downloadPod, subscribePod, cfblogsFeedPod, recentPostsPod, recentCommentsPod, categoriesPod, monthlyArchivesPod, calendarPod, compositeFooter. The desktop and mobile code, along with the theme selections and revert are all on a separate editor interface --->
		<!--- The following are global and are not specific to the device --->
		<cfargument name="navigationMenuEnable" default="true">
		<cfargument name="aboutWindowEnable" default="true">
		<cfargument name="bioWindowEnable" default="true">
		<cfargument name="downloadWindowEnable" default="true">
		<cfargument name="downloadPodEnable" default="true">
		<cfargument name="subscribePodEnable" default="true">
		<cfargument name="cfblogsFeedPodEnable" default="true">
		<cfargument name="recentPostsPodEnable" default="true">
		<cfargument name="recentCommentsPodEnable" default="true">
		<cfargument name="categoriesPodEnable" default="true">
		<cfargument name="monthlyArchivesPodEnable" default="true"> 
		<cfargument name="blogPostCalendarPodEnable" default="true">
		<cfargument name="upcomingEventsPodEnable" default="true">
		<cfargument name="compositeFooterEnable" default="true">
		<!--- Tail end scripts --->
		<cfargument name="customFooterHtmlCode" default="">
		<cfargument name="applyCustomFooterHtmlToAllThemes"  default="">
			
		<!--- Invoke the stringUtils object to send the proper file path for theme related images. By design, the theme image locations are only using part of the file path starting from /images. This was initially done as I wanted to keep the theme images from using specific domain and blog path information. This simplifies the logic when installing the blog and allows the blog to be more portable from server to server. However, we need this information when using the editors and the full paths will be sent in. We need to remove the path info here. I may revisit this decision in future editions. 

		We are also using the sanitizeStrForDbForDb to sanitize the attach strings that we are using to bypass ColdFusions Global Security. All of the forms that use the code mirror editor are being sanitized below --->
		<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
		
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = false>
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<!--- Handle font args from the UI. These were named via the UI as the form is serialized and is very long) --->
		<cfif len(arguments.blogNameFontDropdown)>
			<cfset blogNameFontId = arguments.blogNameFontDropdown>
		</cfif>
		<cfif len(arguments.menuFontDropdown)>
			<cfset menuFontId = arguments.menuFontDropdown>
		</cfif>
		<cfif len(arguments.bodyFontDropdown)>
			<cfset fontId = arguments.bodyFontDropdown>
		</cfif>

		<!--- Handle arguments coming from the new theme function (and other potential new functions) --->
		<cfif len(arguments.blogNameFontRef)>
			<cfset blogNameFontId = arguments.blogNameFontRef>
		</cfif>
		<cfif len(arguments.menuFontRef)>
			<cfset menuFontId = arguments.menuFontRef>
		</cfif>
		<cfif len(arguments.fontRef)>
			<cfset fontId = arguments.fontRef>
		</cfif>

		<!--- The folowing four args are checkboxes and will not come through unless clicked --->
		<cfif len(arguments.useTheme)>
			<cfset useTheme = true>
		<cfelse>
			<cfset useTheme = false>
		</cfif>

		<cfif len(arguments.selectedTheme)>
			<cfset selectedTheme = true>
		<cfelse>
			<cfset selectedTheme = false>
		</cfif>

		<cfif len(arguments.darkTheme)>
			<cfset darkTheme = true>
		<cfelse>
			<cfset darkTheme = false>
		</cfif>

		<cfif len(stretchHeaderAcrossPage)>
			<cfset stretchHeaderAcrossPage = true>
		<cfelse>
			<cfset stretchHeaderAcrossPage = false>
		</cfif>

		<cfif len(applyFavIconToAllThemes)>
			<cfset applyFavIconToAllThemes = true>
		<cfelse>
			<cfset applyFavIconToAllThemes = false>
		</cfif>
			
		<cfif len(applyCustomHeaderHtmlAcrossThemes)>
			<cfset applyCustomHeaderHtmlAcrossThemes = true>
		<cfelse>
			<cfset applyCustomHeaderHtmlAcrossThemes = false>
		</cfif>
			
		<cfif len(applyCustomFooterHtmlToAllThemes)>
			<cfset applyCustomFooterHtmlToAllThemes = true>
		<cfelse>
			<cfset applyCustomFooterHtmlToAllThemes = false>
		</cfif>

		<!--- Create the themeAlias. This is always done as the user may have changed the theme name --->
		<cfset themeAlias = application.blog.makeAlias(arguments.theme)>
		
		<cftransaction>

			<!--- First, if a theme was selected, deselect any other selected themes. There can only be on selected theme. --->
			<cfif selectedTheme>
				<cfquery name="deselectAllThemes" dbtype="hql">
					UPDATE Theme
					SET SelectedTheme = ''
					WHERE SelectedTheme = 1
				</cfquery>
			</cfif>

			<!--- Second, deal with settings that can be applied to all themes. --->
			<cfif len(arguments.favIconHtmlCode)>
				<!--- Sanitize the form value --->
				<cfset sanitizedFavIconHtml = StringUtilsObj.sanitizeStrForDb(arguments.favIconHtmlCode)>
			</cfif>
			<!--- If the applyFavIconToAllThemes argument is set, apply the favorite icon string across all themes. --->
			<cfif applyFavIconToAllThemes and len(arguments.favIconHtmlCode)>
				<!--- Save it --->
				<cfquery name="updateTheme" dbtype="hql">
					UPDATE ThemeSetting
					SET FavIconHtml = <cfqueryparam value="#sanitizedFavIconHtml#" cfsqltype="cf_sql_longvarchar">,
					FavIconHtmlApplyAcrossThemes = 1
				</cfquery>
			</cfif>
			<cfif not applyFavIconToAllThemes>
				<cfquery name="updateTheme" dbtype="hql">
					UPDATE ThemeSetting
					SET FavIconHtmlApplyAcrossThemes = 0
				</cfquery>
			</cfif>
			<cfif len(arguments.customHeaderHtmlCode)>
				<!--- Sanitize the custom header --->
				<cfset sanitizedCustomHeaderHtml = StringUtilsObj.sanitizeStrForDb(arguments.customHeaderHtmlCode)>
			</cfif>
			<!--- If the applyCustomHeaderHtmlToAllThemes argument is set, apply the custom header HTML string across all themes. --->
			<cfif applyCustomHeaderHtmlAcrossThemes and len(arguments.customHeaderHtmlCode)>
				<!--- Save it --->
				<cfquery name="updateTheme" dbtype="hql">
					UPDATE ThemeSetting
					SET CustomHeaderHtml = <cfqueryparam value="#sanitizedCustomHeaderHtml#" cfsqltype="cf_sql_longvarchar">,
					CustomHeaderHtmlApplyAcrossThemes = 1
				</cfquery>
			</cfif>
			<cfif not applyCustomHeaderHtmlAcrossThemes>
				<cfquery name="updateTheme" dbtype="hql">
					UPDATE ThemeSetting
					SET CustomHeaderHtmlApplyAcrossThemes = 0
				</cfquery>
			</cfif>
			<cfif len(arguments.customFooterHtmlCode)>
				<!--- Sanitize the form value --->
				<cfset sanitizedCustomFooterHtmlCode = StringUtilsObj.sanitizeStrForDb(arguments.customFooterHtmlCode)>
			</cfif>
			<!--- If the applyCustomFooterHtmlToAllThemes argument is set, apply the custom header HTML string across all themes. --->
			<cfif applyCustomFooterHtmlToAllThemes and len(arguments.customFooterHtmlCode)>
				<!--- Save it --->
				<cfquery name="updateTheme" dbtype="hql">
					UPDATE ThemeSetting
					SET TailEndScripts = <cfqueryparam value="#sanitizedCustomFooterHtmlCode#" cfsqltype="cf_sql_longvarchar">,
					TailEndScriptsApplyAcrossThemes = 1
				</cfquery>
			</cfif>
			<cfif not applyCustomFooterHtmlToAllThemes>
				<cfquery name="updateTheme" dbtype="hql">
					UPDATE ThemeSetting
					SET TailEndScripts = '',
					TailEndScriptsApplyAcrossThemes = 0
				</cfquery>
			</cfif>

			<!--- Now, save the record to the database. --->
			<cfif len(arguments.themeId) and len(arguments.themeSettingId)>
				<!--- Load the theme entity. --->
				<cfset ThemeDbObj = entityLoadByPK("Theme", arguments.themeId)>
				<!--- Load the theme setting entity --->
				<cfset ThemeSettingDbObj = entityLoadByPk("ThemeSetting", arguments.themeSettingId )>
			<cfelse>
				<!--- Create the theme entity. --->
				<cfset ThemeDbObj = entityNew("Theme")>
				<!--- Create the theme setting entity --->
				<cfset ThemeSettingDbObj = entityNew("ThemeSetting")>
			</cfif>
			<!--- Load the kendo theme entity --->
			<cfif len(arguments.kendoThemeId)>
				<!--- Get the kendo theme using the supplied arguments. --->
				<cfset KendoThemeDbObj = entityLoadByPK("KendoTheme", arguments.kendoThemeId)>
			<cfelse>
				<cfset arguments.kendoThemeId = ThemeDbObj.getKendoThemeRef().getKendoThemeId()>
				<!--- Get the Kendo theme by the theme ref --->
				<cfset KendoThemeDbObj = entityLoadByPK("KendoTheme", arguments.kendoThemeId)>
			</cfif>
			<!--- And finally the font entity (the fontId is derived by logic, see above) --->
			<cfset FontDbObj = entityLoadByPK("Font", fontId)>
			<!--- Set theme columns --->
			<cfset ThemeDbObj.setThemeName(arguments.theme)>
			<cfset ThemeDbObj.setThemeAlias(themeAlias)>
			<cfset ThemeDbObj.setKendoThemeRef(KendoThemeDbObj)>
			<cfset ThemeDbObj.setThemeGenre(arguments.themeGenre)>
			<!--- Checkbox logic for the following three args are at top of the page. ---> 
			<cfset ThemeDbObj.setSelectedTheme(selectedTheme)>
			<cfset ThemeDbObj.setUseTheme(useTheme)>
			<cfset ThemeDbObj.setDarkTheme(darkTheme)>
			<!--- If the theme style is modern, set the breakpoint to 0 --->
			<cfif arguments.themeStyle eq 'modern'>
				<cfset ThemeSettingDbObj.setBreakpoint(0)>
				<!--- Set the content width to 50 if it was not changed in the interface. --->
				<cfif arguments.contentWidth eq '66'>
					<cfset ThemeSettingDbObj.setContentWidth('50')>	
				<cfelse>
					<cfset ThemeSettingDbObj.setContentWidth(arguments.contentWidth)>
				</cfif>
			</cfif>
			<!--- Fonts (the arguments are from the UI) --->
			<cfset ThemeSettingDbObj.setFontRef(FontDbObj)>	
			<!--- The next two font arguments are derived by logic (see above). --->
			<cfset ThemeSettingDbObj.setBlogNameFontRef(blogNameFontId)>
			<cfset ThemeSettingDbObj.setMenuFontRef(menuFontId)>
			<cfset ThemeSettingDbObj.setFontSize(arguments.fontSize)>
			<cfset ThemeSettingDbObj.setFontSizeMobile(arguments.fontSizeMobile)>
			<cfset ThemeSettingDbObj.setBlogNameFontSize(arguments.blogNameFontSize)>
			<cfset ThemeSettingDbObj.setBlogNameFontSizeMobile(arguments.blogNameFontSizeMobile)>
			<!--- Content Widths --->
			<cfset ThemeSettingDbObj.setMainContainerWidth(arguments.mainContainerWidth)>
			<cfset ThemeSettingDbObj.setSideBarContainerWidth(arguments.sideBarContainerWidth)>
			<cfset ThemeSettingDbObj.setSiteOpacity(arguments.siteOpacity)>
			<!--- Custom Header Html --->
			<cfif len(arguments.customHeaderHtmlCode)>
				<cfset ThemeSettingDbObj.setCustomHeaderHtml(sanitizedCustomHeaderHtml)>
				<cfset ThemeSettingDbObj.setCustomHeaderHtmlApplyAcrossThemes(applyCustomHeaderHtmlAcrossThemes)>
			</cfif>
			<!--- FavIcon --->
			<cfif len(arguments.favIconHtmlCode)>
				<cfset ThemeSettingDbObj.setFavIconHtml(sanitizedFavIconHtml)>
				<cfset ThemeSettingDbObj.setFavIconHtmlApplyAcrossThemes(applyFavIconToAllThemes)>
			</cfif>
			<!--- Logo's --->
			<cfset ThemeSettingDbObj.setLogoImage(StringUtilsObj.setThemeFilePath(arguments.logoImage))>
			<cfset ThemeSettingDbObj.setLogoImageMobile(StringUtilsObj.setThemeFilePath(arguments.logoImageMobile))>
			<cfset ThemeSettingDbObj.setLogoMobileWidth(arguments.logoMobileWidth)>
			<cfset ThemeSettingDbObj.setLogoPaddingLeft(arguments.logoPaddingLeft)>
			<cfset ThemeSettingDbObj.setDefaultLogoImageForSocialMediaShare(StringUtilsObj.setThemeFilePath(arguments.defaultLogoImageForSocialMediaShare))>
			<!--- Background images --->
			<cfset ThemeSettingDbObj.setIncludeBackgroundImages(arguments.includeBackgroundImages)>
			<cfset ThemeSettingDbObj.setBlogBackgroundImage(StringUtilsObj.setThemeFilePath(arguments.blogBackgroundImage))>
			<cfset ThemeSettingDbObj.setBlogBackgroundImageMobile(StringUtilsObj.setThemeFilePath(arguments.blogBackgroundImageMobile))>
			<cfset ThemeSettingDbObj.setBlogBackgroundImagePosition(arguments.blogBackgroundImagePosition)>
			<cfset ThemeSettingDbObj.setBlogBackgroundImageRepeat(arguments.blogBackgroundImageRepeat)>
			<cfset ThemeSettingDbObj.setBlogBackgroundColor(arguments.blogBackgroundColor)>
			<!--- Title --->
			<cfif len(arguments.displayBlogName)>
				<cfset ThemeSettingDbObj.setDisplayBlogName(true)>
			<cfelse>
				<cfset ThemeSettingDbObj.setDisplayBlogName(false)>
			</cfif>
			<cfset ThemeSettingDbObj.setBlogNameTextColor(arguments.blogNameTextColor)>
			<!--- Header --->
			<cfset ThemeSettingDbObj.setHeaderBackgroundColor(arguments.headerBackgroundColor)>
			<cfset ThemeSettingDbObj.setHeaderBackgroundImage(StringUtilsObj.setThemeFilePath(arguments.headerBackgroundImage))>
			<cfset ThemeSettingDbObj.setHeaderBodyDividerImage(StringUtilsObj.setThemeFilePath(arguments.headerBodyDividerImage))>
			<cfset ThemeSettingDbObj.setStretchHeaderAcrossPage(arguments.stretchHeaderAcrossPage)>
			<!--- Menu --->
			<cfset ThemeSettingDbObj.setMenuBackgroundImage(StringUtilsObj.setThemeFilePath(arguments.menuBackgroundImage))>
			<cfset ThemeSettingDbObj.setAlignBlogMenuWithBlogContent(arguments.alignBlogMenuWithBlogContent)>
			<cfset ThemeSettingDbObj.setCoverKendoMenuWithMenuBackgroundImage(arguments.coverKendoMenuWithMenuBackgroundImage)>
			<cfset ThemeSettingDbObj.setTopMenuAlign(arguments.topMenuAlign)>
			<!--- Footer --->
			<cfset ThemeSettingDbObj.setFooterImage(StringUtilsObj.setThemeFilePath(arguments.footerImage))>
			<!--- Tail end scripts --->
			<cfif len(arguments.customFooterHtmlCode)>
				<cfset ThemeSettingDbObj.setTailEndScripts(sanitizedCustomFooterHtmlCode)>
				<cfset ThemeSettingDbObj.setTailEndScriptsApplyAcrossThemes(applyCustomFooterHtmlToAllThemes)>
			</cfif>
			<!--- On new themes, save the theme setting ref --->
			<cfif len(themeId) eq 0 and len(themeSettingId) eq 0>
				<cfset ThemeDbObj.setThemeSettingRef(ThemeSettingDbObj.getThemeSettingId())>
			</cfif>
			<!--- Save the entities --->
			<cfset EntitySave(ThemeSettingDbObj)>
			<cfset EntitySave(ThemeDbObj)>

		</cftransaction>
				
		<!--- Update the conent output if new content was sent in. 
		We are going to loop through the content templates and update the data. Everything related to the content is based upon the contentTemplate name that we will loop through. Note: we will handle the calendarPod below as it does not have any code. --->
		<!--- 2026-10-13: blogPostCalendarPod added. The comment above said the calendar pod was handled below, but nothing handled it,
		so its Enable checkbox never saved. It has no code to save, only the Enable flag, which this loop sets. --->
		<cfset contentTemplates = "navigationMenu,aboutWindow,bioWindow,downloadWindow,downloadPod,subscribePod,cfblogsFeedPod,recentPostsPod,recentCommentsPod,categoriesPod,monthlyArchivesPod,blogPostCalendarPod,upcomingEventsPod,compositeFooter">
			
		<cfloop list="#trim(contentTemplates)#" index="i">
			<cfset thisContentTemplateEnable = evaluate(i & 'Enable')>
				
			<!--- The enable and revert variables will come thru as either on or off. Chage this to true or false --->
			<cfif thisContentTemplateEnable eq 'on'>
				<cfset thisContentTemplateEnable = true>
			<cfelse>
				<cfset thisContentTemplateEnable = false>
			</cfif>

			<!--- Set the active flag (the Enable checkbox) with an HQL UPDATE, which writes to the database at once. 2026-10-13: this
			used entityLoad + setActive + entitySave, but this loop runs after the cftransaction above has closed and the application
			sets ormsettings.flushAtRequestEnd = false, so nothing ever flushed those changes: no Enable checkbox on the theme screen
			was saved (found when the Composite Footer's wouldn't stay checked on gregoryalexander.com). Updating by name also copes
			with a template name that is on more than one row, which the unique entityLoad would have thrown on. --->
			<cfquery name="setContentTemplateActive" dbtype="hql">
				UPDATE ContentTemplate
				SET Active = <cfqueryparam value="#thisContentTemplateEnable#" cfsqltype="cf_sql_bit">
				WHERE ContentTemplateName = <cfqueryparam value="#i#" cfsqltype="cf_sql_varchar">
			</cfquery>
				
		</cfloop>
    	
		<!--- Return true --->
		<cfset response = true><!--- or process to debug the result --->
		<!--- Return it --->

		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
		
	</cffunction>
					
	<cffunction name="createNewThemeFromCurrentTheme" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the comments grid.">
		<cfargument name="csrfToken" required="yes">
		<cfargument name="themeName" required="yes">
		<cfargument name="themeId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = false>
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<!--- Get the theme that we will copy the data from --->
		<cfset Data = application.blog.getTheme(themeId=arguments.themeId)>
	
		<!--- This should only loop once. I am putting this in a loop as this logic is also intended to also be used to populate the initial database.--->
		<cfloop from="1" to="#arrayLen(Data)#" index="i">  

			<cfinvoke component="#application.blog#" method="saveTheme" returnvariable="newThemeId">
				<cfinvokeargument name="kendoThemeId" value="#Data[i]['KendoThemeId']#">
				<cfinvokeargument name="theme" value="#arguments.themeName#">
				<cfinvokeargument name="useTheme" value="#Data[i]['UseTheme']#">
				<!--- The copy isn't the theme in use; the user picks it to use it. 5.0 (2026-10-20): this sent "0", and blog.saveTheme
				selects the theme whenever selectedTheme has any value, so every copy became the site's theme. Empty leaves it unselected. --->
				<cfinvokeargument name="selectedTheme" value="">
				<!--- Kendo Theme settings --->
				<cfinvokeargument name="kendoCommonCssFileLocation" value="#Data[i]['KendoCommonCssFileLocation']#">
				<cfinvokeargument name="kendoThemeCssFileLocation" value="#Data[i]['KendoThemeCssFileLocation']#">
				<cfinvokeargument name="kendoThemeMobileCssFileLocation" value="#Data[i]['KendoThemeMobileCssFileLocation']#">
				<cfinvokeargument name="darkTheme" value="#Data[i]['DarkTheme']#">
				<!--- Fonts --->
				<cfinvokeargument name="fontId" value="#Data[i]['FontId']#">
				<cfinvokeargument name="menuFontId" value="#Data[i]['MenuFontId']#">
				<cfinvokeargument name="blogNameFontId" value="#Data[i]['BlogNameFontId']#">
				<cfinvokeargument name="blogNameFontSize" value="#Data[i]['BlogNameFontSize']#">
				<cfinvokeargument name="blogNameFontSizeMobile" value="#Data[i]['BlogNameFontSizeMobile']#">
				<!--- Container dimensions --->
				<cfinvokeargument name="contentWidth" value="#Data[i]['ContentWidth']#">
				<cfinvokeargument name="mainContainerWidth" value="#Data[i]['MainContainerWidth']#">
				<cfinvokeargument name="sideBarContainerWidth" value="#Data[i]['SideBarContainerWidth']#">
				<!--- Backgrounds --->
				<cfinvokeargument name="blogBackgroundImage" value="#Data[i]['BlogBackgroundImage']#">
				<cfinvokeargument name="blogBackgroundImageMobile" value="#Data[i]['BlogBackgroundImageMobile']#">
				<cfinvokeargument name="blogBackgroundImageRepeat" value="#Data[i]['BlogBackgroundImageRepeat']#">
				<cfinvokeargument name="blogBackgroundImagePosition" value="#Data[i]['BlogBackgroundImagePosition']#">
				<cfinvokeargument name="siteOpacity" value="#Data[i]['SiteOpacity']#">
				<!--- Header --->
				<cfinvokeargument name="stretchHeaderAcrossPage" value="#Data[i]['StretchHeaderAcrossPage']#">
				<cfinvokeargument name="headerBackgroundImage" value="#Data[i]['HeaderBackgroundImage']#">
				<cfinvokeargument name="headerBodyDividerImage" value="#Data[i]['HeaderBodyDividerImage']#">
				<!--- Title --->
				<cfinvokeargument name="blogNameTextColor" value="#Data[i]['BlogNameTextColor']#">
				<!--- Menu --->
				<cfinvokeargument name="alignBlogMenuWithBlogContent" value="#Data[i]['AlignBlogMenuWithBlogContent']#">
				<cfinvokeargument name="topMenuAlign" value="#Data[i]['TopMenuAlign']#">
				<cfinvokeargument name="menuBackgroundImage" value="#Data[i]['MenuBackgroundImage']#">
				<cfinvokeargument name="coverKendoMenuWithMenuBackgroundImage" value="#Data[i]['CoverKendoMenuWithMenuBackgroundImage']#">
				<!--- Responsive breakpoint --->
				<cfinvokeargument name="breakpoint" value="#Data[i]['Breakpoint']#">
				<!--- Logos --->
				<cfinvokeargument name="logoImage" value="#Data[i]['LogoImage']#">
				<cfinvokeargument name="logoImageMobile" value="#Data[i]['LogoImageMobile']#">
				<cfinvokeargument name="logoMobileWidth" value="#Data[i]['LogoMobileWidth']#">
				<cfinvokeargument name="logoPaddingTop" value="#Data[i]['LogoPaddingTop']#">
				<cfinvokeargument name="logoPaddingRight" value="#Data[i]['LogoPaddingRight']#">
				<cfinvokeargument name="logoPaddingLeft" value="#Data[i]['LogoPaddingLeft']#">
				<cfinvokeargument name="logoPaddingBottom" value="#Data[i]['LogoPaddingBottom']#">
			</cfinvoke>
					
			<cfset response[ "themeId" ] = newThemeId />

		</cfloop>
			
		<!--- Return the new theme id --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
	
	</cffunction>
				
	<cffunction name="deleteThemeViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the comments grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="yes" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost,ReleasePost')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>

		<cftransaction>
			<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- Extract the needed fields. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="commentId" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset commentId = i['CommentId']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the comment entity. --->
				<cfset CommentDbObj = entityLoad("Comment", { CommentId = commentId }, "true" )>
				<!--- Set the remove column to true --->
				<cfset CommentDbObj.setRemove(1)>
				<!--- Save it --->
				<cfset EntitySave(CommentDbObj)>

			</cfloop>

		</cftransaction>
								
    	<cfset jsonString = []><!--- '{"data":null}', --->
			
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn jsonString>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( jsonString ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
			
	</cffunction>
				
	<cffunction name="deleteThemeViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Deletes a comment via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="themeId" hint="Pass in the themeSettingId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
			<cftransaction>

				<!--- Update the database. --->
				<!--- Load the entity. --->
				<cfset ThemeDbObj = entityLoadByPK("Theme", arguments.themeId)>
				<!--- Set the remove column to true --->
				<cfset ThemeDbObj.setUseTheme(0)>
				<!--- Save it --->
				<cfset EntitySave(ThemeDbObj)>

			</cftransaction>
    	
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn arguments.themeId>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( arguments.themeId ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>	
				
	</cffunction>
					
	<!---******************************************************************************************************
		Content Output
	*******************************************************************************************************--->
				
	<cffunction name="saveContentTemplate" access="remote" returnformat="json" output="false" 
		hint="Returns a json array.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="action" default="" required="true" hint="Either updateCode or revertCode">
		<cfargument name="selectedContentThemes" default="" required="true">
		<cfargument name="contentTemplate" default="" required="true">
		<cfargument name="codeColumn" default="" required="false" hint="The column in the contentOutput table that stores the code (example 'aboutWindowDesktop')"> 
		<cfargument name="code" default="" required="false">
		<cfargument name="applyAcrossDevices" default="" required="false">	
		
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Send the response back to the client. --->
				<cfreturn serializeJSON( response )>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<!--- Include the string utilities. --->
		<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
			
		<!--- The code or action argument set to revertCode is necessary --->
		<cfif len(arguments.code) or ( len(arguments.action) and arguments.action eq 'revertCode' )>
			<!--- Each theme will have its own record. There can be one or more themes. A zero indicates that all was themes were selected and we will not create a unique theme record --->
			<cfloop list="#arguments.selectedContentThemes#" index="thisThemeId">
				
				<!--- Save it --->
				<cfinvoke component="#application.blog#" method="saveContentOutput" returnvariable="contentTemplateId">
					<cfinvokeargument name="contentTemplate" value="#arguments.contentTemplate#">
					<!--- Pass in the themeId, if it is 0 we wil not use it. --->
					<cfif thisThemeId is not 0>
						<cfinvokeargument name="themeId" value="#thisThemeId#">
					</cfif>
					<cfif arguments.action eq 'updateCode' and len(arguments.code)>
						<!--- Send the sanitized code with all forms used in the code mirror editor. If the applyAcrossDevices argument is true, update both columns --->
						<cfif arguments.applyAcrossDevices>
							<cfinvokeargument name="contentOutputMobile" value="#StringUtilsObj.sanitizeStrForDb(arguments.code)#">
							<cfinvokeargument name="contentOutputDesktop" value="#StringUtilsObj.sanitizeStrForDb(arguments.code)#">
						<cfelse>
							<!--- Only update one column --->
							<cfif arguments.codeColumn contains 'Mobile'>
								<cfinvokeargument name="contentOutputMobile" value="#StringUtilsObj.sanitizeStrForDb(arguments.code)#">
							<cfelse>
								<cfinvokeargument name="contentOutputDesktop" value="#StringUtilsObj.sanitizeStrForDb(arguments.code)#">
							</cfif> 
						</cfif>
						
						<!--- Set the active flag to true --->
						<cfinvokeargument name="active" value="1">
					<cfelseif arguments.action eq 'revertCode'>
						<cfif arguments.codeColumn contains 'Mobile'>
							<cfinvokeargument name="revertMobile" value="true">
						<cfelse>
							<cfinvokeargument name="revertDesktop" value="true">
						</cfif>
						<!--- Set the active flag to false. 2026-10-13: this sat after the cfif, so it overrode active=1 above and every
						saved content template was stored as inactive; it belongs to reverting only. --->
						<cfinvokeargument name="active" value="0">
					</cfif>
				</cfinvoke>
				
			</cfloop><!---<cfloop list="#thisContentTemplateThemes#" index="themeId">--->
			
			<!--- Return true --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn 1>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( 1 ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			
		<cfelse>
			<cfreturn "Must send code or revert arguments">
		</cfif>
			
	</cffunction>
				
	<!---******************************************************************************************************
		Kendo Dropdowns
	*******************************************************************************************************--->
					
	<cffunction name="getCategoriesForDropdown" access="remote" returnformat="json" output="false" 
		hint="Returns a json array to populate the categories dropdown.">
		<cfargument name="parentCategory" default="false" required="false">
		<cfargument name="childCategory" default="false" required="false">
		<cfargument name="csrfToken" default="" required="false">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
			
		<!--- Get the categories, don't use the cached values. --->
		<cfset Data = application.blog.getCategories(false)>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="includeDataHandle" value="false">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="getTagsForDropdown" access="remote" returnformat="json" output="false" 
		hint="Returns a json array to populate the tags dropdown.">
		<cfargument name="csrfToken" default="" required="true">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<!--- Get the categories, don't use the cached values. --->
		<cfset Data = application.blog.getTags(false)>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="includeDataHandle" value="false">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
			
	<!--- Related posts dropdown --->
	<cffunction name="getRelatedPostsForDropdown" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the related posts dropdown.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="postId" required="no" default="">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<!--- Get the related posts, don't  use the cached values. --->
		<cfset Data = application.blog.getRelatedPosts(postId=arguments.postId)>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="includeDataHandle" value="false">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="getPostsTitleAndId" access="remote" returnformat="json" output="false" 
			hint="Returns a json array of all of the posts title and id to populate the related posts dropdown.">
		<cfargument name="csrfToken" default="" required="true">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<!--- Get the related posts, even ones that are not yet released --->
		<cfset Data = application.blog.getPostsTitleAndId(released=false)>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="includeDataHandle" value="false">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="getThemesForDropdown" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the themes dropdown used to create a new theme.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="themeId" type="string" required="false" default="">
		<cfargument name="themeIdList" type="string" required="false" default="">
		<cfargument name="themeIdNotInList" type="string" required="false" default="">
		<cfargument name="includeAllLabel" type="boolean" required="false" default="false">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
			
		<!--- Get the theme name and id. --->
		<cfinvoke component="#application.blog#" method="getThemeNameAndId" returnvariable="Data">
			<cfinvokeargument name="themeId" value="#arguments.themeId#">
			<cfinvokeargument name="themeIdList" value="#arguments.themeIdList#">
			<cfinvokeargument name="themeIdNotInList" value="#arguments.themeIdNotInList#">
			<cfinvokeargument name="includeAllLabel" value="#arguments.includeAllLabel#">
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="includeDataHandle" value="false">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="getKendoThemesForDropdown" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the kendo themes dropdown. Note: this function is not locked down as it is used for demonstration purposes.">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
			
		<!--- Get all of the kendo themes. --->
		<cfset Data = application.blog.getKendoThemes()> 
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="includeDataHandle" value="false">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="getFontsForDropdown" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the font dropdown.">
		<cfargument name="webSafeFont" default="false" required="no">
		<cfargument name="themeFont" default="false" required="no">
		<cfargument name="themeId" default="false" required="no" hint="Required when using themeFont">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
		<!--- Note: the csrfToken is not required for this query is also used on the external blog (non-admin). This query is not secured. --->
			
		<!--- Get the fonts, don't  use the cached values. --->
		<cfif arguments.webSafeFont>
			<cfset Data = application.blog.getFont(webSafeFont=true)>
		<cfelseif arguments.themeFont>
			<cfset Data = application.blog.getThemeFonts(themeId=arguments.themeId)>
		<cfelse>
			<cfset Data = application.blog.getFont()>
		</cfif>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="includeDataHandle" value="false">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<!---****************************************************************************************************
		Font Grid functions
	******************************************************************************************************--->
				
	<cffunction name="getFontsForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the fonts grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="font" required="no" default="">
		<cfargument name="fontWeight" required="no" default="">
		<cfargument name="italic" required="no" default="">
		<cfargument name="fontType" required="no" default="">
		<cfargument name="fileName" required="no" default="">
		<cfargument name="webSafeFont" required="no" default="">
		<cfargument name="googleFont" required="no" default="">
		<cfargument name="useFont" required="no" default="">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will set a 403 status code and abort the page if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<cfinvoke component="#application.blog#" method="getFont" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->
			<cfif arguments.font neq ''>
				<cfinvokeargument name="font" value="#arguments.font#"/>
			</cfif>
			<cfif arguments.fontWeight neq ''>
				<cfinvokeargument name="fontWeight" value="#arguments.fontWeight#"/>
			</cfif>
			<cfif arguments.italic neq ''>
				<cfinvokeargument name="italic" value="#arguments.italic#"/>
			</cfif>
			<cfif arguments.fontType neq ''>
				<cfinvokeargument name="fontType" value="#arguments.fontType#"/>
			</cfif>
			<cfif arguments.fileName neq ''>
				<cfinvokeargument name="fileName" value="#arguments.fileName#"/>
			</cfif>
			<cfif arguments.webSafeFont neq ''>
				<cfinvokeargument name="webSafeFont" value="#arguments.webSafeFont#"/>
			</cfif>
			<cfif arguments.googleFont neq ''>
				<cfinvokeargument name="googleFont" value="#arguments.googleFont#"/>
			</cfif>
			<cfif arguments.useFont neq ''>
				<cfinvokeargument name="useFont" value="#arguments.useFont#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
					
	<cffunction name="updateFontViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the font via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="fontId" type="numeric" required="no">
		<cfargument name="fontWeight" type="string" required="no">
		<cfargument name="fontType" type="string" required="no">
		<cfargument name="italic" type="boolean" required="no">
		<cfargument name="webSafeFont" type="boolean" required="no">
		<cfargument name="fileName" type="string" required="no">
		<cfargument name="useFont" type="boolean" required="no">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- Validate the data --->
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Invalid token</li>">
		</cfif>
			
		<cfif not error>
			
			<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
			<cfset secureFunction('editTheme')>

			<cfinvoke component="#application.blog#" method="saveFont" returnvariable="fontId">
				<cfinvokeargument name="fontId" value="#arguments.fontId#">
				<cfinvokeargument name="fontWeight" value="#arguments.fontWeight#">
				<cfinvokeargument name="fontType" value="#arguments.fontType#">
				<cfinvokeargument name="italic" value="#arguments.italic#">
				<cfinvokeargument name="webSafeFont" value="#arguments.webSafeFont#">
				<cfinvokeargument name="fileName" value="#arguments.fileName#">
				<cfinvokeargument name="useFont" value="#arguments.useFont#">
			</cfinvoke>

			<!---For the jsGrid, we need to return: updatedItem: 1 (ie the fontId)--->
			<cfset response[ "success" ] = true />
			<cfset response[ "fontId" ] = arguments.fontId />
		
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->
			<cfset response[ "success" ] = false />
			<cfset response[ "errorMessage" ] = errorMessage />
		</cfif>
					
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
    	<!--- Send the response back to the client. This is a custom function in the jsonArray.cfc template. --->
    	<cfreturn thisResponse>	
		
	</cffunction>	
					
	<cffunction name="deleteFontViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Removes a font via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="fontId" hint="Pass in the fontId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
			<cftransaction>

				<!--- Update the database. --->
				<!--- Load the entity. --->
				<cfset FontDbObj = entityLoad("Font", { FontId = arguments.fontId }, "true" )>
				<!--- Delete it --->
				<cfset EntityDelete(FontDbObj)>

			</cftransaction>
					
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfset thisResponse = arguments.fontId />
			<cfelse>
				<cfset thisResponse = serializeJSON( arguments.fontId ) />
			</cfif>
    	
		<cfreturn thisResponse>
	</cffunction>
				
	<!---****************************************************************************************************
		Post Grid functions
	******************************************************************************************************--->

	<cffunction name="getPostsForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the recent comments grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		<cfargument name="showPages" required="yes" default="false">
		<cfargument name="showBlogPosts" required="yes" default="true">
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="fullName" required="no" default="" hint="Changed from user to fix a Post Grid error">
		<cfargument name="alias" required="no" default="">
		<cfargument name="title" required="no" default="">
		<cfargument name="description" required="no" default="">
		<cfargument name="body" required="no" default="">
		<cfargument name="moreBody" required="no" default="">
		<cfargument name="released" required="no" default="">
		<cfargument name="datePosted" required="no" default="" hint="Changed from posted to fix a Post Grid error">
		<!--- This is not used as a logical argument, however, with strict argument matching after CF 2023 update 14, the grid will send this variable to the cfc and cause an error.  --->
		<cfargument name="blogSortDate" required="no" default="" hint="Added argument to fix a Post Grid error. This argument does nothing but it is needed after June 2025">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AddPost,EditPost,ReleasePost')>	
			
		<cfinvoke component="#application.blog#" method="getPosts" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->			
			<!--- We always want to show removed posts on this grid --->
			<cfinvokeargument name="showRemovedPosts" value="true"/>
			<cfif arguments.fullName neq ''>
				<cfinvokeargument name="user" value="#arguments.fullName#"/>
			</cfif>
			<cfif arguments.alias neq ''>
				<cfinvokeargument name="alias" value="#arguments.alias#"/>
			</cfif>
			<cfif arguments.title neq ''>
				<cfinvokeargument name="title" value="#arguments.title#"/>
			</cfif>
			<cfif arguments.description neq ''>
				<cfinvokeargument name="description" value="#arguments.description#"/>
			</cfif>
			<cfif arguments.body neq ''>
				<cfinvokeargument name="body" value="#arguments.body#"/>
			</cfif>
			<cfif arguments.moreBody neq ''>
				<cfinvokeargument name="moreBody" value="#arguments.moreBody#"/>
			</cfif>
			<cfif arguments.datePosted neq ''>
				<cfinvokeargument name="posted" value="#arguments.datePosted#"/>
			</cfif>
			<cfinvokeargument name="showPages" value="#arguments.showPages#"/>
			<cfinvokeargument name="showBlogPosts" value="#arguments.showBlogPosts#"/>
			<cfinvokeargument name="released" value="#arguments.released#"/>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
			
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="updatePostViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the released column from the post grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="no" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
		<cfargument name="emailSubscriber" required="no" default="true" hint="Determines whether to email the subscribers">
			
		<cfset response[ "promptToEmailSubscriber" ] = false />
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('ReleasePost')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>
		<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 

		<cftransaction>
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- We are only looking for the CommentId. If we were editing other fields, use the column name and extract them. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="postId" default="" type="any">
				<cfparam name="released" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset postId = i['postId']>
					<cfset released = i['released']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the post entity. --->
				<cfset PostDbObj = entityLoad("Post", { PostId = postId }, "true" )>
				<!--- Set the approved column --->
				<cfset PostDbObj.setReleased( "#released#" )>
				<!--- Save it --->
				<cfset EntitySave(PostDbObj)>

			</cfloop>
					
			<!--- Send email if the post was just released. --->
			<cfif arguments.released and arguments.emailSubscriber>
				<!--- Determine if this is eligible for emailing. --->
				<cfset promptToEmailToSubscribers = application.blog.promptToEmailToSubscribers(postId=arguments.postId)>
				<cfif promptToEmailToSubscribers and application.blog.getReleasedPostEmailMode() eq "auto">
					<!--- Blog Options, Subscriber Email is set to send automatically (2026-10-12): email it now instead of asking. --->
					<cfset application.blog.sendPostEmailToSubscribers(postId=arguments.postId)>
					<cfset response[ "emailSent" ] = true />
				<cfelseif promptToEmailToSubscribers>
					<!--- Send a response indicating that the client should raise a yes/no dialog and ask if the subscribers should be emeiled. --->
					<cfset response[ "promptToEmailSubscriber" ] = true />
				</cfif>
			</cfif><!---<cfif arguments.released and arguments.emailSubscriber>--->

		</cftransaction>
					
		<!--- Send back the postId --->	
		<cfset response[ "postId" ] = arguments.postId />
					
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
		<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
		
	</cffunction>
			
	<cffunction name="updatePostViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the post via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="postId" type="numeric" required="yes" hint="Pass in the postId">
		<cfargument name="released" type="boolean" required="yes" hint="Is this post released?">
		<cfargument name="emailSubscriber" required="no" default="true" hint="Determines whether to email the subscribers">
			
		<cfset response[ "promptToEmailSubscriber" ] = false />
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('ReleasePost')>

		<cftransaction>

			<!--- Update the database. --->
			<!--- Load the entity. --->
			<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
			<!--- Set the released column --->
			<cfset PostDbObj.setReleased( "#arguments.released#" )>
			<!--- Save it --->
			<cfset EntitySave(PostDbObj)>

		</cftransaction>
				
		<!--- Send email if the post was just released. --->
		<cfif arguments.released and emailSubscriber>
			<!--- Determine if this is eligible for emailing. --->
			<cfset promptToEmailToSubscribers = application.blog.promptToEmailToSubscribers(postId=arguments.postId)>
			<cfif promptToEmailToSubscribers and application.blog.getReleasedPostEmailMode() eq "auto">
				<!--- Blog Options, Subscriber Email is set to send automatically (2026-10-12): email it now instead of asking. --->
				<cfset application.blog.sendPostEmailToSubscribers(postId=arguments.postId)>
				<cfset response[ "emailSent" ] = true />
			<cfelseif promptToEmailToSubscribers>
				<!--- Send a response indicating that the client should raise a yes/no dialog and ask if the subscribers should be emeiled. --->
				<cfset response[ "promptToEmailSubscriber" ] = true />
			</cfif>
		</cfif>

		<!--- Send back the postId --->	
		<cfset response[ "postId" ] = arguments.postId />
		
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
		<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
		
	</cffunction>
				
	<cffunction name="removePostViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Removes a post using the kendo grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="yes" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('ReleasePost')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>

		<cftransaction>
			<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- Extract the needed fields. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="postId" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset postId = i['postId']>
					<cfset released = i['removed']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the entity. --->
				<!--- postId is the loop's value from the grid row. arguments.postId does not exist in this function, so using it made the lookup fail and nothing was removed. --->
				<cfset PostDbObj = entityLoad("Post", { PostId = postId }, "true" )>
				<!--- Set the remove column to true --->
				<cfset PostDbObj.setRemove(1)>
				<!--- Save it --->
				<cfset EntitySave(PostDbObj)>
				<!--- Clear the blog's cached post listings and pages, the same way the post editor's own save and delete do. The cfcache flush below does not clear them. --->
				<cfset application.blog.flushGalaxieCache(type='post', postId='#postId#', relatedPostIdList='#application.blog.getRelatedPostIdList(postId)#')>

			</cfloop>

		</cftransaction>
					
		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>
								
    	<cfset jsonString = []><!--- '{"data":null}', --->
    	
		<cfreturn jsonString>
	</cffunction>
				
	<cffunction name="removePostViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Removes a post via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="postId" hint="Pass in the postId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('ReleasePost')>
			
		<cftransaction>

			<!--- Update the database. --->
			<!--- Load the entity. --->
			<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
			<!--- Set the remove column to true --->
			<cfset PostDbObj.setRemove(1)>
			<!--- Save it --->
			<cfset EntitySave(PostDbObj)>

		</cftransaction>

		<!--- flush the cache --->
		<cfcache action="flush"></cfcache>
					
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = arguments.postId />
		<cfelse>
			<cfset thisResponse = serializeJSON( arguments.postId ) />
		</cfif>
    	
		<cfreturn thisResponse>
	</cffunction>
				
	<!---****************************************************************************************************
		User login grid (read only)
	******************************************************************************************************--->
		
	<cffunction name="getUserHistoryForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the user login history grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		<cfargument name="userName" required="yes" default="" hint="Pass in the username">
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="ipAddress" required="no" default="">
		<cfargument name="userAgent" required="no" default="">
		<cfargument name="loginDate" required="no" default="">
		<cfargument name="httpUserAgent" required="no" default="" hint="The jsGrid sends the filter of the user agent column with this name">
		<cfif len(arguments.httpUserAgent)><cfset arguments.userAgent = arguments.httpUserAgent></cfif>
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>			
			
		<cfinvoke component="#application.blog#" method="getUserLoginHistory" returnvariable="Data">
			<cfinvokeargument name="userName" value="#arguments.userName#"/>
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->			
			<cfif arguments.ipAddress neq ''>
				<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#"/>
			</cfif>
			<cfif arguments.userAgent neq ''>
				<cfinvokeargument name="userAgent" value="#arguments.userAgent#"/>
			</cfif>
			<cfif arguments.loginDate neq ''>
				<cfinvokeargument name="loginDate" value="#arguments.loginDate#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
					
	<!--- ****************************************************************************************************
		Admin Log grid (read only)
	******************************************************************************************************--->
		
	<cffunction name="getAdminLogForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the visitor log grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="anonymousUserId" required="no" default="">
		<cfargument name="fullName" required="no" default="">
		<cfargument name="hitCount" required="no" default="">
		<cfargument name="ipAddress" required="no" default=""> 
		<!--- These two args are not used as logical arguments, however, with strict argument matching after CF 2023 update 14, the grid will send extra variables to the cfc and cause an error.  --->
		<cfargument name="httpUserAgent" required="no" default="" hint="Changed from userAgent to httpUserAgent to fix a new CF related bug in June 2025">
		<cfargument name="dateVisited" required="no" default="" hint="Changed from date to dateVisited to fix a new CF related bug in June 2025">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>			
			
		<cfinvoke component="#application.blog#" method="getAdminLog" returnvariable="Data">			
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->	
			<cfif arguments.fullName neq ''>
				<cfinvokeargument name="fullName" value="#arguments.fullName#"/>
			</cfif>
			<cfif arguments.ipAddress neq ''>
				<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#"/>
			</cfif>
			<cfif arguments.httpUserAgent neq ''>
				<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#"/>
			</cfif>
			<cfif arguments.dateVisited neq ''>
				<cfinvokeargument name="date" value="#arguments.dateVisited#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<!---****************************************************************************************************
		Visitor Log grid (read only)
	******************************************************************************************************--->
		
	<cffunction name="getVisitorLogForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the visitor log grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="anonymousUserId" required="no" default="">
		<cfargument name="fullName" required="no" default="">
		<cfargument name="postId" required="no" default="">
		<cfargument name="postTitle" required="no" default="">
		<cfargument name="hitCount" required="no" default="">
		<cfargument name="ipAddressId" required="no" default=""> 
		<cfargument name="ipAddress" required="no" default=""> 
		<!--- These two args are not used as logical arguments, however, with strict argument matching after CF 2023 update 14, the grid will send extra variables to the cfc and cause an error.  --->
		<cfargument name="httpUserAgent" required="no" default="">
		<cfargument name="isBot" required="no" default="">
		<cfargument name="dateVisited" required="no" default="" hint="Changed from date to dateVisited to fix a new CF related bug in June 2025">
		<!--- The admin home's Visitors card (2026-10-20): people only, the last few days. Names the grid's own filters never send. --->
		<cfargument name="peopleOnly" required="no" default="">
		<cfargument name="sinceDays" required="no" default="">
		<!--- The window passes an id in the URL (ie anonymousUserId=1) and the jsGrid filter of the same column sends an empty value with the same name (AnonymousUserId=). ColdFusion combines URL variables that have the same name into a list ('1,') and the query fails to convert this to a number. Use the first value. --->
		<cfloop list="anonymousUserId,postId,ipAddressId" index="idArgument">
			<cfif find(",", arguments[idArgument])><cfset arguments[idArgument] = listFirst(arguments[idArgument])></cfif>
		</cfloop>
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>			
			
		<cfinvoke component="#application.blog#" method="getVisitorLog" returnvariable="Data">			
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->	
			<cfif arguments.anonymousUserId neq ''>
				<cfinvokeargument name="anonymousUserId" value="#arguments.anonymousUserId#"/>
			</cfif>
			<cfif arguments.fullName neq ''>
				<cfinvokeargument name="fullName" value="#arguments.fullName#"/>
			</cfif>
			<cfif arguments.postId neq ''> 
				<cfinvokeargument name="postId" value="#arguments.postId#"/>
			</cfif>
			<cfif arguments.postTitle neq ''> 
				<cfinvokeargument name="postTitle" value="#arguments.postTitle#"/>
			</cfif>
			<cfif arguments.hitCount neq ''> 
				<cfinvokeargument name="hitCount" value="#arguments.hitCount#"/>
			</cfif>
			<cfif arguments.ipAddressId neq ''>
				<cfinvokeargument name="ipAddressId" value="#arguments.ipAddressId#"/>
			</cfif>
			<cfif arguments.ipAddress neq ''>
				<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#"/>
			</cfif>
			<cfif arguments.httpUserAgent neq ''>
				<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#"/>
			</cfif>
			<cfif arguments.isBot neq ''>
				<cfinvokeargument name="isBot" value="#arguments.isBot#"/>
			</cfif>
			<cfif arguments.dateVisited neq ''>
				<cfinvokeargument name="date" value="#arguments.dateVisited#"/>
			</cfif>
			<cfif isBoolean(arguments.peopleOnly) and arguments.peopleOnly>
				<cfinvokeargument name="peopleOnly" value="true"/>
			</cfif>
			<cfif isNumeric(arguments.sinceDays) and arguments.sinceDays gt 0>
				<cfinvokeargument name="sinceDays" value="#min(int(arguments.sinceDays), 366)#"/>
			</cfif>
		</cfinvoke>

		<!--- Signed-in members (2026-10-17): their name, email and picture, for the "Signed in as" column (Members.cfc getVisitorMembers). --->
		<cfset var visitorMemberIds = "">
		<cfset var visitorRow = "">
		<cfset var visitorMembers = {}>
		<cfset var visitorMember = {}>
		<cfif structKeyExists(application, "members") and isArray(Data) and arrayLen(Data)>
			<cfset visitorMemberIds = "">
			<cfloop array="#Data#" index="visitorRow">
				<cfif structKeyExists(visitorRow, "AnonymousUserId") and not isNull(visitorRow["AnonymousUserId"])><cfset visitorMemberIds = listAppend(visitorMemberIds, visitorRow["AnonymousUserId"])></cfif>
			</cfloop>
			<cfset visitorMembers = application.members.getVisitorMembers(visitorMemberIds)>
			<cfloop array="#Data#" index="visitorRow">
				<cfset visitorMember = (structKeyExists(visitorRow, "AnonymousUserId") and not isNull(visitorRow["AnonymousUserId"]) and structKeyExists(visitorMembers, visitorRow["AnonymousUserId"])) ? visitorMembers[visitorRow["AnonymousUserId"]] : {}>
				<cfset visitorRow["MemberName"] = structIsEmpty(visitorMember) ? "" : visitorMember.name>
				<cfset visitorRow["MemberEmail"] = structIsEmpty(visitorMember) ? "" : visitorMember.email>
				<cfset visitorRow["MemberPicture"] = structIsEmpty(visitorMember) ? "" : visitorMember.picture>
			</cfloop>
		</cfif>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
					
	<!---*****************************************************************************************************
		Error Log grid (read only)
	******************************************************************************************************--->
		
	<cffunction name="getErrorLogForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the visitor log grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="errorLogId" required="no" default="">
		<cfargument name="errorURL" required="no" default="">
		<cfargument name="errorEvent" required="no" default="">
		<cfargument name="errorType" required="no" default="">
		<cfargument name="errorMessage" required="no" default=""> 
		<cfargument name="errorDetail" required="no" default=""> 
		<cfargument name="errorTemplate" required="no" default=""> 
		<cfargument name="numErrors" required="no" default=""> 
		<cfargument name="resolved" required="no" default=""> 
		<cfargument name="ipAddressId" required="no" default=""> 
		<cfargument name="ipAddress" required="no" default=""> 
		<cfargument name="httpUserAgent" required="no" default=""> 
		<cfargument name="isBot" required="no" default=""> 
		<cfargument name="date" required="no" default=""> 
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>		
			
		<cfinvoke component="#application.blog#" method="getErrorLog" returnvariable="Data">			
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->	
			<cfif arguments.errorLogId neq ''>
				<cfinvokeargument name="errorLogId" value="#arguments.errorLogId#"/>
			</cfif>
			<cfif arguments.errorURL neq ''>
				<cfinvokeargument name="errorURL" value="#arguments.errorURL#"/>
			</cfif>
			<cfif arguments.errorEvent neq ''> 
				<cfinvokeargument name="errorEvent" value="#arguments.errorEvent#"/>
			</cfif>
			<cfif arguments.errorType neq ''>
				<cfinvokeargument name="errorType" value="#arguments.errorType#"/>
			</cfif>
			<cfif arguments.errorMessage neq ''>
				<cfinvokeargument name="errorMessage" value="#arguments.errorMessage#"/>
			</cfif>
			<cfif arguments.errorDetail neq ''>
				<cfinvokeargument name="errorDetail" value="#arguments.errorDetail#"/>
			</cfif>
			<cfif arguments.errorTemplate neq ''>
				<cfinvokeargument name="errorTemplate" value="#arguments.errorTemplate#"/>
			</cfif>
			<cfif arguments.numErrors neq ''>
				<cfinvokeargument name="numErrors" value="#arguments.numErrors#"/>
			</cfif>
			<cfif arguments.resolved neq ''>
				<cfinvokeargument name="resolved" value="#arguments.resolved#"/>
			</cfif>
			<cfif arguments.ipAddressId neq ''>
				<cfinvokeargument name="ipAddressId" value="#arguments.ipAddressId#"/>
			</cfif>
			<cfif arguments.ipAddress neq ''>
				<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#"/>
			</cfif>
			<cfif arguments.httpUserAgent neq ''>
				<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#"/>
			</cfif>
			<cfif arguments.isBot neq ''>
				<cfinvokeargument name="isBot" value="#arguments.isBot#"/>
			</cfif>
			<cfif arguments.date neq ''>
				<cfinvokeargument name="date" value="#arguments.date#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
					
	<cffunction name="saveErrorLog" access="remote" returnformat="json" output="false" 
			hint="Saves the resolved and notes fields to the database. Used by the errorDetail form.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="errorLogId" hint="Pass in the errorLogId" required="yes">
		<cfargument name="resolved" hint="Was this resolved?" required="no" default="false">
		<cfargument name="notes" hint="Resolution notes" required="no" default="">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('ReleasePost')>
			
		<cftransaction>

			<!--- Update the database. --->
			<!--- Load the entity. --->
			<cfset ErrorLogDbObj = entityLoad("ErrorLog", { ErrorLogId = arguments.errorLogId }, "true" )>
			<!--- Save the resolved and notes field --->
			<cfset ErrorLogDbObj.setResolved(arguments.resolved)>
			<cfset ErrorLogDbObj.setResolutionNotes(arguments.notes)>
			<!--- Save it --->
			<cfset EntitySave(ErrorLogDbObj)>

		</cftransaction>
					
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = arguments.errorLogId />
		<cfelse>
			<cfset thisResponse = serializeJSON( arguments.errorLogId ) />
		</cfif>

		<cfreturn thisResponse>
	</cffunction>

	<cffunction name="deleteErrorLogViaJsGrid" access="remote" returnformat="json" output="false"
			hint="Deletes an error log entry via the jsGrid or the Delete button on errorDetail.cfm.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="errorLogId" hint="Pass in the errorLogId" required="yes">

		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>

		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('ReleasePost')>

		<!--- Delete the row with a bulk HQL DELETE rather than loading the entity and calling EntityDelete() - ErrorLog.AnonymousUserRef is cascade="all", and EntityDelete() on this side risks Hibernate cascading the delete onto the shared AnonymousUser row, which may still be referenced by other ErrorLog/VisitorLog rows for that same visitor. cleanUpLogs() (blog.cfc) uses this same bulk-DELETE approach on ErrorLog for the same reason, and notes it may error on Lucee - hence the cftry here too. --->
		<cftry>
			<cfquery name="deleteErrorLogQuery" dbtype="hql">
				DELETE FROM ErrorLog
				WHERE ErrorLogId = <cfqueryparam value="#arguments.errorLogId#" cfsqltype="cf_sql_integer">
			</cfquery>
			<cfcatch type="any">
				<!--- Do nothing --->
			</cfcatch>
		</cftry>

		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = arguments.errorLogId />
		<cfelse>
			<cfset thisResponse = serializeJSON( arguments.errorLogId ) />
		</cfif>

		<cfreturn thisResponse>
	</cffunction>

	<cffunction name="deleteErrorLogViaKendoGrid" access="remote" returnformat="json" output="false"
			hint="Deletes one or more error log entries via the Kendo grid's destroy command.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string argument will be like so:
		models: [{"ErrorLogId":42,"ErrorMessage":"...", ...}] --->
		<cfargument name="models" type="string" required="yes" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a row is destroyed.">

		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>

		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('ReleasePost')>

		<!--- Remove the models in the string --->
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>

		<!--- Loop thru the struct. There is normally just one row (this grid does not use batch editing), but the Kendo grid always sends an array. --->
		<cfloop array="#thisStruct#" index="i">
			<cfparam name="thisErrorLogId" default="" type="any">
			<cftry>
				<!--- Get the selected value of the field --->
				<cfset thisErrorLogId = i['ErrorLogId']>
				<cfcatch type="any">
					<cfset error = "one of the variables was not defined.">
				</cfcatch>
			</cftry>

			<!--- See deleteErrorLogViaJsGrid above for why this uses a bulk HQL DELETE instead of EntityDelete(). --->
			<cftry>
				<cfquery name="deleteErrorLogQuery" dbtype="hql">
					DELETE FROM ErrorLog
					WHERE ErrorLogId = <cfqueryparam value="#thisErrorLogId#" cfsqltype="cf_sql_integer">
				</cfquery>
				<cfcatch type="any">
					<!--- Do nothing --->
				</cfcatch>
			</cftry>
		</cfloop>

		<cfset jsonString = []>

		<cfreturn jsonString>
	</cffunction>

	<!---*****************************************************************************************************
		Ban Visitors (createAdminInterfaceWindow(66)). Bans/unbans anonymous visitors by IP address or by
		HTTP User-Agent string using a Kendo MultiSelect. See blog.cfc's getDistinctIpAddresses,
		getDistinctHttpUserAgents, setIpAddressBan, setHttpUserAgentBan, and isVisitorBanned.
	******************************************************************************************************--->

	<cffunction name="getIpAddressesForMultiSelect" access="remote" returnformat="json" output="false"
			hint="Returns every unique IP address logged for this blog (and its ban status) to populate the Kendo MultiSelect on the Ban Visitors admin interface.">
		<cfargument name="csrfToken" default="" required="true">

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>

		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>

		<cfinvoke component="#application.blog#" method="getDistinctIpAddresses" returnvariable="Data">
		</cfinvoke>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn Data>
		<cfelse>
			<cfreturn serializeJSON(Data)>
		</cfif>
	</cffunction>

	<cffunction name="getHttpUserAgentsForMultiSelect" access="remote" returnformat="json" output="false"
			hint="Returns every unique HTTP User-Agent string logged for this blog (and its ban status) to populate the Kendo MultiSelect on the Ban Visitors admin interface.">
		<cfargument name="csrfToken" default="" required="true">

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>

		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>

		<cfinvoke component="#application.blog#" method="getDistinctHttpUserAgents" returnvariable="Data">
		</cfinvoke>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn Data>
		<cfelse>
			<cfreturn serializeJSON(Data)>
		</cfif>
	</cffunction>

	<cffunction name="saveAnonymousUserBan" access="remote" returnformat="json" output="false"
			hint="Bans and/or unbans IP addresses or User-Agent strings selected via the Kendo MultiSelect on the Ban Visitors admin interface. banValues/unbanValues are each a JSON-encoded array of strings.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="banType" required="yes" default="" hint="Either 'ip' or 'userAgent'.">
		<cfargument name="banValues" required="no" default="[]" hint="JSON-encoded array of values to ban.">
		<cfargument name="unbanValues" required="no" default="[]" hint="JSON-encoded array of values to unban.">
		<cfargument name="note" required="no" default="" hint="Optional reason/notes for the ban.">

		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>

		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>

		<!--- Parse the JSON arrays sent from the Kendo MultiSelect. We can't rely on a delimited list here since User-Agent strings routinely contain commas (eg. "KHTML, like Gecko"). --->
		<cftry>
			<cfset banArray = deserializeJSON(arguments.banValues)>
		<cfcatch type="any">
			<cfset banArray = []>
		</cfcatch>
		</cftry>
		<cftry>
			<cfset unbanArray = deserializeJSON(arguments.unbanValues)>
		<cfcatch type="any">
			<cfset unbanArray = []>
		</cfcatch>
		</cftry>

		<cfset success = true>

		<cfif arguments.banType eq 'userAgent'>
			<cfif arrayLen(banArray)>
				<cfinvoke component="#application.blog#" method="setHttpUserAgentBan" returnvariable="banSuccess">
					<cfinvokeargument name="httpUserAgents" value="#banArray#">
					<cfinvokeargument name="banned" value="true">
					<cfinvokeargument name="note" value="#arguments.note#">
				</cfinvoke>
				<cfset success = success and banSuccess>
			</cfif>
			<cfif arrayLen(unbanArray)>
				<cfinvoke component="#application.blog#" method="setHttpUserAgentBan" returnvariable="unbanSuccess">
					<cfinvokeargument name="httpUserAgents" value="#unbanArray#">
					<cfinvokeargument name="banned" value="false">
					<cfinvokeargument name="note" value="">
				</cfinvoke>
				<cfset success = success and unbanSuccess>
			</cfif>
		<cfelse>
			<cfif arrayLen(banArray)>
				<cfinvoke component="#application.blog#" method="setIpAddressBan" returnvariable="banSuccess">
					<cfinvokeargument name="ipAddresses" value="#banArray#">
					<cfinvokeargument name="banned" value="true">
					<cfinvokeargument name="note" value="#arguments.note#">
				</cfinvoke>
				<cfset success = success and banSuccess>
			</cfif>
			<cfif arrayLen(unbanArray)>
				<cfinvoke component="#application.blog#" method="setIpAddressBan" returnvariable="unbanSuccess">
					<cfinvokeargument name="ipAddresses" value="#unbanArray#">
					<cfinvokeargument name="banned" value="false">
					<cfinvokeargument name="note" value="">
				</cfinvoke>
				<cfset success = success and unbanSuccess>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn success>
		<cfelse>
			<cfreturn serializeJSON(success)>
		</cfif>
	</cffunction>

	<!---*****************************************************************************************************
		Banned Users grid (read only, jsGrid - createAdminInterfaceWindow(67)). Shows every anonymous visitor
		whose IP address or HTTP User-Agent is currently banned via the Ban Visitors admin interface
		(createAdminInterfaceWindow(66)). See blog.cfc's getBannedAnonymousUsers.
	******************************************************************************************************--->

	<cffunction name="getBannedUsersForGrid" access="remote" returnformat="json" output="false"
			hint="Returns a json array to populate the Banned Users grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="jsGrid" hint="Either Kendo or jsGrid">
		<cfargument name="AnonymousUserId" required="no" default="">
		<cfargument name="IpAddress" required="no" default="">
		<cfargument name="HttpUserAgent" required="no" default="">
		<cfargument name="FullName" required="no" default="">
		<cfargument name="BannedBy" required="no" default="">
		<cfargument name="BanReason" required="no" default="">
		<cfargument name="BannedDate" required="no" default="">
		<!--- jsGrid sends these two automatically (not typed by the admin) whenever a sortable column header is clicked - see bannedUsers.cfm (sorting: true). --->
		<cfargument name="sortField" required="no" default="">
		<cfargument name="sortOrder" required="no" default="">

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>

		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>

		<cfinvoke component="#application.blog#" method="getBannedAnonymousUsers" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->
			<cfif arguments.AnonymousUserId neq ''>
				<cfinvokeargument name="anonymousUserId" value="#arguments.AnonymousUserId#"/>
			</cfif>
			<cfif arguments.IpAddress neq ''>
				<cfinvokeargument name="ipAddress" value="#arguments.IpAddress#"/>
			</cfif>
			<cfif arguments.HttpUserAgent neq ''>
				<cfinvokeargument name="httpUserAgent" value="#arguments.HttpUserAgent#"/>
			</cfif>
			<cfif arguments.FullName neq ''>
				<cfinvokeargument name="fullName" value="#arguments.FullName#"/>
			</cfif>
			<cfif arguments.BannedBy neq ''>
				<cfinvokeargument name="bannedBy" value="#arguments.BannedBy#"/>
			</cfif>
			<cfif arguments.BanReason neq ''>
				<cfinvokeargument name="banReason" value="#arguments.BanReason#"/>
			</cfif>
			<cfif arguments.BannedDate neq ''>
				<cfinvokeargument name="bannedDate" value="#arguments.BannedDate#"/>
			</cfif>
			<cfif arguments.sortField neq ''>
				<cfinvokeargument name="sortField" value="#arguments.sortField#"/>
			</cfif>
			<cfif arguments.sortOrder neq ''>
				<cfinvokeargument name="sortOrder" value="#arguments.sortOrder#"/>
			</cfif>
		</cfinvoke>

		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. --->
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>

		<!--- Return the json string. --->
		<cfreturn jsonString>

	</cffunction>

	<!---*****************************************************************************************************
		Search Query grid (read only)
	******************************************************************************************************--->
		
	<cffunction name="getSearchQueryForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the search log grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="searchQueryId" required="no" default="">
		<cfargument name="searchQuery" required="no" default="">
		<cfargument name="anonymousUserId" required="no" default="">
		<cfargument name="fullName" required="no" default="">
		<cfargument name="ipAddress" required="no" default="">
		<cfargument name="httpUserAgent" required="no" default="">
		<cfargument name="date" required="no" default=""> 
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>		
			
		<cfinvoke component="#application.blog#" method="getSearchQuery" returnvariable="Data">			
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->	
			<cfif arguments.searchQueryId neq ''>
				<cfinvokeargument name="searchQueryId" value="#arguments.searchQueryId#"/>
			</cfif>
			<cfif arguments.anonymousUserId neq ''>
				<cfinvokeargument name="anonymousUserId" value="#arguments.anonymousUserId#"/>
			</cfif>
			<cfif arguments.searchQuery neq ''>
				<cfinvokeargument name="searchQuery" value="#arguments.searchQuery#"/>
			</cfif>
			<cfif arguments.fullName neq ''>
				<cfinvokeargument name="fullName" value="#arguments.fullName#"/>
			</cfif>
			<cfif arguments.ipAddress neq ''>
				<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#"/>
			</cfif>
			<cfif arguments.httpUserAgent neq ''>
				<cfinvokeargument name="httpUserAgent" value="#arguments.httpUserAgent#"/>
			</cfif>
			<cfif arguments.date neq ''>
				<cfinvokeargument name="date" value="#arguments.date#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<!---****************************************************************************************************
		Post functions
	******************************************************************************************************--->
				
	<cffunction name="insertNewPost" access="remote" returnformat="json" output="false" 
			hint="Saves data from the admin user interfaces.">
		<cfargument name="csrfToken" type="string" default="" required="yes">
		<cfargument name="postType" type="string" default="blogPost" required="true">
		<cfargument name="postAlias" type="string" default="" required="false">
		<cfargument name="datePosted" type="string" required="true">
		<cfargument name="timePosted" type="string" required="true">
		<cfargument name="author" type="string" default="" required="true" hint="This will be the userId of the author">
		<cfargument name="title" type="string" default="" required="true">
		<cfargument name="description" type="string" default="" required="true">
		
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!--- Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>

			<!--- Validate the data --->
			<cfif not len(postType)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Post type is required</li>">
			</cfif>
			<cfif not len(datePosted)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Date posted is required</li>">
			</cfif>
			<cfif not len(timePosted)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Time posted is required</li>">
			</cfif>
			<cfif not len(author)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Author is required</li>">
			</cfif>
			<cfif not len(title)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Title is required</li>">
			</cfif>
			<cfif not len(description)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Description is required</li>">
			</cfif>
			<!--- See if the title exists --->
			<cfset postTitle = application.blog.getPostTitle(arguments.title)>
				
			<cfif len(postTitle)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Title already exists</li>">
			</cfif>
			
			<cfif not error>
					
				<!--- Save the data --->
				<cfinvoke component="#application.blog#" method="insertNewPost" returnvariable="postId">
					<cfinvokeargument name="postType" value="#arguments.postType#">
					<cfinvokeargument name="datePosted" value="#arguments.datePosted#">
					<cfinvokeargument name="timePosted" value="#arguments.timePosted#">
					<cfinvokeargument name="author" value="#arguments.author#">
					<cfinvokeargument name="title" value="#arguments.title#">
					<cfinvokeargument name="description" value="#arguments.description#">
				</cfinvoke>
				
				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
				<!--- And send the new or updated postId --->
				<cfset response[ "postId" ] = postId />
			<cfelse>
				<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
				
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
			
	</cffunction>
	
	<cffunction name="savePost" access="remote" returnformat="json" output="false" 
			hint="Saves data from the admin user interfaces.">
		<cfargument name="csrfToken" default="" required="true">
		<!--- If the postId is passed, the function will update the post table. Otherwise it is an insertion. --->
		<cfargument name="postId" type="string" default="" required="false">
		<cfargument name="postType" type="string" default="blogPost" required="false">
		<cfargument name="postAlias" type="string" default="" required="false">
		<cfargument name="datePosted" type="string" required="false">
		<cfargument name="timePosted" type="string" required="false">
		<cfargument name="blogSortDate" type="string" required="false">
		<cfargument name="blogSortDateChanged" type="string" required="false">
		<cfargument name="author" type="string" default="" required="false" hint="This will be the userId of the author">
		<cfargument name="title" type="string" default="" required="false">
		<cfargument name="changeTitleAndLink" type="string" default="false" required="false">
		<cfargument name="description" type="string" default="" required="true">
		<cfargument name="themeId" type="string" default="0" required="false">
		<cfargument name="jsonLd" type="string" default="" required="false" hint="A Json Ld string">
		<cfargument name="post" type="string" default="" required="true" hint="The contents of the post">
		<!--- Media (images, video or maps). There is either zero of one of these send in for an enclosure --->
		<cfargument name="imageMediaId" type="string" default="" required="false" hint="Send the mediaId of the image">
		<cfargument name="videoMediaId" type="string" default="" required="false" hint="The video's mediaId">
		<cfargument name="mapId" type="string" default="" required="false" hint="The mapId">
		<cfargument name="postCategories" type="string" default="" required="false" hint="This can have 0 or more items">
		<cfargument name="postTags" type="string" default="" required="false" hint="This can have 0 or more items">
		<cfargument name="pageCollectionIdList" type="string" default="" required="false" hint="Which Page Collection(s) this Page belongs to - only meaningful when the post is a Page.">
		<cfargument name="relatedPosts" type="string" default="" required="false" hint="This can have 0 or more items">
		<cfargument name="released" type="boolean" default="true" required="no">
		<cfargument name="allowComment" type="boolean" default="true" required="no">
		<cfargument name="promote" type="boolean" default="false" required="no">
		<cfargument name="displayOnRss" type="boolean" default="true" required="no">
		<cfargument name="remove" type="boolean" default="false" required="no">
		<cfargument name="redirectUrl" type="string" required="false" default="">
		<cfargument name="redirectType" type="string" required="false" default="">
		<cfargument name="emailSubscriber" required="no" default="true" hint="Determines whether to email the subscribers">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		<!--- The postContent may not be defined when using a cfinclude --->
		<cfparam name="postContent" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>

			<!--- Validate the data --->
			<cfif not len(datePosted)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Date posted is required</li>">
			</cfif>
			<cfif not len(timePosted)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Time posted is required</li>">
			</cfif>
			<cfif not len(author)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Author is required</li>">
			</cfif>
			<cfif not len(title)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Title is required</li>">
			</cfif>
			<cfif not len(description)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Description is required</li>">
			</cfif>
			<!--- Get the post header to determine if we should display an error if there is not a post. A post may not be available when there is a cfinclude in the post header ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) . --->
			<cfset getPost = application.blog.getPostByPostId(arguments.postId,true,true)>
			<cfset postHeader = getPost[1]["PostHeader"]>
			<!--- Raise an error if the post content is not sent and there is no cfinclude in the post header column --->
			<cfif not len(arguments.post) and not len(postHeader)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Post is required</li>">
			</cfif>
					
			<!--- *************************** Format the post content. *************************** --->
			<!--- Remove special tags that we changed to bypass Global Script Protection- this removes any <attachScript tags and replaces them with <script as well as handling css and meta tags the same way.  --->
			<cfset arguments.post = StringUtilsObj.sanitizeStrForDb(arguments.post)>
					
			<!--- Render the more tag if it has &lt; and &gt; or comments surrounding it. --->
			<cfset arguments.post = RendererObj.renderMoreTagFromTinyMce(arguments.post)>
					
			<!--- When we are viewing a gallery in the tinymce editor, we are looking at a prepared gallery that has iFrames in order for tinymce to show the galleries correctly. However, we want to strip the iframes out and generate new gallery code from the database. The following function will take care of this and return the proper HTML code prior to inserting the post into the database. Note: the post may not be sent in when using a cfinclude or other directive. --->
			<cfif len(arguments.post)>
				<cfinvoke component="#application.jsoupComponentPath#" method="removeGalleryIframes" returnvariable="postContent">
					<cfinvokeargument name="post" value="#arguments.post#">
				</cfinvoke>
			</cfif>
			<!---<cfoutput>removeGalleryIframes: #postContent#</cfoutput>--->
			
			<cfif not error>
					
				<!--- Save the data --->
				<cfinvoke component="#application.blog#" method="savePost" returnvariable="postId">
					<cfif len(arguments.postId)>
						<cfinvokeargument name="postId" value="#arguments.postId#">
					</cfif>
					<cfinvokeargument name="postType" value="#arguments.postType#">
					<cfinvokeargument name="datePosted" value="#arguments.datePosted#">
					<cfinvokeargument name="timePosted" value="#arguments.timePosted#">
					<cfinvokeargument name="blogSortDate" value="#arguments.blogSortDate#">
					<cfinvokeargument name="blogSortDateChanged" value="#arguments.blogSortDateChanged#">
					<cfinvokeargument name="author" value="#arguments.author#">
					<cfinvokeargument name="title" value="#arguments.title#">
					<cfinvokeargument name="changeTitleAndLink" value="#arguments.changeTitleAndLink#">	
					<!--- The post alias is dependent upon the title. --->
					<cfinvokeargument name="postAlias" value="#postAlias#">
					<cfinvokeargument name="description" value="#arguments.description#">
					<cfinvokeargument name="themeId" value="#arguments.themeId#">
					<cfinvokeargument name="jsonLd" value="#arguments.jsonLd#">
					<cfinvokeargument name="post" value="#postContent#">
					<cfinvokeargument name="imageMediaId" value="#arguments.imageMediaId#">
					<cfinvokeargument name="videoMediaId" value="#arguments.videoMediaId#">
					<cfinvokeargument name="mapId" value="#arguments.mapId#">
					<cfinvokeargument name="postCategories" value="#arguments.postCategories#">
					<cfinvokeargument name="postTags" value="#arguments.postTags#">
					<cfinvokeargument name="pageCollectionIdList" value="#arguments.pageCollectionIdList#">
					<cfinvokeargument name="relatedPosts" value="#arguments.relatedPosts#">
					<cfinvokeargument name="released" value="#arguments.released#">
					<cfinvokeargument name="allowComment" value="#arguments.allowComment#">
					<cfinvokeargument name="promote" value="#arguments.promote#">
					<cfinvokeargument name="displayOnRss" value="#arguments.displayOnRss#">
					<cfinvokeargument name="remove" value="#arguments.remove#">
					<cfinvokeargument name="redirectUrl" value="#arguments.redirectUrl#">
					<cfinvokeargument name="redirectType" value="#arguments.redirectType#">
					<cfinvokeargument name="emailSubscriber" value="#arguments.emailSubscriber#">
				</cfinvoke>

				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
				<!--- And send the new or updated postId --->
				<cfset response[ "postId" ] = postId />
				<!--- Whether it's on the homepage now (2026-10-21): the editor says so when a post or page is first released. --->
				<cftry>
					<cfset response[ "frontPage" ] = application.blog.getFrontPageStatus(val(postId)) />
					<cfcatch type="any"><cfset response[ "frontPage" ] = {} /></cfcatch>
				</cftry>
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
				
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
	
	</cffunction>
				
	<cffunction name="savePostHeader" access="remote" returnformat="json" output="false" 
			hint="Saves data to the Post.PostHeader column. Used for cfincludes and directives.">
		<cfargument name="csrfToken" default="" required="true">
		<!--- If the postId is passed, the function will update the post table. Otherwise it is an insertion. --->
		<cfargument name="postId" type="string" default="" required="false">
		<cfargument name="postHeader" type="string" default="" required="false">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>
			
			<cfif not error>
					
				<!--- Save the data --->
				<cfinvoke component="#application.blog#" method="savePostHeader" returnvariable="postId">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="postHeader" value="#postHeader#">
				</cfinvoke>
				
				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
				<!--- And send the new or updated postId --->
				<cfset response[ "postId" ] = postId />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
	</cffunction>
				
	<cffunction name="savePostCss" access="remote" returnformat="json" output="false" 
			hint="Saves data to the Post.Css column.">
		<cfargument name="csrfToken" default="" required="true">
		<!--- If the postId is passed, the function will update the post table. Otherwise it is an insertion. --->
		<cfargument name="postId" type="string" default="" required="false">
		<cfargument name="postCss" type="string" default="" required="false">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>
			
			<cfif not error>
					
				<!--- Save the data --->
				<cfinvoke component="#application.blog#" method="savePostCss" returnvariable="postId">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="postCss" value="#postCss#">
				</cfinvoke>
				
				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
				<!--- And send the new or updated postId --->
				<cfset response[ "postId" ] = postId />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
	</cffunction>
				
	<cffunction name="savePostJavaScript" access="remote" returnformat="json" output="false" 
			hint="Saves data to the Post.JavaScript column.">
		<cfargument name="csrfToken" default="" required="true">
		<!--- If the postId is passed, the function will update the post table. Otherwise it is an insertion. --->
		<cfargument name="postId" type="string" default="" required="false">
		<cfargument name="postJavaScript" type="string" default="" required="false">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>
			
			<cfif not error>
					
				<!--- Save the data --->
				<cfinvoke component="#application.blog#" method="savePostJavaScript" returnvariable="postId">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="postJavaScript" value="#postJavaScript#">
				</cfinvoke>
				
				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
				<!--- And send the new or updated postId --->
				<cfset response[ "postId" ] = postId />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
	</cffunction>
				
	<cffunction name="savePostAlias" access="remote" returnformat="json" output="false" 
			hint="Saves data from the admin user interfaces.">
		<cfargument name="csrfToken" default="" required="true">
		<!--- If the postId is passed, the function will update the post table. Otherwise it is an insertion. --->
		<cfargument name="postId" type="string" default="" required="true">
		<cfargument name="postAlias" type="string" default="" required="true">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>

			<!--- Validate the data --->
			<cfif not len(arguments.postAlias)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Alias is required</li>">
			</cfif>
					
			<cfset currentPostAlias = application.blog.getPostAlias(arguments.postAlias)>
				
			<cfif len(currentPostAlias)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Alias already exists</li>">
			</cfif>
			
			<cfif not error>
					
				<!--- Save the data --->
				<cfinvoke component="#application.blog#" method="savePostAlias" returnvariable="postId">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="postAlias" value="#arguments.postAlias#">
				</cfinvoke>
				
				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
				<!--- Send the post alias that was sent for debugging purposes --->
				<cfset response[ "postAlias" ] = arguments.postAlias />
				<!--- And send the new or updated postId --->
				<cfset response[ "postId" ] = arguments.postId />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
	</cffunction>
				
	<cffunction name="deletePost" access="remote" returnformat="json" output="false" 
			hint="Permenantly removes a post from the system">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="postId" type="string" default="" required="false">
		
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>
					
			<!--- Delete it --->
			<cfinvoke component="#application.blog#" method="deletePost" returnvariable="postId">
				<cfinvokeargument name="postId" value="#arguments.postId#">
			</cfinvoke>

			<!--- Set the success response --->
			<cfset response[ "success" ] = true />
			<!--- And send a boolean value --->
			<cfset response[ "sucess" ] = 1 />
						
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn thisResponse>
	</cffunction>
				
	<!---****************************************************************************************************
		Roles and capabilities
	******************************************************************************************************--->
				
	<cffunction name="getAuthorsForDropdown" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the authors dropdown in the post interfaces.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="userId" required="no" default="" hint="Pass in the userId">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AddPost,ReleasePost')>
			
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT new Map (
				UserId as UserId,
				FullName as FullName
			)
			FROM Users
			WHERE 0=0
			<cfif arguments.userId neq "">
				AND UserId = <cfqueryparam value="#arguments.userId#" cfsqltype="cf_sql_integer">
			</cfif>
				AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
			<cfif isSimpleValue(application.BlogDbObj.getBlogId())>
				AND BlogRef = #application.BlogDbObj.getBlogId()#
			</cfif>
		</cfquery>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfinvokeargument name="includeDataHandle" value="false">
			<cfinvokeargument name="dataHandleName" value="">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
	
	<cffunction name="getRolesForDropdown" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the roles dropdown in the user interfaces.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="userName" required="no" default="" hint="Pass in the userId">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
		
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>
			
		<cfset Data = application.blog.getBlogRoles()>
			
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfinvokeargument name="includeDataHandle" value="false">
			<cfinvokeargument name="dataHandleName" value="">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="getCapabilitiesForDropdown" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the capability dropdown in the user interfaces.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="role" required="no" default="" hint="Pass in the userId">
		<!--- Unused argument needed to prevent a bug after CF2023 Update 14 --->
		<cfargument name="_" required="no" default="" hint="This is required when there is an error on the server when Kendo UI automatically appends a '_' with a string to the URL when calling a remote method. This behavior is typical with the Kendo dropdowns, but it causes a bug that this solves with CF 2023 update 14.">
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>
			
		<cfquery name="Data" dbtype="hql">
			SELECT DISTINCT new Map (
				Role.RoleName as RoleName,
				Capability.CapabilityName as CapabilityName,
				Capability.CapabilityId as CapabilityId,
				Capability.CapabilityUiLabel as CapabilityUiLabel
			)
			FROM 
				Role as Role
				<!--- After establishing a pointer to the UserRole table, we need to get to the RoleCapability table which is another array. --->
				JOIN Role.RoleCapability as RoleCapability
				<!--- Finally, we need to traverse to the actual CapabilityRef column in the Capability table that holds an array of capability data. --->
				JOIN RoleCapability.CapabilityRef as Capability
			WHERE 0=0
				AND Role.RoleName IN (<cfqueryparam cfsqltype="varchar" value="#arguments.role#" list="yes">)
			<cfif isSimpleValue(application.BlogDbObj.getBlogId())>
				AND Role.BlogRef = #application.BlogDbObj.getBlogId()#
			</cfif>
		</cfquery>
			
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfinvokeargument name="includeDataHandle" value="false">
			<cfinvokeargument name="dataHandleName" value="">
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<!---****************************************************************************************************
		Category Grid Functions
	******************************************************************************************************--->
				
	<cffunction name="getCategoriesForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the categories grid."> 
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="categoryAlias" required="no" default="">
		<cfargument name="category" required="no" default="">
		<cfargument name="date" required="no" default="">
		<!--- This is not used as a logical argument, however, with strict argument matching after CF 2023 update 14, the grid will send the extra variables to the cfc and cause an error.  --->
		<cfargument name="postCount" required="no" default="">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditCategory,AddPost,EditPost,ReleasePost')>	
			
		<cfinvoke component="#application.blog#" method="getCategoriesForGrid" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->			
			<cfif arguments.category neq ''>
				<cfinvokeargument name="category" value="#arguments.category#"/>
			</cfif>
			<cfif arguments.categoryAlias neq ''>
				<cfinvokeargument name="alias" value="#arguments.categoryAlias#"/>
			</cfif>
			<cfif arguments.date neq ''>
				<cfinvokeargument name="date" value="#arguments.date#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="updateCategoryViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the category via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="categoryId" type="numeric" required="yes">
		<cfargument name="parentCategoryId" type="numeric" default="0" required="no">
		<cfargument name="category" type="string" required="yes">
		<cfargument name="categoryAlias" type="string" required="yes">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Invalid token</li>">
		</cfif>
			
		<!--- See if the category and category alias already exist before proceeding. --->
		<cfinvoke component="#application.blog#" method="getCategory" returnvariable="getCategory">
			<cfinvokeargument name="parentCategoryId" value="#arguments.parentCategoryId#">
			<cfinvokeargument name="category" value="#arguments.category#">
		</cfinvoke>
		<cfinvoke component="#application.blog#" method="getCategory" returnvariable="getCategoryAlias">
			<cfinvokeargument name="parentCategoryId" value="#arguments.parentCategoryId#">
			<cfinvokeargument name="categoryAlias" value="#arguments.categoryAlias#">
		</cfinvoke>
			
		<!--- Validate the data --->
		<cfif arrayLen(getCategory) and getCategory[1]["CategoryId"] neq arguments.categoryId>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Category already exists</li>">
		</cfif>
		<cfif arrayLen(getCategoryAlias) and getCategoryAlias[1]["CategoryAlias"] neq arguments.categoryAlias>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Category Alias already exists</li>">
		</cfif>
			
		<cfif not error>
			
			<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
			<cfset secureFunction('editCategory')>

			<cftransaction>

				<!--- Update the database. --->
				<!--- Load the category entity. --->
				<cfset CategoryDbObj = entityLoad("Category", { CategoryId = arguments.categoryId }, "true" )>
				<!--- Set the category and alias --->
				<cfset CategoryDbObj.setCategory( arguments.category )>
				<cfset CategoryDbObj.setCategoryAlias( arguments.categoryAlias )>
				<!--- Save it --->
				<cfset EntitySave(CategoryDbObj)>

			</cftransaction>

			<!---For the jsGrid, we need to return: updatedItem: 1 (ie the categoryid)--->
			<cfset response[ "success" ] = true />
			<cfset response[ "categoryId" ] = arguments.categoryId />
		
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->
			<cfset response[ "success" ] = false />
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
			
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
		
	</cffunction>
				
	<cffunction name="deleteCategoryViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the comments grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="yes" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost,ReleasePost')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>

		<cftransaction>
			<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- Extract the needed fields. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="commentId" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset commentId = i['CommentId']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the comment entity. --->
				<cfset CommentDbObj = entityLoad("Comment", { CommentId = commentId }, "true" )>
				<!--- Set the remove column to true --->
				<cfset CommentDbObj.setRemove(1)>
				<!--- Save it --->
				<cfset EntitySave(CommentDbObj)>

			</cfloop>

		</cftransaction>
								
    	<cfset jsonString = []><!--- '{"data":null}', --->
    	
		<cfreturn jsonString>
	</cffunction>
				
	<cffunction name="deleteCategoryViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Deletes a comment via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="categoryId" hint="Pass in the categoryId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditCategory')>
			
		<cftransaction>
			<!--- Delete the association to the blog table. --->
			<!--- Load the comment entity. --->
			<cfset CategoryDbObj = entityLoad("Category", { CategoryId = arguments.categoryId }, "true" )>
			<!--- Remove the blog reference in order to delete this record --->
			<cfset CategoryDbObj.setBlogRef(javaCast("null",""))>
			<!--- Save it --->
			<cfset EntitySave(CategoryDbObj)>
		</cftransaction>

		<cftransaction>
			<!--- Now, in a different transaction, delete the record. --->
			<!--- Load the comment entity. --->
			<cfset CategoryDbObj = entityLoad("Category", { CategoryId = arguments.categoryId }, "true" )>
			<!--- Delete it --->
			<cfset EntityDelete(CategoryDbObj)>
		</cftransaction>
					
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = arguments.categoryId />
		<cfelse>
			<cfset thisResponse = serializeJSON( arguments.categoryId ) />
		</cfif>
			
		<cfreturn thisResponse>
    	
	</cffunction>
							
	<!---****************************************************************************************************
		Category functions
	******************************************************************************************************--->
				
	<cffunction name="saveCategory" access="remote" returnformat="json" output="false" 
			hint="Saves data from the comment user interfaces.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<!--- If the categoryId is passed, the function will update the category table. Otherwise it is an insertion. --->
		<cfargument name="categoryId" type="string" default="" required="false">
		<cfargument name="parentCategoryId" type="string" default="0" required="false">
		<cfargument name="category" type="string" required="true">
		<cfargument name="CategoryAlias" type="string" default="" required="false">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,EditPage,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>

			<!--- Validate the data --->
			<cfif not len(category)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Category is required</li>">
			</cfif>
			<!--- See if the category exists. There is an sipmlified categoryExists function in blog.cfc, however, we want to use this one as we are querying by the parent category. This will return a HQL array --->
			<cfinvoke component="#application.blog#" method="getCategory" returnvariable="categoryExists">
				<cfinvokeargument name="parentCategoryId" value="#arguments.parentCategoryId#">
				<cfinvokeargument name="category" value="#arguments.category#">
			</cfinvoke>
			<!--- Raise an error if the category exists --->
			<cfif arrayLen(categoryExists)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Category already exists</li>">
			</cfif>
			<!--- And finally check the category alias --->
			<cfif len(arguments.categoryAlias)>
				<cfinvoke component="#application.blog#" method="getCategory" returnvariable="categoryAliasExists">
					<cfinvokeargument name="parentCategoryId" value="#arguments.parentCategoryId#">
					<cfinvokeargument name="categoryAlias" value="#arguments.categoryAlias#">
				</cfinvoke>
				<!--- Raise an error if the category exists --->
				<cfif arrayLen(categoryAliasExists)>
					<cfset error = true>
					<cfset errorMessage = errorMessage & "<li>Category Allias already exists</li>">
				</cfif>
			</cfif>
			
			<cfif not error>
				<!--- Insert or update the comment and return the categoryId. --->
				<cfinvoke component="#application.blog#" method="saveCategory" returnvariable="categoryId">
					<cfinvokeargument name="parentCategoryId" value="#arguments.parentCategoryId#">
					<cfinvokeargument name="category" value="#arguments.category#">
					<cfinvokeargument name="categoryAlias" value="#arguments.categoryAlias#">
				</cfinvoke>
				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
				<!--- And send the new or updated categoryId --->
				<cfset response[ "categoryId" ] = categoryId />
				<cfset response[ "parentCategoryRef" ] = arguments.parentCategoryId />
				<cfset response[ "category" ] = arguments.category />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
	</cffunction>
				
	<!---****************************************************************************************************
		Tag Grid Functions
	******************************************************************************************************--->
				
	<cffunction name="getTagsForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the categories grid.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="tagAlias" required="no" default="" hint="Changed this from alias to solve errors after a CF update in June 2025">
		<cfargument name="tag" required="no" default="">
		<cfargument name="date" required="no" default="">
		<!--- This is not used as a logical argument, however, with strict argument matching after CF 2023 update 14, the grid will send the postcount variable to the cfc and cause an error.  --->
		<cfargument name="postCount" required="no" default="" hint="New unused argument needed after June 2025">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditCategory,AddPost,EditPost,ReleasePost')>	
			
		<cfinvoke component="#application.blog#" method="getTagsForGrid" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->			
			<cfif arguments.tag neq ''>
				<cfinvokeargument name="tag" value="#arguments.tag#"/>
			</cfif>
			<cfif arguments.TagAlias neq ''>
				<cfinvokeargument name="alias" value="#arguments.TagAlias#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="updateTagViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the tag via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="tagId" type="numeric" required="yes">
		<cfargument name="tag" type="string" required="yes">
		<cfargument name="tagAlias" type="string" required="yes">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Invalid token</li>">
		</cfif>
			
		<!--- See if the tag and tag alias already exist before proceeding. --->
		<cfinvoke component="#application.blog#" method="getTag" returnvariable="getTag">
			<cfinvokeargument name="tag" value="#arguments.tag#">
		</cfinvoke>
		<cfinvoke component="#application.blog#" method="getTag" returnvariable="getTagAlias">
			<cfinvokeargument name="tagAlias" value="#arguments.tagAlias#">
		</cfinvoke>
			
		<!--- Validate the data --->
		<cfif arrayLen(getTag) and getTag[1]["TagId"] neq arguments.tagId>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Tag already exists</li>">
		</cfif>
		<cfif arrayLen(getTagAlias) and getTagAlias[1]["TagAlias"] neq arguments.tagAlias>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Tag Alias already exists</li>">
		</cfif>
			
		<cfif not error>
			
			<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
			<cfset secureFunction('editCategory')>

			<cftransaction>

				<!--- Update the database. --->
				<!--- Load the tag entity. --->
				<cfset TagDbObj = entityLoad("Tag", { TagId = arguments.tagId }, "true" )>
				<!--- Set the tag and alias --->
				<cfset TagDbObj.setTag( arguments.tag )>
				<cfset TagDbObj.setTagAlias( arguments.tagAlias )>
				<!--- Save it --->
				<cfset EntitySave(TagDbObj)>

			</cftransaction>

			<!---For the jsGrid, we need to return: updatedItem: 1 (ie the tagId)--->
			<cfset response[ "success" ] = true />
			<cfset response[ "tagId" ] = arguments.tagId />
		
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->
			<cfset response[ "success" ] = false />
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
			
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
		
	</cffunction>
				
	<cffunction name="deleteTagViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the tags grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="yes" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditComment,EditPost,ReleasePost')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>

		<cftransaction>
			<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- Extract the needed fields. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="tagId" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset tagId = i['TagId']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the tag entity. --->
				<cfset TagDbObj = entityLoad("Tag", { TagId = tagId }, "true" )>
				<!--- Set the remove column to true --->
				<cfset TagDbObj.setRemove(1)>
				<!--- Save it --->
				<cfset EntitySave(TagDbObj)>

			</cfloop>

		</cftransaction>
								
    	<cfset jsonString = []><!--- '{"data":null}', --->
    	
		<cfreturn jsonString>
	</cffunction>
				
	<cffunction name="deleteTagViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Deletes a tag via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="tagId" hint="Pass in the tagId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditCategory')>
			
		<cftransaction>
			<!--- Delete the association to the blog table. --->
			<!--- Load the comment entity. --->
			<cfset TagDbObj = entityLoad("Tag", { TagId = arguments.tagId }, "true" )>
			<!--- Remove the blog reference in order to delete this record --->
			<cfset TagDbObj.setBlogRef(javaCast("null",""))>
			<!--- Save it --->
			<cfset EntitySave(TagDbObj)>
		</cftransaction>

		<cftransaction>
			<!--- Now, in a different transaction, delete the record. --->
			<!--- Load the comment entity. --->
			<cfset TagDbObj = entityLoad("Tag", { TagId = arguments.tagId }, "true" )>
			<!--- Delete it --->
			<cfset EntityDelete(TagDbObj)>
		</cftransaction>
					
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = arguments.tagId />
		<cfelse>
			<cfset thisResponse = serializeJSON( arguments.tagId ) />
		</cfif>
			
		<cfreturn thisResponse>
    	
	</cffunction>
				
	<cffunction name="saveTag" access="remote" returnformat="json" output="false" 
			hint="Saves data from the tag user interfaces.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<!--- If the tagId is passed, the function will update the tag table. Otherwise it is an insertion. --->
		<cfargument name="tagId" type="string" default="" required="false">
		<cfargument name="tag" type="string" required="true">
		<cfargument name="tagAlias" type="string" default="" required="false">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- Set the default response objects. --->
		<cfset response[ "success" ] = false />
		<cfset response[ "tagId" ] = "" />
		<cfset response[ "tag" ] = "" />
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditPost,EditPage,ReleasePost')>

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>

			<!--- Validate the data --->
			<cfif not len(tag)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Tag is required</li>">
			</cfif>
			<!--- See if the tag exists. This will return a HQL array --->
			<cfinvoke component="#application.blog#" method="getTag" returnvariable="tagExists">
				<cfinvokeargument name="tag" value="#arguments.tag#">
			</cfinvoke>
			<!--- Raise an error if the tag exists --->
			<cfif arrayLen(tagExists)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Tag already exists</li>">
			</cfif>
			<!--- And finally check the tag alias --->
			<cfif len(arguments.tagAlias)>
				<cfinvoke component="#application.blog#" method="getTag" returnvariable="tagAliasExists">
					<cfinvokeargument name="tagAlias" value="#arguments.tagAlias#">
				</cfinvoke>
				<!--- Raise an error if the tag exists --->
				<cfif arrayLen(tagAliasExists)>
					<cfset error = true>
					<cfset errorMessage = errorMessage & "<li>Tag Alias already exists</li>">
				</cfif>
			</cfif>
			
			<cfif not error>
				<!--- Insert or update the comment and return the tagId. --->
				<cfinvoke component="#application.blog#" method="saveTag" returnvariable="tagId">
					<cfinvokeargument name="tag" value="#arguments.tag#">
					<cfinvokeargument name="tagAlias" value="#arguments.tagAlias#">
				</cfinvoke>
				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
				<!--- And send the new or updated tagId and tag --->
				<cfset response[ "tagId" ] = tagId />
				<cfset response[ "tag" ] = arguments.tag />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
	</cffunction>
				
	<!---****************************************************************************************************
		User Grid Functions
	******************************************************************************************************--->
				
	<cffunction name="getUsersForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the categories grid.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="yes" default="kendo" hint="Either Kendo or jsGrid">
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="userName" required="no" default="">
		<cfargument name="firstName" required="no" default="">
		<cfargument name="lastName" required="no" default="">
		<cfargument name="email" required="no" default="">
		<cfargument name="active" required="no" default="">
		<cfargument name="date" required="no" default="">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>	
			
		<cfinvoke component="#application.blog#" method="getUsers" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->			
			<cfif arguments.userName neq ''>
				<cfinvokeargument name="userName" value="#arguments.userName#"/>
			</cfif>
			<cfif arguments.firstName neq ''>
				<cfinvokeargument name="firstName" value="#arguments.firstName#"/>
			</cfif>
			<cfif arguments.lastName neq ''>
				<cfinvokeargument name="lastName" value="#arguments.lastName#"/>
			</cfif>
			<cfif arguments.email neq ''>
				<cfinvokeargument name="email" value="#arguments.email#"/>
			</cfif>
			<cfif arguments.active neq ''>
				<cfinvokeargument name="active" value="#arguments.active#"/>
			</cfif>
		</cfinvoke>
		
		<!--- Return the data as a json object. --->
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<!--- When we use server side paging, we need to override the total and specify a new total which is the sum of the entire query. --->
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<!--- The Kendo grid is not using the data handle, the jsGrid does. --->
			<cfif gridType eq 'jsGrid'>
				<!--- The includeDataHandle is used when the format is json (or jsonp), however, the data handle is not included when you want to make a javascript object embedded in the page. ---> 
				<cfinvokeargument name="includeDataHandle" value="true">
				<!--- If the data handle is not used, this can be left blank. If you are going to use a service on the cfc, typically, the value would be 'data'. --->
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">	
			</cfif>
		</cfinvoke>
		
		<!--- Return the json string. --->
		<cfreturn jsonString>
    
	</cffunction>
				
	<cffunction name="updateUserViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Updates the user via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="userId" type="numeric" required="yes">
		<cfargument name="firstName" type="string" required="yes">
		<cfargument name="lastName" type="string" required="yes">
		<cfargument name="email" type="string" required="yes">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Invalid token</li>">
		</cfif>
				
		<!--- See if the email already exists before proceeding. --->
		<cfinvoke component="#application.blog#" method="getUser" returnvariable="getUserEmail">
			<cfinvokeargument name="email" value="#arguments.email#">
		</cfinvoke>
			
		<!--- Validate the data --->
		<cfif arrayLen(getUserEmail) and getUserEmail[1]["Email"] neq arguments.email>
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Email already exists</li>">
		</cfif>
			
		<cfif not error>
			
			<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
			<cfset secureFunction('editUser')>

			<cftransaction>

				<!--- Update the database. --->
				<!--- Load the users entity. --->
				<cfset UsersDbObj = entityLoad("Users", { UserId = arguments.userId }, "true" )>
				<!--- Set the user info --->
				<cfset UsersDbObj.setFirstName( arguments.firstName )>
				<cfset UsersDbObj.setLastName( arguments.lastName )>
				<cfset UsersDbObj.setEmail( arguments.email )>
				<!--- Save it --->
				<cfset EntitySave(UsersDbObj)>

			</cftransaction>

			<!---For the jsGrid, we need to return: updatedItem: 1 (ie the userId)--->
			<cfset response[ "success" ] = true />
			<cfset response[ "userId" ] = arguments.userId />
		
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->
			<cfset response[ "success" ] = false />
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
			
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
		
	</cffunction>
				
	<cffunction name="deleteUserViaKendoGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the comments grid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Note: when using the Kendo grid, the incoming string arguments will be like so:
		models: [{"Hide":false,"PostUuid":"23B17AD3-B14A-1408-C282B3B6C49B0AC0","Comment":"test 3","UserName":null,"Approved":true,"Promote":false,"Subscribe":false,"Remove":false,"CommenterWebsite":"http://www.gregoryalexander.com","PostTitle":"test","PostId":13,"DatePosted":"August, 25 2020 23:44:00","Spam":false,"CommentId":32,"CommentUuid":"9F051589-CF87-E1AF-D2505B6B468293C4","CommenterFullName":"Gregory Alexander","CommenterEmail":"gregoryalexander77@gmail.com","Moderated":false,"PostAlias":"test"}]  --->
		<cfargument name="models" type="string" required="yes" default="" hint="This argument is bound to the model of the kendo grid. The models is a json string that is sent to this function via ajax whenever a change has been made to the grid. Query kendo grid model or look at the comments in this function for clarification.">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>

		<!--- Remove the models in the string ---> 
		<cfset thisStr = replaceNoCase(models, 'models=', '', 'one')>
		<!--- Decode the string and make it into an array --->
		<cfset thisStr = urlDecode(thisStr)>
		<!--- Use the deserialize function to get at the underlying data. --->
		<cfset thisStruct = deserializeJson(thisStr, false)>

		<cftransaction>
			<!--- Now that we have a clean array of structures, loop thru the array and get to the underlying values that were sent in the grid. ---> 
			<!--- Loop thru the struct. --->
			<cfloop array="#thisStruct#" index="i">
				<!--- Extract the needed fields. Note: some of the variables may not come thru if they are empty. Use error catching here to catch and continue processing if there is an error.  --->
				<cfparam name="userId" default="" type="any">
				<cftry>
					<!--- Get the selected values of the fields --->
					<cfset userId = i['UserId']>
					<cfcatch type="any">
						<cfset error = "one of the variables was not defined.">
					</cfcatch>
				</cftry>

				<!--- Update the database. --->
				<!--- Load the entity. --->
				<cfset UserDbObj = entityLoad("User", { UserId = userId }, "true" )>
				<!--- Set the remove column to true --->
				<cfset UserDbObj.setActive(0)>
				<!--- Save it --->
				<cfset EntitySave(UserDbObj)>

			</cfloop>

		</cftransaction>
								
    	<cfset jsonString = []><!--- '{"data":null}', --->
    	
		<cfreturn jsonString>
	</cffunction>
				
	<cffunction name="deleteUserViaJsGrid" access="remote" returnformat="json" output="false" 
			hint="Removes a user via the jsGrid.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="userId" hint="Pass in the userId" required="yes">
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditUser')>
			
			<!--- Update the database. --->
			<cftransaction>
				<!--- Load the entity. --->
				<cfset UserDbObj = entityLoad("Users", { UserId = userId }, "true" )>
				<!--- Set active false --->
				<cfset UserDbObj.setActive(false)>
				<!--- Save it --->
				<cfset EntitySave(UserDbObj)>
			</cftransaction>
    	
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = arguments.userId />
		<cfelse>
			<cfset thisResponse = serializeJSON( arguments.userId ) />
		</cfif>
			
		<cfreturn thisResponse>
	</cffunction>
				
	<!---****************************************************************************************************
		User functions
	******************************************************************************************************--->
				
	<cffunction name="saveUser" access="remote" returnformat="json" output="false" 
			hint="Saves data from the comment user interfaces.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="action" hint="Either insert, newProfile or update, or updateProfile" default="">
		<cfargument name="pkey" hint="The encrypted password string in the users table. This is only used for new users that have to change their password when setting up the initial account" required="false" default="">
		<cfargument name="userId" type="numeric" required="false">
		<cfargument name="firstName" type="string" required="true">
		<cfargument name="lastName" type="string" required="true">
		<cfargument name="displayName" type="string" required="false" default="">
		<cfargument name="email" type="string" required="true">
		<cfargument name="displayEmail" type="string" required="false">
		<cfargument name="biography" type="string" required="false" default="">
		<cfargument name="profilePicture" type="string" required="false">
		<cfargument name="website" type="string" required="false">
		<cfargument name="facebookUrl" type="string" required="false">
		<cfargument name="linkedInUrl" type="string" required="false">
		<cfargument name="instagramUrl" type="string" required="false">
		<cfargument name="twitterUrl" type="string" required="false">
		<cfargument name="userName" type="string" required="true">
		<cfargument name="password" type="string" required="true">
		<!--- The confirmed password will only be sent when the user is changing the password --->
		<cfargument name="confirmedPasword" type="string" default="" required="false">
		<!--- Security answers for password resets --->
		<cfargument name="securityAnswer1" type="string" default="" required="false">
		<cfargument name="securityAnswer2" type="string" default="" required="false">
		<cfargument name="securityAnswer3" type="string" default="" required="false">
		<!--- Notify sends an email out to the new user asking them to fill out their profile. --->
		<cfargument name="notify" type="boolean" required="false">
		<!--- Either role or new role is required. --->
		<cfargument name="role" type="string" required="false">
		<!--- Only used when there is a new role --->
		<cfargument name="newRole" type="string" required="false">
		<cfargument name="newRoleDesc" type="string" required="false">
		<cfargument name="capabilities" type="any" default="" required="false">
		<!--- Unused argument needed after CF update in June of 2025 --->
		<cfargument name="roleId" type="string" required="false">
			
		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
			
		<!--- For new users that were invited, verify that the pkey matches the temporary long password stored in the database. --->
		<cfif len(arguments.pkey)>

			<!--- Verify that the password is correct.  --->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					UserName as UserName,
					Password as Password
				)
				FROM Users
				WHERE 0=0
					AND Password = <cfqueryparam cfsqltype="cf_sql_varchar" value="#StringUtilsObj.trimStr(arguments.pkey)#" maxlength="175">
					AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				<cfif isSimpleValue(application.BlogDbObj.getBlogId())>
					AND BlogRef = #application.BlogDbObj.getBlogId()#
				</cfif>
			</cfquery>
		
			<!--- Set the temp credentials --->
			<cfset userName = Data[1]["UserName"]>
			<cfset arguments.notify = true>
				
		</cfif><!---<cfif len(arguments.pkey)>--->
			
		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in.
			Note: the user can edit their own profile when a new user is required to change their password -- but
			creating a new account, updating someone else's account, or assigning a role/capabilities (anything
			other than action='updateProfile') is a genuine administrative action and must require the real,
			session-verified EditUser capability rather than the free "edit my own profile" pass. --->
		<cfif arguments.action eq 'updateProfile'>
			<cfset secureFunction('EditProfile', arguments.pkey, arguments.userName)>
		<cfelse>
			<cfset secureFunction('EditUser', arguments.pkey)>
		</cfif>
		<!--- A profile is changed by its own user, or by someone with EditUser (2026-10-14). --->
		<cfif arguments.action eq 'updateProfile' and application.Udf.isLoggedIn()
			and (not structKeyExists(session, "userName") or compareNoCase(trim(arguments.userName), trim(session.userName)) neq 0)
			and not (structKeyExists(session, "capabilityList") and listFindNoCase(session.capabilityList, "EditUser"))>
			<cfheader statuscode="403">
			<cfabort>
		</cfif>

		<!--- Only admins or authenticated new users can update this. --->
		<cfif application.Udf.isLoggedIn()>

			<!--- Validate the data --->
			<cfif not len(firstName)>

				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>First name is required</li>">
			</cfif>
			<cfif not len(lastName)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Last name is required</li>">
			</cfif>
			<cfif not isValid("email", arguments.email)>
				<cfset error = true>
				<cfset errorMessage = "<li>Email is not valid</li>">
			</cfif>
			<cfif len(website) and not isValid("url", arguments.website)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Website is not valid</li>">
			</cfif>
			<cfif not len(userName)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Username is required</li>">
			</cfif>
			<!--- See if the user name is unique --->
			<cfif not len(password)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Password is required</li>">
			</cfif>
			<!--- For update and insert, either a roleId or newRole is required. --->
			<cfif action eq 'update' and (not len(roleId) and not len(newRole))>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Role is required</li>">
			</cfif>
			<cfif action eq 'update' and not len(capabilities)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Capabilities are required</li>">
			</cfif>
			<!--- This is only required when the user is setting up the blog --->
			<cfif action eq 'updateProfile' and not len(securityAnswer1)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Favorite pet name is required</li>">
			</cfif>
			<cfif action eq 'updateProfile' and not len(securityAnswer2)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Favorite childhood friend is required</li>">
			</cfif>
			<cfif action eq 'updateProfile' and not len(securityAnswer3)>
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Favorite pet place is required</li>">
			</cfif>
					
			<cfif not error>
				<!--- Update the comment --->
				<cfinvoke component="#application.blog#" method="saveUser">
					<cfinvokeargument name="action" value="#arguments.action#">
					<cfinvokeargument name="currentUser" value="#session.userName#">
					<cfinvokeargument name="firstName" value="#arguments.firstName#">
					<cfinvokeargument name="lastName" value="#arguments.lastName#">
					<cfinvokeargument name="displayName" value="#arguments.displayName#">
					<cfinvokeargument name="email" value="#arguments.email#">
					<cfif action neq 'insert'>
						<cfinvokeargument name="displayEmail" value="#arguments.displayEmail#">
						<cfinvokeargument name="biography" value="#arguments.biography#">
						<cfinvokeargument name="profilePicture" value="#arguments.profilePicture#">
						<cfinvokeargument name="website" value="#arguments.website#">
						<cfinvokeargument name="facebookUrl" value="#arguments.facebookUrl#">
						<cfinvokeargument name="linkedInUrl" value="#arguments.linkedInUrl#">
						<cfinvokeargument name="instagramUrl" value="#arguments.instagramUrl#">
						<cfinvokeargument name="twitterUrl" value="#arguments.twitterUrl#">
					</cfif><!---<cfif action neq 'insert'>--->
					<cfinvokeargument name="userName" value="#arguments.userName#">
					<cfinvokeargument name="password" value="#arguments.password#">
					<cfinvokeargument name="confirmedPasword" value="#arguments.confirmedPasword#">
					<cfinvokeargument name="securityAnswer1" value="#arguments.securityAnswer1#">
					<cfinvokeargument name="securityAnswer2" value="#arguments.securityAnswer2#">
					<cfinvokeargument name="securityAnswer3" value="#arguments.securityAnswer3#">
					<cfinvokeargument name="notify" value="#arguments.notify#">
					<!--- The roles and capabilities are not passed when updating a profile --->
					<cfif action neq 'updateProfile'>
						<cfinvokeargument name="roleId" value="#arguments.roleId#">
						<cfinvokeargument name="newRole" value="#arguments.newRole#">
						<cfinvokeargument name="newRoleDesc" value="#arguments.newRoleDesc#">
						<cfinvokeargument name="capabilities" value="#arguments.capabilities#">
					</cfif><!---<cfif action neq 'updateProfile'>--->
				</cfinvoke>
				<!--- Set the success response --->
				<cfset response[ "success" ] = true />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		</cfif>
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
	</cffunction>

	<!---****************************************************************************************************
		Site maintenance functions

		Note: the actual side effects for both of these (flushing caches / reinitializing app vars, and
		reloading the ORM metadata) are NOT performed here. They already run in Application.cfc's
		onRequestStart, gated on the URL.reinit / URL.reloadOrm params, which every request into the
		application passes through -- including this one, since the calling JS appends the same param to
		this very AJAX request's URL (e.g. "...&method=refreshSite&reinit=1"). By the time either function
		body below executes, onRequestStart has already run for this request and already done the work.
		These two functions exist purely to give the client a CSRF-checked, capability-checked, definitive
		success/failure response it can use to show a confirmation window -- a plain page navigation (the
		original approach for Refresh Site) has no way to report back to a Kendo window on the admin page
		it just navigated away from.
	******************************************************************************************************--->

	<cffunction name="refreshSite" access="remote" returnformat="json" output="false"
			hint="Confirms that the site was reinitialized after the calling request also carried URL.reinit=1.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Not read in the function body -- Application.cfc's onRequestStart already consumed
			URL.reinit before this function ran. It just needs to be declared here so that ColdFusion's
			strict remote-method argument binding doesn't reject "reinit" as an unrecognized param when
			the calling JS includes it on this same request's URL. --->
		<cfargument name="reinit" type="string" required="no" default="" hint="Unused -- see above.">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response[ "errorMessage" ] = "Invalid token" />
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON( response )>
			</cfif>
		</cfif>

		<!--- Secure this function. Any logged in user may refresh the site -- this matches the Refresh
			Site icon's existing visibility, which (unlike most other admin icons) has never been
			restricted to a specific capability. --->
		<cfset secureFunction('EditProfile')>

		<cfset response[ "success" ] = true />

		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>

		<cfreturn thisResponse>
	</cffunction>

	<cffunction name="reloadOrmObjects" access="remote" returnformat="json" output="false"
			hint="Confirms that the ORM metadata was reloaded after the calling request also carried URL.reloadOrm=1.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Not read in the function body -- Application.cfc's onRequestStart already consumed
			URL.reloadOrm before this function ran. It just needs to be declared here so that ColdFusion's
			strict remote-method argument binding doesn't reject "reloadOrm" as an unrecognized param when
			the calling JS includes it on this same request's URL. --->
		<cfargument name="reloadOrm" type="string" required="no" default="" hint="Unused -- see above.">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<!--- Verify the csrftoken. --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response[ "errorMessage" ] = "Invalid token" />
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON( response )>
			</cfif>
		</cfif>

		<!--- Secure this function. Any logged in user may reload the ORM objects, matching the same
			(deliberately unrestricted) visibility as Refresh Site. --->
		<cfset secureFunction('EditProfile')>

		<cfset response[ "success" ] = true />

		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>

		<cfreturn thisResponse>
	</cffunction>

	<!---****************************************************************************************************
		Gallery functions
	******************************************************************************************************--->
				
	<cffunction name="saveGallery" access="remote" output="false" returnformat="plain" 
			hint="Saves data from the comment detail page.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="action" hint="Either insert or update" default="insert">
		<cfargument name="mediaIdList" type="string" required="true">
		<cfargument name="darkTheme" type="string" required="true">
		<!--- Note: the following arguments may be send in when saving a gallery. They are not used by this function but will cause errors after CF2023 if these are not declared --->
		<cfargument name="numGalleries" type="string" default="" required="false">
		<cfargument name="selectorId" type="string" default="" required="false">
		<!--- There can be one or more gallery items. We have to declare these arguments now after 2023 (sigh) --->
		<cfargument name="mediaUrl1" type="string" default="" required="false">
		<cfargument name="mediaItemTitle1" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl1" type="string" default="" required="false">
		<cfargument name="mediaUrl2" type="string" default="" required="false">
		<cfargument name="mediaItemTitle2" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl2" type="string" default="" required="false">
		<cfargument name="mediaUrl3" type="string" default="" required="false">
		<cfargument name="mediaItemTitle3" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl3" type="string" default="" required="false">
		<cfargument name="mediaUrl4" type="string" default="" required="false">
		<cfargument name="mediaItemTitle4" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl4" type="string" default="" required="false">
		<cfargument name="mediaUrl5" type="string" default="" required="false">
		<cfargument name="mediaItemTitle5" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl5" type="string" default="" required="false">
		<cfargument name="mediaUrl6" type="string" default="" required="false">
		<cfargument name="mediaItemTitle6" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl6" type="string" default="" required="false">
		<cfargument name="mediaUrl7" type="string" default="" required="false">
		<cfargument name="mediaItemTitle7" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl7" type="string" default="" required="false">
		<cfargument name="mediaUrl8" type="string" default="" required="false">
		<cfargument name="mediaItemTitle8" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl8" type="string" default="" required="false">
		<cfargument name="mediaUrl9" type="string" default="" required="false">
		<cfargument name="mediaItemTitle9" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl9" type="string" default="" required="false">
		<cfargument name="mediaUrl10" type="string" default="" required="false">
		<cfargument name="mediaItemTitle10" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl10" type="string" default="" required="false">
		<cfargument name="mediaUrl11" type="string" default="" required="false">
		<cfargument name="mediaItemTitle11" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl11" type="string" default="" required="false">
		<cfargument name="mediaUrl12" type="string" default="" required="false">
		<cfargument name="mediaItemTitle12" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl12" type="string" default="" required="false">
		<cfargument name="mediaUrl13" type="string" default="" required="false">
		<cfargument name="mediaItemTitle13" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl13" type="string" default="" required="false">
		<cfargument name="mediaUrl14" type="string" default="" required="false">
		<cfargument name="mediaItemTitle14" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl14" type="string" default="" required="false">
		<cfargument name="mediaUrl15" type="string" default="" required="false">
		<cfargument name="mediaItemTitle15" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl15" type="string" default="" required="false">
		<cfargument name="mediaUrl16" type="string" default="" required="false">
		<cfargument name="mediaItemTitle16" type="string" default="" required="false">	
		<cfargument name="mediaItemUrl16" type="string" default="" required="false">

		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AddPost,AssetEditor,EditComment,ReleasePost')>
		
		<!--- Set the default response objects. --->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
		<cfparam name="html" type="string" default="">
		
		<cfif arguments.action eq 'insert'>
			<!--- Only admins can update this. --->
			<cfif application.Udf.isLoggedIn()>
				
				<!--- Loop through the mediaId list and validate the data --->
				<cfloop from="1" to="#listLen(arguments.mediaIdList, '_')#" index="i">
					<!--- The title and the url are coming in as a form like so: mediaItemTitle1, 2, 3, etc --->
					<cfset title = evaluate("mediaItemTitle#i#")>
					<cfset url = evaluate("mediaItemUrl#i#")>
				
					<!--- Validate the data --->
					<cfif not len(title)>
						<cfset error = true>
						<cfset errorMessage = "<li>Title is required but was not filled in</li>">
					</cfif>
				</cfloop><!---<cfloop from="1" to="#listLen(arguments.mediaIdList, '_')#" index="i">--->
						
				<cfif not error>
					
					<!--- Loop through the mediaId list --->
					<cfloop from="1" to="#listLen(arguments.mediaIdList, '_')#" index="i">
						<!--- Extract the values. The mediaIdList uses underscores as separaters. --->
						<cfset thisMediaId = listGetAt(mediaIdList, i, '_')>
						<!--- The title and the url are coming in as a form like so: mediaItemTitle1, 2, 3, etc --->
						<cfset title = evaluate("mediaItemTitle#i#")>
						<cfset link = evaluate("mediaItemUrl#i#")>
						<!--- And get the media URL to construct our new HTML --->
						<cfset mediaUrl = evaluate("mediaUrl#i#")>
						<!--- Note: the mediaUrl is the full image that was uploaded. We also want to use the thumbnail that was created when the image was uploaded on the client side (when the user clicked on the upload button) instead. The only difference between the paths is that the image is saved into the thumbnail folder.  --->
						<cfset mediaThumbnailUrl = replaceNoCase(mediaUrl, 'enclosures', 'enclosures/thumbnails')>
						<!---<cfoutput>i: #i# mediaId: #mediaId# title: #title# link: #link#<br/></cfoutput>--->
							
						<cftransaction>
							
							<cftransaction>
								<!--- Load the media ORM database object. --->
								<cfset MediaDbObj = entityLoad("Media", { MediaId = thisMediaId }, "true" )>
								<!--- Save the media title into the media table as well. We will use this as the image description --->
								<cfset MediaDbObj.setMediaTitle(title)>
								<!--- Save it. We're not going to set the date. --->
								<cfset EntitySave(MediaDbObj)>
							</cftransaction>
								
							<!--- Create a new MediaGallery and MediaGalleryItem db object. Only do this once as we don't  want to create multiple records in this table.  --->
							<cfif i eq 1>
								<cftransaction>
									<cfset MediaGalleryDbObj = entityNew("MediaGallery")>
									<!--- Insert the new gallery name 'Gallery1, 2, 3, etc' --->
									<cfset MediaGalleryDbObj.setMediaGalleryName(arguments.mediaIdList)>
									<cfset MediaGalleryDbObj.setDate(application.blog.blogNow())>
									<!---Save the entity--->
									<cfset EntitySave(MediaGalleryDbObj)>
										
									<!--- Get the Id --->
									<cfset galleryId = MediaGalleryDbObj.getMediaGalleryId()>
								</cftransaction>
							</cfif>
							
							<cftransaction>
								<!--- Create a new Media Gallery Item entity --->
								<cfset MediaGalleryItemDbObj = entityNew("MediaGalleryItem")>
								<!--- Set the mediaRef using the media db object --->
								<cfset MediaGalleryItemDbObj.setMediaRef(MediaDbObj)>
								<!---And create the relationship to the media gallery object--->
								<cfset MediaGalleryItemDbObj.setMediaGalleryRef(MediaGalleryDbObj)>
								<!--- Save the title and the URL --->
								<cfset MediaGalleryItemDbObj.setMediaGalleryItemTitle(title)>
								<cfset MediaGalleryItemDbObj.setMediaGalleryItemUrl(link)>
								<cfset MediaGalleryItemDbObj.setDate(application.blog.blogNow())>

								<!--- Save the media gallery entity --->
								<cfset EntitySave(MediaGalleryItemDbObj)>
							</cftransaction>
								
						</cftransaction>
						
					</cfloop><!---<cfloop from="1" to="#listLen(arguments.mediaIdList, '_')#" index="i">--->
						
					<!--- Return a gallery iframe to the client.--->
					<!--- Get the HTML for this gallery. We need to send in the galleryId and the number of images. --->
					<cfset galleryHtml = RendererObj.renderImageGalleryPreview(galleryId, listLen(arguments.mediaIdList, '_'), arguments.darkTheme)>
						
				</cfif><!---<cfif not error>--->
			<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
			</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		</cfif><!---<cfif arguments.action eq 'update'>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<!--- Set the error response --->
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
			<!--- If there is an error, serialize the response --->
    		<cfset response = serializeJSON( response ) />
		<cfelse>
			<!--- Send back our html --->
			<cfset response = galleryHtml>
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn response>
			
	</cffunction>
				
	<!---****************************************************************************************************
		Carousel functions
	******************************************************************************************************--->
				
	<cffunction name="saveCarousel" access="remote" output="false" returnformat="plain" 
			hint="Saves carousel data.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="action" hint="Either insert or update" default="insert">
		<cfargument name="mediaIdList" type="string" required="true">
		<cfargument name="postId" default="" required="false" hint="Mutually exclusive with pageCollectionId">
		<cfargument name="pageCollectionId" default="" required="false" hint="Pass in when this carousel is a Page Collection's hero enclosure instead of a Post's">
		<cfargument name="darkTheme" type="string" required="true">
		<cfargument name="numGalleries" type="string" default="" required="false" hint="Sent by the carousel form's hidden field. Not used by saveCarousel, but it must be declared or ColdFusion rejects the call.">
		<cfargument name="shader" type="string" default="" required="false">
		<cfargument name="effect" type="string" default="" required="false">
		<cfargument name="selectorId" type="string" default="" required="false">
		<cfargument name="carouselFontDropdown" type="string" default="" required="false">
		<cfargument name="carouselTextShadow" type="string" default="" required="false" hint="none, soft, strong or glow; empty for the usual faint shadow.">
		<cfargument name="carouselTextShadowColor" type="string" default="" required="false">
		<cfargument name="getMediaUrl" type="string" default="" required="false">
		<cfargument name="carouselTitle1" type="string" default="" required="false">
		<cfargument name="carouselBody1" type="string" default="" required="false">
		<cfargument name="carouselFontColor1" type="string" default="" required="false">
		<cfargument name="mediaUrl1" type="string" default="" required="false">
		<cfargument name="mediaItemUrl1" type="string" default="" required="false">
		<cfargument name="carouselTitle2" type="string" default="" required="false">
		<cfargument name="carouselBody2" type="string" default="" required="false">
		<cfargument name="carouselFontColor2" type="string" default="" required="false">
		<cfargument name="mediaUrl2" type="string" default="" required="false">
		<cfargument name="mediaItemUrl2" type="string" default="" required="false">
		<cfargument name="carouselTitle3" type="string" default="" required="false">
		<cfargument name="carouselBody3" type="string" default="" required="false">
		<cfargument name="carouselFontColor3" type="string" default="" required="false">
		<cfargument name="mediaUrl3" type="string" default="" required="false">
		<cfargument name="mediaItemUrl3" type="string" default="" required="false">
		<cfargument name="carouselTitle4" type="string" default="" required="false">
		<cfargument name="carouselBody4" type="string" default="" required="false">
		<cfargument name="carouselFontColor4" type="string" default="" required="false">
		<cfargument name="mediaUrl4" type="string" default="" required="false">
		<cfargument name="mediaItemUrl4" type="string" default="" required="false">
		<cfargument name="carouselTitle5" type="string" default="" required="false">
		<cfargument name="carouselBody5" type="string" default="" required="false">
		<cfargument name="carouselFontColor5" type="string" default="" required="false">
		<cfargument name="mediaUrl5" type="string" default="" required="false">
		<cfargument name="mediaItemUrl5" type="string" default="" required="false">
		<cfargument name="carouselTitle6" type="string" default="" required="false">
		<cfargument name="carouselBody6" type="string" default="" required="false">
		<cfargument name="carouselFontColor6" type="string" default="" required="false">
		<cfargument name="mediaUrl6" type="string" default="" required="false">
		<cfargument name="mediaItemUrl6" type="string" default="" required="false">
		<cfargument name="carouselTitle7" type="string" default="" required="false">
		<cfargument name="carouselBody7" type="string" default="" required="false">
		<cfargument name="carouselFontColor7" type="string" default="" required="false">
		<cfargument name="mediaUrl7" type="string" default="" required="false">
		<cfargument name="mediaItemUrl7" type="string" default="" required="false">
		<cfargument name="carouselTitle8" type="string" default="" required="false">
		<cfargument name="carouselBody8" type="string" default="" required="false">
		<cfargument name="carouselFontColor8" type="string" default="" required="false">
		<cfargument name="mediaUrl8" type="string" default="" required="false">
		<cfargument name="mediaItemUrl8" type="string" default="" required="false">
		<cfargument name="carouselTitle9" type="string" default="" required="false">
		<cfargument name="carouselBody9" type="string" default="" required="false">
		<cfargument name="carouselFontColor9" type="string" default="" required="false">
		<cfargument name="mediaUrl9" type="string" default="" required="false">
		<cfargument name="mediaItemUrl9" type="string" default="" required="false">
		<cfargument name="carouselTitle10" type="string" default="" required="false">
		<cfargument name="carouselBody10" type="string" default="" required="false">
		<cfargument name="carouselFontColor10" type="string" default="" required="false">
		<cfargument name="mediaUrl10" type="string" default="" required="false">
		<cfargument name="mediaItemUrl10" type="string" default="" required="false">
		<cfargument name="carouselTitle11" type="string" default="" required="false">
		<cfargument name="carouselBody11" type="string" default="" required="false">
		<cfargument name="carouselFontColor11" type="string" default="" required="false">
		<cfargument name="mediaUrl11" type="string" default="" required="false">
		<cfargument name="mediaItemUrl11" type="string" default="" required="false">
		<cfargument name="carouselTitle12" type="string" default="" required="false">
		<cfargument name="carouselBody12" type="string" default="" required="false">
		<cfargument name="carouselFontColor12" type="string" default="" required="false">
		<cfargument name="mediaUrl12" type="string" default="" required="false">
		<cfargument name="mediaItemUrl12" type="string" default="" required="false">
		<cfargument name="carouselTitle13" type="string" default="" required="false">
		<cfargument name="carouselBody13" type="string" default="" required="false">
		<cfargument name="carouselFontColor13" type="string" default="" required="false">
		<cfargument name="mediaUrl13" type="string" default="" required="false">
		<cfargument name="mediaItemUrl13" type="string" default="" required="false">
		<cfargument name="carouselTitle14" type="string" default="" required="false">
		<cfargument name="carouselBody14" type="string" default="" required="false">
		<cfargument name="carouselFontColor14" type="string" default="" required="false">
		<cfargument name="mediaUrl14" type="string" default="" required="false">
		<cfargument name="mediaItemUrl14" type="string" default="" required="false">
		<cfargument name="carouselTitle15" type="string" default="" required="false">
		<cfargument name="carouselBody15" type="string" default="" required="false">
		<cfargument name="carouselFontColor15" type="string" default="" required="false">
		<cfargument name="mediaUrl15" type="string" default="" required="false">
		<cfargument name="mediaItemUrl15" type="string" default="" required="false">
		<cfargument name="carouselTitle16" type="string" default="" required="false">
		<cfargument name="carouselBody16" type="string" default="" required="false">
		<cfargument name="carouselFontColor16" type="string" default="" required="false">
		<cfargument name="mediaUrl16" type="string" default="" required="false">
		<cfargument name="mediaItemUrl16" type="string" default="" required="false">
		<cfargument name="carouselTitle17" type="string" default="" required="false">
		<cfargument name="carouselBody17" type="string" default="" required="false">
		<cfargument name="carouselFontColor17" type="string" default="" required="false">
		<cfargument name="mediaUrl17" type="string" default="" required="false">
		<cfargument name="mediaItemUrl17" type="string" default="" required="false">
		<cfargument name="carouselTitle18" type="string" default="" required="false">
		<cfargument name="carouselBody18" type="string" default="" required="false">
		<cfargument name="carouselFontColor18" type="string" default="" required="false">
		<cfargument name="mediaUrl18" type="string" default="" required="false">
		<cfargument name="mediaItemUrl18" type="string" default="" required="false">
		<cfargument name="carouselTitle19" type="string" default="" required="false">
		<cfargument name="carouselBody19" type="string" default="" required="false">
		<cfargument name="carouselFontColor19" type="string" default="" required="false">
		<cfargument name="mediaUrl19" type="string" default="" required="false">
		<cfargument name="mediaItemUrl19" type="string" default="" required="false">
		<cfargument name="carouselTitle20" type="string" default="" required="false">
		<cfargument name="carouselBody20" type="string" default="" required="false">
		<cfargument name="carouselFontColor20" type="string" default="" required="false">
		<cfargument name="mediaUrl20" type="string" default="" required="false">
		<cfargument name="mediaItemUrl20" type="string" default="" required="false">

		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AddPost,AssetEditor,EditComment,ReleasePost')>
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />
		<cfparam name="html" type="string" default="">
		
		<cfif arguments.action eq 'insert'>
			<!--- Only admins can update this. --->
			<cfif application.Udf.isLoggedIn()>
						
				<cfif not error>
					
					<!--- Loop through the mediaId list --->
					<cfloop from="1" to="#listLen(arguments.mediaIdList, '_')#" index="i">
						<!--- Extract the values. The mediaIdList uses underscores as separaters. --->
						<cfset thisMediaId = listGetAt(mediaIdList, i, '_')>
						<!--- The title, body, and the url are coming in as a form like so: mediaItemTitle1, 2, 3, etc --->
						<cfset title = evaluate("carouselTitle#i#")>
						<cfset body = evaluate("carouselBody#i#")>
						<cfset link = evaluate("mediaItemUrl#i#")>
						<!--- Font --->
						<cfset fontColor = evaluate("carouselFontColor#i#")>
						<!--- And get the media URL to construct our new HTML --->
						<cfset mediaUrl = evaluate("mediaUrl#i#")>
						<!--- Note: the mediaUrl is the full image that was uploaded. We also want to use the thumbnail that was created when the image was uploaded on the client side (when the user clicked on the upload button) instead. The only difference between the paths is that the image is saved into the thumbnail folder.  --->
						<cfset mediaThumbnailUrl = replaceNoCase(mediaUrl, 'enclosures', 'enclosures/thumbnails')>
						<!---<cfoutput>i: #i# mediaId: #mediaId# title: #title# link: #link#<br/></cfoutput>--->
							
						<cftransaction>
							
							<cftransaction>
								<!--- Load the media ORM database object. --->
								<cfset MediaDbObj = entityLoad("Media", { MediaId = thisMediaId }, "true" )>
								<!--- Save the media title into the media table as well. This may not be present --->
								<cfset MediaDbObj.setMediaTitle(title)>
								<!--- Save it. We're not going to set the date. --->
								<cfset EntitySave(MediaDbObj)>
							</cftransaction>
								
							<!--- Create a new carousel and carousel db object. We also want to create a single carousel record. Only do this once as we don't want to create multiple records in this table.  --->
							<cfif i eq 1>
								<cftransaction>
									<cfset CarouselDbObj = entityNew("Carousel")>
									<!--- Insert the new carousel name 'Gallery1, 2, 3, etc' --->
									<cfset CarouselDbObj.setCarouselName(arguments.mediaIdList)>
									<cfset CarouselDbObj.setCarouselEffect(arguments.effect)>
									<cfset CarouselDbObj.setCarouselShader(arguments.shader)>
									<cfset CarouselDbObj.setCarouselTextShadow(listFind("none,soft,strong,glow", arguments.carouselTextShadow) ? arguments.carouselTextShadow : "")>
									<cfset CarouselDbObj.setCarouselTextShadowColor(reFind("^##[0-9A-Fa-f]{3,8}$", arguments.carouselTextShadowColor) ? arguments.carouselTextShadowColor : "")>
									<cfset CarouselDbObj.setDate(application.blog.blogNow())>
									<!---Save the entity--->
									<cfset EntitySave(CarouselDbObj)>
										
									<!--- Get the Id --->
									<cfset carouselId = CarouselDbObj.getCarouselId()>
								</cftransaction>
									
								<!--- Now, assign the new carousel to the post - or the page collection, when this carousel is a Page Collection's hero enclosure instead of a Post's. --->
								<cftransaction>
									<cfif len(arguments.postId)>
										<!--- Load the post entity --->
										<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>

										<!--- Set the enclosureCarousel --->
										<cfset PostDbObj.setEnclosureCarousel(CarouselDbObj)>

										<!--- Remove other enclosures --->
										<cfset PostDbObj.setEnclosureMedia(javaCast("null",""))>
										<cfset PostDbObj.setEnclosureMap(javaCast("null",""))>

										<!--- Save it. We're not going to set the date. --->
										<cfset EntitySave(PostDbObj)>
									<cfelseif len(arguments.pageCollectionId)>
										<cfset PageCollectionDbObj = entityLoad("PageCollection", { PageCollectionId = arguments.pageCollectionId }, "true" )>
										<cfset PageCollectionDbObj.setEnclosureCarousel(CarouselDbObj)>
										<cfset PageCollectionDbObj.setEnclosureMedia(javaCast("null",""))>
										<cfset PageCollectionDbObj.setEnclosureMap(javaCast("null",""))>
										<cfset EntitySave(PageCollectionDbObj)>
									</cfif>
								</cftransaction>
								<!--- The public collection pages are cached - clear them so the new carousel shows. --->
								<cfif len(arguments.pageCollectionId)>
									<cfset application.blog.flushGalaxieCache('pageCollection')>
								</cfif>

							</cfif><!---<cfif i eq 1>--->
							
							<cftransaction>
								<!--- Load the font entity --->
								<cfset FontDbObj = EntityLoadByPk("Font", carouselFontDropdown)>
								
								<!--- Create a new Media Gallery Item entity --->
								<cfset CarouselItemDbObj = entityNew("CarouselItem")>
								<!--- Set the mediaRef using the media db object --->
								<cfset CarouselItemDbObj.setMediaRef(MediaDbObj)>
								<!---And create the relationship to the carousel object--->
								<cfset CarouselItemDbObj.setCarouselRef(CarouselDbObj)>
								<!--- Save the font properties. Note: there is only one choice in the UI, however, I may add other dropdowns for each item in the future. I am keeping the font ref here instead of its logical placement in the parent carousel table.  --->
								<cfset CarouselItemDbObj.setCarouselItemTitleFontRef(FontDbObj)>
								<cfset CarouselItemDbObj.setCarouselItemTitleFontColor(fontColor)>	
								<!--- Save the title, body, and the URL --->
								<cfset CarouselItemDbObj.setCarouselItemTitle(title)>
								<cfset CarouselItemDbObj.setCarouselItemBody(body)>
								<cfset CarouselItemDbObj.setCarouselItemUrl(link)>
								<cfset CarouselItemDbObj.setDate(application.blog.blogNow())>

								<!--- Save the entity --->
								<cfset EntitySave(CarouselItemDbObj)>
							</cftransaction>
								
						</cftransaction>
						
					</cfloop><!---<cfloop from="1" to="#listLen(arguments.mediaIdList, '_')#" index="i">--->
						
					<!--- Return a gallery iframe to the client.--->
					<!--- Get the HTML for this carousel.  --->
					<cfset thumbnailHtml = RendererObj.renderCarouselPreview(carouselId,'postEditor')>
						
				</cfif><!---<cfif not error>--->
			<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
				<cfset error = true>
				<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
			</cfif><!---<cfif application.Udf.isLoggedIn()>--->
		</cfif><!---<cfif arguments.action eq 'update'>--->
		
		<!--- Prepare the default response objects --->
		<cfif error>
			<!--- Set the error response --->
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
			<!--- If there is an error, serialize the response --->
    		<cfset response = serializeJSON( response ) />
		<cfelse>
			<!--- Send back our html --->
			<cfset response = thumbnailHtml>
		</cfif>
    
    	<!--- Send the response back to the client. --->
    	<cfreturn response>

	</cffunction>

	<!---******************************************************************************************************
		Hero image pool functions - the blog-wide shared photo pool for BlogOption.NoImageFallbackMode='pool'
		(see Renderer.cfc's getHeroFallbackHtml()). Reuses the Carousel/CarouselItem entities, same as a Post's
		own enclosure carousel, but owned by BlogOption instead - the admin UI for this is heroImagePool.cfm.
	*******************************************************************************************************--->

	<cffunction name="getHeroImagePool" access="remote" output="false" returnformat="json"
			hint="Returns the current hero image pool's items (empty array if no pool has been created yet), for heroImagePool.cfm's management grid.">
		<cfargument name="csrfToken" default="" required="true">

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>

		<cfset var poolCarouselId = application.blog.getHeroImagePoolCarouselId()>
		<cfset var getPoolItems = []>
		<cfif len(poolCarouselId)>
			<cfset getPoolItems = application.blog.getCarousel(poolCarouselId)>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn getPoolItems>
		<cfelse>
			<cfreturn serializeJSON(getPoolItems)>
		</cfif>

	</cffunction>

	<cffunction name="addHeroImagePoolItem" access="remote" output="false" returnformat="json"
			hint="Adds an already-uploaded Media (via uploadImage, called separately by the client first) to the hero image pool, creating the pool's own Carousel lazily on first use.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="mediaId" type="numeric" required="yes">

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>

		<cfset var poolCarouselId = application.blog.getHeroImagePoolCarouselId()>
		<cfset var poolCarousel = "">
		<cfset var getFont = "">
		<cfset var defaultFont = "">
		<cfset var newItem = "">
		<cfset var thisResponse = {}>
		<cfset var currentPoolItems = "">
		<!--- Hard cap - unbounded before this, since heroImagePool.cfm's Add Photo button has no client-side limit
		of its own and this was just a plain Carousel/CarouselItem pair with no count check on insert. 75 is a
		deliberate, arbitrary ceiling (not derived from any technical constraint) - just a sane stopping point for
		a shared photo pool meant to be a curated rotation, not an unbounded media library. --->
		<cfset var maxHeroImagePoolItems = 75>

		<cfif len(poolCarouselId)>
			<cfset currentPoolItems = application.blog.getCarousel(poolCarouselId)>
			<cfif arrayLen(currentPoolItems) gte maxHeroImagePoolItems>
				<cfset thisResponse["success"] = false>
				<cfset thisResponse["errorMessage"] = "The hero image pool is capped at #maxHeroImagePoolItems# images. Remove one before adding another.">
				<cfif application.serverProduct eq 'Lucee'>
					<cfreturn thisResponse>
				<cfelse>
					<cfreturn serializeJSON(thisResponse)>
				</cfif>
			</cfif>
		</cfif>

		<cftransaction>
			<cfif len(poolCarouselId)>
				<cfset poolCarousel = entityLoadByPK("Carousel", poolCarouselId)>
			<cfelse>
				<!--- Lazily create the pool's Carousel - nothing owns it (no PostRef/PageCollectionRef), it's reached only via BlogOption.HeroImagePoolCarouselRef. --->
				<cfset poolCarousel = entityNew("Carousel")>
				<cfset poolCarousel.setCarouselName("Hero Image Pool")>
				<cfset poolCarousel.setCarouselTitle("")>
				<cfset poolCarousel.setCarouselEffect("")>
				<cfset poolCarousel.setCarouselShader("")>
				<cfset poolCarousel.setDate(application.blog.blogNow())>
				<cfset entitySave(poolCarousel)>
				<cfset ormFlush()>
				<cfset application.BlogOptionDbObj.setHeroImagePoolCarouselRef(poolCarousel)>
				<cfset entitySave(application.BlogOptionDbObj)>
			</cfif>

			<!--- blog.cfc's getCarousel() inner-joins on CarouselItemTitleFontRef, so any item missing one is
			silently excluded from every render - title/font are otherwise meaningless here since pool items never
			show a title, so any valid Font row satisfies the join. --->
			<cfquery name="getFont" dbtype="hql">
				SELECT new Map (
					Font.FontId as FontId
				)
				FROM Font as Font
			</cfquery>
			<cfif arrayLen(getFont)>
				<cfset defaultFont = entityLoadByPK("Font", getFont[1]["FontId"])>
			</cfif>

			<cfset newItem = entityNew("CarouselItem")>
			<cfset newItem.setCarouselRef(poolCarousel)>
			<cfset newItem.setMediaRef(entityLoadByPK("Media", arguments.mediaId))>
			<cfif isObject(defaultFont)>
				<cfset newItem.setCarouselItemTitleFontRef(defaultFont)>
			</cfif>
			<cfset newItem.setCarouselItemTitle("")>
			<cfset newItem.setCarouselItemTitleFontColor("")>
			<cfset newItem.setCarouselItemTitleFontSize("")>
			<cfset newItem.setCarouselItemBody("")>
			<cfset newItem.setCarouselItemBodyFontColor("")>
			<cfset newItem.setCarouselItemBodyFontSize("")>
			<cfset newItem.setCarouselItemUrl("")>
			<cfset newItem.setDate(application.blog.blogNow())>
			<cfset entitySave(newItem)>
			<cfset ormFlush()>
		</cftransaction>

		<cfset thisResponse["success"] = true>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn thisResponse>
		<cfelse>
			<cfreturn serializeJSON(thisResponse)>
		</cfif>

	</cffunction>

	<cffunction name="deleteHeroImagePoolItem" access="remote" output="false" returnformat="json"
			hint="Removes one item from the hero image pool.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="carouselItemId" type="numeric" required="yes">

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>

		<cfset var poolCarouselId = application.blog.getHeroImagePoolCarouselId()>
		<cfset var thisItem = "">
		<cfset var thisResponse = {}>

		<!--- Only allow deleting an item that actually belongs to the pool carousel - never trust a raw id from the client without checking ownership. --->
		<cfif len(poolCarouselId)>
			<cfset thisItem = entityLoadByPK("CarouselItem", arguments.carouselItemId)>
			<cfif isObject(thisItem) and isObject(thisItem.getCarouselRef()) and thisItem.getCarouselRef().getCarouselId() eq poolCarouselId>
				<!--- Plain SQL, not entityDelete() - CarouselItem.CarouselRef declares cascade="all" back toward its
				parent Carousel (an unusual direction for cascade, normally set on the parent's one-to-many side),
				and nothing in this codebase has ever deleted a single CarouselItem before now. Verified directly:
				entityDelete() on a CarouselItem throws a Hibernate ConstraintViolationException on commit even in
				total isolation, while a plain DELETE works cleanly. --->
				<cfquery name="deleteItem" datasource="#application.dsn#">
					DELETE FROM CarouselItem WHERE CarouselItemId = <cfqueryparam value="#arguments.carouselItemId#" cfsqltype="cf_sql_integer">
				</cfquery>
				<cfset thisResponse["success"] = true>
			<cfelse>
				<cfset thisResponse["success"] = false>
				<cfset thisResponse["errorMessage"] = "That item does not belong to the hero image pool.">
			</cfif>
		<cfelse>
			<cfset thisResponse["success"] = false>
			<cfset thisResponse["errorMessage"] = "There is no hero image pool yet.">
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn thisResponse>
		<cfelse>
			<cfreturn serializeJSON(thisResponse)>
		</cfif>

	</cffunction>

	<cffunction name="replaceEnclosureWithWebp" access="remote" output="false" returnformat="json"
			hint="Swaps a post's enclosure image for an already-converted WebP file the admin uploads directly (enclosureImageEditor.cfm), without cfimage touching it at all - for a server that can't read or write WebP through cfimage (eg CF2023, unlike the DefaultImageQuality/createSocialMediaImages() pipeline elsewhere, which needs cfimage to actually work with the format). Only Media.MediaUrl/MediaPath change - the existing thumbnail and any social-media crops are left exactly as they were generated from the original upload, since there's no way to regenerate them from a WebP source on a server that can't read one either.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="postId" type="numeric" required="yes">
		<cfargument name="file" default="" required="false">

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>

		<cfset var thisResponse = {}>
		<cfset var PostDbObj = "">
		<cfset var MediaDbObj = "">
		<cfset var UploadObj = "">
		<cfset var destination = "">
		<cfset var newFileName = "">
		<cfset var newFilePath = "">
		<cfset var newFileUrl = "">
		<cfset var oldFilePath = "">

		<cftry>
			<cffile action="uploadAll" accept="image/webp" strict="true" destination="#getTempDirectory()#" mode="644" nameconflict="makeunique" result="UploadObj">
			<cfcatch type="any">
				<cfset thisResponse["success"] = false>
				<cfset thisResponse["errorMessage"] = "Upload failed - make sure the file is a .webp image.">
				<cfif application.serverProduct eq 'Lucee'>
					<cfreturn thisResponse>
				<cfelse>
					<cfreturn serializeJSON(thisResponse)>
				</cfif>
			</cfcatch>
		</cftry>

		<cfif not arrayLen(UploadObj) or listLast(UploadObj[1].serverFile, ".") neq "webp">
			<cfset thisResponse["success"] = false>
			<cfset thisResponse["errorMessage"] = "That file isn't a .webp image.">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn thisResponse>
			<cfelse>
				<cfreturn serializeJSON(thisResponse)>
			</cfif>
		</cfif>

		<cfset PostDbObj = entityLoadByPK("Post", arguments.postId)>
		<cfif not isObject(PostDbObj) or not isObject(PostDbObj.getEnclosureMedia())>
			<cffile action="delete" file="#UploadObj[1].serverDirectory#/#UploadObj[1].serverFile#">
			<cfset thisResponse["success"] = false>
			<cfset thisResponse["errorMessage"] = "This post has no enclosure image to swap yet - upload one normally first.">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn thisResponse>
			<cfelse>
				<cfreturn serializeJSON(thisResponse)>
			</cfif>
		</cfif>
		<cfset MediaDbObj = PostDbObj.getEnclosureMedia()>

		<cftransaction>
			<!--- Same destination folder as a normal enclosure upload, keeping the current file's own base name -
			only the extension changes to .webp - so this doesn't leave a second, differently-named copy floating
			around alongside the original once the old one is cleaned up below. --->
			<cfset destination = ImageObj.getImageUploadDestination('enclosure')>
			<cfset oldFilePath = MediaDbObj.getMediaPath()>
			<cfset newFileName = listFirst(getFileFromPath(oldFilePath), ".") & ".webp">
			<cfset newFilePath = destination & "\" & newFileName>
			<cfset newFileUrl = application.baseUrl & "/enclosures/" & newFileName>

			<cffile action="copy" source="#UploadObj[1].serverDirectory#/#UploadObj[1].serverFile#" destination="#newFilePath#">
			<cffile action="delete" file="#UploadObj[1].serverDirectory#/#UploadObj[1].serverFile#">

			<cfset MediaDbObj.setMediaPath(newFilePath)>
			<cfset MediaDbObj.setMediaUrl(newFileUrl)>
			<cfset EntitySave(MediaDbObj)>

			<!--- Clean up the old file, but only once the new one is confirmed in place and the DB is updated - and
			only if it's genuinely a different file (a re-swap over an existing .webp would otherwise delete the file
			this just wrote). --->
			<cfif oldFilePath neq newFilePath and fileExists(oldFilePath)>
				<cffile action="delete" file="#oldFilePath#">
			</cfif>
		</cftransaction>

		<cfset thisResponse["success"] = true>
		<cfset thisResponse["mediaUrl"] = newFileUrl>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn thisResponse>
		<cfelse>
			<cfreturn serializeJSON(thisResponse)>
		</cfif>

	</cffunction>

	<!---******************************************************************************************************
		Media functions
	*******************************************************************************************************--->

	<cffunction name="uploadImage" access="remote" output="false" returnformat="json"
			hint="This function uploads an image and inserts a media record into the database. If the updates were successful, it returns an empty json array.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="mediaProcessType" type="string" default="enclosure" required="false" hint="What media files are we processing? This string determines how to process the image. For example, with enclosures, we want to create social media sharing images for Facebook and Twitter, we are also processing images for galleries and carousels.">
		<cfargument name="mediaTitle" type="string" default="" required="false">
		<!--- The media type determines what to do with the image. Supported types are found in the media type db table. --->
		<cfargument name="mediaType" type="string" default="image" required="false">
		<cfargument name="postId" default="" required="false">
		<!--- Some images may not have a comment (ie a post) --->
		<cfargument name="commentId" default="" required="false">
		<!--- Blog images (ie Logos, backgrounds, etc) have a themeId --->
		<cfargument name="themeId" default="" required="false">
		<!--- User profile images have a userId --->
		<cfargument name="userId" default="" required="false">
		<!--- Page Collection hero images have a pageCollectionId --->
		<cfargument name="pageCollectionId" default="" required="false">
		<!--- Arguments that are not sent but need to be there after the May 13th 2025 CF update --->
		<cfargument name="selectorId" default="" required="false">	
		<!--- The image is sent as a file argument. --->
		<cfargument name="file" default="" required="false">
		<!--- files may be send in when uploading an image gallery --->
		<cfargument name="files" default="" required="false">
		<!--- The per-upload compression slider (enclosureImageEditor.cfm), pre-filled from Blog Options' own
		DefaultImageQuality but adjustable per image. Blank when not sent (eg. every OTHER caller of this function -
		logos, backgrounds, profile pictures, theme images, etc - none of which pass this argument), in which case
		the site default is used. Only meaningful for jpg/webp - see the mime-type check below. --->
		<cfargument name="quality" default="" required="false">

		<!--- Make sure that output is turned on when debugging --->
		<cfset debug = false>
		<!--- Resolve the quality to actually use once, here, rather than re-deriving it at each write site below. --->
		<cfset resolvedImageQuality = len(trim(arguments.quality)) ? val(arguments.quality) : application.BlogOptionDbObj.getDefaultImageQuality()>
		<!--- Save a list of actions taken --->
		<cfparam name="mediaActions" default="">
		<!--- The mediaId is not returned when saving a profile image or an image used in themes (logos, etc) --->
		<cfparam name="mediaId" default="">
		<!--- Image optimizations for social sharing. These should be set to true if the image is an enclosure and it is large enough to optimize. --->
		<cfparam name="facebookOptimized" default="false" type="boolean">
		<cfparam name="twitterOptimized" default="false" type="boolean">
		<cfparam name="googleOptimized" default="false" type="boolean">
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<!--- Galleries and carousels are using Uppy's bundle option and sending the files all at once. The logic is different when using this pathway --->
		<cfparam name="usingUppyBundleOption" default="false">
		<cfif mediaProcessType eq 'gallery' or mediaProcessType eq 'carousel'> 
			<cfset usingUppyBundleOption = true>
		</cfif>
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<cfif application.Udf.isLoggedIn()>

			<!--- Note: this function follows the best practices given by http://learncfinaweek.com/course/index/section/Security/item/File_Uploads/. --->

			<!--- There are three main processes here- inspecting and uploading the image(s), saving the data to the database, and returning data back to the client..
			A Upload the original image to a temp directory and check for sanity, create thumbnail and social media images for enclosures, and moving the image to the proper folder.
			B Save the image data to the database.
			C Return the data to the client. --->
			
			<!--- ************************************ A1 Inspect images and upload them ************************************ --->
			<!--- Allowed mime types. --->
			<cfset acceptedMimeTypes = {
				'image/jpeg': {extension: 'jpg'},
				'image/gif': {extension: 'gif'},
				'image/webp': {extension: 'webp'},
				'image/png': {extension: 'png'}
			}>

			<!--- Reject anything over 25MB. Generous headroom for a high-resolution source photo (well past the
			1920x1440 master resolution these get cropped down to), while still ruling out someone uploading a huge
			uncompressed TIFF/BMP-style file by mistake. Checked per-file below (see the loop), after upload - cffile
			has no attribute to reject a file by size before it uploads. The CF Administrator's own Server Settings
			> Request Tuning > "Maximum size of post data" is the real first line of defense against a truly
			enormous request, and should be set there too as a blanket ceiling across every upload endpoint, not
			just this one. --->
			<cfset imageMaxFileSizeBytes = 25 * 1024 * 1024>

			<!--- ******************************* A2- Upload the image(s) to a temp directory ******************************* --->
			<!--- Put this in a catch block --->
			<cftry>

				<!--- Upload all of the files to ColdFusion's temporary directory and then check the file(s) before we upload them to our permanent destination. The file field name may vary here, its different for the uppy (ie. files[]) and tinymce (ie file) interfaces, and we need some extra logic to differentiate them. --->

				<!--- When we are uploading for the gallery or carousel, we need to make sure to upload the files sequentially and are using Uppy's bundle option which sends all of the images at once. Since we are not looping through each image individually, we need to use a query object to store the file results --->
				<cfif usingUppyBundleOption>
					
					<!--- Create a query to hold the response sent back to the client. --->
					<cfset responseQuery = queryNew("error,errorMessage,mediaId,location,clientFile", "bit,varchar,integer,varchar,varchar")>
						
				</cfif><!---<cfif mediaProcessType eq 'gallery' or mediaProcessType eq 'carousel'>--->
						
				<!--- We are using using uploadAll for all uploads. We are using mode 644 for Linux clients to set permissions --->
				<cffile 
					action="uploadAll" 
					accept="#structKeyList(acceptedMimeTypes)#"
					strict="true" 
					destination="#getTempDirectory()#" 
					mode = "644"
					nameconflict="overwrite"
					result="UploadObj">
				
				<cfif debug>
					<!--- Note: the json will be malformed when using this, but it will show you the results of the upload --->
					<cfdump var="#UploadObj#">
				</cfif>
					
				<!--- **************************************** A3 Check for sanity  **************************************** --->
				<cfcatch type="any">
					<!--- File is not written to disk if error is thrown  --->
					<!--- Prevent zero length files --->
					<cfif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Zero length file</li>">
					<!--- Prevent invalid file types --->
					<cfelseif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>The MIME type or the Extension of the uploaded file</li>">
					<!--- Prevent empty form field --->
					<cfelseif findNoCase( "did not contain a file.", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Empty form</li>">
					<!--- Catch all other errors --->
					<cfelse>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Unhandled File Upload Error: #cfcatch.message#</li>">
					</cfif>
							
					<!--- If there is an error when using the bundled option, dump it into the result query --->
					<cfif usingUppyBundleOption>
						<cfset queryAddRow(responseQuery)>
						<!--- Set the values --->
						<cfset querySetCell(responseQuery,"error",true)>
						<cfset querySetCell(responseQuery,"errorMessage","#errorMessage#")>
						<cfset querySetCell(responseQuery,"mediaId","")>
						<cfset querySetCell(responseQuery,"location","")>
					</cfif><!---<cfif usingUppyBundleOption>--->
				</cfcatch>
			</cftry>

			<!---  A4 If there are no errors, create thumbnails for enclosures, get image data, move the image to the desired destination and return the image path info --->
			<cfif not error>
					
				<!--- There can be one or more images. Loop through the image array provided by cffile --->
				<cfloop array="#UploadObj#" item="image">

					<!--- Reject an oversized image now, before it ever reaches thumbnail/social-crop generation or
					its permanent destination - delete the temp copy and report the error the same way an actual
					upload failure above does (a row in responseQuery for a gallery/carousel bundle, so the rest of
					the batch still processes; otherwise an early error return for a single-file upload). --->
					<cfif image.fileSize gt imageMaxFileSizeBytes>
						<cffile action="delete" file="#image.ServerDirectory#/#image.ServerFile#">
						<cfset oversizedMessage = "<li>Image is too large (" & numberFormat(image.fileSize / 1024 / 1024, "0.0") & "MB). The maximum allowed size is " & (imageMaxFileSizeBytes / 1024 / 1024) & "MB.</li>">
						<cfif usingUppyBundleOption>
							<cfset queryAddRow(responseQuery)>
							<cfset querySetCell(responseQuery,"error",true)>
							<cfset querySetCell(responseQuery,"errorMessage","#oversizedMessage#")>
							<cfset querySetCell(responseQuery,"mediaId","")>
							<cfset querySetCell(responseQuery,"location","")>
							<cfcontinue>
						<cfelse>
							<cfset response = {}>
							<cfset response["errorMessage"] = "<ul>#oversizedMessage#</ul>">
							<cfif application.serverProduct eq 'Lucee'>
								<cfreturn response>
							<cfelse>
								<cfreturn serializeJSON(response)>
							</cfif>
						</cfif>
					</cfif>

					<!--- Set our final destination. To reduce potential confilict between the image names, we are saving each type of media in its own folder --->
					<cfset destination = ImageObj.getImageUploadDestination(arguments.mediaProcessType)>
					
					<!--- Determine if the image already exists. This flag will be used to determine whether to update or insert the record into the database. --->
					<cfif fileExists(destination & image.ServerFile)>
						<cfset imageExists = true>
					<cfelse>
						<cfset imageExists = false>
					</cfif>
					
					<!--- Create our thumbnail image (for presentation in the administrative interface). The thumbnails are created for enclosures (posts), carousels, and fancybox when creating a gallery (createThumbnail(source, fileName). We do not want to create thumbnails of smaller images, such as our Logos, user profile images, etc --->
					<cfif mediaProcessType eq 'enclosure' or mediaProcessType eq 'carousel' or mediaProcessType eq 'gallery' or mediaProcessType eq 'pageCollectionHero'>
						<cfset createThumbnail = true>
					<cfelse>
						<cfset createThumbnail = false>
					</cfif>
					<!--- Create the thumbnail --->
					<cfif createThumbnail>
						<cfset thumbnail = ImageObj.createThumbnail('#image.ServerDirectory & '/' & image.ServerFile#', '#image.ServerFile#')>
						<cfif isDefined("thumbnail")>
							<cfset mediaActions = listAppend(mediaActions, 'Thumbnail Image')>
						</cfif>
						<cfif debug><cfdump var="#thumbnail#"></cfif>
					</cfif>
					
					<!--- Get image data. --->
					<!--- Get the image height and width. Note: as a matter of principle, this should always be done after uploading the image as there may be errors and we want to extract them in the cffile logic. This also allows us to read the saved object rather than the file field name which may be different depending upon the interface. --->
					<cfimage 
						action = "info"
						source = "#image.ServerDirectory & '/' & image.ServerFile#"
						structname="imageInfo">

					<!--- Determine the mime type --->
					<cfset mimeType = fileGetMimeType( image.ServerDirectory & '/' & image.ServerFile, true )>
					
					<!--- Move the file to the final destination. --->
					<cffile
						action="move"
						source="#image.serverDirectory#/#image.serverFile#"
						destination="#destination#"
						mode="644">

					<!--- Gallery and carousel pictures are shown at their full size (a gallery's enlarged view, every
					carousel slide), and until now they were only recompressed, never resized - a 6000px camera photo
					went to every visitor at 6000px. Scale them down so the longest side is at most 1920px, which still
					fills a large screen. Smaller pictures are left alone, and animated GIFs are skipped (a resize keeps
					only the first frame). The resized copy is written with the same quality the recompress below would
					use, so the picture is only re-encoded once. --->
					<cfset imageRewritten = false>
					<cfset maxGalleryImageSide = 1920>
					<cfif (mediaProcessType eq 'gallery' or mediaProcessType eq 'carousel')
							and (imageInfo.width gt maxGalleryImageSide or imageInfo.height gt maxGalleryImageSide)
							and not findNoCase("gif", mimeType)>
						<cftry>
							<cfset resizedImage = imageRead(destination & image.serverFile)>
							<cfset imageScaleToFit(resizedImage, maxGalleryImageSide, maxGalleryImageSide, "highQuality")>
							<!--- Quality only matters for lossy formats; 1 (100%) for png. --->
							<cfif findNoCase("jpg", mimeType) or findNoCase("jpeg", mimeType) or findNoCase("webp", mimeType)>
								<cfset imageWrite(resizedImage, destination & image.serverFile, resolvedImageQuality, true)>
							<cfelse>
								<cfset imageWrite(resizedImage, destination & image.serverFile, 1, true)>
							</cfif>
							<!--- The width and height are saved with the picture below, so record the new size. --->
							<cfset imageInfo.width = imageGetWidth(resizedImage)>
							<cfset imageInfo.height = imageGetHeight(resizedImage)>
							<cfset imageRewritten = true>
							<cfset mediaActions = listAppend(mediaActions, 'Resized Image')>
							<cfcatch type="any">
								<!--- Keep the original if resizing fails for any reason (eg. an engine without webp
								read/write support) - never block the upload over this. --->
							</cfcatch>
						</cftry>
					</cfif>

					<!--- Recompress in place, using the resolved quality (per-upload slider, or Blog Options' own
					default) - only for lossy formats (jpg/webp), where cfimage's own "quality" attribute actually
					does something; a no-op for png/gif source uploads (checked client-side too - see
					enclosureImageEditor.cfm - but re-checked here since this function is called by more than one
					UI path, and never for images already at 1.0/100%, which is the same thing as not recompressing
					at all. --->
					<cfif not imageRewritten and resolvedImageQuality lt 1 and (findNoCase("jpg", mimeType) or findNoCase("jpeg", mimeType) or findNoCase("webp", mimeType))>
						<cftry>
							<cfimage action="write" source="#destination##image.serverFile#" destination="#destination##image.serverFile#" quality="#resolvedImageQuality#" overwrite="yes">
							<cfcatch type="any">
								<!--- Leave the originally-moved file as-is if recompression fails for any reason (eg.
								an older CF/Lucee version without webp write support) - never block the upload over
								this. --->
							</cfcatch>
						</cftry>
					</cfif>

					<!--- Get the full path and the name of the file. --->
					<cfif mediaProcessType eq 'post'>
						<cfset imageUrl = application.baseUrl & "/enclosures/post/" & image.serverFile>
					<cfelseif mediaProcessType eq 'gallery'>
						<cfset imageUrl = application.baseUrl & "/enclosures/gallery/" & image.serverFile>
					<cfelseif mediaProcessType eq 'carousel'>
						<cfset imageUrl = application.baseUrl & "/enclosures/carousel/" & image.serverFile>
					<cfelseif mediaProcessType eq 'headerBackgroundImage' or mediaProcessType eq 'menuBackgroundImage'>
						<cfset imageUrl = application.baseUrl & "/images/header/" & image.serverFile>
					<cfelseif mediaProcessType eq 'headerBodyDividerImage'>
						<cfset imageUrl = application.baseUrl & "/images/divider/" & image.serverFile>
					<cfelseif mediaProcessType contains 'Background'>
						<cfset imageUrl = application.baseUrl & "/images/background/" & image.serverFile>
					<cfelseif mediaProcessType contains 'Logo' or mediaProcessType eq 'footerImage'>
						<cfset imageUrl = application.baseUrl & "/images/logo/" & image.serverFile>
					<cfelseif arguments.mediaProcessType eq 'mediaVideoCoverUrl'>
						<cfset imageUrl = application.baseUrl & "/enclosures/videos/" & image.serverFile>
					<cfelseif arguments.mediaProcessType eq 'heroCoverImage'>
						<cfset imageUrl = application.baseUrl & "/enclosures/" & image.serverFile>
					<cfelseif arguments.mediaProcessType eq 'profilePicture' or arguments.mediaProcessType eq 'userBio'>
						<cfset imageUrl = application.baseUrl & "/images/photo/" & image.serverFile>
					<!--- Custom content types --->
					<cfelseif arguments.mediaProcessType contains 'header'>
						<cfset imageUrl = application.baseUrl & "/images/header/" & image.serverFile>
					<cfelseif arguments.mediaProcessType contains 'window'>
						<cfset imageUrl = application.baseUrl & "/images/windows/" & image.serverFile>
					<cfelseif arguments.mediaProcessType contains 'pod'>
						<cfset imageUrl = application.baseUrl & "/images/pods/" & image.serverFile>
					<cfelseif arguments.mediaProcessType contains 'footer'>
						<cfset imageUrl = application.baseUrl & "/images/footer/" & image.serverFile>
					<cfelse>
						<!--- Standard pathway --->
						<cfset imageUrl = application.baseUrl & "/enclosures/" & image.serverFile>
					</cfif>
						
					<!--- Set the thumbnail path --->
					<cfif createThumbnail>
						<cfif mediaProcessType contains 'Background'>
							<cfset imageThumbnailUrl = application.baseUrl & "/images/background/thumbnails/" & image.serverFile>
						<cfelse>
							<cfset imageThumbnailUrl = application.baseUrl & "/enclosures/thumbnails/" & image.serverFile>
						</cfif>
					<cfelse>
						<!--- There is no thumbnail --->
						<cfset imageThumbnailUrl = ''>
					</cfif>
						
					<!--- A5 Create social media images for enclosures --->
					<!--- When saving enclosures, create our social media sharing images --->
					<!--- 2026-10-01: also fires for heroCoverImage - this is the actual mechanism that makes a Hero
					Cover Image drive og:image/twitter:image (seoMetaTags.cfm), replacing the old per-post practice
					of hand-typing facebookImageUrlMetaData/twitterImageUrlMetaData XML Post Directives for a
					Gradient/animation post that has no real photo of its own. --->
					<cfif (arguments.mediaProcessType eq 'enclosure' and arguments.mediaType eq 'image') or arguments.mediaProcessType eq 'heroCoverImage'>
						<cftry>
							<!--- Manipulate the image and save it in the social media sharing folders --->
							<cfset socialMediaImagePath = destination & "\" & image.serverFile>
							<!--- Method: createSocialMediaImages(socialMediaImagePath, socialMediaImageType) --->
							<!--- Create a social media sharing image for Facebook --->
							<cfset facebookSharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'facebook', '', resolvedImageQuality)>
							<cfif isDefined("facebookSharingImage")>
								<cfset mediaActions = listAppend(mediaActions, 'Facebook Sharing Image')>
								<cfset facebookOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#facebookSharingImage#" label="facebook"></cfif>

							<!--- Twiter... --->
							<cfset twitterSharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'twitter', '', resolvedImageQuality)>
							<cfif isDefined("twitterSharingImage")>
								<cfset mediaActions = listAppend(mediaActions, 'Twitter Sharing Image')>
								<cfset twitterOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#twitterSharingImage#"></cfif>
								
							<!--- and the various formats for Google (these are also used for google search) --->
							<cfset google16_9SharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'google', 'google16_9Image', resolvedImageQuality)>
							<cfif isDefined("google16_9SharingImage")>
								<cfset mediaActions = listAppend(mediaActions, 'Google 16x9 Sharing Image')>
								<cfset googleOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#google16_9SharingImage#"></cfif>
								
							<cfset google4_3SharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'google', 'google4_3Image', resolvedImageQuality)>
							<!--- 2026-10-01: fixed - was checking isDefined("google4_3Image"), a variable that's
							never actually set (createSocialMediaImages()'s 3rd argument is just an image-type label
							passed in, not an output variable name) - the real result lands in google4_3SharingImage
							above, so this always fell through silently and "Google 4x3 Sharing Image" never
							appeared in mediaActions even when the crop was generated successfully. --->
							<cfif isDefined("google4_3SharingImage")>
								<cfset mediaActions = listAppend(mediaActions, 'Google 4x3 Sharing Image')>
								<cfset googleOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#google4_3SharingImage#"></cfif>
								
							<cfset google1_1SharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'google', 'google1_1Image', resolvedImageQuality)>
							<!--- 2026-10-01: same fix as google4_3 above - was checking the wrong variable name. --->
							<cfif isDefined("google1_1SharingImage")>
								<cfset mediaActions = listAppend(mediaActions, 'Google 1x1 Sharing Image')>
								<cfset googleOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#google1_1SharingImage#"></cfif>

							<!--- Pinterest - only generated when the source clears the 1000x1500 (2:3) threshold; createSocialMediaImages()
							returns false and writes nothing otherwise, since a smaller/looser crop from a landscape source doesn't fix
							the real problem (wrong shape), it just makes the same bad crop at lower resolution. --->
							<cfset pinterestSharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'pinterest', '', resolvedImageQuality)>
							<cfif isDefined("pinterestSharingImage") and pinterestSharingImage>
								<cfset mediaActions = listAppend(mediaActions, 'Pinterest Sharing Image')>
								<cfset pinterestOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#pinterestSharingImage#"></cfif>

							<!--- Classic GalaxieBlog 1200x900 crop - the universal fallback seoMetaTags.cfm now uses
							whenever a platform-specific crop doesn't exist for a post, instead of silently serving
							the full uncropped original. Always generated, no qualifying gate. --->
							<cfset classicSharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'classic', '', resolvedImageQuality)>
							<cfif isDefined("classicSharingImage") and classicSharingImage>
								<cfset mediaActions = listAppend(mediaActions, 'Classic GalaxieBlog 1200x900 Crop')>
								<cfset classicOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#classicSharingImage#"></cfif>

							<cfcatch type="any">
								<cfset errorMessage = "Error creating social media images">
							</cfcatch>
						</cftry>
					</cfif><!---<cfif arguments.mediaProcessType eq 'enclosure'>--->
							
					<!--- B Save images to the database --->
					<!--- There are three separate logical branches here: 1) update the theme setting, 2) update the video cover with an image in the database, and 3) to insert or update a media record. --->
					
					<!--- B1) Update the theme setting table. 5.0 (2026-10-19): the logos too (logoImage, logoImageMobile and
					defaultLogoImageForSocialMediaShare) - a logo uploaded in Theme Settings was saved as a file but never set on the
					theme, so it was gone when Theme Settings reloaded. Theme pictures are stored from /images/ on, without the blog's
					base URL (as Theme Settings' own save does); with it, a blog in a folder showed /blog/blog/images/... --->
					<cfif arguments.mediaProcessType contains 'Background' or arguments.mediaProcessType eq 'footerImage'
							or listFindNoCase("logoImage,logoImageMobile,defaultLogoImageForSocialMediaShare", arguments.mediaProcessType)>
						<cfinvoke component="#application.blog#" method="saveTheme" returnvariable="themeId">
							<cfinvokeargument name="themeId" value="#arguments.themeId#" />
							<cfinvokeargument name="#arguments.mediaProcessType#" value="#StringUtilsObj.setThemeFilePath(imageUrl)#" />
						</cfinvoke>
					<!--- B2) We only want to update the MediaVideoCoverUrl column when updating the video cover. We don't  need to insert a new media record here. --->
					<cfelseif arguments.mediaProcessType eq 'mediaVideoCoverUrl'>
						
						<!--- Get the mediaId for this enclosure. --->
						<cfset mediaId = application.blog.getEnclosureMediaIdByPostId(arguments.postId)>
							
						<cfinvoke component="#application.blog#" method="updateMediaRecord" returnvariable="mediaId">
							<cfinvokeargument name="mediaId" value="#mediaId#" />
							<cfinvokeargument name="mediaVideoCoverUrl" value="#imageUrl#" />
						</cfinvoke>
							
					<cfelseif arguments.mediaProcessType eq 'profilePicture'>

						<cfinvoke component="#application.blog#" method="saveUserProfileImage">
							<cfinvokeargument name="userId" value="#arguments.userId#" />
							<cfinvokeargument name="profilePicture" value="#imageUrl#" />
						</cfinvoke>

					<!--- B1b) Page Collection hero image - a plain field on the PageCollection entity, same shape as the theme-background case above. --->
					<cfelseif arguments.mediaProcessType eq 'pageCollectionHero'>

						<cfinvoke component="#application.blog#" method="savePageCollectionHeroImage">
							<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
							<cfinvokeargument name="heroImageUrl" value="#imageUrl#" />
						</cfinvoke>

					<!--- B1c) Hero Cover Image - a plain field on the Post entity, same shape as pageCollectionHero
					above - 2026-10-01. Not a Media-table record (unlike mediaVideoCoverUrl/B3 below): this is for
					a post with no real media enclosure at all (Gradient/animation/generated fallback), so there's no
					existing Media row to attach a cover to. --->
					<cfelseif arguments.mediaProcessType eq 'heroCoverImage'>

						<cfinvoke component="#application.blog#" method="savePostHeroCoverImage">
							<cfinvokeargument name="postId" value="#arguments.postId#" />
							<cfinvokeargument name="heroCoverImageUrl" value="#imageUrl#" />
						</cfinvoke>

					<cfelse>
						
						<!--- B3) Update or insert a new media record. 
						Note: this must be put in a cflock otherwise the mediaid may be duplicated. --->
						<cflock type="exclusive" timeout="15">
							<cfif imageExists>
								<!--- Update the record in the database --->
								<cfinvoke component="#application.blog#" method="updateMediaRecord" returnvariable="mediaId">
									<cfif len(arguments.postId)>
										<cfinvokeargument name="postId" value="#arguments.postId#" />
									</cfif>
									<cfif len(arguments.commentId)>
										<cfinvokeargument name="commentId" value="#arguments.commentId#" />
									</cfif>
									<cfif len(arguments.pageCollectionId)>
										<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
									</cfif>
									<cfinvokeargument name="mediaPath" value="#destination & "\" & image.serverFile#" />

									<cfinvokeargument name="mediaUrl" value="#imageUrl#" />
									<cfinvokeargument name="MediaThumbnailUrl" value="#imageThumbnailUrl#" />
									<cfinvokeargument name="mediaTitle" value="#arguments.mediaTitle#" />
									<cfinvokeargument name="mediaType" value="#arguments.mediaType#" />
									<cfinvokeargument name="mimeType" value="#mimeType#" />
									<cfif arguments.mediaProcessType eq 'enclosure'>
										<cfinvokeargument name="enclosure" value="true" />
									<cfelse>
										<cfinvokeargument name="enclosure" value="false" />
									</cfif>
									<cfinvokeargument name="mediaHeight" value="#imageInfo.height#" />
									<cfinvokeargument name="mediaWidth" value="#imageInfo.width#" />
									<cfinvokeargument name="mediaSize" value="#image.filesize#" />
									<cfinvokeargument name="facebookOptimized" value="#facebookOptimized#" />
									<cfinvokeargument name="twitterOptimized" value="#twitterOptimized#" />
									<cfinvokeargument name="googleOptimized" value="#googleOptimized#" />
								</cfinvoke>
							<cfelse><!---<cfif imageExists>--->
								<!--- Insert the record to the database. --->
								<cfinvoke component="#application.blog#" method="insertMediaRecord" returnvariable="mediaId">
									<cfif len(arguments.postId)>
										<cfinvokeargument name="postId" value="#arguments.postId#" />
									</cfif>
									<cfif len(arguments.commentId)>
										<cfinvokeargument name="commentId" value="#arguments.commentId#" />
									</cfif>
									<cfif len(arguments.pageCollectionId)>
										<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
									</cfif>
									<cfinvokeargument name="mediaPath" value="#destination & "\" & image.serverFile#" />
									<cfinvokeargument name="mediaUrl" value="#imageUrl#" />
									<cfinvokeargument name="MediaThumbnailUrl" value="#imageThumbnailUrl#" />
									<cfinvokeargument name="mediaTitle" value="#arguments.mediaTitle#" />
									<cfinvokeargument name="mediaType" value="#arguments.mediaType#" />
									<cfinvokeargument name="mimeType" value="#mimeType#" />
									<cfif arguments.mediaProcessType eq 'enclosure'>
										<cfinvokeargument name="enclosure" value="true" />
									<cfelse>
										<cfinvokeargument name="enclosure" value="false" />
									</cfif>
									<cfinvokeargument name="mediaHeight" value="#imageInfo.height#" />
									<cfinvokeargument name="mediaWidth" value="#imageInfo.width#" />
									<cfinvokeargument name="mediaSize" value="#image.filesize#" />
									<cfinvokeargument name="facebookOptimized" value="#facebookOptimized#" />
									<cfinvokeargument name="twitterOptimized" value="#twitterOptimized#" />
									<cfinvokeargument name="googleOptimized" value="#googleOptimized#" />
								</cfinvoke>
							</cfif><!---<cfif imageExists>--->
						</cflock>

						<!--- Keep the plain HeroImageUrl field (what every front-end template and the Page Collection
						Detail preview actually read) in sync with this Enclosure-based upload - otherwise a new hero
						image uploaded here never shows up anywhere, since HeroImageUrl is a separate field that
						nothing else in this branch touches. --->
						<cfif len(arguments.pageCollectionId)>
							<cfinvoke component="#application.blog#" method="savePageCollectionHeroImage">
								<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
								<cfinvokeargument name="heroImageUrl" value="#imageUrl#" />
							</cfinvoke>
						</cfif>
					</cfif><!---<cfif arguments.mediaProcessType eq 'mediaVideoCoverUrl'>--->
								
					<!--- When using the bundled option, dump the response into the result query. We must do this for every file within the file loop --->
					<cfif usingUppyBundleOption>
						<cfset queryAddRow(responseQuery)>
						<!--- Set the values --->
						<cfset querySetCell(responseQuery,"error",false)>
						<cfset querySetCell(responseQuery,"errorMessage","")>
						<cfset querySetCell(responseQuery,"location","#imageUrl#")>
						<cfset querySetCell(responseQuery,"mediaId","#mediaId#")>
						<!--- The original file name, so the upload window can put the pictures back in the order it showed them (the server processes them in whatever order the multipart parser hands them over). --->
						<cfset querySetCell(responseQuery,"clientFile","#image.clientFile#")>
					</cfif><!---<cfif usingUppyBundleOption>--->

				</cfloop><!---<cfloop array="#UploadObj#" item="image">--->
							
				<!--- C Return data to the client. --->
				<cfif not usingUppyBundleOption>
					<!--- Create a new location struct with the new image URL, the new mediaId, and all of the actions that were taken. This is needed as we have not yet saved the comment when the image is uploaded, and we want to diaply our actions to the user on success. --->
					<!--- Note: this no longer works in CF2021 (it works in prior versions to CF11). It returns the keys in upper case: 
					<cfset imageUrlString = { location="#imageUrl#", mediaId="#mediaId#", mediaActions="#mediaActions#" }>
					--->
					<cfset imageUrlString["location"] = "#imageUrl#">
					<cfset imageUrlString["mediaId"] = "#mediaId#">
					<cfset imageUrlString["mediaActions"] = "#mediaActions#">

					<!--- Return the structure with the image back to the client --->
					<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
					<cfif application.serverProduct eq 'Lucee'>
						<cfset thisResponse = imageUrlString />
					<cfelse>
						<cfset thisResponse = serializeJSON( imageUrlString ) />
					</cfif>

					<cfreturn thisResponse>

				</cfif><!---<cfif usingUppyBundleOption>--->

			<cfelse>
				<!--- Serialize our error list --->
				<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
			</cfif>
				
			<cfif usingUppyBundleOption> 
				<!--- Return the data as a json object. --->  
				<cfinvoke component="#application.cfJsonComponentPath#" method="convertCfQuery2JsonStruct" returnvariable="jsonResponse">
					<cfinvokeargument name="queryObj" value="#responseQuery#">
					<cfinvokeargument name="includeDataHandle" value="false">
					<cfinvokeargument name="dataHandleName" value="">
				</cfinvoke> 
				<!--- Return it --->
				<cfreturn jsonResponse>
			</cfif><!---<cfif usingUppyBundleOption>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfset thisResponse = response />
			<cfelse>
				<cfset thisResponse = serializeJSON( response ) />
			</cfif>
			
			<cfreturn thisResponse>
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->

	</cffunction>
					
	<!--- uploadImageViaUploaderMethod (an old, unused TinyMCE uploader) was removed on 2026-10-14. --->

	<cffunction name="debugTraceLocal" access="private" returntype="void" output="false"
			hint="Temporary, self-contained diagnostic tracer for the uploadVideo() enclosure-not-persisting bug -
			deliberately NOT going through Udf.cfc's debugTrace() (an app-scoped singleton kept getting reverted to
			an old version on disk without picking up cleanly, wasting a lot of a debugging session on cache/reinit
			red herrings that turned out to be a vanishing file, not a caching problem). This is a local private
			method instead, recompiled fresh from this file on every request with no app-scope object to go stale.
			NOT visitor/user tracking - silent (near-zero cost no-op) unless an admin explicitly turns it on for
			their OWN session via TestUtility.cfc's setDebugTrace(), used only while actively reproducing a
			specific bug, then turned back off. It never runs for an ordinary visitor and captures nothing about
			them. Remove this whole function and its call sites once the uploadVideo() bug is resolved.">
		<cfargument name="label" type="string" required="true">
		<cfargument name="data" required="false" default="">
		<cfif not (structKeyExists(session, "debugTraceEnabled") and session.debugTraceEnabled)>
			<cfreturn>
		</cfif>
		<cfset var text = arguments.label>
		<cfif not isSimpleValue(arguments.data)>
			<cftry>
				<cfset text = text & " | " & serializeJSON(arguments.data)>
				<cfcatch type="any">
					<cfset text = text & " | [unserializable data: " & cfcatch.message & "]">
				</cfcatch>
			</cftry>
		<cfelseif len(arguments.data)>
			<cfset text = text & " | " & arguments.data>
		</cfif>
		<cflog file="galaxieDebugTrace" type="information" text="#text#">
	</cffunction>

	<cffunction name="uploadVideo" access="remote" output="false" returnformat="json"
			hint="Very similiar to the uploadImage function, but this function uploads a video and inserts a media record into the database. If the updates were successful, it returns an empty json array.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="mediaProcessType" type="string" default="enclosure" required="false" hint="What media files are we processing? This string determines how to process the image. For example, with enclosures, we want to create social media sharing images for Facebook and Twitter, however, when we process a gallery or an embedded image in a comment, we are not going to need that.">
		<cfargument name="mediaTitle" type="string" default="" required="false">
		<!--- The media type determines what to do with the image. Supported types are found in the media type db table. --->
		<cfargument name="mediaType" type="string" default="largeVideo" required="false">
		<cfargument name="postId" default="" required="false">
		<!--- Some images may not have a comment (ie a post)--->
		<cfargument name="commentId" default="" required="false">
		<cfargument name="pageCollectionId" default="" required="false" hint="Pass in when this video is a Page Collection's hero enclosure instead of a Post's">
		<!--- Uppy posts the file under this field name (see uppyVideoUpload.cfm). It is read by cffile uploadAll, not by this argument, but it must be declared or ColdFusion rejects the call. --->
		<cfargument name="files" default="" required="false">
		<!--- Uppy can also post these file details as form fields. They are not used here, but they must be declared or ColdFusion rejects the call. --->
		<cfargument name="relativePath" default="" required="false">
		<cfargument name="name" default="" required="false">
		<cfargument name="type" default="" required="false">
		<!--- Arguments that are not sent but need to be there after the May 13th 2025 CF update --->
		<cfargument name="selectorId" default="" required="false">	  
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<!--- Set the default response object. --->
		<cfset response = {} />
		<!--- Prepare the response object. --->
		<cfset response[ "message" ] = "" />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<cfif application.Udf.isLoggedIn()>

			<!--- This is NOT visitor/user tracking - debugTrace() is a temporary, opt-in diagnostic aid, silent
			(near-zero cost no-op) unless an admin explicitly turns it on for their OWN session via
			TestUtility.cfc's setDebugTrace(), used only while actively reproducing a specific bug, then turned
			back off. It never runs for an ordinary visitor and captures nothing about them. See Udf.cfc's
			debugTrace() for the full explanation. --->
			<cfset debugTraceLocal("uploadVideo:start", {mediaProcessType: arguments.mediaProcessType, mediaType: arguments.mediaType, postId: arguments.postId, commentId: arguments.commentId, pageCollectionId: arguments.pageCollectionId})>

			<!--- Note: this function follows the best practices given by http://learncfinaweek.com/course/index/section/Security/item/File_Uploads/. --->

			<!--- ************************************ Error checking ************************************ --->

			<!--- Allowed mime types. --->
			<cfset acceptedMimeTypes = {
			'video/mp4': {extension: 'mp4'},
			'video/webm': {extension: 'webm'},
			'video/ogg': {extension: 'ogg'},
			'video/quicktime': {extension: 'mov'},
			'video/mpeg': {extension: 'mpg'}
			}>

			<!--- Reject anything over 100MB. Enclosure videos are short instructional/demo clips shown at the top
			of a post, not primary video content - the biggest video ever legitimately uploaded on this site so far
			is ~16MB (weekndStarBoy1.mp4, in enclosures/videos), so 100MB leaves generous headroom for a longer or
			less-compressed clip while still ruling out someone uploading a raw/uncompressed capture or a full movie
			file by mistake. cffile has no attribute to reject a file by size before it uploads, so this check runs
			AFTER the file lands in the temp directory (see the loop below) - the CF Administrator's own Server
			Settings > Request Tuning > "Maximum size of post data" is the real first line of defense against a
			truly enormous request, and should be set there too as a blanket ceiling across every upload endpoint,
			not just this one. --->
			<!--- Now sourced from Blog Options > Media Uploads (default 100MB) instead of a hardcoded constant, so each
		site can tune it without a code change. --->
		<cfset videoMaxFileSizeBytes = application.BlogOptionDbObj.getVideoMaxFileSizeMB() * 1024 * 1024>

			<!--- Put this in a catch block --->
			<cftry>

				<!--- Upload all of the files to ColdFusion's temporary directory and then check the file(s) before we upload them to our permanent destination. The file field name may vary here, its different for the uppy (ie. files[]) and tinymce (ie file) interfaces, so don't  use it. --->
				<cffile
					action="uploadAll"
					accept="#structKeyList(acceptedMimeTypes)#"
					strict="true"
					destination="#getTempDirectory()#"
					mode = "644"
					nameconflict="overwrite"
					result="UploadObj">
					
				<cfcatch type="any">
					<!--- File is not written to disk if error is thrown  --->
					<!--- Prevent zero length files --->
					<cfif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Zero length file</li>">
					<!--- Prevent invalid file types --->
					<cfelseif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>The MIME type or the Extension of the uploaded file</li>">
					<!--- Prevent empty form field --->
					<cfelseif findNoCase( "did not contain a file.", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Empty form</li>">
					<!--- Catch all other errors --->
					<cfelse>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Unhandled File Upload Error: #cfcatch.message#</li>">
					</cfif>
				</cfcatch>
			</cftry>

			<cfset debugTraceLocal("uploadVideo:afterFileUpload", {error: error, errorMessage: errorMessage, fileCount: (isDefined("UploadObj") ? arrayLen(UploadObj) : -1)})>

			<!--- *********** If there were no errors, move the video to the desired destination  ************ --->
			<cfif not error>

				<!--- There can be one or more videos. Loop through the video array provided by cffile --->
				<cfloop array="#UploadObj#" item="video">

					<!--- Reject an oversized video now, before it ever reaches the permanent enclosures/videos
					folder - delete the temp copy and bail out with a proper error response rather than silently
					moving/DB-recording a huge file. --->
					<cfif video.fileSize gt videoMaxFileSizeBytes>
						<cffile action="delete" file="#video.ServerDirectory#/#video.ServerFile#">
						<cfset response = {}>
						<cfset response["errorMessage"] = "<ul><li>Video is too large (" & numberFormat(video.fileSize / 1024 / 1024, "0.0") & "MB). The maximum allowed size is " & (videoMaxFileSizeBytes / 1024 / 1024) & "MB.</li></ul>">
						<cfset debugTraceLocal("uploadVideo:tooLarge", {fileSize: video.fileSize, maxBytes: videoMaxFileSizeBytes})>
						<cfif application.serverProduct eq 'Lucee'>
							<cfreturn response>
						<cfelse>
							<cfreturn serializeJSON(response)>
						</cfif>
					</cfif>

					<!--- Determine the mime type --->
					<cfset mimeType = fileGetMimeType( video.ServerDirectory & '/' & video.ServerFile, true )>

					<!--- Set our final destination. --->
					<cfset destination = expandPath("#application.baseUrl#/enclosures/videos/")>
					
					<!--- Move the file to the final destination. --->
					<cffile 
						action="move"
						source="#video.serverDirectory#/#video.serverFile#"
						destination="#destination#" 
						mode="644">
						
					<!--- Get the full path and the name of the file --->
					<cfset videoUrl = application.baseUrl & "/enclosures/videos/" & video.serverFile>
						
					<!--- See if the enclosure record already exists --->
					<cfif len(arguments.postId)>
						<cfinvoke component="#application.blog#" method="getPostEnclosureMediaIdByUrl" returnvariable="mediaId">
							<cfinvokeargument name="postId" value="#arguments.postId#">
							<cfinvokeargument name="mediaUrl" value="#videoUrl#">
						</cfinvoke>
					<cfelseif len(arguments.pageCollectionId)>
						<cfinvoke component="#application.blog#" method="getPageCollectionEnclosureMediaIdByUrl" returnvariable="mediaId">
							<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#">
							<cfinvokeargument name="mediaUrl" value="#videoUrl#">
						</cfinvoke>
					<cfelse>
						<!--- This is a comment. Set the mediaId to 0 to insert a new record.--->
						<cfset mediaId = 0>
					</cfif>

					<cfset debugTraceLocal("uploadVideo:mediaIdLookup", {existingMediaId: mediaId, videoUrl: videoUrl})>

					<!--- Insert the record to the database. --->
					<cfif mediaId eq 0>
						<cfinvoke component="#application.blog#" method="insertMediaRecord" returnvariable="mediaId">
							<cfif len(arguments.postId)>
								<cfinvokeargument name="postId" value="#arguments.postId#" />
							</cfif>
							<cfif len(arguments.commentId)>
								<cfinvokeargument name="commentId" value="#arguments.commentId#" />
							</cfif>
							<cfif len(arguments.pageCollectionId)>
								<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
							</cfif>
							<cfinvokeargument name="mediaPath" value="#destination & "\" & video.serverFile#" />
							<cfinvokeargument name="mediaUrl" value="#videoUrl#" />
							<cfinvokeargument name="MediaThumbnailUrl" value="" />
							<cfinvokeargument name="mediaTitle" value="" />
							<cfinvokeargument name="mediaType" value="#arguments.mediaType#" />
							<cfinvokeargument name="mimeType" value="#mimeType#" />
							<cfif arguments.mediaProcessType eq 'enclosure'>
								<cfinvokeargument name="enclosure" value="true" />
							<cfelse>
								<cfinvokeargument name="enclosure" value="false" />
							</cfif>
							<cfinvokeargument name="mediaHeight" value="" />
							<cfinvokeargument name="mediaWidth" value="" />
							<cfinvokeargument name="mediaSize" value="#video.filesize#" />
						</cfinvoke>
						<cfset response[ "mediaAction" ] = "insert" />
						<cfset debugTraceLocal("uploadVideo:insertMediaRecord:done", {newMediaId: mediaId, postId: arguments.postId})>
					<cfelse>
						<!--- Update the existing record --->
						<cfinvoke component="#application.blog#" method="updateMediaRecord" returnvariable="mediaId">
							<cfinvokeargument name="mediaId" value="#mediaId#" />
							<cfif len(arguments.postId)>
								<cfinvokeargument name="postId" value="#arguments.postId#" />
							</cfif>
							<cfif len(arguments.commentId)>
								<cfinvokeargument name="commentId" value="#arguments.commentId#" />
							</cfif>
							<cfif len(arguments.pageCollectionId)>
								<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
							</cfif>
							<cfinvokeargument name="mediaPath" value="#destination & "\" & video.serverFile#" />
							<cfinvokeargument name="mediaUrl" value="#videoUrl#" />
							<cfinvokeargument name="MediaThumbnailUrl" value="" />
							<cfinvokeargument name="mediaTitle" value="" />
							<cfinvokeargument name="mediaType" value="#arguments.mediaType#" />
							<cfinvokeargument name="mimeType" value="#mimeType#" />
							<cfif arguments.mediaProcessType eq 'enclosure'>
								<cfinvokeargument name="enclosure" value="true" />
							<cfelse>
								<cfinvokeargument name="enclosure" value="false" />
							</cfif>
							<cfinvokeargument name="mediaHeight" value="" />
							<cfinvokeargument name="mediaWidth" value="" />
							<cfinvokeargument name="mediaSize" value="#video.filesize#" />
						</cfinvoke>
						<cfset response[ "mediaAction" ] = "update" />
						<cfset debugTraceLocal("uploadVideo:updateMediaRecord:done", {updatedMediaId: mediaId, postId: arguments.postId})>
					</cfif>

				</cfloop><!---<cfloop array="#UploadObj#" item="video">--->

				<!--- Create a new location struct with the new video URL. Also include the new mediaId. This is needed as we have not yet saved the comment when the video is uploaded. --->
				<cfset response[ "postId" ] = arguments.postId />
				<cfset response[ "mediaId" ] = mediaId />
				<cfset response[ "location" ] = videoUrl />
				<cfset debugTraceLocal("uploadVideo:response", response)>
			<cfelse><!---<cfif not error>--->
				<!--- Serialize our error list --->
				<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
			
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
				
	</cffunction>
				
	<cffunction name="saveExternalMediaEnclosure" access="remote" output="false" returnformat="json"
			hint="We need to update the database when an external image is added to an enclosure. Note: this function is called whenever media is placed into the tinymce editor, even if there was just a successfull image upload. We are doing this as we don't know every event that is taking place in the image editor- there are multiple things that can happen with an image, it can be changed, a link can be made, etc. We need to check to see if the mediaId exists and see if the image is the same as the current mediaId record, if it exists, to determine whether to update the database or not. And if the image was not modified, we may not do anything at all.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="mediaId" type="string" default="" required="false" hint="Pass in the mediaId if available.">
		<cfargument name="externalUrl" type="string" default="" required="true" hint="What is the external URL?">
		<cfargument name="mimeType" default="" required="false" hint="Pass in the mime type if available">
		<cfargument name="postId" default="" required="false">
		<cfargument name="themeId" default="" required="false">
		<cfargument name="pageCollectionId" default="" required="false">
		<cfargument name="mediaType" default="image" required="false" hint="Either image or video">
		<cfargument name="imageType" default="image" required="false" hint="Used to determine the image type when updating a user profile image or a theme type image. Only used for users and themes">
		<cfargument name="videoProvider" default="" required="false" hint="The video provider (i.e. Google (Google YouTube Redirect), Microsoft Stream, VideoPress, Vimeo or YouTube). In this version, we are only supporting Vimeo and YouTube, but I will add support for other video providers in the future.">
		<cfargument name="providerVideoId" default="" required="false" hint="The providers video Id (i.e. the Vimeo or YouTube Id)">
		<cfargument name="selectorId" default="" required="false" hint="We need to know where this request is being posted from to determine the logic as necessary.">
		<!--- Arguments that are not used but required after the May 13th 2025 update --->
		<cfargument name="invokedArguments" default="" required="false" hint="This is not used but required after the May 13 2025 CF update">
		<cfargument name="template" default="" required="false" hint="This is not used but required after the May 13 2025 CF update">
			
		<!--- Default params --->
		<cfparam name="imageHeight" default="" type="string">
		<cfparam name="imageWidth" default="" type="string">
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<cfset debug = false>
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
		
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<!---<cfoutput>arguments.externalUrl: #arguments.externalUrl#</cfoutput>--->
			
		<cfif application.Udf.isLoggedIn()>
			
			<!--- If the mediaId was not passed in, and we are dealing with a post (or a page collection), see if the record already exists --->
			<cfif not len(arguments.mediaId) and len(arguments.postId)>
				<cfinvoke component="#application.blog#" method="getPostEnclosureMediaIdByUrl" returnvariable="arguments.mediaId">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="mediaUrl" value="#arguments.externalUrl#">
				</cfinvoke>
			<cfelseif not len(arguments.mediaId) and len(arguments.pageCollectionId)>
				<cfinvoke component="#application.blog#" method="getPageCollectionEnclosureMediaIdByUrl" returnvariable="arguments.mediaId">
					<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#">
					<cfinvokeargument name="mediaUrl" value="#arguments.externalUrl#">
				</cfinvoke>
			</cfif>
					
			<cfif len(arguments.mimeType)>
				<cfset mimeType = arguments.mimeType>
			<cfelse>		
				<!--- Try to get the mime type. It may not be available due to a 403 forbidden error. --->
				<cftry>
					<cfhttp method="get" URL="#arguments.externalUrl#">
					<cfset mimeType = cfhttp.mimeType>
					<cfcatch type="any">
						<cfset mimeType = "">
					</cfcatch>
				</cftry>
			</cfif>
				
			<!--- Update the user or theme record. The selectorId for a post is 'enclosureEditor'. Profile pictures and theme oriented images Theme use the image uploader ('imageUploadEditor') --->
			<cfif arguments.selectorId neq "" and arguments.selectorId eq 'imageUploadEditor'>
				<!--- Handle the profile picture and update the user table. --->
				<cfif imageType eq 'profilePicture'>
					<cfinvoke component="#application.blog#" method="saveUserProfileImage" returnvariable="userId">
						<cfinvokeargument name="userId" value="#arguments.userId#" />
						<cfinvokeargument name="profilePicture" value="#arguments.externalUrl#" />
					</cfinvoke>
				<!--- Page Collection hero image - a plain field on the PageCollection entity, same shape as the theme case below. --->
				<cfelseif imageType eq 'pageCollectionHero'>
					<cfinvoke component="#application.blog#" method="savePageCollectionHeroImage">
						<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
						<cfinvokeargument name="heroImageUrl" value="#arguments.externalUrl#" />
					</cfinvoke>
				<!--- All of the other images used by the imageUploadEditor are theme oriented --->
				<cfelse><!---<cfif imageType eq 'profilePicture'>--->
					<cfinvoke component="#application.blog#" method="saveThemeSettingImage" returnvariable="themeId">
						<cfinvokeargument name="themeId" value="#arguments.themeId#" />
						<cfinvokeargument name="imageType" value="#arguments.imageType#" />
						<cfinvokeargument name="externalURL" value="#arguments.externalUrl#" />
					</cfinvoke>
				</cfif><!---<cfif imageType eq 'profilePicture'>--->
					
			<!--- Update the current media record with the URL of the video cover. --->
			<cfelseif arguments.selectorId neq "" and arguments.selectorId eq 'videoCoverEditor'>
				<!--- Get the mediaId for this enclosure. --->
				<cfif not len(arguments.mediaId)>
					<cfset arguments.mediaId = application.blog.getEnclosureMediaIdByPostId(arguments.postId)>
				</cfif>
					
				<cfinvoke component="#application.blog#" method="updateMediaRecord" returnvariable="mediaId">
					<cfinvokeargument name="postId" value="#arguments.postId#" />
					<cfinvokeargument name="mediaId" value="#arguments.mediaId#" />
					<cfinvokeargument name="mediaVideoCoverUrl" value="#arguments.externalUrl#" />
				</cfinvoke>
			
			<!--- Insert a new media record into the database. --->
			<cfelse><!---<cfif arguments.selectorId and arguments.selectorId eq 'videoCoverEditor'>--->
				
				<!--- Get the mediaType by the provider argument. This will return either 'Video - YouTube URL' or 'Video - Vimeo URL' at this time --->
				<cfif len(arguments.videoProvider)>
					<cfinvoke component="#application.blog#" method="getMediaTypeByVideoProvider" returnvariable="mediaTypeStrId">
						<cfinvokeargument name="provider" value="#arguments.videoProvider#">
					</cfinvoke>
				<cfelse>
					<cfset mediaTypeStrId = arguments.mediaType>
				</cfif>
					
				<!--- If the mediaId is present, see if the URL is different than the current URL in the media table. --->
				<cfif len(arguments.mediaId)>
					
					<!--- Get the URL if available from the media table --->
					<cfset mediaUrl = application.blog.getMediaUrlByMediaId(arguments.mediaId)>
						
					<cfif debug>
						Debugging:<br/>
						<cfoutput>
							Updating mediaId #mediaId#<br/>
							arguments.videoProvider: #arguments.videoProvider#<br/>
							mediaTypeStrId: #mediaTypeStrId#<br/>
							mediaUrl: #mediaUrl#<br/> 
							externalUrl: #externalUrl#<br/> 
							findNoCase(mediaUrl, externalUrl): #findNoCase(externalUrl, mediaUrl)#<br/>
						</cfoutput>
					</cfif>
						
					<!--- If the media record was found... --->
					<cfif len(mediaUrl)>
						<!--- Are the URL's the same? --->
						<cfif findNoCase(externalUrl, mediaUrl)>
							<!--- No need to insert a record --->
							<cfset insertMediaTable = false>
							<!--- don't update the media table. It is the same URL. --->
							<cfset updateMediaTable = false>
						<cfelse>
							<!--- don't insert a record --->
							<cfset insertMediaTable = false>
							<!--- Update the media table as the URL's are not the same. --->
							<cfset updateMediaTable = true>
						</cfif>
					<cfelse><!---<cfif len(mediaUrl)>--->
						<!--- Insert the record --->
						<cfset insertMediaTable = true>
						<cfset updateMediaTable = false>
					</cfif><!---<cfif len(mediaUrl)>--->
						
				<cfelse><!---<cfif len(arguments.mediaId)>--->
					
					<!--- See if the media record exists via the externalUrl. This only occurs when the mediaId is not passed. --->
					<cfset arguments.mediaId = application.blog.getMediaIdByMediaUrl(arguments.externalUrl)>
					
					<cfif len(arguments.mediaId)>
						<!--- Update the record --->
						<cfset insertMediaTable = false>
						<cfset updateMediaTable = true>
					<cfelse>
						<!--- Insert the record --->
						<cfset insertMediaTable = true>
						<cfset updateMediaTable = false>	
					</cfif>
				
				</cfif><!---<cfif len(arguments.mediaId)>--->
						
				<cfif debug>
					<cfoutput>
					Debugging: insertMediaTable: #insertMediaTable#<br/>
					updateMediaTable: #updateMediaTable#<br/>
					</cfoutput>
				</cfif>
				
				<!--- Insert the record if the mediaId was not passed in. --->
				<cfif insertMediaTable>
					
					<!--- Insert the record to the database. --->
					<cfinvoke component="#application.blog#" method="insertMediaRecord" returnvariable="mediaId">
						<cfif len(arguments.postId)>
							<cfinvokeargument name="postId" value="#arguments.postId#" />
						</cfif>
						<cfif len(arguments.pageCollectionId)>
							<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
						</cfif>
						<cfinvokeargument name="mediaPath" value="" />
						<cfinvokeargument name="mediaUrl" value="#externalUrl#" />
						<cfinvokeargument name="MediaThumbnailUrl" value="" />
						<cfinvokeargument name="mediaTitle" value="" />
						<cfinvokeargument name="mediaType" value="#mediaTypeStrId#" />
						<!--- The mime type may not be available --->
						<cfif len(mimeType)>
							<cfinvokeargument name="mimeType" value="#mimeType#" />
						</cfif>
						<!--- This is *not* an enlosure if it is coming from the post editor. --->
						<cfif selectorId neq 'postEditor'>
							<cfinvokeargument name="enclosure" value="true" />
						<cfelse>
							<cfinvokeargument name="enclosure" value="false" />
						</cfif>
						<cfinvokeargument name="mediaHeight" value="#imageHeight#" />
						<cfinvokeargument name="mediaWidth" value="#imageWidth#" />
						<cfinvokeargument name="mediaSize" value="" />
						<cfinvokeargument name="providerVideoId" value="#arguments.providerVideoId#" />
					</cfinvoke>

				<cfelse><!---<cfif insertMediaTable>--->

					<cfif updateMediaTable>
						<!--- Update the record to the database. --->
						<cfinvoke component="#application.blog#" method="updateMediaRecord" returnvariable="mediaId">
							<cfif len(arguments.postId)>
								<cfinvokeargument name="postId" value="#arguments.postId#" />
							</cfif>
							<cfif len(arguments.pageCollectionId)>
								<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
							</cfif>
							<cfinvokeargument name="mediaId" value="#arguments.mediaId#" />
							<cfinvokeargument name="mediaPath" value="" />
							<cfinvokeargument name="mediaUrl" value="#externalUrl#" />
							<cfinvokeargument name="MediaThumbnailUrl" value="" />
							<cfinvokeargument name="mediaTitle" value="" />
							<cfinvokeargument name="mediaType" value="#mediaTypeStrId#" />
							<!--- The mime type may not be available --->
							<cfinvokeargument name="mimeType" value="#mimeType#" />
							<!--- This is *not* an enlosure if it is coming from the post editor. --->
							<cfif selectorId neq 'postEditor'>
								<cfinvokeargument name="enclosure" value="true" />
							<cfelse>
								<cfinvokeargument name="enclosure" value="false" />
							</cfif>
							<cfinvokeargument name="mediaHeight" value="#imageHeight#" />
							<cfinvokeargument name="mediaWidth" value="#imageWidth#" />
							<cfinvokeargument name="mediaSize" value="" />
							<cfinvokeargument name="providerVideoId" value="#arguments.providerVideoId#" />
						</cfinvoke>
					</cfif><!---<cfif updateMediaTable>--->
				</cfif><!---<cfif insertMediaTable>--->

				<!--- Same HeroImageUrl sync as uploadImage's equivalent branch, for the external-URL (paste a link)
				version of this same upload. --->
				<cfif len(arguments.pageCollectionId) and arguments.mediaType eq 'image'>
					<cfinvoke component="#application.blog#" method="savePageCollectionHeroImage">
						<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#" />
						<cfinvokeargument name="heroImageUrl" value="#externalUrl#" />
					</cfinvoke>
				</cfif>

			</cfif><!---<cfif arguments.selectorId and arguments.selectorId eq 'videoCoverEditor'>--->
			
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
				
		<!--- Prepare the response object --->
		<cfset response[ "postId" ] = arguments.postId />
    	<cfset response[ "mediaId" ] = arguments.mediaId />
		<cfset response[ "externalUrl" ] = arguments.externalUrl />
					
		<!--- Return it --->
		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
		</cfif>
	</cffunction>
				
	<cffunction name="removeMediaEnclosure" access="remote" output="false" returnformat="json"
			hint="This removes any existing post (or page collection) enclosures from the database">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="postId" default="" required="false" hint="Mutually exclusive with pageCollectionId">
		<cfargument name="pageCollectionId" default="" required="false" hint="Pass in when removing a Page Collection's hero enclosure instead of a Post's">
		<!--- 2026-10-16: the editor sends template=enclosureImageEditor in the address, and Adobe ColdFusion refuses an argument a remote
		function doesn't declare - so removing a picture always failed there (a JSON error in the editor). --->
		<cfargument name="template" default="" required="false" hint="Which window called this (not used).">
		
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<cfset debug = false>
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
		
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<!---<cfoutput>arguments.externalUrl: #arguments.externalUrl#</cfoutput>--->
			
		<cfif application.Udf.isLoggedIn()>

			<cftransaction>
				<cfif len(arguments.postId)>
					<!--- Load the entity. --->
					<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
					<!--- Set the enclosure media ref to null --->
					<cfset PostDbObj.setEnclosureMedia(javaCast("null",""))>
					<!--- Save the Post. --->
					<cfset EntitySave(PostDbObj)>
				<cfelseif len(arguments.pageCollectionId)>
					<cfset PageCollectionDbObj = entityLoad("PageCollection", { pageCollectionId = arguments.pageCollectionId }, "true" )>
					<cfset PageCollectionDbObj.setEnclosureMedia(javaCast("null",""))>
					<cfset EntitySave(PageCollectionDbObj)>
				</cfif>
			</cftransaction>
			<!--- The public collection pages are cached - clear them so the removed hero doesn't keep showing. --->
			<cfif len(arguments.pageCollectionId)>
				<cfset application.blog.flushGalaxieCache('pageCollection')>
			<!--- And a post's page and the card listings (2026-10-16): until now the removed picture kept showing on the site until the cache was refreshed. --->
			<cfelseif isValid("integer", arguments.postId)>
				<cfset application.blog.flushGalaxieCache(type = "post", postId = val(arguments.postId))>
			</cfif>

			<cfreturn len(arguments.postId) ? arguments.postId : arguments.pageCollectionId>
		<cfelse>
			<cfreturn 0>
		</cfif>

	</cffunction>

	<!---****************************************************************************************************
		Custom Window functions
	******************************************************************************************************--->
				
	<cffunction name="saveCustomWindow" access="remote" output="false" returnformat="json" 
			hint="Saves data from the create custom window interface.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="postId" type="string" default="">
		<cfargument name="customWindowId" type="string" default="">
		<cfargument name="buttonLabel" type="string" required="true">
		<cfargument name="windowTitle" type="string" required="true">
		<cfargument name="unitMeasure" type="string" required="false" default="px">
		<cfargument name="windowHeight" type="string" required="true">
		<cfargument name="windowWidth" type="string" required="true">
		<cfargument name="cfincludePath" type="string" default="">
		<cfargument name="windowContent" type="string" default="">
		<cfargument name="active" type="boolean" default="true">
		<!--- These arguments are needed after CF2023 update. This is not used other than to prevent an error --->
		<cfargument name="selectorid" type="string" default="">
		<cfargument name="unitmeasurement" type="string" default="">	 

		<cfparam name="error" type="boolean" default="false">
		<cfparam name="errorMessage" type="string" default="">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AddPost,AssetEditor,EditComment,ReleasePost')>
		
		<!---Set the default response objects.--->
  		<cfset response[ "success" ] = false />
    	<cfset response[ "errorMessage" ] = "" />

		<!--- Only admins can update this. --->
		<cfif application.Udf.isLoggedIn()>

			<!--- Validate the data --->
			<cfif not len(arguments.buttonLabel)>
				<cfset error = true>
				<cfset errorMessage = "<li>Button label is required but was not filled in</li>">
			</cfif>
			<cfif not len(arguments.windowTitle)>
				<cfset error = true>
				<cfset errorMessage = "<li>Title is required but was not filled in</li>">
			</cfif>
			<cfif not len(arguments.windowHeight)>
				<cfset error = true>
				<cfset errorMessage = "<li>Height is required but was not filled in</li>">
			</cfif>
			<cfif not len(arguments.windowWidth)>
				<cfset error = true>
				<cfset errorMessage = "<li>Width is required but was not filled in</li>">
			</cfif>
			<cfif not len(arguments.cfincludePath) and not len(arguments.windowContent)>
				<cfset error = true>
				<cfset errorMessage = "<li>Either a cfinclude or content must be filled out</li>">
			</cfif>
			<!---<cfif len(arguments.cfincludePath) and not fileExists(expandPath(arguments.cfincludePath))>
				<cfset error = true>
				<cfset errorMessage = "<li>Cfinclude not found. Please check your path or upload the ColdFusion template to the server in the proper directory.</li>">
			</cfif>--->
			
			<cfif not error>
				
				<!--- Remove special tags that we changed to bypass Global Script Protection- this removes any <attachScript tags and replaces them with <script as well as handling css and meta tags the same way.  --->
				<cfset windowContent = StringUtilsObj.sanitizeStrForDb(arguments.windowContent)>
				
				<!--- Set the windowHeight and width along with the unit of measurement --->
				<cfset thisWindowHeight = arguments.windowHeight & arguments.unitMeasurement>
				<cfset thisWindowWidth = arguments.windowWidth & arguments.unitMeasurement>

				<cftransaction>
					<!--- Load the media ORM database object. --->
					<cfif len(arguments.customWindowId) and arguments.customWindowId gt 0>
						<cfset CustomWindowObj = EntityLoadByPk("CustomWindowContent", arguments.customWindowId)>
					<cfelse>
						<cfset CustomWindowObj = entityNew("CustomWindowContent")>
					</cfif>
					<!--- Save the data --->
					<cfif len(arguments.postId)>
						<cfset CustomWindowObj.setPostRef(arguments.postId)>
					</cfif>
					<cfset CustomWindowObj.setButtonName(application.blog.makeAlias(windowTitle))>
					<cfset CustomWindowObj.setButtonLabel(buttonLabel)>
					<cfset CustomWindowObj.setWindowName(application.blog.makeAlias(windowTitle))>
					<cfset CustomWindowObj.setWindowTitle(windowTitle)>
					<cfset CustomWindowObj.setWindowHeight(thisWindowHeight)>
					<cfset CustomWindowObj.setWindowWidth(thisWindowWidth)>
					<cfset CustomWindowObj.setCfincludePath(arguments.cfincludePath)>
					<!--- The windowContent variable strips out any special tags that we are using to bypass Global Script Protection. In this case, we are stripping out the attachIframe tag that the bypassScriptProtection javascript function places to allow iframes to be sent over using Ajax --->
					<cfset CustomWindowObj.setContent(windowContent)>
					<cfset CustomWindowObj.setActive(arguments.active)>
					<cfset CustomWindowObj.setDate(application.blog.blogNow())>
					<!--- And finally, load the blog entity. This is not functional at the moment to have several blogs on a site, but the logic is in the database. --->
					<cfset BlogDbObj = entityLoadByPk("Blog", 1)>
					<!--- Set the blog ref the Theme table --->
					<cfset CustomWindowObj.setBlogRef(BlogDbObj)>
					<!--- Save it. --->
					<cfset EntitySave(CustomWindowObj)>
				</cftransaction>

				<!--- Return the HTML for the button to the client.--->
				<cfsavecontent variable="customWindowButton">
					<cfoutput>
					<button id="customWindow#CustomWindowObj.getCustomWindowContentId()#" name="customWindow#CustomWindowObj.getCustomWindowContentId()#" class="k-button k-primary" onclick="javascript:createCustomInterfaceWindow(#CustomWindowObj.getCustomWindowContentId()#,#postId#);"><span class="fa-solid fa-up-right-from-square fa-2xs"></span> &nbsp;#buttonLabel#</button>
					</cfoutput>
				</cfsavecontent>
			<cfelse>
				<cfset error = true>
				<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
			</cfif><!---<cfif not error>--->
		<cfelse><!---<cfif application.Udf.isLoggedIn()>--->	
			<cfset error = true>
			<cfset errorMessage = errorMessage & "<li>Not logged on</li>">	
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->

		<!--- Prepare the default response objects --->
		<cfif error>
			<cfset response[ "success" ] = false />		
			<!--- Set the error response --->
			<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
		<cfelse>
			<!--- Return a success --->
			<cfset response[ "success" ] = true />
			<!--- Send back the windowId --->
			<cfset response[ "customWindowId" ] = CustomWindowObj.getCustomWindowContentId() />
			<!--- Send back the postId --->
			<cfset response[ "postId" ] = arguments.postId />	
			<!--- Send the title alias, this will be the link --->
			<cfset response[ "titleAlias" ] = application.blog.makeAlias(windowTitle) />
			<!--- Send back our html --->
			<cfset response[ "buttonHtml" ] = customWindowButton />
		</cfif>
    
    	<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
			
	</cffunction>
					
	<!---******************************************************************************************************
		Fonts
	*******************************************************************************************************--->
									
	<cffunction name="uploadFont" access="remote" output="false" returnformat="json"
			hint="Very similiar to the uploadImage and uploadVideo functions, but this function uploads fonts and inserts a font record into the database. If the updates were successful, it returns an empty json array.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="fontName" type="string" default="" required="false">
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<cfif application.Udf.isLoggedIn()>
		
			<!--- Note: this function follows the best practices given by http://learncfinaweek.com/course/index/section/Security/item/File_Uploads/. ---> 
			
			<!--- ************************************ Error checking ************************************ --->

			<!--- Put this in a catch block --->
			<cftry>
				
				<!--- Upload all of the files to ColdFusion's temporary directory and then check the file(s) before we upload them to our permanent destination. The file field name may vary here, its different for the uppy (ie. files[]) and tinymce (ie file) interfaces, so don't  use it. Note: I am having problems nailing down the font mime type and need to turn off the scrict argument here as the upload fails with the arg set to true. --->
				<cffile 
					action="uploadAll" 
					accept=".otf, .ttf, .woff, .woff2"
					strict="false" 
					destination="#getTempDirectory()#" 
					mode = "644"
					nameconflict="overwrite"
					result="UploadObj">
					
				<cfcatch type="any">
					<!--- File is not written to disk if error is thrown  --->
					<!--- Prevent zero length files --->
					<cfif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Zero length file</li>">
					<!--- Prevent invalid file types --->
					<cfelseif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>The MIME type or the Extension of the uploaded file</li>">
					<!--- Prevent empty form field --->
					<cfelseif findNoCase( "did not contain a file.", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Empty form</li>">
					<!--- Catch all other errors --->
					<cfelse>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Unhandled File Upload Error: #cfcatch.message#</li>">
					</cfif>
				</cfcatch>
			</cftry>
							
			<!--- *********** If there were no errors, move the font to the desired destination  ************ --->
			<cfif not error>
					
				<!--- There can be one or more font. Loop through the font array provided by cffile --->
				<cfloop array="#UploadObj#" item="font">

					<!--- Reject anything over 2MB - a real webfont file (woff/woff2/ttf/otf) is virtually always
					well under 1MB, so this is already generous. Lower risk than images/video (fonts are small by
					nature), but the same missing check as uploadImage/uploadVideo existed here too. --->
					<cfif font.fileSize gt (2 * 1024 * 1024)>
						<cffile action="delete" file="#font.ServerDirectory#/#font.ServerFile#">
						<cfset response = {}>
						<cfset response["errorMessage"] = "<ul><li>Font file is too large (" & numberFormat(font.fileSize / 1024 / 1024, "0.0") & "MB). The maximum allowed size is 2MB.</li></ul>">
						<cfif application.serverProduct eq 'Lucee'>
							<cfreturn response>
						<cfelse>
							<cfreturn serializeJSON(response)>
						</cfif>
					</cfif>

					<!--- Determine the mime type --->
					<cfset mimeType = fileGetMimeType( font.ServerDirectory & '/' & font.ServerFile, true )>

					<!--- Set our final destination. --->
					<cfset destination = expandPath("#application.baseUrl#/common/fonts/")>
					
					<!--- Move the file to the final destination. --->
					<cffile 
						action="move"
						source="#font.serverDirectory#/#font.serverFile#"
						destination="#destination#" 
						mode="644">
						
					<!--- Get the file name --->
					<cfset fileName = font.serverFile>
					<!--- Get the full path and the name of the file --->
					<cfset fontUrl = application.baseUrl & "/common/font/" & font.serverFile>
						
					<!--- Determine if this is a woff or woff2 file --->
					<cfparam name="woff" default="false">
					<cfparam name="woff2" default="false">
					<cfif fileName contains '.woff2'>
						<cfset woff2 = true>
					<cfelseif fileName contains '.woff'>
						<cfset woff = true>
					</cfif> 

					<!--- We don't  want to save the extension in the file name. We will determine it dyncamically based upon the woff and woff2 columns in the font table. --->
					<cfset fileNameWithoutExtension = trim(listGetAt(fileName, 1, '.'))>
						
					<cfquery name="Data" dbtype="hql">
						SELECT new Map (
							FontId as FontId,
							FileName
						)
						FROM 
							Font as Font
						WHERE 
							Font.FileName = <cfqueryparam value="#trim(fileNameWithoutExtension)#" cfsqltype="cf_sql_varchar">
					</cfquery>

					<cfif arrayLen(Data)>
						<cfinvoke component="#application.blog#" method="updateFontRecordAfterUpload" returnvariable="fontId">
							<cfinvokeargument name="fontId" value="#Data[1]['FontId']#">
							<cfinvokeargument name="woff" value="#woff#">
							<cfinvokeargument name="woff2" value="#woff2#">
						</cfinvoke>
					<cfelse>
						<cfinvoke component="#application.blog#" method="insertFontRecord" returnvariable="fontId">
							<cfinvokeargument name="fileName" value="#fileName#">
							<cfinvokeargument name="woff" value="#woff#">
							<cfinvokeargument name="woff2" value="#woff2#">
							<cfinvokeargument name="webSafeFont" value="0">
							<cfinvokeargument name="selfHosted" value="1">
							<cfinvokeargument name="useFont" value="1">
						</cfinvoke>
					</cfif>
				
				</cfloop><!---<cfloop array="#UploadObj#" item="video">--->
					
				<!--- Create a new location struct with the new video URL. Also include the new mediaId. This is needed as we have not yet saved the comment when the video is uploaded. --->
								
				<!--- Get the extension --->
				<cfif woff>
					<cfset woffExtension = '.woff'>
				<cfelseif woff2>
					<cfset woffExtension = '.woff2'>
				</cfif>
				<!--- Note: the following syntax no longer works with CF2021 (it worked in CF2016). The keys are not preserved and are in uppercase.
				<cfset uploadedFontStruct = { fontUrl="#fontUrl#", fontId="#fontId#" }>
				--->
				<cfset uploadedFontStruct["fontUrl"] = "#fontUrl#">
				<cfset uploadedFontStruct["fontId"] = "#fontId#">
					
				<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
				<cfif application.serverProduct eq 'Lucee'>
					<cfset thisResponse = uploadedFontStruct />
				<cfelse>
					<cfset thisResponse = serializeJSON( uploadedFontStruct ) />
				</cfif>

				<cfreturn thisResponse>
					
			<cfelse>
				
				<!--- Serialize our error list --->
				<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
				
				<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
				<cfif application.serverProduct eq 'Lucee'>
					<cfset thisResponse = response />
				<cfelse>
					<cfset thisResponse = serializeJSON( response ) />
				</cfif>

				<cfreturn thisResponse>
			</cfif>
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfset thisResponse = response />
			<cfelse>
				<cfset thisResponse = serializeJSON( response ) />
			</cfif>

			<cfreturn thisResponse>
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->

	</cffunction>
				
	<cffunction name="saveFontAfterUpload" access="remote" output="false" returnformat="json"
			hint="This takes a list of font id's and passes what the user entered into the form to upload the font records after an upload.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="fontIdList" type="string" required="true">
		
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<!--- Remove any duplicates in the list that was send in --->
		<cfset sanitizedFontIdList = listRemoveDuplicates(fontIdList, '_', true)>
			
		<cfif application.Udf.isLoggedIn()>
			
			<!--- Loop through the fontIdList --->
			<cfloop from="1" to="#listLen(sanitizedFontIdList, '_')#" index="i">
				<!--- Get the values of the form --->
				<cfset fontId = listGetAt(sanitizedFontIdList, i, '_')>
				<!--- The font and other fields are coming in as a form like so: font1, 2, 3, etc --->
				<cfset font = evaluate("font#i#")>
				<cfset fileName = evaluate("fileName#i#")>
				<cfset fontWeight = evaluate("fontWeight#i#")>
				<cfset fontType = evaluate("fontType#i#")>
				<!---Note: these checkboxes are not sent along if they were not checked. --->
				<cfif isDefined("italic#i#")>
					<cfset italic = evaluate("italic#i#")>
				<cfelse>
					<cfset italic = false>
				</cfif>
				<cfif isDefined("googleFont#i#")>
					<cfset googleFont = evaluate("googleFont#i#")>
				<cfelse>
					<cfset googleFont = false>
				</cfif>
				
				<!--- Save the font --->
				<!---<cftry>--->
					<cfinvoke component="#application.blog#" method="saveFont" returnvariable="fontId">
						<cfinvokeargument name="fontId" value="#fontId#">
						<!--- Optional args --->
						<cfinvokeargument name="fileName" value="#fileName#">
						<cfinvokeargument name="font" value="#font#">
						<cfinvokeargument name="fontWeight"  value="#fontWeight#">
						<cfinvokeargument name="italic" value="#italic#">
						<cfinvokeargument name="fontType" value="#fontType#">
						<cfinvokeargument name="selfHosted" value="1">
					</cfinvoke>

					<!---<cfcatch type="any">
						<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
					</cfcatch>
				</cftry>--->
		
			</cfloop><!---<cfloop from="1" to="#listLen(sanitizedFontIdList)#" index="i">--->
						
			<cfset response[ "success" ] = "true" />
			
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
				
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>

	</cffunction>
				
	<cffunction name="saveFont" access="remote" output="false" returnformat="json"
			hint="Used to save a font in the database. If the updates were successful, it returns an empty json array.">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="fontId" type="string" required="true">
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
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<cfif application.Udf.isLoggedIn()>
			
			<!--- ************************************ Error checking ************************************ --->

			<!--- Put this in a catch block --->
			<cftry>
				
				<cfinvoke component="#application.blog#" method="saveFont" returnvariable="fontId">
					<cfinvokeargument name="fontId" value="#arguments.fontId#">
					<!--- Optional args --->
					<cfinvokeargument name="fileName" value="#arguments.fileName#">
					<cfinvokeargument name="font" value="#arguments.font#">
					<cfinvokeargument name="fontAlias" value="#arguments.fontAlias#">
					<cfif arguments.fontWeight neq "">
						<cfinvokeargument name="fontWeight"  value="#arguments.fontWeight#">
					</cfif>
					<cfif arguments.italic neq "">
						<cfinvokeargument name="italic" value="#arguments.italic#">
					</cfif>
					<cfif arguments.fontType neq "">
						<cfinvokeargument name="fontType" value="#arguments.fontType#">
					</cfif>
					<cfif arguments.webSafeFont neq "">
						<cfinvokeargument name="webSafeFont" value="#arguments.webSafeFont#">
					</cfif>
					<cfif arguments.googleFont neq "">
						<cfinvokeargument name="googleFont" value="#arguments.googleFont#">
					</cfif>
					<cfif arguments.selfHosted neq "">
						<cfinvokeargument name="selfHosted" value="#arguments.selfHosted#">
					</cfif>
					<cfif arguments.useFont neq "">
						<cfinvokeargument name="useFont" value="#arguments.useFont#">
					</cfif>
				</cfinvoke>
				<!--- Pass back the font id--->
				<cfset response[ "success" ] = true />
				<cfset response[ "fontId" ] = #fontId# />
				
			<cfcatch type="any">
				<!--- Serialize our error list --->
				<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
			</cfcatch>
			</cftry>
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
				
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>

	</cffunction>
						
	<!---******************************************************************************************************
		FavIcon
	*******************************************************************************************************--->
						
	<cffunction name="uploadFavIcon" access="remote" output="false" returnformat="json"
			hint="Very similiar to the uploadImage, uploadFont and uploadVideo functions, but this function uploads FavoriteIcons to the root directory of the blog. If the updates were successful, it returns a 1 indicating success">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditTheme')>
			
		<cfif application.Udf.isLoggedIn()>
		
			<!--- Note: this function follows the best practices given by http://learncfinaweek.com/course/index/section/Security/item/File_Uploads/. ---> 
			
			<!--- ************************************ Error checking ************************************ --->

			<!--- Put this in a catch block --->
			<cftry>
				
				<!--- Upload all of the files to ColdFusion's temporary directory and then check the file(s) before we upload them to our permanent destination. The file field name may vary here, its different for the uppy (ie. files[]) and tinymce (ie file) interfaces, so don't  use it. Note: I am having problems nailing down the font mime type and need to turn off the scrict argument here as the upload fails with the arg set to true. --->
				<cffile 
					action="uploadAll" 
					accept=".png, .webmanifest, .json, .ico"
					strict="false" 
					destination="#getTempDirectory()#" 
					mode = "644"
					nameconflict="overwrite"
					result="UploadObj">
					
				<cfcatch type="any">
					<!--- File is not written to disk if error is thrown  --->
					<!--- Prevent zero length files --->
					<cfif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Zero length file</li>">
					<!--- Prevent invalid file types --->
					<cfelseif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>The MIME type or the Extension of the uploaded file</li>">
					<!--- Prevent empty form field --->
					<cfelseif findNoCase( "did not contain a file.", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Empty form</li>">
					<!--- Catch all other errors --->
					<cfelse>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Unhandled File Upload Error: #cfcatch.message#</li>">
					</cfif>
				</cfcatch>
			</cftry>
							
			<!--- *********** If there were no errors, move the font to the desired destination  ************ --->
			<cfif not error>
					
				<!--- There can be one or more font. Loop through the font array provided by cffile --->
				<cfloop array="#UploadObj#" item="file"> 

					<!--- Set our final destination. --->
					<cfset destination = expandPath("#application.baseUrl#/")>
					
					<!--- Move the file to the final destination. --->
					<cffile 
						action="move"
						source="#file.serverDirectory#/#file.serverFile#"
						destination="#destination#" 
						mode="644">
						
				</cfloop><!---<cfloop array="#UploadObj#" item="video">--->
					
				<!--- Create a new success struct --->
				<!---CF2021 converts this to uppercase.			
				<cfset successStruct = { success="1" }>--->
				<cfset successStruct["success"] = "1">
				
					<!--- Return the structure with the video back to the client --->
				<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
				<cfif application.serverProduct eq 'Lucee'>
					<cfset thisResponse = successStruct />
				<cfelse>
					<cfset thisResponse = serializeJSON( successStruct ) />
				</cfif>

				<cfreturn thisResponse>
					
			<cfelse>
				
				<!--- Serialize our error list --->
				<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
				<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
				<cfif application.serverProduct eq 'Lucee'>
					<cfset thisResponse = response />
				<cfelse>
					<cfset thisResponse = serializeJSON( response ) />
				</cfif>
			
		<cfreturn thisResponse>
			</cfif>
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfset thisResponse = response />
			<cfelse>
				<cfset thisResponse = serializeJSON( response ) />
			</cfif>

			<cfreturn thisResponse>
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->

	</cffunction>
					
	<!---******************************************************************************************************
		JSON Ld 
	*******************************************************************************************************--->
					
	<cffunction name="saveJsonLd" access="remote" output="false" returnformat="json"
			hint="Updates the Post.JsonLd column in the database with a Json Ld string">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="postId" default="" required="true">
		<cfargument name="jsonLd" default="string" required="true" hint="Pass in the Json LD string">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditPost,ReleasePost')>
			
		<cfif application.Udf.isLoggedIn()>
			
			<!--- Update the Json Ld --->
			<cfinvoke component="#application.blog#" method="saveJsonLd" returnvariable="success">
				<cfinvokeargument name="postId" value="#arguments.postId#">
				<cfinvokeargument name="jsonLd" value="#arguments.jsonLd#">
			</cfinvoke>
			
			<cfreturn success>
			
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
				
	</cffunction>
				
	<!---******************************************************************************************************
		Blog Options
	*******************************************************************************************************--->
					
	<cffunction name="saveBlogOptions" access="remote" output="false" returnformat="json"
			hint="Updates the BlogOption table">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="blogOptionId" default="" required="true">
		<!--- The following args are checkboxes --->
		<cfargument name="useSsl" default="" required="false">
		<cfargument name="serverRewriteRuleInPlace" default="" required="false">
		<cfargument name="deferScriptsAndCss" default="" required="false">
		<cfargument name="minimizeCode" default="" required="false">
		<cfargument name="disableCache" default="" required="false">
		<cfargument name="entriesPerBlogPage" default="10" required="false">
		<cfargument name="kendoCommercial" default="" required="false">
		<cfargument name="deferKendoCommercialOnPublicSite" default="" required="false">
		<cfargument name="sendDiagnostics" default="" required="false">
		<cfargument name="enableVisitorLog" default="" required="false">
		<cfargument name="includeDisqus" default="" required="false">
		<cfargument name="includeGsap" default="" required="false">
		<!--- The GreenSock library source radios sit inside this form but save themselves (saveSceneSettings), so this is accepted and not used (2026-10-21). --->
		<cfargument name="gsapLibrarySource" default="" required="false">
		<!--- Dropdowns --->
		<cfargument name="visitorLogMonths" default="" required="false">
		<cfargument name="adminLogMonths" default="" required="false">
		<!--- Text boxes --->
		<cfargument name="jQueryCDNPath" default="" required="false">
		<cfargument name="kendoFolderPath" default="" required="false">
		<cfargument name="googleAnalyticsString" default="" required="false">
		<cfargument name="addThisApiKey" default="" required="false">
		<cfargument name="addThisToolboxString" default="" required="false">
		<cfargument name="bingMapsApiKey" default="" required="false">
		<cfargument name="azureMapsApiKey" default="" required="false">
		<cfargument name="disqusBlogIdentifier" default="" required="false">
		<cfargument name="disqusApiKey" default="" required="false">
		<cfargument name="disqusApiSecret" default="" required="false">
		<cfargument name="disqusAuthTokenKey" default="" required="false">
		<cfargument name="disqusAuthUrl" default="" required="false">
		<cfargument name="disqusAuthTokenUrl" default="" required="false">
		<cfargument name="defaultImageQuality" default="0.8" required="false" hint="Site-wide default for the image-upload compression slider, 0.1-1.0.">
		<cfargument name="videoMaxFileSizeMB" default="100" required="false" hint="Rejects an enclosure video upload over this size (see uploadVideo).">
		<cfargument name="postHeroStyle" default="classic" required="false" hint="5.0: classic, held, band or magazine - how a post's image, gradient or animated hero is shown on its own page.">
		<cfargument name="noImageFallbackMode" default="generic" required="false" hint="What shows in place of noImage.jpg for a post with no enclosure - 'generic', 'generated', 'pool', or 'none'. See Renderer.cfc's getHeroFallbackHtml().">
		<cfargument name="heroCarouselImageCount" default="1" required="false" hint="How many pool images the carousel shows per post when noImageFallbackMode='pool' and heroPoolDisplayMode='carousel'.">
		<cfargument name="heroPoolDisplayMode" default="carousel" required="false" hint="'carousel' or 'single' - see BlogOption.cfc's HeroPoolDisplayMode.">
		<cfargument name="releasedPostEmailMode" default="prompt" required="false" hint="'prompt' or 'auto' - see BlogOption.cfc's ReleasedPostEmailMode (Blog Options, Subscriber Email, 2026-10-12).">
		<!--- Payments (2026-10-14), see Payments.cfc. Only saved when the Payments panel was posted (paymentSettingsPosted). A
		blank secret keeps the saved one. --->
		<cfargument name="paymentSettingsPosted" default="" required="false">
		<cfargument name="paymentCurrency" default="" required="false">
		<cfargument name="paymentTaxMode" default="" required="false">
		<cfargument name="paymentTaxName" default="" required="false">
		<cfargument name="paymentTaxRate" default="" required="false">
		<cfargument name="paymentTestMode" default="" required="false">
		<cfargument name="stripeTestPublishableKey" default="" required="false">
		<cfargument name="stripeTestSecretKey" default="" required="false">
		<cfargument name="stripeTestWebhookSecret" default="" required="false">
		<cfargument name="stripeLivePublishableKey" default="" required="false">
		<cfargument name="stripeLiveSecretKey" default="" required="false">
		<cfargument name="stripeLiveWebhookSecret" default="" required="false">
		<cfargument name="clearTestKeys" default="" required="false">
		<cfargument name="clearLiveKeys" default="" required="false">
		<!--- Member accounts (2026-10-15), see Members.cfc. Only saved when the Member Accounts panel was posted. --->
		<cfargument name="errorEmailMode" default="" required="false" hint="daily or immediate (2026-10-18, ErrorDigest.cfc)">
		<cfargument name="errorDigestHour" default="2" required="false">
		<cfargument name="memberSettingsPosted" default="" required="false">
		<cfargument name="memberAccountsEnabled" default="" required="false">
		<cfargument name="memberRememberDays" default="30" required="false">

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditServerSetting')>
			
		<cfif application.Udf.isLoggedIn()>

			<!--- Payments (2026-10-14): checked first, so a wrong key (eg. pasted into the wrong box) saves nothing at all. --->
			<cfif len(arguments.paymentSettingsPosted)>
				<cfset local.paymentData = {
					currency: arguments.paymentCurrency, taxMode: arguments.paymentTaxMode, taxName: arguments.paymentTaxName, taxRate: arguments.paymentTaxRate,
					testMode: len(arguments.paymentTestMode) gt 0,
					stripeTestPublishableKey: arguments.stripeTestPublishableKey, stripeTestSecretKey: arguments.stripeTestSecretKey, stripeTestWebhookSecret: arguments.stripeTestWebhookSecret,
					stripeLivePublishableKey: arguments.stripeLivePublishableKey, stripeLiveSecretKey: arguments.stripeLiveSecretKey, stripeLiveWebhookSecret: arguments.stripeLiveWebhookSecret,
					clearTestKeys: len(arguments.clearTestKeys) gt 0, clearLiveKeys: len(arguments.clearLiveKeys) gt 0
				}>
				<cfset local.paymentErrors = application.payments.validateSettings(local.paymentData)>
				<cfif arrayLen(local.paymentErrors)>
					<cfreturn { "paymentErrors": local.paymentErrors }>
				</cfif>
			</cfif>
			
			<!--- Member accounts (2026-10-15): checked first too. --->
			<cfif len(arguments.memberSettingsPosted) and (not isNumeric(arguments.memberRememberDays) or int(arguments.memberRememberDays) lt 1 or int(arguments.memberRememberDays) gt 365)>
				<cfreturn { "paymentErrors": [ "Keep members signed in for 1 to 365 days." ] }>
			</cfif>

			<!--- Set the value of the checkboxes --->
			<cfif len(arguments.useSsl)>
				<cfset useSsl = true>
			<cfelse>
				<cfset useSsl = false>
			</cfif>
				
			<cfif len(arguments.serverRewriteRuleInPlace)>
				<cfset serverRewriteRuleInPlace = true>
			<cfelse>
				<cfset serverRewriteRuleInPlace = false>
			</cfif>
				
			<cfif len(arguments.deferScriptsAndCss)>
				<cfset deferScriptsAndCss = true>
			<cfelse>
				<cfset deferScriptsAndCss = false>
			</cfif>
				
			<cfif len(arguments.minimizeCode)>
				<cfset minimizeCode = true>
			<cfelse>
				<cfset minimizeCode = false>
			</cfif>
				
			<cfif len(arguments.disableCache)>
				<cfset disableCache = true>
			<cfelse>
				<cfset disableCache = false>
			</cfif>
				
			<cfif len(arguments.kendoCommercial)>
				<cfset kendoCommercial = true>
			<cfelse>
				<cfset kendoCommercial = false>
			</cfif>

			<cfif len(arguments.deferKendoCommercialOnPublicSite)>
				<cfset deferKendoCommercialOnPublicSite = true>
			<cfelse>
				<cfset deferKendoCommercialOnPublicSite = false>
			</cfif>

			<cfif len(arguments.sendDiagnostics)>
				<cfset sendDiagnostics = true>
			<cfelse>
				<cfset sendDiagnostics = false>
			</cfif>
				
			<cfif len(arguments.enableVisitorLog)>
				<cfset enableVisitorLog = true>
			<cfelse>
				<cfset enableVisitorLog = false>
			</cfif>
				
			<cfif len(arguments.includeDisqus)>
				<cfset includeDisqus = true>
			<cfelse>
				<cfset includeDisqus = false>
			</cfif>
				
			<cfif len(arguments.includeGsap)>
				<cfset includeGsap = true>
			<cfelse>
				<cfset includeGsap = false>
			</cfif>
				
			<cftransaction>
			
				<!--- Update the options --->
				<cfset OptionDbObj = EntityLoadByPk("BlogOption", arguments.blogOptionId)>
				<!--- Set the checkbox values. --->
				<cfset OptionDbObj.setUseSsl(useSsl)>
				<cfset OptionDbObj.setServerRewriteRuleInPlace(serverRewriteRuleInPlace)>
				<cfset OptionDbObj.setDeferScriptsAndCss(deferScriptsAndCss)>
				<cfset OptionDbObj.setMinimizeCode(minimizeCode)>
				<cfset OptionDbObj.setDisableCache(disableCache)>
				<cfset OptionDbObj.setEntriesPerBlogPage(arguments.entriesPerBlogPage)>	
				<cfset OptionDbObj.setKendoCommercial(kendoCommercial)>
				<cfset OptionDbObj.setDeferKendoCommercialOnPublicSite(deferKendoCommercialOnPublicSite)>
				<cfset OptionDbObj.setSendDiagnostics(sendDiagnostics)>
				<cfset OptionDbObj.setLogVisitors(enableVisitorLog)>
				<cfset OptionDbObj.setIncludeDisqus(includeDisqus)>
				<cfset OptionDbObj.setIncludeGsap(includeGsap)>
				<cfset OptionDbObj.setUseSsl(useSsl)>
				<!--- These are strings coming from textboxes. --->
				<cfset OptionDbObj.setJQueryCDNPath(arguments.jQueryCDNPath)>
				<cfset OptionDbObj.setKendoFolderPath(arguments.kendoFolderPath)>
				<cfset OptionDbObj.setMonthsToRetainVisitorLog(arguments.visitorLogMonths)>
				<cfset OptionDbObj.setMonthsToRetainAdminLog(arguments.adminLogMonths)>
				<cfset OptionDbObj.setGoogleAnalyticsString(arguments.googleAnalyticsString)>
				<cfset OptionDbObj.setAddThisApiKey(arguments.addThisApiKey)>
				<cfset OptionDbObj.setAddThisToolboxString(arguments.addThisToolboxString)>
				<cfset OptionDbObj.setAddThisApiKey(arguments.addThisApiKey)>
				<cfset OptionDbObj.setAzureMapsApiKey(arguments.azureMapsApiKey)>
				<cfset OptionDbObj.setBingMapsApiKey(arguments.bingMapsApiKey)>
				<cfset OptionDbObj.setDisqusBlogIdentifier(arguments.disqusBlogIdentifier)>
				<cfset OptionDbObj.setDisqusApiKey(arguments.disqusApiKey)>
				<cfset OptionDbObj.setDisqusApiSecret(arguments.disqusApiSecret)>
				<cfset OptionDbObj.setDisqusAuthTokenKey(arguments.disqusAuthTokenKey)>
				<cfset OptionDbObj.setDisqusAuthUrl(arguments.disqusAuthUrl)>
				<cfset OptionDbObj.setDisqusAuthTokenUrl(arguments.disqusAuthTokenUrl)>
				<cfset OptionDbObj.setDefaultImageQuality(val(arguments.defaultImageQuality))>
				<cfset OptionDbObj.setVideoMaxFileSizeMB(val(arguments.videoMaxFileSizeMB))>
				<cfset OptionDbObj.setNoImageFallbackMode(arguments.noImageFallbackMode)>
				<!--- 5.0: how post heroes are shown (Renderer.cfc getPostHeroStyle). The post pages are cleared below. --->
				<cfset OptionDbObj.setPostHeroStyle(listFind("classic,held,band,magazine", arguments.postHeroStyle) ? arguments.postHeroStyle : "classic")>
				<cfset OptionDbObj.setHeroCarouselImageCount(val(arguments.heroCarouselImageCount))>
				<cfset OptionDbObj.setHeroPoolDisplayMode(arguments.heroPoolDisplayMode)>
				<cfset OptionDbObj.setReleasedPostEmailMode(arguments.releasedPostEmailMode eq "auto" ? "auto" : "prompt")>
				<cfset OptionDbObj.setDate(application.blog.blogNow())>
				<!--- Save it --->
				<cfset EntitySave(OptionDbObj)>

			</cftransaction>
			<!--- The running site's copies (2026-10-20): GreenSock decides whether scenes move, and the Azure Maps key whether the map windows
			open, without waiting for the blog to restart. --->
			<cfset application.includeGsap = includeGsap>
			<cfset application.azureMapsApiKey = arguments.azureMapsApiKey>

			<!--- 2026-09-26: same class of bug as saveBlogSettings() (see its own comment on this exact fix) - this
			function loads and saves its own separate BlogOption entity instance (OptionDbObj, local-scoped),
			distinct from application.BlogOptionDbObj, the app-scoped singleton nearly every other part of the app
			actually reads from (eg. getDefaultImageQuality(), getVideoMaxFileSizeMB() - both used directly by
			uploadImage()/uploadVideo()). Without this, saving Blog Options here would write correctly to the
			database but leave every one of these ~30 settings looking unchanged anywhere else in the app until
			something unrelated happened to reload the cache. Re-point the cached singleton at a fresh copy
			immediately after a successful save, same as saveBlogSettings() now does. --->
			<cfset application.BlogOptionDbObj = EntityLoadByPk("BlogOption", arguments.blogOptionId)>

			<!--- Clear the header files as the parent site name may have been updated --->
			<cfset thisDirectory = application.baseUrl & '/cache/header'>
			<!--- This filter will match all posts that use the postId --->
			<cfset thisFileNameOrFilter = 'topMenu'>
			<!--- Delete the files --->
			<cfset application.blog.flushGalaxieCacheFiles(thisDirectory,thisFileNameOrFilter)>

			<!--- Flush every card-level cache (curatedBlogPosts, popularPosts) and every individual post page -
			this form saves ~30 unrelated settings at once (including NoImageFallbackMode/HeroCarouselImageCount/
			HeroImagePoolCarouselRef), and switching, say, 'pool' to 'generated' left every previously-cached page
			still showing the old carousel until its own 24-hour timeout, since nothing here invalidated them. A
			broad flush of both folders is simpler and safer than detecting exactly which setting changed, and
			cheap in practice since Blog Options is saved rarely. --->
			<cfset thisDirectory = application.baseUrl & '/cache/cards'>
			<cfset application.blog.flushGalaxieCacheFiles(thisDirectory,'')>
			<cfset thisDirectory = application.baseUrl & '/cache/posts'>
			<cfset application.blog.flushGalaxieCacheFiles(thisDirectory,'')>

			<!--- Payments (2026-10-14): validated above. --->
			<cfif len(arguments.paymentSettingsPosted)>
				<cfset application.payments.saveSettings(local.paymentData)>
			</cfif>
			<!--- Member accounts (2026-10-15): validated above. --->
			<cfif len(arguments.memberSettingsPosted)>
				<cfset application.members.saveSettings(len(arguments.memberAccountsEnabled) gt 0, int(arguments.memberRememberDays))>
			</cfif>
			<!--- Error emails (2026-10-18): a nightly summary or an email for each new error. --->
			<cfif len(arguments.errorEmailMode)>
				<cfset application.blog.getErrorDigest().saveSettings(arguments.errorEmailMode, isNumeric(arguments.errorDigestHour) ? arguments.errorDigestHour : 2)>
			</cfif>

			<!--- Return the Id --->
			<cfreturn OptionDbObj.getBlogOptionId()>
			
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
				
	</cffunction>
					
	<!---******************************************************************************************************
		Blog Settings
	*******************************************************************************************************--->
					
	<cffunction name="saveBlogSettings" access="remote" output="false" returnformat="json"
			hint="Updates the BlogSetting table">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="blogId" default="1" required="false">
		<!--- Blog meta data --->
		<cfargument name="blogName" default="" required="true">
		<cfargument name="blogTitle" default="" required="true">
		<cfargument name="blogDescription" default="" required="true">
		<cfargument name="blogUrl" default="" required="true">
		<cfargument name="isProd" default="" required="false">
		<cfargument name="blogMetaKeywords" default="" required="false">
		<!--- Parent site --->
		<cfargument name="parentSiteName" default="" required="false">
		<cfargument name="parentSiteLink" default="" required="false">
		<!--- Time zone --->
		<cfargument name="blogTimeZone" default="" required="true">
		<cfargument name="serverTimeZone" default="" required="true">
		<cfargument name="serverTimeZoneOffset" default="" required="true">
		<!--- Database --->
		<cfargument name="dsn" default="" required="true">
		<cfargument name="dsnUserName" default="" required="true">
		<cfargument name="dsnPassword" default="" required="true">
		<!--- Mail server --->
		<cfargument name="mailServer" default="" required="true">
		<cfargument name="mailusername" default="" required="true">
		<cfargument name="mailpassword" default="" required="true">
		<cfargument name="failTo" default="" required="true">
		<cfargument name="blogEmail" default="" required="true">
		<cfargument name="ccEmailAddress" default="" required="false">
		<!--- Unused arguments needed to prevent a new CF related bug introduced with CF2023 update 14. --->
		<cfargument name="blogTimeZoneValue" default="" required="false">
		<cfargument name="serverTimeZoneValue" default="" required="false">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditServerSetting')>
			
		<cfif application.Udf.isLoggedIn()>
			
			<!--- The password fields in Blog Settings start empty (2026-10-14): a blank field keeps the saved password. --->
			<cfset local.keepIniDsnPassword = not len(arguments.dsnPassword)>
			<cfif not len(arguments.dsnPassword)>
				<cfset arguments.dsnPassword = isNull(application.BlogDbObj.getBlogDsnPassword()) ? "" : application.BlogDbObj.getBlogDsnPassword()>
			</cfif>
			<cfif not len(arguments.mailPassword)>
				<cfset arguments.mailPassword = isNull(application.BlogDbObj.getBlogMailServerPassword()) ? "" : application.BlogDbObj.getBlogMailServerPassword()>
			</cfif>

			<!--- Note: we need to store the database connection credentials in the blog.ini file as well. This is needed as the database will not immediately be up and running when the blog is installed and we are using the ini file to store the credentials when we can't get them from the database --->
			<cfset setProfileString(application.iniFile, "default", "dsn", arguments.dsn)>
			<cfset setProfileString(application.iniFile, "default", "username", arguments.dsnUserName)>
			<cfif not local.keepIniDsnPassword>
				<cfset setProfileString(application.iniFile, "default", "password", arguments.dsnPassword)>
			</cfif>
			<!--- Allow users to change the URL in the ini file as well --->
			<cfset setProfileString(application.iniFile, "default", "blogUrl", arguments.blogUrl)>
				
			<!--- Handle checkboxes --->
			<cfif len(arguments.isProd)>
				<cfset isProd = true>
			<cfelse>
				<cfset isProd = false>
			</cfif>
				
			<cftransaction>
			
				<!--- Update the options --->
				<cfset BlogDbObj = EntityLoadByPk("Blog", arguments.blogId)>
				<!--- Set blog meta data --->
				<!--- For now, the blog name is an alias. It is not used yet. Eventually we will allow multiple blogs. --->
				<cfset BlogDbObj.setBlogName(application.blog.makeAlias(arguments.blogName))>
				<cfset BlogDbObj.setBlogTitle(arguments.blogTitle)>
				<cfset BlogDbObj.setBlogDescription(arguments.blogDescription)>
				<cfset BlogDbObj.setBlogUrl(arguments.blogUrl)>
				<cfset BlogDbObj.setIsProd(isProd)>
				<!--- This is an optional field. --->
				<cfset BlogDbObj.setBlogMetaKeywords(arguments.blogMetaKeywords)>
				<!--- Parent site (optional) --->
				<cfset BlogDbObj.setBlogParentSiteName(arguments.parentSiteName)>
				<cfset BlogDbObj.setBlogParentSiteUrl(arguments.parentSiteLink)>
				<!--- Time zone --->
				<cfset BlogDbObj.setBlogTimeZone(arguments.blogTimeZone)>
				<cfset BlogDbObj.setBlogServerTimeZone(arguments.serverTimeZone)>
				<cfset BlogDbObj.setBlogServerTimeZoneOffset(arguments.serverTimeZoneOffset)>
				<!--- DSN (this is also saved in the ini file. See logic above) --->
				<cfset BlogDbObj.setBlogDsn(arguments.dsn)>
				<cfset BlogDbObj.setBlogDsnUserName(arguments.dsnUserName)>
				<cfset BlogDbObj.setBlogDsnPassword(arguments.dsnPassword)>
				<!--- Mail server settings --->
				<cfset BlogDbObj.setBlogMailServer(arguments.mailServer)>
				<cfset BlogDbObj.setBlogMailServerUserName(arguments.mailUserName)>
				<cfset BlogDbObj.setBlogMailServerPassword(arguments.mailPassword)>
				<cfset BlogDbObj.setBlogEmailFailToAddress(arguments.failTo)>	
				<cfset BlogDbObj.setBlogEmail(arguments.blogEmail)>
				<cfset BlogDbObj.setCCEmailAddress(arguments.ccEmailAddress)>
				<!--- Date --->
				<cfset BlogDbObj.setDate(application.blog.blogNow())>
				<!--- Save it --->
				<cfset EntitySave(BlogDbObj)>

			</cftransaction>

			<!--- 2026-09-26: this function loads and saves its own separate Blog entity instance (BlogDbObj,
			local-scoped) - completely distinct from application.BlogDbObj, the app-scoped singleton created once
			at startup (Application.cfc) that every other check in the app actually reads from (eg.
			utils.cfc's "is the blog email set up" guard before sending mail). Without this, a fresh install's
			first save here would correctly write the new email/mail server settings to the database, but
			application.BlogDbObj would keep returning blank/stale values for them - as if the save had silently
			failed - until something else happened to reload it (an ordinary page load appeared to, in testing,
			but that's incidental ORM behavior, not something this function should rely on). Re-point the cached
			singleton at a fresh copy immediately after a successful save so it's never stale for any other
			request. --->
			<cfset application.BlogDbObj = entityLoadByPK("Blog", arguments.blogId)>

			<cfreturn BlogDbObj.getBlogId()>

		</cfif><!---<cfif application.Udf.isLoggedIn()>--->

	</cffunction>

	<!---******************************************************************************************************
		File functions
	*******************************************************************************************************--->
				
	<cffunction name="uploadFile" access="remote" output="false" returnformat="json"
			hint="This function uploads and processes files. At the moment, it is only used for webVtt files"><!---returnformat="json" --->
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="fileType" type="string" default="" required="false" hint="What files are we processing? This string determines how to process the file.">
		<cfargument name="mediaId" default="" required="false">
		<cfargument name="postId" default="" required="false">
		<!--- Some images may not have a comment (ie a post) --->
		<cfargument name="commentId" default="" required="false">
		
		<cfset debug = false>
		<!--- Save a list of actions taken --->
		<cfparam name="fileActions" default="">
		
		<!--- Error params --->
		<cfparam name="error" default="false" type="boolean">
		<cfparam name="errorMessage" default="" type="string">
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<cfif application.Udf.isLoggedIn()>
		
			<!--- Note: this function follows the best practices given by http://learncfinaweek.com/course/index/section/Security/item/File_Uploads/. ---> 
			
			<!--- ************************************ Error checking ************************************ --->
			<cfif arguments.fileType eq 'webVttFile'>
				<!--- Allowed mime types. --->
				<cfset acceptedMimeTypes = {
				'text/vtt': {extension: 'vtt'}
				}>
			</cfif>

			<!--- Put this in a catch block --->
			<cftry>
				
				<!--- Upload all of the files to ColdFusion's temporary directory and then check the file(s) before we upload them to our permanent destination. The file field name may vary here, its different for the uppy (ie. files[]) and tinymce (ie file) interfaces, so don't use it. --->
				<cffile 
					action="uploadAll" 
					accept="#structKeyList(acceptedMimeTypes)#"
					strict="true" 
					destination="#getTempDirectory()#" 
					nameconflict="overwrite"
					mode = "644"
					result="UploadObj">
					
				<cfcatch type="any">
					<!--- File is not written to disk if error is thrown  --->
					<!--- Prevent zero length files --->
					<cfif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Zero length file</li>">
					<!--- Prevent invalid file types --->
					<cfelseif findNoCase( "No data was received in the uploaded", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>The MIME type or the Extension of the uploaded file</li>">
					<!--- Prevent empty form field --->
					<cfelseif findNoCase( "did not contain a file.", cfcatch.message )>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Empty form</li>">
					<!--- Catch all other errors --->
					<cfelse>
						<cfset error = true>
						<cfset errorMessage = errorMessage & "<li>Unhandled File Upload Error: #cfcatch.message#</li>">
					</cfif>
				</cfcatch>
			</cftry>
							
			<!--- *********** If there were no errors, move the image to the desired destination  ************ --->
			<cfif not error>
					
				<!--- There can be one or more files. Loop through the image array provided by cffile --->
				<cfloop array="#UploadObj#" item="file">
					
					<!--- Determine the mime type --->
					<cfset mimeType = fileGetMimeType( file.ServerDirectory & '/' & file.ServerFile, true )>

					<!--- Set our final destination. --->
					<cfif arguments.fileType eq 'webVttFile'>
						<cfset destination = expandPath("#application.baseUrl#/enclosures/videos/")>
					</cfif>
					
					<!--- Move the file to the final destination. --->
					<cffile 
						action="move"
						source="#file.serverDirectory#/#file.serverFile#"
						destination="#destination#" 
						mode="644">
						
					<!--- Get the full path and the name of the file --->
					<cfset fileUrl = application.baseUrl & "/enclosures/videos/" & file.serverFile>
					<!--- Get the mediaId for this enclosure. --->
					<cfset mediaId = application.blog.getEnclosureMediaIdByPostId(arguments.postId)>
					<!--- Read the file. We will pass back the WebVtt file contents back to the editor --->
					<cffile action="read" file="#expandPath(fileUrl)#" variable="fileContent">
						
					<!--- Update the MediaVideoVttFileUrl column in the media table with the location --->
					<cfinvoke component="#application.blog#" method="updateMediaRecord" returnvariable="updateMedia">
						<cfinvokeargument name="mediaId" value="#mediaId#">
						<cfinvokeargument name="mediaVideoVttFileUrl" value="#fileUrl#">
					</cfinvoke>

				</cfloop><!---<cfloop array="#UploadObj#" item="image">--->
					
				<!--- Create a new location struct with the new image URL, the new mediaId, and all of the actions that were taken. This is needed as we have not yet saved the comment when the image is uploaded, and we want to diaply our actions to the user on success. --->
				<cfset fileUrlString = { location="#fileUrl#", mediaId="#mediaId#", fileContent="#fileContent#" }>
				
				<!--- Return the structure with the image back to the client --->
				<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
				<cfif application.serverProduct eq 'Lucee'>
					<cfset thisResponse = fileUrlString />
				<cfelse>
					<cfset thisResponse = serializeJSON( fileUrlString ) />
				</cfif>

				<cfreturn thisResponse>
			<cfelse>
				<!--- Serialize our error list --->
				<cfset response[ "errorMessage" ] = "<ul>" & errorMessage & "</ul>" />
				<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
				<cfif application.serverProduct eq 'Lucee'>
					<cfset thisResponse = response />
				<cfelse>
					<cfset thisResponse = serializeJSON( response ) />
				</cfif>

				<cfreturn thisResponse>
			</cfif>
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
			<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
			<cfif application.serverProduct eq 'Lucee'>
				<cfset thisResponse = response />
			<cfelse>
				<cfset thisResponse = serializeJSON( response ) />
			</cfif>
			
			<cfreturn thisResponse>
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->

	</cffunction>
				
	<cffunction name="saveFile" access="remote" output="false" returnformat="json"
			hint="Saves a file on the server from the contents of a tinymce editor">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="file" type="string" default="" required="true" hint="Pass in the path to the file location">
		<cfargument name="fileContent" default="" required="true" hint="Pass in the content that will be used to generate the file">
		<cfargument name="fileType" type="string" default="" required="true" hint="What is the file type?">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
				
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<cfif application.Udf.isLoggedIn()>
		
			<!--- Only caption files (.vtt) inside this blog's folder (2026-10-14). --->
			<cfif arguments.fileType eq 'webVtt' and lCase(listLast(arguments.file, ".")) eq "vtt" and not find("..", arguments.file)
				and left(arguments.file, len(application.baseUrl) + 1) eq application.baseUrl & "/">
				<!--- Load JSoup to convert the html to text --->
				<cfinvoke component="#application.jsoupComponentPath#" method="jsoupConvertHtmlToText2" returnvariable="jsoupWholeText">
					<cfinvokeargument name="html" value="#arguments.fileContent#">
				</cfinvoke>

				<!--- Write the file with the new text. The new lines should be preserved --->
				<cffile action="write" file="#expandPath(arguments.file)#" output="#jsoupWholeText#" mode="777"  attributes="normal">
			</cfif>

			<cfreturn true>
				
		</cfif>

	</cffunction>
				
	<!---******************************************************************************************************
		Map functions
	*******************************************************************************************************---> ''
				
	<cffunction name="saveMap" access="remote" output="false" returnformat="json"
			hint="This function saves the address and waypoints when creating a map route"><!---returnformat="json" --->
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="isEnclosure" default="true" required="true">
		<cfargument name="postId" default="" required="false" hint="Mutually exclusive with pageCollectionId">
		<cfargument name="pageCollectionId" default="" required="false" hint="Pass in when this map is a Page Collection's hero enclosure instead of a Post's">
		<cfargument name="mapId" default="" required="false">
		<cfargument name="mapType" default="" required="true" hint="This is also known as the Map Style when using Azure Maps">
		<cfargument name="mapZoom" default="" required="true">
		<cfargument name="mapAddress" required="true" default="">
		<cfargument name="mapCoordinates" required="true" default="">
		<!--- Optional args --->
		<cfargument name="latitude" required="false" default="">
		<cfargument name="longitude" required="false" default="">
		<cfargument name="provider" default="Azure Maps" required="false">
		<cfargument name="customMarker" required="false" default="">
		<cfargument name="outlineMap" required="false" default="false">
			
		<!--- Set the default response object.--->
		<cfset response = {} />
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<cfif application.Udf.isLoggedIn()>
			
			<cftry>
			
				<cfinvoke component="#application.blog#" method="saveMap" returnvariable="mapId">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#">
					<cfinvokeargument name="mapId" value="#arguments.mapId#">
					<cfinvokeargument name="mapType" value="#arguments.mapType#">
					<cfinvokeargument name="mapZoom" value="#arguments.mapZoom#">
					<cfinvokeargument name="mapAddress" value="#arguments.mapAddress#">
					<cfinvokeargument name="mapCoordinates" value="#arguments.mapCoordinates#">
					<cfinvokeargument name="latitude" value="#arguments.latitude#">
					<cfinvokeargument name="longitude" value="#arguments.longitude#">
					<cfinvokeargument name="isEnclosure" value="#arguments.isEnclosure#">
					<cfinvokeargument name="provider" value="#arguments.provider#">
					<cfinvokeargument name="customMarker" value="#arguments.customMarker#">
					<cfinvokeargument name="outlineMap" value="#arguments.outlineMap#">
				</cfinvoke>
				<!--- The public collection pages are cached - clear them so the new map shows. --->
				<cfif len(arguments.pageCollectionId)>
					<cfset application.blog.flushGalaxieCache('pageCollection')>
				</cfif>

				<!--- Pass back the map and post id (or page collection id)--->
				<cfset response[ "postId" ] = #arguments.postId# />
				<cfset response[ "pageCollectionId" ] = #arguments.pageCollectionId# />
				<cfset response[ "mapId" ] = #arguments.mapId# />
				<cfset response[ "success" ] = true />

				<cfcatch type="any">
					<!--- Serialize our error. saveMap never sets errorMessage, so report the caught message instead of reading an undefined variable. --->
					<!--- Include where the error was raised (the innermost frame) so the popup shows the exact line. --->
					<!--- Some errors arrive with an empty message and no frames, so also report the type and detail, and the first few frames when there are any. --->
					<cfset errorLocation = "">
					<cfloop from="1" to="#min(3, arrayLen(cfcatch.tagContext))#" index="frameIndex">
						<cfset errorLocation = errorLocation & "<li>" & cfcatch.tagContext[frameIndex].template & " line " & cfcatch.tagContext[frameIndex].line & "</li>">
					</cfloop>
					<cfset response[ "errorMessage" ] = "<ul><li>Type: " & cfcatch.type & "</li><li>Message: " & cfcatch.message & "</li><li>Detail: " & cfcatch.detail & "</li>" & errorLocation & "</ul>" />
					<!--- Also write the details to the Galaxie error log so they can be read from the server, not only from the popup. --->
					<cflog file="galaxieBlogErrors" type="error" text="saveMap failed: #cfcatch.type# | #cfcatch.message# | #cfcatch.detail# | #errorLocation#">
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->

		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>

		<cfreturn thisResponse>

	</cffunction>

	<cffunction name="saveMapRoute" access="remote" output="false" returnformat="json"
			hint="This function saves the address and waypoints when creating a map route"><!---returnformat="json" --->
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="postId" default="" required="false" hint="Mutually exclusive with pageCollectionId">
		<cfargument name="pageCollectionId" default="" required="false" hint="Pass in when this map route is a Page Collection's hero enclosure instead of a Post's">
		<cfargument name="mapId" default="" required="false">
		<cfargument name="mapRouteId" default="" required="false">
		<cfargument name="isEnclosure" default="true" required="false">
		<cfargument name="provider" default="Azure Maps" required="false">
		<cfargument name="locationGeoCoordinates" default="" required="true" hint="This is a sting that has the location, latitude and longitude separated by underscores and the rows are separated using a colon (ie Seattle_xxx_xxx:Bellevue_xxx_xxx:Denver_xxx_xxx)">
		<cfargument name="mapZoom" default="" required="false">
		<cfargument name="mapType" default="" required="false" hint="This is also known as the Map Style when using Azure Maps">
			
		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>	
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('AssetEditor,EditComment,EditPost,ReleasePost')>
			
		<cfif application.Udf.isLoggedIn()>
				
			<!--- There is only one provider as of June 2025. Bing Maps retired... --->
			<cfif arguments.provider eq 'Azure Maps'> 

				<cfinvoke component="#application.blog#" method="saveMapRoute" returnvariable="mapId">
					<cfinvokeargument name="mapId" value="#arguments.mapId#">
					<cfinvokeargument name="mapRouteId" value="#arguments.mapRouteId#">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="pageCollectionId" value="#arguments.pageCollectionId#">
					<cfinvokeargument name="locationGeoCoordinates" value="#arguments.locationGeoCoordinates#">
					<cfinvokeargument name="isEnclosure" value="#arguments.isEnclosure#">
					<cfinvokeargument name="provider" value="Azure Maps">
					<!--- The map type for map routes is 'road_shaded_relief' --->
					<cfinvokeargument name="mapType" value="#arguments.mapType#">
					<cfinvokeargument name="mapZoom" value="#arguments.mapZoom#">
				</cfinvoke>
				<!--- The public collection pages are cached - clear them so the new route shows. --->
				<cfif len(arguments.pageCollectionId)>
					<cfset application.blog.flushGalaxieCache('pageCollection')>
				</cfif>

			</cfif><!---<cfif mapProvider eq 'Azure Maps'>--->

			<!--- Pass back the map and post id (or page collection id)--->
			<cfset response[ "postId" ] = #arguments.postId# />
			<cfset response[ "pageCollectionId" ] = #arguments.pageCollectionId# />
			<cfset response[ "mapId" ] = #arguments.mapId# />
			<cfset response[ "success" ] = true />
			
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul>Not logged in</ul>" />
		</cfif><!---<cfif application.Udf.isLoggedIn()>--->
			
		<!--- Lucee serializes JSON twice when using it with AJAX. To prevent this, we need to send a serializeData false argument. Only use this when using AJAX with Lucee. --->
		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
			
		<cfreturn thisResponse>
			
	</cffunction>
						
	<!---******************************************************************************************************
		Update DB
	*******************************************************************************************************--->
				
	<cffunction name="getDatabaseUpdater" access="private" returnType="any" output="false"
			hint="Returns the DatabaseUpdater. Application.cfc creates it when the application starts, but the application may have been running when new files were uploaded, so create it here if it is not there yet.">

		<cfset var updaterComponentPath = "">

		<cfif not isDefined("application.databaseUpdater")>
			<cfif len(application.baseProxyUrl) gt 0>
				<cfset updaterComponentPath = application.baseComponentPath & ".common.cfc.DatabaseUpdater">
			<cfelse>
				<cfset updaterComponentPath = "common.cfc.DatabaseUpdater">
			</cfif>
			<cfset application.databaseUpdater = createObject("component", updaterComponentPath).init(application.rootDirectoryPath, application.blogIniPath)>
		</cfif>

		<cfreturn application.databaseUpdater>

	</cffunction>

	<cffunction name="runDatabaseUpdate" access="remote" output="false" returnFormat="json"
			hint="Brings the database up to the version of the code that was uploaded. See DatabaseUpdater.cfc and the scripts in /installer/updates/. This is run from the Blog Updates window on the administrative site.">
		<cfargument name="csrfToken" required="true">

		<!--- Set the default response object.--->
		<cfset response = {} />

		<!--- Verify the token --->
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<!--- Set the response --->
			<cfset response = "Invalid token">
			<!--- Return it --->
			<cfif application.serverProduct eq 'Lucee'>
				<!--- Do not serialize the response --->
				<cfreturn response>
			<cfelse>
				<!--- Serialize the response --->
				<cfset serializedResponse = serializeJSON( response ) />
				<!--- Send the response back to the client. --->
				<cfreturn serializedResponse>
			</cfif>
			<!--- Abort the process if the token is not validated. --->
			<cfabort>
		</cfif>

		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in --->
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn()>
			<cfset response = getDatabaseUpdater().run()>
			<!--- The cached html was made by the old files and data, so clear it after a successful update (the same as the Refresh Site button). --->
			<cfif response.success>
				<cftry>
					<cfset application.blog.flushGalaxieCache(type='all')>
					<cfcatch type="any"></cfcatch>
				</cftry>
			</cfif>
		<cfelse>
			<cfset response = { "success": false, "message": "You must be logged in to update the database.", "log": [] }>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<!--- Do not serialize the response --->
			<cfreturn response>
		<cfelse>
			<!--- Serialize the response --->
			<cfset serializedResponse = serializeJSON( response ) />
			<!--- Send the response back to the client. --->
			<cfreturn serializedResponse>
		</cfif>

	</cffunction>

	<cffunction name="savePageCollection" access="remote" returnformat="json" output="false"
			hint="Creates a new Page Collection (pageCollectionId=0, from the New chooser) or updates an existing one's basic fields (from Configure Page Collections).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="pageCollectionId" type="string" default="0" required="false">
		<cfargument name="title" type="string" required="true">
		<cfargument name="description" type="string" default="" required="false">
		<cfargument name="heroImageUrl" type="string" required="false" hint="Omit to keep the current hero image (the Page Collection Detail window's Save Collection omits it - see blog.cfc savePageCollection).">
		<cfargument name="externalUrl" type="string" default="" required="false" hint="When set, this Collection is a pure cross-link - see PageCollection.cfc's own comment on ExternalUrl.">
		<cfargument name="menuOrder" type="string" default="" required="false">
		<cfargument name="showInMenu" type="string" default="" required="false" hint="2026-10-10: true/false - list this collection in the top menu. Blank keeps the current value.">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost')>

		<cfif application.Udf.isLoggedIn()>
			<cfif not len(trim(arguments.title))>
				<cfset response[ "errorMessage" ] = "The title is required.">
			<cfelse>
				<cftry>
					<cfset saveArgs = { menuOrder=arguments.menuOrder, showInMenu=arguments.showInMenu, pageCollectionId=val(arguments.pageCollectionId), title=arguments.title, description=arguments.description, externalUrl=arguments.externalUrl }>
					<cfif isDefined("arguments.heroImageUrl")>
						<cfset saveArgs.heroImageUrl = arguments.heroImageUrl>
					</cfif>
					<cfset newId = application.blog.savePageCollection(argumentCollection=saveArgs)>
					<cfset response[ "success" ] = true />
					<cfset response[ "pageCollectionId" ] = newId />
					<cfcatch type="any">
						<cfset response[ "errorMessage" ] = cfcatch.message>
					</cfcatch>
				</cftry>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="savePageCollectionHeroGradient" access="remote" returnformat="json" output="false"
			hint="Saves the Hero Gradient (+ optional overlay text/color) picked in gradientEditor.cfm's Insert/Edit Gradient popup, for a Page Collection's hero.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="pageCollectionId" type="string" default="0" required="true">
		<cfargument name="heroGradient" type="string" required="true">
		<cfargument name="heroOverlayText" type="string" default="" required="false">
		<cfargument name="heroOverlayTextColor" type="string" default="" required="false">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset application.blog.savePageCollectionHeroGradient(pageCollectionId=val(arguments.pageCollectionId), heroGradient=arguments.heroGradient, heroOverlayText=arguments.heroOverlayText, heroOverlayTextColor=arguments.heroOverlayTextColor)>
				<cfset response[ "success" ] = true />
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="savePostHeroGradient" access="remote" returnformat="json" output="false"
			hint="Saves the Hero Gradient (+ optional overlay text/color/font) picked in gradientEditor.cfm's Insert/Edit Gradient popup, for a Post/Page's enclosure editor.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" type="string" default="0" required="true">
		<cfargument name="heroGradient" type="string" required="true">
		<cfargument name="heroOverlayText" type="string" default="" required="false">
		<cfargument name="heroOverlayTextColor" type="string" default="" required="false">
		<cfargument name="heroOverlayFont" type="string" default="" required="false">
		<cfargument name="heroOverlayFontSize" type="string" default="" required="false">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset application.blog.savePostHeroGradient(postId=val(arguments.postId), heroGradient=arguments.heroGradient, heroOverlayText=arguments.heroOverlayText, heroOverlayTextColor=arguments.heroOverlayTextColor, heroOverlayFont=arguments.heroOverlayFont, heroOverlayFontSize=arguments.heroOverlayFontSize)>
				<cfset response[ "success" ] = true />
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="savePostHeroAnimation" access="remote" returnformat="json" output="false"
			hint="Saves the animation effect (+ its JSON options, + optional overlay text/color/font) picked in heroAnimationEditor.cfm's Choose Animation popup, for a Post's own per-post hero override. 2026-10-03: renamed from savePostHeroVanta/vantaEffect/vantaOptions while still dev-only/unmigrated.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" type="string" default="0" required="true">
		<cfargument name="animationEffect" type="string" required="true">
		<cfargument name="animationOptions" type="string" default="" required="false">
		<cfargument name="heroOverlayText" type="string" default="" required="false">
		<cfargument name="heroOverlayTextColor" type="string" default="" required="false">
		<cfargument name="heroOverlayFont" type="string" default="" required="false">
		<cfargument name="heroOverlayFontSize" type="string" default="" required="false">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset application.blog.savePostHeroAnimation(postId=val(arguments.postId), animationEffect=arguments.animationEffect, animationOptions=arguments.animationOptions, heroOverlayText=arguments.heroOverlayText, heroOverlayTextColor=arguments.heroOverlayTextColor, heroOverlayFont=arguments.heroOverlayFont, heroOverlayFontSize=arguments.heroOverlayFontSize)>
				<cfset response[ "success" ] = true />
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="saveBlogOptionAnimation" access="remote" returnformat="json" output="false"
			hint="Saves the site-wide default animation effect (+ its JSON options) picked in
			heroAnimationEditor.cfm's Choose Animation popup, opened from Blog Options' 'Configure Animation
			Defaults' button. Deliberately its own small endpoint rather than a call to saveBlogOptions() - see
			blog.cfc's saveBlogOptionAnimation() for why reusing that ~30-argument form save here would be
			unsafe. 2026-10-03: renamed from saveBlogOptionVanta/vantaEffect/vantaOptions while still
			dev-only/unmigrated.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="blogOptionId" type="string" default="0" required="true">
		<cfargument name="animationEffect" type="string" required="true">
		<cfargument name="animationOptions" type="string" default="" required="false">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset application.blog.saveBlogOptionAnimation(blogOptionId=val(arguments.blogOptionId), animationEffect=arguments.animationEffect, animationOptions=arguments.animationOptions)>
				<cfset response[ "success" ] = true />
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="deletePageCollection" access="remote" returnformat="json" output="false"
			hint="Explicit owner-triggered delete from Configure Page Collections.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="pageCollectionId" type="string" required="true">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cfset response[ "success" ] = application.blog.deletePageCollection(val(arguments.pageCollectionId)) />
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="setPageCollectionsForPost" access="remote" returnformat="json" output="false"
			hint="Saves the multi-select of which Page Collection(s) a Page belongs to, from the Page editor.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" type="string" required="true">
		<cfargument name="pageCollectionIdList" type="string" default="" required="false">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost')>

		<cfif application.Udf.isLoggedIn()>
			<cfset response[ "success" ] = application.blog.setPageCollectionsForPost(val(arguments.postId), arguments.pageCollectionIdList) />
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="addPagesToPageCollection" access="remote" returnformat="json" output="false"
			hint="Adds one or more Pages to a Page Collection from the quick-add multiselect in Configure Page Collections - additive only, does not touch any other Collection memberships those Pages already have.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="pageCollectionId" type="string" required="true">
		<cfargument name="postIdList" type="string" default="" required="false">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost')>

		<cfif application.Udf.isLoggedIn()>
			<cfif not len(arguments.postIdList)>
				<cfset response[ "errorMessage" ] = "Choose at least one page." />
			<cfelse>
				<cfset response[ "success" ] = application.blog.addPagesToPageCollection(val(arguments.pageCollectionId), arguments.postIdList) />
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="savePageCollectionMemberOrder" access="remote" returnformat="json" output="false"
			hint="Saves a new drag-and-drop member order, from Configure Page Collections.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="pageCollectionId" type="string" required="true">
		<cfargument name="postIdOrderedList" type="string" required="true">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cfset response[ "success" ] = application.blog.savePageCollectionMemberOrder(val(arguments.pageCollectionId), arguments.postIdOrderedList) />
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="savePageCollectionTheme" access="remote" returnformat="json" output="false"
			hint="Sets the theme used to render a Collection's own listing view, from Configure Page Collections.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="pageCollectionId" type="string" required="true">
		<cfargument name="themeRef" type="string" required="true">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cfset response[ "success" ] = application.blog.savePageCollectionTheme(val(arguments.pageCollectionId), val(arguments.themeRef)) />
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="saveHomepageSettings" access="remote" returnformat="json" output="false"
			hint="Saves the Configure Homepage picker - three independently toggled, additive sections.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="homepageShowPages" type="string" default="false" required="false">
		<cfargument name="homepagePageIdList" type="string" default="" required="false" hint="Comma separated, ordered list of PostIds.">
		<cfargument name="homepageShowCollections" type="string" default="false" required="false">
		<cfargument name="homepageCollectionIdList" type="string" default="" required="false" hint="Comma separated, ordered list of PageCollectionIds.">
		<cfargument name="homepageShowBlogPosts" type="string" default="false" required="false">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cfset saveOk = application.blog.saveHomepageSettings(
				showPages=arguments.homepageShowPages,
				pageIdList=arguments.homepagePageIdList,
				showCollections=arguments.homepageShowCollections,
				collectionIdList=arguments.homepageCollectionIdList,
				showBlogPosts=arguments.homepageShowBlogPosts)>
			<cfif saveOk>
				<cfset response[ "success" ] = true />
			<cfelse>
				<cfset response[ "errorMessage" ] = "Choose at least one page/collection for any section you turned on, and make sure every collection already has at least 2 pages." />
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<cffunction name="saveMenuSettings" access="remote" returnformat="json" output="false"
			hint="Saves the Configure Menu window (2026-10-10, 4.8): the owner's Menu links and the two top menu labels. See blog.cfc's saveMenuSettings.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="linksJson" type="string" default="[]" required="false" hint="JSON array of {label, linkUrl, newWindow}, in display order.">
		<cfargument name="collectionsMenuLabel" type="string" default="" required="false">
		<cfargument name="mobileMenuLabel" type="string" default="" required="false">

		<cfset response = {} />
		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<!--- Same capability as Configure Theme, since the menu is part of the site's look. --->
		<cfset secureFunction('EditTheme')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset menuLinks = deserializeJson(arguments.linksJson)>
				<cfif not isArray(menuLinks)>
					<cfset menuLinks = []>
				</cfif>
				<cfset saveResult = application.blog.saveMenuSettings(links=menuLinks, collectionsMenuLabel=arguments.collectionsMenuLabel, mobileMenuLabel=arguments.mobileMenuLabel)>
				<cfset response[ "success" ] = saveResult.success />
				<cfset response[ "errorMessage" ] = saveResult.errorMessage />
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The menu could not be saved: " & cfcatch.message />
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn response>
		<cfelse>
			<cfreturn serializeJSON(response)>
		</cfif>
	</cffunction>

	<!--- ********************************************************************************************************************
		Bookings: locations (2026-10-14). Where bookings happen - in person, online or phone - managed by application.locations
		(common/cfc/Locations.cfc) from the Locations window (88) and the location editor (89). Same capability as Forms: the
		bookings that use these hold visitors' personal details.
	********************************************************************************************************************* --->

	<cffunction name="getLocationsForGrid" access="remote" returnformat="json" output="false"
			hint="The Locations grid (window 88), Kendo or jsGrid.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="no" default="kendo" hint="Either kendo or jsGrid">
		<!--- Not used for filtering (the grid filters client-side) - declared so jsGrid's field-based filter query params don't trip strict argument matching. --->
		<cfargument name="label" required="no" default="">
		<cfargument name="kindLabel" required="no" default="">
		<cfargument name="details" required="no" default="">
		<cfargument name="status" required="no" default="">

		<cfset var data = []>
		<cfset var thisLocation = "">
		<cfset var kindLabels = { "inPerson": "In person", "online": "Online", "phone": "Phone" }>
		<cfset var jsonString = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfif application.serverProduct eq 'Lucee'><cfreturn "Invalid token"><cfelse><cfreturn serializeJSON("Invalid token")></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfloop array="#application.locations.getLocations()#" index="thisLocation">
			<cfset arrayAppend(data, [
				"LocationOptionId": thisLocation.locationOptionId,
				"Label": thisLocation.label,
				"KindLabel": kindLabels[thisLocation.kind],
				"Details": application.locations.getSummary(thisLocation),
				"SortOrder": thisLocation.sortOrder,
				"Status": thisLocation.active ? "Active" : "Not active"
			])>
		</cfloop>

		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfif arguments.gridType eq 'jsGrid'>
				<cfinvokeargument name="includeDataHandle" value="true">
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>
		<cfreturn jsonString>
	</cffunction>

	<cffunction name="saveLocation" access="remote" returnformat="json" output="false"
			hint="Saves a location from the location editor (window 89).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="locationJson" type="string" default="{}" required="false" hint="JSON: locationOptionId, kind, label, venueName, address, onlineLinkMode, onlineUrl, phoneDirection, phoneNumber, instructions, active, sortOrder.">

		<cfset var response = { "success": false, "errorMessage": "", "locationOptionId": 0 }>
		<cfset var locationData = "">
		<cfset var saveResult = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset locationData = deserializeJson(arguments.locationJson)>
				<cfif not isStruct(locationData)>
					<cfset locationData = {}>
				</cfif>
				<cfset saveResult = application.locations.saveLocation(locationData)>
				<cfset response[ "success" ] = saveResult.success>
				<cfset response[ "locationOptionId" ] = saveResult.locationOptionId>
				<!--- The event posts showing this location have it in their cached pages (2026-10-19). --->
				<cfif saveResult.success and val(saveResult.locationOptionId)>
					<cfset application.events.flushEventPosts(application.events.getPostIdsForLocation(val(saveResult.locationOptionId)))>
				</cfif>
				<cfset response[ "errorMessage" ] = arrayToList(saveResult.errors, "<br/>")>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The location could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteLocation" access="remote" returnformat="json" output="false"
			hint="Deletes a location (Locations window 88).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="locationOptionId" default="0" required="true">

		<cfset var response = { "success": false, "errorMessage": "" }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.locationOptionId)>
			<cftry>
				<!--- A location a booking type still offers can't be deleted (2026-10-14): untick it there, or make it inactive. --->
				<cfset local.usedBy = application.bookings.getTypesUsingLocation(val(arguments.locationOptionId))>
				<cfif arrayLen(local.usedBy)>
					<cfset response[ "errorMessage" ] = "This location is offered by " & encodeForHtml(arrayToList(local.usedBy, ", ")) & ". Uncheck it in those booking types first, or edit the location and untick Active to stop offering it.">
				<!--- ...or an event (2026-10-15). --->
				<cfelseif application.events.isLocationUsed(val(arguments.locationOptionId))>
					<cfset response[ "errorMessage" ] = "An event uses this location. Choose another location in that event first, or edit the location and untick Active to stop offering it.">
				<cfelse>
					<cfset response[ "success" ] = application.locations.deleteLocation(val(arguments.locationOptionId))>
					<cfif not response.success>
						<cfset response[ "errorMessage" ] = "That location no longer exists.">
					<cfelse>
						<!--- Its own hours and days off go with it. --->
						<cfset application.bookings.deleteLocationSchedule(val(arguments.locationOptionId))>
					</cfif>
				</cfif>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The location could not be deleted: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<!--- ********************************************************************************************************************
		Bookings on the site (2026-10-14): the booking widget placed in a post or page (common/js/bookings.js). Public, like the
		Forms methods: getBookingWidget hands out a one-time token kept in the visitor's session, getBookingSlots lists free times,
		getBookingQuestions the type's intake questions, and submitBooking checks everything again (token, time, hidden field,
		rate limit, captcha, answers) and books the time inside one lock, so two visitors can't take the same time.
	********************************************************************************************************************* --->

	<cffunction name="saveBookingPage" access="remote" returnformat="json" output="false"
			hint="Makes a page a booking page, or changes what it offers (2026-10-17, the Booking page window, 104). Returns { success, errorMessage, label }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfargument name="offer" type="string" required="false" default="">
		<cfset var response = { "success": false, "errorMessage": "", "label": "" }>
		<cfset var result = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.postId) and arguments.postId gt 0>
			<cfset result = application.bookings.setPageOffer(val(arguments.postId), arguments.offer)>
			<cfset response[ "success" ] = result.success>
			<cfset response[ "errorMessage" ] = arrayToList(result.errors, " ")>
			<cfif result.success>
				<cfset response[ "label" ] = application.bookings.offerLabel(trim(arguments.offer))>
				<cfset application.blog.flushGalaxieCache(type = "post", postId = val(arguments.postId))>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="removeBookingPage" access="remote" returnformat="json" output="false"
			hint="Makes a booking page an ordinary page again: the booking form comes off, the page stays (2026-10-17). Returns { success }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfset var response = { "success": false }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.postId) and arguments.postId gt 0>
			<cfset application.bookings.removePage(val(arguments.postId))>
			<cfset application.blog.flushGalaxieCache(type = "post", postId = val(arguments.postId))>
			<cfset response[ "success" ] = true>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getBookingWidget" access="remote" returnformat="json" output="false"
			hint="The booking types for a booking widget (one type by alias, or all of them for *), as visitors see them, with a token for sending.">
		<cfargument name="alias" type="string" required="false" default="*">

		<cfset var response = { "success": false, "types": [], "token": "", "captcha": false, "timeZone": "" }>
		<cfset var typeAlias = trim(arguments.alias) eq "*" ? "" : left(trim(arguments.alias), 100)>
		<cfset var token = "">
		<cfset var key = "">

		<cfset response[ "types" ] = application.bookings.getPublicTypes(typeAlias)>
		<cfset response[ "timeZone" ] = application.blog.getBlogTimeZoneId()>
		<cfif arrayLen(response.types) and len(response.timeZone)>
			<cfset token = lCase(hash(createUUID() & rand("SHA1PRNG"), "SHA-256"))>
			<cflock scope="session" type="exclusive" timeout="10">
				<cfif not structKeyExists(session, "bookingTokens") or not isStruct(session.bookingTokens)>
					<cfset session.bookingTokens = {}>
				</cfif>
				<cfloop collection="#session.bookingTokens#" item="key">
					<cfif dateDiff("h", session.bookingTokens[key], now()) gte 6>
						<cfset structDelete(session.bookingTokens, key)>
					</cfif>
				</cfloop>
				<cfif structCount(session.bookingTokens) gte 20>
					<cfset session.bookingTokens = {}>
				</cfif>
				<cfset session.bookingTokens[token] = now()>
			</cflock>
			<cfset response[ "token" ] = token>
			<cfset response[ "captcha" ] = captchaRequired()>
			<cfset response[ "success" ] = true>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getBookingSlots" access="remote" returnformat="json" output="false"
			hint="The free times of a booking type at a location between two dates (yyyy-mm-dd, the blog's time zone; at most about two months).">
		<cfargument name="alias" type="string" required="false" default="">
		<cfargument name="locationOptionId" required="false" default="0">
		<cfargument name="fromDate" type="string" required="false" default="">
		<cfargument name="toDate" type="string" required="false" default="">

		<cfset var response = { "success": false, "slots": [] }>
		<cfset var bookingType = application.bookings.getBookingType(alias = left(trim(arguments.alias), 100))>

		<cfif not structIsEmpty(bookingType) and bookingType.active and isNumeric(arguments.locationOptionId)>
			<cfset response[ "slots" ] = application.bookings.getSlots(bookingType, val(arguments.locationOptionId), left(trim(arguments.fromDate), 10), left(trim(arguments.toDate), 10))>
			<cfset response[ "success" ] = true>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getBookingQuestions" access="remote" returnformat="json" output="false"
			hint="The HTML of a booking type's intake questions (its form's fields, encoded by WebForms.cfc), or nothing when it asks none.">
		<cfargument name="alias" type="string" required="false" default="">

		<cfset var response = { "success": true, "html": "" }>
		<cfset var bookingType = application.bookings.getBookingType(alias = left(trim(arguments.alias), 100))>
		<cfset var webForm = "">

		<cfif not structIsEmpty(bookingType) and bookingType.active and bookingType.webFormId gt 0>
			<cfset webForm = application.webForms.getForm(webFormId = bookingType.webFormId)>
			<cfif not structIsEmpty(webForm)>
				<cfset response[ "html" ] = application.webForms.renderFieldsHtml(webForm.fields, "booking" & bookingType.bookingTypeId & "_", application.webForms.getChoiceCounts(webForm))>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="submitBooking" access="remote" returnformat="json" output="false"
			hint="Books a time from the booking widget. Everything is checked again here; nothing from the browser is trusted.">
		<cfargument name="alias" type="string" required="false" default="">
		<cfargument name="locationOptionId" required="false" default="0">
		<cfargument name="startLocal" type="string" required="false" default="">
		<cfargument name="partySize" required="false" default="1">
		<cfargument name="name" type="string" required="false" default="">
		<cfargument name="email" type="string" required="false" default="">
		<cfargument name="phone" type="string" required="false" default="">
		<cfargument name="visitorTimeZone" type="string" required="false" default="">
		<cfargument name="valuesJson" type="string" required="false" default="{}" hint="The intake answers, keyed by field name.">
		<cfargument name="token" type="string" required="false" default="">
		<cfargument name="captchaText" type="string" required="false" default="">
		<cfargument name="website" type="string" required="false" default="" hint="The hidden field only bots fill in.">
		<cfargument name="postId" required="false" default="0">
		<cfargument name="returnUrl" type="string" required="false" default="" hint="The page the visitor books from; they come back to it from the payment page.">

		<cfset var response = { "success": false, "errors": {}, "message": "", "status": "", "detailsHtml": "", "locationLabel": "", "startUtc": "", "checkoutUrl": "" }>
		<cfset var checkout = "">
		<cfset var backTo = "">
		<cfset var bookingType = application.bookings.getBookingType(alias = left(trim(arguments.alias), 100))>
		<cfset var issued = "">
		<cfset var ip = cgi.remote_addr>
		<cfset var recent = []>
		<cfset var stamp = "">
		<cfset var key = "">
		<cfset var sent = {}>
		<cfset var intakeValues = {}>
		<cfset var checked = "">
		<cfset var webForm = {}>
		<cfset var booked = "">
		<cfset var meetLocation = "">

		<cfif structIsEmpty(bookingType) or not bookingType.active>
			<cfset response[ "message" ] = "This can't be booked any more.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<!--- The token: issued to this visitor's session by getBookingWidget, at least 3 seconds ago, used once. --->
		<cflock scope="session" type="exclusive" timeout="10">
			<cfif structKeyExists(session, "bookingTokens") and isStruct(session.bookingTokens) and structKeyExists(session.bookingTokens, arguments.token)>
				<cfset issued = session.bookingTokens[arguments.token]>
			</cfif>
		</cflock>
		<cfif not isDate(issued) or dateDiff("h", issued, now()) gte 6>
			<cfset response[ "message" ] = "This page has been open for a long time, or the booking was already sent. Please reload the page and try again.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfif dateDiff("s", issued, now()) lt 3>
			<cfset response[ "message" ] = "That was very quick - please check the details and send them again.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<!--- The hidden field: answer as if it worked, book nothing. --->
		<cfif len(trim(arguments.website))>
			<cfset forgetBookingToken(arguments.token)>
			<cfset response[ "success" ] = true>
			<cfset response[ "status" ] = "confirmed">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<!--- At most 10 sends an hour from one address, shared with Forms. --->
		<cflock name="galaxieWebFormRateLimit" type="exclusive" timeout="10">
			<cfif not structKeyExists(application, "webFormRateLimit") or not isStruct(application.webFormRateLimit)>
				<cfset application.webFormRateLimit = {}>
			</cfif>
			<cfloop collection="#application.webFormRateLimit#" item="key">
				<cfset recent = []>
				<cfloop array="#application.webFormRateLimit[key]#" index="stamp">
					<cfif dateDiff("n", stamp, now()) lt 60><cfset arrayAppend(recent, stamp)></cfif>
				</cfloop>
				<cfif arrayLen(recent)><cfset application.webFormRateLimit[key] = recent><cfelse><cfset structDelete(application.webFormRateLimit, key)></cfif>
			</cfloop>
			<cfset recent = structKeyExists(application.webFormRateLimit, ip) ? application.webFormRateLimit[ip] : []>
			<cfif arrayLen(recent) gte 10>
				<cfset response[ "message" ] = "Too many bookings and forms have been sent from your connection in the last hour. Please try again later.">
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
		</cflock>

		<!--- The captcha (not for a signed-in user), as on the comment form. --->
		<cfif captchaRequired()>
			<cfif not structKeyExists(session, "captchaText") or not len(session.captchaText) or not len(trim(arguments.captchaText)) or trim(arguments.captchaText) neq session.captchaText>
				<cfset response[ "errors" ][ "captchaText" ] = "The text from the image did not match. Please try again.">
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
		</cfif>

		<!--- The intake answers, checked against the type's form. --->
		<cfif bookingType.webFormId gt 0>
			<cfset webForm = application.webForms.getForm(webFormId = bookingType.webFormId)>
			<cfif not structIsEmpty(webForm)>
				<cftry>
					<cfset sent = deserializeJSON(arguments.valuesJson)>
					<cfcatch type="any"><cfset sent = {}></cfcatch>
				</cftry>
				<cfif not isStruct(sent)><cfset sent = {}></cfif>
				<cfset checked = application.webForms.validateSubmission(webForm, sent, application.webForms.getChoiceCounts(webForm))>
				<cfif not checked.valid>
					<cfset response[ "errors" ] = checked.errors>
					<!--- Point out the visitor's own details too, so every problem shows at once. --->
					<cfif not len(trim(arguments.name))><cfset response[ "errors" ][ "name" ] = "Please enter your name."></cfif>
					<cfif not isValid("email", trim(arguments.email))><cfset response[ "errors" ][ "email" ] = "Please enter a valid email address."></cfif>
					<cfset response[ "message" ] = "Please check the highlighted details.">
					<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
				</cfif>
				<cfset intakeValues = checked.values>
			</cfif>
		</cfif>

		<!--- One lock for the whole blog's bookings: the owner is one person, so any booking can take time from any other. --->
		<cflock name="galaxieBookings_#application.BlogDbObj.getBlogId()#" type="exclusive" timeout="20">
			<cfset booked = application.bookings.createBooking(
				bookingType = bookingType,
				locationOptionId = isNumeric(arguments.locationOptionId) ? val(arguments.locationOptionId) : 0,
				startLocal = left(trim(arguments.startLocal), 16),
				partySize = isNumeric(arguments.partySize) ? val(arguments.partySize) : 1,
				name = left(trim(arguments.name), 255),
				email = left(trim(arguments.email), 255),
				phone = left(trim(arguments.phone), 50),
				visitorTimeZone = arguments.visitorTimeZone,
				intakeValues = intakeValues,
				postId = isNumeric(arguments.postId) ? val(arguments.postId) : 0
			)>
		</cflock>
		<cfif not booked.success>
			<cfset response[ "errors" ] = booked.errors>
			<cfset response[ "message" ] = len(booked.message) ? booked.message : "Please check the highlighted details.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<!--- Booked: spend the token and the captcha word, count it, and send back what the confirmation shows. --->
		<cfset forgetBookingToken(arguments.token)>
		<cfif structKeyExists(session, "captchaText")><cfset structDelete(session, "captchaText")></cfif>
		<cflock name="galaxieWebFormRateLimit" type="exclusive" timeout="10">
			<cfif not structKeyExists(application.webFormRateLimit, ip)><cfset application.webFormRateLimit[ip] = []></cfif>
			<cfset arrayAppend(application.webFormRateLimit[ip], now())>
		</cflock>
		<!--- Paid online (2026-10-15): send the visitor to Stripe's payment page. The time stays held until the payment webhook
		confirms it (common/services/stripeWebhook.cfm), which also sends the emails; nothing is confirmed from the browser. --->
		<cfif structKeyExists(booked, "paymentRequired") and booked.paymentRequired>
			<cfset backTo = listFirst(trim(arguments.returnUrl), "?##")>
			<cfif not len(backTo) or left(backTo, len(application.blogHostUrl)) neq application.blogHostUrl or reFind("[\s<>""']", backTo)>
				<cfset backTo = application.blogHostUrl & "/">
			</cfif>
			<cfset checkout = application.payments.createBookingCheckout(
				bookingId = booked.bookingId,
				purpose = booked.paymentPurpose,
				itemName = bookingType.name & (booked.paymentPurpose eq "deposit" ? " (deposit)" : ""),
				itemDescription = application.bookings.formatInZone(entityLoadByPK("Booking", booked.bookingId).getStartUtc(), application.blog.getBlogTimeZoneId()),
				amount = booked.amountDueNow,
				currencyCode = application.payments.getCurrency(),
				email = trim(arguments.email),
				successUrl = backTo & "?bookingCheckout={CHECKOUT_SESSION_ID}",
				cancelUrl = backTo & "?bookingCancelled=" & booked.manageToken
			)>
			<cfif not checkout.success>
				<cfset application.bookings.expireHeldBooking(booked.bookingId)>
				<cfset response[ "message" ] = checkout.message>
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
			<cfset response[ "success" ] = true>
			<cfset response[ "status" ] = "held">
			<cfset response[ "checkoutUrl" ] = checkout.url>
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<cfset meetLocation = application.locations.getLocation(val(arguments.locationOptionId))>
		<cfset response[ "success" ] = true>
		<cfset response[ "status" ] = booked.status>
		<cfset response[ "locationLabel" ] = meetLocation.label>
		<cfset response[ "detailsHtml" ] = application.locations.getDetailsHtml(meetLocation)>
		<cfset response[ "startUtc" ] = entityLoadByPK("Booking", booked.bookingId).getStartUtc()>
		<!--- The confirmation (or request) to the visitor and the notice to the owner. --->
		<cfset application.bookings.sendBookingEmails(booked.bookingId, "booked")>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<!--- ********************************************************************************************************************
		Bookings: the visitor's own booking (2026-10-14), from the "Cancel or change this booking" link in their emails
		(?manageBooking=<token>, shown by common/js/bookings.js). The long random token is the visitor's key; nothing else about
		them is needed, and nothing about other bookings is ever returned.
	********************************************************************************************************************* --->

	<cffunction name="getBookingsForCalendar" access="remote" returnformat="json" output="false"
			hint="The bookings between two dates for the admin calendar (window 96, 2026-10-15).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="fromDate" type="string" default="" required="false">
		<cfargument name="toDate" type="string" default="" required="false">
		<cfset var response = { "bookings": [] }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and reFind("^\d{4}-\d{2}-\d{2}$", arguments.fromDate) and reFind("^\d{4}-\d{2}-\d{2}$", arguments.toDate)>
			<cfset response[ "bookings" ] = application.bookings.getBookingsForCalendar(arguments.fromDate, arguments.toDate)>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<!--- ****************************************************************************************************************
		Member accounts (2026-10-15): visitors sign in with a one-time emailed link. See common/cfc/Members.cfc and
		common/js/members.js. A member is never an admin user: none of these calls touch the admin login.
	***************************************************************************************************************** --->

	<cffunction name="memberStatus" access="remote" returnformat="json" output="false"
			hint="Whether member accounts are on, and who is signed in. Called by members.js on each page (pages are cached, so nothing member-specific is in the page itself).">
		<cfset var response = { "enabled": application.members.isEnabled(), "signedIn": false, "member": {}, "csrf": "" }>
		<cfset var member = {}>
		<cfif response.enabled>
			<cfset member = application.members.getCurrentMember()>
			<cfif not structIsEmpty(member)>
				<cfset response[ "signedIn" ] = true>
				<cfset response[ "member" ] = memberForBrowser(member)>
				<cfset response[ "csrf" ] = application.members.getCsrfToken()>
			</cfif>
		</cfif>
		<cfheader name="Cache-Control" value="no-store">
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberRequestSignIn" access="remote" returnformat="json" output="false"
			hint="Emails a one-time sign-in link to the address given.">
		<cfargument name="email" type="string" required="false" default="">
		<cfargument name="returnUrl" type="string" required="false" default="">
		<cfargument name="website" type="string" required="false" default="" hint="The hidden field only bots fill in.">
		<cfset var result = {}>
		<cfset var response = { "success": false, "message": "" }>
		<cfif len(arguments.website)>
			<!--- A bot: the same reply a person gets, and nothing sent. --->
			<cfset response = { "success": true, "message": "If that address can be used here, a sign-in link is on its way." }>
		<cfelse>
			<cfset result = application.members.requestSignIn(email = arguments.email, returnUrl = arguments.returnUrl, ipAddress = cgi.remote_addr)>
			<cfset response = { "success": result.success, "message": result.message }>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberCompleteSignIn" access="remote" returnformat="json" output="false"
			hint="Uses the token from an emailed sign-in link. Only by POST, from the page the link opens (after the visitor clicks Sign in), so a mail scanner opening the link can't use it up.">
		<cfargument name="token" type="string" required="false" default="">
		<cfargument name="remember" required="false" default="false">
		<cfset var result = {}>
		<cfset var response = { "success": false, "message": "This sign-in link has expired or was already used. Please ask for a new one.", "member": {}, "csrf": "" }>
		<cfif cgi.request_method eq "POST">
			<cfset result = application.members.completeSignIn(token = trim(arguments.token), remember = isBoolean(arguments.remember) and arguments.remember, userAgent = cgi.http_user_agent)>
			<cfset response[ "success" ] = result.success>
			<cfset response[ "message" ] = result.message>
			<cfif result.success>
				<cfset response[ "member" ] = memberForBrowser(result.member)>
				<cfset response[ "csrf" ] = application.members.getCsrfToken()>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberSaveProfile" access="remote" returnformat="json" output="false" hint="The signed-in member's name, phone and time zone.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfargument name="name" type="string" required="false" default="">
		<cfargument name="phone" type="string" required="false" default="">
		<cfargument name="timeZone" type="string" required="false" default="">
		<cfset var result = {}>
		<cfset var response = { "success": false, "errors": [ "Please sign in again." ], "member": {} }>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf)>
			<cfset result = application.members.saveProfile(name = arguments.name, phone = arguments.phone, timeZone = arguments.timeZone)>
			<cfset response = { "success": result.success, "errors": result.errors, "member": result.success ? memberForBrowser(result.member) : {} }>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberSignOut" access="remote" returnformat="json" output="false" hint="Signs the member out of this browser, or everywhere.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfargument name="everywhere" required="false" default="false">
		<cfset var response = { "success": false }>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf)>
			<cfset application.members.signOut(everywhere = isBoolean(arguments.everywhere) and arguments.everywhere)>
			<cfset response[ "success" ] = true>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberAccount" access="remote" returnformat="json" output="false"
			hint="What the My account window lists: the member's bookings, form sign-ups and email subscriptions.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfset var member = {}>
		<cfset var response = { "success": false, "bookings": [], "signups": [], "subscriptions": {} }>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf)>
			<cfset member = application.members.getCurrentMember()>
			<cfif not structIsEmpty(member)>
				<cfset response = {
					"success": true,
					"bookings": application.members.getAccountBookings(member),
					"signups": application.members.getAccountSignups(member),
					"subscriptions": application.members.getAccountSubscriptions(member),
					<!--- Shop orders (2026-10-21): paid orders and the download links that still work. --->
					"orders": structKeyExists(application, "shop") ? application.shop.getMemberOrders(member) : []
				}>
			</cfif>
		</cfif>
		<cfheader name="Cache-Control" value="no-store">
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberSetNewPostEmails" access="remote" returnformat="json" output="false" hint="Turns the signed-in member's new-post emails on or off.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfargument name="on" required="false" default="false">
		<cfset var response = { "success": false }>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf)>
			<cfset response[ "success" ] = application.members.setNewPostEmails(isBoolean(arguments.on) and arguments.on)>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberStopFollowingPost" access="remote" returnformat="json" output="false" hint="Stops the signed-in member's new-comment emails for one post.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfargument name="postId" required="false" default="0">
		<cfset var response = { "success": false }>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf) and isValid("integer", arguments.postId)>
			<cfset response[ "success" ] = application.members.stopFollowingPost(arguments.postId)>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberExportData" access="remote" returnformat="plain" output="false"
			hint="Download my data: everything the blog keeps about the signed-in member, as a JSON file.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfset var member = {}>
		<cfset var fileName = "">
		<cfif cgi.request_method neq "POST" or not application.members.checkCsrfToken(arguments.csrf)>
			<cfheader statuscode="403">
			<cfreturn "">
		</cfif>
		<cfset member = application.members.getCurrentMember()>
		<cfif structIsEmpty(member)>
			<cfheader statuscode="403">
			<cfreturn "">
		</cfif>
		<cfset fileName = "my-data-" & reReplace(lCase(application.BlogDbObj.getBlogTitle()), "[^a-z0-9]+", "-", "all") & "-" & dateFormat(now(), "yyyy-mm-dd") & ".json">
		<cfheader name="Content-Disposition" value='attachment; filename="#fileName#"'>
		<cfheader name="Cache-Control" value="no-store">
		<cfcontent type="application/json; charset=utf-8">
		<cfreturn serializeJSON(application.members.exportData(member))>
	</cffunction>

	<cffunction name="adminDeletePerson" access="remote" returnformat="json" output="false"
			hint="Delete everything about one person in Members (admin, window 98, 2026-10-17) - Members.cfc adminDeletePerson. Returns { success, blockers[] }: when something stops it (an upcoming booking or event place, or an event they host), nothing is deleted and blockers says what to do first.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="email" type="string" required="false" default="">
		<cfset var response = { "success": false, "blockers": [] }>
		<cfset var outcome = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif application.Udf.isLoggedIn()>
			<cfset outcome = application.members.adminDeletePerson(arguments.email)>
			<cfset response[ "success" ] = outcome.success>
			<cfset response[ "blockers" ] = outcome.blockers>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="useReadyMadeForm" access="remote" returnformat="json" output="false"
			hint="Insert Form (window 86, 2026-10-17) and a scene's Form section: a new form made from a ready-made choice - each use its own copy (WebForms.cfc useReadyMade, 2026-10-20). Returns { success, webFormId, alias, title, publicList, errors }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="key" type="string" required="false" default="">
		<cfargument name="usedFor" type="string" required="false" default="" hint="The post, page or scene it's for; the new form is named after it.">
		<cfset var response = { "success": false, "webFormId": 0, "alias": "", "title": "", "publicList": false, "errors": [] }>
		<cfset var result = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn()>
			<cfset result = application.webForms.useReadyMade(left(trim(arguments.key), 40), left(trim(arguments.usedFor), 80))>
			<cfset response = { "success": result.success, "webFormId": result.webFormId, "alias": result.alias, "title": result.title, "publicList": result.publicList, "errors": result.errors }>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getAdminTraffic" access="remote" returnformat="json" output="false"
			hint="The admin home's traffic cards (5.0): AdminHome.cfc getTraffic, for someone signed in who may open the Visitor Log.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfset var response = { "success": false, "traffic": {} }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset response[ "traffic" ] = application.blog.getAdminHome().getTraffic()>
				<cfset response[ "success" ] = true>
				<cfcatch type="any"><cfset response[ "message" ] = cfcatch.message></cfcatch>
			</cftry>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="hideUpNext" access="remote" returnformat="json" output="false"
			hint="The admin home's Up next row (5.0): hides one suggestion (its x) until something new happens (AdminHome.cfc hide).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="kind" type="string" default="" required="false">
		<cfargument name="signature" type="string" default="" required="false">
		<cfset var response = { "success": false }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfif application.Udf.isLoggedIn() and len(arguments.kind)>
			<cfset application.blog.getAdminHome().hide(arguments.kind, arguments.signature)>
			<cfset response[ "success" ] = true>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getWebFormQuickEdit" access="remote" returnformat="json" output="false"
			hint="A scene's Form section (2026-10-20): the form's quick-edit view (WebForms.cfc getQuickEdit). Returns { success, form }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="webFormId" required="false" default="0">
		<cfset var response = { "success": false, "form": {} }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.webFormId)>
			<cfset response[ "form" ] = application.webForms.getQuickEdit(val(arguments.webFormId))>
			<cfset response[ "success" ] = not structIsEmpty(response.form)>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveWebFormQuickEdit" access="remote" returnformat="json" output="false"
			hint="A scene's Form section (2026-10-20): saves the quick edit (WebForms.cfc saveQuickEdit). fieldsJson = [{ webFormFieldId, label, required }]. Returns { success, errorMessage }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="webFormId" required="false" default="0">
		<cfargument name="description" type="string" required="false" default="">
		<cfargument name="buttonLabel" type="string" required="false" default="">
		<cfargument name="notifyEmails" type="string" required="false" default="">
		<cfargument name="fieldsJson" type="string" required="false" default="[]">
		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var fieldList = []>
		<cfset var saveResult = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.webFormId)>
			<cftry>
				<cfset fieldList = isJSON(arguments.fieldsJson) ? deserializeJSON(arguments.fieldsJson) : []>
				<cfif not isArray(fieldList)><cfset fieldList = []></cfif>
				<cfset saveResult = application.webForms.saveQuickEdit(val(arguments.webFormId), arguments.description, arguments.buttonLabel, arguments.notifyEmails, fieldList)>
				<cfif saveResult.success>
					<cfset flushWebFormPosts(saveResult.changedPostIds)>
					<cfset application.events.flushEventPosts(application.events.getPostIdsForForm(val(saveResult.webFormId)))>
				</cfif>
				<cfset response[ "success" ] = saveResult.success>
				<cfset response[ "errorMessage" ] = arrayToList(saveResult.errors, " ")>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The form could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="sendErrorSummaryNow" access="remote" returnformat="json" output="false"
			hint="Blog Options (2026-10-18): sends the error summary for the last 24 hours right away (ErrorDigest.cfc send), without changing when tonight's is due. Returns { errors, distinct, sent }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfset var response = { "errors": 0, "distinct": 0, "sent": false }>
		<cfset var result = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn()>
			<cfset result = application.blog.getErrorDigest().send(dateTimeFormat(dateAdd("h", -24, application.blog.blogNow()), "yyyy-mm-dd HH:nn:ss"))>
			<cfset response = { "errors": result.errors, "distinct": result.distinct, "sent": result.sent }>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getMemberSignInsForGrid" access="remote" returnformat="json" output="false"
			hint="The Member sign-ins grid (window 105, 2026-10-17), Kendo or jsGrid: every time a member signed in (Members.cfc getSignInsForAdmin).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="no" default="kendo" hint="Either kendo or jsGrid">
		<cfargument name="memberId" required="no" default="0" hint="One member's sign-ins, or 0 for everyone's.">
		<!--- Not used for filtering (the grid filters client-side) - declared so jsGrid's field-based filter query params don't trip strict argument matching. --->
		<cfargument name="memberName" required="no" default="">
		<cfargument name="ipAddress" required="no" default="">
		<cfargument name="httpUserAgent" required="no" default="">
		<cfargument name="method" required="no" default="">
		<cfargument name="signedIn" required="no" default="">
		<cfset var jsonString = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfif application.serverProduct eq 'Lucee'><cfreturn "Invalid token"><cfelse><cfreturn serializeJSON("Invalid token")></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#application.members.getSignInsForAdmin(isValid('integer', arguments.memberId) ? val(arguments.memberId) : 0)#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfif arguments.gridType eq 'jsGrid'>
				<cfinvokeargument name="includeDataHandle" value="true">
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>
		<cfreturn jsonString>
	</cffunction>

	<cffunction name="adminExportPersonData" access="remote" returnformat="plain" output="false"
			hint="Download their data (admin, window 98, 2026-10-17): everything the blog keeps about one person in the Members list, found by email address, as a JSON file - the same file a member gets from Download my data, and it works for people without an account.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="email" type="string" required="false" default="">
		<cfset var person = {}>
		<cfset var fileName = "">
		<cfif cgi.request_method neq "POST" or not verifyCsrfToken(arguments.csrfToken)>
			<cfheader statuscode="403">
			<cfreturn "">
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif not application.Udf.isLoggedIn()>
			<cfheader statuscode="403">
			<cfreturn "">
		</cfif>
		<cfset person = application.members.getPersonForAdmin(arguments.email)>
		<cfif structIsEmpty(person)>
			<cfheader statuscode="404">
			<cfreturn "">
		</cfif>
		<cfset fileName = "data-" & reReplace(lCase(person.email), "[^a-z0-9]+", "-", "all") & "-" & dateFormat(now(), "yyyy-mm-dd") & ".json">
		<cfheader name="Content-Disposition" value='attachment; filename="#fileName#"'>
		<cfheader name="Cache-Control" value="no-store">
		<cfcontent type="application/json; charset=utf-8">
		<cfreturn serializeJSON(application.members.exportData(person.member))>
	</cffunction>

	<cffunction name="memberAccountDeleteInfo" access="remote" returnformat="json" output="false" hint="What the delete-account window needs to say: how many upcoming bookings are still on.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfset var member = {}>
		<cfset var response = { "success": false, "upcomingBookings": 0 }>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf)>
			<cfset member = application.members.getCurrentMember()>
			<cfif not structIsEmpty(member)>
				<cfset response = { "success": true, "upcomingBookings": application.members.countUpcomingBookings(member) }>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberDeleteAccount" access="remote" returnformat="json" output="false" hint="Deletes the signed-in member's account (they type their email address to confirm).">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfargument name="confirmEmail" type="string" required="false" default="">
		<cfargument name="stopEmails" required="false" default="true">
		<cfset var result = {}>
		<cfset var response = { "success": false, "message": "Please sign in again." }>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf)>
			<cfset result = application.members.deleteAccount(confirmEmail = arguments.confirmEmail, stopEmails = isBoolean(arguments.stopEmails) and arguments.stopEmails)>
			<cfset response = { "success": result.success, "message": result.message }>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getMembersForGrid" access="remote" returnformat="json" output="false" hint="Every member, for the admin Members window.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfset var response = { "members": [] }>
		<cfset var member = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif application.Udf.isLoggedIn()>
			<cfloop array="#application.members.getMembersForAdmin()#" index="member">
				<cfset arrayAppend(response.members, {
					"memberId": member.memberId, "email": member.email, "name": member.name, "phone": member.phone, "status": member.status,
					"created": isDate(member.created) ? dateTimeFormat(member.created, "yyyy-mm-dd HH:nn") : "",
					"lastSeen": isDate(member.lastSeen) ? dateTimeFormat(member.lastSeen, "yyyy-mm-dd HH:nn") : ""
				})>
			</cfloop>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="setMemberStatus" access="remote" returnformat="json" output="false" hint="Blocks or unblocks a member (admin).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="memberId" required="false" default="0">
		<cfargument name="status" type="string" required="false" default="">
		<cfset var response = { "success": false }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.memberId)>
			<cfset response[ "success" ] = application.members.setMemberStatus(val(arguments.memberId), arguments.status)>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="adminDeleteMember" access="remote" returnformat="json" output="false" hint="Deletes a member (admin, Members window).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="memberId" required="false" default="0">
		<cfargument name="stopEmails" required="false" default="false">
		<cfset var response = { "success": false }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.memberId)>
			<cfset response[ "success" ] = application.members.adminDeleteMember(val(arguments.memberId), isBoolean(arguments.stopEmails) and arguments.stopEmails)>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

		<cffunction name="captchaRequired" access="private" returntype="boolean" output="false"
			hint="Whether the captcha is asked for: Use Captcha is on, and nobody is signed in - neither an admin user nor (2026-10-15) a member. Comments, bookings and forms all use this one rule, and so does the comment window (includes/windows/addCommentSubscribe.cfm).">
		<cfif not application.useCaptcha or application.Udf.isLoggedIn()>
			<cfreturn false>
		</cfif>
		<cfif structKeyExists(application, "members") and not structIsEmpty(application.members.getCurrentMember())>
			<cfreturn false>
		</cfif>
		<cfreturn true>
	</cffunction>

	
	<!--- ****************************************************************************************************************
		Events (2026-10-15): a post with event details. See common/cfc/Events.cfc and admin/adminInterface/eventDetail.cfm.
	***************************************************************************************************************** --->

	<cffunction name="saveEvent" access="remote" returnformat="json" output="false" hint="Adds or updates the event on a post (admin).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfargument name="startDate" type="string" required="false" default="">
		<cfargument name="startTime" type="string" required="false" default="">
		<cfargument name="endDate" type="string" required="false" default="">
		<cfargument name="endTime" type="string" required="false" default="">
		<cfargument name="allDay" required="false" default="false">
		<cfargument name="timeZone" type="string" required="false" default="">
		<cfargument name="locationIds" type="string" required="false" default="">
		<cfargument name="status" type="string" required="false" default="scheduled">
		<cfargument name="organizerName" type="string" required="false" default="">
		<cfargument name="organizerUrl" type="string" required="false" default="">
		<cfargument name="cost" type="string" required="false" default="">
		<cfargument name="ticketUrl" type="string" required="false" default="">
		<cfargument name="webFormId" required="false" default="0" hint="The RSVP form (0 = no RSVP).">
		<cfargument name="capacity" type="string" required="false" default="">
		<cfargument name="askPartySize" required="false" default="false">
		<cfargument name="maxPartySize" type="string" required="false" default="1">
		<cfargument name="rsvpClosesDate" type="string" required="false" default="">
		<cfargument name="rsvpClosesTime" type="string" required="false" default="">
		<cfargument name="price" type="string" required="false" default="" hint="Per person; empty or 0 = free.">
		<cfargument name="refundHours" type="string" required="false" default="24">
		<cfset var result = {}>
		<cfset var response = { "success": false, "errors": [] }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.postId)>
			<cfset result = application.events.saveEvent(val(arguments.postId), {
				startDate: arguments.startDate, startTime: arguments.startTime, endDate: arguments.endDate, endTime: arguments.endTime,
				allDay: isBoolean(arguments.allDay) and arguments.allDay, timeZone: arguments.timeZone, locationIds: arguments.locationIds,
				status: arguments.status, organizerName: arguments.organizerName, organizerUrl: arguments.organizerUrl,
				cost: arguments.cost, ticketUrl: arguments.ticketUrl,
				webFormId: arguments.webFormId, capacity: arguments.capacity, askPartySize: isBoolean(arguments.askPartySize) and arguments.askPartySize,
				maxPartySize: arguments.maxPartySize, rsvpClosesDate: arguments.rsvpClosesDate, rsvpClosesTime: arguments.rsvpClosesTime,
				price: arguments.price, refundHours: arguments.refundHours
			})>
			<cfset response = { "success": result.success, "errors": result.errors, "signupsLeft": 0 }>
			<!--- A cancelled event that still has people signed up: the window offers Cancel all and refund. --->
			<cfif result.success and arguments.status eq "cancelled">
				<cfset response[ "signupsLeft" ] = application.events.getRsvpState(application.events.getEvent(val(arguments.postId))).taken>
			</cfif>
			<!--- The post shows the event, so its cached page has to be made again. --->
			<cfif result.success>
				<cfset application.blog.flushGalaxieCache(type = "post", postId = val(arguments.postId))>
				<!--- And the Upcoming Events pod and the Events page. --->
				<cfset application.events.flushListings()>
				<!--- The post editor shows a one-line summary beside its Event type (2026-10-16). --->
				<cfset response[ "when" ] = application.events.shortWhenText(application.events.getEvent(val(arguments.postId)))>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<!--- ***************************************************************************************************************
		People cards (2026-10-16) - see common/cfc/People.cfc. Guest cards are managed with the EditUser capability, like
		users; the author card window on the site (includes/windows/personCard.cfm) sends messages with sendPersonMessage.
	***************************************************************************************************************** --->

	<cffunction name="savePersonCard" access="remote" returnformat="json" output="false" hint="Adds or updates a guest card (window 103).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="personJson" type="string" default="{}" required="false" hint="JSON: personCardId, displayName, email, website, profilePicture, biography, facebookUrl, linkedInUrl, instagramUrl, twitterUrl, active.">
		<cfset var response = { "success": false, "errorMessage": "", "ref": "", "name": "" }>
		<cfset var data = {}>
		<cfset var result = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset data = deserializeJson(arguments.personJson)>
				<cfif not isStruct(data)><cfset data = {}></cfif>
				<cfset result = application.events.getPeople().saveGuest(data)>
				<cfset response[ "success" ] = result.success>
				<cfset response[ "errorMessage" ] = arrayToList(result.errors, "<br/>")>
				<cfset response[ "ref" ] = result.ref>
				<cfset response[ "name" ] = structKeyExists(data, "displayName") ? trim(data.displayName) : "">
				<!--- A card's name shows on cached event pages: the posts it hosts, and the listings. --->
				<cfif result.success><cfset application.events.flushEventPosts(len(result.ref) ? application.events.getPostIdsForPerson(result.ref) : [])></cfif>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The card could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="uploadGuestPicture" access="remote" returnformat="json" output="false"
			hint="A guest card's picture (window 103, 2026-10-16): saved to /images/photo/guest/ under a random name, so uploads never replace each other. JPG, PNG, GIF or WebP up to 5 MB, and it has to be a real image. Returns { success, url, errorMessage }; the editor puts the url in its Picture field.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="guestPicture" required="false" default="" hint="The uploaded file's form field (read with cffile upload).">
		<cfset var response = { "success": false, "url": "", "errorMessage": "" }>
		<cfset var folder = expandPath(application.baseUrl & "/images/photo/guest/")>
		<cfset var uploaded = {}>
		<cfset var tempFile = "">
		<cfset var extension = "">
		<cfset var fileName = "">
		<cfset var onWindows = findNoCase("windows", server.os.name) gt 0>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfif not directoryExists(folder)>
					<cfset directoryCreate(folder)>
					<!--- On Linux the web server has to be able to read it (galaxieblog.org answered 403 for files Lucee made). --->
					<cfif not onWindows><cfset fileSetAccessMode(folder, "755")></cfif>
				</cfif>
				<cffile action="upload" fileField="guestPicture" destination="#getTempDirectory()#" nameConflict="makeUnique" result="uploaded">
				<cfset tempFile = uploaded.serverDirectory & "/" & uploaded.serverFile>
				<cfset extension = lCase(uploaded.serverFileExt)>
				<cfif not listFind("jpg,jpeg,png,gif,webp", extension)>
					<cfset response[ "errorMessage" ] = "Choose a JPG, PNG, GIF or WebP picture.">
				<cfelseif val(uploaded.fileSize) gt 5 * 1024 * 1024>
					<cfset response[ "errorMessage" ] = "The picture is too big; 5 MB at most.">
				<cfelseif extension neq "webp" and not isImageFile(tempFile)>
					<cfset response[ "errorMessage" ] = "That file isn't a picture.">
				<cfelse>
					<cfset fileName = "guest-" & lCase(left(hash(createUUID() & rand("SHA1PRNG"), "SHA-256"), 16)) & "." & extension>
					<cffile action="move" source="#tempFile#" destination="#folder##fileName#">
					<cfif not onWindows><cfset fileSetAccessMode(folder & fileName, "644")></cfif>
					<cfset response[ "success" ] = true>
					<cfset response[ "url" ] = application.baseUrl & "/images/photo/guest/" & fileName>
				</cfif>
				<cfif fileExists(tempFile)><cfset fileDelete(tempFile)></cfif>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The picture could not be uploaded: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deletePersonCard" access="remote" returnformat="json" output="false" hint="Deletes a guest card, unless an event names it as its organizer.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="personCardId" required="false" default="0">
		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.personCardId)>
			<!--- Copied into quoted keys: Adobe ColdFusion upper-cases unquoted keys in JSON. --->
			<!--- The event posts this card hosts, found before it goes, so their cached pages stop showing it. --->
			<cfset local.hostedPosts = application.events.getPostIdsForPerson("guest:" & val(arguments.personCardId))>
			<cfset local.deleted = application.events.getPeople().deleteGuest(val(arguments.personCardId))>
			<cfif local.deleted.success><cfset application.events.flushEventPosts(local.hostedPosts)></cfif>
			<cfset response[ "success" ] = local.deleted.success>
			<cfset response[ "errorMessage" ] = local.deleted.errorMessage>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="sendPersonMessage" access="remote" returnformat="json" output="false"
			hint="A visitor's message from an author card on the site, emailed straight to that person (People.sendMessage). The captcha is checked here, as for the contact form, and one visitor can send a few messages an hour.">
		<cfargument name="person" type="string" required="false" default="">
		<cfargument name="fromName" type="string" required="false" default="">
		<cfargument name="fromEmail" type="string" required="false" default="">
		<cfargument name="message" type="string" required="false" default="">
		<cfargument name="captchaText" type="string" required="false" default="">
		<cfset var response = { "success": false, "errors": [], "validCaptcha": true }>
		<cfset var result = {}>
		<cfset var recent = []>
		<cfif captchaRequired()>
			<cfif not structKeyExists(session, "captchaText") or not len(session.captchaText) or not len(trim(arguments.captchaText)) or trim(arguments.captchaText) neq session.captchaText>
				<cfset response[ "validCaptcha" ] = false>
				<cfset arrayAppend(response.errors, "The letters in the picture didn't match. Please try again.")>
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
		</cfif>
		<!--- At most 5 messages an hour from one visitor's session. --->
		<cfif not structKeyExists(session, "personMessagesSent")><cfset session.personMessagesSent = []></cfif>
		<cfset recent = arrayFilter(session.personMessagesSent, function(sentAt) { return dateDiff("n", sentAt, now()) lt 60; })>
		<cfif arrayLen(recent) gte 5>
			<cfset arrayAppend(response.errors, "You've sent several messages already. Please try again later.")>
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset result = application.events.getPeople().sendMessage(arguments.person, arguments.fromName, arguments.fromEmail, arguments.message)>
		<cfset response[ "success" ] = result.success>
		<cfset response[ "errors" ] = result.errors>
		<cfif result.success>
			<cfset arrayAppend(recent, now())>
			<cfset session.personMessagesSent = recent>
			<cfif captchaRequired()><cfset structDelete(session, "captchaText")></cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="adminAddRsvp" access="remote" returnformat="json" output="false"
			hint="Adds a sign-up for someone who signed up by phone, by email or in person (2026-10-16, the sign-ups window, 100). Confirmed straight away with no payment, even after sign-ups close or when the event is full - the owner decides. Optionally emails them the usual confirmation (with the calendar file and the cancel link). Returns { success, errorMessage }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfargument name="name" type="string" required="false" default="">
		<cfargument name="email" type="string" required="false" default="">
		<cfargument name="partySize" required="false" default="1">
		<cfargument name="locationOptionId" required="false" default="0">
		<cfargument name="sendEmail" required="false" default="true">
		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var ev = {}>
		<cfset var webForm = {}>
		<cfset var values = {}>
		<cfset var field = "">
		<cfset var gotEmail = false>
		<cfset var gotName = false>
		<cfset var people = 1>
		<cfset var placeId = 0>
		<cfset var submissionId = 0>
		<cfset var rsvp = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif not application.Udf.isLoggedIn()>
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset ev = isValid("integer", arguments.postId) ? application.events.getEvent(val(arguments.postId)) : {}>
		<cfif not structIsEmpty(ev) and ev.webFormId gt 0>
			<cfset webForm = application.webForms.getForm(webFormId = ev.webFormId)>
		</cfif>
		<cfif structIsEmpty(ev)>
			<cfset response[ "errorMessage" ] = "This post isn't an event any more.">
		<cfelseif structIsEmpty(webForm)>
			<cfset response[ "errorMessage" ] = "Choose a sign-up form for the event first (the Event window, Sign-ups).">
		<cfelseif not len(trim(arguments.name))>
			<cfset response[ "errorMessage" ] = "Enter their name.">
		<cfelseif not isValid("email", trim(arguments.email))>
			<cfset response[ "errorMessage" ] = "Enter a valid email address.">
		<cfelseif application.events.isSignedUp(ev.eventId, trim(arguments.email))>
			<cfset response[ "errorMessage" ] = "That email address already has a place.">
		</cfif>
		<cfif len(response.errorMessage)>
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<!--- The name and email go into the form's own first name and email fields, as if they had filled it in. --->
		<cfloop array="#webForm.fields#" index="field">
			<cfif not gotEmail and field.fieldType eq "email">
				<cfset values[field.fieldName] = trim(arguments.email)>
				<cfset gotEmail = true>
			<cfelseif not gotName and field.fieldType eq "text" and findNoCase("name", field.label)>
				<cfset values[field.fieldName] = trim(arguments.name)>
				<cfset gotName = true>
			</cfif>
		</cfloop>
		<cfif ev.askPartySize and isValid("integer", arguments.partySize) and arguments.partySize gte 1>
			<cfset people = min(int(arguments.partySize), 99)>
		</cfif>
		<cfif arrayLen(ev.locationIds) eq 1>
			<cfset placeId = ev.locationIds[1]>
		<cfelseif isValid("integer", arguments.locationOptionId) and arrayFind(ev.locationIds, int(arguments.locationOptionId))>
			<cfset placeId = int(arguments.locationOptionId)>
		</cfif>
		<cfset submissionId = application.webForms.saveSubmission(webForm, values, val(arguments.postId), { eventId: ev.eventId, partySize: people, locationOptionId: placeId, amountTotal: 0 })>
		<cfif isBoolean(arguments.sendEmail) and arguments.sendEmail>
			<cfset rsvp = application.events.getRsvp(submissionId = submissionId)>
			<cfif not structIsEmpty(rsvp)><cfset application.events.sendRsvpEmails(rsvp, "confirmed")></cfif>
		</cfif>
		<cfset response[ "success" ] = true>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getEventSignupForm" access="remote" returnformat="json" output="false"
			hint="The blog's own event sign-up form, made the first time it's asked for (Events.cfc getSignupFormId), for the event window's Set up forms button (2026-10-16). Returns { success, webFormId, title }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfset var response = { "success": false, "webFormId": 0, "title": "" }>
		<cfset var signupForm = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn()>
			<cfset response[ "webFormId" ] = application.events.getSignupFormId()>
			<cfif response.webFormId gt 0>
				<cfset signupForm = application.webForms.getForm(webFormId = response.webFormId)>
				<cfset response[ "title" ] = structKeyExists(signupForm, "title") ? signupForm.title : "Sign up">
				<cfset response[ "success" ] = true>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getEventCardPreview" access="remote" returnformat="json" output="false"
			hint="The event card exactly as visitors see it at the top of the post (Events.cfc renderCard, the same call blogContentHtml.cfm makes), for the post editor's preview (2026-10-16). Empty when the post isn't an event.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfset var response = { "success": false, "html": "" }>
		<cfset var getPost = []>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.postId)>
			<cfset getPost = application.blog.getPostByPostId(postId = val(arguments.postId), showPages = true, showBlogPosts = true, showPendingPosts = true, showRemovedPosts = true)>
			<cfif arrayLen(getPost)>
				<cfset response[ "html" ] = application.events.renderCard(postId = val(arguments.postId), title = getPost[1]["Title"], postUrl = application.blog.makeLink(isPage = getPost[1]["IsPage"], postAlias = getPost[1]["PostAlias"], datePosted = getPost[1]["DatePosted"]), preview = true)>
				<cfset response[ "success" ] = true>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteEvent" access="remote" returnformat="json" output="false"
			hint="Takes the event off a post (admin). Refused while someone has paid for a place that hasn't been refunded - they must be cancelled and refunded first (Cancel all and refund in the sign-ups window). With checkOnly, only reports the sign-ups, so the editor can ask first.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfargument name="checkOnly" required="false" default="false">
		<cfset var response = { "success": false, "signups": 0, "paid": 0, "errorMessage": "" }>
		<cfset var theEvent = {}>
		<cfset var thisRsvp = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.postId)>
			<!--- Who is still signed up, and who has paid for their place. --->
			<cfset theEvent = application.events.getEvent(val(arguments.postId))>
			<cfif not structIsEmpty(theEvent)>
				<cfloop array="#application.events.getRsvps(theEvent.eventId)#" index="thisRsvp">
					<!--- confirmed, or held = on the payment page now; cancelled and expired don't count. --->
					<cfif listFindNoCase("confirmed,held", thisRsvp.status)>
						<cfset response[ "signups" ]++>
						<cfif val(thisRsvp.amountPaid) gt 0 and thisRsvp.paymentStatus neq "refunded">
							<cfset response[ "paid" ]++>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
			<cfif isBoolean(arguments.checkOnly) and arguments.checkOnly>
				<cfset response[ "success" ] = true>
			<cfelseif response.paid gt 0>
				<cfset response[ "errorMessage" ] = response.paid & (response.paid eq 1 ? " person has" : " people have") & " paid for a place. Cancel and refund them first (Event sign-ups, Cancel all and refund), then remove the event.">
			<cfelse>
				<cfset response[ "success" ] = application.events.deleteEvent(val(arguments.postId))>
				<cfset application.blog.flushGalaxieCache(type = "post", postId = val(arguments.postId))>
				<cfset application.events.flushListings()>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<!--- ***************************************************************************************************************
		Event RSVPs (2026-10-15). Signing up goes through submitWebForm (with eventPostId). The cancel link in the confirmation
		email (?manageRsvp=<ManageToken>, common/js/webForms.js) uses getManagedRsvp and cancelManagedRsvp - the token is the
		key, so no login. The owner's list is window 100 (admin/adminInterface/eventRsvps.cfm).
	***************************************************************************************************************** --->

	<cffunction name="getRsvpCheckoutResult" access="remote" returnformat="json" output="false"
			hint="When someone comes back from Stripe's payment page for an event (2026-10-15): whether the payment webhook has confirmed their place yet. Read only; the webhook is what confirms.">
		<cfargument name="sessionId" type="string" required="false" default="">
		<cfset var response = { "success": false, "paid": false, "title": "", "when": "", "partySize": 0, "how": "" }>
		<cfset var payment = application.payments.getPaymentBySession(trim(arguments.sessionId))>
		<cfset var rsvp = {}>
		<cfif not structIsEmpty(payment) and payment.submissionId gt 0>
			<cfset rsvp = application.events.getRsvp(submissionId = payment.submissionId)>
		</cfif>
		<cfif not structIsEmpty(rsvp) and not structIsEmpty(rsvp.ev)>
			<cfset response = {
				"success": true,
				"paid": rsvp.status eq "confirmed" and listFind("paid,partlyRefunded,refunded", payment.status) gt 0,
				"title": rsvp.title,
				"when": application.events.whenText(rsvp.ev),
				"partySize": rsvp.partySize,
				"how": structIsEmpty(rsvp.location) ? "" : rsvp.location.label
			}>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="cancelRsvpCheckout" access="remote" returnformat="json" output="false"
			hint="They came back from Stripe without paying: closes the payment page and frees the held places at once.">
		<cfargument name="token" type="string" required="false" default="">
		<cfset var response = { "success": false }>
		<cfset var rsvp = application.events.getRsvp(token = trim(arguments.token))>
		<cfset var sessionId = "">
		<cfif not structIsEmpty(rsvp) and rsvp.status eq "held">
			<cfset sessionId = application.payments.getOpenSessionForRsvp(rsvp.submissionId)>
			<cfif len(sessionId)>
				<cfset application.payments.expireCheckout(sessionId)>
				<cfset application.payments.setPaymentStatus(sessionId, "cancelled")>
			</cfif>
			<cfset application.events.expireHeldRsvp(rsvp.submissionId)>
			<cfset response[ "success" ] = true>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getManagedRsvp" access="remote" returnformat="json" output="false" hint="A sign-up, by the token in its cancel link.">
		<cfargument name="token" type="string" required="false" default="">
		<cfset var response = { "success": false }>
		<cfset var rsvp = application.events.getRsvp(token = trim(arguments.token))>
		<cfif not structIsEmpty(rsvp) and not structIsEmpty(rsvp.ev)>
			<cfset response = {
				"success": true,
				"title": rsvp.title,
				"postUrl": rsvp.postUrl,
				"when": application.events.whenText(rsvp.ev),
				"partySize": rsvp.partySize,
				"how": structIsEmpty(rsvp.location) ? "" : rsvp.location.label,
				"status": rsvp.status,
				"canCancel": rsvp.canCancel,
				"paid": rsvp.amountPaid gt 0 ? application.payments.formatMoney(rsvp.amountPaid) : "",
				"refundNote": rsvp.amountPaid gt 0 and rsvp.canCancel ? (rsvp.refundOnCancel gt 0 ? "If you cancel now, " & application.payments.formatMoney(rsvp.refundOnCancel) & " is refunded to your card." : "It's too close to the start for a refund, so cancelling now doesn't refund your payment.") : ""
			}>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="cancelManagedRsvp" access="remote" returnformat="json" output="false" hint="Cancels a sign-up from its cancel link, frees its places and tells the owner.">
		<cfargument name="token" type="string" required="false" default="">
		<cfset var response = { "success": false, "message": "" }>
		<cfset var rsvp = {}>
		<cfset var refunded = 0>
		<cfset var refund = {}>
		<cfif cgi.request_method neq "POST">
			<cfset response[ "message" ] = "Please use the button to cancel.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset rsvp = application.events.getRsvp(token = trim(arguments.token))>
		<cfif structIsEmpty(rsvp)>
			<cfset response[ "message" ] = "We couldn't find this sign-up.">
		<cfelseif rsvp.status eq "cancelled">
			<cfset response[ "success" ] = true>
		<cfelseif not rsvp.canCancel>
			<cfset response[ "message" ] = "The event has started, so this can't be cancelled any more.">
		<cfelse>
			<!--- Inside the event form's lock, like signing up, so the freed places are counted correctly. --->
			<cflock name="galaxieWebForm_#rsvp.ev.webFormId#" type="exclusive" timeout="20">
				<cfset application.events.cancelRsvp(rsvp.submissionId)>
			</cflock>
			<!--- Paid: refunded when it's early enough (the event's refund hours). A refund problem is logged; the place is still cancelled. --->
			<cfif rsvp.refundOnCancel gt 0>
				<cfset refund = application.payments.refundRsvp(rsvp.submissionId, rsvp.refundOnCancel)>
				<cfset refunded = refund.refunded>
				<cfif refunded gt 0><cfset application.events.refreshRsvpPaymentStatus(rsvp.submissionId)></cfif>
			</cfif>
			<cfset application.events.sendRsvpEmails(rsvp, "cancelledByPerson", refunded)>
			<cfset response[ "success" ] = true>
			<cfset response[ "refunded" ] = refunded gt 0 ? application.payments.formatMoney(refunded) : "">
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="adminCancelRsvp" access="remote" returnformat="json" output="false" hint="The owner cancels a sign-up (window 100); the person is told by email.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="submissionId" required="false" default="0">
		<cfargument name="refund" required="false" default="true" hint="Refund what they paid online (an organizer cancelling normally does).">
		<cfset var response = { "success": false, "refunded": 0 }>
		<cfset var rsvp = {}>
		<cfset var refunded = 0>
		<cfset var refundResult = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.submissionId)>
			<cfset rsvp = application.events.getRsvp(submissionId = val(arguments.submissionId))>
			<cfif not structIsEmpty(rsvp) and rsvp.status eq "confirmed">
				<cflock name="galaxieWebForm_#rsvp.ev.webFormId#" type="exclusive" timeout="20">
					<cfset response[ "success" ] = application.events.cancelRsvp(rsvp.submissionId)>
				</cflock>
				<cfif response.success and rsvp.amountPaid gt 0 and isBoolean(arguments.refund) and arguments.refund>
					<cfset refundResult = application.payments.refundRsvp(rsvp.submissionId)>
					<cfset refunded = refundResult.refunded>
					<cfset response[ "refunded" ] = refunded>
					<cfif refunded gt 0><cfset application.events.refreshRsvpPaymentStatus(rsvp.submissionId)></cfif>
				</cfif>
				<cfif response.success><cfset application.events.sendRsvpEmails(rsvp, "cancelledByOwner", refunded)></cfif>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="adminCancelAllRsvps" access="remote" returnformat="json" output="false"
			hint="Cancel all and refund (window 100 and the Event window, 2026-10-15): cancels every confirmed sign-up of an event, refunds what each paid online in full, and emails each person; sign-ups still on the payment page are closed too. Returns { success, cancelled, refunded (formatted), refundProblems }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfset var response = { "success": false, "cancelled": 0, "refunded": "", "refundProblems": 0 }>
		<cfset var ev = {}>
		<cfset var item = {}>
		<cfset var rsvp = {}>
		<cfset var refundResult = {}>
		<cfset var refundedTotal = 0>
		<cfset var refundedOne = 0>
		<cfset var sessionId = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.postId)>
			<!--- Each refund is a call to Stripe, so a big event takes a while. --->
			<cfsetting requesttimeout="600">
			<cfset ev = application.events.getEvent(val(arguments.postId))>
			<cfif not structIsEmpty(ev)>
				<cfloop array="#application.events.getRsvps(ev.eventId)#" index="item">
					<cfif item.status eq "confirmed">
						<cfset rsvp = application.events.getRsvp(submissionId = item.submissionId)>
						<cfset refundedOne = 0>
						<cflock name="galaxieWebForm_#ev.webFormId#" type="exclusive" timeout="20">
							<cfset application.events.cancelRsvp(item.submissionId)>
						</cflock>
						<cfif rsvp.amountPaid gt 0>
							<cfset refundResult = application.payments.refundRsvp(item.submissionId)>
							<cfset refundedOne = refundResult.refunded>
							<cfif refundedOne gt 0>
								<cfset application.events.refreshRsvpPaymentStatus(item.submissionId)>
							<cfelseif application.payments.getRsvpPaymentTotals(item.submissionId).refundable gt 0>
								<!--- Cancelled anyway; the owner can refund this one in Stripe. Logged by Payments.cfc. --->
								<cfset response[ "refundProblems" ]++>
							</cfif>
						</cfif>
						<cfset refundedTotal = refundedTotal + refundedOne>
						<cfset application.events.sendRsvpEmails(rsvp, ev.status eq "cancelled" ? "eventCancelled" : "cancelledByOwner", refundedOne)>
						<cfset response[ "cancelled" ]++>
					<cfelseif item.status eq "held" and item.paying>
						<!--- On the payment page right now: close it, so nobody pays for a place that's gone. --->
						<cfset sessionId = application.payments.getOpenSessionForRsvp(item.submissionId)>
						<cfif len(sessionId)>
							<cfset application.payments.expireCheckout(sessionId)>
							<cfset application.payments.setPaymentStatus(sessionId, "cancelled")>
						</cfif>
						<cfset application.events.expireHeldRsvp(item.submissionId)>
					</cfif>
				</cfloop>
				<cfset response[ "success" ] = true>
				<cfset response[ "refunded" ] = refundedTotal gt 0 ? application.payments.formatMoney(refundedTotal) : "">
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="exportEventRsvps" access="remote" returntype="void" output="true" hint="Downloads an event's sign-ups as a CSV file (window 100).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" default="0" required="true">
		<cfset var ev = {}>
		<cfset var fileName = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfheader statuscode="403">
			<cfcontent type="text/plain" reset="true"><cfoutput>Invalid token</cfoutput><cfabort>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif not application.Udf.isLoggedIn() or not isValid("integer", arguments.postId)>
			<cfheader statuscode="403">
			<cfcontent type="text/plain" reset="true"><cfoutput>Access denied</cfoutput><cfabort>
		</cfif>
		<cfset ev = application.events.getEvent(val(arguments.postId))>
		<cfif structIsEmpty(ev)>
			<cfheader statuscode="404">
			<cfcontent type="text/plain" reset="true"><cfoutput>That event no longer exists.</cfoutput><cfabort>
		</cfif>
		<cfset fileName = "event-" & val(arguments.postId) & "-signups-" & dateFormat(now(), "yyyy-mm-dd") & ".csv">
		<cfheader name="Content-Disposition" value="attachment; filename=#fileName#">
		<!--- The byte order mark makes Excel open the file as UTF-8. --->
		<cfcontent type="text/csv; charset=utf-8" reset="true"><cfoutput>#chr(65279)##application.events.getRsvpsCsv(ev)#</cfoutput><cfabort>
	</cffunction>

	<cffunction name="memberForBrowser" access="private" returntype="struct" output="false" hint="The member fields the visitor's own browser may see, with lower-case keys.">
		<cfargument name="member" type="struct" required="true">
		<cfreturn { "name": arguments.member.name, "email": arguments.member.email, "phone": arguments.member.phone, "timeZone": arguments.member.timeZone,
			"picture": structKeyExists(arguments.member, "memberId") ? application.members.getPicture(arguments.member.memberId) : "" }>
	</cffunction>

	<cffunction name="memberUploadPicture" access="remote" returnformat="json" output="false"
			hint="My account (2026-10-17): the signed-in member's own picture, saved to /images/photo/member/ under a random name. JPG, PNG, GIF or WebP up to 5 MB, and it has to be a real image. Replaces their old one. Returns { success, url, errorMessage }.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfargument name="memberPicture" required="false" default="" hint="The uploaded file's form field (read with cffile upload).">
		<cfset var response = { "success": false, "url": "", "errorMessage": "Please sign in again." }>
		<cfset var member = {}>
		<cfset var folder = expandPath(application.baseUrl & "/images/photo/member/")>
		<cfset var uploaded = {}>
		<cfset var tempFile = "">
		<cfset var extension = "">
		<cfset var fileName = "">
		<cfset var onWindows = findNoCase("windows", server.os.name) gt 0>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf)>
			<cfset member = application.members.getCurrentMember()>
		</cfif>
		<cfif not structIsEmpty(member)>
			<cfset response[ "errorMessage" ] = "">
			<cftry>
				<cfif not directoryExists(folder)>
					<cfset directoryCreate(folder)>
					<!--- On Linux the web server has to be able to read it (galaxieblog.org answered 403 for files Lucee made). --->
					<cfif not onWindows><cfset fileSetAccessMode(folder, "755")></cfif>
				</cfif>
				<cffile action="upload" fileField="memberPicture" destination="#getTempDirectory()#" nameConflict="makeUnique" result="uploaded">
				<cfset tempFile = uploaded.serverDirectory & "/" & uploaded.serverFile>
				<cfset extension = lCase(uploaded.serverFileExt)>
				<cfif not listFind("jpg,jpeg,png,gif,webp", extension)>
					<cfset response[ "errorMessage" ] = "Choose a JPG, PNG, GIF or WebP picture.">
				<cfelseif val(uploaded.fileSize) gt 5 * 1024 * 1024>
					<cfset response[ "errorMessage" ] = "The picture is too big; 5 MB at most.">
				<cfelseif extension neq "webp" and not isImageFile(tempFile)>
					<cfset response[ "errorMessage" ] = "That file isn't a picture.">
				<cfelse>
					<cfset fileName = "member-" & lCase(left(hash(createUUID() & rand("SHA1PRNG"), "SHA-256"), 16)) & "." & extension>
					<cffile action="move" source="#tempFile#" destination="#folder##fileName#">
					<cfif not onWindows><cfset fileSetAccessMode(folder & fileName, "644")></cfif>
					<cfset application.members.setPicture(member.memberId, application.baseUrl & "/images/photo/member/" & fileName)>
					<cfset response[ "success" ] = true>
					<cfset response[ "url" ] = application.baseUrl & "/images/photo/member/" & fileName>
				</cfif>
				<cfif fileExists(tempFile)><cfset fileDelete(tempFile)></cfif>
				<cfcatch type="any">
					<cflog file="galaxieMembers" type="error" text="A member's picture could not be uploaded: #cfcatch.message#">
					<cfset response[ "errorMessage" ] = "The picture could not be uploaded. Please try another one.">
				</cfcatch>
			</cftry>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="memberRemovePicture" access="remote" returnformat="json" output="false" hint="My account (2026-10-17): removes the signed-in member's picture; their initials show again.">
		<cfargument name="csrf" type="string" required="false" default="">
		<cfset var response = { "success": false }>
		<cfset var member = {}>
		<cfif cgi.request_method eq "POST" and application.members.checkCsrfToken(arguments.csrf)>
			<cfset member = application.members.getCurrentMember()>
			<cfif not structIsEmpty(member)>
				<cfset application.members.removePicture(member.memberId)>
				<cfset response[ "success" ] = true>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="adminRemoveMemberPicture" access="remote" returnformat="json" output="false" hint="The site owner removes a member's picture (window 98, 2026-10-17), eg. one that isn't suitable.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="memberId" required="false" default="0">
		<cfset var response = { "success": false }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.memberId) and val(arguments.memberId) gt 0>
			<cfset application.members.removePicture(val(arguments.memberId))>
			<cflog file="galaxieMembers" type="information" text="Member #val(arguments.memberId)#'s picture was removed by #getAuthUser()#.">
			<cfset response[ "success" ] = true>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>


	<cffunction name="newBookingsFeedAddress" access="remote" returnformat="json" output="false"
			hint="Makes a new secret address for the owner's bookings calendar feed (2026-10-15); the old one stops working.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfset var response = { "feedUrl": "" }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn()>
			<cfset application.bookings.newFeedKey()>
			<cfset response[ "feedUrl" ] = application.bookings.getFeedUrl()>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="startBalanceCheckout" access="remote" returnformat="json" output="false"
			hint="From the 'Pay the rest online' link in a client's email (2026-10-15): opens Stripe's payment page for what's still owed.">
		<cfargument name="token" type="string" required="false" default="">
		<cfset var response = { "success": false, "checkoutUrl": "", "message": "" }>
		<cfset var b = {}>
		<cfset var checkout = "">
		<cfif reFind("^[a-f0-9]{64}$", arguments.token)>
			<cfset b = application.bookings.getBooking(manageToken = arguments.token)>
		</cfif>
		<cfif structIsEmpty(b)>
			<cfset response[ "message" ] = "We couldn't find this booking. Please use the link in your most recent email.">
		<cfelseif b.balanceDue lte 0 or b.paymentStatus eq "paid">
			<cfset response[ "message" ] = "Thank you - this booking is already paid in full.">
		<cfelseif not application.bookings.canPayBalanceOnline(b)>
			<cfset response[ "message" ] = "This booking can't be paid online. Please pay at your session.">
		<cfelse>
			<cfset checkout = application.payments.createBookingCheckout(
				bookingId = b.bookingId,
				purpose = "balance",
				itemName = b.bookingType.name & " (the rest)",
				itemDescription = application.bookings.formatInZone(b.startUtc, b.timeZone),
				amount = b.balanceDue,
				currencyCode = len(b.currency) ? b.currency : application.payments.getCurrency(),
				email = b.email,
				successUrl = application.blogHostUrl & "/?bookingCheckout={CHECKOUT_SESSION_ID}",
				cancelUrl = application.blogHostUrl & "/?manageBooking=" & b.manageToken,
				expiresInMinutes = 1440
			)>
			<cfset response[ "success" ] = checkout.success>
			<cfset response[ "checkoutUrl" ] = checkout.url>
			<cfset response[ "message" ] = checkout.message>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="markBookingBalancePaid" access="remote" returnformat="json" output="false"
			hint="The owner records that what was left was paid at the session (window 95) (2026-10-15).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="bookingId" default="0" required="true">
		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.bookingId)>
			<cfset response[ "success" ] = application.bookings.applyBalancePayment(val(arguments.bookingId))>
			<cfif not response.success><cfset response[ "errorMessage" ] = "Nothing is owed on this booking."></cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="refundBookingPayment" access="remote" returnformat="json" output="false"
			hint="The owner refunds a booking's online payment, all or part, from the booking window (95) (2026-10-15).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="bookingId" default="0" required="true">
		<cfargument name="amount" default="0" required="false">
		<cfset var response = { "success": false, "errorMessage": "", "refunded": 0 }>
		<cfset var refund = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.bookingId) and isNumeric(arguments.amount)>
			<cfset refund = application.payments.refundBooking(val(arguments.bookingId), val(arguments.amount))>
			<cfif refund.success>
				<cfset application.bookings.refreshPaymentStatus(val(arguments.bookingId))>
			</cfif>
			<cfset response[ "success" ] = refund.success>
			<cfset response[ "refunded" ] = refund.refunded>
			<cfset response[ "errorMessage" ] = refund.message>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getBookingCheckoutResult" access="remote" returnformat="json" output="false"
			hint="When a visitor comes back from Stripe's payment page (2026-10-15): whether the payment webhook has confirmed their booking yet. Read only; the webhook is what confirms.">
		<cfargument name="sessionId" type="string" required="false" default="">
		<cfset var response = { "success": false, "paid": false, "purpose": "", "status": "", "typeName": "", "startUtc": "", "locationLabel": "", "detailsHtml": "" }>
		<cfset var payment = application.payments.getPaymentBySession(trim(arguments.sessionId))>
		<cfset var b = {}>
		<cfif not structIsEmpty(payment) and payment.bookingId gt 0>
			<cfset b = application.bookings.getBooking(bookingId = payment.bookingId)>
		</cfif>
		<cfif not structIsEmpty(b)>
			<cfset response[ "success" ] = true>
			<cfset response[ "status" ] = b.status>
			<!--- This payment, not the booking: the booking already shows the deposit as paid while the rest is on its way. --->
			<cfset response[ "paid" ] = listFind("paid,partlyRefunded,refunded", application.payments.getPaymentBySession(trim(arguments.sessionId)).status) gt 0>
			<cfset response[ "purpose" ] = payment.purpose>
			<cfset response[ "typeName" ] = structIsEmpty(b.bookingType) ? "" : b.bookingType.name>
			<cfset response[ "startUtc" ] = b.startUtc>
			<cfif response.paid and not structIsEmpty(b.location)>
				<cfset response[ "locationLabel" ] = b.location.label>
				<cfset response[ "detailsHtml" ] = application.locations.getDetailsHtml(b.location)>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="cancelBookingCheckout" access="remote" returnformat="json" output="false"
			hint="The visitor came back from Stripe without paying (2026-10-15): closes the payment page and releases the held time at once.">
		<cfargument name="token" type="string" required="false" default="">
		<cfset var response = { "success": false }>
		<cfset var b = {}>
		<cfset var sessionId = "">
		<cfif reFind("^[a-f0-9]{64}$", arguments.token)>
			<cfset b = application.bookings.getBooking(manageToken = arguments.token)>
		</cfif>
		<cfif not structIsEmpty(b) and b.status eq "held">
			<cfset sessionId = application.payments.getOpenSessionForBooking(b.bookingId)>
			<cfif len(sessionId)>
				<cfset application.payments.expireCheckout(sessionId)>
				<cfset application.payments.setPaymentStatus(sessionId, "cancelled")>
			</cfif>
			<cfset application.bookings.expireHeldBooking(b.bookingId)>
			<cfset response[ "success" ] = true>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getManagedBooking" access="remote" returnformat="json" output="false"
			hint="The visitor's booking for their manage link.">
		<cfargument name="token" type="string" required="false" default="">

		<cfset var response = { "success": false }>
		<cfset var b = application.bookings.getBooking(manageToken = left(trim(arguments.token), 64))>

		<cfif not structIsEmpty(b) and not structIsEmpty(b.bookingType)>
			<cfset response = {
				"success": true,
				"typeName": b.bookingType.name,
				"alias": b.bookingType.alias,
				"durationMinutes": b.bookingType.durationMinutes,
				"locationOptionId": b.locationOptionId,
				"locationLabel": structIsEmpty(b.location) ? "" : b.location.label,
				"detailsHtml": structIsEmpty(b.location) or not listFind("confirmed,pending", b.status) ? "" : application.locations.getDetailsHtml(b.location),
				"startUtc": b.startUtc,
				"status": b.status,
				"visitorTimeZone": b.visitorTimeZone,
				"blogTimeZone": b.timeZone,
				"partySize": b.partySize,
				"canChange": application.bookings.canChange(b),
				"refundNote": ""
			}>
			<!--- What cancelling would give back (2026-10-15). --->
			<cfif b.amountPaid gt 0 and application.bookings.canChange(b)>
				<cfset local.refundNow = application.bookings.getRefundOnCancel(b)>
				<cfif local.refundNow gt 0>
					<cfset response[ "refundNote" ] = "If you cancel now, " & application.payments.formatMoney(local.refundNow, b.currency) & " will be refunded to your card.">
				<cfelseif b.bookingType.refundHours gt 0>
					<cfset response[ "refundNote" ] = "Cancelling less than " & b.bookingType.refundHours & " hours before isn't refunded automatically.">
				<cfelse>
					<cfset response[ "refundNote" ] = "Cancelling isn't refunded automatically.">
				</cfif>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="cancelManagedBooking" access="remote" returnformat="json" output="false"
			hint="Cancels the visitor's booking from their manage link, frees the time, and emails both sides.">
		<cfargument name="token" type="string" required="false" default="">

		<cfset var response = { "success": false, "message": "" }>
		<cfset var b = application.bookings.getBooking(manageToken = left(trim(arguments.token), 64))>

		<cfif structIsEmpty(b) or not application.bookings.canChange(b)>
			<cfset response[ "message" ] = "This booking can't be cancelled any more.">
		<cfelse>
			<!--- Worked out before cancelling, while the booking still counts as upcoming (2026-10-15). --->
			<cfset local.refundNow = application.bookings.getRefundOnCancel(b)>
			<cflock name="galaxieBookings_#application.BlogDbObj.getBlogId()#" type="exclusive" timeout="20">
				<cfset response[ "success" ] = application.bookings.setStatus(b.bookingId, "cancelled")>
			</cflock>
			<cfif response.success>
				<cfif local.refundNow gt 0>
					<cfset local.refund = application.payments.refundBooking(b.bookingId)>
					<cfif local.refund.success>
						<cfset application.bookings.refreshPaymentStatus(b.bookingId)>
						<cfset response[ "message" ] = application.payments.formatMoney(local.refund.refunded, b.currency) & " is being refunded to your card.">
					<cfelse>
						<cfset response[ "message" ] = "Your refund couldn't be made automatically; the owner has been told and will sort it out.">
					</cfif>
				</cfif>
				<cfset application.bookings.sendBookingEmails(b.bookingId, "cancelledByVisitor")>
				<!--- For the admin home's Up next row (5.0): the client changed a booking. --->
				<cfset application.blog.getAdminHome().noteBookingChange(b.bookingId, "cancelled")>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="rescheduleManagedBooking" access="remote" returnformat="json" output="false"
			hint="Moves the visitor's booking to another free time from their manage link, and emails both sides.">
		<cfargument name="token" type="string" required="false" default="">
		<cfargument name="startLocal" type="string" required="false" default="">

		<cfset var response = { "success": false, "message": "", "startUtc": "" }>
		<cfset var b = application.bookings.getBooking(manageToken = left(trim(arguments.token), 64))>
		<cfset var moved = "">

		<cfif structIsEmpty(b)>
			<cfset response[ "message" ] = "This booking can't be changed any more.">
		<cfelse>
			<cflock name="galaxieBookings_#application.BlogDbObj.getBlogId()#" type="exclusive" timeout="20">
				<cfset moved = application.bookings.rescheduleBooking(b.bookingId, left(trim(arguments.startLocal), 16))>
			</cflock>
			<cfset response[ "success" ] = moved.success>
			<cfset response[ "message" ] = moved.message>
			<cfif moved.success>
				<cfset response[ "startUtc" ] = application.bookings.getBooking(bookingId = b.bookingId).startUtc>
				<cfset application.bookings.sendBookingEmails(b.bookingId, "rescheduled")>
				<cfset application.blog.getAdminHome().noteBookingChange(b.bookingId, "moved")>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getManagedBookingSlots" access="remote" returnformat="json" output="false"
			hint="Free times to move the visitor's booking to (their own booking's time counts as free).">
		<cfargument name="token" type="string" required="false" default="">
		<cfargument name="fromDate" type="string" required="false" default="">
		<cfargument name="toDate" type="string" required="false" default="">

		<cfset var response = { "success": false, "slots": [] }>
		<cfset var b = application.bookings.getBooking(manageToken = left(trim(arguments.token), 64))>

		<cfif not structIsEmpty(b) and not structIsEmpty(b.bookingType) and application.bookings.canChange(b)>
			<cfset response[ "slots" ] = application.bookings.getSlots(b.bookingType, b.locationOptionId, left(trim(arguments.fromDate), 10), left(trim(arguments.toDate), 10), b.bookingId)>
			<cfset response[ "success" ] = true>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<!--- ********************************************************************************************************************
		Bookings: the owner's list (2026-10-14) - the Bookings list (window 94) and one booking (window 95).
	********************************************************************************************************************* --->

	<cffunction name="getBookingsForGrid" access="remote" returnformat="json" output="false"
			hint="The Bookings grid (window 94), Kendo or jsGrid: upcoming, past or all.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="no" default="kendo" hint="Either kendo or jsGrid">
		<cfargument name="range" required="no" default="upcoming">
		<!--- Not used for filtering (the grid filters client-side) - declared so jsGrid's field-based filter query params don't trip strict argument matching. --->
		<cfargument name="when" required="no" default="">
		<cfargument name="typeName" required="no" default="">
		<cfargument name="clientName" required="no" default="">
		<cfargument name="statusLabel" required="no" default="">

		<cfset var data = []>
		<cfset var thisBooking = "">
		<cfset var statusText = { "pending": "Waiting for approval", "confirmed": "Confirmed", "cancelled": "Cancelled", "completed": "Completed", "noShow": "No-show", "held": "Waiting for payment", "expired": "Not paid - time released" }>
		<cfset var jsonString = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfif application.serverProduct eq 'Lucee'><cfreturn "Invalid token"><cfelse><cfreturn serializeJSON("Invalid token")></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfloop array="#application.bookings.getBookingsForList(listFind('upcoming,past,all', arguments.range) ? arguments.range : 'upcoming')#" index="thisBooking">
			<cfset arrayAppend(data, [
				"BookingId": thisBooking.bookingId,
				"When": thisBooking.startLocal & " - " & right(thisBooking.endLocal, 5),
				"TypeName": thisBooking.typeName,
				"LocationLabel": thisBooking.locationLabel,
				"ClientName": thisBooking.name & (thisBooking.partySize gt 1 ? " (+" & (thisBooking.partySize - 1) & ")" : ""),
				"Email": thisBooking.email,
				"Status": thisBooking.status,
				"StatusLabel": structKeyExists(statusText, thisBooking.status) ? statusText[thisBooking.status] : thisBooking.status
			])>
		</cfloop>

		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfif arguments.gridType eq 'jsGrid'>
				<cfinvokeargument name="includeDataHandle" value="true">
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>
		<cfreturn jsonString>
	</cffunction>

	<cffunction name="getPeopleForGrid" access="remote" returnformat="json" output="false"
			hint="The Members grid (window 97, 2026-10-17), Kendo or jsGrid: everyone in the combined list (Members.cfc getPeopleForAdmin), one row per email address. Shown when there are more than 10 people.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="no" default="kendo" hint="Either kendo or jsGrid">
		<!--- Not used for filtering (the grid filters client-side) - declared so jsGrid's field-based filter query params don't trip strict argument matching. --->
		<cfargument name="name" required="no" default="">
		<cfargument name="email" required="no" default="">
		<cfargument name="labels" required="no" default="">
		<cfargument name="lastActivity" required="no" default="">
		<cfargument name="since" required="no" default="">
		<cfargument name="filters" required="no" default="">

		<cfset var data = []>
		<cfset var thisPerson = "">
		<cfset var filterKeys = "">
		<cfset var jsonString = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfif application.serverProduct eq 'Lucee'><cfreturn "Invalid token"><cfelse><cfreturn serializeJSON("Invalid token")></cfif>
		</cfif>
		<cfset secureFunction('EditUser')>

		<cfloop array="#application.members.getPeopleForAdmin()#" index="thisPerson">
			<!--- The keys the filter buttons above the grid match on (members.cfm). --->
			<cfset filterKeys = "all">
			<cfif thisPerson.isMember><cfset filterKeys = filterKeys & " member"></cfif>
			<cfif thisPerson.onSite><cfset filterKeys = filterKeys & " onsite"></cfif>
			<cfif thisPerson.isSubscriber><cfset filterKeys = filterKeys & " subscriber"></cfif>
			<cfif thisPerson.bookings><cfset filterKeys = filterKeys & " booked"></cfif>
			<cfif thisPerson.signUps><cfset filterKeys = filterKeys & " signedup"></cfif>
			<cfif thisPerson.forms><cfset filterKeys = filterKeys & " forms"></cfif>
			<cfset arrayAppend(data, [
				"Email": thisPerson.email,
				"MemberId": thisPerson.memberId,
				"Name": len(thisPerson.name) ? thisPerson.name : "(no name)",
				"Labels": arrayToList(thisPerson.labels, ", ") & (thisPerson.isUser ? (arrayLen(thisPerson.labels) ? ". " : "") & "Also a user" : ""),
				"LastActivity": len(thisPerson.lastActivityText) ? thisPerson.lastActivityText & (isDate(thisPerson.lastActivity) ? ", " & dateFormat(thisPerson.lastActivity, "mmm d, yyyy") : "") : "",
				"LastActivityDate": isDate(thisPerson.lastActivity) ? dateTimeFormat(thisPerson.lastActivity, "yyyy-mm-dd HH:nn") : "",
				"Since": isDate(thisPerson.since) ? dateFormat(thisPerson.since, "yyyy-mm") : "",
				"Filters": filterKeys
			])>
		</cfloop>

		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfif arguments.gridType eq 'jsGrid'>
				<cfinvokeargument name="includeDataHandle" value="true">
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>
		<cfreturn jsonString>
	</cffunction>

	<cffunction name="setBookingStatus" access="remote" returnformat="json" output="false"
			hint="The owner approves, cancels, or marks a booking completed or no-show (window 95). Approving and cancelling email the visitor.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="bookingId" default="0" required="true">
		<cfargument name="status" type="string" default="" required="true">
		<cfargument name="message" type="string" default="" required="false" hint="An optional note to the visitor when cancelling.">
		<cfargument name="refund" type="string" default="" required="false" hint="true: refund what was paid online when cancelling.">

		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var b = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.bookingId)>
			<cfset b = application.bookings.getBooking(bookingId = val(arguments.bookingId))>
			<cfif structIsEmpty(b)>
				<cfset response[ "errorMessage" ] = "That booking no longer exists.">
			<cfelse>
				<cflock name="galaxieBookings_#application.BlogDbObj.getBlogId()#" type="exclusive" timeout="20">
					<cfset response[ "success" ] = application.bookings.setStatus(b.bookingId, arguments.status)>
				</cflock>
				<cfif response.success and arguments.status eq "confirmed" and b.status eq "pending">
					<cfset application.bookings.sendBookingEmails(b.bookingId, "approved")>
				<cfelseif response.success and arguments.status eq "cancelled" and listFind("confirmed,pending", b.status)>
					<cfif arguments.refund eq "true">
						<cfset local.refund = application.payments.refundBooking(b.bookingId)>
						<cfif local.refund.success>
							<cfset application.bookings.refreshPaymentStatus(b.bookingId)>
						<cfelseif len(local.refund.message) and local.refund.message neq "There's nothing left to refund.">
							<cfset response[ "errorMessage" ] = "The booking is cancelled, but the refund didn't go through: " & local.refund.message>
						</cfif>
					</cfif>
					<cfset application.bookings.sendBookingEmails(b.bookingId, "cancelledByOwner", left(arguments.message, 2000))>
				</cfif>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveBookingNotes" access="remote" returnformat="json" output="false"
			hint="The owner's private notes on a booking (window 95).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="bookingId" default="0" required="true">
		<cfargument name="notes" type="string" default="" required="false">

		<cfset var response = { "success": false }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.bookingId)>
			<cfset response[ "success" ] = application.bookings.saveNotes(val(arguments.bookingId), arguments.notes)>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="forgetBookingToken" access="private" returntype="void" output="false">
		<cfargument name="token" type="string" required="true">
		<cflock scope="session" type="exclusive" timeout="10">
			<cfif structKeyExists(session, "bookingTokens") and isStruct(session.bookingTokens)>
				<cfset structDelete(session.bookingTokens, arguments.token)>
			</cfif>
		</cflock>
	</cffunction>

	<!--- ********************************************************************************************************************
		Bookings: booking types and the owner's hours (2026-10-14), managed by application.bookings (common/cfc/Bookings.cfc) from
		the Booking types window (90), the booking type editor (91) and Hours (92).
	********************************************************************************************************************* --->

	<cffunction name="getBookingTypesForGrid" access="remote" returnformat="json" output="false"
			hint="The Booking types grid (window 90), Kendo or jsGrid.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="no" default="kendo" hint="Either kendo or jsGrid">
		<!--- Not used for filtering (the grid filters client-side) - declared so jsGrid's field-based filter query params don't trip strict argument matching. --->
		<cfargument name="name" required="no" default="">
		<cfargument name="category" required="no" default="">
		<cfargument name="locations" required="no" default="">
		<cfargument name="status" required="no" default="">

		<cfset var data = []>
		<cfset var thisType = "">
		<cfset var locationNames = {}>
		<cfset var thisLocation = "">
		<cfset var names = []>
		<cfset var locationId = "">
		<cfset var jsonString = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfif application.serverProduct eq 'Lucee'><cfreturn "Invalid token"><cfelse><cfreturn serializeJSON("Invalid token")></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfloop array="#application.locations.getLocations()#" index="thisLocation">
			<cfset locationNames[thisLocation.locationOptionId] = thisLocation.label>
		</cfloop>
		<cfloop array="#application.bookings.getBookingTypes()#" index="thisType">
			<cfset names = []>
			<cfloop array="#thisType.locationIds#" index="locationId">
				<cfif structKeyExists(locationNames, locationId)><cfset arrayAppend(names, locationNames[locationId])></cfif>
			</cfloop>
			<cfset arrayAppend(data, [
				"BookingTypeId": thisType.bookingTypeId,
				"Name": thisType.name,
				"Category": thisType.category,
				"Length": thisType.durationMinutes & " min" & (thisType.bookingMode eq "group" ? " (group of " & thisType.groupSize & ")" : ""),
				"Price": thisType.price gt 0 ? application.payments.formatMoney(thisType.price) : "Free",
				"Locations": arrayToList(names, ", "),
				"SortOrder": thisType.sortOrder,
				"Status": thisType.active ? "Active" : "Not active"
			])>
		</cfloop>

		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfif arguments.gridType eq 'jsGrid'>
				<cfinvokeargument name="includeDataHandle" value="true">
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>
		<cfreturn jsonString>
	</cffunction>

	<cffunction name="saveBookingType" access="remote" returnformat="json" output="false"
			hint="Saves a booking type from the booking type editor (window 91).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="bookingTypeJson" type="string" default="{}" required="false">

		<cfset var response = { "success": false, "errorMessage": "", "bookingTypeId": 0 }>
		<cfset var typeData = "">
		<cfset var saveResult = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset typeData = deserializeJson(arguments.bookingTypeJson)>
				<cfif not isStruct(typeData)><cfset typeData = {}></cfif>
				<cfset saveResult = application.bookings.saveBookingType(typeData)>
				<cfset response[ "success" ] = saveResult.success>
				<cfset response[ "bookingTypeId" ] = saveResult.bookingTypeId>
				<cfset response[ "errorMessage" ] = arrayToList(saveResult.errors, "<br/>")>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The booking type could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteBookingType" access="remote" returnformat="json" output="false"
			hint="Deletes a booking type (Booking types window 90).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="bookingTypeId" default="0" required="true">

		<cfset var response = { "success": false, "errorMessage": "" }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.bookingTypeId)>
			<cftry>
				<cfset response[ "success" ] = application.bookings.deleteBookingType(val(arguments.bookingTypeId))>
				<cfif not response.success>
					<cfset response[ "errorMessage" ] = "That booking type no longer exists.">
				</cfif>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The booking type could not be deleted: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveBookingHours" access="remote" returnformat="json" output="false"
			hint="Saves the weekly hours of the general schedule or one location (Hours window 92).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="locationOptionId" default="0" required="false">
		<cfargument name="own" default="true" required="false">
		<cfargument name="daysJson" type="string" default="[]" required="false" hint="JSON: 7 arrays (Sunday first) of { start, end }.">

		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var days = "">
		<cfset var saveResult = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset days = deserializeJson(arguments.daysJson)>
				<cfif not isArray(days)><cfset days = []></cfif>
				<cfloop condition="arrayLen(days) lt 7"><cfset arrayAppend(days, [])></cfloop>
				<cfset saveResult = application.bookings.saveHours(isNumeric(arguments.locationOptionId) ? val(arguments.locationOptionId) : 0, isBoolean(arguments.own) and arguments.own, days)>
				<cfset response[ "success" ] = saveResult.success>
				<cfset response[ "errorMessage" ] = arrayToList(saveResult.errors, "<br/>")>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The hours could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveAvailabilityException" access="remote" returnformat="json" output="false"
			hint="Adds a day off or a day with different hours (Hours window 92).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="exceptionJson" type="string" default="{}" required="false">

		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var exceptionData = "">
		<cfset var saveResult = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset exceptionData = deserializeJson(arguments.exceptionJson)>
				<cfif not isStruct(exceptionData)><cfset exceptionData = {}></cfif>
				<cfset saveResult = application.bookings.saveException(exceptionData)>
				<cfset response[ "success" ] = saveResult.success>
				<cfset response[ "errorMessage" ] = arrayToList(saveResult.errors, "<br/>")>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The day could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteAvailabilityException" access="remote" returnformat="json" output="false"
			hint="Removes a day off or changed day (Hours window 92).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="availabilityExceptionId" default="0" required="true">

		<cfset var response = { "success": false, "errorMessage": "" }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.availabilityExceptionId)>
			<cfset response[ "success" ] = application.bookings.deleteException(val(arguments.availabilityExceptionId))>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<!--- ********************************************************************************************************************
		Forms (2026-10-13) - the admin site's Forms windows (83 the list, 84 the editor, 85 the submissions). The work is done by
		application.webForms (common/cfc/WebForms.cfc). Forms collect visitors' personal details, so these need the same
		capability as Blog Settings (EditServerSetting).
	********************************************************************************************************************* --->

	<cffunction name="getWebFormsForGrid" access="remote" returnformat="json" output="false"
			hint="The Forms grid (window 83), Kendo or jsGrid - same shape convention as getPageCollectionsForGrid.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="no" default="kendo" hint="Either kendo or jsGrid">
		<!--- Not used for filtering (the grid filters client-side) - declared so jsGrid's field-based filter query params don't trip strict argument matching. --->
		<cfargument name="title" required="no" default="">
		<cfargument name="alias" required="no" default="">
		<cfargument name="status" required="no" default="">

		<cfset var data = []>
		<cfset var thisForm = "">
		<cfset var jsonString = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfif application.serverProduct eq 'Lucee'><cfreturn "Invalid token"><cfelse><cfreturn serializeJSON("Invalid token")></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfloop array="#application.webForms.getForms()#" index="thisForm">
			<cfset arrayAppend(data, [
				"WebFormId": thisForm.webFormId,
				"Title": thisForm.title,
				"Alias": thisForm.alias,
				"FieldCount": thisForm.fieldCount,
				"SubmissionCount": thisForm.submissionCount,
				"LastSubmission": isDate(thisForm.lastSubmission) ? dateTimeFormat(thisForm.lastSubmission, "yyyy-mm-dd'T'HH:nn:ss") : "",
				"Status": thisForm.active ? "Active" : "Not active"
			])>
		</cfloop>

		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfif arguments.gridType eq 'jsGrid'>
				<cfinvokeargument name="includeDataHandle" value="true">
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>
		<cfreturn jsonString>
	</cffunction>

	<cffunction name="getWebFormSubmissionsForGrid" access="remote" returnformat="json" output="false"
			hint="The Form Submissions grid (window 85), Kendo or jsGrid. ValuesHtml holds every value under its field label, already HTML-encoded here, in the form's field order.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="no" default="kendo" hint="Either kendo or jsGrid">
		<cfargument name="webFormId" required="no" default="0">
		<cfargument name="name" required="no" default="">
		<cfargument name="email" required="no" default="">
		<cfargument name="valuesText" required="no" default="">

		<cfset var data = []>
		<cfset var webForm = "">
		<cfset var labels = {}>
		<cfset var thisField = "">
		<cfset var thisSubmission = "">
		<cfset var keys = []>
		<cfset var key = "">
		<cfset var html = "">
		<cfset var text = "">
		<cfset var jsonString = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfif application.serverProduct eq 'Lucee'><cfreturn "Invalid token"><cfelse><cfreturn serializeJSON("Invalid token")></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfset webForm = isNumeric(arguments.webFormId) ? application.webForms.getForm(webFormId = val(arguments.webFormId)) : {}>
		<cfif not structIsEmpty(webForm)>
			<cfloop array="#webForm.fields#" index="thisField">
				<cfset labels[thisField.fieldName] = thisField.label>
			</cfloop>
			<cfloop array="#application.webForms.getSubmissions(val(arguments.webFormId))#" index="thisSubmission">
				<!--- The form's own field order first, then the keys of fields that were removed since. --->
				<cfset keys = []>
				<cfloop array="#webForm.fields#" index="thisField">
					<cfif structKeyExists(thisSubmission.values, thisField.fieldName)><cfset arrayAppend(keys, thisField.fieldName)></cfif>
				</cfloop>
				<cfloop collection="#thisSubmission.values#" item="key">
					<cfif not structKeyExists(labels, key)><cfset arrayAppend(keys, key)></cfif>
				</cfloop>
				<cfset html = "">
				<cfset text = "">
				<cfloop array="#keys#" index="key">
					<cfset html = html & "<div><b>" & encodeForHtml(structKeyExists(labels, key) ? labels[key] : key) & ":</b> " & replaceNoCase(encodeForHtml(thisSubmission.values[key]), "&##xa;", "<br/>", "all") & "</div>">
					<cfset text = text & (structKeyExists(labels, key) ? labels[key] : key) & ": " & thisSubmission.values[key] & " ">
				</cfloop>
				<cfset arrayAppend(data, [
					"WebFormSubmissionId": thisSubmission.webFormSubmissionId,
					"Sent": dateTimeFormat(thisSubmission.created, "yyyy-mm-dd'T'HH:nn:ss"),
					"Name": thisSubmission.name,
					"Email": thisSubmission.email,
					"ValuesHtml": html,
					"ValuesText": text,
					"Hidden": thisSubmission.status eq "hidden"
				])>
			</cfloop>
		</cfif>

		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfif arguments.gridType eq 'jsGrid'>
				<cfinvokeargument name="includeDataHandle" value="true">
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>
		<cfreturn jsonString>
	</cffunction>

	<cffunction name="saveWebForm" access="remote" returnformat="json" output="false"
			hint="Saves a form and its fields from the form editor (window 84).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="formJson" type="string" default="{}" required="false" hint="JSON: webFormId, title, description, buttonLabel, confirmationMessage, confirmationUrl, notifyEmails, offerSubscribe, requireCaptcha, active, fields[].">

		<cfset var response = { "success": false, "errorMessage": "", "webFormId": 0 }>
		<cfset var formData = "">
		<cfset var saveResult = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset formData = deserializeJson(arguments.formJson)>
				<cfif not isStruct(formData)>
					<cfset formData = {}>
				</cfif>
				<cfset saveResult = application.webForms.saveForm(formData)>
				<!--- The posts the form joined or left under "Show on" have cached pages without (or with) it. --->
				<cfif saveResult.success>
					<cfset flushWebFormPosts(saveResult.changedPostIds)>
					<!--- And the event posts that use it for sign-ups: their cached card shows Sign up only while the form is active (2026-10-19). --->
					<cfset application.events.flushEventPosts(application.events.getPostIdsForForm(val(saveResult.webFormId)))>
				</cfif>
				<cfset response[ "success" ] = saveResult.success>
				<cfset response[ "webFormId" ] = saveResult.webFormId>
				<cfset response[ "errorMessage" ] = arrayToList(saveResult.errors, "<br/>")>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The form could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteWebForm" access="remote" returnformat="json" output="false"
			hint="Deletes a form, its fields and all of its submissions (Forms window 83).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="webFormId" default="0" required="true">

		<cfset var response = { "success": false, "errorMessage": "" }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.webFormId)>
			<cftry>
				<cfset local.shownOn = application.webForms.getShowOnPosts(val(arguments.webFormId))>
				<!--- And the event posts using it for sign-ups (2026-10-19), found before it goes. --->
				<cfset local.eventPosts = application.events.getPostIdsForForm(val(arguments.webFormId))>
				<cfset response[ "success" ] = application.webForms.deleteForm(val(arguments.webFormId))>
				<cfif not response.success>
					<cfset response[ "errorMessage" ] = "That form no longer exists.">
				<cfelse>
					<!--- The posts it was shown on have cached pages with it. --->
					<cfset local.shownOnIds = []>
					<cfloop array="#local.shownOn#" index="local.shownOnPost">
						<cfset arrayAppend(local.shownOnIds, local.shownOnPost.postId)>
					</cfloop>
					<cfset flushWebFormPosts(local.shownOnIds)>
					<cfset application.events.flushEventPosts(local.eventPosts)>
				</cfif>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The form could not be deleted: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteWebFormSubmission" access="remote" returnformat="json" output="false"
			hint="Permanently deletes one submission (Submissions window 85).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="webFormSubmissionId" default="0" required="true">

		<cfset var response = { "success": false, "errorMessage": "" }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.webFormSubmissionId)>
			<cftry>
				<cfset response[ "success" ] = application.webForms.deleteSubmission(val(arguments.webFormSubmissionId))>
				<cfif not response.success>
					<cfset response[ "errorMessage" ] = "That submission no longer exists.">
				</cfif>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The submission could not be deleted: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="setWebFormSubmissionHidden" access="remote" returnformat="json" output="false"
			hint="Hides a submission from the form's public sign-up list, or shows it again (Submissions window 85). It keeps its spot under the choice limits.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="webFormSubmissionId" default="0" required="true">
		<cfargument name="hidden" default="true" required="false">

		<cfset var response = { "success": false, "errorMessage": "" }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.webFormSubmissionId)>
			<cftry>
				<cfset response[ "success" ] = application.webForms.setSubmissionHidden(val(arguments.webFormSubmissionId), isBoolean(arguments.hidden) and arguments.hidden)>
				<cfif not response.success>
					<cfset response[ "errorMessage" ] = "That submission no longer exists.">
				</cfif>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The submission could not be changed: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="createPageForWebForm" access="remote" returnformat="json" output="false"
			hint="Creates a draft page with the given title from the form editor's 'Show on' list (window 84), when the page the owner wants the form on doesn't exist yet. The owner fills it in and releases it under Pages.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="title" type="string" default="" required="true">

		<cfset var response = { "success": false, "errorMessage": "", "postId": 0, "title": "" }>
		<cfset var pageTitle = left(trim(arguments.title), 125)>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<!--- Building forms needs EditServerSetting; making the page also needs the right to write posts. --->
		<cfset secureFunction('EditServerSetting')>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cfif not len(pageTitle)>
				<cfset response[ "errorMessage" ] = "Type the page's title first.">
			<cfelseif len(application.blog.getPostTitle(pageTitle))>
				<cfset response[ "errorMessage" ] = "A post or page with that title already exists. Choose it from the list instead.">
			<cfelse>
				<cftry>
					<!--- A new post is a draft (not released) until the owner releases it, so nobody sees an empty page. --->
					<cfset response[ "postId" ] = application.blog.insertNewPost(
						postType = "page",
						author = application.blog.getUserIdByUserName(session.userName),
						title = pageTitle,
						description = pageTitle)>
					<cfset response[ "title" ] = pageTitle>
					<cfset response[ "success" ] = true>
					<cfcatch type="any">
						<cfset response[ "errorMessage" ] = "The page could not be created: " & cfcatch.message>
					</cfcatch>
				</cftry>
			</cfif>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<!--- Scenes (2026-10-19, Galaxie 5): the Scenes window (106) and the Scene editor (107). The work is done by
	application.blog.getScenes() (common/cfc/Scenes.cfc). --->
	<cffunction name="saveScene" access="remote" returnformat="json" output="false"
			hint="Saves a scene from the Scene editor (window 107), then clears the cached pages of the posts that show it.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="sceneId" default="0" required="false" hint="0 for a new scene.">
		<cfargument name="alias" type="string" default="" required="false" hint="What posts use to show the scene. Only used for a new scene; an existing scene keeps its alias.">
		<cfargument name="active" default="true" required="false">
		<cfargument name="sceneJson" type="string" default="{}" required="false" hint="The scene in the engine's own shape: { name, pageColour, settings, sections: [...] }.">

		<cfset var response = { "success": false, "errorMessage": "", "sceneId": 0 }>
		<cfset var scenes = "">
		<cfset var existing = {}>
		<cfset var sceneAlias = trim(arguments.alias)>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset scenes = application.blog.getScenes()>
				<cfif val(arguments.sceneId) gt 0>
					<cfset existing = scenes.getScene(val(arguments.sceneId))>
					<cfif structIsEmpty(existing)>
						<cfthrow type="GalaxieBlog.Scenes" message="This scene no longer exists.">
					</cfif>
					<cfset sceneAlias = existing.alias>
				<cfelseif not reFind("^[A-Za-z0-9_-]{1,80}$", sceneAlias)>
					<cfthrow type="GalaxieBlog.Scenes" message="The name used in posts can only have letters, numbers, dashes and underscores.">
				<cfelseif scenes.aliasExists(sceneAlias)>
					<cfthrow type="GalaxieBlog.Scenes" message="Another scene already uses the name '#sceneAlias#' in posts. Pick another one.">
				</cfif>
				<cfset response[ "sceneId" ] = scenes.saveScene(sceneAlias, arguments.sceneJson, isBoolean(arguments.active) and arguments.active)>
				<cfset flushWebFormPosts(scenes.getPostIdsUsing(sceneAlias))>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The scene could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="uploadSceneImage" access="remote" returnformat="json" output="false"
			hint="A picture uploaded from the Scene editor (window 107). Returns location and phoneLocation (with {baseUrl} in front, as scenes store them).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<!--- The uploaded file's form field. Declared so strict argument checking accepts it; cffile reads it from the form. --->
		<cfargument name="file" required="false" default="">

		<cfset var response = { "success": false, "errorMessage": "", "location": "", "phoneLocation": "" }>
		<cfset var saved = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset saved = application.blog.getScenes().saveUploadedImage("file")>
				<cfset response[ "location" ] = saved.location>
				<cfset response[ "phoneLocation" ] = saved.phoneLocation>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.type eq "GalaxieBlog.Scenes" ? cfcatch.message : "The picture could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getHeroSummary" access="remote" returnformat="json" output="false"
			hint="The line under the post editor's Hero button (2026-10-20): the post's scene and hero text, eg. 'Scene: Delicate Arch'. Empty when it has neither.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" default="0" required="true">
		<cfset var response = { "success": false, "summary": "" }>
		<cfset var sceneAlias = "">
		<cfset var sceneList = "">
		<cfset var sceneName = "">
		<cfset var heroPost = []>
		<cfset var heroText = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.postId)>
			<cftry>
				<cfset sceneAlias = application.blog.getScenes().getPostScene(val(arguments.postId))>
				<cfif len(sceneAlias)>
					<cfset sceneList = application.blog.getScenes().listScenes()>
					<cfloop query="sceneList"><cfif sceneList.Alias eq sceneAlias><cfset sceneName = sceneList.Name></cfif></cfloop>
				</cfif>
				<cfset heroPost = application.blog.getPostByPostId(val(arguments.postId), true, true)>
				<cfif arrayLen(heroPost) and structKeyExists(heroPost[1], "HeroOverlayText") and not isNull(heroPost[1]["HeroOverlayText"])>
					<cfset heroText = trim(reReplace(toString(heroPost[1]["HeroOverlayText"]), "<[^>]*>", "", "all"))>
				</cfif>
				<cfif len(sceneAlias)>
					<cfset response[ "summary" ] = "Scene: " & (len(sceneName) ? sceneName : sceneAlias)>
				<cfelseif len(heroText)>
					<cfset response[ "summary" ] = "Hero text: " & left(heroText, 60) & (len(heroText) gt 60 ? "..." : "")>
				</cfif>
				<cfset response[ "success" ] = true>
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="setPostScene" access="remote" returnformat="json" output="false"
			hint="Shows a scene at the top of a post, or none (an empty alias), from the post's Scene window (108). Changes only the scene line of the post's header, then clears the post's cached page.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" default="0" required="true">
		<cfargument name="alias" type="string" default="" required="false">

		<cfset var response = { "success": false, "errorMessage": "" }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.postId)>
			<cftry>
				<cfset application.blog.getScenes().setPostScene(val(arguments.postId), arguments.alias)>
				<cfset flushWebFormPosts([val(arguments.postId)])>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.type eq "GalaxieBlog.Scenes" ? cfcatch.message : "The scene could not be set: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveSetup" access="remote" returnformat="json" output="false"
			hint="The Site Setup wizard (admin/setup.cfm, 5.0): saves one screen - step = site, testEmail, look, logo, about, home, starter or finish - through common/cfc/Setup.cfc. Only for someone who may change the blog's settings (EditServerSetting).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="step" type="string" default="" required="true">
		<cfargument name="title" type="string" default="" required="false">
		<cfargument name="description" type="string" default="" required="false">
		<cfargument name="email" type="string" default="" required="false">
		<cfargument name="timeZone" type="string" default="" required="false">
		<cfargument name="themeAlias" type="string" default="" required="false">
		<cfargument name="logo" type="string" default="" required="false">
		<cfargument name="social" type="string" default="" required="false">
		<cfargument name="hasName" type="string" default="true" required="false">
		<cfargument name="firstName" type="string" default="" required="false">
		<cfargument name="lastName" type="string" default="" required="false">
		<cfargument name="biography" type="string" default="" required="false">
		<cfargument name="aboutSite" type="string" default="" required="false">
		<cfargument name="facebookUrl" type="string" default="" required="false">
		<cfargument name="linkedInUrl" type="string" default="" required="false">
		<cfargument name="instagramUrl" type="string" default="" required="false">
		<cfargument name="twitterUrl" type="string" default="" required="false">
		<cfargument name="layout" type="string" default="" required="false">
		<cfargument name="heroStyle" type="string" default="classic" required="false">
		<cfargument name="welcomePost" type="string" default="false" required="false">
		<cfargument name="aboutPage" type="string" default="false" required="false">
		<cfargument name="contactForm" type="string" default="false" required="false">
		<cfargument name="footer" type="string" default="" required="false" hint="Site Setup's footer: simple, blurb or none (2026-10-20).">
		<cfargument name="photo" type="string" default="" required="false" hint="A new profile photo as a data URL.">
		<cfargument name="footerMode" type="string" default="same" required="false" hint="The footer logo: same, upload or none (2026-10-21).">
		<cfargument name="footerLogo" type="string" default="" required="false" hint="An uploaded footer logo as a data URL.">

		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var setup = "">
		<cfset var result = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>

		<cfif application.Udf.isLoggedIn()>
			<cfset setup = application.blog.getSetup()>
			<cftry>
				<cfswitch expression="#arguments.step#">
					<cfcase value="site"><cfset setup.saveSite(arguments.title, arguments.description, arguments.email, arguments.timeZone)></cfcase>
					<cfcase value="testEmail"><cfset setup.sendTestEmail(arguments.email)></cfcase>
					<cfcase value="look"><cfset setup.saveLook(arguments.themeAlias)></cfcase>
					<cfcase value="logo">
						<cfset result = setup.saveLogo(arguments.logo, arguments.social, isBoolean(arguments.hasName) and arguments.hasName, arguments.footerMode, arguments.footerLogo)>
						<cfset response[ "logo" ] = result.logo>
					</cfcase>
					<cfcase value="about">
						<cfset setup.saveAbout(arguments.firstName, arguments.lastName, arguments.biography, arguments.aboutSite,
							arguments.facebookUrl, arguments.linkedInUrl, arguments.instagramUrl, arguments.twitterUrl, arguments.photo)>
					</cfcase>
					<cfcase value="home"><cfset setup.saveHome(arguments.layout, arguments.heroStyle, arguments.footer)></cfcase>
					<cfcase value="starter">
						<cfset setup.saveStarter(isBoolean(arguments.welcomePost) and arguments.welcomePost, isBoolean(arguments.aboutPage) and arguments.aboutPage, isBoolean(arguments.contactForm) and arguments.contactForm)>
						<!--- Their ids and addresses, for the next screen's previews and the Done screen's Edit links (2026-10-20). --->
						<cfset local.starterLinks = setup.starterLinks()>
						<cfset response[ "welcomePostId" ] = local.starterLinks.welcomePostId><cfset response[ "welcomeUrl" ] = local.starterLinks.welcomeUrl>
						<cfset response[ "aboutPageId" ] = local.starterLinks.aboutPageId><cfset response[ "aboutUrl" ] = local.starterLinks.aboutUrl>
					</cfcase>
					<cfcase value="finish"><cfset setup.finish()></cfcase>
					<cfdefaultcase><cfthrow type="GalaxieBlog.Setup" message="Unknown setup step."></cfdefaultcase>
				</cfswitch>
				<cfset response[ "success" ] = true>
				<cfset response[ "stepsDone" ] = application.BlogOptionDbObj.getSetupStepsDone() ?: "">
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.type eq "GalaxieBlog.Setup" ? cfcatch.message : "This step could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveThemeEditor" access="remote" returnformat="json" output="false"
			hint="The Themes window (110, admin/adminInterface/themeEditor.cfm, 5.0) - through common/cfc/ThemeEditor.cfc. action = use (the theme in use; themeId 0 for none), look (save a theme's look), draft (the look being edited, for the preview), picture (upload a theme picture), brand (the site's logo, mobile logo, social or footer picture, in every theme), shown (show or hide a window, pod, the menu or the footer) or code (the site's custom code). Only for someone who may edit themes (EditTheme).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="action" type="string" default="" required="true">
		<cfargument name="themeId" type="string" default="0" required="false">
		<cfargument name="look" type="string" default="{}" required="false" hint="The look as JSON, keyed like blog.cfc getTheme().">
		<cfargument name="field" type="string" default="" required="false" hint="picture: the theme picture's name, such as BlogBackgroundImage.">
		<cfargument name="kind" type="string" default="" required="false" hint="brand: logo, logoMobile, social or footer.">
		<cfargument name="dataUrl" type="string" default="" required="false" hint="picture and brand: the picture as a data URL. Empty clears a brand picture.">
		<cfargument name="name" type="string" default="" required="false" hint="shown: the content template's name.">
		<cfargument name="shown" type="string" default="true" required="false">
		<cfargument name="head" type="string" default="" required="false">
		<cfargument name="tail" type="string" default="" required="false">
		<cfargument name="favicon" type="string" default="" required="false">

		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var editor = "">
		<cfset var lookStruct = {}>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditTheme')>

		<cfif application.Udf.isLoggedIn()>
			<cfset editor = application.blog.getThemeEditor()>
			<cftry>
				<cfif listFind("look,draft", arguments.action)>
					<cfset lookStruct = isJSON(arguments.look) ? deserializeJSON(arguments.look) : {}>
					<cfif not isStruct(lookStruct)><cfset lookStruct = {}></cfif>
				</cfif>
				<cfswitch expression="#arguments.action#">
					<cfcase value="use"><cfset editor.useTheme(val(arguments.themeId))></cfcase>
					<cfcase value="look"><cfset editor.saveLook(val(arguments.themeId), lookStruct)></cfcase>
					<cfcase value="draft"><cfset editor.saveDraft(val(arguments.themeId), lookStruct)></cfcase>
					<cfcase value="picture"><cfset response[ "path" ] = editor.saveThemePicture(arguments.field, arguments.dataUrl)></cfcase>
					<cfcase value="brand"><cfset response[ "url" ] = editor.saveBrandPicture(arguments.kind, arguments.dataUrl)></cfcase>
					<cfcase value="shown"><cfset editor.setContentShown(arguments.name, isBoolean(arguments.shown) and arguments.shown)></cfcase>
					<cfcase value="code"><cfset editor.saveCustomCode(arguments.head, arguments.tail, arguments.favicon)></cfcase>
					<cfdefaultcase><cfthrow type="GalaxieBlog.ThemeEditor" message="Unknown action."></cfdefaultcase>
				</cfswitch>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.type eq "GalaxieBlog.ThemeEditor" ? cfcatch.message : "This could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="savePostHeroText" access="remote" returnformat="json" output="false"
			hint="The text over a post's image, gradient or animated hero, from the Hero text window (109, 2026-10-19, Galaxie 5). Anything out of range is dropped rather than refused: an unknown color or shadow becomes empty (the default), a size is kept between 12 and 120 px.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" default="0" required="true">
		<cfargument name="heading" type="string" default="" required="false">
		<cfargument name="subText" type="string" default="" required="false">
		<cfargument name="colour" type="string" default="" required="false">
		<cfargument name="font" type="string" default="" required="false">
		<cfargument name="size" type="string" default="" required="false">
		<cfargument name="sizePhone" type="string" default="" required="false">
		<cfargument name="shadow" type="string" default="" required="false">
		<cfargument name="shadowColour" type="string" default="" required="false">
		<cfargument name="glowColour" type="string" default="" required="false" hint="Empty for no glow.">
		<cfargument name="glowOpacity" type="string" default="" required="false" hint="10 to 100 (percent).">
		<cfargument name="glowSoftness" type="string" default="" required="false" hint="4 to 60 (px).">
		<cfargument name="heroStyle" type="string" default="" required="false" hint="classic, held, band or magazine; empty for the blog's choice.">

		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var heroText = {}>
		<cfset var colourPattern = "^##[0-9A-Fa-f]{3,8}$">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.postId)>
			<cfset heroText = {
				heading = left(trim(arguments.heading), 500),
				subText = left(trim(arguments.subText), 500),
				colour = reFind(colourPattern, arguments.colour) ? arguments.colour : "",
				font = left(trim(arguments.font), 100),
				size = isNumeric(arguments.size) ? toString(min(max(int(arguments.size), 12), 120)) : "",
				sizePhone = isNumeric(arguments.sizePhone) ? toString(min(max(int(arguments.sizePhone), 12), 120)) : "",
				shadow = listFind("none,soft,strong,glow", arguments.shadow) ? arguments.shadow : "",
				shadowColour = reFind(colourPattern, arguments.shadowColour) ? arguments.shadowColour : "",
				glowColour = reFind(colourPattern, arguments.glowColour) ? arguments.glowColour : "",
				glowOpacity = isNumeric(arguments.glowOpacity) ? toString(min(max(int(arguments.glowOpacity), 10), 100)) : "",
				glowSoftness = isNumeric(arguments.glowSoftness) ? toString(min(max(int(arguments.glowSoftness), 4), 60)) : "",
				heroStyle = listFind("classic,held,band,magazine", arguments.heroStyle) ? arguments.heroStyle : ""
			}>
			<cftry>
				<cfset application.blog.savePostHeroText(val(arguments.postId), heroText)>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.type eq "GalaxieBlog.HeroText" ? cfcatch.message : "The hero text could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveSceneSettings" access="remote" returnformat="json" output="false"
			hint="Blog-wide scene settings from the Scenes window (106): where the animation library is loaded from ('cdn' or 'local'). Clears the cached pages of the posts that show scenes, as they carry this choice.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="librarySource" type="string" default="cdn" required="false">

		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var scenes = "">
		<cfset var list = "">
		<cfset var postIds = []>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset scenes = application.blog.getScenes()>
				<cfset scenes.setSetting("librarySource", arguments.librarySource eq "local" ? "local" : "cdn")>
				<cfset list = scenes.listScenes()>
				<cfloop query="list">
					<cfset arrayAppend(postIds, scenes.getPostIdsUsing(list.Alias), true)>
				</cfloop>
				<cfset flushWebFormPosts(postIds)>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The setting could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveSceneTemplate" access="remote" returnformat="json" output="false"
			hint="Keeps the scene open in the Scene editor (107) as one of the owner's own ready-made scenes, for the New scene gallery.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="name" type="string" default="" required="false">
		<cfargument name="description" type="string" default="" required="false">
		<cfargument name="sceneJson" type="string" default="{}" required="false">

		<cfset var response = { "success": false, "errorMessage": "", "templateId": 0 }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset response[ "templateId" ] = application.blog.getScenes().saveTemplate(arguments.name, arguments.description, arguments.sceneJson)>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = cfcatch.type eq "GalaxieBlog.Scenes" ? cfcatch.message : "The ready-made scene could not be saved: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteSceneTemplate" access="remote" returnformat="json" output="false" hint="Removes one of the owner's own ready-made scenes from the New scene gallery.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="templateId" default="0" required="true">

		<cfset var response = { "success": false, "errorMessage": "" }>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.templateId)>
			<cftry>
				<cfset application.blog.getScenes().deleteTemplate(val(arguments.templateId))>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The ready-made scene could not be removed: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteScene" access="remote" returnformat="json" output="false" hint="Deletes a scene (Scenes window 106). Posts that showed it show nothing in its place.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="sceneId" default="0" required="true">

		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var scene = {}>

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.sceneId)>
			<cftry>
				<cfset scene = application.blog.getScenes().getScene(val(arguments.sceneId))>
				<cfif not structIsEmpty(scene)>
					<cfset application.blog.getScenes().deleteScene(val(arguments.sceneId))>
					<cfset flushWebFormPosts(application.blog.getScenes().getPostIdsUsing(scene.alias))>
				</cfif>
				<cfset response[ "success" ] = true>
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "The scene could not be deleted: " & cfcatch.message>
				</cfcatch>
			</cftry>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="flushWebFormPosts" access="private" returntype="void" output="false"
			hint="Clears the cached pages of the posts a form was added to or removed from under 'Show on'.">
		<cfargument name="postIds" type="array" required="true">
		<cfset var postId = "">
		<cfset var done = {}>
		<cfloop array="#arguments.postIds#" index="postId">
			<cfif not structKeyExists(done, postId)>
				<cfset done[postId] = true>
				<cftry>
					<cfset application.blog.flushGalaxieCache(type = "post", postId = postId)>
					<cfcatch type="any">
						<!--- A cache that can't be cleared now is rebuilt when it expires; it mustn't fail the save. --->
					</cfcatch>
				</cftry>
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="exportWebFormSubmissions" access="remote" returntype="void" output="true"
			hint="Downloads a form's submissions as a CSV file (Submissions window 85).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="webFormId" default="0" required="true">

		<cfset var webForm = "">
		<cfset var fileName = "">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfheader statuscode="403">
			<cfcontent type="text/plain" reset="true"><cfoutput>Invalid token</cfoutput><cfabort>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif not application.Udf.isLoggedIn() or not isNumeric(arguments.webFormId)>
			<cfheader statuscode="403">
			<cfcontent type="text/plain" reset="true"><cfoutput>Access denied</cfoutput><cfabort>
		</cfif>

		<cfset webForm = application.webForms.getForm(webFormId = val(arguments.webFormId))>
		<cfif structIsEmpty(webForm)>
			<cfheader statuscode="404">
			<cfcontent type="text/plain" reset="true"><cfoutput>That form no longer exists.</cfoutput><cfabort>
		</cfif>
		<cfset fileName = webForm.alias & "-submissions-" & dateFormat(now(), "yyyy-mm-dd") & ".csv">
		<cfheader name="Content-Disposition" value="attachment; filename=#fileName#">
		<!--- The byte order mark makes Excel open the file as UTF-8, so accented characters show correctly. --->
		<cfcontent type="text/csv; charset=utf-8" reset="true"><cfoutput>#chr(65279)##application.webForms.getSubmissionsCsv(val(arguments.webFormId))#</cfoutput><cfabort>
	</cffunction>

	<!--- ********************************************************************************************************************
		Forms on the site (2026-10-13) - used by visitors, so no login and no admin CSRF token. Instead:
		- getWebFormForPage gives each visitor's page a one-time token kept in their session (session.webFormTokens);
		- submitWebForm accepts a token only once, and only when it is at least 3 seconds old (a person takes longer than that to
		  fill in a form, a bot usually doesn't) and at most 6 hours old;
		- a hidden field ("website") that only bots fill in: such a submission is answered as if it worked, and nothing is kept;
		- at most 10 submissions an hour from one IP address (application.webFormRateLimit);
		- the blog's captcha when the form asks for it, checked here against the session's word (same rule as comments).
		Called by common/js/webForms.js.
	********************************************************************************************************************* --->

	<cffunction name="getWebFormForPage" access="remote" returnformat="json" output="false"
			hint="The HTML of an active form, by alias, with a one-time token for sending it. For an event's RSVP (eventPostId), the form also asks how many people and how they'll attend, with the places left above it - or, when sign-ups aren't open, only says why (closed: true).">
		<cfargument name="alias" type="string" required="false" default="">
		<cfargument name="eventPostId" required="false" default="0">

		<cfset var response = { "success": false, "html": "", "token": "", "captcha": false, "message": "", "closed": false, "placesText": "", "priceText": "" }>
		<cfset var rsvpEvent = {}>
		<cfset var rsvpState = {}>
		<cfset var extraHtml = "">
		<cfset var webForm = application.webForms.getForm(alias = left(trim(arguments.alias), 100))>
		<cfset var token = "">
		<cfset var key = "">
		<cfset var showCaptcha = false>

		<!--- An RSVP: the event has to use this form. --->
		<cfif isValid("integer", arguments.eventPostId) and arguments.eventPostId gt 0 and not structIsEmpty(webForm)>
			<cfset rsvpEvent = application.events.getEvent(val(arguments.eventPostId))>
			<cfif structIsEmpty(rsvpEvent) or rsvpEvent.webFormId neq webForm.webFormId>
				<cfset webForm = {}>
			<cfelse>
				<cfset rsvpState = application.events.getRsvpState(rsvpEvent)>
				<cfset response[ "placesText" ] = application.events.placesText(rsvpState)>
				<cfset response[ "priceText" ] = rsvpState.priceText>
			</cfif>
		</cfif>
		<cfif structIsEmpty(webForm) or not webForm.active>
			<cfset response[ "message" ] = "This form is not available.">
		<cfelseif not structIsEmpty(rsvpState) and not rsvpState.open>
			<cfset response[ "success" ] = true>
			<cfset response[ "closed" ] = true>
			<cfset response[ "message" ] = rsvpState.message>
		<cfelse>
			<cfif not structIsEmpty(rsvpState)>
				<cfset extraHtml = application.events.renderRsvpExtrasHtml(rsvpEvent, rsvpState, "webForm" & webForm.webFormId & "_")>
			</cfif>
			<cfset showCaptcha = webForm.requireCaptcha and captchaRequired()>
			<cfset token = lCase(replace(createUUID(), "-", "", "all"))>
			<cflock scope="session" type="exclusive" timeout="10">
				<cfif not structKeyExists(session, "webFormTokens") or not isStruct(session.webFormTokens)>
					<cfset session.webFormTokens = {}>
				</cfif>
				<!--- Keep the session small: drop tokens older than 6 hours, and never keep more than 20. --->
				<cfloop collection="#session.webFormTokens#" item="key">
					<cfif dateDiff("h", session.webFormTokens[key].issued, now()) gte 6>
						<cfset structDelete(session.webFormTokens, key)>
					</cfif>
				</cfloop>
				<cfif structCount(session.webFormTokens) gte 20>
					<cfset session.webFormTokens = {}>
				</cfif>
				<cfset session.webFormTokens[token] = { webFormId: webForm.webFormId, issued: now() }>
			</cflock>
			<cfset response[ "success" ] = true>
			<cfset response[ "html" ] = application.webForms.renderFormHtml(webForm, showCaptcha, application.webForms.getChoiceCounts(webForm), extraHtml)>
			<cfset response[ "token" ] = token>
			<cfset response[ "captcha" ] = showCaptcha>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getWebFormListForPage" access="remote" returnformat="json" output="false"
			hint="A form's public sign-up list for a post or page (common/js/webForms.js). Only for an active form whose list was made public; the form's private fields, such as email, are never in it.">
		<cfargument name="alias" type="string" required="false" default="">

		<cfset var response = { "success": false, "html": "" }>
		<cfset var webForm = application.webForms.getForm(alias = left(trim(arguments.alias), 100))>

		<cfif not structIsEmpty(webForm) and webForm.active and webForm.publicList>
			<cfset response[ "html" ] = application.webForms.renderPublicListHtml(webForm)>
			<cfset response[ "success" ] = true>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="submitWebForm" access="remote" returnformat="json" output="false"
			hint="Checks and stores what a visitor sent with a form, emails the blog owner, and starts the subscription when asked.">
		<cfargument name="alias" type="string" required="false" default="">
		<cfargument name="token" type="string" required="false" default="">
		<cfargument name="valuesJson" type="string" required="false" default="{}" hint="The fields' values, keyed by field name. A checkbox group's choices come comma separated.">
		<cfargument name="captchaText" type="string" required="false" default="">
		<cfargument name="website" type="string" required="false" default="" hint="The hidden field only bots fill in.">
		<cfargument name="subscribeToBlog" type="string" required="false" default="">
		<cfargument name="postId" required="false" default="0">
		<cfargument name="eventPostId" required="false" default="0" hint="An event RSVP (Events.cfc): the event's post.">
		<cfargument name="rsvpPartySize" required="false" default="1">
		<cfargument name="rsvpLocation" required="false" default="0">

		<cfset var response = { "success": false, "errors": {}, "message": "", "confirmationMessage": "", "confirmationUrl": "", "newToken": "", "placesText": "", "checkoutUrl": "" }>
		<cfset var rsvpAmount = 0>
		<cfset var checkout = {}>
		<cfset var backTo = "">
		<cfset var rsvpEvent = {}>
		<cfset var rsvpChecked = {}>
		<cfset var rsvpEmail = "">
		<cfset var rsvp = {}>
		<cfset var extraRows = []>
		<cfset var webForm = application.webForms.getForm(alias = left(trim(arguments.alias), 100))>
		<cfset var issued = "">
		<cfset var ip = cgi.remote_addr>
		<cfset var recent = []>
		<cfset var stamp = "">
		<cfset var sent = {}>
		<cfset var checked = "">
		<cfset var submissionId = 0>
		<cfset var key = "">

		<cfif structIsEmpty(webForm) or not webForm.active>
			<cfset response[ "message" ] = "This form is not available any more.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<!--- An RSVP: the event has to use this form. --->
		<cfif isValid("integer", arguments.eventPostId) and arguments.eventPostId gt 0>
			<cfset rsvpEvent = application.events.getEvent(val(arguments.eventPostId))>
			<cfif structIsEmpty(rsvpEvent) or rsvpEvent.webFormId neq webForm.webFormId>
				<cfset response[ "message" ] = "Sign-ups for this event are not available any more.">
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
		</cfif>

		<!--- The token: issued to this visitor's session for this form, at least 3 seconds ago, used once. --->
		<cflock scope="session" type="exclusive" timeout="10">
			<cfif structKeyExists(session, "webFormTokens") and isStruct(session.webFormTokens) and structKeyExists(session.webFormTokens, arguments.token) and session.webFormTokens[arguments.token].webFormId eq webForm.webFormId>
				<cfset issued = session.webFormTokens[arguments.token].issued>
			</cfif>
		</cflock>
		<cfif not isDate(issued) or dateDiff("h", issued, now()) gte 6>
			<cfset response[ "message" ] = "This page has been open for a long time, or the form was already sent. Please reload the page and try again.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfif dateDiff("s", issued, now()) lt 3>
			<cfset response[ "message" ] = "That was very quick - please check the form and send it again.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<!--- The honeypot: answer as if it worked, keep nothing. --->
		<cfif len(trim(arguments.website))>
			<cfset forgetWebFormToken(arguments.token)>
			<cfset response[ "success" ] = true>
			<cfset response[ "confirmationMessage" ] = webForm.confirmationMessage>
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<!--- At most 10 submissions an hour from one address. --->
		<cflock name="galaxieWebFormRateLimit" type="exclusive" timeout="10">
			<cfif not structKeyExists(application, "webFormRateLimit") or not isStruct(application.webFormRateLimit)>
				<cfset application.webFormRateLimit = {}>
			</cfif>
			<cfloop collection="#application.webFormRateLimit#" item="key">
				<cfset recent = []>
				<cfloop array="#application.webFormRateLimit[key]#" index="stamp">
					<cfif dateDiff("n", stamp, now()) lt 60><cfset arrayAppend(recent, stamp)></cfif>
				</cfloop>
				<cfif arrayLen(recent)><cfset application.webFormRateLimit[key] = recent><cfelse><cfset structDelete(application.webFormRateLimit, key)></cfif>
			</cfloop>
			<cfset recent = structKeyExists(application.webFormRateLimit, ip) ? application.webFormRateLimit[ip] : []>
			<cfif arrayLen(recent) gte 10>
				<cfset response[ "message" ] = "Too many forms have been sent from your connection in the last hour. Please try again later.">
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
		</cflock>

		<!--- The captcha, when the form asks for it (same rule as the comment form: not for a signed-in user). --->
		<cfif webForm.requireCaptcha and captchaRequired()>
			<cfif not structKeyExists(session, "captchaText") or not len(session.captchaText) or not len(trim(arguments.captchaText)) or trim(arguments.captchaText) neq session.captchaText>
				<cfset response[ "errors" ][ "captchaText" ] = "The text from the image did not match. Please try again.">
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
		</cfif>

		<!--- The values. --->
		<cftry>
			<cfset sent = deserializeJSON(arguments.valuesJson)>
			<cfcatch type="any"><cfset sent = {}></cfcatch>
		</cftry>
		<cfif not isStruct(sent)><cfset sent = {}></cfif>
		<!--- Checked and stored inside one lock per form, so the choice limits (WebForms.cfc) are counted and taken together: two
		people can't both get the last spot. Forms without limits don't read the submissions, so the lock costs them nothing. --->
		<cflock name="galaxieWebForm_#webForm.webFormId#" type="exclusive" timeout="20">
			<cfset checked = application.webForms.validateSubmission(webForm, sent, application.webForms.getChoiceCounts(webForm))>
			<!--- An RSVP: the person's email is needed (confirmation, cancel link, duplicates), then open, party size, how they'll attend and the places left are checked here, inside the lock, right before saving. --->
			<cfif not structIsEmpty(rsvpEvent)>
				<cfloop array="#webForm.fields#" index="key">
					<cfif key.fieldType eq "email">
						<cfset rsvpEmail = structKeyExists(checked.values, key.fieldName) ? checked.values[key.fieldName] : "">
						<cfif not isValid("email", rsvpEmail) and not structKeyExists(checked.errors, key.fieldName)>
							<cfset checked.errors[key.fieldName] = "Please enter your email address, so we can confirm your place.">
						</cfif>
						<cfbreak>
					</cfif>
				</cfloop>
				<cfset rsvpChecked = application.events.checkRsvp(rsvpEvent, rsvpEmail, arguments.rsvpPartySize, arguments.rsvpLocation)>
				<cfset structAppend(checked.errors, rsvpChecked.errors, false)>
				<cfset checked.valid = structIsEmpty(checked.errors) and rsvpChecked.valid>
			</cfif>
			<cfif checked.valid and not structIsEmpty(rsvpEvent)>
				<!--- A paid event (2026-10-15): the places are held while they pay; see Events.cfc. --->
				<cfset rsvpAmount = rsvpEvent.price gt 0 ? round(rsvpEvent.price * rsvpChecked.partySize * 100) / 100 : 0>
				<cfset submissionId = application.webForms.saveSubmission(webForm, checked.values, val(arguments.eventPostId), { eventId: rsvpEvent.eventId, partySize: rsvpChecked.partySize, locationOptionId: rsvpChecked.locationOptionId, amountTotal: rsvpAmount })>
			<cfelseif checked.valid>
				<!--- Accepted: store it, then spend the token and the captcha word, count it, and tell the owner below. --->
				<cfset submissionId = application.webForms.saveSubmission(webForm, checked.values, isNumeric(arguments.postId) ? val(arguments.postId) : 0)>
			</cfif>
		</cflock>
		<cfif not checked.valid>
			<cfset response[ "errors" ] = checked.errors>
			<cfset response[ "message" ] = structIsEmpty(checked.errors) and not structIsEmpty(rsvpChecked) and len(rsvpChecked.message) ? rsvpChecked.message : "Please check the highlighted fields.">
			<cfif not structIsEmpty(rsvpEvent)><cfset response[ "placesText" ] = application.events.placesText(application.events.getRsvpState(rsvpEvent))></cfif>
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<cfset forgetWebFormToken(arguments.token)>
		<cfif structKeyExists(session, "captchaText")><cfset structDelete(session, "captchaText")></cfif>
		<cflock name="galaxieWebFormRateLimit" type="exclusive" timeout="10">
			<cfif not structKeyExists(application.webFormRateLimit, ip)><cfset application.webFormRateLimit[ip] = []></cfif>
			<cfset arrayAppend(application.webFormRateLimit[ip], now())>
		</cflock>
		<!--- A paid RSVP: off to Stripe's payment page. Nothing is confirmed or emailed until the verified payment webhook
		(common/services/stripeWebhook.cfm) arrives; the form's own notification waits for it too. --->
		<cfif not structIsEmpty(rsvpEvent) and rsvpAmount gt 0>
			<cfset rsvp = application.events.getRsvp(submissionId = submissionId)>
			<cfset backTo = listFirst(rsvp.postUrl, "?##")>
			<cfset checkout = application.payments.createRsvpCheckout(
				submissionId = submissionId,
				itemName = rsvp.title & (rsvp.partySize gt 1 ? " (" & rsvp.partySize & " people)" : ""),
				itemDescription = application.events.whenText(rsvpEvent),
				amount = rsvpAmount,
				currencyCode = application.payments.getCurrency(),
				email = rsvp.email,
				successUrl = backTo & "?rsvpCheckout={CHECKOUT_SESSION_ID}",
				cancelUrl = backTo & "?rsvpCancelled=" & rsvp.manageToken
			)>
			<cfif not checkout.success>
				<cfset application.events.expireHeldRsvp(submissionId)>
				<cfset response[ "message" ] = checkout.message>
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
			<cfset response[ "success" ] = true>
			<cfset response[ "checkoutUrl" ] = checkout.url>
			<cfset response[ "confirmationMessage" ] = "Taking you to the secure payment page...">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>

		<!--- An RSVP: the person's confirmation, with the event, how they'll attend, the calendar file and the cancel link. --->
		<cfif not structIsEmpty(rsvpEvent)>
			<cfset rsvp = application.events.getRsvp(submissionId = submissionId)>
			<cfif not structIsEmpty(rsvp)>
				<cfset application.events.sendRsvpEmails(rsvp, "confirmed")>
				<cfset extraRows = [ { label: "Event", value: rsvp.title }, { label: "People", value: rsvp.partySize } ]>
				<cfif not structIsEmpty(rsvp.location)><cfset arrayAppend(extraRows, { label: "How", value: rsvp.location.label })></cfif>
				<cfset arrayAppend(extraRows, { label: "Places taken", value: application.events.getPlacesTaken(rsvpEvent.eventId) & (rsvpEvent.capacity gt 0 ? " of " & rsvpEvent.capacity : "") })>
			</cfif>
		</cfif>
		<cftry>
			<cfset emailWebFormSubmission(webForm, checked.values, extraRows)>
			<cfcatch type="any">
				<!--- The submission is saved; a mail problem must not make the visitor think it failed. --->
				<cflog file="galaxieBlogErrors" type="error" text="Form #webForm.alias#: the notification email could not be sent: #cfcatch.message#">
			</cfcatch>
		</cftry>

		<!--- "Email me new posts": the usual double opt-in subscription, with the form's email address. --->
		<cfif webForm.offerSubscribe and len(arguments.subscribeToBlog)>
			<cfloop array="#webForm.fields#" index="key">
				<cfif key.fieldType eq "email" and structKeyExists(checked.values, key.fieldName) and isValid("email", checked.values[key.fieldName])>
					<cftry>
						<cfset subscribe(email = checked.values[key.fieldName])>
						<cfcatch type="any">
							<cflog file="galaxieBlogErrors" type="error" text="Form #webForm.alias#: the subscription could not be started: #cfcatch.message#">
						</cfcatch>
					</cftry>
					<cfbreak>
				</cfif>
			</cfloop>
		</cfif>

		<cfset response[ "success" ] = true>
		<cfset response[ "confirmationMessage" ] = webForm.confirmationMessage>
		<cfset response[ "confirmationUrl" ] = webForm.confirmationUrl>
		<cfif not structIsEmpty(rsvp)>
			<!--- An RSVP stays on the event page and says so plainly. --->
			<cfset response[ "confirmationUrl" ] = "">
			<cfset response[ "confirmationMessage" ] = "You have a place" & (rsvp.partySize gt 1 ? " for " & rsvp.partySize & " people" : "") & ". We've emailed you a confirmation with a calendar file and a link to cancel if your plans change.">
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="forgetWebFormToken" access="private" returntype="void" output="false">
		<cfargument name="token" type="string" required="true">
		<cflock scope="session" type="exclusive" timeout="10">
			<cfif structKeyExists(session, "webFormTokens") and isStruct(session.webFormTokens)>
				<cfset structDelete(session.webFormTokens, arguments.token)>
			</cfif>
		</cflock>
	</cffunction>

	<cffunction name="emailWebFormSubmission" access="private" returntype="void" output="false"
			hint="Emails a new submission to the form's notify addresses (or the blog's own address), using the blog's branded email.">
		<cfargument name="webForm" type="struct" required="true">
		<cfargument name="values" type="struct" required="true">
		<cfargument name="extraRows" type="array" required="false" default="#[]#" hint="More [{ label, value }] rows, eg. an RSVP's event and number of people.">
		<cfset var recipients = len(arguments.webForm.notifyEmails) ? arguments.webForm.notifyEmails : application.BlogDbObj.getBlogEmail()>
		<cfset var body = "">
		<cfset var emailBody = "">
		<cfset var field = "">
		<cfset var recipient = "">
		<cfsavecontent variable="body"><cfoutput>
			<table cellpadding="5" cellspacing="5" border="0" align="left">
				<tr><td align="right" valign="top">Sent:</td><td align="left">#dateFormat(application.blog.blogNow())# #timeFormat(application.blog.blogNow())#</td></tr>
				<cfloop array="#arguments.webForm.fields#" index="field">
					<tr>
						<td align="right" valign="top">#encodeForHtml(field.label)#:</td>
						<td align="left">#replaceNoCase(encodeForHtml(structKeyExists(arguments.values, field.fieldName) ? arguments.values[field.fieldName] : ""), "&##xa;", "<br/>", "all")#</td>
					</tr>
				</cfloop>
				<cfloop array="#arguments.extraRows#" index="field">
					<tr><td align="right" valign="top">#encodeForHtml(field.label)#:</td><td align="left">#encodeForHtml(field.value)#</td></tr>
				</cfloop>
			</table>
		</cfoutput></cfsavecontent>
		<cfinvoke component="#RendererObj#" method="renderEmail" returnvariable="emailBody">
			<cfinvokeargument name="email" value="#listFirst(recipients)#">
			<cfinvokeargument name="emailTitle" value="New: #arguments.webForm.title#">
			<cfinvokeargument name="emailDesc" value="Sent with the form #arguments.webForm.title# on #application.BlogDbObj.getBlogTitle()#">
			<cfinvokeargument name="emailBody" value="#body#">
			<cfinvokeargument name="callToActionText" value="">
			<cfinvokeargument name="callToActionLink" value="">
		</cfinvoke>
		<cfloop list="#recipients#" index="recipient">
			<cfif isValid("email", trim(recipient))>
				<cfset UtilsObj.mail(to = trim(recipient), subject = "#arguments.webForm.title# - #application.BlogDbObj.getBlogTitle()#", body = emailBody)>
			</cfif>
		</cfloop>
	</cffunction>

	<cffunction name="getAndDismissPendingDissolveNotices" access="remote" returnformat="json" output="false"
			hint="Called once when the admin UI loads. Returns and dismisses any queued Page Collection dissolve notices.">
		<cfargument name="csrfToken" type="string" default="" required="true">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cfset info = application.blog.getAndDismissPendingDissolveNotices()>
		<cfelse>
			<cfset info = {hasNotice=false, message=""}>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn info>
		<cfelse>
			<cfreturn serializeJSON(info)>
		</cfif>
	</cffunction>

	<cffunction name="getPageCollectionsForGrid" access="remote" returnformat="json" output="false"
			hint="Returns a json array/object to populate the Configure Page Collections grid (Kendo or jsGrid) - same shape convention as getPostsForGrid/getCategoriesForGrid.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="gridType" required="no" default="kendo" hint="Either kendo or jsGrid">
		<!--- Not used for filtering (this grid filters client-side only) - declared purely so jsGrid's own field-based filter query params don't trip CF's strict argument matching (same issue/fix as getPostsForGrid's blogSortDate argument). --->
		<cfargument name="title" required="no" default="">
		<cfargument name="description" required="no" default="">
		<cfargument name="status" required="no" default="">
		<cfargument name="created" required="no" default="">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost,ReleasePost')>

		<cfset Data = application.blog.getPageCollectionsForGrid()>

		<cfinvoke component="#jsonArray#" method="convertHqlQuery2JsonStruct" returnvariable="jsonString">
			<cfinvokeargument name="hqlQueryObj" value="#Data#">
			<cfinvokeargument name="includeTotal" value="false">
			<cfinvokeargument name="overRideTotal" value="false">
			<cfinvokeargument name="newTotal" value="">
			<cfif arguments.gridType eq 'jsGrid'>
				<cfinvokeargument name="includeDataHandle" value="true">
				<cfinvokeargument name="dataHandleName" value="data">
			<cfelse>
				<cfinvokeargument name="includeDataHandle" value="false">
				<cfinvokeargument name="dataHandleName" value="">
			</cfif>
			<cfif application.serverProduct eq 'Lucee'>
				<cfinvokeargument name="serializeData" value="false">
			</cfif>
		</cfinvoke>

		<cfreturn jsonString>
	</cffunction>

	<cffunction name="getScheduledReleaseInfo" access="remote" returnformat="json" output="false"
			hint="Returns whether a post has a pending scheduled release, for the Schedule Release window.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" type="string" required="true">

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cfset info = application.blog.getScheduledReleaseInfo(arguments.postId)>
		<cfelse>
			<cfset info = {scheduled=false, startDate="", startTime=""}>
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfreturn info>
		<cfelse>
			<cfreturn serializeJSON(info)>
		</cfif>
	</cffunction>

	<cffunction name="scheduleRelease" access="remote" returnformat="json" output="false"
			hint="Sets a post's Date Posted to a future date/time and schedules it to release itself then, from the Schedule Release window.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" type="string" required="true">
		<cfargument name="releaseDate" type="string" required="true">
		<cfargument name="releaseTime" type="string" required="true">

		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cfset releaseDateTime = createDateTime(
					year(arguments.releaseDate), month(arguments.releaseDate), day(arguments.releaseDate),
					listFirst(arguments.releaseTime, ":"), listGetAt(arguments.releaseTime, 2, ":"), 0)>
				<cfset scheduleResult = application.blog.scheduleRelease(postId=arguments.postId, releaseDateTime=releaseDateTime)>
				<cfset response[ "success" ] = scheduleResult.success />
				<cfset response[ "errorMessage" ] = scheduleResult.errorMessage />
				<cfcatch type="any">
					<cfset response[ "errorMessage" ] = "<ul><li>" & cfcatch.message & "</li></ul>" />
				</cfcatch>
			</cftry>
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul><li>Not logged on</li></ul>" />
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
		<cfreturn thisResponse>
	</cffunction>

	<cffunction name="cancelScheduledRelease" access="remote" returnformat="json" output="false"
			hint="Cancels a post's pending scheduled release, from the Schedule Release window.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" type="string" required="true">

		<cfset response[ "success" ] = false />
		<cfset response[ "errorMessage" ] = "" />

		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'>
				<cfreturn response>
			<cfelse>
				<cfreturn serializeJSON(response)>
			</cfif>
			<cfabort>
		</cfif>

		<cfset secureFunction('AddPost,EditPost,ReleasePost')>

		<cfif application.Udf.isLoggedIn()>
			<cfset response[ "success" ] = application.blog.cancelScheduledRelease(arguments.postId) />
		<cfelse>
			<cfset response[ "errorMessage" ] = "<ul><li>Not logged on</li></ul>" />
		</cfif>

		<cfif application.serverProduct eq 'Lucee'>
			<cfset thisResponse = response />
		<cfelse>
			<cfset thisResponse = serializeJSON( response ) />
		</cfif>
		<cfreturn thisResponse>
	</cffunction>

	<cffunction name="updateDb" access="remote" output="false" returnFormat="json"
			hint="Kept for the update instructions that come from the update site. The database is now updated by the scripts in /installer/updates/, in order, using the version that is saved in the database, so the arguments are not used.">
		<cfargument name="blogVersion" required="false" default="">
		<cfargument name="csrfToken" required="true">

		<cfreturn runDatabaseUpdate(csrfToken=arguments.csrfToken)>

	</cffunction>
						
	<!--- ********************************************************************************************************************
		The shop's admin windows (2026-10-21): Products (111), a product (112), Orders (113) and an order (114). The work is
		done by application.shop (common/cfc/Shop.cfc), which checks everything again. Same capability as Forms and Bookings,
		since orders hold buyers' names, emails and addresses.
	********************************************************************************************************************* --->

	<cffunction name="saveShopSettings" access="remote" returnformat="json" output="false" hint="The shop's switches, from the Products window.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="enabled" default="false" required="false">
		<cfargument name="promotionCodes" default="false" required="false">
		<cfargument name="downloadDays" default="7" required="false">
		<cfargument name="downloadLimit" default="5" required="false">
		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn()>
			<cfset application.shop.saveSettings(isBoolean(arguments.enabled) and arguments.enabled, isBoolean(arguments.promotionCodes) and arguments.promotionCodes, arguments.downloadDays, arguments.downloadLimit)>
			<cfset response[ "success" ] = true>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveShopProduct" access="remote" returnformat="json" output="false" hint="Adds or changes a product (window 112).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="productJson" type="string" default="{}" required="false" hint="JSON: productId, name, description, imageUrl, kind, price, shippingPrice, trackStock, stock, active.">
		<cfset var response = { "success": false, "errorMessage": "", "productId": 0 }>
		<cfset var saved = "">
		<cfset var key = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn()>
			<cfif not isJSON(arguments.productJson) or not isStruct(deserializeJSON(arguments.productJson))>
				<cfset response[ "errorMessage" ] = "The product couldn't be read. Please try again.">
			<cfelse>
				<cfset saved = application.shop.saveProduct(deserializeJSON(arguments.productJson))>
				<cfset response[ "success" ] = saved.success>
				<cfset response[ "productId" ] = saved.productId>
				<cfloop collection="#saved.errors#" item="key">
					<cfset response[ "errorMessage" ] = listAppend(response.errorMessage, saved.errors[key], chr(10))>
				</cfloop>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="deleteShopProduct" access="remote" returnformat="json" output="false" hint="Deletes a product, or switches it off when it has orders.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="productId" default="0" required="false">
		<cfset var response = { "success": false, "errorMessage": "", "message": "" }>
		<cfset var result = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.productId)>
			<cfset result = application.shop.deleteProduct(val(arguments.productId))>
			<cfset response[ "success" ] = result.success>
			<cfset response[ "message" ] = result.message>
			<cfif not result.success><cfset response[ "errorMessage" ] = result.message></cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="uploadShopProductImage" access="remote" returnformat="json" output="false" hint="A product's picture (window 112), or a booking type's (window 91, folder=bookings). Returns url.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="folder" type="string" required="false" default="shop" hint="shop or bookings (2026-10-22).">
		<!--- The uploaded file's form field. Declared so strict argument checking accepts it; cffile reads it from the form. --->
		<cfargument name="file" required="false" default="">
		<cfset var response = { "success": false, "errorMessage": "", "url": "" }>
		<cfset var uploaded = "">
		<cfset var saved = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn()>
			<cftry>
				<cffile action="upload" fileField="file" destination="#getTempDirectory()#" nameConflict="makeUnique" result="uploaded">
				<cfif uploaded.fileSize gt 15 * 1024 * 1024>
					<cffile action="delete" file="#uploaded.serverDirectory#/#uploaded.serverFile#">
					<cfset response[ "errorMessage" ] = "The picture is larger than 15 MB. Please make it smaller.">
				<cfelse>
					<cfset saved = application.shop.saveProductImage(uploaded.serverDirectory & "/" & uploaded.serverFile, uploaded.clientFile, arguments.folder)>
					<cfif not saved.success and fileExists(uploaded.serverDirectory & "/" & uploaded.serverFile)>
						<cffile action="delete" file="#uploaded.serverDirectory#/#uploaded.serverFile#">
					</cfif>
					<cfset response[ "success" ] = saved.success>
					<cfset response[ "url" ] = saved.url>
					<cfset response[ "errorMessage" ] = saved.message>
				</cfif>
				<!--- The server itself refuses some files (eg. .cfm) before Shop.cfc sees them. --->
				<cfcatch type="any"><cfset response[ "errorMessage" ] = cfcatch.message contains "not accepted" ? "Please choose a picture (jpg, png, webp or gif)." : "The picture could not be saved: " & cfcatch.message></cfcatch>
			</cftry>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="uploadShopProductFile" access="remote" returnformat="json" output="false" hint="A download product's file (window 112), kept in the shop's private folder.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="productId" default="0" required="false">
		<cfargument name="file" required="false" default="">
		<cfset var response = { "success": false, "errorMessage": "", "displayName": "" }>
		<cfset var uploaded = "">
		<cfset var saved = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.productId)>
			<cftry>
				<cffile action="upload" fileField="file" destination="#getTempDirectory()#" nameConflict="makeUnique" result="uploaded">
				<cfset saved = application.shop.saveProductFile(val(arguments.productId), uploaded.serverDirectory & "/" & uploaded.serverFile, uploaded.clientFile)>
				<cfif not saved.success and fileExists(uploaded.serverDirectory & "/" & uploaded.serverFile)>
					<cffile action="delete" file="#uploaded.serverDirectory#/#uploaded.serverFile#">
				</cfif>
				<cfset response[ "success" ] = saved.success>
				<cfset response[ "displayName" ] = saved.displayName>
				<cfset response[ "errorMessage" ] = saved.message>
				<cfcatch type="any"><cfset response[ "errorMessage" ] = cfcatch.message contains "not accepted" ? "This kind of file can't be sold as a download. Zip it first." : "The file could not be saved: " & cfcatch.message></cfcatch>
			</cftry>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="markShopOrderShipped" access="remote" returnformat="json" output="false" hint="Marks a paid order as shipped (emails the buyer the first time), or back to paid.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="shopOrderId" default="0" required="false">
		<cfargument name="shipped" default="true" required="false">
		<cfset var response = { "success": false, "errorMessage": "" }>
		<cfset var result = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.shopOrderId)>
			<cfset result = application.shop.markShipped(val(arguments.shopOrderId), isBoolean(arguments.shipped) and arguments.shipped)>
			<cfset response[ "success" ] = result.success>
			<cfset response[ "errorMessage" ] = result.message>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="refundShopOrderPayment" access="remote" returnformat="json" output="false" hint="Refunds an order through Stripe: all of it (amount 0) or up to amount.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="shopOrderId" default="0" required="false">
		<cfargument name="amount" default="0" required="false">
		<cfset var response = { "success": false, "errorMessage": "", "message": "" }>
		<cfset var result = "">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif application.Udf.isLoggedIn() and isNumeric(arguments.shopOrderId) and isNumeric(arguments.amount) and arguments.amount gte 0>
			<cfset result = application.shop.refundOrder(val(arguments.shopOrderId), val(arguments.amount))>
			<cfset response[ "success" ] = result.success>
			<cfset response[ "message" ] = result.message>
			<cfif not result.success><cfset response[ "errorMessage" ] = len(result.message) ? result.message : "The refund couldn't be made."></cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="exportShopOrders" access="remote" returntype="void" output="true" hint="Downloads the paid orders as a CSV file (Orders window 113).">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfheader statuscode="403">
			<cfcontent type="text/plain" reset="true"><cfoutput>Invalid token</cfoutput><cfabort>
		</cfif>
		<cfset secureFunction('EditServerSetting')>
		<cfif not application.Udf.isLoggedIn()>
			<cfheader statuscode="403">
			<cfcontent type="text/plain" reset="true"><cfoutput>Access denied</cfoutput><cfabort>
		</cfif>
		<cfheader name="Content-Disposition" value="attachment; filename=orders-#dateFormat(now(), 'yyyy-mm-dd')#.csv">
		<!--- The byte order mark makes Excel open the file as UTF-8. --->
		<cfcontent type="text/csv; charset=utf-8" reset="true"><cfoutput>#chr(65279)##application.shop.getOrdersCsv()#</cfoutput><cfabort>
	</cffunction>

	<!--- ********************************************************************************************************************
		The shop on the site (2026-10-21) - used by visitors, so no login and no admin CSRF token. Prices, stock and totals are
		always worked out again here from the products as they are now (Shop.cfc priceCart); the cart in the visitor's browser
		only says which products and how many. Nothing is paid or confirmed from the browser: Stripe's webhook (or the blog asking
		Stripe itself) does that. See common/js/shop.js.
	********************************************************************************************************************* --->

	<cffunction name="getShopProducts" access="remote" returnformat="json" output="false" hint="The products for the product cards on a page: a comma-separated list of aliases, or * for every product.">
		<cfargument name="aliases" type="string" required="false" default="">
		<cfset var response = { "success": true, "products": [], "currency": "" }>
		<cfset var settings = application.shop.getSettings()>
		<cfset response[ "products" ] = application.shop.getProductsForPage(left(trim(arguments.aliases), 2000))>
		<cfset response[ "currency" ] = settings.currency>
		<cfset response[ "open" ] = settings.enabled and settings.paymentsReady>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="priceShopCart" access="remote" returnformat="json" output="false" hint="The visitor's cart, checked and priced: lines, shipping, tax and total, and why anything changed.">
		<cfargument name="itemsJson" type="string" required="false" default="[]" hint="JSON: [{ alias, quantity }].">
		<cfset var response = { "success": false }>
		<cfset var cart = "">
		<cfset var items = isJSON(arguments.itemsJson) ? deserializeJSON(arguments.itemsJson) : []>
		<cfif isArray(items) and arrayLen(items) lte 50>
			<cfset cart = application.shop.priceCart(items)>
			<cfset response = {
				"success": true, "lines": cart.lines, "errors": cart.errors, "needsShipping": cart.needsShipping,
				"subtotalText": cart.subtotalText, "shippingText": cart.shippingText, "taxText": cart.taxText, "taxLabel": cart.taxLabel,
				"totalText": cart.totalText, "open": application.shop.getSettings().enabled and application.shop.getSettings().paymentsReady
			}>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="startShopCheckout" access="remote" returnformat="json" output="false" hint="Makes a pending order from the visitor's cart and returns Stripe's checkout address.">
		<cfargument name="itemsJson" type="string" required="false" default="[]">
		<cfargument name="returnUrl" type="string" required="false" default="" hint="The page the visitor checks out from; they come back to it from Stripe.">
		<cfset var response = { "success": false, "checkoutUrl": "", "message": "" }>
		<cfset var items = isJSON(arguments.itemsJson) ? deserializeJSON(arguments.itemsJson) : []>
		<cfset var backTo = listFirst(trim(arguments.returnUrl), "?##")>
		<cfset var ip = cgi.remote_addr>
		<cfset var key = "">
		<cfset var stamp = "">
		<cfset var recent = []>
		<cfset var started = "">
		<cfif not isArray(items) or not arrayLen(items) or arrayLen(items) gt 50>
			<cfset response[ "message" ] = "Your cart is empty.">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<!--- At most 20 checkouts an hour from one address: each makes a pending order and a Stripe checkout. --->
		<cflock name="galaxieShopCheckoutRateLimit" type="exclusive" timeout="10">
			<cfif not structKeyExists(application, "shopCheckoutRateLimit") or not isStruct(application.shopCheckoutRateLimit)>
				<cfset application.shopCheckoutRateLimit = {}>
			</cfif>
			<cfloop collection="#application.shopCheckoutRateLimit#" item="key">
				<cfset recent = []>
				<cfloop array="#application.shopCheckoutRateLimit[key]#" index="stamp">
					<cfif dateDiff("n", stamp, now()) lt 60><cfset arrayAppend(recent, stamp)></cfif>
				</cfloop>
				<cfif arrayLen(recent)><cfset application.shopCheckoutRateLimit[key] = recent><cfelse><cfset structDelete(application.shopCheckoutRateLimit, key)></cfif>
			</cfloop>
			<cfset recent = structKeyExists(application.shopCheckoutRateLimit, ip) ? application.shopCheckoutRateLimit[ip] : []>
			<cfif arrayLen(recent) gte 20>
				<cfset response[ "message" ] = "Too many checkouts have been started from your connection in the last hour. Please try again later.">
				<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
			</cfif>
			<cfif not structKeyExists(application.shopCheckoutRateLimit, ip)><cfset application.shopCheckoutRateLimit[ip] = []></cfif>
			<cfset arrayAppend(application.shopCheckoutRateLimit[ip], now())>
		</cflock>
		<!--- Back to the same page on this blog only. --->
		<cfif not len(backTo) or left(backTo, len(application.blogHostUrl)) neq application.blogHostUrl or reFind("[\s<>""']", backTo)>
			<cfset backTo = application.blogHostUrl & "/">
		</cfif>
		<cfset started = application.shop.startCheckout(items = items, returnUrl = backTo)>
		<cfset response[ "success" ] = started.success>
		<cfset response[ "checkoutUrl" ] = started.checkoutUrl>
		<cfset response[ "message" ] = started.message>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="getShopCheckoutResult" access="remote" returnformat="json" output="false" hint="When a buyer comes back from Stripe: whether the order is paid, what they bought and their download links.">
		<cfargument name="sessionId" type="string" required="false" default="">
		<cfset var response = { "success": false, "paid": false }>
		<cfif reFind("^cs_[A-Za-z0-9_]+$", trim(arguments.sessionId))>
			<cfset response = application.shop.getCheckoutResult(trim(arguments.sessionId))>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="cancelShopCheckout" access="remote" returnformat="json" output="false" hint="The buyer came back from Stripe without paying: closes the checkout and drops the pending order.">
		<cfargument name="token" type="string" required="false" default="">
		<cfset var response = { "success": application.shop.cancelCheckout(trim(arguments.token)) }>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="saveShopPage" access="remote" returnformat="json" output="false"
			hint="Makes a page a shop page, or changes what it offers (2026-10-21, the Shop page window, 116). Returns { success, errorMessage, label }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfargument name="offer" type="string" required="false" default="">
		<cfset var response = { "success": false, "errorMessage": "", "label": "" }>
		<cfset var result = {}>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.postId) and arguments.postId gt 0>
			<cfset result = application.shop.setPageOffer(val(arguments.postId), arguments.offer)>
			<cfset response[ "success" ] = result.success>
			<cfset response[ "errorMessage" ] = arrayToList(result.errors, " ")>
			<cfif result.success>
				<cfset response[ "label" ] = application.shop.offerLabel(application.shop.getPageOffer(val(arguments.postId)))>
				<cfset application.blog.flushGalaxieCache(type = "post", postId = val(arguments.postId))>
			</cfif>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

	<cffunction name="removeShopPage" access="remote" returnformat="json" output="false"
			hint="Makes a shop page an ordinary page again: the products come off, the page and its text stay (2026-10-21). Returns { success }.">
		<cfargument name="csrfToken" type="string" default="" required="true">
		<cfargument name="postId" required="false" default="0">
		<cfset var response = { "success": false }>
		<cfif (not isdefined("arguments.csrfToken")) or (not verifyCsrfToken(arguments.csrfToken))>
			<cfset response = "Invalid token">
			<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
		</cfif>
		<cfset secureFunction('EditPost,ReleasePost')>
		<cfif application.Udf.isLoggedIn() and isValid("integer", arguments.postId) and arguments.postId gt 0>
			<cfset application.shop.removePage(val(arguments.postId))>
			<cfset application.blog.flushGalaxieCache(type = "post", postId = val(arguments.postId))>
			<cfset response[ "success" ] = true>
		</cfif>
		<cfif application.serverProduct eq 'Lucee'><cfreturn response><cfelse><cfreturn serializeJSON(response)></cfif>
	</cffunction>

</cfcomponent>
	
