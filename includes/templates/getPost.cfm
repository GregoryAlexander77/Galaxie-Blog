<!--- //**************************************************************************************************************
		Get the posts. The posts can either be one post, or multiple posts. It is designed this way to keep the output logic the same.
//****************************************************************************************************************--->
  
<!--- 
Get the post count (getPostCount(params,showRemovedPosts, released))
(note: this function must be placed above the getPost invocation below)
--->
<cfset postCount = application.blog.getPostCount(params, false, true)>
<!--- Allow the admin to preview if the showPendingPosts URL var is present and if we are looking at a single entry. This is needed as we don't want to accidently cache the main blog page (with multiple posts) when previewing the page --->
<cfif ( isDefined("URL.showPendingPosts") and (url.mode eq "alias" or URL.mode eq 'entry'))>
	<cfset showPendingPosts = true>
<cfelse>
	<cfset showPendingPosts = false>
</cfif>

<!--- Notes: 
1) External pages will be set by either setting the postId on the index page or setting the IsPage column in the post table. All other pages will use the params structure to get the post 
2) a post may be removed and have a redirect to another URL. We need to allow for removed posts to get the redirect if it exists. 
--->
<!---<cfdump var="#URL#" label="URL">--->
	
<!--- Custom page with a hard coded postId --->
<cfif pageTypeId eq 9 and isDefined("postId")>
	<!--- Custom pages --->
	<!--- Get the individual post ( getPostByPostId(postId, showPendingPosts, showRemovedPosts) ) --->
	<cfset getPost = application.blog.getPostByPostId(postId,true,false)>
<cfelse>
	<!--- Get the posts ( getPost(params, showPendingPosts, showRemovedPosts, showJsonLd, showPromoteAtTopOfQuery) ) 
	<cfset getPost = application.blog.getPost(params, showPendingPosts, false, true, true)>
	--->
	<!--- 
	Get the posts 
	Original code: ( getPost(params, showPendingPosts, showRemovedPosts, showJsonLd, showPromoteAtTopOfQuery) ) 
	<cfset getPost = application.blog.getPost(params, showPendingPosts, false, true, true)>
	--->
	<cfinvoke component="#application.blog#" method="getPost" returnvariable="getPost">
		<cfinvokeargument name="params" value="#params#">
		<!--- Show blog posts and pages --->
		<cfinvokeargument name="showPages" value="true">
		<cfinvokeargument name="showBlogPosts" value="true">
		<cfinvokeargument name="showPendingPosts" value="#showPendingPosts#">
		<cfinvokeargument name="showRemovedPosts" value="false">
		<cfinvokeargument name="showJsonLd" value="true">
		<cfinvokeargument name="showPromoteAtTopOfQuery" value="true">
		<!--- Show pages and blog posts when looking at an page --->
		<cfif URL.mode eq 'page' or url.mode eq "alias" or URL.mode eq 'entry'>
			<cfinvokeargument name="showPages" value="true">
			<cfinvokeargument name="showBlogPosts" value="true">
		<cfelse>
			<!--- Otherwise, only show the posts --->
			<cfinvokeargument name="showPages" value="false">
			<cfinvokeargument name="showBlogPosts" value="true">
		</cfif>
	</cfinvoke>
</cfif>
	
<!--- Determine if the post was found --->
<cfif arrayLen(getPost) eq 0>
	<cfset postFound = false>
<cfelse>
	<cfset postFound = true>
</cfif>
	
<!--- Handle potential post redirects --->
<cfif (url.mode eq "alias" or URL.mode eq 'entry')>
	
	<!--- If the post was not found (as it is set to inactive), handle potential post redirects --->
	<cfif postFound>
		<cftry>
			<!--- See if there is a redirect --->
			<cfset redirectUrl = getPost[1]["RedirectUrl"]>
			<!--- Get the type --->
			<cfset redirectType = getPost[1]["RedirectType"]>
			<cfif len(redirectUrl)>
				<!--- Redirect the URL with the status code --->
				<cflocation url="#redirectUrl#" statusCode="#redirectType#">
			</cfif><!---<cfif len(redirectUrl)>--->
		<cfcatch type="any">
			<!--- Do nothing --->
		</cfcatch>
		</cftry>
	<cfelse><!---<cfif postFound>--->
		<cftry>
			<!--- Get the potential URL redirect when the post is inactive. We are using the alias here as it is in the params struct and we don't have other identifying information. --->
			<cfset getPostRedirect = application.blog.getPostRedirect(params.byAlias)>
			<cfif arrayLen(getPostRedirect)>
				<!--- See if there is a redirect --->
				<cfset redirectUrl = getPostRedirect[1]["RedirectUrl"]>
				<!--- Get the type --->
				<cfset redirectType = getPostRedirect[1]["RedirectType"]>
				<cfif len(redirectUrl)>
					<!--- Redirect the URL with the status code --->
					<cflocation url="#redirectUrl#" statusCode="#redirectType#">
				</cfif><!---<cfif len(redirectUrl)>--->
			</cfif><!---<cfif arrayLen(getPostRedirect)>--->
		<cfcatch type="any">
			<!--- Do nothing --->
		</cfcatch>
		</cftry>
	</cfif><!---<cfif postFound>--->
</cfif><!---<cfif URL.mode eq 'entry'>--->

<!--- 
Debugging: 
<cfdump var="#params#" label="params">
<cfdump var="#getPost#" label="getPost">
--->