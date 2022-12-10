<!---******************************************************************************************************
		Page Mode
******************************************************************************************************--->

<!--- Get the page mode which depends upon what the page is rendering. The page mode on the index.cfm page is 'blog', when the user is reading a post, the pageMode is post, etc.--->
<cffunction name="getPageMode" access="public" output="false" returntype="string" hint="Determines what the page is rendering.">

	<cfif not isDefined("URL.mode")>
		<cfset pageMode = "blog">	
	<cfelse>
		<cfswitch expression="#URL.mode#">
			<cfcase value="alias">
				<!--- Note: when the page is in alias mode- we will create a new strucuture and get the data from the post. --->
				<cfset pageMode = "post">
			</cfcase>
			<cfcase value="entry">
				<cfset pageMode = "post">
			</cfcase>
			<!--- Cat is depracated --->
			<cfcase value="cat">
				<cfset pageMode = "category">
			</cfcase>
			<!--- Category replaces cat --->
			<cfcase value="category">
				<cfset pageMode = "category">
			</cfcase>
			<cfcase value="postedBy">
				<cfset pageMode = "postedBy">
			</cfcase>
			<cfcase value="month">
				<cfset pageMode = "month">
			</cfcase>
			<cfcase value="day">
				<cfset pageMode = "month">
			</cfcase>
			<cfdefaultcase>
				<cfset pageMode = "blog">
			</cfdefaultcase>

		</cfswitch>
	</cfif>

	<!--- Return the pageMode value --->
	<cfreturn pageMode>

</cffunction>
				
<!---******************************************************************************************************
		Templates
******************************************************************************************************--->
				
<cffunction name="getTemplatePathByPageName" access="remote" hint="Function to determine what page template that we should process.">
	<cfargument name="pageName" required="yes" hint="What is the page name?">
	
	<cfswitch expression="#pageName#">
		<cfcase value="login">
			<cfset templatePath = "/includes/templates/login.cfm">
		</cfcase>
		<cfcase value="admin">
			<cfset templatePath = "/includes/templates/admin/htmlContent/index.cfm">
		</cfcase>
		<cfcase value="comments">
			<cfset templatePath = "/includes/templates/admin/htmlContent/comments.cfm">
		</cfcase>
	</cfswitch>
	
	<cfreturn templatePath>
</cffunction>
			
<!---******************************************************************************************************
		Footer Scripts
******************************************************************************************************--->
			
<cffunction name="getTailEndScriptByPageName" access="remote" hint="Function to determine what script we are going to invoke at the very end of the page.">
	<cfargument name="pageName" required="yes" hint="What is the page name?">
	
	<!--- Preset out return value. --->
	<cfparam name="tailEndScript" default="">
	
	<!--- Get the tail end script that we want to invoke. --->
	<cfswitch expression="#pageName#">
		<!---<cfcase value="admin">
			<cfset tailEndScript = "createAdminInterfaceWindow(1, 'recentComments');">
		</cfcase>--->
	</cfswitch>
	
	<!--- Return it --->
	<cfreturn tailEndScript>
</cffunction>
		
<!---******************************************************************************************************
		Structured data functions
******************************************************************************************************--->

<cffunction name="removeMainEntityOfPageFromPostContent" required="yes"  hint="Removes the mainEntityOfPage block from the ld json string. This is used when the blog owner (like me) hardcodes ld json, but needs to remove the mainEntityOfPage block of code when the blog is showing multipe posts (ie the homepage of the blog) as we can't have two different main identities.">
	<cfargument name="postContent" required="yes" hint="Supply the post content.">

	<!--- Set the strings that we're searching for. --->
	<cfset mainEntityStartString = '"mainEntityOfPage": {'>
	<cfset mainEntityEndString = "},">

	<!--- Find the start and end position of the mainEntityOfPage block. --->
	<cfset startPos = findNoCase(mainEntityStartString, arguments.postContent)>
	<cfset endPos = findNoCase(mainEntityEndString, arguments.postContent)>

	<!--- And determine the count --->
	<cfset mainEntityValueCount = endPos - startPos>
	<!--- Get the value in the string. --->
	<cfset mainEntityStringValue = mid(arguments.postContent, startPos, mainEntityValueCount+len(mainEntityEndString))>
	<!--- Remove the mainEntityOfPage code block from the string --->
	<cfset newJsonLdString = replaceNoCase(arguments.postContent, mainEntityStringValue, '')>

	<!--- Return it. --->
	<cfreturn newJsonLdString>
</cffunction>
			
<!---******************************************************************************************************
		Web Paths
******************************************************************************************************--->
			
<!--- Helper function to get the base URL. This was found at https://blog.pengoworks.com/index.cfm/2008/5/8/Getting-the-URLweb-folder-path-in-ColdFusion  --->
<cffunction name="getWebPath" access="public" output="false" returntype="string" hint="Gets the absolute path to the current web folder.">
	<cfargument name="url" required="false" default="#getPageContext().getRequest().getRequestURI()#" hint="Defaults to the current path_info" />
	<cfargument name="ext" required="false" default="\.(cfml?.*|html?.*|[^.]+)" hint="Define the regex to find the extension. The default will work in most cases, unless you have really funky urls like: /folder/file.cfm/extra.path/info" />

	<!---// trim the path to be safe //--->
	<cfset var sPath = trim(arguments.url) />
	<!---// find the where the filename starts (should be the last wherever the last period (".") is) //--->
	<cfset var sEndDir = reFind("/[^/]+#arguments.ext#$", sPath) />

	<cfreturn left(sPath, sEndDir) />
</cffunction>
