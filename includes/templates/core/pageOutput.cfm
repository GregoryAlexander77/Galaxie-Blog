<!--- Sends the page that was captured in the pageHtml variable (index.cfm, admin/index.cfm and admin/login.cfm) to the browser. When the 'Minimize Code' blog option is checked the html is minimized first (see /common/cfc/HtmlMinifier.cfc). The minifier is the same code for ColdFusion and Lucee and it returns the original html if anything goes wrong. --->
<cfif application.minimizeCode>
	<!--- The application may have been running when this was uploaded, so create the minifier if it is not there yet. --->
	<cfif not structKeyExists(application, "htmlMinifier")>
		<cfif len(application.baseProxyUrl) gt 0>
			<cfset application.htmlMinifier = createObject("component", application.baseComponentPath & ".common.cfc.HtmlMinifier").init()>
		<cfelse>
			<cfset application.htmlMinifier = createObject("component", "common.cfc.HtmlMinifier").init()>
		</cfif>
	</cfif>
	<cfoutput>#application.htmlMinifier.minify(pageHtml)#</cfoutput>
<cfelse>
	<cfoutput>#pageHtml#</cfoutput>
</cfif>
