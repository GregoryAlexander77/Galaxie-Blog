<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : recent.cfm
	Author       : Raymond Camden 
	Created      : October 29, 2003
	Last Updated : November 4 2018
	History      : added processingdir (rkc 11/10/03)
				   New link code (rkc 7/12/05)
				   Hide future entries (rkc 6/1/07)
				   Removed classes and formatting (ga 11/04/2018). 
	Purpose		 : Display recent entries
--->


<cfset params = structNew()>
<cfset params.maxEntries = 5>
<cfset params.releasedonly = true>
<cfset entryData = application.blog.getEntries(duplicate(params))>
<cfset entries = entryData.entries>
</cfsilent>
				<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
					<cfif not entries.recordCount>
						<tr>
							<td class="k-header">
							<cfoutput>#application.resourceBundle.getResource("norecententries")#</cfoutput>
							</td>
						</tr>
					</cfif>
					<cfoutput query="entries">
					<tr class="#iif(currentRow MOD 2,DE('k-content'),DE('k-alt'))#">
						<!---Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
						We will create a border between the rows if the current row is not the first row. --->
						<cfif currentRow eq 1>
							<td>
						<cfelse>
							<td align="left" class="border" height="20px">
						</cfif>
						<a href="#application.blog.makeLink(id)#" aria-label="#title#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#title#</a>
						</td>
					</tr>	
					</cfoutput>
				</table>
				<br/>