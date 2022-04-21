<cfprocessingdirective pageencoding="utf-8">
<cfsilent>

<!---
	Name         : searchResults.cfm
	Author       : Gregory Alexander, logic from prior search.cfm template by Raymond Camden.
	Created      : December 4 2018
	Last Updated : 
	History      : Version 1 by Gregory Alexander
	Purpose		 : Provides search results.
--->

<cfparam name="URL.searchTerm" default="">
<cfparam name="URL.category" default="">
<cfparam name="URL.start" default="1">

<cfset searchTerm = left(htmlEditFormat(trim(URL.searchTerm)),255)>

<cfset cats = application.blog.getCategories()>

<!--- Create the params necessary for the getEntries cfc method.--->
<cfset params = structNew()>
<cfset params.searchTerms = searchTerm>
<!---The category is optional--->
<cfif URL.category is not "">
	<cfset params.byCat = URL.category>
</cfif>
	
<cfset params.startrow = URL.start>
<cfset params.maxEntries = application.maxEntries>
<!--- Only get released items --->
<cfset params.releasedonly = true />

<cfif len(searchTerm)>
	<cfset results = application.blog.getPost(params)>
	<cfset searched = true>
<cfelse>
	<cfset searched = false>
</cfif>

<cfset title = "Search Results">
	
<!--- Instantiate the StringUtils cfc. We are going to remove the post data using the removeTag and getTextFromBody methods. --->
<cfobject component="#application.stringUtilsComponentPath#" name="StringUtilsObj">
<!--- Also instantate the JSoup object. This will also be used to remove any HTML using the jsoupConvertHtmlToText method --->
<cfobject component="#application.jsoupComponentPath#" name="JSoupObj">

</cfsilent>
<!---<cfdump var="#results#">--->
			
<script>
	$(document).ready(function() {
		
		// create MultiSelect from select HTML element
        var categoryMultiselect = $("#category").kendoMultiSelect().data("kendoMultiSelect");
		
	});//..document.ready

</script>

<cfoutput>
<cfif searched>

There <cfif arrayLen(results) eq 1>was one result<cfelse>were #arrayLen(results)# results</cfif>.
<div id="blogPost" class="widget k-content">

<cfif arrayLen(results)>
	<cfloop from="1" to="#arrayLen(results)#" index="i">
		<cfsilent>
		<!--- Set the values --->
		<cfset postId = results[i]["PostId"]>
		<cfset title = results[i]["Title"]>
		<cfset body = results[i]["Body"]>
		<cfset posted = results[i]["DatePosted"]>
			
		<!--- Remove the XML and google structured content from the post between the postData tag --->
		<cfset newBody = StringUtilsObj.removeTag(str=body, tag='postData')>
		<!--- Now, remove the html from result. --->
		<cfset newbody = reReplace(newBody, "<.*?>", "", "all")>	
		<!--- Now use JSoup to get the text. This is duplicate logic but it should remove any and all HTML artifacts. --->
		<cfset newBody = JsoupObj.jsoupConvertHtmlToText(newbody)>
		<!--- highlight search terms --->
		<!--- Raymonds comments: Before we "highlight" our matches in the body, we need to find the first match. We will create an except that begins 250 before and ends 250 after. This will give us slightly different sized excerpts, but between you, me, and the door, I think thats ok. It is also possible the match isn't in the entry but just the title. --->
		<cfset match = findNoCase(searchTerm, newbody)>
		<cfif match lte 250>
			<cfset match = 1>
		</cfif>
		<cfset end = match + len(searchTerm) + 500>

		<cfif len(newbody) gt 500>
			<cfif match gt 1>
				<cfset excerpt = "..." & mid(newbody, match-250, end-match)>
			<cfelse>
				<cfset excerpt = left(newbody,end)>
			</cfif>
			<cfif len(newbody) gt end>
				<cfset excerpt = excerpt & "...">
			</cfif>
		<cfelse>
			<cfset excerpt = newbody>
		</cfif>	

		<!---
		We switched to regular expressions to highlight our search terms. However, it is possible for someone to search 
		for a string that isn't a valid regex. So if we fail, we just don't bother highlighting. (RC)
		--->
		<cftry>
			<cfset excerpt = reReplaceNoCase(excerpt, "(#searchTerm#)", "<span class='k-primary'>\1</span>","all")>
			<cfset newtitle = reReplaceNoCase(title, "(#searchTerm#)", "<span class='k-primary'>\1</span>","all")>
			<cfcatch>
				<!--- only need to set newtitle, excerpt already exists (RC). --->
				<cfset newtitle = title>
			</cfcatch>
		</cftry>
		</cfsilent>
		
		<span id="blogContentContainer">
			
			<table align="center" width="100%" cellpadding="4" cellspacing="4" class="#iif(i MOD 2,DE('k-content'),DE('k-alt'))#">
				<tr>
					<td colspan="2">
						<h3 class="topContent">
							<a href="#application.blog.makeLink(postId)#" class="k-content">#newtitle#</a>
						</h3>
					</td>
				</tr>
				<tr>
					<td width="45px;">
						<p class="postDate">
							<!-- We are using Kendo's 'k-primary' class to render the primary accent color background. The primay color is set by the theme that is declared. -->
							<span class="month k-primary">#dateFormat(posted, "mmm")#</span>
							<span class="day k-alt">#day(posted)#</span>
						</p>
					</td>
					<td>
						<span id="postContent" style="padding-left: 25px">#excerpt#</span>
						<br/>
					</td>
				</tr>
			</table>

		<!--- End the div and create a new div for every record. --->
		<cfif i neq arrayLen(results)>
		</div><!-- <div id="blogPost" class="widget k-content"> -->

		<div id="blogPost" class="widget k-content">
		</cfif>

	</cfloop>
	<!---<cfif results.totalEntries gte url.start + application.maxEntries>
		<p align="right">
		<cfif url.start gt 1>
			<a href="search.cfm?search=#urlEncodedFormat(searchTerm)#&amp;category=#category#&amp;start=#url.start-application.maxEntries#" class="k-content">Previous Results</a>
		<cfelse>
			Previous Entries
		</cfif>
		-
		<cfif (url.start + application.maxEntries-1) lt results.totalEntries>
			<a href="search.cfm?search=#urlEncodedFormat(searchTerm)#&amp;category=#category#&amp;start=#url.start+application.maxEntries#" class="k-content">Next Results</a>
		<cfelse>
			Next Entries
		</cfif>
		</p>
	</cfif>--->
</cfif>
	
</cfif>
</cfoutput>
	

