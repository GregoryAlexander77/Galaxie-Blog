<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : monthlyarchives.cfm
	Author       : Rob Brooks-Bilson
	Created      : December 5, 2005
	Last Updated : December 14 2018 (Gregory added the Kendo UI)
	History      : initial creation (rbb: 12/05/2005)
	               removed dbo, {fn} references for MySQL compat (rbb: 12/07/2005)
				   Moved query to blog.cfc method (rbb: 08/08/2010)
	Purpose		 : Displays monthly archives	
--->


<!--- get the last 5 years by default. If you want all months/years, remove the param --->
<cfset getMonthlyArchives = application.blog.getArchives(archiveYears=5)>
</cfsilent>	
<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
	<cfoutput query="getMonthlyArchives">
	<tr class="#iif(currentRow MOD 2,DE('k-content'),DE('k-alt'))#">
		<!---Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif currentRow eq 1>
			<td>
		<cfelse>
			<td align="left" class="border" height="20px">
		</cfif>
		<a href="#thisUrl#?mode=month&amp;month=#previousmonths#&amp;year=#previousyears#" aria-label="#monthAsString(previousmonths)# #previousyears# (#entryCount#)" <cfif darkTheme>style="color:whitesmoke"</cfif>>#monthAsString(previousmonths)# #previousyears# (#entryCount#)</a>
		</td>
	</tr>	
	</cfoutput>
</table>
<br/>
