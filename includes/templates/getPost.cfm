<!--- //**************************************************************************************************************
		Get the posts. The posts can either be one post, or multiple posts. It is designed this way to keep the output logic the same.
//****************************************************************************************************************--->

<!--- Raymond's module to inspect the URL to determine what to pass to the getPost method. Get mode also deterines the start and end row determined by what type of page this is (blog or post for example). I am going to rewrite this in version 4ish --->
<cfmodule template="#application.baseUrl#/tags/getmode.cfm" r_params="params"/>
<!---<cfdump var="#params#">--->

<!--- 
Get the post count (getPostCount(params,showRemovedPosts))
(note: this function must be placed above the getPost invocation below)
--->
<cfset postCount = application.blog.getPostCount(params, false, false)>
<!--- Allow the admin to preview if the showPendingPosts URL var is present and if we are looking at a single entry. This is needed as we don't want to accidently cache the main blog page (with multiple posts) when previewing the page --->
<cfif ( isDefined("URL.showPendingPosts") and (url.mode eq "alias" or URL.mode eq 'entry'))>
	<cfset showPendingPosts = true>
<cfelse>
	<cfset showPendingPosts = false>
</cfif>

<!--- Get the posts ( getPost(params, showPendingPosts, showRemovedPosts, showJsonLd, showPromoteAtTopOfQuery) ) --->
<cfset getPost = application.blog.getPost(params, showPendingPosts, false, true, true)>

<!--- Determine if the post was found --->
<cfif arrayLen(getPost) eq 0>
	<cfset postFound = false>
<cfelse>
	<cfset postFound = true>
</cfif>
<!--- 
Debugging: 
<cfdump var="#params#" label="params">
<cfdump var="#getPost#" label="getPost">
--->