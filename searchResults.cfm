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
	
<!--- Include the resource bundle. --->
<cfset getResourceBundle = application.utils.getResource>
<!--- Include the UDF (this is not automatically included when using an application.cfc) --->
<cfinclude template="includes/udf.cfm">

<cfparam name="URL.searchTerm" default="">
<cfparam name="URL.category" default="">
<cfparam name="URL.start" default="1">

<cfset searchTerm = left(htmlEditFormat(trim(URL.searchTerm)),255)>

<cfset cats = application.blog.getCategories()>

<!---Create the params necessary for the getEntries cfc method.--->
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
	<cfset results = application.blog.getEntries(params)>
	<cfset searched = true>
<cfelse>
	<cfset searched = false>
</cfif>

<cfset title = getResourceBundle("search")>
	
<cffunction name="removePostData" access="public" output="true" returntype="string" hint="Removes everything between data found in the post content. Used by the search results template.">
	<cfargument name="postContent" required="yes" hint="The post content is typically 'application.blog.renderEntry(body,false,enclosure)'.">

	<!--- Set the strings that we're searching for. --->
	<cfset keyWordStartString = "<postData>">
	<cfset keyWordEndString = "</postData>">

	<!--- Find the start and end position of the keywords. --->
	<cfset postDataStartPos = findNoCase(keyWordStartString, arguments.postContent)>
	<cfset postDataEndPos = findNoCase(keyWordEndString, arguments.postContent)>

	<!--- Add the lengh of the keyword to get the proper start position. --->
	<cfset keyWordValueStartPos = postDataStartPos + len(postDataStartPos)>
	<!--- And determine the count --->
	<cfset valueCount = postDataEndPos - postDataStartPos>
	<!--- Get the value in the xml string. --->
	<cfset postData = mid(arguments.postContent, keyWordValueStartPos, valueCount)>

	<!--- Strip it out. --->
	<cfset strippedPostContent = replaceNoCase(arguments.postContent, postData, "", "all")>
	<!--- Rip out the '</postData>' tag --->
	<cfset strippedPostContent = replaceNoCase(strippedPostContent, "</postData>", "", "all")>

	<!--- Return new post content --->
	<cfreturn strippedPostContent>

</cffunction>
</cfsilent>
			
<script>
	$(document).ready(function() {
		
		// create MultiSelect from select HTML element
        var categoryMultiselect = $("#category").kendoMultiSelect().data("kendoMultiSelect");
		
	});//..document.ready

</script>

<cfoutput>
<cfif searched>

There  <cfif results.totalEntries is 1>was one result<cfelse>were #numberFormat(results.totalEntries)# results</cfif>.
<div id="blogPost" class="widget k-content">

<cfif results.entries.recordCount>
	<cfloop query="results.entries">
		<cfsilent>
		<!--- Remove the XML and google structured content from the post. --->
		<cfset newBody = removePostData(body)>
		<!--- Now, remove the html from result. --->
		<cfset newbody = reReplace(newBody, "<.*?>", "", "all")>	
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
			<h3 class="topContent">
				<a href="#application.blog.makeLink(id)#" class="k-content">#newtitle#</a>
			</h3>
			<table align="center" class="k-content" width="100%" cellpadding="0" cellspacing="0">
				<tr>
					<td>
						<p class="postDate">
							<!-- We are using Kendo's 'k-primary' class to render the primary accent color background. The primay color is set by the theme that is declared. -->
							<span class="month k-primary">#dateFormat(posted, "mmm")#</span>
							<span class="day k-alt">#day(posted)#</span>
						</p>
					</td>
					<td>
						<span id="postContent" style="padding-left: 25px">#excerpt#</span>
						<cfif enclosure contains "mp3">
							<cfset alternative=replace(getFileFromPath(enclosure),".mp3","") />
							<div class="audioPlayerParent">
								<div id="#alternative#" class="audioPlayer">
								</div>
							</div>
							<!--- Mp3 player --->
							<script type="text/javascript">
								// <![CDATA[
									var flashvars = {};
									// unique ID
									flashvars.playerID = "#alternative#";
									// load the file
									flashvars.soundFile= "#application.rooturl#/enclosures/#getFileFromPath(enclosure)#";
									// Load width and Height again to fix IE bug
									flashvars.width = "470";
									flashvars.height = "24";
									// Add custom variables
									var params = {};
									params.allowScriptAccess = "sameDomain";
									params.quality = "high";
									params.allowfullscreen = "true";
									params.wmode = "transparent";
									var attributes = false;
									swfobject.embedSWF("#application.rooturl#/includes/audio-player/player.swf", "#alternative#", "470", "24", "8.0.0","/includes/audio-player/expressinstall.swf", flashvars, params, attributes);
								// ]]>
							</script>
						</cfif><!---<cfif enclosure contains "mp3">--->
						<br/>
					</td>
				</tr>
			</table>

		<!--- End the div and create a new div for every record. --->
		<cfif currentRow neq recordCount>
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
	

