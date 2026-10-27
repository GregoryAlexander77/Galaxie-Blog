<!--- The ORDER BY for blog.cfc getPost (2026-10-27): shared by its two queries (see getPost). Included inside a cfquery, so it runs in getPost's own scope. --->
<!--- cfoutput: an included template only evaluates #...# inside cfoutput, even within the caller's cfquery. --->
<cfoutput>
		<cfif arguments.showPopularPosts>
				ORDER BY NumViews/(month(current_date())-month(DatePosted)+12*(year(current_date())-year(DatePosted))+1) #arguments.params.orderByDir#
		<cfelse>
			<cfif arguments.showPromoteAtTopOfQuery>
				ORDER BY Post.Promote DESC, Post.BlogSortDate DESC, Post.DatePosted #arguments.params.orderByDir#
			<cfelse>
				ORDER BY Post.BlogSortDate DESC, #arguments.params.orderBy# #arguments.params.orderByDir#
			</cfif>
		</cfif>
			<!--- ORDER BY #arguments.params.orderBy# #arguments.params.orderByDir# --->
</cfoutput>
