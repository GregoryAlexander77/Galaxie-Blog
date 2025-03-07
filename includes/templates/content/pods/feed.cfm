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
	
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "cfblogFeedsPod">
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

<!--- Set up cache. We are going to timeout in 30 minutes --->
<cfif session.isMobile>
	<cfset cacheName = "podRssFeedMobile">
<cfelse>
	<cfset cacheName = "podRssFeed">
</cfif>
</cfsilent>
		
<cfmodule template="../../../../tags/scopecache.cfm" scope="application" cachename="#cacheName#" timeout="#60*30#" disabled="#application.disableCache#">
	<cfif displayContentOutputData>
		<!--- Include the custom user defined content from the database --->
		<cfoutput>#contentOutputData#</cfoutput>
	<cfelse>
		<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
		<cftry>
			<cfsilent>
			<cfset theURL = "https://www.cfblogs.org/rss.cfm">
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
						<!--- Note: comments is used for the author as cffeed does not generate the author when using cffeed --->
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
	</cfif>
<!--- End cache. --->
</cfmodule>