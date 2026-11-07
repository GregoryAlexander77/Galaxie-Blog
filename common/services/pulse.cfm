<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
	Live updates (2026-11-07): what changed since the browser last looked, by channel (common/cfc/Pulse.cfc). Asked every so often by
	common/js/galaxiePulse.js. Kept as small as a request can be: no database, no files, no visitor logging (it isn't a page view).

	Ask:    pulse.cfm?c=comments:1731012345678,admin:comments:0     (channel:last version seen; 0 = first ask)
	Answer: { "on": true, "seconds": 30, "channels": { "comments": { "v": 1731012399999, "events": [ { "postId": 14 } ], "reset": false } } }
	        { "on": false } when Live Updates is off in Blog Options - the browser stops asking.
	A channel this visitor may not read (Pulse.cfc canRead) is left out of the answer.
--->
<cfset pulseAnswer = { "on": false }>
<cftry>
	<cfset pulseSettings = application.blog.getLiveUpdates()>
	<cfif pulseSettings.on>
		<cfset pulseSince = {}>
		<!--- At most 10 channels, each name letters, digits, colons, dashes and underscores. --->
		<cfloop list="#left(URL.c ?: "", 600)#" index="pulseItem">
			<cfset pulseName = reReplace(listDeleteAt(pulseItem, listLen(pulseItem, ":"), ":"), "[^A-Za-z0-9:_\-]", "", "all")>
			<cfset pulseSeen = listLast(pulseItem, ":")>
			<cfif listLen(pulseItem, ":") gt 1 and len(pulseName) and len(pulseName) le 60 and structCount(pulseSince) lt 10>
				<cfset pulseSince[pulseName] = isNumeric(pulseSeen) ? pulseSeen : 0>
			</cfif>
		</cfloop>
		<cfset pulseAnswer = { "on": true, "seconds": pulseSettings.seconds, "channels": application.blog.getPulse().read(pulseSince) }>
	</cfif>
	<cfcatch type="any">
		<!--- Never an error page: the browser just tries again later. --->
		<cfset pulseAnswer = { "on": true, "seconds": 60, "channels": {} }>
	</cfcatch>
</cftry>
<cfheader name="Cache-Control" value="no-store">
<cfcontent reset="true" type="application/json; charset=utf-8"><cfoutput>#serializeJSON(pulseAnswer)#</cfoutput>
