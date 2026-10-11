<cfsetting enablecfoutputonly=true showdebugoutput=false>
<!---
	Name         : Atom
	Author       : Gregory Alexander
	Created      : October 9, 2026
	Purpose		 : Blog Atom 1.0 feed, alongside rss.cfm (added on request). Takes the same URL options as rss.cfm -
				   mode=full, mode2=day/month/cat/entry, category=, tag= - and lists the same posts; see
				   blog.cfc's generateAtom().
--->

<cfif isDefined("url.mode") and url.mode is "full">
	<cfset mode = "full">
<cfelse>
	<cfset mode = "short">
</cfif>

<cfset params = structNew()>
<cfset params.releasedonly = true />
<cfset additionalTitle = "">

<cfif isDefined("url.mode2")>
	<cfif url.mode2 is "day" and isDefined("url.day") and isDefined("url.month") and isDefined("url.year")>
		<cfset params.byDay = val(url.day)>
		<cfset params.byMonth = val(url.month)>
		<cfset params.byYear = val(url.year)>
	<cfelseif url.mode2 is "month" and isDefined("url.month") and isDefined("url.year")>
		<cfset params.byMonth = val(url.month)>
		<cfset params.byYear = val(url.year)>
	<cfelseif url.mode2 is "cat" and isDefined("url.catid")>
		<cfset params.byCat = "">
		<cfloop index="x" from="1" to="#listLen(url.catid)#">
			<cfset categoryId = listGetAt(url.catid, x)>
			<cfset params.byCat = listAppend(params.byCat, categoryId)>
			<cftry>
				<cfset additionalTitle = additionalTitle & " - " & application.blog.getCategory(categoryId)[1]["CategoryName"]>
				<cfcatch></cfcatch>
			</cftry>
		</cfloop>
	<cfelseif url.mode2 is "entry" and isDefined("url.entry")>
		<cfset params.byEntry = left(url.entry,35)>
	</cfif>
</cfif>

<!--- The feed's own address, for Atom's rel="self" link and the feed id. --->
<cfset selfUrl = replaceNoCase(application.blogHostUrl, "/index.cfm", "") & "/atom.cfm" & (len(cgi.query_string) ? "?" & cgi.query_string : "")>

<cftry>
	<cfset feedXML = application.blog.generateAtom(mode=mode, params=params, additionalTitle=additionalTitle, selfUrl=selfUrl)>

	<!--- Let feed readers skip downloading an unchanged feed: the ETag changes whenever the newest entry's date does. --->
	<cfset newestUpdated = XMLSearch(XMLParse(feedXML), "/*[local-name()='feed']/*[local-name()='updated']")>
	<cfset eTag = '"' & hash(arrayLen(newestUpdated) ? newestUpdated[1].XmlText & mode & cgi.query_string : now()) & '"'>
	<cfset requestHeaders = getHTTPRequestData().headers>
	<cfif structKeyExists(requestHeaders, "If-None-Match") and requestHeaders["If-None-Match"] eq eTag>
		<cfheader statuscode="304">
		<cfexit>
	</cfif>
	<cfheader name="ETag" value="#eTag#">

	<cfcontent type="application/atom+xml; charset=utf-8" reset="true"><cfoutput>#feedXML#</cfoutput>
	<cfcatch>
		<!--- Same as rss.cfm: a bad filter falls back to the plain feed; otherwise stop. --->
		<cfif cgi.query_string neq "">
			<cflocation url="atom.cfm" addtoken="false">
		<cfelse>
			<cfabort>
		</cfif>
	</cfcatch>
</cftry>
