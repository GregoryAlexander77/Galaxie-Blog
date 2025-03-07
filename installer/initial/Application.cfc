<cfcomponent displayname="InitialInstaller" sessionmanagement="yes" clientmanagement="yes" output="false">
	<cfset this.sessionManagement="yes"/>
	<cfset this.enablerobustexception = true />
	
	<!--- Create a dummy blog name in session scope --->
	<cfset session.blogName = "default">

	<cffunction name="OnRequestStart"> 

		<!--- To get to the blog ini file, we are first going to get the current base path in the browser which should be something like 'whatverFolderOrRoot/installer/'. After getting the base path, we are going to remove the '/installer' portion of the string and point to the ini file in 'org/camden/blog/blog.ini.cfm'. The final string should be something like whatverFolderOrRoot/installer/org/camden/blog/blog.ini.cfm --->
		<cfset thisBasePath = getBasePath()>
		<!--- Get the base site URL by removing the /installer/initial folder from the baseUrl --->
		<cfset sitePath = replaceNoCase(thisBasePath, '/installer/initial', '', 'all')>
		<!--- Append '/org/camden/blog/blog.ini.cfm' to the sitePath to get the proper path to the ini file. --->
		<cfset blogIniPath = sitePath & 'org/camden/blog/blog.ini.cfm'>
			
		<!--- Abort if the blog is already installed. --->
		<cfset blogInstalled = getProfileString(blogIniPath, "default", "installed")>
		<cfif len(blogInstalled)>
			<p>This blog is already installed. 
			If you manually set the application.reinstallIni variable, set it back to false in the Application.cfc in the root directory to false to continue.
			
			Alternatively, you may reinstall the blog again by uploading a new /org/camden/blog/blog.ini.cfm file from the GitHub repo or set the installed argument to to an empty string.
			</p>
			<cfabort>
		</cfif>

		<!--- 
		Debugging 
		<cfoutput>
			getBaseUrl(): #getBasePath()#<br/>
			sitePath: #sitePath#<br/>
			blogIniPath: #blogIniPath#<br/>
			fileExists: #fileExists(expandPath(blogIniPath))#<br/>
		</cfoutput>
		--->

		<!--- See if we can find the ini file, if not, we abort --->
		<cfif fileExists(expandPath(blogIniPath))>
			<cfset application.iniFile = expandPath(blogIniPath)>
		<cfelse>

			<cfoutput>
			<p>Unfortunately, I had a problem finding your config file. The ini file does not reside at #application.iniFile#.
			Galaxie Blog may be "stuck" trying to run the installer. Please contact Gregory Alexander (gregory@gregoryalexander.com) for support.</p>
			</cfoutput>
			<cfabort>

		</cfif>

	</cffunction>

	<!--- Helper function to get the base URL. This was found at https://blog.pengoworks.com/index.cfm/2008/5/8/Getting-the-URLweb-folder-path-in-ColdFusion  --->
	<cffunction name="getBasePath" access="public" output="false" returntype="string" hint="Gets the absolute path to the current web folder.">
		<cfargument name="url" required="false" default="#getPageContext().getRequest().getRequestURI()#" hint="Defaults to the current path_info" />
		<cfargument name="ext" required="false" default="\.(cfml?.*|html?.*|[^.]+)" hint="Define the regex to find the extension. The default will work in most cases, unless you have really funky urls like: /folder/file.cfm/extra.path/info" />

		<!---// trim the path to be safe //--->
		<cfset var sPath = trim(arguments.url) />
		<!---// find the where the filename starts (should be the last wherever the last period (".") is) //--->
		<cfset var sEndDir = reFind("/[^/]+#arguments.ext#$", sPath) />

		<cfreturn left(sPath, sEndDir) />
	</cffunction>
			
</cfcomponent>


