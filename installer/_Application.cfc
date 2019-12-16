<cfcomponent displayname="GalaxieBlog" sessionmanagement="yes" clientmanagement="yes" output="true">
	<cfset this.Name = "GalaxieBlog" />
	<cfset this.applicationTimeout = createTimeSpan(7,0,0,0) />
	<cfset this.sessionManagement="yes"/>
	<cfset this.enablerobustexception = true />
	
	<cffunction name="OnRequestStart">  
	
		<!--- Create a dummy blog name in session scope (ga- I changed the logic).--->
		<cfset session.blogName = "default">
		<cfset application.dbtypes = structNew()>
		<cfset application.dbtypes["MSACCESS"] = "Microsoft Access">
		<cfset application.dbtypes["MYSQL"] = "MySQL">
		<cfset application.dbtypes["MSSQL"] = "Microsoft SQL Server">
		<cfset application.dbtypes["Oracle"] = "Oracle">

		<!--- See if we can find the ini file, if not, we abort --->
		<cfif fileExists(expandPath("../org/camden/blog/blog.ini.cfm"))>
			<cfset application.iniFile = expandPath("../org/camden/blog/blog.ini.cfm")>
		<cfelseif fileExists(expandPath("/org/camden/blog/blog.ini.cfm"))>
			<cfset application.iniFile = expandPath("/org/camden/blog/blog.ini.cfm")>
		<cfelse>

			<cfoutput>
			<p>
			Unfortunately, I had a problem finding your config file. I looked for this path: #expandPath("../org/camden/blog/blog.ini.cfm")# and this path: #expandPath("/org/camden/blog/blog.ini.cfm")#.
			I was not able to find either of these files. This means BlogCFC may be "stuck" trying to run the installer. Please contact Gregory Alexander (gregory@gregoryalexander.com) for support.
			</p>
			</cfoutput>
			<cfabort>

		</cfif>

			
	</cffunction>
</cfcomponent>


