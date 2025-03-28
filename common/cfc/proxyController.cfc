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
	<!--- We need the image object to save an manipulate images. These may fail when initally installing the blog with Lucee--->
	<cftry>
		<cfobject component="#application.imageComponentPath#" name="ImageObj">
		<!--- The jsonArray function turns a native ColdFusion query into an array of structs that can be easily used with jQuery. ---> 
		<cfobject component="#application.cfJsonComponentPath#" name="jsonArray">
		<!--- Include our string utils object to trim strings --->
		<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
		<!--- Instantiate the Render.cfc. --->
		<cfobject component="#application.rendererComponentPath#" name="RendererObj">
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
			
		<!--- Note: after one of the Chrome browser updates, my original logic that just used the csrfVerifyToken CF function stopped authenticating the token via AJAX requests when the browser was open for a long time and other tabs were opened with other sites. The workaround was to close the browser and reauthenticate, however, this was not per my original design and I don't want to have to close the browser everytime it fails. I have added logic here that the adminInterface page, used by the administrative site interfaces, creates a token and *then* creates a cookie and now I am also comparing if the cookie is the same as the passed in token to pass when the CSRFVerifyToken function is not working. This can be written in a much more concise way, however, I am making it verbose in order to understand the logic. ---> 
		<cfif isdefined("arguments.csrfToken")>
			<cfif CSRFVerifyToken(arguments.csrfToken, 'admin')>
				<!--- The token passes- all is good. This is the original logic --->
				<cfset tokenAuth = true>
			<cfelse><!---<cfif CSRFVerifyToken(arguments.csrfToken, 'admin')>--->
				<!--- This may sometimes fail if the browser has been opened and used with other sites. --->
				<!--- Was the expected cookie set on the adminInterface.cfm template? --->
				<cfif isDefined(cookie.csrfToken)>
					<cfif arguments.csrfToken eq cookie.csrfToken>
						<!--- Pass the request if the token matches the current csrfToken stored in the cookie --->
						<cfset tokenAuth = true>
					<cfelse><!---<cfif arguments.csrfToken eq cookie.csrfToken>--->
						<!--- Ok, something is wrong here- fail it. --->
						<cfset tokenAuth = false>
					</cfif><!---<cfif arguments.csrfToken eq cookie.csrfToken>--->
				<cfelse><!---<cfif isDefined(cookie.csrfToken)>--->
					<!--- Ok, the expected cookie is not present- fail it. --->
					<cfset tokenAuth = false>
				</cfif><!---<cfif isDefined(cookie.csrfToken)>--->
			</cfif><!---<cfif isDefined(cookie.csrfToken)>--->
		<cfelse><!---<cfif isdefined("arguments.csrfToken")>--->
			<!--- Pass in the token dummy! --->
			<cfset tokenAuth = false>
		</cfif><!---<cfif isdefined("arguments.csrfToken")>--->
			
		<!--- Return it --->
		<cfreturn tokenAuth>
			
	</cffunction>
	
	<cffunction name="secureFunction" access="package" output="yes" returntype="boolean" 
			hint="This is meant to be placed on top of a function to secure it against unauthorized use. It returns a 403 header if this is being called from an ajax request">
		<cfargument name="capabilities" required="no" default="" hint="What capabilities are authorized for this function?">
		<cfargument name="pkey" required="no" default="" hint="A temporary password as a string. We need a way to temporary bypass the isLogged in when a new user has been setup and they need to change the password that was assigned to them. This key will be authenticated against the database to determine if they whould be allowed in.">
		
		<!--- Secure this function. We are going to use an approach suggested by Chris Tierney. --->
		<cfset auth = true>
			
		<!--- One off branch. Allow the user to bypass having to be logged in by authenticating a string against the password in the users table. The user role and capabilities in this case are quite restritive and they should only be able to change their password. I may revisit this at a later time as it is a bit wobbly as far as security is concerned. --->
		<cfif len(arguments.pkey)> 

			<!--- Verify that the userName and password are correct in the link --->
			<cfquery name="Data" dbtype="hql">
				SELECT new Map (
					UserName as UserName
				)
				FROM Users
				WHERE 
					Password = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pkey#" maxlength="255">
					AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
				<cfif isSimpleValue(application.BlogDbObj.getBlogId())>
					AND BlogRef = #application.BlogDbObj.getBlogId()#
				</cfif>
			</cfquery>

			<!--- The ukey and or pkey was not valid --->	
			<cfif not arrayLen(Data)>
				<!--- Set our auth flag to false. --->
				<cfset auth = false>
			</cfif>
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
			
		<!--- The authorizedCapabilities is either a string or a ColdFusion list --->
		<cfloop list="#arguments.authorizedCapabilities#" index="i">
			<!--- All users may edit their own profile. --->
			<cfif findNoCase(i, session.capabilityList) or i eq 'EditProfile'>
				<cfset capabilityAuth = true>
			</cfif>
		</cfloop>
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
			
		<cfif application.blog.authenticate(left(trim(form.username),50),left(trim(form.password),50))>
			<cfloginuser name="#trim(arguments.username)#" password="#trim(arguments.password)#" roles="admin">
			<cfset session.userName = trim(username)>
			<cfset session.key = trim(password)>
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
		<!--- And hash it --->
		<cfset session.captchaHash = hash(session.captchaText)>
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
			
		<!--- Does the text that the user entered match the hashed value? --->
		<cfif arguments.captchaText eq session.captchaText>
			<cfset captchaPass  = true />
			<!--- Set the captcha validated cookie to true. It will expire in one minute. --->
			<cfcookie name="captchaValidated" expires="#dateAdd('n', 1, now())#" value="true">

		<cfelse>
			<!--- Note: the captcha will only be validated true one time as the encryption tokens get changed on true. However, the kendo validator validates quickly on blur, so there many be a true value overwritten by a false a millisecond later. We don't  want to ever change a true value to false and will use session vars to prevent this behavior. You can override this behavior by setting debugging to true. --->
			<cfif not debugging and isDefined("cookie.captchaValidated")>
				<cfset captchaPass  = true />
			<cfelse>
				<cfset captchaPass  = false />
			</cfif>
		</cfif>

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
			<cfset application.utils.mail(
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
		<cfargument name="postId" required="true" default="" hint="Pass in the postId." />
		<cfargument name="uiInterface" required="true" default="" hint="either 'addComment' or 'subscribe'. This function supports both the addComment and subscribe interfaces. We need to know what interface is being used to determine the proper logical pathway." />
		<cfargument name="postTitle" required="true" default="" hint="Pass in the entry title. This will be used as the subject for the sent email." />
		<cfargument name="commenterName" required="true" default="" hint="Pass in the name." />
		<cfargument name="commenterEmail" required="true" default="" hint="Pass in the email." />
		<cfargument name="commenterWebSite" required="false" default="" hint="Pass in the website." />
		<cfargument name="comments" required="true" default="" hint="Pass in the users comments." />
		<cfargument name="ipAddress" required="true" default="" hint="Pass in the users cgi.remote_addr string." />
		<cfargument name="userAgent" required="true" default="" hint="Pass in the users cgi.http_User_Agent string." />
		<cfargument name="captchaText" required="false" default="" hint="Pass in the captcha that the user entered." />
		<cfargument name="captchaHash" required="false" default="" hint="Pass in the captcha hash that is inside a hidden form." />
		<cfargument name="subscribe" required="true" default="" hint="Does the user want to subscribe?" />
		
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
			
		<!--- The captcha validation has occurred on the UI. The captcha backend will validate the captcha once and regenerate a new key. It can't be done twice (that I know of anyway). --->
		<cfif not isDefined("session.encryptionKey")>
			<cfset response[ "sessionExpired" ] = true />
		</cfif>
		<!--- Set the valid response --->
		<cfset response[ "valid" ] = valid />
		
		<!--- See https://www.telerik.com/blogs/extending-the-kendo-ui-validator-with-custom-rules on how we are going to get server side validation working on the client end. --->

		<!--- If there are no errors, proceed. --->
		<cfif valid>

			<!--- Handle the contact form --->
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
				<cfset application.utils.mail(
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
					<cfset application.utils.mail(
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
						<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#">
						<cfinvokeargument name="httpUserAgent" value="#arguments.userAgent#">
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
							<cfinvokeargument name="callToActionLink" value="#application.baseUrl#/admin/">
						</cfif>
					</cfinvoke>
							
					<!--- Email the owner of the blog. --->
					<cfset application.utils.mail(
						to=#application.BlogDbObj.getBlogEmail()#,
						subject="New comment made by #arguments.commenterName#",
						body=emailBody)>
						
					<!--- Send a response back to the client to determine the messages shown in the popup --->
					<cfset response[ "adminEmailedNewComment" ] = true />
						
					<!--- ************* Render email to all post subscribers informing them of the new comment ************* --->
					<!--- Note: if one of the admins is creating the comment it does not need to be approved. --->
					<cfif not application.BlogOptionDbObj.getBlogModerated() or application.Udf.isLoggedIn()>
						
						<!--- Get all post subscribers --->
						<cfset postSubscribers = application.blog.getSubscribers(postId=arguments.postId, verifiedOnly=true)>
							
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
								<cfset application.utils.mail(
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
		Subscriber Grid
	******************************************************************************************************--->
			
	<cffunction name="getSubscribersForGrid" access="remote" returnformat="json" output="false" 
			hint="Returns a json array to populate the subscribers grid.">
		<cfargument name="csrfToken" default="" required="true">
		<argument name="gridType" required="false" default="jsGrid" />
		<cfargument name="subscriberName" required="false" default="" />
		<cfargument name="subscriberEmail" required="false" default="" />
		<cfargument name="subscriberToken"  required="false" default="" />
		<cfargument name="subscribeAll" required="false" default="true" />
		<cfargument name="verifiedOnly" required="false" default="" />
		
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
		<cfinvoke component="#application.blog#" method="getSubscribers" returnvariable="Data">
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
		<cfinvoke component="#application.blog#" method="getSubscribers" returnvariable="getSubscriberEmail">
			<cfinvokeargument name="subscriberEmail" value="#arguments.subscriberEmail#">
		</cfinvoke>
		<cfinvoke component="#application.blog#" method="getSubscribers" returnvariable="getSubscriberToken">
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
			<cfset reponse = "Invalid token">
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
			<cfif arguments.Approved neq ''>
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
			
		<cftransaction>
			<!--- Load the theme entity. --->
			<cfset ThemeDbObj = entityLoadByPK("Theme", arguments.themeId)>
			<!--- Load the theme setting entity --->
			<cfset ThemeSettingDbObj = entityLoad("ThemeSetting", { ThemeSettingId = arguments.themeSettingId }, "true" )>

			<!--- Set the values --->
			<cfif arguments.modernThemeStyle>
				<cfset ThemeSettingDbObj.setBreakpoint(0)>
				<!--- Set the content width to 50 if it was not already been changed. --->
				<cfif arguments.contentWidth eq '66'>
					<cfset ThemeSettingDbObj.setContentWidth('50')>	
				</cfif>
			</cfif>
			<cfset ThemeDbObj.setSelectedTheme(arguments.selectedTheme)>
			<cfset ThemeDbObj.setUseTheme(arguments.useTheme)>				
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
		<cfargument name="calendarPodEnable" default="true">
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
				<cfset sanitizedCustomHeaderHtml = StringUtilsObj.sanitizeStrForDb(arguments.CustomHeaderHtml)>
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
		<cfset contentTemplates = "navigationMenu,aboutWindow,bioWindow,downloadWindow,downloadPod,subscribePod,cfblogsFeedPod,recentPostsPod,recentCommentsPod,categoriesPod,monthlyArchivesPod,compositeFooter">
			
		<cfloop list="#trim(contentTemplates)#" index="i">
			<cfset thisContentTemplateEnable = evaluate(i & 'Enable')>
				
			<!--- The enable and revert variables will come thru as either on or off. Chage this to true or false --->
			<cfif thisContentTemplateEnable eq 'on'>
				<cfset thisContentTemplateEnable = true>
			<cfelse>
				<cfset thisContentTemplateEnable = false>
			</cfif>

			<!--- Load the content template ---> 
			<cfset ContentTemplateDbObj = entityLoad("ContentTemplate", {ContentTemplateName=i}, "true" )>
			<!--- Set the active flag --->
			<cfset ContentTemplateDbObj.setActive(thisContentTemplateEnable)>
			<!--- Save it --->
			<cfset entitySave(ContentTemplateDbObj)>
				
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
				<!--- This is going to be set to false. The user must select this option to set it --->
				<cfinvokeargument name="selectedTheme" value="0">
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
		hint="Returns a json array to populate the categories dropdown.">
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
					</cfif>
					<!--- Set the active flag to false --->
					<cfinvokeargument name="active" value="0">
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
		<!--- Arguments that may be supplied by the client jsGrid when filters are in place. These arguments are passed through the URL. --->
		<cfargument name="user" required="no" default="">
		<cfargument name="alias" required="no" default="">
		<cfargument name="title" required="no" default="">
		<cfargument name="description" required="no" default="">
		<cfargument name="body" required="no" default="">
		<cfargument name="moreBody" required="no" default="">
		<cfargument name="posted" required="no" default="">
			
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
			<cfif arguments.user neq ''>
				<cfinvokeargument name="user" value="#arguments.user#"/>
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
			<cfif arguments.posted neq ''>
				<cfinvokeargument name="posted" value="#arguments.posted#"/>
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
				<cfif promptToEmailToSubscribers>
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
			<cfif promptToEmailToSubscribers>
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
				<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
				<!--- Set the remove column to true --->
				<cfset PostDbObj.setRemove(1)>
				<!--- Save it --->
				<cfset EntitySave(PostDbObj)>

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
		<cfset secureFunction('EditProfile,EditUser')>			
			
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
		<cfargument name="hitCount" required="no" default="">
		<cfargument name="ipAddress" required="no" default="">
		<cfargument name="userAgent" required="no" default="">
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
		<cfset secureFunction('EditProfile,EditUser')>			
			
		<cfinvoke component="#application.blog#" method="getVisitorLog" returnvariable="Data">			
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->	
			<cfif arguments.anonymousUserId neq ''>
				<cfinvokeargument name="anonymousUserId" value="#arguments.anonymousUserId#"/>
			</cfif>
			<cfif arguments.fullName neq ''>
				<cfinvokeargument name="fullName" value="#arguments.fullName#"/>
			</cfif>
			<cfif arguments.hitCount neq ''>
				<cfinvokeargument name="hitCount" value="#arguments.hitCount#"/>
			</cfif>
			<cfif arguments.ipAddress neq ''>
				<cfinvokeargument name="ipAddress" value="#arguments.ipAddress#"/>
			</cfif>
			<cfif arguments.userAgent neq ''>
				<cfinvokeargument name="userAgent" value="#arguments.userAgent#"/>
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
		<cfargument name="relatedPosts" type="string" default="" required="false" hint="This can have 0 or more items">
		<cfargument name="released" type="boolean" default="true" required="no">
		<cfargument name="allowComment" type="boolean" default="true" required="no">
		<cfargument name="promote" type="boolean" default="false" required="no">
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
					<cfinvokeargument name="relatedPosts" value="#arguments.relatedPosts#">
					<cfinvokeargument name="released" value="#arguments.released#">
					<cfinvokeargument name="allowComment" value="#arguments.allowComment#">
					<cfinvokeargument name="promote" value="#arguments.promote#">
					<cfinvokeargument name="remove" value="#arguments.remove#">
					<cfinvokeargument name="redirectUrl" value="#arguments.redirectUrl#">
					<cfinvokeargument name="redirectType" value="#arguments.redirectType#">
					<cfinvokeargument name="emailSubscriber" value="#arguments.emailSubscriber#">
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
		<cfargument name="alias" required="no" default="">
		<cfargument name="category" required="no" default="">
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
		<cfset secureFunction('EditCategory,AddPost,EditPost,ReleasePost')>	
			
		<cfinvoke component="#application.blog#" method="getCategoriesForGrid" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->			
			<cfif arguments.category neq ''>
				<cfinvokeargument name="category" value="#arguments.category#"/>
			</cfif>
			<cfif arguments.alias neq ''>
				<cfinvokeargument name="alias" value="#arguments.alias#"/>
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
			<!--- See if the category exists. This will return a HQL array --->
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
		<cfargument name="alias" required="no" default="">
		<cfargument name="tag" required="no" default="">
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
		<cfset secureFunction('EditCategory,AddPost,EditPost,ReleasePost')>	
			
		<cfinvoke component="#application.blog#" method="getTagsForGrid" returnvariable="Data">
			<!--- Note: the following options are used on the open source jsGrid. The Kendo commercial grid has client side filtering and these are not used. --->			
			<cfif arguments.tag neq ''>
				<cfinvokeargument name="tag" value="#arguments.tag#"/>
			</cfif>
			<cfif arguments.alias neq ''>
				<cfinvokeargument name="alias" value="#arguments.alias#"/>
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
			
		<!--- Secure this function. This will abort the page and set a 403 status code if the user is not logged in. Note: the user can edit their own profile when a new user is required to change their password --->
		<cfset secureFunction('EditProfile,EditUser', arguments.pkey)>

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
		Gallery functions
	******************************************************************************************************--->
				
	<cffunction name="saveGallery" access="remote" output="false" returnformat="plain" 
			hint="Saves data from the comment detail page.">
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="action" hint="Either insert or update" default="insert">
		<cfargument name="mediaIdList" type="string" required="true">
		<cfargument name="darkTheme" type="string" required="true">

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
		<cfargument name="postId" default="" required="true">
		<cfargument name="darkTheme" type="string" required="true">

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
									<cfset CarouselDbObj.setDate(application.blog.blogNow())>
									<!---Save the entity--->
									<cfset EntitySave(CarouselDbObj)>
										
									<!--- Get the Id --->
									<cfset carouselId = CarouselDbObj.getCarouselId()>
								</cftransaction>
									
								<!--- Now, assign the new carousel to the post. --->
								<cftransaction>
									<!--- Load the post entity --->
									<cfset PostDbObj = entityLoad("Post", { PostId = arguments.postId }, "true" )>
										
									<!--- Set the enclosureCarousel --->
									<cfset PostDbObj.setEnclosureCarousel(CarouselDbObj)>
					
									<!--- Remove other enclosures --->
									<cfset PostDbObj.setEnclosureMedia(javaCast("null",""))>
									<cfset PostDbObj.setEnclosureMap(javaCast("null",""))>
									
									<!--- Save it. We're not going to set the date. --->
									<cfset EntitySave(PostDbObj)>
										
								</cftransaction>
										
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
			
		<!--- Make sure that output is turned on when debugging --->
		<cfset debug = false>
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

			<!--- ******************************* A2- Upload the image(s) to a temp directory ******************************* --->
			<!--- Put this in a catch block --->
			<cftry>
				
				<!--- Upload all of the files to ColdFusion's temporary directory and then check the file(s) before we upload them to our permanent destination. The file field name may vary here, its different for the uppy (ie. files[]) and tinymce (ie file) interfaces, and we need some extra logic to differentiate them. --->
				
				<!--- When we are uploading for the gallery or carousel, we need to make sure to upload the files sequentially and are using Uppy's bundle option which sends all of the images at once. Since we are not looping through each image individually, we need to use a query object to store the file results ---> 
				<cfif usingUppyBundleOption> 
					
					<!--- Create a query to hold the response sent back to the client. --->
					<cfset responseQuery = queryNew("error,errorMessage,mediaId,location", "bit,varchar,integer,varchar")>
						
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
					
					<!--- Set our final destination. To reduce potential confilict between the image names, we are saving each type of media in its own folder --->
					<cfset destination = ImageObj.getImageUploadDestination(arguments.mediaProcessType)>
					
					<!--- Determine if the image already exists. This flag will be used to determine whether to update or insert the record into the database. --->
					<cfif fileExists(destination & image.ServerFile)>
						<cfset imageExists = true>
					<cfelse>
						<cfset imageExists = false>
					</cfif>
					
					<!--- Create our thumbnail image (for presentation in the administrative interface). The thumbnails are created for enclosures (posts), carousels, and fancybox when creating a gallery (createThumbnail(source, fileName). We do not want to create thumbnails of smaller images, such as our Logos, user profile images, etc --->
					<cfif mediaProcessType eq 'enclosure' or mediaProcessType eq 'carousel' or mediaProcessType eq 'gallery'>
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
					<cfif arguments.mediaProcessType eq 'enclosure' and arguments.mediaType eq 'image'>
						<cftry>
							<!--- Manipulate the image and save it in the social media sharing folders --->
							<cfset socialMediaImagePath = destination & "\" & image.serverFile>
							<!--- Method: createSocialMediaImages(socialMediaImagePath, socialMediaImageType) --->
							<!--- Create a social media sharing image for Facebook --->
							<cfset facebookSharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'facebook', '')>
							<cfif isDefined("facebookSharingImage")>
								<cfset mediaActions = listAppend(mediaActions, 'Facebook Sharing Image')>
								<cfset facebookOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#facebookSharingImage#" label="facebook"></cfif>

							<!--- Twiter... --->
							<cfset twitterSharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'twitter', '')>
							<cfif isDefined("twitterSharingImage")>
								<cfset mediaActions = listAppend(mediaActions, 'Twitter Sharing Image')>
								<cfset twitterOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#twitterSharingImage#"></cfif>
								
							<!--- and the various formats for Google (these are also used for google search) --->
							<cfset google16_9SharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'google', 'google16_9Image')>
							<cfif isDefined("google16_9SharingImage")>
								<cfset mediaActions = listAppend(mediaActions, 'Google 16x9 Sharing Image')>
								<cfset googleOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#google16_9SharingImage#"></cfif>
								
							<cfset google4_3SharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'google', 'google4_3Image')>
							<cfif isDefined("google4_3Image")>
								<cfset mediaActions = listAppend(mediaActions, 'Google 4x3 Sharing Image')>
								<cfset googleOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#google4_3SharingImage#"></cfif>
								
							<cfset google1_1SharingImage = ImageObj.createSocialMediaImages(socialMediaImagePath, 'google', 'google1_1Image')>
							<cfif isDefined("google1_1Image")>
								<cfset mediaActions = listAppend(mediaActions, 'Google 1x1 Sharing Image')>
								<cfset googleOptimized = true>
							</cfif>
							<cfif debug><cfdump var="#google1_1SharingImage#"></cfif>
								
							<cfcatch type="any">
								<cfset errorMessage = "Error creating social media images">
							</cfcatch>
						</cftry>
					</cfif><!---<cfif arguments.mediaProcessType eq 'enclosure'>--->
							
					<!--- B Save images to the database --->
					<!--- There are three separate logical branches here: 1) update the theme setting, 2) update the video cover with an image in the database, and 3) to insert or update a media record. --->
					
					<!--- B1) Update the theme setting table. --->
					<cfif arguments.mediaProcessType contains 'Background' or arguments.mediaProcessType eq 'footerImage'>
						<cfinvoke component="#application.blog#" method="saveTheme" returnvariable="themeId">
							<cfinvokeargument name="themeId" value="#arguments.themeId#" />
							<cfinvokeargument name="#arguments.mediaProcessType#" value="#imageUrl#" />
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
					</cfif><!---<cfif arguments.mediaProcessType eq 'mediaVideoCoverUrl'>--->
								
					<!--- When using the bundled option, dump the response into the result query. We must do this for every file within the file loop --->
					<cfif usingUppyBundleOption>
						<cfset queryAddRow(responseQuery)>
						<!--- Set the values --->
						<cfset querySetCell(responseQuery,"error",false)>
						<cfset querySetCell(responseQuery,"errorMessage","")>
						<cfset querySetCell(responseQuery,"location","#imageUrl#")>
						<cfset querySetCell(responseQuery,"mediaId","#mediaId#")>
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
					
	<cffunction name="uploadImageViaUploaderMethod" access="remote" returnformat="plain" output="false" 
			hint="Depracated. Still keeping around for future blog post (it's simple). This function uploads an image via the tiny mce editor">
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
				
		<!--- Manipulate the enclosure for social media sharing. ---> 
		<!--- Set the destination. --->
		<cfset destination = expandPath("#application.baseUrl#/enclosures")>

		<!--- Upload it --->
		<cffile action="upload" filefield="file" destination="#destination#" mode = "644" nameconflict="overwrite">

		<!--- Get the full path and the name of the file --->
		<cfset imageUrl = application.baseUrl & "/enclosures/" & cffile.serverFile>

		<!--- Return the structure with the image back to the client --->
		<cfreturn imageUrl>

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
		
			<!--- Note: this function follows the best practices given by http://learncfinaweek.com/course/index/section/Security/item/File_Uploads/. ---> 
			
			<!--- ************************************ Error checking ************************************ --->

			<!--- Allowed mime types. --->
			<cfset acceptedMimeTypes = {
			'video/mp4': {extension: 'mp4'},
			'video/webm': {extension: 'webm'},
			'video/ogg': {extension: 'ogg'},
			'video/quicktime': {extension: 'mov'}
			}>

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
							
			<!--- *********** If there were no errors, move the video to the desired destination  ************ --->
			<cfif not error>
					
				<!--- There can be one or more videos. Loop through the video array provided by cffile --->
				<cfloop array="#UploadObj#" item="video">

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
					<cfelse>
						<!--- This is a comment. Set the mediaId to 0 to insert a new record.--->
						<cfset mediaId = 0>
					</cfif>

					<!--- Insert the record to the database. --->
					<cfif mediaId eq 0>
						<cfinvoke component="#application.blog#" method="insertMediaRecord" returnvariable="mediaId">
							<cfif len(arguments.postId)>
								<cfinvokeargument name="postId" value="#arguments.postId#" />
							</cfif>
							<cfif len(arguments.commentId)>
								<cfinvokeargument name="commentId" value="#arguments.commentId#" />
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
					</cfif>
					
				</cfloop><!---<cfloop array="#UploadObj#" item="video">--->
					
				<!--- Create a new location struct with the new video URL. Also include the new mediaId. This is needed as we have not yet saved the comment when the video is uploaded. --->
				<cfset response[ "postId" ] = arguments.postId />
				<cfset response[ "mediaId" ] = mediaId />
				<cfset response[ "location" ] = videoUrl />
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
		<cfargument name="mediaType" default="image" required="false" hint="Either image or video">
		<cfargument name="imageType" default="image" required="false" hint="Used to determine the image type when updating a user profile image or a theme type image. Only used for users and themes">
		<cfargument name="videoProvider" default="" required="false" hint="The video provider (i.e. Google (Google YouTube Redirect), Microsoft Stream, VideoPress, Vimeo or YouTube). In this version, we are only supporting Vimeo and YouTube, but I will add support for other video providers in the future.">
		<cfargument name="providerVideoId" default="" required="false" hint="The providers video Id (i.e. the Vimeo or YouTube Id)">
		<cfargument name="selectorId" default="" required="false" hint="We need to know where this request is being posted from to determine the logic as necessary.">
			
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
			
			<!--- If the mediaId was not passed in, and we are dealing with a post, see if the record already exists --->
			<cfif not len(arguments.mediaId) and len(arguments.postId)>
				<cfinvoke component="#application.blog#" method="getPostEnclosureMediaIdByUrl" returnvariable="arguments.mediaId">
					<cfinvokeargument name="postId" value="#arguments.postId#">
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
						<cfinvokeargument name="postId" value="#arguments.postId#" />
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
							<cfinvokeargument name="postId" value="#arguments.postId#" />
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
			hint="This removes any existing post enclosures from the database">
		<cfargument name="csrfToken" required="yes" default="" hint="Pass in the csrfToken">
		<cfargument name="postId" default="" required="yes">
		
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
				<!--- Load the entity. --->
				<cfset PostDbObj = entityLoad("Post", { postId = arguments.postId }, "true" )>
				<!--- Set the enclosure media ref to null --->
				<cfset PostDbObj.setEnclosureMedia(javaCast("null",""))>
				<!--- Save the Post. --->
				<cfset EntitySave(PostDbObj)>
			</cftransaction>
			
			<cfreturn arguments.postId>
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
		<cfargument name="includeDisqus" default="" required="false">
		<cfargument name="includeGsap" default="" required="false">
		<!--- These are text boxes --->
		<cfargument name="jQueryCDNPath" default="" required="false">
		<cfargument name="kendoFolderPath" default="" required="false">
		<cfargument name="googleAnalyticsString" default="" required="false">
		<cfargument name="addThisApiKey" default="" required="false">
		<cfargument name="addThisToolboxString" default="" required="false">
		<cfargument name="bingMapsApiKey" default="" required="false">
		<cfargument name="disqusBlogIdentifier" default="" required="false">
		<cfargument name="disqusApiKey" default="" required="false">
		<cfargument name="disqusApiSecret" default="" required="false">
		<cfargument name="disqusAuthTokenKey" default="" required="false">
		<cfargument name="disqusAuthUrl" default="" required="false">
		<cfargument name="disqusAuthTokenUrl" default="" required="false">
			
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
				<cfset OptionDbObj.setIncludeDisqus(includeDisqus)>
				<cfset OptionDbObj.setIncludeGsap(includeGsap)>
				<cfset OptionDbObj.setUseSsl(useSsl)>
				<!--- These are strings coming from textboxes. --->
				<cfset OptionDbObj.setJQueryCDNPath(arguments.jQueryCDNPath)>
				<cfset OptionDbObj.setKendoFolderPath(arguments.kendoFolderPath)>
				<cfset OptionDbObj.setGoogleAnalyticsString(arguments.googleAnalyticsString)>
				<cfset OptionDbObj.setAddThisApiKey(arguments.addThisApiKey)>
				<cfset OptionDbObj.setAddThisToolboxString(arguments.addThisToolboxString)>
				<cfset OptionDbObj.setAddThisApiKey(arguments.addThisApiKey)>
				<cfset OptionDbObj.setBingMapsApiKey(arguments.bingMapsApiKey)>
				<cfset OptionDbObj.setDisqusBlogIdentifier(arguments.disqusBlogIdentifier)>
				<cfset OptionDbObj.setDisqusApiKey(arguments.disqusApiKey)>
				<cfset OptionDbObj.setDisqusApiSecret(arguments.disqusApiSecret)>
				<cfset OptionDbObj.setDisqusAuthTokenKey(arguments.disqusAuthTokenKey)>
				<cfset OptionDbObj.setDisqusAuthUrl(arguments.disqusAuthUrl)>
				<cfset OptionDbObj.setDisqusAuthTokenUrl(arguments.disqusAuthTokenUrl)>
				<cfset OptionDbObj.setDate(application.blog.blogNow())>
				<!--- Save it --->
				<cfset EntitySave(OptionDbObj)>
				
			</cftransaction>
			
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
		<!--- IP Block list --->
		<cfargument name="ipBlockList" default="" required="false">
			
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
			
			<!--- Note: we need to store the database connection credentials in the blog.ini file as well. This is needed as the database will not immediately be up and running when the blog is installed and we are using the ini file to store the credentials when we can't get them from the database --->
			<cfset setProfileString(application.iniFile, "default", "dsn", arguments.dsn)>
			<cfset setProfileString(application.iniFile, "default", "username", arguments.dsnUserName)>
			<cfset setProfileString(application.iniFile, "default", "password", arguments.dsnPassword)>
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
				<!--- IP Block list --->
				<cfset BlogDbObj.setIpBlockList(arguments.ipBlockList)>
				<!--- Date --->
				<cfset BlogDbObj.setDate(application.blog.blogNow())>
				<!--- Save it --->
				<cfset EntitySave(BlogDbObj)>
				
			</cftransaction>
			
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
		
			<cfif arguments.fileType eq 'webVtt'>
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
	*******************************************************************************************************--->
				
	<cffunction name="saveMap" access="remote" output="false" returnformat="json"
			hint="This function saves the address and waypoints when creating a map route"><!---returnformat="json" --->
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="isEnclosure" default="true" required="true">
		<cfargument name="postId" default="" required="true">
		<cfargument name="mapId" default="" required="false">
		<cfargument name="mapType" default="" required="true">
		<cfargument name="mapZoom" default="" required="true">
		<cfargument name="mapAddress" required="true" default="">
		<cfargument name="mapCoordinates" required="true" default="">
		<cfargument name="customMarker" required="false" default="">
		<cfargument name="oulineMap" required="false" default="false">
			
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
					<cfinvokeargument name="isEnclosure" value="#arguments.isEnclosure#">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="mapId" value="#arguments.mapId#">
					<cfinvokeargument name="mapType" value="#arguments.mapType#">
					<cfinvokeargument name="mapZoom" value="#arguments.mapZoom#">
					<cfinvokeargument name="mapAddress" value="#arguments.mapAddress#">
					<cfinvokeargument name="mapCoordinates" value="#arguments.mapCoordinates#">
					<cfinvokeargument name="customMarker" value="#arguments.customMarker#">
					<cfinvokeargument name="outlineMap" value="#arguments.outlineMap#">
				</cfinvoke>

				<!--- Pass back the map and post id--->
				<cfset response[ "postId" ] = #arguments.postId# />
				<cfset response[ "mapId" ] = #arguments.mapId# />
				<cfset response[ "success" ] = true />
			
				<cfcatch type="any">
					<!--- Serialize our error --->
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
				
	<cffunction name="saveMapRoute" access="remote" output="false" returnformat="json"
			hint="This function saves the address and waypoints when creating a map route"><!---returnformat="json" --->
		<cfargument name="csrfToken" default="" required="true">
		<cfargument name="locationGeoCoordinates" default="" required="true">
		<cfargument name="isEnclosure" default="true" required="true">
		<cfargument name="mapId" default="" required="false">
		<cfargument name="mapRouteId" default="" required="false">
		<cfargument name="postId" default="" required="false">
		<cfargument name="mapTitle" type="string" required="false" default="" hint="Pass in the map title">
			
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
			
				<cfinvoke component="#application.blog#" method="saveMapRoute" returnvariable="mapId">
					<cfinvokeargument name="mapId" value="#arguments.mapId#">
					<cfinvokeargument name="mapRouteId" value="#arguments.mapRouteId#">
					<cfinvokeargument name="postId" value="#arguments.postId#">
					<cfinvokeargument name="mapTitle" value="#arguments.mapTitle#">
					<cfinvokeargument name="locationGeoCoordinates" value="#arguments.locationGeoCoordinates#">
					<cfinvokeargument name="isEnclosure" value="#arguments.isEnclosure#">
					<cfinvokeargument name="provider" value="Bing Maps">
				</cfinvoke>

				<!--- Pass back the map and post id--->
				<cfset response[ "postId" ] = #arguments.postId# />
				<cfset response[ "mapId" ] = #arguments.mapId# />
				<cfset response[ "success" ] = true />
			
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
		Update DB
	*******************************************************************************************************--->
				
	<cffunction name="updateDb" access="remote" output="false" returnFormat="json"
			hint="This function updates the database to a new version">
		<cfargument name="blogVersion" required="true">
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
			
			<!--- Determine what tables to update based upon the verson --->
			<cfif arguments.blogVersion eq '3.12'>
				<!--- Update all of the records in the Font table --->
				<cfinvoke component="#application.blog#" method="updateDb" returnvariable="success">
					<cfinvokeargument name="tablesToPopulate" value="Font">
					<cfinvokeargument name="updateRecords" value="true">
				</cfinvoke>
						
				<!--- Only insert the new Joshua Tree records into the Theme related tables. --->
				<cfinvoke component="#application.blog#" method="updateDb" returnvariable="success">
					<cfinvokeargument name="tablesToPopulate" value="Theme">
					<cfinvokeargument name="updateRecords" value="false">
				</cfinvoke>
					
				<!--- Update the version --->
				<cfinvoke component="#application.blog#" method="updateBlogVersion" returnvariable="success">
					<cfinvokeargument name="blogVersion" value="3.12">
					<cfinvokeargument name="blogVersionName" value="Galaxie Blog 3.12">
				</cfinvoke>

			</cfif><!---<cfif arguments.blogVersion eq '3.12'>--->
					
		</cfif>
	
		<cfreturn true>
			
	</cffunction>
						
</cfcomponent>
	