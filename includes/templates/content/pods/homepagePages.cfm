<cfsilent>
<!---
   Name : homepagePages.cfm
   Created : September 23, 2026
   Lists whichever Page(s) are currently selected for the homepage (Configure Homepage, "A specific page" mode), in
   the exact order they were selected - homepagePagesForPod is already built in that order by pods/index.cfm, shared
   via cfinclude's page scope, so this file only renders it. Same alternating-row table style as every other pod
   (Page Collections, Category Archives, etc.).
--->
</cfsilent>
<cfif arrayLen(homepagePagesForPod)>
<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
	<cfloop from="1" to="#arrayLen(homepagePagesForPod)#" index="pageIndex">
	<cfoutput>
		<tr class="#iif(pageIndex MOD 2,DE('k-content'),DE('k-alt'))#">
		<cfif pageIndex eq 1>
			<td>
		<cfelse>
			<td align="left" class="border" height="20px">
		</cfif>
				<a href="#homepagePagesForPod[pageIndex].link#" aria-label="#homepagePagesForPod[pageIndex].title#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#homepagePagesForPod[pageIndex].title#</a>
			</td>
		</tr>
	</cfoutput>
	</cfloop>
</table>
</cfif>
<br/>
