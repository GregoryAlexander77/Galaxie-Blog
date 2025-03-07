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
	
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "monthlyArchivesPod">
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

<!--- get the last 5 years by default. If you want all months/years, remove the param --->
<cfset getMonthlyArchives = application.blog.getArchives(archiveYears=5)>
	
<!--- Cache notes: We're saving this to the application scope. We need to differentiate between the dark theme and light themes in the key. The timeout is set to 24 hours --->
<cfset cacheName = "monthyArchives">
<!--- Dark theme --->
<cfif darkTheme>
	<cfset cacheName = cacheName & "Dark">
</cfif>
</cfsilent>
	
<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#(60*60)*24#" disabled="#application.disableCache#">
<cfif displayContentOutputData>
	<!--- Include the custom user defined content from the database --->
	<cfoutput>#contentOutputData#</cfoutput>
<cfelse>
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
</cfif>
<br/>
</cfmodule>