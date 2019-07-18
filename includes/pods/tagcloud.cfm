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
--->

	<cfset cats = application.blog.getCategories()>

	<cfquery dbtype="query" name="tags">
	  SELECT entrycount AS tagCount,categoryname as tag, categoryid
	  FROM
		 cats
	</cfquery>
	<!--- Original contained the following clause 
	WHERE entrycount >= 10
	--->

	<cfset tagValueArray = ListToArray(ValueList(tags.tagCount))>
	<cfset max = ArrayMax(tagValueArray)>
	<cfset min = ArrayMin(tagValueArray)>

	<cfset diff = max - min>
	<!---
	  scaleFactor will affect the degree of difference between the different font sizes.
	  if you have one really large category and many smaller categories, then set higher.
	  if your category count does not vary too much try a lower number.      
	--->
	<cfset scaleFactor = 25>
	<cfset distribution = diff / scaleFactor>
	<!--- 
	<cfdump var="#cats#">
	<cfdump var="#tags#">
	--->
	<!--- optionally add a range of colors in the CSS color property for each class --->
	</cfsilent>

   <table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="0" cellspacing="0">
   <cfoutput query="tags">
	<tr class="#iif(currentRow MOD 2,DE('k-content'),DE('k-alt'))#">
		<!--- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
		We will create a border between the rows if the current row is not the first row. --->
		<cfif currentRow mod 2>
			<cfset thisClass = 'k-content'>
		<cfelse>
			<cfset thisClass = 'k-alt'>
		</cfif>
		<tr class="#iif(currentRow MOD 2,DE('k-content'),DE('k-alt'))#">
		<cfif currentRow eq 1><td valign="top"><cfelse><td align="left" valign="top" class="border"></cfif>
			<a href="#application.blog.makeCategoryLink(tags.categoryid)#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#lcase(tags.tag)# (#tags.tagCount#)</a>
		</td>
	</tr>
   </cfoutput>
	<tr>
	   	<td>&nbsp;</td>
	</tr>
</table>