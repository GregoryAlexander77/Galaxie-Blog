<!--- //**************************************************************************************************************
		Get the posts. The posts can either be one post, or multiple posts. It is designed this way to keep the output logic the same.
//****************************************************************************************************************--->

<!--- Raymond's module to inspect the URL to determine what to pass to the getPost method. Get mode also deterines the start and end row determined by what type of page this is (blog or post for example). I am going to rewrite this in version 4ish --->
<cfmodule template="#application.baseUrl#/tags/getmode.cfm" r_params="params"/>
<!---<cfdump var="#params#">--->
  
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

<!--- Note: a post may be removed and have a redirect to another URL. We need to allow for removed posts to get the redirect if it exists. --->
<!--- Get the posts ( getPost(params, showPendingPosts, showRemovedPosts, showJsonLd, showPromoteAtTopOfQuery) ) --->
<cfset getPost = application.blog.getPost(params, showPendingPosts, false, true, true)>
	
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