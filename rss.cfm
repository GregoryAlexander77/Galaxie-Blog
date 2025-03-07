<cfsetting enablecfoutputonly=true showdebugoutput=false>
<!---
	Name         : RSS
	Author       : Raymond Camden / Gregory Alexander
	Created      : March 12, 2003
	Last Updated : Please see the Galaxie Blog Git hub repo.
	Purpose		 : Blog RSS feed.
--->

<cfif isDefined("url.mode") and url.mode is "full">
	<cfset mode = "full">
<cfelse>
	<cfset mode = "short">
</cfif>

<!--- only allow 1 or 2 --->
<cfif isDefined("url.version") and url.version is 1>
	<cfset version = 1>
<cfelse>
	<cfset version = 2>
</cfif>

<cfset params = structNew()>
<!---// dgs: only get released items //--->
<cfset params.releasedonly = true />

<cfset additionalTitle = "">

<!--- Set params and get the data. --->
<cfif isDefined("url.mode2")>
	<cfif url.mode2 is "day" and isDefined("url.day") and isDefined("url.month") and isDefined("url.year")>
		<cfset params.byDay = val(url.day)>
		<cfset params.byMonth = val(url.month)>
		<cfset params.byYear = val(url.year)>
	<cfelseif url.mode2 is "month" and isDefined("url.month") and isDefined("url.year")>
		<cfset params.byMonth = val(url.month)>
		<cfset params.byYear = val(url.year)>
	<cfelseif url.mode2 is "cat" and isDefined("url.catid")>
		<!--- can be a list --->
		<cfset additionalTitle = "">
		<cfset params.byCat = "">
		<cfloop index="x" from="1" to="#listLen(url.catid)#">
			<cfset categoryId = listGetAt(url.catid, x)>
			<cfset params.byCat = listAppend(params.byCat, categoryId)>
			<cftry>
				<cfset additionalTitle = additionalTitle & " - " & application.blog.getCategory(categoryId)[1]["CategoryName"]>
				<cfcatch></cfcatch>
			</cftry>
		</cfloop>
	<cfelseif url.mode2 is "entry">
		<cfset params.byEntry = left(url.entry,35)>
	</cfif>
</cfif>

<!--- Only cache if not isdefined mode 2 --->
<!--- In other words, cache just the main view --->
<!--- Therefore, our cache name needs to just care about mode and version --->
<cfset cachename = application.applicationname & "_rss_" & mode & version>
<cfif structKeyExists(url, "mode2") or application.disableCache>
	<cfset disabled = true>
<cfelse>
	<cfset disabled = false>
</cfif>

<!--- Note: this is being cached. I typically removed all of the caching features that were in the initial blog, but I like this one... it gives me time to think about things and perfect the post once it is released. Comment out this code and uncomment the line below it to see a realtime feed. --->
<cfsavecontent variable="variables.feedXML">
	<cfmodule template="tags/scopecache.cfm" cachename="#cachename#" scope="application" timeout="#application.timeout#" disabled="#disabled#">
		<cfoutput>
			#application.blog.generateRSS(mode=mode,params=params,version=version,additionalTitle=additionalTitle)#
		</cfoutput>
	</cfmodule>
</cfsavecontent>

<cfset variables.lastModified = XMLSearch ( XMLParse ( variables.feedXML ), '//item[1]/pubDate' ) />
<cfif arrayLen(variables.lastModified) is 0>
	<cfset variables.lastModified = "">
<cfelse>
	<cfset variables.lastModified = variables.lastModified[1]["XMLText"] />
</cfif>
<cfset variables.ETag = hash ( variables.lastModified ) />

<cfset variables.request = getHTTPRequestData() />
<cfset variables.headers = variables.request.headers />

<cfif structKeyExists ( variables.headers, 'If-Modified-Since' ) and variables.headers['If-Modified-Since'] eq variables.lastModified>
	<cfif structKeyExists ( variables.headers, 'If-None-Match' ) and variables.headers['If-None-Match'] eq variables.ETag>
		<cfheader statuscode="304" statustext="Not Modified" />
		<cfexit />
	</cfif>
</cfif>

<cftry>
	<cfheader name="Last-Modified" value="#variables.lastModified#" />
	<cfheader name="ETag" value="#variables.ETag#" />
	
	<cfcontent type="text/xml; charset=utf-8"><cfoutput>#variables.feedXML#</cfoutput>
	<cfcatch>
		<!--- Logic is - if they filtered incorrectly, revert to default, if not, abort --->
		<cfif cgi.query_string neq "">
			<cflocation url="rss.cfm">
		<cfelse>
			<cfabort>
		</cfif>
	</cfcatch>
</cftry>