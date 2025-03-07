<cfsilent>
<!--- 
********* Content template common logic *********
Note: the following logic should not be cached as each theme may return a different content template and it would overwhelm the cache memory. Instead, I am caching the content output which is the same for most themes. Other than setting the thisTemplate var, this logic is identical for most of the content output templates --->
<cfset thisTemplate = "aboutWindow">
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
<cfif displayContentOutputData>
	<!--- Include the content template for the navigation script --->
	<cfoutput>#contentOutputData#</cfoutput>
<cfelse>
	<img src="<cfoutput><cfif session.isMobile>#application.baseUrl#/images/logo/gregorysBlogMobile.png<cfelse>#application.baseUrl#/images/logo/gregorysBlogLogo.gif</cfif></cfoutput>" id="about" align="left" alt="Gregory Alexander" style="margin: 15px;"/>

	<p style="display: none;">About this blog.</p>

	<p>Question for the seasoned developer- when was the last time that you actually bought a computer programming book? If you’re like me, it has been a long time ago when we had different stacks of different books filled with sticky notes laying next to us. Instead, I rely upon the web, and blogs like this to solve my programming needs. I often joke that my actual job is using search engines as a living. Often, meeting a goal depends on using the right search phrases to find an answer to the current challenge that I am facing. Developing this blog is one way that I can try to give back to this community.</p>

	<p><b>Gregory’s Blog</b> is intended to be the most beautiful and functional open sourced ColdFusion based blog in the world. While I can’t go toe to toe with Wordpress functionality, I believe that Gregory’s Blog competes with Wordpress in core functionality, especially with its abundant theme related features. This blog was built from the ground up to be eminently themeable. Galaxie Blog is a responsive web application, and should be fully functional and work on any modern device: desktop: tablet: and mobile. With a limited amount of time and knowledge, a user can change the background and logo images, set the various container widths, opacities, and even skin and share their own personal themes. I have also developed scores of pre-defined themes.</p>

	<p><b>Gregory’s Blog</b> is a HTML5 interface, has built in social sharing, theme-based code formatters, a web based installer, enclosure support, supports inline .CSS, scripts and HTML, engaging media and animation capabilities using <b><a href="https://greensock.com/">GreenSock</a></b>, an HTML 5 based media player, captcha, comment moderation, search capabilities, RSS feeds and CFBlogger integration, textblock support, and has a plug-in architecture where you can isolate and potentially share your own custom code. Additionally, this blog uses the exact same database and ColdFusion server side logic as another older popular ColdFusion blog engine, blogCfc, so if you are familiar with ColdFusion, or have used BlogCfc, you should be able to convert your current blog and get this up and running quite easily.</p>

	<p>To keep this project moving forward, I hope to elicit your help. I hope to continue developing this blog with rich editor support and hopefully add some features for photographers. If you have a suggestion, or have a bug to report; please don’t hesitate to contact me. Your input and suggestions are welcomed. Finally, if you blog and program in ColdFusion, I would encourage you to consider sharing your own ColdFusion based blogging solution. I designed this blog to support rudimentary plug-in functionality so that others can share their own code.</p>

	<p>The blogging content that I will contribute mainly will deal with the support of Gregory’s Blog, and hopefully provide helpful articles about how to incorporate Telerik’s Kendo UI with ColdFusion. I would like to believe that I am an expert at both technologies and hope to share some of my insight. Also, this blog is intended to be downloaded so that others can learn by examining my code. I also hope to publish a few random non tech articles from time to time, share a recipe or two, and to share my adventures from a recent hiking trip.</p>

	<p>Thanks!</p> 

	<p>Gregory Alexander</p> 

	<p><a href="http://gregoryalexander.com/blog/">http://gregoryalexander.com/blog/</a></p>
</cfif>