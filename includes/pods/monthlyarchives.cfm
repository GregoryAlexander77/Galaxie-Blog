<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : monthlyarchives.cfm
	Author       : Rob Brooks-Bilson / Gregory Alexander
	Created      : December 5, 2005
	Last Updated : December 14 2018 (Gregory added the Kendo UI)
	History      : initial creation (rbb: 12/05/2005)
	               removed dbo, {fn} references for MySQL compat (rbb: 12/07/2005)
				   Moved query to blog.cfc method (rbb: 08/08/2010)
	Purpose		 : Displays monthly archives	
--->
	
<!--- Cache notes: We're saving this to the application scope. We need to differentiate between the dark theme and light themes in the key. The timeout is set to 24 hours --->
<cfset cacheName = "monthyArchives">
<!--- Dark theme --->
<cfif darkTheme>
	<cfset cacheName = cacheName & "Dark">
</cfif>

<!--- get the last 5 years by default. If you want all months/years, remove the param --->
<cfset getMonthlyArchives = application.blog.getArchives(archiveYears=5)>
</cfsilent>
	
<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#(60*60)*24#" disabled="#application.disableCache#">
	<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
	<cfif not arrayLen(getMonthlyArchives)>
		<tr><td>There are no Monthly Archives.</td></tr>
	</cfif>
	<!--- Loop through the month archives ORM object. --->
	<cfloop from="1" to="#arrayLen(getMonthlyArchives)#" index="i">
		<cfsilent>
		<!--- Extract the values from the array. --->
		<cfset previousMonths = getMonthlyArchives[i]["PreviousMonths"]>
		<cfset previousYears = getMonthlyArchives[i]["PreviousYears"]>
		<cfset entryCount = getMonthlyArchives[i]["EntryCount"]>
		</cfsilent>
		<tr class="#iif(i MOD 2,DE('k-content'),DE('k-alt'))#">
			<!---Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
			We will create a border between the rows if the current row is not the first row. --->
			<cfif i eq 1>
				<td>
			<cfelse>
				<td align="left" class="border" height="20px">
			</cfif>
			<cfoutput>
			<a href="#thisUrl#?mode=month&amp;month=#previousMonths#&amp;year=#previousYears#" aria-label="#monthAsString(previousMonths)# #previousYears# (#entryCount#)" <cfif darkTheme>style="color:whitesmoke"</cfif>>#monthAsString(previousMonths)# #previousYears# (#entryCount#)</a>
			</cfoutput>
			</td>
		</tr>	
	</cfloop>
	</table>
	<br/>
</cfmodule>