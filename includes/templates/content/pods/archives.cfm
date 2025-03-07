<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : archives.cfm
	Author       : Raymond Camden 
	Created      : October 29, 2003
	Last Updated : November 4 2018 (Gregory added the Kendo UI)
	History      : Use SES urls (rkc 4/18/06)
				 : don't hide empty cats (rkc 5/10/06)
				 : add norel/nofollow, thanks Rob (rkc 2/28/07)
				 : The UI has been completely revised by Gregory.
	Purpose		 : Display archives
				 : Gregory completely changed this. See the git hub repo and inline comments for more information.
--->
	
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "categoriesPod">
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
	
<cfset categories = application.blog.getCategories(parentCategory=1)>
	
<!--- Cache notes: We're saving this to the application scope. We need to save the dark theme. The timeout is set to 1 hour --->
<cfif darkTheme>
	<cfset cacheName = "archivesDark">
<cfelse>
	<cfset cacheName = "archives">
</cfif>
	
</cfsilent>
	
<cfmodule template="../../../../tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#(60*60)#" disabled="#application.disableCache#">
<cfif displayContentOutputData>
	<!--- Include the custom user defined content from the database --->
	<cfoutput>#contentOutputData#</cfoutput>
<cfelse>
	
	<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
	<cfif not arrayLen(categories)>
		<tr><td>There are no Category Archives.</td></tr>
	</cfif>
	<cfloop from="1" to="#arrayLen(categories)#" index="i">
		<cfsilent>
			<cftry>
				<!--- Extract the values from the category array --->
				<cfset categoryId = categories[i]["CategoryId"]>
				<cfset categoryUuid = categories[i]["CategoryUuid"]>
				<cfset category = categories[i]["Category"]>
				<cfset categoryPostCount = categories[i]["PostCount"]>
				<cfset categoryLink = #application.blog.makeCategoryLink(categoryId)#>
				<cfparam name="categoryRowCount" default="1">
				<cfcatch type="any">
					<cfset error = 'Error trying to render Archive Pod'>
				</cfcatch>
			</cftry>
		</cfsilent>
		<cfoutput>
	<cfif isNumeric(categoryPostCount) and categoryPostCount gt 0>
		<tr class="#iif(categoryRowCount MOD 2,DE('k-content'),DE('k-alt'))#">
			<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
			We will create a border between the rows if the current row is not the first row. --->
			<cfif i eq 1>
				<td>
			<cfelse>
				<td align="left" class="border" height="20px">
			</cfif>
			<a href="#categoryLink#" title="#category# RSS" <cfif darkTheme>style="color:whitesmoke"</cfif>>#category# (#categoryPostCount#)</a> [<a href="#application.baseUrl#/rss.cfm?mode=full&amp;mode2=cat&amp;catid=#categoryId#" rel="noindex,nofollow" <cfif darkTheme>style="color:whitesmoke"</cfif>>RSS</a>]
			</td>
		</tr>
		<!--- Increment our counter --->
		<cfset categoryRowCount = categoryRowCount + 1>
	</cfif><!---<cfif isNumeric(categoryPostCount) and categoryPostCount gt 0>--->
		</cfoutput>
	</cfloop>
	</table>
	<br/>
</cfif>
</cfmodule>