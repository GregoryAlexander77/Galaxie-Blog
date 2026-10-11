<cfsilent>
<cfprocessingdirective pageencoding="utf-8">
<!---
   Name : pages.cfm
   Author : William Haun (orginal) / Gregory Alexander complete rewrite
   Created : August 19, 2006
   Last Updated : September 23, 2026, see GitHub for later revisions
   Note: this pod used to group Pages by Category (an accordion per Category, each expanding to its Pages). Pages are
   organized into Page Collections now instead - see [[front-page-page-groups-design-rethink]] - so this is now a flat
   list of links to every visible (2+ member) Collection's own page, same alternating-row table style as the rest of
   this pod's siblings (Category Archives, etc.) used already.
--->
</cfsilent>
			<cfif displayContentOutputData>
				<!--- Include the custom user defined content from the database --->
				<cfoutput>#contentOutputData#</cfoutput>
			<cfelse>
				<cfsilent>
					<cfset getVisibleCollections = application.blog.getEligiblePageCollectionsForHomepage()>
				</cfsilent>
				<cfif arrayLen(getVisibleCollections)>
				<table align="center" class="k-content fixedPodTableWithWrap" width="100%" cellpadding="7" cellspacing="0">
					<cfloop from="1" to="#arrayLen(getVisibleCollections)#" index="collectionIndex">
					<cfsilent>
						<cfset collectionTitle = getVisibleCollections[collectionIndex]["title"]>
						<cfset collectionLink = application.blog.makeCollectionLink(getVisibleCollections[collectionIndex]["pageCollectionId"])>
					</cfsilent>
					<cfoutput>
						<tr class="#iif(collectionIndex MOD 2,DE('k-content'),DE('k-alt'))#">
						<cfif collectionIndex eq 1>
							<td>
						<cfelse>
							<td align="left" class="border" height="20px">
						</cfif>
								<a href="#collectionLink#" aria-label="#collectionTitle#" <cfif darkTheme>style="color:whitesmoke"</cfif>>#collectionTitle#</a>
							</td>
						</tr>
					</cfoutput>
					</cfloop>
				</table>
				</cfif><!---<cfif arrayLen(getVisibleCollections)>--->
			</cfif>
	<br/>
