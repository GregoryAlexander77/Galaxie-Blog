<cfsetting enablecfoutputonly=true>
<cfprocessingdirective pageencoding="utf-8">
<!---
	Name         : unsubscribe.cfm
	Author       : Raymond Camden 
	Created      : October 20, 2004
	Last Updated : August 20, 2006
	History      : Removed mapping (3/20/05)
				   Adding cfsetting, procdirective (rkc 7/21/05)
				   Use of rb (rkc 8/20/06)
	Purpose		 : Allows you to unsubscribe
--->

<cfif not isDefined("url.email")>
	<cflocation url = "#application.blog.getProperty("blogURL")#">
</cfif>


<cfmodule template="tags/layout.cfm" title="#getResourceBundle("unsubscribe")#">

<cfoutput>
<div class="date">#getResourceBundle("unsubscribe")#</div>
</cfoutput>

<cfif isDefined("url.commentID")>

	<!--- Attempt to unsub --->
	<cftry>
		<cfset result = application.blog.unsubscribeThread(url.commentID, url.email)>
		<cfcatch>
			<cfset result = false>
		</cfcatch>
	</cftry>
	
	<cfif result>
		<cfoutput>
		<p>#getResourceBundle("unsubscribesuccess")#</p>
		</cfoutput>
	<cfelse>
		<cfoutput>
		<p>#getResourceBundle("unsubscribefailure")#</p>
		</cfoutput>
	</cfif>

<cfelseif isDefined("url.token")>

	<!--- Attempt to unsub --->
	<cftry>
		<cfset result = application.blog.removeSubscriber(url.email, url.token)>
		<cfcatch>
			<cfset result = false>
		</cfcatch>
	</cftry>
	
	<cfif result>
		<cfoutput>
		<p>#getResourceBundle("unsubscribeblogsuccess")#</p>
		</cfoutput>
	<cfelse>
		<cfoutput>
		<p>#getResourceBundle("unsubscribeblogfailure")#</p>
		</cfoutput>
	</cfif>

</cfif>

<cfoutput><p><a href="#application.blog.getProperty("blogurl")#" class="k-content">#getResourceBundle("returntoblog")#</a></p></cfoutput>

</cfmodule>
<cfsetting enablecfoutputonly=false>	