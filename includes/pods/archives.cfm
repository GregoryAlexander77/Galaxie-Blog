<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : archives.cfm
	Author       : Raymond Camden 
	Created      : October 29, 2003
	Last Updated : November 4 2018 (Gregory added the Kendo UI)
	History      : Use SES urls (rkc 4/18/06)
				 : Don't hide empty cats (rkc 5/10/06)
				 : add norel/nofollow, thanks Rob (rkc 2/28/07)
				 : The UI has been completely revised by Gregory.
	Purpose		 : Display archives
--->
</cfsilent>
<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
	<cfset cats = application.blog.getCategories()>
	<cfoutput query="cats">
	<cfsilent>
	<!--- We need to perform the same logic for the post author (remove the 'index.cfm' string when a rewrite rule is in place). --->
	<cfif application.serverRewriteRuleInPlace>
		<cfset categoryLink = replaceNoCase(#application.blog.makeCategoryLink(categoryid)#, '/index.cfm', '')>
	<cfelse>
		<cfset categoryLink = #application.blog.makeCategoryLink(categoryid)#>
	</cfif>
	</cfsilent>
	<tr class="#iif(currentRow MOD 2,DE('k-content'),DE('k-alt'))#">
		<!---Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif currentRow eq 1>
			<td>
		<cfelse>
			<td align="left" class="border" height="20px">
		</cfif>
		<a href="#categoryLink#" title="#categoryName# RSS" <cfif darkTheme>style="color:whitesmoke"</cfif>>#categoryName# (#entryCount#)</a> [<a href="#application.rootURL#/rss.cfm?mode=full&amp;mode2=cat&amp;catid=#categoryid#" rel="noindex,nofollow" <cfif darkTheme>style="color:whitesmoke"</cfif>>RSS</a>]
		</td>
	</tr>	
	</cfoutput>
</table>
<br/>