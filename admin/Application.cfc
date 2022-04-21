<cfcomponent sessionmanagement="yes" clientmanagement="yes" output="yes" extends="ApplicationProxyReference">
	<cfset this.sessionManagement="yes"/>
	<cfset this.enablerobustexception = true />
	<cfset this.applicationTimeout = createTimeSpan(7,0,0,0) />
	<!--- 1 hour session timeout. It can take a long time to create a post and I don't want to force the user to reload the page --->
	<cfset this.sessiontimeout = createTimeSpan(0,1,0,0) >
	<!--- 
	Note: we turned off setClientCookies in the previous versions, however, when it is turned off in CF 2021, the sessionId increments everytime a window is open and the crsfToken changes which is breaking things.
	--->
	<cfset this.setClientCookies = true />

	<cffunction name="OnRequestStart">
		
		<!---//*****************************************************************************************
			Mobile Detection
		//******************************************************************************************--->
		
		<!--- This device detection code was updated on Feb 6 2019 (from http://detectmobilebrowsers.com/)--->
		<cfif 
		(reFindNoCase("(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino",CGI.HTTP_USER_AGENT) GT 0 OR reFindNoCase("1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-",Left(CGI.HTTP_USER_AGENT,4)) GT 0)>
			<cfset session.isMobile = true>
		<cfelse>
			<cfset session.isMobile = false>
		</cfif>
			
		<!---//*****************************************************************************************
			Logon
		//******************************************************************************************--->
		
		<!---Logout if the user is on the login page.--->
		<cflogout>
			
		<cflogin>
			<cfif isDefined("form.userName") and isDefined("form.password") and len(trim(form.username)) and len(trim(form.password))>
				
				<!--- Note: there is no way to reconstruct a password. The only thing you can do is to re-create a the same hashed password if you know the existing password and hash key. If you have access to the code, you *can* however add or 1 eq 1 to the following line to log in and change the password. Just change it back after changing it. --->
				<cfif application.blog.authenticate(left(trim(form.username),255),left(trim(form.password),50), cgi.remote_addr, cgi.http_User_Agent)>

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
					<!--- Add the blog user's specific roles to the session scope. --->
					<cfset session.roles = application.blog.getUserBlogRoles(username, 'roleList')>
					<!--- Set the capabilities. There are one or more capabilities for each role.--->
					<cfset session.capabilityList = application.blog.getCapabilitiesByRole(session.roles, 'capabilityList')>
					<!--- Also get the capability id's --->
					<cfset session.capabilityIdList =  application.blog.getCapabilitiesByRole(session.roles, 'capabilityIdList')>
					<!--- Drop a cookie on this machine to allow administators to preview posts that are not yet released (GA) --->
					<!--- Using the cfcookie tag does not work with dynamic vars in the path. --->
					<cfset cookie.isAdmin = { value="true", path="#application.baseUrl#", expires=30 }>
						
				<cfelse>
					<!--- Suggested by Shlomy Gantz to slow down brute force attacks --->
					<cfset createObject("java", "java.lang.Thread").sleep(500)>
				</cfif>
					
			</cfif><!---<cfif isDefined("form.userName") and isDefined("form.password") and len(trim(form.username)) and len(trim(form.password))>--->
		</cflogin>

		<!--- Allow the user to logout --->
		<cfif isDefined("url.logout") and application.Udf.isLoggedIn()>
			<cfset structDelete(session,"loggedin")>
			<cflogout>
		</cfif>

		<cfif findNoCase("/admin", cgi.script_name) and not application.Udf.isLoggedIn()>
			<cfsetting enablecfoutputonly="false">
			<!--- Here we are using a module instead of a cfinclude as the include would essentially place the login.cfm template, which has identical logic to the other admin templates, which causes errors as there are duplicate functions. --->
			<cfmodule template="logonPage.cfm">
			<cfabort>
		</cfif>
				
		<!---//*****************************************************************************************
			Persist login
		//******************************************************************************************--->
				
		<!--- We need to persist the login. It is not persisted with the changes to the application. --->
		<cfif application.Udf.isLoggedIn()>
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