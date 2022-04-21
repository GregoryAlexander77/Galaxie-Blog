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
	
<!--- Cache notes: We're saving this to the application scope. We need to save the dark theme. The timeout is set to 1 hour --->
<cfif darkTheme>
	<cfset cacheName = "archivesDark">
<cfelse>
	<cfset cacheName = "archives">
</cfif>
	
<cfset categories = application.blog.getCategories()>
	
</cfsilent>
	
<cfmodule template="../../tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#(60*60)#" disabled="#application.disableCache#">
	<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
	<cfif not arrayLen(categories)>
		<tr><td>There are no Category Archives.</td></tr>
	</cfif>
	<cfloop from="1" to="#arrayLen(categories)#" index="i">
		<cfsilent>
			<!--- Extract the values from the category array --->
			<cfset categoryId = categories[i]["CategoryId"]>
			<cfset categoryUuid = categories[i]["CategoryUuid"]>
			<cfset category = categories[i]["Category"]>
			<cfset categoryPostCount = categories[i]["PostCount"]>
			<cfset categoryLink = #application.blog.makeCategoryLink(categoryId)#>
			<cfparam name="categoryRowCount" default="1">
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
			<a href="#categoryLink#" title="#category# RSS" <cfif darkTheme>style="color:whitesmoke"</cfif>>#category# (#categoryPostCount#)</a> [<a href="#application.rootURL#/rss.cfm?mode=full&amp;mode2=cat&amp;catid=#categoryId#" rel="noindex,nofollow" <cfif darkTheme>style="color:whitesmoke"</cfif>>RSS</a>]
			</td>
		</tr>
		<!--- Increment our counter --->
		<cfset categoryRowCount = categoryRowCount + 1>
	</cfif><!---<cfif isNumeric(categoryPostCount) and categoryPostCount gt 0>--->
		</cfoutput>
	</cfloop>
	</table>
	<br/>
</cfmodule>