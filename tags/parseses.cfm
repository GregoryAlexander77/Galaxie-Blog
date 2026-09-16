<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : parseses.cfm
	Author       : Raymond Camden/Gregory Alexander 
				 : Other edits by Gregory Alexander, check GitHub for more information.
	Purpose		 : Attempts to find SES info in URL and set URL vars
	Desc		 : This template gets the number of forward slashes in a year and determines what is being sent by the positions of the elements in the URL.

If there is one forward slash this assumes it is a category: /galaxie-blog-2025-roadmap
Tags are sent via the URL like so: tag/galaxie-blog-2025-roadmap
Author links are: postedby/Gregory_Alexander
 
Important note: the URL and param variables that are used in this function are set in three places, parseses.cfm, getMode.cfm, and in the getPost method in blog.cfc. I need to consolidate this logic in the future.
--->

<cfscript>
/**
 * Parses my SES format. A blog post uses /YYYY/MMMM/TITLE or /YYYY/MMMM/DDDD/TITLE
 * 
 */ 
function parseMySES() {
	var urlVars=reReplaceNoCase(trim(cgi.path_info), '.+\.cfm/? *', '');
	var r = structNew();
	var theLen = listLen(urlVars,"/");
	
	/** Debugging
	writeOutput('urlVars:' & urlVars);
	writeOutput('theLen:' & theLen);
	 */ 
	
	/* Return an empty struct if there are no URL vars or the number of URL variables exceeds 4 */
	if (len(urlVars) is 0 or urlvars is "/" or len(theLen) GT 4) return r;
	
	// handles categories and pages
	if (theLen is 1) {
		urlVars = replace(urlVars, "/","");
		// See if the page exists
		if (application.blog.pageExists(postAlias=urlVars)){
			r.pageName = urlVars;	
		} else {
			// We assume that it's a category
			r.categoryName = urlVars;
		}
		return r;
	}
	
	// handles tags
	if (theLen is 2 and urlVars contains "tag") {
		urlVars = replace(urlVars, "/tag/","");
		r.tagName = urlVars;	
		return r;
	}
	
	// handles users (aka posters, authors)
	if (theLen is 2 and urlVars contains "postedby") {
		urlVars = replace(urlVars, "/postedby/","");
		r.postedby = urlVars;	
		return r;
	}

	r.year = listFirst(urlVars,"/");
	if (theLen gte 2) r.month = listGetAt(urlVars,2,"/");
	if (theLen gte 3) r.day = listGetAt(urlVars,3,"/");
	if (theLen gte 4) r.title = listLast(urlVars, "/");
	return r;
}
</cfscript>
<!---<cfdump var="#parseMySES()#" label="ses">--->

<!--- Try to load my info from the URL ... --->
<cfset sesInfo = parseMySES()> 

<!--- I don't have the right info, so we are outa here! --->
<cfif structIsEmpty(sesInfo)>
	<cfsetting enablecfoutputonly=false>
	<cfexit method="exitTag">
</cfif>

<cfset params = structNew()>
	
<!--- Handle pages --->
<cfif structKeyExists(sesInfo, "pageName")>
	<cfset params.byAlias = sesInfo.pageName>
	<cfset url.mode = 'page'>
	<cfset url.alias = params.byAlias>
	
<!--- Handle a category --->
<cfelseif structKeyExists(sesInfo, "categoryName")>

	<cfif len(trim(sesInfo.categoryName)) and len(trim(sesInfo.categoryName)) lte 50>
		<!--- Set the URL mode, get the categoryId and save it. --->
		<cfset getCategory = application.blog.getCategory(CategoryAlias=sesInfo.categoryName)>
		<cfif arrayLen(getCategory) and len(getCategory[1]["CategoryId"])>
			<cfset url.mode = "category">
			<cfset url.categoryId = getCategory[1]["CategoryId"]>
		</cfif>
	</cfif>
			
<!--- We have a tag --->
<cfelseif structKeyExists(sesInfo, "tagName")>
	
	<!--- Set the URL mode, get the tagId and save it. --->
	<cfset getTag = application.blog.getTag(TagAlias=sesInfo.tagName)>
	<cfif arrayLen(getTag) and len(getTag[1]["TagId"])>
		<cfset url.mode = "tag">
		<cfset url.tagId = getTag[1]["TagId"]>
	</cfif>
	
<!--- We have a blog poster/user/author --->
<cfelseif structKeyExists(sesInfo, "postedby")>

	<cfif len(trim(sesInfo.postedby)) and len(trim(sesInfo.postedby)) lte 50>
		<!--- Set the mode and user name --->
		<cfset username = application.blog.getUserByName(sesInfo.postedby)>
		<cfif len(username)>
			<cfset url.mode = "postedby">
			<cfset URL.authorName = sesInfo.postedby>
			<cfset url.postedby = username>
		</cfif>
	</cfif>

<!--- By month --->
<cfelseif not structKeyExists(sesInfo, "title")>

	<cfset url.month = sesInfo.month>
	<cfset url.year = sesInfo.year>
	
	<cfif structKeyExists(sesInfo, "day")>
		<cfset url.day = sesInfo.day>
		<cfset url.mode = "day">
	<cfelse>
		<cfset url.mode = "month">
	</cfif>
	
<!--- This is a full blog entry --->
<cfelse>

	<!--- The blog checks, but lets be extra careful --->
	<cfif not isNumeric(sesInfo.year) or not isNumeric(sesInfo.month) or not (sesInfo.month gte 1 and sesInfo.month lte 12) or not len(trim(sesInfo.title))>
		<cfsetting enablecfoutputonly=false>
		<cfexit method="exitTag">
	</cfif>
	
	<cfset params.byMonth = sesInfo.month>
	<cfset params.byYear = sesInfo.year>
	<cfif structKeyExists(sesInfo,"day")>
		<cfset params.byDay = sesInfo.day>
	</cfif>
	
	<cfset params.byAlias = sesInfo.title>
	<cfset url.mode = "alias">
	<cfset url.alias = params.byAlias>

</cfif>	
<!---<cfdump var="#URL#" label="url set in parseses">--->

<!--- Return vars --->
<cfset caller.params = params>

<cfsetting enablecfoutputonly=false>
<cfexit method="exitTag">