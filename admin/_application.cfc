<cfcomponent displayname="GalaxieBlog" sessionmanagement="yes" clientmanagement="yes" extends="blog.applicationProxyReference">
	<cfset this.sessionManagement="yes"/>
	<cfset this.enablerobustexception = true />

	<cffunction name="OnRequestStart">  
		
		<!--- This template is needed in order to secure the admin portions of the site. Note: the cflogin code below the udf was coded by Raymond and is essentially unchanged. --->
		<!---Include the resource bundle.--->
		<cfset getResourceBundle = application.utils.getResource>
		<!--- Include the UDF (Raymond's code) --->
		<cfinclude template="../includes/udf.cfm">
		<!--- There are two coldfusion application templates that I used, the legacy application.cfm template, and the modern application.cfc template. I am having problems with the cfc template as it requires a hard coded mapping. There are ways around this, but for this particular version, its easier just to use the original application.cfm extension until I can re-write the administrative section. This is a workaround. However, I need to set a applicationTemplateType flag in order to still use the application.cfc template for my own personal debugging (my hosting provider requires it). --->
		<cfset application.coldFusionApplicationTemplateType = "cfc">

		<cflogin>
			<cfif isDefined("form.username") and isDefined("form.password") and len(trim(form.username)) and len(trim(form.password))>
				<cfif application.blog.authenticate(left(trim(form.username),50),left(trim(form.password),50))>
					<cfloginuser name="#trim(username)#" password="#trim(password)#" roles="admin">
					<cfset session.userName = trim(username)>
					<cfset session.key = trim(password)>
					<!--- 
						  This was added because CF's built in security system has no way to determine if a user is logged on.
						  In the past, I used getAuthUser(), it would return the username if you were logged in, but
						  it also returns a value if you were authenticated at a web server level. (cgi.remote_user)
						  Therefore, the only say way to check for a user logon is with a flag. 
					--->  
					<cfset session.loggedin = true>
					<!--- 
					While we use roles above based on CF's built in stuff, I plan on moving away from that, and the role here
					is more a high level role. We need to add a blog user's specific roles to the session scope.
					--->
					<cfset session.roles = application.blog.getUserBlogRoles(username)>
					<!--- Drop a cookie on this machine to allow administators to preview posts that are not yet released (GA) --->
					<!--- Using the cfcookie tag does not work with dynamic vars in the path. --->
					<cfset cookie.isAdmin = { value="true", path="#application.baseUrl#", expires=30 }>
				<cfelse>
					<!--- Suggested by Shlomy Gantz to slow down brute force attacks --->
					<cfset createObject("java", "java.lang.Thread").sleep(500)>
				</cfif>
			</cfif>
		</cflogin>

		<!--- Security Related --->
		<cfif isDefined("url.logout") and isLoggedIn()>
			<cfset structDelete(session,"loggedin")>
			<cflogout>
		</cfif>

		<cfif findNoCase("/admin", cgi.script_name) and not isLoggedIn() and not findNoCase("/admin/notify.cfm", cgi.script_name)>
			<cfsetting enablecfoutputonly="false">
			<cfinclude template="login.cfm">
			<cfabort>
		</cfif>
				
		<!--- Gregory's code: we need to persist the login. It is not persisted with the changes to the application. --->
		<cfif isLoggedIn()>
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

</cfcomponent>