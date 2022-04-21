<cfprocessingdirective pageencoding="utf-8">
<!---
This is used to send future emails out using a scheduled task when the user saves a post to be released at a later date.
--->

<!--- Email the post --->
<cfinvoke component="#application.blog#" method="sendPostEmailToSubscribers" returnvariable="emailSent">
	<cfinvokeargument name="postId" value="#URL.postId#">
	<cfinvokeargument name="bypassErrors" value="true">
</cfinvoke>
<cfoutput>#emailSent#</cfoutput>

<!--- Delete the scheduled task --->
<cftry>
	<cfschedule action="delete" task="/common/services/sendSubscriberEmail.cfm?postId=#URL.postId#">
	<cfcatch type="any">Task can't be found</cfcatch>
</cftry>