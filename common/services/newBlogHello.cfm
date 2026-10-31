<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<!---
	Say hello (5.0.x, 2026-10-31, owner). A new blog's Site Wizard can, when its owner ticks the boxes on the last screen, tell
	Galaxie Blog's author that it is running (Setup.cfc sendHello): its name, address, Galaxie version and engine, and, to be
	added to cfblogs.org, its feed and the owner's email. This page takes that note and emails it to this blog's own address.
	Every blog has this file, but only galaxieblog.org answers (and a local test copy); anywhere else it says not found, so it
	can't be used to send mail to other blogs' owners. A few notes a day per address at most.
--->
<cfif cgi.request_method neq "POST">
	<cfheader statuscode="405">
	<cfabort>
</cfif>
<cfset helloHost = lCase(reReplace(cgi.server_name, "^www\.", ""))>
<cfif not listFindNoCase("galaxieblog.org,localhost,127.0.0.1", helloHost)>
	<cfheader statuscode="404">
	<cfabort>
</cfif>

<!--- At most 5 notes a day from one address, and 100 a day in all. --->
<cfset helloToday = dateFormat(now(), "yyyy-mm-dd")>
<cflock name="galaxieNewBlogHello_#application.applicationName#" type="exclusive" timeout="5">
	<cfif not structKeyExists(application, "galaxieHelloLog") or application.galaxieHelloLog.day neq helloToday>
		<cfset application.galaxieHelloLog = { day = helloToday, total = 0, byAddress = {} }>
	</cfif>
	<cfset helloCount = application.galaxieHelloLog.byAddress[cgi.remote_addr] ?: 0>
	<cfif helloCount gte 5 or application.galaxieHelloLog.total gte 100>
		<cfheader statuscode="429">
		<cfoutput>{"ok":false,"message":"Too many notes today."}</cfoutput>
		<cfabort>
	</cfif>
	<cfset application.galaxieHelloLog.byAddress[cgi.remote_addr] = helloCount + 1>
	<cfset application.galaxieHelloLog.total = application.galaxieHelloLog.total + 1>
</cflock>

<!--- Only what the wizard sends, cut to sensible lengths; addresses must be web addresses. --->
<cfset hello = {
	siteName = left(trim(form.siteName ?: ""), 200),
	siteUrl = left(trim(form.siteUrl ?: ""), 300),
	version = left(trim(form.version ?: ""), 20),
	engine = left(trim(form.engine ?: ""), 60),
	database = left(trim(form.database ?: ""), 40),
	addToCfblogs = isBoolean(form.addToCfblogs ?: "") and form.addToCfblogs,
	feedUrl = left(trim(form.feedUrl ?: ""), 300),
	email = left(trim(form.email ?: ""), 150)
}>
<cfif not reFindNoCase("^https?://[^\s""'<>]+$", hello.siteUrl)>
	<cfheader statuscode="400">
	<cfoutput>{"ok":false,"message":"The site address is missing."}</cfoutput>
	<cfabort>
</cfif>
<cfif len(hello.feedUrl) and not reFindNoCase("^https?://[^\s""'<>]+$", hello.feedUrl)><cfset hello.feedUrl = ""></cfif>
<cfif len(hello.email) and not isValid("email", hello.email)><cfset hello.email = ""></cfif>

<cfsavecontent variable="helloBody"><cfoutput>
<p>A new Galaxie Blog said hello<cfif hello.addToCfblogs> and asked to be added to <b>cfblogs.org</b></cfif>.</p>
<table cellpadding="4" cellspacing="0" border="0">
	<tr><td align="right"><b>Site</b></td><td>#encodeForHtml(hello.siteName)#</td></tr>
	<tr><td align="right"><b>Address</b></td><td><a href="#encodeForHtmlAttribute(hello.siteUrl)#">#encodeForHtml(hello.siteUrl)#</a></td></tr>
	<tr><td align="right"><b>Galaxie</b></td><td>#encodeForHtml(hello.version)#</td></tr>
	<tr><td align="right"><b>Engine</b></td><td>#encodeForHtml(hello.engine)#</td></tr>
	<tr><td align="right"><b>Database</b></td><td>#encodeForHtml(hello.database)#</td></tr>
	<cfif hello.addToCfblogs>
	<tr><td align="right"><b>Feed</b></td><td><cfif len(hello.feedUrl)><a href="#encodeForHtmlAttribute(hello.feedUrl)#">#encodeForHtml(hello.feedUrl)#</a><cfelse>(none sent)</cfif></td></tr>
	<tr><td align="right"><b>Owner's email</b></td><td><cfif len(hello.email)><a href="mailto:#encodeForHtmlAttribute(hello.email)#">#encodeForHtml(hello.email)#</a><cfelse>(none sent)</cfif></td></tr>
	</cfif>
	<tr><td align="right"><b>Sent from</b></td><td>#encodeForHtml(cgi.remote_addr)#, #dateTimeFormat(now(), "yyyy-mm-dd HH:nn")#</td></tr>
</table>
</cfoutput></cfsavecontent>

<cftry>
	<cfset createObject("component", application.utilsComponentPath).mail(
		to = application.BlogDbObj.getBlogEmail(),
		subject = "New Galaxie blog: " & (len(hello.siteName) ? hello.siteName : hello.siteUrl) & (hello.addToCfblogs ? " (add to cfblogs)" : ""),
		body = helloBody,
		replyTo = (hello.addToCfblogs ? hello.email : ""))>
	<cfcatch type="any">
		<cfheader statuscode="500">
		<cfoutput>{"ok":false,"message":"The note could not be sent."}</cfoutput>
		<cfabort>
	</cfcatch>
</cftry>
<cfoutput>{"ok":true}</cfoutput>
