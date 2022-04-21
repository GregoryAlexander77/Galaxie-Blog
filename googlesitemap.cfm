<cfsetting enablecfoutputonly=true showdebugoutput=false>
<cfprocessingdirective pageencoding="utf-8">
<!--- Note to self- don't forget to add pages when they come online in the next version. I should probably update this again in the next version as well --->

<cfset params = structNew()>
<!--- This should be good for a while.... --->
<cfset params.maxEntries = 99999>
<cfset params.mode = "short">

<!--- Get the posts. --->
<cfset getPosts = application.blog.getPost(params, false)>

<!--- Time zone logic --->
<cfset z = getTimeZoneInfo()>
<cfif not find("-", z.utcHourOffset)>
	<cfset utcPrefix = "-">
<cfelse>
	<cfset z.utcHourOffset = right(z.utcHourOffset, len(z.utcHourOffset) -1 )>
	<cfset utcPrefix = "+">
</cfif>

<!--- If there are posts, get the most recent post and set the date --->
<cfif arrayLen(getPosts)>
	<cfset dateStr = dateFormat(getPosts[1]["DatePosted"],"yyyy-mm-dd")>
	<cfset dateStr = dateStr & "T" & timeFormat(getPosts[1]["DatePosted"],"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & ":00">
<cfelse>
	<cfset dateStr = dateFormat(now(),"yyyy-mm-dd") & "T" & timeFormat(now(),"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & ":00">
</cfif>
		
<!--- If the application.serverRewriteRuleInPlace variable has been set to true, we need to eliminate 'index.cfm' from the URL --->
<cfif application.serverRewriteRuleInPlace>
	<cfset blogUrl = replaceNoCase(application.rootURL, 'index.cfm', '')>
<cfelse>
	<cfset blogUrl = application.rootURL>
</cfif>

<cfcontent type="text/xml" reset="true"><cfoutput><?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.google.com/schemas/sitemap/0.84"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.google.com/schemas/sitemap/0.84
	http://www.google.com/schemas/sitemap/0.84/sitemap.xsd">
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
		<cfset postLink = application.blog.makeLink(getPosts[i]["PostId"])>
		<!--- If the application.serverRewriteRuleInPlace variable has been set to true, we need to eliminate 'index.cfm' from the URL --->
		<cfif application.serverRewriteRuleInPlace>
			<cfset postLink = replaceNoCase(postLink, '/index.cfm', '')>
		<cfelse>
			<cfset postLink = postLink>
		</cfif>
		<cfset dateStr = dateFormat(getPosts[i]["DatePosted"],"yyyy-mm-dd")>
		<cfset dateStr = dateStr & "T" & timeFormat(getPosts[i]["DatePosted"],"HH:mm:ss") & utcPrefix & numberFormat(z.utcHourOffset,"00") & ":00">
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