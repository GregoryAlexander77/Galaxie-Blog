<!--- Common pointers. --->
<cfset application.rootURL = application.blog.getProperty("blogURL")>
<!--- per documentation - rooturl should be http://www.foo.com/something/something/index.cfm --->
<cfset application.rootURL = reReplace(application.rootURL, "(.*)/index.cfm", "\1")>
	
<!--- Set the component path. --->
<!--- Remove the first forward slash in the baseUrl. --->
<cfset baseProxyUrl = replace(baseUrl, "/", "", "one")>
<!--- Replace forward slashes with dots. --->
<cfset baseProxyUrl = replace(baseProxyUrl, "/", ".", "all")>
<!--- Append the base URL with the proxyController. --->
<cfset application.proxyControllerComponentPath = baseProxyUrl & ".common.cfc.proxyController">
			
<!--- load and init blog --->
<cfset application.blog = createObject("component","#application.proxyControllerComponentPath#.org.camden.blog.blog").init('default')>
	
<!--- Include the udf library that used to be included from the root's application.cfm template. --->
<cfinclude template="#application.rootURL#/includes/udf.cfm">

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

