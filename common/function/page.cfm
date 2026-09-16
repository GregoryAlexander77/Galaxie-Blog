<!---******************************************************************************************************
		Page Mode
******************************************************************************************************--->

<!--- 
Get the page mode which depends upon what the page is rendering. The page mode on the index.cfm page is 'blog', when the user is reading a post, the pageMode is post, etc.
Important note: the URL and param variables that are used in this function are set in three places, parseses.cfm, getMode.cfm, and in the getPost method in blog.cfc. I need to consolidate this logic in the future.
--->
<cffunction name="getPageMode" access="public" output="false" returntype="string" hint="Determines what the page is rendering.">

	<cfif pageTypeId eq 9 and isDefined("postId")>
		<!--- The postId is defined when using an external page --->
		<cfset pageMode = "post">
	<cfelseif not isDefined("URL.mode")>
		<cfset pageMode = "blog">	
	<cfelse>
		<cfswitch expression="#URL.mode#">
			<!--- Note: when in post mode- we will create a new strucuture and get the data to display a single post. This applies to the next 3 blocks. --->
			<cfcase value="page">
				<cfset pageMode = "post">
			</cfcase>
			<cfcase value="alias">
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
				
<!--- 
Determine if the post is a page. This uses URL variables, if available, to make this determination.
--->
<cffunction name="isPageMode" access="public" output="false" returntype="boolean" hint="Determine if the post is a page. This uses URL variables, if available, to make this determination.">
	
	<!--- Preset the var --->
	<cfset isPage = false>
	
		<!--- Reset it if the isPage URL var is set --->
	<cfif structKeyExists(URL, "isPage")>
		 <cfif URL.isPage>
			<cfset isPage = true>
		</cfif>
	</cfif>
	<cfreturn isPage>
</cffunction>

<!---******************************************************************************************************
		Cache
******************************************************************************************************--->

<!---
Builds a theme- and device-aware cache key, e.g. buildCacheKey("font", themeId) -> "fontThemeId=3Mobile".
Centralizes the mobile-suffix logic that was previously duplicated at each cache-key call site in index.cfm.
--->
<cffunction name="buildCacheKey" access="public" output="false" returntype="string" hint="Builds a cache key of the form {prefix}ThemeId={themeId}[Mobile].">
	<cfargument name="prefix" type="string" required="true" hint="Cache key prefix, e.g. 'font', 'topMenu', 'footer'.">
	<cfargument name="themeId" type="string" required="true" hint="The current theme id.">
	<cfreturn arguments.prefix & "ThemeId=" & arguments.themeId & (session.isMobile ? "Mobile" : "")>
</cffunction>

<!---
Applies the "XML keyword overrides a database-derived fallback" pattern used throughout coreLogic.cfm's
video-metadata and SEO meta-tag sections. If keywordName is embedded in the post header XML, its value wins;
otherwise the caller-supplied fallback (already computed by the caller) is used.
--->
<cffunction name="getXmlOverride" access="public" output="false" returntype="string" hint="Returns the XML-embedded keyword value if present, otherwise the supplied fallback.">
	<cfargument name="xmlKeywords" type="string" required="true">
	<cfargument name="postHeader" type="string" required="true">
	<cfargument name="keywordName" type="string" required="true">
	<cfargument name="fallback" type="string" default="">
	<cfif findNoCase(arguments.keywordName, arguments.xmlKeywords) gt 0>
		<cfreturn application.blog.getXmlKeywordValue(arguments.postHeader, arguments.keywordName)>
	</cfif>
	<cfreturn arguments.fallback>
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
			<cfset templatePath = "/includes/templates/admin/index.cfm">
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
