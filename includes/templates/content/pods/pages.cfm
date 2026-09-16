<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
   Name : pages.cfm
   Author : William Haun (orginal) / Gregory Alexander complete rewrite
   Created : August 19, 2006
   Last Updated : June 20, 2026, see GitHub for later revisions
--->
</cfsilent>
			<cfif displayContentOutputData>
				<!--- Include the custom user defined content from the database --->
				<cfoutput>#contentOutputData#</cfoutput>
			<cfelse>
				<cfsilent>
					<cfset getPageCategories = application.blog.getPageCategories(pageCategoryType='parent')>
				</cfsilent>
				<cfif arrayLen(getPageCategories)>
				<script>
					$(document).ready(function() {
						// Create an accordian style panel for each page category. 
						$("#pagePodPanelBar").kendoPanelBar({
							expandMode: "multiple"
						});
					});//..document.ready
				</script>
				<nav>
					<ul id="pagePodPanelBar">
					<!--- Loop through the page categories --->
					<cfloop from="1" to="#arrayLen(getPageCategories)#" index="i">
						<cfsilent>
							<!--- Set the values. --->
							<cfset category = getPageCategories[i]["Category"]>
							<cfset categoryId = getPageCategories[i]["CategoryId"]>
							<cfset categoryLevel = getPageCategories[i]["CategorySubLevel"]>
							<cfset categoryLink = application.blog.makeCategoryLink(categoryId)>

							<!--- Get the pages for each page category. --->
							<cfset pagesByCategoryId = application.blog.getPagesByCategoryId(categoryId=getPageCategories[i]["CategoryId"], type='active')>							
						</cfsilent>
						<cfoutput>
						<li>
							#category#
						</cfoutput>
						<div style="padding: 10px;">
						<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
							<cfloop from="1" to="#arrayLen(pagesByCategoryId)#" index="pageIndex">
							<cfsilent>
							<cfset thisPostId = pagesByCategoryId[pageIndex]["PostId"]>
							<cfset pagePostUuid = pagesByCategoryId[pageIndex]["PostUuid"]>
							<cfset pagePostId = pagesByCategoryId[pageIndex]["PostId"]>
							<cfset pageTitle = pagesByCategoryId[pageIndex]["Title"]>
							<cfif CGI.remote_addr eq '50.54.137.103'>
								<!--- We already know we want pages --->
								<cfset pageLink = application.blog.makeLink(
								isPage=1, 
								postAlias=pagesByCategoryId[pageIndex]["PostAlias"], 
								datePosted=pagesByCategoryId[pageIndex]["DatePosted"])>
							<cfelse>
								<cfset pageLink = application.blog.makeLink(
								postId=thisPostId)>
							</cfif>
							
							</cfsilent>
							<cfoutput>
								<tr class="#iif(pageIndex MOD 2,DE('k-content'),DE('k-alt'))#">
								<cfif pageIndex eq 1>
									<td>
								<cfelse>
									<td align="left" class="border" height="20px">
								</cfif>
										<a href="#pageLink#" aria-label="#pageTitle#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#pageTitle#</a>
									</td>
								</tr>
							</cfoutput>
						</cfloop>
						<!--- End the table, div and list element --->
						</table>
						</div>
					</li>
				</cfloop>
				</ul>
			</nav>
		</cfif><!---<cfif arrayLen(getPageCategories)>--->
	</cfif>
	<br/>