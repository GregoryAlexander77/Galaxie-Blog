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

<cfif getTask.recordcount>
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