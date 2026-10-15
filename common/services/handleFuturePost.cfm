<cfprocessingdirective pageencoding="utf-8">
<!---
This is used to send future emails out using a scheduled task when the user saves a post to be released at a later date.
--->
	
<!--- See if the scheduled post task exists. If it doesn't, abort this --->
<!--- Get all of the tasks. --->
<cfschedule action="list" result="tasks">
<!--- See if the task is in the list. --->
<cfquery name="getTask" dbtype="query"> 
	SELECT Task FROM Tasks
	WHERE Task = <cfqueryparam value="schedulePost#URL.postId#">
</cfquery>

<!--- Only a post whose release time has come, and that isn't released yet (2026-10-14). --->
<cfset futurePostIsDue = false>
<cfif getTask.recordcount and isNumeric(URL.postId)>
	<cfset futurePost = entityLoadByPK("Post", val(URL.postId))>
	<cfif not isNull(futurePost) and not (isBoolean(futurePost.getReleased()) and futurePost.getReleased()) and not isNull(futurePost.getDatePosted())
		and dateCompare(futurePost.getDatePosted(), dateAdd("n", 2, application.blog.blogNow())) lte 0>
		<cfset futurePostIsDue = true>
	</cfif>
</cfif>

<cfif futurePostIsDue>
	<!--- Email and release the post --->
	<cfinvoke component="#application.blog#" method="releaseFuturePosts" returnvariable="emailSent">
		<cfinvokeargument name="postId" value="#URL.postId#">
		<cfinvokeargument name="bypassErrors" value="true">
	</cfinvoke>
	<cfoutput>emailSent: #emailSent#</cfoutput>

	<!--- Delete the scheduled task --->
	<cftry>
		<cfschedule action="delete" task="schedulePost#URL.postId#">
		<cfcatch type="any">Task can't be found</cfcatch>
	</cftry> 
	
</cfif><!---<cfif getTask.recordcount>--->