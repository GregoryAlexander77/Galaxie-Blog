<cfsilent>
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "compositeFooter">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- The footer's content comes from the Composite Footer content template (Themes in the administrative site). If the blog owner hasn't saved one, the neutral default below is used. --->
<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
	<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
	<cfinvokeargument name="isMobile" value="#session.isMobile#">
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<cfinvokeargument name="themeRef" value="#URL.optArgs#">
	</cfif>
</cfinvoke>
<!--- Phones read the mobile version of the footer only. An owner who saved just the desktop footer would otherwise see the default footer on phones, so fall back to the desktop footer. --->
<cfif session.isMobile and not len(trim(contentOutputData))>
	<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
		<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
		<cfinvokeargument name="isMobile" value="false">
	</cfinvoke>
</cfif>
<!--- Determine if we should display the data or use the default HTML --->
<cfif len(trim(contentOutputData))>
	<cfset displayContentOutputData = true>		
</cfif>
<!--- ********* End content template logic *********--->
</cfsilent>

<br/><br/><br/>
<div id="footerDiv" name="footerDiv" class="k-content">
	<footer>
		<span id="footerInnerContainer">
		<cfif displayContentOutputData>
			<!--- The owner's own footer from the Composite Footer content template. Note: the footer and span tags are removed by tinymce so we need to manually include them --->
			<cfoutput>#contentOutputData#</cfoutput>
		<cfelse>
			<!--- Neutral default for any blog. The site-specific text that used to be here (the galaxieblog.org promo on Lucee, the gregoryalexander.com credits on Adobe ColdFusion) now lives in each site's own Composite Footer. --->
			<a href="<cfoutput>#application.blogHostUrl#</cfoutput>"><img src="<cfoutput>#application.baseUrl##footerImage#</cfoutput>" alt="Footer Logo"/></a>
			<!--- Shown only to a logged-in admin. The footer is cached as HTML for every visitor, so this stays hidden here and index.cfm reveals it after the cached footer when an admin is logged in. --->
			<p id="footerCustomizeHint" hidden>You can replace this footer with your own in the administrative site: Themes, then Composite Footer.</p>
		</cfif>
			<h2 style="font-size:14pt">Version:</h2>
			<p>
				Powered by <a href="https://www.galaxieblog.org">Galaxie Blog</a> Version <cfoutput>#application.blog.getVersionName()# #application.blog.getVersionDate()# #getTheme[1]["Theme"]# theme</cfoutput><br/>
				&copy; <cfoutput>#dateFormat(now(), 'yyyy')# #encodeForHtml(application.BlogDbObj.getBlogTitle())#</cfoutput>
			</p>
		</span>
	</footer>
</div><!---<div id="footerDiv" name="footerDiv" class="k-content">--->
