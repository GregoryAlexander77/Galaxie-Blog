<cfsetting enablecfoutputonly=true showdebugoutput=false>
<cfprocessingdirective pageencoding="utf-8">
<!--- Note to self- don't forget to add pages when they come online in the next version. I should probably update this again in the next version as well --->

<cfset params = structNew()>
<!--- This should be good for a while.... --->
<cfset params.maxEntries = 99999>

<!--- Get the posts ( getPost(params, showPendingPosts, showRemovedPosts, showJsonLd, showPromoteAtTopOfQuery) ). 
Original code: <cfset getPosts = application.blog.getPost(params, false, false, false, false)>
--->
<cfinvoke component="#application.blog#" method="getPost" returnvariable="getPosts">
	<cfinvokeargument name="params" value="#params#">
	<!--- Show both blog posts and pages --->
	<cfinvokeargument name="showPages" value="true">
	<cfinvokeargument name="showBlogPosts" value="true">
	<cfinvokeargument name="showPendingPosts" value="false">
	<cfinvokeargument name="showRemovedPosts" value="false">
	<cfinvokeargument name="showJsonLd" value="false">
	<cfinvokeargument name="showPromoteAtTopOfQuery" value="false">
</cfinvoke>

<!--- Time zone logic --->
<cfset z = getTimeZoneInfo()>
<cfif not find("-", z.utcHourOffset)>
	<cfset utcPrefix = "-">
<cfelse>
	<cfset z.utcHourOffset = right(z.utcHourOffset, len(z.utcHourOffset) -1 )>
	<cfset utcPrefix = "+">
</cfif>

<!--- lastmod (2026-11-09, owner: "how does google know when to search the docs after an update"): the day a post or page was
last saved (Post.Date, which every save sets, and which the JSON-LD's dateModified already uses), or the day it was posted when
that is later (a post scheduled for the future). It used to be the date posted only, so an edited page never looked changed to
Google. A date without a time is valid in a sitemap and avoids getting the time zone wrong. The home page gets the newest of them. --->
<cffunction name="sitemapLastMod" returntype="string" output="false">
	<cfargument name="post" type="struct" required="true">
	<cfset var lastDate = arguments.post["DatePosted"]>
	<cfif isDate(arguments.post["Date"] ?: "") and (not isDate(lastDate) or dateCompare(arguments.post["Date"], lastDate, "d") gt 0)>
		<cfset lastDate = arguments.post["Date"]>
	</cfif>
	<cfreturn isDate(lastDate) ? dateFormat(lastDate, "yyyy-mm-dd") : dateFormat(now(), "yyyy-mm-dd")>
</cffunction>
<cfset dateStr = dateFormat(now(), "yyyy-mm-dd")>
<cfif arrayLen(getPosts)>
	<cfset dateStr = "">
	<cfloop from="1" to="#arrayLen(getPosts)#" index="i">
		<cfset thisLastMod = sitemapLastMod(getPosts[i])>
		<cfif thisLastMod gt dateStr><cfset dateStr = thisLastMod></cfif>
	</cfloop>
</cfif>
		
<!--- If the application.serverRewriteRuleInPlace variable has been set to true, we need to eliminate 'index.cfm' from the URL --->
<cfif application.serverRewriteRuleInPlace>
	<cfset blogUrl = replaceNoCase(application.blogHostUrl, 'index.cfm', '')>
<cfelse>
	<cfset blogUrl = application.blogHostUrl>
</cfif>

<cfcontent type="text/xml" reset="true"><cfoutput><?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
	<url>
		<loc>#blogUrl#/</loc>
    	<lastmod>#dateStr#</lastmod>
		<changefreq>hourly</changefreq>
		<priority>0.8</priority>
	</url>
	</cfoutput>
	<!--- Loop through the posts array --->
	<cfloop from="1" to="#arrayLen(getPosts)#" index="i">
		<!--- Set the link to the post --->
		<!--- The following original code required an additional query to the database
		<cfset postLink = application.blog.makeLink(getPosts[i]["PostId"])>
		--->
		<cfset postLink = application.blog.makeLink(
			   isPage=getPosts[i]["IsPage"], 
			   postAlias=getPosts[i]["PostAlias"], 
			   datePosted=getPosts[i]["DatePosted"]
		)>
		<!--- If the application.serverRewriteRuleInPlace variable has been set to true, we need to eliminate 'index.cfm' from the URL --->
		<cfif application.serverRewriteRuleInPlace>
			<cfset postLink = replaceNoCase(postLink, '/index.cfm', '')>
		<cfelse>
			<cfset postLink = postLink>
		</cfif>
		<cfset dateStr = sitemapLastMod(getPosts[i])>
		<cfoutput>
		<url>
		<loc>#xmlFormat(postLink)#</loc>
		<lastmod>#dateStr#</lastmod>
		</url>
		</cfoutput>
	</cfloop>
<cfoutput>
</urlset>
</cfoutput>
<cfsetting enablecfoutputonly=false showdebugoutput=false>