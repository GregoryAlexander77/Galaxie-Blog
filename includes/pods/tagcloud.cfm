<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
   Name : 			tags.cfm
   Author : 		Steven Erat
   Created : 		November 15, 2005
   Last Updated : 	December 21 2018
   History : 		Based on blog entries by Pete Freitag and Joe Rinehart
					Use SES cat urls (rkc 8/29/06)
					Rewritten for Kendo by Gregory
   Purpose : 		Display archives as sized tags
   Gregory's notes: This template has been completely overhauled. I converted this to ORM and simplified the logic quite a bit. 
--->

	<cfset categories = application.blog.getCategories()>
		
	<!--- Cache note: this template does not need to differentiate between desktop and mobile. We do need to track the dark theme tho. --->
	<cfset cacheName = "tagCloud">
	<cfif darkTheme>
		<cfset cacheName = cacheName & "Dark">
	<cfelse>
		<cfset cacheName = cacheName & "Light">
	</cfif>

</cfsilent>
<cfmodule template="#application.baseUrl#/tags/scopecache.cfm" scope="application" cachename="#cacheName#" disabled="#application.disableCache#">
   <table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="0" cellspacing="0">
   <cfif not arrayLen(categories)>
	   <tr><td>There are no categories</td></tr>
   </cfif>
   <cfloop from="1" to="#arrayLen(categories)#" index="i"><cfoutput>
	<cfsilent>
	<cftry>
		<!--- Extract the values from the category array --->
		<cfset CategoryId = categories[i]["CategoryId"]>
		<cfset category = categories[i]["Category"]>
		<cfset categoryPostCount = categories[i]["PostCount"]>
		<!--- Make the category link --->
		<cfset categoryTagLink = application.blog.makeCategoryLink(CategoryId)>
		<!---Make a var to hold the row count since we are supressing categories that don't  have a post count --->
		<cfparam name="categoryRowCount" default="1">
		<cfcatch type="any">
			<cfset CategoryId = "">
			<cfset category = "">
			<cfset categoryPostCount = "">
			<cfset categoryTagLink = "">
		</cfcatch>
	</cftry>
	</cfsilent>
<cfif isNumeric(categoryPostCount) and categoryPostCount gt 0>
	<tr class="#iif(i MOD categoryRowCount,DE('k-content'),DE('k-alt'))#">
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif i mod 2>
			<cfset thisClass = 'k-content'>
		<cfelse>
			<cfset thisClass = 'k-alt'>
		</cfif>
		<tr class="#iif(categoryRowCount MOD 2,DE('k-content'),DE('k-alt'))#">
		<cfif i eq 1><td valign="top"><cfelse><td align="left" valign="top" class="border"></cfif>
			<a href="#categoryTagLink#" aria-label="#lcase(category)# (#categoryPostCount#)" <cfif darkTheme>style="color:whitesmoke"</cfif>>#lcase(category)# (#categoryPostCount#)</a>
		</td>
	</tr>
	<!--- Increment our row count counter --->
	<cfset categoryRowCount = categoryRowCount + 1>
</cfif><!---<cfif isNumeric(categoryPostCount) and categoryPostCount gt 0>--->
   </cfoutput>
	</cfloop>
	<tr>
	   	<td>&nbsp;</td>
	</tr>
</table>
</cfmodule>