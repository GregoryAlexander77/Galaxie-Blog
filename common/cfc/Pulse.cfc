<cfcomponent displayName="Pulse" output="false" hint="Live updates (2026-11-07, owner: 'another polling function to check for new comments and render the new comments on the front page ... this poll needs to be used for our new notifications in future versions, so the polling needs to be fast and adaptable'). A tiny in-memory change log, by channel. Anything that changes calls touch(channel, data); browsers ask common/services/pulse.cfm every so often what changed since the version they last saw (common/js/galaxiePulse.js). Answering never touches the database or the disk. Used through blog.cfc getPulse().">

<!---
	Channels are plain names. Who may read one is decided here, in canRead():
	  comments         - public: a comment was approved, changed or deleted. data = { postId }.
	  admin:<name>     - signed-in admins only (for the admin notifications to come).
	  member:<id>      - only that signed-in member (for member notifications to come).
	A channel that has never been touched has the version of the moment this log started.

	A version is the time it changed, in milliseconds (always larger than the one before), so it means the same thing to every
	browser. The log is kept in memory only: after a restart it starts again, empty, and a browser that last looked before then
	(or further back than the log reaches) is told to start over ("reset") instead of being sent changes it may have missed.
--->

<cfset variables.channels = {}>
<!--- When this log started (a restart starts a new, empty one): a browser that last looked before then may have missed changes. --->
<cfset variables.started = createObject("java", "java.lang.System").currentTimeMillis()>
<!--- How many changes each channel keeps. A browser further behind than this gets "reset". --->
<cfset variables.keep = 100>

<cffunction name="touch" access="public" returntype="numeric" output="false" hint="Records a change on a channel and returns its new version. data is any small struct that tells a browser what changed (for comments, { postId }).">
	<cfargument name="channel" type="string" required="true">
	<cfargument name="data" type="struct" required="false" default="#{}#">
	<cfset var name = lCase(trim(arguments.channel))>
	<cfset var entry = "">
	<cfset var version = 0>
	<cfif not len(name)><cfreturn 0></cfif>
	<cflock name="galaxiePulse_#application.applicationName#" type="exclusive" timeout="5">
		<cfif not structKeyExists(variables.channels, name)>
			<cfset variables.channels[name] = { version: 0, events: [] }>
		</cfif>
		<cfset entry = variables.channels[name]>
		<cfset version = max(nowMs(), entry.version + 1)>
		<cfset arrayAppend(entry.events, { "v": version, "data": duplicate(arguments.data) })>
		<cfif arrayLen(entry.events) gt variables.keep>
			<cfset arrayDeleteAt(entry.events, 1)>
		</cfif>
		<cfset entry.version = version>
	</cflock>
	<cfreturn version>
</cffunction>

<cffunction name="read" access="public" returntype="struct" output="false"
		hint="What changed on each channel since the version the browser last saw: { channel: { v, events: [data...], reset } }. A channel the visitor may not read is left out. since = 0 (first ask) gives the version and no events.">
	<cfargument name="since" type="struct" required="true" hint="{ channel: last version seen }">
	<cfset var result = {}>
	<cfset var name = "">
	<cfset var seen = 0>
	<cfset var entry = "">
	<cfset var events = []>
	<cfset var one = "">
	<cflock name="galaxiePulse_#application.applicationName#" type="readonly" timeout="5">
		<cfloop collection="#arguments.since#" item="name">
			<cfif canRead(name)>
				<cfset seen = isNumeric(arguments.since[name]) ? arguments.since[name] : 0>
				<cfset entry = structKeyExists(variables.channels, lCase(name)) ? variables.channels[lCase(name)] : { version: 0, events: [] }>
				<cfset events = []>
				<cfif seen gt 0 and entry.version gt seen and seen ge variables.started>
					<cfloop array="#entry.events#" index="one">
						<cfif one.v gt seen><cfset arrayAppend(events, one.data)></cfif>
					</cfloop>
				</cfif>
				<!--- Start over when the browser last looked before this log began (a restart), or when more changed since then than
				the log keeps (the oldest kept change is newer than what it saw, and some were dropped). The version goes as text: a 13-digit
				number can come out as 1.7E12 in JSON. --->
				<cfset result[lCase(name)] = {
					"v": numberFormat(max(entry.version, variables.started), "0"),
					"events": events,
					"reset": seen gt 0 and (seen lt variables.started or (arrayLen(entry.events) ge variables.keep and entry.events[1].v gt seen))
				}>
			</cfif>
		</cfloop>
	</cflock>
	<cfreturn result>
</cffunction>

<cffunction name="canRead" access="public" returntype="boolean" output="false" hint="Whether this visitor may read a channel.">
	<cfargument name="channel" type="string" required="true">
	<cfset var name = lCase(trim(arguments.channel))>
	<cfset var member = "">
	<cfif listFind("comments", name)>
		<cfreturn true>
	</cfif>
	<cfif left(name, 6) eq "admin:">
		<cfreturn application.Udf.isLoggedIn()>
	</cfif>
	<cfif left(name, 7) eq "member:" and isNumeric(listLast(name, ":")) and structKeyExists(application, "members")>
		<cfset member = application.members.getCurrentMember()>
		<cfreturn not structIsEmpty(member) and member.memberId eq val(listLast(name, ":"))>
	</cfif>
	<cfreturn false>
</cffunction>

<cffunction name="nowMs" access="private" returntype="numeric" output="false">
	<cfreturn createObject("java", "java.lang.System").currentTimeMillis()>
</cffunction>

</cfcomponent>
