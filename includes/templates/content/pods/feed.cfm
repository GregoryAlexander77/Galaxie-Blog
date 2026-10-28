<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!--- 
********* Content template common logic *********
Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "cfblogFeedsPod">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- This template drives the navigation menu and is a unordered HTML list. This template uses the getContentOutputData function to determine the content. It will display custom content that is in the database or use the default code below if no custom code exists  --->
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
		<cfsilent>
		<!--- The feed is read in the background and kept in memory (2026-10-27). It used to be read with a cfhttp while the page was
		being drawn, twice per page (the sidebar and the side panel each include this pod), and whenever cfblogs.org didn't answer
		each read waited out its 5 second timeout: every page of galaxieblog.org took 10.8 seconds. Now a page never waits on
		cfblogs.org: it shows the last copy that was read (or nothing yet), and a stale copy is refreshed by one background thread,
		at most every 30 minutes, or 10 minutes after a failure. --->
		<cfif not structKeyExists(application, "cfblogsFeed")>
			<cfset application.cfblogsFeed = { items: [], nextRead: now(), reading: false, failed: false }>
		</cfif>
		<cfif dateCompare(now(), application.cfblogsFeed.nextRead) gte 0 and not application.cfblogsFeed.reading>
			<cflock name="cfblogsFeedRead_#application.applicationName#" type="exclusive" timeout="1" throwontimeout="false">
				<cfif not application.cfblogsFeed.reading>
					<cfset application.cfblogsFeed.reading = true>
					<!--- Try again in 10 minutes whatever happens; a good read pushes it to 30. --->
					<cfset application.cfblogsFeed.nextRead = dateAdd("n", 10, now())>
					<cfthread action="run" name="cfblogsFeedRead_#createUUID()#">
						<cftry>
							<!--- ?galaxie= tells cfblogs.org which Galaxie version is reading the feed (5.0, 2026-10-28): a rough count of installs
							and versions from its web log. Only the version; nothing about the site. --->
							<cfhttp url="https://www.cfblogs.org/rss.cfm?galaxie=#urlEncodedFormat(application.blog.getVersion())#" timeout="10" result="feedHttp" throwonerror="true">
							<cfset feedXml = xmlParse(feedHttp.fileContent)>
							<cfset feedNodes = xmlSearch(feedXml, "//*[local-name() = 'item']")>
							<cfset feedItems = []>
							<cfloop index="x" from="1" to="#min(arrayLen(feedNodes), 5)#">
								<cfset feedNode = feedNodes[x]>
								<!--- Note: comments holds the author, as cffeed does not generate the author --->
								<cfset arrayAppend(feedItems, {
									author: structKeyExists(feedNode, "comments") ? feedNode.comments.xmlText : "",
									link: structKeyExists(feedNode, "link") ? feedNode.link.xmlText : "",
									title: structKeyExists(feedNode, "title") ? feedNode.title.xmlText : ""
								})>
							</cfloop>
							<cfset application.cfblogsFeed.items = feedItems>
							<cfset application.cfblogsFeed.failed = false>
							<cfset application.cfblogsFeed.nextRead = dateAdd("n", 30, now())>
							<cfcatch type="any">
								<cfset application.cfblogsFeed.failed = true>
								<cflog file="galaxieBlogErrors" type="warning" text="CfBlogs feed pod: cfblogs.org could not be read (tried again in 10 minutes): #cfcatch.message#">
							</cfcatch>
						</cftry>
						<cfset application.cfblogsFeed.reading = false>
					</cfthread>
				</cfif>
			</cflock>
		</cfif>
		<cfset feedItems = application.cfblogsFeed.items>
		</cfsilent>
		<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
		<cfif arrayLen(feedItems)>
			<cfloop index="x" from="1" to="#arrayLen(feedItems)#">
				<cfsilent>
				<!-- Create alternating rows in the table. The Kendo classes which we will use are k-alt and k-content.
				We will create a border between the rows if the current row is not the first row. -->
				<cfif x mod 2>
					<cfset thisClass = 'k-content'>
				<cfelse>
					<cfset thisClass = 'k-alt'>
				</cfif>
				</cfsilent>
				<tr class="<cfoutput>#thisClass#</cfoutput>" height="35px;">
					<!--Create the nice borders after the first row.-->
					<cfif x eq 1>
					<td valign="top">
					<cfelse>
					<td align="left" valign="top" class="border">
					</cfif>
						<!--Display the content.-->
						<cfoutput>
						#encodeForHtml(feedItems[x].author)#<br/>
						<a href="#encodeForHtmlAttribute(feedItems[x].link)#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#encodeForHtml(feedItems[x].title)#</a><br />
						</cfoutput>
					</td>
				</tr>
			</cfloop>
		<cfelse>
			<tr>
				<td>
				<cfif application.cfblogsFeed.failed>CFBlogs isn't answering right now.<cfelse>The latest posts from CFBlogs will show here shortly.</cfif>
				</td>
			</tr>
		</cfif>
		</table>
		<br/>
	</cfif>
