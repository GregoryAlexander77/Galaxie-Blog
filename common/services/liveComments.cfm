<cfsetting enablecfoutputonly="false" showdebugoutput="false">
<!---
	Live updates for comments (2026-11-07): after common/services/pulse.cfm says a post's comments changed, a page showing them asks
	here for the fresh list (common/js/galaxieLiveComments.js). The same markup as the page itself (includes/templates/content/
	postComments.cfm): approved comments only. Not a page view, so nothing is logged.

	?postId=14              -> { "success": true, "postId": 14, "count": 3, "ids": [12, 13, 15], "html": "<table ...>" }
	?part=recentComments    -> { "success": true, "html": "..." }  (the Recent Comments pod's list)
--->
<cfset liveAnswer = { "success": false }>
<cftry>
	<!--- The same in-memory ban check pages use. --->
	<cfif application.blog.isVisitorBanned(ipAddress = application.blog.getIpAddress(), httpUserAgent = CGI.Http_User_Agent)>
		<cfheader statuscode="403">
		<cfcontent reset="true" type="application/json; charset=utf-8"><cfoutput>{"success":false}</cfoutput><cfabort>
	</cfif>
	<cfif not application.blog.getLiveUpdates().on>
		<cfthrow message="Live updates are off.">
	</cfif>
	<cfif (URL.part ?: "") eq "recentComments">
		<!--- What the pod's template gets from the page (pods/index.cfm): the side bar's kind and the theme's look, sent back by the page. --->
		<cfset sideBarType = (URL.sideBar ?: "") eq "panel" ? "panel" : "div">
		<cfset modernTheme = (URL.modern ?: "") eq "1">
		<cfset darkTheme = (URL.dark ?: "") eq "1">
		<cfset scriptTypeString = application.blog.getScriptTypeString()>
		<cfsavecontent variable="liveHtml"><cfoutput><cfinclude template="../../includes/templates/content/pods/recentcomments.cfm"></cfoutput></cfsavecontent>
		<cfset liveAnswer = { "success": true, "html": trim(liveHtml) }>
	<cfelseif isValid("integer", URL.postId ?: "") and URL.postId gt 0>
		<cfset postId = int(URL.postId)>
		<!--- Released, not removed: getPostByPostId(postId, showPendingPosts, showRemovedPosts). --->
		<cfset livePost = application.blog.getPostByPostId(postId, false, false)>
		<cfif arrayLen(livePost)>
			<cfset allowComment = not structKeyExists(livePost[1], "AllowComment") or livePost[1]["AllowComment"] eq true>
			<cfset postLink = application.blog.makeLink(postId)>
			<cfif application.serverRewriteRuleInPlace><cfset postLink = replaceNoCase(postLink, "/index.cfm", "")></cfif>
			<cfsavecontent variable="liveHtml"><cfoutput><cfinclude template="../../includes/templates/content/postComments.cfm"></cfoutput></cfsavecontent>
			<cfset liveIds = []>
			<cfloop array="#comments ?: []#" index="liveComment"><cfset arrayAppend(liveIds, liveComment["CommentId"])></cfloop>
			<cfset liveAnswer = { "success": true, "postId": postId, "count": arrayLen(liveIds), "ids": liveIds, "html": trim(liveHtml) }>
		</cfif>
	</cfif>
	<cfcatch type="any">
		<cfset liveAnswer = { "success": false }>
	</cfcatch>
</cftry>
<cfheader name="Cache-Control" value="no-store">
<cfcontent reset="true" type="application/json; charset=utf-8"><cfoutput>#serializeJSON(liveAnswer)#</cfoutput>
