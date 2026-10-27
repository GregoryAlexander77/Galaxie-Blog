<!--- //**************************************************************************************************************
		Per-post view-count tracking and grid/list display flags. Assumes postFound is true and getPost/getPageMode() are available (guaranteed by the caller's <cfif postFound> wrapper).
//****************************************************************************************************************--->
<!--- Split out of coreLogic.cfm (item 7 of the index.cfm/coreLogic.cfm rewrite proposal) so each concern is easier to find. Assumes it is included from coreLogic.cfm, which is itself included from within a <cfsilent> block on index.cfm. --->

		<cfswitch expression="#getPageMode()#">

			<!--- //**********************************************************************************************************
				Get the post
			//************************************************************************************************************--->
			<cfcase value = "post">
				
				<cfif arrayLen(getPost)>
					<!--- When in post mode, there will only be one element in the getPost array. --->
					<!--- If the blog is in entry or alias mode, set the URL mode to entry --->
					<cfset url.mode = "entry">
					<cfset url.postId = getPost[1]["PostId"]>
					<cfif structKeyExists(getPost[1], "IsPage")>
						<cfset url.isPage = getPost[1]["IsPage"]>
					<cfelse>
						<cfset url.isPage = false>
					</cfif>
					<!--- Set the postId. I don't want to use the array syntax every time I use this variable in the code. --->
					<cfset postId = getPost[1]["PostId"]>
					<cfset title = getPost[1]["Title"]>

					<!--- ********************************************************************************************************
					Obtain user information and increment the view count if the user has not seen this post. 
					********************************************************************************************************  --->

					<!--- The session.viewedpages struct may not exist yet the first time a session hits a post. Initializing it here (instead of relying on a try/catch to paper over the resulting undefined-variable error) also protects the dontLog check just below, which read session.viewedpages before the try/catch ever ran. --->
					<cfparam name="session.viewedpages" default="#structNew()#">

					<!--- Preset the dontLog --->
					<cfset dontLog = false>
					<cfif getPageMode() neq "alias" or structKeyExists(session.viewedpages, postId)>
						<cfset dontLog = true>
					<cfelse>
						<!--- Mark the post that this user viewed --->
						<cfset session.viewedpages[postId] = 1>
					</cfif>

					<!--- Increment the view count. --->
					<cfif not structKeyExists(session.viewedpages, postId)>
						<cfset session.viewedpages[postId] = 1>
						<!--- Not for bots (2026-10-24, owner): most keep no session, so every crawl counted as a view. --->
						<cfif not application.blog.isBot()>
							<cfset application.blog.logView(postId)>
						</cfif>
					</cfif>
				</cfif><!---<cfif arrayLen(getPost)>--->
						
			</cfcase>

		</cfswitch>
					
		<!--- Determine if we should display popular posts --->
		<!--- Not on a Page Collection's own page (pageTypeId 20) or a curated set of homepage Pages (21) - those list
		Pages, not blog posts, so a "Popular Blogs" strip above them was out of place. --->
		<cfif getPageMode() eq 'blog' and URL.startRow lte 1 and arrayLen(getPost) gte 9
				and not (isDefined("pageTypeId") and (pageTypeId eq 20 or pageTypeId eq 21))>
			<!--- Off switch (2026-10-27, blog.cfc isOff). --->
			<cfset showPopularPosts = not application.blog.isOff("popularPosts")>
		</cfif>
				
		<!---<cfoutput>getPageMode(): #getPageMode()#</cfoutput>--->
		<!--- Determine if we should show the condensedGridView view. This is done for all modes other than when looking at an individual post --->
		<cfif getPageMode() eq 'category' or getPageMode() eq 'postedBy' or getPageMode() eq 'month' or getPageMode() eq 'day' or getPageMode() eq 'blog'>
			<cfset condensedGridView = true>
		</cfif>