<cfsilent>
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "compositeFooter">
<!--- The following logic does not need to be modified and will work with most of the content output templates --->
<!--- Reset our display content output var --->
<cfset displayContentOutputData = false>
<!--- This template drives the navigation menu and is a unordered HTML list. This template uses the getPageContent function to determine the content. It will display custom content that is in the database or use the default code below if no custom code exists  --->
<cfinvoke component="#application.blog#" method="getContentOutputData" returnvariable="contentOutputData">
	<cfinvokeargument name="contentTemplate" value="#thisTemplate#">
	<cfinvokeargument name="isMobile" value="#session.isMobile#">
	<cfif isDefined("URL.optArgs") and len(URL.optArgs)>
		<cfinvokeargument name="themeRef" value="#URL.optArgs#">
	</cfif>
</cfinvoke>		
<!--- Determine if we should display the data or use the default HTML --->
<cfif len(contentOutputData)>
	<cfset displayContentOutputData = true>		
</cfif>
<!--- ********* End content template logic *********--->
</cfsilent>

<br/><br/><br/>
<cfif displayContentOutputData>
	<!--- Include the custom user defined content from the database. Note: the footer and span tags are removed by tinymce so we need to manually include them --->
	<div id="footerDiv" name="footerDiv" class="k-content">
		<footer>
			<span id="footerInnerContainer">
				<cfoutput>#contentOutputData#</cfoutput>
			</span>
		</footer>
	</div>
<cfelse>
	<div id="footerDiv" name="footerDiv" class="k-content">
		<footer>
			<span id="footerInnerContainer">
				<img src="<cfoutput>#application.baseUrl##footerImage#</cfoutput>" alt="Footer Logo"/>

				<h2 style="font-size:14pt; display: block; margin-left: auto; margin-right: auto;">Your input and contributions are welcomed!</h2>
				<p>If you have an idea, BlogCfc based code, or a theme that you have built using this site that you want to share, please contribute by making a post here or share it by contacting us! This community can only thrive if we continue to work together.</p>

				<h2 style="font-size:14pt">Images and Photography:</h2>
				<p>Gregory Alexander either owns the copyright, or has the rights to use, all images and photographs on the site. If an image is not part of the "Galaxie Blog" open sourced distribution package, and instead is part of a personal blog post or a comment, please contact us and the author of the post or comment to obtain permission if you would like to use a personal image or photograph found on this site.</p>

				<h2 style="font-size:14pt">Credits:</h2>
				<p>
					Portions of Galaxie Blog are powered on the server side by BlogCfc, an open source blog developed by <a href="https://www.raymondcamden.com/" <cfif darkTheme>style="color:whitesmoke"</cfif>>Raymond Camden</a>. Revitalizing BlogCfc was a part of my orginal inspiration that prompted me to design this site. 
				</p>
				<h2 style="font-size:14pt">Version:</h2>
				<p>
					Galaxie Blog Version <cfoutput>#application.blog.getVersionName()# #application.blog.getVersionDate()# #getTheme[1]["Theme"]# theme</cfoutput>
				</p>
				<p>
				<cfif application.serverProduct eq 'Lucee'>
					<a href="https://www.viviotech.net/"><img src="<cfoutput>#application.baseUrl#</cfoutput>/images/logo/viviotech/vivioTechSmallLogo.<cfif application.serverSupportsWebP>webp<cfelse>png</cfif>" alt="Lucee Linux Hosting provided by www.viviotech.net"></a>
				<cfelse>
					<a href="https://www.media3.net"><img src="<cfoutput>#application.baseUrl#</cfoutput>/images/logo/m3/m3-cloud-logo-hosting-small.gif" alt="ColdFusion Windows Hosting provided by www.media3.net"></a>
				</cfif>
				</p>
			</span>
		</footer>
	</div><!---<div id="footerDiv" name="footerDiv" class="k-content">--->
</cfif>