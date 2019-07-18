<cfprocessingdirective pageencoding="utf-8">

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

<!--- Set default params --->
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
	
<!---
<script>
	
	function postSearchTerm(){
		// Get the value of the forms
		var searchTerm = $( "#siteSearchField" ).val();
		var category = $( "#category" ).val();
		var startRow = $( "#startRow" ).val();
		var maxEntries = <cfoutput>#application.maxEntries#</cfoutput>;

		// Submit form via AJAX.
		$.ajax({
			type: 'post', 
			// This posts to the proxy controller as it needs to have session vars and performs client side operations.
			url: "<cfoutput>#application.proxyControllerUrl#</cfoutput>?method=getSiteSearchResults",
			data: {
				searchTerm: searchTerm,
				category: category,
				startRow: startRow,
				endRow: startRow+25
			},//..data: {
			dataType: "json",
			cache: false,
			success: function(data) {
				setTimeout(function () {
					searchResult(data);
				}, 500);//..setTimeout(function () {
			}//..success: function(data) {
		});//..$.ajax({

		// Open the plese wait window. Note: the ExtWaitDialog's are mine and not a part of the Kendo official library. I designed them as I prefer my own dialog design over Kendo's dialog offerings.
		$.when(kendo.ui.ExtWaitDialog.show({ title: "Please wait...", message: "Searching.", icon: "k-ext-information" }));
		// Use a quick set timeout in order for the data to load.
		setTimeout(function() {
			// Close the wait window that was launched in the calling function.
			kendo.ui.ExtWaitDialog.hide();
		}, 500);
		// Get a reference to the add comment window
		var searchWindow = $("#searchWindow").data("kendoWindow");
		// Close the add comment window
		searchWindow.close();
		// Return false in order to prevent any potential redirection.
		return false;
	}//..function postSearchTerm(){
	
	function searchResults(){
		
	}

	$(document).ready(function() {
		
		// create MultiSelect from select HTML element
        var categoryMultiselect = $("#category").kendoMultiSelect().data("kendoMultiSelect");
		
	});//..document.ready

</script>
--->
	
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
		<!--- remove html from result. --->
		<cfset newbody = rereplace(body, "<.*?>", "", "all")>
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
		for a string that isn't a valid regex. So if we fail, we just don't bother highlighting.
		--->
		<cftry>
			<cfset excerpt = reReplaceNoCase(excerpt, "(#searchTerm#)", "<span class='k-primary'>\1</span>","all")>
			<cfset newtitle = reReplaceNoCase(title, "(#searchTerm#)", "<span class='k-primary'>\1</span>","all")>
			<cfcatch>
				<!--- only need to set newtitle, excerpt already exists. --->
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
	

