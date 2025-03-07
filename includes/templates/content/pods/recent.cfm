<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : recent.cfm
	Author       : Raymond Camden/Gregory Alexander 
	Created      : October 29, 2003
	Last Updated : 8/11/2020
	History      : added processingdir (rkc 11/10/03)
				   New link code (rkc 7/12/05)
				   Hide future entries (rkc 6/1/07)
				   Removed classes and formatting (ga 11/04/2018). ORM 8/11/2020. 
	Purpose		 : Display recent entries
--->
	
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "recentPostsPod">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- This template drives the navigation menu and is a unordered HTML list. This template uses the getPageContent function to determine the content. It will display custom content that is in the database or use the default code below if no custom code exists  --->
<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
	<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
	<cfinvokeargument name="isMobile" value="#session.isMobile#">
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<cfinvokeargument name="themeRef" value="#URL.optArgs#">
	</cfif>
</cfinvoke>		
<!--- Determine if we should display the data or use the default HTML --->
<cfif len(contentOutputData)>
	<cfset displayContentOutputData = true>		
</cfif>
<!--- ********* End content template logic *********--->
	
<!--- Get the new recent posts --->
<cfset recentPosts = application.blog.getRecentPosts()>
	
<!--- Cache notes: We're saving this to the application scope. We need to differentiate between the dark theme and light themes in the key. The timeout is set to 30 minutes --->
<cfif session.isMobile>
	<cfset cacheName = "recentPostsMobile">
<cfelse>
	<cfset cacheName = "recentPosts">
</cfif>
<!--- Dark theme --->
<cfif darkTheme>
	<cfset cacheName = "recentPostsDark">
</cfif>

</cfsilent>
		<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#60*30#" disabled="#application.disableCache#">
			<cfif displayContentOutputData>
				<!--- Include the custom user defined content from the database --->
				<cfoutput>#contentOutputData#</cfoutput>
			<cfelse>
				<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
					<cfif not arrayLen(recentPosts)>
						<tr>
							<td class="k-content">
							<cfoutput>There are no recent posts.</cfoutput>
							</td>
						</tr>
					</cfif>
				<!--- Set a loop counter to mimic ColdFusion's currentRow --->
				<cfparam name="recentPostLoopCount" default="1">
				<!--- Loop through the array --->
				<cfloop from="1" to="#arrayLen(recentPosts)#" index="i">
					<cfsilent>
					<!--- Set the values. --->
					<cfset recentPostUuid = recentPosts[i]["PostUuid"]>
					<cfset recentPostId = recentPosts[i]["PostId"]>
					<cfset recentPostTitle = recentPosts[i]["Title"]>
					<cfif application.serverRewriteRuleInPlace>
						<cfset entryLink = replaceNoCase(application.blog.makeLink(recentPostId), '/index.cfm', '')>
					<cfelse>
						<cfset entryLink = application.blog.makeLink(recentPostId)>
					</cfif>
					</cfsilent>
					<cfoutput>
					<tr class="#iif(recentPostLoopCount MOD 2,DE('k-content'),DE('k-alt'))#">
						<!---Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
						We will create a border between the rows if the current row is not the first row. --->
						<cfif recentPostLoopCount eq 1>
							<td>
						<cfelse>
							<td align="left" class="border" height="20px">
						</cfif>
						<a href="#entryLink#" aria-label="#recentPostTitle#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#recentPostTitle#</a>
						</td>
					</tr>
					</cfoutput>
					<cfset recentPostLoopCount = recentPostLoopCount + 1>
				</cfloop>
				</table>
			</cfif>
			<br/>
		</cfmodule>