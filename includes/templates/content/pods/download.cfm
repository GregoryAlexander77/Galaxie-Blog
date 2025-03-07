<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : download.cfm
	Author       : Gregory Alexander 
	Created      : June 10th, 2019
	Last Updated : 
	History      : 
	Purpose		 : Prominent download button on site.
--->

<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "downloadPod">
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

</cfsilent>
				
<cfif displayContentOutputData>
	<!--- Include the custom user defined content from the database --->
	<cfoutput>#contentOutputData#</cfoutput>
<cfelse>
	<table align="center" class="k-content fixedPodTable" width="100%" cellpadding="0" cellspacing="0">
		<cfoutput>
		<tr class="k-content">
			<td align="left">
			<button type="button" class="k-button k-primary" style="#kendoButtonStyle#" onClick="createAboutWindow(3);">
				Download
			</button>
			</td>
		</tr>	
		</cfoutput>
	</table>
	<br/>
</cfif>