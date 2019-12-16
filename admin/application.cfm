<cfapplication name="GalaxieBlog" sessionManagement="true" loginStorage="session">
	
<!--- This template is needed in order to secure the admin portions of the site. I could have used a application.cfc instead, but then I would have had to screw around with creating proxyies in order to get the extends argument in order to find the parent application.cfc, and it is just a pain. It is just not needed here. Note: the cflogin code below the udf was coded by Raymond and is essentially unchanged. --->
	
<!--- Include the UDF (Raymond's code) --->
<cfinclude template="#application.baseUrl#/includes/udf.cfm">

<cflogin>
	<cfif isDefined("form.username") and isDefined("form.password") and len(trim(form.username)) and len(trim(form.password))>
		<cfif application.blog.authenticate(left(trim(form.username),50),left(trim(form.password),50))>
			<cfloginuser name="#trim(username)#" password="#trim(password)#" roles="admin">
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