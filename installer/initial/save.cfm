<!---
	The installer's saves (5.0, 2026-10-20): the wizard (index.cfm) sends each step here and gets JSON back. It does what the old
	step pages did - step3SaveSiteInfo.cfm, step5SaveDatabase.cfm and step7Post.cfm - each value kept in the session (so the
	wizard can show it again) and written to blog.ini.cfm, which the blog reads when it installs itself.

	step=site      blogUrl, blogTitle
	step=database  dsn, databaseType - only a datasource that exists, connects and has no blog in it (dsnCheck.cfm)
	step=account   firstName, lastName, profileDisplayName, email, website, userName, password, confirmPassword,
	               securityAnswer1-3. Checks the site and database steps again, then returns installUrl: the blog's
	               index.cfm?init=1&install=true, which builds the database and runs ../insertData.cfm (it needs a new request,
	               so that ORM starts with the datasource just saved). insertData.cfm empties the password and answers from
	               blog.ini.cfm once the administrator is saved.
	Returns { success, message, field, installUrl }; field names the input a message is about.
--->
<cfsetting showdebugoutput="false">
<cfinclude template="dsnCheck.cfm">
<cfparam name="form.step" default="">
<cfset response = { "success": false, "message": "", "field": "", "installUrl": "" }>

<cffunction name="formValue" returntype="string" output="false">
	<cfargument name="name" type="string" required="true">
	<cfargument name="maxLength" type="numeric" required="false" default="255">
	<cfreturn structKeyExists(form, arguments.name) ? left(trim(form[arguments.name]), arguments.maxLength) : "">
</cffunction>

<cffunction name="saveValue" returntype="void" output="false" hint="Keeps a value in the session and in blog.ini.cfm.">
	<cfargument name="name" type="string" required="true">
	<cfargument name="value" type="string" required="true">
	<cfset session[arguments.name] = arguments.value>
	<cfset setProfileString(application.iniFile, "default", arguments.name, arguments.value)>
</cffunction>

<cfswitch expression="#form.step#">

	<cfcase value="site">
		<cfset blogTitle = formValue("blogTitle", 125)>
		<cfset blogUrl = formValue("blogUrl", 500)>
		<!--- The address the blog builds every link from: a scheme, no page name, then /index.cfm (as the old step 3 saved it). --->
		<cfif len(blogUrl) and not reFindNoCase("^https?://", blogUrl)>
			<cfset blogUrl = (cgi.https eq "on" ? "https://" : "http://") & blogUrl>
		</cfif>
		<cfset blogUrl = reReplaceNoCase(blogUrl, "/index\.cfm$", "")>
		<cfset blogUrl = reReplace(blogUrl, "/+$", "")>
		<cfif not reFindNoCase("^https?://[a-z0-9.-]+(:[0-9]+)?(/[^\s?##]*)?$", blogUrl)>
			<cfset response.message = "Please enter your site's address, such as https://www.example.com">
			<cfset response.field = "blogUrl">
		<cfelseif not len(blogTitle)>
			<cfset response.message = "Please enter your site's name.">
			<cfset response.field = "blogTitle">
		<cfelse>
			<cfset saveValue("useSsl", left(blogUrl, 8) eq "https://")>
			<cfset saveValue("blogTitle", blogTitle)>
			<cfset saveValue("blogUrl", blogUrl & "/index.cfm")>
			<cfset response.success = true>
		</cfif>
	</cfcase>

	<cfcase value="database">
		<cfset dsn = formValue("dsn", 100)>
		<cfset databaseType = formValue("databaseType", 30)>
		<cfset problem = getInstallDsnProblem(dsn)>
		<cfif not listFindNoCase("sqlServer,mySql,postgre,oracle,db2,apacheDerby,sybase", databaseType)>
			<cfset response.message = "Please choose your database.">
			<cfset response.field = "databaseType">
		<cfelseif len(problem)>
			<cfset response.message = problem>
			<cfset response.field = "dsn">
		<cfelse>
			<cfset saveValue("dsn", dsn)>
			<cfset saveValue("databaseType", databaseType)>
			<cfset response.success = true>
			<cfset response.message = "Connected. The database is empty and ready.">
		</cfif>
	</cfcase>

	<cfcase value="account">
		<cfset values = {}>
		<cfloop list="firstName,lastName,profileDisplayName,email,website,userName,securityAnswer1,securityAnswer2,securityAnswer3" index="name">
			<cfset values[name] = formValue(name)>
		</cfloop>
		<cfset password = structKeyExists(form, "password") ? left(form.password, 50) : "">
		<cfset confirmPassword = structKeyExists(form, "confirmPassword") ? left(form.confirmPassword, 50) : "">
		<!--- Each in turn, so the wizard can point at the field. --->
		<cfif not len(values.firstName)><cfset response.message = "Please enter your first name."><cfset response.field = "firstName">
		<cfelseif not len(values.lastName)><cfset response.message = "Please enter your last name."><cfset response.field = "lastName">
		<cfelseif not isValid("email", values.email)><cfset response.message = "Please enter your email address."><cfset response.field = "email">
		<cfelseif len(values.website) and not reFindNoCase("^https?://", values.website)><cfset response.message = "A website address starts with https:// or http://."><cfset response.field = "website">
		<cfelseif not reFind("^[A-Za-z0-9._@-]{3,50}$", values.userName)><cfset response.message = "A user name is 3 to 50 letters, numbers, dots, dashes or underscores."><cfset response.field = "userName">
		<cfelseif len(password) lt 8 or not reFind("[^A-Za-z]", password)><cfset response.message = "Please use a password of at least 8 characters, with a number or symbol."><cfset response.field = "password">
		<cfelseif compare(password, confirmPassword) neq 0><cfset response.message = "The two passwords are different."><cfset response.field = "confirmPassword">
		<cfelseif not len(values.securityAnswer1)><cfset response.message = "Please answer each question; they let you reset a forgotten password."><cfset response.field = "securityAnswer1">
		<cfelseif not len(values.securityAnswer2)><cfset response.message = "Please answer each question; they let you reset a forgotten password."><cfset response.field = "securityAnswer2">
		<cfelseif not len(values.securityAnswer3)><cfset response.message = "Please answer each question; they let you reset a forgotten password."><cfset response.field = "securityAnswer3">
		<!--- The earlier steps, again: the install must not start without them. --->
		<cfelseif not len(getProfileString(application.iniFile, "default", "blogUrl")) or not len(getProfileString(application.iniFile, "default", "blogTitle"))>
			<cfset response.message = "Your site's address and name are missing. Go back to Your site.">
		<cfelseif len(getInstallDsnProblem(getProfileString(application.iniFile, "default", "dsn")))>
			<cfset response.message = getInstallDsnProblem(getProfileString(application.iniFile, "default", "dsn")) & " Go back to Database.">
		<cfelse>
			<cfloop collection="#values#" item="name">
				<cfset saveValue(name, values[name])>
			</cfloop>
			<!--- For the install only: insertData.cfm hashes it into the administrator and then empties it from blog.ini.cfm. --->
			<cfset setProfileString(application.iniFile, "default", "password", password)>
			<cfset response.success = true>
			<cfset response.installUrl = "../../index.cfm?init=1&install=true">
		</cfif>
	</cfcase>

	<cfdefaultcase>
		<cfset response.message = "Unknown step.">
	</cfdefaultcase>
</cfswitch>
<cfcontent type="application/json; charset=utf-8" reset="true"><cfoutput>#serializeJSON(response)#</cfoutput>
