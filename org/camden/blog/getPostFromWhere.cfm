<!--- The FROM and WHERE for blog.cfc getPost (2026-10-27): shared by its two queries (see getPost). Included inside a cfquery, so it runs in getPost's own scope. --->
<!--- cfoutput: an included template only evaluates #...# inside cfoutput, even within the caller's cfquery. --->
<cfoutput>
			FROM Post as Post 
			<!--- UserRef is the actual database foreign key pointing to the Users table. --->
			LEFT JOIN Post.UserRef as User
			<!--- EnclosureMedia is the psuedo object based key in Post.cfc that points to the Media table. --->
			LEFT JOIN Post.EnclosureMedia as Enclosure
			<!--- We need to traverse the Post.EnclosureMedia object to get to the MimeTypeRef and MediaType objects --->
			LEFT JOIN Enclosure.MediaTypeRef as MediaType  
			LEFT JOIN Enclosure.MimeTypeRef as MimeType
			<!--- Get the Enclosure Map (there can only be one) --->
			LEFT JOIN Post.EnclosureMap as EnclosureMap
			<!--- Get the carousel, there is only one --->
			LEFT JOIN Post.EnclosureCarousel as EnclosureCarousel
			WHERE 0=0
			<cfif !arguments.showPages or !arguments.showBlogPosts>
				<!--- Determine if blog posts or layers should be shown. I will only filter if one of the arguments is false --->
				<cfif arguments.showPages>
					AND Post.IsPage = <cfqueryparam value="1" cfsqltype="cf_sql_bit">
				<cfelse>
					AND (Post.IsPage = <cfqueryparam value="0" cfsqltype="cf_sql_bit"> OR IsPage IS NULL)
				</cfif>
				<cfif arguments.showBlogPosts>
					AND Post.IsBlogPost = <cfqueryparam value="1" cfsqltype="cf_sql_bit">
				<cfelse>
					AND (Post.IsBlogPost = <cfqueryparam value="0" cfsqltype="cf_sql_bit"> OR IsBlogPost IS NULL)
				</cfif>
			</cfif><!---<cfif arguments.showPages and arguments.showBlogPosts>--->
			<cfif not arguments.showRemovedPosts>
				AND Post.Remove = <cfqueryparam value="0" cfsqltype="cf_sql_bit">
			</cfif>
			<cfif structKeyExists(arguments.params,"lastXDays")>
				AND date(Post.DatePosted) > <cfqueryparam value="#createDate(params.byYear, params.byMonth, params.byDay)#" cfsqltype="cf_sql_date">
			</cfif>
			<!--- Todo: serverOffset --->
			<cfif structKeyExists(arguments.params,"byDay") and not structKeyExists(arguments.params,"byAlias")>
			 	<!--- I am going to search between 24 hours on the given date. --->
				AND Post.DatePosted > <cfqueryparam value="#CreateDateTime(params.byYear, params.byMonth, params.byDay, '00', '00')#" cfsqltype="timestamp">
				AND Post.DatePosted < <cfqueryparam value="#CreateDateTime(params.byYear, params.byMonth, params.byDay, '23', '59')#" cfsqltype="timestamp">
			</cfif>
			<cfif structKeyExists(arguments.params,"byTitle")>
				AND Post.Title = <cfqueryparam value="#arguments.params.byTitle#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<cfif structKeyExists(arguments.params,"byCat") and arguments.params.byCat neq 'all'>
				AND Post.PostId IN (
					SELECT PostRef
					FROM PostCategoryLookup
					WHERE CategoryRef IN (#replaceNoCase(arguments.params.byCat,'all,','')#)
				)
			</cfif>
			<cfif structKeyExists(arguments.params,"byTag") and arguments.params.byTag neq 'all'>
				AND Post.PostId IN (
					SELECT PostRef
					FROM PostTagLookup
					WHERE TagRef IN (#replaceNoCase(arguments.params.byTag,'all,','')#)
				)
			</cfif>
			<cfif structKeyExists(arguments.params,"byPosted")>
				AND User.UserName =  <cfqueryparam value="#arguments.params.byPosted#" cfsqltype="cf_sql_varchar" maxlength="50" list=true>
			</cfif>
			<cfif structKeyExists(arguments.params,"searchTerms")>
				<cfif not structKeyExists(arguments.params, "don'tlogsearch")>
					<cfset logSearch(arguments.params.searchTerms)>
				</cfif>
				AND (
						Post.Title LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
						OR Post.Body LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
						OR Post.MoreBody LIKE <cfqueryparam value="%#arguments.params.searchTerms#%" cfsqltype="cf_sql_varchar">
					)
			</cfif>
			<!--- By entry passes a single postId in the URL --->
			<cfif structKeyExists(arguments.params,"byEntry")>
				AND Post.PostId = <cfqueryparam value="#arguments.params.byEntry#" cfsqltype="cf_sql_varchar" maxlength="35">
			</cfif>
			<!--- The postIdList is sent in manually and is used to get the related posts at the bottom of a post --->
			<cfif len(arguments.postIdList)>
				AND Post.PostId IN (<cfqueryparam value="#arguments.postIdList#" cfsqltype="cf_sql_varchar" list="Yes">)
			</cfif>
			<cfif structKeyExists(arguments.params,"byAlias")>
				AND Post.PostAlias = <cfqueryparam value="#left(arguments.params.byAlias,100)#" cfsqltype="cf_sql_varchar" maxlength="100">
			</cfif>
			<!--- Date operations --->
			<cfif structKeyExists(arguments.params,"byDay")>
				AND day(Post.DatePosted) = <cfqueryparam value="#arguments.params.byDay#" cfsqltype="integer">
			</cfif>
			<cfif structKeyExists(arguments.params,"byMonth")>
				AND month(Post.DatePosted) = <cfqueryparam value="#arguments.params.byMonth#" cfsqltype="integer">
			</cfif>
			<cfif structKeyExists(arguments.params,"byYear")>
				AND year(Post.DatePosted) = <cfqueryparam value="#arguments.params.byYear#" cfsqltype="integer">
			</cfif>
			<cfif not arguments.showPendingPosts>
				AND Post.Released = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
			</cfif>
				<!--- Make sure we get posts with complete data --->
				AND Post.Title IS NOT NULL
				AND Post.DatePosted IS NOT NULL
				AND Post.BlogRef = #application.BlogDbObj.getBlogId()#
</cfoutput>
