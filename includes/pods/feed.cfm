<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
   Name			: feed.cfm
   Author 		: Raymond Camden
   Created 		: September 20, 2006
   Last Updated : December 14 2018 (Gregory added the Kendo UI)
   History 		: Forgot the enableoutputonly false

	Note - this pod is meant to allow you to easily show
	another site's RSS feed on your blog. You should 
	edit the title to match the site you are hitting. 
	You may also need to edit the xmlSearch tag based
	on the type of RSS feed you are using.
--->

<!--- Set up cache. We are going to timeout in 30 minutes --->
<cfif session.isMobile>
	<cfset cacheName = "podRssFeedMobile">
<cfelse>
	<cfset cacheName = "podRssFeed">
</cfif>
</cfsilent>
<cfmodule template="../../tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#60*30#" disabled="#application.disableCache#">
	<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
	<cftry>
		<cfsilent>
		<cfset theURL = "https://gregoryalexander.com/cfblogs/rss.cfm">
		<cfhttp url="#theURL#" timeout="5">
		<cfset xml = xmlParse(cfhttp.filecontent)>
		<cfset items = xmlSearch(xml, "//*[local-name() = 'item']")>
		<!--- Set a loop counter to keep track of the current row for display purposes. --->
		<cfset feedLoopCount = 1>
		</cfsilent>
		<cfloop index="x" from="1" to="#min(arrayLen(items),5)#">
			<cfsilent>
			<cfset item = items[x]>
			<!-- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
			We will create a border between the rows if the current row is not the first row. -->
			<cfif feedLoopCount mod 2>
				<cfset thisClass = 'k-content'>
			<cfelse>
				<cfset thisClass = 'k-alt'>
			</cfif>
			</cfsilent>
			<tr class="<cfoutput>#thisClass#</cfoutput>" height="35px;">
				<!--Create the nice borders after the first row.-->
				<cfif feedLoopCount eq 1>
				<td valign="top">
				<cfelse>
				<td align="left" valign="top" class="border">
				</cfif>
					<!--Display the content.-->
					<cfoutput>
					#item.comments.xmlText#<br/> 
					<a href="#item.link.xmlText#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#item.title.xmlText#</a><br />
					</cfoutput>
				</td>
			</tr>
			<!---Increment the loop counter--->
			<cfset feedLoopCount = feedLoopCount + 1>
		</cfloop>
		<cfcatch>
			<tr>
				<td>
				<cfoutput>
				CFBloggers down
				</cfoutput>
				</td>
			</tr>
		</cfcatch>
	</cftry>
	</table>
	<br/>
<!--- End cache. --->
</cfmodule>





