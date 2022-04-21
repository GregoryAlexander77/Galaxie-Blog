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
	
<!--- Cache notes: We're saving this to the application scope. We need to differentiate between the dark theme and light themes in the key. The timeout is set to 30 minutes --->
<cfif sideBarType eq "div">
	<cfset cacheName = "recentPosts">
</cfif>
<!--- Dark theme --->
<cfif darkTheme>
	<cfset cacheName = cacheName & "Dark">
</cfif>

<!--- Get the new recent posts --->
<cfset recentPosts = application.blog.getRecentPosts()>
</cfsilent>
			<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#60*30#" disabled="#application.disableCache#">
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
				<br/>
			</cfmodule>